#!/usr/bin/env python3
r"""RE-SPELL THE SOUND EDITOR'S SCREEN-DATA BLOCK AS TYPED DATA (v10, v9, v7).

QUESTION ANSWERED
-----------------
Given the reader-derived model of se_screendata_model.py, can the block be
written as typed records, pointer tables, string/box/word tables and 1-bpp
bitmaps -- each object under a header that names its reader -- and still
rebuild every byte of the ROM?

WHAT IT DOES
  * reads the address->line map of audio/sound_editor_ui.s (seui_amap.py) to
    find the source lines that emit [SeScreenData, SeScreenData_End);
  * KEEPS verbatim every `.incbin "includes/generated/..."` line inside that
    span (byte-exact C screen descriptors from earlier lanes) and every
    comment line, `.set` line and still-referenced label;
  * REPLACES every other byte-emitting line (instructions the tree had framed
    over this data, `.byte`/`.ascii` runs, and in v7 the verbatim
    `includes/romslices/*` slices) with typed data rendered from the ROM:
        records   one macro line per record (sd_* static, sdb_* bound)
        tables    `.long <label>` per pointer
        strings   `.ascii` fixed-width cells
        boxes     `.short x1, y1, x2, y2`
        bitmaps   `.byte 0b........` one row per line
  * labels every object start as SeScreenData_0xNNNN (offset from the block
    start -- the same offset in all three images) unless it already has a
    referenced label, and drops labels nothing references (they named
    fragments of the old instruction framing);
  * writes the file (latin-1, byte-for-byte outside the span) only with
    --apply.  The byte gate (`make gate`) is the certification.

RUN
    python3 scripts/lanes/seui/seui_amap.py --image v10 --out A.json --files audio/sound_editor_ui.s
    python3 scripts/lanes/seui/se_screendata_render.py --image v10 --amap A.json [--apply]
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
import se_screendata_model as sm          # noqa: E402

BASE = sm.BASE
REL = "audio/sound_editor_ui.s"
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
STRUCTURAL = re.compile(r"_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Helper)\d*$")

# Names for objects whose content says what they are (offsets from
# SeScreenData, the same in v10, v9 and v7).  The pixels are rendered below
# each one; the names describe those pixels, not a guess about their use.
NAMES = {
    0x0000: "SeBitmap_Pattern24x10_1",
    0x001E: "SeBitmap_Pattern24x10_2",
    0x003C: "SeBitmap_Pattern24x10_3",
    0x005A: "SeBitmap_Pattern24x10_4",
    0x0078: "SeBitmap_RadioOn",
    0x0090: "SeBitmap_RadioOff",
    0x0490: "SeBitmap_EnvCurve6",
    0x06EF: "SeBitmap_Picture40x40",
}

QUAD_OPS = {0x00, 0x01, 0x02, 0x05, 0x09, 0x0A, 0x11, 0x12, 0x13, 0x15, 0x1B, 0x22}
CTEXT_OPS = {0x06, 0x07, 0x08, 0x20}
PTEXT_OPS = {0x17, 0x1C}

MACROS = r"""; -----------------------------------------------------------------------------
; ScreenData record macros (lane seui 2026-09-25).  One macro = one record =
; {u8 op, u8 len, payload}; the layouts are the reads the interpreter's own
; handlers make (se_gfx_wrappers_probe.py / se_screendata_model.py):
;  static (GraphicsRender_ProcessEntries, 36-entry table):
;   sd_quad   op, a, b, c, d   len 10, four u16 at +2/+4/+6/+8 (ops 00 01 02 05
;                              09 0A 11 12 13 15 1B 22: two corner points)
;   sd_ctext  op, len, cell, text   u16 +2 = y*40 + x/8, written Y*40+C below
;                              (the handler divides by 40: y = cell/40 pixel
;                              rows, x = 8*(cell%40)); text = len-4 bytes
;                              (ops 06 07 08 20)
;   sd_ptext  op, len, x, y, text   u16 +2 = x, u16 +4 = y in pixels, text =
;                              len-6 bytes (ops 17 1C)
;   sd_blit   bitmap, cell, bpr, rows   op 03 len 12: u32 +2 1-bpp bitmap,
;                              u16 +6 cell, u16 +8 bytes per row, u16 +10 rows
;   sd_op23   style, cell      op 23 len 5: u8 +2, u16 +3 cell
;   sd_rec    op, len, bytes...     any other static record, payload verbatim
;  bound (GraphicsRender_Start, 12-entry table): value = (RAM[ram] & mask) >>
;  (shift & 15), then:
;   sdb_num   ram, mask, shift, style, cell, digits      op 00 len 10
;   sdb_snum  ram, mask, shift, style, cell, digits, zero op 05 len 11: prints
;                              value-zero with a '+'/'-' sign
;   sdb_str   ram, mask, shift, style, table, width, cell      op 02 len 15:
;                              `width` chars of table[value*width] at cell
;   sdb_strxy ram, mask, shift, style, table, width, x, y      op 07 len 17
;   sdb_box   op, ram, mask, shift, b6, table   ops 03/04/08 len 11: u32 +7
;                              -> table of {x1,y1,x2,y2} u16 boxes, [value]
; -----------------------------------------------------------------------------
.macro sd_quad op, a, b, c, d
	.byte \op, 10
	.short \a, \b, \c, \d
