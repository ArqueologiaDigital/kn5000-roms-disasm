/**
 * control_menu_header.c — CONTROL MENU screen header (first 9 widgets)
 *
 * Proof-of-concept: NAKA widget descriptors expressed as C structs
 * with named fields instead of raw .byte sequences.
 *
 * Source: control_menu_screens.s lines 3-97
 * ROM address range: 0xED3C96 - 0xED3EE6 (592 bytes)
 *
 * Widgets:
 *   w1: CONTAINER  "CONTROL MENU"
 *   w2: MENU_ITEM  "INITIAL"
 *   w3: MENU_ITEM  "OVERALL TOUCH SENSITIVITY"
 *   w4: MENU_ITEM  "FOOT CONTROLLERS"
 *   w5: MENU_ITEM  "DISPLAY TIME OUT"
 *   w6: MENU_ITEM  "PANEL MEMORY MODE"
 *   w7: TYPE_0x48  (separator/spacer)
 *   w8: MENU_ITEM  "MUSIC STYLE ARRANGER MODE"
 *   w9: MENU_ITEM  "WALLPAPER SETTING"
 */

#include "naka_types.h"

/* ── External handler addresses (resolved by linker script) ── */

extern const char Naka_PresentationRootState;  /* 0x00EF013F */

/* ── Base ROM address of this data block ─────────────────── */

#define BASE  0x00ED3C96u

/* ── Overall layout struct ───────────────────────────────── */

/* NAKA class TtlScreen -- class id 0x01600034 (Class table slot 0x160, entry 52),
 * parent Screen; allsize 42.  Field names and type characters are the
 * class chain's own propname / propdata (see THE CLASS SYSTEM in
 * scripts/analysis/nakarest_objtab_map.py). */
typedef struct __attribute__((packed)) {
    uint32_t class_;            /* +0 M */
    uint16_t super;             /* +4 [ */
    uint16_t sub;               /* +6 [ */
    uint16_t next;              /* +8 [ */
    uint16_t prev;              /* +10 [ */
    uint16_t flag;              /* +12 ] */
    int16_t rect[4];          /* +14 P */
    uint16_t color;             /* +22 ^ */
    uint16_t border;            /* +24 _ */
    uint32_t exit;              /* +26 a */
    uint32_t window;            /* +30 r */
    uint32_t title;             /* +34 X */
    uint32_t icon;              /* +38 b */
} naka_cls_TtlScreen_t;

/* NAKA class AcTitleMenu -- class id 0x0160001D (Class table slot 0x160, entry 29),
 * parent PsMenuBox; allsize 54.  Field names and type characters are the
 * class chain's own propname / propdata (see THE CLASS SYSTEM in
 * scripts/analysis/nakarest_objtab_map.py). */
typedef struct __attribute__((packed)) {
    uint32_t class_;            /* +0 M */
    uint16_t super;             /* +4 [ */
    uint16_t sub;               /* +6 [ */
    uint16_t next;              /* +8 [ */
    uint16_t prev;              /* +10 [ */
    uint16_t flag;              /* +12 ] */
    int16_t rect[4];          /* +14 P */
    uint16_t color;             /* +22 ^ */
    uint16_t border;            /* +24 _ */
    uint16_t index;             /* +26 A */
    uint32_t font;              /* +28 c */
    uint16_t fontcolor;         /* +32 ^ */
    uint16_t align;             /* +34 d */
    uint16_t editsw;            /* +36 e */
    uint32_t selected;          /* +38 m */
    uint32_t str;               /* +42 X */
    uint32_t title;             /* +46 a */
    uint32_t icon;              /* +50 b */
} naka_cls_AcTitleMenu_t;

/* NAKA class IvExitMode -- class id 0x01600048 (Class table slot 0x160, entry 72),
 * parent IvExit; allsize 26.  Field names and type characters are the
 * class chain's own propname / propdata (see THE CLASS SYSTEM in
 * scripts/analysis/nakarest_objtab_map.py). */
