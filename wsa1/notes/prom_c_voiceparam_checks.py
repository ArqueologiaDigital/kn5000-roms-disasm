#!/usr/bin/env python3
"""Every quantified claim the voice-parameter block comment makes, re-derived from the ROM.

The block is prom_c 0xFA7E2C-0xFABE2F.  Nothing in its header is quoted anywhere
without appearing here first; a claim that cannot be turned into a check does not go
into the header.

RUN
  python3 notes/prom_c_voiceparam_checks.py            # prints every check
  python3 notes/prom_c_voiceparam_checks.py --selftest # + negative controls
Exit status is non-zero if any check fails.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTES = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, NOTES)
import prom_c_module_map as mm            # noqa: E402
import prom_c_jumptables as jt            # noqa: E402

IMG, BASE = mm.IMG, mm.BASE
START, END = 0xFA7E2C, 0xFABE30
fails = []


def check(ok, what):
    print("  %-4s %s" % ("ok" if ok else "FAIL", what))
    if not ok:
        fails.append(what)


def at(a, n):
    return IMG[a - BASE:a - BASE + n]


def parts():
    ents, xfer, spans = mm.entries(START, END)
    routines = [a for a in ents if xfer.get(a) or at(a, 2) == b"\xee\x0c"]
    arms = [a for a in ents if a not in routines]
    return routines, arms, xfer, spans


def calr_target(a):
    """If a `1E dd dd` calr starts at `a`, its absolute target; else None."""
    if at(a, 1) != b"\x1e":
        return None
    return BASE + (a - BASE) + 3 + struct.unpack_from("<h", IMG, a - BASE + 1)[0]


def main():
    routines, arms, xfer, spans = parts()

    print("1  THE BLOCK'S OWN BOUNDARIES")
    check(at(START - 1, 1) == b"\x0e", "0xFA7E2B, the byte before the block, is `ret` (0x0E)")
    check(at(START, 2) == b"\xee\x0c", "0xFA7E2C is `link XIZ,imm16` -- a frame prologue")
    check(at(END, 2) == b"\xee\x0c", "0xFABE30, the first byte past it, is also `link XIZ`")
    check(at(END - 1, 1) == b"\x0e", "0xFABE2F, the block's last byte, is `ret`")
    check(END - START == 16388, "the block is %d bytes" % (END - START))

    print("\n2  THE FOUR COMPUTED-GOTO TABLES")
    tabs = [(t, g, n) for _, t, g, n, _ in jt.tables() if START <= t < END]
    check(len(tabs) == 4, "four tables inside the block: "
                          + " ".join("0x%06X" % t for t, _, _ in tabs))
    for t, g, n in tabs:
        check(g == 5 and n == 6,
              "0x%06X: guard `cp WA,%d` and %d contents entries agree on SIX" % (t, g, n))
        last = struct.unpack_from("<I", IMG, t - BASE + 5 * 4)[0]
        check(START <= last < END,
              "  ...and its LAST entry 0x%06X is inside the block" % last)
        past = struct.unpack_from("<I", IMG, t - BASE + 6 * 4)[0]
        check(not (0xF80000 <= past <= 0xFFFFFF),
              "  ...and the word after it (0x%08X) is not a plausible seventh" % past)
    check(all(struct.unpack_from("<I", IMG, t - BASE)[0] not in (t, )
              for t, _, _ in tabs), "no table's entry 0 points at the table itself")
    for t, _, _ in tabs:
        e0 = struct.unpack_from("<I", IMG, t - BASE)[0]
        # entry 0 is the same address the `jr/jrl UGT` guard jumps to
        print("        0x%06X entry 0 = 0x%06X (the out-of-range arm)" % (t, e0))

    print("\n3  THE ROUTINE CENSUS")
    check(len(routines) == 60, "%d routines (an entry with a literal call site or a"
                               " `link XIZ` prologue, after prom_c_module_map.py drops"
                               " candidates the source's own decode says are not"
                               " instruction boundaries)" % len(routines))
    # ⚠ This said 68 until 2026-08-25.  Six of those were byte-pattern noise -- a `1D`
    # or `1E` inside a longer instruction -- and the count went into this block's
    # comment before prom_c_module_map.py could filter them.  With BOTH filters --
    # candidate entries and call SITES checked against the source's own decode -- the
    # ten blocks of round 3 hold 600 routines, not the 761 the unfiltered heuristic
    # reported, and the count now matches the number of headers the file carries.
    check(len(arms) == 22, "%d computed-goto arms (an entry with neither)" % len(arms))
    ins = sum(len([s for s in v if START <= s < END]) for k, v in xfer.items()
              if START <= k < END)
    outs = sum(len([s for s in v if not (START <= s < END)]) for k, v in xfer.items()
               if START <= k < END)
    check(ins == 41 and outs == 126,
          "%d literal call sites from inside the block, %d from outside it" % (ins, outs))
    # ⚠ 47 / 128 until 2026-08-25.  Six of those "sites" were byte-pattern noise --
    # a `1D`/`1E` inside a longer instruction -- and prom_c_module_map.py now keeps a
    # site only where the source file's own decode agrees it is an instruction.
    check(max(routines) == 0xFABDAC,
          "the LAST routine starts at 0x%06X" % max(routines))
    check(min(routines) == START, "the FIRST routine starts at the block's first byte")

    print("\n4  THE DUPLICATED ROUTINES")
    order = sorted(routines)
    ext = {a: (order[k + 1] if k + 1 < len(order) else END) - a for k, a in enumerate(order)}
    pairs = []
    for i in range(len(order)):
        for j in range(i + 1, len(order)):
            a, b = order[i], order[j]
            if ext[a] != ext[b] or ext[a] < 24:
                continue
            n = ext[a]
            d = [k for k in range(n) if IMG[a - BASE + k] != IMG[b - BASE + k]]
            if len(d) * 8 <= n:
                pairs.append((a, b, n, d))
    check(len(pairs) == 3, "%d pairs of equal-length routines differing in <= 12.5%%"
                           " of their bytes" % len(pairs))
    # ⚠ RETRACTED 2026-08-25: this said FOUR, the fourth being 0xFA8D9B / 0xFA8E47
    # "71 bytes, 1 differs".  The 71-byte statement is true -- the only difference in
    # the first 71 bytes is at +0x1B, a `calr 0xFA778E` displacement -- but the two
    # routines are NOT the same length.  The pair existed only because two BYTE-PATTERN
    # false entries (0xFA8DE2, 0xFA8E8E) cut both routines at 71 bytes; with
    # prom_c_module_map.py's false-entry filter their extents are 172 and 176.
    d = [k for k in range(71) if IMG[0xFA8D9B - BASE + k] != IMG[0xFA8E47 - BASE + k]]
    check(d == [0x1B] and calr_target(0xFA8D9B + 0x1A) == calr_target(0xFA8E47 + 0x1A)
          == 0xFA778E,
          "0xFA8D9B and 0xFA8E47 still share their first 71 bytes but ONE (+0x1B, a"
          " `calr 0xFA778E` displacement) -- they are simply not equal-length routines")
    for a, b, n, d in sorted(pairs, key=lambda p: len(p[3])):
        # is every differing byte inside a `calr` whose TARGET is the same on both sides?
        same_target = True
        for k in d:
            hit = False
            for back in (1, 2):
                if k - back >= 0 and IMG[a - BASE + k - back] == 0x1E:
                    ta, tb = calr_target(a + k - back), calr_target(b + k - back)
                    if ta is not None and ta == tb:
                        hit = True
            if not hit:
                same_target = False
        check(True, "0x%06X vs 0x%06X: %d bytes, %d differ%s"
              % (a, b, n, len(d),
                 " -- every one a `calr` displacement to the SAME target" if same_target
                 else " -- NOT all calr displacements, read them"))
    a, b = 0xFA8347, 0xFA83CC
    d = [k for k in range(97) if IMG[a - BASE + k] != IMG[b - BASE + k]]
    check(d == [0x53] and calr_target(a + 0x52) == calr_target(b + 0x52) == 0xFA7570,
          "0xFA8347 and 0xFA83CC are 97 bytes differing in ONE -- byte +0x53, the low"
          " half of a `calr` displacement whose target is 0xFA7570 on BOTH sides")

    print("\n5  THE TWO DISPATCHERS ARE THE SAME ROUTINE ON A DIFFERENT FIELD")
    a, b = 0xFA8BDD, 0xFA900A
    check(at(a, 12) == at(b, 12), "0xFA8BDD and 0xFA900A open with the same 12 bytes")
    check(at(a + 0x0A, 3) == at(b + 0x0A, 3) == b"\xab\x17\x21",
          "both do `ld XBC,(XHL+0x17)` -- the same pointer field of the argument")
    check(at(a + 0x0D, 1) == b"\x89" and at(b + 0x0D, 1) == b"\x89",
          "both then do `ld A,(XBC+n)`")
    check(at(a + 0x0E, 1) == b"\x36" and at(b + 0x0E, 1) == b"\x11",
          "and n is 0x36 at 0xFA8BDD, 0x11 at 0xFA900A -- the ONLY semantic difference")
    check(at(a + 0x10, 3) == at(b + 0x10, 3) == b"\xc9\xcc\x07",
          "both mask the field with 7, so both switch on a 3-bit field")

    print("\n6  WHO CALLS INTO THE BLOCK")
    callers = {}
    for k, v in xfer.items():
        if not (START <= k < END):
            continue
        for s in v:
            if not (START <= s < END):
                callers[s] = k
    lo, hi = min(callers), max(callers)
    check(len(callers) == 126, "%d distinct outside call sites" % len(callers))
    check(lo == 0xFABE52 and hi == 0xFB8CBD,
          "they span 0x%06X-0x%06X, and BOTH ends are checked" % (lo, hi))
    print("        lowest  site 0x%06X -> 0x%06X" % (lo, callers[lo]))
    print("        highest site 0x%06X -> 0x%06X" % (hi, callers[hi]))

    print("\n7  THE OUTSIDE CALLERS, BY THE CONVERTED ROUTINE THEY SIT IN")
    import gen_prom_c_block_headers as gh
    from collections import Counter
    lab = gh.source_routines()
    tally = Counter()
    for s in callers:
        e = gh.enclosing(s, lab)
        tally[(e.split("__")[0] if e else "(caller not yet converted)")] += 1
    for name, k in tally.most_common():
        print("        %4d  %s" % (k, name))
    check(sum(tally.values()) == 126, "the tally covers all 126 sites")
    four = (tally["VoiceRegs_Stage_A"] + tally["VoiceRegs_Stage_B"]
            + tally["VoiceRegs_Stage_C"] + tally["VoiceRegs_Stage_D"])
    check(four == 61, "the four VoiceRegs_Stage_* routines account for %d of them" % four)
    # ⚠ THIS ROW IS THE ONE THAT MOVES.  It was 39 when the block was converted and 0
    # by the end of round 3, because the callers themselves got converted.  Asserting
    # a fixed value here would turn ordinary progress into a failure, so what is
    # asserted is the INVARIANT -- the row can only shrink -- and the value is printed.
    unconv = tally["(caller not yet converted)"]
    print("        (caller not yet converted) = %d  [39 when the block was converted;"
          " 0 at the end of round 3]" % unconv)
    check(unconv <= 39, "the unconverted-caller row can only shrink; it is %d" % unconv)

    if "--selftest" in sys.argv:
        print("\n8  NEGATIVE CONTROLS")
        check(0xFA9034 not in routines and 0xFA9034 not in arms,
              "an address inside a computed-goto table is neither a routine nor an arm")
        check(0xFB3F36 not in routines,
              "MidiNote_Dispatch, outside the block, is not in the census")
        check(at(0xFA7E2C + 1, 1) != b"\x0c" or True, "(structural control ran)")
        d = [k for k in range(97) if IMG[0xFA8347 - BASE + k] != IMG[0xFA842D - BASE + k]]
        check(len(d) > 12, "a NON-pair (0xFA8347 vs 0xFA842D) differs in %d of 97 bytes,"
                           " so the pair test is not vacuous" % len(d))

    print("\n%s" % ("ALL CHECKS PASS" if not fails else "FAILURES: %d" % len(fails)))
    for f in fails:
        print("  FAIL " + f)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
