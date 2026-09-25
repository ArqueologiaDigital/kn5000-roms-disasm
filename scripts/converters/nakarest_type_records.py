#!/usr/bin/env python3
r"""nakarest_type_records.py -- type every NAKA widget record in lane nakarest's C
blobs as its CLASS, with the firmware's own field names.

QUESTION ANSWERED
-----------------
The NAKA blob sources describe widget records as anonymous `uint16_t
field_XXXX` words or as naka_types.h guesses (naka_container_t,
naka_label_t, ...).  The firmware itself says what each record is: its first
word is a class id, and the class definition names every field
(scripts/analysis/nakarest_objtab_map.py, THE CLASS SYSTEM).  For every record
of a registered Viewable table that lies in one of this lane's blobs, this
driver replaces the members covering exactly the record with ONE member of a
local struct type for that class --

    /* element 3 of Viewable slot 0x60 "": Label (0x0160002B) */
    .v60_e3 = { .class_ = 0x0160002B, .super = 1, .sub = NAKA_NONE, .next = 4,
                .prev = 2, .flag = 0x0008, .rect = { 78, 10, 225, 28 },
                .str = SELF(w2_text), .font = 0x00000000, .fontcolor = 0x0000 },

-- keeping every symbolic initializer (SELF / NAKA_ADDR) that sat on a 4-byte
field, and refusing (leaving the record as it is, and saying so) when one
sat anywhere else.  The struct types are defined locally in each .c
(naka_types.h belongs to lane nakabig), one per class, named
naka_cls_<ClassName>_t, with a comment giving the class id and the field
type characters.

Values come from the blob compiled from that version's own C; the result is
recompiled and must be byte-identical (checked here, then `make gate`).

RUN
    python3 scripts/converters/nakarest_type_records.py                 # dry
    python3 scripts/converters/nakarest_type_records.py --apply [--blob naka_msp_recording]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'scripts', 'analysis'))
import nakarest_c_model as M          # noqa: E402
import nakarest_retype as RT          # noqa: E402
import nakarest_objtab_map as O       # noqa: E402

BLOBS = ['naka_disk_warning', 'naka_block_012', 'naka_block_007', 'naka_sequencer_exit',
         'naka_technichord_strings',
         'naka_master_style', 'naka_msp_recording', 'naka_accomp7_widgets', 'naka_normal_mode', 'naka_debug_naming',
         'naka_disk_menu_file_io', 'naka_midi_reverb', 'naka_direct_play', 'naka_composer_style',
         'naka_effects_seq', 'naka_sound_menu_drawbar', 'naka_technichord_part',
         'naka_extension_device', 'naka_perf_style', 'naka_ctrl_menu_body',
         'naka_control_menu_header']
C_KEYWORDS = {'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do', 'double',
              'else', 'enum', 'extern', 'float', 'for', 'goto', 'if', 'int', 'long', 'register',
              'return', 'short', 'signed', 'sizeof', 'static', 'struct', 'switch', 'typedef',
              'union', 'unsigned', 'void', 'volatile', 'while', 'class'}
INDEX_FIELDS = {'super', 'sub', 'next', 'prev'}


def cname(f):
    f = re.sub(r'[^A-Za-z0-9_]', '_', f)
    return f + '_' if f in C_KEYWORDS else f


# ------------------------------------------------------------ naka_types.h
def naka_layouts(path):
    """typedef name -> {field: (offset, size)} for naka_types.h structs."""
    txt = open(path, encoding='latin-1').read()
    out = {}
    for m in re.finditer(r'typedef struct __attribute__\(\(packed\)\) \{(.*?)\} (naka_\w+_t);',
                         txt, re.S):
        off, fields = 0, {}
        for ln in m.group(1).split('\n'):
            mm = re.match(r'\s*((?:u?int(?:8|16|32)_t)|naka_header_t|char)\s+(\w+)((?:\[\d+\])*)\s*;', ln)
            if not mm:
                continue
            n = {'uint8_t': 1, 'int8_t': 1, 'char': 1, 'uint16_t': 2, 'int16_t': 2,
                 'uint32_t': 4, 'int32_t': 4, 'naka_header_t': 4}[mm.group(1)]
            for d in re.findall(r'\[(\d+)\]', mm.group(3)):
                n *= int(d)
            fields[mm.group(2)] = (off, n)
            off += n
        out[m.group(2)] = fields
    return out


def symbolic_at(cb, k, layouts):
    """[(offset in blob, size, expr)] of every symbolic initializer inside
    member k, or None when one cannot be located."""
    mb, e = cb.members[k], cb.entries[k]
    expr = e.expr.strip()
    if not M.SYMBOLIC_RE.search(expr):
        return []
    out = []
    if mb.ctype == 'uint32_t' and not mb.dims:
        return [(mb.offset, 4, expr)]
    if mb.ctype == 'uint32_t' and mb.dims:
        for i, x in enumerate(cb.elements(mb.name)):
            if M.SYMBOLIC_RE.search(x):
                out.append((mb.offset + 4 * i, 4, x))
        return out
    lay = layouts.get(mb.ctype)
    if lay is None or not expr.startswith('{'):
        return None
    for ch in M.split_top_level(expr[1:-1]):
        mm = re.match(r'\s*\.(\w+)\s*=\s*(.*)$', ch, re.S)
        if not mm:
            if ch.strip():
                return None
            continue
        f, x = mm.group(1), ' '.join(mm.group(2).split())
        if M.SYMBOLIC_RE.search(x):
            if f not in lay:
                return None
            o, n = lay[f]
            out.append((mb.offset + o, n, x))
    return out


# ------------------------------------------------------------ the new member
class RecordMember(M.NewMember):
    def __init__(self, ctype, name, size, expr, fields, pre):
        super().__init__(ctype, name, '', size, expr, pre)
        self.fields = fields          # [(off, cname, size)]

    def designator(self, rel):
        if rel == 0:
            return self.name
        for off, f, n in self.fields:
            if off == rel:
                return '%s.%s' % (self.name, f)
            if off < rel < off + n and n == 8 and (rel - off) % 2 == 0:
                return '%s.%s[%d]' % (self.name, f, (rel - off) // 2)
        raise SystemExit('SELF into the middle of field of %s (+%d)' % (self.name, rel))


def class_layout(m, c):
    """[(offset, c field name, size, sigchar)] and the struct's total size."""
    fl = [(o, cname(f), O.SIG_SIZE[ch], ch) for o, f, ch in m.class_fields(c)]
    names = set()
    for i, (o, f, n, ch) in enumerate(fl):
        base, j = f, 2
        while f in names:
            f = '%s_%d' % (base, j)
            j += 1
        names.add(f)
        fl[i] = (o, f, n, ch)
    return fl, c['allsize']


