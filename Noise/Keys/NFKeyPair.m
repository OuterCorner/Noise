//
//  NFKeyPair.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFKeyPair.h"

static NSString *const kPublicKeyCodingKey = @"pub";
static NSString *const kPrivateKeyCodingKey = @"priv";

@implementation NFKeyPair

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithPublicKey:(NFKey *)publicKey privateKey:(NFKey *)privateKey
{
    self = [super init];
    if (self) {
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _publicKey = [aDecoder decodeObjectOfClass:[NFKey class] forKey:kPublicKeyCodingKey];
        _privateKey = [aDecoder decodeObjectOfClass:[NFKey class] forKey:kPrivateKeyCodingKey];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.publicKey forKey:kPublicKeyCodingKey];
    [aCoder encodeObject:self.privateKey forKey:kPrivateKeyCodingKey];
}

@end
