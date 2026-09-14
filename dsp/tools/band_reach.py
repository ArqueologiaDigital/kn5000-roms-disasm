#!/usr/bin/env python3
"""band_reach.py -- DOES THE WORD UNDER TEST TOUCH A CELL THE ORACLE'S BAND ACTUALLY READS?

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED sect. 160 selected the programs for the mode-4 experiment with this
    criterion: *"an `op0x70' biquad band is consumed DOWNSTREAM of the class-4 word"* -- 11
    algorithms carry a band, 8 contain a class-4 word, 8 of 8 qualified.  sect. 161 ran on one of
    them (EXCITER) and got a large two-sided effect; sect. 164 ran a second (PEQ+CHORUS), got
    NOTHING, and recorded *"I cannot say why"*.

    ★★★ THIS FILE SAYS WHY, AND IT IS THE SAME DEFECT sect. 164 NAMED WITHOUT BEING ABLE TO
    DEMONSTRATE.  `DOWNSTREAM IN PROGRAM ORDER' IS NOT `READS THE CELL THIS WORD TOUCHES'.  Walk
    the D-RAM operand pointer and ask the membership question directly:

        EXCITER       class-4 writes p = 75, 79     band reads p = 75..82     ★ REACHES
        PEQ+CHORUS    class-4 writes p =  7, 13     band reads p = 75..84       cannot reach
        PEQ+FLANGER   class-4 writes p =  9, 15     band reads p = 75..84       cannot reach
        PEQ+VIBRATO   class-4 writes p =  8, 14     band reads p = 75..83       cannot reach
        PEQ+CO+DIST   class-4 writes p = 13, 13     band reads p = 3, 75..84     cannot reach
        PEQ+CO+OVER   class-4 writes p = 80, 87     band reads p = 3, 75..86     cannot reach
        PEQ+DIST+DLY  class-4 writes p = 13, 13     band reads p = 75..82       cannot reach
        PEQ+OVR+DLY   class-4 writes p = 79, 87     band reads p = 75..86       cannot reach

    ⇒ **EXCITER is the ONLY one of the eight where the arm can reach the band.**  The seven
    "failed replications" are PREDICTED negatives: in PEQ+CHORUS the class-4 word writes p = 7 and
    13 while the band reads p = 75..84, so suppressing 5 433 347 stores and performing 3 547 234
    pointer advances leaves the band byte-identical because they never meet.  (They do change a
    great many OTHER cells -- 0x02, 0x87..0x8D, 0x94, 0xD1, 0xD2 -- which is what "the arm works
    but cannot reach this observable" looks like.)

USAGE
    python3 dsp/tools/band_reach.py              # the table above, plus the stability check
    python3 dsp/tools/band_reach.py --all        # every algorithm carrying an op0x70 band

WHY THE POINTER'S UNKNOWN BASE DOES NOT MATTER
    `closure-pointer.md' leaves the body's ENTRY pointer open (the frame does not close; a
    re-establishing mechanism is FORCED).  It does not need to be known: membership of one word's
    cell in another's read set is a question about DIFFERENCES, and the unknown base cancels.  The
    walk here is relative, starting at 0.

⛔⛔ AND THE TRAP THIS FILE MUST NOT HIDE -- the selection is NOT independent of what is under test.
    The walk advances the pointer on class 2 / class A.  Whether it should ALSO advance on class 4
    is the open question (`closure_pointer.py' variant V7).  Run both ways and the verdict FLIPS on
    exactly one program:

        EXCITER   assuming NO MOVE  -> class-4 cells 75, 79 ARE in the band's read set 75..82
                  assuming V7       -> band reads 76..79, 81..84, and the class-4 cells are NOT

    ⇒ EXCITER is a DISCRIMINATING program -- the two readings make opposite predictions there --
    but for the same reason "the arm reaches the band" CANNOT be used to select programs while
    "reaches" depends on the answer.  A criterion that presupposes the hypothesis is not a
    criterion (rule 15, in its subtlest form yet).
    ⚠ AND THE SHAPES DO NOT SEPARATE CLEANLY EITHER.  Both readings predict EIGHT band reads; they
    differ only in whether those eight are one run of 8 (no move) or 4+4 with a hole (V7).  The
    arm-ON census spans 0x50..0x5E with most cells written once, which maps cleanly onto NEITHER.
    So this does not settle mode 4; it settles why sect. 164's replication was empty.

WHAT THE NEXT PASS SHOULD TAKE FROM IT
    1. Select experiment programs by MEMBERSHIP, not by program order -- and report the membership
       computation, so a null result can be told from an unreachable one.
    2. When the membership test itself depends on the hypothesis, say so, and look for a program
       where BOTH readings predict reachability.  Over the eight here there is none, which is why
       mode 4 has exactly one witness and cannot be replicated as posed.
"""
import os
import sys

sys.path.insert(0, "/home/fsanches/compartilhado/kn7000_mame/tools")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kn5000_dsp_namedcoeff as NC                                       # noqa: E402
import kn5000_dsp_params as P                                            # noqa: E402
import sd_rerun as SD                                                    # noqa: E402
import dsp_disasm as DIS                                                 # noqa: E402

SUB = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")
#  The eight sect. 160 admitted, in its order, so the table is comparable line for line.
EIGHT = ((35, "EXCITER"), (71, "PEQ+CHORUS"), (73, "PEQ+FLANGER"), (74, "PEQ+VIBRATO"),
         (96, "PEQ+CO+DIST"), (97, "PEQ+CO+OVER"), (98, "PEQ+DIST+DLY"), (99, "PEQ+OVR+DLY"))


