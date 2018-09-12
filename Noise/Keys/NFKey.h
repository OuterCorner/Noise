//
//  NFKey.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NFKeyRole) {
    NFKeyRoleSymmetric,
    NFKeyRolePublic,
    NFKeyRolePrivate
} NS_SWIFT_NAME(NoiseKeyRole);

typedef NSString *NFKeyAlgo;

extern NFKeyAlgo const NFKeyAlgoCurve25519;
extern NFKeyAlgo const NFKeyAlgoCurve448;

NS_ASSUME_NONNULL_BEGIN
/**
 Represents either a public, private or symmetric key.
 You can create keys using @see NFKeyGenerator.
 */
NS_SWIFT_NAME(NoiseKey)
@interface NFKey : NSObject

@property (strong, readonly) NSData *keyMaterial;
@property (readonly) NFKeyRole keyRole;
@property (nullable, readonly) NFKeyAlgo keyAlgo;

@end

NS_ASSUME_NONNULL_END
