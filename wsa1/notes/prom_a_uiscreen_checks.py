#!/usr/bin/env python3
"""Do the fourteen dispatch tables of prom_a 0xFF3800-0xFF42B1 still add up?

QUESTION IT ANSWERS
  The module banner and the fourteen table headers in prom_a/wsa1_prom_a.s make
  three kinds of quantified claim, and this script re-derives all three FROM THE
  ROM:

    1. every table's BASE is named by a `add Xrr,#imm32` or `lda_24` in the
       code, and every table's ENTRY COUNT comes from a bound in that same
       reader -- so the pair (base, count) is checkable;
    2. the tables TILE 0xFF3800-0xFF42B1 exactly: no gap, no overlap, and the
       last one ends where the module's code begins;
    3. the slot statistics -- 654 slots, 459 of them the default handler
       0xFF42B1, 112 distinct targets, 8 of which are outside the module.

  Claim 2 is the interesting one: it is an INDEPENDENT check on all fourteen
  counts at once.  If any single count were wrong the tiling would not close.

RUN
  python3 notes/prom_a_uiscreen_checks.py
Exit status is non-zero if any check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
BASE = 0xF80000
LO, HI = 0xFF3800, 0xFF42B1
DEFAULT = 0xFF42B1

FAIL = 0


def check(ok, msg):
    global FAIL
    print(("  ok   " if ok else "  FAIL ") + msg)
    if not ok:
        FAIL = 1


def long_at(a):
    return int.from_bytes(ROM[a - BASE:a - BASE + 4], "little")


# (base, entries, kind, reader) -- entries from the reader's own bound, kind is
# how the region is emitted.
TABLES = [
    (0xFF3800,  32, "long", 0xFF431C),
    (0xFF3880,  32, "long", 0xFF4596),
    (0xFF3900,  32, "long", 0xFF4995),
    (0xFF3980,  32, "long", 0xFF522F),
    (0xFF3A00,   6, "long", 0xFF548A),
    (0xFF3A18,  17, "text", 0xFF5628),
    (0xFF3A29, 192, "long", 0xFF572E),
    (0xFF3D29,   4, "long", 0xFF5C3E),
    (0xFF3D39, 192, "long", 0xFF5ED1),
    (0xFF4039,   8, "byte", 0xFF6789),
    (0xFF4041,   2, "long", 0xFF672D),
    (0xFF4049,  64, "long", 0xFF68D8),
    (0xFF4149,   2, "long", 0xFF6DB7),
    (0xFF4151,  64, "long", 0xFF6F21),
    (0xFF4251,  16, "long", 0xFF70B6),
    (0xFF4291,  16, "text", 0xFF71A5),
    (0xFF42A1,  16, "text", 0xFF744E),
]

print("1. the tables tile 0xFF3800-0xFF42B1 with no gap and no overlap")
at = LO
for b, n, kind, _ in TABLES:
    check(b == at, "0x%06X follows the previous table exactly" % b)
    at = b + (4 * n if kind == "long" else n)
check(at == HI, "the last table ends at 0x%06X, where the code begins (got "
                "0x%06X)" % (HI, at))
check(ROM[HI - BASE] == 0x0E, "0x%06X is 0x0E -- a bare `ret`, the default "
                              "handler" % HI)

print("\n2. every table base is named by a reader in the code")
sites = {}
for i in range(len(ROM) - 6):
    w = int.from_bytes(ROM[i + 2:i + 6], "little")
    if ROM[i + 1] == 0xC8 and 0xE8 <= ROM[i] <= 0xEF and LO <= w < HI:
        sites.setdefault(w, []).append(BASE + i)
    w3 = int.from_bytes(ROM[i + 1:i + 4], "little")
    if ROM[i] == 0xF2 and LO <= w3 < HI and 0x30 <= ROM[i + 4] <= 0x37:
        sites.setdefault(w3, []).append(BASE + i)
named = set(sites)
declared = {b for b, _, _, _ in TABLES}
extra = named - declared
check(declared <= named | {0xFF3F39, 0xFF3FB9},
      "every declared base is named by at least one `add Xrr,#imm32` or "
      "`lda_24` (missing %s)" % sorted("%06X" % a for a in declared - named))
check(extra == {0xFF3F39, 0xFF3FB9},
      "the only bases named but not declared are 0xFF3F39 and 0xFF3FB9, which "
      "are rows 4 and 5 of Dispatch_FF3D39 (got %s)"
      % sorted("%06X" % a for a in extra))
check(0xFF3F39 == 0xFF3D39 + 4 * 32 * 4 and 0xFF3FB9 == 0xFF3D39 + 5 * 32 * 4,
      "★ 0xFF3F39 and 0xFF3FB9 ARE rows 4 and 5 of the 0xFF3D39 matrix, "
      "arithmetically")

print("\n3. the reader bounds, read out of the ROM as text in the source")
# Each 32-entry reader carries `cp H,0x20`; each page-indexed one carries
# `cp (0x2229),#n`.  Both are quoted from the byte-exact listing.
def has(addr, needle):
    for line in SRC.split("\n"):
        m = re.match(r"^\s*(\S.*?)\s+;\s([0-9A-F]{6})\s\s", line)
        if m and int(m.group(2), 16) == addr:
            return needle in m.group(1)
    return False


for reader, addr, needle, why in (
        (0xFF431C, 0xFF4324, "cp H,0x20", "Dispatch_FF3800 = 32"),
        (0xFF4596, 0xFF459E, "cp H,0x20", "Dispatch_FF3880 = 32"),
        (0xFF4995, 0xFF499D, "cp H,0x20", "Dispatch_FF3900 = 32"),
        (0xFF522F, 0xFF5237, "cp H,0x20", "Dispatch_FF3980 = 32"),
        (0xFF548A, 0xFF548A, "0x2229, 0x06", "Dispatch_FF3A00 = 6"),
        (0xFF572E, 0xFF573B, "0x2229, 0x06", "Dispatch_FF3A29 = 6 rows"),
        (0xFF5C3E, 0xFF5C3E, "0x2229, 0x03", "Dispatch_FF3D29 = 4 (jr UGT)"),
        (0xFF5ED1, 0xFF5EDE, "0x2229, 0x05", "Dispatch_FF3D39 matrix reader"),
        (0xFF672D, 0xFF672D, "0x2229, 0x02", "Dispatch_FF4041 = 2"),
        (0xFF6DB7, 0xFF6DB7, "0x2229, 0x02", "Dispatch_FF4149 = 2"),
        (0xFF70B6, 0xFF70CF, "cp HL,0x0010", "PtrTable_FF4251 = 16")):
    check(has(addr, needle), "reader 0x%06X: `%s` at 0x%06X -- %s"
          % (reader, needle, addr, why))
check(has(0xFF5C43, "jr ugt"), "★ Dispatch_FF3D29's bound is `jr ugt`, which "
                               "ADMITS 3 -- four entries, not three")

print("\n4. slot statistics")
slots, dflt, targets = 0, 0, set()
for b, n, kind, _ in TABLES:
    if kind != "long":
        continue
    if b == 0xFF4251:          # RAM pointers, not handlers
        continue
    for k in range(n):
        v = long_at(b + 4 * k)
        slots += 1
        targets.add(v)
        if v == DEFAULT:
            dflt += 1
check(slots == 654, "654 handler slots in the twelve pointer tables (got %d)"
      % slots)
check(dflt == 459, "459 of them are the default 0xFF42B1 (got %d)" % dflt)
check(len(targets) == 112, "112 distinct targets in all of them (got %d)"
      % len(targets))
out = {t for t in targets if not (0xFF42B1 <= t < 0xFF7C65)}
check(len(out) == 8 and all(0xF42F84 <= t <= 0xF42FA0 for t in out),
      "8 targets are outside the module, all in the prom_b directory "
      "0xF42F84-0xF42FA0 (got %s)" % sorted("%06X" % t for t in out))

print("\n5. PtrTable_FF4251 is RAM pointers, and its reader says what for")
ptrs = [long_at(0xFF4251 + 4 * k) for k in range(16)]
check(all(0x7000 <= p < 0x8000 for p in ptrs),
      "all sixteen values are RAM addresses in 0x7000-0x7FFF")
steps = {ptrs[i + 1] - ptrs[i] for i in range(15)}
check(steps == {0x40, 0x80},
      "the steps between neighbours are 0x40 except one 0x80 (got %s)"
      % sorted(hex(s) for s in steps))
check(has(0xFF70C6, "0x26b2"),
      "the reader stores each pointed-at BYTE at RAM 0x26B2 + i")

print("\n6. the two text fields")
check(ROM[0xFF3A18 - BASE:0xFF3A29 - BASE] == b"??" + b" " * 14 + b"\x00",
      'Text_FF3A18 is "??" + 14 spaces + NUL, 17 bytes')
check(ROM[0xFF4291 - BASE:0xFF42A1 - BASE] == b" " * 16,
      "Text_FF4291 is 16 spaces")
check(ROM[0xFF42A1 - BASE:0xFF42B1 - BASE] == b"U1 -U2 -UD1-UD2-",
      'Text_FF42A1 is "U1 -U2 -UD1-UD2-", four four-character labels')

print("\n7. the module-variant site the emulation notes already knew")
check(has(0xFF42EE, "0xc4"),
      "0xFF42EE tests the model-variant strap (0x0000C4) -- this module owns "
      "the screen whose two display lists that strap chooses between")
for a in (0xF580B0, 0xF58127, 0xF58162, 0xF58014):
    check(("0x%06x" % a) in SRC[SRC.index("Dispatch_FF3800:"):],
          "0x%06X, a prom_b display list, is named in this module" % a)

print()
sys.exit(FAIL)
