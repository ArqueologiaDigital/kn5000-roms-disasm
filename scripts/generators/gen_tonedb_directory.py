#!/usr/bin/env python3
"""Generate tone_database_directory.s (ROM 0x830000-0x8324D3) from the original ROM.

Also emits external_labels_stub.s (p6/p7 label placement used for the standalone
self-check harness) and harness.s.
"""
import struct, collections

import os
_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = open(os.path.join(_REPO, 'original_ROMs', 'kn5000_table_data.rom'), 'rb').read()
BASE = 0x800000
DB = 0x830000
OFF = DB - BASE               # 0x30000
END = 0x8324D4                # exclusive
d = ROM[OFF:END - BASE]

def u16(a): return struct.unpack_from('<H', d, a)[0]
def u32(a): return struct.unpack_from('<I', d, a)[0]

# ---- 629-entry tone offset table ----
NENT = 629
tbl = [u32(0x1B00 + 4 * i) for i in range(NENT)]
first_idx = {}
for i, v in enumerate(tbl):
    first_idx.setdefault(v, i)

def rec_name(v):
    a = DB - BASE + v
    return ROM[a:a + 16].decode('latin1').strip()

KIT_RANGE = range(310, 336)      # 26 drum kits, live in the aux area (p7)
DRAWBAR = (336, 337)             # drawbar organ records, aux area (p7)

# Records living outside the record module (drum kits / drawbar presets, table
# indices 310-337) carry the aux module's semantic labels instead of ToneRec_NNN.
REC_NAME_OVERRIDE = {
    310: 'DrumKit_05_JazzKit',
    311: 'DrumKit_19_JazzKit',
    312: 'DrumKit_07_BrushKit',
    313: 'DrumKit_20_BrushKit',
    314: 'DrumKit_06_TradKit',
    315: 'DrumKit_00_StandardKit',
    316: 'DrumKit_14_StandardKit',
    317: 'DrumKit_18_AnalogKit',
    318: 'DrumKit_01_RoomKit',
    319: 'DrumKit_15_RoomKit',
    320: 'DrumKit_03_LightRockKit',
    321: 'DrumKit_02_PowerKit',
    322: 'DrumKit_16_PowerKit',
    323: 'DrumKit_04_FunkKit',
    324: 'DrumKit_08_DanceKit',
    325: 'DrumKit_09_HouseKit',
    326: 'DrumKit_10_SoulKit',
    327: 'DrumKit_11_ElectricKit',
    328: 'DrumKit_17_ElectricKit',
    329: 'DrumKit_23_SynthKit',
    330: 'DrumKit_12_OrchestralKit',
    331: 'DrumKit_21_OrchestralKit',
    332: 'DrumKit_24_SoundEffectKit',
    333: 'DrumKit_25_SoundEffectKit',
    334: 'DrumKit_13_MSPKit',
    335: 'DrumKit_22_SpecialKit',
    336: 'DrawbarPreset_Jazz',
    337: 'DrawbarPreset_Rock',
}

def rec_label(i):
    return REC_NAME_OVERRIDE.get(i, f'ToneRec_{i:03d}')


# ---- aux (p7) labels referenced by the directory ----
aux_labels = {
    0x855A48: 'ToneDB_DefaultLayerParams',
    0x855A99: 'ToneDB_ToneIndexMapA',
    0x856299: 'ToneDB_ToneIndexMapB',
    0x856A99: 'ToneDB_MixerDefaultTable',
    0x857914: 'ToneDB_EnvDescTable',
    0x85959D: 'ToneDB_ToneIndexMapC',
    0x859D9D: 'ToneDB_ToneIndexMapD',
    0x85A59D: 'ToneDB_DrumToneIndexMap',
    0x864E6F: 'PercInst_000_Silent',
    0x86D8A3: 'DrumKit_NoteMapA',
    0x86F8A3: 'ToneDB_PercMixerDefaultTable',
    0x86FEBD: 'ToneDB_PercSourceIndexMapA',
    0x870A11: 'DrawbarPreset_EnvDescTable',
    0x872C91: 'ToneDB_SourceNameList1',
    0x874161: 'ToneDB_SourceIndexMapA',
    0x874961: 'ToneDB_SourceIndexMapB',
    0x875161: 'ToneDB_SourceList1_Footer',
    0x875172: 'ToneDB_SourceNameList2',
    0x8766A2: 'ToneDB_SourceIndexMapC',
    0x876EA2: 'ToneDB_SourceIndexMapD',
    0x8776A2: 'ToneDB_SourceList2_Footer',
    0x8776B3: 'ToneDB_PercSourceNameList1',
    0x877F83: 'ToneDB_PercList1_Footer',
    0x877F91: 'ToneDB_PercSourceIndexMapB',
    0x878791: 'ToneDB_PercSourceNameList2',
    0x879091: 'ToneDB_PercSourceIndexMapC',
    0x879891: 'ToneDB_PercList2_Footer',
    0x87989F: 'ToneDB_DrumSourceNameList',
    0x87B31F: 'ToneDB_DrumList_Footer',
    0x87B322: 'DrumKit_NoteMapB',
    0x87D322: 'PercName_Pack',
}

