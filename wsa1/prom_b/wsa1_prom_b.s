	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_b.ic13
; Target CPU: Toshiba TMP95C061 (TLCS-900/H), "CPU 1" / IC1
; ==============================================================================
;
; IC13, the second program EPROM on CPU 1's bus, base 0xF00000.
;
; ⚠ The base is now CONFIRMED, not inferred.  Four independent proofs are
; written out in prom_b/prom_b.ld; the short form is that prom_a's interrupt
; vectors, its reset path, a PC-relative call across the boundary and the
; expansion-board probe's thunk all land on well-formed code in this image at
; exactly this base, and none of them survives a one-byte error in it.
;
; prom_a + prom_b are ONE contiguous 1 MiB image on CS2.  This half is not a
; boot image: its own file 0x7FF00 holds only 3 vector-shaped words, and its
; 0x7FFF0 -- where the other three images carry a lowercase `wsaX_NNN` build
; tag -- is code.
;
; File 0x40000-0x434F4 is a large linker thunk region: 1971 of its 3388
; 4-byte-aligned slots hold `jp` into 0xF00000-0xFFFFFF.  Converting it is the
; obvious next slice of territory, since every entry is self-checking against
; the routine it names.
;
; STATUS: not yet converted.  The whole image is one .incbin, so it builds
; byte-exact by construction and asserts nothing about its contents.  The gate
; (scripts/analysis/assert_byte_identical.py) must print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

wsa1_prom_b:
	.incbin "original_ROMs/wsa1_prom_b.ic13"
end:
