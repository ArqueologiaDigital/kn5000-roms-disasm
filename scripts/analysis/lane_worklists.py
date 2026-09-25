#!/usr/bin/env python3
r"""Per-lane worklists for the 2026-09-25 semantic push.

QUESTION THIS ANSWERS
    Given the roster (notes/lanes/ROSTER-2026-09-25.json: which lane owns which
    source files), a data-census JSON (scripts/analysis/data_range_census.py
    --json) and the branch symboliser's --report JSONs, what concrete work is
    in each lane's files?  One markdown worklist per lane: census bytes, the
    research targets, the biggest name-only (KNOWN-B) objects, the branch sites
    the symboliser REFUSED (misframe / data-as-code evidence), v7 romslices and
    data-as-code marker counts.

    --check asserts that every tracked source file (.s/.c/.h/.ld under the
    gated trees) is owned by EXACTLY one lane.  Ownership is the most specific
    matching glob: an exact path beats any glob; among globs, the one with more
    literal characters wins; a glob without '/' only matches repo-root /
    maincpu-root files.

RUN
    python3 scripts/analysis/lane_worklists.py --check
    python3 scripts/analysis/lane_worklists.py --census C.json --symbr-dir DIR --out OUTDIR
      (DIR holds <image>.json reports written by symbolize_numeric_branches.py --report)
"""
import argparse
import collections
import fnmatch
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROSTER = os.path.join(ROOT, "notes", "lanes", "ROSTER-2026-09-25.json")
MAINCPU = ("v10/maincpu/", "v9/maincpu/", "v7/maincpu/")
IMG_ROOT = {"v10": "v10/maincpu/", "v9": "v9/maincpu/", "v7": "v7/maincpu/",
            "v142": "v142/subcpu/", "subboot": "subcpu/boot/", "tabledata": "table_data/",
            "customdata": "custom_data/", "hdae5000": "hdae5000/",
            "prom_a": "wsa1/", "prom_b": "wsa1/", "prom_c": "wsa1/", "prom_d": "wsa1/"}
GATED = MAINCPU + ("v142/subcpu/", "subcpu/boot/", "table_data/", "custom_data/",
                   "hdae5000/", "wsa1/prom_a/", "wsa1/prom_b/", "wsa1/prom_c/",
                   "wsa1/prom_d/", "wsa1/kernel/", "wsa1/dsp/")
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')


def score(pat, path):
    if "/" not in pat and "/" in path:
        return None
    if not fnmatch.fnmatchcase(path, pat):
        return None
    lit = len(re.sub(r'[*?\[\]]', '', pat))
    return lit + (1000 if not re.search(r'[*?\[]', pat) else 0)


def owner(path, lanes):
    """repo-relative path -> lane id (or None)."""
    best = []
    for ln in lanes:
        if path.startswith(MAINCPU):
            rel = path.split("/", 2)[2]
            pats = ln.get("maincpu", [])
        else:
            rel = path
            pats = ln.get("repo", [])
        for p in pats:
            sc = score(p, rel)
            if sc is not None:
                best.append((sc, ln["id"]))
    if not best:
        return None
    best.sort(reverse=True)
    if len(best) > 1 and best[0][0] == best[1][0] and best[0][1] != best[1][1]:
        return "AMBIGUOUS:%s/%s" % (best[0][1], best[1][1])
    return best[0][1]


