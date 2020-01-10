//
//  NoiseProtocol.swift
//  Noise
//
//  Created by Developer on 09/01/2020.
//  Copyright © 2020 Outer Corner. All rights reserved.
//

import Foundation
import CNoise

public enum NoiseProtocolError: Error {
    case invalidProtocol
    case unsuportedProtocol
}

/**
Represents a specific noise protocol.
*/
@objcMembers
@objc(NPFProtocol)
public class NoiseProtocol: NSObject {
    
    public let protocolId: UnsafePointer<NoiseProtocolId>
    
    /// You create an instance of this class by passing in the name of the desired protocol
    /// has specified in the Noise Protocol Framework.
    /// Examples:
    ///  * Noise_XX_25519_AESGCM_SHA256
    ///  * Noise_N_25519_ChaChaPoly_BLAKE2s
    ///  * Noise_IK_448_ChaChaPoly_BLAKE2b
    /// - Parameter name: The name of the protocol
    public init?(name: String) {
        guard let nameData = name.data(using: .utf8) else {
            return nil
        }
        
        let mutableProtoId = UnsafeMutablePointer<NoiseProtocolId>.allocate(capacity: 1)
        do {
            
            try nameData.withUnsafeBytes { (rawBufferPtr) throws -> Void in
                guard let namePtr = rawBufferPtr.bindMemory(to: Int8.self).baseAddress else {
                    throw NoiseProtocolError.invalidProtocol
                }
                
                let ret = noise_protocol_name_to_id(mutableProtoId, namePtr, nameData.count)
                let noiseError = CNoiseErrorCode(rawValue: ret)
                guard noiseError == CNoiseErrorNone else {
                    if noiseError == CNoiseErrorUnknownName {
                        throw NoiseProtocolError.unsuportedProtocol
                    }
                    else {
                        throw NoiseProtocolError.invalidProtocol
                    }
                }
            }
        } catch {
            mutableProtoId.deallocate()
            return nil
        }

        self.protocolId = UnsafePointer(mutableProtoId)
        
    }
    
    deinit {
        protocolId.deallocate()
    }
    
    /** The name of the handshake pattern, e.g.: XX, IK, NN, etc */
    @objc
    public var handshakePattern: String {
        let name = noise_id_to_name(CNoisePatternCategory.rawValue, protocolId.pointee.pattern_id)!
        return String(cString: name)
    }
    
    /** The DH function name, e.g.: 25519, 448 */
    public var dhFunction: String {
        if protocolId.pointee.hybrid_id == 0 {
            let name = noise_id_to_name(CNoiseDHCategory.rawValue, protocolId.pointee.dh_id)!
            return String(cString: name)
        }
        else {
            /*Format the DH names as "dh_id+hybrid_id"; e.g. "25519+NewHope" */
            let name = noise_id_to_name(CNoiseDHCategory.rawValue, protocolId.pointee.dh_id)!
            let hybridName = noise_id_to_name(CNoiseDHCategory.rawValue, protocolId.pointee.hybrid_id)!
            return "\(String(cString: name))+\(String(cString: hybridName))"
        }
    }
    
    /** The DH function name, e.g.: 25519, 448 (this is the same as dhFunction) */
    public var keyAlgo: NoiseKeyAlgo {
        return NoiseKeyAlgo(rawValue: self.dhFunction)
    }
    
    /** The cipher function name, e.g.: AESGCM, ChaChaPoly */
    public var cipherFunction: String {
        let name = noise_id_to_name(CNoiseCipherCategory.rawValue, protocolId.pointee.cipher_id)!
        return String(cString: name)
    }
    
    /** The hash function name, e.g.: SHA256, BLAKE2s */
    public var hashFunction: String {
        let name = noise_id_to_name(CNoiseHashCategory.rawValue, protocolId.pointee.hash_id)!
        return String(cString: name)
    }
    
    /** The hash length in bytes */
    public var hashLength: UInt {
        var hashState: OpaquePointer? = nil
        noise_hashstate_new_by_id(&hashState, protocolId.pointee.hash_id)
        let length = noise_hashstate_get_hash_length(hashState)
        noise_hashstate_free(hashState)
        return UInt(length)
    }
    
    /** The public key size for the underlying dh function */
    public var dhPublicKeySize: UInt {
        var dhState: OpaquePointer? = nil
        noise_dhstate_new_by_id(&dhState, protocolId.pointee.dh_id)
        let length = noise_dhstate_get_public_key_length(dhState)
        noise_dhstate_free(dhState)
        return UInt(length)
    }
    
    /** The private key size for the underlying dh function */
    public var dhPrivateKeySize: UInt {
        var dhState: OpaquePointer? = nil
        noise_dhstate_new_by_id(&dhState, protocolId.pointee.dh_id)
        let length = noise_dhstate_get_private_key_length(dhState)
        noise_dhstate_free(dhState)
        return UInt(length)
    }

    override public var description: String {
        let maxProtoNameLength = Int(NOISE_MAX_PROTOCOL_NAME)
        let cName = UnsafeMutablePointer<Int8>.allocate(capacity: maxProtoNameLength)
        cName.initialize(to: 0)
        noise_protocol_id_to_name(cName, maxProtoNameLength, protocolId)
        let name = cName.withMemoryRebound(to: UInt8.self, capacity: maxProtoNameLength) { (uint8Ptr) -> String in
            return String(cString: uint8Ptr)
        }
        cName.deallocate()
        return name
    }
}