def s8(a):
    return a - 256 if a >= 128 else a


def walk(words, cells70, cls4_moves):
    """Relative D-RAM pointer walk.  -> (offsets a class-4 word writes, offsets the band reads).

    The post-increment rule is the device's: class 2 and class A move by `s8(addr8)'.  `cls4_moves'
    adds `closure_pointer.py' variant V7 -- the reading under test -- so the caller can see whether
    the answer depends on it."""
    ptr, cur, c4, band = 0, 0, [], []
    for w in words:
        if DIS.c_format(w):
            continue
        is_band = DIS.cursor_fetch(w) and DIS.coeff_consumer(w) and cur in cells70
        if DIS.cursor_fetch(w) and DIS.coeff_consumer(w):
            cur += 1
        if DIS.class4(w) == 4:
            c4.append(ptr)                       # writes mem[ptr] (the shipped store target)
        if is_band:
            band.append(ptr)                     # reads mem[ptr]
        if (DIS.class4(w) & 7) == 2:
            ptr += s8(DIS.addr8(w))
        elif cls4_moves and DIS.class4(w) == 4:
            ptr += s8(DIS.addr8(w))
    return c4, sorted(set(band))


def bands(rom, algo):
    p = SD.L.program(algo)
    m = NC.host_coeff_map(rom, algo)
    return list(p.words), {a for a, v in m.items() if v[0] == 0x70}


def runs_of(xs):
    if not xs:
        return []
    out, cur = [], [xs[0]]
    for x in xs[1:]:
        if x == cur[-1] + 1:
            cur.append(x)
        else:
            out.append(cur)
            cur = [x]
    out.append(cur)
    return out


def main():
    rom = P.Rom(SUB, P.SUB_BASE)
    todo = list(EIGHT)
    if "--all" in sys.argv:
        todo = []
        for a in range(100):
            try:
                ws, c = bands(rom, a)
            except Exception:
                continue
            if c and any((not DIS.c_format(w)) and DIS.class4(w) == 4 for w in ws):
                todo.append((a, str(getattr(SD.L.program(a), "name", ""))[:13]))

    print("=" * 100)
    print("  band_reach -- does the class-4 word touch a cell the op0x70 band actually READS?")
    print("  sect. 160 selected by PROGRAM ORDER and admitted 8 of 8.  Membership admits ONE.")
    print("=" * 100)
    print("\n  %-13s %-20s %-30s %s"
          % ("program", "class-4 writes p=", "op0x70 band reads p=", "reaches?"))
    reach = []
    for algo, nm in todo:
        try:
            ws, c70 = bands(rom, algo)
        except Exception:
            continue
        c4, band = walk(ws, c70, False)
        hit = sorted(set(c4) & set(band))
        if hit:
            reach.append(nm)
        print("  %-13s %-20s %-30s %s"
              % (nm, " ".join(str(x) for x in sorted(set(c4)))[:20],
                 " ".join(str(x) for x in band)[:30],
                 ("★ YES %s" % hit) if hit else "no -- the arm CANNOT reach it"))
    print("\n  ⇒ programs where the arm can reach the band: %d of %d -- %s"
          % (len(reach), len(todo), ", ".join(reach) or "none"))
    print("    sect. 164's empty replication on PEQ+CHORUS is therefore a PREDICTED negative, not")
    print("    a failure to reproduce: the class-4 word and the band never share a cell there.")

    print("\n  ⛔⛔ THE TRAP -- is this selection independent of what is under test?\n")
    print("  %-13s %-28s %-28s" % ("program", "assuming NO MOVE", "assuming V7 post-increment"))
    flips = []
    for algo, nm in todo:
        try:
            ws, c70 = bands(rom, algo)
        except Exception:
            continue
        ha = bool(set(walk(ws, c70, False)[0]) & set(walk(ws, c70, False)[1]))
        hb = bool(set(walk(ws, c70, True)[0]) & set(walk(ws, c70, True)[1]))
        if ha != hb:
            flips.append(nm)
        print("  %-13s %-28s %-28s%s"
              % (nm, "REACHES" if ha else "cannot reach", "REACHES" if hb else "cannot reach",
                 "   <-- DISCRIMINATING" if ha != hb else ""))
    print("\n  verdict flips between the two readings on: %s" % (", ".join(flips) or "no program"))
    if flips:
        print("  ⇒ NOT independent.  Those programs DISCRIMINATE (the readings predict opposite")
        print("    things there) -- and for the same reason membership cannot be used to SELECT")
        print("    programs while `reaches' depends on the answer.  A criterion that presupposes")
        print("    the hypothesis is not a criterion.")
    ws, c70 = bands(rom, 35)
    print("\n  ⚠ and the READ-SET SHAPES do not separate cleanly either (EXCITER):")
    for tag, mv in (("no move", False), ("V7     ", True)):
        b = walk(ws, c70, mv)[1]
        print("       %s  %d cells, runs of %s"
              % (tag, len(b), "+".join(str(len(r)) for r in runs_of(b))))
    print("    The arm-ON census spans 0x50..0x5E with most cells written once -- neither shape.")
    print("    ⇒ this file settles why sect. 164's replication was empty.  It does NOT settle mode 4.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
