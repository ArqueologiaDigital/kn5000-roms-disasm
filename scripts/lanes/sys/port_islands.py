#!/usr/bin/env python3
r"""Port disassembled source lines from one maincpu version onto the undecoded
`.byte` / `.incbin` islands of another, by byte alignment, refusing anything
that does not re-assemble to the destination's own bytes.

QUESTION THIS ANSWERS
    A `.byte` run (or a romslice `.incbin`) in, say, v7's copy of a file sits
    between instructions, and the same routine is disassembled in v10.  Which
    v10 lines, re-targeted to v7's addresses and operand values, reproduce the
    v7 island byte for byte?  Those lines replace the island; every byte no v10
    line explains stays `.byte`.

HOW (per island [lo, hi) of the destination image)
  1. Address maps of both trees (scripts/analysis/address_line_map.py's marker
     technique; order of every source line, with its address and size).
  2. Anchor: the nearest label above the island that both trees define gives a
     first delta; difflib then aligns dst[lo-CTX, hi+CTX) against a src window
     around lo+delta.  Equal blocks and EQUAL-LENGTH replace gaps between them
     map src bytes to dst addresses (piecewise delta).
  3. A src line whose bytes all map with ONE delta into [lo, hi) is a candidate.
     Its text is rewritten for dst: a symbol operand is kept when the dst tree
     gives it the value the dst bytes need, else a dst label at that value is
     used, else the number; relative-branch targets come from the dst bytes.
  4. EVERY candidate is assembled in isolation with all symbols replaced by the
     required numbers and must reproduce the dst bytes exactly, else it stays
     `.byte`.
  5. Labels: every dst label inside the island stays at its address (an item
     that would straddle one is demoted to `.byte`).  A src label is added at
     its mapped address only if the dst tree defines no symbol of that name and
     no label already sits there.  Src comments on ported lines come along
     (marked as carried from the src version); every dst comment of the island
     is re-emitted at its address.
  6. --apply rewrites the island lines, rebuilds dst (llvm-mc + ld.lld +
     objcopy into a scratch dir) and compares with the dump; lines covering a
     differing byte are demoted and the loop repeats.  A final mismatch
     restores the file.

Adapted from the audio lane's scripts/converters/port_v10_span_to_v7.py
(s2/audio 67da248f): assemble_lines/assemble_all and the operand-substitution
rule are that tool's, re-written for arbitrary (src, dst) pairs and for
per-island replacement instead of whole-file regeneration.

RUN
    python3 scripts/lanes/sys/port_islands.py --src v10 --dst v7 \
        --file storage/flash_floppy_handlers.s [--line N ...] [--min 8] [--apply]
    (--line restricts to the island(s) starting at those dst line numbers)
"""
import argparse
import bisect
import collections
import difflib
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import address_line_map as alm  # noqa: E402

BASE = 0xE00000
MC, NM, OBJCOPY, LLD = alm.MC, alm.NM, alm.OBJCOPY, alm.LLD
SCRATCH = os.environ.get("PORT_SCRATCH", "/tmp/claude-1000/lane-sys/port")
REL = {"jr", "jrl", "calr", "djnz", "djnz16", "djnz8"}
REL_W = {"jr": 1, "djnz": 1, "djnz8": 1, "jrl": 2, "calr": 2, "djnz16": 2}
RESERVED = set("""a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz xsp
    ixl ixh iyl iyh izl izh qa qw qb qc qd qe qh ql qwa qbc qde qhl qix qiy qiz qsp
    ra rw rb rc rd re rh rl t f z nz nc ov nov pl mi ge lt gt le uge ult ugt ule eq ne
    v nv m p sr pc opc i3 io""".split())
IDENT = re.compile(r'(?<![\w.$])([A-Za-z_.$][\w.$]*)')
NUM = re.compile(r'(?<![\w.$])(-?0x[0-9a-fA-F]+|-?\d+)(?![\w.$])')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):')
DATA_DIR = re.compile(r'^\.(byte|incbin)\b')
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')


# ------------------------------------------------------------------ maps
def rom(img):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % img), "rb").read()


def tree_key(img):
    import hashlib
    h = hashlib.sha1()
    top = os.path.join(ROOT, img, "maincpu")
    for dp, dn, fn in sorted(os.walk(top)):
        for f in sorted(fn):
            if f.endswith((".s", ".ld", ".bin")):
                q = os.path.join(dp, f)
                h.update(q.encode())
                h.update(open(q, "rb").read())
    return h.hexdigest()[:16]


