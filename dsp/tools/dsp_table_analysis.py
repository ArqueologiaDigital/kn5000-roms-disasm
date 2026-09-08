#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_table_analysis.py -- decode the class-6 table-lookup SELECTOR by effect family.

The uPD6383GF class-6 word is a table lookup (a LUT read); its `addr8` selects WHICH table
and its role has been INFERRED but not pinned. Grouping the selector value by the effect
FAMILY that uses it discriminates what each table IS -- a distortion curve, an LFO waveform
-- because a distortion program only ever looks up a waveshaper and a chorus only ever looks
up an LFO shape. The effect names are the independent variable.

    python3 dsp/tools/dsp_table_analysis.py

MEASURED 2026-09-08 (both products' committed .dsm):
  * lo12 = 0x4CD on ~every class-6 word: the table-lookup operation/register.
  * addr8 = 0x28  -> the WAVESHAPER / distortion-curve table: DISTORTION, FUZZ, OVERDRIVE,
    EXCITER, and every PEQ+DIST / PEQ+OVERDR combo, ROCK ROTARY.
  * addr8 = 0x18  -> the LFO WAVEFORM table: RING MODULATOR, VIBRATO, PHASER, CHORUS,
    FLANGER, AUTO PAN -- the modulation effects. So the LFO is phase-accumulate -> table
    lookup (a shaped waveform), not a bare ramp.
  * addr8 = 0x18/0x1A/0x1E/0x20 together (ENSEMBLE, some PEQ+CHORUS/S.DELAY+CHORUS) -> the
    multi-voice effects read SEVERAL LFO tables at once (one detuned phase per voice).

⇒ the class-6 selector is a table id, decoded by family. Graded (family correlation), not
proof, but the discrimination (waveshaper vs LFO) is measured across the catalog.

stdlib + dsp_disasm; read-only.
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


def family(n):
    n = n.upper()
    if any(k in n for k in ("DISTORT", "FUZZ", "OVERDRIVE")):        return "distortion"
    if "EXCITER" in n:                                              return "exciter"
    if "PITCH" in n:                                                return "pitch"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "VIBRATO",
                            "ENSEMBLE", "AUTO PAN", "RING", "ROTARY")): return "modulation"
    if "+" in n:                                                    return "combination"
    return "other"


SELECTOR_ROLE = {0x28: "waveshaper / distortion curve",
                 0x18: "LFO waveform (voice 0)",
                 0x1A: "LFO waveform (voice)",
                 0x1E: "LFO waveform (voice)",
                 0x20: "LFO waveform (voice)"}


def main():
    progs = load_all()
    bysel = collections.defaultdict(collections.Counter)   # addr8 -> family counter
    lo12s = collections.Counter()
    for nm, ws in progs.items():
        for w in ws:
            if D.class4(w) == 6:
                bysel[D.addr8(w)][family(nm)] += 1
                lo12s[D.lo12(w)] += 1
    print("class-6 table-lookup: the operation register lo12 =", dict(lo12s.most_common(3)))
    print("\nselector addr8 -> which families use it -> decoded table role\n")
    print("addr8  count  families                         proposed table")
    for a, fams in sorted(bysel.items(), key=lambda kv: -sum(kv[1].values())):
        tot = sum(fams.values())
        fs = ", ".join("%s(%d)" % (f, n) for f, n in fams.most_common())
        print("0x%02X   %4d   %-32s %s" % (a, tot, fs[:32], SELECTOR_ROLE.get(a, "?")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
