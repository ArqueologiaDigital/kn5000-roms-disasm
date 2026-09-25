#!/usr/bin/env python3
r"""scoop_respell_byte_insns.py -- re-spell `.byte ...\t; <reading>` lines
(instructions written as bytes, with unidasm's reading as a comment) when
the backend CAN spell them after all.

QUESTION ANSWERED
-----------------
"Which instruction-as-.byte lines in display/*.s have a backend spelling that
re-assembles to exactly their bytes?"  The backend's disassembler cannot
print some forms its assembler accepts: `srla e` (SRL A,E = cd ff),
`popw (0x0d5c:16)` (F1 form; the plain printout picks the F2 form),
`xorcf a, (0x0dc7:16)`, `add xhl, (0x2a:8)`, `rrc_i_8 a, 3`.  Each candidate
from scoop_reframe.alt_spellings() and the tree's own custom-mnemonic
spellings is assembled; the first whose bytes equal the line's is written,
the unidasm comment kept.  The image is rebuilt and compared.

RUN
    python3 scripts/converters/scoop_respell_byte_insns.py --image v10
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402

FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
LINE = re.compile(r"^(\t)\.byte\t((?:0x[0-9a-f]{2}(?:, )?)+)(\t; (.+?))(\s+\(llvm-mc:.*\))?$")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    a = ap.parse_args()
    img = a.image
    backup, todo = {}, []
    for rel in FILES:
        p = os.path.join(R.ROOT, img, "maincpu", rel)
        raw = open(p, "rb").read()
        backup[p] = raw
        for i, ln in enumerate(raw.decode("latin-1").split("\n")):
            m = LINE.match(ln)
            if m:
                b = bytes(int(x, 16) for x in m.group(2).split(", "))
                todo.append((p, i, b, m.group(4).strip(), ln))
    cands = []
    for (p, i, b, ut, ln) in todo:
        segs = R.decode_each([b])
        lt = segs[0][1] if segs and segs[0][0] == len(b) else None
        for c in R.alt_spellings(ut, lt):
            cands.append(((p, i), c, b))
        if b.hex() in R.known_spellings(img):
            cands.append(((p, i), R.known_spellings(img)[b.hex()], b))
    enc = R.assemble_lines([c for _, c, _ in cands])
    pick = {}
    for (key, c, b), e in zip(cands, enc):
        if e == b and key not in pick:
            pick[key] = c
    files = {}
    for (p, i, b, ut, ln) in todo:
        if (p, i) in pick:
            L = files.setdefault(p, backup[p].decode("latin-1").split("\n"))
            m = LINE.match(ln)
            L[i] = "\t" + pick[(p, i)] + m.group(3) + (m.group(5) or "")
    for p, L in files.items():
        open(p, "wb").write("\n".join(L).encode("latin-1"))
    ok, _, data = R.build(img)
    if not ok or data != R.rom(img):
        for p, t in backup.items():
            open(p, "wb").write(t)
        raise SystemExit("REJECTED: restored")
    print("%s: %d of %d .byte instructions re-spelled; image byte-identical" % (img, len(pick), len(todo)))
    left = sorted({ut for (p, i, b, ut, ln) in todo if (p, i) not in pick})
    print("   still .byte:", left)


if __name__ == "__main__":
    main()
