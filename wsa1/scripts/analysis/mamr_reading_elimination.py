#!/usr/bin/env python3
"""Which reading of MAMR survives the WSA1's OWN firmware?

QUESTION.  MAME names MSAR/MAMR and never decodes them (tmp95c061.cpp:1313 and
:1329 are bare stores into m_mem_start_reg / m_mem_start_mask, which nothing
else reads).  No TMP95C061 databook exists in these trees.  The sibling project
(../kn5000-roms-disasm -> kn5000-docs/tmp94c241-memory-controller.md) carries a
reconstruction that grades ITSELF unproven, and explicitly records that a rival
64 KB-granularity reading was once "confirmed" just as convincingly.  Importing
either one and calling it derived is how that project got burned.

So this script does not import a reading.  It enumerates every combination of

    granularity   32 KB per MAMR unit   vs   64 KB per MAMR unit
    base          MSAR<<16 truncated to the window   vs   taken literally
    priority      higher-numbered CS wins   vs   lower-numbered CS wins

= 8 candidate decoders, feeds each the register values the two boot blocks
actually write, and checks them against facts that come from the firmware
itself, not from any datasheet:

  CPU 1
    F1  0x600000 must be served by CS3.
        RESET clears 0x600000-0x6033FF and 0x604000-0x60FFFF (prom_a 0xF8279A,
        0xF827AF), so something answers there; MSAR3 = 0x60 aims CS3 at it; and
        `ldio P6FC,0x1F` at 0xF826B2 turns the CS3 pin into LCAS -- port 6 is
        "Shared with CS0, CS1, CS3/LCAS, RAS, REFOUT" (tmp95c061.h:19).  A
        chip-select area that wins over CS3 there would leave the DRAM
        unaddressable.
    F2  0x7E0000 must be served by CS0.
        prom_a 0xFE509B writes B0CS = 0x10, runs 256 iterations that each call
        0xFE4CE0 -- `add XWA,0x007E0000` then `ld HL,(XWA)` -- and then restores
        B0CS = 0x14 at 0xFE50D5.  Retuning B0CS around reads of an address that
        another chip select answers would be a no-op.
    F3  0x000080 (cleared by RESET, above the internal I/O registers) must be
        served by CS1, which is the only area MSAR1 = 0x00 aims there.
    F4  0xF80000 and 0xF00000 (this CPU's two EPROMs) must be served by CS2.

  CPU 2
    F5  0xC00000 must NOT be served by CS2.  prom_c reads the expansion board's
        header there (0xFB6B6E `ld XIX,0x00C00000`, then +0x18 and +0x31), and
        CS2's devices are the flash and this EPROM.
    F6  0xE80000 (the flash) and 0xF80000 (this EPROM) must be served by CS2.
        The flash width fact -- unlock addresses 0xAAAA/0x5554, i.e. 2x the
        AMD byte-mode 0x5555/0x2AAA -- is what proves that CS window is 16 bits
        wide, and prom_c shares it.
    F7  0x100000 (the link port to CPU 1) must be served by CS0; MSAR0 = 0x10
        is the write that proves MSAR means A23-A16 in the first place, since
        `ld XIX,0x00100000` follows it 0x2F bytes later at 0xFFF067.
    F8  0x000080 (cleared by prom_c's RESET) must be served by CS3.

WHAT THIS CAN AND CANNOT DO.  It cannot prove a reading -- a ninth semantics
nobody has thought of is not on the list, and the eight it does test all assume
"size = unit * (MAMR+1)" with the mask being contiguous from the bottom.  What
it can do is KILL readings, and a reading killed by this machine's own firmware
stays killed no matter what another model's service manual says.

Run:  python3 scripts/analysis/mamr_reading_elimination.py
Exit 0 if the byte re-reads all match; non-zero if any cited byte is not what
this script says it is.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
IMG = {
    "a": os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"),
    "b": os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"),
    "c": os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"),
}

# ---------------------------------------------------------------- byte re-reads
# (rom, cpu address, expected bytes, what it is)
CITED = [
    ("a", 0xF826B2, "08151f", "ldio P6FC,0x1F -- CS3 pin becomes LCAS"),
    ("a", 0xF8272D, "083c78", "ldio MSAR0,0x78"),
    ("a", 0xF82730, "083e00", "ldio MSAR1,0x00"),
    ("a", 0xF82733, "085ce0", "ldio MSAR2,0xE0"),
    ("a", 0xF82736, "085e60", "ldio MSAR3,0x60"),
    ("a", 0xF82739, "083d3f", "ldio MAMR0,0x3F"),
    ("a", 0xF8273C, "083f7f", "ldio MAMR1,0x7F"),
    ("a", 0xF8273F, "085d3f", "ldio MAMR2,0x3F"),
    ("a", 0xF82742, "085f0f", "ldio MAMR3,0x0F"),
    ("a", 0xF8279F, "4400006000", "ld XIX,0x00600000 -- DRAM clear target"),
    ("a", 0xFE509B, "086810", "ldio B0CS,0x10 -- retune before the transfer"),
    ("a", 0xFE4CF8, "e8c80000 7e00".replace(" ", ""), "add XWA,0x007E0000"),
    ("a", 0xFE4CFE, "9023", "ld HL,(XWA) -- the read through 0x7E0000"),
    ("a", 0xFE50D5, "086814", "ldio B0CS,0x14 -- retune after the transfer"),
    ("c", 0xFFF01A, "08151f", "ldio P6FC,0x1F on CPU 2 as well"),
    ("c", 0xFFF038, "083c10", "ldio MSAR0,0x10"),
    ("c", 0xFFF03B, "083d07", "ldio MAMR0,0x07"),
    ("c", 0xFFF03E, "083ec0", "ldio MSAR1,0xC0"),
    ("c", 0xFFF041, "083f7f", "ldio MAMR1,0x7F"),
    ("c", 0xFFF044, "085ce0", "ldio MSAR2,0xE0"),
    ("c", 0xFFF047, "085d3f", "ldio MAMR2,0x3F"),
    ("c", 0xFFF04A, "085e00", "ldio MSAR3,0x00"),
    ("c", 0xFFF04D, "085f03", "ldio MAMR3,0x03"),
    ("c", 0xFFF067, "4400001000", "ld XIX,0x00100000 -- proves MSAR = A23-A16"),
    ("c", 0xFB6B6E, "4400 00c000".replace(" ", ""), "ld XIX,0x00C00000 -- EXTBD header"),
]

CPU1 = dict(msar=[0x78, 0x00, 0xE0, 0x60], mamr=[0x3F, 0x7F, 0x3F, 0x0F])
CPU2 = dict(msar=[0x10, 0xC0, 0xE0, 0x00], mamr=[0x07, 0x7F, 0x3F, 0x03])

# (address, required CS or None-for-"must not be this CS", label)
FACTS1 = [
    (0x600000, 3, True,  "F1 work DRAM is on CS3 (CS3 pin is LCAS)"),
    (0x7E0000, 0, True,  "F2 0x7E0000 is on CS0 (B0CS retuned around reads of it)"),
    (0x000080, 1, True,  "F3 static RAM is on CS1"),
    (0xF80000, 2, True,  "F4 prom_a is on CS2"),
    (0xF00000, 2, True,  "F4 prom_b is on CS2"),
]
FACTS2 = [
    (0xC00000, 2, False, "F5 the expansion board is NOT on CS2"),
    (0xE80000, 2, True,  "F6 the flash is on CS2"),
    (0xF80000, 2, True,  "F6 prom_c is on CS2"),
    (0x100000, 0, True,  "F7 the link port is on CS0"),
    (0x000080, 3, True,  "F8 work DRAM is on CS3"),
]


def window(msar, mamr, unit, literal):
    size = unit * (mamr + 1)
    start = msar << 16
    if not literal:
        start &= ~(size - 1) & 0xFFFFFF
    return start, size


def decode(addr, regs, unit, literal, higher_wins):
    hit = [n for n in range(4)
           if (lambda s, z: s <= addr < s + z)(*window(regs["msar"][n], regs["mamr"][n], unit, literal))]
    if not hit:
        return None
    return max(hit) if higher_wins else min(hit)


def main():
    print("=" * 78)
    print("byte re-reads (every address this script argues from)")
    print("=" * 78)
    bad = 0
    for rom, addr, hexbytes, what in CITED:
        want = bytes.fromhex(hexbytes)
        off = addr - BASE[rom]
        with open(IMG[rom], "rb") as fh:
            fh.seek(off)
            got = fh.read(len(want))
        ok = got == want
        bad += not ok
        print(f"  {'PASS' if ok else 'FAIL'}  prom_{rom} 0x{addr:06X}  {got.hex()}  {what}")
    if bad:
        print(f"\nFAIL: {bad} cited byte(s) are not what this script claims.")
        return 2

    print()
    print("=" * 78)
    print("eight candidate decoders vs the firmware's own facts")
    print("=" * 78)
    survivors = []
    for unit, uname in ((32 << 10, "32K"), (64 << 10, "64K")):
        for literal, lname in ((False, "trunc"), (True, "literal")):
            for hw, hname in ((True, "hi-wins"), (False, "lo-wins")):
                fails = []
                for regs, facts, cpu in ((CPU1, FACTS1, 1), (CPU2, FACTS2, 2)):
                    for addr, cs, must, label in facts:
                        got = decode(addr, regs, unit, literal, hw)
                        if (got == cs) != must:
                            fails.append(f"CPU{cpu} {label} -> CS{got}")
                tag = f"{uname}/{lname}/{hname}"
                if fails:
                    print(f"  ELIMINATED  {tag:22s} {fails[0]}"
                          + (f"  (+{len(fails)-1} more)" if len(fails) > 1 else ""))
                else:
                    survivors.append((tag, unit, literal, hw))
                    print(f"  survives    {tag:22s} --")

    print()
    print("=" * 78)
    print("what the survivors agree and disagree on")
    print("=" * 78)
    if not survivors:
        print("  NOTHING SURVIVES -- one of the eight assumptions or one of the facts")
        print("  is wrong.  Do not write a memory map until this is resolved.")
        return 1
    print(f"  {len(survivors)} of 8 survive: " + ", ".join(t for t, *_ in survivors))
    print()
    for regs, cpu in ((CPU1, 1), (CPU2, 2)):
        print(f"  --- CPU {cpu} ---")
        for n in range(4):
            spans = set()
            for _, unit, literal, hw in survivors:
                s, z = window(regs["msar"][n], regs["mamr"][n], unit, literal)
                spans.add((s, z))
            if len(spans) == 1:
                s, z = spans.pop()
                print(f"    CS{n}  0x{s:06X}-0x{s+z-1:06X}   ({z>>10} KB)  AGREED")
            else:
                txt = " | ".join(f"0x{s:06X}-0x{s+z-1:06X}" for s, z in sorted(spans))
                print(f"    CS{n}  {txt}   NOT ESTABLISHED")
    print()
    print("  Read this as elimination, not as proof.  All eight candidates assume")
    print("  size = unit*(MAMR+1) with a contiguous bottom-up mask; a semantics")
    print("  outside that family is untested here.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
