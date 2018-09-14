//
//  NFHandshakeState.h
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFSession.h"
#import "NFProtocol.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseHandshakeState)
@interface NFHandshakeState : NSObject <NFSessionSetup>

/**
 The designated initializer for a new handshake object.
 As a client of the Noise framework you should not have to instantiate a handshake yourself,
 the NFSession object will do that for you.

 @param protocol the protocol for the handshake
 @param role the role for the handshake
 @return a new instance
 */
- (instancetype)initWithProtocol:(NFProtocol *)protocol role:(NFSessionRole)role NS_DESIGNATED_INITIALIZER;

/** The protocol for this handshake. */
@property (strong, readonly) NFProtocol *protocol;

/** The role for this session. */
@property (readonly) NFSessionRole role;

/** The associated session. */
@property (nullable, weak, readonly) NFSession *session;

@end

NS_ASSUME_NONNULL_END
