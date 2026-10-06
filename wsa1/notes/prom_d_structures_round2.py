#!/usr/bin/env python3
"""prom_d round 2 -- what records does this image hold, and WHAT PROVES BOTH ENDS?

QUESTION IT ANSWERS
    scripts/analysis/prom_d_tone_database.py established the tone/wave/drum
    structures.  It left four things open, and this script closes three of them
    and corrects one number that was measured on the FIRST record only:

      1. the three "descriptor" blocks at directory slots +0x30, +0x38 and +0x70,
         which that pass framed as "N x 14 + a remainder" and called
         "SUPPORTED, not proved" (+0x70: "framing not established");
      2. the 768 bytes at the end of the index map at slot +0x28, "Unexplained";
      3. the two 541-byte Drawbar tone records, "172 bytes short of the layout
         their own mask implies ... Left open";
      4. ⚠ the claim that a 43-byte wave-select record has 7F 7F 7F at +0x00 and
         7D 80 54 at +0x0D "in every record inspected".  Over the FULL
         populations that is false; the true counts are printed and asserted
         below.  This is the project's signature failure -- a shape read off the
         first record and quoted as a universal.

    It also runs the search that item 3 of the wave-7 writer-D brief asks for --
    a byte-level tie between a NAMED prom_d structure and an instruction in
    prom_a/b/c -- and reports the honest negative with the search stated.

HOW TO RUN
    python3 notes/prom_d_structures_round2.py            # every check, verbose
    python3 notes/prom_d_structures_round2.py --quiet    # failures only
    python3 notes/prom_d_structures_round2.py --layout   # the layout, for the emitter

    Exit status is non-zero if ANY check fails.  scripts/analysis/gen_prom_d_asm.py
    imports desc_layout() from this file and refuses to emit if the shape moved,
    so a boundary cannot drift between this audit and the assembly.

WHAT IS *NOT* ESTABLISHED, said before the results
    No WSA1 instruction that reads any structure named here has been found; §5 is
    the census that says so and names the five candidates it adjudicated as false.
    Every FIELD meaning inside a descriptor, a curve or a 6/8-byte row is unknown.
    What is measured is shape: where a record array starts, where it ends, what
    proves the end, and which pointer inside the image says so.
"""
import collections
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
assert len(D) == 0x80000

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-66s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-66s %s" % (label, detail))


# ===========================================================================
# the layout, re-derived from the image on every call
# ===========================================================================
DESC_BLOCKS = {                       # slot -> (start, end)
    0x30: (0x22D3B, 0x2B2AC),         # end = the drum-kit block, from the offset table
    0x38: (0x4399C, 0x446B4),         # end = the first Drawbar tone record
    0x70: (0x44AEE, 0x46D6A),         # end = the wave catalogue at slot +0x50
}
DESC_STRIDE = 14                      # the directory's own stride word at +0xEC / +0xF2


def desc_layout(slot):
    """Split a descriptor block into (header_count, pool_start, records).

    THE SPLIT IS NOT ASSUMED.  Each 14-byte header record carries two 32-bit
    0-based file offsets; every one of them points into the pool that follows the
    header.  So the header's END is the MINIMUM of those offsets, and the record
    count follows.  Solved as a fixed point starting from one record, because the
    count is needed to collect the offsets and the offsets give the count.

    Returns (H, P, recs) with recs[i] = (tag, off1, off2, byte9, w10, w12).
    Raises on any inconsistency, so a caller that gets a value can trust it.
    """
    a, b = DESC_BLOCKS[slot]
    H = 1
    for _ in range(64):
        offs = []
        for i in range(H):
            o = a + DESC_STRIDE * i
            offs += [u32(o + 1), u32(o + 5)]
        P = min(x for x in offs if x)          # 0 is a null pointer, not a target
        if (P - a) % DESC_STRIDE:
            raise AssertionError("slot +0x%02X: min pointer 0x%05X is not on the "
                                 "14-byte grid" % (slot, P))
        H2 = (P - a) // DESC_STRIDE
        if H2 == H:
            break
        H = H2
    else:
        raise AssertionError("slot +0x%02X: fixed point did not converge" % slot)
    P = a + DESC_STRIDE * H
    recs = []
    for i in range(H):
        o = a + DESC_STRIDE * i
        recs.append((D[o], u32(o + 1), u32(o + 5), D[o + 9], u16(o + 10), u16(o + 12)))
    for i, (_t, o1, o2, _b9, _w10, _w12) in enumerate(recs):
        for off in (o1, o2):
            if off and not (P <= off < b):
                raise AssertionError("slot +0x%02X record %d: pointer 0x%05X outside "
                                     "the pool 0x%05X-0x%05X" % (slot, i, off, P, b))
    return H, P, recs


