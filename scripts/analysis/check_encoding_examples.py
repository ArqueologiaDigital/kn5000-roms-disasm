#!/usr/bin/env python3
"""check_encoding_examples.py -- does every assembler example in CLAUDE.md's
"LLVM TLCS-900 Assembler Encoding Quirks" section assemble, with a given
llvm-mc, to exactly the bytes the text says?

QUESTION
    That section is the guidance future agents follow when they turn bytes into
    instructions.  Commit 828894fa claimed "every example assembled with
    llvm-mc c949d618"; the wave 3a V1 panel found six that the pinned binary
    refused (`ld_srib3`, `lda_dri3`, `cps`, `ldb`, `lds32` -- deleted
    spellings) and a gotcha about one more (`ldada_24`).  This script makes the
    claim checkable instead of asserted: it extracts every pair written as

        `<assembler text>` → `<hex bytes>`

    from the section (the arrow is U+2192), assembles each text alone, and
    compares the encoding byte for byte.  A row whose bytes column says
    "raw bytes" has no pair and is not checked.

RUN (from the tree root)
    python3 scripts/analysis/check_encoding_examples.py
    MC=~/compartilhado/toolchain-snapshot/llvm-mc.snap python3 scripts/analysis/check_encoding_examples.py

Exit 0 = every example matches; 1 = a mismatch or refusal (each is printed).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MC = os.environ.get("MC", os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc"))
PAIR = re.compile(r'`([^`]+)`\s*→\s*`([0-9a-fA-F]{2}(?:\s+[0-9a-fA-F]{2})*)`')


def section(text):
    start = text.index("### LLVM TLCS-900 Assembler Encoding Quirks")
    end = text.find("\n### ", start + 10)
    return text[start:end if end > 0 else len(text)]


def encode(line):
    p = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=line + "\n",
                       capture_output=True, text=True)
    m = re.search(r"encoding: \[([^\]]*)\]", p.stdout)
    if p.returncode != 0 or not m:
        err = [l for l in p.stderr.splitlines() if "error" in l]
        return None, (err[0] if err else p.stderr.strip()[:120])
    return " ".join("%02x" % int(x, 16) for x in m.group(1).split(",") if x.strip()), ""


def main():
    text = open(os.path.join(ROOT, "CLAUDE.md"), encoding="utf-8").read()
    pairs = PAIR.findall(section(text))
    bad = 0
    for asm, want in pairs:
        want = " ".join(want.lower().split())
        got, err = encode(asm)
        ok = got == want
        bad += not ok
        print("%-4s %-36s want %-16s got %s" % ("ok" if ok else "BAD", asm, want,
                                              got if got else "REFUSED: " + err))
    print("llvm-mc: %s" % MC)
    print("%d examples, %d mismatched or refused" % (len(pairs), bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
