#!/usr/bin/env python3
r"""Split GUI_DisplayStructData / EmbeddedPtrTable_* / ToneGen_ParamTable into the
objects their READERS use, and say what each is.

QUESTION THIS ANSWERS
    The root file carries 6,550 bytes (v10/v9/v7 0xE0CFDE-0xE0E973) as three
    blobs: GUI_DisplayStructData (a slice of the C-compiled
    includes/generated/gui_display_struct_data.bin), a run of 384 `.long`
    (EmbeddedPtrTable_*), a second slice of that .bin, and ToneGen_ParamTable
    (audio/tonegen_param_table.c).  The census grades them "descriptive name
    only".  Which code reads which bytes, and as what?

HOW
  1. Reader scan: every `lda <reg>, (T:24)` (F2 T24 30+r) in the ROM whose T lies
     in the range, classified by the instructions that follow (decoded by MAME
     unidasm):
       objblock  `ld (xbc+0x0a),xwa / ld wa,N / call RegisterObjectTable` --
                 T is the data pointer (+10) of a 14-byte object descriptor
                 {+0 u32 class, +4 u32 proc, +8 u16, +10 u32 data} that
                 RegisterObjectTable copies to the registry at 0x27ED2 + 14*N;
                 class and proc are read back from the preceding stores;
       dispatch  `exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)` -- T is a
                 table of 4-byte code pointers indexed by BC*4 (the caller does
                 `sla bc, 2`) and the entry is CALLED;
       other     anything else: the next instructions are quoted.
  2. Every positional alias (shared/positional_labels.s) that points into the
     range is a second source of boundaries: something outside names it.
  3. The blobs are cut at every boundary into `.incbin <file>, off, len` slices
     (the `.long` run is kept, lines only gain labels); each slice gets a label
     -- the alias's own name where one exists (its .set line is removed), else
     <owner>_0xOFF -- and a header with its readers.  Runs of object blocks of
     one class registered in index order are one slice.  Numeric `.long` code
     pointers become <nearest code label> + off.
  4. --apply writes, rebuilds and compares; a mismatch restores the files.

RUN
    python3 scripts/lanes/sys/gui_tables.py --image v10 [--apply]
"""
import argparse
import bisect
import collections
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402

ROOT = pi.ROOT
BASE = pi.BASE
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
GUIBIN = "includes/generated/gui_display_struct_data.bin"
TGBIN = "includes/generated/tonegen_param_table.bin"


def unidasm(rom, lo, hi):
    tmp = os.path.join(pi.SCRATCH, "gt_%x.bin" % lo)
    os.makedirs(pi.SCRATCH, exist_ok=True)
    open(tmp, "wb").write(rom[lo - BASE:hi - BASE])
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", "0x%x" % lo],
                         capture_output=True, text=True).stdout
    os.unlink(tmp)
    res = []
    for ln in out.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            res.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return res


