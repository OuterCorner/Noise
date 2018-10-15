//
//  NPFHandshakeState.m
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFHandshakeState.h"
#import "NPFProtocol+Package.h"
#import "NPFUtil.h"
#import <noise/protocol.h>
#import "NPFKeyPair.h"
#import "NPFKey.h"
#import "NPFErrors+Package.h"
#import "NPFCipherState+Package.h"
#import "NPFSession+Package.h"
#import "NPFErrors.h"

@interface NPFHandshakeState ()

@property (nullable, weak, readwrite) NPFSession *session;

@end


@implementation NPFHandshakeState {
    NoiseHandshakeState *_handshakeState;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    self = nil;
    return nil;
}
#pragma clang diagnostic pop

- (instancetype)initWithProtocol:(NPFProtocol *)protocol role:(NPFSessionRole)role
{
    self = [super init];
    if (self) {
        _protocol = protocol;
        _role = role;
        noise_handshakestate_new_by_id(&_handshakeState, protocol.protocolId, NPFSessionRoleToNoiseRole(role));
    }
    return self;
}

- (void)dealloc
{
    if (_handshakeState) {
        noise_handshakestate_free(_handshakeState);
        _handshakeState = NULL;
    }
}

- (void)setPrologue:(NSData *)prologue
{
    noise_handshakestate_set_prologue(_handshakeState, [prologue bytes], [prologue length]);
}

- (void)setPreSharedKey:(NPFKey *)preSharedKey
{
    NSData *km = [preSharedKey keyMaterial];
    if ([preSharedKey keyRole] != NPFKeyRoleSymmetric || [km length] != 32) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"%@ is not symmetric or is not 32 bytes in length" userInfo:nil] raise];
        return;
    }
    noise_handshakestate_set_pre_shared_key(_handshakeState, [km bytes], [km length]);
}


- (BOOL)preSharedKeyMissing
{
    return noise_handshakestate_needs_pre_shared_key(_handshakeState);
}

- (NPFKeyPair *)localKeyPair
{
    if (!noise_handshakestate_has_local_keypair(_handshakeState)) {
        return nil;
    }
    
    NoiseDHState *dh = noise_handshakestate_get_local_keypair_dh(_handshakeState);
    size_t priv_key_len = noise_dhstate_get_private_key_length(dh);
    size_t pub_key_len = noise_dhstate_get_public_key_length(dh);
    uint8_t *priv_key = (uint8_t *)malloc(priv_key_len);
    uint8_t *pub_key = (uint8_t *)malloc(pub_key_len);
    
    BOOL ok = YES;
    int err = noise_dhstate_get_keypair(dh, priv_key, priv_key_len, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    NPFKeyPair *keyPair = nil;
    if (ok) {
        NPFKey *publicKey = [NPFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                             role:NPFKeyRolePublic
                                             algo:self.protocol.keyAlgo];
        NPFKey *privateKey = [NPFKey keyWithMaterial:[NSData dataWithBytes:priv_key length:priv_key_len]
                                              role:NPFKeyRolePrivate
                                              algo:self.protocol.keyAlgo];
        keyPair = [[NPFKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    }
    
    noise_free(priv_key, priv_key_len);
    noise_free(pub_key, pub_key_len);
    
    return keyPair;
}

- (void)setLocalKeyPair:(NPFKeyPair *)localKeyPair
{
    if ([localKeyPair.privateKey.keyAlgo compare:self.protocol.keyAlgo] != NSOrderedSame) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"KeyAlgo differs: %@ != %@", localKeyPair.privateKey.keyAlgo, self.protocol.keyAlgo]
                               userInfo:nil] raise];
        return;
    }
    NoiseDHState *dh = noise_handshakestate_get_local_keypair_dh(_handshakeState);
    NSData *privKeyMaterial = [localKeyPair.privateKey keyMaterial];
    NSData *pubKeyMaterial = [localKeyPair.publicKey keyMaterial];
    noise_dhstate_set_keypair(dh, [privKeyMaterial bytes], [privKeyMaterial length], [pubKeyMaterial bytes], [pubKeyMaterial length]);
}

- (BOOL)localKeyPairMissing
{
    return noise_handshakestate_needs_local_keypair(_handshakeState);
}

- (NPFKey *)remotePublicKey
{
    if (!noise_handshakestate_has_remote_public_key(_handshakeState)) {
        return nil;
    }
    NoiseDHState *dh = noise_handshakestate_get_remote_public_key_dh(_handshakeState);
    size_t pub_key_len = noise_dhstate_get_public_key_length(dh);
    uint8_t *pub_key = (uint8_t *)malloc(pub_key_len);
    
    BOOL ok = YES;
    int err = noise_dhstate_get_public_key(dh, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    NPFKey *key = nil;
    if (ok) {
        key = [NPFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                role:NPFKeyRolePublic
                                algo:self.protocol.keyAlgo];
    }
    
    noise_free(pub_key, pub_key_len);
    return key;
}

- (void)setRemotePublicKey:(NPFKey *)remotePublicKey
{
    if ([remotePublicKey.keyAlgo compare:self.protocol.keyAlgo] != NSOrderedSame) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"KeyAlgo differs: %@ != %@", remotePublicKey.keyAlgo, self.protocol.keyAlgo]
                               userInfo:nil] raise];
        return;
    }
    if (remotePublicKey.keyRole != NPFKeyRolePublic) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"Expecing a public key got: %lu", (unsigned long)remotePublicKey.keyRole]
                               userInfo:nil] raise];
        return;
    }
    
    NoiseDHState *dh = noise_handshakestate_get_remote_public_key_dh(_handshakeState);
    NSData *pubKeyMaterial = [remotePublicKey keyMaterial];
    noise_dhstate_set_public_key(dh, [pubKeyMaterial bytes], [pubKeyMaterial length]);
}

