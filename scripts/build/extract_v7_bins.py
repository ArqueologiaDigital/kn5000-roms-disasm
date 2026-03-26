#!/usr/bin/env python3
"""Extract v7 .incbin data from the v7 ROM.
Uses v7 ELF addresses when available (preferred), falls back to v9 ELF.
Run before assembling v7 to ensure correct data blobs."""
import subprocess, os, glob, re

LLVM_NM = '/mnt/shared/llvm-project/build/bin/llvm-nm'
ROM_BASE = 0xe00000
v7_rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()

def load_elf_syms(elf_path):
    """Load symbols from ELF, return dict name->addr."""
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
        capture_output=True, text=True)
    syms = {}
    for line in result.stdout.strip().split('\n'):
        parts = line.strip().split()
        if len(parts) >= 3:
            try:
                syms[parts[2]] = int(parts[0], 16)
            except ValueError:
                pass
    return syms

# Load v7 ELF if available (preferred for addresses), fall back to v9
v7_elf = 'rebuilt_ROMs/kn5000_v7_program.llvm.elf'
v9_elf = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'

if not os.path.exists(v9_elf):
    print("v9 ELF not found, building v9 first...")
    os.system('make rebuilt_ROMs/kn5000_v9_program.llvm.rom')

v9_syms = load_elf_syms(v9_elf)
v7_syms = load_elf_syms(v7_elf) if os.path.exists(v7_elf) else {}

# Use v7 addresses when available, fall back to v9
def get_addr(label):
    if label in v7_syms:
        return v7_syms[label]
    return v9_syms.get(label)

# === STAGE 1: Extract .incbin data using label addresses ===
# Walk v9 source to find .incbin labels (v9 has same structure as v7 for shared files)
incbin_map = {}  # Use (label, bin_rel) as key to handle multiple .incbin per label
for fp in sorted(glob.glob('v9/maincpu/**/*.s', recursive=True)):
    with open(fp, 'rb') as f:
        lines = f.readlines()
    last_label = None
    for line in lines:
        s = line.strip()
        _m = re.match(rb'^(\w+):', s)
        if _m and not s.startswith(b'.') and not s.startswith(b';'):
            last_label = _m.group(1).decode('latin-1')
        if b'.incbin' in s and b'generated/' in s:
            i1 = s.find(b'"') + 1
            i2 = s.find(b'"', i1)
            bin_rel = s[i1:i2].decode('latin-1')
            addr = get_addr(last_label) if last_label else None
            if addr is not None:
                key = (last_label, bin_rel)
                incbin_map[key] = (addr, f'v9/maincpu/{bin_rel}')

extracted = 0
for (label, _), (addr, v9_path) in sorted(incbin_map.items(), key=lambda x: x[1][0]):
    if not os.path.exists(v9_path):
        continue
    v9_size = os.path.getsize(v9_path)
    rom_off = addr - ROM_BASE

    v7_data = v7_rom[rom_off:rom_off+v9_size]
    v9_data = open(v9_path, 'rb').read()

    # Check similarity (>50% = same block at same address)
    match_pct = sum(1 for a, b in zip(v7_data, v9_data) if a == b) / v9_size if v9_size > 0 else 0

    v7_path = v9_path.replace('v9/', 'v7/')
    os.makedirs(os.path.dirname(v7_path), exist_ok=True)

    if match_pct > 0.5:
        with open(v7_path, 'wb') as f:
            f.write(v7_data)
        extracted += 1
    else:
        # Different block at this offset — use v9 data (safe default)
        with open(v7_path, 'wb') as f:
            f.write(v9_data)

print(f"Extracted {extracted} v7 bins from ROM")

# Special case: naka_sequencer_channels.bin is 42 bytes SHORTER in v7
# The C compilation produces v9's 7936-byte version.
# Override with correct v7 data (7894 bytes).
seq_path = 'v7/maincpu/includes/generated/naka_sequencer_channels.bin'
seq_off = 0xeee078 - ROM_BASE
seq_data = v7_rom[seq_off:seq_off+7894]
os.makedirs(os.path.dirname(seq_path), exist_ok=True)
with open(seq_path, 'wb') as f:
    f.write(seq_data)
