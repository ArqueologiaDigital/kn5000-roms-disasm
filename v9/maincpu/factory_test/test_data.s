; Factory Test UI Configuration Data
; Factory diagnostics (codename "HAMA"): mode initialization table,
; debug page function names, RTOS command strings, and test list widgets

Hama_ModeInit_Table:
; table of 6 pointers to NakaInst_* instruction texts ("Select the sound for each part" and
; its A-D variants); evidence: SndArrLangCheck (audio/sound_editor_ui.s) returns this address in
; XHL when XBC = 0x01E0009F.  Not HAMA mode data; the name is kept because that file uses it.
	.long	NakaInst_Select_the_sound_for_each_part
	.long	NakaInst_Select_the_sound_for_each_part
	.long	NakaInst_SelectSoundForPart_A
	.long	NakaInst_SelectSoundForPart_B
	.long	NakaInst_SelectSoundForPart_C
	.long	NakaInst_SelectSoundForPart_D
; table of 3 code pointers, ending in 0 (object 0x429 holds their names)
; evidence: InitializeHama `RegObjTablHama 0x1600002, ApFunctionProc, 0x2, <this>, 0x129` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ApFuncTable_129:
	.long	FDTestDialogProc
	.long	HamaEvtDisp_Entry
	.long	0
; table of 3 pointers to the NAME strings of the functions in object 0x129's table
; evidence: InitializeHama `RegObjTablHama 0x1600002, ApFunctionProc, 0x2, <this>, 0x429` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ApFuncTable_429:
	.long	HamaStr_HamaPage1Func
	.long	HamaStr_hamadeb
	.long	HamaStr_Empty
HamaStr_Empty:
	aligned_string ""
HamaStr_hamadeb:
	aligned_string "hamadeb"
HamaStr_HamaPage1Func:
	aligned_string "HamaPage1Func"
HamaList_Entry:
	.long	HamaList_EntryStr_Empty
HamaList_EntryStr_Empty:
	aligned_string ""
; parameter block of object 0x169 (class 0x01600004, proc ClassProc); its descriptor's +8 word is read from HamaStr_HamaList + 0xa
; evidence: InitializeHama `RegObjTableHama 0x1600004, ClassProc, HamaStr_HamaList + 0xa, <this>, 0x169` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ClassTable_169:
	.long	HamaListProc
	.byte	0x55, 0x00, 0x60, 0x01, 0x30, 0x00, 0x00, 0x00
	.long	HamaStr_HamaList
	.long	HamaList_HeaderStr_Empty
	.long	HamaList_Entry
	.zero 24
HamaList_HeaderStr_Empty:
	aligned_string ""
HamaStr_HamaList:
	aligned_string "HamaList"
	.byte	0x01, 0x00
; parameter block of object 0x1C9 (class 0x0160000C, proc ResEventProc); its descriptor's +8 word is read from HamaStr_EV_INDEX_PUTS + 0xe
; evidence: InitializeHama `RegObjTableHama 0x160000c, ResEventProc, HamaStr_EV_INDEX_PUTS + 0xe, <this>, 0x1c9` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ResEventTable_1C9:
	.long	HamaStr_EV_INDEX_PUTS
	.byte	0x00, 0x00, 0x00, 0x00
HamaStr_EV_INDEX_PUTS:
	aligned_string "EV_INDEX_PUTS"
	.byte	0x01, 0x00
; parameter block of object 0x1E9 (class 0x0160000D, proc ResMethodProc); its descriptor's +8 word is read from HamaStr_MT_CONTINUE + 0xc
; evidence: InitializeHama `RegObjTableHama 0x160000d, ResMethodProc, HamaStr_MT_CONTINUE + 0xc, <this>, 0x1e9` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ResMethodTable_1E9:
	.long	HamaStr_MT_CONTINUE
	.byte	0x00, 0x00, 0x00, 0x00
HamaStr_MT_CONTINUE:
	aligned_string "MT_CONTINUE"
	.byte	0x01, 0x00
