#!/usr/bin/env python3
"""LANE REVIEW-WB, round 10: does the evidence carry prom_b's new round-10 prose?

Every number this reviewer reported is produced here.  Run from the repo root:
    python3 review_wb_round10.py

QUESTIONS ANSWERED, in order of the checks below
  1. Is prom_a sub_F8A088 really "the ONLY consumer" of the SC1 inbound queue at
     RAM 0x2B40, as prom_b/wsa1_prom_b.s:98483 states?          -> NO.
  2. Do the six cited direct readers of the 0x2B20 shadow pair with the cells
     the header names?                                          -> YES, 6/6.
  3. Does PanelWireGroupMap map wires 0xC0-0xCA to groups 0x00-0x0A "Variant1/2"
     as prom_b/wsa1_prom_b.s:98488 states?                      -> V1 yes, V2 NO.
  4. Do the two template pointer tables, the 27 entries, and the 40-list tiling
     reproduce from the walker's own immediates?                -> YES.
  5. Does the button-table prediction test reproduce?            -> YES, exactly.
  6. Is the (0x209B)/(0x209C) literal census right, and is PanelButton_Accept
     the only reader of that pair?                              -> census YES,
     sole-reader NO (second reader pair at 0xF86874/0xF8687A).
  7. Is the prom_a 0xF8A44B / 0xF8A84B copy report exact?        -> YES, 9 bytes.
"""
import os, collections, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
if not os.path.isdir(os.path.join(ROOT, "original_ROMs")):
    ROOT = "/home/fsanches/compartilhado/wsa1-roms-disasm"
IM = {"a": ("wsa1_prom_a.ic12", 0xF80000), "b": ("wsa1_prom_b.ic13", 0xF00000),
      "c": ("wsa1_prom_c.ic28", 0xF80000), "d": ("wsa1_prom_d.bin", 0)}
D = {k: (open(os.path.join(ROOT, "original_ROMs", v[0]), "rb").read(), v[1])
     for k, v in IM.items()}
A, BA = D["a"]
def a8(x):  return A[x - BA]
def aw(x):  return int.from_bytes(A[x - BA:x - BA + 4], "little")
def abs_(x, n): return A[x - BA:x - BA + n]

print("1) CONSUMERS of the queue at RAM 0x2B40 -- `ld XIZ/XHL,0x00002B40`")
for k in ("a", "b"):
    d, B = D[k]
    hits = []
    i = d.find(b"\x40\x2b\x00\x00")
    while i >= 0:
        hits.append(B + i - 1); i = d.find(b"\x40\x2b\x00\x00", i + 1)
    print("   prom_%s: %s" % (k, ", ".join("0x%06X" % h for h in hits)))
print("   prom_a 0xF8A088:", abs_(0xF8A088, 8).hex(" "))
print("   prom_a 0xF94E1C:", abs_(0xF94E1C, 16).hex(" "))
print("   0xF94E1C commits the read index back at 0xF94ED0:",
      abs_(0xF94ED0, 3).hex(" "), "(ld (XIZ+0x06),IX)")
print("   and it is called: prom_a 0xF956A6 =", abs_(0xF956A6, 4).hex(" "),
      "(call 0x00F94E1C)")
print("   => 'It is the ONLY consumer' is FALSE.\n")

print("2) the six cited direct readers of the 0x2B20 shadow")
for addr, cell in ((0xF8295F, 0x2B30), (0xF953D2, 0x2B31), (0xF82952, 0x2B32),
                   (0xF82A18, 0x2B33), (0xF828DF, 0x2B38), (0xF82A0A, 0x2B3A)):
    got = a8(addr + 1) | (a8(addr + 2) << 8)
    print("   0x%06X %s -> (0x%04X) %s" % (addr, abs_(addr, 4).hex(" "), got,
                                           "OK" if got == cell else "MISMATCH"))
print()

print("3) PanelWireGroupMap wire -> group, index = (w&0x1F) | ((w&0xC0)>>1)")
for name, base in (("Variant1 0xF8A109", 0xF8A109), ("Variant2 0xF8A189", 0xF8A189)):
    row = " ".join("%02X:%02X" % (w, a8(base + ((w & 0x1F) | ((w & 0xC0) >> 1))))
                   for w in range(0xC0, 0xCB))
    print("   %-18s %s" % (name, row))
print("   => 'wires 0xC0-0xCA are groups 0x00-0x0A' holds for Variant 1 only;")
print("      Variant 2 gives 0xC6->0x20, 0xC7->06, 0xC8->07, 0xC9->08, 0xCA->0x20.\n")

t1, t2 = aw(0xF8A84D), aw(0xF8A858)
n = (t2 - t1) // 4
def recs(base, g):
    p = aw(base + 4 * g); out = []
    while a8(p) != 0xFF:
        out.append(tuple(abs_(p, 4))); p += 4
    return out, p + 1
