//
//  NPFKeyPair.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPFKey.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseKeyPair)
@interface NPFKeyPair : NSObject <NSSecureCoding>

- (instancetype)initWithPublicKey:(NPFKey *)publicKey privateKey:(NPFKey *)privateKey;

@property (strong) NPFKey *publicKey;
@property (strong) NPFKey *privateKey;

@end

NS_ASSUME_NONNULL_END
