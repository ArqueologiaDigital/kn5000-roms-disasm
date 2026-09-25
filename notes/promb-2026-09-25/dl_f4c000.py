#!/usr/bin/env python3
r"""prom_b 0xF4C000-0xF4C38C: not one display list with no caller, but six pieces and their callers.

QUESTION THIS ANSWERS
    `DL_F4C000` was filed as 81 display-list records "nobody passes to an
    interpreter" (Called from: NOT established; Unknown: which interpreter
    runs it), emitted as framed `.byte` rows, with one record at 0xF4C2F8
    framing as op 0x00 length 134 -- "a shape nothing else in prom_b shows".
    The callers are in the same module and name the pieces with 24-bit
    `lda` operands (the stack call shape, `lda XBC,<end> / push XBC / lda
    XWA,<start> / push XWA / call T_DisplayList{,B}_Run_Stack`):

      sub_F4C5C9  0xF4C5D9/DF  A  0xF4C000-0xF4C044  when (0x2870) == 0
                  0xF4C5E7/ED  A  0xF4C045-0xF4C070  when (0x2870) != 0
                  0xF4C5F7/FD  A  0xF4C071-0xF4C2B6  always
      sub_F4C60C  0xF4C613/19  B  0xF4C36F-0xF4C38C
                  0xF4C66B/71  B  0xF4C2B7-0xF4C2E2  with (0x2540) = 1

    and 0xF4C2E3-0xF4C36E is not records at all: it is the four entry arrays
    the B list at 0xF4C2B7 points at (`+0x07` of each record) -- two 6-byte
    entries for op 0x04 (mask 0, so one entry each) and two 8-entry arrays of
    8-byte entries for op 0x03 (mask 7) -- 6 + 6 + 64 + 64 = 140 bytes, which
    tile the gap exactly.  The "op 0x00, length 134" was the flat walk
    reading those arrays as a record.

    Each piece is checked to walk exactly by its own length bytes, and is
    rendered with the tree's own record renderers
    (scripts/analysis/prom_b_display_lists.py for interpreter A,
    notes/gen_prom_b_display_lists_v2.py render_b for B), read-only.

RUN
    python3 notes/promb-2026-09-25/dl_f4c000.py            # checks
    python3 notes/promb-2026-09-25/dl_f4c000.py --apply    # write the source
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WSA1 = os.path.join(ROOT, "wsa1")
sys.path.insert(0, os.path.join(WSA1, "notes"))
sys.path.insert(0, os.path.join(WSA1, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
import gen_prom_b_display_lists_v2 as DLV2  # noqa: E402

SRC = os.path.join(WSA1, "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(WSA1, "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
RUN_A, RUN_B = 0xF42E00, 0xF42E04
FAIL = []

# (label, start, end_excl, interpreter, lda-end site, lda-start site, call site, run target, note)
PIECES = [
    ("DL_CreatorSelectController", 0xF4C000, 0xF4C045, "A", 0xF4C5D9, 0xF4C5DF, 0xF4C5F3, RUN_A,
     "the title, drawn when (0x2870) == 0: CREATOR SELECT (op 0x1C, the title face), CONTROLLER, "
     "a 24x24 glyph and two frames"),
    ("DL_CreatorSelectController_Alt", 0xF4C045, 0xF4C071, "A", 0xF4C5E7, 0xF4C5ED, 0xF4C5F3,
     RUN_A, "the same title drawn when (0x2870) != 0 -- the same run call as the first piece, "
     "reached through the other arm of `cp (0x2870),0 / jr nz`"),
    ("DL_CreatorSelectController_Grid", 0xF4C071, 0xF4C2B7, "A", 0xF4C5F7, 0xF4C5FD, 0xF4C603,
     RUN_A, "always drawn after the title: two rows of the digits 1-6 and the frames and "
     "lines of a six-slot grid"),
    ("DLB_CreatorSelectController_Cursor", 0xF4C2B7, 0xF4C2E3, "B", 0xF4C66B, 0xF4C671, 0xF4C677,
     RUN_B, "four interpreter-B records on (0x2640): two op-0x04 records (swi 7 fn 0x0E, "
     "LCD_Svc_0E_ClearColumns, one 6-byte IY/BC/HL entry each since their mask is 0) and two "
     "op-0x03 records (fn 5, LCD_Svc_05_FillRect, 8-byte x0/y0/x1/y1 entries indexed by "
     "(0x2640) & 7).  sub_F4C60C sets (0x2640) to the index of the lowest set bit among the "
     "low six of IndexedTable_GetByte(25 or 26, 32 + (0x2250)) before running it -- the "
     "selected slot of the grid"),
    ("DLB_CreatorSelectController_Names", 0xF4C36F, 0xF4C38D, "B", 0xF4C613, 0xF4C619, 0xF4C61F,
     RUN_B, "two op-0x02 string readouts with source (0x0000) and mask 0 -- entry 0 of the "
     "13-byte string tables at RAM 0x2950 and 0x2940, drawn with swi 7 fn 0x20"),
]
ARRAYS_AT = 0xF4C2E3


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    for lab, s, e, interp, le, ls, call, tgt, _ in PIECES:
        ok = (at(le, 1) == b"\xf2" and int.from_bytes(at(le + 1, 3), "little") == e and
              at(le + 4, 1) == b"\x31" and at(ls, 1) == b"\xf2" and
              int.from_bytes(at(ls + 1, 3), "little") == s and at(ls + 4, 1) == b"\x30" and
              at(call, 1) == b"\x1d" and int.from_bytes(at(call + 1, 3), "little") == tgt)
        check("%s: `lda XBC,0x%06X` at 0x%06X, `lda XWA,0x%06X` at 0x%06X, `call 0x%06X` "
              "(interpreter %s) at 0x%06X" % (lab, e, le, s, ls, tgt, interp, call), ok)
        r = DL.walk(b, s, e)
        check("  0x%06X-0x%06X walks exactly by its own length bytes (%s records)"
              % (s, e - 1, None if r is None else len(r)), r is not None)
    # the four B records' tables
    r = DL.walk(b, 0xF4C2B7, 0xF4C2E3)
    arrays = []
    for p, op, ln in r:
        mask = b[p - BASE + 4]
        ptr = int.from_bytes(at(p + 7, 4), "little")
        stride = {0x04: 6, 0x03: 8}[op]
        arrays.append((ptr, op, mask, stride, (mask + 1) * stride))
    a = ARRAYS_AT
    tile = True
    for ptr, op, mask, stride, size in arrays:
        tile &= ptr == a
        a += size
    check("the B records' +0x07 arrays (%s) tile 0xF4C2E3-0xF4C36E exactly, entries = mask+1"
          % ", ".join("0x%06X op%02X x%d" % (p, o, m + 1) for p, o, m, _, _ in arrays),
          tile and a == 0xF4C36F)
    return b, arrays


def render(b, arrays):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]
    out = [HEADER.rstrip("\n")]
    for lab, s, e, interp, le, ls, call, tgt, note in PIECES[:4]:
        out += piece(b, lab, s, e, interp, le, call, note, hta, htb)
    # the arrays
    names = ["CreatorSelectController_ClearArea", "CreatorSelectController_ClearArea2",
             "CreatorSelectController_Boxes", "CreatorSelectController_Boxes2"]
    import textwrap
    out += textwrap.wrap("The four entry arrays DLB_CreatorSelectController_Cursor's records point at "
                         "(+0x07): an op-0x04 entry is IY, BC, HL for swi 7 fn 0x0E; an op-0x03 "
                         "entry is four words for (0x2530)..(0x2536), fn 5.", width=76,
                         initial_indent="; ", subsequent_indent=";   ")
    for (ptr, op, mask, stride, size), nm in zip(arrays, names):
        out.append("%s:\t\t; %d entr%s of %d bytes, index (0x2640) & 0x%02X"
                   % (nm, mask + 1, "y" if mask == 0 else "ies", stride, mask))
        for k in range(mask + 1):
            w = [int.from_bytes(b[ptr - BASE + stride * k + 2 * i:ptr - BASE + stride * k + 2 * i + 2],
                                "little") for i in range(stride // 2)]
            out.append("\t.short\t%s\t; %06X  [%d] %s" % (", ".join("0x%04x" % x for x in w),
                                                         ptr + stride * k, k,
                                                         "IY, BC, HL" if op == 0x04 else
                                                         "x0, y0, x1, y1"))
    lab, s, e, interp, le, ls, call, tgt, note = PIECES[4]
    out += piece(b, lab, s, e, interp, le, call, note, hta, htb)
    return "\n".join(out) + "\n"


def piece(b, lab, s, e, interp, le, call, note, hta, htb):
    import textwrap
    out = ["; " + "-" * 74]
    out += textwrap.wrap("%s -- 0x%06X-0x%06X, interpreter %s: %s.  Run by %s: `lda XBC,0x%06X` "
                         "(the end) / `lda XWA,0x%06X` / `call %s` at 0x%06X."
                         % (lab, s, e - 1, interp, note,
                            "sub_F4C5C9" if interp == "A" else "sub_F4C60C", e, s,
                            "T_DisplayList_Run_Stack" if interp == "A"
                            else "T_DisplayListB_Run_Stack", call),
                         width=76, initial_indent="; ", subsequent_indent=";   ")
    out.append("; " + "-" * 74)
    out.append("%s:" % lab)
    recs = DL.walk(b, s, e)
    if interp == "B":
        for p, op, ln in recs:
            out += [x.rstrip("\n") for x in "".join(DLV2.render_b(b, p, op, ln, htb)).split("\n")
                    if x.strip()]
    else:
        out += [x for x in "".join(DL.render(b, recs, hta, set())).rstrip("\n").split("\n")]
    return out


HEADER = """; --------------------------------------------------------------------------
; 0xF4C000-0xF4C38C -- THE "CREATOR SELECT / CONTROLLER" SCREEN: three
;   interpreter-A lists, one interpreter-B list, the four entry arrays that
;   B list reads, and a second B list.  Rendered record by record.
; ⚠ REPLACES `DL_F4C000`, filed as 81 records with "Called from: NOT
;   established" and "Unknown: which interpreter runs it" -- both false:
;   sub_F4C5C9 and sub_F4C60C in this module name every piece with 24-bit
;   `lda` operands and run it through T_DisplayList_Run_Stack (A) or
;   T_DisplayListB_Run_Stack (B).  The record that framed as "op 0x00 with
;   length 134" at 0xF4C2F8 was the flat walk reading the entry arrays at
;   0xF4C2E3 as a record.  Checked by python3 notes/promb-2026-09-25/
;   dl_f4c000.py (the lda/call bytes, every piece's walk, the arrays' tiling).
; --------------------------------------------------------------------------
"""

BANNER_OLD = """;             is re-run on every emit.  Nothing spells 0xF4C000 as a 32-bit word,
;             so the list's caller is not established and the records are emitted
;             as framed `.byte` rows rather than rendered."""
BANNER_NEW = BANNER_OLD + """
;             \u26a0 2026-09-25 (lane promb): the callers ARE in this module, with
;             24-bit `lda` operands -- sub_F4C5C9 and sub_F4C60C -- and the span is
;             six pieces, rendered below as DL_CreatorSelectController et al."""


def apply(b, arrays):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    i = [k for k, t in enumerate(L) if t.startswith("DL_F4C000:")]
    j = [k for k, t in enumerate(L) if t.startswith("DispatchTable_F4C38D:")]
    assert len(i) == 1 and len(j) == 1
    s = i[0]
    while L[s - 1].startswith(";"):
        s -= 1
    e = j[0]
    while L[e - 1].startswith(";"):
        e -= 1
    while not L[e - 1].strip():
        e -= 1
    L = L[:s] + ["@@DL_F4C000_BLOCK@@"] + L[e:]
    txt = "\n".join(L)
    assert txt.count(BANNER_OLD) == 1
    txt = txt.replace(BANNER_OLD, BANNER_NEW.encode("utf-8").decode("latin-1"))
    txt = re.sub(r'\bDL_F4C000 \+ 0x45\b', "DL_CreatorSelectController_Alt", txt)
    txt = re.sub(r'\bDL_F4C000 \+ 0x71\b', "DL_CreatorSelectController_Grid", txt)
    txt = re.sub(r'\bDL_F4C000 \+ 0x2B7\b', "DLB_CreatorSelectController_Cursor", txt)
    txt = re.sub(r'\bDL_F4C000 \+ 0x2E3\b', "CreatorSelectController_ClearArea", txt)
    txt = re.sub(r'\bDL_F4C000 \+ 0x36F\b', "DLB_CreatorSelectController_Names", txt)
    txt = re.sub(r'\bDL_F4C000\b(?! --)', "DL_CreatorSelectController", txt)
    # the new block goes in AFTER the renames, so its own mention of the old name survives
    txt = txt.replace("@@DL_F4C000_BLOCK@@",
                      render(b, arrays).encode("utf-8").decode("latin-1").rstrip("\n"))
    data = txt.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


def main():
    b, arrays = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--show" in sys.argv:
        sys.stdout.write(render(b, arrays))
    if "--apply" in sys.argv:
        apply(b, arrays)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
