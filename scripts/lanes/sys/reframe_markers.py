#!/usr/bin/env python3
r"""Find MISFRAMED stretches of code around data-as-code markers and re-frame
them with MAME unidasm's linear decode, every instruction verified by llvm-mc.

QUESTION THIS ANSWERS
    Many lines in these sources are real code decoded from the wrong starting
    byte: a lone `.byte 0xd1` followed by "instructions" made of the operand
    bytes of the real one (`ld xwa, 0x033f8a` where the ROM holds
    `cpw (0x8a40), 3`), recognisable by absurd markers (halt / incf / decf /
    ldf / normal / max / min / swi / `jr cc, 0` / never-taken `jr f`) and by
    short `.byte` prefixes.  Where, exactly, does the source framing leave the
    ROM's real instruction stream and where does it rejoin it -- and what is
    the correct framing in between?

HOW (per cluster of suspect lines in one file)
  1. Suspects: lines whose instruction is an absurd marker (the regex of
     scripts/analysis/lane_worklists.py) and `.byte` runs of 1-3 bytes lying
     between instruction lines.  Suspects closer than 12 lines are clustered.
  2. Start: walking back from the cluster, the earliest instruction line (at
     most BACK lines up, never across a data line or into another file) such
     that unidasm, decoding linearly from it, has an instruction start at every
     source line start up to the first suspect.  The source framing up to the
     suspect is thereby confirmed by a second decoder.
  3. Divergence: the first source line whose start unidasm does not share.
     Resync: the first later address where both have a boundary and the next
     RESYNC source lines all start on unidasm boundaries too.  [div, resync)
     is the misframed range.
  4. Refusals (the cluster is reported and left alone):
       - the range contains a label unidasm puts inside an instruction;
       - unidasm's own framing of the range contains an absurd marker (the
         bytes are probably DATA, not misframed code -- another job);
       - no resync within FWD lines.
  5. Each unidasm instruction's bytes are decoded by llvm-mc and the text
     re-assembled in isolation; it must reproduce the bytes, else the
     instruction is written as `.byte` with unidasm's text as a comment.
  6. Labels and comments of the old lines are re-emitted at their addresses.
  7. --apply writes, rebuilds the image into scratch and compares with the
     dump; a mismatch restores the file.

RUN
    python3 scripts/lanes/sys/reframe_markers.py --image v10 --file storage/fdc_routines.s [--apply]
    then scripts/converters/symbolize_numeric_branches.py on the same files.
"""
import argparse
import collections
import concurrent.futures as cf
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402

ROOT = pi.ROOT
BASE = pi.BASE
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
UABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi|db)\b|^(jr|jrl)\s+f,', re.I)
BACK, FWD, RESYNC = 12, 40, 4
BRANCH = {"jr", "jrl", "calr", "djnz", "djnz16", "djnz8"}
# llvm-mc printer name -> the parser spelling used across the tree
CANON = {"cpdi8": "cp\t(%s:16), %s", "cpdi16": "cpw\t(%s:16), %s"}
CANON_RE = re.compile(r'^(cpdi8|cpdi16)\t\((0x[0-9a-f]+)\), (\S+)$')


def unidasm(rom, lo, hi):
    tmp = os.path.join(pi.SCRATCH, "rfm_%x.bin" % lo)
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


def house_numbers(mn, ops):
    """(from the audio lane's reframe_region.py) addresses in parentheses and
    values >= 256 in hex, small values decimal; branch displacements as is."""
    if mn in BRANCH:
        return ops

    def paren(m):
        return re.sub(r'(?<![\w.$])(\d+)(?![\w.$])', lambda n: "0x%x" % int(n.group(1)), m.group(0))
    ops = re.sub(r'\([^)]*\)', paren, ops)

    def big(m):
        v = int(m.group(1))
        return ("0x%x" % v) if v >= 256 else m.group(1)
    out = []
    for part in re.split(r'(\([^)]*\))', ops):
        out.append(part if part.startswith("(") else re.sub(r'(?<![\w.$:])(\d+)(?![\w.$])', big, part))
    return "".join(out)


def mc_decode(b):
    r = subprocess.run([pi.MC, "-triple=tlcs900", "--disassemble"], input=" ".join("0x%02x" % x for x in b),
                       capture_output=True, text=True)
    lines = [l.strip() for l in r.stdout.splitlines() if l.strip() and not l.strip().startswith(".text")]
    if r.returncode != 0 or len(lines) != 1 or "warning" in r.stderr or "invalid" in r.stderr:
        return None
    t = re.sub(r'\s+', " ", lines[0])
    p = t.split(" ", 1)
    mn, ops = p[0], (p[1] if len(p) > 1 else "")
    return mn + ("\t" + house_numbers(mn, ops) if ops else "")


def body_of(text):
    return pi.split_line(text)[1]


def is_insn(body):
    return bool(body) and not body.startswith(".") and not body.startswith("#")


