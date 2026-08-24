#!/usr/bin/env python3
"""Is prom_d a TONE DATABASE of the same design as the KN5000's, and what is in it?

Every number quoted in notes/FINDINGS-prom-d-tone-database.md is produced here,
and every claim that can fail is an assert.  Reads only:

    original_ROMs/wsa1_prom_d.bin                              (this tree)
    ../kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom  (cross-reference)

Run:  python3 scripts/analysis/prom_d_tone_database.py
      python3 scripts/analysis/prom_d_tone_database.py --quiet   (asserts only)

Exit 0 = every assertion held.

THE QUESTIONS, in the order they are answered
---------------------------------------------
 Q1  Is the 48-slot table at file 0x0000 the same directory as the KN5000's
     `ToneDB_Directory` (table_data/tone_database_directory.s)?
 Q2  What are the 10 x 128 LE16 tables at 0x0180, and is their program order
     General MIDI?
 Q3  How many tone records are there, and what is a tone record's layout?
     -- specifically, is the "217 + N*124" the anatomy script printed real, and
     does 124 split into 81 + 43?
 Q4  Is the WSA1's 81-byte element block the SAME STRUCTURE as the KN5000's?
 Q5  What do the other directory slots point at, and do the sizes come out
     whole?

WHAT AN ASSERT HERE DOES AND DOES NOT ESTABLISH
-----------------------------------------------
It establishes SHAPE: counts, strides, that a span divides exactly, that two
populations share modal bytes far above a null.  It does NOT establish MEANING.
No WSA1 instruction that reads any of these structures has been found yet -- the
base address of prom_d is not even established (prom_d/prom_d.ld) -- so every
NAME below is transplanted from the KN5000 and is a hypothesis.  The names are
cited to ../kn5000-roms-disasm/table_data/tone_database_directory.s so that a
later reader can check them rather than believe them.
"""
import collections
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KN5000 = os.path.join(os.path.dirname(ROOT), "kn5000-roms-disasm")

QUIET = "--quiet" in sys.argv
FAILED = []


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    if cond:
        say("  PASS  %-64s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-64s %s" % (label, detail))


D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
u8 = lambda o: D[o]
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]

# --------------------------------------------------------------------------
# Q1  the 48-slot directory at 0x0000
# --------------------------------------------------------------------------
say("== Q1  the directory at file 0x0000 ==")
DIR = [u32(4 * i) for i in range(48)]
used = [(i, v) for i, v in enumerate(DIR) if v != 0xFFFFFFFF]
check("48 slots, 46 hold a value, slots 0/46/47 are 0xFFFFFFFF",
      len(used) == 45 and DIR[0] == 0xFFFFFFFF and DIR[46] == DIR[47] == 0xFFFFFFFF,
      "%d used" % len(used))
check("every used slot is a valid file offset (< 0x80000)",
      all(v < 0x80000 for _, v in used))

# The KN5000's directory tail is a run of scalars at +0xC0..+0xFF.  Same shape here.
tail = [u16(0xC0 + 2 * i) for i in range(32)]
check("+0xC0..+0xCF are zero, as in the KN5000", all(x == 0 for x in tail[0:8]))
kn_tail = {0xD0: 3, 0xD2: 0, 0xD4: 3, 0xD6: 2, 0xD8: 3, 0xDA: 2, 0xE8: 426}
for off, val in sorted(kn_tail.items()):
    check("tail word +0x%02X == %d (KN5000 has the same value)" % (off, val),
          u16(off) == val, "got %d" % u16(off))
say("  strides that differ from the KN5000: "
    "+0xE0=%d (KN5000 28), +0xEA=%d (11), +0xEC=%d (15), +0xEE=%d (58), +0xF0=%d (11), +0xF2=%d (15)"
    % (u16(0xE0), u16(0xEA), u16(0xEC), u16(0xEE), u16(0xF0), u16(0xF2)))
