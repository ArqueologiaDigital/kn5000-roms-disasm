#!/usr/bin/env python3
"""Place a blob's remaining named offsets INSIDE converted `.long` runs.

`convert_equ_offsets_to_labels.py` splits `.incbin` directives at named offsets.
It cannot reach an offset whose bytes were already converted to `.long` by
`convert_embedded_ptr_regions.py` -- there is no `.incbin` there to split. 979
offsets across 6 bases are in that state.

A `.long` run starting at blob offset R holds one 4-byte entry per line, so a
named offset O with `(O - R) % 4 == 0` lands exactly BETWEEN two lines and the
label can be emitted there with no change to the bytes.

⚠ An offset that is NOT 4-aligned to the run cannot be placed without splitting a
`.long` into `.byte`s, which changes how the value is expressed and would undo
the pointer conversion for that entry. Those are counted and left alone, not
forced.

⚠ Same hazard as the other label work: a label emitted at the wrong line MOVES
the symbol silently, and the `.equ` it replaces must be deleted in the same edit.
The byte-match gate catches a moved symbol because the ROM's own pointer tables
hold `.long <symbol>` values that would change.

Run:  python3 scripts/converters/place_labels_in_long_runs.py [--apply]
"""
import argparse, glob, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
EQU = re.compile(r'^\s*\.equ\s+(\w+)\s*,\s*(\w+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*$')
RUN = re.compile(r'^EmbeddedPtrTable_(?:v7|v9|v10)_\w+_([0-9A-F]{6}):$')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    placed = unaligned = 0
    files = 0
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))):
        lines = open(f, encoding="latin1").read().splitlines()
        bm = None
        for i, ln in enumerate(lines):
            m = re.match(r'^(\w+):$', ln)
            if m and i + 1 < len(lines) and ".incbin" in lines[i + 1]:
                bm = m.group(1); break
        if not bm:
            continue
        offs = {}
        for ln in lines:
            e = EQU.match(ln)
            if e and e.group(2) == bm:
                offs[int(e.group(3), 0)] = (e.group(1), ln)
        if not offs:
            continue
        # map every .long line to its blob offset
        pos = {}
        cur = None
        for i, ln in enumerate(lines):
            r = RUN.match(ln)
            if r:
                cur = int(r.group(1), 16); continue
            if cur is not None:
                if ln.startswith("\t.long "):
                    pos[cur] = i; cur += 4
                else:
                    cur = None
        ins = {}
        used = set()
        for o, (nm, ln) in sorted(offs.items()):
            if o in pos:
                ins[pos[o]] = nm; used.add(ln); placed += 1
            elif any(o in range(k, k + 4) for k in pos):
                unaligned += 1
        if not ins:
            continue
        out = []
        for i, ln in enumerate(lines):
            if i in ins:
                out.append(f"{ins[i]}:")
            if ln not in used:
                out.append(ln)
        files += 1
        print(f"  {bm:34} {len(ins):4} labels into .long runs   {os.path.basename(f)}")
        if a.apply:
            open(f, "w", encoding="latin1").write("\n".join(out) + "\n")
    print()
    print(f"  files {'changed' if a.apply else 'changeable (DRY RUN)'} : {files}")
    print(f"  labels placed inside .long runs   : {placed}")
    print(f"  offsets NOT 4-aligned to a run    : {unaligned}   (left alone)")
    if not a.apply:
        print("\n  dry run -- nothing written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
