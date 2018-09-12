//
//  NFKeyPair.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFKeyPair.h"

@implementation NFKeyPair

- (instancetype)initWithPublicKey:(NFKey *)publicKey privateKey:(NFKey *)privateKey
{
    self = [super init];
    if (self) {
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

@end
