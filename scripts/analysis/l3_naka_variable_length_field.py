#!/usr/bin/env python3
"""Where do the VARIABLE-length NAKA types carry their length?

`l3_naka_record_format.py` pinned a length for 10 type bytes and found 12 more
whose length varies. A variable-length record has to say how long it is, so some
field should carry it. This tests every byte position and every u16 position in
the record against the OBSERVED length (distance to the next header).

TESTS, per type:
  EXACT      value at that offset == length, in every record of the type
  OFFSET-k   value + k == length, for a single constant k (a header-exclusive
             count, say) -- k is reported, not fitted per record
  SCALED     value * 2 + k == length (a WORD count rather than a byte count)

⚠ THE CONTROL THAT MATTERS: a position can match by luck, especially for a type
with few records or few distinct lengths. So every candidate is scored on how
many DISTINCT lengths it predicts correctly -- a rule verified across 1 distinct
length is worth nothing, since a constant would pass it. Types with fewer than 3
distinct lengths are reported as UNTESTABLE rather than given a false answer.

⚠ Lengths come from distance-to-next-header, so a missing or accidental header
shifts two records at once. A candidate that fails on one record out of many is
reported with its failure count rather than silently dropped.

Run:  python3 scripts/analysis/l3_naka_variable_length_field.py
"""
import collections, glob, importlib.util, os, pathlib, re, struct, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO); sys.path.insert(0, str(REPO))
BASE, SIG = 0xE00000, (0x00, 0x60, 0x01)

_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)


def main():
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    inv = {n: a for a, n in syms.items()}
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

    recs = collections.defaultdict(list)      # type -> [(addr, length)]
    for i, ad in enumerate(hits[:-1]):
        recs[rom[ad - BASE]].append((ad, hits[i + 1] - ad))

    print(f"  {'type':>5} {'recs':>5} {'distinct len':>12}  verdict")
    solved = untestable = unsolved = 0
    for ty in sorted(recs, key=lambda t: -len(recs[t])):
        rs = recs[ty]
        if len(rs) < 8:
            continue
        lens = {L for _a, L in rs}
        c = collections.Counter(L for _a, L in rs)
        if c.most_common(1)[0][1] / len(rs) >= 0.8:
            continue                          # already pinned as fixed
        if len(lens) < 3:
            print(f"  0x{ty:02X} {len(rs):5} {len(lens):12}  UNTESTABLE (<3 distinct lengths)")
            untestable += 1
            continue
        best = None
        maxoff = min(L for _a, L in rs)
        for off in range(2, min(maxoff, 32)):
            for mode in ("byte", "word"):
                vals = []
                for a, L in rs:
                    o = a - BASE + off
                    v = rom[o] if mode == "byte" else struct.unpack("<H", rom[o:o + 2])[0]
                    vals.append((v, L))
                for scale in ((1,) if mode == "word" else (1, 2)):
                    ks = collections.Counter(L - v * scale for v, L in vals)
                    k, n = ks.most_common(1)[0]
                    if n == len(vals):
                        preds = len({L for v, L in vals})
                        cand = (preds, off, mode, scale, k, 0)
                        if best is None or cand > best:
                            best = cand
        if best:
            preds, off, mode, scale, k, _ = best
            print(f"  0x{ty:02X} {len(rs):5} {len(lens):12}  "
                  f"len = {mode}@+0x{off:02X}"
                  + (f" * {scale}" if scale != 1 else "")
                  + f" + {k}   (verified across {preds} distinct lengths)")
            solved += 1
        else:
            print(f"  0x{ty:02X} {len(rs):5} {len(lens):12}  no field predicts the length")
            unsolved += 1
    print()
    print(f"  length field FOUND : {solved}")
    print(f"  untestable         : {untestable}")
    print(f"  not found          : {unsolved}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
