#!/usr/bin/env python3
r"""text_tables_retype.py -- type the text renderer's style->font and character->glyph tables (naka_disk_warning.c).

QUESTION ANSWERED
-----------------
Two 256-byte slices of naka_disk_warning had [nakarest] "purpose not established" notes and generic C members:
  +0x2358  Scoop_EnvelopeCalc_Data_2.  Its readers (DrawText_ExtLayout_NullAndDraw, DrawFunc_Init_Join2 / _Join3,
           DrawFunc_Init_PushFontAndDraw, ... in display/graphics_text_vga.s) do `ld a, (record+6); and a, 0x3f;
           sla wa, 2; ld xbc, (<this>+wa)` and pass xbc to DrawText_QueueOrDirect as the font.  So it is 64 x u32
           text style -> font index (table_data/fonts.s), every value a font 0-9 (asserted).  In v10:
           style 7 -> 1, 8 -> 2, 32 -> 6, the rest 0.  Name: TextStyle_FontTable.
  +0x2508  TextRender_CharEncodeAndDraw_Data.  FontGlyph_ByteData does `out = <this>[in]`, and its neighbour
           (SeMenu_CopyWriteUpdate_Step3_Helper18) searches the table for a glyph and returns the index (space
           when absent).  So it is the 256-entry character code -> font glyph code map: printable ASCII to
           itself (asserted for 0x21-0x5B and 0x5D-0x7D; 0x5C '\' -> 0xA5), 0x10-0x1F to UI-symbol glyphs,
           0x80-0xAB to the Latin-1 letters of the fonts' accent page.  Name: Text_CharGlyphMap.
Per tree (each tree's own bytes): the slice is typed in C, the asm label renamed everywhere in the tree, and a
header replaces the [nakarest] note.

RUN (repository root, built tree)
    python3 scripts/converters/text_tables_retype.py [--apply]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

TABLES = [
    dict(start=0x2358, size=0x100, old="Scoop_EnvelopeCalc_Data_2", new="TextStyle_FontTable",
         header=["; TextStyle_FontTable -- 64 x u32, text style (record byte & 0x3f) -> font index (table_data/fonts.s);",
                 "; the readers in display/graphics_text_vga.s pass the entry to DrawText_QueueOrDirect as the font.",
                 "; Typed in ui_widgets/naka_disk_warning.c (scripts/converters/text_tables_retype.py)."],
         cdoc="TextStyle_FontTable: text style (& 0x3f) -> font index passed to DrawText_QueueOrDirect"
              " (read in display/graphics_text_vga.s)"),
    dict(start=0x2508, size=0x100, old="TextRender_CharEncodeAndDraw_Data", new="Text_CharGlyphMap",
         header=["; Text_CharGlyphMap -- 256 x u8, character code -> font glyph code: ASCII to itself except '\\' -> 0xA5,",
                 "; 0x10-0x1F to UI-symbol glyphs, 0x80-0xAB to the Latin-1 letters of the fonts' accent page.",
                 "; FontGlyph_ByteData maps through it; the routine after it searches it for the reverse.",
                 "; Typed in ui_widgets/naka_disk_warning.c (scripts/converters/text_tables_retype.py)."],
         cdoc="Text_CharGlyphMap: character code -> font glyph code (FontGlyph_ByteData,"
              " display/graphics_text_vga.s)"),
]


def member(t, b):
    s = t["start"]
    if t["new"] == "TextStyle_FontTable":
        v = [int.from_bytes(b[s + 4 * i:s + 4 * i + 4], "little") for i in range(64)]
        assert all(x <= 9 for x in v), v
        rows = ["        " + " ".join("%d," % v[i] for i in range(r, r + 16)) + "  /* styles %d.. */" % r
                for r in range(0, 64, 16)]
        return M.NewMember("uint32_t", t["new"], "[64]", 256, "{\n" + "\n".join(rows) + "\n    }",
                           ["    /* %s */" % t["cdoc"]])
    v = list(b[s:s + 256])
    assert all(v[c] == c for c in list(range(0x21, 0x5C)) + list(range(0x5D, 0x7E))), "not ASCII-identical"
    rows = ["        " + " ".join("0x%02X," % v[i] for i in range(r, r + 16)) + "  /* 0x%02X.. */" % r
            for r in range(0, 256, 16)]
    return M.NewMember("uint8_t", t["new"], "[256]", 256, "{\n" + "\n".join(rows) + "\n    }",
                       ["    /* %s */" % t["cdoc"]])


def font_table(cb, b, t):
    """The generic decode's `uint32_t ptrs_22[68]` runs from the last 4 bytes of the Pad_AfterStr_No slice through
    both GraphicsRender op tables and the six text clip boxes into the first 7 words of the font table, so
    the whole stretch is retyped as its parts.  The op tables keep ptrs_22's own element expressions (NAKA_ADDR
    or the number), so every byte stays as it was."""
    k = cb.index_at(t["start"])
    pm = cb.members[k]
    assert pm.name.startswith("ptrs_") and pm.ctype == "uint32_t", pm.name
    o = pm.offset
    assert o <= 0x2268 and (0x2268 - o) % 4 == 0 and t["start"] < o + pm.size <= t["start"] + t["size"], (o, pm.size)
    body = cb.entries[cb.by_name[pm.name]].expr.strip()
    assert body.startswith("{") and body.endswith("}"), body[:40]
    els = [re.sub(r'/\*.*?\*/', '', x).strip() for x in M.split_top_level(body[1:-1])]
    els = [x for x in els if x]
    assert len(els) == pm.size // 4, (len(els), pm.size)
    w0 = (0x2268 - o) // 4

    def rows(xs, per):
        return "{\n" + "\n".join("        " + " ".join(x + "," for x in xs[i:i + per]) for i in range(0, len(xs), per)) \
            + "\n    }"
    new = []
    if o < 0x2268:
        new.append(M.NewMember("uint8_t", "Pad_AfterStr_No_Tail", "[%d]" % (0x2268 - o), 0x2268 - o,
                               "{" + ", ".join("0x%02X" % x for x in b[o:0x2268]) + "}",
                               ["    /* Pad_AfterStr_No_Tail: the last bytes of the asm slice Pad_AfterStr_No */"]))
    new.append(M.NewMember("uint32_t", "GraphicsRender_ProcessEntries_PtrTable", "[36]", 144,
                           rows(els[w0:w0 + 36], 4),
                           ["    /* GraphicsRender_ProcessEntries_PtrTable: the static display-record handler of each op"
                            " (scripts/tools/label_segfx_ops.py) */"], keeps=(pm.name,)))
    new.append(M.NewMember("uint32_t", "GraphicsRender_Start_PtrTable", "[12]", 48,
                           rows(els[w0 + 36:w0 + 48], 4),
                           ["    /* GraphicsRender_Start_PtrTable: the bound display-record handler of each op */"],
                           keeps=(pm.name,)))
    boxes = [tuple(int.from_bytes(b[0x2328 + 8 * i + 2 * j:0x2328 + 8 * i + 2 * j + 2], "little") for j in range(4))
             for i in range(6)]
    assert all(x == (0, 0, 319, 239) for x in boxes), boxes
    new.append(M.NewMember("uint16_t", "SeGfx_TextClipBoxes", "[6][4]", 48,
                           "{\n" + "\n".join("        {%d, %d, %d, %d}," % x for x in boxes) + "\n    }",
                           ["    /* SeGfx_TextClipBoxes: {x0, y0, x1, y1} copied by the six text handlers (static ops 06,"
                            " 07, 08, 17, 1C, 20): the full screen */"]))
    new.append(member(t, b))
    cb.retype(o, t["start"] + t["size"], new, b)


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_disk_warning.c")
        b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_disk_warning.bin"), "rb").read()
        text = open(c, encoding="latin-1").read()
        todo = [t for t in TABLES if t["new"] not in text]
        if todo:
            cb = M.CBlob(c)
            for t in todo:
                if t["new"] == "TextStyle_FontTable":
                    font_table(cb, b, t)
                    print(tree, t["new"], "C typed (with the op tables and clip boxes before it)")
                    continue
                sym = [mb.name for mb in cb.members if t["start"] <= mb.offset < t["start"] + t["size"]
                       and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
                assert not sym, (tree, t["new"], sym)
                cb.retype(t["start"], t["start"] + t["size"], [member(t, b)], b)
                print(tree, t["new"], "C typed")
            if apply:
                data = cb.render().encode("latin-1")
                open(c + ".tmp", "wb").write(data)
                os.replace(c + ".tmp", c)
        root = os.path.join(ROOT, tree, "maincpu")
        for dp, _, fs in os.walk(root):
            for f in fs:
                if not f.endswith(".s"):
                    continue
                p = os.path.join(dp, f)
                L = open(p, "rb").read().decode("latin-1").split("\n")
                changed = False
                for t in TABLES:
                    if t["old"] + ":" in L:
                        k = L.index(t["old"] + ":")
                        j = k
                        while L[j - 1].startswith("; [nakarest]"):
                            j -= 1
                        assert k - j >= 3 and ("0x%X, 0x100" % t["start"]) in L[k + 1], (tree, p, L[k + 1])
                        L[j:k + 1] = t["header"] + [t["new"] + ":"]
                        changed = True
                for i, line in enumerate(L):
                    nl = line
                    for t in TABLES:
                        nl = re.sub(r'\b%s\b' % t["old"], t["new"], nl)
                    if nl != line:
                        L[i] = nl
                        changed = True
                if changed:
                    print(tree, os.path.relpath(p, root), "asm updated")
                    if apply:
                        data = "\n".join(L).encode("latin-1")
                        open(p + ".tmp", "wb").write(data)
                        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
