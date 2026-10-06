/**
 * sound_config_lookup.c -- NakaInst_SoundConfig_LookupTable
 *
 * Sound configuration lookup table for the NAKA widget dispatch system.
 * Structure: 138-byte header + 25 x 234-byte channel config records
 * + 148-byte trailer.
 *
 * Each 234-byte record contains MIDI parameter address tables and
 * default values for a sound channel/part configuration.
 *
 * Total size: 6136 bytes
 */

#include <stdint.h>

#define SOUND_CONFIG_HEADER_SIZE  138
#define SOUND_CONFIG_RECORD_SIZE  234
#define SOUND_CONFIG_RECORD_COUNT  25
#define SOUND_CONFIG_TRAILER_SIZE  148

/* 234-byte channel configuration record */
/* Sound-parameter bank entries (6 bytes; a bank is 23 base + 16 masked entries = 234 bytes, address 0 =
 * unused).  The same types are defined in sound_config_lookup.c (the 25 ROM presets) and
 * naka_extension_device.c (the three flash defaults); scripts/converters/sndparam_bank_retype.py. */
typedef struct __attribute__((packed)) {
    uint32_t address;    /* a part record's payload byte 12 in live-panel RAM */
    uint8_t  low_bits;   /* SndParam_ApplyBaseBlock: address[0] = (address[0] & 0xF8) | low_bits */
    uint8_t  next_byte;  /*                          address[1] = next_byte (payload byte 13) */
} snd_param_base_entry_t;

typedef struct __attribute__((packed)) {
    uint32_t address;    /* a live-panel RAM byte */
    uint8_t  mask;       /* SndParam_ApplyMaskBlock: *address = (*address & ~mask) | value */
    uint8_t  value;
} snd_param_mask_entry_t;

/* One bank: SndParam_ApplyBaseBlock walks .base, SndParam_ApplyMaskBlock .masked. */
typedef struct __attribute__((packed)) {
    snd_param_base_entry_t base[23];
    snd_param_mask_entry_t masked[16];
} snd_param_bank_t;

typedef struct __attribute__((packed)) {
    uint8_t header[SOUND_CONFIG_HEADER_SIZE];
    snd_param_bank_t SndParam_PresetBanks[SOUND_CONFIG_RECORD_COUNT];  /* blocks 0..24 of SndParam_GetBlockPointer */
    uint8_t trailer[SOUND_CONFIG_TRAILER_SIZE];
} sound_config_lookup_t;

_Static_assert(sizeof(sound_config_lookup_t) == 6136,
    "sound_config_lookup must be exactly 6136 bytes");

