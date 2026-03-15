/**
 * naka_types.h — C struct definitions for NAKA UI widget descriptors
 *
 * The KN5000 uses a data-driven UI framework ("NAKA") where screen layouts
 * are described by packed widget descriptors. Each descriptor starts with a
 * 4-byte header: { type, 0x00, 0x60, 0x01 }.
 *
 * 94 widget types are defined (see macros.s). This header provides packed
 * C structs for the most common types, enabling readable initializers
 * instead of raw .byte sequences.
 *
 * All multi-byte integers are little-endian (native for TLCS-900).
 * All structs are __attribute__((packed)) to match the binary encoding.
 */

#ifndef NAKA_TYPES_H
#define NAKA_TYPES_H

#include <stdint.h>

/* ── Type codes ─────────────────────────────────────────────── */

#define NAKA_TYPE_DIAGLIST   0x16
#define NAKA_TYPE_MENU_ITEM  0x1d
#define NAKA_TYPE_PANEL      0x1e
#define NAKA_TYPE_LABEL      0x2b
#define NAKA_TYPE_VALUE      0x2e
#define NAKA_TYPE_OPTION     0x2f
#define NAKA_TYPE_SLIDER     0x30
#define NAKA_TYPE_GROUP      0x31
#define NAKA_TYPE_CONTAINER  0x34
#define NAKA_TYPE_LIST       0x66
#define NAKA_TYPE_BITMAP     0x6c

/* ── Constants ──────────────────────────────────────────────── */

#define NAKA_NONE  0xFFFF   /* unused index slot */

/* ── Header ─────────────────────────────────────────────────── */

/** 4-byte NAKA widget header (common to all types) */
typedef struct __attribute__((packed)) {
    uint8_t type;       /* widget type code */
    uint8_t zero;       /* always 0x00 */
    uint8_t hi_lo;      /* always 0x60 */
    uint8_t hi_hi;      /* always 0x01 */
} naka_header_t;

/** Header initializer macro */
#define NAKA_HDR(t) { .type = (t), .zero = 0x00, .hi_lo = 0x60, .hi_hi = 0x01 }

/* ── Address helpers ────────────────────────────────────────── */

/** Get the absolute ROM address of an extern symbol */
#define NAKA_ADDR(sym)  ((uint32_t)&(sym))

/** Self-referential pointer: base address + offsetof(struct, field) */
#define NAKA_SELF(base, type, field) \
    ((uint32_t)(base) + __builtin_offsetof(type, field))

/* ── CONTAINER (type 0x34) — 42 bytes fixed + trailing string ─ */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: parent widget index (NAKA_NONE = root) */
    uint16_t self_idx;         /*  +6: this widget's index */
    uint16_t next_sibling;     /*  +8: next sibling (NAKA_NONE = last) */
    uint16_t prev_sibling;     /* +10: previous sibling (NAKA_NONE = first) */
    uint16_t child_count;      /* +12: number of child widgets */
    uint16_t field_0e;         /* +14: */
    uint16_t field_10;         /* +16: */
    uint32_t handler;          /* +18: handler/state callback address */
    uint16_t style;            /* +22: style flags */
    uint16_t field_18;         /* +24: */
    uint16_t field_1a;         /* +26: */
    uint16_t screen_id;        /* +28: screen identifier (e.g. 0x01A0) */
    uint32_t proc_addr;        /* +30: Proc handler address */
    uint32_t string_ptr;       /* +34: pointer to title string */
    uint16_t string_id;        /* +38: string length or identifier */
    uint16_t reserved;         /* +40: padding (always 0) */
} naka_container_t;            /* 42 bytes */

/** CONTAINER with inline trailing string */
#define NAKA_CONTAINER_TYPE(str_alloc) \
    struct __attribute__((packed)) { \
        naka_container_t c; \
        char text[str_alloc]; \
    }

/* ── MENU_ITEM (type 0x1D) — 54 bytes fixed + trailing string ─ */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: parent widget index */
    uint16_t prev_sibling;     /*  +6: previous sibling (NAKA_NONE = first) */
    uint16_t self_idx;         /*  +8: this widget's index */
    uint16_t next_sibling;     /* +10: next sibling (NAKA_NONE = last) */
    uint16_t x_margin;        /* +12: x margin/offset */
    uint16_t y_pos;            /* +14: y position */
    uint16_t sel_x1;           /* +16: selection rect left */
    uint16_t sel_y1;           /* +18: selection rect top */
    uint16_t sel_x2;           /* +20: selection rect right */
    uint16_t sel_y2;           /* +22: selection rect bottom */
    uint16_t flags;            /* +24: widget flags */
    uint16_t link_idx;         /* +26: linked widget index (NAKA_NONE = none) */
    uint16_t field_1c;         /* +28: */
    uint16_t field_1e;         /* +30: */
    uint16_t bg_color;         /* +32: background color */
    uint16_t field_22;         /* +34: */
    uint16_t handler_id;       /* +36: handler function ID */
    uint32_t proc_addr;        /* +38: Proc handler address */
    uint32_t string_ptr;       /* +42: pointer to display string */
    uint16_t ui_class;         /* +46: UI class/category */
    uint16_t screen_id;        /* +48: screen identifier */
    uint16_t string_len;       /* +50: display string length */
    uint16_t reserved;         /* +52: padding (always 0) */
} naka_menu_item_t;            /* 54 bytes */

