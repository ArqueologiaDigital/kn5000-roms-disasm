#!/usr/bin/env python3
r"""ui_widgets/naka_widget_desc_dispatch.s: the MIDI-menu object tables InitializeEast registers.

QUESTION ANSWERED
    The file (ROM 0xE55BC8-0xE55E37 in v10, v9 and v7) was widget strings,
    four "padding" rows and, in v9/v7, instructions decoded from pointers.
    InitializeEast (sequencer/seq_event_playback.s) registers five tables from
    it with the RegObjTable / RegObjTabl macros (count word address or
    immediate count, table address), v10 source:

      RegObjTable 0x1600004, ClassProc,     0xe55cd4, 0xe559ea, 0x163
      RegObjTable 0x160000c, ResEventProc,  0xe55cda, 0xe55cd6, 0x1c3
      RegObjTable 0x160000d, ResMethodProc, 0xe55dac, 0xe55cdc, 0x1e3
      RegObjTabl  0x1600001, FunctionProc,  0x10,     0xe55dae, 0x103
      RegObjTabl  0x1600001, FunctionProc,  0x10,     MidiMenu_NakaProcName_Table, 0x403

    so 0xE55CD4 is the u16 count (16) of the widget records at 0xE559EA,
    0xE55CD6/0xE55CDA an empty table and its zero count, 0xE55CDC a 12-entry
    table of message-type string pointers (+ NULL) whose count is the u16 at
    0xE55DAC, and 0xE55DAE 16 routine pointers (+ NULL) paired entry for entry
    with the name strings of MidiMenu_NakaProcName_Table.  The widget records
    at 0xE559EA point back into the string block at the top of the file
    (+8 name, +12 instance-code string).

    --probe asserts, per version: the InitializeEast operand bytes name these
    addresses; the 12 message-type pointers land on the MT_* strings; each of
    the 16 routine pointers is the routine named by the string its name-table
    entry points at (v10 labels); every string parses.  --apply rewrites the
    file (image unchanged; `make gate` checks).

RUN
    python3 scripts/generators/gen_midimenu_registration_data.py --probe
    python3 scripts/generators/gen_midimenu_registration_data.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
LO, END = 0xE55BC8, 0xE55E38
COUNT16, EMPTY_T, EMPTY_N, MSG_T, MSG_N, PROC_T, NAME_T = (0xE55CD4, 0xE55CD6, 0xE55CDA, 0xE55CDC,
                                                            0xE55DAC, 0xE55DAE, 0xE55DF2)
WIDGETS = 0xE559EA
MSG_LABELS = {  # existing labels, kept
    0xE55D10: "MsgType_RevEqLoad", 0xE55D1E: "MsgType_EqLoad", 0xE55D28: "MsgType_RevLoad",
    0xE55D34: "MsgType_VstSendOk", 0xE55D44: "MsgType_VstPstOk", 0xE55D52: "MsgType_FlashLoad",
    0xE55D60: "MsgType_FlashWrite", 0xE55D6E: "MsgType_MpstWrite", 0xE55D7C: "MsgType_MpstLoad",
    0xE55D88: "MsgType_DrawKey", 0xE55D94: "MsgType_ExcSend", 0xE55DA0: "MsgType_PcgSend"}


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def syms(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    at = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t" and "_0x" not in p[2]:
            at.setdefault(int(p[0], 16), []).append(p[2])
    return at


def u16(d, a):
    return struct.unpack_from("<H", d, a - B)[0]


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def cstr(d, a):
    e = d.index(b"\0", a - B)
    return d[a - B:e].decode("latin-1")


def strings(d, a, stop):
    """aligned strings from a to stop -> [(addr, text)]"""
    out = []
    while a < stop:
        s = cstr(d, a)
        assert all(32 <= ord(c) < 127 for c in s), (hex(a), s)
        n = len(s) + 1
        if n % 2:
            assert d[a - B + n] == 0xFF, hex(a)
            n += 1
        out.append((a, s))
        a += n
    assert a == stop, (hex(a), hex(stop))
    return out


def probe_one(v):
    d = rom(v)
    at = syms(v)
    for t in (COUNT16, EMPTY_N, EMPTY_T, MSG_N, MSG_T, PROC_T, NAME_T, WIDGETS):
        pat, i, hits = t.to_bytes(3, "little"), 0, []
        while True:
            i = d.find(pat, i + 1)
            if i < 0:
                break
            if B + i >= 0xEF0000:
                hits.append(i)
        assert hits, (v, hex(t))
    assert u16(d, COUNT16) == 16 and u32(d, EMPTY_T) == 0 and u16(d, EMPTY_N) == 0
    n = u16(d, MSG_N)
    assert n == 12
    msgs = [u32(d, MSG_T + 4 * k) for k in range(n)]
    assert u32(d, MSG_T + 4 * n) == 0 and MSG_T + 4 * n + 4 == min(msgs)
    assert set(msgs) == set(MSG_LABELS), sorted(map(hex, msgs))
    procs = [u32(d, PROC_T + 4 * k) for k in range(16)]
    assert u32(d, PROC_T + 64) == 0 and PROC_T + 68 == NAME_T
    names = [u32(d, NAME_T + 4 * k) for k in range(17)]
    assert names[16] == END - 2 and d[END - 2 - B:END - B] == b"\0\xff"
    pairs = []
    for p, nm in zip(procs, names):
        s = cstr(d, nm)
        if v == "v10":
            assert s in at.get(p, []), (hex(p), s, at.get(p))
        pairs.append((p, s))
    return d, at, msgs, pairs


def probe():
    for v in ("v10", "v9", "v7"):
        d, at, msgs, pairs = probe_one(v)
        print("%s: count16=16, empty table, 12 message types, 16 routines: %s ..." % (
            v, ", ".join("%s=0x%06X" % (s, p) for p, s in pairs[:3])))
    return 0


def emit(v):
    d, at, msgs, pairs = probe_one(v)
    L = [
        "// Widget descriptor dispatch data",
        "// Extracted from kn5000_v10_program.s",
        "// Contains: NAKA dispatch widgets (AcPmemOutLGridBox, AcPcgOutGridBox, etc.),",
        "// MidiMenu_MsgType_Table, MidiMenu_NakaProcName_Table, and instance name strings.",
        "",
        "; MIDI-menu object tables that InitializeEast (sequencer/seq_event_playback.s)",
        "; registers with RegObjTable/RegObjTabl -- see each block below.  Regenerate with",
        "; scripts/generators/gen_midimenu_registration_data.py (--probe checks it).",
        "; Strings of the 16 widget records (24 bytes each, naka_dispatch_t) at 0xE559EA,",
        "; which `RegObjTable 0x1600004, ClassProc, 0xe55cd4, 0xe559ea, 0x163` registers:",
        "; record +12 points at an instance-code string (\"XXj\", \"nXXFB\", \"fjXn\", \"Att\"",
        "; or \"\") and +8 at the name after it.  The first two bytes end \"XXj\", which",
        "; starts at 0xE55BC6 in the previous file.",
        "\t.byte 0x6a, 0x00",
    ]
    for a, s in strings(d, LO + 2, COUNT16):
        L.append("\taligned_string \"%s\"" % s)
    L += ["; u16 16: number of widget records at 0xE559EA, read by that RegObjTable",
          "; (`ldw_da xwa,(0xe55cd4)`).",
          "MidiMenu_WidgetCount:",
          "\t.short 16",
          "; Empty table (one zero word) and its count 0, registered by",
          "; `RegObjTable 0x160000c, ResEventProc, 0xe55cda, 0xe55cd6, 0x1c3`.",
          "MidiMenu_ResEventTable:",
          "\t.long 0",
          "MidiMenu_ResEventCount:",
          "\t.short 0",
          "; 12 message-type string pointers + NULL, registered by",
          "; `RegObjTable 0x160000d, ResMethodProc, 0xe55dac, 0xe55cdc, 0x1e3` (count:",
          "; MidiMenu_MsgTypeCount).  The first entry, MT_PCGSEND, used to be written as",
          "; \"padding\" with this label one entry later.",
          "MidiMenu_MsgType_Table:"]
    for p in msgs:
        L.append("\t.long %s" % MSG_LABELS[p])
    L.append("\t.long 0")
    for a, s in strings(d, min(msgs), MSG_N):
        lab = MSG_LABELS[a]
        L.append("%s:%s\taligned_string \"%s\"" % (lab, "\t" if len(lab) + 1 < 16 else "", s))
    L += ["; u16 12: entries of MidiMenu_MsgType_Table, read by that RegObjTable",
          "; (`ldw_da xwa,(0xe55dac)`).",
          "MidiMenu_MsgTypeCount:",
          "\t.short 12",
          "; 16 routine pointers + NULL, registered with count 16 by",
          "; `RegObjTabl 0x1600001, FunctionProc, 0x10, 0xe55dae, 0x103`.  Entry k is the",
          "; routine named by the string MidiMenu_NakaProcName_Table entry k points at (the",
          "; next RegObjTabl, id 0x403).",
          "MidiMenu_ProcTable:"]
    for p, s in pairs:
        names = at.get(p, [])
        if s in names:
            L.append("\t.long %s" % s)
        elif names:
            L.append("\t.long %s\t; the routine v10 calls %s" % (sorted(names)[0], s))
        else:
            L.append("\t.long 0x%08x\t; %s (no label at this address in this tree)" % (p, s))
    L.append("\t.long 0")
    L += ["; 16 name-string pointers + a pointer to the empty string NakaProc_NullEntry,",
          "; registered by `RegObjTabl 0x1600001, FunctionProc, 0x10,",
          "; MidiMenu_NakaProcName_Table, 0x403`; entry k names MidiMenu_ProcTable entry k."]
    return L


def apply(v):
    path = os.path.join(ROOT, v, "maincpu/ui_widgets/naka_widget_desc_dispatch.s")
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    i = lines.index("MidiMenu_NakaProcName_Table:")
    new = emit(v) + lines[i:]
    open(path, "wb").write("\n".join(new).encode("latin-1"))
    print("%s rewritten up to MidiMenu_NakaProcName_Table" % path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.apply:
        for v in a.apply:
            apply(v)
        return 0
    return probe()


if __name__ == "__main__":
    sys.exit(main())
