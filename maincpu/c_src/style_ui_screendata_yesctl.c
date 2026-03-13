/**
 * StyleUI_ScreenData_YesCtl — Yes/No confirmation + CTL Value screen
 *
 * Source: e0ca13_e0caf6.bin (228 bytes, 29 commands)
 *
 * Screen elements:
 *   - Labeled REFs: "YES" (sel box at 277,120), "NO " (sel box at 277,160)
 *   - Labels: "MEAS" (25,31), "CURSOR" (56,31), "CTL" (30,31), "VALUE" (40,31)
 *   - Up/down arrows: 3 pairs, navigation "<" ">"
 *   - Bottom bar: 5 FILLED_RECTs, 3 HLINE dividers
 *   - Status area: FILLED_RECT (5,175)-(250,195)
 */

#include "screendata_types.h"

typedef struct __attribute__((packed)) {
    /* YES button + selection box */
    sd_labeled_ref_3_t  yes_ref;          /* "YES" addr=0x135B */
    sd_short_ref_3_t    yes_shortref;
    sd_selection_box_t  yes_box;          /* (277,120)-(307,135) / (275,118)-(309,137) */

    /* NO button + selection box */
    sd_labeled_ref_3_t  no_ref;           /* "NO " addr=0x199B */
    sd_selection_box_t  no_box;           /* (277,160)-(307,175) / (275,158)-(309,177) */
    sd_short_ref_3_t    no_shortref;

    /* Labels */
    sd_string_4_t       label_meas;       /* "MEAS" at (25,31) */
    sd_string_6_t       label_cursor;     /* "CURSOR" at (56,31) */

    /* Up/down arrow pairs */
    sd_string_1_t       arrow_up_1;       /* "|" at (210,32) */
    sd_string_1_t       arrow_down_1;     /* "~" at (218,34) */
    sd_string_1_t       arrow_up_2;       /* "|" at (215,32) */
    sd_string_1_t       arrow_down_2;     /* "~" at (223,34) */

    /* CTL/VALUE labels */
    sd_string_3_t       label_ctl;        /* "CTL" at (30,31) */
    sd_string_5_t       label_value;      /* "VALUE" at (40,31) */

    /* Third arrow pair */
    sd_string_1_t       arrow_up_3;       /* "|" at (225,32) */
    sd_string_1_t       arrow_down_3;     /* "~" at (233,34) */

    /* Navigation arrows */
    sd_string_1_t       nav_left;         /* "<" at (48,34) */
    sd_string_1_t       nav_right;        /* ">" at (53,34) */

    /* Bottom bar */
    sd_filled_rect_t    bottom_bar_1;     /* (5,210)-(35,236) */
    sd_hline_t          bottom_divider_1; /* (5,223)-(35,223) */
    sd_filled_rect_t    bottom_bar_2;     /* (45,210)-(75,236) */
    sd_hline_t          bottom_divider_2; /* (45,223)-(75,223) */
    sd_filled_rect_t    bottom_bar_3;     /* (125,210)-(155,236) */
    sd_hline_t          bottom_divider_3; /* (125,223)-(155,223) */
    sd_filled_rect_t    bottom_bar_4;     /* (245,210)-(275,236) */
    sd_filled_rect_t    bottom_bar_5;     /* (285,210)-(315,236) */

    /* Status bar */
    sd_filled_rect_t    status_bar;       /* (5,175)-(250,195) */
} screendata_yesctl_t;

_Static_assert(sizeof(screendata_yesctl_t) == 228,
    "ScreenData_YesCtl must be exactly 228 bytes");

