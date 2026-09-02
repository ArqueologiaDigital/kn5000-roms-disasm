#!/usr/bin/env python3
"""sri_rr_subopcode_rom_census.py -- how often does each SriRRReg sub-opcode
nibble (0x30 LDA / 0x40 STB / 0x50 STW / 0x60 STL) actually occur in the real
ROM images, at sites shaped like the R+R addressing mode
`[F3, 0x07, base_addr, idx_addr, SubOpc+reg]`?

WHY: TLCS900MCCodeEmitter.cpp's `Opcode < 0xF0` guard means the SriRRReg
family (ST_RRB/W/L, LDA_RR, prefix 0xF3) can only carry size information in
its sub-opcode BYTE, not its prefix byte. llvm-project@1b9432474daa fixed
ST_RRW/ST_RRL to use distinct sub-opcodes (0x50/0x60) instead of colliding
with ST_RRB's 0x40, citing direct ROM evidence for the LDA/STB pair only
(`f3 07 e4 e0 31` = lda XBC,XBC+WA in the KN5000 v7 ROM) and inferring
STW=0x50/STL=0x60 by analogy with the neighbouring DRI3/DPI/DPD families,
which already carry that convention.

This script is not proof that any INDIVIDUAL 0x50 or 0x60 hit is really a
`st_rrw`/`st_rrl` -- nobody has written a SriRRReg decoder yet (see
DEBT-INVENTORY item 5), and this pattern match has no way to rule out data
that merely looks like the shape. What it DOES show: all four sub-opcode
nibbles appear at plausible, monotonically-decreasing frequencies (LDA most
common, STL rarest) consistent with real code -- not "0x50/0x60 never occur"
(which would falsify the analogy) and not noise-flat frequencies (which
would suggest false-positive pattern matches dominate).

RUN
    python3 notes/llvmencaudit-audit/sri_rr_subopcode_rom_census.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

IMAGES = {
    "v10": "original_ROMs/kn5000_v10_program.rom",
    "wsa1_prom_a": "wsa1/original_ROMs/wsa1_prom_a.ic12",
    "wsa1_prom_b": "wsa1/original_ROMs/wsa1_prom_b.ic13",
    "wsa1_prom_c": "wsa1/original_ROMs/wsa1_prom_c.ic28",
    "wsa1_prom_d": "wsa1/original_ROMs/wsa1_prom_d.bin",
}

LABELS = {0x00: "LD_imm", 0x30: "LDA", 0x40: "STB", 0x50: "STW", 0x60: "STL"}


def census(path: str) -> dict:
    data = open(path, "rb").read()
    hits = {}
    for i in range(len(data) - 5):
        if data[i] == 0xF3 and data[i + 1] == 0x07:
            base, idx, sub = data[i + 2], data[i + 3], data[i + 4]
            # base/idx addr bytes: register-file addresses are 0xE0 + n*4.
            if (base & 0x03) == 0 and 0xE0 <= base <= 0xFC and \
               (idx & 0x03) == 0 and 0xE0 <= idx <= 0xFC:
                hits.setdefault(sub & 0xF0, 0)
                hits[sub & 0xF0] += 1
    return hits


def main() -> int:
    print(f"{'image':14s} " + " ".join(f"{LABELS.get(k, hex(k)):>8s}" for k in (0x30, 0x40, 0x50, 0x60)))
    for name, rel in IMAGES.items():
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            print(f"{name:14s} (missing: {path})")
            continue
        hits = census(path)
        row = " ".join(f"{hits.get(k, 0):8d}" for k in (0x30, 0x40, 0x50, 0x60))
        print(f"{name:14s} {row}")

    print()
    print("Expectation under the LDA(0x30)/STB(0x40)/STW(0x50)/STL(0x60)")
    print("convention: monotonically decreasing counts left to right (address")
    print("computation is commonest, 32-bit-register stores rarest). This is a")
    print("corroborating signal, not proof -- see module docstring.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
