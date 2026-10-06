#!/usr/bin/env python3
"""respell_embedded_code_bytes.py -- `.byte` runs sitting between two instructions -> the instructions they encode.

QUESTION IT ANSWERS
  The KN5000 trees still hold instructions spelled as `.byte` in the middle of routines, from the days when llvm-mc
  could not encode them: `.byte 0x8f, 0x06, 0xf1` is `cp a, (xsp+6)`, `.byte 0x9f, 0x04, 0xf0` is `cp wa, (xsp+4)`.
  scripts/analysis/data_range_census.py flags many of them as code-suspect data (a data region next to a branch
  target).  convert_code_bytes.py can decode and round-trip them, but it picks its blocks by label prefix and file
  name, so it would also rewrite data tables.  This driver uses its decoder (unidasm, then an llvm-mc round trip of
  every instruction) and takes only the unambiguous shape:
    - one or more consecutive `.byte 0x..` lines with no label on them;
    - the previous code line is an instruction that falls through (not ret / reti / retd / an unconditional jp, jr
      or jrl) -- or there is a label between, which makes the run a branch target;
    - the next code line (labels may come between) is an instruction;
    - every byte decodes and round-trips; no decoded instruction is a branch (its target would be numeric) or a
      filler-like opcode (nop, halt, swi, max, min, normal, ldf, incf, decf, ei, di, push/pop sr).
  The decoder's raw-address pseudos are respelled natively when llvm-mc encodes the native form to the same bytes:
  `cpdi8 A, n` -> `cp (A:16), n`, `cpdi16` -> `cpw (A:16), n`, `stdi8` -> `ld (A:16), n`, `ldw_d16 r, A` ->
  `ld r, (A:16)`, `lda_d16 r, A` -> `lda r, (A:16)`, and `lda_24 r, A` -> `lda r, (Label:24)` with the tree's
  symbol file; any other `(0xADDR:24)` ROM operand takes its label the same way.  A memory address the decoder prints in decimal, `(9834:16)`, is written in hex, `(0x266a:16)`, and
  so are the immediate of and / or / xor (a mask) and a 32-bit immediate above 0xFFFF.
  A comment on a `.byte` line is kept on the first instruction; when it begins with the decode itself
  (`; cp (xwa), 0xff -- why`), only the part after ` -- ` stays.  The byte gate is the proof.

RUN (repository root)
  python3 scripts/converters/respell_embedded_code_bytes.py [--apply] [--trees v10,v9,v7]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts/converters"))
from convert_code_bytes import convert_block, verify_roundtrip   # noqa: E402

TREES = {"v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu", "v142": "v142/subcpu",
         "subboot": "subcpu/boot", "hdae5000": "hdae5000", "tabledata": "table_data", "customdata": "custom_data"}
BYTE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{1,2}\s*,\s*)*0x[0-9a-fA-F]{1,2})\s*(;.*)?$')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):\s*(.*)$')
MNEM = re.compile(r'^([a-z][a-z0-9_]*)\b\s*(.*)$')
DATA_MACROS = {"naka_header", "addr24", "aligned_string"}
COND = {"t", "f", "z", "nz", "c", "nc", "eq", "ne", "ult", "uge", "ule", "ugt", "lt", "ge", "le", "gt", "mi", "pl",
        "ov", "nov", "pe", "po"}
FILLER = re.compile(r'^(nop|halt|swi|max|min|normal|ldf|incf|decf|ei|di|push\s+sr|pop\s+sr)\b')
BRANCH = re.compile(r'^(jp|jr|jrl|call|calr|djnz|ret|reti|retd)\b')
ADDR = re.compile(r'\((\d+)(:8|:16|:24)?\)')
MASK = re.compile(r'^((?:and|or|xor)w?\s+.*,\s*)(\d+)$')


SYMS = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt",
        "v7": "symbols/maincpu_v7_symbols_reference.txt"}
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
NUM = r'(0x[0-9a-fA-F]+|\d+)'
PSEUDO = [(re.compile(r'^cpdi8\s+%s,\s*(.+)$' % NUM), "cp\t(0x{a:x}:16), {1}"),
          (re.compile(r'^cpdi16\s+%s,\s*(.+)$' % NUM), "cpw\t(0x{a:x}:16), {1}"),
          (re.compile(r'^stdi8\s+%s,\s*(.+)$' % NUM), "ld\t(0x{a:x}:16), {1}"),
          (re.compile(r'^ldw_d16\s+(\w+),\s*%s$' % NUM), "ld\t{0}, (0x{a:x}:16)"),
          (re.compile(r'^lda_d16\s+(\w+),\s*%s$' % NUM), "lda\t{0}, (0x{a:x}:16)"),
          (re.compile(r'^lda_24\s+(\w+),\s*%s$' % NUM), "lda\t{0}, ({sym}:24)")]
ROM24 = re.compile(r'\((0x[ef][0-9a-f]{5}):24\)')
IMM32 = re.compile(r'^(ld\s+x\w+,\s*)(\d+)$')


def load_syms(tree):
    best = {}
    if tree not in SYMS:
        return best
    for ln in open(os.path.join(ROOT, SYMS[tree]), encoding="latin-1"):
        f = ln.split()
        if len(f) == 2 and not ln.startswith("#"):
            a, n = int(f[1], 16), f[0]
            rank = (n.startswith("."), bool(CONT.search(n)), len(n))
            if a not in best or rank < best[a][0]:
                best[a] = (rank, n)
    return {a: n for a, (r, n) in best.items() if not n.startswith(".")}


def hexify(m):
    """Addresses and masks in hex (the decoder prints them in decimal)."""
    m = ADDR.sub(lambda x: "(0x%x%s)" % (int(x.group(1)), x.group(2) or ""), m)
    m = IMM32.sub(lambda x: x.group(1) + ("0x%x" % int(x.group(2)) if int(x.group(2)) > 0xFFFF else x.group(2)), m)
    return MASK.sub(lambda x: "%s0x%x" % (x.group(1), int(x.group(2))), m)


def nativize(m, expected, syms):
    """The native spelling of a raw-address pseudo, when llvm-mc encodes it to the same bytes."""
    s = " ".join(m.split())
    for rx, fmt in PSEUDO:
        x = rx.match(s)
        if not x:
            continue
        g = list(x.groups())
        ai = 1 if fmt.startswith("ld\t{0}") or fmt.startswith("lda\t{0}") else 0
        a = int(g[ai], 0)
        if "{sym}" in fmt and a not in syms:
            return m
        cand = fmt.format(*g, a=a, sym=syms.get(a, ""))
        test = cand if "{sym}" not in fmt else cand.replace("(%s:24)" % syms[a], "(0x%x:24)" % a)
        return cand if verify_roundtrip(test.replace("\t", " "), expected) else m
    return m


def code_kind(line):
    """'insn' for an instruction line (a label before it allowed), 'label' for a bare label, None otherwise."""
    s = line.split(";")[0].strip()
    if not s:
        return "skip"
    m = LABEL.match(s)
    if m:
        s = m.group(2).strip()
        if not s:
            return "label"
    if s.startswith("."):
        return None
    m = MNEM.match(s)
    if not m or m.group(1) in DATA_MACROS:
        return None
    return "insn"


def falls_through(line):
    s = line.split(";")[0].strip()
    m = LABEL.match(s)
    if m:
        s = m.group(2).strip()
    m = MNEM.match(s)
    op, rest = m.group(1), m.group(2)
    if op in ("ret", "reti", "retd", "halt"):
        return False
    if op in ("jp", "jr", "jrl"):
        first = rest.split(",")[0].strip().lower()
        return first in COND and first != "t" and "," in rest
    return True


def main():
    apply = "--apply" in sys.argv
    trees = TREES
    if "--trees" in sys.argv:
        trees = {k: TREES[k] for k in sys.argv[sys.argv.index("--trees") + 1].split(",")}
    for tree, path in trees.items():
        done = nb = skipped = 0
        syms = load_syms(tree)
        for p in sorted(glob.glob(os.path.join(ROOT, path, "**", "*.s"), recursive=True)):
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changes = []
            i = 0
            while i < len(L):
                if not BYTE.match(L[i]):
                    i += 1
                    continue
                j = i
                while j < len(L) and BYTE.match(L[j]):
                    j += 1
                block, comments = [], []
                for x in L[i:j]:
                    m = BYTE.match(x)
                    block += [int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{1,2})', m.group(1))]
                    if m.group(2):
                        comments.append(m.group(2))
                # previous code line
                k, labelled = i - 1, False
                while k >= 0 and code_kind(L[k]) in ("skip", "label"):
                    labelled |= code_kind(L[k]) == "label"
                    k -= 1
                n = j
                while n < len(L) and code_kind(L[n]) in ("skip", "label"):
                    n += 1
                ok = (k >= 0 and code_kind(L[k]) == "insn" and (labelled or falls_through(L[k]))
                      and n < len(L) and code_kind(L[n]) == "insn" and len(block) >= 2)
                if not ok:
                    i = j
                    continue
                res = convert_block(block)
                if any(m is None for m, _, _ in res) or any(FILLER.match(m) or BRANCH.match(m) for m, _, _ in res):
                    skipped += 1
                    i = j
                    continue
                new = []
                for m, off, nbytes in res:
                    m = nativize(m, block[off:off + nbytes], syms)
                    m = hexify(m.replace(" ", "\t", 1) if "\t" not in m else m)
                    m = ROM24.sub(lambda x: "(%s:24)" % syms[int(x.group(1), 16)]
                                  if int(x.group(1), 16) in syms else x.group(0), m)
                    new.append("\t" + m)
                if comments:
                    c = " ".join(comments)
                    x = re.match(r'^;\s*(\S+)[^;]*?\s--\s+(.*)$', c)
                    if x and x.group(1).lower() == new[0].split()[0].lower():
                        c = "; " + x.group(2)
                    new[0] += "\t" + c
                changes.append((i, j, new))
                done += 1
                nb += len(block)
                i = j
            if changes and apply:
                for a, b, new in reversed(changes):
                    L[a:b] = new
                data = "\n".join(L).encode("latin-1")
                with open(p + ".tmp", "wb") as fh:
                    fh.write(data)
                os.replace(p + ".tmp", p)
        print("%s: %d runs (%d bytes) respelled, %d embedded runs left (undecodable, branch or filler)"
              % (tree, done, nb, skipped))


if __name__ == "__main__":
    main()
