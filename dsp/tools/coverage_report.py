#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""coverage_report.py -- NEC uPD6383GF (SX-KN5000 IC311): HOW MUCH OF EACH EFFECT
CAN WE ACTUALLY EXECUTE, AND WHAT BLOCKS THE REST?

⚠ WHAT THIS DOES AND DOES NOT MEASURE.  The device reports "285 slots = 285
DECODED, 0 TRAP", but that number is an ARTEFACT: alu_decoded_speculative() ends in
an unconditional `return true', so every word is admitted whatever its fields say.
The per-slot probe shows the truth in its `dec' and `gfail' columns -- words with
dec = 0 run only via that catch-all.

So this counts, per program, how many words are decoded on ANCHORED evidence versus
how many depend on a field this project still lists as UNKNOWN.  It is a STATIC
approximation of alu_decoded(), keyed on the unknown FIELDS rather than reproducing
its guard order, so treat it as a lower bound on what is genuinely understood.

The unknown sets are stated in the source below so the numbers are interpretable
rather than authoritative-looking.
"""
import argparse
import collections
import os
import sys

ALGO_TABLE = 0x0001ED7C
N_ALGOS = 100
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}

# ---- THE UNKNOWN SETS, as this project currently records them -----------------
#  f31 = hi12[3:1] > 2      the standing task "attack hi12[3:1] > 2"
UNK_ACT = {0x0b, 0x0c, 0x0d, 0x0e, 0x1c}      # §107, §120: undecoded actions
UNK_SRC = {0x00, 0x02, 0x03, 0x04, 0x05,      # §100/§101: 0x02/0x03 defeated at n=1
           0x06, 0x0a, 0x13, 0x1b, 0x1d}      # 0x00 is 610 words and still a guess
UNK_CLASS = {0, 4, 5, 6}                      # register-space.md §5.3 "unknown classes"
#  ANCHORED SRC: 0x07 mem[ptr], 0x08 C-RAM[cursor] (§111 corroborated), 0x0B delay,
#  0x10 acc, 0x11 (contested: ACCB vs mem[ptr]), 0x19 tempA, 0x1A tempB, 0x1C LFO?


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def c_format(w):
    return (((w >> 24) & 0xFFF) & 0xF00) == 0xC00


def classify(w):
    """-> None if decoded, else a short reason string naming the blocker."""
    hi, c, a, lo = fields(w)
    if c_format(w):
        return None                      # C-format: MEASURED (the terminator etc.)
    if (lo >> 5) & 1:
        return None                      # pointer/cursor family: settled selectors
    f31 = (hi >> 1) & 7
    src, act = (lo >> 6) & 0x1F, lo & 0x1F
    if f31 > 2:
        return "f31=%d" % f31
    if act in UNK_ACT:
        return "ACT %02X" % act
    if src in UNK_SRC:
        return "SRC %02X" % src
    if c in UNK_CLASS:
        return "class %d" % c
    return None


def load(sub, tools):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    rom = E.Rom(sub)

    def blk(addr):
        ir, _c, _o = E.parse_stream(rom, addr, limit=40)
        return [int.from_bytes(bytes(x), "big") for x in ir[0][1]] if ir else []

    header, epilogue = blk(HEADER_ROM), blk(EPILOGUE_ROM)
    progs = {}
    for i in range(N_ALGOS):
        p = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            ir, _c, _o = E.parse_stream(rom, p)
        except Exception:
            continue
        if ir:
            progs[i] = [int.from_bytes(bytes(x), "big")
                        for x in (x for _a, ws, _l in ir for x in ws)]
    return header, epilogue, progs


def names(path):
    out = {}
    if not os.path.exists(path):
        return out
    for line in open(path):
        if line.startswith("#"):
            continue
        f = line.rstrip("\n").split("\t")
        if len(f) > 2 and f[0].isdigit():
            out[int(f[0])] = (f[1], f[4] if len(f) > 4 else "?")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub", default="original_ROMs/kn5000_subprogram_v142.rom")
    ap.add_argument("--tools", default="../kn7000_mame/tools")
    ap.add_argument("--tsv", default="dsp/programs.tsv")
    ap.add_argument("--notes", default="dsp/analysis")
    a = ap.parse_args()
    header, epilogue, progs = load(a.sub, a.tools)
    nm = names(a.tsv)

    # the header and epilogue run for EVERY algorithm, so their blockers are common
    common = [w for w in header + epilogue]
    cb = [classify(w) for w in common]
    print("=" * 78)
    print("COMMON CODE (the 60-word kernel + 23-word epilogue, run by every effect)")
    print("=" * 78)
    print("  %d words, %d blocked (%.0f%%)"
          % (len(common), sum(1 for x in cb if x), 100.0 * sum(1 for x in cb if x) / len(common)))
    print("  blockers: %s\n" % dict(collections.Counter(x for x in cb if x).most_common()))

    rows, blockers = [], collections.Counter()
    prog_blockers = collections.defaultdict(set)
    for i in sorted(progs):
        if i in DSP2_MISPARSED:
            continue
        ws = progs[i]
        cs = [classify(w) for w in ws]
        bad = [x for x in cs if x]
        for x in bad:
            blockers[x] += 1
            prog_blockers[x].add(i)
        rows.append((len(bad), len(ws), i, nm.get(i, ("?", "?"))[0]))

    rows.sort(key=lambda r: (r[0], r[1]))
    print("=" * 78)
    print("PER-EFFECT BODY COVERAGE -- closest to fully executable FIRST")
    print("=" * 78)
    print("  blocked/words  algo  effect")
    clean = [r for r in rows if r[0] == 0]
    for bad, tot, i, name in rows[:18]:
        mark = "  ★ FULLY DECODED" if bad == 0 else ""
        print("     %3d/%-4d      %3d  %-26s%s" % (bad, tot, i, name[:26], mark))
    print("     ... %d programs total\n" % len(rows))
    print("  ★ FULLY DECODED BODIES: %d of %d" % (len(clean), len(rows)))
    if clean:
        print("     %s" % ", ".join("%d %s" % (i, n) for _b, _t, i, n in clean))
    print()

    print("=" * 78)
    print("BLOCKER RANKING -- what to decode next, by programs unblocked")
    print("=" * 78)
    print("  blocker    words   programs affected")
    for b, n in blockers.most_common(12):
        print("   %-9s %5d   %3d" % (b, n, len(prog_blockers[b])))
    print()

    # which effects has the investigation actually used?
    print("=" * 78)
    print("LEVERAGE -- which effects the analysis notes have actually used")
    print("=" * 78)
    text = ""
    if os.path.isdir(a.notes):
        for f in os.listdir(a.notes):
            if f.endswith(".md"):
                text += open(os.path.join(a.notes, f), errors="ignore").read().upper()
    seen, unseen = [], []
    for i in sorted(progs):
        if i in DSP2_MISPARSED:
            continue
        n = nm.get(i, ("?", ""))[0]
        if n in ("?", ""):
            continue
        (seen if text.count(n.upper()) >= 3 else unseen).append((text.count(n.upper()), i, n))
    print("  NEVER OR BARELY USED (< 3 mentions across all analysis notes):")
    for c, i, n in sorted(unseen)[:22]:
        print("     %2d mentions  algo %3d  %s" % (c, i, n))
    print("     ... %d barely-used of %d named\n" % (len(unseen), len(seen) + len(unseen)))


if __name__ == "__main__":
    main()
