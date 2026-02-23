/* hdae5000.ld - Linker script for HDAE5000 extension ROM (LLVM build)
 *
 * Memory map:
 *   HDAE5000 occupies 0x280000-0x2FFFFF (512KB).
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x280000, LENGTH = 512K
}

SECTIONS {
  .text 0x280000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
