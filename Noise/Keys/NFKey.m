//
//  NFKey.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFKey+Package.h"

NFKeyAlgo const NFKeyAlgoCurve25519   = @"25519";
NFKeyAlgo const NFKeyAlgoCurve448     = @"448";


@implementation NFKey

+ (instancetype)keyWithMaterial:(NSData *)material role:(NFKeyRole)role algo:(NFKeyAlgo)algo
{
    return [[self alloc] initWithKeyMaterial:material role:role algo:algo];
}

- (instancetype)initWithKeyMaterial:(NSData *)material role:(NFKeyRole)role algo:(NFKeyAlgo)algo
{
    self = [super init];
    if (self) {
        _keyMaterial = [material copy];
        _keyRole = role;
        _keyAlgo = algo;
    }
    return self;
}

@end
