
	.text

	.include "shared/event_codes.s"

; ----------------------------------------------------------------------------
; RAM variables (the expansion's SRAM 0x200000-0x23FFFF) whose role the code
; shows; each comment names the evidence.  Operands equal to one of these
; addresses were rewritten by scripts/converters/hdae5000_symbolize_ram.py.
; ----------------------------------------------------------------------------
	.equ HDAE5000_RAM_AtaError, 0x200222	; drive error byte: 0 = ok; set by the HDAE5000_ATA_* routines, tested after every disk operation
	.equ HDAE5000_RAM_DirNames, 0x201632	; directory names, 16 B x 120 (HDAE5000_HD_GetBlockInfo block 0)
	.equ HDAE5000_RAM_SongRecords, 0x201db2	; song records, 76 B x 1920 (HDAE5000_HD_GetBlockInfo block 1)
	.equ HDAE5000_RAM_FlsRecords, 0x2257b2	; FLS records, 144 B x 120 (HDAE5000_HD_GetBlockInfo block 2)
	.equ HDAE5000_RAM_ClusterBytes, 0x229c58	; cluster size in bytes (HDAE5000_HD_ParseIdentify)
	.equ HDAE5000_RAM_SectorsPerCluster, 0x229c5c	; 0x20, or 0x40 on drives of >= 0x14DC93 sectors (HD_ParseIdentify)
	.equ HDAE5000_RAM_TablesStartSector, 0x229c64	; first of the 323 filesystem-table sectors, 3908 (HD_ParseIdentify)
	.equ HDAE5000_RAM_FatStartSector, 0x229c68	; 2 (HD_ParseIdentify)
	.equ HDAE5000_RAM_DataStartSector, 0x229c6c	; 4231, cluster 1's first sector (HD_ParseIdentify)
	.equ HDAE5000_RAM_FatEntryCount, 0x229c70	; FAT entries, whole 128-entry sectors (HD_ParseIdentify)
	.equ HDAE5000_RAM_FreeClusters, 0x229c80	; free-cluster count (HDAE5000_HD_CountFreeClusters, WriteFile, FreeChain)
	.equ HDAE5000_RAM_DataSectorCount, 0x229c94	; sectors from DataStartSector to the end (HD_ParseIdentify)
	.equ HDAE5000_RAM_HdInitResult, 0x229d92	; HDAE5000_HD_Init's step code, returned by HDAE5000_Check_HD_Present
	.equ HDAE5000_RAM_HdSignatureOk, 0x229d98	; 1 when sector 1 carries AA55AA55 F4F1F2F3 (HDAE5000_HD_CheckSignature)
	.equ HDAE5000_RAM_WriteProtect, 0x229d99	; "WRITE PROTECTION" of HDAE5000_TitleInfo_Template, 0/1 = OFF/ON
	.equ HDAE5000_RAM_WriteConfirm, 0x229d9a	; "WRITE CONFIRM" of HDAE5000_TitleInfo_Template, 0/1 = OFF/ON
	.equ HDAE5000_RAM_QuickLoadMode, 0x229da9	; "QUICK LOAD MODE" (TitleInfo); one of the six setting bytes of sector 1
	.equ HDAE5000_RAM_LoadByNumberMode, 0x229daa	; "LOAD BY NUMBER MODE" (TitleInfo); sector-1 setting byte
	.equ HDAE5000_RAM_JumpAfterLoad, 0x229dab	; "JUMP AFTER LOAD" (TitleInfo); sector-1 setting byte
	.equ HDAE5000_RAM_SaveOptions, 0x22aa4c	; 12-byte part-selection record of the save options: u16 mask, then flags 0x22AA4E+k (HDAE5000_TypeSel_*)
	.equ HDAE5000_RAM_LbnDigitPos, 0x22aa5c	; load-by-number digit position 0..5 (HDAE5000_Lbn_TypeDigit)
	.equ HDAE5000_RAM_LbnDir, 0x22aa5e	; load-by-number directory number being typed (HDAE5000_Lbn_TypeDigit)
	.equ HDAE5000_RAM_LbnSong, 0x22aa60	; load-by-number song number being typed (HDAE5000_Lbn_TypeDigit)
	.equ HDAE5000_RAM_DeleteOptions, 0x22abe6	; 12-byte part-selection record of the delete options (HDAE5000_DelOpt_*)
	.equ HDAE5000_RAM_SeparateOutputMode, 0x22b2f4	; 0..3 = OFF / DRUMS L/R / BASS+DRUMS MIX / BASS/DRUMS MONO (HDAE5000_SeparateOutput_Apply)
	.equ HDAE5000_RAM_HdStreamBuffer, 0x230f1c	; 0x8000-byte buffer of the streamed file writes/reads (HDAE5000_HD_WriteStream, the part loaders/savers)
	.equ HDAE5000_RAM_HdStreamBufferEnd, 0x238f1c	; end of HdStreamBuffer (HDAE5000_HD_WriteStream)
	.equ HDAE5000_RAM_HdStreamFill, 0x238f24	; fill pointer into HdStreamBuffer (HDAE5000_HD_WriteOpen/_WriteStream)
	.equ HDAE5000_RAM_HdStreamSlot, 0x238f28	; the first-cluster slot of the open buffered write (HD_WriteOpen)
	.equ HDAE5000_RAM_HdStreamState, 0x238f2c	; 0 closed, 1 open and nothing written, 2 written (HD_WriteOpen)
	.equ HDAE5000_RAM_PportError, 0x2390d4	; PC-link error flag, set to 1 by PPORT_RecvByte/SendByte/EndBlock
	.equ HDAE5000_RAM_PportChecksum, 0x2390fc	; 32-bit running sum of the PC-link block in transfer
	.equ HDAE5000_RAM_PportPacket, 0x239168	; the 256-byte PC-link packet (HDAE5000_PPORT_SendPacket/RecvPacket)
	.equ HDAE5000_RAM_DirPageBase, 0x23a08e	; first directory of the list page (HDAE5000_DirList_BuildPage)
	.equ HDAE5000_RAM_FlsPageBase, 0x23a090	; first FLS of the list page (HDAE5000_FlsList_BuildPage)
	.equ HDAE5000_RAM_CurDir, 0x23a092	; selected directory (HDAE5000_SongScreen_Refresh, Song_PartMask callers)
	.equ HDAE5000_RAM_CurSong, 0x23a094	; selected song within CurDir (HDAE5000_SongScreen_Refresh)
	.equ HDAE5000_RAM_CurFls, 0x23a096	; selected FLS (HDAE5000_FlsScreen_Refresh)
	.equ HDAE5000_RAM_SeparateBassPart, 0x23a09e	; bass part, 0 = NONE (SeparateBassPartCheck's value; _Apply)
	.equ HDAE5000_RAM_SeparateDrumPart, 0x23a0a0	; drum part, 0 = NONE (SeparateDrumPartCheck's value; _Apply)
	.equ HDAE5000_RAM_SeparateDrumPartSent, 0x23a0a2	; drum part last sent by HDAE5000_SeparateOutput_Apply
	.equ HDAE5000_RAM_SeparateBassPartSent, 0x23a0a4	; bass part last sent by HDAE5000_SeparateOutput_Apply
	.equ HDAE5000_RAM_MainWorkspacePtr, 0x23a1a2	; the main CPU's workspace; every call into it is (this)->0x0E88 or ->0x0E0A table + offset (init image: 4 bytes after HDAE5000_LyricBoxObj_Init; the object table at 0x027ED2)
	.equ HDAE5000_RAM_LyricJump, 0x229dac	; sector-1 setting byte; handler "LyricJumpEditCheck" returns its address
	.equ HDAE5000_RAM_LyricForeColor, 0x229dad	; sector-1 setting byte 0..4; "LyricForeColorCheck"; palette code via HDAE5000_Lyrics_ResetState
	.equ HDAE5000_RAM_LyricBackColor, 0x229dae	; sector-1 setting byte 0..4; "LyricBackColorCheck"; palette code via HDAE5000_Lyrics_ResetState
	.equ HDAE5000_RAM_LyricBuffer, 0x22b430	; the lyric file, 0x5000 bytes: TLhd/TLtr chunks, events from +22 (HDAE5000_Lyrics_ClearBuffer, _ParseEvent)
	.equ HDAE5000_RAM_LyricLines, 0x23a0aa	; six 40-byte text lines of the lyric window (HDAE5000_Lyrics_FillLines)
	.equ HDAE5000_RAM_LyricLoaded, 0x23a19c	; 1 once a lyric file passed its checks (HDAE5000_Lyrics_CheckFile)
	.equ HDAE5000_RAM_LyricBoxObj, 0x23a19e	; the open lyric box's object id, 0xFFFFFFFF when closed (HDAE5000_LyricBoxProc); redraw events go to it
	.equ HDAE5000_RAM_LyricPosEvt, 0x230ec2	; parameter block of event 0x01CA0004 to the lyric box: +0 sqbtof word, +2 LyricPosStep, +4 LyricPosition (HDAE5000_Frame_Handler)
	.equ HDAE5000_RAM_LyricPosStep, 0x230ec4	; (sq_beadt >> 3) + 1 at the last post; a change triggers the next one
	.equ HDAE5000_RAM_LyricPosition, 0x230ec6	; sqbtof * 12 + (sq_beadt >> 3) + 2: the position HDAE5000_Lyrics_PlayToPosition scales by division / 12
	.equ HDAE5000_RAM_SqSrtcPtr, 0x230ecc	; address of the main CPU's sqsrtc byte (HamaFn_GetAdr_sqsrtc = 0x0421, HDAE5000_Boot_Init); HDAE5000_Frame_Handler watches its bit 2
	.equ HDAE5000_RAM_SqSrtcBit2Prev, 0x230ed0	; bit 2 of sqsrtc at the previous frame (HDAE5000_Frame_Handler_Status)
	.equ HDAE5000_RAM_SqBtofPtr, 0x230ed2	; address of the main CPU's sqbtof word (HamaFn_GetAdr_sqbtof = 0x041C, HDAE5000_Boot_Init)
	.equ HDAE5000_RAM_SqBeadtPtr, 0x230ed6	; address of the main CPU's sq_beadt byte (HamaFn_GetAdr_sq_beadt = 0x041B, HDAE5000_Boot_Init)
	.equ HDAE5000_RAM_HdPresent, 0x230eda	; HDAE5000_Check_HD_Present's result (HDAE5000_Boot_Init; HDAE5000_Get_Init_Flag)
	.equ HDAE5000_RAM_FdLyricNames, 0x230884	; 40 x 9-byte base names of the *.TLX files on the floppy, sorted (HDAE5000_FdLyricList_AddTlx)
	.equ HDAE5000_RAM_FdLyricTitles, 0x2309f6	; 40 x 27 bytes: the first 26 bytes of each <name>.TTX (HDAE5000_FdLyricList_Scan)
	.equ HDAE5000_RAM_FdLyricHasMid, 0x230e4a	; 40 flags: <name>.MID opens (HDAE5000_FdLyricList_Scan)
	.equ HDAE5000_RAM_FdLyricCount, 0x230e72	; entries in FdLyricNames, at most 40 (HDAE5000_FdLyricList_AddTlx)
	.equ HDAE5000_RAM_FdVolumeLabel, 0x230e7a	; the floppy's volume label (HamaFn_GetVolumeLabel) + " ->" (HDAE5000_FdLyricList_Scan)

; ----------------------------------------------------------------------------
; The main CPU's function tables, as the HD-AE5000 reaches them: workspace
; (= object table 0x027ED2, 14-byte records {id, proc, count, data}) + 0x0E0A
; is the data pointer of table 0x100, + 0x0E88 that of table 0x109.  The
; constant names are the firmware's own, read from the name table the main
; CPU registers beside each function table (0x400 / 0x409); generated by
; scripts/converters/hdae5000_symbolize_fn_tables.py, which checks each
; against original_ROMs/kn5000_v10_program.rom.
; ----------------------------------------------------------------------------
	.equ WS_RootFnTable, 0x0e0a	; 14 * 0x100 + 10: table 0x100 = 0xEAFA6E (InitializeRoot: RegObjTabl 0x1600001, FunctionProc, 0x160, 0xeafa6e, 0x100)
	.equ WS_HamaFnTable, 0x0e88	; 14 * 0x109 + 10: table 0x109 = 0xE1F0EC (InitializeHama: RegObjTablHama 0x1600001, FunctionProc, 0x4b, 0xe1f0ec, 0x109)
	.equ RootFn_UpdateScreen, 0x0084	; -> 0xFAA61D (index 33); v10 build label LcdOff_Epilogue
	.equ RootFn_DrawLine, 0x009c	; -> 0xFAA98A (index 39)
	.equ RootFn_DrawBox, 0x00a4	; -> 0xFAB273 (index 41)
	.equ RootFn_DrawFrame, 0x00a8	; -> 0xFAB3DE (index 42)
	.equ RootFn_MovePixels, 0x00b0	; -> 0xFABA53 (index 44)
	.equ RootFn_DrawString, 0x00c4	; -> 0xFACACA (index 49)
	.equ RootFn_InheritedProc, 0x00dc	; -> 0xFA4409 (index 55)
	.equ RootFn_RegisterObjectTable, 0x00e4	; -> 0xFA42FB (index 57)
	.equ RootFn_SendEvent, 0x0100	; -> 0xFA9660 (index 64)
	.equ RootFn_PostEvent, 0x0104	; -> 0xFA9752 (index 65)
	.equ RootFn_ApPostEvent, 0x0124	; -> 0xFA9D58 (index 73)
	.equ RootFn_ResEventProc, 0x013c	; -> 0xFA58FB (index 79)
	.equ RootFn_ResMethodProc, 0x0140	; -> 0xFA5948 (index 80)
	.equ RootFn_ResNameProc, 0x0148	; -> 0xFA62CB (index 82)
	.equ RootFn_GetCharHeight, 0x0150	; -> 0xFB260A (index 84)
	.equ RootFn_GetCharDescent, 0x0154	; -> 0xFB2617 (index 85)
	.equ RootFn_GetCenteredDelta, 0x0158	; -> 0xFB2624 (index 86)
	.equ RootFn_ConvertStrings, 0x015c	; -> 0xFB2640 (index 87)
	.equ RootFn_ClassProc, 0x0168	; -> 0xFA44E2 (index 90)
	.equ RootFn_FunctionProc, 0x0244	; -> 0xFA48A9 (index 145)
	.equ RootFn_ApFunctionProc, 0x0248	; -> 0xFA496C (index 146)
	.equ RootFn_MainFunctionProc, 0x024c	; -> 0xFA4A18 (index 147)
	.equ RootFn_ApFuncCall, 0x0250	; -> 0xFA49B7 (index 148)
	.equ RootFn_MainFuncCall, 0x0254	; -> 0xFA4A63 (index 149)
	.equ RootFn_RegisterTitle, 0x0270	; -> 0xFA4D80 (index 156)
	.equ RootFn_GetTitleNow, 0x0278	; -> 0xFA5867 (index 158)
	.equ RootFn_ViewableProc, 0x0280	; -> 0xFA5995 (index 160)
	.equ RootFn_SetVisible, 0x0294	; -> 0xFA5E8C (index 165)
	.equ RootFn_GetViewInstance, 0x02c4	; -> 0xFA6266 (index 177)
	.equ RootFn_GetClientBox, 0x02d4	; -> 0xF995DD (index 181)
	.equ RootFn_DrawDesignBox, 0x02dc	; -> 0xFAD559 (index 183)
	.equ RootFn_SetDialEnable, 0x03c4	; -> 0xF9A53B (index 241)
	.equ RootFn_SetDialUp, 0x03c8	; -> 0xF9A579 (index 242)
	.equ RootFn_SetDialDown, 0x03cc	; -> 0xF9A58A (index 243)
	.equ RootFn_SetApTimer, 0x0410	; -> 0xFAA135 (index 260)
	.equ RootFn_KillApTimer, 0x0418	; -> 0xFAA257 (index 262)
	.equ RootFn_SetAutoInc, 0x042c	; -> 0xF9A5BD (index 267)
	.equ RootFn_GetNamingWindowID, 0x050c	; -> 0xFA1FC7 (index 323)
	.equ RootFn_DeleteEvent, 0x0534	; -> 0xFA9868 (index 333)
	.equ RootFn_SleepMainTask, 0x0538	; -> 0xF9883C (index 334)
	.equ RootFn_WakeUpMainTask, 0x053c	; -> 0xF9884B (index 335)
	.equ HamaFn_FDLoadSaveTest, 0x0004	; -> 0xF1E5DA (index 1)
	.equ HamaFn_GetMediaType, 0x0008	; -> 0xF525EC (index 2)
	.equ HamaFn_PreLswLoad, 0x000c	; -> 0xFDB434 (index 3)
	.equ HamaFn_PostLswLoad, 0x0010	; -> 0xFDB43B (index 4)
	.equ HamaFn_PreLswSave, 0x0014	; -> 0xFDB48E (index 5)
	.equ HamaFn_PostLswSave, 0x0018	; -> 0xFDB48F (index 6)
	.equ HamaFn_PrePmLoad, 0x001c	; -> 0xFDB490 (index 7)
	.equ HamaFn_PostPmLoad, 0x0020	; -> 0xFDB491 (index 8)
	.equ HamaFn_PrePmSave, 0x0024	; -> 0xFDB49E (index 9)
	.equ HamaFn_PostPmSave, 0x0028	; -> 0xFDB49F (index 10)
	.equ HamaFn_SeqLoadPre, 0x002c	; -> 0xF47850 (index 11)
	.equ HamaFn_SeqLoadPost, 0x0030	; -> 0xF47858 (index 12)
	.equ HamaFn_SeqSavePre, 0x0034	; -> 0xF47923 (index 13)
	.equ HamaFn_SeqSavePost, 0x0038	; -> 0xF47943 (index 14)
	.equ HamaFn_cmp_ld_mae, 0x003c	; -> 0xF6BC24 (index 15)
	.equ HamaFn_cmp_ld_ato, 0x0040	; -> 0xF6BC2F (index 16)
	.equ HamaFn_cmp_sv_mae, 0x0044	; -> 0xF6BC48 (index 17)
	.equ HamaFn_cmp_sv_ato, 0x0048	; -> 0xF6BC5A (index 18)
	.equ HamaFn_PreTmLoad, 0x004c	; -> 0xFF049F (index 19)
	.equ HamaFn_PostTmLoad, 0x0050	; -> 0xFF04A0 (index 20)
	.equ HamaFn_PreTmSave, 0x0054	; -> 0xFF04E4 (index 21)
	.equ HamaFn_PostTmSave, 0x0058	; -> 0xFF04E5 (index 22)
	.equ HamaFn_msp_ld_mae, 0x005c	; -> 0xF6BC66 (index 23)
	.equ HamaFn_msp_ld_ato, 0x0060	; -> 0xF6BC71 (index 24)
	.equ HamaFn_msp_sv_mae, 0x0064	; -> 0xF6BC82 (index 25)
	.equ HamaFn_msp_sv_ato, 0x0068	; -> 0xF6BC99 (index 26)
	.equ HamaFn_PreMidiLoad, 0x006c	; -> 0xFDB4A0 (index 27)
	.equ HamaFn_PostMidiLoad, 0x0070	; -> 0xFDB4A1 (index 28)
	.equ HamaFn_PreMidiSave, 0x0074	; -> 0xFDB4A2 (index 29)
	.equ HamaFn_PostMidiSave, 0x0078	; -> 0xFDB4A3 (index 30)
	.equ HamaFn_FlashWrite, 0x007c	; -> 0xEF3C3C (index 31)
	.equ HamaFn_GetResouceInfo, 0x0080	; -> 0xF1EA30 (index 32)
	.equ HamaFn_SetSepaOutMode, 0x0084	; -> 0xF1EB30 (index 33)
	.equ HamaFn_GetVolumeLabel, 0x0090	; -> 0xF527CE (index 36)
	.equ HamaFn__findfirst, 0x0094	; -> 0xF5298A (index 37)
	.equ HamaFn__findnext, 0x0098	; -> 0xF52AE8 (index 38)
	.equ HamaFn__findclose, 0x009c	; -> 0xF52AAA (index 39)
	.equ HamaFn_fopen_ext, 0x00a0	; -> 0xF1ED24 (index 40)
	.equ HamaFn_fread_ext, 0x00a8	; -> 0xF1ED2C (index 42)
	.equ HamaFn_fclose_ext, 0x00ac	; -> 0xF1ED30 (index 43)
	.equ HamaFn_rcm_ld_XAPR_j, 0x00b0	; -> 0xF1EB28 (index 44)
	.equ HamaFn_rcm_sv_XAPR_j, 0x00b4	; -> 0xF1EB2C (index 45)
	.equ HamaFn_rot_rdq_X, 0x00b8	; -> 0xF1ED38 (index 46)
	.equ HamaFn_ref_sem_X, 0x00d0	; -> 0xF1ED50 (index 52)
	.equ HamaFn_pdly_tim_X, 0x00e4	; -> 0xF1ED64 (index 57)
	.equ HamaFn_PlayHalt, 0x00e8	; -> 0xF1ED68 (index 58)
	.equ HamaFn_PlayStandBy, 0x00ec	; -> 0xF1EDA8 (index 59)
	.equ HamaFn_EditSwRefresh, 0x00f0	; -> 0xF1EDBE (index 60)
	.equ HamaFn_GetAdr_sqbtof, 0x0100	; -> 0xF1EDE2 (index 64)
	.equ HamaFn_GetAdr_sq_beadt, 0x0104	; -> 0xF1EDE7 (index 65)
	.equ HamaFn_GetAdr_sqsrtc, 0x0108	; -> 0xF1EDEC (index 66)
	.equ HamaFn_sendCOMM, 0x0114	; -> 0xEF32F4 (index 69)
	.equ HamaFn_SwbtWr, 0x0120	; -> 0xFDB255 (index 72)
	.equ HamaFn_SetGlobalError, 0x012c	; -> 0xF1EDF6 (index 75)
	.equ HamaFn_malloc_X, 0x0130	; -> 0xF1EDFB (index 76)
	.equ HamaFn_free_X, 0x0134	; -> 0xF1EE03 (index 77)
	.equ HamaFn_ChangePalette, 0x0138	; -> 0xFAF2C7 (index 78)
	.equ HamaFn_ChangeWall, 0x013c	; -> 0xFAF20B (index 79)

; HDAE5000 Hard Disk Expansion ROM Disassembly
; Original file: hd-ae5000_v2_06i.ic4
; Size: 512KB (0x80000 bytes)
; Base address: 0x280000 (mapped in main CPU address space)
;
; This ROM is part of the optional HD-AE5000 hard disk expansion for the
; Technics KN5000 music keyboard. It provides:
;   - Hard disk file management
;   - PC parallel port communication (PPORT)
;   - Additional UI elements for HD operations
;
; Version: 2.33J (as stated in ROM strings)
; Date: Juli-Oktober 1996
; Author: M. Kitajima (Technics Software section)
;
; Entry Points (called by main CPU via validation at boot):
;   0x280008 - JP to HDAE5000_Boot_Init (0x28F576)
;   0x280010 - JP to HDAE5000_Frame_Handler (0x28F662)
;
; Hardware accessed:
;   0x160000-0x160006 - HDAE5000 PPI (8255) ports
;   0x23xxxx - RAM workspace (shared with main CPU)
;
; ROM Layout (file offsets → memory addresses):
;   0x00000-0x0001F  Header with "XAPR4" magic and entry vectors (32 bytes)
;   0x00020-0x0F575  Code section 1 - setup routines (62806 bytes)
;   0x0F576-0x0F661  HDAE5000_Boot_Init routine (236 bytes)
;   0x0F662-0x15421  Code section 2 part A - frame handler (0x28F662-0x295421)
;   0x15422-0x15FC0  PPORT command menu strings (0x295422-0x295FC0, ~1440 bytes)
;                    Contains 20+ menu items: "Exit PPORT", "Read FSB from HD",
;                    "Send data to PC", "Formatting HD", etc.
;   0x15FC1-0x1A3AF  Code section 2 part B - more routines
;   0x1A3B0-0x1A3DF  Version info block (0x2999B0-0x2999DF):
;                    "Technics Software section    M. Kitajima"
;                    Version: "2.33J", also "2.21"
;                    "TECHNICS KN5000"
;   0x1C9FF-0x1D9FF  UI configuration strings (0x29BFE0-0x29CFF0):
;                    "infofont", "reversecolor", "fontcolor", "dial", etc.
;   0x1D000-0x65DCD  Additional code, lookup tables, German error messages
;   0x65DCE-0x661CD  HDAE5000_Palette_Data - 256 RGBX VGA entries (1,024 bytes)
;   0x661CE-0x78DCD  HDAE5000_Bitmap_BootSplash - boot splash bitmap
;                    (0x2E61CE, 320x240 8bpp indexed, 76,800 bytes)
;   0x78DCE-0x7A134  HDAE5000_Display_Params + HDAE5000_Init_Data
;   0x7A135-0x7FFFF  Padding zeros (24,267 bytes; the ROM's last non-zero
;                    byte is at file offset 0x7A134 = 0x2FA134)
;
; Key Routine Addresses (within code sections):
;
; Code Section 1 (0x280020-0x28F575):
;   0x280020  HDAE5000_Handler_Registration - Handler registration entry (DISASSEMBLED)
;   0x28030E  HDAE5000_Alloc_Memory_1 - bitmap resource descriptor (see below)
;   0x28033B  HDAE5000_Alloc_Memory_2 - bitmap resource descriptor
;   0x280368  HDAE5000_Alloc_Memory_3 - bitmap resource descriptor
;   0x2803C2  HDAE5000_UiState_Reset - Register frame handler callback
;   0x28F543  HDAE5000_Alloc_Memory - Display parameter lookup (DISASSEMBLED)
;   0x28F570  HDAE5000_Get_Init_Flag - Return HD presence flag (DISASSEMBLED)
;
; Code Section 2 (0x28F662-0x2FFFFF):
;   0x28F662  HDAE5000_Frame_Handler - Main frame handler entry (DISASSEMBLED)
;                Calculates display offset, calls registered callbacks
;   0x28F6E0  HDAE5000_Frame_Handler_Status - Status check section (DISASSEMBLED)
;                Monitors bit 2, triggers display init on state change
;   0x28F781  HDAE5000_Frame_Handler_Exit - Exit via JP to PPORT (DISASSEMBLED)
;   0x28F785  HDAE5000_Clear_Work_Buffer - Clear/init work buffer (DISASSEMBLED)
;   0x28F7DD  HDAE5000_Delay_Loop - Nested delay loop (DISASSEMBLED)
;   0x28F7EE  HDAE5000_VGA_Port_Write - Write to VGA port (mem-mapped at 0x170000) (DISASSEMBLED)
;   0x28F813  HDAE5000_Palette_Setup - Set one VGA palette entry (DISASSEMBLED)
;   0x28F8E0  HDAE5000_Load_Palette - Load all 256 palette entries (DISASSEMBLED)
;   0x28F90B  HDAE5000_Finalize_Init - Just returns (1-byte stub) (DISASSEMBLED)
;   0x28F90C  HDAE5000_HD_FormatDrive - format the drive (see its header)
;   0x28F97E  HDAE5000_DirName_Address - Calculate 16-byte offset in table
;   0x28F98B  HDAE5000_DirName_SetAndStore - Copy data to table at 0x201632
;   0x28F9AD  HDAE5000_Dir_IsBlankName - Memory check routine
;   0x28F9EB  HDAE5000_Dir_CountEmptySongs - Count invalid entries
;   0x28FA1E  HDAE5000_SongRecord_Address - Calculate address with 0x4C multiplier
;   0x28FA56  HDAE5000_SongName_SetAndStore - Copy table entry
;   0x28FAA0  HDAE5000_FlsRecord_Address - Calculate address with 0x90 multiplier
;   0x28FABA  HDAE5000_FlsName_SetAndStore - Copy 0x90-stride entry
;   0x28FAE9  HDAE5000_Fls_IsBlankName - Check table entry validity
;   0x28FB26  HDAE5000_FlsItem_SongRecord - Get entry address with validation
;   0x28FBB1  HDAE5000_FlsItem_IsSet - Validate entry at coordinates
;   0x29501C  HDAE5000_PPORT_ServicePending - PPORT state machine entry
;   0x295009  HDAE5000_PPORT_Svc27 - PPORT utility function
;   0x295046  HDAE5000_PPORT_SwitchToLink - context switch main -> PC link
;   0x295058  HDAE5000_PPORT_YieldToMain - context switch PC link -> main
;   0x2950CC  HDAE5000_PPORT_ReturnToLink - resume the link, detect its end
;   0x2950F8  HDAE5000_PPORT_CallService - link asks main to run service WA (heavily used)
;   0x29511C  HDAE5000_PPORT_ServiceDispatch - PPORT setup routine
;   0x2952D6  HDAE5000_PPORT_LinkMain - PPORT menu handler
;   0x2952F8  HDAE5000_PPORT_Execute - Execute PPORT command
;   0x2953E2  HDAE5000_PPORT_Cmd_Table - Jump table for PPORT commands
;   0x295412  HDAE5000_PPORT_Strings - Command menu strings
;   0x2958D6  HDAE5000_PPORT_Cmd06_WriteFsbToHd - command 06 "Writing FSB to HD"
;   0x295914  HDAE5000_PPORT_Cmd07_LoadHdToMemory - command 07 "Load HD to Memory"
;   0x2959F6  HDAE5000_PPORT_Cmd08_SendDataToPc - command 08 "Send data to PC"
;   0x295D3C  HDAE5000_PPORT_Cmd09_SendFilesToPc - command 09 "Sending files to PC"
;   0x29605A  HDAE5000_PPORT_Cmd10_RcvDataFromPc - command 10 "Rcv data from PC"
;   0x296294  HDAE5000_PPORT_Cmd11_SaveMemoryToHd - command 11 "Save memory to HD"
;   0x2967B4  HDAE5000_PPORT_LatchPacketArgs - Display utility
;   0x2967E4  HDAE5000_PPORT_RequestSongInfo - Display utility 2
;   0x29AE9F  HDAE5000_MemCopy - Memory copy utility
;   0x29AFF0  HDAE5000_StrNCpy - Memory copy variant
;   0x29AFBE  HDAE5000_StrNCmp - Memory compare
;   0x29AF71  HDAE5000_StrLen - Memory utility
;   0x29B72D  HDAE5000_Multiply - 32-bit multiply routine
;   0x2971A3  HDAE5000_Check_HD_Present - Hard disk presence detection
;   0x2999B0  HDAE5000_Version_Info - Version string block:
;                "Technics Software section    M. Kitajima"
;                Version "2.33J", "2.21", "TECHNICS KN5000"
;   0x29BFE0  HDAE5000_UI_Config - UI configuration strings
;   0x2A898E  bitmaps and palettes (the retired HDAE5000_Font_Data label
;                claimed font data at 0x2BA1A6; there is none -- see
;                hdae5000_data_tables.s)
;   0x2E1C82  the C program's .rodata, 0x2E1C82-0x2E3703, one label per object
;                (strings, switch tables, templates), each naming its readers
;                (scripts/generators/gen_hdae5000_rodata.py).  The six range
;                names that stood here (Config/Test/Dir/Path strings, Char
;                tables, UI icons) did not survive that typing.
;   0x2E3704  HDAE5000_Multilingual_Messages - Trilingual UI messages (EN/DE/FR)
;   0x2E5B80  the lyrics module's .rodata, 0x2E5B80-0x2E5DCD (gen_hdae5000_rodata.py
;                --block2): lyric messages, TLhd/TLtr tags, .TLX/.TTX/.MID
;   0x2F8DCE  HDAE5000_Display_Params - File extensions, device names, config
;   0x2F94B2  HDAE5000_Init_Data - Data copied to 0x23952A (0xC82 bytes)
;
; RAM Workspace (0x23xxxx):
;   0x23A19E  HDAE5000_RAM_LyricBoxObj - the open lyric box's object id
;   0x23A1A2  HDAE5000_RAM_MainWorkspacePtr - the main CPU's object table (0x027ED2)
;   0x230EC2  HDAE5000_WORK_TEMP - Temporary work variable
;   0x230EC4  HDAE5000_STATE_VAR - State variable
;   0x230EC6  HDAE5000_CALC_RESULT - Calculation result storage
;   0x230ECC  HDAE5000_HANDLER_1 - Handler function pointer 1
;   0x230ED0  HDAE5000_PREV_STATE - Previous state value
;   0x230ED2  HDAE5000_HANDLER_2 - Handler function pointer 2
;   0x230ED6  HDAE5000_HANDLER_3 - Handler function pointer 3
;   0x230EDA  HDAE5000_INIT_FLAG - Initialization result flag
;   0x22A000  HDAE5000_WORK_BUFFER - Work buffer (0xF52A bytes, cleared at init)
;   0x23952A  HDAE5000_DATA_COPY_DEST - Data copy destination
;
; Hard Disk RAM Variables (0x229Dxx):
;   0x229D90  HD_STATUS_FLAG - Current drive status
;   0x229D92  HDAE5000_RAM_HdInitResult - HD_Init's step code (0 = no HD)
;   0x229D99  HDAE5000_RAM_WriteProtect .. 0x229DAE HDAE5000_RAM_LyricBackColor -
;             the user settings (write protection/confirm, quick load, load by
;             number, jump after load, lyric jump and colours), not drive flags
;   0x229DC8  HD_CONTROL_FLAG - Control register shadow
;   0x229DD9  HD_ENABLE_FLAG - Drive enabled flag
;   0x23A08E  HDAE5000_RAM_DirPageBase - first directory of the list page
;
; Hard Disk Interface:
;   The HD-AE5000 uses an IDE/ATA hard disk accessed via PPI bridge.
;   The disk uses CHS (Cylinder/Head/Sector) addressing.
;   Debug strings reveal parameters: hddtrck, hddhead, hddsctr, hddscby
;
; Filesystem Structures:
;   FSB - File System Block (master metadata)
;   FGB - File Group Block (file grouping)
;   FEB - File Entry Block (individual file metadata)
;
; PPORT (PC Parallel Port) Command Menu:
;   The HD-AE5000 provides a parallel port interface for PC communication.
;   Command menu strings at 0x295412 define available operations:
;
;   01>Send Infos About HD   - Send HD information to PC
;   02>Exit PPORT            - Exit PPORT mode
;   03>Read FSB from HD      - Read File System Block from HD
;   04>Sending FSB to PC     - Transfer FSB data to PC
;   05>Rcv FSB from PC       - Receive FSB data from PC
;   06>Writing FSB to HD     - Write FSB data to HD
;   07>Load HD to Memory     - Load HD content to memory
;   08>Send data to PC       - Send data block to PC
;   09>Sending files to PC   - Transfer files to PC
;   10>Rcv data from PC      - Receive data from PC
;   11>Save memory to HD     - Save memory content to HD
;   12>nothing               - (reserved)
;   13>Rcv data from PC      - Receive data from PC (variant)
;   14>Sending infos to PC   - Send info block to PC
;   15>nothing               - (reserved)
;   16>Delete files          - Delete files from HD
;   17>Formating HD          - Format hard disk
;   18>Switch HD-motor off   - Turn off HD motor
;   19>nothing               - (reserved)
;   20>Send XapFile flash    - Flash XapFile data
;
; PPORT Command Handler Jump Table at 0x2953E2:
;   Contains 17 handler addresses for commands 01-17+


	.org 0x280000 - 0x280000, 0xFF

; ============================================================================
; ROM HEADER
; ============================================================================

HDAE5000_ROM_HEADER:
	.ascii "XAPR4"	; Magic identifier ("XAPR" checked by main CPU)
	.byte 0xa1	; Version byte
	.byte 0x2f, 0x00	; Unknown (possibly size/flags)

; Entry point 1 - Jump to boot initialization
HDAE5000_ENTRY_1:	; 280008h
	jp HDAE5000_Boot_Init	; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:	; 280010h
	jp HDAE5000_Frame_Handler	; Called from main loop for HD status updates

; Padding after vector
	ret
	nop
	nop
	nop

; Unused entry vectors (return immediately)
HDAE5000_ENTRY_3:	; 280018h
	ret
	nop
	nop
	nop

HDAE5000_ENTRY_4:	; 28001Ch
	ret
	nop
	nop
	nop

; ============================================================================
; CODE SECTION 1 (0x280020 - 0x28F575)
;
; Key routines:
;   0x280020  Handler_Registration - Register 11 handlers with main CPU workspace
;   0x28030E  Alloc_Memory_1 - Bitmap resource descriptor, HDAE5000_Bitmap_TitleLogo
;                             (A1 = 0x2A898E bitmap data, not a palette)
;   0x28033B  Alloc_Memory_2 - Bitmap resource descriptor, HDAE5000_Bitmap_DriveMech
;                             (A1 = 0x2BB98E bitmap data, not a palette)
;   0x280368  Alloc_Memory_3 - Bitmap resource descriptor, HDAE5000_Bitmap_FilePanel
;                             (A1 = 0x2CE98E bitmap data, not a palette)
;   0x280395  BitmapHdd_icon - Bitmap resource descriptor, HDAE5000_Bitmap_HddIcon
;                             (A1 = 0x2E198E bitmap data, not a palette; unlike
;                              its three neighbours this one carries the
;                              firmware's own registry name)
;   0x2803C2  HDAE5000_UiState_Reset - (was Register_Frame; see its header)
;   0x28F543  Alloc_Memory - Bitmap resource descriptor for the boot splash
;                             (A1 = 0x2E61CE HDAE5000_Bitmap_BootSplash, A2 = 320,
;                              A3 = 240 -- bitmap data, not a palette)
; ============================================================================

; ----------------------------------------------------------------------------
; HDAE5000_Handler_Registration (0x280020 - 0x28030D)
;
; Registers this module's eleven object tables with the main CPU's
; RootFn_RegisterObjectTable, then its title with RootFn_RegisterTitle -- the
; same sequence, with the same class ids and procs, as the main CPU's own
; InitializeRoot (module 0) and InitializeHama (module 9) in the v10 source;
; the HD-AE5000 is module 0x0A: table index = kind + 0x0A.
; Called from HDAE5000_Boot_Init after the workspace pointer is stored.
;
; The workspace is the main CPU's object table at 0x027ED2: 14-byte records
; at 0x027ED2 + 14 * index (RegisterObjectTable), each {+0 class id,
; +4 proc, +8 count, +10 data}.  (Tables 0x100 and 0x109 are the ones this ROM
; calls through: WS_RootFnTable / WS_HamaFnTable.)
;
; Registration record (14 bytes on the stack):
;   (XSP+0x00): class id of the proc (0x016000nn -- InitializeRoot pairs the
;               same ids with the same procs)
;   (XSP+0x04): the proc, read from the main CPU's function table
;   (XSP+0x08): entry count
;   (XSP+0x0A): table pointer
;
; Handler Registration Table:
;   index  class id    proc              count  table
;   0x016A 0x01600004  ClassProc         13     0x29C0AA   classes (13 records)
;   0x01CA 0x0160000C  ResEventProc      var    0x2397EA
;   0x01EA 0x0160000D  ResMethodProc     var    0x239824
;   0x012A 0x01600002  ApFunctionProc    0x45   0x23952A   ApFunction table
;   0x042A 0x01600002  ApFunctionProc    0x45   0x239642   ... its names
;   0x010A 0x01600001  FunctionProc      0x0D   0x239872   Function table
;   0x040A 0x01600001  FunctionProc      0x0D   0x2398AA   ... its names
;   0x014A 0x01600003  MainFunctionProc  0x0E   0x239FD2   MainFunction table
;   0x044A 0x01600003  MainFunctionProc  0x0E   0x23A00E   ... its names
;   0x007F 0x01600010  ViewableProc      0x315  0x2A5D2C   UI object descriptor table
;   0x037F 0x0160000F  ResNameProc       0x315  0x2A6984   UI object name table
;   (0x7F / 0x37F replace the empty tables InitializeHama registers there.)
;          (for these two the "Size" word is an ENTRY COUNT: 0x315 = 789
;           objects; both tables hold 790 .long entries, the last a
;           terminator - see hdae5000_data_tables.s)
;   then RegisterTitle(0x7F, 0x014A0000, HDAE5000_OBJ_IV_HDDMENU; stack: name
;   "TT_HDDEXT" at 0x2A849A, module 0x0A) -- InitializeHama registers title
;   0x7F the same way with 0x01490000 and module 9.
;
; Each registration calls RootFn_RegisterObjectTable with:
;   WA = table index
;   XBC = pointer to the record on the stack
; ----------------------------------------------------------------------------

HDAE5000_Handler_Registration:	; 280020h
	; Allocate 14-byte parameter block on stack
	lda xsp, (xsp - 14)	; lda XSP, XSP - 0Eh  (allocate 14 bytes)

	; === table 0x16A: ClassProc, the module's 13 classes (class id 0x01600004) ===
	; Record count = 13 (from ROM at 0x29D97E)
	; Data table = 0x29C0AA (13 records x 24 bytes each)
	; Handler function = ClassProc (0xFA44E2) via workspace[0x0E0A][0x0168]
	ld xwa, 0x1600004	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA  ; class id
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)             ; Handler dispatch table
	ld XWA, (xwa + RootFn_ClassProc)             ; Handler function via table offset 0x0168
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA  ; handler function ptr
	ld wa, (0x29d97e:24)
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; record count (= 13)
	lda xwa, (0x29c0aa:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA  ; data pointer
	lda xwa, (xsp)	; lda XWA, XSP  ; XWA = param block ptr
	ld xbc, xwa	; XBC = param block ptr
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable function
	ldw wa, 0x16A	; Handler ID
	call (xhl)	; Register handler

	; === table 0x1CA: ResEventProc (class id 0x0160000C) ===
	ld xwa, 0x160000C	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ResEventProc)             ; Handler function via table offset 0x013C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ld wa, (0x239822:24)
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	lda xwa, (0x2397ea:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x1CA	; Handler ID
	call (xhl)

	; === table 0x1EA: ResMethodProc (class id 0x0160000D) ===
	ld xwa, 0x160000D	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ResMethodProc)             ; Handler function via table offset 0x0140
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ld wa, (0x239870:24)
	ld (xsp + 8), wa	; ld (XSP+0x08), WA   ; data size (variable)
	lda xwa, (0x239824:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x1EA	; Handler ID
	call (xhl)

	; === table 0x12A: ApFunctionProc, the module's ApFunction table (class id 0x01600002) ===
	ld xwa, 0x1600002	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ApFunctionProc)             ; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	lda xwa, (0x23952a:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x12A	; Handler ID
	call (xhl)

	; === table 0x42A: the names of table 0x12A ===
	ld xwa, 0x1600002	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ApFunctionProc)             ; Handler function via table offset 0x0248
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x45	; ld (XSP+0x08), 0045h  ; size = 69 bytes
	lda xwa, (0x239642:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x42A	; Handler ID
	call (xhl)

	; === table 0x10A: FunctionProc, the module's Function table (class id 0x01600001) ===
	ld xwa, 0x1600001	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_FunctionProc)             ; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	lda xwa, (0x239872:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x10A	; Handler ID
	call (xhl)

	; === table 0x40A: the names of table 0x10A ===
	ld xwa, 0x1600001	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_FunctionProc)             ; Handler function via table offset 0x0244
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xD	; ld (XSP+0x08), 000Dh  ; size = 13 bytes
	lda xwa, (0x2398aa:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x40A	; Handler ID
	call (xhl)

	; === table 0x14A: MainFunctionProc, the module's MainFunction table (class id 0x01600003) ===
	ld xwa, 0x1600003	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_MainFunctionProc)             ; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	lda xwa, (0x239fd2:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x14A	; Handler ID
	call (xhl)

	; === table 0x44A: the names of table 0x14A ===
	ld xwa, 0x1600003	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_MainFunctionProc)             ; Handler function via table offset 0x024C
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0xE	; ld (XSP+0x08), 000Eh  ; size = 14 bytes
	lda xwa, (0x23a00e:24)
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x44A	; Handler ID
	call (xhl)

	; === table 0x7F: ViewableProc, the UI object descriptor table (class id 0x01600010) ===
	ld xwa, 0x1600010	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ViewableProc)             ; Handler function via table offset 0x0280
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; entry count = 789 objects
	lda xwa, (0x2a5d2c:24)	; = HDAE5000_UiObject_PtrTable
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x7F	; Handler ID
	call (xhl)

	; === table 0x37F: ResNameProc, the UI object names (class id 0x0160000F) ===
	ld xwa, 0x160000F	; class id
	ld (xsp + 256), xwa	; ld (XSP+0x00), XWA
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XWA, (xwa + RootFn_ResNameProc)             ; Handler function via table offset 0x0148
	ld (xsp + 4), xwa	; ld (XSP+0x04), XWA
	ldw (xsp + 8), 0x315	; ld (XSP+0x08), 0315h  ; entry count = 789 objects
	lda xwa, (0x2a6984:24)	; = HDAE5000_UiObjectName_PtrTable
	ld (xsp + 10), xwa	; ld (XSP+0x0A), XWA
	lda xwa, (xsp)	; lda XWA, XSP
	ld xbc, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld_sril XHL, (xwa + RootFn_RegisterObjectTable)             ; RegisterObjectTable
	ldw wa, 0x37F	; Handler ID
	call (xhl)

	; === RootFn_RegisterTitle: title 0x7F = "TT_HDDEXT" ===
	pushw 0xA	; module number 0x0A (InitializeHama pushes 9)
	lda xwa, (0x2a849a:24)
	push xwa	; the title's name, "TT_HDDEXT"
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld XWA, (xwa + WS_RootFnTable)
	ld XHL, (xwa + RootFn_RegisterTitle)
	ld xwa, 0x7F	; title number
	ld xbc, 0x14A0000	; entry 0 of MainFunction table 0x14A
	ld xde, HDAE5000_OBJ_IV_HDDMENU	; the title's view object
	call (xhl)

	; Deallocate the 14-byte record (RegisterTitle's retd 6 popped its pushes)
	lda xsp, (xsp + 14)	; lda XSP, XSP + 0Eh  (deallocate 14 bytes)
	ret

; ----------------------------------------------------------------------------
; Bitmap resource descriptors (0x28030E - 0x2803C1)
;
; Four constant lookups, one per embedded bitmap.  They allocate nothing, so
; the "Alloc_Memory" spelling is a misnomer; the first three keep it only
; because the firmware publishes no name for them.  The fourth one it does
; publish: HDAE5000_ObjHandler_Table entry 39 is 0x280395 and the parallel
; HDAE5000_ObjName_Table entry points at 0x29BD0A = "BitmapHdd_icon".
;
; Input:  XBC = request type
;           0x01E000A1 -> base address of the bitmap DATA, not a palette (the
;                        same immediates are the MemCopy sources at 0x2804BB,
;                        0x280599 and 0x280677 -- see hdae5000_data_tables.s)
;           0x01E000A2 -> width
;           0x01E000A3 -> height
; Output: XHL = the answer, or 0 for any other request
; ----------------------------------------------------------------------------

HDAE5000_Alloc_Memory_1:	; 28030Eh
	; Returns 0x2A898E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_1__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_1__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_1__type_A1
	ld xhl, 0:i3
	ret
HDAE5000_Alloc_Memory_1__type_A1:
	lda xhl, (0x2a898e:24); Palette data pointer 1
	ret
HDAE5000_Alloc_Memory_1__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_1__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

HDAE5000_Alloc_Memory_2:	; 28033Bh
	; Returns 0x2BB98E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_2__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_2__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_2__type_A1
	ld xhl, 0:i3
	ret
HDAE5000_Alloc_Memory_2__type_A1:
	lda xhl, (0x2bb98e:24); Palette data pointer 2
	ret
HDAE5000_Alloc_Memory_2__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_2__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

HDAE5000_Alloc_Memory_3:	; 280368h
	; Returns 0x2CE98E for A1, 0x140 for A2, 0xF0 for A3
	cp xbc, 0x1E000A3
	jr z, HDAE5000_Alloc_Memory_3__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_Alloc_Memory_3__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_Alloc_Memory_3__type_A1
	ld xhl, 0:i3
	ret
HDAE5000_Alloc_Memory_3__type_A1:
	lda xhl, (0x2ce98e:24); Palette data pointer 3
	ret
HDAE5000_Alloc_Memory_3__type_A2:
	ld xhl, 0x140	; 320 (width)
	ret
HDAE5000_Alloc_Memory_3__type_A3:
	ld xhl, 0xF0	; 240 (height)
	ret

; --- HDAE5000_BitmapHdd_icon (was HDAE5000_Alloc_Memory_4) -------------------
; The label is the firmware's own name.  HDAE5000_ObjHandler_Table entry 39
; (ROM 0x2F94B2 + 0x9C) holds 0x280395, and the parallel HDAE5000_ObjName_Table
; entry (ROM 0x2F95CA + 0x9C) points at 0x29BD0A = "BitmapHdd_icon".
HDAE5000_BitmapHdd_icon:	; 280395h
	; Resource descriptor for HDAE5000_Bitmap_HddIcon.  Allocates nothing.
	cp xbc, 0x1E000A3
	jr z, HDAE5000_BitmapHdd_icon__type_A3
	cp xbc, 0x1E000A2
	jr z, HDAE5000_BitmapHdd_icon__type_A2
	cp xbc, 0x1E000A1
	jr z, HDAE5000_BitmapHdd_icon__type_A1
	ld xhl, 0:i3
	ret
HDAE5000_BitmapHdd_icon__type_A1:
	lda xhl, (0x2e198e:24); HDAE5000_Bitmap_HddIcon data, NOT a palette
	ret
HDAE5000_BitmapHdd_icon__type_A2:
	ld xhl, 0x1B	; 27 (icon width)
	ret
HDAE5000_BitmapHdd_icon__type_A3:
	ld xhl, 0x1B	; 27 (icon height)
	ret

; ============================================================================
; CODE SECTION 1: Setup, HD interface, filesystem, and UI routines
; 0x2803C2-0x28F542 (61,825 bytes, 64 identified routines)
;
; Hardware access:
;   PPI 8255 ports at 0x160000-0x160006 (IDE/ATA bridge to HD)
;   VGA registers via memory-mapped I/O
;   HD config flags at 0x229D90-0x229DAE
;   Workspace at 0x23A1A2 (shared with main CPU)
;
; Subsystem groups:
;   0x2803C2-0x2827F3  Frame registration and event dispatch (9,266 bytes)
;   0x2827F4-0x282B97  Event handler (932 bytes)
;   0x282B98-0x282E3B  PPI/IDE low-level I/O (1,188 bytes)
;   0x282E8D-0x28541B  HD drive setup and configuration (9,615 bytes)
;   0x28541C-0x287054  HD config manager and CHS geometry (7,225 bytes)
;   0x2870D6-0x28A2EF  Filesystem operations (12,826 bytes)
;   0x28A2F0-0x28B3E9  Display, menu, and utility routines (4,346 bytes)
;   0x28B3EA-0x28F542  UI handler, file ops, path/string utilities (16,857 bytes)
; ============================================================================

HDAE5000_UiState_Reset:	; 0x2803C2
	; Reset the browser selection (0x23A08E, 0x23A092 directory, 0x23A094
	; song = 0), the load-by-number block 0x22AA58 (template 0x2E1CA2), and
	; the save-option record 0x22AA4C (template 0x2E1C96, mask 0x1FF, then
	; "YES" for the parts the selected song holds -- HDAE5000_TypeSel_Init);
	; ends in HDAE5000_Set_Menu_Visibility(1).  Caller: HDAE5000_Boot_Init.
	; (Was Register_Frame, "(9266 bytes)".)
; LRF: 0x2803C2 (9266 bytes)
	; ^ conversion-region size (local-label prefix .LRF_), not a routine size.

	ldw	(HDAE5000_RAM_DirPageBase:24), 0
	ldw	(HDAE5000_RAM_CurDir:24), 0
	ldw	(HDAE5000_RAM_CurSong:24), 0
	ld	xiy, HDAE5000_Lbn_BlockTemplate
	ld	xix, 0x0022aa58
	ld	bc, 5:i3
	ldirw                                   ; ldirw
	ld	xiy, HDAE5000_TypeSel_TemplateBlank
	ld	xix, HDAE5000_RAM_SaveOptions
	ld	bc, 6:i3
	ldirw                                   ; ldirw
	ldw	(HDAE5000_RAM_SaveOptions:24), 511
	ld	wa, (HDAE5000_RAM_CurDir:24)
	ld	bc, (HDAE5000_RAM_CurSong:24)
	call HDAE5000_Song_PartMask
	ld	wa, hl
	cp	wa, 0xffff
	jr z, .LRF_0424                        ; [66 14] jr Z,0x280424
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	ld	bc, hl
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	calr	HDAE5000_TypeSel_Init
	jr t, .LRF_0436                        ; [68 12] jr T,0x280436
.LRF_0424:
	lda xwa, (HDAE5000_RAM_SaveOptions:24)
	pushw 0x0002
	lda xde, (HDAE5000_TypeSel_TemplateBlank:24)
	ld	bc, 0:i3
	calr	HDAE5000_TypeSel_Init
.LRF_0436:
	ld	wa, 1:i3
	jp HDAE5000_Set_Menu_Visibility                             ; jp 0x28b258

HDAE5000_AcWindowPage1Proc:
	; registered as "AcWindowPage1Proc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld (xsp + 0x08), xbc                    ; ld (XSP+0x08),XBC
	ld	xiz, xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	cp	xwa, 0x01c00001
	jr nz, .LRF_046c                       ; [6e 1a] jr NZ,0x28046c
	ld	xwa, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e0007f
	ld	xde, 1:i3
	call	(xhl)
.LRF_046c:
	ld	xwa, xiz
	ld xbc, (xsp + 0x08)                    ; ld XBC,(XSP+0x08)
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_TtlScreenRProc:
	; registered as "TtlScreenRProc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_0537                       ; [76 98 00] jrl Z,0x280537
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_054a                      ; [7e a2 00] jrl NZ,0x28054a
	ld	xwa, 0:i3
	ld	xbc, 0x01e000a1
	ld	xde, 0:i3
	calr	HDAE5000_Alloc_Memory_1
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_051a                        ; [66 62] jr Z,0x28051a
	pushw 0x9600
	lda xwa, (0x2a898e:24)
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda xwa, (0x2b1f8e:24)
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda xwa, (0x2a858e:24)
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangeWall)
	ld	wa, 3:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 3:i3
	call	(xhl)
.LRF_051a:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_0563                        ; [68 2c] jr T,0x280563
.LRF_0537:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 2:i3
	call	(xhl)
.LRF_054a:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_0563:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_TtlScreenR2Proc:
	; registered as "TtlScreenR2Proc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_0615                       ; [76 98 00] jrl Z,0x280615
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_0628                      ; [7e a2 00] jrl NZ,0x280628
	ld	xwa, 0:i3
	ld	xbc, 0x01e000a1
	ld	xde, 0:i3
	calr	HDAE5000_Alloc_Memory_2
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_05f8                        ; [66 62] jr Z,0x2805f8
	pushw 0x9600
	lda xwa, (0x2bb98e:24)
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda xwa, (0x2c4f8e:24)
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda xwa, (0x2bb58e:24)
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangeWall)
	ld	wa, 3:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 3:i3
	call	(xhl)
