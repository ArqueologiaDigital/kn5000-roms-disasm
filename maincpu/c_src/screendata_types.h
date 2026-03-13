/**
 * screendata_types.h — C struct definitions for ScreenData bytecode commands
 *
 * The KN5000 Style UI uses a bytecode format to describe screen layouts.
 * Each command is a packed struct starting with an opcode byte.
 *
 * All multi-byte integers are little-endian (native for TLCS-900).
 * All structs are __attribute__((packed)) to match the bytecode encoding.
 */

#ifndef SCREENDATA_TYPES_H
#define SCREENDATA_TYPES_H

#include <stdint.h>

/* ── Opcodes ─────────────────────────────────────────────────── */

#define SD_OP_HLINE        0x01
#define SD_OP_VLINE_WIDGET 0x02  /* sub=0x0A → VLINE, else WIDGET */
#define SD_OP_LABELED_REF  0x06
#define SD_OP_SHORT_REF    0x07
#define SD_OP_MESSAGE      0x08
#define SD_OP_RECT         0x09
#define SD_OP_FILLED_RECT  0x0A
#define SD_OP_STRING       0x20
#define SD_OP_UNKNOWN_23   0x23

#define SD_SUB_VLINE       0x0A

/* ── Coordinate types ────────────────────────────────────────── */

/** Screen coordinate pair (little-endian 16-bit) */
typedef struct __attribute__((packed)) {
    uint16_t x;
    uint16_t y;
} sd_point_t;

/* ── Fixed-size command structs ──────────────────────────────── */

/** HLINE: horizontal line (op=0x01, 10 bytes) */
typedef struct __attribute__((packed)) {
    uint8_t    opcode;   /* SD_OP_HLINE */
    uint8_t    length;   /* always 0x0A */
    sd_point_t p1;
    sd_point_t p2;
} sd_hline_t;

/** VLINE: vertical line (op=0x02, sub=0x0A, 10 bytes) */
typedef struct __attribute__((packed)) {
    uint8_t    opcode;   /* SD_OP_VLINE_WIDGET */
    uint8_t    subtype;  /* SD_SUB_VLINE (0x0A) */
    sd_point_t p1;
    sd_point_t p2;
} sd_vline_t;

/** RECT: outline rectangle (op=0x09, 10 bytes) */
typedef struct __attribute__((packed)) {
    uint8_t    opcode;   /* SD_OP_RECT */
    uint8_t    length;   /* always 0x0A */
    sd_point_t top_left;
    sd_point_t bottom_right;
} sd_rect_t;

/** FILLED_RECT: filled rectangle (op=0x0A, 10 bytes) */
typedef struct __attribute__((packed)) {
    uint8_t    opcode;   /* SD_OP_FILLED_RECT */
    uint8_t    length;   /* always 0x0A */
    sd_point_t top_left;
    sd_point_t bottom_right;
} sd_filled_rect_t;

/** Selection box: inner + outer RECT pair */
typedef struct __attribute__((packed)) {
    sd_rect_t inner;
    sd_rect_t outer;
} sd_selection_box_t;

/* ── Variable-length command structs ─────────────────────────── */
/*
 * For variable-length commands (STRING, LABELED_REF, SHORT_REF, MESSAGE),
 * we define parameterized macros and concrete types for each text length.
 *
 * Usage:
 *   SD_STRING_TYPE(3)  → sd_string_3_t  (STRING with 3-char text)
 *   SD_LABELED_REF_TYPE(3) → sd_labeled_ref_3_t (REF with 3-char label)
 */

/** STRING: text at screen position (op=0x20) */
#define SD_STRING_TYPE(text_len) \
    struct __attribute__((packed)) { \
        uint8_t opcode;  /* SD_OP_STRING */ \
        uint8_t length;  /* 4 + text_len */ \
        uint8_t x;       \
        uint8_t y;       \
        char    text[text_len]; \
    }

/** LABELED_REF: handler reference with label text (op=0x06) */
#define SD_LABELED_REF_TYPE(label_len) \
    struct __attribute__((packed)) { \
        uint8_t  opcode; /* SD_OP_LABELED_REF */ \
        uint8_t  length; /* 4 + label_len */ \
        uint16_t addr;   \
        char     label[label_len]; \
    }

/** SHORT_REF: compact reference (op=0x07) */
#define SD_SHORT_REF_TYPE(data_len) \
    struct __attribute__((packed)) { \
        uint8_t opcode;  /* SD_OP_SHORT_REF */ \
        uint8_t length;  /* 2 + data_len */ \
        uint8_t data[data_len]; \
    }

/** MESSAGE: text message at position (op=0x08) */
#define SD_MESSAGE_TYPE(text_len) \
    struct __attribute__((packed)) { \
        uint8_t opcode;  /* SD_OP_MESSAGE */ \
        uint8_t length;  /* 4 + text_len */ \
        uint8_t x;       \
        uint8_t y;       \
        char    text[text_len]; \
    }

/* ── Convenience typedefs for common sizes ───────────────────── */

typedef SD_STRING_TYPE(1)  sd_string_1_t;    /* single-char (arrows, etc.) */
typedef SD_STRING_TYPE(3)  sd_string_3_t;    /* "CTL", "BAL", etc. */
typedef SD_STRING_TYPE(4)  sd_string_4_t;    /* "MEAS" */
typedef SD_STRING_TYPE(5)  sd_string_5_t;    /* "VALUE", "TRACK" */
typedef SD_STRING_TYPE(6)  sd_string_6_t;    /* "CURSOR" */
typedef SD_STRING_TYPE(37) sd_string_37_t;   /* long label row */

typedef SD_LABELED_REF_TYPE(2)  sd_labeled_ref_2_t;  /* "NO" */
typedef SD_LABELED_REF_TYPE(3)  sd_labeled_ref_3_t;  /* "BAL", "ERS", "YES", "CLR", "CTL" */
typedef SD_LABELED_REF_TYPE(4)  sd_labeled_ref_4_t;  /* "REST" */
typedef SD_LABELED_REF_TYPE(6)  sd_labeled_ref_6_t;  /* "TRACK:" */

typedef SD_SHORT_REF_TYPE(3)    sd_short_ref_3_t;    /* standard 5-byte shortref */
typedef SD_SHORT_REF_TYPE(14)   sd_short_ref_14_t;   /* "STEP RECORD:" embedded text */

typedef SD_MESSAGE_TYPE(13) sd_message_13_t; /* "Are You Sure?" */

/* ── LCD special character codes ─────────────────────────────── */

#define LCD_CHAR_FLAT   0x88  /* ♭ */
#define LCD_CHAR_SHARP  0x8C  /* ♯ */
#define LCD_CHAR_VBAR   0x8D  /* | (up arrow) */
#define LCD_CHAR_DARROW 0x8E  /* ~ (down arrow) */

/* ── Helper for unknown opcodes ──────────────────────────────── */

#define SD_UNKNOWN_TYPE(data_len) \
    struct __attribute__((packed)) { \
        uint8_t opcode;  \
        uint8_t length;  \
        uint8_t data[data_len]; \
    }

typedef SD_UNKNOWN_TYPE(3) sd_unknown_5_t;

#endif /* SCREENDATA_TYPES_H */