; table of 85 code pointers, ending in 0 (object 0x409 holds their names)
; evidence: InitializeHama `RegObjTablHama 0x1600001, FunctionProc, 0x4b, <this>, 0x109` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_FunctionTable_109:
	.long	HamaListProc
	.long	FDLoadSaveTest
	.long	GetMediaType
	.long	PreLswLoad
	.long	PostLswLoad
	.long	PreLswSave
	.long	PostLswSave
	.long	PrePmLoad
	.long	PostPmLoad
	.long	PrePmSave
	.long	PostPmSave
	.long	SeqLoadPre
	.long	SeqLoadPost
	.long	SeqSavePre
	.long	SeqSavePost
	.long	cmp_ld_mae
	.long	cmp_ld_ato
	.long	cmp_sv_mae
	.long	cmp_sv_ato
	.long	PreTmLoad
	.long	PostTmLoad
	.long	PreTmSave
	.long	PostTmSave
	.long	msp_ld_mae
	.long	msp_ld_ato
	.long	msp_sv_mae
	.long	msp_sv_ato
	.long	PreMidiLoad
	.long	PostMidiLoad
	.long	PreMidiSave
	.long	PostMidiSave
	.long	FlashWrite
	.long	VoiceSynth_CmdCase1
	.long	SetSepaOutMode
	.long	format_FD
	.long	GetDiskFreeSpace
	.long	GetVolumeLabel
	.long	_findfirst
	.long	_findnext
	.long	_findclose
	.long	fopen_ext
	.long	fwrite_ext
	.long	fread_ext
	.long	fclose_ext
	.long	rcm_ld_XAPR_j
	.long	rcm_sv_XAPR_j
	.long	rot_rdq_X
	.long	set_flg_X
	.long	wai_flg_X
	.long	sig_sem_X
	.long	preq_sem_X
	.long	wai_sem_X
	.long	ref_sem_X
	.long	snd_msg_X
	.long	rcv_msg_X
	.long	prcv_msg_X
	.long	get_tid_X
	.long	pdly_tim_X
	.long	PlayHalt
	.long	PlayStandBy
	.long	EditSwRefresh
	.long	putc_mtx_bf_X
	.long	putc_mrx_bf_X
	.long	midi_out_en_X
	.long	GetAdr_sqbtof
	.long	GetAdr_sq_beadt
	.long	GetAdr_sqsrtc
	.long	GetAdr_rtmcfg
	.long	LoadFileSMF
	.long	sendCOMM
	.long	AssswbWr
	.long	AddswbWr
	.long	SwbtWr
	.long	SwbtWr_ReinitBothBanks
	.long	SwbtWr_ReinitOutputBank
	.long	SetGlobalError
	.long	malloc_X
	.long	free_X
	.long	ChangePalette
	.long	ChangeWall
	.long	BitMapOut
	.long	AllBOut
	.long	SetWall_X
	.long	ferror_ext
	.long	0
