#!/usr/bin/env python3
"""Recover the NAKA headers whose third byte is not 0x60, POSITIONALLY.

The value-based fix does not work and the numbers say why: broadening the
signature to `XX 00 [60..68] 01` adds 481 headers while a nine-value control
window elsewhere yields 601 from noise alone, and length consistency falls from
53% of types to 41%. See notes/FINDINGS-naka-record-format.md.

This does it the other way round. Start from the headers the strict `0x60`
signature finds. Wherever a record runs LONGER than its type's modal length,
look at exactly the modal offset -- the one place a sibling header is predicted
to be -- and accept a header there only if the byte pattern also fits. Position
supplies the evidence the value cannot.

    accept at `start + modal` iff  rom[+1] == 0x00
                             and  rom[+3] == 0x01
                             and  rom[+2] in the seven POSITION-CONFIRMED values

The seven values {0x60,0x61,0x63,0x64,0x65,0x67,0x68} were themselves derived
from position, not chosen: they are the third bytes of the 168 headers that sit
exactly at a modal boundary, which is 26x the 0.85% rate of header-shaped words
at random ROM offsets.

⚠ ITERATES. Splitting one record can expose another boundary inside the
remainder, so the pass repeats until no new header is found, with a round cap.

⚠ CONTROL, and it is the point of the script: the identical procedure is run
with the acceptance offset moved OFF the modal length (modal +/- 3). If position
is doing the work, the off-boundary run must recover far fewer. If it recovers a
similar number, this is finding noise too and the recovery is worthless.

Run:  python3 scripts/analysis/l3_naka_positional_headers.py
"""
import collections, glob, importlib.util, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO); sys.path.insert(0, str(REPO))
BASE = 0xE00000
VALID3 = {0x60, 0x61, 0x63, 0x64, 0x65, 0x67, 0x68}

_c = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)


def load():
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
    base = []
    for ad, sz in spans:
        o0 = ad - BASE
        for o in range(o0, min(o0 + sz, len(rom)) - 3):
            if rom[o + 1] == 0 and rom[o + 2] == 0x60 and rom[o + 3] == 1:
                base.append(BASE + o)
    base.sort()
    return rom, base


def modal_of(rom, hits):
    r = collections.defaultdict(list)
    for i, ad in enumerate(hits[:-1]):
        r[rom[ad - BASE]].append(hits[i + 1] - ad)
    out = {}
    for ty, L in r.items():
        if len(L) < 8:
            continue
        m, n = collections.Counter(L).most_common(1)[0]
        if n / len(L) >= 0.5:
            out[ty] = m
    return out


def recover(rom, hits, delta=0, rounds=6):
    hits = list(hits)
    total = 0
    for _ in range(rounds):
        modal = modal_of(rom, hits)
        found = []
        for i, ad in enumerate(hits[:-1]):
            ty = rom[ad - BASE]
            m = modal.get(ty)
            if not m:
                continue
            span = hits[i + 1] - ad
            at = m + delta
            if span <= at or at < 4:
                continue
            o = ad - BASE + at
            if (rom[o + 1] == 0 and rom[o + 3] == 1 and rom[o + 2] in VALID3):
                found.append(BASE + o)
        found = [f for f in found if f not in set(hits)]
        if not found:
            break
        hits = sorted(set(hits) | set(found))
        total += len(found)
    return hits, total


def consistency(rom, hits):
    r = collections.defaultdict(list)
    for i, ad in enumerate(hits[:-1]):
        r[rom[ad - BASE]].append(hits[i + 1] - ad)
    tot = fix = 0
    for ty, L in r.items():
        if len(L) < 8:
            continue
        tot += 1
        if collections.Counter(L).most_common(1)[0][1] / len(L) >= 0.8:
            fix += 1
    return fix, tot


def main():
    rom, base = load()
    print(f"  strict 0x60 headers                : {len(base)}")
    f0, t0 = consistency(rom, base)
    print(f"  types with a consistent length     : {f0}/{t0}  ({100*f0//t0}%)")
    print()
    hits, n = recover(rom, base, delta=0)
    f1, t1 = consistency(rom, hits)
    print(f"  RECOVERED at the modal boundary    : +{n}   -> {len(hits)} headers")
    print(f"  types with a consistent length     : {f1}/{t1}  ({100*f1//t1}%)")
    print()
    for d in (+3, -3):
        _h, nc = recover(rom, base, delta=d)
        print(f"  CONTROL, offset modal{d:+d}            : +{nc}")
    print()
    print("  If the controls recover a similar count, position is NOT doing the")
    print("  work and this recovery is finding noise.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