def tracked():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True).stdout.split()
    return [p for p in out if p.startswith(GATED) and p.endswith((".s", ".c", ".h", ".ld", ".inc"))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--census")
    ap.add_argument("--symbr-dir")
    ap.add_argument("--out")
    a = ap.parse_args()
    lanes = json.load(open(ROSTER))["lanes"]
    files = tracked()
    own = {p: owner(p, lanes) for p in files}
    if a.check:
        bad = {p: o for p, o in own.items() if o is None or o.startswith("AMBIGUOUS")}
        per = collections.Counter(own.values())
        for k, v in sorted(per.items(), key=lambda kv: str(kv[0])):
            print("  %-12s %5d files" % (k, v))
        for p, o in sorted(bad.items())[:40]:
            print("  UNOWNED/AMBIGUOUS", p, o)
        print("CHECK", "PASS" if not bad else "FAIL (%d)" % len(bad))
        sys.exit(1 if bad else 0)

    cen = json.load(open(a.census))["regions"]
    work = collections.defaultdict(lambda: collections.defaultdict(list))
    tot = collections.defaultdict(collections.Counter)
    for r in cen:
        path = IMG_ROOT[r["image"]] + r["rel"]
        o = own.get(path)
        if not o:
            continue
        g = r["grade"]
        tot[o][g] += r["size"]
        tgt = g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")
        if tgt and g != "CODE":
            tot[o]["RESEARCH"] += r["size"]
            work[o]["targets"].append(r)
        elif g == "KNOWN-B" and r["size"] >= 512:
            work[o]["knownb"].append(r)
        if r.get("code_suspect") and g != "CODE":
            work[o]["suspect"].append(r)
    # symboliser refusals
    for img in IMG_ROOT:
        f = os.path.join(a.symbr_dir, img + ".json") if a.symbr_dir else None
        if not f or not os.path.exists(f):
            continue
        rep = json.load(open(f))["report"]
        for kind, rows in rep.items():
            for x in rows:
                path = IMG_ROOT[img] + x["src"].rsplit(":", 1)[0]
                o = own.get(path)
                if o:
                    work[o]["symbr"].append((img, kind, x))
    # v7 romslices + absurd markers
    for p, o in own.items():
        if not p.endswith(".s"):
            continue
        L = open(os.path.join(ROOT, p), encoding="latin-1").read().split("\n")
        prev, nabs = "", 0
        for i, ln in enumerate(L):
            c = ln.split(";")[0]
            m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
            if m:
                full = os.path.join(ROOT, "v7/maincpu", m.group(1))
                work[o]["romslices"].append((p, i + 1, m.group(1),
                                             os.path.getsize(full) if os.path.exists(full) else -1))
            cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
            if not cc or cc.startswith("."):
                prev = ""
                continue
            if ABS.match(cc) or (cc == "nop" and prev == "nop"):
                nabs += 1
            prev = cc
        if nabs:
            work[o]["absurd"].append((p, nabs))

    os.makedirs(a.out, exist_ok=True)
    for ln in lanes:
        o = ln["id"]
        w = work[o]
        mine = sorted(p for p, x in own.items() if x == o)
        out = ["# Worklist -- lane `%s`" % o, "",
               "Generated by `scripts/analysis/lane_worklists.py` from census `%s`." % os.path.basename(a.census),
               "Regenerable; do not edit.  Owned files: %d." % len(mine), "",
               "## Census bytes in your files (all versions summed)", "",
               "| CODE | KNOWN-A | KNOWN-B | UNKNOWN | FILLER | research targets |",
               "|---:|---:|---:|---:|---:|---:|",
               "| %d | %d | %d | %d | %d | %d |" % tuple(tot[o][k] for k in
                                                     ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH")),
               ""]
        t = sorted(w["targets"], key=lambda r: -r["size"])
        out += ["## Research targets (%d regions, %d B) -- largest first" % (len(t), sum(r["size"] for r in t)), ""]
        for r in t[:80]:
            why = "UNKNOWN" if r["grade"] == "UNKNOWN" else ("self-admitted" if r.get("admits") else "embedded-in-code")
            out.append("- %s `%s:%d` 0x%06X %d B `%s` -- %s" % (r["image"], r["rel"], r["line"] + 1,
                                                              r["addr"] or 0, r["size"], r["label"], why))
        kb = sorted(w["knownb"], key=lambda r: -r["size"])
        out += ["", "## Name-only (KNOWN-B) objects >= 512 B (%d, %d B) -- need an evidence header" %
                (len(kb), sum(r["size"] for r in kb)), ""]
        for r in kb[:60]:
            out.append("- %s `%s:%d` 0x%06X %d B `%s` %s" % (r["image"], r["rel"], r["line"] + 1,
                                                          r["addr"] or 0, r["size"], r["label"],
                                                          ",".join(sorted(set(r.get("hints", []))))))
        su = sorted(w["suspect"], key=lambda r: -r["size"])
        out += ["", "## Code-suspect data regions (something branches into them) (%d, %d B)" %
                (len(su), sum(r["size"] for r in su)), ""]
        for r in su[:40]:
            out.append("- %s `%s:%d` 0x%06X %d B `%s`" % (r["image"], r["rel"], r["line"] + 1,
                                                       r["addr"] or 0, r["size"], r["label"]))
        sb = w["symbr"]
        kinds = collections.Counter((img, k) for img, k, _ in sb)
        out += ["", "## Branch sites the symboliser left NUMERIC (evidence of misframing / data-as-code)", "",
                "Reasons: R1 incoherent small block, R2 fragment in a table, R3 absurd neighbourhood,"
                " R5 second decoder (unidasm) disagrees = phantom branch from a MISFRAMED instruction,"
                " R6 text/pointer table, never-taken `jr f`, mid-line-* = target lands inside an"
                " instruction/data line, external = target outside the image.", ""]
        for (img, k), n in sorted(kinds.items()):
            out.append("- %s %s: %d" % (img, k, n))
        out += [""]
        shown = 0
        for img, k, x in sb:
            if k in ("R5", "mid-line-code", "mid-line-data") and shown < 120:
                out.append("  - %s %s `%s` src %s -> %s %s" % (img, k, x["src"], x["src_addr"], x["target"],
                                                            x.get("unidasm", "")))
                shown += 1
        rs = w["romslices"]
        out += ["", "## v7 romslices (verbatim ROM slices) in your files (%d, %d B)" %
                (len(rs), sum(max(0, x[3]) for x in rs)), ""]
        for p, line, inc, n in sorted(rs, key=lambda x: -x[3])[:80]:
            out.append("- `%s:%d` %s %d B" % (p, line, inc, n))
        ab = sorted(w["absurd"], key=lambda x: -x[1])
        out += ["", "## Data-as-code marker counts (halt/incf/decf/ldf/normal/max/min/swi/jr cc,0/jr f/nop-nop)", ""]
        for p, n in ab:
            out.append("- `%s`: %d" % (p, n))
        out += ["", "## Owned files", ""] + ["- `%s`" % p for p in mine]
        open(os.path.join(a.out, o + ".md"), "w").write("\n".join(out) + "\n")
        print("%-10s files=%4d research=%8d knownB=%8d refusals=%6d romslices=%4d absurd=%6d" % (
            o, len(mine), tot[o]["RESEARCH"], tot[o]["KNOWN-B"], len(sb), len(rs), sum(n for _, n in ab)))


if __name__ == "__main__":
    main()
