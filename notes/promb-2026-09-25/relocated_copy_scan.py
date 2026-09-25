#!/usr/bin/env python3
r"""Lead finder: stretches of prom_b that are copies of other stretches, allowing relocated operands.

QUESTION THIS ANSWERS
    Which byte runs of prom_b reappear elsewhere in prom_b at a constant
    distance d -- identical except where a 24-bit operand differs by exactly d
    (what relocating a block changes)?  And which such runs end on a 1 KB
    boundary (--boundaries)?  This is how the three OLDER-BUILD remnants were
    found (0xF0ED50-0xF0EFFF = live - 0x23001, 0xF17A5F-0xF17BFF = live -
    0x1A401, 0xF6F000-0xF6F3FF = live - 0xBA00; see stale_dl_tables_f0ed50.py,
    stale_value_glyphs_f17a5f.py, old_module_copy_f6f000.py, which PROVE each).

    ⚠ A LEAD LIST, NOT EVIDENCE.  Most hits are legitimate repetition: screens
    that share display-list records, template tables, twin routines.  A hit
    becomes a finding only when a separate check shows the copy is named by
    nothing and its pointers/operands are the live copy's shifted by d.

RUN
    python3 notes/promb-2026-09-25/relocated_copy_scan.py               # runs >= 128 B, relocation-tolerant
    python3 notes/promb-2026-09-25/relocated_copy_scan.py --boundaries  # the 64 bytes before each 1 KB boundary
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000


def relocated_runs(b, W=32, min_len=128, top=50):
    n = len(b)
    idx = {}
    for i in range(0, n - W):
        w = b[i:i + W]
        if len(set(w)) >= 8 and w.count(0x0E) < W // 2 and w.count(0) < W // 2 and w.count(0xFF) < W // 2:
            idx.setdefault(w, []).append(i)
    pairs = {}
    for w, ps in idx.items():
        if 1 < len(ps) < 6:
            for x in ps:
                for y in ps:
                    if y > x:
                        pairs.setdefault(y - x, set()).add(x)
    res = set()
    for d, xs in pairs.items():
        xs = sorted(xs)
        if len(xs) < 8:
            continue
        clusters = []
        for x in xs:
            if clusters and x - clusters[-1][1] <= 64:
                clusters[-1][1] = x
            else:
                clusters.append([x, x])

        def ok(i):
            if b[i] == b[i + d]:
                return True
            for s in range(i - 3, i + 1):
                if int.from_bytes(b[s + d:s + d + 3], "little") - int.from_bytes(b[s:s + 3], "little") == d:
                    return True
            return False
        for lo, hi in clusters:
            hi += W
            if hi - lo < min_len:
                continue
            while lo > 0 and ok(lo - 1):
                lo -= 1
            while hi + d < n and ok(hi):
                hi += 1
            diff = sum(1 for i in range(lo, hi) if b[i] != b[i + d])
            res.add((hi - lo, lo, hi, d, diff))
    seen, out = [], []
    for ln, lo, hi, d, diff in sorted(res, reverse=True):
        if any(lo >= s and hi <= e and d == dd for s, e, dd in seen):
            continue
        seen.append((lo, hi, d))
        out.append((ln, lo, hi, d, diff))
    return out[:top]


def boundary_copies(b, W=64):
    out = []
    for bd in range(0x400, len(b), 0x400):
        lo = bd - W
        w = b[lo:bd]
        if len(set(w)) < 10:
            continue
        i = b.find(w)
        while i >= 0:
            if i != lo:
                d = i - lo
                s = lo
                while s > 0 and b[s - 1] == b[s - 1 + d]:
                    s -= 1
                out.append((bd, s, bd - s, d))
            i = b.find(w, i + 1)
    return out


def main():
    b = open(ROMB, "rb").read()
    if "--boundaries" in sys.argv:
        for bd, s, n, d in boundary_copies(b):
            print("boundary 0x%06X: 0x%06X-0x%06X (%d B) == 0x%06X (%+#x)" % (BASE + bd, BASE + s,
                                                                          BASE + s + n - 1, n,
                                                                          BASE + s + d, d))
        return 0
    for ln, lo, hi, d, diff in relocated_runs(b):
        print("%5d  0x%06X-0x%06X == 0x%06X  delta +0x%X  relocated bytes %d  end %% 1K = 0x%X"
              % (ln, BASE + lo, BASE + hi - 1, BASE + lo + d, d, diff, (BASE + hi) % 0x400))
    return 0


if __name__ == "__main__":
    sys.exit(main())
