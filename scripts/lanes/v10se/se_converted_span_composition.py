#!/usr/bin/env python3
r"""WHAT WERE THE CONVERTED BYTES SPELLED AS BEFORE THIS LANE TOUCHED THEM?

QUESTION ANSWERED
-----------------
This lane replaced 2,342 bytes of `sound_editor_ui.s` with `.incbin` of
byte-exact C screen descriptors.  "2,342 bytes converted" is only meaningful
with a breakdown of what those bytes USED to be, because the three cases are
worth very different amounts:

  * DISASSEMBLED INSTRUCTIONS -- data-as-code.  The tree asserted these bytes
    were executable code and they never were.  Fixing this is the whole point:
    it is the defect the byte gate is structurally unable to object to.
  * `.byte` runs -- untyped data.  Correct but uninformative; a typed struct is
    strictly better.
  * `.ascii` literals -- already typed.  Absorbing them into the descriptor is
    roughly neutral on its own; they are carried along because they are fields
    INSIDE the record the descriptor types, and the C file keeps them as
    commented label fields.

It walks the address->line map for the PRE-EDIT tree and attributes every byte
of every converted span to the kind of source line that emitted it.

RUN
    python3 scripts/lanes/v10se/se_converted_span_composition.py \
        --amap /tmp/amap.json  --snapshot /tmp/sound_editor_ui.s.before \
        --spans F1115E:206,F11964:471,...
"""
import argparse
import bisect
import json
import os
import re

DIRECTIVE = re.compile(r"^\s*\.(byte|word|hword|long|dword|ascii|asciz|zero|"
                       r"fill|space|incbin)\b")
LABEL_ONLY = re.compile(r"^[A-Za-z_.$][\w.$]*:\s*(;.*)?$")
TARGET = "v10/maincpu/audio/sound_editor_ui.s"


def kind(line):
    m = DIRECTIVE.match(line)
    if m:
        d = m.group(1)
        if d in ("ascii", "asciz"):
            return ".ascii"
        if d == "incbin":
            return ".incbin"
        return "." + d
    s = line.strip()
    if not s or s.startswith(";") or LABEL_ONLY.match(s):
        return None
    return "instruction"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--snapshot", required=True,
                    help="copy of sound_editor_ui.s as it was for that amap")
    ap.add_argument("--spans", required=True,
                    help="comma-separated BASEHEX:SIZE list")
    args = ap.parse_args()

    ent = [e for e in json.load(open(args.amap))]
    addrs = [e["addr"] for e in ent]
    lines = open(args.snapshot, encoding="latin-1").read().split("\n")

    tot = {}
    for spec in args.spans.split(","):
        b, n = spec.split(":")
        base, size = int(b, 16), int(n)
        i = bisect.bisect_right(addrs, base) - 1
        per = {}
        while i < len(ent) and ent[i]["addr"] < base + size:
            a = ent[i]["addr"]
            nxt = ent[i + 1]["addr"] if i + 1 < len(ent) else base + size
            lo, hi = max(a, base), min(nxt, base + size)
            if hi > lo:
                k = kind(lines[ent[i]["line"] - 1]) if ent[i]["src"] == TARGET \
                    else "OTHER FILE"
                if k:
                    per[k] = per.get(k, 0) + (hi - lo)
            i += 1
        print("  %06X +%-4d  %s" % (base, size,
                                    "  ".join("%s=%d" % kv
                                              for kv in sorted(per.items()))))
        for k, v in per.items():
            tot[k] = tot.get(k, 0) + v
    print()
    s = sum(tot.values())
    for k in sorted(tot, key=lambda k: -tot[k]):
        print("  %-14s %6d B  %5.1f%%" % (k, tot[k], 100.0 * tot[k] / s))
    print("  %-14s %6d B" % ("TOTAL", s))


if __name__ == "__main__":
    main()