def lbl(addr):
    """Symbol for a DB-relative offset used in a directory slot."""
    if addr in aux_labels:
        return aux_labels[addr]
    raise KeyError(hex(addr))

out = []
w = out.append

w('; =============================================================================')
w('; TONE DATABASE -- Directory, Program Maps and Tone-Record Offset Table')
w('; =============================================================================')
w('; ROM range 0x830000-0x8324D3.  This is the head of the tone/voice database')
w('; that the Main CPU ships to the Sub CPU at boot: SubCPU_Send_Payload')
w('; (maincpu) copies ROM 0x830000-0x87FFFF into Sub-CPU work RAM 0x050000-')
w('; 0x09FFFF as five 64KB InterCPU E1 bulk transfers.  DSP_System_Init (subcpu)')
w('; then stores the RAM base 0x050000 at ToneDB_RelBase (0x045310) and')
w('; ToneDB_RootPtr (0x045314).  ALL offsets inside the database are relative to')
w('; ToneDB_Base, so every value here is equally valid as a Sub-CPU address')
w('; (0x050000 + offset) -- keep this aliasing in mind when reading the subcpu')
w('; disassembly, which never sees the 0x83xxxx addresses.')
w(';')
w('; The Sub CPU addresses the database exclusively through the directory below:')
w('; a table of 4-byte little-endian entries at ToneDB_Base, each entry either a')
w('; database-relative offset, a scalar parameter, or 0xFFFFFFFF/0 (unused).')
w('; Subcpu code reads a slot as (ToneDB_RootPtr)[slot offset] and adds')
w('; ToneDB_RelBase.')
w(';')
w('; DATABASE LAYOUT (this module covers the first three regions):')
w(';   0x830000  ToneDB_Directory        4-byte slots, consumers noted per line')
w(';   0x830100  ToneDB_BankMap_Main     bank-select byte map (128 entries)')
w(';   0x830180  ToneDB_ToneNumBanks_Main 11 banks x 128 LE16 tone numbers')
w(';   0x830C80  ToneDB_BankMap_Coeff    bank-select byte map (128 entries)')
w(';   0x830D00  ToneDB_ToneNumBanks_Coeff 14 banks x 128 LE16 tone numbers')
w(';   0x831B00  ToneDB_ToneOffsetTable  629 LE32 offsets -> tone records')
w(';   0x8324D4  tone/voice records (ToneRec_000...), variable length, 16-char')
w(';             space-padded name first; drum-kit and drawbar records plus all')
w(';             auxiliary wave/coefficient tables follow at 0x8558AE+ (see the')
w(';             per-slot comments; those labels are defined with the aux data).')
w(';')
w('; TONE LOOKUP (ToneDB_Find_PatchRecord, subcpu): the caller presents a bank')
w('; selector (high byte) and a program number (low 7 bits).  The bank selector')
w('; indexes ToneDB_BankMap_Main to fetch a bank byte b; bank bytes 0x10, 0x15,')
w('; 0x50, 0x55 divert to RAM-resident user/edit banks, otherwise tone number =')
w('; u16[ToneDB_ToneNumBanks_Main + (b*128 + program)*2].  The tone number then')
w('; indexes ToneDB_ToneOffsetTable; record = ToneDB_Base + entry.')
w('; ToneDB_Find_ToneRecord_CoeffPath performs the same walk through')
w('; ToneDB_BankMap_Coeff (slot +0x6C) with no bank-validity filter.')
w(';')
w('; DSP1 STREAM BIAS (slot +0x88) -- verified against DSP1_ResolveStreamPtr in')
w('; the subcpu disassembly: the routine loads XBC from (base + 0x88) -- the')
w('; dword 338 below -- adds BC to the caller\'s stream index WA, fetches the')
w('; dword at base + (word at base+0x08) + 4*index, i.e. this module\'s')
w('; ToneDB_ToneOffsetTable[index + 338], and returns XHL = base + entry.  So')
w('; "stream" indices used by DSP_Reinit_VoiceSlots (its only 3 call sites) are')
w('; biased past the first 338 entries: the region starting at ToneRec_338 holds')
w('; the records that DSP1 streams are resolved from.  Consistently, the')
w('; ToneNumBanks_Main tables only hold tone numbers 0-337 while the')
w('; ToneNumBanks_Coeff tables hold 311-628.')
w('; =============================================================================')
w('')
w('ToneDB_Base:')
w('ToneDB_Directory:')

