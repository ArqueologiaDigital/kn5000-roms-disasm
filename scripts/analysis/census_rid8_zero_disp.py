#!/usr/bin/env python3
"""census_rid8_zero_disp.py -- which forced-mnemonic *_rid8 sites does the
2026-09-02 InstPrinter/decoder fix actually retire?

QUESTION ANSWERED
  Lane INSTPRINT fixed a print/round-trip collision in the TLCS900 LLVM
  backend (llvm-project commit 63ff7d92fb5f): the 3-byte register-indirect
  d8-displacement encoding "(Xrr+d8)" and the 2-byte no-displacement
  encoding "(Xrr)" printed IDENTICALLY as "(Xrr)" whenever the true
  displacement was zero, so a disassembled 3-byte-disp0 instruction could
  not be told apart from its 2-byte sibling and re-assembling always chose
  the shorter form. The fix makes decodeMemPrefix() emit the sentinel
  displacement 256 (which prints as the ordinary "+256") whenever the d8
  byte was actually present and its value is literally 0.

  The disasm tree worked around the ORIGINAL bug with four forced,
  asm-only mnemonics (ld8_src_rid8, ld16_src_rid8, ld_dst16_rid8, lda_rid8)
  plus two ALU-family ones (xor8_mem_rid8, sub16_mem_rid8) that spell the
  address register, raw displacement byte and data register as three plain
  operands instead of natural memory syntax, sidestepping the collision
  entirely (at the cost of a mnemonic no reader recognizes).

  THIS IS NOT THE SAME QUESTION AS "does grep find the mnemonic". Most
  occurrences of these forced mnemonics have a NON-ZERO displacement and
  were never blocked by the print collision at all -- the natural "ld"/
  "lda"/"xor"/"sub" spelling already worked for them before this fix, and
  may have been used for an unrelated reason (see the CAVEAT below). Only
  the disp == 0x00 occurrences are the ones this fix actually unblocks;
  this script tells the two groups apart so nobody claims credit for sites
  the fix did not touch.

CAVEAT -- a spelling trap in the NON-ZERO group, found while writing this
  script: TLCS900MCCodeEmitter's natural-syntax encoder treats a `(reg+N)`
  displacement as SIGNED and picks the 16-bit d16 SRI encoding (silently,
  no diagnostic) whenever N is written as a literal outside -128..127 --
  e.g. `lda xhl, (xde+0x97)` assembles to the WRONG, 5-byte form (f3 e9 97
  00 33) because 0x97 = 151 > 127, even though the ROM's real disp8 byte
  is 0x97 (i.e. -105, and `(xde-105)` correctly assembles to the 3-byte
  `ba 97 33`). Converting a NON-ZERO forced-mnemonic site to natural syntax
  is only safe if any raw disp8 byte >= 0x80 is re-spelled as its signed
  decimal value first. This script flags every non-zero site with disp8
  byte >= 0x80 under NEEDS_SIGN_FIX so nobody blindly greps-and-replaces.

RUN
  python3 scripts/analysis/census_rid8_zero_disp.py

Prints, per mnemonic and per file: how many occurrences have disp == 0x00
(retired by the fix, safe mechanical rewrite to "(reg+256)"), how many are
non-zero and already safe to rewrite as-is, and how many non-zero sites
need the sign fix above before rewriting.
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# mnemonic -> (natural mnemonic, operand order template)
# "src": natural is `ld data, (addr+disp)` (LOAD FROM memory)
# "dst": natural is `ld (addr+disp), data` (STORE TO memory)
# "lda": natural is `lda data, (addr+disp)`
# "alu": natural is `<op> (addr+disp), data`
FAMILIES = {
    "ld8_src_rid8":   ("ld",  "src"),
    "ld16_src_rid8":  ("ld",  "src"),
    "ld_dst16_rid8":  ("ld",  "dst"),
    "lda_rid8":       ("lda", "lda"),
    "xor8_mem_rid8":  ("xor", "alu"),
    "sub16_mem_rid8": ("sub", "alu"),
}

LINE_RE = re.compile(
    r'^\s*(' + "|".join(re.escape(k) for k in FAMILIES) + r')'
    r'\s+(\S+?),\s*(-?0x[0-9a-fA-F]+|-?\d+)\s*,\s*(\S+)', re.MULTILINE)


def parse_disp(tok):
    return int(tok, 16) if tok.lower().startswith(("0x", "-0x")) else int(tok)


def scan_file(path):
    hits = {k: {"zero": 0, "nonzero_safe": 0, "nonzero_needs_sign_fix": 0}
            for k in FAMILIES}
    with open(path, encoding="latin-1") as f:
        for line in f:
            m = LINE_RE.match(line)
            if not m:
                continue
            mnem, addr, disptok, data = m.groups()
            disp = parse_disp(disptok)
            bucket = hits[mnem]
            if disp == 0:
                bucket["zero"] += 1
            elif 0x80 <= disp <= 0xFF:
                bucket["nonzero_needs_sign_fix"] += 1
            else:
                bucket["nonzero_safe"] += 1
    return hits


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "**", "*.s"), recursive=True))
    totals = {k: {"zero": 0, "nonzero_safe": 0, "nonzero_needs_sign_fix": 0}
              for k in FAMILIES}
    per_file = {}
    for path in files:
        hits = scan_file(path)
        if any(any(v.values()) for v in hits.values()):
            rel = os.path.relpath(path, ROOT)
            per_file[rel] = hits
            for k in FAMILIES:
                for bucket in totals[k]:
                    totals[k][bucket] += hits[k][bucket]

    print("Per-file breakdown (only files with hits):")
    for rel, hits in sorted(per_file.items()):
        nonzero = sum(hits[k]["nonzero_safe"] + hits[k]["nonzero_needs_sign_fix"]
                      for k in FAMILIES)
        zero = sum(hits[k]["zero"] for k in FAMILIES)
        if zero or nonzero:
            print(f"  {rel}")
            for k in FAMILIES:
                z, ns, nf = hits[k]["zero"], hits[k]["nonzero_safe"], hits[k]["nonzero_needs_sign_fix"]
                if z or ns or nf:
                    print(f"      {k:16s} zero(fix-retires)={z:3d}  "
                          f"nonzero-already-safe={ns:3d}  "
                          f"nonzero-NEEDS_SIGN_FIX={nf:3d}")

    print()
    print("Totals across the tree:")
    grand_zero = grand_safe = grand_sign = 0
    for k, (natural, kind) in FAMILIES.items():
        t = totals[k]
        grand_zero += t["zero"]
        grand_safe += t["nonzero_safe"]
        grand_sign += t["nonzero_needs_sign_fix"]
        print(f"  {k:16s} -> natural '{natural}': "
              f"retired-by-fix={t['zero']:3d}  "
              f"already-safe-nonzero={t['nonzero_safe']:3d}  "
              f"needs-sign-fix={t['nonzero_needs_sign_fix']:3d}")
    print(f"\n  RETIRED BY THE 2026-09-02 DECODER FIX (disp==0 sites): {grand_zero}")
    print(f"  Non-zero, already safe to rewrite as-is:                {grand_safe}")
    print(f"  Non-zero, needs the signed-displacement rewrite first:  {grand_sign}")


if __name__ == "__main__":
    main()
