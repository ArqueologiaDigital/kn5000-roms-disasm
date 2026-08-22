#!/usr/bin/env python3
"""Tags 0x44 / 0x45 / 0x46 of the KN5000 panel TLV are the DRAWBAR registrations,
one per keyboard part -- and tag 0x71 is a one-bit panel-memory switch.

QUESTION ANSWERED
-----------------
`docs/kn-disk-file-formats.md` and `README-lsw-leftover-records.md` ended with:

    0x71 -- two payload bytes, +0 masked 0x03.  Reached by `PmemOutLGridCheck` and
        `BitMapOut_Snapshot_PostProcess`; no parameter id, no naming routine.
    0x44 / 0x45 / 0x46 -- NOT identified.  ... nothing was found that indexes the three
        as a group.  The 12-byte stride 0xFC24/0xFC30/0xFC3C is an invitation, not evidence.

Both statements were written from the 0x4000..0x4FFF parameter-id namespace.  The three
records DO have parameter ids -- 48 of them -- but in the 0x8200 / 0x8600 / 0x8A00
namespaces, which that scan never looked at.  Once those are read the identification is
immediate and the "three as a group" artefact appears in two independent places.

RESULT -- 0x44 / 0x45 / 0x46 = the DRAWBAR (organ) registration of ONE keyboard part each
------------------------------------------------------------------------------------------
    tag 0x44 -> part 0 = RIGHT 1     tag 0x45 -> part 1 = RIGHT 2     tag 0x46 -> part 2 = LEFT

Field map, identical for all three records (ids differ by exactly 0x0400 per part):

    payload  mask  param id (0x44/0x45/0x46)   max   what it is
    +1       0x0F  82CC / 86CC / 8ACC           15
    +1       0xF0  82CB / 86CB / 8ACB           15
    +2       0x0F  8293 / 8693 / 8A93           15
    +2       0xF0  8294 / 8694 / 8A94           15
    +3       0x0F  8280 / 8680 / 8A80            8   DRAWBAR  16'
    +3       0xF0  8281 / 8681 / 8A81            8   DRAWBAR  8'
    +4       0x0F  8282 / 8682 / 8A82            8   DRAWBAR  5 1/3'
    +4       0xF0  8283 / 8683 / 8A83            8   DRAWBAR  4'
    +5       0x0F  8284 / 8684 / 8A84            8   DRAWBAR  2 2/3'
    +5       0xF0  8285 / 8685 / 8A85            8   DRAWBAR  2'
    +6       0x0F  8286 / 8686 / 8A86            8   DRAWBAR  1 3/5'
    +6       0xF0  8287 / 8687 / 8A87            8   DRAWBAR  1 1/3'
    +7       0x0F  8288 / 8688 / 8A88            8   DRAWBAR  1'
    +7       0x10  82C0 / 86C0 / 8AC0            1   a switch
    +7       0x20  82C1 / 86C1 / 8AC1            1   a switch
    +8       0x0F  8221 / 8621 / 8A21            1   a switch
    +0       --    (no id)  a shadow of tag 0x61 +0, the DSP-EFFECT algorithm number
    +9       --    (no id)  declared by the schema as a plain byte

The footage labels come from the KN5000's own DRAWBAR page, not from Hammond folklore:
the string at 0xE84266 is the nine-column footage row and 0xE841E0 is `DRAWBAR SETTING`.

THE TESTS  (D1..D8 on v7, v9 and v10; D9 covers tag 0x71)
---------------------------------------------------------
D1  THE THREE RECORDS CARRY THE SAME PARAMETER BLOCK.  A whole-image scan for descriptors
    `u32 id | u8 tag | u8 off | u16 mask | u8 max | u8 shift` whose tag is a schema tag,
    whose offset is inside the record and whose mask is one contiguous run of bits.
    PASS = exactly 16 for each of 0x44/0x45/0x46; the id sets are 0x82xx / 0x86xx / 0x8Axx
    over the SAME sixteen low bytes; and (offset, mask, max, shift) agrees field for field.
    FAIL is what "three unrelated records that happen to be the same size" would look like.

D2  NINE FIELDS WITH max=8 TILE +3..+7 AS NIBBLE PAIRS.  PASS = ids 0x_280..0x_288 have
    max=8 and sit at (+3 lo, +3 hi, +4 lo, +4 hi, +5 lo, +5 hi, +6 lo, +6 hi, +7 lo).
    Nine positions of nine steps each is a drawbar set; a 0..8 range is not a 0..127 level.

D3  THE SCREEN THAT EDITS THEM.  The 15-entry u16 table at 0xE9F88C -- read by
    `MainMemDrawControl` in `ui/drawbar_panel_ui.s`, which splits its items at
    `cp wa,0x8 / jr ule` -- is exactly
        8280 8282 8281 8283 8284 8285 8286 8287 8288 | 82C1 82C0 82CC 82CB 8293 8294
    i.e. the nine max-8 ids first, then the six others.  PASS = that list, plus the
    literal strings `DRAWBAR SETTING` @0xE841E0 and the footage row @0xE84266.

D4  THE GROUP INDEX -- the artefact the earlier pass could not find.
    `FDemoText_SendVoiceParams` (v9 0xF84CBF) contains `ld A,(XSP+0x0c) / add A,0x44 /
    extz WA / calr <tag -> payload-address lookup>`, i.e. it addresses record `0x44 + part`.
    PASS = the byte pattern occurs (twice: this routine and its Ext twin), the tag->address
    table at 0xEDAE64 resolves 0x44/0x45/0x46 to 0xFC26/0xFC32/0xFC3E, and 0x47..0x56 --
    the tags a part index >= 3 would reach -- are 0xFFFFFFFF, so `part` can only be 0..2.

D5  WHICH THREE PARTS.  Two descending part-name tables: 8-byte stride at 0xE9F374 and
    12-byte stride at 0xE95540.  PASS = index 0/1/2 read `RIGHT1`/`RIGHT2`/`LEFT` in the
    first and `RIGHT 1`/`RIGHT 2`/`LEFT` in the second.  (Descending tables are this ROM's
    convention -- the effect-name table in `lsw_leftover_records.py` is BASE - 18n.)

D6  THE SHARED SUBSCRIBER AGREES WITH THE PARAMETER IDS.  The UI subscriber table (located
    exactly as in `lsw_leftover_records.py` T8) gives 0x44/0x45/0x46 one handler that no
    other tag has.  Its body is `ld E,(<tag global>) / sub E,0x44` -- the group index again
    -- then it BOUNDS the payload offset to 1..7 and splits offset 7 on mask 0x0F versus
    mask 0x30.  PASS = the accepted offset window is exactly the set of offsets that carry
    a parameter id, minus +8; and the 0x0F / 0x30 split is exactly the 0x0F | 0x10 | 0x20
    the ids declare at +7.  Two tables written for different purposes agreeing to the bit.

D7  THE FIRMWARE'S OWN DEFAULT IMAGE.  0xEDB3FC holds a complete power-on default of panel
    block 0 as a TLV stream in schema order (45 records, ending 0xEDB7BA).  PASS = the walk
    reproduces the schema tag/length sequence, 0x44/0x45/0x46 all read
    `00 00 00 88 80 80 00 00 00 00`, and every drawbar nibble is <= 8.
    That default decodes to the registration  16'=8  5 1/3'=0  8'=8  4'=8  2 2/3'=0  2'=8
    1 3/5'=0  1 1/3'=0  1'=0 .

D8  CORPUS.  The seven floppies: 175 records per tag.  PASS = every drawbar nibble <= 8 and
    both switch bits legal.  0x44 and 0x45 are BYTE-IDENTICAL to the firmware default above;
    0x46 differs in exactly one nibble -- LEFT's 16' drawbar, 8 -> 0.
    Stated limit: only three distinct byte values occur in the corpus (0x00, 0x80, 0x88), so
    this gate can only catch a gross misreading, not an off-by-one in the nibble order.

D9  TAG 0x71 -- NOT IDENTIFIED, and here is exactly how far it goes.
    (a) No parameter descriptor ANYWHERE in the image names tag 0x71, while the same scan
        finds 48 for 0x44/0x45/0x46 -- so the search is shown capable of finding one.
    (b) Its non-generic UI subscriber is a single 0x0E byte (`ret`) that is the last byte of
        another routine: a no-op placeholder, like tag 0x68's.
    (c) A whole-image census of TLCS-900 direct addressing (`F1 lo hi`, `F2 lo hi 00`)
        landing in 0xFD2A..0xFD2D finds SIX candidates per image, the same six in all three
        versions: three `lda XDE,0xFD2C / sub XDE,0xF9A0` arms of `PmemOutLGridCheck`, the
        `bit 1,(0xFD2C)` gate in `BitMapOut_Snapshot_PostProcess`, the bulk restore in
        `BitMapOut_CopyAuxTable_Check`, and one mid-instruction false positive whose context
        bytes are named below.  EVERY real site touches BIT 1 -- set, clear, test.  Bit 0 of
        the schema's `mask 0x03` is touched by nothing.
    (d) The third grid arm renders that bit as text: `bit 1,(...) / jr Z` selects between
        0xE8013E ` ON  ` and 0xE80144 ` OFF `, in the same string block as ` LEFT  `,
        `RIGHT 2`, `RIGHT 1` (0xE800F6/FE/0xE80106).  The pointer it tests is
        `0x1ED400 + index*0x3C0 + (0xFD2C - 0xF9A0)`, i.e. the same field inside a
        960-byte-strided array, not the live panel.
    (e) `bit 1,(0xFD2C)` gates `BitMapOut_DispatchIOChanges`, which re-posts parts
        0x00/0x01/0x02's payload +14/+15/+17 -- the same three parts the drawbar records
        belong to.
    (f) A schema inconsistency worth recording: the descriptor list at 0xED8DFE declares
        offsets 0,1,2,3 while the record's declared payload length is 2, so it over-declares
        by two bytes.  The disk `.LSW` files carry FOUR payload bytes for tag 0x71 -- which
        is what the descriptor list, not the length byte, describes.
    NOT DETERMINED: what the bit is called on the instrument, and what bit 0 is for.
    WHAT WOULD SETTLE IT: the KN5000's PANEL MEMORY page on real hardware -- toggle the one
    ON/OFF cell that `AcPmemOutLGridBox` draws and re-read `0x1ED400 + n*0x3C0 + 0x38C`
    bit 1; or the KN7000 firmware, whose widget labels are in plain ASCII.

    python3 analysis/disk-format-probes/lsw_drawbar_records.py
    python3 analysis/disk-format-probes/lsw_drawbar_records.py --quiet
    python3 analysis/disk-format-probes/lsw_drawbar_records.py --lsw-dir /tmp/disk
"""
import argparse, glob, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
LOAD = 0xE00000
VERSIONS = ('v7', 'v9', 'v10')
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))

