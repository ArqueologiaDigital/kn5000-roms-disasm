/**
 * StyleUI_ParamBlock_AltE — Style UI parameter block (AltE)
 *
 * Source: e0b9ed_e0ba5f.bin (115 bytes, 13 commands)
 *
 * Screen elements:
 *   - SHORT_REF "STEP RECORD:" header
 *   - LABELED_REF "TRACK:", "CLR"
 *   - "TRACK" and "MEAS" labels
 *   - Up/Down arrows
 *   - CLR selection box
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] SHORT_REF "STEP RECORD:" at (51,0) */
    sd_short_ref_14_t   step_record;

    /* [1] LABELED_REF "TRACK:" */
    sd_labeled_ref_6_t  track_ref;

    /* [2] STRING "TRACK" at (26,23) */
    sd_string_5_t       label_track;

    /* [3] LABELED_REF "CLR" */
    sd_labeled_ref_3_t  clr_ref;

    /* [4-5] CLR selection box */
    sd_selection_box_t  clr_box;

    /* [6] SHORT_REF */
    sd_short_ref_3_t    clr_shortref;

    /* [7] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;

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
} paramblock_alte_t;

_Static_assert(sizeof(paramblock_alte_t) == 115,
    "ParamBlock_AltE must be exactly 115 bytes");

const paramblock_alte_t StyleUI_ParamBlock_AltE
    __attribute__((section(".text"), used)) = {
    /* [0] SHORT_REF "STEP RECORD:" at (51,0) */
    .step_record = {
        .opcode = SD_OP_SHORT_REF,
        .length = 16,
        .data   = { 0x33, 0x00,
                    'S', 'T', 'E', 'P', ' ', 'R', 'E', 'C', 'O', 'R', 'D', ':' },
    },

    /* [1] LABELED_REF "TRACK:" */
    .track_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 10,
        .addr   = 0x028F,
        .label  = "TRACK:",
    },

    /* [2] STRING "TRACK" at (26,23) */
    .label_track = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 0x1a,
        .y      = 0x17,
        .text   = "TRACK",
    },

    /* [3] LABELED_REF "CLR" */
    .clr_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x199B,
        .label  = "CLR",
    },

    /* [4-5] CLR selection box */
    .clr_box = {
        .inner = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 277, .y = 160 },
            .bottom_right = { .x = 307, .y = 175 },
        },
        .outer = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 275, .y = 158 },
            .bottom_right = { .x = 309, .y = 177 },
        },
    },

    /* [6] SHORT_REF */
    .clr_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    /* [7] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },

    /* [8] STRING "MEAS" at (25,31) */
    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = "MEAS",
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
};
