#!/usr/bin/env python3
"""Emit the annotated assembly for prom_a's floppy-disk-controller module.

QUESTION IT ANSWERS
    "What text goes into prom_a/wsa1_prom_a.s for 0xFE54EC-0xFE594B,
     0xFE5A41-0xFE6850 and the four jump tables at 0xFE6E3A-0xFE6E83?"

HOW IT IS SAFE
    The instruction text is not written here.  It comes from
    prom_a/roundtrip.py --block, which assembles every candidate spelling and
    byte-compares it against the ROM before printing, and re-assembles the
    labelled block as a whole.  This script only adds NAMES and COMMENTS on top
    of that text, and the byte gate re-checks the result.

    The "Called from:" line of every header is COMPUTED, by
    notes/prom_a_fdc_callgraph.py, from an instruction-anchored scan of the
    module -- it is not typed in.  That is deliberate: hand-written call-site
    lines are the single thing this tree has had to retract most often.

RUN
    python3 notes/gen_prom_a_fdc_module.py --out-dir /tmp/frag
      writes frag/fdc_span1.s, frag/fdc_span2.s, frag/fdc_tables.s and
      frag/fdc_labels.txt, then splice them with prom_a/insert_region.py:
        python3 prom_a/insert_region.py 0xFE54EC 0xFE594C /tmp/frag/fdc_span1.s
        python3 prom_a/insert_region.py 0xFE5A41 0xFE6851 /tmp/frag/fdc_span2.s
        python3 prom_a/insert_region.py 0xFE6E3A 0xFE6E84 /tmp/frag/fdc_tables.s
      and run scripts/analysis/assert_byte_identical.py.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF80000

SPAN1 = (0xFE54EC, 0xFE594C)
SPAN2 = (0xFE5A41, 0xFE6851)
TABLES = (0xFE6E3A, 0xFE6E84)

# --------------------------------------------------------------------------
# The names.  addr -> (label, header text).  "{CALLED}" in a header is replaced
# by the computed caller list.  A bare label (no header) is a local entry point
# inside a routine that another routine jumps straight into.
# --------------------------------------------------------------------------
MODULE_BANNER = """
; ==============================================================================
; 0xFE54EC-0xFE594B and 0xFE5A41-0xFE6850 -- the FLOPPY DISK CONTROLLER driver
; ==============================================================================
;
; ★★ THIS NAMES THE DEVICE AT 0x7B0004/0x7B0005 AND 0x7A0000.  It is a
; uPD765-family floppy disk controller: 0x7B0004 read is the MAIN STATUS
; REGISTER, 0x7B0004 written is a control register, 0x7B0005 is the DATA
; register, and 0x7A0000 is the same data register reached on the micro-DMA
; path.  notes/FINDINGS-dev7b-and-int5.md said "⚠ What the device IS has not
; been established ... Do not name it"; that sentence is now WITHDRAWN and the
; note is corrected.  The evidence is in notes/FINDINGS-prom_a-fdc.md and every
; number in it is re-derived by notes/prom_a_fdc_checks.py.  In one line:
;
;   the opcode validator at 0xFE5CE8 accepts a set of 15 command opcodes and
;   rejects the other 17, and that 32-value truth table is EXACTLY the one
;   MAME's own uPD765 command decoder implements
;   (../mame/src/devices/machine/upd765.cpp:1433-1478).
;
; Everything else agrees with it and none of it had to be assumed:
;
;   * the command-phase encoder at 0xFE5C0A emits, per opcode, exactly the
;     parameter bytes the uPD765 command takes -- 1 byte for SENSE INTERRUPT
;     STATUS (0x08), 2 for SPECIFY (0x03), 2 for RECALIBRATE / SENSE DRIVE
;     STATUS / READ ID, 2 for SEEK, 5 for FORMAT TRACK (0x4D), 8 for the
;     READ/WRITE family, and for the three SCAN opcodes it substitutes STP for
;     the final DTL byte, which is the one place the uPD765 command set differs;
;   * SPECIFY's two bytes are built as (SRT<<4)|HUT and (HLT<<1)|ND at 0xFE5D41;
;   * the drive byte is built as (HD<<2)|US at 0xFE5C73;
;   * the FORMAT TRACK filler byte is 0xE5 (0xFE639C);
;   * the result-phase classifier at 0xFE5B5E reads the IC field as
;     `ST0 & 0xC0` and then tests ST0 bits 3 and 4 and ST1 bits 0,1,2,4,5,7 --
;     which is ST0_NR, ST0_EC and ALL SIX defined ST1 bits and neither of the
;     two undefined ones (../mame/src/devices/machine/upd765.h:82-95);
;   * SENSE DRIVE STATUS's handler at 0xFE6668 tests ST3 bits 7, 5 and 6 --
;     ST3_FT, ST3_RY and ST3_WP -- and raises the SAME three error codes the
;     ST0/ST1 decoder raises for the same physical conditions;
;   * every wait loop masks the status byte with a union of the defined MSR
;     fields: 0x1F = CB|DB, 0x90 = RQM|CB, 0xE0 = RQM|DIO|EXM, and `res 4,A`
;     clears CB;
;   * 0xFE57FF programmes three complete disk geometries whose (N, SC, GPL,
;     GPL-format, cylinders) tuples are the textbook 720 KB / 1.2 MB / 1.44 MB
;     parameter sets.
;
; kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md (gap B) records that this
; machine has a uPD72070 floppy controller and a disk drive; that is consistent
; with everything here, and it is a statement from the emulation lane, NOT
; something this ROM says -- nothing in either image names a part.  Note also
; that the driver's validator implements the BASE uPD765 opcode map, not the
; enhanced one: see
; Fdc_IssueCommand's header for the CONFIGURE (0x13) arm that its own validator
; makes unreachable.  ⚠ The exact PART is not established from the ROM; what is
; established is the register-level protocol.
;
; SHAPE OF THE MODULE
;   Fdc_Request (0xFE66C7) is the only public entry.  It takes a 16-byte request
;   block, copies it to (0x605A30) and (0x605A40), and dispatches on its first
;   word through a 12-entry table.  Unit number (request+2) selects the BACK
;   END: unit 0 is this controller, unit 1 is a second block device whose driver
;   lives at 0xFE4CE0-0xFE544D and talks to the 16-bit port at 0x7E0008 (see
;   Fdc_Request's header).  Interrupt-side: INT5 (0xFE6866) collects the result
;   phase, INTTC0 (0xFE6851) ends a micro-DMA burst, and Fdc_ServiceDataByte
;   (0xFE67F9) is the programmed-I/O alternative to that burst.
;
; THE RAM BLOCK, 0x605A00-0x605B09.  Field-by-field layouts are in the headers
; of the routines that establish them: the 0x18-byte COMMAND BLOCK at 0x605A18
; (Fdc_SendSectorIdParams and Fdc_SelectFormatParameters), the 16-byte REQUEST
; BLOCK at 0x605A30 (Fdc_Request), and the RESULT BUFFER at 0x605A50
; (Fdc_ClassifyResultStatus).
;
; ⚠ NOT ESTABLISHED, listed so nothing below quietly assumes it:
;   * which bit of the byte written to 0x7B0004 does what.  The driver writes
;     0x80, 0x02 and 0x00 there and shadows the value because the register does
;     not read back (Dev7B_WriteControl_Shadowed);
;   * what PA bit 3 -- set by operation 7, cleared by operation 6 -- drives;
;   * what (0x605A59) and (0x605AEC) are for: both are written and NEVER read,
;     anywhere in prom_a or prom_b (notes/prom_a_addr_census.py 0x605A59 finds
;     3 writes and 0 reads; 0x605AEC finds 2 writes and 0 reads);
;   * what the second copy of the request block at 0x605A40 is for.
; ==============================================================================
"""

R = {}


def routine(addr, label, header=None):
    R[addr] = (label, header)


# ---- span 1 --------------------------------------------------------------
routine(0xFE54EC, "Fdc_WaitControllerIdle", """
; ---------------------------------------------------------------------
; Fdc_WaitControllerIdle -- spin until MSR says no command is in progress
;
; Called from: {CALLED}
; Inputs:  none.
; Outputs: nothing; on timeout it calls Fdc_SetError(0x01).  IZ preserved.
; Evidence: it reads 0x7B0004 through Dev7B_ReadStatus and succeeds when
;          `status & 0x1F` is zero.  0x1F is MSR_CB | MSR_DB
;          (../mame/src/devices/machine/upd765.h:76-77), i.e. the controller
;          is not busy and no drive is seeking.  The timeout is 500 counts of
;          (0x605A00), the INTT1 tick that notes/FINDINGS-dev7b-and-int5.md
;          shows has exactly one writer; at the 488.28 Hz of
;          notes/FINDINGS-system-clock.md that is 1.024 s.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5533, "Fdc_WaitRqmAndCommandBusy", """
; ---------------------------------------------------------------------
; Fdc_WaitRqmAndCommandBusy -- spin until the FDC wants another byte of the
; command it is already executing
;
; Called from: {CALLED}
; Inputs:  none.
; Outputs: nothing; Fdc_SetError(0x01) on timeout.
; Evidence: succeeds when `status & 0x90 == 0x90`.  0x90 is MSR_RQM | MSR_CB
;          (upd765.h:77,80) -- a byte is requested AND a command is in
;          progress, which is exactly the parameter-phase condition.  Same
;          500-tick timeout as Fdc_WaitControllerIdle.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5576, "Fdc_PulseControlReset", """
; ---------------------------------------------------------------------
; Fdc_PulseControlReset -- write 0x80 to the control register, settle, and
; declare the medium unknown
;
; Called from: {CALLED}
; Inputs:  none.
; Outputs: control register := 0x80 (through Dev7B_WriteControl_Shadowed, so
;          (0x605B08)/(0x605B09) follow it); (0x605AEE) := 0xFF.
; Evidence: (0x605AEE) is the cylinder the head is known to be on --
;          Fdc_Op2_SeekToCylinder skips the SEEK when the wanted cylinder
;          already equals it and sets it to 0xFF whenever a seek fails, so
;          0xFF means "position unknown".  Writing it here is what makes this
;          a reset rather than an ordinary control write.
; Unknown:  ⚠ WHICH BIT of 0x80 resets the part is not established.  What is
;          established is that this write is followed by the SENSE INTERRUPT
;          STATUS / SPECIFY sequence a uPD765 needs after a reset -- see
;          Fdc_ResetAndIdentifyMedia.
; ---------------------------------------------------------------------""")
routine(0xFE558B, "Fdc_ResetAndIdentifyMedia", """
; ---------------------------------------------------------------------
; Fdc_ResetAndIdentifyMedia -- reset the controller, drain the four SENSE
; INTERRUPT STATUS results, and choose the disk geometry
;
; Called from: {CALLED}
; Inputs:  the request block at 0x605A30; (0x605A5B), the media descriptor
;          byte, whose LOW NIBBLE selects the geometry.
; Outputs: (0x605A5A) := the geometry index 0..5; (0x605A12) := 0; the
;          controller left specified and recalibrated.
; Evidence: the sequence is the textbook uPD765 post-reset one.  After the
;          control write it loops: wait for MSR_RQM; if MSR_DIO is clear, spin
;          until `status & 0xF0 == 0x80` and write 0x08 to the DATA register --
;          0x08 is SENSE INTERRUPT STATUS, the one command whose opcode this
;          driver hard-codes rather than routing through Fdc_IssueCommand
;          (upd765.cpp:1442-1443) -- then read the two result bytes into
;          0x605A51.., classify them, and repeat until the first result byte
;          is 0x80.  0x80 in ST0's IC field is "invalid command", which is what
;          a uPD765 answers to the FIFTH SENSE INTERRUPT STATUS after a reset:
;          that is the standard way of draining the four pending drive-change
;          interrupts, and the loop terminating on it is why nothing here has
;          to know how many drives exist.  It then issues 0x13 and 0x03
;          (see Fdc_IssueCommand for what happens to 0x13) and dispatches the
;          media nibble through Fdc_MediaTypeJumpTable.
; Unknown:  what (0x605A13), set to 0 in every arm, is read by.
; ---------------------------------------------------------------------""")
routine(0xFE56D7, "Fdc_Op10_TestControllerPresent", """
; ---------------------------------------------------------------------
; Fdc_Op10_TestControllerPresent -- operation 10: is a controller there at all?
;
; Called from: {CALLED}  (and Fdc_OperationJumpTable entry 10)
; Inputs:  (0x605A32), the unit number.
; Outputs: HL = 0 if present, 0x00FC if not, and Fdc_SetError(0xFC) in that case.
; Evidence: for unit 0 it writes 0x80 to the control register, waits one tick
;          and reads the MAIN STATUS REGISTER; an MSR that reads 0xFF is a
;          floating bus, which is what an absent or unselected part gives.  For
;          unit 1 it delegates to 0xFE4D01 in the other back end and applies the
;          same 0x00FF test to that device's answer.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5716, "Fdc_ValidateRequest", """
; ---------------------------------------------------------------------
; Fdc_ValidateRequest -- range-check a request against the current geometry
;
; Called from: {CALLED}
; Inputs:  the request block at 0x605A30.
; Outputs: L = the error code (0 = accepted); Fdc_SetError(0xFE) on a bad field.
; Evidence: it dispatches the operation word through Fdc_ValidateJumpTable and
;          the generic arm then checks, in order: unit <= 1; track <
;          (0x605AF1), the cylinder count the geometry set; and sector <= the
;          per-geometry maximum -- 8 for geometry 2, 0x12 for geometry 3, 9 for
;          geometries 0, 4 and 5, with 0xFF additionally allowed for geometry 4.
;          Those bounds are the SC values Fdc_SelectFormatParameters wrote, so
;          the two routines are consistent by construction.
; Unknown:  why geometry 4 admits sector 0xFF.
; ---------------------------------------------------------------------""")
routine(0xFE57FF, "Fdc_SelectFormatParameters", """
; ---------------------------------------------------------------------
; Fdc_SelectFormatParameters -- fill the command block's format fields for one
; of THREE disk geometries
;
; Called from: {CALLED}
; Inputs:  (0x605A36) = request+6, the media descriptor byte.  Its low nibble
;          is the geometry index and its HIGH nibble becomes SRT.
; Outputs: (0x605A5B) := the descriptor; command block fields +6 (N), +7 (EOT),
;          +8 (GPL), +9 (DTL=0xFF), +0x0A (SC), +0x0B (GPL for FORMAT),
;          +0x0C (D=0), +0x0D (STP=1), +0x0F (SRT), +0x10 (HUT=0x0F),
;          +0x11 (HLT=1), +0x12 (ND=0), +0x13..+0x17 (=0); and the four
;          geometry words (0x605AEF) last cylinder, (0x605AF1) cylinder count,
;          (0x605AF5) sectors per track, (0x605AF7) sectors per track + 1.
; Evidence: the three arms are, verbatim from the ROM immediates,
;
;            index      N  EOT  GPL  GPLfmt  cyls  spt   capacity
;            0, 4, 5    2   9   0x1B  0x54   0x50   9    2 x 80 x  9 x  512 =  720 KB
;            2          3   8   0x53  0x74   0x4D   8    2 x 77 x  8 x 1024 = 1.2 MB
;            3          2  0x12 0x1B  0x6C   0x50  0x12  2 x 80 x 18 x  512 = 1.44 MB
;
;          Those are the three standard uPD765 parameter sets, GPL values
;          included, and the byte-per-sector code N is 2 -> 512 and 3 -> 1024.
;          notes/prom_a_fdc_checks.py re-reads all 30 immediates from the ROM.
; Unknown:  nothing here; every immediate is accounted for.
; ---------------------------------------------------------------------""")
routine(0xFE5914, "Fdc_SetHeadFromRequest", """
; ---------------------------------------------------------------------
; Fdc_SetHeadFromRequest -- copy the request's head number into the command block
;
; Called from: {CALLED}
; Inputs:  (0x605A34) = request+4.
; Outputs: command block +1 (the HD bit of the drive byte) and +4 (the H byte
;          of the sector ID) both := it; Fdc_SetError(0xFE) if it is not 0 or 1.
; Evidence: +1 is the field Fdc_IssueCommand shifts left 2 into the drive byte
;          and +4 is the field Fdc_SendSectorIdParams sends as H; a single
;          source for both is what makes the ID field agree with the head the
;          chip is told to use.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5935, "Fdc_ValidateHead_Nop", """
; ---------------------------------------------------------------------
; Fdc_ValidateHead_Nop -- a bare RET, reached from Fdc_ValidateRequest's
; operation-5 arm.  Kept as its own label because it is a distinct call target.
; Called from: {CALLED}
; ---------------------------------------------------------------------""")
routine(0xFE5936, "Fdc_ValidateHead", """
; ---------------------------------------------------------------------
; Fdc_ValidateHead -- reject a head number that is not 0 or 1
; Called from: {CALLED}
; Inputs:  (0x605A34).   Outputs: Fdc_SetError(0xFE) if out of range.
; Evidence: the same two-value test Fdc_SetHeadFromRequest makes, without the
;          stores; it is the operation-9 arm of Fdc_ValidateJumpTable.
; ---------------------------------------------------------------------""")

