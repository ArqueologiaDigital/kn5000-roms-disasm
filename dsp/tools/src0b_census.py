#!/usr/bin/env python3
"""§218 -- the class-2 `SRC 0x0B' census, and the per-frame delay schedule.

WHY THIS EXISTS.  §217 sect.5 re-did in prose a census the device source already
carried (`upd6383.cpp' at `case 0x0B': "Of 106 corpus SRC 0x0B words, 99 are
class-1 delay words and 7 are class 2"), got **9** instead of 7, and built its
"honest residue" on the two extra words.  They are `000.2.00.40B' (ENSEMBLE w62)
and `000.2.09.40B' (MULTI TAP w25), whose `lo12 = 0x40B' carries

    SRC = lo12[10:6] = 0x10   the ACCUMULATOR (anchored)
    ACT = lo12[4:0]  = 0x0B   the open action code

-- i.e. the `0B' is the ACTION field, not the SOURCE field.  ⇒ NEVER group words
by the `lo12' string: eleven distinct lo12 values occur on BOTH class-1 delay
words and class-2 words (see `pairs'), and the kernel's own iw26 is
`880.1.20.40B', a class-1 delay READ sharing w62's lo12.

Everything §218 states about the corpus comes out of this file.

    python3 dsp/tools/src0b_census.py            # all of it
    python3 dsp/tools/src0b_census.py census     # 1  the 7 class-2 SRC 0x0B words + neighbours
    python3 dsp/tools/src0b_census.py act0b      # 2  the ACT 0x0B population it was confused with
    python3 dsp/tools/src0b_census.py pairs      # 3  lo12 values that span class-1 and class-2
    python3 dsp/tools/src0b_census.py schedule   # 4 ★ the 42-word per-frame delay schedule
    python3 dsp/tools/src0b_census.py heads      # 5  the 212.2.xx.00B program-head idiom
"""
import os
import re
import sys
import collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                          # noqa: E402

DIS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'disasm')
WRE = re.compile(r"^\s*w(\d+)\s+([0-9A-F]{10})\s")

#  the cold-boot residency, MEASURED: §204's guarded census places body 0's delay
#  words at iw93..iw152 and body 1's at iw200.., and the unique corpus programs
#  whose delay offsets land there are CHORUS at I-RAM 84 and ROOM REVERB 1 at 200
#  (§190 identified the latter by its 16-word fingerprint).
RESIDENT = [('kernel.dsm', 0), ('prog01_chorus.dsm', 84), ('prog16_room_reverb_1.dsm', 200)]


def words(prog):
    p = os.path.join(DIS, prog)
    return [(int(m.group(1)), int(m.group(2), 16))
            for m in (WRE.match(ln) for ln in open(p)) if m]


def programs():
    return [p for p in sorted(os.listdir(DIS)) if p.endswith('.dsm')]


def field(w):
    return "%03X.%X.%02X.%03X" % (D.hi12(w), D.class4(w), D.addr8(w), w & 0xFFF)


def dram(prog, base=0):
    """[(index, 'READ'|'WRITE'|'?')] -- the program's external delay-DRAM words."""
    return [(base + i, D.dram_dir(w) or '?') for i, w in words(prog) if D.is_dram(w)]


# --------------------------------------------------------------------------
def census():
    """1 -- every class-2 SRC 0x0B word, with the delay READ on each side."""
    rows, tot = [], 0
    for prog in programs():
        dr = dram(prog)
        for i, w in words(prog):
            tot += 1
            if D.c_format(w) or D.class4(w) != 2 or D.lo_src(w) != 0x0B:
                continue
            pr = [k for k, d in dr if k < i and d == 'READ']
            nx = [k for k, d in dr if k > i and d == 'READ']
            rows.append((prog[:-4], i, field(w), pr[-1] if pr else None,
                         nx[0] if nx else None))
    print("1) CLASS-2 `SRC 0x0B' WORDS -- %d over %d corpus words in %d listings"
          % (len(rows), tot, len(programs())))
    print("   (`upd6383.cpp' case 0x0B has said 7 since §215; §217 sect.5's `9' was a field mix-up)")
    for name, i, f, pr, nx in rows:
        print("   %-24s w%-3d %-14s prevREAD %-6s (%+3d)   nextREAD %-6s (%s)"
              % (name, i, f, "w%d" % pr if pr is not None else "--",
                 (i - pr) if pr is not None else 0,
                 "w%d" % nx if nx is not None else "NONE",
                 ("%+d" % (nx - i)) if nx is not None else " -- "))
    print("   ⇒ item A (the PRECEDING read) is uniform +4 at 6/6 ENSEMBLE sites;")
    print("     the cross-frame rival (the FOLLOWING read) is UNDEFINED at w92 and -30 at w34.")


