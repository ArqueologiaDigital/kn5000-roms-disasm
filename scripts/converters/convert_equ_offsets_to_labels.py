#!/usr/bin/env python3
"""Turn `.equ NAME, BASE + 0xNNN` into a LABEL positioned inside the blob.

These sources document blob interiors with 3,709 `.equ` constants. That is real
documentation -- it is why the binary-include audit under-credits these blobs --
but it puts the name in one place and the bytes in another. Splitting the
`.incbin` directive at each named offset and emitting the name AS A LABEL there
makes the blob self-describing:

    NakaData_SequencerExit:                 NakaData_SequencerExit:
        .incbin "f.bin"              ->         .incbin "f.bin", 0, 0x164
    .equ NakaInst_IvRealRecExit, ...      NakaInst_IvRealRecExit:
    .equ NakaInst_AcPanicEditSw, ...          .incbin "f.bin", 0x164, 0x10
                                          NakaInst_AcPanicEditSw:
                                              .incbin "f.bin", 0x174, 0x12

⚠ THE `.equ` LINES MUST GO. A label and an `.equ` of the same name are two
definitions of one symbol and the link fails. So this is not additive: it
REPLACES the documentation form, and if the emitted label lands at the wrong
offset the symbol silently moves -- which is exactly the failure mode of the 981
retracted label repairs (docs/IS-IT-DONE.md). The byte-match gate DOES catch it,
because every `.long <symbol>` in the ROM's pointer tables would change value.

⚠ SLICE-AWARE. A blob may already be split -- by an earlier run of this script,
or by `convert_embedded_ptr_regions.py` replacing a region with `.long` lines.
Each named offset is placed into the slice that COVERS it, and offsets falling
inside a converted `.long` region are skipped (their bytes are no longer in any
`.incbin`, so there is nothing to split). Requiring a bare single `.incbin` left
10 bases / 2,030 offsets unreachable -- the same blocker that hid six pointer
regions until the site filter was fixed.

Run:  python3 scripts/converters/convert_equ_offsets_to_labels.py [--apply] [--base NAME]
"""
import argparse, glob, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
EQU = re.compile(r'^\s*\.equ\s+(\w+)\s*,\s*(\w+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--base", help="restrict to one base label")
    a = ap.parse_args()

    total_files = total_names = 0
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))):
        txt = open(f, encoding="latin1").read()
        bm = re.search(r'^(\w+):\s*\n(\s*)\.incbin\s+"([^"]+)"', txt, re.M)
        if not bm:
            continue
        base, ind, inc = bm.group(1), bm.group(2), bm.group(3)
        if a.base and base != a.base:
            continue
        blob = REPO / os.path.dirname(f).split(os.sep)[0] / "maincpu" / inc
        if not blob.exists():
            blob = REPO / os.path.dirname(f) / inc
        if not blob.exists():
            continue
        size = blob.stat().st_size
        offs = []
        for ln in txt.splitlines():
            e = EQU.match(ln)
            if e and e.group(2) == base:
                offs.append((int(e.group(3), 0), e.group(1), ln))
        offs = sorted(set(offs))
        if not offs:
            continue
        # every .incbin SLICE of this blob in this file, in file order
        SL = re.compile(r'^([ \t]*)\.incbin\s+"([^"]*' + re.escape(os.path.basename(inc))
                        + r')"(?:[ \t]*,[ \t]*(0x[0-9A-Fa-f]+|\d+)[ \t]*,'
                        r'[ \t]*(0x[0-9A-Fa-f]+|\d+))?[ \t]*$', re.M)
        slices = []
        for sm in SL.finditer(txt):
            sk = int(sm.group(3), 0) if sm.group(3) else 0
            cnt = int(sm.group(4), 0) if sm.group(4) else size - sk
            slices.append((sm.start(), sm.end(), sm.group(1), sm.group(2), sk, cnt))
        if not slices:
            continue
        # group the named offsets by the slice that covers them
        bucket = {}
        placed = 0
        for o, nm, ln in offs:
            for i, (_a1, _b1, _ind, _inc, sk, cnt) in enumerate(slices):
                if sk < o < sk + cnt:
                    bucket.setdefault(i, []).append((o, nm, ln)); placed += 1
                    break
        if not placed:
            continue
        # rebuild each affected slice, LAST FIRST so earlier offsets stay valid
        new_txt = txt
        used = set()
        ok = True
        for i in sorted(bucket, reverse=True):
            st, en, sind, sinc, sk, cnt = slices[i]
            items = sorted(bucket[i])
            parts = [f'{sind}.incbin "{sinc}", 0x{sk:X}, 0x{items[0][0]-sk:X}']
            for j, (o, nm, ln) in enumerate(items):
                end = items[j + 1][0] if j + 1 < len(items) else sk + cnt
                if end <= o:
                    ok = False; break
                parts.append(f"{nm}:")
                parts.append(f'{sind}.incbin "{sinc}", 0x{o:X}, 0x{end-o:X}')
                used.add(ln)
            if not ok:
                break
            new_txt = new_txt[:st] + "\n".join(parts) + new_txt[en:]
        if not ok or not used:
            continue
        new_txt = "\n".join(l for l in new_txt.splitlines() if l not in used) + "\n"
        print(f"  {base:34} {len(used):4} names -> labels   {os.path.basename(f)}")
        total_files += 1; total_names += len(used)
        if a.apply:
            open(f, "w", encoding="latin1").write(new_txt)

    print()
    print(f"  blobs {'converted' if a.apply else 'convertible (DRY RUN)'}: {total_files}")
    print(f"  names repositioned as labels        : {total_names}")
    if not a.apply:
        print("\n  dry run -- nothing written.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
