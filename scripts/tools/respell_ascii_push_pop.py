#!/usr/bin/env python3
"""Respell register push/pop runs that the source holds as `.ascii` text back into instructions.

QUESTION IT ANSWERS / WHAT IT DOES
  Bytes 0x38-0x3F are `push xwa`..`push xsp`, 0x58-0x5F `pop xwa`..`pop xsp`, 0x28-0x2F / 0x48-0x4F the 1-byte
  `pushw` / `popw`; as text they read "89:;<=>?", "XYZ[\\]^_", "()*+,-./", "HIJKLMNO".  An earlier string pass
  turned register save/restore runs inside code into `.ascii` lines (e.g. `.ascii ":;<>"` = push xde/xhl/xix/xiz
  right after a `jp t, (xix+de)`).  This script finds every tracked `.s` line `[Label:] .ascii "..."` whose bytes
  are all such opcodes AND whose next instruction-or-directive line is an instruction, and rewrites it as one
  instruction per byte (the label, if any, kept on its own line).  `--list` prints the candidates only.
  Lines listed in KEEP are real text and are never touched.

RUN (repository root)
  python3 scripts/tools/respell_ascii_push_pop.py --list
  python3 scripts/tools/respell_ascii_push_pop.py            # rewrite; then `make all` must stay byte-identical
"""
import os
import re
import subprocess
import sys

REGS = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
REG16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
OP = {}
for k in range(8):
    OP[0x38 + k] = "push\t" + REGS[k]
    OP[0x58 + k] = "pop\t" + REGS[k]
    OP[0x28 + k] = "pushw\t" + REG16[k]
    OP[0x48 + k] = "popw\t" + REG16[k]
KEEP = {"SoundBank_CopyCh_FromDefault_Data"}     # the default sound-bank name's six underscores: text
INSN = re.compile(r'^(ld|lda|ldw|call|calr|jp|jr|jrl|ret|retd|reti|pop|push|popw|pushw|cp|add|sub|inc|dec|and|or|'
                  r'xor|ex|bit|set|res|link|unlk|extz|exts|swi|ei|di|nop)\b', re.I)
ASCII = re.compile(r'^\s*(?:([A-Za-z_.$][\w.$@]*):)?\s*\.ascii\s+"((?:[^"\\]|\\.)*)"\s*(;.*)?$')


def code(line):
    c = line.split(";")[0].strip()
    return re.sub(r'^[A-Za-z_.$][\w.$@]*:\s*', '', c)


def main():
    listing = "--list" in sys.argv
    files = subprocess.run(["git", "ls-files", "*.s"], capture_output=True, text=True).stdout.split()
    total = 0
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        out, changed = [], 0
        for i, line in enumerate(L):
            m = ASCII.match(line)
            if m and m.group(1) not in KEEP:
                raw = m.group(2).encode("latin-1").decode("unicode_escape").encode("latin-1")
                nxt = next((code(L[k]) for k in range(i + 1, min(len(L), i + 8)) if code(L[k])), "")
                if raw and all(b in OP for b in raw) and INSN.match(nxt):
                    total += 1
                    if listing:
                        print("%s:%d %s" % (f, i + 1, line.strip()))
                    else:
                        changed += 1
                        if m.group(1):
                            out.append(m.group(1) + ":")
                        note = "\t; was .ascii \"%s\"" % m.group(2)
                        for n_, b in enumerate(raw):
                            out.append("\t" + OP[b] + (note if n_ == 0 else ""))
                        continue
            out.append(line)
        if changed:
            data = "\n".join(out).encode("latin-1")
            open(f + ".tmp", "wb").write(data)
            os.replace(f + ".tmp", f)
    print("%d line(s) %s" % (total, "found" if listing else "respelled"), file=sys.stderr)


if __name__ == "__main__":
    main()