; table of 85 pointers to the NAME strings of the functions in object 0x109's table
; evidence: InitializeHama `RegObjTablHama 0x1600001, FunctionProc, 0x4b, <this>, 0x409` -> RegisterObjectTable (descriptor +10 = this; registry 0x27ED2 + 14*index)
Hama_ModeParam_Table:
	.long HamaStr_HamaListProc
	.long HamaStr_FDLoadSaveTest
	.long HamaStr_GetMediaType
	.long HamaStr_PreLswLoad
	.long HamaStr_PostLswLoad
	.long HamaStr_PreLswSave
	.long HamaStr_PostLswSave
	.long HamaStr_PrePmLoad
	.long HamaStr_PostPmLoad
	.long HamaStr_PrePmSave
	.long HamaStr_PostPmSave
	.long HamaStr_SeqLoadPre
	.long HamaStr_SeqLoadPost
	.long HamaStr_SeqSavePre
	.long HamaStr_SeqSavePost
	.long HamaStr_cmp_ld_mae
	.long HamaStr_cmp_ld_ato
	.long HamaStr_cmp_sv_mae
	.long HamaStr_cmp_sv_ato
	.long HamaStr_PreTmLoad
	.long HamaStr_PostTmLoad
	.long HamaStr_PreTmSave
	.long HamaStr_PostTmSave
	.long HamaStr_msp_ld_mae
	.long HamaStr_msp_ld_ato
	.long HamaStr_msp_sv_mae
	.long HamaStr_msp_sv_ato
	.long HamaStr_PreMidiLoad
	.long HamaStr_PostMidiLoad
	.long HamaStr_PreMidiSave
	.long HamaStr_PostMidiSave
	.long HamaStr_FlashWrite
	.long HamaStr_GetResouceInfo
	.long HamaStr_SetSepaOutMode
	.long HamaStr_format_FD
	.long HamaStr_GetDiskFreeSpace
	.long HamaStr_GetVolumeLabel
	.long HamaStr_findfirst
	.long HamaStr_findnext
	.long HamaStr_findclose
	.long HamaStr_fopen_ext
	.long HamaStr_fwrite_ext
	.long HamaStr_fread_ext
	.long HamaStr_fclose_ext
	.long HamaStr_rcm_ld_XAPR_j
	.long HamaStr_rcm_sv_XAPR_j
	.long HamaStr_rot_rdq_X
	.long HamaStr_set_flg_X
	.long HamaStr_wai_flg_X
	.long HamaStr_sig_sem_X
	.long HamaStr_preq_sem_X
	.long HamaStr_wai_sem_X
	.long HamaStr_ref_sem_X
	.long HamaStr_snd_msg_X
	.long HamaStr_rcv_msg_X
	.long HamaStr_prcv_msg_X
	.long HamaStr_get_tid_X
	.long HamaStr_pdly_tim_X
	.long HamaStr_PlayHalt
	.long HamaStr_PlayStandBy
	.long HamaStr_EditSwRefresh
	.long HamaStr_putc_mtx_bf_X
	.long HamaStr_putc_mrx_bf_X
	.long HamaStr_midi_out_en_X
	.long HamaStr_GetAdr_sqbtof
	.long HamaStr_GetAdr_sq_beadt
	.long HamaStr_GetAdr_sqsrtc
	.long HamaStr_GetAdr_rtmcfg
	.long HamaStr_LoadFileSMF
	.long HamaStr_sendCOMM
	.long HamaStr_AssswbWr
	.long HamaStr_AddswbWr
	.long HamaStr_SwbtWr
	.long HamaStr_assswb_op
	.long HamaStr_assswb_out
	.long HamaStr_SetGlobalError
	.long HamaStr_malloc_X
	.long HamaStr_free_X
	.long HamaStr_ChangePalette
	.long HamaStr_ChangeWall
	.long HamaStr_BitMapOut
	.long HamaStr_AllBOut
	.long HamaStr_SetWall_X
	.long HamaStr_ferror_ext
	.long HamaStr_ModeParam_Empty
