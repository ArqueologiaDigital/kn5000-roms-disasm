	.text

; Technics SX-WSA1R -- wsa1_prom_d.bin
; Target CPU: Toshiba TMP95C061 (TLCS-900/H)
;
; Designator not legible in the manual scan. DATA ONLY -- 0 of 64 vector slots are plausible (all 0xFFFFFFFF). Base address UNKNOWN; ORIGIN 0 here is a build convenience and asserts nothing.
;
; STATUS: bootstrap. The whole image is still one .incbin, so this tree builds
; byte-exact by construction and nothing here is yet a claim about the contents.
; Territory is converted incrementally; the gate
; (scripts/analysis/assert_byte_identical.py) must stay green at every commit.

wsa1_prom_d:
	.incbin "original_ROMs/wsa1_prom_d.bin"
end:
