#!/usr/bin/env python3
r"""naka_c_model.py -- parse, edit and re-emit the auto-generated NAKA blob C sources.

QUESTION ANSWERED
-----------------
The NAKA blob sources (`v10/maincpu/ui_widgets/naka_*.c`, generated long ago by
`scripts/converters/naka_struct_decode.py`) describe each ROM blob as ONE packed
struct whose members are mostly anonymous `uint16_t field_XXXX` words, with one
designated initializer per member.  To give an object inside such a blob a real
type (a bitmap as `uint8_t [H][W]`, a string as `char []`, a fill run as an
explicit fill array) the member run covering it has to be replaced, in the
struct AND in the initializer, without disturbing anything else and without
changing one compiled byte.

This module is that edit, done structurally rather than by text substitution:

  * parse the struct into members (type, name, dims, size, OFFSET) and the
    comment blocks between them;
  * parse the initializer into one designated entry per member;
  * `retype(start, end, new_members)` swaps the members covering exactly
    [start, end) for new ones, splitting a boundary `uint16_t field_XXXX` into
    two bytes when an object starts or ends mid-word;
  * every `SELF(member)` in the file that named a removed member is rewritten
    to the new member (with an array subscript for interior targets), so the
    blob's self-pointers keep their values symbolically;
  * any removed member whose initializer was SYMBOLIC (NAKA_ADDR / SELF / an
    extern) is reported: the caller must either preserve it in the new typing
    or explicitly declare it a false pointer (a value that happens to equal an
    address, e.g. pixel bytes 00 00 FF 00 read as `0x00FF0000`).

Values for the new members come from the COMPILED blob (`includes/generated/
<name>.bin` built from the unmodified source), so the new text is derived from
the bytes, not typed by hand.  The byte gate (`make gate`) certifies the result.

Self-checks on parse: every `field_XXXX` member must sit at offset 0xXXXX, and
the summed member sizes must equal the `_Static_assert` size.

This is a library; the driver is `naka_c_retype.py`.
"""
import re

TYPE_SIZES = {
    'uint8_t': 1, 'int8_t': 1, 'char': 1,
    'uint16_t': 2, 'int16_t': 2,
    'uint32_t': 4, 'int32_t': 4,
    'naka_header_t': 4, 'naka_dispatch_t': 24, 'naka_container_t': 42,
    'naka_menu_item_t': 54, 'naka_label_t': 32, 'naka_group_t': 26,
    'naka_slider_t': 44, 'naka_type_0x48_t': 26,
    'accseq_part_t': 16, 'accseq_record_t': 32, 'naka_class_t': 24,
}

MEMBER_RE = re.compile(
    r'^(\s*)((?:const\s+)?[A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)'
    r'((?:\[[^\]]+\])*)\s*;(.*)$')
STRUCT_START_RE = re.compile(r'^typedef struct __attribute__\(\(packed\)\) \{\s*$')
STRUCT_END_RE = re.compile(r'^\} (naka_[A-Za-z0-9_]+_t);\s*$')
INIT_START_RE = re.compile(r'^const (naka_[A-Za-z0-9_]+_t) ([A-Za-z0-9_]+)\s*$')
SIZE_ASSERT_RE = re.compile(r'_Static_assert\(sizeof\((naka_[A-Za-z0-9_]+_t)\) == (\d+)')
SELF_RE = re.compile(r'SELF\(\s*([A-Za-z_][A-Za-z0-9_]*)((?:\[[^\]]*\])*)\s*\)')
SYMBOLIC_RE = re.compile(r'NAKA_ADDR\(|SELF\(|NAKA_SELF\(')


def _eval_dim(d):
    d = d.strip()
    m = re.fullmatch(r'NAKA_STR_ALLOC\((\d+)\)', d)
    if m:
        n = int(m.group(1))
        return (n + 2) & ~1
    return int(d, 0)


class Member:
    __slots__ = ('indent', 'ctype', 'name', 'dims', 'tail', 'size', 'offset',
                 'pre')

    def __init__(self, indent, ctype, name, dims, tail, pre):
        self.indent, self.ctype, self.name, self.dims = indent, ctype, name, dims
        self.tail, self.pre = tail, pre       # pre: comment/blank lines before it
        n = TYPE_SIZES[ctype.replace('const ', '')]
        for d in re.findall(r'\[([^\]]+)\]', dims):
            n *= _eval_dim(d)
        self.size = n
        self.offset = None

    def decl(self):
        return '%s%s %s%s;%s' % (self.indent, self.ctype, self.name, self.dims,
                                 self.tail)


