//
//  NFKeyGenerator.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFKeyGenerator.h"
#import "NFKey+Package.h"

#import <noise/protocol.h>

@implementation NFKeyGenerator

+ (NFKeyGenerator *)sharedGenerator
{
    static dispatch_once_t onceToken;
    static NFKeyGenerator *_sharedGenerator;
    dispatch_once(&onceToken, ^{
        _sharedGenerator = [[NFKeyGenerator alloc] init];
    });
    return _sharedGenerator;
}

- (NFKeyPair *)generateKeyPair:(NFKeyAlgo)keyAlgo
{
    NoiseDHState *dh;
    const char *key_type = [keyAlgo UTF8String];
    int err = noise_dhstate_new_by_name(&dh, key_type);
    if (err != NOISE_ERROR_NONE) {
        noise_perror(key_type, err);
        return nil;
    }
    err = noise_dhstate_generate_keypair(dh);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("generate keypair", err);
        noise_dhstate_free(dh);
        return nil;
    }
    
    /* Fetch the keypair to be saved */
    size_t priv_key_len = noise_dhstate_get_private_key_length(dh);
    size_t pub_key_len = noise_dhstate_get_public_key_length(dh);
    uint8_t *priv_key = (uint8_t *)malloc(priv_key_len);
    uint8_t *pub_key = (uint8_t *)malloc(pub_key_len);
    if (!priv_key || !pub_key) {
        fprintf(stderr, "Out of memory\n");
        return nil;
    }
    BOOL ok = YES;
    err = noise_dhstate_get_keypair
    (dh, priv_key, priv_key_len, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    
    NFKeyPair *keyPair = nil;
    if (ok) {
        NFKey *publicKey = [NFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                             role:NFKeyRolePublic
                                             algo:keyAlgo];
        NFKey *privateKey = [NFKey keyWithMaterial:[NSData dataWithBytes:priv_key length:priv_key_len]
                                              role:NFKeyRolePrivate
                                              algo:keyAlgo];
        keyPair = [[NFKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    }
    
    /* Clean up */
    noise_dhstate_free(dh);
    noise_free(priv_key, priv_key_len);
    noise_free(pub_key, pub_key_len);

    return keyPair;
}

@end