- (BOOL)remotePublicKeyMissing
{
    return noise_handshakestate_needs_remote_public_key(_handshakeState);
}


#pragma mark - Package private methods

- (BOOL)startForSession:(NPFSession *)session error:(NSError * _Nullable __autoreleasing *)error
{
    int err = noise_handshakestate_start(_handshakeState);
    if (err != NOISE_ERROR_NONE) {
        if (error != NULL) {
            *error = internalErrorFromNoiseError(err);
        }
        return NO;
    }
    self.session = session;
    
    return YES;
}

- (BOOL)receivedData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error
{
    NPFSession *session = [self session];
    int action = noise_handshakestate_get_action(_handshakeState);

    if (action != NOISE_ACTION_READ_MESSAGE) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NPFErrorDomain
                                         code:handshakeFailedError
                                     userInfo:@{NSLocalizedDescriptionKey: @"Received unexpected data during handshake"}];
        }
        return NO;
    }
    
    NSString *pattern = [self currentActionPattern];

    NoiseBuffer message_buffer;
    NoiseBuffer payload_buffer;
    size_t max_payload_size = NOISE_MAX_PAYLOAD_LEN;
    uint8_t *buffer = (uint8_t *)malloc(max_payload_size);
    
    noise_buffer_set_input(message_buffer, (uint8_t *)[data bytes], [data length]);
    noise_buffer_set_output(payload_buffer, buffer, max_payload_size);
    
    int err = noise_handshakestate_read_message(_handshakeState, &message_buffer, &payload_buffer);
    if (err != NOISE_ERROR_NONE) {
        free(buffer);
        if (error != NULL) {
            *error = internalErrorFromNoiseError(err);
        }
        return NO;
    }
    
    NSData *payload = [NSData dataWithBytes:buffer length:payload_buffer.size];
    free(buffer);
    if ([session.delegate respondsToSelector:@selector(session:didReceiveHandshakeMessage:payload:)]) {
        [session.delegate session:session didReceiveHandshakeMessage:pattern payload:payload];
    }
    
    return [self performNextAction:error];
}

- (BOOL)needsPerformAction
{
    int action = noise_handshakestate_get_action(_handshakeState);
    return action == NOISE_ACTION_WRITE_MESSAGE || action == NOISE_ACTION_SPLIT;
}

- (BOOL)performNextAction:(NSError * _Nullable __autoreleasing *)error
{
    NPFSession *session = [self session];
    int action = NOISE_ACTION_NONE;
    
    while ((void)(action = noise_handshakestate_get_action(_handshakeState)),
           action == NOISE_ACTION_WRITE_MESSAGE || action == NOISE_ACTION_SPLIT) {

        if (action == NOISE_ACTION_WRITE_MESSAGE) {
            NSString *pattern = [self currentActionPattern];
            NSData *payload = nil;
            if ([session.delegate respondsToSelector:@selector(session:willSendHandshakeMessagePattern:)]) {
                payload = [session.delegate session:session
                    willSendHandshakeMessagePattern:pattern];
            }
            
            size_t max_buffer_size = 4096 + [payload length];
            uint8_t *buffer = (uint8_t *)malloc(max_buffer_size);
            NoiseBuffer message_buffer;
            NoiseBuffer payload_buffer;
            
            noise_buffer_set_input(payload_buffer, (uint8_t *)[payload bytes], (size_t)[payload length]);
            noise_buffer_set_output(message_buffer, buffer, max_buffer_size);
            int err = noise_handshakestate_write_message(_handshakeState, &message_buffer, payload ? &payload_buffer : NULL);
            if (err != NOISE_ERROR_NONE) {
                free(buffer);
                if (error != NULL) {
                    *error = internalErrorFromNoiseError(err);
                }
                return NO;
            }
            
            NSData *messageData = [[NSData alloc] initWithBytesNoCopy:buffer length:message_buffer.size];
            
            [self.session sendData:messageData];
        }
        else if (action == NOISE_ACTION_SPLIT) { // handshake finished
            NoiseCipherState *send_cipher = NULL;
            NoiseCipherState *recv_cipher = NULL;
            
            int err = noise_handshakestate_split(_handshakeState, &send_cipher, &recv_cipher);
            if (err != NOISE_ERROR_NONE) {
                if (error != NULL) {
                    *error = internalErrorFromNoiseError(err);
                }
                return NO;
            }
            
            NPFCipherState *sendCipherState = [[NPFCipherState alloc] initWithNoiseCCipherState:send_cipher maxMessageSize:session.maxMessageSize];
            NPFCipherState *recvCipherState = [[NPFCipherState alloc] initWithNoiseCCipherState:recv_cipher maxMessageSize:session.maxMessageSize];
            
            [session establishWithSendingCipher:sendCipherState receivingCipher:recvCipherState];
        }
    }
    return YES;
}

#pragma mark - Private

- (NSString *)currentActionPattern
{
    char s[1024] = {'\0'};
    noise_handshakestate_get_action_pattern(_handshakeState, s, 1024);
    return [[NSString alloc] initWithUTF8String:s];
}



@end