.LRF_05f8:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_0641                        ; [68 2c] jr T,0x280641
.LRF_0615:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 2:i3
	call	(xhl)
.LRF_0628:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_0641:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_TtlScreenR3Proc:
	; registered as "TtlScreenR3Proc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jrl z, .LRF_06f3                       ; [76 98 00] jrl Z,0x2806f3
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_0706                      ; [7e a2 00] jrl NZ,0x280706
	ld	xwa, 0:i3
	ld	xbc, 0x01e000a1
	ld	xde, 0:i3
	calr	HDAE5000_Alloc_Memory_3
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_06d6                        ; [66 62] jr Z,0x2806d6
	pushw 0x9600
	lda xwa, (0x2ce98e:24)
	push xwa
	ld	xwa, 0x00056800
	push xwa
	call HDAE5000_MemCopy
	pushw 0x9600
	lda xwa, (0x2d7f8e:24)
	push xwa
	ld	xwa, 0x0005fe00
	push xwa
	call HDAE5000_MemCopy
	pushw 0x0400
	lda xwa, (0x2ce58e:24)
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+30)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangeWall)
	ld	wa, 3:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 3:i3
	call	(xhl)
.LRF_06d6:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_071f                        ; [68 2c] jr T,0x28071f
.LRF_06f3:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 2:i3
	call	(xhl)
