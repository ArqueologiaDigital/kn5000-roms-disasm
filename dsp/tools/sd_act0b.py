#!/usr/bin/env python3
"""sd_act0b.py -- `ACTION 0x0B' against SINGLE DELAY's lag-1001 ROM product.

QUESTION IT ANSWERS
    `ACT 0x0B' is the second-largest entry in `decode_leverage.py' (62 sole, 66 occurrences) and
    `act0b-reverb.md' item D collapsed its six readings to **three** -- `none`, `mem<-bus`,
    `tA<-acc` -- and then stopped, item H: *"picking between them needs known mathematics the
    reverb does not supply -- the diffuser gains are known but there is NO REFERENCE RESPONSE."*

    ★ SINGLE DELAY supplies one, and it is the ROM's own arithmetic rather than a fit: an impulse
    must return at the cascade lag **1001** carrying **45 074** = `((c*c)>>23)*h>>23` from the
    program's own coefficients.  `sd_rerun.py` builds that harness and self-tests it **13 of 13**.
    ⇒ and `prog09_single_delay` carries **three ACT-0x0B words** (`w0`, `w9`, `w32`).

    This is the same shape that closed the store gate in N-INPUT-GATE-OPENED §104-106: an
    enumerated survivor set, a criterion the ROM states, and elimination.

USAGE
    python3 dsp/tools/sd_act0b.py

WHAT IT DOES, in the order the rules require
    1. ★ REACH TEST (rule 15) FIRST.  `ACT0B_FIRED` is counted UNCONDITIONALLY inside the machine
       model, so "nothing moved" can be told apart from "the code never ran".  If it is 0 the run
       says nothing and says so.
    2. ★ THE CONTROL THAT CAN FAIL.  The known-good machine must reproduce the ROM answer, and the
       ADDRESSING must not move across the readings -- otherwise a difference in the echo is a
       difference in where the impulse was written, not in what `ACT 0x0B' does.
    3. The sweep: all six readings scored on `(lag 1001, sample 45074)`.

⚠ A reading that survives here is not decoded -- it is not refuted by THIS criterion.  The gate
  §106 closed took two independent criteria (a firmware cell and the LFO) to eliminate four rivals;
  one criterion can only ever do part of that, and this file reports what it did, not what it hoped.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                 # noqa: E402
import action00_discriminate as A                                        # noqa: E402
import sd_rerun as SD                                                    # noqa: E402

ACT0B_MENU = ("none", "tA<-bus", "tB<-bus", "tA<-acc", "tB<-acc", "mem<-bus")
#   act0b-reverb.md item D: the six collapse to three at the reverb's sites.  The other three are
#   carried anyway -- a menu pruned by one criterion is not a menu when a second one is applied.
SURVIVORS = ("none", "mem<-bus", "tA<-acc")


def main():
    SD.hdr("act0b -- ACTION 0x0B against SINGLE DELAY's lag-1001 ROM product")
    lag, _D = SD.cascade()[1], None
    stages, D = SD.cascade()
    want = SD.predicted_echo_sample(1 << 21)
    words, cells, cons, coefs = SD.descriptors()

    #  ---- 1. REACH TEST (rule 15) -----------------------------------------
    sites = [i for i, w in enumerate(words)
             if not DIS.c_format(w) and DIS.lo_act(w) == 0x0B]
    print("   ★ REACH TEST FIRST (rule 15) -- a09's own ACT-0x0B words:\n")
    for i in sites:
        w = words[i]
        print("      w%-3d %010X  class %X  addr8 %02X  SRC %02X  f31 %d  store %d  %s"
              % (i, w, DIS.class4(w), DIS.addr8(w), DIS.lo_src(w),
                 DIS.hi_f31(DIS.hi12(w)), (DIS.hi12(w) >> 4) & 1,
                 "delay-DRAM escape" if DIS.is_dram(w) else "plain"))
    if not sites:
        print("      NONE -- this criterion cannot see the code at all.")
        return 1

    A.ACT0B_FIRED[0] = 0
    #  ⚠ `BASE' leaves `act0d'/`act0e' unset and `A.step()' REFUSES a word carrying either, so
    #  `out_run' returns None and every score would be a silent null.  Pin them to the SHIPPED
    #  pair -- the one `sd_rerun.py act0d0e' grades -- so this sweep varies ACT 0x0B and nothing
    #  else.  (Found by the harness returning None rather than a number, which is the failure mode
    #  a `None` check catches and an `if not ev` check would not.)
    #  ⚠⚠ AND THE SHIPPED `act0d'/`act0e' PAIR DOES NOT REPRODUCE THE ROM ANSWER.  §234 already
    #  records it: *"the shipped pair puts the same 45074 at lag 500 ... 37 of 49 pairs pass the
    #  pre-registered (1001, 45074) and the shipped pair is not one of them."*  A baseline that
    #  fails the criterion cannot host a sweep, so the pair is chosen MECHANICALLY -- the FIRST in
    #  menu order that reproduces (lag, sample) -- and printed, so the choice is inspectable rather
    #  than fitted.  Which pair is right is §234's open question and is not touched here.
    base_de = None
    for d in SD.ACT0D0E_MENU:
        for e in SD.ACT0D0E_MENU:
            rr = SD.out_run(SD.machine(act0d=d, act0e=e, act0b="none"),
                            nsamp=SD.NSCORE, incell=SD.CELL_PUB, p0=SD.P0_PUB)
            if rr is not None and any(x[0] == D and int(x[1]) == want for x in SD.echoes(*rr)):
                base_de = (d, e)
                break
        if base_de:
            break
    print("\n   ★ BASELINE `act0d'/`act0e' = %s -- the first pair in menu order that reproduces"
          % (base_de,))
    print("     the ROM answer.  The SHIPPED pair %s does NOT (it puts 45074 at lag 500, §234)."
          % (SD.SHIPPED,))
    if base_de is None:
        print("      ⛔ no pair reproduces it -- the criterion cannot host a sweep.")
        return 1

    def mach(a):
        return SD.machine(act0d=base_de[0], act0e=base_de[1], act0b=a)

    m0 = mach("none")
    r0 = SD.out_run(m0, nsamp=SD.NSCORE, incell=SD.CELL_PUB, p0=SD.P0_PUB)
    fired = A.ACT0B_FIRED[0]
    print("\n   ⇒ in ONE scoring pass (%d frames) ACT 0x0B fired %d times (UNCONDITIONAL)"
          % (SD.NSCORE, fired))
    #  ⚠ THE THRESHOLD IS NOT "> 0".  Three ACT-0x0B words x %d frames is ~%d firings; anything
    #  far below that means the ACTION stage is not being reached for these words and the sweep
    #  has no power, which is a different statement from "the readings agree".
    expect = len(sites) * SD.NSCORE
    print("      expected if the ACTION stage is reached every frame: ~%d" % expect)
    if fired < expect // 10:
        print("      ⛔ %d of ~%d.  THE ACTION STAGE IS NOT REACHED for these words, so every row"
              % (fired, expect))
        print("         below would be a null with no power.  THE RUN SAYS NOTHING, and this is")
        print("         the same shape as sect. 97: an arm that cannot reach the word it is aimed at.")
        return 1

    #  ---- 2. THE CONTROLS --------------------------------------------------
    ev0 = SD.echoes(*r0)
    good = any(e[0] == D and int(e[1]) == want for e in ev0)
    print("      known-GOOD (act0b = none): %s   %s"
          % (SD.echo_class(ev0),
             "✔ the ROM answer (lag %d, sample %d)" % (D, want) if good
             else "⛔ CONTROL BROKEN -- the harness does not reproduce it; stop here"))
    if not good:
        return 1
    offs = {a: tuple(sorted(SD.ptr_offsets(mach(a)).items())) for a in ACT0B_MENU}
    inv = len(set(offs.values())) == 1
    print("      ★ ADDRESSING CONTROL -- pointer map over the 6 readings: %d distinct   %s"
          % (len(set(offs.values())),
             "✔ INVARIANT, so any echo difference is the ACTION" if inv
             else "⛔ CONFOUNDED -- a reading that moves the pointer is not comparable"))

    #  ---- 3. THE SWEEP -----------------------------------------------------
    print("\n   ★ THE SIX READINGS, pre-registered criterion = lag %d carrying %d\n" % (D, want))
    out = {}
    for a in ACT0B_MENU:
        rr = SD.out_run(mach(a), nsamp=SD.NSCORE, incell=SD.CELL_PUB, p0=SD.P0_PUB)
        if rr is None:
            out[a] = (False, "the machine REFUSES a word -- no run")
            print("      %-9s %-40s ⛔ NO RUN" % (a, out[a][1][:40]))
            continue
        ev = SD.echoes(*rr)
        ok = any(e[0] == D and int(e[1]) == want for e in ev)
        out[a] = (ok, SD.echo_class(ev))
        print("      %-9s %-40s %s%s" % (a, out[a][1][:40], "✔ ACCEPTED" if ok else "⛔ REFUTED",
                                         "   [item D survivor]" if a in SURVIVORS else ""))
    acc = [a for a in ACT0B_MENU if out[a][0]]
    print("\n   ⇒ %d of 6 readings reproduce the ROM product; of item D's three survivors, %d do:"
          " %s" % (len(acc), len([a for a in acc if a in SURVIVORS]),
                   ", ".join(a for a in acc if a in SURVIVORS) or "none"))
    print("   ⚠ Surviving here is NOT a decode -- it is not being refuted by THIS criterion.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