const screendata_yesctl_t StyleUI_ScreenData_YesCtl
    __attribute__((section(".text"), used)) = {

    /* YES button */
    .yes_ref = {
        .opcode = SD_OP_LABELED_REF, .length = 7,
        .addr = 0x135B,
        .label = { 'Y', 'E', 'S' },
    },
    .yes_shortref = {
        .opcode = SD_OP_SHORT_REF, .length = 5,
        .data = { 0x37, 0x13, 0x11 },
    },
    .yes_box = {
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

    /* NO button (note: "NO " has trailing space) */
    .no_ref = {
        .opcode = SD_OP_LABELED_REF, .length = 7,
        .addr = 0x199B,
        .label = { 'N', 'O', ' ' },
    },
    .no_box = {
        .inner = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 277, .y = 160 },
            .bottom_right = { .x = 307, .y = 175 },
        },
        .outer = {
            .opcode = SD_OP_RECT, .length = 0x0a,
            .top_left = { .x = 275, .y = 158 },
            .bottom_right = { .x = 309, .y = 177 },
        },
    },
    .no_shortref = {
        .opcode = SD_OP_SHORT_REF, .length = 5,
        .data = { 0x77, 0x19, 0x11 },
    },

    /* Labels */
    .label_meas = {
        .opcode = SD_OP_STRING, .length = 8,
        .x = 0x19, .y = 0x1f,
        .text = { 'M', 'E', 'A', 'S' },
    },
    .label_cursor = {
        .opcode = SD_OP_STRING, .length = 10,
        .x = 0x38, .y = 0x1f,
        .text = { 'C', 'U', 'R', 'S', 'O', 'R' },
    },

    /* Arrow pairs */
    .arrow_up_1 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xd2, .y = 0x20,
        .text = { LCD_CHAR_VBAR },
    },
    .arrow_down_1 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xda, .y = 0x22,
        .text = { LCD_CHAR_DARROW },
    },
    .arrow_up_2 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xd7, .y = 0x20,
        .text = { LCD_CHAR_VBAR },
    },
    .arrow_down_2 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xdf, .y = 0x22,
        .text = { LCD_CHAR_DARROW },
    },

    /* CTL / VALUE labels */
    .label_ctl = {
        .opcode = SD_OP_STRING, .length = 7,
        .x = 0x1e, .y = 0x1f,
        .text = { 'C', 'T', 'L' },
    },
    .label_value = {
        .opcode = SD_OP_STRING, .length = 9,
        .x = 0x28, .y = 0x1f,
        .text = { 'V', 'A', 'L', 'U', 'E' },
    },

    /* Third arrow pair */
    .arrow_up_3 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xe1, .y = 0x20,
        .text = { LCD_CHAR_VBAR },
    },
    .arrow_down_3 = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0xe9, .y = 0x22,
        .text = { LCD_CHAR_DARROW },
    },

    /* Navigation arrows */
    .nav_left = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0x30, .y = 0x22,
        .text = { '<' },
    },
    .nav_right = {
        .opcode = SD_OP_STRING, .length = 5,
        .x = 0x35, .y = 0x22,
        .text = { '>' },
    },

    /* Bottom bar */
    .bottom_bar_1 = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 5, .y = 210 },
        .bottom_right = { .x = 35, .y = 236 },
    },
    .bottom_divider_1 = {
        .opcode = SD_OP_HLINE, .length = 0x0a,
        .p1 = { .x = 5, .y = 223 },
        .p2 = { .x = 35, .y = 223 },
    },
    .bottom_bar_2 = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 45, .y = 210 },
        .bottom_right = { .x = 75, .y = 236 },
    },
    .bottom_divider_2 = {
        .opcode = SD_OP_HLINE, .length = 0x0a,
        .p1 = { .x = 45, .y = 223 },
        .p2 = { .x = 75, .y = 223 },
    },
    .bottom_bar_3 = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 125, .y = 210 },
        .bottom_right = { .x = 155, .y = 236 },
    },
    .bottom_divider_3 = {
        .opcode = SD_OP_HLINE, .length = 0x0a,
        .p1 = { .x = 125, .y = 223 },
        .p2 = { .x = 155, .y = 223 },
    },
    .bottom_bar_4 = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 245, .y = 210 },
        .bottom_right = { .x = 275, .y = 236 },
    },
    .bottom_bar_5 = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 285, .y = 210 },
        .bottom_right = { .x = 315, .y = 236 },
    },

    /* Status bar */
    .status_bar = {
        .opcode = SD_OP_FILLED_RECT, .length = 0x0a,
        .top_left = { .x = 5, .y = 175 },
        .bottom_right = { .x = 250, .y = 195 },
    },
};
