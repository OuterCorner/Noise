//
//  NFKeyPair.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFKey.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseKeyPair)
@interface NFKeyPair : NSObject

- (instancetype)initWithPublicKey:(NFKey *)publicKey privateKey:(NFKey *)privateKey;

@property (strong) NFKey *publicKey;
@property (strong) NFKey *privateKey;

@end

NS_ASSUME_NONNULL_END
