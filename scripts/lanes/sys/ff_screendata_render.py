#!/usr/bin/env python3
r"""Re-type the ScreenData continuation at the head of storage/flash_floppy_handlers.s
from its readers: one line per record, tables as tables, a label and a reader
header on every object.

QUESTION THIS ANSWERS
    The 3,396 bytes from FlashWrite_BlockHandler_Table to InitializeNaka
    (v10/v9 0xF158A7, v7 0xF1587D) are the tail of the sound editor's ScreenData
    block (see ff_screendata_headers.py for the objects and how each is pinned).
    The source spelled them as `.byte` rows that cut records in half and, in
    places, as `.long <symbol>` where the bytes are record coordinates, not
    pointers (e.g. `.long Pad_NakaExternal_Block4` inside a {0x01, 0x0a, x1,
    y1, x2, y2} record at v10 0xF1629A).  What is the faithful typed form?

HOW
    * the seui model (vendored as se_screendata_model_seui.py) gives every
      record {u8 op, u8 len, payload[len-2]} of every list the code draws, the
      pointer tables, the boundary table, the string and box tables;
      ff_screendata_headers.Doc adds the per-variant tables pinned by hand;
    * each record becomes one `.byte op, len, ...` line (printable runs of 4+
      as `.ascii`); pointer tables `.long <label>[ + off]`; the boundary table
      `.long start, end` pairs; string tables `.ascii` rows of their width; box
      tables `.short x1, y1, x2, y2`; bytes no reader explains stay `.byte`;
    * the byte-exact C descriptors already `.incbin`'d here (lane seui's
      audio/sound_editor_screens/*.c) are kept verbatim;
    * every comment of the old lines is re-emitted at its address, every old
      label stays at its address, every object start gets its label and a
      reader header (canonical names as in ff_screendata_headers.py).
    --apply writes the file, retargets aliases (shared/positional_labels.s,
    numeric `.set`s in the root file), rebuilds the image and compares with the
    dump; a mismatch restores everything.

RUN
    python3 scripts/lanes/sys/ff_screendata_render.py --image v10 [--apply]
"""
import argparse
import bisect
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402
import ff_screendata_headers as fh  # noqa: E402

ROOT = pi.ROOT
BASE = pi.BASE
REL = fh.REL


def ascii_ok(b):
    return 0x20 <= b < 0x7f and b not in (0x22, 0x5c)


def render_bytes(bs):
    """-> list of operand groups for one record: .byte/.ascii segments"""
    out, i = [], 0
    while i < len(bs):
        j = i
        while j < len(bs) and ascii_ok(bs[j]):
            j += 1
        if j - i >= 4:
            out.append(("ascii", bs[i:j]))
            i = j
            continue
        k = i
        while k < len(bs):
            j = k
            while j < len(bs) and ascii_ok(bs[j]):
                j += 1
            if j - k >= 4:
                break
            k = j + 1 if j == k else j
        out.append(("byte", bs[i:k]))
        i = k
    return out


def seg_lines(segs):
    lines = []
    for kind, b in segs:
        if kind == "ascii":
            lines.append('\t.ascii\t"%s"' % b.decode("latin-1"))
        else:
            for q in range(0, len(b), 16):
                lines.append("\t.byte\t" + ", ".join("0x%02x" % x for x in b[q:q + 16]))
    return lines


