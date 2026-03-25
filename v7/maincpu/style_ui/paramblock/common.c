/**
 * StyleUI_ParamBlock_Common — Style UI parameter block (Common)
 *
 * Source: e0b60e_e0b6a5.bin (152 bytes, 19 commands)
 *
 * Screen elements:
 *   - "MEAS" and "CURSOR" labels
 *   - Up/Down arrows, "<" / ">" navigation
 *   - BAL and ERS buttons with selection boxes
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    sd_string_4_t       label_meas;

    sd_string_6_t       label_cursor;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_string_1_t       nav_left;

    sd_string_1_t       nav_right;

    sd_filled_rect_t    button_fill_1;

    sd_filled_rect_t    button_fill_2;

    sd_filled_rect_t    button_fill_3;

    sd_hline_t          button_hline;

    sd_labeled_ref_3_t  bal_ref;

    sd_selection_box_t  bal_box;

    sd_short_ref_3_t    bal_shortref;

    sd_labeled_ref_3_t  ers_ref;

    sd_selection_box_t  ers_box;

    sd_short_ref_3_t    ers_shortref;

    sd_filled_rect_t    status_bar;
} paramblock_common_t;

_Static_assert(sizeof(paramblock_common_t) == 152,
    "ParamBlock_Common must be exactly 152 bytes");

const paramblock_common_t StyleUI_ParamBlock_Common
    __attribute__((section(".text"), used)) = {
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

    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 210,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },

    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 218,
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

    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },

    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },

    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

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

    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
