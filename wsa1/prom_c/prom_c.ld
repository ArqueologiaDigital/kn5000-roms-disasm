/* prom_c.ld -- linker script for Technics SX-WSA1R wsa1_prom_c.ic28
 *
 * IC28, program EPROM, boot image of CPU 2 (IC2, "MICROCOMPUTER (SUB)",
 * Toshiba TMP95C061 / TLCS-900/H).
 *
 * Base 0xF80000 is ESTABLISHED the same way as prom_a: 33 of 64 words at file
 * offset 0x7FF00 are vectors, and the reset word 0x00FFF000 lands on a boot
 * block.
 *
 * CPU 2 is a SEPARATE address space from CPU 1.  The two talk over a byte port
 * with a two-wire handshake -- 0x100000 here, 0x7C0000 there.  Addresses that
 * appear inside link packets (0xC00000, 0xE8xxxx-0xECxxxx) are CPU 2's, never
 * CPU 1's.
 *
 * ==========================================================================
 * CPU 2 MEMORY MAP -- programmed by RESET at 0xFFF000, MSAR/MAMR/BnCS block at
 * 0xFFF038-0xFFF064.  Full argument in notes/FINDINGS-memory-map.md; window
 * sizes from scripts/analysis/mamr_reading_elimination.py.  Unlike CPU 1, both
 * surviving decoders give IDENTICAL windows on this CPU.
 * ==========================================================================
 *
 *   0x000000-0x00007F   internal I/O registers
 *   0x000080-0x01007F   CS3  work DRAM, cleared at boot -- LOWER BOUND
 *   0x00FFF0            CS3  initial stack pointer (0xFFF006); the main entry
 *                            at 0xF9816B moves it down to 0x00FA00
 *   0x010080-0x01FFFF   CS3  NOT ESTABLISHED
 *   0x100000            CS0  inter-processor link port (strobe PA.0, busy PA.3)
 *   0x104000 +0/+2      CS0  16-bit address/data register pair
 *   0x108000            CS0  same shape (three sites)
 *   0x10C000 +0/+2/+4   CS0  16-bit address/data device, nop-padded for bus
 *                            timing; 102 references, the busiest device here
 *   0x110000-0x13FFFF   CS0  NOT ESTABLISHED
 *   0xC00000 +0x18/+0x31 CS1 expansion board header; checked against the ASCII
 *                            signature "WSA1 EXTBD" (file 0x6129E, 0x61EC9)
 *   0xC00040-0xDFFFFF   CS1  NOT ESTABLISHED
 *   0xE00000 +0/+2      CS2  address/data register pair -- byte-identical
 *                            driver shape to CPU 1's 0x7F0000.  Whether that is
 *                            one dual-ported chip or two instances is NOT
 *                            ESTABLISHED
 *   0xE00004-0xE7FFFF   CS2  NOT ESTABLISHED
 *   0xE80000-0xEFFFFF   CS2  FLASH, 512 KiB -- size ESTABLISHED from the
 *                            sector-erase addresses at 0xFC8646ff (first and
 *                            last 64 KiB blocks are special-cased; highest
 *                            sector base 0xEFC000).  AMD/Fujitsu command set,
 *                            unlock at base+0xAAAA / base+0x5554
 *   0xF00000-0xF7FFFF   CS2  NOT ESTABLISHED
 *   0xF80000-0xFFFFFF   CS2  prom_c   (this image)
 *
 * BUS WIDTH: the flash unlock offsets 0xAAAA/0x5554 are exactly 2x the AMD
 * byte-mode 0x5555/0x2AAA, so A0 is not routed to the flash and the CPU eats it
 * as a byte-lane select.  CS2 here is 16 bits wide, and prom_c shares that
 * window -- so prom_c is a x16 device and this image is a complete contiguous
 * byte image, not an even or odd half.
 *
 * CPU 2 makes NO runtime change to the CS or DRAM controller.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF80000, LENGTH = 512K
}

SECTIONS {
  .text 0xF80000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
