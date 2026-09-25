#!/usr/bin/env python3
r"""Run the branch symboliser on prom_b with TWO of its R3 "absurd marker" shapes recognised as code.

QUESTION THIS ANSWERS
    scripts/converters/symbolize_numeric_branches.py refuses every numeric
    branch within 12 instructions of an "absurd" instruction (its rule R3).
    On prom_b, 182 of its 202 R3 refusals are caused by exactly two shapes that
    are ordinary code in THIS image:

      * `jr cc, 0` right after a compare or test -- `cp A,0xb0 / jr Z,0`: the
        compiler's empty case, a branch to the next instruction.  (It is absurd
        after a `swi` or a `.byte` island, which is what R3 was written for.)
      * a run of `nop`s straight after a `ret`/`reti`/unconditional jump -- the
        alignment padding between two routines (sub_F001C9_Arm ends
        `ret / nop / nop` at 0xF00290 before sub_F00293).

    This wrapper loads the shared tool's source UNCHANGED on disk, patches that
    one test in memory (asserting the text it patches is present), and runs
    the tool's own main() -- so every other rule (R1, R2, R5 second decoder,
    R6 table/text, boundary targets, naming, --verify re-mirroring) is the
    shared tool's.  The remaining R3 shapes (reti without pop, `normal`, nop
    pairs NOT after a routine end) still refuse.

RUN
    python3 notes/promb-2026-09-25/symbolize_prom_b_r3.py --report R.json      # dry
    python3 notes/promb-2026-09-25/symbolize_prom_b_r3.py --apply --verify
    make gate-wsa1
"""
import os
import re
import sys
import types

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TOOL = os.path.join(ROOT, "scripts", "converters", "symbolize_numeric_branches.py")

OLD_INIT = '''        prev = ""
        k = 0
'''
NEW_INIT = '''        prev = ""
        _hist = []
        k = 0
'''
OLD_TEST = '''                if ABSURD.match(c) or (c == "nop" and prev == "nop") or (
                        c == "reti" and not prev.startswith("pop")):'''
NEW_TEST = '''                _hist.append(c)
                if _lane_absurd(ABSURD, c, prev, _hist, img):'''

CMP = re.compile(r'^(cp|cpw|bit|and|or|xor|sub|add|inc|dec|tst|m_cp|m_bit|m_and|m_or|m_xor|'
                 r'm_tst|mx_cp|cp_)')
JRCC0 = re.compile(r'^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$')
TERM = re.compile(r'^(ret|reti|retd\b|jp\s+[^,]+$|jr\s+[^,]+$|jrl\s+[^,]+$|jp\s+t\s*,|jr\s+t\s*,)')


def _lane_absurd(ABSURD, c, prev, hist, img):
    if img.get("key") == "prom_b":
        if JRCC0.match(c) and CMP.match(prev):
            return False
        if c == "nop" and prev == "nop":
            j = len(hist) - 1
            while j >= 0 and hist[j] == "nop":
                j -= 1
            if j >= 0 and TERM.match(hist[j]):
                return False          # a run of nops that starts right after a routine end
    return bool(ABSURD.match(c) or (c == "nop" and prev == "nop") or (
        c == "reti" and not prev.startswith("pop")))


def load():
    src = open(TOOL).read()
    for old, new in ((OLD_INIT, NEW_INIT), (OLD_TEST, NEW_TEST)):
        if src.count(old) != 1:
            sys.exit("the shared tool changed: the text to patch occurs %d times" % src.count(old))
        src = src.replace(old, new)
    mod = types.ModuleType("snb_prom_b_r3")
    mod.__file__ = TOOL
    mod.__dict__["_lane_absurd"] = _lane_absurd
    sys.path.insert(0, os.path.dirname(TOOL))
    exec(compile(src, TOOL, "exec"), mod.__dict__)
    return mod


def main():
    if "--image" not in sys.argv:
        sys.argv[1:1] = ["--image", "prom_b", "--only", "prom_b/wsa1_prom_b.s"]
    mod = load()
    return mod.main()


if __name__ == "__main__":
    sys.exit(main())
