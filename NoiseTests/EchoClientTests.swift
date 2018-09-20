//
//  EchoClientTests.swift
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class EchoClientTests: XCTestCase, StreamDelegate, NoiseSessionDelegate {

    let didReceiveEchoNotification = Notification.Name("didReceiveEchoNotification")
    let didReceiveSessionEstablishedNotification = Notification.Name("didReceiveSessionEstablishedNotification")
    let notificationHanshakeKey = "hs"
    
    let serverHost = "localhost"
    let serverPort = 7000
    
    var serverProcess: Process?
    var fromServerStream: InputStream?
    var toServerStream: OutputStream?
    var tcpStreamEstablished: XCTestExpectation?
    
    var currentSession: NoiseSession?
    
    override func setUp() {
        continueAfterFailure = false
        // run the server
        let serverExecutableURL = Bundle(for: EchoClientTests.self).url(forAuxiliaryExecutable: "echo-server")!
        let keyFolderURL = Bundle(for: EchoClientTests.self).url(forResource: "keys", withExtension: nil)!
        serverProcess = Process()
        serverProcess!.launchPath = serverExecutableURL.path
        serverProcess!.arguments = ["-k", keyFolderURL.path, "\(serverPort)"]
        serverProcess!.launch()
        
        Stream.getStreamsToHost(withName: serverHost, port: serverPort, inputStream: &fromServerStream, outputStream: &toServerStream)
        XCTAssertNotNil(fromServerStream)
        XCTAssertNotNil(toServerStream)
        
        fromServerStream!.delegate = self
        fromServerStream?.schedule(in: RunLoop.current, forMode: .default)
        
        tcpStreamEstablished = expectation(description: "TCP connect")
        
        fromServerStream?.open()
        toServerStream?.open()
        
        wait(for: [tcpStreamEstablished!], timeout: 10.0)
        
    }

    override func tearDown() {
        // stop the server
        serverProcess?.terminate()
        serverProcess = nil
        toServerStream = nil
        fromServerStream = nil
    }

    func testNN() {
        currentSession = NoiseSession(protocolName: "Noise_NN_25519_AESGCM_SHA256", role: .initiator)
        currentSession?.delegate = self
        XCTAssertNotNil(currentSession)
        
        currentSession?.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        
        startSessionAndEstablishConnection()
        exchangeMessages()
        stopSession()
    }

    func testNX() {
        currentSession = NoiseSession(protocolName: "Noise_NX_448_ChaChaPoly_BLAKE2b", role: .initiator)
        currentSession!.delegate = self
        XCTAssertNotNil(currentSession)
        
        let ready = currentSession!.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        XCTAssertTrue(ready)
        
        let remotePublicKeyExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self) { (note) -> Bool in
            guard let handshake = note.userInfo?[self.notificationHanshakeKey] as? NoiseHandshakeState else {
                return false
            }
            return handshake.remotePublicKey != nil
        }
        startSessionAndEstablishConnection()
        wait(for: [remotePublicKeyExpectation], timeout: 2.0)
        exchangeMessages()
        stopSession()
    }

    func testXX() {
        currentSession = NoiseSession(protocolName: "Noise_XX_448_AESGCM_SHA512", role: .initiator)
        currentSession!.delegate = self
        XCTAssertNotNil(currentSession)
        
        var ready = currentSession!.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            setup.localKeyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve448)
        }
        XCTAssertTrue(ready)
        
        let remotePublicKeyExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self) { (note) -> Bool in
            guard let handshake = note.userInfo?[self.notificationHanshakeKey] as? NoiseHandshakeState else {
                return false
            }
            return handshake.remotePublicKey != nil
        }
        startSessionAndEstablishConnection()
        wait(for: [remotePublicKeyExpectation], timeout: 2.0)
        exchangeMessages()
        stopSession()
    }
    
    func testNK() {
        currentSession = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_BLAKE2s", role: .initiator)
        currentSession!.delegate = self
        XCTAssertNotNil(currentSession)
        
        var ready = currentSession!.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            guard let remotePublicKeyURL = Bundle(for: EchoClientTests.self).url(forResource: "keys/server_key_25519", withExtension: "pub") else {
                XCTFail("Could not find server public key")
                return
            }
            var keyMaterial = [UInt8](repeating: 0, count: 32)
            let ret = echo_load_public_key(remotePublicKeyURL.path.cString(using: .utf8), &keyMaterial, 32)
            XCTAssertEqual(ret, 1)
            setup.remotePublicKey = NoiseKey(material: Data(keyMaterial), role: NoiseKeyRole.public, algo: NoiseKeyAlgo.curve25519)
        }
        XCTAssertTrue(ready)
        
        let remotePublicKeyExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self) { (note) -> Bool in
            guard let handshake = note.userInfo?[self.notificationHanshakeKey] as? NoiseHandshakeState else {
                return false
            }
            return handshake.remotePublicKey != nil
        }
        startSessionAndEstablishConnection()
        wait(for: [remotePublicKeyExpectation], timeout: 2.0)
        exchangeMessages()
        stopSession()
    }
    
    
    func testXK() {
        currentSession = NoiseSession(protocolName: "Noise_XK_25519_ChaChaPoly_BLAKE2s", role: .initiator)
        currentSession!.delegate = self
        XCTAssertNotNil(currentSession)
        
        var ready = currentSession!.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            setup.localKeyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519)
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            guard let remotePublicKeyURL = Bundle(for: EchoClientTests.self).url(forResource: "keys/server_key_25519", withExtension: "pub") else {
                XCTFail("Could not find server public key")
                return
            }
            var keyMaterial = [UInt8](repeating: 0, count: 32)
            let ret = echo_load_public_key(remotePublicKeyURL.path.cString(using: .utf8), &keyMaterial, 32)
            XCTAssertEqual(ret, 1)
            setup.remotePublicKey = NoiseKey(material: Data(keyMaterial), role: NoiseKeyRole.public, algo: NoiseKeyAlgo.curve25519)
        }
        XCTAssertTrue(ready)
        
        let remotePublicKeyExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self) { (note) -> Bool in
            guard let handshake = note.userInfo?[self.notificationHanshakeKey] as? NoiseHandshakeState else {
                return false
            }
            return handshake.remotePublicKey != nil
        }
        startSessionAndEstablishConnection()
        wait(for: [remotePublicKeyExpectation], timeout: 2.0)
        exchangeMessages()
        stopSession()
    }
    
    func testKK() {
        currentSession = NoiseSession(protocolName: "Noise_KK_25519_ChaChaPoly_BLAKE2s", role: .initiator)
        currentSession!.delegate = self
        XCTAssertNotNil(currentSession)
        
        var ready = currentSession!.setup { (setup) in
            setup.setPrologue(self.echoProtocolIdAsData(for: self.currentSession!))
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            guard let clientPublicKeyURL = Bundle(for: EchoClientTests.self).url(forResource: "keys/client_key_25519", withExtension: "pub"),
                let clientPrivateKeyURL = Bundle(for: EchoClientTests.self).url(forResource: "keys/client_key_25519", withExtension: nil) else {
                    XCTFail("Could not find client keys")
                    return
            }
            var pubKeyMaterial = [UInt8](repeating: 0, count: 32)
            var ret = echo_load_public_key(clientPublicKeyURL.path.cString(using: .utf8), &pubKeyMaterial, 32)
            XCTAssertEqual(ret, 1)
            var privKeyMaterial = [UInt8](repeating: 0, count: 32)
            ret = echo_load_private_key(clientPrivateKeyURL.path.cString(using: .utf8), &privKeyMaterial, 32)
            XCTAssertEqual(ret, 1)
            
            let pubKey = NoiseKey(material: Data(pubKeyMaterial), role: .public, algo: .curve25519)
            let privKey = NoiseKey(material: Data(privKeyMaterial), role: .private, algo: .curve25519)
            setup.localKeyPair = NoiseKeyPair(publicKey: pubKey, privateKey: privKey)
        }
        XCTAssertFalse(ready)
        ready = currentSession!.setup { (setup) in
            guard let remotePublicKeyURL = Bundle(for: EchoClientTests.self).url(forResource: "keys/server_key_25519", withExtension: "pub") else {
                XCTFail("Could not find server public key")
                return
            }
            var keyMaterial = [UInt8](repeating: 0, count: 32)
            let ret = echo_load_public_key(remotePublicKeyURL.path.cString(using: .utf8), &keyMaterial, 32)
            XCTAssertEqual(ret, 1)
            setup.remotePublicKey = NoiseKey(material: Data(keyMaterial), role: NoiseKeyRole.public, algo: NoiseKeyAlgo.curve25519)
        }
        XCTAssertTrue(ready)
        
        let remotePublicKeyExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self) { (note) -> Bool in
            guard let handshake = note.userInfo?[self.notificationHanshakeKey] as? NoiseHandshakeState else {
                return false
            }
            return handshake.remotePublicKey != nil
        }
        startSessionAndEstablishConnection()
        wait(for: [remotePublicKeyExpectation], timeout: 2.0)
        exchangeMessages()
        stopSession()
    }
    
    // MARK: - NoiseSession delegate
    
    func sessionWillStart(_ session: NoiseSession) {
        write(data: echoProtocolIdAsData(for: session), to: toServerStream!)
    }
    
    
    func session(_ session: NoiseSession, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to parse server response")
            return
        }
        
        NotificationCenter.default.post(name: didReceiveEchoNotification, object: self, userInfo: ["text": string])
    }
    
    func session(_ session: NoiseSession, handshakeComplete handshakeState: NoiseHandshakeState) {
        NotificationCenter.default.post(name: didReceiveSessionEstablishedNotification,
                                        object: self,
                                        userInfo: [notificationHanshakeKey: handshakeState])
    }
    
    var sessionDidStopExpectation: XCTestExpectation?
    func sessionDidStop(_ session: NoiseSession, error: Error?) {
        sessionDidStopExpectation?.fulfill()
    }
    
    // MARK: - Stream delegate
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            while(fromServerStream?.hasBytesAvailable ?? false) {
                var buffer = [UInt8](repeating: 0, count: 1024)
                let bytesRead = fromServerStream!.read(&buffer, maxLength: buffer.count)
                if (bytesRead > 0) {
                    let data = Data(bytes: &buffer, count: bytesRead)
                    currentSession?.receivingHandle?.write(data)
                }
                
            }
        case Stream.Event.openCompleted:
            tcpStreamEstablished?.fulfill()
            break;
        default:
            break;
        }
    }
    
    
    // MARK: - Aux
    
    func write(data: Data, to outStream: OutputStream) {
        var bytesToSend = data.count
        
        while bytesToSend > 0 {
            let bytesSent = data.count - bytesToSend
            let buff = [UInt8](data.advanced(by: bytesSent))
            let sentBytes = toServerStream!.write(buff, maxLength: bytesToSend)
            if (sentBytes >= 0) {
                bytesToSend -= sentBytes
            }
            else {
                XCTFail("Failed to write to server")
                return
            }
        }
    }
    
    func echoProtocolIdAsData(for session: NoiseSession) -> Data {
        var echoProtoId = EchoProtocolId()
        XCTAssertEqual(echo_get_protocol_id(&echoProtoId, "\(session.protocol)"), 1)
        
        let echoProtoData = Data(bytes: &echoProtoId, count: MemoryLayout<EchoProtocolId>.size)
        return echoProtoData
    }
    
    func startSessionAndEstablishConnection() {
        do {
            try currentSession!.start()
        }
        catch {
            XCTFail("Failed to start noise session \(error)")
            return
        }
        
        
        currentSession!.sendingHandle?.readabilityHandler = { [weak self] fh -> Void in
            guard let sSelf = self else {
                return
            }
            sSelf.write(data: fh.availableData, to: sSelf.toServerStream!)
        }
        
        let establishedExpectation = keyValueObservingExpectation(for: currentSession!, keyPath: "state", expectedValue: NoiseSessionState.established.rawValue)
        let establishedNotificationExpectation = expectation(forNotification: didReceiveSessionEstablishedNotification, object: self, handler: nil)
        wait(for: [establishedExpectation, establishedNotificationExpectation], timeout: 50.0)
    }
    
    func exchangeMessages() {
        var text = "Hello World\n";
        currentSession?.send(text.data(using: .utf8)!)
        
        var echoResponse = expectation(forNotification: didReceiveEchoNotification, object: self) { (note) -> Bool in
            guard let receivedText = note.userInfo?["text"] as? String else {
                return false
            }
            return text == receivedText
        }
        
        wait(for: [echoResponse], timeout: 2.0)
        
        text = "All Noise messages are less than or equal to 65535 bytes in length.\n";
        currentSession?.send(text.data(using: .utf8)!)
        
        echoResponse = expectation(forNotification: didReceiveEchoNotification, object: self) { (note) -> Bool in
            guard let receivedText = note.userInfo?["text"] as? String else {
                return false
            }
            return text == receivedText
        }
        
        wait(for: [echoResponse], timeout: 2.0)
    }
    
    func stopSession(){
        sessionDidStopExpectation = expectation(description: "Session stopped")
        currentSession!.stop()
        
        wait(for: [sessionDidStopExpectation!], timeout: 1.0)
    }
}


extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x ", $1)}
    }
}
