#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""mode_alias.py -- NEC uPD6383GF (SX-KN5000 IC311): DO MODE-1 `addr8' AND
MODE-2 `mem[ptr]' ADDRESS THE SAME MEMORY?

SPECULATIVE-APPLIED-REGISTER.md sect. 96 resolved the sect.71/sect.86 conflict by
observing that our core resolves BOTH routes onto one 256-cell array.  That is a
statement about the emulator.  This asks the corpus whether the CHIP does.

    python3 dsp/tools/mode_alias.py [sections]

Sections
    sets        the two address sets, corpus-wide, and their intersection
    direction   per cell: which route reads it, which route writes it
    volume      the decisive argument -- item J's forcing, extended to mode 2
    walk        the static pointer trajectory of the kernel (who writes 0x06)

SCOPE, stated in the result rather than after it: the mode-1 population here is
class4 == 1 AND NOT the format escape AND NOT c_format -- i.e. the REGISTER form,
excluding the external delay-DRAM family (`is_dram', which is class 1 WITH the
escape).  The mode-2 population is every word whose operand is LO_SRC_MEM or
whose store lands on mem[ptr].  Both are stated per region, never pooled.
"""
import argparse
import collections
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

LO_SRC_MEM = 0x07
HI_ESC = 0x800          # hi12 bit 11
HI_STORE = 0x010        # hi12 bit 4
LO_ACT_ST_BUS = 0x07


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


def is_dram(w):
    hi, c, _a, _l = fields(w)
    return bool(hi & HI_ESC) and c == 1 and not c_format(w)


def is_mode1(w):
    """the REGISTER form: class 1 without the format escape."""
    hi, c, _a, _l = fields(w)
    return c == 1 and not (hi & HI_ESC) and not c_format(w)


def ptr_postinc(w):
    return (not c_format(w)) and (((w >> 20) & 0xF) & 7) == 2


def reads_mem(w):
    return (not c_format(w)) and lo_src(w) == LO_SRC_MEM and not lo_ptrmode(w)


def writes_mem(w):
    """mode-2 store: bit-4 store, or ACTION 0x07, on a class-2 word."""
    hi, c, _a, _l = fields(w)
    if c_format(w) or (c & 7) != 2:
        return False
    return bool(hi & HI_STORE) or lo_act(w) == LO_ACT_ST_BUS


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


# --------------------------------------------------------------------------
def walk(words, base):
    """static pointer trajectory; returns [(index, word, ptr_at_access)]."""
    p = base
    out = []
    for i, w in enumerate(words):
        out.append((i, w, p))            # access uses the PRE-increment cell
        if ptr_postinc(w):
            p = (p + ((w >> 12) & 0xFF)) & 0xFF
            if p > 127 and ((w >> 12) & 0xFF) > 127:
                pass
    return out, p


def walk_signed(words, base):
    p = base
    out = []
    for i, w in enumerate(words):
        out.append((i, w, p))
        if ptr_postinc(w):
            d = (w >> 12) & 0xFF
            d = d - 256 if d > 127 else d
            p = (p + d) & 0xFF
    return out, p


# --------------------------------------------------------------------------
def sec_sets(header, epilogue, images):
    print("=" * 74)
    print("SETS -- the two address sets, per region, never pooled")
    print("=" * 74)

    # KERNEL ENTRY IS 0xFF, NOT 0x05.  The forced per-unit base 0x05 | unit<<7
    # is applied AT THE BODY CALL (upd6383.cpp:3099), not at kernel entry; the
    # core's own closure arithmetic (upd6383.cpp:3236) is
    #     0x85 - 133 - 1 = 0xFF   and   0xFF + 6 = 0x05
    # i.e. the kernel walks +6 from the frame-closure cell to arrive at the base.
    # Starting the kernel at 0x05 puts every kernel cell six too high.
    regions = [("kernel (header, iw 0..59)", header, 0xFF),
               ("epilogue (iw 60..82)", epilogue, 0x85)]

    m1_all, m2_all = collections.Counter(), collections.Counter()

    for name, words, base in regions:
        m1 = collections.Counter()
        for w in words:
            if is_mode1(w):
                m1[(w >> 12) & 0xFF] += 1
        tr, end = walk_signed(words, base)
        m2 = collections.Counter()
        for _i, w, p in tr:
            if reads_mem(w) or writes_mem(w):
                m2[p] += 1
        m1_all.update(m1)
        m2_all.update(m2)
        print("\n  %s" % name)
        print("    mode-1 cells : %s" % (" ".join("%02X" % c for c in sorted(m1)) or "(none)"))
        print("    mode-2 cells : %s" % (" ".join("%02X" % c for c in sorted(m2)) or "(none)"))
        print("    intersection : %s"
              % (" ".join("%02X" % c for c in sorted(set(m1) & set(m2))) or "(EMPTY)"))

    # the 38 body images
    bm1, bm2 = collections.Counter(), collections.Counter()
    for r, _a, ws in images:
        for w in ws:
            if is_mode1(w):
                bm1[(w >> 12) & 0xFF] += 1
        for unitbase in (0x05, 0x85):
            tr, _e = walk_signed(ws, unitbase)
            for _i, w, p in tr:
                if reads_mem(w) or writes_mem(w):
                    bm2[p] += 1
    print("\n  the 38 body images (both unit bases)")
    print("    mode-1 cells : %s" % " ".join("%02X" % c for c in sorted(bm1)))
    print("    mode-2 cells : %d distinct, %02X..%02X"
          % (len(bm2), min(bm2), max(bm2)))
    print("    intersection : %s"
          % (" ".join("%02X" % c for c in sorted(set(bm1) & set(bm2))) or "(EMPTY)"))

    m1_all.update(bm1)
    m2_all.update(bm2)
    inter = sorted(set(m1_all) & set(m2_all))
    print("\n  CORPUS TOTAL")
    print("    mode-1 : %2d distinct cells, %d words" % (len(m1_all), sum(m1_all.values())))
    print("    mode-2 : %2d distinct cells, %d accesses" % (len(m2_all), sum(m2_all.values())))
    print("    shared : %2d cells -- %s"
          % (len(inter), " ".join("%02X" % c for c in inter) or "(EMPTY)"))
    print()
    print("    >> A NUMERIC INTERSECTION IS NOT AN ALIAS.  Both routes index with")
    print("       8 bits, so index collisions are expected whether or not the two")
    print("       spaces are the same memory.  See section `volume'.")
    print()
    return m1_all, m2_all


def sec_direction(header, epilogue, images):
    print("=" * 74)
    print("DIRECTION -- per cell, which route READS it and which route WRITES it")
    print("=" * 74)
    rd1 = collections.Counter(); wr1 = collections.Counter()
    rd2 = collections.Counter(); wr2 = collections.Counter()

    def scan(words, base, label):
        for w in words:
            if is_mode1(w):
                a = (w >> 12) & 0xFF
                # item J (FORCED): a mode-1 ACTION 0x07 does NOT write reg[addr8]
                if (w >> 24) & HI_STORE:
                    wr1[a] += 1
                else:
                    rd1[a] += 1
        tr, _e = walk_signed(words, base)
        for _i, w, p in tr:
            if writes_mem(w):
                wr2[p] += 1
            elif reads_mem(w):
                rd2[p] += 1

    scan(header, 0xFF, "kernel")        # see sec_sets(): kernel entry is 0xFF
    scan(epilogue, 0x85, "epilogue")
    for _r, _a, ws in images:
        for b in (0x05, 0x85):
            scan(ws, b, "body")

    cells = sorted(set(rd1) | set(wr1) | set(rd2) | set(wr2))
    print("\n   cell |  mode-1 rd  wr |  mode-2 rd    wr | verdict")
    print("   -----+----------------+------------------+---------------------------")
    for c in cells:
        if not (rd1[c] or wr1[c]):
            continue
        v = ""
        if (rd1[c] or wr1[c]) and (rd2[c] or wr2[c]):
            v = "BOTH ROUTES TOUCH IT"
        else:
            v = "mode-1 only"
        print("    %02X   |    %4d %4d |  %5d %5d | %s"
              % (c, rd1[c], wr1[c], rd2[c], wr2[c], v))
    print()
    return rd1, wr1, rd2, wr2


def sec_volume(header, epilogue, images):
    print("=" * 74)
    print("VOLUME -- the decisive argument, item J extended to mode 2")
    print("=" * 74)
    print("""
  ESTABLISHED, not assumed here:
    A1  (register-space.md, ***) cells 0x06/0x86 hold the user-facing VOLUME,
        named by the effect's own parameter bytecode, the T1 map, the UI name
        table and two curve tables.  Written ONCE by EFF_VolumeLoop after
        linking (PROVEN BY CONSTRUCTION).
    J   (output-stage-decode.md, FORCED) a mode-1 ACTION-0x07 word does NOT
        write reg[addr8] -- because w72 is `000.1.06.087', and if it wrote,
        "that depth would survive exactly ONE frame".

  THE EXTENSION.  Guard 6 rejected a ONE-frame lifetime as impossible.  If
  mode-2 mem[ptr] were the SAME memory, the same cell would be overwritten by
  the kernel's own scratch stores every frame -- not once, but:
""")
    tr, _end = walk_signed(header, 0xFF)
    hits = [(i, w, p) for i, w, p in tr if writes_mem(w) and p == 0x06]
    for i, w, p in hits:
        hi, c, a, lo = fields(w)
        print("      iw%-3d  %010X   %03X.%X.%02X.%03X   writes mem[%02X]"
              % (i, w, hi, c, a, lo, p))
    print("\n    %d kernel writes to cell 0x06 per frame (static walk)." % len(hits))

    # CALIBRATION, run before the argument is believed, not after.  The live
    # core measured the writers of cell 0x06 (SPECULATIVE-APPLIED-REGISTER sect.96).
    # If the static walk cannot reproduce that set, the walk is the thing that
    # is wrong, and NOTHING here may rest on it.
    MEASURED_96 = {11, 19, 21, 27, 33, 34, 39}
    static = {i for i, _w, _p in hits}
    print("\n  CALIBRATION vs the live trace (sect.96), before believing any of it:")
    print("    sect.96 measured : %s" % sorted(MEASURED_96))
    print("    static walk      : %s" % sorted(static))
    print("    agree %d, static-only %s, trace-only %s"
          % (len(static & MEASURED_96), sorted(static - MEASURED_96),
             sorted(MEASURED_96 - static)))
    if static != MEASURED_96:
        print("""
    >> THE TWO DISAGREE.  The static walk is a reimplementation carrying at
       least three unverified conventions (kernel entry cell, whether a store
       lands on the pre- or post-increment cell, and which store forms count).
       It is NOT independent evidence and the verdict below does not use it.
""")
    print("""
  THE ARGUMENT, which needs no walk at all:

    * the epilogue's w72 `000.1.06.087' READS mode-1 reg[0x06] as the volume
      (item J names this word, and A1 names the cell)
    * the kernel's mode-2 route WRITES its whole pointer window every frame --
      that much is true under ANY base, and under the core's OWN measured base
      cell 0x06 is inside that window (sect.86/96, seven writers)
    * item J already FORCED that reg[0x06] cannot be written even ONCE per
      frame, because the user's effect depth would not survive

    Under the alias hypothesis the kernel destroys the volume every frame.
    Item J's forcing therefore refutes the alias.

  VERDICT: mode-1 `addr8' and mode-2 `mem[ptr]' are NOT the same memory.
           The numeric intersection in section `sets' is index collision --
           both routes index with 8 bits -- not aliasing.  Our core resolves
           both onto one 256-cell array; the chip does not.
""")
    return hits


def sec_walk(header):
    print("=" * 74)
    print("WALK -- static kernel pointer trajectory from the forced base 0x05")
    print("=" * 74)
    tr, end = walk_signed(header, 0x05)
    for i, w, p in tr:
        hi, c, a, lo = fields(w)
        tag = []
        if reads_mem(w):
            tag.append("rd mem[%02X]" % p)
        if writes_mem(w):
            tag.append("WR mem[%02X]" % p)
        if is_mode1(w):
            tag.append("mode-1 reg[%02X]" % a)
        if ptr_postinc(w):
            d = a - 256 if a > 127 else a
            tag.append("ptr %+d" % d)
        if tag:
            print("   iw%-3d %010X  %03X.%X.%02X.%03X  %s"
                  % (i, w, hi, c, a, lo, ", ".join(tag)))
    print("\n   pointer after the kernel: %02X\n" % end)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*",
                    default=["sets", "direction", "volume"])
    ap.add_argument("--sub", default="original_ROMs/kn5000_subprogram_v142.rom")
    ap.add_argument("--tools", default="../kn7000_mame/tools")
    a = ap.parse_args()
    header, epilogue, images = load_corpus(a.sub, a.tools)
    print("corpus: header %d + epilogue %d + %d body images\n"
          % (len(header), len(epilogue), len(images)))
    if "sets" in a.sections:
        sec_sets(header, epilogue, images)
    if "direction" in a.sections:
        sec_direction(header, epilogue, images)
    if "volume" in a.sections:
        sec_volume(header, epilogue, images)
    if "walk" in a.sections:
        sec_walk(header)


if __name__ == "__main__":
    main()
