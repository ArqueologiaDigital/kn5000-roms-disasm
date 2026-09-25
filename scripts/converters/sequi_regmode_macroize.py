#!/usr/bin/env python3
r"""sequi_regmode_macroize.py -- re-express a `.byte` run of RegisterMode /
RegisterTitle call records as the RegMode / RegTitle macro calls v10 uses.

QUESTION THIS ANSWERS
---------------------
v7 `InitializeKubo` (sequencer/sequencer_ui.s) ends in 1,280 bytes of `.byte`
that the census reports as a research target ("embedded-in-code").  v10's
copy of the same routine spells those bytes as 7 `RegMode` + 33 `RegTitle`
macro calls (macros defined in display/scoop_display.s).  Are the v7 bytes the
same record shape, and can they be written the same way?

HOW
---
Reads the ORIGINAL ROM from --addr and parses consecutive records of the shape
the macros emit:

    0b lo hi   pushw ParamA
    0b lo hi   pushw ParamBhi
    0b lo hi   pushw ParamBlow
    e8 a8+n | 40 imm32        ld xwa, ParamC   (compact form iff value <= 7)
    e9 a8+n | 41 imm32        ld xbc, ParamD
    ea a8+n | 42 imm32        ld xde, ParamE
    1d imm24                  call RegisterMode | RegisterTitle

refusing (exit 1) if a record uses the long form for a value <= 7 (the macro
could not reproduce it) or calls anything other than the two routines whose
addresses are given.  The run must end with the routine's epilogue
`bf 0e 37 0e` (lda xsp,(xsp+14); ret) exactly at --end.

It then checks that the source lines being replaced (--first-line up to the
line holding --end-label) emit exactly (end - addr) bytes -- counting `pushw`
as 3 and every `.byte` item as 1 and refusing on any other emitting line --
and rewrites them.  Latin-1 read/write, bytes untouched elsewhere.

RUN (dry by default)
    python3 scripts/converters/sequi_regmode_macroize.py \
        --image v7 --file sequencer/sequencer_ui.s --first-line 5910 \
        --addr 0xF2DF39 --end 0xF2E442 --end-label AutoPunchTtlRqFunc \
        --register-mode 0xFA491E --register-title 0xFA4973 [--apply]

The byte gate (`make gate`) is the certification; this script only refuses
early.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def parse_records(rom, base, addr, end, reg_mode, reg_title):
    p = addr - base
    stop = end - base
    out = []
    while p < stop:
        if rom[p:p + 4] == bytes([0xbf, 0x0e, 0x37, 0x0e]) and p + 4 == stop:
            out.append(("\tlda xsp, (xsp + 14)", None))
            out.append(("\tret", None))
            return out
        vals = []
        for _ in range(3):
            if rom[p] != 0x0b:
                sys.exit("not a pushw at 0x%06X: %02x" % (base + p, rom[p]))
            vals.append(int.from_bytes(rom[p + 1:p + 3], "little"))
            p += 3
        for short, long_ in ((0xe8, 0x40), (0xe9, 0x41), (0xea, 0x42)):
            if rom[p] == short and 0xa8 <= rom[p + 1] <= 0xaf:
                vals.append(rom[p + 1] - 0xa8)
                p += 2
            elif rom[p] == long_:
                v = int.from_bytes(rom[p + 1:p + 5], "little")
                if v <= 7:
                    sys.exit("long form for %d at 0x%06X: macro cannot reproduce"
                             % (v, base + p))
                vals.append(v)
                p += 5
            else:
                sys.exit("unexpected ld at 0x%06X: %02x" % (base + p, rom[p]))
        if rom[p] != 0x1d:
            sys.exit("not a call at 0x%06X" % (base + p))
        tgt = int.from_bytes(rom[p + 1:p + 4], "little")
        p += 4
        if tgt == reg_mode:
            mac = "RegMode"
        elif tgt == reg_title:
            mac = "RegTitle"
        else:
            sys.exit("call to 0x%06X at 0x%06X is neither routine" % (tgt, base + p - 4))
        out.append(("\t%s %s" % (mac, ", ".join("0x%x" % v for v in vals)), mac))
    sys.exit("run did not end with the lda xsp,(xsp+14); ret epilogue at --end")


def emitted(line):
    t = line.split(";")[0].strip()
    if not t or t.endswith(":"):
        return 0
    if t.startswith(".byte"):
        return len([x for x in t[5:].split(",") if x.strip()])
    if re.match(r"pushw\s+0x[0-9a-fA-F]+$", t):
        return 3
    sys.exit("unexpected emitting line in replaced span: %r" % line)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--first-line", type=int, required=True)
    ap.add_argument("--addr", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--end", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--end-label", required=True)
    ap.add_argument("--register-mode", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--register-title", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    rom = open(os.path.join(ROOT, "original_ROMs",
                            "kn5000_%s_program.rom" % a.image), "rb").read()
    recs = parse_records(rom, 0xE00000, a.addr, a.end,
                         a.register_mode, a.register_title)
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    lines = open(path, encoding="latin-1").read().split("\n")
    i0 = a.first_line - 1
    i1 = next(i for i in range(i0, len(lines))
              if lines[i].strip() == a.end_label + ":")
    n = sum(emitted(l) for l in lines[i0:i1])
    if n != a.end - a.addr:
        sys.exit("replaced span emits %d bytes, ROM span is %d" % (n, a.end - a.addr))
    new = []
    prev = None
    for text, mac in recs:
        if prev is not None and mac != prev:
            new.append("")
        new.append(text)
        prev = mac
    new.append("")
    counts = {m: sum(1 for _, x in recs if x == m) for m in ("RegMode", "RegTitle")}
    print("%s:%d-%d  %d bytes -> %s" % (a.file, a.first_line, i1, n, counts))
    if a.apply:
        lines[i0:i1] = new
        open(path, "w", encoding="latin-1").write("\n".join(lines))
        print("applied")
    else:
        print("\n".join(new[:6]) + "\n\t...")


if __name__ == "__main__":
    main()
