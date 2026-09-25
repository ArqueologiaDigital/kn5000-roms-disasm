import sys, re, subprocess
img, p = sys.argv[1], sys.argv[2]
import os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ROM = open(ROOT + '/original_ROMs/kn5000_%s_program.rom' % img, 'rb').read()
B = 0xE00000
nm = subprocess.run([os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm'),
                     '--defined-only', ROOT + '/rebuilt_ROMs/kn5000_%s_program.llvm.elf' % img],
                    capture_output=True, text=True).stdout
SYM = {}
for ln in nm.split('\n'):
    x = ln.split()
    if len(x) == 3:
        SYM.setdefault(x[2], int(x[0], 16))
def A(n):
    return "0x%06X" % SYM[n]
s = open(p, encoding='latin-1').read()

def bytes_at(a, n):
    return ROM[a - B:a - B + n]

h = SYM['SMF_HeaderConstants']
blk = bytes_at(h, 0x66)
assert blk[4:8] == b'MThd' and blk[0x12:0x16] == b'MTrk'
words = [int.from_bytes(blk[0x1A + 2 * i:0x1C + 2 * i], 'little') for i in range(20)]
tbl = list(blk[0x52:0x66])
new = []
new.append('''; =============================================================================
; SMF_HeaderConstants -- constant pieces of the Standard MIDI File the
; sequencer writes (SMF export), 0x66 = 102 bytes, to SMF_ScanChannels.  Every
; piece is addressed through a positional alias (shared/positional_labels.s,
; `.set SMF_HeaderConstants_0xNN, SMF_HeaderConstants + NN`); readers are in
; sequencer/smf_event_processor.s.  Until 2026-09-25 the first 24 bytes were
; framed as instructions (`nop / swi 7 / pop sr / rcf / .asciz "MThd" ...`).
; =============================================================================
SMF_HeaderConstants:
	; +0x00: delta-time 0, meta event FF 03 (sequence/track name), length 16.
	; SMF_SetupActiveChannel (%s) copies these 4 bytes (`ld bc, 4; ldir85`)
	; and then the 16-byte name from RAM 0xF280 (`ldw bc, 0x10; ldir85`).
	.byte 0x00, 0xff, 0x03, 0x10
	; +0x04 (SMF_HeaderConstants_0x4): the MThd chunk -- "MThd", length 6,
	; format 0, 1 track, division 96 ticks per quarter note.  Copied whole to
	; RAM 0x13FA by SMF_SetupActiveChannel (`ld bc, 7; ldirw` = 7 words).
	.ascii "MThd"
	.byte 0x00, 0x00, 0x00, 0x06	; chunk length (big-endian)
	.byte 0x00, 0x00		; format 0
	.byte 0x00, 0x01		; one track
	.byte 0x00, 0x60		; 96 ticks per quarter note
	; +0x12 (SMF_HeaderConstants_0x12): "MTrk", copied after the MThd chunk
	; by SMF_SetupActiveChannel (`ld bc, 4; ldir85`).
	.ascii "MTrk"
	; +0x16: four zero bytes that nothing reads -- SMF_SetupActiveChannel
	; writes the track-length placeholder from RAM words 0x0FA2/0x0FA4
	; instead (scripts/analysis/sequi_find_refs.py %s %s -> none).
	.byte 0x00, 0x00, 0x00, 0x00''' % (A('SMF_SetupActiveChannel'), img, "0x%06X" % (h + 0x16)))