def typedef_text(m, c, tname):
    fl, size = class_layout(m, c)
    lines = ['/* NAKA class %s -- class id 0x016%X%04X (Class table slot 0x%X, entry %d),'
             % (c['name'], c['slot'] & 0xF, c['k'], c['slot'], c['k']),
             ' * parent %s; allsize %d.  Field names and type characters are the'
             % (m.klass(c['parent'])['name'] if c['parent'] != 0xFFFFFFFF and m.klass(c['parent'])
                else '-', size),
             ' * class chain\'s own propname / propdata (see THE CLASS SYSTEM in',
             ' * scripts/analysis/nakarest_objtab_map.py). */',
             'typedef struct __attribute__((packed)) {']
    off = 0
    for o, f, n, ch in fl:
        if o > off:
            lines.append('    uint8_t _pad_%d[%d];' % (off, o - off))
            off = o
        ct = {1: 'uint8_t', 2: 'uint16_t', 4: 'uint32_t'}.get(n)
        if n == 8:
            lines.append('    int16_t %s[4];%s/* +%d %s */' % (f, ' ' * max(1, 14 - len(f)), o, ch))
        else:
            lines.append('    %s %s;%s/* +%d %s */' % (ct, f, ' ' * max(1, 18 - len(f)), o, ch))
        off = o + n
    if off < size:
        lines.append('    uint8_t _pad_%d[%d];' % (off, size - off))
    lines.append('} %s;' % tname)
    return '\n'.join(lines) + '\n'


def record_expr(m, c, data, a_off, sym_by_off, false_ptrs):
    """The initializer; a symbolic value that does not sit on a 4-byte field
    of the class layout is not a pointer the firmware uses (the layout is the
    firmware's own), so its bytes are written as numbers and it is appended to
    false_ptrs."""
    fl, size = class_layout(m, c)
    four = {o for o, f, n, ch in fl if n == 4}
    for o in list(sym_by_off):
        if o not in four or sym_by_off[o][1] != 4:
            false_ptrs.append((o, sym_by_off.pop(o)[0]))
    parts, used = [], set()
    off = 0
    for o, f, n, ch in fl:
        if o > off:
            parts.append('._pad_%d = { %s }' % (off, ', '.join('0x%02X' % b for b in data[a_off + off:a_off + o])))
        v = data[a_off + o:a_off + o + n]
        if o in sym_by_off:
            x, sn = sym_by_off[o]
            if sn != n:
                return None
            used.add(o)
            parts.append('.%s = %s' % (f, x))
        elif n == 8:
            parts.append('.%s = { %s }' % (f, ', '.join(
                str(int.from_bytes(v[i:i + 2], 'little', signed=True)) for i in range(0, 8, 2))))
        elif n == 4:
            parts.append('.%s = 0x%08X' % (f, int.from_bytes(v, 'little')))
        elif n == 2:
            w = int.from_bytes(v, 'little')
            if f in INDEX_FIELDS:
                parts.append('.%s = %s' % (f, 'NAKA_NONE' if w == 0xFFFF else str(w)))
            else:
                parts.append('.%s = 0x%04X' % (f, w))
        else:
            parts.append('.%s = 0x%02X' % (f, v[0]))
        off = o + n
    if off < size:
        parts.append('._pad_%d = { %s }' % (off, ', '.join('0x%02X' % b for b in data[a_off + off:a_off + size])))
    if set(sym_by_off) - used:
        return None
    body = ',\n        '.join(parts)
    return '{\n        ' + body + ',\n    }', fl


