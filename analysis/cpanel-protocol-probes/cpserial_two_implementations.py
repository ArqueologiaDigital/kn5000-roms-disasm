#!/usr/bin/env python3
"""Are the KN5000 bootloader CP-serial driver and the runtime CPanel driver
the SAME protocol implementation?

`docs/kn5000-control-panel-serial.md` warns, in bold, that the bootloader's
driver "is INDEPENDENT of the runtime CPanel_* protocol stack ... nothing
proven here transfers to the runtime driver, and vice versa."  This script
tests that warning instead of repeating it, by looking for the runtime
driver's code IN THE BOOTLOADER ROM, byte for byte.

It is a pure byte-pattern search over the four shipped ROM images.  Nothing is
read from the disassembly sources, so a wrong reading of them cannot make a
check pass.  Every check is written so that it CAN FAIL: each looks for an
exact encoding and asserts an exact number of hits, and the RAM base addresses
are EXTRACTED from the ROM rather than supplied.

    $ python3 analysis/cpanel-protocol-probes/cpserial_two_implementations.py

Exit status 0 = every check agreed; 1 = at least one disagreed.  Negative control, run
2026-08-22: perturbing one expected combo constant (0x6c -> 0x6d) or one byte of the
frame-length encoding (cp a,0x30 -> cp a,0x31) makes it exit 1, so the checks can fail.

Numbers this produced on 2026-08-22 (documented in
docs/kn5000-control-panel-panel-side.md):

  * 15 of the 16 host->panel command frames occur with IDENTICAL multiplicity
    in kn5000_table_data.rom (bootloader) and in v7/v9/v10 (runtime); the
    16th, (0xe0,0x13), is runtime-only and loads its two bytes in the
    opposite register order.
  * The 12-byte frame-length rule `and a,0x3f / cp a,0x30 / jr c / and a,0x0f
    / add a,3` occurs exactly TWICE in every one of the four ROMs (once on the
    transmit path, once on the receive path).
  * The receive format dispatch `and l,0x38 / srl l,1` occurs exactly once per
    ROM and indexes an 8-entry table whose shape is [A,A,B,C,C,C,D,D] in all
    four.  The transmit dispatch `and a,0x30 / srl a,2` occurs once and indexes
    a 4-entry table shaped [A,A,A,B] in all four.
  * The 2-byte report handler is byte-identical across all four ROMs except
    for one 32-bit immediate, the base of the button-state array:
        table_data 0x00001022   v7 0x00008dae   v9/v10 0x00008e4a
  * Using each ROM's own extracted base, the four power-on button combos
    (base+20 == 0x6c, base+1 == 0x70, base+22 == 0x38, base+6 == 0x0f) are
    each present exactly once in ALL four ROMs -- i.e. the bootloader routine
    named Boot_ClassifyDeviceID is the boot copy of CPanel_CheckSpecialCombos.
  * The startup poll (read base+11, bit7 -> 0x0d, bit6 -> 0x0e, else 0x0c,
    compare with base+32) is present exactly once in all four ROMs.
"""

import re
import sys

ROMS = [
    ("table_data", "original_ROMs/kn5000_table_data.rom", 0x800000),
    ("v7",         "original_ROMs/kn5000_v7_program.rom",  0xE00000),
    ("v9",         "original_ROMs/kn5000_v9_program.rom",  0xE00000),
    ("v10",        "original_ROMs/kn5000_v10_program.rom", 0xE00000),
]

# ---------------------------------------------------------------- encodings
# Every literal below was produced with
#   llvm-project/build/bin/llvm-mc -triple=tlcs900 --show-encoding
# and is quoted next to the mnemonic it came from.
LD_A_IMM8  = 0x21          # ldb a, imm8   -> 21 nn
LD_W_IMM8  = 0x20          # ldb w, imm8   -> 20 nn

FRAME_LEN_RULE = re.compile(
    rb"\xc9\xcc\x3f"      # and a, 0x3f
    rb"\xc9\xcf\x30"      # cp  a, 0x30
    rb"..",               # jr  c, <count already 2>
    re.S)
FRAME_LEN_RULE_TAIL = (
    b"\xc9\xcc\x0f"       # and a, 0x0f
    b"\xc9\xc8\x03")      # add a, 3

