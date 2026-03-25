/**
 * StyleUI_ParamBlock_AltE — Style UI parameter block (AltE)
 *
 * Source: e0b9ed_e0ba5f.bin (115 bytes, 13 commands)
 *
 * Screen elements:
 *   - SHORT_REF "STEP RECORD:" header
 *   - LABELED_REF "TRACK:", "CLR"
 *   - "TRACK" and "MEAS" labels
 *   - Up/Down arrows
 *   - CLR selection box
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    sd_short_ref_14_t   step_record;

    sd_labeled_ref_6_t  track_ref;

    sd_string_5_t       label_track;

    sd_labeled_ref_3_t  clr_ref;

    sd_selection_box_t  clr_box;

    sd_short_ref_3_t    clr_shortref;

    sd_filled_rect_t    status_bar;

    sd_string_4_t       label_meas;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_filled_rect_t    button_fill;

    sd_hline_t          button_hline;
} paramblock_alte_t;

_Static_assert(sizeof(paramblock_alte_t) == 115,
    "ParamBlock_AltE must be exactly 115 bytes");

const paramblock_alte_t StyleUI_ParamBlock_AltE
    __attribute__((section(".text"), used)) = {
    .step_record = {
        .opcode = SD_OP_SHORT_REF,
        .length = 16,
        .data   = { 0x33, 0x00,
                    'S', 'T', 'E', 'P', ' ', 'R', 'E', 'C', 'O', 'R', 'D', ':' },
    },

    .track_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 10,
        .addr   = 0x028F,
        .label  = "TRACK:",
    },

    .label_track = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 26,
        .y      = 23,
        .text   = "TRACK",
    },

    .clr_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x199B,
        .label  = "CLR",
    },

    .clr_box = {
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

    .clr_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
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
};
