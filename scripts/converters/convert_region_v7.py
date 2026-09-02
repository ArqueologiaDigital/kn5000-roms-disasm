#!/usr/bin/env python3
"""convert_region_v7.py -- convert ONE pre-vetted v7 .byte run to real instructions.

ADAPTATION OF scripts/converters/convert_region.py (Lane V10V9) FOR v7
  The original script applies an edit to BOTH v9 and v10 in lockstep, after
  asserting their bytes at that path/line are identical -- it has no notion of
  a single tree. v7 is a different firmware revision with no v9/v10-style
  sibling to cross-check against (v7's own tree is the only copy), so this is
  a single-tree variant: same block parser, same decode/round-trip engine
  (reused from convert_code_bytes.py, unmodified), same dry-run-by-default
  safety, but it reads and writes ONLY v7/<relpath>.

RUN
    python3 scripts/converters/convert_region_v7.py <relpath> <start_line> <size>
    python3 scripts/converters/convert_region_v7.py <relpath> <start_line> <size> --apply

⚠ IT ANCHORS ON A 1-INDEXED LINE NUMBER -- same fragility as the original:
  converting an earlier block in the same file first moves every later line
  number. Convert bottom-to-top within one file, or re-read line numbers
  after every --apply.

⚠ DECODING IS NOT PROOF. Vet the block's external corroboration (e.g. via
  verify_converted_call_targets.py --tag v7) BEFORE --apply, not after.
"""
import sys, re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_code_bytes as cb

BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
LABEL_RE = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*)\s*:\s*$')


def parse_block(lines, start_idx):
    """start_idx is 0-indexed. Returns (end_idx_inclusive, raw_bytes, labels).

    A run is a MAXIMAL sequence of `.byte` lines, with blank lines, comment
    lines, and bare (non-directive) labels allowed to interleave WITHOUT
    ending the run -- mirroring the marker-injector grouping logic in
    v9_v10_undisassembled_census.py's inject(), which is what census() used to
    size this region in the first place. A label mid-block is common: v7's
    census regions frequently cross a named entry point (e.g. a dispatch
    target) sitting inside a longer undecoded span. `labels` maps a byte
    OFFSET (0-indexed into raw_bytes) to the label text(s) that sat
    immediately before that offset, so the caller can put them back at the
    right point in the re-framed instruction stream instead of losing them.
    """
    # PASS 1: find the true last `.byte` line, exactly like inject()'s own
    # lookahead -- blanks/comments/labels are consumed SPECULATIVELY while
    # scanning for one more `.byte` line, but `last` only ever advances to a
    # confirmed `.byte` line index. A label sitting AFTER the true last .byte
    # line (the entry point of whatever comes next, not part of this block)
    # must never be swallowed: it stays untouched in the file at its original
    # position, which is still byte-address-correct because converting the
    # bytes BEFORE it to instructions does not change their total count.
    j = last = start_idx
    while j < len(lines):
        t = lines[j].strip()
        if BYTE_RE.match(lines[j]):
            last = j; j += 1
        elif t == "" or t.startswith(";") or t.startswith("#") or LABEL_RE.match(t):
            j += 1
        else:
            break

    # PASS 2: collect bytes and INTERIOR labels only over [start_idx, last].
    raw, labels = [], {}
    for k in range(start_idx, last + 1):
        m = BYTE_RE.match(lines[k])
        if m:
            raw.extend(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1)))
            continue
        lm = LABEL_RE.match(lines[k].strip())
        if lm:
            labels.setdefault(len(raw), []).append(lm.group(1))
    return last, raw, labels


def build_replacement(raw_bytes, labels):
    results = cb.convert_block(raw_bytes, base_pc=0, verbose=False)
    new_lines = []
    undecoded = []
    def flush():
        if undecoded:
            hexs = ', '.join(f'0x{b:02x}' for b in undecoded)
            new_lines.append(f'\t.byte {hexs}')
            undecoded.clear()
    seen = set()
    def emit_labels(off):
        # flush() FIRST: a label marks an exact byte ADDRESS, so any undecoded
        # bytes preceding it must be closed out into their own .byte line
        # before the label text -- otherwise a later instruction's flush()
        # would merge pre-label and post-label bytes into one directive and
        # silently shift the label to the wrong address. Bytes are unaffected
        # either way (labels emit none), but the label's resolved address
        # would be wrong -- a correctness bug the byte gate cannot see.
        if off in labels:
            flush()
            for name in labels[off]:
                new_lines.append(f'{name}:')
            seen.add(off)
    pos = 0
    emit_labels(0)
    for mnem, off, nb in results:
        # off/nb from convert_block are relative to this call's raw_bytes, in order.
        if mnem is None:
            undecoded.extend(raw_bytes[off:off + nb])
        else:
            flush()
            new_lines.append(f'\t{mnem}')
        pos = off + nb
        emit_labels(pos)
    flush()
    missed = set(labels) - seen
    if missed:
        raise AssertionError(
            f"label(s) at offset(s) {sorted(missed)} do not fall on an "
            f"instruction boundary produced by this decode -- refusing to "
            f"silently drop or mis-place them; this region's framing is "
            f"suspect, do not --apply")
    remaining = sum(nb for mnem, _, nb in results if mnem is None)
    return new_lines, remaining


def process(relpath, start_line, expected_size, apply=False):
    p7 = REPO / 'v7' / relpath
    lines7 = p7.read_text(encoding='latin-1').split('\n')
    start_idx = start_line - 1
    end7, raw7, labels7 = parse_block(lines7, start_idx)
    assert len(raw7) == expected_size, f"size mismatch: got {len(raw7)} expected {expected_size}"
    if labels7:
        print(f"    (preserving {sum(len(v) for v in labels7.values())} label(s) "
              f"at byte offsets {sorted(labels7)})")
    new_lines, remaining = build_replacement(raw7, labels7)
    print(f"=== v7/{relpath}:{start_line}  {len(raw7)}B  ->  "
          f"{len(raw7) - remaining}B converted, {remaining}B left as .byte ===")
    for nl in new_lines:
        print("   ", nl)
    if apply:
        lines7[start_idx:end7 + 1] = new_lines
        p7.write_text('\n'.join(lines7), encoding='latin-1')
        print(f"APPLIED to {p7}")
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