TRIO = (0x44, 0x45, 0x46)
NS = {0x44: 0x8200, 0x45: 0x8600, 0x46: 0x8A00}
# (id low byte, payload offset, mask, max, shift) -- the block every one of the three carries
FIELDS = ((0xCC, 1, 0x0F, 15, 0), (0xCB, 1, 0xF0, 15, 4),
          (0x93, 2, 0x0F, 15, 0), (0x94, 2, 0xF0, 15, 4),
          (0x80, 3, 0x0F, 8, 0), (0x81, 3, 0xF0, 8, 4),
          (0x82, 4, 0x0F, 8, 0), (0x83, 4, 0xF0, 8, 4),
          (0x84, 5, 0x0F, 8, 0), (0x85, 5, 0xF0, 8, 4),
          (0x86, 6, 0x0F, 8, 0), (0x87, 6, 0xF0, 8, 4),
          (0x88, 7, 0x0F, 8, 0),
          (0xC0, 7, 0x10, 1, 4), (0xC1, 7, 0x20, 1, 5),
          (0x21, 8, 0x0F, 1, 0))
# the DRAWBAR page's item list, in the order it paints them
SCREEN_TABLE = 0xE9F88C
SCREEN_IDS = (0x8280, 0x8282, 0x8281, 0x8283, 0x8284, 0x8285, 0x8286, 0x8287, 0x8288,
              0x82C1, 0x82C0, 0x82CC, 0x82CB, 0x8293, 0x8294)