# ---- directory ----
# slot -> (expr, comment)   expr None => emit raw value
def rel(name): return f'{name} - ToneDB_Base'

slots = {
 0x00: (None, 'slot +0x00: unused'),
 0x04: (rel('ToneDB_BankMap_Main'),
        'slot +0x04: bank map + tone-number banks (preset lookup path)'),
 0x08: (rel('ToneDB_ToneOffsetTable'),
        'slot +0x08: tone-record offset table (629 entries)'),
 0x0C: (rel('ToneDB_ToneIndexMapA'),
        'slot +0x0C: WaveSel_StageA1 index table, SET families 0x00/0xC0'),
 0x10: (rel('ToneDB_ToneIndexMapB'),
        'slot +0x10: WaveSel_StageA1 index table, family 0x80'),
 0x14: (rel('ToneDB_PercSourceIndexMapA'),
        'slot +0x14: WaveSel_StageA1 index table, family 0x40'),
 0x18: (rel('ToneDB_MixerDefaultTable'),
        'slot +0x18: wave-select records, families 0x00/0xC0 (stride = word +0xEA)'),
 0x1C: (rel('ToneDB_MixerDefaultTable'),
        'slot +0x1C: family 0x80 shares the family-0x00 records'),
 0x20: (rel('ToneDB_PercMixerDefaultTable'),
        'slot +0x20: wave-select records, family 0x40 (stride = word +0xF0)'),
 0x24: (rel('ToneDB_ToneIndexMapC'),
        'slot +0x24: WaveSel_StageA2 index table, families 0x00/0xC0'),
 0x28: (rel('ToneDB_ToneIndexMapD'),
        'slot +0x28: WaveSel_StageA2 index table, family 0x80'),
 0x2C: (rel('ToneDB_DrumToneIndexMap'),
        'slot +0x2C: WaveSel_StageA2 index table, family 0x40'),
 0x30: (rel('ToneDB_EnvDescTable'),
        'slot +0x30: wave-set descriptors, families 0x00/0xC0 (stride = word +0xEC)'),
 0x34: (rel('ToneDB_EnvDescTable'),
        'slot +0x34: family 0x80 (same descriptor block)'),
 0x38: (rel('ToneDB_EnvDescTable'),
        'slot +0x38: family 0x40 (same block, stride = word +0xF2)'),
 0x3C: (None, 'slot +0x3C: unused'),
 0x40: (None, 'slot +0x40: unused'),
 0x44: (rel('ToneDB_SourceIndexMapA'),
        'slot +0x44: DSP_RouteCoeffs_TypeA row-index table, selectors 00/11'),
 0x48: (rel('ToneDB_SourceIndexMapB'),
        'slot +0x48: DSP_RouteCoeffs_TypeA row-index table, selector 10'),
 0x4C: (rel('ToneDB_PercSourceIndexMapB'),
        'slot +0x4C: DSP_RouteCoeffs_TypeA row-index table, selector 01'),
 0x50: (rel('ToneDB_SourceNameList1'),
        'slot +0x50: wave catalogue A, 16-byte named rows ("Piano L", ...)'),
 0x54: (rel('ToneDB_SourceList1_Footer'),
        'slot +0x54: DSP_AlgoCoeffLookup bank 0/default (self-sized block)'),
 0x58: (rel('ToneDB_SourceIndexMapC'),
        'slot +0x58: DSP_VoiceCoeffRoute2 row-index table, selectors 00/11'),
 0x5C: (rel('ToneDB_SourceIndexMapD'),
        'slot +0x5C: DSP_VoiceCoeffRoute2 row-index table, selector 10'),
 0x60: (rel('ToneDB_PercSourceIndexMapC'),
        'slot +0x60: DSP_VoiceCoeffRoute2 row-index table, selector 01'),
 0x64: (rel('ToneDB_SourceNameList2'),
        'slot +0x64: wave catalogue B, 16-byte named rows'),
 0x68: (rel('ToneDB_SourceList2_Footer'),
        'slot +0x68: DSP_AlgoCoeffLookup bank 1'),
 0x6C: (rel('ToneDB_BankMap_Coeff'),
        'slot +0x6C: coefficient-path bank map (sole consumer: ToneDB_Find_ToneRecord_CoeffPath)'),
 0x70: (rel('DrawbarPreset_EnvDescTable'),
        'slot +0x70: alternate 15-byte descriptor records (stride = word +0xEC)'),
 0x74: (rel('DrumKit_NoteMapA'),
        'slot +0x74: drum-instrument index table (ToneDB_Resolve_NamedToneRecord)'),
 0x78: (rel('PercInst_000_Silent'),
        'slot +0x78: drum-instrument records, 13-char name + params (stride = word +0xEE)'),
 0x7C: (rel('DrumKit_NoteMapB'),
        'slot +0x7C: DSP_RouteCoeffs four-way row-index table (all selectors)'),
 0x80: (rel('ToneDB_DrumSourceNameList'),
        'slot +0x80: wave catalogue C, 16-byte named rows (custom-tone loader)'),
 0x84: (rel('ToneDB_DrumList_Footer'),
        'slot +0x84: DSP_AlgoCoeffLookup bank 2'),
 0x88: ('338',
        'slot +0x88: DSP1 stream-index bias -- see header (DSP1_ResolveStreamPtr)'),
 0x8C: (rel('ToneDB_PercSourceNameList1'),
        'slot +0x8C: sub-unit wave catalogue (VoiceParam_CustomTone_Apply_Catalog8C)'),
 0x90: (rel('ToneDB_PercList1_Footer'),
        'slot +0x90: DSP_AlgoCoeffLookup bank 3'),
 0x94: (rel('ToneDB_PercSourceNameList2'),
        'slot +0x94: pair-mode wave catalogue (VoiceParam_CustomTone_Apply_Catalog94)'),
 0x98: (rel('ToneDB_PercList2_Footer'),
        'slot +0x98: DSP_AlgoCoeffLookup bank 4'),
 0x9C: (rel('ToneDB_ToneIndexMapC'),
        'slot +0x9C: StageA2 alt-mode alias (ToneGen_GlobalFlags bit 2), fam 0x00/0xC0'),
 0xA0: (rel('ToneDB_ToneIndexMapD'),
        'slot +0xA0: StageA2 alt-mode alias, family 0x80'),
 0xA4: (rel('ToneDB_DrumToneIndexMap'),
        'slot +0xA4: StageA2 alt-mode alias, family 0x40'),
 0xA8: (None, 'slot +0xA8: unused'),
 0xAC: (rel('ToneDB_DefaultLayerParams'),
        'slot +0xAC: fallback descriptor bound when a patch partial is absent (EFF slot scan)'),
 0xB0: (rel('PercName_Pack'),
        'slot +0xB0: packed 10-char percussion-source names (stride 10, no terminators)'),
 0xB4: (None, 'slot +0xB4: unused'),
 0xB8: (None, 'slot +0xB8: unused'),
 0xBC: (None, 'slot +0xBC: unused'),
}

