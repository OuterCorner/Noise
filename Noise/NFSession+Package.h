//
//  NFSession+Package.h
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFSession.h"
@class NFCipherState;

NS_ASSUME_NONNULL_BEGIN

@interface NFSession (Package)

- (void)establishWithSendingCipher:(NFCipherState *)sendCipher receivingCipher:(NFCipherState *)recvCipher;

@end

NS_ASSUME_NONNULL_END
