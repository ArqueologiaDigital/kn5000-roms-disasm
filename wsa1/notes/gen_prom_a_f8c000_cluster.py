#!/usr/bin/env python3
"""Emit the prom_a 0xF8C000-0xF8C2EC cluster (231 B across 7 items) plus
0xF97503-0xF97533 (48 B), all licensed by an inbound reference ALREADY
PRESENT in already-converted code -- not a walk-plausibility argument.

QUESTION IT ANSWERS
  0xF8C000-0xF8C842 sits inside notes/gen_prom_a_cover_round1.py's coverage,
  which explicitly declines it ("5412 bytes that nothing reaches stay
  `.incbin`").  What changed: reading the ALREADY-CONVERTED code immediately
  around each gap turns up a literal, opcode-anchored citation of that gap's
  address, in every one of the 8 pieces below -- something round 1's walk,
  which only follows STRONG seed classes, does not credit.

THE EIGHT PIECES

  1. sub_F8C000 (50 B, CODE).  Preceded by 222 bytes of `.fill 0x0E` (a
     verified module boundary -- notes/gen_prom_a_block.py already checked
     it byte by byte) and followed immediately by the established
     sub_F8C032.  `jp 0xf8c018` skips five dead `ret/nop/nop/nop` veneer
     slots -- the same "unused vector slot" shape already accepted for the
     0xFE0000 module header (six `jp` veneers, FINDINGS-prom_a-fcf000-module
     precedent: "what pins the start is module structure, not the decode").
     0xF8C018 itself does five `ld (addr),0x05` writes and returns. No
     inbound literal pointer was found for the module START (a whole-ROM
     3-byte scan for 0x00C0F8 turns up one hit, at 0xFAD2C9, already
     explained as a `.long` stride table with no relation -- see --check).
     What pins the start is the SAME structural argument already accepted
     for 0xFE0000, not a fresh one.

  2-6. Five CmdList_* tables (8+22+15+15+15 = 75 B, DATA).  Every one has an
     explicit `ld XIY,<this address>` in ALREADY-EXISTING code immediately
     before it (5/5), and every one of those five sites' following `calr`
     resolves -- by the SAME relative-displacement arithmetic the ROM
     itself encodes, not anything this pass invented -- to the IDENTICAL
     address, 0xF8C16D. That address is `.LF8C16D: cp (XIY),0xff` in
     ALREADY-CONVERTED code: a parser that walks records via XIY and tests
     for the exact terminator byte (0xFF) this pass independently derived
     from the record structure. Each table is N x 7-byte records + one
     0xFF terminator byte, zero remainder in all five.

  7. DispatchTable_F8C2B2 (58 B, DATA).  A list of variable-length entries:
     a 2-byte id, then EITHER a placeholder (id == 0xFFFF, entry is 2 bytes
     total) or a 4-byte little-endian pointer (entry is 6 bytes total).
     Zero remainder over the full 58 bytes. All 8 non-placeholder pointers
     land inside the union of the two immediately following, still-`.incbin`
     spans, 0xF8C485-0xF8C630 and 0xF8C652-0xF8C842 -- two of them (0xF8C485
     and 0xF8C652) are those spans' exact START addresses. This is the
     strongest evidence yet that those two spans are real entry points, but
     NEITHER IS CONVERTED THIS PASS: 0xF8C485-0xF8C630 decodes
     self-consistently overall (0 db, 0xF8C630 a boundary) but one of the
     table's OTHER internal targets, 0xF8C4D8, lands 3 bytes off a decode
     boundary next to a cluster of suspicious mnemonics (`normal`, `max`,
     several bare `nop`s) -- exactly the kind of subtle mid-span drift this
     project's own history says not to paper over. 0xF8C652-0xF8C842 fails
     outright: 8 undecodable bytes at a ~16-byte stride (0xF8C687 through
     0xF8C708), the signature of an embedded fixed-stride table, not a
     misread of pure code. Both are left `.incbin`, refused, with this
     finding recorded as the lead for whoever takes them next.

  8. sub_F97503 (48 B, CODE).  `push XIZ/XIX/XHL/XDE ... pop XDE/XHL/XIX/XIZ
     / ret` -- the canonical four-register save/restore shape used
     throughout this tree.  Reached via a COMPUTED jump: already-converted
     code at 0xF98628 does `lda_24 xix, (0xf97503)`, and the SAME routine
     later executes `push XIY / jp (xix)` (twice, 0xF98670 and 0xF986CF) --
     a manual call-with-return-address idiom whose target is the address
     this pass converts. This is not a bare pointer citation; XIX is
     actually jumped through.

RUN
  python3 notes/gen_prom_a_f8c000_cluster.py --check
  python3 notes/gen_prom_a_f8c000_cluster.py --emit-<name> for each of:
      f8c000 cmdlist1 cmdlist2 cmdlist3 cmdlist4 cmdlist5 dispatch f97503
  python3 prom_a/insert_region.py <lo> <hi> /tmp/<name>.s   (once per piece)
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import prom_a_linear_decode_check as C  # noqa: E402
import roundtrip as RT                   # noqa: E402

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def rb(lo, hi):
    return ROM[lo - BASE:hi - BASE]


F8C000 = (0xF8C000, 0xF8C032)
CMDLISTS = [
    (0xF8C046, 0xF8C04E, "CmdList_F8C046", 0xF8C03D),
    (0xF8C05B, 0xF8C071, "CmdList_F8C05B", 0xF8C052),
    (0xF8C086, 0xF8C095, "CmdList_F8C086", 0xF8C07D),
    (0xF8C0A4, 0xF8C0B3, "CmdList_F8C0A4", 0xF8C09B),
    (0xF8C0C1, 0xF8C0D0, "CmdList_F8C0C1", 0xF8C0B8),
]
DISPATCH = (0xF8C2B2, 0xF8C2EC, "DispatchTable_F8C2B2")
F97503 = (0xF97503, 0xF97533)
PARSER = 0xF8C16D          # .LF8C16D: cp (XIY),0xff -- already-converted code
NEIGHBOURS = [(0xF8C485, 0xF8C630), (0xF8C652, 0xF8C842)]  # NOT converted


def parse_records(lo, hi):
    """N x 7-byte record + one 0xFF terminator.  Returns (records, ok)."""
    data = rb(lo, hi)
    if data[-1] != 0xFF:
        return None, False
    body = data[:-1]
    if len(body) % 7 != 0:
        return None, False
    recs = [body[i:i + 7] for i in range(0, len(body), 7)]
    return recs, True


def parse_dispatch(lo, hi):
    """2-byte id; id==0xFFFF -> 2-byte placeholder, else + 4-byte LE32 ptr."""
    data = rb(lo, hi)
    i = 0
    entries = []
    while i < len(data):
        if i + 2 > len(data):
            return None
        idv = data[i] | (data[i + 1] << 8)
        if idv == 0xFFFF:
            entries.append(("placeholder", None))
            i += 2
        else:
            if i + 6 > len(data):
                return None
            ptr = data[i + 2] | (data[i + 3] << 8) | (data[i + 4] << 16) | (data[i + 5] << 24)
            entries.append((idv, ptr))
            i += 6
    return entries


def cmd_check():
    ok = True
    checks = []

    # module header: self-consistent, padding before, established code after
    checks.append(("0xF8C000-0xF8C032 self-consistent",
                    C.run(*F8C000, quiet=True)))
    pad = rb(0xF8BF22, 0xF8C000)
    checks.append(("0xF8BF22-0xF8C000 is 222 bytes of pure 0x0E (verified module boundary)",
                    len(pad) == 222 and set(pad) == {0x0E}))
    hit = ROM.find(bytes([0x00, 0xC0, 0xF8]))
    checks.append(("whole-ROM scan for a pointer to 0xF8C000: exactly 1 hit, at 0xFAD2C9 "
                    "(a .long stride-table coincidence, not a real reference)",
                    hit == 0xFAD2C9 - BASE
                    and ROM.find(bytes([0x00, 0xC0, 0xF8]), hit + 1) == -1))

    # 5 CmdList tables
    calr_targets = set()
    for lo, hi, name, reader_addr in CMDLISTS:
        recs, good = parse_records(lo, hi)
        checks.append((f"{name}: N x 7B records + 0xFF terminator, zero remainder",
                        good))
        rows = C.decode(reader_addr, lo)
        ld_xiy = [t for a, l, t in rows if t == f"ld XIY,0x00{lo:06x}"]
        checks.append((f"{name}: reader has `ld XIY,0x00{lo:06x}` immediately before it",
                        len(ld_xiy) == 1))
        rows2 = C.decode(reader_addr, lo + 8)
        calr = [t for a, l, t in rows2 if t.startswith("calr 0x")]
        targets = {int(t.split()[1], 16) for t in calr}
        calr_targets |= targets
    checks.append(("all 5 CmdList readers' `calr` resolve to the SAME address, 0xF8C16D",
                    calr_targets == {PARSER}))
    checks.append((f"0x{PARSER:06X} is `.LF8C16D: cp (XIY),0xff` in already-converted code",
                    "cp (XIY),0xff" in open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()))

    # dispatch table
    lo, hi, name = DISPATCH
    entries = parse_dispatch(lo, hi)
    checks.append((f"{name}: variable-length id/pointer parse consumes exactly {hi-lo} bytes",
                    entries is not None))
    real = [(i, p) for i, p in entries if i != "placeholder"]
    in_neighbour = sum(1 for _, p in real
                        if any(nlo <= p < nhi for nlo, nhi in NEIGHBOURS))
    checks.append((f"{name}: {len(real)} non-placeholder pointers, "
                    f"{in_neighbour}/{len(real)} land inside the two neighbouring spans",
                    in_neighbour == len(real) and len(real) == 8))
    checks.append(("two of those pointers are the neighbours' own START addresses",
                    any(p == 0xF8C485 for _, p in real) and any(p == 0xF8C652 for _, p in real)))

    # the two neighbours are NOT converted, and here is why
    checks.append(("0xF8C485-0xF8C630 self-consistent OVERALL but 1 internal target "
                    "(0xF8C4D8) is off-boundary -- NOT converted",
                    C.run(0xF8C485, 0xF8C630, quiet=True)
                    and 0xF8C4D8 not in {a for a, _, _ in C.decode(0xF8C485, 0xF8C640)}))
    checks.append(("0xF8C652-0xF8C842 is NOT self-consistent (undecodable bytes) -- NOT converted",
                    not C.run(0xF8C652, 0xF8C842, quiet=True)))

    # sub_F97503
    checks.append(("0xF97503-0xF97533 self-consistent", C.run(*F97503, quiet=True)))
    src = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()
    checks.append(("0xF98628 already has `lda_24 xix, (0xf97503)`",
                    "lda_24 xix, (0xf97503)" in src))
    checks.append(("the same routine executes `jp (xix)` (computed jump through it)",
                    src.count("jp (xix)") >= 1))

    total = ((F8C000[1] - F8C000[0]) + sum(hi - lo for lo, hi, _, _ in CMDLISTS)
             + (DISPATCH[1] - DISPATCH[0]) + (F97503[1] - F97503[0]))
    checks.append(("byte accounting: 50 + 75 + 58 + 48 = 231", total == 231))

    for name, passed in checks:
        print(f"  {name:<85s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def _emit_code(lo, hi, label):
    lines, good, stats = RT.emit_block(lo, hi)
    if not good:
        sys.stderr.write("!! 0x%06X-0x%06X did not round-trip: %r\n" % (lo, hi, dict(stats)))
        sys.exit(1)
    print(f"{label}:")
    for l, addr, bs, why in lines:
        if addr is None:
            print(l)
        else:
            raw = " ".join("%02x" % b for b in bs)
            print("%-46s ; %06X  %s" % (l, addr, raw))
    sys.stderr.write("  0x%06X-0x%06X round-trip OK  %r\n" % (lo, hi, dict(stats)))


def _emit_records(lo, hi, name, reader_addr):
    recs, good = parse_records(lo, hi)
    assert good
    print(f"; ---------------------------------------------------------------------")
    print(f"; {name} -- {hi - lo} bytes, {len(recs)} x 7-byte record(s) + 0xFF "
          f"terminator.")
    print(f"; Reader: 0x{reader_addr:06X} `ld XIY,0x00{lo:06x}` (already-converted),")
    print(f"; whose `calr` resolves to 0xF8C16D (`.LF8C16D: cp (XIY),0xff`, also")
    print(f"; already-converted) -- the exact terminator byte below.  See")
    print(f"; notes/gen_prom_a_f8c000_cluster.py --check and")
    print(f"; notes/FINDINGS-prom_a-f8c000-cluster.md.")
    print(f"; ---------------------------------------------------------------------")
    print(f"{name}:")
    for i, r in enumerate(recs):
        print("\t.byte " + ", ".join("0x%02x" % b for b in r)
              + f"  ; {lo + i*7:06X}  record {i}")
    print(f"\t.byte 0xff" + f"  ; {hi - 1:06X}  terminator")


def _emit_dispatch():
    lo, hi, name = DISPATCH
    entries = parse_dispatch(lo, hi)
    assert entries is not None
    print(f"; ---------------------------------------------------------------------")
    print(f"; {name} -- {hi - lo} bytes.  Variable-length: a 2-byte id, then either")
    print(f"; a 2-byte placeholder (id == 0xFFFF) or a 4-byte little-endian pointer.")
    print(f"; 8 non-placeholder pointers, ALL landing inside the two neighbouring")
    print(f"; still-.incbin spans 0xF8C485-0xF8C630 and 0xF8C652-0xF8C842 (two of")
    print(f"; them are those spans' own START addresses) -- neither neighbour is")
    print(f"; converted this pass, see notes/FINDINGS-prom_a-f8c000-cluster.md.")
    print(f"; ---------------------------------------------------------------------")
    print(f"{name}:")
    addr = lo
    for idv, ptr in entries:
        if idv == "placeholder":
            print(f"\t.byte 0xff, 0xff" + f"  ; {addr:06X}  placeholder")
            addr += 2
        else:
            b0 = ptr & 0xFF; b1 = (ptr >> 8) & 0xFF
            b2 = (ptr >> 16) & 0xFF; b3 = (ptr >> 24) & 0xFF
            print("\t.byte 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x" %
                  (idv & 0xFF, (idv >> 8) & 0xFF, b0, b1, b2, b3)
                  + f"  ; {addr:06X}  id=0x{idv:04x} ptr=0x{ptr:08x}")
            addr += 6


def main():
    if "--check" in sys.argv:
        return cmd_check()
    if "--emit-f8c000" in sys.argv:
        _emit_code(*F8C000, "sub_F8C000")
        return 0
    for i, (lo, hi, name, reader) in enumerate(CMDLISTS, 1):
        if f"--emit-cmdlist{i}" in sys.argv:
            _emit_records(lo, hi, name, reader)
            return 0
    if "--emit-dispatch" in sys.argv:
        _emit_dispatch()
        return 0
    if "--emit-f97503" in sys.argv:
        _emit_code(*F97503, "sub_F97503")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
