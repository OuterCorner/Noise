//
//  SessionTests.swift
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class SessionTests: XCTestCase {

    func testInitialization() {
        let s1 = NoiseSession(protocolName: "LOREM_IPSUM", role: .initiator)
        XCTAssertNil(s1)
        
        let s2 = NoiseSession(protocolName: "Noise_XX_25519_AESGCM_SHA256", role: .initiator)
        XCTAssertNotNil(s2)
        
        let p = NoiseProtocol(name: "Noise_IK_448_ChaChaPoly_BLAKE2b")!
        let s3 = NoiseSession(with: p, role: .responder)
        XCTAssertNotNil(s3)
        
        let s4 = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator) { setup in
            guard let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519) else {
                XCTFail("Failed to generate \(NoiseKeyAlgo.curve25519) key pair")
                return
            }
            let pubKey = keyPair.publicKey;
            setup.remotePublicKey = pubKey
        }
        XCTAssertNotNil(s4)
        XCTAssertTrue(s4!.isReady)
    }

    func testSetup() {
        let session = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator)!
        
        var ready = session.setup { (setup) in }
        XCTAssertFalse(ready)
        
        ready = session.setup { (setup) in
            guard let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519) else {
                XCTFail("Failed to generate \(NoiseKeyAlgo.curve25519) key pair")
                return
            }
            let pubKey = keyPair.publicKey;
            setup.remotePublicKey = pubKey;
        }
        XCTAssertTrue(ready)
    }
    
    func testStart() {
        let session = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator)!
        
        XCTAssertThrowsError(try session.start(), "Failed to throw on") { (error) in
            if let nfError = error as? NPFError, nfError.code == NPFError.sessionNotSetupError {
                // OK!
            }
            else {
                XCTFail("Unexpected error thrown \(error)")
            }
        }
        session.setup { (setup) in }
        
        XCTAssertThrowsError(try session.start(), "Failed to throw on") { (error) in
            if let nfError = error as? NPFError, nfError.code == NPFError.sessionNotReadyError {
                // OK!
            }
            else {
                XCTFail("Unexpected error thrown \(error)")
            }
        }
        
        session.setup { (setup) in
            guard let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519) else {
                XCTFail("Failed to generate \(NoiseKeyAlgo.curve25519) key pair")
                return
            }
            let pubKey = keyPair.publicKey;
            setup.remotePublicKey = pubKey;
        }
        
        let delegate = NoiseSessionStubDelegate()
        
        delegate.didStartExpectation = expectation(description: "DidStart")
        delegate.handshakeExpectation = expectation(description: "Handshake")
        // being the initiator the "e" should have been written to sending
        delegate.expectedHandshakeSendingPatterns = ["e,es"]
        session.delegate = delegate
        
        keyValueObservingExpectation(for: session, keyPath: "state", expectedValue:  NoiseSessionState.handshaking.rawValue)
        
        XCTAssertNoThrow(try session.start())
        
        XCTAssertNotNil(session.sendingHandle)
        XCTAssertNotNil(session.receivingHandle)
        
        waitForExpectations(timeout: 2.0, handler: nil)
        
        let p = NSPredicate { (b, bindings) -> Bool in
            guard let fh = b as? FileHandle else {
                return false
            }
            return fh.availableData.count > 0
        }
        
        expectation(for: p, evaluatedWith: session.sendingHandle ?? NSNull(), handler: nil)
        
        waitForExpectations(timeout: 2.0, handler: nil)
        
        delegate.didStopExpectation = expectation(description: "DidStop")
        keyValueObservingExpectation(for: session, keyPath: #keyPath(NoiseSession.state), expectedValue: NoiseSessionState.stopped.rawValue)
        session.stop()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testMaxMessageSize() {
        let session = NoiseSession(protocolName: "Noise_NN_25519_AESGCM_SHA256", role: .initiator)!
        
        XCTAssertEqual(session.maxMessageSize, 65535)
        
        XCTAssertThrowsError(try ObjC.catchException{session.maxMessageSize = 70000}, "Exception should have been thrown") { (error) in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "BridgedException")
            XCTAssertEqual(nsError.userInfo["name"] as? String, NSExceptionName.invalidArgumentException.rawValue)
            XCTAssertEqual(nsError.userInfo["reason"] as? String, "maxMessageSize (70000) must be less than 65535.")
        }
        
        XCTAssertThrowsError(try ObjC.catchException{session.maxMessageSize = 2}, "Exception should have been thrown") { (error) in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "BridgedException")
            XCTAssertEqual(nsError.userInfo["name"] as? String, NSExceptionName.invalidArgumentException.rawValue)
            XCTAssertEqual(nsError.userInfo["reason"] as? String, "maxMessageSize (2) must be greater than 18.")
        }
        
        session.maxMessageSize = 100
        
        // now lets setup a client-server session
        // and make sure messages over 100 bytes are split
        let serverSession = NoiseSession(protocolName: "Noise_NN_25519_AESGCM_SHA256", role: .responder)!
        
        session.setup { (setup) in
            // nothing
        }
        
        serverSession.setup { (setup) in
            // nothing
        }
        let serverSessionDelegate = NoiseSessionStubDelegate()
        serverSession.delegate = serverSessionDelegate
        
        let establishedExpectation = keyValueObservingExpectation(for: session, keyPath: "state") { (object, change) -> Bool in
            return session.state == NoiseSessionState.established
        }
        XCTAssertNoThrow(try session.start())
        XCTAssertNoThrow(try serverSession.start())
        
        XCTAssertNotNil(session.sendingHandle)
        XCTAssertNotNil(session.receivingHandle)
        XCTAssertNotNil(serverSession.sendingHandle)
        XCTAssertNotNil(serverSession.receivingHandle)
        
        session.sendingHandle!.readabilityHandler = { fh in
            serverSession.receivingHandle!.write(fh.availableData)
        }
        serverSession.sendingHandle!.readabilityHandler = { fh in
            session.receivingHandle!.write(fh.availableData)
        }
        
        wait(for: [establishedExpectation], timeout: 1.0)
        
        
        func testSending(data: Data, expectedMessageCount: Int) {
            let receivedData = NSMutableData() // we actually need this to be an object-type vs a value type to be used in the NSPredicate expectation below
            var messagesReceived = 0
            
            let receivedDataObserver = NotificationCenter.default.addObserver(forName: NoiseSessionStubDelegate.didReceiveDataNotificationName, object: serverSessionDelegate, queue: OperationQueue.main) { (note) in
                guard let data = note.userInfo?["data"] as? Data else {
                    XCTFail("Notification is missing data")
                    return
                }
                receivedData.append(data)
                messagesReceived += 1
            }
            
            session.send(data) // message data should be split in two packets
            
            let expect1 = expectation(for: NSPredicate(format: "SELF == %@", argumentArray: [data]), evaluatedWith: receivedData, handler: nil)
            
            wait(for: [expect1], timeout: 2)
            
            XCTAssertEqual(data, receivedData as Data)
            XCTAssertEqual(messagesReceived, expectedMessageCount)
            NotificationCenter.default.removeObserver(receivedDataObserver)
        }
        
        func randomData(of size: Int) -> Data {
            var data = Data(count: size)
            let res = data.withUnsafeMutableBytes { (bytes) -> OSStatus in
                return SecRandomCopyBytes(kSecRandomDefault, size, bytes)
            }
            XCTAssertEqual(res, errSecSuccess)
            return data
        }
        
        testSending(data: randomData(of: 50), expectedMessageCount: 1)
        testSending(data: randomData(of: 100), expectedMessageCount: 2)
        testSending(data: randomData(of: 132), expectedMessageCount: 2)
        testSending(data: randomData(of: 246), expectedMessageCount: 3)
        testSending(data: randomData(of: 247), expectedMessageCount: 4)
    }
    
}

