#!/usr/bin/env python3
r"""sequi_misframe_scan.py -- does every code line of a file start where MAME
unidasm, decoding linearly, starts an instruction?

QUESTION THIS ANSWERS
    After the 2026-09-25 re-frames, is any MISFRAMED code left in a file?
    The file's emitting lines (addresses from the inert marker mirror of
    symbolize_numeric_branches.build_map) are grouped into maximal runs of
    contiguous CODE lines; each run is decoded by unidasm from its first
    byte, and every source line of the run must begin on an instruction
    boundary of that decode.  A line that does not is printed (first one per
    run) as MISFRAME?.

    Limits: a run that begins on a wrong byte and resynchronises would show
    as a mismatch only up to the resync; data framed as code that both
    decoders read the same way is not caught (that is what the absurd-marker
    count and the reader checks are for).

RUN
    python3 scripts/analysis/sequi_misframe_scan.py v10 sequencer/sequencer_ui.s
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "converters"))
sys.path.insert(0, HERE)
import sequi_reframe as S  # noqa: E402


def main():
    img, rel = sys.argv[1], sys.argv[2]
    ctx = S.Ctx(img, rel)
    lis = sorted(ctx.span)
    runs, cur = [], []
    for li in lis:
        if ctx.kind(li)[0] == "code":
            if cur and ctx.span[cur[-1]][1] != ctx.span[li][0]:
                runs.append(cur)
                cur = []
            cur.append(li)
        elif cur:
            runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    bad = 0
    for r in runs:
        lo, hi = ctx.span[r[0]][0], ctx.span[r[-1]][1]
        starts = {a for a, _, _ in S.unidasm(ctx.rom[lo - S.BASE:hi - S.BASE], lo)}
        for li in r:
            a = ctx.span[li][0]
            if a not in starts:
                bad += 1
                print("MISFRAME? line %d 0x%06X %s" % (li + 1, a, ctx.lines[li].strip()[:60]))
                break
    print("%s %s: %d code run(s), %d with a line off the unidasm framing"
          % (img, rel, len(runs), bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
