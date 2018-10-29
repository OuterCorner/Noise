//
//  NPFHandshakeState.h
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPFSession.h"
#import "NPFProtocol.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NoiseHandshakeState)
@interface NPFHandshakeState : NSObject <NPFSessionSetup>

/**
 The designated initializer for a new handshake object.
 As a client of the Noise framework you should not have to instantiate a handshake yourself,
 the NPFSession object will do that for you.

 @param protocol the protocol for the handshake
 @param role the role for the handshake
 @return a new instance
 */
- (instancetype)initWithProtocol:(NPFProtocol *)protocol role:(NPFSessionRole)role NS_DESIGNATED_INITIALIZER;

/** The protocol for this handshake. */
@property (strong, readonly) NPFProtocol *protocol;

/** The role for this session. */
@property (readonly) NPFSessionRole role;

/** The associated session. */
@property (nullable, weak, readonly) NPFSession *session;


/**
 A hash value that can be used for channel binding.
 This is nil if the handhshake is not complete yet.
 */
@property (nullable, strong, readonly) NSData *handshakeHash;

@end

NS_ASSUME_NONNULL_END
