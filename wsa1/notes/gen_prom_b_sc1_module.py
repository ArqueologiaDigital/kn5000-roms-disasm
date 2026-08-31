#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF5A800-0xF5B7FF -- the serial-channel-1 module.

QUESTION IT ANSWERS
    "What is the assembly text for the SC1 module, in a form the byte gate
     accepts, with every label and header attached to the right address?"
    This is the emitter whose output is pasted into prom_b/wsa1_prom_b.s.

HOW
    * code runs are transcribed by notes/llvm_roundtrip_autoforce.py, which
      proves the listing rebuilds the range byte for byte before printing it;
    * the three jump tables are emitted as `.long`, one line per entry, with the
      entry's index and target in the comment;
    * the 946-byte 0x0E tail is emitted as `.fill`;
    * labels and headers come from the tables below, keyed by ADDRESS, and the
      script asserts that every label address is an instruction boundary in the
      transcription -- except the ones listed in MIDSTREAM, which are the four
      `calr` targets in the dead tail that are NOT boundaries (see the header
      of SC1_DeadTail, and notes/FINDINGS-prom_b-sc1-link.md).

RUN
    python3 notes/gen_prom_b_sc1_module.py            # the assembly
    python3 notes/gen_prom_b_sc1_module.py --layout   # just the segment table
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")

# (kind, start, length).  The three tables were located by scanning the module
# for runs of 4-byte little-endian words in 0x00F5A800-0x00F5B44D and are each
# bounded by abutment with their own first target; see the findings note.
LAYOUT = [
    ("code",  0xF5A800, 0x467),
    ("table", 0xF5AC67, 0x2C),
    ("code",  0xF5AC93, 0x422),
    ("table", 0xF5B0B5, 0x20),
    ("code",  0xF5B0D5, 0x1C4),
    ("table", 0xF5B299, 0x10),
    ("code",  0xF5B2A9, 0x1A5),
    ("fill",  0xF5B44E, 0x3B2),
]

TABLE_NOTE = {
    0xF5AC67: ("SC1_StateTable", "0x2A80", "the state byte is used as a BYTE "
               "OFFSET, not an index (no shift), so entry n is state 4*n"),
    0xF5B0B5: ("SC1_RxOpTable", "(rx byte & 0x38) >> 1",
               "the mask and shift fix the size at 8 entries"),
    0xF5B299: ("SC1_TxOpTable", "(tx byte & 0x30) >> 2",
               "the mask and shift fix the size at 4 entries"),
}

