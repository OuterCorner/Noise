//
//  NFKeyGenerator.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFKey.h"
#import "NFKeyPair.h"

NS_ASSUME_NONNULL_BEGIN

/**
 You use this class to generate the keys you need.
 */
NS_SWIFT_NAME(NoiseKeyGenerator)
@interface NFKeyGenerator : NSObject

/**
 The shared key generator.
 You should not instantiate another generator, but use this one instead.
 */
@property (class, readonly, strong) NFKeyGenerator *sharedGenerator;

/**
 Generates a new keypair for a given algorithm.

 @param keyAlgo the algorithm to generate keys for
 @return a new keypair or nil if key algo is not supported
 */
- (NFKeyPair *)generateKeyPair:(NFKeyAlgo)keyAlgo;

- (NFKey *)generateSymmetricKey:(NSUInteger)sizeInBytes;

@end

NS_ASSUME_NONNULL_END
