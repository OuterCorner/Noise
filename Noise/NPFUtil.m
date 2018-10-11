//
//  NPFUtil.m
//  Noise
//
// Created by Paulo Andrade on 11/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#import "NPFUtil.h"
#import <noise/protocol.h>

void NPFInit(void) {
    noise_init();
}


int NPFSessionRoleToNoiseRole(NPFSessionRole role) {
    switch (role) {
        case NPFSessionRoleInitiator:
            return NOISE_ROLE_INITIATOR;
        case NPFSessionRoleResponder:
            return NOISE_ROLE_RESPONDER;
    }
}
