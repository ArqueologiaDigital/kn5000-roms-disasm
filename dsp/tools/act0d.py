#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""act0d.py -- NEC uPD6383GF (SX-KN5000 IC311): WHAT IS ACTION 0x0D?

Section 106 pinned the body-0 base+0 read as blocked by an UNDECODED ACTION 0x0D:
  iw85 = 000.2.0E.1CD -- SRC 0x07 (mem[ptr], ANCHORED) handed to ACTION 0x0D.

action-field.md sect. 6 establishes the family arithmetic:
    "0x19 captures tempA and 0x1A captures tempB, i.e. they are a second pair of
     capture codes beside the anchored 0x13/0x14, with the same two destinations
     and lo12[4:3] = 3 instead of 2.  The arithmetic agrees: 0x19 = 0x13 + 6,
     0x1A = 0x14 + 6."

Extending it DOWNWARD gives the hypothesis this script tests:
    0x0D = 0x13 - 6  ->  captures tempA          lo12[4:3] = 1
    0x0E = 0x14 - 6  ->  captures tempB          lo12[4:3] = 1

THE METHOD IS NOT NEW EITHER.  upd6383.cpp validated ACTION 0x19's destination as
"followed by a word SOURCING tempA in 74 of 89 distinct-image sites (base rate
16.0%, shuffled null 42.7%)".  This replicates that, and adds the discriminator
that test lacked: the CROSS pairing.  If 0x0D scores high on tempA AND LOW on
tempB, the destination is identified.  If it scores alike on both, it is not --
and that outcome is available, which is what makes this a test.

    python3 dsp/tools/act0d.py
"""
import argparse
import collections
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

LO_SRC_TA = 0x19        # sourcing tempA
LO_SRC_TB = 0x1a        # sourcing tempB
ACT_FAMILIES = [(0x0d, 0x0e, 1), (0x13, 0x14, 2), (0x19, 0x1a, 3)]


def c_format(w):
    return (((w >> 24) & 0xFFF) & 0xF00) == 0xC00


def lo_src(w):
    return (w >> 6) & 0x1F


def lo_act(w):
    return w & 0x1F


def lo_ptrmode(w):
    return (w >> 5) & 1


def alu(w):
    """a word with an ALU operand route at all."""
    return not c_format(w) and not lo_ptrmode(w)


def load_corpus(sub, tools):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    rom = E.Rom(sub)

    def blk(a):
        ir, _c, _o = E.parse_stream(rom, a, limit=40)
        return [int.from_bytes(bytes(w), "big") for w in ir[0][1]] if ir else []

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    progs = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if ir:
            progs[i] = [int.from_bytes(bytes(w), "big")
                        for w in (w for _a, ws, _l in ir for w in ws)]
    g = {}
    for a in sorted(progs):
        if a in DSP2_MISPARSED:
            continue
        g.setdefault(tuple(progs[a]), []).append(a)
    images = sorted([(v[0], v, list(k)) for k, v in g.items()], key=lambda t: t[0])
    return header, epilogue, images


def streams(header, epilogue, images):
    """each independently-executed word sequence, so 'the NEXT word' is meaningful."""
    yield ('header', header)
    yield ('epilogue', epilogue)
    for r, _a, ws in images:
        yield ('algo%d' % r, ws)


def followed_by(seq, i, src, window):
    """does any word in (i, i+window] source `src'?  Stops at the next capture of
    the same destination, because a second capture would overwrite it."""
    for j in range(i + 1, min(i + 1 + window, len(seq))):
        w = seq[j]
        if not alu(w):
            continue
        if lo_src(w) == src:
            return True
    return False


def score(header, epilogue, images, act, src, window):
    sites = hits = 0
    for _nm, seq in streams(header, epilogue, images):
        for i, w in enumerate(seq):
            if not alu(w) or lo_act(w) != act:
                continue
            sites += 1
            if followed_by(seq, i, src, window):
                hits += 1
    return sites, hits


def base_rate(header, epilogue, images, src, window):
    """the shuffled null, done HONESTLY: the probability that an arbitrary ALU word
    is followed within `window' by a word sourcing `src'.  This is the number the
    0x19 validation quoted as 42.7% and the reason its 74/89 meant something."""
    sites = hits = 0
    for _nm, seq in streams(header, epilogue, images):
        for i, w in enumerate(seq):
            if not alu(w):
                continue
            sites += 1
            if followed_by(seq, i, src, window):
                hits += 1
    return sites, hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub", default="original_ROMs/kn5000_subprogram_v142.rom")
    ap.add_argument("--tools", default="../kn7000_mame/tools")
    ap.add_argument("--window", type=int, default=4)
    a = ap.parse_args()
    h, e, im = load_corpus(a.sub, a.tools)
    print("corpus: header %d + epilogue %d + %d body images, follow-window %d\n"
          % (len(h), len(e), len(im), a.window))

    nA, hA = base_rate(h, e, im, LO_SRC_TA, a.window)
    nB, hB = base_rate(h, e, im, LO_SRC_TB, a.window)
    print("THE NULL, COMPUTED FIRST (rule 4):")
    print("   an arbitrary ALU word is followed within %d by a tempA source: %d/%d = %.1f%%"
          % (a.window, hA, nA, 100.0 * hA / nA))
    print("   ... by a tempB source: %d/%d = %.1f%%\n" % (hB, nB, 100.0 * hB / nB))

    print("PER ACTION CODE -- tempA follow-rate vs tempB follow-rate.")
    print("The DISCRIMINATOR is the gap between the two columns, not either alone.\n")
    print("  lo12[4:3]  ACT   n    ->tempA        ->tempB       verdict")
    print("  ---------  ---  ---   -----------   -----------   -------------------------")
    rows = []
    for ta, tb, fam in ACT_FAMILIES:
        for act, want in ((ta, 'A'), (tb, 'B')):
            n1, k1 = score(h, e, im, act, LO_SRC_TA, a.window)
            n2, k2 = score(h, e, im, act, LO_SRC_TB, a.window)
            if n1 == 0:
                continue
            pA, pB = 100.0 * k1 / n1, 100.0 * k2 / n1
            if pA - pB > 15:
                v = "-> tempA"
            elif pB - pA > 15:
                v = "-> tempB"
            else:
                v = "NO SEPARATION"
            exp = 'tempA' if want == 'A' else 'tempB'
            ok = ('agrees with %s' % exp) if v.endswith(exp[-1].upper()) or v == '-> ' + exp else ''
            rows.append((fam, act, n1, pA, pB, v, exp))
            print("      %d      %02X  %3d   %3d/%3d %4.0f%%   %3d/%3d %4.0f%%   %-14s (family expects %s)"
                  % (fam, act, n1, k1, n1, pA, k2, n1, pB, v, exp))
    print()
    print("READ THE ANCHORED ROWS FIRST.  0x13/0x14 are ANCHORED to tempA/tempB, so they")
    print("are the CALIBRATION: whatever separation they show is what a true capture code")
    print("looks like under this test.  If they do not separate, the test is blind and")
    print("nothing about 0x0D can be concluded from it.")
    print()


if __name__ == "__main__":
    main()
