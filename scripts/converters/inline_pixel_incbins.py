#!/usr/bin/env python3
"""inline_pixel_incbins.py -- replace single-line `Label: .incbin "..."` directives
with literal .byte data, for the round-trip-PNG pixel slices in table_data.

QUESTION ANSWERED: after scripts/converters/convert_wallpapers.py closed the two
wallpapers, table_data/{fonts,ui_bitmaps,kn5000_table_data}.s still pull in
307,086 B of PNG-regenerated pixel/glyph data via `.incbin`. Each directive
already sits on a single `Label:\t.incbin "path"\t; comment` line with a
verified round-trip (font_images.py / icon_images.py / ui_bitmaps_images.py
`verify`, plus style_events.py for Composer_FactoryMemoryImage and
mono_images.py for the boot banners). This script inlines every one of those
still-classified-as-round-trip-png blobs as literal `.byte` rows (16/line,
file-offset annotated), same convention as convert_wallpapers.py and the
pre-existing tone_database_records.s / style_records.s. The trailing
end-of-line comment (dimensions, notes) is preserved on the label line.

Deliberately excludes (by construction -- see table_data_debt.py classify()):
verbatim BMPs, LZSS/SLIDE8K compressed streams, and the stale SLIDE8K remnant.
Those resist for reasons recorded in table_data_debt.py's docstring and are
NOT touched by this script.

Usage:
    python3 scripts/converters/inline_pixel_incbins.py table_data/fonts.s [...]
    python3 scripts/converters/inline_pixel_incbins.py --check table_data/fonts.s
"""
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
TABLE_DIR = REPO / "table_data"

sys.path.insert(0, str(REPO / "scripts" / "analysis"))
import table_data_debt as tdd  # noqa: E402

LINE_RE = re.compile(
    r'^([A-Za-z_][A-Za-z0-9_]*):(\t+| +)\.incbin\s+"([^"]+)"(.*)$'
)


def convert_file(path: pathlib.Path, check_only: bool) -> int:
    text = path.read_text()
    lines = text.split('\n')
    out = []
    converted_bytes = 0
    converted_count = 0
    for line in lines:
        m = LINE_RE.match(line)
        if not m:
            out.append(line)
            continue
        label, _sep, incpath, rest = m.groups()
        label_class = tdd.classify(incpath)
        if label_class != 'round-trip-png':
            out.append(line)
            continue
        full = TABLE_DIR / incpath
        if not full.exists():
            print(f"SKIP {label}: {full} not built (run `make tabledata-images` / "
                  f"`make style-events` first)", file=sys.stderr)
            out.append(line)
            continue
        data = full.read_bytes()
        converted_bytes += len(data)
        converted_count += 1
        rest = rest.strip()
        header = f"{label}:\t{rest}" if rest else f"{label}:"
        out.append(header)
        for i in range(0, len(data), 16):
            chunk = data[i:i + 16]
            vals = ", ".join(f"0x{b:02x}" for b in chunk)
            out.append(f"\t.byte\t{vals}\t; +{i:04x}")
        if len(data) == 0:
            out.append("\t; (0 bytes)")
    new_text = '\n'.join(out)
    if converted_count == 0:
        return 0
    print(f"{path}: {converted_count} directive(s), {converted_bytes:,} bytes"
          f"{' (check only, not written)' if check_only else ''}")
    if not check_only:
        path.write_text(new_text)
    return converted_bytes


def main():
    argv = sys.argv[1:]
    check_only = '--check' in argv
    files = [a for a in argv if a != '--check']
    if not files:
        print(__doc__)
        return 1
    total = 0
    for f in files:
        total += convert_file(pathlib.Path(f), check_only)
    print(f"TOTAL: {total:,} bytes inlined")
    return 0


if __name__ == "__main__":
    sys.exit(main())
