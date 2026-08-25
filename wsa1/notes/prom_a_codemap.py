#!/usr/bin/env python3
"""Which bytes of a prom_a range are reachable CODE, and which are DATA?

QUESTION IT ANSWERS
    Before converting a module you have to know where its data tables are.  A
    linear sweep does not tell you: unidasm decodes a table of pointers into
    tidy-looking instructions, and prom_a/roundtrip.py will happily round-trip
    them byte-exactly -- the GATE cannot catch it, because the bytes are right
    and only the meaning is wrong.  The FDC module of 2026-08-25 was uniformly
    code and needed none of this; the 0xF86000 module is not.

METHOD
    Recursive descent from seeds, using the phase-merged decode table of
    scripts/analysis/trace_code.py (which is the tool that already establishes
    "reachable" for this tree's memory-map work).  Seeds are, by default:
      * every target of a prom_b thunk-table slot that lands in the range;
      * every `jp abs` at the range's first 4-byte-aligned words, while they
        keep pointing into the range (module entry directories look like that);
      * plus anything given on the command line.
    Everything the walk reaches is CODE; everything else in the range is
    reported as a DATA candidate.

WHAT IS EXACT AND WHAT IS NOT
    NOT EXACT in one direction: code reached only through a computed jump or a
    pointer table this walk does not know about will be reported as data.  Read
    the data runs before believing them -- a run that disassembles as sane code
    is a missing seed, not a table.
    EXACT in the other: everything it calls CODE really is reached by a
    control-flow path from a seed.

RUN
    python3 notes/prom_a_codemap.py 0xF86000 0xF87000
    python3 notes/prom_a_codemap.py 0xF86000 0xF87000 0xF86123   # extra seed
"""
import importlib.util
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location(
    "tc", os.path.join(ROOT, "scripts", "analysis", "trace_code.py"))
tc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tc)

A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE, B_BASE = 0xF80000, 0xF00000
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018


def main():
    lo, hi = int(sys.argv[1], 16), int(sys.argv[2], 16)
    extra = [int(x, 16) for x in sys.argv[3:]]
    tab = tc.decode_table(os.path.join(ROOT, "original_ROMs",
                                       "wsa1_prom_a.ic12"), A_BASE)

    def decode(addr):
        """One instruction at ADDR.  The phase-merged table of trace_code.py
        misses an address when no phase's greedy sweep happens to land on it
        (0xF86CAE is one), and a walk that treats a miss as "not code" then
        reports live routines as data.  So decode on demand."""
        if addr in tab:
            return tab[addr]
        with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as t:
            t.write(A[addr - A_BASE:addr - A_BASE + 16])
            path = t.name
        try:
            out = subprocess.run([tc.UNIDASM, path, "-arch", "tlcs900",
                                  "-basepc", "0x%X" % addr],
                                 capture_output=True, text=True).stdout
        finally:
            os.unlink(path)
        for ln in out.splitlines():
            m = tc.LINE.match(ln)
            if m and int(m.group(1), 16) == addr:
                tab[addr] = (len(m.group(2).split()), m.group(3).strip())
                return tab[addr]
        return None

    seeds = set(extra)
    # (1) prom_b thunk slots naming this range
    for slot in range(THUNK_LO, THUNK_HI, 4):
        o = slot - B_BASE
        if B[o] == 0x1B:
            t = B[o + 1] | (B[o + 2] << 8) | (B[o + 3] << 16)
            if lo <= t < hi:
                seeds.add(t)
    n_thunk = len(seeds - set(extra))
    # (2) a leading `jp abs` entry directory
    a = lo
    while a + 4 <= hi and A[a - A_BASE] == 0x1B:
        t = int.from_bytes(A[a - A_BASE + 1:a - A_BASE + 4], "little")
        if not (lo <= t < hi):
            break
        seeds.add(t)
        a += 4
    n_dir = (a - lo) // 4
    print("seeds: %d from prom_b thunk slots, %d from the leading `jp` directory "
          "at 0x%06X (%d words), %d given"
          % (n_thunk, n_dir, lo, n_dir, len(extra)))

    seen, work = set(), list(seeds)
    while work:
        p = work.pop()
        while True:
            if p in seen or not (lo <= p < hi) or decode(p) is None:
                break
            seen.add(p)
            n, txt = tab[p]
            for t in tc.branch_targets(txt):
                if t not in seen and lo <= t < hi:
                    work.append(t)
            if tc.is_flow_end(txt):
                break
            p += n

    covered = bytearray(hi - lo)
    for p in seen:
        n = tab[p][0]
        for i in range(p, min(p + n, hi)):
            covered[i - lo] = 1
    # the leading directory is code by construction
    for i in range(lo, lo + n_dir * 4):
        covered[i - lo] = 1

    nb = sum(covered)
    print("range 0x%06X-0x%06X = %d bytes: %d code (%.1f%%), %d data candidates"
          % (lo, hi - 1, hi - lo, nb, 100.0 * nb / (hi - lo), hi - lo - nb))
    print("\nruns:")
    i = 0
    while i < hi - lo:
        j = i
        while j < hi - lo and covered[j] == covered[i]:
            j += 1
        print("  0x%06X-0x%06X  %5d  %s"
              % (lo + i, lo + j - 1, j - i, "CODE" if covered[i] else "data?"))
        i = j


if __name__ == "__main__":
    main()