def desc_segments(slot):
    """The pool of slot +0x30 / +0x38, cut into the parts its own pointers name.

    Returns a list of (start, end, kind, record_index); kind is 'A' for the part
    a record's FIRST pointer names and 'B' for the part its SECOND names.  The
    segments are in address order and tile the pool with no gap and no overlap --
    which is check 1.6, not an assumption made here.
    """
    a, b = DESC_BLOCKS[slot]
    H, P, recs = desc_layout(slot)
    pts = sorted({o for _t, o1, o2, _b, _w, _v in recs for o in (o1, o2) if o})
    owner = {}
    for i, (_t, o1, o2, _b, _w, _v) in enumerate(recs):
        if o1:
            owner.setdefault(o1, ("A", i))
        if o2:
            owner.setdefault(o2, ("B", i))
    segs = []
    for j, p in enumerate(pts):
        e = pts[j + 1] if j + 1 < len(pts) else b
        kind, idx = owner[p]
        segs.append((p, e, kind, idx))
    return segs


CURVE_BASE = 0x22A3B                  # = S(0x28) + 2048, the index map's real end
CURVE_STRIDE = 128
CURVE_N = (S(0x30) - CURVE_BASE) // CURVE_STRIDE


def curves():
    return [CURVE_BASE + CURVE_STRIDE * k for k in range(CURVE_N)]


if "--layout" in sys.argv:
    for sl in sorted(DESC_BLOCKS):
        H, P, _r = desc_layout(sl)
        a, b = DESC_BLOCKS[sl]
        print("slot +0x%02X  0x%05X..0x%05X  header %d x 14 = %d  pool 0x%05X..0x%05X = %d"
              % (sl, a, b, H, 14 * H, P, b, b - P))
    print("curves    0x%05X..0x%05X  %d x %d" % (CURVE_BASE, S(0x30), CURVE_N, CURVE_STRIDE))
    raise SystemExit


# ===========================================================================
say("== Q1  the three descriptor blocks: a 14-byte header ARRAY over a POOL ==")
# ===========================================================================
say("   The previous pass framed these as 'N x 14 + a remainder' and could not")
say("   place the remainder.  There is no remainder: each block is an array of")
say("   14-byte records followed by a pool, and the records' OWN 32-bit offsets")
say("   say where the array stops.")

EXPECT = {                             # slot -> (H, pool bytes, tail gap after the last target)
    0x30: (318, 29709, 6),
    0x38: (161, 1098, 6),
    0x70: (4, 8772, 24),
}
for slot in (0x30, 0x38, 0x70):
    a, b = DESC_BLOCKS[slot]
    H, P, recs = desc_layout(slot)
    eH, epool, etail = EXPECT[slot]
    check("+0x%02X: header is %d records of 14" % (slot, eH), H == eH,
          "H=%d, 14*H=%d" % (H, 14 * H))
    check("+0x%02X: header + pool TILES the block exactly" % slot,
          14 * H + (b - P) == b - a,
          "%d + %d = %d bytes" % (14 * H, b - P, b - a))
    check("+0x%02X: pool is %d bytes" % (slot, epool), b - P == epool)
    tg = [o for _t, o1, o2, _x, _y, _z in recs for o in (o1, o2) if o]
    nulls = sum(1 for _t, o1, o2, _x, _y, _z in recs for o in (o1, o2) if not o)
    check("+0x%02X: every non-null pointer lands in the pool" % slot,
          all(P <= o < b for o in tg),
          "%d pointers, %d null" % (len(tg), nulls))
    check("+0x%02X: the SMALLEST pointer IS the pool start (this is what proves "
          "the header's end)" % slot, min(tg) == P, "min = 0x%05X" % min(tg))
    # ---- and the LAST record, not only the first ----
    lt, lo1, lo2, lb9, lw10, lw12 = recs[-1]
    check("+0x%02X: the LAST record's second pointer is the LAST object in the "
          "pool" % slot, max(tg) == lo2 and b - lo2 == etail,
          "0x%05X, %d bytes short of the block end" % (lo2, b - lo2))
    say("        last record @0x%05X = %s" %
        (a + 14 * (H - 1), " ".join("%02X" % x for x in D[a + 14 * (H - 1):a + 14 * H])))

