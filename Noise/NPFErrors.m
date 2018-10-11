//
//  NPFErrors.m
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFErrors.h"
#import <noise/protocol.h>

NSErrorDomain const NPFErrorDomain = @"com.outercorner.Noise.ErrorDomain";

NSString *const NPFInternalErrorCodeKey = @"internal_error_code";
NSString *const NPFInternalErrorMessageKey = @"internal_error_message";


NSError *internalErrorFromNoiseError(int noise_err)
{
    char err_str[1024];
    noise_strerror(noise_err, err_str, 1024);
    NSString *errorString = [NSString stringWithUTF8String:err_str];
    return [NSError errorWithDomain:NPFErrorDomain
                                 code:internalError
                             userInfo:@{ NPFInternalErrorCodeKey: @(noise_err), NPFInternalErrorMessageKey: errorString}];
}
