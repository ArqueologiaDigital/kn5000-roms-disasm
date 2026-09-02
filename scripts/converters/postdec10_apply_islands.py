#!/usr/bin/env python3
"""postdec10_apply_islands.py -- Convert the islands that scan reports. ⚠ THIS WRITES.

RUN
    python3 scripts/converters/postdec10_apply_islands.py

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
import sys, os, re, subprocess, tempfile

REPO = "/home/fsanches/compartilhado/disasm-lanes/postdec10"
LLVM_MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
LLVM_OBJCOPY = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-objcopy"

BYTE_RE = re.compile(r'^(\s*)\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')

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
    ok = p2.returncode == 0
    data = open(binpath, 'rb').read() if ok else None
    os.unlink(objpath)
    if ok: os.unlink(binpath)
    return data

def parse_candidates(path):
    out = []
    for line in open(path):
        line = line.rstrip('\n')
        if not line.strip(): continue
        # format: "  v10/relpath:LINE  NB  decoded / text"
        m = re.match(r'^\s*(\S+):(\d+)\s+\d+B\s+', line)
        if not m: continue
        relp, lineno = m.group(1), int(m.group(2))
        out.append((relp, lineno))
    return out

def get_byte_line(fp, lineno):
    lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
    if lineno - 1 >= len(lines): return None, None, None
    m = BYTE_RE.match(lines[lineno-1])
    if not m: return None, None, None
    indent = m.group(1)
    raw = bytes(int(x.strip(), 16) for x in m.group(2).split(','))
    return lines, indent, raw

def main():
    apply = '--apply' in sys.argv
    cand_file = sys.argv[1]
    candidates = parse_candidates(cand_file)
    print(f"{len(candidates)} candidates loaded from {cand_file}")

    converted = []
    skipped = []
    v9_mismatch = []

    for relp, lineno in candidates:
        v10_fp = os.path.join(REPO, relp)
        lines10, indent, raw = get_byte_line(v10_fp, lineno)
        if lines10 is None:
            skipped.append((relp, lineno, "line no longer a .byte directive"))
            continue
        dl, warn = disasm(list(raw))
        if warn > 0:
            skipped.append((relp, lineno, "decode warning"))
            continue
        rt = reassemble(dl)
        if rt != raw:
            skipped.append((relp, lineno, f"round-trip mismatch (got {rt})"))
            continue
        # Build replacement lines with matching indent, tab-separated mnemonic/operands
        new_src_lines = []
        for dline in dl:
            txt = dline.strip()
            # llvm-mc prints "mnemonic\toperands" or just "mnemonic"
            new_src_lines.append(indent + txt)

        v9_relp = relp.replace('v10', 'v9') if relp.startswith('v10/') else None
        v9_fp = os.path.join(REPO, v9_relp) if v9_relp else None
        v9_ok = False
        if v9_fp and os.path.exists(v9_fp):
            lines9, indent9, raw9 = get_byte_line(v9_fp, lineno)
            if lines9 is not None and raw9 == raw:
                v9_ok = True
            else:
                v9_mismatch.append((relp, lineno))

        converted.append(dict(relp=relp, lineno=lineno, raw=raw, new_lines=new_src_lines,
                              v9_relp=v9_relp, v9_ok=v9_ok))

    print(f"\n{len(converted)} converted, {len(skipped)} skipped, "
          f"{len(v9_mismatch)} v9-mirror-mismatch (v10-only)")
    for relp, lineno, reason in skipped:
        print(f"  SKIP {relp}:{lineno} -- {reason}")
    total_bytes = sum(len(c['raw']) for c in converted)
    print(f"Total bytes to convert: {total_bytes}")

    if not apply:
        print("\nDRY RUN -- pass --apply to write changes")
        for c in converted[:20]:
            print(f"  {c['relp']}:{c['lineno']}  {len(c['raw'])}B -> {' / '.join(l.strip() for l in c['new_lines'])}  v9={'OK' if c['v9_ok'] else 'SKIP'}")
        return

    # Apply: group by file, process from bottom to top so line numbers don't shift within a file
    from collections import defaultdict
    by_file = defaultdict(list)
    for c in converted:
        by_file[c['relp']].append(c)
        if c['v9_ok']:
            by_file[c['v9_relp']].append(dict(c, relp=c['v9_relp']))

    for relp, items in by_file.items():
        fp = os.path.join(REPO, relp)
        lines = open(fp, encoding='utf-8', errors='surrogateescape').read().split('\n')
        items.sort(key=lambda c: -c['lineno'])
        for c in items:
            i = c['lineno'] - 1
            # re-verify before writing
            m = BYTE_RE.match(lines[i])
            if not m:
                print(f"  ABORT {relp}:{c['lineno']} -- line changed since scan, skipping")
                continue
            raw_now = bytes(int(x.strip(), 16) for x in m.group(2).split(','))
            if raw_now != c['raw']:
                print(f"  ABORT {relp}:{c['lineno']} -- bytes changed since scan, skipping")
                continue
            lines[i:i+1] = c['new_lines']
        open(fp, 'w', encoding='utf-8', errors='surrogateescape').write('\n'.join(lines))
        print(f"  wrote {relp} ({len(items)} edits)")

if __name__ == '__main__':
    main()
