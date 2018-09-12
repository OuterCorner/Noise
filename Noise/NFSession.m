//
//  NFSession.m
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFSession.h"
#import "NFProtocol.h"
#import "NFHandshakeState.h"
#import <noise/protocol.h>

@interface NFSession ()

@property (nullable, strong) NFHandshakeState *handshakeState;

@end

@implementation NFSession

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    self = nil;
    return nil;
}
#pragma clang diagnostic pop

- (nullable instancetype)initWithProtocolName:(NSString *)protocolName role:(NFSessionRole)role
{
    NFProtocol *protocol = [[NFProtocol alloc] initWithName:protocolName];
    if (protocolName) {
        return [self initWithProtocol:protocol role:role];
    } else {
        self = nil;
        return nil;
    }
}

- (instancetype)initWithProtocol:(NFProtocol *)protocol role:(NFSessionRole)role
{
    self = [super init];
    if (self) {
        _protocol = protocol;
        _role = role;
        _state = NFSessionStateInitializing;
        _delegateQueue = [NSOperationQueue mainQueue];
    }
    return self;
}

- (BOOL)setup:(void (^)(id<NFSessionSetup> _Nonnull))setup
{
    if (self.state != NFSessionStateInitializing) {
        [[NSException exceptionWithName:@"InvalidState"
                                 reason:[NSString stringWithFormat:@"Session state is %lu", (unsigned long)self.state]
                               userInfo:nil] raise];
        return NO;
    }
    
    if (self.handshakeState == nil) {
        self.handshakeState = [[NFHandshakeState alloc] initWithProtocol:self.protocol
                                                                    role:self.role];
    }
    
    setup(self.handshakeState);
    return
    !self.handshakeState.preSharedKeyMissing &&
    !self.handshakeState.localKeyPairMissing &&
    !self.handshakeState.remotePublicKeyMissing;
}

@end
