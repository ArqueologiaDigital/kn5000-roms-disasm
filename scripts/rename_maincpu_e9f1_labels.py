#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E9F148-EA066C."""
import os, re

RENAMES = [
    # E9F148: MIDI parameters panel config descriptor table.
    # Structure: count/flags + pointer to string array + per-param descriptors
    # with fields for position, default value ptr, label address, etc.
    # Covers parameters: LOCAL, MIDI, KEY SHIFT, DIGITAL EFF, DSP EFF, REVERB, VOLUME, PAN, SOUND
    ('LABEL_E9F148', 'MidiParam_PanelCfgTable', 'MIDI params panel config table (sound editor view 1)'),

    # E9F1FC-E9F24A: string data block referenced by E9F148
    ('LABEL_E9F1FC', 'MidiParamStr1_Local',        'MIDI param name string: LOCAL (with null+0xff pad)'),
    ('LABEL_E9F204', 'MidiParamStr1_Midi',          'MIDI param name string: MIDI (with null+0xff pad)'),
    ('LABEL_E9F20C', 'MidiParamStr1_Empty',         'MIDI param name: empty entry (null pair placeholder)'),
    ('LABEL_E9F210', 'MidiParamStr1_KeyShift',      'MIDI param name strings: KEY SHIFT / DIGITAL EFF'),
    ('LABEL_E9F226', 'MidiParamStr1_DspEff',        'MIDI param name strings: DSP EFF / REVERB'),
    ('LABEL_E9F236', 'MidiParamStr1_Volume',        'MIDI param name strings: empty / VOLUME'),
    ('LABEL_E9F240', 'MidiParamStr1_Pan',           'MIDI param name strings: PAN / SOUND'),
    ('LABEL_E9F24A', 'MidiParamStr1_End',           'MIDI param string block end (empty aligned string)'),

    # E9F24C: 32-word MIDI channel mapping table (part index -> MIDI channel)
    # Entries 0-15 map directly, 16-23 use rearranged order, 0xFF = unused
    ('LABEL_E9F24C', 'Midi_PartToChMappingTable',   'MIDI channel mapping table: part index -> MIDI channel (32 words)'),

    # E9F28C-E9F37C: 6-character part name strings for full display (mixer panel etc.)
    # Order matches part layout: blank, RHYTHM, CTRL, APC, MIC, METRO, MSP, DRUMS, BASS,
    # ACOMP3, ACOMP2, ACOMP1, R.BASS, CHORD, PART16..PART4, LEFT, RIGHT2, RIGHT1, blank(4-char)
    ('LABEL_E9F28C', 'PartName6_Blank',    'Part name 6-char: blank/spaces'),
    ('LABEL_E9F294', 'PartName6_Rhythm',   'Part name 6-char: RHYTHM'),
    ('LABEL_E9F29C', 'PartName6_Ctrl',     'Part name 6-char: CTRL'),
    ('LABEL_E9F2A4', 'PartName6_Apc',      'Part name 6-char: APC'),
    ('LABEL_E9F2AC', 'PartName6_Mic',      'Part name 6-char: MIC'),
    ('LABEL_E9F2B4', 'PartName6_Metro',    'Part name 6-char: METRO'),
    ('LABEL_E9F2BC', 'PartName6_Msp',      'Part name 6-char: MSP'),
    ('LABEL_E9F2C4', 'PartName6_Drums',    'Part name 6-char: DRUMS'),
    ('LABEL_E9F2CC', 'PartName6_Bass',     'Part name 6-char: BASS'),
    ('LABEL_E9F2D4', 'PartName6_Acomp3',   'Part name 6-char: ACOMP3'),
    ('LABEL_E9F2DC', 'PartName6_Acomp2',   'Part name 6-char: ACOMP2'),
    ('LABEL_E9F2E4', 'PartName6_Acomp1',   'Part name 6-char: ACOMP1'),
    ('LABEL_E9F2EC', 'PartName6_RBass',    'Part name 6-char: R.BASS'),
    ('LABEL_E9F2F4', 'PartName6_Chord',    'Part name 6-char: CHORD'),
    ('LABEL_E9F2FC', 'PartName6_Part16',   'Part name 6-char: PART16'),
    ('LABEL_E9F304', 'PartName6_Part15',   'Part name 6-char: PART15'),
    ('LABEL_E9F30C', 'PartName6_Part14',   'Part name 6-char: PART14'),
    ('LABEL_E9F314', 'PartName6_Part13',   'Part name 6-char: PART13'),
    ('LABEL_E9F31C', 'PartName6_Part12',   'Part name 6-char: PART12'),
    ('LABEL_E9F324', 'PartName6_Part11',   'Part name 6-char: PART11'),
    ('LABEL_E9F32C', 'PartName6_Part10',   'Part name 6-char: PART10'),
    ('LABEL_E9F334', 'PartName6_Part9',    'Part name 6-char: PART 9'),
    ('LABEL_E9F33C', 'PartName6_Part8',    'Part name 6-char: PART 8'),
    ('LABEL_E9F344', 'PartName6_Part7',    'Part name 6-char: PART 7'),
    ('LABEL_E9F34C', 'PartName6_Part6',    'Part name 6-char: PART 6'),
    ('LABEL_E9F354', 'PartName6_Part5',    'Part name 6-char: PART 5'),
    ('LABEL_E9F35C', 'PartName6_Part4',    'Part name 6-char: PART 4'),
    ('LABEL_E9F364', 'PartName6_Left',     'Part name 6-char: LEFT'),
    ('LABEL_E9F36C', 'PartName6_Right2',   'Part name 6-char: RIGHT2'),
    ('LABEL_E9F374', 'PartName6_Right1',   'Part name 6-char: RIGHT1'),
    ('LABEL_E9F37C', 'PartName6_TableEnd', 'Part 6-char name table end (4-char blank)'),

    # E9F382-E9F42A: 4-character abbreviated part name strings
    # Same part ordering but using short 4-char names
    ('LABEL_E9F382', 'PartName4_Rhythm',   'Part name 4-char: RHY'),
    ('LABEL_E9F388', 'PartName4_Ctrl',     'Part name 4-char: CTRL'),
    ('LABEL_E9F38E', 'PartName4_Apc',      'Part name 4-char: APC'),
    ('LABEL_E9F394', 'PartName4_Mic',      'Part name 4-char: MIC'),
    ('LABEL_E9F39A', 'PartName4_Metro',    'Part name 4-char: METR'),
    ('LABEL_E9F3A0', 'PartName4_Msp',      'Part name 4-char: MSP'),
    ('LABEL_E9F3A6', 'PartName4_Drums',    'Part name 4-char: DRUM'),
    ('LABEL_E9F3AC', 'PartName4_Bass',     'Part name 4-char: BASS'),
    ('LABEL_E9F3B2', 'PartName4_Acomp3',   'Part name 4-char: ACP3'),
    ('LABEL_E9F3B8', 'PartName4_Acomp2',   'Part name 4-char: ACP2'),
    ('LABEL_E9F3BE', 'PartName4_Acomp1',   'Part name 4-char: ACP1'),
    ('LABEL_E9F3C4', 'PartName4_RBass',    'Part name 4-char: R.BA'),
    ('LABEL_E9F3CA', 'PartName4_Chord',    'Part name 4-char: CHRD'),
    ('LABEL_E9F3D0', 'PartName4_Part16',   'Part name 4-char: PT16'),
    ('LABEL_E9F3D6', 'PartName4_Part15',   'Part name 4-char: PT15'),
    ('LABEL_E9F3DC', 'PartName4_Part14',   'Part name 4-char: PT14'),
    ('LABEL_E9F3E2', 'PartName4_Part13',   'Part name 4-char: PT13'),
    ('LABEL_E9F3E8', 'PartName4_Part12',   'Part name 4-char: PT12'),
    ('LABEL_E9F3EE', 'PartName4_Part11',   'Part name 4-char: PT11'),
    ('LABEL_E9F3F4', 'PartName4_Part10',   'Part name 4-char: PT10'),
    ('LABEL_E9F3FA', 'PartName4_Part9',    'Part name 4-char: PT 9'),
    ('LABEL_E9F400', 'PartName4_Part8',    'Part name 4-char: PT 8'),
    ('LABEL_E9F406', 'PartName4_Part7',    'Part name 4-char: PT 7'),
    ('LABEL_E9F40C', 'PartName4_Part6',    'Part name 4-char: PT 6'),
    ('LABEL_E9F412', 'PartName4_Part5',    'Part name 4-char: PT 5'),
    ('LABEL_E9F418', 'PartName4_Part4',    'Part name 4-char: PT 4'),
    ('LABEL_E9F41E', 'PartName4_Left',     'Part name 4-char: LEFT'),
    ('LABEL_E9F424', 'PartName4_Right2',   'Part name 4-char: RT 2'),
    ('LABEL_E9F42A', 'PartName4_Right1',   'Part name 4-char: RT 1'),

    # E9F430-E9F468: alternate 6-char part names for accompaniment section
    # Reordered to put chord-section parts first (used in Composer/Arranger context)
    ('LABEL_E9F430', 'AccompName6_Chord',   'Accomp part 6-char name: CHORD'),
    ('LABEL_E9F438', 'AccompName6_RBass',   'Accomp part 6-char name: R.BASS'),
    ('LABEL_E9F440', 'AccompName6_Msp',     'Accomp part 6-char name: MSP'),
    ('LABEL_E9F448', 'AccompName6_Bass',    'Accomp part 6-char name: BASS'),
    ('LABEL_E9F450', 'AccompName6_Acomp1',  'Accomp part 6-char name: ACOMP1'),
    ('LABEL_E9F458', 'AccompName6_Acomp2',  'Accomp part 6-char name: ACOMP2'),
    ('LABEL_E9F460', 'AccompName6_Acomp3',  'Accomp part 6-char name: ACOMP3'),
    ('LABEL_E9F468', 'AccompName6_Drums',   'Accomp part 6-char name: DRUMS'),

    # E9F470-E9F4E8: 6-character composer track name strings (TR 1 .. TR16, padded)
    ('LABEL_E9F470', 'TrackName6_Tr16',    'Composer track 6-char name:  TR16'),
    ('LABEL_E9F478', 'TrackName6_Tr15',    'Composer track 6-char name:  TR15'),
    ('LABEL_E9F480', 'TrackName6_Tr14',    'Composer track 6-char name:  TR14'),
    ('LABEL_E9F488', 'TrackName6_Tr13',    'Composer track 6-char name:  TR13'),
    ('LABEL_E9F490', 'TrackName6_Tr12',    'Composer track 6-char name:  TR12'),
    ('LABEL_E9F498', 'TrackName6_Tr11',    'Composer track 6-char name:  TR11'),
    ('LABEL_E9F4A0', 'TrackName6_Tr10',    'Composer track 6-char name:  TR10'),
    ('LABEL_E9F4A8', 'TrackName6_Tr9',     'Composer track 6-char name:  TR 9'),
    ('LABEL_E9F4B0', 'TrackName6_Tr8',     'Composer track 6-char name:  TR 8'),
    ('LABEL_E9F4B8', 'TrackName6_Tr7',     'Composer track 6-char name:  TR 7'),
    ('LABEL_E9F4C0', 'TrackName6_Tr6',     'Composer track 6-char name:  TR 6'),
    ('LABEL_E9F4C8', 'TrackName6_Tr5',     'Composer track 6-char name:  TR 5'),
    ('LABEL_E9F4D0', 'TrackName6_Tr4',     'Composer track 6-char name:  TR 4'),
    ('LABEL_E9F4D8', 'TrackName6_Tr3',     'Composer track 6-char name:  TR 3'),
    ('LABEL_E9F4E0', 'TrackName6_Tr2',     'Composer track 6-char name:  TR 2'),
    ('LABEL_E9F4E8', 'TrackName6_Tr1',     'Composer track 6-char name:  TR 1'),

    # E9F4F0-E9F51A: unassigned/empty track display strings " -- "
    # Used when a track slot has no assignment
    ('LABEL_E9F4F0', 'TrackName6_Unassigned',   'Unassigned track 6-char name: " -- " (no aligned pad)'),
    ('LABEL_E9F4F6', 'TrackName6_Unassigned_02', 'Unassigned track 6-char name: " -- " (slot 2)'),
    ('LABEL_E9F4FC', 'TrackName6_Unassigned_03', 'Unassigned track 6-char name: " -- " (slot 3)'),
    ('LABEL_E9F502', 'TrackName6_Unassigned_04', 'Unassigned track 6-char name: " -- " (slot 4)'),
    ('LABEL_E9F508', 'TrackName6_Unassigned_05', 'Unassigned track 6-char name: " -- " (slot 5)'),
    ('LABEL_E9F50E', 'TrackName6_Unassigned_06', 'Unassigned track 6-char name: " -- " (slot 6)'),
    ('LABEL_E9F514', 'TrackName6_Unassigned_07', 'Unassigned track 6-char name: " -- " (slot 7)'),
    ('LABEL_E9F51A', 'TrackName6_Unassigned_08', 'Unassigned track 6-char name: " -- " (slot 8)'),

    # E9F520-E9F57A: 4-character composer track name strings (TR 1 .. TR16)
    ('LABEL_E9F520', 'TrackName4_Tr16',    'Composer track 4-char name: TR16'),
    ('LABEL_E9F526', 'TrackName4_Tr15',    'Composer track 4-char name: TR15'),
    ('LABEL_E9F52C', 'TrackName4_Tr14',    'Composer track 4-char name: TR14'),
    ('LABEL_E9F532', 'TrackName4_Tr13',    'Composer track 4-char name: TR13'),
    ('LABEL_E9F538', 'TrackName4_Tr12',    'Composer track 4-char name: TR12'),
    ('LABEL_E9F53E', 'TrackName4_Tr11',    'Composer track 4-char name: TR11'),
    ('LABEL_E9F544', 'TrackName4_Tr10',    'Composer track 4-char name: TR10'),
    ('LABEL_E9F54A', 'TrackName4_Tr9',     'Composer track 4-char name: TR 9'),
    ('LABEL_E9F550', 'TrackName4_Tr8',     'Composer track 4-char name: TR 8'),
    ('LABEL_E9F556', 'TrackName4_Tr7',     'Composer track 4-char name: TR 7'),
    ('LABEL_E9F55C', 'TrackName4_Tr6',     'Composer track 4-char name: TR 6'),
    ('LABEL_E9F562', 'TrackName4_Tr5',     'Composer track 4-char name: TR 5'),
    ('LABEL_E9F568', 'TrackName4_Tr4',     'Composer track 4-char name: TR 4'),
    ('LABEL_E9F56E', 'TrackName4_Tr3',     'Composer track 4-char name: TR 3'),
    ('LABEL_E9F574', 'TrackName4_Tr2',     'Composer track 4-char name: TR 2'),
    ('LABEL_E9F57A', 'TrackName4_Tr1',     'Composer track 4-char name: TR 1'),

    # E9F670-E9F6B8: string data block for MIDI panel config view 2 (second instance)
    # Identical structure to E9F1FC-E9F24A but at a different address
    ('LABEL_E9F670', 'MidiParamStr2_End',        'MIDI param string block 2 end (empty aligned string)'),
    ('LABEL_E9F672', 'MidiParamStr2_Local',       'MIDI param name string 2: LOCAL'),
    ('LABEL_E9F67E', 'MidiParamStr2_Empty',       'MIDI param name 2: empty entry (null pair placeholder)'),
    ('LABEL_E9F682', 'MidiParamStr2_KeyShift',    'MIDI param name strings 2: empty / KEY SHIFT'),
    ('LABEL_E9F68E', 'MidiParamStr2_DspEff',      'MIDI param name strings 2: DIGITAL EFF / DSP EFF'),
    ('LABEL_E9F6A2', 'MidiParamStr2_Reverb',      'MIDI param name strings 2: REVERB / (empty)'),
    ('LABEL_E9F6AC', 'MidiParamStr2_Volume',      'MIDI param name strings 2: VOLUME / PAN'),
    ('LABEL_E9F6B8', 'MidiParamStr2_Sound',       'MIDI param name string 2: SOUND'),

    # E9F7B4-E9F802: string data block for MIDI panel config view 3 (third instance)
    # Same LOCAL/MIDI/KEY SHIFT/etc structure, third occurrence
    ('LABEL_E9F7B4', 'MidiParamStr3_Local',      'MIDI param name string 3: LOCAL (with null+0xff pad)'),
    ('LABEL_E9F7BC', 'MidiParamStr3_Midi',        'MIDI param name string 3: MIDI (with null+0xff pad)'),
    ('LABEL_E9F7C4', 'MidiParamStr3_Empty',       'MIDI param name 3: empty entry (null pair placeholder)'),
    ('LABEL_E9F7C8', 'MidiParamStr3_KeyShift',    'MIDI param name strings 3: KEY SHIFT / DIGITAL EFF'),
    ('LABEL_E9F7DE', 'MidiParamStr3_DspEff',      'MIDI param name strings 3: DSP EFF / REVERB'),
    ('LABEL_E9F7EE', 'MidiParamStr3_Volume',      'MIDI param name strings 3: empty / VOLUME'),
    ('LABEL_E9F7F8', 'MidiParamStr3_Pan',         'MIDI param name strings 3: PAN / SOUND'),
    ('LABEL_E9F802', 'MidiParam_MixerCfgData',    'Mixer channel config data (part reorder table + volume/note tables)'),

    # E9F8AA: key transposition display string pointer table (16 entries)
    # Points to strings for semitone shift values from -8 to +7 and 0
    ('LABEL_E9F8AA', 'KeyShift_DisplayStrTable',  'Key transposition display string pointer table (16 entries)'),
    ('LABEL_E9F8EA', 'KeyShiftStr_Minus1',         'Key shift display string: -1'),
    ('LABEL_E9F8EE', 'KeyShiftStr_Minus2',         'Key shift display string: -2'),
    ('LABEL_E9F8F2', 'KeyShiftStr_Minus3',         'Key shift display string: -3'),
    ('LABEL_E9F8F6', 'KeyShiftStr_Minus4',         'Key shift display string: -4'),
    ('LABEL_E9F8FA', 'KeyShiftStr_Minus5',         'Key shift display string: -5'),
    ('LABEL_E9F8FE', 'KeyShiftStr_Minus6',         'Key shift display string: -6'),
    ('LABEL_E9F902', 'KeyShiftStr_Minus7',         'Key shift display string: -7'),
    ('LABEL_E9F906', 'KeyShiftStr_Minus8',         'Key shift display string: -8'),
    ('LABEL_E9F90A', 'KeyShiftStr_Plus7',          'Key shift display string: +7'),
    ('LABEL_E9F90E', 'KeyShiftStr_Plus6',          'Key shift display string: +6'),
    ('LABEL_E9F912', 'KeyShiftStr_Plus5',          'Key shift display string: +5'),
    ('LABEL_E9F916', 'KeyShiftStr_Plus4',          'Key shift display string: +4'),
    ('LABEL_E9F91A', 'KeyShiftStr_Plus3',          'Key shift display string: +3'),
    ('LABEL_E9F91E', 'KeyShiftStr_Plus2',          'Key shift display string: +2'),
    ('LABEL_E9F922', 'KeyShiftStr_Plus1',          'Key shift display string: +1'),
    ('LABEL_E9F926', 'KeyShiftStr_Zero',           'Key shift display string:  0 (no transposition)'),

    # E9F9C8: 6-entry pointer table for demo disk prompt strings by language
    # Languages: Indonesian, Italian, English(x2), German, English(default)
    ('LABEL_E9F9C8', 'DemoDisk_LangPromptTable',  'External demo disk prompt language selection table (6 entries)'),
    ('LABEL_E9F9E0', 'DemoDiskPrompt_Indonesian',  'External demo disk prompt: Indonesian language'),
    ('LABEL_E9FA82', 'DemoDiskPrompt_Italian',     'Language label: Italian'),
    ('LABEL_E9FA8A', 'DemoDiskPrompt_English2',    'External demo disk prompt: English (variant 2)'),
    ('LABEL_E9FB10', 'DemoDiskPrompt_English3',    'External demo disk prompt: English (variant 3)'),
    ('LABEL_E9FB96', 'DemoDiskPrompt_German',      'External demo disk prompt: German language'),
    ('LABEL_E9FC3E', 'DemoDiskPrompt_English1',    'External demo disk prompt: English (default)'),

    # E9FDDC: error message for GetInstanceID failure
    ('LABEL_E9FDDC', 'ErrStr_GetInstanceID',       'Error string: "Error! (GetInstanceID)"'),

    # E9FDF4: 4-entry pointer table for file/data source type name strings
    ('LABEL_E9FDF4', 'FileType_NameTable',         'File/data source type name pointer table (4 entries)'),
    ('LABEL_E9FE04', 'FileTypeName_Empty',          'File type name: empty string'),
    ('LABEL_E9FE06', 'FileTypeName_Name',           'File type name: NAME'),
    ('LABEL_E9FE0C', 'FileTypeName_Src',            'File type name: SRC'),
    ('LABEL_E9FE10', 'FileTypeName_Song',           'File type name: SONG'),

    # E9FE76-E9FE7C: small raw string data (PAN, NO)
    ('LABEL_E9FE76', 'UIStr_Pan',                  'UI string: PAN (raw, no align)'),
    ('LABEL_E9FE7C', 'UIStr_No',                   'UI string: NO (raw, no align)'),

    # E9FE8C-E9FE94: image/display attribute strings (empty, COLOR, SIZE)
    ('LABEL_E9FE8C', 'ImgAttr_Empty',              'Image attribute string: empty'),
    ('LABEL_E9FE8E', 'ImgAttr_Color',              'Image attribute string: COLOR'),
    ('LABEL_E9FE94', 'ImgAttr_Size',               'Image attribute string: SIZE (followed by font size table)'),

    # E9FEC2: 10-entry pointer table for HTML-like image element attribute name strings
    ('LABEL_E9FEC2', 'ImgAttr_NameTable',          'Image element attribute name pointer table (10 entries)'),
    ('LABEL_E9FEEA', 'ImgAttrName_Empty',           'Image attribute name: empty string'),
    ('LABEL_E9FEEC', 'ImgAttrName_Border',          'Image attribute name: BORDER'),
    ('LABEL_E9FEF4', 'ImgAttrName_Lowsrc',         'Image attribute name: LOWSRC'),
    ('LABEL_E9FEFC', 'ImgAttrName_Height',          'Image attribute name: HEIGHT'),
    ('LABEL_E9FF04', 'ImgAttrName_Width',           'Image attribute name: WIDTH'),
    ('LABEL_E9FF0A', 'ImgAttrName_Hspace',          'Image attribute name: HSPACE'),
    ('LABEL_E9FF12', 'ImgAttrName_Vspace',          'Image attribute name: VSPACE'),
    ('LABEL_E9FF1A', 'ImgAttrName_Align',           'Image attribute name: ALIGN'),
    ('LABEL_E9FF20', 'ImgAttrName_Alt',             'Image attribute name: ALT'),
    ('LABEL_E9FF24', 'ImgAttrName_Src',             'Image attribute name: SRC'),

    # E9FFB4-E9FFB6: object element data area (empty OBJ record + padding)
    ('LABEL_E9FFB4', 'ObjAttr_Empty',              'Object element attribute: empty/null entry'),
    ('LABEL_E9FFB6', 'ObjAttr_Obj',                'Object element attribute: OBJ identifier string'),

    # EA0000: presentation system root entry (pointer to EF013F + padding)
    ('LABEL_EA0000', 'Presentation_RootEntry',     'Presentation system root entry (ptr to main handler + padding)'),

    # EA0008: presentation/action XML-like tag strings and file extension table
    ('LABEL_EA0008', 'Presentation_TagStrTable',   'Presentation/Action XML tag and file extension string table'),

    # EA013F: boundary/entry after presentation tag table
    ('LABEL_EA013F', 'Presentation_TagTableEnd',   'End of presentation tag string table (boundary)'),

    # EA01F8, EA01FC, EA0200: resource ID region boundary markers
    ('LABEL_EA01F8', 'Resource_Region7_Start',     'Resource ID region 7 start marker'),
    ('LABEL_EA01FC', 'Resource_Region2_Start',     'Resource ID region 2 start marker'),
    ('LABEL_EA0200', 'Resource_Region3_Start',     'Resource ID region 3 start marker'),

    # EA024C: padding/end of resource ID region data
    ('LABEL_EA024C', 'Resource_RegionPad',         'Resource region padding area (rb terminator entries)'),

    # EA0340: 10-entry pointer table for 3-char sequencer file type code strings
    ('LABEL_EA0340', 'SeqFileType_CodeTable',      'Sequencer file type 3-char code pointer table (10 entries)'),
    ('LABEL_EA0368', 'SeqFileTypeCode_Seq',         'Sequencer file type code: SEQ (standard sequencer)'),
    ('LABEL_EA036C', 'SeqFileTypeCode_Sqf',         'Sequencer file type code: SQF'),
    ('LABEL_EA0370', 'SeqFileTypeCode_Md',          'Sequencer file type code: MD (MIDI data)'),
    ('LABEL_EA0374', 'SeqFileTypeCode_Rcm',         'Sequencer file type code: RCM'),
    ('LABEL_EA0378', 'SeqFileTypeCode_Msp',         'Sequencer file type code: MSP'),
    ('LABEL_EA037C', 'SeqFileTypeCode_Tm',          'Sequencer file type code: TM (tone map)'),
    ('LABEL_EA0380', 'SeqFileTypeCode_Cmp',         'Sequencer file type code: CMP (composer)'),
    ('LABEL_EA0384', 'SeqFileTypeCode_Sqt',         'Sequencer file type code: SQT'),
    ('LABEL_EA0388', 'SeqFileTypeCode_Pmt',         'Sequencer file type code: PMT (panel memory tone)'),
    ('LABEL_EA038C', 'SeqFileTypeCode_Lsw',         'Sequencer file type code: LSW'),

    # EA0448: filename template area (blank filenames like ______.MID)
    ('LABEL_EA0448', 'Filename_TemplateArea',       'Filename template area (blank/wildcard filename templates)'),

    # EA04C2: code stub with jrl/swi pattern + directory filename strings
    ('LABEL_EA04C2', 'FileOp_StubAndDirNames',     'File operation stub code + MUSIC.DIR / PIANODIR.FIL strings'),

    # EA0558: 8-entry pointer table for 3-char disk/media type strings
    ('LABEL_EA0558', 'DiskType_CodeTable',         'Disk/media type 3-char code pointer table (8 entries)'),
    ('LABEL_EA0578', 'DiskTypeCode_Doc1',           'Disk type code: DOC (slot 1)'),
    ('LABEL_EA057C', 'DiskTypeCode_Doc2',           'Disk type code: DOC (slot 2)'),
    ('LABEL_EA0580', 'DiskTypeCode_Pd',             'Disk type code: PD (PD media)'),
    ('LABEL_EA0584', 'DiskTypeCode_2DD1',           'Disk type code: 2DD (double-density slot 1)'),
    ('LABEL_EA0588', 'DiskTypeCode_2HD',            'Disk type code: 2HD (high-density)'),
    ('LABEL_EA058C', 'DiskTypeCode_2DD2',           'Disk type code: 2DD (double-density slot 2)'),
    ('LABEL_EA0590', 'DiskTypeCode_Dashes1',        'Disk type code: --- (unknown/empty slot 1)'),
    ('LABEL_EA0594', 'DiskTypeCode_Dashes2',        'Disk type code: --- (unknown/empty slot 2)'),

    # EA0598: 5-entry pointer table for storage area name strings
    ('LABEL_EA0598', 'StorageArea_NameTable',       'Storage area name pointer table (5 entries)'),
    ('LABEL_EA05AC', 'StorageAreaName_Blank',        'Storage area name: blank (spaces)'),
    ('LABEL_EA05BA', 'StorageAreaName_SoundMemory',  'Storage area name: SOUND MEMORY'),
    ('LABEL_EA05C8', 'StorageAreaName_Composer',     'Storage area name: COMPOSER'),
    ('LABEL_EA05D6', 'StorageAreaName_Sequencer',    'Storage area name: SEQUENCER'),
    ('LABEL_EA05E4', 'StorageAreaName_PanelMemory',  'Storage area name: PANEL MEMORY'),

    # EA0606-EA061E: bank display label strings (----, BANK)
    ('LABEL_EA0606', 'BankStr_Dashes',              'Bank label string: ---- (no bank)'),
    ('LABEL_EA060C', 'BankStr_Bank1',               'Bank label string: BANK (with null prefix, variant 1)'),
    ('LABEL_EA0612', 'BankStr_Bank2',               'Bank label string: BANK (with null prefix, variant 2)'),
    ('LABEL_EA0618', 'BankStr_Dashes2',             'Bank label string: ---- (with null prefix, variant 2)'),
    ('LABEL_EA061E', 'BankStr_Bank3',               'Bank label string: BANK (with null prefix, variant 3) + ptr'),

    # EA0628: 4-entry pointer table for disk/memory item type strings
    ('LABEL_EA0628', 'DiskItem_TypeTable',          'Disk/memory item type pointer table (4 entries)'),
    ('LABEL_EA0638', 'DiskItemType_Dashes',          'Disk item type string: ----- (empty/none)'),
    ('LABEL_EA0642', 'DiskItemType_Memory',          'Disk item type string: MEMORY'),
    ('LABEL_EA064C', 'DiskItemType_Pattern',         'Disk item type string: PATTERN'),
    ('LABEL_EA0656', 'DiskItemType_Song',            'Disk item type string: SONG'),

    # EA0660: MEMORY label string (with null prefix)
    ('LABEL_EA0660', 'BankStr_Memory',              'Bank/disk label string: MEMORY (with null prefix)'),

    # EA066C: end of this region, start of next data block
    ('LABEL_EA066C', 'DiskOp_ChannelCfgTable',     'Disk operation channel config table (start of next data block)'),
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
