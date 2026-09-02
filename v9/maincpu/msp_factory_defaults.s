; MSP_FACTORY_DEFAULTS -- factory image of the accompaniment stream-buffer pool
;
; 5,376 bytes = 21 x 256.  Voice_InitBankData copies this to RAM 0x1E8B00 with
; `ldw bc, 0xa80` + `ldirw` (0xA80 WORDS), and Voice_GetSlotAddress computes
; `0x1e8b00 + (index << 8)`, so the destination is an array of 256-byte blocks
; and this image preloads the first 21 of the pool's 57.
;
; The record structure and every field name now live in msp_factory_defaults.c,
; which `clang -target tlcs900` compiles to the byte-identical 5,376 bytes
; .incbin'd below.  Each field there is named after the instruction that reads
; or writes it (allocation bit, prev/next block links, the two 0x87 guards the
; runtime cursor can never reach, and the accompaniment opcode stream), and the
; stream rows are split at event boundaries.
;
; The 5,376 bytes are byte-identical in v7, v9 and v10 (verified by
; scripts/generators/gen_msp_factory_defaults_c.py), so the same .c is used for
; all three images.
;
; !! The old header here called this "MSP (Music Style Preset) Factory Default
; Data ... default values for all MSP parameters".  No evidence supports that:
; nothing reads these bytes as parameters.  The label is kept only because the
; assembly references it by name.

MSP_FACTORY_DEFAULTS:
	.incbin "includes/generated/msp_factory_defaults.bin"
