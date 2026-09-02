#!/usr/bin/env python3
"""instprint_test_residuals.py -- Probe which residual encodings survive a decode/re-encode cycle, for the zero-displacement collapse.

RUN
    python3 notes/instprint_test_residuals.py

⚠ A clean decode is NOT proof the bytes are code, and the byte-identity gate
  cannot help: re-assembling a wrong interpretation reproduces the same bytes.
  Corroborate with call targets landing on routines already named in the tree.

⚠ `--show-encoding`'s `encoding:` field is NOT reliably the bytes the
  disassembler consumed -- it can be a re-encode, shorter than the true
  consumed length. Summing shown-encoding lengths silently desyncs and then
  fabricates a PARTIAL DECODE for everything downstream; that produced a
  phantom 407-byte "decoder gap" which was retracted on 2026-09-02. Verify per
  instruction against the true byte slice.

PROVENANCE
  Lane INSTPRINT of the 2026-09-02 push; recovered from session scratch,
  which is volatile, before it was lost.
"""
import subprocess, sys

LLVM_MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"

def disasm(data):
    hexstr = ' '.join(f'0x{b:02x}' for b in data)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '--disassemble'],
                        input=hexstr, capture_output=True, text=True, timeout=10)
    warnings = p.stderr.count('warning: invalid instruction encoding')
    lines = [l for l in p.stdout.split('\n') if l.strip() and not l.strip().startswith('.text')]
    return lines, warnings, p.stderr

def reassemble(lines):
    text = '\n'.join(lines)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=10)
    if p.returncode != 0:
        return None
    import tempfile, os
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout)
        objpath = f.name
    binpath = objpath + '.bin'
    p2 = subprocess.run([LLVM_MC.replace('llvm-mc','llvm-objcopy'), '-O', 'binary', objpath, binpath],
                         capture_output=True, timeout=10)
    if p2.returncode != 0:
        return None
    data = open(binpath, 'rb').read()
    os.unlink(objpath); os.unlink(binpath)
    return data

with open(sys.argv[1]) as f:
    lines = [l.strip() for l in f if l.strip()]

converts = []
for lineno, line in enumerate(lines):
    raw = bytes(int(x.strip(), 16) for x in line.split(','))
    dl, warn, err = disasm(list(raw))
    if warn > 0:
        continue
    # Try full-consumption round trip
    rt = reassemble(dl)
    status = "FULL_MATCH" if rt == raw else ("PARTIAL/DIFF" if rt is not None else "REASM_FAIL")
    print(f"{line}  ->  decode_ok warn={warn}  insns={len(dl)}  reasm={status}")
    for l in dl:
        print("      ", l)
    if status == "FULL_MATCH":
        converts.append(line)

print()
print(f"=== {len(converts)}/{len(lines)} full byte-exact round trips ===")
for c in converts:
    print("  ", c)
