#!/usr/bin/env python3
r"""style_name_override_retype.py -- the two style-name override tables, typed and named (v10/v9/v7).

QUESTION ANSWERED
-----------------
naka_style_bitmaps +0xAE2 (396 B) and +0xC6E (90 B) were "[nakarest]" slices, EffectMode_SearchPresetTableC2C5_Data
and EffectMode_SearchPresetTableC0_Data, read by two search routines of the same names (ui/ui_mode_handlers.s).
Each routine walks records of 18 bytes (`sll 3 / add / add` = 18 * index) for 22 resp. 5 entries
(`cp ix, 0x16` / `cp ix, 5`), compares the u16 at +0 with WA, and returns the address of +2 -- a 16-character
name -- or -1.  EffectMode_DisplayPresetName calls them with the style number of RAM 0x8D56 minus one, when the
title on screen (ACTIVE_TITLE) is TT_MSCTSEL / TT_MSALPSEL (0xC2 / 0xC5: the C2C5 table) or TT_ONETCH (0xC0: the
other one).  Only on -1 does it fall back to the table_data style record's own name (record + 43): from
STYLEREC_PTRTABLE_C2C5 (0x986000) for 0xC2 / 0xC5, else from STYLEREC_PTRTABLE_DEFAULT (0x987000).
NormScreenProc reads the second table in the same way.  So these are per-context DISPLAY-NAME OVERRIDES for a
few styles: {u16 style index, char name[16]}, e.g. index 0x249 -> "Modern Vibes".
This script:
  - adds a typedef style_name_override_t to naka_style_bitmaps.c and types the ranges as
    StyleNameOverride_C2C5[22] and StyleNameOverride_Default[5] (each tree's own bytes; the names are asserted to
    be 16 printable characters);
  - renames the asm labels (and the search routines: StyleName_FindOverride_C2C5 / _Default) across the tree,
    with the scripts/renaming/rename_style_name_override_<tree>.sed it writes;
  - replaces the [nakarest] notes above the two slices with a header.

RUN (repository root)
    python3 scripts/converters/style_name_override_retype.py [--apply]
    then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

APPLY = "--apply" in sys.argv
BLOB = "naka_style_bitmaps"
TABLES = [  # (offset, entries, old asm label, new name, header)
    (0xAE2, 22, "EffectMode_SearchPresetTableC2C5_Data", "StyleNameOverride_C2C5",
     ["; StyleNameOverride_C2C5 -- 22 x {u16 style index, char name[16]}: display names that replace the table_data",
      "; style record's own (record + 43) while the title is TT_MSCTSEL / TT_MSALPSEL (0xC2 / 0xC5).  Searched by",
      "; StyleName_FindOverride_C2C5 for EffectMode_DisplayPresetName; on a miss the name comes from",
      "; STYLEREC_PTRTABLE_C2C5 (0x986000).  Typed in ui_widgets/naka_style_bitmaps.c",
      "; (scripts/converters/style_name_override_retype.py)."]),
    (0xC6E, 5, "EffectMode_SearchPresetTableC0_Data", "StyleNameOverride_Default",
     ["; StyleNameOverride_Default -- 5 x {u16 style index, char name[16]}: the same overrides for TT_ONETCH (0xC0) and",
      "; NormScreenProc, whose fallback is STYLEREC_PTRTABLE_DEFAULT (0x987000).  Searched by",
      "; StyleName_FindOverride_Default.  Typed in ui_widgets/naka_style_bitmaps.c",
      "; (scripts/converters/style_name_override_retype.py)."]),
]
RULES = [("EffectMode_SearchPresetTableC2C5_Data", "StyleNameOverride_C2C5"),
         ("EffectMode_SearchPresetTableC0_Data", "StyleNameOverride_Default"),
         ("EffectMode_SearchPresetTableC2C5_Loop", "StyleName_FindOverride_C2C5_Loop"),
         ("EffectMode_SearchPresetTableC2C5_Next", "StyleName_FindOverride_C2C5_Next"),
         ("EffectMode_SearchPresetTableC0_Loop", "StyleName_FindOverride_Default_Loop"),
         ("EffectMode_SearchPresetTableC0_Next", "StyleName_FindOverride_Default_Next"),
         ("EffectMode_SearchPresetTableC2C5", "StyleName_FindOverride_C2C5"),
         ("EffectMode_SearchPresetTableC0", "StyleName_FindOverride_Default")]
TYPEDEF = ("/* StyleNameOverride_*'s record (scripts/converters/style_name_override_retype.py). */\n"
           "typedef struct __attribute__((packed)) {\n"
           "    uint16_t style;        /* +0 style record index (the 1-based style number minus one) */\n"
           "    char name[16];         /* +2 the name shown instead of the record's own */\n"
           "} style_name_override_t;\n\n")


def check(tree):
    L = open(os.path.join(ROOT, tree, "maincpu/ui/ui_mode_handlers.s"), "rb").read().decode("latin-1").split("\n")
    code = [re.sub(r'\s+', ' ', x.split(";")[0].strip()) for x in L]
    for name, n in (("EffectMode_SearchPresetTableC2C5", "0x16"), ("EffectMode_SearchPresetTableC0", "5:i3")):
        k = L.index(name + ":") if name + ":" in L else L.index(dict(RULES)[name] + ":")
        body = [c for c in code[k + 1:k + 24] if c]
        assert "sll xde, 3" in body and "add xde, xde" in body and "cp wa, (xbc)" in body, (tree, name)
        assert ("cp ix, %s" % n) in body, (tree, name, n)


def main():
    for tree in ("v10", "v9", "v7"):
        check(tree)
        b = open(os.path.join(ROOT, tree, "maincpu/includes/generated", BLOB + ".bin"), "rb").read()
        recs = {}
        for off, n, *_ in TABLES:
            rs = [(struct.unpack_from("<H", b, off + 18 * i)[0], b[off + 18 * i + 2:off + 18 * i + 18]) for i in range(n)]
            assert all(all(0x20 <= c < 0x7F for c in nm) for _, nm in rs), (tree, hex(off))
            recs[off] = rs
        print("%s: shapes asserted; %s" % (tree, ", ".join("%d records at +0x%X" % (len(r), o) for o, r in recs.items())))
        if not APPLY:
            continue
        c = os.path.join(ROOT, tree, "maincpu/ui_widgets", BLOB + ".c")
        s = open(c, "rb").read().decode("latin-1")
        if "style_name_override_t" not in s:
            k = s.index("typedef struct __attribute__((packed)) {\n", s.index("#define BASE"))
            s = s[:k] + TYPEDEF + s[k:]
            data = s.encode("latin-1")
            open(c + ".tmp", "wb").write(data)
            os.replace(c + ".tmp", c)
            cb = M.CBlob(c)
            for off, n, _, new, _ in TABLES:
                rows = ['        { 0x%03X, "%s" },' % (st, nm.decode("latin-1").replace("\\", "\\\\").replace('"', '\\"'))
                        for st, nm in recs[off]]
                cb.retype(off, off + 18 * n, [M.NewMember("style_name_override_t", new, "[%d]" % n, 18 * n,
                                                          "{\n" + "\n".join(rows) + "\n    }",
                                                          ["    /* %s: {style index, display name} overrides"
                                                           " (asm header) */" % new])], b)
            data = cb.render().encode("latin-1")
            open(c + ".tmp", "wb").write(data)
            os.replace(c + ".tmp", c)
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets/style_bitmaps.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        for _, _, old, _, hdr in TABLES:
            k = next((i for i, x in enumerate(L) if x.startswith(old + ":")), None)
            if k is not None and L[k - 1].startswith("; [nakarest]"):
                j = k
                while L[j - 1].startswith("; [nakarest]"):
                    j -= 1
                L[j:k] = hdr
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
        sed = os.path.join(ROOT, "scripts/renaming/rename_style_name_override_%s.sed" % tree)
        open(sed, "w").write("# rename_style_name_override_%s.sed -- written by scripts/converters/style_name_override_retype.py\n"
                             % tree + "".join("s/\\b%s\\b/%s/g\n" % r for r in RULES))
        hit = subprocess.run(["grep", "-rlwE", "|".join(o for o, _ in RULES), os.path.join(ROOT, tree, "maincpu"),
                              "--include=*.s", "--include=*.c", "--include=*.ld"], capture_output=True, text=True).stdout.split()
        subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  %s: C typed, headers, %d files renamed" % (tree, len(hit)))


if __name__ == "__main__":
    main()
