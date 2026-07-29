#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""route3_tag15.py -- ARE THE REVERB'S PER-STAGE GAINS IN THE D-RAM PACKETS?

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware.

ROUTE 3 asked: the host poke port (cmd 0x01 @ 0x0160) carries 881 canned tag-0x15
D-RAM writes that the emulator dropped until 2026-07-29, so nobody had read them.
Are any of them the missing per-stage feedback gain of the reverb ladder?

    python3 dsp/tools/route3_tag15.py capture   # 1 decode EVERY poke packet, live
    python3 dsp/tools/route3_tag15.py census    # 2 *** the ROM-wide tag-0x15 census
    python3 dsp/tools/route3_tag15.py gains     # 3 *** where the gains ACTUALLY are
    python3 dsp/tools/route3_tag15.py ladder    # 4 *** algo 16's ladder, stage by stage
    python3 dsp/tools/route3_tag15.py all

ANSWER (see analysis): NO -- 108 of 108 canned tag-0x15 writes reaching the twelve
reverbs are exactly 0x000000, and the only non-zero runtime one is cell 0x86 =
VOLUME.  The gains are in C-RAM 0x90..0xB0, one per delay stage, 396/396 resolved,
max |g| = 0.810 < 1.
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import register_space as RS                                         # noqa: E402
import dsp_disasm as DIS                                            # noqa: E402
import delayline as DL                                              # noqa: E402
import lfo_ramp as L                                                # noqa: E402
import dram_cursor as DC                                            # noqa: E402

SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")
CAP = os.path.expanduser("~/compartilhado/kn7000-emulator/kn5000_dsp1_upload.txt")
TAGN = {0x15: "DRAM", 0x26: "CRAM", 0x4C: "DESC"}


def q23(v):
    return (v - (1 << 24)) / float(1 << 23) if v & 0x800000 else v / float(1 << 23)


def head(n, s):
    print("=" * 78)
    print("%s. %s" % (n, s))
    print("=" * 78)


def poke_writes(path=CAP):
    """The live cold-boot capture, poke port ONLY -> [(xfer, tag|None, cell, v)].

    RS.coldboot_capture keeps the two-byte command address, so `01 60' is the
    poke PORT and `01 61' the 24-bit coefficient port (host-side.md C4).  Only
    the former carries five-byte tagged packets; parsing the latter as five-byte
    words produces the phantom `selects' that earlier passes had to hand-wave."""
    out = []
    for i, pay in enumerate(RS.coldboot_capture(path)):
        if len(pay) < 3 or pay[0] != 0x01 or pay[1] != 0x60:
            continue
        data, cell = pay[2:], None
        for k in range(0, len(data) - 4, 5):
            b5 = data[k:k + 5]
            if RS.is_packet(b5):
                v, tag, _b32, _b31 = RS.packet(b5)
                out.append((i, tag, cell, v))
                if cell is not None:
                    cell += 1
            else:
                cell = DIS.addr8(int.from_bytes(b5, "big"))
                out.append((i, None, cell, None))
    return out


def cmd_capture():
    head(1, "THE LIVE COLD-BOOT CAPTURE, poke port decoded packet by packet")
    w = poke_writes()
    if not w:
        print("   capture not found: %s" % CAP)
        return
    for (i, tag, cell, v) in w:
        if tag is None:
            print("   x%02d  SELECT cell 0x%02X" % (i, cell))
        else:
            print("   x%02d  %-4s [0x%02X] = 0x%06X  %+11.7f"
                  % (i, TAGN.get(tag, "t%02X" % tag), cell or 0, v, q23(v)))
    c = collections.Counter(t for (_i, t, _c, _v) in w if t is not None)
    print()
    for t, n in sorted(c.items()):
        print("   tag 0x%02X %-5s : %d packets" % (t, TAGN.get(t, "?"), n))
    print("   selects            : %d"
          % sum(1 for x in w if x[1] is None))


def cmd_census():
    head(2, "THE ROM-WIDE tag-0x15 CENSUS -- can ANY of them be a gain?")
    rom, main, _t = RS.load(SUB, MAIN, TOOLS)
    unit = {a: u for (a, u, _c, _k) in DL.ctx().algos}
    allw = []
    for a, p in RS.all_streams(rom).items():
        for tag, cell, v in RS.transactions(rom, p, autoinc=1):
            if tag == 0x15:
                allw.append((a, cell, v))
    gain = lambda v: 0.30 <= abs(q23(v)) <= 0.95                    # noqa: E731
    print("   canned tag-0x15 writes: %d over %d cells, %d algorithms, %d values"
          % (len(allw), len(set(c for _a, c, _v in allw)),
             len(set(a for a, _c, _v in allw)),
             len(set(v for _a, _c, v in allw))))
    z = sum(1 for _a, _c, v in allw if v == 0)
    g = sum(1 for _a, _c, v in allw if gain(v))
    print("   EXACTLY ZERO      : %d = %.1f%%" % (z, 100.0 * z / len(allw)))
    print("   in 0.30..0.95     : %d = %.1f%%" % (g, 100.0 * g / len(allw)))
    rev = [(a, c, v) for (a, c, v) in allw if unit.get(a) == 1]
    print()
    print("   ** THE TWELVE REVERBS (unit 1), which is the question:")
    cells = collections.defaultdict(collections.Counter)
    for a, c, v in rev:
        cells[c][v] += 1
    for c in sorted(cells):
        print("      cell 0x%02X : %s" % (c, ", ".join(
            "0x%06X x%d" % (v, n) for v, n in sorted(cells[c].items()))))
    print("      -> %d writes, %d of them non-zero.  ROUTE 3 IS FALSIFIED for the"
          % (len(rev), sum(1 for _a, _c, v in rev if v)))
    print("         reverbs: there is no gain in this space to find.")
    print()
    print("   ** every gain-band value, and whose cell it is:")
    gb = collections.defaultdict(list)
    for a, c, v in allw:
        if gain(v):
            gb[c].append((a, v))
    for c in sorted(gb):
        print("      cell 0x%02X  unit(s) %s  n=%d  %s"
              % (c, sorted(set(unit.get(a) for a, _v in gb[c])), len(gb[c]),
                 sorted(set("%+0.4f" % q23(v) for _a, v in gb[c]))[:6]))