def act0b():
    """2 -- the ACT 0x0B population, the one §217 sect.5 mistook for SRC 0x0B."""
    for name, sel in (("SRC 0x0B", D.lo_src), ("ACT 0x0B", D.lo_act)):
        c = collections.Counter()
        for prog in programs():
            for _, w in words(prog):
                if D.c_format(w) or sel(w) != 0x0B:
                    continue
                c['delay-DRAM' if D.is_dram(w) else 'class %X' % D.class4(w)] += 1
        print("%s %s: total %d  %s" % ("2)" if name.startswith("SRC") else "  ",
                                       name, sum(c.values()), dict(sorted(c.items()))))
    print("   (the ACT 0x0B 82 = 50 delay + 32 is `register-space.md' §4's published split)")
    print("   class-2 ACT 0x0B words, which are NOT delay-bus consumers:")
    for prog in programs():
        for i, w in words(prog):
            if D.c_format(w) or D.class4(w) != 2 or D.lo_act(w) != 0x0B:
                continue
            print("     %-24s w%-3d %-14s SRC %02X %s" % (prog[:-4], i, field(w), D.lo_src(w),
                  "<- the ACCUMULATOR" if D.lo_src(w) == D.LO_SRC_ACC else ""))


def pairs():
    """3 -- lo12 values that occur on BOTH a class-1 delay word and a class-2 word."""
    seen = collections.defaultdict(set)
    for prog in programs():
        for _, w in words(prog):
            if D.c_format(w):
                continue
            if D.is_dram(w):
                seen[w & 0xFFF].add('dram')
            elif D.class4(w) == 2:
                seen[w & 0xFFF].add('cls2')
    both = sorted(lo for lo, s in seen.items() if len(s) == 2)
    print("3) lo12 values spanning class-1 delay words AND class-2 words: %d" % len(both))
    for lo in both:
        print("     0x%03X   SRC %02X   ACT %02X" % (lo, (lo >> 6) & 0x1F, lo & 0x1F))
    print("   ⇒ lo12 does not determine class behaviour.  Group by the SOURCE FIELD.")


def schedule():
    """4 -- the per-frame delay-DRAM schedule of the cold-boot residency."""
    k = dict(dram('kernel.dsm'))
    b0, b1 = dram(RESIDENT[1][0], 84), dram(RESIDENT[2][0], 200)
    #  §217 P1 (from §209's m_delay_ix) places kernel iw54 BETWEEN the two bodies.
    order = [(12, k[12]), (26, k[26]), (46, k[46])] + b0 + [(54, k[54])] + b1
    nr = sum(1 for _, d in order if d == 'READ')
    print("4) PER-FRAME DELAY SCHEDULE -- kernel + CHORUS@84 (unit 0) + ROOM REVERB 1@200 (unit 1);")
    print("   epilogue has none.  %d delay words: %d READS, %d WRITES"
          % (len(order), nr, len(order) - nr))
    print("   ", " ".join("iw%d%s" % (i, d[0]) for i, d in order))
    at26 = [n for n, (i, _) in enumerate(order) if i == 26][0]
    inter = order[at26 + 1:] + [order[0]]      # rest of frame N-1, then frame N's iw12
    ir = sum(1 for _, d in inter if d == 'READ')
    print("   between iw26 (frame N-1) and iw25 (frame N): %d delay words, %d READS, %d WRITES"
          % (len(inter), ir, len(inter) - ir))
    print("   ⇒ a ONE-DEEP `m_dr' cannot carry iw26's datum across them, which is why the")
    print("     cross-frame rival is refuted; arm A measures the survivor and it is iw289.")


def heads():
    """5 -- the 212.2.xx.00B program-head idiom (SPECULATIVE)."""
    print("5) the `212.2.xx.00B' head idiom -- hi12 0x212, SRC 0x00, ACT 0x0B, class 2")
    for prog in programs():
        dr = [i for i, _ in dram(prog)]
        for i, w in words(prog):
            if D.hi12(w) == 0x212 and (w & 0xFFF) == 0x00B:
                print("     %-24s w%-3d %-14s   first delay word of program: w%s"
                      % (prog[:-4], i, field(w), dr[0] if dr else '--'))
    print("   addr8 varies freely and is a SIGNED pointer post-increment, so it is not the idiom.")


ALL = {'census': census, 'act0b': act0b, 'pairs': pairs, 'schedule': schedule, 'heads': heads}

if __name__ == '__main__':
    which = sys.argv[1:] or list(ALL)
    for n, name in enumerate(which):
        if name not in ALL:
            sys.exit("unknown section %r; pick from %s" % (name, ", ".join(ALL)))
        if n:
            print()
        ALL[name]()
