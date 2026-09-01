#!/usr/bin/env python3
"""measure_lane_cust_ic19_debt.py -- lane CUST (2026-09-01), KN5000 custom data (IC19).

QUESTION ANSWERED: the lane brief quotes "roughly 639,296 bytes handed back verbatim with no C
source at all" for custom_data/kn5000_custom_data.s. Is that the right instrument for debt, per
BRIEF-2026-09-01.md's own warning ("`.incbin` count alone is the WRONG instrument... Measure
bytes, not directives")? And after the fix this session made to scripts/build/style_events.py
(cells_of() now also matches a second, 0x00-marked cell shape), how much is left unclassified?

ANSWER, measured below and reproduced by this script:

  * "0 bytes clang-compiled" is not evidence of debt by itself: this ROM is pure DATA, built with
    llvm-mc directly, like table_data/ and hdae5000/ -- there is no C source for a flash chip that
    holds no code to begin with.
  * scripts/analysis/audit_incbin_legitimacy.py, the project's OWN cross-tree audit, already
    classifies every `section_*` .incbin in custom_data/kn5000_custom_data.s as "style bank
    rebuilt from committed .styles" -- a justified, non-debt category, same footing as the
    hdae5000/table_data PNG-sourced images.
  * The 639,296 .incbin bytes are not an opaque COMMITTED blob: `custom_data/includes/*.bin` is
    gitignored (`custom_data/includes/section_*.bin`) and is regenerated at every build by
    `style_events.py build` from the committed, human-readable `custom_data/styles/*.styles`
    files -- non-circularly: `style_events.py verify` reconstructs all four banks and diffs them
    against the ORIGINAL ROM dump, not against the .bin.
  * What the .styles text itself still leaves unclassified (an L1 territory gap, not an L0 gap)
    is the number worth taking, block by block: CELL (music event stream, decoded under the
    grammar in docs/accompaniment-style-format.md), HEADER_DIR (the "H.K." header + 30x96B style
    directory -- ALSO typed directly as .byte in kn5000_custom_data.s, so a duplicate view, not
    new debt), ERASED_FF / ZERO_FILL padding (proven by exhaustive byte check), and UNCLASSIFIED
    (everything else -- the honest residue).

RUN
    python3 scripts/lanes/measure_lane_cust_ic19_debt.py
"""
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO / 'scripts' / 'build'))
import style_events as se  # noqa: E402  (path set up above)

HEADER_DIR_BYTES = 96 + 30 * 96  # "H.K." header + 30 style-directory records, 96 B each = 2976


def classify(sec, d):
    """Return byte counts per territory for one bank's raw bytes `d`."""
    cell = header_dir = erased_ff = zero_fill = other = 0
    hks = list(se.hk_sections(d))
    # hk_sections() only yields FROM the first "H\x00K\x00" magic onward. section_1_2/3_4/5_6
    # each have one at the block's own start -- proven erased (all 0xFF), an unused sector gap
    # ahead of section 1/3/5's real start at ROM offset base+0x800 (matches the pointer table in
    # kn5000_custom_data.s's header comment, e.g. section 1 = 0x319800 = base 0x319000 + 0x800).
    lead = hks[0][0] if hks else len(d)
    for off in range(0, lead, 256):
        b = d[off:off + 256]
        if all(x == 0xFF for x in b):
            erased_ff += 256
        elif all(x == 0 for x in b):
            zero_fill += 256
        else:
            other += 256
    for s, e in hks:
        cells = set(se.cells_of(d, s, e))
        cell += len(cells) * 256
        hdr_end = s + HEADER_DIR_BYTES  # the header+directory span, byte-exact, from the ROM's
        # own "H\x00K\x00" magic at `s` -- not a guess about which blocks it lands in.
        for off in range(s, e, 256):
            if off in cells:
                continue
            b = d[off:off + 256]
            if off < hdr_end:
                header_dir += 256
            elif all(x == 0xFF for x in b):
                erased_ff += 256
            elif all(x == 0 for x in b):
                zero_fill += 256
            else:
                other += 256
    return cell, header_dir, erased_ff, zero_fill, other


def main():
    incbin_bytes = 0
    for line in (REPO / 'custom_data' / 'kn5000_custom_data.s').read_text().splitlines():
        s = line.strip()
        if s.startswith('.incbin') and 'section_' in s:
            s = s.split(';', 1)[0]  # strip a trailing "; 0x300000-0x316FFF (92KB)" comment
            parts = [p.strip() for p in s.split(',')]
            incbin_bytes += int(parts[-1].split()[0], 0)
    print(f".incbin bytes in custom_data/kn5000_custom_data.s (the lane's headline figure): "
          f"{incbin_bytes:,}")
    print(f"original_ROMs/kn5000_custom_data.ic19 total size: {se.ROM.stat().st_size:,}\n")

    print("L0 (non-circular reproduction) -- style_events.py verify:")
    r = subprocess.run([sys.executable, str(REPO / 'scripts' / 'build' / 'style_events.py'),
                         'verify'], capture_output=True, text=True, cwd=REPO)
    print('  ' + '\n  '.join(r.stdout.strip().splitlines()))
    if r.returncode != 0:
        sys.exit("verify FAILED -- the .styles source does not reproduce the ROM; stop here")
    print()

    print("L1 (territory, measured straight from the ROM with the SAME cells_of() the build uses):")
    tot = [0, 0, 0, 0, 0]
    for sec, (off, ln) in se.SECTIONS.items():
        d = se.ROM.read_bytes()[off:off + ln]
        row = classify(sec, d)
        tot = [a + b for a, b in zip(tot, row)]
        cell, hdr, ff, zero, other = row
        print(f"  {sec:<14} CELL {cell:7,}  HEADER_DIR {hdr:6,}  ERASED_FF {ff:6,}  "
              f"ZERO_FILL {zero:6,}  UNCLASSIFIED {other:6,}")
    cell, hdr, ff, zero, other = tot
    grand = sum(tot)
    print(f"  {'TOTAL':<14} CELL {cell:7,}  HEADER_DIR {hdr:6,}  ERASED_FF {ff:6,}  "
          f"ZERO_FILL {zero:6,}  UNCLASSIFIED {other:6,}")
    want = sum(ln for _, ln in se.SECTIONS.values())
    assert grand == want, f"territory partition {grand:,} != style area size {want:,}"
    print(f"\n  {grand:,} bytes partitioned exactly (style area total). "
          f"UNCLASSIFIED: {other:,} bytes ({other / grand * 100:.3f}%).")
    print("  See docs/accompaniment-style-format.md, 'A second cell marker (2026-09-01)', for")
    print("  what CELL/HEADER_DIR/UNCLASSIFIED are and the evidence behind each.")


if __name__ == '__main__':
    main()
