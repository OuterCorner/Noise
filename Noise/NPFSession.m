//
//  NPFSession.m
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFSession+Package.h"
#import "NPFProtocol+Package.h"
#import "NPFHandshakeState+Package.h"
#import "NPFCipherState+Package.h"
#import "NPFErrors.h"
#import <noise/protocol.h>

@interface NPFSession ()

@property (strong, readwrite) NPFHandshakeState *handshakeState;
@property (strong, readwrite) NPFCipherState *sendingCipherState;
@property (strong, readwrite) NPFCipherState *receivingCipherState;

@property (readwrite) NPFSessionState state;

@property (nullable, strong) NSPipe *inPipe;
@property (nullable, strong) NSPipe *outPipe;

@property (nullable, strong, readwrite) NSFileHandle *sendingHandle;
@property (nullable, strong, readwrite) NSFileHandle *receivingHandle;

@property (nonatomic, strong) NSOperationQueue *sessionQueue;

@end

@implementation NPFSession

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    self = nil;
    return nil;
}
#pragma clang diagnostic pop

- (nullable instancetype)initWithProtocolName:(NSString *)protocolName role:(NPFSessionRole)role
{
    NPFProtocol *protocol = [[NPFProtocol alloc] initWithName:protocolName];
    if (protocol) {
        return [self initWithProtocol:protocol role:role];
    } else {
        self = nil;
        return nil;
    }
}

- (nullable instancetype)initWithProtocolName:(NSString *)protocolName role:(NPFSessionRole)role setup:(void(^)(id<NPFSessionSetup>))setupBlock
{
    self = [self initWithProtocolName:protocolName role:role];
    if (self) {
        [self setup:setupBlock];
    }
    return self;
}


