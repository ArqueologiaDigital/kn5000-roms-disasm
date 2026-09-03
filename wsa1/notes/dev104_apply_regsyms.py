#!/usr/bin/env python3
"""Give the 0x00104000 (L7A1429) register-block literals a symbolic name.

QUESTION THIS ANSWERS
    The driver for the acoustic-modelling LSI selects a register by writing
    `block * 0x40 + channel` to 0x00104000+0x00.  In the listing every one of
    those blocks was a bare number -- `add BC,0x0140` -- so the meaning wave 19
    established (`notes/FINDINGS-l7a1429-parameter-names.md`,
    `notes/HLE-GUIDE-l7a1429.md`) was readable only in the file header and never
    at the instruction that uses it.  This script rewrites each such operand to
    a `.equ` symbol, and answers: *did the rewrite move a byte?*

WHY IT IS A REAL PROOF
    These values ARE instruction operands, so `make gate-all` is a genuine test
    of the substitution: an assembler that resolved a symbol differently would
    change 4 bytes of an `add rr,imm16` and the ROM would stop matching.  The
    same rewrite applied to a raw-byte pseudo-instruction (`extpfx*`) would NOT
    be provable, which is why this script refuses to touch one.

WHAT IT EDITS
    prom_c/devices/dev10c_dev104_drivers.s only, and only the 44 instruction
    operands listed in SITES.  Every site is keyed by the ROM ADDRESS in its own
    trailing comment, and the value already there must equal the symbol's value
    or the script aborts.  Comments are never touched: the substitution rewrites
    the instruction text left of `;` and re-pads so the `;` stays in its column.

RUN
    python3 notes/dev104_apply_regsyms.py            # apply (idempotent)
    python3 notes/dev104_apply_regsyms.py --verify   # assert every site is done
    python3 notes/dev104_apply_regsyms.py --checks   # the header's own claims
    python3 notes/dev104_apply_regsyms.py --selftest # the checks below

    --checks re-reads original_ROMs/wsa1_prom_c.ic28 -- bytes, no .s file -- for
    the three claims section 7 of the driver header makes on its own account:
    the 64-channel bound, the value of the one global register, and the census
    of 0x00104000 literals that keeps the four sub_ routines out of this
    device's story.

    --selftest requires the applier to REFUSE a site whose literal does not
    match the symbol, and to refuse an `extpfx` line.  A check that cannot go
    red is not evidence.

    Then, always:
      make LLVM_MC=... gate-all                                   # bytes
      python3 scripts/analysis/assert_comments_preserved.py ...   # prose
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
WSA1 = HERE.parent
TARGET = WSA1 / "prom_c" / "devices" / "dev10c_dev104_drivers.s"

# ---------------------------------------------------------------------------
# The symbol table.  Names come from the tone editor's own vocabulary where
# wave 19 graded one STRONG; everything else is named by its BLOCK NUMBER, so
# that a reader cannot mistake a placeholder for a finding.
# ---------------------------------------------------------------------------
BASE_SYMBOL = "DEV104_BASE"
BASE_VALUE = 0x00104000

BLOCKS = [
    (0x0000, "DEV104_BLK_0000"),
    (0x0040, "DEV104_MAIN_TUNE"),
    (0x0080, "DEV104_SUB_TUNE"),
    (0x00C0, "DEV104_POSITION"),
    (0x0100, "DEV104_BLK_0100"),
    (0x0140, "DEV104_MAIN_FITTING_DECAY"),
    (0x0180, "DEV104_SUB_FITTING_DECAY"),
    (0x01C0, "DEV104_MAIN_FITTING_RISE"),
    (0x0200, "DEV104_SUB_FITTING_RISE"),
    (0x0240, "DEV104_BLK_0240"),
    (0x0280, "DEV104_SUB_GAIN"),
    (0x02C0, "DEV104_BLK_02C0"),
    (0x0300, "DEV104_BLK_0300"),
    (0x0340, "DEV104_MAIN_MUTING_Q13"),
    (0x0380, "DEV104_SUB_MUTING_Q13"),
    (0x03C0, "DEV104_BLK_03C0"),
    (0x0400, "DEV104_MAIN_MUTING_Q16"),
    (0x0440, "DEV104_SUB_MUTING_Q16"),
    (0x0480, "DEV104_BLK_0480"),
    (0x0800, "DEV104_BLK_0800"),
]
BLOCK_SYM = dict(BLOCKS)

# (ROM address of the instruction, the value its operand must already hold).
# Derived by listing every `add rr,K` / `ldw (rr),K` / `ld xrr,0x00104000` in
# the Dev104_* accessor family plus the one 0x00104000 write in
# Dev10C_ResetAllChannels; --verify re-reads them from the file.
SITES = [
    # Dev104_WriteAllChanRegs -- the full 18-block walk
    (0xFB7802, BASE_VALUE), (0xFB77FE, 0x0040), (0xFB781B, 0x0080),
    (0xFB782E, 0x00C0), (0xFB7841, 0x0100), (0xFB7854, 0x0140),
    (0xFB7867, 0x0180), (0xFB787A, 0x01C0), (0xFB788D, 0x0200),
    (0xFB78A0, 0x0240), (0xFB78B3, 0x0280), (0xFB78C6, 0x02C0),
    (0xFB78D9, 0x0300), (0xFB78EC, 0x0340), (0xFB78FF, 0x0380),
    (0xFB7912, 0x03C0), (0xFB7925, 0x0400), (0xFB7938, 0x0440),
    (0xFB794B, 0x0480),
    # Dev104_SetChanRegs_01C0_0200_0240
    (0xFB797B, BASE_VALUE), (0xFB7993, 0x01C0), (0xFB79A6, 0x0200),
    (0xFB79B9, 0x0240),
    # Dev104_SetChanRegs_0140_to_0240
    (0xFB79DD, BASE_VALUE), (0xFB79F5, 0x0140), (0xFB7A08, 0x0180),
    (0xFB7A1B, 0x01C0), (0xFB7A2E, 0x0200), (0xFB7A41, 0x0240),
    # Dev104_WriteChanReg0 -- block 0 is the raw channel, so there is no
    # register-block operand here; only the device base.
    (0xFB7A5D, BASE_VALUE),
    # Dev104_SetChanRegs_00C0_0100_0240
    (0xFB7A86, BASE_VALUE), (0xFB7A82, 0x00C0), (0xFB7A9F, 0x0100),
    (0xFB7AB2, 0x0240),
    # Dev104_SetChanRegs_00C0_0100
    (0xFB7AD6, BASE_VALUE), (0xFB7AD2, 0x00C0), (0xFB7AEF, 0x0100),
    # Dev104_SetChanRegs_0140_0180
    (0xFB7B12, BASE_VALUE), (0xFB7B0E, 0x0140), (0xFB7B2B, 0x0180),
    # Dev104_SetChanReg_0280
    (0xFB7B4E, BASE_VALUE), (0xFB7B4A, 0x0280),
    # Dev10C_ResetAllChannels -- the one global write, register 0x0800
    (0xFB80F1, BASE_VALUE), (0xFB80F6, 0x0800),
]

# `add de, 64` / `add bc, 0x0140` / `ldw (xix), 0x0800` / `ld xbc, 0x00104000`
OPERAND = re.compile(r"^(?P<head>\s*\S+\s+[^,;]+,\s*)(?P<num>0x[0-9A-Fa-f]+|\d+)"
                     r"(?P<pad>\s*)$")


def symbol_for(value):
    return BASE_SYMBOL if value == BASE_VALUE else BLOCK_SYM[value]


def split_comment(line):
    """(code, gap, comment).  `gap` is the run of spaces before `;`."""
    i = line.find(";")
    if i < 0:
        return line, "", ""
    code = line[:i].rstrip()
    return code, line[len(code):i], line[i:]


def rewrite_line(line, addr, value):
    """Return the rewritten line, or raise ValueError saying why not."""
    code, gap, comment = split_comment(line)
    if "extpfx" in code:
        raise ValueError(
            "%06X is an extpfx raw-byte pseudo-instruction: its operand is a "
            "byte list, not an expression, so a symbol cannot be proved there"
            % addr)
    sym = symbol_for(value)
    if re.search(r"\b%s\b" % re.escape(sym), code):
        return line, False                      # already applied
    m = OPERAND.match(code)
    if not m:
        raise ValueError("%06X: no immediate operand in %r" % (addr, code))
    got = int(m.group("num"), 0)
    if got != value:
        raise ValueError("%06X: operand is 0x%X, expected 0x%X"
                         % (addr, got, value))
    new_code = m.group("head") + sym
    # Keep `;` in the column it is in now when the longer text still fits.
    want = len(line) - len(comment)
    pad = " " * max(1, want - len(new_code)) if comment else ""
    return new_code + pad + comment, True


def find_line(lines, addr):
    """The single line whose trailing comment is anchored at this ROM address."""
    tag = "; %06X " % addr
    hits = [i for i, ln in enumerate(lines) if tag in ln]
    if len(hits) != 1:
        raise ValueError("%06X: %d candidate lines, expected 1"
                         % (addr, len(hits)))
    return hits[0]


def run(apply_changes):
    raw = TARGET.read_bytes()
    lines = raw.decode("latin-1").split("\n")
    changed = pending = 0
    for addr, value in SITES:
        i = find_line(lines, addr)
        new, did = rewrite_line(lines[i], addr, value)
        if did:
            pending += 1
            if apply_changes:
                lines[i] = new
                changed += 1
    if apply_changes and changed:
        TARGET.write_bytes("\n".join(lines).encode("latin-1"))
    return changed, pending


# ---------------------------------------------------------------------------
# --checks: the ROM evidence behind section 7 of the driver header.
# ---------------------------------------------------------------------------
ROM = WSA1 / "original_ROMs" / "wsa1_prom_c.ic28"
ROM_BASE = 0x00F80000

# The four routines this file leaves as addresses, and their spans as their own
# wave-17 headers state them.  The census below must miss every one of them.
SUB_SPANS = [
    ("sub_FB6F2C", 0xFB6F2C, 0xFB707D),
    ("sub_FB707E", 0xFB707E, 0xFB7139),
    ("sub_FB7521", 0xFB7521, 0xFB762E),
    ("sub_FB762F", 0xFB762F, 0xFB7714),
]


def checks():
    rom = ROM.read_bytes()

    def at(addr, n):
        return rom[addr - ROM_BASE:addr - ROM_BASE + n]

    fails = 0

    def want(cond, said):
        nonlocal fails
        print("  %-4s %s" % ("ok" if cond else "FAIL", said))
        if not cond:
            fails += 1

    print("1. 64 CHANNELS, from THIS device's own writers")
    # calr disp16 is relative to the address AFTER the 3-byte instruction.
    def calr_target(addr):
        d = int.from_bytes(at(addr + 1, 2), "little", signed=True)
        return (addr + 3 + d) & 0xFFFFFF
    want(at(0xFB81A4, 1) == b"\x1e" and calr_target(0xFB81A4) == 0xFB77EF,
         "0xFB81A4 calls Dev104_WriteAllChanRegs (0xFB77EF)")
    want(at(0xFB81B9, 4) == b"\xdb\xcf\x40\x00",
         "0xFB81B9 bounds that loop with `cp HL,0x0040`")
    want(at(0xFB826B, 1) == b"\x1e" and calr_target(0xFB826B) == 0xFB7A58,
         "0xFB826B calls Dev104_WriteChanReg0 (0xFB7A58)")
    want(at(0xFB8281, 4) == b"\xdb\xcf\x40\x00",
         "0xFB8281 bounds that loop with `cp HL,0x0040`")
    # And the loop that is NOT evidence, because it drives the other device.
    want(at(0xFB8102, 5) == b"\x44\x00\xc0\x10\x00",
         "0xFB8102 reloads XIX with 0x0010C000 before the `ldb D,0x40` loop")

    print("2. THE GLOBAL REGISTER 0x0800")
    want(at(0xFB80F6, 4) == b"\xb4\x02\x00\x08",
         "0xFB80F6 selects register 0x0800 (`ld (XIX),0x0800`)")
    want(at(0xFB80FA, 5) == b"\xd2\x13\x13\xfe\x21",
         "0xFB80FA loads its value from ROM 0xFE1313")
    w = int.from_bytes(at(0xFE1313, 2), "little")
    want(w == 0x1100, "the word at 0xFE1313 is 0x%04X, i.e. 0x1100" % w)

    print("3. THE 0x00104000 CENSUS, and the four sub_ routines")
    seen = []
    for op in (0x41, 0x44):                      # ld XBC,imm32 / ld XIX,imm32
        pat = bytes([op]) + BASE_VALUE.to_bytes(4, "little")
        i = -1
        while True:
            i = rom.find(pat, i + 1)
            if i < 0:
                break
            seen.append(ROM_BASE + i)
    seen.sort()
    want(len(seen) == 9, "nine 0x00104000 literals in the image (%d)" % len(seen))
    expect = sorted(a for a, v in SITES if v == BASE_VALUE)
    want(seen == expect, "every one of them is a converted site")
    for name, lo, hi in SUB_SPANS:
        want(not any(lo <= a <= hi for a in seen),
             "%s (0x%06X-0x%06X) holds none" % (name, lo, hi))

    print("FAILURES: %d" % fails)
    return 1 if fails else 0


def selftest():
    fails = 0

    def want_error(line, addr, value, why):
        nonlocal fails
        try:
            rewrite_line(line, addr, value)
        except ValueError:
            return
        fails += 1
        print("  FAIL: accepted %s (%s)" % (line.strip(), why))

    want_error("\tadd\tbc, 0x0140      ; FB7854  add BC,0x0140", 0xFB7854,
               0x0180, "wrong literal for the symbol")
    want_error("\textpfx4 0xD9, 0xC8, 0x40, 0x01 ; FB7854  add BC,0x0140",
               0xFB7854, 0x0140, "extpfx raw-byte form")

    out, did = rewrite_line(
        "\tadd\tbc, 0x0140                             ; FB7854  x", 0xFB7854,
        0x0140)
    if not did or "DEV104_MAIN_FITTING_DECAY" not in out:
        fails += 1
        print("  FAIL: did not substitute a matching site")
    if out.index(";") != len("\tadd\tbc, 0x0140                             "):
        fails += 1
        print("  FAIL: comment column moved")
    again, did2 = rewrite_line(out, 0xFB7854, 0x0140)
    if did2 or again != out:
        fails += 1
        print("  FAIL: not idempotent")

    if len(SITES) != len(set(SITES)):
        fails += 1
        print("  FAIL: duplicate site")
    for _, v in SITES:
        if v != BASE_VALUE and v not in BLOCK_SYM:
            fails += 1
            print("  FAIL: site value 0x%X has no symbol" % v)
    print("FAILURES: %d" % fails)
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--verify", action="store_true",
                    help="assert every site already carries its symbol")
    ap.add_argument("--checks", action="store_true",
                    help="re-read the ROM evidence behind header section 7")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    if args.checks:
        return checks()
    if args.verify:
        _, pending = run(apply_changes=False)
        print("%d sites, %d still literal" % (len(SITES), pending))
        return 1 if pending else 0
    changed, _ = run(apply_changes=True)
    print("%d sites, %d rewritten" % (len(SITES), changed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
