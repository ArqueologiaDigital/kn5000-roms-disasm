#!/usr/bin/env python3
"""Which bytes of a prom_b module are CODE, and which are DATA?

QUESTION IT ANSWERS
  Before a range can be converted, something has to decide where the
  instructions stop.  A linear sweep cannot: it happily decodes a data table
  and then resynchronises, and the only symptom is that a KNOWN entry point --
  a thunk target -- is no longer on an instruction boundary.  That is exactly
  what prom_b 0xF63441 does: the linear decode of the module steps over
  0xF63489, and 0xF63489 is the target of thunk slot T_F42790.

  This script does a RECURSIVE DESCENT inside one address range instead, seeded
  from the module's own entry points, and prints the runs no walk ever reached.
  Those runs are the data islands.

WHAT IT USES
  * the decode table of `scripts/analysis/trace_code.py` -- unidasm run once per
    byte phase and merged, so a length is available at EVERY address, not only
    at the ones a linear sweep happened to land on;
  * the thunk table's `jp` slots (`scripts/analysis/prom_b_thunk_table.py`) as
    the outside world's entry points into the range;
  * every `call`/`calr`/`jp`/`jr`/`jrl` target discovered while walking, which
    is what picks up entries reached only from inside.

WHAT IT DOES NOT CLAIM
  An unreached run is a run this walk did not reach.  A routine entered only
  through a POINTER TABLE would look like data here.  So "data island" is a
  finding to be checked by looking at the bytes, never a conclusion on its own;
  the script prints the bytes for exactly that reason.  Conversely a run this
  walk DOES reach is code: it was reached by following real control flow from a
  real entry point.

RUN
  python3 notes/prom_b_module_trace.py 0xF62C00 0xF64C10
  python3 notes/prom_b_module_trace.py 0xF62C00 0xF64C10 --entries
  python3 notes/prom_b_module_trace.py --selftest
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import trace_code as TC                                            # noqa: E402
import prom_b_thunk_table as TT                                    # noqa: E402

B_BASE = 0xF00000
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
_tab = None


def table():
    global _tab
    if _tab is None:
        _tab = TC.decode_table(IMG, B_BASE)
    return _tab


def decode_at(addr, window=0x40):
    """(length, text) for the instruction AT addr, decoded from addr itself.

    trace_code.decode_table merges 32 phase-shifted sweeps of the whole ROM, and
    that is NOT enough: the sweeps resynchronise long before they reach a given
    module, so an address no sweep happened to land on has no entry.  Both of
    the entry points this script exists to find -- 0xF63489 and 0xF63CE0 -- are
    such addresses.  This decodes the window starting exactly at addr, which by
    construction puts addr on a boundary."""
    tab = table()
    if addr in tab:
        return tab[addr]
    data = open(IMG, "rb").read()
    o = addr - B_BASE
    if o < 0 or o >= len(data):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([TC.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m and int(m.group(1), 16) == addr:
            tab[addr] = (len(m.group(2).split()), m.group(3).strip())
            return tab[addr]
    return None


def thunk_entries(lo, hi):
    """jp-slot targets of the thunk table that land in [lo,hi)."""
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    out = []
    for slot in range(0x40000, 0x44018, 4):
        if b[slot] == 0x1B:
            t = b[slot + 1] | b[slot + 2] << 8 | b[slot + 3] << 16
            if lo <= t < hi:
                out.append((B_BASE + slot, t))
    return out


def trace(lo, hi, seeds):
    table()
    seen, work = set(), list(seeds)
    entries = set(seeds)
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen:
            d = decode_at(p)
            if d is None:
                break
            n, txt = d
            seen.update(range(p, p + n))
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen:
                    work.append(t)
                    if txt.split()[0] in ("call", "calr"):
                        entries.add(t)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen, entries


def runs(lo, hi, seen):
    out, p = [], lo
    while p < hi:
        if p in seen:
            p += 1
            continue
        q = p
        while q < hi and q not in seen:
            q += 1
        out.append((p, q))
        p = q
    return out


def report(lo, hi, show_entries=False):
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    th = thunk_entries(lo, hi)
    seeds = sorted(set(t for _, t in th))
    if not seeds:
        seeds = [lo]
    seen, entries = trace(lo, hi, seeds)
    print("range 0x%06X-0x%06X  (%d bytes)" % (lo, hi, hi - lo))
    print("  thunk-table entry points: %d" % len(th))
    print("  reached as code: %d bytes (%.1f%%)"
          % (len(seen), 100.0 * len(seen) / (hi - lo)))
    if show_entries:
        for a in sorted(entries):
            src = [hex(s) for s, t in th if t == a]
            print("    entry 0x%06X%s" % (a, ("  <- thunk " + ",".join(src)) if src else ""))
    gaps = runs(lo, hi, seen)
    print("  runs never reached: %d" % len(gaps))
    for s, e in gaps:
        raw = b[s - B_BASE:e - B_BASE]
        distinct = sorted(set(raw))
        print("    0x%06X-0x%06X  %4d bytes  %d distinct byte values%s"
              % (s, e - 1, e - s, len(distinct),
                 "  (all 0x%02X)" % distinct[0] if len(distinct) == 1 else ""))
        for i in range(0, min(len(raw), 128), 16):
            print("        %06X  %s" % (s + i, raw[i:i + 16].hex(" ")))
        if len(raw) > 128:
            print("        ... %d more bytes" % (len(raw) - 128))
    return gaps


def selftest():
    """The 0xF63441 island is why this script exists; assert it comes back."""
    gaps = report(0xF62C00, 0xF64C10)
    want = (0xF63441, 0xF63489)
    ok = want in gaps
    print()
    print("selftest: 0xF63441-0xF63488 reported as unreached ... %s" % ("ok" if ok else "FAILED"))
    # and the entry it hides must be a thunk target
    th = dict((t, s) for s, t in thunk_entries(0xF62C00, 0xF64C10))
    ok2 = 0xF63489 in th
    print("selftest: 0xF63489 is a thunk target (0x%06X) ... %s"
          % (th.get(0xF63489, 0), "ok" if ok2 else "FAILED"))
    return 0 if (ok and ok2) else 1


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    report(int(sys.argv[1], 0), int(sys.argv[2], 0), "--entries" in sys.argv)
