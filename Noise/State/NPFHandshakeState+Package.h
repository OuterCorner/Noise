//
//  NPFHandshakeState+Package.h
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFSession.h"
#import "NPFHandshakeState.h"

NS_ASSUME_NONNULL_BEGIN

@interface NPFHandshakeState (Package)

- (BOOL)startForSession:(NPFSession *)session error:(NSError * _Nullable __autoreleasing *)error;

- (BOOL)receivedData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error;

- (BOOL)needsPerformAction;
- (BOOL)performNextAction:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
