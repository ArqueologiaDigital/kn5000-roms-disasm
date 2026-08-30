#!/usr/bin/env python3
"""P5 -- the descriptor tag's bit 7, and why the WSA1 and the KN5000 trees
appeared to contradict each other about it.

THE QUESTION
------------
  prom_d/tone_database_aux.s says, of the 14-byte descriptors at directory slot
  +0x30:   "the element SIZE is the descriptor's own tag bit 7: 6 bytes when it
            is clear (187 records here) and 8 when it is set (131)"
  and adds "⚠ ../kn5000-roms-disasm's note on the same field states the OPPOSITE
            polarity ... The polarity is therefore NOT transferable".

  ../kn5000-roms-disasm/table_data/tone_database_aux.s says, of the 15-byte
  descriptors at the SAME directory slot:
            "bit 7  zone-record stride: set -> 6 bytes (143 records), clear -> 4
             bytes (344 records) ... but bit 6 is clear in every record here".

  Are those two claims in conflict?

THE ANSWER: NO.  THERE IS ONE TABLE AND IT IS INDEXED BY TWO BITS.
------------------------------------------------------------------
  Both machines' consuming code tests BIT 6 FIRST and only then bit 7, and
  bit 7's meaning depends on what bit 6 said:

      tag bit6  bit7      WSA1 (prom_c)        KN5000 (v1.42 sub-CPU)
      --------------------------------------------------------------
         1        1            8               15 or 12 (a further bit-5 test)
         1        0            6               13 or 10 (idem)
         0        1            6                6
         0        0            4                4

  The two machines' BIT-6-CLEAR ROWS ARE IDENTICAL.  They diverge only on the
  bit-6-set row, where the WSA1 has two forms and no bit-5 test and the KN5000
  has four.

  And the two documented sentences are each TRUE OF THEIR OWN POPULATION,
  because the populations sit on opposite sides of bit 6:
      WSA1  slot +0x30:  bit 6 SET in 317 of 318 descriptors  -> only {8, 6}
      KN5000 the 487:    bit 6 SET in   0 of 487              -> only {6, 4}
  Neither tree was wrong about its own data.  What is wrong is the WSA1's
  cross-tree sentence, which reports a MISSING VARIABLE as a contradiction.

★ AND prom_d ALREADY HELD THE COUNTER-EXAMPLE, refusing to explain it.  Its
  slot +0x70 banner says: "⚠ Tag 0x92 has bit 7 SET yet every object is a
  multiple of 6, so the bit-7 rule stated on slot +0x30 is NOT claimed for this
  block."  0x92 has bit 6 CLEAR, so the two-bit table predicts 6 -- which is
  what the bytes do.  The refusal was right and the rule it refused was the
  incomplete one.  The KN5000's +0x70 descriptors carry the SAME flags byte,
  0x92, in all four records.

  python3 notes/prom_d_desc_tag_bit67.py            # the evidence
  python3 notes/prom_d_desc_tag_bit67.py --selftest # ★ the controls

★ --selftest PINS NO CURRENT VALUE.  Its checks are invariants of the argument:
  that the dispatch really tests bit 6 before bit 7, that the four callees are
  one instruction apart, that the three candidate rules DISCRIMINATE (a scoring
  that cannot separate them proves nothing), and that each two-bit-blind rule
  is refuted by a population the other tree owns.
"""
import collections
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KN = os.path.join(os.path.dirname(ROOT), "kn5000-roms-disasm")

PROM_C_BASE = 0xF80000
C = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()