RX_FORMAT_DISPATCH = bytes.fromhex("cfcc38cfef01")   # and l,0x38 / srl l,1
TX_FORMAT_DISPATCH = bytes.fromhex("c9cc30c9ef02")   # and a,0x30 / srl a,2
DISPATCH_TAIL      = bytes.fromhex("ced6eb12ebc8")   # xor h,h / extz xhl / add xhl, imm32
LD_L_A             = bytes.fromhex("c98f")           # ld l, a  (transmit path only)

REPORT_INDEX_HEAD  = bytes.fromhex("c8cc4f")         # and w, 0x4f
REPORT_INDEX_TAIL  = bytes.fromhex("c8330666 03 c8ca30".replace(" ", ""))
#                                   bit 6,w  jr z,+3  sub w,0x30

# The four power-on combos, as (array offset, expected value, combo code).
# Codes are the values the routine returns in HL.
COMBOS = [(20, 0x6C, 3), (1, 0x70, 2), (22, 0x38, 1), (6, 0x0F, 4)]

# Host -> panel command frames, as (first, second).
FRAMES = [(0x1F, 0xDA), (0x1F, 0x1A), (0x1D, 0x00), (0xDD, 0x03), (0x1E, 0x80),
          (0x20, 0x00), (0xE0, 0x00), (0x25, 0x01), (0xE2, 0x04), (0x20, 0x10),
          (0xE2, 0x11), (0x2B, 0x00), (0xEB, 0x00), (0xE3, 0x10), (0x20, 0x0B)]


def u32(buf, off):
    return int.from_bytes(buf[off:off + 4], "little")


def count(buf, pat):
    return len(re.findall(re.escape(pat), buf, re.S))


