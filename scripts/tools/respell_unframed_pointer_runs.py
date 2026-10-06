#!/usr/bin/env python3
"""Spell the dispatch census's unframed pointer runs as `.long Label` lines.

QUESTION IT ANSWERS / WHAT IT DOES
  The census's U detector (scripts/analysis/dispatch_table_census/census.py) finds runs of 32-bit code
  pointers held as bytes: a slice of a compiled-C .incbin with no link script, or `.byte` lines.  Each word
  is a labelled instruction start.  Byte-identical either way, such a run hides a pointer table from every
  reader.  For one maincpu tree and the run names given on the command line (reviewed by hand: the census
  has a measured false-positive rate), this script replaces the bytes of each run with one `.long` per word.
    - a word that equals a labelled instruction start is spelled by that label;
    - any other word stays a number, so no name is invented;
    - each source row the run covers is rewritten IN PLACE: its own label, the bytes before the run, the
      `.long` words that fall inside the row, the bytes after it.  Lines between rows -- labels on their own
      line, comments -- are untouched, so every label keeps its address.  A run in which a word straddles
      two rows is skipped.  (The first version replaced the whole span and moved an interior label by 0x30:
      `make all` caught it.)
  The census map must be built from this exact tree first.

RUN (repository root)
  python3 scripts/analysis/dispatch_table_census/build_maps.py
  python3 scripts/tools/respell_unframed_pointer_runs.py v10 --dry-run NAME ...
  python3 scripts/tools/respell_unframed_pointer_runs.py v10 NAME ...       # then `make all`: byte-identical
"""
import collections
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
ARGS = sys.argv[1:]
sys.argv = sys.argv[:1]
import census  # noqa: E402

TREE_DIR = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu"}
LABEL_PREFIX = re.compile(r'^([A-Za-z_.$][\w.$@]*):')


def label_at(m, addr):
    r = census.find(m, addr)
    if r and r[0] == addr and r[7]:
        return r[7]
    names = sorted(n for (a, t, n) in m["syms"] if a == addr and t in "tT" and not n.startswith(".L"))
    return names[0] if names else None


def byte_values(text):
    vals = []
    for o in census.operands(text):
        if not census.NUM.match(o):
            return None
        vals.append(int(o, 0) & 0xFF)
    return vals


def main():
    key = ARGS[0]
    dry = "--dry-run" in ARGS
    names = [a for a in ARGS[1:] if not a.startswith("--")]
    m = census.load(key)
    rows = m["rows"]
    runs = [t for t in census.detect_U(key) if t["name"] in names]
    edits = collections.defaultdict(list)
    done = []
    for t in runs:
        lo_ = min(e["at"] for e in t["ents"])
        hi_ = max(e["at"] for e in t["ents"]) + 4
        words = [(a, census.le(m, a, 4)) for a in range(lo_, hi_, 4)]
        longs = []
        for a, v in words:
            lab = label_at(m, v) if census.owner(key, v) and census.owner(key, v)[0] == key else None
            longs.append("\t.long\t%s" % (lab if lab else "0x%08x" % v))
        cover = sorted((r for r in rows if r[1] > lo_ and r[0] < hi_), key=lambda r: r[0])
        if not cover or len({r[3] for r in cover}) != len(cover):
            print("skip %s: several rows share a source line" % t["name"])
            continue
        word_at = dict(zip(range(lo_, hi_, 4), longs))
        ok, plans = True, []
        for r in cover:
            lo, hi, rel, li, kind, detail, text, lab = r
            s_, e_ = max(lo, lo_), min(hi, hi_)
            if (s_ - lo_) % 4 or (e_ - lo_) % 4:
                ok = False                      # a word straddles two source rows
                break
            mm = LABEL_PREFIX.match(text.strip())
            new = [mm.group(1) + ":"] if mm else []
            body = [word_at[x] for x in range(s_, e_, 4)]
            if kind == "data" and detail == ".incbin":
                mi = re.search(r'\.incbin\s+"([^"]+)"(?:\s*,\s*(0x[0-9a-fA-F]+|\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+))?', text)
                if not mi:
                    ok = False
                    break
                path, off = mi.group(1), int(mi.group(2), 0) if mi.group(2) else 0
                if lo < s_:
                    new.append('\t.incbin "%s", 0x%x, 0x%x' % (path, off, s_ - lo))
                new += body
                if hi > e_:
                    new.append('\t.incbin "%s", 0x%x, 0x%x' % (path, off + (e_ - lo), hi - e_))
            elif kind == "data" and detail == ".byte":
                vals = byte_values(text)
                if vals is None or len(vals) != hi - lo:
                    ok = False
                    break
                if lo < s_:
                    new.append("\t.byte\t" + ", ".join("0x%02x" % x for x in vals[:s_ - lo]))
                new += body
                if hi > e_:
                    new.append("\t.byte\t" + ", ".join("0x%02x" % x for x in vals[e_ - lo:]))
            else:
                ok = False
                break
            plans.append((rel, li, new))
        if not ok:
            print("skip %s: a word straddles two rows, or its bytes are not an .incbin slice or plain .byte lines"
                  % t["name"])
            continue
        for rel, li, new in plans:
            edits[rel].append((li, li, new))      # each row's own line only: labels, comments around it stay
        n_sym = sum(1 for x in longs if not x.split("\t")[-1].startswith("0x"))
        done.append((t["name"], len(longs), n_sym))
    for n, k, s in done:
        print("%-44s %3d words, %3d by label" % (n, k, s))
    if dry:
        return
    root = os.path.join(REPO, TREE_DIR[key])
    for rel, ops in edits.items():
        p = os.path.join(root, rel)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        floor = None
        for a, b, new in sorted(ops, key=lambda x: -x[0]):
            assert floor is None or b < floor
            L[a:b + 1] = new
            floor = a
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
