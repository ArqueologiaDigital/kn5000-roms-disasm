#!/usr/bin/env python3
"""The 2B / 2C parameter-access families: what the bytes after the model id mean.

QUESTION THIS ANSWERS
    `F0 50 2B 04 nn 11 ...` and `F0 50 2C 04 nn 11 ...` between them account for
    7512 of the 7542 sequences the grammar accepts.  Is that space a RULE
    ("byte 6 selects X, byte 7 selects Y") or 7512 unrelated literals?  Which
    internal command id does each terminate in, and what distinguishes 2B
    from 2C?

ANSWER, IN ONE LINE
    Bytes 6..8 are a 21-bit MSB-first septet ADDRESS, bytes 9..11 the matching
    21-bit BYTE COUNT; inside the parameter area (byte 6 = 0) byte 7 selects the
    area or the part and byte 8 the parameter inside it.  2C carries the value,
    2B asks for it and is answered with a 2C.

WHERE THE SIGNAL IS  (all prom_a addresses unless said otherwise)
  * ROOT record `0x2B` -> node 0xF5114F -> `04` -> node 0xF5113D; `0x2C` ->
    0xF50FC3 -> `04` -> 0xF50FB1.  Same record layout as
    sysex_grammar_dump.py documents.  ⚠ the depth-8 cap in that script's
    --paths hides the count triple; this script walks to the bottom.
  * A TERMINAL record's `next` pointer is NOT a node: 0xFB645F/0xFB647B read
    *(next) and *(next+1) into parse-record fields 1 and 2.  Field 1 is the
    GROUP, field 2 the INDEX.
  * GROUP dispatch: `dec 1,WA / cp wa,0x06 / jr ugt` at 0xFB34F1+ (cmd 0x18)
    and 0xFB42AB+ (cmd 0x1A) -> 7 arms, so group is 1..7 and 1-based.
  * Each arm bounds the INDEX (`cp A,<n> / jr nc`) and indexes a table of
    LE32 descriptor pointers.  The twelve tables TILE from 0xF51E8E to
    0xF5220E, alternating 2C-arm / 2B-arm per group -- that tiling is the
    last-entry test on all twelve bounds at once.
  * A descriptor's first six bytes are its own address triple + count triple
    (0xF51215 = `00 00 00 | 00 00 01`).  0xFB4DBC puts exactly those six
    bytes on the wire after the `F0 50 2C 04 00 11` header at prom_b
    0xF4FEF2 -- so the reply's header is the descriptor, verbatim.
  * The septet arithmetic is prom_b `Pack3x7BitFields_Bytes6To8` (0xF36849):
    `(b6&7F)<<14 | (b7&7F)<<7 | (b8&7F)`.
  * PART number: `sub A,0x20` on parse field 0x0A at 0xFB3969 and on the
    reply's own byte 7 at 0xFB4792.
  * DIRECTION: the cmd-0x18 (2C) arms reach descriptor+0x14, which calls
    sub_FB77F3 (0xFB77F3) -- that routine READS TWO BYTES off the message and
    returns `(b0<<4)|(b1&0x0F)`.  The cmd-0x1A (2B) arms reach descriptor+0x18,
    e.g. 0xFB4562, which READS THE INSTRUMENT (sub_FB7A02) and calls
    sub_FB4D62, the transmitter.  Third witness: the length check at
    0xFB6D5F admits only families 0x7E/0x2D/0x2C -- 2B is not length-checked
    because it has no data.
  * COUNT TRIPLE, the case the trie does not spell out: 0xFB6CA6 catches
    command ids 0x18 and 0x1A, tests parse field 0x0C for the untouched
    0xFF, then reads three bytes itself and requires their OR to be 1
    (0xFB6CE1); otherwise status 0x0E -> `ERROR 41!`.  So the triple is
    always on the wire, whatever the trie did or did not consume.
  * TRAILING FLAG: 0xFB6DE8 admits families 0x7E/0x2D/0x2C/0x2B, reads one
    byte that must be 0 or 1 (else status 0x12), stores it in field 0x0F, and
    only then checksums.  The reply builder emits it as the third byte of its
    data block, prefilled from prom_b 0xF4FA84 (`00 00 00`).

RUN
    python3 wsa1/notes/sysex-probes/sysex_param_space.py           # tables
    python3 wsa1/notes/sysex-probes/sysex_param_space.py --paths   # every sequence

PASS
    Every assert is silent and the script prints OK.  Headline numbers:
    3756 accepted sequences under EACH of 2B and 2C; command ids
    0x1A x3742 / 0x19 x6 / 0x1B,0x1C,0x1E,0x1F x2 for 2B and
    0x18 x3750 / 0x17 x6 for 2C; 32 part blocks of 57 parameters; the twelve
    descriptor tables tile 0xF51E8E..0xF5220E.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROM  = os.path.join(HERE, "..", "..", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
NULLREC = 0xF4FF61          # LinkTable_F4FF61 record 0, key 0xFFFF

rom = open(ROM, "rb").read()
def rd(a, n):
    o = a - BASE
    assert 0 <= o and o + n <= len(rom), "address outside prom_b"
    return rom[o:o + n]
def l32(a):
    return int.from_bytes(rd(a, 4), "little")

assert rd(0xF4FEB4, 5) == bytes([0xF0, 0x50, 0x23, 0x7E, 0xF7]), "wrong load base"
assert rd(0xF4FEF2, 6) == bytes([0xF0, 0x50, 0x2C, 0x04, 0x00, 0x11]), "2C reply header moved"
print("base check OK: prom_b loads at 0x%06X" % BASE)

# ---------------------------------------------------------------- the trie
def records(addr, limit=4096):
    out = []
    for i in range(limit):
        b = rd(addr + 6 * i, 6)
        out.append((b[0], b[1], int.from_bytes(b[2:6], "little")))
        if b[0] == 0xFF:
            break
    return out

def walk(p, prefix, out, depth=0):
    assert depth < 24, "trie deeper than any 2B/2C sequence -- re-check"
    for m, c, nx in records(p):
        if m == 0xFF:
            break
        pfx = prefix + [m]
        if c:                       # terminal: `next` is a 2-byte (group,index) key
            k = rd(nx, 2)
            out.append((pfx, c, k[0], k[1]))
        elif nx != NULLREC:
            walk(nx, pfx, out, depth + 1)

# root -> family -> `04` -> the subtree that starts at the device byte
ROOT = 0xF5115B
root = {m: nx for m, c, nx in records(ROOT, 15) if m != 0xFF}
assert root[0x2B] == 0xF5114F and root[0x2C] == 0xF50FC3, "root moved"
SUB = {}
for fam in (0x2B, 0x2C):
    recs = [r for r in records(root[fam]) if r[0] != 0xFF]
    assert len(recs) == 1 and recs[0][0] == 0x04, "byte 3 of %02X is no longer a fixed 04" % fam
    SUB[fam] = recs[0][2]
assert SUB[0x2B] == 0xF5113D and SUB[0x2C] == 0xF50FB1

PATHS = {}
for fam in (0x2B, 0x2C):
    out = []
    walk(SUB[fam], [], out)
    PATHS[fam] = out
    assert len(out) == 3756, "%02X: %d sequences, expected 3756" % (fam, len(out))

# device byte: only 00 and 01, and the two halves are byte-identical
for fam in (0x2B, 0x2C):
    half = {0: [], 1: []}
    for p, c, g, i in PATHS[fam]:
        assert p[0] in (0, 1), "device byte %02X accepted" % p[0]
        assert p[1] == 0x11, "model id is not 0x11"
        half[p[0]].append((tuple(p[1:]), c, g, i))
    assert half[0] == half[1], "%02X: device 00 and 01 subtrees differ" % fam
    assert len(half[0]) == 1878

import collections
CMDS = {fam: collections.Counter(c for _, c, _, _ in PATHS[fam]) for fam in PATHS}
assert dict(CMDS[0x2B]) == {0x1A: 3742, 0x19: 6, 0x1B: 2, 0x1C: 2, 0x1E: 2, 0x1F: 2}
assert dict(CMDS[0x2C]) == {0x18: 3750, 0x17: 6}

# ------------------------------------------------ descriptor pointer tables
# (family, group) -> (table, index bound).  Bounds are the ROM's own
# `cp A,<n> / jr nc` at the arm quoted beside each row.
TABLES = [
    (0x2C, 1, 0xF51E8E, 0x17, 0xFB356C), (0x2B, 1, 0xF51EEA, 0x17, 0xFB4326),
    (0x2C, 2, 0xF51F46, 0x05, 0xFB35C0), (0x2B, 2, 0xF51F5A, 0x01, 0xFB437A),
    (0x2C, 3, 0xF51F5E, 0x19, 0xFB3613), (0x2B, 3, 0xF51FC2, 0x19, 0xFB43CD),
    (0x2C, 5, 0xF52026, 0x13, 0xFB3668), (0x2B, 5, 0xF52072, 0x13, 0xFB4422),
    (0x2C, 6, 0xF520BE, 0x28, 0xFB36BC), (0x2B, 6, 0xF5215E, 0x28, 0xFB4476),
    (0x2C, 7, 0xF521FE, 0x02, 0xFB3710), (0x2B, 7, 0xF52206, 0x02, 0xFB44CA),
]
# LAST-ENTRY TEST: the twelve tables tile with no gap and no overlap.
cur = TABLES[0][2]
for fam, g, base, n, site in TABLES:
    assert base == cur, "table %06X does not follow the previous one" % base
    cur = base + 4 * n
assert cur == 0xF5220E, "the tiling ends at %06X" % cur

# 0xFB3AE2 `add XWA,0x00f4fa9c` -- byte 8 -> internal id, 0xFF = ignore
XLAT = rd(0xF4FA9C, 0x80)
XLAT_OK = [i for i, b in enumerate(XLAT) if b != 0xFF]
XLAT_FIRST = XLAT_OK[0]
assert len(XLAT_OK) == 68 and XLAT_FIRST == 0x20
assert [b for b in XLAT if b != 0xFF] == list(range(1, 69)), "xlat is not a dense run"

PLACEHOLDER = 0xF511F9      # index 0 of every group; 0xFB4D92 refuses it by name
DESC = {}
for fam, g, base, n, site in TABLES:
    for i in range(n):
        d = l32(base + 4 * i)
        DESC[(fam, g, i)] = (d, tuple(rd(d, 3)), tuple(rd(d + 3, 3)))
    assert DESC[(fam, g, 0)][0] == PLACEHOLDER, "index 0 is not the placeholder"

# -------------------------------------------- grammar vs descriptor, byte for byte
def septets(t):
    return (t[0] << 14) | (t[1] << 7) | t[2]

PARTS = range(0x20, 0x40)
stats = collections.Counter()
for fam in (0x2B, 0x2C):
    for p, c, g, i in PATHS[fam]:
        if p[0]:                      # one device half is enough
            continue
        if g == 0xFF:                 # the whole-area sequences, checked below
            continue
        gg = g
        addr = tuple(p[2:5])
        d, da, ds = DESC[(fam, gg, i)]
        # the part blocks share one descriptor whose template byte 7 is 0x20
        if addr[1] in PARTS and da[1] == 0x20:
            assert (addr[0], addr[2]) == (da[0], da[2]), "part address mismatch"
        elif addr[2] == 0xFE:
            # THE ONE WILDCARD.  byte 7 = 11, byte 8 = anything: 0xFB3AD1 reads
            # byte 8 back out of the parse record and looks it up in prom_b
            # 0xF4FA9C; 0xFF there means "drop the message".  The descriptor's
            # own low byte is the first index the table admits.
            assert (fam, gg, i) in ((0x2B, 3, 24), (0x2C, 3, 24))
            assert addr[:2] == da[:2] and da[2] == XLAT_FIRST
        else:
            assert addr == da, "address %s != descriptor %s" % (addr, da)
        tail = tuple(p[5:])
        if tail:
            assert tail == ds, "count triple %s != descriptor %s" % (tail, ds)
        assert bool(tail) == (septets(ds) != 1), \
            "the count triple is in the grammar iff the parameter is multi-byte"
        stats[(fam, gg, septets(ds))] += 1

# ---------------------------------------------------------------- the shape
AREA = {}                      # byte7 -> [(byte8, group, index, count)]
for p, c, g, i in PATHS[0x2C]:
    if p[0] or g == 0xFF or p[2] != 0x00:
        continue
    AREA.setdefault(p[3], []).append((p[4], g, i, septets(DESC[(0x2C, g, i)][2])))

assert sorted(AREA) == [0x00, 0x01, 0x08, 0x10, 0x11] + list(PARTS) + [0x60]
ref = AREA[0x20]
for b7 in PARTS:
    assert AREA[b7] == ref, "part block %02X differs from part block 20" % b7
assert len(ref) == 57, "a part block holds %d parameters" % len(ref)
assert len([x for x in ref if x[1] == 5]) == 18
assert len([x for x in ref if x[1] == 6]) == 39

# 0x08 is the one area 2C reaches and 2B does not, and its 2B method is a bare RET
b7_2B = {p[3] for p, c, g, i in PATHS[0x2B] if g != 0xFF and p[2] == 0x00}
b7_2C = set(AREA)
assert b7_2C - b7_2B == {0x08}, "the read/write asymmetry moved"
assert rd(0xF4F800 + 4 * 0x1A, 4) == rd(0xF4F888 + 4 * 0x1A, 4)

# ------------------------------------------------- whole-area requests (2B only)
# byte 6 = area, byte 7 = byte 8 = 0, count wild.  Each arm writes a job code to
# (0x60F802); the codes are the SEND menu's own row->job table at prom_a 0xF99AE3.
AREA_REQ = {}
for p, c, g, i in PATHS[0x2B]:
    if p[0] == 0 and g == 0xFF and p[2] not in (0x10, 0x18, 0x19):
        assert p[3] == 0 and p[4] == 0 and p[5:] == [0xFE, 0xFE, 0xFE]
        AREA_REQ[p[2]] = c
assert AREA_REQ == {0x40: 0x1B, 0x20: 0x1C, 0x50: 0x1F, 0x60: 0x1E}
prom_a = open(os.path.join(HERE, "..", "..", "original_ROMs",
                           "wsa1_prom_a.ic12"), "rb").read()
def a_rd(a, n):
    return prom_a[a - 0xF80000: a - 0xF80000 + n]
assert a_rd(0xF99AE3, 5) == bytes([0x00, 0x03, 0x05, 0x04, 0x02]), "menu table moved"
JOB_SITE = {0x1B: 0xFB5122, 0x1C: 0xFB512C, 0x1E: 0xFB5140, 0x1F: 0xFB514A}
JOBS = {}
for cmd, site in JOB_SITE.items():
    ins = a_rd(site, 6)                     # ld (0x60f802:24),<imm8>
    assert ins[:5] == bytes([0xF2, 0x02, 0xF8, 0x60, 0x00])
    JOBS[cmd] = ins[5]
assert JOBS == {0x1B: 4, 0x1C: 3, 0x1E: 2, 0x1F: 5}

# --------------------------------------------------------------------- output
if "--paths" in sys.argv:
    for fam in (0x2B, 0x2C):
        for p, c, g, i in PATHS[fam]:
            print("F0 50 %02X 04 %s  => CMD 0x%02X  group %s index %s" % (
                fam, " ".join("<any>" if b == 0xFE else "%02X" % b for b in p),
                c, "-" if g == 0xFF else g, "-" if i == 0xFF else i))
    sys.exit(0)

print()
print("family  sequences  command ids")
for fam in (0x2B, 0x2C):
    print("  %02X      %5d     %s" % (fam, len(PATHS[fam]),
          ", ".join("0x%02X x%d" % kv for kv in sorted(CMDS[fam].items()))))

print()
print("PARAMETER AREA  (byte 6 = 00)   byte 7 = area / part, byte 8 = parameter")
NAMES = {0x00: "common block 0", 0x01: "common block 1", 0x08: "2C-only block",
         0x10: "common block 10", 0x11: "common block 11", 0x60: "single parameter"}
for b7 in sorted(AREA):
    if b7 in PARTS and b7 != 0x20:
        continue
    lo = sorted(x[0] for x in AREA[b7] if x[0] != 0xFE)
    tag = "part 0 of 32 (byte 7 = 20 + part)" if b7 == 0x20 else NAMES[b7]
    multi = [("%02X" % x[0], x[3]) for x in AREA[b7] if x[3] != 1]
    print("  byte7=%02X  %-34s %2d parameters  byte8 %02X..%02X%s" % (
        b7, tag, len(AREA[b7]), lo[0], lo[-1],
        "   multi-byte: " + ", ".join("%s=%d" % m for m in multi) if multi else ""))

print()
runs, start = [], XLAT_OK[0]
for a, b in zip(XLAT_OK, XLAT_OK[1:] + [-1]):
    if b != a + 1:
        runs.append((start, a)); start = b
print("byte7=11 byte8>=03  one wildcard record; byte 8 is looked up, %d values admitted"
      % len(XLAT_OK))
print("  admitted byte8 runs: %s" % ", ".join("%02X..%02X" % r for r in runs))
print("  anything else under byte7=11 is accepted by the grammar and then dropped")

print()
print("WHOLE-AREA REQUEST  (2B only)   F0 50 2B 04 nn 11 <area> 00 00 <count3>")
CAT = {4: "SYSTEM, PART & MIDI", 3: "SOUND", 5: "COMBINATION", 2: "SEQUENCER"}
for area in sorted(AREA_REQ):
    cmd = AREA_REQ[area]
    print("  byte6=%02X  address 0x%06X  CMD 0x%02X  job %d = %s" % (
        area, area << 14, cmd, JOBS[cmd], CAT[JOBS[cmd]]))

print()
print("THIRD REGION  (both families)   byte 6 = 10 / 18 / 19, rest wild")
print("  2B -> CMD 0x19 (prom_a 0xFB3495 -> prom_b sub_F36F8C)")
print("  2C -> CMD 0x17 (prom_a 0xFB3483 -> prom_b sub_F379AB)")
print("  both unpack the address and count septets and are otherwise undecoded")

print()
print("descriptor tables tile 0x%06X..0x%06X over %d groups x 2 families"
      % (TABLES[0][2], cur, len({g for _, g, _, _, _ in TABLES})))
print("OK")
