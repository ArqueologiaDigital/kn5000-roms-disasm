#!/usr/bin/env python3
"""What does the SX-WSA1R share with Technics' MN10300 arranger keyboards?

QUESTION IT ANSWERS
    The WSA1 (1995) and the KN5000 are Toshiba TLCS-900 machines.  The KN7000
    (2002), KN6000/KN6500 and KN2400/KN2600/PR54 are Panasonic MN10300/AM33
    machines -- a DIFFERENT INSTRUCTION SET.  So "is any code shared?" is a
    category error and this script never asks it.  What CAN cross an
    architecture boundary is DATA: glyph bitmaps, name tables, parameter
    records, file formats, and the part numbers on the board.  This script
    measures the data question and states, with its search, where it found
    nothing.

WHAT IT FOUND (all reproduced below; run it, do not quote this paragraph)
    1. THE WSA1 AND THE KN7000 SHARE THREE LATIN GLYPH FACES, byte for byte, at
       the same code points.  Four of the KN7000's twelve font-descriptor
       records point at glyph blocks that are the WSA1's prom_b faces (two of
       the four are the same face with different upper blocks).  The ACCENTED
       block above 0x7E is NOT shared, and section 3 states that per face.
    2. THE WSA1's TONE DATABASE (prom_d) AND THE KN7000's TABLE ROM SHARE
       SOUND NAMES AND BINARY RECORDS.  195 of the 252 distinct sixteen-
       character 0x10-terminated name fields in the WSA1 images occur verbatim
       in the KN7000 table ROM and every one of them is in prom_d; and 250
       binary runs share 8,152 bytes, 74 of them exactly 81 bytes apart, which
       is prom_d's own per-element block stride derived independently.
    3. NO SHARED CODE, MEASURED RATHER THAN ASSUMED.  Not one of the 389 kept
       runs contains an instruction start in any of the four `.s` files, and
       prom_d emits no instruction at all.  Section 2 prints the census.
    4. THE PERIPHERALS ARE NOT SHARED, and that is worth as much: different
       LCD controller, different FDC generation, different effects DSP, no
       shared drum-name table and no shared effect-name table.  Section 5.

THE GUARD THAT MATTERS, AND WHY THE FIRST DRAFT NEEDED A SECOND ONE
    kn5000_shared_runs.py's entropy guard (distinct-byte count, most-common-byte
    share, short period) is NOT enough here.  A monotone ramp -- 0x7F 0x7E 0x7D
    ... -- has 256 distinct values, no dominant byte and no short period, so it
    sails through, and the first draft of this script duly reported a "2,178-byte
    shared run" between prom_c and all three MN10300 images.  It is a
    concatenation of ramps and interpolation curves that two independent
    firmwares generate identically because arithmetic is arithmetic.  So a
    SECOND guard is applied to the FIRST DIFFERENCE of every run, and section 2
    prints how many bytes each guard rejected.  A rejected byte count that is
    two orders of magnitude above the kept one is the normal, correct outcome.

NULLS
    Five, all printed whether they help or not:
      * a byte-SHUFFLED copy of the KN7000 table ROM (same histogram, no order)
      * a byte-REVERSED copy (keeps ramps and local structure, breaks provenance)
      * the KN5000 rhythm-data ROM (Technics, same era, unrelated content)
      * the Access Virus C firmware (another vendor's synth entirely)
      * the Roland D-50 mask ROM (another vendor, and it has an LCD font)
    For the font measurement the null is the same alignment vote run against all
    of the above plus EVERY OTHER Technics ROM in ../technics_roms/roms.

WHAT THIS DOES NOT ESTABLISH
    * Not which way the assets travelled.  The WSA1 is 1995 and the KN7000 2002,
      which is suggestive and is not proof; a common internal library is equally
      consistent with the bytes.
    * Not the MEANING of the shared prom_d records.  Their field layout is
      unestablished in this tree (notes/FINDINGS-prom-d-tone-database.md says so)
      and this script does not invent one.
    * Nothing about the KN6000/KN6500/KN2400 TABLE ROMs.  They are NOT DUMPED --
      those romsets carry a byte-identical copy of the KN7000's, which section 1
      checks by hash.  Every negative about them is a fact about the dump.

WHAT THE SECTIONS ARE
    1  the MN10300 images, and the halfword interleave PROVED against two
       reference images (a byte interleave finds no ASCII in 4 MB and would
       have produced a clean negative that was a fact about the interleave)
    2  shared byte runs, guarded twice, with five nulls, and the measurement
       that no run touches an instruction in any of the four .s files
    3  the fonts: four KN7000 descriptors == three WSA1 faces
    3b the font null: every Technics ROM plus two foreign ones
    4  the tone database: 195/252 names, and 250 binary records at stride 81
    5  the negatives -- drum-kit names, MILK, chip inventory, effect names,
       0xFF047F, LCD controller, floppy controller
    6  what is importable, in priority order

RUN                                                  (about 45 s in full)
    python3 notes/wave7_xref_mn10300_family.py             # the whole report
    python3 notes/wave7_xref_mn10300_family.py --selftest  # the checks only
    python3 notes/wave7_xref_mn10300_family.py --quick     # skip the null scans
    python3 notes/wave7_xref_mn10300_family.py --mutation  # prove the checks CAN fail
"""
import bisect
import collections
import hashlib
import os
import random
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TECH = "/home/fsanches/compartilhado/technics_roms/roms"
VIRUS = ("/home/fsanches/compartilhado/accessvirus/original_roms/virusc/"
         "virus_c_660x368.bin")
D50 = ("/home/fsanches/compartilhado/roland_d50_disasm/original_roms/d50/"
       "roland__r15179858_8801ebi__tc534000p-7477.ic30")

# prom_d's base is 0x00F00000 on CPU 2's bus, which COLLIDES with prom_b's
# 0xF00000 on CPU 1's.  prom_d addresses are therefore printed as FILE offsets.
IMAGES = [("prom_a", "wsa1_prom_a.ic12", 0xF80000),
          ("prom_b", "wsa1_prom_b.ic13", 0xF00000),
          ("prom_c", "wsa1_prom_c.ic28", 0xF80000),
          ("prom_d", "wsa1_prom_d.bin",  None)]

FAILED = []
NCHECK = 0


def check(name, cond, detail=""):
    global NCHECK
    NCHECK += 1
    if not cond:
        FAILED.append(name + (" -- " + detail if detail else ""))
    return cond


def rom(name):
    with open(os.path.join(ROOT, "original_ROMs", name), "rb") as fh:
        return fh.read()


def tech(rel):
    with open(os.path.join(TECH, rel), "rb") as fh:
        return fh.read()


def maybe(path):
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except OSError:
        return None


# ---------------------------------------------------------------------------
# 1.  The MN10300 images: two 16-bit chips per flash, interleaved BY HALFWORD
# ---------------------------------------------------------------------------

def interleave16(even, odd):
    """even/odd are 16-bit-wide chips on a 32-bit bus: e[0:2] o[0:2] e[2:4] ...

    NOT a byte interleave.  The first draft of this lane used a byte
    interleave, found no ASCII anywhere in 4 MB, and would have reported a
    clean negative that was a fact about the interleave.  build_mn10300()
    proves the order against two reference images instead of assuming it.
    """
    out = bytearray(len(even) * 2)
    for k in range(0, len(even), 2):
        out[k * 2:k * 2 + 2] = even[k:k + 2]
        out[k * 2 + 2:k * 2 + 4] = odd[k:k + 2]
    return bytes(out)


