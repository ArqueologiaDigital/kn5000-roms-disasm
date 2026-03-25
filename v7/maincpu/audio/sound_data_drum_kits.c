/**
 * sound_data_drum_kits.c — Drum Kits category data
 *
 * 213 bytes total:
 *   - 18 bytes: per-category config (same as other sound_data_* config tables)
 *   - 55 bytes: drum kit descriptors (5 x 8-byte records + 15 bytes metadata)
 *   - 140 bytes: part name table (20 x 7-char fixed-width, space-padded)
 *
 * Each drum kit descriptor record: { header_hi, header_lo, offset(16LE),
 * count(16LE), param(16LE) }. The offset values increase in steps corresponding
 * to waveform data regions (e.g., 0, 1200, 3000, 4800, 6600).
 *
 * The part name table assigns 7-character type labels to sequencer parts:
 * "MELODY ", "DRUM   ", "CHORD  ", "CONTROL", "RHYTHM ".
 */

#include <stdint.h>

/* Drum kit descriptor record (8 bytes) */
typedef struct __attribute__((packed)) {
    uint8_t  header_hi;   /* Always 0x0E */
    uint8_t  header_lo;   /* Always 0x08 */
    uint16_t offset;      /* Waveform data offset */
    uint16_t count;       /* Number of entries */
    uint16_t param;       /* Configuration parameter */
} drum_kit_desc_t;

_Static_assert(sizeof(drum_kit_desc_t) == 8,
    "drum_kit_desc must be 8 bytes");

/* Complete drum kits data structure */
typedef struct __attribute__((packed)) {
    /* Per-category config (18 bytes) */
    uint8_t category_config[18];

    /* Drum kit descriptors (5 x 8 = 40 bytes) */
    drum_kit_desc_t kits[5];

    /* Additional metadata (15 bytes) */
    uint8_t metadata[15];

    /* Part name table: 20 x 7-char fixed-width strings (140 bytes) */
    char part_names[20][7];
} drum_kits_data_t;

_Static_assert(sizeof(drum_kits_data_t) == 213,
    "drum_kits_data must be exactly 213 bytes");

const drum_kits_data_t drum_kits_data
    __attribute__((section(".text"), used)) = {
    /* Per-category config */
    .category_config = {
        /* Piano          */ 0xFF,
        /* Guitar         */ 0xFF,
        /* Strings&Vocal  */ 0xFF,
        /* Brass          */ 0xFF,
        /* Flute          */ 0xFF,
        /* Sax&Reed       */ 0xFF,
        /* Mallet&OrchPrc */ 0xFF,
        /* World Perc     */ 0xFF,
        /* Organ&Accord   */ 0xFF,
        /* Orchestral Pad */ 0xFF,
        /* Synth          */ 0xFF,
        /* Bass           */ 0xFF,
        /* Digital Drawbar*/ 0xFF,
        /* Accordion Reg  */ 0xFF,
        /* GM Special     */ 0xFF,
        /* Drum Kits      */ 0x07,
        /* Memory A       */ 0xFF,
        /* Memory B       */ 0xFF,
    },

    /* Drum kit descriptors */
    .kits = {
        { 0x0E, 0x08, 0x0000, 0x0028, 0x00F0 },  /* Kit 0: offset=0,    count=40, param=240 */
        { 0x0E, 0x08, 0x04B0, 0x0022, 0x000E },  /* Kit 1: offset=1200, count=34, param=14  */
        { 0x0E, 0x08, 0x0BB8, 0x0022, 0x0006 },  /* Kit 2: offset=3000, count=34, param=6   */
        { 0x0E, 0x08, 0x12C0, 0x0019, 0x0006 },  /* Kit 3: offset=4800, count=25, param=6   */
        { 0x0E, 0x08, 0x19C8, 0x0022, 0x0006 },  /* Kit 4: offset=6600, count=34, param=6   */
    },

    /* Additional metadata */
    .metadata = {
        0x02, 0x0F, 0x8D, 0x11, 0xFF, 0x00, 0x07,
        0x61, 0xB4, 0xE0, 0x00, 0x07, 0x00, 0x3F, 0x00,
    },

    /* Part name table (20 entries x 7 chars, space-padded) */
    .part_names = {
        "MELODY ",  /*  0 */
        "MELODY ",  /*  1 */
        "MELODY ",  /*  2 */
        "MELODY ",  /*  3 */
        "MELODY ",  /*  4 */
        "MELODY ",  /*  5 */
        "MELODY ",  /*  6 */
        "MELODY ",  /*  7 */
        "MELODY ",  /*  8 */
        "MELODY ",  /*  9 */
        "MELODY ",  /* 10 */
        "MELODY ",  /* 11 */
        "DRUM   ",  /* 12 */
        "CHORD  ",  /* 13 */
        "CHORD  ",  /* 14 */
        "CONTROL",  /* 15 */
        "RHYTHM ",  /* 16 */
        "MELODY ",  /* 17 */
        "MELODY ",  /* 18 */
        "MELODY ",  /* 19 */
    },
};
