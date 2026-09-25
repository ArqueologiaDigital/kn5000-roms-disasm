#!/usr/bin/env python3
r"""PtrTable_F99121 (0xF99121-0xF993C4) is four tables, each named by its own reader.

QUESTION THIS ANSWERS
    The old header of PtrTable_F99121 found ONE reader (at +0x200) and wrote
    "what indexes entries 0..127 is NOT ESTABLISHED".  The previous address
    pass spelled every reader's operand as PtrTable_F99121+<offset>, which
    shows THREE readers at three offsets, and each one fixes a table:

      +0x000  64 (start, end) LE32 pairs, index = message id (0x2880) < 0x40,
              reached THROUGH +0x298 by sub_F99098 (0xF99098), which draws
              the pair with T_DisplayList_Run_Stack (interpreter A)
      +0x200  3 (start, end) pairs, index = (0x7FC1), drawn with
              T_DisplayListB_Run_Stack by the same routine when the id is 0x1A
      +0x218  32 LE32 handlers, index = T_F4160C's first argument (<= 0x1F),
              called by sub_F9904D (0xF9904D)
      +0x298  3 LE32 pointers, index = (0x7FC1), each = +0x000

    prom_b's message module header (the other image's lane) documents the
    pair lists as its dialogs and reads (0x7FC1) as the LANGUAGE; this file
    quotes that, it does not re-derive it.

CHECKS (against wsa1/original_ROMs)
    Q1  sub_F99098: `cp C,0x40 / jrl nc` (F990A3), `mul C,8` (F990AF),
        `ld A,4 / mul WA,(0x7FC1)` (F990B7), `add XWA,0xF993B9` (F990BF),
        `ld XIY,(XWA)` (F990CC), `inc 4,XBC` (F990D1), `call 0xF42E00` (F990DA)
    Q2  `cp C,0x1A` (F990E2), `ld C,8 / mul BC,(0x7FC1)` (F990EF), `add
        XBC,0xF99321` (F990F9), `inc 4,XWA / add XWA,0xF99321` (F99106),
        `call 0xF42E04` (F99112)
    Q3  sub_F9904D: `cp (XIZ+8),0x001F / jr ugt` (F99052), `ldw BC,4 /
        mul BC,(XIZ+8)` (F9906A), `add XBC,0xF99339` (F99070), `jp (XBC)`
        (F9907E); prom_b directory slot T_F4160C is `jp 0xF9904D`
    Q4  the 64 + 3 pairs are prom_b addresses with start < end; the 32
        handlers are 0xF99120 (a lone `ret`) or 0xF99085; the 3 language
        pointers all equal 0xF99121; 0xF993C5 starts the 0x0E pad

RUN
    python3 notes/proma-2026-09-25/gen_message_pairs.py          # checks
    python3 notes/proma-2026-09-25/gen_message_pairs.py --apply  # ran once
    python3 notes/proma-2026-09-25/symbolize_prom_a_addresses.py --apply   # then: prom_b names
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
BASE = 0xF99121
ROMB = os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13")


def at(r, a, h):
    return r[a - B:a - B + len(bytes.fromhex(h))] == bytes.fromhex(h)


def l32(r, a):
    return int.from_bytes(r[a - B:a - B + 4], "little")


def checks(r):
    for a, h in ((0xF990A3, "cbcf40"), (0xF990A6, "7f"), (0xF990AF, "cb0808"), (0xF990B7, "2104"),
                 (0xF990B9, "c1c17f41"), (0xF990BF, "e8c8b993f900"), (0xF990CC, "a025"),
                 (0xF990D1, "e964"), (0xF990DA, "1d002ef4")):
        assert at(r, a, h), hex(a)
    print("Q1 ok: sub_F99098 indexes the language table, then (id*8) into the pair table")
    for a, h in ((0xF990E2, "cbcf1a"), (0xF990EF, "2308"), (0xF990F1, "c1c17f43"),
                 (0xF990F9, "e9c82193f900"), (0xF99106, "e864"), (0xF99108, "e8c82193f900"),
                 (0xF99112, "1d042ef4")):
        assert at(r, a, h), hex(a)
    print("Q2 ok: message 0x1A also draws the (0x7FC1)-th interpreter-B pair")
    for a, h in ((0xF99052, "9e083f1f00"), (0xF99057, "6b"), (0xF9906A, "310400"), (0xF9906D, "9e0841"),
                 (0xF99070, "e9c83993f900"), (0xF9907E, "b1d8")):
        assert at(r, a, h), hex(a)
    rb = open(ROMB, "rb").read()
    assert rb[0xF4160C - 0xF00000:0xF41610 - 0xF00000] == bytes.fromhex("1b4d90f9")
    print("Q3 ok: sub_F9904D (directory slot T_F4160C) calls handler[arg <= 0x1F]")
    pairs = [(l32(r, BASE + 8 * k), l32(r, BASE + 8 * k + 4)) for k in range(64)]
    bpairs = [(l32(r, 0xF99321 + 8 * k), l32(r, 0xF99325 + 8 * k)) for k in range(3)]
    for s, e in pairs + bpairs:
        assert 0xF00000 <= s < e < 0xF80000, (hex(s), hex(e))
    hand = [l32(r, 0xF99339 + 4 * k) for k in range(32)]
    assert set(hand) == {0xF99120, 0xF99085} and r[0xF99120 - B] == 0x0E
    lang = [l32(r, 0xF993B9 + 4 * k) for k in range(3)]
    assert lang == [BASE] * 3 and r[0xF993C5 - B] == 0x0E
    print("Q4 ok: 64 + 3 prom_b (start,end) pairs; handlers %s; 3 x 0xF99121; pad at 0xF993C5"
          % sorted(hex(x) for x in set(hand)))
    return pairs, bpairs, hand


def apply(r, pairs, bpairs, hand):
    m = srcmap.load()
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    dash = "; ---------------------------------------------------------------------"
    i0 = L.index("; PtrTable_F99121 -- 169 LE32 pointers, 676 bytes") - 1
    assert L[i0] == dash
    i1 = next(k for k in range(i0, i0 + 120) if re.search(r";\s*F993C5\s", L[k]))
    old_hdr = L[i0:L.index("PtrTable_F99121:", i0)]
    new = [dash,
           "; MessageScreen_ListPairs -- 64 (start, end) LE32 pairs, one display list per",
           ";          message id; this span was PtrTable_F99121, whose header (kept",
           ";          below) found only the +0x200 reader.",
           "; Read by: sub_F99098 (0xF99098, posted by sub_F99021 through",
           ";          T_CallbackQueue_Post): id = (0x2880), `cp C,0x40 / jrl nc` -- ids",
           ";          0x40 and up draw nothing, hence COUNT 64 -- then `ld A,4 / mul",
           ";          WA,(0x7FC1) / add XWA,MessageScreen_PairTableByLanguage / ld XWA,",
           ";          (XWA)` for THIS table, `mul C,8`, start = (table + id*8), end =",
           ";          (table + id*8 + 4), and T_DisplayList_Run_Stack(start, end).",
           "; Values: every start and end is a prom_b display list in the message",
           ";          module whose header quotes this reader (prom_b 0xF2BE35-, the",
           ";          `DL_` lists); start < end for all 64 (check Q4).",
           "; (notes/proma-2026-09-25/gen_message_pairs.py, checks Q1-Q4)",
           dash]
    ext = old_hdr.index(";          run: 0xF99120 is a `ret` that ends the routine above, and the four") - 1
    assert old_hdr[ext].startswith("; Extent:  0xF99121-0xF993C4.")
    # The prose below is plain str and the final assignment encodes everything
    # ONCE.  The run that applied this wrapped the list in u8() too, which
    # double-encoded the star; that one line was repaired in the source by hand.
    # old_hdr lines are already latin-1 text, so they are decoded back first.
    new = new[:-1] + [x.encode("latin-1").decode("utf-8") for x in old_hdr[ext:ext + 3]] + [
        ";          (The `ret` at 0xF99120 is now labelled MessageScreen_ArgIgnore.)",
        "; ★ CORRECTED 2026-09-25 (lane proma).  This span was PtrTable_F99121: 169",
        ";          LE32 pointers with one located reader (+0x200) and none for",
        ";          entries 0..127, a count taken from the shape detector",
        ";          (notes/prom_a_ptr_tables.py) for want of a reader bound, and the",
        ";          entries' meaning open.  Three readers at +0x000 (via +0x298),",
        ";          +0x200 and +0x218 split it into the four tables below, each with",
        ";          its own count; the detector's 169 = 128 + 6 + 32 + 3, and the old",
        ";          \"self-reference\" (three entries = the base, asserted by",
        ";          wsa1/notes/prom_a_uiblock_checks.py 1f) is",
        ";          MessageScreen_PairTableByLanguage.",
        dash, "MessageScreen_ListPairs:"]
    for k, (s, e) in enumerate(pairs):
        new.append("\t.long 0x%08x, 0x%08x                     ; %06X  [id 0x%02X]" % (s, e, BASE + 8 * k, k))
    new += ["", dash,
            "; MessageScreen_ListPairsB -- 3 (start, end) LE32 pairs, interpreter B.",
            "; Read by: sub_F99098 when the message id is 0x1A: (0x2881) = (0x0C12),",
            ";          then `ld C,8 / mul BC,(0x7FC1)`, start = (this + 8*v), `inc 4` /",
            ";          end = (this + 8*v + 4), T_DisplayListB_Run_Stack(start, end).",
            "; COUNT 3: the abutment -- MessageScreen_ArgHandlers starts at +0x18 --",
            ";          and the 3 entries of MessageScreen_PairTableByLanguage, the other",
            ";          table indexed by the same (0x7FC1).  (checks Q2, Q4)",
            dash, "MessageScreen_ListPairsB:"]
    for k, (s, e) in enumerate(bpairs):
        new.append("\t.long 0x%08x, 0x%08x                     ; %06X  [(0x7FC1) = %d]"
                   % (s, e, 0xF99321 + 8 * k, k))
    new += ["", dash,
            "; MessageScreen_ArgHandlers -- 32 LE32 handler addresses.",
            "; Read by: sub_F9904D (0xF9904D, prom_b directory slot T_F4160C):",
            ";          `cp (XIZ+8),0x001F / jr ugt` -- COUNT 32 -- then `ldw BC,4 /",
            ";          mul BC,(XIZ+8) / add XBC,<this> / ld XBC,(XBC)` and a call with",
            ";          H = bit 7 of the second argument (XIZ+0x0A) pushed.",
            ";          31 slots are MessageScreen_ArgIgnore (one `ret`); slot 15 is",
            ";          sub_F99085, which sets (0x209A) = 1 when H is 0.  (checks Q3, Q4)",
            "; ⚠ What the argument numbers (who calls T_F4160C, with what) is not",
            ";          established here.",
            dash, "MessageScreen_ArgHandlers:"]
    for k, h in enumerate(hand):
        nm = "MessageScreen_ArgIgnore" if h == 0xF99120 else "sub_F99085"
        new.append("\t.long %-40s ; %06X  [%2d]" % (nm, 0xF99339 + 4 * k, k))
    new += ["", dash,
            "; MessageScreen_PairTableByLanguage -- 3 LE32 pointers, each to a",
            ";          64-pair table; all three are MessageScreen_ListPairs, so every",
            ";          value of (0x7FC1) draws the same lists in this ROM.",
            "; Read by: sub_F99098, `ld A,4 / mul WA,(0x7FC1) / add XWA,<this> /",
            ";          ld XWA,(XWA)` at 0xF990B7-0xF990C5.  COUNT 3: the abutment with",
            ";          the 0x0E pad at 0xF993C5 (check Q4); prom_b's message-module",
            ";          header reads (0x7FC1) as the language.",
            dash, "MessageScreen_PairTableByLanguage:"]
    for k in range(3):
        new.append("\t.long MessageScreen_ListPairs                    ; %06X  [%d]" % (0xF993B9 + 4 * k, k))
    L[i0:i1] = [u8(x) for x in new]
    # the readers' operands
    rep = {"PtrTable_F99121+0x218": "MessageScreen_ArgHandlers",
           "PtrTable_F99121+0x298": "MessageScreen_PairTableByLanguage",
           "PtrTable_F99121+0x200": "MessageScreen_ListPairsB"}
    txt = "\n".join(L)
    for a, b in rep.items():
        n0 = txt.count(a)
        assert n0 >= 1, a
        txt = txt.replace(a, b)
    L = txt.split("\n")
    # labels at the two handlers
    i = next(k for k, l in enumerate(L) if re.match(r"^\tret\s+; F99120\s", l))
    L[i:i] = ["MessageScreen_ArgIgnore:   ; entry: MessageScreen_ArgHandlers (31 slots)"]
    i = next(k for k, l in enumerate(L) if re.match(r"^\tlink XIZ,0x0000\s+; F99085\s", l))
    L[i:i] = ["sub_F99085:   ; entry: MessageScreen_ArgHandlers[15]"]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    R = open(srcmap.ROM, "rb").read()
    P, BP, H = checks(R)
    if "--apply" in sys.argv:
        apply(R, P, BP, H)