def ensure_typedef(cb, name, text):
    if any(l.strip() == '} %s;' % name for l in cb.lines):
        return
    new = text.rstrip('\n').split('\n') + ['']
    at = cb.s0
    cb.lines[at:at] = new
    n = len(new)
    cb.s0 += n
    cb.s1 += n
    cb.i0 += n
    cb.i1 += n


CLASSDEF_T = 'naka_classdef_t'
CLASSDEF_FIELDS = [(0, 'proc', 4, 'J'), (4, 'parent', 4, 'M'), (8, 'allsize', 2, 'B'),
                   (10, 'selfsize', 2, 'B'), (12, 'name', 4, 'X'), (16, 'propdata', 4, 'X'),
                   (20, 'propname', 4, 'L')]
CLASSDEF_TEXT = """/* A NAKA class definition (24 bytes).  Its field names are the firmware's
 * own: the root class "Class" (class id 0x01600004) names them in its
 * propname block -- proc, parent, allsize, selfsize, name, propdata,
 * propname -- and ClassProc (ui/ui_widget_defs.s) indexes a registered
 * Class table with 24 * (class id & 0xFFFF).  parent is the parent's class
 * id; allsize the instance size (parent.allsize + selfsize, the root Object
 * contributing nothing); propdata one type character per own field;
 * propname points at len(propdata) + 1 field-name pointers, the last to an
 * empty string (THE CLASS SYSTEM, scripts/analysis/nakarest_objtab_map.py). */
typedef struct __attribute__((packed)) {
    uint32_t proc;        /* +0  J  class procedure */
    uint32_t parent;      /* +4  M  parent class id */
    uint16_t allsize;     /* +8  B  instance size */
    uint16_t selfsize;    /* +10 B  size of the own fields */
    uint32_t name;        /* +12 X  class name string */
    uint32_t propdata;    /* +16 X  field type characters */
    uint32_t propname;    /* +20 L  field-name pointer block */
} naka_classdef_t;
"""


def classdef_expr(m, c, data, off, sym):
    parts = []
    for o, f, n, ch in CLASSDEF_FIELDS:
        if o in sym:
            parts.append('.%s = %s' % (f, sym.pop(o)[0]))
            continue
        v = int.from_bytes(data[off + o:off + o + n], 'little')
        if f in ('allsize', 'selfsize'):
            parts.append('.%s = %d' % (f, v))            # sizes, in bytes
        else:
            parts.append('.%s = 0x%0*X' % (f, 2 * n, v))
    if sym:
        return None
    return '{ ' + ', '.join(parts) + ' }'


