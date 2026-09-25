
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
NakaInst_FxReservedSlot_00:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E1A, 0x12
NakaInst_FxReservedSlot_01:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E2C, 0x12
NakaInst_FxReservedSlot_02:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E3E, 0x12
NakaInst_FxReservedSlot_03:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E50, 0x12
NakaInst_FxReservedSlot_04:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E62, 0x12
NakaInst_FxReservedSlot_05:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E74, 0x12
NakaInst_FxReservedSlot_06:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E86, 0x12
NakaInst_FxReservedSlot_07:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1E98, 0x12
NakaInst_FxReservedSlot_08:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EAA, 0x12
NakaInst_FxReservedSlot_09:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EBC, 0x12
NakaInst_FxReservedSlot_10:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1ECE, 0x12
NakaInst_FxReservedSlot_11:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EE0, 0x12
NakaInst_FxReservedSlot_12:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1EF2, 0x12
NakaInst_FxReservedSlot_13:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F04, 0x12
NakaInst_FxReservedSlot_14:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F16, 0x12
NakaInst_FxReservedSlot_15:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F28, 0x12
NakaInst_FxReservedSlot_16:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F3A, 0x12
NakaInst_FxReservedSlot_17:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F4C, 0x12
NakaInst_FxReservedSlot_18:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F5E, 0x12
NakaInst_FxReservedSlot_19:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F70, 0x12
NakaInst_FxReservedSlot_20:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F82, 0x12
NakaInst_FxReservedSlot_21:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1F94, 0x12
NakaInst_FxReservedSlot_22:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FA6, 0x12
NakaInst_FxReservedSlot_23:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FB8, 0x12
NakaInst_FxReservedSlot_24:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FCA, 0x12
NakaInst_FxReservedSlot_25:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FDC, 0x12
NakaInst_FxReservedSlot_26:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1FEE, 0x12
NakaInst_FxReservedSlot_27:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2000, 0x12
NakaInst_PEQ_OVERDR_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2012, 0x12
NakaInst_PEQ_DIST_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2024, 0x12
NakaInst_PEQ_COMPR_OVERDR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2036, 0x12
NakaInst_PEQ_COMPR_DIST:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2048, 0x12
NakaInst_FxComboReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x205A, 0x12
NakaInst_FxComboReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x206C, 0x12
NakaInst_FxComboReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x207E, 0x12
NakaInst_FxComboReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2090, 0x12
NakaInst_STAGE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20A2, 0x12
NakaInst_BATH_ROOM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20B4, 0x12
NakaInst_KARAOKE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20C6, 0x12
NakaInst_ROOM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20D8, 0x12
NakaInst_ReverbReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20EA, 0x12
NakaInst_ReverbReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x20FC, 0x12
NakaInst_ReverbReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x210E, 0x12
NakaInst_ReverbReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2120, 0x12
NakaInst_ReverbReserved_4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2132, 0x12
NakaInst_ReverbReserved_5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2144, 0x12
NakaInst_OVER_D:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2156, 0x12
NakaInst_DS_D:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2168, 0x12
NakaInst_GEQ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x217A, 0x12
NakaInst_EqReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x218C, 0x12
NakaInst_EqReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x219E, 0x12
NakaInst_EqReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21B0, 0x12
NakaInst_PEQ_COMPRESSOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21C2, 0x12
NakaInst_PEQ_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21D4, 0x12
NakaInst_PEQ_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21E6, 0x12
NakaInst_PEQ_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x21F8, 0x12
NakaInst_PEQ_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x220A, 0x12
NakaInst_AUTO_WAH_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x221C, 0x12
NakaInst_PEDAL_WAH_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x222E, 0x12
NakaInst_S_DELAY_PHASER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2240, 0x12
NakaInst_S_DELAY_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2252, 0x12
NakaInst_S_DELAY_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2264, 0x12
NakaInst_S_DELAY_S_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2276, 0x12
NakaInst_S_DELAY_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2288, 0x12
NakaInst_STRING:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x229A, 0x12
NakaInst_ChorusReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22AC, 0x12
NakaInst_ChorusReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22BE, 0x12
NakaInst_DEEP_SPACE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22D0, 0x12
NakaInst_SYMPHONIC:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22E2, 0x12
NakaInst_PERCUSSIVE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x22F4, 0x12
NakaInst_STANDARD:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2306, 0x12
NakaInst_MIX_UP:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2318, 0x12
NakaInst_HARS_EFFECT:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x232A, 0x12
NakaInst_RING_MODULATOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x233C, 0x12
NakaInst_ROTARY_SPEAKER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x234E, 0x12
NakaInst_AUTO_WAH:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2360, 0x12
NakaInst_PEDAL_WAH:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2372, 0x12
NakaInst_VIBRATO:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2384, 0x12
NakaInst_PITCH_SHIFTER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2396, 0x12
NakaInst_AUTO_PAN:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23A8, 0x12
NakaInst_ModulationReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23BA, 0x12
NakaInst_ModulationReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23CC, 0x12
NakaInst_CELM:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23DE, 0x12
NakaInst_CEL:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x23F0, 0x12
NakaInst_CelReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2402, 0x12
NakaInst_CelReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2414, 0x12
NakaInst_CelReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2426, 0x12
NakaInst_CelReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2438, 0x12
NakaInst_PARAMETRIC_EQ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x244A, 0x12
NakaInst_NOISE_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245C, 0x12
NakaInst_SLOW_ATTACKER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246E, 0x12
NakaInst_COMPRESSOR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2480, 0x12
NakaInst_EXCITER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2492, 0x12
NakaInst_FUZZ:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A4, 0x12
NakaInst_OVERDRIVE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B6, 0x12
NakaInst_DISTORTION:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24C8, 0x12
NakaInst_DistReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24DA, 0x12
NakaInst_DistReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24EC, 0x12
NakaInst_DistReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24FE, 0x12
NakaInst_DistReserved_3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2510, 0x12
NakaInst_WAVE_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2522, 0x12
NakaInst_WAVE_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2534, 0x12
NakaInst_BRIGHT_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2546, 0x12
NakaInst_BRIGHT_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2558, 0x12
NakaInst_DARK_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x256A, 0x12
NakaInst_DARK_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x257C, 0x12
NakaInst_CONCERT_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x258E, 0x12
NakaInst_CONCERT_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25A0, 0x12
NakaInst_PLATE_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25B2, 0x12
NakaInst_PLATE_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25C4, 0x12
NakaInst_ROOM_REVERB_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25D6, 0x12
NakaInst_ROOM_REVERB_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25E8, 0x12
NakaInst_ROCK_ROTARY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x25FA, 0x12
NakaInst_DelayReserved_0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x260C, 0x12
NakaInst_DelayReserved_1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x261E, 0x12
NakaInst_DelayReserved_2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2630, 0x12
NakaInst_MODULATION_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2642, 0x12
NakaInst_MULTI_TAP_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2654, 0x12
NakaInst_SINGLE_DELAY:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2666, 0x12
NakaInst_GATED_REVERB:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2678, 0x12
NakaInst_ReverbGateReserved:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x268A, 0x12
NakaInst_ENSEMBLE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x269C, 0x12
NakaInst_PHASER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26AE, 0x12
NakaInst_FLANGER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26C0, 0x12
NakaInst_ENHANCER:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26D2, 0x12
NakaInst_MODULATED_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26E4, 0x12
NakaInst_CHORUS:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x26F6, 0x12
NakaInst_NO_OPERATION:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2708, 0x2D0
NakaInst_ACHTUNG:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x29D8, 0xA
NakaInst_ATTENTION:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x29E2, 0xC
NakaInst_ATENCI_N:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x29EE, 0xC
NakaInst_Perhatian:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x29FA, 0x1A
NakaInst_Sind_Sie_sicher:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2A14, 0x12
NakaInst_Etes_vous_sur_FR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2A26, 0x10
NakaInst_Est_seguro:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2A36, 0x72
NakaInst_Features_for_editing_a_song:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2AA8, 0x1E
NakaInst_Funktionen_zur_Bearbeitung_eines_Songs:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2AC6, 0x28
NakaInst_EASY_RECORD_sets_the_Sequencer_to_record_your:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2AEE, 0x82
NakaInst_EASY_RECORD_aktiviert_DE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2B70, 0x92
NakaInst_Press_OK_to_proceed:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2C02, 0x16
NakaInst_Bestaetigen_Sie_mit_OK_DE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2C18, 0x18
NakaInst_PANEL_WRITE_replaces_the_sounds_and_settings_at:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2C30, 0xC2
NakaInst_PANEL_WRITE_ersetzt_alle_Kl_nge_und_Einstellungen:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2CF2, 0xDE
NakaInst_Press_the_up_down_buttons_under_the_screen:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2DD0, 0x60
NakaInst_Druecken_Sie_Doppeltasten_DE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2E30, 0x68
NakaInst_Press_OK_to_complete_TRACK_CLEAR:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2E98, 0x22
NakaInst_Druecken_OK_TRACK_CLEAR_DE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2EBA, 0x2C
NakaInst_Press_the_up_down_button_under_the_screen:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2EE6, 0x5C
NakaInst_Dr_cken_Sie_eine_der_Doppeltasten_unter_dem:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2F42, 0x68
NakaInst_Using_SONG_CLEAR_will_erase_any_existing:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2FAA, 0x46
NakaInst_SONG_CLEAR_loescht_DE:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2FF0, 0x3C
NakaInst_Al_anular_la_canci_n_se_borra_la_grabaci_n_del:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x302C, 0xE4
NakaInst_Using_TRACK_CLEAR_will_erase_any_existing:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3110, 0x4E
NakaInst_TRACK_CLEAR_l_scht_alle_Daten_in_den_ausgew_hlten:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x315E, 0x3C
NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x319A, 0x4DE
ExtDevice_ModeDispatch_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3678, 0x6B0
NakaInst_3d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3D28, 0xC8
NakaInst_2d:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x3DF0, 0x228
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
WidgetData_DrawbarPositionTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13618, 0x1BE
WidgetData_CharsetMappingTable:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x137D6, 0x53C
FontPalette_Gradient7:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13D12, 0x46
FontPalette_Gradient6:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13D58, 0x60
FontPalette_Gradient5:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13DB8, 0x60
FontPalette_Gradient4:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13E18, 0x60
FontPalette_Gradient3:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13E78, 0x60
FontPalette_Gradient2:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13ED8, 0x60
FontPalette_Gradient1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13F38, 0x60
FontPalette_Gradient0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13F98, 0x60
Display_FontPalette_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x13FF8, 0x71EC
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
NakaInst_OFF_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x1B272, 0x918E
EmbeddedPtrTable_v10_naka_widget_descriptors_024400:
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
	.long NakaInst_TtMdmenu
