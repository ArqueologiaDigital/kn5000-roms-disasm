#!/usr/bin/env python3
"""fix_se_range_headers.py -- the sound-editor table headers say how many cells the table holds.

QUESTION THIS ANSWERS / JOB IT DOES
  scripts/lanes/seui/se_screendata_render.py headed each value-indexed table of SeScreenData
  "... indexed by a bound record's value (...; value range up to N)".  N is the bound of the
  READING record's mask (1 + mask >> shift), not the table's size: SeScreenData_0x21F2 holds 14
  3-char cells and said "up to 128" (claims review 2026-10-02, open item 27).  This counts the
  cells the table's own source lines hold -- quoted strings of its `.ascii` lines for a string
  table, `.short` values / 4 for a box table -- and restates the header as "value at most N by
  the record's mask; the table holds K cells", adding "values >= K would read past it" where
  K < N.  Comments only: no byte changes.

USAGE
  python3 scripts/tools/fix_se_range_headers.py FILE.s [FILE.s ...]
"""
import re
import sys

RANGE = re.compile(r'value range up to (\d+)\)')
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')


def cells(L, i):
    """Cells of the table whose header ends at line i: from its label to the next label."""
    j = i + 1
    while j < len(L) and not LABEL.match(L[j]):
        j += 1
    j += 1
    strings, shorts = 0, 0
    while j < len(L) and not LABEL.match(L[j]) and not L[j].startswith(";"):
        code = L[j].split(";", 1)[0]
        if re.match(r'^\s*\.ascii\b', code):
            strings += len(re.findall(r'"(?:[^"\\]|\\.)*"', code))
        elif re.match(r'^\s*\.short\b', code):
            shorts += len([x for x in code.split(None, 1)[1].split(",") if x.strip()])
        elif code.strip():
            break
        j += 1
    return strings, shorts


def main():
    for f in sys.argv[1:]:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        n_fix = 0
        for i, l in enumerate(L):
            m = RANGE.search(l)
            if not m:
                continue
            head = " ".join(L[max(0, i - 1):i + 1])
            s, sh = cells(L, i)
            k = s if "string table" in head else sh // 4 if "box table" in head else None
            if not k:
                continue
            n = int(m.group(1))
            new = "value at most %d by the record's mask; the table holds %d cell%s%s)" % (
                n, k, "" if k == 1 else "s", "; values >= %d would read past it" % k if k < n else "")
            L[i] = l[:m.start()] + new + l[m.end():]
            n_fix += 1
        open(f, "wb").write("\n".join(L).encode("latin-1"))
        print("%s: %d headers" % (f, n_fix))


if __name__ == "__main__":
    main()
