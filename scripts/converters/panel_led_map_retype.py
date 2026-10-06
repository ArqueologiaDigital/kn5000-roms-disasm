#!/usr/bin/env python3
r"""panel_led_map_retype.py -- type PanelButton_LedMap (naka_style_bitmaps.c) and head its slice (v10/v9/v7).

QUESTION ANSWERED
-----------------
naka_style_bitmaps +0xCCE..+0xE2E (352 B) was EffectMode_MidiSetLEDs_Data, with a [nakarest] "purpose not
established" note.  Its one reader, EffectMode_MidiSetLEDs (ui/ui_mode_handlers.s), takes a panel change record
{segment, state, changed} (segment <= 0x15 = the 22 panel input segments: technics-docs control-panel-protocol.md).
It reads the two bytes at <this> + 16*segment + 2*(lowest set bit of `changed`) and calls
Set_LEDs(row = byte 0, pattern = byte 1, or 0 when the button is not down).  So the table is
[22 segments][8 button bits] x {LED row, LED pattern}.  The row indexes Protocol_values_for_LED_rows (0-5 left
panel, 6-14 right), and every row is <= 14 (asserted).  Buttons with no LED of their own hold {0x0E, 0x0F}:
row 14, the four START/STOP beat LEDs.  This script types the slice as
`uint8_t PanelButton_LedMap[22][8][2]`, renames the asm label everywhere in the tree, and replaces the note
with a header.  Each tree uses its own bytes.

RUN (repository root, built tree)
    python3 scripts/converters/panel_led_map_retype.py [--apply]
    then (v7): scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; gate
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

START, SEGS = 0xCCE, 22
OLD, NEW = "EffectMode_MidiSetLEDs_Data", "PanelButton_LedMap"
HEADER = [
    "; PanelButton_LedMap -- [22 panel segments][8 button bits] x {LED row, LED pattern}.  EffectMode_MidiSetLEDs",
    "; reads entry [segment][lowest set bit of the change mask] and calls Set_LEDs(row, pattern or 0); the row",
    "; indexes Protocol_values_for_LED_rows.  {0x0E, 0x0F} (row 14, the four START/STOP beat LEDs) fills the",
    "; buttons that have no LED of their own.  Typed in ui_widgets/naka_style_bitmaps.c",
    "; (scripts/converters/panel_led_map_retype.py).",
]


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_style_bitmaps.c")
        b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_style_bitmaps.bin"), "rb").read()
        tab = [[(b[START + 16 * s + 2 * k], b[START + 16 * s + 2 * k + 1]) for k in range(8)] for s in range(SEGS)]
        assert all(r <= 14 for seg in tab for r, _ in seg), tree
        if NEW not in open(c, encoding="latin-1").read():
            cb = M.CBlob(c)
            sym = [mb.name for mb in cb.members if START <= mb.offset < START + 16 * SEGS
                   and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
            assert not sym, sym
            rows = ["        {" + ", ".join("{%d, 0x%02X}" % e for e in seg) + "},  /* segment %d */" % s
                    for s, seg in enumerate(tab)]
            new = [M.NewMember("uint8_t", NEW, "[%d][8][2]" % SEGS, 16 * SEGS, "{\n" + "\n".join(rows) + "\n    }",
                               ["    /* PanelButton_LedMap: [panel segment][button bit] = {LED row, LED pattern} for"
                                " Set_LEDs (EffectMode_MidiSetLEDs, ui/ui_mode_handlers.s) */"])]
            cb.retype(START, START + 16 * SEGS, new, b)
            print(tree, "C typed")
            if apply:
                data = cb.render().encode("latin-1")
                open(c + ".tmp", "wb").write(data)
                os.replace(c + ".tmp", c)
        for rel in ("ui_widgets/style_bitmaps.s", "ui/ui_mode_handlers.s"):
            p = os.path.join(ROOT, tree, "maincpu", rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changed = False
            if OLD + ":" in L:
                k = L.index(OLD + ":")
                j = k
                while L[j - 1].startswith("; [nakarest]"):
                    j -= 1
                assert k - j >= 3 and "0xCCE, 0x160" in L[k + 1], (tree, L[k + 1])
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
