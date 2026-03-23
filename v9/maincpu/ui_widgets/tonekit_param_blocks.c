/**
 * tonekit_param_blocks.c -- ToneKit sound parameter block definitions
 *
 * Sound parameter configuration for the ToneKit voice initialization system.
 * Most blocks are sequences of 6-byte parameter range records:
 *   { min_value (u16LE), max_value (u16LE), param_id (u16LE) }
 * Two special blocks (ToneKit_DefaultParams, NakaInst_PFTK) use 24-byte
 * fixed-size entries with different internal structure.
 *
 * Total size: 4226 bytes (120 blocks)
 */

#include <stdint.h>
#include <stddef.h>

/* 6-byte parameter range record */
typedef struct __attribute__((packed)) {
    uint16_t min_value;
    uint16_t max_value;
    uint16_t param_id;
} tonekit_param_t;

/* 24-byte special entry (used by ToneKit_DefaultParams and NakaInst_PFTK) */
typedef struct __attribute__((packed)) {
    uint8_t data[24];
} tonekit_special_entry_t;

typedef struct __attribute__((packed)) {
    tonekit_param_t ToneKit_NullParams[2];  /* 12 bytes @ 0xEE4FC6 */
    tonekit_param_t ToneKit_ParamBlock_000[5];  /* 30 bytes @ 0xEE4FD2 */
    tonekit_param_t ToneKit_ParamBlock_001[5];  /* 30 bytes @ 0xEE4FF0 */
    tonekit_param_t ToneKit_ParamBlock_002[5];  /* 30 bytes @ 0xEE500E */
    tonekit_param_t ToneKit_ParamBlock_003[7];  /* 42 bytes @ 0xEE502C */
    tonekit_param_t ToneKit_ParamBlock_004[17];  /* 102 bytes @ 0xEE5056 */
    tonekit_param_t ToneKit_ParamBlock_005[5];  /* 30 bytes @ 0xEE50BC */
    tonekit_param_t ToneKit_ParamBlock_006[7];  /* 42 bytes @ 0xEE50DA */
    tonekit_param_t ToneKit_ParamBlock_007[7];  /* 42 bytes @ 0xEE5104 */
    tonekit_param_t ToneKit_ParamBlock_008[8];  /* 48 bytes @ 0xEE512E */
    tonekit_param_t ToneKit_ParamBlock_009[8];  /* 48 bytes @ 0xEE515E */
    tonekit_param_t ToneKit_ParamBlock_010[16];  /* 96 bytes @ 0xEE518E */
    tonekit_param_t ToneKit_ParamBlock_011[6];  /* 36 bytes @ 0xEE51EE */
    tonekit_param_t ToneKit_ParamBlock_012[6];  /* 36 bytes @ 0xEE5212 */
    tonekit_param_t ToneKit_ParamBlock_013[5];  /* 30 bytes @ 0xEE5236 */
    tonekit_param_t ToneKit_ParamBlock_014[16];  /* 96 bytes @ 0xEE5254 */
    tonekit_param_t ToneKit_ParamBlock_015[5];  /* 30 bytes @ 0xEE52B4 */
    tonekit_param_t ToneKit_ParamBlock_016[5];  /* 30 bytes @ 0xEE52D2 */
    tonekit_param_t ToneKit_ParamBlock_017[6];  /* 36 bytes @ 0xEE52F0 */
    tonekit_param_t ToneKit_ParamBlock_018[5];  /* 30 bytes @ 0xEE5314 */
    tonekit_param_t ToneKit_ParamBlock_019[6];  /* 36 bytes @ 0xEE5332 */
    tonekit_param_t ToneKit_ParamBlock_020[8];  /* 48 bytes @ 0xEE5356 */
    tonekit_param_t ToneKit_ParamBlock_021[7];  /* 42 bytes @ 0xEE5386 */
    tonekit_param_t ToneKit_ParamBlock_022[12];  /* 72 bytes @ 0xEE53B0 */
    tonekit_param_t ToneKit_ParamBlock_023[11];  /* 66 bytes @ 0xEE53F8 */
    tonekit_param_t ToneKit_ParamBlock_024[12];  /* 72 bytes @ 0xEE543A */
    tonekit_param_t ToneKit_ParamBlock_025[14];  /* 84 bytes @ 0xEE5482 */
    tonekit_param_t ToneKit_ParamBlock_026[11];  /* 66 bytes @ 0xEE54D6 */
    tonekit_param_t ToneKit_ParamBlock_027[14];  /* 84 bytes @ 0xEE5518 */
    tonekit_param_t ToneKit_ParamBlock_028[10];  /* 60 bytes @ 0xEE556C */
    tonekit_param_t ToneKit_ParamBlock_029[5];  /* 30 bytes @ 0xEE55A8 */
    tonekit_param_t ToneKit_ParamBlock_030[5];  /* 30 bytes @ 0xEE55C6 */
    tonekit_param_t ToneKit_ParamBlock_031[5];  /* 30 bytes @ 0xEE55E4 */
    tonekit_param_t ToneKit_ParamBlock_032[5];  /* 30 bytes @ 0xEE5602 */
    tonekit_param_t ToneKit_ParamBlock_033[5];  /* 30 bytes @ 0xEE5620 */
    tonekit_param_t ToneKit_ParamBlock_034[5];  /* 30 bytes @ 0xEE563E */
    tonekit_param_t ToneKit_ParamBlock_035[5];  /* 30 bytes @ 0xEE565C */
    tonekit_param_t ToneKit_ParamBlock_036[5];  /* 30 bytes @ 0xEE567A */
    tonekit_param_t ToneKit_ParamBlock_037[5];  /* 30 bytes @ 0xEE5698 */
    tonekit_param_t ToneKit_ParamBlock_038[5];  /* 30 bytes @ 0xEE56B6 */
    tonekit_param_t ToneKit_ParamBlock_039[5];  /* 30 bytes @ 0xEE56D4 */
    tonekit_param_t ToneKit_ParamBlock_040[5];  /* 30 bytes @ 0xEE56F2 */
    tonekit_param_t ToneKit_ParamBlock_041[9];  /* 54 bytes @ 0xEE5710 */
    tonekit_param_t ToneKit_ParamBlock_042[10];  /* 60 bytes @ 0xEE5746 */
    tonekit_param_t ToneKit_ParamBlock_043[12];  /* 72 bytes @ 0xEE5782 */
    tonekit_param_t ToneKit_ParamBlock_044[9];  /* 54 bytes @ 0xEE57CA */
    tonekit_param_t ToneKit_ParamBlock_045[9];  /* 54 bytes @ 0xEE5800 */
    tonekit_param_t ToneKit_ParamBlock_046[12];  /* 72 bytes @ 0xEE5836 */
    tonekit_param_t ToneKit_ParamBlock_047[12];  /* 72 bytes @ 0xEE587E */
    tonekit_param_t ToneKit_ParamBlock_048[13];  /* 78 bytes @ 0xEE58C6 */
    tonekit_param_t ToneKit_ParamBlock_049[13];  /* 78 bytes @ 0xEE5914 */
    tonekit_param_t ToneKit_ParamBlock_050[2];  /* 12 bytes @ 0xEE5962 */
    tonekit_param_t ToneKit_ParamBlock_051[2];  /* 12 bytes @ 0xEE596E */
    tonekit_param_t ToneKit_ParamBlock_052[2];  /* 12 bytes @ 0xEE597A */
    tonekit_param_t ToneKit_ParamBlock_053[2];  /* 12 bytes @ 0xEE5986 */
    tonekit_param_t ToneKit_ParamBlock_054[5];  /* 30 bytes @ 0xEE5992 */
    tonekit_param_t ToneKit_ParamBlock_055[5];  /* 30 bytes @ 0xEE59B0 */
    tonekit_param_t ToneKit_ParamBlock_056[5];  /* 30 bytes @ 0xEE59CE */
    tonekit_param_t ToneKit_ParamBlock_057[5];  /* 30 bytes @ 0xEE59EC */
    tonekit_param_t ToneKit_ParamBlock_058[9];  /* 54 bytes @ 0xEE5A0A */
    tonekit_special_entry_t ToneKit_DefaultParams;  /* 24 bytes @ 0xEE5A40 */
    tonekit_special_entry_t NakaInst_PFTK;  /* 24 bytes @ 0xEE5A58 */
    tonekit_param_t ToneKit_ParamBlock_059[4];  /* 24 bytes @ 0xEE5A70 */
    tonekit_param_t ToneKit_ParamBlock_060[4];  /* 24 bytes @ 0xEE5A88 */
    tonekit_param_t ToneKit_ParamBlock_061[4];  /* 24 bytes @ 0xEE5AA0 */
    tonekit_param_t ToneKit_ParamBlock_062[4];  /* 24 bytes @ 0xEE5AB8 */
    tonekit_param_t ToneKit_ParamBlock_063[4];  /* 24 bytes @ 0xEE5AD0 */
    tonekit_param_t ToneKit_ParamBlock_064[4];  /* 24 bytes @ 0xEE5AE8 */
    tonekit_param_t ToneKit_ParamBlock_065[4];  /* 24 bytes @ 0xEE5B00 */
    tonekit_param_t ToneKit_ParamBlock_066[4];  /* 24 bytes @ 0xEE5B18 */
    tonekit_param_t ToneKit_ParamBlock_067[4];  /* 24 bytes @ 0xEE5B30 */
    tonekit_param_t ToneKit_ParamBlock_068[4];  /* 24 bytes @ 0xEE5B48 */
    tonekit_param_t ToneKit_ParamBlock_069[4];  /* 24 bytes @ 0xEE5B60 */
    tonekit_param_t ToneKit_ParamBlock_070[4];  /* 24 bytes @ 0xEE5B78 */
    tonekit_param_t ToneKit_ParamBlock_071[4];  /* 24 bytes @ 0xEE5B90 */
    tonekit_param_t ToneKit_ParamBlock_072[4];  /* 24 bytes @ 0xEE5BA8 */
    tonekit_param_t ToneKit_ParamBlock_073[4];  /* 24 bytes @ 0xEE5BC0 */
    tonekit_param_t ToneKit_ParamBlock_074[4];  /* 24 bytes @ 0xEE5BD8 */
    tonekit_param_t ToneKit_ParamBlock_075[4];  /* 24 bytes @ 0xEE5BF0 */
    tonekit_param_t ToneKit_ParamBlock_076[4];  /* 24 bytes @ 0xEE5C08 */
    tonekit_param_t ToneKit_ParamBlock_077[4];  /* 24 bytes @ 0xEE5C20 */
    tonekit_param_t ToneKit_ParamBlock_078[4];  /* 24 bytes @ 0xEE5C38 */
    tonekit_param_t ToneKit_ParamBlock_079[4];  /* 24 bytes @ 0xEE5C50 */
    tonekit_param_t ToneKit_ParamBlock_080[4];  /* 24 bytes @ 0xEE5C68 */
    tonekit_param_t ToneKit_ParamBlock_081[4];  /* 24 bytes @ 0xEE5C80 */
    tonekit_param_t ToneKit_ParamBlock_082[4];  /* 24 bytes @ 0xEE5C98 */
    tonekit_param_t ToneKit_ParamBlock_083[4];  /* 24 bytes @ 0xEE5CB0 */
    tonekit_param_t ToneKit_ParamBlock_084[4];  /* 24 bytes @ 0xEE5CC8 */
    tonekit_param_t ToneKit_ParamBlock_085[4];  /* 24 bytes @ 0xEE5CE0 */
    tonekit_param_t ToneKit_ParamBlock_086[4];  /* 24 bytes @ 0xEE5CF8 */
    tonekit_param_t ToneKit_ParamBlock_087[4];  /* 24 bytes @ 0xEE5D10 */
    tonekit_param_t ToneKit_ParamBlock_088[4];  /* 24 bytes @ 0xEE5D28 */
    tonekit_param_t ToneKit_ParamBlock_089[4];  /* 24 bytes @ 0xEE5D40 */
    tonekit_param_t ToneKit_ParamBlock_090[4];  /* 24 bytes @ 0xEE5D58 */
    tonekit_param_t ToneKit_ParamBlock_091[4];  /* 24 bytes @ 0xEE5D70 */
    tonekit_param_t ToneKit_ParamBlock_092[4];  /* 24 bytes @ 0xEE5D88 */
    tonekit_param_t ToneKit_ParamBlock_093[4];  /* 24 bytes @ 0xEE5DA0 */
    tonekit_param_t ToneKit_ParamBlock_094[4];  /* 24 bytes @ 0xEE5DB8 */
    tonekit_param_t ToneKit_ParamBlock_095[4];  /* 24 bytes @ 0xEE5DD0 */
    tonekit_param_t ToneKit_ParamBlock_096[4];  /* 24 bytes @ 0xEE5DE8 */
    tonekit_param_t ToneKit_ParamBlock_097[4];  /* 24 bytes @ 0xEE5E00 */
    tonekit_param_t ToneKit_ParamBlock_098[4];  /* 24 bytes @ 0xEE5E18 */
    tonekit_param_t ToneKit_ParamBlock_099[4];  /* 24 bytes @ 0xEE5E30 */
    tonekit_param_t ToneKit_ParamBlock_100[4];  /* 24 bytes @ 0xEE5E48 */
    tonekit_param_t ToneKit_ParamBlock_101[4];  /* 24 bytes @ 0xEE5E60 */
    tonekit_param_t ToneKit_ParamBlock_102[4];  /* 24 bytes @ 0xEE5E78 */
    tonekit_param_t ToneKit_ParamBlock_103[4];  /* 24 bytes @ 0xEE5E90 */
    tonekit_param_t ToneKit_ParamBlock_104[4];  /* 24 bytes @ 0xEE5EA8 */
    tonekit_param_t ToneKit_ParamBlock_105[4];  /* 24 bytes @ 0xEE5EC0 */
    tonekit_param_t ToneKit_ParamBlock_106[4];  /* 24 bytes @ 0xEE5ED8 */
    tonekit_param_t ToneKit_ParamBlock_107[4];  /* 24 bytes @ 0xEE5EF0 */
    tonekit_param_t ToneKit_ParamBlock_108[4];  /* 24 bytes @ 0xEE5F08 */
    tonekit_param_t ToneKit_ParamBlock_109[4];  /* 24 bytes @ 0xEE5F20 */
    tonekit_param_t ToneKit_ParamBlock_110[4];  /* 24 bytes @ 0xEE5F38 */
    tonekit_param_t ToneKit_ParamBlock_111[4];  /* 24 bytes @ 0xEE5F50 */
    tonekit_param_t ToneKit_ParamBlock_112[4];  /* 24 bytes @ 0xEE5F68 */
    tonekit_param_t ToneKit_ParamBlock_113[4];  /* 24 bytes @ 0xEE5F80 */
    tonekit_param_t ToneKit_ParamBlock_114[4];  /* 24 bytes @ 0xEE5F98 */
    tonekit_param_t ToneKit_ParamBlock_115[4];  /* 24 bytes @ 0xEE5FB0 */
    tonekit_param_t ToneKit_ParamBlock_116_records[21];  /* 126 bytes */
    uint8_t ToneKit_ParamBlock_116_trailing[2];  /* 2 bytes */
} tonekit_all_params_t;

