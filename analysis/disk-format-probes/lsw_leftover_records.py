#!/usr/bin/env python3
"""The KN5000 panel-TLV records the previous pass left unidentified: 0x9A, 0x68, 0x43,
0x71, 0x44/0x45/0x46, and *which effect* the five DSP slots 0x61/0x63/0x64/0x65/0x66 drive.

QUESTION ANSWERED
-----------------
`docs/kn-disk-file-formats.md` ended with:

    Still unidentified, stated plainly: `0x9A` is touched by nothing but the generic init
    walk.  `0x68 0x43 0x71 0x44 0x45 0x46` have known shapes but no distinguishing routine.
    Which effect `0x61/0x65/0x66` drive is unsettled.

This probe settles the effect slots outright, identifies 0x43, refutes one half of the
0x9A claim and confirms the other half, and reports the rest as still open.  Every test
below is stated so that it can come out negative, and each is run against v7, v9 and v10.

THE SEVEN TESTS
---------------
T1  SLOT -> TAG.  A 5-byte ROM table `61 63 65 66 64 FF` (v7/v9/v10: 0x00EE636C) is read by
    `DSPCfg_WriteAllSlots_Direct` as `lda XBC,0xee636c / add XBC,slot / ld A,(XBC)`, and the
    byte it fetches is the TAG handed to `AssswbWr`.  PASS = the table is present exactly
    once per ROM and each of its five bytes is a schema tag whose payload is 24 bytes long.
    FAIL if the byte string moves, repeats, or names a record of another size.

T2  TAG -> (PARAMETER NAMESPACE, SLOT).  `DSPCfg_Data_ParamDispatch` computes `tag - 0x61`,
    bounds it to 0..5 and jumps through a 6-entry u16 offset table into six arms, each
    `ld XIZ,0x00004N00 / ... / lds WA,<slot>`.  PASS = the six arms are found by byte
    pattern, exactly once per ROM, and decode to
        61->0x4900 slot 0 | 62->0x4A00 slot 1 | 63->0x4B00 slot 1
        64->0x4C00 slot 4 | 65->0x4D00 slot 2 | 66->0x4E00 slot 3
    FAIL on any other namespace or slot.  (0x62 has no panel record; it shares slot 1.)

T3  WHICH ALGORITHMS EACH SLOT ACCEPTS.  `DSPCfg_SlotAcceptsAlgorithm` (v9/v10 0x00FDC883,
    v7 0x00FDC10A-0x58) takes WA = record byte 0 and BC = slot and returns HL = 0 for
    ACCEPT.  Its per-slot arms are a chain of `cp WA,imm16`.  PASS = the fingerprint of the
    slot-2/3/4 arms occurs exactly once per ROM and the immediates are 0x39/0x3C, 0x58/0x5B
    and 0x4F.  FAIL if the numbers move.

T4  THE ALGORITHM NAMES.  The effect-name table is 18-byte fields at BASE - 18n, BASE
    located by requiring name(79) == 'GEQ'.  PASS = names 9, 10, 16..27, 57..60, 79, 88..91
    are the documented ones.  This is what turns T3's numbers into English.
    A second, arithmetic gate rides on it.  The routine's common precondition is
    `algo <= 0x63 && u32[0x00EE75F6 + 4*algo] != 0` (59 of 100 entries are non-null), and
    slot 0's arm only excludes the reverbs -- so slot 0 also lets through the nine
    algorithms slots 2/3/4 own.  PASS = slot 0 accepts 47 named algorithms, the union of
    slots 2/3/4 is exactly 9, and 47 - 9 == 38, the DSP EFFECT page count that
    `docs/effects-dsp.md` arrived at from the Sub-CPU side.  FAIL on any other arithmetic.

T5  CORPUS GATE (the falsifiable one).  If byte 0 of a slot record really is the algorithm
    number, then in the seven real `.LSW` floppies EVERY tag-0x61 record's byte 0 must
    satisfy slot 0's predicate from T3 and EVERY tag-0x63 record's byte 0 must satisfy
    slot 1's.  These two predicates are disjoint over the reverb range, so a mix-up would
    show.  PASS = 100% on both.  Needs the extracted floppies; skipped without them.

T6  PARAMETER-ID DESCRIPTORS.  A ROM descriptor is `u32 param-id | u8 tag | u8 offset |
    u16 mask | u8 max | u8 shift | ...`.  Scanning the whole image for ids in 0x4000..0x4FFF
    whose (tag, offset) is inside the schema yields a small, consistent map.  PASS = the six
    entries this probe's conclusions rest on are present and unique:
        0x4002 -> tag 0x60 +1 mask 0x80    0x4140 -> tag 0x43 +0 mask 0x80
        0x4004 -> tag 0x60 +1 mask 0x40    0x4141 -> tag 0x43 +1 mask 0x7F
        0x4006 -> tag 0x60 +1 mask 0x20    0x4142 -> tag 0x43 +1 mask 0x80
    and the 9-cell screen table at 0x00E34750 reads
        4141 - - 4140 4E00 4E10 4E11 4E12 4E13.

T7  TAG 0x9A.  Four separate checks, see the RESULTS section.

WHAT THIS PRODUCED (2026-08-22; v7 / v9 / v10 identical unless stated)
---------------------------------------------------------------------
SLOT TABLE 0x00EE636C = `61 63 65 66 64 FF`, so slot0=0x61 slot1=0x63 slot2=0x65
slot3=0x66 slot4=0x64 -- the order the older note asserted, now with its ROM artefact.

*** WHICH EFFECT EACH SLOT DRIVES, from T3+T4 ***

  slot 0  tag 0x61  ns 0x4900  47 named, everything EXCEPT 16..27
                               = the 38 DSP EFFECT algorithms + the 9 of slots 2/3/4
  slot 1  tag 0x63  ns 0x4B00  14 named: {9,10} + 16..27
                               = SINGLE DELAY, MULTI TAP DELAY and the twelve reverbs
                               = the DIGITAL REVERB page (12 reverbs + 2 delays)
  slot 2  tag 0x65  ns 0x4D00  4 named: 57..60
                               = STANDARD / PERCUSSIVE / SYMPHONIC / DEEP SPACE
                               = ACOUSTIC ILLUSION
  slot 3  tag 0x66  ns 0x4E00  4 named: 88..91
                               = ROOM / KARAOKE / BATH ROOM / STAGE
  slot 4  tag 0x64  ns 0x4C00  1 named: 79 = GEQ = the master EQUALIZER

  Slot 0's arm is a NEGATIVE rule ("not a reverb"), so the validator is wider than the page:
  it also passes the nine algorithms slots 2/3/4 own.  47 - 9 = 38 exactly.

  Cross-check that was NOT used to derive the above: `docs/effects-dsp.md` records, from the
  Sub CPU side, that nine effect numbers are IC310 (MN19413) programs -- 57,58,59,60,79,
  88,89,90,91 -- that the slot->chip table at Sub-CPU 0x01ED6D is `0,0,1,1,1`, and that the
  DSP EFFECT page offers 38 types.  The union of slots 2,3,4 above is exactly those nine
  numbers, slots 0 and 1 are exactly the IC311 ones, and the leftover is exactly 38.  Three
  independent agreements between two derivations that share no code path.

  Byte 0 of a slot record IS the algorithm number: the ROM reverb-preset table at 0xEDB36C
  and EQ-preset table at 0xEDB394 are 24-byte blobs copied straight to 0xFC8E (tag 0x63)
  and 0xFCA8 (tag 0x64), and their byte 0 reads 16..27 and 79 respectively.

  T5 on the seven floppies: 175/175 tag-0x61 records legal for slot 0 and 175/175 tag-0x63
  records legal for slot 1, zero violations, and the two byte-0 sets are disjoint --
        tag 0x61: 01 05 06 09 21 23 34 36 42 44 50   (all outside 0x10..0x1B)
        tag 0x63: 14 15 18 19                        (all inside  0x10..0x1B)
  A single misassignment of the two predicates would have produced 175 violations.

*** THE SLOT ON/OFF SWITCHES (T6) ***  The notify ids 0x4002 and 0x4006 that the older note
  recorded beside the 0x63 and 0x64 send loops are not slot ids at all -- they are the
  slots' ON/OFF bits, and the descriptor table says where they live:
        0x4002 = tag 0x60 payload+1 bit 7  -> slot 1 (REVERB)
        0x4004 = tag 0x60 payload+1 bit 6  -> slot 2 (ACOUSTIC ILLUSION)
        0x4006 = tag 0x60 payload+1 bit 5  -> slot 4 (EQUALIZER)
        0x4140 = tag 0x43 payload+0 bit 7  -> slot 3
  Independent corroboration: `BitMapOut_RestoreExtra_*` restores 0xFC6F bit 0x40 together
  with the whole tag-0x65 record, bit 0x20 together with tag 0x64, and tag 0x43 together
  with tag 0x66.  The grouping and the descriptor table were derived separately and agree
  on all three.

*** TAG 0x43 -- IDENTIFIED ***  Three parameters, all in one 9-cell screen (0x00E34750)
  together with slot 3's algorithm and its four values:
        +0 bit 7  = 0x4140, an on/off      (also slot 3's enable)
        +1 mask 7F= 0x4141, a 0..127 level, printed with "%3d"
        +1 bit 7  = 0x4142, a second on/off
  Slot 3's algorithms are ROOM / KARAOKE / BATH ROOM / STAGE and the only KN5000 page title
  pairing a level with a reverb is `MIC LEVEL & REVERB` (0x00ED128C).  So 0x43 is the
  MICROPHONE record and 0x66 its reverb.  [INFERENCE] on the word "microphone" -- the
  on/off + level + those four ambience names is what carries it; no routine says "MIC".

*** TAG 0x9A -- the old claim is HALF WRONG AND HALF RIGHT ***
  WRONG: it is not "touched by nothing".  It has a live subscriber list, and the handler is
  specific to it: it accepts payload offsets 4..19 only, maps each through the RAM byte
  array at 0x00F1A0 and then through the ROM class table at 0x00EE8EA2, and forwards only
  when that class is 0, 1 or 2.  So sixteen of the record's twenty-six bytes are live UI
  fields, one per entry of the 0xF1A0 array.
  And the split is exact: the schema's field descriptors for 0x9A declare offsets 0..3 and
  20..25 -- precisely the ten bytes the subscriber refuses.  Descriptors and handler tile
  the record with no gap and no overlap.
  RIGHT: no instruction anywhere reads or writes it by address.  Across v7, v9, v10, the
  table-data ROM, the v142 sub-program and the sub-CPU boot ROM the census finds 1, 1, 1,
  2, 1 and 0 F1/F2 direct-address candidates landing in 0x9A.  Every one but a single named
  exception is the same four bytes `.. f1 b0 ff` -- the tail of `cp XBC,XWA` plus `ret NC`
  inside a busy-wait loop, i.e. not an instruction start; the exception is a table-data
  interrupt vector, listed in CENSUS_EXCEPTIONS with its reason.  Nor does any parameter-id
  descriptor name tag 0x9A, while 20 other tags do (45 ids in all).
  THE CENSUS COULD HAVE FOUND ONE.  Positive control, same scan, same run: the tags 0x78,
  0x48 and 0x80 collect 267 (v7) / 268 (v9, v10) candidates.  A search returning 268 hits
  for three neighbouring records and 0 for this one is a search that works.
  ⚠ The control is weak in the OTHER images: the table-data ROM yields 0 control hits and
  the sub-program 1, so "absent from the sub CPU" rests on a scan with almost nothing to
  calibrate against there.  Stated rather than smoothed over.
  ⚠ And absolute addressing is not the only way in.  The generic tag->address table at
  0x00EDAE64 holds 0xFFA4 at index 0x9A, so the parameter machinery can reach the record
  with a computed pointer, exactly as the C0..D4 family is reached.  "No instruction names
  it" is the claim; "no code can touch it" is NOT.
  NOT SETTLED: who writes it.  Of the 131 `AssswbWr` / `AddswbWr` / `SwbtWr_QueuePostEvent`
  call sites in the v9 sources, 56 carry a literal tag in WA within ten lines (tags 00 04 44
  48 61 63 64 70 90 91 93 98 A8 B0) and none is 0x9A; the other 75 pass the tag in a
  register, so the search cannot exclude it there.  Saying "nothing posts 0x9A" would be a
  claim this method cannot support.

*** TAG 0x68 -- a declared-but-empty record ***  Its schema descriptor list is the bare
  terminator (no fields at all), no parameter id names it, its only absolute access is the
  bulk copy in `BitMapOut_CopyAuxTable_Loop`, and its UI subscriber is four `ret` bytes
  (0x0E 0x0E 0x0E 0x0E).  Ten bytes that the firmware saves, restores and ignores.

*** STILL OPEN, stated plainly ***
  0x71 -- two payload bytes, +0 masked 0x03.  Reached by `PmemOutLGridCheck` (the panel-
      memory grid) and `BitMapOut_Snapshot_PostProcess`; no parameter id, no naming routine.
  0x44 / 0x45 / 0x46 -- NOT identified.  What IS established: they carry no parameter-id
      descriptor, so they are not UI-editable; their event subscribers are identical; in all
      seven floppies all three are constant across every block and every disk, with 0x44 and
      0x45 BYTE-IDENTICAL (`00 00 00 88 80 80 00 00 00 00`) and 0x46 differing in one bit
      (`... 80 80 80 ...`); and `FDemoText_SyncPreset_DirectCopy` copies the byte at 0xFC74
      (tag 0x61 +0, the DSP-EFFECT algorithm) into 0xFC26 (tag 0x44 +0), after which
      `FDemoText_UpdateVoiceDisplay` compares the two and re-posts a tag-0x61 event when
      they differ -- so 0x44 +0 is a shadow of the DSP-effect algorithm.  No equivalent
      pairing was found for 0x45 or 0x46, and nothing was found that indexes the three as a
      group.  The 12-byte stride 0xFC24/0xFC30/0xFC3C is an invitation, not evidence.

    python3 analysis/disk-format-probes/lsw_leftover_records.py
    python3 analysis/disk-format-probes/lsw_leftover_records.py --lsw-dir /tmp/disk
    python3 analysis/disk-format-probes/lsw_leftover_records.py --quiet
"""
import argparse, glob, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
LOAD = 0xE00000
VERSIONS = ('v7', 'v9', 'v10')
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))

