#!/usr/bin/env python3
"""How much of each WSA1 image is real assembly, and how much is still .incbin?

Question answered: the README's status table. It exists as a SCRIPT because the hand-typed
version went stale within a single commit -- it still read "4,639 bytes" and "prom_b and
prom_d are still one .incbin each" after four agents had converted 604,523 bytes. Three of
four agents noticed and none fixed it, because the front page was outside every lane.

Method: sum the length argument of every `.incbin "...", off, len` in a source; converted =
524288 - that. This is exact, not an estimate, BECAUSE the byte gate guarantees the source
reproduces the image: whatever is not .incbin is emitted by directives that assemble to the
remaining bytes.

⚠ It measures TERRITORY, not understanding. A region emitted as `.byte 0x12, 0x34, ...`
counts as converted while telling you nothing. Coverage is a floor on effort, never a claim
about documentation quality -- for that, read notes/ and the routine headers.

⚠⚠ AND FILLER IS NOT PROGRESS. Wave 3 converted 123,151 bytes of prom_c of which 118,298
were a verified run of 0x0E pad emitted as .fill -- a 96% filler fraction that moved the
headline from 4.3% to 27.7% while adding ~4.8 KB of actual content. The bytes are real and
the .fill is checked rather than sampled, so it belongs in the source; but a single number
that treats it as equal to decoded code is a number that flatters. So this script now
reports SUBSTANTIVE and FILLER separately, and the substantive column is the one to quote.

Run:  python3 scripts/analysis/source_coverage.py [--markdown]
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SIZE = 524288
IMAGES = [("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
          ("c", "wsa1_prom_c.ic28"), ("d", "wsa1_prom_d.bin")]


def measure(key):
    src = os.path.join(ROOT, f"prom_{key}", f"wsa1_prom_{key}.s")
    text = open(src).read()
    inc = sum(int(m.group(2), 16) for m in
              re.finditer(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', text))
    whole = re.findall(r'\.incbin\s+"[^"]+"\s*$', text, re.M)
    inc += SIZE * len(whole)
    # .fill count, size, value  -- padding emitted wholesale, not decoded content
    fill = 0
    for m in re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*,\s*([0-9]+)', text):
        n = int(m.group(1), 0)
        fill += n * int(m.group(2), 0)
    for m in re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*$', text, re.M):
        fill += int(m.group(1), 0)
    conv = SIZE - inc
    return conv, inc, text.count(".incbin"), fill


def main():
    md = "--markdown" in sys.argv
    rows = [(k, fn) + measure(k) for k, fn in IMAGES]
    total = sum(r[2] for r in rows)
    total_fill = sum(r[5] for r in rows)
    total_sub = total - total_fill
    if md:
        print(f"**Converted: {total:,} of {SIZE*4:,} bytes ({100.0*total/(SIZE*4):.1f}%)** "
              f"-- of which {total_sub:,} substantive ({100.0*total_sub/(SIZE*4):.1f}%) "
              f"and {total_fill:,} verified filler.\n")
        print("| source | image | substantive | filler | still `.incbin` | `.incbin` spans |")
        print("|---|---|---:|---:|---:|---:|")
        for k, fn, conv, inc, n, fill in rows:
            print(f"| `prom_{k}/` | `{fn}` | {conv - fill:,} | {fill:,} | {inc:,} | {n} |")
    else:
        for k, fn, conv, inc, n, fill in rows:
            print(f"  prom_{k}  {conv - fill:8,} substantive  {fill:8,} filler  "
                  f"{inc:8,} incbin  ({100.0*(conv-fill)/SIZE:5.1f}% / {100.0*conv/SIZE:5.1f}% incl. filler)")
        print(f"  TOTAL   {total_sub:,} substantive + {total_fill:,} filler = {total:,} of {SIZE*4:,}")
        print(f"          {100.0*total_sub/(SIZE*4):.1f}% substantive, {100.0*total/(SIZE*4):.1f}% incl. filler")


if __name__ == "__main__":
    main()