class Render:
    def __init__(self, img):
        self.img = img
        self.D = fh.Doc(img)
        self.by = self.D.objects()
        self.order, self.syms = pi.amap(img)
        self.rom = self.D.rom
        self.lo, self.hi = self.D.lo, self.D.hi
        self.own = fh.owned_files(img)

    def region_lines(self):
        rows = [(k, e) for k, e in enumerate(self.order) if e[1] == REL]
        i0 = next(i for i, (k, e) in enumerate(rows) if e[0] is not None and e[0] >= self.lo)
        i1 = next(i for i, (k, e) in enumerate(rows) if e[0] is not None and e[0] >= self.hi)
        # the label line of InitializeNaka and anything after stays
        return rows[i0:i1]

    def run(self):
        rows = self.region_lines()
        D, lo, hi = self.D, self.lo, self.hi
        # old labels / comments / incbins by address
        labels = collections.defaultdict(list)
        notes = collections.defaultdict(list)
        incb = {}
        cur = lo
        for k, e in rows:
            labs, body, com = pi.split_line(e[3])
            a = e[0] if e[0] is not None else cur
            if e[0] is not None and e[4] > 0:
                cur = e[0] + e[4]
            t = e[3].strip()
            if t.startswith(";"):
                notes[a].append(t)
            elif com.strip():
                notes[a].append(com.strip())
            for lab in labs:
                labels[a].append(lab)
            if body.startswith(".incbin"):
                incb[e[0]] = (e[4], "\t" + body)
        # canonical names for object starts
        canon, renames, aliases, heads = {}, {}, {}, {}
        for a in sorted(self.by):
            if not (lo <= a < hi):
                continue
            here = [x for x in labels.get(a, []) if not x.startswith(".")]
            keep = [x for x in here if x in fh.KEEP_EXTERNAL or not (fh.users(x, self.img) <= self.own)]
            mine = [x for x in here if x not in keep]
            c = keep[0] if keep else D.name(a)
            for x in mine:
                renames[x] = c
            canon[a] = c
            for nm in D.byaddr.get(a, []):
                if nm not in here and nm != c:
                    aliases[nm] = c
            h = []
            for kind, size, txt, ev in self.by[a]:
                h.append("; %s" % txt)
                if ev:
                    h.append("; evidence: %s" % ", ".join(ev[:3]))
            if keep:
                h.append("; (name %s kept: other files use it; the object is ScreenData, see above)" % c)
            heads[a] = h
        # symbol for any address
        names = {}
        for v, ks in D.byaddr.items():
            ks = [k for k in ks if k not in renames and k not in aliases]
            if ks:
                names[v] = sorted(ks)[0]
        for a, c in canon.items():
            names[a] = c
        starts = sorted(set(canon) | {a for a in labels if lo <= a < hi})
        allnames = sorted(names)

        def sym(v):
            if v in names:
                return names[v]
            if lo <= v < hi:
                i = bisect.bisect_right(starts, v) - 1
                s0 = starts[i]
                base = canon.get(s0) or next(x for x in labels[s0] if not x.startswith("."))
                return "%s + 0x%x" % (base, v - s0)
            i = bisect.bisect_right(allnames, v) - 1
            if i >= 0 and BASE <= v < 0x1000000 and v - allnames[i] < 0x10000:
                # a ROM address with no label of its own: the nearest label
                # before it plus the offset (symbolic, and exact)
                return "%s + 0x%x" % (names[allnames[i]], v - allnames[i])
            return "0x%08x" % v

        # atoms: (addr, size, lines)
        atoms = {}
        for a, (n, line) in incb.items():
            atoms[a] = (n, [line])
        m = D.m
        tables = {}
        for a, roles in self.by.items():
            for kind, size, txt, ev in roles:
                if kind in ("recptrs", "vartab") and size:
                    tables[a] = ("ptr", size)
                elif kind == "pairs":
                    tables[a] = ("ptr", size)
                elif kind == "strtab":
                    o = m.objs[a]
                    tables[a] = ("str", size, o["width"])
                elif kind == "boxtab":
                    tables[a] = ("box", size)
        for a, t in tables.items():
            if a in atoms or not (lo <= a < hi):
                continue
            if t[0] == "ptr":
                lines = []
                for q in range(a, a + t[1], 4):
                    lines.append("\t.long\t%s" % sym(struct.unpack_from("<I", self.rom, q - BASE)[0]))
                atoms[a] = (t[1], lines)
            elif t[0] == "box":
                lines = []
                for q in range(a, a + t[1], 8):
                    lines.append("\t.short\t%s" % ", ".join(
                        str(struct.unpack_from("<H", self.rom, q - BASE + 2 * j)[0]) for j in range(4)))
                atoms[a] = (t[1], lines)
            elif t[0] == "str":
                w = t[2]
                lines = []
                for q in range(a, a + t[1], w):
                    ent = self.rom[q - BASE:min(q + w, a + t[1]) - BASE]
                    if all(ascii_ok(x) for x in ent):
                        lines.append('\t.ascii\t"%s"' % ent.decode("latin-1"))
                    else:
                        lines.extend(seg_lines(render_bytes(ent)))
                atoms[a] = (t[1], lines)
        for r, (op, ln, fam) in m.recs.items():
            if lo <= r < hi and r not in atoms:
                # pointer fields the interpreter dereferences (seui model):
                # static op03 +2 bitmap; bound op02/07 +7 string table;
                # bound op03/04/08 +7 box table
                off = None
                if fam == "S" and op == 0x03 and ln == 12:
                    off = 2
                elif fam == "B" and op in (0x02, 0x07, 0x03, 0x04, 0x08) and ln >= 11:
                    off = 7
                if off is not None:
                    v = struct.unpack_from("<I", self.rom, r + off - BASE)[0]
                    lines = seg_lines([("byte", self.rom[r - BASE:r + off - BASE])])
                    lines.append("\t.long\t%s" % sym(v))
                    lines += seg_lines(render_bytes(self.rom[r + off + 4 - BASE:r + ln - BASE]))
                    atoms[r] = (ln, lines)
                else:
                    atoms[r] = (ln, seg_lines(render_bytes(self.rom[r - BASE:r + ln - BASE])))
        # emit
        out = []
        a = lo
        cuts = sorted(set(atoms) | set(labels) | set(canon) | set(notes) | {hi})
        lab_cuts = sorted(set(labels) | set(canon))
        while a < hi:
            out.extend(heads.get(a, []))
            # labels at a: old ones (renamed), then the canonical one if new
            written = set()
            for x in labels.get(a, []):
                y = renames.get(x, x)
                if y not in written:
                    out.append("%s:" % y)
                    written.add(y)
            if a in canon and canon[a] not in written:
                out.append("%s:" % canon[a])
            out.extend(notes.pop(a, []))
            if a in atoms:
                n, lines = atoms[a]
                # an old label INSIDE this atom forces a split (emit as bytes up
                # to it); an old comment inside it is emitted before it
                inner = [x for x in lab_cuts if a < x < a + n]
                if inner and a not in incb:
                    nxt = inner[0]
                    out.extend(seg_lines([("byte", self.rom[a - BASE:nxt - BASE])]))
                    a = nxt
                    continue
                for x in sorted(notes):
                    if a < x < a + n:
                        out.extend(notes.pop(x))
                out.extend(lines)
                if a in incb:
                    # objects that start INSIDE a byte-exact C descriptor get a
                    # name relative to the descriptor's first label
                    here = [y for y in (renames.get(x, x) for x in labels.get(a, [])) if not y.startswith(".")]
                    anchor = canon.get(a) or (here[0] if here else None)
                    if anchor is None and any(a < x < a + n for x in canon):
                        anchor = D.name(a)          # give the descriptor a label of its own
                        out.insert(len(out) - len(lines), "%s:" % anchor)
                    for x in sorted(canon):
                        if a < x < a + n:
                            out.extend(heads.get(x, []))
                            out.append("\t.set\t%s, %s + 0x%x" % (canon[x], anchor, x - a))
                            heads.pop(x, None)
                a += n
                continue
            nxt = min(cuts[bisect.bisect_right(cuts, a)], hi)
            gap = self.rom[a - BASE:nxt - BASE]
            dw = [struct.unpack_from("<I", gap, q)[0] for q in range(0, len(gap) - 3, 4)]
            if len(gap) % 4 == 0 and dw and all(v in names for v in dw):
                # a run of exact pointers to named objects (e.g. the last two
                # entries of FlashRead_BlockHandler_Table, into the part of the
                # block in audio/sound_editor_ui.s)
                out.extend("\t.long\t%s" % names[v] for v in dw)
            else:
                out.extend(seg_lines([("byte", gap)]))
            a = nxt
        return rows, out, renames, aliases


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", type=int, default=0)
    a = ap.parse_args()
    R = Render(a.image)
    rows, out, renames, aliases = R.run()
    print("%s: region lines %d-%d -> %d lines; %d renames, %d aliases" % (
        a.image, rows[0][1][2], rows[-1][1][2], len(out), len(renames), len(aliases)))
    for l in out[:a.show]:
        print("   " + l)
    if not a.apply:
        return 0
    paths = {}
    path = os.path.join(ROOT, a.image, "maincpu", REL)
    raw = open(path, "rb").read()
    paths[path] = raw
    L = raw.decode("latin-1").split("\n")
    l0, l1 = rows[0][1][2], rows[-1][1][2]
    L[l0 - 1:l1] = out
    txt = "\n".join(L)
    for old, new in renames.items():
        txt = re.sub(r'(?<![\w.$])' + re.escape(old) + r'(?![\w.$:])', new, txt)
    open(path, "wb").write(txt.encode("latin-1"))
    for rel in ("shared/positional_labels.s", "kn5000_%s_program.s" % a.image):
        p = os.path.join(ROOT, a.image, "maincpu", rel)
        raw = open(p, "rb").read()
        paths[p] = raw
        t = raw.decode("latin-1")
        for old, new in renames.items():
            t = re.sub(r'(?<![\w.$])' + re.escape(old) + r'(?![\w.$])', new, t)
        for nm, c in aliases.items():
            t = re.sub(r'(\t\.set\s+%s,\s*)[^\n;]+' % re.escape(nm), r'\g<1>%s' % c, t)
        open(p, "wb").write(t.encode("latin-1"))
    built, err = pi.fast_build(a.image, os.path.join(pi.SCRATCH, "build"))
    if built == pi.rom(a.image):
        print("%s IDENTICAL" % a.image)
        return 0
    print("MISMATCH/FAIL; restoring", err[-2000:] if built is None else "")
    if built is not None:
        rd = pi.rom(a.image)
        bad = [x for x in range(min(len(built), len(rd))) if built[x] != rd[x]]
        print("  %d bytes differ, first 0x%06X" % (len(bad), bad[0] + BASE if bad else 0))
    for p, raw in paths.items():
        open(p, "wb").write(raw)
    return 1


if __name__ == "__main__":
    sys.exit(main())
