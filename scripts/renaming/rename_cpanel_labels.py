#!/usr/bin/env python3
"""
rename_cpanel_labels.py - Rename LABEL_* symbols in cpanel_routines.s

Renames all opaque LABEL_FC* symbols to descriptive names based on their
role within each function. All labels defined in cpanel_routines.s are
internal (no cross-file references), so only that one file needs updating.

Uses binary I/O with Latin-1 encoding to safely pass through non-ASCII
bytes (e.g. UTF-8 em-dashes in comments) without corruption, consistent
with the project policy for kn5000_v10_program.s and other source files.

Usage:
    python3 scripts/rename_cpanel_labels.py

Run from any directory; paths are resolved relative to this script's location.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename map
#
# Convention: FunctionNameAbbrev_ActionOrRole
#
# Each entry documents the enclosing function and the label's role:
#
# DELAY_2_LOOPS / DELAY_6_LOOPS / DELAY_10_LOOPS /
# DELAY_300_LOOPS / DELAY_1500_LOOPS / DELAY_3000_LOOPS
#   These six delay routines share identical structure:
#     load counter -> LABEL_loop: dec/cps/jr-z-exit/jr-loop -> LABEL_exit: ret
#
# DELAY_6_TICKS
#   Same tick-based structure: load tick snapshot -> LABEL_loop: read/sub/cps/jr-lt-loop -> ret
#
# DELAY_51_TICKS
#   Same tick-based structure.
#
# CPanel_PanelDetection
#   LABEL_FC41C8 - reached when left-panel response check is skipped (jr z)
#                  falls through to right-panel probe. "SkipLeft" = skip left-MCU flag set.
#   LABEL_FC41F7 - exit point after right-panel response check; loads result byte and returns.
#
# CPanel_WaitTXReady
#   LABEL_FC43B0 - reached when timeout counter hits zero (hardware is ready or gave up);
#                  enables interrupts, disables RX, sets B.7 flag, returns.
#                  Shared by both the "counter exhausted" path and the "buffer empty" path.
#                  Role: configure serial for TX and return.
#
# INTA_HANDLER
#   LABEL_FC4462 - reached when CP_Status (36235) != 0; handles the "not first byte" case
#                  of the INTA interrupt (count-down the receive-byte countdown).
#   LABEL_FC4470 - body of that countdown: decrement, set flags, fall through to handler end.
#                  (FC4470 is jumped into when 36255 was already non-zero at FC4462.)
#
# CPanel_SM_SendByte1
#   LABEL_FC45ED - reached after circular TX buffer wrap check; stores byte count (2) and
#                  inspects the byte to determine how many extra clocks are needed.
#   LABEL_FC4606 - exit point: advance state machine to next routine and return via common end.
#
# CPanel_SM_SendByteN
#   LABEL_FC4652 - reached after circular TX buffer wrap check; decrements byte counter and
#                  checks whether done (counter == 1 or 0).
#   LABEL_FC466B - byte counter reached 1 or 0: advance to next state and return.
#
# CPanel_SM_TXComplete
#   LABEL_FC46C1 - reached when fewer than 2 bytes remain (buffer nearly empty);
#                  disables TX clocks and resets flags, returning via common end.
#
# CPanel_SM_RXByte1
#   LABEL_FC4722 - no wrap needed: RX write ptr >= RX read ptr, compute forward distance.
#   LABEL_FC4727 - common continuation: distance is in IY, compare to threshold (3).
#   LABEL_FC4732 - distance >= 3: clear B.0, advance RX write ptr, check for wrap.
#   LABEL_FC4749 - common exit: store byte count (2), inspect byte for extra clock count.
#   LABEL_FC4760 - exit point: advance state machine to next routine, return via common end.
#
# CPanel_SM_RXByteN
#   LABEL_FC478D - common point after RX buffer advance (or skip when B.0 set);
#                  decrement byte counter and check completion.
#   LABEL_FC47CC - counter not 1: still more bytes expected; set up for next RX byte
#                  and return via common end (keep receiving).
#
# CPanel_InterruptPoll_MainLoop
#   LABEL_FC482C - TX ptrs: write >= read, compute forward distance (no negation needed).
#   LABEL_FC4831 - common: distance in HL, compare to threshold (3).
#   LABEL_FC485B - main body: check/update CP_Flags_A.76 counter, decide LED vs button path.
#   LABEL_FC4877 - "do this" branch: call CPanel_UpdateLEDs (counter not at 3).
#   LABEL_FC487A - post-LED/button work: check hardware pins to decide if TX can start.
#   LABEL_FC48A4 - TX buffer has >= 2 bytes pending: set up state machine to begin TX.
#   LABEL_FC48E8 - re-enable interrupts and return (common exit for poll loop body).
#   LABEL_FC48EB - hardware busy (pin state bad or flags set); bump retry counter.
#
# CPanel_RX_ButtonPacket
#   LABEL_FC49BD - bit 6 of first packet byte clear: no subtract; add W directly to XHL offset.
#   LABEL_FC49C3 - common: XOR with lookup table byte to compute button event data.
#
# CPanel_RX_EncoderPacket
#   LABEL_FC4A14 - encoder dispatch returned a valid result (HL != 0xFFFF);
#                  write delta + 0xFF marker to event queue and commit.
#   LABEL_FC4A33 - loop back to parse next packet.
#   LABEL_FC4A36 - local thunk: save/restore registers around CPanel_EncoderDispatch call.
#
# CPanel_RX_MultiBytePacket
#   LABEL_FC4A7D - bit 6 of C set: subtract 0x30 to adjust address; then OR with A.
#   LABEL_FC4A8B - per-byte loop body: write event byte to LED/event queue and advance ptrs.
#   LABEL_FC4AB7 - encoder returned 0xFFFF (no event): undo event queue write and commit RX ptr.
#   LABEL_FC4AC1 - encoder returned valid: reload A from 36246 and fall into write path.
#   LABEL_FC4AC5 - common write path: write A to event queue, advance ptr.
#   LABEL_FC4AEA - bit 4 of W set (encoder type): load 0xFF as the event data byte.
#   LABEL_FC4AEC - common: write the final event byte and advance ptrs, commit, continue.
#   LABEL_FC4B00 - commit RX read ptr (xiy -> 36253) after partial decode / error path.
#   LABEL_FC4B04 - per-byte loop tail: advance W/B counters, branch back to loop body.
#
# CPanel_UpdateLEDs
#   LABEL_FC4B4E - LED event queue differs OR pending count non-zero: check TX buffer space.
#   LABEL_FC4B5E - TX ptrs: write >= read, compute forward distance directly.
#   LABEL_FC4B63 - common: distance in HL, compare to threshold (3) for enough TX space.
#   LABEL_FC4C07 - return: TX buffer full, event queue empty, or no more events.
#
# CPanel_IncRXPtr
#   LABEL_FC4C12 - IY < 0x5C: no wrap needed, return.
#
# CPanel_IncLEDPtr
#   LABEL_FC4C1D - IY < 0x3C: no wrap needed, return.
#
# CPanel_IncEventPtr
#   LABEL_FC4C28 - IX < 0x80: no wrap needed, return.
#
# CPanel_DecEventPtr
#   LABEL_FC4C31 - IX != 0: decrement normally and return.
# ---------------------------------------------------------------------------

RENAMES = {
    # --- DELAY_2_LOOPS ---
    "LABEL_FC40E0": "Delay2L_Loop",
    "LABEL_FC40E8": "Delay2L_Done",

    # --- DELAY_6_LOOPS ---
    "LABEL_FC40EB": "Delay6L_Loop",
    "LABEL_FC40F3": "Delay6L_Done",

    # --- DELAY_10_LOOPS ---
    "LABEL_FC40F7": "Delay10L_Loop",
    "LABEL_FC40FF": "Delay10L_Done",

    # --- DELAY_300_LOOPS ---
    "LABEL_FC4103": "Delay300L_Loop",
    "LABEL_FC410B": "Delay300L_Done",

    # --- DELAY_1500_LOOPS ---
    "LABEL_FC410F": "Delay1500L_Loop",
    "LABEL_FC4117": "Delay1500L_Done",

    # --- DELAY_3000_LOOPS ---
    "LABEL_FC411B": "Delay3000L_Loop",
    "LABEL_FC4123": "Delay3000L_Done",

    # --- DELAY_6_TICKS ---
    "LABEL_FC4141": "Delay6T_Loop",

    # --- DELAY_51_TICKS ---
    "LABEL_FC4156": "Delay51T_Loop",

    # --- CPanel_PanelDetection ---
    # jr z skips setting the left-MCU flag; lands here to probe right panel
    "LABEL_FC41C8": "PanelDet_ProbeRight",
    # right-panel check done; load result byte and return
    "LABEL_FC41F7": "PanelDet_Return",

    # --- CPanel_WaitTXReady ---
    # timeout counter exhausted OR buffer empty: configure serial for TX and return
    "LABEL_FC43B0": "WaitTX_ConfigAndReturn",

    # --- INTA_HANDLER ---
    # CP_Status != 0: not the first byte of an INTA sequence; handle countdown
    "LABEL_FC4462": "INTA_HandleCountdown",
    # countdown body: 36255 was already non-zero, decrement and set flags
    "LABEL_FC4470": "INTA_DecrementRXCount",

    # --- CPanel_SM_SendByte1 ---
    # after TX buffer wrap check: store byte count, inspect byte for clock count
    "LABEL_FC45ED": "SendByte1_InspectByte",
    # advance state machine to next routine and jump to common ISR exit
    "LABEL_FC4606": "SendByte1_AdvanceState",

    # --- CPanel_SM_SendByteN ---
    # after TX buffer wrap check: decrement byte counter, test for completion
    "LABEL_FC4652": "SendByteN_CheckDone",
    # counter reached 1 or 0: advance to next state machine state
    "LABEL_FC466B": "SendByteN_AdvanceState",

    # --- CPanel_SM_TXComplete ---
    # fewer than 2 bytes remain: disable TX clocks, clear flags, return via common end
    "LABEL_FC46C1": "TXComplete_BufferEmpty",

    # --- CPanel_SM_RXByte1 ---
    # RX write ptr >= read ptr: forward distance, no negation needed
    "LABEL_FC4722": "RXByte1_ForwardDist",
    # common: distance in IY, compare to threshold
    "LABEL_FC4727": "RXByte1_CheckThreshold",
    # distance >= 3: enough space; clear B.0, advance RX write ptr
    "LABEL_FC4732": "RXByte1_AdvanceWritePtr",
    # common exit: store byte count 2, inspect byte for extra clock count
    "LABEL_FC4749": "RXByte1_InspectByte",
    # exit point: advance state machine, return via common ISR end
    "LABEL_FC4760": "RXByte1_AdvanceState",

    # --- CPanel_SM_RXByteN ---
    # common after RX buffer advance (or skip): decrement counter, check completion
    "LABEL_FC478D": "RXByteN_CheckDone",
    # counter != 1: more bytes expected; set up for next RX byte
    "LABEL_FC47CC": "RXByteN_ContinueRX",

    # --- CPanel_InterruptPoll_MainLoop ---
    # TX ptrs: write >= read, compute forward distance directly
    "LABEL_FC482C": "PollLoop_TXForwardDist",
    # common: distance in HL, compare to threshold (3)
    "LABEL_FC4831": "PollLoop_TXCheckThreshold",
    # main body after counter check: decide LED update vs InitButtonState
    "LABEL_FC485B": "PollLoop_DispatchWork",
    # LED update branch (counter != 3)
    "LABEL_FC4877": "PollLoop_DoLEDUpdate",
    # after LED/button work: check hardware pins for TX readiness
    "LABEL_FC487A": "PollLoop_CheckTXReady",
    # TX buffer has >= 2 bytes: configure state machine to begin TX
    "LABEL_FC48A4": "PollLoop_StartTX",
    # common exit: re-enable interrupts and return
    "LABEL_FC48E8": "PollLoop_Return",
    # hardware busy: increment retry counter, check limit
    "LABEL_FC48EB": "PollLoop_BusyRetry",

    # --- CPanel_RX_ButtonPacket ---
    # bit 6 of first byte clear: add W directly (no subtract of 0x30)
    "LABEL_FC49BD": "BtnPkt_AddOffset",
    # common: XOR with lookup table entry to compute event data
    "LABEL_FC49C3": "BtnPkt_XORLookup",

    # --- CPanel_RX_EncoderPacket ---
    # encoder dispatch returned a valid delta (HL != 0xFFFF): write to event queue
    "LABEL_FC4A14": "EncPkt_WriteEvent",
    # loop back to CPanel_RX_ParseNext
    "LABEL_FC4A33": "EncPkt_ParseNext",
    # register-save thunk around CPanel_EncoderDispatch
    "LABEL_FC4A36": "EncPkt_DispatchThunk",

    # --- CPanel_RX_MultiBytePacket ---
    # bit 6 of C set: subtract 0x30 from address offset, then OR with A
    "LABEL_FC4A7D": "MBytePkt_AdjustAddr",
    # per-byte loop body: write event byte, advance ptrs
    "LABEL_FC4A8B": "MBytePkt_LoopBody",
    # encoder returned 0xFFFF: undo event write, commit RX ptr
    "LABEL_FC4AB7": "MBytePkt_EncNoEvent",
    # encoder returned valid result: reload A from 36246 and write
    "LABEL_FC4AC1": "MBytePkt_EncWriteResult",
    # common write path: write final event byte, advance ptrs
    "LABEL_FC4AC5": "MBytePkt_WriteEventByte",
    # bit 4 of W set (encoder sub-type): load 0xFF as event data
    "LABEL_FC4AEA": "MBytePkt_EncFFMarker",
    # write final event byte, advance ptrs, commit, continue loop
    "LABEL_FC4AEC": "MBytePkt_CommitAndContinue",
    # commit RX read ptr after partial decode / underflow path
    "LABEL_FC4B00": "MBytePkt_CommitRXPtr",
    # loop tail: increment W byte-selector, decrement B counter, branch back
    "LABEL_FC4B04": "MBytePkt_LoopTail",

    # --- CPanel_UpdateLEDs ---
    # event queue differs or count non-zero: check TX buffer has room
    "LABEL_FC4B4E": "LEDs_CheckTXSpace",
    # TX ptrs: write >= read, compute forward distance directly
    "LABEL_FC4B5E": "LEDs_TXForwardDist",
    # common: distance in HL, compare to threshold (3)
    "LABEL_FC4B63": "LEDs_TXCheckThreshold",
    # return: TX full, queue empty, or nothing to do
    "LABEL_FC4C07": "LEDs_Return",

    # --- CPanel_IncRXPtr ---
    # IY < 0x5C: no wrap, return
    "LABEL_FC4C12": "IncRX_NoWrap",

    # --- CPanel_IncLEDPtr ---
    # IY < 0x3C: no wrap, return
    "LABEL_FC4C1D": "IncLED_NoWrap",

    # --- CPanel_IncEventPtr ---
    # IX < 0x80: no wrap, return
    "LABEL_FC4C28": "IncEvt_NoWrap",

    # --- CPanel_DecEventPtr ---
    # IX != 0: decrement normally and return
    "LABEL_FC4C31": "DecEvt_NoWrap",
}


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    target_file = os.path.join(repo_root, "maincpu", "cpanel_routines.s")

    # Read with binary I/O, decode as Latin-1.
    # The file contains non-ASCII bytes (UTF-8 em-dashes in comments).
    # Latin-1 is a byte-transparent codec: every byte 0x00-0xFF round-trips
    # unchanged, so non-ASCII comment text is preserved exactly.
    with open(target_file, "rb") as fh:
        raw = fh.read()
    content = raw.decode("latin-1")

    # Verify every old label exists exactly once as a definition (label:)
    # and at least once total (used in a branch).
    errors = []
    for old, new in RENAMES.items():
        # Definition: "^LABEL_XXX:" at start of line (possibly with trailing whitespace)
        defs = re.findall(r"^" + re.escape(old) + r":", content, re.MULTILINE)
        if len(defs) != 1:
            errors.append(
                f"  {old}: expected 1 definition, found {len(defs)}"
            )
        # Total references (definition + uses).
        # LABEL_FC4AB7 is reached by fall-through from a __jrt_nop_ trampoline,
        # so it has no explicit branch reference — count of 1 is acceptable.
        total = re.findall(re.escape(old), content)
        if len(total) < 1:
            errors.append(
                f"  {old}: not found in file at all"
            )

    if errors:
        print("Pre-flight check FAILED — label mismatches:")
        for e in errors:
            print(e)
        raise SystemExit(1)

    # Apply renames in a single pass using a regex that replaces every
    # occurrence of each old name (definition and all branch targets).
    # We sort by descending length to avoid prefix collisions between
    # labels that share a common prefix (e.g. FC4A8B vs FC4A8).
    sorted_renames = sorted(RENAMES.items(), key=lambda kv: len(kv[0]), reverse=True)

    for old, new in sorted_renames:
        # Replace all occurrences (definition line and branch/jump references)
        content = content.replace(old, new)

    # Write back with binary I/O using Latin-1 to preserve non-ASCII bytes
    with open(target_file, "wb") as fh:
        fh.write(content.encode("latin-1"))

    print(f"Renamed {len(RENAMES)} labels in {target_file}")
    for old, new in sorted(RENAMES.items()):
        print(f"  {old}  ->  {new}")


if __name__ == "__main__":
    main()
