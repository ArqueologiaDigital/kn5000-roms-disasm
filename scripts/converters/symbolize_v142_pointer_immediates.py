#!/usr/bin/env python3
r"""symbolize_v142_pointer_immediates.py -- `ld xNN, <number>` immediates in the sub-CPU v1.42 code
that are proven table addresses become `ld xNN, <Label>`.

QUESTION THIS ANSWERS
    Some code loads a table's address as a plain 32-bit immediate (`ld xbc, 0x12226` then
    `add xbc,xwa / ld a,(xbc)`) instead of `lda xbc,(T:24)`.  An immediate can be a constant
    (the lane brief warns the payload's address range overlaps small constants -- e.g.
    `ld xbc, 0x35d54` before a divide is 220500 = 5 x 44100, a number, not an address), so
    only immediates PROVEN to be used as addresses are rewritten:
      * the value is exactly a label's address in a fresh, byte-identity-checked link, and
      * within the next three instructions the register is dereferenced as a base:
        `add R,..` followed by an access through `(R)`, `ld_rrw ..,R,..` (indexed load), or it
        is the source of an `ldirw`/`ldir` block copy.
    The byte gate then proves each rewrite.

RUN
    python3 scripts/converters/symbolize_v142_pointer_immediates.py            # dry: list
    python3 scripts/converters/symbolize_v142_pointer_immediates.py --apply    # then make gate
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
FILES = ["kn5000_subprogram_v142.s", "subcpu_fp_math.s", "subcpu_data_tables.s"]
IMM = re.compile(r"^(\s*ld\s+)(x[a-z]{2})(\s*,\s*)(0x[0-9a-fA-F]+|\d+)(\s*)$", re.I)


def labels():
    d = tempfile.mkdtemp(prefix="v142ptr_")
    o, e, b = (os.path.join(d, x) for x in ("m.o", "m.elf", "m.bin"))
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", TREE, "-o", o,
                    os.path.join(TREE, "kn5000_subprogram_v142.s")], check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(TREE, "subcpu.ld"), "-o", e, o],
                   check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    if full[:256] + full[60416:] != open(os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom"), "rb").read():
        sys.exit("fresh link not byte-identical -- refusing")
    at = {}
    for ln in subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith((".L", "__")):
            at.setdefault(int(p[0], 16), []).append(p[2])
    return at


def used_as_base(reg, following):
    r = reg.lower()
    for k, c in enumerate(following):
        c = c.lower()
        if re.search(r"ldirw?\b|ldir\b", c) and r == "xiy":
            return True
        if re.search(r"ld_rrw\s+\w+\s*,\s*%s\b" % r, c):
            return True
        if re.match(r"^\s*add\s+%s\s*," % r, c):
            return any(re.search(r"\(%s\)" % r, x.lower()) for x in following[k + 1:k + 2])
    return False


def main():
    apply = "--apply" in sys.argv
    at = labels()
    n = 0
    for f in FILES:
        p = os.path.join(TREE, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")
            m = IMM.match(code)
            if not m:
                continue
            v = int(m.group(4), 0)
            if v not in at or len(at[v]) != 1:
                continue
            nxt = [x.split(";")[0] for x in L[i + 1:i + 5] if x.split(";")[0].strip()][:3]
            if not used_as_base(m.group(2), nxt):
                print("  keep %s:%d %s (not dereferenced as a base)" % (f, i + 1, code.strip()))
                continue
            L[i] = m.group(1) + m.group(2) + m.group(3) + at[v][0] + m.group(5) + sep + com
            print("  %s:%d %s -> %s" % (f, i + 1, m.group(4), at[v][0]))
            n += 1
        if apply:
            open(p, "wb").write("\n".join(L).encode("latin-1"))
    print("rewritten: %d" % n)


if __name__ == "__main__":
    main()