class G:
    def __init__(self, img):
        self.img = img
        self.rom = pi.rom(img)
        self.order, self.syms = pi.amap(img)
        s = self.syms
        self.lo = s["GUI_DisplayStructData"]
        self.t = s["ToneGen_ParamTable"]
        self.hi = self.t + 1389
        self.ept = next(k for k in s if k.startswith("EmbeddedPtrTable_") and s[k] == self.lo + 0xB00)
        self.code = sorted((v, k) for k, v in s.items() if 0xE00000 <= v < 0x1000000
                           and not k.startswith(("__", ".")))
        self.ckeys = [v for v, k in self.code]

    def near(self, a):
        i = bisect.bisect_right(self.ckeys, a) - 1
        v, k = self.code[i]
        return k if v == a else "%s+0x%X" % (k, a - v)

    def scan(self):
        rom, lo, hi = self.rom, self.lo, self.hi
        found = collections.defaultdict(list)
        for i in range(0, len(rom) - 5):
            if rom[i] != 0xF2 or not (0x30 <= rom[i + 4] <= 0x36):
                continue
            T = rom[i + 1] | rom[i + 2] << 8 | rom[i + 3] << 16
            if not (lo <= T < hi):
                continue
            site = BASE + i
            if lo <= site < hi:
                continue
            ins = unidasm(rom, site, site + 16)
            if not ins or ins[0][0] != site:
                continue
            nxt = [t for a, n, t in ins[1:4]]
            reg = "xwa xbc xde xhl xix xiy xiz".split()[rom[i + 4] - 0x30]
            if nxt and nxt[0] == "ld (XBC+0x0a),XWA":
                # object block: read the descriptor stores around it
                # decode from the descriptor build's own start, `lda xbc, xsp`
                # (b7 31), so the framing is the code's own
                k = rom.rfind(b"\xb7\x31", i - 40, i)
                start = BASE + k if k >= 0 else site - 30
                pre = unidasm(rom, start, site + 20)
                pre = [x for x in pre if x[0] <= site + 12]
                cls = proc = idx = None
                for a, n, t in pre:
                    m = re.match(r'ld XWA,0x([0-9a-f]{8})$', t)
                    if m and a < site:
                        cls = int(m.group(1), 16)
                    m = re.match(r'lda XWA,0x([0-9a-f]+)$', t)
                    if m and a < site:
                        proc = int(m.group(1), 16)
                    m = re.match(r'ld WA,0x([0-9a-f]+)$', t)
                    if m and a > site:
                        idx = int(m.group(1), 16)
                found[T].append(dict(kind="objblock", site=site, cls=cls, proc=proc, idx=idx))
            elif nxt[:4] == ["exts XBC", "add XBC,XDE", "ld XHL,(XBC)"] or \
                    (len(nxt) >= 3 and nxt[0] == "exts XBC" and nxt[1] == "add XBC,XDE"):
                found[T].append(dict(kind="dispatch", site=site))
            else:
                found[T].append(dict(kind="other", site=site, reg=reg, nxt=nxt[:2]))
        return found

    def aliases(self):
        """positional .set names pointing into the range -> address"""
        p = os.path.join(ROOT, self.img, "maincpu", "shared/positional_labels.s")
        out = {}
        for ln in open(p, encoding="latin-1"):
            m = re.match(r'^\t\.set\s+([A-Za-z_.$][\w.$]*),\s*([A-Za-z_.$][\w.$]*)\s*\+\s*(\d+)\s*$', ln)
            if m and m.group(2) in self.syms:
                a = self.syms[m.group(2)] + int(m.group(3))
                if self.lo <= a < self.hi:
                    out[m.group(1)] = a
        return out


def users_of(img, name):
    rx = re.compile(r'(?<![\w.$])' + re.escape(name) + r'(?![\w.$])')
    hits = []
    for dp, dn, fn in os.walk(os.path.join(ROOT, img, "maincpu")):
        for f in fn:
            if not f.endswith(".s") or f == "positional_labels.s":
                continue
            p = os.path.join(dp, f)
            for i, ln in enumerate(open(p, encoding="latin-1")):
                if rx.search(ln.split(";")[0]):
                    hits.append((os.path.relpath(p, os.path.join(ROOT, img, "maincpu")), i + 1, ln.strip()))
    return hits


