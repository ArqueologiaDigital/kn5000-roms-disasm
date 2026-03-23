/* accomp_screens_link.ld — Shared linker script for Accompaniment screen data files
 *
 * Provides absolute symbol addresses for extern references in accomp screen C files.
 * These addresses point to data tables in accompaniment_engine.s.
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Accompaniment display string name tables */
Accomp_SectionParam_Names  = 0x00F6ACA0;  /* "CONTROL PITCH BEND =..." */
Accomp_PartOnOff_Names     = 0x00F6AD27;  /* "OFF ON" */
Accomp_Articulation_Names  = 0x00F6AE4C;  /* "TENUNORMSTACCUTTACCOMP 1..." */
