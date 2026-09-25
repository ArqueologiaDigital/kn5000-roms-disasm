/**
 * sound_data_gm_special.c — GM Special category config table
 *
 * CORRECTED 2026-09-25 -- read this first.  Descriptor slot +0x48: the
 * MODE-1 per-category LAST SLOT INDEX table for ordinary parts (reader
 * CharMap_ActivePreamb_Prologue, v10/v9 0xFEE43F; see sound_data_bass.c).
 * 12 categories are offered and the values sum to 128 sounds; 0xFF = not
 * offered, not "use all" (false).
 * Evidence for everything in this block: audio/sound_data.s (reader
 * addresses for v10/v9/v7) and scripts/analysis/sound_data_map_proof.py.
 * The category word in this FILE NAME comes from pairing descriptor slot k
 * with category name k; no reader indexes these tables by category.
 *
 * 18 bytes: one uint8_t per sound category (matching SOUND_CATEGORY_NAMES).
 * Varies per category. Value 0xFF indicates "use all" or "not applicable".
 */

#include <stdint.h>

#define NUM_CATEGORIES 18

_Static_assert(sizeof(uint8_t[NUM_CATEGORIES]) == 18,
    "gm_special_config must be exactly 18 bytes");

const uint8_t gm_special_category_config[NUM_CATEGORIES]
    __attribute__((section(".text"), used)) = {
    /* Piano          */ 0x07,
    /* Guitar         */ 0x07,
    /* Strings&Vocal  */ 0x0E,
    /* Brass          */ 0x07,
    /* Flute          */ 0x08,
    /* Sax&Reed       */ 0x08,
    /* Mallet&OrchPrc */ 0x09,
    /* World Perc     */ 0x06,
    /* Organ&Accord   */ 0x06,
    /* Orchestral Pad */ 0xFF,
    /* Synth          */ 0x15,
    /* Bass           */ 0x07,
    /* Digital Drawbar*/ 0xFF,
    /* Accordion Reg  */ 0xFF,
    /* GM Special     */ 0x10,
    /* Drum Kits      */ 0xFF,
    /* Memory A       */ 0xFF,
    /* Memory B       */ 0xFF,
};
