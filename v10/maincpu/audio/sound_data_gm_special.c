/**
 * sound_data_gm_special.c — GM Special category config table
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