const sound_config_lookup_t sound_config_lookup_data
    __attribute__((section(".text"), used)) = {

    /* Header: 4 pointers + channel mapping tables */
    .header = {
        0x1B, 0xF1, 0xFC, 0x00, 0x3A, 0xF1, 0xFC, 0x00,
        0x3B, 0xF1, 0xFC, 0x00, 0x3C, 0xF1, 0xFC, 0x00,
        0x17, 0x14, 0x13, 0x10, 0x11, 0x12, 0x00, 0x01,
        0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
        0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x15, 0x16,
        0x00, 0x01, 0x20, 0x21, 0x23, 0x09, 0x0A, 0x04,
        0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x11, 0x11, 0x14, 0x15, 0x15, 0x15, 0x0A, 0x0A,
        0x0A, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x0F, 0x1E, 0x2D, 0x37, 0x46, 0x4E, 0x55, 0x5A,
        0x5C, 0x5E, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46,
        0x00, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6,
        0xC7, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6,
        0xC7, 0xB3, 0x88, 0x92, 0x93, 0x94, 0x40, 0x96,
        0x99, 0xA1, 0xA2, 0xA3, 0xB0, 0xAD, 0xA9, 0xAA,
        0xAC, 0xAE, 0xAF, 0x01, 0x41, 0x42, 0xC0, 0xC1,
        0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0x9D, 0x97,
        0x98, 0xA8
    },

    .SndParam_PresetBanks = {
        /* Record 0 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x0F },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x09 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x03 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x1C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x41 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x01 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 1 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x0F },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x09 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x03 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x1C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x81 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 2 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x81 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 3 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x01 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x81 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 4 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0E },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0F },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x01 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x00 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 5 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0E },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0F },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x01 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x00 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 6 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x00 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 7 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 7, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x00 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 8 */
        {
            .base = {
                { 0xF9C2, 0, 0xC0 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x00 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x01 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 9 */
        {
            .base = {
                { 0xF9C2, 0, 0x20 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x21 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x22 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x23 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x24 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x25 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x26 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x27 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x28 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x29 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x2A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x2B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x2C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x2D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x2E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x2F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xE0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xE0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xE0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xE0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xE0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xE0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xE0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x05 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x08 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x01 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 10 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0xC0 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0xC0 },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0xC0 },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0x0C },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0x0D },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0x0E },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0x0F },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x09 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x43 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x1C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0xC1 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 11 */
        {
            .base = {
                { 0xF9C2, 0, 0xC0 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x00 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0xC1 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 12 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0xC0 },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0xC0 },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0xC0 },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0x0B },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0x0C },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0x0D },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0x0E },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0F },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x41 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0xC5 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 13 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0F },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0E },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x05 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 14 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0xC0 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0F },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0E },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x05 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 15 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0F },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0E },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x05 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 16 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 17 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0xC0 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 18 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x01 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 7, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 1, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 19 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x03 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0xC0 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 7, 0x02 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 1, 0x01 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x44 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x02 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0xFD02, 0x03, 0x00 },  /* tag 0x70 payload byte 0 */
                { 0xFD03, 0x7F, 0x24 },  /* tag 0x70 payload byte 1 */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 20 */
        {
            .base = {
                { 0xF9C2, 0, 0xC0 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 1, 0x20 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x45 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 21 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0xC0 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0F },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x0E },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x05 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x0C },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x08 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x45 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 22 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0xC0 },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0xC0 },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0xC0 },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0x0E },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0x0D },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0x0C },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x01 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x85 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x61 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 23 */
        {
            .base = {
                { 0xF9C2, 0, 0x00 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x03 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x09 },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x0F },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x01 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x0C },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0x41 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xFE },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x01 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
        /* Record 24 */
        {
            .base = {
                { 0xF9C2, 0, 0xC0 },  /* tag 0x00 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9DC, 0, 0x01 },  /* tag 0x01 payload byte 12 (low 3 bits) and the next byte */
                { 0xF9F6, 0, 0x02 },  /* tag 0x02 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA10, 0, 0x00 },  /* tag 0x03 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA2A, 0, 0x04 },  /* tag 0x04 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA44, 0, 0x05 },  /* tag 0x05 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA5E, 0, 0x06 },  /* tag 0x06 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA78, 0, 0x07 },  /* tag 0x07 payload byte 12 (low 3 bits) and the next byte */
                { 0xFA92, 0, 0x08 },  /* tag 0x08 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAAC, 0, 0x0F },  /* tag 0x09 payload byte 12 (low 3 bits) and the next byte */
                { 0xFAC6, 0, 0x0A },  /* tag 0x0A payload byte 12 (low 3 bits) and the next byte */
                { 0xFAE0, 0, 0x0B },  /* tag 0x0B payload byte 12 (low 3 bits) and the next byte */
                { 0xFAFA, 0, 0x0C },  /* tag 0x0C payload byte 12 (low 3 bits) and the next byte */
                { 0xFB14, 0, 0x0D },  /* tag 0x0D payload byte 12 (low 3 bits) and the next byte */
                { 0xFB2E, 0, 0x0E },  /* tag 0x0E payload byte 12 (low 3 bits) and the next byte */
                { 0xFB48, 0, 0x09 },  /* tag 0x0F payload byte 12 (low 3 bits) and the next byte */
                { 0xFC18, 0, 0xC0 },  /* tag 0x19 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB62, 0, 0xC0 },  /* tag 0x10 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB7C, 0, 0xC0 },  /* tag 0x11 payload byte 12 (low 3 bits) and the next byte */
                { 0xFB96, 0, 0xC0 },  /* tag 0x12 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBB0, 0, 0xC0 },  /* tag 0x13 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBCA, 0, 0xC0 },  /* tag 0x14 payload byte 12 (low 3 bits) and the next byte */
                { 0xFBE4, 0, 0xC0 },  /* tag 0x15 payload byte 12 (low 3 bits) and the next byte */
            },
            .masked = {
                { 0xFD50, 0x7F, 0x00 },  /* tag 0x80 payload byte 0 */
                { 0xFD51, 0x0C, 0x04 },  /* tag 0x80 payload byte 1 */
                { 0xFD52, 0x1C, 0x04 },  /* tag 0x80 payload byte 2 */
                { 0xFD53, 0xC5, 0xC1 },  /* tag 0x80 payload byte 3 */
                { 0xFD54, 0xFF, 0x00 },  /* tag 0x80 payload byte 4 */
                { 0xFD55, 0x3F, 0x06 },  /* tag 0x80 payload byte 5 */
                { 0xFD56, 0xFE, 0xF6 },  /* tag 0x80 payload byte 6 */
                { 0xFD57, 0xFF, 0xFF },  /* tag 0x80 payload byte 7 */
                { 0xFD58, 0xBF, 0xBF },  /* tag 0x80 payload byte 8 */
                { 0xFD59, 0x61, 0x41 },  /* tag 0x80 payload byte 9 */
                { 0xFD5A, 0x03, 0x00 },  /* tag 0x80 payload byte 10 */
                { 0xFD5B, 0xFF, 0x00 },  /* tag 0x80 payload byte 11 */
                { 0xFD5C, 0xFF, 0x50 },  /* tag 0x80 payload byte 12 */
                { 0x0000, 0x03, 0x02 },  /* unused */
                { 0x0000, 0x7F, 0x3C },  /* unused */
                { 0x0000, 0x00, 0x00 },  /* unused */
            },
        },
    },

    /* Trailer: additional config data */
    .trailer = {
        0xF0, 0x00, 0x00, 0x10, 0x00, 0x35, 0x60, 0x0F,
        0x00, 0x00, 0x00, 0x00, 0x00, 0xF7, 0xB0, 0x10,
        0x00, 0xFF, 0xC0, 0x00, 0xF0, 0x00, 0x00, 0x10,
        0x00, 0x35, 0x60, 0x0F, 0x00, 0x00, 0x00, 0x00,
        0x00, 0xF7, 0xB3, 0x00, 0x26, 0x00, 0xC0, 0x07,
        0xFF, 0xFF, 0xB3, 0x00, 0x26, 0x00, 0x00, 0x79,
        0xBC, 0xBC, 0x77, 0x00, 0x0F, 0x00, 0xC0, 0x07,
        0xFF, 0xFF, 0x77, 0x00, 0x0F, 0x00, 0x00, 0x79,
        0xFF, 0xFF, 0x77, 0x00, 0x0F, 0x00, 0xC0, 0x07,
        0xFF, 0xFF, 0x77, 0x04, 0x0F, 0x00, 0x00, 0x79,
        0xFF, 0xFF, 0x00, 0x00, 0x03, 0x00, 0x07, 0x00,
        0x0B, 0x00, 0x0F, 0x00, 0x13, 0x00, 0x17, 0x00,
        0x1B, 0x00, 0x1F, 0x00, 0x26, 0x00, 0x2D, 0x00,
        0x34, 0x00, 0x3B, 0x00, 0x42, 0x00, 0x49, 0x00,
        0x50, 0x00, 0x00, 0x00, 0x04, 0x00, 0x08, 0x00,
        0x0C, 0x00, 0x10, 0x00, 0x14, 0x00, 0x18, 0x00,
        0x1C, 0x00, 0x20, 0x00, 0x27, 0x00, 0x2E, 0x00,
        0x35, 0x00, 0x3C, 0x00, 0x43, 0x00, 0x4A, 0x00,
        0x51, 0x00, 0x00, 0xF7
    }

};

