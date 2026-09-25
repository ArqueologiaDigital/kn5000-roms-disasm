#!/usr/bin/env python3
r"""scoop_symbolize_imm.py -- replace numeric ROM addresses in INSTRUCTION
operands of lane scoop's files by the label that stands at that address.

QUESTION ANSWERED
-----------------
"Which instruction operands in display/*.s still spell a ROM address as a
number (`ld xix, 15688317`, `call 16692690`, `ld xde, 0xef7769`) although a
label sits exactly at that address?"  Those are cross-references the policy
wants symbolic, and they also hide READERS from every by-name search (the v7
tables looked unread for exactly this reason).

Only instruction lines are touched -- never `.long`/`.byte` data (a misaligned
data word can equal a label address by accident) and never macro arguments.
A value is replaced only when an ELF symbol of the image sits exactly at it;
a descriptive label is preferred to a positional `.set NAME, BASE + N` one.
Numbers with no label at their address are listed, not guessed.  The image
is rebuilt and compared with the dump; files are restored if a byte moves.

RUN
    python3 scripts/converters/scoop_symbolize_imm.py --image v7 [--dry-run]
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scoop_reframe as R  # noqa: E402

FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
NUM = re.compile(r'(?<![\w:$.])(0x[0-9a-fA-F]{6,8}|\d{8})(?![\w:])')
POS = re.compile(r'_0x[0-9A-Fa-f]+$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    img = a.image
    ok, elf, _ = R.build(img)
    a2n, _ = R.symbols(elf)
    macros = set()
    for dp, _, fn in os.walk(os.path.join(R.ROOT, img, "maincpu")):
        for f in fn:
            if f.endswith((".s", ".inc")):
                for ln in open(os.path.join(dp, f), encoding="latin-1"):
                    m = re.match(r'\s*\.macro\s+([\w.$]+)', ln)
                    if m:
                        macros.add(m.group(1).lower())
    backup, done, left = {}, 0, []
    for rel in FILES:
        p = os.path.join(R.ROOT, img, "maincpu", rel)
        raw = open(p, "rb").read()
        backup[p] = raw
        lines = raw.decode("latin-1").split("\n")
        for i, ln in enumerate(lines):
            code, com = R.strip_comment(ln)
            c = code.strip()
            while R.LABEL_RE.match(c):
                c = c[R.LABEL_RE.match(c).end():].strip()
            if not c or c.startswith(".") or c.split()[0].lower() in macros:
                continue

            def sub(m):
                v = int(m.group(1), 0)
                if not (0xE00000 <= v <= 0xFFFFFF):
                    return m.group(0)
                names = [x for x in a2n.get(v, []) if not x.startswith(("Zsr_", "__drc_", ".L"))]
                if not names:
                    left.append("%s:%d %s" % (rel, i + 1, c))
                    return m.group(0)
                names.sort(key=lambda x: (bool(POS.search(x)), len(x)))
                return names[0]
            new = NUM.sub(sub, code)
            if new != code:
                done += 1
                lines[i] = new + com
        if not a.dry_run:
            open(p, "wb").write("\n".join(lines).encode("latin-1"))
    print("%s: %d operands made symbolic; %d numeric ROM operands have no label at their address"
          % (img, done, len(left)))
    for x in left[:40]:
        print("   left:", x)
    if a.dry_run:
        return
    ok, _, data = R.build(img)
    if not ok or data != R.rom(img):
        for p, t in backup.items():
            open(p, "wb").write(t)
        raise SystemExit("REJECTED: restored")
    print("VERIFIED: %s image byte-identical" % img)


if __name__ == "__main__":
    main()
