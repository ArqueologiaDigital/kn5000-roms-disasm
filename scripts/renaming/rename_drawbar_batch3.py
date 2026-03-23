#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 3)
Handles labels in LswPartExp, LswLocalControl, LswMidiChannel, IvMesageProc,
AcPleaseWaitProc, CheckLanguage, CheckMessage, MessageText, MessageHeader,
IvAccordionXProc, AcAccordionTabProc, IvSdtecdProc, IvSdtecd1Proc,
LswOrchestrator, and PsLabelBoxProc."""

import sys
import os

# Mapping of old label -> new label
RENAMES = {
    # === LswPartExp sub-labels (lines 7172-7224) ===
    "LABEL_F7DAD9": "LswPartExp_StrDisabled",        # Load string 0xE95648 (disabled state)
    "LABEL_F7DAE0": "LswPartExp_StrOff",              # Load string 0xE9564C (off state)
    "LABEL_F7DAE5": "LswPartExp_StrCopyReturn",       # Push+Strcpy+return via PopIzRet
    "LABEL_F7DAF1": "LswPartExp_PartIdLookup",        # Part ID lookup from table 0xE953CE
    "LABEL_F7DB00": "LswPartExp_SubParam",             # Return sub-parameter 0x604
    "LABEL_F7DB07": "LswPartExp_StepSize",             # Return step size 3
    "LABEL_F7DB0B": "LswPartExp_EnabledCheck",         # Check bit for enabled state
    "LABEL_F7DB17": "LswPartExp_ToggleState",          # Toggle state check (bit 16, unsigned)
    "LABEL_F7DB27": "LswPartExp_SignedToggle",          # Toggle state check (bit 16, signed)

    # === LswLocalControl sub-labels (lines 7272-7321) ===
    "LABEL_F7DBB6": "LswLocal_StrDisabled",            # Load string 0xE95654 (disabled state)
    "LABEL_F7DBBD": "LswLocal_StrOff",                 # Load string 0xE95658 (off state)
    "LABEL_F7DBC2": "LswLocal_StrCopyReturn",          # Push+Strcpy+return via PopIzRet
    "LABEL_F7DBCE": "LswLocal_PartIdLookup",           # Part ID lookup from table 0xE953CE
    "LABEL_F7DBDD": "LswLocal_SubParam",               # Return sub-parameter 0x400
    "LABEL_F7DBE4": "LswLocal_StepSize",               # Return step size 3
    "LABEL_F7DBE8": "LswLocal_EnabledCheck",           # Check bit 0 for enabled state
    "LABEL_F7DBF3": "LswLocal_ToggleState",            # Toggle state (bit 0 set -> -1)
    "LABEL_F7DBFA": "LswLocal_ReturnMinusOne",         # Return 0xFFFFFFFF (-1)
    "LABEL_F7DC01": "LswLocal_SignedToggle",           # Signed toggle (bit 0 -> signed extend)

    # === LswMidiChannel sub-labels (lines 7390-7441) ===
    "LABEL_F7DCBD": "LswMidi_StrChannelAlt",          # Load string 0xE95662 (alt channel)
    "LABEL_F7DCC6": "LswMidi_StrOff",                 # Load string 0xE95668 (off state)
    "LABEL_F7DCD0": "LswMidi_StrCopyReturn",          # Strcpy and return path
    "LABEL_F7DCD6": "LswMidi_LoadReturnValue",        # Load return value from stack
    "LABEL_F7DCDB": "LswMidi_PartIdLookup",           # Part ID lookup from table 0xE953CE
    "LABEL_F7DCE7": "LswMidi_SubParam",               # Return sub-parameter 0x401
    "LABEL_F7DCEE": "LswMidi_StepSize",               # Return step size 3
    "LABEL_F7DCF2": "LswMidi_EnabledCheck",           # Check bit 1 for enabled state
    "LABEL_F7DCFD": "LswMidi_ToggleState",            # Toggle state (bit 1 -> unsigned)
    "LABEL_F7DD0D": "LswMidi_SignedToggle",           # Signed toggle (bit 1 -> signed)

    # === IvMesageProc sub-labels (lines 7499-7554) ===
    "LABEL_F7DDC4": "IvMessage_Close",                # Handle close event (0x1C00002)
    "LABEL_F7DDC8": "IvMessage_ShowHide",             # Handle show/hide (0x1C0000C/0x1C0000B)
    "LABEL_F7DDCA": "IvMessage_CallInherited",        # Call InheritedProc shared path
    "LABEL_F7DDD0": "IvMessage_Paint",                # Handle paint event (0x1C0000D)
    "LABEL_F7DDF9": "IvMessage_SendEvent",            # Call SendEvent shared path
    "LABEL_F7DDFF": "IvMessage_SelectionChange",      # Handle selection change (0x1E000B6)
    "LABEL_F7DE2F": "IvMessage_GetText",              # Get text (0x1E0003A) - Strcpy 0xE9D7C6
    "LABEL_F7DE40": "IvMessage_ForwardToBase",        # Forward to InheritedProc (default)
    "LABEL_F7DE46": "IvMessage_Epilogue",             # Pop xiz, ret

    # === AcPleaseWaitProc sub-labels (lines 7580-7695) ===
    "LABEL_F7DE8C": "PleaseWait_Init",                # Handle init event (0x1C00001)
    "LABEL_F7DE9D": "PleaseWait_Close",               # Handle close event (0x1C00002)
    "LABEL_F7DEBD": "PleaseWait_InheritedReturn",     # Call InheritedProc then return
    "LABEL_F7DEC4": "PleaseWait_Paint",               # Handle paint event (0x1C0000D)
    "LABEL_F7DEE1": "PleaseWait_Confirm",             # Handle confirm event (0x1C0000F)
    "LABEL_F7DF0D": "PleaseWait_GetText",             # Handle get text (0x1E0003A)
    "LABEL_F7DF36": "PleaseWait_DotFillLoop",         # Fill with dots (0x2E) loop
    "LABEL_F7DF45": "PleaseWait_BuildScrollStr",      # Build scrolling string
    "LABEL_F7DF82": "PleaseWait_OverflowPath",        # Overflow path (hl >= de)
    "LABEL_F7DF95": "PleaseWait_Strncpy",             # Call Strncpy for truncation
    "LABEL_F7DF9E": "PleaseWait_Epilogue",            # Pop xiz, clean stack, ret

    # === CheckLanguage sub-labels (lines 7718-7767) ===
    "LABEL_F7DFDC": "CheckLang_SkipLang4",            # Skip language 4 (decrement path)
    "LABEL_F7DFEE": "CheckLang_Increment",            # Increment language counter
    "LABEL_F7DFFB": "CheckLang_SkipLang4Up",          # Skip language 4 (increment path)
    "LABEL_F7E01D": "CheckLang_GetTextStr",           # Get text string from table 0xE9D846
    "LABEL_F7E03C": "CheckLang_ReturnZero",           # Return zero
    "LABEL_F7E03F": "CheckLang_ReturnAddress",        # Return address of language byte
    "LABEL_F7E045": "CheckLang_ReturnOne",            # Return 1 (count)

    # === CheckMessage sub-labels (lines 7802-7846) ===
    "LABEL_F7E0B3": "CheckMsg_IncrementCheck",        # Check if next message exists
    "LABEL_F7E0FF": "CheckMsg_AudioCommand",          # Send Sprintf_Locked for text
    "LABEL_F7E115": "CheckMsg_ReturnZero",            # Return zero (default)
    "LABEL_F7E119": "CheckMsg_ReturnAddress",         # Return address of 0x02478C
    "LABEL_F7E120": "CheckMsg_ReturnTwo",             # Return 2 (count)
    "LABEL_F7E122": "CheckMsg_Epilogue",              # Pop xiz, ret

    # === MessageText sub-labels (lines 7856-7887) ===
    "LABEL_F7E12F": "MsgText_LookupMessage",          # Lookup message by index
    "LABEL_F7E149": "MsgText_CheckLanguage",          # Check language for message 0x1A
    "LABEL_F7E15F": "MsgText_Lang1",                  # Language 1 string 0xE981B8
    "LABEL_F7E166": "MsgText_Lang2",                  # Language 2 string 0xE98382
    "LABEL_F7E16D": "MsgText_Lang3",                  # Language 3 string 0xE9855C
    "LABEL_F7E172": "MsgText_Return",                 # Return after language selection

    # === MessageHeader sub-labels (lines 7898-7964) ===
    "LABEL_F7E183": "MsgHeader_BuildHeader",          # Build header with Malloc/PostEvent
    "LABEL_F7E1BF": "MsgHeader_BuildLoop",            # Loop building header entries
    "LABEL_F7E249": "MsgHeader_SingleEntry",          # Single entry (non-3 type)
    "LABEL_F7E24C": "MsgHeader_Epilogue",             # Pop xiz, clean stack, ret

    # === IvAccordionXProc sub-labels (lines 8310-8346) ===
    "LABEL_F7E67F": "AccordionX_PageSelect",          # Handle page select (0x1C00029)
    "LABEL_F7E6A8": "AccordionX_Paint",               # Handle paint (0x1C0000D)
    "LABEL_F7E6C0": "AccordionX_GetText",             # Get text (0x1E0003A) - Strcpy 0xE9D9C0
    "LABEL_F7E6D2": "AccordionX_Epilogue",            # Pop xiz, clean stack, ret

    # === AcAccordionTabProc sub-labels (lines 8361-8456) ===
    "LABEL_F7E6ED": "AccTab_Confirm",                 # Handle confirm (0x1C0000F)
    "LABEL_F7E746": "AccTab_DrawInactive",            # Draw tab inactive (value == 0)
    "LABEL_F7E752": "AccTab_DrawCentered",            # DrawStringCentered call point
    "LABEL_F7E7B6": "AccTab_DrawSecondInactive",      # Draw second tab inactive
    "LABEL_F7E7BF": "AccTab_DrawSecondCentered",      # Second DrawStringCentered call
    "LABEL_F7E7D6": "AccTab_Epilogue",                # Pop xiz, clean stack, ret

    # === IvSdtecdProc sub-labels (lines 8479-8536) ===
    "LABEL_F7E80E": "Sdtecd_Init",                    # Handle init (0x1C00001)
    "LABEL_F7E837": "Sdtecd_InitCase3",               # Init case 3 (SndParam voice lookup)
    "LABEL_F7E86F": "Sdtecd_Paint",                   # Handle paint (0x1C0000D)
    "LABEL_F7E88B": "Sdtecd_GetText",                 # Get text (0x1E0003A) - Strcpy 0xE9D9C6
    "LABEL_F7E89B": "Sdtecd_ReturnZero",              # Return zero
    "LABEL_F7E89D": "Sdtecd_Epilogue",                # Pop xiz, clean stack, ret

    # === IvSdtecd1Proc sub-labels (lines 8585-8722) ===
    "LABEL_F7E93E": "Sdtecd1_ScrollDown",             # Handle scroll down (0x1C00019/0x1C00017)
    "LABEL_F7E995": "Sdtecd1_ScrollDown_Lookup",      # Lookup part for scroll down
    "LABEL_F7E9CB": "Sdtecd1_ScrollUp",               # Handle scroll up (0x1C0001A/0x1C00018)
    "LABEL_F7EA21": "Sdtecd1_ScrollUp_Lookup",        # Lookup part for scroll up
    "LABEL_F7EA51": "Sdtecd1_PutAndReturn",           # MainLswPut then return
    "LABEL_F7EA57": "Sdtecd1_Match",                  # Handle match (0x1C0001C)
    "LABEL_F7EA83": "Sdtecd1_Paint",                  # Handle paint (0x1C0000D)
    "LABEL_F7EA96": "Sdtecd1_SendEventReturn",        # Send event then return
    "LABEL_F7EA9C": "Sdtecd1_GetText",                # Get text (0x1E0003A) - Strcpy 0xE9DA22
    "LABEL_F7EAAD": "Sdtecd1_ForwardToBase",          # Forward to InheritedProc
    "LABEL_F7EAB6": "Sdtecd1_Epilogue",               # Pop xiz, clean stack, ret

    # === LswOrchestrator sub-labels (lines 8752-8775) ===
    "LABEL_F7EB09": "LswOrch_StrDefault",             # Load default string 0xE9DB16
    "LABEL_F7EB0F": "LswOrch_StrCopyReturn",          # Strcpy+return via PopIzRet
    "LABEL_F7EB1A": "LswOrch_SubParam",               # Return sub-parameter 0x4201
    "LABEL_F7EB21": "LswOrch_StepSize",               # Return step size 3
    "LABEL_F7EB25": "LswOrch_ReturnOne",              # Return 1 (enabled/toggle)
    "LABEL_F7EB29": "LswOrch_ReturnZero",             # Return zero (default)
}

def main():
    files_to_update = set()
    main_file = "/mnt/shared/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s"
    files_to_update.add(main_file)

    total_replacements = 0
    for filepath in sorted(files_to_update):
        with open(filepath, 'rb') as f:
            data = f.read()

        original = data
        file_replacements = 0
        for old_label, new_label in RENAMES.items():
            old_bytes = old_label.encode('ascii')
            new_bytes = new_label.encode('ascii')
            count = data.count(old_bytes)
            if count > 0:
                data = data.replace(old_bytes, new_bytes)
                file_replacements += count

        if data != original:
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f"  {filepath}: {file_replacements} replacements")
            total_replacements += file_replacements
        else:
            print(f"  {filepath}: no changes")

    print(f"\nTotal: {total_replacements} replacements across {len(files_to_update)} files")
    print(f"Labels renamed: {len(RENAMES)}")

if __name__ == "__main__":
    main()
