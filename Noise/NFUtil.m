//
//  NFUtil.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NFUtil.h"
#import <noise/protocol.h>

void NFInit(void) {
    noise_init();
}


int NFSessionRoleToNoiseRole(NFSessionRole role) {
    switch (role) {
        case NFSessionRoleInitiator:
            return NOISE_ROLE_INITIATOR;
        case NFSessionRoleResponder:
            return NOISE_ROLE_RESPONDER;
    }
}
