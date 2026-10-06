#!/usr/bin/env python3
r"""panel_memory_slot_table_retype.py -- type PanelMemory_SlotAddresses in naka_style_bitmaps.c and head its slice.

QUESTION ANSWERED
-----------------
+0x784..+0x8C8 of naka_style_bitmaps (324 B) was generic members.  It is 81 u32 RAM addresses: entries 0..79 are
the 80 panel memories, 0x1ED400 + 960*n (asserted), entry 80 is RAM 0x3C2C4, the Music Stylist record's mirror of
the panel stream (technics-docs music-stylist-database.md).  PanelMemory_Recall and PanelMemory_CopySlotToLivePanel
index it by slot number (0x80 = 80, the mirror), as do the other panel-memory readers in ui/bitmap_out_routines.s.
This script types it as `uint32_t PanelMemory_SlotAddresses[81]` (values from each tree's own blob; the file
differs between trees) and replaces the slice's [nakarest] "purpose not established" note with a header.

RUN (repository root, built tree)
    python3 scripts/converters/panel_memory_slot_table_retype.py [--apply]
C comment gate: --allow '/\* zero padding \*/' (generator notes on bytes of the table).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402

START, COUNT = 0x784, 81
HEADER = [
    "; PanelMemory_SlotAddresses -- 81 u32 RAM addresses, one per panel-memory slot: 0..79 = the 80 panel",
    "; memories at 0x1ED400 + 960*n, 80 = RAM 0x3C2C4, the Music Stylist record's mirror of the panel stream (slot",
    "; code 0x80 is read as 80).  Indexed by slot by PanelMemory_Recall_Slot, PanelMemory_CopySlotToLivePanel,",
    "; PanelMemory_RecallRecords and the other panel-memory readers in ui/bitmap_out_routines.s; typed in",
    "; ui_widgets/naka_style_bitmaps.c (scripts/converters/panel_memory_slot_table_retype.py).",
]
INC = '.incbin "includes/generated/naka_style_bitmaps.bin", 0x784, 0x144'


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_style_bitmaps.c")
        b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_style_bitmaps.bin"), "rb").read()
        vals = [int.from_bytes(b[START + 4 * i:START + 4 * i + 4], "little") for i in range(COUNT)]
        assert all(vals[i] == 0x1ED400 + 960 * i for i in range(80)) and vals[80] == 0x3C2C4, tree
        if "PanelMemory_SlotAddresses" not in open(c, encoding="latin-1").read():
            cb = M.CBlob(c)
            sym = [mb.name for mb in cb.members if START <= mb.offset < START + 4 * COUNT
                   and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
            assert not sym, sym                  # nothing symbolic in the region: only RAM addresses
            rows = ["        0x%06X,  /* %s */" % (v, "slot %d" % i if i < 80 else "the Music Stylist mirror")
                    for i, v in enumerate(vals)]
            new = [M.NewMember("uint32_t", "PanelMemory_SlotAddresses", "[%d]" % COUNT, 4 * COUNT,
                               "{\n" + "\n".join(rows) + "\n    }",
                               ["    /* PanelMemory_SlotAddresses: the RAM address of each panel-memory slot, 0x1ED400 +"
                                " 960*n for n < 80; [80] = the Music Stylist record's mirror (read by PanelMemory_Recall"
                                " and the other panel-memory routines in ui/bitmap_out_routines.s) */"])]
            cb.retype(START, START + 4 * COUNT, new, b)
            print(tree, "C typed")
            if apply:
                data = cb.render().encode("latin-1")
                open(c + ".tmp", "wb").write(data)
                os.replace(c + ".tmp", c)
        s = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "style_bitmaps.s")
        L = open(s, "rb").read().decode("latin-1").split("\n")
        if HEADER[0] in L:
            continue
        k = L.index("PanelMemory_SlotAddresses:")
        assert L[k + 1] == "\t" + INC, L[k + 1]
        j = k
        while L[j - 1].startswith("; [nakarest]"):
            j -= 1
        L[j:k + 2] = HEADER + ["PanelMemory_SlotAddresses:\t" + INC]
        print(tree, "asm headed")
        if apply:
            data = "\n".join(L).encode("latin-1")
            open(s + ".tmp", "wb").write(data)
            os.replace(s + ".tmp", s)


if __name__ == "__main__":
    main()
