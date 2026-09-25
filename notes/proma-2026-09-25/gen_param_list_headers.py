#!/usr/bin/env python3
r"""The message module's 0x2030 -> 0x2C00 translator, its parameter-number dispatch, and the eleven controllers.

QUESTION THIS ANSWERS
    Dispatch_By_60F080's header said the byte it is indexed by is "not traced
    to a source".  It is: the loop that reads it copies byte 0 of each record
    of the RAM 0x2030 list -- the PARAMETER NUMBER -- into (0x60F080) first.
    This script asserts that chain, and for the eleven controller numbers
    0xB1-0xB5 / 0xB8-0xBD that both this dispatcher and
    MidiIn_ControlRecordHandlers serve it asserts that the two load the SAME
    32-bit part-mask cell per number, and that the MIDI-in tables pin each
    number to its controller.  With --apply it names the routines and writes
    the headers.

CHECKS (all against wsa1/original_ROMs)
    M1  sub_FAB164 copies record bytes 0/1/2/3 of 0x2030+cursor into
        (0x60F080), (0x60F088)+(0x60F081), (0x60F089), (0x60F08A)
    M2  sub_FAB81F: `ld A,(XBC+0x2030) / cp A,0xFF`, `calr 0xFAB164`,
        `ld C,4 / mul BC,(0x60F080)`, `add XBC,0xFAC8EA`, `jp (XBC)`
    M3  Dispatch_By_60F080[n] for the eleven numbers: each handler tests bit 5
        of (0x7F36), loads one 0x60F2xx cell and calls 0xFABE2B (0xFABE6F for
        0xB1)
    M4  MidiIn_ControlRecordHandlers[n - 0xB2] loads the same cell for every n
        in 0xB2..0xBD it serves
    M5  the MIDI-in table named for each controller holds that number in all
        32 records (pitch bend and channel pressure in their 2-byte tables)
    M6  sub_FABE2B / sub_FABE6F: `and XBC,1`, `ld (0x60F081),H`, value and
        mask copied, `cp H,0x1F / jr ule`
    M7  sub_FAB20B tests (0x60F083), compares (0x60F000) with 0x1FC, calls
        T_Queue2C00_DrainPassAB, then 0xFAC846, which stores (0x60F080..83)
        at 0x2C00+cursor and 0xFF after them
    M8  0xFABE9D is `call 0xFAA4FC` = Queue2C00_PublishStaged

RUN
    python3 notes/proma-2026-09-25/gen_param_list_headers.py          # checks
    python3 notes/proma-2026-09-25/gen_param_list_headers.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
DISPATCH = 0xFAC8EA
CTRLREC = 0xFABF4A
CTRL = [  # number, controller name (as the MidiIn_/MidiOut_ labels spell it), MIDI-in table
    (0xB1, "PitchBend", 0xFA8BE8, 2), (0xB2, "CC01_Modulation", 0xFA85E8, 3),
    (0xB3, "CC0B_Expression", 0xFA86A8, 3), (0xB4, "ChannelPressure", 0xFA8C28, 2),
    (0xB5, "CC40_Hold", 0xFA84C8, 3), (0xB8, "CC10_RTCreatX", 0xFA8948, 3),
    (0xB9, "CC11_RTCreatY", 0xFA89A8, 3), (0xBA, "CC12_RTCtrlX", 0xFA8A08, 3),
    (0xBB, "CC13_RTCtrlY", 0xFA8A68, 3), (0xBC, "CC02_Modulation2", 0xFA8888, 3),
    (0xBD, "CC04_CtrlPedal", 0xFA88E8, 3),
]


def rom():
    return open(srcmap.ROM, "rb").read()


def at(r, a, hexs):
    return r[a - B:a - B + len(bytes.fromhex(hexs))] == bytes.fromhex(hexs)


def l32(r, a):
    return int.from_bytes(r[a - B:a - B + 4], "little")


def checks():
    r = rom()
    for a, h in ((0xFAB170, "c3e5302026"), (0xFAB175, "f280f06046"), (0xFAB18C, "c3e5302026"),
                 (0xFAB191, "f288f06046"), (0xFAB196, "f281f06046"), (0xFAB1A5, "c3ed302023"),
                 (0xFAB1AA, "f289f06043"), (0xFAB1BD, "c3e9302023"), (0xFAB1C2, "f28af06043")):
        assert at(r, a, h), hex(a)
    print("M1 ok: List2030_LoadRecord copies record bytes 0-3 into 0x60F080/88+81/89/8A")
    for a, h in ((0xFAB83A, "c3e5302021"), (0xFAB83F, "c9cfff"), (0xFAB847, "2304"),
                 (0xFAB849, "c280f06043"), (0xFAB850, "e9c8eac8fa00"), (0xFAB85E, "b1d8")):
        assert at(r, a, h), hex(a)
    assert r[0xFAB844 - B] == 0x1E and 0xFAB847 + int.from_bytes(r[0xFAB845 - B:0xFAB847 - B], "little",
                                                                  signed=True) == 0xFAB164
    print("M2 ok: sub_FAB81F loads a record, then calls Dispatch_By_60F080[(0x60F080)]")
    cells = {}
    for n, name, _, _ in CTRL:
        h = l32(r, DISPATCH + 4 * n)
        assert at(r, h, "c1367f23cbcc20"), (hex(n), hex(h))          # ld C,(0x7F36) / and C,0x20
        assert r[h - B + 7] == 0x6E                                   # jr nz
        assert r[h - B + 9] == 0xE2 and r[h - B + 11:h - B + 14] == b"\xf2\x60\x21", hex(h)
        cell = 0x600000 | (0xF2 << 8) | r[h - B + 10]
        c = h + 15                                                    # push XBC then calr
        assert r[c - B] == 0x1E, hex(h)
        tgt = c + 3 + int.from_bytes(r[c + 1 - B:c + 3 - B], "little", signed=True)
        assert tgt == (0xFABE6F if n == 0xB1 else 0xFABE2B), (hex(n), hex(tgt))
        cells[n] = (h, cell)
    print("M3 ok: the eleven entries test bit 5 of (0x7F36), load one 0x60F2xx cell and fan out")
    for n in range(0xB2, 0xBE):
        t = l32(r, CTRLREC + 4 * (n - 0xB2))
        if n in cells:
            assert r[t - B] == 0xE2 and r[t - B + 4] == 0x24, hex(t)
            assert 0x600000 | (0xF2 << 8) | r[t - B + 1] == cells[n][1], hex(n)
    print("M4 ok: MidiIn_ControlRecordHandlers loads the same cell per number")
    for n, name, tab, stride in CTRL:
        assert all(r[tab - B + stride * p] == n and r[tab - B + stride * p + 1] == p for p in range(32)), name
    print("M5 ok: each controller's MIDI-in table holds its number, class = part, in all 32 records")
    for a in (0xFABE2B, 0xFABE6F):
        body = r[a - B:a - B + 0x44]
        for h in ("e9cc01000000", "f281f06046", "c289f06023", "f282f06043", "c28af06021",
                  "f283f06041", "cecf1f"):
            assert bytes.fromhex(h) in body, (hex(a), h)
    print("M6 ok: both fan-out loops walk 32 bits and stage [number][bit][value][mask]")
    for a, h in ((0xFAB20B, "c283f0603f00"), (0xFAB213, "d200f0603ffc01"), (0xFAB220, "1d1800f4"),
                 (0xFAB22F, "1e1416"), (0xFAC857, "f3e5002c41"), (0xFAC89A, "f3ed002c00ff")):
        assert at(r, a, h), hex(a)
    print("M7 ok: sub_FAB20B / sub_FAC846 are a byte-wise PublishStagedIfPending")
    assert at(r, 0xFABE9D, "1dfca4fa")
    print("M8 ok: 0xFABE9D calls Queue2C00_PublishStaged (0xFAA4FC)")
    return r, cells


RENAME = [
    ("sub_FAB81F", "List2030_TranslateToQueue2C00"), ("sub_FAB164", "List2030_LoadRecord"),
    ("sub_FAB20B", "Queue2C00_AppendStagedIfPending"), ("sub_FAC846", "Queue2C00_AppendStaged"),
    ("sub_FABE2B", "Queue2C00_FanOutToPartMask"), ("sub_FABE6F", "Queue2C00_FanOutToPartMask_Publish"),
    ("sub_FABD3B", "ParamMsg_B1_PitchBend"), ("sub_FABD4F", "ParamMsg_B2_CC01_Modulation"),
    ("sub_FABE0D", "ParamMsg_B3_CC0B_Expression"), ("sub_FABD77", "ParamMsg_B4_ChannelPressure"),
    ("sub_FABD9F", "ParamMsg_B5_CC40_Hold"), ("sub_FABDBD", "ParamMsg_B8_CC10_RTCreatX"),
    ("sub_FABDD1", "ParamMsg_B9_CC11_RTCreatY"), ("sub_FABDE5", "ParamMsg_BA_CC12_RTCtrlX"),
    ("sub_FABDF9", "ParamMsg_BB_CC13_RTCtrlY"), ("sub_FABD63", "ParamMsg_BC_CC02_Modulation2"),
    ("sub_FABD8B", "ParamMsg_BD_CC04_CtrlPedal"),
    ("sub_FABF7A", "MidiIn_CtrlRec_B2_CC01_Modulation"), ("sub_FABFB9", "MidiIn_CtrlRec_B3_CC0B_Expression"),
    ("sub_FABFA4", "MidiIn_CtrlRec_B4_ChannelPressure"), ("sub_FABFB2", "MidiIn_CtrlRec_B5_CC40_Hold"),
    ("sub_FABF88", "MidiIn_CtrlRec_B8_CC10_RTCreatX"), ("sub_FABF8F", "MidiIn_CtrlRec_B9_CC11_RTCreatY"),
    ("sub_FABF96", "MidiIn_CtrlRec_BA_CC12_RTCtrlX"), ("sub_FABF9D", "MidiIn_CtrlRec_BB_CC13_RTCtrlY"),
    ("sub_FABF81", "MidiIn_CtrlRec_BC_CC02_Modulation2"), ("sub_FABFAB", "MidiIn_CtrlRec_BD_CC04_CtrlPedal"),
]
DASH = "; ---------------------------------------------------------------------"
SRC = "(checks M1-M8: notes/proma-2026-09-25/gen_param_list_headers.py)"


def headers(r, cells, src_text):
    n20b = len(re.findall(r'\n\tcalr sub_FAB20B\b', src_text))
    rows = []
    for n, name, _, _ in CTRL:
        rows.append(";   0x%02X  ParamMsg_%02X_%-17s cell 0x%06X" % (n, n, name, cells[n][1]))
    single = []
    for n in range(0x40, 0xB1):
        t = l32(r, DISPATCH + 4 * n)
        if t != 0xFAC845:
            single.append("0x%02X" % n)
    assert 256 - 64 - len(single) - len(CTRL) == sum(
        1 for n in range(256) if l32(r, DISPATCH + 4 * n) == 0xFAC845) == 168
    H = {
        "List2030_TranslateToQueue2C00": [
            "; List2030_TranslateToQueue2C00 -- turn each record of the 0xFF-terminated",
            ";          4-byte list at RAM 0x2030 into records of the queue at RAM 0x2C00,",
            ";          dispatching on the record's parameter NUMBER.",
            "; Called from: sub_FAB7E6 (`calr` at 0xFAB7FE), which first checks (0x2030)",
            ";          is not 0xFF and sets (0x60F018) = ParamNumber_RecordPtrs.",
            "; Body:    (0x60F08C) = 0 is the list cursor.  Per record: stop on 0xFF;",
            ";          List2030_LoadRecord; `ld C,4 / mul BC,(0x60F080)` and call",
            ";          Dispatch_By_60F080[number] with 0xFAB860 pushed as its return.",
            ";          Whenever the queue cursor (0x60F000) has reached 0x1FC the queue",
            ";          is drained (T_Queue2C00_DrainPassAB) and (0x60F002) zeroed.  At",
            ";          the end bit 4 of (0x60F021) is cleared, 0xFF is written at",
            ";          0x2C00 + (0x60F000) and (0x60F01E) = 0x7F.",
            "; " + SRC,
        ],
        "List2030_LoadRecord": [
            "; List2030_LoadRecord -- copy the list record at 0x2030 + (0x60F08C) into the",
            ";          module's working cells and step the cursor over it.",
            "; Called from: List2030_TranslateToQueue2C00 (`calr` at 0xFAB844).",
            "; Body:    byte 0, the parameter NUMBER -> (0x60F080), and",
            ";          ParamNumber_RecordPtrs[number] (via sub_FAC8AA) -> (0x60F084);",
            ";          byte 1, the CLASS -> (0x60F088) and (0x60F081); byte 2, the",
            ";          VALUE -> (0x60F089); byte 3, the MASK -> (0x60F08A); (0x60F082)",
            ";          and (0x60F083) zeroed.  (0x60F080..0x60F083) is the staged record",
            ";          Queue2C00_AppendStagedIfPending emits.",
            "; Evidence: `ld H,(XBC+0x2030) / ld (0x60F080),H` at 0xFAB170-0xFAB175 and",
            ";          three more `(XBC+0x2030)` loads at 0xFAB18C, 0xFAB1A5, 0xFAB1BD,",
            ";          each after a cursor step.  " + SRC,
        ],
        "Queue2C00_AppendStagedIfPending": [
            "; Queue2C00_AppendStagedIfPending -- this module's byte-wise copy of",
            ";          Queue2C00_PublishStagedIfPending: nothing if the staged mask",
            ";          (0x60F083) is 0; otherwise drain the 0x2C00 queue when its cursor",
            ";          (0x60F000) has reached 0x1FC, then Queue2C00_AppendStaged.",
            "; Called from: %d `calr` sites in this module, among them the fan-out" % n20b,
            ";          loop Queue2C00_FanOutToPartMask.",
            "; Evidence: `cp (0x60F083),0` at 0xFAB20B, `cp (0x60F000),0x1FC` at 0xFAB213,",
            ";          `call T_Queue2C00_DrainPassAB` at 0xFAB220.  " + SRC,
        ],
        "Queue2C00_AppendStaged": [
            "; Queue2C00_AppendStaged -- store the staged record (0x60F080), (0x60F081),",
            ";          (0x60F082), (0x60F083) as four bytes at 0x2C00 + (0x60F000),",
            ";          advance the cursor by 4, write 0xFF after them, clear (0x60F083).",
            "; Called from: Queue2C00_AppendStagedIfPending (0xFAB22F) and 0xFAB24F.",
            "; Notes:   same buffer, cursor and terminator as the word-wise tail of",
            ";          Queue2C00_PublishStagedIfPending (0xFAA4CA).  " + SRC,
        ],
        "Queue2C00_FanOutToPartMask": [
            "; Queue2C00_FanOutToPartMask -- emit the current record once per set bit of",
            ";          a 32-bit mask, with the bit's index as the record's CLASS.",
            "; Inputs:  (XIZ+8) = the mask, pushed by the caller.",
            "; Body:    for H = 0..31, low bit first: if set, (0x60F081) = H, (0x60F082)",
            ";          = the value (0x60F089), (0x60F083) = the mask (0x60F08A), then",
            ";          Queue2C00_AppendStagedIfPending.",
            "; Called from: ten of the eleven ParamMsg_ controller entries below, and the",
            ";          common tail of MidiIn_ControlRecordHandlers (0xFABFD9).",
            "; ★ The index is a PART: for these numbers every MIDI-in table puts the",
            ";          part in the class byte (check M5), so a controller record goes",
            ";          out once per part whose bit is set.  " + SRC,
        ],
        "Queue2C00_FanOutToPartMask_Publish": [
            "; Queue2C00_FanOutToPartMask_Publish -- Queue2C00_FanOutToPartMask with",
            ";          Queue2C00_PublishStaged (no zero-mask test) instead of",
            ";          Queue2C00_AppendStagedIfPending, the `call` at 0xFABE9D.",
            "; Called from: ParamMsg_B1_PitchBend (0xFABD4A) and the 0xB1 arm of",
            ";          MidiIn_ControlRecord_Dispatch (0xFABF26) -- pitch bend only.",
            "; " + SRC,
        ],
        "ParamMsg_B1_PitchBend": [
            "; ParamMsg_B1_PitchBend .. ParamMsg_B3_CC0B_Expression -- the eleven MIDI",
            ";          controller entries of Dispatch_By_60F080, 0xFABD3B-0xFABE2A.",
            "; Each:    if bit 5 of (0x7F36) is clear, push the 32-bit part mask held in",
            ";          one RAM cell and fan the record out over it",
            ";          (Queue2C00_FanOutToPartMask; the _Publish variant for 0xB1).",
            ";          ParamMsg_B3 and ParamMsg_B5 also copy the value to (0x60F191) /",
            ";          (0x60F192).",
        ] + rows + [
            "; ★ Number -> controller is pinned twice: the MIDI-in table named for the",
            ";          controller holds that number in every record (check M5), and",
            ";          MidiOut_ParamNumberTable[number] is the MidiOut_ handler of the",
            ";          same controller.  MidiIn_ControlRecordHandlers loads the SAME",
            ";          cell for each number (check M4): two readers of eleven cells.",
            "; ⚠ What bit 5 of (0x7F36) switches off is not established.",
            "; " + SRC,
        ],
    }
    return H, single


PARA_OLD = [
    "; Unknown:  what any command byte MEANS.  (0x60F080) is written by other code",
    ";          in this module -- 0xFAC39B is `ld (0x60F080),C` with C loaded from",
    ";          (XIZ+0x08) three bytes earlier -- and its values are not traced to a",
    ";          source here.",
]


def para_new(single):
    return [
        "; Index:   (0x60F080) is written by other code in this module too -- 0xFAC39B",
        ";          is `ld (0x60F080),C` with C loaded from (XIZ+0x08) three bytes",
        ";          earlier -- but for THIS reader it is traced:",
        "; ★ CORRECTED 2026-09-25 (lane proma).  This paragraph said the byte's",
        ";          values were \"not traced to a source here\" and that what a command",
        ";          byte MEANS is unknown.  The loop around the reader,",
        ";          List2030_TranslateToQueue2C00, calls List2030_LoadRecord first,",
        ";          which copies byte 0 of the current record of the RAM 0x2030 list",
        ";          into (0x60F080).  So the index is that record's PARAMETER NUMBER,",
        ";          the number space of Evt2030_ClassHandlers and",
        ";          MidiOut_ParamNumberTable.  What the populated entries serve:",
        ";   0x00-0x1F  sub_FAB894 -- part parameters (number = the part); it",
        ";              dispatches again on the record's CLASS, JumpTable_FAB8B4",
        ";   0x20-0x3F  sub_FABAFD -- the other half of each part record",
        ";              (ParamNumber_RecordPtrs, pin 3)",
        ";   %s -- one handler" % ", ".join(single),
        ";              each, not decoded here",
        ";   0xB1-0xB5, 0xB8-0xBD -- the eleven MIDI controllers, ParamMsg_B1_PitchBend",
        ";              and its block header",
        ";   the other 168 numbers: sub_FAC845, one `ret`.",
        "; " + SRC,
    ]


def apply(r, cells):
    L = open(srcmap.SRC, encoding="latin-1").read().split("\n")
    txt = "\n".join(L)
    for old, new in RENAME:
        txt, k = re.subn(r"(?<![\w.$])%s(?![\w$])" % old, new, txt)
        assert k >= 1, old
    H, single = headers(r, cells, "\n".join(L))
    L = txt.split("\n")
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    for name, hdr in H.items():
        i = next(k for k, l in enumerate(L) if re.match(r"^%s:" % name, l))
        assert L[i - 1] != DASH, name
        L[i:i] = [u8(x) for x in [DASH] + hdr + [DASH]]
    # Dispatch_By_60F080: the corrected paragraph
    i = L.index(PARA_OLD[0])
    assert L[i:i + 4] == PARA_OLD
    L[i:i + 4] = [u8(x) for x in para_new(single)]
    # JumpTable_FAB8B4: the selector is traced too
    old = ";          0x0B take the `jrl UGT,0xFAB914` two instructions earlier."
    i = L.index(old)
    j = L.index("; Unknown:  what the selector at (0x60F088) means.", i)
    L[j:j + 1] = [u8(x) for x in [
        "; Selector: (0x60F088) is byte 1, the CLASS, of the list record",
        ";          (List2030_LoadRecord), and for numbers 0x00-0x1F the class names",
        ";          the part attribute: MidiOut_ParamClassTable, indexed by the same",
        ";          class, is 0 MidiOut_ProgramChange, 3 MidiOut_CC07_Volume, 5/6/7 the",
        ";          effect depths, 8 MidiOut_CC0A_Pan, 9-11 the three RPN tunings,",
        ";          and the MIDI-in tables confirm classes 3, 5, 6, 7 and 8.",
        "; ★ 2026-09-25 (lane proma): this line said \"Unknown: what the selector at",
        ";          (0x60F088) means\".  What each entry here DOES with it is still",
        ";          not decoded.",
    ]]
    # JumpTable_FAB8B4 entry 0: give the target a label so the pointer is symbolic
    i = L.index("\t.long 0x00fab8e4                                 ; FAB8B4  [  0]")
    L[i] = "\t.long sub_FAB8E4                                 ; FAB8B4  [  0]"
    j = next(k for k in range(i, i + 20) if re.search(r";\s*FAB8E4\b", L[k]))
    L[j:j] = ["sub_FAB8E4:   ; entry: JumpTable_FAB8B4[0], class 0"]
    # MidiIn_ControlRecord_Dispatch: the record is known
    old = [
        "; Unknown:  what a record IS. Its first byte selects one of thirteen",
        ";           arms and the twelve jump-table arms are not decoded here;",
        ";           JumpTable_FABF4A's own header states the same gap",
    ]
    i = L.index(old[0])
    assert L[i:i + 3] == old
    L[i:i + 3] = [u8(x) for x in [
        "; ★ CORRECTED 2026-09-25 (lane proma).  This said \"Unknown: what a record",
        ";           IS ... the twelve jump-table arms are not decoded here\".  The",
        ";           record is the 4-byte parameter-change record the MIDI-in",
        ";           controller handlers build at RAM 0x1950 -- [number] [class]",
        ";           [value] [mask], see MidiIn_CC01_ParamTable's header -- so its",
        ";           first byte is the parameter number, and the MIDI-in tables pin",
        ";           all eleven of 0xB1-0xB5 / 0xB8-0xBD to their controllers.  Each",
        ";           arm loads its number's 32-bit part mask (the MidiIn_CtrlRec_",
        ";           labels) and the common tail fans the record out over it with",
        ";           Queue2C00_FanOutToPartMask -- the same cells, number for",
        ";           number, that the ParamMsg_ entries of Dispatch_By_60F080 use",
        ";           (check M4).  0xB6/0xB7 take the skip arm.",
        "; " + SRC,
    ]]
    # Queue2C00_PublishStaged: the negative is disproven
    old = [
        "; Called from: no directory slot and no proven call site found; it is",
        ";          reached by falling out of Queue2C00_PublishStagedIfPending's",
        ";          `ret` only if something jumps here, which nothing does.  Stated",
        ";          as a searched negative, not as a fact about the hardware.",
    ]
    i = L.index(old[0])
    assert L[i:i + 4] == old
    L[i:i + 4] = [u8(x) for x in [
        "; Called from: `call` at 0xFABE9D in Queue2C00_FanOutToPartMask_Publish.",
        ";          ★ CORRECTED 2026-09-25 (lane proma): this said \"no directory slot",
        ";          and no proven call site found ... nothing does\"; the call became",
        ";          visible when 0xFABE9D's operand was symbolised (check M8).  No",
        ";          directory slot names it.",
    ]]
    out = "\n".join(L).encode("latin-1")          # encode BEFORE opening: a failed
    open(srcmap.SRC, "wb").write(out)             # encode must not truncate the file
    print("applied")


if __name__ == "__main__":
    R, C = checks()
    if "--apply" in sys.argv:
        apply(R, C)
