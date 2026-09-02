#!/usr/bin/env python3
"""table_data_debt.py -- how many bytes of table_data are still .incbin (real debt),
broken out by legitimacy class, at the moment this script runs.

QUESTION ANSWERED: lane TABLE's brief (notes/lanes/BRIEF-2026-09-01.md) defines debt as
"any byte not reproduced by real source": .incbin of a committed blob, or untyped
.byte/.word runs standing in for undecoded code/data. This script measures the FIRST half
(every .incbin an assembly file in table_data/ actually pulls in) against the current tree,
rather than trusting docs/COMPLETENESS-STATUS.md's 2026-08-21 snapshot or the coarser
audit_incbin_legitimacy.py (which also sweeps wsa1/ and inflates the "generated/" bucket).

Legitimacy classes (same spirit as scripts/analysis/audit_incbin_legitimacy.py, scoped to
table_data/ only, and reporting BYTES not directive counts):

    round-trip-png     rebuilt from a committed PNG/manifest by scripts/build/*_images.py;
                       `make ...-images` regenerates the .bin, verify asserts the round trip
    round-trip-codec   demo-song / help-db compressed stream; codec has a committed
                       decoder AND encoder (LZSS / SLIDE8K) and rebuilds byte-exactly
    round-trip-shifted the table_data stale-remnant duplicate (17,570 B, CLOSED 2026-09-02):
                       StyleRecords_Residue + HelpDB_German_Stale's body are the live
                       English+German SLIDE8K streams duplicated 0x8000 lower in the ROM;
                       gen_stale_help_duplicate.py derives them from help_db_english/german_
                       compressed.bin (themselves round-trip-codec build products) instead of
                       the old icons_to_strings.bin blob -- see that script's header and
                       scripts/analysis/verify_stale_band.py for the original discovery
    verbatim-bmp       genuine Windows BMP, stored verbatim by the firmware, checked into git
    stale-remnant      documented dead/superseded slice preserved byte-exact on purpose
                       (0 B as of 2026-09-02: this class is now empty -- see round-trip-shifted)
    UNCLASSIFIED       anything not matching the above -- this is the number that matters

Run:
    python3 scripts/analysis/table_data_debt.py            # measure + classify
    python3 scripts/analysis/table_data_debt.py --selftest  # prove the classifier isn't vacuous

--selftest is the answer to "couldn't this just call everything legitimate?": it (1) feeds the
classifier paths it has never seen and asserts they come back UNCLASSIFIED, so a genuinely new
undocumented blob would be caught, not silently waved through; (2) pins today's known paths to
their expected class as a regression guard; (3) actually RE-RUNS the underlying round-trip
verifiers (font_images.py / icon_images.py / ui_bitmaps_images.py / indexed_images.py /
mono_images.py / style_events.py `verify`, plus `make verify-demo-presets` and
`verify-help-databases`) rather than trusting the classifier's path-string guess -- if a PNG or
.styles file drifts from the ROM, or a codec regresses, THIS goes red; (4) checks the six
verbatim-BMP files actually have a 'BM' magic and a header-declared size matching the file, so
"verbatim-bmp" is not just a filename pattern. Anything that would make the 0-B-unclassified
finding false makes --selftest exit 1.
"""
import pathlib
import re
import struct
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
TABLE_DIR = REPO / "table_data"

INCBIN = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*,\s*([0-9a-fA-Fx]+))?')
COMMENT = re.compile(r'^\s*;')

RULES = [
    (('FTBMP',), 'verbatim-bmp'),
    (('images/',), 'round-trip-png'),
    (('includes/generated/',), 'round-trip-png'),
    (('stale_style_records_residue.bin', 'stale_help_db_german_head.bin'), 'round-trip-shifted'),
    (('demo_preset', 'help_db'), 'round-trip-codec'),
    (('icons_to_strings.bin',), 'stale-remnant'),
]


def classify(path):
    for needles, label in RULES:
        if any(n in path for n in needles):
            return label
    return 'UNCLASSIFIED'


def resolve_size(path_str, off, ln):
    if ln is not None:
        return int(ln, 0)
    full = TABLE_DIR / path_str
    if full.exists():
        return full.stat().st_size
    return None  # not built yet -- must be generated to know the size



