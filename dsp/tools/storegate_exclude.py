#!/usr/bin/env python3
"""storegate_exclude.py -- can the rival store-gate reading be excluded by a store census?

QUESTION IT ANSWERS
    `store-gate.md' item C ran all nine enumerated gate conditions against both witnesses and
    exactly TWO survive:  `b7 & f31 == 1'  and  `b7 & f31 != 2'.  Its own note says they "differ
    only where alu_decoded() already refuses" -- and that place is now countable: **16 words whose
    SOLE open axis is `store gate, f31 0'**, four distinct shapes, every one carrying
    `hi12 = 0x090' (bit 7 set, bit 4 set, f31 = 0), and every one of them in a REVERB:

        090201000 x7   090206000 x7   090A001D5 x1   0902FB40E x1

    At f31 = 0 the two survivors DISAGREE: `b7 & f31 == 1' lets the store happen (the shipped
    device's reading), `b7 & f31 != 2' suppresses it.  Sixteen words turn on which is right.

    So: is the rival excludable WITHOUT an emulator run?  A reverb is a delay line, and a program
    that never writes memory cannot be one.  If suppressing every `b7 & f31 != 2' word leaves any
    reverb with ZERO surviving stores, the rival is dead on structure alone.

USAGE
    python3 dsp/tools/storegate_exclude.py

MEASURED 2026-09-14 -- ⛔ AND THE ANSWER IS NO:

        image                          stores   suppressed   SURVIVE
        KN  prog16_room_reverb_1          32        2          30
        WSA eff26_room_reverb_1           22        6          16
        WSA eff28_plate_reverb_1          21        4          17
        WSA eff30_concert_reverb_1        22        6          16
        WSA struct_6a_fce71f              22        5          17
        WSA struct_6a_fcfca1              22        5          17
        WSA struct_6a_fd91ea              21        6          15
        WSA struct_6a_fdb219              22        5          17

    Every reverb keeps 15 to 30 stores under the rival gate.  The structural argument FAILS and
    the rival is NOT excluded: these programs write memory plentifully either way.

    ⇒ the 16 words stay open, and separating the two survivors needs a criterion that can see
    the difference -- an emulator arm graded against the HLE reverb oracle, not a word count.
    ⚠ Recorded so the cheap argument is not re-attempted in the belief that it works.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402
import acc_blind as AB                                                    # noqa: E402


def is_store(w):
    """A word that writes memory: the bit-4 store, or ACT 0x07 (store to the bus)."""
    return bool(DIS.hi12(w) & DIS.HI_ST) or DIS.lo_act(w) == DIS.LO_ACT_ST_BUS


def suppressed_by_rival(w):
    """`b7 & f31 != 2' -- the survivor the shipped device does NOT implement."""
    return bool(DIS.hi12(w) & DIS.HI_B7) and DIS.hi_f31(DIS.hi12(w)) != 2


def main():
    #  1 -- locate the words the two survivors disagree about, from the project's own enumerator.
    owner = collections.defaultdict(list)
    seen = set()
    for label, img, _s, ws in CT.images():
        k = (label, tuple(ws))
        if k in seen:
            continue
        seen.add(k)
        for w in ws:
            if DIS.decoded(w):
                continue
            if tuple(sorted(AB.open_axes(w))) == ("store gate, f31 0",):
                owner[(label, img)].append(w)
    tot = sum(len(v) for v in owner.values())
    print("=" * 88)
    print("  storegate_exclude -- can a store census kill the rival gate reading?")
    print("=" * 88)
    print("\n  words whose SOLE open axis is `store gate, f31 0': %d, in %d images"
          % (tot, len(owner)))
    sh = collections.Counter(w for v in owner.values() for w in v)
    for w, n in sh.most_common():
        print("     %09X x%-2d  hi12=%03X f31=%d b7=%d bit4=%d class=%X addr8=%02X"
              % (w, n, DIS.hi12(w), DIS.hi_f31(DIS.hi12(w)),
                 1 if DIS.hi12(w) & DIS.HI_B7 else 0,
                 1 if DIS.hi12(w) & DIS.HI_ST else 0,
                 DIS.class4(w), (w >> 12) & 0xff))

    #  2 -- the exclusion test.
    print("\n  THE TEST: suppress every `b7 & f31 != 2' word and count what still writes.\n")
    print("  image                            stores   suppressed   SURVIVE")
    dead = 0
    names = {img for _l, img in owner}
    seen2 = set()
    for label, img, _s, ws in CT.images():
        if img not in names:
            continue
        k = (label, tuple(ws))
        if k in seen2:
            continue
        seen2.add(k)
        st = [w for w in ws if is_store(w)]
        sup = [w for w in st if suppressed_by_rival(w)]
        surv = len(st) - len(sup)
        if surv == 0:
            dead += 1
        print("  %-4s %-28s %6d %11d %9d%s"
              % (label, img[:28], len(st), len(sup), surv,
                 "   <- NO STORE SURVIVES" if surv == 0 else ""))
    print()
    if dead:
        print("  ★ %d image(s) keep ZERO stores under the rival -- a reverb that never writes" % dead)
        print("    memory cannot be a reverb, so the rival is EXCLUDED on structure alone.")
        return 0
    print("  ⛔ EVERY image keeps stores under the rival gate.  The structural argument FAILS:")
    print("     these programs write memory plentifully either way, so a word count cannot")
    print("     separate the two survivors.  The 16 words stay open.")
    print("  ⇒ separating them needs a criterion that can SEE the difference -- an emulator arm")
    print("    graded against the HLE reverb oracle.  ⚠ Do not re-attempt the cheap argument.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
