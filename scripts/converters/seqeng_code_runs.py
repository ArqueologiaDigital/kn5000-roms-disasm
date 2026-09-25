#!/usr/bin/env python3
r"""seqeng_code_runs.py -- decode CODE written as `.byte`/`.incbin` runs.

QUESTION ANSWERED
-----------------
"Which of the data runs that the census grades `embedded-in-code` in one of
lane seqeng's files are really code, and what are their instructions?"

HOW
---
Candidates are the census regions (data_range_census.py --json) of the file
that are not CODE and are embedded in code.  For each candidate [a0, a1):
  * unidasm decodes from a0 (FRESH -- starting at the run, not the global
    linear listing, which may be out of step after data);
  * the zone is extended past a1 to the first address that is both an
    instruction start of that decode AND the start of a source line holding an
    instruction or label -- when a run ends mid-instruction, the instructions
    after it were misframed and are re-framed with it;
  * scripts/converters/seqeng_reframe.py then rewrites the zone (llvm-mc
    spelling only where it agrees with unidasm on length, operation and
    registers; `.byte` + unidasm's text otherwise; referenced labels must land
    on instruction starts or the zone is refused).

A zone is ACCEPTED only when, over its decode:
  * no absurd mnemonic appears (the reframe tool's decode-absurdity guard:
    db / halt / swi / ldf / incf / decf / max / min / normal / reti / ei /
    auto-increment stores / low-memory calls);
  * at most 1 in 8 instructions falls back to `.byte`;
  * a1 is reached (the extension found a common boundary within 32 bytes).
Evidence strength is printed per zone: the number of call/calr/jp targets in
it that are EXISTING labels of the linked image (an independent confirmation
that it is code that calls known routines), and whether the same bytes decode
cleanly from a0+1 (they should not).

RUN
    python3 scripts/converters/seqeng_code_runs.py v7 sequencer/sequencer_engine.s \
        --census X.json --unidasm v7.unidasm [--min-size 1] [--apply]
"""
import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
import seqeng_reframe as RF  # noqa: E402
from seqeng_line_map import line_map, strip_comment, ROOT, IMAGES  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")


def image_labels(image):
    """address -> names, from a fresh link of the current tree (qc build)."""
    elf = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % image)
    out = subprocess.run([NM, "-n", elf], capture_output=True, text=True).stdout
    d = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) >= 3 and p[1] in "tT":
            d.setdefault(int(p[0], 16), []).append(p[2])
    return d