# --- signals, as byte patterns so they survive the v7/v9 address shift -------------------
SLOT_TO_TAG = bytes((0x61, 0x63, 0x65, 0x66, 0x64, 0xFF))
# DSPCfg_Data_ParamDispatch's six arms: ld XIZ,0x00004N00 ... lds WA,<slot>
NS_ARMS = ('46 00 49 00 00 d8 a8 68 .. 46 00 4a 00 00 68 .. 46 00 4b 00 00 d8 a9 68 .. '
           '46 00 4c 00 00 d8 ac 68 .. 46 00 4d 00 00 d8 aa 68 .. 46 00 4e 00 00 d8 ab')
# DSPCfg_SlotAcceptsAlgorithm, the slot 2 / 3 / 4 arms
SLOT_RANGES = ('d8 cf 39 00 67 .. d8 cf 3c 00 6b .. 68 .. '
               'd8 cf 58 00 67 .. d8 cf 5b 00 6b .. 68 .. d8 cf 4f 00 6e ..')
# the tag-0x9A subscriber: bound offset to 4..0x13, index RAM 0xF1A0, class-table 0xEE8EA2
SUB_9A = ('8f 01 21 c9 cf 13 6b .. c9 dc 67 .. 8f 01 21 c9 6c d8 12 f1 a0 f1 31 '
          'e8 12 e9 80 80 21 d8 12 f2 a2 8e ee 31')
