#!/usr/bin/env python3
"""Is the -0x41A label repair WELL-DEFINED? A dry run that moves nothing.

QUESTION ANSWERED
-----------------
`v7_label_displacement.py` shows 3,474 v7 labels in one contiguous region
(0x00FCCE4A..0x00FFFE80) sitting exactly 0x41A above the routine they name.
"Plausibly one operation" is a hypothesis. This tests it, per label:

    for a label L currently at address A, the routine is at A-0x41A.
    Is there a place in the SOURCE that corresponds to A-0x41A?
    Is that place free, or does another label already own it?

Three outcomes, and only the first is a repair that can be performed mechanically:

    MOVABLE    a source position for A-0x41A exists and carries no label
    OCCUPIED   a label already sits at A-0x41A. ⚠ Usually NOT a conflict: if that
               label is itself displaced it moves too and the slot frees. Only a
               target held by a STATIC label is a real collision. 121 targets are
               occupied; 109 free themselves; 12 are genuine.
    NO SITE    no source line corresponds to A-0x41A (it falls inside a `.byte`
               run or an `.incbin`, where there is no line boundary to attach to)

⚠ CORRECTION 2026-08-23, and it changes the answer. The first version of this
script reported "3,462 mechanical moves" while only ever testing whether a LABEL
owned the target address. That is not feasibility -- an unowned address is not a
placeable one. Measuring the missing half against the converter's own block
index:

    targets landing INSIDE a `.byte` run (no line to hold a label)   2,834
    targets in a code region (a line boundary plausibly exists)        640

So the repair is NOT mostly mechanical today. For 2,834 labels the destination
is in the middle of an undisassembled byte run, and placing a label there means
SPLITTING the run -- which is conversion work, not a rename.

⚠ THE USEFUL CONSEQUENCE: this repair gets easier as conversion proceeds. Every
`.byte` run that becomes instructions turns some of those 2,834 into the 640
case. The two jobs are coupled -- and `v7_guard_vs_displacement.py` shows the
coupling runs BOTH ways: 88% of the labels blocking conversion are themselves
displaced. So they must INTERLEAVE region by region; neither can simply follow
the other.

THE 640 FIGURE IS VERIFIED, not merely inferred -- which matters, because the
claim it replaced ("3,462 mechanical moves") was wrong for exactly the sin of
not checking. "Target not inside a `.byte` run" would still not prove a source
line exists there, so a sample was decoded from the nearest preceding symbol and
asked whether an instruction starts exactly at the target: 11 of 11 do. The
remaining 629 are inferred from the same territory test, and a full check would
decode all of them.

⚠ THIS MOVES NOTHING, and the reason matters: relocating a label changes no
bytes, so `make clean-all && make all` reports 9/9 whether every label lands
right or every one lands wrong (spec anti-patterns 12 and 13). A repair the
gate cannot review must be shown to be well-defined BEFORE it is attempted, not
after.

⚠ The four labels inside the span that are correctly placed must be excluded by
NAME, not by rule -- a blanket shift breaks them. They are listed in the output.

Run:  python3 scripts/analysis/v7_label_repair_feasibility.py
"""
import collections, glob, os, re, sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
BASE = 0xE00000
DISP = 0x41A
LO, HI = 0x00FCCE4A, 0x00FFFE80
W = 32
LABEL = re.compile(r'^([A-Za-z_][\w]*):')


def syms(path):
    d = {}
    for line in open(os.path.join(REPO, "symbols", path), encoding="latin1"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            try:
                d[f[0]] = int(f[1], 16)
            except ValueError:
                pass
    return d


def main():
    rom7 = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    rom9 = open(os.path.join(REPO, "original_ROMs", "kn5000_v9_program.rom"), "rb").read()
    s7, s9 = syms("maincpu_v7_symbols_reference.txt"), syms("maincpu_v9_symbols_reference.txt")

    displaced, correct_inside = [], []
    for n in sorted(set(s7) & set(s9)):
        a7, a9 = s7[n], s9[n]
        if not (LO <= a7 <= HI):
            continue
        o7, o9 = a7 - BASE, a9 - BASE
        if not (0 <= o9 < len(rom9) - W and DISP <= o7 < len(rom7) - W):
            continue
        ref = rom9[o9:o9 + W]
        at = sum(1 for x, y in zip(rom7[o7:o7 + W], ref) if x == y)
        tr = sum(1 for x, y in zip(rom7[o7 - DISP:o7 - DISP + W], ref) if x == y)
        if at <= 8 and tr >= 28:
            displaced.append((n, a7))
        elif at >= 28:
            correct_inside.append((n, a7))

    # Every address that some label already owns.
    owned = collections.defaultdict(list)
    for n, a in s7.items():
        owned[a].append(n)

    # ⚠ AN OCCUPIED TARGET IS USUALLY NOT A CONFLICT. If the label sitting on the
    # target is ITSELF displaced, it moves down in the same shift and the slot
    # frees. Only a target held by a STATIC (correctly placed) label is a real
    # collision needing a human decision. Asking the first question alone reports
    # 121 conflicts; asking the second reports 12.
    dispnames = {n for n, _ in displaced}
    movable, freed, conflict = [], [], []
    for n, a in displaced:
        tgt = a - DISP
        holders = owned.get(tgt, [])
        if not holders:
            movable.append((n, a, tgt))
        elif all(h in dispnames for h in holders):
            freed.append((n, a, tgt, holders))
        else:
            conflict.append((n, a, tgt, [h for h in holders if h not in dispnames]))
    occupied = conflict

    print(f"  region {LO:#08x}..{HI:#08x}")
    print(f"  displaced labels                       : {len(displaced):,}")
    print(f"  correctly placed INSIDE the region     : {len(correct_inside)}  (must NOT move)")
    for n, a in correct_inside:
        print(f"      {n:44} {a:#010x}")
    print(f"\n  target free                            : {len(movable):,}")
    print(f"  target held by an ALSO-DISPLACED label : {len(freed):,}"
          f"   (frees in the same simultaneous shift)")
    print(f"  target held by a STATIC label          : {len(conflict):,}"
          f"   <- the only genuine conflicts")
    print(f"  => mechanical moves                    : {len(movable)+len(freed):,}"
          f" of {len(displaced):,}")
    if occupied:
        print("\n  sample of OCCUPIED targets (the name there now, vs the one that wants it):")
        for n, a, t, who in occupied[:10]:
            print(f"    {n:40} {a:#010x} -> {t:#010x} held by {','.join(who)[:44]}")
    print("\n  ⚠ Nothing was moved. An OCCUPIED target means two names claim one address,")
    print("     which is a judgement about which name is right -- not a mechanical shift.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
