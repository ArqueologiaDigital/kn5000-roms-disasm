#!/usr/bin/env python3
r"""ext_retype_span.py -- re-express a byte range of v10 extensions/extension_data.s as typed items.

QUESTION ANSWERED
-----------------
"Given the v10 line map, rewrite exactly the source lines that emit
[lo, hi) so that the bytes come out as the typed items I specify -- keeping
every label at its address and every comment line and every non-emitting directive line (`.set`,
`.macro` blocks) of the span -- and fill
whatever the items do not cover with `.byte` rows."  It is the mechanical
half of each retyping step of the `ext` lane (2026-09-25); the byte gate is
the certification, and this helper refuses rather than guess when a label
would land inside an item or the span does not start/end on line
boundaries.

USE (as a module)
    from ext_retype_span import load, retype, save
    L, m, rom = load()
    retype(L, m, rom, lo, hi, {addr: (size, ["\tline", ...]), ...}, header=[...])
    save(L)
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "v10/maincpu/extensions/extension_data.s")
BASE = 0xE00000
LABEL = re.compile(r'^([A-Za-z_]\w*):')


def load(mapfile):
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    m = json.load(open(mapfile))["extensions/extension_data.s"]
    rom = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    return L, m, rom


def save(L):
    open(SRC, "wb").write("\n".join(L).encode("latin-1"))


def byte_rows(b, per=16):
    return ["\t.byte " + ", ".join("0x%02x" % x for x in b[k:k + per]) for k in range(0, len(b), per)]


def retype(L, m, rom, lo, hi, items, header=None, keep_labels=True):
    span = [x for x in m if lo <= x[1] < hi and x[2] != 0]
    if not span or span[0][1] != lo or span[-1][1] + span[-1][2] != hi:
        raise SystemExit("span 0x%06X-0x%06X is not on line boundaries" % (lo, hi))
    l0, l1 = span[0][0], span[-1][0]
    # extend upward over label-only lines that sit directly on lo
    while l0 - 2 >= 0 and LABEL.match(L[l0 - 2]) and not L[l0 - 2].split(":", 1)[1].strip():
        l0 -= 1
    addr_of = {}
    for lno, a, sz, _ in m:
        addr_of[lno] = a
    comments, labels = [], {}
    pending = []
    for i in range(l0 - 1, l1):
        ln = L[i]
        s = ln.strip()
        if s.startswith(";"):
            comments.append(ln)
            continue
        mm = LABEL.match(ln)
        if mm:
            rest = ln.split(":", 1)[1].strip()
            if rest and not rest.startswith(";"):
                labels.setdefault(addr_of[i + 1], []).append(mm.group(1))
            else:
                pending.append(mm.group(1))
            continue
        if s and (i + 1) in addr_of:
            for p in pending:
                labels.setdefault(addr_of[i + 1], []).append(p)
            pending = []
        elif s:
            # a line that emits nothing and is no label -- a `.set`, or a
            # `.macro` .. `.endm` block: keep it, in order, with the comments
            # (a first version dropped a whole .macro definition this way; the
            # assembler caught it)
            comments.append(ln)
    for p in pending:
        labels.setdefault(hi, []).append(p)
    for la in labels:
        for a, (sz, _) in items.items():
            if a < la < a + sz:
                raise SystemExit("label %s at 0x%06X falls inside item 0x%06X+%d" % (labels[la], la, a, sz))
    out = list(header or []) + comments
    a = lo
    stops = sorted(set(list(items) + list(labels) + [hi]))
    while a < hi:
        if keep_labels:
            for nm in labels.get(a, []):
                out.append(nm + ":")
        if a in items:
            sz, lines = items[a]
            out.extend(lines)
            a += sz
            continue
        nxt = min(s for s in stops if s > a)
        out.extend(byte_rows(rom[a - BASE:nxt - BASE]))
        a = nxt
    for nm in labels.get(hi, []):
        out.append(nm + ":")
    L[l0 - 1:l1] = out
    return l0, l1, len(out)