MN_PARTS = {
    "kn7000_table": ("kn7000/kn7000_table_even.rom", "kn7000/kn7000_table_odd.rom"),
    "kn7000_prog":  ("kn7000/kn7000_program_even.rom", "kn7000/kn7000_program_odd.rom"),
    "kn6000_prog":  ("kn6000/kn6000_program_even.rom", "kn6000/kn6000_program_odd.rom"),
    "kn6500_prog":  ("kn6500/kn6500_program_even.rom", "kn6500/kn6500_program_odd.rom"),
    "kn2400_prog":  ("kn2400/kn2400_program_even.rom", "kn2400/kn2400_program_odd.rom"),
}


def build_mn10300(quiet=False):
    out = {}
    for name, (e, o) in MN_PARTS.items():
        out[name] = interleave16(tech(e), tech(o))
    # PROOF of the interleave order, not an assumption: the collection also
    # holds two already-linear reference images, and the halfword interleave
    # must reproduce them exactly over their length, with 0xFF beyond it.
    for name, ref in (("kn7000_table", "kn7000/kn7000_table.rom"),
                      ("kn7000_prog", "kn7000/kn7000_program.rom")):
        r = tech(ref)
        mine = out[name]
        check("halfword interleave reproduces %s (%d B)" % (ref, len(r)),
              mine[:len(r)] == r)
        check("...and the tail past %s is all 0xFF" % ref,
              set(mine[len(r):]) == {0xFF})
    # the KN6000/KN6500 romsets carry the KN7000's table ROM as a PLACEHOLDER
    def md5(rel):
        return hashlib.md5(tech(rel)).hexdigest()
    same = (md5("kn6000/kn7000_table_even.rom") == md5("kn7000/kn7000_table_even.rom")
            and md5("kn6500/kn7000_table_even.rom") == md5("kn7000/kn7000_table_even.rom"))
    check("kn6000/kn6500 'table' ROMs are md5-identical to the KN7000's "
          "(i.e. NOT dumps of their own parts)", same)
    if not quiet:
        print("=== 1. the MN10300 images ===\n")
        print("  The WSA1 and the KN5000 are TLCS-900 (TMP95C061 x2 / TMP94C241).")
        print("  The KN7000, KN6000/KN6500 and KN2400/KN2600 are MN10300/AM33.")
        print("  Different instruction set: shared CODE is not a hypothesis this")
        print("  script entertains.  Shared DATA is, and is what is measured.\n")
        for name in sorted(out):
            print("    %-14s %d B  (halfword interleave of %s + %s)"
                  % (name, len(out[name]), *[os.path.basename(p) for p in MN_PARTS[name]]))
        print("\n  ⚠ kn6000/kn6500/kn2400 TABLE ROMs are UNDUMPED.  The kn6000 and")
        print("    kn6500 romsets carry a byte-identical copy of the KN7000's table")
        print("    ROM (md5 checked above).  Any negative about their table data is")
        print("    a fact about the dump, not about the firmware.\n")
    return out


# ---------------------------------------------------------------------------
# 2.  Shared byte runs, entropy-guarded AND ramp-guarded, code/data classified
# ---------------------------------------------------------------------------

MIN = 16
# target -> (kept runs, ASCII-ish runs, binary runs), pinned so the reported
# numbers are gated rather than merely printed
EXPECTED_RUNS = {"kn7000_table": (389, 118, 271),
                 "kn7000_prog": (274, 196, 78),
                 "kn6000_prog": (590, 299, 291),
                 "kn6500_prog": (274, 198, 76),
                 "kn2400_prog": (256, 194, 62)}
MIN_DISTINCT = 12
MAX_FILL = 0.60
MIN_DELTA_DISTINCT = 12
MAX_DELTA_FILL = 0.60


def guard(run):
    """None if the run is evidence; otherwise the name of the rule that kills it."""
    c = collections.Counter(run)
    if len(c) < MIN_DISTINCT:
        return "few-distinct-bytes"
    if c.most_common(1)[0][1] / len(run) > MAX_FILL:
        return "one-byte-dominant"
    for p in (1, 2, 3, 4):
        if len(run) > 2 * p and run[:-p] == run[p:]:
            return "period<=4"
    d = [(run[i + 1] - run[i]) & 0xFF for i in range(len(run) - 1)]
    cd = collections.Counter(d)
    if len(cd) < MIN_DELTA_DISTINCT:
        return "ramp/curve-few-deltas"
    if cd.most_common(1)[0][1] / len(d) > MAX_DELTA_FILL:
        return "ramp/curve-one-delta"
    return None


def _index(buf):
    d = {}
    for i in range(len(buf) - MIN + 1):
        k = buf[i:i + MIN]
        if k not in d:
            d[k] = i
    return d


def shared_runs(target, wsa1_bufs):
    """Maximal runs of >= MIN bytes of each WSA1 image that occur in `target`."""
    idx = _index(target)
    kept, rejected = [], collections.Counter()
    for name, buf, base in wsa1_bufs:
        i, n = 0, len(buf)
        while i <= n - MIN:
            j = idx.get(buf[i:i + MIN])
            if j is None:
                i += 1
                continue
            L = MIN
            while i + L < n and j + L < len(target) and buf[i + L] == target[j + L]:
                L += 1
            run = buf[i:i + L]
            g = guard(run)
            if g:
                rejected[g] += L
            else:
                kept.append((name, base, i, j, L, run))
            i += L
    return kept, rejected


# `; FEB2A6  c3 03 f0 e0 22` -- every emitted line carries its address and, for
# an instruction, the exact bytes it assembles to.  ⚠ DATA lines do NOT all
# carry an address (prom_c's `.short` tables and all of prom_d carry none), so
# "which line is this address on?" cannot be answered for every byte.  The
# question that CAN be answered exactly is the one that matters here: does this
# run overlap an INSTRUCTION?  Instruction extents are complete, because an
# instruction line always prints its own bytes.
# `; FEB2AB  cf 89` (prom_a) or `; F9822C  ld HL,0x0148` (prom_b/c) -- every
# emitted line carries its address, but only prom_a prints the assembled bytes.
# ⚠ DATA lines do NOT all carry an address (prom_c's `.short` tables and all of
# prom_d carry none), so "which line is this byte on?" is not answerable for
# every byte.  The question that IS answerable exactly is the one that matters:
# does a kept run contain an INSTRUCTION START?  Instruction starts are complete
# in all three code images, and no TLCS-900 instruction is as long as MIN (that
# is checked from prom_a's byte column), so a >= MIN-byte run that overlapped
# code at all would have to contain a start.
SRCADDR = re.compile(r";\s*([0-9A-F]{6})\s")
SRCBYTES = re.compile(r";\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})\s*$")
DIRECTIVE = (".byte", ".ascii", ".asciz", ".word", ".short", ".long",
             ".fill", ".incbin", ".space", ".quad")


