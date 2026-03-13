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
    /* [0] STRING "MEAS" at (25,31) */
    sd_string_4_t       label_meas;

    /* [1] STRING "|" at (210,32) — up arrow */
    sd_string_1_t       arrow_up;

    /* [2] STRING "~" at (218,34) — down arrow */
    sd_string_1_t       arrow_down;

    /* [3] FILLED_RECT (5,210)-(35,236) */
    sd_filled_rect_t    button_fill_1;

    /* [4] HLINE (5,223)-(35,223) */
    sd_hline_t          button_hline;

    /* [5] LABELED_REF "REP" */
    sd_labeled_ref_rep_t rep_ref;

    /* [6] LABELED_REF "END" */
    sd_labeled_ref_end_t end_ref;

    /* [7] FILLED_RECT (205,210)-(235,236) */
    sd_filled_rect_t    button_fill_2;

    /* [8] FILLED_RECT (245,210)-(275,236) */
    sd_filled_rect_t    button_fill_3;

    /* [9] LABELED_REF "ERS" */
    sd_labeled_ref_3_t  ers_ref;

    /* [10-11] ERS selection box */
    sd_selection_box_t  ers_box;

    /* [12] SHORT_REF */
    sd_short_ref_3_t    ers_shortref;

    /* [13] STRING "TRACK" at (26,23) */
    sd_string_5_t       label_track;

    /* [14] LABELED_REF "CLR" */
    sd_labeled_ref_3_t  clr_ref;

    /* [15-16] CLR selection box */
    sd_selection_box_t  clr_box;

    /* [17] SHORT_REF */
    sd_short_ref_3_t    clr_shortref;

    /* [18] FILLED_RECT (5,175)-(250,195) */
    sd_filled_rect_t    status_bar;
} paramblock_meas_t;

_Static_assert(sizeof(paramblock_meas_t) == 155,
    "ParamBlock_MEAS must be exactly 155 bytes");

const paramblock_meas_t StyleUI_ParamBlock_MEAS
    __attribute__((section(".text"), used)) = {
    /* [0] STRING "MEAS" at (25,31) */
    .label_meas = {
        .opcode = SD_OP_STRING,
        .length = 8,
        .x      = 0x19,
        .y      = 0x1f,
        .text   = "MEAS",
    },

    /* [1] STRING "|" at (210,32) — up arrow */
    .arrow_up = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xd2,
        .y      = 0x20,
        .text   = { LCD_CHAR_VBAR },
    },

    /* [2] STRING "~" at (218,34) — down arrow */
    .arrow_down = {
        .opcode = SD_OP_STRING,
        .length = 5,
        .x      = 0xda,
        .y      = 0x22,
        .text   = { LCD_CHAR_DARROW },
    },

    /* [3] FILLED_RECT (5,210)-(35,236) */
    .button_fill_1 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },

    /* [4] HLINE (5,223)-(35,223) */
    .button_hline = {
        .opcode = SD_OP_HLINE,
        .length = 0x0A,
        .p1     = { .x = 5, .y = 223 },
        .p2     = { .x = 35, .y = 223 },
    },

    /* [5] LABELED_REF "REP" */
    .rep_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x222A,
        .label  = "REP",
    },

    /* [6] LABELED_REF "END" */
    .end_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x222F,
        .label  = "END",
    },

    /* [7] FILLED_RECT (205,210)-(235,236) */
    .button_fill_2 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 205, .y = 210 },
        .bottom_right = { .x = 235, .y = 236 },
    },

    /* [8] FILLED_RECT (245,210)-(275,236) */
    .button_fill_3 = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },

    /* [9] LABELED_REF "ERS" */
    .ers_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x0D1B,
        .label  = "ERS",
    },

    /* [10-11] ERS selection box */
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

    /* [12] SHORT_REF */
    .ers_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0xF7, 0x0C, 0x11 },
    },

    /* [13] STRING "TRACK" at (26,23) */
    .label_track = {
        .opcode = SD_OP_STRING,
        .length = 9,
        .x      = 0x1a,
        .y      = 0x17,
        .text   = "TRACK",
    },

    /* [14] LABELED_REF "CLR" */
    .clr_ref = {
        .opcode = SD_OP_LABELED_REF,
        .length = 7,
        .addr   = 0x199B,
        .label  = "CLR",
    },

    /* [15-16] CLR selection box */
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

    /* [17] SHORT_REF */
    .clr_shortref = {
        .opcode = SD_OP_SHORT_REF,
        .length = 5,
        .data   = { 0x77, 0x19, 0x11 },
    },

    /* [18] FILLED_RECT (5,175)-(250,195) */
    .status_bar = {
        .opcode       = SD_OP_FILLED_RECT,
        .length       = 0x0A,
        .top_left     = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
