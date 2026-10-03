#!/usr/bin/env python3
"""name_wsa1_ram.py -- WSA1 CPU-1 RAM variables whose meaning a findings note establishes get a name.

QUESTION THIS ANSWERS / JOB IT DOES
  prom_a and prom_b (one CPU, one RAM) address their variables by number: `ld (0x2540:16), 0`,
  `ld (9536:16), 0` (prom_b spells addresses in decimal), `m_add_rm MW16, 0x2555, r4`.  Where a
  wsa1/notes FINDINGS table establishes what an address holds -- with the routine or service that
  establishes it -- the address gets a name in wsa1/include/wsa1_ram.inc (generated here from GROUPS:
  the LCD drawing state, the inter-processor link block, prom_b's field-blink control block, the
  UI request / screen state, the block store),
  and the memory operands and the macro address arguments that spell it become the name.
  Only memory operands `(N)` / `(N:16)` / `(N:24)`, the address argument of the m_* macros
  (`MB16|MW16|MD16|MB24|MW24|MD24, N`), the last argument of the memory-to-memory macros
  (m_ld_mm16 / m_ldw_mm16 / m_ld_m16m: the other 16-bit address) and 24-bit immediates (`ld XIY,0x006007db`: at that width
  only an address) change; a 16-bit immediate equal to the number may be a value, and data
  (`.byte` / `.short`) is left alone.  Comments keep the numbers -- the WSA1 tools read
  `; F8E85F  f1 58 25 41` and the evidence headers cite `(0x2540)`.
  prom_c is another CPU with its own RAM: its sources are not touched, and it does not include
  wsa1_ram.inc.  Same bytes: `make gate-all`.

USAGE
  python3 scripts/tools/name_wsa1_ram.py [--apply]
  python3 scripts/tools/name_wsa1_ram.py --check   # any number left that a name covers? (exit 1)
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
INC = "wsa1/include/wsa1_ram.inc"
SOURCES = ["wsa1/prom_a/wsa1_prom_a.s", "wsa1/prom_b/wsa1_prom_b.s"] + \
    sorted(glob.glob(os.path.join(REPO, "wsa1/maincpu/shared/*.s")))

# Groups of (findings note, section, {address: (name, what it holds, what establishes it)}).
# A name with `+` is an operand expression over a named base (a field the note establishes only by
# its layout); it gets no .equ of its own.
GROUPS = [
    ("wsa1/notes/FINDINGS-display-controller.md", "The drawing state, as it now stands", {
        0x2530: ("LCD_X0", "box / line X0; clamped to 319", "the clamp"),
        0x2532: ("LCD_Y0", "box / line Y0; clamped to 239", "the clamp"),
        0x2534: ("LCD_X1", "box / line X1", "the clamp"),
        0x2536: ("LCD_Y1", "box / line Y1", "the clamp"),
        0x2540: ("LCD_CurrentLayer", "the layer being drawn into, 0..2", "LCD_SelectCurrentLayer"),
        0x2541: ("LCD_Layer0_SAD", "layer 0's SED1330 screen start address", "LCD_Init_SED1330 writes it"),
        0x2543: ("LCD_Layer1_SAD", "layer 1's SED1330 screen start address", "LCD_Init_SED1330 writes it"),
        0x2545: ("LCD_Layer2_SAD", "layer 2's SED1330 screen start address", "LCD_Init_SED1330 writes it"),
        0x2547: ("LCD_LineFlags", "bit 0: the line draw's X and Y are swapped", "LCD_Line_ChooseMajorAxis"),
        0x2548: ("LCD_LineSlopeX100", "line slope x 100", "LCD_Line_ComputeSlope"),
        0x254A: ("LCD_LineInterceptX100", "line intercept x 100", "LCD_Line_ComputeIntercept"),
        0x2550: ("LCD_PlotX", "X of the point being plotted", "LCD_PlotPointAt reads it"),
        0x2552: ("LCD_PlotY", "Y of the point being plotted", "LCD_PlotPointAt reads it"),
        0x2554: ("LCD_OvlayShadow", "shadow of the SED1330 OVLAY parameter", "service 0x05 masks it with 0xFC"),
        0x2555: ("LCD_CurrentLayerBase", "display-RAM base of the current layer", "LCD_SelectCurrentLayer writes it"),
        0x2557: ("LCD_BytesPerLine", "SED1330 AP, bytes per line (40); 16-bit, low byte", "the plotter multiplies Y by it"),
        0x2558: ("LCD_BytesPerLine_Hi", "AP's high byte, written on its own", "services 0x0F and 0x10"),
        0x2559: ("LCD_DispOnOffShadow", "the last DISP ON/OFF parameter", "service 0x0C"),
        0x255A: ("LCD_RunAddress", "display address of the run being drawn", "services 0x01, 0x05, 0x11"),
        0x255C: ("LCD_SavedX0", "X0 saved across a shadowed box", "services 0x0A, 0x22"),
        0x255E: ("LCD_SavedY0", "Y0 saved across a shadowed box", "services 0x0A, 0x22"),
        0x2560: ("LCD_SavedX1", "X1 saved across a shadowed box", "services 0x0A, 0x22"),
        0x2562: ("LCD_SavedY1", "Y1 saved across a shadowed box", "services 0x0A, 0x22"),
    }),
    ("wsa1/notes/FINDINGS-interprocessor-link.md", "the receiving half, channel 2, remote block read, completion selector, counters", {
        0x600780: ("Link_RxCommand", "copy of the message's first (command) byte", "INT0_LinkByte"),
        0x600788: ("Link_E2Payload", "an 0xE2 message's 10 payload bytes: long +0, long +4, word +8", "INT0_LinkByte; Link_ServiceTask reads the three fields"),
        0x60078C: ("Link_E2Payload+4", "", ""),
        0x600790: ("Link_E2Payload+8", "", ""),
        0x600792: ("Link_PendingFlags", "bit 7: an 0xE2 request waits for Link_ServiceTask", "INTTC3_LinkDmaDone sets it"),
        0x6007A1: ("Link_TxDest", "outgoing 0xE1 header: destination long", "the 0xE1 transmitter at 0xF8E26F"),
        0x6007A5: ("Link_TxCount", "outgoing 0xE1 header: count word", "the 0xE1 transmitter at 0xF8E26F"),
        0x6007B3: ("Link_RxPayload", "payload of any other command, (cmd & 0x1F)+1 bytes", "INT0_LinkByte"),
        0x6007D3: ("Link_E1Dest", "an 0xE1 message's destination long, fed to DMAD3", "INTTC3_LinkDmaDone selector 2"),
        0x6007D7: ("Link_E1Count", "an 0xE1 message's count word, fed to DMAC3", "INTTC3_LinkDmaDone selector 2"),
        0x6007D9: ("Link_TxBurstsLeft", "stepped 2 -> 1 -> 0 per transmit burst; the arming code spins on 0", "INTTC2_uDMA2Done"),
        0x6007DA: ("Link_CompletionSelector", "which message INTTC3 is finishing: 0..4", "INT0_LinkByte sets it, INTTC3_LinkDmaDone dispatches on it"),
        0x6007DB: ("Link_HandshakeTimeouts", "counts timed-out 0xE5/0xE6 handshakes (2500 ticks); nothing reads it", "the handshake at 0xF8E222"),
        0x6007DC: ("Link_StallAborts", "counts receives the stall watchdog aborted; nothing reads it", "Link_ServiceTask"),
        0x6007DF: ("Link_LastDmaCount", "the stall watchdog's previous DMAC3 sample", "Link_ServiceTask"),
        0x6007E1: ("Link_BlockDoneTimeouts", "counts Link_WaitBlockDone timeouts (500 ticks); nothing reads it", "Link_WaitBlockDone"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-field-blink.md", "The control block, 0x28C8-0x28D3", {
        0x28C0: ("Blink_TextPtr", "the template's default +7: where the text is", "the template's own bytes"),
        0x28C8: ("Blink_Layer", "LCD layer for the draw", "ld (0x2540),(0x28c8)"),
        0x28C9: ("Blink_SwiFunction", "the record's +6, the swi 7 function; 0x17 / 0x1C pick the op-07 template", "ld (XIX+0x06),(0x28c9)"),
        0x28CA: ("Blink_Op02Word0D", "op-02 record's +0x0D word", "ldw (XIX+0x0d),(0x28ca)"),
        0x28CC: ("Blink_Op07Word0D", "op-07 record's +0x0D word", "ldw (XIX+0x0d),(0x28cc)"),
        0x28CE: ("Blink_Op07Word0F", "op-07 record's +0x0F word", "ldw (XIX+0x0f),(0x28ce)"),
        0x28D0: ("Blink_BytesPerEntry", "the record's +0x0B, bytes per entry", "ld BC,(0x28d0) / extz BC / ld (XIX+0x0b),BC"),
        0x28D1: ("Blink_Phase", "the 8-phase blink counter", "inc 1,(0x28d1); and C,0x07"),
        0x28D2: ("Blink_State", "0 stopped, 2 blinking, 1 unexplained", "Blink_Tick proceeds only on 2"),
        0x28D3: ("Blink_PostToRing", "0: draw inline; non-0: post to the ring buffer", "Blink_Command, from a stack-address test"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-for-the-mame-driver.md", "Related RAM the driver may want in a comment; with FINDINGS-prom_b-song-store.md and FINDINGS-prom_a-panel-control-map.md", {
        0x0EF5: ("UI_Screen0E_SubScreen", "which sub-screen of screen 0x0E is showing", "FINDINGS-prom_b-for-the-mame-driver.md"),
        0x2070: ("UI_Request", "16-bit message code; high byte 0x80 = go to the screen id in the low byte", "the panel row handlers; song-store.md: `(0x2070)` takes a 16-bit message code"),
        0x2071: ("UI_Request_Hi", "UI_Request's high byte: 0x80 with a screen id", "panel-control-map.md: the screen-request pair"),
        0x2075: ("UI_RequestBits", "request bits, set by `or` and cleared by `and`; several owners (bit 1 = blink enable)", "song-store.md; field-blink.md"),
        0x207C: ("UI_ScreenId", "the screen id; indexes the 256-entry table at prom_b 0xF2D000", "ld L,(0x207C) / xor H,H / sla 0x02,HL"),
        0x2661: ("Value_AsciiDigits", "three ASCII digits, the output of prom_a's Value_ToAsciiDigits3", "FINDINGS-prom_b-for-the-mame-driver.md"),
        0x2662: ("Value_AsciiDigits+1", "", ""),
        0x2663: ("Value_AsciiDigits+2", "", ""),
        0x2880: ("UI_StatusCode", "a status/error byte: eleven literal values; the block store's error table feeds it", "song-store.md; f6d002-module.md"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-block-store.md", "The cursor; the heap base; with FINDINGS-prom_b-song-store.md's allocator table", {
        0x0CA4: ("BStore_BlockLimit", "what BStore_CursorAdvance range-checks a followed block number against", "BStore_CursorAdvance"),
        0x0D4A: ("BStore_ErrorCode", "the block store's error code; BStore_ErrorToStatusByte maps it to UI_StatusCode", "BStore_ErrorToStatusByte"),
        0x1008: ("BStore_DirEntry", "the directory entry BStore_AppendBytes appends to", "BStore_AppendBytes"),
        0x126E: ("BStore_CursorBlockAddr", "the cursor's block address (0x617800 + (n-1)*0x100)", "BStore_SeekBlock"),
        0x12A2: ("BStore_AllocHeapBase", "the allocator's own copy of the heap base", "BStore_LatchHeapBase"),
        0x345C: ("BStore_CursorBlock", "the cursor's 1-based block number", "the block-store cursor section"),
        0x3604: ("BStore_HeapBase", "the heap base, 0x00617800", "BStore_SeekBlock and its two inverses"),
        0x3608: ("BStore_BlockCount", "how many blocks BStore_FreeList_Init threads onto the free list", "BStore_FreeList_Init"),
        0x6034B8: ("BStore_FreeHead", "head of the free list; 0xFFFF = empty", "BStore_AllocBlock"),
        0x6034BA: ("BStore_FreeCount", "number of blocks on the free list", "BStore_FreeChain"),
    }),
]
NAMES = {a: v for _, _, g in GROUPS for a, v in g.items()}
MEM = re.compile(r'\((0x[0-9a-fA-F]+|\d+)(:16|:24)?\)')
MAC = re.compile(r'\b(MB16|MW16|MD16|MB24|MW24|MD24),(\s*)(0x[0-9a-fA-F]+|\d+)\b')
# memory-to-memory macros: the LAST argument is the other 16-bit memory address
MM = re.compile(r'^(\s*m_(?:ld_mm16|ldw_mm16|ld_m16m)\s+[^,]+,[^,]+,\s*)(0x[0-9a-fA-F]+|\d+)(\s*)$')
# an immediate is renamed when it is 24-bit (>= 0x10000: there it can only be an address), or when
# it is loaded into a 16/32-bit register (`ld xiy, 9825`, `ldw bc, 0x2661` -- then used as a
# pointer: `add bc,hl / extz xbc / ld A,(XBC)`) and is a named address >= 0x100
IMM = re.compile(r'(?<![\w(])(0x[0-9a-fA-F]{5,8})\b(?!\s*[:)])')
REGIMM = re.compile(r'^(\s*(?:ld|ldw|lda)\s+(?:x?(?:wa|bc|de|hl|ix|iy|iz|sp))\s*,\s*)(0x[0-9a-fA-F]+|\d+)(\s*)$', re.I)


def inc_text():
    out = ["; wsa1_ram.inc -- names of CPU-1 RAM variables (prom_a + prom_b share the CPU and its RAM).",
           "; Generated by scripts/tools/name_wsa1_ram.py from its GROUPS table; edit there.",
           "; Each block's rows are established in the findings note its header names; the last",
           "; column of a row names what establishes it.  Not included by prom_c, another CPU."]
    col = (len(".equ ") + max(len(n) for n, _, _ in NAMES.values()) + 1) // 8 * 8 + 8

    def tabs(text):
        return text + "\t" * ((col - len(text) + 7) // 8)

    for doc, section, g in GROUPS:
        out += ["", "; ---- %s -- \"%s\"" % (doc, section)]
        for a, (n, what, by) in sorted(g.items()):
            if "+" in n:
                continue
            out.append("\t%s0x%04x\t; %s -- %s" % (tabs(".equ %s," % n), a, what, by))
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--check", action="store_true",
                    help="list code lines that still spell a named address as a number; exit 1 if any")
    a = ap.parse_args()
    if a.check:
        left = 0
        for f in SOURCES:
            p = f if os.path.isabs(f) else os.path.join(REPO, f)
            for k, l in enumerate(open(p, "rb").read().decode("latin-1").split("\n")):
                code = l.split(";")[0]
                if not code.strip() or code.strip().startswith("."):
                    continue
                for m in re.finditer(r'(0x[0-9a-fA-F]+|\b\d+\b)', code):
                    if int(m.group(1), 0) in NAMES:
                        left += 1
                        print("%s:%d: %s" % (os.path.relpath(p, REPO), k + 1, code.strip()))
        print("%d numeric spellings of named addresses left" % left)
        return 1 if left else 0
    total = 0
    for f in SOURCES:
        p = f if os.path.isabs(f) else os.path.join(REPO, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        n = 0
        for i, l in enumerate(L):
            code, sep, cmt = l.partition(";")
            s = code.strip()
            if not s or s.startswith(".") or re.match(r'^[\w.$]+:\s*$', s):
                continue

            def mem(m):
                v = int(m.group(1), 0)
                return "(%s%s)" % (NAMES[v][0], m.group(2) or "") if v in NAMES else m.group(0)

            def mac(m):
                v = int(m.group(3), 0)
                return "%s,%s%s" % (m.group(1), m.group(2), NAMES[v][0]) if v in NAMES else m.group(0)

            def imm(m):
                v = int(m.group(1), 0)
                return NAMES[v][0] if v in NAMES and v >= 0x10000 else m.group(0)

            def mm(m):
                v = int(m.group(2), 0)
                return m.group(1) + NAMES[v][0] + m.group(3) if v in NAMES else m.group(0)

            def regimm(m):
                v = int(m.group(2), 0)
                return m.group(1) + NAMES[v][0] + m.group(3) if v in NAMES and v >= 0x100 else m.group(0)

            stage = MAC.sub(mac, MEM.sub(mem, code))
            stage2 = IMM.sub(imm, stage)
            new = REGIMM.sub(regimm, MM.sub(mm, stage2))
            if new != code:
                g = MM.match(stage2)
                n += 1 if g and int(g.group(2), 0) in NAMES else 0
                g = REGIMM.match(MM.sub(mm, stage2))
                n += 1 if g and int(g.group(2), 0) in NAMES and int(g.group(2), 0) >= 0x100 else 0
                n += len([1 for x in MEM.finditer(code) if int(x.group(1), 0) in NAMES]) + \
                    len([1 for x in MAC.finditer(code) if int(x.group(3), 0) in NAMES]) + \
                    len([1 for x in IMM.finditer(MAC.sub(mac, MEM.sub(mem, code))) if int(x.group(1), 0) in NAMES])
                L[i] = new + sep + cmt
        if n and a.apply:
            if os.path.basename(p) in ("wsa1_prom_a.s", "wsa1_prom_b.s") and \
                    not any('"include/wsa1_ram.inc"' in x for x in L):
                k = next(j for j, x in enumerate(L) if '.include "include/tlcs900_mem_ops.inc"' in x)
                L.insert(k + 1, '\t.include "include/wsa1_ram.inc"')
            open(p, "wb").write("\n".join(L).encode("latin-1"))
        print("%-45s %4d operands" % (os.path.relpath(p, REPO), n))
        total += n
    print("%d operands%s" % (total, "" if a.apply else " (dry run)"))
    if a.apply:
        open(os.path.join(REPO, INC), "w").write(inc_text())
    return 0


if __name__ == "__main__":
    sys.exit(main())
