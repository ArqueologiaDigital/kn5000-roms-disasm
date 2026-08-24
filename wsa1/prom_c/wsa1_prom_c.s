	.text

; Technics SX-WSA1R -- wsa1_prom_c.ic28
; Target CPU: Toshiba TMP95C061 (TLCS-900/H)
;
; IC28, program EPROM of the SECOND processor. Load address ESTABLISHED the same way as A: 33 of 64 vectors at 0x7FF00.
;
; STATUS: bootstrap. The whole image is still one .incbin, so this tree builds
; byte-exact by construction and nothing here is yet a claim about the contents.
; Territory is converted incrementally; the gate
; (scripts/analysis/assert_byte_identical.py) must stay green at every commit.

wsa1_prom_c:
	.incbin "original_ROMs/wsa1_prom_c.ic28"
end:
