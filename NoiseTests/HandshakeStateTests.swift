//
//  HandshakeStateTests.swift
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class HandshakeStateTests: XCTestCase {

    func testInitializer() {
        let p = NoiseProtocol(name: "Noise_XX_25519_AESGCM_SHA256")!
        let handshake = NoiseHandshakeState(with: p, role: .initiator)
        
        XCTAssertEqual(handshake.protocol, p)
        XCTAssertEqual(handshake.role, .initiator)
    }

    func testHandshakePrologSetup() {
        let p = NoiseProtocol(name: "Noise_XX_25519_AESGCM_SHA256")!
        let handshake = NoiseHandshakeState(with: p, role: .initiator)
        
        handshake.setPrologue("outer corner".data(using: .utf8)!)
    }
    
    
    func testHandshakePSKSetup() {
        var p = NoiseProtocol(name: "Noise_XX_25519_AESGCM_SHA256")!
        var handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertFalse(handshake.preSharedKeyMissing)
        
        p = NoiseProtocol(name: "NoisePSK_XX_25519_AESGCM_SHA256")!
        handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertTrue(handshake.preSharedKeyMissing)
        
        let psk = NoiseKeyGenerator.shared.generateSymmetricKey(32)
        handshake.setPreSharedKey(psk)
        XCTAssertFalse(handshake.preSharedKeyMissing)        
    }
    
    func testHandshakeLocalKeyPairSetup() {
        var p = NoiseProtocol(name: "Noise_NN_25519_AESGCM_SHA256")!
        var handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertFalse(handshake.localKeyPairMissing)
        
        p = NoiseProtocol(name: "Noise_XX_25519_AESGCM_SHA256")!
        handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertTrue(handshake.localKeyPairMissing)
        
        let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519)
        handshake.localKeyPair = keyPair;
        XCTAssertFalse(handshake.localKeyPairMissing)
        
        XCTAssertEqual(keyPair.privateKey.keyMaterial, handshake.localKeyPair?.privateKey.keyMaterial)
        XCTAssertEqual(keyPair.publicKey.keyMaterial, handshake.localKeyPair?.publicKey.keyMaterial)
        XCTAssertEqual(keyPair.privateKey.keyAlgo, handshake.localKeyPair?.privateKey.keyAlgo)
        XCTAssertEqual(keyPair.publicKey.keyAlgo, handshake.localKeyPair?.publicKey.keyAlgo)
        XCTAssertEqual(keyPair.privateKey.keyRole, handshake.localKeyPair?.privateKey.keyRole)
        XCTAssertEqual(keyPair.publicKey.keyRole, handshake.localKeyPair?.publicKey.keyRole)
    }
    
    func testRemotePublicKeySetup() {
        var p = NoiseProtocol(name: "Noise_NN_25519_AESGCM_SHA256")!
        var handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertFalse(handshake.remotePublicKeyMissing)
        
        p = NoiseProtocol(name: "Noise_KK_25519_AESGCM_SHA256")!
        handshake = NoiseHandshakeState(with: p, role: .initiator)
        XCTAssertTrue(handshake.remotePublicKeyMissing)
        
        let keyPair = NoiseKeyGenerator.shared.generateKeyPair(.curve25519)
        let pubKey = keyPair.publicKey;
        handshake.remotePublicKey = pubKey;
        XCTAssertFalse(handshake.remotePublicKeyMissing)
        
        XCTAssertEqual(pubKey.keyMaterial, handshake.remotePublicKey?.keyMaterial)
        XCTAssertEqual(pubKey.keyAlgo, handshake.remotePublicKey?.keyAlgo)
        XCTAssertEqual(pubKey.keyRole, handshake.remotePublicKey?.keyRole)
    }
}
