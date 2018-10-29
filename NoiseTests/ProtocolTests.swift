//
//  ProtocolTests.swift
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class ProtocolTests: XCTestCase {

    func testInitialization() {
        let p = NoiseProtocol(name: "Noise_XX_25519_AESGCM_SHA256")
        XCTAssertNotNil(p);
        
        let nilP = NoiseProtocol(name: "Make_Some_Noise")
        XCTAssertNil(nilP);
    }
    
    func testAccessors() {
        if let p = NoiseProtocol(name: "Noise_IK_448_ChaChaPoly_BLAKE2b") {
            XCTAssertEqual(p.handshakePattern, "IK")
            XCTAssertEqual(p.dhFunction, "448")
            XCTAssertEqual(p.cipherFunction, "ChaChaPoly")
            XCTAssertEqual(p.hashFunction, "BLAKE2b")
            XCTAssertEqual(p.hashLength, 64)
        }
        else {
            XCTFail("Failed to initialize noise protocol")
        }
    }
    
    func testDescription(){
        if let p = NoiseProtocol(name: "Noise_N_25519_ChaChaPoly_BLAKE2s") {
            XCTAssertEqual("\(p)", "Noise_N_25519_ChaChaPoly_BLAKE2s")
        }
        else {
            XCTFail("Failed to initialize noise protocol")
        }
    }

}
