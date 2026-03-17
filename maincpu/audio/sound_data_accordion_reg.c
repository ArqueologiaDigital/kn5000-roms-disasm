/**
 * sound_data_accordion_reg.c — Accordion Registration category config table
 *
 * 18 bytes: one uint8_t per sound category (matching SOUND_CATEGORY_NAMES).
 * Value 0xFF indicates "use all" or "not applicable".
 * Only Drum Kits (index 15) has a distinct value of 0x0F.
 */

#include <stdint.h>

#define NUM_CATEGORIES 18

_Static_assert(sizeof(uint8_t[NUM_CATEGORIES]) == 18,
    "accordion_reg_config must be exactly 18 bytes");

const uint8_t accordion_reg_category_config[NUM_CATEGORIES]
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
