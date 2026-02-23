/* subcpu_boot.ld - Linker script for KN5000 Sub CPU Boot ROM (LLVM build)
 *
 * Memory map:
 *   Boot ROM occupies 0xFE0000-0xFFFFFF (128KB) in the sub CPU address space.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xFE0000, LENGTH = 128K
}

SECTIONS {
  .text 0xFE0000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