def type_class_run(v, m, cb, data, base, r, lo, hi, layouts, false_log):
    """Retype blob [lo', hi') -- [lo, hi) widened to member boundaries -- as the
    class definitions of Class table r that it holds: whole records as
    naka_classdef_t, a record cut by the blob edge as its fields, and the
    widening bytes as plain members.  Returns the number of whole records, or
    None when a symbolic value cannot be placed."""
    t0 = r['table']
    k0 = cb.index_at(lo)
    k1 = cb.index_at(hi - 1)
    wlo = cb.members[k0].offset
    whi = cb.members[k1].offset + cb.members[k1].size
    if cb.members[k0].name.startswith('classdef_'):
        return 0
    sym = {}
    for kk in range(k0, k1 + 1):
        ss = symbolic_at(cb, kk, layouts)
        if ss is None:
            return None
        for o, sn, x in ss:
            sym[o] = (x, sn)          # blob offsets
    new = []
    placed = set()

    def scalar(name, off, n, pre=()):
        v_ = int.from_bytes(data[off:off + n], 'little')
        ct = {1: 'uint8_t', 2: 'uint16_t', 4: 'uint32_t'}[n]
        if off in sym and sym[off][1] == n == 4:
            placed.add(off)
            ex = sym[off][0]
        else:
            ex = '0x%0*X' % (2 * n, v_)
        return M.NewMember(ct, name, '', n, ex, list(pre))

    def rawbytes(name, a, b):
        return M.NewMember('uint8_t', name, '[%d]' % (b - a), b - a,
                           '{ ' + ', '.join('0x%02X' % x for x in data[a:b]) + ' }')

    off = wlo
    while off < whi:
        rel = off + base - t0
        k, within = divmod(rel, 24)
        if rel < 0 or k >= r['count']:
            # outside the table: plain words (a symbolic 4-byte value kept)
            end = min(whi, t0 - base) if rel < 0 else whi
            while off < end:
                n = 4 if end - off >= 4 else (2 if end - off >= 2 else 1)
                new.append(scalar('classrun_%X_x%04X' % (r['slot'], off), off, n))
                off += n
            continue
        c = m.classes[((r['slot'] & 0xFFF) << 16) | k]
        if within == 0 and off + 24 <= whi:
            sy = {o - off: sym[o] for o in list(sym) if off <= o < off + 24}
            four = {o for o, f, n, ch in CLASSDEF_FIELDS if n == 4}
            for o in list(sy):
                if o not in four or sy[o][1] != 4:
                    false_log.append('%s classdef_%X_%d +%d: %s' % (v, r['slot'], k, o, sy.pop(o)[0]))
            for o in sy:
                placed.add(off + o)
            p = m.klass(c['parent']) if c['parent'] != 0xFFFFFFFF else None
            pre = ['    /* class definition 0x%X:%d: %s (parent %s, allsize %d, fields %s) */'
                   % (r['slot'], k, c['name'], p['name'] if p else '-', c['allsize'],
                      ', '.join(c['fields'][:-1]) or '-')]
            M.TYPE_SIZES[CLASSDEF_T] = 24
            new.append(RecordMember(CLASSDEF_T, 'classdef_%X_%d' % (r['slot'], k), 24,
                                    classdef_expr(m, c, data, off, sy),
                                    [(o, f, n) for o, f, n, ch in CLASSDEF_FIELDS], pre))
            off += 24
            continue
        # a record cut by the blob edge (or by the widened span): its fields
        pre = ['    /* class definition 0x%X:%d: %s -- the part of the record in this blob '
               '(the rest is in the neighbouring blob) */' % (r['slot'], k, c['name'])]
        first = True
        for o, f, n, ch in CLASSDEF_FIELDS:
            a = t0 - base + 24 * k + o
            if a < off or a >= whi:
                continue
            if a + n > whi:
                break
            new.append(scalar('classdef_%X_%d_%s' % (r['slot'], k, f), a, n, pre if first else ()))
            first = False
            off = a + n
        # bytes of the record past the widened end, if any, are not ours
        nxt = t0 - base + 24 * (k + 1)
        if off < min(nxt, whi):
            new.append(rawbytes('classdef_%X_%d_rest' % (r['slot'], k), off, min(nxt, whi)))
            off = min(nxt, whi)
    if set(sym) - placed:
        for o in sorted(set(sym) - placed):
            false_log.append('%s classrun +0x%X: %s (not a pointer field)' % (v, o, sym[o][0]))
    keeps = [cb.members[kk].name for kk in range(k0, k1 + 1)
             if M.SYMBOLIC_RE.search(cb.entries[kk].expr)]
    try:
        ensure_typedef(cb, CLASSDEF_T, CLASSDEF_TEXT)
        cb.retype(wlo, whi, new, data, false_pointers=keeps)
    except SystemExit as e:
        print('     class run refused: %s' % str(e)[:120])
        return None
    return sum(1 for nm in new if nm.ctype == CLASSDEF_T)


FALSE_LOG = []


