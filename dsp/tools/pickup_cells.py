#!/usr/bin/env python3
"""pickup_cells.py -- read the INPUT (pickup) cells out of a frame capture, and say if any RAILED.

QUESTION IT ANSWERS
    "Is there audio at this program's input, and is it a SIGNAL or a RAIL?"

    N-INPUT-GATE-OPENED §62 found `prog32_distortion` reading STATIC at the correct selector and
    traced it to its pickup cell sitting at `0x7FFFFF`.  A railed cell is CONSTANT frame to frame,
    so a body fed from one cannot move -- the frame-pair liveness test says STATIC and is right.
    That exposed a lenient check used all session: the precondition was *"any of 0x01 / 0x04 / 0x05
    greater than 1000"*, and the distortion PASSED it on `0x01` while `0x05` sat at the rail.

    ⇒ ★ THE RULE (RULE 13 one level up -- a constant is not a signal, even a large one):
      an input cell must be NON-ZERO **and NOT RAILED**.

    This reads the three cells from the trace's own `dp`/`mem` columns and applies that rule.

USAGE
    python3 dsp/tools/pickup_cells.py <error.log> [more.log ...]

⚠ PROVENANCE.  `data/railed_pickups_2026-09-13.txt` was committed from an ad-hoc script that was
  not.  This tool is that measurement made reproducible, and it is checked against that table: on
  the sel-7 captures it must reproduce `prog04_flanger = -32512 / -14848 / 517549` and
  `prog32_distortion 0x05 = 8388607 RAILED`.  If it ever stops doing so, this tool is wrong, not
  the table.
"""
import os
import re
import sys

ROW = re.compile(r"upd6383:\s+(\d+)\s+(\d+)\s+([01])\s+([0-9A-F]{10})\s+([0-9A-F]{2})\s+"
                 r"([0-9A-F]{6})\s")
CELLS = (0x01, 0x04, 0x05)
RAIL = 0x7fffff


def sext24(v):
    return v - (1 << 24) if v & 0x800000 else v


def read(path):
    """FIRST value seen in each pickup cell over the traced frame.

    ⚠⚠ ONE-FRAME LAG, and it has already caused one misreading.  The first touch is what the
    frame INHERITS from its predecessor -- which is exactly right for "what is this body handed",
    but it means **the effect of any arm appears one frame LATE**.  N-INPUT-GATE-OPENED §73 read
    `prog04_flanger` as "unchanged, the arm did not fix it" on that basis; the trace shows its
    `iw45` storing -21 382 with the arm against +8 388 607 without, i.e. the arm HAD fixed it and
    this function was reporting the previous frame.  ⇒ to grade an ARM, read the frame's own
    STORES (trace_window.py / the cell trajectory), not this function alone.

    ★ FIRST, not last, and the difference is not cosmetic.  Cell `0x05` is touched 19 times in a
    frame: the kernel DEPOSITS the arriving sample at `iw8`, and the site-2 bit-4 store rewrites it
    again at `iw35`/`iw45` (the device's own `NOZ05` note names those sites).  The PICKUP question
    is "what did the input stage hand over", so it is the first touch that answers it -- taking the
    last one reports a downstream value and, on the flanger, turns 517 549 into 2 824 201.
    ⚠ Found by this tool failing to reproduce `data/railed_pickups_2026-09-13.txt`, whose own
    producer had not been committed.  That is what the reproducibility rule is for."""
    vals, started = {}, False
    for ln in open(path, errors="replace"):
        if "TIME-ORDERED FRAME TRACE" in ln:
            started = True
            continue
        if not started:
            continue
        m = ROW.search(ln)
        if m:
            dp = int(m.group(5), 16)
            if dp in CELLS and dp not in vals:          # FIRST touch only
                vals[dp] = sext24(int(m.group(6), 16))
    return vals


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    print("PICKUP CELLS -- an input cell must be NON-ZERO **and NOT RAILED** (§62)")
    print("%-24s %12s %12s %12s  state" % ("capture", "0x01", "0x04", "0x05"))
    bad = 0
    for p in sys.argv[1:]:
        v = read(p)
        if not v:
            print("%-24s %s" % (os.path.basename(p), "(no trace rows touched 0x01/0x04/0x05)"))
            continue
        cells = [v.get(c) for c in CELLS]
        railed = [c for c, x in zip(CELLS, cells) if x is not None and abs(x) >= RAIL]
        live = [x for x in cells if x not in (None, 0)]
        state = ("⛔ RAILED at %s" % ", ".join("0x%02X" % c for c in railed) if railed
                 else "⚠ all zero -- NO AUDIO" if not live else "ok")
        bad += bool(railed or not live)
        print("%-24s %12s %12s %12s  %s" % (os.path.basename(p),
                                            *["%d" % x if x is not None else "-" for x in cells],
                                            state))
    print("\n⇒ %d of %d captures fail the non-zero-and-not-railed precondition."
          % (bad, len(sys.argv) - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
