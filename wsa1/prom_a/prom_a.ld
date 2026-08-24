/* prom_a.ld -- linker script for Technics SX-WSA1R wsa1_prom_a.ic12
 *
 * IC12, program EPROM. Load address ESTABLISHED: 33 of 64 interrupt vectors at file offset 0x7FF00 point into 0xF00000-0xFFFFFF, which places 0xFFFF00 there, i.e. base 0xF80000.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF80000, LENGTH = 512K
}

SECTIONS {
  .text 0xF80000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
