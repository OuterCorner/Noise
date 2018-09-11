//
//  NFProtocol+Package.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFProtocol.h"
#import <noise/protocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface NFProtocol (Package)

- (NoiseProtocolId *)protocolId;

@end

NS_ASSUME_NONNULL_END
