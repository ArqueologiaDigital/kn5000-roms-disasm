#!/usr/bin/env python3
"""Cross-model census of TONE-GENERATOR DATA LITERALS: KN5000 vs the MN10300 generation.

THE QUESTION IT ANSWERS
-----------------------
The KN6000 and KN7000 are known to share a tone-generator driver because their TG
write primitives are BYTE-IDENTICAL (both MN10300).  The KN5000's sub-CPU is a
Toshiba TLCS-900/H2, so a byte comparison against it is meaningless by construction
-- a null there would measure the instruction set, not the driver.

This probe runs the comparison that IS valid across an architecture boundary:
the vocabulary of HARD-CODED 16-BIT DATA VALUES each firmware pushes into its tone
generator, and which register each value lands in.  Constants survive recompilation
onto a different CPU; opcodes do not.  It is the same instrument the project already
uses for the KN5000<->KN7000 UI-framework match (shared strings/symbols), applied to
the audio driver.

WHAT IS READ, AND WHAT COUNTS AS A HIT
--------------------------------------
KN5000  (sub-CPU, TLCS-900, this repo's disassembly)
    signal : `ldw (0x100002:24), 0xNNNN`  -- an immediate store to the IC303 DATA
             port.  0x100000 is the ADDRESS latch, 0x100002 the DATA port.
    the paired latch value is `add wa, 0xNNN` on the preceding lines; register
    number = latch >> 6, because latch = (register << 6) | channel.

KN6000  (MN10300, program flash, ROM_LOAD32_WORD-interleaved from the romset)
    signal : `fc e4 <imm32 LE>` (= `or imm32,d0`) immediately followed by `cd`
             (= `call`).  The KN6000 packs the whole TG transaction into d0 as
             (voice << 20) | (class << 16) | data and calls the write primitive at
             0x4849465B, so the imm32's high half is the register class and its low
             half is the DATA literal.  Scanning `or ... ; call` therefore enumerates
             the driver's entire literal vocabulary with its destination register.

PASS / EXPECTED OUTPUT (measured 2026-09-23)
--------------------------------------------
  * KN6000 write primitive at 0x4849465B is 20 bytes, and the identical 20 bytes
    occur in the KN7000 program ROM at 0x487EFF7C (the flash-resident original of
    the RAM-resident 0x4C036F7C leg quoted in kn7000_mame/src/mame/matsushita/
    kn_tonegen.h).  This re-derives that claim from the romsets.
  * KN5000 TG data literals, complete: FF80 x11, FF00 x11, 8100 x7, A280 x6,
    A200 x6, 7E00 x3, 0000 x3.   Seven values, nothing else.
  * KN6000 TG data literals: 0000, C000, A280, 7F80, FF80, FF00, A200, 7F00, 4000.
    (0x87FF, the gate, is built by a SHORT `or 0x87ff,d0` and is not in this scan.)
  * INTERSECTION, excluding 0x0000:  FF80, FF00, A280, A200.
    Those four are exactly the two <X>80 / <X>00 PAIRS that both firmwares send to
    the FIRST TWO REGISTERS of the amplitude-envelope bank, 0x**80 to the lower
    register number and 0x**00 to the higher, on both machines.
  * SPECIFICITY: in the KN5000 sub-CPU ROM image the 16-bit value 0xA280 occurs
    6 times TOTAL, at any alignment, and all 6 are TG data writes.  It occurs
    nowhere else in the image.  0xA280 is not a round constant; this is what makes
    the overlap a result rather than an artefact of both firmwares liking 0xFF.
  * The two KN5000 literals with NO counterpart -- 0x8100 and 0x7E00 -- are its
    GATE values (register 0x00).  The gate is also the one register that provably
    MOVES between the KN6000 and the KN7000 (r0 vs r3), so the one place the
    correspondence fails is the one place the family's own variation already lives.

HOW TO RUN (from the repository root)
-------------------------------------
    python3 analysis/tonegen-register-interface/tg_literal_crossmodel.py \
        --romset ~/compartilhado/technics_romsets

Without --romset only the KN5000 half runs.  The KN6000/KN7000 halves need
kn6000.zip / kn7000.zip (the MAME romsets); nothing is written to disk.
"""

import argparse
import collections
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SUB_ASM = os.path.join(ROOT, "v142", "subcpu", "kn5000_subprogram_v142.s")
SUB_ROM = os.path.join(ROOT, "original_ROMs", "kn5000_subprogram_v142.rom")

# IC303 ports on the sub-CPU bus.
TG_ADDR_PORT = "0x100000"
TG_DATA_PORT = "0x100002"

# The MN10300 generation's TG literal vocabulary is compared against this set.
MN10300_BASE = 0x48400000
KN6000_PRIMITIVE = 0x4849465B


