#!/usr/bin/env python3
"""v7_blocker_delta.py -- what did a toolchain change actually do to v7's
blocked slices?

QUESTION THIS ANSWERS
----------------------
`v7_offset_blockers.py` reports, per NO_OFFSET_FOUND slice, the FIRST form that
resists at the anchor offset. Run it twice around a backend change and the
interesting quantity is the DIFFERENCE. Its own header states the trap in
advance and this script exists to make the trap impossible to fall into
accidentally:

  ⚠ A FORM'S COUNT DROPPING TO ZERO DOES NOT MEAN ITS BYTES ARE CONVERTED.
  It means those slices cleared THAT gate. Each slice's tail is attributed to
  whichever form blocks it first, so fixing the first blocker usually just
  reveals the second one and the TOTAL BLOCKED BYTES DO NOT MOVE AT ALL.

So this prints three things and refuses to print a headline number without them:
the total blocked bytes before and after (which is the honest bottom line), the
bytes that cleared the specific gate you fixed, and the per-slice list of where
each of those slices now stops instead.

⚠ AND `CLEAN` IS NOT `CODE`. A slice reaching CLEAN means its tail round-trips
byte-exactly through llvm-mc. On an opcode space this dense that is close to
free -- see `blind_run_decode_census.py`, where uniform RANDOM bytes round-trip
clean 24% of the time. A CLEAN verdict is a candidate for review, never a
licence to convert.

RUN
    python3 scripts/analysis/v7_blocker_delta.py BEFORE.json [AFTER.json]
    AFTER defaults to scripts/analysis/v7_offset_blockers.json
    The snapshot taken before tlcs900_backend@6f456a19f05b is committed as
    scripts/analysis/v7_offset_blockers.pre-6f456a19f05b.json, so

        python3 scripts/analysis/v7_blocker_delta.py \
            scripts/analysis/v7_offset_blockers.pre-6f456a19f05b.json

    reproduces that commit's reported movement exactly.
"""
import collections
import json
import sys

# The five leading bytes taught to the decoder in tlcs900_backend@6f456a19f05b.
FIXED = {"0x01": "normal", "0x04": "max", "0x17": "ldf",
         "0x1a": "jp nnnn", "0x1c": "call nnnn"}


def load(path):
    return {(s["label"], s["file"], s["incbin_line"]): s
            for s in json.load(open(path))}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    before = load(sys.argv[1])
    after = load(sys.argv[2] if len(sys.argv) > 2
                 else "scripts/analysis/v7_offset_blockers.json")

    tb = sum(s["tail_len"] for s in before.values())
    ta = sum(s["tail_len"] for s in after.values())
    print("slices          before %4d   after %4d" % (len(before), len(after)))
    print("blocked bytes   before %6d   after %6d   delta %+d"
          % (tb, ta, ta - tb))

    def gated(d):
        v = [s for s in d.values() if s["blocker"].get("byte") in FIXED]
        return len(v), sum(s["tail_len"] for s in v)
    nb, bb = gated(before)
    na, ba = gated(after)
    print("gated by the five taught bytes:  before %d slices / %d B   "
          "after %d slices / %d B" % (nb, bb, na, ba))

    moved = [(k, before[k]["form"], after[k]["form"])
             for k in before if k in after
             and before[k]["form"] != after[k]["form"]]
    print("\n%d slice(s) changed blocking form:" % len(moved))
    for k, f0, f1 in sorted(moved, key=lambda x: -before[x[0]]["tail_len"]):
        print("  %-42s %7d B  %-26s -> %s"
              % (k[0], before[k]["tail_len"], f0, f1))

    newly = [k for k in before if k in after
             and before[k]["form"] != "CLEAN" and after[k]["form"] == "CLEAN"]
    print("\nnewly CLEAN: %d slice(s), %d B  (⚠ candidates for review, NOT a "
          "licence to convert)"
          % (len(newly), sum(after[k]["tail_len"] for k in newly)))
    for k in newly:
        print("  %-42s %7d B  %s" % (k[0], after[k]["tail_len"], k[1]))

    print("\ntop blocking forms after:")
    forms = collections.Counter()
    for s in after.values():
        forms[s["form"]] += s["tail_len"]
    fb = collections.Counter()
    for s in before.values():
        fb[s["form"]] += s["tail_len"]
    for f, n in forms.most_common(10):
        print("  %-34s %7d B  (before %7d B)" % (f, n, fb.get(f, 0)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