.LRF_0706:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_071f:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_IvScreenR2Proc:
	; registered as "IvScreenR2Proc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld (xsp + 0x04), xde                    ; ld (XSP+0x04),XDE
	ld	xiz, xbc
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld	xwa, xiz
	cp	xwa, 0x01c00002
	jr z, .LRF_07a9                        ; [66 71] jr Z,0x2807a9
	cp	xwa, 0x01c0000d
	jr nz, .LRF_07bc                       ; [6e 7c] jr NZ,0x2807bc
	ld	xwa, 0:i3
	ld	xbc, 0x01e000a1
	ld	xde, 0:i3
	calr	HDAE5000_Alloc_Memory_2
	or xhl, xhl                             ; or XHL,XHL
	jr z, .LRF_078c                        ; [66 3c] jr Z,0x28078c
	pushw 0x0400
	lda xwa, (0x2bb58e:24)
	push xwa
	ld	xwa, 0x00069400
	push xwa
	call HDAE5000_MemCopy
	lda	xsp, (xsp+10)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangeWall)
	ld	wa, 3:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 3:i3
	call	(xhl)
.LRF_078c:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_07d5                        ; [68 2c] jr T,0x2807d5
.LRF_07a9:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_HamaFnTable)
	ld	xhl, (xwa + HamaFn_ChangePalette)
	ld	wa, 2:i3
	call	(xhl)
