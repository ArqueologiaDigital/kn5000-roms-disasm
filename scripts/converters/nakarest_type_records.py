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

BLOBS = ['naka_msp_recording', 'naka_accomp7_widgets', 'naka_normal_mode', 'naka_debug_naming',
         'naka_disk_menu_file_io', 'naka_midi_reverb', 'naka_direct_play', 'naka_composer_style',
         'naka_effects_seq', 'naka_sound_menu_drawbar', 'naka_technichord_part',
         'naka_extension_device', 'naka_perf_style', 'naka_ctrl_menu_body']
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


FALSE_LOG = []


def type_blob(v, blob, apply, layouts):
    m = RT.objmap(v)
    cpath = os.path.join(RT.ui(v), blob + '.c')
    cb = M.CBlob(cpath)
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
    print('%s %-24s records %4d: typed %4d, already %4d, skipped %4d' % (v, blob, len(recs), done,
                                                                       already, skipped))
    for why, ms in reasons.items():
        print('     skipped (%s): %d, e.g. %s' % (why, len(ms), ', '.join(ms[:4])))
    if false_log:
        print('     %d symbolic values off the class\'s 4-byte fields retired as false '
              'pointers, e.g. %s' % (len(false_log), '; '.join(false_log[:3])))
    FALSE_LOG.extend(false_log)
    if apply and done:
        cb.write()
        if RT.compile_blob(v, blob) != data:
            raise SystemExit('%s %s: typed C compiles to different bytes' % (v, blob))
        print('     %s %s: recompiled, byte-identical' % (v, blob))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--blob', action='append')
    a = ap.parse_args()
    for v in RT.VERSIONS:
        layouts = naka_layouts(os.path.join(RT.ui(v), 'naka_types.h'))
        for blob in a.blob or BLOBS:
            type_blob(v, blob, a.apply, layouts)


if __name__ == '__main__':
    main()