.endm
.macro sd_ctext op, len, cell, text:vararg
	.byte \op, \len
	.short \cell
	.ascii \text
.endm
.macro sd_ptext op, len, x, y, text:vararg
	.byte \op, \len
	.short \x, \y
	.ascii \text
.endm
.macro sd_blit bitmap, cell, bpr, rows
	.byte 0x03, 12
	.long \bitmap
	.short \cell, \bpr, \rows
.endm
.macro sd_op23 style, cell
	.byte 0x23, 5, \style
	.short \cell
.endm
.macro sd_rec op, len, bytes:vararg
	.byte \op, \len, \bytes
.endm
.macro sdb_num ram, mask, shift, style, cell, digits
	.byte 0x00, 10
	.short \ram
	.byte \mask, \shift, \style
	.short \cell
	.byte \digits
.endm
.macro sdb_snum ram, mask, shift, style, cell, digits, zero
	.byte 0x05, 11
	.short \ram
	.byte \mask, \shift, \style
	.short \cell
	.byte \digits, \zero
.endm
.macro sdb_str ram, mask, shift, style, table, width, cell
	.byte 0x02, 15
	.short \ram
	.byte \mask, \shift, \style
	.long \table
	.short \width, \cell
.endm
.macro sdb_strxy ram, mask, shift, style, table, width, x, y
	.byte 0x07, 17
	.short \ram
	.byte \mask, \shift, \style
	.long \table
	.short \width, \x, \y
.endm
.macro sdb_box op, ram, mask, shift, b6, table
	.byte \op, 11
	.short \ram
	.byte \mask, \shift, \b6
	.long \table
