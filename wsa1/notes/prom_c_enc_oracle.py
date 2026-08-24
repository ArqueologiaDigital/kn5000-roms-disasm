#!/usr/bin/env python3
"""What llvm-mc source line assembles to THESE bytes?  Answered from the sibling's own source.

WHY. Converting prom_c code to assembly needs the exact spelling llvm-mc's TLCS-900
assembler wants, and that spelling is not guessable: the backend represents complex
addressing modes as literal operand bytes (`stl_dri XIZ, 0x07, 0xE0, 0xE4`), and its
DISASSEMBLER is not a usable inverse -- it decodes `link XIZ,0xffff` as `incf` + `swi 7`.

So the oracle is built from ../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s,
40,101 instructions of already-byte-verified assembly for the SAME cpu emitted by the SAME
compiler.  Assembling it with `--show-encoding` gives (source line -> bytes) for every one
of them; this script inverts that map.

  --build                      (re)build the index from the sibling source (a ~1.5 MB
                               JSON cache; it is NOT kept in the tree, any query
                               rebuilds it automatically in a few seconds)
  --exact  "39 28 ee 0c fe ff" every sibling line whose encoding starts here, longest first
  --first  0xBE                every distinct mnemonic whose encoding starts with that byte
  --like   "st_dd8w"           every distinct encoding shape for a mnemonic

The unidasm output (scripts/analysis/dis.sh) supplies the SEMANTICS; this supplies the
SPELLING.  Confirm every result by round-tripping the real bytes -- the byte gate is the
only thing that certifies anything here.
"""
import collections
import json
import os
import re
import subprocess
import sys

SP = os.path.dirname(os.path.abspath(__file__))
IDX = os.path.join(SP, "prom_c_enc_index.json")
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
SRC = os.path.join(SIB, "v142/subcpu/kn5000_subprogram_v142.s")


def build():
    out = subprocess.run([MC, "-triple=tlcs900", "--show-encoding",
                          "-I", os.path.join(SIB, "v142/subcpu"), SRC],
                         capture_output=True, text=True, cwd=SIB).stdout
    rows = []
    pat = re.compile(r"^\s*(\S+)\s*(.*?)\s*; encoding: \[(.*)\]\s*$")
    for ln in out.splitlines():
        m = pat.match(ln)
        if not m:
            continue
        mn, ops, enc = m.group(1), m.group(2), m.group(3)
        try:
            b = [int(x, 16) for x in enc.replace("0x", "").split(",") if x.strip()]
        except ValueError:
            continue
        rows.append([mn, ops, b])
    json.dump(rows, open(IDX, "w"))
    print(f"  indexed {len(rows):,} instructions from {os.path.relpath(SRC, SIB)}")


def load():
    if not os.path.exists(IDX):
        build()
    return json.load(open(IDX))


def main():
    a = sys.argv[1:]
    if not a or "--build" in a:
        build()
        if not a:
            return
    rows = load()
    if "--exact" in a:
        want = [int(x, 16) for x in a[a.index("--exact") + 1].replace("0x", "").split()]
        hits = []
        for mn, ops, b in rows:
            n = min(len(b), len(want))
            if b[:n] == want[:n] and n >= 1:
                hits.append((n, mn, ops, b))
        hits.sort(key=lambda h: -h[0])
        seen = set()
        for n, mn, ops, b in hits[:400]:
            k = (mn, len(b), tuple(b[:1]))
            if k in seen:
                continue
            seen.add(k)
            print(f"  match {n} B   {mn:14s} {ops:34s} [{' '.join(f'{x:02x}' for x in b)}]")
    elif "--first" in a:
        f = int(a[a.index("--first") + 1], 16)
        c = collections.defaultdict(list)
        for mn, ops, b in rows:
            if b and b[0] == f:
                c[mn].append((ops, b))
        for mn in sorted(c):
            ops, b = c[mn][0]
            print(f"  {mn:16s} x{len(c[mn]):<5d} e.g. {ops:38s} [{' '.join(f'{x:02x}' for x in b)}]")
    elif "--like" in a:
        want = a[a.index("--like") + 1]
        c = collections.OrderedDict()
        for mn, ops, b in rows:
            if mn == want:
                k = len(b)
                c.setdefault(k, (ops, b))
        for k, (ops, b) in sorted(c.items()):
            print(f"  {want:16s} {ops:38s} [{' '.join(f'{x:02x}' for x in b)}]")
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
