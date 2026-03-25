/**
 * tonegen_param_table.c — Feature Demo text / Sound Engine parameter table
 *
 * Base ROM address: 0xE0E407
 * Total size: 1389 bytes
 *
 * Despite its name, this table is used by the Feature Demo text system
 * (fdemotext_routines.s) for language-indexed Sound Engine menu pointers,
 * parameter size tables, SE function pointers, NAKA init data block
 * references, and FtLangText strings (Feature Text Language Text).
 *
 * Structure (7 sections):
 *   A. SE command rows: 10 full rows + 1 partial row of tagged 4-byte entries (752 bytes)
 *      Each entry: { prefix_hi, prefix_lo, value_lo, value_hi }
 *      prefix=0xF000: SE function ref (value = low 16 bits of 0x00F0XXXX address)
 *      prefix=0x0000: alt entry (row-specific parameter)
 *      value=0x6B4A: sentinel (SeMenu_BitShift_Stub)
 *      value=0x0000 with prefix=0xF000: NULL (row divider at column 6)
 *   B. Parameter size table: 27 x uint16_t (54 bytes)
 *   C. SE function pointer table: 32 x uint32_t (128 bytes)
 *   D. Flag byte: 0xFF (1 byte)
 *   E. NAKA init data block pointers: 18 x uint32_t (72 bytes)
 *   F. NULL terminator: uint32_t = 0 (4 bytes)
 *   G. FtLangText string pointers: 19 x uint32_t (76 bytes)
 *   H-J. String data + padding + trailer (302 bytes)
 */

#include <stdint.h>

/* ── Constants ── */
#define SENTINEL  0x6B4A  /* SeMenu_BitShift_Stub low word */
#define SE_PREFIX 0xF000  /* Normal SE function entry prefix */
#define ALT_PREFIX 0x0000 /* Alt-type entry prefix */

/* ── Tagged entry type (4 bytes) ── */
/* Each entry stores: [prefix_hi] [prefix_lo] [value_lo] [value_hi]
 * This is NOT a standard LE integer — it's two big-endian bytes
 * followed by a 16-bit LE value. We use a packed struct to match. */
typedef struct __attribute__((packed)) {
    uint8_t  prefix_hi;  /* 0xF0 for normal, 0x00 for alt/null */
    uint8_t  prefix_lo;  /* 0x00 always */
    uint16_t value;       /* 16-bit LE: function ref, sentinel, or 0 */
} se_entry_t;

/* ── Row type (18 entries = 72 bytes) ── */
typedef struct __attribute__((packed)) {
    se_entry_t entries[6];  /* columns 0-5: normal SE entries */
    se_entry_t null_entry;  /* column 6: always {0xF0, 0x00, 0x0000} */
    se_entry_t alt_entry;   /* column 7: {0x00, 0x00, value} (alt type) */
    se_entry_t entries2[10]; /* columns 8-17: normal SE entries */
} se_row_t;

/* ── Partial row (8 entries = 32 bytes) ── */
typedef struct __attribute__((packed)) {
    se_entry_t entries[6];  /* columns 0-5 */
    se_entry_t null_entry;  /* column 6: NULL */
    se_entry_t alt_entry;   /* column 7: {0x00, 0x00, 0x0000} */
} se_partial_row_t;

/* ── FtLangText string entry (14 bytes: 0xFF + "FtLangTextNN" + NUL) ── */
/* Exception: FtLangText01S is 15 bytes, FtLangText01 has no 0xFF prefix (13 bytes) */

/* ── Main table struct ── */
typedef struct __attribute__((packed)) {
    /* Section A: SE command rows (752 bytes) */
    se_row_t rows[10];                /* 10 full rows x 72 = 720 bytes */
    se_partial_row_t partial_row;     /* 1 partial row = 32 bytes */

    /* Section B: Parameter sizes (54 bytes) */
    uint16_t param_sizes[27];

    /* Section C: SE function pointers (128 bytes) */
    uint32_t se_func_ptrs[32];

    /* Section D: Flag byte (1 byte) */
    uint8_t flag_byte;

    /* Section E: NAKA init data block pointers (72 bytes) */
    uint32_t naka_init_ptrs[18];

    /* Section F: NULL terminator (4 bytes) */
    uint32_t null_terminator;

    /* Section G: FtLangText string pointers (76 bytes) */
    uint32_t string_ptrs[19];

    /* Sections H-J: String data + padding + trailer (302 bytes) */
    uint8_t string_data[302];
} tonegen_param_table_t;

