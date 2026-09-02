#!/usr/bin/env python3
"""v7_slice_data_run_extent.py -- how much of a v9/v10 DATA-kind label is
ACTUALLY that data type, versus code that starts a few bytes later?

WHY THIS EXISTS
----------------
`v7_slice_v9v10_correspondence.py` classifies a v7 romslice by looking at the
FIRST directive/instruction after the same-named label in v9/v10 -- its own
docstring says this names a CANDIDATE, not a verdict. That warning turns out
to matter in the opposite direction from the one already documented (a CODE
verdict that is really a string): a `byte`/`long`/`ascii`/`zero`/`asciz`
verdict can ALSO be wrong, when the v9/v10 label opens with a short data run
and then falls straight into real code.

Two examples found manually while triaging the v7 romslice worklist
(2026-09-02):

  * `AccPatch_AdvPlayPos_DataBlock` (v7 slice: 143 B, classified `zero`):
    v9 has `.zero 8` then `nop / nop / nop / .byte 0x9d / ldw de,0 / ...` --
    real code (itself carrying its own small misframed islands) for the
    other 135 B. Blind-inlining the v7 slice as `.zero 143` would silently
    claim 135 B of code is zero fill.
  * `CmpSetTtl_Dispatch2` (v7 slice: 94 B, classified `asciz`): v9 opens
    `.asciz ":;<> "` (6 B) then `call ... / .ascii "..." / .byte ... / popw
    ix / jr lt, ...` for the other 88 B -- another short-run-then-code shape.

Inlining either as a single data directive would be exactly the "code as
`.byte`" trap DEBT-INVENTORY warns about, just with the wrong directive name
attached, AND it would not even be visible to `v7_no_source_bytes.py` (which
only counts live `.incbin`) -- it would look like progress while adding
opaque, unverified content to the tree.

WHAT THIS SCRIPT DOES
----------------------
For every DATA-kind slice (`byte`, `long`, `ascii`, `asciz`, `zero`) from
`v7_slice_v9v10_correspondence.json`, measures the RUN LENGTH in bytes of
directives of THAT SAME KIND, starting at the label, in whichever of v9/v10
supplied the classification -- stopping at the first line that is not a
blank, a comment, or a directive of the same kind. Reports the ratio of that
run length to the v7 slice's own size.

A slice is a SAFE CANDIDATE only when the run length covers the ENTIRE v7
slice size (run >= size) -- meaning the analogous span in v9/v10 is
homogeneously that data type for at least as long as the v7 slice runs, not
just at its start. Everything else stays opaque; blind conversion is not
attempted here, only measured and reported.

RUN
    python3 scripts/analysis/v7_slice_data_run_extent.py
    reads scripts/analysis/v7_slice_v9v10_correspondence.json (run that first)
    writes scripts/analysis/v7_slice_data_run_extent.json
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

LABEL_DEF = re.compile(r'^([A-Za-z_.][\w.]*):\s*(.*)$')
BYTE_DIR = re.compile(r'^\.byte\s+(.*)$')
LONG_DIR = re.compile(r'^\.long\s+(.*)$')
ZERO_DIR = re.compile(r'^\.zero\s+(\d+)\s*$')
ASCII_DIR = re.compile(r'^\.ascii\s+"(.*)"\s*$')
ASCIZ_DIR = re.compile(r'^\.asciz\s+"(.*)"\s*$')

DATA_KINDS = ('byte', 'long', 'ascii', 'asciz', 'zero')


def unescape_len(s):
    """Byte length of a `.ascii`/`.asciz` string literal body, honouring the
    handful of escapes llvm-mc accepts (\\\\, \\", \\n, \\t, \\r, \\0,
    \\xHH). Anything else counts as one byte per source character, which is
    what this assembler's own lexer does too."""
    n, i = 0, 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == 'x':
                i += 4  # \xHH
            else:
                i += 2  # \\, \", \n, \t, \r, \0, ...
        else:
            i += 1
        n += 1
    return n


