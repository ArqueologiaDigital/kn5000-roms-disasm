#!/usr/bin/env python3
r"""nakarest_objtab_map.py -- what every registered NAKA object table points at.

QUESTION ANSWERED
-----------------
"Which ROM addresses are NAKA widget records, name strings, object tables or
procedure tables, according to the tables the firmware itself REGISTERS?"

The firmware registers its UI objects at start-up with the `RegObjTabl`
macro (display/scoop_display.s):  RegObjTabl class, proc, count, table, slot
stores {class, proc, count, table} at 0x27ED2 + 14*slot through
RegisterObjectTable (ui/ui_widget_defs.s).  The classes that matter here:

    0x1600010  ViewableProc   table = `count` pointers to widget RECORDS
    0x160000F  ResNameProc    table = `count` pointers to the NAME strings of
                              the same elements (slot = viewable slot + 0x300)
    0x1600002  ApFunctionProc table = `count` code addresses; slot + 0x300 is
                              the parallel name table
    0x1600001  FunctionProc   likewise
    0x1600003  MainFunctionProc likewise

This tool parses every RegObjTabl invocation in a version's source tree
(recording the Initialize* routine it sits in), reads each table out of the
ORIGINAL ROM dump, and for Viewable tables checks the widget links the ext
lane established (notes in scripts/analysis/ext_lane_checks.py): every record
starts `TT 00 6x 01` (a 32-bit word 0x016x00TT; x is 0 in 2,869 of the 3,340
v10 records and 1..8 in the rest), and +4 parent / +6 first child / +8 next sibling /
+10 previous sibling are element indices of the same table (0xFFFF = none)
that agree with each other.

THE CLASS SYSTEM (established by this tool, 2026-09-25)
    The NAKA object model is self-describing.  `RegObjTable 0x1600004,
    ClassProc, <count addr>, <table>, <slot>` registers a Class table (the
    count is the WORD at the third operand: `ldw_da xwa, (<addr>)`); ten are
    registered, slots 0x160-0x168 and 0x16B, one per module (InitializeRoot
    0x160 with 109 classes, Murai 0x161, Toshi 0x162, East 0x163, Suna 0x164,
    Cheap 0x165, Scoop 0x166, Yoko 0x167, Kubo 0x168, Naka 0x16B): 292 classes.
    ClassProc (ui/ui_widget_defs.s) maps a class id 0x016S_KKKK to entry KKKK
    (x 24 bytes: add xhl,xhl / add xhl,xbc / sll xhl,3) of the table in
    registry slot (id >> 16) & 0xFFF (srl 16 / and 0xFFF).  The 24-byte Class
    record's fields are named by the root class "Class" itself: proc, parent,
    allsize, selfsize, name, propdata, propname (+0 .. +20).  propdata is one
    character per own field (its type; byte sizes in SIG_SIZE, solved so that
    sum == selfsize for all 292 classes); propname points at len(propdata)+1
    string pointers -- the own fields' names in record order, the last one an
    empty string -- followed by the strings.  allsize == parent.allsize +
    selfsize for all 291 classes with a parent, the root Object (0x01600000,
    allsize 2) contributing no prefix.  A widget record's first word is its
    class id: the "TT 00 6x 01 header" of older notes is 0x016x00TT, TT the
    class index (0x2B Label, 0x34 TtlScreen, 0x35 Window, 0x1D AcTitleMenu,
    0x2E Line, 0x31 Box, 0x66 AcLanguageText, 0x6C VwUserBitmapByName...).
    All 3,340 in-ROM records of the 209 Viewable tables resolve to a class and
    none is closer to the next record than its allsize (1,747 exactly that far).
    E.g. Viewable: +0 class, +4 super, +6 sub, +8 next, +10 prev, +12 flag,
    +14 rect (allsize 22); Label adds +22 str, +26 font, +30 fontcolor (32).
    --check-classes asserts all of this and exits non-zero on any failure; it
    passes on v10, v9 and v7.

It is a library for scripts/converters/nakarest_retype.py (the .s evidence
headers) and a report:

RUN
    python3 scripts/analysis/nakarest_objtab_map.py v10 --classes      # class system
    python3 scripts/analysis/nakarest_objtab_map.py v10 --check-classes
    python3 scripts/analysis/nakarest_objtab_map.py v10                # tables
    python3 scripts/analysis/nakarest_objtab_map.py v10 --at 0xEA14A2  # one addr
    python3 scripts/analysis/nakarest_objtab_map.py v10 --range 0xEA13CC 0xEA8CAC

The rebuilt ELF (rebuilt_ROMs/kn5000_<v>_program.llvm.elf) must exist; it
resolves symbolic table operands such as NAKA_UIObjectTable.
"""
import argparse
import bisect
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
BASE = 0xE00000
CLASS = {0x1600010: 'Viewable', 0x160000F: 'ResName', 0x1600002: 'ApFunction',
         0x1600001: 'Function', 0x1600003: 'MainFunction', 0x1600004: 'Class',
         0x160000C: 'ResEvent', 0x160000D: 'ResMethod'}
