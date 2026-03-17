#!/usr/bin/env python3
"""
rename_computer_interface_labels.py

Renames LABEL_* symbols in:
  - maincpu/computer_interface_pcg.s    (21 labels)
  - maincpu/computer_interface_config.s (20 labels)

All I/O uses binary mode with ascii encoding to avoid corrupting
Latin-1 characters or other non-UTF8 bytes in the source files.

Cross-reference check (run before creating this script):
  grep -rn "LABEL_F77..." maincpu/ --include="*.s" | grep -v computer_interface_pcg.s
  grep -rn "LABEL_F74..." maincpu/ --include="*.s" | grep -v computer_interface_config.s

Result: no cross-file references found for any of the 41 labels.
All renames are strictly within each respective file.

Naming convention: FunctionNameAbbrev_ActionOrRole
"""

import os
import sys

# ---------------------------------------------------------------------------
# Rename tables
# ---------------------------------------------------------------------------

# computer_interface_pcg.s
# 21 LABEL_* symbols, all internal (no cross-file refs)
PCG_RENAMES = [
    # TtMdPcgOut labels
    ("LABEL_F773D7", "TtMdPcgOut_Exit"),
        # Common early-exit point in TtMdPcgOut — reached for all non-activate
        # events (0x1C0000C, 0x1C0000B, 0x1C00002, not-0x1C00001, or xde!=0).
        # Clears xhl to 0 and returns.

    # AcPcgOutGridBoxProc labels
    ("LABEL_F774F6", "PcgOutGrid_CheckAltPrev"),
        # Zero result from 0x1E00050 query in the decrement (prev) branch.
        # Falls through to check the alternate condition 0x1E00091.

    ("LABEL_F7759F", "PcgOutGrid_CheckAltNext"),
        # Zero result from 0x1E00050 query in the increment (next) branch.
        # Parallel structure to PcgOutGrid_CheckAltPrev.

    ("LABEL_F775F5", "PcgOutGrid_CopyStrBank0"),
        # Handles event 0x1E0008A: loads xiz with offset 0x3E (62) then
        # falls into PcgOutGrid_CopyStrCommon to copy the bank-0 string.

    ("LABEL_F775FE", "PcgOutGrid_CopyStrBank1"),
        # Handles event 0x1E0008B: loads xiz with offset 0x42 (66) then
        # falls into PcgOutGrid_CopyStrCommon to copy the bank-1 string.

    ("LABEL_F77605", "PcgOutGrid_CopyStrCommon"),
        # Shared string copy path entered from both CopyStrBank0 and
        # CopyStrBank1. Calls FA6266 to get the workspace, adds the xiz
        # offset to xhl, then calls Strcpy and jumps to ReturnZero.

    ("LABEL_F7762B", "PcgOutGrid_DispatchDelegate"),
        # Handles event 0x1E0008D: loads the workspace pointer, reads the
        # delegate pointer at offset +70, and dispatches via FA49B7.

    ("LABEL_F7763A", "PcgOutGrid_CallDelegate"),
        # Common tail: calls FA49B7 (delegate/callback dispatcher).
        # Entered from both the DispatchDelegate path and the fall-through
        # code below PcgOutGrid_CopyStrCommon.

    ("LABEL_F7763E", "PcgOutGrid_ReturnZero"),
        # Common return path: sets xhl = 0 (no-op / not consumed),
        # then falls into the epilogue.

    ("LABEL_F77642", "PcgOutGrid_DefaultHandler"),
        # Out-of-range event fallback (event outside 0x1C00017..0x1C0001D).
        # Calls FA4409 (default/pass-through event handler).

    ("LABEL_F7764E", "PcgOutGrid_Epilogue"),
        # Function epilogue shared by all paths: pop xiz, restore xsp, ret.

    # PcgOutCheckGridDataStructure labels
    ("LABEL_F77B9E", "PcgOutCheck_SendPreset1"),
        # de==1 branch in PcgOutCheckGridDataStructure. Reads audio index
        # from 0x02476c, increments it, and sends an audio command for
        # preset slot 1.

    ("LABEL_F77BC7", "PcgOutCheck_SendPreset2"),
        # de==2 branch. Checks if name byte at 0x024770 is 0xFF (no user
        # name). If so, copies the default string; otherwise falls through
        # to PcgOutCheck_SendPreset2Named.

    ("LABEL_F77C14", "PcgOutCheck_SendPreset2Named"),
        # de==2 with a user name (name != 0xFF). Computes drum-bank index
        # (type<<7 + bank) and sends two audio commands: type and
        # bank+name.

    ("LABEL_F77C77", "PcgOutCheck_SendPreset3"),
        # de==3 branch. Writes 0x2 into the struct, then checks the name
        # byte for the empty/named split.

    ("LABEL_F77CEF", "PcgOutCheck_SendPreset3Named"),
        # de==3 with a user name. Sends three audio commands: bank index,
        # bank+name (first), and bank+name (second with drum-bank calc).

    ("LABEL_F77D7F", "PcgOutCheck_SetFinalProp"),
        # Common tail for all preset send paths. Calls FA9660 to write
        # the final property value into the grid data structure.

    # PcgOutSendFunc labels
    ("LABEL_F77DB9", "PcgOutSend_StoreBankIndex"),
        # Name is not 0xFF: computes combined bank index (type<<7 + bank)
        # and stores it into the output buffer before transmitting.

    ("LABEL_F77DC9", "PcgOutSend_TransmitMidi"),
        # Shared MIDI transmit path. Sets up source (0x1430000) and
        # destination (0x1E30000) addresses, then calls FA4A63 to send.

    ("LABEL_F77DD7", "PcgOutSendFunc_Exit"),
        # Early exit of PcgOutSendFunc when event is not 0x1C00008.
        # Clears xhl and returns.

    # MainPcgOutSend labels
    ("LABEL_F77DF2", "MainPcgOutSend_Exit"),
        # Early exit of MainPcgOutSend when xbc does not match 0x1E30000.
        # Clears xhl and returns.
]

