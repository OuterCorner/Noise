//
//  NFUtil.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFSession.h"

void NFInit(void) __attribute__((constructor));

int NFSessionRoleToNoiseRole(NFSessionRole role);