_Static_assert(sizeof(tonegen_param_table_t) == 1389,
    "tonegen_param_table must be exactly 1389 bytes");

/* ── Helper macros ── */
#define SE(val)   { 0xF0, 0x00, (val) }           /* Normal SE entry */
#define SENT      { 0xF0, 0x00, SENTINEL }         /* Sentinel entry */
#define ENULL     { 0xF0, 0x00, 0x0000 }           /* NULL entry (row divider) */
#define ALT(val)  { 0x00, 0x00, (val) }            /* Alt-type entry */

const tonegen_param_table_t tonegen_param_table_data
    __attribute__((section(".text"), used)) = {

    /* ================================================================
     * Section A: SE command rows
     * 10 full rows + 1 partial row
     * Each row: 6 entries, NULL divider, alt entry, 10 more entries
     * ================================================================ */
    .rows = {
        /* Row 0 */
        { .entries = { SE(0xC5C3), SE(0xC62A), SENT, SENT, SE(0xC6C2), SENT },
          .null_entry = ENULL, .alt_entry = ALT(0xC7BF),
          .entries2 = { SE(0xC817), SE(0xC88B), SENT, SENT,
                        SE(0xC8EE), SE(0xC96E), SE(0xC9D6), SE(0xCA45),
                        SE(0xCA4E), SE(0xCA5E) } },
        /* Row 1 */
        { .entries = { SE(0xCA6E), SE(0xCA7E), SENT, SENT, SE(0xCA9A), SE(0xCA8E) },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SE(0xCAAC), SENT, SE(0xCBAD), SENT,
                        SE(0xCC12), SE(0xCCCC), SENT, SE(0xCD16),
                        SE(0xCD1F), SE(0xCD2F) } },
        /* Row 2 */
        { .entries = { SE(0xCD3F), SE(0xCD4F), SENT, SENT, SE(0xCD6D), SE(0xCD5F) },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SENT, SE(0xCD81), SE(0xCDEB), SE(0xCE66),
                        SE(0xCEE1), SENT, SENT, SE(0xCF4B),
                        SE(0xCF54), SE(0xCF6C) } },
        /* Row 3 */
        { .entries = { SE(0xCF8B), SE(0xCFA3), SENT, SENT, SE(0xCFBB), SENT },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SENT, SE(0xCFCF), SE(0xD040), SE(0xD0BF),
                        SE(0xD13E), SENT, SENT, SE(0xD1AF),
                        SE(0xD1B8), SE(0xD1D7) } },
        /* Row 4 */
        { .entries = { SE(0xD1EF), SE(0xD207), SENT, SENT, SE(0xD21F), SENT },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SE(0xD297), SE(0xD31C), SENT, SENT,
                        SE(0xD392), SENT, SE(0xD233), SE(0xD62C),
                        SE(0xD635), SE(0xD64D) } },
        /* Row 5 */
        { .entries = { SE(0xD665), SE(0xD691), SENT, SENT, SE(0xD6E6), SE(0xD6BD) },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SENT, SENT, SE(0xD811), SENT,
                        SENT, SENT, SENT, SE(0xDA0E),
                        SE(0xDA22), SE(0xDA5C) } },
        /* Row 6 */
        { .entries = { SE(0xDA96), SE(0xDAD0), SENT, SENT, SE(0xDB0B), SENT },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SENT, SENT, SENT, SENT,
                        SENT, SENT, SENT, SE(0xE08E),
                        SENT, SE(0xE0C3) } },
        /* Row 7 */
        { .entries = { SE(0xE136), SE(0xE1A9), SENT, SENT, SE(0xE1B7), SENT },
          .null_entry = ENULL, .alt_entry = ALT(0xE1CB),
          .entries2 = { SE(0xE1CE), SE(0xE1D1), SE(0xE1D4), SE(0xE1D7),
                        SE(0xE1DA), SE(0xE1DD), SE(0xE1EE), SE(0xE1F1),
                        SE(0xE257), SENT } },
        /* Row 8 */
        { .entries = { SENT, SENT, SENT, SENT, SE(0xE25E), SENT },
          .null_entry = ENULL, .alt_entry = ALT(0xDB19),
          .entries2 = { SE(0xDBA0), SE(0xDC35), SE(0xDCE0), SE(0xDD73),
                        SE(0xDE00), SE(0xDE64), SE(0xDED3), SENT,
                        SE(0xDF3B), SE(0xE001) } },
        /* Row 9 */
        { .entries = { SENT, SENT, SENT, SENT, SE(0xE080), SENT },
          .null_entry = ENULL, .alt_entry = ALT(SENTINEL),
          .entries2 = { SENT, SENT, SENT, SENT,
                        SENT, SENT, SENT, SENT,
                        SE(0xE8E4), SE(0xE8F8) } },
    },

    /* Partial row 10 (last row, truncated) */
    .partial_row = {
        .entries = { SENT, SE(0xE90C), SENT, SENT, SE(0xE920), SENT },
        .null_entry = ENULL,
        .alt_entry = ALT(0x0000),
    },

    /* ================================================================
     * Section B: Parameter size table (27 x uint16_t)
     * Size values in bytes for each sound parameter type
     * ================================================================ */
    .param_sizes = {
        0x0000, 0x0000, 0x0000,
        0x0029, 0x0029, 0x0031, 0x0029, 0x0039,
        0x0045, 0x0029, 0x0029,
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x0000, 0x0029, 0x0000,
        0x0029, 0x0031, 0x0000, 0x0000, 0x0000,
        0x0000, 0x0029, 0x0029,
    },

    /* ================================================================
     * Section C: SE function pointers (32 x uint32_t)
     * ROM addresses of Sound Engine menu handler functions/data
     * ================================================================ */
    .se_func_ptrs = {
        0x00F0A162, /* UpdSeSel_ProcessStep */
        0x00F0A6A5, /* UpdSeSel_ExtendedOps_Data */
        0x00F0B3DD, /* SeMenu_AltUpdate */
        0x00F0B554, /* SeMenu_AltUpdate_Data */
        0x00F0B630,
        0x00F0B70F,
        0x00F0B7EE, /* SeMenu_ControllerUpdate */
        0x00F0A786,
        0x00F0A89B,
        0x00F0A931,
        0x00F0A9DB,
        0x00F0AAE3,
        0x00F0AC33,
        0x00F0ACD4,
        0x00F0ADD0,
        0x00F0AE7B,
        0x00F0B04F,
        0x00F0B18B,
        0x00F0B1A6,
        0x00F0B1BD,
        0x00F0B1D4,
        0x00F0B1E7,
        0x00F0B1F6,
        0x00F0B297,
        0x00F0B32D,
        0x00F0B3D7,
        0x00F0BAD8,
        0x00F0AE81,
        0x00F0B00B,
        0x00F0BB7D,
        0x00F0B9C4, /* SeMenu_CopyWriteUpdate_Data */
        0x00F0BABE,
    },

    /* ================================================================
     * Section D: Flag byte
     * ================================================================ */
    .flag_byte = 0xFF,

    /* ================================================================
     * Section E: NAKA init data block pointers (18 x uint32_t)
     * Evenly spaced at 0x11 (17) byte intervals starting at
     * NAKA_InitDataBlock (0xF167AE) + 1
     * ================================================================ */
    .naka_init_ptrs = {
        0x00F167AF, 0x00F167C0, 0x00F167D1, 0x00F167E2,
        0x00F167F3, 0x00F16804, 0x00F16815, 0x00F16826,
        0x00F16837, 0x00F16848, 0x00F16859, 0x00F1686A,
        0x00F1687B, 0x00F1688C, 0x00F1689D, 0x00F168AE,
        0x00F168BF, 0x00F168D0,
    },

    /* ================================================================
     * Section F: NULL terminator
     * ================================================================ */
    .null_terminator = 0x00000000,

    /* ================================================================
     * Section G: FtLangText string pointers (19 x uint32_t)
     * Pointers to FtLangText strings within this table,
     * in reverse order (01 first, 17 last, then empty string)
     * ================================================================ */
    .string_ptrs = {
        0x00E0E936, /* FtLangText01 */
        0x00E0E928, /* FtLangText01S */
        0x00E0E91A, /* FtLangText02 */
        0x00E0E90C, /* FtLangText03 */
        0x00E0E8FE, /* FtLangText04 */
        0x00E0E8F0, /* FtLangText05 */
        0x00E0E8E2, /* FtLangText06 */
        0x00E0E8D4, /* FtLangText07 */
        0x00E0E8C6, /* FtLangText08 */
        0x00E0E8B8, /* FtLangText09 */
        0x00E0E8AA, /* FtLangText10 */
        0x00E0E89C, /* FtLangText11 */
        0x00E0E88E, /* FtLangText12 */
        0x00E0E880, /* FtLangText13 */
        0x00E0E872, /* FtLangText14 */
        0x00E0E864, /* FtLangText15 */
        0x00E0E856, /* FtLangText16 */
        0x00E0E848, /* FtLangText17 */
        0x00E0E846, /* empty string (NUL byte) */
    },

    /* ================================================================
     * Sections H-J: String data + padding + trailer (302 bytes)
     *
     * Layout:
     *   [0]     = 0x00 (empty string target for string_ptrs[18])
     *   [1]     = 0xFF (delimiter)
     *   [2-14]  = "FtLangText17\0"  (13 bytes)
     *   [15]    = 0xFF
     *   [16-28] = "FtLangText16\0"
     *   ... (14 bytes each: 0xFF + 12-char name + NUL)
     *   [239]   = 0xFF
     *   [240-253] = "FtLangText01\0" (13 bytes)
     *   [253]   = 0xFF (trailing delimiter)
     *   [254-295] = 42 bytes of 0x00 padding
     *   [296-299] = 0x72 0xE9 0xE0 0x00 (ROM addr 0x00E0E972)
     *   [300-301] = 0x00 0xFF (final terminator)
     * ================================================================ */
    .string_data = {
        /* Empty string (offset 1087 from table base) */
        0x00,
        /* FtLangText17 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','7', 0x00,
        /* FtLangText16 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','6', 0x00,
        /* FtLangText15 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','5', 0x00,
        /* FtLangText14 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','4', 0x00,
        /* FtLangText13 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','3', 0x00,
        /* FtLangText12 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','2', 0x00,
        /* FtLangText11 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','1', 0x00,
        /* FtLangText10 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','1','0', 0x00,
        /* FtLangText09 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','9', 0x00,
        /* FtLangText08 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','8', 0x00,
        /* FtLangText07 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','7', 0x00,
        /* FtLangText06 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','6', 0x00,
        /* FtLangText05 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','5', 0x00,
        /* FtLangText04 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','4', 0x00,
        /* FtLangText03 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','3', 0x00,
        /* FtLangText02 */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','2', 0x00,
        /* FtLangText01S (14 chars + NUL = 15 bytes with 0xFF prefix = 16) */
        0xFF, 'F','t','L','a','n','g','T','e','x','t','0','1','S', 0x00,
        /* FtLangText01 (no 0xFF prefix — follows directly after) */
        'F','t','L','a','n','g','T','e','x','t','0','1', 0x00,
        /* Trailing delimiter */
        0xFF,
        /* 42 bytes of zero padding */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00,
        /* Trailer: ROM self-reference + terminator */
        0x72, 0xE9, 0xE0, 0x00,  /* 0x00E0E972 */
        0x00, 0xFF,
    },
};
