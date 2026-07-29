#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""src02.py -- NEC uPD6383GF (SX-KN5000 IC311): WHAT IS OPERAND SOURCE 0x02?

§99 named this: iw72 `000.1.06.087' carries SRC 0x02, our core evaluates it as 0,
and that zeroes the unit-0 output level every frame.  output-stage-decode.md item J
states the hypothesis to beat:

    "SRC 0x02, undecoded, might carry the level itself and make the write an
     identity."

i.e. SRC 0x02 = reg[addr8], the MODE-1 addressed register -- the register-file
counterpart of SRC 0x07 = mem[ptr], which is the mode-2 memory operand.

    python3 dsp/tools/src02.py [sections]

Sections
    census      every SRC code in the corpus, with its class4 profile
    modes       ★ THE TEST: is SRC 0x02 mode-locked the way 0x07 is?
    sites       every SRC 0x02 / 0x03 word, in context
    identity    do the SRC-0x02 words' addr8 match a cell the HOST writes?
"""
import argparse
import collections
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

# the anchored operand-source codes (upd6383d.h)
SRC_NAME = {0x07: "mem[ptr]", 0x10: "acc", 0x11: "ACCB?", 0x19: "tempA",
            0x1a: "tempB", 0x0b: "delayRAM", 0x08: "LFO?", 0x1c: "LFO?"}


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def c_format(w):
    return (((w >> 24) & 0xFFF) & 0xF00) == 0xC00


def lo_src(w):
    return (w >> 6) & 0x1F


def lo_act(w):
    return w & 0x1F


def lo_ptrmode(w):
    return (w >> 5) & 1


def mode(w):
    return 2 if c_format(w) else (((w >> 20) & 0xF) & 7)


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


def allwords(header, epilogue, images):
    """(label, index, word) over the whole corpus."""
    for i, w in enumerate(header):
        yield ("header", i, w)
    for i, w in enumerate(epilogue):
        yield ("outstage", 60 + i, w)
    for r, _a, ws in images:
        for i, w in enumerate(ws):
            yield ("algo%d" % r, i, w)


def sec_census(header, epilogue, images):
    print("=" * 74)
    print("CENSUS -- every operand-source code, with its addressing-mode profile")
    print("=" * 74)
    n = collections.Counter()
    bymode = collections.defaultdict(collections.Counter)
    for _l, _i, w in allwords(header, epilogue, images):
        if c_format(w) or lo_ptrmode(w):
            continue          # no ALU operand route on these
        s = lo_src(w)
        n[s] += 1
        bymode[s][mode(w)] += 1
    print("\n   SRC  count  name          mode-0  mode-1  mode-2  mode-3+")
    print("   ---  -----  ------------  ------  ------  ------  -------")
    for s in sorted(n):
        m = bymode[s]
        m3 = sum(v for k, v in m.items() if k >= 3)
        print("   %02X   %5d  %-12s  %6d  %6d  %6d  %7d"
              % (s, n[s], SRC_NAME.get(s, ""), m[0], m[1], m[2], m3))
    print()
    return n, bymode


def sec_modes(header, epilogue, images):
    print("=" * 74)
    print("MODES -- ★ THE TEST.  Is SRC 0x02 mode-locked the way 0x07 is?")
    print("=" * 74)
    print("""
  The hypothesis (item J): SRC 0x02 = reg[addr8], the MODE-1 addressed register,
  as SRC 0x07 = mem[ptr] is the MODE-2 pointer operand.

  If that is right, SRC 0x02 should occur ONLY on mode-1 words -- naming a
  register makes no sense on a word that has no register address.  This test
  CAN fail: a single mode-2 SRC-0x02 word refutes it.
""")
    rows = []
    for s in (0x02, 0x03, 0x07):
        m = collections.Counter()
        for _l, _i, w in allwords(header, epilogue, images):
            if c_format(w) or lo_ptrmode(w) or lo_src(w) != s:
                continue
            m[mode(w)] += 1
        tot = sum(m.values())
        rows.append((s, tot, m))
    print("   SRC  total   mode-1   mode-2   other   verdict")
    print("   ---  -----   ------   ------   -----   -----------------------------")
    for s, tot, m in rows:
        other = tot - m[1] - m[2]
        if tot == 0:
            v = "absent from the corpus"
        elif m[1] == tot:
            v = "★ MODE-1 LOCKED (%d of %d)" % (tot, tot)
        elif m[2] == tot:
            v = "MODE-2 LOCKED (%d of %d)" % (tot, tot)
        else:
            v = "MIXED -- not mode-locked"
        print("   %02X   %5d   %6d   %6d   %5d   %s" % (s, tot, m[1], m[2], other, v))
    print()
    return rows


def sec_sites(header, epilogue, images):
    print("=" * 74)
    print("SITES -- every SRC 0x02 / 0x03 word in the corpus, in context")
    print("=" * 74)
    print("\n   where       iw    word         hi12 c a8 lo12  mode act  addr8")
    print("   ----------  ----  ----------   ---- - -- ----  ---- ---  -----")
    seen = collections.Counter()
    for l, i, w in allwords(header, epilogue, images):
        if c_format(w) or lo_ptrmode(w) or lo_src(w) not in (0x02, 0x03):
            continue
        hi, c, a, lo = fields(w)
        key = w
        seen[key] += 1
        if seen[key] > 1 and l.startswith("algo"):
            continue        # one line per distinct word per body image
        print("   %-10s  %-4d  %010X   %03X  %X %02X %03X   %d   %02X   %02X"
              % (l, i, w, hi, c, a, lo, mode(w), lo_act(w), a))
    print()


def sec_identity(header, epilogue, images):
    print("=" * 74)
    print("IDENTITY -- do the SRC-0x02 words address cells the HOST writes?")
    print("=" * 74)
    # register-space.md C2 / 5.1: the host-primed mode-1 cells and the never-primed ones
    HOST_PRIMED = {0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0e,
                   0x10, 0x11, 0x12, 0x13, 0x14, 0x16, 0x1b,
                   0x85, 0x86, 0x87, 0x8a, 0x8b, 0x94, 0xd0, 0xd1, 0xd2}
    NEVER_PRIMED = {0x0f, 0x8c, 0x8d, 0x8f}
    print("""
  If SRC 0x02 reads the addressed REGISTER, the cells it names should be cells
  that HOLD something -- i.e. host-primed parameters -- rather than the
  never-initialised port-like cells C2 identified.
""")
    hit = miss = port = 0
    cells = collections.Counter()
    for _l, _i, w in allwords(header, epilogue, images):
        if c_format(w) or lo_ptrmode(w) or lo_src(w) != 0x02 or mode(w) != 1:
            continue
        a = (w >> 12) & 0xFF
        cells[a] += 1
        if a in HOST_PRIMED:
            hit += 1
        elif a in NEVER_PRIMED:
            port += 1
        else:
            miss += 1
    tot = hit + miss + port
    print("   cells named: %s" % " ".join("%02X:%d" % (c, n) for c, n in sorted(cells.items())))
    print("   host-primed %d, never-primed(port-like) %d, neither %d, of %d"
          % (hit, port, miss, tot))
    if tot:
        print("   -> %.0f%% of SRC-0x02 mode-1 words name a cell the host primes"
              % (100.0 * hit / tot))
    print()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*",
                    default=["census", "modes", "sites", "identity"])
    ap.add_argument("--sub", default="original_ROMs/kn5000_subprogram_v142.rom")
    ap.add_argument("--tools", default="../kn7000_mame/tools")
    a = ap.parse_args()
    h, e, im = load_corpus(a.sub, a.tools)
    print("corpus: header %d + epilogue %d + %d body images\n" % (len(h), len(e), len(im)))
    if "census" in a.sections:
        sec_census(h, e, im)
    if "modes" in a.sections:
        sec_modes(h, e, im)
    if "sites" in a.sections:
        sec_sites(h, e, im)
    if "identity" in a.sections:
        sec_identity(h, e, im)


if __name__ == "__main__":
    main()
