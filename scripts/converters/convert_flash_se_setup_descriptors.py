#!/usr/bin/env python3
r"""Hand two ScreenData spans in flash_floppy_handlers.s back to their C source.

QUESTION IT ANSWERS
    `v10/maincpu/audio/sound_editor_screens/se_setup_editor_full.c` and
    `se_setup_sel4.c` are committed, named, typed C descriptors that compile
    byte-exact with `clang -target tlcs900`.  They were never wired into the
    build, so the 276 bytes they describe are carried in
    `storage/flash_floppy_handlers.s` as anonymous `.byte` rows instead:

        se_setup_editor_full  0xF1616F  266 B   (28 commands, named fields)
        se_setup_sel4         0xF1659F   10 B

    `.incbin` of a clang-compiled C struct is REAL SOURCE, not verbatim debt --
    the brief says so explicitly -- so this is a strict upgrade: untyped bytes
    become named, typed, documented fields, and the same C already serves v7,
    v9 and v10.

    ★ The script verifies the compiled .bin equals the ROM bytes at the stated
    address BEFORE touching the source, and refuses otherwise.  It also refuses
    if any label or comment sits inside a span, since `.incbin` cannot carry
    one.  A span rarely ends on a source-line boundary; the leftover bytes of
    the straddling line are re-emitted as `.byte`.

RUN
    make v10/maincpu/includes/generated/se_setup_editor_full.bin \
         v10/maincpu/includes/generated/se_setup_sel4.bin
    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/converters/convert_flash_se_setup_descriptors.py /tmp/amap.json [--dry-run]
"""
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = "v10/maincpu/storage/flash_floppy_handlers.s"
BASE = 0xE00000
ROM = open(os.path.join(REPO, "original_ROMs",
                        "kn5000_v10_program.rom"), "rb").read()

SPANS = [("se_setup_editor_full", 0xF1616F, 266),
         ("se_setup_sel4", 0xF1659F, 10)]

LABEL_RE = re.compile(r"^[A-Za-z_.$][\w.$]*:")

sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
from lane_v10storage_byte_split import tree_reference_kinds  # noqa: E402
DEFINED = set(tree_reference_kinds())


def main():
    amap = json.load(open(sys.argv[1]))
    dry = "--dry-run" in sys.argv
    ent = sorted((e["addr"], e["line"]) for e in amap if e["src"] == SRC)
    path = os.path.join(REPO, SRC)
    lines = open(path, encoding="latin-1").read().split("\n")

    # line -> (start addr, end addr) using the next distinct marker address
    extent = {}
    for i, (a, ln) in enumerate(ent):
        nxt = next((x for x, _ in ent[i + 1:] if x > a), None)
        if nxt is not None:
            extent[ln] = (a, nxt)

    edits = []
    for name, lo, size in SPANS:
        hi = lo + size
        got = open(os.path.join(REPO, "v10/maincpu/includes/generated",
                                name + ".bin"), "rb").read()
        want = ROM[lo - BASE:hi - BASE]
        if got != want or len(got) != size:
            sys.exit(f"REFUSING: {name}.bin does not equal the ROM at {lo:06X}")
        inside = [ln for ln, (a, b) in extent.items() if lo <= a < hi]
        inside.sort()
        first, last = inside[0], inside[-1]
        if extent[first][0] != lo:
            sys.exit(f"REFUSING: {name} does not start on a source line boundary")
        for ln in inside:
            body = lines[ln - 1]
            if LABEL_RE.match(body) or ";" in body:
                sys.exit(f"REFUSING: {SRC}:{ln} carries a label or comment "
                         f"that .incbin cannot hold")
            # Instruction lines are allowed -- part of this span is still
            # framed as fake code (`ld xix, 0x4d414e59` is the ASCII "MANY"),
            # and the .incbin is byte-verified against the ROM, so replacing
            # them loses nothing.  What must NOT be lost is a NAME: refuse if
            # any operand mentions a symbol defined anywhere in the tree.
            for w in re.findall(r'[A-Za-z_][A-Za-z0-9_]{2,}', body.split(";")[0]):
                if w in DEFINED:
                    sys.exit(f"REFUSING: {SRC}:{ln} names the symbol {w!r}, "
                             f"which .incbin cannot carry")
        tail_end = extent[last][1]
        new = [f'\t; {name}: {size} B at 0x{lo:06X}, compiled from '
               f'audio/sound_editor_screens/{name}.c',
               f'\t.incbin "includes/generated/{name}.bin"']
        if tail_end > hi:
            rest = ROM[hi - BASE:tail_end - BASE]
            new.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in rest)
                       + f"\t; {hi:06X} -- remainder of the source line the "
                         f"descriptor ends inside")
        edits.append((first, last, new, name, size, tail_end - hi))

    for first, last, new, name, size, tail in sorted(edits, reverse=True):
        print(f"  {name}: {size} B, source lines {first}..{last} "
              f"({last - first + 1} lines) -> {len(new)} lines"
              + (f", {tail} B tail re-emitted" if tail else ""))
        if not dry:
            lines[first - 1:last] = new
    if dry:
        for _, _, new, _, _, _ in edits:
            print("\n".join(new))
        return 0
    data = "\n".join(lines).encode("latin-1")
    tmp = path + ".tmp"
    open(tmp, "wb").write(data)
    os.replace(tmp, path)
    print(f"  rewrote {SRC}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
