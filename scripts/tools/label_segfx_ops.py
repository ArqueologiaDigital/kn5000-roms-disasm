#!/usr/bin/env python3
"""label_segfx_ops.py -- name the display-list record handlers by op and primitive (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  GraphicsRender_ProcessEntries walks a static display list ({u8 op, u8 len, payload} records, the sd_* macros of
  audio/sound_editor_ui.s) and calls GraphicsRender_ProcessEntries_PtrTable[op] with the record.  11 of the 36
  handlers had no label (the table and its C copy, naka_disk_warning.c, spelled them as numbers), the others had
  generic names (SeGfx_StaticOp00_FromBuf_Helper).  Read from each handler's body (v10 addresses):
    00 01 02  DrawLineWithMode from (x0,y0) = record +2/+4 to (x1,y1) = +6/+8: the same compiled body three times
    11 12 15  the same with DrawDottedLineWithMode
    13        four DrawDottedLineWithMode calls: the dotted outline of the box (x0,y0)-(x1,y1)
    09        DrawRect (the clipped outline, below) of the box
    22 / 0A   DrawRect, then one / two DrawLineWithMode pairs offset +1 (and +2) along the right and bottom
              sides: the box with a 1- / 2-pixel drop shadow
    05        ColorBlit of the box with COLORBLIT_MODE forced to 1 (toggle bit 5 by bit 7: a highlight)
    03        1-bpp bitmap blit at a cell (sd_blit)
    06 07 08 20  text at a cell (sd_ctext), 17 1C text at a pixel position (sd_ptext): identical bodies except
              the font index passed to DrawText_QueueOrDirect (0, 1, 2, 6 and 3, 4: table_data/fonts.s)
    23        DrawDesignBox + DrawIcons (sd_op23 style, cell)
  The rectangle primitive the box ops call had generic or wrong names: DrawText_LayoutAndRender_Variant1_Helper3
  queues or draws it, like ColorBlit; its deferred-record callback and its clipped four-line body were named
  Voice_FactoryPresetData_Code / _Helper2.  They took the name of the `.incbin` that precedes them in
  kn5000_v<N>_program.s, as did the branch labels of DrawDottedLineWithMode_Impl after the file boundary (the
  routine starts at the end of ui/ui_window_procs.s and continues there).  This script renames them:
  DrawRect / DrawRect_Deferred / DrawRect_CallbackBlock / DrawRect_Impl, and DrawDottedLineWithMode_Impl_Skip28...
  The bound-record table (GraphicsRender_Start_PtrTable) keeps ops 08-0B unnamed: their record layouts are not
  derived yet.

  Per tree (v9 = v10's addresses; v7 = v10 - 0x40D in this stretch, every target checked byte for byte): the
  label is renamed where one exists, else a label line goes before the instruction (census map); the asm table
  entries and the C words (NAKA_ADDR + extern + the tree's naka_disk_warning_link.ld) are spelled with the name;
  the tables' [nakarest] notes become headers.  Then: regenerate_v7_c_divergence.py --apply BEFORE make (it
  certifies against the current v7 bins); make all; gate.

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/label_segfx_ops.py [--apply]
"""
import collections
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
APPLY = "--apply" in sys.argv
sys.argv = sys.argv[:1]
import census  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
DELTA = {"v10": 0, "v9": 0, "v7": -0x40D}
# v10 address -> new name
OPS = {0xFB19D4: "SeGfx_StaticOp00_Line", 0xFB19FE: "SeGfx_StaticOp01_Line", 0xFB1A28: "SeGfx_StaticOp02_Line",
       0xFB1CFF: "SeGfx_StaticOp03_Bitmap", 0xFB1DB3: "SeGfx_StaticOp05_FillBoxMode1",
       0xFB164E: "SeGfx_StaticOp06_CellTextFont0", 0xFB16E9: "SeGfx_StaticOp07_CellTextFont1",
       0xFB1784: "SeGfx_StaticOp08_CellTextFont2", 0xFB1AD0: "SeGfx_StaticOp09_Box",
       0xFB1AFA: "SeGfx_StaticOp0A_ShadowBox2", 0xFB1A52: "SeGfx_StaticOp11_DottedLine",
       0xFB1A7C: "SeGfx_StaticOp12_DottedLine", 0xFB1BDB: "SeGfx_StaticOp13_DottedBox",
       0xFB1AA6: "SeGfx_StaticOp15_DottedLine", 0xFB181F: "SeGfx_StaticOp17_PixelTextFont3",
       0xFB18AC: "SeGfx_StaticOp1C_PixelTextFont4", 0xFB1939: "SeGfx_StaticOp20_CellTextFont6",
       0xFB1C78: "SeGfx_StaticOp22_ShadowBox1", 0xFB1D48: "SeGfx_StaticOp23_DesignBox"}