# Byte size of each field-signature character (propdata), solved from the
# 292 class definitions of v10: sum(size(ch) for ch in propdata) == selfsize
# (see THE CLASS SYSTEM in this docstring above).  'C' is one byte and
# is followed by a pad byte when it ends a class.
SIG_SIZE = {'I': 4, 'B': 2, 'X': 4, 'A': 2, 'j': 4, 'm': 4, 'n': 4, 'r': 4, 'f': 2,
            'e': 2, 'c': 4, 't': 4, 'k': 4, 'u': 2, '^': 2, 'i': 4, 'b': 4, 'g': 2,
            'h': 2, '_': 2, 'a': 4, 'G': 2, 'd': 2, '`': 4, 'N': 4, 's': 4, 'v': 2,
            'w': 2, 'F': 4, 'C': 1, 'l': 2, 'J': 4, 'M': 4, 'L': 4, 'K': 4, '[': 2,
            ']': 2, 'P': 8}
NONE = 0xFFFF


def nm(v):
    elf = os.path.join(ROOT, 'rebuilt_ROMs', 'kn5000_%s_program.llvm.elf' % v)
    out = subprocess.run([os.path.join(LLVM, 'llvm-nm'), '--defined-only', elf],
                         capture_output=True, text=True, check=True).stdout
    d, rev = {}, []
    for ln in out.split('\n'):
        f = ln.split()
        if len(f) == 3 and f[1] in 'tT':
            d.setdefault(f[2], int(f[0], 16))
            rev.append((int(f[0], 16), f[2]))
    rev.sort()
    return d, rev


