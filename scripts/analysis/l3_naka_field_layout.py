#!/usr/bin/env python3
"""What are the FIELDS of a NAKA record, position by position?

`l3_naka_record_format.py` pinned a length for 10 of the type bytes. A length is
not a format. This takes every record of one type, stacks them, and asks what
each byte position DOES across the population:

  CONST   one value in every record            -> part of the record's shape
  FLAG    2-4 distinct values                  -> an enum or a bitfield
  VARY    many values, no address structure    -> a datum
  PTR     the u32 at this offset lands in ROM range in most records, and
          resolves to a real symbol far above the 1.79% null -> a pointer field

⚠ WHY STACKING IS THE RIGHT INSTRUMENT and a single record is not: one record
cannot tell a constant from a coincidence. With 163 records of type 0x1F, a byte
that is identical in all 163 is a fact about the FORMAT; the same byte read once
tells you nothing. The population IS the evidence, so the record count is printed
next to every verdict and small populations are marked.

⚠ CONTROL: the same analysis is run on records SHUFFLED ACROSS THE POPULATION at
each offset (column-wise shuffle destroys nothing) -- no; the honest control is
to run the classifier on records cut at the WRONG offset. A field structure that
survives cutting the population at length+2 is not a field structure, it is an
artefact of the byte distribution. That control is run and reported.

⚠ A record whose length is only "mostly N" contains members of other lengths;
those are excluded rather than padded, and the excluded count is printed.

Run:  python3 scripts/analysis/l3_naka_field_layout.py --type 0x1f
      python3 scripts/analysis/l3_naka_field_layout.py --all
"""
import argparse, collections, glob, importlib.util, os, pathlib, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO); sys.path.insert(0, str(REPO))
BASE = 0xE00000
SIG = (0x00, 0x60, 0x01)
ROM_LO, ROM_HI = 0xE00000, 0x1000000

_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)


def collect():
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    inv = {n: ad for ad, n in syms.items()}
    spans = []
    for f in sorted(set(glob.glob("v7/maincpu/**/*.s", recursive=True))):
        txt = open(f, encoding="latin1").read()
        for m in re.finditer(r'^(\w+):\s*\n\s*\.incbin\s+"([^"]+)"', txt, re.M):
            ad = inv.get(m.group(1)); p = REPO / "v7/maincpu" / m.group(2)
            if ad and p.exists():
                spans.append((ad, p.stat().st_size))
    hits = []
    for ad, sz in spans:
        o0 = ad - BASE
        for o in range(o0, min(o0 + sz, len(rom)) - 3):
            if tuple(rom[o + 1:o + 4]) == SIG:
                hits.append(BASE + o)
    hits.sort()
    return rom, syms, hits


def records(rom, hits, ty, length):
    out = []
    for i, ad in enumerate(hits[:-1]):
        if rom[ad - BASE] != ty:
            continue
        if hits[i + 1] - ad != length:
            continue
        out.append(rom[ad - BASE: ad - BASE + length])
    return out


def classify(recs, syms, null=0.0179):
    n = len(recs)
    L = len(recs[0])
    out = []
    for off in range(L):
        vals = collections.Counter(r[off] for r in recs)
        if len(vals) == 1:
            out.append((off, "CONST", f"0x{recs[0][off]:02X}")); continue
        if len(vals) <= 4:
            top = " ".join(f"0x{v:02X}x{c}" for v, c in vals.most_common(4))
            out.append((off, "FLAG", top)); continue
        out.append((off, "VARY", f"{len(vals)} values"))
    # pointer fields: u32 at 4-aligned offsets
    for off in range(0, L - 3):
        w = [struct.unpack("<I", r[off:off + 4])[0] for r in recs]
        inr = sum(1 for x in w if ROM_LO <= x < ROM_HI) / n
        res = sum(1 for x in w if x in syms) / n
        if inr >= 0.9 and res >= 10 * null:
            for i, (o, k, d) in enumerate(out):
                if o == off:
                    out[i] = (o, "PTR ", f"u32, {100*inr:.0f}% in range, "
                                         f"{100*res:.0f}% resolve  <-- {int(res/null)}x null")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--type"); ap.add_argument("--all", action="store_true")
    a = ap.parse_args()
    rom, syms, hits = collect()
    lens = collections.defaultdict(list)
    for i, ad in enumerate(hits[:-1]):
        lens[rom[ad - BASE]].append(hits[i + 1] - ad)

    todo = []
    if a.type:
        ty = int(a.type, 0)
        todo = [(ty, collections.Counter(lens[ty]).most_common(1)[0][0])]
    else:
        for ty, L in lens.items():
            c = collections.Counter(L)
            top, k = c.most_common(1)[0]
            if k / len(L) >= 0.8 and len(L) >= 20:
                todo.append((ty, top))
    for ty, length in sorted(todo):
        recs = records(rom, hits, ty, length)
        if len(recs) < 8:
            continue
        print(f"\n=== type 0x{ty:02X}, length {length}, {len(recs)} records "
              f"(of {len(lens[ty])} headers; others are a different length) ===")
        rows = classify(recs, syms)
        for off, kind, desc in rows:
            if kind == "CONST" and off > 3:
                print(f"  +0x{off:02X}  {kind}  {desc}")
            elif kind != "CONST":
                print(f"  +0x{off:02X}  {kind}  {desc}")
        # CONTROL: cut the population at the WRONG length
        # CONTROL -- the null is "arbitrary equal-length chunks cut from the
        # SAME blobs share a field layout". Sample chunk starts uniformly from
        # the blob bytes, not at headers, same population size.
        #
        # ⚠ TWO EARLIER VERSIONS OF THIS CONTROL WERE INCAPABLE OF FAILING.
        # Both shifted every record by a constant (2, then 1 and 3). Shifting the
        # whole population identically only RELABELS the columns -- the alignment
        # between records, which is the entire thing being tested, is untouched.
        # Both reported "20 CONST vs 20 real" and I read the first as a weak
        # control rather than as no control at all.
        nconst = sum(1 for _o, k, _d in rows if k == "CONST")
        import random as _r
        rng = _r.Random(17)
        pool = b"".join(rom[ad - BASE: ad - BASE + length] for ad in hits[:400])
        if len(pool) > length * 4:
            chunks = []
            for _ in range(len(recs)):
                o = rng.randrange(0, len(pool) - length)
                chunks.append(pool[o:o + length])
            cr = classify(chunks, syms)
            nc = sum(1 for _o, k, _d in cr if k == "CONST")
            print(f"  CONTROL, {len(chunks)} random equal-length chunks from the same "
                  f"blobs: {nc} CONST vs {nconst} real"
                  + ("   <-- discriminates" if nc < nconst * 0.6 else
                     "   <-- DOES NOT discriminate"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
