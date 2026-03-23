/* maincpu.ld - Linker script for KN5000 Main CPU Program ROM (LLVM build)
 *
 * Memory map:
 *   ROM: 0xE00000-0xFFFFFF (2MB program flash)
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xE00000, LENGTH = 2M
}

SECTIONS {
  .text 0xE00000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
