#!/usr/bin/env python3
"""prom_b coverage with `.fill` padding broken out.

QUESTION IT ANSWERS
    Round-1 audit finding **F1**: scripts/analysis/source_coverage.py computes
    converted = SIZE - incbin, so every `.fill` of `ret` padding counts as
    "converted territory".  For prom_c that inflated a headline number by 22
    points.  prom_b's inflation is smaller but real, and any figure quoted from
    this lane should say which of the two it is.

    This does NOT replace source_coverage.py and does not touch it -- it reads
    the same source file and reports the split.

⚠ A parsing trap this script exists to avoid: prom_b's fills are written with
    HEX counts (`.fill 0x40, 1, 0x0E`) as well as decimal ones
    (`.fill 946, 1, 0x0E`).  A `\\d+` regex silently matches only the decimal
    ones and under-reports the padding by about 8 KB.  Counts are parsed with
    int(x, 0).

RUN
    python3 notes/prom_b_real_coverage.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZE = 524288
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")

text = open(SRC).read()
inc = sum(int(m.group(2), 16) for m in re.finditer(
    r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', text))
fills = [(int(m.group(1), 0), int(m.group(2), 0), m.group(3))
         for m in re.finditer(
             r'\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,'
             r'\s*(0x[0-9A-Fa-f]+|\d+)', text)]
fill = sum(n * w for n, w, _ in fills)
conv = SIZE - inc

by_val = {}
for n, w, v in fills:
    by_val[v] = by_val.get(v, 0) + n * w

print("prom_b/wsa1_prom_b.s")
print("  .incbin (unconverted)       %8d" % inc)
print("  converted, as source_coverage.py counts it %8d  (%.2f%%)"
      % (conv, 100.0 * conv / SIZE))
print("  of which .fill padding      %8d  in %d directives"
      % (fill, len(fills)))
for v, n in sorted(by_val.items(), key=lambda x: -x[1]):
    print("      value %-6s            %8d" % (v, n))
print("  REAL converted (ex-fill)    %8d  (%.2f%%)"
      % (conv - fill, 100.0 * (conv - fill) / SIZE))
assert inc + conv == SIZE
assert fill <= conv