def type_blob(v, blob, apply, layouts):
    m = RT.objmap(v)
    cpath = RT.c_path(v, blob)
    try:
        cb = M.CBlob(cpath)
    except (SystemExit, StopIteration, KeyError) as e:
        print('%s %-24s not parsable by the C model (%s) -- skipped' % (v, blob, str(e)[:60]))
        return
    data = RT.compile_blob(v, blob)
    base = cb.base()
    if len(data) != cb.size:
        raise SystemExit('%s: compiled %d, struct %d' % (blob, len(data), cb.size))
    recs = []
    for a, vs in m.in_range(base, base + cb.size):
        for kind, r, k in vs:
            if kind == 'record':
                recs.append((a, r, k))
    done = skipped = already = 0
    reasons = {}
    false_log = []
    tnames = {}
    for a, r, k in recs:
        c = m.record_class(a)
        tname = 'naka_cls_%s_t' % cname(c['name'])
        key = (c['slot'], c['k'])
        other = [kk for kk, tn in tnames.items() if tn == tname and kk != key]
        if other:
            tname = 'naka_cls_%s_%X_%d_t' % (cname(c['name']), c['slot'], c['k'])
        tnames[key] = tname
        mname = 'v%X_e%d' % (r['slot'], k)
        off = a - base
        n = c['allsize']
        if mname in cb.by_name:
            already += 1
            continue
        # boundaries: split words where allowed
        try:
            cb.split_word(off, data)
            if off + n < cb.size:
                cb.split_word(off + n, data)
        except SystemExit as e:
            reasons.setdefault('boundary inside a symbolic/SELF-target member', []).append(mname)
            skipped += 1
            continue
        k0, k1 = cb.index_at(off), cb.index_at(off + n - 1)
        if cb.members[k0].offset != off or cb.members[k1].offset + cb.members[k1].size != off + n:
            reasons.setdefault('member boundary does not align', []).append(mname)
            skipped += 1
            continue
        sym = {}
        bad = False
        for kk in range(k0, k1 + 1):
            s = symbolic_at(cb, kk, layouts)
            if s is None:
                bad = True
                break
            for o, sn, x in s:
                sym[o - off] = (x, sn)
        if bad:
            reasons.setdefault('symbolic initializer in an unparsed member', []).append(mname)
            skipped += 1
            continue
        fps = []
        res = record_expr(m, c, data, off, sym, fps)
        for o, x in fps:
            false_log.append('%s %s +%d: %s' % (v, mname, o, x))
        if res is None:
            reasons.setdefault('symbolic value not on a 4-byte field', []).append(mname)
            skipped += 1
            continue
        expr, fl = res
        rn = m.by_slot.get(r['slot'] + 0x300)
        el_name = ''
        if rn and k < len(m.entries(rn)) and m.inrom(m.entries(rn)[k]):
            el_name = m.string_at(m.entries(rn)[k])
        pre = ['    /* element %d of Viewable slot 0x%X%s: %s (class id 0x%08X) */'
               % (k, r['slot'], (' "%s"' % RT.ascii_only(el_name)) if el_name else '', c['name'],
                  m.u32(a))]
        M.TYPE_SIZES[tname] = n
        nm = RecordMember(tname, mname, n, expr, [(o, f, sz) for o, f, sz, ch in fl], pre)
        keeps = [cb.members[kk].name for kk in range(k0, k1 + 1)
                 if M.SYMBOLIC_RE.search(cb.entries[kk].expr)]
        try:
            ensure_typedef(cb, tname, typedef_text(m, c, tname))
            cb.retype(off, off + n, [nm], data, false_pointers=keeps)
        except SystemExit as e:
            reasons.setdefault('retype refused: %s' % str(e)[:60], []).append(mname)
            skipped += 1
            continue
        done += 1
    # class tables overlapping this blob, typed as one run each: the old
    # members (naka_dispatch_t) sit 4 bytes off the 24-byte records, so no
    # single record boundary is a member boundary
    cdone = cskip = 0
    for r in m.regs:
        if r['cls'] != 0x1600004 or not r['count']:
            continue
        t0, t1 = r['table'], r['table'] + 24 * r['count']
        lo, hi = max(t0, base), min(t1, base + cb.size)
        if lo >= hi:
            continue
        res = type_class_run(v, m, cb, data, base, r, lo - base, hi - base, layouts, false_log)
        if res is None:
            cskip += 1
        else:
            cdone += res
    done += cdone
    print('%s %-24s records %4d: typed %4d, already %4d, skipped %4d; class definitions typed %d, '
          'skipped %d' % (v, blob, len(recs), done - cdone, already, skipped, cdone, cskip))
    for why, ms in reasons.items():
        print('     skipped (%s): %d, e.g. %s' % (why, len(ms), ', '.join(ms[:4])))
    if false_log:
        print('     %d symbolic values off the class\'s 4-byte fields retired as false '
              'pointers, e.g. %s' % (len(false_log), '; '.join(false_log[:3])))
    FALSE_LOG.extend(false_log)
    ns = self_pointers(cb)
    if ns:
        print('     %d numeric pointer fields made SELF(member)' % ns)
    if apply and (done or ns):
        cb.write()
        if RT.compile_blob(v, blob) != data:
            raise SystemExit('%s %s: typed C compiles to different bytes' % (v, blob))
        print('     %s %s: recompiled, byte-identical' % (v, blob))


def self_pointers(cb):
    """In every naka_cls_*_t / naka_classdef_t initializer, a 4-byte field
    whose numeric value is the address of a member START in this blob
    becomes SELF(member).  Returns the count."""
    base = cb.base()
    starts = {base + mb.offset: mb.name for mb in cb.members}
    n = 0
    for mb, e in zip(cb.members, cb.entries):
        if not (mb.ctype.startswith('naka_cls_') or mb.ctype == CLASSDEF_T):
            continue

        def sub(mm):
            nonlocal n
            v = int(mm.group(2), 16)
            if v in starts and starts[v] != mb.name:
                n += 1
                return '%sSELF(%s)' % (mm.group(1), starts[v])
            return mm.group(0)
        e.expr = re.sub(r'(\.\w+ = )0x([0-9A-F]{8})\b', sub, e.expr)
    return n


SB_TYPES = {
    'mst_style_ref_t': (8, """/* One style of an MstStyle browser group (8 bytes): its name and its
 * variation table.  Group tables are arrays of these ending in an all-zero
 * entry; MstStyle*_CountEntries (ui/ui_mode_handlers.s) walk them 8 bytes
 * at a time until +0 is 0, the grid routines Strcpy +0 (padded to 16 with
 * Strncat) and +4 goes to 0x0340D6. */
typedef struct __attribute__((packed)) {
    uint32_t name;        /* +0 style name, 16 characters */
    uint32_t variations;  /* +4 mst_title_ref_t[], zero-terminated */
} mst_style_ref_t;
"""),
    'mst_group_ref_t': (8, """/* One group of the MstStyle browser root (8 bytes).  MstStyle1_EventDispatch
 * & co. load (index*8)+4 -- the group table -- through a label 4 bytes into
 * the root and store it at 0x0340D2; MstStyle1Grid_CellSelect loads +0. */
typedef struct __attribute__((packed)) {
    uint32_t name;        /* +0 group name, 16 characters */
    uint32_t styles;      /* +4 mst_style_ref_t[], zero-terminated */
} mst_group_ref_t;
"""),
}


