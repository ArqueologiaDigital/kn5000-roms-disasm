#!/usr/bin/env python3
"""prom_a_stale_twins.py -- which live routine is each stale handler a copy of, and how far did its call
targets move?

QUESTION IT ANSWERS
    An unreferenced block of handlers whose `call imm24` targets land mid-instruction is an older build's
    copy: its calls still hold the old addresses.  For each handler in [LO, HI) -- a `link` at an
    instruction start through the next `ret` -- this finds every other place in prom_a whose bytes are
    identical except for the 3-byte operands of the handler's `call`s (its live twins), and prints what
    the twin calls and the delta live - stale.  A delta shared by many twins pairs an old address with a
    live routine; a stale call with no twin is left unpaired.

    Instruction starts are read from the `; ADDR  bytes` comments of wsa1/prom_a/wsa1_prom_a.s; the
    bytes from wsa1/original_ROMs/wsa1_prom_a.ic12.  A handler cut off at the front (no `link`) is not
    examined.

RUN (from the repository root)
    python3 wsa1/notes/prom_a_stale_twins.py 0xFDFEE2 0xFDFFDF

SIGNAL
    "stale 0xS-0xE calls [...]" then one "twin 0xT live [...] delta [...]" line per twin.
    Recorded 2026-10-03 in wsa1/notes/FINDINGS-prom_a-fdfee2-stale-handlers.md.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
rom = open(os.path.join(ROOT, "wsa1/original_ROMs/wsa1_prom_a.ic12"), "rb").read()
B = 0xF80000
src = open(os.path.join(ROOT, "wsa1/prom_a/wsa1_prom_a.s"), "rb").read().decode("latin-1")
starts = {int(m.group(1), 16) for m in re.finditer(r";\s+([0-9A-F]{6})  [0-9a-f]{2}", src)}
LO, HI = int(sys.argv[1], 0), int(sys.argv[2], 0)
links = [a for a in range(LO, HI) if rom[a - B:a - B + 2] == b"\xee\x0c" and a in starts]
for s in links:
    e = s
    while rom[e - B] != 0x0E or e not in starts:
        e += 1
    body = rom[s - B:e + 1 - B]
    calls = [k for k in range(len(body) - 3) if body[k] == 0x1D and (s + k) in starts]
    mask = set(j for k in calls for j in range(k + 1, k + 4))
    rx = re.compile(b"".join(b"." if j in mask else re.escape(body[j:j + 1]) for j in range(len(body))), re.S)
    twins = [B + m.start() for m in rx.finditer(rom) if B + m.start() != s]
    old = [int.from_bytes(body[k + 1:k + 4], "little") for k in calls]
    print("stale 0x%06X-0x%06X calls %s" % (s, e, [hex(x) for x in old]))
    for t in twins:
        live = [int.from_bytes(rom[t - B + k + 1:t - B + k + 4], "little") for k in calls]
        print("   twin 0x%06X  live %s  delta %s" % (t, [hex(x) for x in live],
                                                     [hex(l - o) for l, o in zip(live, old)]))
