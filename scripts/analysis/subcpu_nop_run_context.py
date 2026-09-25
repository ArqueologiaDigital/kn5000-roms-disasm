#!/usr/bin/env python3
r"""subcpu_nop_run_context.py -- are the sub-CPU's `nop`-`nop` "data-as-code markers" really data?

QUESTION THIS ANSWERS
    The 2026-09-25 lane census (lane_worklists.py / lane_subcpu_measure.py) counts every `nop`
    that follows a `nop` as a data-as-code marker.  In v142/subcpu/kn5000_subprogram_v142.s and
    subcpu/boot/kn5000_subcpu_boot.s those markers are the bulk of the count.  Are they
    mis-framed data, or deliberate delays in real code?

    For every run of >= 2 consecutive `nop` instructions it looks at the three instructions
    before the run and classifies it:
      * "after HW register/port write" -- one of them writes/accesses the tone-generator latch
        (0x100000/0x100002, spelled hex or decimal), the 0x110000 keybed/TG status window, the
        0x130000 DSP window, or toggles a port bit (`set_dd8` / `res_dd8`, or SFR 0x34 / 0x3C);
      * "after jr-to-next delay" -- the instruction before is a `jr` to the next instruction;
      * "other".
    A marker count dominated by the first class means the nops are settling delays between
    hardware accesses (the source already labels many of them *_NopGap / *_NopCont), not data.

RUN
    python3 scripts/analysis/subcpu_nop_run_context.py
"""
import collections
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["v142/subcpu/kn5000_subprogram_v142.s", "subcpu/boot/kn5000_subcpu_boot.s"]
HW = re.compile(r"\(0x1[013]000[02]|\(1048576|\(1048578|\(1114112|\(1114114|_dd8|0x130|\(0x3c|\(0x34", re.I)


def main():
    for f in FILES:
        L = open(os.path.join(ROOT, f), "rb").read().decode("latin-1").split("\n")
        code = [(i, re.sub(r"^[\w.$]+:\s*", "", ln.split(";")[0].strip()).lower()) for i, ln in enumerate(L)]
        code = [(i, c) for i, c in code if c and not c.startswith(".")]
        runs, k = [], 0
        while k < len(code):
            if code[k][1] == "nop":
                j = k
                while j < len(code) and code[j][1] == "nop":
                    j += 1
                if j - k >= 2:
                    runs.append((k, j))
                k = j
            else:
                k += 1
        ctx = collections.Counter()
        for a, b in runs:
            back = " | ".join(c for _, c in code[max(0, a - 3):a])
            prev = code[a - 1][1] if a else ""
            if HW.search(back):
                ctx["after HW register/port write"] += 1
            elif prev.startswith("jr"):
                ctx["after jr-to-next delay"] += 1
            else:
                ctx["other"] += 1
        print("%-40s nop runs %3d, nop-nop markers %3d, %s" % (f, len(runs), sum(b - a - 1 for a, b in runs), dict(ctx)))


if __name__ == "__main__":
    main()