BUSY_WAIT_TAIL = ('e8 f1 b0 ff', 'd8 f1 b0 ff')   # cp XBC,XWA / ret NC  and its WA twin
# The one candidate that is neither the busy-wait tail nor an instruction.  Named, with its
# reason, rather than tolerated -- a NEW disagreement still fails the run.
CENSUS_EXCEPTIONS = {
    ('table data', 0x9FFF54):
        'interrupt vector #21 of the table-data ROM (block 0x9FFF00, 45 entries, most of '
        'them 0x00FFB705).  Its value 0x00FFB7F2 is a handler address in the PRE-REMAP map, '
        'where 0x00FFxxxx is boot ROM and not panel DRAM, so its low half is not an address '
        'in the panel area at all.',
}

SCREEN_TABLE = 0x00E34750
SCREEN_CELLS = (0x4141, 0xFFFFFFFF, 0xFFFFFFFF, 0x4140, 0x4E00, 0x4E10, 0x4E11, 0x4E12, 0x4E13)
PARAM_EXPECT = {0x4002: (0x60, 1, 0x80), 0x4004: (0x60, 1, 0x40), 0x4006: (0x60, 1, 0x20),
                0x4140: (0x43, 0, 0x80), 0x4141: (0x43, 1, 0x7F), 0x4142: (0x43, 1, 0x80)}
