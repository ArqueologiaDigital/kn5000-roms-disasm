#!/usr/bin/env python3
r"""icon_pixel_pair_table_retype.py -- type DrawIcons_PixelPairTable in naka_disk_warning.c and head its slice.

QUESTION ANSWERED
-----------------
naka_disk_warning +0x1F46..+0x2146 (512 B) was generic members (a run of uint16 field_* in the C), labelled
DrawIcons_Impl_ColLoop_Data in the asm with a [nakarest] "purpose not established" note.  Its one reader,
DrawIcons_Impl (ui/drawing_primitives.s), walks a 24 x 24 icon of 12 bytes per row.  For every byte it does
`ld wa, (<this> + 2*byte); ld (xix), wa`: two 8-bit pixels into the offscreen buffer.  So entry b is the colour
pair of the two 4-bpp pixels in b, high nibble first (the left pixel), each nibble n mapped to n when n < 8,
else to 0xF0 + n (asserted for all 256 entries).  This script:
  * types the slice as `uint8_t DrawIcons_PixelPairTable[256][2]` (each tree's own bytes);
  * renames the asm label DrawIcons_Impl_ColLoop_Data -> DrawIcons_PixelPairTable (its reader too);
  * replaces the [nakarest] note with a header.

RUN (repository root, built tree)
    python3 scripts/converters/icon_pixel_pair_table_retype.py [--apply]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

START, COUNT = 0x1F46, 256
OLD, NEW = "DrawIcons_Impl_ColLoop_Data", "DrawIcons_PixelPairTable"
HEADER = [
    "; DrawIcons_PixelPairTable -- 256 x {u8 left, u8 right}: the two colour indices of the two 4-bpp pixels in one",
    "; icon byte (high nibble = left pixel), nibble n -> n for n < 8, else 0xF0 + n.  DrawIcons_Impl writes",
    "; entry [byte] as one word per icon byte, 12 bytes x 24 rows: a 24 x 24 icon.  Typed in",
    "; ui_widgets/naka_disk_warning.c (scripts/converters/icon_pixel_pair_table_retype.py).",
]


def colour(n):
    return n if n < 8 else 0xF0 + n


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_disk_warning.c")
        b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_disk_warning.bin"), "rb").read()
        pairs = [(b[START + 2 * i], b[START + 2 * i + 1]) for i in range(COUNT)]
        assert all(p == (colour(i >> 4), colour(i & 15)) for i, p in enumerate(pairs)), tree
        if NEW not in open(c, encoding="latin-1").read():
            cb = M.CBlob(c)
            sym = [mb.name for mb in cb.members if START <= mb.offset < START + 2 * COUNT
                   and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
            assert not sym, sym
            rows = []
            for r in range(0, COUNT, 8):
                rows.append("        " + " ".join("{0x%02X, 0x%02X}," % pairs[i] for i in range(r, r + 8))
                            + "  /* 0x%02X.. */" % r)
            new = [M.NewMember("uint8_t", NEW, "[%d][2]" % COUNT, 2 * COUNT, "{\n" + "\n".join(rows) + "\n    }",
                               ["    /* DrawIcons_PixelPairTable: [icon byte] -> {left, right} colour index of its two"
                                " 4-bpp pixels, nibble n -> n (n < 8) or 0xF0 + n; read by DrawIcons_Impl"
                                " (ui/drawing_primitives.s) */"])]
            cb.retype(START, START + 2 * COUNT, new, b)
            print(tree, "C typed")
            if apply:
                data = cb.render().encode("latin-1")
                open(c + ".tmp", "wb").write(data)
                os.replace(c + ".tmp", c)
        for rel in ("ui_widgets/disk_warning_strings.s", "ui/drawing_primitives.s"):
            p = os.path.join(ROOT, tree, "maincpu", rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changed = False
            if rel.endswith("disk_warning_strings.s") and OLD + ":" in L:
                k = L.index(OLD + ":")
                j = k
                while L[j - 1].startswith("; [nakarest]"):
                    j -= 1
                assert k - j >= 3 and L[k + 1].startswith('\t.incbin "includes/generated/naka_disk_warning.bin", 0x1F46'), \
                    (tree, L[k + 1])
                L[j:k + 1] = HEADER + [NEW + ":"]
                changed = True
            for i, line in enumerate(L):
                nl = re.sub(r'\b%s\b' % OLD, NEW, line)
                if nl != line:
                    L[i] = nl
                    changed = True
            if changed:
                print(tree, rel, "asm updated")
                if apply:
                    data = "\n".join(L).encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
