#!/usr/bin/env python3
"""What is the RECORD FORMAT of the NAKA widget structures?

The completeness spec asks for the data format of every structure, not just its
name and address. The NAKA blobs resist the usual approach: the gap histogram of
their 3,709 named offsets has no dominant stride, so they are VARIABLE-LENGTH
records and there is no single record size to find.

Variable-length records are defined by their HEADER. This tree's own macro says
what one looks like:

    .macro naka_header type
        .byte \\type, 0x00, 0x60, 0x01
    .endm

So the format question becomes answerable: find every `XX 00 60 01` in the ROM,
take XX as the record TYPE, measure each record's length as the distance to the
next header, and ask whether a given type has a CONSISTENT length.

  * a type with one length  -> fixed-size record, format pinned by that type
  * a type with many lengths -> genuinely variable, and the length must be
    carried inside the record; the spread tells you where to look

⚠ CONTROL, and the first version of it was measured on the WRONG POPULATION.
Sampling random offsets across the whole ROM gives ~0.185%, which predicted ~1,670
accidental hits inside the blob spans -- more than half the 2,857 found, which
would have made the whole table worthless. That estimate is wrong, because the
blob spans are not ROM-typical bytes.

The right control shuffles the SPANS THEMSELVES: byte frequency preserved, all
structure destroyed. It is also directly checkable against the type histogram --
accidental hits carry a uniform type byte, so they would spread over ~256 values
at a few each. Observed: only 94 distinct types occur, and the entire tail of 49
types with <=8 hits accounts for 156 hits, against 2,701 in the 45 types above
that. The noise is ~156, an order of magnitude below the bad estimate.

⚠ A consistent length is evidence of a fixed record, NOT proof: records of one
type could simply happen to be equally sized in this ROM.

Run:  python3 scripts/analysis/l3_naka_record_format.py [--type 0x1f]
"""
import argparse, collections, importlib.util, os, pathlib, random, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO); sys.path.insert(0, str(REPO))
BASE = 0xE00000
SIG = (0x00, 0x60, 0x01)

_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--type", help="show records of one type, e.g. 0x1f")
    a = ap.parse_args()

    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    inv = {n: ad for ad, n in syms.items()}

    # The NAKA blob address ranges: base label -> (start, size on disk)
    spans = []
    for f in sorted(set(__import__("glob").glob("v7/maincpu/**/*.s", recursive=True))):
        txt = open(f, encoding="latin1").read()
        for m in re.finditer(r'^(\w+):\s*\n\s*\.incbin\s+"([^"]+)"', txt, re.M):
            lbl, inc = m.group(1), m.group(2)
            ad = inv.get(lbl)
            p = REPO / "v7/maincpu" / inc
            if ad and p.exists():
                spans.append((lbl, ad, p.stat().st_size))
    spans.sort(key=lambda r: r[1])
    covered = sum(sz for _l, _a, sz in spans)
    print(f"  NAKA-style blob spans found : {len(spans)}  ({covered:,} bytes)")

    # CONTROL on the right population: shuffle the span bytes.
    rng = random.Random(3)
    blob = bytearray()
    for _l, ad, sz in spans:
        blob += rom[ad - BASE: ad - BASE + sz]
    sh = bytearray(blob); rng.shuffle(sh)
    ctrl = sum(1 for o in range(len(sh) - 3) if tuple(sh[o + 1:o + 4]) == SIG)
    whole = sum(1 for _ in range(100000)
                if tuple(rom[(o := rng.randrange(0, len(rom) - 4)) + 1:o + 4]) == SIG) / 100000
    print(f"  CONTROL, spans shuffled     : {ctrl} accidental hits")
    print(f"  (whole-ROM rate {100*whole:.3f}% would predict ~{int(whole*covered)} -- "
          f"the WRONG population, see docstring)")

    hits = []
    for _lbl, ad, sz in spans:
        o0 = ad - BASE
        for o in range(o0, min(o0 + sz, len(rom)) - 3):
            if tuple(rom[o + 1:o + 4]) == SIG:
                hits.append((BASE + o, rom[o]))
    print(f"  headers found in those spans: {len(hits)}")
    print()

    hits.sort()
    lens = collections.defaultdict(list)
    for i, (ad, ty) in enumerate(hits[:-1]):
        lens[ty].append(hits[i + 1][0] - ad)

    if a.type:
        ty = int(a.type, 0)
        L = lens.get(ty, [])
        c = collections.Counter(L)
        print(f"  type 0x{ty:02X}: {len(L)} records, {len(c)} distinct lengths")
        for k, v in sorted(c.items())[:20]:
            print(f"    length {k:5}  x{v}")
        return 0

    print(f"  {'type':>5} {'records':>8} {'distinct len':>13} {'most common':>12}  verdict")
    fixed = varia = 0
    for ty in sorted(lens, key=lambda t: -len(lens[t]))[:22]:
        L = lens[ty]
        c = collections.Counter(L)
        top, n = c.most_common(1)[0]
        share = n / len(L)
        if len(c) == 1:
            v = "FIXED"; fixed += 1
        elif share >= 0.8:
            v = f"mostly {top} ({100*share:.0f}%)"; fixed += 1
        else:
            v = "variable"; varia += 1
        print(f"  0x{ty:02X} {len(L):8} {len(c):13} {top:12}  {v}")
    print()
    print(f"  types with a pinned-down length : {fixed}")
    print(f"  types genuinely variable        : {varia}")
    print("\n  ⚠ Lengths are distance-to-next-header, so a trailing gap or an")
    print("    accidental signature inflates one record and shrinks its neighbour.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
