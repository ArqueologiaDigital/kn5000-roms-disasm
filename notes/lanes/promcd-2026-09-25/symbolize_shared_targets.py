#!/usr/bin/env python3
r"""Make prom_c's numeric branches INTO the shared kernel/dsp sources symbolic.

QUESTION THIS ANSWERS
    scripts/converters/symbolize_numeric_branches.py refuses every branch whose
    target line is in wsa1/kernel/ or wsa1/dsp/ (files prom_a and prom_c both
    include), because a NEW label there would be defined in two images.  But
    when a label ALREADY sits at the target, reusing it is exact: the shared
    file assembles into each image at that image's addresses, so `call
    Kernel_ExitTask` in a prom_c-only file resolves to prom_c's copy.  This
    script converts exactly those sites -- source in a prom_c-only file, target
    carrying an existing label in the shared file -- and leaves the rest.

    Input: the --report JSON of symbolize_numeric_branches.py for prom_c
    (its `shared-file` list: src file:line, target address).  Each target's
    label is looked up by the `F85xxx/F98xxx` address pair the shared sources
    print on every line, and every edited line must still contain the numeric
    spelling it is replacing, or the script stops.

RUN
    python3 scripts/converters/symbolize_numeric_branches.py --image prom_c --report R.json
    python3 notes/lanes/promcd-2026-09-25/symbolize_shared_targets.py R.json [--apply]
    then `make gate-wsa1`.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
SHARED = [os.path.join(W, "kernel", "kernel.s"), os.path.join(W, "dsp", "dsp_channel_regs.s")]
LABEL = re.compile(r"^([A-Za-z_][\w.$]*):")


def label_at(addr):
    tag = "/%06X " % addr
    for path in SHARED:
        L = open(path, encoding="latin-1").read().split("\n")
        for i, ln in enumerate(L):
            if tag in ln:
                j = i - 1
                labs = []
                while j >= 0 and (LABEL.match(L[j]) or not L[j].strip()):
                    m = LABEL.match(L[j])
                    if m and "__" not in m.group(1):
                        labs.append(m.group(1))
                    j -= 1
                return labs[0] if labs else None
    return None


def main():
    rep = json.load(open(sys.argv[1]))["report"]["shared-file"]
    edits = {}
    for x in rep:
        rel, li = x["src"].rsplit(":", 1)
        tgt = int(x["target"], 16)
        lab = label_at(tgt)
        if not lab:
            print("  no label at 0x%06X -- left numeric" % tgt)
            continue
        edits.setdefault(os.path.join(W, rel), []).append((int(li) - 1, tgt, lab))
    n = 0
    for path, es in edits.items():
        L = open(path, "rb").read().decode("latin-1").split("\n")
        for li, tgt, lab in es:
            ln = L[li]
            pat = re.compile(r"\(0x%06X\s*-\s*0x[0-9A-F]{6}\)|0x%06X\b" % (tgt, tgt), re.I)
            assert len(pat.findall(ln.split(";")[0])) == 1, (path, li + 1, ln)
            code, sep, com = ln.partition(";")
            L[li] = pat.sub(lab, code, count=1) + sep + com
            print("  %s:%d  %s" % (os.path.relpath(path, ROOT), li + 1, L[li].strip()[:90]))
            n += 1
        if "--apply" in sys.argv:
            data = "\n".join(L).encode("latin-1")
            open(path, "wb").write(data)
    print("%d sites %s" % (n, "rewritten" if "--apply" in sys.argv else "would be rewritten"))


if __name__ == "__main__":
    main()
