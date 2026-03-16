/**
 * voice_factory_presets.c — Voice factory preset data
 *
 * Base ROM address: 0xF6F42F
 * Total size: 480 bytes (12 active presets + 18 empty slots)
 *
 * 30 records x 16 bytes each. Each record defines a voice preset:
 *   type       (uint8)  — 0x11 = standard, 0x01 = alternate, 0x00 = empty
 *   reserved   (2 bytes)
 *   slot_index (uint8)  — voice slot number
 *   reserved   (5 bytes)
 *   param_1    (uint8)  — primary voice parameter
 *   param_2    (uint8)  — secondary voice parameter
 *   max_value  (uint8)  — always 0x7F (127)
 *   base_value (uint8)  — always 0x40 (64)
 *   flags      (uint8)  — 0x00 or 0x01
 *   reserved   (2 bytes)
 */

#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint8_t  type;
    uint8_t  _reserved_01;
    uint8_t  _reserved_02;
    uint8_t  slot_index;
    uint8_t  _reserved_04;
    uint8_t  _reserved_05;
    uint8_t  _reserved_06;
    uint8_t  _reserved_07;
    uint8_t  _reserved_08;
    uint8_t  param_1;
    uint8_t  param_2;
    uint8_t  max_value;
    uint8_t  base_value;
    uint8_t  flags;
    uint8_t  _reserved_0e;
    uint8_t  _reserved_0f;
} voice_preset_t;

_Static_assert(sizeof(voice_preset_t) == 16, "voice_preset_t must be 16 bytes");

#define PRESET(typ, idx, p1, p2, fl) \
    { .type = (typ), .slot_index = (idx), \
      .param_1 = (p1), .param_2 = (p2), \
      .max_value = 0x7F, .base_value = 0x40, .flags = (fl) }

#define EMPTY { 0 }

typedef struct __attribute__((packed)) {
    voice_preset_t presets[30];
} voice_factory_presets_t;

_Static_assert(sizeof(voice_factory_presets_t) == 480,
    "voice_factory_presets must be exactly 480 bytes");

const voice_factory_presets_t voice_factory_presets_data
    __attribute__((section(".text"), used)) = {
    .presets = {
        /*  0 */ PRESET(0x11, 0x00, 0x1A, 0x00, 0x01),
        /*  1 */ PRESET(0x11, 0x01, 0x16, 0x00, 0x00),
        /*  2 */ PRESET(0x01, 0x02, 0x63, 0x00, 0x01),
        /*  3 */ PRESET(0x11, 0x03, 0x52, 0x02, 0x01),
        /*  4 */ PRESET(0x11, 0x05, 0xF0, 0x00, 0x00),
        /*  5 */ PRESET(0x11, 0x06, 0xFC, 0x00, 0x00),
        /*  6 */ PRESET(0x01, 0x0F, 0xF0, 0x00, 0x00),
        /*  7 */ PRESET(0x01, 0x10, 0xF0, 0x00, 0x00),
        /*  8 */ PRESET(0x01, 0x11, 0xF0, 0x00, 0x00),
        /*  9 */ PRESET(0x01, 0x12, 0xF0, 0x00, 0x00),
        /* 10 */ PRESET(0x01, 0x13, 0xF0, 0x00, 0x00),
        /* 11 */ PRESET(0x01, 0x14, 0xFC, 0x00, 0x00),
        /* 12-29: empty slots */
        EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
        EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
        EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
    },
};
