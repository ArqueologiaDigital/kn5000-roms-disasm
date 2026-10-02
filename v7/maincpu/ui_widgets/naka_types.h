/**
 * naka_types.h — C struct definitions for NAKA UI widget descriptors
 *
 * The KN5000 uses a data-driven UI framework ("NAKA") where screen layouts
 * are described by packed widget records.  Every NAKA record starts with its
 * CLASS ID, a little-endian u32 0x016S_KKKK: registry slot S (0x160 for the
 * main CPU's class table, 0x16A for the HD-AE5000's), class-table entry KKKK --
 * the NAKA_CLASS_* constants of shared/event_codes.s.  naka_header_t below is
 * the legacy BYTE view of that id ({ entry, 0x00, 0x60, 0x01 } for slot 0x160),
 * and its "type" byte is the class-table entry.
 *
 * 94 widget classes are used (see macros.s). This header provides packed
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
    uint32_t handler_table;    /* +30: event handler dispatch table (DRAM address) */
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
    uint32_t handler_table;    /* +38: event handler dispatch table (DRAM address) */
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

/* ── DISPATCH (compact 24-byte widget) ─────────────────────── */

/**
 * Compact dispatch widget used in several NAKA data blocks.
 * Contains a type header, two index fields, and four pointers:
 * instance name string, instance code string, linked widget, and handler.
 */
typedef struct __attribute__((packed)) {
    naka_header_t header;      /*  +0: widget type + marker */
    uint16_t field_04;         /*  +4: screen/widget index */
    uint16_t field_06;         /*  +6: child count or flags */
    uint32_t name_ptr;         /*  +8: → instance name string */
    uint32_t inst_ptr;         /* +12: → instance block (code string) */
    uint32_t link_ptr;         /* +16: → linked widget (external) */
    uint32_t proc_addr;        /* +20: → Proc handler function */
} naka_dispatch_t;             /* 24 bytes */

/* ── Records that live inside the NAKA blobs but are not widgets ───── */

/**
 * AccompSeq style-data part descriptor, 16 bytes; accseq_record_t is two of
 * them.  Field meanings are read off the code, nothing else:
 *
 *   AccompSeq_LookupStyleData (sequencer/accompseq_routines.s) takes an index
 *   below 0x80 (from Voice_DecodeNoteChannel2), multiplies it by 0x20 and adds
 *   AccompSeq_StyleDataTable.  AccompSeq_LoadParams then reads, for part 1
 *   (+0x00) and part 2 (+0x10):
 *     flags    (+0) part 1: 0x7E27 = flags & 0x1D (bit 0 = part 1 active);
 *                   part 2: bit 0 sets bit 1 of 0x7E27.  AccompSeq_CompareChord
 *                   tests bit 4 of part 1's flags.
 *     stream   (+1) event stream; the cursor starts at stream + 6, past the
 *                   6-byte header 80 FF FF FF FF 87 every stream carries.
 *     loop     (+5) copied to the second cursor (0x7E34/0x7E36 for part 1,
 *                   0x7E38/0x7E3A for part 2); 0 or a pointer into the stream.
 *   AccompSeq_InitMidiEvents writes 3-byte events to the sequencer event
 *   buffer (AccompSeq_WriteMidiToBuffer -> SeqEvtBuf_WriteByte x3):
 *     program  (+9)  event (0xC1|0xC2, program & 0x7F, bank | (bit7 ? 0x10 : 0))
 *     bank     (+10) low nibble used, see program
 *     ctl04    (+12) event (0xD1|0xD2, 0x04, ctl04)
 *     ctl07_on (+13) bit 0 -> event (0xD1|0xD2, 0x07, 0x7F or 0x00)
 *     ctl03_on (+14) bit 0 -> event (0xD1|0xD2, 0x03, 0x7F or 0x00)
 *   +11 (0x7F in every record) and +15 (0x00 in every record) are read by
 *   none of these routines.
 */
typedef struct __attribute__((packed)) {
    uint8_t  flags;        /* +0x00 */
    uint32_t stream;       /* +0x01 -> event stream (header 80 FF FF FF FF 87) */
    uint32_t loop;         /* +0x05 -> 0, or a position inside the stream */
    uint8_t  program;      /* +0x09 */
    uint8_t  bank;         /* +0x0A */
    uint8_t  field_0b;     /* +0x0B: 0x7F throughout, no reader found */
    uint8_t  ctl04;        /* +0x0C */
    uint8_t  ctl07_on;     /* +0x0D: bit 0 */
    uint8_t  ctl03_on;     /* +0x0E: bit 0 */
    uint8_t  field_0f;     /* +0x0F: 0x00 throughout, no reader found */
} accseq_part_t;           /* 16 bytes */

typedef struct __attribute__((packed)) {
    accseq_part_t part[2];
} accseq_record_t;         /* 32 bytes */

