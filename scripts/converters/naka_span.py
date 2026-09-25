#!/usr/bin/env python3
r"""naka_span.py -- partition a span of a NAKA blob into typed, evidenced objects.

QUESTION ANSWERED
-----------------
What is each object inside a span of `naka_widget_tables_1.c`,
`naka_widget_tables_2.c` or `naka_widget_descriptors.c`, and who reads it?
Three independent kinds of evidence are combined, strongest first:

1. The OBJECT REGISTRY.  Every `RegObjTabl` / `RegObjTable` call in the v10
   sources registers a table with the UI object system:

       RegObjTabl class, proc, count, table, base_id   -> RegisterObjectTable
       RegObjTable class, proc, &count, table, base_id  (count read from ROM)

   (macro bodies: display/scoop_display.s).  A table registered in the span
   is typed as `uint32_t [count]`, plus the terminator that follows it
   (a 0, or for the name tables a pointer to ""), and the strings a name
   table points at inside the span become one string block.  Classes:
   0x1600010 ViewableProc (widget records), 0x160000F ResNameProc (resource
   names), 0x1600003 MainFunctionProc, 0x1600002 ApFunctionProc, 0x1600001
   FunctionProc (procedures -- the id|0x400 twin is their name table),
   0x1600004 ClassProc, 0x160000C ResEventProc, 0x160000D ResMethodProc.
2. CODE REFERENCES through the span's slice labels and the positional
   labels anchored on them (the shapes naka_seq_rodata.py classifies:
   switch case tables, local-array initializers, procedure tables, lookups).
3. The BYTES, only to type what 1 and 2 bound: a run that is exactly a
   sequence of NUL-terminated strings (with ALIGNED_STRING's 0xFF pad)
   becomes a string block.

Whatever none of the three reaches stays as an explicit `_Tail` object whose
header says what was searched and that its content is not established.

Labels that other files use (a slice label named outside the lane's three
.s files -- positional_labels.s above all) are kept at their offsets.

RUN
    python3 scripts/converters/naka_span.py SPAN [-v]     # print the partition
    SPAN: t1 (all of naka_widget_tables_1)
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'scripts', 'analysis'))
import naka_seq_rodata as SR  # noqa: E402  (classify, _fmt_vals)

CLASSES = {0x1600010: ('ViewableProc', 'View', 'pointers to widget records'),
           0x160000F: ('ResNameProc', 'ResName', 'pointers to resource-name strings'),
           0x1600003: ('MainFunctionProc', 'MainFunc', None),
           0x1600002: ('ApFunctionProc', 'ApFunc', None),
           0x1600001: ('FunctionProc', 'Func', None),
           0x1600004: ('ClassProc', 'Class', 'pointers to class records'),
           0x160000C: ('ResEventProc', 'ResEvent', None),
           0x160000D: ('ResMethodProc', 'ResMethod', None)}
OWN = ('ui_widgets/widget_descriptors.s', 'ui_widgets/naka_widget_tables_1.s',
       'ui_widgets/naka_widget_tables_2.s')

def _midimenu_names(data):
    """Manual objects for the 61 strings MidiMenu_ApFunctionNameTable
    (blob +0x244A4, 61 u32) points at, named by the .s labels they already
    have."""
    base = 0xE30E60
    sl = slices(os.path.join(ROOT, 'v10/maincpu/ui_widgets/widget_descriptors.s'),
                'naka_widget_descriptors')
    byoff = {v[0]: k for k, v in sl.items()}
    out = {}
    for k in range(61):
        t = int.from_bytes(data[0x244A4 + 4 * k:0x244A8 + 4 * k], 'little') - base
        ln = string_run_one(data, t, len(data))
        nm = data[t:data.index(b'\0', t)].decode('latin-1')
        out[t] = (ln, byoff[t], 'char', '[%d]' % ln,
                  'name string of MIDI-menu procedure %d ("%s"): entry %d of '
                  'MidiMenu_ApFunctionNameTable, registered by {InitializeEast} with '
                  'RegObjTabl 0x1600002, ApFunctionProc, 0x3C, 0xE55304, 0x423%s.'
                  % (k, nm, k, '; this empty name is the terminator' if k == 60 else ''))
    return out


SPANS = {
    't1': dict(blob='naka_widget_tables_1', sfile='naka_widget_tables_1.s',
               base=0xE24056, lo=0x0, hi=0x324E, manual={}),
    # naka_widget_tables_2 around the bitmaps typed by naka_c_retype.OBJECTS
    't2a': dict(blob='naka_widget_tables_2', sfile='naka_widget_tables_2.s',
                base=0xE5A39E, lo=0x0, hi=0xAAC, manual={}),
    # naka_widget_descriptors: the UI-string zone after the effect names
    # (the effect-name block itself stays hand-carved) and the class data
    # after the MIDI-menu ApFunction names
    'd_ui': dict(blob='naka_widget_descriptors', sfile='widget_descriptors.s',
                 base=0xE30E60, lo=0x271A, hi=0x4018, manual={}),
    'd_mem': dict(blob='naka_widget_descriptors', sfile='widget_descriptors.s',
                  base=0xE30E60, lo=0x1B1E4, hi=0x1B272, manual={
        0x1B1E4: (14, 'NakaInst_MEMORY_C', 'char', '[14]',
                  '" MEMORY-C " (14 bytes with NUL and pad): entry 2 of '
                  'MainCmpCpFunc_LocalInit, the three string pointers {MainCmpCpFunc} '
                  'copies into its stack frame.'),
        0x1B1F2: (14, 'NakaInst_MEMORY_B', 'char', '[14]',
                  '" MEMORY-B ": entry 1 of MainCmpCpFunc_LocalInit ({MainCmpCpFunc}).'),
        0x1B200: (14, 'NakaInst_MEMORY_A', 'char', '[14]',
                  '" MEMORY-A ": entry 0 of MainCmpCpFunc_LocalInit ({MainCmpCpFunc}).  '
                  'The label also anchors the positional labels NakaInst_MEMORY_A_0xE .. '
                  '_0x5E that the switch tables below are reached through.'),
        0x1B262: (4, 'NakaInst_DashDash', 'char', '[4]',
                  '"-- ": the string the one-entry table before it points at '
                  '({SndArgNmGet} copies that pointer to its frame).'),
        0x1B26E: (4, 'NakaInst_ON_Str', 'char', '[4]',
                  '"ON ": entry 1 of the {OFF, ON} pointer pair just before it, which '
                  '{SndArgNmGet} copies to its frame (NakaInst_OFF_Str follows).'),
    }),
    'd_names': dict(blob='naka_widget_descriptors', sfile='widget_descriptors.s',
                    base=0xE30E60, lo=0x24598, hi=0x248FC, manual={},
                    manual_fn=_midimenu_names),
    'd_cls': dict(blob='naka_widget_descriptors', sfile='widget_descriptors.s',
                  base=0xE30E60, lo=0x248FC, hi=0x24D68, manual={}),
    't2b': dict(blob='naka_widget_tables_2', sfile='naka_widget_tables_2.s',
                base=0xE5A39E, lo=0x24954, hi=0x26C44, manual={
        0x25444: (52, 'SplitPoint_BitmapTable', 'uint32_t', '[13]',
                  'the 13 keyboard-octave bitmaps of the split-point display: entry 0 = '
                  'Bitmap_SplitPoint_no_split, entries 1..12 = Bitmap_SplitPoint_C .. '
                  'Bitmap_SplitPoint_B.  {SplitPointFunc} reads entry 1 + (split note mod '
                  '12) through SplitPoint_NoteEntry_C_Code+4 (`lda xde,...; ld xbc,'
                  '(xde+bc)`), with bc = (note mod 12) * 4.'),
    }),
}


def _rom():
    return open(os.path.join(ROOT, 'original_ROMs/kn5000_v10_program.rom'), 'rb').read()


def _nm():
    import naka_c_retype as NR
    return NR._nm('v10')


def sources():
    import nakabig_rodata_refs as RR
    return RR.load_sources('v10')


def registry(srcs):
    """All RegObjTabl/RegObjTable calls: dicts with file, line, routine,
    cls, proc, count, table (absolute), base_id."""
    nm = {k: int(v, 16) for k, v in _nm().items()}
    rom = _rom()
    u16 = lambda a: int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + 2], 'little')

    def val(x):
        try:
            return int(x, 0)
        except ValueError:
            return nm.get(x)
    out = []
    for rel, lines in srcs:
        routine = None
        for i, ln in enumerate(lines):
            m = re.match(r'^([A-Za-z_]\w*):', ln)
            if m:
                routine = m.group(1)
            m = re.match(r'\s*(RegObjTable?)\s+(\S+),\s*(\S+),\s*(\S+),\s*(\S+),\s*(\S+)\s*$',
                         ln.split(';')[0])
            if not m:
                continue
            kind, cls, proc, cnt, tab, bid = m.groups()
            t = val(tab)
            if t is None:
                continue
            c = val(cnt) if kind == 'RegObjTabl' else u16(val(cnt))
            out.append(dict(file=rel, line=i + 1, routine=routine, kind=kind,
                            cls=int(cls, 0), proc=proc, count=c, count_src=cnt,
                            table=t, id=int(bid, 0)))
    return out


def class_map(regs):
    """class id -> (name, record_size) from every ClassProc table."""
    rom = _rom()
    u = lambda a, n: int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + n], 'little')
    out = {}
    for r in regs:
        if r['cls'] != 0x1600004 or r['count'] is None:
            continue
        for k in range(r['count']):
            d = r['table'] + 24 * k
            nm_ = rom[u(d + 12, 4) - 0xE00000:u(d + 12, 4) - 0xE00000 + 40].split(b'\0')[0]
            out[r['id'] << 16 | k] = (nm_.decode('latin-1'), u(d + 8, 2))
    return out


def slices(sfile, blob):
    import naka_c_retype as NR
    return NR.s_slices(sfile, blob)


def external_labels(srcs, names):
    """Slice labels that some file other than the lane's own names."""
    rx = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, names), key=len, reverse=True)) + r')\b')
    used = set()
    for rel, lines in srcs:
        if rel in OWN:
            continue
        for ln in lines:
            for m in rx.finditer(ln.split(';')[0]):
                used.add(m.group(1))
    return used


