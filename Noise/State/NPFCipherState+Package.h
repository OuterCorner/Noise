//
//  NPFCipherState+Package.h
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFCipherState.h"
#import <noise/protocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface NPFCipherState (Package)

- (instancetype)initWithNoiseCCipherState:(NoiseCipherState *)cipher_state maxMessageSize:(NSUInteger)maxMessageSize;

- (instancetype)initWithCipherName:(NSString *)cipherName maxMessageSize:(NSUInteger)maxMessageSize;
    
@end

NS_ASSUME_NONNULL_END