/**
 * Class descriptor, 24 bytes: the records a ClassProc (0x1600004) registration
 * hands to RegisterObjectTable (`RegObjTable 0x1600004, ClassProc, &count,
 * table, id`).  ClassProc (ui/ui_widget_defs.s) indexes them with index * 24.
 *
 * Checked over all 292 descriptors of the 10 ClassProc tables registered in
 * v10 by scripts/analysis/naka_class_descriptors.py:
 *   - record_size - props_size is ONE constant per base_class (37 base
 *     classes, no exception): the size of the base class's record, which
 *     every derived record starts with.  E.g. base 0x160002B -> 32 (=
 *     naka_label_t), 0x1600034 -> 42 (= naka_container_t), 0x1600031 -> 26
 *     (= naka_group_t);
 *   - `sig` holds one type letter per property, and `props` points at one
 *     name pointer per letter followed by a pointer to "" (292 of 292);
 *   - props_size is the sum of the letters' sizes, j c X ` = 4 bytes and
 *     B C ^ _ A G f = 2 bytes, for 80 of the 81 descriptors that use only
 *     those letters (AcCmpRecBox "CC" says 2).
 * base_class is the same u32 that begins every NAKA widget record: its
 * "XX 00 60 01" header read little-endian is class 0x16000XX.
 */
typedef struct __attribute__((packed)) {
    uint32_t proc;         /* +0x00  class procedure (EffectBoxProc, ...) */
    uint32_t base_class;   /* +0x04  0x16000xx */
    uint16_t record_size;  /* +0x08  bytes of an instance record, base included */
    uint16_t props_size;   /* +0x0A  bytes this class adds */
    uint32_t name;         /* +0x0C -> class name string */
    uint32_t sig;          /* +0x10 -> one type letter per property */
    uint32_t props;        /* +0x14 -> property-name pointers, "" last, then the names */
} naka_class_t;            /* 24 bytes */

/**
 * AccompSeq event streams (the byte arrays accseq_part_t.stream points at).
 * The grammar is the one AccompSeq_ParseEvents / AccompSeq_InitEventDispatch
 * and AccompSeq_ParseSequenceData (sequencer/accompseq_routines.s) walk; it
 * consumes every byte of all 103 streams in naka_widget_descriptors.c with
 * no opcode left over (checked by scripts/converters/naka_c_retype.py, which
 * refuses to emit a stream it cannot parse exactly).
 *
 *   ASEQ_HEADER   80 FF FF FF FF 87 -- skipped: AccompSeq_LoadParams starts
 *                 the cursor at stream + 6
 *   0x90  6 bytes tick, then 4 bytes AccompSeq_ReadParams stores at
 *                 0x7E56..0x7E59 and AccompSeq_ProcessNoteOn6 re-emits
 *                 (p1 is also tested against 0x78 by AccompSeq_CheckVelocityFlags;
 *                 p3 == 0 is emitted as 1)
 *   0x91  8 bytes tick, then 6 bytes (0x7E56..0x7E5B) -> AccompSeq_ProcessNoteOn8
 *   0xC0  6 bytes tick, program, flags (bit 0 -> program bit 7 / bank bit 4),
 *                 bank (low nibble), one byte not read by ParseSequenceData
 *   0xDn  3 bytes (n = 1..5, 7) tick, value: controller n; ParseSequenceData
 *                 emits (0xD1|0xD2, n, value); n = 5 also stores value at the
 *                 part's 0x7E72/0x7E73
 *   0x81  1 byte  end of a 96-tick unit (0x7E46 += 1; ticks are 0..95 within it)
 *   0x83  1 byte  end of stream (AccompSeq_CleanupSequence / part transition)
 *   0x84  1 byte  jump back to the loop point (not present in the ROM streams)
 *   0x87  1 byte  block end: in the RAM variant (index >= 0x80, 256-byte blocks
 *                 at 0x1E8B00) it links to the next block; every ROM stream
 *                 ends 83 87
 *   "tick" is the event's position inside the current 96-tick unit.
 */
#define ASEQ_HEADER              0x80, 0xFF, 0xFF, 0xFF, 0xFF, 0x87
#define ASEQ_EV6(t, a, b, c, d)  0x90, (t), (a), (b), (c), (d)
#define ASEQ_EV8(t, a, b, c, d, e, f) 0x91, (t), (a), (b), (c), (d), (e), (f)
#define ASEQ_PROG(t, p, f, b, x) 0xC0, (t), (p), (f), (b), (x)
#define ASEQ_CTL(n, t, v)        (0xD0 | (n)), (t), (v)
#define ASEQ_UNIT                0x81
#define ASEQ_END                 0x83
#define ASEQ_LOOP                0x84
#define ASEQ_BLOCK_END           0x87

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
 * ALIGNED_STRING("text") — Aligned string initializer for char array fields.
 *
 * Equivalent to the assembly `aligned_string` macro: NUL-terminated,
 * then 0xFF-padded to even byte count.
 *
 * Use for even-length strings (which need 0xFF pad after NUL):
 *   char text[NAKA_STR_ALLOC(10)] = ALIGNED_STRING("CONTROLLER");
 *   // → { 'C','O','N','T','R','O','L','L','E','R', 0x00, 0xFF }
 *
 * For odd-length strings (NUL already at even boundary), use bare literal:
 *   char text[NAKA_STR_ALLOC(1)] = "a";
 *   // → { 'a', 0x00 }
 *
 * Implementation: appends "\0\xFF" to the literal. When the enclosing
 * char array is exactly NAKA_STR_ALLOC(n) bytes, the compiler drops
 * the trailing NUL from the literal, leaving { chars..., 0x00, 0xFF }.
 * The pragma suppresses the -Wexcess-initializers warning for this
 * intentional one-byte overflow (applied to the entire translation unit
 * since the warning fires at each usage site, not the macro definition).
 */
#pragma GCC diagnostic ignored "-Wexcess-initializers"
#define ALIGNED_STRING(s)  (s "\0\xFF")

#endif /* NAKA_TYPES_H */
