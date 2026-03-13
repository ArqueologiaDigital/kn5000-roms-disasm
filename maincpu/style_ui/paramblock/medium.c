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
    sd_labeled_ref_3_t  bal_ref;

    sd_short_ref_3_t    bal_shortref;

    sd_selection_box_t  bal_box;

    sd_labeled_ref_3_t  ers_ref;

    sd_selection_box_t  ers_box;

    sd_short_ref_3_t    ers_shortref;

    sd_string_4_t       label_meas;

    sd_string_6_t       label_cursor;

    sd_string_1_t       arrow_up_1;

    sd_string_1_t       arrow_down_1;

    sd_string_5_t       label_value;

    sd_string_1_t       arrow_up_2;

    sd_string_1_t       arrow_down_2;

    sd_string_1_t       nav_left;

    sd_string_1_t       nav_right;

    sd_filled_rect_t    button_fill_1;

    sd_hline_t          button_hline_1;

    sd_filled_rect_t    button_fill_2;

    sd_hline_t          button_hline_2;

    sd_filled_rect_t    button_fill_3;

    sd_filled_rect_t    button_fill_4;

    sd_filled_rect_t    status_bar;
} paramblock_medium_t;

_Static_assert(sizeof(paramblock_medium_t) == 191,
    "ParamBlock_Medium must be exactly 191 bytes");

const paramblock_medium_t StyleUI_ParamBlock_Medium
    __attribute__((section(".text"), used)) = {
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x06DB,
        .label  = "BAL",
    },

    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xB7, 0x06, 0x11 },
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

    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 25,
        .y      = 31,
        .text   = "MEAS",
    },

    .label_cursor = {
        .opcode = SD_OP_STRING,
        .length = 10,
        .x      = 56,
        .y      = 31,
        .text   = "CURSOR",
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

    .label_value = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 44,
        .y      = 31,
        .text   = "VALUE",
    },

    .arrow_up_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 230,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },

    .arrow_down_2 = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 238,
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

    .button_fill_1 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    .button_hline_1 = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 165, .y = 210 },
        .bottom_right = { .x = 195, .y = 236 },
    },

    .button_hline_2 = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 165, .y = 223 },
        .p2     = { .x = 195, .y = 223 },
    },

    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },

    .button_fill_4 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },

    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
