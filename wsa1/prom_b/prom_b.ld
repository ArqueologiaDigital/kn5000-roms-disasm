/* prom_b.ld -- linker script for Technics SX-WSA1R wsa1_prom_b.ic13
 *
 * IC13, the second program EPROM on CPU 1's bus.
 *
 * ==========================================================================
 * BASE 0xF00000 -- CONFIRMED.  This was "inferred" before; it is not any more.
 * ==========================================================================
 *
 * Four independent proofs, none of which survives a one-byte error in the base:
 *
 *  1. prom_a's interrupt vectors point into this image, at 4-byte-aligned
 *     `jp` thunks.  Vector 0x1C = 0x00F400A4 -> file 0x400A4 = `1b a5 e9 f8`
 *     = `jp 0xF8E9A5`; vector 0x28 = 0x00F40EDC -> file 0x40EDC =
 *     `jp 0xF8E47F`, followed by more aligned `jp`s.  (⚠ An earlier pass wrote
 *     these as file 0x000A4 / 0x00EDC.  Those offsets hold unrelated bytes.)
 *  2. prom_a's reset path jumps here.  0xF827C4 `jp 0xF42D60` -> file 0x42D60
 *     = `jp 0xF85606`, and 0xF85606 is `ld XSP,0x0060EB80` -- the first stack
 *     this machine has.
 *  3. A PC-relative call crosses the boundary: prom_a 0xF80007
 *     `calr 0xF7F245` lands on file 0x7F245, a well-formed function
 *     (`push 0x0000` / `call 0xF42E28` / `inc 2,XSP` / `call 0xF42E24` / `ret`).
 *     prom_b sits immediately below prom_a.
 *  4. The thunk the expansion-board probe needs is here: prom_a 0xF828A1
 *     `call 0xF40EF0` -> file 0x40EF0 = `jp 0xF8E0FE`, the 0xE2 remote-read
 *     entry point.
 *
 * File 0x40000-0x434F4 is a large linker thunk region: of its 3388
 * 4-byte-aligned slots, 1971 hold `1B lo mid hi` targeting 0xF00000-0xFFFFFF.
 *
 * prom_a + prom_b are ONE contiguous 1 MiB program image on CS2, which the
 * boot block programs as MSAR2 = 0xE0 / MAMR2 = 0x3F / B2CS = 0x1B.  See
 * notes/FINDINGS-memory-map.md for the whole CPU 1 map.
 *
 * NOT a boot image: only 3 of the 64 words at its own file offset 0x7FF00 look
 * like vectors, and 0x7FF00 here is not 0xFFFF00 anyway.  Its file 0x7FFF0 is
 * code -- `1d 78 2a f4 1e 8f 00` = `call 0xF42A78` / `calr 0xF80086` -- where
 * prom_a, prom_c and prom_d each carry a lowercase `wsaX_NNN` build tag.
 * prom_b has no lowercase "wsa" string at all.  (⚠ It does have 13 uppercase
 * "WSA" strings, e.g. file 0x2E13F "WSA and cannot be played", 0x48C00
 * "WSA SOUND RAM S0WSA1"; an earlier pass said it had none.)
 */

MEMORY {
  ROM (rx) : ORIGIN = 0xF00000, LENGTH = 512K
}

SECTIONS {
  .text 0xF00000 : { *(.text*) } > ROM
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
