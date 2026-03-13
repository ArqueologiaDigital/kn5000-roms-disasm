/**
 * StyleUI_ParamBlock_BAL — Style UI parameter block (BAL)
 *
 * Source: e0b4ed_e0b5e6.bin (250 bytes, 32 commands)
 *
 * Screen elements:
 *   - BAL, ERS, REST buttons with selection boxes
 *   - CTL label with shortref
 *   - Long label row "MEAS NOTE VEL   LENGTH   PHRS  CURSOR"
 *   - 6 up/down arrow pairs
 *   - Navigation "<" / ">" arrows
 *   - Status bar FILLED_RECT
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] LABELED_REF "BAL" */
    sd_labeled_ref_3_t  bal_ref;

    /* [1-2] BAL selection box */
    sd_selection_box_t  bal_box;

    /* [3] SHORT_REF */
    sd_short_ref_3_t    bal_shortref;

    /* [4] LABELED_REF "ERS" */
    sd_labeled_ref_3_t  ers_ref;

    /* [5-6] ERS selection box */
    sd_selection_box_t  ers_box;

    /* [7] SHORT_REF */
    sd_short_ref_3_t    ers_shortref;

    /* [8] STRING "CTL" at (91,19) */
    sd_string_3_t       label_ctl;

    /* [9] SHORT_REF */
    sd_short_ref_3_t    ctl_shortref;

    /* [10-11] CTL selection box */
    sd_selection_box_t  ctl_box;

    /* [12] LABELED_REF "REST" */
    sd_labeled_ref_4_t  rest_ref;

    /* [13-14] REST selection box */
    sd_selection_box_t  rest_box;

    /* [15] SHORT_REF */
    sd_short_ref_3_t    rest_shortref;

    /* [16] STRING long label row at (25,31) */
    sd_string_37_t      label_row;

    /* [17-28] 6 up/down arrow pairs */
    sd_string_1_t       arrow_up_1;
    sd_string_1_t       arrow_down_1;
    sd_string_1_t       arrow_up_2;
    sd_string_1_t       arrow_down_2;
    sd_string_1_t       arrow_up_3;
    sd_string_1_t       arrow_down_3;
    sd_string_1_t       arrow_up_4;
    sd_string_1_t       arrow_down_4;
    sd_string_1_t       arrow_up_5;
    sd_string_1_t       arrow_down_5;
    sd_string_1_t       arrow_up_6;
    sd_string_1_t       arrow_down_6;

    /* [29] STRING "<" at (48,34) */
    sd_string_1_t       nav_left;

    /* [30] STRING ">" at (53,34) */
    sd_string_1_t       nav_right;

    /* [31] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_bal_t;

_Static_assert(sizeof(paramblock_bal_t) == 250,
    "ParamBlock_BAL must be exactly 250 bytes");

const paramblock_bal_t StyleUI_ParamBlock_BAL
    __attribute__((section(".text"), used)) = {
    /* [0] LABELED_REF "BAL" */
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x06DB,
        .label  = "BAL",
    },

    /* [1-2] BAL selection box */
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

    /* [3] SHORT_REF */
    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xB7, 0x06, 0x11 },
    },

    /* [4] LABELED_REF "ERS" */
    .ers_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = "ERS",
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

    /* [8] STRING "CTL" at (91,19) */
    .label_ctl = {
        .opcode = SD_OP_STRING,
        .length = 7,
        .x      = 0x5b,
        .y      = 0x13,
        .text   = "CTL",
    },

    /* [9] SHORT_REF */
    .ctl_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },

    /* [10-11] CTL selection box */
    .ctl_box = {
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

    /* [12] LABELED_REF "REST" */
    .rest_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 8,
        .addr   = 0x199A,
        .label  = "REST",
    },

    /* [13-14] REST selection box */
    .rest_box = {
        .inner = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 269, .y = 160 },
            .bottom_right = { .x = 307, .y = 175 },
        },
        .outer = {
            .opcode       = SD_OP_RECT,
            .length       = 0x0A,
            .top_left     = { .x = 267, .y = 158 },
            .bottom_right = { .x = 309, .y = 177 },
        },
    },

    /* [15] SHORT_REF */
    .rest_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    /* [16] STRING "MEAS NOTE VEL   LENGTH   PHRS  CURSOR" at (25,31) */
    .label_row = {
        .opcode = SD_OP_STRING,
        .length = 41,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = "MEAS NOTE VEL   LENGTH   PHRS  CURSOR",
    },

    /* [17] STRING "|" at (210,32) */
    .arrow_up_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd2,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [18] STRING "~" at (218,34) */
    .arrow_down_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xda,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },
    /* [19] STRING "|" at (215,32) */
    .arrow_up_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd7,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [20] STRING "~" at (223,34) */
    .arrow_down_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xdf,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },
    /* [21] STRING "|" at (220,32) */
    .arrow_up_3 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xdc,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [22] STRING "~" at (228,34) */
    .arrow_down_3 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe4,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },
    /* [23] STRING "|" at (225,32) */
    .arrow_up_4 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe1,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [24] STRING "~" at (233,34) */
    .arrow_down_4 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe9,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },
    /* [25] STRING "|" at (230,32) */
    .arrow_up_5 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe6,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [26] STRING "~" at (238,34) */
    .arrow_down_5 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xee,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },
    /* [27] STRING "|" at (235,32) */
    .arrow_up_6 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xeb,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },
    /* [28] STRING "~" at (243,34) */
    .arrow_down_6 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xf3,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [29] STRING "<" at (48,34) */
    .nav_left = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x30,
        .y      = 0x22,
        .text   = "<",
    },

    /* [30] STRING ">" at (53,34) */
    .nav_right = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0x35,
        .y      = 0x22,
        .text   = ">",
    },

    /* [31] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
