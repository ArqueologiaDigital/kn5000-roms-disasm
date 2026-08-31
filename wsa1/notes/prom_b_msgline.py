#!/usr/bin/env python3
"""What is the 30-character text line at RAM 0x00000FE4, and who writes it?

WHAT QUESTION THIS ANSWERS
--------------------------
  prom_b holds three dozen short routines that all end the same way: they copy
  an ASCII literal out of the ROM into a fixed low-RAM address between 0x0FE4
  and 0x1001, then `call 0xf431b4`.  Every one of them was `sub_XXXXXX`, and the
  reason is that nothing in the routine says what 0x0FE4 IS.

  It is one line of on-screen text.  This script derives that from the ROM
  rather than asserting it, in four steps that do not depend on each other:

    1. THE RECORD.  prom_a 0xF81C15 -- reached from prom_b through thunk slot
       T_F431B4 -> the veneer at 0xF7D006 -> `jrl 0xF81C15` -- runs the single
       interpreter-B record at 0xF3D38A through the opcode-0x02 handler
       (T_F417F8 -> DisplayListB_StringTable, 0xF31B21).  Those 15 bytes are
       read here and their fields printed: XIY = 0x00000FE4, BC = 30,
       `swi 7` function 6, cursor IX.
    2. THE SERVICE.  prom_a's SWI7 service 6 is LCD_Svc_06_DrawText8x14: it
       draws BC glyphs of the 14-byte-per-cell 8-wide font at 0xF1B400,
       starting at XIY + HL*BC, to LCD cursor IX + (0x2555).  So the record
       draws THIRTY CHARACTERS starting at 0x00000FE4.
    3. THE GEOMETRY.  LCD_Init_SED1330 programs AP = 40 bytes per display line
       (prom_a 0xF8E850/0xF8E85B), so a cursor value splits as
       (row, col) = divmod(IX, 40).  Three sibling records give three more
       lines; all four are printed with their pixel position.
    4. THE WRITERS.  Every routine of the committed prom_b source that copies
       into 0x0FE4-0x1001 is listed with the literal it copies, the offset it
       copies to, and the sub-screen code it claims in (0x0EF5).

  ★ THE BUFFER'S LENGTH IS SAID TWICE, BY TWO UNRELATED PIECES OF CODE, and the
  two agree: the record's BC is 30, and MsgLine_Control (0xF6D410) blanks the
  line with `ld WA,0x2020 / ld BC,0x000F / ld (XIX+),WA / djnz` from 0x0FE4 --
  fifteen 16-bit stores, 30 bytes, ending exactly at 0x1001.  Neither number was
  derived from the other.

WHAT THIS DOES NOT ESTABLISH
  Which screen the four lines belong to is NOT decided here.  prom_a 0xF81C15
  and 0xF81ACB both refuse to draw unless the screen id (0x207C) is 0x0E, and
  that is all that is known: 0x0E is a number, and no table in this tree yet
  says what screen 0x0E is called.  Nothing below is named for a screen.

  The three sibling lines at 0x1012, 0x1030 and 0x104E have NO writers in the
  converted part of prom_b.  They are listed because the records are real, not
  because anything here reaches them.

RUN
    python3 notes/prom_b_msgline.py             # the four lines + the writers
    python3 notes/prom_b_msgline.py --writers   # only the writer table
    python3 notes/prom_b_msgline.py --selftest  # 30 checks, incl. 2 negative
Exit status is non-zero if a check fails.
"""
import os
import re
import sys
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402  (the image, not the master)

B_BASE = 0xF00000
A_BASE = 0xF80000
BUF_LO, BUF_LEN = 0x0FE4, 30
BUF_HI = BUF_LO + BUF_LEN                      # 0x1002, exclusive
LINE_RECORDS = (0xF3D38A, 0xF3D3AD, 0xF3D3CB, 0xF3D3E9)
AP = 40                                        # bytes per display line, prom_a 0xF8E850/0xF8E85B
FONT_BASE, FONT_H, FONT_W = 0xF1B400, 14, 8    # prom_a LCD_Svc_06_DrawText8x14
PAINT_SLOT = 0xF431B4                          # -> 0xF7D006 -> prom_a 0xF81C15
PREP_SLOT = 0xF431B0                           # -> 0xF7D000 -> prom_a 0xF81ACB
SUBSCREEN_VAR = 0x0EF5
SCREEN_ID_VAR = 0x207C

LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s(.*)$")


def rom(name):
    fn = {"prom_a": "wsa1_prom_a.ic12", "prom_b": "wsa1_prom_b.ic13"}[name]
    with open(os.path.join(ROOT, "original_ROMs", fn), "rb") as f:
        return f.read()


def text_at(b, addr, n):
    o = addr - B_BASE
    return "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in b[o:o + n])


def le(b, addr, n):
    o = addr - B_BASE
    return int.from_bytes(b[o:o + n], "little")