class Entry:
    """One designated initializer: `pre` is everything (blank lines, comments)
    between the previous entry's comma and this entry's `.name`; `expr` is the
    text after `=` up to (not including) the top-level comma."""
    __slots__ = ('name', 'pre', 'expr')

    def __init__(self, name, pre, expr):
        self.name, self.pre, self.expr = name, pre, expr

    def text(self):
        return '%s.%s = %s,' % (self.pre, self.name, self.expr)


def split_top_level(body):
    """Split an initializer body at top-level commas, respecting strings,
    char literals, comments and brackets.  Returns the list of chunks (the
    last chunk is whatever trails the final comma)."""
    out, cur, depth, i, n = [], [], 0, 0, len(body)
    while i < n:
        c = body[i]
        if c == '/' and i + 1 < n and body[i + 1] == '*':
            j = body.index('*/', i + 2) + 2
            cur.append(body[i:j]); i = j; continue
        if c == '/' and i + 1 < n and body[i + 1] == '/':
            j = body.find('\n', i)
            j = n if j < 0 else j
            cur.append(body[i:j]); i = j; continue
        if c in '"\'':
            j = i + 1
            while body[j] != c:
                j += 2 if body[j] == '\\' else 1
            cur.append(body[i:j + 1]); i = j + 1; continue
        if c in '({[':
            depth += 1
        elif c in ')}]':
            depth -= 1
        if c == ',' and depth == 0:
            out.append(''.join(cur)); cur = []; i += 1; continue
        cur.append(c); i += 1
    out.append(''.join(cur))
    return out


