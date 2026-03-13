/**
 * StyleUI_ParamBlock_AltB — Style UI parameter block (AltB)
 *
 * Source: e0b905_e0b92d.bin (41 bytes, 4 commands)
 *
 * Screen elements:
 *   - UNKNOWN_23 command
 *   - SHORT_REF "STEP RECORD:" header
 *   - LABELED_REF "TRACK:"
 *   - FILLED_RECT status bar
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] UNKNOWN_23 */
    sd_unknown_5_t      unknown;

    /* [1] SHORT_REF "STEP RECORD:" at (51,0) */
    sd_short_ref_14_t   step_record;

    /* [2] LABELED_REF "TRACK:" */
    sd_labeled_ref_6_t  track_ref;

    /* [3] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_altb_t;

_Static_assert(sizeof(paramblock_altb_t) == 41,
    "ParamBlock_AltB must be exactly 41 bytes");

const paramblock_altb_t StyleUI_ParamBlock_AltB
    __attribute__((section(".text"), used)) = {
    /* [0] UNKNOWN_23 */
    .unknown = {
        .opcode = SD_OP_UNKNOWN_23,
        .length = 5,
        .data   = { 0x34, 0x2d, 0x00 },
    },

    /* [1] SHORT_REF "STEP RECORD:" at (51,0) */
    .step_record = {
        .opcode = SD_OP_SHORT_REF,
        .length = 16,
        .data   = { 0x33, 0x00,
                    'S', 'T', 'E', 'P', ' ', 'R', 'E', 'C', 'O', 'R', 'D', ':' },
    },

    /* [2] LABELED_REF "TRACK:" */
    .track_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 10,
        .addr   = 0x028F,
        .label  = { 'T', 'R', 'A', 'C', 'K', ':' },
    },

    /* [3] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
