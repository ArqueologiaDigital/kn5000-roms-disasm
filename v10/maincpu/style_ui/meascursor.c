/**
 * StyleUI_ScreenData_MeasCursor — Measure Cursor screen layout
 *
 * Source: e0c95b_e0ca12.bin (184 bytes, 22 commands)
 *
 * Screen elements:
 *   - Labels: "MEAS" (25,31), "CURSOR" (56,31), "CTL" (91,19)
 *   - Labeled REFs: "BAL" (Balance), "ERS" (Erase)
 *   - Navigation arrows: "<" (48,34), ">" (53,34)
 *   - Bottom bar: 3 FILLED_RECTs at y=210-236 with 1 HLINE divider
 *   - Selection box: CTL at (277,120)
 *   - Status area: FILLED_RECT (5,175)-(250,195)
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* Labels */
    sd_string_4_t       label_meas;       /* "MEAS" at (25,31) */
    sd_string_6_t       label_cursor;     /* "CURSOR" at (56,31) */
    sd_string_3_t       label_ctl;        /* "CTL" at (91,19) */

    /* CTL shortref + selection box */
    sd_short_ref_3_t    ctl_shortref;
    sd_selection_box_t  ctl_box;          /* (277,120)-(307,135) / (275,118)-(309,137) */

    /* Up/down arrows */
    sd_string_1_t       arrow_up;         /* "|" at (210,32) */
    sd_string_1_t       arrow_down;       /* "~" at (218,34) */

    /* Navigation arrows */
    sd_string_1_t       nav_left;         /* "<" at (48,34) */
    sd_string_1_t       nav_right;        /* ">" at (53,34) */

    /* Bottom bar */
    sd_filled_rect_t    bottom_bar_left;
    sd_filled_rect_t    bottom_bar_right;
    sd_filled_rect_t    bottom_bar_far_right;
    sd_hline_t          bottom_divider;

    /* BAL button + selection box */
    sd_labeled_ref_3_t  bal_ref;          /* "BAL" addr=0x06DB */
    sd_selection_box_t  bal_box;          /* (277,40)-(307,55) / (275,38)-(309,57) */
    sd_short_ref_3_t    bal_shortref;

    /* ERS button + selection box */
    sd_labeled_ref_3_t  ers_ref;          /* "ERS" addr=0x0D1B */
    sd_selection_box_t  ers_box;          /* (277,80)-(307,95) / (275,78)-(309,97) */
    sd_short_ref_3_t    ers_shortref;

    /* Status bar */
    sd_filled_rect_t    status_bar;
} screendata_meascursor_t;

_Static_assert(sizeof(screendata_meascursor_t) == 184,
    "ScreenData_MeasCursor must be exactly 184 bytes");

const screendata_meascursor_t StyleUI_ScreenData_MeasCursor
    __attribute__((section(".text"), used)) = {

    /* Labels */
    .label_meas = {
        .opcode = SD_OP_STRING, .length = 8,
        .x = 25, .y = 31,
        .text = "MEAS",
    },
    .label_cursor = {
        .opcode = SD_OP_STRING, .length = 10,
        .x = 56, .y = 31,
        .text = "CURSOR",
    },
    .label_ctl = {
        .opcode = SD_OP_STRING, .length = 7,
        .x = 91, .y = 19,
        .text = "CTL",
    },

    /* CTL shortref + selection box */
    .ctl_shortref = {
        .opcode = SD_OP_SHORT_REF, .length = 5,
        .data = { 0x37, 0x13, 0x11 },
    },
    .ctl_box = {
        .inner = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 277, .y = 120 },
            .bottom_right = { .x = 307, .y = 135 },
        },
        .outer = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 275, .y = 118 },
            .bottom_right = { .x = 309, .y = 137 },
        },
    },

    /* Up/down arrows */
    .arrow_up = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 210, .y = 32,
        .text = { LCD_CHAR_VBAR },
    },
    .arrow_down = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 218, .y = 34,
        .text = { LCD_CHAR_DARROW },
    },

    /* Navigation arrows */
    .nav_left = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 48, .y = 34,
        .text = "<",
    },
    .nav_right = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 53, .y = 34,
        .text = ">",
    },

    /* Bottom bar */
    .bottom_bar_left = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },
    .bottom_bar_right = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },
    .bottom_bar_far_right = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },
    .bottom_divider = {
        .opcode = SD_OP_HLINE, .length = 0x0a,
        .p1 = { .x = 5, .y = 223 },
        .p2 = { .x = 35, .y = 223 },
    },

    /* BAL button */
    .bal_ref = {
        .opcode = SD_OP_LABELED_REF, .length = 7,
        .addr = 0x06DB,
        .label = "BAL",
    },
    .bal_box = {
        .inner = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 277, .y = 40 },
            .bottom_right = { .x = 307, .y = 55 },
        },
        .outer = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 275, .y = 38 },
            .bottom_right = { .x = 309, .y = 57 },
        },
    },
    .bal_shortref = {
        .opcode = SD_OP_SHORT_REF, .length = 5,
        .data = { 0xb7, 0x06, 0x11 },
    },

    /* ERS button */
    .ers_ref = {
        .opcode = SD_OP_LABELED_REF, .length = 7,
        .addr = 0x0D1B,
        .label = "ERS",
    },
    .ers_box = {
        .inner = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 277, .y = 80 },
            .bottom_right = { .x = 307, .y = 95 },
        },
        .outer = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 275, .y = 78 },
            .bottom_right = { .x = 309, .y = 97 },
        },
    },
    .ers_shortref = {
        .opcode = SD_OP_SHORT_REF, .length = 5,
        .data = { 0xf7, 0x0c, 0x11 },
    },

    /* Status bar */
    .status_bar = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