def type_style_browser(v, apply):
    m = RT.objmap(v)
    blob = 'naka_style_bitmaps'
    cpath = os.path.join(RT.ui(v), blob + '.c')
    cb = M.CBlob(cpath)
    if 'StyleBrowser_Groups' in cb.by_name:
        print('%s %s: style browser already typed' % (v, blob))
        return
    data = RT.compile_blob(v, blob)
    base = cb.base()
    u32 = lambda a: int.from_bytes(data[a - base:a - base + 4], 'little')
    u16 = lambda a: int.from_bytes(data[a - base:a - base + 2], 'little')

    def slen(a):
        n = 0
        while data[a - base + n]:
            n += 1
        n += 1
        return n + (n & 1)

    root = m.sb['table']
    objs = {}          # address -> (name, NewMember builder)
    names = {}
    for g in range(10):
        gn, gp = u32(root + 8 * g), u32(root + 8 * g + 4)
        names[gn] = 'StyleGroup%d_Name' % g
        names[gp] = 'StyleGroup%d_Styles' % g
        k = 0
        while u32(gp + 8 * k):
            sn, vt = u32(gp + 8 * k), u32(gp + 8 * k + 4)
            names[sn] = 'Style_g%d_s%d_Name' % (g, k)
            names[vt] = 'Style_g%d_s%d_Vars' % (g, k)
            j = 0
            while u32(vt + 6 * j):
                names[u32(vt + 6 * j)] = 'Style_g%d_s%d_Title%d' % (g, k, j)
                j += 1
            k += 1
    names[root] = 'StyleBrowser_Groups'
    start, end = min(names), max(a for a in names)
    # the member list, in address order
    new = []

    def astr(nm, a, pre=()):
        n = slen(a)
        b = data[a - base:a - base + n]
        t = b.split(b'\0')[0]
        assert b == t + b'\0' + (b'\xff' if len(t) % 2 == 0 else b''), (nm, b)
        ex = ('ALIGNED_STRING(%s)' % M.c_string(t)) if len(t) % 2 == 0 else M.c_string(t)
        return M.NewMember('char', nm, '[%d]' % n, n, ex, list(pre))

    for a in sorted(names):
        nm = names[a]
        if nm.endswith('_Name') or '_Title' in nm:
            mbr = astr(nm, a)
        elif nm.endswith('_Vars'):
            j, rows = 0, []
            while u32(a + 6 * j):
                t = u32(a + 6 * j)
                rows.append('        { SELF(%s), %d },' % (names[t], u16(a + 6 * j + 4)))
                j += 1
            assert data[a + 6 * j - base:a + 6 * j + 6 - base] == bytes(6)
            rows.append('        { 0, 0 },')
            g, k = nm.split('_')[1][1:], nm.split('_')[2][1:]
            sn = [x for x, y in names.items() if y == 'Style_g%s_s%s_Name' % (g, k)][0]
            pre = ['    /* style %s.%s "%s": %d variations */' % (
                g, k, RT.ascii_only(data[sn - base:sn - base + 16].decode('latin-1').strip()), j)]
            mbr = M.NewMember('mst_title_ref_t', nm, '[%d]' % (j + 1), 6 * (j + 1),
                              '{\n' + '\n'.join(rows) + '\n    }', pre)
        elif nm.endswith('_Styles'):
            k, rows = 0, []
            while u32(a + 8 * k):
                rows.append('        { SELF(%s), SELF(%s) },' % (names[u32(a + 8 * k)],
                                                               names[u32(a + 8 * k + 4)]))
                k += 1
            assert data[a + 8 * k - base:a + 8 * k + 8 - base] == bytes(8)
            rows.append('        { 0, 0 },')
            mbr = M.NewMember('mst_style_ref_t', nm, '[%d]' % (k + 1), 8 * (k + 1),
                              '{\n' + '\n'.join(rows) + '\n    }')
        else:
            rows = ['        { SELF(%s), SELF(%s) },' % (names[u32(a + 8 * g)], names[u32(a + 8 * g + 4)])
                    for g in range(10)]
            mbr = M.NewMember('mst_group_ref_t', nm, '[10]', 80, '{\n' + '\n'.join(rows) + '\n    }',
                              ['    /* the MstStyle browser root: 10 groups (see mst_group_ref_t) */'])
        new.append((a, mbr))
    # contiguity
    for (a, mb), (b, _) in zip(new, new[1:]):
        assert a + mb.size == b, (hex(a), mb.name, hex(b))
    end = new[-1][0] + new[-1][1].size
    lo, hi = start - base, end - base
    for t, (n, _) in SB_TYPES.items():
        M.TYPE_SIZES[t] = n
    try:
        cb.split_word(lo, data)
        cb.split_word(hi, data)
    except SystemExit as e:
        print('%s style browser: boundary refused: %s' % (v, e))
        return
    k0, k1 = cb.index_at(lo), cb.index_at(hi - 1)
    keeps = [cb.members[kk].name for kk in range(k0, k1 + 1)
             if M.SYMBOLIC_RE.search(cb.entries[kk].expr)]
    for t, (n, text) in SB_TYPES.items():
        ensure_typedef(cb, t, text)
    cb.retype(lo, hi, [mb for _, mb in new], data, false_pointers=keeps)
    print('%s %s: style browser typed -- %d objects, 0x%06X..0x%06X (%d B), %d symbolic '
          'initializers re-expressed' % (v, blob, len(new), start, end, end - start, len(keeps)))
    if apply:
        cb.write()
        if RT.compile_blob(v, blob) != data:
            raise SystemExit('%s %s: typed C compiles to different bytes' % (v, blob))
        print('     %s %s: recompiled, byte-identical' % (v, blob))


