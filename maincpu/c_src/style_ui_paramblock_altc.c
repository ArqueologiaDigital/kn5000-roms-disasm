/**
 * StyleUI_ParamBlock_AltC — Style UI parameter block (AltC)
 *
 * Source: e0b92e_e0b99c.bin (111 bytes, 14 commands)
 *
 * Screen elements:
 *   - YES/NO buttons with selection boxes
 *   - "MEAS" label at (25,31)
 *   - Up/Down arrows
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0-3] YES button */
    sd_labeled_ref_3_t  yes_ref;
    sd_short_ref_3_t    yes_shortref;
    sd_selection_box_t  yes_box;

    /* [4-7] NO button */
    sd_labeled_ref_2_t  no_ref;
    sd_short_ref_3_t    no_shortref;
    sd_selection_box_t  no_box;

    /* [8] STRING "MEAS" at (25,31) */
    sd_string_4_t       label_meas;

    /* [9] STRING "|" at (210,32) — up arrow */
    sd_string_1_t       arrow_up;

    /* [10] STRING "~" at (218,34) — down arrow */
    sd_string_1_t       arrow_down;

    /* [11] FILLED_RECT (5,210)-(35,236) */
    sd_filled_rect_t    button_fill;

    /* [12] HLINE (5,223)-(35,223) */
    sd_hline_t          button_hline;

    /* [13] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_altc_t;

_Static_assert(sizeof(paramblock_altc_t) == 111,
    "ParamBlock_AltC must be exactly 111 bytes");

const paramblock_altc_t StyleUI_ParamBlock_AltC
    __attribute__((section(".text"), used)) = {
    /* [0] LABELED_REF "YES" */
    .yes_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = { 'Y', 'E', 'S' },
    },
    /* [1] SHORT_REF */
    .yes_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },
    /* [2-3] YES selection box */
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

    /* [4] LABELED_REF "NO" */
    .no_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 6,
        .addr   = 0x135B,
        .label  = { 'N', 'O' },
    },
    /* [5] SHORT_REF */
    .no_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },
    /* [6-7] NO selection box */
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

    /* [8] STRING "MEAS" at (25,31) */
    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = { 'M', 'E', 'A', 'S' },
    },

    /* [9] STRING "|" at (210,32) — up arrow */
    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd2,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [10] STRING "~" at (218,34) — down arrow */
    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xda,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [11] FILLED_RECT (5,210)-(35,236) */
    .button_fill = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    /* [12] HLINE (5,223)-(35,223) */
    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    /* [13] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
