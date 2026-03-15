/**
 * naka_block_007.c — Widget panel grid descriptors
 *
 * 13 compact dispatch widgets for gridbox settings:
 * GM on/off, LSW function, fade, vocal, I/O, MIDI parts, etc.
 *
 * Base ROM address: 0xE55A36
 * Total size: 402 bytes
 */

#include "naka_types.h"

/* Linked widget descriptors */
extern const char NakaDesc_OnOffStyle_Table;
extern const char NakaDesc_PageGridBox1_Table;
extern const char NakaDesc_PmanOnOff1_Table;
extern const char NakaDesc_PmanOnOff2_Table;

/* Proc handler functions */
extern const char AcCtlMsgGridBoxProc;
extern const char AcFadeSetGridBoxProc;
extern const char AcGMOnOffBoxProc;
extern const char AcInOutGridBoxProc;
extern const char AcLswFuncBoxProc;
extern const char AcLswFuncEditBoxProc;
extern const char AcMidiPartGridBoxProc;
extern const char AcParaLoadOptGridBoxProc;
extern const char AcPcgOutGridBoxProc;
extern const char AcPmemOutLGridBoxProc;
extern const char AcPmemOutRGridBoxProc;
extern const char AcVocalGridBoxProc;

typedef struct __attribute__((packed)) {
    naka_dispatch_t w0;       /* AcGMOnOffBox */
    naka_dispatch_t w1;       /* AcLswFuncEditBox */
    naka_dispatch_t w2;       /* AcLswFuncBox */
    naka_dispatch_t w3;       /* AcFadeSetGridBox */
    naka_dispatch_t w4;       /* AcVocalGridBox */
    naka_dispatch_t w5;       /* AcInOutGridBox */
    naka_dispatch_t w6;       /* AcParaLoadOptGridBox */
    naka_dispatch_t w7;       /* AcPcgOutGridBox */
    naka_dispatch_t w8;       /* AcPmemOutLGridBox */
    naka_dispatch_t w9;       /* AcPmemOutRGridBox */
    naka_dispatch_t w10;      /* AcCtlMsgGridBox */
    naka_dispatch_t w11;      /* AcMidiPartGridBox */
    naka_dispatch_t w12;      /* AcMidiPartGridBox2 */
    uint8_t trailing[90];
} naka_block_007_t;

extern const char NakaLink_E557BC;
extern const char NakaLink_E5584A;
extern const char NakaLink_E55876;
extern const char NakaLink_E558A2;
extern const char NakaLink_E558CE;
extern const char NakaLink_E558FA;
extern const char NakaLink_E55926;
extern const char NakaLink_E55952;
extern const char NakaLink_E559B4;
extern const char NakaCode_XXjn_5B82;
extern const char NakaName_AcMidiPartGridBox;
extern const char NakaCode_XXjn;
extern const char NakaName_AcCtlMsgGridBox;
extern const char NakaCode_XXj_5BB0;
extern const char NakaName_AcPmemOutRGridBox;
extern const char NakaCode_XXj_5BC6;
extern const char NakaName_AcPmemOutLGridBox;
extern const char NakaCode_XXj_5BDC;
extern const char NakaName_AcPcgOutGridBox;
extern const char NakaCode_XXj_5BF0;
extern const char NakaName_AcParaLoadOptGridBox;
extern const char NakaCode_XXj_5C0A;
extern const char NakaName_AcInOutGridBox;
extern const char NakaCode_XXj_5C1E;
extern const char NakaName_AcVocalGridBox;
extern const char NakaCode_XXj;
extern const char NakaName_AcFadeSetGridBox;
extern const char NakaCode_nXXFB_5C48;
extern const char NakaName_AcLswFuncBox;
extern const char NakaCode_nXXFB;
extern const char NakaName_AcLswFuncEditBox;
extern const char NakaCode_E55C74;
extern const char NakaName_AcGMOnOffBox;
extern const char NakaCode_fjXn;
extern const char NakaName_AcSendEditSw;

#define BASE  0x00E55A36u
#define SELF(field) \
    ((uint32_t)(BASE + __builtin_offsetof(naka_block_007_t, field)))

_Static_assert(sizeof(naka_block_007_t) == 402,
    "naka_block_007 must be exactly 402 bytes");