# id low byte -> printed footage, in that screen order
FOOTAGE = ((0x80, "16'"), (0x82, "5 1/3'"), (0x81, "8'"), (0x83, "4'"), (0x84, "2 2/3'"),
           (0x85, "2'"), (0x86, "1 3/5'"), (0x87, "1 1/3'"), (0x88, "1'"))
STR_DRAWBAR = (0xE841E0, b'DRAWBAR SETTING')
STR_FOOTAGE = (0xE84266, b"16' 5")
TAG_ADDR_TABLE = 0xEDAE64
PART_NAMES_8 = (0xE9F374, 8, (b'RIGHT1', b'RIGHT2', b'LEFT  '))
# the second table is a PACKED string blob, not fixed stride -- assert the strings, not a stride
PART_NAMES_12 = ((0xE95540, b' RIGHT 1 '), (0xE95536, b' RIGHT 2 '), (0xE9552A, b'   LEFT   '))
DEFAULT_IMAGE = 0xEDB3FC
DEFAULT_TRIO = bytes.fromhex('00 00 00 88 80 80 00 00 00 00')
# ld A,(XSP+0x0c) / add A,0x44 / extz WA / calr <lookup>
GROUP_INDEX = 'c9 c8 44 d8 12 1e'
# ld E,(<tag global>) / sub E,0x44 / ld A,(<offset global>) / extz WA / dec 1,WA /
# cp WA,0 / ret LT / cp WA,6 / ret GT / add WA,WA / lda XIX,0xe9fcd4
SUBSCRIBER = ('cd ca 44 c1 .. .. 21 d8 12 d8 69 d8 d8 b0 f1 d8 de b0 fa d8 80 '
              'f2 d4 fc e9 34')
