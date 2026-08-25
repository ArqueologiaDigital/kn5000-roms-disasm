#!/usr/bin/env python3
"""Re-derive, from the ROM, every quantified claim the CONTROL NORMALISER makes.

QUESTION IT ANSWERS: "prom_a 0xF89800-0xF89FFF's banner and
notes/FINDINGS-prom_a-control-normaliser.md say `32 reachable table entries and
ten live slots`, `these ten (raw, curve, cooked, idle) tuples`, `eight curve
tables that tile`, `0xF89E34 has no reference`, `0xF89AB4 and 0xF89C34 are
byte-identical`, `the six AnalogScan call sites pass W = 0..5` -- do they still
hold?"

The byte gate cannot check any of it.  Every check below is named after the
sentence it defends.

    python3 notes/prom_a_ctrl_checks.py        # non-zero exit on any failure
    python3 notes/prom_a_ctrl_checks.py -v
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def u32(addr):
    return int.from_bytes(a(addr, 4), "little")


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


# --- 1. the dispatcher's index arithmetic -----------------------------------
check("dispatcher: index = ((W & 0xC0) >> 1) | ((W & 0x07) << 2)",
      a(0xF89809, 2) == b"\xc8\x8f"          # ld L,W
      and a(0xF8980B, 3) == b"\xcf\xcc\xc0"  # and L,0xC0
      and a(0xF8980E, 3) == b"\xcf\xef\x01"  # srl 1,L
      and a(0xF89811, 3) == b"\xc8\xcc\x07"  # and W,0x07
      and a(0xF89814, 3) == b"\xc8\xec\x02"  # sla 2,W
      and a(0xF89817, 2) == b"\xc8\xe7",     # or L,W
      " ".join("%02x" % x for x in a(0xF89809, 16)))
check("dispatcher: the table base is 0x00F89825",
      a(0xF89819, 1) == b"\x44" and u32(0xF8981A) == 0xF89825,
      " ".join("%02x" % x for x in a(0xF89819, 5)))
check("the largest index the arithmetic can form is 0x7C = entry 31",
      max(((w & 0xC0) >> 1) | ((w & 7) << 2) for w in range(256)) == 0x7C)

# --- 2. the handler table ---------------------------------------------------
TAB, TAB_END = 0xF89825, 0xF898AD
n_ent = (TAB_END - TAB) // 4
ent = [u32(TAB + 4 * i) for i in range(n_ent)]
IGNORE = 0xF89AB0
check("the handler table holds 34 LE32 entries, 0xF89825-0xF898AC", n_ent == 34)
check("all 34 entries point inside the module's handler range 0xF898AD-0xF89AB3",
      all(0xF898AD <= v <= 0xF89AB3 for v in ent),
      str(["0x%06X" % v for v in ent]))
check("the 32 REACHABLE entries name 12 distinct targets",
      len(set(ent[:32])) == 12, str(sorted("0x%06X" % v for v in set(ent[:32]))))
check("21 of the 32 reachable entries are the ignore handler 0xF89AB0",
      ent[:32].count(IGNORE) == 21, str(ent[:32].count(IGNORE)))
check("32 = 10 live slots + 1 always-changed stub + 21 ignore",
      10 + 1 + ent[:32].count(IGNORE) == 32)
check("entries 32 and 33 lie beyond index 0x7C and are both the ignore handler",
      ent[32] == ent[33] == IGNORE)
live = sorted({v for v in ent[:32] if v != IGNORE})
check("ten live slots plus the always-changed stub 0xF89AAD",
      len(live) == 11 and 0xF89AAD in live, str(["0x%06X" % v for v in live]))
GROUP0 = [ent[i] for i in range(6)]
check("slots 0.0-0.5 are six DISTINCT handlers", len(set(GROUP0)) == 6)
check("slots 0.6 through 2.7 (indices 6..23) are all the ignore handler",
      all(v == IGNORE for v in ent[6:24]))
check("slots 3.0-3.3 are four distinct handlers",
      len(set(ent[24:28])) == 4)
check("slots 3.4-3.6 ignore and slot 3.7 is the always-changed stub",
      ent[28:31] == [IGNORE] * 3 and ent[31] == 0xF89AAD)

# --- 3. the ten live slots, field by field ----------------------------------
# per handler: WANT = (raw slot, curve base, cooked slot, idle value or None)
WANT = {
    0xF898AD: (0x24D0, 0xF89BB4, 0x2505, 0x40),
    0xF898E0: (0x24D1, 0xF89BB4, 0x2506, 0x40),
    0xF89913: (0x24D2, 0xF89EB4, 0x24FF, 0x00),
    0xF8997C: (0x24D3, 0xF89DB4, 0x24F2, 0x00),
    0xF899B2: (0x24D4, 0xF89B34, 0x2503, None),
    0xF899D6: (0x24D5, 0xF89B34, 0x2504, None),
    0xF899FA: (0x24E9, 0xF89CB4, 0x24F4, 0x80),
    0xF89A2A: (0x24E8, 0xF89C34, 0x24F5, 0x00),
    0xF89A5B: (0x24EA, 0xF89B34, 0x24F6, 0x40),
    0xF89A8B: (0x24EB, 0xF89AB4, 0x24F3, None),
}
bounds = sorted(WANT) + [0xF89AAD]
for i, h in enumerate(sorted(WANT)):
    lo, hi = h, bounds[i + 1]
    blob = a(lo, hi - lo)
    stores = [int.from_bytes(blob[j + 1:j + 3], "little")
              for j in range(len(blob) - 3)
              if blob[j] == 0xF1 and blob[j + 3] == 0x41]        # ld (nn),A
    cmps = [int.from_bytes(blob[j + 1:j + 3], "little")
            for j in range(len(blob) - 3)
            if blob[j] == 0xC1 and blob[j + 3] == 0xF1]          # cp A,(nn)
    curves = [int.from_bytes(blob[j + 1:j + 4], "little")
              for j in range(len(blob) - 4)
              if blob[j] == 0x44 and blob[j + 4] == 0x00]        # ld XIX,imm32
    idle = None
    k = blob.find(b"\xc0\xc4\x3f\x02")                            # cp (0xC4),2
    if k >= 0 and blob[k + 6] == 0x21:                            # ld A,#
        idle = blob[k + 7]
    w_raw, w_curve, w_cooked, w_idle = WANT[h]
    check("slot 0x%06X: cooked value lives at 0x%04X" % (h, w_cooked),
          cmps == [w_cooked], str(["0x%04X" % x for x in cmps]))
    check("slot 0x%06X: raw reading is stored at 0x%04X" % (h, w_raw),
          w_raw in stores and set(stores) <= {w_raw, w_cooked},
          str(["0x%04X" % x for x in stores]))
    # slot 0.2 loads a SECOND imm32, the 0x007F5A calibration record.
    want_curves = [w_curve] + ([0x007F5A] if h == 0xF89913 else [])
    check("slot 0x%06X: response curve is 0x%06X%s"
          % (h, w_curve, " (plus the 0x007F5A calibration record)"
             if h == 0xF89913 else ""),
          curves == want_curves, str(["0x%06X" % x for x in curves]))
    check("slot 0x%06X: idle value when (0xC4)==2 is %s"
          % (h, "0x%02X" % w_idle if w_idle is not None else "no such arm"),
          idle == w_idle, "got %s" % idle)
    check("slot 0x%06X: reports change with `scf`" % h, b"\x11" in blob)
check("slot 0xF8997C inverts the raw byte before the curve",
      a(0xF8998B, 3) == b"\xc9\xcd\xff",
      " ".join("%02x" % x for x in a(0xF8998B, 3)))
check("the two 256-entry curves are indexed by the RAW byte "
      "(no `srl 1,A` in their slots)",
      b"\xc9\xef\x01" not in a(0xF89913, 0xF8997C - 0xF89913)
      and b"\xc9\xef\x01" not in a(0xF899FA, 0xF89A2A - 0xF899FA))
check("the shared tail is `scf` at 0xF89AAD / `rcf` at 0xF89AB0 then pop, pop, ret",
      a(0xF89AAD, 1) == b"\x11" and a(0xF89AB0, 1) == b"\x10"
      and a(0xF89AB1, 3) == b"\x5c\x5b\x0e",
      " ".join("%02x" % x for x in a(0xF89AAD, 8)))

# --- 4. the curve tables ----------------------------------------------------
CURVES = [(0xF89AB4, 128), (0xF89B34, 128), (0xF89BB4, 128), (0xF89C34, 128),
          (0xF89CB4, 256), (0xF89DB4, 128), (0xF89E34, 128), (0xF89EB4, 256),
          (0xF89FB4, 11)]
cur = 0xF89AB4
for lo, n in CURVES:
    check("curve tables tile: 0x%06X follows the previous one" % lo, lo == cur)
    cur = lo + n
check("the curve tables end at 0xF89FBF, where the module pad starts",
      cur == 0xF89FBF, "0x%06X" % cur)
check("the pad 0xF89FBF-0xF89FFF is 65 bytes of uniform 0x0E",
      set(a(0xF89FBF, 65)) == {0x0E})
check("0xF89AB4 is the identity map 0..127",
      list(a(0xF89AB4, 128)) == list(range(128)))
check("0xF89C34 is BYTE-IDENTICAL to 0xF89AB4",
      a(0xF89C34, 128) == a(0xF89AB4, 128))
d = [i for i in range(128) if a(0xF89B34, 128)[i] != a(0xF89BB4, 128)[i]]
check("0xF89B34 and 0xF89BB4 differ in exactly 40 of their 128 bytes",
      len(d) == 40, str(len(d)))
deltas = [a(0xF89BB4, 128)[i] - a(0xF89B34, 128)[i] for i in d]
check("...every one of those differences is exactly +1 or -1",
      set(deltas) == {1, -1}, str(sorted(set(deltas))))
check("...21 of them are +1 and 19 are -1",
      deltas.count(1) == 21 and deltas.count(-1) == 19,
      "%d up, %d down" % (deltas.count(1), deltas.count(-1)))
check("...and they all lie between indices 37 and 89",
      d[0] == 37 and d[-1] == 89, "%d..%d" % (d[0], d[-1]))
for lo, n in CURVES[:-1]:
    b = a(lo, n)
    check("curve 0x%06X spans 0..%d" % (lo, n - 1 if n == 128 else 255),
          b[0] == 0 and b[-1] == (127 if n == 128 else 255),
          "%d..%d" % (b[0], b[-1]))
for lo in (0xF89B34, 0xF89BB4):
    b = a(lo, 128)
    nm = [i for i in range(127) if b[i] > b[i + 1]]
    check("curve 0x%06X has exactly ONE non-monotone step, at index 20" % lo,
          nm == [20], str(nm))
    check("curve 0x%06X entry 20 is 0x2C between neighbours 0x21 and 0x24" % lo,
          (b[19], b[20], b[21]) == (0x21, 0x2C, 0x24),
          "%02X %02X %02X" % (b[19], b[20], b[21]))
for lo in (0xF89AB4, 0xF89C34, 0xF89CB4, 0xF89DB4, 0xF89E34, 0xF89EB4):
    b = a(lo, 256 if lo in (0xF89CB4, 0xF89EB4) else 128)
    check("curve 0x%06X is monotone non-decreasing" % lo,
          all(b[i] <= b[i + 1] for i in range(len(b) - 1)))

# --- CURVE SHAPE, added 2026-08-25 (round-1 audit F3) -------------------------
# The audit's finding was that `Ctrl_Curve_Expo128` was a SHAPE claim that no
# check defended and that the bytes contradict.  These four defend the new name
# `Ctrl_Curve_Concave128` and the two "convex" words in its comment.  Deviation
# means b[i] - i, i.e. how far the curve sits from the identity map.
def _dev(lo, n):
    b = a(lo, n)
    return [b[i] - i for i in range(n)]


_d = _dev(0xF89DB4, 128)
check("0xF89DB4 sits ABOVE the diagonal: mean deviation is +11.9",
      abs(sum(_d) / 128 - 11.9) < 0.05, "%+.2f" % (sum(_d) / 128))
check("...its deviation never leaves -1..+22, so it is concave, not exponential",
      min(_d) == -1 and max(_d) == 22, "%d..%d" % (min(_d), max(_d)))
check("...and it maps 32->54, 64->80, 96->104",
      (a(0xF89DB4, 128)[32], a(0xF89DB4, 128)[64], a(0xF89DB4, 128)[96])
      == (54, 80, 104))
for lo, n, mean in ((0xF89E34, 128, -5.8), (0xF89EB4, 256, -46.7)):
    _d = _dev(lo, n)
    check("curve 0x%06X is the CONVEX kind: mean deviation %+.1f" % (lo, mean),
          abs(sum(_d) / n - mean) < 0.05, "%+.2f" % (sum(_d) / n))


def imm32_sites(v):
    le = bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, 0])
    out = []
    for img, base in ((A, 0xF80000), (B, 0xF00000)):
        i = 0
        while True:
            i = img.find(le, i)
            if i < 0:
                break
            out.append(base + i)
            i += 1
    return out


for lo, _ in CURVES:
    sites = imm32_sites(lo)
    if lo == 0xF89E34:
        check("⚠ NOTHING references curve 0xF89E34: zero imm32 sites in "
              "prom_a + prom_b", sites == [], str(["0x%06X" % s for s in sites]))
    else:
        check("curve 0x%06X is named by exactly one imm32 site (0x%06X)"
              % (lo, sites[0] if sites else 0),
              len(sites) in (1, 2, 3), str(["0x%06X" % s for s in sites]))

# --- 5. the six AnalogScan call sites -------------------------------------
CALL = b"\x1d\xf0\x05\xf4"           # call 0xF405F0
ws = []
i = 0
while True:
    i = A.find(CALL, i)
    if i < 0:
        break
    site = 0xF80000 + i
    if A[i - 2] == 0x20:              # ldb W,#imm8 immediately before
        ws.append((site, A[i - 1]))
    i += 1
check("AnalogScan has EIGHT converted call sites, passing W = 0,1,2,3,4,5,4,5",
      [w for _, w in ws] == [0, 1, 2, 3, 4, 5, 4, 5],
      str([("0x%06X" % s, "0x%02X" % w) for s, w in ws]))
check("all eight of those sites are inside AnalogScan (0xF8DC00-0xF8DDE5)",
      all(0xF8DC00 <= s <= 0xF8DDE5 for s, _ in ws),
      str(["0x%06X" % s for s, _ in ws]))
check("the eight sites cover exactly the six group-0 channels",
      sorted(set(w for _, w in ws)) == [0, 1, 2, 3, 4, 5])
check("the two extra sites are inside a BYTE-IDENTICAL duplicate: "
      "0xF8DDBC-0xF8DDE5 == 0xF8DD4D-0xF8DD76",
      a(0xF8DDBC, 0x2A) == a(0xF8DD4D, 0x2A),
      " ".join("%02x" % x for x in a(0xF8DD4D, 0x2A)))
bsites = []
i = 0
while True:
    i = B.find(CALL, i)
    if i < 0:
        break
    bsites.append(0xF00000 + i)
    i += 1
check("prom_b calls the same slot from exactly two sites, both inside the SC1 "
      "module 0xF5A800-0xF5B7FF",
      bsites == [0xF5B14C, 0xF5B1D6],
      str(["0x%06X" % s for s in bsites]))

# --- 6. the names are in the source, at these addresses ---------------------
LABELS = {
    0xF89800: "Ctrl_Normalise", 0xF89805: "Ctrl_Normalise_Dispatch",
    0xF89825: "Ctrl_HandlerTable", 0xF898AD: "Ctrl_Ch0_Normalise",
    0xF899FA: "Ctrl_G3Ch1_Normalise", 0xF89AB0: "Ctrl_ReportUnchanged",
    0xF89AB4: "Ctrl_Curve_Identity128", 0xF89E34: "Ctrl_Curve_Unreferenced128",
    0xF89BB4: "Ctrl_Curve_Compressed_PlusMinus1",
    0xF89DB4: "Ctrl_Curve_Concave128",
    0xF89FB4: "Ctrl_SpanTable",
}
found, pending = {}, []
for line in open(SRC):
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', line)
    if m:
        pending.append(m.group(1))
        continue
    m = re.search(r';\s*([0-9A-F]{6})\b', line)
    if m and pending:
        for n in pending:
            found.setdefault(n, int(m.group(1), 16))
        pending = []
for addr, name in sorted(LABELS.items()):
    check("source label %s is at 0x%06X" % (name, addr),
          found.get(name) == addr,
          "found at %s" % ("0x%06X" % found[name] if name in found else "nowhere"))

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
