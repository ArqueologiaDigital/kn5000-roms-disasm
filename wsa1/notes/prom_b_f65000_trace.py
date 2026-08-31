#!/usr/bin/env python3
"""Which bytes of prom_b 0xF65000-0xF6F000 are CODE, and which are DATA?

QUESTION IT ANSWERS
  notes/prom_b_module_trace.py reaches only 44.7% of this range, because the
  block is built almost entirely out of POINTER TABLES: a handler is selected by
  indexing a table of `jp addr24` slots (opcode 0x1B) or a table of 32-bit
  pointers, and the recursive descent has no way to follow either.  A run this
  script's parent calls "never reached" is therefore not evidence of data here.

  This script closes that hole in the only way that does not turn into a linear
  sweep: it alternates
      (1) recursive descent from the current seed set, and
      (2) a scan of the runs the descent did NOT reach for the two table shapes,
          whose entries become new seeds,
  to a fixpoint.  A seed added in step (2) is justified by a POINTER that names
  it, not by "the bytes decode".

WHAT COUNTS AS A TABLE ENTRY
  * `1B lo mid hi`             -> `jp 0x00hi_mid_lo`, the same 4-byte shape the
    thunk table at 0xF40000 uses (scripts/analysis/prom_b_thunk_table.py), with
    the target inside [lo,hi).
  * `lo mid hi 00`             -> a 32-bit pointer with the target inside
    [lo,hi).  Required to sit at a 4-byte stride from a neighbouring entry of
    the same shape, so an accidental match inside code cannot seed the walk on
    its own -- a lone match is reported and NOT followed.

RUN
  python3 notes/prom_b_f65000_trace.py                 # the residue
  python3 notes/prom_b_f65000_trace.py --tables        # the pointer tables found
  python3 notes/prom_b_f65000_trace.py --entries       # every entry point
  python3 notes/prom_b_f65000_trace.py --lo 0xF65000 --hi 0xF6F000
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import trace_code as TC                                            # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402

B_BASE = 0xF00000
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
LO, HI = 0xF65000, 0xF6F000


def rom():
    return open(IMG, "rb").read()


def jp_slots(d, lo, hi, s, e):
    """4-byte `jp addr24` slots inside [s,e) whose target is inside [lo,hi)."""
    out = []
    for a in range(s, e - 3):
        o = a - B_BASE
        if d[o] == 0x1B:
            t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
            if lo <= t < hi:
                out.append((a, t))
    return out


def ptr_slots(d, lo, hi, s, e):
    """4-byte little-endian pointers inside [s,e) whose target is in [lo,hi)."""
    out = []
    for a in range(s, e - 3):
        o = a - B_BASE
        if d[o + 3] == 0x00:
            t = d[o] | d[o + 1] << 8 | d[o + 2] << 16
            if lo <= t < hi:
                out.append((a, t))
    return out


def paired(slots):
    """Keep only entries with a same-shape neighbour exactly 4 bytes away."""
    at = {a for a, _ in slots}
    return [(a, t) for a, t in slots if (a - 4) in at or (a + 4) in at]


def classify(d, s, e):
    """A one-word shape for an unreached run.  Descriptive only -- it is the
    hex/ASCII the reader judges, not this word."""
    raw = d[s - B_BASE:e - B_BASE]
    if set(raw) == {0x0E}:
        return "FILL"
    n = e - s
    if n % 4 == 0 and n >= 8 and all(raw[i + 3] == 0x00 and 0xF0 <= raw[i + 2] <= 0xFF
                                     for i in range(0, n, 4)):
        return "PTR32 x%d" % (n // 4)
    if n % 4 == 0 and n >= 8 and all(raw[i] == 0x1B for i in range(0, n, 4)):
        return "JPTBL x%d" % (n // 4)
    if sum(1 for c in raw if 32 <= c < 127) >= 0.8 * n:
        return "ASCII"
    return "?"


def far_calls(d, lo, hi):
    """Opcode-anchored `call addr24` / `jp addr24` sites in prom_a+prom_b whose
    target is inside [lo,hi).  An UPPER BOUND (the scan is at every byte, not at
    instruction boundaries) -- used only to SEED the descent, never quoted as a
    call count."""
    a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    out = []
    for blob, base in ((a, 0xF80000), (d, B_BASE)):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.append((base + i, t))
    return out


def imm_targets(seen_lines, lo, hi):
    """Addresses in [lo,hi) that appear as a 32-bit IMMEDIATE in an instruction
    the descent already decoded (`ld XIY,0x00f68a35`, `lda ...`)."""
    out = set()
    for txt in seen_lines:
        for m in re.findall(r"0x00([0-9a-f]{6})", txt):
            v = int(m, 16)
            if lo <= v < hi:
                out.add(v)
    return out


def survey(lo=LO, hi=HI, verbose=False):
    d = rom()
    th = MT.thunk_entries(lo, hi)
    seeds = set(t for _, t in th)
    seeds |= {t for _, t in far_calls(d, lo, hi)}
    tables = []
    lone = []
    for _ in range(50):
        seen, entries = MT.trace(lo, hi, sorted(seeds))
        gaps = MT.runs(lo, hi, seen)
        new = set()
        tab = MT.table()
        new |= imm_targets([tab[a][1] for a in sorted(seen) if a in tab],
                           lo, hi) - seeds
        for s, e in gaps:
            js = jp_slots(d, lo, hi, s, e)
            ps = paired(ptr_slots(d, lo, hi, s, e))
            solo = [x for x in ptr_slots(d, lo, hi, s, e) if x not in ps]
            for a, t in js + ps:
                if t not in seeds:
                    new.add(t)
                    tables.append((a, t, "jp" if (a, t) in js else "ptr"))
            lone += solo
        if not new:
            break
        seeds |= new
    return seen, entries, gaps, sorted(set(tables)), sorted(set(lone)), th


def linear_lands(d, s, e):
    """Does a LINEAR decode from s consume [s,e) exactly?

    Both edges of an unreached run are proven instruction boundaries: the byte
    before s is the last byte of an instruction the descent decoded, and e is an
    address the descent decoded AT.  A linear decode is not evidence on its own
    (notes/prom_a_linear_decode_check.py: TLCS-900 resynchronises), but a decode
    that starts on a proven boundary and lands EXACTLY on the next proven
    boundary having consumed every byte is a different claim: a wrong split
    would have to re-synchronise onto the same byte.  Returns (lands, ninstr).
    """
    p, n = s, 0
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return False, n
        p += dec[0]
        n += 1
    return p == e, n


def selfconsistent(d, s, e, seen):
    """A STRONGER code test than linear_lands(), and the reason that one is not
    used: the run must decode from s to e exactly, contain no `db`
    (undefined-opcode) line, and every RELATIVE branch it contains must target
    an instruction boundary -- either one of its own, or an address the descent
    already proved is a boundary.  Returns (ok, nbranch, why).

    Data resynchronises; data whose every embedded displacement happens to point
    at a decode boundary does not.  The counts this prints on the known ASCII and
    known pointer-table runs are what says whether the test discriminates."""
    p, bounds, ins = s, set(), []
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return False, 0, "undecodable at 0x%06X" % p
        bounds.add(p)
        ins.append((p, dec[0], dec[1]))
        p += dec[0]
    if p != e:
        return False, 0, "overruns to 0x%06X" % p
    nb = 0
    for a, n, txt in ins:
        if txt.split()[0] == "db" or txt.strip() == "db":
            return False, nb, "undefined opcode at 0x%06X" % a
        m = re.match(r"^(jr|jrl|calr)\b", txt)
        if not m:
            continue
        for t in TC.branch_targets(txt):
            nb += 1
            if t not in bounds and t not in seen:
                return False, nb, "branch at 0x%06X -> 0x%06X is not a boundary" % (a, t)
    return True, nb, "ok"


def accept_code(d, gaps, seen):
    """Iterate selfconsistent() to a fixpoint.

    A run that passes becomes code, and ITS instruction boundaries then count
    for the runs still under test -- which is what a single pass cannot do:
    0xF68A35 branches to 0xF6B96F, and 0xF6B96F is itself an unreached run, so
    on the first pass neither can be accepted and on the second both are."""
    ok, pending = {}, list(gaps)
    for _ in range(20):
        grew = False
        still = []
        for s, e in pending:
            good, nb, why = selfconsistent(d, s, e, seen)
            if good:
                ok[(s, e)] = nb
                p = s
                while p < e:
                    dec = MT.decode_at(p)
                    seen.add(p)
                    p += dec[0]
                grew = True
            else:
                still.append((s, e))
        pending = still
        if not grew:
            break
    return ok, pending


def main():
    lo = LO
    hi = HI
    if "--lo" in sys.argv:
        lo = int(sys.argv[sys.argv.index("--lo") + 1], 0)
    if "--hi" in sys.argv:
        hi = int(sys.argv[sys.argv.index("--hi") + 1], 0)
    seen, entries, gaps, tables, lone, th = survey(lo, hi)
    d = rom()
    print("range 0x%06X-0x%06X  (%d bytes)" % (lo, hi, hi - lo))
    print("  thunk-table entry points: %d" % len(th))
    print("  pointer-table entries followed: %d" % len(tables))
    print("  reached as code: %d bytes (%.1f%%)"
          % (len(seen), 100.0 * len(seen) / (hi - lo)))
    if "--tables" in sys.argv:
        for a, t, k in tables:
            print("    %-3s 0x%06X -> 0x%06X" % (k, a, t))
        print("  unpaired 32-bit matches NOT followed: %d" % len(lone))
        for a, t in lone:
            print("    lone 0x%06X -> 0x%06X" % (a, t))
    if "--entries" in sys.argv:
        for a in sorted(entries):
            print("    entry 0x%06X" % a)
    print("  runs never reached: %d  (%d bytes)"
          % (len(gaps), sum(e - s for s, e in gaps)))
    for s, e in gaps:                       # e is EXCLUSIVE
        raw = d[s - B_BASE:e - B_BASE]
        distinct = sorted(set(raw))
        pr = "".join(chr(c) if 32 <= c < 127 else "." for c in raw[:64])
        print("    0x%06X..0x%06X  %5d bytes  %3d distinct%s  %s"
              % (s, e, e - s, len(distinct),
                 "  (all 0x%02X)" % distinct[0] if len(distinct) == 1 else "",
                 classify(d, s, e)))
        print("        |%s|" % pr)
        if "--anchor" in sys.argv:
            lands, n = linear_lands(d, s, e)
            ok, nb, why = selfconsistent(d, s, e, seen)
            print("        linear: %-12s  self-consistent: %-5s %2d rel-branches  %s"
                  % ("LANDS" if lands else "no", "YES" if ok else "no", nb, why))
    if "--discriminate" in sys.argv:
        # Does linear_lands() discriminate code from data?  It does not, and
        # this is the measurement that says so.  selfconsistent() does.
        rows = []
        for s_, e_ in gaps:
            rows.append((classify(d, s_, e_),
                         linear_lands(d, s_, e_)[0],
                         selfconsistent(d, s_, e_, seen)[0]))
        def tally(pred, label):
            sel = [r for r in rows if pred(r[0])]
            print("  %-22s %3d runs   linear LANDS %3d   self-consistent %3d"
                  % (label, len(sel), sum(1 for r in sel if r[1]),
                     sum(1 for r in sel if r[2])))
        tally(lambda k: True, "all unreached runs")
        tally(lambda k: k.startswith("PTR32"), "tagged PTR32")
        tally(lambda k: k == "ASCII", "tagged ASCII")
        tally(lambda k: k == "FILL", "tagged FILL (0x0E)")
        tally(lambda k: k == "?", "tagged ? (unknown)")
        print("  A criterion that passes the pointer tables and the strings is")
        print("  not a code/data test.  linear_lands() is kept only so nobody")
        print("  re-invents it; the layout uses selfconsistent().")
        return 0
    if "--accept" in sys.argv:
        okd, pend = accept_code(d, gaps, set(seen))
        codeb = sum(e - s for s, e in okd)
        print("  SELF-CONSISTENT CODE runs accepted: %d  (%d bytes)"
              % (len(okd), codeb))
        for (s, e), nb in sorted(okd.items()):
            print("    code 0x%06X..0x%06X %5d bytes  %2d rel-branches" % (s, e, e - s, nb))
        print("  runs still NOT code: %d  (%d bytes)"
              % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - B_BASE:e - B_BASE]
            print("    data 0x%06X..0x%06X %5d bytes  %-10s |%s|"
                  % (s, e, e - s, classify(d, s, e),
                     "".join(chr(c) if 32 <= c < 127 else "." for c in raw[:56])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