typedef struct __attribute__((packed)) {
    uint32_t class_;            /* +0 M */
    uint16_t super;             /* +4 [ */
    uint16_t sub;               /* +6 [ */
    uint16_t next;              /* +8 [ */
    uint16_t prev;              /* +10 [ */
    uint16_t flag;              /* +12 ] */
    int16_t rect[4];          /* +14 P */
    uint32_t mode;              /* +22 ` */
} naka_cls_IvExitMode_t;

typedef struct __attribute__((packed)) {
    /* w1: CONTAINER "CONTROL MENU" */
    /* element 0 of Viewable slot 0x40 "ControlMenu": TtlScreen (class id 0x01600034) */
    naka_cls_TtlScreen_t v40_e0;
    char w1_text[14];       /* "CONTROL MENU" + NUL + 0xFF pad */

    /* w2: MENU_ITEM "INITIAL" */
    /* element 1 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e1;
    char w2_text[8];        /* "INITIAL" + NUL */

    /* w3: MENU_ITEM "OVERALL TOUCH SENSITIVITY" */
    /* element 2 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e2;
    char w3_text[26];       /* "OVERALL TOUCH SENSITIVITY" + NUL */

    /* w4: MENU_ITEM "FOOT CONTROLLERS" */
    /* element 3 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e3;
    char w4_text[18];       /* "FOOT CONTROLLERS" + NUL + 0xFF pad */

    /* w5: MENU_ITEM "DISPLAY TIME OUT" */
    /* element 4 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e4;
    char w5_text[18];       /* "DISPLAY TIME OUT" + NUL + 0xFF pad */

    /* w6: MENU_ITEM "PANEL MEMORY MODE" */
    /* element 5 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e5;
    char w6_text[18];       /* "PANEL MEMORY MODE" + NUL */

    /* w7: TYPE_0x48 (separator/spacer) */
    /* element 6 of Viewable slot 0x40: IvExitMode (class id 0x01600048) */
    naka_cls_IvExitMode_t v40_e6;

    /* w8: MENU_ITEM "MUSIC STYLE ARRANGER MODE" */
    /* element 7 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e7;
    char w8_text[26];       /* "MUSIC STYLE ARRANGER MODE" + NUL */

    /* w9: MENU_ITEM "WALLPAPER SETTING" */
    /* element 8 of Viewable slot 0x40: AcTitleMenu (class id 0x0160001D) */
    naka_cls_AcTitleMenu_t v40_e8;
    char w9_text[18];       /* "WALLPAPER SETTING" + NUL */
} ctrl_menu_header_t;

/* Self-referential pointer: computes ROM address of a field */
#define SELF(field)  (BASE + __builtin_offsetof(ctrl_menu_header_t, field))

_Static_assert(sizeof(ctrl_menu_header_t) == 592,
    "ctrl_menu_header must be exactly 592 bytes");

/* ── Data ────────────────────────────────────────────────── */

