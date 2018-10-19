//
//  ObjC.h
//  Noise
//
// Created by Paulo Andrade on 19/10/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ObjC : NSObject
    
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;
    
@end


