#!/usr/bin/env python3
"""name_wsa1_ram.py -- WSA1 CPU-1 RAM variables whose meaning a findings note establishes get a name.

QUESTION THIS ANSWERS / JOB IT DOES
  prom_a and prom_b (one CPU, one RAM) address their variables by number: `ld (0x2540:16), 0`,
  `ld (9536:16), 0` (prom_b spells addresses in decimal), `m_add_rm MW16, 0x2555, r4`.  Where a
  wsa1/notes FINDINGS table establishes what an address holds -- with the routine or service that
  establishes it -- the address gets a name in wsa1/include/wsa1_ram.inc (generated here from GROUPS:
  the LCD drawing state, the inter-processor link block, prom_b's field-blink control block, the
  UI request / screen state, the block store, the SC1 panel link and the switch shadow, the tick
  counter, the model-variant flag, the disk flags, the part index),
  and the memory operands and the macro address arguments that spell it become the name.
  Only memory operands `(N)` / `(N:8)` / `(N:16)` / `(N:24)`, the address argument of the m_* macros
  (`MB8|MW8|MD8|ML8|...|MD24|ML24, N`), the last argument of the memory-to-memory macros
  (m_ld_mm16 / m_ldw_mm16 / m_ld_m16m: the other 16-bit address) and 24-bit immediates (`ld XIY,0x006007db`: at that width
  only an address) change; a 16-bit immediate equal to the number may be a value, and data
  (`.byte` / `.short`) is left alone -- except the +0x02 field of an interpreter-B display-list
  record (`.short 0x27A7 ; +0x02 source variable`), which IS the 16-bit address of the variable drawn.  Comments keep the numbers -- the WSA1 tools read
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
        0x0EF5: ("UI_StepRecord_SubScreen", "which sub-screen of screen 0x0E is showing", "FINDINGS-prom_b-for-the-mame-driver.md"),
        0x2070: ("UI_Request", "16-bit message code; high byte 0x80 = go to the screen id in the low byte", "the panel row handlers; song-store.md: `(0x2070)` takes a 16-bit message code"),
        0x2071: ("UI_Request_Hi", "UI_Request's high byte: 0x80 with a screen id", "panel-control-map.md: the screen-request pair"),
        0x2075: ("UI_RequestBits", "request bits, set by `or` and cleared by `and`; several owners (bit 1 = blink enable)", "song-store.md; field-blink.md"),
        0x207C: ("UI_ScreenId", "the screen id; indexes the 256-entry table at prom_b 0xF2D000", "ld L,(0x207C) / xor H,H / sla 0x02,HL"),
        0x2661: ("Value_AsciiDigits", "three ASCII digits, the output of prom_a's Value_ToAsciiDigits3", "FINDINGS-prom_b-for-the-mame-driver.md"),
        0x2662: ("Value_AsciiDigits+1", "", ""),
        0x2663: ("Value_AsciiDigits+2", "", ""),
        0x1088: ("InputStream_Cursor", "cursor into the 1,024-byte input window at 0x60A700-0x60AAFF", "InputStream_Refill refills the window"),
        0x2880: ("UI_StatusCode", "a status/error byte: eleven literal values; the block store's error table feeds it", "song-store.md; f6d002-module.md"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-block-store.md", "The cursor; the heap base; with FINDINGS-prom_b-song-store.md's allocator table and prom_b's BStore_* headers", {
        0x0C59: ("BStore_CopyDestAddr", "BStore_CopyAcrossBlocks' destination block address", "BStore_CopyAcrossBlocks header"),
        0x0C63: ("BStore_CopySrcAddr", "BStore_CopyAcrossBlocks' source block address", "BStore_CopyAcrossBlocks header"),
        0x0CA4: ("BStore_BlockLimit", "BStore_LoadGeometry's copy of the block count; the cp WA,(0x0CA4) bound of BStore_CursorAdvance / BStore_OpenChain", "BStore_LoadGeometry header"),
        0x0CA6: ("BStore_GeomBase", "BStore_LoadGeometry's copy of the heap base", "BStore_LoadGeometry header"),
        0x0CAC: ("BStore_BlocksAllocated", "BStore_AllocChain output: blocks allocated", "BStore_AllocChain header"),
        0x0CAE: ("BStore_AllocBytesWanted", "BStore_AllocChain input: byte count wanted", "BStore_AllocChain header"),
        0x0CC0: ("BStore_LinkBlock", "BStore_AllocChain input: the block to link the new chain onto", "BStore_AllocChain header"),
        0x0CC2: ("BStore_LastBlockAddr", "BStore_AllocChain output: the last block's address", "BStore_AllocChain header"),
        0x0CC6: ("BStore_LastBlockUsed", "BStore_AllocChain input: bytes already in the last block", "BStore_AllocChain header"),
        0x0D08: ("BStore_LastBlockFree", "BStore_AllocChain output: bytes free in the last block", "BStore_AllocChain header"),
        0x0D4A: ("BStore_ErrorCode", "the block store's error code; BStore_ErrorToStatusByte maps it to UI_StatusCode", "BStore_ErrorToStatusByte"),
        0x1008: ("BStore_DirEntry", "the directory entry BStore_AppendBytes appends to", "BStore_AppendBytes"),
        0x126E: ("BStore_CursorBlockAddr", "the cursor's block address (0x617800 + (n-1)*0x100)", "BStore_SeekBlock"),
        0x12A2: ("BStore_AllocHeapBase", "the allocator's own copy of the heap base", "BStore_LatchHeapBase"),
        0x345E: ("BStore_CursorOffset", "the cursor's byte offset in its block, 5..0xFF", "prom_b cursor headers: ((0x345C) block number, (0x345E) offset)"),
        0x345C: ("BStore_CursorBlock", "the cursor's 1-based block number", "the block-store cursor section"),
        0x360A: ("BStore_CurrentBank", "the current bank, 0..9 (prom_a refuses to step outside); bank n lives at 0x610000 + n*0xC00", "0xF8143F cp A,0 / 0xF814D2 cp A,0x09"),
        0x3604: ("BStore_HeapBase", "the heap base, 0x00617800", "BStore_SeekBlock and its two inverses"),
        0x3608: ("BStore_BlockCount", "how many blocks BStore_FreeList_Init threads onto the free list", "BStore_FreeList_Init"),
        0x6034B8: ("BStore_FreeHead", "head of the free list; 0xFFFF = empty", "BStore_AllocBlock"),
        0x6034BA: ("BStore_FreeCount", "number of blocks on the free list", "BStore_FreeChain"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-sc1-link.md", "The RAM, and why every extent is exact; with prom_b's SC1 module header (THE RAM STATE)", {
        0x0080: ("Tick_Count", "the tick counter INTT1_Tick increments (488.28 Hz)", "INTT1_Tick; prom_a's own header"),
        0x2A80: ("SC1_State", "state; a byte offset into SC1_StateTable, stepped by 4", "inc 4,(0x2A80) / dec 4,(0x2A80)"),
        0x2A81: ("SC1_RxBytesExpected", "bytes still expected in the message being received", "SC1 receive path"),
        0x2A82: ("SC1_BusyFlags", "bit 0 rx active, bit 1 tx active, bit 2 SC1_Service_SetBit2/ClearBit2, bit 4 tested once", "SC1 module header"),
        0x2A83: ("SC1_ConfigSelector", "compared against 1, 2 and 3 in SC1_ConfigurePort only", "SC1_ConfigurePort"),
        0x2A84: ("SC1_ErrorBits", "sticky error/event bits: 0 rx ring full, 1 tx aborted, 2 abort, 3 decoder gave up, 6 INT6 while busy, 7 impossible state", "SC1 module header"),
        0x2A85: ("SC1_StatusResult", "result byte of SC1_Cmd_E0_ReadStatus", "SC1_Cmd_E0_ReadStatus"),
        0x2A86: ("SC1_P8CR_Shadow", "shadow of P8CR, which this driver only writes from here", "every write to 0x1A is ld A,(shadow)"),
        0x2A87: ("SC1_P8FC_Shadow", "shadow of P8FC, which this driver only writes from here", "every write to 0x1B is ld A,(shadow)"),
        0x2A88: ("SC1_LastInbound", "the last three bytes handed to the inbound queue", "SC1_RxOp0_ThreeByte and SC1_RxOp2"),
        0x2A89: ("SC1_LastInbound+1", "", ""),
        0x2A8A: ("SC1_LastInbound+2", "", ""),
        0x2A8B: ("SC1_TxDrainRetries", "retry counter of SC1_WaitTxDrain, 0xC8 = 200", "SC1_WaitTxDrain"),
        0x2A8E: ("SC1_TickSnapshot", "snapshot of Tick_Count taken by the three tick waits", "the tick waits"),
        0x2A90: ("SC1_RxReadIndex", "rx ring read index", "SC1 module header"),
        0x2A92: ("SC1_RxWriteIndex", "rx ring write index", "SC1 module header"),
        0x2A94: ("SC1_RxRing", "rx ring, 76 bytes (0x4C, the modulus of SC1_RxRing_Next)", "abuts 0x2AE0"),
        0x2AE0: ("SC1_TxReadIndex", "tx ring read index", "SC1 module header"),
        0x2AE2: ("SC1_TxWriteIndex", "tx ring write index", "SC1 module header"),
        0x2AE4: ("SC1_TxRing", "tx ring, 60 bytes (0x3C, the modulus of SC1_TxRing_Next)", "abuts 0x2B20"),
        0x2B20: ("Panel_SwitchShadow", "the debounced switch-state shadow: one byte per switch-matrix column, index 0..0x1F", "round 10: wires 0xC0-0xCA index 0x10 + (wire & 0x0F)"),
        0x2B40: ("SC1_InQueue", "inbound queue: 10-byte descriptor + 86 bytes", "SC1_ConfigurePort writes the descriptor"),
        0x2BA0: ("SC1_OutQueue", "outbound queue: the same shape", "SC1_ConfigurePort"),
        **{0x2B20 + k: ("Panel_SwitchShadow+0x%02x" % k, "", "") for k in range(1, 32)},
    }),
    ("wsa1/notes/FINDINGS-prom_a-boot-and-version-screen.md", "3. The model-variant flag (0x00C4) comes from PORT B BIT 0", {
        0x00C4: ("Variant_Flag", "the model variant: 1 when port B bit 0 reads high, 2 when low; set once on reset", "Variant_SetFromPB0"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-disk-cmd-layer.md", "File-system workers", {
        0x21E7: ("Disk_Flags", "bit 6: the ready flag, set and cleared from the result byte (0x1735); other bits not established", "sub_FE08BD; Disk_FormatSelectedMedia tests and C,0x40"),
    }),
    ("wsa1/notes/FINDINGS-l7a1429-parameter-names.md", "2c. The CPU 1 sender, and the element bits -- GRADE PROVEN", {
        0x2250: ("UI_PartIndex", "the part index the CPU 1 parameter sender puts in byte[1]", "sub_FD616A"),
    }),
    ("wsa1/prom_b/wsa1_prom_b.s", "EffectAlgoMaps header (0xF133E4)", {
        0x2797: ("Effect_BlockIndex", "which DSP effect block: IndexedTable entry 97, 98 or 99, minus 97", "EffectAlgoMaps: (0x2797) = entry - 97"),
    }),
    ("wsa1/prom_a/wsa1_prom_a.s", "UiListA_* headers: the payload UiEventList_Run hands the class handlers", {
        0x20B8: ("UiEvent_Byte1", "the event record's byte +1; the message/page number the 0xFC0000 module dispatches on", "UiListA_* headers; MidiIn_ReqRouteRebuild_Msg0D"),
        0x20B9: ("UiEvent_Byte2", "the event record's byte +2", "UiListA_* headers"),
        0x20BA: ("UiEvent_Byte3", "the event record's byte +3", "UiListA_* headers"),
        0x20BB: ("UiEvent_Class", "the event record's class", "UiListA_* headers"),
    }),
    ("wsa1/prom_b/wsa1_prom_b.s", "the SMF reader's input-stream fetch header", {
        0x124A: ("InputStream_Status", "the fetch's status: 1 on the fast path, else InputStream_Refill's return code; callers test 1 and 0xFD", "the fetch at the head of 0xF6F5A2-0xF7136F"),
    }),
    ("wsa1/prom_a/wsa1_prom_a.s", "Disk_FormatSelectedMedia / LCD_TextCol_* headers", {
        0x2243: ("Disk_LastError", "the error code the FDC layer returned", "Disk_FormatSelectedMedia: Outputs"),
        0x259C: ("LCD_TextColumnAddr", "display-RAM address of the byte column the packed-text services write", "LCD_TextCol_SetCursor: Inputs"),
        0x259E: ("LCD_TextBitOffset", "the packed-text bit offset / shift count, 0..8", "the packed-text services' Inputs"),
    }),
    ("wsa1/notes/FINDINGS-l7a1429-editor-pages.md", "0. THE ANSWER: the MODELING pages store reply n at ((u8 *)0x27A6)[n]; extent 0x27A6-0x27B7 per FINDINGS-prom_b-ui-variable-index.md", dict(
        [(0x27A6, ("ModelingPage_Fields", "the MODELING pages' fields as read back from CPU 2, reply n at +n (bytes to 0x27B7)", "the pages' read-back order, 8 of 8 field editors agree"))] +
        [(0x27A6 + k, ("ModelingPage_Fields+%d" % k, "", "")) for k in range(1, 18)])),
    ("wsa1/notes/FINDINGS-prom_b-message-line.md", "2. 0x00000FE4 is one line of on-screen text: record 0xF3D38A draws 30 characters from it", dict(
        [(0x0FE4, ("MsgLine_Text", "the 30 characters (to 0x1001) of the bottom text line the panel draws (y = 180)", "record 0xF3D38A; MsgLine_Clear blanks exactly 30"))] +
        [(0x0FE4 + k, ("MsgLine_Text+%d" % k, "", "")) for k in range(1, 30)])),
    ("wsa1/notes/FINDINGS-prom_a-fdc.md", "6. The API (the 16-byte request block); 7. Errors; with FINDINGS-dev7b-and-int5.md", dict([
        (0x605A00, ("Fdc_TickCount", "16-bit INTT1 tick counter; INTT1_Tick its only writer; the 500-tick timeouts", "prom_a_addr_census.py 0x605A00")),
        (0x605A09, ("Fdc_ReentryGuard", "0xA5 while a request runs; a second entry returns error 0xFB", "Fdc_Request")),
        (0x605A0E, ("Fdc_DmaCount", "the count Dev7A_StartDma loads into DMAC0", "Dev7A_StartDma")),
        (0x605A15, ("Fdc_ErrorCode", "the request's error code; Fdc_SetError keeps the first, every operation clears it", "Fdc_SetError")),
        (0x605A18, ("Fdc_CommandByte", "the uPD765 command byte Dev7A_StartDma's compare chain reads", "Dev7A_StartDma")),
        (0x605A30, ("Fdc_ReqOp", "the request block Fdc_Request copies here: +0 word operation 0..11", "Fdc_Request")),
        (0x605A32, ("Fdc_ReqUnit", "request +2: unit 0 or 1, which selects the back end", "every operation begins cp (0x605A32),1")),
        (0x605A34, ("Fdc_ReqHead", "request +4: head", "Fdc_Request")),
        (0x605A36, ("Fdc_ReqTrack", "request +6: track, or the media descriptor byte for operation 0", "Fdc_Request")),
        (0x605A38, ("Fdc_ReqSector", "request +8: first sector", "Fdc_Request")),
        (0x605A3A, ("Fdc_ReqCount", "request +0x0A: sector count", "Fdc_Request")),
        (0x605A3C, ("Fdc_ReqBuffer", "request +0x0C: buffer address, the pointer the DMA path walks", "Fdc_Request; Dev7A_Dma_*")),
        (0x605A3E, ("Fdc_ReqBuffer+2", "", "")),
        (0x605A40, ("Fdc_ReqCopy", "the second copy of the request block (why two: not established)", "Fdc_Request")),
        (0x605A50, ("Fdc_ResultBuf", "INT5 / the drain store result bytes at +1.., and INT5 zeroes +0 on exit", "INT5_Dev7B_Receive; Fdc_WaitReadyForCommandByte")),
        (0x605AEE, ("Fdc_CurrentCylinder", "the cylinder the head is on; SEEK is skipped when it already matches", "Fdc_Op2_SeekToCylinder")),
        (0x605AF1, ("Fdc_LastCylinderPlus1", "last cylinder + 1, derived from the geometry", "Fdc_Op0_ResetAndIdentifyMedia")),
        (0x605AF7, ("Fdc_SectorsPerTrackPlus1", "sectors per track + 1, derived from the geometry", "Fdc_Op0_ResetAndIdentifyMedia")),
    ] + [(0x605A50 + k, ("Fdc_ResultBuf+%d" % k, "", "")) for k in range(1, 8)])),
    ("wsa1/notes/FINDINGS-prom_b-smf-writer.md", "Why the MTrk length is zero; It really is a MIDI writer; with FINDINGS-prom_b-for-the-mame-driver.md (the 8.3 name)", dict([
        (0x126C, ("SmfOut_WindowsFlushed", "how many 1,024-byte output windows the SMF writer has flushed", "the MTrk length computation at 0xF7789A")),
        (0x10C4, ("SmfOut_TrackLength", "the MTrk chunk length, most significant byte first (4 bytes)", "0xF7789A stores it; copy A writes it into the file")),
        (0x10C5, ("SmfOut_TrackLength+1", "", "")), (0x10C6, ("SmfOut_TrackLength+2", "", "")), (0x10C7, ("SmfOut_TrackLength+3", "", "")),
        (0x108C, ("SmfOut_Tempo", "the 24-bit Set Tempo value (FF 51 03), emitted +2, +1, +0", "0xF77918; staged by 0xF778D2")),
        (0x108D, ("SmfOut_Tempo+1", "", "")), (0x108E, ("SmfOut_Tempo+2", "", "")),
        (0x21C8, ("Disk_FileName", "an 8.3 file name: 8 characters, extension at +8..+10 (default MID)", "the SMF reader writes M I D to 0x21D0-0x21D2; the writer's track name takes the 8")),
    ] + [(0x21C8 + k, ("Disk_FileName+%d" % k, "", "")) for k in range(1, 11)])),
    ("wsa1/notes/FINDINGS-prom_a-screen-module.md", "8. The NOTE / DRUM EDIT state in work DRAM", {
        0x601F3F: ("EditCursor_Measure", "the NOTE / DRUM EDIT cursor's measure, 1..999 (word)", "sub_FEAAB6 / sub_FEAAE0 clamp it; sub_FE9E04 carries the beat into it"),
        0x601F41: ("EditCursor_Beat", "the cursor's beat within the measure, from 0 (word)", "sub_FE9E04 wraps it at sub_FE9F23's beat count"),
        0x601F43: ("EditCursor_Tick", "the cursor's tick within the beat, 0..95", "sub_FE9DB4 / sub_FE9DD5 step it and clamp to 0x5F"),
        0x601F45: ("EditField_Note", "the NOTE field (DRUM EDIT: SND), 1..127", "EditField_NoteUp / _Down / _Up5 / _Down5"),
        0x601F46: ("EditField_Velocity", "the VEL field, 1..127, 100 by default", "EditField_VelocityUp / _Down / _Up5 / _Down5; 0xFE833F sets 100"),
        0x601F47: ("EditField_Length", "the LEN field (word), 1..0x2FFF, when (0x601F5B) bit 0 is set", "EditField_LengthUp / _Down / _Up12 / _Down12"),
        0x601F4D: ("EditField_Inc", "the INC field (word): the cursor step in ticks, 1..0x60, 0x30 by default", "EditField_IncUp / _Down / _Up5 / _Down5"),
        0x601F71: ("DrumEdit_TopRowNote", "the note number of DRUM EDIT's top row; row k shows it + k; 0x28 by default", "DrumEdit_DrawRowNote0..11; EditScreen_BootPhase2And4 sets 0x28"),
        0x601F73: ("EditScreen_CursorRow", "the left column's highlighted row, 0..11 (y = row * 10 + 0x2A); 5 by default", "EditScreen_HighlightCursorRow; EditScreen_BootPhase2And4 sets 5"),
        0x601F54: ("EditCursor_TickInMeasure", "the cursor's position in ticks from the start of the measure (word), below EditMeasure_Beats * 96", "EditCursor_NextBeat compares it with EditMeasure_Beats * 0x60 - 1; EditCursor_MeasureChanged zeroes it with the beat and tick"),
        0x601F75: ("EditMeasure_Beats", "beats in the measure being edited; * 0x60 = its length in ticks", "EditCursor_NextBeat, EditScreen_CursorRight"),
        0x601F70: ("EditScreen_Mode", "bit 0: 1 = DRUM EDIT, 0 = NOTE EDIT; selects the layout tables ScreenDrawPtrs_FEF9FA / _FEFA2A", "ShowScreen_DrumEditPartSelect / sub_FE8868 set it, ShowScreen_NoteEditPartSelect / sub_FE88AA clear it"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-panel-state-variables.md", "1. The mode / screen latches; 2. The dial's button pair", {
        0x2078: ("PanelMode", "the panel mode; PanelMode_ToScreenId maps it to a screen", "PanelState_LatchPrevious, PanelMode_ToScreenId"),
        0x2079: ("PanelMode_Previous", "PanelMode at the previous pass of the panel task", "PanelState_LatchPrevious"),
        0x207A: ("UI_ScreenLatch", "UI_ScreenId latched when the mode changes or (0x2092) bit 0 is clear", "PanelState_UpdateScreenLatch, PanelState_Init"),
        0x207B: ("UI_ScreenLatch_Previous", "UI_ScreenLatch at the previous pass; Enter / Leave bodies compare the two", "PanelState_LatchPrevious"),
        0x207D: ("UI_ScreenId_Previous", "UI_ScreenId at the previous pass", "PanelState_LatchPrevious"),
        0x209B: ("PanelDial_DownButton", "the button code the dial acts as when turned down (with (0x2075) bit 0 set)", "PanelEvent_Code21_Dial 0xF8687A"),
        0x209C: ("PanelDial_UpButton", "the button code the dial acts as when turned up", "PanelEvent_Code21_Dial 0xF86874"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-system-menu-screen-state.md", "the SYSTEM-menu screens' state bytes", {
        0x2690: ("TuneScale_ItemCursor", "TUNE & SCALE item, 0..4 in bits 0-2", "TuneScale_MoveItemCursor"),
        0x2691: ("TuneScale_MasterTuneIndex", "index of the MASTER TUNE value (ByteTable79_FA1C5C)", "TuneScale_StoreMasterTune"),
        0x2692: ("TuneScale_KeyScalingIndex", "index of the key-scaling type (ByteTable16_FA1C4C)", "TuneScale_StoreKeyScalingType"),
        0x2695: ("SoundGroupNaming_Bank", "bank 0..4 (USER1/USER2/RE-MAP1-3)", "SoundGroupNaming_AdjustBank"),
        0x2696: ("SoundGroupNaming_Group", "group 0..15", "SoundGroupNaming_AdjustGroup"),
        0x2698: ("CombinationGroupNaming_Bank", "bank 0..3", "CombinationGroupNaming_AdjustBank"),
        0x2699: ("CombinationGroupNaming_Group", "group 0..15", "CombinationGroupNaming_AdjustGroup"),
        0x269A: ("CopyScreen_Page", "SOUND / COMBINATION COPY page: bit 0 SINGLE, bit 1 the question, bit 2 an error", "Paint_SoundCopy, Paint_CombinationCopy"),
        0x269B: ("SoundCopy_SourceBank", "ROM 1 / ROM 2 / USER 1 / USER 2 / EXT 1", "SoundCopy_AdjustSourceBank"),
        0x269C: ("SoundCopy_SourceGroup", "the source group", "SoundCopy_AdjustSourceBank"),
        0x269D: ("SoundCopy_SourceSound", "SINGLE page: the source sound", "SoundCopy_DrawSourceSoundCursor"),
        0x269E: ("SoundCopy_SourceGroupRow", "GROUP page: cursor row of the source list", "SoundCopy_DrawSourceGroupCursor"),
        0x269F: ("SoundCopy_SourceListTop", "GROUP page: first group of the source list", "SoundCopy_DrawSourceGroupList"),
        0x26A0: ("SoundCopy_DestBank", "USER 1 / USER 2", "SoundCopy_AdjustDestBank"),
        0x26A1: ("SoundCopy_DestGroup", "the destination group", "SoundCopy_AdjustDestBank"),
        0x26A2: ("SoundCopy_DestSound", "SINGLE page: the destination sound", "SoundCopy_DrawDestSoundCursor"),
        0x26A3: ("SoundCopy_DestGroupRow", "GROUP page: cursor row of the destination list", "SoundCopy_DrawDestGroupCursor"),
        0x26A4: ("SoundCopy_DestListTop", "GROUP page: first group of the destination list", "SoundCopy_DrawDestGroupList"),
        0x26A5: ("DataLoadFilter_ItemCursor", "DATA LOAD FILTER row (JumpTable_F9EC58 index)", "DataLoadFilter_*"),
        0x2702: ("DrumsMap_Map", "NORMAL / USER 1-3", "DrumsMap_AdjustMap"),
        0x2703: ("DrumsMap_RowCursor", "cursor row 0..11", "DrumsMap_MoveRowCursor"),
        0x2704: ("DrumsMap_ListTop", "first note the rows show", "DrumsMap_MoveRowCursor"),
        0x2706: ("CombinationCopy_SourceBank", "the source bank", "CombinationCopy_AdjustSourceBank"),
        0x2707: ("CombinationCopy_SourceGroup", "the source group", "CombinationCopy_AdjustSourceBank"),
        0x2708: ("CombinationCopy_SourceCombi", "SINGLE page: the source combination", "CombinationCopy_DrawSourceCombiCursor"),
        0x2709: ("CombinationCopy_SourceGroupRow", "GROUP page: cursor row of the source list", "CombinationCopy_DrawSourceGroupCursor"),
        0x270A: ("CombinationCopy_SourceListTop", "GROUP page: first group of the source list", "CombinationCopy_DrawSourceGroupList"),
        0x270B: ("CombinationCopy_DestBank", "the destination bank", "CombinationCopy_AdjustDestBank"),
        0x270C: ("CombinationCopy_DestGroup", "the destination group", "CombinationCopy_AdjustDestBank"),
        0x270D: ("CombinationCopy_DestCombi", "SINGLE page: the destination combination", "CombinationCopy_DrawDestCombiCursor"),
        0x270E: ("CombinationCopy_DestGroupRow", "GROUP page: cursor row of the destination list", "CombinationCopy_DrawDestGroupCursor"),
        0x270F: ("CombinationCopy_DestListTop", "GROUP page: first group of the destination list", "CombinationCopy_DrawDestGroupList"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-system-menu-screen-state.md", "2. The MIDI and disk screens", {
        0x2720: ("UI_ScreenItem", "the item the current screen's cursor is on (MIDI, sysex, disk screens); GENERAL MIDI: bit 2 its pending ON / OFF", "MidiTotalMode_StepItem and 38 more"),
        0x2746: ("MidiOutPgm_Channel", "MIDI OUT PROGRAM CHANGE: MIDI channel 0..0x1F", "MidiOutProgramChange_EditMidiCh"),
        0x2747: ("MidiOutPgm_Program", "the program, 0..0x7F", "MidiOutProgramChange_EditProgram"),
        0x2748: ("MidiOutPgm_BankMsb", "bank select MSB", "MidiOutProgramChange_EditBankMsb"),
        0x2749: ("MidiOutPgm_BankLsb", "bank select LSB", "MidiOutProgramChange_EditBankLsb"),
        0x274A: ("MidiOutPgm_BankSelect", "word MSB*128+LSB, 0xFFFF = OFF", "MidiOutProgramChange_ResetState / _EditBankLsb"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-medley-and-name-edit-state.md", "1. SEQUENCER MEDLEY; 2. The name editor", {
        0x2208: ("Medley_FirstSong", "the first song of the medley (index; shown + 1)", "SequencerMedley_KeypadCommit"),
        0x2209: ("Medley_LastSong", "the last song", "SequencerMedley_KeypadCommit"),
        0x220A: ("Medley_PlayingSong", "the song now playing", "SequencerMedley_DrawPlayState"),
        0x220B: ("Medley_Source", "0 INT, 1 FD, 2 HD", "SequencerMedley_DrawSourceBox"),
        0x0E35: ("Medley_FileType", "0 NORM FILE, 1 MIDI FILE", "SequencerMedley_DrawFileTypeBox"),
        0x0DC1: ("Medley_Playing", "1 while the medley plays", "SequencerMedley_NumberPad / _DrawPlayState"),
        0x0C0F: ("Medley_Field", "the selected field, 1 FIRST S0NG / 2 LAST S0NG", "SequencerMedley_KeypadCommit"),
        0x222D: ("NameEdit_CursorPos", "the character position of the name cursor", "S0ngSelectName_CursorLeft / _CursorRight"),
        0x21F9: ("NameEdit_CharIndex", "the character-set index of the character at the cursor", "SongName_CharIndexAtCursor"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-medley-and-name-edit-state.md", "3. The song-edit screens", {
        0x0DE5: ("AdvanceDelay_Field", "the selected field", "AdvanceDelay_KeypadCommit"),
        0x0DED: ("N0teChange_Field", "the selected field (2/3 measures, 4/5 notes)", "N0teChange_KeypadCommit"),
        0x0DF0: ("N0teChange_FromMeasure", "field 2, 1..999", "N0teChange_KeypadCommit"),
        0x0DF2: ("N0teChange_ToMeasure", "field 3, 1..999", "N0teChange_KeypadCommit"),
        0x0DF4: ("N0teChange_FromNote", "field 4, note 0..127", "N0teChange_KeypadCommit"),
        0x0DF5: ("N0teChange_ToNote", "field 5, note 0..127", "N0teChange_KeypadCommit"),
        0x0DBC: ("MeasureC0py_Field", "the selected field", "MeasureC0py_KeypadCommit"),
        0x0DDA: ("MeasureInsert_Field", "the selected field", "MeasureInsert_KeypadCommit"),
        0x0E0C: ("S0ngC0py_FromSong", "the source song (1-based)", "S0ngC0py_DrawFromSong"),
        0x0E0D: ("S0ngC0py_ToSong", "the destination song", "S0ngC0py_DrawToSong"),
        0x0E0E: ("S0ngC0py_FromTrack", "the source track; 0x12 = ALL", "S0ngC0py_DrawTracks"),
        0x0E0F: ("S0ngC0py_ToTrack", "the destination track", "S0ngC0py_DrawTracks"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-mode-screen-state.md", "1. The sound selection; 2. COMBINATION MODE", {
        0x216A: ("SoundSel_Bank", "the selected bank (R1 0, R2 1, U1 8, U2 9, RD 0x20, UD 0x28/0x29, E1 0x10, RE-MAP 0x18-0x1A)", "SoundBank_Select*, PanelLed_ShowBank"),
        0x2169: ("SoundSel_Group", "the selected group", "SoundGroup_StepSelected"),
        0x216B: ("SoundSel_Member", "the selected member", "SoundGroup_LoadSelectionFromPart / _FromGlobal"),
        0x2675: ("SoundGroupMenu_Highlight", "the group the menu box is drawn on", "SoundGroupMenu_MoveGroupHighlight"),
        0x2670: ("GroupMembers_Page", "the page of members shown", "GroupMembers_ShowPageOfTwo / _OfMany"),
        0x267F: ("DisplayHold_Flag", "bit 0: DISPLAY HOLD on", "SoftKeyCol7/8_GroupSoundDisplayHold"),
        0x2687: ("CombinationMode_Page", "0 page 1, 1 page 2", "PageKey_C0mbinati0nM0de"),
        0x2678: ("CombinationMode_EditRow", "page 2 row: bit 0 SOUND, 3 INT, 2 PAN, 1 VOL", "C0mbinati0nM0de_EditSelectedRow"),
        0x267D: ("CombinationMode_Solo", "bit 0: SOLO", "LcdKeyRow1_C0mbinati0nM0de_Page2"),
        0x267E: ("CombinationMode_ShownPart", "the part the PART box was last drawn for", "C0mbinati0nM0de_ShowSelectedPart"),
        0x2676: ("ModeScreen_DirtyFields", "page-1 value fields to redraw, a bit each", "Paint_SoundModeFields"),
        0x2677: ("ModeScreen_DirtyFields2", "more field bits (0x18-0x1A events: bits 0-2)", "UiEvent_MarkRedrawFromClass20Block"),
        0x2679: ("CombinationMode_DirtySound", "page 2: parts whose SOUND cell to redraw", "UiEvent_MarkPartRedrawBits"),
        0x267A: ("CombinationMode_DirtyInt", "parts whose INT cell to redraw", "UiEvent_MarkPartRedrawBits"),
        0x267B: ("CombinationMode_DirtyPan", "parts whose PAN cell to redraw", "UiEvent_MarkPartRedrawBits"),
        0x267C: ("CombinationMode_DirtyVol", "parts whose VOL cell to redraw", "UiEvent_MarkPartRedrawBits"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-panel-io-state.md", "panel LED, analog-control and held-key state", {
        0x20D0: ("PanelLed_Shadow", "8 LED bytes as they should be", "PanelLed_Show*, PanelLed_SendChangedBytes"),
        0x20F0: ("PanelLed_Sent", "the 8 LED bytes as last sent", "PanelLed_SendChangedBytes"),
        0x28E0: ("AnalogScan_HystState", "two hysteresis bytes per A/D channel 0-3", "AnalogScan_AdChannel0..3"),
        0x28EC: ("AnalogScan_Cooked", "six cooked controller values, bit 7 = changed: +0/+1 channels 4/5, +2..+5 A/D 0-3", "AnalogScan_*, PanelGroupQueue_AppendFlaggedGroups"),
        0x2252: ("PanelHeld_Pos0", "32-bit set of the pair-position-0 keys held", "PanelAction_PairPos0_HeldMask"),
        0x2256: ("PanelHeld_Pos1", "32-bit set of the pair-position-1 keys held", "PanelAction_PairPos1_HeldMask"),
        0x2196: ("PanelWire_Phase", "poll phase 0..3", "PanelWire_ThrottledPoll"),
        0x2197: ("PanelWire_LastPollTick", "Tick_Count at the last producer poll (word)", "PanelWire_PollProducers"),
        **{0x20D0 + k: ("PanelLed_Shadow+%d" % k, "", "") for k in range(1, 8)},
        **{0x20F0 + k: ("PanelLed_Sent+%d" % k, "", "") for k in range(1, 8)},
        **{0x28E0 + k: ("AnalogScan_HystState+%d" % k, "", "") for k in range(1, 8)},
        **{0x28EC + k: ("AnalogScan_Cooked+%d" % k, "", "") for k in range(1, 6)},
    }),
    ("wsa1/notes/FINDINGS-prom_a-midi-settings.md", "the MIDI settings bytes 0x7F32-0x7F3B", {
        0x7F32: ("MidiCfg_ModeBits", "bits 0-1 PROG CHANGE MODE, bit 3 SINGLE CH PROG CHANGE; read by the clock code too", "MidiTotalMode_EditProgChangeMode"),
        0x7F33: ("MidiFilter_SongSelect", "bit 3: SONG SELECT filter", "MidiInputOutputFilter_EditSongSelect"),
        0x7F35: ("MidiCfg_InOutMode", "bits 0-3 INPUT MODE, 4-7 OUTPUT MODE", "MidiTotalMode_EditInputMode"),
        0x7F36: ("MidiCfg_SingleChannel", "bits 0-3 SINGLE CHANNEL, bit 5 LOCAL TOTAL off", "MidiTotalMode_EditSingleChannel"),
        0x7F38: ("MidiFilter_Exclusive", "bits 0-3 EXCLUSIVE", "MidiInputOutputFilter_EditExclusive"),
        0x7F39: ("MidiFilter_ChannelMsgs", "bit 3 CC, 4 PC, 5 CHANNEL PRESSURE, 6 PITCH BEND", "MidiInputOutputFilter_Edit*"),
        0x7F3A: ("MidiFilter_BankSelect", "bit 7 BANK SELECT", "MidiInputOutputFilter_EditBankSelect"),
        0x7F3B: ("MidiFilter_ResetAllCtrl", "bit 0 RESET ALL CTRL", "MidiInputOutputFilter_EditResetAllCtrl"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-seqbuf-and-timed-events.md", "the sequencer buffer, the timed-event ring and the 96-tick counter", {
        0x0093: ("Seq_BeatTick", "tick within the beat, 0..0x5F", "INTTR4_SequencerTick, TimedEvents_IsNotYetDue"),
        0x00C2: ("MainTask_TickCountdown", "ticks until the main loop's periodic pass", "MainTask_RearmTickCountdown"),
        0x00AA: ("SeqBuf_Flags", "bit 0: append through the staging buffer", "SeqBuf_AppendEvent / _FlushStaged"),
        0x00AC: ("SeqBuf_StagedCount", "bytes staged (word)", "SeqBuf_FlushStaged"),
        0x00AE: ("SeqBuf_Staged", "the staged bytes", "SeqBuf_FlushStaged"),
        0x600A14: ("SeqBuf_Ring", "the 0x200-byte sequencer ring; descriptor below it", "Ring600A14_*, SeqBuf_PutByte"),
        0x600A10: ("SeqBuf_RingPut", "the ring's write index", "SeqBuf_PutByte"),
        0x600A12: ("SeqBuf_RingFree", "the ring's free count", "SeqBuf_PutByte"),
        0x60080A: ("TimedEvents_Ring", "the timed-event ring", "Ring60080A_*, TimedEvents_DrainDue"),
    }),
    # 2026-10-04: the three transports INTTR4_SequencerTick advances.  Which three things they are is not
    # established, so they keep the header's letters A, B, C.
    ("wsa1/prom_a/wsa1_prom_a.s", "INTTR4_SequencerTick header: THREE TRANSPORTS, NOT ONE", {
        0x0094: ("TransportA_State", "transport A's state: bit 2 running; 0x01 start, 0x0C stop request", "INTTR4_SequencerTick, Transport_StopAllRunning"),
        0x0096: ("TransportB_State", "transport B's state, same bits", "INTTR4_SequencerTick, Transport_StopAllRunning"),
        0x0095: ("TransportC_State", "transport C's state, same bits; also the MIDI clock source", "INTTR4_SequencerTick, MIDI_RT_Start_ResetCounters"),
        0x008B: ("TransportA_Tick", "transport A's tick, 0..95", "INTTR4_SequencerTick"),
        0x008C: ("TransportA_Beat", "transport A's beat in the bar", "INTTR4_SequencerTick wraps it at TransportA_BeatsPerBar"),
        0x605000: ("TransportA_BeatsPerBar", "beats per bar for transport A", "INTTR4_SequencerTick"),
        0x605002: ("TransportA_Bar", "transport A's bar counter (word)", "INTTR4_SequencerTick"),
        0x0091: ("TransportB_Beat", "transport B's beat counter (word); its tick is Seq_BeatTick", "INTTR4_SequencerTick"),
        0x008D: ("TransportC_Tick", "transport C's tick, 0..95", "INTTR4_SequencerTick"),
        0x008E: ("TransportC_Beat", "transport C's beat counter (word)", "INTTR4_SequencerTick"),
    }),
    ("wsa1/prom_a/wsa1_prom_a.s", "MIDI_TX_Ready header: the real-time requests", {
        0x00A0: ("MidiTx_RealtimePending", "bits 0-4 queue F8 clock, FA start, FB continue, FC stop, FE active sensing", "MIDI_TX_Ready"),
    }),
    ("wsa1/prom_a/wsa1_prom_a.s", "DiskApi_ReadFileToWindow header (the window); prom_b DL_F583F0 (the content type)", {
        0x21D3: ("Disk_WindowStart", "start of the memory window a file is read into / written from (32-bit)", "DiskApi_ReadFileToWindow, DiskLoad_ReadRemapFile"),
        0x21D7: ("Disk_WindowEnd", "end of that window (32-bit); clamped to start + the file size", "DiskApi_ReadFileToWindow"),
        0x2725: ("Disk_ContentType", "the SAVE / LOAD content type, 0 ALL .. 8 DRUM MAP", "prom_b DL_F583F0 draws it from DLText_F585AD; DiskLoad_ByContentType"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-disk-and-file-menus.md", "2026-10-04: the extensions a WSA1 disk DOES carry (content types 6-8)", {
        0x5210: ("SoundRemap_Ram", "the SOUND RE-MAP block, 0x650 bytes (0x230 used by a non-'1' file)", "DiskLoad_SoundRemap / DiskSave_SoundRemap; SoundRemap_ResetToDefault"),
        0x5860: ("CombiRemap_Ram", "the COMBI RE-MAP block, 0x650 bytes", "DiskLoad_CombiRemap / DiskSave_CombiRemap; CombiRemap_ResetToDefault"),
        0x5EB0: ("DrumMap_Ram", "the DRUM MAP block, 0x1D0 bytes", "DiskLoad_DrumMap / DiskSave_DrumMap; DrumMap_ResetToDefault"),
    }),
    ("wsa1/notes/prom_b_smf_reader.py", "WHAT IS ESTABLISHED, 2 and 4: the SMF header fields and the input cursor", {
        0x1078: ("Smf_Format", "the MThd format word (stored low byte first; 0 or 1 accepted)", "the MThd parser at 0xF6F5xx"),
        0x107A: ("Smf_TrackCount", "the MThd ntrks word", "the MThd parser"),
        0x107C: ("Smf_Division", "the MThd division word, ticks per quarter note (0 and SMPTE refused)", "the MThd parser; Smf_TicksToPpq96"),
        0x1088: ("Smf_InputCursor", "the 32-bit cursor into the 0x60A700-0x60AAFF input window", "the byte fetch at 0xF7138F"),
    }),
    ("wsa1/notes/prom_ab_read_names_2026_10_04.py", "prom_b 0xF6FD7A-0xF71369: the MIDI FILE loader's event layer", {
        0x10CC: ("Smf_RunningStatus", "the last status byte read (MIDI running status)", "SmfEvent_ReadWithNewStatus / _ReadWithRunningStatus"),
        0x10D0: ("Smf_EventStatus", "the event being stored: status; data bytes at +1 and +2", "SmfEvent_DispatchChannelMessage"),
        0x1193: ("Smf_VlqBytes", "the raw bytes of a variable-length quantity", "Smf_ReadVlqBytes"),
        0x1198: ("Smf_VlqValue", "its decoded 24-bit value (0x1198..0x119A)", "Smf_DecodeVlq"),
    }),
    ("wsa1/notes/prom_ab_read_names_2026_10_04.py", "CompareKey_CombiEdit / CombiEdit_CompareOn / _CompareOff (2026-10-04)", {
        0x277F: ("CombiEdit_Comparing", "1 while COMBINATION EDIT compares (the COMPARE key toggles it)", "CombiEdit_CompareOn sets it, CombiEdit_CompareOff clears it"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-seqbuf-and-timed-events.md", "2. The MIDI-in rings", {
        0x600C1E: ("MidiIn_PortARing", "MIDI port A's received-byte ring (0x400)", "MidiIn_PumpPortA, MidiIn_RoutePortA"),
        0x601028: ("MidiIn_PortBRing", "MIDI port B's received-byte ring (0x400)", "MidiIn_PumpPortB, MidiIn_RoutePortB"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-part-masks-and-event-shadows.md", "1. The part masks; 2. The sequencer-event shadows", {
        0x60F280: ("ParamMsg_PartMask_PitchBend", "parts receiving B1 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2AC: ("ParamMsg_PartMaskPrev_PitchBend", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F284: ("ParamMsg_PartMask_Modulation", "parts receiving B2 CC01 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2B0: ("ParamMsg_PartMaskPrev_Modulation", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F288: ("ParamMsg_PartMask_Modulation2", "parts receiving BC CC02 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2B4: ("ParamMsg_PartMaskPrev_Modulation2", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F28C: ("ParamMsg_PartMask_ChannelPressure", "parts receiving B4 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2B8: ("ParamMsg_PartMaskPrev_ChannelPressure", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F290: ("ParamMsg_PartMask_CtrlPedal", "parts receiving BD CC04 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2BC: ("ParamMsg_PartMaskPrev_CtrlPedal", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F294: ("ParamMsg_PartMask_Hold", "parts receiving B5 CC40 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2C0: ("ParamMsg_PartMaskPrev_Hold", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F298: ("ParamMsg_PartMask_RTCreatX", "parts receiving B8 CC10 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2C4: ("ParamMsg_PartMaskPrev_RTCreatX", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F29C: ("ParamMsg_PartMask_RTCreatY", "parts receiving B9 CC11 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2C8: ("ParamMsg_PartMaskPrev_RTCreatY", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F2A0: ("ParamMsg_PartMask_RTCtrlX", "parts receiving BA CC12 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2CC: ("ParamMsg_PartMaskPrev_RTCtrlX", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F2A4: ("ParamMsg_PartMask_RTCtrlY", "parts receiving BB CC13 (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2D0: ("ParamMsg_PartMaskPrev_RTCtrlY", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F2A8: ("ParamMsg_PartMask_Expression", "parts receiving B3 CC0B (32-bit)", "ParamMsg_ComputePartMasks, ParamMsg_ResyncParts_*"),
        0x60F2D4: ("ParamMsg_PartMaskPrev_Expression", "the same mask before the last ComputePartMasks", "ParamMsg_ResyncParts_*"),
        0x60F630: ("SeqEvt_PressureShadow", "per event slot: channel pressure, flushed as 0xB4; bit 7 = pending", "SeqEvt_ShadowChanPressure / _PostChanPressure"),
        0x60F5B0: ("SeqEvt_ModulationShadow", "per event slot: modulation, flushed as 0xB2; bit 7 = pending", "SeqEvt_ShadowModulation / _PostModulation"),
        0x60F5D0: ("SeqEvt_PitchBendShadow", "per event slot: pitch bend, 16-bit per slot, flushed as 0xB1; bit 7 = pending", "SeqEvt_ShadowPitchBend / _PostPitchBend"),
        0x60F590: ("SeqEvt_ExpressionShadow", "per event slot: expression, flushed as 0xB3; bit 7 = pending", "SeqEvt_ShadowExpression"),
        0x60F610: ("SeqEvt_VolumeShadow", "per event slot: part volume, flushed as {part,3}; bit 7 = pending", "SeqEvt_ShadowPartVolume / _PostPartVolume"),
    }),
    ("wsa1/notes/FINDINGS-prom_ab-screen-stage-and-flags.md", "1. UI_ScreenStage; 2. UI_ScreenFlags", {
        0x207E: ("UI_ScreenStage", "the page of the current screen; job screens: 0 = parameters, 1 = \"Are You Sure ?\"", "25 cp 0 / jr nz with the question on the non-zero side; 14 two-press execute keys"),
        0x2095: ("UI_ScreenFlags", "bit 4 = repaint in place, bit 0 = request allowed past the lock, bit 1 = keep (0x20A2)", "PanelState_SyncScreenFlags, PanelState_CheckRequestAllowed, PanelScreen_ApplyRequest"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-panel-mode-group-and-screen-hold.md", "1. PanelModeGroup; 2. The screen hold timer", {
        0x2076: ("PanelModeGroup", "PanelMode folded by the map at 0xF86E81 (modes 3-7 -> 3; 0, 1, 0x11, 0x18-0x1F -> 1)", "PanelMode_ToGroup"),
        0x2077: ("PanelModeGroup_Previous", "PanelModeGroup at the previous pass; 0xFF after PanelState_Init", "PanelState_LatchPrevious, PanelState_Init"),
        0x2073: ("UI_ScreenHoldTimer", "countdown; at 0 raises UI_Request_Hi bit 2 (drop the requested screen); 0x70 per request", "PanelTimer_ScreenHold, PanelScreen_ApplyRequest"),
        0x209A: ("UI_ScreenHoldPending", "one-shot preload for UI_ScreenHoldTimer (1 from 32 handlers, 0xFF / 0x3F from the splash)", "PanelState_TakePendingHoldTime"),
        0x2092: ("UI_ScreenHoldState", "bit 0 = UI_ScreenHoldTimer running this pass, bit 1 = it stopped this pass", "PanelState_UpdateScreenHoldState"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-panel-event-flags.md", "The two bytes", {
        0x28B0: ("PanelEvent_Flags", "flags of the panel event being handled: bit 0 = pair position, bit 1 = in (0x208C), bit 2 = rewritten code, bit 5 = number pad", "PanelCode_ToSlotAndFlags"),
        0x28B1: ("PanelEvent_ButtonCode", "the 5-bit panel button code of that event", "PanelCode_ToSlotAndFlags"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-panel-button-state.md", "1. The held-button state; 2. The hold timer", {
        0x2088: ("PanelButton_HeldMask", "32-bit; bit i = button i is down", "PanelButton_Accept, PanelButton_SweepHeld, PanelTimers_Step"),
        0x2084: ("PanelButton_HeldPairPos", "32-bit; bit i = button i was pressed in pair position 1", "PanelButton_Accept, PanelButton_SweepHeld"),
        0x2082: ("PanelButton_Current", "the button code to route, | 0x80 = pair position", "PanelButton_DispatchCurrent"),
        0x2074: ("PanelButton_RepeatTimer", "ticks to the next auto-repeat: 0x10 first, then 3", "PanelButton_Accept, PanelButton_Dispatch, PanelTimer_ButtonRepeat"),
        0x20A7: ("PanelHold_Timer", "ticks before a held event requests its screen (0x40 / 0x30)", "PanelEvent_Code01/20_ArmHold, PanelHold_Tick"),
        0x2096: ("PanelHold_Index", "16-bit index into PanelHold_ScreenRequest", "PanelHold_Tick"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-midi-parser-state.md", "the state bytes of the two MIDI parsers", {
        0x009A: ("MIDI_RX_RunningStatus", "the interrupt-time parser's running status", "the 0xFA5942 banner; MIDI_RX_Byte"),
        0x009E: ("MIDI_RX_Flags", "its flags; bit 6 = first data byte pending (cleared with bit 1 by and 0xBD)", "the 0xFA5942 banner"),
        0x00A9: ("MIDI_RX_SysExState", "its SysEx state", "the 0xFA5942 banner; MIDI_RX_SysEx*"),
        0x0960: ("MIDI_Fg_RunningStatus", "the foreground consumer's running status", "the 0xFA5942 banner"),
        0x0961: ("MIDI_Fg_FirstData", "the first data byte of a pending two-byte message", "MIDI_Fg_StashFirstData"),
        0x0963: ("MIDI_Fg_Flags", "bit 6 = first data byte pending", "MIDI_Fg_StashFirstData, MIDI_Fg_DataByte"),
        0x0964: ("MIDI_Fg_SysExState", "bit 0 = SysEx open, bit 1 = system-common gate; 4 = closed, 0 = abandoned", "MIDI_DrainQueue__status, MIDI_Fg_SysExData"),
        0x0931: ("MIDI_RX_ErrorCount", "8-bit receive-error counter", "MIDI_RX_ErrorReset"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-midi-in-routing-and-small-cells.md", "1. The staged MIDI-in message and its routing", {
        0x1940: ("MidiIn_MsgStatus", "the staged message's status byte", "MidiIn_FetchMessage_PortA/B"),
        0x1941: ("MidiIn_MsgData1", "its first data byte", "MidiIn_FetchMessage_PortA/B; MidiIn_ControlChange"),
        0x1942: ("MidiIn_MsgData2", "its second data byte", "MidiIn_FetchMessage_PortA/B; MidiIn_ControlChange"),
        0x1943: ("MidiIn_MsgPortTag", "0x00 port A, 0x10 port B", "MidiIn_FetchMessage_PortA/B"),
        0x1974: ("MidiIn_RouteCursor", "offset into the part list at 0x1820", "MidiIn_RouteChannelMessage"),
        0x1975: ("MidiIn_RouteCount", "the part list's count", "MidiIn_RouteChannelMessage"),
        0x1976: ("MidiIn_CurrentPart", "the part the message is applied to", "MidiIn_RouteChannelMessage; MidiIn_CC*_ParamTable readers"),
        0x1977: ("MidiIn_RouteRemaining", "parts left in the list", "MidiIn_RouteChannelMessage"),
        0x197E: ("MidiIn_ChannelTag", "channel | port tag, 0..0x1F", "MidiIn_RouteChannelMessage"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-midi-in-routing-and-small-cells.md", "2. Five more cells", {
        0x60F018: ("IndexedTable_Base", "32-bit base of the pointer table IndexedTable_GetPtr indexes", "FINDINGS-prom_b-thunk-table.md"),
        0x20C8: ("EditValue_Max", "ceiling, signed 16-bit", "EditValue_ApplyStep"),
        0x20CA: ("EditValue_Min", "floor, signed 16-bit", "EditValue_ApplyStep"),
        0x20CC: ("EditValue_Value", "the value a step is applied to", "EditValue_ApplyStep"),
        0x20CE: ("EditValue_Step", "the step", "EditValue_ApplyStep, EditStep_Lookup"),
        0x259A: ("LCD_TextCharsLeft", "characters left to draw", "the packed-text services"),
        0x259F: ("LCD_TextGlyphPtr", "32-bit pointer to the current glyph's bitmap", "the packed-text services; TextShift_LoadGlyph8/16"),
        0x0932: ("MIDI_RX_OverflowCount", "8-bit count of input-queue overflows", "the MIDI_RX banner"),
    }),
    ("wsa1/notes/FINDINGS-prom_a-midi-in-routing-and-small-cells.md", "3. The rest of the MIDI_RX banner's RAM list", {
        **{0x0900 + 4 * k: ("MIDI_Parser_Saved" + r, "the interrupt parser's saved " + r + " between interrupts",
                            "MIDI_Parser_LoadContext / _SaveContext / _ClearContext")
           for k, r in enumerate(["XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ"])},
        0x216F: ("MIDI_ActivityFlags", "bit 0 set on every MIDI byte actually delivered", "the MIDI_RX banner; PanelLed_RequestIfBlinkEnableChanged"),
    }),
    ("wsa1/notes/FINDINGS-prom_ab-display-list-b-stage.md", "the display-list-B staging block", {
        0x12F6 + k: ("DisplayListB_Stage" + ("+%d" % k if k else ""),
                     "27 bytes the screens stage for interpreter-B display-list records; meaning per screen",
                     "every byte is a `+0x02 source variable`; 363 code stores, 1 code read")
        for k in range(27)
    }),
    ("wsa1/notes/FINDINGS-prom_ab-draw-scratch.md", "the 32-byte draw scratch", {
        0x2640 + k: ("UI_DrawScratch" + ("+%d" % k if k else ""),
                     "32 bytes each screen fills with what it is about to draw (tags, names, effect parameters)",
                     "188 display-list records read it; 137 code stores")
        for k in range(32)
    }),
    ("wsa1/notes/FINDINGS-prom_b-dsp-effect-parameters.md", "2. the descriptor table at 0xF12F24 is indexed by the effect algorithm number", {
        0x2796: ("Effect_Algorithm", "the effect algorithm number, 0..127: indexes the 128-entry tables at 0xF12F24 ...", "0xF10609 mul WA,(0x2796) / add XWA,0x00F12F24"),
    }),
    ("wsa1/notes/FINDINGS-prom_b-dsp-effect-parameters.md", "7.1 `DspEffect_Section` (0x2790)", {
        0x2790: ("DspEffect_Section", "the DSP EFFECT screen's section, 0..5: 0 no block opened, 1..3 block 0..2's parameters, 4 / 5 block 0 / 2's EQ",
                 "every DSP EFFECT key handler switches on it (cp BC,5 / jp table); EffectPage_BlockIndex maps it to the block"),
    }),
]
NAMES = {a: v for _, _, g in GROUPS for a, v in g.items()}
MEM = re.compile(r'\((0x[0-9a-fA-F]+|\d+)(:8|:16|:24)?\)')   # :8 -- the direct page, `cp (0xc4:8), 2`
MAC = re.compile(r'\b(MB8|MW8|MD8|ML8|MB16|MW16|MD16|ML16|MB24|MW24|MD24|ML24),(\s*)(0x[0-9a-fA-F]+|\d+)\b')   # ML: the 32-bit-operand prefix
# an interpreter-B display-list record's +0x02 field is the 16-bit address of the RAM variable it
# draws (wsa1/notes/FINDINGS-ui-display-list-interpreter-b.md): `.short 0x27A7\t; +0x02 source variable`
SRCVAR = re.compile(r'^(\s*\.short\s+)(0x[0-9a-fA-F]+|\d+)(\s*;\s*\+0x02 source variable.*)$')
# an indexed operand whose displacement is a named address -- `ld (XBC+0x27a6),A`, element XBC of the
# array there; same encoding (d16) with the absolute symbol
IDX = re.compile(r'\((x[a-z]{2})\s*\+\s*(0x[0-9a-fA-F]{3,}|\d{3,})\)', re.I)
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


def _write(path, data):
    # encode before opening, and replace atomically: `open(p, "wb").write(x.encode())` truncates
    # the file first and leaves it empty if the encode raises (it emptied wsa1_prom_a.s 2026-10-03)
    tmp = path + ".tmp-name_wsa1_ram"
    with open(tmp, "wb") as fh:
        fh.write(data)
    os.replace(tmp, path)


def clashes():
    """Names in GROUPS that some source already defines as a label, .set or .equ.  The assembler
    takes the duplicate without an error: 2026-10-03 the RAM name SeqEvt_ShadowModulation (0x60F5B0)
    replaced the code label of the same name in a 4-entry jump table, 36 bytes off in prom_a."""
    defined = {}
    for f in SOURCES:
        p = f if os.path.isabs(f) else os.path.join(REPO, f)
        for k, l in enumerate(open(p, "rb").read().decode("latin-1").split("\n")):
            m = re.match(r'^([A-Za-z_.$][\w.$]*):', l) or \
                re.match(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$]*)\s*,', l)
            if m:
                defined.setdefault(m.group(1), "%s:%d" % (os.path.relpath(p, REPO), k + 1))
    return sorted((n.split("+")[0], defined[n.split("+")[0]]) for n, _, _ in NAMES.values()
                  if n.split("+")[0] in defined)


def main():
    clash = clashes()
    if clash:
        for n, where in clash:
            print("name already defined in the source: %s (%s)" % (n, where))
        return 2
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
                # a data directive is a value, also after a label: `Draw_..._Data:\t.short\t0x0910` is a
                # KeyValueList key, not MIDI_Parser_SavedXIX (2026-10-03)
                if not code.strip() or re.sub(r'^[\w.$]+:\s*', '', code.strip()).startswith("."):
                    continue
                for m in re.finditer(r'(0x[0-9a-fA-F]+|\b\d+\b)', code):
                    v = int(m.group(1), 0)
                    # a named address >= 0x100 is flagged anywhere; below 0x100 (0x80, 0xC4), and an
                    # array element (`Name+n`: 0x0FFF / 0x1000 are masks and sizes), the number is a
                    # common VALUE, so only in an address position: `(N...)` or the address argument
                    # of an 8/16/24-bit macro kind
                    addr_pos = code[:m.start()].rstrip().endswith("(") or \
                        re.search(r'\bM[BWDL](?:8|16|24),\s*$', code[:m.start()])
                    if v in NAMES and ((v >= 0x100 and "+" not in NAMES[v][0]) or addr_pos):
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
            sv = SRCVAR.match(l)
            if sv and int(sv.group(2), 0) in NAMES:
                L[i] = sv.group(1) + NAMES[int(sv.group(2), 0)][0] + sv.group(3)
                n += 1
                continue
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
                # an element of an array (`Name+n`) is never taken from a 16-bit register immediate:
                # `ldw bc, 0x1000` in prom_a is a size, not MsgLine_Text+28 (2026-10-03)
                wide = re.match(r'\s*(?:ld|ldw|lda)\s+x', m.group(1), re.I)
                ok = v in NAMES and v >= 0x100 and ("+" not in NAMES[v][0] or wide)
                return m.group(1) + NAMES[v][0] + m.group(3) if ok else m.group(0)

            def idx(m):
                v = int(m.group(2), 0)
                return "(%s+%s)" % (m.group(1), NAMES[v][0]) if v in NAMES and v >= 0x100 else m.group(0)

            orig = code
            n += len([1 for x in IDX.finditer(code) if int(x.group(2), 0) in NAMES and int(x.group(2), 0) >= 0x100])
            code = IDX.sub(idx, code)
            stage = MAC.sub(mac, MEM.sub(mem, code))
            stage2 = IMM.sub(imm, stage)
            new = REGIMM.sub(regimm, MM.sub(mm, stage2))
            if new != orig:
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
            _write(p, "\n".join(L).encode("latin-1"))
        print("%-45s %4d operands" % (os.path.relpath(p, REPO), n))
        total += n
    print("%d operands%s" % (total, "" if a.apply else " (dry run)"))
    if a.apply:
        _write(os.path.join(REPO, INC), inc_text().encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