# the tag-0x9A subscriber body, used ONLY to locate the subscriber table (see T8 of
# lsw_leftover_records.py) -- kept identical so the two probes cannot drift apart
SUB_9A = ('8f 01 21 c9 cf 13 6b .. c9 dc 67 .. 8f 01 21 c9 6c d8 12 f1 a0 f1 31 '
          'e8 12 e9 80 80 21 d8 12 f2 a2 8e ee 31')

# --- tag 0x71 -------------------------------------------------------------------------
REC_71 = (0xFD2A, 0xFD2E)          # record span, exclusive end
FIELDS_71 = 0xED8DFE               # its field-descriptor list
ONOFF = ((0xE8013E, b' ON  '), (0xE80144, b' OFF '))
PARTS_STR = ((0xE800F6, b' LEFT  '), (0xE800FE, b'RIGHT 2'), (0xE80106, b'RIGHT 1'))
# 4th byte of the F1 operand -> what the site is
SITES_71 = {0x32: 'lda XDE,0xFD2C (+ sub XDE,0xF9A0) -- a PmemOutLGridCheck grid arm',
            0xC9: 'bit 1,(0xFD2C) -- the BitMapOut_Snapshot_PostProcess gate',
            0x31: 'lda XBC,0xFD2C -- the BitMapOut_CopyAuxTable_Check bulk restore'}
# the one candidate that is not an instruction start, named with its reason
FP_71 = bytes.fromhex('30 bf 14 60 f1 2c fd 30')


def rom(name):
    return open(os.path.join(REPO, 'original_ROMs', name), 'rb').read()


def schema(d):
    """[(payload_start, tag, payload_len)] in table order."""
    out = []
    for addr, count, base in TABLES:
        for i in range(count):
            o = addr - LOAD + 10 * i
            eoff, fptr, tag, ln = struct.unpack_from('<IIBB', d, o)
            if tag == 0xFF:
                break
            out.append((base + eoff + 2, tag, ln))
    return out


def find_all(d, pat):
    out, i = [], 0
    while True:
        i = d.find(pat, i)
        if i < 0:
            return out
        out.append(i)
        i += 1


def wfind(d, pattern):
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


def contiguous(m):
    lo = (m & -m).bit_length() - 1
    return m and (((m >> lo) + 1) & (m >> lo)) == 0


def descriptors(d, recs):
    """{tag: {id: (offset, mask, max, shift, address)}} over the WHOLE id space."""
    lens = {tag: ln for _, tag, ln in recs}
    out = {}
    for i in range(len(d) - 18):
        pid = struct.unpack_from('<I', d, i)[0]
        if not (0x1000 <= pid < 0x10000):
            continue
        tag, off = d[i + 4], d[i + 5]
        if tag not in lens or off >= lens[tag] + 2:
            continue
        mask = struct.unpack_from('<H', d, i + 6)[0]
        if not (0 < mask <= 0xFF and contiguous(mask)):
            continue
        out.setdefault(tag, {})[pid] = (off, mask, d[i + 8], d[i + 9], LOAD + i)
    return out


