/* naka_widget_names_charmap_link.ld — Linker script for naka_widget_names_charmap.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