HamaStr_ModeParam_Empty:	aligned_string ""
HamaStr_ferror_ext:	aligned_string "ferror_ext"
HamaStr_SetWall_X:	aligned_string "SetWall_X"
HamaStr_AllBOut:	aligned_string "AllBOut"
HamaStr_BitMapOut:	aligned_string "BitMapOut"
HamaStr_ChangeWall:	aligned_string "ChangeWall"
HamaStr_ChangePalette:	aligned_string "ChangePalette"
HamaStr_free_X:	aligned_string "free_X"
HamaStr_malloc_X:	aligned_string "malloc_X"
HamaStr_SetGlobalError:	aligned_string "SetGlobalError"
HamaStr_assswb_out:	aligned_string "assswb_out"
HamaStr_assswb_op:	aligned_string "assswb_op"
HamaStr_SwbtWr:	aligned_string "SwbtWr"
HamaStr_AddswbWr:	aligned_string "AddswbWr"
HamaStr_AssswbWr:	aligned_string "AssswbWr"
HamaStr_sendCOMM:	aligned_string "sendCOMM"
HamaStr_LoadFileSMF:	aligned_string "LoadFileSMF"
HamaStr_GetAdr_rtmcfg:	aligned_string "GetAdr_rtmcfg"
HamaStr_GetAdr_sqsrtc:	aligned_string "GetAdr_sqsrtc"
HamaStr_GetAdr_sq_beadt:	aligned_string "GetAdr_sq_beadt"
HamaStr_GetAdr_sqbtof:	aligned_string "GetAdr_sqbtof"
HamaStr_midi_out_en_X:	aligned_string "midi_out_en_X"
HamaStr_putc_mrx_bf_X:	aligned_string "putc_mrx_bf_X"
HamaStr_putc_mtx_bf_X:	aligned_string "putc_mtx_bf_X"
HamaStr_EditSwRefresh:	aligned_string "EditSwRefresh"
HamaStr_PlayStandBy:	aligned_string "PlayStandBy"
HamaStr_PlayHalt:	aligned_string "PlayHalt"
HamaStr_pdly_tim_X:	aligned_string "pdly_tim_X"
HamaStr_get_tid_X:	aligned_string "get_tid_X"
HamaStr_prcv_msg_X:	aligned_string "prcv_msg_X"
HamaStr_rcv_msg_X:	aligned_string "rcv_msg_X"
HamaStr_snd_msg_X:	aligned_string "snd_msg_X"
HamaStr_ref_sem_X:	aligned_string "ref_sem_X"
HamaStr_wai_sem_X:	aligned_string "wai_sem_X"
HamaStr_preq_sem_X:	aligned_string "preq_sem_X"
HamaStr_sig_sem_X:	aligned_string "sig_sem_X"
HamaStr_wai_flg_X:	aligned_string "wai_flg_X"
HamaStr_set_flg_X:	aligned_string "set_flg_X"
HamaStr_rot_rdq_X:	aligned_string "rot_rdq_X"
HamaStr_rcm_sv_XAPR_j:	aligned_string "rcm_sv_XAPR_j"
HamaStr_rcm_ld_XAPR_j:	aligned_string "rcm_ld_XAPR_j"
HamaStr_fclose_ext:	aligned_string "fclose_ext"
HamaStr_fread_ext:	aligned_string "fread_ext"
HamaStr_fwrite_ext:	aligned_string "fwrite_ext"
HamaStr_fopen_ext:	aligned_string "fopen_ext"
HamaStr_findclose:	aligned_string "_findclose"
HamaStr_findnext:	aligned_string "_findnext"
HamaStr_findfirst:	aligned_string "_findfirst"
HamaStr_GetVolumeLabel:	aligned_string "GetVolumeLabel"
HamaStr_GetDiskFreeSpace:	aligned_string "GetDiskFreeSpace"
HamaStr_format_FD:	aligned_string "format_FD"
HamaStr_SetSepaOutMode:	aligned_string "SetSepaOutMode"
HamaStr_GetResouceInfo:	aligned_string "GetResouceInfo"
HamaStr_FlashWrite:	aligned_string "FlashWrite"
HamaStr_PostMidiSave:	aligned_string "PostMidiSave"
HamaStr_PreMidiSave:	aligned_string "PreMidiSave"
HamaStr_PostMidiLoad:	aligned_string "PostMidiLoad"
HamaStr_PreMidiLoad:	aligned_string "PreMidiLoad"
HamaStr_msp_sv_ato:	aligned_string "msp_sv_ato"
HamaStr_msp_sv_mae:	aligned_string "msp_sv_mae"
HamaStr_msp_ld_ato:	aligned_string "msp_ld_ato"
HamaStr_msp_ld_mae:	aligned_string "msp_ld_mae"
HamaStr_PostTmSave:	aligned_string "PostTmSave"
HamaStr_PreTmSave:	aligned_string "PreTmSave"
HamaStr_PostTmLoad:	aligned_string "PostTmLoad"
HamaStr_PreTmLoad:	aligned_string "PreTmLoad"
HamaStr_cmp_sv_ato:	aligned_string "cmp_sv_ato"
HamaStr_cmp_sv_mae:	aligned_string "cmp_sv_mae"
HamaStr_cmp_ld_ato:	aligned_string "cmp_ld_ato"
HamaStr_cmp_ld_mae:	aligned_string "cmp_ld_mae"
HamaStr_SeqSavePost:	aligned_string "SeqSavePost"
HamaStr_SeqSavePre:	aligned_string "SeqSavePre"
HamaStr_SeqLoadPost:	aligned_string "SeqLoadPost"
HamaStr_SeqLoadPre:	aligned_string "SeqLoadPre"
HamaStr_PostPmSave:	aligned_string "PostPmSave"
HamaStr_PrePmSave:	aligned_string "PrePmSave"
HamaStr_PostPmLoad:	aligned_string "PostPmLoad"
HamaStr_PrePmLoad:	aligned_string "PrePmLoad"
HamaStr_PostLswSave:	aligned_string "PostLswSave"
HamaStr_PreLswSave:	aligned_string "PreLswSave"
HamaStr_PostLswLoad:	aligned_string "PostLswLoad"
HamaStr_PreLswLoad:	aligned_string "PreLswLoad"
HamaStr_GetMediaType:	aligned_string "GetMediaType"
HamaStr_FDLoadSaveTest:	aligned_string "FDLoadSaveTest"
HamaStr_HamaListProc:	aligned_string "HamaListProc"
	aligned_string "FD SAVE/LOAD TEST"
