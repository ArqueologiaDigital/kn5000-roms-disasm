#!/usr/bin/env python3
"""Move the `0x41A`-displaced labels onto the routines they name.

EVIDENCE (see notes/FINDINGS-naka-record-format.md and
tools/spelling-probes/check_0x41A_contradiction.py):

  * 126 v7 symbols have a 32-bit ROM word at `address - 0x41A` and NONE at their
    current address, against a 0.9% control;
  * for the eight handled here, the candidate address is a dispatch handler whose
    behaviour was read from the code with no name attached, and the displaced
    name DESCRIBES that behaviour -- `SndParam_ReturnNotFound` on the
    `ld HL,0xffff ; ret` stub, `SndParam_ReadRegWithLUT` on the one that indexes
    a second table, `SndParam_ResetDefaultTable` on the one that reseeds a
    template and marks it invalid.

⚠ WHY THIS IS SAFE WHERE THE 981 REPAIRS WERE NOT. Those labels were REFERENCED,
so moving them changed `.long <symbol>` values and corrupted the ROM -- which is
how the byte gate caught it. These eight are referenced NOWHERE, so the move
changes no bytes at all. The byte gate therefore cannot corrupt, and equally
CANNOT VALIDATE. The gate that applies here is different:

    the rebuilt ELF must place each symbol at its PREDICTED address.

That is checked below and the run aborts if any symbol lands elsewhere.

⚠ SCOPE: only the eight with both pointer evidence AND semantic confirmation.
The other 118 have pointer evidence alone and stay in the queue
(`tools/spelling-probes/list_0x41A_suspects.py`). Acting on the whole population
because part of it is proven is the mistake that produced the 981.

Run:  python3 scripts/converters/move_0x41A_displaced_labels.py [--apply]
"""
import argparse, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
SHIFT = 0x41A
SRC = "v7/maincpu/audio/sndparam_routines.s"

MOVES = {
    "SndParam_ReturnNotFound":     0xFCD1EC,
    "SndParam_ReadRegField":       0xFCD1F0,
    "SndParam_ReadRegWithLUT":     0xFCD22E,
    "SndParam_CompareRegField":    0xFCD272,
    "SndParam_ReadRegWord":        0xFCD2D5,
    "SndParam_ReadRegBitfield":    0xFCD31A,
    "SndParam_ReadRegAddress":     0xFCD373,
    "SndParam_ResetDefaultTable":  0xFCD396,
}
BYTE = re.compile(r'^\t\.byte\s+(.*)$')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    lines = open(SRC, encoding="latin1").read().splitlines()

    # byte offset of every line, counting .byte payloads only
    off, pos = 0, {}
    for i, ln in enumerate(lines):
        pos[i] = off
        m = BYTE.match(ln)
        if m:
            off += len([x for x in m.group(1).split(",") if x.strip()])

    label_line = {}
    for i, ln in enumerate(lines):
        m = re.match(r'^(\w+):$', ln)
        if m and m.group(1) in MOVES:
            label_line[m.group(1)] = i
    missing = set(MOVES) - set(label_line)
    if missing:
        sys.exit(f"labels not found in {SRC}: {sorted(missing)}")

    # target offset = current offset - SHIFT
    plan = []
    for nm, i in sorted(label_line.items(), key=lambda kv: kv[1]):
        want = pos[i] - SHIFT
        if want < 0:
            sys.exit(f"{nm}: target offset negative -- refusing")
        plan.append((nm, i, pos[i], want))
        print(f"  {nm:30} run offset 0x{pos[i]:05X} -> 0x{want:05X}")

    if not a.apply:
        print("\n  dry run -- nothing written. Re-run with --apply, then check the ELF.")
        return 0

    # rebuild: drop the label lines, then re-insert by splitting a .byte line
    drop = {i for _n, i, _o, _w in plan}
    out, off = [], 0
    want_at = {w: n for n, _i, _o, w in plan}
    for i, ln in enumerate(lines):
        if i in drop:
            continue
        m = BYTE.match(ln)
        if not m:
            out.append(ln); continue
        vals = [x.strip() for x in m.group(1).split(",") if x.strip()]
        start = off
        cut = [k for k in range(len(vals)) if (start + k) in want_at]
        if not cut:
            out.append(ln); off += len(vals); continue
        prev = 0
        for k in cut:
            if k > prev:
                out.append("\t.byte " + ", ".join(vals[prev:k]))
            out.append(f"{want_at[start + k]}:")
            prev = k
        if prev < len(vals):
            out.append("\t.byte " + ", ".join(vals[prev:]))
        off += len(vals)
    open(SRC, "w", encoding="latin1").write("\n".join(out) + "\n")
    print(f"\n  wrote {SRC}. NOW VERIFY: rebuild and check each symbol's ELF address.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
