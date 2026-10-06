#!/usr/bin/env python3
"""Name the unnamed entries of prom_b's two screen-code paint tables.

QUESTION IT ANSWERS
  prom_a repaints a screen through two prom_b selectors with a SCREEN CODE argument
  (notes/FINDINGS-l7a1429-editor-pages.md, section 2c):
    Dispatch_Code80_Bracketed -> Dispatch_Code80_PaintTable[code - 0x80]  the FULL paint (display bracket)
    Dispatch_Code80           -> Dispatch_Code80_RepaintFieldTable[code - 0x80]  the PARTIAL repaint
  both 48 entries for codes 0x80..0xAF, codes 0xC0.. reusing 0xA0.. .  Their named entries already
  follow that split (SoundEditController_PaintPage1 / _RepaintFieldPage1, SoundEditCopy_Paint /
  _RepaintField ...).  This names the rest the same way:
    F5B8F8 entry for code XX -> ScreenCode<XX>_Paint
    F5B9F8 entry for code XX -> ScreenCode<XX>_RepaintField
  except codes 0xA0-0xA7, the MODELING pages, which prom_a already calls ToneEditPage_A<k>_*
  (ToneEditPage_A3_PositionParameter ...): those become ToneEditPage_A<k>_Paint / _RepaintField.
  A routine in several slots of one table is named after its first code; the header lists all.
  Only `sub_XXXXXX` entries are touched.

RUN
  python3 notes/prom_b_repaint_table_names.py           # the plan
  python3 notes/prom_b_repaint_table_names.py --args    # 'old=new|header' lines for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_B = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
TABLES = [("Dispatch_Code80_PaintTable", "Paint", "Dispatch_Code80_Bracketed, the full paint"),
          ("Dispatch_Code80_RepaintFieldTable", "RepaintField", "Dispatch_Code80, the partial repaint")]


def plan():
    L = open(PROM_B, "rb").read().decode("latin-1").split("\n")
    rows = []
    for tab, verb, how in TABLES:
        i = [k for k, l in enumerate(L) if l.startswith(tab + ":")][0]
        uses = collections.OrderedDict()
        for l in L[i + 1:i + 49]:
            m = re.match(r'^\s*\.long\s+(\S+)\s*;\s*\[0x([0-9A-F]{2})\]', l)
            if m and re.match(r'^sub_F[0-9A-F]{5}$', m.group(1)):
                uses.setdefault(m.group(1), []).append(int(m.group(2), 16))
        for old, codes in uses.items():
            c = codes[0]
            screen = "ToneEditPage_A%d" % (c - 0xA0) if 0xA0 <= c <= 0xA7 else "ScreenCode%02X" % c
            new = "%s_%s" % (screen, verb)
            also = (" (also codes %s)" % ", ".join("0x%02X" % x for x in codes[1:])) if codes[1:] else ""
            rows.append((old, new, "%s: %s[code 0x%02X]%s -- %s." % (new, tab, c, also, how)))
    return rows


def main():
    rows = plan()
    names = collections.Counter(r[1] for r in rows)
    assert all(v == 1 for v in names.values()), [n for n, v in names.items() if v > 1]
    for old, new, hdr in rows:
        print("%s=%s|%s" % (old, new, hdr) if "--args" in sys.argv else "%-12s -> %s" % (old, new))
    if "--args" not in sys.argv:
        print("entries to name: %d" % len(rows))


if __name__ == "__main__":
    main()
