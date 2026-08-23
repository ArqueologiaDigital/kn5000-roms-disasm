#!/usr/bin/env python3
"""Trim each converted `.long` region to the part that is ACTUALLY pointers.

ROOT CAUSE of a real defect: `l3_embedded_structure_scan.py` reports regions on a
256-byte WINDOW grid, and a table's true extent does not respect that grid. So a
converted region can run past the end of its table into whatever follows -- which
for `naka_widget_names_charmap` 0x4C00 was an ASCII string table (retracted), for
`naka_widget_tables_1` 0x1000 is the strings `ApPlaySyori` / `NameGe...` after 58
pointers, and for `naka_sequencer_channels` 0x1500 is 4 non-pointer words BEFORE
the pointers start.

A word belongs to the table if it is NULL or lands in the ROM address range.
This trims the HEAD and TAIL only -- the first and last word that belongs to the
table -- and leaves the interior alone.

⚠ The first version took the longest CONTIGUOUS run, which is wrong in the other
direction: `naka_effects_seq` 0x006700 is 99% in-range with a few scattered
interior non-pointers, and contiguity would have reverted 218 valid pointer
entries to opaque bytes. The defect being fixed is a region running PAST its
table, not a table containing an occasional non-pointer. Bytes are unchanged either way; what changes is whether
the file CLAIMS those bytes are pointers.

⚠ Reverting is the conservative direction: a byte left in `.incbin` is described
as "opaque", which is weaker than the truth but never wrong. A byte wrongly
called `.long <address>` is a false statement that no gate in this project can
detect.

⚠ Regions where the pointer run is shorter than 8 words are reverted ENTIRELY --
below that length the run is not evidence of a table.

Run:  python3 scripts/converters/trim_ptr_regions_to_extent.py [--apply]
"""
import argparse, glob, os, pathlib, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
ROM_LO, ROM_HI = 0xE00000, 0x1000000
RUN = re.compile(r'^EmbeddedPtrTable_(v7|v9|v10)_(\w+?)_([0-9A-F]{6}):$')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    trimmed = words_reverted = 0
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))):
        lines = open(f, encoding="latin1").read().splitlines()
        inc = None
        for i, ln in enumerate(lines):
            m = re.search(r'\.incbin\s+"([^"]+)"', ln)
            if m:
                inc = m.group(1); break
        if not inc:
            continue
        blob = REPO / f.split(os.sep)[0] / "maincpu" / inc
        if not blob.exists():
            continue
        data = open(blob, "rb").read()
        out, i, changed = [], 0, False
        while i < len(lines):
            r = RUN.match(lines[i])
            if not r:
                out.append(lines[i]); i += 1; continue
            rev, name, off = r.group(1), r.group(2), int(r.group(3), 16)
            j = i + 1
            while j < len(lines) and lines[j].startswith("\t.long "):
                j += 1
            n = j - i - 1
            w = [struct.unpack("<I", data[off + 4 * k: off + 4 * k + 4])[0]
                 for k in range(n) if off + 4 * k + 4 <= len(data)]
            ok = [(x == 0 or ROM_LO <= x < ROM_HI) for x in w]
            # HEAD/TAIL trim: first and last index that belongs to the table.
            idx = [k for k, g in enumerate(ok) if g]
            if not idx:
                st, en = 0, 0
            else:
                st, en = idx[0], idx[-1] + 1
            ln_ = en - st
            if ln_ == n:
                out.extend(lines[i:j]); i = j; continue
            changed = True; trimmed += 1; words_reverted += n - ln_
            ind = "\t"
            if ln_ < 8:
                out.append(f'{ind}.incbin "{inc}", 0x{off:X}, 0x{4*n:X}')
            else:
                if st:
                    out.append(f'{ind}.incbin "{inc}", 0x{off:X}, 0x{4*st:X}')
                out.append(f"EmbeddedPtrTable_{rev}_{name}_{off+4*st:06X}:")
                out.extend(lines[i + 1 + st: i + 1 + en])
                if en < n:
                    out.append(f'{ind}.incbin "{inc}", 0x{off+4*en:X}, 0x{4*(n-en):X}')
            print(f"  {name} 0x{off:06X}: {n} words -> pointer run {ln_} "
                  f"at +{st}   ({n-ln_} words reverted)   {os.path.basename(f)}")
            i = j
        if changed and a.apply:
            open(f, "w", encoding="latin1").write("\n".join(out) + "\n")
    print()
    print(f"  regions {'trimmed' if a.apply else 'trimmable (DRY RUN)'} : {trimmed}")
    print(f"  words reverted to .incbin              : {words_reverted}")
    if not a.apply:
        print("\n  dry run -- nothing written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
