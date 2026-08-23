#!/usr/bin/env python3
"""Position `.equ` offsets as labels for EVERY blob base in a file.

`convert_equ_offsets_to_labels.py` takes the FIRST `LABEL:` + `.incbin` pair in
each file. `widget_dispatch.s` holds two `.incbin` blocks, so its second base --
`ToneKit_NullParams`, with 119 named offsets and a bare `.incbin` directly under
it -- was never considered. The skip was invisible: the file WAS processed, just
for the wrong base, and the run reported "0 convertible" rather than skipping
anything.

This handles every base independently. Same rules as the original:
  * the slice covering an offset is split and the name emitted as a label there;
  * aliased offsets (two names, one address) emit both labels and advance to the
    next DISTINCT offset;
  * the `.equ` lines that became labels are deleted in the same edit, because a
    label plus an `.equ` of one name is a duplicate symbol.

⚠ A label at a wrong offset moves the symbol silently. The byte-match gate is
what catches it: the ROM's own pointer tables hold `.long <symbol>` values that
would change.

Run:  python3 scripts/converters/place_labels_all_bases.py [--apply]
"""
import argparse, glob, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
EQU = re.compile(r'^\s*\.equ\s+(\w+)\s*,\s*(\w+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*$')
BASE = re.compile(r'^(\w+):\s*\n([ \t]*)\.incbin\s+"([^"]+)"', re.M)


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = names = 0
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))):
        txt = open(f, encoding="latin1").read()
        bases = [(m.group(1), m.group(2), m.group(3)) for m in BASE.finditer(txt)]
        if len(bases) < 2:
            continue                      # the first-base case is already handled
        touched = 0
        for base, ind, inc in bases:
            blob = REPO / f.split(os.sep)[0] / "maincpu" / inc
            if not blob.exists():
                continue
            size = blob.stat().st_size
            offs = {}
            for ln in txt.splitlines():
                e = EQU.match(ln)
                if e and e.group(2) == base:
                    offs.setdefault(int(e.group(3), 0), []).append((e.group(1), ln))
            if not offs:
                continue
            SL = re.compile(r'^([ \t]*)\.incbin\s+"([^"]*'
                            + re.escape(os.path.basename(inc))
                            + r')"(?:[ \t]*,[ \t]*(0x[0-9A-Fa-f]+|\d+)[ \t]*,'
                            r'[ \t]*(0x[0-9A-Fa-f]+|\d+))?[ \t]*$', re.M)
            slices = [(m.start(), m.end(), m.group(1), m.group(2),
                       int(m.group(3), 0) if m.group(3) else 0,
                       int(m.group(4), 0) if m.group(4) else size
                       - (int(m.group(3), 0) if m.group(3) else 0))
                      for m in SL.finditer(txt)]
            bucket = {}
            for o in sorted(offs):
                for i, (_s, _e, _i, _n, sk, cnt) in enumerate(slices):
                    if sk < o < sk + cnt:
                        bucket.setdefault(i, []).append(o); break
            if not bucket:
                continue
            used, ok = set(), True
            new = txt
            for i in sorted(bucket, reverse=True):
                st, en, sind, sinc, sk, cnt = slices[i]
                keys = sorted(bucket[i])
                parts = [f'{sind}.incbin "{sinc}", 0x{sk:X}, 0x{keys[0]-sk:X}']
                for j, o in enumerate(keys):
                    end = keys[j + 1] if j + 1 < len(keys) else sk + cnt
                    if end <= o:
                        ok = False; break
                    for nm, ln in offs[o]:
                        parts.append(f"{nm}:"); used.add(ln)
                    parts.append(f'{sind}.incbin "{sinc}", 0x{o:X}, 0x{end-o:X}')
                if not ok:
                    break
                new = new[:st] + "\n".join(parts) + new[en:]
            if not ok or not used:
                continue
            txt = "\n".join(l for l in new.splitlines() if l not in used) + "\n"
            print(f"  {base:28} {len(used):4} names -> labels   {os.path.basename(f)}")
            names += len(used); touched += 1
        if touched:
            files += 1
            if a.apply:
                open(f, "w", encoding="latin1").write(txt)
    print()
    print(f"  files {'changed' if a.apply else 'changeable (DRY RUN)'} : {files}")
    print(f"  names repositioned as labels       : {names}")
    if not a.apply:
        print("\n  dry run -- nothing written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
