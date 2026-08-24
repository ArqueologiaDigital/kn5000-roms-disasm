/* prom_c.ld -- linker script for Technics SX-WSA1R wsa1_prom_c.ic28
 *
 * IC28, program EPROM of the SECOND processor. Load address ESTABLISHED the same way as A: 33 of 64 vectors at 0x7FF00.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF80000, LENGTH = 512K
}

SECTIONS {
  .text 0xF80000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
