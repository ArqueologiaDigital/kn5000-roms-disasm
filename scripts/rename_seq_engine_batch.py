#!/usr/bin/env python3
"""Rename LABEL_XXXXXX labels in sequencer_engine.s to semantic names (batch 13).

Uses binary I/O to preserve Latin-1 bytes.
Updates all .s files in maincpu/ that reference renamed labels.
"""

import sys
import os
import glob

RENAMES = {
    # --- LABEL_F47B34 - FileIO block write area (lines ~24319-24390) ---
    "LABEL_F47B34": "FileIO_WriteBlockToStream",
    "LABEL_F47B5C": "FileIO_WriteBlockCopyLoop",
    "LABEL_F47B95": "FileIO_WriteCheckDefault",
    "LABEL_F47BA1": "FileIO_WriteUpdateCounter",
    "LABEL_F47BC4": "FileIO_WritePopReturn",
    "LABEL_F47BC8": "FileIO_FlushPendingBlock",

    # --- LABEL_F47BE0 - FileIO write all parts (lines ~24392-24450) ---
    "LABEL_F47BE0": "FileIO_WriteAllPartVoices",
    "LABEL_F47BFB": "FileIO_WritePartLoop",
    "LABEL_F47C2D": "FileIO_WriteVoiceChainLoop",
    "LABEL_F47C55": "FileIO_WritePartAccumulate",
    "LABEL_F47C5D": "FileIO_WriteNextPart",
    "LABEL_F47C69": "FileIO_WriteEpilogue",

    # --- LABEL_F47C70 - SeqSave prepare (lines ~24452-24496) ---
    "LABEL_F47C70": "SeqSave_PreparePartData",
    "LABEL_F47C8B": "SeqSave_CopyBlockAndInit",
    "LABEL_F47CF9": "SeqSave_AllocAndWrite",

    # --- LABEL_F47D23 - SeqSave write (lines ~24514-24612) ---
    "LABEL_F47D23": "SeqSave_WriteAndFree",
    "LABEL_F47D4E": "SeqSave_CountBlocksLoop",
    "LABEL_F47D86": "SeqSave_WritePartDataLoop",
    "LABEL_F47DD6": "SeqSave_WritePartInner",
    "LABEL_F47E28": "SeqSave_NextPartLoop",

    # --- LABEL_F47E3C - SeqLoad format validation (lines ~24622-24654) ---
    "LABEL_F47E3C": "SeqLoad_ValidateFormat",
    "LABEL_F47E56": "SeqLoad_FormatInvalid",
    "LABEL_F47E60": "SeqLoad_JmpLoadPre",
    "LABEL_F47E63": "SeqLoad_JmpLoadPost",
    "LABEL_F47E66": "SeqLoad_JmpInitPreset",
    "LABEL_F47E69": "SeqLoad_JmpAltEntry",

    # --- SeqBar_ComputeAndSetPositions area (lines ~24656-24724) ---
    "LABEL_F47E83": "SeqBar_ClampAndStore",
    "LABEL_F47E9D": "SeqBar_ComputeRange",
    "LABEL_F47EAC": "SeqBar_CheckZeroRange",
    "LABEL_F47EB8": "SeqBar_SetPositionLoop",
    "LABEL_F47ED9": "SeqBar_LinkNextPosition",
    "LABEL_F47EEB": "SeqBar_WriteBoundary",
    "LABEL_F47EFF": "SeqBar_ReturnDone",

    # --- LABEL_F47F01 - large .byte data block ---
    "LABEL_F47F01": "SeqBar_DataBlock",

    # --- LABEL_F47FA4 - restore part config (lines ~24749-24768) ---
    "LABEL_F47FA4": "SeqLoad_RestorePartConfig",

    # --- LABEL_F47FE1 - compute total voice size (lines ~24770-24833) ---
    "LABEL_F47FE1": "SeqSave_ComputeVoiceSize",
    "LABEL_F47FFB": "SeqSave_VoiceSizeInitLoop",
    "LABEL_F47FFE": "SeqSave_VoiceSizePartLoop",
    "LABEL_F4803E": "SeqSave_VoiceSizeChainLoop",
    "LABEL_F4805F": "SeqSave_VoiceSizeNextPart",
    "LABEL_F48076": "SeqSave_VoiceSizeReturn",

    # --- LABEL_F4807C - read block from memory ---
    "LABEL_F4807C": "SeqSave_ReadBlockFromMem",

    # --- LABEL_F48094 - write block to file ---
    "LABEL_F48094": "SeqSave_WriteBlockToFile",

    # --- LABEL_F480AD - seek and read with buffer ---
    "LABEL_F480AD": "FileIO_SeekReadAndCheck",
    "LABEL_F480C7": "FileIO_SeekReadReturn",

    # --- FileIO_SeekAndRead16BitValue area (lines ~24872-24895) ---
    "LABEL_F480F6": "FileIO_Read16Return",

    # --- LABEL_F480F8 - large .byte block ---
    "LABEL_F480F8": "SeqLoad_ReadPartDataBlock",

    # --- SeqLoad_CheckAutoAccompFlag area (lines ~24929-24954) ---
    "LABEL_F48211": "SeqLoad_ClearAutoAccompBit1",

    # --- SeqLoad_ProcessAllVoiceData area ---
    "LABEL_F4821D": "SeqLoad_ProcessOuterLoop",
    "LABEL_F48221": "SeqLoad_ProcessInnerLoop",
    "LABEL_F48255": "SeqLoad_ProcessVoiceFound",
    "LABEL_F4829F": "SeqLoad_ProcessNextInner",
    "LABEL_F482CF": "SeqLoad_ProcessNextOuter",
    "LABEL_F482FA": "SeqLoad_ProcessReturn",
    "LABEL_F48312": "SeqLoad_ProcessCopyLoop",
}

def main():
    base_dir = "/mnt/shared/kn5000-roms-disasm"
    s_files = glob.glob(os.path.join(base_dir, "maincpu", "**", "*.s"), recursive=True)
    print(f"Found {len(s_files)} .s files to scan")

    file_contents = {}
    for path in s_files:
        with open(path, 'rb') as f:
            file_contents[path] = f.read()

    total_replacements = 0
    files_modified = set()

    for old_label, new_label in RENAMES.items():
        old_bytes = old_label.encode('ascii')
        new_bytes = new_label.encode('ascii')
        for path, content in file_contents.items():
            if old_bytes in content:
                count = content.count(old_bytes)
                file_contents[path] = content.replace(old_bytes, new_bytes)
                total_replacements += count
                files_modified.add(path)

    for path in files_modified:
        with open(path, 'wb') as f:
            f.write(file_contents[path])
        rel = os.path.relpath(path, base_dir)
        print(f"  Modified: {rel}")

    print(f"\nTotal: {len(RENAMES)} labels renamed, {total_replacements} replacements across {len(files_modified)} files")

if __name__ == "__main__":
    main()
