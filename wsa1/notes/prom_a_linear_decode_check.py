#!/usr/bin/env python3
"""Is a LINEAR disassembly of this span self-consistent, or is there data in it?

QUESTION IT ANSWERS
  Converting a span means committing to one set of instruction boundaries.  A
  linear decode that runs into an embedded table desynchronises and then prints
  invented instructions -- and the byte gate cannot see it, because the bytes are
  still the bytes.  So before a large span is converted, and afterwards whenever
  the claim is re-checked, three independent tests have to agree:

    1. NO UNDECODABLE BYTES.  unidasm prints `db` for a byte it cannot decode.
       Zero of them is necessary, not sufficient -- data often decodes.
    2. THE END IS AN INSTRUCTION BOUNDARY.  The decode is run PAST the end of
       the span and the end address must fall on an instruction start.
       ⚠ The first version of this test cut the file at the end address and then
       checked that the decode finished there -- which it always does, because
       unidasm cannot run off the bytes it was given.  A test that cannot fail is
       not a test; this one is run over a longer window for that reason.
    3. EVERY PUBLISHED ENTRY IS A BOUNDARY.  Each prom_b directory slot pointing
       into the span must land exactly on one of the decode's instruction
       starts.  These addresses are chosen by the linker, not by the decode, so
       agreement is evidence and not tautology.

  ⚠ WHAT THESE THREE DO NOT ESTABLISH: the START.  Re-running the whole check
  one byte late, on 0xFE0001, passes all three -- a TLCS-900 decode
  resynchronises within a couple of instructions and then agrees with everything
  downstream.  What pins the start of a span is its module structure (a run of
  `jp` veneers, a directory slot, a pad boundary), never this script.  The
  selftest asserts the failing controls rather than that one, precisely so the
  distinction stays visible.

  It also reports the call/calr targets inside the span that are NOT boundaries,
  split by whether the SITE that names them is itself a boundary.  A phantom
  reference (opcode-anchored scans produce many) has a site that is not a
  boundary; a real caller that reaches a non-boundary would mean the decode is
  wrong there, and that is the row to worry about.

RUN
  python3 notes/prom_a_linear_decode_check.py 0xFE0000 0xFE54B6
  python3 notes/prom_a_linear_decode_check.py --selftest
Exit status is non-zero if any of the three tests fails.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_ringbuf_map as MAP                                # noqa: E402

UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
ROW = re.compile(r"^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$")


def decode(lo, hi):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(ROM[lo - BASE:hi - BASE])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(lo)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for line in out.splitlines():
        m = ROW.match(line)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()),
                         m.group(3).strip()))
    return rows


def run(lo, hi, quiet=False):
    # decode PAST the end, so that "hi is an instruction boundary" can fail
    over = min(hi + 16, BASE + len(ROM))
    rows_all = decode(lo, over)
    rows = [r for r in rows_all if r[0] < hi]
    bounds = {a for a, _, _ in rows_all}
    db = [a for a, _, t in rows if t == "db"]
    end_is_boundary = hi in bounds or hi == BASE + len(ROM)
    slots = sorted(t for t in MAP.thunk_targets() if lo <= t < hi)
    off = [t for t in slots if t not in bounds]

    refs = MAP.all_refs()
    site_ok = site_bad = outside = 0
    for t, ss in refs.items():
        if not (lo <= t < hi) or t in bounds:
            continue
        for k, at in ss:
            if k not in ("call", "calr"):
                continue
            if not (lo <= at < hi):
                outside += 1
            elif at in bounds:
                site_bad += 1
            else:
                site_ok += 1

    ok = not db and end_is_boundary and not off and site_bad == 0
    if not quiet:
        print("0x%06X-0x%06X   %d instructions" % (lo, hi - 1, len(rows)))
        print("  1. undecodable `db` bytes            : %d%s"
              % (len(db), "" if not db else "  " + ", ".join("0x%06X" % a
                                                             for a in db[:8])))
        near = sorted(a for a in bounds if abs(a - hi) <= 8)
        print("  2. 0x%06X is an instruction boundary : %s   (nearby: %s)"
              % (hi, "ok" if end_is_boundary else "FAIL",
                 ", ".join("0x%06X" % a for a in near)))
        print("  3. directory slots into the span     : %d, off-boundary %d %s"
              % (len(slots), len(off), ["0x%06X" % a for a in off[:8]]))
        print("  call/calr into a NON-boundary address:")
        print("     from a site that IS an instruction here : %d   <-- must be 0"
              % site_bad)
        print("     from a site that is NOT (phantom)       : %d" % site_ok)
        print("     from outside the span (unverifiable)    : %d" % outside)
        print("  VERDICT: %s" % ("self-consistent" if ok else "NOT self-consistent"))
    return ok


def main():
    if "--selftest" in sys.argv:
        # POSITIVE: the span this round converted.
        good = run(0xFE0000, 0xFE54B6)
        print()
        # NEGATIVE 1: a span that really does hold data tables -- 0xF86000 is
        # still .incbin for exactly this reason.  Must fail tests 1 and 3.
        bad_data = run(0xF86000, 0xF8969B)
        print()
        # NEGATIVE 2: the same converted span with an end that is NOT an
        # instruction boundary.  Must fail test 2 and nothing else.
        bad_end = run(0xFE0000, 0xFE54B4)
        print()
        # NOT a control: one byte late passes.  Printed so nobody re-derives it
        # as a surprise.
        late = run(0xFE0001, 0xFE54B6, quiet=True)
        print("selftest")
        print("  converted span 0xFE0000-0xFE54B6 self-consistent : %s (want True)"
              % good)
        print("  data-bearing span 0xF86000-0xF8969B              : %s (want False)"
              % bad_data)
        print("  end not on a boundary, 0xFE0000-0xFE54B4         : %s (want False)"
              % bad_end)
        print("  ⚠ started one byte late, 0xFE0001               : %s -- PASSES."
              " These tests do not pin the start." % late)
        return 0 if (good and not bad_data and not bad_end) else 1
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    return 0 if run(int(sys.argv[1], 16), int(sys.argv[2], 16)) else 1


if __name__ == "__main__":
    sys.exit(main())