NAME_EXPECT = {9: 'SINGLE DELAY', 10: 'MULTI TAP DELAY', 16: 'ROOM REVERB 1',
               27: 'WAVE REVERB 2', 57: 'STANDARD', 58: 'PERCUSSIVE', 59: 'SYMPHONIC',
               60: 'DEEP SPACE', 79: 'GEQ', 88: 'ROOM', 89: 'KARAOKE', 90: 'BATH ROOM',
               91: 'STAGE'}
SLOT_NS_SLOT = {0x61: (0x4900, 0), 0x62: (0x4A00, 1), 0x63: (0x4B00, 1),
                0x64: (0x4C00, 4), 0x65: (0x4D00, 2), 0x66: (0x4E00, 3)}

IMAGES = (('v7 program', 'kn5000_v7_program.rom', 0xE00000),
          ('v9 program', 'kn5000_v9_program.rom', 0xE00000),
          ('v10 program', 'kn5000_v10_program.rom', 0xE00000),
          ('table data', 'kn5000_table_data.rom', 0x800000),
          ('subprogram v142', 'kn5000_subprogram_v142.rom', 0x000000),
          ('subcpu boot', 'kn5000_subcpu_boot.ic30', 0x000000))


# ------------------------------------------------------------------ small helpers
def rom(name):
    return open(os.path.join(REPO, 'original_ROMs', name), 'rb').read()