LABELS = {
    0xF5A800: "SC1_Vtable",
    0xF5A818: "SC1_Vtable_0_Open",
    0xF5A831: "SC1_Vtable_3_Ret",
    0xF5A832: "SC1_Service",
    0xF5A836: "SC1_TxFlush",
    0xF5A83A: "SC1_Entry_F40F18_Ret",
    0xF5A83B: "SC1_Entry_F40F1C",
    0xF5A847: "SC1_Entry_F40F20",
    0xF5A84B: "SC1_Entry_F40F24",
    0xF5A84F: "SC1_Vtable_Unused_Ret",
    0xF5A850: "SC1_ConfigurePort",
    0xF5A95D: "SC1_SendWord_Polled",
    0xF5AA26: "SC1_Spin2",
    0xF5AA32: "SC1_Spin6",
    0xF5AA3E: "SC1_Spin10",
    0xF5AA4A: "SC1_Spin100",
    0xF5AA56: "SC1_Spin500",
    0xF5AA62: "SC1_WaitTicks2",
    0xF5AA79: "SC1_WaitTicks6",
    0xF5AA90: "SC1_WaitTicks51",
    0xF5AAA9: "SC1_Cmd_E0_ReadStatus",
    0xF5AAD9: "SC1_Cmd_E3_E2_E3",
    0xF5AB2A: "SC1_Cmd_EF",
    0xF5AB74: "SC1_WaitTxDrain",
    0xF5ABB4: "SC1_StartWordTx",
    0xF5AC0A: "INT6_SC1_PeerRequest",
    0xF5AC58: "SC1_Irq_Exit_1",
    0xF5AC5A: "SC1_Irq_Exit_1_Delayed",
    0xF5AC93: "INTTX1_SC1_Dispatch",
    0xF5ACA8: "SC1_Irq_Exit_3",
    0xF5ACAC: "SC1_Irq_Exit_3_Delayed",
    0xF5ACBB: "INTRX1_SC1_Dispatch",
    0xF5ACD0: "SC1_Irq_Exit_3b",
    0xF5ACD4: "SC1_Irq_Exit_3b_Delayed",
    0xF5ACE3: "SC1_State04_TxByte1",
    0xF5AD2E: "SC1_State0C",
    0xF5AD5D: "SC1_State14",
    0xF5AD92: "SC1_State08_TxFromRing",
    0xF5ADF7: "SC1_State10_TxFromRing",
    0xF5AE5C: "SC1_State18_TxDone",
    0xF5AED4: "SC1_State20_RxFirstByte",
    0xF5AF51: "SC1_State24_RxNextByte",
    0xF5AFD3: "SC1_State_Unexpected",
    0xF5AFDB: "SC1_AbortToIdle",
    0xF5AFF2: "SC1_TxFlush_Body",
    0xF5B05D: "SC1_TxFlush_Exit",
    0xF5B060: "SC1_Service_SetBit2",
    0xF5B067: "SC1_Service_ClearBit2",
    0xF5B06C: "SC1_RxDecode",
    0xF5B07D: "SC1_RxDecode_Loop",
    0xF5B0D5: "SC1_RxOp0_ThreeByte",
    0xF5B12C: "SC1_RxOp2",
    0xF5B179: "SC1_RxOp6_Run",
    0xF5B226: "SC1_RxOp3_Discard",
    0xF5B242: "SC1_RxDecode_Ret",
    0xF5B243: "SC1_TxEncode",
    0xF5B254: "SC1_TxEncode_Loop",
    0xF5B299 + 0x10: "SC1_TxOp0_TwoByte",
    0xF5B2D9: "SC1_TxOp3_Run",
    0xF5B31B: "SC1_TxEncode_Ret",
    0xF5B31C: "SC1_RxRing_Next",
    0xF5B328: "SC1_TxRing_Next",
    0xF5B334: "SC1_Queue_Next",
    0xF5B33F: "SC1_Queue_Prev",
    0xF5B34A: "SC1_Entry_F40F24_Body_Ret",
    0xF5B34B: "SC1_DeadTail",
}

# addresses that other code branches to but that are NOT instruction boundaries
# in the linear framing of the live module -- all four are in the dead tail.
MIDSTREAM = {0xF5A9B2, 0xF5AA9B, 0xF5AAA7, 0xF5AAB3, 0xF5AB21, 0xF5B07E}

HEADERS = {}   # filled in by prom_b/wsa1_prom_b.s itself; kept out of the emitter


def run(addr, ln):
    p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(addr), hex(ln)],
                       capture_output=True, text=True)
    if p.returncode != 0:
        sys.stderr.write(p.stderr)
        raise SystemExit("autoforce failed for 0x%06X" % addr)
    return p.stdout.splitlines(True), p.stderr


def main():
    data = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    if "--layout" in sys.argv:
        for kind, a, n in LAYOUT:
            print("  %-6s 0x%06X..0x%06X  %5d bytes" % (kind, a, a + n - 1, n))
        print("  total %d bytes" % sum(n for _, _, n in LAYOUT))
        return 0

    out = []
    boundaries = set()
    for kind, a, n in LAYOUT:
        if kind == "code":
            lines, err = run(a, n)
            sys.stderr.write("  0x%06X %s" % (a, err.lstrip()))
            for ln in lines:
                m = re.search(r";\s*([0-9A-F]{6})\s", ln)
                if m:
                    ad = int(m.group(1), 16)
                    boundaries.add(ad)
                    if ad in LABELS:
                        out.append("%s:\n" % LABELS[ad])
                out.append(ln)
        elif kind == "table":
            name, idx, why = TABLE_NOTE[a]
            boundaries.add(a)
            out.append("%s:\n" % name)
            for k in range(0, n, 4):
                w = int.from_bytes(data[a - 0xF00000 + k:a - 0xF00000 + k + 4], "little")
                out.append("\t.long\t0x%08X\t; %06X  [%2d] state/op 0x%02X -> 0x%06X\n"
                           % (w, a + k, k // 4, k, w))
        else:
            boundaries.add(a)
            out.append("\t.fill\t%d, 1, 0x0E\t; %06X-%06X  ret padding to the "
                       "4 KiB boundary\n" % (n, a, a + n - 1))

    missing = sorted(x for x in LABELS if x not in boundaries)
    if missing:
        raise SystemExit("label addresses that are not instruction boundaries: %s"
                         % ["0x%06X" % x for x in missing])
    sys.stdout.write("".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