.endm
"""


def split_comment(t):
    """-> (code, comment or None), honouring double-quoted strings"""
    q = False
    i = 0
    while i < len(t):
        c = t[i]
        if c == "\\" and q:
            i += 2
            continue
        if c == '"':
            q = not q
        elif c == ";" and not q:
            return t[:i], t[i:]
        i += 1
    return t, None


def qtext(bs):
    out = []
    for c in bs:
        if c in (0x22, 0x5C):
            out.append("\\" + chr(c))
        elif 0x20 <= c < 0x7F:
            out.append(chr(c))
        else:
            out.append("\\%03o" % c)
    return '"' + "".join(out) + '"'


def cell(v):
    return "%d*40+%d" % (v // 40, v % 40)


class Render:
    def __init__(self, v, amap_path):
        self.v = v
        self.syms = sm.symbols(v)
        self.m, self.gaps = sm.build(v, s=self.syms)
        m = self.m
        self.rom = m.rom
        self.lo, self.hi = m.lo, m.hi
        self.path = os.path.join(ROOT, v, "maincpu", REL)
        self.raw = open(self.path, "rb").read()
        self.L = self.raw.decode("latin-1").split("\n")
        spans = [s for s in json.load(open(amap_path)) if s[2] == REL]
        self.emit = {s[3]: (s[0], s[1]) for s in spans}
        # the line span
        first = [li for li, (a, e) in self.emit.items() if a == self.lo]
        last = [li for li, (a, e) in self.emit.items() if e == self.hi]
        if not first or not last:
            sys.exit("region %06x-%06x does not start/end on a source line" % (self.lo, self.hi))
        self.Ls, self.Le = min(first), max(last)
        # every line from Ls..Le must emit inside the region or not at all
        for li in range(self.Ls, self.Le + 1):
            if li in self.emit:
                a, e = self.emit[li]
                assert self.lo <= a and e <= self.hi, (li, hex(a))

    # -------------------------------------------------------------- analysis
    def next_addr(self, li):
        k = li
        while k <= self.Le and k not in self.emit:
            k += 1
        return self.emit[k][0] if k <= self.Le else self.hi

    def plan_lines(self):
        """classify every line of the span"""
        self.keep_lines = {}        # li -> (addr, end) preserved byte-emitting lines
        self.ne_lines = []          # (addr, li, text) non-emitting lines to carry
        self.labels = {}            # name -> (addr, li)
        for li in range(self.Ls, self.Le + 1):
            t = self.L[li]
            if li in self.emit:
                a, e = self.emit[li]
                if re.search(r'\.incbin\s+"includes/generated/', t):
                    self.keep_lines[li] = (a, e)
                    continue
                # trailing comment of a replaced line survives as its own line
                code, com = split_comment(t)
                if com:
                    self.ne_lines.append((a, li, "\t" + com.strip()))
                m = LABEL_RE.match(t.strip())
                if m:
                    self.labels[m.group(1)] = (a, li)
                continue
            s = t.strip()
            a = self.next_addr(li)
            m = LABEL_RE.match(s)
            if m:
                self.labels[m.group(1)] = (a, li)
                rest = s[m.end():].strip()
                if rest.startswith(";"):
                    self.ne_lines.append((a, li, "\t" + rest))
                continue
            if s == "":
                continue
            self.ne_lines.append((a, li, t))

    def label_refs(self):
        """which span labels are referenced outside the replaced lines"""
        names = set(self.labels)
        cnt = dict.fromkeys(names, 0)
        tok = re.compile(r"[A-Za-z_.$][\w.$]*")
        root = os.path.join(ROOT, self.v, "maincpu")
        for dp, _, fns in os.walk(root):
            for fn in fns:
                if not fn.endswith((".s", ".c", ".h", ".ld", ".inc")):
                    continue
                p = os.path.join(dp, fn)
                lines = open(p, encoding="latin-1").read().split("\n")
                for i, ln in enumerate(lines):
                    if p == self.path and self.Ls <= i <= self.Le:
                        # inside the span only comments, .set lines and kept
                        # lines survive
                        if i in self.emit and i not in self.keep_lines:
                            continue
                        s = ln.strip()
                        m = LABEL_RE.match(s)
                        if m:
                            s = s[m.end():]
                    for t in tok.findall(ln if not (p == self.path and self.Ls <= i <= self.Le) else s):
                        if t in cnt:
                            cnt[t] += 1
        self.kept_labels = {n: self.labels[n] for n in names if cnt[n] > 0}
        self.dropped_labels = sorted(n for n in names if cnt[n] == 0)

    # -------------------------------------------------------------- objects
    def build_items(self):
        m = self.m
        preserved = sorted(self.keep_lines.values())
        self.preserved = preserved
        objs = {o["addr"]: o for o in m.objs.values()
                if o["kind"] not in ("record1",) and o["size"] > 0}
        lists_at = {}
        for (a, e), o in m.lists.items():
            lists_at.setdefault(a, []).append(o)
        rec1_at = {o["addr"]: o for o in m.objs.values() if o["kind"] == "record1"}
        self.lists_at, self.rec1_at = lists_at, rec1_at
        gaps = {g[0]: g for g in self.gaps}
        items = []
        p = self.lo
        pi = 0
        while p < self.hi:
            if pi < len(preserved) and preserved[pi][0] == p:
                p = preserved[pi][1]
                pi += 1
                continue
            stop = preserved[pi][0] if pi < len(preserved) else self.hi
            if p in objs and objs[p]["kind"] not in ("list",):
                o = objs[p]
                size = min(o["size"], stop - p)
                if size != o["size"]:
                    raise SystemExit("%s at %06x crosses a preserved block" % (o["kind"], p))
                items.append((p, p + size, o["kind"], o))
                p += size
                continue
            if p in m.recs:
                op, ln, fam = m.recs[p]
                if p + ln > stop:
                    raise SystemExit("record at %06x crosses %06x" % (p, stop))
                items.append((p, p + ln, "rec", (op, ln, fam)))
                p += ln
                continue
            if p in gaps:
                g = gaps[p]
                e = min(g[1], stop)
                items.append((p, e, "gap", g))
                p = e
                continue
            raise SystemExit("nothing models %06x" % p)
        self.items = items

    def targets(self):
        """addresses that need a symbol: every pointer the rendered data
        holds, plus every object start (so each gets its header)"""
        m = self.m
        need = set()
        for (a, e, kind, o) in self.items:
            if kind in ("bounds", "recptrs", "startptrs", "pairs", "grouptab"):
                need.update(o["ptrs"])
            if kind == "rec":
                op, ln, fam = o
                if fam == "S" and op == 0x03 and ln == 12:
                    need.add(m.l(a + 2))
                if fam == "B" and op in (0x02, 0x07, 0x03, 0x04, 0x08):
                    need.add(m.l(a + 7))
        starts = set()
        for (a, e, kind, o) in self.items:
            if kind != "rec" or a in self.lists_at or a in self.rec1_at:
                starts.add(a)
        # every list start (including lists that begin inside another)
        starts.update(self.lists_at)
        starts.update(self.rec1_at)
        return need, starts

    def name_for(self, addr):
        if not (self.lo <= addr < self.hi):
            # outside the block: RAM (e.g. the 0x020BF3 name buffers) stays
            # numeric; ROM gets whatever symbol the tree already has there
            cands = sorted(n for n, a in self.syms.items() if a == addr and not n.startswith("__"))
            good = [n for n in cands if not STRUCTURAL.search(n)]
            return (good or cands or ["0x%08x" % addr])[0]
        # an existing, still-referenced, non-structural label wins
        best = [n for n, (a, li) in self.kept_labels.items()
                if a == addr and not STRUCTURAL.search(n) and not re.search(r"_0x[0-9A-F]+$", n)]
        if best:
            return sorted(best, key=lambda n: self.kept_labels[n][1])[0]
        off = addr - self.lo
        if off in NAMES:
            return NAMES[off]
        if addr == self.lo:
            return "SeScreenData"
        return "SeScreenData_0x%04X" % off

    # -------------------------------------------------------------- rendering
    def render_item(self, a, e, kind, o):
        m = self.m
        n = self.name_for
        L = []
        if kind == "rec":
            op, ln, fam = o
            b = self.rom[a - BASE:e - BASE]
            w = lambda k: b[k] | b[k + 1] << 8
            lng = lambda k: m.l(a + k)
            if fam == "S":
                if op in QUAD_OPS and ln == 10:
                    L.append("\tsd_quad\t0x%02x, %d, %d, %d, %d" % (op, w(2), w(4), w(6), w(8)))
                elif op in CTEXT_OPS and ln >= 4:
                    L.append("\tsd_ctext\t0x%02x, %d, %s, %s" % (op, ln, cell(w(2)), qtext(b[4:])))
                elif op in PTEXT_OPS and ln >= 6:
                    L.append("\tsd_ptext\t0x%02x, %d, %d, %d, %s" % (op, ln, w(2), w(4), qtext(b[6:])))
                elif op == 0x03 and ln == 12:
                    L.append("\tsd_blit\t%s, %s, %d, %d" % (n(lng(2)), cell(w(6)), w(8), w(10)))
                elif op == 0x23 and ln == 5:
                    L.append("\tsd_op23\t0x%02x, %s" % (b[2], cell(b[3] | b[4] << 8)))
                else:
                    L.append("\tsd_rec\t0x%02x, %d, %s" % (op, ln, ", ".join("0x%02x" % x for x in b[2:])))
            else:
                hdr = "0x%04x, 0x%02x, %d, 0x%02x" % (w(2), b[4], b[5], b[6])
                if op == 0x00 and ln == 10:
                    L.append("\tsdb_num\t%s, %s, %d" % (hdr, cell(w(7)), b[9]))
                elif op == 0x05 and ln == 11:
                    L.append("\tsdb_snum\t%s, %s, %d, 0x%02x" % (hdr, cell(w(7)), b[9], b[10]))
                elif op == 0x02 and ln == 15:
                    L.append("\tsdb_str\t%s, %s, %d, %s" % (hdr, n(lng(7)), w(11), cell(w(13))))
                elif op == 0x07 and ln == 17:
                    L.append("\tsdb_strxy\t%s, %s, %d, %d, %d" % (hdr, n(lng(7)), w(11), w(13), w(15)))
                elif op in (0x03, 0x04, 0x08) and ln == 11:
                    L.append("\tsdb_box\t0x%02x, %s, %s" % (op, hdr, n(lng(7))))
                else:
                    L.append("\tsd_rec\t0x%02x, %d, %s" % (op, ln, ", ".join("0x%02x" % x for x in b[2:])))
            return L
        if kind in ("bounds", "recptrs", "startptrs", "grouptab"):
            for p in o["ptrs"]:
                L.append("\t.long\t%s" % n(p))
            return L
        if kind == "pairs":
            ps = o["ptrs"]
            for i in range(0, len(ps), 2):
                L.append("\t.long\t%s, %s" % (n(ps[i]), n(ps[i + 1])))
            return L
        if kind == "strtab":
            wdt = max(1, o["width"])
            b = self.rom[a - BASE:e - BASE]
            cells = [b[i:i + wdt] for i in range(0, len(b) - len(b) % wdt, wdt)]
            per = 8 if wdt <= 2 else (4 if wdt <= 4 else 1)
            for i in range(0, len(cells), per):
                L.append("\t.ascii\t" + ", ".join(qtext(c) for c in cells[i:i + per]))
            if len(b) % wdt:
                L.append("\t.ascii\t" + qtext(b[len(b) - len(b) % wdt:]))
            return L
        if kind == "boxtab":
            b = self.rom[a - BASE:e - BASE]
            for i in range(0, len(b) - len(b) % 8, 8):
                ws = [b[i + k] | b[i + k + 1] << 8 for k in (0, 2, 4, 6)]
                L.append("\t.short\t%d, %d, %d, %d" % tuple(ws))
            if len(b) % 8:
                L.append("\t.byte\t" + ", ".join("0x%02x" % x for x in b[len(b) - len(b) % 8:]))
            return L
        if kind == "wordtab":
            b = self.rom[a - BASE:e - BASE]
            st = o.get("stride", 2)
            per = st // 2 if st in (2, 4) else 1
            ws = [b[i] | b[i + 1] << 8 for i in range(0, len(b) - len(b) % 2, 2)]
            per = max(per, 1)
            for i in range(0, len(ws), per if per > 1 else 8):
                L.append("\t.short\t" + ", ".join("%d" % x for x in ws[i:i + (per if per > 1 else 8)]))
            if len(b) % 2:
                L.append("\t.byte\t0x%02x" % b[-1])
            return L
        if kind == "bitmap":
            # stored COLUMN by column: the blitter (0xFAFB48 in v10, reached
            # from static op 03) walks y inside each 8-pixel column and only
            # then steps x by 8, advancing the source pointer once per row --
            # so one line per byte shows each column as a vertical strip
            b = self.rom[a - BASE:e - BASE]
            rows = o["rows"]
            for k in range(o["bpr"]):
                L.append("\t; column %d (x %d-%d)" % (k, 8 * k, 8 * k + 7))
                for r in range(rows):
                    L.append("\t.byte\t0b{:08b}".format(b[k * rows + r]))
            return L
        if kind == "gap":
            return self.render_gap(a, e)
        raise SystemExit("no renderer for " + kind)

    def render_gap(self, a, e):
        m = self.m
        b = self.rom[a - BASE:e - BASE]
        # record-shaped?
        for fam, lim in (("S", 0x23), ("B", 0x0B)):
            p, ok, recs = a, True, []
            while p < e:
                op, ln = m.b(p), m.b(p + 1)
                if op > lim or ln < 2 or p + ln > e:
                    ok = False
                    break
                recs.append((p, op, ln))
                p += ln
            if ok and p == e:
                L = []
                for (r, op, ln) in recs:
                    L += self.render_item(r, r + ln, "rec", (op, ln, fam))
                return L
        if all(0x20 <= x < 0x7F for x in b):
            return ["\t.ascii\t" + qtext(b)]
        if e - a == 200:
            return self.render_item(a, e, "bitmap", {"bpr": 5, "rows": 40})
        return ["\t.byte\t" + ", ".join("0x%02x" % x for x in b[i:i + 8]) for i in range(0, len(b), 8)]

    def routine(self, site):
        """nearest preceding non-positional, non-structural code symbol"""
        best = None
        for nme, adr in self.syms.items():
            if adr <= site and not nme.startswith(("__", ".")) and not re.search(r"_0x[0-9A-F]+$", nme) \
                    and not STRUCTURAL.search(nme) and adr > site - 0x400:
                if best is None or adr > best[1]:
                    best = (nme, adr)
        return best[0] if best else "code 0x%06X" % site

    def header(self, a, e, kind, o):
        """two or more comment lines naming what the object is and its reader"""
        m = self.m
        H = []
        evs = []
        if kind == "rec" or a in self.lists_at or a in self.rec1_at:
            ls = self.lists_at.get(a, [])
            fams = {x["family"] for x in ls} | ({self.rec1_at[a]["family"]} if a in self.rec1_at else set())
            if not fams and kind == "rec":
                fams = {o[2]}
            fam = "static" if fams == {"S"} else "bound" if fams == {"B"} else "static/bound"
            if ls:
                ends = sorted({x["end"] for x in ls})
                nrec = max(x["nrec"] for x in ls)
                ends_s = ", ".join("SeScreenData_0x%04X" % (x - self.lo) if x != self.hi else "SeScreenData_End"
                                   for x in ends[:3]) + (" ..." if len(ends) > 3 else "")
                H.append("; %s record list (%d record%s), read by %s; end%s %s" % (
                    fam, nrec, "s" if nrec != 1 else "",
                    "GraphicsRender_ProcessEntries" if fam == "static" else
                    "GraphicsRender_Start" if fam == "bound" else "both interpreters",
                    "s" if len(ends) > 1 else "", ends_s))
                for x in ls:
                    evs += x["ev"]
            elif a in self.rec1_at:
                H.append("; single %s record, read by %s" % (
                    fam, "SeGfx_DrawBoundRecord (GraphicsRender_Start)" if fam == "bound"
                    else "a SeGfx_Static* wrapper"))
                evs += self.rec1_at[a]["ev"]
            else:
                op, ln, f1 = o
                tabs = [t for t in self.m.objs.values() if a in t.get("ptrs", [])]
                H.append("; %s record (op 0x%02x), pointed at by the table%s below/above;" % (
                    "static" if f1 == "S" else "bound", op, "s" if len(tabs) > 1 else ""))
                H.append("; part of the record %s that table bounds" % (
                    "lists" if any(t["kind"] == "bounds" for t in tabs) else "set"))
                evs += ["%s %06x" % (t["kind"], t["addr"]) for t in tabs]
        elif kind in ("bounds", "recptrs", "startptrs", "pairs", "grouptab"):
            what = {"bounds": "list-boundary table: entry i and i+1 bound list i",
                    "recptrs": "record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord",
                    "startptrs": "list-start table: entry i -> a list of %s bytes" % o.get("span"),
                    "pairs": "(start, end) pair table, 8 bytes per list",
                    "grouptab": "record-group table: entry i -> %s-byte records, one picked by value" % o.get("span")}[kind]
            H.append("; %s (%d entries, LE32)" % (what, len(o["ptrs"])))
            evs += o["ev"]
        elif kind == "strtab":
            H.append("; string table, %d-char cells, indexed by a bound record's value (field +7 of" % o["width"])
            H.append("; a bound op 02/07 record; value range up to %d)" % o["maxn"])
            evs += o["ev"]
        elif kind == "boxtab":
            H.append("; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08")
            H.append("; record's value (pointer field +7; value range up to %d)" % o["maxn"])
            evs += o["ev"]
        elif kind == "wordtab":
            H.append("; u16 table, stride %d, fields %s, indexed directly by code" % (
                o["stride"], "/".join("+%d" % f for f in sorted(o.get("fields", [0])))))
            evs += o["ev"]
        elif kind == "bitmap":
            H.append("; 1-bpp bitmap %dx%d px, stored column by column (%d byte-columns of %d rows;" % (
                8 * o["bpr"], o["rows"], o["bpr"], o["rows"]))
            H.append("; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock")
            evs += o["ev"]
        elif kind == "gap":
            H.append("; NO READER FOUND for these %d bytes.  Searched: LE32/LE24/LE16 of every" % (e - a))
            H.append("; address in the span, ld xiy/xix/xiz immediates, and the loop bounds of the")
            H.append("; tables beside it.")
            import textwrap
            for ln in textwrap.wrap("Shape only: " + self.gap_shape(a, e), 74):
                H.append("; " + ln)
            return H
        # evidence: code sites -> routine names; table/record evidence as is
        cites = []
        for ev in evs:
            mm = re.match(r"code ([0-9a-f]{6})", ev)
            if mm:
                r = self.routine(int(mm.group(1), 16))
                if r not in cites:
                    cites.append(r)
            else:
                mm = re.match(r"(\w[\w ]*?) ([0-9a-f]{6})", ev)
                if mm:
                    t = int(mm.group(2), 16)
                    s = "%s at SeScreenData_0x%04X" % (mm.group(1), t - self.lo) if self.lo <= t < self.hi \
                        else "%s %s" % (mm.group(1), self.routine(t))
                    if s not in cites:
                        cites.append(s)
        if cites:
            txt = "; evidence: " + ", ".join(cites[:4]) + (" (+%d more)" % (len(cites) - 4) if len(cites) > 4 else "")
            H.append(txt)
        return H

    def gap_shape(self, a, e):
        b = self.rom[a - BASE:e - BASE]
        blk = self.rom[self.lo - BASE:self.hi - BASE]
        dups = []
        i = blk.find(b)
        while i >= 0:
            if self.lo + i != a:
                dups.append("SeScreenData_0x%04X" % i)
            i = blk.find(b, i + 1)
        dup = (" The same %d bytes also sit at %s." % (e - a, ", ".join(dups))) if dups else ""
        if all(0x20 <= x < 0x7F for x in b):
            return "printable text." + dup
        if e - a == 200:
            return ("read column by column like the six SeBitmap_EnvCurve* bitmaps it follows, "
                    "it is a coherent 40x40 picture." + dup)
        for fam, lim in (("static", 0x23), ("bound", 0x0B)):
            p, ok = a, True
            while p < e:
                op, ln = self.m.b(p), self.m.b(p + 1)
                if op > lim or ln < 2 or p + ln > e:
                    ok = False
                    break
                p += ln
            if ok and p == e:
                return "parses exactly as %s records." % fam + dup
        if (e - a) % 5 == 0:
            return "same size as a 5x40 envelope bitmap; rendered as 5-byte rows."
        return "bytes."

    # -------------------------------------------------------------- assemble
    def assemble(self):
        self.plan_lines()
        self.label_refs()
        self.build_items()
        need, starts = self.targets()
        label_at = {}      # addr -> name we define
        for t in sorted(t for t in (need | starts) if self.lo <= t < self.hi):
            label_at[t] = self.name_for(t)
        # entries: (addr, pri, order, [lines])
        E = []
        item_start = {}
        for (a, e, kind, o) in self.items:
            for x in range(a, e):
                item_start[x] = a
        for (a, e) in self.preserved:
            for x in range(a, e):
                item_start[x] = a
        for (a, li, t) in self.ne_lines:
            E.append((item_start.get(a, a), 0, li, [t]))
        defined_pre = {"SeScreenData"}
        kept_at = {}
        for nme, (a, li) in self.kept_labels.items():
            kept_at.setdefault(a, []).append((li, nme))
        defined = set(defined_pre)
        for a in sorted(kept_at):
            base = item_start.get(a, a)
            for (li, nme) in sorted(kept_at[a]):
                if base == a:
                    E.append((a, 2, li, ["%s:" % nme]))
                else:
                    E.append((base, 2, li, ["\t.set\t%s, . + %d" % (nme, a - base)]))
                defined.add(nme)
        for t, nme in label_at.items():
            if nme in defined:
                continue
            base = item_start.get(t, t)
            if base == t:
                E.append((t, 2, 10 ** 9, ["%s:" % nme]))
            else:
                E.append((base, 2, 10 ** 9, ["\t.set\t%s, . + %d" % (nme, t - base)]))
            defined.add(nme)
        for (a, e, kind, o) in self.items:
            if a in starts or a in label_at:
                E.append((a, 1, 0, self.header(a, e, kind, o)))
            E.append((a, 3, 0, self.render_item(a, e, kind, o)))
        for li, (a, e) in self.keep_lines.items():
            E.append((a, 3, li, [self.L[li]]))
        # the block's own bracket labels and region header
        E.append((self.lo, -1, 0, self.region_header()))
        E.append((self.hi, 4, 0, ["SeScreenData_End:"]))
        E.sort(key=lambda x: (x[0], x[1], x[2]))
        out = []
        for x in E:
            out += x[3]
        self.out = out
        self.defined = defined
        return out

    def region_header(self):
        return MACROS.rstrip("\n").split("\n") + [
            "; =============================================================================",
            "; SeScreenData -- the sound editor's screen-layout block (%d bytes up to" % (self.hi - self.lo),
            "; SeScreenData_End).  Everything in it is read by the ScreenData interpreters",
            "; in display/graphics_text_vga.s through the SeGfx_* wrappers, or by the",
            "; sound-editor code directly; the model that pins every object -- which code",
            "; loads which address, which list parses exactly to its stated end, which",
            "; pointer field names which table -- is scripts/lanes/seui/se_screendata_model.py",
            "; (run it to see the evidence for any object).  Rendered from that model by",
            "; scripts/lanes/seui/se_screendata_render.py (lane seui, 2026-09-25); until then",
            "; the tree spelled this block as instructions (v10/v9) or verbatim ROM slices",
            "; (v7).  Labels are SeScreenData_0xNNNN = offset from SeScreenData, identical",
            "; in v10, v9 and v7.  The byte-exact C screen descriptors (`.incbin` of",
            "; includes/generated/se_*.bin) inside the block are earlier lanes' work and",
            "; are kept as they were.",
            "; =============================================================================",
            "SeScreenData:",
        ]

    def write(self):
        new = self.L[:self.Ls] + self.out + self.L[self.Le + 1:]
        txt = "\n".join(new)
        open(self.path, "wb").write(txt.encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--amap", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", type=int, default=0)
    a = ap.parse_args()
    r = Render(a.image, a.amap)
    out = r.assemble()
    print("%s: lines %d..%d (%d) -> %d lines; %d items; %d preserved C blocks; "
          "%d labels kept, %d dropped"
          % (a.image, r.Ls + 1, r.Le + 1, r.Le - r.Ls + 1, len(out), len(r.items),
             len(r.preserved), len(r.kept_labels), len(r.dropped_labels)))
    if a.show:
        print("\n".join(out[:a.show]))
    if a.apply:
        r.write()
        print("written", r.path)


if __name__ == "__main__":
    main()
