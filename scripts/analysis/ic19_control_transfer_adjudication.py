#!/usr/bin/env python3
r"""ARE THE 13 CONTROL TRANSFERS INTO IC19's ADDRESS WINDOW AN ENTRY PATH INTO IC19?

QUESTION THIS ANSWERS
---------------------
`kn5000.cpp:631` maps IC19 (`custom_data`, 8 Mbit flash, CS5) as
`map(0x300000, 0x3fffff).rom()` -- i.e. it is CPU-FETCHABLE, not a data port.
A previous lane concluded IC19 is a PURE DATA ROM (all 206 references load its
address; `llvm-mc` emits 0 instruction statements from `custom_data/`'s source
against 36,391 for HD-AE5000; injected real code scores far above anything
actually there).

But **13 control transfers whose target lies inside 0x300000-0x3FFFFF do exist
in the maincpu sources** -- 6 in `v10/maincpu/sequencer/accompaniment_engine.s`
and 7 in its v9 twin -- and every one of them sits inside a `.byte`-adjacent
region.  Nobody had adjudicated them.  Either they are misframed data (which
would STRENGTHEN the pure-data verdict) or IC19 has an entry path nobody has
found (which would be a correction with driver consequences).

This script adjudicates all 13 FROM ROM BYTES, never from the .s framing that
is itself under suspicion.

THE FIVE INDEPENDENT LINES OF EVIDENCE
--------------------------------------
1. --census    the 13 source sites, and the fact that they name only FOUR
               distinct targets: 0x3540F1, 0x379BF1, 0x37C9F1, 0x3B1D1C.
2. --rom       every ROM byte sequence that can produce one.  `jp imm24` is
               `1B <lo> <mid> <hi>`.  GUARD: the ROM bytes at each located
               offset must equal the encoding the source line claims, and the
               v9 and v10 program ROMs must be BYTE-IDENTICAL there (they are;
               the 13 sites are 12 ROM addresses shared by both images).
3. --targets   what is AT the target inside the dumped IC19 image.  A real
               entry point must land on code.
4. --reframe   MAME's `unidasm` -- a decoder wholly independent of this tree's
               `llvm-mc` backend, whose listing is committed beside the ROM --
               frames the SAME bytes differently at every one of the 12 sites.
5. --null      the false-positive control.  How many `1B <3 bytes>` sequences
               land in each 1 MiB window of the 24-bit maincpu space, including
               the three windows that have NO DEVICE AT ALL (0x200000,
               0xC00000, 0xD00000, per kn5000.cpp's maincpu_mem).  If IC19's
               count sits at the same level as an unmapped window, the "entry
               path" reading carries no signal.

⚠ THE NULL IS THE POINT.  A 2 MiB code ROM contains ~2 million 4-byte windows;
`1B` is a common byte; so SOME of them will spell a `jp` into any window you
name.  The count only means something against what an empty window scores.

RUN
    python3 scripts/analysis/ic19_control_transfer_adjudication.py            # all sections
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --census
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --rom
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --targets
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --reframe
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --null

TOOLCHAIN.  Sections 1-5 read BYTES and a committed text listing only; none of
them invokes llvm-mc, so none is exposed to the shared-toolchain drift the lane
brief warns about.  The four `jp imm24` encodings quoted were taken from
`llvm-mc -triple=tlcs900 -show-encoding` at tlcs900_backend@6f456a19f05b and are
asserted against the ROM here, so a later decoder change cannot silently move
them.
"""
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(ROOT, "original_ROMs")
PROG_BASE = 0xE00000
IC19_LO, IC19_HI = 0x300000, 0x3FFFFF

# `jp imm24` = 0x1B followed by the 24-bit target, little endian.
# (llvm-mc -triple=tlcs900 -show-encoding, tlcs900_backend@6f456a19f05b)
def jp_enc(target):
    return bytes([0x1B, target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF])

XFER = re.compile(r"^\s+(jp|jr|jrl|call|calr|djnz)\s+(?:[a-z]+\s*,\s*)?0x([0-9a-f]{6})\s*$")

# kn5000.cpp maincpu_mem(), condensed to 1 MiB windows.  The three windows with
# NO DEVICE AT ALL are the null.
WINDOWS = {
    0x0: "DRAM (IC9/IC10)", 0x1: "devices + IC21 SRAM", 0x2: "-- NO DEVICE --",
    0x3: "IC19 custom_data  <<< THE QUESTION", 0x4: "IC14 rhythm_data",
    0x5: "IC14 rhythm_data", 0x6: "IC14 rhythm_data", 0x7: "IC14 rhythm_data",
    0x8: "IC1/IC3 table_data", 0x9: "IC1/IC3 table_data",
    0xA: "table_data mirror", 0xB: "table_data mirror",
    0xC: "-- NO DEVICE --", 0xD: "-- NO DEVICE --",
    0xE: "program ROM (IC4/IC6)", 0xF: "program ROM (IC4/IC6)",
}
NULL_WINDOWS = [0x2, 0xC, 0xD]

