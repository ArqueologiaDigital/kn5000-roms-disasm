/**
 * StyleUI_ParamBlock_VALUE — Style UI parameter block (VALUE)
 *
 * Source: e0b5e7_e0b60d.bin (39 bytes, 5 commands)
 *
 * Screen elements:
 *   - "VALUE" label at (44, 31)
 *   - Up/Down arrows
 *   - FILLED_RECT + HLINE (button area)
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    sd_string_5_t       label_value;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_filled_rect_t    button_fill;

    sd_hline_t          button_hline;
} paramblock_value_t;

_Static_assert(sizeof(paramblock_value_t) == 39,
    "ParamBlock_VALUE must be exactly 39 bytes");

const paramblock_value_t StyleUI_ParamBlock_VALUE
    __attribute__((section(".text"), used)) = {
    .label_value = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 44,
        .y      = 31,
        .text   = "VALUE",
    },

    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 230,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },

    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 238,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },

    .button_fill = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 165, .y = 210 },
        .bottom_right = { .x = 195, .y = 236 },
    },

    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 165, .y = 223 },
        .p2     = { .x = 195, .y = 223 },
    },
};