def interleave32(even: bytes, odd: bytes) -> bytes:
    """ROM_LOAD32_WORD: even half supplies bytes 0-1 of each dword, odd half 2-3."""
    out = bytearray(len(even) + len(odd))
    for i in range(0, len(even), 2):
        out[2 * i:2 * i + 2] = even[i:i + 2]
        out[2 * i + 2:2 * i + 4] = odd[i:i + 2]
    return bytes(out)


def load_romset(path, even_name, odd_name):
    with zipfile.ZipFile(path) as z:
        names = {os.path.basename(n): n for n in z.namelist()}
        e = z.read(names[even_name])
        o = z.read(names[odd_name])
    return interleave32(e, o)


def kn5000_literals():
    """Every hard-coded 16-bit value the sub-CPU stores to the IC303 data port."""
    src = open(SUB_ASM, encoding="utf-8", errors="replace").read()
    pat = re.compile(r"ldw \(" + re.escape(TG_DATA_PORT) + r":24\), (0x[0-9a-fA-F]+)")
    vals = collections.Counter(int(m.group(1), 16) for m in pat.finditer(src))
    return vals


def kn5000_latch_registers():
    """Register numbers reached by `add wa, <latch>` before an address-port store."""
    lines = open(SUB_ASM, encoding="utf-8", errors="replace").read().splitlines()
    addr_store = "ld (" + TG_ADDR_PORT + ":24), wa"
    regs = collections.Counter()
    for i, ln in enumerate(lines):
        if addr_store not in ln:
            continue
        # walk back a few lines for the bank add that built WA
        for j in range(i - 1, max(-1, i - 6), -1):
            m = re.search(r"add wa, (0x[0-9a-fA-F]+)\s*$", lines[j])
            if m:
                regs[int(m.group(1), 16) >> 6] += 1
                break
    return regs


def rom_value_counts(blob, values):
    return {v: len(re.findall(re.escape(v.to_bytes(2, "little")), blob)) for v in values}


def mn10300_literals(blob):
    """`or imm32,d0` immediately followed by a call = one packed TG transaction."""
    data = collections.Counter()
    cls = collections.Counter()
    for m in re.finditer(rb"\xfc\xe4(....)\xcd", blob):
        imm = int.from_bytes(m.group(1), "little")
        cls[(imm >> 16) & 0xFFFF] += 1
        data[imm & 0xFFFF] += 1
    return data, cls


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--romset", help="directory holding kn6000.zip / kn7000.zip")
    args = ap.parse_args()

    print("== KN5000 (TLCS-900 sub-CPU): hard-coded IC303 data literals ==")
    k5 = kn5000_literals()
    for v, c in k5.most_common():
        print(f"   0x{v:04X}  x{c}")

    print("\n== KN5000: register numbers reached by the address latch ==")
    regs = kn5000_latch_registers()
    print("   " + " ".join(f"{r:02X}({c})" for r, c in sorted(regs.items())))

    if os.path.exists(SUB_ROM):
        blob = open(SUB_ROM, "rb").read()
        print(f"\n== KN5000: raw 16-bit occurrences in the {len(blob)}-byte sub ROM image ==")
        print("   (specificity check: a literal that appears ONLY as a TG write is a"
              " strong signal)")
        for v, c in rom_value_counts(blob, sorted(k5)).items():
            print(f"   0x{v:04X}  {c} in image   vs  {k5[v]} TG writes")

    if not args.romset:
        print("\n(no --romset given; KN6000/KN7000 halves skipped)")
        return 0

    k6 = load_romset(os.path.join(args.romset, "kn6000.zip"),
                     "kn6000_program_even.ic12", "kn6000_program_odd.ic11")
    k7 = load_romset(os.path.join(args.romset, "kn7000.zip"),
                     "kn7000_program_even.ic17", "kn7000_program_odd.ic16")

    off = KN6000_PRIMITIVE - MN10300_BASE
    prim = k6[off:off + 20]
    print(f"\n== MN10300 write primitive, KN6000 0x{KN6000_PRIMITIVE:08X} ==")
    print("   " + prim.hex(" "))
    hits = [MN10300_BASE + m.start() for m in re.finditer(re.escape(prim), k7)]
    print("   same 20 bytes in the KN7000 program ROM at: "
          + (", ".join(f"0x{h:08X}" for h in hits) or "NOWHERE"))

    print("\n== KN6000: TG data literals (or imm32,d0 ; call) ==")
    data, cls = mn10300_literals(k6)
    for v, c in data.most_common():
        print(f"   0x{v:04X}  x{c}")

    shared = sorted(set(k5) & set(data) - {0x0000})
    print("\n== INTERSECTION (0x0000 excluded) ==")
    print("   " + " ".join(f"0x{v:04X}" for v in shared))
    print("   KN5000 only: "
          + " ".join(f"0x{v:04X}" for v in sorted(set(k5) - set(data))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
