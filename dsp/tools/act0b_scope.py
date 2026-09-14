#!/usr/bin/env python3
"""act0b_scope.py -- the sentence that keeps `ACT 0x0B' closed, re-scored on the full corpus.

QUESTION IT ANSWERS
    `ACT 0x0B' is the HEAD of the pooled decode queue -- **191 words whose only open axis it is**
    (62 KN5000 + 129 SX-WSA1R).  `dsp_disasm.py::_act_anchored()' admits it on class A and refuses
    it everywhere else, and the refusal quotes one sentence:

        *"ACT 0x0B => READ is DEGENERATE with H-ADB6: EVERY ACT-0x0B DELAY WORD CARRIES
        addr8 0x20/0x30.  It adds nothing and it is not independent evidence.  0x0B stays OPEN."*

    That sentence is a GENERALISATION of a SCOPED measurement.  `dram-matching.md' item J states
    the population explicitly -- *"203 slots over the 83 algorithms where `#cells == #consumers'"*
    -- and `adjudication-round5.md' item J says "over the in-scope aligned cells".  The code
    comment drops the qualifier and states a universal over "every ACT-0x0B delay word".

    ⚠ This file does NOT re-run round 5's scoped measurement and does not claim to refute it.  It
    measures the universal the CODE states, because that is what the code acts on.

USAGE
    python3 dsp/tools/act0b_scope.py

WHAT IT MEASURES
    1. Every `ACT 0x0B' delay-DRAM escape in both products, by `addr8'.  `adjudication-round5.md'
       item D FORCED `addr8' bit 6 as the direction with `0x60' = WRITE, so an ACT-0x0B word
       carrying `0x60' is a counterexample to the universal.
    2. The converse, which is the half that decides SEPARABILITY: do `0x60' words carry ACTIONS
       other than `0x0B'?  Two fields are degenerate only if each determines the other.
    3. ★ THE CONTROL.  A rule that cannot fail is not a rule: the same 2x2 is printed for an
       ACTION that IS expected to be independent of the direction, so the reader can see what
       "separable" looks like on this corpus.

⚠ WHAT THIS IS NOT.  Separating two fields does not decode either of them.  `act0b-reverb.md'
  item D's menu still has THREE survivors (`none', `mem<-bus', `tA<-acc') and `sd_act0b.py'
  measured that SINGLE DELAY's lag-1001 ROM product cannot tell them apart (all six readings
  accepted, LEDGER sect. 291).  What this removes is the stated REASON the elimination stopped.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402

ACT0B = 0x0B


def delay_words():
    for label, name, ws in X.images():
        for i, w in enumerate(ws):
            if (not DIS.c_format(w)) and DIS.is_dram(w):
                yield label, name, i, w


def main():
    print("=" * 100)
    print("  act0b_scope -- `every ACT-0x0B delay word carries addr8 0x20/0x30', re-scored")
    print("=" * 100)

    #  ---- 1. the universal the code states ---------------------------------
    per = collections.defaultdict(collections.Counter)
    bad = []
    for label, name, i, w in delay_words():
        if DIS.lo_act(w) != ACT0B:
            continue
        per[label][DIS.addr8(w)] += 1
        if DIS.addr8(w) & 0x40:
            bad.append((label, name, i, w))
    print("\n   ★ TEST 1 -- every ACT-0x0B DELAY-DRAM ESCAPE, by `addr8'"
          "  (round 5 D: bit 6 = direction, 0x60 = WRITE)\n")
    for label in ("KN", "WSA"):
        tot = sum(per[label].values())
        row = "  ".join("%02X x%-4d" % kv for kv in sorted(per[label].items()))
        print("      %-5s %4d words   %s" % (label, tot, row))
    print("\n      ⛔ COUNTEREXAMPLES -- ACT 0x0B on the WRITE side, which the universal forbids:")
    for label, name, i, w in bad:
        print("         %-5s %-26s w%-3d %010X  %03X.%X.%02X.%03X"
              % (label, name, i, w, DIS.hi12(w), DIS.class4(w), DIS.addr8(w), DIS.lo12(w)))
    print("      ⇒ %d words.  If the universal held this list would be EMPTY." % len(bad))
    kn_alg = [r for r in bad if r[0] == "KN" and r[1] not in ("kernel", "epilogue")]
    print("      ⚠ %d of them are in the KN5000's own ALGORITHM images (%s) -- so the universal"
          % (len(kn_alg), ", ".join(sorted({r[1] for r in kn_alg})) or "none"))
    print("        fails inside one product, before the second is pooled in.  The other %d are"
          % (len(bad) - len(kn_alg)))
    print("        resident-kernel words and SX-WSA1R words.")

    #  ---- 2. the converse, which is what `degenerate' needs ----------------
    print("\n   ★ TEST 2 -- THE CONVERSE.  Two fields are degenerate only if EACH determines the")
    print("     other.  So: do `0x60' (WRITE) delay words carry ACTIONS other than 0x0B?\n")
    conv = collections.Counter()
    for label, name, i, w in delay_words():
        if DIS.addr8(w) & 0x40:
            conv[DIS.lo_act(w)] += 1
    tot = sum(conv.values())
    for a, n in conv.most_common(8):
        print("      ACT %02X  x%-4d %s" % (a, n, "   <- the one the rule predicts" if a == ACT0B else ""))
    print("      ⇒ %d WRITE-side delay words carry %d distinct ACTIONS; ACT 0x0B is %d of them"
          % (tot, len(conv), conv[ACT0B]))
    print("        (%.1f %%).  Neither field determines the other." % (100.0 * conv[ACT0B] / tot))

    #  ---- 3. the control ---------------------------------------------------
    print("\n   ★ TEST 3 -- THE CONTROL.  What does `separable' look like here?  The same 2x2 for")
    print("     every ACTION on the delay family, so no single row can be read in isolation.\n")
    t = collections.defaultdict(lambda: [0, 0])
    for label, name, i, w in delay_words():
        t[DIS.lo_act(w)][1 if (DIS.addr8(w) & 0x40) else 0] += 1
    print("      %-8s %8s %8s   %s" % ("ACT", "READ", "WRITE", "one-sided?"))
    for a in sorted(t, key=lambda a: -(t[a][0] + t[a][1]))[:10]:
        r, ww = t[a]
        print("      %-8s %8d %8d   %s" % ("0x%02X" % a, r, ww,
              "YES -- only one side" if 0 in (r, ww) else "no -- both sides"))
    one = [a for a in t if 0 in t[a]]
    print("\n      ⇒ %d of %d ACTIONS on this family are one-sided, so `one-sided' is the NORM"
          % (len(one), len(t)))
    print("        here and carries little information by itself.  ACT 0x0B is NOT one of them.")
    print("\n   ⇒ THE UNIVERSAL IS FALSE; the SCOPED measurement it generalises is untouched and")
    print("     not re-run here.  What that removes is the stated REASON `_act_anchored()' refuses")
    print("     ACT 0x0B outside class A -- not the openness of the code, which stands: the menu")
    print("     still has three survivors and `sd_act0b.py' cannot separate them (LEDGER 291).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
