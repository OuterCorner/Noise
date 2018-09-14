//
//  NFErrors.h
//  Noise
//
// Created by Paulo Andrade on 14/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const NFErrorDomain;

extern NSString *const NFInternalErrorCodeKey;
extern NSString *const NFInternalErrorMessageKey;
typedef NS_ERROR_ENUM(NFErrorDomain, NFError) {
    sessionNotSetupError = 1,
    sessionNotReadyError,
    fileHandleReadFailedError,
    handshakeMessageToBigError,
    internalError
};
