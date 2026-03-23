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
    sd_labeled_ref_3_t  bal_ref;

    sd_selection_box_t  bal_box;

    sd_short_ref_3_t    bal_shortref;

    sd_labeled_ref_3_t  ers_ref;

    sd_selection_box_t  ers_box;

    sd_short_ref_3_t    ers_shortref;

    sd_string_3_t       label_ctl;

    sd_short_ref_3_t    ctl_shortref;

    sd_selection_box_t  ctl_box;

    sd_labeled_ref_4_t  rest_ref;

    sd_selection_box_t  rest_box;

    sd_short_ref_3_t    rest_shortref;

    sd_string_37_t      label_row;

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

    sd_string_1_t       nav_left;

    sd_string_1_t       nav_right;

    sd_filled_rect_t    status_bar;
} paramblock_bal_t;

_Static_assert(sizeof(paramblock_bal_t) == 250,
    "ParamBlock_BAL must be exactly 250 bytes");

const paramblock_bal_t StyleUI_ParamBlock_BAL
    __attribute__((section(".text"), used)) = {
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x06DB,
        .label  = "BAL",
    },

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

    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xB7, 0x06, 0x11 },
    },

    .ers_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = "ERS",
    },

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

    .ers_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },

    .label_ctl = {
        .opcode = SD_OP_STRING,
        .length = 7,
        .x      = 91,
        .y      = 19,
        .text   = "CTL",
    },

    .ctl_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },

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

    .rest_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 8,
        .addr   = 0x199A,
        .label  = "REST",
    },

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

    .rest_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    .label_row = {
        .opcode = SD_OP_STRING,
        .length = 41,
        .x      = 25,
        .y      = 31,
        .text   = "MEAS NOTE VEL   LENGTH   PHRS  CURSOR",
    },

    .arrow_up_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 210,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_1 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 218,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },
    .arrow_up_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 215,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 223,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },
    .arrow_up_3 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 220,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_3 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 228,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },
    .arrow_up_4 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 225,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_4 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 233,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },
    .arrow_up_5 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 230,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_5 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 238,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },
    .arrow_up_6 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 235,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },
    .arrow_down_6 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 243,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },

    .nav_left = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 48,
        .y      = 34,
        .text   = "<",
    },

    .nav_right = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 53,
        .y      = 34,
        .text   = ">",
    },

    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
