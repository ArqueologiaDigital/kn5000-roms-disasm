#!/usr/bin/env python3
"""blind_byte_rom_sites.py -- find REAL ROM sites for the five instructions
tlcs900_backend could not decode, and judge whether any of them is CODE.

QUESTION THIS ANSWERS
----------------------
`unmapped_byte_oracle.py` established that five leading bytes -- 0x01 normal,
0x04 max, 0x17 ldf, 0x1a jp nnnn, 0x1c call nnnn -- are real TLCS-900
instructions this backend never decoded.  Two things follow that need
answering separately, and conflating them is the trap:

  (1) WHERE do those byte sequences occur in the committed dumps?  A lit test
      claiming to use "real ROM bytes" needs an image, an offset, and a
      rendering from an independent decoder.  This is a provenance question and
      it has a clean answer.
  (2) Is any such site EXECUTED CODE?  `byte_run_start_enrichment.py` read a
      46x enrichment of these bytes among v10's `.byte` run-starts as evidence
      that the residue is hidden code.  That is a much stronger claim, and it
      is the one this script was written to check.

WHY THE OBVIOUS CORROBORATION DOES NOT WORK -- I SHIPPED IT FIRST
------------------------------------------------------------------
The first version of this script scored a candidate by asking whether the W
listing lines either side of it decode, byte-for-byte, to exactly one
instruction each under `llvm-mc -disassemble` -- an independent decoder
agreeing on every instruction BOUNDARY around the site.  That sounds strong.

It scored 8/8 on every top v10 candidate, and every one of those candidates was
DATA.  0xe014d3 is `00 00 00 01 00 02 00 03 ...`, a 16-bit index ramp.
0xe02055 is a table of 24-bit pointers whose second byte happens to be 0x1a.
0xe006d5 and 0xe00c8e are bitmap glyphs.  Two decoders agreeing on a length
proves they implement the same instruction set, not that the bytes are code.

So this version keeps the boundary check and adds SHAPE FILTERS that reject the
window if it looks like a linear sweep through data:

  * any `db` (unidasm's undecodable marker) in the window -- real code does not
    contain bytes no decoder recognises;
  * more than one `nop` -- 0x00 is the commonest data byte and zero-fill
    disassembles to nop runs;
  * a byte ramp -- >60% of adjacent byte deltas equal to +1 or -1, which catches
    the 00 01 02 03 / 20 21 22 counter tables these ROMs are full of;
  * fewer than 8 distinct mnemonics in 13 lines -- catches repeating table rows.

⚠ THE ANSWER, 2026-09-02, ACROSS SIX COMMITTED IMAGES: NOT ONE SITE SURVIVES AS
CODE.  Every candidate that passes the shape filters still lands, on inspection,
in an ascending-byte test pattern, a power-of-two mask table, a pointer table, a
string, or a DSP parameter block.  So the sites below are good PROVENANCE -- the
bytes really are at those offsets and unidasm really renders them that way --
and they are NOT evidence that any image contains these instructions as executed
code.  See `blind_run_decode_census.py` for the quantitative version of the same
negative result.

⚠ DO NOT UPGRADE A SITE PRINTED HERE INTO A CLAIM ABOUT CODE.  The filters
reduce false positives; they do not turn a linear sweep into a control-flow
argument.  Deciding a region is code still needs something that references it.

RUN
    python3 scripts/analysis/blind_byte_rom_sites.py [--rom SUBSTR] [--top N]
    python3 scripts/analysis/blind_byte_rom_sites.py --check   # verify the
        byte sequences quoted in llvm/test/MC/TLCS900/missing-leading-bytes.s
        are really present at those offsets in the committed dumps
    needs $LLVM_MC, else ~/compartilhado/llvm-project/build/bin/llvm-mc
"""
import argparse
import os
import re
import subprocess
import sys

LLVM_MC = os.environ.get("LLVM_MC") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc")

# leading byte -> (unidasm mnemonic prefix, total encoding length)
TARGETS = {
    0x01: ("normal", 1),
    0x04: ("max", 1),
    0x17: ("ldf", 2),
    0x1a: ("jp", 3),
    0x1c: ("call", 3),
}

LINE_RE = re.compile(r"^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$")

# Listings live in two places since the WSA1R tree was migrated in here.
LISTING_DIRS = ["original_ROMs", "wsa1/original_ROMs"]

# The sites quoted by the lit test, as (dump path, file offset, bytes).
# --check re-reads each from the committed dump so the test's provenance claims
# are verifiable rather than asserted.
TEST_SITES = [
    # (dump, file offset, bytes, ROM address in that image's address space)
    ("original_ROMs/kn5000_v10_program.rom", 0x00150C, "01", 0xE0150C),
    ("original_ROMs/kn5000_v10_program.rom", 0x001698, "04", 0xE01698),
    ("original_ROMs/kn5000_v10_program.rom", 0x001531, "17 01", 0xE01531),
    ("original_ROMs/kn5000_v10_program.rom", 0x002059, "1a e0 00", 0xE02059),
    ("original_ROMs/kn5000_subprogram_v142.rom", 0x000461, "1a a0 01",
     0x00F361),
    ("original_ROMs/kn5000_subprogram_v142.rom", 0x0033BE, "1c 2a 38",
     0x0122BE),
    ("wsa1/original_ROMs/wsa1_prom_a.ic12", 0x006EA8, "1a 12 b0", 0xF86EA8),
    ("wsa1/original_ROMs/wsa1_prom_a.ic12", 0x03055C, "1c 06 7f", 0xFB055C),
    ("wsa1/original_ROMs/wsa1_prom_c.ic28", 0x04E9CE, "17 c7", 0xFCE9CE),
    ("wsa1/original_ROMs/wsa1_prom_c.ic28", 0x04D34A, "1c 24 01", 0xFCD34A),
]


