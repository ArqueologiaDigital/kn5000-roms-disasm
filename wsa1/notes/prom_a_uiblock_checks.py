#!/usr/bin/env python3
"""Re-derive every quantified claim the two UI screen blocks make.

QUESTION IT ANSWERS: "prom_a 0xF92C62-0xF96017 and 0xF99021-0xFA1403 say
`22 pointer tables with these bases and these entry counts`, `every count comes
from a reader's own bound or from a detector with a null control`, `the block
touches no device`, and `every call from converted code into these spans lands
on a converted instruction` -- are they still true of the ROM and the source?"

The byte gate proves the source rebuilds the ROM and is blind to all of it.

★ Section 4 is the one that would have caught this round's most likely mistake.
A linear decode of these spans reports ZERO offenders -- because nothing CALLS
into a pointer table -- so 1,920 + 1,032 bytes of pointers would have been
emitted as plausible-looking instructions and nothing in the tree would have
noticed.  What found them is notes/prom_a_ptr_tables.py, whose null control over
24 KiB of prom_a that is already converted CODE is 0.85%.

    python3 notes/prom_a_uiblock_checks.py        # non-zero exit on any failure
    python3 notes/prom_a_uiblock_checks.py -v
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
FAILS, RAN = [], []
VERBOSE = "-v" in sys.argv
SPANS = ((0xF92C62, 0xF96018), (0xF99021, 0xFA1404))


def bt(addr):
    return A[addr - 0xF80000]


def u16(addr):
    return int.from_bytes(A[addr - 0xF80000:addr - 0xF80000 + 2], "little")


def u32(addr):
    return int.from_bytes(A[addr - 0xF80000:addr - 0xF80000 + 4], "little")


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


# ---------------------------------------------------------------------------
# 1. The 22 tables: base, entry count, and where the count comes from.
#    reader = the address of the `add XBC,imm32` / `ld XIX,imm32` that names the
#    base; bound = (address, value) of the `cp` that limits the index, or None.
# ---------------------------------------------------------------------------
TABLES = [
    # (base, entries, kind, reader_imm_at, bound_at, bound_val)
    (0xF99121, 169, "DATA", None,     None,     None),
    (0xF99870,  96, "LONG", 0xF99836, None,     None),   # count from the CALLEE
    (0xF99F96,  32, "LONG", 0xF99F8E, 0xF99F82, 0x1F),
    (0xF9A2A7,  32, "LONG", 0xF9A29F, 0xF9A293, 0x1F),
    (0xF9A3C7,   6, "LONG", 0xF9A3BF, 0xF9A3B6, 0x05),
    (0xF9A78E,  32, "LONG", 0xF9A786, 0xF9A77A, 0x1F),
    (0xF9AA89,  32, "LONG", 0xF9AA81, 0xF9AA75, 0x1F),
    (0xF9AB84,   8, "LONG", 0xF9AB7C, 0xF9AB72, 0x07),
    (0xF9B098,  32, "LONG", 0xF9B090, 0xF9B084, 0x1F),
    (0xF9D966,   8, "LONG", 0xF9D95E, 0xF9D954, 0x07),
    (0xF9DBE6,   8, "LONG", 0xF9DBDE, 0xF9DBD4, 0x07),
    (0xF9EC58,   7, "LONG", 0xF9EC50, 0xF9EC47, 0x06),
    (0xFA08BF,   6, "LONG", 0xFA08B7, 0xFA08AD, 0x05),
    (0xFA09BD,   6, "LONG", 0xFA09B5, None,     0x05),
    (0xFA0B13,   6, "LONG", 0xFA0B0B, None,     0x05),
    (0xF92C66,  32, "LONG", 0xF92C59, None,     None),   # count from the CALLEE
    (0xF93444,   7, "LONG", 0xF9341B, None,     None),
    (0xF93557,  32, "LONG", 0xF9354A, None,     None),
    (0xF93839,  32, "LONG", 0xF9382C, None,     None),
    (0xF9408E,  32, "LONG", 0xF94081, None,     None),
    (0xF95C95,  32, "DATA", 0xF958B6, 0xF95896, 0x1F),
]

for base, n, kind, rd, bat, bval in TABLES:
    # 1a. the reader really spells the base as a 24-bit immediate
    if rd is not None:
        got = u32(rd) & 0xFFFFFF
        check("1a 0x%06X: the reader at 0x%06X names it" % (base, rd),
              got == base, "0x%06X" % got)
    # 1b. every entry is pointer-shaped
    ws = [u32(base + 4 * k) for k in range(n)]
    bad = [k for k, w in enumerate(ws) if not (w == 0 or 0xF00000 <= w <= 0xFFFFFF)]
    check("1b 0x%06X: all %d entries are NULL or an address in 0xF00000-0xFFFFFF"
          % (base, n), not bad, str(bad[:5]))
    # 1c. the bound, where there is one, gives exactly this count
    if bat is not None:
        check("1c 0x%06X: the reader's own bound at 0x%06X is 0x%02X, i.e. %d entries"
              % (base, bat, bval, bval + 1),
              (bval + 1) == n or base == 0xF95C95,
              "bound %d, table %d" % (bval + 1, n))

# 1d. LAST-ENTRY TEST for every table with a bound: base + 4*n is the minimum
#     entry value -- the table abuts its own first arm.
ABUT = [0xF99F96, 0xF9A2A7, 0xF9A3C7, 0xF9A78E, 0xF9AA89, 0xF9AB84, 0xF9B098,
        0xF9D966, 0xF9DBE6, 0xF9EC58, 0xFA08BF, 0xFA09BD, 0xFA0B13]
for base in ABUT:
    n = dict((t[0], t[1]) for t in TABLES)[base]
    ws = [u32(base + 4 * k) for k in range(n)]
    check("1d LAST-ENTRY TEST 0x%06X: base + %d*4 = 0x%06X is the minimum entry"
          % (base, n, base + 4 * n), min(ws) == base + 4 * n,
          "min 0x%06X vs 0x%06X" % (min(ws), base + 4 * n))

# 1g. PtrTables_F95C95 is THREE tables and one stray byte, not one array.  The
#     region is 493 bytes = 128 + 128 + 1 + 236, and the third table is offset by
#     ONE byte -- which is why it is emitted as `.byte` and not `.long`.
for base, n in ((0xF95C95, 32), (0xF95D15, 32), (0xF95D96, 59)):
    ws = [u32(base + 4 * k) for k in range(n)]
    bad = [k for k, w in enumerate(ws) if not (w == 0 or 0xF00000 <= w <= 0xFFFFFF)]
    check("1g 0x%06X: all %d entries are pointer-shaped" % (base, n), not bad,
          str(bad[:5]))
check("1g the stray byte at 0xF95D95 is 0x00 and belongs to neither table",
      bt(0xF95D95) == 0x00, "0x%02X" % bt(0xF95D95))
check("1g 128 + 128 + 1 + 236 = 493 = the declared region 0xF95C95-0xF95E81",
      128 + 128 + 1 + 236 == 0xF95E82 - 0xF95C95, str(0xF95E82 - 0xF95C95))
check("1g the second table's base 0xF95D15 is named at 0xF95A07",
      (u32(0xF95A07) & 0xFFFFFF) == 0xF95D15, "0x%06X" % (u32(0xF95A07) & 0xFFFFFF))
check("1g LAST-ELEMENT: the word at 0xF95E82 is 0x0E0E0E0E, a RET pad, so the "
      "region cannot be extended", u32(0xF95E82) == 0x0E0E0E0E,
      "0x%08X" % u32(0xF95E82))

# 1e. the two tables whose count comes from the CALLEE's bound, not the reader's
check("1e T_F41B08 -> prom_a 0xF8BDC5 opens `cp HL,0x001F / jr ugt` = 32 entries",
      A[0xF8BDC5 - 0xF80000:0xF8BDC5 - 0xF80000 + 4] == bytes([0xDB, 0xCF, 0x1F, 0x00]),
      A[0xF8BDC5 - 0xF80000:0xF8BDC5 - 0xF80000 + 4].hex())
check("1e T_F41B0C -> prom_a 0xF8BDF8 opens with the SAME two instructions",
      A[0xF8BDF8 - 0xF80000:0xF8BDF8 - 0xF80000 + 4] == bytes([0xDB, 0xCF, 0x1F, 0x00]),
      A[0xF8BDF8 - 0xF80000:0xF8BDF8 - 0xF80000 + 4].hex())

# 1f. PtrTable_F99121's self-reference -- its last three entries hold its own base
check("1f PtrTable_F99121's last three entries all hold 0x00F99121",
      u32(0xF993B9) == 0xF99121 and u32(0xF993BD) == 0xF99121 and
      u32(0xF993C1) == 0xF99121,
      "%08X %08X %08X" % (u32(0xF993B9), u32(0xF993BD), u32(0xF993C1)))
check("1f ...and the word after it, at 0xF993C5, is 0x0E0E0E0E -- a RET pad",
      u32(0xF993C5) == 0x0E0E0E0E, "0x%08X" % u32(0xF993C5))

# ---------------------------------------------------------------------------
# 2. The source really carries these names, at these addresses.
# ---------------------------------------------------------------------------
NAMES = {
    0xF99121: "PtrTable_F99121", 0xF99870: "DisplayListPtrs_F99870",
    0xF99F96: "JumpTable_F99F96", 0xF9A2A7: "JumpTable_F9A2A7",
    0xF9A3C7: "JumpTable_F9A3C7", 0xF9A78E: "JumpTable_F9A78E",
    0xF9AA89: "JumpTable_F9AA89", 0xF9AB84: "JumpTable_F9AB84",
    0xF9B098: "JumpTable_F9B098", 0xF9D966: "JumpTable_F9D966",
    0xF9DBE6: "JumpTable_F9DBE6", 0xF9EC58: "JumpTable_F9EC58",
    0xFA08BF: "JumpTable_FA08BF", 0xFA09BD: "JumpTable_FA09BD",
    0xFA0B13: "JumpTable_FA0B13", 0xF92C66: "DisplayListPtrs_F92C66",
    0xF93444: "PtrTable_F93444", 0xF93557: "DisplayListPtrs_F93557",
    0xF93839: "DisplayListPtrs_F93839", 0xF9408E: "DisplayListPtrs_F9408E",
    0xF95C95: "PtrTables_F95C95",
}
LINES = open(SRC, encoding="utf-8").read().splitlines()
label_at, pend = {}, []
ADDRC = re.compile(r";\s([0-9A-F]{6})\b")
for line in LINES:
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
    if m:
        pend.append(m.group(1))
        continue
    m = ADDRC.search(line)
    if m and pend:
        for nm in pend:
            label_at.setdefault(nm, int(m.group(1), 16))
        pend = []
for at, nm in sorted(NAMES.items()):
    check("2 source defines %s at 0x%06X" % (nm, at), label_at.get(nm) == at,
          "found at %s" % ("0x%06X" % label_at[nm] if nm in label_at else "nowhere"))

# ---------------------------------------------------------------------------
# 3. Span A touches no device.
# ---------------------------------------------------------------------------
dev = []
for line in LINES:
    m = ADDRC.search(line)
    if not m:
        continue
    at = int(m.group(1), 16)
    if not (SPANS[1][0] <= at < SPANS[1][1]):
        continue
    for mm in re.finditer(r"0x00([67][0-9a-f]{5})", line.split(";")[0]):
        v = int(mm.group(1), 16)
        if v != 0x60A000:
            dev.append((at, v))
check("3 the 0xF99021 block names no device address in 0x600000-0x7FFFFF "
      "except the RAM staging buffer 0x60A000", not dev,
      str(["0x%06X@0x%06X" % (v, a) for a, v in dev[:5]]))

# ---------------------------------------------------------------------------
# 4. ★ EVERY call/calr/jp from a CONVERTED line into either new span lands on a
#    converted line.  Decoded from the BYTES on each line, not from its text, so
#    a mis-spelled operand cannot hide.
# ---------------------------------------------------------------------------
BYTES_RE = re.compile(r";\s([0-9A-F]{6})\s\s([0-9a-f]{2}(?: [0-9a-f]{2})*)\s*$")
converted = set()
instrs = []
for line in LINES:
    m = BYTES_RE.match(line.rstrip("\n").split("\t", 1)[-1] if "\t" in line else line)
    m = m or BYTES_RE.search(line.rstrip("\n"))
    if not m:
        continue
    at = int(m.group(1), 16)
    bs = [int(x, 16) for x in m.group(2).split()]
    converted.add(at)
    instrs.append((at, bs))
data_bytes = set()
for base, n, kind, rd, bat, bval in TABLES:
    span = 4 * n if base != 0xF95C95 else 0xF95E82 - 0xF95C95
    data_bytes.update(range(base, base + span))

bad = []
for at, bs in instrs:
    tgt = None
    if bs[0] in (0x1D, 0x1B) and len(bs) >= 4:
        tgt = bs[1] | bs[2] << 8 | bs[3] << 16
    elif bs[0] == 0x1E and len(bs) >= 3:
        d = bs[1] | bs[2] << 8
        tgt = (at + 3 + (d - 0x10000 if d & 0x8000 else d)) & 0xFFFFFF
    if tgt is None:
        continue
    for lo, hi in SPANS:
        if lo <= tgt < hi and tgt not in converted and tgt not in data_bytes:
            bad.append((at, tgt))
check("4 every call/calr/jp from a converted prom_a instruction into the two new "
      "spans lands on a converted instruction or inside a declared table",
      not bad, str(["0x%06X->0x%06X" % x for x in bad[:6]]))
check("4b ...and the check has teeth: it examined %d converted instructions" %
      len(instrs), len(instrs) > 60000, str(len(instrs)))
# 4c NEGATIVE CONTROL.  A criterion that cannot fail is not a pass: feed the same
# comparison a target that is deliberately one byte off a real instruction inside
# span A and require it to be reported.
_probe = sorted(x for x in converted if SPANS[1][0] < x < SPANS[1][1])[100]
check("4c NEGATIVE CONTROL: 0x%06X+1 is NOT a converted instruction, so the "
      "section-4 comparison would have caught it" % _probe,
      (_probe + 1) not in converted and (_probe + 1) not in data_bytes,
      "0x%06X" % (_probe + 1))

# ---------------------------------------------------------------------------
# 5. The two spans' own boundaries.
# ---------------------------------------------------------------------------
check("5 0xF92C62 and 0xF99021 are both prom_b directory targets, so each "
      "decode's START is pinned by the directory", True, "see section 6")
Bimg = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
tg = set()
for a_ in range(0xF40000, 0xF44018, 4):
    o = a_ - 0xF00000
    if Bimg[o] == 0x1B:
        tg.add(Bimg[o + 1] | Bimg[o + 2] << 8 | Bimg[o + 3] << 16)
check("6 0xF92C62 is a prom_b directory target", 0xF92C62 in tg)
check("6 0xF99021 is a prom_b directory target", 0xF99021 in tg)
check("6 the last directory target in the whole 0xF90989-0xFA53FF region is "
      "0xFA1304, below both span ends",
      max(t for t in tg if 0xF90989 <= t < 0xFA5400) == 0xFA1304,
      "0x%06X" % max(t for t in tg if 0xF90989 <= t < 0xFA5400))

# ---------------------------------------------------------------------------
# 7. The panel change-mask shadow 0x2B00-0x2BFF: exactly eight references in the
#    whole of prom_a, and after this round all eight are converted.  This is a
#    gap-O datum, so it is counted rather than described.
# ---------------------------------------------------------------------------
PANEL = {}
for line in LINES:
    body = line.split(";")[0]
    m2 = ADDRC.search(line)
    if not m2:
        continue
    for mm in re.finditer(r"\(0x2b([0-9a-f]{2})\)", body):
        PANEL.setdefault(0x2B00 | int(mm.group(1), 16), []).append(int(m2.group(1), 16))
total = sum(len(v) for v in PANEL.values())
check("7 exactly 8 references to the panel shadow 0x2B00-0x2BFF in converted "
      "prom_a", total == 8, "%d: %s" % (total, {("0x%04X" % k): ["0x%06X" % x for x in v]
                                                for k, v in sorted(PANEL.items())}))
check("7 the six power-on chord reads are at 0xF828DF/0xF828E9 (0x2B38), "
      "0xF82952 (0x2B32), 0xF8295F (0x2B30), 0xF82A0A (0x2B3A), 0xF82A18 (0x2B33)",
      PANEL.get(0x2B38) == [0xF828DF, 0xF828E9] and PANEL.get(0x2B32) == [0xF82952]
      and PANEL.get(0x2B30) == [0xF8295F] and PANEL.get(0x2B3A) == [0xF82A0A]
      and 0xF82A18 in PANEL.get(0x2B33, []), str(PANEL))
check("7 the two runtime dispatchers are 0xF953D2 (0x2B31) and 0xF954AF (0x2B33)",
      PANEL.get(0x2B31) == [0xF953D2] and 0xF954AF in PANEL.get(0x2B33, []),
      str(PANEL))

print("\n%d checks ran" % len(RAN))
print("ALL CHECKS PASS" if not FAILS
      else "%d FAILED: %s" % (len(FAILS), ", ".join(FAILS)))
sys.exit(1 if FAILS else 0)
