; =============================================================================
; Work-RAM image 2, tail: ROM 0xEEFF4E-0xEF02EE -> RAM 0xE7AA-0xEB4A
; =============================================================================
; Not read in ROM.  Boot_InitWorkRAM_ROMCopy2_Start (0xEF0BA8) copies ROM
; 0xEEFA66-0xEF0396 (0x931 bytes) to RAM 0xE2C2 at boot, so each byte here is the
; power-on value of a RAM byte and the code uses the RAM addresses (given
; per row below).  The image starts in ui_widgets/sequencer_channel_containers.s
; and ends with SndParam_ValueMapGrid (ui/charmap_dispatch_table.s).
; Formerly titled "Character Encoding Tables & NAKA State Blocks": the text-like
; bytes and most instructions decoded here were node links, the rest small
; variables; the zero blocks are song-player variables.  The old labels stay
; as `.set` aliases at the end.
; Pinned by scripts/generators/gen_workram2_tail.py --probe (v10, v9, v7).
; v7 holds the same 929 bytes; its RAM addresses are v10's minus 0xC6.  Routine
; names are v10's (the v7 counterparts use the v7 RAM addresses).
; Extracted from kn5000_v10_program.s
; =============================================================================
; Nodes 0x21-0x7F of link array A: {u8 prev, u8 next} per node, node k at
; RAM 0xE768 + 2k (nodes 0-0x20 are the last bytes of the previous file).
; Power-on state: nodes 0-0x7F chained on the free list, prev = k-1, next = k+1.
; NoteMap_AllocNewVoiceEntry and others take the base (`lda xwa,(0xE768)`,
; `lda xde,(0xE768)`) and pass it with a node index to NoteMap_SwapVoiceLinks
; and NoteMap_LinkVoiceSlots.
WorkRam2_VoiceLinkA_Nodes21:
	.byte 0x20, 0x22, 0x21, 0x23, 0x22, 0x24, 0x23, 0x25, 0x24, 0x26, 0x25, 0x27, 0x26, 0x28, 0x27, 0x29	; RAM 0xE7AA
	.byte 0x28, 0x2a, 0x29, 0x2b, 0x2a, 0x2c, 0x2b, 0x2d, 0x2c, 0x2e, 0x2d, 0x2f, 0x2e, 0x30, 0x2f, 0x31	; RAM 0xE7BA
	.byte 0x30, 0x32, 0x31, 0x33, 0x32, 0x34, 0x33, 0x35, 0x34, 0x36, 0x35, 0x37, 0x36, 0x38, 0x37, 0x39	; RAM 0xE7CA
	.byte 0x38, 0x3a, 0x39, 0x3b, 0x3a, 0x3c, 0x3b, 0x3d, 0x3c, 0x3e, 0x3d, 0x3f, 0x3e, 0x40, 0x3f, 0x41	; RAM 0xE7DA
	.byte 0x40, 0x42, 0x41, 0x43, 0x42, 0x44, 0x43, 0x45, 0x44, 0x46, 0x45, 0x47, 0x46, 0x48, 0x47, 0x49	; RAM 0xE7EA
	.byte 0x48, 0x4a, 0x49, 0x4b, 0x4a, 0x4c, 0x4b, 0x4d, 0x4c, 0x4e, 0x4d, 0x4f, 0x4e, 0x50, 0x4f, 0x51	; RAM 0xE7FA
	.byte 0x50, 0x52, 0x51, 0x53, 0x52, 0x54, 0x53, 0x55, 0x54, 0x56, 0x55, 0x57, 0x56, 0x58, 0x57, 0x59	; RAM 0xE80A
	.byte 0x58, 0x5a, 0x59, 0x5b, 0x5a, 0x5c, 0x5b, 0x5d, 0x5c, 0x5e, 0x5d, 0x5f, 0x5e, 0x60, 0x5f, 0x61	; RAM 0xE81A
	.byte 0x60, 0x62, 0x61, 0x63, 0x62, 0x64, 0x63, 0x65, 0x64, 0x66, 0x65, 0x67, 0x66, 0x68, 0x67, 0x69	; RAM 0xE82A
	.byte 0x68, 0x6a, 0x69, 0x6b, 0x6a, 0x6c, 0x6b, 0x6d, 0x6c, 0x6e, 0x6d, 0x6f, 0x6e, 0x70, 0x6f, 0x71	; RAM 0xE83A
	.byte	0x70, 0x72, 0x71, 0x73, 0x72, 0x74, 0x73	; RAM 0xE84A
NakaData_NormalModeMap:	.byte	0x75, 0x74, 0x76, 0x75, 0x77, 0x76, 0x78, 0x77, 0x79
	.byte	0x78, 0x7a	; RAM 0xE85A
	.byte	0x79, 0x7b, 0x7a, 0x7c
	.byte	0x7b, 0x7d, 0x7c
	.byte	0x7e, 0x7d, 0x7f
	.byte	0x7e, 0x80
; Node 0x80 of array A: free-list sentinel {prev = tail 0x7F, next = head 0}.
; AllocNewVoiceEntry_LoadParam: `ld a,(0xE869); ... cp a,0x80` -- the
; list is empty when the head is the sentinel itself.
WorkRam2_VoiceLinkA_FreeList:
	.byte 0x7f, 0x00	; RAM 0xE868