fileprivate class NoiseSessionStubDelegate: NSObject, NoiseSessionDelegate {
    
    var didStartExpectation: XCTestExpectation?
    func sessionDidStart(_ session: NoiseSession) {
        didStartExpectation?.fulfill()
    }
    
    var handshakeExpectation: XCTestExpectation?
    var expectedHandshakeSendingPatterns: [String] = []
    func session(_ session: NoiseSession, willSendHandshakeMessagePattern pattern: String) -> Data? {
        if let expectation = handshakeExpectation {
            let p = expectedHandshakeSendingPatterns.first
            XCTAssertEqual(p, pattern)
            expectedHandshakeSendingPatterns.removeFirst()
            
            if expectedHandshakeSendingPatterns.count == 0 {
                expectation.fulfill()
            }
        }
        
        return nil
    }
    
    var didStopExpectation: XCTestExpectation?
    func sessionDidStop(_ session: NoiseSession, error: Error?) {
        didStopExpectation?.fulfill()
    }
    
    static let didReceiveDataNotificationName = Notification.Name("NoiseSessionDelegateDidReceiveData")
    func session(_ session: NoiseSession, didReceive data: Data) {
        NotificationCenter.default.post(name: NoiseSessionStubDelegate.didReceiveDataNotificationName, object: self, userInfo: ["data": data])
    }
}
