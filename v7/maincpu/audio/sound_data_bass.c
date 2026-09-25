/**
 * sound_data_bass.c — Bass category configuration byte table
 *
 * CORRECTED 2026-09-25 -- read this first.  Descriptor slot +0x3C: for
 * ordinary parts in mode 0, the LAST SLOT INDEX of each category (value + 1
 * sounds), 0xFF = category not offered.  Reader
 * CharMap_ActivePreamb_Prologue (v10/v9 0xFEE43F); GetSoundBankCount and
 * Sound_Navigate step categories by value + 1 and skip 0xFF.  The 18 values
 * sum to 368 sounds, the populated-cell count of sound_data_guitar.c.  The
 * "sub-bank count or configuration flags" and "use all" readings below are
 * false.
 * Evidence for everything in this block: audio/sound_data.s (reader
 * addresses for v10/v9/v7) and scripts/analysis/sound_data_map_proof.py.
 * The category word in this FILE NAME comes from pairing descriptor slot k
 * with category name k; no reader indexes these tables by category.
 *
 * 18 bytes: one uint8_t per sound category (matching SOUND_CATEGORY_NAMES).
 * Likely a per-category parameter (sub-bank count or configuration flags).
 * Value 0xFF indicates "use all" or "not applicable".
 */

#include <stdint.h>

#define NUM_CATEGORIES 18

_Static_assert(sizeof(uint8_t[NUM_CATEGORIES]) == 18,
    "bass_config must be exactly 18 bytes");

const uint8_t bass_category_config[NUM_CATEGORIES]
    __attribute__((section(".text"), used)) = {
    /* Piano          */ 0x13,
    /* Guitar         */ 0x13,
    /* Strings&Vocal  */ 0x1D,
    /* Brass          */ 0x13,
    /* Flute          */ 0x13,
    /* Sax&Reed       */ 0x13,
    /* Mallet&OrchPrc */ 0x13,
    /* World Perc     */ 0x13,
    /* Organ&Accord   */ 0x13,
    /* Orchestral Pad */ 0x13,
    /* Synth          */ 0x27,
    /* Bass           */ 0x13,
    /* Digital Drawbar*/ 0x01,
    /* Accordion Reg  */ 0x13,
    /* GM Special     */ 0x13,
    /* Drum Kits      */ 0x0F,
    /* Memory A       */ 0x13,
    /* Memory B       */ 0x13,
};
