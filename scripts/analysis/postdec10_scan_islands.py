#!/usr/bin/env python3
"""postdec10_scan_islands.py -- Scan v10 for misframed .byte islands newly visible after the ERP/SriRR decoder fix.

RUN
    python3 scripts/analysis/postdec10_scan_islands.py

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
  Lane POSTDEC10 of the 2026-09-02 push; recovered from session scratch,
  which is volatile, before it was lost.
"""
import glob, re, subprocess, sys, os, tempfile

REPO = "/home/fsanches/compartilhado/disasm-lanes/postdec10"
LLVM_MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
LLVM_OBJCOPY = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-objcopy"

BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
# crude "is this line a real instruction" check: has a mnemonic, not a directive/label/comment
INSN_RE = re.compile(r'^\s*[a-zA-Z_][a-zA-Z0-9_]*(\s|$)')
DIRECTIVE_OR_LABEL = re.compile(r'^\s*(\.|;|#)|:$')

def is_code_line(line):
    s = line.strip()
    if not s: return False
    if DIRECTIVE_OR_LABEL.match(s): return False
    return bool(INSN_RE.match(s))

def disasm(data):
    hexstr = ' '.join(f'0x{b:02x}' for b in data)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '--disassemble'],
                        input=hexstr, capture_output=True, text=True, timeout=10)
    warnings = p.stderr.count('warning: invalid instruction encoding')
    lines = [l for l in p.stdout.split('\n') if l.strip() and not l.strip().startswith('.text')]
    return lines, warnings

def reassemble(lines):
    text = '\n'.join(lines)
    p = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '-'],
                        input=text.encode('latin-1'), capture_output=True, timeout=10)
    if p.returncode != 0:
        return None
    with tempfile.NamedTemporaryFile(suffix='.o', delete=False) as f:
        f.write(p.stdout); objpath = f.name
    binpath = objpath + '.bin'
    p2 = subprocess.run([LLVM_OBJCOPY, '-O', 'binary', objpath, binpath], capture_output=True, timeout=10)
    if p2.returncode != 0:
        os.unlink(objpath)
        return None
    data = open(binpath, 'rb').read()
    os.unlink(objpath); os.unlink(binpath)
    return data

results = []
files = sorted(glob.glob(os.path.join(REPO, "v10/maincpu/**/*.s"), recursive=True))
for fp in files:
    lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
    for i, line in enumerate(lines):
        m = BYTE_RE.match(line)
        if not m: continue
        # flanked check: previous non-blank/non-comment/non-label line is code, AND next is code
        pi = i - 1
        while pi >= 0 and (not lines[pi].strip() or lines[pi].strip().startswith(';') or lines[pi].strip().endswith(':')):
            pi -= 1
        ni = i + 1
        while ni < len(lines) and (not lines[ni].strip() or lines[ni].strip().startswith(';') or lines[ni].strip().endswith(':')):
            ni += 1
        prev_code = pi >= 0 and is_code_line(lines[pi])
        next_code = ni < len(lines) and is_code_line(lines[ni])
        if not (prev_code and next_code):
            continue
        raw = bytes(int(x.strip(), 16) for x in m.group(1).split(','))
        results.append((fp, i+1, raw))

print(f"Found {len(results)} CODE-flanked isolated .byte lines in v10/maincpu")
total_bytes = sum(len(r[2]) for r in results)
print(f"Total bytes in these islands: {total_bytes}")

converts = []
for fp, lineno, raw in results:
    dl, warn = disasm(list(raw))
    if warn > 0:
        continue
    rt = reassemble(dl)
    if rt == raw:
        converts.append((fp, lineno, raw, dl))

print(f"\n=== {len(converts)} islands now decode+round-trip byte-exact with the new decoder ===")
conv_bytes = sum(len(c[2]) for c in converts)
print(f"Total bytes convertible: {conv_bytes}")
for fp, lineno, raw, dl in converts:
    relp = os.path.relpath(fp, REPO)
    print(f"  {relp}:{lineno}  {len(raw)}B  {' / '.join(l.strip() for l in dl)}")