def schema(d):
    """[(payload_start, tag, payload_len)] and the field-descriptor offsets per tag."""
    recs, fields = [], {}
    for addr, count, base in TABLES:
        for i in range(count):
            o = addr - LOAD + 10 * i
            eoff, fptr, tag, ln = struct.unpack_from('<IIBB', d, o)
            if tag == 0xFF:
                break
            recs.append((base + eoff + 2, tag, ln))
            fields[tag] = decode_fields(d, fptr)
    return recs, fields


def decode_fields(d, ptr):
    """Offsets a field descriptor list declares.  Entry sizes follow the schema probe."""
    o, out = ptr - LOAD, []
    for _ in range(64):
        t = d[o]
        if t == 0xFF:
            break
        if t == 8:
            out.append(d[o + 1]); o += 2
        elif t == 7:
            out.append(d[o + 1]); o += 3
        elif t in (0, 1, 2, 5, 6):
            out.append(d[o + 1]); o += 3
        elif t in (3, 4):
            out.append(d[o + 1]); o += 6
        else:
            return out
    return out


def locate(recs, a):
    for st, tag, ln in recs:
        if st - 2 <= a < st + ln:
            return tag, (a - st)
    return None


def wfind(d, pattern):
    """All offsets where a '..'-wildcarded hex byte pattern matches."""
    toks = pattern.split()
    fixed = [(i, int(t, 16)) for i, t in enumerate(toks) if t != '..']
    ai, ab = fixed[0]
    res, s = [], 0
    while True:
        i = d.find(bytes((ab,)), s)
        if i < 0:
            return res
        s = i + 1
        b = i - ai
        if b < 0 or b + len(toks) > len(d):
            continue
        if all(d[b + k] == v for k, v in fixed):
            res.append(b)


def find_all(d, pat):
    out, i = [], 0
    while True:
        i = d.find(pat, i)
        if i < 0:
            return out
        out.append(i)
        i += 1


# ------------------------------------------------------------------ T1..T4, T6, T7 on one ROM
def name_table(d):
    """(base, fn) for the 18-byte descending effect-name table; base pinned by GEQ==79."""
    i = d.find(b'      GEQ       ')
    if i < 0:
        return None, None
    base = LOAD + i + 18 * 79

    def nm(n):
        a = base - 18 * n - LOAD
        return d[a:a + 16].decode('latin1').strip()
    return base, nm


def param_descriptors(d, recs):
    """{param id: (tag, offset, mask, addr)} for ids 0x4000..0x4FFF landing in the schema."""
    lens = {tag: ln for _, tag, ln in recs}
    out = {}
    for i in range(len(d) - 18):
        pid = struct.unpack_from('<I', d, i)[0]
        if not (0x4000 <= pid < 0x5000):
            continue
        tag, off = d[i + 4], d[i + 5]
        mask = struct.unpack_from('<H', d, i + 6)[0]
        if tag not in lens or off >= lens[tag] or not 0 < mask <= 0xFF:
            continue
        out.setdefault(pid, []).append((tag, off, mask, LOAD + i))
    return out


