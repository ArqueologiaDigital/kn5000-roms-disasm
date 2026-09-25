#!/usr/bin/env python3
# edit_subcpu_boot_symbolic_refs_2026_09_25.py -- the one-shot edit behind the 2026-09-25 boot-ROM commit
# (labels for the channel-init cells, 13 numeric ROM operands made symbolic, SUB_FEC1 renamed).
# Kept for the record; it asserts the pre-edit text, so it refuses to run twice.  RUN: python3 <this>, then make gate.
import re
p='subcpu/boot/kn5000_subcpu_boot.s'
S='★'.encode('utf-8').decode('latin-1')
t=open(p,'rb').read().decode('latin-1')
def rep(o,n,c=1):
    global t
    assert t.count(o)==c,(t.count(o),o[:70]); t=t.replace(o,n)
t=re.sub(r'\bSUB_FEC1\b','DEBUG_OUTPUT_CHAR_STUB',t)
rep("lda xde, (0xfffef0:24)","lda xde, (ToneGen_ChannelInit_Config:24)")
rep("cpw (16776942:24), 65535","cpw (ToneGen_ChannelInit_Flag:24), 65535")
rep("ld xhl, 0xFF8F6C","ld xhl, VECTOR_TRAMPOLINES")
rep("lda xbc, (0xff8000:24)","lda xbc, (CmdHandler_Table:24)")
rep("lda xbc, (0xff8020:24)","lda xbc, (MemTest_RegionTable:24)")
rep("lda xde, (0xff804c:24)","lda xde, (ToneGen_Velocity_Input_Curve:24)")
rep("ld bc, (0xff802a:24)","ld bc, (ToneGen_VelCurve_Pivot:24)")
rep("lda xde, (0xff8040:24)","lda xde, (ToneGen_VelCurve_ModeParams_Mode6:24)")
rep("ld hl, (0xff802c:24)","ld hl, (ToneGen_VelCurve_Divisor:24)")
rep("lda xde, (0xff814c:24)","lda xde, (ToneGen_Velocity_Output_Curve:24)")
rep("ld xbc, 0xFF824C","ld xbc, ToneGen_ProbeVoice_ParamBlock")
rep("ld bc, (0xff824c:24)","ld bc, (ToneGen_ProbeVoice_ParamBlock:24)")
rep("\t.long 0xFFFEe0\t; Reset - points to ROM handler at 0xFFFEE0","\t.long RESET_HANDLER\t; Reset - points to ROM handler at 0xFFFEE0")
rep("""	.fill 9, 1, 0xff	; 0xFFFEE5-0xFFFEED
	.byte 0x00, 0x00	; 0xFFFEEE-0xFFFEEF
""","""	.fill 9, 1, 0xff	; 0xFFFEE5-0xFFFEED
; u16 channel-init flag: TONE_GEN_CHANNEL_INIT (0xFF8437) runs its 4-channel loop only when
; this word is 0xFFFF (`cpw (this:24),0xFFFF / jr nz`).  The dumped value is 0x0000, so the
; loop is skipped.  The v1.42 payload reads the same cell as a byte, BootROM_ChannelInitFlag
; (kn5000_subprogram_v142.s, DSP_Init_Channels_FromBootTable).
ToneGen_ChannelInit_Flag:
	.byte 0x00, 0x00	; 0xFFFEEE-0xFFFEEF
""")
rep("""; Reserved data area (0xFFFEF0 - 0xFFFEFF)
; Appears to be some kind of configuration or padding data
""","""; Reserved data area (0xFFFEF0 - 0xFFFEFF)
; Appears to be some kind of configuration or padding data
; %s 2026-09-25: it is TONE_GEN_CHANNEL_INIT's channel table -- 4 x u32, entry ch loaded
; `lda xde,(ToneGen_ChannelInit_Config:24) / ld_sril3 XBC,(XDE+BC)` with BC = 4*ch and passed to
; TONE_GEN_WRITE; the v1.42 payload addresses it as BootROM_ChannelConfigTable.  All four entries
; are 0x00000400 in the dump.
""" % S)
rep("""	.org 0xFFFEF0 - 0xFE0000, 0xFF

	.byte 0x00, 0x04, 0x00, 0x00	; 0xFFFEF0-0xFFFEF3""","""	.org 0xFFFEF0 - 0xFE0000, 0xFF

ToneGen_ChannelInit_Config:
	.byte 0x00, 0x04, 0x00, 0x00	; 0xFFFEF0-0xFFFEF3""")
rep("""DEBUG_OUTPUT_CHAR_STUB:
	ldw iz, 0xFE00	; Output port address (placeholder)""","""; The per-character sink DEBUG_OUTPUT_STRING calls.  In this ROM it outputs nothing: it loads
; IZ = 0xFE00 and burns twelve `nop`s before `ret` -- a stubbed-out debug port.  The v1.42 payload
; reaches it through BootROM_DEBUG_OUTPUT_STRING, so its Debug_Print_* calls are no-ops.
; %s Renamed 2026-09-25 from SUB_FEC1 (its address, 0xFFFEC1).
DEBUG_OUTPUT_CHAR_STUB:
	ldw iz, 0xFE00	; Output port address (placeholder)""" % S)
rep("""ToneGen_VelCurve_ModeParams_Mode6:	; 0xFF8040 -- the mode the boot ROM uses""","""; Row 6 is the only row the boot ROM reads: NOTE_VELOCITY_LOOKUP_CALCULATE loads it with
; `lda xde,(ToneGen_VelCurve_ModeParams_Mode6:24)` (gain +0, pivot output +1, black-key trim +2).
ToneGen_VelCurve_ModeParams_Mode6:	; 0xFF8040 -- the mode the boot ROM uses""")
rep("""; 0x00,0x10,...,0x90.  The payload's copy of this table is still unlabelled.
""","""; 0x00,0x10,...,0x90.  The payload's copy of this table is still unlabelled.
; %s 2026-09-25: no longer -- the payload labels its copy ToneGen_VelCurve_ModeParams too
; (v142/subcpu/subcpu_data_tables.s, 0x01F420).
""" % S)
open(p,'wb').write(t.encode('latin-1'))
p2='v142/subcpu/kn5000_subprogram_v142.s'
k=open(p2,'rb').read().decode('latin-1')
o2="""; subcpu/boot/kn5000_subcpu_boot.s they are the init flag and the 4 x u32 channel table that
; the boot ROM's own TONE_GEN_CHANNEL_INIT (0xFF8437) reads; both are dumped bytes there
; (flag = 00 00, table = 4 x 00 04 00 00)."""
assert k.count(o2)==1
k=k.replace(o2,o2+"""
; (Labelled there, since 2026-09-25, ToneGen_ChannelInit_Flag and ToneGen_ChannelInit_Config;
; the sink named SUB_FEC1 further down this file is DEBUG_OUTPUT_CHAR_STUB there now.)""")
open(p2,'wb').write(k.encode('latin-1'))