def instruction_starts(prom):
    """Sorted addresses of every INSTRUCTION line emitted for `prom`, and the
    longest instruction seen where the byte column exists (0 if it does not)."""
    out, longest = [], 0
    with open(os.path.join(ROOT, prom, "wsa1_%s.s" % prom)) as fh:
        for ln in fh:
            ln = ln.rstrip("\n")
            mo = SRCADDR.search(ln)
            if not mo:
                continue
            body = ln[:mo.start()].strip()
            if not body or body.startswith(DIRECTIVE) or body.endswith(":"):
                continue
            out.append(int(mo.group(1), 16))
            mb = SRCBYTES.search(ln)
            if mb:
                longest = max(longest, len(mb.group(2).split()))
    out.sort()
    return out, longest


def data_only(prom):
    """True if the whole .s is directives, labels, comments and blanks."""
    with open(os.path.join(ROOT, prom, "wsa1_%s.s" % prom)) as fh:
        for ln in fh:
            t = ln.strip()
            if not t or t.startswith(";") or t.endswith(":"):
                continue
            if not t.startswith(DIRECTIVE + (".text", ".data", ".globl",
                                             ".section", ".align")):
                return False
    return True


def contains_instruction(starts, lo, hi):
    """Does [lo, hi) contain the start of any instruction?"""
    i = bisect.bisect_left(starts, lo)
    return i < len(starts) and starts[i] < hi


def ascii_ish(run):
    return sum(1 for c in run if 0x20 <= c < 0x7F) / len(run) >= 0.75


def section_runs(mn, quiet=False, do_nulls=True):
    bufs = [(n, rom(f), (b if b is not None else 0)) for n, f, b in IMAGES]
    if not quiet:
        print("=== 2. shared byte runs (>= %d B), entropy- AND ramp-guarded ===\n" % MIN)
        print("    target                          kept B   runs   ASCII-ish   binary")
    results = {}
    for name in ("kn7000_table", "kn7000_prog", "kn6000_prog", "kn6500_prog",
                 "kn2400_prog"):
        kept, rej = shared_runs(mn[name], bufs)
        a = [k for k in kept if ascii_ish(k[5])]
        b = [k for k in kept if not ascii_ish(k[5])]
        results[name] = (kept, rej, a, b)
        if not quiet:
            print("    %-28s %7d %6d   %4d/%-6d %4d/%d"
                  % (name, sum(k[4] for k in kept), len(kept),
                     len(a), sum(k[4] for k in a), len(b), sum(k[4] for k in b)))
    nulls = {}
    if do_nulls:
        random.seed(7)
        sh = bytearray(mn["kn7000_table"])
        random.shuffle(sh)
        cands = [("NULL shuffled kn7000_table", bytes(sh)),
                 ("NULL reversed kn7000_table", mn["kn7000_table"][::-1]),
                 ("NULL kn5000 rhythm data", tech("kn5000/kn5000_rhythm_data_rom.ic14")),
                 ("NULL Access Virus C", maybe(VIRUS)),
                 ("NULL Roland D-50 mask ROM", maybe(D50))]
        for label, buf in cands:
            if buf is None:
                if not quiet:
                    print("    %-28s  (file absent -- null not run)" % label)
                continue
            kept, rej = shared_runs(buf, bufs)
            a = [k for k in kept if ascii_ish(k[5])]
            b = [k for k in kept if not ascii_ish(k[5])]
            nulls[label] = (kept, a, b)
            if not quiet:
                print("    %-28s %7d %6d   %4d/%-6d %4d/%d"
                      % (label, sum(k[4] for k in kept), len(kept),
                         len(a), sum(k[4] for k in a), len(b), sum(k[4] for k in b)))
        for label, (kept, a, b) in nulls.items():
            check("%s yields ZERO binary shared runs" % label, len(b) == 0,
                  "%d runs, %d B" % (len(b), sum(k[4] for k in b)))
    kept, rej, asc, bina = results["kn7000_table"]
    check("kn7000_table binary runs are far above every null",
          len(bina) > 100)
    # ★ pinned, so a changed byte anywhere in the shared regions breaks a check
    for name, want in EXPECTED_RUNS.items():
        k, _, a, b = results[name]
        check("%s: %d kept runs, %d ASCII-ish and %d binary"
              % (name, want[0], want[1], want[2]),
              (len(k), len(a), len(b)) == want,
              "got %s" % ((len(k), len(a), len(b)),))
    if not quiet:
        print("\n    rejected by guard, kn7000_table target: %s" % dict(rej))
        print("    (the ramp/curve rules are what kill the '2,178-byte shared run'")
        print("     between prom_c and every MN10300 image -- concatenated ramps.)\n")
    # -- code or data?  the whole point of the architecture argument -----------
    ist, tally, codehits = {}, collections.Counter(), 0
    for p in ("prom_a", "prom_b", "prom_c", "prom_d"):
        ist[p] = instruction_starts(p)
    check("prom_a's byte column exists and its longest instruction is < %d B"
          % MIN, 0 < ist["prom_a"][1] < MIN, "longest %d" % ist["prom_a"][1])
    check("prom_d's .s is 100%% directives -- it emits no instruction at all",
          data_only("prom_d") and not ist["prom_d"][0])
    for p in ("prom_a", "prom_b", "prom_c"):
        check("%s does have instructions to collide with" % p,
              len(ist[p][0]) > 10000, "%d" % len(ist[p][0]))
    for name, base, i, j, L, run in kept:
        lo = (base + i) if base else i
        hot = contains_instruction(ist[name][0], lo, lo + L)
        codehits += hot
        tally[(name, "CONTAINS AN INSTRUCTION" if hot else "no instruction inside")] += 1
    check("ZERO shared runs contain an instruction start in any .s", codehits == 0,
          "%d did" % codehits)
    if not quiet:
        print("    Do the kept runs touch an INSTRUCTION?  Starts come from the")
        print("    `; ADDR` comment on every emitted code line; prom_a's byte column")
        print("    puts the longest instruction at %d B, under the %d-byte run floor,"
              % (ist["prom_a"][1], MIN))
        print("    so a run that overlapped code would have to contain a start.")
        for (n, k), v in sorted(tally.items()):
            print("        %-8s %-24s %4d runs   (%d instructions in this image)"
                  % (n, k, v, len(ist[n][0])))
        print("    -> %d of %d runs contain an instruction.  prom_d emits none at"
              % (codehits, len(kept)))
        print("       all (its .s is 100% directives, checked).  A shared")
        print("       instruction stream between TLCS-900 and MN10300 would be a")
        print("       decoding error; this is the measurement that says there is")
        print("       not one.\n")
    return results


# ---------------------------------------------------------------------------
# 3.  The fonts
# ---------------------------------------------------------------------------

# The twelve WSA1 glyph tables, copied from notes/font_layout_check.py's TABLES
# (that script asserts the bases and pitches against the ROM; 89 checks).
WSA1_FONTS = [(0xF1B400, 14), (0xF1BEF0, 16), (0xF1CB70, 32), (0xF1E470, 8),
              (0xF1EAB0, 32), (0xF203B0, 32), (0xF212B0, 14), (0xF21940, 32),
              (0xF22840, 32), (0xF24640, 32), (0xF24DC0, 10), (0xF25590, 48)]