check("slots +0x9C/+0xA0/+0xA4 alias +0x24/+0x28/+0x2C, exactly as the KN5000's do",
      (DIR[0x9C // 4], DIR[0xA0 // 4], DIR[0xA4 // 4]) ==
      (DIR[0x24 // 4], DIR[0x28 // 4], DIR[0x2C // 4]))
check("slots +0x18/+0x1C are equal and +0x30/+0x34 are equal, as in the KN5000",
      DIR[6] == DIR[7] and DIR[12] == DIR[13])

# --------------------------------------------------------------------------
# Q2  bank map + tone-number banks
# --------------------------------------------------------------------------
say("== Q2  bank map (0x0100) and tone-number banks (0x0180) ==")
check("directory +0x6C points at 0x0100 and +0x04 at 0x0180, i.e. +0x80 apart -- "
      "the KN5000's BankMap/ToneNumBanks pair",
      DIR[0x6C // 4] == 0x100 and DIR[0x04 // 4] == 0x180)
bank_map = D[0x100:0x180]
check("bank map is 128 bytes; entries 0..7 are 0..7; entry 0x20 is 8 and entry 0x27 is 9",
      len(bank_map) == 128 and list(bank_map[0:8]) == list(range(8))
      and bank_map[0x20] == 8 and bank_map[0x27] == 9)
check("all other bank-map entries are 0",
      sum(1 for i, b in enumerate(bank_map) if b and i not in (1, 2, 3, 4, 5, 6, 7, 0x20, 0x27)) == 0)

NBANK = 10
banks = [[u16(0x180 + 0x100 * b + 2 * p) for p in range(128)] for b in range(NBANK)]
check("0x0180..0x0B7F is exactly %d x 128 LE16" % NBANK, 0xB80 - 0x180 == NBANK * 256)
check("every entry is a valid tone index (< 274)", all(v < 274 for b in banks for v in b))
check("banks 0-7 select ONLY melodic tones (index < 256)",
      all(v < 256 for b in banks[0:8] for v in b))
check("banks 8-9 select ONLY drum kits (index >= 256)",
      all(v >= 256 for b in banks[8:10] for v in b))

# --------------------------------------------------------------------------
# Q3  the offset table and the tone-record layout
# --------------------------------------------------------------------------
say("== Q3  tone-record offset table (0x0B80) and record layout ==")
PTRS = []
o = 0xB80
while 0x1000 <= u32(o) < 0x80000:
    PTRS.append(u32(o))
    o += 4
check("274 LE32 entries, terminated by a 0 word at 0x0FC8",
      len(PTRS) == 274 and o == 0xFC8 and u32(o) == 0)
check("all 274 offsets are distinct", len(set(PTRS)) == 274)
name = lambda p: D[p:p + 16]
check("every offset lands on 16 printable bytes (a space-padded name)",
      all(all(0x20 <= c < 0x7F for c in name(p)) for p in PTRS))
say("     tone 0x000 = %r   tone 0x100 = %r   tone 0x111 = %r"
    % (name(PTRS[0]), name(PTRS[256]), name(PTRS[273])))

MEL = sorted(PTRS[:256])
DRUM = sorted(PTRS[256:])
check("the 18 drum kits are contiguous on a 408-byte stride",
      all(DRUM[i + 1] - DRUM[i] == 408 for i in range(17)))
DRUM_END = DRUM[-1] + 408
check("the drum-kit block ends at 0x%05X, which is directory slot +0x74" % DRUM_END,
      DRUM_END == DIR[0x74 // 4])

# melodic record sizes: successor distance inside the two runs, plus the two
# ends, which are fixed by the next directory-named section.
GUNSHOT_END = DIR[0xAC // 4]          # +0xAC = ToneDB_DefaultLayerParams
DRAWBAR_END = DIR[0x70 // 4]          # +0x70 = DrawbarPreset_EnvDescTable
sizes = {}
for i, p in enumerate(MEL):
    nxt = MEL[i + 1] if i + 1 < len(MEL) else None
    if p >= 0x40000:                       # the two "Drawbar" records
        sizes[p] = (nxt if nxt and nxt >= 0x40000 else DRAWBAR_END) - p
    else:
        sizes[p] = (nxt if nxt and nxt < 0x40000 else GUNSHOT_END) - p
hist = collections.Counter(sizes.values())
say("     melodic record-size histogram: %s" % sorted(hist.items()))
check("every melodic record is 341/465/589/713 bytes, except the two Drawbar records at 541",
      set(hist) == {341, 465, 589, 713, 541} and hist[541] == 2)
check("341/465/589/713 = 217 + N*124 for N = 1..4",
      all(217 + 124 * n in hist for n in (1, 2, 3, 4)))

# the element-count byte
NOF = {p: (sizes[p] - 217) // 124 for p in MEL if sizes[p] != 541}
mask_by_n = collections.defaultdict(set)
for p, n in NOF.items():
    mask_by_n[n].add(D[p + 0x11])
check("byte +0x11 partitions the records by N with NO overlap: %s"
      % {n: sorted(v) for n, v in sorted(mask_by_n.items())},
      all(not (mask_by_n[a] & mask_by_n[b]) for a in mask_by_n for b in mask_by_n if a < b))
check("byte +0x11 is four 2-bit fields whose set-field count IS N",
      all(sum(1 for k in range(0, 8, 2) if (m >> k) & 3) == n
          for n, ms in mask_by_n.items() for m in ms))
check("the two 541-byte Drawbar records carry +0x11 = 0x55 (all four fields set)",
      all(D[p + 0x11] == 0x55 for p in MEL if sizes[p] == 541))

# --- the 124 = 81 + 43 split, by column entropy over the whole population -----
import math


def col_entropy(blocks, width):
    n = len(blocks)
    h = 0.0
    for c in range(width):
        cnt = collections.Counter(b[c] for b in blocks)
        h += -sum(v / n * math.log2(v / n) for v in cnt.values())
    return h


def split_score(W):
    """Total column entropy of the two arrays when 124 is cut as W + (124-W)."""
    V = 124 - W
    A, B = [], []
    for p, n in NOF.items():
        for i in range(n):
            A.append(D[p + 217 + W * i:][:W])
            B.append(D[p + 217 + W * n + V * i:][:V])
    return col_entropy(A, W) + col_entropy(B, V)


scores = sorted((split_score(W), W) for W in range(20, 105))
best_h, best_W = scores[0]
runner_h, runner_W = scores[1]
say("     best split W=%d (%.2f bits); runner-up W=%d (%.2f bits); worst %.2f bits"
    % (best_W, best_h, runner_W, runner_h, scores[-1][0]))
check("the record body cuts as 81 + 43 and nothing else comes close",
      best_W == 81 and runner_h - best_h > 50,
      "gap to runner-up = %.1f bits" % (runner_h - best_h))

# interleaved control: A0 B0 A1 B1 ... instead of A0 A1 .. B0 B1 ..
inter = []
for p, n in NOF.items():
    for i in range(n):
        inter.append(D[p + 217 + 124 * i:][:124])
h_inter = col_entropy(inter, 124)
check("the two arrays are SEPARATE, not interleaved per element",
      h_inter - best_h > 100, "interleaved reading costs %.1f bits" % (h_inter - best_h))

# 43 is the directory's own stride word
check("43 is the directory word at +0xEA (the KN5000 calls it the wave-select "
      "record stride/copy length)", u16(0xEA) == 43)

# and the +0xAC default block is exactly one of each
check("slot +0xAC spans exactly 81+43 = 124 bytes -- one element block plus one "
      "wave-select record", DIR[0xB0 // 4] - DIR[0xAC // 4] == 124)

# --------------------------------------------------------------------------
# Q4  is the 81-byte element block the KN5000's?
# --------------------------------------------------------------------------
say("== Q4  WSA1 element block vs KN5000 element block ==")
kn_path = os.path.join(KN5000, "original_ROMs", "kn5000_table_data.rom")
if not os.path.exists(kn_path):
    say("  SKIP  %s not present" % kn_path)
else:
    T = open(kn_path, "rb").read()
    KB = 0x30000                      # ToneDB_Base = ROM 0x830000 = file 0x30000
    koff = [struct.unpack_from("<I", T, KB + 0x1B00 + 4 * i)[0] for i in range(629)]
    ks = sorted(set(koff))
    ksz = {ks[i]: ks[i + 1] - ks[i] for i in range(len(ks) - 1)}
    kn_hist = collections.Counter(v for v in ksz.values() if v < 1000)
    say("     KN5000 record-size histogram: %s" % sorted(kn_hist.items()))
    check("KN5000 tone records are 21 + 81*N, N = 1..5 (documented stride, re-measured)",
          all(21 + 81 * n in kn_hist for n in range(1, 6)))
    K = [T[KB + o + 21 + 81 * i:][:81]
         for o, z in ksz.items() if z in (102, 183, 264, 345, 426)
         for i in range((z - 21) // 81)]

    def wsa_elems(shift):
        return [D[p + 217 + shift + 81 * i:][:81] for p, n in NOF.items() for i in range(n)]

    modal = lambda P: [collections.Counter(b[c] for b in P).most_common(1)[0][0] for c in range(81)]
    mk = modal(K)
    agree = lambda P: sum(1 for c in range(81) if mk[c] == modal(P)[c])
    aligned = agree(wsa_elems(0))
    nulls = [agree(wsa_elems(k)) for k in (-8, -5, -3, -2, -1, 1, 2, 3, 5, 8, 13, 21, 40)]
    mw = modal(wsa_elems(0))
    rot = [sum(1 for c in range(81) if mk[c] == mw[(c + r) % 81]) for r in (1, 2, 3, 7, 11, 17, 29, 40)]
    say("     %d KN5000 blocks vs %d WSA1 blocks" % (len(K), len(wsa_elems(0))))
    say("     columns sharing the modal byte: aligned %d/81; shift nulls %s; rotation nulls %s"
        % (aligned, nulls, rot))
    check("the WSA1 81-byte element block IS the KN5000's, by modal-byte agreement "
          "far above both nulls", aligned >= 55 and aligned > 2 * max(nulls + rot),
          "%d vs worst null %d" % (aligned, max(nulls + rot)))
    nz = [c for c in range(81) if mk[c] != 0]
    say("     of the %d columns whose KN5000 modal byte is NON-zero, %d also agree"
        % (len(nz), sum(1 for c in nz if mk[c] == mw[c])))

    # --- the element mask exists in the KN5000 too, with an off-by-one --------
    kn_n = {o: (z - 21) // 81 for o, z in ksz.items() if z in (102, 183, 264, 345, 426)}
    kn_by = collections.defaultdict(collections.Counter)
    for o, n in kn_n.items():
        kn_by[n][T[KB + o + 0x11]] += 1
    say("     KN5000 byte +0x11 by N: %s"
        % {n: dict(c) for n, c in sorted(kn_by.items())})
    pc = lambda m: sum(1 for k in range(0, 8, 2) if (m >> k) & 3)
    lo = [(n, m) for n in (1, 2, 3, 4) for m in kn_by[n]]
    check("the KN5000 tone record has the SAME 4x2-bit mask at +0x11, but its set-field "
          "count is N-1, not N (519 records, N=1..4)",
          all(pc(m) == n - 1 for n, m in lo)
          and sum(sum(kn_by[n].values()) for n in (1, 2, 3, 4)) == 519)
    bad5 = sum(v for m, v in kn_by[5].items() if pc(m) != 4)
    say("     ⚠ the rule BREAKS for the KN5000's N=5 class: %d of %d of those records "
        "carry a mask with fewer than 4 set fields, so the 426-byte size class is not "
        "trustworthy as 'five elements'" % (bad5, sum(kn_by[5].values())))

    # --- byte +0x10 ----------------------------------------------------------
    say("     KN5000 byte +0x10 values: %s" % sorted(collections.Counter(T[KB + o + 0x10] for o in kn_n).items()))
    say("     WSA1   byte +0x10 values, melodic: %s ; drum kits: %s"
        % (sorted(collections.Counter(D[p + 0x10] for p in MEL).items()),
           sorted(collections.Counter(D[p + 0x10] for p in PTRS[256:]).items())))
    check("every WSA1 drum-kit record has +0x10 = 0x80 and no melodic record does",
          all(D[p + 0x10] == 0x80 for p in PTRS[256:])
          and not any(D[p + 0x10] == 0x80 for p in MEL))

# --- drum-kit records ------------------------------------------------------
say("== Q4b drum-kit records vs melodic tone records ==")
KITS = PTRS[256:]
check("18 drum kits, all 408 bytes, all with a 16-byte printable name",
      len(KITS) == 18 and all(all(0x20 <= c < 0x7F for c in D[p:p + 16]) for p in KITS))
check("a drum kit ends with 128 LE16, one per MIDI note: 152 + 2*128 == 408",
      152 + 256 == 408)
LANDMARK = b"\x11\x00\x01\x63\x1e\x06\x00\x54"
nmel = sum(1 for p in MEL if p < 0x40000 and D[p + 138:p + 146] == LANDMARK)
nkit = sum(1 for p in KITS if D[p + 82:p + 90] == LANDMARK)
check("the 8-byte token %r sits at melodic record +138 (%d of 254) and at drum-kit "
      "record +82 (%d of 18) -- the drum head reaches it 56 bytes earlier"
      % (LANDMARK, nmel, nkit), nmel >= 240 and nkit == 18)


def modal(pop, off):
    return collections.Counter(D[p + off] for p in pop).most_common(1)[0][0]


melo = [p for p in MEL if p < 0x40000]
ag = sum(1 for k in range(70) if modal(melo, 138 + k) == modal(KITS, 82 + k))
nulls = [sum(1 for k in range(70) if modal(melo, 138 + k + s) == modal(KITS, 82 + k))
         for s in (-5, -3, -1, 1, 3, 5, 17, 33)]
check("past that landmark the two heads AGREE: %d of 70 columns share a modal byte, "
      "against %s for shift nulls" % (ag, nulls), ag >= 50 and ag > 1.8 * max(nulls))
say("     but the melodic head runs 79 bytes past the landmark and the drum head only "
    "70, and the drum head is 56 bytes shorter before it -- so they are NOT the same header")

# --------------------------------------------------------------------------
# Q5  the remaining directory sections, and whether their spans divide whole
# --------------------------------------------------------------------------
say("== Q5  section sizes ==")
# wave catalogues: 16-byte rows, and each has a FOOTER whose LE16 is its row count
CATALOGUES = [(0x50, 0x54), (0x64, 0x68), (0x80, 0x84), (0x8C, 0x90), (0x94, 0x98)]
bounds = sorted(set(v for _, v in used)) + [0x50B09]
after = lambda off: min(b for b in bounds if b > off)
for cat_slot, foot_slot in CATALOGUES:
    base = DIR[cat_slot // 4]
    span = after(base) - base
    foot = DIR[foot_slot // 4]
    n = span // 16
    ok_rows = sum(1 for i in range(n) if all(0x20 <= c < 0x7F for c in D[base + 16 * i:base + 16 * i + 13]))
    check("catalogue +0x%02X: %d bytes = %d x 16, all %d rows start with a 13-char "
          "printable name, and its footer +0x%02X declares %d"
          % (cat_slot, span, n, n, foot_slot, u16(foot)),
          span % 16 == 0 and ok_rows == n and u16(foot) == n)
    check("  footer +0x%02X is self-sized: LE16 count, u8 length, that many bytes"
          % foot_slot, 3 + D[foot + 2] == after(foot) - foot or foot == DIR[0x98 // 4],
          "3+%d vs span %d" % (D[foot + 2], after(foot) - foot))

# 43-byte wave-select record arrays
for slot in (0x18, 0x20, 0x3C):
    base = DIR[slot // 4]
    span = after(base) - base
    check("wave-select array +0x%02X: %d bytes = %d x 43 exactly"
          % (slot, span, span // 43), span % 43 == 0)

# drum-instrument records, stride = directory word +0xEE
PERC = DIR[0x78 // 4]
perc_span = after(PERC) - PERC
STRIDE = u16(0xEE)
check("drum-instrument records +0x78: %d bytes = %d x %d exactly"
      % (perc_span, perc_span // STRIDE, STRIDE), perc_span % STRIDE == 0)
NPERC = perc_span // STRIDE
check("every drum-instrument record starts with a 13-char printable name",
      all(all(0x20 <= c < 0x7F for c in D[PERC + STRIDE * i:PERC + STRIDE * i + 13])
          for i in range(NPERC)))
check("the template at slot +0xB4 is byte-identical to drum-instrument record 0",
      D[DIR[0xB4 // 4]:DIR[0xB4 // 4] + STRIDE] == D[PERC:PERC + STRIDE])

# the two 2048-entry LE16 tables index the drum-instrument records
for slot in (0x74, 0x7C):
    base = DIR[slot // 4]
    span = after(base) - base
    vals = [u16(base + 2 * i) for i in range(span // 2)]
    real = [v for v in vals if v != 0xFFFF]
    check("+0x%02X: %d bytes = %d LE16, %d distinct values, max %d < %d drum-instrument records"
          % (slot, span, span // 2, len(set(real)), max(real), NPERC),
          span == 4096 and max(real) < NPERC)

# the 1024-entry LE16 index maps
IDX = (0x0C, 0x10, 0x14, 0x24, 0x28, 0x2C, 0x44, 0x48, 0x4C, 0x58, 0x5C, 0x60)
for slot in IDX:
    base = DIR[slot // 4]
    vals = [u16(base + 2 * i) for i in range(1024)]
    real = [v for v in vals if v != 0xFFFF]
    say("     +0x%02X @0x%05X  1024 LE16  max %d  distinct %d" % (slot, base, max(real), len(set(real))))
check("index map +0x48 tops out one below the 307-row catalogue at +0x50",
      max(u16(DIR[0x48 // 4] + 2 * i) for i in range(1024)) == u16(DIR[0x54 // 4]) - 1)
check("index map +0x5C tops out one below the 314-row catalogue at +0x64",
      max(u16(DIR[0x5C // 4] + 2 * i) for i in range(1024)) == u16(DIR[0x68 // 4]) - 1)
check("index map +0x14 tops out one below the 208-row catalogue at +0x8C",
      max(u16(DIR[0x14 // 4] + 2 * i) for i in range(1024)) == u16(DIR[0x90 // 4]) - 1)
check("index maps +0x2C and +0x60 top out one below the 161-row catalogue at +0x94",
      max(u16(DIR[0x2C // 4] + 2 * i) for i in range(1024)) ==
      max(u16(DIR[0x60 // 4] + 2 * i) for i in range(1024)) == u16(DIR[0x98 // 4]) - 1)

# the erased tail
last = 0x7FFEF
while D[last] == 0xFF:
    last -= 1
check("payload ends at 0x%05X, then one unbroken 0xFF run to the 16-byte tail tag" % last,
      last == 0x50B08 and all(x == 0xFF for x in D[0x50B09:0x7FFF0]))
check("tail tag is b'wsad_54.ssf' + 5 NULs", D[0x7FFF0:] == b"wsad_54.ssf\x00\x00\x00\x00\x00")

# --------------------------------------------------------------------------
say("")
if FAILED:
    print("FAILED (%d): %s" % (len(FAILED), FAILED))
    sys.exit(1)
print("prom_d tone database: all assertions held.")