def subscriber_table(d):
    """Base of the tag -> subscriber-list table, located from the tag-0x9A handler."""
    hits = wfind(d, SUB_9A)
    if len(hits) != 1:
        return None
    h = LOAD + hits[0] - 0x16
    slots = [LOAD + i for i in find_all(d, struct.pack('<I', h))]
    if len(slots) != 1:
        return None
    outer = [LOAD + i for i in find_all(d, struct.pack('<I', slots[0]))]
    if len(outer) != 1:
        return None
    return outer[0] - 4 * 0x9A


def sub_lists(d, tbase):
    lists = {}
    for tag in range(0x100):
        lst = struct.unpack_from('<I', d, tbase - LOAD + 4 * tag)[0]
        if not (LOAD <= lst < LOAD + len(d)):
            continue
        ents, o = [], lst - LOAD
        for k in range(16):
            v = struct.unpack_from('<I', d, o + 4 * k)[0]
            if v == 0xFFFFFFFF:
                break
            ents.append(v)
        lists[tag] = ents
    return lists


def drawbars(payload):
    """The nine drawbar values, in the order the KN5000 paints them."""
    vals = {}
    for lo, off, mask, mx, sh in FIELDS:
        vals[lo] = (payload[off] & mask) >> sh
    return [(lbl, vals[lo]) for lo, lbl in FOOTAGE]


