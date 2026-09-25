#!/usr/bin/env python3
r"""The two u16 fields of InitializeSuna's class records, spelled as data instead of instructions.

QUESTION ANSWERED
    InitializeSuna registers 41 class records at 0xE16C86 (`RegObjTable
    0x1600004, ClassProc, 0xe17322, 0xe16c86, 0x164`; count word 41 at
    0xE17322), 24 bytes each: +0 routine, +4 naka_header, +8 u16, +10 u16,
    +12 name string, +16 instance-code string, +20 property descriptor
    (StrDesc_*).  In ui_widgets/naka_property_descriptors.s the two u16 of the
    records with a `naka_header NAKA_TYPE_0x12` line are decoded as
    instructions -- `ld d, 0:opc / nop / nop` (24 00 00 00) and
    `ld h, 0:opc / push sr / nop` (26 00 02 00) -- in v10, v9 and v7.
    This rewrites them as `.short 36, 0` / `.short 38, 2`, reading the values
    from each ROM; --check lists them.  The record grid (every header at
    0xE16C86 + 24k + 4) is asserted.

RUN
    python3 scripts/converters/retype_suna_class_fields.py --check
    python3 scripts/converters/retype_suna_class_fields.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import file_line_addresses as fla  # noqa: E402

B = 0xE00000
LO, N, SZ = 0xE16C86, 41, 24
REL = "ui_widgets/naka_property_descriptors.s"


def run(v, apply_it):
    d = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
    assert struct.unpack_from("<H", d, 0xE17322 - B)[0] == N
    lm = fla.build(v, REL)
    addr = {e["line"]: e["addr"] for e in lm}
    path = os.path.join(ROOT, v, "maincpu", REL)
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    edits = []
    for i, l in enumerate(lines, 1):
        if l.strip() != "naka_header NAKA_TYPE_0x12" or i not in addr:
            continue
        a = addr[i]
        if not LO <= a < LO + N * SZ:
            continue
        assert (a - 4 - LO) % SZ == 0, hex(a)
        j = i                      # 0-based index of the line after the header
        while not lines[j].startswith("\t.long"):
            assert ";" not in lines[j], lines[j]
            j += 1
        f4, f6 = struct.unpack_from("<HH", d, a + 4 - B)
        edits.append((i, j, "\t.short %d, %d" % (f4, f6), lines[i:j]))
    print("%s: %d records" % (v, len(edits)))
    for i, j, new, old in edits[:3]:
        print("   %s  <-  %s" % (new.strip(), " / ".join(x.strip() for x in old)))
    if apply_it:
        for i, j, new, old in sorted(edits, reverse=True):
            lines[i:j] = [new]
        open(path, "wb").write("\n".join(lines).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    for v in (a.apply or ["v10", "v9", "v7"]):
        run(v, bool(a.apply))
    return 0


if __name__ == "__main__":
    sys.exit(main())