.LRF_07bc:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, xiz
	ld xde, (xsp + 0x04)                    ; ld XDE,(XSP+0x04)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_07d5:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_SelectListProc:
	; registered as "SelectListProc" in HDAE5000_ClassProc_Table
	lda	xsp, (xsp-104)
	push xiz
	ld (xsp + 0x60), xde                    ; ld (XSP+0x60),XDE
	ld (xsp + 0x64), xbc                    ; ld (XSP+0x64),XBC
	ld (xsp + 0x68), xwa                    ; ld (XSP+0x68),XWA
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	cp	xwa, 0x01ca0002
	jrl z, .LRF_11d8                       ; [76 e6 09] jrl Z,0x2811d8
	cp	xwa, 0x01ca0001
	jrl z, .LRF_11d8                       ; [76 dd 09] jrl Z,0x2811d8
	cp	xwa, 0x01ca0000
	jrl z, .LRF_11d8                       ; [76 d4 09] jrl Z,0x2811d8
	cp	xwa, 0x01c00018
	jrl z, .LRF_0f6a                       ; [76 5d 07] jrl Z,0x280f6a
	cp	xwa, 0x01c0001a
	jrl z, .LRF_0f6a                       ; [76 54 07] jrl Z,0x280f6a
	cp	xwa, 0x01c00017
	jrl z, .LRF_0f6a                       ; [76 4b 07] jrl Z,0x280f6a
	cp	xwa, 0x01c00019
	jrl z, .LRF_0f6a                       ; [76 42 07] jrl Z,0x280f6a
	cp	xwa, 0x01ea000a
	jrl z, .LRF_0f44                       ; [76 13 07] jrl Z,0x280f44
	cp	xwa, 0x01ea0004
	jrl z, .LRF_0f03                       ; [76 c9 06] jrl Z,0x280f03
	cp	xwa, 0x01ea0003
	jrl z, .LRF_0e6d                       ; [76 2a 06] jrl Z,0x280e6d
	cp	xwa, 0x01ea0002
	jrl z, .LRF_0dcc                       ; [76 80 05] jrl Z,0x280dcc
	cp	xwa, 0x01c0000f
	jrl z, .LRF_0a91                       ; [76 3c 02] jrl Z,0x280a91
	cp	xwa, 0x01c0000b
	jrl z, .LRF_09a4                       ; [76 46 01] jrl Z,0x2809a4
	cp	xwa, 0x01c00002
	jrl z, .LRF_0965                       ; [76 fe 00] jrl Z,0x280965
	cp	xwa, 0x01c00001
	jr z, .LRF_08b5                        ; [66 46] jr Z,0x2808b5
	cp	xwa, 0x01c0000d
	jrl nz, .LRF_120b                      ; [7e 93 09] jrl NZ,0x28120b
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	ld	xde, 0xffffffff
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 70 09] jrl T,0x281225
.LRF_08b5:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	ldw	(xwa), 0x0001
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+50), 0x0000
	jr z, .LRF_0942                        ; [66 49] jr Z,0x280942
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialUp)
	ld	xbc, 0x01c00018
	ld	xde, 0:i3
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialDown)
	ld	xbc, 0x01c00017
	ld	xde, 0:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetDialEnable)
	ld	wa, 1:i3
	call	(xhl)
.LRF_0942:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01c00001
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 c0 08] jrl T,0x281225
.LRF_0965:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	ldw	(xwa), 0x0000
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 81 08] jrl T,0x281225
.LRF_09a4:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	cpw	(xwa+42), 0x0002
	jrl lt, .LRF_0a8c                      ; [71 ad 00] jrl LT,0x280a8c
	lda	xwa, (xsp+80)
	ld	xbc, xwa
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_GetClientBox)
	call	(xhl)
	ld	bc, (xsp+84)
	sub	bc, (xsp+80)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2a, bc		; divs XBC,(XWA+0x2a)
	ld (xsp + 0x0c), bc
	ld	wa, (xsp+82)
	inc	1, wa
	ld (xsp + 0x5e), wa                     ; ld (XSP+0x5e),WA
	ld	wa, (xsp+86)
	dec	1, wa
	ld (xsp + 0x5a), wa                     ; ld (XSP+0x5a),WA
	ldw (xsp + 0x08), 1
	jr t, .LRF_0a81                        ; [68 61] jr T,0x280a81
.LRF_0a20:
	ld	wa, (xsp+12)
	mul16_rid8 xsp, 0x08, wa		; mul XWA,(XSP+0x08)
	ld	bc, (xsp+80)
	add	bc, wa
	dec	1, bc
	ld (xsp + 0x5c), bc
	ld (xsp + 0x58), bc
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+22), 0x0007
	jr nz, .LRF_0a5f                       ; [6e 22] jr NZ,0x280a5f
	lda	xwa, (xsp+92)
	ld	xde, xwa
	lda	xwa, (xsp+88)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawLine)
	ldw	de, 0x00ff
	call	(xhl)
	jr t, .LRF_0a7e                        ; [68 1f] jr T,0x280a7e
.LRF_0a5f:
	lda	xwa, (xsp+92)
	ld	xde, xwa
	lda	xwa, (xsp+88)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawLine)
	ld	de, 7:i3
	call	(xhl)
.LRF_0a7e:
	incw	1, (xsp+8)
.LRF_0a81:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+42)
	cp	(xsp+8), wa
	jr c, .LRF_0a20                        ; [67 94] jr C,0x280a20
.LRF_0a8c:
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 94 07] jrl T,0x281225
.LRF_0a91:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x26)                    ; ld XWA,(XWA+0x26)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LRF_0abd                       ; [6e 0a] jr NZ,0x280abd
	ld	xwa, (HDAE5000_TextPtrs_01Selectlist0203040506070809)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
	jr t, .LRF_0ac8                        ; [68 0b] jr T,0x280ac8
.LRF_0abd:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x26)                    ; ld XWA,(XWA+0x26)
	ld xwa, (xwa)                           ; ld XWA,(XWA)
	ld (xsp + 0x10), xwa                    ; ld (XSP+0x10),XWA
.LRF_0ac8:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x36)                    ; ld XWA,(XWA+0x36)
	cpw	(xwa), 0x0001
	jr z, .LRF_0ad9                        ; [66 05] jr Z,0x280ad9
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 4c 07] jrl T,0x281225
.LRF_0ad9:
	lda	xwa, (xsp+80)
	ld	xbc, xwa
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_GetClientBox)
	call	(xhl)
	ld	bc, (xsp+84)
	sub	bc, (xsp+80)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2a, bc		; divs XBC,(XWA+0x2a)
	ld (xsp + 0x0c), bc
	ld	bc, (xsp+86)
	sub	bc, (xsp+82)
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	divs16_rid8 xwa, 0x2c, bc		; divs XBC,(XWA+0x2c)
	ld (xsp + 0x0e), bc
	ldw (xsp + 0x08), 0
	ldw (xsp + 0x0a), 0
	ldw (xsp + 0x14), 0
	jrl t, .LRF_0db5                       ; [78 8f 02] jrl T,0x280db5
.LRF_0b26:
	ld	(xsp+22), 0x00
	jr t, .LRF_0b6c                        ; [68 40] jr T,0x280b6c
.LRF_0b2c:
	ld	wa, (xsp+10)
	extz xwa
	add	xwa, (xsp+16)
	cp	(xwa), 0x09
	jr nz, .LRF_0b4f                       ; [6e 16] jr NZ,0x280b4f
	lda	xbc, (xsp+22)
	ld	wa, (xsp+20)
	stib_ind 0x07, 0xE4, 0xE0, 0x00	; ld (XBC+WA),0x00
	incw	1, (xsp+10)
	ldw (xsp + 0x14), 0
	jr t, .LRF_0b79                        ; [68 2a] jr T,0x280b79
.LRF_0b4f:
	lda	xde, (xsp+22)
	ld	wa, (xsp+10)
	extz xwa
	ld	xbc, xwa
	add	xbc, (xsp+16)
	ld	wa, (xsp+20)
	ld	c, (xbc)
	stb_dri c, 0x07, 0xE8, 0xE0	; ld (XDE+WA),C
	incw	1, (xsp+20)
	incw	1, (xsp+10)
.LRF_0b6c:
	ld	wa, (xsp+10)
	extz xwa
	add	xwa, (xsp+16)
	cp	(xwa), 0x00
	jr nz, .LRF_0b2c                       ; [6e b3] jr NZ,0x280b2c
.LRF_0b79:
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	cp	xwa, 0xffffffff
	jr z, .LRF_0b91                        ; [66 0d] jr Z,0x280b91
	ld	wa, (xsp+8)
	extz xwa
	ld xbc, (xsp + 0x60)                    ; ld XBC,(XSP+0x60)
	cp	xbc, xwa
	jrl nz, .LRF_0db2                      ; [7e 21 02] jrl NZ,0x280db2
