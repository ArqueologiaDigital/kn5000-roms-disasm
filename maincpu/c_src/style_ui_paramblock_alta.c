/**
 * StyleUI_ParamBlock_AltA — Style UI parameter block (AltA)
 *
 * Source: e0b8de_e0b904.bin (39 bytes, 5 commands)
 *
 * Screen elements:
 *   - "VALUE" label at (39, 31)
 *   - Up/Down arrows
 *   - FILLED_RECT + HLINE (button area)
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* [0] STRING "VALUE" at (39,31) */
    sd_string_5_t       label_value;

    /* [1] STRING "|" at (225,32) — up arrow */
    sd_string_1_t       arrow_up;

    /* [2] STRING "~" at (233,34) — down arrow */
    sd_string_1_t       arrow_down;

    /* [3] FILLED_RECT (125,210)-(155,236) */
    sd_filled_rect_t    button_fill;

    /* [4] HLINE (125,223)-(155,223) */
    sd_hline_t          button_hline;
} paramblock_alta_t;

_Static_assert(sizeof(paramblock_alta_t) == 39,
    "ParamBlock_AltA must be exactly 39 bytes");

const paramblock_alta_t StyleUI_ParamBlock_AltA
    __attribute__((section(".text"), used)) = {
    /* [0] STRING "VALUE" at (39,31) */
    .label_value = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 0x27,
        .y      = 0x1f,
        .text   = "VALUE",
    },

    /* [1] STRING "|" at (225,32) — up arrow */
    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe1,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [2] STRING "~" at (233,34) — down arrow */
    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xe9,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [3] FILLED_RECT (125,210)-(155,236) */
    .button_fill = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 125, .y = 210 },
        .bottom_right = { .x = 155, .y = 236 },
    },

    /* [4] HLINE (125,223)-(155,223) */
    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 125, .y = 223 },
        .p2     = { .x = 155, .y = 223 },
    },
};
