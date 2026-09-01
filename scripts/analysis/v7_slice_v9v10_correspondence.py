#!/usr/bin/env python3
"""v7_slice_v9v10_correspondence.py -- what does each v7 romslice look like in v9/v10?

QUESTION ANSWERED
-----------------
v7's 272 live `.incbin`-referenced `includes/romslices/*.bin` blobs
(`v7_no_source_bytes.py`) carry names derived, at transplant time, from the
symbol at that exact ROM address (`scripts/build/v7_incbin_transplant.py`).
Since v7/maincpu shares its source-file layout and most of its labels with
v9/v10 (three revisions of the same firmware), a v7 slice's label very often
names a real symbol in v9/v10 too -- so "what does the v9/v10 counterpart look
like at this label" is not a fuzzy nearest-neighbour search, it is a literal
name lookup. This script does that lookup for every live slice and reports
what kind of content sits there: real disassembled CODE, a `.byte`/`.ascii`
DATA run, a `.long` table, or NOTFOUND (the name has drifted, e.g. through a
label-repair pass, or is v7-only).

⚠ A LABEL CAN CARRY ITS DIRECTIVE ON THE SAME LINE ("Label:\t.byte ..."). An
early version of this script only scanned lines AFTER the label line and
misclassified every such case as CODE (it fell through to the next real
content). `KeyScaleNoteStr_G` was caught this way: it looked like code, round
was a plausible decode, and it is actually `.byte 0x47, 0x20, 0x00, 0xff, ...`,
a string, with the directive on the label's own line. Fixed by checking the
label line's own tail first. The lesson generalises: THIS SCRIPT NAMES A
CANDIDATE, NOT A VERDICT. See v7_slice_code_roundtrip.py for the verification
step this feeds, and its docstring for a second trap (a clean decode is not
proof of code) it does NOT protect against.

Run:  python3 scripts/analysis/v7_slice_v9v10_correspondence.py
      writes scripts/analysis/v7_slice_v9v10_correspondence.json
"""
import glob
import json
import os
import re
import sys
import collections

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
LABEL_DEF = re.compile(r'^([A-Za-z_.][\w.]*):\s*(.*)$')
DIRECTIVE = re.compile(r'^\.(\w+)')
MACRO_INVOKE = re.compile(r'^(\w+)\b')


def macro_names(*roots):
    """Names defined by `.macro NAME ...` anywhere in the given trees. A macro
    invocation has no leading dot and no colon, so it is syntactically
    indistinguishable from an instruction mnemonic to a naive classifier --
    ProcNameStr_NormScreenProc was caught exactly this way: its v9/v10 body is
    `aligned_string "NormScreenProc"`, a STRING via macro, and the naive
    classifier called it CODE. A macro invocation is reported as its own kind
    (below), never as CODE."""
    names = set()
    pat = re.compile(r'^\.macro\s+(\S+)')
    for root in roots:
        for f in glob.glob(f'{root}/**/*.s', recursive=True):
            for line in open(f, encoding='latin-1'):
                m = pat.match(line)
                if m:
                    names.add(m.group(1))
    return names


def list_slices():
    """Every live-referenced romslice: which file/label incbins it, its size,
    and the label that follows it in the SAME v7 file (used only to sanity-check
    the boundary, e.g. against SeMenu_RefreshPartDisplay_Data's +13 offset)."""
    rows, seen = [], set()
    for f in sorted(glob.glob('v7/maincpu/**/*.s', recursive=True)):
        lines = open(f, encoding='latin-1').readlines()
        base = os.path.dirname(f)
        for i, line in enumerate(lines):
            m = INC.search(line)
            if not m or 'romslices/' not in m.group(1):
                continue
            path, off, ln = m.groups()
            real = next((c for c in (os.path.join(base, path), os.path.join('v7/maincpu', path), path)
                         if os.path.exists(c)), None)
            if not real:
                continue
            real = os.path.abspath(real)
            fsz = os.path.getsize(real)
            size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            label = None
            for j in range(i - 1, -1, -1):
                mm = LABEL_DEF.match(lines[j].strip())
                if mm:
                    label = mm.group(1)
                    break
            nextlabel = None
            for j in range(i + 1, min(i + 5, len(lines))):
                mm = LABEL_DEF.match(lines[j].strip())
                if mm:
                    nextlabel = mm.group(1)
                    break
            if real in seen:
                continue
            seen.add(real)
            rows.append({'file': f, 'incbin_line': i, 'label': label, 'next_label': nextlabel,
                         'bin': os.path.relpath(real, REPO), 'size': size})
    return rows


def build_label_index(root):
    """label -> (file, line_index, all_lines), first definition only."""
    idx = {}
    for f in glob.glob(f'{root}/**/*.s', recursive=True):
        lines = open(f, encoding='latin-1').readlines()
        for i, line in enumerate(lines):
            m = LABEL_DEF.match(line.strip())
            if m and m.group(1) not in idx:
                idx[m.group(1)] = (f, i, lines)
    return idx


def classify_at(f, i, lines, macros):
    """What immediately follows a label definition: CODE, a MACRO invocation
    (never CODE -- see macro_names), or a directive name (byte/ascii/long/...).
    Checks the LABEL'S OWN line tail first -- see the module docstring for why
    that is not optional."""
    same_line_tail = LABEL_DEF.match(lines[i].strip()).group(2).strip()
    candidates = [same_line_tail] + [lines[j].strip() for j in range(i + 1, min(i + 8, len(lines)))]
    for s in candidates:
        if not s or s.startswith(';'):
            continue
        m = DIRECTIVE.match(s)
        if m:
            d = m.group(1)
            if d in ('equ', 'set', 'globl', 'global', 'include'):
                continue
            return d, s
        if LABEL_DEF.match(s):
            continue
        mm = MACRO_INVOKE.match(s)
        if mm and mm.group(1) in macros:
            return f'MACRO:{mm.group(1)}', s
        return 'CODE', s
    return 'EMPTY', ''


def main():
    rows = list_slices()
    idx9 = build_label_index('v9/maincpu')
    idx10 = build_label_index('v10/maincpu')
    macros = macro_names('v7/maincpu', 'v9/maincpu', 'v10/maincpu')

    results = []
    for r in rows:
        label = r['label']
        v9d = v9line = v10d = v10line = None
        if label:
            if label in idx9:
                f, i, lines = idx9[label]
                v9d, v9line = classify_at(f, i, lines, macros)
            if label in idx10:
                f, i, lines = idx10[label]
                v10d, v10line = classify_at(f, i, lines, macros)
        results.append({**r, 'kind': v9d or v10d or 'NOTFOUND', 'sample': v9line or v10line or ''})

    out = os.path.join('scripts/analysis', 'v7_slice_v9v10_correspondence.json')
    json.dump(results, open(out, 'w'), indent=1)

    c, b = collections.Counter(), collections.Counter()
    for r in results:
        c[r['kind']] += 1
        b[r['kind']] += r['size']
    print(f"{len(rows)} live romslices, {sum(r['size'] for r in rows):,} B -- classified by the "
          f"v9/v10 label of the same name:\n")
    for k, n in c.most_common():
        print(f"  {k:12s} {n:4d} files {b[k]:8,d} bytes")
    print(f"\nwrote {out}")


if __name__ == '__main__':
    sys.exit(main())