.LRF_0b91:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld	wa, (xsp+8)
	extz xwa
	div	xwa, bc
	ld	hl, qwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld	wa, (xsp+8)
	extz xwa
	div	xwa, bc
	ld	de, wa
	ld	wa, (xsp+14)
	mul	xwa, hl
	ld	bc, (xsp+82)
	add	bc, wa
	inc	1, bc
	ld (xsp + 0x4a), bc
	ld	wa, bc
	add	wa, (xsp+14)
	dec	1, wa
	ld (xsp + 0x4e), wa                     ; ld (XSP+0x4e),WA
	ld	wa, (xsp+12)
	mul	xwa, de
	ld	bc, (xsp+80)
	add	bc, wa
	inc	1, bc
	ld (xsp + 0x48), bc
	ld	wa, bc
	add	wa, (xsp+12)
	dec	4, wa
	ld (xsp + 0x4c), wa                     ; ld (XSP+0x4c),WA
	ld	wa, (xsp+72)
	ld (xsp + 0x5c), wa                     ; ld (XSP+0x5c),WA
	ld	wa, (xsp+14)
	srl	wa, 0x01
	ld	bc, (xsp+74)
	add	bc, wa
	ld (xsp + 0x5e), bc
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_GetCharDescent)
	call	(xhl)
	ld	iz, hl
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetCharHeight)
	call	(xix)
	sub	hl, iz
	ld	wa, hl
	neg	wa
	exts xwa                                ; exts XWA
	divs	wa, 0x0002
	ld	iz, wa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetCenteredDelta)
	call	(xix)
	add	hl, iz
	add	(xsp+94), hl
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	wa, (xwa)
	cp	wa, (xsp+8)
	jrl nz, .LRF_0d14                      ; [7e b6 00] jrl NZ,0x280d14
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+58), 0x0000
	jr nz, .LRF_0cb1                       ; [6e 49] jr NZ,0x280cb1
	lda	xwa, (xsp+72)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawBox)
	ldw	bc, 0x00ff
	call	(xhl)
	lda	xwa, (xsp+72)
	ld	xhl, xwa
	lda	xwa, (xsp+92)
	ld	xbc, xwa
	lda	xwa, (xsp+22)
	ld	xde, xwa
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	pushw 0x0000
	pushw 0x00f7
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jrl t, .LRF_0db2                       ; [78 01 01] jrl T,0x280db2
.LRF_0cb1:
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawBox)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	lda	xwa, (xsp+72)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawFrame)
	ldw	bc, 0x00f2
	call	(xhl)
	jrl t, .LRF_0db2                       ; [78 9e 00] jrl T,0x280db2
.LRF_0d14:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+58), 0x0000
	jr nz, .LRF_0d69                       ; [6e 4b] jr NZ,0x280d69
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawBox)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	jr t, .LRF_0db2                        ; [68 49] jr T,0x280db2
.LRF_0d69:
	lda	xwa, (xsp+72)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawBox)
	call	(xhl)
	lda	xhl, (xsp+72)
	lda	xbc, (xsp+92)
	lda	xde, (xsp+22)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x1c)                    ; ld XWA,(XWA+0x1c)
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+32)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
.LRF_0db2:
	incw	1, (xsp+8)
.LRF_0db5:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+42)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	muls16_rid8 xwa, 0x2c, bc		; muls XBC,(XWA+0x2c)
	cp	(xsp+8), bc
	jrl c, .LRF_0b26                       ; [77 5f fd] jrl C,0x280b26
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 59 04] jrl T,0x281225
.LRF_0dcc:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	add	de, wa
	jr ge, .LRF_0e15                       ; [69 24] jr GE,0x280e15
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0001
	call	(xhl)
	jr t, .LRF_0e68                        ; [68 53] jr T,0x280e68
.LRF_0e15:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	bc, (xwa+44)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	muls16_rid8 xwa, 0x2a, bc		; muls XBC,(XWA+0x2a)
	cp	de, bc
	jr lt, .LRF_0e49                       ; [61 24] jr LT,0x280e49
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0000
	call	(xhl)
	jr t, .LRF_0e68                        ; [68 1f] jr T,0x280e68
.LRF_0e49:
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ea0003
	call	(xhl)
.LRF_0e68:
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 b8 03] jrl T,0x281225
.LRF_0e6d:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xbc, (xwa + 0x2e)                    ; ld XBC,(XWA+0x2e)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	ld (xbc), wa                            ; ld (XBC),WA
	ld	bc, de
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0002
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 22 03] jrl T,0x281225
.LRF_0f03:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0005
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 e1 02] jrl T,0x281225
.LRF_0f44:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xbc, (xwa + 0x26)                    ; ld XBC,(XWA+0x26)
	ld xwa, (xsp + 0x60)                    ; ld XWA,(XSP+0x60)
	ld (xbc), xwa                           ; ld (XBC),XWA
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 bb 02] jrl T,0x281225
.LRF_0f6a:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	wa, 0:i3
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00051
	ld	xde, 0:i3
	call	(xhl)
	ld	xiz, xhl
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	cp	(xsp+96), xiz
	jrl nz, .LRF_1077                      ; [7e b7 00] jrl NZ,0x281077
	ld xwa, (xsp + 0x64)                    ; ld XWA,(XSP+0x64)
	cp	xwa, 0x01c00017
	jr z, .LRF_0fd4                        ; [66 09] jr Z,0x280fd4
	cp	xwa, 0x01c00019
	jrl nz, .LRF_1072                      ; [7e 9e 00] jrl NZ,0x281072
.LRF_0fd4:
	ldw	wa, 0xffff
.LRF_0fd7:
	ld	bc, wa
	exts xbc                                ; exts XBC
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01ea0002
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+52), 0x0000
	jr z, .LRF_101a                        ; [66 1a] jr Z,0x28101a
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
.LRF_101a:
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cpw	(xwa+50), 0x0000
	jr z, .LRF_106d                        ; [66 49] jr Z,0x28106d
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialUp)
	ld	xbc, 0x01c00018
	call	(xhl)
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xde, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialDown)
	ld	xbc, 0x01c00017
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetDialEnable)
	ld	wa, 1:i3
	call	(xhl)
.LRF_106d:
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 b3 01] jrl T,0x281225
.LRF_1072:
	ld	wa, 1:i3
	jrl t, .LRF_0fd7                       ; [78 60 ff] jrl T,0x280fd7
.LRF_1077:
	ld	xwa, xiz
	inc 1, xwa                              ; inc 1,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_1089                       ; [6e 09] jr NZ,0x281089
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+44)
	jrl t, .LRF_0fd7                       ; [78 4e ff] jrl T,0x280fd7
.LRF_1089:
	ld	xwa, xiz
	inc 2, xwa                              ; inc 2,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_109d                       ; [6e 0b] jr NZ,0x28109d
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld	wa, (xwa+44)
	neg	wa
	jrl t, .LRF_0fd7                       ; [78 3a ff] jrl T,0x280fd7
.LRF_109d:
	ld	xwa, xiz
	inc	3, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_10d1                       ; [6e 2b] jr NZ,0x2810d1
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0006
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 54 01] jrl T,0x281225
.LRF_10d1:
	ld	xwa, xiz
	inc 4, xwa                              ; inc 4,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_1105                       ; [6e 2b] jr NZ,0x281105
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0008
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 20 01] jrl T,0x281225
.LRF_1105:
	ld	xwa, xiz
	inc	5, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_1139                       ; [6e 2b] jr NZ,0x281139
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea000d
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 ec 00] jrl T,0x281225
.LRF_1139:
	ld	xwa, xiz
	inc	6, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_116d                       ; [6e 2b] jr NZ,0x28116d
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0007
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 b8 00] jrl T,0x281225
.LRF_116d:
	ld	xwa, xiz
	inc	7, xwa
	cp	xwa, (xsp+96)
	jr nz, .LRF_11a1                       ; [6e 2b] jr NZ,0x2811a1
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea000c
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_1225                       ; [78 84 00] jrl T,0x281225
.LRF_11a1:
	ld	xwa, xiz
	inc 0, xwa		; inc 0,XWA
	cp	xwa, (xsp+96)
	jr nz, .LRF_11d4                       ; [6e 2a] jr NZ,0x2811d4
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x2e)                    ; ld XWA,(XWA+0x2e)
	ld	de, (xwa)
	exts xde                                ; exts XDE
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_MainFuncCall)
	ld	xbc, 0x01ea0009
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_1225                        ; [68 51] jr T,0x281225
.LRF_11d4:
	ld	xhl, 0:i3
	jr t, .LRF_1225                        ; [68 4d] jr T,0x281225
.LRF_11d8:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	ld xwa, (xwa + 0x22)                    ; ld XWA,(XWA+0x22)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_MainFuncCall)
	call	(xhl)
.LRF_120b:
	ld xwa, (xsp + 0x68)                    ; ld XWA,(XSP+0x68)
	ld xbc, (xsp + 0x64)                    ; ld XBC,(XSP+0x64)
	ld xde, (xsp + 0x60)                    ; ld XDE,(XSP+0x60)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_1225:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+104)
	ret

HDAE5000_DbMemoClProc:
	; registered as "DbMemoClProc" in HDAE5000_ClassProc_Table
	lda	xsp, (xsp-106)
	push xiz
	ld (xsp + 0x6a), xde                    ; ld (XSP+0x6a),XDE
	ld	xiz, xwa
	ld	xwa, xbc
	cp	xwa, 0x01c00025
	jrl z, .LRF_12f0                       ; [76 b2 00] jrl Z,0x2812f0
	cp	xwa, 0x01c0000d
	jr z, .LRF_125f                        ; [66 19] jr Z,0x28125f
	ld	xwa, xiz
	ld xde, (xsp + 0x6a)                    ; ld XDE,(XSP+0x6a)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LRF_140c                       ; [78 ad 01] jrl T,0x28140c
.LRF_125f:
	ld	xwa, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	lda	xwa, (xwa+14)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	de, (xbc+22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_DrawDesignBox)
	ldw	bc, 0x00c5
	call	(xhl)
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	lda	xiy, (xwa+14)
	lda	xix, (xsp+98)
	ld	bc, 4:i3
	ldirw                                   ; ldirw
	incw	4, (xsp+100)
	incw	4, (xsp+98)
	decm	4, (xsp+102)
	decm	4, (xsp+104)
	lda	xwa, (xsp+98)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	de, (xbc+22)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_DrawDesignBox)
	ldw	bc, 0x00c6
	call	(xhl)
	lda xwa, (HDAE5000_Str_DebugTime:24)
	ld	xbc, xwa
	ld	xwa, xiz
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c00025
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_140c                       ; [78 1c 01] jrl T,0x28140c
.LRF_12f0:
	ld	xwa, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld (xsp + 0x04), xhl                    ; ld (XSP+0x04),XHL
	ld	xwa, xhl
	lda	xiy, (xwa+14)
	lda	xix, (xsp+98)
	ld	bc, 4:i3
	ldirw                                   ; ldirw
	incw	5, (xsp+100)
	incw	5, (xsp+98)
	decm	5, (xsp+102)
	decm	5, (xsp+104)
	ld	wa, (xsp+102)
	sub	wa, (xsp+98)
	exts xwa                                ; exts XWA
	divs	wa, 0x0006
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ld	wa, (xsp+98)
	ld (xsp + 0x4e), wa                     ; ld (XSP+0x4e),WA
	ld	wa, (xsp+104)
	dec 0, wa		; dec 0,WA
	ld (xsp + 0x50), wa                     ; ld (XSP+0x50),WA
	lda	xiy, (xsp+98)
	lda	xix, (xsp+90)
	ld	bc, 4:i3
	ldirw                                   ; ldirw
	incw	8, (xsp+92)
	lda	xiy, (xsp+98)
	lda	xix, (xsp+82)
	ld	bc, 4:i3
	ldirw                                   ; ldirw
	ld	wa, (xsp+88)
	dec 0, wa		; dec 0,WA
	ld (xsp + 0x54), wa                     ; ld (XSP+0x54),WA
	ld	wa, (xsp+98)
	ld (xsp + 0x4a), wa                     ; ld (XSP+0x4a),WA
	ld	wa, (xsp+100)
	ld (xsp + 0x4c), wa                     ; ld (XSP+0x4c),WA
	ld xwa, (xsp + 0x6a)                    ; ld XWA,(XSP+0x6a)
	ld (xsp + 0x0a), xwa                    ; ld (XSP+0x0a),XWA
.LRF_136c:
	lda	xwa, (xsp+90)
	ld	xde, xwa
	lda	xwa, (xsp+74)
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_MovePixels)
	call	(xhl)
	lda	xwa, (xsp+82)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	bc, (xbc+22)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld_sril	xhl, (xde + RootFn_DrawBox)
	call	(xhl)
	ld	wa, (xsp+8)
	pushw wa                                ; push WA
	ld xwa, (xsp + 0x0c)                    ; ld XWA,(XSP+0x0c)
	push xwa
	lda	xwa, (xsp+20)
	push xwa
	call HDAE5000_StrNCpy
	lda	xsp, (xsp+10)
	ld	wa, (xsp+8)
	extz xwa
	lda	xbc, (xsp+14)
	add	xbc, xwa
	ld	(xbc), 0x00
	lda	xhl, (xsp+98)
	lda	xbc, (xsp+78)
	lda	xwa, (xsp+14)
	ld	xde, xwa
	ld	xwa, 3:i3
	push xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	pushm	(xwa+24)
	ld xwa, (xsp + 0x0a)                    ; ld XWA,(XSP+0x0a)
	pushm	(xwa+22)
	ld	xwa, xhl
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	lda	xwa, (xsp+14)
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	cp	hl, (xsp+8)
	jr nz, .LRF_140a                       ; [6e 0b] jr NZ,0x28140a
	ld	wa, (xsp+8)
	extz xwa
	add	(xsp+10), xwa
	jrl t, .LRF_136c                       ; [78 62 ff] jrl T,0x28136c
.LRF_140a:
	ld	xhl, 0:i3
.LRF_140c:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+106)
	ret

HDAE5000_AcHddNamingWindowProc:
	; registered as "AcHddNamingWindowProc" in HDAE5000_ClassProc_Table
	lda	xsp, (xsp-48)
	push xiz
	ld (xsp + 0x28), xde                    ; ld (XSP+0x28),XDE
	ld (xsp + 0x2c), xbc                    ; ld (XSP+0x2c),XBC
	ld (xsp + 0x30), xwa                    ; ld (XSP+0x30),XWA
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	cp	xwa, 0x01c00029
	jrl z, .LRF_251f                       ; [76 f5 10] jrl Z,0x28251f
	cp	xwa, 0x01e00081
	jrl z, .LRF_24e7                       ; [76 b4 10] jrl Z,0x2824e7
	cp	xwa, 0x01e00080
	jrl z, .LRF_22b7                       ; [76 7b 0e] jrl Z,0x2822b7
	cp	xwa, 0x01e0007f
	jrl z, .LRF_2231                       ; [76 ec 0d] jrl Z,0x282231
	cp	xwa, 0x01e0007b
	jrl z, .LRF_2224                       ; [76 d6 0d] jrl Z,0x282224
	cp	xwa, 0x01e0003a
	jrl z, .LRF_220f                       ; [76 b8 0d] jrl Z,0x28220f
	cp	xwa, 0x01e00086
	jrl z, .LRF_21df                       ; [76 7f 0d] jrl Z,0x2821df
	cp	xwa, 0x01c00018
	jrl z, .LRF_19ba                       ; [76 51 05] jrl Z,0x2819ba
	cp	xwa, 0x01c0001a
	jrl z, .LRF_19ba                       ; [76 48 05] jrl Z,0x2819ba
	cp	xwa, 0x01c00017
	jrl z, .LRF_19ba                       ; [76 3f 05] jrl Z,0x2819ba
	cp	xwa, 0x01c00019
	jrl z, .LRF_19ba                       ; [76 36 05] jrl Z,0x2819ba
	cp	xwa, 0x01c0000f
	jrl z, .LRF_18c3                       ; [76 36 04] jrl Z,0x2818c3
	cp	xwa, 0x01c0000e
	jrl z, .LRF_172c                       ; [76 96 02] jrl Z,0x28172c
	cp	xwa, 0x01c00002
	jrl z, .LRF_170d                       ; [76 6e 02] jrl Z,0x28170d
	cp	xwa, 0x01c0000c
	jrl z, .LRF_16c0                       ; [76 18 02] jrl Z,0x2816c0
	cp	xwa, 0x01c0000b
	jrl z, .LRF_16c0                       ; [76 0f 02] jrl Z,0x2816c0
	cp	xwa, 0x01c00001
	jrl nz, .LRF_2662                      ; [7e a8 11] jrl NZ,0x282662
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	or xwa, xwa                             ; or XWA,XWA
	jr z, .LRF_14d8                        ; [66 17] jr Z,0x2814d8
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	cp	xwa, 0x00000003
	jr z, .LRF_14d8                        ; [66 0c] jr Z,0x2814d8
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	cp	xwa, 0x00000005
	jrl nz, .LRF_1658                      ; [7e 80 01] jrl NZ,0x281658