new.append('''	; +0x1A (SMF_HeaderConstants_0x1A): 20 x 16-bit offsets indexed by the
	; PART-TYPE CODE a MIDI channel carries in RAM 0xF1A0[channel] (x2).
	; Readers SMF_ScanAndProcessChannel (%s), SMF_WriteVol_PanAndPitch (%s),
	; SMF_WriteRPN_FineTune (%s), SMF_WriteRPN_CoarseTune (%s) and
	; SMF_WriteRPN_Transpose (%s): `ld xix, SMF_HeaderConstants_0x1A`,
	; `ldw_sri HL, ...` (hl := table[code]); 0xFFFF skips the channel;
	; otherwise the offset is added to RAM 0xF460 (`lda_dri XIY`) to reach
	; that part's record.  The offsets are 0x36 + 26*k (k = 0..15), so the
	; records sit 26 bytes apart.  20 entries, pinned by the next piece at +0x42.''' % (
    A('SMF_ScanAndProcessChannel'), A('SMF_WriteVol_PanAndPitch'), A('SMF_WriteRPN_FineTune'),
    A('SMF_WriteRPN_CoarseTune'), A('SMF_WriteRPN_Transpose')))
for i in range(0, 20, 5):
    new.append("\t.short " + ", ".join("0x%04x" % w for w in words[i:i + 5]) + "\t; codes %d-%d" % (i, i + 4))
new.append('''	; +0x42 (SMF_HeaderConstants_0x42): delta 0 + SysEx F0 05 7E 7F 09 01 F7,
	; "General MIDI System On".  +0x4A (SMF_HeaderConstants_0x4A): the same
	; with 09 02, "GM System Off".  SMF_Setup_WriteLoop (%s) writes 8 bytes
	; of the first when RAM byte 0x10E4 is non-zero, of the second when it
	; is zero.
	.byte 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09, 0x01, 0xf7
	.byte 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09, 0x02, 0xf7
	; +0x52 (SMF_HeaderConstants_0x52): 20 bytes, indexed by the same
	; part-type code.  SMF_ProgramChange_ProcessPatch (%s): L := 0xF1A0[ch],
	; `ld xix, SMF_HeaderConstants_0x52`, `ldb_sri L, ...` (L := table[L]),
	; stored at RAM 0x1A5C, the third byte of the 3-byte message built at
	; 0x1A5A before SndParam_InitBufferConverge.  0x7F exactly where the
	; offset table above holds 0xFFFF (codes 13-16).''' % (A('SMF_Setup_WriteLoop'),
                                                         A('SMF_ProgramChange_ProcessPatch')))
new.append("\t.byte " + ", ".join("0x%02x" % x for x in tbl[:10]) + "\t; codes 0-9")
new.append("\t.byte " + ", ".join("0x%02x" % x for x in tbl[10:]) + "\t; codes 10-19")
assert [w == 0xffff for w in words] == [t == 0x7f for t in tbl], "0xFFFF/0x7F alignment claim false"
# replace from label line to SMF_ScanChannels
i = s.index('\nSMF_HeaderConstants:\n') + 1
j = s.index('\nSMF_ScanChannels:\n') + 1
s = s[:i] + "\n".join(new) + "\n\n" + s[j:]

# SMF_PartAssignTable
pa = SYM['SMF_PartAssignTable']
pb = bytes_at(pa, 24)
old = s[s.index('\nSMF_PartAssignTable:\n') + 1:s.index('\nSMF_EncodeTimeDelta:\n') + 1]
new = '''; -----------------------------------------------------------------------------
; SMF_PartAssignTable -- maps a value 0..15 read from the SMF event stream to
; a PART-TYPE CODE of the kind RAM 0xF1A0[channel] holds (0xFF = none).
; Readers: SMF_Event_ProgramChange (%s) and SMF_Event_ControlChange (%s),
; identically: after checking the value is 0..0xF, `ld xde,
; SMF_PartAssignTable` / `ldb_sri A, 0x07, 0xe8, 0xec` (A := table[value]),
; then search 0xF1A0[0..15] for that code to find the channel (0x7F if none).
; Only entries 0-15 are reachable through that range check; entries 16-23
; (to SMF_EncodeTimeDelta, code) are read by nothing found
; (scripts/analysis/sequi_find_refs.py %s --window 24 %s).  The codes used
; (0..0x13) are the same 20 codes SMF_HeaderConstants' two tables index by.
; -----------------------------------------------------------------------------
SMF_PartAssignTable:
	.byte %s	; values 0-7
	.byte %s	; values 8-15
	.byte %s	; 16-23: past the 0..15 check
''' % (A('SMF_Event_ProgramChange'), A('SMF_Event_ControlChange'), img, A('SMF_PartAssignTable'),
       ", ".join("0x%02x" % x for x in pb[:8]), ", ".join("0x%02x" % x for x in pb[8:16]),
       ", ".join("0x%02x" % x for x in pb[16:]))