# ---- span 2 --------------------------------------------------------------
routine(0xFE5A41, "Fdc_WaitRqm", """
; ---------------------------------------------------------------------
; Fdc_WaitRqm -- spin until the FDC raises RQM outside an execution phase
;
; Called from: {CALLED}
; Inputs:  none.   Outputs: Fdc_SetError(0x02) on a 500-tick timeout.
; Evidence: succeeds when `status & 0xE0` is 0x80 or 0xC0.  0xE0 is
;          MSR_RQM|MSR_DIO|MSR_EXM (upd765.h:78-80), so both accepted values
;          have RQM set and EXM clear and they differ only in DIO -- i.e. "the
;          chip wants a byte, in either direction, and is not in a
;          non-DMA execution phase".
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5A8F, "Fdc_WaitReadyForCommandByte", """
; ---------------------------------------------------------------------
; Fdc_WaitReadyForCommandByte -- wait until a byte may be WRITTEN, first
; draining any result bytes the chip still holds
;
; Called from: {CALLED}
; Inputs:  none.
; Outputs: Fdc_SetError(0x03) on a 500-tick timeout; any drained bytes land in
;          the result buffer from 0x605A51 upward.
; Evidence: it reads MSR, clears MSR_CB with `res 4,A`, and compares the rest
;          against 0x80 (RQM, direction CPU->FDC: done, ready to write) and
;          0xC0 (RQM, direction FDC->CPU: the chip still has result bytes).
; Unknown:  ⚠ THE DRAIN LOOP AT 0xFE5AB7 HAS NO EXIT TEST.  It reads the DATA
;          register, stores it at 0x605A50+i, reads MSR, DISCARDS that MSR and
;          loops, unconditionally.  This is stated as read, not diagnosed: an
;          emulated MSR that ever presents RQM|DIO with EXM and CB clear at a
;          command-phase boundary will wedge CPU 1 here.
; ---------------------------------------------------------------------""")
routine(0xFE5AF8, "Fdc_SendCommandByte", """
; ---------------------------------------------------------------------
; Fdc_SendCommandByte -- Fdc_WaitReadyForCommandByte, then write the byte
; Called from: {CALLED}
; Inputs:  the byte at (XSP+0x04) -- a stack argument, caller cleans up.
; Outputs: the DATA register 0x7B0005 is written.
; Evidence: the two calls are its whole body.
; ---------------------------------------------------------------------""")
routine(0xFE5B07, "Fdc_SendParamByte", """
; ---------------------------------------------------------------------
; Fdc_SendParamByte -- Fdc_WaitRqmAndCommandBusy, then write the byte
; Called from: {CALLED}
; Inputs:  the byte at (XSP+0x04).
; Evidence: it waits on RQM|CB rather than on RQM alone, which is the
;          distinction between a command byte and a byte of a command already
;          under way; every parameter-emitting routine below uses this one.
; ---------------------------------------------------------------------""")
routine(0xFE5B16, "Fdc_WriteControlRegister", """
; ---------------------------------------------------------------------
; Fdc_WriteControlRegister -- wait, then write the CONTROL register 0x7B0004
; Called from: {CALLED}
; Inputs:  the byte at (XSP+0x04).
; Evidence: same wait as Fdc_SendCommandByte but the store goes through
;          Dev7B_WriteControl, i.e. to 0x7B0004 rather than 0x7B0005.
; ---------------------------------------------------------------------""")
routine(0xFE5B25, "Fdc_WriteControlRegister_IfNoError", """
; ---------------------------------------------------------------------
; Fdc_WriteControlRegister_IfNoError -- as above, skipped when (0x605A15) is set
; Called from: {CALLED}.  ⚠ NO CALLER HAS BEEN FOUND: neither inside the module
;          nor in any converted prom_a code, and `python3 notes/prom_a_xref.py
;          0xFE5B25` finds no absolute reference either.  It is reached, if at
;          all, from code that is still `.incbin`.  Recorded as a searched
;          negative with the searches named, not as "unused".
; ---------------------------------------------------------------------""")
routine(0xFE5B3C, "Fdc_WriteControlRegister_AndReadResult", """
; ---------------------------------------------------------------------
; Fdc_WriteControlRegister_AndReadResult -- control write, then take one byte
; Called from: {CALLED}.  ⚠ Same searched negative as
;          Fdc_WriteControlRegister_IfNoError above.
; Outputs: (0x605A51) := one byte read from the DATA register after
;          Dev7B_WaitStatus_8x_Cx reports the chip has one.
; ---------------------------------------------------------------------""")
routine(0xFE5B5E, "Fdc_ClassifyResultStatus", """
; ---------------------------------------------------------------------
; Fdc_ClassifyResultStatus -- turn ST0/ST1 in the result buffer into an error code
;
; Called from: {CALLED}
; Inputs:  the RESULT BUFFER at 0x605A50:
;            +0x00  sentinel: 0xFF = no result yet (Fdc_MarkResultPending),
;                   cleared by INT5_Dev7B_Receive when a packet has arrived
;            +0x01  ST0        +0x02  ST1        +0x03..  the rest, unread here
; Outputs: L = 0, or 8 for a status this routine cannot classify; the specific
;          faults are reported through Fdc_SetError instead.
; Evidence: this is the decisive routine for naming the device.  It reads
;          `ST0 & 0xC0` -- the IC field -- and branches on 0x40 (abnormal
;          termination) into the fault decode, on 0x80 (invalid command) and
;          0x00 (normal) into a plain return, and on 0xC0 sets the media-change
;          flag (0x605AEC).  In the fault decode it tests exactly these bits:
;
;            ST0 bit 3  ST0_NR  not ready        -> error 0x31
;            ST0 bit 4  ST0_EC  equipment check  -> error 0x32
;            ST1 bit 0  ST1_MA  missing addr mark-> error 0x35
;            ST1 bit 1  ST1_NW  not writable     -> error 0x2F
;            ST1 bit 2  ST1_ND  no data          -> error 0x33
;            ST1 bit 4  ST1_OR  overrun          -> error 0x34
;            ST1 bit 5  ST1_DE  data error       -> error 0x36
;            ST1 bit 7  ST1_EN  end of cylinder  -> error 0x37
;
;          Those are ALL SIX defined ST1 bits and NEITHER of the two undefined
;          ones, and the two ST0 bits, exactly as named in
;          ../mame/src/devices/machine/upd765.h:82-95.
; Unknown:  who reads (0x605AEC).  Nothing does: notes/prom_a_addr_census.py
;          0x605AEC finds two writes and no read in prom_a + prom_b.
; ---------------------------------------------------------------------""")
routine(0xFE5C00, "Fdc_ClassifyResultStatus__unclassified")
routine(0xFE5C03, "Fdc_EnableInterrupts", """
; ---------------------------------------------------------------------
; Fdc_EnableInterrupts -- arm INT5 and INTTC0 in the CPU
; Called from: {CALLED}
; Outputs: INTE45 (SFR 0x71) := 0x40, INTETC01 (SFR 0x79) := 0x05.
; Evidence: register names from ../mame/src/devices/cpu/tlcs900/tmp95c061.cpp
;          :1386,1389.  0x40 gives INT5 priority 4 and leaves INT4 masked;
;          0x05 gives INTTC0 priority 5 and leaves INTTC1 masked.  INT5 is the
;          result-phase interrupt (INT5_Dev7B_Receive) and INTTC0 is micro-DMA
;          channel 0's end-of-count (INTTC0_uDMA0Done) -- the module's own two
;          interrupts and no others.
; ---------------------------------------------------------------------""")
routine(0xFE5C0A, "Fdc_IssueCommand", """
; ---------------------------------------------------------------------
; Fdc_IssueCommand -- the COMMAND PHASE: send one opcode and exactly the
; parameter bytes that opcode takes
;
; Called from: {CALLED}
; Inputs:  the opcode as a word at (XSP+0x04) on entry; the command block at
;          0x605A18 supplies every parameter.
; Outputs: (0x605A18) := the opcode; the chip has the whole command; errors via
;          Fdc_SetError.  Returns with the stack frame it opened closed.
; Evidence: the per-opcode arms are what make the parameter layout of the
;          command block readable, and each matches the uPD765 command it names:
;
;            0x08          nothing more                 SENSE INTERRUPT STATUS
;            0x03          Fdc_SendSpecifyParams        SPECIFY, 2 bytes, and
;                          NO drive byte -- SPECIFY is the one command that has
;                          none, and this arm is taken BEFORE the drive byte is
;                          built, which is how the ROM says so
;            0x0F          drive byte + NCN             SEEK
;            0x4D          drive byte + N, SC, GPL, D   FORMAT TRACK
;            0x07/0x04/0x4A  drive byte only            RECALIBRATE / SENSE
;                                                       DRIVE STATUS / READ ID
;            otherwise     drive byte + C,H,R,N,EOT,GPL and then DTL, except
;                          for opcodes 0xDD/0xD9/0xD1 -- the three SCAN
;                          commands -- where STP is sent instead
;
;          The drive byte itself is built at 0xFE5C73 as
;          ((command+1) & 1) << 2 | ((command+2) & 3), i.e. (HD<<2)|US1|US0.
; Unknown:  ⚠ THE 0x13 ARM IS UNREACHABLE.  The routine classifies the opcode
;          first (Fdc_ClassifyCommandOpcode) and returns immediately when the
;          answer is "invalid"; 0x13 & 0x1F = 0x13 is one of the 17 values that
;          classifier rejects.  So the three bytes 0x00, 0x0C, 0xFF that the
;          0x13 arm would send -- which are a well-formed uPD765-family
;          CONFIGURE payload -- are never sent, and Fdc_ResetAndIdentifyMedia's
;          `push 0x13` call does nothing.  Reported as read: this note does not
;          claim it is a defect, only that the controller is never CONFIGUREd
;          and therefore runs in its power-on mode.
; ---------------------------------------------------------------------""")
routine(0xFE5CE8, "Fdc_ClassifyCommandOpcode", """
; ---------------------------------------------------------------------
; Fdc_ClassifyCommandOpcode -- is (0x605A18) a command this controller has?
;
; Called from: {CALLED}
; Inputs:  (0x605A18), the opcode byte.
; Outputs: L = 0 accepted, 1 rejected.
; Evidence: ★ THIS IS THE ROUTINE THAT NAMES THE DEVICE.  It masks the opcode
;          with 0x1F -- so MT, MFM and SK are ignored, which is how a uPD765
;          decodes -- and accepts 0x1D, 0x19, 0x02..0x0A, plus whichever of
;          0x0B..0x11 the seven-entry Fdc_OpcodeValidityJumpTable admits, which
;          is 0x0C, 0x0D, 0x0F and 0x11.  The accepted set is therefore
;
;            {02 03 04 05 06 07 08 09 0A 0C 0D 0F 11 19 1D}   -- 15 opcodes
;
;          and the rejected set is the other 17 values of the 5-bit field.
;          That is EXACTLY the truth table of
;          `upd765_family_device::check_command()`
;          (../mame/src/devices/machine/upd765.cpp:1433-1478): every accepted
;          value is a uPD765 command and every rejected value is not.
;          notes/prom_a_fdc_checks.py builds both sets -- ours by simulating
;          this routine's constants as read back from the ROM, MAME's from the
;          case labels in upd765.cpp -- and fails unless all 32 values agree.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE5D2A, "Fdc_ClassifyCommandOpcode__valid")
routine(0xFE5D2D, "Fdc_ClassifyCommandOpcode__invalid")
routine(0xFE5D30, "Fdc_SendScanStepByte", """
; ---------------------------------------------------------------------
; Fdc_SendScanStepByte -- send STP, the ninth byte of a SCAN command
; Called from: {CALLED}
; Inputs:  (0x605A25), which is command block byte +0x0D; it sends `& 3` of it.
; Evidence: reached only from Fdc_SendSectorIdParams's tail, and only for
;          opcodes 0xDD, 0xD9 and 0xD1 -- SCAN HIGH OR EQUAL, SCAN LOW OR EQUAL
;          and SCAN EQUAL with MT and MFM set.  STP is the only uPD765
;          parameter that replaces DTL, and it is a 2-bit field, which is what
;          the `& 3` is.
; Unknown:  nothing here.  Fdc_SelectFormatParameters writes +0x0D = 1 in all
;          three geometry arms, so STP is always a one-sector step.
; ---------------------------------------------------------------------""")
routine(0xFE5D41, "Fdc_SendSpecifyParams", """
; ---------------------------------------------------------------------
; Fdc_SendSpecifyParams -- the two bytes of SPECIFY
; Called from: {CALLED}
; Inputs:  command block +0x0F (SRT), +0x10 (HUT), +0x11 (HLT), +0x12 (ND).
; Outputs: sends `(SRT << 4) | (HUT & 0x0F)` then `(HLT << 1) | (ND & 1)`.
; Evidence: that packing is the uPD765 SPECIFY encoding and nothing else has
;          that shape; it is also why Fdc_SelectFormatParameters stores SRT as
;          a nibble taken from the media descriptor's high nibble.
; ---------------------------------------------------------------------""")
routine(0xFE5D76, "Fdc_SendFormatParams", """
; ---------------------------------------------------------------------
; Fdc_SendFormatParams -- the four bytes of FORMAT TRACK after the drive byte
; Called from: {CALLED}
; Outputs: sends command block +6 (N, masked to 3 bits), +0x0A (SC),
;          +0x0B (GPL) and +0x0C (D).
; Evidence: N, SC, GPL, D in that order is FORMAT TRACK's parameter list, and
;          Fdc_Op5_FormatDisk sets +0x0C to 0xE5, the conventional filler.
; ---------------------------------------------------------------------""")
routine(0xFE5DA8, "Fdc_SendSeekParams", """
; ---------------------------------------------------------------------
; Fdc_SendSeekParams -- the one byte of SEEK after the drive byte
; Called from: {CALLED}
; Outputs: sends (0x605A26), the wanted cylinder (NCN).
; Evidence: SEEK takes exactly one parameter after the drive byte, and
;          Fdc_Op2_SeekToCylinder is built entirely around (0x605A26).
; ---------------------------------------------------------------------""")
routine(0xFE5DB6, "Fdc_SendSectorIdParams", """
; ---------------------------------------------------------------------
; Fdc_SendSectorIdParams -- C, H, R, N, EOT, GPL and then DTL or STP
;
; Called from: {CALLED}
; Outputs: sends command block +3, +4, +5, +6, +7, +8, and then either
;          Fdc_SendScanStepByte (for opcodes 0xDD, 0xD9, 0xD1) or +9.
; Evidence: ★ THIS ESTABLISHES THE COMMAND BLOCK AT 0x605A18 FIELD BY FIELD.
;          Read with the other senders and with Fdc_SelectFormatParameters:
;
;            +0x00  opcode, written by Fdc_IssueCommand
;            +0x01  HD  head bit of the drive byte  (toggled per track)
;            +0x02  US  unit bits of the drive byte
;            +0x03  C   cylinder            +0x04  H   head, ID field
;            +0x05  R   sector              +0x06  N   bytes/sector code
;            +0x07  EOT                     +0x08  GPL (read/write)
;            +0x09  DTL                     +0x0A  SC  (FORMAT)
;            +0x0B  GPL (FORMAT)            +0x0C  D   filler byte
;            +0x0D  STP (SCAN step)         +0x0E  NCN (SEEK target)
;            +0x0F  SRT +0x10 HUT +0x11 HLT +0x12 ND   (SPECIFY)
;            +0x13..+0x17  zeroed at setup, never read
;
;          The masks the ROM applies are themselves the field widths: H is
;          `& 1`, N is `& 7`, and STP is `& 3`.
; Unknown:  nothing structural.  +0x0E is SEEK's parameter, not a spare copy of
;          +0x03: Fdc_SendSeekParams sends (0x605A26) = +0x0E, and every writer
;          of the cylinder sets +0x03 and +0x0E together precisely so that the
;          seek that precedes a transfer goes to the cylinder the transfer will
;          name.
; ---------------------------------------------------------------------""")
routine(0xFE5E2B, "Fdc_RequestIsTrack0SectorProbe", """
; ---------------------------------------------------------------------
; Fdc_RequestIsTrack0SectorProbe -- is the pending request the boot-area probe?
; Called from: {CALLED}
; Outputs: HL = 0xFFFF if request+0 == 3 (read), +4 == 0, +6 == 0, +0x0A == 1
;          and (0x605A06) == 0xFFFF and request+8 is 2 or 0xFF; else 0.
; Evidence: stated as the literal predicate the ROM tests, because that is all
;          that is established.  (0x605A06) is written only at 0xFE42B4 and
;          0xFE42D2, both in the unit-1 back end (notes/prom_a_addr_census.py).
; Unknown:  why this one request shape is special.
; ---------------------------------------------------------------------""")
routine(0xFE5E68, "Fdc_RequestIsOp0WithCountFFFF", """
; ---------------------------------------------------------------------
; Fdc_RequestIsOp0WithCountFFFF -- HL = 0xFFFF iff request+0x0A == 0xFFFF and
; request+0 == 0; else 0.
; Called from: {CALLED}
; Evidence: literal.   Unknown: what the caller uses it to mean.
; ---------------------------------------------------------------------""")
routine(0xFE5E83, "Fdc_Nop_Ret", """
; ---------------------------------------------------------------------
; Fdc_Nop_Ret -- a bare RET, called from Fdc_Op5_FormatDisk.
; Called from: {CALLED}
; ---------------------------------------------------------------------""")
routine(0xFE5E84, "Fdc_SetError", """
; ---------------------------------------------------------------------
; Fdc_SetError -- record the FIRST error code and leave later ones alone
;
; Called from: {CALLED}
; Inputs:  the code as a word at (XSP+0x04).
; Outputs: (0x605A15) := the code, but only if it was 0; L = (0x605A15).
; Evidence: the guard `cp (0x605A15),0 / jr nz` is the whole of its "first one
;          wins" behaviour, and it is why every operation clears (0x605A15)
;          before starting.  The codes raised anywhere in the module are:
;
;            0x01 controller-idle or parameter-phase wait timed out
;            0x02 Fdc_WaitRqm timed out        0x03 Fdc_WaitReadyForCommandByte
;            0x08 result status not classifiable
;            0x09 no INT5 result within 500 ticks
;            0x10 read retries exhausted       0x20 write retries exhausted
;            0x2F write protected (ST1_NW, ST3_WP)
;            0x31 drive not ready (ST0_NR, ST3_RY clear)
;            0x32 equipment check (ST0_EC, ST3_FT)
;            0x33 no data (ST1_ND)             0x34 overrun (ST1_OR)
;            0x35 missing address mark (ST1_MA)
;            0x36 data error (ST1_DE)          0x37 end of cylinder (ST1_EN)
;            0xFC no controller                0xFE bad request field
;            0xFF unknown operation code
;
;          ★ the same code for the same physical condition whether it arrives
;          in ST0/ST1 or in ST3 is one of the reasons the ST3 reading is safe.
; Unknown:  the three arms that compare the code against 0x36, 0x35 and 0x33
;          and then fall into the same exit are NOPs in the ROM; nothing is
;          claimed about what they were meant to do.
; ---------------------------------------------------------------------""")
routine(0xFE5EB2, "Fdc_SetError__return_current")
routine(0xFE5EB8, "Fdc_ClearError", """
; ---------------------------------------------------------------------
; Fdc_ClearError -- (0x605A15) := 0
; Called from: {CALLED}
; ---------------------------------------------------------------------""")
routine(0xFE5EBF, "Fdc_MarkResultPending", """
; ---------------------------------------------------------------------
; Fdc_MarkResultPending -- (0x605A50) := 0xFF, "INT5 has not answered yet"
; Called from: {CALLED}
; Evidence: INT5_Dev7B_Receive writes 0 to (0x605A50) as its last act, and
;          Fdc_WaitResultFromInt5 waits for exactly that.  Every command that
;          ends in an interrupt calls this first.
; ---------------------------------------------------------------------""")
routine(0xFE5EC6, "Fdc_WaitResultFromInt5", """
; ---------------------------------------------------------------------
; Fdc_WaitResultFromInt5 -- block until INT5 has collected the result phase
; Called from: {CALLED}
; Outputs: Fdc_SetError(0x09) after 500 ticks with (0x605A50) still 0xFF.
; Evidence: the loop's only exit condition is the sentinel this module's own
;          Fdc_MarkResultPending sets and INT5_Dev7B_Receive clears.
; ---------------------------------------------------------------------""")
routine(0xFE5EF3, "Fdc_DelayTicks", """
; ---------------------------------------------------------------------
; Fdc_DelayTicks -- busy-wait (argument >> 1) ticks of (0x605A00)
; Called from: {CALLED}
; Inputs:  a word at (XSP+0x04); the routine halves it.
; Evidence: `srl 1,BC` then spin while `(0x605A00) - snapshot <= BC`, with a
;          16-bit safety counter that caps the spin at 0xFFFF iterations.
; ---------------------------------------------------------------------""")
routine(0xFE5F14, "Fdc_Delay20Ticks", """
; ---------------------------------------------------------------------
; Fdc_Delay20Ticks -- Fdc_DelayTicks(0x28), i.e. 20 ticks
; Called from: {CALLED}.  ⚠ NO CALLER FOUND, by the same two searches named in
;          Fdc_WriteControlRegister_IfNoError's header
;          (notes/prom_a_fdc_callgraph.py and notes/prom_a_xref.py 0xFE5F14).
; ---------------------------------------------------------------------""")
routine(0xFE5F1D, "Fdc_Op0_ResetAndIdentifyMedia", """
; ---------------------------------------------------------------------
; Fdc_Op0_ResetAndIdentifyMedia -- OPERATION 0
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 0)
; Evidence: for unit 1 it jumps into the other back end at 0xFE65EF's unit-1
;          path; for unit 0 it re-arms micro-DMA channel 0 (uDMA0_ArmOnINT7),
;          pulses PB bit 3, clears (0x605A59) and (0x605AEC), enables INT5 and
;          INTTC0, resets the controller and tail-calls
;          Fdc_ResetAndIdentifyMedia.
; ---------------------------------------------------------------------""")
routine(0xFE5F44, "Fdc_Op1_Recalibrate", """
; ---------------------------------------------------------------------
; Fdc_Op1_Recalibrate -- OPERATION 1: step out to track 0
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 1)
; Evidence: it saves (0x605A26), forces it to 5 so that Fdc_Op2_SeekToCylinder
;          really moves the head, seeks, then issues opcode 0x07 -- RECALIBRATE
;          -- waits for INT5 and restores the saved cylinder.  Seeking to a
;          known non-zero cylinder before recalibrating is the standard way of
;          making RECALIBRATE's 77-step limit sufficient.
; ---------------------------------------------------------------------""")
routine(0xFE5F98, "Fdc_Op2_SeekToCylinder", """
; ---------------------------------------------------------------------
; Fdc_Op2_SeekToCylinder -- OPERATION 2: SEEK, skipped if already there
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 2)
; Inputs:  (0x605A26) wanted cylinder; (0x605AEE) the cylinder believed current.
; Outputs: opcode 0x0F issued and awaited; (0x605AEE) := the new cylinder, or
;          0xFF if the seek reported an error.
; Evidence: the early `ret` when the two agree is what makes (0x605AEE) a
;          position cache rather than a copy.
; ---------------------------------------------------------------------""")
routine(0xFE5FDF, "Fdc_IssueReadData", """
; ---------------------------------------------------------------------
; Fdc_IssueReadData -- opcode 0xC6, with micro-DMA armed device -> RAM
; Called from: {CALLED}
; Evidence: 0xC6 is READ DATA (0x06) with MT and MFM set; (0x605A18) is loaded
;          with it BEFORE Dev7A_StartDma, because that routine's ten-code
;          direction chain reads (0x605A18) to decide which way channel 0 runs
;          (notes/FINDINGS-dev7b-and-int5.md).  ★ So the ten "direction codes"
;          in that note are uPD765 command opcodes: 0x4D 0xC9 0xC5 are FORMAT
;          TRACK, WRITE DELETED DATA and WRITE DATA -- the three that move RAM
;          to the device -- and 0xDD 0xD9 0xD1 0x4A 0x42 0xCC 0xC6 are SCAN
;          HIGH OR EQUAL, SCAN LOW OR EQUAL, SCAN EQUAL, READ ID, READ TRACK,
;          READ DELETED DATA and READ DATA, which move the device to RAM.
; ---------------------------------------------------------------------""")
routine(0xFE5FFE, "Fdc_Op3_ReadSectors", """
; ---------------------------------------------------------------------
; Fdc_Op3_ReadSectors -- OPERATION 3
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 3)
; Inputs:  request block: +4 head, +6 track, +8 first sector, +0x0A sector
;          count, +0x0C buffer address.
; Outputs: the sectors, through micro-DMA channel 0; request+0x0A left holding
;          the sectors still outstanding; error 0x10 if the retries run out.
; Evidence: for unit 1 it pushes +6, +4, +8, +0x0A and +0x0C and calls
;          0xFE4FB2 in the other back end.  For unit 0 it runs the CHS loop
;          below, which is what makes the geometry words readable: it clamps
;          the sector to (0x605AF7), sets the DMA byte count (0x605A0E) to
;          sectors x (0x605A10), where (0x605A10) is 0x400 for geometry 2 and
;          0x200 otherwise, transfers, and on a short count advances to the
;          next track by toggling command block +1 and, when that wraps to 0,
;          incrementing +3 and +0x0E.
; Unknown:  nothing structural; the retry count starts at 1, or at 8 when
;          Fdc_RequestIsTrack0SectorProbe said no.
; ---------------------------------------------------------------------""")
routine(0xFE6041, "Fdc_Op3_ReadSectors__attempt")
routine(0xFE6181, "Fdc_Op4_WriteSectors", """
; ---------------------------------------------------------------------
; Fdc_Op4_WriteSectors -- OPERATION 4
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 4)
; Evidence: byte-for-byte the same CHS loop as Fdc_Op3_ReadSectors with three
;          differences: it calls 0xFE4E4C for unit 1, it issues opcode 0xC5
;          (WRITE DATA with MT and MFM) through Fdc_IssueWriteData, and it
;          reports error 0x20 instead of 0x10 when the retries run out.  It
;          also gives up immediately on error 0x2F -- write protected -- which
;          is the one fault no retry can clear.
; ---------------------------------------------------------------------""")
routine(0xFE61B4, "Fdc_Op4_WriteSectors__attempt")
routine(0xFE62FA, "Fdc_IssueWriteData", """
; ---------------------------------------------------------------------
; Fdc_IssueWriteData -- opcode 0xC5, with micro-DMA armed RAM -> device
; Called from: {CALLED}
; ---------------------------------------------------------------------""")
routine(0xFE6319, "Fdc_Op5_FormatDisk", """
; ---------------------------------------------------------------------
; Fdc_Op5_FormatDisk -- OPERATION 5: format every track of the medium
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 5)
; Evidence: it re-runs the SENSE DRIVE STATUS check and the recalibrate, sets
;          N and the FORMAT GPL per geometry -- (2, 0x50), (2, 0x6C) or
;          (3, 0x74) for geometry {0,4,5}, 3 and 2 respectively -- writes the
;          filler byte 0xE5 into command block +0x0C, zeroes C, H and +0x0E,
;          and then loops Fdc_FormatOneTrack while the cylinder is below
;          (0x605AF1), toggling the head between tracks.
; ---------------------------------------------------------------------""")
routine(0xFE6406, "Fdc_FormatOneTrack", """
; ---------------------------------------------------------------------
; Fdc_FormatOneTrack -- build the ID table for one track and issue FORMAT TRACK
; Called from: {CALLED}
; Evidence: it points DMAS0 at the ID table at 0x605A5C through (0x605A3C),
;          arms channel 0 for opcode 0x4D and calls Fdc_IssueFormatTrack.
; ---------------------------------------------------------------------""")
routine(0xFE6430, "Fdc_BuildFormatIdTable", """
; ---------------------------------------------------------------------
; Fdc_BuildFormatIdTable -- write the C,H,R,N quadruples FORMAT TRACK reads
;
; Called from: {CALLED}
; Inputs:  command block +3 (C), +4 (H), +6 (N), +5 used as the running sector
;          number; (0x605AF5), the sectors per track.
; Outputs: the table at 0x605A5C, and (0x605A0E), the DMA byte count, which it
;          increments once per byte written.
; Evidence: FORMAT TRACK consumes 4 bytes per sector -- C, H, R, N -- over the
;          DMA path, and this routine emits exactly 4 x (sectors per track)
;          bytes.  It emits them in an INTERLEAVED order: the loop body writes
;          two quadruples per iteration and runs (spt >> 1) times, with the
;          second quadruple's R taken as `first R + spt/2`, and a final
;          quadruple appended when spt is odd.  That is a 2:1 interleave, and
;          the odd-sector tail is why the loop is written twice over.
; Unknown:  nothing here; the interleave factor is read off the `srl 1` and the
;          `add H,(XBC)`, not assumed.
; ---------------------------------------------------------------------""")
routine(0xFE65D0, "Fdc_IssueFormatTrack", """
; ---------------------------------------------------------------------
; Fdc_IssueFormatTrack -- opcode 0x4D, with micro-DMA armed RAM -> device
; Called from: {CALLED}
; ---------------------------------------------------------------------""")
routine(0xFE65EF, "Fdc_Op6_PortA3_Off", """
; ---------------------------------------------------------------------
; Fdc_Op6_PortA3_Off -- OPERATION 6: clear PA bit 3, then wait 5 ticks
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 6)
; Evidence: `ld A,(0x1E) / and A,0xF7 / ld (0x1E),A`; SFR 0x1E is PA
;          (tmp95c061.cpp:1363).  For unit 1 it calls 0xFE53E4 instead.
; Unknown:  ⚠ WHAT PA BIT 3 DRIVES IS NOT ESTABLISHED.  It is the module's only
;          output outside the two device windows, operations 6 and 7 are its
;          only writers, and no other code in prom_a or prom_b touches it.  A
;          drive-motor or drive-select line is the obvious reading and is NOT
;          claimed here.
; ---------------------------------------------------------------------""")
routine(0xFE661F, "Fdc_Op7_PortA3_On", """
; ---------------------------------------------------------------------
; Fdc_Op7_PortA3_On -- OPERATION 7: set PA bit 3
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 7)
; Evidence: `or A,0x08` on SFR 0x1E; unit 1 goes to 0xFE544D.
; ---------------------------------------------------------------------""")
routine(0xFE6635, "Fdc_Op8_GetSavedError", """
; ---------------------------------------------------------------------
; Fdc_Op8_GetSavedError -- OPERATION 8: (0x605A15) := (0x605A16)
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 8)
; Evidence: Fdc_Request saves the incoming (0x605A15) into (0x605A16) before it
;          clears it, so this operation republishes the error of the PREVIOUS
;          request as this one's result.
; ---------------------------------------------------------------------""")
routine(0xFE6640, "Fdc_Op9_SetFlag605A59", """
; ---------------------------------------------------------------------
; Fdc_Op9_SetFlag605A59 -- OPERATION 9: (0x605A59) := 0xFF or 0x00
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 9)
; Inputs:  (0x605A34) = request+4; 1 sets the flag, 0 clears it, anything else
;          raises error 0xFE.
; Unknown:  ⚠ what the flag means.  `python3 notes/prom_a_addr_census.py
;          0x605A59` finds THREE writes -- here twice and once in
;          Fdc_Op0_ResetAndIdentifyMedia -- and NO read, anywhere in prom_a or
;          prom_b.  So CPU 1 never acts on it.
; ---------------------------------------------------------------------""")
routine(0xFE6668, "Fdc_Op11_SenseDriveStatus", """
; ---------------------------------------------------------------------
; Fdc_Op11_SenseDriveStatus -- OPERATION 11: issue SENSE DRIVE STATUS and
; decode ST3
;
; Called from: {CALLED}  (Fdc_OperationJumpTable entry 11)
; Evidence: opcode 0x04, then Dev7B_WaitStatus_8x_Cx and ONE byte read from the
;          DATA register -- SENSE DRIVE STATUS's result phase is exactly one
;          byte, ST3.  The three bits it tests are
;
;            bit 7 set    ST3_FT  fault           -> error 0x32
;            bit 5 CLEAR  ST3_RY  not ready       -> error 0x31
;            bit 6 set    ST3_WP  write protected -> error 0x2F
;
;          named in ../mame/src/devices/machine/upd765.h:105-110, and the three
;          codes are the SAME ones Fdc_ClassifyResultStatus raises for not
;          ready, equipment check and not writable.
; Unknown:  nothing here.
; ---------------------------------------------------------------------""")
routine(0xFE66C7, "Fdc_Request", """
; ---------------------------------------------------------------------
; Fdc_Request -- ★ THE MODULE'S ONLY PUBLIC ENTRY POINT
;
; Called from: {CALLED}.
;          Those eight sites are exact, not an upper bound: they are read out of
;          this file's own byte comments by notes/prom_a_fdc_callgraph.py, and
;          `python3 notes/prom_a_xref.py 0xFE66C7` independently finds the same
;          eight.
; Inputs:  XSP+0x10 -> a 16-byte REQUEST BLOCK:
;            +0x00 word  operation, 0..11        +0x02 word  unit, 0 or 1
;            +0x04 word  head                    +0x06 word  track, or the
;                                                            media descriptor
;                                                            for operation 0
;            +0x08 word  first sector            +0x0A word  sector count
;            +0x0C long  buffer address
; Outputs: HL = the error code, sign-extended; the block is copied to
;          (0x605A30) AND to (0x605A40), and (0x605A16) keeps the previous
;          request's error for operation 8.
; Evidence: ★ THE UNIT FIELD IS WHAT SELECTS THE BACK END.  It lands at
;          (0x605A32), and every operation begins `cp (0x605A32),1`; the unit-1
;          arm calls into 0xFE4CE0-0xFE544D, and the only device that region
;          touches is the 16-bit port at 0x7E0008 (0xFE4CE0 / 0xFE50A0,
;          notes/FINDINGS-memory-map.md).  So this is a two-unit block-device
;          layer, not a floppy driver with dead code in it.
;          Reentrancy: (0x605A09) is a guard byte set to 0xA5 for the duration
;          under `ei 6` / `ei 0`, and a second entry while it is 0xA5 returns
;          error 0xFB without touching the hardware.  The operation word is
;          bounded `cp WA,0x0B / jr UGT` before Fdc_OperationJumpTable is
;          indexed, and out of range raises 0xFF.
; Unknown:  why the request is copied twice, to 0x605A30 and 0x605A40; nothing
;          in this module reads the second copy.
; ---------------------------------------------------------------------""")
routine(0xFE67A4, "Fdc_Request__dispatch")
routine(0xFE67F9, "Fdc_ServiceDataByte", """
; ---------------------------------------------------------------------
; Fdc_ServiceDataByte -- move ONE byte through 0x7A0000 by programmed I/O
;
; Called from: {CALLED}.
;          0xFE30D8 is `call 0xFE67F9 / reti` -- an interrupt handler.  It is
;          published as slot 3 of the module's entry directory at 0xFE3000 and
;          reached through prom_b thunk 0xF42D2C (notes/prom_a_xref.py
;          0xFE300C).
; Inputs:  (0x605A0E) the remaining byte count; (0x605A3E) the RAM pointer;
;          (0x605A30) the operation, 3 = read, 4 = write.
; Outputs: one byte moved in the operation's direction, the pointer advanced,
;          the count decremented; at zero it pulses PB bit 3 (PortB3_Pulse) and
;          re-arms micro-DMA channel 0 on INT7 (uDMA0_ArmOnINT7) -- the same
;          two acts INTTC0_uDMA0Done performs.
; Evidence: ★ THIS IS THE PROGRAMMED-I/O TWIN OF THE MICRO-DMA PATH, and it
;          settles what 0x7A0000 is: the same FDC data register, reached on the
;          DMA-acknowledged decode.  Both paths move one byte per INT7 and both
;          finish with the same pair of calls.
; Unknown:  ⚠ NO INTERRUPT VECTOR REACHES IT.  `python3 notes/vector_map.py`
;          puts slot 0x38, INT7, at 0xF82D09, the deliberate hang -- not at
;          0xF42D2C.  So on this firmware the byte path is micro-DMA only, and
;          this handler is published but unwired.  Stated as measured; no claim
;          about intent.
; ---------------------------------------------------------------------""")

