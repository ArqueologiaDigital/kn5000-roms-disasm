	.text

; Technics SX-WSA1R -- wsa1_prom_a.ic12
; Target CPU: Toshiba TMP95C061 (TLCS-900/H)
;
; IC12, program EPROM. Load address ESTABLISHED: 33 of 64 interrupt vectors at file offset 0x7FF00 point into 0xF00000-0xFFFFFF, which places 0xFFFF00 there, i.e. base 0xF80000.
;
; STATUS: bootstrap. The whole image is still one .incbin, so this tree builds
; byte-exact by construction and nothing here is yet a claim about the contents.
; Territory is converted incrementally; the gate
; (scripts/analysis/assert_byte_identical.py) must stay green at every commit.

wsa1_prom_a:
	.incbin "original_ROMs/wsa1_prom_a.ic12"
end:
