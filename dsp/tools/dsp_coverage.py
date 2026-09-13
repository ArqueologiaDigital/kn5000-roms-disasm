#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_coverage.py -- how much of the uPD6383GF instruction set is actually read.

NEC uPD6383GF (Technics SX-KN5000 IC311).  Every coverage number quoted in
`dsp/instruction-set.md` comes out of THIS tool, so the document cannot drift
away from the disassembler.  It decodes nothing: it asks
`dsp/tools/dsp_disasm.py` what it can read, over the words that actually run.

    python3 dsp/tools/dsp_coverage.py
    python3 dsp/tools/dsp_coverage.py --sub <rom> --tools <kn7000_mame/tools>

TWO TIERS, NEVER ADDED TOGETHER:

  TIER 1  DECODED   -- a real mnemonic; a core could EXECUTE the word.
  TIER 2  OPERATION -- the operation is DETERMINED or MEASURED but the operand
                       encoding is not, so the word still cannot be executed
                       (external delay-DRAM read/write; the C-format 13-bit
                       immediate load; the call-vector writes' source field).

The FRAME FLOOR is the honest headline: the 83-word resident kernel plus the
133-word reverb -- the code that runs in every frame of every reverb preset and
that carries the audio in and out.  Body-corpus percentages are vocabulary
statistics and are reported separately.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D

ALGO_TABLE = 0x0001ED7C
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
N_ALGOS = 100
# RENAMED 2026-07-27: NOT malformed -- these are IC310 (MN19413) programs
# whose cmd-0x30 record rides on record opcode 3, so an IC311-shaped parser
# turns them into a phantom I-RAM block.  Algorithms 57-60 are IC310's too
# (their cmd-0x30 rides on opcode 0x0E and parses to nothing, so `if ir:'
# already drops them): the IC311 population is 91 of 100, not 95.
# See dsp/analysis/second-dsp-and-ready.md sect. 2.
DSP2_MISPARSED = {79, 88, 89, 90, 91}
MALFORMED = DSP2_MISPARSED      # deprecated alias
REVERB_ALGO = 16


# THE FORM TABLE LIVES IN dsp_disasm.py, NOT HERE.  This copy drifted once
# already -- it mapped every `hi12 == 0x801' word that was not `ldptr' to
# `rstcur', so the newly added `ldptr.d' would have been mis-tallied
# (analysis/isa-adjudication.md sect. 7).  A second copy of a decode table is a
# second thing to keep in step, and this project has paid for that twice.
form_of = D.form_of


#   ★ TIER 1b -- EXECUTABLE IN CONTEXT (N-INPUT-GATE-OPENED sect. 96).  `decoded()' is a
#   per-WORD predicate and the MAME disassembler mirrors it word for word, so it cannot see that
#   a word's ONE open axis is an accumulator the image throws away four slots later.  That is a
#   property of the SITE, not of the word, and `acc_blind.py' computes it from the image.  Kept
#   as its own column so the per-word number stays comparable with every figure ever published.
import acc_blind as B                                                    # noqa: E402


def tally(images):
    """★ `images' is a LIST OF IMAGES, not a flat word list.  Tier 1b is a per-SITE property and
    its liveness walk runs to the end of THE IMAGE -- concatenating first would let a site at the
    tail of one body find its `f31 == 0' killer in the next body, which does not follow it in
    execution.  Every caller passes the images separately for that reason."""
    n = a = nb = b = 0
    for words in images:
        blind = set(B.blind_sites(words))
        n += len(words)
        a += sum(1 for w in words if D.decoded(w))
        nb += len(blind)
        b += sum(1 for i, w in enumerate(words)
                 if not D.decoded(w) and i not in blind and D.status(w))
    return n, a, nb, b


def row(name, *images):
    n, a, nb, b = tally(images)
    return ("  %-30s %5d %7d %7.1f%% %6d %7.1f%% %6d %7.1f%%"
            % (name, n, a, 100.0 * a / n if n else 0.0,
               nb, 100.0 * (a + nb) / n if n else 0.0, b,
               100.0 * (a + nb + b) / n if n else 0.0))


def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    if not os.path.isdir(args.tools):
        sys.exit("ERROR: need the ROM parser -- pass --tools <kn7000_mame/tools>")
    sys.path.insert(0, args.tools)
    import kn5000_dsp_extract as E

    rom = E.Rom(args.sub)

    def blk(addr):
        iram, _c, _o = E.parse_stream(rom, addr, limit=40)
        return [int.from_bytes(bytes(w), "big") for w in iram[0][1]]

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    imgs = {}
    for i in range(N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        if ir and i not in MALFORMED:
            imgs[i] = [int.from_bytes(bytes(w), "big")
                       for _a, ws, _l in ir for w in ws]
    seen = {}
    for a in sorted(imgs):
        seen.setdefault(tuple(imgs[a]), a)
    distinct = {v: list(k) for k, v in seen.items()}
    allbody = [w for a in sorted(distinct) for w in distinct[a]]
    reverb = imgs[REVERB_ALGO]
    kernel = header + epilogue

    print("=" * 78)
    print("uPD6383GF DECODE COVERAGE -- tier 1 = executable, tier 2 = operation only")
    print("=" * 78)
    print("  %-30s %5s %7s %8s %6s %8s %6s %8s"
          % ("region", "words", "tier1", "tier1%", "+1b", "t1+1b%", "tier2", "all%"))
    # What the chip actually EXECUTES differs from the canned ROM image in
    # exactly two words: after EFF_Link the host has overwritten I-RAM 64 and 71
    # with the C-format call-vector loads (cold-boot capture transfers 50/51,
    # PROVEN BY CONSTRUCTION -- analysis/k5-output-stage.md sect. 2).
    linked = list(epilogue)
    linked[64 - 60] = 0xC40A80445          # setvec unit0,#84
    linked[71 - 60] = 0xC41900446          # setvec unit1,#200

    print(row("resident kernel I-RAM 0..82", header, epilogue))
    print(row("   ...header  I-RAM  0..59", header))
    print(row("   ...output stage 60..82", epilogue))
    print(row("   ...output stage AS LINKED", linked))
    print(row("reverb image (algo 16)", reverb))
    print(row("FRAME FLOOR kernel + reverb", header, epilogue, reverb))
    print(row("FRAME FLOOR as linked", header, linked, reverb))
    print(row("all %d distinct body images" % len(distinct),
              *[distinct[a] for a in sorted(distinct)]))
    print()
    print("  tier-1 forms on the frame floor:")
    fc = {}
    for w in kernel + reverb:
        f = form_of(w)
        if f:
            fc[f] = fc.get(f, 0) + 1
    for k in sorted(fc):
        print("      %-8s %d" % (k, fc[k]))
    print("  tier-2 words on the frame floor, by annotation status:")
    sc = {}
    for w in kernel + reverb:
        if not D.decoded(w):
            s = D.status(w)
            if s:
                sc[s] = sc.get(s, 0) + 1
    for k in sorted(sc):
        print("      %-12s %d" % (k, sc[k]))
    print()
    print("  images with ZERO tier-1 words: %d of %d"
          % (sum(1 for a in distinct if not any(D.decoded(w) for w in distinct[a])),
             len(distinct)))
    print("  distinct undecoded words   : %d"
          % len({w for w in allbody if not D.decoded(w)}))
    print("  distinct undecoded FAMILIES: %d"
          % len({(D.hi12(w), D.class4(w), D.lo12(w))
                 for w in allbody if not D.decoded(w)}))


if __name__ == "__main__":
    main()
