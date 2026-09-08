#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_cformat_analysis.py -- decode the C-format immediate-load DESTINATIONS by
correlating their loaded values with each program's structure.

The uPD6383GF's C-format words load a MEASURED 13-bit immediate into a register named
by `lo12`; the immediate is known, but the destination has always been "UNKNOWN". This
finds meaning WITHOUT more corpus RE, by a cross-program correlation: a destination whose
value tracks the number of delay-DRAM taps is a delay/memory parameter; one that tracks
the coefficient-MAC count is a filter parameter; one that tracks nothing and sits near
unity is a gain. The effect NAMES + structural idiom counts are the independent variable.

    python3 dsp/tools/dsp_cformat_analysis.py

MEASURED 2026-09-08 (both products' committed .dsm):
  lo12 0x000 (195 words, ~all effects): r=-0.81 vs delay taps, 0.00 vs cMACs
     -> a DELAY/MEMORY structural parameter (values 384/480/704/896; reverbs->384,
        simple effects->896), NOT a signal coefficient.
  lo12 0x44C (46 words): no structural correlation; values 800/992 = 0.78/0.97 of 1024
     -> a near-unity GAIN / makeup-scale immediate.
  lo12 0x451 (8 words): r=+0.98 vs cMACs, -1.00 vs taps -> a FILTER-structure parameter.

Every reading here is a graded correlational hypothesis (a discriminator the raw corpus
lacked), not a proven fact. stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]


def load_all():
    progs = {}
    for tree in TREES:
        for p in glob.glob(os.path.join(tree, "*.dsm")):
            if os.path.basename(p) == "index.dsm":
                continue
            nm, ws = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    nm = m.group(1)
                m = WORD.match(ln)
                if m:
                    ws.append(int(m.group(1), 16))
            if nm and ws:
                progs[nm] = ws
    return progs


def features(ws):
    dram = sum(1 for w in ws if D.class4(w) == 1 and (D.hi12(w) & 0x800))
    macs = sum(1 for w in ws if (D.class4(w) & 8) and not D.c_format(w))
    return dram, macs, len(ws)


def pearson(xs, ys):
    if len(xs) < 3:
        return None
    mx, my = statistics.mean(xs), statistics.mean(ys)
    sx, sy = statistics.pstdev(xs), statistics.pstdev(ys)
    if not (sx and sy):
        return None
    return sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / len(xs) / (sx * sy)


def imm_of(w):
    im = D.c_imm13(w)
    return im - 0x2000 if im & 0x1000 else im


def role(lo, rd, rm, vals):
    if rd is not None and rd <= -0.6 and (rm is None or abs(rm) < 0.4):
        return "DELAY/MEMORY parameter (tracks delay-tap count, not coefficients)"
    if rm is not None and rm >= 0.6:
        return "FILTER-structure parameter (tracks coefficient-MAC count)"
    if all(600 <= v <= 1024 for v in vals):
        return "near-unity GAIN / makeup-scale (~%.2f..%.2f of 1024)" % (
            min(vals) / 1024, max(vals) / 1024)
    return "unclassified (constant or too few samples)"


def main():
    progs = load_all()
    dest = collections.defaultdict(list)
    for nm, ws in progs.items():
        dram, macs, ln = features(ws)
        for w in ws:
            if D.c_format(w):
                dest[D.lo12(w)].append((imm_of(w), dram, macs, ln, nm))
    print("C-format immediate-load destinations, decoded by cross-program correlation\n")
    print("lo12   words  r(taps)  r(cMAC)  values                proposed role")
    for lo, rows in sorted(dest.items(), key=lambda kv: -len(kv[1])):
        ims = [r[0] for r in rows]
        rd = pearson(ims, [r[1] for r in rows])
        rm = pearson(ims, [r[2] for r in rows])
        vals = sorted(set(ims))
        f = lambda x: ("%+.2f" % x) if x is not None else "  -- "
        print("0x%03X  %4d   %s    %s   %-20s  %s"
              % (lo, len(rows), f(rd), f(rm), str(vals[:5]),
                 role(lo, rd, rm, vals) if len(rows) >= 3 else "constant %s" % vals))
    return 0


if __name__ == "__main__":
    sys.exit(main())
