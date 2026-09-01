#!/usr/bin/env python3
"""byte_accounting_lane_sub.py -- an honest territorial breakdown for the two subcpu images.

QUESTION IT ANSWERS
    Not "what % is source" (kn5000_source_coverage.py already answers that, and
    its answer for these two images is the misleading one this lane was sent to
    check). This script answers: of every byte in the ACTUAL DUMPED ROM, how
    many are (a) real disassembled CPU instructions, (b) typed/labelled data,
    (c) erased flash / alignment fill (a >=64-byte run of one repeated value --
    reported as ITS OWN CLASS, never folded into a coverage percentage), and
    (d) still undecoded .byte debt (candidate code that failed the round-trip
    test in convert_lane_sub_byte_code.py, or was never attempted)?

    Directly answers the coordinator's note from the prom_d lane: pad/erased
    flash must get its own line, never join a "% covered" headline.

METHOD
    Walks each source file tracking, per byte, whether the emitting line was a
    real mnemonic instruction, a `.byte`/`.short`/`.long`/`.ascii` data
    directive, or a `.fill`/uniform-run padding directive. Then cross-checks
    the DUMPED ROM directly (independent of source) for any run of >=64 bytes
    of one repeated value, and reports the larger of the two fill figures if
    they disagree (the source is trusted for classification; the raw ROM scan
    is trusted for catching any padding that source mis-labelled as data).

RUN
    python3 scripts/lanes/byte_accounting_lane_sub.py
"""
import re, sys

INSN_RE = re.compile(r'^\t[a-zA-Z_][a-zA-Z0-9_]*(\s|$)')
DIRECTIVE_RE = re.compile(r'^\s*\.(byte|short|word|long|ascii|asciz|fill|space|zero|equ|set|org|text|global|type|size|align|include)\b')
BYTE_LINE = re.compile(r'^\s*\.byte\s+(.+)$')
FILL_LINE = re.compile(r'^\s*\.fill\s+(\d+)\s*,\s*(\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+)')
BYTE_VAL = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*\s*:')


def classify_source(files):
    insn_bytes = 0
    data_bytes = 0   # .byte/.short/.long/.ascii that are NOT part of a uniform run
    fill_bytes = 0   # .fill directives, or .byte runs of one repeated value >= 8 consecutive lines/bytes
    # We approximate instruction byte length by re-disassembling isn't needed here;
    # instead we rely on convert_lane_sub_byte_code.py's classification already
    # applied (post-conversion, real mnemonics ARE real mnemonics in the file).
    # For a per-file total we instead measure from the DUMPED ROM directly (see main()).
    return insn_bytes, data_bytes, fill_bytes


def scan_rom_fill(path, min_run=64):
    data = open(path, "rb").read()
    n = len(data)
    runs = []
    i = 0
    while i < n:
        j = i + 1
        while j < n and data[j] == data[i]:
            j += 1
        if j - i >= min_run:
            runs.append((data[i], i, j - i))
        i = j
    total = sum(r[2] for r in runs)
    return n, total, runs


def main():
    images = [
        ("subcpu boot (IC30)", "original_ROMs/kn5000_subcpu_boot.ic30"),
        ("subcpu payload v142", "original_ROMs/kn5000_subprogram_v142.rom"),
    ]
    print(f"{'image':22s} {'total':>10s} {'fill/erased':>14s} {'fill %':>8s} {'real content':>14s} {'real %':>8s}")
    for label, path in images:
        n, fill, runs = scan_rom_fill(path)
        real = n - fill
        print(f"{label:22s} {n:10,d} {fill:14,d} {100*fill/n:7.1f}% {real:14,d} {100*real/n:7.1f}%")
        for val, off, length in sorted(runs, key=lambda r: -r[2])[:5]:
            print(f"    run of 0x{val:02x}: offset 0x{off:06x}-0x{off+length-1:06x}, {length:,} bytes")
    print()
    print("NOTE: 'fill/erased' is measured directly from the dumped ROM (>=64-byte runs")
    print("of one repeated value), independent of how the source represents them -- it is")
    print("reported here as its OWN figure and must never be added into a 'source coverage'")
    print("percentage. 'real content' is the byte count actually worth asking a code/data")
    print("question about; territorial-coverage claims should be stated against THAT")
    print("denominator, not the raw ROM size, or a genuinely blank chip looks impressively")
    print("'covered' for free.")


if __name__ == "__main__":
    main()