class CBlob:
    def __init__(self, path):
        self.path = path
        with open(path, encoding='latin-1') as f:
            self.lines = f.read().split('\n')
        L = self.lines
        self.s0 = next(i for i, l in enumerate(L) if STRUCT_START_RE.match(l))
        self.s1 = next(i for i in range(self.s0, len(L)) if STRUCT_END_RE.match(L[i]))
        self.tname = STRUCT_END_RE.match(L[self.s1]).group(1)
        # members
        self.members, pre = [], []
        for ln in L[self.s0 + 1:self.s1]:
            m = MEMBER_RE.match(ln)
            if m and not ln.lstrip().startswith(('/*', '*')):
                ind, ct, nm, dims, tail = m.groups()
                self.members.append(Member(ind, ct, nm, dims, tail, pre))
                pre = []
            else:
                pre.append(ln)
        self.struct_trailer = pre           # lines after the last member
        off = 0
        for mb in self.members:
            mb.offset = off
            off += mb.size
        self.size = off
        txt = '\n'.join(L)
        m = SIZE_ASSERT_RE.search(txt)
        if not m or int(m.group(2)) != self.size:
            raise SystemExit('%s: member sizes sum to %d, _Static_assert says %s'
                             % (path, self.size, m and m.group(2)))
        for mb in self.members:
            fm = re.fullmatch(r'field_([0-9a-f]{4,5})', mb.name)
            if fm and int(fm.group(1), 16) != mb.offset:
                raise SystemExit('%s: %s sits at 0x%x' % (path, mb.name, mb.offset))
        # initializer
        self.i0 = next(i for i in range(self.s1, len(L)) if INIT_START_RE.match(L[i]))
        assert L[self.i0 + 1].rstrip().endswith('= {'), L[self.i0 + 1]
        self.i1 = next(i for i in range(len(L) - 1, self.i0, -1) if L[i] == '};')
        body = '\n'.join(L[self.i0 + 2:self.i1])
        chunks = split_top_level(body)
        self.init_trailer = chunks.pop()      # text after the last comma
        self.entries = []
        for ch in chunks:
            m = re.match(r'^(.*?)\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', ch, re.S)
            if not m:
                raise SystemExit('%s: unparsable initializer chunk %r' % (path, ch[:200]))
            self.entries.append(Entry(m.group(2), m.group(1), m.group(3)))
        names = [e.name for e in self.entries]
        if names != [mb.name for mb in self.members]:
            bad = next(i for i, (a, b) in enumerate(zip(names, [mb.name for mb in self.members])) if a != b)
            raise SystemExit('%s: initializer order diverges from struct at #%d (%s vs %s)'
                             % (path, bad, names[bad], self.members[bad].name))
        self.by_name = {mb.name: k for k, mb in enumerate(self.members)}
        self.dropped_tails = []     # (member, trailing comment) of removed members

    # ------------------------------------------------------------------ query
    def index_at(self, off):
        lo, hi = 0, len(self.members)
        while lo < hi:
            mid = (lo + hi) // 2
            if self.members[mid].offset <= off:
                lo = mid + 1
            else:
                hi = mid
        return lo - 1

    def member_at(self, off):
        return self.members[self.index_at(off)]

    def elements(self, name):
        """Initializer element texts of a 1-D array member (comments that
        precede an element stay attached to it)."""
        e = self.entries[self.by_name[name]].expr.strip()
        assert e.startswith('{') and e.endswith('}'), (name, e[:60])
        items = split_top_level(e[1:-1])
        if items and not items[-1].strip():
            items.pop()
        return [' '.join(x.split()) for x in items]

    # ------------------------------------------------------------------ edits
    def split_word(self, off, blob):
        """Make `off` a member boundary.  The member containing it must have a
        purely numeric initializer (no NAKA_ADDR/SELF) and must not be a SELF
        target; it is replaced by two byte pieces whose values come from the
        compiled blob, so no information is lost."""
        k = self.index_at(off)
        mb = self.members[k]
        if mb.offset == off:
            return
        e = self.entries[k]
        if SYMBOLIC_RE.search(e.expr):
            raise SystemExit('%s: refusing to split symbolic %s %s%s at +0x%x'
                             % (self.path, mb.ctype, mb.name, mb.dims, off))
        if mb.name in self.self_targets():
            raise SystemExit('%s: %s is a SELF target, not splitting' % (self.path, mb.name))
        pieces = []
        for a, b in ((mb.offset, off), (off, mb.offset + mb.size)):
            n = b - a
            if n == 1:
                p = Member(mb.indent, 'uint8_t', 'field_%04x' % a, '', '', [])
                ex = '0x%02X' % blob[a]
            else:
                p = Member(mb.indent, 'uint8_t', 'bytes_%04x' % a, '[%d]' % n, '', [])
                ex = '{ ' + ', '.join('0x%02X' % x for x in blob[a:b]) + ' }'
            p.offset = a
            pieces.append((p, ex))
        pieces[0][0].pre = mb.pre
        self.members[k:k + 1] = [p for p, _ in pieces]
        self.entries[k:k + 1] = [Entry(pieces[0][0].name, e.pre, pieces[0][1]),
                                 Entry(pieces[1][0].name, '\n\n    ', pieces[1][1])]
        self._reindex()

    def _reindex(self):
        self.by_name = {mb.name: k for k, mb in enumerate(self.members)}

    def self_targets(self):
        """name -> list of (subscripts) used in SELF(...) anywhere in the file."""
        out = {}
        for e in self.entries:
            for m in SELF_RE.finditer(e.expr):
                out.setdefault(m.group(1), []).append(m.group(2))
        return out

    def retype(self, start, end, new, blob, false_pointers=(), note=None):
        """Replace the members covering [start, end) by `new`, a list of
        (Member, expr, pre) triples or NewMember objects (see below).
        `false_pointers`: removed members allowed to carry a symbolic value
        because the bytes are proven not to be a pointer."""
        self.split_word(start, blob)
        if end < self.size:
            self.split_word(end, blob)
        k0 = self.index_at(start)
        k1 = self.index_at(end - 1)
        if self.members[k0].offset != start:
            raise SystemExit('%s: +0x%x is inside %s' % (self.path, start, self.members[k0].name))
        last = self.members[k1]
        if last.offset + last.size != end:
            raise SystemExit('%s: +0x%x is inside %s' % (self.path, end, last.name))
        gone = self.members[k0:k1 + 1]
        gone_e = self.entries[k0:k1 + 1]
        size = sum(nm.size for nm in new)
        if size != end - start:
            raise SystemExit('%s: new members total %d B for a %d B region'
                             % (self.path, size, end - start))
        # symbolic values being dropped
        dropped = []
        for mb, e in zip(gone, gone_e):
            if SYMBOLIC_RE.search(e.expr):
                dropped.append((mb, e))
        fp = set(false_pointers)
        bad = [(mb.name, e.expr.strip()) for mb, e in dropped
               if mb.name not in fp and not any(nm.keeps(mb.name) for nm in new)]
        if bad:
            raise SystemExit('%s: region +0x%x..+0x%x drops symbolic initializers %s'
                             % (self.path, start, end, bad[:8]))
        # comment blocks that were inside the region must survive
        kept_pre = []
        for mb in gone:
            kept_pre += [l for l in mb.pre if l.strip()]
        # SELF targets inside the region
        targets = self.self_targets()
        remap = {}
        off = start
        placed = []
        for nm in new:
            nm.offset = off
            placed.append(nm)
            off += nm.size
        for mb in gone:
            if mb.name in targets:
                for sub in targets[mb.name]:
                    if sub:
                        raise SystemExit('%s: SELF(%s%s) into a retyped region'
                                         % (self.path, mb.name, sub))
                owner = next(nm for nm in placed
                             if nm.offset <= mb.offset < nm.offset + nm.size)
                remap[mb.name] = owner.designator(mb.offset - owner.offset)
        # build replacement members/entries
        new_members, new_entries = [], []
        first = True
        for nm in placed:
            pre = list(gone[0].pre) if first else []
            pre += nm.pre_lines
            mbr = Member('    ', nm.ctype, nm.name, nm.dims, nm.tail, pre)
            mbr.offset = nm.offset
            if mbr.size != nm.size:
                raise SystemExit('%s: %s declared size %d, computed %d'
                                 % (self.path, nm.name, nm.size, mbr.size))
            new_members.append(mbr)
            new_entries.append(Entry(nm.name, gone_e[0].pre if first else '\n\n    ',
                                     nm.expr))
            first = False
        # comments that belonged to removed members (other than the first,
        # whose `pre` was carried) are kept in front of the first new member;
        # likewise comments inside removed initializer entries
        lost = []
        for mb in gone[1:]:
            lost += [l for l in mb.pre if l.strip()]
        init_lost = [e.pre.strip() for e in gone_e[1:] if e.pre.strip()]
        if init_lost:
            new_entries[0].pre = new_entries[0].pre.rstrip(' ') + \
                '\n    '.join(init_lost) + '\n    '
        for mb in gone:
            if '/*' in mb.tail or '//' in mb.tail:
                self.dropped_tails.append((mb.name, mb.tail.strip()))
        if lost:
            new_members[0].pre = new_members[0].pre[:len(gone[0].pre)] + lost + \
                new_members[0].pre[len(gone[0].pre):]
        self.members[k0:k1 + 1] = new_members
        self.entries[k0:k1 + 1] = new_entries
        self._reindex()
        if remap:
            for e in self.entries:
                e.expr = SELF_RE.sub(
                    lambda m: 'SELF(%s)' % remap[m.group(1)] if m.group(1) in remap
                    else m.group(0), e.expr)
        return [mb.name for mb, _ in dropped], remap

    def base(self):
        m = re.search(r'^#define BASE\s+(0x[0-9A-Fa-f]+)u?\s*$', '\n'.join(self.lines), re.M)
        return int(m.group(1), 16)

    def symbolize_self_pointers(self, names):
        """In every uint32_t member's initializer, replace a numeric literal
        that equals BASE + offset(name) for one of `names` by SELF(name).
        Returns the number of replacements.  Only whole-object starts are
        matched, and only inside uint32_t members, so pixel or text bytes can
        never be rewritten."""
        base = self.base()
        want = {}
        for n in names:
            mb = self.members[self.by_name[n]]
            want[base + mb.offset] = n
        count = 0
        for mb, e in zip(self.members, self.entries):
            if mb.ctype != 'uint32_t':
                continue
            def sub(m):
                nonlocal count
                v = int(m.group(0), 16)
                if v in want:
                    count += 1
                    return 'SELF(%s)' % want[v]
                return m.group(0)
            e.expr = re.sub(r'\b0x[0-9A-Fa-f]{8}\b', sub, e.expr)
        return count

    # ------------------------------------------------------------------ write
    def render(self):
        L = self.lines
        out = L[:self.s0 + 1]
        for mb in self.members:
            out += mb.pre
            out.append(mb.decl())
        out += self.struct_trailer
        out += L[self.s1:self.i0 + 2]
        body = ''.join(e.text() for e in self.entries) + self.init_trailer
        out += body.split('\n')
        out += L[self.i1:]
        return '\n'.join(out)

    def write(self, path=None):
        with open(path or self.path, 'w', encoding='latin-1', newline='') as f:
            f.write(self.render())