OTHER = {0xFB0D14: "DrawRect", 0xFB0D40: "DrawRect_Deferred", 0xFB0D69: "DrawRect_Return",
         0xFB0D6D: "DrawRect_CallbackBlock", 0xFB0D8C: "DrawRect_Impl", 0xFB0DAB: "DrawRect_Impl_CheckX0",
         0xFB0DB8: "DrawRect_Impl_CheckX1", 0xFB0DC8: "DrawRect_Impl_CheckY1", 0xFB0DD8: "DrawRect_Impl_Clipped",
         0xFB0E03: "DrawRect_Impl_FourSides", 0xFB0E71: "DrawRect_Impl_LastSide",
         # DrawDottedLineWithMode_Impl after the file boundary (its labels ran to _Skip27 / _Join6 / _Loop)
         0xFB0B76: "DrawDottedLineWithMode_Impl_Skip28", 0xFB0B78: "DrawDottedLineWithMode_Impl_Join7",
         0xFB0B7B: "DrawDottedLineWithMode_Impl_Join8", 0xFB0BA0: "DrawDottedLineWithMode_Impl_Skip29",
         0xFB0BEB: "DrawDottedLineWithMode_Impl_Loop2", 0xFB0BF8: "DrawDottedLineWithMode_Impl_Skip30",
         0xFB0C5A: "DrawDottedLineWithMode_Impl_Skip31", 0xFB0C8E: "DrawDottedLineWithMode_Impl_Skip32",
         0xFB0C93: "DrawDottedLineWithMode_Impl_Skip33", 0xFB0CA8: "DrawDottedLineWithMode_Impl_Skip34",
         0xFB0CAC: "DrawDottedLineWithMode_Impl_Skip35", 0xFB0CC1: "DrawDottedLineWithMode_Impl_Skip36",
         0xFB0CC3: "DrawDottedLineWithMode_Impl_Join9", 0xFB0CC6: "DrawDottedLineWithMode_Impl_Join10",
         0xFB0CEA: "DrawDottedLineWithMode_Impl_Join11", 0xFB0D0F: "DrawDottedLineWithMode_Impl_Epilogue"}
NEW = {**OPS, **OTHER}
# C words of the two tables that become NAKA_ADDR (v10 address -> name; the existing names are kept)
CWORDS = {**OPS, 0xFB2201: "SeGfx_BoundOp06_Helper"}
HEAD_STATIC = [
    "; GraphicsRender_ProcessEntries_PtrTable -- 36 x u32, the handler of each static display-list record op",
    "; ({u8 op, u8 len, payload}; the sd_* macros of audio/sound_editor_ui.s).  GraphicsRender_ProcessEntries",
    "; calls [op] with the record.  Lines 00-02, dotted lines 11/12/15, dotted box 13, box 09, shadowed boxes",
    "; 22 / 0A, highlight fill 05, bitmap 03, text at a cell 06/07/08/20 (fonts 0/1/2/6) or a pixel 17/1C (fonts",
    "; 3/4), design box 23; GraphicsRender_RetStub = no such op (scripts/tools/label_segfx_ops.py).",
]
HEAD_BOUND = [
    "; GraphicsRender_Start_PtrTable -- 12 x u32, the handler of each bound display record op (a value read from",
    "; RAM: the sdb_* macros of audio/sound_editor_ui.s); GraphicsRender_Start calls [op].  Ops 08-0B are not",
    "; named: their record layouts are not derived yet.",
]


def syms(tree):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % tree)],
                         capture_output=True, text=True, check=True).stdout
    at = collections.defaultdict(list)
    for line in out.splitlines():
        f = line.split()
        if len(f) == 3 and f[1] in "tT":
            at[int(f[0], 16)].append(f[2])
    return at


