#!/usr/bin/env python3
"""The code/data LAYOUT of prom_b 0xF6D002-0xF77FFF -- round 6's span.

WHAT THE BLOCK IS.  Its own strings name it: `  TEMPO  `, `START   STOP    FILL
IN1FILL IN2INTRO1  COUNT INENDING1`, `P 1 P 2 ... P32`, `VOLUME=`, `PANPOT=`,
`KEY SHIFT=`, `TUNING=`, `BEND SENS=`, `SUSTAIN ON  OFF `, `DSP EFFECT `,
`EFFECT1=`, `REVERB=`, `PANEL MEMORY=`, `APC OFF         ONE FINGER      FINGERED
        PIANIST`, `ACCOMP PART1 ON`, `DYNAMIC ACCOMP ON `, `TECHNI-CHORD ON `,
`ACC. TOTAL VOL.=`, `TOTAL REVERB `, `M.S.A. OFF ON  #2  #3  `,
`TIME SIGNATURE: /4`, `CTRL.PEDAL=`, `R.T.CREAT.X=`.  It is the PERFORMANCE and
ACCOMPANIMENT screen layer, and 0xF6F000 upwards is the sequencer/song side --
`MThdMTrk` sits at 0xF6F528.  ⚠ That is what the STRINGS say.  It is not a claim
about any individual routine; every routine below is `sub_XXXXXX` with its
evidence grade, exactly as in rounds 4 and 5.

QUESTION IT ANSWERS
  "Which bytes of 0xF6D002-0xF78000 are instructions, which are tables, which are
   screen text, and WHY is each code byte code?"  Frozen into
   notes/gen_prom_b_f6d002_module.py's LAYOUT, re-derived on every emit.

WHAT IS DIFFERENT FROM notes/prom_b_f0ea9f_layout.py, WHICH THIS IMPORTS
  NOTHING in the rules -- and that is the finding.  Round 5's rule set is the
  first one in this lane that transferred to a new module unchanged: 0 barrier
  conflicts, and every null re-measured on this span's own corpus still fires
  zero.  The only settings that move are LO/HI.  Round 5 had to add five rules
  to round 4's; round 6 had to add none, so the method is now calibrated rather
  than being re-invented per block.

  ⚠ ONE THING IS NEW AND IT IS A MEASUREMENT, NOT A RULE: this span contains a
  865-byte run of 0x0E at 0xF6EC9F, the first `.fill` any prom_b round has met.
  It is FILLER and is reported separately from the substantive total, per
  scripts/analysis/source_coverage.py's split.

RUN
  python3 notes/prom_b_f6d002_layout.py                 # the LAYOUT table
  python3 notes/prom_b_f6d002_layout.py --provenance    # WHY each segment is code
  python3 notes/prom_b_f6d002_layout.py --conflicts     # descent-vs-barrier (0)
  python3 notes/prom_b_f6d002_layout.py --null-ptr      # content-rule null
  python3 notes/prom_b_f6d002_layout.py --residue       # unsplit runs, with hex
  python3 notes/prom_b_f6d002_layout.py --python        # paste-ready LAYOUT
  python3 notes/prom_b_f6d002_layout.py --all           # all of it, one process
Exit status is non-zero if a --null or --conflicts run finds something it must
not.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import trace_code as TC                                            # noqa: E402

LO, HI = 0xF6D002, 0xF78000
LY.LO, LY.HI = LO, HI          # every LY function reads these at call time

# build() is called twice by --all and by --provenance and costs ~30 s; the
# 0xF0EA9F module was small enough not to notice and this one is not.
_built = []
_orig_build = LY.build


def build():
    if not _built:
        _built.append(_orig_build())
    return _built[0]


LY.build = build


def _seg_boundaries():
    """Instruction START addresses of every `code` segment, walked linearly.

    WHY THIS EXISTS.  LY.provenance() calls MT.decode_at() once per CODE BYTE
    (`for a in sorted(seen)`), and decode_at falls back to spawning unidasm for
    any address the merged phase table missed -- which is most mid-instruction
    addresses.  On the 0xF0EA9F module's 13,357 code bytes that was tolerable; on
    this module's 32,569 it is tens of thousands of subprocesses and the report
    never finishes.  Walking BOUNDARIES gives the identical branch-target and
    immediate sets -- an operand can only be read off an instruction, and every
    instruction starts at a boundary -- at a third of the calls, each of which is
    on a boundary and therefore usually already in the table."""
    out = []
    for kind, a, n in build()[0]:
        if kind != "code":
            continue
        p = a
        while p < a + n:
            dec = MT.decode_at(p)
            if dec is None:
                break
            out.append((p, dec[1]))
            p += dec[0]
    return out


def provenance():
    """LY.provenance(), but seeded from _seg_boundaries().  Same grades, same
    order, same weak-grade listing; see prom_b_f0ea9f_layout.provenance."""
    d = L.rom()
    segs, conflicts, pend, ok, seen = build()
    proven = LY.proven_call_sites(LO, HI)
    thunk = set(t for _, t in MT.thunk_entries(LO, HI))
    far = L.far_calls(d, LO, HI)
    tab = LY.table_entry_seeds(d, LO, HI)
    branch, immed = set(), set()
    for a, txt in _seg_boundaries():
        for t in TC.branch_targets(txt):
            branch.add(t)
        for m in re.findall(r"0x00([0-9a-f]{6})", txt):
            immed.add(int(m, 16))
    accepted = set(s for s, _ in ok)
    grades, rows = {}, []
    prev_end, prev_kind = None, None
    for kind, s, n in segs:
        if kind != "code":
            prev_kind, prev_end = kind, s + n
            continue
        g = ("PROVEN" if s in proven else
             "THUNK" if s in thunk else "CALL" if s in far else
             "BRANCH" if s in branch else
             "FALL" if prev_kind == "code" and prev_end == s else
             "IMMED" if s in immed else "TABLE" if s in tab else
             "ACCEPT" if s in accepted else "NONE")
        grades[g] = grades.get(g, 0) + 1
        rows.append((g, s, n))
        prev_kind, prev_end = kind, s + n
    order = ["PROVEN", "THUNK", "CALL", "BRANCH", "FALL", "TABLE", "ACCEPT",
             "IMMED", "NONE"]
    print("code segments by the STRONGEST reason their entry point is code:")
    for g in order:
        if g in grades:
            b = sum(n for gg, _, n in rows if gg == g)
            print("  %-7s %3d segments  %6d bytes" % (g, grades[g], b))
    print("\nthe weak grades, every one (look at these by hand):")
    for g in ("TABLE", "ACCEPT", "IMMED", "NONE"):
        for gg, s, n in rows:
            if gg == g:
                print("  %-7s 0x%06X  %5d bytes" % (g, s, n))
    return sum(1 for g, _, _ in rows if g == "NONE")


LY.provenance = provenance

if __name__ == "__main__":
    sys.exit(LY.main())
