# VENDORED COPY -- scripts/lanes/seui/se_screendata_model.py from branch s2/seui at 09123f18
# (lane seui, 2026-09-25), copied unchanged below this header so that lane sys can
# run the ScreenData model over the continuation of the block in its own file
# storage/flash_floppy_handlers.s (--lo/--hi) before s2/seui is merged.  When both
# branches are on main, delete this copy and import the original.
#!/usr/bin/env python3
r"""WHAT IS EVERY BYTE OF THE SOUND EDITOR'S SCREEN-DATA BLOCK, AND HOW DO WE KNOW?

QUESTION ANSWERED
-----------------
`audio/sound_editor_ui.s` holds ~19 KB (v10/v9 0xF10C06-0xF158A7, v7 shifted)
that the tree carried as instructions (v10/v9: `SeBitmap_EnvCurve1..5`,
`TuningSystem_Handler_Table`, ...; 755 absurd-instruction markers in v10) or
as verbatim ROM slices (v7).  This tool builds a byte-exact MODEL of that block
from its READERS, so every object can be typed with a cited reader, stride and
count instead of a guess.

THE READERS (all in display/graphics_text_vga.s, reached through the 17
`SeGfx_*` wrappers -- see se_gfx_wrappers_probe.py)
  GraphicsRender_ProcessEntries (XWA=start, XBC=end): walks records
      {u8 op, u8 len, payload[len-2]}, advancing by `len`, dispatching op
      0x00-0x23 through a 36-entry handler table ("STATIC" records).
  GraphicsRender_Start (same contract): 12-entry table, ops 0x00-0x0B
      ("BOUND" records: every handler first reads the byte at the RAM address
      in u16 +2, ANDs it with +4 and shifts it right by (+5 & 0x0f)).
  Pointer fields the handlers dereference, and so the objects they pin:
      static op 03  +2 u32 -> 1-bpp bitmap, +8 u16 bytes/row, +10 u16 rows
      bound  op 02  +7 u32 -> fixed-width string table, +11 u16 chars/entry
      bound  op 07  +7 u32 -> fixed-width string table, +11 u16 chars/entry
      bound  op 03/04/08  +7 u32 -> table of 8-byte {x1,y1,x2,y2} u16 boxes,
                    indexed by the masked value
  Code that holds region addresses (found by scanning the ROM for
  `ld xiy/xix/xiz, imm32` = 45/44/46 + LE32 and for LE32 words):
      XIY..XIX pair + call wrapper          -> a record LIST [start, end)
      XIY alone + call single-record wrapper -> ONE record
      XIZ = T; XIY=(T+i); XIX=(T+i+4)        -> list-BOUNDARY table
      XIY = T; call 0xF10BE7 (idx in WA)     -> table of pointers to records

EVERY LIST IS CHECKED: parsing from its start must land EXACTLY on its end.
That is a falsifiable test of both the record framing and the reference -- a
misread length anywhere in the list would overshoot or undershoot.

OUTPUT  JSON: {"objects": [...], "gaps": [...]} and a summary on stdout.

RUN
    python3 scripts/lanes/seui/se_screendata_model.py --image v10 [--json out.json]
"""
import argparse
import json
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

# region per image: [first byte, first byte of storage/flash_floppy_handlers.s)
# (start = the 24x10 envelope icons right after the push/pop no-op routine)
WRAPPER_NAMES = {
    "SeGfx_DrawStaticList": "S*", "SeGfx_DrawBoundList": "B*",
    "SeGfx_DrawBoundRecord": "B1", "SeGfx_StaticOp06_Text": "S1",
    "SeGfx_StaticOp07_Text": "S1", "SeGfx_StaticOp0E": "S1",
    "SeGfx_BoundOp00": "B1", "SeGfx_BoundOp02": "B1", "SeGfx_BoundOp03": "B1",
    "SeGfx_BoundOp06": "B1",
    "GraphicsRender_ProcessEntries": "S*", "GraphicsRender_Start": "B*",
}
# old names, so the model also runs on a tree from before the rename
OLD = {"SeMenu_NameEditor_Setup": "S*", "SeMenu_NameEditor_Draw": "B*",
       "SeMenu_NameEditor_HandleInput": "B1", "SeMenu_NameEditor_MoveCursor_Data": "S1",
       "SeMenu_NameEditor_ChangeCase": "S1", "SeMenu_NameEditor_SelectCharSet": "S1",
       "SeMenu_NameEditor_Cancel": "B1", "SeMenu_NameEditor_Cancel_Data": "B1",
       "SeMenu_NameEditor_Redraw": "B1", "SeMenu_NameEditor_Redraw_Data": "B1"}


