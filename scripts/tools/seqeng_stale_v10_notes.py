#!/usr/bin/env python3
r"""seqeng_stale_v10_notes.py -- are v7's "v10 does not spell this byte either" notes still true?

QUESTION ANSWERED
-----------------
An earlier lane wrote `; v10 does not spell this byte either` beside `.byte`
lines of v7 smf_event_processor.s.  Lane seqeng then decoded those bytes in
BOTH versions.  For each such note, take the v7 instruction that now holds
the byte, find the same bytes (12..6-byte window, unique) in the v10 dump, and
check whether v10's source spells them as an instruction.  A note whose v10
bytes are now all instruction lines is proven stale.

RUN
    python3 scripts/tools/seqeng_stale_v10_notes.py [--apply]   # --apply deletes proven-stale notes
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
from seqeng_line_map import line_map, strip_comment, ROOT  # noqa: E402

REL = "sequencer/smf_event_processor.s"
NOTE = "; v10 does not spell this byte either"


def kind(t):
    c = strip_comment(t).strip()
    c = re.sub(r'^([A-Za-z_.$][\w.$@]*:\s*)+', '', c)
    return None if not c else ("data" if c.startswith(".") else "insn")


def main():
    apply = "--apply" in sys.argv
    r7 = open(os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    r10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    m7 = {ln: (a, s) for ln, a, s in line_map("v7", [REL])[REL]}
    m10 = line_map("v10", [REL])[REL]
    s7 = open(os.path.join(ROOT, "v7/maincpu", REL), "rb").read().decode("latin-1").split("\n")
    s10 = open(os.path.join(ROOT, "v10/maincpu", REL), "rb").read().decode("latin-1").split("\n")
    k10 = {}
    for ln, a, s in m10:
        for x in range(a, a + (s or 0)):
            k10[x] = kind(s10[ln - 1])
    stale, kept = [], []
    for i, t in enumerate(s7):
        if NOTE not in t:
            continue
        j = i + 1
        while j < len(s7) and (j + 1 not in m7 or not (m7[j + 1][1] or 0)):
            j += 1
        a, sz = m7[j + 1]
        verdict = None
        for w in (12, 10, 8, 6):
            pat = r7[a - 0xE00000 - 2:a - 0xE00000 - 2 + w]
            k = r10.find(pat)
            if k < 0 or r10.find(pat, k + 1) >= 0:
                continue
            xa = k + 0xE00000 + 2
            ks = {k10.get(xa + d) for d in range(sz)}
            verdict = "stale" if ks == {"insn"} else "true"
            break
        (stale if verdict == "stale" else kept).append(i)
    print("notes: %d; proven stale (v10 spells the same bytes as instructions): %d; kept: %d"
          % (len(stale) + len(kept), len(stale), len(kept)))
    if apply and stale:
        out = []
        for i, t in enumerate(s7):
            if i in set(stale):
                if t.strip() == NOTE:
                    continue                     # full-line note: drop
                t = t.replace("\t" + NOTE, "")   # trailing note: strip
            out.append(t)
        open(os.path.join(ROOT, "v7/maincpu", REL), "wb").write("\n".join(out).encode("latin-1"))
        print("written")


if __name__ == "__main__":
    main()
