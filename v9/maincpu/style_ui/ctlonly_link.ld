/* ctlonly_link.ld — Linker script for ctlonly.c standalone build
 *
 * Provides absolute symbol addresses for extern references in ctlonly.c.
 * These addresses correspond to labels in scoop_display.s (Scoop display handlers).
 *
 * To regenerate from the main ELF:
 *   llvm-nm rebuilt_ROMs/kn5000_v10_program.llvm.elf | grep 'Scoop_'
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Scoop Envelope Calculation handlers (inside Scoop_EnvelopeCalc_Data) */
Scoop_EnvCalc_Handler0 = 0x00F01C29;
Scoop_EnvCalc_Handler1 = 0x00F01C6C;
Scoop_EnvCalc_Handler2 = 0x00F01D09;
Scoop_EnvCalc_Handler3 = 0x00F01D38;

/* Scoop Glide Parameter handlers */
Scoop_GlideParam_Setup = 0x00F01DAB;
Scoop_GlideParam_Data  = 0x00F01E89;

/* Scoop Glide Calculation handlers (inside Scoop_GlideParam_Data) */
Scoop_GlideCalc_Handler0 = 0x00F01F26;
Scoop_GlideCalc_Handler1 = 0x00F01FB7;
Scoop_GlideCalc_Handler2 = 0x00F01FDD;

/* Scoop Dispatch handlers */
Scoop_Dispatch_Nop         = 0x00F020D6;
Scoop_Dispatch_CallFAA98A  = 0x00F020D7;
Scoop_Dispatch_CallFAB273  = 0x00F02106;
