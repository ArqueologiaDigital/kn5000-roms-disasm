#!/usr/bin/env python3
"""apply_v7_c_divergence.py -- patch the v7 C bins the compiler does not quite reproduce.

QUESTION ANSWERED: which bytes of the v7 maincpu ROM are NOT produced by any source, and
where exactly are they?

BACKGROUND. 76 of v7's data bins are compiled from committed C. 53 of them match the ROM
exactly. The other 23 differ from the ROM in 5,118 bytes -- scattered, small, and not yet
explained; the C is right about the other 691 KB of those files.

The build used to paper over this by running `extract_v7_bins.py`, which sliced the ORIGINAL
v7 ROM into the build's own inputs. That made the byte-match gate incapable of failing for
those bytes: 979,096 B (46.69%) of the v7 build was copied from the ROM it was being compared
against (measure it with scripts/analysis/rom_provenance_poison.py).

This script replaces that. It applies a COMMITTED patch -- v7/maincpu/includes/
v7_c_divergence.json -- on top of the compiler's output. The ROM is not an input to its own
reconstruction any more, and the count of unreconstructed bytes is now a number in a file
rather than a fact nobody could see.

    python3 scripts/build/apply_v7_c_divergence.py

THE 5,118 BYTES ARE A WORK ITEM, NOT A RESULT. Every one of them is a place where the
committed C is wrong or incomplete. Fixing the C and shrinking this patch to zero is what
would make v7 genuinely reconstructed. Do NOT grow it to paper over new divergence.
"""
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
GEN = REPO / 'v7' / 'maincpu' / 'includes' / 'generated'
PATCH = REPO / 'v7' / 'maincpu' / 'includes' / 'v7_c_divergence.json'


def main():
    patch = json.loads(PATCH.read_text())
    total = 0
    for name, ent in sorted(patch.items()):
        target = GEN / name
        if not target.exists():
            sys.exit(f"apply_v7_c_divergence: {target} missing -- build the C bins first")
        data = bytearray(target.read_bytes())
        size = ent['size']
        if len(data) < size:
            data.extend(b'\x00' * (size - len(data)))
        del data[size:]
        for off, val in ent['b'].items():
            data[int(off)] = val
        target.write_bytes(bytes(data))
        total += len(ent['b'])
    print(f"apply_v7_c_divergence: patched {len(patch)} bins, {total:,} bytes "
          f"({total * 100.0 / 2097152:.2f}% of the v7 ROM has no source)")


if __name__ == '__main__':
    main()