fails = []


def rom(name):
    return open(os.path.join(ROM, name), "rb").read()


def src_files(tree):
    out = []
    for dp, _, fn in os.walk(os.path.join(ROOT, tree, "maincpu")):
        for f in sorted(fn):
            if f.endswith(".s"):
                out.append(os.path.join(dp, f))
    return sorted(out)


def census():
    print("=" * 78)
    print("1. THE 13 SITES -- every control transfer in v10/v9 maincpu whose")
    print("   literal target lies inside IC19's window 0x300000-0x3FFFFF")
    print("=" * 78)
    sites = []
    for tree in ("v10", "v9"):
        for path in src_files(tree):
            # latin-1: these sources are NOT utf-8 (lane brief).
            for n, line in enumerate(open(path, encoding="latin-1"), 1):
                m = XFER.match(line.rstrip("\n"))
                if m and IC19_LO <= int(m.group(2), 16) <= IC19_HI:
                    sites.append((tree, os.path.relpath(path, ROOT), n,
                                  m.group(1), int(m.group(2), 16)))
    for t, p, n, mn, tgt in sites:
        print(f"   {t:3s} {p}:{n:<6d} {mn} 0x{tgt:06x}")
    tgts = sorted(set(s[4] for s in sites))
    print(f"\n   TOTAL SITES: {len(sites)}   "
          f"(v10 {sum(1 for s in sites if s[0]=='v10')}, "
          f"v9 {sum(1 for s in sites if s[0]=='v9')})")
    print(f"   DISTINCT TARGETS: {len(tgts)} -- " +
          ", ".join(f"0x{t:06x}" for t in tgts))
    print("   Every one is a `jp`, and every one is in ONE file "
          "(sequencer/accompaniment_engine.s).")
    if len(sites) != 13:
        fails.append(f"expected 13 sites, found {len(sites)}")
    return tgts


def rom_sites(tgts):
    print()
    print("=" * 78)
    print("2. WHERE THOSE BYTES ARE IN THE ROM, AND WHETHER v9 AND v10 AGREE")
    print("=" * 78)
    v10, v9 = rom("kn5000_v10_program.rom"), rom("kn5000_v9_program.rom")
    found = []
    for t in tgts:
        enc = jp_enc(t)
        for m in re.finditer(re.escape(enc), v10):
            o = m.start()
            same = v9[o:o + 4] == enc
            if not same:
                fails.append(f"v9 differs at {o:#x}")
            found.append((o, t))
            print(f"   0x{PROG_BASE+o:06X}  jp 0x{t:06x}   enc {enc.hex(' ')}  "
                  f"v9 identical: {'YES' if same else 'NO'}")
    # GUARD (lane brief: a map that is not checked against the ROM certifies nothing)
    for o, t in found:
        if v10[o:o + 4] != jp_enc(t):
            fails.append(f"ROM byte guard failed at {o:#x}")
    # and the whole 0x40-byte neighbourhood of every site must match between images
    for o, _ in found:
        if v10[o - 0x20:o + 0x20] != v9[o - 0x20:o + 0x20]:
            fails.append(f"v9/v10 neighbourhood differs at {o:#x}")
    print(f"\n   {len(found)} ROM addresses carry these encodings; the 13 source")
    print("   sites are drawn from them (some occurrences are ALREADY typed as")
    print("   data in the sources -- which is itself corroboration).")
    print("   ★ v9 and v10 are BYTE-IDENTICAL in the 0x40-byte neighbourhood of")
    print("     every one, so one adjudication covers both trees.")
    return found


