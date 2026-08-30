#!/usr/bin/env python3
"""What SHAPE is a still-`.incbin` span of prom_a, before anyone converts it?

QUESTION IT ANSWERS
  "Which of prom_a's remaining .incbin spans is worth a conversion pass, and
   what does its converter have to declare as data?"

  Three passes over one span, all read off the ROM:
    * POINTER-SHAPED RUNS -- runs of >=4 LE32 words in 0x00F00000-0x00FFFFFF.
      ⚠ SHAPE, NOT EXTENT.  A run can be several tables (see the 0xF91865 case
      in notes/gen_prom_a_f90989_module.py, where one 32-entry run was four
      8-entry tables); only a reader settles the boundaries.
    * TABLE BASES -- every `ld XWA/XBC/XDE/XHL/XIX/XIY/XIZ,imm32` in the span
      whose immediate lands in the span.  This is the list a converter has to
      explain; it is what corrects the run detector.
    * A LINEAR DECODE of everything the runs do not cover, reporting the rows
      llvm-mc cannot spell.  A handful means encoding gaps; a cluster means a
      table the first two passes missed.
  Plus ASCII runs and 0x0E pad runs, and the call-target histogram that says
  whether the span is code at all.

RUN
  python3 notes/prom_a_span_survey.py 0xF96018 0xF99021
  python3 notes/prom_a_span_survey.py --all      # every remaining .incbin span
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
REGS = {0x40: "XWA", 0x41: "XBC", 0x42: "XDE", 0x43: "XHL",
        0x44: "XIX", 0x45: "XIY", 0x46: "XIZ", 0x47: "XSP"}


def w32(a):
    return int.from_bytes(ROM[a - BASE:a - BASE + 4], "little")


def spans():
    out = []
    for m in re.finditer(r'\.incbin "original_ROMs/wsa1_prom_a\.ic12", '
                         r'0x([0-9A-Fa-f]+), 0x([0-9A-Fa-f]+)',
                         open(SRC, encoding="utf-8").read()):
        off, ln = int(m.group(1), 16), int(m.group(2), 16)
        out.append((BASE + off, BASE + off + ln))
    return sorted(out)


def chunked(RT, lo, hi, chunk=0x800):
    """RT.convert over [lo,hi) in ALIGNED chunks, and why it must be chunked.

    ⚠ roundtrip.assemble_batch feeds every candidate line of a region to one
    llvm-mc run and drops the lines llvm-mc rejects, retrying.  That is fine for
    a few hundred lines.  Over a whole 17 KB span it degrades badly -- measured
    on 0xFA5AEB-0xFA9FFF, one call reported 3,066 rows as unspellable while the
    same bytes decoded in 2 KB chunks report 40, and hand-checking one of the
    "failures" (0xFA5AEF `2b`) shows llvm-mc spells it `pushw hl` perfectly
    well.  So the big-region number is a TOOL ARTEFACT, not a property of the
    code, and any survey that quotes it is lying about the span.

    Alignment is preserved by continuing each chunk from the END of the last
    instruction the previous chunk decoded, never from a round address.
    """
    rows, at = [], lo
    while at < hi:
        rs = RT.convert(at, min(at + chunk, hi))[0]
        if not rs:
            break
        rows += rs
        at = rs[-1][0] + len(rs[-1][1])
    return rows


def survey(lo, hi, decode=True):
    body = ROM[lo - BASE:hi - BASE]
    print("=" * 78)
    print("0x%06X-0x%06X  %d bytes" % (lo, hi - 1, hi - lo))
    calls = {}
    for i in range(len(body) - 3):
        if body[i] == 0x1D:
            t = int.from_bytes(body[i + 1:i + 4], "little")
            if 0xF00000 <= t <= 0xFFFFFF:
                calls[t >> 12] = calls.get(t >> 12, 0) + 1
    print("  absolute `call` targets by 4K page: %s"
          % (", ".join("%06X:%d" % (k << 12, v)
                       for k, v in sorted(calls.items(), key=lambda kv: -kv[1])[:8])
             or "NONE -- this span may be data"))
    runs, a = [], lo
    while a < hi - 4:
        n, p = 0, a
        while p < hi - 4 and 0x00F00000 <= w32(p) <= 0x00FFFFFF:
            n, p = n + 1, p + 4
        if n >= 4:
            runs.append((a, n))
            a = p
        else:
            a += 1
    print("  pointer-shaped runs (>=4): %d, %d bytes"
          % (len(runs), sum(4 * n for _, n in runs)))
    for a, n in runs:
        t = [w32(a + 4 * k) for k in range(n)]
        print("    0x%06X  %3d entries  ends 0x%06X  targets %06X-%06X"
              % (a, n, a + 4 * n, min(t), max(t)))
    bases = []
    for i in range(lo - BASE, hi - BASE - 5):
        if ROM[i] in REGS and ROM[i + 4] == 0x00:
            v = int.from_bytes(ROM[i + 1:i + 5], "little")
            if lo <= v < hi:
                bases.append((BASE + i, REGS[ROM[i]], v))
    print("  in-span table bases (`ld R,imm32` landing in the span): %d"
          % len(bases))
    for a, r, v in bases:
        print("    0x%06X  ld %s,0x%06X" % (a, r, v))
    txt, cur = [], 0
    for i, x in enumerate(body):
        if 0x20 <= x < 0x7F:
            cur += 1
        else:
            if cur >= 8:
                txt.append((lo + i - cur, cur))
            cur = 0
    print("  ASCII runs >= 8: %s"
          % ([("%06X" % a, n, ROM[a - BASE:a - BASE + n].decode("latin1")[:40])
              for a, n in txt] or "none"))
    pads, i = [], lo
    while i < hi:
        if ROM[i - BASE] == 0x0E:
            j = i
            while j < hi and ROM[j - BASE] == 0x0E:
                j += 1
            if j - i >= 8:
                pads.append(("%06X-%06X" % (i, j), j - i))
            i = j
        else:
            i += 1
    print("  0x0E runs >= 8: %s" % (pads or "none"))
    if not decode:
        return
    import roundtrip as RT
    # ⚠ DECODE FROM ONE PINNED START, NOT FROM EVERY RUN BOUNDARY.
    # An earlier version of this tool cut the span at the pointer-shaped run
    # boundaries and decoded each gap from its own start.  On 0xFA5AEB that
    # reported 1,131 unspellable rows -- and the number was an ARTEFACT: the run
    # boundaries are shape, not extent, so most of those decodes began in the
    # middle of an instruction and stayed out of step.  Decoding the same span
    # in ONE pass from `lo` reports 40.  A single pass can still desynchronise,
    # on a real table -- but then the failures COME IN A CLUSTER at the table,
    # which is the signal worth having.  Scattered singletons are llvm-mc
    # encoding gaps; a cluster is a table to declare.
    bad = [(r[0], bytes(r[1]).hex(), r[4]) for r in chunked(RT, lo, hi)
           if r[3] == "byte"]
    print("  ONE linear decode of 0x%06X-0x%06X: %d rows llvm-mc cannot spell"
          % (lo, hi, len(bad)))
    prev, cluster = None, []
    for a, h, u in bad:
        if prev is not None and a - prev > 64 and len(cluster) >= 4:
            print("    ★ CLUSTER of %d from %06X -- look for a table there"
                  % (len(cluster), cluster[0]))
        if prev is None or a - prev > 64:
            cluster = []
        cluster.append(a)
        prev = a
    if len(cluster) >= 4:
        print("    ★ CLUSTER of %d from %06X -- look for a table there"
              % (len(cluster), cluster[0]))
    for a, h, u in bad[:30]:
        print("    %06X  %-14s %s" % (a, h, u))


if __name__ == "__main__":
    if "--all" in sys.argv:
        for lo, hi in spans():
            survey(lo, hi, decode="--fast" not in sys.argv)
    else:
        survey(int(sys.argv[1], 16), int(sys.argv[2], 16))