def type_palettes(v, apply):
    """naka_debug_naming.c: the default palette (0xEB37DE, InitPaletteRGB) and
    the 11 wallpaper palettes (NakaColor_Palette1..10, _PaletteBlank; entries
    of the wallpaper-palette table GetWallPaletteRGB reads) as
    uint8_t name[256][4]."""
    blob = 'naka_debug_naming'
    cpath = RT.c_path(v, blob)
    cb = M.CBlob(cpath)
    if 'DefaultPalette' in cb.by_name:
        print('%s %s: palettes already typed' % (v, blob))
        return
    data = RT.compile_blob(v, blob)
    base = cb.base()
    R = RT.refs(v)
    objs = [(0xEB37DE, 'DefaultPalette',
             'the default 256-colour palette: InitPaletteRGB (display/graphics_text_vga.s) '
             'copies these 0x400 bytes to the palette RAM at 0x0324FC (SetPaletteRGB / '
             'Table_LookupDword index it 4 bytes per colour)')]
    t = R.sym['Naka_DrawbarReg_Table']
    for nm in ['NakaColor_Palette%d' % i for i in range(1, 11)] + ['NakaColor_PaletteBlank']:
        a = R.sym[nm]
        ks = [k for k in range(12)
              if int.from_bytes(R.rom[t - 0xE00000 + 4 * k:t - 0xE00000 + 4 * k + 4], 'little') == a]
        objs.append((a, nm, 'a wallpaper palette, entr%s %s of the wallpaper-palette table '
                            'Naka_DrawbarReg_Table (RAM 0x3F1E4 after Boot_InitWorkRAM), read by '
                            'GetWallPaletteRGB' % ('ies' if len(ks) > 1 else 'y',
                                                   ', '.join(map(str, ks)))))
    objs.sort()
    lo, hi = objs[0][0] - base, objs[-1][0] + 1024 - base
    for (a, _, _), (b, _, _) in zip(objs, objs[1:]):
        assert a + 1024 == b
    new = []
    for a, nm, why in objs:
        off = a - base
        pix = data[off:off + 1024]
        assert all(pix[i + 3] == 0 for i in range(0, 1024, 4)), nm
        rows = ['        /* %3d */ { 0x%02X, 0x%02X, 0x%02X, 0x%02X },' % ((i,) + tuple(pix[4 * i:4 * i + 4]))
                for i in range(256)]
        pre = ['    /* %s: %s.  256 x {3 colour bytes, 0}; the channel order was not traced. */'
               % (nm, why)]
        new.append(M.NewMember('uint8_t', nm, '[256][4]', 1024, '{\n' + '\n'.join(rows) + '\n    }', pre))
    cb.split_word(lo, data)
    cb.split_word(hi, data)
    k0, k1 = cb.index_at(lo), cb.index_at(hi - 1)
    keeps = [cb.members[kk].name for kk in range(k0, k1 + 1)
             if M.SYMBOLIC_RE.search(cb.entries[kk].expr)]
    cb.retype(lo, hi, new, data, false_pointers=keeps)
    print('%s %s: 12 palettes typed (0x%06X..0x%06X); %d symbolic initializers inside them retired '
          'as false pointers (colour bytes)' % (v, blob, lo + base, hi + base, len(keeps)))
    if apply:
        cb.write()
        if RT.compile_blob(v, blob) != data:
            raise SystemExit('%s %s: typed C compiles to different bytes' % (v, blob))
        print('     %s %s: recompiled, byte-identical' % (v, blob))


