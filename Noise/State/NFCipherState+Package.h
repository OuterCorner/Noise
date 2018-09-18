//
//  NFCipherState+Package.h
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFCipherState.h"
#import <noise/protocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface NFCipherState (Package)

- (instancetype)initWithNoiseCCipherState:(NoiseCipherState *)cipher_state maxMessageSize:(NSUInteger)maxMessageSize;

@end

NS_ASSUME_NONNULL_END