# ------------------------------------------------------------ new member kinds
def c_char(b):
    if b == 0x22:
        return '\\"'
    if b == 0x5C:
        return '\\\\'
    if 0x20 <= b <= 0x7E:
        return chr(b)
    return '\\x%02X' % b


def c_string(bs):
    """A C string literal for bytes `bs`; hex escapes are closed off with
    `" "` when the next character is a hex digit."""
    out, prev_hex = [], False
    for b in bs:
        s = c_char(b)
        if prev_hex and s[0] in '0123456789abcdefABCDEF':
            out.append('" "')
        out.append(s)
        prev_hex = s.startswith('\\x')
    return '"' + ''.join(out) + '"'


class NewMember:
    """A typed replacement member.  `expr` is its initializer text."""
    absorbs_comments = False

    def __init__(self, ctype, name, dims, size, expr, pre_lines=(), tail='',
                 keeps=()):
        self.ctype, self.name, self.dims, self.size = ctype, name, dims, size
        self.expr, self.pre_lines, self.tail = expr, list(pre_lines), tail
        self._keeps = set(keeps)
        self.offset = None

    def keeps(self, old_name):
        return old_name in self._keeps

    def designator(self, rel):
        if rel == 0:
            return self.name
        if self.dims == '':
            if rel:
                raise SystemExit('SELF into the middle of scalar %s' % self.name)
            return self.name
        dims = [_eval_dim(d) for d in re.findall(r'\[([^\]]+)\]', self.dims)]
        esz = self.size
        for d in dims:
            esz //= d
        if rel % esz:
            raise SystemExit('SELF into the middle of an element of %s' % self.name)
        idx, k = [], rel // esz
        for d in reversed(dims):
            idx.append(k % d)
            k //= d
        return self.name + ''.join('[%d]' % i for i in reversed(idx))


