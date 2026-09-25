#!/usr/bin/env python3
r"""RE-FRAME MIS-DECODED CODE IN LANE seui'S FILES, WITH A SECOND DECODER AS WITNESS.

QUESTION ANSWERED
-----------------
Which stretches of this lane's code are spelled wrongly -- a lone `.byte 0x8f`
followed by "instructions" made of the real instruction's operand bytes, or a
whole routine left as `.byte` (v7) -- and what are the right instructions?

HOW
  For a SEED address (a `.byte` line, or a data-as-code marker line such as
  `halt`/`swi`/`max` inside code), decode forward with the tree's own backend
  (`llvm-objdump`, via scripts/analysis/v10_reframe.py's disassemble) AND with
  MAME `unidasm`, and look for the first address T after the seed where
    * both decoders put an instruction boundary on every one of their
      instructions between seed and T (they agree on the framing), and
    * T is also a line boundary of the current source, and
    * no byte in [seed, T) was undecodable to the backend.
  The source lines covering [seed, T) are then replaced by the backend's
  instructions.  A label inside [seed, T) is kept if it falls on a new
  instruction boundary; if it falls INSIDE a new instruction the window is
  refused (the label is either a phantom of the old framing or the new framing
  is wrong -- this tool does not decide which).  Comments are carried over.

  `--span A B` instead re-decodes [A, B) whole (used for v7's `.byte` routines):
  the two decoders must agree on every boundary in the span.

  Operands: relative branches are written as the backend prints them (the
  displacement); absolute call/jp targets and 24-bit data addresses are written
  as the symbol the linked ELF has at exactly that address, else in hex.  Run
  scripts/converters/symbolize_numeric_branches.py afterwards for the branches.

  Verification is the rebuilt image (`make gate`), not this tool.

RUN
    python3 scripts/lanes/seui/seui_amap.py --image v10 --out A.json --files audio/semenu_routines.s
    python3 scripts/lanes/seui/se_reframe_code.py --image v10 --file audio/semenu_routines.s --amap A.json [--apply]
    python3 scripts/lanes/seui/se_reframe_code.py --image v7 --file audio/sndparam_routines.s --amap A.json \
        --span 0xFCCFE4 0xFCF000 [--apply]
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, HERE)
import v10_reframe as vr                  # noqa: E402  (disassemble() only)
import se_screendata_model as sm          # noqa: E402  (symbols())

BASE = 0xE00000
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')


def unidasm_bounds(rom, a, n):
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(rom[a - BASE:a - BASE + n])
        f.flush()
        out = subprocess.run([UNIDASM, f.name, "-arch", "tlcs900", "-basepc", "%x" % a],
                             capture_output=True, text=True, check=True).stdout
    res = []
    for ln in out.splitlines():
        m = re.match(r"^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$", ln)
        if m:
            res.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return res


def llvm_decode(rom, a, n):
    out, p = [], a
    for k, t in vr.disassemble(rom[a - BASE:a - BASE + n]):
        out.append((p, k, t))
        p += k
    return out


class Reframer:
    def __init__(self, v, rel, amap):
        self.v, self.rel = v, rel
        self.rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
        self.path = os.path.join(ROOT, v, "maincpu", rel)
        self.L = open(self.path, "rb").read().decode("latin-1").split("\n")
        spans = [s for s in json.load(open(amap)) if s[2] == rel]
        self.emit = {s[3]: (s[0], s[1]) for s in spans}
        self.at = {}
        for li, (a, e) in self.emit.items():
            self.at.setdefault(a, []).append(li)
        self.starts = sorted(self.at)
        self.ends = {}
        for li, (a, e) in self.emit.items():
            self.ends.setdefault(e, []).append(li)
        s = sm.symbols(v)
        self.byname = s
        self.byaddr = {}
        for n, a in s.items():
            if n.startswith("__") or n.startswith(".L"):
                continue
            self.byaddr.setdefault(a, []).append(n)
        self.edits = []          # (first_line, last_line_incl, new_lines, note)
        self.moved = []          # (label, old addr, new addr)
        self._refs = None

    # ---------------------------------------------------------------- naming
    def sym(self, a):
        c = self.byaddr.get(a, [])
        good = [n for n in c if not re.search(r"_0x[0-9A-F]+$", n)]
        return sorted(good or c)[0] if (good or c) else None

    def fix_operands(self, t):
        """absolute targets / data addresses -> symbol or hex"""
        m = re.match(r"^\t(call|jp|calr|jrl?)\s+(?:(\w+),\s*)?(\d+)$", t)
        if m and m.group(1) in ("call", "jp"):
            a = int(m.group(3))
            nm = self.sym(a)
            cc = (m.group(2) + ", ") if m.group(2) else ""
            return "\t%s\t%s%s" % (m.group(1), cc, nm or "0x%06x" % a)

        def big(mm):
            v = int(mm.group(0))
            if v >= 0xE00000 and v < 0x1000000:
                return self.sym(v) or "0x%06x" % v
            if v >= 0x10000:
                return "0x%x" % v
            return mm.group(0)
        head, _, rest = t.strip().partition(" ")
        rest = re.sub(r"(?<![\w.])\d{5,}(?![\w])", big, rest.strip())
        # a direct memory address reads better in hex: (63952) -> (0xf9d0)
        rest = re.sub(r"\((\d{3,})\)", lambda mm: "(0x%x)" % int(mm.group(1)), rest)
        return "\t" + head + ("\t" + rest if rest else "")

    # ---------------------------------------------------------------- lines
    def lines_between(self, a, b):
        """source line indices whose bytes are in [a, b), plus the
        non-emitting lines between the first and the last"""
        lis = sorted(li for li, (x, e) in self.emit.items() if a <= x < b)
        if not lis:
            return None
        first, last = lis[0], lis[-1]
        if self.emit[last][1] != b or self.emit[first][0] != a:
            return None
        # nothing in between may emit outside [a, b)
        for li in range(first, last + 1):
            if li in self.emit and not (a <= self.emit[li][0] < b):
                return None
        return first, last

    def render(self, a, b, dec, relabel=None):
        """new text for [a, b) from decode `dec`.  Lines whose framing the new
        decode CONFIRMS (same address, same length) at the two ends of the
        window are kept verbatim -- their symbols and spelling stay; only the
        mis-framed middle is replaced.  Labels in the middle are kept if they
        fall on a new instruction boundary; comments are carried over."""
        first, last = self.lines_between(a, b)
        em = [li for li in range(first, last + 1) if li in self.emit]
        old = [(self.emit[li][0], self.emit[li][1] - self.emit[li][0]) for li in em]
        nw = [(p, k) for (p, k, t) in dec]
        i = 0
        while i < min(len(old), len(nw)) and old[i] == nw[i]:
            i += 1
        j = 0
        while j < min(len(old), len(nw)) - i and old[-1 - j] == nw[-1 - j]:
            j += 1
        if i == len(old) and i == len(nw):
            return None, "framing unchanged"
        ma = nw[i][0]
        mb = nw[len(nw) - j][0] if j else b
        mid = dec[i:len(dec) - j]
        # replaced line range: from the first old emitting line at ma (plus the
        # non-emitting lines just before it that belong to it are LEFT in place)
        f = em[i]
        l = em[len(em) - 1 - j]
        bounds = {p for (p, k, t) in mid}
        extra = []
        for li in range(f, l + 1):
            if li in self.emit:
                t = self.L[li]
                c = t.find(";")
                if c >= 0 and '"' not in t[:c]:
                    extra.append((self.emit[li][0], li, "\t" + t[c:].strip()))
                m = LABEL_RE.match(t.strip())
                if m:
                    return None, "label on an instruction line"
                continue
            t = self.L[li]
            st = t.strip()
            m = LABEL_RE.match(st)
            addr = self.addr_of_line(li)
            if m:
                if addr not in bounds:
                    # v7's labels were copied onto `.byte` rows and some fall
                    # INSIDE an instruction of the true framing.  Other code
                    # uses several of them as bases (`.long Label + 164`), so
                    # the address must not move: it is kept as
                    # `.set Label, . + k` in front of the instruction that
                    # contains it (policy: mid-instruction address = .set).
                    if relabel is None:
                        return None, "label %s at %06x falls inside a new instruction" % (m.group(1), addr)
                    fix = relabel(m.group(1), a, b)
                    if fix is not None and fix in bounds and not self.referenced(m.group(1)):
                        # nothing uses it as a base: put it where the witness
                        # image's label of the same name is (by offset)
                        self.moved.append((m.group(1), addr, fix))
                        extra.append((fix, li, m.group(1) + ":"))
                        continue
                    base = max(x for x in bounds if x <= addr)
                    self.moved.append((m.group(1), addr, None))
                    extra.append((base, li, "\t.set\t%s, . + %d" % (m.group(1), addr - base)))
                    continue
                extra.append((addr, li, m.group(1) + ":"))
                rest = st[m.end():].strip()
                if rest.startswith(";"):
                    extra.append((addr, li, "\t" + rest))
            elif st.startswith(";"):
                extra.append((addr, li, t))
        out = []
        for (p, k, t) in mid:
            for (x, li, txt) in sorted(extra, key=lambda z: z[1]):
                if x == p:
                    out.append(txt)
            out.append(self.fix_operands(t))
        for (x, li, txt) in sorted(extra, key=lambda z: z[1]):
            if x not in bounds:
                out.append(txt)
        return (f, l, out), None

    def addr_of_line(self, li):
        k = li
        while k not in self.emit and k < len(self.L):
            k += 1
        return self.emit[k][0] if k in self.emit else None

    # ---------------------------------------------------------------- windows
    def window(self, seed, maxlen=48, past=None):
        """smallest [seed, T) both decoders frame alike, ending on a line start
        after `past` (default: seed)"""
        past = seed if past is None else past
        dl = llvm_decode(self.rom, seed, maxlen + 16)
        du = unidasm_bounds(self.rom, seed, maxlen + 16)
        ub = {p: k for (p, k, t) in du}
        acc = []
        for (p, k, t) in dl:
            if t.startswith("\t.byte"):
                return None, "backend cannot decode %06x" % p
            if ub.get(p) != k:
                return None, "decoders disagree at %06x" % p
            acc.append((p, k, t))
            T = p + k
            if T - seed > maxlen:
                return None, "no resync within %d bytes" % maxlen
            if T > past and T in self.at and self.lines_between(seed, T):
                return (T, acc), None
        return None, "no resync"

    def is_insn(self, li):
        s = self.L[li].split(";")[0].strip()
        s = re.sub(r"^[\w.$]+:\s*", "", s)
        return bool(s) and not s.startswith(".") and not ABS.match(s.lower())

    def excluded(self, a):
        """the typed screen-data block is data, never a seed"""
        lo, hi = self.byname.get("SeScreenData"), self.byname.get("SeScreenData_End")
        return lo is not None and hi is not None and lo <= a < hi

    def seeds(self):
        """addresses of suspect lines: `.byte` lines and marker lines"""
        out = []
        for li, (a, e) in sorted(self.emit.items(), key=lambda x: x[1][0]):
            s = self.L[li].split(";")[0].strip()
            s = re.sub(r"^[\w.$]+:\s*", "", s).lower()
            short_text = s.startswith((".ascii", ".asciz")) and e - a <= 8
            if (s.startswith(".byte") or ABS.match(s) or short_text) and not self.excluded(a):
                out.append(a)
        return out

    def code_flanked(self, st, T):
        """the window must sit INSIDE code: the emitting line before it and the
        line at its end are both real instructions (a `.byte` row of a data
        table is flanked by data and is never touched)"""
        before = self.ends.get(st, [])
        after = self.at.get(T, [])
        left = (bool(before) and all(self.is_insn(li) for li in before)) or st in self.call_targets()
        return left and bool(after) and all(self.is_insn(li) for li in after)

    def call_targets(self):
        """addresses some `call`/`calr` in this image names symbolically: a
        routine entry, even when the line before it is a table"""
        if getattr(self, "_ct", None) is None:
            self._ct = set()
            root = os.path.join(ROOT, self.v, "maincpu")
            pat = re.compile(r"^\s*(?:[\w.$]+:\s*)?(?:call|calr)\s+(?:\w+,\s*)?([A-Za-z_][\w.$]*)\s*(?:;|$)")
            for dp, _, fns in os.walk(root):
                for fn in fns:
                    if fn.endswith(".s"):
                        for ln in open(os.path.join(dp, fn), encoding="latin-1"):
                            m = pat.match(ln)
                            if m and m.group(1) in self.byname:
                                self._ct.add(self.byname[m.group(1)])
        return self._ct

    def auto(self):
        done_until = 0
        report = {"ok": 0, "refused": {}}
        for sd in self.seeds():
            if sd < done_until:
                continue
            # start the window at the earliest line start <= seed whose decode
            # agrees -- a `.byte 0x8f` is often the FIRST byte of the real insn
            # the misframe may have begun a few lines BEFORE the suspect line
            # (a previous "instruction" swallowed the real one's first bytes):
            # try the seed itself and up to 4 earlier line starts, earliest
            # first, never reaching back before a window already applied
            i = self.starts.index(sd)
            cands = [x for x in self.starts[max(0, i - 4):i + 1] if x >= done_until]
            got, why = None, "no candidate"
            for st in cands:
                win, why = self.window(st, past=sd)
                if not win:
                    continue
                T, dec = win
                if not self.code_flanked(st, T):
                    why = "not flanked by code"
                    continue
                r, why = self.render(st, T, dec)
                if not r:
                    continue
                first, last, new = r
                got = (first, last, new, "%06x-%06x" % (st, T), T)
                break
            if not got:
                key = re.sub(r" [0-9a-f]{6}.*| at .*| %.*", "", why)
                report["refused"][key] = report["refused"].get(key, 0) + 1
                continue
            self.edits.append(got[:4])
            report["ok"] += 1
            done_until = got[4]
        return report

    def span(self, a, b, w=None, need=0.9):
        """re-decode [a, b) whole, in lock-step (unidasm framing, backend
        spelling); with a witness image the >= need agreement rule applies"""
        dl = self.lockstep(a, b)
        if dl[-1][0] + dl[-1][1] != b:
            return "decode does not end at %06x (%06x)" % (b, dl[-1][0] + dl[-1][1])
        if not self.lines_between(a, b):
            return "span does not start/end on source lines"
        if w is not None:
            ag, cp = self.witness(w, a, dl)
            print("  witness: %d / %d comparable instructions start a witness instruction line" % (ag, cp))
            if cp == 0 or ag < need * cp:
                return "witness disagrees"
        # Moving a label by content (the witness's same-named label's first
        # bytes) was tried and REJECTED: two different labels can share their
        # first 10 bytes (common epilogues) and land on one address.  Every
        # label that falls inside an instruction is therefore kept at its
        # exact old address as `.set Label, . + k`.
        def relabel(name, lo, hi):
            return None
        r, why = self.render(a, b, dl, relabel=relabel)
        if not r:
            return why
        self.edits.append(r + ("span %06x-%06x" % (a, b),))
        return None

    def referenced(self, name):
        """is `name` used anywhere in this image's sources besides its own
        definition?  (a label that code or data refers to must not move)"""
        if self._refs is None:
            self._refs = {}
            tok = re.compile(r"[A-Za-z_.$][\w.$]*")
            root = os.path.join(ROOT, self.v, "maincpu")
            for dp, _, fns in os.walk(root):
                for fn in fns:
                    if fn.endswith((".s", ".c", ".h", ".ld", ".inc")):
                        for ln in open(os.path.join(dp, fn), encoding="latin-1"):
                            code = ln.split(";")[0]
                            code = LABEL_RE.sub("", code.strip())
                            for t in tok.findall(code):
                                self._refs[t] = self._refs.get(t, 0) + 1
        return self._refs.get(name, 0) > 0

    # ---------------------------------------------------------------- v7 runs
    def lockstep(self, a, limit):
        """decode from a following MAME unidasm's framing; each instruction
        must be spelled by the backend at the same address with the same
        length (re-syncing the backend's sweep after a byte it cannot
        decode, which is then kept as `.byte` of unidasm's length).
        -> list of (addr, len, text) up to the first boundary >= limit"""
        du = unidasm_bounds(self.rom, a, limit - a + 64)
        dl = {p: (k, t) for (p, k, t) in llvm_decode(self.rom, a, limit - a + 64)}
        out = []
        for (p, k, ut) in du:
            if p >= limit and out:
                break
            got = dl.get(p)
            if got is None or got[1].startswith("\t.byte"):
                dl.update({q: (kk, tt) for (q, kk, tt) in llvm_decode(self.rom, p, limit - p + 64)})
                got = dl.get(p)
            if got and got[0] == k and not got[1].startswith("\t.byte"):
                out.append((p, k, got[1]))
            else:
                out.append((p, k, "\t.byte\t" + ", ".join(
                    "0x%02x" % x for x in self.rom[p - BASE:p - BASE + k])))
        return out

    def delta_for(self, w, a, b):
        """the witness address offset for [a, b): among the offsets of labels
        both images define (same name), the one under which the most bytes of
        the run are equal"""
        rom10, starts10, shared = w
        cands = {d for (x, d) in sorted(shared, key=lambda x: abs(x[0] - a))[:12]}
        # plus: where do 8-byte pieces of the run occur verbatim in the witness?
        for i in range(a, max(a + 1, b - 8), max(1, (b - a) // 12)):
            piece = self.rom[i - BASE:i - BASE + 8]
            j = rom10.find(piece)
            if j >= 0 and rom10.find(piece, j + 1) < 0:
                cands.add(BASE + j - i)
        best = (-1, 0)
        for d in cands:
            eq = sum(1 for i in range(a, b) if 0 <= i + d - BASE < len(rom10)
                     and rom10[i + d - BASE] == self.rom[i - BASE])
            if eq > best[0]:
                best = (eq, d)
        return best[1]

    def witness(self, w, a, dec):
        """fraction of instructions whose counterpart in the witness image
        (same bytes at a + delta) starts a source line there"""
        rom10, starts10, shared = w
        delta = self.delta_for(w, a, dec[-1][0] + dec[-1][1])
        agree = comp = 0
        for (p, k, t) in dec:
            q = p + delta
            if rom10[q - BASE:q - BASE + k] == self.rom[p - BASE:p - BASE + k]:
                comp += 1
                agree += q in starts10
        return agree, comp

    def runs(self):
        """maximal runs of `.byte` lines / romslice `.incbin` lines"""
        out, cur = [], None
        for li, (a, e) in sorted(self.emit.items(), key=lambda x: x[1][0]):
            c = re.sub(r"^[\w.$]+:\s*", "", self.L[li].split(";")[0].strip())
            isd = c.startswith(".byte") or (".incbin" in c and "romslices" in c)
            if isd and not self.excluded(a):
                if cur and cur[1] == a:
                    cur[1] = e
                else:
                    cur = [a, e]
                    out.append(cur)
            else:
                cur = None
        return [tuple(r) for r in out]

    def convert_runs(self, w, minlen=4, need=0.9):
        report = {"ok": 0, "bytes": 0, "refused": {}}
        done_until = 0
        for (a, b) in self.runs():
            if b - a < minlen or a < done_until:
                continue
            # the run must END where both framings meet: extend to the first
            # new boundary >= b that is also a source line start
            dec = self.lockstep(a, b)
            T = dec[-1][0] + dec[-1][1]
            ext = 0
            while not (T in self.at and self.lines_between(a, T)) and ext < 8:
                more = self.lockstep(T, T + 1)
                dec += more[:1]
                T = dec[-1][0] + dec[-1][1]
                ext += 1
            why = None
            if not (T in self.at and self.lines_between(a, T)):
                why = "no line boundary to end on"
            else:
                ag, cp = self.witness(w, a, dec)
                d = self.delta_for(w, a, T)
                wd = getattr(self, "wdata", ())
                hits = [p for (p, k, t) in dec
                        if any(q in wd for q in range(p + d, p + d + k))
                        and w[0][p + d - BASE:p + d - BASE + k] == self.rom[p - BASE:p - BASE + k]]
                if cp == 0 or ag < need * cp:
                    why = "witness disagrees (%d/%d)" % (ag, cp)
                elif hits:
                    why = "witness has DATA at %06x" % hits[0]
            if not why:
                rom10 = w[0]

                def relabel(name, lo, hi, rom10=rom10):
                    q = self.w10syms.get(name)
                    if q is None:
                        return None
                    piece = rom10[q - BASE:q - BASE + 10]
                    j = self.rom.find(piece, lo - BASE, hi - BASE)
                    if j < 0 or self.rom.find(piece, j + 1, hi - BASE) >= 0:
                        return None
                    return BASE + j
                r, why = self.render(a, T, dec, relabel)
                if r:
                    self.edits.append(r + ("run %06x-%06x" % (a, T),))
                    report["ok"] += 1
                    report["bytes"] += T - a
                    done_until = T
                    continue
            key = re.sub(r" [0-9a-f]{6}.*| \(.*|%.*", "", why)
            report["refused"][key] = report["refused"].get(key, 0) + 1
        return report

    def write(self):
        L = self.L
        for (first, last, new, note) in sorted(self.edits, key=lambda e: -e[0]):
            L = L[:first] + new + L[last + 1:]
        open(self.path, "wb").write("\n".join(L).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--amap", required=True)
    ap.add_argument("--span", nargs=2)
    ap.add_argument("--runs", action="store_true",
                    help="convert .byte/romslice runs (v7), with a witness image")
    ap.add_argument("--witness", nargs=2, metavar=("IMAGE", "AMAP"),
                    help="e.g. v10 amap_v10.json: the witness image and its address map")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", action="store_true")
    ap.add_argument("--notes", action="store_true", help="list the windows/runs only")
    a = ap.parse_args()
    r = Reframer(a.image, a.file, a.amap)
    def load_witness(wimg, wamap):
        """(rom, instruction-or-.byte line starts, shared-label offsets); also
        sets r.wdata = bytes of the witness's DATA lines.  The map may cover
        every file of the witness image (a routine can live in another file
        there)."""
        rom10 = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % wimg), "rb").read()
        sp = json.load(open(wamap))
        cache = {}

        def text(rel, li):
            if rel not in cache:
                cache[rel] = open(os.path.join(ROOT, wimg, "maincpu", rel),
                                  encoding="latin-1").read().split("\n")
            return re.sub(r"^[\w.$]+:\s*", "", cache[rel][li].split(";")[0].strip())
        starts, r.wdata = set(), set()
        for (x0, x1, rel, li) in sp:
            c = text(rel, li)
            if c.startswith((".long", ".short", ".hword", ".word", ".ascii", ".asciz",
                             ".fill", ".zero", ".space", "sd_", "sdb_")):
                r.wdata.update(range(x0, x1))
            elif c and (not c.startswith(".") or c.startswith(".byte")) and not ABS.match(c.lower()):
                # an instruction, or a `.byte` island the backend cannot spell:
                # either way the witness has an instruction boundary here
                starts.add(x0)
        s10 = sm.symbols(wimg)
        r.w10syms = s10
        shared = [(av, s10[n] - av) for n, av in r.byname.items()
                  if n in s10 and not n.startswith(("__", ".")) and 0xF00000 <= av < 0x1000000]
        return (rom10, starts, shared)

    if a.runs:
        w = load_witness(*a.witness)
        rep = r.convert_runs(w)
        for (n, x, y) in r.moved:
            print("  label %s %06x kept as .set (inside an instruction)" % (n, x))
        print("%s %s: %d runs (%d B) converted; refused %s"
              % (a.image, a.file, rep["ok"], rep["bytes"], rep["refused"]))
    elif a.span:
        w = load_witness(*a.witness) if a.witness else None
        why = r.span(int(a.span[0], 16), int(a.span[1], 16), w)
        print("span:", why or "ok")
        for (n, x, y) in r.moved:
            print("  label %s %06x %s" % (n, x, ("moved to %06x (same bytes as the witness's %s)" % (y, n))
                                          if y else "kept as .set (inside an instruction)"))
    else:
        rep = r.auto()
        print("%s %s: %d windows re-framed; refused %s" % (a.image, a.file, rep["ok"], rep["refused"]))
    if a.notes:
        for (first, last, new, note) in r.edits:
            print("  %s  lines %d-%d -> %d lines" % (note, first + 1, last + 1, len(new)))
    if a.show:
        for (first, last, new, note) in r.edits[:40]:
            print("---", note, "lines %d-%d" % (first + 1, last + 1))
            for li in range(first, last + 1):
                print("  -", r.L[li])
            for x in new:
                print("  +", x)
    if a.apply and r.edits:
        r.write()
        print("written", r.path)


if __name__ == "__main__":
    main()
