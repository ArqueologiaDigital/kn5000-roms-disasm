#!/usr/bin/env python3
"""audit_incbin_legitimacy.py -- is every .incbin in this tree a JUSTIFIED one?

QUESTION ANSWERED: §3 of DISASSEMBLY-COMPLETENESS-SPEC.md says a binary include is legitimate
only when the bytes have no better human-readable representation. This checks that claim instead
of leaving it to memory, and FAILS if an unclassified include appears.

Categories, and why each is legitimate:

    generated/ or romslices/   built by a committed generator, or a committed slice that is
                               honestly documented as having no source (v7's 288)
    demo_preset / help_db      compressed streams whose codec has a committed DECODER **and**
                               ENCODER and rebuilds byte-exactly
    images/                    rebuilt from a committed PNG or palette text by one of the
                               round-trip converters in scripts/build/
    section_*                  style banks rebuilt from committed .styles event listings
    FTBMP                      genuine Windows BMP files, stored verbatim by the firmware
    icons_to_strings.bin       two SLIDE8K-compressed remnants (the stale German help DB, and
                               the copy of the English DB's tail that style_records.s calls
                               residue) -- compressed, documented, legitimately opaque

TWO METHODOLOGY TRAPS, both hit while writing this, both worth keeping:

  * `.incbin` also appears inside COMMENTS -- this tree deliberately keeps `; Was: .incbin ...`
    lines recording what a directive used to be. Counting raw matches reports ten hdae5000
    includes that do not exist.
  * a directive is frequently written on a LABEL LINE (`Font0_Glyphs:\t.incbin "..."`), so a
    regex anchored at line start misses 382 of the 873.

    python3 scripts/analysis/audit_incbin_legitimacy.py
"""
import pathlib
import re
import sys
from collections import Counter

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
INC = re.compile(r'\.incbin\s+"([^"]+)"')
RULES = [
    (('generated/', 'romslices/'), 'generated or committed no-source slice'),
    (('demo_preset', 'help_db'), 'compressed, codec has a committed encoder'),
    (('FTBMP',), 'genuine Windows BMP stored verbatim'),
    (('images/',), 'rebuilt from a committed PNG or palette text'),
    (('section_',), 'style bank rebuilt from committed .styles'),
    (('icons_to_strings.bin',), 'SLIDE8K remnant, compressed and documented'),
]


def main():
    rows, kind, other = [], Counter(), []
    for s in REPO.rglob('*.s'):
        rel = s.relative_to(REPO).as_posix()
        if rel.startswith('archive/'):
            continue
        for line in s.read_bytes().decode('latin1').splitlines():
            if line.lstrip().startswith(';'):
                continue                      # a comment is not a directive
            m = INC.search(line)              # NOT match(): labels precede the directive
            if not m:
                continue
            p = m.group(1)
            rows.append((rel, p))
            for keys, label in RULES:
                if any(k in p for k in keys):
                    kind[label] += 1
                    break
            else:
                other.append((rel, p))
    print(f"active .incbin directives outside archive/: {len(rows)}\n")
    for k, v in kind.most_common():
        print(f"  {v:4d}  {k}")
    if other:
        print(f"\n*** {len(other)} UNCLASSIFIED -- each must be justified under §3 or converted:")
        for f, p in sorted(set(other)):
            print(f"    {f}: {p}")
        sys.exit(1)
    print("\nEvery include falls in a justified category: 0 illegitimate blob bytes.")


if __name__ == '__main__':
    main()
