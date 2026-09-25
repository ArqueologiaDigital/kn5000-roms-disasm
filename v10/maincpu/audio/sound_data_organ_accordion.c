/**
 * sound_data_organ_accordion.c — Organ & Accordion Drawbar Registration Data
 *
 * CORRECTED 2026-09-25 -- read this first.  Descriptor slot +0x30.  The
 * readers index it by VOICE INDEX (0..127), two bytes per entry:
 * SndParam_LookupOscEnvelope (v10/v9 0xFEE8F1) when record+5 == 15 or
 * SndParam_LookupViaEncode(record+5, 0) >= 0xF0, and
 * SndParam_LookupAndDispatch (0xFEEA24) when its bank argument is 0x78.
 * So it is 128 x {byte, byte}, every entry (0xF0-0xF3/0xF5/0xF7/0xFC/0xFD, 0).
 * The "16 registration sets x 8 drawbar levels", the drawbar footages and the
 * pipe/jazz organ presets below have no reader behind them and are false.
 * Evidence for everything in this block: audio/sound_data.s (reader
 * addresses for v10/v9/v7) and scripts/analysis/sound_data_map_proof.py.
 * The category word in this FILE NAME comes from pairing descriptor slot k
 * with category name k; no reader indexes these tables by category.
 *
 * 256 bytes: 16 registration sets x 8 drawbar levels (uint16_t each).
 * Used by organ/accordion voice configuration to set drawbar footages.
 *
 * Each drawbar level is stored as uint16_t LE where only the low byte
 * carries the registration value (high byte is always 0x00).
 *
 * Rows 0-7: Eight distinct registration presets (pipe organ, jazz organ, etc.)
 * Rows 8-15: All set to 0xF0 (default/unused registration slots)
 */

#include <stdint.h>

#define NUM_REGISTRATIONS 16
#define NUM_DRAWBARS       8

typedef struct __attribute__((packed)) {
    uint16_t regs[NUM_REGISTRATIONS][NUM_DRAWBARS];
} organ_accordion_data_t;

_Static_assert(sizeof(organ_accordion_data_t) == 256,
    "organ_accordion_data must be exactly 256 bytes");

const organ_accordion_data_t organ_accordion_data
    __attribute__((section(".text"), used)) = {
    .regs = {
        /* Registration 0 */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 1 */  { 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3 },
        /* Registration 2 */  { 0xF7, 0xF7, 0xF7, 0xF7, 0xF7, 0xF7, 0xF7, 0xF7 },
        /* Registration 3 */  { 0xF2, 0xF0, 0xF2, 0xF2, 0xF2, 0xF2, 0xF2, 0xF2 },
        /* Registration 4 */  { 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1 },
        /* Registration 5 */  { 0xF5, 0xF5, 0xF5, 0xF5, 0xF5, 0xF5, 0xF5, 0xF5 },
        /* Registration 6 */  { 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC },
        /* Registration 7 */  { 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD },
        /* Registration 8  (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 9  (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 10 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 11 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 12 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 13 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 14 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
        /* Registration 15 (default) */  { 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0 },
    },
};
