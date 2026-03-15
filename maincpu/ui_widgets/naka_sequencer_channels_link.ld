/* naka_sequencer_channels_link.ld — Linker script for naka_sequencer_channels.c
 * Auto-generated
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
