#!/usr/bin/env python3
"""apply_v7_slice_splits.py -- apply SAFE splits from v7_slice_split_plan.json:
replace an `.incbin` romslice with a short typed data header (the original
label, unchanged) followed by a new label carrying the disassembled code tail.

WHY A SEPARATE STEP FROM THE PLANNER
-------------------------------------
v7_slice_split_plan.py only DECIDES; it never touches a `.s` file. This script
performs the edit, and only for entries the planner marked SAFE (both the
header-value/similarity gate and the whole-tail llvm-mc round trip + trivial-
instruction-fraction guard already passed).

⚠ LATIN-1, NOT UTF-8. These `.s` files carry raw high bytes in `.ascii`
literals; opening with the platform default codec (UTF-8) and writing back
has silently corrupted a byte before (BRIEF addendum, 2026-09-02). Every read
and write here is explicit `encoding='latin-1'`.

HEADER TEXT: always regenerated from the v7 slice's OWN raw bytes (never from
v9/v10's source text), even when kind is ascii/asciz and the v9/v10 bytes are
byte-identical (`header_similarity == 1.0`) -- one fewer thing to trust.

CODE LABEL: the plan's `named_boundary` (a real v9/v10 label sitting exactly
at the split point) when available, else `<Label>_Code`. Checked against every
label already defined anywhere in v7/maincpu before use, to avoid a silent
duplicate.

USAGE
    python3 scripts/converters/apply_v7_slice_splits.py [--labels A,B,C] [--apply]
    (no --apply: dry run, prints the diff-shape per label, touches nothing)
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

LABEL_DEF = re.compile(r'^([A-Za-z_.][\w.]*):\s*(.*)$')
INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')

PRINTABLE_SAFE = re.compile(rb'^[\x20-\x7e]$')


def escape_ascii(data):
    """Bytes -> a `.ascii`-literal-safe string body, escaping the same set
    unescape_bytes() in v7_slice_split_plan.py understands, so the round trip
    is exact both ways."""
    out = []
    for b in data:
        c = bytes([b])
        if c == b'\\':
            out.append('\\\\')
        elif c == b'"':
            out.append('\\"')
        elif b == 10:
            out.append('\\n')
        elif b == 9:
            out.append('\\t')
        elif b == 13:
            out.append('\\r')
        elif PRINTABLE_SAFE.match(c):
            out.append(c.decode('latin-1'))
        else:
            out.append(f'\\x{b:02x}')
    return ''.join(out)


def format_header(kind, data):
    """Header directive line(s) for `data`, built ONLY from those raw bytes."""
    if kind == 'zero' and all(b == 0 for b in data):
        return [f'\t.zero {len(data)}']
    if kind == 'asciz' and data and data[-1] == 0:
        body = data[:-1]
        if all(32 <= b <= 126 or b in (9, 10, 13) for b in body):
            return [f'\t.asciz "{escape_ascii(body)}"']
    if kind == 'ascii':
        if all(32 <= b <= 126 or b in (9, 10, 13) for b in data):
            return [f'\t.ascii "{escape_ascii(data)}"']
    # byte/long or any kind whose bytes are not cleanly printable: raw .byte,
    # 8 values per line, matching this tree's existing convention.
    lines = []
    for i in range(0, len(data), 8):
        chunk = data[i:i + 8]
        lines.append('\t.byte ' + ', '.join(f'0x{b:02x}' for b in chunk))
    return lines


def all_labels(root='v7/maincpu'):
    labels = set()
    for f in glob.glob(f'{root}/**/*.s', recursive=True):
        for line in open(f, encoding='latin-1'):
            m = LABEL_DEF.match(line.strip())
            if m:
                labels.add(m.group(1))
    return labels


def find_incbin_line(lines, binname):
    """Index of the line whose `.incbin` references a path ending in
    `binname` (the romslice's basename -- these are unique per-slice names)."""
    for i, line in enumerate(lines):
        m = INC.search(line)
        if m and os.path.basename(m.group(1)) == binname:
            return i
    return None


def main():
    argv = sys.argv[1:]
    apply = '--apply' in argv
    argv = [a for a in argv if a != '--apply']
    only = None
    for a in argv:
        if a.startswith('--labels'):
            only = set(a.split('=', 1)[1].split(','))

    plan = json.load(open('scripts/analysis/v7_slice_split_plan.json'))
    safe = [p for p in plan if p['verdict'] == 'SAFE']
    if only:
        safe = [p for p in safe if p['label'] in only]

    existing_labels = all_labels()
    from collections import defaultdict
    byfile = defaultdict(list)
    for p in safe:
        byfile[p['file']].append(p)

    touched_files = []
    removed_bins = []
    for f, items in byfile.items():
        lines = open(f, encoding='latin-1').readlines()
        # descending by incbin_line so earlier edits don't shift later ones
        items = sorted(items, key=lambda p: -p['incbin_line'])
        changed = False
        for p in items:
            label = p['label']
            binname = os.path.basename(p['bin'])
            i = find_incbin_line(lines, binname)
            if i is None:
                print(f'SKIP {label}: incbin for {binname} not found in {f} (stale plan?)')
                continue
            v7data = open(p['bin'], 'rb').read()
            hlen = p['header_len']
            header, tail_src = v7data[:hlen], v7data[hlen:]
            if len(tail_src) != p['tail_len']:
                print(f'SKIP {label}: tail_len mismatch, plan is stale, rerun the planner')
                continue

            header_lines = format_header(p['kind'], header)
            code_label = p.get('named_boundary')
            if code_label and code_label not in existing_labels:
                pass  # a real v9/v10 boundary name, not yet used in v7 -- best case
            else:
                code_label = f'{label}_Code'
            if code_label in existing_labels:
                print(f'SKIP {label}: candidate code label {code_label} already exists -- resolve by hand')
                continue

            # The label may sit on the incbin's own line ("Label:\t.incbin
            # ...") or on a separate preceding line ("Label:\n\t.incbin
            # ..."). Find which, and replace the whole [label_line, i] span
            # -- never just line i alone, or a same-line label would be lost.
            label_line = None
            for j in range(i, -1, -1):
                m = LABEL_DEF.match(lines[j].strip())
                if m and m.group(1) == label:
                    label_line = j
                    break
            if label_line is None:
                print(f'SKIP {label}: could not relocate its own label line in {f}')
                continue
            between_ok = all(not lines[j].strip() or lines[j].strip().startswith(';')
                              for j in range(label_line + 1, i))
            if label_line != i and not between_ok:
                print(f'SKIP {label}: unexpected content between label and incbin in {f}')
                continue

            new_lines = [f'{label}:\n']
            new_lines += [hl + '\n' for hl in header_lines]
            new_lines += [f'{code_label}:\n']
            new_lines += [tl + '\n' for tl in p['tail_lines']]

            print(f'{"APPLY" if apply else "PLAN "} {label}: header {hlen} B ({p["kind"]}), '
                  f'code {code_label} {p["tail_len"]} B ({len(p["tail_lines"])} instrs)')
            if apply:
                lines[label_line:i + 1] = new_lines
                changed = True
                existing_labels.add(code_label)
                removed_bins.append(p['bin'])

        if apply and changed:
            open(f, 'w', encoding='latin-1').writelines(lines)
            touched_files.append(f)

    if apply:
        print(f'\nTouched files: {touched_files}')
        print(f'Bins to remove: {removed_bins}')
        for b in removed_bins:
            if os.path.exists(b):
                os.remove(b)


if __name__ == '__main__':
    sys.exit(main())