print(f"Fixed naka_sequencer_channels.bin: {len(seq_data)} bytes (v7 size)")

# V7-specific data extractions: regions in .s files that use v9 pointer values
# and need to be replaced with v7 ROM data.
v7_data_extractions = [
    # (bin_name, rom_start, rom_end)
    ('v7_data_charmap_fullpermutation.bin', 0xEED118, 0xEEDD36),
    ('v7_data_charmap_valuedata_b.bin', 0xEE8ED8, 0xEEAE08),
    ('v7_data_fdtest_string_testtitlefunc.bin', 0xE1FD3E, 0xE1FFD2),
    ('v7_data_keyscalenotestr_g.bin', 0xED1C82, 0xED1D4A),
    ('v7_data_methodnamestr_mt_svariini.bin', 0xED2F4A, 0xED2FDA),
    ('v7_data_msgtype_excsend.bin', 0xE55D94, 0xE55DF2),
    ('v7_data_mtname_songnameset.bin', 0xE2104A, 0xE21078),
    ('v7_data_naka_subdispatch_a_table.bin', 0xEE0158, 0xEE0198),
    ('v7_data_naka_toshiparam_table.bin', 0xEDB370, 0xEDBAC0),
    ('v7_data_procnamestr_normscreenproc.bin', 0xED3282, 0xED32E6),
    ('v7_data_seqchan_commanddispatch_table.bin', 0xEE2D6C, 0xEE2F26),
    ('v7_data_str_storetotalsetting_de.bin', 0xED0C8C, 0xED0F48),
    ('v7_data_systemconfig_pointertable.bin', 0xEE8C7E, 0xEE8CF8),
    ('v7_data_uistate_defaultconfig_b.bin', 0xEE86B0, 0xEE86D0),
    ('v7_data_widgetparam_selfref_table.bin', 0xEE4E1C, 0xEE4FC6),
    ('v7_data_encoder_region.bin', 0xEDA160, 0xEDA616),
]

gen_dir = 'v7/maincpu/includes/generated'
for bin_name, rom_start, rom_end in v7_data_extractions:
    rom_off = rom_start - ROM_BASE
    data = v7_rom[rom_off:rom_end - ROM_BASE]
    bin_path = os.path.join(gen_dir, bin_name)
    with open(bin_path, 'wb') as f:
        f.write(data)

print(f"Extracted {len(v7_data_extractions)} v7-specific data bins")