def amap(img):
    import json
    key = tree_key(img)
    cf = os.path.join(SCRATCH, "map_%s_%s.json" % (img, key))
    if os.path.exists(cf):
        d = json.load(open(cf))
        return d["order"], d["syms"]
    order, syms = amap_build(img)
    os.makedirs(SCRATCH, exist_ok=True)
    json.dump({"order": order, "syms": syms}, open(cf, "w"))
    return order, syms


def amap_build(img):
    """-> (order, syms): order = [addr|None, rel, line, text] for every line of
    every file in emission order; syms = every defined symbol's value."""
    alm.SRCDIR = os.path.join(ROOT, "%s/maincpu" % img)
    alm.ROOT_S = "kn5000_%s_program.s" % img
    ent, tmp, elf = alm.build()
    subprocess.run([OBJCOPY, "-O", "binary", elf, os.path.join(tmp, "m.rom")], check=True)
    blob = open(os.path.join(tmp, "m.rom"), "rb").read()
    if blob != rom(img):
        sys.exit("%s: address-map mirror is not byte-identical to the dump; refusing" % img)
    pos = {}
    for a, src, line, text in ent:
        rel = os.path.relpath(os.path.join(ROOT, src), alm.SRCDIR)
        pos[(rel, line)] = a
    order = []

    def walk(rel):
        lines = open(os.path.join(alm.SRCDIR, rel), encoding="latin-1").read().split("\n")
        for i, ln in enumerate(lines):
            order.append([pos.get((rel, i + 1)), rel, i + 1, ln])
            m = re.match(r'^\s*\.include\s+"([^"]+)"', ln.split(";")[0])
            if m:
                walk(m.group(1))
    walk(alm.ROOT_S)
    syms = {}
    for line in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3 and not p[2].startswith(alm.MARK):
            syms[p[2]] = int(p[0], 16)
    shutil.rmtree(tmp, ignore_errors=True)
    fill(order)
    return order, syms


def fill(order):
    """give every line a size (bytes it emits); lines with no marker get None addr."""
    marked = [i for i, e in enumerate(order) if e[0] is not None]
    for e in order:
        e.append(0)
    for k, i in enumerate(marked):
        code = order[i][3].split(";")[0].strip()
        body = LABEL.sub("", code).strip()
        if not body or body.startswith(".include"):
            continue
        j = marked[k + 1] if k + 1 < len(marked) else None
        order[i][4] = (order[j][0] - order[i][0]) if j is not None else 0


# ------------------------------------------------------------------ text helpers
def split_line(text):
    code, sep, com = text.partition(";")
    if code.count('"') % 2 == 1:
        code, com, sep = text, "", ""
    labels = []
    rest = code.strip()
    while True:
        m = LABEL.match(rest)
        if not m:
            break
        labels.append(m.group(1))
        rest = rest[m.end():].strip()
    return labels, rest, (";" + com) if sep else ""


def le(b, off, w):
    return int.from_bytes(b[off:off + w], "little")


def sval(v, w):
    return v - (1 << (8 * w)) if v >= 1 << (8 * w - 1) else v


