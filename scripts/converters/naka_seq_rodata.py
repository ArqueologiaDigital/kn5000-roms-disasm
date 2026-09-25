#!/usr/bin/env python3
r"""naka_seq_rodata.py -- partition the sequencer constant data inside naka_widget_descriptors.

QUESTION ANSWERED
-----------------
Blob +0x13618..+0x1B272 (ROM 0xE44478..0xE4C0D2, 31,834 B) of
`naka_widget_descriptors.c` sat under four slice labels whose names were
guesses from the bytes -- `WidgetData_DrawbarPositionTable`,
`WidgetData_CharsetMappingTable`, `FontPalette_Gradient0..7` and a 29 KB
`Display_FontPalette_Table`.  None of it is widget data, a charset or a font
palette: the code reaches into the span at 144 offsets (listed by
`scripts/analysis/nakabig_rodata_refs.py`), all from the sequencer,
accompaniment, rhythm, SMF and floppy modules, and every reference is one of
a handful of compiled-C access shapes:

  switch   `lda xix,(T)` + `ldw_sri` (or `add xwa,T` + `ld wa,(xwa)`), then
           `lda xix,(Base); jp_ind`: u16 case offsets from Base -- the jump
           table of a C `switch`.  Entry count = the reader's own bound
           (`cp r,N; jr ugt` -> N+1 cases), taken from the source.
  local    `ld xiy,T; lda xix,(xsp+n); ld bc,N; ldirw` (or ldiw/ldi): the
           initializer of a local array, copied into the caller's frame;
           size = what the copy moves.
  procs    `lda xbc,(T); ld xhl,(xbc+4*i); jp (xhl)` / `call (xhl)`: u32
           code addresses.
  fdc      `lda xwa,(T); push xwa; call FDC_CommandEntry`: an FDC command
           block.
  memcpy   `lda xwa,(T); push; ...; call Mem_Copy`: a template copied out.
  lookup   indexed byte/word reads; layout from the index arithmetic where the
           reader shows it (the larger tables are laid out by hand below).

This module turns that into OBJECTS: (blob offset, size, name, C type, header),
one per object, tiling the span exactly.  Anything left between a typed object
and the next referenced offset becomes an explicit `*_Unref` object whose
header says what was searched.  `naka_c_retype.py` types the C from it and
`naka_s_headers.py` splits the .s slices and writes the headers.

The four historical labels stay at their offsets (other lanes' files --
shared/positional_labels.s above all -- define 144 names as offsets from
them), each with a header that says what really sits there.

RUN
    python3 scripts/converters/naka_seq_rodata.py            # print the partition
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'scripts', 'analysis'))

LO, HI = 0x13618, 0x1B1E4          # up to NakaInst_MEMORY_C (a separate slice)
HISTORICAL = {0x13618: 'WidgetData_DrawbarPositionTable',
              0x137D6: 'WidgetData_CharsetMappingTable',
              0x13D12: 'FontPalette_Gradient7',
              0x13FF8: 'Display_FontPalette_Table'}
for _k in range(7):
    HISTORICAL[0x13F98 - 0x60 * _k] = 'FontPalette_Gradient%d' % _k

SEARCHED = ('searched: every label and positional-label name anchored on the '
            'historical labels of this span, in all v10 .s files')


def refs():
    """offset -> [(file, line, routine, instr, after_lines, before_lines)]"""
    import nakabig_rodata_refs as RR
    srcs = RR.load_sources('v10')
    pos = {}
    for rel, lines in srcs:
        for ln in lines:
            m = re.match(r'\s*\.set (\w+), (\w+) \+ (\d+)\s*$', ln)
            if m and m.group(2) in RR.ANCHORS:
                pos[m.group(1)] = RR.ANCHORS[m.group(2)] + int(m.group(3))
    names = dict(pos)
    names.update(RR.ANCHORS)
    rx = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, names), key=len, reverse=True)) + r')\b')
    out = {}
    for rel, lines in srcs:
        if rel in ('shared/positional_labels.s', 'ui_widgets/widget_descriptors.s'):
            continue
        routine = None
        for i, ln in enumerate(lines):
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
            if m and not RR.LOCAL.search(m.group(1)):
                routine = m.group(1)
            code = ln.split(';')[0]
            for mm in rx.finditer(code):
                off = names[mm.group(1)]
                if LO <= off < HI:
                    cl = lambda s: ' '.join(s.split(';')[0].split())
                    out.setdefault(off, []).append(
                        (rel, i + 1, routine, cl(code),
                         [cl(x) for x in lines[i + 1:i + 9]],
                         [cl(x) for x in lines[max(0, i - 10):i]]))
    return out


def classify(rs):
    """-> (kind, info) from the first reference's shape."""
    rel, n, routine, ins, after, before = rs[0]
    aft = ' | '.join(after[:5])
    if 'jp_ind' in aft or 'jp_rr' in aft:
        base = re.search(r'lda xix, \((\w+):24\)', aft)
        bound = None
        for x in reversed(before):
            m = re.match(r'(?:cp|cps) \w+, (0x[0-9a-f]+|\d+)(?::i3)?$', x)
            if m and int(m.group(1), 0) > 0:
                bound = int(m.group(1), 0)
                break
        return 'switch', dict(base=base.group(1) if base else None, bound=bound)
    norm = [('ldiw' if (x == '.byte 0x95' and i + 1 < len(after) and after[i + 1] == 'rcf')
             else 'skip' if (x == 'rcf' and i > 0 and after[i - 1] == '.byte 0x95') else x)
            for i, x in enumerate(after)]
    if ins.startswith('ld xiy,') and any(x.startswith(('ldirw', 'ldiw', 'ldi85', 'ldir85')) for x in norm[:4]):
        size, bc = 0, 0
        for x in norm[:8]:
            m = re.match(r'ldw? bc, (0x[0-9a-f]+|\d+)(?::i3)?$', x)
            if m:
                bc = int(m.group(1), 0)
            elif x.startswith('ldirw'):
                size += 2 * bc
            elif x.startswith('ldir85'):
                size += bc
            elif x.startswith('ldiw'):
                size += 2
            elif x.startswith('ldi85'):
                size += 1
            elif x.startswith(('lda xix', 'ld xix', 'skip')):
                continue
            elif size:
                break
        return 'local', dict(after=[x for x in norm[:8] if x != 'skip'], size=size)
    if 'jp (xhl)' in aft or 'call (xhl)' in aft:
        return 'procs', {}
    if 'FDC_CommandEntry' in aft:
        return 'fdc', {}
    if 'Mem_Copy' in aft:
        return 'memcpy', {}
    return 'lookup', {}