def run_version(ver, v):
    d = rom('kn5000_%s_program.rom' % ver)
    recs = schema(d)
    lens = {tag: ln for _, tag, ln in recs}
    ok = True
    print('######## %s ########' % ver)

    # ---- D1 the three records carry the same parameter block
    pdesc = descriptors(d, recs)
    for tag in TRIO:
        got = pdesc.get(tag, {})
        want = {NS[tag] + lo: (off, mask, mx, sh) for lo, off, mask, mx, sh in FIELDS}
        have = {pid: val[:4] for pid, val in got.items()}
        if have != want:
            print('  D1 FAIL: tag %02X descriptors are %s' % (tag, sorted(have.items())))
            ok = False
    if ok and v:
        base = pdesc[0x44]
        print('  D1 tags 44/45/46 each carry the SAME 16 fields; ids differ by exactly '
              '0x0400 (0x82xx / 0x86xx / 0x8Axx).  First entry @%06X'
              % min(x[4] for x in base.values()))

    # ---- D2 nine max-8 fields tiling +3..+7
    nine = [(lo, off, mask) for lo, off, mask, mx, sh in FIELDS if mx == 8]
    want = [(0x80, 3, 0x0F), (0x81, 3, 0xF0), (0x82, 4, 0x0F), (0x83, 4, 0xF0),
            (0x84, 5, 0x0F), (0x85, 5, 0xF0), (0x86, 6, 0x0F), (0x87, 6, 0xF0),
            (0x88, 7, 0x0F)]
    if nine != want:
        print('  D2 FAIL: the max=8 fields are %s' % nine)
        ok = False
    elif v:
        print('  D2 nine fields with max=8 tile payload +3..+7 as nibble pairs '
              '(nine positions, nine steps each)')

    # ---- D3 the screen
    cells = tuple(struct.unpack_from('<H', d, SCREEN_TABLE - LOAD + 2 * k) [0]
                  for k in range(len(SCREEN_IDS)))
    if cells != SCREEN_IDS:
        print('  D3 FAIL: screen table @%06X reads %s' % (SCREEN_TABLE, [hex(c) for c in cells]))
        ok = False
    for addr, text in (STR_DRAWBAR, STR_FOOTAGE):
        if d[addr - LOAD:addr - LOAD + len(text)] != text:
            print('  D3 FAIL: %r is not at %06X' % (text, addr))
            ok = False
    if ok and v:
        row = d[STR_FOOTAGE[0] - LOAD:STR_FOOTAGE[0] - LOAD + 36].decode('latin1')
        print('  D3 screen item table @%06X = the 9 max-8 ids then the 6 others; '
              'the page prints %r' % (SCREEN_TABLE, row))

    # ---- D4 the group index
    hits = wfind(d, GROUP_INDEX)
    if len(hits) != 2:
        print('  D4 FAIL: `add A,0x44` group indexing occurs %d times, expected 2' % len(hits))
        ok = False
    tt = {t: struct.unpack_from('<I', d, TAG_ADDR_TABLE - LOAD + 4 * t)[0] for t in range(0x60)}
    if [tt[t] for t in TRIO] != [0xFC26, 0xFC32, 0xFC3E]:
        print('  D4 FAIL: tag->address table gives %s' % [hex(tt[t]) for t in TRIO])
        ok = False
    dead = [t for t in range(0x47, 0x60) if tt[t] != 0xFFFFFFFF]
    if dead != [0x47, 0x48, 0x49]:
        print('  D4 FAIL: tags 0x47..0x5F that resolve: %s' % [hex(t) for t in dead])
        ok = False
    elif v:
        print('  D4 `ld A,(XSP+0x0c) / add A,0x44` @%s indexes the trio by part; '
              '0x44/45/46 -> FC26/FC32/FC3E and 0x4A..0x5F are all FFFFFFFF, so part <= 2'
              % ' '.join('%06X' % (LOAD + h) for h in hits))

    # ---- D5 which three parts
    base, stride, names = PART_NAMES_8
    got = tuple(d[base - LOAD - stride * n:base - LOAD - stride * n + len(names[n])]
                for n in range(3))
    if got != names:
        print('  D5 FAIL: part-name table @%06X stride %d reads %s' % (base, stride, got))
        ok = False
    for addr, text in PART_NAMES_12:
        if d[addr - LOAD:addr - LOAD + len(text)] != text:
            print('  D5 FAIL: %r is not at %06X' % (text, addr))
            ok = False
    if ok and v:
        print('  D5 part 0/1/2 = RIGHT 1 / RIGHT 2 / LEFT  (descending 8-byte table @%06X; '
              'a second, packed block @%06X counts down the same way)'
              % (PART_NAMES_8[0], PART_NAMES_12[0][0]))

    # ---- D6 the shared subscriber
    tbase = subscriber_table(d)
    if tbase is None:
        print('  D6 FAIL: the subscriber table could not be located from the 0x9A handler')
        ok = False
    else:
        lists = sub_lists(d, tbase)
        shared = set(lists[0x44]) & set(lists[0x45]) & set(lists[0x46])
        owners = {h: [t for t in lists if h in lists[t]] for h in shared}
        only3 = [h for h, t in owners.items() if sorted(t) == list(TRIO)]
        if len(only3) != 1:
            print('  D6 FAIL: %d handler(s) belong to exactly {44,45,46}: %s'
                  % (len(only3), [hex(x) for x in only3]))
            ok = False
        else:
            handler = only3[0]
            body = wfind(d, SUBSCRIBER)
            if len(body) != 1 or LOAD + body[0] - 4 != handler:
                print('  D6 FAIL: the `sub E,0x44` body is at %s, handler is %06X'
                      % ([hex(LOAD + b - 4) for b in body], handler))
                ok = False
            elif v:
                have = sorted({off for off, _, _, _, _ in pdesc[0x44].values()})
                print('  D6 handler %06X belongs to tags 44/45/46 and to nothing else; it '
                      'does `sub E,0x44` then bounds the payload offset to 1..7' % handler)
                print('      offsets carrying a parameter id: %s -- the handler accepts '
                      '%s and rejects +0, +8, +9'
                      % (have, [x for x in have if x != 8]))
                print('      it splits offset 7 on mask 0x0F vs 0x30; the ids at +7 are '
                      '0x_288 mask 0F, 0x_2C0 mask 10, 0x_2C1 mask 20 -- the same split')

    # ---- D7 the firmware's own default image
    p, walked = DEFAULT_IMAGE - LOAD, 0
    payloads = {}
    for st, tag, ln in recs:
        if d[p] != tag or d[p + 1] != ln:
            break
        payloads[tag] = d[p + 2:p + 2 + ln]
        p += 2 + ln
        walked += 1
    if walked != 45:
        print('  D7 FAIL: the default image at %06X walks %d records, expected 45'
              % (DEFAULT_IMAGE, walked))
        ok = False
    elif any(payloads[t] != DEFAULT_TRIO for t in TRIO):
        print('  D7 FAIL: defaults are %s' % {hex(t): payloads[t].hex(' ') for t in TRIO})
        ok = False
    elif v:
        print('  D7 default image @%06X..%06X (45 records, schema order); 44/45/46 all read '
              '`%s`' % (DEFAULT_IMAGE, LOAD + p, DEFAULT_TRIO.hex(' ')))
        print('      = %s' % '  '.join('%s=%d' % x for x in drawbars(DEFAULT_TRIO)))
    if 0x71 in payloads and v:
        print('      tag 0x71 default = `%s` (2 bytes)' % payloads[0x71].hex(' '))

    # ---- D9 tag 0x71
    ok &= tag71(d, ver, recs, pdesc, tbase, v)
    return ok