def assemble_lines(texts, incdir):
    d = tempfile.mkdtemp(prefix="porti-")
    src = ['\t.include "shared/macros.s"', "\t.text"]
    for i, t in enumerate(texts):
        src.append("__t%d:" % i)
        src.append("\t" + t)
    src.append("__t%d:" % len(texts))
    open(os.path.join(d, "t.s"), "w", encoding="latin-1").write("\n".join(src) + "\n")
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", incdir,
                        "-o", os.path.join(d, "t.o"), os.path.join(d, "t.s")], capture_output=True, text=True)
    if r.returncode != 0:
        bad = set()
        for m in re.finditer(r't\.s:(\d+):\d+: error', r.stderr):
            bad.add((int(m.group(1)) - 4) // 2)
        shutil.rmtree(d)
        return None, bad
    subprocess.run([OBJCOPY, "-O", "binary", "-j", ".text", os.path.join(d, "t.o"), os.path.join(d, "t.bin")],
                   check=True)
    blob = open(os.path.join(d, "t.bin"), "rb").read()
    off = {}
    for line in subprocess.run([NM, os.path.join(d, "t.o")], capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3 and p[2].startswith("__t"):
            off[int(p[2][3:])] = int(p[0], 16)
    shutil.rmtree(d)
    return [blob[off[i]:off[i + 1]] if i in off and i + 1 in off else None for i in range(len(texts))], set()


def assemble_all(texts, incdir):
    dead = set()
    for _ in range(80):
        live = [i for i in range(len(texts)) if i not in dead]
        if not live:
            break
        res, bad = assemble_lines([texts[i] for i in live], incdir)
        if res is not None:
            out = [None] * len(texts)
            for k, i in enumerate(live):
                out[i] = res[k]
            return out
        if not bad:
            break
        for b in bad:
            if 0 <= b < len(live):
                dead.add(live[b])
    return [None] * len(texts)


def defined_names(img):
    """every name defined as a label or .set/.equ anywhere in the image's tree"""
    names = set()
    top = os.path.join(ROOT, img, "maincpu")
    for dp, dn, fn in os.walk(top):
        for f in fn:
            if not f.endswith(".s"):
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                code = ln.split(";")[0]
                for m in re.finditer(r'(?:^|:)\s*([A-Za-z_.$][\w.$]*):', code):
                    names.add(m.group(1))
                m = re.match(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$]*)\s*,', code)
                if m:
                    names.add(m.group(1))
    return names


# ------------------------------------------------------------------ islands
def islands(order, rel, minsize, only_lines=None):
    """maximal runs of `.byte`/`.incbin` lines of file REL (label-only, blank
    and comment lines may sit inside a run).  -> list of (k0, k1, lo, hi) with
    order indices [k0, k1) of the run's lines."""
    out = []
    idx = [k for k, e in enumerate(order) if e[1] == rel]
    run = None
    for k in idx:
        e = order[k]
        labs, body, com = split_line(e[3])
        if body and DATA_DIR.match(body) and e[0] is not None and e[4] > 0:
            if run is None:
                run = [k, k + 1, e[0], e[0] + e[4]]
            else:
                if e[0] != run[3]:
                    out.append(run)
                    run = [k, k + 1, e[0], e[0] + e[4]]
                else:
                    run[1] = k + 1
                    run[3] = e[0] + e[4]
            continue
        if not body:
            continue          # label / comment / blank: may sit inside a run
        if run is not None:
            out.append(run)
            run = None
    if run is not None:
        out.append(run)
    res = []
    for k0, k1, lo, hi in out:
        if hi - lo < minsize:
            continue
        if only_lines and order[k0][2] not in only_lines:
            continue
        res.append((k0, k1, lo, hi))
    return res


class Porter:
    def __init__(self, src, dst):
        self.src, self.dst = src, dst
        self.rs, self.rd = rom(src), rom(dst)
        self.os, self.ss = amap(src)
        self.od, self.sd = amap(dst)
        self.marked_s = sorted((e[0], k) for k, e in enumerate(self.os) if e[0] is not None)
        self.mkeys_s = [x[0] for x in self.marked_s]
        # src symbol values incl. local labels read from the text
        self.sv = dict(self.ss)
        for e in self.os:
            if e[0] is not None:
                for lab in split_line(e[3])[0]:
                    self.sv.setdefault(lab, e[0])
        self.dnames = defined_names(dst)
        self.dlab_at = collections.defaultdict(set)
        for e in self.od:
            if e[0] is not None:
                for lab in split_line(e[3])[0]:
                    self.dlab_at[e[0]].add(lab)
        self.incdir = os.path.join(ROOT, dst, "maincpu")

    # -- anchor + alignment
    def anchor_delta(self, k0):
        """delta src-dst from the nearest label above line k0 (same file) that
        both trees define and whose bytes agree."""
        rel = self.od[k0][1]
        k = k0
        while k > 0:
            k -= 1
            e = self.od[k]
            if e[1] != rel:
                continue
            for lab in split_line(e[3])[0]:
                if lab in self.ss and lab in self.sd:
                    a7, a10 = self.sd[lab], self.ss[lab]
                    if self.rd[a7 - BASE:a7 - BASE + 8] == self.rs[a10 - BASE:a10 - BASE + 8]:
                        return a10 - a7
        return None

    def align(self, lo, hi, delta, ctx=0x60, win=0x300):
        d0, d1 = max(BASE, lo - ctx), min(BASE + len(self.rd), hi + ctx)
        s0 = max(BASE, lo + delta - win)
        s1 = min(BASE + len(self.rs), hi + delta + win)
        a = self.rs[s0 - BASE:s1 - BASE]
        b = self.rd[d0 - BASE:d1 - BASE]
        sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
        dm = {}
        pi = pj = 0
        blocks = [(i, j, n) for i, j, n in sm.get_matching_blocks() if n]
        for (i, j, n) in blocks + [(len(a), len(b), 0)]:
            di, dj = i - pi, j - pj
            if di and di == dj and (pi or pj):
                for q in range(di):
                    dm[s0 + pi + q] = (d0 + pj + q) - (s0 + pi + q)
            for q in range(n):
                dm[s0 + i + q] = (d0 + j + q) - (s0 + i + q)
            pi, pj = i + n, j + n
        return dm, s0, s1

    # -- candidates
    def candidates(self, lo, hi, dm, s0, s1):
        j = bisect.bisect_left(self.mkeys_s, s0)
        out = []
        while j < len(self.marked_s):
            a0, k = self.marked_s[j]
            j += 1
            if a0 >= s1:
                break
            k += 1
            e = self.os[k - 1]
            if e[4] <= 0:
                continue
            labs, body, com = split_line(e[3])
            if not body or body.startswith((".include", ".incbin", ".byte")):
                continue          # .byte -> .byte would gain nothing
            a, n = e[0], e[4]
            ds = {dm.get(a + q) for q in range(n)}
            if len(ds) != 1 or None in ds:
                continue
            a7 = a + ds.pop()
            if lo <= a7 and a7 + n <= hi:
                out.append((a7, n, k - 1))
        return out

    def rewrite(self, k, a7, n, labs_new):
        """-> (newtext, testtext) for src line k at dst address a7."""
        e = self.os[k]
        labs, body, com = split_line(e[3])
        p = body.split(None, 1)
        mn, ops = p[0], (p[1] if len(p) > 1 else "")
        bs = self.rs[e[0] - BASE:e[0] - BASE + n]
        bd = self.rd[a7 - BASE:a7 - BASE + n]
        rel = mn.lower() in REL
        quoted = [(m.start(), m.end()) for m in re.finditer(r'"(?:[^"\\]|\\.)*"', ops)]

        def inq(x):
            return any(q0 <= x < q1 for q0, q1 in quoted)
        toks = []
        for m in IDENT.finditer(ops):
            if inq(m.start()) or m.group(1).lower() in RESERVED:
                continue
            if m.group(1) in self.sv:
                toks.append((m.start(), m.end(), "sym", m.group(1), self.sv[m.group(1)]))
        for m in NUM.finditer(ops):
            if inq(m.start()) or (m.start() > 0 and ops[m.start() - 1] == ":"):
                continue
            toks.append((m.start(), m.end(), "num", m.group(1), int(m.group(1), 0)))
        toks.sort()

        def dval(nm):
            if nm in labs_new:
                return labs_new[nm]
            return self.sd.get(nm)

        def dlabel(v):
            names = sorted(x for x, a in labs_new.items() if a == v) + sorted(self.dlab_at.get(v, ()))
            names = [x for x in names if not x.startswith("__")]
            return names[0] if names else None
        new, test, pos = [], [], 0
        for (s, e2, kind, raw, vs) in toks:
            new.append(ops[pos:s])
            test.append(ops[pos:s])
            pos = e2
            if rel and (s, e2) == (toks[-1][0], toks[-1][1]):
                w = REL_W.get(mn.lower(), 1)
                disp = sval(le(bd, n - w, w), w)
                tgt = a7 + n + disp
                test.append(str(disp))
                if kind == "sym" and dval(raw) == tgt:
                    new.append(raw)
                else:
                    new.append(dlabel(tgt) or str(disp))
                continue
            req = vs
            if bs != bd:
                found = None
                for w in (4, 3, 2, 1):
                    if vs < 0 or vs >= 1 << (8 * w):
                        continue
                    offs = [o for o in range(n - w + 1) if le(bs, o, w) == vs and bs[o:o + w] != bd[o:o + w]]
                    if len(offs) == 1:
                        found = (offs[0], w)
                        break
                if found:
                    req = le(bd, found[0], found[1])
            test.append(hex(req) if req >= 0 else str(req))
            if kind == "sym" and dval(raw) == req:
                new.append(raw)
            elif kind == "sym" and req >= BASE and dlabel(req):
                new.append(dlabel(req))
            elif kind == "num":
                new.append(raw if req == vs else hex(req))
            else:
                new.append(hex(req))
        new.append(ops[pos:])
        test.append(ops[pos:])
        sep = "\t" if ops else ""
        return mn + (sep + "".join(new) if ops else ""), mn + (" " + "".join(test) if ops else ""), com

    # -- one island
    def port_island(self, k0, k1, lo, hi, demoted=frozenset()):
        delta = self.anchor_delta(k0)
        if delta is None:
            return None, "no anchor label"
        dm, s0, s1 = self.align(lo, hi, delta)
        cands = [c for c in self.candidates(lo, hi, dm, s0, s1) if c[2] not in demoted]
        cands.sort()
        # if the src counterpart itself holds data-as-code markers, it is
        # (partly) data decoded as code: port only its typed-data lines
        if cands:
            ks = [c[2] for c in cands]
            span = range(min(ks), max(ks) + 1)
            if any(ABS.search(split_line(self.os[q][3])[1]) for q in span if self.os[q][0] is not None):
                cands = [c for c in cands if split_line(self.os[c[2]][3])[1].startswith(".")]
                self.note = "src has markers: typed data only"
            else:
                self.note = ""
        else:
            self.note = ""
        # non-overlapping, not straddling a dst label
        dlabels_in = {a for a in self.dlab_at if lo < a < hi}
        items, last = [], lo
        for a7, n, k in cands:
            if a7 < last:
                continue
            if any(a7 < x < a7 + n for x in dlabels_in):
                continue
            items.append([a7, n, k])
            last = a7 + n
        # src labels to add (only names the dst tree lacks, at free addresses)
        labs_new = {}
        for a7, n, k in items:
            for lab in split_line(self.os[k][3])[0]:
                if lab not in self.dnames and not self.dlab_at.get(a7) and lab not in labs_new:
                    labs_new[lab] = a7
            # labels on label-only lines directly above
            q = k - 1
            while q >= 0 and self.os[q][4] == 0 and self.os[q][1] == self.os[k][1]:
                for lab in split_line(self.os[q][3])[0]:
                    if lab not in self.dnames and not self.dlab_at.get(a7) and lab not in labs_new:
                        labs_new[lab] = a7
                if split_line(self.os[q][3])[1]:
                    break
                q -= 1
        texts = []
        for it in items:
            nt, tt, com = self.rewrite(it[2], it[0], it[1], labs_new)
            above = []
            q = it[2] - 1
            while q >= 0 and self.os[q][1] == self.os[it[2]][1]:
                t = self.os[q][3].strip()
                lb, bd, cm = split_line(self.os[q][3])
                if bd:
                    break
                if t.startswith(";"):
                    above.append(t)
                q -= 1
            above.reverse()
            it += [nt, tt, com, above]
            texts.append(tt)
        enc = assemble_all(texts, self.incdir)
        ok = []
        for it, got in zip(items, enc):
            if got == self.rd[it[0] - BASE:it[0] - BASE + it[1]]:
                ok.append(it)
        # drop labels whose item did not survive
        alive = {it[0] for it in ok}
        labs_new = {k: v for k, v in labs_new.items() if v in alive}
        return (ok, labs_new, delta), None

    def emit(self, k0, k1, lo, hi, ok, labs_new):
        """new text lines for dst order lines [k0, k1)"""
        # dst comments and labels of the island, by address
        notes = collections.defaultdict(list)
        dlabs = collections.defaultdict(list)
        cur = lo
        for k in range(k0, k1):
            e = self.od[k]
            labs, body, com = split_line(e[3])
            addr = e[0] if e[0] is not None else cur
            if e[0] is not None:
                cur = e[0] + e[4]
            t = e[3].strip()
            if t.startswith(";"):
                notes[addr].append(t)
            elif com.strip():
                notes[addr].append(com.strip())
            for lab in labs:
                dlabs[addr].append(lab)
            if body.startswith(".incbin"):
                notes[addr].append("; (was %s)" % body)
        for lab, a in labs_new.items():
            dlabs[a].append(lab)
        out = []
        byitem = {it[0]: it for it in ok}
        a = lo
        starts = sorted(set(byitem) | set(notes) | set(dlabs) | {hi})
        while a < hi:
            out.extend(notes.get(a, []))
            for lab in dlabs.get(a, []):
                out.append("%s:" % lab)
            it = byitem.get(a)
            if it is not None:
                # dst notes of bytes INSIDE this item (their lines were
                # mid-instruction) are kept, just before it
                for x in range(a + 1, a + it[1]):
                    out.extend(notes.pop(x, []))
                tag = "; [%s] " % self.src
                for c in it[6]:
                    out.append(tag + c.lstrip(";").strip())
                com = it[5].strip()
                if com:
                    com = tag + com.lstrip(";").strip()
                out.append("\t" + it[3] + (("\t" + com) if com else ""))
                a += it[1]
                continue
            nxt = starts[bisect.bisect_right(starts, a)]
            end = min(nxt, hi)
            for q in range(a, end, 8):
                r = min(end, q + 8)
                out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in self.rd[q - BASE:r - BASE]))
            a = end
        for x in sorted(notes):
            if x >= hi:
                out.extend(notes[x])
        return out


