/* custom_data.ld - Linker script for KN5000 Custom Data ROM (LLVM build)
 *
 * Memory map:
 *   Custom data occupies 0x300000-0x3FFFFF (1MB).
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x300000, LENGTH = 1M
}

SECTIONS {
  .text 0x300000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
