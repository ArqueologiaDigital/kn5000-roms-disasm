/**
 * StyleUI_ParamBlock_MEAS — Style UI parameter block (MEAS)
 *
 * Source: e0b843_e0b8dd.bin (155 bytes, 19 commands)
 *
 * Screen elements:
 *   - "MEAS" and "TRACK" labels
 *   - Up/Down arrows
 *   - REP, END, ERS, CLR buttons with selection boxes
 *   - FILLED_RECTs + HLINE
 */

#include "screendata_types.h"

/* REP and END use 3-char labels */
typedef SD_LABELED_REF_TYPE(3) sd_labeled_ref_rep_t;
typedef SD_LABELED_REF_TYPE(3) sd_labeled_ref_end_t;

typedef struct __attribute__((packed)) {
    sd_string_4_t       label_meas;

    sd_string_1_t       arrow_up;

    sd_string_1_t       arrow_down;

    sd_filled_rect_t    button_fill_1;

    sd_hline_t          button_hline;

    sd_labeled_ref_rep_t rep_ref;

    sd_labeled_ref_end_t end_ref;

    sd_filled_rect_t    button_fill_2;

    sd_filled_rect_t    button_fill_3;

    sd_labeled_ref_3_t  ers_ref;

    sd_selection_box_t  ers_box;

    sd_short_ref_3_t    ers_shortref;

    sd_string_5_t       label_track;

    sd_labeled_ref_3_t  clr_ref;

    sd_selection_box_t  clr_box;

    sd_short_ref_3_t    clr_shortref;

    sd_filled_rect_t    status_bar;
} paramblock_meas_t;

_Static_assert(sizeof(paramblock_meas_t) == 155,
    "ParamBlock_MEAS must be exactly 155 bytes");

const paramblock_meas_t StyleUI_ParamBlock_MEAS
    __attribute__((section(".text"), used)) = {
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

    .button_fill_1 = {
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

    .rep_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x222A,
        .label  = "REP",
    },

    .end_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x222F,
        .label  = "END",
    },

    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 205, .y = 210 },
        .bottom_right = { .x = 235, .y = 236 },
    },

    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
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
};