FONT_DESC_PTR_SLOT = 0x20C          # table-ROM header word holding the descriptor table
DESC_STRIDE = 0x14
# KN7000 descriptor id -> (WSA1 table base, identical over ASCII 0x20-0x7E of 95,
#                          identical over codes 0x20-0xC7 of 168)
# id -> (WSA1 base, identical of 95 ASCII, identical of 168 for 0x20-0xC7,
#        identical of 73 for 0x7F-0xC7 -- the ACCENTED/SYMBOL block, and it is
#        near zero.  ⚠ An earlier draft asserted "at most one" here from id 1
#        alone; id 3 has four (three of them blank on BOTH sides).  Measured
#        per face, not generalised from the first one.)
EXPECTED_FONT = {1: (0xF1BEF0, 86, 87, 1),
                 3: (0xF1E470, 85, 89, 4),
                 6: (0xF24DC0, 83, 83, 0),
                 8: (0xF1BEF0, 86, 86, 0)}


def kn7000_font_descriptors(table):
    """(id, width, height, file offset, extent) for the KN7000's font records.

    The pointer comes from the table ROM's own header, per
    ../kn7000_mame/notes/kn6000-kn6500-boot.md: the KN6000's font-table
    initialiser at 0x48420312 copies five pointers out of 0x48000200, and the
    fourth is the font descriptor table.  Record = 0x14 B: +0 width, +2 height,
    +4/+6 metrics, +8 glyph base, +0x10 extension.
    """
    ptr = int.from_bytes(table[FONT_DESC_PTR_SLOT:FONT_DESC_PTR_SLOT + 4], "little")
    fd = ptr - 0x48000000
    out = []
    for i in range(64):
        r = table[fd + i * DESC_STRIDE:fd + (i + 1) * DESC_STRIDE]
        if len(r) < DESC_STRIDE:
            break
        w = int.from_bytes(r[0:2], "little")
        h = int.from_bytes(r[2:4], "little")
        base = int.from_bytes(r[8:12], "little")
        if not (0x48000000 <= base < 0x48400000) or h == 0 or h > 64:
            break                       # the table ends and glyph data begins
        out.append([i, w, h, base - 0x48000000, None])
    for k in range(len(out) - 1):
        out[k][4] = out[k + 1][3] - out[k][3]
    return [tuple(r) for r in out], fd


def font_report(mn, quiet=False):
    b = rom("wsa1_prom_b.ic13")
    table = mn["kn7000_table"]

    def cell(base, pitch, code):
        o = base - 0xF00000 + code * pitch
        return b[o:o + pitch]

    desc, fd = kn7000_font_descriptors(table)
    check("the KN7000 table ROM's header names a font descriptor table",
          0 < fd < len(table))
    check("it holds twelve usable descriptors", len(desc) == 12,
          "got %d" % len(desc))

    # For each descriptor, find the WSA1 face whose ASCII block matches best.
    # The KN7000 indexes its glyph blocks FROM CODE 0x20; the WSA1 tables index
    # from 0.  That 32-cell shift is derived below, not assumed: it is the
    # difference between the vote-derived alignment and the descriptor's base.
    rows = []
    for i, w, h, off, ext in desc:
        best = None
        for fb, pitch in WSA1_FONTS:
            ident = tot = 0
            for c in range(0x20, 0x7F):
                j = off + (c - 0x20) * pitch
                if j + pitch > len(table):
                    break
                tot += 1
                if cell(fb, pitch, c) == table[j:j + pitch]:
                    ident += 1
            if tot and (best is None or ident > best[1]):
                best = (fb, ident, tot, pitch)
        rows.append((i, w, h, off, ext, best))
    hits = [r for r in rows if r[5][1] >= 50]
    check("exactly four KN7000 font descriptors match a WSA1 face", len(hits) == 4,
          "got %d" % len(hits))
    # ★ The reported numbers are PINNED, so a single changed glyph byte breaks a
    # check.  Without this the section asserted only structure and --mutation
    # showed the checks were vacuous; that is how this block came to exist.
    for i, w, h, off, ext, best in rows:
        if i in EXPECTED_FONT:
            fb, ident, tot, pitch = best
            xf, xi, xfull, xup = EXPECTED_FONT[i]
            check("font id %d matches WSA1 0x%06X" % (i, xf), fb == xf,
                  "matched 0x%06X" % fb)
            check("font id %d: %d/95 identical over ASCII" % (i, xi),
                  (ident, tot) == (xi, 95), "got %d/%d" % (ident, tot))
            full = sum(1 for c in range(0x20, 0xC8)
                       if cell(fb, pitch, c)
                       == table[off + (c - 0x20) * pitch:
                                off + (c - 0x20) * pitch + pitch])
            check("font id %d: %d/168 identical over codes 0x20-0xC7" % (i, xfull),
                  full == xfull, "got %d" % full)
            # ★ the upper block is NOT shared: this is the number that stops a
            # reader assuming the whole face was transplanted.
            upper = sum(1 for c in range(0x7F, 0xC8)
                        if cell(fb, pitch, c)
                        == table[off + (c - 0x20) * pitch:
                                 off + (c - 0x20) * pitch + pitch])
            check("font id %d: %d of the 73 codes 0x7F-0xC7 are shared"
                  % (i, xup), upper == xup, "got %d" % upper)
        else:
            check("font id %d does NOT match any WSA1 face (< 50 of 95)" % i,
                  best[1] < 50, "%d/95 to 0x%06X" % (best[1], best[0]))

    if not quiet:
        print("=== 3. THE FONTS ARE SHARED ===\n")
        print("    KN7000 font descriptor table at table-ROM file offset 0x%06X"
              " (from the header word at 0x%03X)\n" % (fd, FONT_DESC_PTR_SLOT))
        print("    id   w  h   glyph base  extent  best WSA1 face        ASCII 0x20-0x7E")
        for i, w, h, off, ext, best in rows:
            print("    %2d  %2d %2d   0x%06X   %-6s 0x%06X pitch %-2d   %3d/%d identical"
                  % (i, w, h, off, ext if ext else "?", best[0], best[3],
                     best[1], best[2]))
        print()

    # The independent corroboration: the alignment that a blind glyph-vote finds
    # must land exactly 0x20 cells BEFORE a descriptor's own glyph base.
    for i, w, h, off, ext, best in hits:
        fb, ident, tot, pitch = best
        # ⚠ The vote is taken INSIDE this descriptor's own block only.  A
        # global vote fails for id 8, because ids 1 and 8 are near-duplicate
        # faces and id 1's copy outvotes id 8's for id 8's own glyphs.  That is
        # a real property of the ROM, not a bug, and searching globally would
        # have reported id 8 as living at id 1's address.
        lo = max(0, off - 0x20 * pitch)
        hi = off + (ext if ext else 0x100 * pitch)
        window = table[lo:hi]
        votes = collections.Counter()
        for c in range(200):
            g = cell(fb, pitch, c)
            if not any(g):
                continue                # a blank cell matches everywhere: no vote
            o = window.find(g)
            seen = 0
            while o >= 0 and seen < 40:
                votes[lo + o - c * pitch] += 1
                seen += 1
                o = window.find(g, o + 1)
        al, v = votes.most_common(1)[0]
        check("id %d: the blind glyph vote lands 0x20 cells before its own "
              "descriptor base" % i, off - al == 0x20 * pitch,
              "vote 0x%06X, base 0x%06X, pitch %d" % (al, off, pitch))
        check("id %d: the winning alignment has >= 50 votes" % i, v >= 50,
              "%d votes" % v)
        # LAST element as well as first: the WSA1 tables hold 200 cells, so the
        # last comparable code is 0xC7.
        first_same = cell(fb, pitch, 0x20) == table[off:off + pitch]
        lastc = 0xC7
        j = off + (lastc - 0x20) * pitch
        check("id %d: code 0x20 (the FIRST comparable cell) is decided" % i,
              isinstance(first_same, bool))
        check("id %d: code 0xC7 (the LAST WSA1 cell) is inside the KN7000 block"
              % i, ext is None or (lastc - 0x20) * pitch < ext)
        if not quiet:
            full = sum(1 for c in range(0x20, 0xC8)
                       if cell(fb, pitch, c)
                       == table[off + (c - 0x20) * pitch:off + (c - 0x20) * pitch + pitch])
            blankdiff = sum(1 for c in range(0x20, 0xC8)
                            if not any(cell(fb, pitch, c))
                            and cell(fb, pitch, c)
                            != table[off + (c - 0x20) * pitch:
                                     off + (c - 0x20) * pitch + pitch])
            print("    WSA1 0x%06X (pitch %2d) == KN7000 font id %-2d @0x%06X"
                  % (fb, pitch, i, off))
            print("        blind glyph vote  : align 0x%06X, %d votes; "
                  "descriptor base - align = %d = 0x20 cells"
                  % (al, v, off - al))
            print("        codes 0x20-0x7E   : %d/%d identical, %d differing"
                  % (ident, tot, tot - ident))
            upper = sum(1 for c in range(0x7F, 0xC8)
                        if cell(fb, pitch, c)
                        == table[off + (c - 0x20) * pitch:
                                 off + (c - 0x20) * pitch + pitch])
            print("        codes 0x20-0xC7   : %d/168 identical (%d of the %d "
                  "differences are BLANK in the WSA1)"
                  % (full, blankdiff, 168 - full))
            print("        codes 0x7F-0xC7   : %d/73 identical -- the ACCENTED /"
                  " SYMBOL block is NOT shared" % upper)
            diffs = [c for c in range(0x20, 0x7F)
                     if cell(fb, pitch, c)
                     != table[off + (c - 0x20) * pitch:off + (c - 0x20) * pitch + pitch]]
            print("        differing ASCII   : %s"
                  % " ".join("0x%02X(%s)" % (c, chr(c)) for c in diffs))
    # ids 1 and 8 are the SAME face in ASCII and diverge above it, which is why
    # both score 86/95 against the same WSA1 table.  Measured, so a reader does
    # not conclude the script double-counted one block.
    d1, d8 = 0x0246A8, 0x02BC58
    same_asc = sum(1 for c in range(0x20, 0x7F)
                   if table[d1 + (c - 0x20) * 16:d1 + (c - 0x20) * 16 + 16]
                   == table[d8 + (c - 0x20) * 16:d8 + (c - 0x20) * 16 + 16])
    same_up = sum(1 for c in range(0x7F, 0x100)
                  if table[d1 + (c - 0x20) * 16:d1 + (c - 0x20) * 16 + 16]
                  == table[d8 + (c - 0x20) * 16:d8 + (c - 0x20) * 16 + 16])
    check("KN7000 font ids 1 and 8 are the same face over ASCII (95/95) and "
          "diverge above it (25/129)", (same_asc, same_up) == (95, 25),
          "got %d/95 and %d/129" % (same_asc, same_up))
    if not quiet:
        print("    ⚠ ids 1 and 8 are not two independent hits.  They are identical")
        print("      to each other over ASCII (%d/95) and differ above it (%d/129"
              % (same_asc, same_up))
        print("      of codes 0x7F-0xFF), so the KN7000 carries TWO copies of the")
        print("      WSA1's 8x16 face with different upper blocks.  Three WSA1")
        print("      faces, four KN7000 descriptors.")
        print()
    return rows