def slot0(a):    return a < 0x10 or a > 0x1B
def slot1(a):    return a in (0x09, 0x0A) or 0x10 <= a <= 0x1B
SLOT_PRED = {0: slot0, 1: slot1, 2: lambda a: 0x39 <= a <= 0x3C,
             3: lambda a: 0x58 <= a <= 0x5B, 4: lambda a: a == 0x4F}
# the routine's common precondition, ahead of the per-slot arms:
#   cp WA,0x63 / jr UGT,fail  and  u32[PARAM_DESC_TABLE + 4*algo] != 0
PARAM_DESC_ENTRY = 'd8 cf 63 00 6b .. d8 8a ea 12 ea ee 02 43 .. .. .. 00'


def desc_table(d):
    """Address of the 100-entry parameter-descriptor pointer array, from the routine itself."""
    h = wfind(d, PARAM_DESC_ENTRY)
    if len(h) != 1:
        return None
    return struct.unpack_from('<I', d, h[0] + 14)[0]


def accepted(d, tbl, slot):
    """Algorithm numbers slot `slot` accepts, precondition included."""
    return [n for n in range(0x64)
            if struct.unpack_from('<I', d, tbl - LOAD + 4 * n)[0] and SLOT_PRED[slot](n)]


def run_version(ver, v):
    d = rom('kn5000_%s_program.rom' % ver)
    recs, fields = schema(d)
    ok = True
    print('######## %s ########' % ver)

    # ---- T1 slot -> tag
    hits = find_all(d, SLOT_TO_TAG)
    if len(hits) != 1:
        print('  T1 FAIL: `61 63 65 66 64 FF` occurs %d times, expected 1' % len(hits))
        ok = False
    else:
        addr = LOAD + hits[0]
        lens = {tag: ln for _, tag, ln in recs}
        bad = [t for t in SLOT_TO_TAG[:5] if lens.get(t) != 0x18]
        if bad:
            print('  T1 FAIL: tags %s are not 24-byte records' % bad)
            ok = False
        elif v:
            print('  T1 slot->tag table @%06X: %s'
                  % (addr, ' '.join('slot%d=0x%02X' % (i, t)
                                    for i, t in enumerate(SLOT_TO_TAG[:5]))))

    # ---- T2 tag -> namespace, slot
    hits = wfind(d, NS_ARMS)
    if len(hits) != 1:
        print('  T2 FAIL: the six ld XIZ,0x00004N00 arms occur %d times, expected 1' % len(hits))
        ok = False
    else:
        b = hits[0]
        got = {}
        o = b
        for tag in range(0x61, 0x67):
            ns = 0x4000 + (d[o + 2] - 0x40) * 0x100
            j, slot = o + 5, None
            while j < o + 18:
                if d[j] == 0xD8 and 0xA8 <= d[j + 1] <= 0xAC:
                    slot = d[j + 1] - 0xA8
                    break
                j += 1
            got[tag] = (ns, slot)
            n = d.find(b'\x46\x00', o + 2)
            o = n
        if got != SLOT_NS_SLOT:
            print('  T2 FAIL: decoded %s' % got)
            ok = False
        elif v:
            print('  T2 tag->namespace/slot @%06X: %s' % (LOAD + b, ' '.join(
                '%02X->%04X/s%d' % (t, got[t][0], got[t][1]) for t in sorted(got))))

    # ---- T3 which algorithms each slot accepts
    hits = wfind(d, SLOT_RANGES)
    if len(hits) != 1:
        print('  T3 FAIL: the slot-2/3/4 range arms occur %d times, expected 1' % len(hits))
        ok = False
    elif v:
        print('  T3 DSPCfg_SlotAcceptsAlgorithm arms @%06X: slot2 39..3C, slot3 58..5B, '
              'slot4 ==4F (slot0/slot1 use the 10..1B split)' % (LOAD + hits[0]))

    # ---- T4 names
    base, nm = name_table(d)
    if nm is None:
        print('  T4 FAIL: the effect-name table was not located')
        ok = False
    else:
        bad = [(n, NAME_EXPECT[n], nm(n)) for n in NAME_EXPECT if nm(n) != NAME_EXPECT[n]]
        if bad:
            print('  T4 FAIL: %s' % bad)
            ok = False
    tbl = desc_table(d)
    if tbl is None:
        print('  T3 FAIL: the routine entry / descriptor-table load was not found exactly once')
        ok = False
    elif nm is not None and v:
        print('  T4 name table @%06X - 18n; precondition table @%06X (%d of 100 non-null):'
              % (base, tbl, len(accepted(d, tbl, 0)) + len([n for n in range(0x10, 0x1C)
                 if struct.unpack_from('<I', d, tbl - LOAD + 4 * n)[0]])))
        for slot, tag in enumerate(SLOT_TO_TAG[:5]):
            acc = accepted(d, tbl, slot)
            named = [n for n in acc if nm(n) != '----------']
            shown = ', '.join(nm(n) for n in named[:6])
            print('      slot %d  tag 0x%02X  %2d accepted (%2d named)  %s%s'
                  % (slot, tag, len(acc), len(named), shown, ' ...' if len(named) > 6 else ''))
    if tbl is not None and nm is not None:
        # slot 0's arm only excludes the reverbs, so it also lets through the nine IC310
        # algorithms that slots 2/3/4 own.  Removing those must leave exactly the 38 entries
        # docs/effects-dsp.md counted on the DSP EFFECT page, from a completely different route.
        ic310 = set(accepted(d, tbl, 2)) | set(accepted(d, tbl, 3)) | set(accepted(d, tbl, 4))
        s0 = [n for n in accepted(d, tbl, 0) if nm(n) != '----------']
        rest = [n for n in s0 if n not in ic310]
        if len(ic310) != 9 or len(rest) != 38:
            print('  T4 FAIL: slot0 named minus the IC310 set is %d, expected 38 (IC310 set %d)'
                  % (len(rest), len(ic310)))
            ok = False
        elif v:
            print('      slot 0 accepts %d named, of which %d are the IC310 algorithms owned '
                  'by slots 2/3/4; the remaining %d are the DSP EFFECT page'
                  % (len(s0), len(ic310), len(rest)))

    # ---- T6 parameter descriptors
    pd = param_descriptors(d, recs)
    miss = []
    for pid, exp in PARAM_EXPECT.items():
        got = [x[:3] for x in pd.get(pid, [])]
        if exp not in got:
            miss.append((pid, exp, got))
    if miss:
        print('  T6 FAIL: %s' % miss)
        ok = False
    elif v:
        print('  T6 param descriptors: %s'
              % '  '.join('%04X=tag%02X+%d/%02X' % ((p,) + PARAM_EXPECT[p])
                          for p in sorted(PARAM_EXPECT)))
        print('      %d distinct param ids resolve onto %d schema tags'
              % (len(pd), len({t for e in pd.values() for t, _, _, _ in e})))
    cells = tuple(struct.unpack_from('<I', d, SCREEN_TABLE - LOAD + 4 * k)[0] for k in range(9))
    if cells != SCREEN_CELLS:
        print('  T6 FAIL: screen table @%06X reads %s' % (SCREEN_TABLE, [hex(c) for c in cells]))
        ok = False
    elif v:
        print('      screen @%06X = %s' % (SCREEN_TABLE,
                                           ' '.join('-' if c > 0xFFFF else '%04X' % c
                                                    for c in cells)))

    # ---- T7 tag 0x9A
    hits = wfind(d, SUB_9A)
    if len(hits) != 1:
        print('  T7 FAIL: the tag-0x9A subscriber body occurs %d times, expected 1' % len(hits))
        ok = False
    else:
        h = LOAD + hits[0]
        declared = sorted(fields[0x9A])
        window = list(range(4, 0x14))
        ln = {tag: l for _, tag, l in recs}[0x9A]
        if sorted(declared + window) != list(range(ln)):
            print('  T7 FAIL: descriptors %s and handler window 4..19 do not tile 0..%d'
                  % (declared, ln - 1))
            ok = False
        elif v:
            print('  T7 tag 0x9A subscriber body @%06X accepts payload offsets 4..19;'
                  % (h - 0x16))
            print('      descriptors declare %s -- together they tile 0..%d exactly'
                  % (' '.join(str(x) for x in declared), ln - 1))
    if 0x9A in {t for e in pd.values() for t, _, _, _ in e}:
        print('  T7 FAIL: a parameter id now names tag 0x9A')
        ok = False
    elif v:
        print('      no parameter id names tag 0x9A (20 other tags have one)')
    return ok


