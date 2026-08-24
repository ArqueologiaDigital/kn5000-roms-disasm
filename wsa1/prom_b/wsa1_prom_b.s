	.text

; Technics SX-WSA1R -- wsa1_prom_b.ic13
; Target CPU: Toshiba TMP95C061 (TLCS-900/H)
;
; IC13, second EPROM on the same bus as A. Base 0xF00000 is INFERRED from A sitting at 0xF80000 and the pair filling a 1 MiB window; only 3 of 64 words at its 0x7FF00 look like vectors, so it is not a boot image.
;
; STATUS: bootstrap. The whole image is still one .incbin, so this tree builds
; byte-exact by construction and nothing here is yet a claim about the contents.
; Territory is converted incrementally; the gate
; (scripts/analysis/assert_byte_identical.py) must stay green at every commit.

wsa1_prom_b:
	.incbin "original_ROMs/wsa1_prom_b.ic13"
end:
