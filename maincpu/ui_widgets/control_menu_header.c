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

typedef struct __attribute__((packed)) {
    /* w1: CONTAINER "CONTROL MENU" */
    naka_container_t w1;
    char w1_text[14];       /* "CONTROL MENU" + NUL + 0xFF pad */

    /* w2: MENU_ITEM "INITIAL" */
    naka_menu_item_t w2;
    char w2_text[8];        /* "INITIAL" + NUL */

    /* w3: MENU_ITEM "OVERALL TOUCH SENSITIVITY" */
    naka_menu_item_t w3;
    char w3_text[26];       /* "OVERALL TOUCH SENSITIVITY" + NUL */

    /* w4: MENU_ITEM "FOOT CONTROLLERS" */
    naka_menu_item_t w4;
    char w4_text[18];       /* "FOOT CONTROLLERS" + NUL + 0xFF pad */

    /* w5: MENU_ITEM "DISPLAY TIME OUT" */
    naka_menu_item_t w5;
    char w5_text[18];       /* "DISPLAY TIME OUT" + NUL + 0xFF pad */

    /* w6: MENU_ITEM "PANEL MEMORY MODE" */
    naka_menu_item_t w6;
    char w6_text[18];       /* "PANEL MEMORY MODE" + NUL */

    /* w7: TYPE_0x48 (separator/spacer) */
    naka_type_0x48_t w7;

    /* w8: MENU_ITEM "MUSIC STYLE ARRANGER MODE" */
    naka_menu_item_t w8;
    char w8_text[26];       /* "MUSIC STYLE ARRANGER MODE" + NUL */

    /* w9: MENU_ITEM "WALLPAPER SETTING" */
    naka_menu_item_t w9;
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
    .w1 = {
        .header       = NAKA_HDR(NAKA_TYPE_CONTAINER),
        .parent_idx   = NAKA_NONE,
        .self_idx     = 0x0001,
        .next_sibling = NAKA_NONE,
        .prev_sibling = NAKA_NONE,
        .child_count  = 10,
        .field_0e     = 0x0000,
        .field_10     = 0x0000,
        .handler      = NAKA_ADDR(Naka_PresentationRootState),
        .style        = 0x00F8,
        .field_18     = 0x0002,
        .field_1a     = 0x0001,
        .screen_id    = 0x01A0,
        .proc_addr    = 0x0003F434,
        .string_ptr   = SELF(w1_text),
        .string_id    = 0x0093,
        .reserved     = 0x0000,
    },
    .w1_text = { 'C','O','N','T','R','O','L',' ','M','E','N','U', 0, 0xFF },

    /* ─── w2: MENU_ITEM "INITIAL" ──────────────────────── */
    .w2 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0002,
        .next_sibling = NAKA_NONE,
        .x_margin     = 8,
        .y_pos        = 8,
        .sel_x1       = 0x001E,
        .sel_y1       = 0x009C,
        .sel_x2       = 0x0037,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x0088,
        .proc_addr    = 0x0003F438,
        .string_ptr   = SELF(w2_text),
        .ui_class     = 0x0041,
        .screen_id    = 0x01A0,
        .string_len   = 0x000E,
        .reserved     = 0x0000,
    },
    .w2_text = "INITIAL",

    /* ─── w3: MENU_ITEM "OVERALL TOUCH SENSITIVITY" ───── */
    .w3 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0003,
        .next_sibling = 0x0001,
        .x_margin     = 8,
        .y_pos        = 8,
        .sel_x1       = 0x0048,
        .sel_y1       = 0x009C,
        .sel_x2       = 0x0061,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x0089,
        .proc_addr    = 0x0003F43A,
        .string_ptr   = SELF(w3_text),
        .ui_class     = 0x0043,
        .screen_id    = 0x01A0,
        .string_len   = 0x000A,
        .reserved     = 0x0000,
    },
    .w3_text = "OVERALL TOUCH SENSITIVITY",

    /* ─── w4: MENU_ITEM "FOOT CONTROLLERS" ─────────────── */
    .w4 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0004,
        .next_sibling = 0x0002,
        .x_margin     = 8,
        .y_pos        = 8,
        .sel_x1       = 0x0072,
        .sel_y1       = 0x009C,
        .sel_x2       = 0x008B,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x008A,
        .proc_addr    = 0x0003F43C,
        .string_ptr   = SELF(w4_text),
        .ui_class     = 0x0042,
        .screen_id    = 0x01A0,
        .string_len   = 0x0081,
        .reserved     = 0x0000,
    },
    .w4_text = { 'F','O','O','T',' ','C','O','N','T','R','O','L','L','E','R','S', 0, 0xFF },

    /* ─── w5: MENU_ITEM "DISPLAY TIME OUT" ─────────────── */
    .w5 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0005,
        .next_sibling = 0x0003,
        .x_margin     = 8,
        .y_pos        = 0x00A3,
        .sel_x1       = 0x001E,
        .sel_y1       = 0x0137,
        .sel_x2       = 0x0037,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x0008,
        .proc_addr    = 0x0003F43E,
        .string_ptr   = SELF(w5_text),
        .ui_class     = 0x0047,
        .screen_id    = 0x01A0,
        .string_len   = 0x0094,
        .reserved     = 0x0000,
    },
    .w5_text = { 'D','I','S','P','L','A','Y',' ','T','I','M','E',' ','O','U','T', 0, 0xFF },

    /* ─── w6: MENU_ITEM "PANEL MEMORY MODE" ────────────── */
    .w6 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0006,
        .next_sibling = 0x0004,
        .x_margin     = 8,
        .y_pos        = 0x00A3,
        .sel_x1       = 0x0048,
        .sel_y1       = 0x0137,
        .sel_x2       = 0x0061,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x0009,
        .proc_addr    = 0x0003F440,
        .string_ptr   = SELF(w6_text),
        .ui_class     = 0x0045,
        .screen_id    = 0x01A0,
        .string_len   = 0x0031,
        .reserved     = 0x0000,
    },
    .w6_text = "PANEL MEMORY MODE",

    /* ─── w7: TYPE_0x48 (separator/spacer) ─────────────── */
    .w7 = {
        .header       = NAKA_HDR(0x48),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0007,
        .next_sibling = 0x0005,
        .field_0c     = 0x0018,
        .field_0e     = 0x0000,
        .field_10     = 0x0000,
        .field_12     = 0x001F,
        .field_14     = 0x001F,
        .field_16     = 0x0001,
        .field_18     = 0x0180,
    },

    /* ─── w8: MENU_ITEM "MUSIC STYLE ARRANGER MODE" ───── */
    .w8 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = 0x0008,
        .next_sibling = 0x0006,
        .x_margin     = 8,
        .y_pos        = 0x00A3,
        .sel_x1       = 0x0072,
        .sel_y1       = 0x0137,
        .sel_x2       = 0x008B,
        .sel_y2       = 0x00F5,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x000A,
        .proc_addr    = 0x0003F442,
        .string_ptr   = SELF(w8_text),
        .ui_class     = 0x0044,
        .screen_id    = 0x01A0,
        .string_len   = 0x0032,
        .reserved     = 0x0000,
    },
    .w8_text = "MUSIC STYLE ARRANGER MODE",

    /* ─── w9: MENU_ITEM "WALLPAPER SETTING" ────────────── */
    .w9 = {
        .header       = NAKA_HDR(NAKA_TYPE_MENU_ITEM),
        .parent_idx   = 0x0000,
        .prev_sibling = NAKA_NONE,
        .self_idx     = NAKA_NONE,
        .next_sibling = 0x0007,
        .x_margin     = 8,
        .y_pos        = 8,
        .sel_x1       = 0x009C,
        .sel_y1       = 0x009C,
        .sel_x2       = 0x00B5,
        .sel_y2       = 0x00F7,
        .flags        = 0x0000,
        .link_idx     = NAKA_NONE,
        .field_1c     = 0x0000,
        .field_1e     = 0x0000,
        .bg_color     = 0x00FF,
        .field_22     = 0x0000,
        .handler_id   = 0x008B,
        .proc_addr    = 0x0003F444,
        .string_ptr   = SELF(w9_text),
        .ui_class     = 0x0048,
        .screen_id    = 0x01A0,
        .string_len   = 0x0085,
        .reserved     = 0x0000,
    },
    .w9_text = "WALLPAPER SETTING",
};
