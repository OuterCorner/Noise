//
//  NFKey+Package.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFKey.h"

NS_ASSUME_NONNULL_BEGIN

@interface NFKey (Package)

+ (instancetype)keyWithMaterial:(NSData *)material role:(NFKeyRole)role algo:(nullable NFKeyAlgo)algo;

@end

NS_ASSUME_NONNULL_END
