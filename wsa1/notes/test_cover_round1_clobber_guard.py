#!/usr/bin/env python3
"""Does gen_prom_b_cover_round1.py's re-splice guard actually fire, and does it
fire BEFORE anything is written?

QUESTION IT ANSWERS
  A guard that has never been seen to fire is not evidence.  splice() in
  notes/gen_prom_b_cover_round1.py replaces a whole `; === COVER-R1 ... ===`
  block with its own emission, and its "nothing was touched" check collects
  converted lines from OUTSIDE the markers -- so work spliced INSIDE one (the
  0xF0033F-0xF007FF and 0xF0199E-0xF01E71 conversions are exactly that) would be
  reverted to `.incbin` with the byte gate still green.  A guard was added on
  2026-09-02 to refuse instead.  This drives splice() to that branch and checks:

    1. it raises SystemExit,
    2. the message names the labels that would have been lost,
    3. write_part is NEVER called.

  ⚠ It cannot be driven through the tool's own front door here: `--splice` dies
  first in reachability.py's cache (`_cache_load()` returns None in a fresh
  worktree), which is a SEPARATE defect and is why this probe stubs the two
  functions ahead of the guard instead of running the whole pipeline.

  ⚠ AND IT COMPUTES A NULL.  The same call with a replacement block that DOES
  carry the labels must NOT raise -- otherwise the guard is just "always refuse"
  and proves nothing about clobbering.

RUN
  python3 notes/test_cover_round1_clobber_guard.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))

import asm_source  # noqa: E402
import gen_prom_b_cover_round1 as G  # noqa: E402

WROTE = []


def run(block_for_f00000):
    """Call splice() with everything before the guard stubbed out."""
    # ⚠ read the file splice() itself reads (the EXPANDED image), and match the
    # markers LINE BY LINE: MARK_RE is anchored and not multiline, so a
    # finditer over the whole text matches only at offset 0.
    src = open(G.SRCB, encoding="utf-8").read()
    spans = []
    for line in src.split("\n"):
        m = G.MARK_RE.match(line)
        if m:
            spans.append((int(m.group(1), 16), int(m.group(2), 16), []))
    assert spans, "no COVER-R1 markers found -- the probe would prove nothing"
    G.check_record = lambda: (spans, None)
    G.verify = lambda s: (True, "stubbed")
    G.span_block = lambda lo, hi, runs: (
        block_for_f00000(lo, hi, src))
    del WROTE[:]
    G.write_part = lambda path, text: WROTE.append(path)
    try:
        G.splice()
        return None
    except SystemExit as e:
        return str(e)


def empty_block(lo, hi, src):
    """What the tool would emit if its span record no longer knew about the
    labels a later pass spliced in: markers and an `.incbin`, no labels."""
    return [G.MARK % (lo, hi),
            '\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X'
            % (G.ROMNAME, lo - G.B_BASE, hi - lo),
            G.MARK_END % (lo, hi)]


def faithful_block(lo, hi, src):
    """The NULL: a replacement that carries every label the block already has.
    The guard must stay silent for this one."""
    lines = src.split("\n")
    i = lines.index(G.MARK % (lo, hi))
    j = lines.index(G.MARK_END % (lo, hi), i)
    return lines[i:j + 1]


def main():
    bad = 0

    msg = run(empty_block)
    ok = msg is not None and "refusing to re-splice" in msg
    print("  %s guard fires when the replacement drops labels" % ("ok  " if ok else "FAIL"))
    bad += not ok
    if msg:
        print("       " + msg.split(" -- ")[0])
        names = re.findall(r"\b(PtrTable_F[0-9A-F]{5}|Bitmap_F[0-9A-F]{5}|Data_F[0-9A-F]{5})\b", msg)
        hit = [n for n in ("PtrTable_F00340", "PtrTable_F003F9") if n in msg]
        print("       names %d of the lost labels, including %s" % (len(names), hit))
        bad += not hit
    ok = not WROTE
    print("  %s nothing was written (write_part calls: %d)"
          % ("ok  " if ok else "FAIL", len(WROTE)))
    bad += not ok

    msg = run(faithful_block)
    ok = msg is None or "refusing to re-splice" not in msg
    print("  %s NULL: guard stays silent when no label is dropped%s"
          % ("ok  " if ok else "FAIL", "" if msg is None else " (%s)" % msg[:60]))
    bad += not ok

    print("%d check(s) failed" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