# V7-specific code blocks: regions where v7 has different code than v9.
# Use the v7 ELF for addresses when available (preferred), fall back to v9 ELF.
elf_for_addrs = v7_elf if os.path.exists(v7_elf) else v9_elf
if os.path.exists(elf_for_addrs):
    elf_result = subprocess.run([LLVM_NM, '--no-sort', elf_for_addrs],
        capture_output=True, text=True)
    elf_addrs = {}
    for line in elf_result.stdout.strip().split('\n'):
        parts = line.strip().split()
        if len(parts) >= 3:
            try: elf_addrs[parts[2]] = int(parts[0], 16)
            except: pass

    v7_code_blocks = [
        ('v7_block_bitmapout_snapshot_execute.bin', 'BitMapOut_Snapshot_Execute', 303),
        ('v7_block_bitmapout_copyexttable_check.bin', 'BitMapOut_CopyExtTable_Check', 315),
        ('v7_block_acmststylealp_boundary.bin', 'AcMstStyleAlp_Boundary', 497),
        ('v7_block_fileio_loadsongregion8.bin', 'FileIO_LoadSongRegion8', 372),
        ('v7_block_midistream_cmdpedaldone.bin', 'MidiStream_CmdPedalDone', 924),
        ('v7_block_midistream_handlerunningstatus.bin', 'MidiStream_HandleRunningStatus', 1444),
        ('v7_block_sprintf_decexp_applysign.bin', 'Sprintf_DecExp_ApplySign', 27),
        ('v7_block_uistateevt_transposeupdate.bin', 'UIStateEvt_TransposeUpdate', 3812),
        ('v7_block_seqplay_voicechannelcfg.bin', 'SeqPlay_VoiceChannelCfg', 333),
        ('v7_block_seqtimerflags_checksysflag.bin', 'SeqTimerFlags_CheckSysFlag', 157),
        ('v7_block_seqchload_setupandcopy.bin', 'SeqChLoad_SetupAndCopy', 161),
        ('v7_block_seqch_loaddata_checkbass.bin', 'SeqCh_LoadData_CheckBass', 107),
        ('v7_block_seqload_processepilogue.bin', 'SeqLoad_ProcessEpilogue', 88),
        ('v7_block_seqstep_voicereassignexit.bin', 'SeqStep_VoiceReassignExit', 120),
        
        # Interrupt vector trampolines: extracted at MidiStream end
        ('v7_block_sebitmap_envcurve5.bin', 'SeBitmap_EnvCurve5', 8055),
        ('v7_block_semenu_comparescreen_datatable.bin', 'SeMenu_CompareScreen_DataTable', 672),
        ('v7_block_accscreen_uidatablock.bin', 'AccScreen_UIDataBlock', 2096),
        # REMOVED ('{bad}', 'DrumDetailEdit_Menu_Table', 1024),
        # REMOVED ('{bad}', 'TuningSys_Param_01', 610),
        ('v7_block_midipkt_sysexbulktransfer_data.bin', 'MidiPkt_SysExBulkTransfer_Data', 547),
        ('v7_block_scoop_soundeditordata.bin', 'Scoop_SoundEditorData', 9200),
        ('v7_block_audioinit_initpartsendlevels.bin', 'AudioInit_InitPartSendLevels', 77),
        ('v7_block_screengroup_initfinalize.bin', 'ScreenGroup_InitFinalize', 34),
        ('v7_block_soundparam_notifychange.bin', 'SoundParam_NotifyChange', 85),
        # Sub-labels inside data blocks with v7-specific pointer values
        ('v7_block_nakainst_mainvariset.bin', 'NakaInst_MainVariSet', 4746),
        ('v7_block_scoop_soundeditordata_0xeb.bin', 'Scoop_SoundEditorData_0xEB', 4083),
        ('v7_block_scoop_soundeditordata_0x127c.bin', 'Scoop_SoundEditorData_0x127C', 4468),
        ('v7_block_semenu_refreshpartdisplay_data_0x97.bin', 'SeMenu_RefreshPartDisplay_Data_0x97', 1462),
        ('v7_block_sebitmap_envcurve5_0x40b.bin', 'SeBitmap_EnvCurve5_0x40B', 72),
        ('v7_block_sebitmap_envcurve5_0x453.bin', 'SeBitmap_EnvCurve5_0x453', 24),
        ('v7_block_sebitmap_envcurve5_0x4b0.bin', 'SeBitmap_EnvCurve5_0x4B0', 95),
        ('v7_block_sebitmap_envcurve5_0x7e6.bin', 'SeBitmap_EnvCurve5_0x7E6', 72),
        ('v7_block_sebitmap_envcurve5_0x82e.bin', 'SeBitmap_EnvCurve5_0x82E', 100),
        ('v7_block_sebitmap_envcurve5_0x892.bin', 'SeBitmap_EnvCurve5_0x892', 120),
        ('v7_block_sebitmap_envcurve5_0x90a.bin', 'SeBitmap_EnvCurve5_0x90A', 66),
        ('v7_block_sebitmap_envcurve5_0x94c.bin', 'SeBitmap_EnvCurve5_0x94C', 58),
        ('v7_block_sebitmap_envcurve5_0x986.bin', 'SeBitmap_EnvCurve5_0x986', 757),
        ('v7_block_sebitmap_envcurve5_0xe88.bin', 'SeBitmap_EnvCurve5_0xE88', 20),
        ('v7_block_sebitmap_envcurve5_0xe9c.bin', 'SeBitmap_EnvCurve5_0xE9C', 12),
        ('v7_block_sebitmap_envcurve5_0x1539.bin', 'SeBitmap_EnvCurve5_0x1539', 150),
        ('v7_block_sebitmap_envcurve5_0x1a03.bin', 'SeBitmap_EnvCurve5_0x1A03', 259),
        ('v7_block_sebitmap_envcurve5_0x1b06.bin', 'SeBitmap_EnvCurve5_0x1B06', 167),
        ('v7_block_sebitmap_envcurve5_0x1bad.bin', 'SeBitmap_EnvCurve5_0x1BAD', 11),
        ('v7_block_sebitmap_envcurve5_0x1bb8.bin', 'SeBitmap_EnvCurve5_0x1BB8', 480),
        ('v7_block_sebitmap_envcurve5_0x1d98.bin', 'SeBitmap_EnvCurve5_0x1D98', 66),
        ('v7_block_sebitmap_envcurve5_0x1dda.bin', 'SeBitmap_EnvCurve5_0x1DDA', 30),
        ('v7_block_sebitmap_envcurve5_0x1df8.bin', 'SeBitmap_EnvCurve5_0x1DF8', 92),
        ('v7_block_sebitmap_envcurve5_0x1e54.bin', 'SeBitmap_EnvCurve5_0x1E54', 51),
        ('v7_block_sebitmap_envcurve5_0x1e87.bin', 'SeBitmap_EnvCurve5_0x1E87', 16),
        ('v7_block_sebitmap_envcurve5_0x1e97.bin', 'SeBitmap_EnvCurve5_0x1E97', 81),
        ('v7_block_sebitmap_envcurve5_0x1ee8.bin', 'SeBitmap_EnvCurve5_0x1EE8', 24),
        ('v7_block_sebitmap_envcurve5_0x1f00.bin', 'SeBitmap_EnvCurve5_0x1F00', 117),
        ('v7_block_semenu_comparescreen_datatable_0x24.bin', 'SeMenu_CompareScreen_DataTable_0x24', 183),
        ('v7_block_semenu_comparescreen_datatable_0xdb.bin', 'SeMenu_CompareScreen_DataTable_0xDB', 52),
        ('v7_block_semenu_comparescreen_datatable_0x141.bin', 'SeMenu_CompareScreen_DataTable_0x141', 56),
        ('v7_block_semenu_comparescreen_datatable_0x179.bin', 'SeMenu_CompareScreen_DataTable_0x179', 16),
        ('v7_block_semenu_comparescreen_datatable_0x1cf.bin', 'SeMenu_CompareScreen_DataTable_0x1CF', 28),
        ('v7_block_semenu_comparescreen_datatable_0x1eb.bin', 'SeMenu_CompareScreen_DataTable_0x1EB', 117),
        ('v7_block_semenu_comparescreen_datatable_0x278.bin', 'SeMenu_CompareScreen_DataTable_0x278', 40),
        ('v7_block_tuningsys_param_01_0x25e.bin', 'TuningSys_Param_01_0x25E', 4),
        ('v7_block_tuningsystem_handler_table_0x3c.bin', 'TuningSystem_Handler_Table_0x3C', 25),
        ('v7_block_tuningsystem_handler_table_0x69.bin', 'TuningSystem_Handler_Table_0x69', 25),
        ('v7_block_tuningsystem_handler_table_0x82.bin', 'TuningSystem_Handler_Table_0x82', 11),
        ('v7_block_tuningsystem_handler_table_0x8d.bin', 'TuningSystem_Handler_Table_0x8D', 62),
        ('v7_block_tuningsystem_handler_table_0xcb.bin', 'TuningSystem_Handler_Table_0xCB', 20),
        ('v7_block_tuningsystem_handler_table_0xdf.bin', 'TuningSystem_Handler_Table_0xDF', 68),
        ('v7_block_tuningsystem_handler_table_0x15f.bin', 'TuningSystem_Handler_Table_0x15F', 20),
        ('v7_block_tuningsystem_handler_table_0x1e1.bin', 'TuningSystem_Handler_Table_0x1E1', 180),
        ('v7_block_tuningsystem_handler_table_0x295.bin', 'TuningSystem_Handler_Table_0x295', 44),
        ('v7_block_tuningsystem_handler_table_0x2c1.bin', 'TuningSystem_Handler_Table_0x2C1', 16),
        ('v7_block_tuningsystem_handler_table_0x3c9.bin', 'TuningSystem_Handler_Table_0x3C9', 40),
        ('v7_block_tuningsystem_handler_table_0x628.bin', 'TuningSystem_Handler_Table_0x628', 11),
        ('v7_block_tuningsystem_handler_table_0x633.bin', 'TuningSystem_Handler_Table_0x633', 28),
        ('v7_block_tuningsystem_handler_table_0x64f.bin', 'TuningSystem_Handler_Table_0x64F', 28),
        ('v7_block_tuningsystem_handler_table_0xfe0.bin', 'TuningSystem_Handler_Table_0xFE0', 72),
        ('v7_block_tuningsystem_handler_table_0x1028.bin', 'TuningSystem_Handler_Table_0x1028', 24),
        ('v7_block_tuningsystem_handler_table_0x1040.bin', 'TuningSystem_Handler_Table_0x1040', 96),
        ('v7_block_tuningsystem_handler_table_0x10a0.bin', 'TuningSystem_Handler_Table_0x10A0', 60),
        ('v7_block_tuningsystem_handler_table_0x110e.bin', 'TuningSystem_Handler_Table_0x110E', 60),
        ('v7_block_tuningsystem_handler_table_0x114a.bin', 'TuningSystem_Handler_Table_0x114A', 51),
        ('v7_block_tuningsystem_handler_table_0x117d.bin', 'TuningSystem_Handler_Table_0x117D', 192),
        ('v7_block_tuningsystem_handler_table_0x126f.bin', 'TuningSystem_Handler_Table_0x126F', 71),
        ('v7_block_tuningsystem_handler_table_0x12b6.bin', 'TuningSystem_Handler_Table_0x12B6', 20),
        ('v7_block_tuningsystem_handler_table_0x12fc.bin', 'TuningSystem_Handler_Table_0x12FC', 51),
        ('v7_block_tuningsystem_handler_table_0x132f.bin', 'TuningSystem_Handler_Table_0x132F', 20),
        ('v7_block_tuningsystem_handler_table_0x1343.bin', 'TuningSystem_Handler_Table_0x1343', 87),
        ('v7_block_tuningsystem_handler_table_0x139a.bin', 'TuningSystem_Handler_Table_0x139A', 92),
        ('v7_block_tuningsystem_handler_table_0x1592.bin', 'TuningSystem_Handler_Table_0x1592', 30),
        ('v7_block_tuningsystem_handler_table_0x15b0.bin', 'TuningSystem_Handler_Table_0x15B0', 111),
        ('v7_block_tuningsystem_handler_table_0x161f.bin', 'TuningSystem_Handler_Table_0x161F', 962),
        ('v7_block_tuningsystem_handler_table_0x19e1.bin', 'TuningSystem_Handler_Table_0x19E1', 30),
        ('v7_block_tuningsystem_handler_table_0x1e73.bin', 'TuningSystem_Handler_Table_0x1E73', 24),
        ('v7_block_tuningsystem_handler_table_0x23bd.bin', 'TuningSystem_Handler_Table_0x23BD', 96),
        ('v7_block_tuningsystem_handler_table_0x241d.bin', 'TuningSystem_Handler_Table_0x241D', 15),
        ('v7_block_tuningsystem_handler_table_0x242c.bin', 'TuningSystem_Handler_Table_0x242C', 30),
        ('v7_block_drumdetailedit_menu_table_0x27b.bin', 'DrumDetailEdit_Menu_Table_0x27B', 55),
        ('v7_block_drumdetailedit_menu_table_0x2b2.bin', 'DrumDetailEdit_Menu_Table_0x2B2', 20),
        ('v7_block_drumdetailedit_menu_table_0x2e8.bin', 'DrumDetailEdit_Menu_Table_0x2E8', 66),
        ('v7_block_drumdetailedit_menu_table_0x32a.bin', 'DrumDetailEdit_Menu_Table_0x32A', 52),
        ('v7_block_effectparamedit_entry_02.bin', 'EffectParamEdit_Entry_02', 15),
        ('v7_block_effectparamedit_entry_08.bin', 'EffectParamEdit_Entry_08', 11),
        ('v7_block_drumdetailedit_menu_table_0x3c8.bin', 'DrumDetailEdit_Menu_Table_0x3C8', 56),
        ('v7_block_accscreen_uidatablock_0x1e7.bin', 'AccScreen_UIDataBlock_0x1E7', 111),
        ('v7_block_accscreen_uidatablock_0x256.bin', 'AccScreen_UIDataBlock_0x256', 59),
        ('v7_block_accscreen_uidatablock_0x291.bin', 'AccScreen_UIDataBlock_0x291', 41),
        ('v7_block_accscreen_uidatablock_0x2ba.bin', 'AccScreen_UIDataBlock_0x2BA', 135),
        ('v7_block_accscreen_uidatablock_0x341.bin', 'AccScreen_UIDataBlock_0x341', 21),
        ('v7_block_accscreen_uidatablock_0x356.bin', 'AccScreen_UIDataBlock_0x356', 10),
        ('v7_block_accscreen_uidatablock_0x360.bin', 'AccScreen_UIDataBlock_0x360', 30),
        ('v7_block_accscreen_uidatablock_0x386.bin', 'AccScreen_UIDataBlock_0x386', 10),
        ('v7_block_accscreen_uidatablock_0x390.bin', 'AccScreen_UIDataBlock_0x390', 40),
        ('v7_block_accscreen_uidatablock_0x3b8.bin', 'AccScreen_UIDataBlock_0x3B8', 254),
        ('v7_block_accscreen_uidatablock_0x804.bin', 'AccScreen_UIDataBlock_0x804', 37),
        ('v7_block_accscreen_uidatablock_0x829.bin', 'AccScreen_UIDataBlock_0x829', 7),
        ('v7_block_accstyle_tabledataentry_0x90.bin', 'AccStyle_TableDataEntry_0x90', 972),
        ('v7_block_msp_factorypresetdata_continued.bin', 'MSP_FactoryPresetData_Continued', 2676),
        ('v7_block_colorblit2_largecodeblock_0x3f0.bin', 'ColorBlit2_LargeCodeBlock_0x3F0', 2025),
        ('v7_block_colorblit2_largecodeblock_0xbd9.bin', 'ColorBlit2_LargeCodeBlock_0xBD9', 1886),
        ('v7_block_midistream_handlerunningstatus_0x98.bin', 'MidiStream_HandleRunningStatus_0x98', 1292),
        # Code labels in source with v7-specific data
        ('v7_block_boot_readfdcstatus.bin', 'Boot_ReadFDCStatus', 5),
        # REMOVED 3638),
        ('v7_block_free_x.bin', 'free_X', 8),
        ('v7_block_accstate_readaccompparams.bin', 'AccState_ReadAccompParams', 43),
        ('v7_block_rhythm_tailpadding.bin', 'Rhythm_TailPadding', 5),
        ('v7_block_accscreen_uidatablock.bin', 'AccScreen_UIDataBlock', 2096),
        ('v7_block_accstyle_tabledataentry.bin', 'AccStyle_TableDataEntry', 144),
        ('v7_block_voice_initbanktables_slotloop.bin', 'Voice_InitBankTables_SlotLoop', 21),
        ('v7_block_msp_factory_defaults.bin', 'MSP_FACTORY_DEFAULTS', 2700),
        ('v7_block_voiceui_mischandler.bin', 'VoiceUI_MiscHandler', 93),
        ('v7_block_numtoascii_onesdigitandfinish.bin', 'NumToAscii_OnesDigitAndFinish', 28),
        ('v7_block_dispseqlist_loopbody.bin', 'DispSeqList_LoopBody', 102),
        ('v7_block_buildslotlabel_writecontent.bin', 'BuildSlotLabel_WriteContent', 34),
        ('v7_block_initializeroot.bin', 'InitializeRoot', 571),
        ('v7_block_rvari_select_checksamebank.bin', 'RVari_Select_CheckSameBank', 931),
        ('v7_block_actranspose_formatlabel.bin', 'AcTranspose_FormatLabel', 28),
        # REMOVED 3381),
        ('v7_block_midicc_resetstate.bin', 'MidiCC_ResetState', 11),
        ('v7_block_encoder_configurerangelimit.bin', 'Encoder_ConfigureRangeLimit', 23),
        ('v7_block_soundparam_notifychange.bin', 'SoundParam_NotifyChange', 85),
        ('v7_block_sndparam_heapallocok.bin', 'SndParam_HeapAllocOK', 13),
        ('v7_block_sc0txenable_return.bin', 'SC0TxEnable_Return', 2),
        ('v7_block_voiceparam_lookupandenqueue.bin', 'VoiceParam_LookupAndEnqueue', 60),
        ('v7_block_midipkt_sysexbulktransfer_data.bin', 'MidiPkt_SysExBulkTransfer_Data', 547),
        ('v7_block_dspcfg_returnvaluetable.bin', 'DSPCfg_ReturnValueTable', 21),
        ('v7_block_screengroup_initfinalize.bin', 'ScreenGroup_InitFinalize', 34),
        ('v7_block_audioinit_initpartsendlevels.bin', 'AudioInit_InitPartSendLevels', 77),
        ('v7_block_math_absint16.bin', 'Math_AbsInt16', 10),
    ]

    for bin_name, label, size in v7_code_blocks:
        addr = elf_addrs.get(label)
        if addr:
            rom_off = addr - ROM_BASE
            data = v7_rom[rom_off:rom_off + size]
            bin_path = os.path.join(gen_dir, bin_name)
            with open(bin_path, 'wb') as f:
                f.write(data)


    # Interrupt vector trampolines: fixed offset after MidiStream_HandleRunningStatus
    midi_addr = elf_addrs.get('MidiStream_HandleRunningStatus')
    if midi_addr:
        tramp_off = midi_addr + 1444 - 0xe00000
        tramp_data = v7_rom[tramp_off:tramp_off+525]
        tramp_path = os.path.join(gen_dir, 'v7_block_interrupt_vector_trampolines.bin')
        with open(tramp_path, 'wb') as f:
            f.write(tramp_data)

    print(f"Extracted {len(v7_code_blocks)} v7-specific code blocks (using {os.path.basename(elf_for_addrs)})")

# Transplant bins: generated by v7_incbin_transplant.py, regenerated here from manifest
manifest_path = 'v7/maincpu/transplant_manifest.txt'
if os.path.exists(manifest_path):
    transplant_count = 0
    with open(manifest_path) as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                bin_name, label, size = parts[0], parts[1], int(parts[2])
                addr = elf_addrs.get(label) if 'elf_addrs' in dir() else None
                if addr:
                    rom_off = addr - ROM_BASE
                    if 0 <= rom_off and rom_off + size <= len(v7_rom):
                        data = v7_rom[rom_off:rom_off + size]
                        bin_path = os.path.join(gen_dir, bin_name)
                        with open(bin_path, 'wb') as f2:
                            f2.write(data)
                        transplant_count += 1
    print(f"Regenerated {transplant_count} transplant bins from manifest")

