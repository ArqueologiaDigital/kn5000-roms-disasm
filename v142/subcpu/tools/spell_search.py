#!/usr/bin/env python3
"""spell_search.py -- find an llvm-mc spelling for an instruction the pinned
DISASSEMBLER refuses.

QUESTION ANSWERED: `llvm-mc --disassemble` returns "invalid instruction
encoding" for a handful of byte sequences in the v1.42 payload. Does that mean
the toolchain cannot express them -- or only that its decoder is narrower than
its assembler?

WHY THIS EXISTS. The project's rule about untried spellings has now fired nine
times, and the most recent instance (notes/DEBT-INVENTORY-2026-09-02.md) was
exactly this shape: five bytes recorded as "blocked in the assembler" turned
out to ASSEMBLE fine; only the decoder lacked them. So before any refusal in
this lane says "the toolchain cannot spell this", it is checked here. The
first thing this tool found: `cp (xwa), 0` assembles to 0x80,0x3f,0x00 --
which `--disassemble` will not produce.

METHOD. unidasm (MAME's TLCS-900 core, the framing authority named in
original_ROMs/README-unidasm.md) says what the bytes mean. The candidate
MNEMONIC SET is harvested from the tree's own v142 sources -- every mnemonic
token this codebase already uses -- filtered to those sharing a prefix with
unidasm's. Operands are rendered a few ways (parenthesised or not, hex or
decimal, immediate widened). Every candidate is assembled and accepted ONLY if
its encoding equals the target bytes EXACTLY. There is no fuzzy match and no
"close enough": a spelling either reproduces the bytes or it is discarded.

⚠ The mnemonic set is the tree's, so a form this tree has never used cannot be
found. A negative result here means "no spelling found among the ones this
codebase already uses", never "the assembler cannot do it".

⚠ Decodability and spellability are properties of a SPECIFIC LLVM build. Every
number this tool produces must be quoted with the build it was measured
against; `llvm-mc` moved from 6fe210fb0a81 to 6f456a19f05b mid-push.

RUN (from the lane worktree root):
    python3 v142/subcpu/tools/spell_search.py 80 3f 00
    python3 v142/subcpu/tools/spell_search.py --hint 'cp (XWA),0x00' 80 3f 00
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'encoding: \[([^\]]*)\]')
MNEM = re.compile(r'^\s+([a-z][a-z0-9_]*)\b')


def tree_mnemonics():
    out = set()
    d = os.path.join(ROOT, "v142/subcpu")
    for fn in sorted(os.listdir(d)):
        if fn.endswith(".s"):
            for line in open(os.path.join(d, fn), encoding="latin-1"):
                m = MNEM.match(line)
                if m:
                    out.add(m.group(1))
    return sorted(out)


REGS = ("a", "b", "c", "d", "e", "h", "l", "w", "wa", "bc", "de", "hl",
        "ix", "iy", "iz", "sp", "xwa", "xbc", "xde", "xhl", "xix", "xiy",
        "xiz", "xsp", "qa", "qb", "qc", "qd")


def operand_variants(ops, target):
    """Two families.

    (1) unidasm's own operand text, lightly re-rendered -- enough for the
        ordinary forms (`cp (XWA),0x00` -> `cp (xwa), 0x00`).

    (2) RAW-BYTE TEMPLATES. This tree spells the register-indexed forms with
        the instruction's own encoding bytes as operands
        (`or_sriw_rm hl, 0x07, 0xF0, 0xE8` = d3 07 f0 e8 e3), so no
        re-rendering of `HL,(XIX+DE)` can ever reach them. Those spellings are
        generated directly from the target bytes instead: a register name
        followed by each trailing byte-slice of the encoding.
    """
    ops = ops.strip().lower()
    v = {ops} if ops else set()
    if ops:
        v.add(re.sub(r'\b(0x[0-9a-f]+)\b', r'(\1)', ops, count=1))
        v.add(ops.replace("(", "").replace(")", ""))
        v.add(re.sub(r'0x([0-9a-f]{2})$',
                     lambda m: "0x%04x" % int(m.group(1), 16), ops))
        v.add(re.sub(r'0x([0-9a-f]{4})$',
                     lambda m: "0x%02x" % (int(m.group(1), 16) & 0xFF), ops))
        v.add(ops.replace(",", ", "))
    n = len(target)
    for lo in range(1, n):
        for hi in range(lo + 1, n + 1):
            body = ", ".join("0x%02X" % b for b in target[lo:hi])
            v.add(body)
            for r in REGS:
                v.add("%s, %s" % (r, body))
    return sorted(x for x in v if x)


def search(target, hint):
    parts = hint.split(None, 1)
    stem = parts[0].lower() if parts else ""
    ops = parts[1] if len(parts) > 1 else ""
    cands = [m for m in tree_mnemonics()
             if not stem or m == stem or m.startswith(stem[:2])]
    lines = []
    for m in cands:
        for o in operand_variants(ops, target):
            lines.append("%s %s" % (m, o))
    if not lines:
        return None
    # ⚠ llvm-mc CONTINUES past a bad line and prints encodings only for the
    # good ones, so candidates cannot be matched back by index. The emitted
    # TEXT is used instead -- it is llvm-mc's own canonical rendering of the
    # line it accepted, so it assembles to the encoding printed beside it by
    # construction.
    # ⚠ CHUNK IS SMALL ON PURPOSE. llvm-mc gives up after a fixed number of
    # errors and stops assembling the rest of the input: a 4,000-line batch
    # of mostly-bogus candidates returned 115 encodings and silently dropped
    # the one that matched, at line 2,144. Measured, not assumed.
    CHUNK = 60
    for i in range(0, len(lines), CHUNK):
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input="\n".join(lines[i:i + CHUNK]) + "\n",
                           capture_output=True, text=True)
        for l in r.stdout.split("\n"):
            g = ENC.search(l)
            if not g:
                continue
            enc = bytes(int(x, 16) for x in g.group(1).split(",") if x.strip())
            if enc == target:
                return l.split(";")[0].strip()
    return None


def main():
    argv = sys.argv[1:]
    hint = ""
    if "--hint" in argv:
        i = argv.index("--hint")
        hint = argv[i + 1]
        del argv[i:i + 2]
    if not argv:
        sys.exit(__doc__)
    target = bytes(int(x, 16) for x in argv)
    got = search(target, hint)
    print("%s -> %s" % (" ".join("%02x" % b for b in target), got or "NO SPELLING FOUND"))
    return 0 if got else 1


if __name__ == "__main__":
    sys.exit(main())