# ---- 1.6  the +0x30 pool is PARTITIONED by its descriptors -----------------
segs = desc_segments(0x30)
a30, b30 = DESC_BLOCKS[0x30]
H30, P30, recs30 = desc_layout(0x30)
cov = [0] * (b30 - P30)
for s, e, _k, _i in segs:
    for x in range(s, e):
        cov[x - P30] += 1
check("+0x30: the 318 (partA, partB) pairs PARTITION the 29,709-byte pool",
      cov.count(0) == 0 and max(cov) == 1,
      "%d segments, %d bytes uncovered, %d bytes covered twice"
      % (len(segs), cov.count(0), sum(1 for c in cov if c > 1)))
check("+0x30: 636 distinct pointer targets, all different",
      len(segs) == 2 * H30, "%d segments for %d records" % (len(segs), H30))

# ---- 1.7  every part A begins with a pointer into the curve bank -----------
CV = set(curves())
partA = [s for s, _e, k, _i in segs if k == "A"]
partB = [s for s, _e, k, _i in segs if k == "B"]
check("+0x30: EVERY part-A object begins with a 32-bit offset naming one of the "
      "six curves", all(u32(s) in CV for s in partA),
      "%d of %d" % (sum(1 for s in partA if u32(s) in CV), len(partA)))
check("+0x30: NO part-B object does (so the two pointers are different roles)",
      not any(u32(s) in CV for s in partB),
      "%d of %d" % (sum(1 for s in partB if u32(s) in CV), len(partB)))
alen = collections.Counter(e - s for s, e, k, _i in segs if k == "A")
say("        part-A lengths: %s" % sorted(alen.items()))

# ---- 1.8  tag bit 7 selects the part-B row size ---------------------------
blen = {}
for s, e, k, i in segs:
    if k == "B":
        blen[i] = e - s
n0 = [i for i in range(H30) if not recs30[i][0] >> 7]
n1 = [i for i in range(H30) if recs30[i][0] >> 7]
check("+0x30: tag bit 7 CLEAR -> part-B length is a multiple of 6",
      all(blen[i] % 6 == 0 for i in n0), "%d of %d records" % (len(n0), H30))
check("+0x30: tag bit 7 SET   -> part-B length is a multiple of 8",
      all(blen[i] % 8 == 0 for i in n1), "%d of %d records" % (len(n1), H30))
d0 = sum(1 for i in n0 if blen[i] % 8)
d1 = sum(1 for i in n1 if blen[i] % 6)
check("+0x30: the rule is not vacuous -- it is DISCRIMINATING for 264 of 318",
      d0 == 145 and d1 == 119,
      "%d bit7=0 lengths are NOT /8, %d bit7=1 lengths are NOT /6; the other "
      "54 are multiples of 24 and decide nothing" % (d0, d1))
say("        tag values: %s" % sorted(collections.Counter(r[0] for r in recs30).items()))

# ---- 1.9  +0x38: one SHARED part A, then one 6-byte row per record --------
H38, P38, recs38 = desc_layout(0x38)
o1s = [r[1] for r in recs38]
o2s = [r[2] for r in recs38]
check("+0x38: all 161 records share ONE part-A object", len(set(o1s)) == 1,
      "at 0x%05X, %d bytes" % (o1s[0], o2s[0] - o1s[0]))
