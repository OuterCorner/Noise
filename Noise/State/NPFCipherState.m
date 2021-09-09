//
//  NPFCipherState.m
//  Noise
//
// Created by Paulo Andrade on 18/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFCipherState+Package.h"
#import "NPFErrors+Package.h"

#import <noise/protocol.h>

@implementation NPFCipherState {
    NoiseCipherState *_cipherState;
    uint8_t *_buffer;
    NSUInteger _maxMessageSize;
}


- (void)dealloc
{
    if (_cipherState) {
        noise_cipherstate_free(_cipherState);
        _cipherState = NULL;
    }
    
    if (_buffer) {
        free(_buffer);
        _buffer = NULL;
    }
}

- (instancetype)initWithNoiseCCipherState:(NoiseCipherState *)cipher_state maxMessageSize:(NSUInteger)maxMessageSize
{
    self = [super init];
    if (self) {
        _cipherState = cipher_state;
        _maxMessageSize = maxMessageSize;
        _buffer = (uint8_t *)malloc(_maxMessageSize);
    }
    return self;
}

- (instancetype)initWithCipherName:(NSString *)cipherName maxMessageSize:(NSUInteger)maxMessageSize
{
    NoiseCipherState *cipher = NULL;
    int err = noise_cipherstate_new_by_name(&cipher, [cipherName cStringUsingEncoding:NSUTF8StringEncoding]);
    if (err != NOISE_ERROR_NONE) {
        return nil;
    }
    return [self initWithNoiseCCipherState:cipher maxMessageSize:maxMessageSize];
}
    
- (NSData *__nullable)encrypt:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error
{
    NoiseBuffer noise_buffer;
    NSUInteger dataLength = [data length];
    [data getBytes:_buffer length:dataLength];
    
    noise_buffer_set_inout(noise_buffer, _buffer, dataLength, _maxMessageSize);
    
    int err = noise_cipherstate_encrypt(_cipherState, &noise_buffer);
    if(err != NOISE_ERROR_NONE) {
        if (error != NULL) {
            *error = internalErrorFromNoiseError(err);
        }
        return nil;
    }
    
    return [NSData dataWithBytes:_buffer length:noise_buffer.size];
}

- (NSData *__nullable)decrypt:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error
{
    NoiseBuffer noise_buffer;
    NSUInteger dataLength = [data length];
    [data getBytes:_buffer length:dataLength];
    
    noise_buffer_set_inout(noise_buffer, _buffer, dataLength, _maxMessageSize);
    
    int err = noise_cipherstate_decrypt(_cipherState, &noise_buffer);
    if(err != NOISE_ERROR_NONE) {
        if (error != NULL) {
            *error = internalErrorFromNoiseError(err);
        }
        return nil;
    }
    
    return [NSData dataWithBytes:_buffer length:noise_buffer.size];
}

- (NSUInteger)macLength
{
    return noise_cipherstate_get_mac_length(_cipherState);
}

- (int64_t)nonce
{
    return noise_cipherstate_get_nonce(_cipherState);
}

@end
