/**
 * StyleUI_ParamBlock_Extended — Style UI parameter block (Extended)
 *
 * Source: e0b6cd_e0b783.bin (183 bytes, 23 commands)
 *
 * Screen elements:
 *   - "MEAS" and "CURSOR" labels
 *   - Up/Down arrows, "<" / ">" navigation
 *   - BAL, YES, NO buttons with selection boxes
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] STRING "MEAS" at (25,31) */
    sd_string_4_t       label_meas;

    /* [1] STRING "CURSOR" at (56,31) */
    sd_string_6_t       label_cursor;

    /* [2] STRING "|" at (210,32) — up arrow */
    sd_string_1_t       arrow_up;

    /* [3] STRING "~" at (218,34) — down arrow */
    sd_string_1_t       arrow_down;

    /* [4] STRING "<" at (48,34) */
    sd_string_1_t       nav_left;

    /* [5] STRING ">" at (53,34) */
    sd_string_1_t       nav_right;

    /* [6] FILLED_RECT (5,210)-(35,236) */
    sd_filled_rect_t    button_fill_1;

    /* [7] FILLED_RECT (245,210)-(275,236) */
    sd_filled_rect_t    button_fill_2;

    /* [8] FILLED_RECT (285,210)-(315,236) */
    sd_filled_rect_t    button_fill_3;

    /* [9] HLINE (5,223)-(35,223) */
    sd_hline_t          button_hline;

    /* [10] LABELED_REF "BAL" */
    sd_labeled_ref_3_t  bal_ref;

    /* [11] SHORT_REF */
    sd_short_ref_3_t    bal_shortref;

    /* [12-13] BAL selection box */
    sd_selection_box_t  bal_box;

    /* [14] LABELED_REF "YES" */
    sd_labeled_ref_3_t  yes_ref;

    /* [15] SHORT_REF */
    sd_short_ref_3_t    yes_shortref;

    /* [16-17] YES selection box */
    sd_selection_box_t  yes_box;

    /* [18] LABELED_REF "NO" */
    sd_labeled_ref_2_t  no_ref;

    /* [19] SHORT_REF */
    sd_short_ref_3_t    no_shortref;

    /* [20-21] NO selection box */
    sd_selection_box_t  no_box;

    /* [22] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_extended_t;

_Static_assert(sizeof(paramblock_extended_t) == 183,
    "ParamBlock_Extended must be exactly 183 bytes");

const paramblock_extended_t StyleUI_ParamBlock_Extended
    __attribute__((section(".text"), used)) = {
    /* [0] STRING "MEAS" at (25,31) */
    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = { 'M', 'E', 'A', 'S' },
    },

    /* [1] STRING "CURSOR" at (56,31) */
    .label_cursor = {
        .opcode = SD_OP_STRING,
        .length = 10,
        .x      = 0x38,
        .y      = 0x1f,
        .text   = { 'C', 'U', 'R', 'S', 'O', 'R' },
    },

    /* [2] STRING "|" at (210,32) — up arrow */
    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd2,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [3] STRING "~" at (218,34) — down arrow */
    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xda,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [4] STRING "<" at (48,34) */
    .nav_left = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x30,
        .y      = 0x22,
        .text   = { '<' },
    },

    /* [5] STRING ">" at (53,34) */
    .nav_right = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x35,
        .y      = 0x22,
        .text   = { '>' },
    },

    /* [6] FILLED_RECT (5,210)-(35,236) */
    .button_fill_1 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    /* [7] FILLED_RECT (245,210)-(275,236) */
    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },

    /* [8] FILLED_RECT (285,210)-(315,236) */
    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },

    /* [9] HLINE (5,223)-(35,223) */
    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    /* [10] LABELED_REF "BAL" */
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x06DB,
        .label  = { 'B', 'A', 'L' },
    },

    /* [11] SHORT_REF */
    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xB7, 0x06, 0x11 },
    },

    /* [12-13] BAL selection box */
    .bal_box = {
        .inner = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 277, .y =  40 },
            .bottom_right = { .x = 307, .y =  55 },
        },
        .outer = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 275, .y =  38 },
            .bottom_right = { .x = 309, .y =  57 },
        },
    },

    /* [14] LABELED_REF "YES" */
    .yes_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x135B,
        .label  = { 'Y', 'E', 'S' },
    },

    /* [15] SHORT_REF */
    .yes_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },

    /* [16-17] YES selection box */
    .yes_box = {
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

    /* [18] LABELED_REF "NO" */
    .no_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 6,
        .addr   = 0x199B,
        .label  = { 'N', 'O' },
    },

    /* [19] SHORT_REF */
    .no_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    /* [20-21] NO selection box */
    .no_box = {
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

    /* [22] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