def comment_block(text, width=76):
    """`text` (already wrapped lines) -> a C block comment, 4-space indent."""
    lines = ['    /* ' + '-' * (width - 7)]
    for t in text.split('\n'):
        lines.append(('     * ' + t).rstrip())
    lines.append('     * ' + '-' * (width - 7) + ' */')
    return lines


def bytes_member(name, data, pre=(), per_line=16, tail=''):
    body = []
    for i in range(0, len(data), per_line):
        body.append('        ' + ', '.join('0x%02X' % b for b in data[i:i + per_line]) + ',')
    expr = '{\n' + '\n'.join(body) + '\n    }'
    return NewMember('uint8_t', name, '[%d]' % len(data), len(data), expr, pre, tail)


def bitmap_member(name, data, width, height, stride, pre=(), per_line=None):
    """uint8_t name[height][stride], one row per line (split every
    `per_line` values when a row is long)."""
    assert len(data) == height * stride, (name, len(data), height, stride)
    per_line = per_line or stride
    rows = []
    for y in range(height):
        row = data[y * stride:(y + 1) * stride]
        chunks = [', '.join('0x%02X' % b for b in row[i:i + per_line])
                  for i in range(0, stride, per_line)]
        if len(chunks) == 1:
            rows.append('        /* %3d */ { %s },' % (y, chunks[0]))
        else:
            rows.append('        /* %3d */ {' % y)
            rows += ['            %s,' % c for c in chunks]
            rows.append('        },')
    expr = '{\n' + '\n'.join(rows) + '\n    }'
    return NewMember('uint8_t', name, '[%d][%d]' % (height, stride), height * stride,
                     expr, pre)


def fill_member(name, n, value, pre=(), tail=''):
    assert n >= 1
    if value == 0:
        expr = '{ 0 }'
    else:
        expr = '{ [0 ... %d] = 0x%02X }' % (n - 1, value)
    return NewMember('uint8_t', name, '[%d]' % n, n, expr, pre, tail)


def string_member(name, data, pre=(), tail=''):
    """char name[len(data)] initialised from the exact bytes.  A trailing
    NUL is dropped from the literal when it would be the implicit one."""
    n = len(data)
    lit = data
    if lit.endswith(b'\x00'):
        lit = lit[:-1]          # the literal's own terminator supplies it
    return NewMember('char', name, '[%d]' % n, n, c_string(lit), pre, tail)
