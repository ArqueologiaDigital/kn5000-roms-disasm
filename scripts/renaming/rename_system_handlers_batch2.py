#!/usr/bin/env python3
"""Rename remaining 165 LABEL_XXXXXX to semantic names in system_handlers.s - Batch 2 (all remaining)"""

import os
import sys
import tempfile

# Mapping of old label -> new label
RENAMES = {
    # SeqBuf_DspSysEx_WriteBytes loop
    "LABEL_EF2A4D": "SeqBuf_DspSysEx_WriteBytes_Loop",

    # SeqBuf_DspSysEx_CheckSongEnd return
    "LABEL_EF2A6E": "SeqBuf_DspSysEx_CheckSongEnd_Return",

    # Orphan data block after DspSysEx_CheckSongEnd
    "LABEL_EF2A6F": "SeqBuf_DspSysEx_OrphanData",

    # SeqBuf_DspSysEx misc helpers
    "LABEL_EF2A83": "SeqBuf_DspSysEx_CopyPointers",

    # Large .byte data block (sequencer buffer operations)
    "LABEL_EF2AD3": "SeqBuf_TimerEvent_BytecodeBlock",

    # Another large .byte data block
    "LABEL_EF2B97": "SeqBuf_TimerEvent_BytecodeBlock2",

    # SeqBuf_SoundEdit large .byte block
    "LABEL_EF2E39": "SeqBuf_SoundEdit_BytecodeBlock",

    # SeqBuf_NoteEvent_CheckSongEnd return
    "LABEL_EF2E82": "SeqBuf_NoteEvent_CheckSongEnd_Return",

    # SeqBuf_NoteEvent orphan data
    "LABEL_EF2E83": "SeqBuf_NoteEvent_OrphanData",

    # SeqBuf_NoteEvent_InitBuffer
    "LABEL_EF2E89": "SeqBuf_NoteEvent_InitBuffer",

    # SeqBuf_NoteEvent pointer copy
    "LABEL_EF2E97": "SeqBuf_NoteEvent_CopyPointers",

    # SeqBuf_NoteEvent alternate read .byte block
    "LABEL_EF2EA4": "SeqBuf_NoteEvent_AlternateRead",

    # Ring buffer pointer copy subs
    "LABEL_EF2EC0": "RingBuf_CopyPtr_Sub1",
    "LABEL_EF2ECD": "RingBuf_CopyPtr_Sub2",

    # Ring buffer struct init
    "LABEL_EF2EDA": "RingBuf_InitStructFields",

    # Ring buffer internal read/check routines (128-byte)
    "LABEL_EF2EF4": "RingBuf128_CheckEmpty",
    "LABEL_EF2F00": "RingBuf128_ReadByte",

    # Ring buffer internal read routines (128-byte, alternate)
    "LABEL_EF2F12": "RingBuf128_ReadAlt_CheckEmpty",
    "LABEL_EF2F1E": "RingBuf128_ReadAlt_Dequeue",
    "LABEL_EF2F2D": "RingBuf128_ReadAlt2_CheckEmpty",
    "LABEL_EF2F39": "RingBuf128_ReadAlt2_Dequeue",

    # Ring buffer write/check (128-byte)
    "LABEL_EF2F48": "RingBuf128_WriteByte_CheckFull",
    "LABEL_EF2F53": "RingBuf128_WriteByte_Store",

    # Seq_RingBuf_ReadByte internal
    "LABEL_EF2F8F": "Seq_RingBuf_ReadByte_Dequeue",

    # Seq_RingBuf_ReadByte_Large internal
    "LABEL_EF2FAD": "Seq_RingBuf_ReadByte_Large_Dequeue",

    # Seq_RingBuf_ReadByte_Small internal
    "LABEL_EF2FC8": "Seq_RingBuf_ReadByte_Small_Dequeue",

    # Seq_RingBuf_WriteByte_Small internal
    "LABEL_EF2FE2": "Seq_RingBuf_WriteByte_Small_Store",

    # RingBuf_CheckFull_512 internal
    "LABEL_EF301E": "RingBuf512_CheckFull_Read",

    # RingBuf_CheckFull_256 internal
    "LABEL_EF303C": "RingBuf256_CheckFull_Read",

    # .byte data block (ring buffer read with 512 modulus)
    "LABEL_EF304B": "RingBuf512_ReadAlt_ByteBlock",

    # Seq_RingBuf_WriteByte_512 internal
    "LABEL_EF3071": "Seq_RingBuf_WriteByte_512_Store",

    # Seq_RingBuf_Dequeue_1024 internal
    "LABEL_EF30AD": "Seq_RingBuf_Dequeue_1024_Read",

    # Seq_RingBuf_ReadData internal
    "LABEL_EF30CB": "Seq_RingBuf_ReadData_Dequeue",

    # .byte data block (ring buffer read with 1024 modulus)
    "LABEL_EF30DA": "RingBuf1024_ReadAlt_ByteBlock",

    # Seq_RingBuf_WriteByte internal
    "LABEL_EF3100": "Seq_RingBuf_WriteByte_1024_Store",

    # InterCPU / DMA setup
    "LABEL_EF32F4": "Audio_InitDMAChannels_Done",

    # sendCOMM chunked loop
    "LABEL_EF330B": "sendCOMM_ChunkLoop",
    "LABEL_EF332B": "sendCOMM_FinalChunk",

    # InterCPU_Send_Data_Block internal
    "LABEL_EF334B": "InterCPU_Send_WaitReady",
    "LABEL_EF3368": "InterCPU_Send_WaitAck",
    "LABEL_EF3389": "InterCPU_Send_WaitComplete",
    "LABEL_EF3391": "InterCPU_Send_TimeoutLoop",
    "LABEL_EF339C": "InterCPU_Send_AckTimeoutLoop",

    # InterCPU_E2_Send internal
    "LABEL_EF33B3": "InterCPU_E2_WaitIdle",
    "LABEL_EF33C4": "InterCPU_E2_ClearAndSend",
    "LABEL_EF33D4": "InterCPU_E2_WaitAck",
    "LABEL_EF3405": "InterCPU_E2_WaitComplete",
    "LABEL_EF340D": "InterCPU_E2_TimeoutLoop",

    # Audio_DMA_Transfer internal
    "LABEL_EF342C": "Audio_DMA_Transfer_CheckSize",
    "LABEL_EF3436": "Audio_DMA_Transfer_ByteLoop",
    "LABEL_EF344A": "Audio_DMA_Transfer_DelayLoop",

    # InterCPU_E1_Bulk_Transfer internal
    "LABEL_EF3461": "E1Bulk_WaitIdle_Loop",
    "LABEL_EF3473": "E1Bulk_ReadyCheck",
    "LABEL_EF3475": "E1Bulk_WaitSubCPU_Ready",
    "LABEL_EF348B": "E1Bulk_WaitAck",
    "LABEL_EF34BF": "E1Bulk_WaitPhase1_Loop",
    "LABEL_EF34C6": "E1Bulk_Phase2_Init",
    "LABEL_EF34C8": "E1Bulk_Phase2_Delay",
    "LABEL_EF34EE": "E1Bulk_WaitPhase2_Loop",
    "LABEL_EF34F5": "E1Bulk_PostTransfer_Delay_Init",
    "LABEL_EF34FD": "E1Bulk_PostTransfer_Delay_Loop",
    "LABEL_EF3506": "E1Bulk_PostTransfer_Exit",
    "LABEL_EF3508": "E1Bulk_ReadyTimeout_Loop",
    "LABEL_EF3515": "E1Bulk_AckTimeout_Loop",

    # INT0_HANDLER internal
    "LABEL_EF3530": "INT0_UnusedBranch",
    "LABEL_EF3532": "INT0_ProcessCommand",
    "LABEL_EF3536": "INT0_ReadLatch",

    # INT0 command dispatch internal
    "LABEL_EF356F": "INT0_CheckE2Command",
    "LABEL_EF3599": "INT0_HandleDataCommand",
    "LABEL_EF35C4": "INT0_AckAndReturn",

    # INTTC2_HANDLER internal
    "LABEL_EF35DB": "INTTC2_CheckPhase2",
    "LABEL_EF35E7": "INTTC2_Exit",

    # INTTC0_HANDLER internal (DMA ISR)
    "LABEL_EF3662": "INTTC0_E2_Complete",
    "LABEL_EF3675": "INTTC0_E1_Phase2_Complete",
    "LABEL_EF367E": "INTTC0_SetTransferDone",

    # Large .byte data block after E1DMA_ISR_Epilogue
    "LABEL_EF3689": "E1DMA_ISR_BytecodeBlock",

    # Flash_IdentifyChip internal
    "LABEL_EF3733": "Flash_IdentifyChip_UseBank1",
    "LABEL_EF3735": "Flash_IdentifyChip_WaitReady",
    "LABEL_EF3798": "Flash_IdentifyChip_Done",

    # Flash_IdentifyAndValidateChip internal
    "LABEL_EF37B5": "Flash_IdentifyValidate_UseBank1",
    "LABEL_EF37EB": "Flash_IdentifyValidate_CheckDeviceId",
    "LABEL_EF3806": "Flash_IdentifyValidate_PostStore",
    "LABEL_EF380E": "Flash_IdentifyValidate_Return",

    # Flash_ProgramWord internal
    "LABEL_EF3825": "Flash_ProgramWord_WaitReady",
    "LABEL_EF384E": "Flash_ProgramWord_UseBank1",
    "LABEL_EF3876": "Flash_ProgramWord_Done",

    # Flash chip erase routine (unnamed)
    "LABEL_EF387A": "Flash_ChipErase",
    "LABEL_EF3890": "Flash_ChipErase_UseBank1",
    "LABEL_EF3923": "Flash_ChipErase_Done",

    # Flash_EraseSectorWithBankSelect internal
    "LABEL_EF3943": "Flash_EraseSector_UseBank1",
    "LABEL_EF396C": "Flash_EraseSector_WriteSequence",
    "LABEL_EF39D6": "Flash_EraseSector_BootBlock_HighBank",
    "LABEL_EF3A0E": "Flash_EraseSector_CheckRegion",
    "LABEL_EF3A3E": "Flash_EraseSector_TopSector",
    "LABEL_EF3A82": "Flash_EraseSector_Bank2Check",
    "LABEL_EF3AAA": "Flash_EraseSector_Bank2TopSector",
    "LABEL_EF3AD2": "Flash_EraseSector_FinalWrite",

    # Flash_CheckReady internal
    "LABEL_EF3AE9": "Flash_CheckReady_NotReady",

    # Flash_WaitUntilReady internal
    "LABEL_EF3AFB": "Flash_WaitUntilReady_Loop",

    # Flash initialization (unnamed)
    "LABEL_EF3B05": "Flash_InitAllBanks",

    # Flash fill helper (unnamed)
    "LABEL_EF3B2F": "Flash_FillBuffer",
    "LABEL_EF3B35": "Flash_FillBuffer_Loop",

    # Flash copy from ROM to buffer (unnamed)
    "LABEL_EF3B3F": "Flash_CopyROMToBuffer",

    # Flash write buffer to chip (unnamed)
    "LABEL_EF3B55": "Flash_WriteBufferToChip",
    "LABEL_EF3B6F": "Flash_WriteBufferToChip_Loop",
    "LABEL_EF3B95": "Flash_WriteBufferToChip_Delay",

    # Flash write from memory (unnamed)
    "LABEL_EF3BAA": "Flash_WriteFromMemory",
    "LABEL_EF3BC1": "Flash_WriteFromMemory_Loop",
    "LABEL_EF3BE7": "Flash_WriteFromMemory_Delay",

    # Flash_EraseSectorAndWrite internal
    "LABEL_EF3C22": "Flash_EraseSectorAndWrite_WaitLoop",
    "LABEL_EF3C2B": "Flash_EraseSectorAndWrite_Write",

    # FlashWrite internal
    "LABEL_EF3C86": "FlashWrite_WaitEraseLoop",
    "LABEL_EF3C8F": "FlashWrite_DoWrite",

    # HDAE5000 Table Data ROM identify (32-bit bus)
    "LABEL_EF3CD1": "TableDataROM_IdentifyChip",
    "LABEL_EF3CD6": "TableDataROM_IdentifyChip_WaitReady",

    # HDAE5000_Detect internal
    "LABEL_EF3D5E": "HDAE5000_Detect_CheckManufId",
    "LABEL_EF3D6E": "HDAE5000_Detect_StoreDeviceId",
    "LABEL_EF3D71": "HDAE5000_Detect_ResetChip",
    "LABEL_EF3D74": "HDAE5000_Detect_Return",

    # Flash_ProgramByte internal
    "LABEL_EF3D8B": "Flash_ProgramByte_WaitReady",
    "LABEL_EF3DB7": "Flash_ProgramByte_Done",

    # HDAE5000_Flash_Verify (large .byte block after it)
    "LABEL_EF3E21": "HDAE5000_Flash_Erase_AllSectors",

    # Firmware Update UI - floppy change handler
    "LABEL_EF46A4": "FirmwareUpdate_SaveDiskType",
    "LABEL_EF46C5": "FloppyChange_WaitDiskRemove_Loop",
    "LABEL_EF46CD": "FloppyChange_DiskRemoved",
    "LABEL_EF46CF": "FloppyChange_Debounce1_Loop",
    "LABEL_EF46E1": "FloppyChange_WaitDiskInsert_Loop",
    "LABEL_EF46E9": "FloppyChange_DiskInserted",
    "LABEL_EF46EB": "FloppyChange_Debounce2_Loop",

    # Flash_BurnWithProgress internal
    "LABEL_EF471A": "FlashBurn_ProgressLoop",
    "LABEL_EF4739": "FlashBurn_CheckDone",
    "LABEL_EF4743": "FlashBurn_Done",

    # Firmware update file type dispatch helpers
    "LABEL_EF47C2": "UpdateFile_WriteSectors_AndCleanup",
    "LABEL_EF47F5": "UpdateFile_WriteCompressed_AndCleanup",

    # SHOW_ILLEGAL_DISK_MESSAGE halt loop
    "LABEL_EF4841": "IllegalDisk_HaltLoop",

    # BusyWait loop
    "LABEL_EF4849": "BusyWait_Loop",

    # Port LED cycling routine (unnamed)
    "LABEL_EF4850": "LED_CyclePattern",
    "LABEL_EF4873": "LED_CyclePattern_Phase1",
    "LABEL_EF487B": "LED_CyclePattern_Phase2",
    "LABEL_EF4883": "LED_CyclePattern_Phase3",

    # LED toggle routines (unnamed)
    "LABEL_EF4890": "LED_Toggle_Bit2_Loop",
    "LABEL_EF489F": "LED_Toggle_Bit3_Loop",

    # TableData_ROM_Verify internal
    "LABEL_EF48BA": "TableData_ROM_Verify_NextBlock",
    "LABEL_EF48C4": "TableData_ROM_Verify_CheckBlock",

    # HDAE5000_ROM_Transfer internal
    "LABEL_EF48DA": "HDAE5000_ROM_Transfer_BlockLoop",
    "LABEL_EF48E6": "HDAE5000_ROM_Transfer_WordLoop",
    "LABEL_EF48FC": "HDAE5000_ROM_Transfer_Success",
    "LABEL_EF48FE": "HDAE5000_ROM_Transfer_Return",

    # HDAE5000 ROM write routines
    "LABEL_EF4911": "HDAE5000_FlashWrite_BankLoop",
    "LABEL_EF4923": "HDAE5000_FlashWrite_WordLoop",

    # Large .byte data block (HDAE5000 flash/verify)
    "LABEL_EF4953": "HDAE5000_FlashVerify_BytecodeBlock",

    # HDAE5000 Table Data ROM transfer
    "LABEL_EF49A5": "HDAE5000_TableData_Write",
    "LABEL_EF49B5": "HDAE5000_TableData_BankLoop",
    "LABEL_EF49C7": "HDAE5000_TableData_WordLoop",

    # Large .byte data block (HDAE5000 init/bitmap)
    "LABEL_EF49F7": "HDAE5000_Init_BytecodeBlock",

    # HDAE5000 init sequence
    "LABEL_EF4B54": "HDAE5000_Init_DetectAndVerify",
    "LABEL_EF4B6D": "HDAE5000_Init_VerifyROM",
    "LABEL_EF4B8C": "HDAE5000_Init_WaitFlashReady",
    "LABEL_EF4B9F": "HDAE5000_Init_TransferData",
    "LABEL_EF4BCA": "HDAE5000_Init_HaltLoop",

    # Draw_FlashMemUpdate_message_bitmap internal
    "LABEL_EF5050": "DrawBitmap_RowLoop",
    "LABEL_EF5063": "DrawBitmap_CheckNewRow",
    "LABEL_EF5066": "DrawBitmap_BitLoop",
    "LABEL_EF50AA": "DrawBitmap_BackgroundPixel",
    "LABEL_EF50BB": "DrawBitmap_NextBit",
}

def do_renames(renames):
    base = "/mnt/shared/kn5000-roms-disasm"
    # Find all .s files in maincpu/
    s_files = []
    for root, dirs, files in os.walk(os.path.join(base, "maincpu")):
        for f in files:
            if f.endswith(".s"):
                s_files.append(os.path.join(root, f))
    s_files.sort()

    for fpath in s_files:
        with open(fpath, 'rb') as fh:
            data = fh.read()

        original = data
        for old, new in renames.items():
            data = data.replace(old.encode('ascii'), new.encode('ascii'))

        if data != original:
            # Atomic write
            dirname = os.path.dirname(fpath)
            fd, tmp = tempfile.mkstemp(dir=dirname, suffix='.tmp')
            try:
                os.write(fd, data)
                os.fsync(fd)
                os.close(fd)
                os.rename(tmp, fpath)
                print(f"  Updated: {fpath}")
            except:
                os.close(fd)
                os.unlink(tmp)
                raise

if __name__ == "__main__":
    print(f"Renaming {len(RENAMES)} labels (Batch 2 - all remaining)...")
    do_renames(RENAMES)
    print("Done.")