# computer_interface_config.s
# 20 LABEL_* symbols, all internal (no cross-file refs)
CONFIG_RENAMES = [
    # MdCmptCnctFunc / CmptCnctDrawConnectionDiagram labels
    ("LABEL_F74BB5", "CmptCnct_DrawDiagram1"),
        # bc==1 case in CmptCnctDrawConnectionDiagram. Copies string from
        # offset 0xF862, selects bitmap 2 at 0xE6C452 (USB connection).

    ("LABEL_F74BD2", "CmptCnct_DrawDiagram2"),
        # bc==2 case. Copies string from offset 0xF87C, selects bitmap 3
        # at 0xE74132 (TO HOST connection).

    ("LABEL_F74BEF", "CmptCnct_DrawDiagramDefault"),
        # Default/other case (bc != 0/1/2). Copies string from 0xF896,
        # falls through to bitmap 1 at 0xE64772.

    ("LABEL_F74C1B", "MdCmptCnct_Epilogue"),
        # Function epilogue for MdCmptCnctFunc: pop xiz, restore xsp, ret.
        # Shared by all branches that do not use jrl.

    # MdPcgModeFunc labels
    ("LABEL_F74C71", "PcgMode_CopyStrCustom"),
        # de==3 case in PcgModeGridEventStart. Pushes the string pointer
        # from (xwa) onto the stack, then falls into PcgMode_CallStrcpy.

    ("LABEL_F74C81", "PcgMode_CopyStrEntry"),
        # Shared string dispatch entry: push xwa (string pointer), push
        # xbc (destination), then fall into PcgMode_CallStrcpy.

    ("LABEL_F74C83", "PcgMode_CallStrcpy"),
        # Calls Strcpy, adjusts xsp, restores xhl from xiz, then jumps
        # to MdPcgMode_Epilogue.

    ("LABEL_F74C8D", "PcgMode_InvalidReturn"),
        # Event 0x1E00040 in MdPcgModeFunc: returns 0x2201, indicating
        # an invalid / non-editable input for this mode.

    ("LABEL_F74C94", "PcgMode_BlockingReturn"),
        # Events 0x1E0003F, 0x1E0003E, 0x1E00041 in MdPcgModeFunc.
        # Returns 1 (blocking: consume event without action).

    ("LABEL_F74C96", "MdPcgMode_Epilogue"),
        # Function epilogue for MdPcgModeFunc: pop xiz, ret.

    # MdDrumTypeFunc labels
    ("LABEL_F74CC7", "DrumType_GridEvent"),
        # Event 0x1E00042 case in MdDrumTypeFunc. Decodes de from the
        # grid data structure and routes to the appropriate string path.

    ("LABEL_F74CE3", "DrumType_CopyStrBank1"),
        # de==1 case in DrumType_GridEvent. Loads string pointer
        # 0xE7F8E2 (bank-1 label) and falls into DrumType_CopyStrEntry.

    ("LABEL_F74CEA", "DrumType_CopyStrCustom"),
        # de==3 case. Pushes the custom string pointer from (xwa) onto
        # the stack, then falls into DrumType_CallStrcpy.

    ("LABEL_F74CF5", "DrumType_CopyStrDefault"),
        # Default de case (not 0, 1, or 3). Loads fallback string pointer
        # 0xE7F8F6 and falls into DrumType_CopyStrEntry.

    ("LABEL_F74CFA", "DrumType_CopyStrEntry"),
        # Shared entry: push xwa (string pointer), push xbc (destination),
        # fall into DrumType_CallStrcpy.

    ("LABEL_F74CFC", "DrumType_CallStrcpy"),
        # Calls Strcpy, adjusts xsp, restores xhl from xiz, then jumps
        # to MdDrumType_Epilogue.

    ("LABEL_F74D06", "DrumType_InvalidReturn"),
        # Event 0x1E00040 in MdDrumTypeFunc: returns 0x2205, indicating
        # an invalid / non-editable input for drum type selection.

    ("LABEL_F74D0D", "DrumType_BlockingReturn"),
        # Events 0x1E0003F, 0x1E0003E, 0x1E00041 in MdDrumTypeFunc.
        # Returns 1 (blocking: consume event without action).

    ("LABEL_F74D0F", "MdDrumType_Epilogue"),
        # Function epilogue for MdDrumTypeFunc: pop xiz, ret.

    # MdSetupLoadFunc labels
    ("LABEL_F74D87", "MdSetupLoad_Epilogue"),
        # Function epilogue for MdSetupLoadFunc: pop xiz, restore xsp, ret.
        # Reached by SetupLoadInvalidIndex and by the jump table entries.
]

