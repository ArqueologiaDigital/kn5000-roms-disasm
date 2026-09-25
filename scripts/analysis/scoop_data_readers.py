#!/usr/bin/env python3
r"""scoop_data_readers.py -- who READS each data object of a source file?

QUESTION ANSWERED
-----------------
For every run of data lines (`.ascii/.byte/.short/.long/...`) in one source
file of a maincpu image, which instructions anywhere in the image load its
address -- by any name defined at that address (a label, a positional
`.set NAME, BASE + N`, an absolute `.set NAME, 0x...`) or as a bare number --
and what do the next few instructions do with it?  That is the evidence an
evidence header (census grade KNOWN-A) must cite: the reader by name and
address, the index arithmetic (stride), the bytes copied per record.

The object's own bytes are printed too, so a reader can check the header
against them.

RUN (repo root)
    python3 scripts/analysis/scoop_data_readers.py --image v10 \
        --file v10/maincpu/display/scoop_display.s [--lo 0xEFF000 --hi 0xF00400] [--after 6]
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "converters"))
import scoop_reframe as R  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--lo")
    ap.add_argument("--hi")
    ap.add_argument("--after", type=int, default=6)
    a = ap.parse_args()
    img = a.image
    amap, elf = R.linemap(img, [a.file])
    a2n, n2a = R.symbols(elf)
    addrs = amap[a.file]
    ext = R.line_extents(addrs)
    lines = open(os.path.join(R.ROOT, a.file), encoding="latin-1").read().split("\n")
    lo = int(a.lo, 16) if a.lo else 0
    hi = int(a.hi, 16) if a.hi else 1 << 32
    # data runs
    runs, cur = [], None
    for i, ln in enumerate(lines):
        ad, n = addrs[i], ext[i]
        if ad is None or not n:
            continue
        c = R.strip_comment(ln)[0].strip()
        while R.LABEL_RE.match(c):
            c = c[R.LABEL_RE.match(c).end():].strip()
        isdata = c.startswith(".") and not c.startswith(".set")
        if isdata and lo <= ad < hi:
            if cur and cur[1] == ad:
                cur[1] = ad + n
            else:
                cur = [ad, ad + n, i]
                runs.append(cur)
        else:
            cur = None
    # every source line of the image, for reference search
    names_at = {}
    for nm, ad in n2a.items():
        names_at.setdefault(ad, []).append(nm)
    src = []
    root = os.path.join(R.ROOT, img, "maincpu")
    for dp, _, fn in os.walk(root):
        for f in fn:
            if f.endswith(".s"):
                p = os.path.join(dp, f)
                src.append((os.path.relpath(p, R.ROOT),
                            open(p, encoding="latin-1").read().split("\n")))
    rb = R.rom(img)
    for (s, e, li) in runs:
        cand = {}
        for ad in range(s, e):
            for nm in names_at.get(ad, []):
                if not nm.startswith(("Zsr_", "__drc_")):
                    cand[nm] = ad
        print("=" * 78)
        print("DATA 0x%06X-0x%06X (%d B) at %s:%d  names: %s" % (
            s, e, e - s, a.file, li + 1,
            ", ".join("%s@+%d" % (n, ad - s) for n, ad in sorted(cand.items(), key=lambda x: x[1]))))
        blob = rb[s - R.BASE:e - R.BASE]
        print("   bytes: %s%s" % (blob[:48].hex(" "), " ..." if len(blob) > 48 else ""))
        print("   text : %r" % blob[:64])
        if not cand:
            continue
        pat = re.compile(r'\b(' + "|".join(re.escape(n) for n in sorted(cand, key=len, reverse=True)) + r')\b')
        for rel, L in src:
            for i, ln in enumerate(L):
                code = R.strip_comment(ln)[0]
                if not pat.search(code):
                    continue
                cs = code.strip()
                if R.LABEL_RE.match(cs) and not cs.split(":", 1)[1].strip():
                    continue
                if cs.startswith(".set"):
                    continue
                ctx = [R.strip_comment(x)[0].strip() for x in L[i:i + a.after]]
                print("   <- %s:%d  %s" % (rel, i + 1, " / ".join(x for x in ctx if x)))


if __name__ == "__main__":
    main()