def span_refs(srcs, anchors, lo, hi):
    """offset -> [(file, line, routine, instr, after, before)], via the slice
    labels in `anchors` and positional labels anchored on them."""
    import nakabig_rodata_refs as RR
    pos = {}
    for rel, lines in srcs:
        for ln in lines:
            m = re.match(r'\s*\.set (\w+), (\w+) \+ (\d+)\s*$', ln)
            if m and m.group(2) in anchors:
                pos[m.group(1)] = anchors[m.group(2)] + int(m.group(3))
    names = dict(pos)
    names.update(anchors)
    rx = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, names), key=len, reverse=True)) + r')\b')
    out = {}
    for rel, lines in srcs:
        if rel in OWN or rel == 'shared/positional_labels.s':
            continue
        routine = None
        for i, ln in enumerate(lines):
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
            if m and not RR.LOCAL.search(m.group(1)):
                routine = m.group(1)
            code = ln.split(';')[0]
            if re.match(r'\s*RegObjTable?\s', code):
                continue            # registrations are handled as registry objects
            for mm in rx.finditer(code):
                off = names[mm.group(1)]
                if lo <= off < hi:
                    cl = lambda s: ' '.join(s.split(';')[0].split())
                    out.setdefault(off, []).append(
                        (rel, i + 1, routine, cl(code),
                         [cl(x) for x in lines[i + 1:i + 9]],
                         [cl(x) for x in lines[max(0, i - 10):i]]))
    return out


