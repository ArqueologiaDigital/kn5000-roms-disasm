#!/usr/bin/env python3
"""Convert NAKA widget header .byte patterns to naka_header macro calls.

Replaces `.byte 0xXX, 0x00, 0x60, 0x01` with `naka_header NAKA_TYPE_XXX`
for all 9 known widget type bytes in the maincpu program source.

When the header bytes appear on the same line as body bytes, splits the line:
the macro call goes on its own line, remaining bytes become a new .byte line.
"""

import re
import sys

# Map type byte values to EQU constant names
TYPE_MAP = {
    0x1e: "NAKA_TYPE_PANEL",
    0x2b: "NAKA_TYPE_LABEL",
    0x2e: "NAKA_TYPE_VALUE",
    0x2f: "NAKA_TYPE_OPTION",
    0x30: "NAKA_TYPE_SLIDER",
    0x31: "NAKA_TYPE_GROUP",
    0x34: "NAKA_TYPE_CONTAINER",
    0x66: "NAKA_TYPE_LIST",
    0x6c: "NAKA_TYPE_BITMAP",
}

# Build regex pattern matching any of the 9 type bytes
# Matches: .byte 0xXX, 0x00, 0x60, 0x01 possibly followed by more bytes
type_hex = "|".join(f"0x{t:02x}" for t in TYPE_MAP)
# Match the full .byte directive, capturing header and any trailing bytes
PATTERN = re.compile(
    r"(\t)\.byte (" + type_hex + r"), 0x00, 0x60, 0x01"
    r"(, .+)?"  # optional trailing bytes
)


def convert_line(line_bytes):
    """Convert a single line (as bytes). Returns list of output lines (as bytes)."""
    line = line_bytes.decode("latin-1")

    m = PATTERN.search(line)
    if not m:
        return [line_bytes]

    indent = m.group(1)
    type_str = m.group(2)
    trailing = m.group(3)  # e.g. ", 0x05, 0x00, 0xff, 0xff" or None
    type_val = int(type_str, 16)
    name = TYPE_MAP[type_val]

    # Build macro line (preserve any label prefix before the .byte)
    prefix = line[:m.start()]
    after = line[m.end():]  # anything after the match (comments, etc.)

    macro_line = f"{prefix}{indent}naka_header {name}"

    result = []
    if trailing:
        # Split: macro on one line, remaining bytes on the next
        # trailing starts with ", " so strip that
        rest_bytes = trailing[2:]  # remove leading ", "
        result.append(macro_line.encode("latin-1"))
        body_line = f"{indent}.byte {rest_bytes}{after}"
        result.append(body_line.encode("latin-1"))
    else:
        result.append((macro_line + after).encode("latin-1"))

    return result


def main():
    src = "maincpu/kn5000_v10_program.s"
    if len(sys.argv) > 1:
        src = sys.argv[1]

    with open(src, "rb") as f:
        data = f.read()

    lines = data.split(b"\n")
    count = 0
    new_lines = []

    for line_bytes in lines:
        converted = convert_line(line_bytes)
        if len(converted) != 1 or converted[0] != line_bytes:
            count += 1
        new_lines.extend(converted)

    with open(src, "wb") as f:
        f.write(b"\n".join(new_lines))

    print(f"Converted {count} NAKA widget headers in {src}")


if __name__ == "__main__":
    main()