def line_records(b):
    """-> [(record addr, buffer, width, swi7 fn, cursor, row, col)]"""
    out = []
    for a in LINE_RECORDS:
        opcode, length = b[a - B_BASE], b[a - B_BASE + 1]
        fn = b[a - B_BASE + 6]
        buf = le(b, a + 7, 4)
        wid = le(b, a + 0x0B, 2)
        cur = le(b, a + 0x0D, 2)
        row, col = divmod(cur, AP)
        out.append((a, opcode, length, fn, buf, wid, cur, row, col))
    return out


def source_rows():
    """-> {label: [(addr, mame text)]}, in emission order, from the IMAGE."""
    seq = collections.OrderedDict()
    cur = None
    for ln in image_lines(ROOT, "prom_b/wsa1_prom_b.s"):
        m = LABEL.match(ln)
        if m:
            cur = m.group(1)
            seq.setdefault(cur, [])
        if ln.lstrip().startswith(";"):
            continue
        m2 = ADDRC.search(ln)
        if m2 and cur is not None:
            seq[cur].append((int(m2.group(1), 16), m2.group(2).strip()))
    return seq


def writers(seq, b):
    """Routines that copy into 0x0FE4-0x1001.

    -> [(entry, label, [codes], [(site, src, width, indexed, dst)], paints, preps)]
    A copy is `ld XIX,<dst>` ... `ldir`/`ldirw`, the only two block moves this
    family uses; `indexed` records that an `lda XIY,XIY+<reg>` came between the
    source load and the move, which means the source is a TABLE and the literal
    printed is its entry 0.
    """
    out = []
    for name, rows in seq.items():
        if not rows:
            continue
        xix = xiy = bc = None
        last_dst = None
        indexed = False
        copies, codes = [], []
        touches_buf = False
        for a, t in rows:
            m = re.fullmatch(r"ld XIX,0x([0-9a-f]+)", t)
            if m:
                xix = int(m.group(1), 16)
                if BUF_LO <= xix < BUF_HI:
                    touches_buf = True
                continue
            m = re.fullmatch(r"ld XIY,0x([0-9a-f]+)", t)
            if m:
                xiy, indexed = int(m.group(1), 16), False
                continue
            m = re.fullmatch(r"ld BC,0x([0-9a-f]+)", t)
            if m:
                bc = int(m.group(1), 16)
                continue
            if re.match(r"lda XIY,XIY\+", t):
                indexed = True
                continue
            m = re.fullmatch(r"(?:ld|cp) \(0x0ef5\),0x([0-9a-f]+)", t)
            if m:
                codes.append(int(m.group(1), 16))
                continue
            if t in ("ldir", "ldirw") and xix is not None and BUF_LO <= xix < BUF_HI:
                if xiy is not None and bc:
                    n = bc * (2 if t == "ldirw" else 1)
                    copies.append((a, xiy, n, indexed, xix, xix is not last_dst))
                    last_dst = xix
                xiy = None
        if not (copies or touches_buf):
            continue
        texts = [t for _, t in rows]
        paints = "call 0xf431b4" in texts
        preps = "call 0xf431b0" in texts
        out.append((rows[0][0], name, sorted(set(codes)), copies, paints, preps))
    out.sort()
    return out


def non_buffer_ldir_count(seq):
    """NEGATIVE CONTROL: `ldir` from a ROM literal to somewhere that is NOT the line."""
    n = 0
    for name, rows in seq.items():
        xix = xiy = None
        for a, t in rows:
            m = re.fullmatch(r"ld XIX,0x([0-9a-f]+)", t)
            if m:
                xix = int(m.group(1), 16)
            m = re.fullmatch(r"ld XIY,0x([0-9a-f]+)", t)
            if m:
                xiy = int(m.group(1), 16)
            if t in ("ldir", "ldirw"):
                if xiy is not None and xiy >= B_BASE and not (xix is not None and BUF_LO <= xix < BUF_HI):
                    n += 1
                xiy = None
    return n


def report(only_writers=False):
    b = rom("prom_b")
    if not only_writers:
        print(f"THE FOUR TEXT LINES  (AP = {AP} bytes/line, font {FONT_W}x{FONT_H} at 0x{FONT_BASE:06X})")
        print(f"  {'record':9s} {'op':>4s} {'len':>4s} {'swi7':>5s} {'buffer':>9s} {'chars':>6s} {'cursor':>7s}   pixel x,y")
        for a, op, ln, fn, buf, wid, cur, row, col in line_records(b):
            print(f"  0x{a:06X} {op:4d} {ln:4d} {fn:5d}  0x{buf:06X} {wid:6d}  0x{cur:04X}   x={col*FONT_W:3d} y={row:3d}")
        print()
        print(f"  drawn by prom_a 0xF81C15, reached from prom_b through slot T_0x{PAINT_SLOT:06X};")
        print(f"  neither it nor prom_a 0xF81ACB draws unless (0x{SCREEN_ID_VAR:04X}) == 0x0E.")
        print()
    seq = source_rows()
    ws = writers(seq, b)
    print(f"WRITERS OF 0x{BUF_LO:04X}-0x{BUF_HI - 1:04X}  ({len(ws)} routines in the committed source)")
    for entry, name, codes, copies, paints, preps in ws:
        cs = ",".join("0x%02X" % c for c in codes) or "-"
        flags = ("P" if paints else "-") + ("R" if preps else "-")
        print(f"  0x{entry:06X} {name:34s} (0x0EF5)={cs:9s} {flags}")
        for site, src, n, idx, dst, fresh in copies:
            kind = "table" if idx else ("RAM" if src < B_BASE else "literal")
            where = f"+{dst - BUF_LO:<2d}" if fresh else "then"
            body = text_at(b, src, n) if src >= B_BASE else f"(0x{src:04X}) {n} digit(s)"
            print(f"      @0x{site:06X} {where} {n:2d}ch  {kind:7s} 0x{src:06X}  {body!r}")
    print()
    print(f"  P = calls the painter (slot 0x{PAINT_SLOT:06X}); R = calls the full-repaint entry (slot 0x{PREP_SLOT:06X}).")
    print(f"  `+n` is the offset into the 30-character line; `table` means an")
    print(f"  `lda XIY,XIY+<reg>` indexed the source, so the literal shown is entry 0.")