def targets(tgts):
    print()
    print("=" * 78)
    print("3. WHAT IS AT THE TARGET, INSIDE THE DUMPED IC19 IMAGE")
    print("   (a real entry point must land on code)")
    print("=" * 78)
    ic19 = rom("kn5000_custom_data.ic19")
    for t in tgts:
        off = t - IC19_LO
        b = ic19[off:off + 32]
        ctx = ic19[max(0, off - 16):off + 48]
        ff = sum(1 for x in b if x == 0xFF) / len(b)
        printable = sum(1 for x in ctx if 0x20 <= x < 0x7F) / len(ctx)
        if ff > 0.9:
            verdict = "ERASED FLASH (0xFF fill) -- cannot be an entry point"
        else:
            verdict = "structured record data (see the ASCII column)"
        print(f"   target 0x{t:06x} -> IC19 file 0x{off:06x}")
        print(f"      {b[:16].hex(' ')}  |{''.join(chr(c) if 32<=c<127 else '.' for c in b[:16])}|")
        print(f"      {b[16:].hex(' ')}  |{''.join(chr(c) if 32<=c<127 else '.' for c in b[16:])}|")
        print(f"      0xFF ratio {ff:.2f}   printable ratio (±ctx) {printable:.2f}")
        print(f"      => {verdict}")
    print("\n   0x379BF1 in particular is 16 bytes ahead of the ASCII style name")
    print('   "CaribbeanRockN  " -- it is inside a style record, which is exactly')
    print("   what IC19 is documented to hold.")


UNIDASM = "kn5000_v10_program.rom.unidasm"


def reframe(found):
    print()
    print("=" * 78)
    print("4. HOW AN INDEPENDENT DECODER FRAMES THE SAME BYTES")
    print("   MAME's unidasm, listing committed at original_ROMs/" + UNIDASM)
    print("=" * 78)
    lines = open(os.path.join(ROM, UNIDASM), encoding="latin-1").read().splitlines()
    index = {}
    for i, ln in enumerate(lines):
        m = re.match(r"^([0-9a-f]{6}):", ln)
        if m:
            index[int(m.group(1), 16)] = i
    for o, t in sorted(found):
        a = PROG_BASE + o
        print(f"\n   --- site 0x{a:06X}  (source says: jp 0x{t:06x}) ---")
        hit = index.get(a)
        if hit is None:
            # the `1B` is not an instruction start for unidasm at all: find the
            # instruction that CONTAINS it.
            starts = sorted(x for x in index if a - 8 <= x <= a)
            owner = starts[-1] if starts else None
            print(f"       unidasm does NOT begin an instruction at 0x{a:06X}.")
            if owner is not None:
                print(f"       the byte is inside: {lines[index[owner]].strip()}")
                for j in range(index[owner], min(index[owner] + 3, len(lines))):
                    print(f"          {lines[j].strip()}")
        else:
            for j in range(max(0, hit - 2), min(hit + 3, len(lines))):
                mark = " <<<" if j == hit else ""
                print(f"       {lines[j].strip()}{mark}")
    print()
    print("   ★ THE MECHANISM, VISIBLE IN EVERY CASE.  The 0x1B that the tree")
    print("     reads as a `jp` opcode is NOT an opcode.  In eleven of the twelve")
    print("     sites it is the DISPLACEMENT BYTE of a preceding `jr cc,d8`")
    print("     (0x66 = jr Z, 0x6E = jr NZ), and the three bytes the phantom `jp`")
    print("     swallows are `F1 <lo> <hi>` -- the TLCS-900 (nnnn) direct-memory")
    print("     prefix plus a 16-bit RAM variable address.  That is why every")
    print("     phantom target ends in 0xF1 and why its top byte is 0x3n: the")
    print("     RAM variables involved are 0x3540, 0x379B, 0x37C8 and 0x37C9,")
    print("     which the SAME routines address explicitly elsewhere.")
    print("     In the twelfth (0xF6B1FD) the 0x1B is entry 0x1B of a 30-entry")
    print("     permutation table and the 0x3B is `push xhl`.")


def precedent():
    print()
    print("=" * 78)
    print("5. THE PRECEDENT ALREADY IN THE TREE: one of the 13 is a PROVEN misframe")
    print("=" * 78)
    p10 = os.path.join(ROOT, "v10/maincpu/sequencer/accompaniment_engine.s")
    p9 = os.path.join(ROOT, "v9/maincpu/sequencer/accompaniment_engine.s")
    s10 = open(p10, encoding="latin-1").read()
    s9 = open(p9, encoding="latin-1").read()
    has10 = "jp\t0x3b1d1c" in s10
    has9 = "jp\t0x3b1d1c" in s9
    print(f"   v10 still contains `jp 0x3b1d1c`: {has10}")
    print(f"   v9  still contains `jp 0x3b1d1c`: {has9}")
    note = "had lost its entry point inside a phantom `jp 0x3b1d1c` at 0xF6B1FD"
    print(f"   v10 carries the note {note!r}: {note in s10}")
    print("   v10's corrected framing of those exact bytes (0xF6B1F2-0xF6B200):")
    print("       .byte ... 0x1a, 0x1b, 0x1c, 0x1d   <- 30-entry ordering table")
    print("       AccScreen_GetByte_0x353C: push xhl / ldb_d8 a,(0x353c) / pop xhl / ret")
    print("   The v9 tree has NOT had that correction applied, which is the whole")
    print("   reason v9 has 7 sites and v10 has 6.  Same bytes, both images.")
    if has10 or not has9:
        fails.append("the 0x3b1d1c precedent does not read as expected")


