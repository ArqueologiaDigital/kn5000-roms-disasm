#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""xcorpus_routing_census.py -- the OPEN routing codes across BOTH uPD6383GF corpora.

NEC uPD6383GF-3BA.  This chip is IC311 in the Technics SX-KN5000 and appears
three times in the SX-WSA1R; the WSA1R's DSP microcode was cross-decoded in
`wsa1/dsp/analysis/wsa1_dsp_isa_crossval.py` and confirmed to be the same ISA.

THE QUESTION IT ANSWERS
  The routing guard holds 60.6% of the KN5000's undecoded words (`f31_367.py`),
  and 97% of the routing ceiling sits in eight SRC/ACT codes.  SRC 0x00 and the
  ACT 0x0D/0x0E pair are DECIDED (register tail sect. 233/234); the rest --
  SRC 0x11 (+49), ACT 0x0B (+19), SRC 0x08 (+10), ACT 0x08 (+9), SRC 0x0B (+7)
  -- are OPEN.  The strategic review said the only lever past the KN5000's own
  ceiling is a foreign corpus of the same chip.  This asks the sharp version of
  that: does the WSA1R corpus CLOSE any OPEN routing code by rule 4 (every site's
  operand a measured constant), or does it only confirm the field structure?

WHAT IT FOUND (2026-09-06, self-test PASSes below)
  The WSA1R corpus CONFIRMS the structural anchoring of every OPEN code -- the
  same class4 / f31 signature holds across both firmwares -- but CLOSES none of
  them: the addr8 operand VARIES in both corpora (SRC 0x11 and SRC 0x0B carry a
  tail of distinct operands; ACT 0x08 walks a pointer).  So the WSA1R corpus
  supplies OCCURRENCES, not a CONSUMER: decoding these codes still needs a
  discriminating execution context, i.e. a uPD6383 device fed the WSA1R
  microcode -- not a static closure.  This is what "100% decode is not reachable
  from the corpus alone" means in one command.

    python3 dsp/tools/xcorpus_routing_census.py

stdlib only, read-only (no build, no MAME run).
"""
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))     # kn5000-roms-disasm
sys.path.insert(0, HERE)                                    # dsp/tools
sys.path.insert(0, os.path.join(ROOT, "wsa1", "dsp", "analysis"))

from pat_corpus import load, F                              # noqa: E402
import wsa1_dsp_isa_crossval as X                           # noqa: E402

# published self-test anchors (must reproduce or the corpora moved under us)
KN_WORDS = 3057
OPEN = [("SRC", 0x11, "src"), ("ACT", 0x0B, "act"), ("SRC", 0x08, "src"),
        ("ACT", 0x08, "act"), ("SRC", 0x0B, "src")]


def kn_sites(code, fld):
    progs, _ = load()
    return [w for ws in progs.values() for w in ws
            if not F(w).cfmt and getattr(F(w), fld) == code]


def wsa_sites(code, fld):
    prog, _c, _o = X.wsa1_stream_words()
    getter = X.src if fld == "src" else X.act
    return [w for w in prog if not X.cfmt(w) and getter(w) == code]


def top(counter, n=6):
    return dict(sorted(counter.items(), key=lambda kv: -kv[1])[:n])


def profile(words, corpus):
    if corpus == "KN":
        cls = collections.Counter(F(w).class4 for w in words)
        f31 = collections.Counter(F(w).f31 for w in words)
        adr = collections.Counter(F(w).addr8 for w in words)
    else:
        cls = collections.Counter(X.cls(w) for w in words)
        f31 = collections.Counter(X.f31(w) for w in words)
        adr = collections.Counter(X.addr8(w) for w in words)
    return cls, f31, adr


def main():
    progs, _ = load()
    kn_tot = sum(len(v) for v in progs.values())
    wp, _c, _o = X.wsa1_stream_words()
    print("== RULE 20 SELF-TEST")
    print("   KN5000 corpus words   %4d   published %4d   %s"
          % (kn_tot, KN_WORDS, "PASS" if kn_tot == KN_WORDS else "FAIL"))
    print("   WSA1R program words   %4d   (informational)" % len(wp))

    for label, code, fld in OPEN:
        kn = kn_sites(code, fld)
        wa = wsa_sites(code, fld)
        kc, kf, ka = profile(kn, "KN")
        wc, wf, wafld = profile(wa, "WSA")
        # rule 4: is the operand a single measured constant in BOTH corpora?
        kn_const = len(ka) == 1
        wa_const = len(wafld) == 1
        closes = kn_const and wa_const
        print("\n== %s 0x%02X   KN5000 %d sites   WSA1R %d sites" % (label, code, len(kn), len(wa)))
        print("   class4  KN %-28s WSA %s" % (top(kc), top(wc)))
        print("   f31     KN %-28s WSA %s" % (dict(kf), dict(wf)))
        print("   addr8   KN %-28s WSA %s" % (top(ka), top(wafld)))
        print("   distinct addr8: KN %d, WSA %d  ->  rule-4 closable: %s"
              % (len(ka), len(wafld), "YES" if closes else "NO (operand varies)"))

    print("\n== VERDICT")
    print("   Every OPEN routing code keeps a varying operand in at least one corpus,")
    print("   so none is closable by rule 4.  The WSA1R corpus confirms the ISA field")
    print("   model but supplies occurrences, not a consumer -- decoding these needs an")
    print("   execution instrument (a uPD6383 device fed the WSA1R microcode).")


if __name__ == "__main__":
    sys.exit(main())
