#!/usr/bin/env python3
"""convert_v7_data_slices.py -- rewrite verified-homogeneous v7 `.incbin` DATA
romslices as inline `.byte` lines.

WHAT THIS CONVERTS, AND WHY ONLY THIS SUBSET
---------------------------------------------
`v7_slice_v9v10_correspondence.py` classifies 272 live v7 romslices by the
directive/instruction that opens the same-named label in v9/v10.
`v7_slice_data_run_extent.py` then measures, for every DATA-kind verdict
(byte/long/ascii/asciz/zero), how many bytes of THAT SAME DIRECTIVE actually
run before v9/v10 falls into something else (usually real code) -- because a
kind of "byte" only means the label's FIRST line is `.byte`; many such
labels are short data headers glued onto a following ROUTINE (documented
examples: `AccPatch_AdvPlayPos_DataBlock`, `.zero 8` then 135 B of real code;
`FileIO_BytecodeData`, 3 B of `.byte` then 3,080 B of code). Converting the
whole v7 slice on the strength of the label alone would silently launder
code into `.byte`, exactly the "code-as-.byte" debt class this project has
already shipped by mistake twice.

This script only touches the SAFE subset: `kind == 'byte'` AND
`run_length >= size`, i.e. the v9/v10 span is `.byte` for at least as long as
the v7 slice itself runs, so there is no code hiding past its end. `long`-kind
candidates are deliberately excluded even when their run covers the slice --
a `.long` at these labels is a pointer/dispatch entry in v9/v10 (confirmed by
sampling: `Naka_MainDispatch_Table` reads `.long VoiceCtrlR1_Entry_047`), and
`convert_v7_ptr_tables.py` -- the tool that resolves those against the v7
ELF's own symbol table, tried Tier A (exact v7 symbol) and Tier B (v10
corroboration) against the FULL current romslice set and returned 0 proven
tables. Emitting `.long 0xRAWHEX` here without that resolution would be a
downgrade from what the specialized tool already tried and could not certify,
not a new fact -- so those stay `.incbin`, unconverted, and are reported as
such by --list.

VERIFICATION
------------
Before writing anything, every candidate's proposed `.byte` text is
assembled with the pinned llvm-mc and the resulting bytes are compared,
byte for byte, against the ORIGINAL `.incbin`'d file. Only exact matches are
written. (For a plain `.byte` list this is really just re-deriving the same
bytes, but it also catches a malformed hex render or an off-by-one slice
read before it ever reaches the tree.)

Emission format matches `convert_v7_ptr_tables.py`'s residue() helper: 8
values per `.byte` line, `0x%02x`, tab-indented. The old `.bin` file is left
on disk unreferenced (same convention that script uses for a
fully-converted blob) rather than deleted, so a sibling lane mid-edit on the
same directory is never surprised by a missing file.

RUN
    python3 scripts/converters/convert_v7_data_slices.py            # dry run, prints the plan
    python3 scripts/converters/convert_v7_data_slices.py --apply    # writes, only for entries that verified
    python3 scripts/converters/convert_v7_data_slices.py --list     # one line per candidate + verdict

Reads scripts/analysis/v7_slice_data_run_extent.json (run
v7_slice_v9v10_correspondence.py then v7_slice_data_run_extent.py first).
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)
LLVM_MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
LLVM_OBJCOPY = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-objcopy')


def byte_lines(data):
    lines = []
    for off in range(0, len(data), 8):
        chunk = data[off:off + 8]
        lines.append('\t.byte ' + ', '.join(f'0x{b:02x}' for b in chunk))
    return lines


def verify(lines, expect):
    """Assemble `lines` with the pinned llvm-mc and require the exact bytes
    of `expect` back. Returns True/False."""
    text = '\n'.join(lines) + '\n'
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=30)
    if p.returncode != 0:
        return False
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    try:
        p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath],
                             capture_output=True, timeout=30)
        if p2.returncode != 0:
            return False
        with open(binpath, 'rb') as f:
            got = f.read()
        return got == expect
    finally:
        for p_ in (objpath, binpath):
            if os.path.exists(p_):
                os.remove(p_)


def candidates():
    rows = json.load(open('scripts/analysis/v7_slice_data_run_extent.json'))
    return [r for r in rows if r['kind'] == 'byte' and r['run_length'] >= r['size']]


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--apply', action='store_true', help='rewrite the sources (default: dry run)')
    ap.add_argument('--list', action='store_true', help='one line per candidate + verdict')
    args = ap.parse_args()

    rows = candidates()
    per_file = {}
    total_ok = total_size = 0
    reports = []
    for r in rows:
        binpath = r['bin']
        if not os.path.exists(binpath):
            reports.append((r, 'MISSING BIN', False))
            continue
        with open(binpath, 'rb') as f:
            data = f.read()
        if len(data) != r['size']:
            reports.append((r, f'SIZE MISMATCH bin={len(data)} json={r["size"]}', False))
            continue
        lines = byte_lines(data)
        ok = verify(lines, data)
        reports.append((r, 'OK' if ok else 'ROUNDTRIP FAILED', ok))
        if ok:
            total_ok += 1
            total_size += len(data)
            per_file.setdefault(r['file'], []).append((r, lines))

    if args.list or not args.apply:
        for r, status, ok in sorted(reports, key=lambda x: -x[0]['size']):
            print(f"  {r['size']:6,d}  {r['label']:40s} {r['file']:50s} {status}")
        print(f"\n{total_ok}/{len(rows)} candidates verified, {total_size:,} B "
              f"would leave .incbin for inline .byte")

    if not args.apply:
        print("\n(dry run -- pass --apply to write)")
        return 0

    for fname, entries in per_file.items():
        lines = open(fname, encoding='latin-1').readlines()
        # apply bottom-to-top so earlier line indices stay valid
        for r, newlines in sorted(entries, key=lambda e: -e[0]['incbin_line']):
            i = r['incbin_line']
            assert '.incbin' in lines[i] and 'romslices/' in lines[i], \
                f"{fname}:{i+1} does not look like the expected .incbin line: {lines[i]!r}"
            lines[i] = '\n'.join(newlines) + '\n'
        open(fname, 'w', encoding='latin-1').writelines(lines)
        print(f"rewrote {fname}")

    print(f"\n{total_ok} slices, {total_size:,} B converted from .incbin to inline .byte.")
    print("now: make rebuilt_ROMs/kn5000_v7_program.llvm.rom && cmp against original_ROMs/kn5000_v7_program.rom")
    return 0


if __name__ == '__main__':
    sys.exit(main())