CHECKS = []


def ck(cond, what):
    CHECKS.append((bool(cond), what))


def selftest():
    b = rom("prom_b")
    a = rom("prom_a")
    recs = line_records(b)
    ck(len(recs) == 4, "four line records")
    for r in recs:
        addr, op, ln, fn, buf, wid, cur, row, col = r
        ck(op == 0x02, f"0x{addr:06X} is interpreter-B opcode 0x02")
        ck(ln == 0x0F, f"0x{addr:06X} declares 15 bytes")
        ck(fn == 6, f"0x{addr:06X} calls swi7 function 6")
        ck(wid == BUF_LEN, f"0x{addr:06X} draws {BUF_LEN} characters")
        ck(buf < 0x010000, f"0x{addr:06X} points at low RAM (0x{buf:06X})")
        ck(col * FONT_W < 320 and row < 240, f"0x{addr:06X} cursor 0x{cur:04X} lands on the panel")
    ck(recs[0][4] == BUF_LO, "the first record's buffer is 0x0FE4")
    ck(len({r[4] for r in recs}) == 4, "the four buffers are distinct")

    # the second, independent statement of the length: the blank-out loop
    txt = {}
    seq = source_rows()
    for name, rows in seq.items():
        for addr, t in rows:
            txt[addr] = t
    ck(txt.get(0xF6D413) == "ld XIX,0x00000fe4", "0xF6D413 aims the blank-out at 0x0FE4")
    ck(txt.get(0xF6D418) == "ld WA,0x2020", "0xF6D418 loads two spaces")
    ck(txt.get(0xF6D41B) == "ld BC,0x000f", "0xF6D41B counts 15")
    ck(txt.get(0xF6D41E) == "ld (XIX+),WA", "0xF6D41E stores a word and steps")
    ck(15 * 2 == BUF_LEN, "15 word stores == 30 bytes == the record's character count")

    # the thunk slots really are what the header says
    for slot, want in ((PAINT_SLOT, 0xF7D006), (PREP_SLOT, 0xF7D000)):
        o = slot - B_BASE
        ck(b[o] == 0x1B, f"slot 0x{slot:06X} is a `jp`")
        ck(le(b, slot + 1, 3) == want, f"slot 0x{slot:06X} -> 0x{want:06X}")

    # AP = 40 is read off prom_a's SYSTEM SET, not assumed
    ck(a[0xF8E851 - A_BASE] == 0x28, "prom_a 0xF8E850 sends APL = 0x28")
    ck(a[0xF8E85C - A_BASE] == 0x00, "prom_a 0xF8E85B sends APH = 0x00")
    ck(0x0028 == AP, "AP = 40 bytes per display line")

    ws = writers(seq, b)
    ck(len(ws) >= 30, f"at least 30 writers found ({len(ws)})")
    named = [w for w in ws if w[1].startswith("MsgLine_")]
    ck(len(named) >= 30, f"at least 30 of them carry a MsgLine_ name ({len(named)})")
    ck(all(BUF_LO <= c[4] < BUF_HI for _, _, _, cps, _, _ in ws for c in cps),
       "every copy this script reports lands inside the line")

    # NEGATIVE CONTROLS
    n_other = non_buffer_ldir_count(seq)
    ck(n_other > 0, f"the ldir shape is NOT unique to this line ({n_other} elsewhere) "
                    f"-- the buffer address is what selects the family, not the shape")
    ck(not any(w[1].startswith("MsgLine_") for w in ws if not w[3]) or True, "")
    CHECKS.pop()  # drop the placeholder above
    ck(text_at(b, 0xF6DF50, 7) == "PANPOT=", "the 0xF6DEF7 literal still reads PANPOT=")
    ck(text_at(b, 0xF6E1A6, 11) == "DSP EFFECT ", "the 0xF6E152 literal still reads DSP EFFECT")

    bad = [w for ok, w in CHECKS if not ok]
    for ok, what in CHECKS:
        print(("  ok   " if ok else "  FAIL ") + what)
    print(f"\n{len(CHECKS) - len(bad)}/{len(CHECKS)} checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    report(only_writers="--writers" in sys.argv)
