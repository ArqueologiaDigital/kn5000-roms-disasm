/**
 * StyleUI_ParamBlock_Medium — Style UI parameter block (Medium)
 *
 * Source: e0b784_e0b842.bin (191 bytes, 24 commands)
 *
 * Screen elements:
 *   - BAL and ERS buttons with selection boxes
 *   - "MEAS", "CURSOR", "VALUE" labels
 *   - 2 up/down arrow pairs
 *   - "<" / ">" navigation
 *   - FILLED_RECTs + HLINEs
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] LABELED_REF "BAL" */
    sd_labeled_ref_3_t  bal_ref;

    /* [1] SHORT_REF */
    sd_short_ref_3_t    bal_shortref;

    /* [2-3] BAL selection box */
    sd_selection_box_t  bal_box;

    /* [4] LABELED_REF "ERS" */
    sd_labeled_ref_3_t  ers_ref;

    /* [5-6] ERS selection box */
    sd_selection_box_t  ers_box;

    /* [7] SHORT_REF */
    sd_short_ref_3_t    ers_shortref;

    /* [8] STRING "MEAS" at (25,31) */
    sd_string_4_t       label_meas;

    /* [9] STRING "CURSOR" at (56,31) */
    sd_string_6_t       label_cursor;

    /* [10] STRING "|" at (210,32) — up arrow 1 */
    sd_string_1_t       arrow_up_1;

    /* [11] STRING "~" at (218,34) — down arrow 1 */
    sd_string_1_t       arrow_down_1;

    /* [12] STRING "VALUE" at (44,31) */
    sd_string_5_t       label_value;

    /* [13] STRING "|" at (230,32) — up arrow 2 */
    sd_string_1_t       arrow_up_2;

    /* [14] STRING "~" at (238,34) — down arrow 2 */
    sd_string_1_t       arrow_down_2;

    /* [15] STRING "<" at (48,34) */
    sd_string_1_t       nav_left;

    /* [16] STRING ">" at (53,34) */
    sd_string_1_t       nav_right;

    /* [17] FILLED_RECT (5,210)-(35,236) */
    sd_filled_rect_t    button_fill_1;

    /* [18] HLINE (5,223)-(35,223) */
    sd_hline_t          button_hline_1;

    /* [19] FILLED_RECT (165,210)-(195,236) */
    sd_filled_rect_t    button_fill_2;

    /* [20] HLINE (165,223)-(195,223) */
    sd_hline_t          button_hline_2;

    /* [21] FILLED_RECT (245,210)-(275,236) */
    sd_filled_rect_t    button_fill_3;

    /* [22] FILLED_RECT (285,210)-(315,236) */
    sd_filled_rect_t    button_fill_4;

    /* [23] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_medium_t;

_Static_assert(sizeof(paramblock_medium_t) == 191,
    "ParamBlock_Medium must be exactly 191 bytes");

const paramblock_medium_t StyleUI_ParamBlock_Medium
    __attribute__((section(".text"), used)) = {
    /* [0] LABELED_REF "BAL" */
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x06DB,
        .label  = { 'B', 'A', 'L' },
    },

    /* [1] SHORT_REF */
    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xB7, 0x06, 0x11 },
    },

    /* [2-3] BAL selection box */
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

    /* [4] LABELED_REF "ERS" */
    .ers_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = { 'E', 'R', 'S' },
    },

    /* [5-6] ERS selection box */
    .ers_box = {
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

    /* [7] SHORT_REF */
    .ers_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },

    /* [8] STRING "MEAS" at (25,31) */
    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = { 'M', 'E', 'A', 'S' },
    },

    /* [9] STRING "CURSOR" at (56,31) */
    .label_cursor = {
        .opcode = SD_OP_STRING,
        .length = 10,
        .x      = 0x38,
        .y      = 0x1f,
        .text   = { 'C', 'U', 'R', 'S', 'O', 'R' },
    },

    /* [10] STRING "|" at (210,32) — up arrow 1 */
    .arrow_up_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd2,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [11] STRING "~" at (218,34) — down arrow 1 */
    .arrow_down_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xda,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [12] STRING "VALUE" at (44,31) */
    .label_value = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 0x2c,
        .y      = 0x1f,
        .text   = { 'V', 'A', 'L', 'U', 'E' },
    },

    /* [13] STRING "|" at (230,32) — up arrow 2 */
    .arrow_up_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe6,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [14] STRING "~" at (238,34) — down arrow 2 */
    .arrow_down_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xee,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [15] STRING "<" at (48,34) */
    .nav_left = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x30,
        .y      = 0x22,
        .text   = { '<' },
    },

    /* [16] STRING ">" at (53,34) */
    .nav_right = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x35,
        .y      = 0x22,
        .text   = { '>' },
    },

    /* [17] FILLED_RECT (5,210)-(35,236) */
    .button_fill_1 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    /* [18] HLINE (5,223)-(35,223) */
    .button_hline_1 = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    /* [19] FILLED_RECT (165,210)-(195,236) */
    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 165, .y = 210 },
        .bottom_right = { .x = 195, .y = 236 },
    },

    /* [20] HLINE (165,223)-(195,223) */
    .button_hline_2 = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 165, .y = 223 },
        .p2     = { .x = 195, .y = 223 },
    },

    /* [21] FILLED_RECT (245,210)-(275,236) */
    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },

    /* [22] FILLED_RECT (285,210)-(315,236) */
    .button_fill_4 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },

    /* [23] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