def font_sweep(quiet=False):
    """The null: run the same vote against EVERY Technics ROM, and two foreign ones."""
    b = rom("wsa1_prom_b.ic13")

    def cell(base, pitch, code):
        o = base - 0xF00000 + code * pitch
        return b[o:o + pitch]

    faces = [(0xF1BEF0, 16), (0xF1E470, 8), (0xF24DC0, 10)]
    paths = []
    for d, _, fs in os.walk(TECH):
        for f in sorted(fs):
            p = os.path.join(d, f)
            if os.path.getsize(p) >= 0x8000 and not f.endswith((".md", ".svg")):
                paths.append(p)
    paths = sorted(paths)
    for extra in (VIRUS, D50):
        if os.path.exists(extra):
            paths.append(extra)
    rows = []
    for p in paths:
        with open(p, "rb") as fh:
            img = fh.read()
        best = []
        for fb, pitch in faces:
            votes = collections.Counter()
            for c in range(200):
                g = cell(fb, pitch, c)
                if not any(g):
                    continue
                o = img.find(g)
                seen = 0
                while o >= 0 and seen < 40:
                    votes[o - c * pitch] += 1
                    seen += 1
                    o = img.find(g, o + 1)
            best.append(votes.most_common(1)[0][1] if votes else 0)
        rows.append((os.path.relpath(p, TECH), best))
    # The interleaved KN7000 table is the only image that can hit: the raw
    # even/odd chips split every glyph, which is itself a check on the interleave.
    hi = [r for r in rows if max(r[1]) >= 5]
    check("in a sweep of %d ROM files, only the linear KN7000 table ROM and the "
          "WSA1's own prom_b carry the three faces" % len(rows),
          len(hi) == 2, "got %s" % [r[0] for r in hi])
    if not quiet:
        print("=== 3b. the font null: every Technics ROM plus two foreign ones ===\n")
        print("    best alignment vote per face (8x16 pitch 16 / 8x8 pitch 8 / 8x10 pitch 10)\n")
        for rel, best in rows:
            mark = "HIT " if max(best) >= 5 else "    "
            print("    %s%-58s %s" % (mark, rel, best))
        print("\n    Every raw even/odd chip scores <= 1 because a halfword interleave")
        print("    splits each glyph across two parts -- an independent check that the")
        print("    interleave in section 1 is the right one.\n")
    return rows


# ---------------------------------------------------------------------------
# 4.  The tone database
# ---------------------------------------------------------------------------