for off in range(0x00, 0xC0, 4):
    v = u32(off)
    expr, comment = slots[off]
    if expr is None:
        assert v in (0xFFFFFFFF,), hex(v)
        field = '.long 0xFFFFFFFF'
    else:
        # verify the expression's value against the ROM
        if expr == '338':
            assert v == 338
        else:
            name = expr.split(' ')[0]
            want = {vv: kk for kk, vv in aux_labels.items()}
            if name in want:
                assert want[name] - DB == v, (name, hex(v))
            else:
                local = {'ToneDB_BankMap_Main': 0x100, 'ToneDB_ToneOffsetTable': 0x1B00,
                         'ToneDB_BankMap_Coeff': 0xC80}
                assert local[name] == v, (name, hex(v))
        field = f'.long {expr}'
    pad = '\t' * max(1, (72 - 8 - len(field) + 7) // 8)
    w(f'\t{field}{pad}; {comment}')

# tail of the directory: scalar parameter words
w('')
w('; Directory tail: scalar parameters (read as 16-bit words by the subcpu).')
w('; The four stride/length words +0xEA/+0xEC/+0xEE/+0xF0 (and +0xF2) size the')
w('; records behind the pointer slots above; word offsets not listed in a')
w('; comment have no reader in the v1.42 subcpu image.')
assert d[0xC0:0xD0] == b'\x00' * 16
w('\t.long 0, 0, 0, 0\t\t\t\t\t\t; +0xC0..+0xCF: unused (zero)')
tailc = {
 0xD0: 'unread in v1.42',
 0xD2: '',
 0xD4: 'unread in v1.42',
 0xD6: '',
 0xD8: 'unread in v1.42',
 0xDA: '',
 0xE0: 'unread in v1.42',
 0xE8: 'unread in v1.42',
 0xEA: 'wave-select record stride/copy length, families 0x00/0x80/0xC0',
 0xEC: 'set-descriptor stride, families 0x00/0x80/0xC0 (also SetDescRecs_Alt)',
 0xEE: 'drum-instrument record stride/copy length',
 0xF0: 'wave-select record stride/copy length, family 0x40',
 0xF2: 'set-descriptor stride, family 0x40',
}
o = 0xD0
while o < 0x100:
    v = u16(o)
    c = tailc.get(o, '')
    field = f'\t.short {v}'
    pad = '\t' * max(1, (72 - 8 - len(field) + 8) // 8)
    if c:
        w(f'{field}{pad}; +0x{o:02X}: {c}')
    elif v == 0:
        # coalesce runs of zero shorts without comments
        run = 0
        oo = o
        while oo < 0x100 and u16(oo) == 0 and tailc.get(oo, '') == '':
            run += 1
            oo += 2
        if run > 1:
            w(f'\t.short {", ".join(["0"] * run)}')
            o = oo
            continue
        w(field)
    else:
        w(field)
    o += 2

# ---- bank map main ----
mapA = d[0x100:0x180]
w('')
w('; =============================================================================')
w('; BANK-SELECT MAPS AND TONE-NUMBER BANKS')
w('; =============================================================================')
w('; A bank map is 128 bytes indexed by the bank selector byte of a tone lookup;')
w('; the fetched value picks one 128-entry tone-number bank below (values 0x10/')
w('; 0x15/0x50/0x55 would divert to RAM edit buffers -- none occur in this ROM).')
w('; Tone numbers index ToneDB_ToneOffsetTable.')
w('; =============================================================================')
w('ToneDB_BankMap_Main:')
for r in range(0, 0x80, 16):
    row = mapA[r:r + 16]
    field = '\t.byte ' + ', '.join(str(b) for b in row)
    w(f'{field}\t; selectors 0x{r:02X}-0x{r + 15:02X}')

banksA = [[u16(0x180 + b * 0x100 + 2 * i) for i in range(128)] for b in range(11)]
w('')
w('; 11 banks x 128 LE16 tone numbers for the preset lookup path (slot +0x04).')
w('; Only tone numbers 0-337 appear here (the un-biased half of the offset')
w('; table).  Unassigned program slots repeat a default tone of the bank.')
w('ToneDB_ToneNumBanks_Main:')
for b, bank in enumerate(banksA):
    sels = [i for i, x in enumerate(mapA) if x == b]
    if b == 0:
        sels_s = '0x00 (and every selector the map leaves at 0)'
    else:
        sels_s = ', '.join(f'0x{s:02X}' for s in sels)
    w(f'; Bank {b}: selector(s) {sels_s}; tone numbers {min(bank)}-{max(bank)}.')
    w(f'ToneDB_ToneNumBank_Main{b:02d}:')
    for r in range(0, 128, 8):
        w('\t.short ' + ', '.join(str(x) for x in bank[r:r + 8]))

# ---- bank map coeff ----
mapB = d[0xC80:0xD00]
w('')
w('ToneDB_BankMap_Coeff:')
for r in range(0, 0x80, 16):
    row = mapB[r:r + 16]
    field = '\t.byte ' + ', '.join(str(b) for b in row)
    w(f'{field}\t; selectors 0x{r:02X}-0x{r + 15:02X}')

banksB = [[u16(0xD00 + b * 0x100 + 2 * i) for i in range(128)] for b in range(14)]
w('')
w('; 14 banks x 128 LE16 tone numbers for the unfiltered coefficient path')
w('; (slot +0x6C).  Only tone numbers 311-628 appear here -- the drum kits,')
w('; drawbar records and the DSP1 stream region of the offset table.')
w('ToneDB_ToneNumBanks_Coeff:')
for b, bank in enumerate(banksB):
    sels = [i for i, x in enumerate(mapB) if x == b]
    if b == 0:
        sels_s = '0x00 (and every selector the map leaves at 0)'
    else:
        sels_s = ', '.join(f'0x{s:02X}' for s in sels)
    w(f'; Bank {b}: selector(s) {sels_s}; tone numbers {min(bank)}-{max(bank)}.')
    w(f'ToneDB_ToneNumBank_Coeff{b:02d}:')
    for r in range(0, 128, 8):
        w('\t.short ' + ', '.join(str(x) for x in bank[r:r + 8]))

# ---- 629-entry offset table ----
w('')
w('; =============================================================================')
w('; TONE-RECORD OFFSET TABLE -- 629 LE32 database-relative offsets')
w('; =============================================================================')
w('; Entry n is the offset of tone record ToneRec_n from ToneDB_Base.  Records')
w('; carry a 16-char space-padded name first; the name is quoted per entry.')
w('; Entries 310-335 are the 26 drum-kit records and 336/337 the two drawbar')
w('; records; those live past the plain tone records, among the aux tables.')
w('; Entries 378-399 are unused slots aliasing entry 0.  Entries 338 and up form')
w('; the DSP1 stream region (see the bias note in the module header).')
w('; =============================================================================')
w('ToneDB_ToneOffsetTable:')
for i, v in enumerate(tbl):
    fi = first_idx[v]
    name = rec_name(v)
    if i == 338:
        w('; --- DSP1 stream region: entries 338+ = stream index 0+ after the +338 bias ---')
    note = ''
    if i in KIT_RANGE:
        note = ' (drum kit)'
    elif i in DRAWBAR:
        note = ' (drawbar organ)'
    if fi != i:
        w(f'\t.long {rec_label(fi)} - ToneDB_Base\t; {i}: unused slot, aliases entry {fi} "{name}"')
    else:
        w(f'\t.long {rec_label(i)} - ToneDB_Base\t; {i}: "{name}"{note}')

open('tone_database_directory.s', 'w').write('\n'.join(out) + '\n')

# ---- external label stubs for the standalone self-check ----
stub = []
stub.append('; Self-check stubs: places every label that tone_database_directory.s')
stub.append('; references outside its own range (p6 tone records / p7 aux tables) at')
stub.append('; its authoritative ROM address.  Used ONLY by the standalone harness;')
stub.append('; the real definitions belong to the record/aux-table modules.')
places = {}
for v, i in first_idx.items():
    places.setdefault(DB + v, []).append(rec_label(i))
for a, name in aux_labels.items():
    places.setdefault(a, []).append(name)
for a in sorted(places):
    stub.append(f'\t.org 0x{a:06X} - 0x800000')
    for name in sorted(places[a]):
        stub.append(f'{name}:')
open('external_labels_stub.s', 'w').write('\n'.join(stub) + '\n')

harness = f'''\t.text
\t.org 0x830000 - 0x800000, 0xFF
\t.include "tone_database_directory.s"
\t.include "external_labels_stub.s"
'''
open('harness.s', 'w').write(harness)
print('generated: tone_database_directory.s (%d lines), stubs (%d labels at %d addresses)'
      % (len(out), sum(len(v) for v in places.values()), len(places)))