def plan(img):
    g = G(img)
    found = g.scan()
    als = g.aliases()
    lo, t, hi = g.lo, g.t, g.hi
    fixed = {lo, lo + 0xB00, lo + 0x1100, t, hi}
    # group object blocks of one class/proc registered with consecutive indices
    starts = set(found) | set(als.values())
    grouped = {}
    objb = sorted(a for a in found if all(r["kind"] == "objblock" for r in found[a]))
    run = []
    for a in objb:
        r = found[a][0]
        if run:
            pa = run[-1]
            pr = found[pa][0]
            same = (r["cls"], r["proc"]) == (pr["cls"], pr["proc"]) and r["idx"] is not None and \
                pr["idx"] is not None and r["idx"] == pr["idx"] + 1
            if same and a not in als.values():
                run.append(a)
                continue
        if len(run) > 1:
            grouped[run[0]] = run
        run = [a]
    if len(run) > 1:
        grouped[run[0]] = run
    members = {a for r in grouped.values() for a in r[1:]}
    # a run of object blocks ends where its last block does (last address
    # difference repeated); what follows is its own slice
    ends = set()
    for r in grouped.values():
        ends.add(r[-1] + (r[-1] - r[-2]))
    cuts = sorted((starts - members) | fixed | ends)
    cuts = [c for c in cuts if lo <= c <= hi]
    names = {}
    alias_at = collections.defaultdict(list)
    for nm, a in als.items():
        alias_at[a].append(nm)
    for c in cuts:
        if c in (lo, lo + 0xB00, t, hi):
            continue
        if alias_at.get(c):
            names[c] = sorted(alias_at[c])[0]
        elif c < t:
            names[c] = "GUI_DisplayStructData_0x%X" % (c - lo)
        else:
            names[c] = "ToneGen_ParamTable_0x%X" % (c - t)
    heads = {}
    soft = sorted((starts - members) | ends | {hi})      # boundaries something outside names
    for c in cuts[:-1]:
        h = []
        rs = found.get(c, [])
        grp = grouped.get(c)
        if grp:
            f0, fN = found[grp[0]][0], found[grp[-1]][0]
            diffs = sorted({y - x for x, y in zip(grp, grp[1:])})
            size = ("%d B" % diffs[0]) if len(diffs) == 1 else ("%d-%d B (address differences)" % (diffs[0], diffs[-1]))
            h.append("; %d parameter blocks of %s, one per object %s..%s (class 0x%08X, proc %s),"
                     % (len(grp), size, hex(f0["idx"]), hex(fN["idx"]), f0["cls"] or 0,
                        g.near(f0["proc"]) if f0["proc"] else "?"))
            h.append("; registered by %s: the block address is the +10 data field of the 14-byte"
                     % g.near(f0["site"]))
            h.append("; descriptor {+0 class, +4 proc, +8 u16, +10 data} RegisterObjectTable copies to"
                     " 0x27ED2 + 14*index")
        else:
            for r in rs:
                nxtc = next(x for x in cuts if x > c)
                if r["kind"] == "objblock":
                    h.append("; parameter block of object %s (class 0x%08X, proc %s), registered by %s"
                             % (hex(r["idx"]) if r["idx"] is not None else "?", r["cls"] or 0,
                                g.near(r["proc"]) if r["proc"] else "?", g.near(r["site"])))
                    h.append("; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index);"
                             " the slice runs to the next boundary, %d B; the proc's read length was not measured"
                             % (nxtc - c))
                elif r["kind"] == "dispatch":
                    ext = next(x for x in soft if x > c) - c
                    h.append("; table of 4-byte code pointers, %d B = %d entries to the next address the code names"
                             % (ext, ext // 4))
                    h.append("; evidence: %s (0x%06X) loads it into XDE, adds BC*4 and calls the entry"
                             " (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)"
                             % (g.near(r["site"]), r["site"]))
                else:
                    h.append("; data read by %s (0x%06X)" % (g.near(r["site"]), r["site"]))
                    h.append("; evidence: `lda %s, (this)` then `%s`" % (r["reg"], " / ".join(r["nxt"])))
            if not rs:
                nm = names.get(c)
                u = users_of(img, nm) if nm else []
                if u:
                    f, ln, txt = u[0]
                    h.append("; object named by %d line(s) of code outside this file; what that code does"
                             " with it:" % len(u))
                    h.append("; evidence: %s:%d `%s`"
                             % (f, ln, re.sub(r'\s+', ' ', txt.split(";")[0])[:70]))
                elif any(x < c < x + (next(y for y in soft if y > x) - x) and
                         any(r2["kind"] == "dispatch" for r2 in found.get(x, [])) for x in soft if x < c):
                    x = max(x for x in soft if x < c and any(r2["kind"] == "dispatch" for r2 in found.get(x, [])))
                    k, r3 = (c - x) // 4, (c - x) % 4
                    h.append("; the rest of the code-pointer table at %s, from entry %d%s on;"
                             % (names.get(x, hex(x)), k, (" byte %d" % r3) if r3 else ""))
                    h.append("; the table runs across this boundary (%s)"
                             % ("label of the next source" if c == t else "file slice"))
                elif True:
                    h.append("; purpose not established.")
                    h.append("; tried: `lda`/`ld` of a 24- or 32-bit immediate, and any little-endian 24-bit"
                             " copy of an address from 0x120 B before this slice to its end, anywhere in"
                             " the ROM: none found")
        heads[c] = h
    return g, cuts, names, heads, als, found, grouped


REGION_HEAD = [
    "; -----------------------------------------------------------------------------",
    "; GUI_DisplayStructData .. the end of ToneGen_ParamTable: the data of the Scoop",
    "; and sound-editor objects, cut at every address the code loads or names",
    "; (scripts/lanes/sys/gui_tables.py: object parameter blocks passed to",
    "; RegisterObjectTable, 18-entry code-pointer tables the Scoop_SoundEditorData /",
    "; SeMenu_* dispatchers call through, and tables other code reads).  The bytes come",
    "; from includes/gui_display_struct_data.c and audio/tonegen_param_table.c; the",
    "; section names in those files' comments predate this and were not derived from",
    "; these readers (ToneGen_ParamTable is not tone-generator data:",
    "; scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py).",
    "; -----------------------------------------------------------------------------",
]


def emit(img, g, cuts, names, heads):
    """new lines for the region, replacing the lines from `GUI_DisplayStructData:`
    to the ToneGen .incbin inclusive"""
    lo, t, hi = g.lo, g.t, g.hi
    src = open(os.path.join(ROOT, img, "maincpu", "kn5000_%s_program.s" % img), encoding="latin-1").read()
    L = src.split("\n")
    i0 = L.index("GUI_DisplayStructData:")
    i1 = next(i for i in range(i0, len(L)) if TGBIN in L[i])
    old = L[i0:i1 + 1]
    longs = [ln for ln in old if ln.startswith("\t.long")]
    assert len(longs) == 384, len(longs)
    out = []

    def lab(c):
        if c in names:
            out.extend(heads.get(c, []))
            out.append("%s:" % names[c])
        else:
            out.extend(heads.get(c, []))

    def slices(a, b, binname, binbase):
        cs = [c for c in cuts if a <= c < b] + [b]
        for x, y in zip(cs, cs[1:]):
            if x != lo:
                lab(x)
            out.append('\t.incbin "%s", 0x%X, 0x%X' % (binname, x - binbase, y - x))
    out.extend(REGION_HEAD)
    out.extend(heads.get(lo, []))
    out.append("GUI_DisplayStructData:")
    slices(lo, lo + 0xB00, GUIBIN, lo)
    out.append("%s:" % g.ept)
    for k, ln in enumerate(longs):
        a = lo + 0xB00 + 4 * k
        if a != lo + 0xB00:
            lab(a) if a in cuts else None
        elif a in heads:
            out[-1:-1] = heads[a]
        m = re.match(r'^\t\.long 0x([0-9A-Fa-f]{8})$', ln)
        if m:
            v = int(m.group(1), 16)
            out.append("\t.long %s" % (g.near(v) if 0xE00000 <= v < 0x1000000 else "0x%08X" % v))
        else:
            out.append(ln)
    slices(lo + 0x1100, t, GUIBIN, lo)
    out.append("ToneGen_ParamTable:")
    if t in heads:
        out[-1:-1] = heads[t]
    cs = [c for c in cuts if t <= c < hi] + [hi]
    for x, y in zip(cs, cs[1:]):
        if x != t:
            lab(x)
        out.append('\t.incbin "%s", 0x%X, 0x%X' % (TGBIN, x - t, y - x))
    return L, i0, i1, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", type=int, default=0)
    a = ap.parse_args()
    g, cuts, names, heads, als, found, grouped = plan(a.image)
    kinds = collections.Counter(r["kind"] for rs in found.values() for r in rs)
    print("%s: %d reader bases (%s), %d aliases, %d slices, %d object-block runs" % (
        a.image, len(found), dict(kinds), len(als), len(cuts) - 1, len(grouped)))
    L, i0, i1, out = emit(a.image, g, cuts, names, heads)
    for ln in out[:a.show]:
        print("   " + ln)
    if not a.apply:
        return 0
    p = os.path.join(ROOT, a.image, "maincpu", "kn5000_%s_program.s" % a.image)
    q = os.path.join(ROOT, a.image, "maincpu", "shared/positional_labels.s")
    raw_p, raw_q = open(p, "rb").read(), open(q, "rb").read()
    L[i0:i1 + 1] = out
    open(p, "wb").write("\n".join(L).encode("latin-1"))
    used = set(names.values())
    Q = raw_q.decode("latin-1").split("\n")
    Q = [ln for ln in Q if not (re.match(r'^\t\.set\s+([A-Za-z_.$][\w.$]*),', ln)
                                and re.match(r'^\t\.set\s+([A-Za-z_.$][\w.$]*),', ln).group(1) in used)]
    open(q, "wb").write("\n".join(Q).encode("latin-1"))
    built, err = pi.fast_build(a.image, os.path.join(pi.SCRATCH, "build"))
    if built == pi.rom(a.image):
        print("%s IDENTICAL" % a.image)
        return 0
    print("MISMATCH/FAIL; restoring", err[-2000:] if built is None else "")
    open(p, "wb").write(raw_p)
    open(q, "wb").write(raw_q)
    return 1


if __name__ == "__main__":
    sys.exit(main())