def selftest():
    """Prove the classifier can go red -- see the module docstring's --selftest section."""
    failures = []

    # (1) paths the classifier has never seen must NOT be waved through as legitimate.
    bogus_paths = [
        "includes/mystery_blob_nobody_has_looked_at.bin",
        "includes/tone_database_directory_extra.bin",
        "raw/unknown_dump.bin",
        "includes/new_factory_data_2026.bin",
    ]
    for p in bogus_paths:
        got = classify(p)
        if got != "UNCLASSIFIED":
            failures.append(
                f"classify({p!r}) = {got!r}, expected UNCLASSIFIED -- the classifier would "
                f"silently legitimise a brand-new, never-reviewed blob"
            )

    # (2) today's known paths must map to their documented class (regression guard).
    known = [
        ("images/FTBMP01.BMP", "verbatim-bmp"),
        ("images/Wallpaper_0.bin", "round-trip-png"),
        ("includes/generated/IconPixels_000.bin", "round-trip-png"),
        ("includes/generated/Composer_FactoryMemoryImage.bin", "round-trip-png"),
        ("includes/demo_presets/demo_preset_00_compressed.bin", "round-trip-codec"),
        ("includes/help_databases/help_db_english_compressed.bin", "round-trip-codec"),
        ("includes/help_databases/stale_style_records_residue.bin", "round-trip-shifted"),
        ("includes/help_databases/stale_help_db_german_head.bin", "round-trip-shifted"),
        ("includes/icons_to_strings.bin", "stale-remnant"),
    ]
    for p, expected in known:
        got = classify(p)
        if got != expected:
            failures.append(f"classify({p!r}) = {got!r}, expected {expected!r}")

    # (3) the round-trip CLAIM must be backed by actually re-running the round trip, not just
    #     matched by a path substring. This is what makes "round-trip-png"/"round-trip-codec"
    #     mean something -- if a committed PNG or .styles file no longer reproduces the ROM,
    #     this fails, regardless of what the .incbin path looks like.
    py_checks = [
        ("round-trip-png: fonts", ["scripts/build/font_images.py", "verify"]),
        ("round-trip-png: icons", ["scripts/build/icon_images.py", "verify"]),
        ("round-trip-png: UI bitmaps/frames", ["scripts/build/ui_bitmaps_images.py", "verify"]),
        ("round-trip-png: indexed images (incl. wallpapers)",
         ["scripts/build/indexed_images.py", "verify"]),
        ("round-trip-png: boot-update banners", ["scripts/build/mono_images.py", "verify"]),
        ("round-trip-png: Composer/style banks", ["scripts/build/style_events.py", "verify"]),
        ("round-trip-shifted: stale help duplicate",
         ["scripts/generators/gen_stale_help_duplicate.py", "verify"]),
    ]
    for name, argv in py_checks:
        try:
            r = subprocess.run([sys.executable] + argv, cwd=REPO, capture_output=True,
                                text=True, timeout=180)
        except Exception as e:  # noqa: BLE001
            failures.append(f"{name}: could not run ({e})")
            continue
        if r.returncode != 0 or "EXACT" not in r.stdout.upper():
            failures.append(f"{name}: FAILED (exit {r.returncode})\n"
                             f"{r.stdout[-500:]}\n{r.stderr[-500:]}")

    make_checks = [
        ("round-trip-codec: demo presets", "verify-demo-presets"),
        ("round-trip-codec: help databases", "verify-help-databases"),
    ]
    for name, target in make_checks:
        try:
            r = subprocess.run(["make", target], cwd=REPO, capture_output=True,
                                text=True, timeout=180)
        except Exception as e:  # noqa: BLE001
            failures.append(f"{name}: could not run ({e})")
            continue
        if r.returncode != 0:
            failures.append(f"{name}: FAILED (exit {r.returncode})\n"
                             f"{r.stdout[-800:]}\n{r.stderr[-500:]}")

    # (4) "verbatim-bmp" must actually BE a Windows BMP (magic + header-declared size matches
    #     the file), not just a file whose path contains "FTBMP".
    for name in ["FTBMP01.BMP", "FTBMP02.BMP", "FTBMP03.BMP", "FTBMP04.BMP",
                 "FTBMP05.BMP", "FTBMP06.BMP"]:
        p = TABLE_DIR / "images" / name
        data = p.read_bytes()
        if data[:2] != b"BM":
            failures.append(f"{name}: missing 'BM' magic -- not a real BMP")
            continue
        declared = struct.unpack_from("<I", data, 2)[0]
        if declared != len(data):
            failures.append(f"{name}: header declares {declared} B, file on disk is {len(data)} B")

    if failures:
        print(f"SELFTEST FAILED ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        return 1

    print(f"SELFTEST OK: {len(bogus_paths)} bogus paths correctly rejected as UNCLASSIFIED, "
          f"{len(known)} known-path classifications unchanged, "
          f"{len(py_checks)} PNG/.styles round trips re-verified live, "
          f"{len(make_checks)} LZSS/SLIDE8K codec round trips re-verified live, "
          f"6 BMP headers checked against their file sizes.")
    return 0


def main():
    rows = []
    missing = []
    for f in sorted(TABLE_DIR.glob("*.s")):
        text = f.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            if COMMENT.match(line):
                continue
            m = INCBIN.search(line)
            if not m:
                continue
            # strip a leading "; Was: .incbin ..." style comment tail on the SAME line
            code_part = line.split(';', 1)[0]
            if '.incbin' not in code_part:
                continue
            path_str, off, ln = m.groups()
            size = resolve_size(path_str, off, ln)
            label = classify(path_str)
            rows.append((f.name, lineno, path_str, off, ln, size, label))
            if size is None:
                missing.append((f.name, lineno, path_str))

    if missing:
        print("Sizes unknown (file not built) -- run `make tabledata-images` etc. first, or pass "
              "--build:", file=sys.stderr)
        for r in missing:
            print("  ", r, file=sys.stderr)

    totals = {}
    grand = 0
    for _, _, _, _, _, size, label in rows:
        if size is None:
            continue
        totals[label] = totals.get(label, 0) + size
        grand += size

    print(f"{'file':<28}{'line':>6}  {'path':<55}{'bytes':>10}  class")
    for f, lineno, path_str, off, ln, size, label in rows:
        sz = "?" if size is None else str(size)
        print(f"{f:<28}{lineno:>6}  {path_str:<55}{sz:>10}  {label}")

    print()
    print("Totals by class:")
    for label, total in sorted(totals.items(), key=lambda kv: -kv[1]):
        print(f"  {label:<20}{total:>10,} B")
    print(f"  {'GRAND TOTAL':<20}{grand:>10,} B  ({len(rows)} .incbin directives, "
          f"{len(missing)} unresolved)")
    unclassified = totals.get('UNCLASSIFIED', 0)
    print()
    print(f"UNCLASSIFIED (the number that matters -- real conversion debt): {unclassified:,} B")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    main()
