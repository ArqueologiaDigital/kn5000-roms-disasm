#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_context_analysis.py -- decode-support by PROGRAM-ORDER context of the OPEN codes.

A word's meaning is constrained by its neighbours: what feeds it and what it feeds. This
aggregates, across every effect program of both products, the idiom of the instruction
before and after each occurrence of an OPEN routing code, and detects ADJACENT PAIRS. It
turns "this code is undecoded" into "this code sits between X and Y in N% of the corpus",
which is a cross-program discriminator the isolated word could not give.

Calibrated against a MEASURED code (SRC 0x07 = mem[ptr]) so the shape of a real context is
visible for comparison.

    python3 dsp/tools/dsp_context_analysis.py

MEASURED 2026-09-08 (both products' committed .dsm):
  * ACT 0x0D is IMMEDIATELY followed by ACT 0x0E in 355/441 (80%); ACT 0x0E is preceded by
    ACT 0x0D in 355/483 (73%). The pair is the two-state (z^-1 / z^-2) filter update -- a
    strong cross-program confirmation of the biquad-pair reading, and it appears in ALL
    families (a general resonant-filter / damping primitive, not EQ-only).
  * SRC 0x00's context matches the MEASURED mem-read (SRC 0x07) -> supports "delay-read".
  * SRC 0x11 is preceded by a route 56% of the time -> consistent with a 2nd accumulator
    set up then read.

Graded correlational evidence, not proof. stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]


def load_all():
    # LIST of word-arrays, not a name-keyed dict: KN5000/WSA1R share 31 effect names across
    # byte-different programs, so a dict would drop one product's version. (Fixed 2026-09-08.)
    progs = []
    for tree in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
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
                progs.append(ws)
    return progs


def idiom(w):
    if D.c_format(w):
        return "Cload"
    if D.lo_act(w) in (0x0D, 0x0E):
        return "biqz"
    c = D.class4(w)
    if c == 1 and (D.hi12(w) & 0x800):
        return "DRAMw" if (D.addr8(w) & 0x40) else "DRAMr"
    if c & 8:
        return "cMAC"
    if c == 2 and (D.lo12(w) & 0x10):
        return "store"
    if c == 2:
        return "route"
    if c == 0:
        return "load0"
    if c == 6:
        return "table"
    return "other"


def context(progs, pred, label):
    prev, nxt = collections.Counter(), collections.Counter()
    n = 0
    for ws in progs:
        for i, w in enumerate(ws):
            if pred(w):
                n += 1
                if i > 0:
                    prev[idiom(ws[i - 1])] += 1
                if i < len(ws) - 1:
                    nxt[idiom(ws[i + 1])] += 1
    tp, tn = sum(prev.values()) or 1, sum(nxt.values()) or 1
    print("\n%s  (%d occurrences)" % (label, n))
    print("  preceded by: " + ", ".join("%s %d%%" % (k, 100 * v // tp) for k, v in prev.most_common(4)))
    print("  followed by: " + ", ".join("%s %d%%" % (k, 100 * v // tn) for k, v in nxt.most_common(4)))


def adjacency(progs, a_code, b_code, aname, bname):
    a_tot = ab = b_tot = ba = 0
    for ws in progs:
        acts = [D.lo_act(w) for w in ws]
        for i, a in enumerate(acts):
            if a == a_code:
                a_tot += 1
                if i + 1 < len(acts) and acts[i + 1] == b_code:
                    ab += 1
            if a == b_code:
                b_tot += 1
                if i > 0 and acts[i - 1] == a_code:
                    ba += 1
    print("\nADJACENT-PAIR test %s -> %s:" % (aname, bname))
    print("  %s immediately followed by %s: %d/%d = %d%%" % (aname, bname, ab, a_tot, 100 * ab // (a_tot or 1)))
    print("  %s immediately preceded by %s: %d/%d = %d%%" % (bname, aname, ba, b_tot, 100 * ba // (b_tot or 1)))


def main():
    progs = load_all()
    context(progs, lambda w: not D.c_format(w) and D.lo_src(w) == 0x00, "SRC 0x00 (device: delay-read)")
    context(progs, lambda w: not D.c_format(w) and D.lo_src(w) == 0x11, "SRC 0x11 (device: ACCB)")
    context(progs, lambda w: D.lo_act(w) == 0x0D, "ACT 0x0D (biquad z^-1 candidate)")
    context(progs, lambda w: D.lo_act(w) == 0x0E, "ACT 0x0E (biquad z^-1 candidate)")
    context(progs, lambda w: not D.c_format(w) and D.lo_src(w) == 0x07, "SRC 0x07 CONTROL (=mem[ptr], MEASURED)")
    adjacency(progs, 0x0D, 0x0E, "ACT 0x0D", "ACT 0x0E")
    return 0


if __name__ == "__main__":
    sys.exit(main())
