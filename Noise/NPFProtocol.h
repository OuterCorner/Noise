//
//  NPFProtocol.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPFKey.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a specific noise protocol.
 */
NS_SWIFT_NAME(NoiseProtocol)
@interface NPFProtocol : NSObject

/**
 You create an instance of this class by passing in the name of the desired protocol
 has specified in the Noise Protocol Framework.
 Examples:
    * Noise_XX_25519_AESGCM_SHA256
    * Noise_N_25519_ChaChaPoly_BLAKE2s
    * Noise_IK_448_ChaChaPoly_BLAKE2b

 @param name The name of the protocol.
 @return A new protocol instance or nil if the protocol isn't supported.
 */
- (nullable instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

/** The name of the handshake pattern, e.g.: XX, IK, NN, etc */
@property (strong, readonly) NSString *handshakePattern;

/** The DH function name, e.g.: 25519, 448 */
@property (strong, readonly) NSString *dhFunction;

/** The DH function name, e.g.: 25519, 448 (this is the same as dhFunction) */
@property (strong, readonly) NPFKeyAlgo keyAlgo;

/** The cipher function name, e.g.: AESGCM, ChaChaPoly */
@property (strong, readonly) NSString *cipherFunction;

/** The hash function name, e.g.: SHA256, BLAKE2s */
@property (strong, readonly) NSString *hashFunction;

/** The hash length in bytes */
@property (readonly) NSUInteger hashLength;

/** The public key size for the underlying dh function */
@property (readonly) NSUInteger dhPublicKeySize;

/** The private key size for the underlying dh function */
@property (readonly) NSUInteger dhPrivateKeySize;

@end

NS_ASSUME_NONNULL_END