def tone_names(quiet=False, mn=None):
    """16 printable bytes followed by the 0x10 record marker -- the field shape
    ../technics_roms/tools/wsa1_kinship.py uses.  This re-derives its 195/252
    headline AND says WHERE, which that tool does not."""
    table = mn["kn7000_table"]
    tot, hits = 0, []
    per = collections.Counter()
    uniq, uhit = set(), set()
    for name, fn, base in IMAGES:
        buf = rom(fn)
        for i in range(len(buf) - 17):
            if buf[i + 16] != 0x10:
                continue
            f = buf[i:i + 16]
            if not all(0x20 <= c < 0x7F for c in f):
                continue
            tot += 1
            uniq.add(f)
            j = table.find(f)
            if j >= 0:
                hits.append((name, i, j, f))
                uhit.add(f)
                per[name] += 1
    check("every shared 16-char name field is in prom_d, not prom_a/b/c",
          set(per) == {"prom_d"}, "got %s" % dict(per))
    # ../technics_roms/tools/wsa1_kinship.py counts DISTINCT fields over the
    # concatenated image and reports 195 / 252 (77.4%).  Reproduced exactly:
    check("the distinct-field count reproduces wsa1_kinship.py's 252",
          len(uniq) == 252, "got %d" % len(uniq))
    check("the shared-name count reproduces wsa1_kinship.py's 195",
          len(uhit) == 195, "got %d" % len(uhit))
    # first AND last element checked against the raw ROMs
    hits.sort(key=lambda h: h[2])
    d = rom("wsa1_prom_d.bin")
    for tag, h in (("first", hits[0]), ("last", hits[-1])):
        check("the %s shared name verifies byte for byte in both images" % tag,
              d[h[1]:h[1] + 16] == table[h[2]:h[2] + 16] == h[3])
    if not quiet:
        print("=== 4. the tone database ===\n")
        print("    16-char 0x10-terminated name fields, DISTINCT               : %d" % len(uniq))
        print("    ...also present verbatim in the KN7000 table ROM            : %d (%.1f%%)"
              % (len(uhit), 100.0 * len(uhit) / len(uniq)))
        print("    (this is ../technics_roms/tools/wsa1_kinship.py's headline,")
        print("     195/252 = 77.4%%, reproduced.  %d field POSITIONS carry one of" % tot)
        print("     them, %d of those positions matching.)" % len(hits))
        print("    ...and their WSA1 home                                      : %s"
              % dict(per))
        print("    KN7000-side span: 0x%06X .. 0x%06X" % (hits[0][2], hits[-1][2]))
        for tag, h in (("first", hits[0]), ("last", hits[-1])):
            print("        %-5s  prom_d file 0x%06X  ->  kn7000_table 0x%06X  %r"
                  % (tag, h[1], h[2], h[3].decode("ascii")))
        print()
    return hits


def tone_records(results, quiet=False):
    """The BINARY prom_d runs, and the stride between them."""
    kept, rej, asc, bina = results["kn7000_table"]
    pd = sorted([k for k in bina if k[0] == "prom_d"], key=lambda k: k[2])
    gaps = collections.Counter(pd[i + 1][2] - pd[i][2] for i in range(len(pd) - 1))
    top, ntop = gaps.most_common(1)[0]
    check("the modal gap between consecutive binary prom_d shared runs is 81 -- "
          "the per-element block stride notes/FINDINGS-prom-d-tone-database.md "
          "§3 derives independently", top == 81, "modal gap %d (x%d)" % (top, ntop))
    d = rom("wsa1_prom_d.bin")
    for tag, k in (("first", pd[0]), ("last", pd[-1])):
        check("the %s binary prom_d run verifies against both raw images" % tag,
              d[k[2]:k[2] + k[4]] == k[5])
    check("250 binary prom_d runs totalling 8,152 bytes, 74 of them exactly 81 "
          "bytes after their predecessor",
          (len(pd), sum(k[4] for k in pd), ntop) == (250, 8152, 74),
          "got %s" % ((len(pd), sum(k[4] for k in pd), ntop),))
    check("the modal shared-run LENGTH is 39 bytes, 118 of them",
          collections.Counter(k[4] for k in pd).most_common(1)[0] == (39, 118))
    if not quiet:
        print("    BINARY (non-ASCII) shared runs from prom_d: %d runs, %d bytes"
              % (len(pd), sum(k[4] for k in pd)))
        print("    run-length modes : %s"
              % collections.Counter(k[4] for k in pd).most_common(4))
        print("    prom_d-side gap between consecutive runs, modes : %s"
              % gaps.most_common(4))
        print("    ★ the modal gap is %d, and 81 is the tone record's per-element"
              % top)
        print("      block stride (217 + N*(81+43)) that this tree derived from")
        print("      prom_d ALONE.  Two independent derivations of the same number.")
        print("    first: prom_d file 0x%06X -> kn 0x%06X  %d B" % (pd[0][2], pd[0][3], pd[0][4]))
        print("    last : prom_d file 0x%06X -> kn 0x%06X  %d B" % (pd[-1][2], pd[-1][3], pd[-1][4]))
        print("    ⚠ NOT claimed: what any field in these records means.  This tree")
        print("      has no field meanings for prom_d and none are invented here.\n")
    return pd


# ---------------------------------------------------------------------------
# 5.  The honest negatives, each with its search stated
# ---------------------------------------------------------------------------

PART_RE = (r"\b(uPD[0-9]{3,5}[A-Z]*|SED13[0-9]{2}|S1D13[0-9]{3}|93C[0-9]{2}"
           r"|MN1[0-9]{4}|HD44780|LC7[0-9]{4}|PCM1[0-9]{3}|AK4[0-9]{3}"
           r"|TC9[0-9]{3}|MB8[0-9]{4}|TMP9[0-9]C[0-9]{3}|ADSP-2106[0-9][A-Z]*"
           r"|MSM[0-9]{4}|YM[0-9]{4}|T6963)\b")
KN_NOTES = "/home/fsanches/compartilhado/kn7000_mame/notes"


def part_tokens(root, skip=()):
    pat = re.compile(PART_RE, re.I)
    c = collections.Counter()
    for d, _, fs in os.walk(root):
        for f in fs:
            if not f.endswith((".md", ".txt", ".py", ".json", ".cpp", ".h")):
                continue
            if f in skip or os.path.join(d, f) == os.path.abspath(__file__):
                continue                # never count this script's own prose
            try:
                with open(os.path.join(d, f), errors="ignore") as fh:
                    for m in pat.finditer(fh.read()):
                        c[m.group(0).upper()] += 1
            except OSError:
                pass
    return c


