#!/usr/bin/env python3
"""
rename_misc_routines_labels.py - Rename LABEL_* symbols in three misc routine files.

Files handled:
  maincpu/sound_editor_routines.s  (19 LABEL_* symbols)
  maincpu/midi_encoder_routines.s  (7 LABEL_* symbols)
  maincpu/sysex_routines.s         (6 LABEL_* symbols)

All file I/O uses binary mode with ASCII encoding.

Analysis of each LABEL_*:

--- sound_editor_routines.s ---

  LABEL_F9AE97  (call target only, defined in kn5000_v10_program.s)
    - Called by every *TitleFunc in this file (32 call sites total)
    - In the main program: LABEL_F9AE97 shares the same address as DirmdEmulator
      (the display immediate-mode renderer). No code exists between the two labels.
    - Convention: use DirmdEmulator_Entry to reflect the alternate-entry nature.
    -> DirmdEmulator_Entry

  LABEL_F039B7  (data block immediately following SeAmpAmp2TitleFunc)
    - Follows the same naming pattern used for every other TitleFunc display data
      block in this file (e.g. SeMenuTitleFunc_DisplayData, SeTonTon1TitleFunc_DisplayData).
    - SeAmpAmp2TitleFunc copies from xiy into its local stack frame then calls
      DirmdEmulator_Entry; this block is the display descriptor for that title.
    -> SeAmpAmp2TitleFunc_DisplayData

  LABEL_F039EA  (data block immediately following SeAmpEnv1TitleFunc)
    -> SeAmpEnv1TitleFunc_DisplayData

  LABEL_F03A1D  (data block immediately following SeAmpEnv2TitleFunc)
    -> SeAmpEnv2TitleFunc_DisplayData

  LABEL_F03A50  (data block immediately following SeAmpLfo1TitleFunc)
    -> SeAmpLfo1TitleFunc_DisplayData

  LABEL_F03A83  (data block immediately following SeFilLpq1TitleFunc)
    -> SeFilLpq1TitleFunc_DisplayData

  LABEL_F03AB6  (data block immediately following SeFilHpq1TitleFunc)
    -> SeFilHpq1TitleFunc_DisplayData

  LABEL_F03AE9  (data block immediately following SeFilL241TitleFunc)
    -> SeFilL241TitleFunc_DisplayData

  LABEL_F03B1C  (data block immediately following SeFilH241TitleFunc)
    -> SeFilH241TitleFunc_DisplayData

  LABEL_F03B4F  (data block immediately following SeFilBpf1TitleFunc)
    -> SeFilBpf1TitleFunc_DisplayData

  LABEL_F03B82  (data block immediately following SeFilBcf1TitleFunc)
    -> SeFilBcf1TitleFunc_DisplayData

  LABEL_F03BB5  (data block immediately following SeFilFil2TitleFunc)
    -> SeFilFil2TitleFunc_DisplayData

  LABEL_F03BE8  (data block immediately following SeFilEnv1TitleFunc)
    -> SeFilEnv1TitleFunc_DisplayData

  LABEL_F03C1B  (data block immediately following SeFilEnv2TitleFunc)
    -> SeFilEnv2TitleFunc_DisplayData

  LABEL_F03C4E  (data block immediately following SeFilLfo1TitleFunc)
    -> SeFilLfo1TitleFunc_DisplayData

  LABEL_F03C81  (data block immediately following SeDigEffTitleFunc)
    -> SeDigEffTitleFunc_DisplayData

  LABEL_F03CB4  (data block immediately following SeCtr2TitleFunc)
    -> SeCtr2TitleFunc_DisplayData

  LABEL_F03CE7  (data block immediately following SeCtr3TitleFunc)
    -> SeCtr3TitleFunc_DisplayData

  LABEL_F03D1A  (data block immediately following SeCopyTitleFunc)
    -> SeCopyTitleFunc_DisplayData

  LABEL_F03D4D  (data block immediately following SeWrtMemTitleFunc)
    -> SeWrtMemTitleFunc_DisplayData

--- midi_encoder_routines.s ---

  LABEL_FF0C18  (call target only, defined in kn5000_v10_program.s)
    - Called after XWA/XBC are loaded as dividend/divisor; divides XWA by XBC
      (32-bit unsigned division with overflow guard). Used for range scaling.
    -> Math_DivideU32

  LABEL_FF0A5C  (call target only, defined in kn5000_v10_program.s)
    - Loads two register pairs from memory (E2/E6 scratch slots), multiplies
      XHL*XBC and XDE*XWA, accumulates their sum into XHL, then does a final
      XWA*XBC accumulate. Bilinear multiply-accumulate helper.
    -> Math_MultiplyAccumulate

  LABEL_FC6CAE  (address immediately past the last instruction of Encoder_ProcessModwheel)
    - No code or data follows before the next function comment.
      Acts as an end-of-function boundary marker (size/range computation target).
    -> Encoder_ProcessModwheel_End

  LABEL_FC6D2D  (address immediately past the last instruction of Encoder_ClampScaleAndNormalize)
    -> Encoder_ClampScaleAndNormalize_End

  LABEL_FC6D9F  (address immediately past the last instruction of Encoder_ProcessBreath)
    -> Encoder_ProcessBreath_End

  LABEL_FC6DC9  (address immediately past the last instruction of Encoder_ProcessFoot)
    -> Encoder_ProcessFoot_End

  LABEL_FC6DE9  (address immediately past the last instruction of Encoder_ProcessExpression)
    -> Encoder_ProcessExpression_End

  LABEL_FC6DEE  (address immediately past the last instruction of Encoder_PassthroughIdentity)
    -> Encoder_PassthroughIdentity_End

  LABEL_FC6DF1  (address immediately past the last instruction of Encoder_ReturnDefaultConstant)
    -> Encoder_ReturnDefaultConstant_End

--- sysex_routines.s ---

  LABEL_FD8CAE  (call target only, defined in kn5000_v10_program.s)
    - Called from MainExcSend after a type-byte is read from a lookup table.
      Sets bit 7 of the SysEx status byte, calls three initialization routines,
      then dispatches to one of up to 6 SysEx-type handlers via a 3-bit index
      into a word jump table at 0xEE2F7E.
    -> SysEx_InitiateSend

  LABEL_F766D3  (6-byte data block immediately after ExcDotFunc_HandlerJumpTable)
    - Additional entries extending the DOT handler jump table. The jp_dri
      instruction in ExcDotFunc indexes into 0xF76696 and these bytes are part
      of the same contiguous inline dispatch table.
    -> ExcDotFunc_HandlerJumpTable_Ext

  LABEL_F76706  (38-byte inline data block inside ExcPmemFunc after jp_dri)
    - Jump-dispatch target table used by ExcPmemFunc's jp_dri instruction.
      Contains interleaved handler addresses and control bytes for panel-memory
      SysEx dispatch.
    -> ExcPmemFunc_HandlerJumpTable

  LABEL_F76764  (38-byte inline data block inside ExcSmemFunc after jp_dri)
    - Same structure as ExcPmemFunc_HandlerJumpTable but for sound-memory SysEx.
    -> ExcSmemFunc_HandlerJumpTable

  LABEL_F767C2  (38-byte inline data block inside ExcCompFunc after jp_dri)
    - Composer SysEx dispatch table.
    -> ExcCompFunc_HandlerJumpTable

  LABEL_F76820  (38-byte inline data block inside ExcSeqFunc after jp_dri)
    - Sequencer SysEx dispatch table.
    -> ExcSeqFunc_HandlerJumpTable

  LABEL_F7687E  (38-byte inline data block inside ExcMspFunc after jp_dri)
    - Music Style Programmer SysEx dispatch table.
    -> ExcMspFunc_HandlerJumpTable
"""

