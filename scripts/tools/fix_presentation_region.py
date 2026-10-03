#!/usr/bin/env python3
"""fix_presentation_region.py -- the "<PRESENTATION>" span of technichord_string_data.s, cut at NAKA view ids, is put back together.

QUESTION THIS ANSWERS / JOB IT DOES
  naka_technichord_strings+0x1A0B2.. sits at ROM 0xEA0000, and 0x00EA00nn is ALSO the id of view n
  of Viewable slot 0xEA (Drawbar 0, DrawPerc4 2, DrawPerc223 3, DrawSetting 12, ...).  Earlier passes
  took the `ld xwa, <view id>` before SendEvent / ApPostEvent for pointers into this span, cut its
  slices at every such value, labelled them, and the [nakarest] headers listed those loads as the
  span's readers ("first string 'SENTATION>'").  scripts/tools/name_naka_view_ids.py made the loads
  NAKA_VIEW_* and retired the labels; this restores the span to its real objects (ROM bytes):
      +0x1A0B2  0x013F, 0x00EF (319, 239), 4 B           Presentation_RootEntry
      +0x1A0B6  "" + 0xFF pad, Strcpy source               Seq_InitVoiceStructures_Str_Empty
      +0x1A0B8  "" + 0xFF pad, Seq_CopyResourcePtrs' fill   Seq_CopyResourcePtrs_Data
      +0x1A0BA  "<PRESENTATION>", NUL, 0xFF pad            Presentation_TagStrTable
      +0x1A0CA  "</PRESENTATION>", NUL                     Seq_LoadResource_Proceed_Str_PRESENTATION
  merging the artefact slices, and rewrites the headers: the data-word clauses (words elsewhere
  whose value equals these addresses) stay, the code "readers" that were view ids go.
  IvDrawbar_DrawbarUpdate_Data_2 -- named after a view-id load, really Seq_InitVoiceStructures'
  Strcpy source -- is renamed (the tree's other uses follow).  Same bytes: make gate-all.

USAGE
  python3 scripts/tools/fix_presentation_region.py --tree v10 [--apply]
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
BIN = '"includes/generated/naka_technichord_strings.bin"'


def wrap(text, prefix="; [nakarest] ", width=100):
    out, cur = [], ""
    for w in text.split(" "):
        if cur and len(prefix) + len(cur) + 1 + len(w) > width:
            out.append(prefix + cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    if cur:
        out.append(prefix + cur)
    return [x.rstrip() for x in out]


def block_text(L, i):
    j = i
    while j < len(L) and L[j].startswith("; [nakarest]"):
        j += 1
    return j, " ".join(x[len("; [nakarest] "):] for x in L[i:j])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    p = os.path.join(REPO, a.tree, "maincpu", "ui_widgets", "technichord_string_data.s")
    L = open(p, "rb").read().decode("latin-1").split("\n")
    # 1. FDemoText_RenderTextLine_Data's header: its CDlikeSwTtl "reader" was a view id
    h = next(i for i, l in enumerate(L) if l.startswith("; [nakarest] naka_technichord_strings+0x1a0ae "))
    e, _ = block_text(L, h)
    r = next(i for i in range(h, e) if "Readers:" in L[i])      # keep the title / purpose lines
    t = " ".join(x[len("; [nakarest] "):] for x in L[r:e])
    t2 = re.sub(r'; 1 data word in CDlikeSwTtl_SetRecordAndNotify_Data \(at (0x[0-9a-f]+)\), which is read by '
                r'.*?`ld xwa, CDlikeSwTtl_SetRecordAndNotify_Data`\)\.$', r'; 1 data word at \1.', t)
    assert t2 != t, "FDemoText header shape changed"
    L[r:e] = wrap(t2)
    # 2. the span: from Presentation_RootEntry's header to Seq_LoadDisplayResource_Str_Empty's header
    s = next(i for i, l in enumerate(L) if l.startswith("; [nakarest] Presentation_RootEntry "))
    z = next(i for i, l in enumerate(L) if l.startswith("; [nakarest] naka_technichord_strings+0x1a0da "))
    _, root = block_text(L, s)
    m = re.search(r'Readers: (.*)$', root)
    assert m, "Presentation_RootEntry header shape changed"
    # v10/v9 list RegTitle's view argument first (v7 expands the macro and does not)
    words = re.sub(r'^source references InitializeMurai \(ui/drawbar_panel_ui\.s: `RegTitle [^`]*`\), ',
                   'source references ', m.group(1))
    hdr = ("Presentation_RootEntry +0x1a0b2..+0x1a0ca: 0x013F, 0x00EF (319, 239), then two empty strings each"
           " padded with 0xFF, then \"<PRESENTATION>\" -- the ROM bytes.  Readers: " + words + "  2026-10-03:"
           " 0x00EA00nn is also the NAKA id of view nn of slot 0xEA (Drawbar, DrawPerc4, DrawPerc223,"
           " DrawSetting ...), and the code once listed here as reading this span -- RegTitle's view"
           " argument, and `ld xwa, ...` before SendEvent / ApPostEvent -- loaded those view ids"
           " (NAKA_VIEW_*, scripts/tools/name_naka_view_ids.py); the slices cut at them are merged back"
           " (scripts/tools/fix_presentation_region.py).  Whether the data words above are view ids too"
           " is not settled.")
    new = wrap(hdr) + [
        "Presentation_RootEntry:\t\t\t\t.incbin %s, 0x1A0B2, 0x4\t; 0x013F, 0x00EF = 319, 239" % BIN,
        "Seq_InitVoiceStructures_Str_Empty:\t\t.incbin %s, 0x1A0B6, 0x2\t; \"\", 0xFF pad: Seq_InitVoiceStructures' Strcpy source" % BIN,
        "Seq_CopyResourcePtrs_Data:\t\t\t.incbin %s, 0x1A0B8, 0x2\t; \"\", 0xFF pad: the pointer Seq_CopyResourcePtrs fills its table with" % BIN,
        "Presentation_TagStrTable:\t\t\t.incbin %s, 0x1A0BA, 0x10\t; \"<PRESENTATION>\", NUL, 0xFF pad" % BIN,
        "Seq_LoadResource_Proceed_Str_PRESENTATION:\t.incbin %s, 0x1A0CA, 0x10\t; \"</PRESENTATION>\", NUL" % BIN,
    ]
    old_bytes = [l for l in L[s:z] if ".incbin" in l]
    span = [re.search(r'0x([0-9A-F]+), 0x([0-9A-F]+)', l).groups() for l in old_bytes]
    lo, hi = int(span[0][0], 16), int(span[-1][0], 16) + int(span[-1][1], 16)
    assert (lo, hi) == (0x1A0B2, 0x1A0DA), (hex(lo), hex(hi))
    L[s:z] = new
    print("%s: header of +0x1a0ae fixed; +0x1a0b2..+0x1a0da: %d slices -> 5%s" % (a.tree, len(old_bytes), "" if a.apply else " (dry run)"))
    if a.apply:
        open(p, "wb").write("\n".join(L).encode("latin-1"))
        files = glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*.s"), recursive=True)
        subprocess.run(["sed", "-i", "s/\\bIvDrawbar_DrawbarUpdate_Data_2\\b/Seq_InitVoiceStructures_Str_Empty/g"] + files, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