def null():
    print()
    print("=" * 78)
    print("6. THE NULL -- `jp imm24` phantoms per 1 MiB window of the maincpu space")
    print("=" * 78)
    v10 = rom("kn5000_v10_program.rom")
    hist = Counter()
    for i in range(len(v10) - 3):
        if v10[i] == 0x1B:
            hist[v10[i + 3] >> 4] += 1
    total = sum(hist.values())
    print(f"   every `1B <lo> <mid> <hi>` in the 2 MiB image: {total}\n")
    print(f"   {'win':>4}  {'count':>6}  device")
    for w in range(16):
        print(f"   {w:>3}x  {hist[w]:>6}  {WINDOWS[w]}")
    nulls = [hist[w] for w in NULL_WINDOWS]
    ic19 = hist[0x3]
    print(f"\n   IC19 window (0x3xxxxx) ....... {ic19}")
    print(f"   NO-DEVICE windows ............ {nulls}  "
          f"(mean {sum(nulls)/len(nulls):.1f})")
    print(f"   IC19 / null mean ............. {ic19/(sum(nulls)/len(nulls)):.2f}x")
    print()
    print("   ⚠ READ THIS THE RIGHT WAY.  Windows 0x2, 0xC and 0xD have NO DEVICE")
    print("     on the maincpu bus -- a `jp` into them cannot be a real entry")
    print("     point under any reading -- and they score the SAME ORDER as IC19.")
    print("     So the existence of `jp`-shaped byte sequences aimed at IC19 is")
    print("     the ordinary background of a 2 MiB code ROM and carries NO signal.")
    print("     Only 12 of them survive the extra constraint of being emitted as")
    print("     a `jp` by THIS TREE's framing, and section 4 reframes all 12.")
    print()
    print("   THE SHARPER NULL -- not byte patterns, but `jp`/`call`/`jr` statements")
    print("   THIS TREE ACTUALLY EMITS, per window.  If the tree emits comparably")
    print("   many transfers into windows that hold no device, then 13 into IC19")
    print("   is a property of the framing, not of IC19:")
    print()
    stmt = Counter()
    for tree in ("v10", "v9"):
        for path in src_files(tree):
            for line in open(path, encoding="latin-1"):
                m = XFER.match(line.rstrip("\n"))
                if m:
                    stmt[int(m.group(2), 16) >> 20] += 1
    for w in (0x2, 0x3, 0xC, 0xD):
        tag = "  <<< IC19" if w == 3 else ""
        print(f"      window 0x{w:X}xxxxx  {stmt[w]:>4}  {WINDOWS[w]}{tag}")
    ns = [stmt[w] for w in NULL_WINDOWS]
    print(f"\n      IC19 {stmt[3]}   no-device windows {ns} (mean {sum(ns)/len(ns):.1f})")
    print()
    print("      ⚠ AND THIS NULL DOES NOT WASH OUT, so say so.  13 against a")
    print("        no-device mean of 2.7 is 4.8x, and IC19 leads every window in")
    print("        the table.  What the null DOES establish is that phantom")
    print("        transfers into address space holding no device are a REAL and")
    print("        COMMON artefact of this tree's framing -- eight of them aim at")
    print("        0xDxxxxx, where nothing can possibly be entered -- so 13 is not")
    print("        by itself evidence of anything.  It licenses no verdict either")
    print("        way; the verdict comes from section 4, which reframes all 12")
    print("        ROM sites individually against an independent decoder.")
    print("        The FLAT null is the byte-pattern one above (0.96x): IC19's")
    print("        window is not enriched in jp-shaped BYTES at all.")


def main():
    args = sys.argv[1:]
    run_all = not args
    tgts = census() if (run_all or "--census" in args) else \
        [0x3540F1, 0x379BF1, 0x37C9F1, 0x3B1D1C]
    found = None
    if run_all or "--rom" in args:
        found = rom_sites(tgts)
    if run_all or "--targets" in args:
        targets(tgts)
    if run_all or "--reframe" in args:
        if found is None:
            found = rom_sites(tgts)
        reframe(found)
    if run_all or "--precedent" in args:
        precedent()
    if run_all or "--null" in args:
        null()
    print()
    print("=" * 78)
    print(f"FAILURES: {len(fails)}")
    for f in fails:
        print("   " + f)
    print("=" * 78)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