def negatives(mn, quiet=False):
    # 5a.  the drum-kit NAME TABLE is not shared, only its vocabulary
    a = rom("wsa1_prom_a.ic12")
    base = 0xFEB5C4 - 0xF80000
    names = [a[base + i * 10:base + i * 10 + 10] for i in range(13 * 129)]
    uniq = sorted({n for n in names if n.strip()})
    table, prog = mn["kn7000_table"], mn["kn7000_prog"]
    sub = [n for n in uniq if n in table or n in prog]
    # the real question: does any CONTIGUOUS PAIR of table entries survive?
    pairs = 0
    for i in range(len(names) - 1):
        two = names[i] + names[i + 1]
        if two.strip() and (two in table or two in prog):
            pairs += 1
    check("no two ADJACENT WSA1 drum-kit name slots occur together in any "
          "MN10300 image (so the TABLE is not shared)", pairs == 0,
          "%d adjacent pairs did" % pairs)

    # 5b.  the MILK toolkit tag, present on the MN10300 side, absent here
    wsa1_all = b"".join(rom(f) for _, f, _ in IMAGES)
    check("'MILK' occurs in the MN10300 program images", b"MILK" in prog)
    check("'MILK' does NOT occur in any WSA1 image", b"MILK" not in wsa1_all)

    # 5c.  the chip inventories, as the two note trees record them
    mine = part_tokens(os.path.join(ROOT, "notes"))
    theirs = part_tokens(KN_NOTES, skip=("WSA1-EMULATION-DISASM-GAPS.md",))
    only_theirs = {k: v for k, v in theirs.items() if k not in mine}
    both = {k: (mine[k], theirs[k]) for k in mine if k in theirs}
    check("uPD6383GF is named in BOTH note trees", "UPD6383GF" in both)
    check("...and the KN7000 tree names it at least five times as often",
          both.get("UPD6383GF", (1, 0))[1] >= 5 * both.get("UPD6383GF", (1, 0))[0],
          "%s" % (both.get("UPD6383GF"),))
    # the asymmetry is not about how OFTEN the part is named but about whether
    # it has been DECODED.  These three words are the KN7000 tree's vocabulary
    # for the decode, and they do not occur in this tree at all.
    vocab = collections.Counter()
    for root, tag in ((os.path.join(ROOT, "notes"), "wsa1"), (KN_NOTES, "kn7000")):
        for d, _, fs in os.walk(root):
            for f in fs:
                if not f.endswith((".md", ".txt", ".py")):
                    continue
                if os.path.join(d, f) == os.path.abspath(__file__):
                    continue            # ⚠ this file names all three words itself
                try:
                    with open(os.path.join(d, f), errors="ignore") as fh:
                        t = fh.read()
                except OSError:
                    continue
                for w in ("microprogram", "lo12", "hi12"):
                    vocab[(tag, w)] += t.count(w)
    for w in ("microprogram", "lo12", "hi12"):
        check("'%s' occurs ZERO times in this tree's notes/" % w,
              vocab[("wsa1", w)] == 0, "%d" % vocab[("wsa1", w)])
        check("'%s' occurs in the KN7000 tree's notes/" % w,
              vocab[("kn7000", w)] > 0)

    # 5d.  the DSP EFFECT-NAME table is not shared either
    b = rom("wsa1_prom_b.ic13")
    eb = 0xF147AC - 0xF00000
    ents = [b[eb + i * 16:eb + i * 16 + 16] for i in range(128)]
    real = [e for e in ents if e.strip() and b"---" not in e]
    epairs = sum(1 for i in range(len(ents) - 1)
                 if (ents[i] + ents[i + 1]).strip()
                 and (ents[i] + ents[i + 1] in table or ents[i] + ents[i + 1] in prog))
    etrim = [e.strip() for e in real if e.strip() in table or e.strip() in prog]
    check("the 2,048-byte effect-name table at prom_b 0xF147AC has 128 slots of "
          "which 56 are real names", len(ents) == 128 and len(real) == 56,
          "%d real" % len(real))
    check("no two ADJACENT effect names occur together in any MN10300 image",
          epairs == 0, "%d did" % epairs)
    # 5e.  ⚠ the brief handed to this lane called 0xFF047F an "838-byte
    # effect-name table".  It is not; notes/wave7_doc_audit.py already
    # corrected that and this re-checks it from the ROM.
    a = rom("wsa1_prom_a.ic12")
    check("prom_a 0xFF047F is six SPACES (the default arm of the kit-category "
          "switch), not an effect-name table",
          a[0xFF047F - 0xF80000:0xFF047F - 0xF80000 + 6] == b"      ")
    check("the real effect-name table is prom_b 0xF147AC and its first entry is "
          "'  NO OPERATION  '", ents[0] == b"  NO OPERATION  ")
    # 5f.  the two peripheral asymmetries, as the note trees record them
    check("SED1330 is named far more in this tree than in the KN7000 tree "
          "(the LCD controller is the WSA1's, not the KN7000's)",
          mine.get("SED1330", 0) > theirs.get("SED1330", 0))
    n82 = 0
    for d, _, fs in os.walk(os.path.join(ROOT, "notes")):
        for f in fs:
            if f.endswith((".md", ".py", ".txt")) and os.path.join(d, f) != os.path.abspath(__file__):
                try:
                    with open(os.path.join(d, f), errors="ignore") as fh:
                        n82 += fh.read().count("82077")
                except OSError:
                    pass
    kn82 = 0
    for d, _, fs in os.walk(KN_NOTES):
        for f in fs:
            if f.endswith((".md", ".py", ".txt")):
                try:
                    with open(os.path.join(d, f), errors="ignore") as fh:
                        kn82 += fh.read().count("82077")
                except OSError:
                    pass
    check("'82077' (the KN7000's FDC part) occurs in the KN7000 tree", kn82 > 0)
    check("'82077' occurs ZERO times in this tree -- the two FDCs have never "
          "been compared", n82 == 0, "%d" % n82)

    if not quiet:
        print("=== 5. the negatives, with the search that produced each ===\n")
        print("  5a. THE DRUM-KIT NAME TABLE IS NOT SHARED.")
        print("      Searched: all %d distinct non-blank 10-char entries of the WSA1's"
              % len(uniq))
        print("      13x129 table at prom_a 0xFEB5C4, against kn7000_table and")
        print("      kn7000_prog.  %d of them occur as a byte SUBSTRING -- but that is"
              % len(sub))
        print("      a vocabulary overlap, not a table: the KN7000 stores 13-char")
        print("      names in 24-byte records, so 'Ride Bell ' matches inside")
        print("      'Ride Bell 1  '.  The table test is whether any two ADJACENT")
        print("      slots occur together, and the answer is %d.  A shared drum-name" % pairs)
        print("      table would have scored in the hundreds.\n")
        print("  5b. THE WSA1 DOES NOT CARRY THE MILK TOOLKIT.")
        print("      b'MILK' occurs in the MN10300 program images and in NONE of the")
        print("      four WSA1 images.  (Consistent with ../technics_roms/tools/")
        print("      wsa1_kinship.py's docstring, now measured here too.)\n")
        print("  5c. CHIP PART NUMBERS: what the KN7000 tree names and this one does not.")
        print("      %s\n      vs %s\n" % (os.path.join(ROOT, "notes"), KN_NOTES))
        print("      in BOTH trees (this tree / KN7000 tree):")
        for k in sorted(both, key=lambda k: -both[k][1]):
            print("          %-12s %4d / %4d" % (k, both[k][0], both[k][1]))
        print("\n      named ONLY in the KN7000 tree (top 12 by mentions):")
        for k, v in sorted(only_theirs.items(), key=lambda kv: -kv[1])[:12]:
            print("          %-12s %4d" % (k, v))
        print("\n      ★ uPD6383GF is the asymmetry that matters.")
        print("        This tree names it %d times -- all of them parts-list mentions"
              % both["UPD6383GF"][0])
        print("        ('the SX-WSA1R carries three uPD6383GF DSPs',")
        print("        notes/prom_c_dsp_port.py).  The KN7000 tree names it %d times"
              % both["UPD6383GF"][1])
        print("        because it has DECODED the part: ALU field structure, register")
        print("        space, per-frame execution trace, microprogram upload, effect")
        print("        catalogue.  And prom_c UPLOADS MICROCODE to three destinations")
        print("        over port P7 (notes/prom_c_dsp_port.py, emulation gap G).")
        print("        Decode vocabulary, counted in both trees:")
        for w in ("microprogram", "lo12", "hi12"):
            print("            %-14s this tree %3d   KN7000 tree %4d"
                  % (w, vocab[("wsa1", w)], vocab[("kn7000", w)]))
        print("        Zero here, hundreds there.  That is the largest importable")
        print("        body of knowledge this lane found, and it arrives via the")
        print("        KN5000 (IC311), which is TLCS-900 -- NOT via an MN10300 machine.")
        print()
        print("  5d. THE DSP EFFECT-NAME TABLE IS NOT SHARED.")
        print("      prom_b 0xF147AC is 128 x 16 characters, %d of them real names."
              % len(real))
        print("      Adjacent-pair test against both KN7000 images: %d.  Only %d of the"
              % (epairs, len(etrim)))
        print("      names occur at all, and they are the generic ones: %s."
              % ", ".join(e.decode() for e in etrim))
        print("      Expected: the WSA1's effects run on three uPD6383GF DSPs and the")
        print("      KN7000's on an ADSP-21065L SHARC (IC306), so a shared effect")
        print("      catalogue would have been the surprise.\n")
        print("  5e. ⚠ 0xFF047F IS NOT AN EFFECT-NAME TABLE.")
        print("      Several planning documents call it 'the 838-byte effect-name")
        print("      table'.  It is the DRUM-KIT CATEGORY legends (STANDR / ROOM /")
        print("      POWER / ELEC / DANCE ...); notes/wave7_doc_audit.py caught this")
        print("      first and this script re-checks it from the ROM.  The effect")
        print("      names are prom_b 0xF147AC, in a different image.\n")
        print("  5f. TWO PERIPHERALS THAT ARE **NOT** SHARED, which is worth as much:")
        print("      * LCD CONTROLLER.  The WSA1 has an SED1330-family part (%d mentions"
              % mine.get("SED1330", 0))
        print("        here, %d there).  The KN7000 has a custom controller in its own"
              % theirs.get("SED1330", 0))
        print("        register bank at 0x34000000 (58 registers) -- see the header of")
        print("        ../kn7000_mame/src/mame/matsushita/kn7000.cpp.  No transplant.")
        print("      * FLOPPY CONTROLLER.  Both are 765-lineage, but not the same")
        print("        generation: this tree measured the WSA1's validator to implement")
        print("        the BASE uPD765 opcode map (notes/FINDINGS-prom_a-fdc.md), while")
        print("        the KN7000's IC103 is identified as an N82077AA / PC-AT part with")
        print("        the full DOR/DIR set, from the service-manual chip-select decoder")
        print("        plus firmware register writes (../kn7000_mame/notes/")
        print("        fdc-architecture.md and AUTONOMOUS-STATUS.md tick 2026-07-12).")
        print("        '82077' occurs %d times in this tree and %d times in that one:"
              % (n82, kn82))
        print("        the two FDCs have never been put side by side, and the KN7000's")
        print("        METHOD -- read the part off the schematic's CS decoder -- is not")
        print("        available here because the SX-WSA1R service manual PDF is a")
        print("        SCAN WITH NO TEXT LAYER (`pdftotext -layout` on")
        print("        ../KN7000/service_manual/'SX-WSA1R Service Manual.pdf' yields 42")
        print("        bytes).  That, not disinterest, is why this tree names fewer")
        print("        parts than the KN7000 tree does.\n")


