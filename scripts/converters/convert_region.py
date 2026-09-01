#!/usr/bin/env python3
"""convert_region.py -- convert ONE pre-vetted .byte run to real instructions.

QUESTION ANSWERED
  Does this specific contiguous `.byte` block decode as real TLCS-900 code,
  and if so what are the instructions?  Prints a dry run by default; only
  `--apply` writes.  Applies the same edit to the v9 and v10 copies of the
  same relative path, having first asserted their bytes are identical.

RUN
    python3 scripts/converters/convert_region.py <relpath> <start_line> <size>
    python3 scripts/converters/convert_region.py <relpath> <start_line> <size> --apply

  Nothing outside the named block's exact line span is touched, and a size
  mismatch or a v9/v10 byte mismatch aborts rather than guessing.

⚠ IT ANCHORS ON A 1-INDEXED LINE NUMBER, WHICH IS FRAGILE.
  Line numbers move as soon as any earlier block in the same file is
  converted, so a start_line is only valid against the tree state it was
  derived from.  ALWAYS read the dry-run output before `--apply` and confirm
  the printed byte count matches what you expected; the size assert is the
  only thing standing between a stale line number and an edit to the wrong
  block.  Anchoring on a label or a ROM address would be the durable fix.

⚠ DECODING IS NOT PROOF.  Data decodes as plausible instructions in this
  ROM family -- that is a documented trap here, and the byte gate cannot
  see it, because re-assembling the wrong interpretation reproduces the same
  bytes.  A clean decode is a candidate, not a verdict; vet the block first.

PROVENANCE
  Lane V10V9 of the 2026-09-01 full-disassembly push; recovered from session
  scratch before it was lost.  REPO derives from this file's location.
"""
import sys, re, subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_code_bytes as cb

BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')

def parse_block(lines, start_idx):
    """start_idx is 0-indexed. Returns (end_idx_inclusive, raw_bytes)."""
    raw = []
    i = start_idx
    while i < len(lines):
        m = BYTE_RE.match(lines[i])
        if not m:
            break
        raw.extend(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1)))
        i += 1
    return i - 1, raw

def build_replacement(raw_bytes):
    results = cb.convert_block(raw_bytes, base_pc=0, verbose=False)
    new_lines = []
    undecoded = []
    def flush():
        if undecoded:
            hexs = ', '.join(f'0x{b:02x}' for b in undecoded)
            new_lines.append(f'\t.byte {hexs}')
            undecoded.clear()
    for mnem, off, nb in results:
        if mnem is None:
            undecoded.extend(raw_bytes[off:off+nb])
        else:
            flush()
            new_lines.append(f'\t{mnem}')
    flush()
    converted = sum(nb for mnem, _, nb in results if mnem is None)
    return new_lines, converted  # converted here = REMAINING undecoded bytes

def process(relpath, start_line, expected_size, apply=False):
    rel = relpath
    p9 = REPO / 'v9' / rel
    p10 = REPO / 'v10' / rel
    lines9 = p9.read_text(encoding='latin-1').split('\n')
    lines10 = p10.read_text(encoding='latin-1').split('\n')
    start_idx = start_line - 1
    end9, raw9 = parse_block(lines9, start_idx)
    end10, raw10 = parse_block(lines10, start_idx)
    assert raw9 == raw10, f"v9/v10 byte mismatch at {rel}:{start_line}"
    assert len(raw9) == expected_size, f"size mismatch: got {len(raw9)} expected {expected_size}"
    new_lines, remaining = build_replacement(raw9)
    print(f"=== {rel}:{start_line}  {len(raw9)}B  ->  {len(raw9)-remaining}B converted, {remaining}B left as .byte ===")
    for nl in new_lines:
        print("   ", nl)
    if apply:
        lines9[start_idx:end9+1] = new_lines
        lines10[start_idx:end10+1] = new_lines
        p9.write_text('\n'.join(lines9), encoding='latin-1')
        p10.write_text('\n'.join(lines10), encoding='latin-1')
        print(f"APPLIED to {p9} and {p10}")
    return remaining

if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('relpath')
    ap.add_argument('start_line', type=int)
    ap.add_argument('expected_size', type=int)
    ap.add_argument('--apply', action='store_true')
    a = ap.parse_args()
    process(a.relpath, a.start_line, a.expected_size, apply=a.apply)
