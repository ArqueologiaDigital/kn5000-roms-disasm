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
# historical slice labels that no other file uses and that the typed C
# renames (FontPalette_Gradient0..6 are the seven quantize maps)
RENAMED_OK = {'FontPalette_Gradient%d' % k for k in range(7)}
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
    assert pieces[0][1] == off, pieces[0]
    assert pieces[0][0] == label or label in RENAMED_OK, (label, pieces[0])
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


def restructure_seq_rodata(lines, cb):
    """Split the 11 historical slices over +0x13618..+0x1B1E4 into one
    labelled slice per object typed by naka_seq_rodata.py."""
    import naka_seq_rodata as SR
    if 'QuantizeMap_Grid8:' in lines:
        return 0
    blob = 'naka_widget_descriptors'
    mem = [mb for mb in cb.members if SR.LO <= mb.offset < SR.HI]
    old = []
    for j in range(len(lines) - 1):
        m = INCBIN_RE.match(lines[j + 1])
        if lines[j].endswith(':') and m and m.group(1) == blob:
            o, n = int(m.group(2), 0), int(m.group(3), 0)
            if SR.LO <= o < SR.HI:
                old.append((lines[j][:-1], o, n))
    assert sum(n for _, _, n in old) == SR.HI - SR.LO, old
    count = 0
    for label, o, n in old:
        pieces = [[mb.name, mb.offset, mb.size] for mb in mem if o <= mb.offset < o + n]
        split_slices(lines, blob, label, pieces)
        count += len(pieces)
    return count


SHORT = '; [naka_s_headers:short] '


def short_headers(lines, blob, items):
    """items: [(label, [text lines])].  Put a compact header (marker line +
    text) directly above each label; a re-run replaces its own block."""
    n = 0
    for label, text in items:
        idx = [i for i, l in enumerate(lines) if l == label + ':']
        if len(idx) != 1:
            raise SystemExit('short header: label %s found %d times' % (label, len(idx)))
        i = idx[0]
        j = i
        while j > 0 and lines[j - 1].startswith(';') and not lines[j - 1].startswith(SHORT):
            j -= 1
        if j > 0 and lines[j - 1] == SHORT + label:
            del lines[j - 1:i]
            i = j - 1
        block = [SHORT + label] + ['; ' + t for t in text]
        block = [re.sub(r'0x[0-9A-Fa-f]+', lambda m: m.group(0).lower(), b) for b in block]
        lines[i:i] = block
        n += 1
    return n