import os
import sys

# ---------------------------------------------------------------------------
# Rename map: (old_name, new_name) for each of the three target files.
# The script performs whole-word replacements so that a label that is a
# prefix of another label is never corrupted.
# ---------------------------------------------------------------------------

# sound_editor_routines.s  -  19 unique LABEL_* symbols
SOUND_EDITOR_RENAMES = [
    # External call target (defined in kn5000_v10_program.s)
    ("LABEL_F9AE97",  "DirmdEmulator_Entry"),
    # Inline display-data blocks (defined in this file only)
    ("LABEL_F039B7",  "SeAmpAmp2TitleFunc_DisplayData"),
    ("LABEL_F039EA",  "SeAmpEnv1TitleFunc_DisplayData"),
    ("LABEL_F03A1D",  "SeAmpEnv2TitleFunc_DisplayData"),
    ("LABEL_F03A50",  "SeAmpLfo1TitleFunc_DisplayData"),
    ("LABEL_F03A83",  "SeFilLpq1TitleFunc_DisplayData"),
    ("LABEL_F03AB6",  "SeFilHpq1TitleFunc_DisplayData"),
    ("LABEL_F03AE9",  "SeFilL241TitleFunc_DisplayData"),
    ("LABEL_F03B1C",  "SeFilH241TitleFunc_DisplayData"),
    ("LABEL_F03B4F",  "SeFilBpf1TitleFunc_DisplayData"),
    ("LABEL_F03B82",  "SeFilBcf1TitleFunc_DisplayData"),
    ("LABEL_F03BB5",  "SeFilFil2TitleFunc_DisplayData"),
    ("LABEL_F03BE8",  "SeFilEnv1TitleFunc_DisplayData"),
    ("LABEL_F03C1B",  "SeFilEnv2TitleFunc_DisplayData"),
    ("LABEL_F03C4E",  "SeFilLfo1TitleFunc_DisplayData"),
    ("LABEL_F03C81",  "SeDigEffTitleFunc_DisplayData"),
    ("LABEL_F03CB4",  "SeCtr2TitleFunc_DisplayData"),
    ("LABEL_F03CE7",  "SeCtr3TitleFunc_DisplayData"),
    ("LABEL_F03D1A",  "SeCopyTitleFunc_DisplayData"),
    ("LABEL_F03D4D",  "SeWrtMemTitleFunc_DisplayData"),
]

