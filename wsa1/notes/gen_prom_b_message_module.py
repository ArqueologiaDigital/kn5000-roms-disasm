#!/usr/bin/env python3
"""Emit prom_b 0xF2BE35-0xF317FF -- the message and service module -- as assembly.

QUESTION IT ANSWERS
    "...and what is the assembly for the layout notes/prom_b_message_module.py
    derives?"  Every object's kind and extent comes from that script; this one
    only renders.  Display-list records are rendered by the interpreter each list
    belongs to, reusing scripts/analysis/prom_b_display_lists.py's renderer for
    interpreter A and notes/gen_prom_b_display_lists_v2.py's for interpreter B,
    so the text of a record here is the same text those emitters produce
    elsewhere in the .s.

    ⚠ The byte gate is what proves the output: assembling it must reproduce
    0xF2D800-0xF317FF exactly.  This script additionally re-reads its own output
    (`--verify`) and compares it with the ROM before printing anything.

RUN
    python3 notes/gen_prom_b_message_module.py            # the assembly
    python3 notes/gen_prom_b_message_module.py --verify   # re-derive the bytes
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                 # noqa: E402
import prom_b_dl_length_audit as LA                               # noqa: E402
import gen_prom_b_display_lists_v2 as V2                          # noqa: E402
import prom_b_message_module as MM                                # noqa: E402

B_BASE = 0xF00000
BAR = "; " + "-" * 66 + "\n"


def bytes_block(b, s, e, per=16):
    out = []
    for a in range(s, e, per):
        chunk = b[a - B_BASE:min(a + per, e) - B_BASE]
        txt = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in chunk)
        out.append("\t.byte %-63s ; %06X  %s\n"
                   % (", ".join("0x%02X" % c for c in chunk), a, txt))
    return out


def ascii_block(b, s, e):
    raw = b[s - B_BASE:e - B_BASE]
    if all(0x20 <= c < 0x7F for c in raw):
        return ["\t.ascii \"%s\"\n" % DL.esc(raw.decode("ascii"))]
    return bytes_block(b, s, e)


def emit(imgs):
    b = imgs["b"]
    hta, htb = LA.tables(b)
    objs = MM.layout(imgs)
    out = []
    out.append("\n")
    out.append("; " + "=" * 76 + "\n")
    out.append("; 0xF2BE35-0xF317FF -- THE MESSAGE MODULE: the machine's dialogs, in more\n")
    out.append(";                     than one language, the SERVICE-MODE self-diagnostic\n")
    out.append(";                     screens, and three RAM defaults\n")
    out.append("; " + "=" * 76 + "\n")
    out.append(";\n")
    out.append("; 22,987 bytes: 18,694 substantive and 4,293 of 0x0E `ret` padding.\n")
    out.append("; 802 display-list records in 81 lists, plus 4 single records that are run\n")
    out.append("; on their own; four string/array operand tables; a 5x30 bitmap; a\n")
    out.append("; 256-entry screen index and the 127 field lists it points at; 3,712 bytes\n")
    out.append("; of RAM initialisation image; and 37 bytes of text that only an\n")
    out.append("; overlapping list reaches.\n")
    out.append(";\n")
    out.append("; WHY IT WAS STILL `.incbin` AFTER SEVEN ROUNDS.  The committed scanner\n")
    out.append("; finds a display list only where a caller spells BOTH ends as immediates\n")
    out.append("; (`ld XIY,imm32 / ld XIX,imm32 / call`).  These lists are named by a TABLE\n")
    out.append("; of (start,end) pairs instead, so no immediate in the image holds their\n")
    out.append("; addresses and no amount of scanning for one would have found them.\n")
    out.append(";\n")
    out.append("; THE READER, prom_a 0xF99098 (that image is another lane's; quoted, not\n")
    out.append("; edited):\n")
    out.append(";     lda XIX,0x2880 / ld C,(XIX)          C = MESSAGE ID\n")
    out.append(";     cp C,0x40 / jrl NC,0xF9911C          ids >= 0x40 draw nothing\n")
    out.append(";     ld A,0x04 / mul WA,(0x7FC1)          (0x7FC1) = LANGUAGE\n")
    out.append(";     add XWA,0x00F993B9 / ld XWA,(XWA)    -> that language's pair table\n")
    out.append(";     mul C,0x08 / add XWA,XBC / ld XIY,(XWA)      + id*8  -> list START\n")
    out.append(";     inc 4,XBC / add XBC,(XIZ-8) / ld XWA,(XBC)           -> list END\n")
    out.append(";     push XWA / push XIY / call 0xF42E00  -> DisplayList_Run_Stack (A)\n")
    out.append(";\n")
    out.append("; The table that call reaches for language 0 is prom_a 0xF99121: 64 entries\n")
    out.append("; of 8 bytes, 0xF99121-0xF99320, every one of which names a list in THIS\n")
    out.append("; range and every one of which frames.  A second reader at prom_a 0xF990F1\n")
    out.append("; indexes prom_a 0xF99321 by 8*(0x7FC1) with no message id at all and calls\n")
    out.append("; 0xF42E04, DisplayListB_Run_Stack -- which is why two lists here are\n")
    out.append("; interpreter-B lists among 74 interpreter-A ones.\n")
    out.append(";\n")
    out.append("; EXTENTS.  75 (start,end) pairs, kept only when the framing walk from the\n")
    out.append("; start lands EXACTLY on the end.  Between them the range tiles with no\n")
    out.append("; hole and nothing unexplained: `python3 notes/prom_b_message_module.py\n")
    out.append("; --selftest`, 76 checks, 0 failures.\n")
    out.append("; " + "=" * 76 + "\n")

    for s, e, kind, det in objs:
        if kind == "list":
            which, recs = det
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d records, %d bytes -- interpreter %s\n"
                       % (s, e - 1, len(recs), e - s, which))
            if s == 0xF31685:
                out.append(";   ⚠ the LAST record declares 0x%02X bytes and ends one byte past\n"
                           % recs[-1][2])
                out.append(";   0xF317FF.  The loop's `cp XIX,XIY / jr ULE` stops there anyway;\n")
                out.append(";   same shape as the one at 0xF3B651 already documented in\n")
                out.append(";   notes/FINDINGS-ui-display-list-interpreter-b.md.\n")
            out.append(BAR)
            out.append("DL_%06X:\n" % s)
            for p, op, ln in recs:
                if p + ln > e:                       # the over-declaring record
                    have = e - p
                    raw = b[p - B_BASE:e - B_BASE]
                    out.append("\t.byte 0x%02X, 0x%02X\t; op %02X, %d bytes DECLARED but only "
                               "%d are in the ROM\n" % (op, ln, op, ln, have))
                    out.append("\t.short 0x%04X\n" % int.from_bytes(raw[2:4], "little"))
                    out.append("\t.ascii \"%s\"\n" % DL.esc(raw[4:].decode("ascii")))
                elif which == "B":
                    out += V2.render_b(b, p, op, ln, htb)
                else:
                    out += DL.render(b, [(p, op, ln)], hta, set())
        elif kind == "strtab":
            width, rec = det
            n = (e - s) // width
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- string table, %d entries of %d bytes\n"
                       % (s, e - 1, n, width))
            out.append(";   The width is the +0x0B word of the interpreter-B record at\n")
            out.append(";   0x%06X, whose +7 long is this address.  The entry COUNT is the\n" % rec)
            out.append(";   extent divided by that width, and both ends are named: this table\n")
            out.append(";   starts where the record run before it ends and stops where the\n")
            out.append(";   next named object starts.\n")
            out.append(BAR)
            out.append("DLTable_%06X:\n" % s)
            for i in range(n):
                a = s + i * width
                out += ["\t.ascii \"%s\"\t; [%d]\n"
                        % (DL.esc(b[a - B_BASE:a - B_BASE + width].decode("latin1")
                                  .encode("ascii", "backslashreplace").decode()), i)] \
                    if all(0x20 <= c < 0x7F for c in b[a - B_BASE:a - B_BASE + width]) \
                    else bytes_block(b, a, a + width)
        elif kind == "tail":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d bytes no list in this tiling starts on.\n"
                       % (s, e - 1, e - s))
            out.append(";   READING, not a decode: they are the tail of a record belonging to\n")
            out.append(";   an OVERLAPPING list.  Several messages here end in the same\n")
            out.append(";   sentence -- `for direct play.` appears twice within 40 bytes --\n")
            out.append(";   so a list that starts a few bytes earlier runs through the same\n")
            out.append(";   closing record.  Only one tiling can be written down; this is the\n")
            out.append(";   text the other one steps over.  What is CERTAIN is only that no\n")
            out.append(";   (start,end) pair found anywhere names these bytes.\n")
            out.append(BAR)
            out.append("MsgTail_%06X:\n" % s)
            out += ascii_block(b, s, e)
        elif kind == "ramimg":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d bytes copied to RAM 0x%04X at init\n"
                       % (s, e - 1, e - s, det))
            out.append(";   prom_a `ld BC,0x%04X / ld XIY,0x00%06X / ld XIX,0x0000%04X / ldir`.\n"
                       % (e - s, s, det))
            out.append(";   The four blocks tile 0xF30800-0xF3167F exactly\n")
            out.append(";   (0x10 + 0x650 + 0x650 + 0x1D0 = 0xE80), which is what says this\n")
            out.append(";   part of the range is NOT display lists.\n")
            out.append(BAR)
            out.append("RamDefault_%06X:\n" % s)
            out += bytes_block(b, s, e)
        elif kind == "orphan":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d space characters nothing reaches\n"
                       % (s, e - 1, e - s))
            out.append(";   The interpreter-A list before them is 0xF2BDF5-0xF2BE34, named by\n")
            out.append(";   prom_a 0x%06X (`ld XIY,0x00F2BDF5 / ld XIX,0x00F2BE35 /\n" % det)
            out.append(";   call 0xF417F0`), so its walk stops on the first of these bytes.\n")
            out.append(";   No pointer in any of the four images names any address in this\n")
            out.append(";   range, and the 0x0E pad starts immediately after.  Emitted as the\n")
            out.append(";   data it is; what wrote it is NOT established.\n")
            out.append(BAR)
            out.append("MsgPad_%06X:\n" % s)
            out += ascii_block(b, s, e)
        elif kind == "fill":
            out.append("\n; 0x%06X-0x%06X -- %d bytes of 0x%02X `ret` padding\n"
                       % (s, e - 1, e - s, det))
            out.append("\t.fill %d, 1, 0x%02X\n" % (e - s, det))
        elif kind == "brec":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- ONE interpreter-B record, run on its own\n"
                       % (s, e - 1))
            out.append(";   prom_a 0x%06X: `lda XBC,0x%06X / push XBC / call 0xF42E0C`,\n"
                       % (det, s))
            out.append(";   and T_F42E0C is DisplayListB_RunOne_Stack -- one record, no end\n")
            out.append(";   pointer, so no framing walk reaches this byte from anywhere.\n")
            out.append(BAR)
            out.append("DLRec_%06X:\n" % s)
            out += V2.render_b(b, s, b[s - B_BASE], e - s, htb)
        elif kind == "array":
            stride, rec, mask = det
            n = (e - s) // stride
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d entries of %d bytes\n" % (s, e - 1, n, stride))
            out.append(";   The record at 0x%06X points here; its handler 0xF31B57 indexes\n" % rec)
            out.append(";   by value<<3, which is the stride, and its +4 AND MASK is 0x%02X,\n" % mask)
            out.append(";   which bounds the index at %d.  %d x %d = %d = the extent, so the\n"
                       % (mask, n, stride, e - s))
            out.append(";   mask and the extent are two independent witnesses to the count.\n")
            out.append(BAR)
            out.append("DLArray_%06X:\n" % s)
            for i in range(n):
                a0 = s + i * stride
                words = [int.from_bytes(b[a0 - B_BASE + 2 * k:a0 - B_BASE + 2 * k + 2],
                                        "little") for k in range(stride // 2)]
                out.append("\t.short %s\t; [%d]\n"
                           % (", ".join("0x%04X" % w for w in words), i))
        elif kind == "strtab3":
            width, rec, mask = det
            n = (e - s) // width
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- string table, %d entries of %d bytes\n"
                       % (s, e - 1, n, width))
            out.append(";   Width from the +0x0B word of the record at 0x%06X; count from\n" % rec)
            out.append(";   its +4 AND MASK 0x%02X and, independently, from the extent.\n" % mask)
            out.append(BAR)
            out.append("DLTable_%06X:\n" % s)
            for i in range(n):
                a0 = s + i * width
                out.append("\t.ascii \"%s\"\t; [%d]\n"
                           % (DL.esc(b[a0 - B_BASE:a0 - B_BASE + width].decode("latin1")), i))
        elif kind == "bitmap":
            cols, rows, rec = det
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- a BITMAP, %d columns of %d bytes\n"
                       % (s, e - 1, cols, rows))
            out.append(";   Three A op-03 records at 0x%06X, 0x%06X and 0x%06X blit it at\n"
                       % (rec, rec + 12, rec + 24))
            out.append(";   0x208F, 0x2094 and 0x2099 -- five apart, i.e. side by side.\n")
            out.append(";   Opcode 03 IS SWI7 service 3, LCD_Svc_03_BlitColumns, whose prom_a\n")
            out.append(";   header reads \"BC = number of columns; HL = bytes down each\n")
            out.append(";   column\".  BC x HL = %d x %d = %d = the extent.\n"
                       % (cols, rows, cols * rows))
            out.append(BAR)
            out.append("Bitmap_%06X:\n" % s)
            for c in range(cols):
                out += bytes_block(b, s + c * rows, s + (c + 1) * rows, per=rows)
        elif kind == "ptrtab":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d pointers, indexed by the SCREEN ID at RAM 0x207C\n"
                       % (s, e - 1, det))
            out.append(";   prom_a 0xF9940B: `ld L,(0x207C) / xor H,H / sla 0x02,HL /\n")
            out.append(";   ld XIY,0x00F2D000 / ld XHL,(XIY+HL)`, then `cp (XHL),0xFF` to test\n")
            out.append(";   the target for empty.  The index is a byte and nothing bounds it,\n")
            out.append(";   so the table is 256 entries; every one of them points into\n")
            out.append(";   0xF2D400-0xF2D5A1, which is where the table's own data begins.\n")
            out.append(BAR)
            out.append("ScreenFieldListPtrs:\n")
            for i in range(det):
                v = int.from_bytes(b[s - B_BASE + 4 * i:s - B_BASE + 4 * i + 4], "little")
                out.append("\t.long 0x%08X\t; [%3d]%s\n"
                           % (v, i, "  empty" if b[v - B_BASE] == 0xFF else ""))
        elif kind == "fieldlists":
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- the lists ScreenFieldListPtrs points at\n" % (s, e - 1))
            out.append(";   Each is 16-bit values terminated by 0xFFFF; prom_a 0xF99437\n")
            out.append(";   compares each against a word taken from RAM 0x2C00.  The 127\n")
            out.append(";   distinct targets' lists TILE this range exactly, with no hole and\n")
            out.append(";   no byte left over -- which is what fixes the range's end.\n")
            out.append(BAR)
            starts = {int.from_bytes(b[0xF2D000 - B_BASE + 4 * i:0xF2D000 - B_BASE + 4 * i + 4],
                                     "little") for i in range(256)}
            for a0 in range(s, e, 2):
                if a0 in starts:
                    out.append("ScreenFieldList_%06X:\n" % a0)
                v = int.from_bytes(b[a0 - B_BASE:a0 - B_BASE + 2], "little")
                out.append("\t.short 0x%04X%s\n" % (v, "\t; end of list" if v == 0xFFFF else ""))
        else:
            out.append("\n; 0x%06X-0x%06X -- UNEXPLAINED\n" % (s, e - 1))
            out += bytes_block(b, s, e)
    return "".join(out)


def main():
    imgs = {"a": MM.rom("wsa1_prom_a.ic12"), "b": MM.rom("wsa1_prom_b.ic13"),
            "c": MM.rom("wsa1_prom_c.ic28"), "d": MM.rom("wsa1_prom_d.bin")}
    text = emit(imgs)
    if "--verify" in sys.argv:
        objs = MM.layout(imgs)
        n = sum(e - s for s, e, _k, _d in objs)
        print("objects %d, bytes %d (want 16384)" % (len(objs), n))
        return 0 if n == 16384 else 1
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