_Static_assert(sizeof(tonekit_all_params_t) == 4226,
    "tonekit_all_params must be exactly 4226 bytes");

const tonekit_all_params_t tonekit_param_data
    __attribute__((section(".text"), used)) = {

    /* ToneKit_NullParams — 2 records, 12 bytes @ 0xEE4FC6 */
    .ToneKit_NullParams = {
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_000 — 5 records, 30 bytes @ 0xEE4FD2 */
    .ToneKit_ParamBlock_000 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_001 — 5 records, 30 bytes @ 0xEE4FF0 */
    .ToneKit_ParamBlock_001 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_002 — 5 records, 30 bytes @ 0xEE500E */
    .ToneKit_ParamBlock_002 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_003 — 7 records, 42 bytes @ 0xEE502C */
    .ToneKit_ParamBlock_003 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0100, 0x1A00, 0x2000 },
        { 0x0000, 0x6300, 0x0600 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_004 — 17 records, 102 bytes @ 0xEE5056 */
    .ToneKit_ParamBlock_004 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_005 — 5 records, 30 bytes @ 0xEE50BC */
    .ToneKit_ParamBlock_005 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_006 — 7 records, 42 bytes @ 0xEE50DA */
    .ToneKit_ParamBlock_006 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0900 },
        { 0x0000, 0x6300, 0x4700 },
        { 0x0000, 0x6300, 0x0A00 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_007 — 7 records, 42 bytes @ 0xEE5104 */
    .ToneKit_ParamBlock_007 = {
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0x6300, 0x3600 },
        { 0x0000, 0x6300, 0x3700 },
        { 0x0000, 0x5E01, 0x1600 },
        { 0x0000, 0x5E01, 0x1700 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_008 — 8 records, 48 bytes @ 0xEE512E */
    .ToneKit_ParamBlock_008 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x9DFF, 0x6300, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_009 — 8 records, 48 bytes @ 0xEE515E */
    .ToneKit_ParamBlock_009 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x9DFF, 0x6300, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_010 — 16 records, 96 bytes @ 0xEE518E */
    .ToneKit_ParamBlock_010 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x1400 },
        { 0x0000, 0x6300, 0x4800 },
        { 0x0000, 0x6300, 0x4900 },
        { 0x0000, 0x6300, 0x0F00 },
        { 0x0000, 0x6300, 0x1000 },
        { 0x0000, 0x6300, 0x1100 },
        { 0x0000, 0x6300, 0x4A00 },
        { 0x0000, 0x6300, 0x1200 },
        { 0x0000, 0x6300, 0x1300 },
        { 0x0000, 0x6300, 0x1000 },
        { 0x0000, 0x6300, 0x1100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x0100, 0x0D00 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_011 — 6 records, 36 bytes @ 0xEE51EE */
    .ToneKit_ParamBlock_011 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_012 — 6 records, 36 bytes @ 0xEE5212 */
    .ToneKit_ParamBlock_012 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_013 — 5 records, 30 bytes @ 0xEE5236 */
    .ToneKit_ParamBlock_013 = {
        { 0x0000, 0x0200, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0x6300, 0x3A00 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_014 — 16 records, 96 bytes @ 0xEE5254 */
    .ToneKit_ParamBlock_014 = {
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x1400 },
        { 0x0000, 0x6300, 0x4800 },
        { 0x0000, 0x6300, 0x4900 },
        { 0x0000, 0x6300, 0x0F00 },
        { 0x0000, 0x6300, 0x1000 },
        { 0x0000, 0x6300, 0x1100 },
        { 0x0000, 0x6300, 0x4A00 },
        { 0x0000, 0x6300, 0x1200 },
        { 0x0000, 0x6300, 0x1300 },
        { 0x0000, 0x6300, 0x1000 },
        { 0x0000, 0x6300, 0x1100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x0100, 0x0D00 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_015 — 5 records, 30 bytes @ 0xEE52B4 */
    .ToneKit_ParamBlock_015 = {
        { 0x0000, 0x6300, 0x1500 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_016 — 5 records, 30 bytes @ 0xEE52D2 */
    .ToneKit_ParamBlock_016 = {
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2C00 },
        { 0x0000, 0x6300, 0x2D00 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_017 — 6 records, 36 bytes @ 0xEE52F0 */
    .ToneKit_ParamBlock_017 = {
        { 0x0000, 0x6300, 0x2E00 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2F00 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_018 — 5 records, 30 bytes @ 0xEE5314 */
    .ToneKit_ParamBlock_018 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_019 — 6 records, 36 bytes @ 0xEE5332 */
    .ToneKit_ParamBlock_019 = {
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2900 },
        { 0x0000, 0x5A00, 0x2A00 },
        { 0x0000, 0x5A00, 0x2B00 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_020 — 8 records, 48 bytes @ 0xEE5356 */
    .ToneKit_ParamBlock_020 = {
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0900 },
        { 0x0000, 0x6300, 0x4000 },
        { 0x0000, 0x6300, 0x4100 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_021 — 7 records, 42 bytes @ 0xEE5386 */
    .ToneKit_ParamBlock_021 = {
        { 0x0000, 0x5E01, 0x1600 },
        { 0x0000, 0x5E01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_022 — 12 records, 72 bytes @ 0xEE53B0 */
    .ToneKit_ParamBlock_022 = {
        { 0x0000, 0xBC02, 0x4B00 },
        { 0x0000, 0xBC02, 0x4C00 },
        { 0x0000, 0xBC02, 0x4D00 },
        { 0x0000, 0xBC02, 0x4E00 },
        { 0x0000, 0x6300, 0x4F00 },
        { 0x0000, 0x6300, 0x5000 },
        { 0x0000, 0x6300, 0x5100 },
        { 0x0000, 0x6300, 0x5200 },
        { 0x9DFF, 0x6300, 0x3900 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_023 — 11 records, 66 bytes @ 0xEE53F8 */
    .ToneKit_ParamBlock_023 = {
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x1B00 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_024 — 12 records, 72 bytes @ 0xEE543A */
    .ToneKit_ParamBlock_024 = {
        { 0x0000, 0x6300, 0x4300 },
        { 0x0000, 0xB400, 0x1600 },
        { 0x0000, 0xB400, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x4400 },
        { 0x0000, 0xB400, 0x1600 },
        { 0x0000, 0xB400, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_025 — 14 records, 84 bytes @ 0xEE5482 */
    .ToneKit_ParamBlock_025 = {
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x1C00 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x9DFF, 0x6300, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_026 — 11 records, 66 bytes @ 0xEE54D6 */
    .ToneKit_ParamBlock_026 = {
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_027 — 14 records, 84 bytes @ 0xEE5518 */
    .ToneKit_ParamBlock_027 = {
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x1D00 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x9DFF, 0x6300, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_028 — 10 records, 60 bytes @ 0xEE556C */
    .ToneKit_ParamBlock_028 = {
        { 0x0000, 0x0200, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0x6300, 0x3A00 },
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_029 — 5 records, 30 bytes @ 0xEE55A8 */
    .ToneKit_ParamBlock_029 = {
        { 0x0000, 0x4D00, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_030 — 5 records, 30 bytes @ 0xEE55C6 */
    .ToneKit_ParamBlock_030 = {
        { 0x0000, 0x4D00, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_031 — 5 records, 30 bytes @ 0xEE55E4 */
    .ToneKit_ParamBlock_031 = {
        { 0x0000, 0x4D00, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_032 — 5 records, 30 bytes @ 0xEE5602 */
    .ToneKit_ParamBlock_032 = {
        { 0x0000, 0x4D00, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_033 — 5 records, 30 bytes @ 0xEE5620 */
    .ToneKit_ParamBlock_033 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_034 — 5 records, 30 bytes @ 0xEE563E */
    .ToneKit_ParamBlock_034 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_035 — 5 records, 30 bytes @ 0xEE565C */
    .ToneKit_ParamBlock_035 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_036 — 5 records, 30 bytes @ 0xEE567A */
    .ToneKit_ParamBlock_036 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_037 — 5 records, 30 bytes @ 0xEE5698 */
    .ToneKit_ParamBlock_037 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_038 — 5 records, 30 bytes @ 0xEE56B6 */
    .ToneKit_ParamBlock_038 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_039 — 5 records, 30 bytes @ 0xEE56D4 */
    .ToneKit_ParamBlock_039 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_040 — 5 records, 30 bytes @ 0xEE56F2 */
    .ToneKit_ParamBlock_040 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0000, 0xC800, 0x2300 },
        { 0x0000, 0x1800, 0x2400 },
        { 0x0000, 0x6300, 0x2500 },
        { 0x0000, 0x7F00, 0x0200 }
    },

    /* ToneKit_ParamBlock_041 — 9 records, 54 bytes @ 0xEE5710 */
    .ToneKit_ParamBlock_041 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x1B00 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_042 — 10 records, 60 bytes @ 0xEE5746 */
    .ToneKit_ParamBlock_042 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_043 — 12 records, 72 bytes @ 0xEE5782 */
    .ToneKit_ParamBlock_043 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x1C00 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x9DFF, 0x6300, 0x0B00 },
        { 0x0000, 0x6300, 0x0C00 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_044 — 9 records, 54 bytes @ 0xEE57CA */
    .ToneKit_ParamBlock_044 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x0700 },
        { 0x0000, 0x6300, 0x0800 },
        { 0x0000, 0xB400, 0x3800 },
        { 0x0000, 0x0200, 0x3100 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_045 — 9 records, 54 bytes @ 0xEE5800 */
    .ToneKit_ParamBlock_045 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2900 },
        { 0x0000, 0x5A00, 0x2A00 },
        { 0x0000, 0x5A00, 0x2B00 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 }
    },

    /* ToneKit_ParamBlock_046 — 12 records, 72 bytes @ 0xEE5836 */
    .ToneKit_ParamBlock_046 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2900 },
        { 0x0000, 0x5A00, 0x2A00 },
        { 0x0000, 0x5A00, 0x2B00 },
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_047 — 12 records, 72 bytes @ 0xEE587E */
    .ToneKit_ParamBlock_047 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x2800 },
        { 0x0000, 0x6300, 0x2900 },
        { 0x0000, 0x5A00, 0x2A00 },
        { 0x0000, 0x5A00, 0x2B00 },
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_048 — 13 records, 78 bytes @ 0xEE58C6 */
    .ToneKit_ParamBlock_048 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_049 — 13 records, 78 bytes @ 0xEE5914 */
    .ToneKit_ParamBlock_049 = {
        { 0x0100, 0x1A00, 0x3300 },
        { 0x0000, 0x1F00, 0x3400 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0000, 0x6300, 0x0400 },
        { 0x0000, 0x6300, 0x0500 },
        { 0x0000, 0x6300, 0x1A00 },
        { 0x0000, 0x2C01, 0x1600 },
        { 0x0000, 0x2C01, 0x1700 },
        { 0x9DFF, 0x6300, 0x1800 },
        { 0x9DFF, 0x6300, 0x1900 },
        { 0x0000, 0x6300, 0x0100 },
        { 0x0000, 0x6300, 0x0300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_050 — 2 records, 12 bytes @ 0xEE5962 */
    .ToneKit_ParamBlock_050 = {
        { 0x0100, 0x6300, 0x5300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_051 — 2 records, 12 bytes @ 0xEE596E */
    .ToneKit_ParamBlock_051 = {
        { 0x0100, 0x6300, 0x5300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_052 — 2 records, 12 bytes @ 0xEE597A */
    .ToneKit_ParamBlock_052 = {
        { 0x0100, 0x6300, 0x5300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_053 — 2 records, 12 bytes @ 0xEE5986 */
    .ToneKit_ParamBlock_053 = {
        { 0x0100, 0x6300, 0x5300 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_ParamBlock_054 — 5 records, 30 bytes @ 0xEE5992 */
    .ToneKit_ParamBlock_054 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0400, 0x1700, 0x2000 },
        { 0x0C00, 0x2400, 0x0600 },
        { 0x0000, 0x7F00, 0x0200 },
        { 0x0000, 0x7F00, 0x5500 }
    },

    /* ToneKit_ParamBlock_055 — 5 records, 30 bytes @ 0xEE59B0 */
    .ToneKit_ParamBlock_055 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0400, 0x1700, 0x2000 },
        { 0x0C00, 0x2400, 0x0600 },
        { 0x0000, 0x7F00, 0x0200 },
        { 0x0000, 0x7F00, 0x5500 }
    },

    /* ToneKit_ParamBlock_056 — 5 records, 30 bytes @ 0xEE59CE */
    .ToneKit_ParamBlock_056 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0400, 0x1700, 0x2000 },
        { 0x0C00, 0x2400, 0x0600 },
        { 0x0000, 0x7F00, 0x0200 },
        { 0x0000, 0x7F00, 0x5500 }
    },

    /* ToneKit_ParamBlock_057 — 5 records, 30 bytes @ 0xEE59EC */
    .ToneKit_ParamBlock_057 = {
        { 0x0F00, 0x6100, 0x2200 },
        { 0x0400, 0x1700, 0x2000 },
        { 0x0C00, 0x2400, 0x0600 },
        { 0x0000, 0x7F00, 0x0200 },
        { 0x0000, 0x7F00, 0x5500 }
    },

    /* ToneKit_ParamBlock_058 — 9 records, 54 bytes @ 0xEE5A0A */
    .ToneKit_ParamBlock_058 = {
        { 0x0000, 0x1600, 0x1E00 },
        { 0x0000, 0x3000, 0x1F00 },
        { 0x0400, 0x1A00, 0x3300 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0400, 0x1A00, 0x3300 },
        { 0x0000, 0x3000, 0x3500 },
        { 0x0800, 0x1A00, 0x2000 },
        { 0x0000, 0x3000, 0x2100 },
        { 0x0000, 0x6300, 0x5500 }
    },

    /* ToneKit_DefaultParams — 24 bytes @ 0xEE5A40 */
    .ToneKit_DefaultParams = { { 0x00, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0xFF } },

    /* NakaInst_PFTK — 24 bytes @ 0xEE5A58 */
    .NakaInst_PFTK = { { 0x20, 0x50, 0x46, 0x54, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0xFF } },

    /* ToneKit_ParamBlock_059 — 4 records, 24 bytes @ 0xEE5A70 */
    .ToneKit_ParamBlock_059 = {
        { 0x5A21, 0x5444, 0x014B },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_060 — 4 records, 24 bytes @ 0xEE5A88 */
    .ToneKit_ParamBlock_060 = {
        { 0x5A22, 0x5442, 0x024B },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_061 — 4 records, 24 bytes @ 0xEE5AA0 */
    .ToneKit_ParamBlock_061 = {
        { 0x1E23, 0x0556, 0x4600 },
        { 0x4B54, 0x0001, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_062 — 4 records, 24 bytes @ 0xEE5AB8 */
    .ToneKit_ParamBlock_062 = {
        { 0x5927, 0x5A58, 0x5A18 },
        { 0x5BD8, 0x5C98, 0x5458 },
        { 0x004B, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_063 — 4 records, 24 bytes @ 0xEE5AD0 */
    .ToneKit_ParamBlock_063 = {
        { 0x1E01, 0x0006, 0x4B54 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_064 — 4 records, 24 bytes @ 0xEE5AE8 */
    .ToneKit_ParamBlock_064 = {
        { 0x1E02, 0x3C06, 0x000F },
        { 0x4B54, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_065 — 4 records, 24 bytes @ 0xEE5B00 */
    .ToneKit_ParamBlock_065 = {
        { 0x3203, 0x6363, 0x1900 },
        { 0x0000, 0x4B54, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_066 — 4 records, 24 bytes @ 0xEE5B18 */
    .ToneKit_ParamBlock_066 = {
        { 0x5004, 0x3C02, 0x5A00 },
        { 0x5400, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_067 — 4 records, 24 bytes @ 0xEE5B30 */
    .ToneKit_ParamBlock_067 = {
        { 0x5005, 0x3C04, 0x5A32 },
        { 0x5400, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_068 — 4 records, 24 bytes @ 0xEE5B48 */
    .ToneKit_ParamBlock_068 = {
        { 0x5A0F, 0x463A, 0x072D },
        { 0x0A0A, 0x283C, 0x4806 },
        { 0x544F, 0x4601, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_069 — 4 records, 24 bytes @ 0xEE5B60 */
    .ToneKit_ParamBlock_069 = {
        { 0x5030, 0x5A08, 0x5400 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_070 — 4 records, 24 bytes @ 0xEE5B78 */
    .ToneKit_ParamBlock_070 = {
        { 0x1432, 0x5A28, 0x5400 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_071 — 4 records, 24 bytes @ 0xEE5B90 */
    .ToneKit_ParamBlock_071 = {
        { 0x0234, 0x6300, 0x4663 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_072 — 4 records, 24 bytes @ 0xEE5BA8 */
    .ToneKit_ParamBlock_072 = {
        { 0x0035, 0x404B, 0x072D },
        { 0x0A0A, 0x283C, 0x4806 },
        { 0x544F, 0x4601, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_073 — 4 records, 24 bytes @ 0xEE5BC0 */
    .ToneKit_ParamBlock_073 = {
        { 0x4036, 0x005A, 0x4654 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_074 — 4 records, 24 bytes @ 0xEE5BD8 */
    .ToneKit_ParamBlock_074 = {
        { 0x0C25, 0x0131, 0x4654 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_075 — 4 records, 24 bytes @ 0xEE5BF0 */
    .ToneKit_ParamBlock_075 = {
        { 0x1408, 0x280C, 0x5405 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_076 — 4 records, 24 bytes @ 0xEE5C08 */
    .ToneKit_ParamBlock_076 = {
        { 0x1E06, 0x0004, 0x0054 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_077 — 4 records, 24 bytes @ 0xEE5C20 */
    .ToneKit_ParamBlock_077 = {
        { 0x0E24, 0x091C, 0x5409 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_078 — 4 records, 24 bytes @ 0xEE5C38 */
    .ToneKit_ParamBlock_078 = {
        { 0x3238, 0x541E, 0x5A51 },
        { 0x5400, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_079 — 4 records, 24 bytes @ 0xEE5C50 */
    .ToneKit_ParamBlock_079 = {
        { 0x0109, 0x015E, 0xC45E },
        { 0x12C4, 0x4654, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_080 — 4 records, 24 bytes @ 0xEE5C68 */
    .ToneKit_ParamBlock_080 = {
        { 0x000A, 0x0188, 0x0110 },
        { 0x0298, 0x0020, 0x3C1E },
        { 0xC463, 0x5412, 0x0046 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_081 — 4 records, 24 bytes @ 0xEE5C80 */
    .ToneKit_ParamBlock_081 = {
        { 0x1440, 0x2C01, 0x2C01 },
        { 0xD8D8, 0x2832, 0x0006 },
        { 0x4654, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_082 — 4 records, 24 bytes @ 0xEE5C98 */
    .ToneKit_ParamBlock_082 = {
        { 0x1E41, 0xB400, 0xB400 },
        { 0xC4C4, 0x001E, 0x0064 },
        { 0xB064, 0x54B0, 0x0046 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_083 — 4 records, 24 bytes @ 0xEE5CB0 */
    .ToneKit_ParamBlock_083 = {
        { 0x1442, 0x2C01, 0x2C01 },
        { 0xD8D8, 0x5050, 0x3C02 },
        { 0x5A32, 0x5400, 0x0046 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_084 — 4 records, 24 bytes @ 0xEE5CC8 */
    .ToneKit_ParamBlock_084 = {
        { 0x1443, 0x2C01, 0x2C01 },
        { 0xD8D8, 0x0628, 0x005A },
        { 0x4654, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_085 — 4 records, 24 bytes @ 0xEE5CE0 */
    .ToneKit_ParamBlock_085 = {
        { 0x1444, 0x2C01, 0x2C01 },
        { 0xD8D8, 0x5050, 0x3C04 },
        { 0x5A32, 0x5400, 0x0046 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_086 — 4 records, 24 bytes @ 0xEE5CF8 */
    .ToneKit_ParamBlock_086 = {
        { 0x0246, 0x6300, 0x0114 },
        { 0x012C, 0xD82C, 0x63D8 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_087 — 4 records, 24 bytes @ 0xEE5D10 */
    .ToneKit_ParamBlock_087 = {
        { 0x1310, 0x0C00, 0x3212 },
        { 0x005E, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_088 — 4 records, 24 bytes @ 0xEE5D28 */
    .ToneKit_ParamBlock_088 = {
        { 0x1911, 0x0C00, 0x3214 },
        { 0x005A, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_089 — 4 records, 24 bytes @ 0xEE5D40 */
    .ToneKit_ParamBlock_089 = {
        { 0x2312, 0x2D00, 0x320C },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_090 — 4 records, 24 bytes @ 0xEE5D58 */
    .ToneKit_ParamBlock_090 = {
        { 0x2913, 0x2D00, 0x3210 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_091 — 4 records, 24 bytes @ 0xEE5D70 */
    .ToneKit_ParamBlock_091 = {
        { 0x2314, 0x0B00, 0x3214 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_092 — 4 records, 24 bytes @ 0xEE5D88 */
    .ToneKit_ParamBlock_092 = {
        { 0x2715, 0x3C00, 0x5012 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_093 — 4 records, 24 bytes @ 0xEE5DA0 */
    .ToneKit_ParamBlock_093 = {
        { 0x2D16, 0x2D00, 0x320C },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_094 — 4 records, 24 bytes @ 0xEE5DB8 */
    .ToneKit_ParamBlock_094 = {
        { 0x3717, 0x5A00, 0x320C },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_095 — 4 records, 24 bytes @ 0xEE5DD0 */
    .ToneKit_ParamBlock_095 = {
        { 0x2918, 0x1900, 0x3214 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_096 — 4 records, 24 bytes @ 0xEE5DE8 */
    .ToneKit_ParamBlock_096 = {
        { 0x2D19, 0x1E00, 0x3206 },
        { 0x0032, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_097 — 4 records, 24 bytes @ 0xEE5E00 */
    .ToneKit_ParamBlock_097 = {
        { 0x2D1A, 0x2D00, 0x3212 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_098 — 4 records, 24 bytes @ 0xEE5E18 */
    .ToneKit_ParamBlock_098 = {
        { 0x371B, 0x2D00, 0x3212 },
        { 0x0046, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_099 — 4 records, 24 bytes @ 0xEE5E30 */
    .ToneKit_ParamBlock_099 = {
        { 0x5C47, 0x3264, 0x061E },
        { 0x5400, 0x004B, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_100 — 4 records, 24 bytes @ 0xEE5E48 */
    .ToneKit_ParamBlock_100 = {
        { 0x5C48, 0x1464, 0x2C01 },
        { 0x2C01, 0xD8D8, 0x4B54 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_101 — 4 records, 24 bytes @ 0xEE5E60 */
    .ToneKit_ParamBlock_101 = {
        { 0x5C49, 0x5064, 0x0250 },
        { 0x323C, 0x005A, 0x4B54 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_102 — 4 records, 24 bytes @ 0xEE5E78 */
    .ToneKit_ParamBlock_102 = {
        { 0x5C4A, 0x2864, 0x5A06 },
        { 0x5400, 0x004B, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_103 — 4 records, 24 bytes @ 0xEE5E90 */
    .ToneKit_ParamBlock_103 = {
        { 0x5C4B, 0x0E64, 0x091C },
        { 0x5409, 0x004B, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_104 — 4 records, 24 bytes @ 0xEE5EA8 */
    .ToneKit_ParamBlock_104 = {
        { 0x5C60, 0x0E64, 0x091C },
        { 0x4109, 0x5442, 0x004B },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_105 — 4 records, 24 bytes @ 0xEE5EC0 */
    .ToneKit_ParamBlock_105 = {
        { 0x5C61, 0x0E64, 0x091C },
        { 0x5009, 0x5450, 0x014B },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_106 — 4 records, 24 bytes @ 0xEE5ED8 */
    .ToneKit_ParamBlock_106 = {
        { 0x5C62, 0x5064, 0x1444 },
        { 0x2C01, 0x2C01, 0xD8D8 },
        { 0x4B54, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_107 — 4 records, 24 bytes @ 0xEE5EF0 */
    .ToneKit_ParamBlock_107 = {
        { 0x5C63, 0x5064, 0x1450 },
        { 0x2C01, 0x2C01, 0xD8D8 },
        { 0x4B54, 0x0001, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_108 — 4 records, 24 bytes @ 0xEE5F08 */
    .ToneKit_ParamBlock_108 = {
        { 0x3239, 0x0054, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_109 — 4 records, 24 bytes @ 0xEE5F20 */
    .ToneKit_ParamBlock_109 = {
        { 0x323A, 0x0054, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_110 — 4 records, 24 bytes @ 0xEE5F38 */
    .ToneKit_ParamBlock_110 = {
        { 0x323B, 0x0054, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_111 — 4 records, 24 bytes @ 0xEE5F50 */
    .ToneKit_ParamBlock_111 = {
        { 0x633C, 0x0054, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_112 — 4 records, 24 bytes @ 0xEE5F68 */
    .ToneKit_ParamBlock_112 = {
        { 0x2358, 0x9C03, 0x3254 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_113 — 4 records, 24 bytes @ 0xEE5F80 */
    .ToneKit_ParamBlock_113 = {
        { 0x2359, 0x9C03, 0x3254 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_114 — 4 records, 24 bytes @ 0xEE5F98 */
    .ToneKit_ParamBlock_114 = {
        { 0x2D5A, 0x9C03, 0x3254 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_115 — 4 records, 24 bytes @ 0xEE5FB0 */
    .ToneKit_ParamBlock_115 = {
        { 0x235B, 0x9C03, 0x3254 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 }
    },

    /* ToneKit_ParamBlock_116 — 21 records + 2 trailing, 128 bytes @ 0xEE5FC8 */
    .ToneKit_ParamBlock_116_records = {
        { 0x014F, 0x03D8, 0x0598 },
        { 0x0518, 0x54D8, 0x0000 },
        { 0x0000, 0x0000, 0x0000 },
        { 0x0000, 0x0000, 0xFF63 },
        { 0x0505, 0x0707, 0x0808 },
        { 0x0505, 0x0706, 0x050C },
        { 0x0505, 0x1005, 0x0505 },
        { 0x0505, 0x0505, 0x0505 },
        { 0x0505, 0x0505, 0x0505 },
        { 0x0505, 0x0505, 0x0705 },
        { 0x0506, 0x1105, 0x0505 },
        { 0x0505, 0x0505, 0x0505 },
        { 0x0506, 0x0506, 0x1005 },
        { 0x0505, 0x0208, 0x0202 },
        { 0x0502, 0x0505, 0x0C0B },
        { 0x0B0E, 0x050E, 0x090A },
        { 0x0C0A, 0x0909, 0x0505 },
        { 0x0905, 0x0505, 0x0505 },
        { 0x0505, 0x0505, 0x0505 },
        { 0x0505, 0x0505, 0x0505 },
        { 0x0C0C, 0x0D0D, 0x4FC6 }
    },
    .ToneKit_ParamBlock_116_trailing = { 0xEE, 0x00 },

};

