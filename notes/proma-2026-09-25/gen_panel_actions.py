#!/usr/bin/env python3
r"""Panel action handlers: labels, a symbolic action-list pool, and what the 0x7F12 assignment bytes are.

QUESTION THIS ANSWERS
    1. PanelGroupActionListPool (0xF8B812-0xF8BBB3) held its handler pointers
       as raw `.byte` groups.  Which routines are they?  This script labels the
       15 distinct targets (a semantic name where the handler is understood,
       the house `sub_<ADDR>` otherwise) and re-types every record as
       `.byte group, mask` + `.long <handler>`, so the gate checks each target.
    2. The assignable panel controllers read a byte from RAM 0x7F12 + slot
       (PanelGroupToRam7F12Slot) and turn it into a parameter number.  What is
       that byte?  Answer, by check A1: a MIDI CONTROLLER NUMBER -- the
       firmware's own byte -> number map (twice: sub_F8AAAC and the inline
       chain in the handler at 0xF8AFD0) is identical, value for value, to
       the MIDI-in map from controller to parameter number that the
       MidiIn_CCxx_ParamTable data defines; 0x81, which is not a controller
       number, maps to 0xB4, the number of MidiIn_ChannelPressure_ParamTable.

CHECKS (against wsa1/original_ROMs)
    A1  parse `cp A,v / jr nz / ld A,n` (sub_F8AAAC) and `cp A,v / jr nz /
        ld (XIX-2),n` (0xF8AFFE..) into maps; both equal; each (v, n) with
        v < 0x80 has the MIDI-in table for controller v holding n; 0x81 -> the
        channel-pressure table's number
    A2  sub_F8AAAC's two callers pass XIX = 0x7F27 / 0x7F28 (0x7F12 + 0x15/0x16)
    A3  every pool record's handler is one of the 15 labelled targets, each
        target is an instruction start in the source with no label yet

    A4  sub_F8B298 (PanelAction_AssignableSwitch's arm for assignment 0x40)
        writes the event word 0x00B5 -- parameter number 0xB5, MIDI-in's CC40
        Hold -- and value 0x7F / 0x00: a switch assigned controller 0x40 sends
        Hold on/off, which is what reading the byte as a CC number predicts

RUN
    python3 notes/proma-2026-09-25/gen_panel_actions.py            # checks
    python3 notes/proma-2026-09-25/gen_panel_actions.py --apply    # ran once
    python3 notes/proma-2026-09-25/gen_panel_actions.py --headers  # ran once, after --apply
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
POOL = (0xF8B812, 0xF8BBB4)
NAMES = {
    0xF8AA24: "sub_F8AA24", 0xF8AA57: "sub_F8AA57",
    0xF8AB08: "PanelAction_OrdinalToEventValue_A", 0xF8AB42: "PanelAction_OrdinalToEventValue_B",
    0xF8AB70: "sub_F8AB70", 0xF8ABFD: "sub_F8ABFD",
    0xF8ACE8: "PanelAction_SoundSelectOrKeypad_V1", 0xF8ADDE: "PanelAction_Keypad_V2",
    0xF8AE68: "sub_F8AE68", 0xF8AEDB: "sub_F8AEDB", 0xF8AF4E: "sub_F8AF4E", 0xF8AF81: "sub_F8AF81",
    0xF8AFB4: "sub_F8AFB4", 0xF8AFD0: "PanelAction_AssignableController",
    0xF8B08B: "PanelAction_AssignableSwitch",
}
MIDIIN = {0x01: 0xFA85E8, 0x02: 0xFA8888, 0x04: 0xFA88E8, 0x0B: 0xFA86A8, 0x10: 0xFA8948,
          0x11: 0xFA89A8, 0x12: 0xFA8A08, 0x13: 0xFA8A68, 0x40: 0xFA84C8}  # CC -> its MIDI-in table
CHANPRESS = 0xFA8C28


def chain(rom, lo, hi, tail):
    """pairs (value, result) from `cp A,v` (c9 cf v | c9 d8+v) / `jr nz` (6e d) or `jrl nz`
    (7e d d) / <tail> n"""
    out = {}
    a = lo
    while a < hi:
        s = rom[a - B:a - B + 12]
        if s[0] == 0xC9 and s[1] == 0xCF:
            v, k = s[2], 3
        elif s[0] == 0xC9 and 0xD8 <= s[1] <= 0xDF:
            v, k = s[1] - 0xD8, 2
        else:
            a += 1
            continue
        j = k + 2 if s[k] == 0x6E else k + 3 if s[k] == 0x7E else None   # jr nz / jrl nz
        if j is not None and s[j:j + len(tail)] == tail:
            out[v] = s[j + len(tail)]
            a += j + len(tail) + 1
        else:
            a += 1
    return out


def checks(m):
    rom = m.rom
    m1 = chain(rom, 0xF8AAAC, 0xF8AB08, b"\x21")               # ld A,n
    m2 = chain(rom, 0xF8AFF2, 0xF8B07E, b"\xbc\xfe\x00")       # ld (XIX-2),n
    assert m1 == m2 and len(m1) == 10, (m1, m2)
    for v, n in m1.items():
        if v == 0x81:
            assert rom[CHANPRESS - B] == n == 0xB4
        else:
            t = MIDIIN[v]
            assert all(rom[t - B + 3 * p] == n for p in range(32)), hex(v)
    print("A1 ok: assignment byte -> parameter number, 10 pairs, identical in both chains and "
          "to the MIDI-in controller tables:", " ".join("%02X->%02X" % kv for kv in sorted(m1.items())))
    for c, ix in ((0xF8AA6C, 0x7F27), (0xF8AA91, 0x7F28)):
        assert rom[c - B:c - B + 5] == b"\x44" + ix.to_bytes(4, "little"), hex(c)
    print("A2 ok: sub_F8AAAC is handed 0x7F27 / 0x7F28 = 0x7F12 + 0x15 / + 0x16")
    tg = set()
    for a in range(POOL[0], POOL[1], 6):
        r = rom[a - B:a - B + 6]
        if r[0] == 0xFF:
            assert r == b"\xff" * 6
            continue
        tg.add(int.from_bytes(r[2:], "little"))
    assert tg == set(NAMES), sorted(hex(x) for x in tg ^ set(NAMES))
    for a in NAMES:
        assert m.line_of(a) is not None, hex(a)
        assert not m.labels_at(a) or m.labels_at(a) == [NAMES[a]], hex(a)
    print("A3 ok: %d pool targets, each an unlabelled instruction start (before --apply)" % len(tg))
    assert rom[0xF8B29E - B:0xF8B2A3 - B] == bytes.fromhex("bcfe02b500")       # ld (XIX-2),0x00B5
    assert rom[0xF8B2A7 - B:0xF8B2AA - B] == bytes.fromhex("327f7f")           # ldw DE,0x7F7F
    assert rom[0xF8B2AE - B:0xF8B2B1 - B] == bytes.fromhex("32007f")           # ldw DE,0x7F00
    assert rom[0xF8B0B2 - B:0xF8B0B6 - B] == bytes.fromhex("1b98b2f8")         # jp 0xF8B298 on 0x40
    assert rom[0xFA84C8 - B] == 0xB5
    print("A4 ok: assignment 0x40 on a switch sends number 0xB5 (Hold), value 0x7F/0x00")
    return m1


def apply(m, amap):
    rom = m.rom
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    # pool records, bottom-up so line numbers stay valid
    edits = []
    for a in range(POOL[0], POOL[1], 6):
        r = rom[a - B:a - B + 6]
        if r[0] == 0xFF:
            continue
        i = m.line_of(a)
        line = L[i]
        mm = re.match(r"^\t\.byte 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x(\s+;.*)$"
                      % tuple(r), line)
        assert mm, line
        h = int.from_bytes(r[2:], "little")
        edits.append((i, ["\t.byte 0x%02x, 0x%02x                                           %s"
                          % (r[0], r[1], mm.group(1).lstrip()),
                          "\t.long %-50s ; %06X" % (NAMES[h], a + 2)]))
    for i, new in sorted(edits, reverse=True):
        L[i:i + 1] = new
    # labels at the handler entries
    for a in sorted(NAMES, reverse=True):
        i = next(k for k, l in enumerate(L) if re.search(r";\s*%06X\s" % a, l)
                 and not l.lstrip().startswith(";"))
        L[i:i] = ["%s:   ; entry: PanelGroupActionListPool" % NAMES[a]]
    # the pool header: say how the handler field is written now
    i = L.index("; Evidence: the pool runs from the lowest list head (0xF8B812) to the last")
    L[i:i] = [u8(x) for x in [
        "; ★ 2026-09-25 (lane proma): the LE32 handler of every record is written",
        ";          `.long <label>` (a `.byte group, mask` line, then the pointer), so",
        ";          the byte gate checks each target; the 15 distinct handlers carry",
        ";          labels (notes/proma-2026-09-25/gen_panel_actions.py, check A3).",
    ]]
    # sub_F8AAAC
    txt = "\n".join(L)
    txt, k = re.subn(r"(?<![\w.$])sub_F8AAAC(?![\w$])", "PanelCtrl_AssignToParamNumber", txt)
    assert k == 3, k
    L = txt.split("\n")
    i = L.index("PanelCtrl_AssignToParamNumber:")
    pl = ["0x%02X->%02X" % kv for kv in sorted(amap.items())]
    L[i:i] = [u8(x) for x in [
        "; ---------------------------------------------------------------------",
        "; PanelCtrl_AssignToParamNumber -- A = the parameter number for the controller",
        ";          assignment byte at (XIX); 0xFE when the byte is none of the ten.",
        "; Called from: sub_F8AA57 with XIX = 0x7F27 and 0x7F28, i.e. 0x7F12 + 0x15",
        ";          and + 0x16, two of the slots PanelGroupToRam7F12Slot maps groups to.",
        "; Body:    a `cp A,v / jr nz / ld A,n` chain:",
        ";          %s," % ", ".join(pl[:5]),
        ";          %s." % ", ".join(pl[5:]),
        ";          PanelAction_AssignableController (0xF8AFD0) carries the same ten",
        ";          pairs inline (check A1).",
        "; ★ The assignment byte IS A MIDI CONTROLLER NUMBER: for every v < 0x80 the",
        ";          MIDI-in table of controller v (MidiIn_CC01_ParamTable, ..._CC40_)",
        ";          holds exactly n as its parameter number, and 0x81 -> 0xB4 is",
        ";          MidiIn_ChannelPressure_ParamTable's number -- so 0x81 is how an",
        ";          assignment spells channel pressure (aftertouch).",
        "; (check A1: notes/proma-2026-09-25/gen_panel_actions.py)",
        "; ---------------------------------------------------------------------",
    ]]
    # PanelGroupToRam7F12Slot: sharpen the conclusion
    old = "; So the RAM bytes at 0x7F12 + slot hold an ASSIGNMENT per controller."
    i = L.index(old)
    L[i:i + 1] = [u8(x) for x in [
        "; So the RAM bytes at 0x7F12 + slot hold an ASSIGNMENT per controller, and",
        ";          the assignment is a MIDI controller number (0x81 = channel",
        ";          pressure): the byte -> CLASS map above is the MIDI-in",
        ";          controller -> parameter-number map (the CLASS of the panel event",
        ";          lists is byte 0, the parameter number) -- see",
        ";          PanelCtrl_AssignToParamNumber, check A1 of gen_panel_actions.py.",
    ]]
    out = "\n".join(L).encode("latin-1")
    open(srcmap.SRC, "wb").write(out)
    print("applied")


HANDLER_HDR = {
    "PanelAction_OrdinalToEventValue_A": [
        "; PanelAction_OrdinalToEventValue_A -- action handler of 10 pool records (v1",
        ";          group 0x07 masks 01..20, v2 group 0x06 masks 01..08): turn the one",
        ";          set bit into the event value PanelOrdinalToEventValue_A gives it.",
        ";          The body is described in that table's header.",
    ],
    "PanelAction_OrdinalToEventValue_B": [
        "; PanelAction_OrdinalToEventValue_B -- action handler of 8 pool records (v1",
        ";          and v2 group 0x00 masks 01..08); the body is described in",
        ";          PanelOrdinalToEventValue_B's header.",
    ],
    "PanelAction_SoundSelectOrKeypad_V1": [
        "; PanelAction_SoundSelectOrKeypad_V1 -- action handler of v1 groups 0x01 and",
        ";          0x02, mask FF: sixteen switches with two uses.",
        ";   bit 1 of (0x2075) set: the numeric-keypad path at 0xF8AD54, see",
        ";          PanelKeypad_OrdinalToKey_V1.",
        ";   otherwise: E = the set bit's index (+8 for group 2), D = 0x0F; the index",
        ";          is checked with T_SoundGroup_MaxMemberIndex_Get (or its ToneCopy",
        ";          twin, chosen by (0x2076) and (0x7F02)) and, if accepted, stored",
        ";          at (0x2169) and committed; 0xFF from the check drops the event.",
    ],
    "PanelAction_Keypad_V2": [
        "; PanelAction_Keypad_V2 -- action handler of v2 group 0x01 mask FF and group",
        ";          0x02 mask 0F: the V1 keypad path instruction for instruction, with",
        ";          PanelKeypad_OrdinalToKey_V2 (see that table's header).",
    ],
    "PanelAction_AssignableController": [
        "; PanelAction_AssignableController -- action handler of the 7-bit (mask 7F)",
        ";          groups v1 0x0B 0x0D 0x10 0x11 0x13 0x14 0x15 and v2 0x14 0x15:",
        ";          slot = PanelGroupToRam7F12Slot[group - 0x0B]; the assignment byte",
        ";          at 0x7F12 + slot is a MIDI controller number, and the chain",
        ";          0xF8AFF2-0xF8B07D rewrites the event's parameter number at",
        ";          (XIX-2) from it -- the ten pairs of PanelCtrl_AssignToParamNumber",
        ";          (check A1) -- or drops the event for any other value.  With",
        ";          (0xC4) = 2 only slots 0x15 / 0x16 get through.",
    ],
    "PanelAction_AssignableSwitch": [
        "; PanelAction_AssignableSwitch -- action handler of v1 groups 0x16 and 0x17,",
        ";          mask 01 (switches): dropped when (0xC4) = 2; otherwise the slot",
        ";          byte (PanelGroupToRam7F12Slot, slots 0x04 / 0x05) selects:",
        ";   0x40 -> sub_F8B298: event word 0x00B5, value 0x7F on / 0x00 off -- a",
        ";          Hold (controller 0x40, parameter number 0xB5) switch (check A4);",
        ";   0x88 -> sub_F8B0D2, 0x89 -> sub_F8B1C1, 0x90 -> sub_F8B2B5 (which writes",
        ";          event word 0x11A8); anything else drops the event.",
        "; ⚠ 0x88, 0x89 and 0x90 are not controller numbers; what they assign is",
        ";          not established here.",
    ],
}


def apply_headers(m):
    L = m.lines
    dash = "; ---------------------------------------------------------------------"
    for name, hdr in HANDLER_HDR.items():
        i = next(k for k, l in enumerate(L) if l.startswith(name + ":"))
        assert not L[i - 1].startswith(";"), name
        L[i:i] = [x.encode("utf-8").decode("latin-1") for x in
                  [dash] + hdr + ["; (notes/proma-2026-09-25/gen_panel_actions.py)", dash]]
    out = "\n".join(L).encode("latin-1")
    open(srcmap.SRC, "wb").write(out)
    print("headers applied")


if __name__ == "__main__":
    M = srcmap.load()
    AM = checks(M)
    if "--apply" in sys.argv:
        apply(M, AM)
    if "--headers" in sys.argv:
        apply_headers(M)