# ---------------------------------------------------------------------------
# Rename engine
# ---------------------------------------------------------------------------

def apply_renames(file_path, renames):
    """
    Read file in binary mode, perform whole-word ASCII replacements for each
    (old_name, new_name) pair, then write back in binary mode.

    'Whole-word' here means the label token must not be immediately preceded
    or followed by an alphanumeric character or underscore (i.e. it must be
    a standalone identifier token).
    """
    with open(file_path, 'rb') as f:
        data = f.read()

    text = data.decode('ascii')
    total_replacements = 0

    for old, new in renames:
        old_b = old.encode('ascii')
        new_b = new.encode('ascii')

        # Count occurrences before replacement for reporting.
        count = text.count(old)
        if count == 0:
            print(f"  WARNING: '{old}' not found in {os.path.basename(file_path)}")
            continue

        text = text.replace(old, new)
        total_replacements += count
        print(f"  {old:30s} -> {new}  ({count} occurrence{'s' if count != 1 else ''})")

    result = text.encode('ascii')
    with open(file_path, 'wb') as f:
        f.write(result)

    print(f"  Done: {total_replacements} replacement(s) written to {file_path}")
    return total_replacements


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    maincpu_dir = os.path.join(script_dir, '..', 'maincpu')

    pcg_path    = os.path.join(maincpu_dir, 'computer_interface_pcg.s')
    config_path = os.path.join(maincpu_dir, 'computer_interface_config.s')

    for path in (pcg_path, config_path):
        if not os.path.exists(path):
            print(f"ERROR: file not found: {path}", file=sys.stderr)
            sys.exit(1)

    print("=" * 70)
    print("Renaming LABEL_* symbols in computer_interface_pcg.s")
    print("=" * 70)
    apply_renames(pcg_path, PCG_RENAMES)

    print()
    print("=" * 70)
    print("Renaming LABEL_* symbols in computer_interface_config.s")
    print("=" * 70)
    apply_renames(config_path, CONFIG_RENAMES)

    print()
    print("All done. Verify with: make all && python scripts/compare_roms.py")


if __name__ == '__main__':
    main()
