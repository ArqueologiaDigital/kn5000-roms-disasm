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
import naka_c_model as M  # noqa: E402

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


INCBIN_RE = re.compile(r'^\t\.incbin "includes/generated/([a-z0-9_]+)\.bin", '
                       r'(0x[0-9A-Fa-f]+|\d+), (0x[0-9A-Fa-f]+|\d+)\s*$')


def c_header(cb, name):
    """The comment block a retype builder wrote above C member `name`, as
    plain text (the `[typed] by` bookkeeping line removed)."""
    mb = cb.members[cb.by_name[name]]
    pre = mb.pre
    end = max(i for i, l in enumerate(pre) if l.rstrip().endswith('*/'))
    start = max(i for i in range(end + 1) if pre[i].lstrip().startswith('/*'))
    out = []
    for l in pre[start + 1:end]:
        t = l.strip()
        if t.startswith('* [typed] by'):
            continue
        out.append(t[2:] if t.startswith('* ') else t.lstrip('*'))
    return '\n'.join(out).strip('\n')


def split_slices(lines, blob, label, pieces):
    """Replace `label:` + one .incbin line by one labelled .incbin per piece
    (name, offset, length).  The pieces must tile the old slice exactly."""
    i = lines.index(label + ':')
    m = INCBIN_RE.match(lines[i + 1])
    assert m and m.group(1) == blob, lines[i + 1]
    off, ln = int(m.group(2), 0), int(m.group(3), 0)
    assert pieces[0][0] == label and pieces[0][1] == off, pieces[0]
    assert sum(p[2] for p in pieces) == ln, (sum(p[2] for p in pieces), ln)
    new = []
    for nm, o, n in pieces:
        new += [nm + ':', '\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (blob, o, n)]
    lines[i:i + 2] = new


def restructure_descriptors(lines, cb, data):
    """widget_descriptors.s: split NakaInst_OFF_Str's 37,262-byte slice at the
    objects the C now types, and spell the two ApFunction tables as .long."""
    if 'AccompSeq_StyleDataTable:' in lines:
        return 0
    blob = 'naka_widget_descriptors'
    base = cb.base()
    k0 = cb.by_name['NakaInst_OFF_Str']
    k1 = cb.by_name['MidiMenu_ApFunctionTable']
    pieces = []
    for mb in cb.members[k0:k1]:
        if mb.name.startswith('AccompSeq_Stream_'):
            if pieces[-1][0] != 'AccompSeq_Streams':
                pieces.append(['AccompSeq_Streams', mb.offset, 0])
            pieces[-1][2] += mb.size
        else:
            pieces.append([mb.name, mb.offset, mb.size])
    ft = cb.members[k1]
    pieces.append(['MidiMenu_ApFunctionTable', ft.offset, 0x24400 - ft.offset])
    split_slices(lines, blob, 'NakaInst_OFF_Str', pieces)
    # the ApFunction table and its name table, as symbolic .long
    sl = {}
    for j in range(len(lines) - 1):
        m = INCBIN_RE.match(lines[j + 1])
        if lines[j].endswith(':') and m and m.group(1) == blob:
            sl[int(m.group(2), 0)] = lines[j][:-1]
    fel = cb.elements('MidiMenu_ApFunctionTable')
    funcs = [re.fullmatch(r'NAKA_ADDR\((\w+)\)', e).group(1) for e in fel[:60]]
    assert fel[60] == '0x00000000'
    nt = cb.members[cb.by_name['MidiMenu_ApFunctionNameTable']]
    names = []
    for k in range(61):
        v = int.from_bytes(data[nt.offset + 4 * k:nt.offset + 4 * k + 4], 'little') - base
        names.append(sl[v])
    a = lines.index('MidiMenu_ApFunctionTable:')
    b = lines.index('NakaInst_EmptyFuncName:')
    old = '\n'.join(lines[a:b])
    # what we replace: the head incbin, EmbeddedPtrTable_*_024400 (40 procs,
    # the 0, the first name), Naka_UIStringRef_Table (names 2..22, which put
    # that label one entry past the table's start) and the incbin of names
    # 23..61.  Every symbol already spelled there must reappear in place.
    spelled = re.findall(r'\.long (\w+)', old)
    new = (['MidiMenu_ApFunctionTable:'] + ['\t.long %s' % f for f in funcs] +
           ['\t.long 0x00000000', 'MidiMenu_ApFunctionNameTable:'] +
           ['\t.long %s' % n for n in names])
    assert spelled == [x for x in re.findall(r'\.long (\w+)', '\n'.join(new))
                       if x != 'NakaInst_EmptyFuncName'][20:20 + len(spelled)], 'order'
    lines[a:b] = new
    return len(pieces)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()
    byfile = {}
    for o in R.OBJECTS:
        byfile.setdefault(R.S_FOR[o['blob']], []).append(o)
    # objects typed by the C builders: header text is read back from the C
    cb = M.CBlob(os.path.join(ROOT, R.UI, 'naka_widget_descriptors.c'))
    data = open(os.path.join(ROOT, R.GEN, 'naka_widget_descriptors.bin'), 'rb').read()
    from_c = []
    k0 = cb.by_name['NakaInst_OFF_Str']
    k1 = cb.by_name['MidiMenu_ApFunctionNameTable']
    for mb in cb.members[k0:k1 + 1]:
        if mb.name.startswith('AccompSeq_Stream_') and mb.name != 'AccompSeq_Stream_00_a':
            continue
        label = 'AccompSeq_Streams' if mb.name == 'AccompSeq_Stream_00_a' else mb.name
        typed = 'Typed in naka_widget_descriptors.c as %s %s%s.' % (mb.ctype, mb.name, mb.dims)
        if label == 'AccompSeq_Streams':
            typed = ('Typed in naka_widget_descriptors.c as one uint8_t array per '
                     'stream, AccompSeq_Stream_00_a .. AccompSeq_Stream_77_b.')
        from_c.append(dict(kind='c', blob='naka_widget_descriptors', label=label,
                           header=c_header(cb, mb.name), typed=typed))
    byfile.setdefault('widget_descriptors.s', []).extend(from_c)
    for v in ('v10', 'v9', 'v7'):
        for sname, objs in sorted(byfile.items()):
            path = os.path.join(ROOT, v, 'maincpu/ui_widgets', sname)
            if sname == 'widget_descriptors.s':
                raw = open(path, 'rb').read()
                lines = raw.decode('latin-1').split('\n')
                n = restructure_descriptors(lines, cb, data)
                if n and args.apply:
                    open(path, 'wb').write('\n'.join(lines).encode('latin-1'))
                print('%-4s %-26s split into %d slices%s' % (v, sname, n, '' if args.apply else '  (dry run)'))
                if n and not args.apply:
                    continue
            n, delta = apply_file(path, objs, args.apply)
            print('%-4s %-26s %3d headers  %+d bytes%s'
                  % (v, sname, n, delta, '' if args.apply else '  (dry run)'))


if __name__ == '__main__':
    main()
