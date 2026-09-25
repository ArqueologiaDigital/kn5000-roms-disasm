#!/usr/bin/env python3
r"""nakabig_rodata_refs.py -- who references each byte of a NAKA-blob span, and how.

QUESTION ANSWERED
-----------------
The span 0xE44478..0xE4C0D2 of `widget_descriptors.s` carried four slice
labels (`WidgetData_DrawbarPositionTable`, `WidgetData_CharsetMappingTable`,
`FontPalette_Gradient0..7`, `Display_FontPalette_Table`) whose names were
guesses from the bytes.  The code reaches into it at ~120 distinct offsets,
mostly through `shared/positional_labels.s` names such as
`Display_FontPalette_Table_0x4507` (= label + 0x4507).  To find out what the
span really is, every such reference has to be listed with the instruction
that makes it and the routine it sits in.  This script does that, for any
set of anchor labels, over every `.s` file of an image (read as latin-1 --
never a recursive `grep`, which skips these files).

For each referenced offset it prints: the ROM address, the distance to the
next referenced offset (an upper bound on the object's extent), and for every
reference the file:line, the enclosing routine label (nearest preceding
column-0 label that is not a `_Skip`/`_Join`/`_Loop`-style local), the
instruction, and the next `--after` source lines (where a stride, a bound or a
copy length shows up).

RUN
    python3 scripts/analysis/nakabig_rodata_refs.py                    # default span
    python3 scripts/analysis/nakabig_rodata_refs.py --after 8 --from 0x184FF --to 0x19114
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLOB_BASE = 0xE30E60
ANCHORS = {
    'WidgetData_DrawbarPositionTable': 0x13618,
    'WidgetData_CharsetMappingTable': 0x137D6,
    'FontPalette_Gradient7': 0x13D12,
    'Display_FontPalette_Table': 0x13FF8,
}
for _k in range(7):
    ANCHORS['FontPalette_Gradient%d' % _k] = 0x13F98 - 0x60 * _k
LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Ret|Done|Next|Exit|Found|Clamp|'
                   r'Store\w*|Check\w*|Case\w*|Else|Then|End|Continue|Default|Helper)\d*$')


def load_sources(img):
    out = []
    root = os.path.join(ROOT, img, 'maincpu')
    for dp, _, fns in os.walk(root):
        for fn in sorted(fns):
            if fn.endswith('.s'):
                p = os.path.join(dp, fn)
                out.append((os.path.relpath(p, root),
                            open(p, encoding='latin-1').read().split('\n')))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--image', default='v10')
    ap.add_argument('--after', type=int, default=5)
    ap.add_argument('--from', dest='lo', type=lambda x: int(x, 0), default=0x13618)
    ap.add_argument('--to', dest='hi', type=lambda x: int(x, 0), default=0x1B272)
    a = ap.parse_args()
    srcs = load_sources(a.image)
    pos = {}
    for rel, lines in srcs:
        for ln in lines:
            m = re.match(r'\s*\.set (\w+), (\w+) \+ (\d+)\s*$', ln)
            if m and m.group(2) in ANCHORS:
                pos[m.group(1)] = ANCHORS[m.group(2)] + int(m.group(3))
    names = dict(pos)
    names.update(ANCHORS)
    rx = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, names), key=len, reverse=True)) + r')\b')
    refs = {}
    for rel, lines in srcs:
        if rel in ('shared/positional_labels.s', 'ui_widgets/widget_descriptors.s'):
            continue
        routine = None
        for i, ln in enumerate(lines):
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
            if m and not LOCAL.search(m.group(1)):
                routine = m.group(1)
            code = ln.split(';')[0]
            for mm in rx.finditer(code):
                off = names[mm.group(1)]
                if a.lo <= off < a.hi:
                    ctx = [' '.join(x.split(';')[0].split()) for x in lines[i + 1:i + 1 + a.after]]
                    refs.setdefault(off, []).append((rel, i + 1, routine, ' '.join(code.split()), ctx))
    offs = sorted(refs)
    for k, off in enumerate(offs):
        nxt = offs[k + 1] if k + 1 < len(offs) else a.hi
        print('+0x%05X  ROM 0x%06X  extent <= %d B' % (off, BLOB_BASE + off, nxt - off))
        for rel, n, routine, code, ctx in refs[off]:
            print('    %s:%d  [%s]  %s' % (rel, n, routine, code))
            if a.after:
                print('        | ' + ' | '.join(c for c in ctx if c))
    print('%d referenced offsets' % len(offs), file=sys.stderr)


if __name__ == '__main__':
    main()