const naka_block_007_t naka_block_007_data
    __attribute__((section(".text"), used)) = {

    /* w0: TYPE_0x1E — AcGMOnOffBox */
    .w0 = {
        .header    = NAKA_HDR(0x1E),
        .field_04  = 0x0034,
        .field_06  = 0x000E,
        .name_ptr  = NAKA_ADDR(NakaName_AcSendEditSw),
        .inst_ptr  = NAKA_ADDR(NakaCode_fjXn),
        .link_ptr  = NAKA_ADDR(NakaDesc_OnOffStyle_Table),
        .proc_addr = NAKA_ADDR(AcGMOnOffBoxProc),
    },

    /* w1: TYPE_0x18 — AcLswFuncEditBox */
    .w1 = {
        .header    = NAKA_HDR(0x18),
        .field_04  = 0x0036,
        .field_06  = 0x0000,
        .name_ptr  = NAKA_ADDR(NakaName_AcGMOnOffBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_E55C74),
        .link_ptr  = NAKA_ADDR(NakaLink_E557BC),
        .proc_addr = NAKA_ADDR(AcLswFuncEditBoxProc),
    },

    /* w2: TYPE_0x15 — AcLswFuncBox */
    .w2 = {
        .header    = NAKA_HDR(0x15),
        .field_04  = 0x0044,
        .field_06  = 0x0012,
        .name_ptr  = NAKA_ADDR(NakaName_AcLswFuncEditBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_nXXFB),
        .link_ptr  = NAKA_ADDR(NakaDesc_PmanOnOff1_Table),
        .proc_addr = NAKA_ADDR(AcLswFuncBoxProc),
    },

    /* w3: TYPE_0x12 — AcFadeSetGridBox */
    .w3 = {
        .header    = NAKA_HDR(0x12),
        .field_04  = 0x0036,
        .field_06  = 0x0012,
        .name_ptr  = NAKA_ADDR(NakaName_AcLswFuncBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_nXXFB_5C48),
        .link_ptr  = NAKA_ADDR(NakaDesc_PmanOnOff2_Table),
        .proc_addr = NAKA_ADDR(AcFadeSetGridBoxProc),
    },

    /* w4: TYPE_0x54 — AcVocalGridBox */
    .w4 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcFadeSetGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj),
        .link_ptr  = NAKA_ADDR(NakaLink_E5584A),
        .proc_addr = NAKA_ADDR(AcVocalGridBoxProc),
    },

    /* w5: TYPE_0x54 — AcInOutGridBox */
    .w5 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcVocalGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5C1E),
        .link_ptr  = NAKA_ADDR(NakaLink_E55876),
        .proc_addr = NAKA_ADDR(AcInOutGridBoxProc),
    },

    /* w6: TYPE_0x54 — AcParaLoadOptGridBox */
    .w6 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcInOutGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5C0A),
        .link_ptr  = NAKA_ADDR(NakaLink_E558A2),
        .proc_addr = NAKA_ADDR(AcParaLoadOptGridBoxProc),
    },

    /* w7: TYPE_0x54 — AcPcgOutGridBox */
    .w7 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcParaLoadOptGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5BF0),
        .link_ptr  = NAKA_ADDR(NakaLink_E558CE),
        .proc_addr = NAKA_ADDR(AcPcgOutGridBoxProc),
    },

    /* w8: TYPE_0x54 — AcPmemOutLGridBox */
    .w8 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcPcgOutGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5BDC),
        .link_ptr  = NAKA_ADDR(NakaLink_E558FA),
        .proc_addr = NAKA_ADDR(AcPmemOutLGridBoxProc),
    },

    /* w9: TYPE_0x54 — AcPmemOutRGridBox */
    .w9 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcPmemOutLGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5BC6),
        .link_ptr  = NAKA_ADDR(NakaLink_E55926),
        .proc_addr = NAKA_ADDR(AcPmemOutRGridBoxProc),
    },

    /* w10: TYPE_0x54 — AcCtlMsgGridBox */
    .w10 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004A,
        .field_06  = 0x000C,
        .name_ptr  = NAKA_ADDR(NakaName_AcPmemOutRGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXj_5BB0),
        .link_ptr  = NAKA_ADDR(NakaLink_E55952),
        .proc_addr = NAKA_ADDR(AcCtlMsgGridBoxProc),
    },

    /* w11: TYPE_0x54 — AcMidiPartGridBox */
    .w11 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004E,
        .field_06  = 0x0010,
        .name_ptr  = NAKA_ADDR(NakaName_AcCtlMsgGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXjn),
        .link_ptr  = NAKA_ADDR(NakaDesc_PageGridBox1_Table),
        .proc_addr = NAKA_ADDR(AcMidiPartGridBoxProc),
    },

    /* w12: TYPE_0x54 — AcMidiPartGridBox2 */
    .w12 = {
        .header    = NAKA_HDR(0x54),
        .field_04  = 0x004E,
        .field_06  = 0x0010,
        .name_ptr  = NAKA_ADDR(NakaName_AcMidiPartGridBox),
        .inst_ptr  = NAKA_ADDR(NakaCode_XXjn_5B82),
        .link_ptr  = NAKA_ADDR(NakaLink_E559B4),
        .proc_addr = 0x00000000,
    },

    .trailing = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x58, 0x58, 0x6A, 0x6E, 0x00, 0xFF, 0x41, 0x63, 0x4D, 0x69, 0x64, 0x69,
        0x50, 0x61, 0x72, 0x74, 0x47, 0x72, 0x69, 0x64, 0x42, 0x6F, 0x78, 0x00, 0x58, 0x58, 0x6A, 0x6E,
        0x00, 0xFF, 0x41, 0x63, 0x43, 0x74, 0x6C, 0x4D, 0x73, 0x67, 0x47, 0x72, 0x69, 0x64, 0x42, 0x6F,
        0x78, 0x00, 0x58, 0x58, 0x6A, 0x00, 0x41, 0x63, 0x50, 0x6D, 0x65, 0x6D, 0x4F, 0x75, 0x74, 0x52,
        0x47, 0x72, 0x69, 0x64, 0x42, 0x6F, 0x78, 0x00, 0x58, 0x58
    },
};

#undef SELF
#undef BASE
