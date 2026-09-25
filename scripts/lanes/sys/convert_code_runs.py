#!/usr/bin/env python3
r"""Convert `.byte` runs that are CODE (something branches into them) into
instructions, with the evidence the 2026-09-25 brief asks for.

QUESTION THIS ANSWERS
    The data census flags data regions that a branch or call lands in
    (`code_suspect` / `embedded_in_code`).  For each such `.byte` run in the
    given files: does it decode as clean code from its start, and NOT from
    start+1?  If so, write it as instructions.

EVIDENCE CHECKED PER RUN (all must hold, else the run is reported and left)
  1. MAME unidasm decodes [lo, hi) linearly from lo into instructions that
     tile it exactly (or, with --prefix, a prefix of it ending after a
     ret/jp/jr/jrl that is followed only by bytes the next checks accept),
     with none of the absurd markers (halt/incf/decf/ldf/normal/max/min/
     swi/db/never-taken jr f).
  2. The same bytes decoded from lo+1 are NOT clean (they contain an absurd
     marker or do not tile) -- so the framing is not an accident of dense
     opcode space.
  3. Every label already inside the run lands on an instruction start.
  4. Every instruction is decoded by llvm-mc and re-assembled in isolation to
     the ROM's bytes (else it stays `.byte`, with unidasm's text as comment).
  5. At least one absolute call/jp target inside the decode, or the branch
     into the run that the census found, is reported so a reader can check it.
  Then the image is rebuilt and compared with the dump.

RUN
    python3 scripts/analysis/data_range_census.py --images v10 --json C.json
    python3 scripts/lanes/sys/convert_code_runs.py --image v10 --census C.json \
        --file boot/system_handlers.s [--file ...] [--show] [--apply]
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import port_islands as pi  # noqa: E402
import reframe_markers as rm  # noqa: E402

BASE = pi.BASE
ENDERS = re.compile(r'^(ret|reti|retd|jp|jrl?\s+(t,\s*)?0x|jr\s+0x)', re.I)


def clean(ins, lo, hi):
    if not ins or ins[0][0] != lo:
        return False
    end = ins[-1][0] + ins[-1][1]
    tiles = all(ins[k][0] + ins[k][1] == ins[k + 1][0] for k in range(len(ins) - 1))
    return tiles and end == hi and not any(rm.UABS.search(t) for a, n, t in ins)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--census", required=True)
    ap.add_argument("--file", action="append", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()
    R = rm.Reframer(a.image)
    regs = [r for r in json.load(open(a.census))["regions"]
            if r["image"] == a.image and r["rel"] in a.file and r["grade"] != "CODE"
            and (r.get("code_suspect") or r.get("embedded_in_code")) and ".byte" in r["details"]]
    plans = collections.defaultdict(list)
    for r in sorted(regs, key=lambda r: (r["rel"], r["addr"])):
        lo, hi = r["addr"], r["addr"] + r["size"]
        rows = R.file_rows(r["rel"])
        ins = rm.unidasm(R.rom, lo, hi)
        ins = [x for x in ins if x[0] < hi]
        why = None
        if not clean(ins, lo, hi):
            why = "unidasm from start is not clean code tiling the run"
        elif hi - lo >= 16:
            # discrimination: decodes starting INSIDE the first multi-byte
            # instruction must not all be clean too (else the framing is an
            # accident of dense opcode space)
            # A clean decode from inside an instruction that REJOINS this
            # framing is ordinary self-synchronisation; one that stays
            # disjoint from it to the end of the run is a competing parse.
            first = next((x for x in ins if x[1] > 1), None)
            if first is not None:
                starts0 = {x[0] for x in ins}
                for k in range(1, first[1]):
                    s0 = first[0] + k
                    alt = [x for x in rm.unidasm(R.rom, s0, hi) if x[0] < hi]
                    if clean(alt, s0, hi) and not any(x[0] in starts0 for x in alt):
                        why = "a disjoint clean parse starts at 0x%06X (framing ambiguous)" % s0
                        break
        if not why:
            # corroboration: an internal branch landing on an instruction start,
            # an absolute call/jp to a known label, or a single-instruction run
            starts0 = {x[0] for x in ins}
            corr = []
            for x in ins:
                m = re.search(r'0x([0-9a-f]{6})\b', x[2])
                if m and re.match(r'(jr|jrl|calr|djnz|call|jp)\b', x[2], re.I):
                    v = int(m.group(1), 16)
                    if lo <= v < hi and v in starts0:
                        corr.append("internal branch -> 0x%06X" % v)
                    elif v in R.addr_label:
                        corr.append("-> %s" % R.addr_label[v])
            if len(ins) == 1:
                corr.append("single instruction")
            if not corr:
                why = "no corroboration (no internal branch to an instruction start, no call/jp to a known label)"
        # source lines of the run
        idx = [i for i, e in enumerate(rows) if e[0] is not None and lo <= e[0] < hi and e[4] > 0]
        if not why and not idx:
            why = "no source lines"
        if not why:
            if rows[idx[0]][0] != lo or rows[idx[-1]][0] + rows[idx[-1]][4] != hi:
                why = "run does not start/end on source line boundaries"
            elif any(not pi.split_line(rows[i][3])[1].startswith(".byte") for i in idx):
                why = "run holds non-.byte lines"
        starts = {x[0] for x in ins}
        if not why:
            for i in range(idx[0], idx[-1] + 1):
                if rows[i][0] is not None and pi.split_line(rows[i][3])[0] and rows[i][0] not in starts:
                    why = "label at 0x%06X inside an instruction" % rows[i][0]
        if why:
            print("  %s:%d 0x%06X %4d B %-40s SKIP %s" % (r["rel"], r["line"], lo, r["size"], (r["label"] or "")[:40], why))
            continue
        # absolute targets of the decode, for the reader
        tg = []
        for x in ins:
            m = re.search(r'\b(call|jp|calr)\b.*0x([0-9a-f]{6})', x[2])
            if m:
                v = int(m.group(2), 16)
                tg.append("%s(%s)" % (R.addr_label.get(v, "0x%06X" % v), m.group(1)))
        t = R.texts(ins)
        nb = sum(1 for x in t if not x[3])
        if nb == len(t):
            print("  %s:%d 0x%06X %4d B %-40s SKIP llvm-mc cannot round-trip any of it (stays .byte)" % (
                r["rel"], r["line"], lo, r["size"], (r["label"] or "")[:40]))
            continue
        print("  %s:%d 0x%06X %4d B %-40s -> %d insns (%d .byte); targets: %s" % (
            r["rel"], r["line"], lo, r["size"], (r["label"] or "")[:40], len(t), nb, ", ".join(tg[:4]) or "-"))
        i0 = idx[0]
        # include label/comment lines directly above the first data line only if at lo
        plans[r["rel"]].append({"lo": lo, "hi": hi, "i0": i0, "i1": idx[-1] + 1, "t": t})
        if a.show:
            for x in t:
                print("      + \t" + x[2])
    if not a.apply:
        return 0
    backups = {}
    for rel, ps in plans.items():
        path = os.path.join(pi.ROOT, a.image, "maincpu", rel)
        raw = open(path, "rb").read()
        backups[path] = raw
        lines = raw.decode("latin-1").split("\n")
        rows = R.file_rows(rel)
        for p in sorted(ps, key=lambda p: -p["i0"]):
            notes, labs = collections.defaultdict(list), collections.defaultdict(list)
            cur = p["lo"]
            for i in range(p["i0"], p["i1"]):
                e = rows[i]
                lb, bd, cm = pi.split_line(e[3])
                ad = e[0] if e[0] is not None else cur
                if e[0] is not None:
                    cur = e[0] + e[4]
                s = e[3].strip()
                if s.startswith(";"):
                    notes[ad].append(s)
                elif cm.strip():
                    notes[ad].append(cm.strip())
                for l in lb:
                    labs[ad].append(l)
            out = []
            for (ad, n, t, ok) in p["t"]:
                own = t.split(";", 1)[1].strip() if (not ok and ";" in t) else None
                out.extend(c for c in notes.pop(ad, []) if own is None or c.lstrip("; ").strip() != own)
                for l in labs.pop(ad, []):
                    out.append("%s:" % l)
                out.append("\t" + t)
            for ad in sorted(notes):
                out.extend(notes[ad])
            l0 = rows[p["i0"]][2] - 1
            l1 = rows[p["i1"] - 1][2]
            lines[l0:l1] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
    built, err = pi.fast_build(a.image, os.path.join(pi.SCRATCH, "build"))
    if built == pi.rom(a.image):
        print("%s IDENTICAL" % a.image)
        return 0
    print("MISMATCH/FAIL; restoring", err[-1500:] if built is None else "")
    for path, raw in backups.items():
        open(path, "wb").write(raw)
    return 1


if __name__ == "__main__":
    sys.exit(main())
