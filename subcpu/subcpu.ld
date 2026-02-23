/* subcpu.ld - Linker script for KN5000 Sub CPU Payload ROM (LLVM build)
 *
 * Memory map:
 *   The payload occupies 0x0400-0x3EAFF (sub CPU address space).
 *   After linking, the binary is post-processed with dd to extract the
 *   two regions that form the final ROM (0x0400-0x04FF + 0xF000-0x3EAFF).
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x0400, LENGTH = 256768
}

SECTIONS {
  .text 0x0400 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
