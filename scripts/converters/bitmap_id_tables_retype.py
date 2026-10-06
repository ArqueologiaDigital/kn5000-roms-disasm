#!/usr/bin/env python3
r"""bitmap_id_tables_retype.py -- BitmapIDProc's name/file tables split and named; UserBitmapCheck's 24x24 bitmap typed.

QUESTION ANSWERED
-----------------
1. naka_disk_warning +0x2720 (2,760 B) was one asm slice, BitmapIDProc_PtrTable.  It holds four objects in a row
   -- the same shape as IconIDProc_PtrTable / IconBitmapNamePtrTable:
       +0x2720  256 x u32  bitmap id -> resource name   (BitmapIDProc indexes it: `ld xbc, BitmapIDProc_PtrTable`)
       +0x2B20             the names ("TrashIcon", "GoldTechnics", "SlideBase" ...), up to the next table
       +0x2C58  256 x u32  bitmap id -> .bmp file name  (no reader in the ROM)
       +0x3058             the file names ("19mic.bmp" ...) up to +0x31E8
   The slice is cut at the three internal boundaries (each asserted: the tables are 256 words whose non-zero
   entries point into the string block that follows them).  The C member ptrs_26 (the file-name table) is named
   BitmapID_FileNamePtrTable.
2. naka_disk_warning +0x1274 (576 B) is a 24 x 24 bitmap, one byte per pixel.  UserBitmapCheck (ui/ui_window_procs.s)
   answers EVT_GET_BITMAP_WIDTH / _HEIGHT with 0x18 and EVT_GET_BITMAP_DATA with this address, and
   VwUserBitmap_HandlePaint draws it with DrawBitmapSPFast.  It is typed as uint8_t UserBitmapCheck_Bitmap24x24[24][24]
   (was 55 placeholder members, two of them false pointers to NakaData_RomEnd made of the pixel run FF FF FF 00),
   and the asm label UserBitmapCheck_ReturnTablePtr_Data is renamed.

RUN (repository root)
    python3 scripts/converters/bitmap_id_tables_retype.py [--apply]
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
from name_resname_strings import segments   # noqa: E402

APPLY = "--apply" in sys.argv
BLOB = "naka_disk_warning"
BASE = 0x00EA8CAC
PIECES = [(0x2720, 0x400, "BitmapIDProc_PtrTable",
           ["; BitmapIDProc_PtrTable -- 256 x u32: bitmap id -> resource name.  BitmapIDProc reads table[id] for",
            "; GET/DUMP_PROPERTY_EX and searches it by name for SET_PROPERTY_EX.  35 entries are non-zero, while",
            "; BitmapIDProc_EntryCount (the GET_PROP_DATA_COUNT_SP answer) is 34."]),
          (0x2B20, 0x138, "BitmapID_Names",
           ["; BitmapID_Names -- the resource names BitmapIDProc_PtrTable points at (\"TrashIcon\", \"GoldTechnics\" ...)."]),
          (0x2C58, 0x400, "BitmapID_FileNamePtrTable",
           ["; BitmapID_FileNamePtrTable -- 256 x u32: bitmap id -> its .bmp file name, parallel to BitmapIDProc_PtrTable",
            "; (like IconBitmapNamePtrTable for icons).  No reader in the ROM: a development-time table."]),
          (0x3058, 0x190, "BitmapID_FileNames",
           ["; BitmapID_FileNames -- the .bmp file names BitmapID_FileNamePtrTable points at (\"19mic.bmp\" ...)."])]
BMP_OFF, BMP_W = 0x1274, 24
BMP_OLD, BMP_NEW = "UserBitmapCheck_ReturnTablePtr_Data", "UserBitmapCheck_Bitmap24x24"
BMP_HDR = ["; UserBitmapCheck_Bitmap24x24 -- a 24 x 24 bitmap, one byte per pixel.  UserBitmapCheck answers",
           "; EVT_GET_BITMAP_WIDTH / _HEIGHT with 0x18 and EVT_GET_BITMAP_DATA with this address; VwUserBitmap_HandlePaint",
           "; draws it with DrawBitmapSPFast.  Typed in ui_widgets/naka_disk_warning.c (scripts/converters/bitmap_id_tables_retype.py)."]


def check(b):
    for tab, n, strs in ((0x2720, 0x400, (0x2B20, 0x2C58)), (0x2C58, 0x400, (0x3058, 0x31E8))):
        ws = struct.unpack_from("<256I", b, tab)
        live = [w - BASE for w in ws if w]
        assert live and all(strs[0] <= o < strs[1] for o in live), hex(tab)


def main():
    for tree in ("v10", "v9", "v7"):
        b = open(os.path.join(ROOT, tree, "maincpu/includes/generated", BLOB + ".bin"), "rb").read()
        if tree != "v7":
            check(b)            # v7's blob holds v7 addresses; its layout is v10's (the C members are asserted below)
        if not APPLY:
            print("%s: tables asserted" % tree)
            continue
        c = os.path.join(ROOT, tree, "maincpu/ui_widgets", BLOB + ".c")
        s = open(c, "rb").read().decode("latin-1")
        s = "".join(re.sub(r'\bptrs_26\b', "BitmapID_FileNamePtrTable", seg) if k == "code" else seg for k, seg in segments(s))
        data = s.encode("latin-1")
        open(c + ".tmp", "wb").write(data)
        os.replace(c + ".tmp", c)
        cb = M.CBlob(c)
        assert any(x.name == "BitmapID_FileNamePtrTable" and x.offset == 0x2C58 for x in cb.members), tree
        if BMP_NEW not in cb.by_name:
            px = b[BMP_OFF:BMP_OFF + BMP_W * BMP_W]
            rows = ["        { " + ", ".join("0x%02X" % v for v in px[r * BMP_W:(r + 1) * BMP_W]) + " },"
                    for r in range(BMP_W)]
            # pixel runs FF FF FF 00 were decoded as pointers to NakaData_RomEnd (0x00FFFFFF): pixels, not pointers
            fp = [x.name for x in cb.members if BMP_OFF <= x.offset < BMP_OFF + 576
                  and cb.entries[cb.by_name[x.name]].expr.strip() == "NAKA_ADDR(NakaData_RomEnd)"]
            cb.retype(BMP_OFF, BMP_OFF + BMP_W * BMP_W,
                      [M.NewMember("uint8_t", BMP_NEW, "[24][24]", 576, "{\n" + "\n".join(rows) + "\n    }",
                                   ["    /* UserBitmapCheck_Bitmap24x24: 24 x 24, one byte per pixel (asm header) */"])], b,
                      false_pointers=fp)
        data = cb.render().encode("latin-1")
        open(c + ".tmp", "wb").write(data)
        os.replace(c + ".tmp", c)
        p = os.path.join(ROOT, tree, "maincpu/ui_widgets/disk_warning_strings.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        k = next(i for i, x in enumerate(L) if x.startswith("BitmapIDProc_PtrTable:"))
        assert '0x2720, 0xAC8' in L[k], (tree, L[k])
        j = k
        while L[j - 1].startswith("; [nakarest]"):
            j -= 1
        new = []
        for off, size, lab, hdr in PIECES:
            new += hdr + ['%s:\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (lab, BLOB, off, size)]
        L[j:k + 1] = new
        k = next(i for i, x in enumerate(L) if x.startswith(BMP_OLD + ":"))
        j = k
        while L[j - 1].startswith("; [nakarest]"):
            j -= 1
        L[j:k] = BMP_HDR
        data = "\n".join(L).encode("latin-1")
        open(p + ".tmp", "wb").write(data)
        os.replace(p + ".tmp", p)
        hit = subprocess.run(["grep", "-rlw", BMP_OLD, os.path.join(ROOT, tree, "maincpu"), "--include=*.s",
                              "--include=*.c", "--include=*.ld"], capture_output=True, text=True).stdout.split()
        if hit:
            subprocess.run(["sed", "-i", r"s/\b%s\b/%s/g" % (BMP_OLD, BMP_NEW)] + hit, check=True)
        print("%s: slice split in 4, file table and bitmap typed, %d files renamed" % (tree, len(hit)))


if __name__ == "__main__":
    main()