def string_run(data, o, end, allow_high=False):
    """Length of the longest run starting at o of printable NUL-terminated
    strings (with the 0xFF pad ALIGNED_STRING adds after an odd-length
    one), or 0.  Stops at `end`."""
    i = o
    while i < end:
        j = i
        while j < end and (0x20 <= data[j] < 0x7F or (allow_high and 0x80 <= data[j] < 0xFF)):
            j += 1
        if j >= end or data[j] != 0:
            break
        j += 1
        if j < end and data[j] == 0xFF and (j - i) % 2:
            j += 1
        i = j
    return i - o


def string_run_one(data, o, end, allow_high=False):
    """Length of the single aligned string at o (with its pad), or 0."""
    j = o
    while j < end and (0x20 <= data[j] < 0x7F or (allow_high and 0x80 <= data[j] < 0xFF)):
        j += 1
    if j >= end or data[j] != 0:
        return 0
    j += 1
    if j < end and data[j] == 0xFF and (j - o) % 2:
        j += 1
    return j - o


def ptr_prefix(data, o, end):
    """Number of leading u32 in [o, end) that are 0 or a ROM address."""
    n = 0
    while o + 4 * (n + 1) <= end:
        v = int.from_bytes(data[o + 4 * n:o + 4 * n + 4], 'little')
        if not (v == 0 or 0xE00000 <= v < 0x1000000):
            break
        n += 1
    return n


def c_strings(bs):
    """C initializer (concatenated literals, one string per line) for a block
    of NUL-terminated strings; the implicit final NUL is dropped by the
    array size."""
    import naka_c_model as M
    parts, i = [], 0
    while i < len(bs):
        j = bs.index(b'\0', i)
        k = j + 1
        pad = k < len(bs) and bs[k] == 0xFF
        lit = M.c_string(bs[i:j])
        parts.append(lit[:-1] + '\\0' + ('\\xFF' if pad else '') + '"')
        i = k + (1 if pad else 0)
    parts[-1] = parts[-1].replace('\\0"', '"') if parts[-1].endswith('\\0"') else parts[-1]
    return '\n'.join('        ' + p for p in parts)


INNER = {}     # span -> [(label, offset)] externally used labels inside objects