def symbols(v):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True,
                         text=True, check=True).stdout
    s = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3:
            s.setdefault(p[2], int(p[0], 16))
    return s


class Model:
    def __init__(self, v, lo, hi, syms):
        self.v, self.lo, self.hi, self.s = v, lo, hi, syms
        self.rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
        self.wr = {}
        for n, k in list(WRAPPER_NAMES.items()) + list(OLD.items()):
            if n in syms:
                self.wr[syms[n]] = k
        # the "record from pointer table" helper: extz xwa / xor w,w / sla 2,wa /
        # add xiy,xwa / ld xiy,(xiy) / call DrawBoundRecord  (v10 0xF10BE7)
        pat = bytes.fromhex("e812c8d0d8ec02e885a525")
        i = self.rom.find(pat, 0xF00000 - BASE, 0xF20000 - BASE)
        self.fromtab = BASE + i if i >= 0 else None
        self._dcache = {}
        self.unresolved = []
        self.objs = {}      # addr -> dict
        self.lists = {}     # (start, end) -> dict
        self.recs = {}      # addr -> (op, len, family)
        self.bad = []

    def b(self, a):
        return self.rom[a - BASE]

    def w(self, a):
        return struct.unpack_from("<H", self.rom, a - BASE)[0]

    def l(self, a):
        return struct.unpack_from("<I", self.rom, a - BASE)[0]

    def inr(self, a):
        return self.lo <= a < self.hi

    def zone(self, a):
        """the sound editor's screen data continues past this block into
        storage/flash_floppy_handlers.s; lists there are parsed for their
        pointer fields only"""
        return self.lo <= a < self.hi + 0x6000

    def add(self, a, size, kind, ev, **kw):
        if kind == "list":
            o = self.lists.setdefault((a, a + size), dict(addr=a, size=size, kind=kind, ev=[], **kw))
            if ev not in o["ev"]:
                o["ev"].append(ev)
            return o
        o = self.objs.get(a)
        if o and {o["kind"], kind} == {"bounds", "pairs"}:
            # a stride-1 guess (index arithmetic not seen) loses to a seen stride
            if kw.get("stride", 1) > o.get("stride", 1):
                o.update(kind=kind, **kw)
            if ev not in o["ev"]:
                o["ev"].append(ev)
            return o
        if o and o["kind"] != kind and {o["kind"], kind} <= {"bounds", "rectab_ptrs", "recptrs"}:
            o.setdefault("also", [])
            if kind not in o["also"]:
                o["also"].append(kind)
            if ev not in o["ev"]:
                o["ev"].append(ev)
            return o
        if o and (o["size"] != size or o["kind"] != kind):
            self.bad.append("conflict at %06x: %s/%d vs %s/%d" % (a, o["kind"], o["size"], kind, size))
            return o
        if not o:
            o = self.objs[a] = dict(addr=a, size=size, kind=kind, ev=[], **kw)
        if ev not in o["ev"]:
            o["ev"].append(ev)
        return o

    # ------------------------------------------------------------ records
    def parse_list(self, a, e, fam, ev):
        """Walk [a, e) exactly as the interpreter does.  An op above the
        table's range is the interpreter's TERMINATOR (it calls
        GraphicsRender_RetStub and leaves the loop), so a list may legally end
        early there; any other way of missing `e` is a framing error."""
        p, recs = a, []
        lim = 0x23 if fam == "S" else 0x0B
        term = None
        while p < e:
            op, ln = self.b(p), self.b(p + 1)
            if op > lim:
                term = p
                break
            if ln < 2:
                self.bad.append("%s list %06x-%06x: len %d at %06x" % (fam, a, e, ln, p))
                return None
            recs.append((p, op, ln))
            p += ln
        if term is None and p != e:
            self.bad.append("%s list %06x-%06x overruns to %06x" % (fam, a, e, p))
            return None
        for (r, op, ln) in recs:
            self.record(r, op, ln, fam, ev)
        if self.inr(a):
            self.add(a, p - a, "list", ev, family=fam, nrec=len(recs), end=e,
                     terminated_at=term)
        return recs

    def record(self, r, op, ln, fam, ev):
        """a record the interpreter reads.  Records OUTSIDE the block (the
        sound editor's other screens, in storage/flash_floppy_handlers.s) are
        not modelled, but their pointer fields are followed: several string
        tables in this block are read only from there."""
        if self.inr(r):
            old = self.recs.get(r)
            if old and old[2] != fam:
                self.bad.append("record %06x read as both %s and %s" % (r, old[2], fam))
            self.recs[r] = (op, ln, fam)
        # follow pointer fields
        if fam == "S" and op == 0x03 and ln == 12:
            bm, bpr, rows = self.l(r + 2), self.w(r + 8), self.w(r + 10)
            if self.inr(bm):
                self.add(bm, bpr * rows, "bitmap", "static op03 record %06x" % r,
                         bpr=bpr, rows=rows)
        if fam == "B" and op in (0x02, 0x07):
            t, width = self.l(r + 7), self.w(r + 11)
            if self.inr(t):
                n = (self.b(r + 4) >> (self.b(r + 5) & 15)) + 1
                self.add(t, 0, "strtab", "bound op%02x record %06x" % (op, r),
                         width=width, maxn=n)
        if fam == "B" and op in (0x03, 0x04, 0x08):
            t = self.l(r + 7)
            if self.inr(t):
                n = (self.b(r + 4) >> (self.b(r + 5) & 15)) + 1
                self.add(t, 0, "boxtab", "bound op%02x record %06x" % (op, r), maxn=n)

    # ------------------------------------------------------------ code refs
    def insn(self, pc):
        """-> (len, text) of the instruction unidasm decodes AT pc (a sweep
        started at pc, so framing is pc's own)."""
        if pc not in self._dcache:
            import tempfile
            n = 160
            with tempfile.NamedTemporaryFile(suffix=".bin") as f:
                f.write(self.rom[pc - BASE:pc - BASE + n])
                f.flush()
                out = subprocess.run([UNIDASM, f.name, "-arch", "tlcs900", "-basepc", "%x" % pc],
                                     capture_output=True, text=True, check=True).stdout
            for ln in out.splitlines():
                m = re.match(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$", ln)
                if m:
                    a = int(m.group(1), 16)
                    if a < pc + n - 12:
                        self._dcache.setdefault(a, (len(m.group(2).split()), m.group(3).strip()))
            self._dcache.setdefault(pc, (1, "?"))
        return self._dcache[pc]

    def scan_code(self):
        """Every `ld xiy/xiz, imm32` (45/46 + LE32) in the code bank whose
        immediate lands in the region is a SEED; from each seed a small
        symbolic executor follows straight-line code (both arms of a
        conditional `jr`, the target of `jr t`) and records the XIY/XIX/XIZ
        values in force at each call of a ScreenData wrapper."""
        rom = self.rom
        seeds = []
        for i in range(0xF00000 - BASE, 0xF20000 - BASE):
            opc = rom[i]
            if opc not in (0x44, 0x45, 0x46) or rom[i + 4] != 0:
                continue
            a = struct.unpack_from("<I", rom, i + 1)[0]
            if self.zone(a) and not self.zone(BASE + i):
                seeds.append(BASE + i)
        for site in seeds:
            self.run(site)
        # second pass from a few bytes earlier, so index arithmetic that
        # precedes the seed (`xor b,b / sla 2,bc`) is seen; a table first
        # classified without its stride is re-classified here.
        for site in seeds:
            b = self.back_sync(site)
            if b != site:
                self.run(b)

    def back_sync(self, site, reach=24):
        """the earliest address within `reach` bytes before `site` from which a
        linear sweep lands exactly on `site` -- so the walk sees the index
        arithmetic (`xor b,b / sla 2,bc`) that precedes the seed."""
        for s in range(site - reach, site):
            pc, ok = s, False
            while pc < site:
                n, t = self.insn(pc)
                if t in ("?", "db") or t.startswith(("ret", "jp ", "jr T", "jrl T")):
                    break
                pc += n
            if pc == site:
                return s
        return site

    def run(self, site):
        """Symbolic walk from `site`.  Values: ("c", addr); ("idx", T, stride)
        = T + stride*i; ("elem", T, off, stride) = the LE32 at T + stride*i +
        off; ("elem+", T, off, stride, n) = that plus n."""
        work = [(site, {}, 0)]
        seen = set()
        while work:
            pc, st, depth = work.pop()
            steps = 0
            while steps < 48:
                steps += 1
                key = (pc, tuple(sorted((k, v) for k, v in st.items())))
                if key in seen:
                    break
                seen.add(key)
                n, t = self.insn(pc)
                nxt = pc + n
                pc = nxt
                m = re.match(r"ld (XIY|XIX|XIZ),0x([0-9a-f]+)$", t)
                if m:
                    st[m.group(1)] = ("c", int(m.group(2), 16))
                    continue
                m = re.match(r"ld (XIX|XIZ|XIY),(XIY|XIZ|XIX)$", t)
                if m:
                    st[m.group(1)] = st.get(m.group(2))
                    continue
                m = re.match(r"(?:sla|sll) 0x0([0-9a-f]),(WA|BC|DE|HL)$", t)
                if m:
                    st["sh_" + m.group(2)] = int(m.group(1), 16)
                    continue
                m = re.match(r"add XIY,X(WA|BC|DE|HL)$", t)
                if m and st.get("XIY") and st["XIY"][0] == "elem":
                    # a pointer read from a table, plus a variable offset: the
                    # record GROUP idiom (v10 0xF0FAE9: ptr + 10*value)
                    st["XIY"] = ("elemvar",) + st["XIY"][1:]
                    continue
                m = re.match(r"add (XIY|XIZ),X(WA|BC|DE|HL)$", t)
                if m and st.get(m.group(1)) and st[m.group(1)][0] == "c":
                    st[m.group(1)] = ("idx", st[m.group(1)][1], 1 << st.get("sh_" + m.group(2), 0))
                    continue
                m = re.match(r"add XIX,0x([0-9a-f]+)$", t)
                if m and st.get("XIX") and st["XIX"][0] == "elemvar":
                    st["XIX"] = ("elemvar+",) + st["XIX"][1:] + (int(m.group(1), 16),)
                    continue
                if m and st.get("XIX") and st["XIX"][0] == "elem":
                    st["XIX"] = ("elem+",) + st["XIX"][1:] + (int(m.group(1), 16),)
                    continue
                m = re.match(r"ld (XIY|XIX),\((XIY|XIZ)(?:\+0x([0-9a-f]+))?\)$", t)
                if m:
                    base = st.get(m.group(2))
                    off = int(m.group(3), 16) if m.group(3) else 0
                    st[m.group(1)] = ("elem", base[1], off, base[2]) if base and base[0] == "idx" else None
                    continue
                m = re.match(r"ld (XIY|XIX),\(XIZ\+(BC|WA|DE|HL)\)$", t)
                if m:
                    base = st.get("XIZ")
                    st[m.group(1)] = (("elem", base[1], st.get("k_" + m.group(2), 0),
                                       1 << st.get("sh_" + m.group(2), 0))
                                      if base and base[0] == "c" else None)
                    continue
                m = re.match(r"ld (WA|BC|DE|HL|IX|IY),\(XIZ(?:\+0x([0-9a-f]+))?\)$", t)
                if m and st.get("XIZ") and st["XIZ"][0] == "idx":
                    T, stride = st["XIZ"][1], st["XIZ"][2]
                    self.add(T, 0, "wordtab", "code %06x" % (pc - n), stride=stride)
                    self.objs[T].setdefault("fields", set()).add(int(m.group(2), 16) if m.group(2) else 0)
                    continue
                m = re.match(r"ld (WA|BC|DE|IX|IY),\(XIZ\+HL\)$", t)
                if m and st.get("XIZ") and st["XIZ"][0] == "c":
                    T = st["XIZ"][1]
                    self.add(T, 0, "wordtab", "code %06x" % (pc - n),
                             stride=1 << st.get("sh_HL", 0))
                    self.objs[T].setdefault("fields", set()).add(0)
                    continue
                m = re.match(r"add (BC|WA|DE|HL),0x0*([0-9a-f]+)$", t)
                if m:
                    st["k_" + m.group(1)] = st.get("k_" + m.group(1), 0) + int(m.group(2), 16)
                    continue
                m = re.match(r"jr T,0x([0-9a-f]+)$", t)
                if m:
                    pc = int(m.group(1), 16)
                    continue
                m = re.match(r"jr [A-Z]+,0x([0-9a-f]+)$", t)
                if m and depth < 4:
                    work.append((int(m.group(1), 16), dict(st), depth + 1))
                    continue
                m = re.match(r"call 0x([0-9a-f]+)$", t)
                if m:
                    tgt = int(m.group(1), 16)
                    if tgt in self.wr or tgt == self.fromtab:
                        self.emit(st, tgt, pc - n)
                        continue
                    break
                if re.match(r"(ret|reti|jp |jrl T|djnz|halt|swi|db)", t) or t == "?":
                    break
                self.clobber(st, t)

    FAM = {"A": "WA", "W": "WA", "WA": "WA", "XWA": "WA", "B": "BC", "C": "BC",
           "BC": "BC", "XBC": "BC", "D": "DE", "E": "DE", "DE": "DE", "XDE": "DE",
           "H": "HL", "L": "HL", "HL": "HL", "XHL": "HL"}

    def clobber(self, st, t):
        """forget what an instruction overwrites"""
        m = re.match(r"(\w+) ([^,]+),([^,]+)$", t)
        if not m:
            return
        mn, a, b = m.groups()
        dest = b if mn in ("inc", "dec", "sla", "sll", "srl", "sra", "rl", "rr",
                            "rlc", "rrc") else a
        if dest in ("XIY", "XIX", "XIZ", "IY", "IX", "IZ"):
            st["X" + dest[-2:]] = None
        r = self.FAM.get(dest)
        if r and not (mn in ("sla", "sll")):
            st.pop("k_" + r, None)
            st.pop("sh_" + r, None)

    def emit(self, st, tgt, pc):
        ev = "code %06x" % pc
        y, x = st.get("XIY"), st.get("XIX")
        if tgt == self.fromtab:
            if y and y[0] == "c" and self.inr(y[1]):
                self.add(y[1], 0, "rectab_ptrs", ev)
            return
        k = self.wr[tgt]
        fam = k[0]
        if k.endswith("*"):
            if y and x and y[0] == "c" and x[0] == "c":
                if self.zone(y[1]) and self.zone(x[1] - 1) and x[1] > y[1]:
                    self.parse_list(y[1], x[1], fam, ev)
            elif y and x and y[0] == "elem" and x[0] == "elem" and y[1] == x[1] \
                    and x[2] == y[2] + 4 and self.inr(y[1]):
                kind = "bounds" if y[3] in (1, 4) else "pairs"
                self.add(y[1], 0, kind, ev, family=fam, stride=y[3])
            elif y and x and y[0] == "elem" and x[0] == "elem+" and y[1] == x[1] and self.inr(y[1]):
                self.add(y[1], 0, "startptrs", ev, family=fam, span=x[4])
            elif y and x and y[0] == "elemvar" and x[0] == "elemvar+" and y[1] == x[1] and self.inr(y[1]):
                self.add(y[1], 0, "grouptab", ev, family=fam, span=x[4])
            elif y and x and y[0] == "c" and x[0] == "elem" and self.inr(y[1]):
                # one start, several possible ends read from a table (which may
                # lie outside this block)
                T = x[1]
                p = T + x[2]
                while self.lo <= self.l(p) < 0x1000000 and self.l(p) > y[1] and self.inr(self.l(p) - 1):
                    self.parse_list(y[1], self.l(p), fam, ev + " end=table %06x" % T)
                    p += x[3]
            elif y and y[0] == "c" and self.inr(y[1]):
                # often XIX was loaded on a path this walk did not start on;
                # the walk seeded at that `ld xix` finds the list -- report
                # only if no list at all begins here (checked in finish())
                self.unresolved.append((y[1], pc, x))
        else:
            if y and y[0] == "c" and self.zone(y[1]):
                a = y[1]
                op, ln = self.b(a), self.b(a + 1)
                self.record(a, op, ln, fam, ev)
                if self.inr(a):
                    self.add(a, ln, "record1", ev, family=fam)
            elif y and y[0] == "elem" and self.inr(y[1]):
                self.add(y[1], 0, "rectab_ptrs", ev)

    def table_ptrs(self, a, monotonic=False):
        """consecutive LE32 region pointers from a, stopping at the start of
        any other known object (tables sit back to back in this block).  A
        boundary table whose last entry is its OWN address (the lists end
        exactly where the table begins) stops there."""
        p, ptrs = a, []
        while self.inr(self.l(p)) and not (p > a and p in self.objs):
            v = self.l(p)
            ptrs.append(v)
            p += 4
            if monotonic and v == a:
                break
        return ptrs

    def size_tables(self):
        """boundary tables, record-pointer tables and list-start tables; each
        pointed list/record must parse."""
        for a in sorted(self.objs):
            o = self.objs[a]
            if o["kind"] == "bounds":
                ptrs = self.table_ptrs(a, monotonic=True)
                o["size"], o["ptrs"] = 4 * len(ptrs), ptrs
                for x, y in zip(ptrs, ptrs[1:]):
                    if y > x:
                        self.parse_list(x, y, o["family"], "bounds %06x" % a)
                if "rectab_ptrs" in o.get("also", []):
                    for x in ptrs[:-1]:
                        op, ln = self.b(x), self.b(x + 1)
                        self.record(x, op, ln, "B", "recptrs %06x" % a)
            elif o["kind"] == "grouptab":
                ptrs = self.table_ptrs(a)
                o["size"], o["ptrs"] = 4 * len(ptrs), ptrs
                ends = ptrs[1:] + [a]
                for x, y in zip(ptrs, ends):
                    if y > x and (y - x) % o["span"] == 0:
                        for r in range(x, y, o["span"]):
                            self.parse_list(r, r + o["span"], o["family"], "grouptab %06x" % a)
                    else:
                        self.bad.append("grouptab %06x: group %06x-%06x not a multiple of %d"
                                        % (a, x, y, o["span"]))
            elif o["kind"] == "pairs":
                ptrs = self.table_ptrs(a)
                ptrs = ptrs[:len(ptrs) // 2 * 2]
                o["size"], o["ptrs"] = 4 * len(ptrs), ptrs
                for x, y in zip(ptrs[0::2], ptrs[1::2]):
                    if y > x:
                        self.parse_list(x, y, o["family"], "pairs %06x" % a)
            elif o["kind"] == "rectab_ptrs":
                ptrs = self.table_ptrs(a)
                o["kind"], o["size"], o["ptrs"] = "recptrs", 4 * len(ptrs), ptrs
                for x in ptrs:
                    op, ln = self.b(x), self.b(x + 1)
                    self.record(x, op, ln, "B", "recptrs %06x" % a)
                    self.add(x, ln, "record1", "recptrs %06x" % a, family="B")
            elif o["kind"] == "startptrs":
                ptrs = self.table_ptrs(a)
                o["size"], o["ptrs"] = 4 * len(ptrs), ptrs
                for x in ptrs:
                    self.parse_list(x, x + o["span"], o["family"], "startptrs %06x" % a)

    def outside_tables(self):
        """LE32 pointers into the region held OUTSIDE it (e.g. the 7-entry
        envelope-curve table read at v10 0xF0F4A9 by `ld xiz,T; ld xiy,(xiz+wa)`
        and drawn with SeGfx_StaticOp03_BlitAtCell, BC=5 bytes/row, HL=40 rows)."""
        pat = bytes.fromhex("c8d0d8ee02e307f8e025")   # xor w,w / sll 2,wa / ld xiy,(xiz+wa)
        i = self.rom.find(pat, 0xF00000 - BASE, 0xF20000 - BASE)
        while i >= 0:
            if self.rom[i - 5] == 0x46:
                t = struct.unpack_from("<I", self.rom, i - 4)[0]
                tail = self.rom[i + 10:i + 60]
                k = tail.find(b"\xd9\xad")          # ld bc,5
                h = tail.find(b"\x33\x28\x00")      # ld hl,40
                if k >= 0 and h >= 0:
                    p, n = t, 0
                    while self.inr(self.l(p)):
                        bm = self.l(p)
                        self.add(bm, 200, "bitmap", "curve table %06x entry %d (code %06x)" % (t, n, BASE + i - 5),
                                 bpr=5, rows=40)
                        p += 4
                        n += 1
            i = self.rom.find(pat, i + 1, 0xF20000 - BASE)

    def finish(self):
        starts = {a for (a, e) in self.lists}
        for (a, pc, x) in self.unresolved:
            if a not in starts:
                self.bad.append("list at %06x (call %06x) with unresolved end %r" % (a, pc, x))
        # record objects for every record not yet inside a list object
        cov = bytearray(self.hi - self.lo)
        for r, (op, ln, fam) in self.recs.items():
            for x in range(r, r + ln):
                if self.inr(x):
                    cov[x - self.lo] = 1
        for a, o in self.objs.items():
            if o["kind"] in ("bitmap", "bounds", "recptrs", "startptrs", "pairs", "grouptab"):
                for x in range(a, a + o["size"]):
                    if self.inr(x):
                        cov[x - self.lo] = 1
        # size string / box tables up to the next covered byte
        for a in sorted(self.objs):
            o = self.objs[a]
            if o["kind"] in ("strtab", "boxtab", "wordtab") and o["size"] == 0:
                p = a
                while p < self.hi and not cov[p - self.lo] and not (p > a and p in self.objs):
                    p += 1
                if o["kind"] == "boxtab":
                    # a box is {x1,y1,x2,y2} with x1<=x2<320, y1<=y2<240; the
                    # table ends at the first entry that is not one (the mask
                    # allows more values than the screen uses)
                    q, n = a, 0
                    while q + 8 <= p and n < o["maxn"]:
                        x1, y1, x2, y2 = (self.w(q + k) for k in (0, 2, 4, 6))
                        if not (x1 <= x2 < 320 and y1 <= y2 < 240):
                            break
                        q += 8
                        n += 1
                    p = q
                o["size"] = p - a
                for x in range(a, p):
                    cov[x - self.lo] = 1
        gaps, i = [], 0
        while i < len(cov):
            if not cov[i]:
                j = i
                while j < len(cov) and not cov[j]:
                    j += 1
                gaps.append((self.lo + i, self.lo + j))
                i = j
            else:
                i += 1
        return gaps


def region(v, s):
    """[lo, hi) of the block.  After lane seui's conversion the block is
    bracketed by its own labels SeScreenData / SeScreenData_End; before it,
    lo is the 24x10 icons 0xA8 bytes ahead of SeBitmap_EnvCurve1 and hi the
    first byte of storage/flash_floppy_handlers.s."""
    if "SeScreenData" in s and "SeScreenData_End" in s:
        return s["SeScreenData"], s["SeScreenData_End"]
    return s["SeBitmap_EnvCurve1"] - 0xA8, s["FlashWrite_BlockHandler_Table"]


def build(image, lo=None, hi=None, s=None):
    s = s or symbols(image)
    rlo, rhi = region(image, s)
    m = Model(image, lo or rlo, hi or rhi, s)
    m.scan_code()
    m.outside_tables()
    m.size_tables()
    gaps = m.finish()
    return m, gaps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", default="v10")
    ap.add_argument("--json")
    ap.add_argument("--lo")
    ap.add_argument("--hi")
    a = ap.parse_args()
    m, gaps = build(a.image, a.lo and int(a.lo, 16), a.hi and int(a.hi, 16))
    lo, hi = m.lo, m.hi
    kinds = {}
    for o in list(m.objs.values()) + list(m.lists.values()):
        kinds.setdefault(o["kind"], [0, 0])
        kinds[o["kind"]][0] += 1
        kinds[o["kind"]][1] += o["size"]
    print("%s region %06x-%06x (%d B); record-from-table helper at %s" %
          (a.image, lo, hi, hi - lo, m.fromtab and "%06x" % m.fromtab))
    for k, (n, sz) in sorted(kinds.items()):
        print("  %-12s %4d objects %6d B (lists/records overlap tables)" % (k, n, sz))
    print("  records parsed: %d" % len(m.recs))
    print("  problems: %d" % len(m.bad))
    for x in m.bad[:40]:
        print("    " + x)
    tot = sum(b - a_ for a_, b in gaps)
    print("  uncovered: %d B in %d gaps" % (tot, len(gaps)))
    for g in gaps:
        print("    %06x-%06x %5d  %s" % (g[0], g[1], g[1] - g[0],
                                         m.rom[g[0] - BASE:g[0] - BASE + 20].hex(" ")))
    if a.json:
        json.dump(dict(image=a.image, lo=lo, hi=hi, objects=sorted(m.objs.values(), key=lambda o: o["addr"]),
                       lists=sorted(m.lists.values(), key=lambda o: (o["addr"], o["size"])),
                       records={str(k): v for k, v in m.recs.items()}, gaps=gaps, problems=m.bad),
                  open(a.json, "w"), indent=0,
                  default=lambda o: sorted(o) if isinstance(o, set) else str(o))


if __name__ == "__main__":
    main()
