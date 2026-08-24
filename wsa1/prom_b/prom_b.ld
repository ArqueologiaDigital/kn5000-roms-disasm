/* prom_b.ld -- linker script for Technics SX-WSA1R wsa1_prom_b.ic13
 *
 * IC13, second EPROM on the same bus as A. Base 0xF00000 is INFERRED from A sitting at 0xF80000 and the pair filling a 1 MiB window; only 3 of 64 words at its 0x7FF00 look like vectors, so it is not a boot image.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF00000, LENGTH = 512K
}

SECTIONS {
  .text 0xF00000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
