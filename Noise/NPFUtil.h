//
//  NPFUtil.h
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFSession.h"

void NPFInit(void) __attribute__((constructor));

int NPFSessionRoleToNoiseRole(NPFSessionRole role);
