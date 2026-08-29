/* prom_d.ld -- linker script for Technics SX-WSA1R wsa1_prom_d.bin
 *
 * Reference designator not legible in the manual scan.  DATA ONLY -- 60 of the
 * 64 words at file offset 0x7FF00 are 0xFFFFFFFF and the other four are the
 * build tag, so it is not a boot image.
 *
 * ==========================================================================
 * ORIGIN STAYS 0, AND THAT IS NOW A DECISION RATHER THAN AN ADMISSION.
 * ==========================================================================
 *
 * ⚠ REWRITTEN IN WAVE 7 ROUND 3.  This file used to open "BASE -- NOT
 * ESTABLISHED", name the 512 KiB flash at 0xE80000 as "the leading hypothesis,
 * now strong rather than speculative", and end with
 *
 *     "WHAT IS STILL MISSING: a byte-level tie between a specific structure
 *      inside prom_d and a specific instruction that reads it."
 *
 * Both of those statements are superseded.  The flash reading was REFUTED in
 * round 1 and the tie was FOUND in round 3, and this file was the last place in
 * the tree still carrying the old text.
 *
 * WHERE THIS IMAGE IS ADDRESSED: 0x00F00000, on CPU 2's bus.
 *
 *   * prom_c's ExtBoard_ProbeAndInstallBases loads 0x00F00000 at 0xFB051E and
 *     stores it to RAM 0x00D7ED (0xFB0523) and 0x00D7F1 (0xFB0528).  Those two
 *     stores are the ONLY instructions in prom_c that write either address, so
 *     the base is a compile-time constant wherever it is used.
 *   * prom_c reads THIS IMAGE'S 48-slot directory through that base at 99
 *     instruction pairs covering 33 slots, and adds the base to the 0-based
 *     offsets it finds there -- twice over, in the tone lookup at 0xFB429D /
 *     0xFB429F.  notes/prom_d_documentation_round3.py, 62 checks; every one of
 *     the 99 citations is re-decoded from prom_c's ROM bytes.
 *   * independently, prom_a 0xF82A5F `ld XWA,0x00F7FFF0` reads eleven bytes
 *     that are this image's build tag at file 0x7FFF0, "wsad_54.ssf".
 *     0x00F7FFF0 - 0x7FFF0 = 0x00F00000.  Two processors, two routes, one base.
 *   * the 0xE80000 part is a DIFFERENT, SMALLER device: prom_c's own
 *     Flash_SectorErase holds base 0x00E80000 and its top-boot sub-sector map
 *     ends at 0x00EFFFFF, below this image; and the same routine that installs
 *     0x00F00000 installs 0x00E80000 into a separate slot (0x00D7F5).
 *     notes/prom_d_base_checks.py, 12 checks.
 *
 * WHY ORIGIN IS STILL 0.  Because the hardware does not address this image
 * absolutely and neither should the source.  Its directory holds 0-based FILE
 * OFFSETS, and what proves that is not a statistic but an instruction sequence:
 * prom_c reads a tone-record entry out of the table at slot +0x08 (0xFB429D) and
 * then ADDS THE BASE TO IT (0xFB429F), having already added the base to reach
 * the table itself (0xFB4298).  A stored absolute address needs neither add.
 * Linking at 0xF00000 would relabel every offset in a 32,000-line source with an
 * address the image itself never uses, and would gain nothing.
 *
 * ⚠ CORRECTED IN ROUND 3.  This paragraph used to lean on a second argument --
 * "it contains NO absolute pointers at all: aligned LE32 words with top byte
 * 0x00 and value >= 0x1000 show flat bank noise (0x40:1267, 0x1E:784, 0x64:722
 * of 20076), where prom_a's pile into 0xFA/0xFF/0xFE and prom_b's into
 * 0xF7/0xF1/0xF0/0xFB.  A ROM meant to be executed in place looks like the
 * latter."  Those counts reproduce exactly (round 3 Q8, which is the first
 * committed script to check them) and the prom_a / prom_b halves hold, but the
 * profile DOES NOT DISCRIMINATE and the sentence claimed more than it showed:
 * measured as the share of such words landing in the image's own bank window it
 * is prom_a 20.4%, prom_b 18.6%, prom_c 3.4%, prom_d 1.5% -- and prom_c is a
 * code ROM.  The quoted top banks also omit 0x00, which is the commonest bank in
 * every one of the four images.  The observation is kept as support; it is no
 * longer offered as proof, and the ORIGIN-0 decision does not rest on it.
 *
 * ⚠ WHAT IS STILL OPEN: which PHYSICAL PART this is.  The evidence above fixes
 * the ADDRESS the firmware reads it at, not the device; the erased tail
 * (0x50B09..0x7FFEF is one unbroken 0xFF run of 0x2F4E7 bytes, the only 0xFF run
 * >= 0x1000 in the file) is the shape of a flash device rather than a mask ROM,
 * and that is as far as the bytes go.  Also note that 0x00F00000 is an address
 * in CPU 2's space; it COLLIDES with prom_b's 0xF00000 on CPU 1's, and nothing
 * here should be linked against a CPU 1 map.
 */

MEMORY {
  ROM (rx) : ORIGIN = 0x000000, LENGTH = 512K
}

SECTIONS {
  .text 0x000000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
