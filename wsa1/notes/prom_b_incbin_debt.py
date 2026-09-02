#!/usr/bin/env python3
"""Measure prom_b's REAL `.incbin` debt: total bytes and span count.

QUESTION IT ANSWERS
    "How many bytes of prom_b are still handed back verbatim through
    `.incbin`, with no generating source?" -- the only number the lane brief
    (notes/lanes/BRIEF-2026-09-01.md) asks a lane to report before/after.

★ WHY THIS EXISTS. gen_prom_b_oversized_round2/3/4_module.py's own printed
    summaries ("N bytes total") count the FULL span each site closes --
    the `.incbin` bytes it removes PLUS the already-typed `Data_Fxxxxxx`
    object bytes sitting in front of it (which were never `.incbin` and were
    never debt). Quoting that combined figure as "debt reduced" overstates
    the win: round 2 actually removed 1,225 B of real `.incbin`, not the
    1,312 B its own splice printed. This script counts ONLY `.incbin` bytes,
    which is what the brief means by debt.

RUN
    python3 notes/prom_b_incbin_debt.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCBIN_RE = re.compile(r'\.incbin\s+"[^"]+"\s*,\s*0x([0-9A-Fa-f]+)\s*,\s*0x([0-9A-Fa-f]+)')


def measure(path):
    text = open(path, encoding="utf-8").read()
    spans = [(int(m.group(1), 16), int(m.group(2), 16)) for m in INCBIN_RE.finditer(text)]
    return spans


def main():
    path = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
    spans = measure(path)
    total = sum(ln for _off, ln in spans)
    print("prom_b .incbin debt: %d bytes across %d spans" % (total, len(spans)))
    if "--selftest" in sys.argv:
        # regression pin: the lane-PROMBTHIRD session's own before/after figures
        history = [
            ("2026-09-02 lane start (per BRIEF/DEBT-INVENTORY)", 18169, 109),
            ("after closing 0xF0DB18 (5-language dialog table)", 14865, 108),
            ("after oversized-object round 2 (7 sites)", 13640, 101),
            ("after oversized-object round 3 (6 sites)", 13146, 95),
            ("after oversized-object round 4 (10 sites)", 12794, 85),
        ]
        for label, want_bytes, want_spans in history:
            print("  %-58s %6d B / %3d spans (checked separately, not re-derived here)"
                 % (label, want_bytes, want_spans))
        ok = total <= 12794
        print("  current total is at or below the last recorded milestone: %s" % ok)
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