; Nodes 0x81-0xA0 of array A: 32 list sentinels, each {self, self} = an empty
; circular list at power-on (node 0x81 = bytes 0x81,0x81 ... 0xA0 = 0xA0,0xA0).
WorkRam2_VoiceLinkA_ListHeads:
	.byte 0x81, 0x81, 0x82, 0x82, 0x83, 0x83, 0x84, 0x84, 0x85, 0x85, 0x86, 0x86, 0x87, 0x87, 0x88, 0x88	; RAM 0xE86A
	.byte 0x89, 0x89, 0x8a, 0x8a, 0x8b, 0x8b, 0x8c, 0x8c, 0x8d, 0x8d, 0x8e, 0x8e, 0x8f, 0x8f, 0x90, 0x90	; RAM 0xE87A
	.byte 0x91, 0x91, 0x92, 0x92, 0x93, 0x93, 0x94, 0x94, 0x95, 0x95, 0x96, 0x96, 0x97, 0x97, 0x98, 0x98	; RAM 0xE88A
	.byte 0x99, 0x99, 0x9a, 0x9a, 0x9b, 0x9b, 0x9c, 0x9c, 0x9d, 0x9d, 0x9e, 0x9e, 0x9f, 0x9f, 0xa0, 0xa0	; RAM 0xE89A
; Link array B {u8 prev, u8 next}, node k at RAM 0xE8AA + 2k; nodes 0-0x1F
; chained on the free list at power-on.  NoteMap_FindEntry takes the base
; (`lda xwa,(0xE8AA)`); NoteMap_FindEntry_AdvanceSlotD follows next links
; (`lda xix,(0xE8AB); ld d,(xix+bc)` with bc = 2 * node).
WorkRam2_VoiceLinkB_Nodes:
	.byte 0x20, 0x01, 0x00, 0x02, 0x01, 0x03, 0x02, 0x04, 0x03, 0x05, 0x04, 0x06, 0x05, 0x07, 0x06, 0x08	; RAM 0xE8AA
	.byte	0x07, 0x09, 0x08, 0x0a, 0x09, 0x0b, 0x0a, 0x0c, 0x0b, 0x0d, 0x0c	; RAM 0xE8BA
FDTest_Label_Tilde80_Data0:	.byte	0x0e, 0x0d, 0x0f, 0x0e, 0x10
	.byte 0x0f, 0x11, 0x10, 0x12, 0x11, 0x13, 0x12, 0x14, 0x13, 0x15, 0x14, 0x16, 0x15, 0x17, 0x16, 0x18	; RAM 0xE8CA
	.byte 0x17, 0x19, 0x18, 0x1a, 0x19, 0x1b, 0x1a, 0x1c, 0x1b, 0x1d, 0x1c, 0x1e, 0x1d, 0x1f, 0x1e, 0x20	; RAM 0xE8DA
; Node 0x20 of array B: free-list sentinel {tail 0x1F, head 0}.
; FindEntry_LoadParam: `ld a,(0xE8EB); ... cp a,0x20` (empty = sentinel).
WorkRam2_VoiceLinkB_FreeList:
	.byte 0x1f, 0x00	; RAM 0xE8EA
; Nodes 0x21-0x24 of array B: 4 list sentinels {self, self}, empty at power-on;
; NoteMap_FindEntry_AdvanceSlotD stops a walk at `cp c,0x21`.
WorkRam2_VoiceLinkB_ListHeads:
	.byte 0x21, 0x21, 0x22, 0x22, 0x23, 0x23, 0x24, 0x24	; RAM 0xE8EC
; u16, 0 at power-on: VoiceLinks_SlotLoop `incw 1,(0xE8F4)`,
; VoiceLinks_SkipEmpty `decw 1,(0xE8F4)`.
WorkRam2_VoiceLinks_Count:
	.byte 0x00, 0x00	; RAM 0xE8F4
; {u8 count, 0xFF}; count 10 at power-on.  VoiceMap_AllocateSlo_Block2 sets it
; to 10, NoteMap_FindBestMatch to 0; SeqEvt_CheckExpiry decrements it and calls
; NoteMap_FindBestMatch when it reaches 0 (`ld a,(0xE8F6); ... dec 1,a`).
WorkRam2_VoiceMatchCountdown:
	.byte 0x0a, 0xff	; RAM 0xE8F6
; {u8 index, 0xFF}; 20 at power-on.  UIStateEvt_EffectSelect_Data_Skip4 stores
; (RAM 0xC07E) & 15 here; UIParam_CallbackDispatch reads it as the index of a
; u32 entry (`ld c,(0xE8F8); sla bc,2`) and calls through that entry.
WorkRam2_CallbackIndex:
	.byte 0x14, 0xff	; RAM 0xE8F8
