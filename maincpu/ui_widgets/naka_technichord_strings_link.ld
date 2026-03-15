/* naka_technichord_strings_link.ld — Linker script for naka_technichord_strings.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
