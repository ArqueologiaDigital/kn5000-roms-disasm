; =============================================================================
; Character Map Mode Dispatch Table
; 42 entries mapping mode indices to CharMap handler routines
; Extracted from kn5000_v10_program.s
; =============================================================================
CharMap_ModeDispatchTable:
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_Mode6Forward
	.long CharMap_Mode7
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode17
	.long CharMap_FullPermutation
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode12
	.long CharMap_Mode18
	.long CharMap_Mode2Forward
	.long CharMap_Mode2Reverse
	.long CharMap_Mode2Forward
	.long CharMap_Mode2Reverse
	.long CharMap_Mode13
	.long CharMap_Mode19
	.long CharMap_Mode3Forward
	.long CharMap_Mode3Reverse
	.long CharMap_Mode3Forward
	.long CharMap_Mode3Reverse
	.long CharMap_Mode14
	.long CharMap_Mode20
	.long CharMap_Mode5Forward
	.long CharMap_Mode5Reverse
	.long CharMap_Mode9
	.long CharMap_Mode11
	.long CharMap_Mode16
	.long CharMap_Mode22
	.long CharMap_Mode4Forward
	.long CharMap_Mode4Reverse
	.long CharMap_Mode8
	.long CharMap_Mode10
	.long CharMap_Mode15
	.long CharMap_Mode21