- (instancetype)initWithProtocol:(NPFProtocol *)protocol role:(NPFSessionRole)role
{
    self = [super init];
    if (self) {
        _protocol = protocol;
        _role = role;
        _state = NPFSessionStateInitializing;
        _maxMessageSize = NOISE_MAX_PAYLOAD_LEN;
        _sessionQueue = [[NSOperationQueue alloc] init];
        _sessionQueue.name = @"Internal NPFSession queue";
        _sessionQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (BOOL)setup:(void (^)(id<NPFSessionSetup> _Nonnull))setup
{
    if (self.state != NPFSessionStateInitializing) {
        [[NSException exceptionWithName:@"InvalidState"
                                 reason:[NSString stringWithFormat:@"Session state is %lu", (unsigned long)self.state]
                               userInfo:nil] raise];
        return NO;
    }
    
    if (self.handshakeState == nil) {
        self.handshakeState = [[NPFHandshakeState alloc] initWithProtocol:self.protocol
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
            *error = [NSError errorWithDomain:NPFErrorDomain
                                         code:sessionNotSetupError
                                     userInfo: nil];
        }
        return NO;
    }
    
    // check if we're ready
    if (![self isReady]) {
        if (error != NULL){
            *error = [NSError errorWithDomain:NPFErrorDomain
                                         code:sessionNotReadyError
                                     userInfo: nil];
        }
        return NO;
    }
    
    
    [self tryDelegateCall:@selector(sessionWillStart:) block:^(id<NPFSessionDelegate> delegate) {
        [delegate sessionWillStart:self];
    }];
        
    // start handshake
    if (![self.handshakeState startForSession:self error:error]) {
        return NO;
    }
    
    // setup pipes
    self.inPipe = [NSPipe pipe];
    self.outPipe = [NSPipe pipe];
    
    self.sendingHandle = [self.outPipe fileHandleForReading];
    self.receivingHandle = [self.inPipe fileHandleForWriting];
    

    NSOperationQueue *sessionQueue = self.sessionQueue;
    __weak NPFSession *wSelf = self;
    void(^abort)(NSError *) = ^(NSError *error){
        [sessionQueue addOperationWithBlock:^{ [wSelf abort:error]; }];
    };
    
    self.inPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle * _Nonnull handle) {
        NSData *sizeHeader = [handle readDataOfLength:2];
        if ([sizeHeader length] != 2) {
            abort([NSError errorWithDomain:NPFErrorDomain
                                      code:(sizeHeader != nil && [sizeHeader length] == 0) ? fileHandleEOFError : fileHandleReadFailedError
                                  userInfo:nil]);
            return;
        }
        
        uint8_t *size_header = (uint8_t*)[sizeHeader bytes];
        uint16_t size = (((uint16_t)(size_header[0])) << 8) | ((uint16_t)(size_header[1]));
        
        NSData *message = [handle readDataOfLength:(NSUInteger)size];
        if ([message length] != size) {
            abort([NSError errorWithDomain:NPFErrorDomain
                                      code:(message != nil && [message length] == 0) ? fileHandleEOFError : fileHandleReadFailedError
                                  userInfo:nil]);
            return;
        }
        [sessionQueue addOperationWithBlock:^{
            [wSelf receivedData:message];
        }];
    };
    
    [sessionQueue addOperationWithBlock:^{
        // change state
        [self transitionToState:NPFSessionStateHandshaking];
        
        [self tryDelegateCall:@selector(sessionDidStart:) block:^(id<NPFSessionDelegate> delegate) {
            [self.delegate sessionDidStart:self];
        }];
        
        [self performNextHandshakeActionIfNeeded];
    }];
    
    return YES;
}

- (void)stop
{
    [self.sessionQueue addOperationWithBlock:^{
        [self transitionToState:NPFSessionStateStopped];
        [self tryDelegateCall:@selector(sessionDidStop:error:) block:^(id<NPFSessionDelegate> delegate) {
            [delegate sessionDidStop:self error:nil];
        }];
    }];
}

- (void)sendData:(NSData *)data
{
    if (self.state != NPFSessionStateEstablished) {
        return;
    }
    
    [self.sessionQueue addOperationWithBlock:^{
        NSUInteger minSize = 2 + [self.sendingCipherState macLength];
        NSUInteger remaining = [data length];
        NSUInteger loc = 0;
        NSData *subData = nil;
        while ((void)(subData = [data subdataWithRange:NSMakeRange(loc, MIN(remaining, self.maxMessageSize - minSize))]), [subData length] > 0) {
            NSError *error = nil;
            NSData *cipherText = [self.sendingCipherState encrypt:subData error:&error];
            if (!cipherText) {
                [self abort:error];
                return;
            }
            
            [self writePacketWithPayload:cipherText];
            loc += [subData length];
            remaining -= [subData length];
        }
    }];
}

#pragma mark - Properties
    
- (void)setMaxMessageSize:(NSUInteger)maxMessageSize
{
    NPFCipherState *cipher = [[NPFCipherState alloc] initWithCipherName:self.protocol.cipherFunction maxMessageSize:maxMessageSize];
    NSUInteger minSize = 2 + [cipher macLength];
    if (maxMessageSize > NOISE_MAX_PAYLOAD_LEN) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"maxMessageSize (%lu) must be less than %d.", (unsigned long)maxMessageSize, NOISE_MAX_PAYLOAD_LEN]
                               userInfo:nil] raise];
    }
    else if (maxMessageSize <= minSize) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"maxMessageSize (%lu) must be greater than %lu.", (unsigned long)maxMessageSize, (unsigned long)minSize]
                               userInfo:nil] raise];
    }
    else {
        _maxMessageSize = maxMessageSize;
    }
    
}
    
#pragma mark - Package

- (void)sendHandshakeData:(NSData *)data
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"%@ should be called in the session queue", NSStringFromSelector(_cmd));
    
    if (self.state != NPFSessionStateHandshaking) {
        NSString *errorMessage = @"Attempt to send handshake data while not in a handshaking state";
        NSError *error = [NSError errorWithDomain:NPFErrorDomain
                                             code:internalError
                                         userInfo:@{NPFInternalErrorMessageKey: errorMessage}];
        [self abort:error];
        return;
    }

    if ([data length] > NOISE_MAX_PAYLOAD_LEN - 2) {
        NSError *error = [NSError errorWithDomain:NPFErrorDomain
                                             code:handshakeMessageToBigError
                                         userInfo:nil];
        [self abort:error];
    }
    [self writePacketWithPayload:data];
}


- (void)establishWithSendingCipher:(NPFCipherState *)sendCipher receivingCipher:(NPFCipherState *)recvCipher
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"%@ should be called in the session queue", NSStringFromSelector(_cmd));
    
    self.sendingCipherState = sendCipher;
    self.receivingCipherState = recvCipher;
    
    NPFHandshakeState *handshakeState = self.handshakeState;
    
    [self transitionToState:NPFSessionStateEstablished];
    
    [self tryDelegateCall:@selector(session:handshakeComplete:) block:^(id<NPFSessionDelegate> delegate) {
        [delegate session:self handshakeComplete:handshakeState];
    }];
}