; {u8 value, 0xFF}; 0 at power-on.  UIStateEvt_EffectSelect_Data_Skip3 stores
; RAM 0xC07E here; AudioInit_Pan_CheckReverbChannel compares it with 14 and
; AudioInit_Pan_Reverb_CopyFromMain copies it to RAM 0xC2BC.
WorkRam2_EffectSelectByte:
	.byte 0x00, 0xff	; RAM 0xE8FA
; {u8 value, 0xFF}; 0 at power-on.  SendEpilogue_Data_Skip2 stores it,
; SendEpilogue_Data_Skip compares a register with it (`cp ...,(0xE8FC)`).
WorkRam2_SendEpilogueByte:
	.byte 0x00, 0xff	; RAM 0xE8FC
; Variables of the SeqFile_/SeqPlay_/SongFile_ routines (the song-file player),
; zero at power-on except RAM 0xEB47 = 0xFF, which no instruction names.
; Offsets from here, with the routines that use them (audio/note_voice_mapping.s):
;  +0x00 u8 state; the block from +0 is also passed by address
;        (OutputFlush_Prologue, SeqFile_ParseHeader, LoadAndStartPlayback_LoadParam3
;        `lda xwa,(0xE8FE)`, StoreAndReturn_Block clears it)
;  +0x20 u8 mode 0-4 (OutputFlush_InitVal `cp ...,4`, RecordReadOK_LoadReg sets 2)
;  +0x21 u16 flag bits 0x01/0x02/0x04/0x10 (SeqState_GetFlags, Acc_TransitionPlayMode,
;        Acc_StopPlayMode, Acc_StartFillIn, DecodeMidiEvent_LoadParam3)
;  +0x23 u32 running total (SeqFile_AccumulateLength, ConfigureBanks_Block,
;        ToneGen_AccumulateDelta `add (0xE921),...`)
;  +0x27 u32 (ConfigureBanks_LoadReg4, RecordReadOK_Block, MidiSysMsg_SetScaledTempo)
;  +0x2B u16 set to 384 or 480 (RecordReadOK_Block7, ToneGen_ReadFileRecord) or read
;        from the file (SeqFile_ReadDivisionByte1); [INFERENCE] the SMF time
;        division (384 and 480 are usual ticks-per-quarter values)
;  +0x2D u16 (SeqFile_StoreTempoByte1, SeqFile_ReadTempoByte2)
;  +0x2F u16 (FileIO_ReadChunk, SendSinglePacket_LoadReg)
;  +0x31 u32 (SeqPlay_ReadRecord_Entry, SeqPlay_AccumulateDelta)
;  +0x35, +0x37 buffers passed by address (DecodeMidiEvent_Block2,
;        SeqPlay_CheckSysExMarker, SeqPlay_CopyToMidiBuffer)
;  +0x135 u16 count and +0x137 buffer (DecodeMidiEvent_Block2, SeqPlay_CopyToMidiBuffer,
;        SongFile_DecodeMidiEvent, SeqPlay_CheckMidiBuffer)
;  +0x237 u16 count (SongFile_DecodeMidiEvent, SeqPlay_ClearMidiCount)
;  +0x239 u32, +0x23D u16, +0x23F/+0x240/+0x241 u8 (Epilogue_Block,
;        ToneGen_ProcessMidiConverge, ToneGen_ValidateRange_Loop `cp ...,7`,
;        ProcessMidiConverge_LoadDRAM clamps +0x241 to 127)
;  +0x24A u16 countdown from 6 (PlayModeStateMachine_Prologue)
;  +0x24C u8 (SeqPlay_CheckStatusByte)
WorkRam2_SongPlayerState:
	.zero 585	; RAM 0xE8FE
	.byte 0xff	; RAM 0xEB47
	.zero 3	; RAM 0xEB48
; Legacy labels, kept because other files name them (NAKA C records, factory_test/
; fd_test_data.s, audio/sound_editor_ui.s, audio/presentation_sound_nav.s,
; extensions/extension_data.s, shared/positional_labels.s):
	.set CharEncoding_PrintableHi, WorkRam2_VoiceLinkA_Nodes21 + 136
	.set CharEncoding_ExtendedLo, WorkRam2_VoiceLinkA_ListHeads + 14
	.set CharEncoding_ExtendedHi, WorkRam2_VoiceLinkA_ListHeads + 49
	.set NakaState_ZeroBlock_0, WorkRam2_SongPlayerState + 16
	.set NakaState_ZeroBlock_1, WorkRam2_SongPlayerState + 39
	.set NakaState_ZeroBlock_2, WorkRam2_SongPlayerState + 41
	.set NakaState_ZeroBlock_3, WorkRam2_SongPlayerState + 75
	.set NakaInst_BASS_ACCOMP1_ACCOMP2_ACCOMP3, WorkRam2_SongPlayerState + 95
	.set NakaInst_RHYTHM_SELECT_TEMPO_APC_MEMORY_SPLIT_POINT, WorkRam2_SongPlayerState + 100
	.set NakaState_ZeroBlock_4, WorkRam2_SongPlayerState + 111
	.set NakaState_ZeroBlock_5, WorkRam2_SongPlayerState + 113
	.set Naka_PresentationRootState, WorkRam2_SongPlayerState + 115
	.set NakaState_PresentationTail, WorkRam2_SongPlayerState + 486