# ---------------------------------------------------------------------------
# hand-laid objects: offset -> (size, name, ctype, dims, text).  `text` may
# use {Routine} placeholders (resolved to name + v10/v9/v7 addresses).
# ---------------------------------------------------------------------------
QGRIDS = {0x13D58: 96, 0x13DB8: 48, 0x13E18: 24, 0x13E78: 12,
          0x13ED8: 32, 0x13F38: 16, 0x13F98: 8}
RENAME = {o: 'QuantizeMap_Grid%d' % q for o, q in QGRIDS.items()}

MANUAL = {
    0x137D6: (16, 'WidgetData_CharsetMappingTable', 'uint32_t', '[4]',
              'Historical name (it is no charset map).  Four u32 code addresses: '
              'SeqInit_SetBaseAddress, SeqInit_ReturnStub, SeqInit_JumpToPartInit, '
              'SeqInit_FullReset.  SystemConfig_PointerTable (ui_widgets/widget_dispatch.s) '
              'holds `.long WidgetData_CharsetMappingTable`, and {MidiSysEx_ProcessBlock} '
              'calls entry 2 directly: `ld xhl,(<this>+8); call (xhl)`.'),
    0x139FC: (34, 'AppEvent_RecordDispatch_BitMasks', 'uint16_t', '[17]',
              'Seventeen u16 single-bit masks: 1 << k for k = 0..15, then 1 again.  '
              '{AppEvent_RecordDispatch} picks one (`lda xbc,<this>`, word move to '
              'RAM 0x0D4F).'),
    0x13A72: (36, 'AppEvtHandler_Branch_002_RamPtrs', 'uint32_t', '[9]',
              'Nine u32 RAM addresses (0xF1F1, 0x261C, 0xF228, 0x260E, 0x2604, 0xF1DB, '
              '0x2604, 0xF1D6, 0x2604).  {AppEvtHandler_Branch_002}: `lda xix,<this>; '
              'ld xwa,(xix+wa)` then `cp (xwa),0x11; incm8 1,(xwa)` -- a byte counter '
              'at the selected address.'),
    0x13B0E: (36, 'AppEvent_SubDispatch_RamPtrs', 'uint32_t', '[9]',
              'Byte-identical to AppEvtHandler_Branch_002_RamPtrs (nine u32 RAM '
              'addresses).  {AppEvent_SubDispatch} loads it with `lda xix,<this>`; the '
              'instructions after that load are still misframed as .byte in '
              'sequencer_engine.s (`e3 07 f0 e0` = ld xwa,(xix+wa)).'),
    0x13D44: (20, 'SeqStep_ParseRhythm_ByteMap', 'uint8_t', '[20]',
              '20 bytes 00 02 01 07 08 09 0A 0B 04 05 06 03 0F FF FF FF FF 0C 0D 0E.  '
              '{SeqStep_ParseRhythm} compares against it (`lda xhl,<this>; cpb_sri_rm '
              'A,(xhl+de)`); {SeqPart_InitValidOk} and {SeqPart_DualLoadPartB} move '
              'one byte of it to RAM 0x287C.  What the values stand for is not '
              'established.'),
    0x13FF8: (28, 'Display_FontPalette_Table', 'uint32_t', '[7]',
              'Historical name (it is no font palette).  Seven pointers to the '
              'QuantizeMap_Grid* tables above, in grid order 8, 12, 16, 24, 32, 48, 96 '
              'ticks.  {SeqPart_VelExprEdit} takes entry ((byte 0x25FE) >> 1): '
              '`lda xbc,<this>; ld xwa,(xbc+4*i)`.'),
    0x140A0: (276, 'SeqStep_TimerDispatch_ProcTables', 'uint32_t', '[3][23]',
              'Three tables of 23 u32 code addresses, one per timer dispatcher: '
              '{SeqStep_TimerDispatchA} uses +0x00, {SeqStep_TimerDispatchB} +0x5C, '
              '{SeqStep_TimerDispatchC} +0xB8 -- each `lda xbc,<table>; ld xhl,'
              '(xbc+4*i); jp (xhl)`.  The targets (SeqStep_PlaybackMaxPart, '
              'SeqPlay_BufferUpdateBlock, SeqNotify_DataBlock and three unlabelled '
              'addresses) are the handlers; 23 = (0x104-0xA8)/4, and all 69 values are '
              'code addresses (v7 relocates them through v7_c_divergence.json).'),
    0x14256: (32, 'FDC_Format2DD_BootSectorHead', 'uint8_t', '[32]',
              'First 32 bytes of the boot sector written by {FDC_Format2DD_WriteBoot} '
              '(Mem_Copy source): EB 1C 90, OEM name "Technics", then a FAT12 BIOS '
              'parameter block for a 720 KB 2DD disk -- 512 bytes/sector, 2 '
              'sectors/cluster, 1 reserved, 2 FATs, 112 root entries, 1440 sectors, '
              'media F9, 3 sectors/FAT, 9 sectors/track, 2 heads -- and EB FE.'),
    0x14276: (4, 'FDC_Format2DD_FatHead', 'uint8_t', '[4]',
              'F9 FF FF FF: the first FAT bytes (media byte F9) that '
              '{FDC_Format2DD_WriteFAT1} copies with Mem_Copy.'),
    0x1427A: (32, 'FDC_Format2HD_BootSectorHead', 'uint8_t', '[32]',
              'First 32 bytes of the boot sector written by {FDC_Format2HD_WriteBoot}: '
              'EB 1C 90, "Technics", FAT12 BPB for a 1.44 MB 2HD disk -- 512 '
              'bytes/sector, 1 sector/cluster, 1 reserved, 2 FATs, 224 root entries, '
              '2880 sectors, media F0, 9 sectors/FAT, 18 sectors/track, 2 heads -- '
              'EB FE.'),
    0x1429A: (4, 'FDC_Format2HD_FatHead', 'uint8_t', '[4]',
              'F0 FF FF FF: first FAT bytes (media F0) copied by '
              '{FDC_Format2HD_WriteFAT1} and {FDC_Format2HD_TrackTest}.'),
    0x142E2: (4096, 'RhythmROM_BankProgramLocators', 'uint16_t', '[8][128][2]',
              '8 banks x 128 programs x {u16 hi, u16 lo}.  {AccVoice_ComputeChannelIndex} '
              'shows the index: hl = (h & 7) * 512 + a * 4, then `ld wa,(xiy+hl)`, '
              '`add hl,2`, `ld iy,(xiy+hl)`; {RhythmROM_PatternDispatcher} stores the '
              'two words at 0x355A/0x355C, {DrumVoice_Handler7} and '
              '{VoiceAssign_ProcessRequest} read them the same way.  Measured: every '
              'non-zero pair forms hi:lo = a multiple of 0x800 below 0x70000; zero '
              'pairs mark unused (bank, program) slots.  What the 32-bit value '
              'locates is not established.'),
    0x1552A: (2048, 'VoiceParam_BankProgramWords', 'uint16_t', '[8][128]',
              '8 x 128 u16.  {VoiceParam_Clamp_LookupTable}: `ld xwa,<this>; sla l,1; '
              'and h,7; ld hl,(xwa+hl)` -- row h (bank, clamped to 0..7 by '
              'VoiceParam_Clamp_CheckBank), column l.  Meaning of the words not '
              'established.'),
    0x15D59: (64, 'AccStyle_DefaultStream', 'uint8_t', '[64]',
              'A 64-byte event stream: 03 FF FF FF FF 87, then fifteen '
              '`90 00 7D/7E 40 01 00` events separated by 81, then 81 83 87 -- it '
              'parses exactly under the ASEQ_* byte grammar of naka_types.h.  '
              '{AccStyle_SetupPartAddresses}, {AccStyle_SetupPartAddressesByHL}, '
              '{AccPart_InitPositionsAndBase}, {AccSeq_NextBarPage} and '
              '{AccSeq_ResetToStart} load <this>+6 into the accompaniment cursor at '
              'RAM 0x3293.'),
    0x15D99: (30, 'AccStyle_ExtStyleMap', 'uint8_t', '[30]',
              '30 bytes: 00 01 02 03 three times, then zeros.  {AccStyle_ApplyExtendedStyle} '
              'and {AccStyle_ExtendedInit} index it with (byte 0x32E5) & 0x7F, clamped '
              'to 0..0x1D -- the clamp pins the 30 entries.'),
    0x15DB7: (256, 'Seq_TempoByteMap', 'uint8_t', '[256]',
              '256 bytes indexed by the low byte of RAM word 0x0409: '
              '{Seq_ReadTempoLookup} (`add xhl,<this>; ld a,(xhl)`) stores the result '
              'at 0x334B.  Meaning of the values not established.'),
    0x161E7: (256, 'AccVoice_RomRecords16', 'uint8_t', '[16][16]',
              '16 records x 16 bytes.  {AccVoice_CopyFromROM_Do}: record l (l < 16, '
              'else 0) is copied with `ldir` of 0x10 bytes to RAM 0x34AB.'),
    0x162E7: (3640, 'AccVoice_RomRecords13', 'uint8_t', '[280][13]',
              '280 records x 13 bytes (3640 = 280 x 13 exactly).  {AccVoice_ComputedCopy}: '
              'record (l * 20 + h) is copied with `ldir` of 0x0D bytes to RAM 0x34AB '
              '(the same buffer AccVoice_RomRecords16 fills).'),
    0x1711F: (2016, 'AccStyle_RamImage_1E7800', 'uint8_t', '[2016]',
              'Initial image of RAM 0x1E7800..0x1E7FDF: {AccStyle_InitVRAM} copies '
              'exactly 0x7E0 bytes from here (`ld xix,0x1e7800; ldw bc,0x7e0; ldir`).'),
    0x184FF: (2048, 'AccStyle_VelocityTableMain', 'uint16_t', '[128][8]',
              '128 x 8 u16.  {AccStyle_LookupVelocityTable}, for byte 0x90EA < 128: '
              'index = 0x90EA * 8 + (byte 0x90EB & 7); the word goes to 0x90EE/0x90EF.'),
    0x18CFF: (756, 'AccStyle_TempoWordTable', 'uint16_t', '[378]',
              '378 u16.  {AccStyle_LookupTempo_AddAndStore}: index = '
              'AccStyle_TempoMultiplierTable[byte 0x90EA] + (byte 0x90EB, forced to 0 '
              'above 0x4F); the word goes to 0x90EE/0x90EF.  The extent is to the '
              'next referenced object; the index range was not bounded exactly.'),
    0x18FF3: (256, 'AccStyle_VelocityTableExt', 'uint16_t', '[16][8]',
              '16 x 8 u16.  {AccStyle_Velocity_ExtClamp}, for 128 <= byte 0x90EA < 240: '
              'row = 0x90EA & 0x7F (0 if above 0x0B), column = byte 0x90EB & 7 -- so '
              'rows 0..11 are reachable.'),
    0x190F3: (10, 'AccStyle_VelocityTableHigh', 'uint16_t', '[5]',
              '5 u16.  {AccStyle_Velocity_HighClamp}, for byte 0x90EA >= 240: index = '
              '0x90EA & 0x0F (0 if above 4).'),
    0x191E4: (96, 'TimeSig_ProcTable', 'uint32_t', '[24]',
              '24 u32 code addresses (Tempo_AdjustStartMeasure, Tempo_AdjustEndMeasure, '
              'Tempo_AdjustQuantize, Tempo_AdjustEffect, ...).  {TimeSig_DisplayStrings}: '
              '`ld xde,<this>; add xde,xbc; ld xhl,(xde); call (xhl)`.'),
    0x192D4: (160, 'AccRhythm_Ram3888_Records', 'uint8_t', '[10][16]',
              '10 records x 16 bytes.  The code after the label __pad_F67459 '
              '(sequencer/accompaniment_engine.s): `ld xiy,<this>; add xiy,xwa; ld xix,'
              '0x3888; ld xbc,0x10; ldir` -- one record is copied to RAM 0x3888.  '
              '160 = 10 x 16 is the extent to the next referenced object.'),
    0x1B1D8: (12, 'MainCmpCpFunc_LocalInit', 'uint32_t', '[3]',
              'Initializer of a local array of three string pointers -- " MEMORY-A ", '
              '" MEMORY-B ", " MEMORY-C " (NakaInst_MEMORY_A/B/C, which follow).  '
              '{MainCmpCpFunc}: `ld xiy,<this>; lda xix,(xsp+10); ld bc,6; ldirw` copies '
              'the 12 bytes into its stack frame.'),
    0x19374: (70, 'RhythmDrum_EntryCounts', 'uint8_t', '[7][10]',
              '7 x 10 byte counts.  {RhythmDrum_LoadVoiceParams} and '
              '{DrumParam_ReadMaxCount} index it with drum * 10 + (byte 0x37AB + '
              'drum); {VoiceAssign_ProcessRequest} sums the counts before an index to '
              'find that group\'s start in RhythmDrum_Entries.  The counts sum to '
              '1718, exactly the size of RhythmDrum_Entries.'),
    0x193BA: (6872, 'RhythmDrum_Entries', 'uint32_t', '[1718]',
              '1718 u32 in 70 consecutive groups whose sizes are RhythmDrum_EntryCounts '
              '(sum 1718 = 6872 / 4 -- the layout is pinned by that sum).  '
              '{VoiceAssign_ProcessRequest}: xde = (sum of the counts before the '
              'group + byte 0x37B2 + drum) * 4; `ld xhl,(<this>+xde)`.  The values '
              '(0x100, 0x10100, 0x20100, ...) are not addresses; their field meaning '
              'is not established.'),
    0x1AE92: (384, 'AccVoice_SlotRows', 'uint8_t', '[3][128]',
              '3 rows x 128 bytes.  The code after AccVoice_SetupSlots_DataBlock: '
              '`sll de,7; add xde,<this>; ld c,(xde+a)` -- row de, column a.  Meaning '
              'of the bytes not established.'),
}
def _qgrid_text(o, q):
    """Header text for one quantize map, with any deviation from exact
    rounding MEASURED from the ROM bytes (see qgrid_deviations)."""
    return ('Tick-quantize map for a %d-tick grid (the 96-tick unit of the '
            'sequencer): byte t is t rounded to the nearest multiple of %d, and '
            '0x7F where that rounds into the next unit%s.  Reached through '
            'Display_FontPalette_Table (entry %d); was FontPalette_Gradient%d, a '
            'name no code used.'
            % (q, q, QDEV.get(q, ''), sorted(QGRIDS.values()).index(q),
               (0x13F98 - o) // 0x60))


QDEV = {}


def qgrid_deviations(data):
    """Fill QDEV from the blob: every table is compared with exact
    round-to-nearest-multiple and the exceptions are quoted."""
    for o, q in QGRIDS.items():
        dev = {}
        for t in range(96):
            r = ((t + q // 2) // q) * q
            exp = 0x7F if r >= 96 else r
            if data[o + t] != exp:
                dev.setdefault((exp, data[o + t]), []).append(t)
        if not dev:
            QDEV[q] = ' -- exactly, for all 96 bytes (checked)'
        else:
            QDEV[q] = (' -- checked byte by byte, with one exception: ' +
                       '; '.join('the run for %d (t = %d..%d) is stored as 0x%02X = %d'
                                 % (e, ts[0], ts[-1], got, got)
                                 for (e, got), ts in sorted(dev.items())))


HELPLANG = [0x13C4A, 0x13C7C, 0x13CAE, 0x13CE0, 0x13D12]
for _i, _o in enumerate(HELPLANG):
    MANUAL[_o] = (50, 'FontPalette_Gradient7' if _o == 0x13D12 else 'HelpLang_ByteTable%d' % _i,
                  'uint8_t', '[50]',
                  ('Historical name (no palette). ' if _o == 0x13D12 else '') +
                  'One of five 50-byte tables at 50-byte spacing.  '
                  '{HelpLang_DispatchDataBlock} picks one of the five addresses '
                  '(0xE44AAA, 0xE44ADC, 0xE44B0E, 0xE44B40, 0xE44B72) and reads '
                  '`ld a,(xwa+bc)`; which help language selects which table, and what '
                  'the bytes mean, is not established.')
UNREF_NOTE = {
    0x141B4: 'Holds short NUL-terminated strings -- "A", "w~", "d", "wb", "r", "d", '
             '"r", "a", "d", ". " padded to 11 characters, "r" -- then zeros and '
             '02 02 01 00 02 70 00 A0 05 F9 03 00 09 00 02 00, the 2DD geometry '
             'fields of FDC_Format2DD_BootSectorHead.',
    0x1429E: 'Holds the strings "d" and "A:\\".',
    0x142C6: 'Holds the strings "A:\\", "+wb", "\\", "d", "rb", then 0xFF and '
             '"1 PianoDisc".',
}


def _dims_n(dims):
    n = 1
    for d in re.findall(r'\[(\d+)\]', dims):
        n *= int(d)
    return n


def objects(data, fmt):
    """Tile [LO, HI) with objects.  `fmt(text)` resolves {Routine} names.
    Returns [(off, size, name, ctype, dims, header)]."""
    R = refs()
    offs = sorted(R)
    qgrid_deviations(data)
    for _o, _q in QGRIDS.items():
        MANUAL[_o] = (96, RENAME[_o], 'uint8_t', '[96]', _qgrid_text(_o, _q))
    starts = sorted(set(offs) | set(MANUAL) | set(QGRIDS))
    out = []
    used = {}

    def uniq(nm):
        used[nm] = used.get(nm, 0) + 1
        return nm if used[nm] == 1 else '%s_%d' % (nm, used[nm])

    def readers(off):
        seen, rs = set(), []
        for rel, n, routine, ins, after, before in R.get(off, []):
            if routine not in seen:
                seen.add(routine)
                rs.append('{%s} (`%s`)' % (routine, ins))
        return rs

    k = 0
    cur = LO
    boundaries = starts + [HI]
    while cur < HI:
        nxt = min(b for b in boundaries if b > cur)
        ext = nxt - cur
        if cur in MANUAL:
            size, name, ctype, dims, text = MANUAL[cur]
            interior = [o for o in offs if cur < o < cur + size]
            if interior:
                text += ('  The code also points into it at %s.'
                         % ', '.join('+0x%X' % (o - cur) for o in interior))
            hdr = '%s -- %s' % (name, fmt(text))
            if HISTORICAL.get(cur) == name and 'Historical' not in text:
                hdr += '  (Label name kept for positional_labels.s.)'
            out.append((cur, size, name, ctype, dims, hdr))
            cur += size
            continue
        if cur not in R:
            # an unreferenced remainder after a typed object
            prev = out[-1][2] if out else 'the span start'
            note = UNREF_NOTE.get(cur, '')
            name = uniq('%s_Tail' % re.sub(r'_Tail(_\d+)?$', '', prev))
            out.append((cur, ext, name, 'uint8_t', '[%d]' % ext,
                        '%s -- %d bytes after %s that no code reference reaches '
                        '(%s).  %sContents not established.'
                        % (name, ext, prev, SEARCHED, note + ' ' if note else '')))
            cur = nxt
            continue
        kind, info = classify(R[cur])
        rel, n, routine, ins, after, before = R[cur][0]
        rd = readers(cur)
        size, ctype, dims = ext, 'uint8_t', '[%d]' % ext
        if kind == 'switch':
            b = info['bound']
            nc = b + 1 if b is not None and 2 * (b + 1) <= ext else None
            if nc is None:
                nc = ext // 2
                how = ('the reader\'s bound is not visible in the source (the code '
                       'after the load is still misframed), so the %d entries are the '
                       'extent to the next referenced object' % nc)
            else:
                how = 'the reader\'s bound `cp ..., %d` pins %d cases' % (b, nc)
            size, ctype, dims = 2 * nc, 'uint16_t', '[%d]' % nc
            name = uniq('%s_CaseTable' % routine)
            txt = ('jump table of a compiled `switch` in %s: case k jumps to %s + '
                   'entry[k] (`lda xix,(%s); jp_ind`).  %d u16 offsets; %s.'
                   % (', '.join(rd), info['base'] or 'the base loaded next',
                      info['base'], nc, how))
        elif kind == 'local':
            size = min(info['size'] or ext, ext)
            copy = []
            for x in info['after']:
                copy.append(x)
                if x.startswith(('ldirw', 'ldir85')) or len(copy) >= 5:
                    break
            name = uniq('%s_LocalInit' % routine)
            ctype, dims = ('uint16_t', '[%d]' % (size // 2)) if size % 2 == 0 and size > 2 \
                else ('uint8_t', '[%d]' % size)
            txt = ('initializer of a local array: %s; `%s` copies %d bytes into the '
                   'routine\'s stack frame.' % (', '.join(rd), '; '.join(copy), size))
        elif kind == 'procs':
            m = 0
            while 4 * (m + 1) <= ext and 0xF00000 <= int.from_bytes(
                    data[cur + 4 * m:cur + 4 * m + 4], 'little') < 0x1000000:
                m += 1
            size, ctype, dims = 4 * m, 'uint32_t', '[%d]' % m
            name = uniq('%s_ProcTable' % routine)
            txt = ('%d u32 code addresses: %s loads entry [i] and transfers to it.'
                   % (m, ', '.join(rd)))
        elif kind == 'fdc':
            name = uniq('%s_FdcCmd' % routine)
            txt = ('FDC command block: %s passes its address to FDC_CommandEntry '
                   '(`lda xwa,<this>; push xwa; call FDC_CommandEntry`).  %d bytes to '
                   'the next referenced object; the field layout is not established.'
                   % (', '.join(rd), ext))
        elif kind == 'memcpy':
            name = uniq('%s_Template' % routine)
            txt = ('Mem_Copy source in %s.  %d bytes to the next referenced object.'
                   % (', '.join(rd), ext))
        else:
            name = uniq(('%s_Data' if routine.endswith('Table') else '%s_Table') % routine)
            txt = ('read by %s.  %d bytes to the next referenced object; the layout '
                   'beyond that access is not established.' % (', '.join(rd), ext))
        if cur in HISTORICAL:
            name = HISTORICAL[cur]
            txt = ('Historical name, kept for positional_labels.s and the other '
                   'files that use it; the object here is a ' + txt)
        out.append((cur, size, name, ctype, dims, '%s -- %s' % (name, fmt(txt))))
        cur += size
    assert sum(o[1] for o in out) == HI - LO
    for o in out:
        assert _dims_n(o[4]) * {'uint8_t': 1, 'uint16_t': 2, 'uint32_t': 4}[o[3]] == o[1], o[:5]
    return out


PTR_TABLES = {0x137D6, 0x13FF8, 0x140A0, 0x191E4, 0x1B1D8}


def _fmt_vals(vals, dims, width, per_line):
    """Nested C initializer for a flat value list."""
    ds = [int(d) for d in re.findall(r'\[(\d+)\]', dims)]

    def lit(v):
        return v if isinstance(v, str) else ('0x%%0%dX' % (2 * width)) % v

    def rec(vs, ds, ind):
        if len(ds) == 1:
            items = [lit(v) for v in vs]
            if len(items) <= per_line and all(not isinstance(v, str) for v in vs):
                return '{ ' + ', '.join(items) + ' }'
            lines = [', '.join(items[i:i + per_line]) for i in range(0, len(items), per_line)]
            return '{\n' + '\n'.join(' ' * (ind + 4) + l + ',' for l in lines) + '\n' + ' ' * ind + '}'
        step = len(vs) // ds[0]
        parts = [rec(vs[i:i + step], ds[1:], ind + 4) for i in range(0, len(vs), step)]
        return '{\n' + '\n'.join(' ' * (ind + 4) + '/* %d */ ' % k + p + ','
                                   for k, p in enumerate(parts)) + '\n' + ' ' * ind + '}'
    return rec(vals, ds, 4)


def new_members(cb, data, fmt):
    """-> (NewMember list, names of old members whose symbolic value is
    re-expressed or retired) for the whole span."""
    import naka_c_model as M
    olds = {}
    for mb, e in zip(cb.members, cb.entries):
        if LO <= mb.offset < HI and mb.ctype == 'uint32_t':
            if mb.dims:
                for k, x in enumerate(cb.elements(mb.name)):
                    olds[mb.offset + 4 * k] = x
            else:
                olds[mb.offset] = e.expr.strip()
    out = []
    for off, size, name, ctype, dims, hdr in objects(data, fmt):
        w = {'uint8_t': 1, 'uint16_t': 2, 'uint32_t': 4}[ctype]
        vals = [int.from_bytes(data[off + i:off + i + w], 'little') for i in range(0, size, w)]
        if off in PTR_TABLES:
            vals = [olds.get(off + 4 * k, v) for k, v in enumerate(vals)]
            vals = [v if isinstance(v, int) or M.SYMBOLIC_RE.search(v) else int(v, 0)
                    for v in vals]
        per = {1: 16, 2: 8, 4: 4}[w]
        if off in PTR_TABLES:
            per = 1
        expr = _fmt_vals(vals, dims, w, per)
        pre = M.comment_block(wrap_text(hdr))
        out.append(M.NewMember(ctype, name, dims, size, expr, pre))
    reexp = [mb.name for mb in cb.members if LO <= mb.offset < HI and
             M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
    return out, reexp


def wrap_text(t):
    import textwrap
    return textwrap.fill(' '.join(t.split()), width=70, break_long_words=False,
                         break_on_hyphens=False)


if __name__ == '__main__':
    import naka_c_retype as NR
    data = open(os.path.join(ROOT, 'v10/maincpu/includes/generated/naka_widget_descriptors.bin'), 'rb').read()
    for off, size, name, ctype, dims, hdr in objects(data, NR.fmt):
        print('+0x%05X %5d %-9s %-12s %s' % (off, size, ctype, dims, name))
        if '-v' in sys.argv:
            print('        ' + hdr)