# --------------------------------------------------------------------------
# The four jump tables.  Emitted as data, with the entry counts taken from the
# four `cp` bounds in the code that indexes them.
# --------------------------------------------------------------------------
TABLE_TEXT = """
; ==============================================================================
; 0xFE6E3A-0xFE6E83 -- the FDC module's FOUR JUMP TABLES, which tile exactly
; ==============================================================================
;
; Each is a table of 16-bit BYTE OFFSETS added to a base address that the
; indexing code loads immediately afterwards, in the TLCS-900 idiom
;     lda XIX,<table> / ld WA,(XIX+WA) / lda XIX,<base> / jp XIX+WA
;
; ENTRY COUNTS ARE NOT COUNTED BY EYE.  Each comes from the bound its indexer
; tests before the load, and the four tables then tile 0xFE6E3A-0xFE6E83 with
; no gap and no overlap -- 6 + 12 + 7 + 12 = 37 entries, 74 bytes:
;
;   table      indexer   bound in the ROM              entries  base
;   0xFE6E3A   0xFE565A  cp WA,5  / jr GT   (and < 0)     6      0xFE5682
;   0xFE6E46   0xFE5728  cp WA,0x0B / jr UGT             12      0xFE5746
;   0xFE6E5E   0xFE5D10  cp WA,6  / jr GT   (after -0x0B) 7      0xFE5D2A
;   0xFE6E6C   0xFE6788  cp WA,0x0B / jr UGT             12      0xFE67A4
;
; `python3 notes/prom_a_fdc_checks.py` re-reads the bounds AND the offsets from
; the ROM, resolves every entry, and fails if any target is not a label in
; prom_a/wsa1_prom_a.s or if the four tables stop tiling.
; ==============================================================================
Fdc_MediaTypeJumpTable:
; index = (0x605A5B) & 0x0F, the media descriptor's low nibble.  Base 0xFE5682.
	.short 0x002A                                  ; FE6E3A  0 -> 0xFE56AC  geometry 0
	.short 0x002A                                  ; FE6E3C  1 -> 0xFE56AC  geometry 0
	.short 0x0000                                  ; FE6E3E  2 -> 0xFE5682  geometry 2
	.short 0x0008                                  ; FE6E40  3 -> 0xFE568A  geometry 3
	.short 0x001A                                  ; FE6E42  4 -> 0xFE569C  geometry 4
	.short 0x0022                                  ; FE6E44  5 -> 0xFE56A4  geometry 5
Fdc_ValidateJumpTable:
; index = the request's operation word.  Base 0xFE5746.
	.short 0x0000                                  ; FE6E46   0 -> 0xFE5746  geometry setup
	.short 0x0009                                  ; FE6E48   1 -> 0xFE574F  generic check
	.short 0x0009                                  ; FE6E4A   2 -> 0xFE574F
	.short 0x0009                                  ; FE6E4C   3 -> 0xFE574F
	.short 0x0009                                  ; FE6E4E   4 -> 0xFE574F
	.short 0x0009                                  ; FE6E50   5 -> 0xFE574F
	.short 0x003A                                  ; FE6E52   6 -> 0xFE5780  accept, no check
	.short 0x003A                                  ; FE6E54   7 -> 0xFE5780
	.short 0x003A                                  ; FE6E56   8 -> 0xFE5780
	.short 0x0006                                  ; FE6E58   9 -> 0xFE574C  head check only
	.short 0x003A                                  ; FE6E5A  10 -> 0xFE5780
	.short 0x0009                                  ; FE6E5C  11 -> 0xFE574F
Fdc_OpcodeValidityJumpTable:
; index = (opcode & 0x1F) - 0x0B, for the seven values 0x0B..0x11 only.
; Base 0xFE5D2A = "valid"; 0xFE5D2D = "invalid".
	.short 0x0003                                  ; FE6E5E  0x0B -> invalid
	.short 0x0000                                  ; FE6E60  0x0C -> valid    READ DELETED DATA
	.short 0x0000                                  ; FE6E62  0x0D -> valid    FORMAT TRACK
	.short 0x0003                                  ; FE6E64  0x0E -> invalid
	.short 0x0000                                  ; FE6E66  0x0F -> valid    SEEK
	.short 0x0003                                  ; FE6E68  0x10 -> invalid
	.short 0x0000                                  ; FE6E6A  0x11 -> valid    SCAN EQUAL
Fdc_OperationJumpTable:
; index = the request's operation word.  Base 0xFE67A4; the arms are 5 bytes
; each, which is why the offsets step by 5.
	.short 0x0000                                  ; FE6E6C   0 -> Fdc_Op0_ResetAndIdentifyMedia
	.short 0x0005                                  ; FE6E6E   1 -> Fdc_Op1_Recalibrate
	.short 0x000A                                  ; FE6E70   2 -> Fdc_Op2_SeekToCylinder
	.short 0x000F                                  ; FE6E72   3 -> Fdc_Op3_ReadSectors
	.short 0x0014                                  ; FE6E74   4 -> Fdc_Op4_WriteSectors
	.short 0x0019                                  ; FE6E76   5 -> Fdc_Op5_FormatDisk
	.short 0x001E                                  ; FE6E78   6 -> Fdc_Op6_PortA3_Off
	.short 0x0023                                  ; FE6E7A   7 -> Fdc_Op7_PortA3_On
	.short 0x0028                                  ; FE6E7C   8 -> Fdc_Op8_GetSavedError
	.short 0x002D                                  ; FE6E7E   9 -> Fdc_Op9_SetFlag605A59
	.short 0x0032                                  ; FE6E80  10 -> Fdc_Op10_TestControllerPresent
	.short 0x0037                                  ; FE6E82  11 -> Fdc_Op11_SenseDriveStatus
"""


