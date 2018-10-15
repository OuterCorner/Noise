//
//  NPFKey.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NPFKeyRole) {
    NPFKeyRoleSymmetric,
    NPFKeyRolePublic,
    NPFKeyRolePrivate
} NS_SWIFT_NAME(NoiseKeyRole);

typedef NSString *NPFKeyAlgo NS_SWIFT_NAME(NoiseKeyAlgo) NS_STRING_ENUM;

extern NPFKeyAlgo const _Nonnull NPFKeyAlgoCurve25519;
extern NPFKeyAlgo const _Nonnull NPFKeyAlgoCurve448;

NS_ASSUME_NONNULL_BEGIN
/**
 Represents either a public, private or symmetric key.
 You can create keys using @see NPFKeyGenerator.
 */
NS_SWIFT_NAME(NoiseKey)
@interface NPFKey : NSObject <NSSecureCoding>

+ (instancetype)keyWithMaterial:(NSData *)material role:(NPFKeyRole)role algo:(nullable NPFKeyAlgo)algo;

@property (strong, readonly) NSData *keyMaterial;
@property (readonly) NPFKeyRole keyRole;
@property (nullable, readonly) NPFKeyAlgo keyAlgo;

@end

NS_ASSUME_NONNULL_END
