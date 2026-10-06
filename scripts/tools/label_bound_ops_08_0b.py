#!/usr/bin/env python3
"""label_bound_ops_08_0b.py -- label the handlers of bound display-record ops 08-0B (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  GraphicsRender_Start calls GraphicsRender_Start_PtrTable[op] for each bound display record (a record whose values
  are read from RAM: the sdb_* macros of audio/sound_editor_ui.s).  Entries 08-0B were numeric words, pointing at
  unlabelled entry points that follow a `ret` inside the DrawFunc_Init / ColorBlit_WithPaletteSave runs of
  display/graphics_text_vga.s.  What they do, read from their code:
      op 08          reads a bitmap pointer (xbc+7) and its size words and calls ColorBlit2
      op 09, 0A, 0B  read position bytes and a value pointer from the record (xiz+2/+4/+5, +7/+9, +11) and print the
                     value with Sprintf_Locked through a "%1d" / "%2d" / "%3d" format chosen by the record
  They become SeGfx_BoundOp08_ColorBlit, and SeGfx_BoundOp09_FormatNumber, ..._0A_..., ..._0B_... -- the op number is
  the table index, and the suffix is only what the code does.  The record layouts (which byte is what) are still
  not derived.  Per tree the targets come from the tree's own table words.  The script asserts that each is an
  instruction start without a label, that the op 08 body reaches `calr ColorBlit2` and the op 09-0B bodies
  `call Sprintf_Locked` (within 100 lines).  It places the labels and spells the four `.long` words with them.

RUN (repository root; built tree; census maps: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_bound_ops_08_0b.py [--apply]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

NAMES = {8: ("SeGfx_BoundOp08_ColorBlit", "calr\tColorBlit2"),
         9: ("SeGfx_BoundOp09_FormatNumber", "call\tSprintf_Locked"),
         10: ("SeGfx_BoundOp0A_FormatNumber", "call\tSprintf_Locked"),
         11: ("SeGfx_BoundOp0B_FormatNumber", "call\tSprintf_Locked")}


def main():
    for tree in ("v10", "v9", "v7"):
        m = census.load(tree)
        t = m["byname"]["GraphicsRender_Start_PtrTable"]
        edits = {}
        for op, (name, must) in NAMES.items():
            a = census.le(m, t + 4 * op, 4)
            r = census.find(m, a)
            assert r and r[0] == a and census.is_insn_row(tree, r) and not r[7], (tree, op, hex(a))
            q = os.path.join(REPO, tree, "maincpu", r[2])
            L = open(q, "rb").read().decode("latin-1").split("\n")
            body = "\n".join(L[r[3]:r[3] + 100])
            assert must in body, (tree, op, must)
            edits.setdefault(r[2], []).append((r[3], name + ":"))
            rt = census.find(m, t + 4 * op)
            assert rt[0] == t + 4 * op and re.match(r'^\s*\.long\s+0x[0-9a-fA-F]+\s*$', rt[6]), (tree, op, rt[6])
            edits.setdefault(rt[2], []).append((rt[3], "\t.long\t" + name))
        print("%s: %s" % (tree, ", ".join("%s" % n for n, _ in NAMES.values())))
        if not APPLY:
            continue
        for rel, ops in edits.items():
            q = os.path.join(REPO, tree, "maincpu", rel)
            L = open(q, "rb").read().decode("latin-1").split("\n")
            for li, op in sorted(ops, key=lambda x: (-x[0], x[1].endswith(":"))):
                if op.endswith(":"):
                    L[li:li] = [op]
                else:
                    L[li] = op
            data = "\n".join(L).encode("latin-1")
            open(q + ".tmp", "wb").write(data)
            os.replace(q + ".tmp", q)
        q = os.path.join(REPO, tree, "maincpu/ui_widgets/disk_warning_strings.s")
        s = open(q, "rb").read().decode("latin-1")
        s = s.replace("GraphicsRender_Start calls [op].  Ops 08-0B are not\n; named: their record layouts are not derived yet.",
                      "GraphicsRender_Start calls [op].  Op 08 blits a bitmap, ops 09-0B print a\n"
                      "; number (Sprintf %Nd); their record layouts are not derived yet (scripts/tools/label_bound_ops_08_0b.py).")
        data = s.encode("latin-1")
        open(q + ".tmp", "wb").write(data)
        os.replace(q + ".tmp", q)


if __name__ == "__main__":
    main()
