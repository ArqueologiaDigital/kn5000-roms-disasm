#!/usr/bin/env python3
r"""Which bytes of a source file does CONTROL FLOW actually reach, and where does
the source's instruction framing disagree with it?

QUESTION ANSWERED
-----------------
The midi sources were produced by a linear sweep with an older backend.  Where
that backend could not encode a form it printed `.byte <first opcode byte>` and
resumed decoding one byte later, so the next "instructions" are operand bytes
re-read at the wrong offset (a MISFRAME), and data after a `ret` was swept up
as instructions (DATA-AS-CODE).  Both re-assemble byte-exactly; the gate is
blind to them.  This tool re-derives instruction boundaries the way a CPU
would: by recursive descent from entries whose code-ness is established
independently of the file being judged.

ENTRIES (seeds)
    * every symbol that a `call`/`calr`/`jp`/`jr`/`jrl`/`djnz` names in a file
      OTHER than the ones judged, when it lies inside the judged files' range;
    * every `.long SYMBOL` entry of a run of >= 2 `.long` lines (a pointer
      table) in any file, when SYMBOL's own source line is an instruction;
    * then, to a fixpoint, the targets of call/jp in lines of the judged files
      that the descent itself has reached (never from unreached lines, so a
      branch decoded out of data cannot seed anything).
    `--seed 0xADDR` adds an entry by hand (state the evidence when you use it).

DESCENT (llvm-objdump of the ROM, the shared toolchain -- commit printed)
    follow both arms of conditional jr/jrl/jp/djnz, the target of calls
    (in range), stop after ret/reti/retd/`ret t`, unconditional jr/jrl/jp and
    register-indirect jp.  STOP AND FLAG at swi, halt and undecodable bytes: in
    this firmware those are data signatures, and the flag names the address.

VERDICT PER SOURCE LINE (of the judged files)
    OK          an instruction line that is exactly one reached instruction
    MISFRAME    an instruction line overlapping reached code at a different
                boundary
    CODE-AS-DATA  a data line (.byte ...) whose bytes are reached code
    UNREACHED   an instruction line no path reaches (dead code or data)

RUN (repo root, after `make all`)
    python3 scripts/analysis/midi_lane_reach.py --image v10 --file midi/midi_dispatch_handlers.s
    python3 scripts/analysis/midi_lane_reach.py --image v10 --file midi/x.s --json OUT.json
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "tools"))
import midi_lane_rewrite as rw  # noqa: E402

LL = rw.LLVM
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BR_SYM = re.compile(r"^\s*(?:[\w.$]+:\s*)?(call|calr|jp|jr|jrl|djnz)\s+(?:[a-z]+\s*,\s*)?([A-Za-z_][\w.$]*)\s*(;.*)?$")
IMM_SYM = re.compile(r"^\s*(?:[\w.$]+:\s*)?(ld|lda)\s+(x[a-z]{2}|x[a-z]{1,2}),\s*([A-Za-z_][\w.$]*)\s*(;.*)?$")
LONG_SYM = re.compile(r"^\s*(?:[\w.$]+:\s*)?\.long\s+([A-Za-z_][\w.$]*)\s*(;.*)?$")


def all_symbols(key):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % key)
    out = subprocess.run([os.path.join(LL, "llvm-nm"), "--defined-only", elf],
                         capture_output=True, text=True, check=True).stdout
    s = {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3:
            s[p[2]] = int(p[0], 16)
    return s


class Decoder:
    """Linear objdump decode of a window, cached by start address."""

    def __init__(self, rom):
        self.rom = rom
        self.cache = {}

    def unidasm(self, addr):
        """(length, text) of the instruction at addr per MAME unidasm."""
        with tempfile.TemporaryDirectory() as td:
            f = os.path.join(td, "u.bin")
            open(f, "wb").write(self.rom[addr - rw.BASE:addr - rw.BASE + 16])
            out = subprocess.run([UNIDASM, f, "-arch", "tlcs900", "-basepc", "0x%x" % addr],
                                 capture_output=True, text=True).stdout.split("\n")
        m = re.match(r"^\s*[0-9a-f]+:\s((?:[0-9a-f]{2} )+)\s*(.*)$", out[0]) if out else None
        if not m:
            return None
        return len(m.group(1).split()), "UNIDASM " + m.group(2).strip()

    def run(self, addr, n=192):
        if addr in self.cache:
            return self.cache[addr]
        data = self.rom[addr - rw.BASE:addr - rw.BASE + n]
        segs = rw.objdump(data)
        out, off = [], 0
        for raw, text in segs:
            if addr + off + 10 > addr + n:
                break           # the window may truncate this instruction
            if text is None:
                # a backend decoder gap, not necessarily data: ask unidasm for
                # the length, mark it, and stop this window there
                u = self.unidasm(addr + off)
                if u and not u[1].split()[1:2] == ["swi"]:
                    out.append((addr + off, u[0], u[1]))
                else:
                    out.append((addr + off, 1, None))
                break
            out.append((addr + off, len(raw), text))
            off += len(raw)
        for i, x in enumerate(out):
            self.cache.setdefault(x[0], out[i:])
        return out


def flow(ad, n, text):
    """-> (targets, falls_through, flag)"""
    if text is None:
        return [], False, "undecodable"
    if text.startswith("UNIDASM "):
        u = text[8:].lower()
        mn = u.split()[0]
        if mn in ("ret", "reti", "retd", "jp", "jr", "jrl", "call", "calr", "djnz", "swi", "halt"):
            return [], False, "gap-control:" + u
        return [], True, "gap:" + u
    mn = text.split()[0]
    ops = text[len(mn):].strip()
    if mn in ("swi", "halt"):
        return [], False, mn
    if mn in ("reti", "retd") or (mn == "ret" and ops in ("", "t")):
        return [], False, None
    if mn == "ret":
        return [], True, None
    if mn in ("jr", "jrl", "calr", "djnz", "djnz8"):
        m = re.search(r"(-?\d+)$", ops)
        tgt = ad + n + int(m.group(1)) if m else None
        parts = [p.strip() for p in ops.split(",")]
        if mn == "calr":
            return [tgt], True, None
        if mn.startswith("djnz"):
            return [tgt], True, None
        if len(parts) == 1 or parts[0] == "t":
            return [tgt], False, None
        if parts[0] == "f":
            return [], True, None
        return [tgt], True, None
    if mn in ("call", "call16", "call_24"):
        m = re.search(r"\(?(\d+)\)?$", ops)
        tgt = int(m.group(1)) if m and not re.search(r"\(x|\(\w\w\)", ops) else None
        return ([tgt] if tgt else []), True, None
    if mn in ("jp", "jp16", "jp_24", "jp_rr"):
        parts = [p.strip() for p in ops.split(",")]
        cond = len(parts) > 1 and parts[0] not in ("t",) and mn != "jp_rr"
        m = re.fullmatch(r"\(?(\d+)\)?", parts[-1])
        tgt = int(m.group(1)) if m else None
        if mn == "jp16" and tgt is not None:
            tgt = None      # 16-bit absolute: bank 0 (RAM), never this ROM
        return ([tgt] if tgt else []), cond, None
    return [], True, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--file", action="append", required=True)
    ap.add_argument("--seed", action="append", default=[])
    ap.add_argument("--json")
    ap.add_argument("--show", type=int, default=40)
    ap.add_argument("--emit-spec", help="write a midi_lane_rewrite.py kind=code spec that "
                    "re-frames every MISFRAME / CODE-AS-DATA run, widened to the nearest "
                    "OK line boundaries on both sides")
    a = ap.parse_args()
    img = rw.image(a.image)
    la, rom = rw.line_addresses(a.image, a.file)
    syms = all_symbols(a.image)
    srcdir = os.path.join(ROOT, img["mirror"])
    files = {rel: open(os.path.join(srcdir, rel), encoding="latin-1").read().split("\n") for rel in a.file}
    # the judged files' own address intervals (not the span between them: that
    # would walk every other file linked in between)
    ivs = []
    for rel in a.file:
        xs = [x for x in la[rel] if x is not None]
        if xs:
            ivs.append((min(xs), max(xs) + 8))
    inr = lambda x: x is not None and any(s0 <= x < e0 for s0, e0 in ivs)  # noqa: E731
    # which label names are defined on instruction lines of the judged files
    code_label_addr = {}
    for rel, L in files.items():
        for i, t in enumerate(L):
            m = rw.LABEL_RE.match(t)
            if m and m.group(1) in syms:
                j = i
                while j < len(L) and rw.drc.classify_line(L[j], {})[0] == "none":
                    j += 1
                if j < len(L) and rw.drc.classify_line(L[j], {})[0] == "code":
                    code_label_addr[m.group(1)] = syms[m.group(1)]
    seeds = set()
    why = {}
    # label name -> address, for labels of the judged files whose NEXT emitting
    # line is anything (code or data): the pointer-table rule below decides
    any_label = {}
    for rel, L in files.items():
        for t in L:
            m = rw.LABEL_RE.match(t)
            if m and m.group(1) in syms:
                any_label[m.group(1)] = syms[m.group(1)]
    for path in glob.glob(os.path.join(srcdir, "**", "*.s"), recursive=True):
        rel = os.path.relpath(path, srcdir)
        L = open(path, encoding="latin-1").read().split("\n")
        # pointer tables: maximal runs of `.long SYMBOL` lines (comments and
        # blank lines do not break a run).  A run of >= 3 of which at least
        # HALF of the targets inside the judged files are labels already framed
        # as code (targets elsewhere are not judged either way) is a code-pointer
        # table, and then every in-range target in it is an entry -- including
        # routines whose first bytes the source mis-spells as `.byte`.
        runs, cur = [], []
        for i, t in enumerate(L):
            m = LONG_SYM.match(t)
            if m:
                cur.append((i, m.group(1)))
            elif t.strip() and not t.strip().startswith(";"):
                if cur:
                    runs.append(cur)
                cur = []
        if cur:
            runs.append(cur)
        for r in runs:
            names = [n for _, n in r if n in any_label and inr(any_label[n])]
            codeish = sum(1 for n in names if n in code_label_addr)
            if len(r) >= 3 and names and codeish >= 0.5 * len(names):
                for i, n in r:
                    if n in any_label and inr(any_label[n]):
                        seeds.add(any_label[n])
                        why.setdefault(any_label[n], "ptr-table %s:%d" % (rel, i + 1))
        # a lone `.long SYMBOL` (a record field) or an immediate `ld xrr, SYMBOL`
        # (a procedure registered by address) names an entry only when SYMBOL
        # is already framed as code in the judged files
        for i, t in enumerate(L):
            m = LONG_SYM.match(t) or IMM_SYM.match(t)
            if m:
                n = m.group(m.lastindex - 1) if m.re is IMM_SYM else m.group(1)
                if n in code_label_addr and inr(code_label_addr[n]) and \
                        (rel not in files or m.re is LONG_SYM):
                    seeds.add(code_label_addr[n])
                    why.setdefault(code_label_addr[n], "ref %s:%d" % (rel, i + 1))
        if rel in files:
            continue
        for i, t in enumerate(L):
            m = BR_SYM.match(t)
            if m and m.group(2) in syms and inr(syms[m.group(2)]):
                seeds.add(syms[m.group(2)])
                why.setdefault(syms[m.group(2)], "%s %s:%d" % (m.group(1), rel, i + 1))
    # a 32-bit little-endian pointer to a code-framed label, ANYWHERE in the
    # ROM (the class/procedure tables live in C-compiled .incbin blobs whose
    # symbols no .s file names)
    for n, ad in code_label_addr.items():
        if inr(ad) and ad not in seeds and rom.find(ad.to_bytes(4, "little")) >= 0:
            seeds.add(ad)
            why.setdefault(ad, "rom-pointer")
    # a `call imm24` (0x1D) / `jp imm24` (0x1B) byte pattern anywhere in the ROM
    # whose operand is exactly a label of the judged files (code other lanes'
    # files hold as numeric operands or as C-compiled blobs)
    for n, ad in any_label.items():
        if inr(ad) and ad not in seeds:
            a24 = ad.to_bytes(3, "little")
            if rom.find(b"\x1d" + a24) >= 0 or rom.find(b"\x1b" + a24) >= 0:
                seeds.add(ad)
                why.setdefault(ad, "rom-call-pattern")
    for s in a.seed:
        seeds.add(int(s, 16))
        why[int(s, 16)] = "manual"
    dec = Decoder(rom)
    insn = {}           # start -> (len, text)
    flags = {}
    work = sorted(seeds)
    seen = set()
    while work:
        x = work.pop()
        if x in seen or not inr(x):
            continue
        seen.add(x)
        pc = x
        while inr(pc):
            if pc in insn and pc != x:
                break
            run = dec.run(pc)
            if not run:
                break
            stop = False
            for (ad, n, text) in run:
                if ad in insn and ad != x:
                    stop = True
                    break
                insn[ad] = (n, text)
                tg, ft, fl = flow(ad, n, text)
                if fl:
                    flags[ad] = fl
                for t in tg:
                    if inr(t) and t not in seen:
                        work.append(t)
                if not ft:
                    stop = True
                    break
                pc = ad + n
            if stop:
                break
    covered = {}
    for ad, (n, _) in insn.items():
        for k in range(n):
            covered[ad + k] = ad
    # per-line verdicts
    res = []
    counts = collections.Counter()
    for rel, L in files.items():
        A = la[rel]
        for i, t in enumerate(L):
            kind = rw.drc.classify_line(t, {})[0]
            if kind not in ("code", "data") or A[i] is None:
                continue
            s = A[i]
            j = i + 1
            while j < len(A) and (A[j] is None or rw.drc.classify_line(L[j], {})[0] not in ("code", "data", "fill")):
                j += 1
            e = A[j] if j < len(A) and A[j] is not None else s
            if e <= s:
                continue
            hit = [covered.get(k) for k in range(s, e)]
            reached = any(h is not None for h in hit)
            if kind == "code":
                if not reached:
                    v = "UNREACHED"
                elif s in insn and insn[s][0] == e - s:
                    v = "OK"
                else:
                    v = "MISFRAME"
            else:
                v = "CODE-AS-DATA" if reached else None
            if v:
                counts[v] += 1
                counts[v + "_B"] += e - s
                res.append(dict(rel=rel, line=i + 1, start=s, end=e, verdict=v, text=t.strip()[:60]))
    tc = subprocess.run(["git", "log", "-1", "--format=%h"], cwd=os.path.join(LL, "..", ".."),
                        capture_output=True, text=True).stdout.strip()
    print("toolchain llvm-project@%s  seeds %d  reached insns %d  flags %d" % (tc, len(seeds), len(insn), len(flags)))
    for k in ("OK", "MISFRAME", "CODE-AS-DATA", "UNREACHED"):
        print("  %-13s %6d lines %7d B" % (k, counts[k], counts[k + "_B"]))
    for ad in sorted(flags)[:a.show]:
        print("  FLAG %06X %s" % (ad, flags[ad]))
    if a.emit_spec:
        specs = []
        for rel in a.file:
            rows = [r for r in res if r["rel"] == rel]
            k = 0
            while k < len(rows):
                if rows[k]["verdict"] not in ("MISFRAME", "CODE-AS-DATA"):
                    k += 1
                    continue
                j = k
                # widen backward to an OK line (its start is a reached boundary)
                while j > 0 and rows[j - 1]["verdict"] in ("MISFRAME", "CODE-AS-DATA") and \
                        rows[j - 1]["end"] == rows[j]["start"]:
                    j -= 1
                start = rows[j]["start"]
                e = k
                while e + 1 < len(rows) and rows[e + 1]["start"] == rows[e]["end"] and \
                        rows[e + 1]["verdict"] in ("MISFRAME", "CODE-AS-DATA"):
                    e += 1
                end = rows[e]["end"]
                ok = start in insn and (end in insn or
                                        (end not in covered and (end - 1) in covered))
                # every reached instruction in [start,end) must lie inside it
                if ok and all(ad + insn[ad][0] <= end for ad in insn if start <= ad < end):
                    specs.append(dict(file=rel, start="0x%X" % start, end="0x%X" % end, kind="code"))
                else:
                    print("  SKIP %s 0x%X-0x%X: ends are not reached instruction boundaries" % (rel, start, end))
                k = e + 1
        json.dump(specs, open(a.emit_spec, "w"), indent=1)
        print("  wrote %d re-frame spans (%d B) to %s" % (len(specs), sum(int(x["end"], 16) - int(x["start"], 16) for x in specs), a.emit_spec))
    if a.json:
        json.dump(dict(lines=res, flags={"%06X" % k: v for k, v in flags.items()},
                       insn={"%06X" % k: [n, t] for k, (n, t) in insn.items()},
                       seeds={"%06X" % k: why.get(k, "") for k in seeds}), open(a.json, "w"), indent=0)


if __name__ == "__main__":
    main()
