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

⚠ Only blobs whose `.incbin` appears ONCE, un-split, are handled; a blob already
carrying `.long` conversions is skipped rather than reconciled.

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
        m = re.search(r'^(\w+):\s*\n(\s*)\.incbin\s+"([^"]+)"\s*$', txt, re.M)
        if not m:
            continue
        base, ind, inc = m.group(1), m.group(2), m.group(3)
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
        if not offs or offs[0][0] <= 0 or offs[-1][0] >= size:
            continue
        # build the replacement
        parts = [f"{base}:", f'{ind}.incbin "{inc}", 0, 0x{offs[0][0]:X}']
        for i, (o, nm, _ln) in enumerate(offs):
            end = offs[i + 1][0] if i + 1 < len(offs) else size
            if end <= o:
                parts = None; break
            parts.append(f"{nm}:")
            parts.append(f'{ind}.incbin "{inc}", 0x{o:X}, 0x{end-o:X}')
        if parts is None:
            continue
        new_txt = txt[:m.start()] + "\n".join(parts) + txt[m.end():]
        # drop the .equ lines we just turned into labels
        drop = {ln for _o, _n, ln in offs}
        new_txt = "\n".join(l for l in new_txt.splitlines() if l not in drop) + "\n"
        print(f"  {base:34} {len(offs):4} names -> labels   {os.path.basename(f)}")
        total_files += 1; total_names += len(offs)
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
