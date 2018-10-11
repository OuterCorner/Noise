//
//  NPFProtocol.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFProtocol+Package.h"

@implementation NPFProtocol {
    NoiseProtocolId *_protocolId;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    self = nil;
    return nil;
}
#pragma clang diagnostic pop

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _protocolId = (NoiseProtocolId *)calloc(1, sizeof(NoiseProtocolId));
        
        const char *cName = [name UTF8String];
        if (noise_protocol_name_to_id(_protocolId, cName, strlen(cName)) != NOISE_ERROR_NONE) {
            self = nil;
        }
    }
    return self;
}

- (NSString *)handshakePattern
{
    const char *name = noise_id_to_name(NOISE_PATTERN_CATEGORY, _protocolId->pattern_id);
    return [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
}

- (NSString *)dhFunction
{
    if (!_protocolId->hybrid_id) {
        const char *name = noise_id_to_name(NOISE_DH_CATEGORY, _protocolId->dh_id);
        return [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
    } else {
        /*Format the DH names as "dh_id+hybrid_id"; e.g. "25519+NewHope" */
        const char *name = noise_id_to_name(NOISE_DH_CATEGORY, _protocolId->dh_id);
        const char *hybridName = noise_id_to_name(NOISE_DH_CATEGORY, _protocolId->hybrid_id);
        NSString *n = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
        NSString *h = [[NSString alloc] initWithBytes:hybridName length:strlen(hybridName) encoding:NSASCIIStringEncoding];
        return [NSString stringWithFormat:@"%@+%@", n, h];
    }
}

- (NPFKeyAlgo)keyAlgo
{
    return (NPFKeyAlgo)[self dhFunction];
}

- (NSString *)cipherFunction
{
    const char *name = noise_id_to_name(NOISE_CIPHER_CATEGORY, _protocolId->cipher_id);
    return [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
}

- (NSString *)hashFunction
{
    const char *name = noise_id_to_name(NOISE_HASH_CATEGORY, _protocolId->hash_id);
    return [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
}


- (void)dealloc
{
    if (_protocolId) {
        free(_protocolId);
        _protocolId = NULL;
    }
}
- (NoiseProtocolId *)protocolId
{
    return _protocolId;
}

- (NSString *)description
{
    char name[NOISE_MAX_PROTOCOL_NAME];
    noise_protocol_id_to_name(name, sizeof(name), _protocolId);
    return [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSASCIIStringEncoding];
}

- (NSUInteger)dhPublicKeySize
{
    NoiseDHState *state = NULL;
    noise_dhstate_new_by_id(&state, _protocolId->dh_id);
    
    size_t size = noise_dhstate_get_public_key_length(state);
    
    noise_dhstate_free(state);
    return size;
}

- (NSUInteger)dhPrivateKeySize
{
    NoiseDHState *state = NULL;
    noise_dhstate_new_by_id(&state, _protocolId->dh_id);
    
    size_t size = noise_dhstate_get_private_key_length(state);
    
    noise_dhstate_free(state);
    return size;
}

@end