def build(span, cb, data, fmt, srcs=None):
    """-> list of (off, size, name, ctype, dims, header, expr_or_None)."""
    sp = SPANS[span]
    lo, hi, base = sp['lo'], sp['hi'], sp['base']
    srcs = srcs or sources()
    sl = slices(os.path.join(ROOT, 'v10/maincpu/ui_widgets', sp['sfile']), sp['blob'])
    anchors = {k: v[0] for k, v in sl.items()}
    # labels this lane re-expressed as `.set L, Obj + d` inside the span file
    for ln in open(os.path.join(ROOT, 'v10/maincpu/ui_widgets', sp['sfile']),
                   encoding='latin-1'):
        m = re.match(r'\s*\.set (\w+), (\w+) \+ (\d+)', ln)
        if m and m.group(2) in anchors:
            anchors[m.group(1)] = anchors[m.group(2)] + int(m.group(3))
    ext = external_labels(srcs, list(anchors))
    refs = span_refs(srcs, anchors, lo, hi)
    symolds = old_u32_exprs(cb, lo, hi)
    regs = [r for r in registry(srcs) if base + lo <= r['table'] < base + hi]
    u32 = lambda o: int.from_bytes(data[o:o + 4], 'little')
    objs = {}          # off -> dict(size, name, ctype, dims, text, expr, kind)

    def short(routine):
        return re.sub(r'^Initialize', '', routine or 'Unknown')

    # --- 1. registry tables and the name blocks they point at
    for r in regs:
        o = r['table'] - base
        n = r['count']
        cname, cshort, what = CLASSES.get(r['cls'], ('0x%X' % r['cls'], 'Obj', None))
        isname = r['id'] & 0x400 and r['cls'] in (0x1600001, 0x1600002, 0x1600003)
        kind = ('%sNameTable' % cshort) if isname else ('%sTable' % cshort)
        name = '%s_%s_%03X' % (short(r['routine']), kind, r['id'])
        term = 0
        if o + 4 * n + 4 <= hi:
            t = u32(o + 4 * n)
            if t == 0:
                term = 1
            elif base <= t < base + len(data) and data[t - base] == 0:
                term = 1        # pointer to "" closes a name table
        size = 4 * (n + term)
        if r['cls'] == 0x1600004:
            # ClassProc tables hold 24-byte class descriptors, not pointers
            nfull = min(n, (hi - o) // 24)
            size = 24 * nfull
            text = ('%s -- class table: {%s} (%s:%d) registers it with `%s` -- %d '
                    'naka_class_t descriptors (naka_types.h: proc, base class, two u16, '
                    'name, field-type letters, property data), %d of them inside this blob%s.'
                    % (name, r['routine'], r['file'], r['line'],
                       'RegObjTable %s, %s, (count at %s = %d), 0x%06X, 0x%X'
                       % (hex(r['cls']), r['proc'], r['count_src'], n, r['table'], r['id']),
                       n, nfull, '' if nfull == n else
                       '; the table runs on into the next blob, and the %d bytes left here '
                       'begin descriptor %d' % (hi - o - size, nfull)))
            objs[o] = dict(size=size, name=name, ctype='naka_class_t', dims='[%d]' % nfull,
                           text=text, kind='registry', reg=r)
            if nfull < n and size < hi - o:
                objs[o + size] = dict(size=hi - o - size, name=name + '_Desc%dHead' % nfull,
                                      ctype='uint32_t', dims='[1]',
                                      text=('%s_Desc%dHead -- the first u32 (proc) of '
                                            'descriptor %d of %s; the rest of that table is '
                                            'in the next blob.' % (name, nfull, nfull, name)),
                                      kind='manual')
            # the property blocks the descriptors point at (all of them, also
            # descriptors that lie beyond this blob)
            rom = _rom()
            ru32 = lambda a: int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + 4], 'little')
            rcs = lambda a: rom[a - 0xE00000:a - 0xE00000 + 40].split(b'\0')[0].decode('latin-1')
            recs = [r['table'] + 24 * k for k in range(n)]
            props = sorted(set(ru32(x + 20) - base for x in recs))
            inside = [q for q in props if lo <= q < hi]
            # the class-name and signature strings the descriptors point at
            nt = sorted(set(t for x in recs for t in (ru32(x + 12) - base, ru32(x + 16) - base)
                            if lo <= t < hi))
            if nt:
                s0, last = nt[0], nt[-1]
                ln_last = string_run_one(data, last, hi, True)
                ln = (last + ln_last) - s0 if ln_last else 0
                if ln and string_run(data, s0, s0 + ln, True) == ln:
                    objs[s0] = dict(size=ln, name=name + '_Names', ctype='char',
                                    dims='[%d]' % ln, kind='strings',
                                    text=('%s_Names -- the class names and field-type '
                                          'signature strings that the descriptors of %s point '
                                          'at (+0x0C name, +0x10 sig): %d strings, %d bytes.'
                                          % (name, name, len(nt), ln)))
            for q in inside:
                rec = next(x for x in recs if ru32(x + 20) - base == q)
                k = (rec - r['table']) // 24
                cls = rcs(ru32(rec + 12))
                sig = rcs(ru32(rec + 16))
                nxt_q = min([z for z in props if z > q] + [o])
                np_ = len(sig) + 1
                names = [rcs(ru32(base + q + 4 * i)) for i in range(len(sig))]
                objs[q] = dict(size=nxt_q - q, name='ClassProps_%s' % cls, ctype=None,
                               dims=None, kind='classprops', nptr=np_,
                               text=('ClassProps_%s -- property names of class %s '
                                     '(descriptor %d of %s, whose +0x14 points here): %d '
                                     'pointers, one per letter of its signature "%s" -- %s -- '
                                     'then a pointer to "", then the names themselves.'
                                     % (cls, cls, k, name, len(sig), sig,
                                        ', '.join('"%s"' % x for x in names) or 'none')))
            continue
        if what is None:
            what = ('procedure addresses' if not isname and r['cls'] != 0x1600004 else
                    'pointers to the procedures\' name strings' if isname else 'entries')
        how = ('RegObjTable %s, %s, (count at %s = %d), 0x%06X, 0x%X'
               % (hex(r['cls']), r['proc'], r['count_src'], n, r['table'], r['id'])
               if r['kind'] == 'RegObjTable' else
               'RegObjTabl %s, %s, %d, 0x%06X, 0x%X' % (hex(r['cls']), r['proc'], n,
                                                         r['table'], r['id']))
        text = ('%s -- object table: {%s} (%s:%d) registers it with `%s` -- '
                'class %s (%s), %d objects, base id 0x%X.  Entries: %s%s.'
                % (name, r['routine'], r['file'], r['line'], how, hex(r['cls']), cname, n,
                   r['id'], what, ' then a %s terminator' % ('0' if u32(o + 4 * n) == 0 else '""')
                   if term else ''))
        objs[o] = dict(size=size, name=name, ctype='uint32_t', dims='[%d]' % (n + term),
                       text=text, kind='registry', reg=r)
        # the strings it points at, when they sit together inside the span
        tg = sorted(set(u32(o + 4 * k) - base for k in range(n + term)))
        tg = [t for t in tg if lo <= t < hi]
        if (r['cls'] == 0x160000F or isname) and tg:
            s0 = tg[0]
            last = tg[-1]
            ln_last = string_run_one(data, last, hi, True)
            ln = (last + ln_last) - s0 if ln_last else 0
            if ln and string_run(data, s0, s0 + ln, True) == ln:
                bname = name.replace('Table', 's')
                objs[s0] = dict(size=ln, name=bname, ctype='char', dims='[%d]' % ln,
                                text=('%s -- the strings %s points at: %d NUL-terminated '
                                      'names (0xFF pads to even length), %d bytes.'
                                      % (bname, name, len(tg), ln)),
                                kind='strings')
    # --- 1b. strings / records that tables registered ELSEWHERE point at
    allregs = registry(srcs)
    for r in allregs:
        if base + lo <= r['table'] < base + hi or r['count'] is None or r['count'] > 4096 \
                or r['cls'] == 0x1600004:          # ClassProc tables hold records
            continue
        o_tab = r['table']
        rom = _rom()
        tg = []
        for k in range(r['count']):
            a = o_tab + 4 * k
            t = int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + 4], 'little') - base
            if lo <= t < hi:
                tg.append(t)
        tg = sorted(set(t for t in tg if not any(p <= t < p + (w['size'] or 1)
                                                  for p, w in objs.items())))
        if not tg:
            continue
        cname, cshort, what = CLASSES.get(r['cls'], ('0x%X' % r['cls'], 'Obj', None))
        tname = '%s_%s%s_%03X' % (short(r['routine']), cshort,
                                  'NameTable' if (r['id'] & 0x400 and r['cls'] in
                                                  (0x1600001, 0x1600002, 0x1600003)) else 'Table',
                                  r['id'])
        s0, last = tg[0], tg[-1]
        ln_last = string_run_one(data, last, hi, True)
        ln = (last + ln_last) - s0 if ln_last else 0
        if ln and string_run(data, s0, s0 + ln, True) == ln and \
                not any(s0 < p < s0 + ln for p in objs):
            bname = tname.replace('Table', 's')
            objs[s0] = dict(size=ln, name=bname, ctype='char', dims='[%d]' % ln,
                            text=('%s -- the %d strings that %s (registered by {%s}, %s:%d, '
                                  'table at 0x%06X outside this blob) points at: '
                                  'NUL-terminated, 0xFF pad to even length, %d bytes.'
                                  % (bname, len(tg), tname, r['routine'], r['file'],
                                     r['line'], r['table'], ln)),
                            kind='strings')
    # --- 1c. widget records that ViewableProc tables (anywhere) point at:
    # the record begins with its class id (table id << 16 | index) and is
    # record_size bytes long (scripts/analysis/naka_class_descriptors.py)
    classes = class_map(allregs)
    for r in allregs:
        if r['cls'] != 0x1600010 or r['count'] is None:
            continue
        rom = _rom()
        tname = '%s_ViewTable_%03X' % (short(r['routine']), r['id'])
        for k in range(r['count']):
            a = r['table'] + 4 * k
            t = int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + 4], 'little') - base
            if not (lo <= t < hi) or t in objs:
                continue
            cid = u32(t)
            if cid not in classes:
                continue
            cname, rsize = classes[cid]
            objs[t] = dict(size=rsize, name='%s_Rec%d' % (tname, k), ctype='uint8_t',
                           dims='[%d]' % rsize, kind='manual',
                           text=('%s_Rec%d -- widget record, entry %d of %s (registered by '
                                 '{%s}, %s:%d): it begins with class id 0x%07X = %s, whose '
                                 'descriptor gives record_size %d.'
                                 % (tname, k, k, tname, r['routine'], r['file'], r['line'],
                                    cid, cname, rsize)))
    # --- 2. manual
    manual = dict(sp['manual'])
    if sp.get('manual_fn'):
        manual.update(sp['manual_fn'](data))
    for o, (size, name, ctype, dims, text) in manual.items():
        objs[o] = dict(size=size, name=name, ctype=ctype, dims=dims,
                       text='%s -- %s' % (name, text), kind='manual')
    # --- 3. code references
    for o in sorted(refs):
        if any(p <= o < p + (v['size'] or 1) for p, v in objs.items()):
            continue
        kind, info = SR.classify(refs[o])
        nsym = 0
        while o + 4 * nsym in symolds and (nsym == 0 or (o + 4 * nsym not in refs and
                                                         o + 4 * nsym not in objs)):
            nsym += 1
        if nsym:
            # ... and on over plain ROM addresses the generator left numeric
            while o + 4 * (nsym + 1) <= hi and o + 4 * nsym not in refs and \
                    o + 4 * nsym not in objs and \
                    0xE00000 <= u32(o + 4 * nsym) < 0x1000000:
                nsym += 1
            # the generator (or a previous pass) already resolved these words to
            # symbols: a pointer table, whatever the reader's shape suggests
            objs[o] = dict(size=4 * nsym, kind='ref:ptrs', info=info, refs=refs[o])
            continue
        objs[o] = dict(size=None, kind='ref:' + kind, info=info, refs=refs[o])
    # --- 3b. strings that the span's own pointer tables point at
    for o in sorted(list(objs)):
        v = objs[o]
        if v['kind'] not in ('ref:lookup', 'ref:procs', 'ref:ptrs'):
            continue
        nxt_ = min([p for p in objs if p > o] + [hi])
        npt = ptr_prefix(data, o, nxt_)
        if npt < 2:
            continue
        tg = sorted(set(u32(o + 4 * k) - base for k in range(npt)))
        tg = [t for t in tg if lo <= t < hi and t not in objs and
              not any(p <= t < p + (w['size'] or 1) for p, w in objs.items())]
        if not tg:
            continue
        s0, last = tg[0], tg[-1]
        ln_last = string_run_one(data, last, hi, True)
        ln = (last + ln_last) - s0 if ln_last else 0
        if ln and string_run(data, s0, s0 + ln, True) == ln and \
                not any(s0 < p < s0 + ln for p in objs):
            objs[s0] = dict(size=ln, name=None, ctype='char', dims='[%d]' % ln,
                            text=None, kind='targets', owner=o, count=len(tg))
    # --- 4. externally used labels must start an object
    for lab in ext:
        o = anchors[lab]
        if lo <= o < hi and not any(p <= o < p + (v['size'] or 1) for p, v in objs.items()):
            objs[o] = dict(size=None, kind='label', label=lab)
    # --- tile
    out = []
    starts = sorted(objs)
    cur = lo
    used = {}

    def uniq(nm):
        used[nm] = used.get(nm, 0) + 1
        return nm if used[nm] == 1 else '%s_%d' % (nm, used[nm])
    lab_at = {v[0]: k for k, v in sl.items()}
    while cur < hi:
        nxt = min([s for s in starts if s > cur] + [hi])
        ext_len = nxt - cur
        ob = objs.get(cur)
        if ob is None:
            # untouched bytes: a string block if they are exactly strings, else a tail
            ln = string_run(data, cur, nxt)
            lab = lab_at.get(cur)
            prev = out[-1][2] if out else None
            prefix = {'naka_widget_tables_1': 'NakaT1', 'naka_widget_tables_2': 'NakaT2',
                      'naka_widget_descriptors': 'NakaDesc'}[sp['blob']]
            if isinstance(prev, tuple):
                stem, where = '%s_Str%05X' % (prefix, cur), 'after the string block before it'
            elif prev:
                stem, where = re.sub(r'_(Tail|Strings)(_\d+)?$', '', prev), 'after ' + prev
            else:
                stem, where = prefix, 'at the start of the blob'
            if ln == ext_len:
                name = uniq(lab or (stem if stem.startswith(prefix + '_Str') else stem + '_Strings'))
                out.append((cur, ext_len, name, 'char', '[%d]' % ext_len,
                            '%s -- %d bytes of NUL-terminated strings %s; no registration '
                            'or code reference reaches them (searched: RegObjTabl tables, '
                            'slice and positional labels).  Which code uses them is not '
                            'established.' % (name, ext_len, where), 'strings'))
            else:
                name = uniq(lab or stem + '_Tail')
                out.append((cur, ext_len, name, 'uint8_t', '[%d]' % ext_len,
                            '%s -- %d bytes %s that no registration or code reference '
                            'reaches (searched: RegObjTabl tables, slice and positional '
                            'labels).  Contents not established.' % (name, ext_len, where),
                            'tail'))
            cur = nxt
            continue
        k = ob['kind']
        if k == 'targets':
            out.append((cur, ob['size'], ('@targets', ob['owner'], ob['count']), 'char',
                        ob['dims'], None, 'strings'))
            cur += ob['size']
            continue
        if k in ('registry', 'strings', 'manual', 'classprops'):
            size = min(ob['size'], ext_len) if k == 'strings' else ob['size']
            name = ob['name']
            if cur in lab_at and (lab_at[cur] in ext or '_Rec' in name):
                name = lab_at[cur]
            if name != ob['name']:
                ob = dict(ob, text=ob['text'].replace(ob['name'] + ' --', name + ' --', 1))
            if k == 'classprops':
                out.append((cur, size, name, 'classprops', '[%d]' % ob['nptr'],
                            fmt(ob['text']), k))
            else:
                out.append((cur, size, name, ob['ctype'], ob['dims'] if size == ob['size']
                            else '[%d]' % size, fmt(ob['text']), k))
            cur += size
            continue
        if k == 'label':
            # an externally used label with no other evidence: keep its name,
            # extent to the next start
            lab = ob['label']
            out.append((cur, ext_len, lab, 'uint8_t', '[%d]' % ext_len,
                        '%s -- label kept because other files use it; %d bytes to the '
                        'next object.  Contents not established.' % (lab, ext_len), 'tail'))
            cur = nxt
            continue
        # code-referenced object: reuse naka_seq_rodata's shapes
        rs = ob['refs']
        rel, n, routine, ins, after, before = rs[0]
        rd = []
        for x in rs:
            s_ = '{%s} (`%s`)' % (x[2], x[3])
            if s_ not in rd:
                rd.append(s_)
        kind, info = SR.classify(rs)
        size, ctype, dims = ext_len, 'uint8_t', '[%d]' % ext_len
        ln = string_run(data, cur, nxt)
        if ob['kind'] == 'ref:ptrs':
            npt = ob['size'] // 4
            size, ctype, dims = 4 * npt, 'uint32_t', '[%d]' % npt
            name = uniq(lab_at.get(cur) or '%s_PtrTable' % routine)
            txt = ('%d u32 addresses, read by %s.' % (npt, ', '.join(rd)))
        elif kind == 'switch':
            b = info['bound']
            nc = b + 1 if b is not None and 2 * (b + 1) <= ext_len else ext_len // 2
            size, ctype, dims = 2 * nc, 'uint16_t', '[%d]' % nc
            name = uniq('%s_CaseTable' % routine)
            txt = ('jump table of a compiled `switch` in %s: %d u16 case offsets from %s.'
                   % (', '.join(rd), nc, info['base']))
        elif kind == 'local':
            size = min(info['size'] or ext_len, ext_len)
            ctype, dims = ('uint16_t', '[%d]' % (size // 2)) if size % 2 == 0 and size > 2 \
                else ('uint8_t', '[%d]' % size)
            name = uniq('%s_LocalInit' % routine)
            txt = ('initializer of a local array: %s copies %d bytes into its stack frame.'
                   % (', '.join(rd), size))
        elif ptr_prefix(data, cur, nxt) >= 2 and kind in ('lookup', 'procs'):
            npt = ptr_prefix(data, cur, nxt)
            size, ctype, dims = 4 * npt, 'uint32_t', '[%d]' % npt
            name = uniq(lab_at.get(cur) or '%s_PtrTable' % routine)
            txt = ('%d u32 ROM addresses (or 0), read by %s.'
                   % (npt, ', '.join(rd)))
        elif ln and ln == ext_len:
            ctype, dims = 'char', '[%d]' % ln
            name = uniq(lab_at.get(cur) or '%s_Str' % routine)
            txt = ('NUL-terminated string(s), %d bytes, used by %s.' % (ln, ', '.join(rd)))
        else:
            name = uniq(lab_at.get(cur) or '%s_Table' % routine)
            txt = ('read by %s.  %d bytes to the next object; the layout beyond that '
                   'access is not established.' % (', '.join(rd), ext_len))
        if cur in lab_at and lab_at[cur] in ext:
            name = lab_at[cur]
        out.append((cur, size, name, ctype, dims, fmt('%s -- %s' % (name, txt)), 'ref'))
        cur += size
    starts_final = {o[0] for o in out}
    INNER[span] = sorted((lab, anchors[lab]) for lab in ext
                         if lo <= anchors[lab] < hi and anchors[lab] not in starts_final)
    names_at = {o[0]: o[2] for o in out}
    fixed = []
    for o in out:
        if isinstance(o[2], tuple):
            _, owner, cnt = o[2]
            oname = names_at.get(owner, 'a pointer table')
            name = uniq(lab_at.get(o[0]) if lab_at.get(o[0]) in ext else
                        re.sub(r'_PtrTable(_\d+)?$', '', oname) + '_Strings')
            o = (o[0], o[1], name, o[3], o[4],
                 fmt('%s -- the %d strings %s points at (NUL-terminated, 0xFF pad to '
                     'even length), %d bytes.' % (name, cnt, oname, o[1])), o[6])
        fixed.append(o)
    out = fixed
    assert sum(o[1] for o in out) == hi - lo, (sum(o[1] for o in out), hi - lo)
    return out


# ---------------------------------------------------------------------------
# C typing and .s slicing of a span
# ---------------------------------------------------------------------------
def old_u32_exprs(cb, lo, hi):
    """absolute blob offset -> the old source expression of a u32 there
    (scalar, array element, or naka_dispatch_t pointer field)."""
    import naka_c_model as M
    out = {}
    for mb, e in zip(cb.members, cb.entries):
        if not (lo <= mb.offset < hi):
            continue
        if mb.ctype == 'uint32_t':
            if mb.dims:
                for k, x in enumerate(cb.elements(mb.name)):
                    out[mb.offset + 4 * k] = x
            else:
                out[mb.offset] = ' '.join(e.expr.split())
        elif mb.ctype == 'naka_dispatch_t':
            for fld, d in (('name_ptr', 8), ('inst_ptr', 12), ('link_ptr', 16), ('proc_addr', 20)):
                m = re.search(r'\.%s\s*=\s*([^,}]+)' % fld, e.expr)
                if m:
                    out[mb.offset + d] = m.group(1).strip()
    return {k: v for k, v in out.items() if M.SYMBOLIC_RE.search(v)}


def new_members(span, cb, data, fmt, objs=None):
    import naka_c_model as M
    sp = SPANS[span]
    lo, hi = sp['lo'], sp['hi']
    objs = objs or build(span, cb, data, fmt)
    olds = old_u32_exprs(cb, lo, hi)
    u32 = lambda o: int.from_bytes(data[o:o + 4], 'little')
    u16 = lambda o: int.from_bytes(data[o:o + 2], 'little')

    def v32(o):
        return olds.get(o, '0x%08X' % u32(o))
    out = []
    for off, size, name, ctype, dims, hdr, kind in objs:
        pre = M.comment_block(SR.wrap_text(hdr))
        if kind == 'classprops':
            n = int(dims[1:-1])
            ptr_expr = '{\n' + '\n'.join('        %s,' % v32(off + 4 * i) for i in range(n)) + '\n    }'
            out.append(M.NewMember('uint32_t', name, '[%d]' % n, 4 * n, ptr_expr, pre))
            sb = data[off + 4 * n:off + size]
            out.append(M.NewMember('char', name + '_Names', '[%d]' % len(sb), len(sb),
                                   c_strings(sb).lstrip(), []))
            continue
        if ctype == 'naka_class_t':
            n = int(dims[1:-1])
            rows = []
            for i in range(n):
                r = off + 24 * i
                rows.append('        { %s, 0x%08X, %d, %d, %s, %s, %s },'
                            % (v32(r), u32(r + 4), u16(r + 8), u16(r + 10), v32(r + 12),
                               v32(r + 16), v32(r + 20)))
            out.append(M.NewMember(ctype, name, dims, size, '{\n' + '\n'.join(rows) + '\n    }', pre))
            continue
        if ctype == 'char':
            out.append(M.NewMember('char', name, dims, size, c_strings(data[off:off + size]).lstrip(), pre))
            continue
        w = {'uint8_t': 1, 'uint16_t': 2, 'uint32_t': 4}[ctype]
        if ctype == 'uint32_t':
            vals = [v32(off + 4 * i) for i in range(size // 4)]
            vals = [x if M.SYMBOLIC_RE.search(x) else int(x, 0) for x in vals]
            per = 1 if any(isinstance(x, str) for x in vals) else 4
        else:
            vals = [int.from_bytes(data[off + i:off + i + w], 'little') for i in range(0, size, w)]
            per = {1: 16, 2: 8}[w]
        out.append(M.NewMember(ctype, name, dims, size, SR._fmt_vals(vals, dims, w, per), pre))
    reexp = [mb.name for mb in cb.members if lo <= mb.offset < hi and
             M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
    return out, reexp


def symbolic_longs(span, cb, data, objs):
    """offset -> ['sym' | '0x00000000', ...] for procedure tables whose every
    entry is NAKA_ADDR(sym) (or 0), with each symbol checked to hold exactly
    the ROM value at that entry in the v10, v9 and v7 builds."""
    import naka_c_retype as NR
    sp = SPANS[span]
    olds = old_u32_exprs(cb, sp['lo'], sp['hi'])
    roms = {v: open(os.path.join(ROOT, 'original_ROMs/kn5000_%s_program.rom' % v), 'rb').read()
            for v in ('v10', 'v9', 'v7')}
    out = {}
    for off, size, name, ctype, dims, hdr, kind in objs:
        if kind != 'registry' or ctype != 'uint32_t' or 'Func' not in name or 'NameTable' in name:
            continue
        syms = []
        for k in range(size // 4):
            e = olds.get(off + 4 * k)
            if e is None and data[off + 4 * k:off + 4 * k + 4] == b'\0\0\0\0':
                syms.append('0x00000000')
                continue
            m = re.fullmatch(r'NAKA_ADDR\((\w+)\)', e or '')
            if not m:
                syms = None
                break
            sym = m.group(1)
            a = sp['base'] + off + 4 * k - 0xE00000
            for v in roms:
                addr = NR._nm(v).get(sym)
                if addr is None or int(addr, 16) != int.from_bytes(roms[v][a:a + 4], 'little'):
                    syms = None
                    break
            if syms is None:
                break
            syms.append(sym)
        if syms:
            out[off] = syms
    return out


def s_restructure(span, lines, objs, blob, longs=None):
    """Replace every slice of [lo, hi) (and any .long block among them) by one
    labelled .incbin slice per object.  Refuses if anything other than slice
    labels, .incbin and .long lines sits in the replaced range."""
    sp = SPANS[span]
    lo, hi = sp['lo'], sp['hi']
    inc = re.compile(r'^\t\.incbin "includes/generated/%s\.bin", (0x[0-9A-Fa-f]+|\d+), '
                     r'(0x[0-9A-Fa-f]+|\d+)\s*$' % re.escape(blob))
    # a span edge inside a slice splits that slice first
    for edge in (lo, hi):
        for i, ln in enumerate(lines):
            m = inc.match(ln)
            if m:
                o, n = int(m.group(1), 0), int(m.group(2), 0)
                if o < edge < o + n:
                    lines[i:i + 1] = ['\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (blob, o, edge - o),
                                      '__naka_span_edge_%X:' % edge,
                                      '\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (blob, edge, o + n - edge)]
                    break
    first = last = None
    for i, ln in enumerate(lines):
        m = inc.match(ln)
        if m:
            o, n = int(m.group(1), 0), int(m.group(2), 0)
            if o == lo and first is None:
                first = i - 1 if lines[i - 1].endswith(':') else i
            if o + n == hi:
                last = i
    assert first is not None and last is not None, (first, last)
    for ln in lines[first:last + 1]:
        t = ln.strip()
        if not (t == '' or t.endswith(':') and ' ' not in t or inc.match(ln) or
                t.startswith('.long ') or t.startswith(';')):
            raise SystemExit('unexpected line in the span: %r' % ln)
    kept_comments = [ln for ln in lines[first:last + 1] if ln.strip().startswith(';')]
    new = []
    for off, size, name, ctype, dims, hdr, kind in objs:
        syms = longs.get(off) if longs else None
        if syms:
            new.append(name + ':')
            new += ['\t.long %s' % x for x in syms]
        else:
            new += [name + ':', '\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X'
                    % (blob, off, size)]
        for lab, lo_ in INNER.get(span, []):
            if off < lo_ < off + size:
                new.append('\t.set %s, %s + %d\t; historical label, used by other files'
                           % (lab, name, lo_ - off))
    lines[first:last + 1] = kept_comments + new
    return len(objs)


if __name__ == '__main__':
    import naka_c_retype as NR
    import naka_c_model as M
    span = sys.argv[1]
    sp = SPANS[span]
    data = open(os.path.join(ROOT, 'v10/maincpu/includes/generated/%s.bin' % sp['blob']), 'rb').read()
    cb = M.CBlob(os.path.join(ROOT, 'v10/maincpu/ui_widgets/%s.c' % sp['blob']))
    for o in build(span, cb, data, NR.fmt):
        print('+0x%05X %5d %-8s %-8s %-7s %s' % (o[0], o[1], o[3], o[4], o[6], o[2]))
        if '-v' in sys.argv:
            print('        ' + o[5][:400])
