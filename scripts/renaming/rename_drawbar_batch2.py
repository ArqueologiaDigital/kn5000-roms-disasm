#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in drawbar_panel_ui.s (batch 2)
Covers AudioCtrlSliderProc, all Lsw* handlers (LswSound through LswVelocity),
and AcDrawbarLswCtrlProc inner labels."""

import sys

# Each Lsw* handler has identical internal structure with sub-labels for:
#   _InactiveStr    - inactive/disabled string display
#   _ActiveStr      - active/enabled string display
#   _CopyStr        - copy string and return
#   _ReturnThis     - return xiz
#   _GetPartId      - get part ID from table (0x1E10000)
#   _GetSubParam    - get sub-parameter lookup (0x1E10001)
#   _StepSize       - step size for 0x1E00041
#   _CheckEnabled   - check enabled bit for 0x1E0003E
#   _StepReturn     - return step size 4
#   _GetToggle      - get toggle state for 0x1E0003F
#   _GetSignedTgl   - get signed toggle for 0x1E10002
# Some also have extra labels for _CenterVal, _MinVal etc.

RENAMES = {
    # === AudioCtrlSliderProc remaining labels (lines 4487-5067) ===
    "LABEL_F7C18B": "AudioCtrl_InitPartPanDisplay",   # Get view, lookup part via 0x1E10000
    "LABEL_F7C208": "AudioCtrl_UnboundedPart",        # Part ID == 0xFFFF, unbounded lookup
    "LABEL_F7C227": "AudioCtrl_HighPartOffset",       # Part >= 0x80, apply offset
    "LABEL_F7C299": "AudioCtrl_CallMainLswPartPut",   # Call MainLswPartPut, return
    "LABEL_F7C2A0": "AudioCtrl_HighPartUnbounded",    # High part unbounded lookup
    "LABEL_F7C2F9": "AudioCtrl_DualPartNavigate",     # Dual-part navigation handler
    "LABEL_F7C381": "AudioCtrl_DualPartHighOffset",   # Dual-part high offset handling
    "LABEL_F7C3BF": "AudioCtrl_DualPartUnbounded",    # Dual-part unbounded lookup
    "LABEL_F7C409": "AudioCtrl_DualPartResolve",      # Resolve dual-part sub-parameter
    "LABEL_F7C434": "AudioCtrl_CallMainLswPut",       # Call MainLswPut, return
    "LABEL_F7C43B": "AudioCtrl_InitPartSelection",    # Init part selection via view
    "LABEL_F7C4B9": "AudioCtrl_UnboundedPartSel",     # Unbounded part selection
    "LABEL_F7C4F2": "AudioCtrl_MergeAndForward",      # Merge result and call InheritedProc
    "LABEL_F7C50D": "AudioCtrl_InheritAndConfirm",    # InheritedProc then send 0x1C0000F
    "LABEL_F7C527": "AudioCtrl_MidiMatchHandler",     # Handle MIDI address match
    "LABEL_F7C5AC": "AudioCtrl_StoreValue",           # Store value without bit 7
    "LABEL_F7C5B0": "AudioCtrl_ConfirmAndReturn",     # Send 0x1C0000F and return
    "LABEL_F7C5BD": "AudioCtrl_CheckSecondPart",      # Check second part match
    "LABEL_F7C5EF": "AudioCtrl_ClearHighBit",         # Clear bit 7 (AND 0xFF7F)
    "LABEL_F7C5F9": "AudioCtrl_ConfirmAndReturn2",    # Send 0x1C0000F and return (2)
    "LABEL_F7C606": "AudioCtrl_UnboundedMatch",       # Unbounded MIDI match
    "LABEL_F7C638": "AudioCtrl_StoreUnbounded",       # Store unbounded value
    "LABEL_F7C63C": "AudioCtrl_ConfirmAndReturn3",    # Send 0x1C0000F and return (3)
    "LABEL_F7C649": "AudioCtrl_CheckSecondUnbounded",  # Check second part unbounded
    "LABEL_F7C67C": "AudioCtrl_ClearHighBitUnbd",     # Clear bit 7 unbounded
    "LABEL_F7C682": "AudioCtrl_ConfirmAndReturn4",    # Send 0x1C0000F and return (4)
    "LABEL_F7C68F": "AudioCtrl_GetMinLimit",          # Get min limit via 0x1E0003E
    "LABEL_F7C6D7": "AudioCtrl_GetMaxLimit",          # Get max limit via 0x1E0003F
    "LABEL_F7C71F": "AudioCtrl_GetNegMin",            # Get negated min via 0x1E0003E
    "LABEL_F7C76E": "AudioCtrl_GetNegMax",            # Get negated max via 0x1E0003F
    "LABEL_F7C7BB": "AudioCtrl_GetToggleState",       # Get toggle with bit 7 set
    "LABEL_F7C7FC": "AudioCtrl_ForwardInherited",     # Forward to InheritedProc
    "LABEL_F7C809": "AudioCtrl_Epilogue",             # pop xiz, restore stack, ret

    # === LswSound (lines 5427-5516) ===
    "LABEL_F7CC28": "LswSound_ReturnThis",            # Return xiz
    "LABEL_F7CC2C": "LswSound_GetPartId",             # Get part ID from table
    "LABEL_F7CC3B": "LswSound_LookupPartOffset",      # Lookup part offset from table
    "LABEL_F7CC4A": "LswSound_CheckActive",           # Check bit 15 active
    "LABEL_F7CC52": "LswSound_StepReturn",            # Return step size 4
    "LABEL_F7CC56": "LswSound_GetToggle",             # Get toggle state (bit 31)
    "LABEL_F7CC66": "LswSound_GetSignedToggle",       # Get signed toggle

    # === LswVolume (lines 5518-5641) ===
    "LABEL_F7CD04": "LswVolume_OverflowStr",          # Load overflow string 0xE9558C
    "LABEL_F7CD0B": "LswVolume_InactiveStr",          # Load inactive string 0xE95592
    "LABEL_F7CD10": "LswVolume_CopyStr",              # Copy string and return
    "LABEL_F7CD18": "LswVolume_ReturnThis",           # Return xiz
    "LABEL_F7CD1C": "LswVolume_GetPartId",            # Get part ID from table
    "LABEL_F7CD2B": "LswVolume_LookupPartOffset",     # Lookup part offset
    "LABEL_F7CD3A": "LswVolume_GetSubParam",          # Get sub-parameter (special case 0x17)
    "LABEL_F7CD49": "LswVolume_DefaultSubParam",      # Default sub-parameter 7
    "LABEL_F7CD4D": "LswVolume_StepSize",             # Step size (special case 0x18)
    "LABEL_F7CD59": "LswVolume_CheckEnabled",         # Check bit 15 enabled
    "LABEL_F7CD60": "LswVolume_StepReturn",           # Return step size 4
    "LABEL_F7CD64": "LswVolume_GetToggle",            # Get toggle (bit 15)
    "LABEL_F7CD74": "LswVolume_GetSignedToggle",      # Get signed toggle

    # === LswMute (lines 5643-5762) ===
    "LABEL_F7CE12": "LswMute_OverflowStr",            # Load overflow string 0xE9559C
    "LABEL_F7CE19": "LswMute_InactiveStr",            # Load inactive string 0xE955A2
    "LABEL_F7CE1E": "LswMute_CopyStr",                # Copy string
    "LABEL_F7CE26": "LswMute_ReturnThis",             # Return xiz
    "LABEL_F7CE2A": "LswMute_GetPartId",              # Get part ID
    "LABEL_F7CE39": "LswMute_LookupPartOffset",       # Lookup part offset
    "LABEL_F7CE48": "LswMute_GetSubParam",            # Get sub-param (special 0x17)
    "LABEL_F7CE57": "LswMute_DefaultSubParam",        # Default sub-param 8
    "LABEL_F7CE5E": "LswMute_StepSize",               # Step size 3
    "LABEL_F7CE62": "LswMute_CheckEnabled",           # Check bit 15
    "LABEL_F7CE6D": "LswMute_GetToggle",              # Get toggle
    "LABEL_F7CE7D": "LswMute_GetSignedToggle",        # Get signed toggle

    # === LswPan (lines 5764-5890) ===
    "LABEL_F7CF2E": "LswPan_FormatOffset",            # Format pan offset (!=0x40)
    "LABEL_F7CF41": "LswPan_FormatRight",             # Format right pan (>0x40)
    "LABEL_F7CF4B": "LswPan_SendCommand",             # Send Sprintf_Locked
    "LABEL_F7CF56": "LswPan_InactiveStr",             # Load inactive string
    "LABEL_F7CF5B": "LswPan_CopyStr",                 # Copy string
    "LABEL_F7CF63": "LswPan_ReturnThis",              # Return xiz
    "LABEL_F7CF67": "LswPan_GetPartId",               # Get part ID
    "LABEL_F7CF76": "LswPan_GetSubParam",             # Get sub-param 0xA
    "LABEL_F7CF7D": "LswPan_CheckEnabled",            # Check bit 14
    "LABEL_F7CF82": "LswPan_StepReturn",              # Return step size 4
    "LABEL_F7CF86": "LswPan_GetToggle",               # Get toggle (bit 14)
    "LABEL_F7CF8E": "LswPan_GetSignedToggle",         # Get signed toggle
    "LABEL_F7CF9A": "LswPan_ReturnOne",               # Return 1 (0x1E000B8)
    "LABEL_F7CF9E": "LswPan_ReturnCenter",            # Return center 0x40 (0x1E000B9)

    # === LswReverb (lines 5892-6006) ===
    "LABEL_F7D028": "LswReverb_InactiveStr",          # Load inactive string
    "LABEL_F7D035": "LswReverb_ReturnThis",           # Return xiz
    "LABEL_F7D039": "LswReverb_GetPartId",            # Get part ID
    "LABEL_F7D048": "LswReverb_LookupPartOffset",     # Lookup part offset
    "LABEL_F7D057": "LswReverb_GetSubParam",          # Get sub-param (special 0x17)
    "LABEL_F7D066": "LswReverb_DefaultSubParam",      # Default sub-param 0x5B
    "LABEL_F7D06D": "LswReverb_StepSize",             # Step size (special 0x17)
    "LABEL_F7D079": "LswReverb_CheckEnabled",         # Check bit 13
    "LABEL_F7D080": "LswReverb_StepReturn",           # Return step size 4
    "LABEL_F7D084": "LswReverb_GetToggle",            # Get toggle (bit 13)
    "LABEL_F7D094": "LswReverb_GetSignedToggle",      # Get signed toggle

    # === LswDSPEffect (lines 6008-6103) ===
    "LABEL_F7D128": "LswDSPEff_InactiveStr",          # Load inactive string
    "LABEL_F7D135": "LswDSPEff_ReturnThis",           # Return xiz
    "LABEL_F7D139": "LswDSPEff_GetPartId",            # Get part ID
    "LABEL_F7D148": "LswDSPEff_GetSubParam",          # Get sub-param 0x5D
    "LABEL_F7D14F": "LswDSPEff_CheckEnabled",         # Check bit 12
    "LABEL_F7D156": "LswDSPEff_StepReturn",           # Return step size 4
    "LABEL_F7D15A": "LswDSPEff_GetToggle",            # Get toggle (bit 12)
    "LABEL_F7D16A": "LswDSPEff_GetSignedToggle",      # Get signed toggle

    # === LswDigitalEffect (lines 6105-6201) ===
    "LABEL_F7D1FA": "LswDigEff_StrOff",               # Load "off" string
    "LABEL_F7D201": "LswDigEff_InactiveStr",          # Load inactive string
    "LABEL_F7D206": "LswDigEff_CopyStr",              # Copy string
    "LABEL_F7D212": "LswDigEff_GetPartId",            # Get part ID
    "LABEL_F7D221": "LswDigEff_GetSubParam",          # Get sub-param 0x5E
    "LABEL_F7D228": "LswDigEff_CheckEnabled",         # Check bit 3
    "LABEL_F7D22F": "LswDigEff_StepReturn",           # Return step size 4
    "LABEL_F7D233": "LswDigEff_GetToggle",            # Get toggle (bit 3)
    "LABEL_F7D243": "LswDigEff_GetSignedToggle",      # Get signed toggle

    # === LswSustain (lines 6203-6299) ===
    "LABEL_F7D2D3": "LswSust_StrOff",                 # Load "off" string
    "LABEL_F7D2DA": "LswSust_InactiveStr",            # Load inactive string
    "LABEL_F7D2DF": "LswSust_CopyStr",                # Copy string
    "LABEL_F7D2EB": "LswSust_GetPartId",              # Get part ID
    "LABEL_F7D2FA": "LswSust_GetSubParam",            # Get sub-param 0x40
    "LABEL_F7D301": "LswSust_CheckEnabled",           # Check bit 11
    "LABEL_F7D308": "LswSust_StepReturn",             # Return step size 4
    "LABEL_F7D30C": "LswSust_GetToggle",              # Get toggle (bit 11)
    "LABEL_F7D31C": "LswSust_GetSignedToggle",        # Get signed toggle

    # === LswSustainLength (lines 6301-6398) ===
    "LABEL_F7D3B4": "LswSustLen_InactiveStr",         # Load inactive string
    "LABEL_F7D3C1": "LswSustLen_ReturnThis",          # Return xiz
    "LABEL_F7D3C5": "LswSustLen_GetPartId",           # Get part ID
    "LABEL_F7D3D4": "LswSustLen_GetSubParam",         # Get sub-param 0x600
    "LABEL_F7D3DB": "LswSustLen_CheckEnabled",        # Check bit 10
    "LABEL_F7D3E2": "LswSustLen_StepReturn",          # Return step size 4
    "LABEL_F7D3E6": "LswSustLen_GetToggle",           # Get toggle (bit 10)
    "LABEL_F7D3F6": "LswSustLen_GetSignedToggle",     # Get signed toggle

    # === LswKeyShift (lines 6400-6516) ===
    "LABEL_F7D4A6": "LswKeyShift_ZeroStr",            # Load zero-offset string
    "LABEL_F7D4AD": "LswKeyShift_InactiveStr",        # Load inactive string
    "LABEL_F7D4B2": "LswKeyShift_CopyStr",            # Copy string
    "LABEL_F7D4BA": "LswKeyShift_ReturnThis",         # Return xiz
    "LABEL_F7D4BE": "LswKeyShift_GetPartId",          # Get part ID
    "LABEL_F7D4CD": "LswKeyShift_GetSubParam",        # Get sub-param 0x82
    "LABEL_F7D4D4": "LswKeyShift_CheckEnabled",       # Check bit 9
    "LABEL_F7D4DB": "LswKeyShift_StepReturn",         # Return step size 4
    "LABEL_F7D4DF": "LswKeyShift_GetToggle",          # Get toggle (bit 9)
    "LABEL_F7D4EF": "LswKeyShift_GetSignedToggle",    # Get signed toggle
    "LABEL_F7D503": "LswKeyShift_ReturnOne",          # Return 1 (0x1E000B8)
    "LABEL_F7D507": "LswKeyShift_ReturnCenter",       # Return center 0x40 (0x1E000B9)

    # === LswTuning (lines 6518-6634) ===
    "LABEL_F7D5AA": "LswTuning_ZeroStr",              # Load zero-offset string
    "LABEL_F7D5B1": "LswTuning_InactiveStr",          # Load inactive string
    "LABEL_F7D5B6": "LswTuning_CopyStr",              # Copy string
    "LABEL_F7D5BE": "LswTuning_ReturnThis",           # Return xiz
    "LABEL_F7D5C2": "LswTuning_GetPartId",            # Get part ID
    "LABEL_F7D5D1": "LswTuning_GetSubParam",          # Get sub-param 0x81
    "LABEL_F7D5D8": "LswTuning_CheckEnabled",         # Check bit 8
    "LABEL_F7D5DF": "LswTuning_StepReturn",           # Return step size 4
    "LABEL_F7D5E3": "LswTuning_GetToggle",            # Get toggle (bit 8)
    "LABEL_F7D5F3": "LswTuning_GetSignedToggle",      # Get signed toggle
    "LABEL_F7D607": "LswTuning_ReturnOne",            # Return 1 (0x1E000B8)
    "LABEL_F7D60B": "LswTuning_ReturnCenter",         # Return center 0x80 (0x1E000B9)

    # === LswBendRange (lines 6636-6731) ===
    "LABEL_F7D692": "LswBendRng_InactiveStr",         # Load inactive string
    "LABEL_F7D69F": "LswBendRng_ReturnThis",          # Return xiz
    "LABEL_F7D6A3": "LswBendRng_GetPartId",           # Get part ID
    "LABEL_F7D6B2": "LswBendRng_GetSubParam",         # Get sub-param 0x80
    "LABEL_F7D6B9": "LswBendRng_CheckEnabled",        # Check bit 7
    "LABEL_F7D6C0": "LswBendRng_StepReturn",          # Return step size 4
    "LABEL_F7D6C4": "LswBendRng_GetToggle",           # Get toggle (bit 7)
    "LABEL_F7D6D4": "LswBendRng_GetSignedToggle",     # Get signed toggle

    # === LswGlidePedal (lines 6733-6831) ===
    "LABEL_F7D764": "LswGlide_StrOff",                # Load "off" string
    "LABEL_F7D76B": "LswGlide_InactiveStr",           # Load inactive string
    "LABEL_F7D770": "LswGlide_CopyStr",               # Copy string
    "LABEL_F7D77C": "LswGlide_GetPartId",             # Get part ID
    "LABEL_F7D78B": "LswGlide_GetSubParam",           # Get sub-param 0x603
    "LABEL_F7D792": "LswGlide_StepSize",              # Step size 3
    "LABEL_F7D796": "LswGlide_CheckEnabled",          # Check bit 6
    "LABEL_F7D7A1": "LswGlide_GetToggle",             # Get toggle (bit 6)
    "LABEL_F7D7B1": "LswGlide_GetSignedToggle",       # Get signed toggle

    # === LswSustainPedal (lines 6833-6931) ===
    "LABEL_F7D841": "LswSustPedal_StrOff",            # Load "off" string
    "LABEL_F7D848": "LswSustPedal_InactiveStr",       # Load inactive string
    "LABEL_F7D84D": "LswSustPedal_CopyStr",           # Copy string
    "LABEL_F7D859": "LswSustPedal_GetPartId",         # Get part ID
    "LABEL_F7D868": "LswSustPedal_GetSubParam",       # Get sub-param 0x601
    "LABEL_F7D86F": "LswSustPedal_StepSize",          # Step size 3
    "LABEL_F7D873": "LswSustPedal_CheckEnabled",      # Check bit 5
    "LABEL_F7D87E": "LswSustPedal_GetToggle",         # Get toggle (bit 5)
    "LABEL_F7D88E": "LswSustPedal_GetSignedToggle",   # Get signed toggle

    # === LswKeyScaling (lines 6933-7031) ===
    "LABEL_F7D91E": "LswKeyScale_StrOff",             # Load "off" string
    "LABEL_F7D925": "LswKeyScale_InactiveStr",        # Load inactive string
    "LABEL_F7D92A": "LswKeyScale_CopyStr",            # Copy string
    "LABEL_F7D936": "LswKeyScale_GetPartId",          # Get part ID
    "LABEL_F7D945": "LswKeyScale_GetSubParam",        # Get sub-param 0x602
    "LABEL_F7D94C": "LswKeyScale_StepSize",           # Step size 3
    "LABEL_F7D950": "LswKeyScale_CheckEnabled",       # Check bit 4
    "LABEL_F7D95B": "LswKeyScale_GetToggle",          # Get toggle (bit 4)
    "LABEL_F7D96B": "LswKeyScale_GetSignedToggle",    # Get signed toggle

    # === LswAfterTouch (lines 7033-7131) ===
    "LABEL_F7D9FB": "LswAfterTouch_StrOff",           # Load "off" string
    "LABEL_F7DA02": "LswAfterTouch_InactiveStr",      # Load inactive string
    "LABEL_F7DA07": "LswAfterTouch_CopyStr",          # Copy string
    "LABEL_F7DA13": "LswAfterTouch_GetPartId",        # Get part ID
    "LABEL_F7DA22": "LswAfterTouch_GetSubParam",      # Get sub-param 0x606
    "LABEL_F7DA29": "LswAfterTouch_StepSize",         # Step size 3
    "LABEL_F7DA2D": "LswAfterTouch_CheckEnabled",     # Check bit 2
    "LABEL_F7DA38": "LswAfterTouch_GetToggle",        # Get toggle (bit 2)
    "LABEL_F7DA48": "LswAfterTouch_GetSignedToggle",  # Get signed toggle
}

def main():
    files_to_update = [
        "/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/ui/drawbar_panel_ui.s",
    ]

    total_replacements = 0
    for filepath in files_to_update:
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
