#!/usr/bin/env python3
r"""Are prom_b's "1,266 branch targets that land MID-INSTRUCTION" real misframes?

QUESTION THIS ANSWERS
    scripts/converters/symbolize_numeric_branches.py --report lists branch
    sites whose target is `mid-line-code`, and the 2026-09-25 lane worklist
    quoted prom_b's count (1,693 sites, 1,266 distinct targets) as misframing
    evidence.  This probe splits them by WHERE the target is:

      * inside prom_b (0xF00000-0xF7FFFF) -- genuine: the source frames the
        target byte inside an instruction line;
      * in prom_a (0xF80000-0xFFFFFF) -- an artefact: build_map() gives the
        image's LAST emitting line an open-ended span (`end = a + (1 << 30)`),
        so a target PAST the image lands "inside" that line and is reported
        mid-line instead of `external`.  prom_b's calls and jumps into prom_a
        are the routine directory and ordinary cross-image calls.

    It also prints the last span, so the mechanism is visible, not asserted.

RUN
    python3 notes/promb-2026-09-25/midline_artefact_probe.py
    (about 40 s: it runs the symboliser's own analyse() on prom_b, no writes)
"""
import collections
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import symbolize_numeric_branches as snb  # noqa: E402

IMG_END = 0xF80000


def main():
    img = snb.image_by_key("prom_b")
    marks, addrs, spans, ok, src, macros = snb.build_map(img, os.path.join(ROOT, "wsa1"))
    last = spans[-1]
    print("last emitting line: 0x%06X, span end 0x%X (image ends 0x%06X) -- %s:%d"
          % (last[0], last[1], IMG_END, last[2], last[3] + 1))
    res = snb.analyse(img)
    rep = res["report"]
    c = collections.Counter()
    tg = collections.defaultdict(set)
    for kind, rows in rep.items():
        if not kind.startswith("mid-line"):
            continue
        for x in rows:
            t = int(x["target"], 16)
            side = "in prom_b" if t < IMG_END else "past the image (prom_a)"
            c[(kind, side)] += 1
            tg[(kind, side)].add(t)
    for k in sorted(c):
        print("  %-16s %-26s %5d sites %5d distinct targets" % (k[0], k[1], c[k], len(tg[k])))
    real = sum(v for (k, s), v in c.items() if s == "in prom_b")
    art = sum(v for (k, s), v in c.items() if s != "in prom_b")
    print("mid-line sites: %d genuine (target inside prom_b), %d artefact (target past the image)"
          % (real, art))
    return 0


if __name__ == "__main__":
    sys.exit(main())
