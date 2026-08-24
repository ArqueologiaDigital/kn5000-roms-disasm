/* prom_d.ld -- linker script for Technics SX-WSA1R wsa1_prom_d.bin
 *
 * Reference designator not legible in the manual scan.  DATA ONLY -- all 64
 * words at file offset 0x7FF00 are 0xFFFFFFFF, so it is not a boot image.
 *
 * ==========================================================================
 * BASE -- NOT ESTABLISHED.  ORIGIN 0 below is a build convenience and asserts
 * nothing.  Do not change it without the missing link named at the end.
 * ==========================================================================
 *
 * The leading hypothesis, and it is now strong rather than speculative:
 * prom_d is an image of the 512 KiB FLASH at 0xE80000 on CPU 2's bus.
 *
 *   * prom_d is exactly 0x80000 bytes -- exactly the span the sector-erase
 *     routine at prom_c 0xFC8646 proves for that flash (first and last 64 KiB
 *     blocks special-cased, highest sector base 0xEFC000).
 *   * Its content ends at 0x50B08.  From 0x50B09 to 0x7FFEF it is ONE unbroken
 *     0xFF run of 0x2F4E7 bytes -- the only 0xFF run >= 0x1000 in the file --
 *     and then the build tag "wsad_54.ssf" at 0x7FFF0.  That is the shape of an
 *     erased flash device, not of a mask ROM.
 *   * Its header at 0x00-0xB0 is 44 offsets, all 0-based and all < 0x80000
 *     (the word at +0x000 is 0xFFFFFFFF, not an offset).  The largest is
 *     0x050AFA -- 14 bytes short of where the content stops.
 *   * It holds the tone/voice data: names at 0x50200+ ("Helicopter",
 *     "Telephone", "Orchestra.Hit"), 0x1A1D1 (" Dark Universe ").
 *   * It contains NO absolute code pointers.  Aligned LE32 words with top byte
 *     0x00 and value >= 0x1000 show flat bank noise (0x40:1267, 0x1E:784,
 *     0x64:722 of 20076), where prom_a's pile into 0xFA/0xFF/0xFE and prom_b's
 *     into 0xF7/0xF1/0xF0/0xFB.  A ROM meant to be executed in place looks like
 *     the latter.
 *   * CPU 1 fetches tone data out of that flash over the inter-processor link,
 *     with remote bank bases 0xE8, 0xE9, 0xEA, 0xEB and 0xEC.
 *
 * ⚠ One earlier argument does NOT work and must not be reused: those observed
 *   remote banks stop at 0xEC, i.e. offsets 0x00000-0x4FFFF, while prom_d's
 *   largest header offset 0x050AFA falls in bank 0xED.  The offset table does
 *   not match the observed bank list.  It matches the DEVICE, which is larger
 *   than the part of it prom_a happens to reference.
 *
 * WHAT IS STILL MISSING: a byte-level tie between a specific structure inside
 * prom_d and a specific instruction that reads it.  Until that exists this is
 * "strongly supported, one link short of proof", and this file keeps ORIGIN 0.
 *
 * Note also that even if the identification is right, 0xE80000 is an address in
 * CPU 2's space, not CPU 1's; nothing here should be linked against a CPU 1 map.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x000000, LENGTH = 512K
}

SECTIONS {
  .text 0x000000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
