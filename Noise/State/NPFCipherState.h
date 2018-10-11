//
//  NPFCipherState.h
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseCipherState)
@interface NPFCipherState : NSObject

- (NSData *)encrypt:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error;
- (NSData *)decrypt:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error;

- (NSUInteger)macLength;

@end

NS_ASSUME_NONNULL_END
