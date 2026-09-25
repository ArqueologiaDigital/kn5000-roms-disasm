#!/usr/bin/env python3
r"""Respell string directives that sit inside code as `.byte`, so the re-framing tools can see them.

QUESTION ANSWERED
    A string pass once turned printable runs inside routines into `.ascii`
    lines -- e.g. ui/ui_playback_modes.s `SqMdlyPlyTtl_Dispatch: .ascii ":;<>"`,
    which is `push xde; push xhl; push xix; push xiz` (0x3A-0x3E), or
    `.ascii "^\\[Zh"` = `pop xiz; pop xix; pop xhl; pop xde; jr ...`.  The
    re-framing tools refuse any span holding a string directive (a real string
    is evidence the decoder does not have), so these stay misframed.

    This step rewrites such a line as `.byte` with exactly the ROM bytes it
    emits (aligned_string's 0xFF pad included), but only where the line sits
    in a label region that already holds at least three instruction
    statements; `--list` prints every candidate with its bytes and the
    instruction lines around it so each can be judged.  Follow it with
    scripts/analysis/reframe_code_runs_inside_code.py and READ the result:
    a line that stays `.byte` afterwards was not confirmed as code.

RUN
    python3 scripts/converters/strings_in_code_to_bytes.py --image v10 --list FILES
    python3 scripts/converters/strings_in_code_to_bytes.py --image v10 --apply FILES
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import file_line_addresses as fla  # noqa: E402

STR = re.compile(r'^(\s*(?:[A-Za-z_.$][\w.$]*:\s*)?)(\.ascii|\.asciz|\.string|aligned_string)\s')
LAB = re.compile(r"^([A-Za-z_.$][\w.$]*):")


def is_insn(l):
    t = l.split(";")[0].strip()
    t = LAB.sub("", t).strip() if LAB.match(t) else t
    return bool(t) and not t.startswith((".", "aligned_string", "naka_header", "addr24"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("files", nargs="+")
    a = ap.parse_args()
    for rel in a.files:
        sub = rel.split("/maincpu/", 1)[1]
        lm = fla.build(a.image, sub)
        bl = {e["line"]: e["bytes"] for e in lm}
        path = os.path.join(ROOT, rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        # label regions
        starts = [i for i, l in enumerate(lines) if LAB.match(l) and not l.startswith(("\t", " "))] + [len(lines)]
        region = {}
        for k in range(len(starts) - 1):
            for i in range(starts[k], starts[k + 1]):
                region[i] = (starts[k], starts[k + 1])
        n = 0
        for i, l in enumerate(lines):
            m = STR.match(l)
            if not m or (i + 1) not in bl or i not in region:
                continue
            lo, hi = region[i]
            ins = sum(1 for j in range(lo, hi) if is_insn(lines[j]))
            if ins < 3:
                continue
            data = bytes.fromhex(bl[i + 1])
            if not data:
                continue
            n += 1
            new = m.group(1) + ".byte " + ", ".join("0x%02x" % b for b in data)
            if a.list:
                print("%s:%d  %s  ->  %s" % (sub, i + 1, l.strip(), data.hex(" ")))
            lines[i] = new
        print("%s %s: %d string lines inside code" % (a.image, sub, n))
        if a.apply:
            open(path, "wb").write("\n".join(lines).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