const ctrl_menu_header_t ctrl_menu_header_data
    __attribute__((section(".text"), used)) = {

    /* ─── w1: CONTAINER "CONTROL MENU" ─────────────────── */
    .v40_e0 = {
        .class_ = 0x01600034,
        .super = NAKA_NONE,
        .sub = 1,
        .next = NAKA_NONE,
        .prev = NAKA_NONE,
        .flag = 0x000A,
        .rect = { 0, 0, 319, 239 },
        .color = 0x00F8,
        .border = 0x0002,
        .exit = 0x01A00001,
        .window = 0x0003F434,
        .title = SELF(w1_text),
        .icon = 0x00000093,
    },
    .w1_text = { 'C','O','N','T','R','O','L',' ','M','E','N','U', 0, 0xFF },

    /* ─── w2: MENU_ITEM "INITIAL" ──────────────────────── */
    .v40_e1 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 2,
        .prev = NAKA_NONE,
        .flag = 0x0008,
        .rect = { 8, 30, 156, 55 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x0088,
        .selected = 0x0003F438,
        .str = SELF(w2_text),
        .title = 0x01A00041,
        .icon = 0x0000000E,
    },
    .w2_text = "INITIAL",

    /* ─── w3: MENU_ITEM "OVERALL TOUCH SENSITIVITY" ───── */
    .v40_e2 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 3,
        .prev = 1,
        .flag = 0x0008,
        .rect = { 8, 72, 156, 97 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x0089,
        .selected = 0x0003F43A,
        .str = SELF(w3_text),
        .title = 0x01A00043,
        .icon = 0x0000000A,
    },
    .w3_text = "OVERALL TOUCH SENSITIVITY",

    /* ─── w4: MENU_ITEM "FOOT CONTROLLERS" ─────────────── */
    .v40_e3 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 4,
        .prev = 2,
        .flag = 0x0008,
        .rect = { 8, 114, 156, 139 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x008A,
        .selected = 0x0003F43C,
        .str = SELF(w4_text),
        .title = 0x01A00042,
        .icon = 0x00000081,
    },
    .w4_text = { 'F','O','O','T',' ','C','O','N','T','R','O','L','L','E','R','S', 0, 0xFF },

    /* ─── w5: MENU_ITEM "DISPLAY TIME OUT" ─────────────── */
    .v40_e4 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 5,
        .prev = 3,
        .flag = 0x0008,
        .rect = { 163, 30, 311, 55 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x0008,
        .selected = 0x0003F43E,
        .str = SELF(w5_text),
        .title = 0x01A00047,
        .icon = 0x00000094,
    },
    .w5_text = { 'D','I','S','P','L','A','Y',' ','T','I','M','E',' ','O','U','T', 0, 0xFF },

    /* ─── w6: MENU_ITEM "PANEL MEMORY MODE" ────────────── */
    .v40_e5 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 6,
        .prev = 4,
        .flag = 0x0008,
        .rect = { 163, 72, 311, 97 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x0009,
        .selected = 0x0003F440,
        .str = SELF(w6_text),
        .title = 0x01A00045,
        .icon = 0x00000031,
    },
    .w6_text = "PANEL MEMORY MODE",

    /* ─── w7: TYPE_0x48 (separator/spacer) ─────────────── */
    .v40_e6 = {
        .class_ = 0x01600048,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 7,
        .prev = 5,
        .flag = 0x0018,
        .rect = { 0, 0, 31, 31 },
        .mode = 0x01800001,
    },

    /* ─── w8: MENU_ITEM "MUSIC STYLE ARRANGER MODE" ───── */
    .v40_e7 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = 8,
        .prev = 6,
        .flag = 0x0008,
        .rect = { 163, 114, 311, 139 },
        .color = 0x00F5,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x000A,
        .selected = 0x0003F442,
        .str = SELF(w8_text),
        .title = 0x01A00044,
        .icon = 0x00000032,
    },
    .w8_text = "MUSIC STYLE ARRANGER MODE",

    /* ─── w9: MENU_ITEM "WALLPAPER SETTING" ────────────── */
    .v40_e8 = {
        .class_ = 0x0160001D,
        .super = 0,
        .sub = NAKA_NONE,
        .next = NAKA_NONE,
        .prev = 7,
        .flag = 0x0008,
        .rect = { 8, 156, 156, 181 },
        .color = 0x00F7,
        .border = 0x0000,
        .index = 0xFFFF,
        .font = 0x00000000,
        .fontcolor = 0x00FF,
        .align = 0x0000,
        .editsw = 0x008B,
        .selected = 0x0003F444,
        .str = SELF(w9_text),
        .title = 0x01A00048,
        .icon = 0x00000085,
    },
    .w9_text = "WALLPAPER SETTING",
};