def src_kind(text):
    c = strip_comment(text).strip()
    lab = False
    while RF.LABEL_RE.match(c):
        lab = True
        c = c[RF.LABEL_RE.match(c).end():].strip()
    if not c:
        return "label" if lab else None
    return "data" if c.startswith(".") else "insn"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("file")
    ap.add_argument("--census", required=True)
    ap.add_argument("--unidasm")
    ap.add_argument("--min-size", type=int, default=1)
    ap.add_argument("--only-addr", action="append", default=[],
                    help="restrict to candidates starting at these addresses")
    ap.add_argument("--xref", help="cross-check each zone against this image (e.g. v10): "
                    "is the same byte window found there, and is it CODE in that image's source?")
    ap.add_argument("--require-xref-code", action="store_true",
                    help="accept only zones whose bytes are code in the --xref image")
    ap.add_argument("--all-data", action="store_true",
                    help="consider every non-CODE data region, not only embedded-in-code ones "
                         "(use with --xref v10 --require-xref-code, or review each zone)")
    ap.add_argument("--exclude-label", default=None,
                    help="regex: skip candidates whose census label matches (known data objects)")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    img = IMAGES[a.image]
    base = img["base"]
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    src = open(path, "rb").read().decode("latin-1").split("\n")
    rows = line_map(a.image, [a.file])[a.file]
    starts = {ad: ln for ln, ad, sz in rows}
    line_at = {}
    for ln, ad, sz in rows:
        for x in range(ad, ad + (sz or 0)):
            line_at[x] = ln
    only = {int(x, 0) for x in a.only_addr}
    cands = []
    for r in json.load(open(a.census))["regions"]:
        if r["image"] != a.image or r["rel"] != a.file or r["grade"] == "CODE":
            continue
        if r["size"] < a.min_size or r["grade"] == "FILLER":
            continue
        if not r.get("embedded_in_code") and not (a.all_data and r["bucket"] == "data"):
            continue
        if only and r["addr"] not in only:
            continue
        if a.exclude_label and r["label"] and re.search(a.exclude_label, r["label"]):
            continue
        cands.append((r["addr"], r["addr"] + r["size"], r["label"]))
    # merge touching candidates
    cands.sort()
    merged = []
    for c in cands:
        if merged and c[0] <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], c[1]), merged[-1][2])
        else:
            merged.append(c)
    labels = image_labels(a.image)
    xk = None
    if a.xref:
        xrom = open(os.path.join(ROOT, IMAGES[a.xref]["rom"]), "rb").read()
        xrows = line_map(a.xref, [a.file])[a.file]
        xsrc = open(os.path.join(ROOT, a.xref, "maincpu", a.file), "rb").read().decode("latin-1").split("\n")
        xkind = {}
        for ln, ad, sz in xrows:
            for x in range(ad, ad + (sz or 0)):
                xkind[x] = src_kind(xsrc[ln - 1])

        def xk(a0, a1):
            """kind of the xref image's source over the first window of this zone
            that is found exactly once in the xref dump."""
            n = a1 - a0
            for w in (16, 12, 8, 6):
                if n < w:
                    continue
                for off in range(0, n - w + 1):
                    pat = rom[a0 - base + off:a0 - base + off + w]
                    i = xrom.find(pat)
                    if i < 0 or xrom.find(pat, i + 1) >= 0:
                        continue
                    xa = i + IMAGES[a.xref]["base"]
                    ks = {xkind.get(xa + k) for k in range(w)}
                    return "code" if ks == {"insn"} else ("data" if "data" in ks else "other")
            return "none"
    zones, report = [], []
    for a0, a1, lab in merged:
        if not any(src_kind(src[ln - 1]) == "data" for ln, ad, sz in rows if a0 <= ad < a1):
            continue        # already instructions (converted since the census ran)
        if a0 not in starts:
            report.append("SKIP 0x%06X %s: run does not start on a source line" % (a0, lab))
            continue
        d = RF.fresh_unidasm(rom, base, a0, a1 + 32)
        x, end = a0, None
        while x in d and x < a1 + 32:
            if x >= a1 and x in starts and src_kind(src[starts[x] - 1]) in ("insn",):
                end = x
                break
            n, _ = d[x]
            if n == 0:
                break
            x += n
        if end is None:
            report.append("SKIP 0x%06X %s: no common boundary within 32 B after the run" % (a0, lab))
            continue
        l0 = starts[a0]
        l1 = starts[end] - 1
        # evidence
        calls = 0
        x = a0
        while x < end:
            n, t = d[x]
            m = re.match(r'^(call|calr|jp|jr|jrl)\s+(?:[A-Z/]+,)?0x([0-9a-f]+)$', t.strip())
            if m and int(m.group(2), 16) in labels and m.group(1) in ("call", "calr", "jp"):
                calls += 1
            x += n
        d1 = RF.fresh_unidasm(rom, base, a0 + 1, min(end, a0 + 24))
        plus1_bad = any(RF.SUSPECT_NEW.search(t.lower()) for n, t in d1.values() if n)
        zones.append((l0, l1, a0, end, lab, calls, plus1_bad, xk(a0, end) if xk else "-"))
    zones.sort()
    dz = []
    for z in zones:
        if dz and z[0] <= dz[-1][1]:
            report.append("SKIP 0x%06X %s: overlaps the previous zone" % (z[2], z[4]))
            continue
        dz.append(z)
    zones = dz
    for z in report:
        print(z)
    edits = RF.reframe(a.image, a.file, [(z[0], z[1]) for z in zones], None, rom, rows, src,
                       True, True)
    ok = []
    ev = {(z[0], z[1]): z for z in zones}
    for e in edits:
        l0, l1, out, a0, a1, n_insn, n_byte, dropped = e
        z = ev[(l0, l1)]
        frac_ok = n_byte * 8 <= max(n_insn + n_byte, 1)
        verdict = "ACCEPT" if frac_ok else "REFUSE(.byte share)"
        if frac_ok and a.require_xref_code and z[7] != "code":
            frac_ok = False
            verdict = "REFUSE(xref=%s)" % z[7]
        print("%s 0x%06X-0x%06X %5d B %-40s insns=%d .byte=%d known-call-targets=%d start+1-absurd=%s xref=%s%s" % (
            verdict, a0, a1, a1 - a0, (z[4] or "-")[:40], n_insn, n_byte, z[5], z[6], z[7],
            ("  dropped: " + ",".join(d[0] for d in dropped)) if dropped else ""))
        if frac_ok:
            ok.append(e)
            if not a.quiet:
                for o in out:
                    print("   + " + o)
    for ad, lt, ut in RF.DISAGREE:
        print("DISAGREE 0x%06X llvm=%r unidasm=%r -> .byte" % (ad, lt, ut))
    print("TOTAL accepted %d zones, %d B" % (len(ok), sum(e[4] - e[3] for e in ok)))
    if a.apply and ok:
        for l0, l1, out, *_ in sorted(ok, key=lambda e: -e[0]):
            src[l0 - 1:l1] = out
        open(path, "wb").write("\n".join(src).encode("latin-1"))
        print("written", path)


if __name__ == "__main__":
    main()
