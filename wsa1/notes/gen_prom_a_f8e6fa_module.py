#!/usr/bin/env python3
"""Emit prom_a 0xF8E6FA-0xF8E77C (130 B) as verified assembly; refuse the
remaining 0xF8E77C-0xF8E7CD (81 B).

QUESTION IT ANSWERS
  This 211 B span sits immediately after `MemCopyWords` (already converted).
  A naive linear decode over the whole span finds 9 undecodable bytes
  starting at 0xF8E785 and never resynchronises -- but that failure is
  entirely confined to the LAST 81 bytes; the first 130 are clean.

  0xF8E6FA (1 B) -- a single 0x0E byte, ordinary padding, immediately before:

  0xF8E6FB-0xF8E712 (24 B) -- a byte-for-byte DUPLICATE of `MemCopyWords`
  (0xF8E6E2-0xF8E6F9, already converted, verified with a direct byte
  comparison against that exact range). Whatever called this duplicate is
  not traced, but its bytes are already-understood code, not a guess.

  0xF8E713-0xF8E74A (56 B) -- a second block-move routine, three-way branch
  on carry/zero into one of three `lda`/`ldir` sequences, all converging on
  a shared `pop DE / pop XIX / pop XHL / ret` tail. Decodes with zero
  undecodable bytes.

  0xF8E74B-0xF8E772 (40 B) -- an init routine: `lda XIY,(0xf8e773)` /
  `lda XIX,(0x6007d3)` / `ld XBC,9` / `ldir` copies 9 bytes from THIS SAME
  SPAN (0xF8E773, the very next address) to RAM 0x6007d3, then zero-fills 83
  bytes (`ld XBC,0x53`) at RAM 0x600780. Ends `ret`, then a single `reti`
  (0x07, an ordinary one-byte instruction, not garbage) at 0xF8E772.

  0xF8E773-0xF8E77C (9 B) -- DATA, not a guess: it is the literal LDIR
  SOURCE the init routine above names by address and count (`lda
  XIY,(0xf8e773)` / `ld XBC,0x00000009`). All 9 bytes are 0x00 -- the
  routine zero-initialises a small header before zero-filling the larger
  block that follows it.

  0xF8E77C-0xF8E7CD (81 B) -- REFUSED. This is where the naive decode's 9
  undecodable bytes actually start (0xF8E785 is only 9 bytes in). The first
  32 bytes look like a table of 8 little-endian longs, all `0x00F8Exxx`
  pointers into this same code cluster (`0xf8e68b, 0xf8e67a, 0xf8e000,
  0xf8e69c, 0xf8e6ad, 0xf8e6df, 0xf8e6be, 0xf8e000`) -- but the pattern
  breaks immediately after: the next 4 bytes (`6e f7 0e 07`) are not a
  plausible pointer, then 9 more zero bytes, then the alignment of the
  following "pointers" is off by ONE byte relative to a fixed 4-byte grid
  (`da e6 f8 00` starts at 0xF8E7A9, not 0xF8E7A8). A raw whole-ROM pointer
  scan (3- and 4-byte little-endian) for `0xF8E77C` and for `0xF8E7A9`
  (the byte-shifted second table's apparent start) finds ZERO hits either
  way -- no reader anywhere in the ROM cites where this second stretch
  begins, so there is no external anchor to fix the exact record boundaries
  the way `DispatchTable_F8C2B2` fixed them for 0xF8C485/0xF8C652. Left
  `.incbin`, refused, narrowed to exactly these 81 bytes.

RUN
  python3 notes/gen_prom_a_f8e6fa_module.py --check
  python3 notes/gen_prom_a_f8e6fa_module.py --emit > /tmp/f8e6fa_region.s
  python3 prom_a/insert_region.py 0xF8E6FA 0xF8E77C /tmp/f8e6fa_region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import roundtrip as RT  # noqa: E402

BASE = 0xF80000
LO, HI = 0xF8E6FA, 0xF8E77C          # converted, 130 B
CODE_LO, CODE_HI = 0xF8E6FA, 0xF8E773  # 121 B of code, ending in `reti`
DATA_LO, DATA_HI = 0xF8E773, 0xF8E77C  # 9 B, LDIR source, all zero
TAIL_LO, TAIL_HI = 0xF8E77C, 0xF8E7CD  # 81 B, REFUSED, left .incbin

DUP_SRC_LO, DUP_SRC_HI = 0xF8E6E2, 0xF8E6FA  # already-converted MemCopyWords


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def read(lo, hi):
    return rom()[lo - BASE:hi - BASE]


def scan_pointer(addr):
    lo, mid, hi = addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF
    data = rom()
    return data.count(bytes([lo, mid, hi])), data.count(bytes([lo, mid, hi, 0x00]))


def cmd_check():
    ok = True
    checks = []

    dup = read(0xF8E6FB, 0xF8E713)
    src = read(DUP_SRC_LO, DUP_SRC_HI)
    checks.append(("0xF8E6FB-0xF8E712 is a byte-for-byte duplicate of "
                    "MemCopyWords (0xF8E6E2-0xF8E6F9)", dup == src))

    checks.append(("0xF8E6FA-0xF8E772 (code) is self-consistent: 0 undecodable "
                    "bytes, 0xF8E772 an instruction boundary",
                    RT_selfconsistent(0xF8E6FA, 0xF8E772)))

    ldir_src_ref = read(0xF8E74B, 0xF8E750)
    checks.append(("the init routine's own `lda XIY,(0xf8e773)` literally "
                    "names the data span's start",
                    ldir_src_ref == bytes([0xf2, 0x73, 0xe7, 0xf8, 0x35])))
    ldir_count_ref = read(0xF8E755, 0xF8E75A)
    checks.append(("...and its own `ld XBC,9` literally names the data span's "
                    "length", ldir_count_ref == bytes([0x41, 0x09, 0x00, 0x00, 0x00])))
    data9 = read(DATA_LO, DATA_HI)
    checks.append(("the 9 named bytes are all zero", data9 == b"\x00" * 9))

    checks.append(("byte accounting: converted 130 B = 121 (code) + 9 (data)",
                    (DATA_HI - CODE_LO) == 130 and (CODE_HI - CODE_LO) == 121
                    and (DATA_HI - DATA_LO) == 9))
    checks.append(("refused tail is exactly 81 B (0xF8E7CD-0xF8E77C)",
                    TAIL_HI - TAIL_LO == 81))
    checks.append(("130 + 81 = 211 = the original .incbin length",
                    (DATA_HI - CODE_LO) + (TAIL_HI - TAIL_LO) == 211))

    checks.append(("no reader anywhere in the ROM cites 0xF8E77C (refused "
                    "tail's nominal start)", scan_pointer(0xF8E77C) == (0, 0)))
    checks.append(("no reader anywhere in the ROM cites 0xF8E7A9 (the "
                    "byte-shifted apparent second table start)",
                    scan_pointer(0xF8E7A9) == (0, 0)))

    region = build_region()
    src_text = RT.macro_prelude() + "\n\t.text\n" + region
    got = RT.assemble_block(src_text)
    expected = read(LO, HI)
    checks.append(("the 130 B converted region round-trips byte-exact through llvm-mc",
                    got == expected))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def RT_selfconsistent(lo, hi):
    import prom_a_linear_decode_check as C
    return C.run(lo, hi, quiet=True)


def _block_text(lo, hi):
    lines, good, stats = RT.emit_block(lo, hi)
    if not good:
        sys.stderr.write("!! block 0x%06X-0x%06X did NOT round-trip: %r\n"
                          % (lo, hi, dict(stats)))
        sys.exit(1)
    out = []
    for l, addr, bs, why in lines:
        if addr is None:
            out.append(l)
        else:
            raw = " ".join("%02x" % b for b in bs)
            out.append("%-46s ; %06X  %s" % (l, addr, raw))
    return "\n".join(out)


def build_region():
    parts = []
    parts.append("; ---------------------------------------------------------------------")
    parts.append("; 0xF8E6FA-0xF8E77C (130 B) -- CONVERTED, see")
    parts.append("; notes/FINDINGS-prom_a-f8e6fa-boundary.md.  0xF8E77C-0xF8E7CD (81 B)")
    parts.append("; REMAINS .incbin below, refused: no reader in the ROM cites it and the")
    parts.append("; apparent pointer table's own alignment breaks partway through.")
    parts.append("; ---------------------------------------------------------------------")
    parts.append(_block_text(CODE_LO, CODE_HI))
    parts.append("ZeroInitData_F8E773:   ; 9 B, all zero -- LDIR source named by the")
    parts.append("; init routine above: `lda XIY,(0xf8e773)` / `ld XBC,0x00000009`")
    parts.append("\t.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; F8E773")
    return "\n".join(parts) + "\n"


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--emit" in sys.argv:
        print(build_region())
        return
    sys.exit("usage: --check | --emit")


if __name__ == "__main__":
    main()
