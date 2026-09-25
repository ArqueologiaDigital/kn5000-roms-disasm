#!/usr/bin/env python3
r"""DisplayListPtrs_F99870 (0xF99870-0xF999EF) is three 32-entry BUTTON-HANDLER rows of two screens.

QUESTION THIS ANSWERS
    The old header read two readers into three 32-entry blocks and ended
    "Unknown: what (0x2740) selects, and what the third block is for."

    Both readers are screen BUTTON methods that call T_F41B0C = sub_F8BDF8
    with XIX = a base and E = (0x2740).  sub_F8BDF8 adds E * 128 to the base
    (`xor XDE,XDE / pop E / sla 7,DE / add XIX,XDE`) before indexing by the
    button code -- so (0x2740) selects a 32-entry ROW, i.e. the screen's PAGE:

      0xF99870  SysexBulkDump, page 0.  Its paint writes (0x2740) = 0 and no
                code of that screen writes anything else.
      0xF998F0  GeneralMidiMode, page 0.  Paint_GeneralMidiMode draws
                DL_GeneralMidiMidiGeneralMidiMode when (0x2740) = 0; its handler
                sub_F99DDD (in this row) sets (0x2740) = 1.
      0xF99970  GeneralMidiMode, page 1 -- the YES/NO page: with (0x2740) != 0
                the paint draws DL_GeneralMidiMidiYesNo, and three handlers IN
                THIS ROW (sub_F99E85, sub_F99ED1, sub_F99EE4) set it back to 0.

CHECKS (against wsa1/original_ROMs)
    W1  the two readers' bytes and prom_b's T_F41B0C = `jp 0xF8BDF8`
    W2  sub_F8BDF8: `cp HL,0x1F / jr ugt`, `xor XDE,XDE / pop E / sla 7,DE`,
        `add XIX,XDE`, `ld XIX,(XIX+L)`, `call (XIX)`
    W3  the six (0x2740) writes and which routine/row each lies in
    W4  Paint_GeneralMidiMode's `cp (0x2740),0 / jr nz` and the two lists
    W5  all 96 entries are instruction starts

RUN
    python3 notes/proma-2026-09-25/gen_button_rows.py          # checks
    python3 notes/proma-2026-09-25/gen_button_rows.py --apply  # ran once
"""
import bisect
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
ROWS = (0xF99870, 0xF998F0, 0xF99970)


def at(r, a, h):
    return r[a - B:a - B + len(bytes.fromhex(h))] == bytes.fromhex(h)


def w(r, a, n):
    return [int.from_bytes(r[a - B + 4 * k:a - B + 4 * k + 4], "little") for k in range(n)]


def containing(m, a):
    labs = sorted((x, n) for x, ns in m.by_addr.items() for n in ns if not n.startswith("."))
    k = bisect.bisect_right([x for x, _ in labs], a) - 1
    return labs[k][1]