/** MENU_ITEM with inline trailing string */
#define NAKA_MENU_ITEM_TYPE(str_alloc) \
    struct __attribute__((packed)) { \
        naka_menu_item_t m; \
        char text[str_alloc]; \
    }

/* ── LABEL (type 0x2B) — 32 bytes fixed + trailing string ──── */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: parent widget index */
    uint16_t prev_sibling;     /*  +6: previous sibling */
    uint16_t self_idx;         /*  +8: this widget's index */
    uint16_t next_sibling;     /* +10: next sibling */
    uint16_t x_offset;        /* +12: x offset */
    uint16_t field_0e;         /* +14: */
    uint16_t field_10;         /* +16: */
    uint16_t field_12;         /* +18: */
    uint16_t field_14;         /* +20: */
    uint32_t string_ptr;       /* +22: pointer to display string */
    uint16_t flags;            /* +26: flags */
    uint16_t field_1a;         /* +28: */
    uint16_t bg_color;         /* +30: background color */
} naka_label_t;                /* 32 bytes */

/** LABEL with inline trailing string */
#define NAKA_LABEL_TYPE(str_alloc) \
    struct __attribute__((packed)) { \
        naka_label_t l; \
        char text[str_alloc]; \
    }

/* ── GROUP (type 0x31) — 26 bytes fixed, no trailing string ── */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: */
    uint16_t field_06;         /*  +6: */
    uint16_t self_idx;         /*  +8: */
    uint16_t next_sibling;     /* +10: */
    uint16_t x_offset;        /* +12: */
    uint16_t y_offset;        /* +14: */
    uint16_t field_10;         /* +16: */
    uint16_t field_12;         /* +18: */
    uint16_t field_14;         /* +20: */
    uint16_t field_16;         /* +22: */
    uint16_t field_18;         /* +24: */
} naka_group_t;                /* 26 bytes */

/* ── SLIDER (type 0x30) — variable, ~42 bytes ────────────── */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: */
    uint16_t prev_sibling;     /*  +6: */
    uint16_t self_idx;         /*  +8: */
    uint16_t next_sibling;     /* +10: */
    uint16_t x_offset;        /* +12: */
    int16_t  y_offset;        /* +14: signed offset */
    uint16_t field_10;         /* +16: */
    uint16_t field_12;         /* +18: */
    uint16_t field_14;         /* +20: */
    uint32_t handler;          /* +22: handler address */
    uint16_t field_1a;         /* +26: */
    uint16_t field_1c;         /* +28: */
    uint16_t field_1e;         /* +30: */
    uint16_t handler_id;       /* +32: */
    uint16_t field_22;         /* +34: */
    uint16_t field_24;         /* +36: */
    uint16_t link_idx;         /* +38: */
    uint16_t field_28;         /* +40: */
    uint16_t field_2a;         /* +42: */
} naka_slider_t;               /* 44 bytes */

/* ── Type 0x48 — 26 bytes fixed, no trailing string ────────── */

typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: 4-byte header */
    uint16_t parent_idx;       /*  +4: */
    uint16_t prev_sibling;     /*  +6: */
    uint16_t self_idx;         /*  +8: */
    uint16_t next_sibling;     /* +10: */
    uint16_t field_0c;         /* +12: */
    uint16_t field_0e;         /* +14: */
    uint16_t field_10;         /* +16: */
    uint16_t field_12;         /* +18: */
    uint16_t field_14;         /* +20: */
    uint16_t field_16;         /* +22: */
    uint16_t field_18;         /* +24: */
} naka_type_0x48_t;            /* 26 bytes */

/* ── String alignment helper ────────────────────────────────── */

/**
 * NAKA strings use aligned_string: NUL-terminated, then 0xFF-padded
 * to the next even address. For a string of N chars:
 *   if (N+1) is even: alloc = N+1 (no padding needed)
 *   if (N+1) is odd:  alloc = N+2 (one 0xFF pad byte)
 *
 * Use NAKA_STR_ALLOC(N) to compute the allocation size.
 */
#define NAKA_STR_ALLOC(n)  (((n) + 2) & ~1)

/**
 * ASTR("text") — Aligned string initializer for char array fields.
 *
 * Equivalent to the assembly `aligned_string` macro: NUL-terminated,
 * then 0xFF-padded to even byte count.
 *
 * Use for even-length strings (which need 0xFF pad after NUL):
 *   char text[NAKA_STR_ALLOC(10)] = ASTR("CONTROLLER");
 *   // → { 'C','O','N','T','R','O','L','L','E','R', 0x00, 0xFF }
 *
 * For odd-length strings (NUL already at even boundary), use bare literal:
 *   char text[NAKA_STR_ALLOC(1)] = "a";
 *   // → { 'a', 0x00 }
 *
 * Implementation: appends "\0\xFF" to the literal. When the enclosing
 * char array is exactly NAKA_STR_ALLOC(n) bytes, the compiler drops
 * the trailing NUL from the literal, leaving { chars..., 0x00, 0xFF }.
 */
#define ASTR(s)  (s "\0\xFF")

#endif /* NAKA_TYPES_H */
