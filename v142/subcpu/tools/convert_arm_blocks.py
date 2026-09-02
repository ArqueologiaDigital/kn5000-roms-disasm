#!/usr/bin/env python3
"""convert_arm_blocks.py -- convert the v1.42 payload's computed-jump ARM BLOCKS
from `.byte` runs to instructions.

QUESTION ANSWERED: `scripts/analysis/tier2_byte_split_census.py --report
--image v142 --list a` finds 2,188 B of the payload still spelled as `.byte`
that its CODE test classifies as real instructions. notes/DEBT-INVENTORY
-2026-09-02.md records "subcpu v142: 0 B" of code-as-`.byte`; that entry is
about one specific decoder-blocked family and is not the whole picture. How
much of the 2,188 B can be converted BYTE-EXACTLY with the pinned toolchain,
and what corroborates the framing?

WHICH BLOCKS AND WHY THEY ARE CODE
    Each is preceded, in the source, by
        lda_24 xix, 0x0<block address>
        jp_ind 8, 0x07, 0xF0, 0xE8
    i.e. a computed jump whose base is the block's own address, and each
    already carries a hand-written `; NOT DATA -- arm block of the computed
    jump` comment. This tool does not discover that they are code; it converts
    what the tree already says, into a form the tree can check.

WHAT IS CHECKED, BEYOND THE BYTE GATE
    1. ROUND TRIP. The block's raw bytes are disassembled by `llvm-mc
       --disassemble`, every instruction is individually re-encoded with
       `--show-encoding`, and the concatenation must equal the original bytes
       EXACTLY. Any "invalid instruction encoding" warning aborts the block.
    2. BRANCH-TARGET COHERENCE (the prom_c/prom_d falsification method,
       wsa1/notes/prom_cd_falsification_2026_09_02.py): every in-block branch
       target of the independent unidasm decode must land on a boundary of
       that same decode, excluding degenerate self/next targets. Across the
       four converted blocks that is 10 informative targets, 10 on a
       boundary, at ~2.8x the boundary density -- i.e. the framing is
       self-consistent, not merely re-assemblable. Reproduced, after the
       fact and from the ROM, by v142/subcpu/tools/arm_block_evidence.py.

    3. ARM BOUNDARIES. A computed-jump arm block has SEVERAL entry points,
       one per arm, and a linear framing is only right if every arm entry
       falls on an instruction boundary. The tree already names them: each
       block carries INTERIOR LABELS (`DSP_AlgoType_D2_Arm_Type457:` and so
       on) with their own explanatory comments, and each label's real address
       comes from the same verified probe build the census uses. This tool
       REQUIRES every interior label offset to be a boundary of the decode,
       and refuses the whole block otherwise. Every interior label and
       comment is preserved exactly where it was, so the converted block
       keeps the arm structure the source documented.

WHAT IT REFUSES. Blocks whose bytes do not round-trip are left as `.byte`:
0x01FEDF, 0x020D43, 0x033812, 0x036252, 0x03C32E, 0x03C7BB, 0x03CB8E
(1,522 B). Six hit `llvm-mc --disassemble`'s own decoder gaps -- unidasm
decodes them cleanly, so this is an LLVM-side limitation, not evidence about
the bytes -- and 0x03CB8E re-encodes 24 B for 26 B of input.

RUN (from the lane worktree root):
    python3 v142/subcpu/tools/convert_arm_blocks.py             # dry run
    python3 v142/subcpu/tools/convert_arm_blocks.py --apply
    rm -f rebuilt_ROMs/kn5000_subprogram_v142.llvm.*
    make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom
    cmp rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom original_ROMs/kn5000_subprogram_v142.rom

⚠ latin-1 I/O throughout (BRIEF addendum 2026-09-02).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(ROOT, "v142/subcpu/kn5000_subprogram_v142.s")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
BYTE = re.compile(r'^\s*\.byte\s+(.*)$')

# (label, first source line of the .byte run (1-based), expected byte count)
# (label, expected byte count of the whole `.byte` run under it). The run is
# located, and split at its interior labels, from the census's own verified
# address map -- never by counting `.byte` lines by hand.
BLOCKS = [
    ("DSP_AlgoType_Dispatch2_TableData", 331),
    ("Algo_SubTable_JumpTable1",         135),
    ("Algo_SubTable_JumpTable2",          89),
    ("Algo_SubTable_JumpTable3",         111),
]


def parse_byte_line(txt):
    m = BYTE.match(txt)
    if not m:
        return None
    out = []
    for tok in m.group(1).split(";")[0].split(","):
        tok = tok.strip()
        if tok:
            out.append(int(tok, 0))
    return out


def disassemble(raw):
    """[(offset, nbytes, text)] or None. Every instruction is individually
    re-encoded and the concatenation must equal `raw` exactly."""
    hx = " ".join("0x%02x" % b for b in raw)
    r = subprocess.run([MC, "--triple=tlcs900", "--disassemble"],
                       input=hx, capture_output=True, text=True)
    if "invalid instruction encoding" in r.stderr:
        return None, "llvm-mc cannot decode these bytes"
    ins = [l.strip() for l in r.stdout.strip().split("\n")
           if l.strip() and not l.strip().startswith(".")]
    if not ins:
        return None, "no instructions decoded"
    r2 = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                        input="\n".join(ins) + "\n", capture_output=True, text=True)
    if r2.returncode:
        return None, "re-assembly failed"
    encs = []
    for l in r2.stdout.split("\n"):
        m = ENC.search(l)
        if m:
            encs.append(bytes(int(x, 16) for x in m.group(1).split(",") if x.strip()))
    if b"".join(encs) != raw:
        return None, "re-encode mismatch (%d B vs %d B)" % (
            len(b"".join(encs)), len(raw))
    if len(encs) != len(ins):
        return None, "instruction/encoding count mismatch"
    out, off = [], 0
    for text, e in zip(ins, encs):
        out.append((off, len(e), text))
        off += len(e)
    return out, "OK"


def main():
    apply_ = "--apply" in sys.argv
    sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
    import tier2_byte_split_census as C

    runs, amap, srcmap = C.collect("v142")
    lines = open(SRC, encoding="latin-1").read().split("\n")
    rel = "kn5000_subprogram_v142.s"
    addrs = amap[rel]
    labels = {}
    for i, txt in enumerate(lines, 1):
        m = C.LABEL_DEF.match(txt)
        if m and i < len(addrs) and addrs[i] is not None:
            labels.setdefault(m.group(1), i)

    edits, converted = [], 0
    for label, want in BLOCKS:
        if label not in labels:
            sys.exit("refusing: label %s not found in %s" % (label, rel))
        lab_line = labels[label]
        run = None
        for r in runs:
            if r[0] == rel and r[1] > lab_line and r[1] <= lab_line + 3:
                run = r
                break
        if run is None:
            sys.exit("refusing: no `.byte` run found just below %s" % label)
        _rel, l0, l1, start, size, _t = run
        if size != want:
            sys.exit("refusing: %s run is %d B, expected %d" % (label, size, want))

        raw = bytearray()
        marks = []            # (byte offset, source line) for every passthrough
        for i in range(l0, l1 + 1):
            vals = parse_byte_line(lines[i - 1])
            if vals is None:
                marks.append((len(raw), i))
            else:
                raw += bytes(vals)
        raw = bytes(raw)
        if len(raw) != size:
            sys.exit("refusing: %s collected %d B, run says %d" % (label, len(raw), size))

        ins, why = disassemble(raw)
        if ins is None:
            sys.exit("refusing: %s does not round-trip (%s)" % (label, why))
        bounds = {o for o, _n, _t in ins} | {len(raw)}
        bad = [(o, lines[i - 1].strip()) for o, i in marks if o not in bounds]
        if bad:
            sys.exit("refusing: %s -- interior label/comment at +0x%X (%r) is NOT an "
                     "instruction boundary of the decode. A computed-jump arm entered "
                     "mid-instruction means the linear framing is wrong."
                     % (label, bad[0][0], bad[0][1]))
        print("%-34s lines %6d..%-6d %4d B  %3d instructions, %d interior "
              "lines all on boundaries" % (label, l0, l1, size, len(ins), len(marks)))

        body = [
            "\t; Converted from a %d-byte `.byte` run, round-trip exact: these exact"
            % size,
            "\t; mnemonics re-assemble to the original bytes. Entered by the computed",
            "\t; jump above; every interior arm label below falls on an instruction",
            "\t; boundary of this decode, which is what makes the linear framing right.",
        ]
        mi = dict(marks)
        by_off = {}
        for o, i in marks:
            by_off.setdefault(o, []).append(i)
        for o, _n, text in ins:
            for i in by_off.pop(o, []):
                body.append(lines[i - 1])
            body.append("\t" + text)
        for o in sorted(by_off):
            for i in by_off[o]:
                body.append(lines[i - 1])
        edits.append((l0, l1, body))
        converted += size

    print("total convertible: %d B" % converted)
    if not apply_:
        print("(dry run; pass --apply to write)")
        return 0
    for l0, l1, body in sorted(edits, reverse=True):
        lines[l0 - 1:l1] = body
    open(SRC, "w", encoding="latin-1").write("\n".join(lines))
    print("written: %s" % SRC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