class Map:
    def __init__(self, v):
        self.v = v
        self.rom = open(os.path.join(ROOT, 'original_ROMs', 'kn5000_%s_program.rom' % v), 'rb').read()
        self.sym, self.rev = nm(v)
        self.revaddr = [a for a, _ in self.rev]
        self.regs = []           # dicts: cls, proc, count, table, slot, init, file, line
        self._parse()
        self.by_slot = {r['slot']: r for r in self.regs}
        self.addr = {}           # address -> list of (kind, reg, k)
        self._index()
        self.index_texts()

    # ---------------------------------------------------------------- source
    def _val(self, tok):
        tok = tok.strip()
        try:
            return int(tok, 0)
        except ValueError:
            return self.sym.get(tok)

    def _parse(self):
        """Both spellings: the RegObjTabl macro (v10/v9), and the same code
        written out instruction by instruction (v7):
            ld XWA,<class> / lda xwa,(<proc>:24) / ldw (XBC+0x08),<count> /
            lda xwa,(<table>:24) / ld (XBC+0x0a),XWA / ldw WA,<slot> /
            call RegisterObjectTable"""
        rx = re.compile(r'^\s*RegObjTabl\s+([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,;\s]+)')
        rxe = re.compile(r'^\s*RegObjTable\s+([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,;\s]+)')
        for f in sorted(glob.glob(os.path.join(ROOT, self.v, 'maincpu', '**', '*.s'), recursive=True)):
            init = None
            window = []
            count_at = None
            self._count_at = None
            for i, l in enumerate(open(f, encoding='latin-1')):
                m = re.match(r'^([A-Za-z_]\w*):', l)
                if m and m.group(1).startswith('Initialize'):
                    init = m.group(1)
                window = (window + [l])[-12:]
                m = rx.match(l)
                me = rxe.match(l)
                if m:
                    vals = [self._val(g) for g in m.groups()]
                elif me:
                    # RegObjTable: the count is the WORD at the third operand
                    # (the macro does `ldw_da xwa, (<addr>)`)
                    vals = [self._val(g) for g in me.groups()]
                    count_at = vals[2]
                    vals[2] = self.u16(vals[2]) if vals[2] is not None and self.inrom(vals[2]) else None
                elif re.match(r'^\s*call\s+RegisterObjectTable\b', l):
                    vals = self._expanded(window)
                    if vals is None:
                        continue
                else:
                    continue
                cls, proc, cnt, tab, slot = vals
                if None in (cls, cnt, tab, slot):
                    continue
                self.regs.append(dict(cls=cls, proc=proc, count=cnt, table=tab, slot=slot,
                                      init=init, file=os.path.relpath(f, ROOT), line=i + 1,
                                      count_at=count_at if me else self._count_at))
                count_at = None

    def _expanded(self, w):
        txt = [x.split(';')[0].strip() for x in w]
        cls = proc = cnt = tab = slot = None
        self._count_at = None
        for j, t in enumerate(txt):
            m = re.match(r'^ld\s+XWA,\s*(0x0160[0-9a-fA-F]{4})$', t, re.I)
            if m:
                cls = int(m.group(1), 16)
            m = re.match(r'^lda\s+xwa,\s*\(([^:)]+):24\)$', t, re.I)
            if m and j + 1 < len(txt):
                nxt = txt[j + 1].replace(' ', '').lower()
                if nxt == 'ld(xbc+0x04),xwa':
                    proc = self._val(m.group(1))
                elif nxt == 'ld(xbc+0x0a),xwa':
                    tab = self._val(m.group(1))
            m = re.match(r'^ldw\s+\(XBC\+0x08\),\s*(\S+)$', t, re.I)
            if m:
                cnt = self._val(m.group(1))
            m = re.match(r'^ld\s+wa,\s*\(([^:)]+):24\)$', t, re.I)
            if m and j + 1 < len(txt) and txt[j + 1].replace(' ', '').lower() == 'ld(xbc+0x08),wa':
                a = self._val(m.group(1))
                cnt = self.u16(a) if a is not None and self.inrom(a) else None
                self._count_at = a
            m = re.match(r'^(?:ldw\s+WA,\s*(\S+)|ld\s+wa,\s*(\d+):i3)$', t, re.I)
            if m:
                slot = self._val(m.group(1) or m.group(2))
        if cls is None:
            return None
        return cls, proc, cnt, tab, slot

    # ------------------------------------------------------------------- rom
    def u8(self, a):
        return self.rom[a - BASE]

    def u16(self, a):
        return int.from_bytes(self.rom[a - BASE:a - BASE + 2], 'little')

    def u32(self, a):
        return int.from_bytes(self.rom[a - BASE:a - BASE + 4], 'little')

    def inrom(self, a):
        return BASE <= a < BASE + len(self.rom)

    def entries(self, r):
        return [self.u32(r['table'] + 4 * k) for k in range(r['count'])] \
            if self.inrom(r['table']) else []

    def _index(self):
        self.classes = {}
        for r in self.regs:
            name = CLASS.get(r['cls'])
            if not name or not self.inrom(r['table']):
                continue
            self.addr.setdefault(r['table'], []).append(('table', r, None))
            if name == 'Class':
                for k in range(r['count']):
                    a = r['table'] + 24 * k
                    c = dict(addr=a, proc=self.u32(a), parent=self.u32(a + 4),
                             allsize=self.u16(a + 8), selfsize=self.u16(a + 10),
                             name_p=self.u32(a + 12), sig_p=self.u32(a + 16),
                             pn_p=self.u32(a + 20), slot=r['slot'], k=k, reg=r)
                    c['name'] = self.string_at(c['name_p']) if self.inrom(c['name_p']) else ''
                    c['sig'] = self.string_at(c['sig_p']) if self.inrom(c['sig_p']) else ''
                    self.classes[((r['slot'] & 0xFFF) << 16) | k] = c
                    self.addr.setdefault(a, []).append(('classdef', r, k))
                    for key, kind in (('name_p', 'classname'), ('sig_p', 'classsig'),
                                      ('pn_p', 'propnames')):
                        if self.inrom(c[key]):
                            self.addr.setdefault(c[key], []).append((kind, r, k))
                    # the propname block: len(propdata) + 1 pointers -- one
                    # field-name string per own field, the last one pointing
                    # at an empty string -- followed by the strings.  Only
                    # the block START is indexed; its strings are inside it.
                    c['pn_count'] = len(c['sig']) + 1
                    c['fields'] = [self.string_at(self.u32(c['pn_p'] + 4 * i))
                                   for i in range(c['pn_count'])] if self.inrom(c['pn_p']) else []
                continue
            for k, e in enumerate(self.entries(r)):
                if name == 'Viewable':
                    self.addr.setdefault(e, []).append(('record', r, k))
                elif name in ('ResName', 'ResEvent', 'ResMethod') or r['slot'] >= 0x400:
                    self.addr.setdefault(e, []).append(('name', r, k))

    def class_fields(self, c):
        """[(offset, name, sigchar)] of every field of class c, inherited
        first (Object contributes no prefix)."""
        chain = []
        while c is not None:
            chain.append(c)
            p = c['parent']
            c = self.klass(p) if p not in (0xFFFFFFFF, 0x01600000) else None
        out, off = [], 0
        for c in reversed(chain):
            for ch, name in zip(c['sig'], c['fields']):
                out.append((off, name, ch))
                off += SIG_SIZE.get(ch, 0)
        return out

    def strlen_even(self, a):
        n = 0
        while self.inrom(a + n) and self.u8(a + n) != 0:
            n += 1
        n += 1
        return n + (n & 1)

    def extent(self, kind, r, k, a):
        """Byte length of the object of `kind` starting at `a` (0 = unknown)."""
        if kind == 'record':
            c = self.record_class(a)
            return c['allsize'] if c else 0
        if kind in ('name', 'classname', 'classsig', 'text'):
            return self.strlen_even(a)
        if kind == 'table':
            return (24 if r['cls'] == 0x1600004 else 4) * r['count']
        if kind == 'classdef':
            return 24
        if kind == 'propnames':
            c = self.classes.get(((r['slot'] & 0xFFF) << 16) | k)
            n = c['pn_count']
            end = a + 4 * n
            for i in range(n):
                t = self.u32(a + 4 * i)
                if a <= t < a + 4 * n + 256:
                    end = max(end, t + self.strlen_even(t))
            return end - a
        return 0

    def index_texts(self):
        """Index the strings the widget records' `X` fields point at
        (str, title, caption, name...) as ('text', reg, k) with the field name
        in self.text_field[addr]."""
        self.text_field = {}
        for a, vs in list(self.addr.items()):
            for kind, r, k in vs:
                if kind != 'record' or not self.inrom(a):
                    continue
                c = self.record_class(a)
                if not c:
                    continue
                for off, fname, ch in self.class_fields(c):
                    if ch != 'X':
                        continue
                    t = self.u32(a + off)
                    if self.inrom(t) and t != a:
                        self.addr.setdefault(t, []).append(('text', r, k))
                        self.text_field.setdefault(t, []).append((c['name'], fname, k))

    def klass(self, cid):
        """The class definition for a class id 0x016S_KKKK: table of Class
        slot 0x16S (ClassProc: `srl 16; and 0xFFF` -> registry slot), entry
        KKKK (x 24 bytes)."""
        return self.classes.get((((cid >> 16) & 0xFFF) << 16) | (cid & 0xFFFF))

    def record_class(self, a):
        return self.klass(self.u32(a)) if self.inrom(a) else None

    # --------------------------------------------------------------- checks
    def check_links(self, r):
        """For a Viewable table: (n_records, bad_list)."""
        el = self.entries(r)
        bad = []
        for k, a in enumerate(el):
            h = self.rom[a - BASE:a - BASE + 4] if self.inrom(a) else b''
            if len(h) < 4 or h[1] != 0 or h[2] & 0xF0 != 0x60 or h[3] != 1:
                bad.append((k, 'header'))
                continue
            par, child, nxt, prv = (self.u16(a + o) for o in (4, 6, 8, 10))
            for x, what in ((par, 'parent'), (child, 'child'), (nxt, 'next'), (prv, 'prev')):
                if x != NONE and not (0 <= x < len(el)):
                    bad.append((k, what + ' range'))
            if nxt != NONE and nxt < len(el) and self.u16(el[nxt] + 10) != k:
                bad.append((k, 'next.prev'))
            if prv != NONE and prv < len(el) and self.u16(el[prv] + 8) != k:
                bad.append((k, 'prev.next'))
            if child != NONE and child < len(el) and self.u16(el[child] + 4) != k:
                bad.append((k, 'child.parent'))
        return len(el), bad

    def name_of(self, a):
        i = bisect.bisect_right(self.revaddr, a) - 1
        return self.rev[i] if i >= 0 else (None, None)

    def describe_reg(self, r):
        name = CLASS.get(r['cls'], hex(r['cls']))
        return ('%s table at 0x%06X, %d entries, slot 0x%X, registered by %s (%s:%d)'
                % (name, r['table'], r['count'], r['slot'], r['init'], r['file'], r['line']))

    def string_at(self, a, n=40):
        b = self.rom[a - BASE:a - BASE + n]
        return b.split(b'\0')[0].decode('latin-1')

    def in_range(self, lo, hi):
        """Every indexed address in [lo, hi), sorted."""
        return sorted((a, v) for a, v in self.addr.items() if lo <= a < hi)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('version', nargs='?', default='v10')
    ap.add_argument('--at', type=lambda x: int(x, 0))
    ap.add_argument('--range', nargs=2, type=lambda x: int(x, 0))
    ap.add_argument('--classes', action='store_true',
                    help='every class: id, name, parent, sizes, fields at their offsets')
    ap.add_argument('--check-classes', action='store_true',
                    help='assert the class-system invariants; non-zero exit on failure')
    a = ap.parse_args()
    m = Map(a.version)
    if a.classes or a.check_classes:
        bad = 0
        for cid in sorted(m.classes):
            c = m.classes[cid]
            p = m.klass(c['parent']) if c['parent'] != 0xFFFFFFFF else None
            # Object (0x01600000, allsize 2) is the root and contributes no
            # prefix: its direct children have allsize == selfsize
            base = p['allsize'] if p and c['parent'] != 0x01600000 else 0
            off, fl = base, []
            for ch, fname in zip(c['sig'], c['fields']):
                fl.append('+%d %s:%s' % (off, fname, ch))
                off += SIG_SIZE.get(ch, 0)
            ok_self = sum(SIG_SIZE.get(ch, 0) for ch in c['sig']) in (c['selfsize'], c['selfsize'] - 1)
            ok_all = (p is None) or base + c['selfsize'] == c['allsize']
            ok_pn = len(c['fields']) == len(c['sig']) + 1 and c['fields'][-1] == ''
            if not (ok_self and ok_pn):
                bad += 1
                print('  inconsistent: %s propdata %r selfsize %d fields %r'
                      % (c['name'], c['sig'], c['selfsize'], c['fields']))
            if a.classes:
                print('0x%03X:%-3d %-22s parent %-18s all %3d self %3d  %s%s' % (
                    cid >> 16, cid & 0xFFFF, c['name'], p['name'] if p else '-',
                    c['allsize'], c['selfsize'], ', '.join(fl),
                    '' if ok_all else '   [allsize != parent.allsize + selfsize]'))
        n_all = sum(1 for c in m.classes.values() if c['parent'] != 0xFFFFFFFF and
                    m.klass(c['parent']) and
                    (0 if c['parent'] == 0x01600000 else m.klass(c['parent'])['allsize'])
                    + c['selfsize'] == c['allsize'])
        recs = sorted({x for x, vs in m.addr.items() for kind, r, k in vs
                       if kind == 'record' and m.inrom(x)})
        unres = sum(1 for x in recs if m.record_class(x) is None)
        short = sum(1 for i, x in enumerate(recs[:-1])
                    if m.record_class(x) and recs[i + 1] - x < m.record_class(x)['allsize'])
        print('%s: %d classes in %d Class tables; propdata sizes / propname blocks '
              'inconsistent: %d; allsize == parent.allsize (0 for Object) + selfsize: %d of %d with a '
              'resolvable parent; widget records: %d in ROM, %d with an unresolvable '
              'class, %d closer to the next record than their allsize'
              % (a.version, len(m.classes), sum(1 for r in m.regs if r['cls'] == 0x1600004),
                 bad, n_all, sum(1 for c in m.classes.values()
                                 if c['parent'] != 0xFFFFFFFF and m.klass(c['parent'])),
                 len(recs), unres, short))
        if a.check_classes and (bad or unres or short):
            sys.exit(1)
        return
    if a.at is not None:
        for kind, r, k in m.addr.get(a.at, []):
            print('%s %s of %s' % (kind, k, m.describe_reg(r)))
        return
    if a.range:
        for addr, vs in m.in_range(*a.range):
            for kind, r, k in vs:
                extra = ''
                if kind == 'record':
                    extra = 'type 0x%02X' % m.u8(addr)
                elif kind == 'name':
                    extra = repr(m.string_at(addr))
                print('0x%06X %-6s k=%-4s slot 0x%-4X %-10s %s' % (
                    addr, kind, k, r['slot'], CLASS.get(r['cls'], '?'), extra))
        return
    for r in sorted(m.regs, key=lambda r: r['table']):
        extra = ''
        if r['cls'] == 0x1600010:
            n, bad = m.check_links(r)
            extra = '  links: %d records, %d inconsistencies' % (n, len(bad))
        print(m.describe_reg(r) + extra)


if __name__ == '__main__':
    main()
