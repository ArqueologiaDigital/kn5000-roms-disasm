#!/usr/bin/env python3
r"""seqeng_misframe_zones.py -- where does the source's instruction framing
disagree with MAME unidasm's, in the sequencer files lane `seqeng` owns?

QUESTION ANSWERED
-----------------
"Which spans of these files are written as instructions that start at
addresses where a second, independent decoder (unidasm, linear over the whole
dump) does NOT see an instruction start?"  That is the signature of a
MISFRAMED instruction: a real multi-byte instruction spelled as a lone
`.byte` prefix followed by its operand bytes decoded as bogus instructions
(the symboliser's R5 refusal; notes/branch-symbolization-2026-09-25/README.md).

Each zone is widened to the nearest addresses on both sides where the source
and unidasm AGREE on an instruction start, so a zone is exactly the span a
re-framing must rewrite.  It is a CANDIDATE list, not a verdict: a zone can
also be data typed as code (then unidasm is decoding data too).  Read the
printed unidasm text before converting.

RUN
    python3 scripts/analysis/seqeng_misframe_zones.py v10 sequencer/sequencer_engine.s
    python3 scripts/analysis/seqeng_misframe_zones.py v9 sequencer/seq_event_playback.s --unidasm /path/v9.unidasm

  --unidasm defaults to original_ROMs/kn5000_<v>_program.rom.unidasm; for
  v9/v7 generate it with
    ../tools/unidasm original_ROMs/kn5000_v9_program.rom -arch tlcs900 -basepc 0xE00000
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from seqeng_line_map import line_map, strip_comment, ROOT  # noqa: E402

UNI_RE = re.compile(r'^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def load_unidasm(path):
    starts = {}
    for ln in open(path, encoding="latin-1"):
        m = UNI_RE.match(ln)
        if m:
            a = int(m.group(1), 16)
            starts[a] = (len(m.group(2).split()), m.group(3).strip())
    return starts


def kind(text):
    c = strip_comment(text).strip()
    while re.match(r'^[A-Za-z_.$][\w.$@]*:', c):
        c = c.split(":", 1)[1].strip()
    if not c:
        return None
    if c.startswith("."):
        return "byte" if c.split()[0].lower() == ".byte" else "data"
    return "insn"


def zones(image, rel, uni):
    rows = line_map(image, [rel])[rel]
    src = open(os.path.join(ROOT, image, "maincpu", rel), encoding="latin-1").read().split("\n")
    info = []
    for ln, a, sz in rows:
        info.append((ln, a, sz or 0, kind(src[ln - 1])))
    bad = [i for i, (ln, a, sz, k) in enumerate(info) if k == "insn" and sz and a not in uni]
    out = []
    for i in bad:
        # lo: nearest line at/before i that starts on a unidasm boundary
        lo = i
        while lo > 0 and info[lo][1] not in uni:
            lo -= 1
        # hi: nearest line after i that starts on a unidasm boundary
        hi = i + 1
        while hi < len(info) and info[hi][1] not in uni:
            hi += 1
        if hi >= len(info) or info[hi][1] - info[lo][1] > 256:
            continue
        out.append((info[lo][0], info[hi][0], info[lo][1], info[hi][1]))
    # merge overlapping / touching zones
    merged = []
    for z in sorted(set(out)):
        if merged and z[0] <= merged[-1][1]:
            m = merged[-1]
            merged[-1] = (m[0], max(m[1], z[1]), m[2], max(m[3], z[3]))
        else:
            merged.append(z)
    return merged


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("file")
    ap.add_argument("--unidasm")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    up = a.unidasm or os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom.unidasm" % a.image)
    uni = load_unidasm(up)
    zs = zones(a.image, a.file, uni)
    tot = 0
    for l0, l1, a0, a1 in zs:
        tot += a1 - a0
        print("ZONE lines %d-%d  0x%06X-0x%06X  %d B" % (l0, l1 - 1, a0, a1, a1 - a0))
        if not a.quiet:
            x = a0
            while x < a1:
                if x in uni:
                    n, t = uni[x]
                    print("    %06x: %s" % (x, t))
                    x += n
                else:
                    print("    %06x: <no unidasm start>" % x)
                    x += 1
    print("TOTAL %d zones, %d B" % (len(zs), tot))


if __name__ == "__main__":
    main()
