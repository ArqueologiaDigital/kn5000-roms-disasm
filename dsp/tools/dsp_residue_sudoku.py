#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_residue_sudoku.py -- the prioritised "promote next" roadmap for the uPD6383GF ISA.

The speculative tier executes ~86.7% of the distinct corpus words (KN5000 + WSA1R). This
tool characterises the EXECUTABLE RESIDUE -- the words the speculative ALU still cannot run
-- groups them by the (class, src, act) signature that blocks them, attaches the effect
FAMILIES each appears in (the topology context), and proposes a GRADED reading per group.
It is the "sudoku": each proposal is constrained by (a) the field halves that ARE known,
(b) the algorithm topology of the programs the word lives in, and (c) cross-product
frequency.  Groups are sorted by how much executable coverage a correct reading would add,
so the top rows are the cheapest routes to a complete executable model.

⚠ A proposal here is a PROSPECTIVE hypothesis to be tested (by a device arm + the algorithm
validators), NOT a measured fact.  It is graded, and it never overwrites the strict/spec
tiers -- exactly the project's standing discipline (unknown operations stay OPEN).

    python3 dsp/tools/dsp_residue_sudoku.py            # the roadmap table

Reads the committed .dsm listings of both products; stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")

# known field meanings (measured MEA / speculative SPE), for the proposal text.
SRC = {0x00: "delay-RAM read (SPE)", 0x07: "mem[ptr] (MEA)", 0x10: "accumulator (MEA)",
       0x11: "ACCB 2nd-acc (SPE)", 0x13: "coeff-table port (MEA-const)",
       0x1B: "delay-read reg (SPE)", 0x1C: "LFO output (SPE)", 0x02: "D-RAM[dp] (MEA)",
       0x08: "OPEN routing src", 0x0B: "OPEN routing src"}
ACT = {0x00: "adder bus term (MEA)", 0x01: "store (MEA)", 0x07: "store variant (SPE)",
       0x0D: "biquad z^-1 (SPE)", 0x0E: "biquad z^-1 (SPE)", 0x15: "D-RAM-reg write (SPE)",
       0x0B: "OPEN routing act", 0x08: "table-mul (SPE)", 0x1A: "OPEN act", 0x1D: "OPEN act",
       0x19: "OPEN act", 0x05: "OPEN act", 0x1C: "OPEN act"}


def family_of(name):
    n = (name or "").upper()
    if "+" in n:              return "combination"
    if "REVERB" in n:         return "reverb"
    if "DELAY" in n:          return "delay"
    if "PITCH" in n:          return "pitch"
    if "ROTARY" in n:         return "rotary"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "ENSEMBLE", "VIBRATO",
                            "AUTO PAN", "RING MOD", "HAAS")):          return "modulation"
    if any(k in n for k in ("DISTORT", "OVERDRIVE", "FUZZ")):          return "distortion"
    if any(k in n for k in ("PARAMETRIC EQ", "ENHANCER", "WAH")):      return "eq/filter"
    if any(k in n for k in ("COMPRESS", "NO OPERATION", "SLOW ATT")):  return "dynamics"
    if any(k in n for k in ("EXCITER", "NOISE")):                      return "exciter"
    return "other"


def collect():
    """word -> set of families it appears in, across both products' .dsm."""
    fam = collections.defaultdict(set)
    for tree in (os.path.join(HERE, "..", "disasm"),
                 os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")):
        for p in glob.glob(os.path.join(tree, "*.dsm")):
            if os.path.basename(p) == "index.dsm":
                continue
            name, words = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    name = m.group(1)
                m = WORD.match(ln)
                if m:
                    words.append(int(m.group(1), 16))
            for w in words:
                fam[w].add(family_of(name))
    return fam


def signature(w):
    if D.c_format(w):
        op = D.c_opcode(w) if hasattr(D, "c_opcode") else 0
        return ("cfmt", op, None)
    return (D.class4(w), D.lo_src(w), D.lo_act(w))


def propose(sig, fams):
    """a graded reading proposal for a residue signature, given its family context."""
    if sig[0] == "cfmt":
        return ("C-format immediate-load opcode 0x%03X: loads imm13 into register lo12; "
                "SAFE to execute as 'reg[lo12] <- imm13' (the value is MEASURED; only the "
                "destination is unnamed). Adopt as a no-side-effect register load." % sig[1])
    cls, src, act = sig
    s = SRC.get(src, "src 0x%02X (undocumented)" % src)
    a = ACT.get(act, "act 0x%02X (undocumented)" % act)
    hint = ""
    ff = fams
    if ff <= {"eq/filter", "combination"}:
        hint = " Topology: lives only in biquad/EQ programs => a filter coefficient MAC or z^-1 state update."
    elif ff <= {"reverb"}:
        hint = " Topology: reverb-only => an all-pass/comb tap gain or damping one-pole."
    elif ff <= {"delay", "combination"}:
        hint = " Topology: delay programs => a feedback-gain MAC or tap read."
    elif "modulation" in ff:
        hint = " Topology: modulation => LFO-swept path (phase/coeff)."
    base = {2: "class-2 post-increment MAC/store", 10: "class-A load+coeff (ld acc,c+)",
            8: "class-A multiply", 0: "mode-0 load/route", 1: "class-1 escape/mode-1",
            6: "class-6 table lookup"}.get(cls, "class-%d" % cls)
    return "%s with source=%s, action=%s.%s" % (base, s, a, hint)


def main():
    fam = collect()
    words = sorted(fam)
    resid = [w for w in words if not D.alu_decoded_spec(w)]
    groups = collections.defaultdict(list)
    for w in resid:
        groups[signature(w)].append(w)
    total = len(words)
    covered = sum(1 for w in words if D.alu_decoded_spec(w))
    print("uPD6383GF EXECUTABLE-RESIDUE SUDOKU  (KN5000 + WSA1R, distinct words)")
    print("distinct words %d | spec-executable %d (%.1f%%) | residue %d (%.1f%%)\n"
          % (total, covered, 100 * covered / total, len(resid), 100 * len(resid) / total))
    print("Groups sorted by executable coverage a correct reading would ADD:\n")
    running = covered
    for sig, ws in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        fams = set().union(*(fam[w] for w in ws))
        running += len(ws)
        sigstr = ("cfmt op 0x%03X" % sig[1]) if sig[0] == "cfmt" \
            else "cls=%d src=0x%02X act=0x%02X" % sig
        print("  [%2d words -> +%.1f%% -> %.1f%%]  %s"
              % (len(ws), 100 * len(ws) / total, 100 * running / total, sigstr))
        print("      families: %s" % ", ".join(sorted(fams)))
        print("      propose : %s" % propose(sig, fams))
    print("\nThe first ~9 groups reach the ~93.3%% executable ceiling; the tail is "
          "singletons needing a per-word device arm (rule 4 / hardware Q4).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