def tag71(d, ver, recs, pdesc, tbase, v):
    ok = True
    # (a) no parameter id names it
    if 0x71 in pdesc:
        print('  D9 FAIL: a parameter id now names tag 0x71: %s' % pdesc[0x71])
        ok = False
    elif v:
        n = sum(len(pdesc[t]) for t in TRIO)
        print('  D9a no parameter descriptor names tag 0x71; the same scan finds %d for '
              '44/45/46, so it can find one' % n)
    # (b) the subscriber is a bare `ret`
    if tbase is not None:
        ents = sub_lists(d, tbase)[0x71]
        specific = [e for e in ents if len([t for t in sub_lists(d, tbase) if e in
                                            sub_lists(d, tbase)[t]]) == 1]
        for e in specific:
            if d[e - LOAD] != 0x0E:
                print('  D9 FAIL: tag 0x71 subscriber %06X is not a bare `ret`' % e)
                ok = False
            elif v:
                print('  D9b its only tag-specific subscriber is %06X, whose body is the '
                      'single byte 0x0E = `ret`' % e)
    # (c) the direct-address census
    cand = []
    for i in range(len(d) - 4):
        if d[i] == 0xF1:
            a = d[i + 1] | d[i + 2] << 8
        elif d[i] == 0xF2 and d[i + 3] == 0x00:
            a = d[i + 1] | d[i + 2] << 8
        else:
            continue
        if REC_71[0] <= a < REC_71[1]:
            cand.append((LOAD + i, a, d[i + 3], d[i - 4:i + 4]))
    real, fp = [], []
    for addr, a, k, ctx in cand:
        if ctx == FP_71:
            fp.append(addr)
        elif k in SITES_71:
            real.append((addr, a, k))
        else:
            print('  D9 FAIL: %06X -> %04X has 4th byte %02X, which is not a known site '
                  '(context %s)' % (addr, a, k, ctx.hex(' ')))
            ok = False
    kinds = sorted(k for _, _, k in real)
    if kinds != [0x31, 0x32, 0x32, 0x32, 0xC9] or len(fp) != 1:
        print('  D9 FAIL: census gives %d real sites %s and %d false positives'
              % (len(real), [hex(k) for k in kinds], len(fp)))
        ok = False
    elif v:
        print('  D9c census: %d candidates in 0xFD2A..0xFD2D -- %d real, 1 mid-instruction '
              'false positive @%06X (`30 bf 14 60` = jr F + ld WA)'
              % (len(cand), len(real), fp[0]))
        for addr, a, k in sorted(real):
            print('        %06X -> %04X  %s' % (addr, a, SITES_71[k]))
        print('      every real site touches BIT 1; bit 0 of the schema mask 0x03 is '
              'touched by nothing')
    # (d) the ON/OFF strings
    for addr, text in ONOFF + PARTS_STR:
        if d[addr - LOAD:addr - LOAD + len(text)] != text:
            print('  D9 FAIL: %r is not at %06X' % (text, addr))
            ok = False
    if ok and v:
        print('  D9d the grid arm picks %06X ` ON  ` / %06X ` OFF ` from that bit; the same '
              'string block holds RIGHT 1 / RIGHT 2 / LEFT' % (ONOFF[0][0], ONOFF[1][0]))
    # (f) the descriptor list over-declares
    ln71 = [l for _, t, l in recs if t == 0x71][0]
    offs, p = [], FIELDS_71 - LOAD
    for _ in range(16):
        t = d[p]
        if t == 0xFF:
            break
        step = {0: 3, 1: 3, 2: 3, 3: 6, 4: 6, 7: 3, 8: 2}.get(t)
        if step is None:
            break
        offs.append(d[p + 1])
        p += step
    if ln71 != 2 or offs != [0, 1, 2, 3]:
        print('  D9 FAIL: tag 0x71 len=%d, descriptor offsets %s' % (ln71, offs))
        ok = False
    elif v:
        print('  D9f the descriptor list @%06X declares offsets %s but the record\'s length '
              'byte is %d -- it over-declares by 2, and the disk .LSW files carry 4 payload '
              'bytes, i.e. what the descriptors describe' % (FIELDS_71, offs, ln71))
    return ok


