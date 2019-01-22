//
//  NPFErrors.h
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const NPFErrorDomain;

extern NSString *const NPFInternalErrorCodeKey;
extern NSString *const NPFInternalErrorMessageKey;
typedef NS_ERROR_ENUM(NPFErrorDomain, NPFError) {
    sessionNotSetupError = 1,
    sessionNotReadyError,
    fileHandleReadFailedError,
    fileHandleEOFError,
    handshakeMessageToBigError,
    internalError,
    handshakeFailedError,
};
