/* naka_sequencer_exit_link.ld — Linker script for naka_sequencer_exit.c
 * Auto-generated
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
