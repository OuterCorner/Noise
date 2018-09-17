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
        
        wait(for: [establishedExpectation], timeout: 3000.0)
        
        let text = "Hello World\n";
        currentSession?.send(text.data(using: .utf8)!)
        
        let echoResponse = expectation(forNotification: didReceiveEchoNotification, object: self) { (note) -> Bool in
            guard let receivedText = note.userInfo?["text"] as? String else {
                return false
            }
            return text == receivedText
        }
        
        wait(for: [echoResponse], timeout: 3000.0)
        
    }

    func testXX() {
        
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
}


extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x ", $1)}
    }
}
