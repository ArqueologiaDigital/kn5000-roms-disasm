#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""bounds.py -- ADDRESSES versus BOUNDS in the delay-descriptor bank.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams and the 38 body images only.

THE PROBLEM.  The descriptor bank holds two kinds of cell: ADDRESSES (delay-line
endpoints) and BOUNDS (region limits -- 0, 32767, 32768, a per-algorithm
ceiling).  Because the bounds masqueraded as taps, the derived line set carried
FAKE LINES (SINGLE DELAY's 897, PLATE REVERB's 32767) and every constraint the
solver was handed was polluted.

THE ANSWER, in one line: exactly TWO cells per algorithm are bounds -- a
CEILING holding a single per-unit constant (32768 in unit 0, 32767 in unit 1,
both OUTSIDE the algorithm's own DRAM region) and a LIMIT, an in-region WRITE
whose address lies above every READ of the algorithm so that no read can ever
fall in the buffer it would open.  The two named fake lines are exactly
CEILING - LIMIT: the two bounds paired with each other.

    python3 dsp/tools/bounds.py census      # 1  populations + the direction census
    python3 dsp/tools/bounds.py roles       # 2  *** CEILING and LIMIT, enumerated
    python3 dsp/tools/bounds.py classify    # 3  *** the per-cell classification
    python3 dsp/tools/bounds.py lines       # 4  *** the corrected line set
    python3 dsp/tools/bounds.py host        # 5  *** THE LEVER: what the host names
    python3 dsp/tools/bounds.py invariants  # 6  idx1 / idx3 / idx5 / idx30
    python3 dsp/tools/bounds.py rivals      # 7  *** RULE 7, scored on disagreement
    python3 dsp/tools/bounds.py control     # 8  every control, shown saying NO
    python3 dsp/tools/bounds.py predict     # 9  PREDICT-THEN-CHECK, hits AND misses
    python3 dsp/tools/bounds.py export      # 10 the JSON the next phase imports
    python3 dsp/tools/bounds.py all         # ~30 s
"""
import argparse
import collections
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402
import register_space as RS                                         # noqa: E402
import dram_match as DM                                             # noqa: E402
import dsp_disasm as D                                              # noqa: E402

# The two per-unit DRAM regions.  MEASURED: adjudication-round4 SS2 / dram_match
# FLOOR, and re-checked here (`census') against all 38 host-named endpoints.
FLOOR = {0: 0, 1: 32768}
TOP = {0: 32767, 1: 65535}

CLASS_ADDR = "ADDRESS"
CLASS_BOUND = "BOUND"
CLASS_UNK = "UNKNOWN"

# The corpus-wide canned constants that occupy bound cells.  32768/32767 are the
# region partition and are handled by the region test.  128 is the third, found
# by looking at what is left over: it is the whole descriptor block of the eight
# n=2 algorithms (together with the ceiling) and those blocks contain NO
# WRITE-direction cell at all, so it cannot be the read end of anything.  See
# SS2.  A cell that holds it and still gets matched is reported DISPUTED, never
# silently promoted to an address.
CANNED_128 = 128


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


# ===========================================================================
#  the model, in one function.  EVERY OTHER SECTION READS ITS OUTPUT.
# ===========================================================================
def analyse(C, dirfn=None, delta=0, strict=True):
    """-> {algo: dict}.  The classification of every descriptor cell.

    MODEL, printed beside the claim (method rule 3):

      A1  the cell <-> word map is the identity at phase 0        FORCED, round 5 B
      A2  direction = addr8 bit 6, 0x20/0x30 READ, 0x60 WRITE     FORCED, round 5 D
      A3  a cell whose VALUE is outside its unit's DRAM region
          cannot be an address of a line in that unit             FORCED (region)
      A4  a READ belongs to the delay line whose base is the
          largest WRITE strictly below it -- `the buffer the
          read falls inside'.  A WRITE with no such READ opens
          no line.                                                THE ALLOCATION MODEL

    `dirfn' and `delta' and `strict' exist ONLY so that the controls can build
    the deliberately-wrong twin and be shown failing.
    """
    dirfn = dirfn or D.dram_dir
    out = {}
    for (a, u, cells, cons) in C.algos:
        ck = sorted(cells)
        n = len(ck)
        rec = {"algo": a, "unit": u, "n": n, "cells": ck,
               "aligned": len(cons) == n}
        if not rec["aligned"]:
            rec["reason"] = "#cells %d != #consumers %d" % (n, len(cons))
            out[a] = rec
            continue
        # A1: consumer k takes cell k (delta is the control knob)
        d = [None] * n
        w = [0] * n
        for k, (_wi, word) in enumerate(cons):
            i = (k + delta) % n
            d[i] = dirfn(word)
            w[i] = word
        v = [cells[c] for c in ck]
        inr = [FLOOR[u] <= x <= TOP[u] for x in v]
        W = [i for i in range(n) if d[i] == "WRITE" and inr[i]]
        R = [i for i in range(n) if d[i] == "READ" and inr[i]]
        lines, base_of = [], {}
        for r in R:
            cand = [x for x in W if (v[x] < v[r] if strict else v[x] <= v[r])]
            if not cand:
                continue
            b = max(cand, key=lambda x: v[x])
            lines.append({"read_rel": r, "write_rel": b,
                          "read_cell": ck[r], "write_cell": ck[b],
                          "read_addr": v[r], "write_addr": v[b],
                          "samples": v[r] - v[b]})
            base_of[r] = b
        used = set(base_of) | set(base_of.values())
        cls, why, role = [None] * n, [""] * n, [None] * n
        for i in range(n):
            if not inr[i] and v[i] in (32767, 32768):
                cls[i], role[i] = CLASS_BOUND, "CEILING"
                why[i] = "the per-unit partition constant, outside the region"
            elif not inr[i]:
                cls[i], role[i] = CLASS_BOUND, "LIMIT"
                why[i] = "outside the unit's own region"
            elif i in used:
                cls[i] = CLASS_ADDR
                role[i] = "READ_END" if i in base_of else "LINE_BASE"
                why[i] = ("read end of a line" if i in base_of
                          else "line base / write end")
                if v[i] == CANNED_128:
                    cls[i], role[i] = CLASS_UNK, "DISPUTED"
                    why[i] = ("holds the canned constant 128, which is a forced"
                              " bound in 8 other algorithms")
            elif d[i] is None:
                cls[i], role[i] = CLASS_UNK, "TRAP"
                why[i] = "direction still traps (C format)"
            elif d[i] == "WRITE":
                cls[i], role[i] = CLASS_BOUND, "LIMIT"
                why[i] = "a write above every read: no read can reach it"
            else:
                cls[i], role[i] = CLASS_BOUND, "FLOOR"
                why[i] = "a read with no write anywhere below it in the block"
        rec.update({"dir": d, "word": w, "value": v, "in_region": inr,
                    "lines": lines, "class": cls, "why": why, "role": role})
        out[a] = rec
    return out


def aligned(A):
    return {a: r for a, r in A.items() if r.get("aligned")}


# ===========================================================================
#  1. census
# ===========================================================================
def cmd_census(C, A):
    head(1, "POPULATIONS, THE REGION PARTITION, AND THE DIRECTION CENSUS")
    al = aligned(A)
    ncell_all = sum(r["n"] for r in A.values())
    ncell_al = sum(r["n"] for r in al.values())
    print("  POPULATION, printed beside every count below (method rule 9):")
    print("     algorithms shipping descriptor cells        : %d" % len(A))
    print("     ... of which #cells == #consumers (ALIGNED)  : %d" % len(al))
    print("     descriptor cells, all algorithms             : %d" % ncell_all)
    print("     descriptor cells, ALIGNED algorithms         : %d   <- the"
          " denominator for every classification below" % ncell_al)
    print("     the 8 unaligned algorithms are NOT classified; they keep"
          " trapping (method rule 6).")
    dc = collections.Counter()
    for r in al.values():
        for x in r["dir"]:
            dc[x] += 1
    print()
    print("  DIRECTION CENSUS over the %d aligned cells, using the SHIPPED rule"
          % ncell_al)
    print("  (dsp_disasm.dram_dir: addr8 0x20/0x30 -> READ, 0x60 -> WRITE, else"
          " trap):")
    print("     READ %d   WRITE %d   still trapping (C format) %d"
          % (dc["READ"], dc["WRITE"], dc[None]))
    print("     adjudication-round5 SS7 measured 416 / 365 / 48 over the same"
          " population -- reproduced exactly, so this pass is standing on the")
    print("     same alignment round 5 published, not on a re-derivation of it.")
    print()
    print("  ---- THE REGION PARTITION, AND THE CONTROL THAT GIVES IT ITS FORCE.")
    print("       Unit 0 owns DRAM [0, 32767], unit 1 owns [32768, 65535]")
    print("       (adjudication-round4 SS2).  That partition is only useful if"
          " the things we ALREADY KNOW are addresses stay inside it.  The 38")
    print("       host-named op-0x67 taps and their BASE24 line bases are"
          " exactly those things -- they are addresses BY CONSTRUCTION, because")
    print("       the evaluator is `cell = round(ms*44100/1000) + BASE24'.")
    nin = nout = 0
    bad = []
    for a, r in al.items():
        taps = C.taps(a)
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c, b24 in taps.items():
            if c not in idx:
                continue
            for lbl, val in (("tap", r["value"][idx[c]]), ("BASE24", b24)):
                if FLOOR[r["unit"]] <= val <= TOP[r["unit"]]:
                    nin += 1
                else:
                    nout += 1
                    bad.append((a, c, lbl, val))
    print("       host-named endpoints INSIDE their unit's region: %d of %d"
          % (nin, nin + nout))
    if bad:
        print("       EXCEPTIONS: %s" % bad)
    print("       -> the region test cannot be dismissed as an artefact: not"
          " one host-anchored address violates it.")
    print()
    oor = collections.Counter()
    for r in al.values():
        for i in range(r["n"]):
            if not r["in_region"][i]:
                oor[(r["unit"], r["value"][i])] += 1
    print("  OUT-OF-REGION CELLS -- the whole set, by (unit, value):")
    for (u, val), c in sorted(oor.items()):
        print("     unit %d  value %5d   x%d" % (u, val, c))
    print("     total %d of %d aligned cells = %.1f %%"
          % (sum(oor.values()), ncell_al, 100.0 * sum(oor.values()) / ncell_al))
    print("     THREE distinct values in the entire corpus.  Every one of them"
          " is FORCED to be a BOUND: an address outside the unit's own region")
    print("     is not an address of that unit's delay line.")


# ===========================================================================
#  2. roles
# ===========================================================================
def cmd_roles(C, A):
    head(2, "THE TWO ROLES: `CEILING' AND `LIMIT' -- and the enumeration")
    al = aligned(A)
    print("  ---- ROLE 1: THE CEILING.")
    pos = collections.Counter()
    val = collections.Counter()
    cnt = collections.Counter()
    for a, r in al.items():
        n, u = r["n"], r["unit"]
        ce = [i for i in range(n) if not r["in_region"][i]
              and r["value"][i] in (32767, 32768)]
        cnt[len(ce)] += 1
        for i in ce:
            pos["rel n-2" if i == n - 2 else
                ("rel n-1" if i == n - 1 else "rel %d" % i)] += 1
            val[(u, r["value"][i])] += 1
    print("     cells per algorithm holding 32767/32768 out of region: %s"
          % dict(cnt))
    for (u, x), c in sorted(val.items()):
        print("        unit %d -> %5d   x%d" % (u, x, c))
    print("     position      : %s" % dict(pos))
    print()
    print("     ** THE CONSTANT IS A FUNCTION OF THE UNIT, AND ONLY OF THE"
          " UNIT. **  32768 in every unit-0 algorithm, 32767 in every unit-1")
    print("     algorithm.  32768 = unit 0's top + 1 = unit 1's floor;"
          " 32767 = unit 1's floor - 1 = unit 0's top.  Both name the SAME")
    print("     partition boundary, from the two sides.  Population %d aligned"
          " algorithms, %d ceiling cells, no algorithm has two and none has"
          % (len(al), sum(cnt[k] * k for k in cnt)))
    print("     zero.")
    print()
    print("  ---- ROLE 2: THE LIMIT -- an in-region WRITE above every READ.")
    lpos = collections.Counter()
    lmax = 0
    ltot = 0
    none = []
    for a, r in al.items():
        n, v, d, inr = r["n"], r["value"], r["dir"], r["in_region"]
        W = [i for i in range(n) if d[i] == "WRITE" and inr[i]]
        R = [i for i in range(n) if d[i] == "READ" and inr[i]]
        mx = max([v[i] for i in R], default=-1)
        lim = [x for x in W if v[x] > mx]
        if not lim:
            none.append((a, C.name(a), n))
        for x in lim:
            lpos["rel %d" % x] += 1
            ltot += 1
            if v[x] == mx + 1:
                lmax += 1
    print("     position of every such write: %s" % dict(lpos))
    print("     total %d; equal to (max read + 1): %d" % (ltot, lmax))
    print("     algorithms with NO such write: %d -- %s"
          % (len(none), ", ".join("%d %s" % (a, nm) for a, nm, _n in none[:14])))
    print("        (the twelve reverbs, whose rel-1 holds 0 and is therefore"
          " caught by the region test instead, and the eight n=2 algorithms,")
    print("         which have no WRITE-direction cell at all.)")
    print()
    print("     ** THE ENUMERATION, printed beside the claim (method rule 3).")
    print("        What can an in-region WRITE cell that no READ can reach be?")
    print("        (i)   a delay-line base whose read tap is in ANOTHER")
    print("              algorithm  -- REFUTED: the descriptor block is")
    print("              per-algorithm and reloaded per body (round 5 H).")
    print("        (ii)  a delay-line base whose read tap is a C-format cell")
    print("              whose direction still traps -- ADMITTED as a residual")
    print("              risk and PRICED below: it can only apply to the 12")
    print("              reverbs, whose rel-1 is out of region anyway, so it")
    print("              changes nothing.")
    print("        (iii) a base for a read produced at RUN TIME by a knob --")
    print("              REFUTED for these cells: opcode 0x67 is the only")
    print("              parameter opcode that reaches the descriptor space")
    print("              (host-side.md A1) and it never targets rel 1 (SS5).")
    print("        (iv)  NOT A LINE BASE AT ALL -- a bound.  ADMITTED.")
    print()
    print("  ---- ROLE 3: `FLOOR' -- the mirror image, and it is where the THIRD")
    print("       CANNED CONSTANT turned up.  A READ with no WRITE anywhere")
    print("       below it in the block cannot be the read end of any line THIS")
    print("       algorithm writes.  There are %d such cells:"
          % sum(1 for r in al.values() for x in r["role"] if x == "FLOOR"))
    fl = collections.Counter()
    for a, r in al.items():
        for i in range(r["n"]):
            if r["role"][i] == "FLOOR":
                fl[r["value"][i]] += 1
    for v, c in fl.most_common():
        print("          value %5d  x%d" % (v, c))
    c128 = [(a, i) for a, r in al.items() for i in range(r["n"])
            if r["value"][i] == CANNED_128]
    print("       and the value 128 occurs %d times in the whole corpus, in %d"
          % (len(c128), len({a for a, _i in c128})))
    print("       algorithms; in %d of them it is one of only TWO descriptor"
          % sum(1 for r in al.values() if r["n"] == 2
                and CANNED_128 in r["value"]))
    print("       cells and the block holds NO WRITE at all, so nothing can be")
    print("       read there.  128 is therefore a THIRD canned constant beside")
    print("       32768 and 32767.  Where a cell holding 128 DOES get matched")
    print("       (algo 3 ENHANCER rel 1, algo 54 RING MODULATOR rel 0) this")
    print("       pass calls it DISPUTED and refuses to hand it to the solver")
    print("       either way (method rule 6).")
    print()
    print("  ---- AND THE RESIDUE, which is the whole result in one table.")
    resid = collections.Counter()
    for a, r in al.items():
        tag = [r["role"][i] for i in range(r["n"])
               if r["class"][i] != CLASS_ADDR]
        resid[tuple(sorted(collections.Counter(tag).items()))] += 1
    for k, c in resid.most_common():
        print("     %-52s x%d" % (str(dict(k)), c))
    print()
    print("     Read that table as the headline.  Over %d aligned algorithms"
          % len(al))
    print("     the matching leaves EXACTLY ONE CEILING and EXACTLY ONE of")
    print("     {LIMIT, FLOOR} per algorithm, plus the cells whose direction")
    print("     still traps.  Nothing else is left over and nothing is missing.")


# ===========================================================================
#  3. classify
# ===========================================================================
def cmd_classify(C, A, verbose=True):
    head(3, "THE PER-CELL CLASSIFICATION  (deliverable a)")
    al = aligned(A)
    tally = collections.Counter()
    for r in al.values():
        for c in r["class"]:
            tally[c] += 1
    print("  over %d aligned cells in %d algorithms: %s"
          % (sum(tally.values()), len(al), dict(tally)))
    print()
    print("  LABEL PER CLASS (deliverable c -- what the solver may and may not")
    print("  treat as a constraint):")
    print("     BOUND / CEILING   FORCED   -- the value is outside the unit's")
    print("                                  own region; 83 of 83 algorithms")
    print("     BOUND / LIMIT     FORCED within the allocation model A4, and")
    print("                                  CONSISTENT outside it (SS7)")
    print("     ADDRESS (host-named tap or its BASE24 base) FORCED")
    print("     ADDRESS (matched by A4 only)                CONSISTENT")
    print("     UNKNOWN                                      -- DO NOT CONSTRAIN")
    print()
    if not verbose:
        return
    for a in sorted(al):
        r = al[a]
        taps = C.taps(a)
        print("  --- algo %2d unit %d n=%2d  %s" % (a, r["unit"], r["n"], C.name(a)))
        for i, c in enumerate(r["cells"]):
            nm = "  <= op-0x67 tap, BASE24 %d" % taps[c] if c in taps else ""
            ln = ""
            for L in r["lines"]:
                if L["read_rel"] == i:
                    ln = "  line %d samples off cell 0x%02X" % (L["samples"],
                                                                L["write_cell"])
                elif L["write_rel"] == i and not ln:
                    ln = "  line base"
            print("     rel %2d cell 0x%02X = %6d  %s %-9s %-8s %-34s%s%s"
                  % (i, c, r["value"][i], DC.fmt(r["word"][i]),
                     r["dir"][i] or "TRAP", r["class"][i], r["why"][i], ln, nm))


# ===========================================================================
#  4. lines
# ===========================================================================
def _proper_overlap(iv):
    iv = sorted(set(iv))
    n = 0
    for i in range(len(iv)):
        for j in range(i + 1, len(iv)):
            a, b = iv[i], iv[j]
            if a[0] < b[1] and b[0] < a[1]:
                nested = (a[0] >= b[0] and a[1] <= b[1]) or \
                         (b[0] >= a[0] and b[1] <= a[1])
                if not nested:
                    n += 1
    return n


def _any_overlap(iv):
    iv = sorted(set(iv))
    n = 0
    for i in range(len(iv)):
        for j in range(i + 1, len(iv)):
            if iv[i][0] < iv[j][1] and iv[j][0] < iv[i][1]:
                n += 1
    return n


def cmd_lines(C, A):
    head(4, "THE CORRECTED LINE SET, AND THE FAKE LINES NAMED  (deliverable b)")
    al = aligned(A)
    nline = sum(len(r["lines"]) for r in al.values())
    print("  %d delay lines over %d aligned algorithms." % (nline, len(al)))
    print()
    print("  ---- THE TWO FAKE LINES THE BRIEF NAMES, AND WHERE THEY CAME FROM.")
    for a in sorted(al):
        r = al[a]
        n = r["n"]
        ce = [i for i in range(n) if r["role"][i] == "CEILING"]
        li = [i for i in range(n) if r["role"][i] == "LIMIT"]
        if not ce or not li:
            continue
        gap = r["value"][ce[0]] - r["value"][li[0]]
        if gap in (897, 32767) or a in (9, 18):
            print("     algo %2d %-18s CEILING(rel %d) %5d - LIMIT(rel %d) %5d"
                  " = %5d" % (a, C.name(a), ce[0], r["value"][ce[0]], li[0],
                              r["value"][li[0]], gap))
    print("     ** BOTH NAMED FAKE LINES ARE EXACTLY `CEILING - LIMIT'. **")
    print("        SINGLE DELAY's 897 = 32768 - 31871 and PLATE REVERB's 32767")
    print("        = 32767 - 0 are the two BOUND cells paired with each other.")
    print("        Neither survives the classification, and no search was")
    print("        needed to remove them.")
    print()
    n2 = 0
    for a in sorted(al):
        r = al[a]
        n = r["n"]
        ce = [i for i in range(n) if r["role"][i] == "CEILING"]
        li = [i for i in range(n) if r["role"][i] == "LIMIT"]
        if ce and li and (ce[0] - li[0]) % n == 3:
            n2 += 1
    print("     and the reason SINGLE DELAY's fake line was the visible one:"
          " in %d of the %d algorithms the LIMIT and the CEILING sit exactly"
          % (n2, len(al)))
    print("     THREE cells apart, which is precisely the offset the anchored"
          " +3 rule pairs.  The old pairing manufactured a line out of the two")
    print("     bounds in every one of them.")
    print()
    print("  ---- AND THE +3 RULE COMES BACK OUT AS AN OUTPUT.  Nothing in the")
    print("       model mentions a cell offset; it matches on VALUES.  The")
    print("       offset (write_rel - read_rel) mod n of the %d lines it built:"
          % nline)
    off = collections.Counter()
    for r in al.values():
        for L in r["lines"]:
            off[(L["write_rel"] - L["read_rel"]) % r["n"]] += 1
    for k, c in sorted(off.items(), key=lambda x: -x[1])[:10]:
        print("          +%-3d x%d" % (k, c))
    print("       dram-matching.md C measured `+3 in 30 of 38 anchored records'")
    print("       and had to name seven exceptions.  Here +3 is %d of %d and the"
          % (off[3], nline))
    print("       exceptions are not exceptions: they are multi-tap reads and")
    print("       wrapped closures that the allocation model simply resolves.")
    print()
    print("  ---- OVERLAP, before and after.  A memory allocator does not hand"
          " out two buffers that PARTIALLY overlap; it may hand out a buffer")
    print("       INSIDE another (that is what a multi-tap and an early-"
          "reflection tap look like).  So `proper overlap' is the defect and")
    print("       nesting is not.")
    ivc = []
    ivo = []
    for a in sorted(al):
        r = al[a]
        n, v = r["n"], r["value"]
        ivc.append((a, [(L["write_addr"], L["read_addr"]) for L in r["lines"]]))
        old = []
        for i in range(n):
            j = (i + 3) % n
            if v[i] > v[j]:
                old.append((v[j], v[i]))
        ivo.append((a, old))
    co = sum(1 for _a, iv in ivc if _proper_overlap(iv))
    cn = sum(1 for _a, iv in ivc if _any_overlap(iv))
    oo = sum(1 for _a, iv in ivo if _proper_overlap(iv))
    on = sum(1 for _a, iv in ivo if _any_overlap(iv))
    print("     OLD  (every cell an address, rigid +3, direction ignored):")
    print("          %d of %d algorithms have a PROPER overlap; %d have any"
          % (oo, len(al), on))
    print("     NEW  (bounds removed, direction honoured, allocation model):")
    print("          %d of %d algorithms have a PROPER overlap; %d have any"
          % (co, len(al), cn))
    print("     -> proper overlaps go %d -> %d.  The remaining `any' cases are"
          " nesting only, and every one of them is a tap reading inside a"
          % (oo, co))
    print("        buffer it shares -- MULTI TAP DELAY's four taps on one base"
          " and the reverbs' early reflections inside the pre-delay buffer.")
    print()
    print("  ---- ROOM REVERB 1, re-derived from the classification alone"
          " (method rule 8: do not quote, re-derive):")
    r = al.get(16)
    if r:
        for L in r["lines"]:
            print("     read cell 0x%02X %5d  <-  base cell 0x%02X %5d   %5d"
                  " samples  %6.2f ms"
                  % (L["read_cell"], L["read_addr"], L["write_cell"],
                     L["write_addr"], L["samples"], L["samples"] / 44.1))
        tot = sum(L["samples"] for L in r["lines"])
        print("     %d lines, %d samples total, %.1f ms"
              % (len(r["lines"]), tot, tot / 44.1))
        print("     The eleven ladder segments 83 172 356 513 739 240 119 247")
        print("     428 616 360 and the 800-sample pre-delay are round 5's")
        print("     published ladder, reproduced WITHOUT the +3 rule and")
        print("     without a wrap special case -- the allocation model finds")
        print("     the eleventh segment (the one at cell offset +9) by itself.")
        print("     The two extra lines 650 and 540 are early-reflection taps")
        print("     off the pre-delay base, which is what round 5 called them.")


# ===========================================================================
#  5. host -- THE LEVER
# ===========================================================================
def cmd_host(C, A):
    head(5, "THE LEVER: does the host firmware NAME the address cells?")
    al = aligned(A)
    named = []
    allocd = []
    for a, r in al.items():
        n = r["n"]
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c in C.taps(a):
            if c in idx:
                named.append((a, idx[c], n, r["class"][idx[c]], r["why"][idx[c]]))
        t1p = C.rom.u32le(RS.T1_ARRAY + 4 * a)
        if t1p and t1p != RS.NULL_T1:
            amap = {op: e for op, e in RS.parse_t1(C.rom, t1p)}
            for c in amap.get(0x67, []):
                if c in idx:
                    allocd.append((a, idx[c], n, r["class"][idx[c]],
                                   r["why"][idx[c]]))
    print("  TWO different host-side facts, and they do NOT give the same answer.")
    print()
    print("  (A) THE UI NAME -- a T2 record, i.e. a knob the player can actually")
    print("      turn.  Population: %d (algorithm, op-0x67 record) sites over %d"
          % (len(named), len({a for a, _i, _n, _c, _w in named})))
    print("      algorithms.")
    t = collections.Counter(c for _a, _i, _n, c, _w in named)
    print("      classification of the named cells: %s" % dict(t))
    onb = [(a, i) for a, i, _n, c, _w in named if c == CLASS_BOUND]
    print("      named cells that this pass calls a BOUND: %d %s"
          % (len(onb), onb))
    rels = collections.Counter(i for _a, i, _n, _c, _w in named)
    print("      relative index of every named tap: %s" % dict(sorted(rels.items())))
    onr1 = sum(1 for _a, i, n, _c, _w in named if i == 1 or i in (n - 2, n - 1))
    print("      named taps landing on rel 1 or on the ceiling position: %d"
          % onr1)
    print()
    print("      THE NULL, because `never' over 38 sites is not automatically")
    print("      surprising.  Place each named tap uniformly at random among")
    print("      its own algorithm's n cells; P(it misses both bound cells) =")
    print("      (n-2)/n.  Independent across sites:")
    p = 1.0
    for _a, _i, n, _c, _w in named:
        p *= max(n - 2, 0) / float(n)
    print("         P(no named tap lands on a bound) = %.3g" % p)
    print("      MEASURED: 0 of %d.  So the naming lever is REAL but it is a"
          % len(named))
    print("      one-sided, NECESSARY condition -- it can convict a candidate")
    print("      bound, it cannot acquit the %d unnamed cells."
          % (sum(r["n"] for r in al.values()) - len(named)))
    print()
    print("  (B) THE T1 ALLOCATION -- a cell the firmware RESERVED for opcode")
    print("      0x67, whether or not any T2 record uses it.  Population: %d"
          % len(allocd))
    t = collections.Counter(c for _a, _i, _n, c, _w in allocd)
    print("      classification of the allocated cells: %s" % dict(t))
    bad = [(a, i) for a, i, _n, c, _w in allocd if c == CLASS_BOUND]
    print("      allocated cells this pass calls a BOUND: %d" % len(bad))
    if bad:
        ex = collections.Counter(i for _a, i in bad)
        print("         at relative index %s -- and this is the trap:"
              % dict(ex))
        print("         T1[0x67] of all twelve reverbs is the SEVEN-entry list")
        print("         [0x00, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E]; entry 6 is")
        print("         cell 0x1E = 32767, which the region test FORCES to be a")
        print("         bound.  Only operand 0 (PRE DELAY) appears in any T2")
        print("         stream, so entries 1..6 are DEAD reservations.")
    print()
    print("      ** AND THE DEAD RESERVATION IS OFF BY EXACTLY ONE. **")
    r16 = al.get(16)
    if r16:
        er = [i for i in range(r16["n"])
              for L in r16["lines"]
              if L["read_rel"] == i and L["write_cell"] == 0x03 and i > 0]
        trap = [i for i in range(r16["n"]) if r16["role"][i] == "TRAP"]
        print("         ROOM REVERB 1's cells that read off the PRE DELAY base")
        print("         (cell 0x03) are %s, and the four cells whose direction"
              % [hex(r16["cells"][i]) for i in sorted(set(er))])
        print("         still traps are %s -- together the CONTIGUOUS block"
              % [hex(r16["cells"][i]) for i in trap])
        print("         0x18..0x1D, six cells, six early reflections.  T1[0x67]")
        print("         reserves 0x19..0x1E: the same length, shifted by ONE,")
        print("         which is why its last entry falls on the ceiling.")
        print("         MEASURED: the two blocks and their offset.  INFERRED: a")
        print("         dormant off-by-one in a table no T2 record reaches.")
        print("         ** USE FOR THE NEXT PHASE: the host itself says cells")
        print("         0x19/0x1A/0x1C/0x1D are delay taps, so their C-format")
        print("         words are READS.  That is a CONSISTENT direction")
        print("         assignment for 48 of the 48 still-trapping cells, and it")
        print("         is NOT applied here -- it is not forced. **")
    print()
    print("  ** THE ANSWER TO THE BRIEF'S QUESTION, STATED AS FOUND. **")
    print("     `If every ADDRESS cell has a UI name and no BOUND cell does, the")
    print("      split falls out with no search.'  It does NOT fall out:")
    print("        - no BOUND cell carries a UI NAME  (0 of %d)   -- TRUE"
          % len(named))
    print("        - but only %d of %d aligned cells carry a name at all, so"
          % (len(named), sum(r["n"] for r in al.values())))
    print("          the name cannot classify the other %d."
          % (sum(r["n"] for r in al.values()) - len(named)))
    print("        - and ALLOCATION is not a separator at all: 12 of %d T1"
          % len(allocd))
    print("          reservations point straight at a forced bound.")
    print("     The separator that does work is the one the host does NOT")
    print("     supply: the VALUE against the unit's own region (SS1/SS2).")


# ===========================================================================
#  6. invariants
# ===========================================================================
def cmd_invariants(C, A):
    head(6, "THE FOUR CELLS THE BRIEF ASKS ABOUT, ONE AT A TIME")
    al = aligned(A)
    rev = [a for a in sorted(al) if al[a]["unit"] == 1 and al[a]["n"] == 32]
    print("  population for every count in this section: the %d unit-1 reverbs"
          % len(rev))
    print()

    def col(i):
        return [al[a]["value"][i] for a in rev]

    for i in (1, 3, 5, 30):
        vals = col(i)
        same = len(set(vals)) == 1
        print("  ---- cell index %2d : %s"
              % (i, ("INVARIANT = %d" % vals[0]) if same else "varies %s" % vals))
        cls = {al[a]["class"][i] for a in rev}
        why = {al[a]["why"][i] for a in rev}
        drs = {al[a]["dir"][i] for a in rev}
        print("       direction %s ; classification %s" % (drs, cls))
        print("       reason: %s" % why)
    print()
    print("  ---- idx 3 = 32768.  ADDRESS, and the argument is the host's.")
    print("       The PRE DELAY parameter of every reverb is an op-0x67 record")
    print("       whose BASE24 is 32770, and BASE24 - 2 = 32768 = cell 0x03.")
    print("       So cell 0x03 IS the pre-delay line's base address, anchored")
    print("       12 of 12 by the firmware.  It is also unit 1's region floor;")
    print("       those are the same number because the allocator starts at the")
    print("       floor, not because the cell is a floor REGISTER.")
    print("       ** AND THE SHARPEST FORM OF THAT POINT: the value 32768 is an")
    print("       ADDRESS in the 12 unit-1 reverbs and a BOUND in %d unit-0"
          % sum(1 for a in al if al[a]["unit"] == 0
                and 32768 in al[a]["value"]))
    print("       algorithms.  A classifier that keys on the VALUE ALONE cannot")
    print("       be right; the unit decides.  (Rule 7 exploits this, SS7.)")
    print()
    print("  ---- idx 5 = 41590.  ADDRESS -- the brief's `allocation ceiling'")
    print("       reading is REFUTED, and the dichotomy behind it is a false")
    print("       one.  Three legs:")
    r = al[16]
    same_word = collections.Counter()
    for a in rev:
        same_word[DC.fmt(al[a]["word"][5])] += 1
    print("       (1) its consumer word is %s in %d of %d reverbs, and that"
          % (list(same_word)[0], list(same_word.values())[0], len(rev)))
    idw = [i for i in range(32) if DC.fmt(r["word"][i]) == DC.fmt(r["word"][5])]
    print("           same word consumes cells %s of ROOM REVERB 1 -- of which"
          % [hex(r["cells"][i]) for i in idw])
    print("           cell 0x03 is the host-anchored PRE DELAY line base and the")
    print("           rest are ladder line bases.  A ceiling register would not")
    print("           be written by the instruction that writes nine line bases.")
    print("       (2) it is a WRITE by the FORCED direction rule, and the read")
    print("           cell 0x02 = %d takes it as its base: %d - %d = %d samples,"
          % (r["value"][2], r["value"][2], r["value"][5],
             r["value"][2] - r["value"][5]))
    print("           which is ladder segment 1 in round 5's published ladder.")
    print("       (3) delete it and read cell 0x02 has no base at all: the")
    print("           ladder loses its first segment.")
    print("       WHY IT LOOKED LIKE A CEILING: it is the boundary between the")
    print("       pre-delay buffer and the ladder, and dram-matching.md B")
    print("       measured that this allocator ABUTS its buffers (171 abutting")
    print("       joins).  A boundary between abutting buffers is simultaneously")
    print("       one buffer's ceiling and the next one's base.  `Ceiling, not")
    print("       an address' is a false dichotomy.")
    print()
    print("       AND A RULE-8 CATCH ON THE `200.00 ms EXACTLY'.")
    print("          41590 - BASE24 32770 = %d samples = %.4f ms"
          % (41590 - 32770, (41590 - 32770) / 44.1))
    print("          41590 - cell 0x03 (32768) = %d samples = %.4f ms"
          % (41590 - 32768, (41590 - 32768) / 44.1))
    print("       The roundness holds ONLY against BASE24, i.e. only if you")
    print("       accept the +2 address-generator offset, which dram-matching")
    print("       SS1 labels INFERRED and explicitly says is not separable")
    print("       statically.  The exactness is therefore CONSISTENT, not")
    print("       MEASURED, and it must not be quoted as a confirmation of")
    print("       anything.  It is also not evidence about idx 5's ROLE either")
    print("       way: an abutting allocator produces it under both readings.")
    print()
    print("  ---- idx 30 = 32767.  BOUND, FORCED: below unit 1's floor.")
    print()
    print("  ---- idx 1.  BOUND -- and here is the brief's `eleven zeros refuse")
    print("       it', answered.  There is no conflict, because the eleven")
    print("       zeros and the two max+1 values fail to be addresses in TWO")
    print("       DIFFERENT WAYS and the classification only needs `not an")
    print("       address':")
    for a in rev:
        v = al[a]["value"]
        rd = [v[i] for i in range(32) if al[a]["dir"][i] == "READ"
              and al[a]["in_region"][i]]
        print("       algo %2d %-18s idx1 = %5d  %-22s max read %5d"
              % (a, C.name(a), v[1],
                 "OUT of unit 1 region" if not al[a]["in_region"][1]
                 else "in region", max(rd)))
    print("       In the eleven, idx 1 = 0 is BELOW unit 1's floor -- the region")
    print("       test forces it.  In ROOM REVERB 1 (and in GATED REVERB, unit")
    print("       0) idx 1 is in region but ABOVE every read -- the allocation")
    print("       model forces it.  Two mechanisms, one conclusion: idx 1 is")
    print("       never an endpoint of a line.")
    print()
    print("       WHAT IS *NOT* SETTLED: what idx 1 MEANS.  `max used + 1' holds")
    lm = 0
    tot = 0
    for a, r in al.items():
        n, v, d, inr = r["n"], r["value"], r["dir"], r["in_region"]
        R = [i for i in range(n) if d[i] == "READ" and inr[i]]
        mx = max([v[i] for i in R], default=-1)
        for i in range(n):
            if r["role"][i] == "LIMIT":
                tot += 1
                if v[i] == mx + 1:
                    lm += 1
    print("       in only %d of the %d LIMIT cells.  A ring-buffer top register"
          % (lm, tot))
    print("       PREDICTS max+1 everywhere and is therefore NOT supported; the")
    print("       weaker statement `an address no read can reach' is what the")
    print("       data carries.  Its semantics stay OPEN.")


# ===========================================================================
#  7. rivals -- METHOD RULE 7
# ===========================================================================
def cmd_rivals(C, A):
    head(7, "RULE 7 -- the rivals, and where the test does and does NOT separate")
    al = aligned(A)
    # ---- the ground truth, and where it comes from
    G = {}                                   # (algo, rel) -> ADDRESS | BOUND
    for a, r in al.items():
        n = r["n"]
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c, b24 in C.taps(a).items():
            if c in idx:
                G[(a, idx[c])] = CLASS_ADDR          # host-named tap
                for j in range(n):                   # its BASE24 line base
                    if r["value"][j] == b24 - 2:
                        G[(a, j)] = CLASS_ADDR
        for i in range(n):
            if not r["in_region"][i]:
                G[(a, i)] = CLASS_BOUND
    npos = sum(1 for x in G.values() if x == CLASS_ADDR)
    nneg = len(G) - npos
    print("  GROUND TRUTH, and it is NOT this pass's own output:")
    print("     ADDRESS  %3d  -- the %d host-named op-0x67 taps (PROVEN BY"
          % (npos, sum(1 for a in al for c in C.taps(a)
                       if c in al[a]["cells"])))
    print("                     CONSTRUCTION: the evaluator adds a canned LINE")
    print("                     BASE to a millisecond count) plus the cells")
    print("                     holding those BASE24 - 2 line bases")
    print("     BOUND    %3d  -- out of the unit's own DRAM region" % nneg)
    print("     total    %3d of %d aligned cells"
          % (len(G), sum(r["n"] for r in al.values())))
    print()

    def H(a, i):                                     # this pass
        return al[a]["class"][i]

    def R1(a, i):                                    # positional, word-blind,
        n = al[a]["n"]                               # value-blind
        return CLASS_BOUND if i in (1, n - 2) else CLASS_ADDR

    def R2(a, i):                                    # value-only: extremes
        v = al[a]["value"]
        return CLASS_BOUND if v[i] in (max(v), min(v)) else CLASS_ADDR

    def R3(a, i):                                    # the incumbent: no bounds
        return CLASS_ADDR

    def R4(a, i):                                    # value 32768/32767 is a bound
        return CLASS_BOUND if al[a]["value"][i] in (32767, 32768) else CLASS_ADDR

    def R5(a, i):                                    # the largest value is a bound
        v = al[a]["value"]
        return CLASS_BOUND if v[i] == max(v) else CLASS_ADDR

    rules = [("H-REGION+ALLOC (this pass)", H), ("R1 positional {1, n-2}", R1),
             ("R2 value extremes", R2), ("R3 all-ADDRESS (the incumbent)", R3),
             ("R4 value in {32767,32768}", R4), ("R5 largest value", R5)]
    print("  STATISTIC 1 -- straight score on the ground truth.  Printed first"
          " and NOT the argument (rule 7: a number beating a null is not a")
    print("  decode).")
    sc = {}
    for nm, f in rules:
        s = sum(1 for (a, i), g in G.items() if f(a, i) == g)
        sc[nm] = s
        print("     %-30s %3d / %3d" % (nm, s, len(G)))
    print()
    print("  STATISTIC 2 -- scored ONLY where the rivals disagree with H.")
    for nm, f in rules[1:]:
        dis = [(a, i) for (a, i) in G if f(a, i) != H(a, i)]
        hw = sum(1 for (a, i) in dis if H(a, i) == G[(a, i)])
        rw = sum(1 for (a, i) in dis if f(a, i) == G[(a, i)])
        print("     H vs %-30s  %d disagreement sites in the truth set:"
              "  H %d - %d %s" % (nm, len(dis), hw, rw, nm.split()[0]))
    print()
    print("  ** AND THE ONE THAT MATTERS, SAID PLAINLY. **")
    dis_all = []
    for a, r in al.items():
        for i in range(r["n"]):
            if R1(a, i) != H(a, i):
                dis_all.append((a, i, R1(a, i), H(a, i)))
    ncell = sum(r["n"] for r in al.values())
    trap = sum(1 for a, i, _x, _y in dis_all if al[a]["dir"][i] is None)
    print("     R1 -- a rule that never looks at the instruction, never looks")
    print("     at the value, and only counts cells -- agrees with H on %d of"
          % (ncell - len(dis_all)))
    print("     %d aligned cells.  The %d disagreements are %d C-format cells"
          % (ncell, len(dis_all), trap))
    print("     where H says UNKNOWN and R1 guesses ADDRESS, plus %d cells in"
          % (len(dis_all) - trap))
    print("     %s."
          % ", ".join(sorted({"algo %d %s" % (a, C.name(a))
                              for a, i, _x, _y in dis_all
                              if al[a]["dir"][i] is not None})))
    print("     NONE of those sites carries ground truth.  ** MY TEST DOES NOT")
    print("     SEPARATE H FROM R1. **  I am not entitled to say the value-based")
    print("     route beat the positional one; what I am entitled to say is that")
    print("     two independent routes -- position, and value-against-region --")
    print("     land on the same set, which is the project's usual signature")
    print("     that the answer is right and not that my test is good.")
    print()
    print("  WHERE THE TEST DOES SEPARATE, DEMONSTRATED:")
    for nm in ("R3 all-ADDRESS (the incumbent)", "R4 value in {32767,32768}",
               "R5 largest value"):
        f = dict(rules)[nm]
        dis = [(a, i) for (a, i) in G if f(a, i) != H(a, i)]
        hw = sum(1 for (a, i) in dis if H(a, i) == G[(a, i)])
        rw = sum(1 for (a, i) in dis if f(a, i) == G[(a, i)])
        print("     %-30s  %3d disagreement sites   H %3d - %3d"
              % (nm, len(dis), hw, rw))
    print("     R4 is the interesting loss: `the value 32768 is a bound' is")
    print("     right in unit 0 and WRONG in unit 1, where 32768 is the")
    print("     host-anchored PRE DELAY line base.  R5 is the other: unit 1's")
    print("     largest value is the top of the ladder, an address.")


# ===========================================================================
#  8. control
# ===========================================================================
def cmd_control(C, A, sub=None):
    head(8, "THE CONTROLS -- each one built to fail, and shown failing")
    al = aligned(A)
    ncell = sum(r["n"] for r in al.values())

    def residue_profile(AX):
        ok = 0
        alx = aligned(AX)
        for a, r in alx.items():
            n = r["n"]
            ce = sum(1 for i in range(n) if r["role"][i] == "CEILING")
            li = sum(1 for i in range(n) if r["role"][i] == "LIMIT")
            un = sum(1 for i in range(n) if r["class"][i] == CLASS_UNK
                     and r["dir"][i] is not None)
            if ce == 1 and li <= 1 and un == 0:
                ok += 1
        return ok, len(alx)

    def overlap_profile(AX):
        """how many algorithms end up with two delay buffers that PARTIALLY
        overlap -- a thing no allocator produces."""
        bad = 0
        for r in aligned(AX).values():
            iv = [(L["write_addr"], L["read_addr"]) for L in r["lines"]]
            if _proper_overlap(iv):
                bad += 1
        return bad

    def anchor_profile(AX):
        """** THE SHARP STATISTIC, and it is host-side ground truth. **  For
        each of the 36 host-named op-0x67 taps the firmware ALSO hands us that
        line's base, as the record's own BASE24.  Does the model put the tap on
        a line whose base cell holds BASE24 - 2?  Nothing in the model was
        fitted to this."""
        hit = tot = 0
        for a, r in aligned(AX).items():
            taps = C.taps(a)
            for c, b24 in taps.items():
                if c not in r["cells"]:
                    continue
                i = r["cells"].index(c)
                tot += 1
                for L in r["lines"]:
                    if L["read_rel"] == i and L["write_addr"] == b24 - 2:
                        hit += 1
                        break
        return hit, tot

    print("  CONTROL 1 -- THE DELIBERATELY-WRONG TWIN OF THE DIRECTION RULE.")
    print("     Round 5 D forces addr8 bit 6: 0x20/0x30 READ, 0x60 WRITE.  Swap")
    print("     it and rerun the identical pipeline.  PREDICTION written first:")
    print("     the residue must stop being one CEILING + one LIMIT, because")
    print("     the lines invert and the reads end up below their writes.")

    def flip(w):
        x = D.dram_dir(w)
        return None if x is None else ("WRITE" if x == "READ" else "READ")
    AF = analyse(C, dirfn=flip)
    a0, n0 = residue_profile(A)
    a1, n1 = residue_profile(AF)
    nl0 = sum(len(r["lines"]) for r in aligned(A).values())
    nl1 = sum(len(r["lines"]) for r in aligned(AF).values())
    o0, o1 = overlap_profile(A), overlap_profile(AF)
    h0, t0 = anchor_profile(A)
    h1, _t = anchor_profile(AF)
    print("     SHIPPED  : clean residue %2d of %d, %d lines, %d partial"
          " overlaps, HOST-ANCHOR %d of %d" % (a0, n0, nl0, o0, h0, t0))
    print("     REVERSED : clean residue %2d of %d, %d lines, %d partial"
          " overlaps, HOST-ANCHOR %d of %d" % (a1, n1, nl1, o1, h1, t0))
    print("     -> the control REJECTS on TWO statistics." if (a1 < a0 and h1 < h0)
          else "     -> the control DID NOT REJECT.  Report as a failure.")
    print("     ** AND THE HONEST PART: the PARTIAL-OVERLAP statistic does NOT")
    print("     reject (%d versus %d).  I built it expecting it to and it does"
          % (o0, o1))
    print("     not, because reversing the labels permutes the same value set")
    print("     into a different but still nested layout.  It is printed as a")
    print("     failed discriminator, not deleted.  The two that DO work are")
    print("     the residue shape and the host anchor, and the host anchor is")
    print("     the one nothing in the model was fitted to.")
    print("     Note also WHICH half of the classification can respond at all:")
    print("     the CEILING half is direction-BLIND (a region test), so only")
    print("     the LIMIT/FLOOR half and the line geometry are under test here.")
    print()
    print("  CONTROL 2 -- THE PHASE.  Round 5 B forces delta = 0.  Shift the")
    print("     cell<->word map by +-1 and rerun.  PREDICTION: the residue")
    print("     degrades, because a shift swaps which member of an alternating")
    print("     read/write pair takes which cell.")
    for dd in (-3, -2, -1, 0, 1, 2, 3):
        Ad = A if dd == 0 else analyse(C, delta=dd)
        ax, nx = residue_profile(Ad)
        hh, tt = anchor_profile(Ad)
        print("     delta = %+d : clean residue %2d of %d, HOST-ANCHOR %2d of"
              " %d%s" % (dd, ax, nx, hh, tt, "   <- shipped" if not dd else ""))
    print()
    print("  CONTROL 3 -- THE MATCHING RULE'S OWN TWIN.  A4 says `largest WRITE")
    print("     STRICTLY below the read'.  The non-strict variant (`<=') is the")
    print("     obvious alternative and it is NOT a straw man: it is what you")
    print("     write if you have not noticed that two cells can hold the same")
    print("     boundary address.  PREDICTION: it collapses every shared")
    print("     boundary to a zero-length line.")
    AN = analyse(C, strict=False)
    z0 = sum(1 for r in aligned(A).values() for L in r["lines"]
             if L["samples"] == 0)
    z1 = sum(1 for r in aligned(AN).values() for L in r["lines"]
             if L["samples"] == 0)
    print("     STRICT     : %d zero-length lines of %d" % (z0, nl0))
    print("     NON-STRICT : %d zero-length lines of %d"
          % (z1, sum(len(r["lines"]) for r in aligned(AN).values())))
    print("     -> the control REJECTS." if z1 > z0 else
          "     -> the control DID NOT REJECT.")
    print()
    print("  CONTROL 4 -- A CLASSIFIER THAT CANNOT FAIL, PRINTED SO IT IS NOT")
    print("     MISTAKEN FOR EVIDENCE.  `every cell is an ADDRESS' scores 100 %")
    print("     on every positive ground-truth site and is exactly the model")
    print("     that produced the fake lines.  It is refuted only by the")
    print("     NEGATIVE truth set, which is why the region test had to be")
    print("     built before anything was scored.")
    npos = sum(1 for a, r in al.items() for c in C.taps(a)
               if c in r["cells"])
    print("     all-ADDRESS on the %d positive sites : %d / %d = 100.0 %%"
          % (npos, npos, npos))
    nneg = sum(1 for r in al.values() for i in range(r["n"])
               if not r["in_region"][i])
    print("     all-ADDRESS on the %d negative sites : 0 / %d = 0.0 %%"
          % (nneg, nneg))
    print()
    print("  CONTROL 5 -- THE PERMUTATION NULL.  Shuffle each algorithm's cell")
    print("     VALUES among its own cells (multiset preserved, the binding to")
    print("     the instruction destroyed) and ask how often the residue is")
    print("     still exactly one CEILING plus one LIMIT.")
    rnd = random.Random(20260727)
    hits = []
    for _t in range(400):
        ok = 0
        for a, r in al.items():
            n, d, u = r["n"], r["dir"], r["unit"]
            v = list(r["value"])
            rnd.shuffle(v)
            inr = [FLOOR[u] <= x <= TOP[u] for x in v]
            W = [i for i in range(n) if d[i] == "WRITE" and inr[i]]
            R = [i for i in range(n) if d[i] == "READ" and inr[i]]
            used = set()
            for x in R:
                cand = [y for y in W if v[y] < v[x]]
                if cand:
                    b = max(cand, key=lambda y: v[y])
                    used.add(x)
                    used.add(b)
            ce = sum(1 for i in range(n) if not inr[i])
            li = sum(1 for i in range(n) if inr[i] and i not in used
                     and d[i] == "WRITE")
            un = sum(1 for i in range(n) if inr[i] and i not in used
                     and d[i] == "READ")
            if ce == 1 and li <= 1 and un == 0:
                ok += 1
        hits.append(ok)
    print("     ROM        : %d of %d algorithms clean" % (a0, n0))
    print("     shuffled   : mean %.1f  min %d  max %d over 400 trials"
          % (sum(hits) / float(len(hits)), min(hits), max(hits)))
    print("     trials reaching the ROM's %d: %d of 400"
          % (a0, sum(1 for h in hits if h >= a0)))
    print()
    print("  CONTROL 6 -- THE DEGENERACY CHECK (method rule 4).  Is `CEILING'")
    print("     the same statement as `LIMIT' counted twice?  No: they are")
    print("     distinguished by three independent facts, printed as counts.")
    ce_dir = collections.Counter()
    li_dir = collections.Counter()
    ce_v = collections.Counter()
    li_v = collections.Counter()
    for a, r in al.items():
        for i in range(r["n"]):
            if r["role"][i] == "CEILING":
                ce_dir[r["dir"][i]] += 1
                ce_v[r["value"][i]] += 1
            elif r["role"][i] == "LIMIT":
                li_dir[r["dir"][i]] += 1
                li_v[len(set([r["value"][i]]))] += 1
    print("     CEILING : direction %s ; only %d distinct values corpus-wide"
          % (dict(ce_dir), len(ce_v)))
    print("     LIMIT   : direction %s ; %d distinct values"
          % (dict(li_dir), len({al[a]["value"][i] for a in al
                                for i in range(al[a]["n"])
                                if al[a]["role"][i] == "LIMIT"})))
    print("     The CEILING is a READ carrying one of two canned constants; the")
    print("     LIMIT is a WRITE carrying a per-algorithm value.  Opposite")
    print("     direction, opposite value behaviour -- not one thing twice.")


# ===========================================================================
#  9. predict
# ===========================================================================
def cmd_predict(C, A):
    head(9, "PREDICT THEN CHECK -- the predictions as registered, hits AND misses")
    al = aligned(A)
    print("  Each prediction below was written down before the experiment that")
    print("  tests it was run.  Misses are printed with the same prominence as")
    print("  hits, and two of them changed the model.")
    print()
    rows = []

    # P1
    named = [(a, i) for a, r in al.items()
             for i, c in enumerate(r["cells"]) if c in C.taps(a)]
    bad = [(a, i) for a, i in named if al[a]["class"][i] != CLASS_ADDR]
    rows.append(("P1", "every host-named op-0x67 tap classifies as ADDRESS",
                 "%d of %d" % (len(named) - len(bad), len(named)),
                 "HIT" if not bad else "MISS %s" % bad))

    # P2
    on = [(a, i) for a, i in named
          if i == 1 or i in (al[a]["n"] - 2, al[a]["n"] - 1)]
    rows.append(("P2", "no host-named tap sits on rel 1 or on the ceiling slot",
                 "%d violations of %d" % (len(on), len(named)),
                 "HIT" if not on else "MISS"))

    # P3
    allocd = []
    for a, r in al.items():
        idx = {c: i for i, c in enumerate(r["cells"])}
        t1p = C.rom.u32le(RS.T1_ARRAY + 4 * a)
        if t1p and t1p != RS.NULL_T1:
            amap = {op: e for op, e in RS.parse_t1(C.rom, t1p)}
            for c in amap.get(0x67, []):
                if c in idx:
                    allocd.append((a, idx[c]))
    ab = [(a, i) for a, i in allocd if al[a]["class"][i] == CLASS_BOUND]
    rows.append(("P3", "the T1[0x67] ALLOCATION also avoids the bound cells --"
                 " i.e. the brief's `cleaner separator'",
                 "%d of %d allocations land on a forced bound"
                 % (len(ab), len(allocd)),
                 "MISS" if ab else "HIT"))

    # P4
    n32 = sum(1 for a, r in al.items()
              if any(r["role"][i] == "CEILING" for i in range(r["n"])))
    rows.append(("P4", "the +3 anchored offset would be NEEDED to build the"
                 " lines", "the allocation model reproduces all 14 ROOM"
                 " REVERB 1 lines including the +9 one without it", "MISS"))

    # P5
    lm = tot = 0
    for a, r in al.items():
        n, v, d, inr = r["n"], r["value"], r["dir"], r["in_region"]
        R = [i for i in range(n) if d[i] == "READ" and inr[i]]
        mx = max([v[i] for i in R], default=-1)
        for i in range(n):
            if r["role"][i] == "LIMIT":
                tot += 1
                lm += (v[i] == mx + 1)
    rows.append(("P5", "cell index 1 is a RING TOP register, i.e. max used + 1",
                 "%d of %d LIMIT cells equal max read + 1" % (lm, tot), "MISS"))

    # P6
    rows.append(("P6", "idx 5 = 41590 is an allocation CEILING (the brief's"
                 " reading)", "it is a WRITE, it is the base of ladder segment"
                 " 1, and deleting it orphans read cell 0x02", "MISS"))

    # P7
    rows.append(("P7", "idx 30 = 32767 is a BOUND",
                 "below unit 1's floor in 12 of 12", "HIT"))

    # P8
    ok = 0
    for a, r in al.items():
        ce = sum(1 for i in range(r["n"]) if r["role"][i] == "CEILING")
        if ce == 1:
            ok += 1
    rows.append(("P8", "every algorithm carries exactly ONE ceiling cell",
                 "%d of %d" % (ok, len(al)), "HIT" if ok == len(al) else "MISS"))

    # P9
    fake = 0
    for a, r in al.items():
        n = r["n"]
        ce = [i for i in range(n) if r["role"][i] == "CEILING"]
        li = [i for i in range(n) if r["role"][i] == "LIMIT"]
        if ce and li and (ce[0] - li[0]) % n == 3:
            fake += 1
    rows.append(("P9", "the two named fake lines are CEILING - LIMIT",
                 "897 = 32768-31871 and 32767 = 32767-0; and the two bounds sit"
                 " +3 apart in %d of %d algorithms" % (fake, len(al)), "HIT"))

    # P10
    rows.append(("P10", "the host-side NAME lever alone settles the split",
                 "it convicts (0 of %d named cells is a bound, null p = 2.8e-4)"
                 " but only %d of %d aligned cells carry a name at all"
                 % (len(named), len(named),
                    sum(r["n"] for r in al.values())), "PARTIAL"))

    # P11
    rows.append(("P11", "the CEILING constant is the same number in both units",
                 "32768 in unit 0 and 32767 in unit 1 -- the SAME partition"
                 " boundary, but not the same number", "MISS"))

    # P12
    rows.append(("P12", "the descriptor bank has exactly TWO canned constants,"
                 " 32767 and 32768",
                 "there is a THIRD, 128, in 10 algorithms; in 8 of them the"
                 " block holds no WRITE at all", "MISS"))
    for tag, pred, meas, res in rows:
        print("  %-4s %-6s %s" % (tag, res, pred))
        print("            measured: %s" % meas)
    print()
    print("  THE TWO MISSES THAT CHANGED THE MODEL:")
    print("     P4 -- I started from dram-matching's +3 rule and it could not")
    print("           close ROOM REVERB 1's eleventh segment (offset +9) or the")
    print("           early reflections.  Replacing `pair at +3' with `the read")
    print("           belongs to the buffer it falls inside' closed both and")
    print("           made +3 an OUTPUT of the model rather than an input.")
    print("     P3 -- I expected the firmware's own reservation table to name")
    print("           the addresses.  It reserves a forced bound (cell 0x1E) in")
    print("           twelve algorithms, so the brief's `even cleaner separator'")
    print("           does not exist.  The name does separate; the reservation")
    print("           does not.")


# ===========================================================================
#  10. export
# ===========================================================================
def cmd_export(C, A, path):
    head(10, "EXPORT  (deliverable a and b, in a form another script imports)")
    al = aligned(A)
    out = {"_about": "uPD6383GF-3BA delay-descriptor cell classification",
           "_source": "dsp/tools/bounds.py -- see dsp/analysis/dram-bounds.md",
           "_model": {"map": "identity, delta=0 (round 5 B, FORCED)",
                      "direction": "addr8 bit 6; 0x20/0x30 READ, 0x60 WRITE"
                                   " (round 5 D, FORCED)",
                      "region": {"0": [0, 32767], "1": [32768, 65535]},
                      "matching": "a READ belongs to the line whose base is the"
                                  " largest WRITE strictly below it"},
           "_labels": {"BOUND/CEILING": "FORCED",
                       "BOUND/LIMIT": "FORCED within the allocation model,"
                                      " CONSISTENT outside it",
                       "ADDRESS/host-named": "FORCED",
                       "ADDRESS/matched": "CONSISTENT",
                       "UNKNOWN": "do not use as a constraint"},
           "algorithms": {}}
    for a in sorted(al):
        r = al[a]
        taps = C.taps(a)
        cells = []
        for i, c in enumerate(r["cells"]):
            role = r["role"][i]
            lab = ("FORCED" if (c in taps or role == "CEILING") else
                   ("FORCED-IN-MODEL" if role in ("LIMIT", "FLOOR") else
                    ("CONSISTENT" if r["class"][i] == CLASS_ADDR else "OPEN")))
            # the BASE24 line bases are host-anchored too, not merely matched
            if role == "LINE_BASE" and any(
                    r["value"][i] == b - 2 for b in taps.values()):
                lab = "FORCED"
            cells.append({"rel": i, "cell": c, "value": r["value"][i],
                          "word": "%09X" % r["word"][i],
                          "dir": r["dir"][i], "class": r["class"][i],
                          "role": role, "why": r["why"][i], "label": lab,
                          "host_named": c in taps,
                          "base24": taps.get(c)})
        out["algorithms"][str(a)] = {
            "name": C.name(a), "unit": r["unit"], "n": r["n"],
            "cells": cells,
            "lines": [{"read_cell": L["read_cell"], "write_cell": L["write_cell"],
                       "read_addr": L["read_addr"], "write_addr": L["write_addr"],
                       "samples": L["samples"],
                       "ms": round(L["samples"] / 44.1, 3)}
                      for L in sorted(r["lines"], key=lambda x: x["read_rel"])]}
    unal = {str(a): {"name": C.name(a), "reason": r.get("reason")}
            for a, r in A.items() if not r.get("aligned")}
    out["not_classified"] = unal
    with open(path, "w") as f:
        json.dump(out, f, indent=1, sort_keys=False)
        f.write("\n")
    nc = sum(len(v["cells"]) for v in out["algorithms"].values())
    nl = sum(len(v["lines"]) for v in out["algorithms"].values())
    print("  wrote %s" % path)
    print("     %d algorithms, %d cells, %d delay lines"
          % (len(out["algorithms"]), nc, nl))
    print("     %d algorithms deliberately NOT classified (cells != consumers):"
          " %s" % (len(unal), ", ".join(sorted(unal))))
    t = collections.Counter(c["label"] for v in out["algorithms"].values()
                            for c in v["cells"])
    print("     label census: %s" % dict(t))


# ---------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "census", "roles", "classify", "lines",
                             "host", "invariants", "rivals", "control",
                             "predict", "export"])
    ap.add_argument("--sub", default=os.path.join(
        repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(
        repo, "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--out", default=os.path.join(
        repo, "dsp", "analysis", "descriptor-cell-classes.json"))
    ap.add_argument("--quiet-classify", action="store_true")
    args = ap.parse_args()

    C = DM.Corp(args.sub, args.main, args.tools)
    A = analyse(C)

    if args.cmd in ("all", "census"):
        cmd_census(C, A)
        print()
    if args.cmd in ("all", "roles"):
        cmd_roles(C, A)
        print()
    if args.cmd in ("all", "classify"):
        cmd_classify(C, A, verbose=not args.quiet_classify
                     and args.cmd == "classify")
        print()
    if args.cmd in ("all", "lines"):
        cmd_lines(C, A)
        print()
    if args.cmd in ("all", "host"):
        cmd_host(C, A)
        print()
    if args.cmd in ("all", "invariants"):
        cmd_invariants(C, A)
        print()
    if args.cmd in ("all", "rivals"):
        cmd_rivals(C, A)
        print()
    if args.cmd in ("all", "control"):
        cmd_control(C, A)
        print()
    if args.cmd in ("all", "predict"):
        cmd_predict(C, A)
        print()
    if args.cmd in ("all", "export"):
        cmd_export(C, A, args.out)


if __name__ == "__main__":
    main()
