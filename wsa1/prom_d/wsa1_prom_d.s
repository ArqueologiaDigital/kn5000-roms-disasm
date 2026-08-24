	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_d.bin
; ==============================================================================
;
; Reference designator not legible in the manual scan.  DATA ONLY -- all 64
; words at file offset 0x7FF00 are 0xFFFFFFFF, so it is not a boot image, and no
; CPU is named above because nothing here executes.
;
; BASE: **NOT ESTABLISHED.**  The ORIGIN of 0 in prom_d/prom_d.ld is a build
; convenience and asserts nothing.
;
; The leading hypothesis is that this is an image of the 512 KiB flash at
; 0xE80000 on *CPU 2's* bus: the file is exactly the size that flash's
; sector-erase routine proves, its content stops at 0x50B08 and is followed by
; one unbroken 0xFF run to the build tag (the shape of an erased flash, not of a
; mask ROM), its 44-entry header holds only 0-based offsets, and it contains no
; absolute code pointers.  prom_d/prom_d.ld sets that argument out in full,
; including the one earlier argument for it that does NOT work.
;
; What is missing is a byte-level tie between a structure in here and an
; instruction that reads it.  Until that exists the base stays unestablished.
;
; Contents seen so far: a 44-entry offset table at 0x00-0xB0 (max 0x050AFA);
; voice names around 0x50200 ("Helicopter", "Telephone", "Orchestra.Hit");
; " Dark Universe " at 0x1A1D1; the build tag "wsad_54.ssf" at 0x7FFF0.
;
; STATUS: not yet converted.  The whole image is one .incbin, so it builds
; byte-exact by construction and asserts nothing about its contents.  The gate
; (scripts/analysis/assert_byte_identical.py) must print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

wsa1_prom_d:
	.incbin "original_ROMs/wsa1_prom_d.bin"
end:
