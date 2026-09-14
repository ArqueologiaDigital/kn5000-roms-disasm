#!/usr/bin/env python3
"""queue_probes.py -- four cheap attacks on the decode queue, and the four nulls they returned.

QUESTION IT ANSWERS
    After sect. 128 the pooled queue is dominated by two entries that a session cannot crack --
    `SRC 0x11' (171 sole) is a documented DEPENDENCY CYCLE and `ACT 0x0B' (191 sole) has two
    criteria measured blind to it (sect. 130, LEDGER sect. 291).  Before spending more on either,
    four cheaper lines were worth a look.  All four came back empty, and an empty line that is not
    written down gets walked again.

USAGE
    python3 dsp/tools/queue_probes.py

THE FOUR
    1. MORE CLASS MINIMAL PAIRS?  `class_twins.py' rests the classes-4/6 pointer reading on n = 2
       -- one WSA1R program spelling the C63 macro in class 2 where 99 instances spell it class 4 --
       and the project declined to promote on that.  sect. 125 gave us aligned homolog pairs, so:
       do any of them substitute one class for another at an ALIGNED slot?  That would raise n
       without lowering the bar.
    2. THE CLASS GUARD IS A LIST, NOT A DECOMPOSITION.  `class4' bit 3 is the CURSOR-FETCH enable
       (`cursor_fetch': "bit 23 (== class4 bit3)") and bits 2:0 are the ADDRESSING MODE
       (`upd6383.cpp' rdmode/stmode = `class4 & 7').  `alu_decoded' guard 2 admits `(2, 8, 0xA)' --
       (mode 2, no fetch), (mode 0, fetch), (mode 2, fetch) -- and refuses **class 0**, the fourth
       corner, whose every component is admitted elsewhere.  Guards 5 and 6 of the same function
       already speak the decomposition (`(cl & 7) != 2').  How many words does that cost?
    3. DOES THE SECOND PRODUCT INTRODUCE UNREVIEWED VOCABULARY?  Every pass in this project read
       the KN5000.  A SRC or ACT code occurring only in the SX-WSA1R would never have been looked
       at by anyone.
    4. THE DOCUMENTED SIBLING, AT THE FIELD THAT MATTERS.  `NEC-uPD77C25-rosetta-2026-09-09.md'
       found the 6383's SOURCE codes matching NEC's documented uPD7720/77C25 register encoding
       (RAM 0x07, ACCA/ACCB 0x10/0x11, TA/TB 0x19/0x1A) -- which is why the analogy was taken
       seriously.  `f31' 3..7 is 257 undecoded words.  So: do the ALU-operation codes match too?
       The note warns they should not be transferred; this MEASURES it at that field instead of
       assuming it either way.

⚠ Four nulls is the result, not a failure of the tool.  Each one closes a line and says why.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402

#   MAME's own upd7725 core, src/devices/cpu/upd7725/upd7725.cpp, the ALU switch.
#   NEC's documented sibling family; 4-bit field, 16 operations.
UPD7725_ALU = {0: "NOP", 1: "OR", 2: "AND", 3: "XOR", 4: "SUB", 5: "ADD", 6: "SBB",
               7: "ADC", 8: "DEC", 9: "INC", 10: "CMP", 11: "SHR1", 12: "SHL1",
               13: "SHL2", 14: "SHL4", 15: "XCHG"}
#   The uPD6383's `f31' = hi12[3:1], 3 bits, and the three values the biquad pins.
UPD6383_F31 = {DIS.HI_ACC_LOAD: "acc <- P        (LOAD)",
               DIS.HI_ACC_ADD:  "acc <- acc + P  (ADD)",
               DIS.HI_ACC_HOLD: "acc unchanged   (HOLD/NOP)"}


def probe1():
    print("\n   ★ PROBE 1 -- aligned CLASS substitutions in the homolog pairs\n")
    imgs = list(X.images())
    kn = [t for t in imgs if t[0] == "KN"]
    ws = [t for t in imgs if t[0] == "WSA"]
    hits = 0
    for _, na, a in kn:
        for _, nb, b in ws:
            s, ops = X.score(a, b)
            if s < 35:
                continue
            for op, i1, i2, j1, j2 in ops:
                if op != "replace" or (i2 - i1) != 1 or (j2 - j1) != 1:
                    continue
                wa, wb = a[i1], b[j1]
                if DIS.c_format(wa) or DIS.c_format(wb) or wa == wb:
                    continue
                if ((DIS.hi12(wa), DIS.addr8(wa), DIS.lo12(wa))
                        == (DIS.hi12(wb), DIS.addr8(wb), DIS.lo12(wb))):
                    hits += 1
                    print("      %s w%d  class %X  <->  %s w%d  class %X"
                          % (na, i1, DIS.class4(wa), nb, j1, DIS.class4(wb)))
    print("      ⇒ %d.  %s" % (hits, "n rises" if hits else
          "NONE -- the homologs never swap a class at an aligned slot, so the classes-4/6"
          " reading stays at n = 2 and the project's non-promotion stands."))
    return hits


def probe2():
    print("\n   ★ PROBE 2 -- the class guard's missing 2x2 corner\n")
    print("      %-10s %-22s %-22s" % ("", "fetch = 0", "fetch = 1"))
    print("      %-10s %-22s %-22s" % ("mode 0", "class 0  ⛔ REFUSED", "class 8  ✔ admitted"))
    print("      %-10s %-22s %-22s" % ("mode 2", "class 2  ✔ admitted", "class A  ✔ admitted"))

    def would(w):
        cl = DIS.class4(w)
        if DIS.c_format(w) or cl not in (0, 2, 8, 0xA):
            return False
        if (DIS.lo12(w) & 0x800) or DIS.lo_ptrmode(w):
            return False
        if DIS.lo_src(w) not in DIS._ANCHORED_SRC or not DIS._act_anchored(w):
            return False
        if (DIS.hi12(w) & DIS.HI_ST) and (cl & 7) != 2:
            return False
        if DIS.lo_act(w) == DIS.LO_ACT_ST_BUS and (cl & 7) != 2:
            return False
        hi = DIS.hi12(w)
        if (hi & DIS.HI_ST) and (hi & DIS.HI_B7) and DIS.hi_f31(hi) not in (1, 2):
            return False
        return DIS.hi_f31(hi) in (DIS.HI_ACC_LOAD, DIS.HI_ACC_ADD, DIS.HI_ACC_HOLD)

    tot = gain = 0
    for label, name, ws in X.images():
        for w in ws:
            if DIS.c_format(w) or DIS.class4(w) != 0:
                continue
            tot += 1
            if not DIS.decoded(w) and would(w):
                gain += 1
    print("\n      %d class-0 words pooled; admitting the missing corner decodes %d." % (tot, gain))
    print("      ⇒ %s" % ("a real gain" if gain else
          "the asymmetry is REAL but INERT -- every class-0 word is refused on its SRC, ACT or"
          " f31 anyway, so the guard's shape costs nothing and fixing it would buy nothing."))
    return gain


def probe3():
    print("\n   ★ PROBE 3 -- SRC/ACT codes exclusive to one product\n")
    src = collections.defaultdict(collections.Counter)
    act = collections.defaultdict(collections.Counter)
    for label, name, ws in X.images():
        for w in ws:
            if DIS.c_format(w) or (DIS.lo12(w) & 0x800):
                continue
            src[DIS.lo_src(w)][label] += 1
            act[DIS.lo_act(w)][label] += 1
    only = {"KN": [], "WSA": []}
    for nm, tab in (("SRC", src), ("ACT", act)):
        for code, c in tab.items():
            if c.get("KN", 0) == 0:
                only["WSA"].append((nm, code, c["WSA"]))
            elif c.get("WSA", 0) == 0:
                only["KN"].append((nm, code, c["KN"]))
    for nm, code, n in sorted(only["WSA"]):
        print("      WSA-only  %s 0x%02X  x%d" % (nm, code, n))
    for nm, code, n in sorted(only["KN"]):
        print("      KN-only   %s 0x%02X  x%d" % (nm, code, n))
    print("      ⇒ %d WSA1R-only codes, %d KN5000-only." % (len(only["WSA"]), len(only["KN"])))
    print("      ⇒ %s" % ("unreviewed vocabulary exists" if only["WSA"] else
          "NONE from the second product -- the two products share one SRC/ACT vocabulary, so the"
          " WSA1R's 851 remaining words are blocked by the SAME codes, not by new ones."))
    return len(only["WSA"])


def probe4():
    print("\n   ★ PROBE 4 -- the documented sibling, at the ALU field\n")
    print("      uPD6383 `f31' (3 bits), the values the biquad PINS:")
    for v, nm in sorted(UPD6383_F31.items()):
        print("         %d = %s" % (v, nm))
    print("      NEC uPD7725 ALU field (4 bits), from MAME's own core:")
    for v in (0, 5):
        print("         %d = %s" % (v, UPD7725_ALU[v]))
    match = (UPD7725_ALU.get(DIS.HI_ACC_ADD) == "ADD"
             and UPD7725_ALU.get(DIS.HI_ACC_HOLD) == "NOP")
    print("\n      ⇒ 6383 ADD = %d, 7725 ADD = 5.   6383 HOLD = %d, 7725 NOP = 0."
          % (DIS.HI_ACC_ADD, DIS.HI_ACC_HOLD))
    print("      ⇒ %s" % ("the codes transfer" if match else
          "THE NUMERIC CODES DO NOT TRANSFER at this field.  The rosetta note's own caveat --"))
    if not match:
        print("        *\"analogy to a sibling FAMILY, not ISA identity; numeric codes don't"
              " transfer\"* -- is now MEASURED at the field it matters for, not assumed.  The")
        print("        SOURCE codes matching was real and is not evidence about the ALU field.")
        print("        ⇒ `f31' 3..7 (257 undecoded words) gets nothing from this route.")
    return match


def main():
    print("=" * 100)
    print("  queue_probes -- four cheap attacks on the decode queue")
    print("=" * 100)
    r = [probe1(), probe2(), probe3(), probe4()]
    print("\n   ⇒ %d of 4 probes returned something; %d are nulls, recorded so they are not"
          % (sum(1 for x in r if x), sum(1 for x in r if not x)))
    print("     walked again." )
    return 0


if __name__ == "__main__":
    sys.exit(main())
