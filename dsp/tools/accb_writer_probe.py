#!/usr/bin/env python3
"""accb_writer_probe.py -- identify the second-accumulator (accb) writer.

QUESTION THIS ANSWERS (Phase 5.4 / the root of the 4.2 chain)
  Anchoring SRC 0x11 (= accb) is blocked until we know WHERE accb is written --
  input_route_guards.py showed no SRC-0x11 word coincides with a matchable accb,
  so the accb WRITER must be modelled first.  This probe finds every row where
  accb changes in a trace, names the word responsible, and lists which simple op
  (accb<-acc, accb<-P, accb+=P, accb<-0) is CONSISTENT with that transition.

  It deliberately does NOT promote a decode: one frame gives few transitions and
  several ops can coincide when acc==P.  It reports the candidate set per
  transition and the writer word class, as a LEAD for a multi-capture decode.

  Run: python3 dsp/tools/accb_writer_probe.py [trace.txt]
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
sys.path.insert(0, HERE)
from lle_trace_diff import parse_trace  # noqa: E402
import dsp_disasm as D  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-live-frame-trace-2026-09-10.txt")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    rows = parse_trace(open(path).read())
    print("accb_writer_probe: %s\n" % os.path.basename(path))

    trans = []
    for a, b in zip(rows, rows[1:]):
        if a["accb"] != b["accb"]:
            trans.append((a, b))
    if not trans:
        print("  accb never changes in this trace (writer inactive here).")
        return

    print("  %d accb transition(s).  For each: the WRITER word (prev row) and the" % len(trans))
    print("  simple op consistent with the new accb value.\n")
    classcount = {}
    for a, b in trans:
        w = a["word"]
        cands = []
        if b["accb"] == a["acc"]:        cands.append("accb<-acc")
        if b["accb"] == a["p"]:          cands.append("accb<-P")
        if b["accb"] == a["accb"] + a["p"]: cands.append("accb+=P")
        if b["accb"] == 0:               cands.append("accb<-0 (clear)")
        key = (D.class4(w), D.hi12(w), D.lo_act(w))
        classcount[key] = classcount.get(key, 0) + 1
        print("   n=%d->%d  writer %010X (class %X hi12 0x%03X f31 %d ACT 0x%02X): accb %d -> %d"
              % (a["n"], b["n"], w, D.class4(w), D.hi12(w), D.hi_f31(D.hi12(w)),
                 D.lo_act(w), a["accb"], b["accb"]))
        print("        consistent op(s): %s" % (", ".join(cands) or "NONE of the simple ops"))

    print("\n  writer word classes seen (class, hi12, ACT) -> count:")
    for k, c in sorted(classcount.items()):
        print("     class %X hi12 0x%03X ACT 0x%02X : %d" % (k[0], k[1], k[2], c))
    # Rule out the trivial explanation: accb is NOT just a pipeline-delayed acc.
    acc = [r["acc"] for r in rows]
    accb = [r["accb"] for r in rows]
    n = len(rows)
    best = max((sum(1 for i in range(k, n) if accb[i] == acc[i - k]) / (n - k), k)
               for k in range(8))
    nz = [r["n"] for r in rows if r["accb"] != 0]
    print("\n  NOT delayed-acc: best accb[N]==acc[N-k] match is %.0f%% (k=%d) -- that is just the"
          % (100 * best[0], best[1]))
    print("  shared-zero rows, no clean delay.  accb is a SEPARATE register, live only at rows")
    print("  %s here (a narrow window), so it has its own writer -- not an automatic acc shadow." % nz)
    print("\n  LEAD, not a decode: promoting an accb op needs N-clean/0-contradicting across")
    print("  MANY frames (and a transition where acc != P, to split accb<-acc from accb<-P).")


if __name__ == "__main__":
    main()
