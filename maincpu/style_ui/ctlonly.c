/**
 * StyleUI_ScreenData_CtlOnly — CTL-only screen (control parameters)
 *
 * Source: e0caf7_e0cd19.bin (551 bytes)
 *
 * Structure:
 *   - Bytes 0-31: Bytecode header (STRING "CTL", SHORTREF, selection box RECTs)
 *   - Bytes 32-39: NUL-terminated "END" marker + padding
 *   - Bytes 40-235: LCD character set translation table (196 bytes)
 *   - Bytes 236-550: Control parameter data tables with format strings
 */

#include "screendata_types.h"

/* Sentinel marker pattern in control parameter tables */
#define CTL_SENTINEL { 0x00, 0x00, 0x00, 0x00, 0x3f, 0x01, 0xef, 0x00 }

typedef struct __attribute__((packed)) {
    /* Bytecode header (32 bytes) */
    sd_string_3_t       label_ctl;        /* "CTL" at (91,19) */
    sd_short_ref_3_t    ctl_shortref;     /* [37 13 11] */
    sd_selection_box_t  ctl_box;          /* (277,120)-(307,135) / (275,118)-(309,137) */

    /* "END" marker + padding (8 bytes) */
    uint8_t             end_marker[8];

    /* LCD character set translation table (196 bytes) */
    uint8_t             lcd_charset[196];

    /* Control parameter data tables (315 bytes) */
    uint8_t             blank_padding[52];  /* 52 spaces (0x20) */
    char                fallback_label[3];  /* "???" */
    uint8_t             header_sentinel_0[8];
    uint8_t             header_sentinel_1[8];
    uint8_t             header_sentinel_2[8];
    uint32_t            handlers[36];       /* handler function addresses */
    /* Format string group 0: sentinel + 3 format strings */
    uint8_t             fmt_sentinel_0[8];
    char                fmt_0[3][4];
    /* Format string group 1: sentinel + 6 format strings */
    uint8_t             fmt_sentinel_1[8];
    char                fmt_1[6][4];
    /* Format string group 2: sentinel + 3 format strings */
    uint8_t             fmt_sentinel_2[8];
    char                fmt_2[3][4];
    /* Format string group 3: sentinel + 3 format strings */
    uint8_t             fmt_sentinel_3[8];
    char                fmt_3[3][4];
} screendata_ctlonly_t;

_Static_assert(sizeof(screendata_ctlonly_t) == 551,
    "ScreenData_CtlOnly must be exactly 551 bytes");

const screendata_ctlonly_t StyleUI_ScreenData_CtlOnly
    __attribute__((section(".text"), used)) = {

    /* Bytecode header */
    .label_ctl = {
        .opcode = SD_OP_STRING, .length = 7,
        .x = 91, .y = 19,
        .text = "CTL",
    },
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

    /* "END" + NUL + padding */
    .end_marker = { 'E', 'N', 'D', 0x00, ' ', ' ', ' ', ' ' },

    /* LCD character set translation table */
    .lcd_charset = {
        0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x7f, 0x80, 0x81, 0xa1, 0xa6,
        0xaa, 0xab, 0xac, 0xad, 0xaf, 0xb0, 0xb2, 0xb3, 0xb4, 0xb6, 0xb8, 0x20, 0x21, 0x22, 0x23, 0x24,
        0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34,
        0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44,
        0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54,
        0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0xa5, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64,
        0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74,
        0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x8d, 0x8b, 0xc4, 0xd6, 0xdc, 0xe4, 0xf6,
        0xfc, 0xdf, 0xa4, 0xa0, 0x96, 0x95, 0xd7, 0x9e, 0x9b, 0x98, 0x8f, 0x8e, 0xb7, 0x9d, 0xa8, 0xbd,
        0xbe, 0x3f, 0x3f, 0x9c, 0xc7, 0x9c, 0xe7, 0xf4, 0xe0, 0xe2, 0xe8, 0xe9, 0xeb, 0xea, 0xf9, 0xfc,
        0xfb, 0xee, 0xef, 0x86, 0x87, 0x88, 0x3f, 0x3f, 0x97, 0x90, 0x3f, 0xbb, 0xc1, 0xc9, 0xd1, 0xe1,
        0xf3, 0xfa, 0xf1, 0xec, 0xf2, 0x3f, 0xbf, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
        0x20, 0x20, 0x20, 0x20,
    },

    /* Control parameter data tables */
    .blank_padding = SD_SPACES(52),
    .fallback_label = "???",
    .header_sentinel_0 = CTL_SENTINEL,
    .header_sentinel_1 = CTL_SENTINEL,
    .header_sentinel_2 = CTL_SENTINEL,

    /* Handler addresses (36 entries, 0xF0XXXX range) */
    .handlers = {
        0x00F020D6, 0x00F01D09, 0x00F020D7, 0x00F020D6,
        0x00F020D6, 0x00F020D6, 0x00F01DAB, 0x00F01E89,
        0x00F01F26, 0x00F01FB7, 0x00F01FDD, 0x00F020D6,
        0x00F020D6, 0x00F020D6, 0x00F01C29, 0x00F020D6,
        0x00F020D6, 0x00F020D6, 0x00F020D6, 0x00F020D6,
        0x00F020D6, 0x00F020D6, 0x00F020D6, 0x00F020D6,
        0x00F020D6, 0x00F020D6, 0x00F020D6, 0x00F02106,
        0x00F020D6, 0x00F020D6, 0x00F020D6, 0x00F020D6,
        0x00F01C6C, 0x00F020D6, 0x00F020D6, 0x00F01D38,
    },

    /* Format string groups (sentinel + NUL-terminated printf format strings) */
    .fmt_sentinel_0 = CTL_SENTINEL,
    .fmt_0 = { "%1d", "%2d", "%3d" },

    .fmt_sentinel_1 = CTL_SENTINEL,
    .fmt_1 = { "%1d", "%2d", "%3d", "%2d", "%3d", "%4d" },

    .fmt_sentinel_2 = CTL_SENTINEL,
    .fmt_2 = { "%1d", "%2d", "%3d" },

    .fmt_sentinel_3 = CTL_SENTINEL,
    .fmt_3 = { "%1d", "%2d", "%3d" },
};
