#!/usr/bin/env python3
"""v7_slice_code_roundtrip.py -- which v7 CODE-shaped romslices survive a byte-exact
llvm-mc disassemble -> reassemble round trip?

QUESTION ANSWERED
-----------------
`v7_slice_v9v10_correspondence.py` names slices whose v9/v10 same-named label is
real code. That is a candidate list, not a proof (see its docstring). This script
tests each candidate the only way that actually certifies anything for THIS
project: disassemble the raw slice bytes with llvm-mc's OWN disassembler (the
same tool this tree's Makefile uses to assemble), then reassemble that exact
text and require the ORIGINAL bytes back, exactly. `llvm-mc --disassemble`
reports "warning: invalid instruction encoding" whenever it cannot decode a
byte at all -- a slice with any such warning is not attempted further.

RESULT, 2026-09-02 (v7 lane, wave 2): of 50 CODE-labelled slices (26,515 B),
0 decode warning-free above ~50 B -- the same tlcs900-backend spelling gap
already documented for v7's general code-as-`.byte` debt (DEBT-INVENTORY's
"9,463 unspellable instances") reaches into the romslice transplants too.
13 small slices (269 B total) round-trip clean. Manual review then DROPPED 2
of the 13 the gate cannot see through on its own:

  * KeyScaleNoteStr_G (28 B) -- a clean decode, but v9/v10 show `.byte` (a
    string) at this label once the label's OWN line is read correctly (see the
    correspondence script's docstring for that bug). Never committed as code.
  * FileData_ValidateAndDispatch (47 B) -- the decode ("pushw / incf / halt /
    four near-identical `jrl nc`s / 32x `swi 7`") is not sensible code, and
    v9/v10's real routine at this label opens with an ordinary `push` prologue,
    not this. A byte-exact round trip is necessary, not sufficient -- exactly
    the HD-AE5000 version-string trap (309 B of "code" that was really a
    string, PR notes). Left as `.incbin`.

One further slice, Sprintf_DecExp_ApplySign (27 B, ALL 0xff), round-trips as
27x `swi 7` but is not code either: v9/v10 carry a real ~10-instruction routine
at that label, so this is not shared structure -- this v7 build's flash is
unprogrammed/erased there. Retyped by hand as `.fill 27, 1, 0xff`, not as
instructions.

⚠ WHY WHOLE-BLOCK REASSEMBLY IS POSITION-INDEPENDENT HERE: this dialect's `jr`/
`jrl`/`calr` mnemonics take the RAW DISPLACEMENT BYTE as their printed operand,
not a symbolic target (`echo "jr nz, 44" | llvm-mc --triple=tlcs900
--show-encoding` re-emits [0x6e,0x2c] regardless of where it sits). So
disassembling a slice starting at offset 0 and reassembling it starting at
offset 0 reproduces the exact bytes even though the slice's real ROM address is
different -- no relocation, no symbol table needed for this check.

RUN:  python3 scripts/analysis/v7_slice_code_roundtrip.py
      reads scripts/analysis/v7_slice_v9v10_correspondence.json (run that first)
"""
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)
LLVM_MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
LLVM_OBJCOPY = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-objcopy')


def disasm(data):
    hexstr = ' '.join(f'0x{b:02x}' for b in data)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '--disassemble'],
                        input=hexstr, capture_output=True, text=True, timeout=30)
    warnings = p.stderr.count('warning: invalid instruction encoding')
    lines = [l for l in p.stdout.split('\n') if l.strip()]
    return lines, warnings


def reassemble(lines):
    text = '\n'.join(lines)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=30)
    if p.returncode != 0:
        return None
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath], capture_output=True, text=True)
    if p2.returncode != 0:
        os.unlink(objpath)
        return None
    data = open(binpath, 'rb').read()
    os.unlink(objpath)
    os.unlink(binpath)
    return data


def main():
    src = 'scripts/analysis/v7_slice_v9v10_correspondence.json'
    if not os.path.exists(src):
        sys.exit(f'{src} not found -- run v7_slice_v9v10_correspondence.py first')
    rows = json.load(open(src))
    code_rows = [r for r in rows if r['kind'] == 'CODE']

    results, total_clean, bytes_clean = [], 0, 0
    for r in sorted(code_rows, key=lambda r: -r['size']):
        if not os.path.exists(r['bin']):
            continue          # already converted and its slice file removed
        data = open(r['bin'], 'rb').read()
        lines, warnings = disasm(data)
        if warnings:
            status = f'{warnings} decode warnings'
        else:
            reasm = reassemble(lines)
            if reasm is None:
                status = 'ASM_FAIL'
            elif reasm == data:
                status = 'MATCH'
                total_clean += 1
                bytes_clean += r['size']
            else:
                status = f'MISMATCH len={len(reasm)} vs {len(data)}'
        print(f"{r['size']:6d}  {r['label']:40s} {status}")
        results.append({**r, 'status': status, 'lines': lines if status == 'MATCH' else None})

    print(f"\nCLEAN ROUND TRIP: {total_clean} slices, {bytes_clean} B of "
          f"{sum(r['size'] for r in code_rows if os.path.exists(r['bin'])):,} B still CODE-labelled")
    out = 'scripts/analysis/v7_slice_code_roundtrip.json'
    json.dump(results, open(out, 'w'), indent=1)
    print(f'wrote {out}')


if __name__ == '__main__':
    sys.exit(main())