s = s.replace(old, new)

# SMF_SlotParam_RPNReturn
ra = SYM['SMF_SlotParam_RPNReturn']
rb = bytes_at(ra, 62)
assert rb[:31] == rb[31:]
old = s[s.index('\nSMF_SlotParam_RPNReturn:\n') + 1:s.index('\nSMF_SlotParam_NRPN:\n') + 1]
new = '''; -----------------------------------------------------------------------------
; SMF_SlotParam_RPNReturn -- two identical 31-byte halves, remapping the byte
; at (XIY+3) of a slot record.
; Reader: SMF_SlotParam_BankLSBReturn (%s), for a record whose (XIY+2) is
; 0x39: with HL := 0 and L := (XIY+3), `ld_sri`-style load A := (XIX+HL);
;   bit 5 of (XIY+3) clear: XIX = SMF_SlotParam_RPNReturn,       (XIY+2) := 0xAD
;   bit 5 of (XIY+3) set:   XIX = SMF_SlotParam_RPNReturn_0x1F,  (XIY+2) := 0xAE
; and A is written back to (XIY+3).  62 bytes to SMF_SlotParam_NRPN (code).
; NOT RESOLVED: the second lookup uses the unmasked index, which has bit 5
; set, so it addresses +0x3F or beyond -- past this table.  Either (XIY+3)
; never has bit 5 set here in practice, or that lookup reads the following
; code.  What the remapped values mean is not established.
; -----------------------------------------------------------------------------
SMF_SlotParam_RPNReturn:
	.byte %s
	.byte %s
	; +0x1F (SMF_SlotParam_RPNReturn_0x1F): the same 31 bytes again
	.byte %s
	.byte %s
''' % (A('SMF_SlotParam_BankLSBReturn'),
       ", ".join("0x%02x" % x for x in rb[:16]), ", ".join("0x%02x" % x for x in rb[16:31]),
       ", ".join("0x%02x" % x for x in rb[31:47]), ", ".join("0x%02x" % x for x in rb[47:62]))
s = s.replace(old, new)

# SMF_SlotParam_PortamentoTime header
old = '\nSMF_SlotParam_PortamentoTime:\n'
assert s.count(old) == 1
s = s.replace(old, '''
; -----------------------------------------------------------------------------
; SMF_SlotParam_PortamentoTime -- a slot-parameter handler shaped like its
; neighbours (SMF_SlotParam_Sustain, ...): when RAM 0x112A is 2 or 3, RAM
; 0x2873 is 15, and the record at XIY has (XIY+2) = 0x14 and (XIY+3) = 4, it
; translates (XIY+2) through SMF_TranslateChannel (%s), stores it back,
; sets (XIY+3) := 2 and bit 0 of RAM 0x113B.
; NOT CALLED: it is absent from the `calr SMF_SlotParam_*` chain that runs
; every other handler, and scripts/analysis/sequi_find_refs.py %s %s finds
; no reference.  Nothing found supports "PortamentoTime" in the name.  Was
; `.byte` until 2026-09-25.
; -----------------------------------------------------------------------------
SMF_SlotParam_PortamentoTime:
''' % (A('SMF_TranslateChannel'), img, A('SMF_SlotParam_PortamentoTime')))
open(p, 'w', encoding='latin-1').write(s)
print('ok')