def checks(m):
    r = m.rom
    assert at(r, 0xF99835, "4470 98f9 00c1 4027 251d 0c1b f4".replace(" ", ""))
    assert at(r, 0xF9984C, "44f098f900c14027251d0c1bf4")
    rb = open(os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    assert rb[0xF41B0C - 0xF00000:0xF41B10 - 0xF00000] == bytes.fromhex("1bf8bdf8")
    print("W1 ok: both BUTTON methods call T_F41B0C (sub_F8BDF8) with a base and E = (0x2740)")
    for a, h in ((0xF8BDF8, "dbcf1f006b"), (0xF8BE1D, "ead2cd05daec07"), (0xF8BE2C, "ea84"),
                 (0xF8BE2E, "e303f0ec24"), (0xF8BE33, "b4e8")):
        assert at(r, a, h), hex(a)
    print("W2 ok: sub_F8BDF8 indexes (base + E*128)[code], code <= 0x1F")
    rows = [w(r, x, 32) for x in ROWS]
    writes = {0xF99A16: 0, 0xF99D1E: 0, 0xF99DE8: 1, 0xF99EBB: 0, 0xF99ED6: 0, 0xF99EE9: 0}
    for a, v in writes.items():
        assert at(r, a, "f1402700%02x" % v), hex(a)
    assert containing(m, 0xF99A16) == "Paint_SysexBulkDump"
    # every `ld (0x2740),...` (f1 40 27 00 / f1 40 27 4x) in the SysexBulkDump
    # screen's code 0xF99A04-0xF99D0B is the one at 0xF99A16
    sites = [B + i for i in range(0xF99A04 - B, 0xF99D0C - B)
             if r[i:i + 3] == b"\xf1\x40\x27" and (r[i + 3] == 0 or 0x40 <= r[i + 3] <= 0x47)]
    assert sites == [0xF99A16], [hex(x) for x in sites]
    assert containing(m, 0xF99D1E) == "Paint_GeneralMidiMode"
    assert containing(m, 0xF99DE8) == "sub_F99DDD" and 0xF99DDD in rows[1]
    for a, s in ((0xF99EBB, 0xF99E85), (0xF99ED6, 0xF99ED1), (0xF99EE9, 0xF99EE4)):
        assert containing(m, a) == "sub_%06X" % s and s in rows[2], hex(a)
    print("W3 ok: page 0 -> 1 in GeneralMidi's page-0 row, 1 -> 0 in its page-1 row; "
          "SysexBulkDump only ever writes 0")
    assert at(r, 0xF99D42, "c14027 3f00".replace(" ", "")) and r[0xF99D47 - B] == 0x6E
    assert at(r, 0xF99D5D, "45e2d9f000") and at(r, 0xF99D76, "45a2daf000")
    print("W4 ok: page 0 draws DL_GeneralMidiMidiGeneralMidiMode, page 1 DL_GeneralMidiMidiYesNo")
    for x in set(rows[0] + rows[1] + rows[2]):
        assert m.line_of(x) is not None, hex(x)
    print("W5 ok: 96 entries, %d distinct handlers, all instruction starts"
          % len(set(rows[0] + rows[1] + rows[2])))


def apply(m):
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    dash = "; ---------------------------------------------------------------------"
    old_t = "; DisplayListPtrs_F99870 -- 96 LE32 pointers = THREE 32-entry tables end to end"
    i = L.index(old_t)
    L[i] = "; ScreenButtonRow_SysexBulkDump -- 96 LE32 handler pointers = THREE 32-entry ROWS"
    L[i + 1:i + 1] = [";          end to end; this was DisplayListPtrs_F99870 (they are routines,",
                      ";          not display lists: every entry is an instruction start, check W5)."]
    old_u = "; Unknown:  what (0x2740) selects, and what the third block is for."
    j = L.index(old_u, i)
    L[j:j + 1] = [u8(x) for x in [
        "; ★ CORRECTED 2026-09-25 (lane proma).  This line said \"Unknown: what",
        ";          (0x2740) selects, and what the third block is for.\"  sub_F8BDF8",
        ";          adds E * 128 to the base before indexing by the button code",
        ";          (`xor XDE,XDE / pop E / sla 7,DE / add XIX,XDE`), so (0x2740) picks",
        ";          a ROW -- the screen's PAGE -- and each reader's base is its page 0:",
        ";            0xF99870  SysexBulkDump page 0 (its paint writes (0x2740) = 0 and",
        ";                      that screen writes nothing else);",
        ";            0xF998F0  GeneralMidiMode page 0 -- ScreenButtonRow_GeneralMidi_Page0;",
        ";            0xF99970  GeneralMidiMode page 1, the YES/NO page --",
        ";                      ScreenButtonRow_GeneralMidi_YesNo.",
        ";          (notes/proma-2026-09-25/gen_button_rows.py, checks W1-W5)",
    ]]
    txt = "\n".join(L)
    assert txt.count("DisplayListPtrs_F99870+0x80") == 1
    txt = txt.replace("DisplayListPtrs_F99870+0x80", "ScreenButtonRow_GeneralMidi_Page0")
    txt, k = re.subn(r"(?<![\w.$])DisplayListPtrs_F99870(?![\w$])", "ScreenButtonRow_SysexBulkDump", txt)
    assert k >= 2, k
    L = txt.split("\n")
    heads = {
        0xF998F0: ["; ScreenButtonRow_GeneralMidi_Page0 -- 32 handlers, GeneralMidiMode's main",
                   ";          page: ScreenButton_GeneralMidiMode_Entry's base, row (0x2740) = 0,",
                   ";          drawn by Paint_GeneralMidiMode as DL_GeneralMidiMidiGeneralMidiMode.",
                   ";          Its sub_F99DDD sets (0x2740) = 1 at 0xF99DE8 (check W3).",
                   ";          Also row 1 of the SysexBulkDump base, which that screen never",
                   ";          selects (its only (0x2740) write is 0)."],
        0xF99970: ["; ScreenButtonRow_GeneralMidi_YesNo -- 32 handlers, GeneralMidiMode's YES/NO",
                   ";          page: row (0x2740) = 1 of ScreenButton_GeneralMidiMode_Entry, drawn",
                   ";          as DL_GeneralMidiMidiYesNo; sub_F99E85, sub_F99ED1 and sub_F99EE4",
                   ";          in this row set (0x2740) back to 0 (check W3)."],
        }
    for a, hdr in sorted(heads.items(), reverse=True):
        i = next(k for k, l in enumerate(L) if re.search(r";\s*%06X\s" % a, l) and l.startswith("\t.long"))
        name = hdr[0].split()[1]
        L[i:i] = [dash] + hdr + ["; (notes/proma-2026-09-25/gen_button_rows.py)", dash, name + ":"]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    M = srcmap.load()
    checks(M)
    if "--apply" in sys.argv:
        apply(M)