.LRF_14d8:
	ld	xwa, (0x22a022)
	or xwa, xwa                             ; or XWA,XWA
	jr nz, .LRF_14eb                       ; [6e 0a] jr NZ,0x2814eb
	ld	xwa, 0x01200005
	ld	(0x22a022), xwa
.LRF_14eb:
	ldw	(0x22A028:24), 0
	ldw	(0x22A02A:24), 0
	ld	xwa, (0x22a022)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_ApFuncCall)
	ld	xbc, 0x01e0007c
	ld	xde, 0:i3
	call	(xix)
	ld	(0x22a026), hl
	cpw	(0x22A026:24), 32
	jr ule, .LRF_152b                      ; [63 07] jr ULE,0x28152b
	ldw	(0x22A026:24), 32
.LRF_152b:
	ld	xwa, (0x22a022)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_ApFuncCall)
	ld	xbc, 0x01e00084
	ld	xde, 0:i3
	call	(xix)
	ld	(0x22a032), hl
	ld	wa, (0x22A032:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_Blank1_Chr5F
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld	(0x22a034), xwa
	cpw	(0x22A032:24), 0
	jr z, .LRF_15b8                        ; [66 4a] jr Z,0x2815b8
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingABC
	ld	bc, 0:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingabc
	ld	bc, 0:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingSymbol
	ld	bc, 0:i3
	call	(xhl)
	jr t, .LRF_1600                        ; [68 48] jr T,0x281600
.LRF_15b8:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingABC
	ld	bc, 1:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingabc
	ld	bc, 1:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetVisible)
	ld	xwa, HDAE5000_OBJ_HddNamingSymbol
	ld	bc, 1:i3
	call	(xhl)
.LRF_1600:
	ld	iz, 0:i3
	cp	iz, (0x22A026:24)
	jr nc, .LRF_1626                       ; [6f 1d] jr NC,0x281626
.LRF_1609:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_1609                        ; [67 e3] jr C,0x281609
.LRF_1626:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	(xbc), 0x00
	lda xwa, (0x22a000:24)
	ld	xbc, xwa
	ld	xwa, (0x22a022)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_ApFuncCall)
	ld	xbc, 0x01e0003a
	call	(xhl)
.LRF_1658:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialUp)
	ld	xbc, 0x01c00017
	ld	xde, 5:i3
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xhl, (xbc + RootFn_SetDialDown)
	ld	xbc, 0x01c00018
	ld	xde, 3:i3
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld	xhl, (xwa + RootFn_SetDialEnable)
	ld	wa, 1:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 bc 0f] jrl T,0x28267c
.LRF_16c0:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ldw	(0x22A02C:24), 65535
	ldw	(0x22A030:24), 65535
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 6f 0f] jrl T,0x28267c
.LRF_170d:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 50 0f] jrl T,0x28267c
.LRF_172c:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a02e), wa
	ld	wa, (0x22A030:24)
	cp	wa, (0x22A02E:24)
	jrl z, .LRF_18be                       ; [76 7d 01] jrl Z,0x2818be
	lda	xwa, (xsp+32)
	ld	xbc, xwa
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_GetClientBox)
	call	(xhl)
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	cpw	(0x22A030:24), 65535
	jrl z, .LRF_1817                       ; [76 9d 00] jrl Z,0x281817
	ld	wa, (0x22A030:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A030:24)
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x1a), wa                     ; ld (XSP+0x1a),WA
	ld	wa, (0x22A030:24)
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	dec	1, wa
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	sll	hl, 0x03
	ld	wa, (xsp+24)
	add	wa, hl
	inc	2, wa
	ld (xsp + 0x1c), wa                     ; ld (XSP+0x1c),WA
	ld	wa, (xsp+26)
	add	wa, 0x0011
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	lda	xwa, (xsp+24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawFrame)
	ldw	bc, 0x00f5
	call	(xhl)
.LRF_1817:
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A02E:24)
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x1a), wa                     ; ld (XSP+0x1a),WA
	ld	wa, (0x22A02E:24)
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	dec	1, wa
	ld (xsp + 0x18), wa                     ; ld (XSP+0x18),WA
	lda	xwa, (xsp+10)
	push xwa
	call HDAE5000_StrLen
	inc 4, xsp                              ; inc 4,XSP
	sll	hl, 0x03
	ld	wa, (xsp+24)
	add	wa, hl
	inc	2, wa
	ld (xsp + 0x1c), wa                     ; ld (XSP+0x1c),WA
	ld	wa, (xsp+26)
	add	wa, 0x0011
	ld (xsp + 0x1e), wa                     ; ld (XSP+0x1e),WA
	lda	xwa, (xsp+24)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawFrame)
	ldw	bc, 0x00f2
	call	(xhl)
	ld	wa, (0x22A02E:24)
	ld	(0x22a030), wa
.LRF_18be:
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 b9 0d] jrl T,0x28267c
.LRF_18c3:
	ld	wa, (0x22A02C:24)
	cp	wa, (0x22A02A:24)
	jrl z, .LRF_19b5                       ; [76 e5 00] jrl Z,0x2819b5
	ldw	(0x22A030:24), 65535
	lda	xwa, (xsp+32)
	ld	xbc, xwa
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_GetClientBox)
	call	(xhl)
	lda	xwa, (xsp+32)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_DrawBox)
	ldw	bc, 0x00f5
	call	(xhl)
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	iz, 0:i3
	jr t, .LRF_198d                        ; [68 6c] jr T,0x28198d
.LRF_1921:
	ld	wa, iz
	extz xwa
	div wa, 0x000d
	ld	wa, qwa
	ld	bc, wa
	sll	bc, 0x04
	ld	wa, (xsp+32)
	add	wa, 0x000e
	add	wa, bc
	ld (xsp + 0x14), wa                     ; ld (XSP+0x14),WA
	ld	wa, iz
	extz xwa
	div wa, 0x000d
	mul	wa, 0x0018
	ld	bc, wa
	ld	wa, (xsp+34)
	add	wa, 0x000a
	add	wa, bc
	ld (xsp + 0x16), wa                     ; ld (XSP+0x16),WA
	lda	xwa, (xsp+32)
	ld	xhl, xwa
	lda	xwa, (xsp+20)
	ld	xbc, xwa
	ld	wa, iz
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	ld	xwa, 0:i3
	push xwa
	pushw 0x00ff
	pushw 0x00f7
	ld	xwa, xhl
	ld xde, (xde)                           ; ld XDE,(XDE)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_DrawString)
	call	(xhl)
	inc	1, iz
.LRF_198d:
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	cp	iz, (xbc)
	jrl ule, .LRF_1921                     ; [73 76 ff] jrl ULE,0x281921
	ld	wa, (0x22A02A:24)
	ld	(0x22a02c), wa
.LRF_19b5:
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 c2 0c] jrl T,0x28267c
.LRF_19ba:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	dec	1, xwa
	cp	xwa, 0x00000000
	jrl c, .LRF_21da                       ; [77 f8 07] jrl C,0x2821da
	cp	xwa, 0x00000008
	jrl ugt, .LRF_21da                     ; [7b ef 07] jrl UGT,0x2821da
	add	xwa, xwa
	add	xwa, HDAE5000_AcHddNamingWindowProc_CaseTable
	ld	wa, (xwa)
	lda xix, (HDAE5000_AcHddNamingWindowProc_Case1:24)
	jp_ind 8, 0x07, 0xF0, 0xE0	; jp T,XIX+WA
HDAE5000_AcHddNamingWindowProc_Case1:
	cpw	(0x22A028:24), 0
	jrl z, .LRF_21da                       ; [76 d1 07] jrl Z,0x2821da
	decw	1, (0x22A028:24)
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 8f 07] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case2:
	ld	wa, (0x22A028:24)
	inc	1, wa
	cp	wa, (0x22A026:24)
	jrl nc, .LRF_21da                      ; [7f 80 07] jrl NC,0x2821da
	incw	1, (0x22A028:24)
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 3e 07] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case3:
	cpw	(0x22A02E:24), 0
	jrl z, .LRF_21da                       ; [76 34 07] jrl Z,0x2821da
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	decw	1, (0x22A02E:24)
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 80 06] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case4:
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	cp	xwa, 0x01c00018
	jrl z, .LRF_1c40                       ; [76 da 00] jrl Z,0x281c40
	cp	xwa, 0x01c0001a
	jrl z, .LRF_1c40                       ; [76 d1 00] jrl Z,0x281c40
	cp	xwa, 0x01c00017
	jr z, .LRF_1b80                        ; [66 09] jr Z,0x281b80
	cp	xwa, 0x01c00019
	jrl nz, .LRF_21da                      ; [7e 5a 06] jrl NZ,0x2821da
.LRF_1b80:
	cpw	(0x22A02E:24), 13
	jrl c, .LRF_21da                       ; [77 50 06] jrl C,0x2821da
	subw	(0x22A02E:24), 13
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 9a 05] jrl T,0x2821da
.LRF_1c40:
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	ld	wa, (0x22A02E:24)
	add	wa, 0x000c
	cp	wa, (xbc)
	jr ugt, .LRF_1cb4                      ; [6b 11] jr UGT,0x281cb4
	cp	(xsp+10), 0x5a
	jr z, .LRF_1caf                        ; [66 06] jr Z,0x281caf
	cp	(xsp+10), 0x7a
	jr nz, .LRF_1cb4                       ; [6e 05] jr NZ,0x281cb4
.LRF_1caf:
	decw	1, (0x22A02E:24)
.LRF_1cb4:
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	ld	wa, (0x22A02E:24)
	add	wa, 0x000d
	cp	wa, (xbc)
	jrl ugt, .LRF_21da                     ; [7b ff 04] jrl UGT,0x2821da
	addw	(0x22A02E:24), 13
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_1d44                       ; [6e 1f] jr NZ,0x281d44
	cp	(xsp+11), 0x50
	jr nz, .LRF_1d44                       ; [6e 19] jr NZ,0x281d44
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	jr t, .LRF_1d57                        ; [68 13] jr T,0x281d57
.LRF_1d44:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
.LRF_1d57:
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 24 04] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case5:
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	ld	wa, (0x22A02E:24)
	inc	1, wa
	cp	wa, (xbc)
	jrl ugt, .LRF_21da                     ; [7b e9 03] jrl UGT,0x2821da
	incw	1, (0x22A02E:24)
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_1e42                       ; [6e 1f] jr NZ,0x281e42
	cp	(xsp+11), 0x50
	jr nz, .LRF_1e42                       ; [6e 19] jr NZ,0x281e42
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	jr t, .LRF_1e55                        ; [68 13] jr T,0x281e55
.LRF_1e42:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xsp+10)
	ld	(xbc), a
.LRF_1e55:
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld	xhl, (xhl + RootFn_SetAutoInc)
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 26 03] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case6:
	ld	iz, (0x22A026:24)
	dec	1, iz
	cp	iz, (0x22A028:24)
	jr ule, .LRF_1ee7                      ; [63 25] jr ULE,0x281ee7
.LRF_1ec2:
	ld	wa, iz
	extz xwa
	ld	xde, 0x0022a000
	add	xde, xwa
	ld	wa, iz
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xde), a
	dec	1, iz
	cp	iz, (0x22A028:24)
	jr ugt, .LRF_1ec2                      ; [6b db] jr UGT,0x281ec2
.LRF_1ee7:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 97 02] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case7:
	ld	iz, (0x22A028:24)
	cp	iz, (0x22A026:24)
	jr nc, .LRF_1f74                       ; [6f 25] jr NC,0x281f74
.LRF_1f4f:
	ld	wa, iz
	extz xwa
	ld	xde, 0x0022a000
	add	xde, xwa
	ld	wa, iz
	inc	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xde), a
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_1f4f                        ; [67 db] jr C,0x281f4f
.LRF_1f74:
	ld	wa, (0x22A026:24)
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 08 02] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case8:
	ldw (xsp + 0x04), 0
	ld	iz, 0:i3
	cp	iz, (0x22A026:24)
	jr nc, .LRF_2002                       ; [6f 22] jr NC,0x282002
.LRF_1fe0:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	cp	a, (xbc)
	jr nz, .LRF_2002                       ; [6e 0c] jr NZ,0x282002
	incw	1, (xsp+4)
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_1fe0                        ; [67 de] jr C,0x281fe0
.LRF_2002:
	ld	wa, (xsp+4)
	cp	wa, (0x22A026:24)
	jrl z, .LRF_21da                       ; [76 cd 01] jrl Z,0x2821da
	ldw (xsp + 0x06), 0
	ld	iz, 0:i3
	cp	iz, (0x22A026:24)
	jr nc, .LRF_2044                       ; [6f 29] jr NC,0x282044
.LRF_201b:
	ld	wa, (0x22A026:24)
	sub	wa, iz
	dec	1, wa
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	cp	a, (xbc)
	jr nz, .LRF_2044                       ; [6e 0c] jr NZ,0x282044
	incw	1, (xsp+6)
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_201b                        ; [67 d7] jr C,0x28201b
.LRF_2044:
	ld	wa, (xsp+4)
	ld (xsp + 0x08), wa                     ; ld (XSP+0x08),WA
	ld	wa, (xsp+6)
	add	(xsp+8), wa
	srlw_rid8 xsp, 0x08		; srlw (XSP+0x08)
	ld	wa, (0x22A026:24)
	inc	1, wa
	extz xwa
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld	xix, (xbc + HamaFn_malloc_X)
	call	(xix)
	ld	xiz, xhl
	ld	wa, (xsp+4)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	push xbc
	ld	xwa, xiz
	push xwa
	call HDAE5000_StrCpy
	ld	wa, (0x22A026:24)
	sub	wa, (xsp+12)
	sub	wa, (xsp+14)
	extz xwa
	add	xwa, xiz
	ld	(xwa), 0x00
	ld	xwa, xiz
	push xwa
	ld	wa, (xsp+20)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	push xbc
	call HDAE5000_StrCpy
	lda	xsp, (xsp+16)
	ld	xwa, xiz
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_HamaFnTable)
	ld	xhl, (xbc + HamaFn_free_X)
	call	(xhl)
	ld	iz, 0:i3
	cp	iz, (xsp+8)
	jr nc, .LRF_20e1                       ; [6f 1b] jr NC,0x2820e1
.LRF_20c6:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cp	iz, (xsp+8)
	jr c, .LRF_20c6                        ; [67 e5] jr C,0x2820c6
.LRF_20e1:
	ld	wa, (xsp+4)
	add	wa, (xsp+6)
	sub	wa, (xsp+8)
	ld	iz, (0x22A026:24)
	sub	iz, wa
	cp	iz, (0x22A026:24)
	jr nc, .LRF_2115                       ; [6f 1d] jr NC,0x282115
.LRF_20f8:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_20f8                        ; [67 e3] jr C,0x2820f8
.LRF_2115:
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	jrl t, .LRF_21da                       ; [78 80 00] jrl T,0x2821da
HDAE5000_AcHddNamingWindowProc_Case9:
	ld	iz, 0:i3
	cp	iz, (0x22A026:24)
	jr nc, .LRF_2180                       ; [6f 1d] jr NC,0x282180
.LRF_2163:
	ld	wa, iz
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	(xbc), a
	inc	1, iz
	cp	iz, (0x22A026:24)
	jr c, .LRF_2163                        ; [67 e3] jr C,0x282163
.LRF_2180:
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01e00080
	ld	xde, 0:i3
	call	(xhl)
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	ld	xde, 0:i3
	call	(xhl)
.LRF_21da:
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 9d 04] jrl T,0x28267c
.LRF_21df:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	push xwa
	lda xwa, (0x22a000:24)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 6d 04] jrl T,0x28267c
.LRF_220f:
	lda xwa, (0x22a000:24)
	push xwa
	ld xwa, (xsp + 0x2c)                    ; ld XWA,(XSP+0x2c)
	push xwa
	call HDAE5000_StrCpy
	inc 0, xsp                              ; inc 0,XSP
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 58 04] jrl T,0x28267c
.LRF_2224:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a022), xwa
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 4b 04] jrl T,0x28267c
.LRF_2231:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a02a), wa
	cpw	(0x22A032:24), 0
	jr nz, .LRF_2264                       ; [6e 22] jr NZ,0x282264
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	extz xwa
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c0002a
	call	(xhl)