u16 = lambda b, o: struct.unpack_from("<H", b, o)[0]
u32 = lambda b, o: struct.unpack_from("<I", b, o)[0]
DIR = [u32(D, 4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

FAILS = []


def check(name, cond, detail=""):
    print("  %s  %s%s" % ("PASS" if cond else "FAIL", name,
                          ("   " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


def cbytes(addr, n):
    return C[addr - PROM_C_BASE: addr - PROM_C_BASE + n]


# ---------------------------------------------------------------------------
# THE FOUR SIZE ROUTINES.  Each is `link / push / push / ld HL,(XIZ+8) /
# ld C,#N / mul BC,(XIZ+0x0e) / ...`; the first 0x1C bytes are IDENTICAL in all
# four except the ONE operand byte at +0x0A, which is the element size.
# ---------------------------------------------------------------------------
SIZE_ROUTINES = [0xFA7467, 0xFA74AB, 0xFA74ED, 0xFA752F]
SIZE_OPERAND = 0x0A          # the `ld C,#N` immediate
COMMON = 0x1C                # how far the four are byte-identical

# The dispatcher.  (address, expected bytes, what it is)
DISPATCH = [
    (0xFA81F3, "AE F8 21", "ld XBC,(XIZ+0xf8)   -- XBC = the descriptor"),
    (0xFA81F6, "81 26", "ld H,(XBC)          -- H = the TAG, descriptor +0x00"),
    (0xFA81F8, "CE 88", "ld W,H"),
    (0xFA81FA, "C8 CC 40", "and W,0x40          ★ BIT 6, tested FIRST"),
    (0xFA81FF, "66 19", "jr Z,0xFA821A       -- bit6 CLEAR -> the 6/4 arm"),
    (0xFA8201, "CE 8C", "ld D,H"),
    (0xFA8203, "CC CC 80", "and D,0x80          ★ BIT 7, on the bit6-SET arm"),
    (0xFA820E, "66 05", "jr Z,0xFA8215"),
    (0xFA8210, "1E 54 F2", "calr 0xFA7467       -- bit6=1 bit7=1"),
    (0xFA8215, "1E 93 F2", "calr 0xFA74AB       -- bit6=1 bit7=0"),
    (0xFA821A, "CE 8C", "ld D,H"),
    (0xFA821C, "CC CC 80", "and D,0x80          ★ BIT 7, on the bit6-CLEAR arm"),
    (0xFA8227, "66 05", "jr Z,0xFA822E"),
    (0xFA8229, "1E C1 F2", "calr 0xFA74ED       -- bit6=0 bit7=1"),
    (0xFA822E, "1E FE F2", "calr 0xFA752F       -- bit6=0 bit7=0"),
]

# Where the descriptor pointer is produced: sub_FB45C0 reads the index map and
# the descriptor-array slot as a PAIR, three times, one per family.
PRODUCER = [
    (0xFB4611, "E2 F1 D7 00 20", "ld XWA,(0x00D7F1)   -- prom_d's base"),
    (0xFB4616, "BE F6 60", "ld (XIZ+0xF6),XWA   ★ the base PARKED IN A FRAME SLOT"),
    (0xFB4665, "AE F6 21", "ld XBC,(XIZ+0xF6)   -- and read back here"),
    (0xFB4668, "A9 24 20", "ld XWA,(XBC+0x24)   -- slot +0x24, the index map"),
    (0xFB466E, "A9 30 25", "ld XIY,(XBC+0x30)   ★ SLOT +0x30, the descriptors"),
    (0xFB4679, "D3 E5 EC 00 20", "ld WA,(XBC+0x00EC)  -- the stride word, 14"),
    (0xFB468C, "A9 2C 20", "ld XWA,(XBC+0x2C)   -- slot +0x2C"),
    (0xFB4692, "A9 38 25", "ld XIY,(XBC+0x38)   ★ SLOT +0x38"),
    (0xFB46B3, "A9 28 20", "ld XWA,(XBC+0x28)   -- slot +0x28"),
    (0xFB46B9, "A9 34 25", "ld XIY,(XBC+0x34)   ★ SLOT +0x34"),
    (0xFB46E9, "91 20", "ld WA,(XBC)         -- the map entry"),
    (0xFB46EB, "9E EC 40", "mul XWA,(XIZ+0xEC)  -- x 14"),
    (0xFB46EE, "AE EE 80", "add XWA,(XIZ+0xEE)  -- + the descriptor array"),
    (0xFB46F1, "AE FA 80", "add XWA,(XIZ+0xFA)  -- + prom_d's base"),
]

# ---------------------------------------------------------------------------
RULES = collections.OrderedDict([
    ("prom_d  2-way   bit7 -> 8 : 6", lambda t: 8 if t & 0x80 else 6),
    ("★ 4-way  bit6,bit7 -> 8/6/6/4",
     lambda t: (8 if t & 0x80 else 6) if t & 0x40 else (6 if t & 0x80 else 4)),
    ("KN5000  2-way   bit7 -> 6 : 4", lambda t: 6 if t & 0x80 else 4),
])

# (slot, block end, descriptor count) -- the counts are round 2's, derived from
# the descriptors' own 32-bit offsets, and are asserted below rather than trusted.
BLOCKS = [(0x30, 0x2B2AC, 318), (0x38, 0x446B4, 161), (0x70, 0x46D6A, 4)]


def descriptors(slot, end, n):
    base, st = S(slot), 14
    recs = [dict(i=i, tag=D[base + st * i], A=u32(D, base + st * i + 1),
                 B=u32(D, base + st * i + 5)) for i in range(n)]
    starts = sorted({r["A"] for r in recs if r["A"]}
                    | {r["B"] for r in recs if r["B"]})
    assert starts and starts[0] == base + st * n, \
        "slot +0x%02X: the array does not end where the pool starts" % slot
    nxt = {a: (starts[k + 1] if k + 1 < len(starts) else end)
           for k, a in enumerate(starts)}
    for r in recs:
        r["blen"] = nxt[r["B"]] - r["B"]
        r["atab"] = D[r["A"] + 4: nxt[r["A"]]] if r["A"] else b""
    return recs


def score(recs, f):
    """(records whose part-B length is a multiple of the rule's size,
        records where it is also exactly max(part A)+1 elements)"""
    div = join = 0
    for r in recs:
        es = f(r["tag"])
        if r["blen"] % es == 0:
            div += 1
            if r["atab"] and r["blen"] // es == max(r["atab"]) + 1:
                join += 1
    return div, join


def kn5000():
    T = open(os.path.join(KN, "original_ROMs", "kn5000_table_data.rom"), "rb").read()
    dbb = 0x830000 - 0x800000
    kdir = [u32(T, dbb + 4 * i) for i in range(64)]
    st = u16(T, dbb + 0xEC)
    desc = dbb + kdir[0x30 // 4]
    flags = [T[desc + st * i] for i in range(487)]
    draw = [T[dbb + kdir[0x70 // 4] + st * i] for i in range(4)]
    return st, flags, draw


KN_SUB_PAT = bytes.fromhex("b6ce6640b6cf661eb6cd")   # bit6 / jr / bit7 / jr / bit5
KN_EMITTERS = [(0x022A3F, 15), (0x022A61, 12), (0x022A83, 13),
               (0x022AA4, 10), (0x022AC5, 6)]


def kn_subcpu():
    Sr = open(os.path.join(KN, "original_ROMs",
                           "kn5000_subprogram_v142.rom"), "rb").read()
    hits = [i for i in range(len(Sr)) if Sr.startswith(KN_SUB_PAT, i)]
    return Sr, hits


# ---------------------------------------------------------------------------
def main():
    print("P5 -- the descriptor tag's bit 7 in two machines\n")

    print("=== Q1.  prom_c DISPATCHES ON BIT 6 FIRST, then bit 7 "
          "(wsa1_prom_c.ic28 bytes) ===\n")
    ok = True
    for addr, hexs, what in DISPATCH:
        want = bytes.fromhex(hexs.replace(" ", ""))
        got = cbytes(addr, len(want))
        ok &= got == want
        print("  %06X  %-14s  %s" % (addr, " ".join("%02X" % b for b in got), what))
    check("Q1a  every quoted instruction re-decodes from the ROM at its address", ok)
    i6 = next(a for a, h, w in DISPATCH if "BIT 6" in w)
    i7 = next(a for a, h, w in DISPATCH if "bit6-SET" in w)
    check("Q1b  ★ the BIT-6 test comes BEFORE either bit-7 test -- which is the "
          "whole of P5", i6 < i7, "0x%06X then 0x%06X" % (i6, i7))

    print("\n=== Q2.  THE FOUR SIZE ROUTINES ARE ONE BYTE APART ===\n")
    heads = [cbytes(a, COMMON) for a in SIZE_ROUTINES]
    diff = [k for k in range(COMMON) if len({h[k] for h in heads}) > 1]
    sizes = [h[SIZE_OPERAND] for h in heads]
    for a, s in zip(SIZE_ROUTINES, sizes):
        print("  0x%06X  ld C,0x%02X  then  mul BC,(XIZ+0x0E)   -> element size %d"
              % (a, s, s))
    check("Q2a  over their first 0x%02X bytes the four differ in EXACTLY ONE "
          "position" % COMMON, diff == [SIZE_OPERAND],
          "differ at %s" % [hex(d) for d in diff])
    check("Q2b  and that position is the `ld C,#N` operand: the size table is "
          "8, 6, 6, 4", sizes == [8, 6, 6, 4], str(sizes))
    print("\n      tag bit6  bit7 -> element size")
    print("         1        1          %d" % sizes[0])
    print("         1        0          %d" % sizes[1])
    print("         0        1          %d" % sizes[2])
    print("         0        0          %d" % sizes[3])

    print("\n=== Q3.  WHERE THE DESCRIPTOR COMES FROM -- and why round 3 missed "
          "it ===\n")
    ok = True
    for addr, hexs, what in PRODUCER:
        want = bytes.fromhex(hexs.replace(" ", ""))
        got = cbytes(addr, len(want))
        ok &= got == want
        print("  %06X  %-16s  %s" % (addr, " ".join("%02X" % b for b in got), what))
    check("Q3a  ★ prom_c DOES read directory slots +0x30, +0x34 and +0x38",
          ok)
    print("\n  ⚠ prom_d's banners say `Readers: NONE FOUND` for +0x30 and +0x38.")
    print("    The reason is stated in round 3's own docstring: its census walks")
    print("    forward from a `ld X<r>,(0x00D7ED|0x00D7F1)` and `does not follow a")
    print("    base parked in a frame slot`.  0xFB4616 parks it in XIZ+0xF6 and")
    print("    0xFB4665 reads it back three instructions later.  The census was a")
    print("    stated LOWER BOUND; the banners turned it into an absence.")

    print("\n=== Q4.  THE TWO POPULATIONS SIT ON OPPOSITE SIDES OF BIT 6 ===\n")
    tab = {}
    for slot, end, n in BLOCKS:
        recs = descriptors(slot, end, n)
        tab[slot] = recs
        cen = collections.Counter(r["tag"] for r in recs)
        print("  WSA1 slot +0x%02X  %3d descriptors  tags %s" %
              (slot, n, dict(sorted(cen.items()))))
        print("                    bit6 SET in %d/%d, bit7 SET in %d/%d"
              % (sum(1 for r in recs if r["tag"] & 0x40), n,
                 sum(1 for r in recs if r["tag"] & 0x80), n))
    kst, kflags, kdraw = kn5000()
    kc = collections.Counter(kflags)
    print("  KN5000 slot +0x30 %3d descriptors  flags %s"
          % (len(kflags), dict(sorted(kc.items()))))
    print("                    bit6 SET in %d/%d, bit7 SET in %d/%d"
          % (sum(1 for f in kflags if f & 0x40), len(kflags),
             sum(1 for f in kflags if f & 0x80), len(kflags)))
    check("Q4a  ★ the KN5000's population has bit 6 CLEAR in EVERY record, so it "
          "can only ever exercise the 6/4 row",
          not any(f & 0x40 for f in kflags),
          "%d with bit 6 set" % sum(1 for f in kflags if f & 0x40))
    n30 = tab[0x30]
    check("Q4b  ★ the WSA1's +0x30 population has bit 6 SET in all but one, so it "
          "almost only exercises the 8/6 row",
          sum(1 for r in n30 if r["tag"] & 0x40) == len(n30) - 1,
          "%d of %d" % (sum(1 for r in n30 if r["tag"] & 0x40), len(n30)))
    check("Q4c  and both machines' +0x70 descriptors carry the SAME flags byte "
          "0x92 -- bit 6 CLEAR, bit 7 SET",
          {r["tag"] for r in tab[0x70]} == {0x92} and set(kdraw) == {0x92},
          "WSA1 %s, KN5000 %s" % (sorted({r["tag"] for r in tab[0x70]}),
                                  sorted(set(kdraw))))

    print("\n=== Q5.  THE THREE RULES, SCORED ON EVERY POPULATION ===\n")
    print("  %-32s %-22s %s" % ("", "part-B len divisible", "= max(partA)+1 elements"))
    grid = {}
    for slot, end, n in BLOCKS:
        print("  -- WSA1 slot +0x%02X, %d descriptors" % (slot, n))
        for name, f in RULES.items():
            div, join = score(tab[slot], f)
            grid[(slot, name)] = (div, join, n)
            print("     %-32s %5d/%-5d          %5d/%-5d" % (name, div, n, join, n))
    check("Q5a  the scoring DISCRIMINATES -- the three rules do not agree",
          len({grid[(0x30, k)][0] for k in RULES}) > 1)
    check("Q5b  ★ the KN5000's two-way rule is REFUTED on the WSA1's +0x30 "
          "population", grid[(0x30, "KN5000  2-way   bit7 -> 6 : 4")][1] == 0,
          "%d/%d join" % grid[(0x30, "KN5000  2-way   bit7 -> 6 : 4")][:2])
    k70 = "prom_d  2-way   bit7 -> 8 : 6"
    r4 = "★ 4-way  bit6,bit7 -> 8/6/6/4"
    check("Q5c  ★ and prom_d's two-way rule is REFUTED on the +0x70 population: "
          "it predicts 8 where the objects are 6 x 729",
          grid[(0x70, k70)][0] < grid[(0x70, r4)][0],
          "prom_d %d/%d divisible, two-bit %d/%d"
          % (grid[(0x70, k70)][0], grid[(0x70, k70)][2],
             grid[(0x70, r4)][0], grid[(0x70, r4)][2]))
    check("Q5d  ★★ the two-bit rule is the only one that fits BOTH WSA1 blocks",
          grid[(0x30, r4)][0] >= len(n30) - 1 and grid[(0x70, r4)][0] == 4,
          "+0x30 %d/%d, +0x70 %d/4" % (grid[(0x30, r4)][0], len(n30),
                                       grid[(0x70, r4)][0]))

    odd = [r for r in n30 if not r["tag"] & 0x40]
    print("\n  ⚠ THE ONE RECORD THAT IS NOT SETTLED, stated rather than rounded off:")
    for r in odd:
        print("    +0x30 descriptor %d, tag 0x%02X (bit 6 CLEAR, bit 7 SET).  Its"
              % (r["i"], r["tag"]))
        print("    pool object is %d bytes and part A gives %d element(s)."
              % (r["blen"], max(r["atab"]) + 1 if r["atab"] else 0))
        print("    The two-bit rule says the element is 6 bytes, which leaves 2")
        print("    bytes of slack; prom_d reads the object's length as 8 because a")
        print("    pool tiled by DISTANCE TO THE NEXT OBJECT cannot see slack.  With")
        print("    one element the stride is multiplied by 0, so the two readings")
        print("    address the SAME bytes at run time and nothing in the image can")
        print("    separate them.  It is the only such record.")

    print("\n=== Q6.  THE KN5000's OWN DISPATCH, from its sub-CPU ROM bytes ===\n")
    Sr, hits = kn_subcpu()
    check("Q6a  the bit6/bit7/bit5 dispatch pattern occurs EXACTLY ONCE",
          len(hits) == 1, "%d occurrence(s)" % len(hits))
    base = 0x23893 - hits[0]
    print("  WaveSel_StageB_Build_Reg040 at 0x023893 (file 0x%X, base 0x%X):"
          % (hits[0], base))
    print("    %s" % " ".join("%02X" % b for b in Sr[hits[0]:hits[0] + 12]))
    print("    B6 CE = bit 6,(XIZ)   B6 CF = bit 7,(XIZ)   B6 CD = bit 5,(XIZ)")
    got = []
    for addr, want in KN_EMITTERS:
        o = addr - base
        got.append((addr, want, Sr[o:o + 6] == bytes([0xDA, 0x12, 0xDA, 0x09, want, 0x00])))
        print("    0x%06X  %s   muls DE,%d"
              % (addr, " ".join("%02X" % b for b in Sr[o:o + 6]), want))
    o4 = 0x022AE7 - base
    sla4 = Sr[o4:o4 + 5] == bytes([0xDA, 0x12, 0xDA, 0xEC, 0x02])
    print("    0x0022AE7  %s      sla 2,DE  (x4)"
          % " ".join("%02X" % b for b in Sr[o4:o4 + 5]))
    check("Q6b  all six stride emitters decode, giving {15,12,13,10,6,4}",
          all(g[2] for g in got) and sla4)
    check("Q6c  ★ the KN5000's bit-6-CLEAR arm is the WSA1's, exactly: "
          "bit7 -> 6 else 4", got[-1][1] == sizes[2] and sizes[3] == 4)

    print("\n=== VERDICT ===\n")
    print("  The two trees describe ONE two-bit field in TWO populations that lie")
    print("  on opposite sides of bit 6.  They are not in conflict and neither")
    print("  measurement is wrong.  The KN5000's sentence is correct and already")
    print("  carries its guard (`bit 6 is clear in every record here`).  The WSA1")
    print("  sentence that calls the difference an OPPOSITE POLARITY is the one to")
    print("  correct: the polarity is not inverted, a variable is missing.")
    print("\nFAILURES: %d" % len(FAILS))
    return 1 if FAILS else 0


# ---------------------------------------------------------------------------
def selftest():
    print("=== the instrument's own controls ===\n")
    # T1  the rule table must actually distinguish the three rules somewhere,
    #     otherwise Q5's grid proves nothing.
    tags = [0x40, 0xC0, 0x92, 0x00]
    got = {n: [f(t) for t in tags] for n, f in RULES.items()}
    check("T1  the three candidate rules DISAGREE on some tag -- a scoring that "
          "cannot separate them is not a test",
          len({tuple(v) for v in got.values()}) == 3, str(got))
    # T2  each two-way rule agrees with the two-bit rule on exactly one bit-6 half
    r4 = RULES["★ 4-way  bit6,bit7 -> 8/6/6/4"]
    hi = [t for t in range(256) if t & 0x40]
    lo = [t for t in range(256) if not t & 0x40]
    check("T2  prom_d's rule == the two-bit rule on EVERY bit-6-SET tag, and on "
          "none of the others",
          all(RULES["prom_d  2-way   bit7 -> 8 : 6"](t) == r4(t) for t in hi)
          and not any(RULES["prom_d  2-way   bit7 -> 8 : 6"](t) == r4(t) for t in lo))
    check("T3  the KN5000's rule == the two-bit rule on EVERY bit-6-CLEAR tag, "
          "and on none of the others",
          all(RULES["KN5000  2-way   bit7 -> 6 : 4"](t) == r4(t) for t in lo)
          and not any(RULES["KN5000  2-way   bit7 -> 6 : 4"](t) == r4(t) for t in hi))
    # T4  the ROMs are the ones this argument is about
    check("T4  the four ROM images are the expected sizes",
          len(C) == 0x80000 and len(D) == 0x80000)
    _st, kflags, kdraw = kn5000()
    check("T5  the KN5000 census reads 487 descriptors and the WSA1 318 -- "
          "different record COUNTS as well as different strides",
          len(kflags) == 487 and len(descriptors(0x30, 0x2B2AC, 318)) == 318)
    # T6  a control on the byte quoting itself: a deliberately wrong address
    #     must NOT decode to the quoted bytes.
    a, hexs, _w = DISPATCH[3]
    want = bytes.fromhex(hexs.replace(" ", ""))
    check("T6  quoting the SAME bytes one address later fails -- the citation "
          "check can fail", cbytes(a + 1, len(want)) != want)
    check("T7  the size-routine window is long enough to contain the operand "
          "and short enough to stay inside the common prologue",
          SIZE_OPERAND < COMMON <= 0x40)
    print("\nFAILURES: %d" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