def effect_and_name_headers(data):
    """The 128 effect-name slices (NakaInst_<EFFECT>, 18 bytes each, blob
    +0x1E1A..+0x271A) and the 61 MIDI-menu procedure-name slices after
    MidiMenu_ApFunctionNameTable: one short evidence header each."""
    base = 0xE30E60
    sl = R.s_slices(os.path.join(ROOT, R.UI, 'widget_descriptors.s'), 'naka_widget_descriptors')
    byoff = {v[0]: k for k, v in sl.items()}
    items = []
    for n in range(128):
        off = 0x2708 - 18 * n
        lab = byoff.get(off)
        if lab is None:
            continue
        name = data[off:off + 16].decode('latin-1')
        items.append((lab, R.wrap(
            'Effect %d name, 18 bytes ("%s", NUL, 0xFF): DspEffectName_PtrTable entry %d '
            'points here, and %s Strcpy\'s it (the effect-number -> name table is described in '
            'the file header).' % (n, name.rstrip(), n, R.a('DspItem0_DisplayEffectName'))).split('\n')))
    u32 = lambda o: int.from_bytes(data[o:o + 4], 'little')
    tab = 0x244A4
    for k in range(61):
        t = u32(tab + 4 * k) - base
        lab = byoff.get(t)
        if lab is None:
            continue
        nm = data[t:data.index(b'\0', t)].decode('latin-1')
        items.append((lab, R.wrap(
            'Name string of MIDI-menu procedure %d ("%s"): entry %d of '
            'MidiMenu_ApFunctionNameTable, which %s registers with RegObjTabl 0x1600002, '
            'ApFunctionProc, 0x3C, 0xE55304, 0x423.%s'
            % (k, nm, k, R.a('InitializeEast'),
               ' This empty name is the table\'s terminator.' if k == 60 else '')).split('\n')))
    return items


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
    import naka_seq_rodata as SR
    for mb in cb.members:
        if SR.LO <= mb.offset < SR.HI:
            from_c.append(dict(kind='c', blob='naka_widget_descriptors', label=mb.name,
                               header=c_header(cb, mb.name),
                               typed='Typed in naka_widget_descriptors.c as %s %s%s.'
                                     % (mb.ctype, mb.name, mb.dims)))
    byfile.setdefault('widget_descriptors.s', []).extend(from_c)
    # naka_span.py spans: partition, slicing and headers come from the span
    import naka_span as NS
    span_objs = {}
    for span, sp in NS.SPANS.items():
        scb = M.CBlob(os.path.join(ROOT, R.UI, sp['blob'] + '.c'))
        sdata = open(os.path.join(ROOT, R.GEN, sp['blob'] + '.bin'), 'rb').read()
        objs = NS.build(span, scb, sdata, R.fmt)
        span_objs[span] = (objs, NS.symbolic_longs(span, scb, sdata, objs))
        for off, size, name, ctype, dims, hdr, kind in objs:
            byfile.setdefault(sp['sfile'], []).append(dict(
                kind='c', blob=sp['blob'], label=name, header=R.wrap(hdr),
                typed=('Typed in %s.c as uint32_t %s%s and char %s_Names[].'
                       % (sp['blob'], name, dims, name)) if kind == 'classprops' else
                      ('Typed in %s.c as %s %s%s.' % (sp['blob'], ctype, name, dims))))
    for v in ('v10', 'v9', 'v7'):
        for span, sp in NS.SPANS.items():
            path = os.path.join(ROOT, v, 'maincpu/ui_widgets', sp['sfile'])
            raw = open(path, 'rb').read()
            lines = raw.decode('latin-1').split('\n')
            objs, longs = span_objs[span]
            present = set(l[:-1] for l in lines if l.endswith(':'))
            if all(o[2] in present for o in objs):
                continue      # this span is already sliced
            n = NS.s_restructure(span, lines, objs, sp['blob'], longs)
            if args.apply:
                open(path, 'wb').write('\n'.join(lines).encode('latin-1'))
            print('%-4s %-26s span %s: %d slices%s' % (v, sp['sfile'], span, n,
                                                       '' if args.apply else '  (dry run)'))
    short_items = effect_and_name_headers(data)
    for v in ('v10', 'v9', 'v7'):
        path = os.path.join(ROOT, v, 'maincpu/ui_widgets', 'widget_descriptors.s')
        raw = open(path, 'rb').read()
        lines = raw.decode('latin-1').split('\n')
        n = short_headers(lines, 'naka_widget_descriptors', short_items)
        out = '\n'.join(lines).encode('latin-1')
        if args.apply and out != raw:
            open(path, 'wb').write(out)
        print('%-4s %-26s %3d short headers  %+d bytes%s' % (v, 'widget_descriptors.s', n,
                                                          len(out) - len(raw),
                                                          '' if args.apply else '  (dry run)'))
    for v in ('v10', 'v9', 'v7'):
        for sname, objs in sorted(byfile.items()):
            path = os.path.join(ROOT, v, 'maincpu/ui_widgets', sname)
            if sname == 'widget_descriptors.s':
                raw = open(path, 'rb').read()
                lines = raw.decode('latin-1').split('\n')
                n = restructure_descriptors(lines, cb, data)
                n += restructure_seq_rodata(lines, cb)
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