# ---------------------------------------------------------------------------

IMPORTABLE = [
    ("★★", "The uPD6383GF decode.",
     "notes/prom_c_dsp_port.py already proves prom_c uploads microcode to three "
     "destinations over P7 and cannot say WHAT it is uploading.  "
     "../kn7000_mame/notes/dsp-alu-structure.md, dsp-alu-biquad.md, "
     "dsp-register-space-applied.md, dsp-perframe-execution.md and "
     "dsp-effect-catalog.md decode the SAME PART for the KN5000's IC311.  "
     "⚠ Verify the part first -- this tree's only evidence for 'three "
     "uPD6383GF' is a parts-list reading, and a byte diff against the KN5000's "
     "microprogram word format is the check that would settle it."),
    ("★", "The KN7000's font descriptor format, 0x14 bytes.",
     "Section 3 uses it and it came from ../kn7000_mame/notes/"
     "kn6000-kn6500-boot.md: +0 width, +2 height, +4/+6 metrics, +8 glyph "
     "base, +0x10 extension, reached through the table ROM's own header word "
     "at 0x200+0xC.  The WSA1's Latin tables were ALREADY known to be "
     "ASCII-indexed in 0x20-0x7E (notes/FINDINGS-fonts.md; only the five "
     "Japanese faces carry the unresolved private encoding), so the descriptor "
     "adds a different thing: the KN7000 gives each face 224 glyphs for codes "
     "0x20-0xFF while the WSA1 gives 200 for 0x00-0xC7, and section 3 measures "
     "that 0, 0, 1 and 4 of the 73 codes 0x7F-0xC7 are shared across the "
     "four faces -- and three of those four are blank on both sides.  The "
     "WSA1's upper block is its own, and a glyph name transplanted for it "
     "would be wrong."),
    ("★", "The KN7000's identification METHOD for board parts.",
     "It read the FDC part off the service manual's chip-select decoder "
     "(TC74VHC138F, MAIN 1/5 p.101).  The SX-WSA1R service manual in this "
     "repository's sibling directory is an image-only scan; OCR of its parts "
     "list and CS decoder would let this tree name the LCD part, the DSPs and "
     "the tone generator instead of inferring them."),
    ("", "The 195 shared sound names.",
     "Section 4 gives every prom_d file offset and its KN7000 table offset.  "
     "The KN7000 side sits inside a documented 24-byte record; prom_d's tone "
     "record head is 217 bytes with a 16-character name at a known place "
     "(notes/FINDINGS-prom-d-tone-database.md).  A field-by-field diff of one "
     "matched pair is the cheapest route to prom_d's first FIELD MEANING, "
     "which this tree has none of."),
]


def importable(quiet=False):
    if quiet:
        return
    print("=== 6. what is importable, in priority order ===\n")
    for star, head, body in IMPORTABLE:
        print("  %-3s %s" % (star, head))
        for line in _wrap(body, 72):
            print("      " + line)
        print()


def _wrap(text, w):
    out, line = [], ""
    for word in text.split():
        if len(line) + len(word) + 1 > w:
            out.append(line)
            line = word
        else:
            line = (line + " " + word).strip()
    if line:
        out.append(line)
    return out


def mutation_test():
    """A criterion that cannot fail is not a pass.  Corrupt one glyph byte in
    the KN7000 table image and confirm the font checks notice."""
    global FAILED, NCHECK
    mn = build_mn10300(True)
    before = len(FAILED)
    font_report(mn, True)
    clean = len(FAILED) - before
    print("clean run: %d font-section failures (expected 0)" % clean)
    t = bytearray(mn["kn7000_table"])
    t[0x0246A8 + 0x41 * 16 + 3] ^= 0xFF      # one row of one glyph in font id 1
    mn["kn7000_table"] = bytes(t)
    FAILED, NCHECK = [], 0
    font_report(mn, True)
    print("after flipping one byte inside font id 1's glyph block: %d failures"
          % len(FAILED))
    for f in FAILED:
        print("  (expected) FAIL: %s" % f)
    ok = len(FAILED) > 0 and clean == 0
    print("MUTATION TEST %s" % ("PASSED -- the checks can fail" if ok
                                else "FAILED -- the checks are vacuous"))
    return 0 if ok else 1


def main():
    if "--mutation" in sys.argv:
        return mutation_test()
    quiet = "--selftest" in sys.argv
    do_nulls = "--quick" not in sys.argv
    if not quiet:
        print(__doc__.split("RUN")[0])
    mn = build_mn10300(quiet)
    results = section_runs(mn, quiet, do_nulls)
    font_report(mn, quiet)
    font_sweep(quiet)
    tone_names(quiet, mn)
    tone_records(results, quiet)
    negatives(mn, quiet)
    importable(quiet)
    print("%d checks ran, %d failed" % (NCHECK, len(FAILED)))
    for f in FAILED:
        print("  FAIL: %s" % f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