# ------------------------------------------------------------------ T7 census over all images
def census_9a(v):
    """Every F1/F2 direct-address operand landing in tag 0x9A, in every dumped image."""
    d0 = rom('kn5000_v7_program.rom')
    recs, _ = schema(d0)
    rng = [(st - 2, st + ln) for st, tag, ln in recs if tag == 0x9A][0]
    ok, controls = True, {}
    for label, fname, base in IMAGES:
        d = rom(fname)
        cand, aligned = [], []
        for i in range(len(d) - 4):
            if d[i] == 0xF1:
                a = d[i + 1] | d[i + 2] << 8
            elif d[i] == 0xF2 and d[i + 3] == 0x00:
                a = d[i + 1] | d[i + 2] << 8
            else:
                continue
            if rng[0] <= a < rng[1]:
                cand.append((base + i, a, d[i - 1:i + 3].hex(' ')))
            hit = locate(recs, a)
            if hit and hit[0] in (0x78, 0x48, 0x80):
                controls.setdefault(label, []).append(hit[0])
        for a, val, ctx in cand:
            if (label, a) in CENSUS_EXCEPTIONS:
                if v:
                    print('    %-16s %06X -> %04X   NAMED EXCEPTION: %s'
                          % (label, a, val, CENSUS_EXCEPTIONS[(label, a)]))
            elif ctx not in BUSY_WAIT_TAIL:
                print('    FAIL %s %06X -> %04X context `%s` is NOT the busy-wait tail'
                      % (label, a, val, ctx))
                ok = False
            elif v:
                print('    %-16s %06X -> %04X   `%s` = cp XBC,XWA / ret NC, mid-instruction'
                      % (label, a, val, ctx))
        if v:
            print('    %-16s %d candidate(s) in tag 0x9A; %d in the control tags 78/48/80'
                  % (label, len(cand), len(controls.get(label, []))))
    return ok