def main():
    r10 = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    at10 = syms("v10")
    for tree in ("v10", "v9", "v7"):
        root = os.path.join(REPO, tree, "maincpu")
        rom = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % tree), "rb").read()
        at = syms(tree)
        m = census.load(tree)
        tok, insert, where = {}, collections.defaultdict(list), {}
        for a10, new in NEW.items():
            a = a10 + DELTA[tree]
            assert rom[a - 0xE00000:a - 0xE00000 + 8] == r10[a10 - 0xE00000:a10 - 0xE00000 + 8], (tree, hex(a))
            where[new] = a
            old10 = at10.get(a10, [])
            here = at.get(a, [])
            if here:
                old = next((n for n in here if n in old10), here[0])
                if old != new:
                    tok[old] = new
            else:
                r = census.find(m, a)
                assert r and r[0] == a and census.is_insn_row(tree, r), (tree, new, hex(a))
                insert[(r[2], r[3])].append(new + ":")
        for a10, nm in CWORDS.items():
            where.setdefault(nm, a10 + DELTA[tree])
        print("%s: %d renamed, %d labels inserted" % (tree, len(tok), sum(len(v) for v in insert.values())))
        # the asm tables: numeric `.long`s whose value now has a name
        tabrows = {}
        for tname, n in (("GraphicsRender_ProcessEntries_PtrTable", 36), ("GraphicsRender_Start_PtrTable", 12)):
            base = m["byname"][tname]
            for i in range(n):
                r = census.find(m, base + 4 * i)
                assert r[0] == base + 4 * i and r[5] == ".long", (tree, tname, i)
                val = census.le(m, r[0], 4)
                nm = next((k for k, v in where.items() if v == val), None)
                if nm and re.match(r'^\s*\.long\s+0x[0-9a-fA-F]+\s*$', r[6]):
                    tabrows[(r[2], r[3])] = "\t.long\t" + nm
        if not APPLY:
            continue
        pat = re.compile(r'\b(' + "|".join(map(re.escape, sorted(tok, key=len, reverse=True))) + r')\b')
        for dp, _, fs in os.walk(root):
            for f in fs:
                if not f.endswith((".s", ".c", ".h", ".ld")):
                    continue
                p = os.path.join(dp, f)
                rel = os.path.relpath(p, root)
                L = open(p, "rb").read().decode("latin-1").split("\n")
                out, changed = [], False
                for i, line in enumerate(L):
                    out.extend(insert.get((rel, i), []))
                    changed |= (rel, i) in insert
                    if (rel, i) in tabrows:
                        line = tabrows[(rel, i)]
                        changed = True
                    if f.endswith((".c", ".h")):
                        j = min([k for k in (line.find("/*"), line.find("//")) if k >= 0] or [len(line)])
                        if line.lstrip().startswith("*"):
                            j = 0
                        nl = pat.sub(lambda mm: tok[mm.group(1)], line[:j]) + line[j:]
                    else:
                        nl = pat.sub(lambda mm: tok[mm.group(1)], line)
                    changed |= nl != L[i]
                    out.append(nl)
                if rel == "ui_widgets/disk_warning_strings.s":
                    for label, head in (("GraphicsRender_ProcessEntries_PtrTable:", HEAD_STATIC),
                                        ("GraphicsRender_Start_PtrTable:", HEAD_BOUND)):
                        k = out.index(label)
                        j = k
                        while out[j - 1].startswith("; [nakarest]"):
                            j -= 1
                        assert k - j >= 3, (tree, label)
                        out[j:k] = head
                        changed = True
                if changed:
                    data = "\n".join(out).encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)
        # C words, externs and link-script symbols
        c = os.path.join(root, "ui_widgets/naka_disk_warning.c")
        s = open(c, "rb").read().decode("latin-1")
        added = []
        for a10, nm in sorted(CWORDS.items()):
            lit = "0x%08X," % a10
            if s.count(lit) == 0 and "NAKA_ADDR(%s)," % nm in s:
                continue                        # already symbolic (renamed above)
            assert s.count(lit) == 1, (tree, lit, s.count(lit))
            s = s.replace(lit, "NAKA_ADDR(%s)," % nm)
            if "extern const char %s;" % nm not in s:
                added.append(nm)
        L = s.split("\n")                      # the extern block stays sorted
        i = next(k for k, x in enumerate(L) if x.startswith("extern const char "))
        j = i
        while L[j].startswith("extern const char "):
            j += 1
        L[i:j] = sorted(L[i:j] + ["extern const char %s;" % nm for nm in added], key=lambda x: x.split()[-1])
        s = "\n".join(L)
        data = s.encode("latin-1")
        open(c + ".tmp", "wb").write(data)
        os.replace(c + ".tmp", c)
        ld = os.path.join(root, "ui_widgets/naka_disk_warning_link.ld")
        L = open(ld, "rb").read().decode("latin-1").rstrip("\n").split("\n")
        k = max(i for i, x in enumerate(L) if x.startswith("}")) + 1
        syms_ = {x.split(" = ")[0]: x for x in L[k:] if " = " in x}
        for nm in added:
            syms_[nm] = "%s = 0x%08X;" % (nm, where[nm])
        L = L[:k] + [""] + [syms_[n] for n in sorted(syms_)]
        data = ("\n".join(x for i, x in enumerate(L) if not (i == k and L[k - 1] == "" and x == "")) + "\n").encode("latin-1")
        open(ld + ".tmp", "wb").write(data)
        os.replace(ld + ".tmp", ld)


if __name__ == "__main__":
    main()
