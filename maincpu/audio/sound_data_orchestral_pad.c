/**
 * sound_data_orchestral_pad.c — Orchestral Pad pitch offset table
 *
 * 128 bytes: per-patch signed pitch offsets (int8_t) for the Orchestral Pad
 * sound category. Values observed: 0 (no offset), +12 (up one octave),
 * -12/0xF4 (down one octave).
 *
 * Indexed by patch number within the category (0-127).
 */

#include <stdint.h>

#define NUM_PATCHES 128

_Static_assert(sizeof(int8_t[NUM_PATCHES]) == 128,
    "orchestral_pad_data must be exactly 128 bytes");

const int8_t orchestral_pad_data[NUM_PATCHES]
    __attribute__((section(".text"), used)) = {
    /*   0-  7 */    0,    0,    0,    0,    0,    0,    0,    0,
    /*   8- 15 */  -12,  -12,  -12,    0,    0,  -12,  -12,    0,
    /*  16- 23 */  -12,  -12,    0,    0,    0,    0,    0,    0,
    /*  24- 31 */    0,    0,    0,    0,    0,    0,    0,   12,
    /*  32- 39 */   12,   12,   12,   12,   12,   12,   12,   12,
    /*  40- 47 */    0,    0,    0,   12,    0,    0,    0,    0,
    /*  48- 55 */    0,    0,    0,    0,    0,    0,    0,    0,
    /*  56- 63 */    0,   12,   12,    0,    0,   12,    0,    0,
    /*  64- 71 */    0,    0,    0,    0,    0,    0,   12,    0,
    /*  72- 79 */  -12,    0,    0,    0,    0,    0,  -12,    0,
    /*  80- 87 */    0,    0,    0,    0,    0,    0,    0,   12,
    /*  88- 95 */    0,    0,    0,    0,    0,    0,    0,    0,
    /*  96-103 */    0,    0,    0,    0,    0,    0,    0,    0,
    /* 104-111 */    0,    0,    0,    0,    0,    0,    0,    0,
    /* 112-119 */  -12,   12,    0,  -12,    0,    0,    0,    0,
    /* 120-127 */    0,   12,    0,    0,    0,    0,    0,    0,
};
