#!/usr/bin/env python3
r"""scoop_label_numeric_targets.py -- give a label to every address inside lane
scoop's own files that an instruction still loads as a NUMBER, so the operand
can be made symbolic (scoop_symbolize_imm.py) and the reader becomes visible
to by-name searches.

QUESTION ANSWERED
-----------------
"Which numeric ROM operands point INTO display/*.s where no label stands,
and who loads them?"  For each, emits an annotate spec entry: a label named
after the loading routine (`<Routine>_Data`, numbered if the routine loads
several) and a two-line comment quoting the loading instruction.  Targets in
other lanes' files are listed only.

RUN
    python3 scripts/converters/scoop_label_numeric_targets.py --image v10 --out S.json
    python3 scripts/converters/scoop_annotate.py --image v10 --spec S.json
    python3 scripts/converters/scoop_symbolize_imm.py --image v10
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "analysis"))
import scoop_data_headers as H  # noqa: E402

FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
NUM = re.compile(r'(?<![\w:$.])(0x[0-9a-fA-F]{6,8}|\d{8})(?![\w:])')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    img = a.image
    rels = ["%s/maincpu/%s" % (img, f) for f in FILES]
    amap, elf = R.linemap(img, rels)
    a2n, n2a = R.symbols(elf)
    span = {}
    for rel in rels:
        addrs = amap[rel]
        ext = R.line_extents(addrs)
        for i, x in enumerate(addrs):
            if x is not None and ext[i]:
                for k in range(x, x + ext[i]):
                    span.setdefault(k, rel)
    spec, used, other = [], {}, []
    for rel in rels:
        L = open(os.path.join(R.ROOT, rel), encoding="latin-1").read().split("\n")
        for i, ln in enumerate(L):
            code = R.strip_comment(ln)[0]
            c = code.strip()
            while R.LABEL_RE.match(c):
                c = c[R.LABEL_RE.match(c).end():].strip()
            if not c or c.startswith("."):
                continue
            for m in NUM.finditer(code):
                v = int(m.group(1), 0)
                if not (0xE00000 <= v <= 0xFFFFFF) or \
                        [x for x in a2n.get(v, []) if not x.startswith(("Zsr_", "__drc_"))]:
                    continue
                if v not in span:
                    other.append("%s:%d %s" % (rel, i + 1, c))
                    continue
                if any(e["addr"] == "0x%06X" % v for e in spec):
                    continue
                rn, ra = H.routine_of(L, i, n2a)
                is_call = c.split()[0].lower() in ("call", "calr", "jp", "jr", "jrl")
                base = (rn or "Unnamed") + ("_Helper" if is_call else "_Data")
                used[base] = used.get(base, 0) + 1
                nm = base if used[base] == 1 else "%s%d" % (base, used[base])
                spec.append({"file": span[v], "addr": "0x%06X" % v, "label": nm,
                             "comment": [("Called as a number by %s%s:" if is_call else "Loaded as a number by %s%s:") % (
                                 rn, " (0x%06X)" % ra if ra else ""),
                                 "`%s` (%s:%d)." % (re.sub(r'\s+', ' ', c), rel.split("/")[-1], i + 1)]})
    json.dump(spec, open(a.out, "w"), indent=1)
    print("%d in-file targets labelled -> %s; %d numeric operands point outside these files"
          % (len(spec), a.out, len(other)))
    for x in other:
        print("   outside:", x)


if __name__ == "__main__":
    main()