- (void)tryDelegateCall:(SEL)selector block:(void(^)(id<NPFSessionDelegate> delegate))callBlock
{
    id delegate = self.delegate;
    if (![delegate respondsToSelector:selector]) { return; }
    
    NSOperationQueue *queue = self.delegateQueue ?: [NSOperationQueue mainQueue];
    if (queue == [NSOperationQueue currentQueue]) {
        callBlock(delegate);
    } else {
        dispatch_sync(queue.underlyingQueue, ^{
            callBlock(delegate);
        });
    }
}

#pragma mark - Private

- (void)transitionToState:(NPFSessionState)state
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"%@ should be called in the session queue", NSStringFromSelector(_cmd));
    self.state = state;
    
    switch (state) {
        case NPFSessionStateInitializing:
            break;
        case NPFSessionStateHandshaking:
            break;
        case NPFSessionStateEstablished:
            self.handshakeState = nil;
            break;
        case NPFSessionStateStopped:
        case NPFSessionStateError:
            self.inPipe.fileHandleForReading.readabilityHandler = nil;
            [self.outPipe.fileHandleForWriting closeFile];
            self.handshakeState = nil;
            self.sendingHandle = nil;
            self.receivingHandle = nil;
            self.sendingCipherState = nil;
            self.receivingCipherState = nil;
            break;
    }
}


- (void)performNextHandshakeActionIfNeeded
{
    [self.sessionQueue addOperationWithBlock:^{
        if (self.state == NPFSessionStateHandshaking && [self.handshakeState needsPerformAction]) {
            NSError *error = nil;
            if (![self.handshakeState performNextAction:&error]) {
                [self abort:error];
            }
        }
    }];
    
}
- (void)receivedData:(NSData *)data
{
    [self.sessionQueue addOperationWithBlock:^{
        if (self.state == NPFSessionStateHandshaking) {
            NSError *error = nil;
            if (![self.handshakeState receivedData:data error:&error]) {
                [self abort:error];
            }
        }
        else if (self.state == NPFSessionStateEstablished) {
            NSError *error = nil;
            NSData *plaintext = [self.receivingCipherState decrypt:data error:&error];
            if (!plaintext) {
                [self abort:error];
                return;
            }
            [self tryDelegateCall:@selector(session:didReceiveData:) block:^(id<NPFSessionDelegate> delegate) {
                [self.delegate session:self didReceiveData:plaintext];
            }];
        }
    }];
}

- (void)abort:(NSError *)error
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"%@ should be called in the session queue", NSStringFromSelector(_cmd));
    
    switch (self.state) {
        case NPFSessionStateInitializing:
        case NPFSessionStateHandshaking:
        case NPFSessionStateEstablished:
            break;
        case NPFSessionStateStopped:
            // session is already stopped. Ignore.
            return;
        case NPFSessionStateError:
            // session is already in an error state. Ignore.
            return;
    }
    
    [self transitionToState:NPFSessionStateError];
    [self tryDelegateCall:@selector(sessionDidStop:error:) block:^(id<NPFSessionDelegate> delegate) {
        [delegate sessionDidStop:self error:error];
    }];
}

- (void)writePacketWithPayload:(NSData *)data
{
    NSAssert([NSOperationQueue currentQueue] == self.sessionQueue, @"%@ should be called in the session queue", NSStringFromSelector(_cmd));
    
    uint16_t size = [data length];
    uint8_t size_buf[2];
    size_buf[0] = (uint8_t)(size >> 8);
    size_buf[1] = (uint8_t)(size);
    
    NSData *sizeHeader = [NSData dataWithBytes:size_buf length:2];
    NSFileHandle *writingHandle = [self.outPipe fileHandleForWriting];
    @try {
        [writingHandle writeData:sizeHeader];
        [writingHandle writeData:data];
    } @catch (NSException *exception) {
        NSLog(@"Caugth exception while trying write packet to outPipe: %@, %@", exception, exception.userInfo);
        [self abort:[NSError errorWithDomain:NPFErrorDomain code:packetWriteFailedError userInfo:nil]];
    }    
}


                      
@end
