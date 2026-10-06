#!/usr/bin/env python3
"""compact_label_incbin.py -- put `Label:` and its single `.incbin` on one line, and align the block (KN5000 trees).

QUESTION IT ANSWERS / WHAT IT DOES
  CLAUDE.md's Label+Include Compaction policy (STRICT): "When a label's only content is a single `.include` or
  `.incbin` directive, the label and directive MUST be on the same line.  Consecutive such entries MUST have no
  blank lines between them and MUST be tab-aligned to a common column", the next tab stop after the longest label
  of the block.  On 2026-10-06 about 3,900 labels per maincpu tree still had the label on one line and the
  `.incbin` on the next.  One effect is that data_range_census.py's compact-block rule did not reach them, e.g.
  the 478 widget records under the [nakarest] header of NAKA_PerfReg_Container_Root.
  This script:
    1. joins `Label:` + `\\t.incbin ...` when that `.incbin` is the label's only statement.  The line after it
       must be blank, a comment, another label or the end of the file.  A label line that carries its own
       comment is left alone and counted;
    2. drops a blank line that sits between two such one-line entries;
    3. re-aligns every block (maximal run of consecutive one-line `Label: .incbin` entries) that step 1 or 2
       touched: `Label:` + tabs to the block's column + the directive.  Tabs are 8 columns wide.  Untouched
       blocks keep their spacing.
  Bytes cannot change (same statements, same order).  Comments are kept verbatim.

RUN (repository root)
  python3 scripts/tools/compact_label_incbin.py [--apply] [tree ...]     # default trees: v10 v9 v7
  then: make all; make gate-all
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
TREES = [a for a in sys.argv[1:] if not a.startswith("--")] or ["v10", "v9", "v7"]
LABEL_ONLY = re.compile(r'^([A-Za-z_.$][\w.$@]*):\s*$')
LABEL_WITH_COMMENT = re.compile(r'^([A-Za-z_.$][\w.$@]*):\s*;')
INCBIN = re.compile(r'^\s+(\.incbin\s.*)$')
ENTRY = re.compile(r'^([A-Za-z_.$][\w.$@]*):[ \t]+(\.incbin\s.*)$')


def ends_label(line):
    """True when the line after an .incbin closes the label's content."""
    s = line.strip()
    return s == "" or s.startswith(";") or bool(re.match(r'^[A-Za-z_.$][\w.$@]*:', s))


def process(L):
    joined = skipped = dropped = 0
    out, flag = [], []                             # lines, and whether this pass touched each one
    i = 0
    while i < len(L):
        m = LABEL_ONLY.match(L[i])
        if m and i + 1 < len(L) and INCBIN.match(L[i + 1]) and (i + 2 >= len(L) or ends_label(L[i + 2])):
            out.append("%s:\t%s" % (m.group(1), INCBIN.match(L[i + 1]).group(1).rstrip()))
            flag.append(True)
            joined += 1
            i += 2
            continue
        if LABEL_WITH_COMMENT.match(L[i]) and i + 1 < len(L) and INCBIN.match(L[i + 1]):
            skipped += 1
        out.append(L[i])
        flag.append(False)
        i += 1
    # drop a blank line between two one-line entries
    res, rflag = [], []
    for k, x in enumerate(out):
        if x.strip() == "" and res and ENTRY.match(res[-1]) and k + 1 < len(out) and ENTRY.match(out[k + 1]):
            dropped += 1
            rflag[-1] = True
            continue
        res.append(x)
        rflag.append(flag[k])
    # re-align touched blocks
    k = 0
    while k < len(res):
        if not ENTRY.match(res[k]):
            k += 1
            continue
        j = k
        while j < len(res) and ENTRY.match(res[j]):
            j += 1
        if any(rflag[k:j]):
            width = max(len(ENTRY.match(res[t]).group(1)) + 1 for t in range(k, j))
            col = (width // 8 + 1) * 8
            for t in range(k, j):
                lab, rest = ENTRY.match(res[t]).groups()
                pos = len(lab) + 1
                res[t] = lab + ":" + "\t" * (col // 8 - pos // 8) + rest
        k = j
    return res, joined, skipped, dropped


def main():
    for tree in TREES:
        tj = ts = td = nf = 0
        for p in sorted(glob.glob(os.path.join(REPO, tree, "**", "*.s"), recursive=True)):
            raw = open(p, "rb").read().decode("latin-1")
            L = raw.split("\n")
            res, j, s, d = process(L)
            tj, ts, td = tj + j, ts + s, td + d
            new = "\n".join(res)
            if new != raw:
                nf += 1
                if APPLY:
                    data = new.encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)
        print("%s: %d labels joined to their .incbin, %d blank lines dropped, %d files; %d label lines with a "
              "comment left split" % (tree, tj, td, nf, ts))


if __name__ == "__main__":
    main()
