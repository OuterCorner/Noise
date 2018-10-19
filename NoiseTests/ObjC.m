//
//  ObjC.m
//  Noise
//
// Created by Paulo Andrade on 19/10/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "ObjC.h"

@implementation ObjC
    
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        NSMutableDictionary *uInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        uInfo[@"name"] = exception.name;
        uInfo[@"reason"] = exception.reason;
        uInfo[@"userInfo"] = exception.userInfo;
        *error = [[NSError alloc] initWithDomain:@"BridgedException" code:0 userInfo:uInfo];
        return NO;
    }
}
    
@end

