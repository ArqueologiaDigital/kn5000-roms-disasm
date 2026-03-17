#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E862C2-E9AD48."""
import os, re

RENAMES = [
    # ---- Drawbar UI string names (E862C2-E862EA) ----
    # These are named UI widget strings for the Drawbar organ emulator screen.
    # The nearby table at LABEL_E86186 references E862C2 as one of the Drawbar
    # string entries. "Black23"/"White23"/"DrawPerc223"/"DrawPerc4" are drawbar
    # key/percussion labels.
    ('LABEL_E862C2', 'Str_Drawbar_Black23',       'Drawbar UI string: "Black23"'),
    ('LABEL_E862CA', 'Str_Drawbar_White23',        'Drawbar UI string: "White23"'),
    ('LABEL_E862D2', 'Str_Drawbar_DrawPerc223',    'Drawbar UI string: "DrawPerc223"'),
    ('LABEL_E862DE', 'Str_Drawbar_DrawPerc4',      'Drawbar UI string: "DrawPerc4"'),
    ('LABEL_E862E8', 'Str_Drawbar_Empty',          'Drawbar UI string: "" (empty)'),
    ('LABEL_E862EA', 'Str_Drawbar_Drawbar',        'Drawbar UI string: "Drawbar"'),

    # ---- Null/padding string entries in Drawbar string table (E8638A-E863A4) ----
    # These are 0x00,0xFF null-string entries interleaved in the Drawbar widget
    # string pointer table. Each is a 2-byte sentinel/null slot.
    ('LABEL_E8638A', 'DrawbarStrNull_E8638A',      'Null string entry in drawbar table'),
    ('LABEL_E8638C', 'DrawbarStrNull_E8638C',      'Null string entry in drawbar table'),
    ('LABEL_E8638E', 'DrawbarStrNull_E8638E',      'Null string entry in drawbar table'),
    ('LABEL_E86392', 'DrawbarStrNull_E86392',      'Null string entry in drawbar table'),
    ('LABEL_E86394', 'DrawbarStrNull_E86394',      'Null string entry in drawbar table'),
    ('LABEL_E86396', 'DrawbarStrNull_E86396',      'Null string entry in drawbar table'),
    ('LABEL_E8639A', 'DrawbarStrNull_E8639A',      'Null string entry in drawbar table'),
    ('LABEL_E8639C', 'DrawbarStrNull_E8639C',      'Null string entry in drawbar table'),
    ('LABEL_E8639E', 'DrawbarStrNull_E8639E',      'Null string entry in drawbar table'),
    ('LABEL_E863A2', 'DrawbarStrNull_E863A2',      'Null string entry in drawbar table'),
    ('LABEL_E863A4', 'DrawbarStrNull_E863A4',      'Null string entry in drawbar table'),

    # ---- Accordion UI strings (E863A6-E863F4) ----
    # Named UI widget strings for the Accordion screen.
    ('LABEL_E863A6', 'Str_Accordion_Accordion2',   'Accordion UI string: "Accordion2"'),
    ('LABEL_E863B4', 'AccordionStrNull_E863B4',    'Null string entry in accordion table'),
    ('LABEL_E863B6', 'AccordionStrNull_E863B6',    'Null string entry in accordion table'),
    ('LABEL_E863BA', 'AccordionStrNull_E863BA',    'Null string entry in accordion table'),
    ('LABEL_E863BC', 'AccordionStrNull_E863BC',    'Null string entry in accordion table'),
    ('LABEL_E863BE', 'AccordionStrNull_E863BE',    'Null string entry in accordion table'),
    ('LABEL_E863C2', 'AccordionStrNull_E863C2',    'Null string entry in accordion table'),
    ('LABEL_E863C4', 'AccordionStrNull_E863C4',    'Null string entry in accordion table'),
    ('LABEL_E863C6', 'AccordionStrNull_E863C6',    'Null string entry in accordion table'),
    ('LABEL_E863CA', 'AccordionStrNull_E863CA',    'Null string entry in accordion table'),
    ('LABEL_E863CC', 'Str_Accordion_Accordion1',   'Accordion UI string: "Accordion1"'),
    ('LABEL_E863D8', 'Str_Accordion_Empty',        'Accordion UI string: "" (empty)'),
    ('LABEL_E863DA', 'Str_Accordion_AccordionPart','Accordion UI string: "AccordionPart"'),
    ('LABEL_E863EA', 'AccordionStrNull_E863EA',    'Null string entry in accordion table'),
    ('LABEL_E863EC', 'AccordionStrNull_E863EC',    'Null string entry in accordion table'),
    ('LABEL_E863EE', 'AccordionStrNull_E863EE',    'Null string entry in accordion table'),
    ('LABEL_E863F2', 'AccordionStrNull_E863F2',    'Null string entry in accordion table'),
    ('LABEL_E863F4', 'Str_Accordion_Accordion',    'Accordion UI string: "Accordion"'),

    # ---- MPVersion / AllInitial / Welcom string table (E864D0-E8652C) ----
    # Pointer table for software version / welcome screen widget strings.
    ('LABEL_E864D0', 'StrTable_WelcomVersion',     'Pointer table: welcome/version screen strings'),
    ('LABEL_E86500', 'Str_Version_Empty1',         'Version screen string: "" (empty)'),
    ('LABEL_E86502', 'Str_Version_MPver',          'Version screen string: "MPver"'),
    ('LABEL_E86508', 'Str_Version_Empty2',         'Version screen string: "" (empty)'),
    ('LABEL_E8650A', 'Str_Version_Empty3',         'Version screen string: "" (empty)'),
    ('LABEL_E8650C', 'Str_Version_MPVersion',      'Version screen string: "MPVersion"'),
    ('LABEL_E86516', 'Str_Version_Empty4',         'Version screen string: "" (empty)'),
    ('LABEL_E86518', 'Str_Version_Empty5',         'Version screen string: "" (empty)'),
    ('LABEL_E8651A', 'Str_Version_AllInitial',     'Version screen string: "AllInitial"'),
    ('LABEL_E86526', 'Str_Version_Empty6',         'Version screen string: "" (empty)'),
    ('LABEL_E86528', 'Str_Version_Empty7',         'Version screen string: "" (empty)'),
    ('LABEL_E8652A', 'Str_Version_Empty8',         'Version screen string: "" (empty)'),
    ('LABEL_E8652C', 'Str_Version_Welcom',         'Version screen string: "Welcom"'),

    # ---- Software/ROM version string table (E86538-E86582) ----
    # Pointer table for software version component strings (MainProgram, MainTable, etc.)
    ('LABEL_E86538', 'StrTable_SoftwareVersionComps', 'Pointer table: software component version strings'),
    ('LABEL_E86550', 'Str_SoftVer_Empty1',         'Software version string: "" (empty)'),
    ('LABEL_E86552', 'Str_SoftVer_Empty2',         'Software version string: "" (empty)'),
    ('LABEL_E86554', 'Str_SoftVer_SoundTable',     'Software version string: "SoundTable"'),
    ('LABEL_E86560', 'Str_SoftVer_SubProgram',     'Software version string: "SubProgram"'),
    ('LABEL_E8656C', 'Str_SoftVer_MainTable',      'Software version string: "MainTable"'),
    ('LABEL_E86576', 'Str_SoftVer_MainProgram',    'Software version string: "MainProgram"'),
    ('LABEL_E86582', 'Str_SoftVer_Softver',        'Software version string: "Softver"'),

    # ---- MainMemDrawControl / MainPreControl strings (E86650-E86666) ----
    # Named strings for drawing-control/pre-control UI widget identifiers.
    ('LABEL_E86650', 'Str_DrawCtrl_Empty',         'Draw control string: "" (empty)'),
    ('LABEL_E86652', 'Str_DrawCtrl_MainMemDrawCtrl','Draw control string: "MainMemDrawControl"'),
    ('LABEL_E86666', 'Str_DrawCtrl_MainPreControl', 'Draw control string: "MainPreControl"'),

    # ---- Bitmap boundary labels (E8C66A, E8D97E, E8EC92) ----
    # These mark the start/end boundaries of .incbin bitmap data blobs for the
    # DrawbarNumberedSlider bitmaps. The labels appear just before each .incbin
    # directive, serving as the section-end symbol of the preceding bitmap and
    # section-start of the next.
    ('LABEL_E8C66A', 'BitmapBound_DrawbarSlider1_Start', 'Boundary: start of BitmapDrawbarNumberedSlider_1'),
    ('LABEL_E8D97E', 'BitmapBound_DrawbarSlider2_Start', 'Boundary: start of BitmapDrawbarNumberedSlider_2'),
    ('LABEL_E8EC92', 'BitmapBound_DrawbarSlider3_Start', 'Boundary: start of BitmapDrawbarNumberedSlider_3'),

    # ---- Mixer part-name strings: ON/OFF table + part labels (E9529E-E95540) ----
    # These are the channel/part name strings displayed in the Sound Mixer
    # (Sqmixer / SdPT) screen. The 0xFF-terminated pairs serve as ON/OFF/ERR
    # text and the part-name strings for each MIDI part slot.
    ('LABEL_E9529E', 'Str_Mixer_ON',              'Mixer part label string: "ON "'),
    ('LABEL_E952A2', 'MixerPartTable_Start',       'Start of mixer part/channel data table'),
    ('LABEL_E9540A', 'Str_PartName_Empty',         'Part name: "         " (empty/blank)'),
    ('LABEL_E95414', 'Str_PartName_Rhythm',        'Part name: "  RHYTHM  "'),
    ('LABEL_E95420', 'Str_PartName_Control',       'Part name: " CONTROL "'),
    ('LABEL_E9542A', 'Str_PartName_APC',           'Part name: "   APC   "'),
    ('LABEL_E95434', 'Str_PartName_MIC',           'Part name: "   MIC   "'),
    ('LABEL_E9543E', 'Str_PartName_Metronome',     'Part name: "METRONOME"'),
    ('LABEL_E95448', 'Str_PartName_MSP',           'Part name: "   MSP   "'),
    ('LABEL_E95452', 'Str_PartName_Drums',         'Part name: "  DRUMS  "'),
    ('LABEL_E9545C', 'Str_PartName_Bass',          'Part name: "   BASS   "'),
    ('LABEL_E95468', 'Str_PartName_Accomp3',       'Part name: " ACCOMP3 "'),
    ('LABEL_E95472', 'Str_PartName_Accomp2',       'Part name: " ACCOMP2 "'),
    ('LABEL_E9547C', 'Str_PartName_Accomp1',       'Part name: " ACCOMP1 "'),
    ('LABEL_E95486', 'Str_PartName_RBass',         'Part name: "  R.BASS  "'),
    ('LABEL_E95492', 'Str_PartName_Chord',         'Part name: "  CHORD  "'),
    ('LABEL_E9549C', 'Str_PartName_Part16',        'Part name: " PART 16 "'),
    ('LABEL_E954A6', 'Str_PartName_Part15',        'Part name: " PART 15 " (split across ldb)'),
    ('LABEL_E954B0', 'Str_PartName_Part14',        'Part name: " PART 14 "'),
    ('LABEL_E954BA', 'Str_PartName_Part13',        'Part name: " PART 13 "'),
    ('LABEL_E954C4', 'Str_PartName_Part12',        'Part name: " PART 12 "'),
    ('LABEL_E954CE', 'Str_PartName_Part11',        'Part name: " PART 11 "'),
    ('LABEL_E954D8', 'Str_PartName_Part10',        'Part name: " PART 10 "'),
    ('LABEL_E954E2', 'Str_PartName_Part9',         'Part name: "  PART 9  "'),
    ('LABEL_E954EE', 'Str_PartName_Part8',         'Part name: "  PART 8  "'),
    ('LABEL_E954FA', 'Str_PartName_Part7',         'Part name: "  PART 7  "'),
    ('LABEL_E95506', 'Str_PartName_Part6',         'Part name: "  PART 6  "'),
    ('LABEL_E95512', 'Str_PartName_Part5',         'Part name: "  PART 5  "'),
    ('LABEL_E9551E', 'Str_PartName_Part4',         'Part name: "  PART 4  "'),
    ('LABEL_E9552A', 'Str_PartName_Left',          'Part name: "   LEFT   "'),
    ('LABEL_E95536', 'Str_PartName_Right2',        'Part name: " RIGHT 2 "'),
    ('LABEL_E95540', 'Str_PartName_Right1',        'Part name: " RIGHT 1 "'),

    # ---- Language header string pointer table (E9566E, E95686-E956D4) ----
    # Pointer table for localized "Header" strings (language-specific UI header text),
    # indexed by language ID (0=Indonesian,1=Italian,2=Spanish,3=French,4=German,5=English).
    ('LABEL_E9566E', 'StrTable_LangHeaders',        'Pointer table: language-specific header strings'),
    ('LABEL_E95686', 'Str_Header_Indonesian',       'Language header: Indonesian'),
    ('LABEL_E95698', 'Str_Header_Italian',          'Language header: Italian'),
    ('LABEL_E956A8', 'Str_Header_Spanish',          'Language header: Spanish'),
    ('LABEL_E956B8', 'Str_Header_French',           'Language header: French'),
    ('LABEL_E956C6', 'Str_Header_German',           'Language header: German'),
    ('LABEL_E956D4', 'Str_Header_English',          'Language header: English'),

    # ---- Language text string pointer table (E956E4, E956FC-E95740) ----
    # Pointer table for localized "Text" strings (language-specific UI body text),
    # same language ordering as the header table above.
    ('LABEL_E956E4', 'StrTable_LangTexts',          'Pointer table: language-specific text strings'),
    ('LABEL_E956FC', 'Str_Text_Indonesian',         'Language text: Indonesian'),
    ('LABEL_E9570C', 'Str_Text_Italian',            'Language text: Italian'),
    ('LABEL_E9571A', 'Str_Text_Spanish',            'Language text: Spanish'),
    ('LABEL_E95728', 'Str_Text_French',             'Language text: French'),
    ('LABEL_E95734', 'Str_Text_German',             'Language text: German'),
    ('LABEL_E95740', 'Str_Text_English',            'Language text: English'),

    # ---- ERROR string pointer table (E9574E, E95766-E95786) ----
    # Pointer table for localized "ERROR" label strings (all say "ERROR"/"ERREUR").
    # E95766/E9576C are Indonesian/Italian (raw .byte for "ERROR\0"), others are
    # aligned_string entries in Spanish, French, German, English order.
    ('LABEL_E9574E', 'StrTable_ErrorLabel',         'Pointer table: localized "ERROR" label'),
    ('LABEL_E95766', 'Str_ErrorLabel_Indonesian',   'Error label: Indonesian "ERROR"'),
    ('LABEL_E9576C', 'Str_ErrorLabel_Italian',      'Error label: Italian "ERROR"'),
    ('LABEL_E95772', 'Str_ErrorLabel_Spanish',      'Error label: Spanish "ERROR"'),
    ('LABEL_E95778', 'Str_ErrorLabel_French',       'Error label: French "ERREUR"'),
    ('LABEL_E95780', 'Str_ErrorLabel_German',       'Error label: German "ERROR"'),
    ('LABEL_E95786', 'Str_ErrorLabel_English',      'Error label: English "ERROR"'),

    # ---- REMINDER string pointer table (E95790, E957A4-E957D2) ----
    # Pointer table for localized "REMINDER!" header strings.
    ('LABEL_E95790', 'StrTable_ReminderLabel',      'Pointer table: localized "REMINDER" label'),
    ('LABEL_E957A4', 'Str_Reminder_Indonesian',     'Reminder label: Indonesian "REMINDER !"'),
    ('LABEL_E957B0', 'Str_Reminder_Italian',        'Reminder label: Italian "REMINDER! "'),
    ('LABEL_E957BC', 'Str_Reminder_Spanish',        'Reminder label: Spanish reminder'),
    ('LABEL_E957C8', 'Str_Reminder_French',         'Reminder label: French "RAPPEL! "'),
    ('LABEL_E957D2', 'Str_Reminder_German',         'Reminder label: German "HINWEIS ! "'),

    # ---- COMPLETED string pointer table (E957EA, E95802-E95810) ----
    # Pointer table for localized "COMPLETED!" strings.
    ('LABEL_E957EA', 'StrTable_CompletedLabel',     'Pointer table: localized "COMPLETED" label'),
    ('LABEL_E95802', 'Str_Completed_Indonesian',    'Completed label: Indonesian "LENGKAPILAH!"'),
    ('LABEL_E95810', 'Str_Completed_Italian',       'Completed label: Italian/English "COMPLETED!"'),

    # ---- PLEASE WAIT string pointer table (E95852, E9586A-E9587C) ----
    # Pointer table for localized "PLEASE WAIT!" strings.
    ('LABEL_E95852', 'StrTable_PleaseWaitLabel',    'Pointer table: localized "PLEASE WAIT" label'),
    ('LABEL_E9586A', 'Str_PleaseWait_Indonesian',   'Please wait: Indonesian "SILAHKAN TUNGGU!"'),
    ('LABEL_E9587C', 'Str_PleaseWait_Italian',      'Please wait: Italian/English "PLEASE WAIT!"'),

    # ---- Power-off memory reminder text (E958E6-E95960) ----
    # Multilingual body text for the "internal memory retained 80 minutes" reminder.
    ('LABEL_E958E6', 'Str_MemReminder_Indonesian',  'Memory retention reminder: Indonesian text'),
    ('LABEL_E95960', 'Str_MemReminder_Italian',     'Memory retention reminder: Italian "REMINDER"'),

    # ---- Settings-not-saved reminder pointer table (E95B88, E95BA0-E95E52) ----
    # Pointer table for multilingual "settings canceled because OK not pressed" reminder.
    ('LABEL_E95B88', 'StrTable_SettingsNotSaved',   'Pointer table: settings not saved reminder'),
    ('LABEL_E95BA0', 'Str_SettingsNotSaved_ID',     'Settings not saved: Indonesian text'),
    ('LABEL_E95C32', 'Str_SettingsNotSaved_IT',     'Settings not saved: Italian "REMINDER"'),
    ('LABEL_E95C3C', 'Str_SettingsNotSaved_ES',     'Settings not saved: Spanish text'),
    ('LABEL_E95D0E', 'Str_SettingsNotSaved_FR',     'Settings not saved: French text'),
    ('LABEL_E95DAC', 'Str_SettingsNotSaved_DE',     'Settings not saved: German text'),
    ('LABEL_E95E52', 'Str_SettingsNotSaved_EN',     'Settings not saved: English text'),

    # ---- Generic ERROR! pointer table (E95EFA, E95F12-E95F3A) ----
    # Pointer table for localized generic "ERROR!" dialog strings.
    ('LABEL_E95EFA', 'StrTable_GenericError',       'Pointer table: generic localized "ERROR!" dialog'),
    ('LABEL_E95F12', 'Str_GenericErr_Indonesian',   'Generic error: Indonesian "ERROR!"'),
    ('LABEL_E95F1A', 'Str_GenericErr_Italian',      'Generic error: Italian "ERROR!"'),
    ('LABEL_E95F22', 'Str_GenericErr_Spanish',      'Generic error: Spanish "ERROR!"'),
    ('LABEL_E95F2A', 'Str_GenericErr_French',       'Generic error: French "ERREUR!"'),
    ('LABEL_E95F32', 'Str_GenericErr_German',       'Generic error: German "ERROR!"'),
    ('LABEL_E95F3A', 'Str_GenericErr_English',      'Generic error: English "ERROR!"'),

    # ---- Disk error 00: wrong product data (E95F5A-E95FA8) ----
    # Multilingual error text for disk error 00 (disk data for different product).
    ('LABEL_E95F5A', 'Str_DiskErr00_Indonesian',    'Disk err 00: Indonesian - wrong product disk'),
    ('LABEL_E95FA8', 'Str_DiskErr00_Italian',       'Disk err 00: Italian "ERROR 00"'),

    # ---- Disk error 01 pointer table (E960D8, E960F0-E96232) ----
    # Pointer table + multilingual text for disk error 01 (disk load error).
    ('LABEL_E960D8', 'StrTable_DiskErr01',          'Pointer table: disk error 01 (load error)'),
    ('LABEL_E960F0', 'Str_DiskErr01_Indonesian',    'Disk err 01: Indonesian - disk load error'),
    ('LABEL_E9613C', 'Str_DiskErr01_Italian',       'Disk err 01: Italian "ERROR 01"'),
    ('LABEL_E96146', 'Str_DiskErr01_Spanish',       'Disk err 01: Spanish text'),
    ('LABEL_E9618E', 'Str_DiskErr01_French',        'Disk err 01: French text'),
    ('LABEL_E961DC', 'Str_DiskErr01_German',        'Disk err 01: German text'),
    ('LABEL_E96232', 'Str_DiskErr01_English',       'Disk err 01: English text'),

    # ---- Disk error 03 pointer table (E96348, E9635C-E9641E) ----
    # Pointer table + multilingual text for disk error 03 (file is empty).
    ('LABEL_E96348', 'StrTable_DiskErr03',          'Pointer table: disk error 03 (file empty)'),
    ('LABEL_E9635C', 'Str_DiskErr03_Indonesian',    'Disk err 03: Indonesian - empty file'),
    ('LABEL_E963B2', 'Str_DiskErr03_Italian',       'Disk err 03: Italian "ERROR 03"'),
    ('LABEL_E963BC', 'Str_DiskErr03_Spanish',       'Disk err 03: Spanish text'),
    ('LABEL_E963E8', 'Str_DiskErr03_French',        'Disk err 03: French text'),
    ('LABEL_E9641E', 'Str_DiskErr03_German',        'Disk err 03: German text'),

    # ---- Disk error 05 pointer table (E96482, E9649A-E964E6) ----
    # Pointer table + multilingual text for disk error 05 (disk save error).
    ('LABEL_E96482', 'StrTable_DiskErr05',          'Pointer table: disk error 05 (save error)'),
    ('LABEL_E9649A', 'Str_DiskErr05_Indonesian',    'Disk err 05: Indonesian - disk save error'),
    ('LABEL_E964DC', 'Str_DiskErr05_Italian',       'Disk err 05: Italian "ERROR 05"'),
    ('LABEL_E964E6', 'Str_DiskErr05_Spanish',       'Disk err 05: Spanish text'),

    # ---- Disk error 06 pointer table (E96628, E96640-E967FC) ----
    # Pointer table + multilingual text for disk error 06 (disk write protected).
    ('LABEL_E96628', 'StrTable_DiskErr06',          'Pointer table: disk error 06 (write protected)'),
    ('LABEL_E96640', 'Str_DiskErr06_Indonesian',    'Disk err 06: Indonesian - write protected'),
    ('LABEL_E966A2', 'Str_DiskErr06_Italian',       'Disk err 06: Italian "ERROR 06"'),
    ('LABEL_E966AC', 'Str_DiskErr06_Spanish',       'Disk err 06: Spanish text'),
    ('LABEL_E96724', 'Str_DiskErr06_French',        'Disk err 06: French text'),
    ('LABEL_E96796', 'Str_DiskErr06_German',        'Disk err 06: German text'),
    ('LABEL_E967FC', 'Str_DiskErr06_English',       'Disk err 06: English text'),

    # ---- Disk error 07 pointer table (E9685E, E96876-E968C0) ----
    # Pointer table + multilingual text for disk error 07 (disk full).
    ('LABEL_E9685E', 'StrTable_DiskErr07',          'Pointer table: disk error 07 (disk full)'),
    ('LABEL_E96876', 'Str_DiskErr07_Indonesian',    'Disk err 07: Indonesian - disk full'),
    ('LABEL_E968C0', 'Str_DiskErr07_Italian',       'Disk err 07: Italian "ERROR 07"'),

    # ---- Disk error 08 pointer table (E969C8, E969E0-E96BF4) ----
    # Pointer table + multilingual text for disk error 08 (format error).
    ('LABEL_E969C8', 'StrTable_DiskErr08',          'Pointer table: disk error 08 (format error)'),
    ('LABEL_E969E0', 'Str_DiskErr08_Indonesian',    'Disk err 08: Indonesian - format error'),
    ('LABEL_E96A5E', 'Str_DiskErr08_Italian',       'Disk err 08: Italian "ERROR 08"'),
    ('LABEL_E96A68', 'Str_DiskErr08_Spanish',       'Disk err 08: Spanish text'),
    ('LABEL_E96B06', 'Str_DiskErr08_French',        'Disk err 08: French text'),
    ('LABEL_E96BA6', 'Str_DiskErr08_German',        'Disk err 08: German text'),
    ('LABEL_E96BF4', 'Str_DiskErr08_English',       'Disk err 08: English text'),

    # ---- Disk error 09 pointer table (E96C78, E96C90-E96DDC) ----
    # Pointer table + multilingual text for disk error 09 (copy protected).
    ('LABEL_E96C78', 'StrTable_DiskErr09',          'Pointer table: disk error 09 (copy protected)'),
    ('LABEL_E96C90', 'Str_DiskErr09_Indonesian',    'Disk err 09: Indonesian - copy protected'),
    ('LABEL_E96CD8', 'Str_DiskErr09_Italian',       'Disk err 09: Italian "(ERROR 09)cp_prtct"'),
    ('LABEL_E96CEC', 'Str_DiskErr09_Spanish',       'Disk err 09: Spanish text'),
    ('LABEL_E96D42', 'Str_DiskErr09_French',        'Disk err 09: French text'),
    ('LABEL_E96D84', 'Str_DiskErr09_German',        'Disk err 09: German text'),
    ('LABEL_E96DDC', 'Str_DiskErr09_English',       'Disk err 09: English text'),

    # ---- Disk error 10 pointer table (E96E20, E96E38-E96EDE) ----
    # Pointer table + multilingual text for disk error 10 (already copy protected).
    ('LABEL_E96E20', 'StrTable_DiskErr10',          'Pointer table: disk error 10 (already copy protected)'),
    ('LABEL_E96E38', 'Str_DiskErr10_Indonesian',    'Disk err 10: Indonesian - already protected'),
    ('LABEL_E96E4E', 'Str_DiskErr10_Italian',       'Disk err 10: Italian "ERROR 10"'),
    ('LABEL_E96E58', 'Str_DiskErr10_Spanish',       'Disk err 10: Spanish text'),
    ('LABEL_E96E88', 'Str_DiskErr10_French',        'Disk err 10: French text'),
    ('LABEL_E96EB4', 'Str_DiskErr10_German',        'Disk err 10: German text'),
    ('LABEL_E96EDE', 'Str_DiskErr10_English',       'Disk err 10: English text'),

    # ---- Disk error 11 pointer table (E96F02, E96F1A-E96F3E) ----
    # Pointer table + multilingual text for disk error 11 (wrong password).
    ('LABEL_E96F02', 'StrTable_DiskErr11',          'Pointer table: disk error 11 (wrong password)'),
    ('LABEL_E96F1A', 'Str_DiskErr11_Indonesian',    'Disk err 11: Indonesian - wrong password'),
    ('LABEL_E96F3E', 'Str_DiskErr11_Italian',       'Disk err 11: Italian "ERROR 11"'),

    # ---- Disk error 12 pointer table (E96FE8, E96FFC-E970BA) ----
    # Pointer table + multilingual text for disk error 12 (battery low).
    ('LABEL_E96FE8', 'StrTable_DiskErr12',          'Pointer table: disk error 12 (battery low)'),
    ('LABEL_E96FFC', 'Str_DiskErr12_Indonesian',    'Disk err 12: Indonesian - battery low'),
    ('LABEL_E97048', 'Str_DiskErr12_Italian',       'Disk err 12: Italian "ERROR 12"'),
    ('LABEL_E97052', 'Str_DiskErr12_Spanish',       'Disk err 12: Spanish text'),
    ('LABEL_E970BA', 'Str_DiskErr12_French',        'Disk err 12: French text'),

    # ---- Disk error 16 pointer table (E97300, E97314-E97424) ----
    # Pointer table + multilingual text for disk error 16 (MIDI file incompatible).
    ('LABEL_E97300', 'StrTable_DiskErr16',          'Pointer table: disk error 16 (MIDI file incompatible)'),
    ('LABEL_E97314', 'Str_DiskErr16_Indonesian',    'Disk err 16: Indonesian - MIDI file incompatible'),
    ('LABEL_E97364', 'Str_DiskErr16_Italian',       'Disk err 16: Italian "(ERROR 16)err_cnv"'),
    ('LABEL_E97376', 'Str_DiskErr16_Spanish',       'Disk err 16: Spanish text'),
    ('LABEL_E973C8', 'Str_DiskErr16_French',        'Disk err 16: French text'),
    ('LABEL_E97424', 'Str_DiskErr16_German',        'Disk err 16: German text'),

    # ---- Disk error 17 pointer table (E974D4-E974D8, E974EC-E97576) ----
    # Pointer table + multilingual text for disk error 17 (not a MIDI file).
    # E974D4 and E974D8 are consecutive: E974D4 holds the pointer to E974D8's table.
    ('LABEL_E974D4', 'StrPtr_DiskErr17Table',       'Pointer to disk error 17 table'),
    ('LABEL_E974D8', 'StrTable_DiskErr17',          'Pointer table: disk error 17 (not MIDI file)'),
    ('LABEL_E974EC', 'Str_DiskErr17_Indonesian',    'Disk err 17: Indonesian - not MIDI file'),
    ('LABEL_E9750A', 'Str_DiskErr17_Italian',       'Disk err 17: Italian "(ERROR 17)err_no_midi"'),
    ('LABEL_E97520', 'Str_DiskErr17_Spanish',       'Disk err 17: Spanish text'),
    ('LABEL_E97546', 'Str_DiskErr17_French',        'Disk err 17: French text'),
    ('LABEL_E97576', 'Str_DiskErr17_German',        'Disk err 17: German text'),

    # ---- Disk error 18 text (E975D2-E97626) ----
    # Multilingual text for disk error 18 (wrong PPQ timebase).
    ('LABEL_E975D2', 'Str_DiskErr18_Indonesian',    'Disk err 18: Indonesian - wrong timebase PPQ'),
    ('LABEL_E97626', 'Str_DiskErr18_Italian',       'Disk err 18: Italian "(ERROR 18)err_timebase"'),

    # ---- Disk error 19 pointer table (E977AE, E977C6-E9781E) ----
    # Pointer table + multilingual text for disk error 19 (FORMAT 1 MIDI file).
    ('LABEL_E977AE', 'StrTable_DiskErr19',          'Pointer table: disk error 19 (FORMAT 1 MIDI file)'),
    ('LABEL_E977C6', 'Str_DiskErr19_Indonesian',    'Disk err 19: Indonesian - FORMAT 1 MIDI'),
    ('LABEL_E9781E', 'Str_DiskErr19_Italian',       'Disk err 19: Italian "(ERROR 19)dctp"'),
    ('LABEL_E9782E', 'Str_DiskErr19_Spanish',       'Disk err 19: Spanish text'),

    # ---- Disk error 20 text (E979A2-E97A0E) ----
    # Multilingual text for disk error 20 (sequencer data problem).
    ('LABEL_E979A2', 'Str_DiskErr20_Indonesian',    'Disk err 20: Indonesian - sequencer data problem'),
    ('LABEL_E97A0E', 'Str_DiskErr20_Italian',       'Disk err 20: Italian "ERROR 20"'),

    # ---- Disk error 24 (Rhythm track) pointer table (E97FF0, E98004-E9810C) ----
    # Pointer table + multilingual text for disk error 24 (duplicate rhythm track assign).
    ('LABEL_E97FF0', 'StrTable_DiskErr24_Rhythm',   'Pointer table: disk error 24 (duplicate rhythm track)'),
    ('LABEL_E98004', 'Str_Err24Rhythm_Indonesian',  'Err 24 rhythm: Indonesian text'),
    ('LABEL_E98054', 'Str_Err24Rhythm_Italian',     'Err 24 rhythm: Italian "ERROR 24"'),
    ('LABEL_E9805E', 'Str_Err24Rhythm_Spanish',     'Err 24 rhythm: Spanish text'),
    ('LABEL_E980A8', 'Str_Err24Rhythm_French',      'Err 24 rhythm: French text'),
    ('LABEL_E9810C', 'Str_Err24Rhythm_German',      'Err 24 rhythm: German text'),

    # ---- Disk error 24 (Chord track) pointer table (E981B8, E981D0-E98334) ----
    # Pointer table + multilingual text for disk error 24 (duplicate chord track assign).
    ('LABEL_E981B8', 'StrTable_DiskErr24_Chord',    'Pointer table: disk error 24 (duplicate chord track)'),
    ('LABEL_E981D0', 'Str_Err24Chord_Indonesian',   'Err 24 chord: Indonesian text'),
    ('LABEL_E9821E', 'Str_Err24Chord_Italian',      'Err 24 chord: Italian "ERROR 24"'),
    ('LABEL_E98228', 'Str_Err24Chord_Spanish',      'Err 24 chord: Spanish text'),
    ('LABEL_E98274', 'Str_Err24Chord_French',       'Err 24 chord: French text'),
    ('LABEL_E982D8', 'Str_Err24Chord_German',       'Err 24 chord: German text'),
    ('LABEL_E98334', 'Str_Err24Chord_English',      'Err 24 chord: English text'),

    # ---- Disk error 24 (Control track) text (E9839A-E983EC) ----
    # Multilingual text for disk error 24 (duplicate control track assign).
    ('LABEL_E9839A', 'Str_Err24Ctrl_Indonesian',    'Err 24 control: Indonesian text'),
    ('LABEL_E983EC', 'Str_Err24Ctrl_Italian',       'Err 24 control: Italian "ERROR 24"'),

    # ---- Disk error 24 (APC track) pointer table (E98560, E98574-E98614) ----
    # Pointer table + multilingual text for disk error 24 (duplicate APC track assign).
    ('LABEL_E98560', 'StrTable_DiskErr24_APC',      'Pointer table: disk error 24 (duplicate APC track)'),
    ('LABEL_E98574', 'Str_Err24APC_Indonesian',     'Err 24 APC: Indonesian text'),
    ('LABEL_E985BE', 'Str_Err24APC_Italian',        'Err 24 APC: Italian "ERROR 24"'),
    ('LABEL_E985C8', 'Str_Err24APC_Spanish',        'Err 24 APC: Spanish text'),
    ('LABEL_E98614', 'Str_Err24APC_French',         'Err 24 APC: French text'),

    # ---- Disk error 28 pointer table (E98D58, E98D6C-E98E52) ----
    # Pointer table + multilingual text for disk error 28 (song too long for MIDI file).
    ('LABEL_E98D58', 'StrTable_DiskErr28',          'Pointer table: disk error 28 (song too long for MIDI file)'),
    ('LABEL_E98D6C', 'Str_DiskErr28_Indonesian',    'Disk err 28: Indonesian text'),
    ('LABEL_E98DA6', 'Str_DiskErr28_Italian',       'Disk err 28: Italian "ERROR 28"'),
    ('LABEL_E98DB0', 'Str_DiskErr28_Spanish',       'Disk err 28: Spanish text'),
    ('LABEL_E98DFA', 'Str_DiskErr28_French',        'Disk err 28: French text'),
    ('LABEL_E98E52', 'Str_DiskErr28_German',        'Disk err 28: German text'),

    # ---- Disk error 29 pointer table (E98EC6, E98EDE-E98F72) ----
    # Pointer table + multilingual text for disk error 29 (MIDI file too large).
    ('LABEL_E98EC6', 'StrTable_DiskErr29',          'Pointer table: disk error 29 (MIDI file exceeds memory)'),
    ('LABEL_E98EDE', 'Str_DiskErr29_Indonesian',    'Disk err 29: Indonesian text'),
    ('LABEL_E98F68', 'Str_DiskErr29_Italian',       'Disk err 29: Italian "ERROR 29"'),
    ('LABEL_E98F72', 'Str_DiskErr29_Spanish',       'Disk err 29: Spanish text'),

    # ---- Disk error 30 text (E991EE, E99206-E992D0) ----
    # Pointer table + multilingual text for disk error 30 (cannot change time sig after record).
    ('LABEL_E991EE', 'StrTable_DiskErr30',          'Pointer table: disk error 30 (time sig locked)'),
    ('LABEL_E99206', 'Str_DiskErr30_Indonesian',    'Disk err 30: Indonesian text'),
    ('LABEL_E992D0', 'Str_DiskErr30_Italian',       'Disk err 30: Italian "ERROR 30"'),

    # ---- Disk error 41 pointer table (E99CD8, E99CEC-E99E34) ----
    # Pointer table + multilingual text for disk error 41 (SysEx reception error).
    ('LABEL_E99CD8', 'StrTable_DiskErr41',          'Pointer table: disk error 41 (SysEx receive error)'),
    ('LABEL_E99CEC', 'Str_DiskErr41_Indonesian',    'Disk err 41: Indonesian - SysEx receive error'),
    ('LABEL_E99D86', 'Str_DiskErr41_Italian',       'Disk err 41: Italian "ERROR 41"'),
    ('LABEL_E99D90', 'Str_DiskErr41_Spanish',       'Disk err 41: Spanish text'),
    ('LABEL_E99E34', 'Str_DiskErr41_French',        'Disk err 41: French text'),

    # ---- Disk error 43 pointer table (E9A2C8, E9A2DC-E9A494) ----
    # Pointer table + multilingual text for disk error 43 (file saved on previous KN keyboard).
    ('LABEL_E9A2C8', 'StrTable_DiskErr43',          'Pointer table: disk error 43 (old KN keyboard file)'),
    ('LABEL_E9A2DC', 'Str_DiskErr43_Indonesian',    'Disk err 43: Indonesian text'),
    ('LABEL_E9A378', 'Str_DiskErr43_Italian',       'Disk err 43: Italian "ERROR 43"'),
    ('LABEL_E9A382', 'Str_DiskErr43_Spanish',       'Disk err 43: Spanish text'),
    ('LABEL_E9A3FE', 'Str_DiskErr43_French',        'Disk err 43: French text'),
    ('LABEL_E9A494', 'Str_DiskErr43_German',        'Disk err 43: German text'),

    # ---- Disk error 44 pointer table (E9A5C8, E9A5E0-E9A7FA) ----
    # Pointer table + multilingual text for disk error 44 (cannot edit drum kit).
    ('LABEL_E9A5C8', 'StrTable_DiskErr44',          'Pointer table: disk error 44 (cannot edit drum kit)'),
    ('LABEL_E9A5E0', 'Str_DiskErr44_Indonesian',    'Disk err 44: Indonesian - cannot edit drum kit'),
    ('LABEL_E9A662', 'Str_DiskErr44_Italian',       'Disk err 44: Italian "ERROR 44"'),
    ('LABEL_E9A66C', 'Str_DiskErr44_Spanish',       'Disk err 44: Spanish text'),
    ('LABEL_E9A6F2', 'Str_DiskErr44_French',        'Disk err 44: French text'),
    ('LABEL_E9A778', 'Str_DiskErr44_German',        'Disk err 44: German text'),
    ('LABEL_E9A7FA', 'Str_DiskErr44_English',       'Disk err 44: English text'),

    # ---- Disk error 46 pointer table (E9A86A, E9A882-E9A8EC) ----
    # Pointer table + multilingual text for disk error 46 (can only insert melody tracks).
    ('LABEL_E9A86A', 'StrTable_DiskErr46',          'Pointer table: disk error 46 (melody-only track insert)'),
    ('LABEL_E9A882', 'Str_DiskErr46_Indonesian',    'Disk err 46: Indonesian text'),
    ('LABEL_E9A8EC', 'Str_DiskErr46_Italian',       'Disk err 46: Italian "ERROR 46"'),

    # ---- Disk error 47 pointer table (E9AAE0, E9AAF4-E9AC6C) ----
    # Pointer table + multilingual text for disk error 47 (Sound Arranger incompatible with Composer).
    ('LABEL_E9AAE0', 'StrTable_DiskErr47',          'Pointer table: disk error 47 (Sound Arranger+Composer)'),
    ('LABEL_E9AAF4', 'Str_DiskErr47_Indonesian',    'Disk err 47: Indonesian text'),
    ('LABEL_E9AB70', 'Str_DiskErr47_Italian',       'Disk err 47: Italian "ERROR 47"'),
    ('LABEL_E9AB7A', 'Str_DiskErr47_Spanish',       'Disk err 47: Spanish text'),
    ('LABEL_E9ABF8', 'Str_DiskErr47_French',        'Disk err 47: French text'),
    ('LABEL_E9AC6C', 'Str_DiskErr47_German',        'Disk err 47: German text'),

    # ---- End of region marker (E9AD48) ----
    # This is the final label in the region, at the start of the error 48 table
    # (2HD disk type error), which continues past line 20000.
    ('LABEL_E9AD48', 'StrTable_DiskErr48',          'Pointer table: disk error 48 (2HD disk type)'),
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
