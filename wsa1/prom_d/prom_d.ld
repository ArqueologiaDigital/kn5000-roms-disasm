/* prom_d.ld -- linker script for Technics SX-WSA1R wsa1_prom_d.bin
 *
 * Designator not legible in the manual scan. DATA ONLY -- 0 of 64 vector slots are plausible (all 0xFFFFFFFF). Base address UNKNOWN; ORIGIN 0 here is a build convenience and asserts nothing.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x000000, LENGTH = 512K
}

SECTIONS {
  .text 0x000000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
