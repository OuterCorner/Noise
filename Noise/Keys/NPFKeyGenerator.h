//
//  NPFKeyGenerator.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPFKey.h"
#import "NPFKeyPair.h"

NS_ASSUME_NONNULL_BEGIN

/**
 You use this class to generate the keys you need.
 */
NS_SWIFT_NAME(NoiseKeyGenerator)
@interface NPFKeyGenerator : NSObject

/**
 The shared key generator.
 You should not instantiate another generator, but use this one instead.
 */
@property (class, readonly, strong) NPFKeyGenerator *sharedGenerator;

/**
 Generates a new keypair for a given algorithm.

 @param keyAlgo the algorithm to generate keys for
 @return a new keypair or nil if key algo is not supported
 */
- (NPFKeyPair *__nullable)generateKeyPair:(NPFKeyAlgo)keyAlgo;

- (NPFKey *)generateSymmetricKey:(NSUInteger)sizeInBytes;

@end

NS_ASSUME_NONNULL_END
