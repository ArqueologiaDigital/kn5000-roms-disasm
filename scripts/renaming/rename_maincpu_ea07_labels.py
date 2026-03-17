#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region EA0760-EA9DF4."""
import os, re

RENAMES = [
    # --- SMF conversion mode strings (EA0760-EA0780) ---
    # These are display strings for MIDI conversion mode selection:
    # "  GM ~8d TECH" / "TECH ~8d TECH" / "  GM ~8d GM  "
    # Referenced by a pointer table just above (3 entries).
    ('LABEL_EA0760', 'Str_SmfConvert_GmToTech', 'SMF convert mode string: GM->TECH'),
    ('LABEL_EA0770', 'Str_SmfConvert_TechToTech', 'SMF convert mode string: TECH->TECH'),
    ('LABEL_EA0780', 'Str_SmfConvert_GmToGm', 'SMF convert mode string: GM->GM'),

    # --- Sequencer memory bank name strings (EA07BA-EA07DA) ---
    # Display strings for sequencer memory slot labels A/B/C.
    ('LABEL_EA07BA', 'Str_MemorySlot_C', 'Sequencer memory slot C label string'),
    ('LABEL_EA07CA', 'Str_MemorySlot_B', 'Sequencer memory slot B label string'),
    ('LABEL_EA07DA', 'Str_MemorySlot_A', 'Sequencer memory slot A label string'),

    # --- Sequencer variation name pointer table (EA07EA) ---
    # Pointer table for variation name strings (VARI 1-4).
    ('LABEL_EA07EA', 'PtrTbl_VariationNames', 'Pointer table for variation name strings'),

    # --- Padding/separator entries before variation names ---
    ('LABEL_EA0814', 'Data_VariPad_EA0814', 'Padding entry before variation names'),
    ('LABEL_EA0816', 'Data_VariPad_EA0816', 'Padding entry before variation names'),
    ('LABEL_EA0818', 'Data_VariPad_EA0818', 'Padding entry before variation names'),
    ('LABEL_EA081C', 'Data_VariPad_EA081C', 'Padding entry before variation names'),

    # --- Variation name strings (EA081E-EA0836) ---
    # Display strings for sequencer variation slots 1-4.
    ('LABEL_EA081E', 'Str_Variation4', 'Variation 4 label string'),
    ('LABEL_EA0826', 'Str_Variation3', 'Variation 3 label string'),
    ('LABEL_EA082E', 'Str_Variation2', 'Variation 2 label string'),
    ('LABEL_EA0836', 'Str_Variation1', 'Variation 1 label string'),

    # --- Rhythm section name pointer table (EA084E) ---
    # Pointer table for rhythm pattern section names (INTRO/FILL IN/ENDING).
    ('LABEL_EA084E', 'PtrTbl_RhythmSectionNames', 'Pointer table for rhythm section name strings'),

    # --- Rhythm section name strings (EA0866-EA08C0) ---
    ('LABEL_EA0866', 'Str_Ending2', 'Rhythm section: ENDING 2'),
    ('LABEL_EA0878', 'Str_Ending1', 'Rhythm section: ENDING 1'),
    ('LABEL_EA088A', 'Str_FillIn2', 'Rhythm section: FILL IN 2'),
    ('LABEL_EA089C', 'Str_FillIn1', 'Rhythm section: FILL IN 1'),
    ('LABEL_EA08AE', 'Str_Intro2', 'Rhythm section: INTRO 2'),
    ('LABEL_EA08C0', 'Str_Intro1', 'Rhythm section: INTRO 1'),

    # --- Padding before drum kit name strings (EA08D4-EA08D8) ---
    # Followed by pointer table referencing "USER KIT", "MEMORY B", "MEMORY A".
    ('LABEL_EA08D4', 'Data_DrumKitPad_EA08D4', 'Padding before drum kit name pointer table'),
    ('LABEL_EA08D6', 'Data_DrumKitPad_EA08D6', 'Padding before drum kit name pointer table'),
    ('LABEL_EA08D8', 'PtrTbl_DrumKitNames', 'Pointer table for drum kit name strings (USER KIT/MEMORY A/B)'),

    # --- "ALL" option strings for various save/load menus (EA0980, EA09B2) ---
    # These "ALL" strings appear in disk save/load option menus.
    ('LABEL_EA0980', 'Str_AllOption_EA0980', 'ALL option label for save/load menu'),
    ('LABEL_EA09B2', 'Str_AllOption_EA09B2', 'ALL option label for save/load menu'),

    # --- Save/load menu data table (EA09F0) ---
    # Large data block containing address pointers for save/load handler functions.
    ('LABEL_EA09F0', 'Data_SaveLoadMenuTable', 'Save/load menu handler address data table'),

    # --- Disk function name pointer table (EA0ACE) ---
    # Points to UI function name strings for disk operations
    # (WaitingFunc, FormatDiskNaming, SmfFileNaming, etc.)
    ('LABEL_EA0ACE', 'PtrTbl_DiskFuncNames', 'Pointer table for disk UI function name strings'),

    # --- Disk function name pointer table continuation entries ---
    # EA0B00 and EA0B12 are continuation data for the pointer table above.
    ('LABEL_EA0B00', 'Data_DiskFuncPtrTbl_EA0B00', 'Disk function pointer table data (addresses)'),
    ('LABEL_EA0B12', 'Data_DiskFuncPtrTbl_EA0B12', 'Disk function pointer table data (addresses)'),

    # --- Password UI null/separator entry (EA0B46) ---
    ('LABEL_EA0B46', 'Data_PasswordSep_EA0B46', 'Null/separator entry before password UI name strings'),

    # --- Password/disk UI function name strings (EA0B48-EA0CD6) ---
    # These are UI widget/callback identifiers stored as strings.
    ('LABEL_EA0B48', 'Str_CheckPasswordNo', 'UI name: CheckPasswordNo'),
    ('LABEL_EA0B58', 'Str_CheckPasswordOk', 'UI name: CheckPasswordOk'),
    ('LABEL_EA0B68', 'Str_CheckPasswordText', 'UI name: CheckPasswordText'),
    ('LABEL_EA0B7A', 'Str_PasswordText', 'UI name: PasswordText'),
    ('LABEL_EA0B88', 'Str_PasswordNo', 'UI name: PasswordNo'),
    ('LABEL_EA0B94', 'Str_PasswordOk', 'UI name: PasswordOk'),
    ('LABEL_EA0BA0', 'Str_WakeUpPassword', 'UI name: WakeUpPassword'),
    ('LABEL_EA0BB0', 'Str_SaveNo', 'UI name: SaveNo'),
    ('LABEL_EA0BB8', 'Str_SaveYes', 'UI name: SaveYes'),
    ('LABEL_EA0BC0', 'Str_DeleteNo', 'UI name: DeleteNo'),
    ('LABEL_EA0BCA', 'Str_DeleteYes', 'UI name: DeleteYes'),
    ('LABEL_EA0BD4', 'Str_SaveText', 'UI name: SaveText'),
    ('LABEL_EA0BDE', 'Str_DeleteText', 'UI name: DeleteText'),
    ('LABEL_EA0BEA', 'Str_FormatText', 'UI name: FormatText'),
    ('LABEL_EA0BF6', 'Str_DiskSure', 'UI name: DiskSure'),
    ('LABEL_EA0C00', 'Str_DiskAttention', 'UI name: DiskAttention'),
    ('LABEL_EA0C0E', 'Str_DiskMedleyShowHideFunc', 'UI name: DiskMedleyShowHideFunc'),
    ('LABEL_EA0C26', 'Str_WaitingFunc', 'UI name: WaitingFunc'),
    ('LABEL_EA0C32', 'Str_FormatDiskNaming', 'UI name: FormatDiskNaming'),
    ('LABEL_EA0C44', 'Str_SmfFileNaming', 'UI name: SmfFileNaming'),
    ('LABEL_EA0C52', 'Str_SmfFileRename', 'UI name: SmfFileRename'),
    ('LABEL_EA0C60', 'Str_TechnicsFileRename', 'UI name: TechnicsFileRename'),
    ('LABEL_EA0C74', 'Str_TechnicsFileNaming', 'UI name: TechnicsFileNaming'),
    ('LABEL_EA0C88', 'Str_SetupExitFunc', 'UI name: SetupExitFunc'),
    ('LABEL_EA0C96', 'Str_SetupOkFunc', 'UI name: SetupOkFunc'),
    ('LABEL_EA0CA2', 'Str_FilePriorityFunc', 'UI name: FilePriorityFunc'),
    ('LABEL_EA0CB4', 'Str_JumpInsertFunc', 'UI name: JumpInsertFunc'),
    ('LABEL_EA0CC4', 'Str_TypePriorityText', 'UI name: TypePriorityText'),
    ('LABEL_EA0CD6', 'Str_InsertOptionText', 'UI name: InsertOptionText'),

    # --- Disk UI options pointer table (EA0CE8) ---
    # Points to a set of UI widget property name strings (font, fontcolor, main_func, etc.)
    ('LABEL_EA0CE8', 'PtrTbl_UiWidgetProps_EA0CE8', 'Pointer table for UI widget property name strings'),

    # --- UI widget property name strings (EA0D14-EA0D5C) ---
    # Property name identifiers used in the UI framework for widget configuration.
    ('LABEL_EA0D14', 'Str_UiProp_Empty_EA0D14', 'UI property: empty string sentinel'),
    ('LABEL_EA0D16', 'Str_UiProp_Aicok', 'UI property: aicok'),
    ('LABEL_EA0D1C', 'Str_UiProp_Paintok', 'UI property: paintok'),
    ('LABEL_EA0D24', 'Str_UiProp_AutoInc', 'UI property: auto_inc'),
    ('LABEL_EA0D2E', 'Str_UiProp_Dial', 'UI property: dial'),
    ('LABEL_EA0D34', 'Str_UiProp_SelNum', 'UI property: sel_num'),
    ('LABEL_EA0D3C', 'Str_UiProp_Row', 'UI property: row'),
    ('LABEL_EA0D40', 'Str_UiProp_Column', 'UI property: column'),
    ('LABEL_EA0D48', 'Str_UiProp_MainFunc', 'UI property: main_func'),
    ('LABEL_EA0D52', 'Str_UiProp_FontColor', 'UI property: fontcolor'),
    ('LABEL_EA0D5C', 'Str_UiProp_Font', 'UI property: font'),

    # --- UI widget property separator/null (EA0D72) ---
    ('LABEL_EA0D72', 'Data_UiWidgetSep_EA0D72', 'Separator/null before UI widget property block'),

    # --- Additional UI property string blocks ---
    # EA0D74, EA0D7E (jr nc, 0x66 is actually a string byte: "f"), EA0D86, EA0D94-EA0DB6
    ('LABEL_EA0D74', 'Str_UiProp_MainFunc_EA0D74', 'UI property: main_func (second instance)'),
    ('LABEL_EA0D7E', 'Str_UiProp_FwOn_EA0D7E', 'UI property string: fwin/fwon area'),
    ('LABEL_EA0D86', 'Str_UiProp_Win_EA0D86', 'UI property: win'),
    ('LABEL_EA0D94', 'Str_UiProp_Empty_EA0D94', 'UI property: empty string sentinel'),
    ('LABEL_EA0D96', 'Str_UiProp_MainFunc_EA0D96', 'UI property: main_func (third instance)'),
    ('LABEL_EA0DAC', 'Str_UiProp_Empty_EA0DAC', 'UI property: empty string sentinel'),
    ('LABEL_EA0DAE', 'Str_UiProp_Paintok_EA0DAE', 'UI property: paintok (second instance)'),
    ('LABEL_EA0DB6', 'Str_UiProp_MainFunc_EA0DB6', 'UI property: main_func (fourth instance)'),

    # --- UI widget property pointer table (EA0DC0) ---
    ('LABEL_EA0DC0', 'PtrTbl_UiWidgetProps_EA0DC0', 'Pointer table for UI widget property strings (font group)'),
    ('LABEL_EA0DD0', 'Str_UiProp_Empty_EA0DD0', 'UI property: empty string sentinel'),
    ('LABEL_EA0DD2', 'Str_UiProp_Paintok_EA0DD2', 'UI property: paintok (third instance)'),
    ('LABEL_EA0DDA', 'Str_UiProp_MainFunc_EA0DDA', 'UI property: main_func (fifth instance)'),
    ('LABEL_EA0DE4', 'Str_UiProp_Font_EA0DE4', 'UI property: font (second instance)'),

    # --- Index property separator (EA0DF2) ---
    ('LABEL_EA0DF2', 'Data_IndexPropSep_EA0DF2', 'Separator before index property block'),
    ('LABEL_EA0DF4', 'Str_UiProp_Index', 'UI property: index'),

    # --- Main function property separator (EA0E02) ---
    ('LABEL_EA0E02', 'Data_MainFuncPropSep_EA0E02', 'Separator before main_func property block'),
    ('LABEL_EA0E04', 'Str_UiProp_MainFunc_EA0E04', 'UI property: main_func (sixth instance)'),

    # --- Page/icon/title property separator (EA0E1E) ---
    ('LABEL_EA0E1E', 'Data_PageIconPropSep_EA0E1E', 'Separator before page/icon/title property block'),
    ('LABEL_EA0E20', 'Str_UiProp_Page', 'UI property: page'),
    ('LABEL_EA0E26', 'Str_UiProp_Icon', 'UI property: icon'),
    ('LABEL_EA0E2C', 'Str_UiProp_Title', 'UI property: title'),

    # --- Tail rate / frame / color property pointer table (EA0E32) ---
    ('LABEL_EA0E32', 'PtrTbl_UiWidgetProps_EA0E32', 'Pointer table for UI widget property strings (tail/frame/color)'),
    ('LABEL_EA0E4A', 'Data_TailPropSep_EA0E4A', 'Separator before tail/frame/color property block'),
    ('LABEL_EA0E4C', 'Str_UiProp_TailYRate', 'UI property: tail_y_rate'),
    ('LABEL_EA0E58', 'Str_UiProp_TailXRate', 'UI property: tail_x_rate'),
    ('LABEL_EA0E64', 'Str_UiProp_Dir', 'UI property: dir'),
    ('LABEL_EA0E68', 'Str_UiProp_FrameOnly', 'UI property: frame_only'),
    ('LABEL_EA0E74', 'Str_UiProp_Color', 'UI property: color'),

    # --- Dial/auto-inc property pointer table (EA0E7A) ---
    ('LABEL_EA0E7A', 'PtrTbl_UiWidgetProps_EA0E7A', 'Pointer table for UI widget property strings (dial/auto_inc group)'),
    ('LABEL_EA0E92', 'Data_DialPropSep_EA0E92', 'Separator before dial/auto_inc property block'),
    ('LABEL_EA0E94', 'Str_UiProp_AutoInc_EA0E94', 'UI property: auto_inc (second instance)'),
    ('LABEL_EA0E9E', 'Str_UiProp_DialInv', 'UI property: dial_inv'),
    ('LABEL_EA0EA8', 'Str_UiProp_Dial_EA0EA8', 'UI property: dial (second instance)'),
    ('LABEL_EA0EAE', 'Str_UiProp_IndexMax', 'UI property: index_max'),
    ('LABEL_EA0EB8', 'Str_UiProp_IndexMin', 'UI property: index_min'),

    # --- Paintok/length/interval/func property pointer table (EA0EC2) ---
    ('LABEL_EA0EC2', 'PtrTbl_UiWidgetProps_EA0EC2', 'Pointer table for UI widget property strings (paintok/length/func)'),
    ('LABEL_EA0ED6', 'Data_PaintokPropSep_EA0ED6', 'Separator before paintok/length property block'),
    ('LABEL_EA0ED8', 'Str_UiProp_Paintok_EA0ED8', 'UI property: paintok (fourth instance)'),
    ('LABEL_EA0EE0', 'Str_UiProp_Length', 'UI property: length'),
    ('LABEL_EA0EE8', 'Str_UiProp_Interval', 'UI property: interval'),
    ('LABEL_EA0EF2', 'Str_UiProp_Func', 'UI property: func'),

    # --- Send index / interval property pointer table (EA0EF8) ---
    ('LABEL_EA0EF8', 'PtrTbl_UiWidgetProps_EA0EF8', 'Pointer table for UI widget property strings (send_index group)'),
    ('LABEL_EA0F0C', 'Str_UiProp_Empty_EA0F0C', 'UI property: empty string sentinel'),
    ('LABEL_EA0F0E', 'Str_UiProp_SendIndex', 'UI property: send_index'),
    ('LABEL_EA0F1A', 'Str_UiProp_Interval_EA0F1A', 'UI property: interval (second instance)'),
    ('LABEL_EA0F24', 'Str_UiProp_IndexMax_EA0F24', 'UI property: index_max (second instance)'),
    ('LABEL_EA0F2E', 'Str_UiProp_IndexMin_EA0F2E', 'UI property: index_min (second instance)'),
    ('LABEL_EA0F40', 'Str_UiProp_Empty_EA0F40', 'UI property: empty string sentinel (win group)'),

    # --- Win/address data entry (EA0F42) ---
    # Contains "win\0" string followed by an address pointer (F9:5557).
    ('LABEL_EA0F42', 'Data_WinProp_EA0F42', 'UI property: win string + handler address'),

    # --- Event name pointer table (EA1188) ---
    # Points to event name strings used for wake-up and index switch events.
    ('LABEL_EA1188', 'PtrTbl_EventNames_EA1188', 'Pointer table for UI event name strings'),

    # --- Event name strings (EA11A0-EA11E2) ---
    ('LABEL_EA11A0', 'Str_Ev_WakeUpPassword', 'Event name string: EV_WAKEUPPASSWORD'),
    ('LABEL_EA11B2', 'Str_Ev_IndexSwDownD', 'Event name string: EV_INDEXSW_DOWN_D'),
    ('LABEL_EA11C4', 'Str_Ev_IndexSwUpD', 'Event name string: EV_INDEXSW_UP_D'),
    ('LABEL_EA11D4', 'Str_Ev_NotPostAic', 'Event name string: EV_NOTPOSTAIC'),
    ('LABEL_EA11E2', 'Str_Ev_NotParaDraw', 'Event name string: EV_NOTPARADRAW'),

    # --- Message type name pointer table (EA11F8) ---
    # Points to message type name strings (MT_* identifiers).
    ('LABEL_EA11F8', 'PtrTbl_MsgTypeNames_EA11F8', 'Pointer table for message type name strings (MT_*)'),

    # --- Message type name strings (EA123C-EA133C) ---
    ('LABEL_EA123C', 'Str_Mt_CheckPassword3', 'Message type name: MT_CheckPassword3'),
    ('LABEL_EA124E', 'Str_Mt_CheckPassword2', 'Message type name: MT_CheckPassword2'),
    ('LABEL_EA1260', 'Str_Mt_CheckPassword', 'Message type name: MT_CheckPassword'),
    ('LABEL_EA1272', 'Str_Mt_SetPassword', 'Message type name: MT_SetPassword'),
    ('LABEL_EA1282', 'Str_Mt_FlashLoad', 'Message type name: MT_FlashLoad'),
    ('LABEL_EA1290', 'Str_Mt_FlashWrite', 'Message type name: MT_FlashWrite'),
    ('LABEL_EA129E', 'Str_Mt_WakeUpNow', 'Message type name: MT_WakeUpNow'),
    ('LABEL_EA12AC', 'Str_Mt_WakeUpTime', 'Message type name: MT_WakeUpTime'),
    ('LABEL_EA12BA', 'Str_Mt_IWillWakeUp', 'Message type name: MT_IWillWakeUp'),
    ('LABEL_EA12CA', 'Str_Mt_WhichWindow', 'Message type name: MT_WhichWindow'),
    ('LABEL_EA12DA', 'Str_Mt_OffWindow', 'Message type name: MT_OffWindow'),
    ('LABEL_EA12E8', 'Str_Mt_OnWindow', 'Message type name: MT_OnWindow'),
    ('LABEL_EA12F4', 'Str_Mt_PsFileNameBoxId', 'Message type name: MT_PsFileNameBoxID'),
    ('LABEL_EA1308', 'Str_Mt_GetSelectedFileNumber', 'Message type name: MT_GetSelectedFileNumber'),
    ('LABEL_EA1322', 'Str_Mt_SetSelectedFileNumber', 'Message type name: MT_SetSelectedFileNumber'),
    ('LABEL_EA133C', 'Str_Mt_SetFileSfx', 'Message type name: MT_SetFileSfx'),

    # --- Naka module handler pointer table (EA1392) ---
    # Large pointer table for naka UI module handlers (disk save/load operations).
    ('LABEL_EA1392', 'PtrTbl_NakaModuleHandlers', 'Pointer table for naka UI module handler functions'),

    # --- Naka module separator (EA13CA) ---
    ('LABEL_EA13CA', 'Data_NakaSep_EA13CA', 'Null/separator entry before naka include section'),

    # --- Disk format warning text pointer table (EA8CE0) ---
    # Points to multi-language DISK FORMAT warning strings.
    ('LABEL_EA8CE0', 'PtrTbl_DiskFormatWarning', 'Pointer table for multi-language DISK FORMAT warning strings'),

    # --- DISK FORMAT warning strings by language (EA8CF4-EA8E04) ---
    ('LABEL_EA8CF4', 'Str_DiskFormatWarn_Indonesian', 'DISK FORMAT warning (Indonesian)'),
    ('LABEL_EA8D44', 'Str_DiskFormatWarn_English', 'DISK FORMAT warning (English)'),
    ('LABEL_EA8D80', 'Str_DiskFormatWarn_Spanish', 'DISK FORMAT warning (Spanish)'),

    # --- FILE DELETE warning text pointer table (EA8E70) ---
    # Points to multi-language FILE DELETE warning strings.
    ('LABEL_EA8E70', 'PtrTbl_FileDeleteWarning', 'Pointer table for multi-language FILE DELETE warning strings'),

    # --- FILE DELETE warning strings by language ---
    ('LABEL_EA8EFE', 'Str_FileDeleteWarn_English', 'FILE DELETE warning (English)'),
    ('LABEL_EA90B6', 'Str_FileDeleteWarn_English2', 'FILE DELETE warning (English, duplicate)'),

    # --- Disk auto-open preference pointer table (EA9440) ---
    # Points to multi-language strings for "When a disk is inserted open this page."
    ('LABEL_EA9440', 'PtrTbl_DiskInsertOpenPage', 'Pointer table for multi-language disk-insert page strings'),

    # --- Disk auto-open preference strings by language (EA9454-EA94F4) ---
    ('LABEL_EA9454', 'Str_DiskInsertOpen_Lang0', 'Disk insert open page message (language 0)'),
    ('LABEL_EA947C', 'Str_DiskInsertOpen_Lang1', 'Disk insert open page message (language 1)'),
    ('LABEL_EA94A4', 'Str_DiskInsertOpen_Lang2', 'Disk insert open page message (language 2)'),
    ('LABEL_EA94CC', 'Str_DiskInsertOpen_Lang3', 'Disk insert open page message (language 3)'),

    # --- File type priority pointer table (EA9558) ---
    # Points to multi-language "When a disk contains Technics & SMF files" strings.
    ('LABEL_EA9558', 'PtrTbl_FilePriorityMsg', 'Pointer table for multi-language file priority strings'),

    # --- File type priority strings by language (EA9570-EA965E) ---
    ('LABEL_EA9570', 'Str_FilePriority_Lang0', 'File priority message (language 0)'),
    ('LABEL_EA959C', 'Str_FilePriority_Lang1', 'File priority message (language 1)'),
    ('LABEL_EA95C8', 'Str_FilePriority_Lang2', 'File priority message (language 2)'),
    ('LABEL_EA95F4', 'Str_FilePriority_Lang3', 'File priority message (language 3)'),
    ('LABEL_EA965E', 'Str_FilePriority_Lang5', 'File priority message (language 5)'),

    # --- Disk startup mode name pointer table (EA968A) ---
    # Points to disk startup mode name strings:
    # SONG MEDLEY, DIRECT PLAY, LOAD, DISK MENU, OFF
    ('LABEL_EA968A', 'PtrTbl_DiskStartupModeNames', 'Pointer table for disk startup mode name strings'),

    # --- Disk startup mode name strings (EA969E-EA96D6) ---
    ('LABEL_EA969E', 'Str_DiskMode_SongMedley', 'Disk startup mode: SONG MEDLEY'),
    ('LABEL_EA96AC', 'Str_DiskMode_DirectPlay', 'Disk startup mode: DIRECT PLAY'),
    ('LABEL_EA96BA', 'Str_DiskMode_Load', 'Disk startup mode: LOAD'),
    ('LABEL_EA96C8', 'Str_DiskMode_DiskMenu', 'Disk startup mode: DISK MENU'),
    ('LABEL_EA96D6', 'Str_DiskMode_Off', 'Disk startup mode: OFF'),

    # --- File type label strings (EA9700-EA970C) ---
    ('LABEL_EA9700', 'Str_FileType_Smf', 'File type label: SMF'),
    ('LABEL_EA970C', 'Str_FileType_Technics', 'File type label: TECHNICS'),

    # --- Please wait string pointer table (EA9718) ---
    # Points to multi-language "PLEASE WAIT!" strings.
    ('LABEL_EA9718', 'PtrTbl_PleaseWaitStrings', 'Pointer table for multi-language PLEASE WAIT strings'),

    # --- Please wait strings by language (EA9730-EA97D8) ---
    ('LABEL_EA9730', 'Str_PleaseWait_Indonesian', 'PLEASE WAIT string (Indonesian: SILAHKAN TUNGGU!)'),
    ('LABEL_EA9752', 'Str_PleaseWait_English', 'PLEASE WAIT string (English)'),
    ('LABEL_EA976C', 'Str_PleaseWait_Spanish', 'PLEASE WAIT string (Spanish)'),
    ('LABEL_EA9794', 'Str_PleaseWait_French', 'PLEASE WAIT string (French: VEUILLEZ PATIENTER!)'),
    ('LABEL_EA97BC', 'Str_PleaseWait_German', 'PLEASE WAIT string (German: BITTE WARTEN!)'),
    ('LABEL_EA97D8', 'Str_PleaseWait_English2', 'PLEASE WAIT string (English, duplicate)'),

    # --- Disk save type name strings (EA9816-EA984E) ---
    # Labels for the types of data saved to disk.
    ('LABEL_EA9816', 'Str_SaveType_UserMidi', 'Save type label: USER MIDI'),
    ('LABEL_EA9824', 'Str_SaveType_RhythmCustom', 'Save type label: RHYTHM CUSTOM'),
    ('LABEL_EA9832', 'Str_SaveType_Msp', 'Save type label: MSP'),
    ('LABEL_EA9840', 'Str_SaveType_SoundMemory', 'Save type label: SOUND MEMORY'),
    ('LABEL_EA984E', 'Str_SaveType_Composer', 'Save type label: COMPOSER'),

    # --- Numeric data table (EA98E2) ---
    # Large numeric data table, likely scroll velocity or animation timing values.
    ('LABEL_EA98E2', 'Data_ScrollVelocityTable', 'Scroll velocity or animation timing data table'),

    # --- Character set label strings (EA9BFE-EA9C1A) ---
    # These label the three character entry keyboard modes.
    ('LABEL_EA9BFE', 'Str_CharSet_Symbols', 'Character set label: symbols (!#$%&?...)'),
    ('LABEL_EA9C0C', 'Str_CharSet_Lowercase', 'Character set label: lowercase (abc...123...)'),
    ('LABEL_EA9C1A', 'Str_CharSet_Uppercase', 'Character set label: uppercase (ABC...123...)'),

    # --- Uppercase keyboard character pointer table (EA9C28) ---
    # Points to individual character strings for the uppercase filename entry keyboard.
    ('LABEL_EA9C28', 'PtrTbl_KeyboardChars_Upper', 'Pointer table for uppercase keyboard character strings'),

    # --- Uppercase keyboard character entries (EA9CC4-EA9D12) ---
    # Individual character string entries for uppercase filename keyboard (A-Z, 0-9, _, SPC).
    ('LABEL_EA9CC4', 'KbChar_Upper_Empty', 'Uppercase keyboard: empty string sentinel'),
    ('LABEL_EA9CC6', 'KbChar_Upper_Space', 'Uppercase keyboard: SPC (space)'),
    ('LABEL_EA9CCA', 'KbChar_Upper_9', 'Uppercase keyboard: character 9'),
    ('LABEL_EA9CCC', 'KbChar_Upper_8', 'Uppercase keyboard: character 8'),
    ('LABEL_EA9CCE', 'KbChar_Upper_7', 'Uppercase keyboard: character 7'),
    ('LABEL_EA9CD0', 'KbChar_Upper_6', 'Uppercase keyboard: character 6'),
    ('LABEL_EA9CD2', 'KbChar_Upper_5', 'Uppercase keyboard: character 5'),
    ('LABEL_EA9CD4', 'KbChar_Upper_4', 'Uppercase keyboard: character 4'),
    ('LABEL_EA9CD6', 'KbChar_Upper_3', 'Uppercase keyboard: character 3'),
    ('LABEL_EA9CD8', 'KbChar_Upper_2', 'Uppercase keyboard: character 2'),
    ('LABEL_EA9CDA', 'KbChar_Upper_1', 'Uppercase keyboard: character 1'),
    ('LABEL_EA9CDC', 'KbChar_Upper_0', 'Uppercase keyboard: character 0'),
    ('LABEL_EA9CDE', 'KbChar_Upper_Underscore', 'Uppercase keyboard: underscore (_)'),
    ('LABEL_EA9CE0', 'KbChar_Upper_Z', 'Uppercase keyboard: Z'),
    ('LABEL_EA9CE2', 'KbChar_Upper_Y', 'Uppercase keyboard: Y'),
    ('LABEL_EA9CE4', 'KbChar_Upper_X', 'Uppercase keyboard: X'),
    ('LABEL_EA9CE6', 'KbChar_Upper_W', 'Uppercase keyboard: W'),
    ('LABEL_EA9CE8', 'KbChar_Upper_V', 'Uppercase keyboard: V'),
    ('LABEL_EA9CEA', 'KbChar_Upper_U', 'Uppercase keyboard: U'),
    ('LABEL_EA9CEC', 'KbChar_Upper_T', 'Uppercase keyboard: T'),
    ('LABEL_EA9CEE', 'KbChar_Upper_S', 'Uppercase keyboard: S'),
    ('LABEL_EA9CF0', 'KbChar_Upper_R', 'Uppercase keyboard: R'),
    ('LABEL_EA9CF2', 'KbChar_Upper_Q', 'Uppercase keyboard: Q'),
    ('LABEL_EA9CF4', 'KbChar_Upper_P', 'Uppercase keyboard: P'),
    ('LABEL_EA9CF6', 'KbChar_Upper_O', 'Uppercase keyboard: O'),
    ('LABEL_EA9CF8', 'KbChar_Upper_N', 'Uppercase keyboard: N'),
    ('LABEL_EA9CFA', 'KbChar_Upper_M', 'Uppercase keyboard: M'),
    ('LABEL_EA9CFC', 'KbChar_Upper_L', 'Uppercase keyboard: L'),
    ('LABEL_EA9CFE', 'KbChar_Upper_K', 'Uppercase keyboard: K'),
    ('LABEL_EA9D00', 'KbChar_Upper_J', 'Uppercase keyboard: J'),
    ('LABEL_EA9D02', 'KbChar_Upper_I', 'Uppercase keyboard: I'),
    ('LABEL_EA9D04', 'KbChar_Upper_H', 'Uppercase keyboard: H'),
    ('LABEL_EA9D06', 'KbChar_Upper_G', 'Uppercase keyboard: G'),
    ('LABEL_EA9D08', 'KbChar_Upper_F', 'Uppercase keyboard: F'),
    ('LABEL_EA9D0A', 'KbChar_Upper_E', 'Uppercase keyboard: E'),
    ('LABEL_EA9D0C', 'KbChar_Upper_D', 'Uppercase keyboard: D'),
    ('LABEL_EA9D0E', 'KbChar_Upper_C', 'Uppercase keyboard: C'),
    ('LABEL_EA9D10', 'KbChar_Upper_B', 'Uppercase keyboard: B'),
    ('LABEL_EA9D12', 'KbChar_Upper_A', 'Uppercase keyboard: A'),

    # --- Lowercase keyboard character pointer table (EA9D18) ---
    # Points to individual character strings for the lowercase filename entry keyboard.
    ('LABEL_EA9D18', 'PtrTbl_KeyboardChars_Lower', 'Pointer table for lowercase keyboard character strings'),

    # --- Lowercase keyboard character entries (EA9DB0-EA9DFC) ---
    ('LABEL_EA9DB0', 'KbChar_Lower_Empty', 'Lowercase keyboard: empty string sentinel'),
    ('LABEL_EA9DB2', 'KbChar_Lower_Space', 'Lowercase keyboard: SPC (space)'),
    ('LABEL_EA9DB6', 'KbChar_Lower_9', 'Lowercase keyboard: character 9'),
    ('LABEL_EA9DB8', 'KbChar_Lower_8', 'Lowercase keyboard: character 8'),
    ('LABEL_EA9DBA', 'KbChar_Lower_7', 'Lowercase keyboard: character 7'),
    ('LABEL_EA9DBC', 'KbChar_Lower_6', 'Lowercase keyboard: character 6'),
    ('LABEL_EA9DBE', 'KbChar_Lower_5', 'Lowercase keyboard: character 5'),
    ('LABEL_EA9DC0', 'KbChar_Lower_4', 'Lowercase keyboard: character 4'),
    ('LABEL_EA9DC2', 'KbChar_Lower_3', 'Lowercase keyboard: character 3'),
    ('LABEL_EA9DC4', 'KbChar_Lower_2', 'Lowercase keyboard: character 2'),
    ('LABEL_EA9DC6', 'KbChar_Lower_1', 'Lowercase keyboard: character 1'),
    ('LABEL_EA9DC8', 'KbChar_Lower_0', 'Lowercase keyboard: character 0'),
    ('LABEL_EA9DCA', 'KbChar_Lower_Underscore', 'Lowercase keyboard: underscore (_)'),
    ('LABEL_EA9DCC', 'KbChar_Lower_z', 'Lowercase keyboard: z'),
    ('LABEL_EA9DCE', 'KbChar_Lower_y', 'Lowercase keyboard: y'),
    ('LABEL_EA9DD0', 'KbChar_Lower_x', 'Lowercase keyboard: x'),
    ('LABEL_EA9DD2', 'KbChar_Lower_w', 'Lowercase keyboard: w'),
    ('LABEL_EA9DD4', 'KbChar_Lower_v', 'Lowercase keyboard: v'),
    ('LABEL_EA9DD6', 'KbChar_Lower_u', 'Lowercase keyboard: u'),
    ('LABEL_EA9DD8', 'KbChar_Lower_t', 'Lowercase keyboard: t'),
    ('LABEL_EA9DDA', 'KbChar_Lower_s', 'Lowercase keyboard: s'),
    ('LABEL_EA9DDC', 'KbChar_Lower_r', 'Lowercase keyboard: r'),
    ('LABEL_EA9DDE', 'KbChar_Lower_q', 'Lowercase keyboard: q'),
    ('LABEL_EA9DE0', 'KbChar_Lower_p', 'Lowercase keyboard: p'),
    ('LABEL_EA9DE2', 'KbChar_Lower_o', 'Lowercase keyboard: o'),
    ('LABEL_EA9DE4', 'KbChar_Lower_n', 'Lowercase keyboard: n'),
    ('LABEL_EA9DE6', 'KbChar_Lower_m', 'Lowercase keyboard: m'),
    ('LABEL_EA9DE8', 'KbChar_Lower_l', 'Lowercase keyboard: l'),
    ('LABEL_EA9DEA', 'KbChar_Lower_k', 'Lowercase keyboard: k'),
    ('LABEL_EA9DEC', 'KbChar_Lower_j', 'Lowercase keyboard: j'),
    ('LABEL_EA9DEE', 'KbChar_Lower_i', 'Lowercase keyboard: i'),
    ('LABEL_EA9DF0', 'KbChar_Lower_h', 'Lowercase keyboard: h'),
    ('LABEL_EA9DF2', 'KbChar_Lower_g', 'Lowercase keyboard: g'),
    ('LABEL_EA9DF4', 'KbChar_Lower_f', 'Lowercase keyboard: f'),
]

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')
    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    print(f'\nRenamed {renamed} labels in maincpu')

if __name__ == '__main__':
    main()