print("4) template tables from the walker's own immediates")
print("   0xF8A84C:", abs_(0xF8A84C, 5).hex(" "), "-> 0x%06X" % t1)
print("   0xF8A857:", abs_(0xF8A857, 5).hex(" "), "-> 0x%06X" % t2)
print("   entries per table = (t2-t1)/4 =", n, "; walker bound `cp A,0x18` at 0xF8A83B:",
      abs_(0xF8A83B, 4).hex(" "))
ends = {}
for base in (t1, t2):
    for g in range(n):
        p = aw(base + 4 * g); ends[p] = recs(base, g)[1]
o = sorted(ends)
gaps = [(p, ends[p], q) for p, q in zip(o, o[1:]) if ends[p] != q]
print("   distinct lists = %d, span 0x%06X..0x%06X, gaps/overlaps = %s"
      % (len(o), o[0], ends[o[-1]], gaps or "NONE"))
tw = collections.defaultdict(list)
for g in range(n):
    r, _ = recs(t1, g)
    if r: tw[bytes(b for x in r for b in x)].append(g)
print("   variant 1 byte-identical group pairs:", [v for v in tw.values() if len(v) > 1])
tw2 = collections.defaultdict(list)
for g in range(n):
    r, _ = recs(t2, g)
    if r: tw2[bytes(b for x in r for b in x)].append(g)
print("   variant 2 byte-identical group pairs:",
      [v for v in tw2.values() if len(v) > 1] or "NONE")
print()

print("5) the prediction test, recomputed from scratch on the 32 tables at 0xF7D2D8")
LO, HI, ST = 0xF7D2D8, 0xF7E2D8, 0x80
Bimg, BB = D["b"]
def b_8(x):  return Bimg[x - BB]
def b_w(x):  return int.from_bytes(Bimg[x - BB:x - BB + 4], "little")
occ = collections.Counter()
for i in range((HI - LO) // ST):
    t = LO + ST * i
    for k in range(32):
        tgt = b_w(t + 4 * k)
        if (A[tgt - BA] if tgt >= 0xF80000 else Bimg[tgt - BB]) != 0x0E:
            occ[k] += 1
em = {c for base in (t1, t2) for g in range(n)
      for cls, c, f, m in recs(base, g)[0] if cls == 0xA9}
print("   all 16 slots 0x00-0x0F filled:", all(occ[k] > 0 for k in range(16)))
print("   of those 16, emitted by a template:", sum(1 for k in range(16) if k in em))
print("   slots handled by all 32 screens:", ["%02X" % k for k in range(32) if occ[k] == 32])
print("   hole (filled, never emitted):",
      ["%02X" % k for k in range(32) if occ[k] and k not in em])
print("   emitted, no screen:", ["%02X" % c for c in sorted(em) if c < 0x20 and not occ[c]])
print("   class 0xA8 codes in the templates:",
      sorted({"%02X" % c for base in (t1, t2) for g in range(n)
              for cls, c, f, m in recs(base, g)[0] if cls == 0xA8}))
print()

print("6) (0x209B)/(0x209C): every immediate, and every reader")
vals = collections.Counter()
for cell in (0x209B, 0x209C):
    lo, hi = cell & 0xFF, cell >> 8
    for k in ("a", "b", "c"):
        d, B = D[k]
        for i in range(1, len(d) - 8):
            if d[i] == lo and d[i + 1] == hi and d[i + 2] == 0x00:
                if d[i - 1] == 0xF1: vals[d[i + 3]] += 1
                elif d[i - 1] == 0xD1:
                    v = d[i + 3] | (d[i + 4] << 8); vals[v & 0xFF] += 1; vals[v >> 8] += 1
print("   immediates:", " ".join("%02X" % v for v in sorted(vals)))
print("   max under `and L,0x1f` = 0x%02X  => cannot reach 0x11-0x19: refutation HOLDS"
      % max(v & 0x1F for v in vals))
for cell in (0x209B, 0x209C):
    lo, hi = cell & 0xFF, cell >> 8
    for i in range(1, len(A) - 6):
        if A[i] == lo and A[i + 1] == hi and A[i - 1] == 0xC1 and A[i + 2] in (0x20, 0x23):
            print("   READ (0x%04X) at 0x%06X: %s" % (cell, BA + i - 1, abs_(BA + i - 1, 4).hex(" ")))
print("   0xF86874/0xF8687A feed `calr 0xF861AC` (inside PanelButton_Route) at 0xF8687E:",
      abs_(0xF8687E, 3).hex(" "))
print()

print("7) the prom_a 0xF8A44B / 0xF8A84B copy report")
x, y = abs_(0xF8A44B, 78), abs_(0xF8A84B, 78)
diff = [i for i in range(78) if x[i] != y[i]]
print("   differing bytes:", len(diff), "at offsets", diff)
print("   0xF8A486:", abs_(0xF8A486, 2).hex(" "), "(jr -90 -> 0xF8A42E);",
      "0xF8A42D is a 5-byte", abs_(0xF8A42D, 5).hex(" "))
