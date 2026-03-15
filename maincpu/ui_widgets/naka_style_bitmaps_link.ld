/* naka_style_bitmaps_link.ld — Linker script for naka_style_bitmaps.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