.LRF_2264:
	ld	de, (0x22A02A:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TextPtrs_ABC123_Abc123_Chr202123242526
	add	xbc, xwa
	ld xde, (xbc)                           ; ld XDE,(XBC)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingLabel
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 c5 03] jrl T,0x28267c
.LRF_22b7:
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(0x22a028), wa
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01e00080
	call	(xhl)
	lda xwa, (0x22a000:24)
	ld	xde, xwa
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingCursorBox
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	bit_dri 0, 0x07, 0xE4, 0xE0	; bit 0,(XBC+WA)
	jr z, .LRF_2345                        ; [66 24] jr Z,0x282345
	ldw	(0x22A02A:24), 0
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x41
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 5d 01] jrl T,0x2824a2
.LRF_2345:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	bit_dri 1, 0x07, 0xE4, 0xE0	; bit 1,(XBC+WA)
	jr z, .LRF_2387                        ; [66 24] jr Z,0x282387
	ldw	(0x22A02A:24), 1
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x61
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 1b 01] jrl T,0x2824a2
.LRF_2387:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	extz wa                                 ; extz WA
	lda xbc, (HDAE5000_CType_Table:24)
	bit_dri 2, 0x07, 0xE4, 0xE0	; bit 2,(XBC+WA)
	jr z, .LRF_23d2                        ; [66 2d] jr Z,0x2823d2
	cpw	(0x22A02A:24), 2
	jr nz, .LRF_23b5                       ; [6e 07] jr NZ,0x2823b5
	ldw	(0x22A02A:24), 0
.LRF_23b5:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	sub	a, 0x15
	extz wa                                 ; extz WA
	ld	(0x22a02e), wa
	jrl t, .LRF_24a2                       ; [78 d0 00] jrl T,0x2824a2
.LRF_23d2:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	cp	(xbc), 0x20
	jr nz, .LRF_2409                       ; [6e 24] jr NZ,0x282409
	cpw	(0x22A032:24), 0
	jrl nz, .LRF_24a2                      ; [7e b3 00] jrl NZ,0x2824a2
	cpw	(0x22A02A:24), 2
	jr nz, .LRF_23ff                       ; [6e 07] jr NZ,0x2823ff
	ldw	(0x22A02A:24), 0
.LRF_23ff:
	ldw	(0x22A02E:24), 37
	jrl t, .LRF_24a2                       ; [78 99 00] jrl T,0x2824a2
.LRF_2409:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	cp	(xbc), 0x5f
	jr nz, .LRF_2435                       ; [6e 19] jr NZ,0x282435
	cpw	(0x22A02A:24), 2
	jr nz, .LRF_242c                       ; [6e 07] jr NZ,0x28242c
	ldw	(0x22A02A:24), 0
.LRF_242c:
	ldw	(0x22A02E:24), 26
	jr t, .LRF_24a2                        ; [68 6d] jr T,0x2824a2
.LRF_2435:
	lda xwa, (HDAE5000_TextPtrs_Chr21_to_Chr7D:24)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	iz, 0:i3
	jr t, .LRF_2488                        ; [68 47] jr T,0x282488
.LRF_2441:
	ld	wa, iz
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, (xsp+10)
	jr nz, .LRF_2486                       ; [6e 0c] jr NZ,0x282486
	ldw	(0x22A02A:24), 2
	ld	(0x22a02e), iz
.LRF_2486:
	inc	1, iz
.LRF_2488:
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	inc	2, wa
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	cp	iz, (xbc)
	jr ule, .LRF_2441                      ; [63 9f] jr ULE,0x282441
.LRF_24a2:
	ld	de, (0x22A02A:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e0007f
	call	(xhl)
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 95 01] jrl T,0x28267c
.LRF_24e7:
	ld	wa, (0x22A028:24)
	extz xwa
	ld	xbc, 0x0022a000
	add	xbc, xwa
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	(xbc), a
	ld	de, (0x22A028:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00080
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_267c                       ; [78 5d 01] jrl T,0x28267c
.LRF_251f:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	srl	xwa, 0x00
	ld	qwa, 0
	cp	wa, 0:i3
	jrl nz, .LRF_265e                      ; [7e 17 01] jrl NZ,0x28265e
	ld xwa, (xsp + 0x28)                    ; ld XWA,(XSP+0x28)
	ld	bc, wa
	extz xbc                                ; extz XBC
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e0007f
	call	(xhl)
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	ld	wa, (0x22A02E:24)
	cp	wa, (xbc)
	jr ule, .LRF_25ab                      ; [63 20] jr ULE,0x2825ab
	ld	wa, (0x22A032:24)
	mul	wa, 0x0003
	add	wa, (0x22A02A:24)
	extz xwa
	add	xwa, xwa
	ld	xbc, HDAE5000_Str_Chr25_AcHddNamingWindowProc
	add	xbc, xwa
	ld	wa, (xbc)
	ld	(0x22a02e), wa
.LRF_25ab:
	ld	wa, (0x22A02A:24)
	extz xwa
	sll	xwa, 0x02
	ld	xbc, HDAE5000_TablePtrs_AcHddNamingWindowProc
	add	xbc, xwa
	ld xwa, (xbc)                           ; ld XWA,(XBC)
	ld (xsp + 0x06), xwa                    ; ld (XSP+0x06),XWA
	ld	wa, (0x22A02E:24)
	extz xwa
	sll	xwa, 0x02
	ld	xde, xwa
	add	xde, (xsp+6)
	lda	xwa, (xsp+10)
	ld	xbc, xwa
	ld xwa, (xde)                           ; ld XWA,(XDE)
	ld	xde, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xde, (xde + WS_RootFnTable)
	ld	xhl, (xde + RootFn_ConvertStrings)
	call	(xhl)
	cp	(xsp+10), 0x53
	jr nz, .LRF_261c                       ; [6e 2e] jr NZ,0x28261c
	cp	(xsp+11), 0x50
	jr nz, .LRF_261c                       ; [6e 28] jr NZ,0x28261c
	ld	xwa, (0x22a034)
	ld	a, (xwa)
	ld	xbc, 0:i3
	ld	c, a
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00081
	call	(xhl)
	jr t, .LRF_263e                        ; [68 22] jr T,0x28263e
.LRF_261c:
	ld	a, (xsp+10)
	ld	xbc, 0:i3
	ld	c, a
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01e00081
	call	(xhl)
.LRF_263e:
	ld	de, (0x22A02E:24)
	extz xde                                ; extz XDE
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000e
	call	(xhl)
.LRF_265e:
	ld	xhl, 0:i3
	jr t, .LRF_267c                        ; [68 1a] jr T,0x28267c
.LRF_2662:
	ld xwa, (xsp + 0x30)                    ; ld XWA,(XSP+0x30)
	ld xbc, (xsp + 0x2c)                    ; ld XBC,(XSP+0x2c)
	ld xde, (xsp + 0x28)                    ; ld XDE,(XSP+0x28)
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
.LRF_267c:
	pop xiz                                 ; pop XIZ
	lda	xsp, (xsp+48)
	ret

HDAE5000_IvHddNamingProc:
	; registered as "IvHddNamingProc" in HDAE5000_ClassProc_Table
	dec 0, xsp                              ; dec 0,XSP
	push xiz
	ld	xiz, xde
	ld (xsp + 0x04), xbc                    ; ld (XSP+0x04),XBC
	ld (xsp + 0x08), xwa                    ; ld (XSP+0x08),XWA
	ld xwa, (xsp + 0x04)                    ; ld XWA,(XSP+0x04)
	cp	xwa, 0x01c00002
	jrl z, .LRF_276e                       ; [76 d6 00] jrl Z,0x28276e
	cp	xwa, 0x01c00001
	jr z, .LRF_2704                        ; [66 64] jr Z,0x282704
	cp	xwa, 0x01c0000d
	jr z, .LRF_26c4                        ; [66 1c] jr Z,0x2826c4
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	call	(xix)
	jrl t, .LRF_27a4                       ; [78 e0 00] jrl T,0x2827a4
.LRF_26c4:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	lda xwa, (HDAE5000_Str_Name:24)
	ld	xbc, xwa
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xde, xbc
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld_sril	xhl, (xbc + RootFn_SendEvent)
	ld	xbc, 0x01c0000f
	call	(xhl)
	ld	xhl, 0:i3
	jrl t, .LRF_27a4                       ; [78 a0 00] jrl T,0x2827a4
.LRF_2704:
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld	xbc, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xbc, (xbc + WS_RootFnTable)
	ld	xix, (xbc + RootFn_GetViewInstance)
	call	(xix)
	ld xde, (xhl + 0x16)                    ; ld XDE,(XHL+0x16)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xbc, 0x01e0007b
	call	(xhl)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	jr t, .LRF_27a4                        ; [68 36] jr T,0x2827a4
.LRF_276e:
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HddNamingWindow
	ld	xde, 0:i3
	call	(xhl)
	ld xwa, (xsp + 0x08)                    ; ld XWA,(XSP+0x08)
	ld xbc, (xsp + 0x04)                    ; ld XBC,(XSP+0x04)
	ld	xde, xiz
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xhl, 0:i3
.LRF_27a4:
	pop xiz                                 ; pop XIZ
	inc 0, xsp                              ; inc 0,XSP
	ret

HDAE5000_HDTitleMenuProc:
	; registered as "HDTitleMenuProc" in HDAE5000_ClassProc_Table
	ld	xhl, xbc
	cp	xhl, 0x01c0000f
	jr z, .LRF_27c3                        ; [66 11] jr Z,0x2827c3
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xix, (xhl + RootFn_InheritedProc)
	jp	(xix)
.LRF_27c3:
	ld	xhl, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xhl, (xhl + WS_RootFnTable)
	ld_sril	xhl, (xhl + RootFn_InheritedProc)
	call	(xhl)
	ld	xwa, (HDAE5000_RAM_MainWorkspacePtr)
	ld	xwa, (xwa + WS_RootFnTable)
	ld_sril	xhl, (xwa + RootFn_SendEvent)
	ld	xwa, HDAE5000_OBJ_HD_MENU_BMP
	ld	xbc, 0x01c0000d
	ld	xde, 0:i3
	call	(xhl)
	ld	xhl, 0:i3
	ret


HDAE5000_HardTest_Print:	; 0x2827F4 (932 bytes)
	; Print a line on the hardware-test page: XWA = string, sent as event
	; 0x01C00025 to every object (XWA = 0xFFFFFFFF) through the main-CPU
	; workspace 0x0E0A table +0x100 (tail call).  Callers: HDAE5000_HardTestPage
	; and its tests HDAE5000_HardTest_PortTest / _HddIdRead.  (Was "Event
	; handler ... registers callback via vtable": it registers nothing.)
	ld xde, xwa					; e8 8a
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20 — load context base
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20 — xwa = (xwa+0x0e0a) vtable ptr
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — xhl = (xwa+0x0100) callback
	ld xwa, 0xffffffff				; 40 ff ff ff ff
	ld xbc, 0x01c00025				; 41 25 00 c0 01
	jp (xhl)					; b3 d8
	; Entry point 2: main event handler dispatcher
HDAE5000_HardTestPage:
	; registered as "HardTestPage" in HDAE5000_ObjHandler_Table
	dec 0, xsp					; ef 68 — allocate stack frame
	push xiz					; 3e
	ld (xsp + 0x04), xde				; bf 04 62 — save XDE
	ld (xsp + 0x08), xbc				; bf 08 61 — save XBC
	ld xiz, xwa					; e8 8e — save context in XIZ
	ld xwa, (xsp + 0x08)				; af 08 20 — load event code
	cp xwa, 0x01c00007				; e8 cf 07 00 c0 01
	jr z, .Leh_event_c00007			; 66 55
	cp xwa, 0x01c0000d				; e8 cf 0d 00 c0 01
	jr z, .Leh_event_c0000d			; 66 0e
	cp xwa, 0x01e00085				; e8 cf 85 00 e0 01
	jrl nz, .Leh_epilogue				; 7e 43 03
	; Event 0x01E00085: return 1 (acknowledge)
	ld xhl, 1:i3					; eb a9
	jrl t, .Leh_return				; 78 57 03
	; Event 0x01C0000D: forward to vtable callback
.Leh_event_c0000d:
	ld xwa, xiz					; ee 88 — restore context
	ld xbc, (xsp + 0x08)				; af 08 21
	ld xde, (xsp + 0x04)				; af 04 22
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23 — xhl = (xhl+0x0e0a)
	ld_sril xhl, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 23 — xhl = (xhl+0x00dc) indirect call
	call (xhl)					; b3 e8
	lda xwa, (HDAE5000_Str_Test:24); f2 de 21 2e 30
	ld xbc, xwa					; e8 89
	ld xwa, xiz					; ee 88
	ld xde, xbc					; e9 8a
	ld xbc, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 21
	ld xbc, (xbc + WS_RootFnTable)             ; e3 e5 0a 0e 21 — xbc = (xbc+0x0e0a)
	ld_sril xhl, (xbc + RootFn_SendEvent)             ; e3 e5 00 01 23 — xhl = (xbc+0x0100) callback
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	call (xhl)					; b3 e8
	ld xhl, 0:i3					; eb a8
	jrl t, .Leh_return				; 78 18 03
	; Event 0x01C00007: sub-dispatch on XDE value
.Leh_event_c00007:
	ld xwa, (xsp + 0x04)				; af 04 20 — load XDE arg
	cp xwa, 0x0000000c				; e8 cf 0c 00 00 00
	jrl z, .Leh_xde_0c				; 76 62 02
	cp xwa, 0x0000000b				; e8 cf 0b 00 00 00
	jrl z, .Leh_xde_0b				; 76 6a 01
	cp xwa, 0x0000000a				; e8 cf 0a 00 00 00
	jrl z, .Leh_xde_0a				; 76 b5 00
	cp xwa, 0x00000009				; e8 cf 09 00 00 00
	jrl nz, .Leh_epilogue				; 7e d8 02
	; XDE == 0x09: register event 0x4B, call init, register vtable callback
.Leh_xde_09:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23 — callback ptr
	ld xwa, HDAE5000_OBJ_PPORT_SW				; 40 4b 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 1:i3					; ea a9
	call (xhl)					; b3 e8 — register event
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_UpdateScreen)             ; e3 e1 84 00 23 — (xwa+0x0084) init fn
	call (xhl)					; b3 e8 — call init
	call HDAE5000_YieldUntilSem1Zero		; 1d 2b b2 28
	lda xwa, (HDAE5000_Str_PPORTTEST:24); f2 e4 21 2e 30
	calr HDAE5000_HardTest_Print			; 1e 17 ff — register handler
	calr HDAE5000_HardTest_PortTest		; 1e 47 03
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_PPORT_SW				; 40 4b 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8 — unregister event
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24 — xix = callback
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	ld xde, 0:i3					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e 58 02
	; Post-call: push event/subcode, invoke dispatch
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x0000000a				; 40 0a 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23 — (xwa+0x0410) dispatch
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 2c 02
	; XDE == 0x0A: register event 0x4D, write sector
.Leh_xde_0a:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_HDD_SW				; 40 4d 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 1:i3					; ea a9
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_UpdateScreen)             ; e3 e1 84 00 23 — init fn
	call (xhl)					; b3 e8
	call HDAE5000_YieldUntilSem1Zero		; 1d 2b b2 28
	lda xwa, (HDAE5000_Str_HDDIDREAD:24); f2 f0 21 2e 30
	calr HDAE5000_HardTest_Print			; 1e 6b fe
	calr HDAE5000_HardTest_HddIdRead			; 1e e2 02
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_HDD_SW				; 40 4d 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	ld xde, 0:i3					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e ac 01
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x0000000b				; 40 0b 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 80 01
	; XDE == 0x0B: register event 0x4C, read/check disk status
.Leh_xde_0b:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_FD_SW				; 40 4c 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 1:i3					; ea a9
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_UpdateScreen)             ; e3 e1 84 00 23
	call (xhl)					; b3 e8
	call HDAE5000_YieldUntilSem1Zero		; 1d 2b b2 28
	lda xwa, (HDAE5000_Str_FDTEST:24); f2 fc 21 2e 30
	calr HDAE5000_HardTest_Print			; 1e bf fd
	; Check disk status via 0x0e88 table
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_HamaFnTable)             ; e3 e1 88 0e 20 — (xwa+0x0e88)
	ld xix, (xwa + HamaFn_GetMediaType)				; a8 08 24
	call (xix)					; b4 e8
	cp l, 3:i3					; cf db
	jr z, .Leh_status_2or3			; 66 04
	cp l, 2:i3					; cf da
	jr nz, .Leh_status_other			; 6e 27
.Leh_status_2or3:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_HamaFnTable)             ; e3 e1 88 0e 20
	ld xix, (xwa + HamaFn_FDLoadSaveTest)				; a8 04 24
	call (xix)					; b4 e8
	cp hl, 0:i3					; db d8
	jr nz, .Leh_status_nonzero			; 6e 0a
	lda xwa, (HDAE5000_Str_OK:24); f2 04 22 2e 30
	calr HDAE5000_HardTest_Print			; 1e 8d fd
	jr t, .Leh_after_status			; 68 12
.Leh_status_nonzero:
	lda xwa, (HDAE5000_Str_ERROR:24); f2 08 22 2e 30
	calr HDAE5000_HardTest_Print			; 1e 83 fd
	jr t, .Leh_after_status			; 68 08
