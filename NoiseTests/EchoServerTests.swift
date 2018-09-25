//
//  EchoServerTests.swift
//  Noise
//
// Created by Paulo Andrade on 24/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class EchoServerTests: XCTestCase, NoiseSessionDelegate {
    var serverPort = UInt16(7000)
    let keyFolderURL = Bundle(for: EchoServerTests.self).url(forResource: "keys", withExtension: nil)!
    let clientExecutableURL = Bundle(for: EchoClientTests.self).url(forAuxiliaryExecutable: "echo-client")!
    
    let serverOperationQueue = OperationQueue()
    
    var serverSocket: SocketPort?
    var serverHandle: FileHandle?
    var connectionAcceptedExpectation: XCTestExpectation?
    var connectionAcceptedObserver: Any?
    var clientSessions: [NoiseSession] = []
    
    override func setUp() {
        // Set up the listening socket
        continueAfterFailure = false
        
        
        serverSocket = SocketPort()
        serverSocket?.address.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            var addr = sockaddr_in()
            memcpy(&addr, bytes, MemoryLayout<sockaddr_in>.size)
            XCTAssertTrue(addr.sin_family == AF_INET)
            serverPort = addr.sin_port.bigEndian
        }
        
        serverHandle = FileHandle(fileDescriptor: serverSocket!.socket, closeOnDealloc: true)

        connectionAcceptedExpectation = expectation(description: "Connection accepted");
        connectionAcceptedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleConnectionAccepted, object: serverHandle, queue: serverOperationQueue) { (note) in
            guard let acceptedFileHandle = note.userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle else {
                return
            }
            self.connectionAcceptedExpectation?.fulfill()
            
            self.runServer(on: acceptedFileHandle)
            
            
        }

        serverHandle?.acceptConnectionInBackgroundAndNotify()


    }

    override func tearDown() {
        if let obs = connectionAcceptedObserver {
            NotificationCenter.default.removeObserver(obs)
            connectionAcceptedObserver = nil
        }
        if let s = serverSocket?.socket {
            close(s)
        }
        serverSocket = nil
        
        serverHandle?.closeFile()
        serverHandle = nil
        connectionAcceptedExpectation = nil
        clientSessions = []
    }

    func testNN() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["Noise_NN_448_ChaChaPoly_BLAKE2b", "localhost", "\(serverPort)"]

        run(clientProcess)
    }

    func testNX() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["Noise_NX_25519_ChaChaPoly_SHA512", "localhost", "\(serverPort)"]
        
        run(clientProcess)
    }
    
    func testXX() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["-c", keyFolderURL.appendingPathComponent("client_key_25519").path,
                                   "Noise_XX_25519_AESGCM_SHA512", "localhost", "\(serverPort)"]
        
        run(clientProcess)
    }
    
    func testNK() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["-s", keyFolderURL.appendingPathComponent("server_key_448.pub").path,
                                   "Noise_NK_448_AESGCM_SHA256", "localhost", "\(serverPort)"]
        
        run(clientProcess)
    }
    
    func testXK() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["-c", keyFolderURL.appendingPathComponent("client_key_448").path,
                                   "-s", keyFolderURL.appendingPathComponent("server_key_448.pub").path,
                                   "Noise_XK_448_AESGCM_SHA256", "localhost", "\(serverPort)"]
        
        run(clientProcess)
    }
    
    func testKK() {
        let clientProcess = Process()
        clientProcess.launchPath = clientExecutableURL.path
        clientProcess.arguments = ["-c", keyFolderURL.appendingPathComponent("client_key_25519").path,
                                   "-s", keyFolderURL.appendingPathComponent("server_key_25519.pub").path,
                                   "Noise_KK_25519_AESGCM_SHA256", "localhost", "\(serverPort)"]
        run(clientProcess)
    }
    
    // MARK: - Aux
    
    func run(_ clientProcess: Process) {
        let pipeOut = Pipe()
        clientProcess.standardOutput = pipeOut
        let pipeIn = Pipe()
        clientProcess.standardInput = pipeIn
        clientProcess.launch()
        
        wait(for: [connectionAcceptedExpectation!], timeout: 2.0)
        
        let handshakeComplete = expectation(description: "Handshake Complete")
        readLine(from: pipeOut.fileHandleForReading) { (line) in
            if line.contains("handshake complete") {
                handshakeComplete.fulfill()
            }
        }
        
        wait(for: [handshakeComplete], timeout: 3.0)
        
        XCTAssertTrue(clientSessions.count == 1)
        
        var text = "Hello World"
        write(line: text, to: pipeIn.fileHandleForWriting)
        expect(text: text, on: pipeOut.fileHandleForReading)
        
        text = "All Noise messages are less than or equal to 65535 bytes in length.";
        write(line: text, to: pipeIn.fileHandleForWriting)
        expect(text: text, on: pipeOut.fileHandleForReading)
        clientProcess.terminate()
    }
    
    func expect(text: String, on fh: FileHandle) {
        let expect = expectation(description: "Waiting on '\(text)'")
        readLine(from: fh) { (line) in
            XCTAssertEqual(line, "Received: \(text)" )
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func readLine(from fh: FileHandle, block: @escaping (_ line: String) -> Void) {
        
        DispatchQueue.global().async {
            var d = Data()
            var s: String?
            while let charCode = fh.readData(ofLength: 1).first {
                if CharacterSet.newlines.contains(UnicodeScalar(charCode)) {
                    // found new line character
                    s = String(data: d, encoding: .utf8)
                    break
                }
                else {
                    d.append(charCode)
                }
            }
            
            DispatchQueue.main.async {
                block(s ?? "")
            }
        }
        
    }
    
    func write(line: String, to fh: FileHandle) {
        fh.write("\(line)\n".data(using: .utf8)!)
    }
    
    func runServer(on clientHandle: FileHandle) {
        
        // start by reading the protocol
        let echoProtocolIdSize = MemoryLayout<EchoProtocolId>.size
        let echoProtocolIdData = clientHandle.readData(ofLength: echoProtocolIdSize)
        XCTAssertEqual(echoProtocolIdData.count, echoProtocolIdSize)
        
        var echo_protocol_id = EchoProtocolId()
        let _ = echoProtocolIdData.withUnsafeBytes { bytes in
            memcpy(&echo_protocol_id, bytes, echoProtocolIdSize)
        }
        
        var noise_protocol_id = NoiseProtocolId()
        XCTAssertEqual(echo_to_noise_protocol_id(&noise_protocol_id, &echo_protocol_id), 1)
        
        var nameData = Data(repeating: 0, count: 1024)
        nameData.withUnsafeMutableBytes { (bytes) -> Void in
            noise_protocol_id_to_name(bytes, 1024, &noise_protocol_id)
        }
        
        let protocolName = String(data: nameData, encoding: .utf8)!
        let proto = NoiseProtocol(name: protocolName)!
        let session = NoiseSession(with: proto, role: .responder)
        
        let ready = session.setup { (setup) in
            
            setup.setPrologue(echoProtocolIdData)
            
            if setup.localKeyPairMissing {
                let privKeyURL = self.keyFolderURL.appendingPathComponent("server_key_\(proto.dhFunction)")
                let pubKeyURL = self.keyFolderURL.appendingPathComponent("server_key_\(proto.dhFunction).pub")
                
                var pubKeyMaterial = [UInt8](repeating: 0, count: Int(proto.dhPublicKeySize))
                var ret = echo_load_public_key(pubKeyURL.path.cString(using: .utf8), &pubKeyMaterial, Int(proto.dhPublicKeySize))
                XCTAssertEqual(ret, 1)
                var privKeyMaterial = [UInt8](repeating: 0, count: Int(proto.dhPrivateKeySize))
                ret = echo_load_private_key(privKeyURL.path.cString(using: .utf8), &privKeyMaterial, Int(proto.dhPrivateKeySize))
                XCTAssertEqual(ret, 1)
                
                let pubKey = NoiseKey(material: Data(pubKeyMaterial), role: .public, algo: proto.keyAlgo)
                let privKey = NoiseKey(material: Data(privKeyMaterial), role: .private, algo: proto.keyAlgo)
                setup.localKeyPair = NoiseKeyPair(publicKey: pubKey, privateKey: privKey)
            }
            
            if setup.remotePublicKeyMissing {
                let pubKeyURL = self.keyFolderURL.appendingPathComponent("client_key_\(proto.dhFunction).pub")
                var pubKeyMaterial = [UInt8](repeating: 0, count: Int(proto.dhPublicKeySize))
                let ret = echo_load_public_key(pubKeyURL.path.cString(using: .utf8), &pubKeyMaterial, Int(proto.dhPublicKeySize))
                XCTAssertEqual(ret, 1)
                let pubKey = NoiseKey(material: Data(pubKeyMaterial), role: .public, algo: proto.keyAlgo)
                XCTAssertEqual(ret, 1)
                setup.remotePublicKey = pubKey
            }
            
        }
        
        XCTAssertTrue(ready)
        
        session.delegate = self
        
        
        do {
            try session.start()
        } catch {
            XCTFail("Failed to start server session")
        }
        
        clientSessions.append(session)
        
        clientHandle.readabilityHandler = { (fh) -> Void in
            session.receivingHandle?.write(fh.availableData)
        }
        
        session.sendingHandle?.readabilityHandler = { (fh) -> Void in
            clientHandle.write(fh.availableData)
        }

        
    }
    
    
    func session(_ session: NoiseSession, didReceive data: Data) {
        session.send(data)
    }
    
}
