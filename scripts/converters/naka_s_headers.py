#!/usr/bin/env python3
r"""naka_s_headers.py -- write the evidence header above each NAKA blob slice label.

QUESTION ANSWERED
-----------------
`widget_descriptors.s`, `naka_widget_tables_1.s` and `naka_widget_tables_2.s`
slice the compiled NAKA blobs with labels:

    Bitmap_MIDIConnections_1:
    	.incbin "includes/generated/naka_widget_tables_2.bin", 0xA3D4, 0x7CE0

The label is what other code references and what the data census grades, so
it is where a reader looks first.  This script puts, directly above every
label listed in `naka_c_retype.OBJECTS`, the same evidence the C member
carries: what the object is, its format, and the code that reads it (name and
address in v10, v9 and v7).  The text is identical in the three versions --
the blobs are byte-identical there; only the reader addresses move, and all
three are quoted.

Headers are delimited by a marker line naming the label, so a re-run REPLACES
its own previous header and never touches any other comment.

RUN
    python3 scripts/converters/naka_s_headers.py            # dry run
    python3 scripts/converters/naka_s_headers.py --apply    # v10, v9, v7
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import naka_c_retype as R  # noqa: E402

RULE = '; ' + '-' * 77
MARK = '; [naka_s_headers] '


def header_lines(o):
    if o['kind'] == 'bitmap':
        text = R.bitmap_header(o)
        typed = ('Typed in %s.c as uint8_t %s[%d][%d] (rows of %d bytes).'
                 % (o['blob'], o['label'], o['h'], o['stride'], o['stride']))
    else:
        text = o['header']
        typed = o.get('typed', '')
    out = [RULE, MARK + o['label']]
    for ln in text.split('\n'):
        out.append(('; ' + ln).rstrip())
    if typed:
        out.append(';')
        for ln in R.wrap(typed).split('\n'):
            out.append('; ' + ln)
    out.append(RULE)
    # CLAUDE.md "Lowercase Hex": hex in .s comments is written lowercase
    return [re.sub(r'0x[0-9A-Fa-f]+', lambda m: m.group(0).lower(), l) for l in out]


def apply_file(path, objs, apply):
    raw = open(path, 'rb').read()
    lines = raw.decode('latin-1').split('\n')
    changed = 0
    for o in objs:
        lab = o['label'] + ':'
        idx = [i for i, l in enumerate(lines) if l == lab or l.startswith(lab + '\t') or l.startswith(lab + ' ')]
        if len(idx) != 1:
            raise SystemExit('%s: label %s found %d times' % (path, o['label'], len(idx)))
        i = idx[0]
        # drop our own previous header, if any
        j = i
        if j >= 2 and lines[j - 1] == RULE:
            k = j - 2
            while k >= 0 and lines[k] != RULE:
                k -= 1
            if k >= 0 and k + 1 < j and lines[k + 1] == MARK + o['label']:
                del lines[k:j]
                i = k
        new = header_lines(o)
        lines[i:i] = new
        changed += 1
    out = '\n'.join(lines).encode('latin-1')
    if apply and out != raw:
        open(path, 'wb').write(out)
    return changed, len(out) - len(raw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()
    byfile = {}
    for o in R.OBJECTS:
        byfile.setdefault(R.S_FOR[o['blob']], []).append(o)
    for v in ('v10', 'v9', 'v7'):
        for sname, objs in sorted(byfile.items()):
            path = os.path.join(ROOT, v, 'maincpu/ui_widgets', sname)
            n, delta = apply_file(path, objs, args.apply)
            print('%-4s %-26s %3d headers  %+d bytes%s'
                  % (v, sname, n, delta, '' if args.apply else '  (dry run)'))


if __name__ == '__main__':
    main()