def cmd_gains():
    head(3, "WHERE THE PER-STAGE GAINS ACTUALLY ARE -- C-RAM 0x90..0xB0")
    main = open(MAIN, "rb").read()
    revs = sorted(a for (a, u, _c, _k) in DL.ctx().algos if u == 1)
    allv = []
    print("   algo  name                    nA   keys        miss   min       "
          "max      max|g|")
    for a in revs:
        prog, cram = DL.program(a), L.cram_of_algo(a)
        cur, base = DIS.cursor_addresses(prog.words), DL.cram_base(a)
        ks = [base + k for k in cur if k is not None]
        vs = [cram.get(k) for k in ks]
        vv = [q23(v) for v in vs if v is not None]
        allv += vv
        print("     %2d  %-22s %3d  0x%02X..0x%02X  %d   %+8.5f %+8.5f  %.5f"
              % (a, RS.effect_name(main, a), len(ks), min(ks), max(ks),
                 sum(1 for v in vs if v is None), min(vv), max(vv),
                 max(abs(x) for x in vv)))
    n = len(allv)
    print()
    print("   TOTAL fetches %d ; max|g| %.6f ; |g|>=1 : %d ; negative %d ; "
          "distinct %d" % (n, max(abs(g) for g in allv),
                           sum(1 for g in allv if abs(g) >= 1.0),
                           sum(1 for g in allv if g < 0),
                           len(set("%0.6f" % g for g in allv))))
    print("   in 0.30..0.95 : %d = %.1f%%"
          % (sum(1 for g in allv if 0.30 <= abs(g) <= 0.95),
             100.0 * sum(1 for g in allv if 0.30 <= abs(g) <= 0.95) / n))
    print()
    print("   ** and the emulator does not read them.  The kernel's `ldptr' before")
    print("      body 1 is iw50 = 0801050821 -> 0x50, and under register row 25")
    print("      (upd6383.cpp:2363, live whenever UPD6383_SPEC bit 0x1000 is clear)")
    print("      that seeds the COEFFICIENT cursor, so the body's 33 class-A words")
    print("      walk 0x50..0x70 -- entirely inside the [0x50,0x8B] window where")
    print("      upd6383.cpp:2197 (bit 0x100, SET in the shipped 0x54C) returns")
    print("      WITHOUT forming a product.  33 of 33 gains skipped.")


def cmd_ladder():
    head(4, "ALGO 16 ROOM REVERB 1 -- the ladder, stage by stage")
    a = 16
    prog, cram = DL.program(a), L.cram_of_algo(a)
    cur, base = DIS.cursor_addresses(prog.words), DL.cram_base(a)
    for i, w in enumerate(prog.words):
        k, ad = cur[i], DIS.addr8(w)
        dly = ("DLY %s addr8=%02X" % ("READ " if not (ad & 0x40) else "WRITE", ad)
               if (DIS.hi12(w) & 0x800) else "")
        cv = cram.get(base + k) if k is not None else None
        ct = ("" if cv is None
              else "coef[0x%02X]=0x%06X %+9.6f" % (base + k, cv, q23(cv)))
        if ct or dly:
            print("   iw%3d  %010X  %-34s %s" % (i, w, ct, dly))


def cmd_kernel():
    head(5, "THE KERNEL'S TWO `ldptr 0x821' LOADS ARE UNIT-MATCHED TO THE DRAM HALVES")
    rom, imgs, loads, hdr, epi = DC.load(SUB, TOOLS)
    for nm, ws in (("kernel(header)", hdr), ("epilogue", epi)):
        n = 0
        print("   ---- %s : %d words" % (nm, len(ws)))
        for i, w in enumerate(ws):
            wi = w if isinstance(w, int) else int.from_bytes(bytes(w), "big")
            lo = DIS.lo12(wi)
            if DIS.coeff_consumer(wi):
                n += 1
            if lo in (0x821, 0x825):
                print("      iw%3d %010X  ldptr%s -> 0x%02X"
                      % (i, wi, ".d" if lo == 0x825 else "  ", DIS.addr8(wi)))
        print("      class-A total: %d" % n)
    print()
    print("   iw42 -> 0x70 = TABLE B (0x0000..0x7FFF = unit 0's DRAM half), and it")
    print("   precedes BODY 0 (unit 0).  iw50 -> 0x50 = TABLE A (0x8000..0xFC00 =")
    print("   unit 1's DRAM half), and it precedes BODY 1 (unit 1).  A COEFFICIENT")
    print("   bank would not be partitioned by delay-DRAM region; an ADDRESS table")
    print("   is.  Independent support for K3 item F (0x821 is not the cursor).")
    print("   RESIDUE, stated: the epilogue's iw9 -> 0x90 is NOT an address table,")
    print("   so 0x821 is a general C-RAM pointer with at least that third use.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["capture", "census", "gains", "ladder", "kernel", "all"])
    ns = ap.parse_args()
    for c in (["capture", "census", "gains", "ladder", "kernel"]
              if ns.cmd == "all" else [ns.cmd]):
        globals()["cmd_" + c]()
        print()


if __name__ == "__main__":
    main()
