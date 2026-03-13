/**
 * StyleUI_ParamBlock_AltD — "Are You Sure?" confirmation dialog
 *
 * Source: e0b99d_e0b9ec.bin (80 bytes)
 *
 * Screen layout:
 *   - "Are You Sure?" message at (56, 17)
 *   - YES button with selection box at y=80
 *   - NO button with selection box at y=120
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] "Are You Sure?" prompt */
    sd_message_13_t     message;

    /* [1] YES button */
    sd_labeled_ref_3_t  yes_ref;
    sd_short_ref_3_t    yes_shortref;
    sd_selection_box_t  yes_box;

    /* [5] NO button */
    sd_labeled_ref_2_t  no_ref;
    sd_short_ref_3_t    no_shortref;
    sd_selection_box_t  no_box;
} paramblock_altd_t;

_Static_assert(sizeof(paramblock_altd_t) == 80,
    "ParamBlock_AltD must be exactly 80 bytes");

const paramblock_altd_t StyleUI_ParamBlock_AltD
    __attribute__((section(".text"), used)) = {
    /* [0] MESSAGE "Are You Sure?" at (56, 17) */
    .message = {
        .opcode = SD_OP_MESSAGE,
        .length = 17,
        .x      = 56,
        .y      = 17,
        .text   = "Are You Sure?",
    },

    /* [1] LABELED_REF "YES" */
    .yes_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = "YES",
    },
    /* [2] SHORT_REF */
    .yes_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },
    /* [3-4] YES selection box */
    .yes_box = {
        .inner = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 277, .y =  80 },
            .bottom_right = { .x = 307, .y =  95 },
        },
        .outer = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 275, .y =  78 },
            .bottom_right = { .x = 309, .y =  97 },
        },
    },

    /* [5] LABELED_REF "NO" */
    .no_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 6,
        .addr   = 0x135B,
        .label  = "NO",
    },
    /* [6] SHORT_REF */
    .no_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },
    /* [7-8] NO selection box */
    .no_box = {
        .inner = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 277, .y = 120 },
            .bottom_right = { .x = 307, .y = 135 },
        },
        .outer = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 275, .y = 118 },
            .bottom_right = { .x = 309, .y = 137 },
        },
    },
};