def parse_listing(path):
    out = []
    with open(path, encoding="latin-1") as f:
        for line in f:
            m = LINE_RE.match(line.rstrip("\n"))
            if not m:
                continue
            out.append((int(m.group(1), 16),
                        bytes(int(x, 16) for x in m.group(2).split()),
                        m.group(3).strip()))
    return out


def boundaries_agree(entries):
    """Does llvm-mc decode each entry's EXACT bytes to one clean instruction?

    No padding, deliberately: if our decoder thought an instruction shorter it
    would emit a second instruction or a warning on the leftover, and if longer
    the truncated input would fail.  One clean instruction per line therefore
    means the two decoders agree on every boundary in the window."""
    n = 0
    for raw in entries:
        p = subprocess.run([LLVM_MC, "-triple=tlcs900", "-disassemble"],
                           input=",".join("0x%02x" % b for b in raw),
                           capture_output=True, text=True)
        insns = [l for l in p.stdout.splitlines() if l.strip()]
        if len(insns) == 1 and "warning" not in p.stderr \
                and "error" not in p.stderr:
            n += 1
    return n


def looks_like_data(window):
    """Shape filters -- see the header for why each one is here."""
    texts = [w[2] for w in window]
    if any(t == "db" for t in texts):
        return "contains db"
    if sum(1 for t in texts if t == "nop") > 1:
        return "nop run (zero fill)"
    blob = b"".join(w[1] for w in window)
    deltas = [blob[i + 1] - blob[i] for i in range(len(blob) - 1)]
    if deltas and sum(1 for d in deltas if d in (1, -1)) > 0.6 * len(deltas):
        return "byte ramp"
    if len(set(texts)) < 8:
        return "repeating table rows"
    return None


def check_sites():
    bad = 0
    for path, off, hexs, romaddr in TEST_SITES:
        want = bytes(int(x, 16) for x in hexs.split())
        if not os.path.exists(path):
            print("  MISSING DUMP  %s" % path)
            bad += 1
            continue
        with open(path, "rb") as f:
            f.seek(off)
            got = f.read(len(want))
        ok = got == want
        bad += 0 if ok else 1
        print("  %-4s %-42s +0x%06x (rom 0x%06x)  want %-10s got %s"
              % ("ok" if ok else "FAIL", path, off, romaddr, hexs,
                 " ".join("%02x" % b for b in got)))
    print("\n  %d site(s) checked, %d mismatched" % (len(TEST_SITES), bad))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default=None)
    ap.add_argument("--window", type=int, default=6)
    ap.add_argument("--top", type=int, default=2)
    ap.add_argument("--check", action="store_true",
                    help="verify the lit test's quoted sites against the dumps")
    args = ap.parse_args()

    if args.check:
        return check_sites()

    listings = []
    for d in LISTING_DIRS:
        if os.path.isdir(d):
            listings += [os.path.join(d, f) for f in sorted(os.listdir(d))
                         if f.endswith(".unidasm")]
    if args.rom:
        listings = [f for f in listings if args.rom in f]
    if not listings:
        print("no .unidasm listings found", file=sys.stderr)
        return 1

    W = args.window
    survivors = 0
    for path in listings:
        entries = parse_listing(path)
        if not entries:
            continue
        base = entries[0][0]
        print("=== %s  (base 0x%06x, %d decoded lines)"
              % (path, base, len(entries)))
        for lead in sorted(TARGETS):
            mn, ln = TARGETS[lead]
            shown = 0
            rejected = 0
            for i, (addr, raw, text) in enumerate(entries):
                if len(raw) != ln or raw[0] != lead or not text.startswith(mn):
                    continue
                if i < W or i + W >= len(entries):
                    continue
                win = entries[i - W:i + W + 1]
                why = looks_like_data(win)
                if why:
                    rejected += 1
                    continue
                nb = [e[1] for e in win if e is not entries[i]]
                score = boundaries_agree(nb)
                print("  0x%02x %-9s rom 0x%06x  file +0x%06x  %-9s %-18s"
                      "  boundaries %d/%d"
                      % (lead, mn, addr, addr - base,
                         " ".join("%02x" % b for b in raw), text,
                         score, len(nb)))
                survivors += 1
                shown += 1
                if shown >= args.top:
                    break
            if not shown:
                print("  0x%02x %-9s no site survived the shape filters "
                      "(%d rejected as data)" % (lead, mn, rejected))
        print()
    print("%d site(s) passed the shape filters." % survivors)
    print("⚠ Passing the filters is NOT a verdict of CODE. As of 2026-09-02 "
          "every surviving site, inspected by hand, still sits in a byte ramp, "
          "a mask table, a pointer table, a string or a parameter block. Treat "
          "these as byte PROVENANCE only.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
