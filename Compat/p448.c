//
//  p448.c
//  Noise
//
// Created by Paulo Andrade on 18/10/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

#if __x86_64__
#include "../Noise-C/src/crypto/goldilocks/src/p448/arch_x86_64/p448.c"
#elif __LP64__
#include "../Noise-C/src/crypto/goldilocks/src/p448/arch_ref64/p448.c"
#else
#include "../Noise-C/src/crypto/goldilocks/src/p448/arch_32/p448.c"
#endif


