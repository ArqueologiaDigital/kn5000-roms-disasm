#!/usr/bin/env python3
r"""Label and document the sound editor's screen data that continues into
storage/flash_floppy_handlers.s, from its readers.

QUESTION THIS ANSWERS
    storage/flash_floppy_handlers.s opens (v10/v9 0xF158A7-0xF165EA, v7 0x2A
    lower) with 3,396 bytes that carry names like FlashWrite_BlockData_Type0,
    FlashRead_BlockHandler_Table, DrumDetailEdit_Menu_Table and
    EffectParam_Edit_Table.  They are not flash-write or drum-edit data: they
    are the tail of the sound editor's ScreenData block that lane seui modelled
    (scripts/lanes/sys/se_screendata_model_seui.py, vendored from s2/seui).
    What is each object there, which code reads it, and what should it be
    called?

HOW
    1. The seui model, run with --lo/--hi over this file's range, parses every
       record list the sound-editor code draws (each list must parse exactly to
       the end its code gives), the single records, the record-pointer tables,
       the list-boundary table, and the string / box tables bound records point
       at.  0 problems in all three images.
    2. The six objects the model leaves as gaps are per-variant tables it has
       no pattern for; they are pinned here by hand from their readers:
         * FlashWrite_BlockRef_Type6 + 0x10: 12 pointers, indexed by the byte at
           RAM 0x670 in SeMenu_PatchEdit_DataBlock (`xor xbc,xbc / ld xiz,T /
           ld c,(0x670) / sla 2,bc / ld xiy,(xiz+bc)`), each to a record-pointer
           table handed to SeMenu_EqEdit_DrawInit_0x15 (`sla 2,wa / add xiy,xwa /
           ld xiy,(xiy) / call` -- XIY = table[WA]);
         * FlashWrite_BlockRef_Type6 + 0x40: 12 list END pointers indexed the same
           way in SeMenu_NameEdit_DataBlock1 (`ld xix,(xiz+bc)`), with the list
           start fixed by `ld xiy, <start>` just before;
         * the record-pointer tables those entries name (one per bound list: the
           records of the list, entry 0 repeated).
    3. Every object start gets ONE label: an existing label that other lanes'
       files use is kept (its misnomer is noted); an existing label used only in
       this lane's files is renamed SeScreenData_0xNNNN; otherwise a new
       SeScreenData_0xNNNN is inserted (NNNN = offset from the block base,
       FlashWrite_BlockHandler_Table - 0x4CA1, the same numbering lane seui uses
       for the part of the block in audio/sound_editor_ui.s).  Positional aliases
       (shared/positional_labels.s) and numeric `.set`s in the root file that
       name the same address are pointed at that label.
    4. Above each label: one line saying what the object is and what reads it,
       one `; evidence:` line naming the code.

RUN
    python3 scripts/lanes/sys/ff_screendata_headers.py --image v10 [--apply]
"""
import argparse
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402
import se_screendata_model_seui as sm  # noqa: E402

ROOT = pi.ROOT
BASE = pi.BASE
REL = "storage/flash_floppy_handlers.s"
BLOCK_OFF = 0x4CA1          # FlashWrite_BlockHandler_Table - SeScreenData (v10 0xF158A7 - 0xF10C06)
KEEP_EXTERNAL = {"FlashWrite_BlockHandler_Table", "FlashRead_BlockHandler_Table",
                 "EffectParam_Edit_Table", "FlashWrite_BlockRef_Type6", "DrumDetailEdit_Menu_Table"}
READER = {"S": "GraphicsRender_ProcessEntries", "B": "GraphicsRender_Start"}
FAMW = {"S": "static", "B": "bound"}


def owned_files(img):
    sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import json
    import lane_worklists as lw
    lanes = json.load(open(lw.ROSTER))["lanes"]
    return {p for p in lw.tracked() if lw.owner(p, lanes) == "sys" and p.startswith(img + "/")}


_TEXTS = {}


def users(name, img):
    if img not in _TEXTS:
        _TEXTS[img] = {}
        for dp, dn, fn in os.walk(os.path.join(ROOT, img, "maincpu")):
            for f in fn:
                if f.endswith(".s"):
                    p = os.path.join(dp, f)
                    _TEXTS[img][os.path.relpath(p, ROOT)] = open(p, encoding="latin-1").read()
    rx = re.compile(r'(?<![\w.$])' + re.escape(name) + r'(?![\w.$])')
    return {p for p, t in _TEXTS[img].items() if rx.search(t)}