def count_values(s):
    """Number of comma-separated operands in a `.byte`/`.long` operand list."""
    s = s.split(';')[0].strip()
    if not s:
        return 0
    return len([p for p in s.split(',') if p.strip()])


def run_length(lines, i, kind):
    """Bytes covered by a maximal run of `kind`-directive lines starting at
    label line i (line i itself may carry the directive on its tail).
    Blank lines and full-line comments may interleave without ending the
    run; anything else -- a different directive, an instruction, a bare
    label -- ends it."""
    tail = LABEL_DEF.match(lines[i].strip()).group(2).strip()
    candidates = [tail] + [lines[j].strip() for j in range(i + 1, len(lines))]
    total = 0
    unit = 4 if kind == 'long' else 1
    dirmatch = {'byte': BYTE_DIR, 'long': LONG_DIR}.get(kind)
    for s in candidates:
        if not s or s.startswith(';'):
            continue
        if kind in ('byte', 'long'):
            m = dirmatch.match(s)
            if not m:
                break
            total += unit * count_values(m.group(1))
            continue
        if kind == 'zero':
            m = ZERO_DIR.match(s)
            if not m:
                break
            total += int(m.group(1))
            continue
        if kind == 'ascii':
            m = ASCII_DIR.match(s)
            if not m:
                break
            total += unescape_len(m.group(1))
            continue
        if kind == 'asciz':
            m = ASCIZ_DIR.match(s)
            if not m:
                break
            total += unescape_len(m.group(1)) + 1
            continue
        break
    return total


def build_label_index(root):
    idx = {}
    for f in glob.glob(f'{root}/**/*.s', recursive=True):
        lines = open(f, encoding='latin-1').readlines()
        for i, line in enumerate(lines):
            m = LABEL_DEF.match(line.strip())
            if m and m.group(1) not in idx:
                idx[m.group(1)] = (f, i, lines)
    return idx


def main():
    corr = json.load(open('scripts/analysis/v7_slice_v9v10_correspondence.json'))
    idx9 = build_label_index('v9/maincpu')
    idx10 = build_label_index('v10/maincpu')

    results = []
    for r in corr:
        if r['kind'] not in DATA_KINDS:
            continue
        label = r['label']
        best = None
        for idx in (idx9, idx10):
            if label in idx:
                f, i, lines = idx[label]
                rl = run_length(lines, i, r['kind'])
                if best is None or rl > best:
                    best = rl
        results.append({**r, 'run_length': best if best is not None else 0,
                         'safe': best is not None and best >= r['size']})

    out = 'scripts/analysis/v7_slice_data_run_extent.json'
    json.dump(results, open(out, 'w'), indent=1)

    safe = [r for r in results if r['safe']]
    unsafe = [r for r in results if not r['safe']]
    print(f"{len(results)} DATA-kind slices, {sum(r['size'] for r in results):,} B total\n")
    print(f"SAFE (v9/v10 run covers the whole v7 slice): {len(safe)} files, "
          f"{sum(r['size'] for r in safe):,} B")
    for r in sorted(safe, key=lambda r: -r['size']):
        print(f"    {r['size']:6,d}  {r['label']:40s} kind={r['kind']:6s} run={r['run_length']:,}")
    print(f"\nUNSAFE (run shorter than the slice -- real code starts partway "
          f"through): {len(unsafe)} files, {sum(r['size'] for r in unsafe):,} B")
    for r in sorted(unsafe, key=lambda r: -r['size'])[:20]:
        print(f"    {r['size']:6,d}  {r['label']:40s} kind={r['kind']:6s} run={r['run_length']:,}")
    if len(unsafe) > 20:
        print(f"    ... and {len(unsafe) - 20} more")
    print(f"\nwrote {out}")


if __name__ == '__main__':
    sys.exit(main())
