#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""ptrd_perform.py -- TIER 5: the MAXIMAL field-based delta rule.

Companion to `ptrd_search.py`.  Where that tool enumerates (class-subset x gate)
rules, this one enumerates the strictly larger space of rules that assign a
carries-a-delta / does-not bit **independently to every distinct instruction
FORM**, a form being the triple

        (hi12, class4, lo12)

i.e. the whole 36-bit word except `addr8` itself.

★ Why this bounds everything: every gate in `ptrd_search.py` is a predicate on
  `cfmt / b4 / b7 / b10 / b11 / f98 / f31 / ACT / SRC / lo12`, and every one of
  those is a function of `hi12` and `lo12`.  So EVERY rule in Tiers 1-4 is a
  particular form-indicator vector.  If the form space has no solution, neither
  does any of them, and neither does any other rule that decides from the word's
  fields without reading `addr8` itself.

Method: depth-first over the forms in program order (a form is assigned the
first time the walk meets it), pruning at every READ/WRITE word.  The pruner is
brutal because the 20 chain reads of a05 must collapse onto at most as many
distinct cells as there are modulator writes (2).

Usage:  python3 dsp/tools/ptrd_perform.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pat_corpus as PC                                       # noqa: E402
import ptrd_search as PS                                      # noqa: E402

F = PC.F
s8 = PS.s8

IMAGES = [("C1", "a05 PHASER"), ("C2", "a68 S.DELAY+PHASER"),
          ("C3", "a03 ENHANCER")]


def form(w):
    f = F(w)
    return (f.hi12, f.class4, f.lo12)


def solve_image(ws, node_cap=3_000_000, sol_cap=200000):
    """All form-indicator vectors making {read cells} == {write cells}.

    -> (solutions, forms, nodes, capped)   solutions = list of frozensets of
    the forms that CARRY a delta (restricted to forms with a nonzero addr8;
    zero-addr8 forms cannot matter and are reported separately).
    """
    rd = set(PS.reads(ws))
    wr = set(PS.writes(ws))
    nwrite = len(wr)
    seq = []
    for i, w in enumerate(ws):
        f = F(w)
        seq.append((form(w), s8(f.addr8), i in rd, i in wr))
    forms = []
    seen = {}
    for k, d, _, _ in seq:
        if d and k not in seen:
            seen[k] = len(forms)
            forms.append(k)
    nf = len(forms)
    sols = []
    nodes = [0]
    nsol = [0]
    capped = [False]

    def step(pos, ptr, assign, rset, wset, take):
        """Advance past word `pos`, whose indicator is now known."""
        _, d, isr, isw = seq[pos]
        nr = rset | {ptr} if isr else rset
        nw = wset | {ptr} if isw else wset
        # final sets must be EQUAL and |wset| <= number of write WORDS,
        # so the union can never exceed that count.
        if len(nr | nw) > nwrite:
            return
        rec(pos + 1, ptr + (d if take else 0), assign, nr, nw)

    def rec(pos, ptr, assign, rset, wset):
        nodes[0] += 1
        if nodes[0] > node_cap:
            capped[0] = True
            return
        if pos == len(seq):
            if rset == wset and rset:
                nsol[0] += 1
                if len(sols) < sol_cap:
                    sols.append(frozenset(k for k, v in assign.items() if v))
            return
        k, d, _, _ = seq[pos]
        if d and k not in assign:
            for v in (True, False):
                assign[k] = v
                step(pos, ptr, assign, rset, wset, v)
                if capped[0]:
                    del assign[k]
                    return
            del assign[k]
            return
        step(pos, ptr, assign, rset, wset, bool(assign.get(k, False)) and bool(d))

    rec(0, 0, {}, frozenset(), frozenset())
    return sols, forms, nodes[0], capped[0], nsol[0]