def fast_build(dst, outdir):
    os.makedirs(outdir, exist_ok=True)
    o, elf, rbin = [os.path.join(outdir, "%s.%s" % (dst, x)) for x in ("o", "elf", "rom")]
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", "%s/maincpu" % dst, "-o", o,
                        "%s/maincpu/kn5000_%s_program.s" % (dst, dst)], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stderr[-3000:]
    subprocess.run([LLD, "-T", "%s/maincpu/maincpu.ld" % dst, "-o", elf, o], cwd=ROOT, capture_output=True)
    subprocess.run([OBJCOPY, "-O", "binary", elf, rbin], cwd=ROOT, check=True)
    return open(rbin, "rb").read(), ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="v10")
    ap.add_argument("--dst", required=True)
    ap.add_argument("--file", action="append", required=True)
    ap.add_argument("--line", action="append", type=int, default=[])
    ap.add_argument("--min", type=int, default=8)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()
    P = Porter(a.src, a.dst)
    plan = []
    for rel in a.file:
        for (k0, k1, lo, hi) in islands(P.od, rel, a.min, set(a.line) or None):
            res, why = P.port_island(k0, k1, lo, hi)
            if res is None:
                print("  %s:%d 0x%06X %5d B  SKIP (%s)" % (rel, P.od[k0][2], lo, hi - lo, why))
                continue
            ok, labs_new, delta = res
            cov = sum(it[1] for it in ok)
            print("  %s:%d 0x%06X %5d B  ported %5d B in %d lines (delta %+#x), +%d labels %s" % (
                rel, P.od[k0][2], lo, hi - lo, cov, len(ok), delta, len(labs_new), P.note))
            if cov:
                plan.append([rel, k0, k1, lo, hi, ok, labs_new])
    print("total ported: %d B" % sum(sum(it[1] for it in p[5]) for p in plan))
    if a.show:
        for rel, k0, k1, lo, hi, ok, labs_new in plan:
            print("---- %s 0x%06X" % (rel, lo))
            for ln in P.emit(k0, k1, lo, hi, ok, labs_new)[:80]:
                print("   " + ln)
    if not a.apply or not plan:
        return 0
    backups = {}
    demoted = collections.defaultdict(set)
    for rnd in range(6):
        # write all islands (bottom-up per file so line numbers stay valid)
        byfile = collections.defaultdict(list)
        for p in plan:
            byfile[p[0]].append(p)
        for rel, ps in byfile.items():
            path = os.path.join(ROOT, a.dst, "maincpu", rel)
            if path not in backups:
                backups[path] = open(path, "rb").read()
            lines = backups[path].decode("latin-1").split("\n")
            for rel_, k0, k1, lo, hi, ok, labs_new in sorted(ps, key=lambda p: -p[1]):
                l0 = P.od[k0][2] - 1
                l1 = P.od[k1 - 1][2]
                new = P.emit(k0, k1, lo, hi, ok, labs_new)
                lines[l0:l1] = new
            open(path, "wb").write("\n".join(lines).encode("latin-1"))
        built, err = fast_build(a.dst, os.path.join(SCRATCH, "build"))
        if built is None:
            print("BUILD FAILED:\n" + err)
            break
        if built == P.rd:
            print("%s IDENTICAL after round %d" % (a.dst, rnd))
            return 0
        bad = {x + BASE for x in range(min(len(built), len(P.rd))) if built[x] != P.rd[x]}
        print("  round %d: %d bytes differ (first 0x%06X); demoting" % (rnd, len(bad), min(bad)))
        hit = 0
        for p in plan:
            keep = []
            for it in p[5]:
                if any(it[0] <= x < it[0] + it[1] for x in bad):
                    hit += 1
                else:
                    keep.append(it)
            p[5] = keep
            alive = {it[0] for it in keep}
            p[6] = {k: v for k, v in p[6].items() if v in alive}
        if not hit:
            print("  no ported line covers the differing bytes")
            break
    for path, data in backups.items():
        open(path, "wb").write(data)
    print("RESTORED the original files")
    return 1


if __name__ == "__main__":
    sys.exit(main())