class Doc:
    def __init__(self, img):
        self.img = img
        self.s = sm.symbols(img)
        self.rom = pi.rom(img)
        self.lo = self.s["FlashWrite_BlockHandler_Table"]
        self.hi = self.s["InitializeNaka"]
        self.base = self.lo - BLOCK_OFF
        self.m, self.gaps = sm.build(img, self.lo, self.hi, s=self.s)
        assert not self.m.bad, self.m.bad
        self.byaddr = {}
        for k, v in self.s.items():
            if BASE <= v < 0x1000000 and not k.startswith(("__", ".")):
                self.byaddr.setdefault(v, []).append(k)
        self.code_names = sorted((v, k) for k, v in self.s.items() if 0xF00000 <= v < 0xF158A7
                                 and not k.startswith(("__", ".")))

    def l(self, a):
        return struct.unpack_from("<I", self.rom, a - BASE)[0]

    def where(self, a):
        """nearest code label at or before a"""
        import bisect
        ks = [v for v, k in self.code_names]
        i = bisect.bisect_right(ks, a) - 1
        v, k = self.code_names[i]
        return "%s (0x%06X)" % (k, a) if v == a else "%s+0x%X (0x%06X)" % (k, a - v, a)

    def name(self, a):
        return "SeScreenData_0x%04X" % (a - self.base)

    def ev_text(self, ev):
        out = []
        for e in ev:
            m = re.match(r'code ([0-9a-f]+)', e)
            if m:
                out.append(self.where(int(m.group(1), 16)))
                continue
            m = re.match(r'(pairs|recptrs|bounds|startptrs|grouptab) ([0-9a-f]+)', e)
            if m:
                out.append("%s table 0x%06X" % (m.group(1), int(m.group(2), 16)))
                continue
            m = re.match(r'bound op([0-9a-f]+) record ([0-9a-f]+)', e)
            if m:
                out.append("bound op%s record 0x%06X" % (m.group(1), int(m.group(2), 16)))
                continue
            out.append(e)
        return out

    def objects(self):
        """addr -> list of (kind, size, text, evidence)"""
        by = collections.defaultdict(list)
        m = self.m
        for (x, e), o in m.lists.items():
            n = o.get("nrec", 0)
            by[x].append(("list", o["size"],
                          "%s record list (%d records {u8 op, u8 len, payload}), read by %s; ends 0x%06X"
                          % (FAMW[o["family"]], n, READER[o["family"]], x + o["size"]),
                          self.ev_text(o["ev"])))
        for a, o in m.objs.items():
            k = o["kind"]
            if k == "record1":
                op, ln = self.rom[a - BASE], self.rom[a - BASE + 1]
                txt = "single %s record (op 0x%02X, %d B), read by %s" % (FAMW[o["family"]], op, ln,
                                                                        READER[o["family"]])
            elif k == "recptrs":
                txt = ("table of %d pointers to bound records; the code loads it into XIY and "
                       "SeMenu_EqEdit_DrawInit_0x15 draws entry WA (XIY = (XIY + 4*WA))" % (o["size"] // 4))
            elif k == "pairs":
                txt = ("list-boundary table, %d x {u32 start, u32 end} of bound record lists; the code "
                       "reads XIY = (T+8i), XIX = (T+8i+4)" % (o["size"] // 8))
            elif k == "strtab":
                txt = ("fixed-width string table, %d chars per entry, %d B: the text choices of a bound "
                       "op02/op07 record (its +7 pointer; +11 = chars per entry)" % (o["width"], o["size"]))
            elif k == "boxtab":
                txt = ("table of %d boxes {u16 x1, y1, x2, y2}, indexed by the masked value of a bound "
                       "op03/04/08 record (its +7 pointer)" % (o["size"] // 8))
            else:
                txt = "%s (%d B)" % (k, o["size"])
            by[a].append((k, o["size"], txt, self.ev_text(o["ev"])))
        # --- the gap tables, pinned by hand (see the module docstring)
        t6 = self.s["FlashWrite_BlockRef_Type6"]
        pat = self.s.get("SeMenu_PatchEdit_DataBlock")
        nam = self.s.get("SeMenu_NameEdit_DataBlock1")
        ev10 = [self.where(pat)] if pat else []
        ev40 = [self.where(nam)] if nam else []
        by[t6 + 0x10].append(("vartab", 48, "12 pointers to record-pointer tables, one per screen "
                              "variant = the byte at RAM 0x670; entry -> SeMenu_EqEdit_DrawInit_0x15", ev10))
        by[t6 + 0x40].append(("vartab", 48, "12 list END pointers, one per screen variant = the byte at "
                              "RAM 0x670, for the static list the code starts with `ld xiy, <start>`", ev40))
        for i in range(12):
            tab = self.l(t6 + 0x10 + 4 * i)
            if self.lo <= tab < self.hi and not any(k in ("recptrs",) for k, *_ in by[tab]):
                ptrs = []
                p = tab
                while self.lo <= self.l(p) < self.hi and (p == tab or p not in by):
                    ptrs.append(self.l(p))
                    p += 4
                txt = ("table of %d pointers to the records of the list at 0x%06X (entry 0 repeated); "
                       "entry %d of the per-variant table at 0x%06X, drawn one record at a time by "
                       "SeMenu_EqEdit_DrawInit_0x15 (XIY = (XIY + 4*WA))" % (len(ptrs), ptrs[0], i, t6 + 0x10))
                by[tab].append(("recptrs", 4 * len(ptrs), txt, ev10))
        return by


def plan(img):
    D = Doc(img)
    by = D.objects()
    own = owned_files(img)
    order, syms = pi.amap(img)
    rows = [(k, e) for k, e in enumerate(order) if e[1] == REL]
    # label lines and first byte line at each address
    labels_at = collections.defaultdict(list)
    first_line = {}
    for k, e in rows:
        if e[0] is None:
            continue
        labs, body, com = pi.split_line(e[3])
        for lab in labs:
            labels_at[e[0]].append((e[2], lab))
        if body and e[4] > 0 and e[0] not in first_line:
            first_line[e[0]] = e[2]
    edits = []          # (line, [new lines], rename(old,new) or None)
    renames, aliases, problems = {}, {}, []
    for a in sorted(by):
        if not (D.lo <= a < D.hi):
            continue
        roles = by[a]
        if a not in first_line and not labels_at.get(a):
            problems.append("0x%06X: not a line start" % a)
            continue
        here = [lab for ln, lab in labels_at.get(a, []) if not lab.startswith(".")]
        keep = [x for x in here if x in KEEP_EXTERNAL or not (users(x, img) <= own)]
        mine = [x for x in here if x not in keep]
        if keep:
            canon = keep[0]
        elif mine:
            canon = D.name(a)
            for x in mine:
                renames[x] = canon
        else:
            canon = D.name(a)
        # other names for the same address (positional .set aliases, numeric .sets)
        for nm in D.byaddr.get(a, []):
            if nm not in here and nm != canon:
                aliases[nm] = canon
        head = []
        for kind, size, txt, ev in roles:
            head.append("; %s" % txt)
            if ev:
                head.append("; evidence: %s" % ", ".join(ev[:3]))
        if keep:
            head.append("; (name %s kept: other files use it; the object is ScreenData, see above)" % canon)
        ln = labels_at[a][0][0] if labels_at.get(a) else first_line[a]
        newlab = [] if (keep or mine) else ["%s:" % canon]
        edits.append((ln, head + newlab))
    return D, edits, renames, aliases, problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    D, edits, renames, aliases, problems = plan(a.image)
    print("%s: %d objects documented, %d labels renamed, %d aliases retargeted, %d problems" % (
        a.image, len(edits), len(renames), len(aliases), len(problems)))
    for p in problems:
        print("  PROBLEM", p)
    for k, v in sorted(renames.items()):
        print("  rename %s -> %s" % (k, v))
    for k, v in sorted(aliases.items()):
        print("  alias  %s -> %s" % (k, v))
    if not a.apply:
        for ln, new in edits[:12]:
            print("  @%d" % ln)
            for x in new:
                print("     " + x)
        return 0
    path = os.path.join(ROOT, a.image, "maincpu", REL)
    L = open(path, "rb").read().decode("latin-1").split("\n")
    for ln, new in sorted(edits, key=lambda x: -x[0]):
        L[ln - 1:ln - 1] = new
    txt = "\n".join(L)
    for old, new in renames.items():
        txt = re.sub(r'(?<![\w.$])' + re.escape(old) + r'(?![\w.$])', new, txt)
    open(path, "wb").write(txt.encode("latin-1"))
    # aliases: positional .set lines and numeric root .sets
    for rel in ("shared/positional_labels.s", "kn5000_%s_program.s" % a.image):
        p = os.path.join(ROOT, a.image, "maincpu", rel)
        t = open(p, "rb").read().decode("latin-1")
        for old, new in renames.items():
            t = re.sub(r'(?<![\w.$])' + re.escape(old) + r'(?![\w.$])', new, t)
        for nm, canon in aliases.items():
            t, n = re.subn(r'(\t\.set\s+%s,\s*)[^\n;]+' % re.escape(nm), r'\g<1>%s' % canon, t)
        open(p, "wb").write(t.encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
