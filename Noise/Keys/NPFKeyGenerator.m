//
//  NPFKeyGenerator.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFKeyGenerator.h"
#import "NPFKey.h"
#import <Security/Security.h>
#import <noise/protocol.h>

@implementation NPFKeyGenerator

+ (NPFKeyGenerator *)sharedGenerator
{
    static dispatch_once_t onceToken;
    static NPFKeyGenerator *_sharedGenerator;
    dispatch_once(&onceToken, ^{
        _sharedGenerator = [[NPFKeyGenerator alloc] init];
    });
    return _sharedGenerator;
}

- (NPFKeyPair *)generateKeyPair:(NPFKeyAlgo)keyAlgo
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

    BOOL ok = YES;
    err = noise_dhstate_get_keypair(dh, priv_key, priv_key_len, pub_key, pub_key_len);
    if (err != NOISE_ERROR_NONE) {
        noise_perror("get keypair", err);
        ok = NO;
    }
    
    NPFKeyPair *keyPair = nil;
    if (ok) {
        NPFKey *publicKey = [NPFKey keyWithMaterial:[NSData dataWithBytes:pub_key length:pub_key_len]
                                             role:NPFKeyRolePublic
                                             algo:keyAlgo];
        NPFKey *privateKey = [NPFKey keyWithMaterial:[NSData dataWithBytes:priv_key length:priv_key_len]
                                              role:NPFKeyRolePrivate
                                              algo:keyAlgo];
        keyPair = [[NPFKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    }
    
    /* Clean up */
    noise_dhstate_free(dh);
    noise_free(priv_key, priv_key_len);
    noise_free(pub_key, pub_key_len);

    return keyPair;
}

- (NPFKey *)generateSymmetricKey:(NSUInteger)sizeInBytes
{
    uint8_t buffer[sizeInBytes];
    int ret = SecRandomCopyBytes( kSecRandomDefault, sizeInBytes, (uint8_t *)&buffer);
    assert(ret == 0);
    NSData *randomData = [NSData dataWithBytes:buffer length:sizeInBytes];
    
    return [NPFKey keyWithMaterial:randomData role:NPFKeyRoleSymmetric algo:nil];
}

@end
