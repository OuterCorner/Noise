//
//  NFSession.m
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFSession+Package.h"
#import "NFProtocol+Package.h"
#import "NFHandshakeState+Package.h"
#import "NFCipherState+Package.h"
#import "NFErrors.h"
#import <noise/protocol.h>

@interface NFSession ()

@property (strong, readwrite) NFHandshakeState *handshakeState;
@property (strong, readwrite) NFCipherState *sendingCipherState;
@property (strong, readwrite) NFCipherState *receivingCipherState;

@property (readwrite) NFSessionState state;

@property (nullable, strong) NSPipe *inPipe;
@property (nullable, strong) NSPipe *outPipe;

@property (nullable, strong, readwrite) NSFileHandle *sendingHandle;
@property (nullable, strong, readwrite) NSFileHandle *receivingHandle;

@property (nonatomic, strong) NSOperationQueue *sessionQueue;
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
    if (protocol) {
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
        _maxMessageSize = NOISE_MAX_PAYLOAD_LEN;
        _sessionQueue = [[NSOperationQueue alloc] init];
        _sessionQueue.maxConcurrentOperationCount = 1;
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
    return [self isReady];
}

- (BOOL)isReady
{
    return self.handshakeState != nil &&
    !self.handshakeState.preSharedKeyMissing &&
    !self.handshakeState.localKeyPairMissing &&
    !self.handshakeState.remotePublicKeyMissing;
}


- (BOOL)start:(NSError * _Nullable __autoreleasing *)error
{
    // check if setup has been run
    if (self.handshakeState == nil) {
        if (error != NULL){
            *error = [NSError errorWithDomain:NFErrorDomain
                                         code:sessionNotSetupError
                                     userInfo: nil];
        }
        return NO;
    }
    
    // check if we're ready
    if (![self isReady]) {
        if (error != NULL){
            *error = [NSError errorWithDomain:NFErrorDomain
                                         code:sessionNotReadyError
                                     userInfo: nil];
        }
        return NO;
    }
    
    
    
    if ([self.delegate respondsToSelector:@selector(sessionWillStart:)]) {
        [self.delegate sessionWillStart:self];
    }
    
    // start handshake
    if (![self.handshakeState startForSession:self error:error]) {
        return NO;
    }
    
    // setup pipes
    self.inPipe = [NSPipe pipe];
    self.outPipe = [NSPipe pipe];
    
    self.sendingHandle = [self.outPipe fileHandleForReading];
    self.receivingHandle = [self.inPipe fileHandleForWriting];
    
    __weak NFSession *wSelf = self;
    self.inPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle * _Nonnull handle) {
        
        NSData *sizeHeader = [handle readDataOfLength:2];
        if ([sizeHeader length] != 2) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [wSelf abort:[NSError errorWithDomain:NFErrorDomain code:fileHandleReadFailedError userInfo:nil]];
            });
            return;
        }
        
        uint8_t *size_header = (uint8_t*)[sizeHeader bytes];
        uint16_t size = (((uint16_t)(size_header[0])) << 8) | ((uint16_t)(size_header[1]));
        
        NSData *message = [handle readDataOfLength:(NSUInteger)size];
        if ([message length] != size) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [wSelf abort:[NSError errorWithDomain:NFErrorDomain code:fileHandleReadFailedError userInfo:nil]];
            });
            return;
        }
        
        [wSelf receivedData:message];
    };
    
    // change state
    [self transitionToState:NFSessionStateHandshaking];
    
    if ([self.delegate respondsToSelector:@selector(sessionDidStart:)]) {
        [self.delegate sessionDidStart:self];
    }
    
    [self performNextHandshakeActionIfNeeded];
    return YES;
}

- (void)stop
{
    [self transitionToState:NFSessionStateStopped];
    if ([self.delegate respondsToSelector:@selector(sessionDidStop:error:)]) {
        [self.delegate sessionDidStop:self error:nil];
    }
}

- (void)sendData:(NSData *)data
{
    if (self.state == NFSessionStateHandshaking) {

        if ([data length] > NOISE_MAX_PAYLOAD_LEN - 2) {
            NSError *error = [NSError errorWithDomain:NFErrorDomain
                                                 code:handshakeMessageToBigError
                                             userInfo:nil];
            [self abort:error];
        }
        
        [self writePacketWithPayload:data];
    }
    else if (self.state == NFSessionStateEstablished) {
        NSError *error = nil;
        NSData *cipherText = [self.sendingCipherState encrypt:data error:&error];
        if (!cipherText) {
            [self abort:error];
            return;
        }
    
        [self writePacketWithPayload:cipherText];
    }
}

#pragma mark - Package

- (void)establishWithSendingCipher:(NFCipherState *)sendCipher receivingCipher:(NFCipherState *)recvCipher
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"This should be called in the session queue");
    
    self.sendingCipherState = sendCipher;
    self.receivingCipherState = recvCipher;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(session:handshakeComplete:)]) {
            [self.delegate session:self handshakeComplete:self.handshakeState];
        }
        [self transitionToState:NFSessionStateEstablished];
    });
}


#pragma mark - Private

- (void)transitionToState:(NFSessionState)state
{
    self.state = state;
    
    switch (state) {
        case NFSessionStateInitializing:
            break;
        case NFSessionStateHandshaking:
            break;
        case NFSessionStateEstablished:
            self.handshakeState = nil;
            break;
        case NFSessionStateStopped:
        case NFSessionStateError:
            self.handshakeState = nil;
            self.sendingHandle = nil;
            self.receivingHandle = nil;
            self.inPipe = nil;
            self.outPipe = nil;
            self.sendingCipherState = nil;
            self.receivingCipherState = nil;
            break;
    }
}


- (void)performNextHandshakeActionIfNeeded
{
    [self.sessionQueue addOperationWithBlock:^{
        if ([self.handshakeState needsPerformAction]) {
            NSError *error = nil;
            if (![self.handshakeState performNextAction:&error]) {
                [self abort:error];
            }
        }
    }];
    
}
- (void)receivedData:(NSData *)data
{
    if (self.state == NFSessionStateHandshaking) {
        [self.sessionQueue addOperationWithBlock:^{
            NSError *error = nil;
            if (![self.handshakeState receivedData:data error:&error]) {
                [self abort:error];
            }
        }];
    }
    else if (self.state == NFSessionStateEstablished) {
        NSError *error = nil;
        NSData *plaintext = [self.receivingCipherState decrypt:data error:&error];
        if (!plaintext) {
            [self abort:error];
            return;
        }
        if ([self.delegate respondsToSelector:@selector(session:didReceiveData:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate session:self didReceiveData:plaintext];
                
            });
        }
    }
}

- (void)abort:(NSError *)error
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self abort:error];
        });
        return;
    }
    [self transitionToState:NFSessionStateError];
    if ([self.delegate respondsToSelector:@selector(sessionDidStop:error:)]) {
        [self.delegate sessionDidStop:self error:error];
    }
}

- (void)writePacketWithPayload:(NSData *)data
{
    uint16_t size = [data length];
    uint8_t size_buf[2];
    size_buf[0] = (uint8_t)size >> 8;
    size_buf[1] = (uint8_t)size;
    
    NSData *sizeHeader = [NSData dataWithBytes:size_buf length:2];
    NSFileHandle *writingHandle = [self.outPipe fileHandleForWriting];
    [writingHandle writeData:sizeHeader];
    [writingHandle writeData:data];
}

@end