def main():
    progs, meta = PC.load()
    sc = PS.Scorer(progs)

    print("=" * 78)
    print("TIER 5 -- the MAXIMAL field-based space: one free bit per FORM")
    print("=" * 78)
    allforms = set()
    for _, nm in IMAGES:
        for w in progs[nm]:
            if s8(F(w).addr8):
                allforms.add(form(w))
    for nm in ("a01 CHORUS", "a39 PARAMETRIC EQ", "a16 ROOM REVERB 1"):
        for w in progs[nm]:
            if s8(F(w).addr8):
                allforms.add(form(w))
    print("""
  A form is (hi12, class4, lo12) -- the whole word except addr8.  Every gate in
  ptrd_search.py is a predicate on cfmt/b4/b7/b10/b11/f98/f31/ACT/SRC/lo12, and
  every one of those is a function of hi12 and lo12.  So TIERS 1-4 ARE ALL
  SUBSPACES OF THIS ONE.

  distinct forms with a nonzero addr8 over the six probe images : %d
  size of the tier-5 space                                      : 2^%d = %d
""" % (len(allforms), len(allforms), 1 << len(allforms)))

    per = {}
    for tag, nm in IMAGES:
        ws = progs[nm]
        sols, forms, nodes, capped, nsol = solve_image(ws)
        per[tag] = (nm, sols, forms)
        print("  %s  %-20s  %2d free forms (2^%d = %d rules), %d DFS nodes%s"
              % (tag, nm, len(forms), len(forms), 1 << len(forms), nodes,
                 "  *** NODE CAP HIT, result is a lower bound ***" if capped else ""))
        print("      form-rules making {read cells} == {write cells} : %d" % nsol)
        sys.stdout.flush()
        if sols:
            # which forms are forced on / forced off across all solutions
            on = set(sols[0])
            off = set(forms) - set(sols[0])
            for s in sols[1:]:
                on &= set(s)
                off &= (set(forms) - set(s))
            print("      forms ON in EVERY solution  : %s"
                  % ", ".join("%03X.%X.%03X" % f for f in sorted(on)) or "(none)")
            print("      forms OFF in EVERY solution : %s"
                  % ", ".join("%03X.%X.%03X" % f for f in sorted(off)) or "(none)")

    print()
    print("=" * 78)
    print("THE JOINT TEST -- one rule for all three images at once")
    print("=" * 78)
    # a form shared between images must get the same bit
    shared = {}
    for tag, (nm, sols, forms) in per.items():
        for f in forms:
            shared.setdefault(f, set()).add(tag)
    common = {f for f, t in shared.items() if len(t) > 1}
    print("\n  forms appearing in more than one of the three images : %d" % len(common))
    joint = []
    if all(per[t][1] for t in per):
        for s1 in per["C1"][1]:
            f1 = set(per["C1"][2])
            for s2 in per["C2"][1]:
                f2 = set(per["C2"][2])
                if any((f in s1) != (f in s2) for f in (f1 & f2)):
                    continue
                for s3 in per["C3"][1]:
                    f3 = set(per["C3"][2])
                    if any((f in s1) != (f in s3) for f in (f1 & f3)):
                        continue
                    if any((f in s2) != (f in s3) for f in (f2 & f3)):
                        continue
                    joint.append(set(s1) | set(s2) | set(s3))
        print("  rules satisfying C1 AND C2 AND C3 simultaneously : %d" % len(joint))
    else:
        empty = [t for t in per if not per[t][1]]
        print("  ** %s has NO solution at all in the maximal field-based space, so"
              % ", ".join(empty))
        print("     C1 AND C2 AND C3 is unreachable by construction. **")

    # now score the joint solutions against C4 / P1 / P2 / P3 / N
    if joint:
        print("\n  scoring the joint C1&C2&C3 rules against C4, P1, P2, P3 and N:")
        best = []
        for js in joint:
            def gfn(f, js=js):
                return (f.hi12, f.class4, f.lo12) in js
            cols = sc.columns(gfn, signed=True)
            P = PS.combine(cols, sorted(cols)) or [0] * sc.ncol
            res, extra = sc.evaluate(P)
            sk = sum(1 for c in PS.CRIT if res[c])
            best.append((sk, extra[3], js, dict(res), extra))
        best.sort(key=lambda r: (-r[0], not r[1]))
        for sk, nd, js, res, extra in best[:20]:
            print("    score %d/7  %s  %s  cells %s   forms ON: %s"
                  % (sk, "N-OK " if nd else "DEGEN",
                     " ".join("%s=%s" % (c, "Y" if res[c] else "n")
                              for c in PS.CRIT), extra[4],
                     ",".join("%03X.%X.%03X" % f for f in sorted(js))))
        nn = sum(1 for b in best if b[1] and b[0] == 7)
        print("\n  joint rules scoring 7/7 AND non-degenerate : %d" % nn)
    return 0


if __name__ == "__main__":
    sys.exit(main())
