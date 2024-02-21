//
//  NPFSession+Package.h
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFSession.h"
@class NPFCipherState;

NS_ASSUME_NONNULL_BEGIN

@interface NPFSession (Package)

- (void)sendHandshakeData:(NSData *)data;
- (void)establishWithSendingCipher:(NPFCipherState *)sendCipher receivingCipher:(NPFCipherState *)recvCipher;
- (void)tryDelegateCall:(SEL)selector block:(void(^)(id<NPFSessionDelegate> delegate))callBlock;

@end

NS_ASSUME_NONNULL_END
