#!/usr/bin/env python3
r"""PtrTable_FAD28A is the ROM DEFAULT record for each parameter number's RAM record.

QUESTION THIS ANSWERS
    The table's header ended "Unknown: what lives at 0xF3Fxxx in prom_b".
    Three facts settle it, each checked against the ROMs:

    D1  entry[n] = ParamNumber_RecordPtrs[n] + 0xF37DDE for all 64 n -- the
        two tables move in lockstep, including the +0x80 jump after part 7 and
        the +0x20 second halves (entry[0x20+i] = entry[i] + 0x20);
    D2  the prom_b record at entry[n] is `[op][len][payload]` (the 0xF3F400
        module's framing) with op == n and len == 0x1E, for all 64 -- each
        record names its own parameter number;
    D3  both readers copy a record's payload INTO the RAM record the same
        number selects: sub_FAAE2A copies `len` bytes from +2 (first the
        0x00-0x1F halves, then, via +0x80, the 0x20-0x3F halves);
        sub_FAA967 copies payload bytes 0x0D..0x15 of the 32 first halves
        and calls sub_FAACC0 after each.

    So prom_b 0xF3F480-0xF3FCBF holds the factory defaults of the 32 part
    records (two 30-byte halves each), and this table is how the message
    module finds them.

RUN
    python3 notes/proma-2026-09-25/gen_default_records.py          # checks
    python3 notes/proma-2026-09-25/gen_default_records.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE


def w(r, a, n):
    return [int.from_bytes(r[a - B + 4 * k:a - B + 4 * k + 4], "little") for k in range(n)]


def at(r, a, h):
    return r[a - B:a - B + len(bytes.fromhex(h))] == bytes.fromhex(h)


def checks(r):
    rb = open(os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    d, p = w(r, 0xFAD28A, 64), w(r, 0xFACDEA, 64)
    assert all(d[k] - p[k] == 0xF37DDE for k in range(64))
    assert all(d[0x20 + i] == d[i] + 0x20 for i in range(32))
    print("D1 ok: entry[n] = ParamNumber_RecordPtrs[n] + 0xF37DDE for all 64")
    assert all(rb[x - 0xF00000] == k and rb[x - 0xF00000 + 1] == 0x1E for k, x in enumerate(d))
    print("D2 ok: the prom_b record at entry[n] is op n, len 0x1E, for all 64")
    # sub_FAAE2A: two passes, +0 and +0x80, each copying `len` bytes from +2
    for a, h in ((0xFAAE3C, "1e6b1a"), (0xFAAE46, "e9c88ad2fa00"), (0xFAAE4E, "e98c"),
                 (0xFAAE52, "e961"), (0xFAAE57, "e8a0e862"), (0xFAAE63, "8121c9f6"),
                 (0xFAAE82, "b140"), (0xFAAEA7, "e9c80ad3fa00")):
        assert at(r, a, h), hex(a)
    # sub_FAA967: bytes 0x0D..0x15 from +2
    for a, h in ((0xFAA99F, "1e081f"), (0xFAA9A8, "e9c88ad2fa00"), (0xFAA9B0, "e962"),
                 (0xFAA9B5, "260d"), (0xFAA9CE, "b141"), (0xFAA9DD, "1ee002"), (0xFAA9E4, "cecf15")):
        assert at(r, a, h), hex(a)
    assert at(r, 0xFAC8B5, "e9c8eacdfa00")        # sub_FAC8AA reads ParamNumber_RecordPtrs
    print("D3 ok: sub_FAAE2A and sub_FAA967 copy ROM payload into the RAM record of the same number")


def apply():
    m = srcmap.load()
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    old = [";          nothing here reads through the pointer."]
    i = next(k for k, l in enumerate(L) if l.startswith("; Unknown:  what lives at 0xF3Fxxx in prom_b."))
    assert L[i + 1] == ";          nothing here reads through the pointer." or \
        L[i + 1].startswith(";          nothing here reads")
    L[i:i + 2] = [u8(x) for x in [
        "; WHAT THE ENTRIES ARE -- established 2026-09-25 (lane proma), checks D1-D3 of",
        ";          notes/proma-2026-09-25/gen_default_records.py: entry[n] is the ROM",
        ";          DEFAULT of the RAM record ParamNumber_RecordPtrs[n].  The two tables",
        ";          move in lockstep, entry[n] = ParamNumber_RecordPtrs[n] + 0xF37DDE for",
        ";          all 64 (the +0x80 jump after part 7 and the +0x20 second halves",
        ";          included); the prom_b record at entry[n] is `[op][len][payload]`",
        ";          (prom_b's 0xF3F400 module framing) with op == n and len == 0x1E;",
        ";          and both readers copy payload bytes into the RAM record of the same",
        ";          number -- sub_FAAE2A all `len` bytes from +2 (numbers 0x00-0x1F,",
        ";          then 0x20-0x3F through +0x80), sub_FAA967 bytes 0x0D..0x15 of the",
        ";          32 first halves.  So prom_b 0xF3F480-0xF3FCBF is the part records'",
        ";          factory defaults.",
        "; ★ CORRECTED: the two lines this replaces said what lives at 0xF3Fxxx was",
        ";          open and that nothing here reads through the pointer; both readers",
        ";          above do.",
    ]]
    j = next(k for k in range(i - 30, i) if L[k].startswith("; PtrTable_FAD28A -- "))
    L[j] = "; ParamNumber_DefaultRecordPtrs -- 64 LE32 addresses inside prom_b, stepping by 0x40"
    L[j + 1:j + 1] = [";          (was PtrTable_FAD28A): the default record of each parameter number."]
    txt = "\n".join(L)
    txt, k = re.subn(r"(?<![\w.$])PtrTable_FAD28A(?![\w$])", "ParamNumber_DefaultRecordPtrs", txt)
    assert k >= 4, k
    open(srcmap.SRC, "wb").write(txt.encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    checks(open(srcmap.ROM, "rb").read())
    if "--apply" in sys.argv:
        apply()