check("+0x38: that shared object begins with the STEEPEST curve",
      u32(o1s[0]) == curves()[-1], "0x%05X = curve %d" % (u32(o1s[0]), CURVE_N - 1))
check("+0x38: the 161 part-B pointers are an arithmetic run of step 6",
      all(o2s[i + 1] - o2s[i] == 6 for i in range(H38 - 1)),
      "0x%05X .. 0x%05X" % (o2s[0], o2s[-1]))
check("+0x38: 132 + 161*6 = 1098 accounts for the pool with nothing left over",
      (o2s[0] - P38) + 6 * H38 == DESC_BLOCKS[0x38][1] - P38,
      "%d + %d = %d" % (o2s[0] - P38, 6 * H38, DESC_BLOCKS[0x38][1] - P38))
check("+0x38: all 161 tags are 0x40 (bit 7 clear), consistent with 6-byte rows",
      set(r[0] for r in recs38) == {0x40})

# ---- 1.10  +0x70: a different record class -------------------------------
H70, P70, recs70 = desc_layout(0x70)
check("+0x70: all four records have a NULL first pointer",
      all(r[1] == 0 for r in recs70), "so they carry no curve part")
check("+0x70: tag is 0x92 in all four -- NOT the 0x3F-0x42|bit7 family of +0x30/+0x38",
      set(r[0] for r in recs70) == {0x92})
pts70 = sorted({r[2] for r in recs70})
sizes70 = [(pts70[i + 1] if i + 1 < len(pts70) else DESC_BLOCKS[0x70][1]) - pts70[i]
           for i in range(len(pts70))]
check("+0x70: the four records name THREE distinct objects (two share one)",
      len(pts70) == 3, "sizes %s, total %d" % (sizes70, sum(sizes70)))
check("+0x70: the two large objects are 4374 = 729 x 6 bytes",
      sizes70[0] == sizes70[1] == 4374 and 4374 % 6 == 0)
check("+0x70: ⚠ tag 0x92 has bit 7 SET yet every object is a multiple of 6, so "
      "check 1.8's rule is NOT claimed here",
      all(s % 6 == 0 for s in sizes70) and any(s % 8 for s in sizes70),
      "4374 %% 8 = %d" % (4374 % 8))


def near_const_cols(buf, per):
    n = len(buf) // per
    return sum(1 for c in range(per)
               if collections.Counter(buf[per * i + c] for i in range(n)).most_common(1)[0][1] / n > 0.9)


A70 = D[pts70[0]:pts70[0] + 4374]
prof = {p: near_const_cols(A70, p) for p in (4, 5, 6, 7, 8, 12)}
check("+0x70: a column census picks period 6 over 4/5/7/8 (the null periods)",
      prof[6] == 3 and all(prof[p] == 0 for p in (4, 5, 7, 8)),
      "near-constant columns per period: %s" % prof)

# ===========================================================================
say("")
say("== Q2  the 768 'unexplained' bytes at slot +0x28 are SIX 128-byte curves ==")
# ===========================================================================
check("slot +0x28's index map is 2048 bytes like its eleven siblings, and the "
      "768 start right after it", S(0x28) + 2048 == CURVE_BASE,
      "0x%05X + 2048 = 0x%05X" % (S(0x28), CURVE_BASE))
check("the 768 bytes end exactly where slot +0x30 begins",
      CURVE_BASE + CURVE_N * CURVE_STRIDE == S(0x30),
      "%d = %d x %d" % (S(0x30) - CURVE_BASE, CURVE_N, CURVE_STRIDE))
check("the six curve addresses are EXACTLY the set of part-A head pointers",
      set(curves()) == {u32(s) for s in partA},
      "%s" % ["0x%05X" % c for c in curves()])
for k, c in enumerate(curves()):
    v = D[c:c + 128]
    mono = all(v[i] <= v[i + 1] for i in range(127))
    check("  curve %d @0x%05X: 128 bytes, monotonically NON-DECREASING, v[0]=0" % (k, c),
          mono and v[0] == 0,
          "v[127]=%d, so it rises ~1 per %.2f steps" % (v[127], 127.0 / max(v[127], 1)))
