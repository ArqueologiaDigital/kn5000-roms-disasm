/**
 * StyleUI_ParamBlock_Short — Style UI parameter block (Short)
 *
 * Source: e0b6a6_e0b6cc.bin (39 bytes, 5 commands)
 *
 * Screen elements:
 *   - "TEMPO" label at (39, 31)
 *   - Up/Down arrows
 *   - FILLED_RECT + HLINE (button area)
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    sd_string_5_t       label_tempo;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_filled_rect_t    button_fill;

    sd_hline_t          button_hline;
} paramblock_short_t;

_Static_assert(sizeof(paramblock_short_t) == 39,
    "ParamBlock_Short must be exactly 39 bytes");

const paramblock_short_t StyleUI_ParamBlock_Short
    __attribute__((section(".text"), used)) = {
    .label_tempo = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 39,
        .y      = 31,
        .text   = "TEMPO",
    },

    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 225,
        .y      = 32,
        .text   = { LCD_CHAR_VBAR },
    },

    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 233,
        .y      = 34,
        .text   = { LCD_CHAR_DARROW },
    },

    .button_fill = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 125, .y = 210 },
        .bottom_right = { .x = 155, .y = 236 },
    },

    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 125, .y = 223 },
        .p2     = { .x = 155, .y = 223 },
    },
};
