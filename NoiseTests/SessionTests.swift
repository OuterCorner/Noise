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
    }

    func testSetup() {
        let session = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator)!
        
        var ready = session.setup { (setup) in }
        XCTAssertFalse(ready)
        
        ready = session.setup { (setup) in
            let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519)
            let pubKey = keyPair.publicKey;
            setup.remotePublicKey = pubKey;
        }
        XCTAssertTrue(ready)
    }
    
    func testStart() {
        let session = NoiseSession(protocolName: "Noise_NK_25519_AESGCM_SHA256", role: .initiator)!
        
        XCTAssertThrowsError(try session.start(), "Failed to throw on") { (error) in
            if let nfError = error as? NFError, nfError.code == NFError.sessionNotSetupError {
                // OK!
            }
            else {
                XCTFail("Unexpected error thrown \(error)")
            }
        }
        session.setup { (setup) in }
        
        XCTAssertThrowsError(try session.start(), "Failed to throw on") { (error) in
            if let nfError = error as? NFError, nfError.code == NFError.sessionNotReadyError {
                // OK!
            }
            else {
                XCTFail("Unexpected error thrown \(error)")
            }
        }
        
        session.setup { (setup) in
            let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519)
            let pubKey = keyPair.publicKey;
            setup.remotePublicKey = pubKey;
        }
        
        let delegate = NoiseSessionStubDelegate()
        
        delegate.didStartExpectation = expectation(description: "DidStart")
        delegate.handshakeExpectation = expectation(description: "Handshake")
        // being the initiator the "e" should have been written to sending
        delegate.expectedHandshakeSendingPatterns = ["e,es"]
        session.delegate = delegate
        
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
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

}

class NoiseSessionStubDelegate: NSObject, NoiseSessionDelegate {
    
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
}
