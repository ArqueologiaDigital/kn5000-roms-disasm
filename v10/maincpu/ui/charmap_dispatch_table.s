; =============================================================================
; SndParam_ValueMapGrid (formerly "Character Map Mode Dispatch Table"):
; 7 rows x 6 u32 pointers to the 128-byte value maps in
; ui_widgets/widget_dispatch.s (SndParam_ValueMap_*).  Never read here in ROM:
; it is the last object of the RAM image Boot_InitWorkRAM_ROMCopy2_Start
; (0xEF0BD2) copies, 0x95B bytes ROM 0xEEFA66 -> RAM 0xE35E, so the grid lives
; at RAM 0xEC11 (= 0xE35E + 0xEF0319 - 0xEEFA66) and is read there by
; SndParam_LoadTableConverge (`lda` at 0xFEEB2C) and
; SndParam_LookupTableConverge (`lda` at 0xFEEBB1):
; `lda xde,(0xec11); ld xde,(xde+hl)` (xbc in the second) with
; hl = row * 0x18 (`muls hl,0x18`) + column offset 0/4/8/12/16/20, then
; `ld l,(map + value)`.  The row is the byte SndParam_LookupAndDispatch
; returns (0xFF: no map, the value passes through; the row is not
; bounds-checked, 7 rows is the grid's extent, which ends where the RAM image
; ends).  Column offsets come from SndParamChan_SwitchOffsets (+0,+4,+8,+12)
; and SndParamOffs_SwitchOffsets (+16,+20,+8,+12), indexed by the caller's
; selector 1..6; selectors 5 and 6 use NoteMap_ConvergeMapA/B instead.
; In every row the maps in columns 0/1, 2/3 and 4/5 are mutual inverses on
; their defined entries.  Row 0 is the identity map throughout.
; Pinned by scripts/generators/gen_sndparam_valuemap_headers.py --probe
; (v10, v9 and v7: same pointers, same map bytes).
; Extracted from kn5000_v10_program.s
; =============================================================================
SndParam_ValueMapGrid:
; row 0 (identity)
	.long SndParam_ValueMap_Identity
	.long SndParam_ValueMap_Identity
	.long SndParam_ValueMap_Identity
	.long SndParam_ValueMap_Identity
	.long SndParam_ValueMap_Identity
	.long SndParam_ValueMap_Identity
; row 1
	.long SndParam_ValueMap_R1P0
	.long SndParam_ValueMap_R1P0_Inv
	.long SndParam_ValueMap_R1P1
	.long SndParam_ValueMap_R1P1_Inv
	.long SndParam_ValueMap_R1P2
	.long SndParam_ValueMap_R1P2_Inv
; row 2
	.long SndParam_ValueMap_R1P1
	.long SndParam_ValueMap_R1P1_Inv
	.long SndParam_ValueMap_R1P1
	.long SndParam_ValueMap_R1P1_Inv
	.long SndParam_ValueMap_R2P2
	.long SndParam_ValueMap_R2P2_Inv
; row 3
	.long SndParam_ValueMap_R3P0
	.long SndParam_ValueMap_R3P0_Inv
	.long SndParam_ValueMap_R3P0
	.long SndParam_ValueMap_R3P0_Inv
	.long SndParam_ValueMap_R3P2
	.long SndParam_ValueMap_R3P2_Inv
; row 4
	.long SndParam_ValueMap_R4P0
	.long SndParam_ValueMap_R4P0_Inv
	.long SndParam_ValueMap_R4P0
	.long SndParam_ValueMap_R4P0_Inv
	.long SndParam_ValueMap_R4P2
	.long SndParam_ValueMap_R4P2_Inv
; row 5
	.long SndParam_ValueMap_R5P0
	.long SndParam_ValueMap_R5P0_Inv
	.long SndParam_ValueMap_R5P1
	.long SndParam_ValueMap_R5P1_Inv
	.long SndParam_ValueMap_R5P2
	.long SndParam_ValueMap_R5P2_Inv
; row 6
	.long SndParam_ValueMap_R6P0
	.long SndParam_ValueMap_R6P0_Inv
	.long SndParam_ValueMap_R6P1
	.long SndParam_ValueMap_R6P1_Inv
	.long SndParam_ValueMap_R6P2
	.long SndParam_ValueMap_R6P2_Inv
