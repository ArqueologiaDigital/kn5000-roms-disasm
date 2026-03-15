/* naka_widget_descriptors_link.ld — Linker script for naka_widget_descriptors.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
