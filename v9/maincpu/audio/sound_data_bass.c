/**
 * sound_data_bass.c — Bass category configuration byte table
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
