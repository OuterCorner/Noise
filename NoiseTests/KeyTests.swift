//
//  KeyTests.swift
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class KeyTests: XCTestCase {

    func testKeyGenerator() {
        func testGeneratingKeys(for keyAlgo: NoiseKeyAlgo, length: Int) {
            let key = NoiseKeyGenerator.shared.generateKeyPair(keyAlgo)
            XCTAssertNotNil(key)
            
            XCTAssertEqual(key.publicKey.keyRole, NoiseKeyRole.public)
            XCTAssertEqual(key.publicKey.keyAlgo, keyAlgo)
            XCTAssertEqual(key.privateKey.keyRole, NoiseKeyRole.private)
            XCTAssertEqual(key.privateKey.keyAlgo, keyAlgo)
            
            XCTAssertEqual(key.privateKey.keyMaterial.count, length)
            XCTAssertEqual(key.publicKey.keyMaterial.count, length)
        }
        
        testGeneratingKeys(for: .curve25519, length: 32)
        testGeneratingKeys(for: .curve448, length: 56)
    }

    func testKeySerialization() throws {
        let key = NoiseKeyGenerator.shared.generateKeyPair(.curve448)
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: key, requiringSecureCoding: true)
        
        let rKey = try NSKeyedUnarchiver.unarchivedObject(ofClass: NoiseKeyPair.self, from: data)
        XCTAssertNotNil(rKey)
        
        XCTAssertEqual(key.publicKey.keyRole, rKey?.publicKey.keyRole)
        XCTAssertEqual(key.publicKey.keyAlgo, rKey?.publicKey.keyAlgo)
        XCTAssertEqual(key.privateKey.keyRole, rKey?.privateKey.keyRole)
        XCTAssertEqual(key.privateKey.keyAlgo, rKey?.privateKey.keyAlgo)
        
    }
}
