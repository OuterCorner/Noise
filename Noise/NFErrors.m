//
//  NFErrors.m
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFErrors.h"
#import <noise/protocol.h>

NSErrorDomain const NFErrorDomain = @"com.outercorner.Noise.ErrorDomain";

NSString *const NFInternalErrorCodeKey = @"internal_error_code";
NSString *const NFInternalErrorMessageKey = @"internal_error_message";


NSError *internalErrorFromNoiseError(int noise_err)
{
    char err_str[1024];
    noise_strerror(noise_err, err_str, 1024);
    NSString *errorString = [NSString stringWithUTF8String:err_str];
    return [NSError errorWithDomain:NFErrorDomain
                                 code:internalError
                             userInfo:@{ NFInternalErrorCodeKey: @(noise_err), NFInternalErrorMessageKey: errorString}];
}
