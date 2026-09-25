/**
 * sound_data_digital_drawbar.c — Digital Drawbar category config table
 *
 * CORRECTED 2026-09-25 -- read this first.  Descriptor slot +0x40: the
 * mode-0 per-category LAST SLOT INDEX table for PART 15 (reader
 * CharMap_ActivePreamb_Prologue, v10/v9 0xFEE43F; see sound_data_bass.c).
 * Only category 15 (drum kits) is offered, with 16 kits; 0xFF = not offered.
 * Evidence for everything in this block: audio/sound_data.s (reader
 * addresses for v10/v9/v7) and scripts/analysis/sound_data_map_proof.py.
 * The category word in this FILE NAME comes from pairing descriptor slot k
 * with category name k; no reader indexes these tables by category.
 *
 * 18 bytes: one uint8_t per sound category (matching SOUND_CATEGORY_NAMES).
 * Identical to accordion_reg: all 0xFF except Drum Kits = 0x0F.
 */

#include <stdint.h>

#define NUM_CATEGORIES 18

_Static_assert(sizeof(uint8_t[NUM_CATEGORIES]) == 18,
    "digital_drawbar_config must be exactly 18 bytes");

const uint8_t digital_drawbar_category_config[NUM_CATEGORIES]
    __attribute__((section(".text"), used)) = {
    /* Piano          */ 0xFF,
    /* Guitar         */ 0xFF,
    /* Strings&Vocal  */ 0xFF,
    /* Brass          */ 0xFF,
    /* Flute          */ 0xFF,
    /* Sax&Reed       */ 0xFF,
    /* Mallet&OrchPrc */ 0xFF,
    /* World Perc     */ 0xFF,
    /* Organ&Accord   */ 0xFF,
    /* Orchestral Pad */ 0xFF,
    /* Synth          */ 0xFF,
    /* Bass           */ 0xFF,
    /* Digital Drawbar*/ 0xFF,
    /* Accordion Reg  */ 0xFF,
    /* GM Special     */ 0xFF,
    /* Drum Kits      */ 0x0F,
    /* Memory A       */ 0xFF,
    /* Memory B       */ 0xFF,
};