class Reframer:
    def __init__(self, image):
        self.image = image
        self.rom = pi.rom(image)
        self.order, self.syms = pi.amap(image)
        self.addr_label = {}
        for k, v in self.syms.items():
            if BASE <= v < 0x1000000 and not k.startswith("__"):
                self.addr_label.setdefault(v, k)

    def file_rows(self, rel):
        return [e for e in self.order if e[1] == rel]

    def suspects(self, rows):
        idx = []
        for i, e in enumerate(rows):
            b = body_of(e[3])
            if not b or e[0] is None:
                continue
            if is_insn(b) and ABS.search(b):
                idx.append(i)
            elif b.startswith(".byte") and 0 < e[4] <= 3:
                # short .byte between instructions
                prv = next((rows[j] for j in range(i - 1, -1, -1) if body_of(rows[j][3])), None)
                nxt = next((rows[j] for j in range(i + 1, len(rows)) if body_of(rows[j][3])), None)
                if prv and nxt and is_insn(body_of(prv[3])) and is_insn(body_of(nxt[3])):
                    idx.append(i)
        cl = []
        for i in idx:
            if cl and i - cl[-1][-1] <= 12:
                cl[-1].append(i)
            else:
                cl.append([i])
        return cl

    def plan_cluster(self, rows, cl):
        """-> dict(lo, hi, i0, i1, new=[(addr, n, text)], why) or dict(why=...)"""
        first = cl[0]
        byte_lines = [i for i in range(len(rows)) if rows[i][0] is not None and rows[i][4] > 0]
        # candidate starts: instruction lines above the first suspect
        cands = []
        j = first - 1
        while j >= 0 and len(cands) < BACK:
            e = rows[j]
            b = body_of(e[3])
            if b and e[0] is not None and e[4] > 0:
                if not is_insn(b):
                    break
                cands.append(j)
            j -= 1
        if not cands:
            return {"why": "no instruction line above the cluster"}
        last = cl[-1]
        # end bound for decoding
        tail = [i for i in byte_lines if i > last][:FWD]
        if not tail:
            return {"why": "cluster at end of file"}
        hi_dec = rows[tail[-1]][0] + rows[tail[-1]][4]
        for s in reversed(cands):          # earliest candidate first
            lo_dec = rows[s][0]
            ud = unidasm(self.rom, lo_dec, hi_dec + 8)
            ustart = {a for a, n, t in ud}
            src_starts = [(i, rows[i][0]) for i in byte_lines if s <= i <= tail[-1]]
            # confirm framing from s up to the first suspect
            ok = all(a in ustart for i, a in src_starts if i < first)
            if not ok:
                continue
            div = next(((i, a) for i, a in src_starts if a not in ustart), None)
            if div is None:
                return {"why": "unidasm agrees with the source framing (not a misframe)"}
            di, da = div
            # the misframed range starts at the source line containing the divergence
            # boundary before it: the previous source line start
            prev = [x for x in src_starts if x[1] < da]
            i0, lo = prev[-1] if prev else (di, da)
            # resync
            later = [x for x in src_starts if x[1] > da]
            res = None
            for k, (i, a) in enumerate(later):
                if a in ustart and all(b in ustart for _, b in later[k:k + RESYNC]) and len(later[k:k + RESYNC]) == RESYNC:
                    res = (i, a)
                    break
            if res is None:
                return {"why": "no resync within %d lines" % FWD}
            i1, hi = res
            new = [(a, n, t) for a, n, t in ud if lo <= a < hi]
            if not new or new[0][0] != lo or new[-1][0] + new[-1][1] != hi:
                return {"why": "unidasm framing does not tile [0x%06X, 0x%06X)" % (lo, hi)}
            if any(UABS.search(t) for a, n, t in new):
                return {"why": "unidasm's own framing of 0x%06X-0x%06X has absurd markers (data?)" % (lo, hi)}
            starts = {a for a, n, t in new}
            for i in range(i0, i1):
                for lab in pi.split_line(rows[i][3])[0]:
                    if rows[i][0] is not None and rows[i][0] not in starts and rows[i][0] != hi:
                        return {"why": "label %s at 0x%06X falls inside a unidasm instruction" % (lab, rows[i][0])}
            return {"lo": lo, "hi": hi, "i0": i0, "i1": i1, "new": new, "why": None}
        return {"why": "unidasm disagrees with the source framing before the cluster too"}

    def texts(self, new):
        with cf.ThreadPoolExecutor(8) as ex:
            dec = list(ex.map(lambda x: mc_decode(self.rom[x[0] - BASE:x[0] - BASE + x[1]]), new))
        # canonical spellings the rest of the tree uses, where llvm-mc's printer
        # emits an internal name; kept only if they re-assemble to the same bytes
        canon = {}
        for k, t in enumerate(dec):
            if t is None:
                continue
            c = CANON_RE.sub(lambda m: CANON[m.group(1)] % (m.group(2), m.group(3)), t)
            if c != t:
                canon[k] = c
        ck = sorted(canon)
        cgot = pi.assemble_all([canon[k] for k in ck], os.path.join(ROOT, self.image, "maincpu")) if ck else []
        for k, g in zip(ck, cgot):
            if g == self.rom[new[k][0] - BASE:new[k][0] - BASE + new[k][1]]:
                dec[k] = canon[k]
        idx = [k for k, t in enumerate(dec) if t is not None]
        got = pi.assemble_all([dec[k] for k in idx], os.path.join(ROOT, self.image, "maincpu"))
        out = []
        good = {k for k, g in zip(idx, got) if g == self.rom[new[k][0] - BASE:new[k][0] - BASE + new[k][1]]}
        for k, (a, n, ut) in enumerate(new):
            b = self.rom[a - BASE:a - BASE + n]
            if k in good:
                t = dec[k]
                m = re.match(r'^(ld|lda)\t(x\w\w), 0x([0-9a-f]+)$', t)
                if m and int(m.group(3), 16) in self.addr_label and int(m.group(3), 16) >= BASE:
                    t = "%s\t%s, %s" % (m.group(1), m.group(2), self.addr_label[int(m.group(3), 16)])
                out.append((a, n, t, True))
            else:
                out.append((a, n, ".byte\t" + ", ".join("0x%02x" % x for x in b) + "\t; " + ut, False))
        return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", action="append", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()
    R = Reframer(a.image)
    todo = collections.defaultdict(list)
    tot = collections.Counter()
    for rel in a.file:
        rows = R.file_rows(rel)
        for cl in R.suspects(rows):
            p = R.plan_cluster(rows, cl)
            ln = rows[cl[0]][2]
            if p["why"]:
                print("  %s:%d  SKIP  %s" % (rel, ln, p["why"]))
                tot["skip"] += 1
                continue
            t = R.texts(p["new"])
            nb = sum(1 for x in t if not x[3])
            print("  %s:%d  0x%06X-0x%06X %3d B -> %d insns (%d as .byte)" % (
                rel, ln, p["lo"], p["hi"], p["hi"] - p["lo"], len(t), nb))
            tot["ranges"] += 1
            tot["bytes"] += p["hi"] - p["lo"]
            p["t"] = t
            todo[rel].append(p)
            if a.show:
                for i in range(p["i0"], p["i1"]):
                    print("      - " + rows[i][3])
                for x in t:
                    print("      + \t" + x[2])
    print("clusters: %d reframed ranges (%d B), %d skipped" % (tot["ranges"], tot["bytes"], tot["skip"]))
    if not a.apply:
        return 0
    backups = {}
    for rel, plans in todo.items():
        path = os.path.join(ROOT, a.image, "maincpu", rel)
        raw = open(path, "rb").read()
        backups[path] = raw
        lines = raw.decode("latin-1").split("\n")
        rows = R.file_rows(rel)
        # dedupe overlapping plans
        plans.sort(key=lambda p: p["lo"])
        keep, last = [], None
        for p in plans:
            if last is not None and p["lo"] < last:
                continue
            keep.append(p)
            last = p["hi"]
        for p in sorted(keep, key=lambda p: -p["i0"]):
            notes = collections.defaultdict(list)
            labs = collections.defaultdict(list)
            cur = p["lo"]
            for i in range(p["i0"], p["i1"]):
                e = rows[i]
                lb, bd, cm = pi.split_line(e[3])
                ad = e[0] if e[0] is not None else cur
                if e[0] is not None:
                    cur = e[0] + e[4]
                t = e[3].strip()
                if t.startswith(";"):
                    notes[ad].append(t)
                elif cm.strip():
                    notes[ad].append(cm.strip())
                for l in lb:
                    labs[ad].append(l)
            out = []
            for (ad, n, t, ok) in p["t"]:
                out.extend(notes.pop(ad, []))
                for l in labs.pop(ad, []):
                    out.append("%s:" % l)
                out.append("\t" + t)
            for ad in sorted(notes):
                out.extend(notes[ad])
            for ad in sorted(labs):
                for l in labs[ad]:
                    out.append("%s:" % l)
            l0 = rows[p["i0"]][2] - 1
            l1 = rows[p["i1"] - 1][2]
            lines[l0:l1] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
    built, err = pi.fast_build(a.image, os.path.join(pi.SCRATCH, "build"))
    if built == pi.rom(a.image):
        print("%s IDENTICAL" % a.image)
        return 0
    print("BUILD MISMATCH or failure; restoring.", err[-2000:] if built is None else "")
    if built is not None:
        rd = pi.rom(a.image)
        bad = [x for x in range(min(len(built), len(rd))) if built[x] != rd[x]]
        print("  %d bytes differ, first 0x%06X" % (len(bad), bad[0] + BASE if bad else 0))
    for path, raw in backups.items():
        open(path, "wb").write(raw)
    return 1


if __name__ == "__main__":
    sys.exit(main())
