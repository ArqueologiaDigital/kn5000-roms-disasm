/* table_data.ld - Linker script for KN5000 Table Data ROM (LLVM build)
 *
 * Memory map:
 *   Table data occupies 0x800000-0x9FFFFF (2MB).
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x800000, LENGTH = 2M
}

SECTIONS {
  .text 0x800000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