def roundtrip(lo, hi):
    out = subprocess.run([sys.executable,
                          os.path.join(ROOT, "prom_a", "roundtrip.py"),
                          "0x%06X" % lo, "0x%06X" % hi, "--block"],
                         capture_output=True, text=True, check=True)
    if "round-trip: OK" not in out.stderr:
        sys.exit("roundtrip.py did not certify 0x%06X-0x%06X" % (lo, hi))
    return out.stdout.splitlines()


ADDR_RE = re.compile(r';\s*([0-9A-F]{6})\b')


def annotate(lines, called):
    out, pending = [], []
    for line in lines:
        if re.match(r'^\.L[0-9A-F]+:\s*$', line):
            pending.append(line)
            continue
        m = ADDR_RE.search(line)
        a = int(m.group(1), 16) if m else None
        if a in R:
            label, header = R[a]
            if header:
                txt = header.strip("\n").replace(
                    "{CALLED}", called.get(a, "(no site inside the module)"))
                out.append("")
                out.extend(txt.split("\n"))
            out.append(label + ":")
        out.extend(pending)
        pending = []
        out.append(line)
    out.extend(pending)
    return out


def main():
    outdir = None
    for a in sys.argv[1:]:
        if a.startswith("--out-dir"):
            outdir = a.split("=", 1)[1] if "=" in a else None
    if outdir is None:
        i = sys.argv.index("--out-dir") if "--out-dir" in sys.argv else -1
        if i >= 0 and i + 1 < len(sys.argv):
            outdir = sys.argv[i + 1]
    if not outdir:
        sys.exit("usage: gen_prom_a_fdc_module.py --out-dir DIR")
    os.makedirs(outdir, exist_ok=True)

    labels_path = os.path.join(outdir, "fdc_labels.txt")
    with open(labels_path, "w") as f:
        for a in sorted(R):
            f.write("0x%06X %s\n" % (a, R[a][0]))

    import prom_a_fdc_callgraph as CG
    extra = {a: R[a][0] for a in R}
    all_labels, starts, edges, ext = CG.build(extra)
    called = {}
    for a in R:
        names = sorted({all_labels.get(src, "0x%06X" % (src or 0))
                        for site, src, tgt in edges if tgt == a})
        n = len([1 for site, src, tgt in edges if tgt == a])
        outside = sorted(site for site, tgt in ext if tgt == a)
        parts = []
        parts.append("%d site(s) in the module%s"
                     % (n, (": " + ", ".join(names)) if names else ""))
        if outside:
            parts.append("%d in converted code outside it (%s)"
                         % (len(outside), ", ".join("0x%06X" % x for x in outside)))
        called[a] = "; also called from: ".join([" and ".join(parts)]) \
            if False else "; ".join(parts)

    for (lo, hi), name, banner in ((SPAN1, "fdc_span1.s", MODULE_BANNER),
                                   (SPAN2, "fdc_span2.s", None)):
        body = annotate(roundtrip(lo, hi), called)
        with open(os.path.join(outdir, name), "w") as f:
            if banner:
                f.write(banner.strip("\n") + "\n")
            f.write("\n".join(body) + "\n")
    with open(os.path.join(outdir, "fdc_tables.s"), "w") as f:
        f.write(TABLE_TEXT.strip("\n") + "\n")
    print("wrote fdc_span1.s, fdc_span2.s, fdc_tables.s, fdc_labels.txt to " + outdir)


if __name__ == "__main__":
    main()
