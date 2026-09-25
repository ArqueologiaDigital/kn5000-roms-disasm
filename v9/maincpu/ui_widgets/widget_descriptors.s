
; =============================================================================
; Widget Descriptor Tables & Grid Data  (ROM 0xE30E60-0xE55BC7, 150888 bytes)
; Source: maincpu/ui_widgets/naka_widget_descriptors.c (compiled, then .incbin'd)
; =============================================================================
; One packed C struct covering the whole blob.  Most of it is NAKA widget
; descriptor material; the labels below name the parts that other modules
; reach into.
;
; DSP EFFECT NAMING ZONE (0xE32418-0xE33579)
; -----------------------------------------
; The user-facing naming layer of the effects DSP.  Four tables, all consumed
; by the effect-editor handlers in sequencer/sequencer_ui.s:
;
;   0xE32418  DspParamUnit_Table     86 x  2  parameter unit  ("Hz", "ms", "s ")
;   0xE324C4  DspParamName_Table     86 x 17  parameter name + ':' separator
;   0xE32A7A  DspEffectName_PtrTable 128 x u32, indexed by EFFECT NUMBER
;   0xE32C7A  DspEffectName_Strings  128 x 18  16 chars + 0x00 + 0xFF filler
;
; DspEffectName_PtrTable[n] points at DspEffectName_Strings + 18*(127-n): the
; string block is stored in DESCENDING effect order, which is why the existing
; NakaInst_<EFFECT> labels below run from effect 127 (lowest address) down to
; effect 0 (highest).  Effect numbers 100-127 are "   ----------   " spares.
;
; The unit and name tables share one index: the parameter-id byte of the
; effect's ordered UI parameter list.  Slots 0 and 85 are blank spares.
;
; Consumers (sequencer/sequencer_ui.s):
;   DspItem0_DisplayEffectName  0xF355F3  effect no. (RAM 0x2976) -> ptr table
;   DspItem0_DisplayParamNames  0xF3561F  param id -> name, Strncpy 17
;   DspItem0_DisplayParamValues 0xF3566C  param id -> unit, Strncpy 2
;   EntGridCheck (0xF30326 region)        also reads DspEffectName_PtrTable
;
; Both parameter routines take the id from the per-effect ordered id list at
; RAM 0x29AC, starting at the row index held in the byte at 0x021098, and
; paint 8 rows per page.
;
; The algorithms these names label live in the sub-CPU payload; see
; v142/subcpu/subcpu_data_tables.s (DSP_EffNN_* / DSP2_EffNN_* blocks) and
; technics-docs/dsp-effect-data-zone.md.
; =============================================================================
NakaData_WidgetDescriptors:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x0, 0x1E1A
; [naka_s_headers:short] NakaInst_FxReservedSlot_00
; Effect 127 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 127 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_00:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E1A, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_01
; Effect 126 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 126 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_01:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E2C, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_02
; Effect 125 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 125 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_02:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E3E, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_03
; Effect 124 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 124 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_03:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E50, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_04
; Effect 123 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 123 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_04:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E62, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_05
; Effect 122 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 122 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_05:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E74, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_06
; Effect 121 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 121 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_06:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E86, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_07
; Effect 120 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 120 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_07:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E98, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_08
; Effect 119 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 119 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_08:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EAA, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_09
; Effect 118 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 118 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_09:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EBC, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_10
; Effect 117 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 117 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_10:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1ECE, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_11
; Effect 116 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 116 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_11:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EE0, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_12
; Effect 115 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 115 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_12:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EF2, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_13
; Effect 114 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 114 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_13:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F04, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_14
; Effect 113 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 113 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_14:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F16, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_15
; Effect 112 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 112 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_15:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F28, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_16
; Effect 111 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 111 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_16:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F3A, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_17
; Effect 110 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 110 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_17:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F4C, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_18
; Effect 109 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 109 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_18:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F5E, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_19
; Effect 108 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 108 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_19:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F70, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_20
; Effect 107 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 107 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_20:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F82, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_21
; Effect 106 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 106 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_21:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F94, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_22
; Effect 105 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 105 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_22:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FA6, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_23
; Effect 104 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 104 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_23:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FB8, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_24
; Effect 103 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 103 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_24:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FCA, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_25
; Effect 102 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 102 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_25:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FDC, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_26
; Effect 101 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 101 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_26:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FEE, 0x12
; [naka_s_headers:short] NakaInst_FxReservedSlot_27
; Effect 100 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 100 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxReservedSlot_27:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2000, 0x12
; [naka_s_headers:short] NakaInst_PEQ_OVERDR_DELAY
; Effect 99 name, 18 bytes ("PEQ+OVERDR+DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 99 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_OVERDR_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2012, 0x12
; [naka_s_headers:short] NakaInst_PEQ_DIST_DELAY
; Effect 98 name, 18 bytes (" PEQ+DIST+DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 98 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_DIST_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2024, 0x12
; [naka_s_headers:short] NakaInst_PEQ_COMPR_OVERDR
; Effect 97 name, 18 bytes ("PEQ+COMPR+OVERDR", NUL, 0xff):
; DspEffectName_PtrTable entry 97 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_COMPR_OVERDR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2036, 0x12
; [naka_s_headers:short] NakaInst_PEQ_COMPR_DIST
; Effect 96 name, 18 bytes (" PEQ+COMPR+DIST", NUL, 0xff):
; DspEffectName_PtrTable entry 96 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_COMPR_DIST:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2048, 0x12
; [naka_s_headers:short] NakaInst_FxComboReserved_0
; Effect 95 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 95 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxComboReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x205A, 0x12
; [naka_s_headers:short] NakaInst_FxComboReserved_1
; Effect 94 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 94 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxComboReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x206C, 0x12
; [naka_s_headers:short] NakaInst_FxComboReserved_2
; Effect 93 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 93 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxComboReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x207E, 0x12
; [naka_s_headers:short] NakaInst_FxComboReserved_3
; Effect 92 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 92 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FxComboReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2090, 0x12
; [naka_s_headers:short] NakaInst_STAGE
; Effect 91 name, 18 bytes (" STAGE", NUL, 0xff): DspEffectName_PtrTable
; entry 91 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_STAGE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20A2, 0x12
; [naka_s_headers:short] NakaInst_BATH_ROOM
; Effect 90 name, 18 bytes ("BATH ROOM", NUL, 0xff):
; DspEffectName_PtrTable entry 90 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_BATH_ROOM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20B4, 0x12
; [naka_s_headers:short] NakaInst_KARAOKE
; Effect 89 name, 18 bytes (" KARAOKE", NUL, 0xff):
; DspEffectName_PtrTable entry 89 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_KARAOKE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20C6, 0x12
; [naka_s_headers:short] NakaInst_ROOM
; Effect 88 name, 18 bytes (" ROOM", NUL, 0xff): DspEffectName_PtrTable
; entry 88 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_ROOM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20D8, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_0
; Effect 87 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 87 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20EA, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_1
; Effect 86 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 86 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20FC, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_2
; Effect 85 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 85 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x210E, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_3
; Effect 84 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 84 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2120, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_4
; Effect 83 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 83 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2132, 0x12
; [naka_s_headers:short] NakaInst_ReverbReserved_5
; Effect 82 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 82 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbReserved_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2144, 0x12
; [naka_s_headers:short] NakaInst_OVER_D
; Effect 81 name, 18 bytes (" OVER_D", NUL, 0xff):
; DspEffectName_PtrTable entry 81 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_OVER_D:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2156, 0x12
; [naka_s_headers:short] NakaInst_DS_D
; Effect 80 name, 18 bytes (" DS_D", NUL, 0xff): DspEffectName_PtrTable
; entry 80 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_DS_D:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2168, 0x12
; [naka_s_headers:short] NakaInst_GEQ
; Effect 79 name, 18 bytes (" GEQ", NUL, 0xff): DspEffectName_PtrTable
; entry 79 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_GEQ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x217A, 0x12
; [naka_s_headers:short] NakaInst_EqReserved_0
; Effect 78 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 78 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_EqReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x218C, 0x12
; [naka_s_headers:short] NakaInst_EqReserved_1
; Effect 77 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 77 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_EqReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x219E, 0x12
; [naka_s_headers:short] NakaInst_EqReserved_2
; Effect 76 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 76 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_EqReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21B0, 0x12
; [naka_s_headers:short] NakaInst_PEQ_COMPRESSOR
; Effect 75 name, 18 bytes (" PEQ+COMPRESSOR", NUL, 0xff):
; DspEffectName_PtrTable entry 75 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_COMPRESSOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21C2, 0x12
; [naka_s_headers:short] NakaInst_PEQ_VIBRATO
; Effect 74 name, 18 bytes (" PEQ+VIBRATO", NUL, 0xff):
; DspEffectName_PtrTable entry 74 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21D4, 0x12
; [naka_s_headers:short] NakaInst_PEQ_FLANGER
; Effect 73 name, 18 bytes (" PEQ+FLANGER", NUL, 0xff):
; DspEffectName_PtrTable entry 73 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21E6, 0x12
; [naka_s_headers:short] NakaInst_PEQ_S_DELAY
; Effect 72 name, 18 bytes (" PEQ+S.DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 72 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21F8, 0x12
; [naka_s_headers:short] NakaInst_PEQ_CHORUS
; Effect 71 name, 18 bytes (" PEQ+CHORUS", NUL, 0xff):
; DspEffectName_PtrTable entry 71 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEQ_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x220A, 0x12
; [naka_s_headers:short] NakaInst_AUTO_WAH_S_DELAY
; Effect 70 name, 18 bytes ("AUTO WAH+S.DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 70 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_AUTO_WAH_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x221C, 0x12
; [naka_s_headers:short] NakaInst_PEDAL_WAH_DELAY
; Effect 69 name, 18 bytes ("PEDAL WAH+DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 69 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEDAL_WAH_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x222E, 0x12
; [naka_s_headers:short] NakaInst_S_DELAY_PHASER
; Effect 68 name, 18 bytes (" S.DELAY+PHASER", NUL, 0xff):
; DspEffectName_PtrTable entry 68 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_S_DELAY_PHASER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2240, 0x12
; [naka_s_headers:short] NakaInst_S_DELAY_VIBRATO
; Effect 67 name, 18 bytes ("S.DELAY+VIBRATO", NUL, 0xff):
; DspEffectName_PtrTable entry 67 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_S_DELAY_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2252, 0x12
; [naka_s_headers:short] NakaInst_S_DELAY_FLANGER
; Effect 66 name, 18 bytes ("S.DELAY+FLANGER", NUL, 0xff):
; DspEffectName_PtrTable entry 66 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_S_DELAY_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2264, 0x12
; [naka_s_headers:short] NakaInst_S_DELAY_S_DELAY
; Effect 65 name, 18 bytes ("S.DELAY+S.DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 65 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_S_DELAY_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2276, 0x12
; [naka_s_headers:short] NakaInst_S_DELAY_CHORUS
; Effect 64 name, 18 bytes ("S.DELAY+CHORUS", NUL, 0xff):
; DspEffectName_PtrTable entry 64 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_S_DELAY_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2288, 0x12
; [naka_s_headers:short] NakaInst_STRING
; Effect 63 name, 18 bytes (" STRING", NUL, 0xff):
; DspEffectName_PtrTable entry 63 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_STRING:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x229A, 0x12
; [naka_s_headers:short] NakaInst_ChorusReserved_0
; Effect 62 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 62 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ChorusReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22AC, 0x12
; [naka_s_headers:short] NakaInst_ChorusReserved_1
; Effect 61 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 61 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ChorusReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22BE, 0x12
; [naka_s_headers:short] NakaInst_DEEP_SPACE
; Effect 60 name, 18 bytes (" DEEP SPACE", NUL, 0xff):
; DspEffectName_PtrTable entry 60 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DEEP_SPACE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22D0, 0x12
; [naka_s_headers:short] NakaInst_SYMPHONIC
; Effect 59 name, 18 bytes (" SYMPHONIC", NUL, 0xff):
; DspEffectName_PtrTable entry 59 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_SYMPHONIC:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22E2, 0x12
; [naka_s_headers:short] NakaInst_PERCUSSIVE
; Effect 58 name, 18 bytes (" PERCUSSIVE", NUL, 0xff):
; DspEffectName_PtrTable entry 58 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PERCUSSIVE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22F4, 0x12
; [naka_s_headers:short] NakaInst_STANDARD
; Effect 57 name, 18 bytes (" STANDARD", NUL, 0xff):
; DspEffectName_PtrTable entry 57 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_STANDARD:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2306, 0x12
; [naka_s_headers:short] NakaInst_MIX_UP
; Effect 56 name, 18 bytes (" MIX UP", NUL, 0xff):
; DspEffectName_PtrTable entry 56 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_MIX_UP:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2318, 0x12
; [naka_s_headers:short] NakaInst_HARS_EFFECT
; Effect 55 name, 18 bytes (" HARS EFFECT", NUL, 0xff):
; DspEffectName_PtrTable entry 55 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_HARS_EFFECT:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x232A, 0x12
; [naka_s_headers:short] NakaInst_RING_MODULATOR
; Effect 54 name, 18 bytes (" RING MODULATOR", NUL, 0xff):
; DspEffectName_PtrTable entry 54 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_RING_MODULATOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x233C, 0x12
; [naka_s_headers:short] NakaInst_ROTARY_SPEAKER
; Effect 53 name, 18 bytes (" ROTARY SPEAKER", NUL, 0xff):
; DspEffectName_PtrTable entry 53 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ROTARY_SPEAKER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x234E, 0x12
; [naka_s_headers:short] NakaInst_AUTO_WAH
; Effect 52 name, 18 bytes (" AUTO WAH", NUL, 0xff):
; DspEffectName_PtrTable entry 52 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_AUTO_WAH:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2360, 0x12
; [naka_s_headers:short] NakaInst_PEDAL_WAH
; Effect 51 name, 18 bytes (" PEDAL WAH", NUL, 0xff):
; DspEffectName_PtrTable entry 51 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PEDAL_WAH:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2372, 0x12
; [naka_s_headers:short] NakaInst_VIBRATO
; Effect 50 name, 18 bytes (" VIBRATO", NUL, 0xff):
; DspEffectName_PtrTable entry 50 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2384, 0x12
; [naka_s_headers:short] NakaInst_PITCH_SHIFTER
; Effect 49 name, 18 bytes (" PITCH SHIFTER", NUL, 0xff):
; DspEffectName_PtrTable entry 49 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PITCH_SHIFTER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2396, 0x12
; [naka_s_headers:short] NakaInst_AUTO_PAN
; Effect 48 name, 18 bytes (" AUTO PAN", NUL, 0xff):
; DspEffectName_PtrTable entry 48 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_AUTO_PAN:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23A8, 0x12
; [naka_s_headers:short] NakaInst_ModulationReserved_0
; Effect 47 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 47 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ModulationReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23BA, 0x12
; [naka_s_headers:short] NakaInst_ModulationReserved_1
; Effect 46 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 46 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ModulationReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23CC, 0x12
; [naka_s_headers:short] NakaInst_CELM
; Effect 45 name, 18 bytes (" CELM", NUL, 0xff): DspEffectName_PtrTable
; entry 45 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_CELM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23DE, 0x12
; [naka_s_headers:short] NakaInst_CEL
; Effect 44 name, 18 bytes (" CEL", NUL, 0xff): DspEffectName_PtrTable
; entry 44 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_CEL:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23F0, 0x12
; [naka_s_headers:short] NakaInst_CelReserved_0
; Effect 43 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 43 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CelReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2402, 0x12
; [naka_s_headers:short] NakaInst_CelReserved_1
; Effect 42 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 42 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CelReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2414, 0x12
; [naka_s_headers:short] NakaInst_CelReserved_2
; Effect 41 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 41 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CelReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2426, 0x12
; [naka_s_headers:short] NakaInst_CelReserved_3
; Effect 40 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 40 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CelReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2438, 0x12
; [naka_s_headers:short] NakaInst_PARAMETRIC_EQ
; Effect 39 name, 18 bytes (" PARAMETRIC EQ", NUL, 0xff):
; DspEffectName_PtrTable entry 39 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PARAMETRIC_EQ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x244A, 0x12
; [naka_s_headers:short] NakaInst_NOISE_FLANGER
; Effect 38 name, 18 bytes (" NOISE FLANGER", NUL, 0xff):
; DspEffectName_PtrTable entry 38 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_NOISE_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245C, 0x12
; [naka_s_headers:short] NakaInst_SLOW_ATTACKER
; Effect 37 name, 18 bytes (" SLOW ATTACKER", NUL, 0xff):
; DspEffectName_PtrTable entry 37 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_SLOW_ATTACKER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246E, 0x12
; [naka_s_headers:short] NakaInst_COMPRESSOR
; Effect 36 name, 18 bytes (" COMPRESSOR", NUL, 0xff):
; DspEffectName_PtrTable entry 36 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_COMPRESSOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2480, 0x12
; [naka_s_headers:short] NakaInst_EXCITER
; Effect 35 name, 18 bytes (" EXCITER", NUL, 0xff):
; DspEffectName_PtrTable entry 35 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_EXCITER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2492, 0x12
; [naka_s_headers:short] NakaInst_FUZZ
; Effect 34 name, 18 bytes (" FUZZ", NUL, 0xff): DspEffectName_PtrTable
; entry 34 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_FUZZ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A4, 0x12
; [naka_s_headers:short] NakaInst_OVERDRIVE
; Effect 33 name, 18 bytes (" OVERDRIVE", NUL, 0xff):
; DspEffectName_PtrTable entry 33 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_OVERDRIVE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B6, 0x12
; [naka_s_headers:short] NakaInst_DISTORTION
; Effect 32 name, 18 bytes (" DISTORTION", NUL, 0xff):
; DspEffectName_PtrTable entry 32 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DISTORTION:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24C8, 0x12
; [naka_s_headers:short] NakaInst_DistReserved_0
; Effect 31 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 31 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DistReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24DA, 0x12
; [naka_s_headers:short] NakaInst_DistReserved_1
; Effect 30 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 30 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DistReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24EC, 0x12
; [naka_s_headers:short] NakaInst_DistReserved_2
; Effect 29 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 29 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DistReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24FE, 0x12
; [naka_s_headers:short] NakaInst_DistReserved_3
; Effect 28 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 28 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DistReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2510, 0x12
; [naka_s_headers:short] NakaInst_WAVE_REVERB_2
; Effect 27 name, 18 bytes (" WAVE REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 27 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_WAVE_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2522, 0x12
; [naka_s_headers:short] NakaInst_WAVE_REVERB_1
; Effect 26 name, 18 bytes (" WAVE REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 26 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_WAVE_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2534, 0x12
; [naka_s_headers:short] NakaInst_BRIGHT_REVERB_2
; Effect 25 name, 18 bytes ("BRIGHT REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 25 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_BRIGHT_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2546, 0x12
; [naka_s_headers:short] NakaInst_BRIGHT_REVERB_1
; Effect 24 name, 18 bytes ("BRIGHT REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 24 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_BRIGHT_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2558, 0x12
; [naka_s_headers:short] NakaInst_DARK_REVERB_2
; Effect 23 name, 18 bytes (" DARK REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 23 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DARK_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x256A, 0x12
; [naka_s_headers:short] NakaInst_DARK_REVERB_1
; Effect 22 name, 18 bytes (" DARK REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 22 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DARK_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x257C, 0x12
; [naka_s_headers:short] NakaInst_CONCERT_REVERB_2
; Effect 21 name, 18 bytes ("CONCERT REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 21 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CONCERT_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x258E, 0x12
; [naka_s_headers:short] NakaInst_CONCERT_REVERB_1
; Effect 20 name, 18 bytes ("CONCERT REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 20 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_CONCERT_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25A0, 0x12
; [naka_s_headers:short] NakaInst_PLATE_REVERB_2
; Effect 19 name, 18 bytes (" PLATE REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 19 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PLATE_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25B2, 0x12
; [naka_s_headers:short] NakaInst_PLATE_REVERB_1
; Effect 18 name, 18 bytes (" PLATE REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 18 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_PLATE_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25C4, 0x12
; [naka_s_headers:short] NakaInst_ROOM_REVERB_2
; Effect 17 name, 18 bytes (" ROOM REVERB 2", NUL, 0xff):
; DspEffectName_PtrTable entry 17 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ROOM_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25D6, 0x12
; [naka_s_headers:short] NakaInst_ROOM_REVERB_1
; Effect 16 name, 18 bytes (" ROOM REVERB 1", NUL, 0xff):
; DspEffectName_PtrTable entry 16 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ROOM_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25E8, 0x12
; [naka_s_headers:short] NakaInst_ROCK_ROTARY
; Effect 15 name, 18 bytes (" ROCK ROTARY", NUL, 0xff):
; DspEffectName_PtrTable entry 15 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ROCK_ROTARY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25FA, 0x12
; [naka_s_headers:short] NakaInst_DelayReserved_0
; Effect 14 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 14 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DelayReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x260C, 0x12
; [naka_s_headers:short] NakaInst_DelayReserved_1
; Effect 13 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 13 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DelayReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x261E, 0x12
; [naka_s_headers:short] NakaInst_DelayReserved_2
; Effect 12 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 12 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_DelayReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2630, 0x12
; [naka_s_headers:short] NakaInst_MODULATION_DELAY
; Effect 11 name, 18 bytes ("MODULATION DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 11 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_MODULATION_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2642, 0x12
; [naka_s_headers:short] NakaInst_MULTI_TAP_DELAY
; Effect 10 name, 18 bytes ("MULTI TAP DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 10 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_MULTI_TAP_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2654, 0x12
; [naka_s_headers:short] NakaInst_SINGLE_DELAY
; Effect 9 name, 18 bytes (" SINGLE DELAY", NUL, 0xff):
; DspEffectName_PtrTable entry 9 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_SINGLE_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2666, 0x12
; [naka_s_headers:short] NakaInst_GATED_REVERB
; Effect 8 name, 18 bytes (" GATED REVERB", NUL, 0xff):
; DspEffectName_PtrTable entry 8 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_GATED_REVERB:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2678, 0x12
; [naka_s_headers:short] NakaInst_ReverbGateReserved
; Effect 7 name, 18 bytes (" ----------", NUL, 0xff):
; DspEffectName_PtrTable entry 7 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ReverbGateReserved:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x268A, 0x12
; [naka_s_headers:short] NakaInst_ENSEMBLE
; Effect 6 name, 18 bytes (" ENSEMBLE", NUL, 0xff):
; DspEffectName_PtrTable entry 6 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ENSEMBLE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x269C, 0x12
; [naka_s_headers:short] NakaInst_PHASER
; Effect 5 name, 18 bytes (" PHASER", NUL, 0xff): DspEffectName_PtrTable
; entry 5 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_PHASER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26AE, 0x12
; [naka_s_headers:short] NakaInst_FLANGER
; Effect 4 name, 18 bytes (" FLANGER", NUL, 0xff):
; DspEffectName_PtrTable entry 4 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26C0, 0x12
; [naka_s_headers:short] NakaInst_ENHANCER
; Effect 3 name, 18 bytes (" ENHANCER", NUL, 0xff):
; DspEffectName_PtrTable entry 3 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_ENHANCER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26D2, 0x12
; [naka_s_headers:short] NakaInst_MODULATED_CHORUS
; Effect 2 name, 18 bytes ("MODULATED CHORUS", NUL, 0xff):
; DspEffectName_PtrTable entry 2 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_MODULATED_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26E4, 0x12
; [naka_s_headers:short] NakaInst_CHORUS
; Effect 1 name, 18 bytes (" CHORUS", NUL, 0xff): DspEffectName_PtrTable
; entry 1 points here, and DspItem0_DisplayEffectName (v10/v9 0xf355f3,
; v7 0xf355c9) Strcpy's it (the effect-number -> name table is described
; in the file header).
NakaInst_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26F6, 0x12
; [naka_s_headers:short] NakaInst_NO_OPERATION
; Effect 0 name, 18 bytes (" NO OPERATION", NUL, 0xff):
; DspEffectName_PtrTable entry 0 points here, and
; DspItem0_DisplayEffectName (v10/v9 0xf355f3, v7 0xf355c9) Strcpy's it
; (the effect-number -> name table is described in the file header).
NakaInst_NO_OPERATION:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2708, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBox_HandleInitEvent_Table
; EffectBox_HandleInitEvent_Table -- read by EffectBox_HandleInitEvent
; (v10/v9 0xf3354a, v7 0xf33520) (`ld xbc, NakaInst_NO_OPERATION_0x12`).
; 8 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffectBox_HandleInitEvent_Table[8].
; -----------------------------------------------------------------------------
EffectBox_HandleInitEvent_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x271A, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBox_PostFillSetup_Table
; EffectBox_PostFillSetup_Table -- read by EffectBox_PostFillSetup
; (v10/v9 0xf33752, v7 0xf33728) (`ld xhl, NakaInst_NO_OPERATION_0x1a`),
; EffectBox_PostFill3Setup (v10/v9 0xf337f8, v7 0xf337ce) (`ld xhl,
; NakaInst_NO_OPERATION_0x1a`), EffectBox_HandleSelectEvent (v10/v9
; 0xf339bf, v7 0xf33995) (`ld xwa, NakaInst_NO_OPERATION_0x1a`). 8 bytes
; to the next object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffectBox_PostFillSetup_Table[8].
; -----------------------------------------------------------------------------
EffectBox_PostFillSetup_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2722, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyVal_HandleScrollEvent_Table
; SqplyVal_HandleScrollEvent_Table -- read by SqplyVal_HandleScrollEvent
; (v10/v9 0xf30b75, v7 0xf30b4b) (`ld xde, NakaInst_NO_OPERATION_0x22`).
; 96 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqplyVal_HandleScrollEvent_Table[96].
; -----------------------------------------------------------------------------
SqplyVal_HandleScrollEvent_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x272A, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal_HandleScrollEvent_Table
; SqedtVal_HandleScrollEvent_Table -- read by SqedtVal_HandleScrollEvent
; (v10/v9 0xf31125, v7 0xf310fb) (`ld xde, NakaInst_NO_OPERATION_0x82`),
; SqedtVal3_HandleScrollEvent (v10/v9 0xf31f13, v7 0xf31ee9) (`lda xde,
; (NakaInst_NO_OPERATION_0x82:24)`), SqedtVal3_FillBufferLoop1 (v10/v9
; 0xf31fb4, v7 0xf31f8a) (`lda xde, (NakaInst_NO_OPERATION_0x82:24)`),
; SqedtVal3_FillBufferLoop2 (v10/v9 0xf3205d, v7 0xf32033) (`lda xde,
; (NakaInst_NO_OPERATION_0x82:24)`), SqedtVal3_FillBufferLoop3 (v10/v9
; 0xf32106, v7 0xf320dc) (`lda xde, (NakaInst_NO_OPERATION_0x82:24)`),
; SqedtVal2_HandleScrollEvent (v10/v9 0xf32380, v7 0xf32356) (`ld xde,
; NakaInst_NO_OPERATION_0x82`). 280 bytes to the next object; the layout
; beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtVal_HandleScrollEvent_Table[280].
; -----------------------------------------------------------------------------
SqedtVal_HandleScrollEvent_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x278A, 0x118
; -----------------------------------------------------------------------------
; [naka_s_headers] BmDrEdit_RenderHorizontal_Table
; BmDrEdit_RenderHorizontal_Table -- read by BmDrEdit_RenderHorizontal
; (v10/v9 0xf361c1, v7 0xf36197) (`lda xbc,
; (NakaInst_NO_OPERATION_0x19a:24)`), BmDrEdit_RenderSecondaryHoriz
; (v10/v9 0xf36282, v7 0xf36258) (`lda xbc,
; (NakaInst_NO_OPERATION_0x19a:24)`). 58 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; BmDrEdit_RenderHorizontal_Table[58].
; -----------------------------------------------------------------------------
BmDrEdit_RenderHorizontal_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x28A2, 0x3A
; -----------------------------------------------------------------------------
; [naka_s_headers] BmDrEdit_RenderVertical_Table
; BmDrEdit_RenderVertical_Table -- read by BmDrEdit_RenderVertical
; (v10/v9 0xf361fe, v7 0xf361d4) (`lda xbc,
; (NakaInst_NO_OPERATION_0x1d4:24)`), BmDrEdit_RenderSecondaryVert
; (v10/v9 0xf362c1, v7 0xf36297) (`lda xbc,
; (NakaInst_NO_OPERATION_0x1d4:24)`). 28 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; BmDrEdit_RenderVertical_Table[28].
; -----------------------------------------------------------------------------
BmDrEdit_RenderVertical_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x28DC, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_HandleFocusLost_Table
; NoteEditBox_HandleFocusLost_Table -- read by
; NoteEditBox_HandleFocusLost (v10/v9 0xf2f0f9, v7 0xf2f0cf) (`ld xwa,
; NakaInst_NO_OPERATION_0x1f0`). 12 bytes to the next object; the layout
; beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEditBox_HandleFocusLost_Table[12].
; -----------------------------------------------------------------------------
NoteEditBox_HandleFocusLost_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x28F8, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_HandleFocusLost_Table_2
; NoteEditBox_HandleFocusLost_Table_2 -- read by
; NoteEditBox_HandleFocusLost (v10/v9 0xf2f0f9, v7 0xf2f0cf) (`ld xwa,
; NakaInst_NO_OPERATION_0x1fc`). 12 bytes to the next object; the layout
; beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEditBox_HandleFocusLost_Table_2[12].
; -----------------------------------------------------------------------------
NoteEditBox_HandleFocusLost_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2904, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Table
; NoteEditBox_EventDispatch2_Table -- read by NoteEditBox_EventDispatch2
; (v10/v9 0xf2f2a0, v7 0xf2f276) (`lda xde,
; (NakaInst_NO_OPERATION_0x208:24)`), NoteEditBox_EventDispatch2 (v10/v9
; 0xf2f2a0, v7 0xf2f276) (`lda xbc, (NakaInst_NO_OPERATION_0x208:24)`),
; NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`lda xix,
; (NakaInst_NO_OPERATION_0x208:24)`), NoteEditGrid_LoadCoordinates
; (v10/v9 0xf2f97f, v7 0xf2f955) (`lda xde,
; (NakaInst_NO_OPERATION_0x208:24)`). 72 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEditBox_EventDispatch2_Table[72].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2910, 0x48
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Table_2
; NoteEditBox_EventDispatch2_Table_2 -- read by
; NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`lda xbc,
; (NakaInst_NO_OPERATION_0x250:24)`). 24 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEditBox_EventDispatch2_Table_2[24].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2958, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Table_3
; NoteEditBox_EventDispatch2_Table_3 -- read by
; NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`lda xbc,
; (NakaInst_NO_OPERATION_0x268:24)`). 18 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEditBox_EventDispatch2_Table_3[18].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Table_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2970, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditFunc_Table
; NoteEditFunc_Table -- read by NoteEditFunc (v10/v9 0xf2fa5a, v7
; 0xf2fa30) (`lda xhl, (NakaInst_NO_OPERATION_0x27a:24)`). 66 bytes to
; the next object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t NoteEditFunc_Table[66].
; -----------------------------------------------------------------------------
NoteEditFunc_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2982, 0x42
; -----------------------------------------------------------------------------
; [naka_s_headers] AttAreYouSureCheck_Strings
; AttAreYouSureCheck_Strings -- the 6 strings
; AttAreYouSureCheck_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 158 bytes.
;
; Typed in naka_widget_descriptors.c as char
; AttAreYouSureCheck_Strings[158].
; -----------------------------------------------------------------------------
AttAreYouSureCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x29C4, 0x9E
; -----------------------------------------------------------------------------
; [naka_s_headers] StsSeqMenu1Check_Strings
; StsSeqMenu1Check_Strings -- the 2 strings StsSeqMenu1Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 70 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsSeqMenu1Check_Strings[70].
; -----------------------------------------------------------------------------
StsSeqMenu1Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2A62, 0x46
; -----------------------------------------------------------------------------
; [naka_s_headers] StsSeqMenu2Check_Strings
; StsSeqMenu2Check_Strings -- the 2 strings StsSeqMenu2Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 70 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsSeqMenu2Check_Strings[70].
; -----------------------------------------------------------------------------
StsSeqMenu2Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2AA8, 0x46
; -----------------------------------------------------------------------------
; [naka_s_headers] StsEasyRec1Check_Strings
; StsEasyRec1Check_Strings -- the 2 strings StsEasyRec1Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 276 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsEasyRec1Check_Strings[276].
; -----------------------------------------------------------------------------
StsEasyRec1Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2AEE, 0x114
; -----------------------------------------------------------------------------
; [naka_s_headers] StsEasyRec2Check_Strings
; StsEasyRec2Check_Strings -- the 2 strings StsEasyRec2Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 46 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsEasyRec2Check_Strings[46].
; -----------------------------------------------------------------------------
StsEasyRec2Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2C02, 0x2E
; -----------------------------------------------------------------------------
; [naka_s_headers] StsPnlWrtCheck_Strings
; StsPnlWrtCheck_Strings -- the 2 strings StsPnlWrtCheck_PtrTable points
; at (NUL-terminated, 0xff pad to even length), 416 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsPnlWrtCheck_Strings[416].
; -----------------------------------------------------------------------------
StsPnlWrtCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2C30, 0x1A0
; -----------------------------------------------------------------------------
; [naka_s_headers] StsTrkClr1Check_Strings
; StsTrkClr1Check_Strings -- the 2 strings StsTrkClr1Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 200 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsTrkClr1Check_Strings[200].
; -----------------------------------------------------------------------------
StsTrkClr1Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2DD0, 0xC8
; -----------------------------------------------------------------------------
; [naka_s_headers] StsTrkClr2Check_Strings
; StsTrkClr2Check_Strings -- the 2 strings StsTrkClr2Check_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 78 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsTrkClr2Check_Strings[78].
; -----------------------------------------------------------------------------
StsTrkClr2Check_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2E98, 0x4E
; -----------------------------------------------------------------------------
; [naka_s_headers] StsNtDrEditCheck_Strings
; StsNtDrEditCheck_Strings -- the 2 strings StsNtDrEditCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 196 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsNtDrEditCheck_Strings[196].
; -----------------------------------------------------------------------------
StsNtDrEditCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2EE6, 0xC4
; -----------------------------------------------------------------------------
; [naka_s_headers] AttSongClrCheck_Strings
; AttSongClrCheck_Strings -- the 5 strings AttSongClrCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 358 bytes.
;
; Typed in naka_widget_descriptors.c as char
; AttSongClrCheck_Strings[358].
; -----------------------------------------------------------------------------
AttSongClrCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2FAA, 0x166
; -----------------------------------------------------------------------------
; [naka_s_headers] AttTrkClrCheck_Strings
; AttTrkClrCheck_Strings -- the 5 strings AttTrkClrCheck_PtrTable points
; at (NUL-terminated, 0xff pad to even length), 404 bytes.
;
; Typed in naka_widget_descriptors.c as char
; AttTrkClrCheck_Strings[404].
; -----------------------------------------------------------------------------
AttTrkClrCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3110, 0x194
	.set NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las, AttTrkClrCheck_Strings + 138	; historical label, used by other files
; -----------------------------------------------------------------------------
; [naka_s_headers] StsAtPunchCheck_Strings
; StsAtPunchCheck_Strings -- the 2 strings StsAtPunchCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 102 bytes.
;
; Typed in naka_widget_descriptors.c as char
; StsAtPunchCheck_Strings[102].
; -----------------------------------------------------------------------------
StsAtPunchCheck_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x32A4, 0x66
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaDesc_Str0330A
; NakaDesc_Str0330A -- 6 bytes of NUL-terminated strings after the
; string block before it; no registration or code reference reaches them
; (searched: RegObjTabl tables, slice and positional labels). Which code
; uses them is not established.
;
; Typed in naka_widget_descriptors.c as char NakaDesc_Str0330A[6].
; -----------------------------------------------------------------------------
NakaDesc_Str0330A:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x330A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpTtlFunc_LookupSlide_Strings
; HelpTtlFunc_LookupSlide_Strings -- the 50 strings
; HelpTtlFunc_LookupSlide_PtrTable points at (NUL-terminated, 0xff pad
; to even length), 638 bytes.
;
; Typed in naka_widget_descriptors.c as char
; HelpTtlFunc_LookupSlide_Strings[638].
; -----------------------------------------------------------------------------
HelpTtlFunc_LookupSlide_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3310, 0x27E
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpTtlFunc_LookupSlide_PtrTable
; HelpTtlFunc_LookupSlide_PtrTable -- 50 u32 addresses, read by
; HelpTtlFunc_LookupSlide (v10/v9 0xf2e962, v7 0xf2e938) (`lda xix,
; (NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las_0x3f4:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; HelpTtlFunc_LookupSlide_PtrTable[50].
; -----------------------------------------------------------------------------
HelpTtlFunc_LookupSlide_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x358E, 0xC8
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpTtlFunc_LookupSlide_PtrTable_Strings
; HelpTtlFunc_LookupSlide_PtrTable_Strings -- 30 bytes of NUL-terminated
; strings after HelpTtlFunc_LookupSlide_PtrTable; no registration or
; code reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; HelpTtlFunc_LookupSlide_PtrTable_Strings[30].
; -----------------------------------------------------------------------------
HelpTtlFunc_LookupSlide_PtrTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3656, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] AttAreYouSureCheck_PtrTable
; AttAreYouSureCheck_PtrTable -- 6 u32 addresses, read by
; AttAreYouSureCheck (v10/v9 0xf2ef1d, v7 0xf2eef3) (`lda xhl,
; (NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las_0x4da:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; AttAreYouSureCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AttAreYouSureCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3674, 0x18
	.set ExtDevice_ModeDispatch_Table, AttAreYouSureCheck_PtrTable + 4	; historical label, used by other files
; -----------------------------------------------------------------------------
; [naka_s_headers] AttAttentionCheck_PtrTable
; AttAttentionCheck_PtrTable -- 6 u32 addresses, read by
; AttAttentionCheck (v10/v9 0xf2ef2e, v7 0xf2ef04) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x14:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; AttAttentionCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AttAttentionCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x368C, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsSeqMenu1Check_PtrTable
; StsSeqMenu1Check_PtrTable -- 6 u32 addresses, read by StsSeqMenu1Check
; (v10/v9 0xf2ef3f, v7 0xf2ef15) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x2c:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsSeqMenu1Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsSeqMenu1Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x36A4, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsSeqMenu2Check_PtrTable
; StsSeqMenu2Check_PtrTable -- 6 u32 addresses, read by StsSeqMenu2Check
; (v10/v9 0xf2ef50, v7 0xf2ef26) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x44:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsSeqMenu2Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsSeqMenu2Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x36BC, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsEasyRec1Check_PtrTable
; StsEasyRec1Check_PtrTable -- 6 u32 addresses, read by StsEasyRec1Check
; (v10/v9 0xf2ef61, v7 0xf2ef37) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x5c:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsEasyRec1Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsEasyRec1Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x36D4, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsEasyRec2Check_PtrTable
; StsEasyRec2Check_PtrTable -- 6 u32 addresses, read by StsEasyRec2Check
; (v10/v9 0xf2ef72, v7 0xf2ef48) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x74:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsEasyRec2Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsEasyRec2Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x36EC, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsPnlWrtCheck_PtrTable
; StsPnlWrtCheck_PtrTable -- 6 u32 addresses, read by StsPnlWrtCheck
; (v10/v9 0xf2ef83, v7 0xf2ef59) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x8c:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsPnlWrtCheck_PtrTable[6].
; -----------------------------------------------------------------------------
StsPnlWrtCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3704, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsTrkClr1Check_PtrTable
; StsTrkClr1Check_PtrTable -- 6 u32 addresses, read by StsTrkClr1Check
; (v10/v9 0xf2ef94, v7 0xf2ef6a) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0xa4:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsTrkClr1Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsTrkClr1Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x371C, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsTrkClr2Check_PtrTable
; StsTrkClr2Check_PtrTable -- 6 u32 addresses, read by StsTrkClr2Check
; (v10/v9 0xf2efa5, v7 0xf2ef7b) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0xbc:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsTrkClr2Check_PtrTable[6].
; -----------------------------------------------------------------------------
StsTrkClr2Check_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3734, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsNtDrEditCheck_PtrTable
; StsNtDrEditCheck_PtrTable -- 6 u32 addresses, read by StsNtDrEditCheck
; (v10/v9 0xf2efb6, v7 0xf2ef8c) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0xd4:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsNtDrEditCheck_PtrTable[6].
; -----------------------------------------------------------------------------
StsNtDrEditCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x374C, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] AttTrkClrCheck_PtrTable
; AttTrkClrCheck_PtrTable -- 6 u32 addresses, read by AttTrkClrCheck
; (v10/v9 0xf2efc7, v7 0xf2ef9d) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0xec:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; AttTrkClrCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AttTrkClrCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3764, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] AttSongClrCheck_PtrTable
; AttSongClrCheck_PtrTable -- 6 u32 addresses, read by AttSongClrCheck
; (v10/v9 0xf2efd8, v7 0xf2efae) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x104:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; AttSongClrCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AttSongClrCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x377C, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsAtPunchCheck_PtrTable
; StsAtPunchCheck_PtrTable -- 6 u32 addresses, read by StsAtPunchCheck
; (v10/v9 0xf2efe9, v7 0xf2efbf) (`lda xhl,
; (ExtDevice_ModeDispatch_Table_0x11c:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; StsAtPunchCheck_PtrTable[6].
; -----------------------------------------------------------------------------
StsAtPunchCheck_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3794, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] StsAtPunchCheck_PtrTable_Strings
; StsAtPunchCheck_PtrTable_Strings -- 12 bytes of NUL-terminated strings
; after StsAtPunchCheck_PtrTable; no registration or code reference
; reaches them (searched: RegObjTabl tables, slice and positional
; labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; StsAtPunchCheck_PtrTable_Strings[12].
; -----------------------------------------------------------------------------
StsAtPunchCheck_PtrTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37AC, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Str
; NoteEditBox_EventDispatch2_Str -- NUL-terminated string(s), 8 bytes,
; used by NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x140`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEditBox_EventDispatch2_Str[8].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37B8, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Str_2
; NoteEditBox_EventDispatch2_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x148`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEditBox_EventDispatch2_Str_2[4].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37C0, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_EventDispatch2_Str_3
; NoteEditBox_EventDispatch2_Str_3 -- NUL-terminated string(s), 8 bytes,
; used by NoteEditBox_EventDispatch2 (v10/v9 0xf2f2a0, v7 0xf2f276) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x14c`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEditBox_EventDispatch2_Str_3[8].
; -----------------------------------------------------------------------------
NoteEditBox_EventDispatch2_Str_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37C4, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatEntry_Table
; NoteEdit_FormatEntry_Table -- read by NoteEdit_FormatEntry (v10/v9
; 0xf2fa09, v7 0xf2f9df) (`add xwa,
; ExtDevice_ModeDispatch_Table_0x154`). 12 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; NoteEdit_FormatEntry_Table[12].
; -----------------------------------------------------------------------------
NoteEdit_FormatEntry_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37CC, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatEntry_CaseTable
; NoteEdit_FormatEntry_CaseTable -- jump table of a compiled `switch` in
; NoteEdit_FormatEntry (v10/v9 0xf2fa09, v7 0xf2f9df) (`ld xix,
; ExtDevice_ModeDispatch_Table_0x160`): 2 u16 case offsets from
; NoteEditBox_GridDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEdit_FormatEntry_CaseTable[2].
; -----------------------------------------------------------------------------
NoteEdit_FormatEntry_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37D8, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_GridDispatch2_CaseTable
; NoteEditBox_GridDispatch2_CaseTable -- jump table of a compiled
; `switch` in NoteEditBox_GridDispatch2 (v10/v9 0xf2f251, v7 0xf2f227)
; (`add xwa, ExtDevice_ModeDispatch_Table_0x164`): 12 u16 case offsets
; from NoteEditBox_EventDispatch2.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditBox_GridDispatch2_CaseTable[12].
; -----------------------------------------------------------------------------
NoteEditBox_GridDispatch2_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37DC, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_SetupGrid_CaseTable
; NoteEditBox_SetupGrid_CaseTable -- jump table of a compiled `switch`
; in NoteEditBox_SetupGrid (v10/v9 0xf2f1a2, v7 0xf2f178) (`add xhl,
; ExtDevice_ModeDispatch_Table_0x17c`): 10 u16 case offsets from
; NoteEditBox_EventDispatch1.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditBox_SetupGrid_CaseTable[10].
; -----------------------------------------------------------------------------
NoteEditBox_SetupGrid_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x37F4, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditBox_SetupGrid_CaseTable_Strings
; NoteEditBox_SetupGrid_CaseTable_Strings -- 12 bytes of NUL-terminated
; strings after NoteEditBox_SetupGrid_CaseTable; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; NoteEditBox_SetupGrid_CaseTable_Strings[12].
; -----------------------------------------------------------------------------
NoteEditBox_SetupGrid_CaseTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3808, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatTempoString_Str
; NoteEdit_FormatTempoString_Str -- NUL-terminated string(s), 6 bytes,
; used by NoteEdit_FormatTempoString (v10/v9 0xf2faf2, v7 0xf2fac8) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x19c`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatTempoString_Str[6].
; -----------------------------------------------------------------------------
NoteEdit_FormatTempoString_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3814, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatTempoString_Str_2
; NoteEdit_FormatTempoString_Str_2 -- NUL-terminated string(s), 6 bytes,
; used by NoteEdit_FormatTempoString (v10/v9 0xf2faf2, v7 0xf2fac8) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1a2`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatTempoString_Str_2[6].
; -----------------------------------------------------------------------------
NoteEdit_FormatTempoString_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x381A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatNoteOther_Str
; NoteEdit_FormatNoteOther_Str -- NUL-terminated string(s), 4 bytes,
; used by NoteEdit_FormatNoteOther (v10/v9 0xf2fb54, v7 0xf2fb2a) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1a8`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatNoteOther_Str[4].
; -----------------------------------------------------------------------------
NoteEdit_FormatNoteOther_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3820, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatNoteOther_Str_2
; NoteEdit_FormatNoteOther_Str_2 -- NUL-terminated string(s), 6 bytes,
; used by NoteEdit_FormatNoteOther (v10/v9 0xf2fb54, v7 0xf2fb2a) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1ac`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatNoteOther_Str_2[6].
; -----------------------------------------------------------------------------
NoteEdit_FormatNoteOther_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3824, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatNoteOther_Str_3
; NoteEdit_FormatNoteOther_Str_3 -- NUL-terminated string(s), 6 bytes,
; used by NoteEdit_FormatNoteOther (v10/v9 0xf2fb54, v7 0xf2fb2a) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1b2`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatNoteOther_Str_3[6].
; -----------------------------------------------------------------------------
NoteEdit_FormatNoteOther_Str_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x382A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatNoteOther_Str_4
; NoteEdit_FormatNoteOther_Str_4 -- NUL-terminated string(s), 4 bytes,
; used by NoteEdit_FormatNoteOther (v10/v9 0xf2fb54, v7 0xf2fb2a) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1b8`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatNoteOther_Str_4[4].
; -----------------------------------------------------------------------------
NoteEdit_FormatNoteOther_Str_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3830, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatNoteOther_Str_5
; NoteEdit_FormatNoteOther_Str_5 -- NUL-terminated string(s), 12 bytes,
; used by NoteEdit_FormatNoteOther (v10/v9 0xf2fb54, v7 0xf2fb2a) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1bc`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatNoteOther_Str_5[12].
; -----------------------------------------------------------------------------
NoteEdit_FormatNoteOther_Str_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3834, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime0C_Str
; NoteEdit_GateTime0C_Str -- NUL-terminated string(s), 8 bytes, used by
; NoteEdit_GateTime0C (v10/v9 0xf2fbd9, v7 0xf2fbaf) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1c8`).
;
; Typed in naka_widget_descriptors.c as char NoteEdit_GateTime0C_Str[8].
; -----------------------------------------------------------------------------
NoteEdit_GateTime0C_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3840, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime10_Str
; NoteEdit_GateTime10_Str -- NUL-terminated string(s), 8 bytes, used by
; NoteEdit_GateTime10 (v10/v9 0xf2fbe0, v7 0xf2fbb6) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1d0`).
;
; Typed in naka_widget_descriptors.c as char NoteEdit_GateTime10_Str[8].
; -----------------------------------------------------------------------------
NoteEdit_GateTime10_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3848, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime18_Str
; NoteEdit_GateTime18_Str -- NUL-terminated string(s), 8 bytes, used by
; NoteEdit_GateTime18 (v10/v9 0xf2fbeb, v7 0xf2fbc1) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1d8`).
;
; Typed in naka_widget_descriptors.c as char NoteEdit_GateTime18_Str[8].
; -----------------------------------------------------------------------------
NoteEdit_GateTime18_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3850, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime20_Str
; NoteEdit_GateTime20_Str -- NUL-terminated string(s), 8 bytes, used by
; NoteEdit_GateTime20 (v10/v9 0xf2fbf2, v7 0xf2fbc8) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1e0`).
;
; Typed in naka_widget_descriptors.c as char NoteEdit_GateTime20_Str[8].
; -----------------------------------------------------------------------------
NoteEdit_GateTime20_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3858, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime30_Str
; NoteEdit_GateTime30_Str -- NUL-terminated string(s), 8 bytes, used by
; NoteEdit_GateTime30 (v10/v9 0xf2fbf9, v7 0xf2fbcf) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1e8`).
;
; Typed in naka_widget_descriptors.c as char NoteEdit_GateTime30_Str[8].
; -----------------------------------------------------------------------------
NoteEdit_GateTime30_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3860, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GateTime60_Str
; NoteEdit_GateTime60_Str -- NUL-terminated string(s), 12 bytes, used by
; NoteEdit_GateTime60 (v10/v9 0xf2fc00, v7 0xf2fbd6) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x1f0`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_GateTime60_Str[12].
; -----------------------------------------------------------------------------
NoteEdit_GateTime60_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3868, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_FormatChordType_Str
; NoteEdit_FormatChordType_Str -- NUL-terminated string(s), 4 bytes,
; used by NoteEdit_FormatChordType (v10/v9 0xf2fc1d, v7 0xf2fbf3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x1fc`).
;
; Typed in naka_widget_descriptors.c as char
; NoteEdit_FormatChordType_Str[4].
; -----------------------------------------------------------------------------
NoteEdit_FormatChordType_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3874, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEdit_GetParamValue_CaseTable
; NoteEdit_GetParamValue_CaseTable -- jump table of a compiled `switch`
; in NoteEdit_GetParamValue (v10/v9 0xf2fc64, v7 0xf2fc3a) (`add xde,
; ExtDevice_ModeDispatch_Table_0x200`): 14 u16 case offsets from
; NoteEdit_ParamJumpTable.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEdit_GetParamValue_CaseTable[14].
; -----------------------------------------------------------------------------
NoteEdit_GetParamValue_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3878, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditFunc_CaseTable
; NoteEditFunc_CaseTable -- jump table of a compiled `switch` in
; NoteEditFunc (v10/v9 0xf2fa5a, v7 0xf2fa30) (`add xwa,
; ExtDevice_ModeDispatch_Table_0x21c`): 16 u16 case offsets from
; NoteEdit_FormatTempo.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditFunc_CaseTable[16].
; -----------------------------------------------------------------------------
NoteEditFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3894, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditFunc_CaseTable_Strings
; NoteEditFunc_CaseTable_Strings -- 10 bytes of NUL-terminated strings
; after NoteEditFunc_CaseTable; no registration or code reference
; reaches them (searched: RegObjTabl tables, slice and positional
; labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; NoteEditFunc_CaseTable_Strings[10].
; -----------------------------------------------------------------------------
NoteEditFunc_CaseTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x38B4, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] EntGrid_PostMainEvent_Table
; EntGrid_PostMainEvent_Table -- read by EntGrid_PostMainEvent (v10/v9
; 0xf300ec, v7 0xf300c2) (`lda xbc,
; (ExtDevice_ModeDispatch_Table_0x246:24)`). 18 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EntGrid_PostMainEvent_Table[18].
; -----------------------------------------------------------------------------
EntGrid_PostMainEvent_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x38BE, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] EntGrid_PostMainEvent_Table_2
; EntGrid_PostMainEvent_Table_2 -- read by EntGrid_PostMainEvent (v10/v9
; 0xf300ec, v7 0xf300c2) (`lda xbc,
; (ExtDevice_ModeDispatch_Table_0x258:24)`). 18 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EntGrid_PostMainEvent_Table_2[18].
; -----------------------------------------------------------------------------
EntGrid_PostMainEvent_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x38D0, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] AcEntertainerGridBoxProc_CaseTable
; AcEntertainerGridBoxProc_CaseTable -- jump table of a compiled
; `switch` in AcEntertainerGridBoxProc (v10/v9 0xf30048, v7 0xf3001e)
; (`add xbc, ExtDevice_ModeDispatch_Table_0x26a`): 7 u16 case offsets
; from AcEntertainer_EventDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AcEntertainerGridBoxProc_CaseTable[7].
; -----------------------------------------------------------------------------
AcEntertainerGridBoxProc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x38E2, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_Table
; SndParam_Dispatch_Table -- read by SndParam_Dispatch (v10/v9 0xf303d6,
; v7 0xf303ac) (`lda xbc, (ExtDevice_ModeDispatch_Table_0x278:24)`),
; SndParam_Dispatch (v10/v9 0xf303d6, v7 0xf303ac) (`lda xwa,
; (ExtDevice_ModeDispatch_Table_0x278:24)`), SndParam_Dispatch (v10/v9
; 0xf303d6, v7 0xf303ac) (`lda xix,
; (ExtDevice_ModeDispatch_Table_0x278:24)`), EntGridCheck_Handler
; (v10/v9 0xf305c9, v7 0xf3059f) (`lda xbc,
; (ExtDevice_ModeDispatch_Table_0x278:24)`). 36 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SndParam_Dispatch_Table[36].
; -----------------------------------------------------------------------------
SndParam_Dispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x38F0, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] EntertainerGridCheck_LocalInit
; EntertainerGridCheck_LocalInit -- initializer of a local array:
; EntertainerGridCheck (v10/v9 0xf30326, v7 0xf302fc) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x29c`) copies 10 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EntertainerGridCheck_LocalInit[5].
; -----------------------------------------------------------------------------
EntertainerGridCheck_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3914, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] EntertainerGridCheck_LocalInit_Strings
; EntertainerGridCheck_LocalInit_Strings -- 10 bytes of NUL-terminated
; strings after EntertainerGridCheck_LocalInit; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; EntertainerGridCheck_LocalInit_Strings[10].
; -----------------------------------------------------------------------------
EntertainerGridCheck_LocalInit_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x391E, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_Str
; SndParam_Dispatch_Str -- NUL-terminated string(s), 10 bytes, used by
; SndParam_Dispatch (v10/v9 0xf303d6, v7 0xf303ac) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x2b0`).
;
; Typed in naka_widget_descriptors.c as char SndParam_Dispatch_Str[10].
; -----------------------------------------------------------------------------
SndParam_Dispatch_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3928, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_Str_2
; SndParam_Dispatch_Str_2 -- NUL-terminated string(s), 20 bytes, used by
; SndParam_Dispatch (v10/v9 0xf303d6, v7 0xf303ac) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x2ba`).
;
; Typed in naka_widget_descriptors.c as char
; SndParam_Dispatch_Str_2[20].
; -----------------------------------------------------------------------------
SndParam_Dispatch_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3932, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] EntGridCheck_Handle4140_Str
; EntGridCheck_Handle4140_Str -- NUL-terminated string(s), 10 bytes,
; used by EntGridCheck_Handle4140 (v10/v9 0xf30678, v7 0xf3064e) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x2ce`).
;
; Typed in naka_widget_descriptors.c as char
; EntGridCheck_Handle4140_Str[10].
; -----------------------------------------------------------------------------
EntGridCheck_Handle4140_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3946, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] EntGridCheck_Handle4140_Str_2
; EntGridCheck_Handle4140_Str_2 -- NUL-terminated string(s), 30 bytes,
; used by EntGridCheck_Handle4140 (v10/v9 0xf30678, v7 0xf3064e) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x2d8`).
;
; Typed in naka_widget_descriptors.c as char
; EntGridCheck_Handle4140_Str_2[30].
; -----------------------------------------------------------------------------
EntGridCheck_Handle4140_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3950, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_PtrTable
; SndParam_Dispatch_PtrTable -- 2 u32 ROM addresses (or 0), read by
; SndParam_Dispatch (v10/v9 0xf303d6, v7 0xf303ac) (`lda xix,
; (ExtDevice_ModeDispatch_Table_0x2f6:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; SndParam_Dispatch_PtrTable[2].
; -----------------------------------------------------------------------------
SndParam_Dispatch_PtrTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x396E, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_PtrTable_Strings
; SndParam_Dispatch_PtrTable_Strings -- 10 bytes of NUL-terminated
; strings after SndParam_Dispatch_PtrTable; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; SndParam_Dispatch_PtrTable_Strings[10].
; -----------------------------------------------------------------------------
SndParam_Dispatch_PtrTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3976, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_PtrTable_2
; SndParam_Dispatch_PtrTable_2 -- 2 u32 ROM addresses (or 0), read by
; SndParam_Dispatch (v10/v9 0xf303d6, v7 0xf303ac) (`lda xix,
; (ExtDevice_ModeDispatch_Table_0x308:24)`).
;
; Typed in naka_widget_descriptors.c as uint32_t
; SndParam_Dispatch_PtrTable_2[2].
; -----------------------------------------------------------------------------
SndParam_Dispatch_PtrTable_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3980, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SndParam_Dispatch_PtrTable_2_Strings
; SndParam_Dispatch_PtrTable_2_Strings -- 10 bytes of NUL-terminated
; strings after SndParam_Dispatch_PtrTable_2; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; SndParam_Dispatch_PtrTable_2_Strings[10].
; -----------------------------------------------------------------------------
SndParam_Dispatch_PtrTable_2_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3988, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] EntertainerGridCheck_CaseTable
; EntertainerGridCheck_CaseTable -- jump table of a compiled `switch` in
; EntertainerGridCheck (v10/v9 0xf30326, v7 0xf302fc) (`add xwa,
; ExtDevice_ModeDispatch_Table_0x31a`): 7 u16 case offsets from
; SndParam_Dispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EntertainerGridCheck_CaseTable[7].
; -----------------------------------------------------------------------------
EntertainerGridCheck_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3992, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] EntertainerGridCheck_CaseTable_Strings
; EntertainerGridCheck_CaseTable_Strings -- 12 bytes of NUL-terminated
; strings after EntertainerGridCheck_CaseTable; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; EntertainerGridCheck_CaseTable_Strings[12].
; -----------------------------------------------------------------------------
EntertainerGridCheck_CaseTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x39A0, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyVal_HandleExtraParams_CaseTable
; SqplyVal_HandleExtraParams_CaseTable -- jump table of a compiled
; `switch` in SqplyVal_HandleExtraParams (v10/v9 0xf30cbf, v7 0xf30c95)
; (`add xhl, ExtDevice_ModeDispatch_Table_0x334`): 8 u16 case offsets
; from SqplyVal_ExtraParamsData.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqplyVal_HandleExtraParams_CaseTable[8].
; -----------------------------------------------------------------------------
SqplyVal_HandleExtraParams_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x39AC, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal_ClearDrawBuffer_CaseTable
; SqedtVal_ClearDrawBuffer_CaseTable -- jump table of a compiled
; `switch` in SqedtVal_ClearDrawBuffer (v10/v9 0xf311c6, v7 0xf3119c)
; (`add xwa, ExtDevice_ModeDispatch_Table_0x344`): 15 u16 case offsets
; from SqedtVal_DrawParamsData.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtVal_ClearDrawBuffer_CaseTable[15].
; -----------------------------------------------------------------------------
SqedtVal_ClearDrawBuffer_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x39BC, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal2_UpScrollDefault_Table
; SqedtVal2_UpScrollDefault_Table -- read by SqedtVal2_UpScrollDefault
; (v10/v9 0xf326ae, v7 0xf32684) (`lda xiy,
; (ExtDevice_ModeDispatch_Table_0x362:24)`). 24 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtVal2_UpScrollDefault_Table[24].
; -----------------------------------------------------------------------------
SqedtVal2_UpScrollDefault_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x39DA, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal2_UpScrollModeA2_Table
; SqedtVal2_UpScrollModeA2_Table -- read by SqedtVal2_UpScrollModeA2
; (v10/v9 0xf32688, v7 0xf3265e) (`lda xiy,
; (ExtDevice_ModeDispatch_Table_0x37a:24)`). 16 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtVal2_UpScrollModeA2_Table[16].
; -----------------------------------------------------------------------------
SqedtVal2_UpScrollModeA2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x39F2, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal2_DownScrollDefault_Table
; SqedtVal2_DownScrollDefault_Table -- read by
; SqedtVal2_DownScrollDefault (v10/v9 0xf32716, v7 0xf326ec) (`lda xbc,
; (ExtDevice_ModeDispatch_Table_0x38a:24)`). 24 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtVal2_DownScrollDefault_Table[24].
; -----------------------------------------------------------------------------
SqedtVal2_DownScrollDefault_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A02, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtVal2_DownScrollModeA2_Table
; SqedtVal2_DownScrollModeA2_Table -- read by SqedtVal2_DownScrollModeA2
; (v10/v9 0xf326ef, v7 0xf326c5) (`lda xbc,
; (ExtDevice_ModeDispatch_Table_0x3a2:24)`). 16 bytes to the next
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtVal2_DownScrollModeA2_Table[16].
; -----------------------------------------------------------------------------
SqedtVal2_DownScrollModeA2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A1A, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit
; SqedtFixProc_LocalInit -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3b2`) copies 5 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit[5].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A2A, 0x5
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_Tail
; SqedtFixProc_LocalInit_Tail -- 1 bytes after SqedtFixProc_LocalInit
; that no registration or code reference reaches (searched: RegObjTabl
; tables, slice and positional labels). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A2F, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_2
; SqedtFixProc_LocalInit_2 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3b8`) copies 3 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_2[3].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A30, 0x3
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_2_Tail
; SqedtFixProc_LocalInit_2_Tail -- 1 bytes after
; SqedtFixProc_LocalInit_2 that no registration or code reference
; reaches (searched: RegObjTabl tables, slice and positional labels).
; Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_2_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_2_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A33, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_3
; SqedtFixProc_LocalInit_3 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3bc`) copies 5 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_3[5].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A34, 0x5
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_3_Tail
; SqedtFixProc_LocalInit_3_Tail -- 1 bytes after
; SqedtFixProc_LocalInit_3 that no registration or code reference
; reaches (searched: RegObjTabl tables, slice and positional labels).
; Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_3_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_3_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A39, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_4
; SqedtFixProc_LocalInit_4 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3c2`) copies 6 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFixProc_LocalInit_4[3].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A3A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_5
; SqedtFixProc_LocalInit_5 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3c8`) copies 6 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFixProc_LocalInit_5[3].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A40, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_6
; SqedtFixProc_LocalInit_6 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3ce`) copies 2 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_6[2].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A46, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_7
; SqedtFixProc_LocalInit_7 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3d0`) copies 14 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFixProc_LocalInit_7[7].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A48, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_8
; SqedtFixProc_LocalInit_8 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3de`) copies 13 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_8[13].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_8:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A56, 0xD
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_8_Tail
; SqedtFixProc_LocalInit_8_Tail -- 1 bytes after
; SqedtFixProc_LocalInit_8 that no registration or code reference
; reaches (searched: RegObjTabl tables, slice and positional labels).
; Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_8_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_8_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A63, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_9
; SqedtFixProc_LocalInit_9 -- initializer of a local array: SqedtFixProc
; (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3ec`) copies 14 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFixProc_LocalInit_9[7].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_9:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A64, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_10
; SqedtFixProc_LocalInit_10 -- initializer of a local array:
; SqedtFixProc (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x3fa`) copies 7 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_10[7].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_10:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A72, 0x7
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_10_Tail
; SqedtFixProc_LocalInit_10_Tail -- 1 bytes after
; SqedtFixProc_LocalInit_10 that no registration or code reference
; reaches (searched: RegObjTabl tables, slice and positional labels).
; Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_10_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_10_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A79, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_11
; SqedtFixProc_LocalInit_11 -- initializer of a local array:
; SqedtFixProc (v10/v9 0xf3154f, v7 0xf31525) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x402`) copies 5 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_11[5].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_11:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A7A, 0x5
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFixProc_LocalInit_11_Tail
; SqedtFixProc_LocalInit_11_Tail -- 1 bytes after
; SqedtFixProc_LocalInit_11 that no registration or code reference
; reaches (searched: RegObjTabl tables, slice and positional labels).
; Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SqedtFixProc_LocalInit_11_Tail[1].
; -----------------------------------------------------------------------------
SqedtFixProc_LocalInit_11_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A7F, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyVal_ExtraParams_CaseTable
; SqplyVal_ExtraParams_CaseTable -- jump table of a compiled `switch` in
; SqplyVal_ExtraParams (v10/v9 0xf3240a, v7 0xf323e0) (`add xhl,
; ExtDevice_ModeDispatch_Table_0x408`): 16 u16 case offsets from
; AccIll_Dispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqplyVal_ExtraParams_CaseTable[16].
; -----------------------------------------------------------------------------
SqplyVal_ExtraParams_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3A80, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBoxProc_LocalInit
; EffectBoxProc_LocalInit -- initializer of a local array: EffectBoxProc
; (v10/v9 0xf3344e, v7 0xf33424) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x428`) copies 4 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EffectBoxProc_LocalInit[2].
; -----------------------------------------------------------------------------
EffectBoxProc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AA0, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBoxProc_LocalInit_2
; EffectBoxProc_LocalInit_2 -- initializer of a local array:
; EffectBoxProc (v10/v9 0xf3344e, v7 0xf33424) (`ld xiy,
; ExtDevice_ModeDispatch_Table_0x42c`) copies 4 bytes into its stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EffectBoxProc_LocalInit_2[2].
; -----------------------------------------------------------------------------
EffectBoxProc_LocalInit_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AA4, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBox_NameSetup_CaseTable
; EffectBox_NameSetup_CaseTable -- jump table of a compiled `switch` in
; EffectBox_NameSetup (v10/v9 0xf33a51, v7 0xf33a27) (`add xhl,
; ExtDevice_ModeDispatch_Table_0x430`): 7 u16 case offsets from
; EffectBox_Dispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EffectBox_NameSetup_CaseTable[7].
; -----------------------------------------------------------------------------
EffectBox_NameSetup_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AA8, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_HandleSelectEvent_Table
; Equalizer_HandleSelectEvent_Table -- read by
; Equalizer_HandleSelectEvent (v10/v9 0xf34061, v7 0xf34037) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x43e`). 16 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Equalizer_HandleSelectEvent_Table[16].
; -----------------------------------------------------------------------------
Equalizer_HandleSelectEvent_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AB6, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_HandleSelectEvent_Table_2
; Equalizer_HandleSelectEvent_Table_2 -- read by
; Equalizer_HandleSelectEvent (v10/v9 0xf34061, v7 0xf34037) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x44e`). 16 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Equalizer_HandleSelectEvent_Table_2[16].
; -----------------------------------------------------------------------------
Equalizer_HandleSelectEvent_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AC6, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBox_StateDispatch_CaseTable
; EffectBox_StateDispatch_CaseTable -- jump table of a compiled `switch`
; in EffectBox_StateDispatch (v10/v9 0xf340f2, v7 0xf340c8) (`add xbc,
; ExtDevice_ModeDispatch_Table_0x45e`): 7 u16 case offsets from
; SeqAccomp_Dispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EffectBox_StateDispatch_CaseTable[7].
; -----------------------------------------------------------------------------
EffectBox_StateDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AD6, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] EffectBox_StateDispatch_CaseTable_Tail
; EffectBox_StateDispatch_CaseTable_Tail -- 90 bytes after
; EffectBox_StateDispatch_CaseTable that no registration or code
; reference reaches (searched: RegObjTabl tables, slice and positional
; labels). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffectBox_StateDispatch_CaseTable_Tail[90].
; -----------------------------------------------------------------------------
EffectBox_StateDispatch_CaseTable_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3AE4, 0x5A
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Table
; Sqedt_ParamDispatch_Table -- read by Sqedt_ParamDispatch (v10/v9
; 0xf34a5c, v7 0xf34a32) (`ld xbc, ExtDevice_ModeDispatch_Table_0x4c6`).
; 54 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Sqedt_ParamDispatch_Table[54].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3B3E, 0x36
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Table_2
; Sqedt_ParamDispatch_Table_2 -- read by Sqedt_ParamDispatch (v10/v9
; 0xf34a5c, v7 0xf34a32) (`ld xbc, ExtDevice_ModeDispatch_Table_0x4fc`).
; 66 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Sqedt_ParamDispatch_Table_2[66].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3B74, 0x42
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Table_3
; Sqedt_ParamDispatch_Table_3 -- read by Sqedt_ParamDispatch (v10/v9
; 0xf34a5c, v7 0xf34a32) (`ld xbc, ExtDevice_ModeDispatch_Table_0x53e`).
; 28 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Sqedt_ParamDispatch_Table_3[28].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Table_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3BB6, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Table_4
; Sqedt_ParamDispatch_Table_4 -- read by Sqedt_ParamDispatch (v10/v9
; 0xf34a5c, v7 0xf34a32) (`ld xbc, ExtDevice_ModeDispatch_Table_0x55a`).
; 106 bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Sqedt_ParamDispatch_Table_4[106].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Table_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3BD2, 0x6A
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str
; SqplyFunc_ParamFormatData_Str -- NUL-terminated string(s), 4 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5c4`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str[4].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C3C, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_2
; SqplyFunc_ParamFormatData_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5c8`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_2[4].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C40, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_3
; SqplyFunc_ParamFormatData_Str_3 -- NUL-terminated string(s), 4 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5cc`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_3[4].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C44, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_4
; SqplyFunc_ParamFormatData_Str_4 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5d0`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_4[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C48, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_5
; SqplyFunc_ParamFormatData_Str_5 -- NUL-terminated string(s), 4 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5d6`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_5[4].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C4E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_6
; SqplyFunc_ParamFormatData_Str_6 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5da`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_6[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C52, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_7
; SqplyFunc_ParamFormatData_Str_7 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5e0`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_7[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C58, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_8
; SqplyFunc_ParamFormatData_Str_8 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5e6`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_8[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_8:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C5E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_9
; SqplyFunc_ParamFormatData_Str_9 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5ec`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_9[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_9:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C64, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_10
; SqplyFunc_ParamFormatData_Str_10 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5f2`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_10[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_10:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C6A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_11
; SqplyFunc_ParamFormatData_Str_11 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5f8`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_11[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_11:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C70, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_12
; SqplyFunc_ParamFormatData_Str_12 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x5fe`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_12[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_12:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C76, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_13
; SqplyFunc_ParamFormatData_Str_13 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x604`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_13[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_13:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C7C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_14
; SqplyFunc_ParamFormatData_Str_14 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x60a`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_14[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_14:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C82, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_ParamFormatData_Str_15
; SqplyFunc_ParamFormatData_Str_15 -- NUL-terminated string(s), 6 bytes,
; used by SqplyFunc_ParamFormatData (v10/v9 0xf346ed, v7 0xf346c3) (`ld
; xwa, ExtDevice_ModeDispatch_Table_0x610`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_ParamFormatData_Str_15[6].
; -----------------------------------------------------------------------------
SqplyFunc_ParamFormatData_Str_15:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C88, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_FormatRhythmPattern_Str
; SqplyFunc_FormatRhythmPattern_Str -- NUL-terminated string(s), 6
; bytes, used by SqplyFunc_FormatRhythmPattern (v10/v9 0xf34801, v7
; 0xf347d7) (`ld xwa, ExtDevice_ModeDispatch_Table_0x616`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_FormatRhythmPattern_Str[6].
; -----------------------------------------------------------------------------
SqplyFunc_FormatRhythmPattern_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C8E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_FormatRhythmPattern_Str_2
; SqplyFunc_FormatRhythmPattern_Str_2 -- NUL-terminated string(s), 12
; bytes, used by SqplyFunc_FormatRhythmPattern (v10/v9 0xf34801, v7
; 0xf347d7) (`ld xwa, ExtDevice_ModeDispatch_Table_0x61c`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_FormatRhythmPattern_Str_2[12].
; -----------------------------------------------------------------------------
SqplyFunc_FormatRhythmPattern_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3C94, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_FormatIntro_Str
; SqplyFunc_FormatIntro_Str -- NUL-terminated string(s), 6 bytes, used
; by SqplyFunc_FormatIntro (v10/v9 0xf3483a, v7 0xf34810) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x628`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_FormatIntro_Str[6].
; -----------------------------------------------------------------------------
SqplyFunc_FormatIntro_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CA0, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_FormatEnding_Str
; SqplyFunc_FormatEnding_Str -- NUL-terminated string(s), 6 bytes, used
; by SqplyFunc_FormatEnding (v10/v9 0xf3484a, v7 0xf34820) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x62e`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_FormatEnding_Str[6].
; -----------------------------------------------------------------------------
SqplyFunc_FormatEnding_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CA6, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_FormatFillIn_Str
; SqplyFunc_FormatFillIn_Str -- NUL-terminated string(s), 6 bytes, used
; by SqplyFunc_FormatFillIn (v10/v9 0xf34864, v7 0xf3483a) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x634`).
;
; Typed in naka_widget_descriptors.c as char
; SqplyFunc_FormatFillIn_Str[6].
; -----------------------------------------------------------------------------
SqplyFunc_FormatFillIn_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CAC, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_HandlePartQuery_CaseTable
; SqplyFunc_HandlePartQuery_CaseTable -- jump table of a compiled
; `switch` in SqplyFunc_HandlePartQuery (v10/v9 0xf3498e, v7 0xf34964)
; (`lda xix, (ExtDevice_ModeDispatch_Table_0x63a:24)`): 8 u16 case
; offsets from SqplyFunc_PartQueryDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqplyFunc_HandlePartQuery_CaseTable[8].
; -----------------------------------------------------------------------------
SqplyFunc_HandlePartQuery_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CB2, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_HandleGetValue_CaseTable
; SqplyFunc_HandleGetValue_CaseTable -- jump table of a compiled
; `switch` in SqplyFunc_HandleGetValue (v10/v9 0xf34887, v7 0xf3485d)
; (`add xwa, ExtDevice_ModeDispatch_Table_0x64a`): 11 u16 case offsets
; from SqplyFunc_GetValueDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqplyFunc_HandleGetValue_CaseTable[11].
; -----------------------------------------------------------------------------
SqplyFunc_HandleGetValue_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CC2, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] SqplyFunc_CaseTable
; SqplyFunc_CaseTable -- jump table of a compiled `switch` in SqplyFunc
; (v10/v9 0xf34655, v7 0xf3462b) (`add xhl,
; ExtDevice_ModeDispatch_Table_0x660`): 10 u16 case offsets from
; SqplyFunc_ParamFormatData.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqplyFunc_CaseTable[10].
; -----------------------------------------------------------------------------
SqplyFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CD8, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str
; Sqedt_ParamDispatch_Str -- NUL-terminated string(s), 6 bytes, used by
; Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x674`).
;
; Typed in naka_widget_descriptors.c as char Sqedt_ParamDispatch_Str[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CEC, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_2
; Sqedt_ParamDispatch_Str_2 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x67a`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_2[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CF2, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_3
; Sqedt_ParamDispatch_Str_3 -- NUL-terminated string(s), 18 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x680`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_3[18].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3CF8, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_4
; Sqedt_ParamDispatch_Str_4 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x692`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_4[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D0A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_5
; Sqedt_ParamDispatch_Str_5 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x698`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_5[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D10, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_6
; Sqedt_ParamDispatch_Str_6 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x69e`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_6[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D16, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_7
; Sqedt_ParamDispatch_Str_7 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x6a4`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_7[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D1C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_8
; Sqedt_ParamDispatch_Str_8 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; ExtDevice_ModeDispatch_Table_0x6aa`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_8[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_8:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D22, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaInst_3d
; NakaInst_3d -- NUL-terminated string(s), 6 bytes, used by
; Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`.long
; NakaInst_3d`).
;
; Typed in naka_widget_descriptors.c as char NakaInst_3d[6].
; -----------------------------------------------------------------------------
NakaInst_3d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D28, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_9
; Sqedt_ParamDispatch_Str_9 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x6`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_9[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_9:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D2E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_10
; Sqedt_ParamDispatch_Str_10 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xc`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_10[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_10:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D34, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_11
; Sqedt_ParamDispatch_Str_11 -- NUL-terminated string(s), 44 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x12`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_11[44].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_11:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D3A, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_12
; Sqedt_ParamDispatch_Str_12 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x3e`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_12[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_12:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D66, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_13
; Sqedt_ParamDispatch_Str_13 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x44`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_13[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_13:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D6C, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_14
; Sqedt_ParamDispatch_Str_14 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x4c`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_14[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_14:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D74, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_15
; Sqedt_ParamDispatch_Str_15 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x54`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_15[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_15:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D7C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_16
; Sqedt_ParamDispatch_Str_16 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x5a`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_16[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_16:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D82, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_17
; Sqedt_ParamDispatch_Str_17 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x60`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_17[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_17:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D88, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_18
; Sqedt_ParamDispatch_Str_18 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x68`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_18[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_18:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D90, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_19
; Sqedt_ParamDispatch_Str_19 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x70`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_19[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_19:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D98, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_20
; Sqedt_ParamDispatch_Str_20 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x76`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_20[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_20:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D9E, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_21
; Sqedt_ParamDispatch_Str_21 -- NUL-terminated string(s), 8 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x7e`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_21[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_21:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DA6, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_22
; Sqedt_ParamDispatch_Str_22 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x86`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_22[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_22:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DAE, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_23
; Sqedt_ParamDispatch_Str_23 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x8c`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_23[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_23:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DB4, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_24
; Sqedt_ParamDispatch_Str_24 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x92`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_24[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_24:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DBA, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_25
; Sqedt_ParamDispatch_Str_25 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x98`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_25[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_25:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DC0, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_26
; Sqedt_ParamDispatch_Str_26 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0x9e`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_26[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_26:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DC6, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_27
; Sqedt_ParamDispatch_Str_27 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xa4`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_27[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_27:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DCC, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_28
; Sqedt_ParamDispatch_Str_28 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xaa`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_28[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_28:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DD2, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_29
; Sqedt_ParamDispatch_Str_29 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xb0`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_29[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_29:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DD8, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_30
; Sqedt_ParamDispatch_Str_30 -- NUL-terminated string(s), 12 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xb6`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_30[12].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_30:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DDE, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_31
; Sqedt_ParamDispatch_Str_31 -- NUL-terminated string(s), 6 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_3d_0xc2`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_31[6].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_31:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DEA, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaInst_2d
; NakaInst_2d -- NUL-terminated string(s), 6 bytes, used by
; Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`.long
; NakaInst_2d`).
;
; Typed in naka_widget_descriptors.c as char NakaInst_2d[6].
; -----------------------------------------------------------------------------
NakaInst_2d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DF0, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_32
; Sqedt_ParamDispatch_Str_32 -- NUL-terminated string(s), 12 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_2d_0x6`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_32[12].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_32:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DF6, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_33
; Sqedt_ParamDispatch_Str_33 -- NUL-terminated string(s), 10 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_2d_0x12`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_33[10].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_33:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E02, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_Str_34
; Sqedt_ParamDispatch_Str_34 -- NUL-terminated string(s), 4 bytes, used
; by Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`ld xwa,
; NakaInst_2d_0x1c`).
;
; Typed in naka_widget_descriptors.c as char
; Sqedt_ParamDispatch_Str_34[4].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_Str_34:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E0C, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqFormat_DispatchA_CaseTable
; SeqFormat_DispatchA_CaseTable -- jump table of a compiled `switch` in
; SeqFormat_DispatchA (v10/v9 0xf3513d, v7 0xf35113) (`lda xix,
; (NakaInst_2d_0x20:24)`): 16 u16 case offsets from
; SeqFormat_DispatchA_0x70.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqFormat_DispatchA_CaseTable[16].
; -----------------------------------------------------------------------------
SeqFormat_DispatchA_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E10, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFunc_SignExtend_CaseTable
; SqedtFunc_SignExtend_CaseTable -- jump table of a compiled `switch` in
; SqedtFunc_SignExtend (v10/v9 0xf35115, v7 0xf350eb) (`lda xix,
; (NakaInst_2d_0x40:24)`): 15 u16 case offsets from SeqFormat_DispatchA.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFunc_SignExtend_CaseTable[15].
; -----------------------------------------------------------------------------
SqedtFunc_SignExtend_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E30, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ValueDispatch_CaseTable
; Sqedt_ValueDispatch_CaseTable -- jump table of a compiled `switch` in
; Sqedt_ValueDispatch (v10/v9 0xf3502c, v7 0xf35002) (`lda xix,
; (NakaInst_2d_0x5e:24)`): 9 u16 case offsets from
; Sqedt_ValueDispatch_0x82.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ValueDispatch_CaseTable[9].
; -----------------------------------------------------------------------------
Sqedt_ValueDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E4E, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ValueDispatch_CaseTable_2
; Sqedt_ValueDispatch_CaseTable_2 -- jump table of a compiled `switch`
; in Sqedt_ValueDispatch (v10/v9 0xf3502c, v7 0xf35002) (`lda xix,
; (NakaInst_2d_0x70:24)`): 8 u16 case offsets from
; Sqedt_ValueDispatch_0x58.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ValueDispatch_CaseTable_2[8].
; -----------------------------------------------------------------------------
Sqedt_ValueDispatch_CaseTable_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E60, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ValueDispatch_CaseTable_3
; Sqedt_ValueDispatch_CaseTable_3 -- jump table of a compiled `switch`
; in Sqedt_ValueDispatch (v10/v9 0xf3502c, v7 0xf35002) (`lda xix,
; (NakaInst_2d_0x80:24)`): 9 u16 case offsets from
; Sqedt_ValueDispatch_0x28.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ValueDispatch_CaseTable_3[9].
; -----------------------------------------------------------------------------
Sqedt_ValueDispatch_CaseTable_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E70, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqFunc_ReturnZeroJmp_CaseTable
; SeqFunc_ReturnZeroJmp_CaseTable -- jump table of a compiled `switch`
; in SeqFunc_ReturnZeroJmp (v10/v9 0xf35005, v7 0xf34fdb) (`lda xix,
; (NakaInst_2d_0x92:24)`): 7 u16 case offsets from Sqedt_ValueDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqFunc_ReturnZeroJmp_CaseTable[7].
; -----------------------------------------------------------------------------
SeqFunc_ReturnZeroJmp_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E82, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_CaseTable
; Sqedt_ParamDispatch_CaseTable -- jump table of a compiled `switch` in
; Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`lda xix,
; (NakaInst_2d_0xa0:24)`): 8 u16 case offsets from 15944534.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ParamDispatch_CaseTable[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3E90, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_CaseTable_2
; Sqedt_ParamDispatch_CaseTable_2 -- jump table of a compiled `switch`
; in Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`lda xix,
; (NakaInst_2d_0xb0:24)`): 8 u16 case offsets from 15944414.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ParamDispatch_CaseTable_2[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_CaseTable_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3EA0, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Sqedt_ParamDispatch_CaseTable_3
; Sqedt_ParamDispatch_CaseTable_3 -- jump table of a compiled `switch`
; in Sqedt_ParamDispatch (v10/v9 0xf34a5c, v7 0xf34a32) (`lda xix,
; (NakaInst_2d_0xc0:24)`): 8 u16 case offsets from 15944329.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Sqedt_ParamDispatch_CaseTable_3[8].
; -----------------------------------------------------------------------------
Sqedt_ParamDispatch_CaseTable_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3EB0, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFunc_CaseTable
; SqedtFunc_CaseTable -- jump table of a compiled `switch` in SqedtFunc
; (v10/v9 0xf349d3, v7 0xf349a9) (`add xde, NakaInst_2d_0xd0`): 40 u16
; case offsets from Sqedt_ParamDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFunc_CaseTable[40].
; -----------------------------------------------------------------------------
SqedtFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3EC0, 0x50
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFunc_StateChainB_CaseTable
; SqedtFunc_StateChainB_CaseTable -- jump table of a compiled `switch`
; in SqedtFunc_StateChainB (v10/v9 0xf3523e, v7 0xf35214) (`lda xix,
; (NakaInst_2d_0x120:24)`): 14 u16 case offsets from
; SeqFormat_DispatchB.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SqedtFunc_StateChainB_CaseTable[14].
; -----------------------------------------------------------------------------
SqedtFunc_StateChainB_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F10, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] SqedtFunc_StateChainB_CaseTable_Strings
; SqedtFunc_StateChainB_CaseTable_Strings -- 6 bytes of NUL-terminated
; strings after SqedtFunc_StateChainB_CaseTable; no registration or code
; reference reaches them (searched: RegObjTabl tables, slice and
; positional labels). Which code uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; SqedtFunc_StateChainB_CaseTable_Strings[6].
; -----------------------------------------------------------------------------
SqedtFunc_StateChainB_CaseTable_Strings:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F2C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] DspItem0_TypeChangeHandler_CaseTable
; DspItem0_TypeChangeHandler_CaseTable -- jump table of a compiled
; `switch` in DspItem0_TypeChangeHandler (v10/v9 0xf3572b, v7 0xf35701)
; (`add xde, NakaInst_2d_0x142`): 9 u16 case offsets from
; DspItem0_TypeDispatch.
;
; Typed in naka_widget_descriptors.c as uint16_t
; DspItem0_TypeChangeHandler_CaseTable[9].
; -----------------------------------------------------------------------------
DspItem0_TypeChangeHandler_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F32, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] DspItem0CngFunc_CaseTable
; DspItem0CngFunc_CaseTable -- jump table of a compiled `switch` in
; DspItem0CngFunc (v10/v9 0xf35527, v7 0xf354fd) (`add xiy,
; NakaInst_2d_0x154`): 17 u16 case offsets from
; DspItem0_DisplayEffectName.
;
; Typed in naka_widget_descriptors.c as uint16_t
; DspItem0CngFunc_CaseTable[17].
; -----------------------------------------------------------------------------
DspItem0CngFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F44, 0x22
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_ParamByIndex_Table
; Equalizer_ParamByIndex_Table -- read by Equalizer_ParamByIndex (v10/v9
; 0xf35914, v7 0xf358ea) (`add xde, NakaInst_2d_0x176`). 8 bytes to the
; next object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Equalizer_ParamByIndex_Table[8].
; -----------------------------------------------------------------------------
Equalizer_ParamByIndex_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F66, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_DispatchA_CaseTable
; Equalizer_DispatchA_CaseTable -- jump table of a compiled `switch` in
; Equalizer_DispatchA (v10/v9 0xf35858, v7 0xf3582e) (`add xwa,
; NakaInst_2d_0x17e`): 7 u16 case offsets from Equalizer_DispatchB.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Equalizer_DispatchA_CaseTable[7].
; -----------------------------------------------------------------------------
Equalizer_DispatchA_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F6E, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] EqualizerCngFunc_CaseTable
; EqualizerCngFunc_CaseTable -- jump table of a compiled `switch` in
; EqualizerCngFunc (v10/v9 0xf3580d, v7 0xf357e3) (`add xwa,
; NakaInst_2d_0x18c`): 9 u16 case offsets from Equalizer_DispatchA.
;
; Typed in naka_widget_descriptors.c as uint16_t
; EqualizerCngFunc_CaseTable[9].
; -----------------------------------------------------------------------------
EqualizerCngFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F7C, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_CmdDispatch_CaseTable
; Equalizer_CmdDispatch_CaseTable -- jump table of a compiled `switch`
; in Equalizer_CmdDispatch (v10/v9 0xf359fc, v7 0xf359d2) (`add xwa,
; NakaInst_2d_0x19e`): 15 u16 case offsets from Equalizer_CmdCase0.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Equalizer_CmdDispatch_CaseTable[15].
; -----------------------------------------------------------------------------
Equalizer_CmdDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3F8E, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_FormatDefault_Str
; Equalizer_FormatDefault_Str -- NUL-terminated string(s), 6 bytes, used
; by Equalizer_FormatDefault (v10/v9 0xf35bc7, v7 0xf35b9d) (`ld xwa,
; NakaInst_2d_0x1bc`).
;
; Typed in naka_widget_descriptors.c as char
; Equalizer_FormatDefault_Str[6].
; -----------------------------------------------------------------------------
Equalizer_FormatDefault_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FAC, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] EqFormat_NegativeValue_Str
; EqFormat_NegativeValue_Str -- NUL-terminated string(s), 6 bytes, used
; by EqFormat_NegativeValue (v10/v9 0xf35c2d, v7 0xf35c03) (`ld xwa,
; NakaInst_2d_0x1c2`).
;
; Typed in naka_widget_descriptors.c as char
; EqFormat_NegativeValue_Str[6].
; -----------------------------------------------------------------------------
EqFormat_NegativeValue_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FB2, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] EqFormat_PositiveValue_Str
; EqFormat_PositiveValue_Str -- NUL-terminated string(s), 12 bytes, used
; by EqFormat_PositiveValue (v10/v9 0xf35c39, v7 0xf35c0f) (`ld xwa,
; NakaInst_2d_0x1c8`).
;
; Typed in naka_widget_descriptors.c as char
; EqFormat_PositiveValue_Str[12].
; -----------------------------------------------------------------------------
EqFormat_PositiveValue_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FB8, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] PrepareAudioParam_Str
; PrepareAudioParam_Str -- NUL-terminated string(s), 4 bytes, used by
; PrepareAudioParam (v10/v9 0xf35c7e, v7 0xf35c54) (`ld xwa,
; NakaInst_2d_0x1d4`).
;
; Typed in naka_widget_descriptors.c as char PrepareAudioParam_Str[4].
; -----------------------------------------------------------------------------
PrepareAudioParam_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FC4, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_FormatDispatch_Table
; Equalizer_FormatDispatch_Table -- read by Equalizer_FormatDispatch
; (v10/v9 0xf35b62, v7 0xf35b38) (`lda xix, (NakaInst_2d_0x1d8:24)`). 44
; bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Equalizer_FormatDispatch_Table[44].
; -----------------------------------------------------------------------------
Equalizer_FormatDispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FC8, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] Equalizer_FormatDispatch_CaseTable
; Equalizer_FormatDispatch_CaseTable -- jump table of a compiled
; `switch` in Equalizer_FormatDispatch (v10/v9 0xf35b62, v7 0xf35b38)
; (`ld xix, NakaInst_2d_0x204`): 18 u16 case offsets from
; EqFormat_DispatchTable.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Equalizer_FormatDispatch_CaseTable[18].
; -----------------------------------------------------------------------------
Equalizer_FormatDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3FF4, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] Bitmap_Ntedt0k
; Bitmap_Ntedt0k  --  16 x 127 bitmap, 8 bpp, row stride 16, 2032 bytes
;
; What it shows (render): A vertical piano-key strip (black keys
; pointing left): the key column beside the note grid Bitmap_Ntedt0d.
; Both procs sit in sequencer/sequencer_ui.s just before
; bmdredit_routines.s.
;
; Reader: BitmapNtedt0k (v10/v9 0xf35d62, v7 0xf35d38) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x10 (width 16) and 0x1e000a3 with
; 0x7f (height 127). Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) and hands the three to DrawBitmapSPFast
; (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/naka_c_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_widget_descriptors.c as uint8_t Bitmap_Ntedt0k[127][16]
; (rows of 16 bytes).
; -----------------------------------------------------------------------------
Bitmap_Ntedt0k:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x4018, 0x7F0
; -----------------------------------------------------------------------------
; [naka_s_headers] Bitmap_Ntedt0d
; Bitmap_Ntedt0d  --  240 x 127 bitmap, 8 bpp, row stride 240, 30480 bytes
;
; What it shows (render): An empty dotted grid, 10 columns: the
; background the note grid is drawn on, beside the key strip
; Bitmap_Ntedt0k.
;
; Reader: BitmapNtedt0d (v10/v9 0xf35d8f, v7 0xf35d65) answers 0x1e000a1
; with this address, 0x1e000a2 with 0xf0 (width 240) and 0x1e000a3 with
; 0x7f (height 127). Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) and hands the three to DrawBitmapSPFast
; (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/naka_c_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_widget_descriptors.c as uint8_t Bitmap_Ntedt0d[127][240]
; (rows of 240 bytes).
; -----------------------------------------------------------------------------
Bitmap_Ntedt0d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x4808, 0x7710
; -----------------------------------------------------------------------------
; [naka_s_headers] Bitmap_Dredt0k
; Bitmap_Dredt0k  --  88 x 119 bitmap, 8 bpp, row stride 88, 10472 bytes
;
; What it shows (render): A ruled column (horizontal rules, right-hand
; border): the row-name column beside the dotted grid Bitmap_Dredt0d.
;
; Reader: BitmapDredt0k (v10/v9 0xf35dbc, v7 0xf35d92) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x58 (width 88) and 0x1e000a3 with
; 0x77 (height 119). Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) and hands the three to DrawBitmapSPFast
; (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/naka_c_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_widget_descriptors.c as uint8_t Bitmap_Dredt0k[119][88]
; (rows of 88 bytes).
; -----------------------------------------------------------------------------
Bitmap_Dredt0k:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0xBF18, 0x28E8
; -----------------------------------------------------------------------------
; [naka_s_headers] Bitmap_Dredt0d
; Bitmap_Dredt0d  --  168 x 119 bitmap, 8 bpp, row stride 168, 19992 bytes
;
; What it shows (render): An empty dotted grid, 7 columns, beside the
; ruled name column Bitmap_Dredt0k. Its procs sit in
; sequencer/sequencer_ui.s directly before `.include
; "sequencer/bmdredit_routines.s"`.
;
; Reader: BitmapDredt0d (v10/v9 0xf35de9, v7 0xf35dbf) answers 0x1e000a1
; with this address, 0x1e000a2 with 0xa8 (width 168) and 0x1e000a3 with
; 0x77 (height 119). Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) and hands the three to DrawBitmapSPFast
; (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/naka_c_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_widget_descriptors.c as uint8_t Bitmap_Dredt0d[119][168]
; (rows of 168 bytes).
; -----------------------------------------------------------------------------
Bitmap_Dredt0d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0xE800, 0x4E18
; -----------------------------------------------------------------------------
; [naka_s_headers] WidgetData_DrawbarPositionTable
; WidgetData_DrawbarPositionTable -- Historical name, kept for
; positional_labels.s and the other files that use it; the object here
; is a read by BmDrEdit_SetupScrollRegion_MelodicMode (v10/v9 0xf36f0a,
; v7 0xf36ee0) (`lda xhl, (WidgetData_DrawbarPositionTable:24)`). 106
; bytes to the next referenced object; the layout beyond that access is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; WidgetData_DrawbarPositionTable[106].
; -----------------------------------------------------------------------------
WidgetData_DrawbarPositionTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13618, 0x6A
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPlay_SaveAndPrepareState_Table
; SeqPlay_SaveAndPrepareState_Table -- read by
; SeqPlay_SaveAndPrepareState (v10/v9 0xf39f39, v7 0xf39efe) (`lda xbc,
; (WidgetData_DrawbarPositionTable_0x6a:24)`),
; SeqPlay_SaveState_SetPlayFlags (v10/v9 0xf39fb7, v7 0xf39f7c) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x6a:24)`). 24 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPlay_SaveAndPrepareState_Table[24].
; -----------------------------------------------------------------------------
SeqPlay_SaveAndPrepareState_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13682, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPlay_SaveState_ChordShiftDone_Table
; SeqPlay_SaveState_ChordShiftDone_Table -- read by
; SeqPlay_SaveState_ChordShiftDone (v10/v9 0xf3a022, v7 0xf39fe7) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x82:24)`),
; SeqPlay_SaveState_BassShiftDone (v10/v9 0xf3a066, v7 0xf3a02b) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x82:24)`). 4 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPlay_SaveState_ChordShiftDone_Table[4].
; -----------------------------------------------------------------------------
SeqPlay_SaveState_ChordShiftDone_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1369A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqNote_ProcessCurrent_DrumCheck_Table
; SeqNote_ProcessCurrent_DrumCheck_Table -- read by
; SeqNote_ProcessCurrent_DrumCheck (v10/v9 0xf3aaf3, v7 0xf3aab8) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x86:24)`),
; VoiceConfig_SlotCheck_GetChannel (v10/v9 0xf3ab7b, v7 0xf3ab40) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x86:24)`),
; VoiceConfig_EventType_GetChannel (v10/v9 0xf3abe6, v7 0xf3abab) (`lda
; xhl, (WidgetData_DrawbarPositionTable_0x86:24)`). 32 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqNote_ProcessCurrent_DrumCheck_Table[32].
; -----------------------------------------------------------------------------
SeqNote_ProcessCurrent_DrumCheck_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1369E, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPlay_AssignChordVoices_LocalInit
; SeqPlay_AssignChordVoices_LocalInit -- initializer of a local array:
; SeqPlay_AssignChordVoices (v10/v9 0xf3c66a, v7 0xf3c62f) (`ld xiy,
; WidgetData_DrawbarPositionTable_0xa6`); `lda xix, (xsp + 2); ld bc,
; 4:i3; ldirw` copies 8 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqPlay_AssignChordVoices_LocalInit[4].
; -----------------------------------------------------------------------------
SeqPlay_AssignChordVoices_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x136BE, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPlay_AssignChordVoices_LocalInit_Tail
; SeqPlay_AssignChordVoices_LocalInit_Tail -- 16 bytes after
; SeqPlay_AssignChordVoices_LocalInit that no code reference reaches
; (searched: every label and positional-label name anchored on the
; historical labels of this span, in all v10 .s files). Contents not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPlay_AssignChordVoices_LocalInit_Tail[16].
; -----------------------------------------------------------------------------
SeqPlay_AssignChordVoices_LocalInit_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x136C6, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] PartDetect_LookupAndApply_Table
; PartDetect_LookupAndApply_Table -- read by PartDetect_LookupAndApply
; (v10/v9 0xf3e098, v7 0xf3e07c) (`lda xbc,
; (WidgetData_DrawbarPositionTable_0xbe:24)`),
; Part_SendVoiceOffAndCCEvents (v10/v9 0xf3ebc3, v7 0xf3eba7) (`lda xbc,
; (WidgetData_DrawbarPositionTable_0xbe:24)`),
; SeqVoiceSingle_LookupAndApply (v10/v9 0xf3ec8f, v7 0xf3ec73) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0xbe:24)`). 20 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; PartDetect_LookupAndApply_Table[20].
; -----------------------------------------------------------------------------
PartDetect_LookupAndApply_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x136D6, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] PartSubBlkA_WriteLoop32_Table
; PartSubBlkA_WriteLoop32_Table -- read by PartSubBlkA_WriteLoop32
; (v10/v9 0xf418fd, v7 0xf418ef) (`lda xhl,
; (WidgetData_DrawbarPositionTable_0xd2:24)`). 16 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; PartSubBlkA_WriteLoop32_Table[16].
; -----------------------------------------------------------------------------
PartSubBlkA_WriteLoop32_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x136EA, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] PartSubBlkB_WriteLoop32_Table
; PartSubBlkB_WriteLoop32_Table -- read by PartSubBlkB_WriteLoop32
; (v10/v9 0xf4195f, v7 0xf41951) (`lda xhl,
; (WidgetData_DrawbarPositionTable_0xe2:24)`). 16 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; PartSubBlkB_WriteLoop32_Table[16].
; -----------------------------------------------------------------------------
PartSubBlkB_WriteLoop32_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x136FA, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] PartSubBlkA_WriteLoop48_Table
; PartSubBlkA_WriteLoop48_Table -- read by PartSubBlkA_WriteLoop48
; (v10/v9 0xf41927, v7 0xf41919) (`lda xhl,
; (WidgetData_DrawbarPositionTable_0xf2:24)`), PartSubBlkB_WriteLoop48
; (v10/v9 0xf41989, v7 0xf4197b) (`lda xhl,
; (WidgetData_DrawbarPositionTable_0xf2:24)`). 48 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; PartSubBlkA_WriteLoop48_Table[48].
; -----------------------------------------------------------------------------
PartSubBlkA_WriteLoop48_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1370A, 0x30
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqVoice_ApplyTableEntry_Table
; SeqVoice_ApplyTableEntry_Table -- read by SeqVoice_ApplyTableEntry
; (v10/v9 0xf3ff42, v7 0xf3ff34) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x122`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqVoice_ApplyTableEntry_Table[12].
; -----------------------------------------------------------------------------
SeqVoice_ApplyTableEntry_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1373A, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_ExtendedHandler_Table
; AppEvent_ExtendedHandler_Table -- read by AppEvent_ExtendedHandler
; (v10/v9 0xf3ff1f, v7 0xf3ff11) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x12e`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AppEvent_ExtendedHandler_Table[12].
; -----------------------------------------------------------------------------
AppEvent_ExtendedHandler_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13746, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_ExtendedHandler_Table_2
; AppEvent_ExtendedHandler_Table_2 -- read by AppEvent_ExtendedHandler
; (v10/v9 0xf3ff1f, v7 0xf3ff11) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x13a`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AppEvent_ExtendedHandler_Table_2[12].
; -----------------------------------------------------------------------------
AppEvent_ExtendedHandler_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13752, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Part_ApplyVoiceTableB_Table
; Part_ApplyVoiceTableB_Table -- read by Part_ApplyVoiceTableB (v10/v9
; 0xf3ff2d, v7 0xf3ff1f) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x146`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Part_ApplyVoiceTableB_Table[12].
; -----------------------------------------------------------------------------
Part_ApplyVoiceTableB_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1375E, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Part_ApplyVoiceTableA_Table
; Part_ApplyVoiceTableA_Table -- read by Part_ApplyVoiceTableA (v10/v9
; 0xf3ff34, v7 0xf3ff26) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x152`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Part_ApplyVoiceTableA_Table[12].
; -----------------------------------------------------------------------------
Part_ApplyVoiceTableA_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1376A, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Part_ApplyVoiceTableC_Table
; Part_ApplyVoiceTableC_Table -- read by Part_ApplyVoiceTableC (v10/v9
; 0xf3ff3b, v7 0xf3ff2d) (`ld xwa,
; WidgetData_DrawbarPositionTable_0x15e`). 12 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Part_ApplyVoiceTableC_Table[12].
; -----------------------------------------------------------------------------
Part_ApplyVoiceTableC_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13776, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPlay_WriteErrorToVoiceTable_Data
; SeqPlay_WriteErrorToVoiceTable_Data -- read by
; SeqPlay_WriteErrorToVoiceTable (v10/v9 0xf43a46, v7 0xf43a38) (`lda
; xbc, (WidgetData_DrawbarPositionTable_0x16a:24)`). 12 bytes to the
; next referenced object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPlay_WriteErrorToVoiceTable_Data[12].
; -----------------------------------------------------------------------------
SeqPlay_WriteErrorToVoiceTable_Data:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13782, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] Seq_SyncPositionAndOutputMIDITiming_LocalInit
; Seq_SyncPositionAndOutputMIDITiming_LocalInit -- initializer of a
; local array: Seq_SyncPositionAndOutputMIDITiming (v10/v9 0xf3e1c9, v7
; 0xf3e1ad) (`ld xiy, WidgetData_DrawbarPositionTable_0x176`); `lda xix,
; (xsp + 4); ldi85; ldiw; cp (0xe388:16), 1; jr nz,
; SeqSync_CheckDemoMode` copies 3 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Seq_SyncPositionAndOutputMIDITiming_LocalInit[3].
; -----------------------------------------------------------------------------
Seq_SyncPositionAndOutputMIDITiming_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1378E, 0x3
; -----------------------------------------------------------------------------
; [naka_s_headers] Seq_SyncPositionAndOutputMIDITiming_LocalInit_Tail
; Seq_SyncPositionAndOutputMIDITiming_LocalInit_Tail -- 1 bytes after
; Seq_SyncPositionAndOutputMIDITiming_LocalInit that no code reference
; reaches (searched: every label and positional-label name anchored on
; the historical labels of this span, in all v10 .s files). Contents not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Seq_SyncPositionAndOutputMIDITiming_LocalInit_Tail[1].
; -----------------------------------------------------------------------------
Seq_SyncPositionAndOutputMIDITiming_LocalInit_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13791, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqValPTK_LookupAndReturn_Table
; SeqValPTK_LookupAndReturn_Table -- read by SeqValPTK_LookupAndReturn
; (v10/v9 0xf3f6ef, v7 0xf3f6e1) (`lda xix,
; (WidgetData_DrawbarPositionTable_0x17a:24)`). 14 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqValPTK_LookupAndReturn_Table[14].
; -----------------------------------------------------------------------------
SeqValPTK_LookupAndReturn_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13792, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqData_CopyBlockWithLookup_LocalInit
; SeqData_CopyBlockWithLookup_LocalInit -- initializer of a local array:
; SeqData_CopyBlockWithLookup (v10/v9 0xf409f3, v7 0xf409e5) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x188`); `ld xix, xsp; ldw bc, 0x8;
; ldirw` copies 16 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqData_CopyBlockWithLookup_LocalInit[8].
; -----------------------------------------------------------------------------
SeqData_CopyBlockWithLookup_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137A0, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Rhythm_DispatchNoteAlloc_LocalInit
; Rhythm_DispatchNoteAlloc_LocalInit -- initializer of a local array:
; Rhythm_DispatchNoteAlloc (v10/v9 0xf42852, v7 0xf42844) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x198`); `lda xix, (xsp + 10); ldiw;
; ldiw; ld xiy, WidgetData_DrawbarPositionTable_0x19c; lda xix, (xsp +
; 6)` copies 4 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Rhythm_DispatchNoteAlloc_LocalInit[2].
; -----------------------------------------------------------------------------
Rhythm_DispatchNoteAlloc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137B0, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Rhythm_DispatchNoteAlloc_LocalInit_2
; Rhythm_DispatchNoteAlloc_LocalInit_2 -- initializer of a local array:
; Rhythm_DispatchNoteAlloc (v10/v9 0xf42852, v7 0xf42844) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x19c`); `lda xix, (xsp + 6); ldiw;
; ldiw; calr SeqPart_FindActiveVoiceSlot; ldb_erp L, 0xfb` copies 4
; bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Rhythm_DispatchNoteAlloc_LocalInit_2[2].
; -----------------------------------------------------------------------------
Rhythm_DispatchNoteAlloc_LocalInit_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137B4, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Rhythm_ExtendedNoteAlloc_LocalInit
; Rhythm_ExtendedNoteAlloc_LocalInit -- initializer of a local array:
; Rhythm_ExtendedNoteAlloc (v10/v9 0xf429a0, v7 0xf42992) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1a0`); `lda xix, (xsp + 12); ldiw;
; ldiw; ld xiy, WidgetData_DrawbarPositionTable_0x1a4; lda xix, (xsp +
; 8)` copies 4 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Rhythm_ExtendedNoteAlloc_LocalInit[2].
; -----------------------------------------------------------------------------
Rhythm_ExtendedNoteAlloc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137B8, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Rhythm_ExtendedNoteAlloc_LocalInit_2
; Rhythm_ExtendedNoteAlloc_LocalInit_2 -- initializer of a local array:
; Rhythm_ExtendedNoteAlloc (v10/v9 0xf429a0, v7 0xf42992) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1a4`); `lda xix, (xsp + 8); ldiw;
; ldiw; calr SeqPart_FindActiveVoiceSlot; ldb_erp L, 0xfa` copies 4
; bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Rhythm_ExtendedNoteAlloc_LocalInit_2[2].
; -----------------------------------------------------------------------------
Rhythm_ExtendedNoteAlloc_LocalInit_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137BC, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqEvent_ProcessRhythm4Ch_LocalInit
; SeqEvent_ProcessRhythm4Ch_LocalInit -- initializer of a local array:
; SeqEvent_ProcessRhythm4Ch (v10/v9 0xf42b61, v7 0xf42b53) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1a8`); `lda xix, (xsp + 2); ld bc,
; 4:i3; ldirw` copies 8 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqEvent_ProcessRhythm4Ch_LocalInit[4].
; -----------------------------------------------------------------------------
SeqEvent_ProcessRhythm4Ch_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137C0, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqEvent_ProcessRhythm3Ch_LocalInit
; SeqEvent_ProcessRhythm3Ch_LocalInit -- initializer of a local array:
; SeqEvent_ProcessRhythm3Ch (v10/v9 0xf42bd2, v7 0xf42bc4) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1b0`); `lda xix, (xsp + 2); ld bc,
; 3:i3; ldirw` copies 6 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqEvent_ProcessRhythm3Ch_LocalInit[3].
; -----------------------------------------------------------------------------
SeqEvent_ProcessRhythm3Ch_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137C8, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqEvt_ProcessBlock_LocalInit
; SeqEvt_ProcessBlock_LocalInit -- initializer of a local array:
; SeqEvt_ProcessBlock (v10/v9 0xf42d0b, v7 0xf42cfd) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1b6`); `lda xix, (xsp+4); ldiw;
; ldiw; ld c, (xsp+8); extz bc` copies 4 bytes into the routine's stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqEvt_ProcessBlock_LocalInit[2].
; -----------------------------------------------------------------------------
SeqEvt_ProcessBlock_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137CE, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqEvt_ProcessBlock_LocalInit_2
; SeqEvt_ProcessBlock_LocalInit_2 -- initializer of a local array:
; SeqEvt_ProcessBlock (v10/v9 0xf42d0b, v7 0xf42cfd) (`ld xiy,
; WidgetData_DrawbarPositionTable_0x1ba`); `lda xix, (xsp+4); ldiw;
; ldiw; ld c, (xsp+8); extz bc` copies 4 bytes into the routine's stack
; frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqEvt_ProcessBlock_LocalInit_2[2].
; -----------------------------------------------------------------------------
SeqEvt_ProcessBlock_LocalInit_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137D2, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] WidgetData_CharsetMappingTable
; WidgetData_CharsetMappingTable -- Historical name (it is no charset
; map). Four u32 code addresses: SeqInit_SetBaseAddress,
; SeqInit_ReturnStub, SeqInit_JumpToPartInit, SeqInit_FullReset.
; SystemConfig_PointerTable (ui_widgets/widget_dispatch.s) holds `.long
; WidgetData_CharsetMappingTable`, and MidiSysEx_ProcessBlock (v10/v9
; 0xfd8137, v7 0xfd7d80) calls entry 2 directly: `ld xhl,(<this>+8);
; call (xhl)`. The code also points into it at +0x8.
;
; Typed in naka_widget_descriptors.c as uint32_t
; WidgetData_CharsetMappingTable[4].
; -----------------------------------------------------------------------------
WidgetData_CharsetMappingTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137D6, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Part_InitFromPreset_LocalInit
; Part_InitFromPreset_LocalInit -- initializer of a local array:
; Part_InitFromPreset (v10/v9 0xf42ea4, v7 0xf42e96) (`ld xiy,
; WidgetData_CharsetMappingTable_0x10`); `lda xix, (xsp + 4); ldw bc,
; 0x8; ldirw` copies 16 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Part_InitFromPreset_LocalInit[8].
; -----------------------------------------------------------------------------
Part_InitFromPreset_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137E6, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqData_SendVoiceTableBlock_LocalInit
; SeqData_SendVoiceTableBlock_LocalInit -- initializer of a local array:
; SeqData_SendVoiceTableBlock (v10/v9 0xf43a59, v7 0xf43a4b) (`ld xiy,
; WidgetData_CharsetMappingTable_0x20`); `ld xix, xsp; ld bc, 2:i3;
; ldirw` copies 5 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqData_SendVoiceTableBlock_LocalInit[5].
; -----------------------------------------------------------------------------
SeqData_SendVoiceTableBlock_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137F6, 0x5
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqData_SendVoiceTableBlock_LocalInit_Tail
; SeqData_SendVoiceTableBlock_LocalInit_Tail -- 1 bytes after
; SeqData_SendVoiceTableBlock_LocalInit that no code reference reaches
; (searched: every label and positional-label name anchored on the
; historical labels of this span, in all v10 .s files). Contents not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqData_SendVoiceTableBlock_LocalInit_Tail[1].
; -----------------------------------------------------------------------------
SeqData_SendVoiceTableBlock_LocalInit_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137FB, 0x1
; -----------------------------------------------------------------------------
; [naka_s_headers] EffEdit_ParamChangeB_Table
; EffEdit_ParamChangeB_Table -- read by EffEdit_ParamChangeB (v10/v9
; 0xf45410, v7 0xf45402) (`lda xwa,
; (WidgetData_CharsetMappingTable_0x26:24)`). 128 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffEdit_ParamChangeB_Table[128].
; -----------------------------------------------------------------------------
EffEdit_ParamChangeB_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137FC, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] EffEdit_ParamChangeB_Table_2
; EffEdit_ParamChangeB_Table_2 -- read by EffEdit_ParamChangeB (v10/v9
; 0xf45410, v7 0xf45402) (`lda xde,
; (WidgetData_CharsetMappingTable_0xa6:24)`). 128 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffEdit_ParamChangeB_Table_2[128].
; -----------------------------------------------------------------------------
EffEdit_ParamChangeB_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1387C, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] EffEdit_ParamChangeA_Table
; EffEdit_ParamChangeA_Table -- read by EffEdit_ParamChangeA (v10/v9
; 0xf45398, v7 0xf4538a) (`lda xwa,
; (WidgetData_CharsetMappingTable_0x126:24)`). 128 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffEdit_ParamChangeA_Table[128].
; -----------------------------------------------------------------------------
EffEdit_ParamChangeA_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x138FC, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] EffEdit_ParamChangeA_Table_2
; EffEdit_ParamChangeA_Table_2 -- read by EffEdit_ParamChangeA (v10/v9
; 0xf45398, v7 0xf4538a) (`lda xde,
; (WidgetData_CharsetMappingTable_0x1a6:24)`). 128 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; EffEdit_ParamChangeA_Table_2[128].
; -----------------------------------------------------------------------------
EffEdit_ParamChangeA_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1397C, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_RecordDispatch_BitMasks
; AppEvent_RecordDispatch_BitMasks -- Seventeen u16 single-bit masks: 1
; << k for k = 0..15, then 1 again. AppEvent_RecordDispatch (v10/v9
; 0xf45242, v7 0xf45234) picks one (`lda xbc,<this>`, word move to RAM
; 0x0d4f).
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvent_RecordDispatch_BitMasks[17].
; -----------------------------------------------------------------------------
AppEvent_RecordDispatch_BitMasks:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x139FC, 0x22
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqEvent_MainHandler_CaseTable
; SeqEvent_MainHandler_CaseTable -- jump table of a compiled `switch` in
; SeqEvent_MainHandler (v10/v9 0xf43d4c, v7 0xf43d3e) (`lda xix,
; (WidgetData_CharsetMappingTable_0x248:24)`): case k jumps to
; SeqEvent_Dispatch + entry[k] (`lda xix,(SeqEvent_Dispatch); jp_ind`).
; 14 u16 offsets; the reader's bound `cp ..., 13` pins 14 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqEvent_MainHandler_CaseTable[14].
; -----------------------------------------------------------------------------
SeqEvent_MainHandler_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A1E, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvtHandler_Branch_024_CaseTable
; AppEvtHandler_Branch_024_CaseTable -- jump table of a compiled
; `switch` in AppEvtHandler_Branch_024 (v10/v9 0xf445b0, v7 0xf445a2)
; (`add xwa, WidgetData_CharsetMappingTable_0x264`): case k jumps to
; AppEvtHandler_Branch_024_0x97 + entry[k] (`lda
; xix,(AppEvtHandler_Branch_024_0x97); jp_ind`). 6 u16 offsets; the
; reader's bound `cp ..., 5` pins 6 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvtHandler_Branch_024_CaseTable[6].
; -----------------------------------------------------------------------------
AppEvtHandler_Branch_024_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A3A, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvtHandler_Branch_021_CaseTable
; AppEvtHandler_Branch_021_CaseTable -- jump table of a compiled
; `switch` in AppEvtHandler_Branch_021 (v10/v9 0xf444b9, v7 0xf444ab)
; (`add xwa, WidgetData_CharsetMappingTable_0x270`): case k jumps to
; AppEvtHandler_Branch_021_0x5e + entry[k] (`lda
; xix,(AppEvtHandler_Branch_021_0x5e); jp_ind`). 6 u16 offsets; the
; reader's bound `cp ..., 5` pins 6 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvtHandler_Branch_021_CaseTable[6].
; -----------------------------------------------------------------------------
AppEvtHandler_Branch_021_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A46, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvtHandler_Branch_006_CaseTable
; AppEvtHandler_Branch_006_CaseTable -- jump table of a compiled
; `switch` in AppEvtHandler_Branch_006 (v10/v9 0xf44243, v7 0xf44235)
; (`lda xix, (WidgetData_CharsetMappingTable_0x27c:24)`): case k jumps
; to AppEvtHandler_Branch_006_0x3b + entry[k] (`lda
; xix,(AppEvtHandler_Branch_006_0x3b); jp_ind`). 8 u16 offsets; the
; reader's bound `cp ..., 7` pins 8 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvtHandler_Branch_006_CaseTable[8].
; -----------------------------------------------------------------------------
AppEvtHandler_Branch_006_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A52, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvtHandler_Branch_002_CaseTable
; AppEvtHandler_Branch_002_CaseTable -- jump table of a compiled
; `switch` in AppEvtHandler_Branch_002 (v10/v9 0xf4417e, v7 0xf44170)
; (`lda xix, (WidgetData_CharsetMappingTable_0x28c:24)`): case k jumps
; to AppEvtHandler_Branch_002_0x4b + entry[k] (`lda
; xix,(AppEvtHandler_Branch_002_0x4b); jp_ind`). 8 u16 offsets; the
; reader's bound `cp ..., 7` pins 8 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvtHandler_Branch_002_CaseTable[8].
; -----------------------------------------------------------------------------
AppEvtHandler_Branch_002_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A62, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvtHandler_Branch_002_RamPtrs
; AppEvtHandler_Branch_002_RamPtrs -- Nine u32 RAM addresses (0xf1f1,
; 0x261c, 0xf228, 0x260e, 0x2604, 0xf1db, 0x2604, 0xf1d6, 0x2604).
; AppEvtHandler_Branch_002 (v10/v9 0xf4417e, v7 0xf44170): `lda
; xix,<this>; ld xwa,(xix+wa)` then `cp (xwa),0x11; incm8 1,(xwa)` -- a
; byte counter at the selected address.
;
; Typed in naka_widget_descriptors.c as uint32_t
; AppEvtHandler_Branch_002_RamPtrs[9].
; -----------------------------------------------------------------------------
AppEvtHandler_Branch_002_RamPtrs:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A72, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_ChainDispatch1_CaseTable
; AppEvent_ChainDispatch1_CaseTable -- jump table of a compiled `switch`
; in AppEvent_ChainDispatch1 (v10/v9 0xf44147, v7 0xf44139) (`add xbc,
; WidgetData_CharsetMappingTable_0x2c0`): case k jumps to
; APP_EVENT_HANDLER_TABLE + entry[k] (`lda
; xix,(APP_EVENT_HANDLER_TABLE); jp_ind`). 32 u16 offsets; the reader's
; bound `cp ..., 31` pins 32 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvent_ChainDispatch1_CaseTable[32].
; -----------------------------------------------------------------------------
AppEvent_ChainDispatch1_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13A96, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_SubDispatch_CaseTable
; AppEvent_SubDispatch_CaseTable -- jump table of a compiled `switch` in
; AppEvent_SubDispatch (v10/v9 0xf448a4, v7 0xf44896) (`add xwa,
; WidgetData_CharsetMappingTable_0x300`): case k jumps to
; AppEvent_SubDispatch_0x4cc + entry[k] (`lda
; xix,(AppEvent_SubDispatch_0x4cc); jp_ind`). 6 u16 offsets; the
; reader's bound `cp ..., 5` pins 6 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvent_SubDispatch_CaseTable[6].
; -----------------------------------------------------------------------------
AppEvent_SubDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13AD6, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_SubDispatch_CaseTable_2
; AppEvent_SubDispatch_CaseTable_2 -- jump table of a compiled `switch`
; in AppEvent_SubDispatch (v10/v9 0xf448a4, v7 0xf44896) (`add xwa,
; WidgetData_CharsetMappingTable_0x30c`): case k jumps to
; AppEvent_SubDispatch_0x3a6 + entry[k] (`lda
; xix,(AppEvent_SubDispatch_0x3a6); jp_ind`). 6 u16 offsets; the
; reader's bound `cp ..., 5` pins 6 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvent_SubDispatch_CaseTable_2[6].
; -----------------------------------------------------------------------------
AppEvent_SubDispatch_CaseTable_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13AE2, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_SubDispatch_Table
; AppEvent_SubDispatch_Table -- read by AppEvent_SubDispatch (v10/v9
; 0xf448a4, v7 0xf44896) (`lda xix,
; (WidgetData_CharsetMappingTable_0x318:24)`). 16 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AppEvent_SubDispatch_Table[16].
; -----------------------------------------------------------------------------
AppEvent_SubDispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13AEE, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_SubDispatch_Table_2
; AppEvent_SubDispatch_Table_2 -- read by AppEvent_SubDispatch (v10/v9
; 0xf448a4, v7 0xf44896) (`lda xix,
; (WidgetData_CharsetMappingTable_0x328:24)`). 16 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AppEvent_SubDispatch_Table_2[16].
; -----------------------------------------------------------------------------
AppEvent_SubDispatch_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13AFE, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_SubDispatch_RamPtrs
; AppEvent_SubDispatch_RamPtrs -- Byte-identical to
; AppEvtHandler_Branch_002_RamPtrs (nine u32 RAM addresses).
; AppEvent_SubDispatch (v10/v9 0xf448a4, v7 0xf44896) loads it with `lda
; xix,<this>`; the instructions after that load are still misframed as
; .byte in sequencer_engine.s (`e3 07 f0 e0` = ld xwa,(xix+wa)).
;
; Typed in naka_widget_descriptors.c as uint32_t
; AppEvent_SubDispatch_RamPtrs[9].
; -----------------------------------------------------------------------------
AppEvent_SubDispatch_RamPtrs:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13B0E, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_InlineHandler_CaseTable
; AppEvent_InlineHandler_CaseTable -- jump table of a compiled `switch`
; in AppEvent_InlineHandler (v10/v9 0xf44882, v7 0xf44874) (`add xbc,
; WidgetData_CharsetMappingTable_0x35c`): case k jumps to
; AppEvent_SubDispatch + entry[k] (`lda xix,(AppEvent_SubDispatch);
; jp_ind`). 32 u16 offsets; the reader's bound `cp ..., 31` pins 32
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AppEvent_InlineHandler_CaseTable[32].
; -----------------------------------------------------------------------------
AppEvent_InlineHandler_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13B32, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] AppEvent_RecordDispatch_Table
; AppEvent_RecordDispatch_Table -- read by AppEvent_RecordDispatch
; (v10/v9 0xf45242, v7 0xf45234) (`lda xix,
; (WidgetData_CharsetMappingTable_0x39c:24)`). 16 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AppEvent_RecordDispatch_Table[16].
; -----------------------------------------------------------------------------
AppEvent_RecordDispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13B72, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqState_LabelDispatch_CaseTable
; SeqState_LabelDispatch_CaseTable -- jump table of a compiled `switch`
; in SeqState_LabelDispatch (v10/v9 0xf4519b, v7 0xf4518d) (`lda xix,
; (WidgetData_CharsetMappingTable_0x3ac:24)`): case k jumps to
; SoundData_HandlerDispatch + entry[k] (`lda
; xix,(SoundData_HandlerDispatch); jp_ind`). 16 u16 offsets; the
; reader's bound `cp ..., 15` pins 16 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqState_LabelDispatch_CaseTable[16].
; -----------------------------------------------------------------------------
SeqState_LabelDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13B82, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqAccomp_SubChain_CaseTable
; SeqAccomp_SubChain_CaseTable -- jump table of a compiled `switch` in
; SeqAccomp_SubChain (v10/v9 0xf45fd9, v7 0xf45fcb) (`add xwa,
; WidgetData_CharsetMappingTable_0x3cc`): case k jumps to
; SeqAccomp_SubHandlerB + entry[k] (`lda xix,(SeqAccomp_SubHandlerB);
; jp_ind`). 12 u16 offsets; the reader's bound `cp ..., 11` pins 12
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqAccomp_SubChain_CaseTable[12].
; -----------------------------------------------------------------------------
SeqAccomp_SubChain_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13BA2, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqAccomp_ParamDelivery_CaseTable
; SeqAccomp_ParamDelivery_CaseTable -- jump table of a compiled `switch`
; in SeqAccomp_ParamDelivery (v10/v9 0xf45dc1, v7 0xf45db3) (`add xwa,
; WidgetData_CharsetMappingTable_0x3e4`): case k jumps to
; SeqAccomp_SubHandlerA + entry[k] (`lda xix,(SeqAccomp_SubHandlerA);
; jp_ind`). 12 u16 offsets; the reader's bound `cp ..., 11` pins 12
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqAccomp_ParamDelivery_CaseTable[12].
; -----------------------------------------------------------------------------
SeqAccomp_ParamDelivery_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13BBA, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] ApPlaySyori_CaseTable
; ApPlaySyori_CaseTable -- jump table of a compiled `switch` in
; ApPlaySyori (v10/v9 0xf45ab8, v7 0xf45aaa) (`lda xix,
; (WidgetData_CharsetMappingTable_0x3fc:24)`): case k jumps to
; SeqAccomp_EventDispatch + entry[k] (`lda
; xix,(SeqAccomp_EventDispatch); jp_ind`). 8 u16 offsets; the reader's
; bound `cp ..., 7` pins 8 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; ApPlaySyori_CaseTable[8].
; -----------------------------------------------------------------------------
ApPlaySyori_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13BD2, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditSy_SendModeScrollReset_CaseTable
; NoteEditSy_SendModeScrollReset_CaseTable -- jump table of a compiled
; `switch` in NoteEditSy_SendModeScrollReset (v10/v9 0xf464e4, v7
; 0xf464d6) (`lda xix, (WidgetData_CharsetMappingTable_0x40c:24)`): case
; k jumps to NoteEditSy_ModeDispatch + entry[k] (`lda
; xix,(NoteEditSy_ModeDispatch); jp_ind`). 8 u16 offsets; the reader's
; bound `cp ..., 7` pins 8 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditSy_SendModeScrollReset_CaseTable[8].
; -----------------------------------------------------------------------------
NoteEditSy_SendModeScrollReset_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13BE2, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditSy_HandleDownScroll_CaseTable
; NoteEditSy_HandleDownScroll_CaseTable -- jump table of a compiled
; `switch` in NoteEditSy_HandleDownScroll (v10/v9 0xf46762, v7 0xf46754)
; (`add xde, WidgetData_CharsetMappingTable_0x41c`): case k jumps to
; NoteEditSy_DownScroll_Param0 + entry[k] (`lda
; xix,(NoteEditSy_DownScroll_Param0); jp_ind`). 12 u16 offsets; the
; reader's bound `cp ..., 11` pins 12 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditSy_HandleDownScroll_CaseTable[12].
; -----------------------------------------------------------------------------
NoteEditSy_HandleDownScroll_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13BF2, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] NoteEditSy_HandleUpScroll_CaseTable
; NoteEditSy_HandleUpScroll_CaseTable -- jump table of a compiled
; `switch` in NoteEditSy_HandleUpScroll (v10/v9 0xf466f2, v7 0xf466e4)
; (`add xde, WidgetData_CharsetMappingTable_0x434`): case k jumps to
; NoteEditSy_UpScroll_Param0 + entry[k] (`lda
; xix,(NoteEditSy_UpScroll_Param0); jp_ind`). 15 u16 offsets; the
; reader's bound `cp ..., 14` pins 15 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; NoteEditSy_HandleUpScroll_CaseTable[15].
; -----------------------------------------------------------------------------
NoteEditSy_HandleUpScroll_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13C0A, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] MainExeCall_CaseTable
; MainExeCall_CaseTable -- jump table of a compiled `switch` in
; MainExeCall (v10/v9 0xf470a4, v7 0xf47096) (`lda xix,
; (WidgetData_CharsetMappingTable_0x452:24)`): case k jumps to
; MainExe_HandleD6 + entry[k] (`lda xix,(MainExe_HandleD6); jp_ind`). 17
; u16 offsets; the reader's bound `cp ..., 16` pins 17 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; MainExeCall_CaseTable[17].
; -----------------------------------------------------------------------------
MainExeCall_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13C28, 0x22
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpLang_ByteTable0
; HelpLang_ByteTable0 -- One of five 50-byte tables at 50-byte spacing.
; HelpLang_DispatchDataBlock (v10/v9 0xf47667, v7 0xf47659) picks one of
; the five addresses (0xe44aaa, 0xe44adc, 0xe44b0e, 0xe44b40, 0xe44b72)
; and reads `ld a,(xwa+bc)`; which help language selects which table,
; and what the bytes mean, is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t HelpLang_ByteTable0[50].
; -----------------------------------------------------------------------------
HelpLang_ByteTable0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13C4A, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpLang_ByteTable1
; HelpLang_ByteTable1 -- One of five 50-byte tables at 50-byte spacing.
; HelpLang_DispatchDataBlock (v10/v9 0xf47667, v7 0xf47659) picks one of
; the five addresses (0xe44aaa, 0xe44adc, 0xe44b0e, 0xe44b40, 0xe44b72)
; and reads `ld a,(xwa+bc)`; which help language selects which table,
; and what the bytes mean, is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t HelpLang_ByteTable1[50].
; -----------------------------------------------------------------------------
HelpLang_ByteTable1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13C7C, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpLang_ByteTable2
; HelpLang_ByteTable2 -- One of five 50-byte tables at 50-byte spacing.
; HelpLang_DispatchDataBlock (v10/v9 0xf47667, v7 0xf47659) picks one of
; the five addresses (0xe44aaa, 0xe44adc, 0xe44b0e, 0xe44b40, 0xe44b72)
; and reads `ld a,(xwa+bc)`; which help language selects which table,
; and what the bytes mean, is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t HelpLang_ByteTable2[50].
; -----------------------------------------------------------------------------
HelpLang_ByteTable2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13CAE, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] HelpLang_ByteTable3
; HelpLang_ByteTable3 -- One of five 50-byte tables at 50-byte spacing.
; HelpLang_DispatchDataBlock (v10/v9 0xf47667, v7 0xf47659) picks one of
; the five addresses (0xe44aaa, 0xe44adc, 0xe44b0e, 0xe44b40, 0xe44b72)
; and reads `ld a,(xwa+bc)`; which help language selects which table,
; and what the bytes mean, is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t HelpLang_ByteTable3[50].
; -----------------------------------------------------------------------------
HelpLang_ByteTable3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13CE0, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] FontPalette_Gradient7
; FontPalette_Gradient7 -- Historical name (no palette). One of five
; 50-byte tables at 50-byte spacing. HelpLang_DispatchDataBlock (v10/v9
; 0xf47667, v7 0xf47659) picks one of the five addresses (0xe44aaa,
; 0xe44adc, 0xe44b0e, 0xe44b40, 0xe44b72) and reads `ld a,(xwa+bc)`;
; which help language selects which table, and what the bytes mean, is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FontPalette_Gradient7[50].
; -----------------------------------------------------------------------------
FontPalette_Gradient7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13D12, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_ParseRhythm_ByteMap
; SeqStep_ParseRhythm_ByteMap -- 20 bytes 00 02 01 07 08 09 0A 0B 04 05
; 06 03 0F FF FF FF FF 0C 0D 0E. SeqStep_ParseRhythm (v10/v9 0xf4e372,
; v7 0xf4df6e) compares against it (`lda xhl,<this>; cpb_sri_rm
; A,(xhl+de)`); SeqPart_InitValidOk (v10/v9 0xf4a073, v7 0xf49c89) and
; SeqPart_DualLoadPartB (v10/v9 0xf4b341, v7 0xf4af57) move one byte of
; it to RAM 0x287c. What the values stand for is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqStep_ParseRhythm_ByteMap[20].
; -----------------------------------------------------------------------------
SeqStep_ParseRhythm_ByteMap:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13D44, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid96
; QuantizeMap_Grid96 -- Tick-quantize map for a 96-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 96, and 0x7f where that rounds into the next unit --
; exactly, for all 96 bytes (checked). Reached through
; Display_FontPalette_Table (entry 6); was FontPalette_Gradient6, a name
; no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid96[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid96:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13D58, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid48
; QuantizeMap_Grid48 -- Tick-quantize map for a 48-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 48, and 0x7f where that rounds into the next unit --
; exactly, for all 96 bytes (checked). Reached through
; Display_FontPalette_Table (entry 5); was FontPalette_Gradient5, a name
; no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid48[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid48:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13DB8, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid24
; QuantizeMap_Grid24 -- Tick-quantize map for a 24-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 24, and 0x7f where that rounds into the next unit --
; exactly, for all 96 bytes (checked). Reached through
; Display_FontPalette_Table (entry 3); was FontPalette_Gradient4, a name
; no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid24[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid24:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13E18, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid12
; QuantizeMap_Grid12 -- Tick-quantize map for a 12-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 12, and 0x7f where that rounds into the next unit --
; checked byte by byte, with one exception: the run for 72 (t = 66..77)
; is stored as 0x49 = 73. Reached through Display_FontPalette_Table
; (entry 1); was FontPalette_Gradient3, a name no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid12[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid12:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13E78, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid32
; QuantizeMap_Grid32 -- Tick-quantize map for a 32-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 32, and 0x7f where that rounds into the next unit --
; exactly, for all 96 bytes (checked). Reached through
; Display_FontPalette_Table (entry 4); was FontPalette_Gradient2, a name
; no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid32[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid32:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13ED8, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid16
; QuantizeMap_Grid16 -- Tick-quantize map for a 16-tick grid (the
; 96-tick unit of the sequencer): byte t is t rounded to the nearest
; multiple of 16, and 0x7f where that rounds into the next unit --
; exactly, for all 96 bytes (checked). Reached through
; Display_FontPalette_Table (entry 2); was FontPalette_Gradient1, a name
; no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid16[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid16:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13F38, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] QuantizeMap_Grid8
; QuantizeMap_Grid8 -- Tick-quantize map for a 8-tick grid (the 96-tick
; unit of the sequencer): byte t is t rounded to the nearest multiple of
; 8, and 0x7f where that rounds into the next unit -- exactly, for all
; 96 bytes (checked). Reached through Display_FontPalette_Table (entry
; 0); was FontPalette_Gradient0, a name no code used.
;
; Typed in naka_widget_descriptors.c as uint8_t QuantizeMap_Grid8[96].
; -----------------------------------------------------------------------------
QuantizeMap_Grid8:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13F98, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] Display_FontPalette_Table
; Display_FontPalette_Table -- Historical name (it is no font palette).
; Seven pointers to the QuantizeMap_Grid* tables above, in grid order 8,
; 12, 16, 24, 32, 48, 96 ticks. SeqPart_VelExprEdit (v10/v9 0xf4c5d3, v7
; 0xf4c1e9) takes entry ((byte 0x25fe) >> 1): `lda xbc,<this>; ld
; xwa,(xbc+4*i)`.
;
; Typed in naka_widget_descriptors.c as uint32_t
; Display_FontPalette_Table[7].
; -----------------------------------------------------------------------------
Display_FontPalette_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13FF8, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Display_FontPalette_Table_Tail
; Display_FontPalette_Table_Tail -- 2 bytes after
; Display_FontPalette_Table that no code reference reaches (searched:
; every label and positional-label name anchored on the historical
; labels of this span, in all v10 .s files). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Display_FontPalette_Table_Tail[2].
; -----------------------------------------------------------------------------
Display_FontPalette_Table_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14014, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table
; SeqPart_VelCurveData_Table -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`lda xbc,
; (Display_FontPalette_Table_0x1e:24)`). 2 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table[2].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14016, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_2
; SeqPart_VelCurveData_Table_2 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`lda xbc,
; (Display_FontPalette_Table_0x20:24)`). 4 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_2[4].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14018, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_3
; SeqPart_VelCurveData_Table_3 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`lda xbc,
; (Display_FontPalette_Table_0x24:24)`). 8 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_3[8].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1401C, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_4
; SeqPart_VelCurveData_Table_4 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`lda xbc,
; (Display_FontPalette_Table_0x2c:24)`). 4 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_4[4].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14024, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_5
; SeqPart_VelCurveData_Table_5 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`lda xbc,
; (Display_FontPalette_Table_0x30:24)`). 6 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_5[6].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14028, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelZoneLookup_Table
; SeqPart_VelZoneLookup_Table -- read by SeqPart_VelZoneLookup (v10/v9
; 0xf4c56d, v7 0xf4c183) (`lda xbc,
; (Display_FontPalette_Table_0x36:24)`). 14 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelZoneLookup_Table[14].
; -----------------------------------------------------------------------------
SeqPart_VelZoneLookup_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1402E, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_6
; SeqPart_VelCurveData_Table_6 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`ld xbc, Display_FontPalette_Table_0x44`). 2
; bytes to the next referenced object; the layout beyond that access is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_6[2].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1403C, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelCurveData_Table_7
; SeqPart_VelCurveData_Table_7 -- read by SeqPart_VelCurveData (v10/v9
; 0xf4c38c, v7 0xf4bfa2) (`ld xbc, Display_FontPalette_Table_0x46`). 22
; bytes to the next referenced object; the layout beyond that access is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelCurveData_Table_7[22].
; -----------------------------------------------------------------------------
SeqPart_VelCurveData_Table_7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1403E, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelZoneLookup_Table_2
; SeqPart_VelZoneLookup_Table_2 -- read by SeqPart_VelZoneLookup (v10/v9
; 0xf4c56d, v7 0xf4c183) (`ld xbc, Display_FontPalette_Table_0x5c`). 12
; bytes to the next referenced object; the layout beyond that access is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqPart_VelZoneLookup_Table_2[12].
; -----------------------------------------------------------------------------
SeqPart_VelZoneLookup_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14054, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqPart_VelocityCurveCalc_CaseTable
; SeqPart_VelocityCurveCalc_CaseTable -- jump table of a compiled
; `switch` in SeqPart_VelocityCurveCalc (v10/v9 0xf4c360, v7 0xf4bf76)
; (`lda xix, (Display_FontPalette_Table_0x68:24)`): case k jumps to
; SeqPart_VelCurveData + entry[k] (`lda xix,(SeqPart_VelCurveData);
; jp_ind`). 11 u16 offsets; the reader's bound `cp ..., 10` pins 11
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqPart_VelocityCurveCalc_CaseTable[11].
; -----------------------------------------------------------------------------
SeqPart_VelocityCurveCalc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14060, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_NoteReadEvent_CaseTable
; SeqStep_NoteReadEvent_CaseTable -- jump table of a compiled `switch`
; in SeqStep_NoteReadEvent (v10/v9 0xf4ce61, v7 0xf4ca77) (`lda xix,
; (Display_FontPalette_Table_0x7e:24)`): case k jumps to
; SeqStep_NoteByteBlock + entry[k] (`lda xix,(SeqStep_NoteByteBlock);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqStep_NoteReadEvent_CaseTable[7].
; -----------------------------------------------------------------------------
SeqStep_NoteReadEvent_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14076, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_EventPosConsumeAdvance_CaseTable
; SeqStep_EventPosConsumeAdvance_CaseTable -- jump table of a compiled
; `switch` in SeqStep_EventPosConsumeAdvance (v10/v9 0xf4d127, v7
; 0xf4cd3d) (`lda xix, (Display_FontPalette_Table_0x8c:24)`): case k
; jumps to SeqStep_EventPosFinish + entry[k] (`lda
; xix,(SeqStep_EventPosFinish); jp_ind`). 7 u16 offsets; the reader's
; bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqStep_EventPosConsumeAdvance_CaseTable[7].
; -----------------------------------------------------------------------------
SeqStep_EventPosConsumeAdvance_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14084, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_DeleteDone_CaseTable
; SeqStep_DeleteDone_CaseTable -- jump table of a compiled `switch` in
; SeqStep_DeleteDone (v10/v9 0xf4d37d, v7 0xf4cf93) (`lda xix,
; (Display_FontPalette_Table_0x9a:24)`): case k jumps to
; SeqStep_DeleteExitRestore + entry[k] (`lda
; xix,(SeqStep_DeleteExitRestore); jp_ind`). 7 u16 offsets; the reader's
; bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; SeqStep_DeleteDone_CaseTable[7].
; -----------------------------------------------------------------------------
SeqStep_DeleteDone_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14092, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_TimerDispatch_ProcTables
; SeqStep_TimerDispatch_ProcTables -- Three tables of 23 u32 code
; addresses, one per timer dispatcher: SeqStep_TimerDispatchA (v10/v9
; 0xf4e65a, v7 0xf4e256) uses +0x00, SeqStep_TimerDispatchB (v10/v9
; 0xf4e66f, v7 0xf4e26b) +0x5c, SeqStep_TimerDispatchC (v10/v9 0xf4e684,
; v7 0xf4e280) +0xb8 -- each `lda xbc,<table>; ld xhl,(xbc+4*i); jp
; (xhl)`. The targets (SeqStep_PlaybackMaxPart,
; SeqPlay_BufferUpdateBlock, SeqNotify_DataBlock and three unlabelled
; addresses) are the handlers; 23 = (0x104-0xa8)/4, and all 69 values
; are code addresses (v7 relocates them through v7_c_divergence.json).
; The code also points into it at +0x5c, +0xb8.
;
; Typed in naka_widget_descriptors.c as uint32_t
; SeqStep_TimerDispatch_ProcTables[3][23].
; -----------------------------------------------------------------------------
SeqStep_TimerDispatch_ProcTables:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x140A0, 0x114
; -----------------------------------------------------------------------------
; [naka_s_headers] SeqStep_TimerDispatch_ProcTables_Tail
; SeqStep_TimerDispatch_ProcTables_Tail -- 66 bytes after
; SeqStep_TimerDispatch_ProcTables that no code reference reaches
; (searched: every label and positional-label name anchored on the
; historical labels of this span, in all v10 .s files). Holds short
; NUL-terminated strings -- "A", "w~", "d", "wb", "r", "d", "r", "a",
; "d", ". " padded to 11 characters, "r" -- then zeros and 02 02 01 00
; 02 70 00 A0 05 F9 03 00 09 00 02 00, the 2DD geometry fields of
; FDC_Format2DD_BootSectorHead. Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; SeqStep_TimerDispatch_ProcTables_Tail[66].
; -----------------------------------------------------------------------------
SeqStep_TimerDispatch_ProcTables_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x141B4, 0x42
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2DD_Step2_FdcCmd
; FDC_Format2DD_Step2_FdcCmd -- FDC command block: FDC_Format2DD_Step2
; (v10/v9 0xf51ed7, v7 0xf51ad3) (`lda xwa,
; (Display_FontPalette_Table_0x1fe:24)`), FDC_Format2HD_Step2 (v10/v9
; 0xf522bd, v7 0xf51eb9) (`lda xwa,
; (Display_FontPalette_Table_0x1fe:24)`) passes its address to
; FDC_CommandEntry (`lda xwa,<this>; push xwa; call FDC_CommandEntry`).
; 32 bytes to the next referenced object; the field layout is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2DD_Step2_FdcCmd[32].
; -----------------------------------------------------------------------------
FDC_Format2DD_Step2_FdcCmd:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x141F6, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2DD_Start_FdcCmd
; FDC_Format2DD_Start_FdcCmd -- FDC command block: FDC_Format2DD_Start
; (v10/v9 0xf51eab, v7 0xf51aa7) (`lda xwa,
; (Display_FontPalette_Table_0x21e:24)`), GetMediaType_Try2DDHeader
; (v10/v9 0xf526d4, v7 0xf522d0) (`lda xwa,
; (Display_FontPalette_Table_0x21e:24)`) passes its address to
; FDC_CommandEntry (`lda xwa,<this>; push xwa; call FDC_CommandEntry`).
; 32 bytes to the next referenced object; the field layout is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2DD_Start_FdcCmd[32].
; -----------------------------------------------------------------------------
FDC_Format2DD_Start_FdcCmd:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14216, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2HD_Start_FdcCmd
; FDC_Format2HD_Start_FdcCmd -- FDC command block: FDC_Format2HD_Start
; (v10/v9 0xf52291, v7 0xf51e8d) (`lda xwa,
; (Display_FontPalette_Table_0x23e:24)`), GetMediaType_TryFormat2HD
; (v10/v9 0xf5266d, v7 0xf52269) (`lda xwa,
; (Display_FontPalette_Table_0x23e:24)`) passes its address to
; FDC_CommandEntry (`lda xwa,<this>; push xwa; call FDC_CommandEntry`).
; 16 bytes to the next referenced object; the field layout is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2HD_Start_FdcCmd[16].
; -----------------------------------------------------------------------------
FDC_Format2HD_Start_FdcCmd:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14236, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] GetMediaType_TryRecalib_FdcCmd
; GetMediaType_TryRecalib_FdcCmd -- FDC command block:
; GetMediaType_TryRecalib (v10/v9 0xf52657, v7 0xf52253) (`lda xwa,
; (Display_FontPalette_Table_0x24e:24)`) passes its address to
; FDC_CommandEntry (`lda xwa,<this>; push xwa; call FDC_CommandEntry`).
; 16 bytes to the next referenced object; the field layout is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; GetMediaType_TryRecalib_FdcCmd[16].
; -----------------------------------------------------------------------------
GetMediaType_TryRecalib_FdcCmd:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14246, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2DD_BootSectorHead
; FDC_Format2DD_BootSectorHead -- First 32 bytes of the boot sector
; written by FDC_Format2DD_WriteBoot (v10/v9 0xf51f0f, v7 0xf51b0b)
; (Mem_Copy source): EB 1C 90, OEM name "Technics", then a FAT12 BIOS
; parameter block for a 720 KB 2DD disk -- 512 bytes/sector, 2
; sectors/cluster, 1 reserved, 2 FATs, 112 root entries, 1440 sectors,
; media F9, 3 sectors/FAT, 9 sectors/track, 2 heads -- and EB FE.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2DD_BootSectorHead[32].
; -----------------------------------------------------------------------------
FDC_Format2DD_BootSectorHead:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14256, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2DD_FatHead
; FDC_Format2DD_FatHead -- F9 FF FF FF: the first FAT bytes (media byte
; F9) that FDC_Format2DD_WriteFAT1 (v10/v9 0xf51f7c, v7 0xf51b78) copies
; with Mem_Copy.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2DD_FatHead[4].
; -----------------------------------------------------------------------------
FDC_Format2DD_FatHead:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x14276, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2HD_BootSectorHead
; FDC_Format2HD_BootSectorHead -- First 32 bytes of the boot sector
; written by FDC_Format2HD_WriteBoot (v10/v9 0xf522f5, v7 0xf51ef1): EB
; 1C 90, "Technics", FAT12 BPB for a 1.44 MB 2HD disk -- 512
; bytes/sector, 1 sector/cluster, 1 reserved, 2 FATs, 224 root entries,
; 2880 sectors, media F0, 9 sectors/FAT, 18 sectors/track, 2 heads -- EB
; FE.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2HD_BootSectorHead[32].
; -----------------------------------------------------------------------------
FDC_Format2HD_BootSectorHead:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1427A, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2HD_FatHead
; FDC_Format2HD_FatHead -- F0 FF FF FF: first FAT bytes (media F0)
; copied by FDC_Format2HD_WriteFAT1 (v10/v9 0xf52362, v7 0xf51f5e) and
; FDC_Format2HD_TrackTest (v10/v9 0xf52412, v7 0xf5200e).
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2HD_FatHead[4].
; -----------------------------------------------------------------------------
FDC_Format2HD_FatHead:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1429A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] FDC_Format2HD_FatHead_Tail
; FDC_Format2HD_FatHead_Tail -- 6 bytes after FDC_Format2HD_FatHead that
; no code reference reaches (searched: every label and positional-label
; name anchored on the historical labels of this span, in all v10 .s
; files). Holds the strings "d" and "A:\". Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; FDC_Format2HD_FatHead_Tail[6].
; -----------------------------------------------------------------------------
FDC_Format2HD_FatHead_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1429E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] GetDiskFreeSpace_CaseTable
; GetDiskFreeSpace_CaseTable -- jump table of a compiled `switch` in
; GetDiskFreeSpace (v10/v9 0xf52751, v7 0xf5234d) (`lda xix,
; (Display_FontPalette_Table_0x2ac:24)`): case k jumps to
; GetDiskFreeSpace_JumpTable + entry[k] (`lda
; xix,(GetDiskFreeSpace_JumpTable); jp_ind`). 7 u16 offsets; the
; reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; GetDiskFreeSpace_CaseTable[7].
; -----------------------------------------------------------------------------
GetDiskFreeSpace_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x142A4, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] GetDiskFreeSpace_CaseTable_Tail
; GetDiskFreeSpace_CaseTable_Tail -- 6 bytes after
; GetDiskFreeSpace_CaseTable that no code reference reaches (searched:
; every label and positional-label name anchored on the historical
; labels of this span, in all v10 .s files). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; GetDiskFreeSpace_CaseTable_Tail[6].
; -----------------------------------------------------------------------------
GetDiskFreeSpace_CaseTable_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x142B2, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] GetVolumeLabel_CaseTable
; GetVolumeLabel_CaseTable -- jump table of a compiled `switch` in
; GetVolumeLabel (v10/v9 0xf527ce, v7 0xf523ca) (`lda xix,
; (Display_FontPalette_Table_0x2c0:24)`): case k jumps to
; GetVolumeLabel_JumpTable + entry[k] (`lda
; xix,(GetVolumeLabel_JumpTable); jp_ind`). 7 u16 offsets; the reader's
; bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; GetVolumeLabel_CaseTable[7].
; -----------------------------------------------------------------------------
GetVolumeLabel_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x142B8, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] GetVolumeLabel_CaseTable_Tail
; GetVolumeLabel_CaseTable_Tail -- 28 bytes after
; GetVolumeLabel_CaseTable that no code reference reaches (searched:
; every label and positional-label name anchored on the historical
; labels of this span, in all v10 .s files). Holds the strings "A:\",
; "+wb", "\", "d", "rb", then 0xff and "1 PianoDisc". Contents not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; GetVolumeLabel_CaseTable_Tail[28].
; -----------------------------------------------------------------------------
GetVolumeLabel_CaseTable_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x142C6, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] RhythmROM_BankProgramLocators
; RhythmROM_BankProgramLocators -- 8 banks x 128 programs x {u16 hi, u16
; lo}. AccVoice_ComputeChannelIndex (v10/v9 0xf53d77, v7 0xf53973) shows
; the index: hl = (h & 7) * 512 + a * 4, then `ld wa,(xiy+hl)`, `add
; hl,2`, `ld iy,(xiy+hl)`; RhythmROM_PatternDispatcher (v10/v9 0xf634f3,
; v7 0xf630ef) stores the two words at 0x355a/0x355c, DrumVoice_Handler7
; (v10/v9 0xf654b0, v7 0xf650ac) and VoiceAssign_ProcessRequest (v10/v9
; 0xf67128, v7 0xf66d24) read them the same way. Measured: every
; non-zero pair forms hi:lo = a multiple of 0x800 below 0x70000; zero
; pairs mark unused (bank, program) slots. What the 32-bit value locates
; is not established.
;
; Typed in naka_widget_descriptors.c as uint16_t
; RhythmROM_BankProgramLocators[8][128][2].
; -----------------------------------------------------------------------------
RhythmROM_BankProgramLocators:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x142E2, 0x1000
; -----------------------------------------------------------------------------
; [naka_s_headers] AccPatch_Transpose_LookupTable_Data
; AccPatch_Transpose_LookupTable_Data -- read by
; AccPatch_Transpose_LookupTable (v10/v9 0xf60874, v7 0xf60470) (`add
; xhl, Display_FontPalette_Table_0x12ea`), AccPlayback_TrackPosition
; (v10/v9 0xf61f6e, v7 0xf61b6a) (`ld xix,
; Display_FontPalette_Table_0x12ea`), ToneGen_WriteMultiChanParam
; (v10/v9 0xf62986, v7 0xf62582) (`ld xix,
; Display_FontPalette_Table_0x12ea`), __pad_F62B29 (v10/v9 0xf62b29, v7
; 0xf62725) (`ld xix, Display_FontPalette_Table_0x12ea`),
; Rhythm_CrossVoice_Apply (v10/v9 0xf54ffe, v7 0xf54bfa) (`ld xiy,
; Display_FontPalette_Table_0x12ea`), Rhythm_NoteRangeCheck (v10/v9
; 0xf55030, v7 0xf54c2c) (`ld xiy, Display_FontPalette_Table_0x12ea`),
; Rhythm_InstrBaseLookup (v10/v9 0xf550bb, v7 0xf54cb7) (`ld xiy,
; Display_FontPalette_Table_0x12ea`), Rhythm_TranspMod_BaseApply (v10/v9
; 0xf55b44, v7 0xf55740) (`ld xiy, Display_FontPalette_Table_0x12ea`),
; AccPlay_NoteAllocAndWrite (v10/v9 0xf722ab, v7 0xf71ea7) (`ld xix,
; Display_FontPalette_Table_0x12ea`). 128 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccPatch_Transpose_LookupTable_Data[128].
; -----------------------------------------------------------------------------
AccPatch_Transpose_LookupTable_Data:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x152E2, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] Rhythm_VelLookA_TableLookup_Table
; Rhythm_VelLookA_TableLookup_Table -- read by
; Rhythm_VelLookA_TableLookup (v10/v9 0xf5509a, v7 0xf54c96) (`ld xiy,
; Display_FontPalette_Table_0x136a`), Rhythm_VoiceMap_Inst2Bit3 (v10/v9
; 0xf5524e, v7 0xf54e4a) (`ld xiy, Display_FontPalette_Table_0x136a`),
; Rhythm_VelComp_Lookup (v10/v9 0xf5530d, v7 0xf54f09) (`ld xiy,
; Display_FontPalette_Table_0x136a`), Rhythm_TranspMod_BaseLookup
; (v10/v9 0xf55b5b, v7 0xf55757) (`ld xiy,
; Display_FontPalette_Table_0x136a`). 456 bytes to the next referenced
; object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Rhythm_VelLookA_TableLookup_Table[456].
; -----------------------------------------------------------------------------
Rhythm_VelLookA_TableLookup_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15362, 0x1C8
; -----------------------------------------------------------------------------
; [naka_s_headers] VoiceParam_BankProgramWords
; VoiceParam_BankProgramWords -- 8 x 128 u16.
; VoiceParam_Clamp_LookupTable (v10/v9 0xf5345a, v7 0xf53056): `ld
; xwa,<this>; sla l,1; and h,7; ld hl,(xwa+hl)` -- row h (bank, clamped
; to 0..7 by VoiceParam_Clamp_CheckBank), column l. Meaning of the words
; not established.
;
; Typed in naka_widget_descriptors.c as uint16_t
; VoiceParam_BankProgramWords[8][128].
; -----------------------------------------------------------------------------
VoiceParam_BankProgramWords:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1552A, 0x800
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_LookupByProgram_Table
; AccTone_LookupByProgram_Table -- read by AccTone_LookupByProgram
; (v10/v9 0xf5d640, v7 0xf5d23c) (`lda xbc,
; (Display_FontPalette_Table_0x1d32:24)`),
; AccTone_ExtendAndDispatch_Body (v10/v9 0xf5d740, v7 0xf5d33c) (`lda
; xhl, (Display_FontPalette_Table_0x1d32:24)`),
; AccTone_FoundMatch_IncRet (v10/v9 0xf5d7f4, v7 0xf5d3f0) (`lda xbc,
; (Display_FontPalette_Table_0x1d32:24)`), AccPatch_SlotScanByteData
; (v10/v9 0xf5eb9c, v7 0xf5e798) (`add xwa,
; Display_FontPalette_Table_0x1d32`), AccPatch_FillEntryWithVoiceData
; (v10/v9 0xf5ef3b, v7 0xf5eb37) (`ld xbc,
; Display_FontPalette_Table_0x1d32`), AccPatch_ReadVoiceStride (v10/v9
; 0xf5f108, v7 0xf5ed04) (`ld xbc, Display_FontPalette_Table_0x1d32`),
; AccPatch_RebuildChannelSlot (v10/v9 0xf5f1b7, v7 0xf5edb3) (`add xhl,
; Display_FontPalette_Table_0x1d32`), AccPatch_ComplexDataBlock (v10/v9
; 0xf5fac8, v7 0xf5f6c4) (`ld xbc, Display_FontPalette_Table_0x1d32`),
; AccPatch_FillSlotWithVoiceData (v10/v9 0xf5fd29, v7 0xf5f925) (`ld
; xbc, Display_FontPalette_Table_0x1d32`), VoiceResolve_FindSlot (v10/v9
; 0xf67448, v7 0xf67044) (`ld xbc, Display_FontPalette_Table_0x1d32`),
; AccStyle_ReadVoiceParam (v10/v9 0xf53ddc, v7 0xf539d8) (`ld xhl,
; Display_FontPalette_Table_0x1d32`), AccPatch_ClampedSetParam (v10/v9
; 0xf53df8, v7 0xf539f4) (`ld xhl, Display_FontPalette_Table_0x1d32`).
; 20 bytes to the next referenced object; the layout beyond that access
; is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_LookupByProgram_Table[20].
; -----------------------------------------------------------------------------
AccTone_LookupByProgram_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15D2A, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] AccVoice_LookupTableAddress_Table
; AccVoice_LookupTableAddress_Table -- read by
; AccVoice_LookupTableAddress (v10/v9 0xf569db, v7 0xf565d7) (`ld xde,
; Display_FontPalette_Table_0x1d46`), AccVoice_LookupExtParamAddr
; (v10/v9 0xf569f0, v7 0xf565ec) (`ld xde,
; Display_FontPalette_Table_0x1d46`), AccTempo_ComputeDelta (v10/v9
; 0xf570f8, v7 0xf56cf4) (`add xwa, Display_FontPalette_Table_0x1d46`),
; AccVoice_PatchFromDirect (v10/v9 0xf53dbc, v7 0xf539b8) (`ld xhl,
; Display_FontPalette_Table_0x1d46`), Seq_ProcessAllInputState (v10/v9
; 0xf53509, v7 0xf53105) (`add xhl, Display_FontPalette_Table_0x1d46`).
; 18 bytes to the next referenced object; the layout beyond that access
; is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccVoice_LookupTableAddress_Table[18].
; -----------------------------------------------------------------------------
AccVoice_LookupTableAddress_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15D3E, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_ApplyExt_SkipClamp_Table
; AccStyle_ApplyExt_SkipClamp_Table -- read by
; AccStyle_ApplyExt_SkipClamp (v10/v9 0xf560c5, v7 0xf55cc1) (`ld xhl,
; Display_FontPalette_Table_0x1d58`), AccVoice_Reassign_Mode2 (v10/v9
; 0xf58afd, v7 0xf586f9) (`ld xhl, Display_FontPalette_Table_0x1d58`),
; AccTone_FoundMatch_IncRet (v10/v9 0xf5d7f4, v7 0xf5d3f0) (`lda xbc,
; (Display_FontPalette_Table_0x1d58:24)`), AccPedal_ProcessAllChanges
; (v10/v9 0xf537f0, v7 0xf533ec) (`ld xhl,
; Display_FontPalette_Table_0x1d58`), AccVoice_ReadBankAssign (v10/v9
; 0xf5387b, v7 0xf53477) (`ld xhl, Display_FontPalette_Table_0x1d58`),
; AccChord_DispatchVoiceChange (v10/v9 0xf53b62, v7 0xf5375e) (`ld xhl,
; Display_FontPalette_Table_0x1d58`), RhythmPart_ProcessBit1 (v10/v9
; 0xf53c2f, v7 0xf5382b) (`ld xhl, Display_FontPalette_Table_0x1d58`). 9
; bytes to the next referenced object; the layout beyond that access is
; not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_ApplyExt_SkipClamp_Table[9].
; -----------------------------------------------------------------------------
AccStyle_ApplyExt_SkipClamp_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15D50, 0x9
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_DefaultStream
; AccStyle_DefaultStream -- A 64-byte event stream: 03 FF FF FF FF 87,
; then fifteen `90 00 7D/7E 40 01 00` events separated by 81, then 81 83
; 87 -- it parses exactly under the ASEQ_* byte grammar of naka_types.h.
; AccStyle_SetupPartAddresses (v10/v9 0xf55fde, v7 0xf55bda),
; AccStyle_SetupPartAddressesByHL (v10/v9 0xf56208, v7 0xf55e04),
; AccPart_InitPositionsAndBase (v10/v9 0xf562c6, v7 0xf55ec2),
; AccSeq_NextBarPage (v10/v9 0xf57465, v7 0xf57061) and
; AccSeq_ResetToStart (v10/v9 0xf574a2, v7 0xf5709e) load <this>+6 into
; the accompaniment cursor at RAM 0x3293.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_DefaultStream[64].
; -----------------------------------------------------------------------------
AccStyle_DefaultStream:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15D59, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_ExtStyleMap
; AccStyle_ExtStyleMap -- 30 bytes: 00 01 02 03 three times, then zeros.
; AccStyle_ApplyExtendedStyle (v10/v9 0xf5607e, v7 0xf55c7a) and
; AccStyle_ExtendedInit (v10/v9 0xf58754, v7 0xf58350) index it with
; (byte 0x32e5) & 0x7f, clamped to 0..0x1d -- the clamp pins the 30
; entries.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_ExtStyleMap[30].
; -----------------------------------------------------------------------------
AccStyle_ExtStyleMap:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15D99, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] Seq_TempoByteMap
; Seq_TempoByteMap -- 256 bytes indexed by the low byte of RAM word
; 0x0409: Seq_ReadTempoLookup (v10/v9 0xf534f4, v7 0xf530f0) (`add
; xhl,<this>; ld a,(xhl)`) stores the result at 0x334b. Meaning of the
; values not established.
;
; Typed in naka_widget_descriptors.c as uint8_t Seq_TempoByteMap[256].
; -----------------------------------------------------------------------------
Seq_TempoByteMap:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15DB7, 0x100
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_NoteLookup_Table
; AccTone_NoteLookup_Table -- read by AccTone_NoteLookup (v10/v9
; 0xf5d6ed, v7 0xf5d2e9) (`lda xhl,
; (Display_FontPalette_Table_0x1ebf:24)`). 816 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_NoteLookup_Table[816].
; -----------------------------------------------------------------------------
AccTone_NoteLookup_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x15EB7, 0x330
; -----------------------------------------------------------------------------
; [naka_s_headers] AccVoice_RomRecords16
; AccVoice_RomRecords16 -- 16 records x 16 bytes.
; AccVoice_CopyFromROM_Do (v10/v9 0xf5c4a3, v7 0xf5c09f): record l (l <
; 16, else 0) is copied with `ldir` of 0x10 bytes to RAM 0x34ab.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccVoice_RomRecords16[16][16].
; -----------------------------------------------------------------------------
AccVoice_RomRecords16:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x161E7, 0x100
; -----------------------------------------------------------------------------
; [naka_s_headers] AccVoice_RomRecords13
; AccVoice_RomRecords13 -- 280 records x 13 bytes (3640 = 280 x 13
; exactly). AccVoice_ComputedCopy (v10/v9 0xf5c0d4, v7 0xf5bcd0): record
; (l * 20 + h) is copied with `ldir` of 0x0d bytes to RAM 0x34ab (the
; same buffer AccVoice_RomRecords16 fills).
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccVoice_RomRecords13[280][13].
; -----------------------------------------------------------------------------
AccVoice_RomRecords13:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x162E7, 0xE38
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_RamImage_1E7800
; AccStyle_RamImage_1E7800 -- Initial image of RAM 0x1e7800..0x1e7fdf:
; AccStyle_InitVRAM (v10/v9 0xf5cd52, v7 0xf5c94e) copies exactly 0x7e0
; bytes from here (`ld xix,0x1e7800; ldw bc,0x7e0; ldir`).
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_RamImage_1E7800[2016].
; -----------------------------------------------------------------------------
AccStyle_RamImage_1E7800:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1711F, 0x7E0
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_RamImage_1E7800_Tail
; AccStyle_RamImage_1E7800_Tail -- 3072 bytes after
; AccStyle_RamImage_1E7800 that no code reference reaches (searched:
; every label and positional-label name anchored on the historical
; labels of this span, in all v10 .s files). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_RamImage_1E7800_Tail[3072].
; -----------------------------------------------------------------------------
AccStyle_RamImage_1E7800_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x178FF, 0xC00
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_VelocityTableMain
; AccStyle_VelocityTableMain -- 128 x 8 u16.
; AccStyle_LookupVelocityTable (v10/v9 0xf55c4f, v7 0xf5584b), for byte
; 0x90ea < 128: index = 0x90ea * 8 + (byte 0x90eb & 7); the word goes to
; 0x90ee/0x90ef.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AccStyle_VelocityTableMain[128][8].
; -----------------------------------------------------------------------------
AccStyle_VelocityTableMain:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x184FF, 0x800
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_TempoWordTable
; AccStyle_TempoWordTable -- 378 u16. AccStyle_LookupTempo_AddAndStore
; (v10/v9 0xf55c17, v7 0xf55813): index =
; AccStyle_TempoMultiplierTable[byte 0x90ea] + (byte 0x90eb, forced to 0
; above 0x4f); the word goes to 0x90ee/0x90ef. The extent is to the next
; referenced object; the index range was not bounded exactly.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AccStyle_TempoWordTable[378].
; -----------------------------------------------------------------------------
AccStyle_TempoWordTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x18CFF, 0x2F4
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_VelocityTableExt
; AccStyle_VelocityTableExt -- 16 x 8 u16. AccStyle_Velocity_ExtClamp
; (v10/v9 0xf55c90, v7 0xf5588c), for 128 <= byte 0x90ea < 240: row =
; 0x90ea & 0x7f (0 if above 0x0b), column = byte 0x90eb & 7 -- so rows
; 0..11 are reachable.
;
; Typed in naka_widget_descriptors.c as uint16_t
; AccStyle_VelocityTableExt[16][8].
; -----------------------------------------------------------------------------
AccStyle_VelocityTableExt:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x18FF3, 0x100
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_VelocityTableHigh
; AccStyle_VelocityTableHigh -- 5 u16. AccStyle_Velocity_HighClamp
; (v10/v9 0xf55cba, v7 0xf558b6), for byte 0x90ea >= 240: index = 0x90ea
; & 0x0f (0 if above 4).
;
; Typed in naka_widget_descriptors.c as uint16_t
; AccStyle_VelocityTableHigh[5].
; -----------------------------------------------------------------------------
AccStyle_VelocityTableHigh:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x190F3, 0xA
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_VelocityTableHigh_Tail
; AccStyle_VelocityTableHigh_Tail -- 23 bytes after
; AccStyle_VelocityTableHigh that no code reference reaches (searched:
; every label and positional-label name anchored on the historical
; labels of this span, in all v10 .s files). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccStyle_VelocityTableHigh_Tail[23].
; -----------------------------------------------------------------------------
AccStyle_VelocityTableHigh_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x190FD, 0x17
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_ExtendAndDispatch_Body_Table
; AccTone_ExtendAndDispatch_Body_Table -- read by
; AccTone_ExtendAndDispatch_Body (v10/v9 0xf5d740, v7 0xf5d33c) (`lda
; xiz, (Display_FontPalette_Table_0x511c:24)`). 32 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_ExtendAndDispatch_Body_Table[32].
; -----------------------------------------------------------------------------
AccTone_ExtendAndDispatch_Body_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19114, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_ExtendAndDispatch_Body_Table_2
; AccTone_ExtendAndDispatch_Body_Table_2 -- read by
; AccTone_ExtendAndDispatch_Body (v10/v9 0xf5d740, v7 0xf5d33c) (`lda
; xde, (Display_FontPalette_Table_0x513c:24)`),
; AccTone_FoundMatch_IncRet (v10/v9 0xf5d7f4, v7 0xf5d3f0) (`lda xde,
; (Display_FontPalette_Table_0x513c:24)`). 32 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_ExtendAndDispatch_Body_Table_2[32].
; -----------------------------------------------------------------------------
AccTone_ExtendAndDispatch_Body_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19134, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_LookupByProgram_Table_2
; AccTone_LookupByProgram_Table_2 -- read by AccTone_LookupByProgram
; (v10/v9 0xf5d640, v7 0xf5d23c) (`lda xbc,
; (Display_FontPalette_Table_0x515c:24)`), AccTone_Process_UnderF0
; (v10/v9 0xf5d6cb, v7 0xf5d2c7) (`lda xbc,
; (Display_FontPalette_Table_0x515c:24)`). 20 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_LookupByProgram_Table_2[20].
; -----------------------------------------------------------------------------
AccTone_LookupByProgram_Table_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19154, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTuning_ReadAndApplyOffset_Table
; AccTuning_ReadAndApplyOffset_Table -- read by
; AccTuning_ReadAndApplyOffset (v10/v9 0xf5e393, v7 0xf5df8f) (`lda xbc,
; (Display_FontPalette_Table_0x5170:24)`). 116 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTuning_ReadAndApplyOffset_Table[116].
; -----------------------------------------------------------------------------
AccTuning_ReadAndApplyOffset_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19168, 0x74
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_ExtendAndDispatch_Body_Table_3
; AccTone_ExtendAndDispatch_Body_Table_3 -- read by
; AccTone_ExtendAndDispatch_Body (v10/v9 0xf5d740, v7 0xf5d33c) (`lda
; xde, (Display_FontPalette_Table_0x51e4:24)`). 4 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_ExtendAndDispatch_Body_Table_3[4].
; -----------------------------------------------------------------------------
AccTone_ExtendAndDispatch_Body_Table_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x191DC, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] AccTone_ExtendAndDispatch_PopRet_Table
; AccTone_ExtendAndDispatch_PopRet_Table -- read by
; AccTone_ExtendAndDispatch_PopRet (v10/v9 0xf5d7c1, v7 0xf5d3bd) (`lda
; xde, (Display_FontPalette_Table_0x51e8:24)`). 4 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccTone_ExtendAndDispatch_PopRet_Table[4].
; -----------------------------------------------------------------------------
AccTone_ExtendAndDispatch_PopRet_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x191E0, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TimeSig_ProcTable
; TimeSig_ProcTable -- 24 u32 code addresses (Tempo_AdjustStartMeasure,
; Tempo_AdjustEndMeasure, Tempo_AdjustQuantize, Tempo_AdjustEffect,
; ...). TimeSig_DisplayStrings (v10/v9 0xf65909, v7 0xf65505): `ld
; xde,<this>; add xde,xbc; ld xhl,(xde); call (xhl)`.
;
; Typed in naka_widget_descriptors.c as uint32_t TimeSig_ProcTable[24].
; -----------------------------------------------------------------------------
TimeSig_ProcTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x191E4, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] Tempo_AdjustEffect_Table
; Tempo_AdjustEffect_Table -- read by Tempo_AdjustEffect (v10/v9
; 0xf66346, v7 0xf65f42) (`lda xbc,
; (Display_FontPalette_Table_0x524c:24)`). 20 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Tempo_AdjustEffect_Table[20].
; -----------------------------------------------------------------------------
Tempo_AdjustEffect_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19244, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Tempo_DisplayBPMReturn_LocalInit
; Tempo_DisplayBPMReturn_LocalInit -- initializer of a local array:
; Tempo_DisplayBPMReturn (v10/v9 0xf66779, v7 0xf66375) (`ld xiy,
; Display_FontPalette_Table_0x5260`); `lda xix, (xsp + 6); ldw bc, 0x8;
; ldirw` copies 16 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; Tempo_DisplayBPMReturn_LocalInit[8].
; -----------------------------------------------------------------------------
Tempo_DisplayBPMReturn_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19258, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] Tempo_RefreshDisplay5_Table
; Tempo_RefreshDisplay5_Table -- read by Tempo_RefreshDisplay5 (v10/v9
; 0xf66899, v7 0xf66495) (`lda xbc,
; (Display_FontPalette_Table_0x5270:24)`). 80 bytes to the next
; referenced object; the layout beyond that access is not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; Tempo_RefreshDisplay5_Table[80].
; -----------------------------------------------------------------------------
Tempo_RefreshDisplay5_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19268, 0x50
; -----------------------------------------------------------------------------
; [naka_s_headers] VoiceSlot_Dispatch_CaseTable
; VoiceSlot_Dispatch_CaseTable -- jump table of a compiled `switch` in
; VoiceSlot_Dispatch (v10/v9 0xf66e99, v7 0xf66a95) (`lda xix,
; (Display_FontPalette_Table_0x52c0:24)`): case k jumps to
; Voice_ClearSlotAndRet + entry[k] (`lda xix,(Voice_ClearSlotAndRet);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; VoiceSlot_Dispatch_CaseTable[7].
; -----------------------------------------------------------------------------
VoiceSlot_Dispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x192B8, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] RhythmParam_Dispatch_CaseTable
; RhythmParam_Dispatch_CaseTable -- jump table of a compiled `switch` in
; RhythmParam_Dispatch (v10/v9 0xf66d36, v7 0xf66932) (`lda xix,
; (Display_FontPalette_Table_0x52ce:24)`): case k jumps to
; RhythmParam_CheckExit + entry[k] (`lda xix,(RhythmParam_CheckExit);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; RhythmParam_Dispatch_CaseTable[7].
; -----------------------------------------------------------------------------
RhythmParam_Dispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x192C6, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] AccRhythm_Ram3888_Records
; AccRhythm_Ram3888_Records -- 10 records x 16 bytes. The code after the
; label __pad_F67459 (sequencer/accompaniment_engine.s): `ld xiy,<this>;
; add xiy,xwa; ld xix,0x3888; ld xbc,0x10; ldir` -- one record is copied
; to RAM 0x3888. 160 = 10 x 16 is the extent to the next referenced
; object.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccRhythm_Ram3888_Records[10][16].
; -----------------------------------------------------------------------------
AccRhythm_Ram3888_Records:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x192D4, 0xA0
; -----------------------------------------------------------------------------
; [naka_s_headers] RhythmDrum_EntryCounts
; RhythmDrum_EntryCounts -- 7 x 10 byte counts.
; RhythmDrum_LoadVoiceParams (v10/v9 0xf6710b, v7 0xf66d07) and
; DrumParam_ReadMaxCount (v10/v9 0xf674d4, v7 0xf670d0) index it with
; drum * 10 + (byte 0x37ab + drum); VoiceAssign_ProcessRequest (v10/v9
; 0xf67128, v7 0xf66d24) sums the counts before an index to find that
; group's start in RhythmDrum_Entries. The counts sum to 1718, exactly
; the size of RhythmDrum_Entries.
;
; Typed in naka_widget_descriptors.c as uint8_t
; RhythmDrum_EntryCounts[7][10].
; -----------------------------------------------------------------------------
RhythmDrum_EntryCounts:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x19374, 0x46
; -----------------------------------------------------------------------------
; [naka_s_headers] RhythmDrum_Entries
; RhythmDrum_Entries -- 1718 u32 in 70 consecutive groups whose sizes
; are RhythmDrum_EntryCounts (sum 1718 = 6872 / 4 -- the layout is
; pinned by that sum). VoiceAssign_ProcessRequest (v10/v9 0xf67128, v7
; 0xf66d24): xde = (sum of the counts before the group + byte 0x37b2 +
; drum) * 4; `ld xhl,(<this>+xde)`. The values (0x100, 0x10100, 0x20100,
; ...) are not addresses; their field meaning is not established.
;
; Typed in naka_widget_descriptors.c as uint32_t
; RhythmDrum_Entries[1718].
; -----------------------------------------------------------------------------
RhythmDrum_Entries:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x193BA, 0x1AD8
; -----------------------------------------------------------------------------
; [naka_s_headers] AccVoice_SlotRows
; AccVoice_SlotRows -- 3 rows x 128 bytes. The code after
; AccVoice_SetupSlots_DataBlock: `sll de,7; add xde,<this>; ld
; c,(xde+a)` -- row de, column a. Meaning of the bytes not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccVoice_SlotRows[3][128].
; -----------------------------------------------------------------------------
AccVoice_SlotRows:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1AE92, 0x180
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpMenuTtlFunc_CaseTable
; CmpMenuTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpMenuTtlFunc (v10/v9 0xf67dd0, v7 0xf679cc) (`add xde,
; Display_FontPalette_Table_0x701a`): case k jumps to
; CmpMenuTtl_Dispatch + entry[k] (`lda xix,(CmpMenuTtl_Dispatch);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpMenuTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpMenuTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B012, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpSetTtl_DynamicLookup_CaseTable
; CmpSetTtl_DynamicLookup_CaseTable -- jump table of a compiled `switch`
; in CmpSetTtl_DynamicLookup (v10/v9 0xf67f79, v7 0xf67b75) (`add xde,
; Display_FontPalette_Table_0x7028`): case k jumps to
; CmpSetTtl_Dispatch2 + entry[k] (`lda xix,(CmpSetTtl_Dispatch2);
; jp_ind`). 12 u16 offsets; the reader's bound `cp ..., 11` pins 12
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpSetTtl_DynamicLookup_CaseTable[12].
; -----------------------------------------------------------------------------
CmpSetTtl_DynamicLookup_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B020, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpSetTtlFunc_CaseTable
; CmpSetTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpSetTtlFunc (v10/v9 0xf67e59, v7 0xf67a55) (`add xde,
; Display_FontPalette_Table_0x7040`): case k jumps to CmpSetTtl_Dispatch
; + entry[k] (`lda xix,(CmpSetTtl_Dispatch); jp_ind`). 7 u16 offsets;
; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpSetTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpSetTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B038, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpRealTtl_MajorDispatch_CaseTable
; CmpRealTtl_MajorDispatch_CaseTable -- jump table of a compiled
; `switch` in CmpRealTtl_MajorDispatch (v10/v9 0xf68048, v7 0xf67c44)
; (`add xwa, Display_FontPalette_Table_0x704e`): case k jumps to
; CmpRealTtl_RhythmVar0 + entry[k] (`lda xix,(CmpRealTtl_RhythmVar0);
; jp_ind`). 13 u16 offsets; the reader's bound `cp ..., 12` pins 13
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpRealTtl_MajorDispatch_CaseTable[13].
; -----------------------------------------------------------------------------
CmpRealTtl_MajorDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B046, 0x1A
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpRealTtlFunc_CaseTable
; CmpRealTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpRealTtlFunc (v10/v9 0xf67fee, v7 0xf67bea) (`add xde,
; Display_FontPalette_Table_0x7068`): case k jumps to
; CmpRealTtl_Dispatch + entry[k] (`lda xix,(CmpRealTtl_Dispatch);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpRealTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpRealTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B060, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpBkslTtlFunc_CaseTable
; CmpBkslTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpBkslTtlFunc (v10/v9 0xf682e2, v7 0xf67ede) (`add xde,
; Display_FontPalette_Table_0x7076`): case k jumps to
; CmpBkslTtl_Dispatch + entry[k] (`lda xix,(CmpBkslTtl_Dispatch);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpBkslTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpBkslTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B06E, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpBkslSTtl_DirectMode_CaseTable
; CmpBkslSTtl_DirectMode_CaseTable -- jump table of a compiled `switch`
; in CmpBkslSTtl_DirectMode (v10/v9 0xf684bf, v7 0xf680bb) (`add xwa,
; Display_FontPalette_Table_0x7084`): case k jumps to
; CmpBkslSTtl_FillIn4 + entry[k] (`lda xix,(CmpBkslSTtl_FillIn4);
; jp_ind`). 11 u16 offsets; the reader's bound `cp ..., 10` pins 11
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpBkslSTtl_DirectMode_CaseTable[11].
; -----------------------------------------------------------------------------
CmpBkslSTtl_DirectMode_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B07C, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpBksl_STtlFunc_CaseTable
; CmpBksl_STtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpBksl_STtlFunc (v10/v9 0xf6845b, v7 0xf68057) (`add xde,
; Display_FontPalette_Table_0x709a`): case k jumps to
; CmpBkslSTtl_Dispatch + entry[k] (`lda xix,(CmpBkslSTtl_Dispatch);
; jp_ind`). 7 u16 offsets; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpBksl_STtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpBksl_STtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B092, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpNcpTtl_TableDispatch_CaseTable
; CmpNcpTtl_TableDispatch_CaseTable -- jump table of a compiled `switch`
; in CmpNcpTtl_TableDispatch (v10/v9 0xf686e3, v7 0xf682df) (`add xde,
; Display_FontPalette_Table_0x70a8`): case k jumps to
; CmpNcpTtl_Dispatch2 + entry[k] (`lda xix,(CmpNcpTtl_Dispatch2);
; jp_ind`). 20 u16 offsets; the reader's bound `cp ..., 19` pins 20
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpNcpTtl_TableDispatch_CaseTable[20].
; -----------------------------------------------------------------------------
CmpNcpTtl_TableDispatch_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B0A0, 0x28
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpNcpTtlFunc_CaseTable
; CmpNcpTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmpNcpTtlFunc (v10/v9 0xf685f9, v7 0xf681f5) (`add xde,
; Display_FontPalette_Table_0x70d0`): case k jumps to CmpNcpTtl_Dispatch
; + entry[k] (`lda xix,(CmpNcpTtl_Dispatch); jp_ind`). 7 u16 offsets;
; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpNcpTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmpNcpTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B0C8, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpEsyTtl_Mode2_Table
; CmpEsyTtl_Mode2_Table -- read by CmpEsyTtl_Mode2 (v10/v9 0xf68cfb, v7
; 0xf688f7) (`add xde, Display_FontPalette_Table_0x70de`). 20 bytes to
; the next referenced object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; CmpEsyTtl_Mode2_Table[20].
; -----------------------------------------------------------------------------
CmpEsyTtl_Mode2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B0D6, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpEsyTtl_Mode2_CaseTable
; CmpEsyTtl_Mode2_CaseTable -- jump table of a compiled `switch` in
; CmpEsyTtl_Mode2 (v10/v9 0xf68cfb, v7 0xf688f7) (`ld xix,
; Display_FontPalette_Table_0x70f2`): case k jumps to CmEsyTtl_Dispatch2
; + entry[k] (`lda xix,(CmEsyTtl_Dispatch2); jp_ind`). 6 u16 offsets;
; the reader's bound is not visible in the source (the code after the
; load is still misframed), so the 6 entries are the extent to the next
; referenced object.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpEsyTtl_Mode2_CaseTable[6].
; -----------------------------------------------------------------------------
CmpEsyTtl_Mode2_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B0EA, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] CmEsyTtlFunc_CaseTable
; CmEsyTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CmEsyTtlFunc (v10/v9 0xf68c19, v7 0xf68815) (`add xde,
; Display_FontPalette_Table_0x70fe`): case k jumps to CmEsyTtl_Dispatch
; + entry[k] (`lda xix,(CmEsyTtl_Dispatch); jp_ind`). 7 u16 offsets; the
; reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmEsyTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CmEsyTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B0F6, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpEsyTtl_E_Var1_CaseTable
; CmpEsyTtl_E_Var1_CaseTable -- jump table of a compiled `switch` in
; CmpEsyTtl_E_Var1 (v10/v9 0xf68e86, v7 0xf68a82) (`add xwa,
; Display_FontPalette_Table_0x710c`): case k jumps to
; CmpEsy_E_DispatchDataBlock + entry[k] (`lda
; xix,(CmpEsy_E_DispatchDataBlock); jp_ind`). 12 u16 offsets; the
; reader's bound `cp ..., 11` pins 12 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CmpEsyTtl_E_Var1_CaseTable[12].
; -----------------------------------------------------------------------------
CmpEsyTtl_E_Var1_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B104, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] S2cTtlFunc_CaseTable
; S2cTtlFunc_CaseTable -- jump table of a compiled `switch` in
; S2cTtlFunc (v10/v9 0xf68de2, v7 0xf689de) (`add xde,
; Display_FontPalette_Table_0x7124`): case k jumps to S2cTtl_Dispatch +
; entry[k] (`lda xix,(S2cTtl_Dispatch); jp_ind`). 7 u16 offsets; the
; reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; S2cTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
S2cTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B11C, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] CstmCpTtl_RecMode2_CaseTable
; CstmCpTtl_RecMode2_CaseTable -- jump table of a compiled `switch` in
; CstmCpTtl_RecMode2 (v10/v9 0xf692fc, v7 0xf68ef8) (`add xde,
; Display_FontPalette_Table_0x7132`): case k jumps to
; CstmCpTtl_Dispatch2 + entry[k] (`lda xix,(CstmCpTtl_Dispatch2);
; jp_ind`). 20 u16 offsets; the reader's bound `cp ..., 19` pins 20
; cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CstmCpTtl_RecMode2_CaseTable[20].
; -----------------------------------------------------------------------------
CstmCpTtl_RecMode2_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B12A, 0x28
; -----------------------------------------------------------------------------
; [naka_s_headers] CstmCpTtlFunc_CaseTable
; CstmCpTtlFunc_CaseTable -- jump table of a compiled `switch` in
; CstmCpTtlFunc (v10/v9 0xf69227, v7 0xf68e23) (`add xde,
; Display_FontPalette_Table_0x715a`): case k jumps to CstmCpTtl_Dispatch
; + entry[k] (`lda xix,(CstmCpTtl_Dispatch); jp_ind`). 7 u16 offsets;
; the reader's bound `cp ..., 6` pins 7 cases.
;
; Typed in naka_widget_descriptors.c as uint16_t
; CstmCpTtlFunc_CaseTable[7].
; -----------------------------------------------------------------------------
CstmCpTtlFunc_CaseTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B152, 0xE
; -----------------------------------------------------------------------------
; [naka_s_headers] MainCstmNameFunc_LocalInit
; MainCstmNameFunc_LocalInit -- initializer of a local array:
; MainCstmNameFunc (v10/v9 0xf695ca, v7 0xf691c6) (`ld xiy,
; Display_FontPalette_Table_0x7168`); `lda xix, (xsp + 4); ldw bc, 0x3c;
; ldirw` copies 120 bytes into the routine's stack frame.
;
; Typed in naka_widget_descriptors.c as uint16_t
; MainCstmNameFunc_LocalInit[60].
; -----------------------------------------------------------------------------
MainCstmNameFunc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B160, 0x78
; -----------------------------------------------------------------------------
; [naka_s_headers] MainCmpCpFunc_LocalInit
; MainCmpCpFunc_LocalInit -- Initializer of a local array of three
; string pointers -- " MEMORY-A ", " MEMORY-B ", " MEMORY-C "
; (NakaInst_MEMORY_A/B/C, which follow). MainCmpCpFunc (v10/v9 0xf6985d,
; v7 0xf69459): `ld xiy,<this>; lda xix,(xsp+10); ld bc,6; ldirw` copies
; the 12 bytes into its stack frame.
;
; Typed in naka_widget_descriptors.c as uint32_t
; MainCmpCpFunc_LocalInit[3].
; -----------------------------------------------------------------------------
MainCmpCpFunc_LocalInit:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B1D8, 0xC
NakaInst_MEMORY_C:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B1E4, 0xE
NakaInst_MEMORY_B:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B1F2, 0xE
NakaInst_MEMORY_A:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B200, 0x62
NakaInst_DashDash:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B262, 0xC
NakaInst_ON_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B26E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaInst_OFF_Str
; NakaInst_OFF_Str -- "OFF". With "ON " just before it, the pair is
; pointed at by the 2-entry table at NakaInst_DashDash+4 that
; SndArgNmGet copies to its frame. Everything after it up to the
; ApFunction table (0xe55210) was part of this label's .s slice and is
; typed below.
;
; Typed in naka_widget_descriptors.c as char NakaInst_OFF_Str[4].
; -----------------------------------------------------------------------------
NakaInst_OFF_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B272, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] SndArgNmGet_Bytes5
; SndArgNmGet_Bytes5 (+0x04, ROM 0xe4c0d6): SndArgNmGet (v10/v9
; 0xf6a0bb, v7 0xf69cb7): ld xiy,<this>; ld bc,2; ldirw; ldi -- copies
; the first 5 bytes to its frame; the 6th is 0xff padding.
;
; Typed in naka_widget_descriptors.c as uint8_t SndArgNmGet_Bytes5[6].
; -----------------------------------------------------------------------------
SndArgNmGet_Bytes5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B276, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] SndArgNmGet_RamPtrsA
; SndArgNmGet_RamPtrsA (+0x0a, ROM 0xe4c0dc): SndArgNmGet (v10/v9
; 0xf6a0bb, v7 0xf69cb7): ldirw 10 words to its frame. Five RAM
; addresses, 0x39f8 + 0x11*k (v7 applies -0x9c through
; v7_c_divergence.json).
;
; Typed in naka_widget_descriptors.c as uint32_t
; SndArgNmGet_RamPtrsA[5].
; -----------------------------------------------------------------------------
SndArgNmGet_RamPtrsA:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B27C, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] SndArgNmGet_RamPtrsB
; SndArgNmGet_RamPtrsB (+0x1e, ROM 0xe4c0f0): SndArgNmGet (v10/v9
; 0xf6a0bb, v7 0xf69cb7): ldirw 10 words. Five RAM addresses 0x39e4 +
; 4*k.
;
; Typed in naka_widget_descriptors.c as uint32_t
; SndArgNmGet_RamPtrsB[5].
; -----------------------------------------------------------------------------
SndArgNmGet_RamPtrsB:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B290, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] CmpStepTitleFunc_ProcTable
; CmpStepTitleFunc_ProcTable (+0x32, ROM 0xe4c104): CmpStepTitleFunc
; (v10/v9 0xf6a2e2, v7 0xf69ede): ldirw 8 words to its frame and passes
; the copy to DirmdEmulator_Entry (v10/v9 0xf9ae97, v7 0xf9aa8a). Four
; code addresses inside CmpStepTitleFunc's own region (0xf6a2ff =
; CmpStep_DataBlock, 0xf6a32c, 0xf6a339, 0xf6a346 in v10/v9; v7
; relocates them by -0x404 through v7_c_divergence.json) -- code entry
; points that the accompaniment_engine.s framing does not yet show as
; code.
;
; Typed in naka_widget_descriptors.c as uint32_t
; CmpStepTitleFunc_ProcTable[4].
; -----------------------------------------------------------------------------
CmpStepTitleFunc_ProcTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2A4, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] AccBankData_SlotOrder
; AccBankData_SlotOrder (+0x42, ROM 0xe4c114): AccBankData_SlotScan_Loop
; (v10/v9 0xf6befd, v7 0xf6baf9): lda xwa,<this> and indexes it with
; 3*slot + bank. Entries 0-11 are 0,4,8,1,5,9,2,6,10,3,7,11 and 12-29
; are 12,18,24,13,19,25,...: a column-major renumbering.
;
; Typed in naka_widget_descriptors.c as uint8_t
; AccBankData_SlotOrder[30].
; -----------------------------------------------------------------------------
AccBankData_SlotOrder:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2B4, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnvModl_CnvFilter
; StylCnvModl_CnvFilter (+0x60, ROM 0xe4c132): StylCnvModlTtlFunc
; (v10/v9 0xf6c229, v7 0xf6be25): ld xwa,<this>; call
; ControlState_ProcessCommand (v10/v9 0xf8ad25, v7 0xf8a918). u16 2,
; then "*.CNV,***" -- a file-selector filter.
;
; Typed in naka_widget_descriptors.c as uint8_t
; StylCnvModl_CnvFilter[12].
; -----------------------------------------------------------------------------
StylCnvModl_CnvFilter:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2D2, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnvModl_VerFilter
; StylCnvModl_VerFilter (+0x6c, ROM 0xe4c13e):
; StylCnvModl_ClearDisplayBuf (v10/v9 0xf6c323, v7 0xf6bf1f): ld
; xwa,<this>; call ControlState_ProcessCommand. u16 2, then "*.VER,***".
;
; Typed in naka_widget_descriptors.c as uint8_t
; StylCnvModl_VerFilter[12].
; -----------------------------------------------------------------------------
StylCnvModl_VerFilter:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2DE, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Select
; StylCnv_ModeRb_Select (+0x78, ROM 0xe4c14a): StylCnvModl_OK_SelectItem
; (v10/v9 0xf6c543, v7 0xf6c13f): ld xbc,<this>; call
; FileIO_OpenWithBuiltPath (v10/v9 0xf8ac27, v7 0xf8a81a) -- the
; fopen-style mode "rb".
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Select[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Select:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2EA, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_Str_Stars
; StylCnv_Str_Stars (+0x7c, ROM 0xe4c14e): "***": no reader found
; (searched: label and 24-bit operand forms of 0xe4c14e across the v10
; ROM).
;
; Typed in naka_widget_descriptors.c as char StylCnv_Str_Stars[4].
; -----------------------------------------------------------------------------
StylCnv_Str_Stars:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2EE, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Type3
; StylCnv_ModeRb_Type3 (+0x80, ROM 0xe4c152): StylCnv_Type3_LoadFileLoop
; (v10/v9 0xf6d029, v7 0xf6cc25): mode "rb" for
; FileIO_OpenWithBuiltPath.
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Type3[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Type3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2F2, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Type4
; StylCnv_ModeRb_Type4 (+0x84, ROM 0xe4c156): StylCnv_Type4_OpenFile
; (v10/v9 0xf6d198, v7 0xf6cd94): mode "rb" for FileIO_OpenWithMode
; (v10/v9 0xf88bc7, v7 0xf887ba).
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Type4[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Type4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2F6, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Type6
; StylCnv_ModeRb_Type6 (+0x88, ROM 0xe4c15a): StylCnv_Type6_AppendName
; (v10/v9 0xf6d2a9, v7 0xf6cea5): mode "rb".
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Type6[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Type6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2FA, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Type6b
; StylCnv_ModeRb_Type6b (+0x8c, ROM 0xe4c15e):
; StylCnv_Type6_Case1_CopyName (v10/v9 0xf6d431, v7 0xf6d02d): mode
; "rb".
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Type6b[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Type6b:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B2FE, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_Single
; StylCnv_ModeRb_Single (+0x90, ROM 0xe4c162):
; StylCnv_Single_WriteTMExtension (v10/v9 0xf6d50a, v7 0xf6d106): mode
; "rb".
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_Single[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_Single:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B302, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] StylCnv_ModeRb_LSW
; StylCnv_ModeRb_LSW (+0x94, ROM 0xe4c166): StylCnv_LSW_WriteExtension
; (v10/v9 0xf6d5e4, v7 0xf6d1e0): mode "rb".
;
; Typed in naka_widget_descriptors.c as char StylCnv_ModeRb_LSW[4].
; -----------------------------------------------------------------------------
StylCnv_ModeRb_LSW:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B306, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_SlotOrderA
; AccStyle_SlotOrderA (+0x98, ROM 0xe4c16a): Byte-identical to
; AccBankData_SlotOrder. The code after AccStyle_TableDataEntry_Skip12
; (v10 0xf6d9ca, v9 0xf6d9ca, not labelled in v7) adds <this> to (a -
; 30) and AccStyle_TableDataEntry_Skip15 (v10 0xf6dab3, v9 0xf6dab3, not
; labelled in v7) loads it with lda.
;
; Typed in naka_widget_descriptors.c as uint8_t AccStyle_SlotOrderA[30].
; -----------------------------------------------------------------------------
AccStyle_SlotOrderA:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B30A, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] AccStyle_SlotOrderB
; AccStyle_SlotOrderB (+0xb6, ROM 0xe4c188):
; AccStyle_TableDataEntry_Join (v10 0xf6d8d8, v9 0xf6d8d8, not labelled
; in v7): ld xiy,<this>; ldirw 15 words to its frame. Rows of ten:
; {0..3, 12..17}, {4..7, 18..23}, {8..11, 24..29} -- the same slots
; grouped the other way.
;
; Typed in naka_widget_descriptors.c as uint8_t AccStyle_SlotOrderB[30].
; -----------------------------------------------------------------------------
AccStyle_SlotOrderB:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B328, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] AccompSeq_StyleDataTable
; AccompSeq_StyleDataTable (ROM 0xe4c1a6) -- 78 records x 32 bytes, each
; two accseq_part_t (naka_types.h, where every field is tied to the code
; that reads it).
;
; Reader: AccompSeq_LookupStyle_Internal (v10/v9 0xf6e753, v7 0xf6e34f)
; multiplies an index below 0x80 (from Voice_DecodeNoteChannel2 (v10/v9
; 0xf71592, v7 0xf7118e), which maps a program/bank pair through
; Voice_NoteChannelTable2) by 0x20 and adds this table;
; AccompSeq_LoadParams (v10/v9 0xf6e770, v7 0xf6e36c),
; AccompSeq_InitMidiEvents (v10/v9 0xf6e84e, v7 0xf6e44a) and
; AccompSeq_CompareChord (v10/v9 0xf6ece5, v7 0xf6e8e1) read the fields.
; An index of 0x80 or more takes the other branch (0x1e8800 + ...), not
; this table.
;
; Count: the table runs from here to the first stream it points at,
; 0xe4cb66: 0x9c0 bytes = 78 records; every one of the 103 non-null
; stream pointers lands inside the stream block that follows, and every
; stream starts with 80 FF FF FF FF 87.
;
; Typed in naka_widget_descriptors.c as accseq_record_t
; AccompSeq_StyleDataTable[78].
; -----------------------------------------------------------------------------
AccompSeq_StyleDataTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B346, 0x9C0
; -----------------------------------------------------------------------------
; [naka_s_headers] AccompSeq_Streams
; AccompSeq_Stream_RR_P -- the 103 event streams of
; AccompSeq_StyleDataTable, one per used part (RR = record, P = a for
; part 1, b for part 2), in record order, back to back,
; 0xe4cb66..0xe55210. Boundaries are the stream pointers themselves; no
; two parts share a stream.
;
; Format (the ASEQ_* macros in naka_types.h, where each opcode is tied
; to the code that reads it): the header 80 FF FF FF FF 87, which
; AccompSeq_LoadParams skips (`add xwa, 6`), then events -- 0x90 (6 B)
; and 0x91 (8 B) timed events, 0xc0 program (6 B), 0xdn controller n (3
; B), 0x81 end of a 96-tick unit -- and 0x83 end of stream, 0x87 block
; end. Readers: AccompSeq_ParseEvents (v10/v9 0xf6e07a, v7 0xf6dc76),
; AccompSeq_InitEventDispatch (v10/v9 0xf6de14, v7 0xf6da10) and
; AccompSeq_ParseSequenceData (v10/v9 0xf6ee26, v7 0xf6ea22).
;
; Proof of the framing: that grammar consumes every byte of all 103
; streams (3036 x 0x90, 1435 x 0x91, 1284 x 0x81, 740 x 0xdn, 74 x
; 0xc0), each ending 83 87 (one ends 83 81 83 87, the last 83 87 87 87
; 87 87 87 87 up to the ApFunction table); naka_c_retype.py refuses to
; write a stream the grammar does not consume exactly. What the 4/6
; parameter bytes of the 0x90 / 0x91 events mean musically is not named
; here: the consumers copy them to the output buffer unchanged except p1
; (tested against 0x78) and p3 (0 -> 1).
;
; Typed in naka_widget_descriptors.c as one uint8_t array per stream,
; AccompSeq_Stream_00_a .. AccompSeq_Stream_77_b.
; -----------------------------------------------------------------------------
AccompSeq_Streams:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1BD06, 0x86AA
; -----------------------------------------------------------------------------
; [naka_s_headers] MidiMenu_ApFunctionTable
; MidiMenu_ApFunctionTable (ROM 0xe55210) -- 60 procedure addresses and
; a 0 terminator. InitializeEast (v10/v9 0xf72bac, v7 0xf727a8)
; registers it: RegObjTabl 0x1600002, ApFunctionProc, 0x3c, 0xe55210,
; 0x123 (class 0x1600002, 60 objects, ids from 0x123). The procedures
; are the MIDI-menu title and field functions (TtMdmenu, MdPcgModeFunc,
; ... RevEqOnOffFunc).
;
; Typed in naka_widget_descriptors.c as uint32_t
; MidiMenu_ApFunctionTable[61].
; -----------------------------------------------------------------------------
MidiMenu_ApFunctionTable:
	.long TtMdmenu
	.long TtMdRealMsg
	.long MdPcgModeFunc
	.long MdDrumTypeFunc
	.long MdSetupLoadFunc
	.long TtComputerConnection
	.long MdCmptCnctFunc
	.long R12OctaveFunc
	.long TtMdParaLoad
	.long ParaLoadOptGridCheck
	.long ParaLoadOptOKFunc
	.long TtMdPcgOut
	.long PcgOutGridCheck
	.long PcgOutSendFunc
	.long TtComSet
	.long ComSetGridCheck
	.long TtMdPmemOut
	.long PmemOutLGridCheck
	.long PmemOutRGridCheck
	.long TtMdCtlMsg
	.long CtlMsgGridCheck
	.long TtMdPart
	.long MidiPartGridCheck
	.long TtMdExc
	.long ExcSendFunc
	.long ExcDotFunc
	.long ExcPmemFunc
	.long ExcSmemFunc
	.long ExcCompFunc
	.long ExcSeqFunc
	.long ExcMspFunc
	.long TtMdPreset
	.long MdPresetOKFunc
	.long MdPresetWithoutFunc
	.long MdPresetWithFunc
	.long BitmapBmphk
	.long TtMdGm
	.long GMOKFunc
	.long StsAttentionCheck
	.long StsGMOnCheck
	.long StsGMOffCheck
	.long StsAreYouSureCheck
	.long GMYesFunc
	.long GMNoFunc
	.long HarmOnOffFunc
	.long TtVocalistWorkstation
	.long VocalistGridCheck
	.long VocalistPage1OKFunc
	.long VocalistPage2OKFunc
	.long TtFadeInOut
	.long FadeSetGridCheck
	.long TtMdInOut
	.long InOutGridCheck
	.long StsSplitCheck
	.long SplitPointFunc
	.long RevSelFunc
	.long EqSelFunc
	.long EqOnOffFunc
	.long RevEqSelFunc
	.long RevEqOnOffFunc
	.long 0x00000000
; -----------------------------------------------------------------------------
; [naka_s_headers] MidiMenu_ApFunctionNameTable
; MidiMenu_ApFunctionNameTable (ROM 0xe55304) -- the 60 procedures'
; names, in the same order, and a pointer to "" as terminator.
; Registered by the next line of InitializeEast (v10/v9 0xf72bac, v7
; 0xf727a8): RegObjTabl 0x1600002, ApFunctionProc, 0x3c, 0xe55304,
; 0x423. The strings themselves follow, stored in reverse order.
;
; Typed in naka_widget_descriptors.c as uint32_t
; MidiMenu_ApFunctionNameTable[61].
; -----------------------------------------------------------------------------
MidiMenu_ApFunctionNameTable:
	.long NakaInst_TtMdmenu
	.long NakaInst_TtMdRealMsg
	.long NakaInst_MdPcgModeFunc
	.long NakaInst_MdDrumTypeFunc
	.long NakaInst_MdSetupLoadFunc
	.long NakaInst_TtComputerConnection
	.long NakaInst_MdCmptCnctFunc
	.long NakaInst_R12OctaveFunc
	.long NakaInst_TtMdParaLoad
	.long NakaInst_ParaLoadOptGridCheck
	.long NakaInst_ParaLoadOptOKFunc
	.long NakaInst_TtMdPcgOut
	.long NakaInst_PcgOutGridCheck
	.long NakaInst_PcgOutSendFunc
	.long NakaInst_TtComSet
	.long NakaInst_ComSetGridCheck
	.long NakaInst_TtMdPmemOut
	.long NakaInst_PmemOutLGridCheck
	.long NakaInst_PmemOutRGridCheck
	.long NakaInst_TtMdCtlMsg
	.long NakaInst_CtlMsgGridCheck
	.long NakaInst_TtMdPart
	.long NakaInst_MidiPartGridCheck
	.long NakaInst_TtMdExc
	.long NakaInst_ExcSendFunc
	.long NakaInst_ExcDotFunc
	.long NakaInst_ExcPmemFunc
	.long NakaInst_ExcSmemFunc
	.long NakaInst_ExcCompFunc
	.long NakaInst_ExcSeqFunc
	.long NakaInst_ExcMspFunc
	.long NakaInst_TtMdPreset
	.long NakaInst_MdPresetOKFunc
	.long NakaInst_MdPresetWithoutFunc
	.long NakaInst_MdPresetWithFunc
	.long NakaInst_BitmapBmphk
	.long NakaInst_TtMdGm
	.long NakaInst_GMOKFunc
	.long NakaInst_StsAttentionCheck
	.long NakaInst_StsGMOnCheck
	.long NakaInst_StsGMOffCheck
	.long NakaInst_StsAreYouSureCheck
	.long NakaInst_GMYesFunc
	.long NakaInst_GMNoFunc
	.long NakaInst_HarmOnOffFunc
	.long NakaInst_TtVocalistWorkstation
	.long NakaInst_VocalistGridCheck
	.long NakaInst_VocalistPage1OKFunc
	.long NakaInst_VocalistPage2OKFunc
	.long NakaInst_TtFadeInOut
	.long NakaInst_FadeSetGridCheck
	.long NakaInst_TtMdInOut
	.long NakaInst_InOutGridCheck
	.long NakaInst_StsSplitCheck
	.long NakaInst_SplitPointFunc
	.long NakaInst_RevSelFunc
	.long NakaInst_EqSelFunc
	.long NakaInst_EqOnOffFunc
	.long NakaInst_RevEqSelFunc
	.long NakaInst_RevEqOnOffFunc
	.long NakaInst_EmptyFuncName
; [naka_s_headers:short] NakaInst_EmptyFuncName
; Name string of MIDI-menu procedure 60 (""): entry 60 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423. This empty name is the table's terminator.
NakaInst_EmptyFuncName:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24598, 0x2
; [naka_s_headers:short] NakaInst_RevEqOnOffFunc
; Name string of MIDI-menu procedure 59 ("RevEqOnOffFunc"): entry 59 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_RevEqOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2459A, 0x10
; [naka_s_headers:short] NakaInst_RevEqSelFunc
; Name string of MIDI-menu procedure 58 ("RevEqSelFunc"): entry 58 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_RevEqSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245AA, 0xE
; [naka_s_headers:short] NakaInst_EqOnOffFunc
; Name string of MIDI-menu procedure 57 ("EqOnOffFunc"): entry 57 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_EqOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245B8, 0xC
; [naka_s_headers:short] NakaInst_EqSelFunc
; Name string of MIDI-menu procedure 56 ("EqSelFunc"): entry 56 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_EqSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245C4, 0xA
; [naka_s_headers:short] NakaInst_RevSelFunc
; Name string of MIDI-menu procedure 55 ("RevSelFunc"): entry 55 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_RevSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245CE, 0xC
; [naka_s_headers:short] NakaInst_SplitPointFunc
; Name string of MIDI-menu procedure 54 ("SplitPointFunc"): entry 54 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_SplitPointFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245DA, 0x10
; [naka_s_headers:short] NakaInst_StsSplitCheck
; Name string of MIDI-menu procedure 53 ("StsSplitCheck"): entry 53 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_StsSplitCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245EA, 0xE
; [naka_s_headers:short] NakaInst_InOutGridCheck
; Name string of MIDI-menu procedure 52 ("InOutGridCheck"): entry 52 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_InOutGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245F8, 0x10
; [naka_s_headers:short] NakaInst_TtMdInOut
; Name string of MIDI-menu procedure 51 ("TtMdInOut"): entry 51 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdInOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24608, 0xA
; [naka_s_headers:short] NakaInst_FadeSetGridCheck
; Name string of MIDI-menu procedure 50 ("FadeSetGridCheck"): entry 50
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_FadeSetGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24612, 0x12
; [naka_s_headers:short] NakaInst_TtFadeInOut
; Name string of MIDI-menu procedure 49 ("TtFadeInOut"): entry 49 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtFadeInOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24624, 0xC
; [naka_s_headers:short] NakaInst_VocalistPage2OKFunc
; Name string of MIDI-menu procedure 48 ("VocalistPage2OKFunc"): entry
; 48 of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_VocalistPage2OKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24630, 0x14
; [naka_s_headers:short] NakaInst_VocalistPage1OKFunc
; Name string of MIDI-menu procedure 47 ("VocalistPage1OKFunc"): entry
; 47 of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_VocalistPage1OKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24644, 0x14
; [naka_s_headers:short] NakaInst_VocalistGridCheck
; Name string of MIDI-menu procedure 46 ("VocalistGridCheck"): entry 46
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_VocalistGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24658, 0x12
; [naka_s_headers:short] NakaInst_TtVocalistWorkstation
; Name string of MIDI-menu procedure 45 ("TtVocalistWorkstation"): entry
; 45 of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_TtVocalistWorkstation:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2466A, 0x16
; [naka_s_headers:short] NakaInst_HarmOnOffFunc
; Name string of MIDI-menu procedure 44 ("HarmOnOffFunc"): entry 44 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_HarmOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24680, 0xE
; [naka_s_headers:short] NakaInst_GMNoFunc
; Name string of MIDI-menu procedure 43 ("GMNoFunc"): entry 43 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_GMNoFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2468E, 0xA
; [naka_s_headers:short] NakaInst_GMYesFunc
; Name string of MIDI-menu procedure 42 ("GMYesFunc"): entry 42 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_GMYesFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24698, 0xA
; [naka_s_headers:short] NakaInst_StsAreYouSureCheck
; Name string of MIDI-menu procedure 41 ("StsAreYouSureCheck"): entry 41
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_StsAreYouSureCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246A2, 0x14
; [naka_s_headers:short] NakaInst_StsGMOffCheck
; Name string of MIDI-menu procedure 40 ("StsGMOffCheck"): entry 40 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_StsGMOffCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246B6, 0xE
; [naka_s_headers:short] NakaInst_StsGMOnCheck
; Name string of MIDI-menu procedure 39 ("StsGMOnCheck"): entry 39 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_StsGMOnCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246C4, 0xE
; [naka_s_headers:short] NakaInst_StsAttentionCheck
; Name string of MIDI-menu procedure 38 ("StsAttentionCheck"): entry 38
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_StsAttentionCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246D2, 0x12
; [naka_s_headers:short] NakaInst_GMOKFunc
; Name string of MIDI-menu procedure 37 ("GMOKFunc"): entry 37 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_GMOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246E4, 0xA
; [naka_s_headers:short] NakaInst_TtMdGm
; Name string of MIDI-menu procedure 36 ("TtMdGm"): entry 36 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdGm:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246EE, 0x8
; [naka_s_headers:short] NakaInst_BitmapBmphk
; Name string of MIDI-menu procedure 35 ("BitmapBmphk"): entry 35 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_BitmapBmphk:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246F6, 0xC
; [naka_s_headers:short] NakaInst_MdPresetWithFunc
; Name string of MIDI-menu procedure 34 ("MdPresetWithFunc"): entry 34
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_MdPresetWithFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24702, 0x12
; [naka_s_headers:short] NakaInst_MdPresetWithoutFunc
; Name string of MIDI-menu procedure 33 ("MdPresetWithoutFunc"): entry
; 33 of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_MdPresetWithoutFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24714, 0x14
; [naka_s_headers:short] NakaInst_MdPresetOKFunc
; Name string of MIDI-menu procedure 32 ("MdPresetOKFunc"): entry 32 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_MdPresetOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24728, 0x10
; [naka_s_headers:short] NakaInst_TtMdPreset
; Name string of MIDI-menu procedure 31 ("TtMdPreset"): entry 31 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdPreset:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24738, 0xC
; [naka_s_headers:short] NakaInst_ExcMspFunc
; Name string of MIDI-menu procedure 30 ("ExcMspFunc"): entry 30 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcMspFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24744, 0xC
; [naka_s_headers:short] NakaInst_ExcSeqFunc
; Name string of MIDI-menu procedure 29 ("ExcSeqFunc"): entry 29 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcSeqFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24750, 0xC
; [naka_s_headers:short] NakaInst_ExcCompFunc
; Name string of MIDI-menu procedure 28 ("ExcCompFunc"): entry 28 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcCompFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2475C, 0xC
; [naka_s_headers:short] NakaInst_ExcSmemFunc
; Name string of MIDI-menu procedure 27 ("ExcSmemFunc"): entry 27 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcSmemFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24768, 0xC
; [naka_s_headers:short] NakaInst_ExcPmemFunc
; Name string of MIDI-menu procedure 26 ("ExcPmemFunc"): entry 26 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcPmemFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24774, 0xC
; [naka_s_headers:short] NakaInst_ExcDotFunc
; Name string of MIDI-menu procedure 25 ("ExcDotFunc"): entry 25 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcDotFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24780, 0xC
; [naka_s_headers:short] NakaInst_ExcSendFunc
; Name string of MIDI-menu procedure 24 ("ExcSendFunc"): entry 24 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ExcSendFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2478C, 0xC
; [naka_s_headers:short] NakaInst_TtMdExc
; Name string of MIDI-menu procedure 23 ("TtMdExc"): entry 23 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdExc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24798, 0x8
; [naka_s_headers:short] NakaInst_MidiPartGridCheck
; Name string of MIDI-menu procedure 22 ("MidiPartGridCheck"): entry 22
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_MidiPartGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247A0, 0x12
; [naka_s_headers:short] NakaInst_TtMdPart
; Name string of MIDI-menu procedure 21 ("TtMdPart"): entry 21 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdPart:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247B2, 0xA
; [naka_s_headers:short] NakaInst_CtlMsgGridCheck
; Name string of MIDI-menu procedure 20 ("CtlMsgGridCheck"): entry 20 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_CtlMsgGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247BC, 0x10
; [naka_s_headers:short] NakaInst_TtMdCtlMsg
; Name string of MIDI-menu procedure 19 ("TtMdCtlMsg"): entry 19 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdCtlMsg:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247CC, 0xC
; [naka_s_headers:short] NakaInst_PmemOutRGridCheck
; Name string of MIDI-menu procedure 18 ("PmemOutRGridCheck"): entry 18
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_PmemOutRGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247D8, 0x12
; [naka_s_headers:short] NakaInst_PmemOutLGridCheck
; Name string of MIDI-menu procedure 17 ("PmemOutLGridCheck"): entry 17
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_PmemOutLGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247EA, 0x12
; [naka_s_headers:short] NakaInst_TtMdPmemOut
; Name string of MIDI-menu procedure 16 ("TtMdPmemOut"): entry 16 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdPmemOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247FC, 0xC
; [naka_s_headers:short] NakaInst_ComSetGridCheck
; Name string of MIDI-menu procedure 15 ("ComSetGridCheck"): entry 15 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_ComSetGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24808, 0x10
; [naka_s_headers:short] NakaInst_TtComSet
; Name string of MIDI-menu procedure 14 ("TtComSet"): entry 14 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtComSet:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24818, 0xA
; [naka_s_headers:short] NakaInst_PcgOutSendFunc
; Name string of MIDI-menu procedure 13 ("PcgOutSendFunc"): entry 13 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_PcgOutSendFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24822, 0x10
; [naka_s_headers:short] NakaInst_PcgOutGridCheck
; Name string of MIDI-menu procedure 12 ("PcgOutGridCheck"): entry 12 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_PcgOutGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24832, 0x10
; [naka_s_headers:short] NakaInst_TtMdPcgOut
; Name string of MIDI-menu procedure 11 ("TtMdPcgOut"): entry 11 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdPcgOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24842, 0xC
; [naka_s_headers:short] NakaInst_ParaLoadOptOKFunc
; Name string of MIDI-menu procedure 10 ("ParaLoadOptOKFunc"): entry 10
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_ParaLoadOptOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2484E, 0x12
; [naka_s_headers:short] NakaInst_ParaLoadOptGridCheck
; Name string of MIDI-menu procedure 9 ("ParaLoadOptGridCheck"): entry 9
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_ParaLoadOptGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24860, 0x16
; [naka_s_headers:short] NakaInst_TtMdParaLoad
; Name string of MIDI-menu procedure 8 ("TtMdParaLoad"): entry 8 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdParaLoad:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24876, 0xE
; [naka_s_headers:short] NakaInst_R12OctaveFunc
; Name string of MIDI-menu procedure 7 ("R12OctaveFunc"): entry 7 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_R12OctaveFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24884, 0xE
; [naka_s_headers:short] NakaInst_MdCmptCnctFunc
; Name string of MIDI-menu procedure 6 ("MdCmptCnctFunc"): entry 6 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_MdCmptCnctFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24892, 0x10
; [naka_s_headers:short] NakaInst_TtComputerConnection
; Name string of MIDI-menu procedure 5 ("TtComputerConnection"): entry 5
; of MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9
; 0xf72bac, v7 0xf727a8) registers with RegObjTabl 0x1600002,
; ApFunctionProc, 0x3c, 0xe55304, 0x423.
NakaInst_TtComputerConnection:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248A2, 0x16
; [naka_s_headers:short] NakaInst_MdSetupLoadFunc
; Name string of MIDI-menu procedure 4 ("MdSetupLoadFunc"): entry 4 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_MdSetupLoadFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248B8, 0x10
; [naka_s_headers:short] NakaInst_MdDrumTypeFunc
; Name string of MIDI-menu procedure 3 ("MdDrumTypeFunc"): entry 3 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_MdDrumTypeFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248C8, 0x10
; [naka_s_headers:short] NakaInst_MdPcgModeFunc
; Name string of MIDI-menu procedure 2 ("MdPcgModeFunc"): entry 2 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_MdPcgModeFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248D8, 0xE
; [naka_s_headers:short] NakaInst_TtMdRealMsg
; Name string of MIDI-menu procedure 1 ("TtMdRealMsg"): entry 1 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdRealMsg:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248E6, 0xC
; [naka_s_headers:short] NakaInst_TtMdmenu
; Name string of MIDI-menu procedure 0 ("TtMdmenu"): entry 0 of
; MidiMenu_ApFunctionNameTable, which InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) registers with RegObjTabl 0x1600002, ApFunctionProc,
; 0x3c, 0xe55304, 0x423.
NakaInst_TtMdmenu:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248F2, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaDesc_PageWindow_Sentinel
; NakaDesc_PageWindow_Sentinel -- 2 bytes of NUL-terminated strings at
; the start of the blob; no registration or code reference reaches them
; (searched: RegObjTabl tables, slice and positional labels). Which code
; uses them is not established.
;
; Typed in naka_widget_descriptors.c as char
; NakaDesc_PageWindow_Sentinel[2].
; -----------------------------------------------------------------------------
NakaDesc_PageWindow_Sentinel:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24906, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvMpstPageControl
; ClassProps_IvMpstPageControl -- property names of class
; IvMpstPageControl (descriptor 2 of East_ClassTable_163, whose +0x14
; points here): 3 pointers, one per letter of its signature "Att" --
; "page", "window0", "window1" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_IvMpstPageControl[4] and char
; ClassProps_IvMpstPageControl_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvMpstPageControl:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24908, 0x28
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcSendEditSw
; ClassProps_AcSendEditSw -- property names of class AcSendEditSw
; (descriptor 3 of East_ClassTable_163, whose +0x14 points here): 4
; pointers, one per letter of its signature "fjXn" -- "style", "func",
; "str", "onoff" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcSendEditSw[5] and char ClassProps_AcSendEditSw_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcSendEditSw:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24930, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcGMOnOffBox
; ClassProps_AcGMOnOffBox -- property names of class AcGMOnOffBox
; (descriptor 4 of East_ClassTable_163, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcGMOnOffBox[1] and char ClassProps_AcGMOnOffBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcGMOnOffBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2495C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcLswFuncEditBox
; ClassProps_AcLswFuncEditBox -- property names of class
; AcLswFuncEditBox (descriptor 5 of East_ClassTable_163, whose +0x14
; points here): 5 pointers, one per letter of its signature "nXXFB" --
; "data", "on_str", "off_str", "pman_adr", "pman_out" -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcLswFuncEditBox[6] and char
; ClassProps_AcLswFuncEditBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcLswFuncEditBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24962, 0x44
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcLswFuncBox
; ClassProps_AcLswFuncBox -- property names of class AcLswFuncBox
; (descriptor 6 of East_ClassTable_163, whose +0x14 points here): 5
; pointers, one per letter of its signature "nXXFB" -- "data", "on_str",
; "off_str", "pman_adr", "pman_out" -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcLswFuncBox[6] and char ClassProps_AcLswFuncBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcLswFuncBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249A6, 0x44
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcFadeSetGridBox
; ClassProps_AcFadeSetGridBox -- property names of class
; AcFadeSetGridBox (descriptor 7 of East_ClassTable_163, whose +0x14
; points here): 3 pointers, one per letter of its signature "XXj" --
; "fixedcol", "fixedrow", "func" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcFadeSetGridBox[4] and char
; ClassProps_AcFadeSetGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcFadeSetGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249EA, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcVocalGridBox
; ClassProps_AcVocalGridBox -- property names of class AcVocalGridBox
; (descriptor 8 of East_ClassTable_163, whose +0x14 points here): 3
; pointers, one per letter of its signature "XXj" -- "fixedcol",
; "fixedrow", "func" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcVocalGridBox[4] and char
; ClassProps_AcVocalGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcVocalGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A16, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcInOutGridBox
; ClassProps_AcInOutGridBox -- property names of class AcInOutGridBox
; (descriptor 9 of East_ClassTable_163, whose +0x14 points here): 3
; pointers, one per letter of its signature "XXj" -- "fixedcol",
; "fixedrow", "func" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcInOutGridBox[4] and char
; ClassProps_AcInOutGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcInOutGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A42, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcParaLoadOptGridBox
; ClassProps_AcParaLoadOptGridBox -- property names of class
; AcParaLoadOptGridBox (descriptor 10 of East_ClassTable_163, whose
; +0x14 points here): 3 pointers, one per letter of its signature "XXj"
; -- "fixedcol", "fixedrow", "func" -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcParaLoadOptGridBox[4] and char
; ClassProps_AcParaLoadOptGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcParaLoadOptGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A6E, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcPcgOutGridBox
; ClassProps_AcPcgOutGridBox -- property names of class AcPcgOutGridBox
; (descriptor 11 of East_ClassTable_163, whose +0x14 points here): 3
; pointers, one per letter of its signature "XXj" -- "fixedcol",
; "fixedrow", "func" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcPcgOutGridBox[4] and char
; ClassProps_AcPcgOutGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcPcgOutGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A9A, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcPmemOutLGridBox
; ClassProps_AcPmemOutLGridBox -- property names of class
; AcPmemOutLGridBox (descriptor 12 of East_ClassTable_163, whose +0x14
; points here): 3 pointers, one per letter of its signature "XXj" --
; "fixedcol", "fixedrow", "func" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcPmemOutLGridBox[4] and char
; ClassProps_AcPmemOutLGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcPmemOutLGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AC6, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcPmemOutRGridBox
; ClassProps_AcPmemOutRGridBox -- property names of class
; AcPmemOutRGridBox (descriptor 13 of East_ClassTable_163, whose +0x14
; points here): 3 pointers, one per letter of its signature "XXj" --
; "fixedcol", "fixedrow", "func" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcPmemOutRGridBox[4] and char
; ClassProps_AcPmemOutRGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcPmemOutRGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AF2, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcCtlMsgGridBox
; ClassProps_AcCtlMsgGridBox -- property names of class AcCtlMsgGridBox
; (descriptor 14 of East_ClassTable_163, whose +0x14 points here): 4
; pointers, one per letter of its signature "XXjn" -- "fixedcol",
; "fixedrow", "func", "page" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcCtlMsgGridBox[5] and char
; ClassProps_AcCtlMsgGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcCtlMsgGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B1E, 0x36
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcMidiPartGridBox
; ClassProps_AcMidiPartGridBox -- property names of class
; AcMidiPartGridBox (descriptor 15 of East_ClassTable_163, whose +0x14
; points here): 4 pointers, one per letter of its signature "XXjn" --
; "fixedcol", "fixedrow", "func", "page" -- then a pointer to "", then
; the names themselves.
;
; Typed in naka_widget_descriptors.c as uint32_t
; ClassProps_AcMidiPartGridBox[5] and char
; ClassProps_AcMidiPartGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcMidiPartGridBox:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B54, 0x36
; -----------------------------------------------------------------------------
; [naka_s_headers] East_ClassTable_163
; East_ClassTable_163 -- class table: InitializeEast (v10/v9 0xf72bac,
; v7 0xf727a8) (sequencer/seq_event_playback.s:2621) registers it with
; `RegObjTable 0x1600004, 0xfa44e2, (count at 0xe55cd4 = 16), 0xe559ea,
; 0x163` -- 16 naka_class_t descriptors (naka_types.h: proc, base class,
; two u16, name, field-type letters, property data), 16 of them inside
; this blob.
;
; Typed in naka_widget_descriptors.c as naka_class_t
; East_ClassTable_163[16].
; -----------------------------------------------------------------------------
East_ClassTable_163:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B8A, 0x180
	.set NakaData_Block007, East_ClassTable_163 + 76	; historical label, used by other files
; -----------------------------------------------------------------------------
; [naka_s_headers] East_ClassTable_163_Tail
; East_ClassTable_163_Tail -- 94 bytes after East_ClassTable_163 that no
; registration or code reference reaches (searched: RegObjTabl tables,
; slice and positional labels). Contents not established.
;
; Typed in naka_widget_descriptors.c as uint8_t
; East_ClassTable_163_Tail[94].
; -----------------------------------------------------------------------------
East_ClassTable_163_Tail:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24D0A, 0x5E

; External label offsets within the binary blob above.
; The NakaInst_<EFFECT> run starting at +0x01e1a IS DspEffectName_Strings:
; NakaInst_FxReservedSlot_00 (+0x01e1a) is effect 127 and
; NakaInst_NO_OPERATION (+0x02708) is effect 0 -- so the effect number of
; any label in that run is (0x02708 - offset) / 18.

; --- DSP effect naming zone: table bases ---------------------------------
	.equ DspParamUnit_Table, NakaData_WidgetDescriptors + 0x015b8	; 0xE32418, 86 x 2
	.equ DspParamName_Table, NakaData_WidgetDescriptors + 0x01664	; 0xE324C4, 86 x 17
	.equ DspEffectName_PtrTable, NakaData_WidgetDescriptors + 0x01c1a	; 0xE32A7A, 128 x u32
	.equ DspEffectName_Strings, NakaData_WidgetDescriptors + 0x01e1a	; 0xE32C7A, 128 x 18

; --- DSP parameter slots: name at +0x11*i, unit at DspParamUnit_Table+2*i -
	.equ DspParamName_00_Blank, NakaData_WidgetDescriptors + 0x01664	; slot  0 "(spare)"
	.equ DspParamName_01_VOLUME, NakaData_WidgetDescriptors + 0x01675	; slot  1 "VOLUME"
	.equ DspParamName_02_VOLUME, NakaData_WidgetDescriptors + 0x01686	; slot  2 "VOLUME"
	.equ DspParamName_03_REV_SEND, NakaData_WidgetDescriptors + 0x01697	; slot  3 "REV SEND"
	.equ DspParamName_04_DRIVE, NakaData_WidgetDescriptors + 0x016a8	; slot  4 "DRIVE"
	.equ DspParamName_05_ADJUST, NakaData_WidgetDescriptors + 0x016b9	; slot  5 "ADJUST"
	.equ DspParamName_06_EMPHASIS_GAIN, NakaData_WidgetDescriptors + 0x016ca	; slot  6 "EMPHASIS GAIN"
	.equ DspParamName_07_DEPTH, NakaData_WidgetDescriptors + 0x016db	; slot  7 "DEPTH"
	.equ DspParamName_08_LFO_SPEED, NakaData_WidgetDescriptors + 0x016ec	; slot  8 "LFO SPEED" [Hz]
	.equ DspParamName_09_SLOW_LFO_SPEED, NakaData_WidgetDescriptors + 0x016fd	; slot  9 "SLOW LFO SPEED" [Hz]
	.equ DspParamName_10_FAST_LFO_BALANCE, NakaData_WidgetDescriptors + 0x0170e	; slot 10 "FAST LFO BALANCE"
	.equ DspParamName_11_RESONANCE, NakaData_WidgetDescriptors + 0x0171f	; slot 11 "RESONANCE"
	.equ DspParamName_12_MANUAL, NakaData_WidgetDescriptors + 0x01730	; slot 12 "MANUAL"
	.equ DspParamName_13_SLOW_FAST, NakaData_WidgetDescriptors + 0x01741	; slot 13 "SLOW/FAST"
	.equ DspParamName_14_TREBLE_FAST, NakaData_WidgetDescriptors + 0x01752	; slot 14 "TREBLE FAST" [Hz]
	.equ DspParamName_15_SLOW, NakaData_WidgetDescriptors + 0x01763	; slot 15 "SLOW" [Hz]
	.equ DspParamName_16_WIND_UP, NakaData_WidgetDescriptors + 0x01774	; slot 16 "WIND UP" [s ]
	.equ DspParamName_17_WIND_DOWN, NakaData_WidgetDescriptors + 0x01785	; slot 17 "WIND DOWN" [s ]
	.equ DspParamName_18_BASS_FAST, NakaData_WidgetDescriptors + 0x01796	; slot 18 "BASS   FAST" [Hz]
	.equ DspParamName_19_BASS_SLOW, NakaData_WidgetDescriptors + 0x017a7	; slot 19 "BASS   SLOW" [Hz]
	.equ DspParamName_20_VOLUME_ADJUST, NakaData_WidgetDescriptors + 0x017b8	; slot 20 "VOLUME ADJUST"
	.equ DspParamName_21_OSC_SPEED, NakaData_WidgetDescriptors + 0x017c9	; slot 21 "OSC SPEED" [Hz]
	.equ DspParamName_22_DELAY_L, NakaData_WidgetDescriptors + 0x017da	; slot 22 "DELAY L" [ms]
	.equ DspParamName_23_DELAY_R, NakaData_WidgetDescriptors + 0x017eb	; slot 23 "DELAY R" [ms]
	.equ DspParamName_24_FEEDBACK_L, NakaData_WidgetDescriptors + 0x017fc	; slot 24 "FEEDBACK L"
	.equ DspParamName_25_FEEDBACK_R, NakaData_WidgetDescriptors + 0x0180d	; slot 25 "FEEDBACK R"
	.equ DspParamName_26_DELAY_DRY_WET, NakaData_WidgetDescriptors + 0x0181e	; slot 26 "DELAY DRY/WET"
	.equ DspParamName_27_CHORUS_DRY_WET, NakaData_WidgetDescriptors + 0x0182f	; slot 27 "CHORUS DRY/WET"
	.equ DspParamName_28_FLANGER_DRY_WET, NakaData_WidgetDescriptors + 0x01840	; slot 28 "FLANGER DRY/WET"
	.equ DspParamName_29_PHASER_DRY_WET, NakaData_WidgetDescriptors + 0x01851	; slot 29 "PHASER DRY/WET"
	.equ DspParamName_30_LOW_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x01862	; slot 30 "LOW  EMPHASIS FC"
	.equ DspParamName_31_LOW_EMPHASIS_G, NakaData_WidgetDescriptors + 0x01873	; slot 31 "LOW  EMPHASIS  G"
	.equ DspParamName_32_HIGH_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x01884	; slot 32 "HIGH EMPHASIS FC" [Hz]
	.equ DspParamName_33_HIGH_EMPHASIS_G, NakaData_WidgetDescriptors + 0x01895	; slot 33 "HIGH EMPHASIS  G"
	.equ DspParamName_34_REVERB_TIME, NakaData_WidgetDescriptors + 0x018a6	; slot 34 "REVERB TIME" [s ]
	.equ DspParamName_35_PRE_DELAY, NakaData_WidgetDescriptors + 0x018b7	; slot 35 "PRE DELAY" [ms]
	.equ DspParamName_36_HIGH_DAMP_GAIN, NakaData_WidgetDescriptors + 0x018c8	; slot 36 "HIGH DAMP GAIN"
	.equ DspParamName_37_ERLEVEL, NakaData_WidgetDescriptors + 0x018d9	; slot 37 "ER.LEVEL"
	.equ DspParamName_38_PITCH_L, NakaData_WidgetDescriptors + 0x018ea	; slot 38 "PITCH L"
	.equ DspParamName_39_PITCH_R, NakaData_WidgetDescriptors + 0x018fb	; slot 39 "PITCH R"
	.equ DspParamName_40_THRESHOLD, NakaData_WidgetDescriptors + 0x0190c	; slot 40 "THRESHOLD"
	.equ DspParamName_41_RATIO, NakaData_WidgetDescriptors + 0x0191d	; slot 41 "RATIO"
	.equ DspParamName_42_ATTACK_SENS, NakaData_WidgetDescriptors + 0x0192e	; slot 42 "ATTACK SENS." [s ]
	.equ DspParamName_43_RELEASE_SENS, NakaData_WidgetDescriptors + 0x0193f	; slot 43 "RELEASE SENS." [s ]
	.equ DspParamName_44_ATTACK_RATE, NakaData_WidgetDescriptors + 0x01950	; slot 44 "ATTACK RATE" [s ]
	.equ DspParamName_45_RELEASE_RATE, NakaData_WidgetDescriptors + 0x01961	; slot 45 "RELEASE RATE" [s ]
	.equ DspParamName_46_GATE_TIME, NakaData_WidgetDescriptors + 0x01972	; slot 46 "GATE TIME" [ms]
	.equ DspParamName_47_MASK_TIME, NakaData_WidgetDescriptors + 0x01983	; slot 47 "MASK TIME" [ms]
	.equ DspParamName_48_HARS_TIME, NakaData_WidgetDescriptors + 0x01994	; slot 48 "HARS TIME"
	.equ DspParamName_49_LFO_WAVEFORM, NakaData_WidgetDescriptors + 0x019a5	; slot 49 "LFO WAVEFORM"
	.equ DspParamName_50_OSC_WAVEFORM, NakaData_WidgetDescriptors + 0x019b6	; slot 50 "OSC WAVEFORM"
	.equ DspParamName_51_BAND_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x019c7	; slot 51 "BAND EMPHASIS FC" [Hz]
	.equ DspParamName_52_BAND_EMPHASIS_Q, NakaData_WidgetDescriptors + 0x019d8	; slot 52 "BAND EMPHASIS  Q"
	.equ DspParamName_53_BAND_EMPHASIS_G, NakaData_WidgetDescriptors + 0x019e9	; slot 53 "BAND EMPHASIS  G"
	.equ DspParamName_54_LOW_MIX, NakaData_WidgetDescriptors + 0x019fa	; slot 54 "LOW MIX"
	.equ DspParamName_55_HIGH_MIX, NakaData_WidgetDescriptors + 0x01a0b	; slot 55 "HIGH MIX"
	.equ DspParamName_56_PHASE, NakaData_WidgetDescriptors + 0x01a1c	; slot 56 "PHASE"
	.equ DspParamName_57_FEEDBACK, NakaData_WidgetDescriptors + 0x01a2d	; slot 57 "FEEDBACK"
	.equ DspParamName_58_SWEEP_RANGE, NakaData_WidgetDescriptors + 0x01a3e	; slot 58 "SWEEP RANGE"
	.equ DspParamName_59_WAH_CENTER_FC, NakaData_WidgetDescriptors + 0x01a4f	; slot 59 "WAH CENTER FC"
	.equ DspParamName_60_HARS_TIME_L, NakaData_WidgetDescriptors + 0x01a60	; slot 60 "HARS TIME L" [ms]
	.equ DspParamName_61_HARS_TIME_R, NakaData_WidgetDescriptors + 0x01a71	; slot 61 "HARS TIME R" [ms]
	.equ DspParamName_62_BALANCE_L, NakaData_WidgetDescriptors + 0x01a82	; slot 62 "BALANCE L"
	.equ DspParamName_63_BALANCE_R, NakaData_WidgetDescriptors + 0x01a93	; slot 63 "BALANCE R"
	.equ DspParamName_64_FAST_LFO_SPEED_L, NakaData_WidgetDescriptors + 0x01aa4	; slot 64 "FAST LFO SPEED L" [Hz]
	.equ DspParamName_65_FAST_LFO_SPEED_R, NakaData_WidgetDescriptors + 0x01ab5	; slot 65 "FAST LFO SPEED R" [Hz]
	.equ DspParamName_66_MODULATION_DEPTH, NakaData_WidgetDescriptors + 0x01ac6	; slot 66 "MODULATION DEPTH"
	.equ DspParamName_67_DELAY1_DRY_WET, NakaData_WidgetDescriptors + 0x01ad7	; slot 67 "DELAY1 DRY/WET"
	.equ DspParamName_68_DELAY2_DRY_WET, NakaData_WidgetDescriptors + 0x01ae8	; slot 68 "DELAY2 DRY/WET"
	.equ DspParamName_69_VIBRATO_DRY_WET, NakaData_WidgetDescriptors + 0x01af9	; slot 69 "VIBRATO DRY/WET"
	.equ DspParamName_70_WAH_DRY_WET, NakaData_WidgetDescriptors + 0x01b0a	; slot 70 "WAH DRY/WET"
	.equ DspParamName_71_FAST_LFO_SPEED, NakaData_WidgetDescriptors + 0x01b1b	; slot 71 "FAST LFO SPEED" [Hz]
	.equ DspParamName_72_TREBLE_DEPTH, NakaData_WidgetDescriptors + 0x01b2c	; slot 72 "TREBLE DEPTH"
	.equ DspParamName_73_FAST, NakaData_WidgetDescriptors + 0x01b3d	; slot 73 "FAST" [Hz]
	.equ DspParamName_74_BASS_DEPTH, NakaData_WidgetDescriptors + 0x01b4e	; slot 74 "BASS DEPTH"
	.equ DspParamName_75_DELAY_1, NakaData_WidgetDescriptors + 0x01b5f	; slot 75 "DELAY 1" [ms]
	.equ DspParamName_76_DELAY_2, NakaData_WidgetDescriptors + 0x01b70	; slot 76 "DELAY 2" [ms]
	.equ DspParamName_77_DELAY_3, NakaData_WidgetDescriptors + 0x01b81	; slot 77 "DELAY 3" [ms]
	.equ DspParamName_78_DELAY_4, NakaData_WidgetDescriptors + 0x01b92	; slot 78 "DELAY 4" [ms]
	.equ DspParamName_79_PAN_1, NakaData_WidgetDescriptors + 0x01ba3	; slot 79 "PAN   1"
	.equ DspParamName_80_PAN_2, NakaData_WidgetDescriptors + 0x01bb4	; slot 80 "PAN   2"
	.equ DspParamName_81_PAN_3, NakaData_WidgetDescriptors + 0x01bc5	; slot 81 "PAN   3"
	.equ DspParamName_82_PAN_4, NakaData_WidgetDescriptors + 0x01bd6	; slot 82 "PAN   4"
	.equ DspParamName_83_INTENSITY, NakaData_WidgetDescriptors + 0x01be7	; slot 83 "INTENSITY"
	.equ DspParamName_84_EXCITE, NakaData_WidgetDescriptors + 0x01bf8	; slot 84 "EXCITE"
	.equ DspParamName_85_Blank, NakaData_WidgetDescriptors + 0x01c09	; slot 85 "(spare)"