# ------------------------------------------------------------------ T5 corpus gate
def corpus_gate(paths, v):
    tot = {0x61: 0, 0x63: 0}
    bad = {0x61: 0, 0x63: 0}
    seen = {0x61: set(), 0x63: set()}
    for p in paths:
        data = open(p, 'rb').read()
        q, blk = 0x20, 0
        while q + 1 < len(data) and blk < 26:
            tag, ln = data[q], data[q + 1]
            if tag == 0xFF and ln == 0xFF:
                blk += 1
                q += 2
                continue
            if tag in (0x61, 0x63) and ln:
                slot = 0 if tag == 0x61 else 1
                tot[tag] += 1
                seen[tag].add(data[q + 2])
                if not SLOT_PRED[slot](data[q + 2]):
                    bad[tag] += 1
            q += 2 + ln
    for tag, slot in ((0x61, 0), (0x63, 1)):
        print('  T5 tag %02X (slot %d): %d records, %d violating slot %d\'s predicate; '
              'byte-0 values seen: %s'
              % (tag, slot, tot[tag], bad[tag], slot,
                 ' '.join('%02X' % x for x in sorted(seen[tag]))))
    if seen[0x61] & seen[0x63]:
        print('  T5 NOTE: the two byte-0 sets overlap on %s' % sorted(seen[0x61] & seen[0x63]))
    return not (bad[0x61] or bad[0x63]) and tot[0x61] and tot[0x63]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    ap.add_argument('--lsw-dir', default='/tmp/disk',
                    help='directory searched recursively for *.LSW (T5); skipped if empty')
    args = ap.parse_args()
    v = not args.quiet
    ok = True
    for ver in VERSIONS:
        ok &= run_version(ver, v)
        print()
    print('######## tag 0x9A: whole-image direct-address census ########')
    ok &= census_9a(v)
    print()
    paths = sorted(glob.glob(os.path.join(args.lsw_dir, '**', '*.LSW'), recursive=True))
    if paths:
        print('######## T5 corpus gate: %d .LSW file(s) ########' % len(paths))
        ok &= corpus_gate(paths, v)
    else:
        print('######## T5 skipped: no *.LSW under %s ########' % args.lsw_dir)
    print()
    print('PASS: slot->tag, tag->namespace/slot, the per-slot algorithm ranges, the names, '
          'the slot on/off descriptors and the tag-0x9A split all hold.' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