Naka_UIStringRef_Table:
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
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24500, 0x98
NakaInst_EmptyFuncName:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24598, 0x2
NakaInst_RevEqOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2459A, 0x10
NakaInst_RevEqSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245AA, 0xE
NakaInst_EqOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245B8, 0xC
NakaInst_EqSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245C4, 0xA
NakaInst_RevSelFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245CE, 0xC
NakaInst_SplitPointFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245DA, 0x10
NakaInst_StsSplitCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245EA, 0xE
NakaInst_InOutGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x245F8, 0x10
NakaInst_TtMdInOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24608, 0xA
NakaInst_FadeSetGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24612, 0x12
NakaInst_TtFadeInOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24624, 0xC
NakaInst_VocalistPage2OKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24630, 0x14
NakaInst_VocalistPage1OKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24644, 0x14
NakaInst_VocalistGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24658, 0x12
NakaInst_TtVocalistWorkstation:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2466A, 0x16
NakaInst_HarmOnOffFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24680, 0xE
NakaInst_GMNoFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2468E, 0xA
NakaInst_GMYesFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24698, 0xA
NakaInst_StsAreYouSureCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246A2, 0x14
NakaInst_StsGMOffCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246B6, 0xE
NakaInst_StsGMOnCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246C4, 0xE
NakaInst_StsAttentionCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246D2, 0x12
NakaInst_GMOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246E4, 0xA
NakaInst_TtMdGm:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246EE, 0x8
NakaInst_BitmapBmphk:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x246F6, 0xC
NakaInst_MdPresetWithFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24702, 0x12
NakaInst_MdPresetWithoutFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24714, 0x14
NakaInst_MdPresetOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24728, 0x10
NakaInst_TtMdPreset:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24738, 0xC
NakaInst_ExcMspFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24744, 0xC
NakaInst_ExcSeqFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24750, 0xC
NakaInst_ExcCompFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2475C, 0xC
NakaInst_ExcSmemFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24768, 0xC
NakaInst_ExcPmemFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24774, 0xC
NakaInst_ExcDotFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24780, 0xC
NakaInst_ExcSendFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2478C, 0xC
NakaInst_TtMdExc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24798, 0x8
NakaInst_MidiPartGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247A0, 0x12
NakaInst_TtMdPart:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247B2, 0xA
NakaInst_CtlMsgGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247BC, 0x10
NakaInst_TtMdCtlMsg:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247CC, 0xC
NakaInst_PmemOutRGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247D8, 0x12
NakaInst_PmemOutLGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247EA, 0x12
NakaInst_TtMdPmemOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x247FC, 0xC
NakaInst_ComSetGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24808, 0x10
NakaInst_TtComSet:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24818, 0xA
NakaInst_PcgOutSendFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24822, 0x10
NakaInst_PcgOutGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24832, 0x10
NakaInst_TtMdPcgOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24842, 0xC
NakaInst_ParaLoadOptOKFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2484E, 0x12
NakaInst_ParaLoadOptGridCheck:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24860, 0x16
NakaInst_TtMdParaLoad:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24876, 0xE
NakaInst_R12OctaveFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24884, 0xE
NakaInst_MdCmptCnctFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24892, 0x10
NakaInst_TtComputerConnection:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248A2, 0x16
NakaInst_MdSetupLoadFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248B8, 0x10
NakaInst_MdDrumTypeFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248C8, 0x10
NakaInst_MdPcgModeFunc:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248D8, 0xE
NakaInst_TtMdRealMsg:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248E6, 0xC
NakaInst_TtMdmenu:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x248F2, 0x14
NakaDesc_PageWindow_Sentinel:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24906, 0x2
NakaDesc_PageWindow_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24908, 0x10
NakaDesc_PageWindow_NullStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24918, 0x2
NakaDesc_PageWindow_Window1:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2491A, 0x8
NakaDesc_PageWindow_Window0:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24922, 0x8
NakaDesc_PageWindow_Page:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2492A, 0x6
NakaDesc_OnOffStyle_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24930, 0x14
NakaDesc_OnOffStyle_NullStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24944, 0x2
NakaDesc_OnOffStyle_Onoff:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24946, 0x6
NakaDesc_OnOffStyle_Str:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2494C, 0x4
NakaDesc_OnOffStyle_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24950, 0x6
NakaDesc_OnOffStyle_Style:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24956, 0xA
NakaDesc_PmanOnOff_NullTerm:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24960, 0x2
NakaDesc_PmanOnOff1_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24962, 0x18
NakaDesc_PmanOnOff1_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2497A, 0x2
NakaDesc_PmanOnOff1_PmanOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x2497C, 0xA
NakaDesc_PmanOnOff1_PmanAdr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24986, 0xA
NakaDesc_PmanOnOff1_OffStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24990, 0x8
NakaDesc_PmanOnOff1_OnStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24998, 0x8
NakaDesc_PmanOnOff1_Data:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249A0, 0x6
NakaDesc_PmanOnOff2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249A6, 0x18
NakaDesc_PmanOnOff2_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249BE, 0x2
NakaDesc_PmanOnOff2_PmanOut:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249C0, 0xA
NakaDesc_PmanOnOff2_PmanAdr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249CA, 0xA
NakaDesc_PmanOnOff2_OffStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249D4, 0x8
NakaDesc_PmanOnOff2_OnStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249DC, 0x8
NakaDesc_PmanOnOff2_Data:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249E4, 0x16
NakaDesc_GridBox1_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249FA, 0x2
NakaDesc_GridBox1_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x249FC, 0x6
NakaDesc_GridBox1_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A02, 0xA
NakaDesc_GridBox1_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A0C, 0x1A
NakaDesc_GridBox2_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A26, 0x2
NakaDesc_GridBox2_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A28, 0x6
NakaDesc_GridBox2_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A2E, 0xA
NakaDesc_GridBox2_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A38, 0x1A
NakaDesc_GridBox3_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A52, 0x2
NakaDesc_GridBox3_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A54, 0x6
NakaDesc_GridBox3_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A5A, 0xA
NakaDesc_GridBox3_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A64, 0x1A
NakaDesc_GridBox4_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A7E, 0x2
NakaDesc_GridBox4_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A80, 0x6
NakaDesc_GridBox4_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A86, 0xA
NakaDesc_GridBox4_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24A90, 0x1A
NakaDesc_GridBox5_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AAA, 0x2
NakaDesc_GridBox5_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AAC, 0x6
NakaDesc_GridBox5_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AB2, 0xA
NakaDesc_GridBox5_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24ABC, 0x1A
NakaDesc_GridBox6_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AD6, 0x2
NakaDesc_GridBox6_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AD8, 0x6
NakaDesc_GridBox6_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24ADE, 0xA
NakaDesc_GridBox6_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24AE8, 0x1A
NakaDesc_GridBox7_NullEntry:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B02, 0x2
NakaDesc_GridBox7_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B04, 0x6
NakaDesc_GridBox7_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B0A, 0xA
NakaDesc_GridBox7_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B14, 0xA
NakaDesc_PageGridBox1_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B1E, 0x14
NakaDesc_PageGridBox1_Null:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B32, 0x2
NakaDesc_PageGridBox1_Page:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B34, 0x6
NakaDesc_PageGridBox1_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B3A, 0x6
NakaDesc_PageGridBox1_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B40, 0xA
NakaDesc_PageGridBox1_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B4A, 0xE
NakaDesc_PageGridBox2_Table:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B58, 0x10
NakaDesc_PageGridBox2_NullStr:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B68, 0x2
NakaDesc_PageGridBox2_Page:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B6A, 0x6
NakaDesc_PageGridBox2_Func:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B70, 0x6
NakaDesc_PageGridBox2_FixedRow:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B76, 0xA
NakaDesc_PageGridBox2_FixedCol:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24B80, 0x56
NakaData_Block007:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24BD6, 0x192

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
