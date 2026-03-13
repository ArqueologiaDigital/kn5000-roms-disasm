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
    sd_labeled_ref_3_t  yes_ref;
    sd_short_ref_3_t    yes_shortref;
    sd_selection_box_t  yes_box;

    sd_labeled_ref_2_t  no_ref;
    sd_short_ref_3_t    no_shortref;
    sd_selection_box_t  no_box;

    sd_string_4_t       label_meas;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_filled_rect_t    button_fill;

    sd_hline_t          button_hline;

    sd_filled_rect_t    status_bar;
} paramblock_altc_t;

_Static_assert(sizeof(paramblock_altc_t) == 111,
    "ParamBlock_AltC must be exactly 111 bytes");

const paramblock_altc_t StyleUI_ParamBlock_AltC
    __attribute__((section(".text"), used)) = {
    .yes_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = "YES",
    },
    .yes_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },
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

    .no_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 6,
        .addr   = 0x135B,
        .label  = "NO",
    },
    .no_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x37, 0x13, 0x11 },
    },
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

    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 25,
        .y      = 31,
        .text   = "MEAS",
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

    .button_fill = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