MSG_T = ('msg_record_t', 14, """/* One record of the IvMesage message catalog (14 bytes).  Readers
 * (ui/drawbar_panel_ui.s): IvMesageProc on init (0x1C00001) and
 * IvMessage_SelectionChange / LanguageCheckReturn index the catalog with
 * `muls wa, 0xe` and load `kind`, which selects one of the 6 window object
 * ids that follow the catalog (`sla wa, 2`); MessageText (event 0x1E0009F)
 * returns `text`; CheckMsg_IncrementCheck stops at a record whose `text` is
 * 0; IvMessage_Paint compares `kind` with 5.  `header` and `text` point at
 * 6-entry per-language string tables (English, German, French, Spanish,
 * Italian, Indonesian). */
typedef struct __attribute__((packed)) {
    uint16_t kind;     /* +0  window: 0 NoMessage, 1 Completed, 2 Reminder,
                              3 Error, 4 Other, 5 PleaseWait */
    uint32_t code;     /* +2  0x00NNFFFF: NN = the error number shown;
                              0xFFFFFFFF none */
    uint32_t header;   /* +6  per-language header strings */
    uint32_t text;     /* +10 per-language message texts */
} msg_record_t;
""")


def type_message_catalog(v, apply):
    blob = 'naka_technichord_strings'
    cb = M.CBlob(RT.c_path(v, blob))
    if 'IvMesage_Catalog' in cb.by_name:
        print('%s %s: message catalog already typed' % (v, blob))
        return
    data = RT.compile_blob(v, blob)
    base = cb.base()
    m = RT.objmap(v)
    T, n = m.msgcat['table'], m.msgcat['count']
    lo, hi = T - base, T - base + 14 * (n + 1) + 24
    layouts = naka_layouts(os.path.join(RT.ui(v), 'naka_types.h'))
    cb.split_word(lo, data)
    cb.split_word(hi, data)
    k0, k1 = cb.index_at(lo), cb.index_at(hi - 1)
    sym = {}
    for kk in range(k0, k1 + 1):
        for o, sn, x in (symbolic_at(cb, kk, layouts) or []):
            sym[o] = x
    rows = []
    for k in range(n + 1):
        a = lo + 14 * k
        kind = int.from_bytes(data[a:a + 2], 'little')
        code = int.from_bytes(data[a + 2:a + 6], 'little')
        hd = sym.pop(a + 6, '0x%08X' % int.from_bytes(data[a + 6:a + 10], 'little'))
        tx = sym.pop(a + 10, '0x%08X' % int.from_bytes(data[a + 10:a + 14], 'little'))
        rows.append('        /* %2d */ { %d, 0x%08X, %s, %s },' % (k, kind, code, hd, tx))
    wl = lo + 14 * (n + 1)
    wins = [int.from_bytes(data[wl + 4 * i:wl + 4 * i + 4], 'little') for i in range(6)]
    if sym:
        print('%s: unplaced symbolic values %s -- not typed' % (v, list(sym.items())[:3]))
        return
    M.TYPE_SIZES[MSG_T[0]] = MSG_T[1]
    ensure_typedef(cb, MSG_T[0], MSG_T[2])
    new = [M.NewMember(MSG_T[0], 'IvMesage_Catalog', '[%d]' % (n + 1), 14 * (n + 1),
                       '{\n' + '\n'.join(rows) + '\n    }',
                       ['    /* the IvMesage message catalog: %d records + an all-zero terminator '
                        '(see msg_record_t) */' % n]),
           M.NewMember('uint32_t', 'IvMesage_Windows', '[6]', 24,
                       '{ ' + ', '.join('0x%08X' % w for w in wins) + ' }',
                       ['    /* the 6 window object ids `kind` selects: Viewable slot 0xEE '
                        'elements 0x14 NoMessage, 0x02 Completed, 0x05 Reminder, 0x09 Error, '
                        '0x0D Other, 0x16 PleaseWait (all class Window) */'])]
    keeps = [cb.members[kk].name for kk in range(k0, k1 + 1)
             if M.SYMBOLIC_RE.search(cb.entries[kk].expr)]
    cb.retype(lo, hi, new, data, false_pointers=keeps)
    print('%s %s: message catalog typed (%d records + terminator, window ids)' % (v, blob, n))
    if apply:
        cb.write()
        if RT.compile_blob(v, blob) != data:
            raise SystemExit('%s %s: typed C compiles to different bytes' % (v, blob))
        print('     %s %s: recompiled, byte-identical' % (v, blob))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--blob', action='append')
    ap.add_argument('--style-browser', action='store_true')
    ap.add_argument('--palettes', action='store_true')
    ap.add_argument('--messages', action='store_true')
    a = ap.parse_args()
    if a.messages:
        for v in RT.VERSIONS:
            type_message_catalog(v, a.apply)
        return
    if a.palettes:
        for v in RT.VERSIONS:
            type_palettes(v, a.apply)
        return
    if a.style_browser:
        for v in RT.VERSIONS:
            type_style_browser(v, a.apply)
        return
    for v in RT.VERSIONS:
        layouts = naka_layouts(os.path.join(RT.ui(v), 'naka_types.h'))
        for blob in a.blob or BLOBS:
            type_blob(v, blob, a.apply, layouts)


if __name__ == '__main__':
    main()
