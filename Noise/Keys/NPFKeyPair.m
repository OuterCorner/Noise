//
//  NPFKeyPair.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFKeyPair.h"

static NSString *const kPublicKeyCodingKey = @"pub";
static NSString *const kPrivateKeyCodingKey = @"priv";

@implementation NPFKeyPair

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithPublicKey:(NPFKey *)publicKey privateKey:(NPFKey *)privateKey
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
        _publicKey = [aDecoder decodeObjectOfClass:[NPFKey class] forKey:kPublicKeyCodingKey];
        _privateKey = [aDecoder decodeObjectOfClass:[NPFKey class] forKey:kPrivateKeyCodingKey];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.publicKey forKey:kPublicKeyCodingKey];
    [aCoder encodeObject:self.privateKey forKey:kPrivateKeyCodingKey];
}

@end