# midi_encoder_routines.s  -  7 LABEL_* definitions + 2 external call references
MIDI_ENCODER_RENAMES = [
    # External call targets (defined in kn5000_v10_program.s)
    ("LABEL_FF0C18",  "Math_DivideU32"),
    ("LABEL_FF0A5C",  "Math_MultiplyAccumulate"),
    # End-of-function boundary markers (defined in this file only)
    ("LABEL_FC6CAE",  "Encoder_ProcessModwheel_End"),
    ("LABEL_FC6D2D",  "Encoder_ClampScaleAndNormalize_End"),
    ("LABEL_FC6D9F",  "Encoder_ProcessBreath_End"),
    ("LABEL_FC6DC9",  "Encoder_ProcessFoot_End"),
    ("LABEL_FC6DE9",  "Encoder_ProcessExpression_End"),
    ("LABEL_FC6DEE",  "Encoder_PassthroughIdentity_End"),
    ("LABEL_FC6DF1",  "Encoder_ReturnDefaultConstant_End"),
]

# sysex_routines.s  -  6 LABEL_* definitions + 1 external call reference
SYSEX_RENAMES = [
    # External call target (defined in kn5000_v10_program.s)
    ("LABEL_FD8CAE",  "SysEx_InitiateSend"),
    # Inline data / jump-table blocks (defined in this file only)
    ("LABEL_F766D3",  "ExcDotFunc_HandlerJumpTable_Ext"),
    ("LABEL_F76706",  "ExcPmemFunc_HandlerJumpTable"),
    ("LABEL_F76764",  "ExcSmemFunc_HandlerJumpTable"),
    ("LABEL_F767C2",  "ExcCompFunc_HandlerJumpTable"),
    ("LABEL_F76820",  "ExcSeqFunc_HandlerJumpTable"),
    ("LABEL_F7687E",  "ExcMspFunc_HandlerJumpTable"),
]

# ---------------------------------------------------------------------------
# Files to process (relative to the roms-disasm repo root).
# Each entry is (relative_path, rename_list).
# ---------------------------------------------------------------------------
FILES = [
    ("maincpu/sound_editor_routines.s",  SOUND_EDITOR_RENAMES),
    ("maincpu/midi_encoder_routines.s",  MIDI_ENCODER_RENAMES),
    ("maincpu/sysex_routines.s",         SYSEX_RENAMES),
]


def is_label_char(b: int) -> bool:
    """Return True if *b* (an integer 0-255) can be part of a label name."""
    # A-Z, a-z, 0-9, _
    return (
        (0x41 <= b <= 0x5A) or  # A-Z
        (0x61 <= b <= 0x7A) or  # a-z
        (0x30 <= b <= 0x39) or  # 0-9
        b == 0x5F               # _
    )


def replace_whole_word(data: bytes, old: str, new: str) -> tuple[bytes, int]:
    """
    Replace every occurrence of *old* in *data* that is not immediately
    preceded or followed by a label-character byte (whole-word boundary).

    Returns (new_data, replacement_count).
    """
    old_b = old.encode("ascii")
    new_b = new.encode("ascii")
    result = bytearray()
    count = 0
    i = 0
    n = len(data)
    olen = len(old_b)

    while i < n:
        if data[i:i + olen] == old_b:
            # Check left boundary
            left_ok = (i == 0) or (not is_label_char(data[i - 1]))
            # Check right boundary
            right_end = i + olen
            right_ok = (right_end >= n) or (not is_label_char(data[right_end]))
            if left_ok and right_ok:
                result.extend(new_b)
                count += 1
                i += olen
                continue
        result.append(data[i])
        i += 1

    return bytes(result), count


def process_file(path: str, renames: list[tuple[str, str]]) -> None:
    """Apply all renames to the file at *path* using binary I/O."""
    with open(path, "rb") as fh:
        data = fh.read()

    total = 0
    for old, new in renames:
        data, n = replace_whole_word(data, old, new)
        if n > 0:
            print(f"  {old!s:45s} -> {new}  ({n} occurrence{'s' if n != 1 else ''})")
            total += n
        else:
            print(f"  {old!s:45s} -> {new}  (NOT FOUND - skipped)")

    with open(path, "wb") as fh:
        fh.write(data)

    print(f"  [{total} replacement(s) written to {path}]")


def main() -> None:
    # Resolve the repo root relative to this script's location:
    #   scripts/rename_misc_routines_labels.py  ->  ../  (repo root)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.normpath(os.path.join(script_dir, ".."))

    print(f"Repo root: {repo_root}")
    print()

    for rel_path, renames in FILES:
        abs_path = os.path.join(repo_root, rel_path)
        print(f"=== {rel_path} ===")
        if not os.path.isfile(abs_path):
            print(f"  ERROR: file not found: {abs_path}", file=sys.stderr)
            sys.exit(1)
        process_file(abs_path, renames)
        print()

    print("Done.")


if __name__ == "__main__":
    main()
