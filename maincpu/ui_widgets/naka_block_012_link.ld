/* naka_block_012_link.ld — Linker script for naka_block_012.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