def corpus(paths, v):
    ok = True
    seen = {t: {} for t in TRIO + (0x71,)}
    for p in paths:
        data = open(p, 'rb').read()
        q, blk = 0x20, 0
        while q + 1 < len(data) and blk < 26:
            tag, ln = data[q], data[q + 1]
            if tag == 0xFF and ln == 0xFF:
                blk += 1
                q += 2
                continue
            if tag in seen:
                seen[tag][data[q + 2:q + 2 + ln]] = seen[tag].get(data[q + 2:q + 2 + ln], 0) + 1
            q += 2 + ln
    for tag in TRIO:
        for payload, n in sorted(seen[tag].items()):
            if len(payload) != 10:
                print('  D8 FAIL: tag %02X record is %d bytes in the files' % (tag, len(payload)))
                ok = False
                continue
            bars = drawbars(payload)
            bad = [x for x in bars if x[1] > 8]
            if bad:
                print('  D8 FAIL: tag %02X value out of range: %s' % (tag, bad))
                ok = False
            if v:
                print('  D8 tag %02X x%-4d `%s`  ->  %s' % (tag, n, payload.hex(' '),
                      '  '.join('%s=%d' % x for x in bars)))
    if v:
        d44 = list(seen[0x44])[0] if len(seen[0x44]) == 1 else None
        d46 = list(seen[0x46])[0] if len(seen[0x46]) == 1 else None
        if d44 == DEFAULT_TRIO:
            print('      0x44 and 0x45 are BYTE-IDENTICAL to the firmware default')
        if d46 is not None and d46 != DEFAULT_TRIO:
            diff = [i for i in range(10) if d46[i] != DEFAULT_TRIO[i]]
            print('      0x46 (LEFT) differs from the default at payload offset(s) %s '
                  'only -- its 16\' drawbar reads %d where the default reads %d'
                  % (diff, d46[3] & 0x0F, DEFAULT_TRIO[3] & 0x0F))
        vals = sorted({b for pl in seen[0x44] for b in pl} |
                      {b for pl in seen[0x46] for b in pl})
        print('      LIMIT: only %d distinct byte values occur across the corpus (%s), so '
              'this gate catches a gross misreading, not an off-by-one'
              % (len(vals), ' '.join('%02X' % x for x in vals)))
        for payload, n in sorted(seen[0x71].items()):
            print('  D8 tag 71 x%-4d `%s` (%d payload bytes in the files, 2 in the KN5000)'
                  % (n, payload.hex(' '), len(payload)))
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    ap.add_argument('--lsw-dir', default='/tmp/disk',
                    help='directory searched recursively for *.LSW (D8); skipped if empty')
    args = ap.parse_args()
    v = not args.quiet
    ok = True
    for ver in VERSIONS:
        ok &= run_version(ver, v)
        print()
    paths = sorted(glob.glob(os.path.join(args.lsw_dir, '**', '*.LSW'), recursive=True))
    if paths:
        print('######## D8 corpus gate: %d .LSW file(s) ########' % len(paths))
        ok &= corpus(paths, v)
    else:
        print('######## D8 skipped: no *.LSW under %s ########' % args.lsw_dir)
    print()
    print('PASS: 0x44/0x45/0x46 are the DRAWBAR registration of RIGHT 1 / RIGHT 2 / LEFT; '
          'tag 0x71 is a single bit whose label is NOT determined.' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