tops = [D[c + 127] for c in curves()]
sums = [sum(D[c:c + 128]) for c in curves()]
check("the six curves are ordered by slope, shallowest first",
      tops == sorted(tops), "v[127] = %s" % tops)
check("  five distinct slopes, not six: curves 3 and 4 share v[127] AND their sum, "
      "but are NOT the same curve", tops[3] == tops[4] and sums[3] == sums[4]
      and D[curves()[3]:curves()[3] + 128] != D[curves()[4]:curves()[4] + 128],
      "top %d, sum %d, differing in %d of 128 bytes"
      % (tops[3], sums[3], sum(1 for i in range(128)
                               if D[curves()[3] + i] != D[curves()[4] + i])))
check("curve 0 is one step per twelve indices (an octave, if the index is a note)",
      all(D[curves()[0] + i] == i // 12 for i in range(128)))
check("nothing else in the 768 bytes: the six curves tile it exactly",
      CURVE_N * CURVE_STRIDE == 768)

# ===========================================================================
say("")
say("== Q3  the five catalogue footers are PARTITIONS, not just self-sized ==")
# ===========================================================================
for cat, foot in ((0x50, 0x54), (0x64, 0x68), (0x80, 0x84), (0x8C, 0x90), (0x94, 0x98)):
    f = S(foot)
    total, n = u16(f), D[f + 2]
    body = list(D[f + 3:f + 3 + n])
    rows = None
    ends = sorted(v for v in DIR if v != 0xFFFFFFFF) + [0x50B09]
    nxt = min(v for v in ends if v > S(cat))
    rows = (nxt - S(cat)) // 16
    check("+0x%02X footer: %d groups summing to %d = the catalogue's %d rows"
          % (foot, n, sum(body), rows),
          sum(body) == total == rows, "groups %s" % body)
extra = D[0x50B08]
check("the stray byte at 0x50B08 is NOT part of the last footer's partition",
      sum(D[S(0x98) + 3:S(0x98) + 3 + D[S(0x98) + 2]]) == u16(S(0x98)),
      "footer closes at 0x%05X; 0x%02X at 0x50B08 is left over" % (S(0x98) + 3 + D[S(0x98) + 2], extra))
pay = D[:0x50B09]
hyp = {"sum8 of payload": sum(pay[:-1]) & 0xFF,
       "xor8 of payload": 0,
       "sum8 of the footer region": sum(D[S(0x98):0x50B08]) & 0xFF}
x = 0
for c in pay[:-1]:
    x ^= c
hyp["xor8 of payload"] = x
check("and it is not a checksum of the payload by three obvious readings",
      all(v != extra for v in hyp.values()),
      "0x08 vs %s" % {k: "0x%02X" % v for k, v in hyp.items()})

# ===========================================================================
say("")
say("== Q4  the two Drawbar records are 217 + 4*81, with NO wave-select array ==")
# ===========================================================================
PTRS = [u32(0xB80 + 4 * i) for i in range(274)]
DRAW = sorted(p for p in PTRS if 0x446B4 <= p < 0x44AEE)
check("the two Drawbar records are at 0x446B4 and 0x448D1, 541 bytes each",
      DRAW == [0x446B4, 0x448D1] and DRAW[1] - DRAW[0] == 541)
check("the SECOND one ends exactly where directory slot +0x70 begins (both ends "
      "proved, not only the first record's)", DRAW[1] + 541 == S(0x70),
      "0x%05X + 541 = 0x%05X" % (DRAW[1], S(0x70)))
check("541 = 217 + 4*81 exactly -- four element blocks and ZERO wave-select records",
      217 + 4 * 81 == 541,
      "the 'missing' 172 bytes of the old reading are exactly 4 x 43")
check("their element mask at +0x11 is 0x55 = four slots set, agreeing with N=4",
      all(D[p + 0x11] == 0x55 for p in DRAW))

# calibration: the modal-column profile of the 451 ORDINARY element blocks
mel = sorted(p for p in PTRS if p < S(0xAC))
NBY = {341: 1, 465: 2, 589: 3, 713: 4}
blocks = []
for i, p in enumerate(mel):
    e = mel[i + 1] if i + 1 < len(mel) else S(0xAC)
    for k in range(NBY[e - p]):
        blocks.append(D[p + 217 + 81 * k:p + 217 + 81 * (k + 1)])
modal = [collections.Counter(b[c] for b in blocks).most_common(1)[0][0] for c in range(81)]
agree = lambda blk: sum(1 for c in range(81) if blk[c] == modal[c])
self_mean = sum(agree(b) for b in blocks) / len(blocks)
draw_scores, null_scores = [], []
for p in DRAW:
    for k in range(4):
        o = p + 217 + 81 * k
        draw_scores.append(agree(D[o:o + 81]))
        for sh in (-7, -5, -3, 3, 5, 7):
            null_scores.append(agree(D[o + sh:o + sh + 81]))
check("and those 8 blocks ARE element blocks: they match the 451-block modal "
      "profile far better than any shifted null",
      min(draw_scores) > max(null_scores),
      "drawbar %d-%d of 81; shift nulls %d-%d; the 451 ordinary blocks average %.1f"
      % (min(draw_scores), max(draw_scores), min(null_scores), max(null_scores), self_mean))

# ===========================================================================
say("")
say("== Q4b LAST-element re-checks of strides this tree already claims ==")
# ===========================================================================
check("melodic tone records: the LAST one starts at 0x%05X and its 589 bytes end "
      "exactly at slot +0xAC" % mel[-1], mel[-1] + 589 == S(0xAC),
      "so the 254th record's size is proved by the next region, not by a stride")
check("drum kits: 18 x 408 tiles 0x2B2AC..0x%05X with nothing left over" % S(0x74),
      0x2B2AC + 18 * 408 == S(0x74))
check("  and the LAST kit's name is printable ASCII",
      all(0x20 <= c < 0x7F for c in D[0x2B2AC + 17 * 408:0x2B2AC + 17 * 408 + 16]),
      repr(D[0x2B2AC + 17 * 408:0x2B2AC + 17 * 408 + 16].decode("latin1")))
pi = S(0x78)
check("drum instruments: 504 x 150 tiles the slot up to +0x20, and the LAST "
      "record's 13-byte name is printable",
      pi + 504 * 150 == S(0x20)
      and all(0x20 <= c < 0x7F for c in D[pi + 503 * 150:pi + 503 * 150 + 13]),
      repr(D[pi + 503 * 150:pi + 503 * 150 + 13].decode("latin1")))
for slot, n in ((0x50, 307), (0x64, 314), (0x80, 503), (0x8C, 208), (0x94, 161)):
    last = S(slot) + 16 * (n - 1)
    check("  catalogue +0x%02X: the LAST of its %d rows is printable" % (slot, n),
          all(0x20 <= c < 0x7F for c in D[last:last + 13]),
          repr(D[last:last + 13].decode("latin1")))

say("")
say("   ⚠ CORRECTION to notes/FINDINGS-prom-d-tone-database.md §3: the wave-select")
say("     record's leading 7F 7F 7F and its 7D 80 54 at +0x0D are NOT in 'every")
say("     record'.  Measured over all three arrays, first record to last:")
WS_EXPECT = {0x18: (322, 312, 261), 0x20: (208, 203, 158), 0x3C: (64, 64, 18)}
for slot, (n, e3, ed) in WS_EXPECT.items():
    a = S(slot)
    c3 = sum(1 for i in range(n) if D[a + 43 * i:a + 43 * i + 3] == b"\x7f\x7f\x7f")
    cd = sum(1 for i in range(n) if D[a + 43 * i + 13:a + 43 * i + 16] == b"\x7d\x80\x54")
    check("  +0x%02X (%d records): 7F7F7F %d/%d, 7D8054 %d/%d" % (slot, n, c3, n, cd, n),
          (c3, cd) == (e3, ed),
          "LAST record starts %s" % " ".join("%02X" % x for x in D[a + 43 * (n - 1):a + 43 * (n - 1) + 3]))
    check("    and the array's LAST record ends exactly on the next region",
          a + 43 * n == min(v for v in sorted(set(DIR)) if v != 0xFFFFFFFF and v > a))

# ===========================================================================
say("")
say("== Q5  is any NAMED prom_d structure tied to an instruction?  NO -- the census ==")
# ===========================================================================
say("   The base 0x00F00000 IS tied to an instruction (VersionScreen_Show reads")
say("   remote 0x00F7FFF0, this image's build tag; notes/FINDINGS-memory-map.md §5,")
say("   notes/prom_d_base_checks.py).  What is still missing is narrower: a tie to a")
say("   NAMED STRUCTURE.  This is the search, so the negative can be checked.")
CODE = {}
for k, fn in (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"), ("c", "wsa1_prom_c.ic28")):
    CODE[k] = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
targets = {}
for i, v in enumerate(DIR):
    if v != 0xFFFFFFFF:
        targets.setdefault(v, []).append("directory slot +0x%02X" % (4 * i))
for off, nm in ((CURVE_BASE, "the curve bank"), (P30, "+0x30 pool"), (P38, "+0x38 pool"),
                (P70, "+0x70 pool"), (0x2B2AC, "drum-kit array"), (0x446B4, "Drawbar records"),
                (0x50B09, "erased tail")):
    targets.setdefault(off, []).append(nm)
hits = []
for off in sorted(targets):
    for k, B in CODE.items():
        pats = [("LE32 file offset", struct.pack("<I", off)),
                ("LE32 0xF00000+off", struct.pack("<I", 0xF00000 + off)),
                ("LE24 0xF00000+off", struct.pack("<I", 0xF00000 + off)[:3])]
        for label, pat in pats:
            if off < 0x1000 and label == "LE32 file offset":
                continue                      # a 4-byte pattern of small ints is noise
            s = 0
            while True:
                p = B.find(pat, s)
                if p < 0:
                    break
                hits.append((k, p, label, off))
                s = p + 1
check("the search covered %d distinct prom_d offsets x 3 encodings x 3 code ROMs"
      % len(targets), len(targets) == 46, "%d candidate byte matches" % len(hits))
ADJUDICATED = {
    ("b", 0x207D9): "inside a run of zeros in prom_b data; no instruction",
    ("c", 0x489FA): "prom_c 0xFC89F9 `ld DE,0x0100` in the EEPROM bit-banger; the "
                    "third byte of the 'LE24' is the F0 opcode of the NEXT instruction",
    ("c", 0x48A34): "prom_c 0xFC8A32 `or DE,0x0180`, same bit-banger, same straddle",
    ("b", 0x40AC5): "prom_b thunk table: LE24 0xF44AEE is a prom_b CODE address that "
                    "happens to equal 0xF00000 + 0x44AEE",
    ("a", 0x583D6): "straddles prom_a 0xFD83D4 `calr SoundEditEnvelope1_DrawGraph` and 0xFD83D7 "
                    "`pushw 0x05`; not an operand",
}
check("EVERY candidate is a false positive, each adjudicated by name",
      {(k, p) for k, p, _l, _o in hits} == set(ADJUDICATED),
      "%d hits, %d adjudicated" % (len(hits), len(ADJUDICATED)))
for k, p, label, off in sorted(hits):
    say("     prom_%s file 0x%05X  %-18s off 0x%05X (%s)"
        % (k, p, label, off, ", ".join(targets[off])))
    say("        -> %s" % ADJUDICATED[(k, p)])
say("   ANSWER: no.  And the negative is expected rather than surprising -- prom_c's")
say("   known consumer (Voice_SelectKeyZone_Reg0040) COMPUTES its addresses from a")
say("   base held in RAM 0x00D7ED plus offsets read out of the tone object, so a")
say("   structure offset never appears as an immediate.  A tie will have to come")
say("   from tracing what loads those RAM words, not from a constant search.")

# ===========================================================================
print("")
if FAILED:
    print("prom_d structures round 2: %d of %d checks FAILED" % (len(FAILED), NCHECK[0]))
    for f in FAILED:
        print("   - %s" % f)
    sys.exit(1)
print("prom_d structures round 2: all %d checks held." % NCHECK[0])