.Leh_status_other:
	lda xwa, (HDAE5000_Str_ERROR_HardTestPage:24); f2 0e 22 2e 30
	calr HDAE5000_HardTest_Print			; 1e 79 fd
.Leh_after_status:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_FD_SW				; 40 4c 00 7f 00
	ld xbc, 0x01c0000f				; 41 0f 00 c0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	ld xde, 0:i3					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jrl nz, .Leh_epilogue				; 7e bd 00
	ld xwa, 0x01c00007				; 40 07 00 c0 01
	push xwa					; 38
	ld xwa, 0x00000009				; 40 09 00 00 00
	push xwa					; 38
	ld xbc, xiz					; ee 89
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_SetApTimer)             ; e3 e1 10 04 23
	ld xwa, 0x00000029				; 40 29 00 00 00
	ld xde, 0xffffffff				; 42 ff ff ff ff
	call (xhl)					; b3 e8
	jrl t, .Leh_epilogue				; 78 91 00
	; XDE == 0x0C: check device, show status messages
.Leh_xde_0c:
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xix, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 24
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0006b				; 41 6b 00 e0 01
	ld xde, 0:i3					; ea a8
	call (xix)					; b4 e8
	cp xhl, 0x00000001				; eb cf 01 00 00 00
	jr nz, .Leh_xde_0c_no_device			; 6e 27
	; Device present: show "connected" message
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0003b				; 41 3b 00 e0 01
	ld xde, 0:i3					; ea a8
	call (xhl)					; b3 e8
	lda xwa, (HDAE5000_Str_STOPTESTLOOP:24); f2 14 22 2e 30
	calr HDAE5000_HardTest_Print			; 1e c0 fc
	jr t, .Leh_epilogue				; 68 45
.Leh_xde_0c_no_device:
	; Device not present: show "not connected" message
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld_sril xhl, (xwa + RootFn_SendEvent)             ; e3 e1 00 01 23
	ld xwa, HDAE5000_OBJ_RUN_STOP				; 40 49 00 7f 00
	ld xbc, 0x01e0003b				; 41 3b 00 e0 01
	ld xde, 1:i3					; ea a9
	call (xhl)					; b3 e8
	lda xwa, (HDAE5000_Str_STARTTESTLOOP:24); f2 24 22 2e 30
	calr HDAE5000_HardTest_Print			; 1e 99 fc
	; Final cleanup: call deregister via vtable
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 20
	ld xwa, (xwa + WS_RootFnTable)             ; e3 e1 0a 0e 20
	ld xhl, (xwa + RootFn_PostEvent)             ; e3 e1 04 01 23 — (xwa+0x0104) deregister
	ld xwa, 0xffffffff				; 40 ff ff ff ff
	ld xbc, 0x01c00007				; 41 07 00 c0 01
	ld xde, 0x00000009				; 42 09 00 00 00
	call (xhl)					; b3 e8
	; Epilogue: restore regs, call cleanup callback, return
.Leh_epilogue:
	ld xwa, xiz					; ee 88
	ld xbc, (xsp + 0x08)				; af 08 21
	ld xde, (xsp + 0x04)				; af 04 22
	ld xhl, (HDAE5000_RAM_MainWorkspacePtr:24); e2 a2 a1 23 23
	ld xhl, (xhl + WS_RootFnTable)             ; e3 ed 0a 0e 23 — xhl = (xhl+0x0e0a)
	ld_sril xix, (xhl + RootFn_InheritedProc)             ; e3 ed dc 00 24 — xix = (xhl+0x00dc)
	call (xix)					; b4 e8
.Leh_return:
	pop xiz					; 5e
	inc 0, xsp					; ef 60 — deallocate stack frame
	ret						; 0e

; --- PPI/IDE Low-Level I/O ---
HDAE5000_PPI_Init:	; 0x282B98 (13 bytes)
	; Initialize 8255 PPI: control=0x90 (mode set), port A=0xFF (all bits high)
	ld (0x160006:24), 0x90; ld (0x160006), 0x90 - PPI control: mode 0, all output
	ld (0x160000:24), 0xff; ld (0x160000), 0xFF - Port A: set all bits
	ret

HDAE5000_PPI_LoopbackByte:	; 0x282BA5 (130 bytes)
	; Send byte A to the PPI (0x160002/0x160004, two nibbles, handshake on
	; 0x160000 bit 4) and read it back from port A -- the loopback of the
	; hardware test's "PPORT TEST".  (Not the IDE bus: the drive sits on the
	; ATA registers at 0x130010.., HDAE5000_ATA_*.)
	; Input: A = byte to transfer. Returns: L = 0x00 on match, 0xFF on mismatch
	; --- Low nibble phase ---
	ld l, a				; save original byte
	and a, 0x0f			; mask low nibble
	set 4, a			; set bit 4 (data strobe)
	sll a, 3			; shift left 3
	ld (0x160002:24), a; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	ld (0x160004:24), c; ld (0x160004), C — PPI port C
	res 7, a			; clear bit 7 (handshake low)
	srl a, 6			; shift right 6
	ld (0x160004:24), a; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_high:
	bit 4, (1441792:24); bit 4, (0x160000) — check ACK
	jr z, .Lppi_wait_high		; wait until bit 4 set
	ld a, (0x160000:24); ld A, (0x160000) — read port A
	and a, 0x0f			; mask low nibble
	ld e, a				; save low nibble in E
	; --- High nibble phase ---
	ld a, l				; restore original byte
	srl a, 1			; shift right 1
	res 7, a			; clear bit 7
	ld (0x160002:24), a; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	ld (0x160004:24), c; ld (0x160004), C — PPI port C
	set 7, a			; set bit 7 (handshake high)
	srl a, 6			; shift right 6
	ld (0x160004:24), a; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_low:
	bit 4, (1441792:24); bit 4, (0x160000) — check ACK
	jr nz, .Lppi_wait_low		; wait until bit 4 clear
	; --- Reassemble and verify ---
	ld c, e				; C = low nibble
	ld a, (0x160000:24); ld A, (0x160000) — read port A
	and a, 0x0f			; mask low nibble (high nibble of result)
	sll a, 4			; shift left 4 to high position
	or a, c				; combine with low nibble
	cp a, l				; compare with original byte
	jr nz, .Lppi_fail		; if mismatch, fail
	ld l, 0x00:opc			; success: L = 0
	ret
.Lppi_fail:
	ld l, 0xFF:opc			; failure: L = 0xFF
	ret

HDAE5000_HardTest_PortTest:	; 0x282C27 (71 bytes)
	; "PPORT TEST" of the hardware-test page: loop all 256 byte values through
	; HDAE5000_PPI_LoopbackByte, OR the failures together and print
	; "=======> Port Test OK" / "... Error" (0x2E224A / 0x2E2234) with
	; HDAE5000_HardTest_Print.  (Was "read an IDE register value via PPI".)
	dec 2, xsp
	pushw iz
	ldw (xsp + 2), 0x0000		; result = 0
	calr HDAE5000_PPI_Init
	ld iz, 0:i3			; IZ = 0 (loop counter)
	cp iz, 0x0100
	jr ge, .Lppi_rd_loop_end
.Lppi_rd_loop:
	stb_erp a, 0xf8		; ld a, izl (extended register)
	extz wa
	calr HDAE5000_PPI_LoopbackByte
	ld a, l				; result byte from transfer
	exts wa				; sign-extend to 16-bit
	or (xsp + 2), wa		; OR into result word
	inc 1, iz
	cp iz, 0x0100
	jr lt, .Lppi_rd_loop
.Lppi_rd_loop_end:
	cpw (xsp + 2), 0x0000	; test if result is zero
	jr nz, .Lppi_rd_nonzero
	lda xwa, (HDAE5000_Str_PortTestOK:24); 0x2E2234 - error event string
	calr HDAE5000_HardTest_Print
	jr t, .Lppi_rd_done
.Lppi_rd_nonzero:
	lda xwa, (HDAE5000_Str_PortTestError:24); 0x2E224A - success event string
	calr HDAE5000_HardTest_Print
.Lppi_rd_done:
	popw iz
	inc 2, xsp
	ret

HDAE5000_HardTest_HddIdRead:	; 0x282C6E (192 bytes)
	; "HDD ID READ" of the hardware-test page: HDAE5000_HD_LoadTables,
	; HDAE5000_HD_GetGeometry, then prints "HD-TYPE : <model>", "Fre Capa:
	; %3.1f [MB]" (free space / 100.0 as a float) and "=======> HDD OK" or
	; "... HDD NG!".  (Was "write a sector of data to HD via PPI".)
	; Large 124-byte stack frame for sector buffer and parameter blocks
	lda xsp, (xsp - 124)		; allocate stack frame
	ld wa, 0:i3
	call HDAE5000_HD_LoadTables
	cp hl, 0:i3
	jrl nz, .Lpws_error
	lda xwa, (xsp + 72)
	call HDAE5000_HD_GetGeometry
	; MemFill: clear 32-byte buffer
	pushw 0x0020			; count = 32
	pushw 0x0000			; fill value = 0
	lda xwa, (xsp + 28)
	push xwa			; buffer address
	call HDAE5000_MemFill
	; MemCopy_Block: copy 46 bytes from 0x2264 offset
	pushw 0x002E			; count = 46 -- high half of HDAE5000_Str_HDTYPE
	pushw 0x2264			; source offset		; low half of HDAE5000_Str_HDTYPE
	lda xwa, (xsp + 36)
	push xwa			; dest address
	call HDAE5000_StrCpy
	; MemCopy: copy 10 bytes between buffers
	pushw 0x000A			; count = 10
	lda xwa, (xsp + 100)
	push xwa			; source
	lda xwa, (xsp + 56)
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 26)		; pop all args (26 bytes)
	; Transfer byte to PPI
	lda xwa, (xsp + 24)
	calr HDAE5000_HardTest_Print
	; Write sector data
	lda xwa, (xsp + 56)
	call HDAE5000_HD_GetDiskUsage
	; MemFill: clear buffer again
	pushw 0x0020			; count = 32
	pushw 0x0000			; fill value = 0
	lda xwa, (xsp + 28)
	push xwa			; buffer address
	call HDAE5000_MemFill
	; Compare and copy operations
	lda xbc, (xsp + 76)
	lda xwa, (xsp + 20)
	call HDAE5000_ULongToFloat
	lda xbc, (xsp + 20)
	lda xde, (HDAE5000_Float_100_HddIdRead:24); 0x2E22AA
	lda xwa, (xsp + 20)
	call HDAE5000_FloatDiv
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 24)
	call HDAE5000_FloatToDouble
	; Copy block via PPI
	lda xiy, (xsp + 24)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy + 0)
	push xix
	pushw 0x002E			; count = 46 -- high half of HDAE5000_Fmt_Fre_Capa_3_1f_MB
	pushw 0x2270			; offset		; low half of HDAE5000_Fmt_Fre_Capa_3_1f_MB
	lda xwa, (xsp + 44)
	push xwa
	call HDAE5000_SPrintf
	lda xsp, (xsp + 24)		; pop args
	; Transfer results
	lda xwa, (xsp + 24)
	calr HDAE5000_HardTest_Print
	lda xwa, (HDAE5000_Str_Empty:24); 0x2E2286
	calr HDAE5000_HardTest_Print
	lda xwa, (HDAE5000_Str_HDDOK:24); 0x2E2288
	calr HDAE5000_HardTest_Print
	jr t, .Lpws_done
.Lpws_error:
	lda xwa, (HDAE5000_Str_HDDNG:24); 0x2E2298
	calr HDAE5000_HardTest_Print
.Lpws_done:
	lda xsp, (xsp + 124)		; deallocate stack frame
	ret

HDAE5000_FdList_Clear:	; 0x282D2E (270 bytes)
	; Blank the floppy-list screen: copy the empty title/row templates
	; (0x2E1CE6, and the "01:" .. "20:" rows at 0x2E1CF4) to 0x22AA9C /
	; 0x22AAAA and show them in objects 0x7F00DE / 0x7F00D7 (event
	; 0x01EA000A, then 0x01C0000F), hide 0x7F00D9/0x7F00D8, clear the flag
	; arrays 0x22AB9C and 0x22ABB0.  (Was "read a sector of data from HD via
	; PPI ... registers PPI device handlers": no PPI access here.)
	; Copy 14 bytes: source table → PPI buffer
	pushw 0x000E			; count = 14
	lda xwa, (HDAE5000_Str_Blank12Tab:24); 0x2E1CE6
	push xwa			; source
	lda xwa, (0x22aa9c:24); 0x22AA9C
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: first handler pair (0xDE)
	lda xwa, (0x22aa9c:24); 0x22AA9C - buffer ptr
	ld xde, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24); workspace ptr (0x23A1A2)
	ld xwa, (xwa + WS_RootFnTable)             ; (XWA + 0x0E0A)
	ld xhl, (xwa + RootFn_ApPostEvent)             ; (XWA + 0x0124)
	ld xwa, HDAE5000_OBJ_CP_FD_VOLLABEL
	ld xbc, 0x01EA000A
	call (xhl)
	; Register second handler (0xDE, different params)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_CP_FD_VOLLABEL
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Copy 241 bytes: second table → PPI buffer
	pushw 0x00F1			; count = 241
	lda xwa, (HDAE5000_FdList_RowsTemplate:24); 0x2E1CF4
	push xwa			; source
	lda xwa, (0x22aaaa:24); 0x22AAAA
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: second handler pair (0xD7)
	lda xwa, (0x22aaaa:24); 0x22AAAA
	ld xde, xwa
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_CP_FD_LIST
	ld xbc, 0x01EA000A
	call (xhl)
	; Second handler (0xD7, different params)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_CP_FD_LIST
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Register third handler (0xD9)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_CP_FD_LINE1
	ld xbc, 0x01C0000D
	ld xde, 0:i3
	call (xhl)
	; Register fourth handler (0xD8)
	ld xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
	ld xwa, (xwa + WS_RootFnTable)
	ld xhl, (xwa + RootFn_ApPostEvent)
	ld xwa, HDAE5000_OBJ_CP_FD_LINE2
	ld xbc, 0x01C0000D
	ld xde, 0:i3
	call (xhl)
	; Clear two 20-byte buffers
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	lda xwa, (0x22ab9c:24); 0x22AB9C
	push xwa
	call HDAE5000_MemFill
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	lda xwa, (0x22abb0:24); 0x22ABB0
	push xwa
	call HDAE5000_MemFill
	lda xsp, (xsp + 16)		; pop all args (16 bytes)
	ret

HDAE5000_FdName_SongNumber:	; 0x282E3C (81 bytes)
	; XWA = a floppy file name: HL = n-1 when it starts with the 2-digit
	; number n = 1..20 (SPrintf "%2.2d", StrNCmp over its length), else
	; 0xFFFF.  (Was "transfer a block of data via PPI".)
	; Iterates entries 1..20, copies block via PPI_Block_Copy, validates buffer,
	; then compares with MemCompare_Block. Returns matching index-1 or 0xFFFF.
	dec 0, xsp			; allocate 8 bytes on stack
	pushw iz
	ld (xsp + 6), xwa		; save input parameter
	ld iz, 1:i3			; IZ = 1 (entry counter)
	cp iz, 0x0014
	jr gt, .Lptb_not_found
.Lptb_loop:
	pushw iz
	pushw 0x002E			; block size = 46 -- high half of HDAE5000_Fmt_2_2d
	pushw 0x22AE			; source base address		; low half of HDAE5000_Fmt_2_2d
	lda xwa, (xsp + 8)		; pointer to local buffer
	push xwa
	call HDAE5000_SPrintf
	lda xwa, (xsp + 0x0C)		; pointer to compare buffer
	push xwa
	call HDAE5000_StrLen
	pushw hl			; save validation result
	ld xwa, (xsp + 0x16)		; reload input parameter
	push xwa
	lda xwa, (xsp + 0x16)		; pointer to local buffer
	push xwa
	call HDAE5000_StrNCmp
	add xsp, 0x00000018		; clean up stack (24 bytes)
	cp hl, 0:i3			; check compare result
	jr nz, .Lptb_found
	ld hl, iz			; return index - 1
	dec 1, hl
	jr t, .Lptb_done
.Lptb_found:
	inc 1, iz
	cp iz, 0x0014
	jr le, .Lptb_loop
.Lptb_not_found:
	ldw hl, 0xFFFF			; return -1 (not found)
.Lptb_done:
	popw iz
	inc 0, xsp			; deallocate 8 bytes
	ret

; --- HD Drive Setup and Configuration ---

; --- HD (IDE/ATA) Driver ---
	.include "hdae5000_hd_driver.s"

; --- FAT16 Filesystem ---
	.include "hdae5000_filesystem.s"

; --- Menu UI & Display ---
	.include "hdae5000_ui_display.s"

; --- Utility & Math Functions ---
	.include "hdae5000_utilities.s"

; --- Data Tables, Config, Graphics & Strings ---
	.include "hdae5000_data_tables.s"

