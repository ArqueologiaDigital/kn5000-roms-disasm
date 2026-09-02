#!/usr/bin/env python3
"""convert_v7_code_slices.py -- rewrite hand-vetted v7 CODE romslices as
real instructions, from v7_slice_code_roundtrip.json's MATCH verdicts.

`v7_slice_code_roundtrip.py` finds every CODE-labelled romslice (per
v9/v10 cross-version correspondence) that survives a disassemble/reassemble
round trip with the pinned llvm-mc. A clean round trip is necessary but NOT
sufficient -- see that script's docstring for two matches it already threw
out by hand: `FileData_ValidateAndDispatch` (round-trips, but the decode is
nonsense -- pushw/incf/halt/four near-identical jrl-nc/32x swi 7 -- while
v9/v10's real routine at that label opens with a `push xix / push xiy /
push xiz ...` prologue that shares nothing with it) and
`Sprintf_DecExp_ApplySign` (27x 0xff, decodes as 27x `swi 7`, i.e. erased
flash, not code).

This run (2026-09-02) added a THIRD manual exclusion for the same reason:
`MidiSerial_StatusTable`. Its own name says table, v9/v10 show it addressed
via `ld xiz, MidiSerial_StatusTable_0x1` then a register-indexed load then
`call (xiz)` -- an indirect call through a computed offset, the exact "jump
table round-trips as code" shape the lane brief calls out as a hazard -- and
v9/v10's own decode at that label is a suspicious near-uniform repeat
(`swi 7` then seven near-identical `cpm_spiw ix, 250 / nop` pairs), which
looks like a repeated-byte-value coincidental decode rather than a real
routine. Left `.incbin`.

The three CONVERTED here passed a stronger check: their v9/v10 counterpart,
read directly (not just classified), is an instruction-for-instruction
structural match -- same operand shapes, same `call`/`extz`/`divs` sequences,
consistent reuse of a handful of absolute call targets across repeats within
one slice (RVari_Select_CheckSameBank calls the same four addresses 2-3
times each) -- not a chain of fabricated local labels referencing nothing
outside the span.

  * RVari_Select_CheckSameBank (931 B) -- matches v9/v10's real routine at
    that label line-for-line (mnemonic families differ only because the
    pinned backend now prints newer SriRR-family forms).
  * DispSeqList_LoopBody (102 B) -- v9/v10 body is IDENTICAL modulo absolute
    addresses (same loop counter compare, same `jr lt` back-branch).
  * AccDir_JumpTable (7 B) -- despite the name, v9 AND v10 both hold the
    exact shape `nop / nop / call <addr> / ret` at this label (confirmed by
    reading the source directly, not just its classification).

VERIFICATION
------------
Each candidate's stored decode (already proven byte-exact by
v7_slice_code_roundtrip.py) is re-verified against the CURRENT .bin content
before writing, in case the corpus moved under it.

RUN
    python3 scripts/converters/convert_v7_code_slices.py             # dry run
    python3 scripts/converters/convert_v7_code_slices.py --apply     # writes
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

APPROVED = {'RVari_Select_CheckSameBank', 'DispSeqList_LoopBody', 'AccDir_JumpTable'}


def assemble(lines):
    text = '\n'.join(lines) + '\n'
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=30)
    if p.returncode != 0:
        return None
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    try:
        p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath],
                             capture_output=True, timeout=30)
        if p2.returncode != 0:
            return None
        with open(binpath, 'rb') as f:
            return f.read()
    finally:
        for p_ in (objpath, binpath):
            if os.path.exists(p_):
                os.remove(p_)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    rows = json.load(open('scripts/analysis/v7_slice_code_roundtrip.json'))
    candidates = [r for r in rows if r['label'] in APPROVED and r['status'] == 'MATCH']
    assert len(candidates) == len(APPROVED), \
        f"expected {len(APPROVED)} approved MATCH rows, found {len(candidates)}"

    total = 0
    per_file = {}
    for r in candidates:
        with open(r['bin'], 'rb') as f:
            data = f.read()
        got = assemble(r['lines'])
        if got != data:
            print(f"SKIP {r['label']}: re-verify failed (corpus moved under this candidate)")
            continue
        print(f"  OK  {r['size']:6,d}  {r['label']}")
        total += r['size']
        per_file.setdefault(r['file'], []).append(r)

    print(f"\n{total:,} B verified across {len(per_file)} files")
    if not args.apply:
        print("(dry run -- pass --apply to write)")
        return 0

    for fname, entries in per_file.items():
        lines = open(fname, encoding='latin-1').readlines()
        for r in sorted(entries, key=lambda r: -r['incbin_line']):
            i = r['incbin_line']
            assert '.incbin' in lines[i] and 'romslices/' in lines[i], \
                f"{fname}:{i+1} does not look like the expected .incbin line: {lines[i]!r}"
            lines[i] = '\n'.join(r['lines']) + '\n'
        open(fname, 'w', encoding='latin-1').writelines(lines)
        print(f"rewrote {fname}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
