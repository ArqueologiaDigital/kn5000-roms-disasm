/* naka_widget_tables_2_link.ld — Linker script for naka_widget_tables_2.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
