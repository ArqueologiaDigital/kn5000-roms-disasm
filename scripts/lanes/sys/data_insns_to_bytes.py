#!/usr/bin/env python3
r"""Re-type instruction lines inside a DATA-ONLY file as the bytes they are.

QUESTION THIS ANSWERS
    factory_test/fd_test_data.s is data: Naka widget records (naka_header),
    pointer tables and the FD test's message strings.  In places the source
    spells those bytes as instructions -- "File remove =>" as `ldw (70:8),
    27753:io / jr mi, 32 / jrl le, 28005 / ...`, record fields as `swi 7 /
    pushw 65280 / nop`.  Which lines are these, and what are their bytes?

HOW
    Every instruction line of the file (anything that is not a directive, a
    known data macro or a label/comment) is replaced by its own ROM bytes
    (address map, scripts/analysis/address_line_map.py via port_islands.amap):
    printable runs of 4+ as `.ascii`, the rest `.byte`.  Labels and comments
    on those lines are kept.  Refuses if any label in the file is a branch or
    call target in the ROM (then it might be code) -- checked by searching the
    ROM for call/jp to, and calr/jr/jrl landing on, each label's address.
    --apply rebuilds and compares with the dump; a mismatch restores the file.

RUN
    python3 scripts/lanes/sys/data_insns_to_bytes.py --image v10 --file factory_test/fd_test_data.s [--apply]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402
import ff_screendata_render as fr  # noqa: E402

BASE = pi.BASE
DATA_MACROS = ("naka_header", "aligned_string", "addr24")


def texty(rom, i):
    w = rom[max(0, i - 4):i + 8]
    return sum(1 for x in w if 0x20 <= x < 0x7f or x in (0, 0xff)) >= 0.75 * len(w)


def branch_targets(rom, addrs):
    """branch/call sources that are not themselves inside text (a `jrl`
    opcode byte 0x70-0x7F is also 'p'..'\x7f' in ASCII)"""
    hit = set()
    aset = set(addrs)
    for i in range(len(rom) - 4):
        if texty(rom, i):
            continue
        o = rom[i]
        if o in (0x1d, 0x1b) and (rom[i + 1] | rom[i + 2] << 8 | rom[i + 3] << 16) in aset:
            hit.add(rom[i + 1] | rom[i + 2] << 8 | rom[i + 3] << 16)
        if o in (0x1e, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c,
                 0x7d, 0x7e, 0x7f):
            t = BASE + i + 3 + int.from_bytes(rom[i + 1:i + 3], "little", signed=True)
            if t in aset:
                hit.add(t)
    return hit


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    order, syms = pi.amap(a.image)
    rom = pi.rom(a.image)
    rows = [e for e in order if e[1] == a.file]
    labels = [(e[0], lab) for e in rows if e[0] is not None for lab in pi.split_line(e[3])[0]]
    tg = branch_targets(rom, [x for x, l in labels])
    if tg:
        print("REFUSED: labels that are branch/call targets:", [l for x, l in labels if x in tg])
        return 1
    # runs of consecutive instruction lines (no label/comment between) are
    # rendered together, so a string split over several "instructions" comes
    # back as one `.ascii`
    runs, cur = [], None
    for e in rows:
        labs, body, com = pi.split_line(e[3])
        isins = bool(body) and e[0] is not None and e[4] > 0 and not body.startswith(".") \
            and body.split()[0] not in DATA_MACROS
        if isins and not labs and not com.strip() and cur and cur[-1][0] + cur[-1][4] == e[0] \
                and cur[-1][2] + 1 == e[2]:
            cur.append(e)
            continue
        if cur:
            runs.append(cur)
            cur = None
        if isins:
            cur = [e]
    if cur:
        runs.append(cur)
    edits = {}
    n = nb = 0
    for run in runs:
        e0 = run[0]
        labs, body, com = pi.split_line(e0[3])
        a0, a1 = e0[0], run[-1][0] + run[-1][4]
        new = ["%s:" % l for l in labs]
        lines = fr.seg_lines(fr.render_bytes(rom[a0 - BASE:a1 - BASE]))
        c = com.strip()
        new.append(lines[0] + (("\t" + c) if c else ""))
        new.extend(lines[1:])
        edits[(e0[2], run[-1][2])] = new
        n += len(run)
        nb += a1 - a0
    print("%s %s: %d instruction lines (%d B) -> data" % (a.image, a.file, n, nb))
    if not a.apply:
        for ln, new in list(edits.items())[:20]:
            print("  %s: %s" % (ln, " | ".join(new)))
        return 0
    p = os.path.join(pi.ROOT, a.image, "maincpu", a.file)
    raw = open(p, "rb").read()
    L = raw.decode("latin-1").split("\n")
    for (l0, l1) in sorted(edits, reverse=True):
        L[l0 - 1:l1] = edits[(l0, l1)]
    open(p, "wb").write("\n".join(L).encode("latin-1"))
    built, err = pi.fast_build(a.image, os.path.join(pi.SCRATCH, "build"))
    if built == rom:
        print("%s IDENTICAL" % a.image)
        return 0
    print("MISMATCH/FAIL; restoring", err[-1500:] if built is None else "")
    open(p, "wb").write(raw)
    return 1


if __name__ == "__main__":
    sys.exit(main())