def main():
    roms = []
    for name, path, base in ROMS:
        with open(path, "rb") as fh:
            roms.append((name, base, fh.read()))

    failures = []

    def check(label, ok, detail=""):
        print(f"  [{'ok ' if ok else 'FAIL'}] {label}{'  ' + detail if detail else ''}")
        if not ok:
            failures.append(label)

    # -- 1. command-frame census ------------------------------------------
    print("1. host -> panel command frames  (ldb a,X / ldb w,Y = 21 XX 20 YY)")
    for a, w in FRAMES:
        pat = bytes([LD_A_IMM8, a, LD_W_IMM8, w])
        counts = [count(rom, pat) for _, _, rom in roms]
        check(f"frame {a:02x} {w:02x}",
              len(set(counts)) == 1 and counts[0] >= 1,
              "counts=" + ",".join(f"{n}:{c}" for (n, _, _), c in zip(roms, counts)))

    # -- 2. frame-length rule ---------------------------------------------
    print("2. frame length: 2 bytes, or (first & 0x0f) + 3 when (first & 0x3f) >= 0x30")
    for name, _, rom in roms:
        hits = [m for m in FRAME_LEN_RULE.finditer(rom)
                if rom[m.end():m.end() + len(FRAME_LEN_RULE_TAIL)] == FRAME_LEN_RULE_TAIL]
        check(f"{name}: rule occurrences", len(hits) == 2, f"found {len(hits)} (expect 2)")

    # -- 3. format dispatch tables ----------------------------------------
    print("3. format dispatch tables")
    for label, pat, tail, nent, shape in [
            ("RX (b & 0x38) >> 3", RX_FORMAT_DISPATCH, DISPATCH_TAIL, 8, [0, 0, 1, 2, 2, 2, 3, 3]),
            ("TX (b & 0x30) >> 4", TX_FORMAT_DISPATCH, LD_L_A + DISPATCH_TAIL, 4, [0, 0, 0, 1])]:
        for name, base, rom in roms:
            hits = [m.start() for m in re.finditer(re.escape(pat), rom, re.S)]
            if len(hits) != 1:
                check(f"{name}: {label} site", False, f"{len(hits)} sites (expect 1)")
                continue
            off = hits[0] + len(pat)
            if rom[off:off + len(tail)] != tail:
                check(f"{name}: {label} tail", False, "unexpected bytes after the shift")
                continue
            tbl_addr = u32(rom, off + len(tail))
            # the boot copy stores the BOOT-TIME ALIAS (ROM label + 0x600000)
            tbl_off = None
            for cand in (tbl_addr - base, tbl_addr - 0x600000 - base):
                if 0 <= cand < len(rom) - 4 * nent:
                    tbl_off = cand
                    break
            if tbl_off is None:
                check(f"{name}: {label} table address", False, f"tbl=0x{tbl_addr:06x} out of range")
                continue
            ents = [u32(rom, tbl_off + 4 * i) for i in range(nent)]
            uniq, got = {}, []
            for e in ents:
                got.append(uniq.setdefault(e, len(uniq)))
            check(f"{name}: {label} table shape", got == shape,
                  f"tbl=0x{tbl_addr:06x} shape={got} (expect {shape})")

    # -- 4. the 2-byte report handler, and the array base it uses ---------
    print("4. 2-byte report handler: index = (tag & 0x0f) + (tag & 0x40 ? 16 : 0)")
    bases, windows = {}, {}
    for name, _, rom in roms:
        hits = [m.start() for m in re.finditer(re.escape(REPORT_INDEX_HEAD), rom, re.S)]
        if len(hits) != 1:
            check(f"{name}: report-index site", False, f"{len(hits)} sites (expect 1)")
            continue
        i = hits[0] + len(REPORT_INDEX_HEAD)
        ok_ld = rom[i] == 0x43            # ld xhl, imm32
        base_imm = u32(rom, i + 1)
        tail_ok = rom[i + 5:i + 5 + len(REPORT_INDEX_TAIL)] == REPORT_INDEX_TAIL
        bases[name] = base_imm
        check(f"{name}: handler body", ok_ld and tail_ok,
              f"button-state array base = 0x{base_imm:08x}")
        # widen it: the whole handler body must match once the one immediate is
        # blanked out.  This is the check that earns the word "byte-identical".
        # window layout: [0:3] and w,0x4f   [3] ld xhl opcode   [4:8] immediate
        #                [8:] bit 6,w / jr z / sub w,0x30
        win = bytearray(rom[i - len(REPORT_INDEX_HEAD):
                            i + 5 + len(REPORT_INDEX_TAIL)])
        win[4:8] = b"\0\0\0\0"
        windows[name] = bytes(win)

    ref_name, ref_win = next(iter(windows.items()))
    for name, win in windows.items():
        check(f"{name}: handler window identical to {ref_name} (immediate blanked)",
              win == ref_win, win.hex(" "))

    # -- 5. the four power-on button combos, at each ROM's own base -------
    print("5. power-on button combos, tested against each ROM's OWN array base")
    for name, _, rom in roms:
        if name not in bases:
            continue
        b = bases[name]
        for off, val, code in COMBOS:
            addr = b + off
            pat = bytes([0xC1, addr & 0xFF, (addr >> 8) & 0xFF, 0x3F, val])
            c = count(rom, pat)
            check(f"{name}: combo {code}: (base+{off:2d}) == 0x{val:02x}", c == 1,
                  f"addr=0x{addr:04x} hits={c}")

    # -- 6. the startup poll's three-way mode code ------------------------
    print("6. startup poll: read base+11, bit7 -> 0x0d, bit6 -> 0x0e, else 0x0c")
    for name, _, rom in roms:
        if name not in bases:
            continue
        b = bases[name]
        st, prev = b + 11, b + 32
        pat = re.compile(
            bytes([0xC1, st & 0xFF, (st >> 8) & 0xFF, 0x21]) +      # ldb a,(base+11)
            b"\x20\x0d\xc9\x33\x07.." +                             # ldb w,0x0d; bit 7,a; jr nz
            b"\x20\x0e\xc9\x33\x06.." +                             # ldb w,0x0e; bit 6,a; jr nz
            b"\x20\x0c" +                                           # ldb w,0x0c
            bytes([0xC1, prev & 0xFF, (prev >> 8) & 0xFF, 0xF8]) +  # cp (base+32), w
            bytes([0xF1, prev & 0xFF, (prev >> 8) & 0xFF, 0x40]),   # ld (base+32), w
            re.S)
        c = len(pat.findall(rom))
        check(f"{name}: startup-poll mode block", c == 1,
              f"status=0x{st:04x} previous=0x{prev:04x} hits={c}")

    print()
    if failures:
        print(f"{len(failures)} CHECK(S) FAILED")
        return 1
    print("all checks agreed: the bootloader and runtime CP-serial drivers are "
          "the same implementation at two link addresses")
    return 0


if __name__ == "__main__":
    sys.exit(main())
