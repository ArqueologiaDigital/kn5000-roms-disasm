#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E249F8-E27E60.
Uses binary I/O to handle encoding safely.

Region: Lines 6001-7500 of maincpu/kn5000_v10_program.s
Context: Display mode string tables, sequencer mode strings, demo menu strings,
         title function pointer tables, UI message strings (multilanguage),
         sequencer track assignment/part name strings, naka UI descriptor tables,
         and MT_ (message table) function name strings.
"""
import os, re

RENAMES = [
    # -----------------------------------------------------------------------
    # DkMdlyPly mode string table entries (disk medley play mode options)
    # Parent table at E24980, displayed strings for playback mode options
    # -----------------------------------------------------------------------
    ('LABEL_E249F8', 'DkMdlyPly_Str00', 'Disk medley play mode string entry 0'),
    ('LABEL_E249FA', 'DkMdlyPly_Str01', 'Disk medley play mode string entry 1'),
    ('LABEL_E249FC', 'DkMdlyPly_Str02', 'Disk medley play mode string entry 2'),
    ('LABEL_E249FE', 'DkMdlyPly_Str03', 'Disk medley play mode string entry 3'),
    ('LABEL_E24A00', 'DkMdlyPly_Str04', 'Disk medley play mode string entry 4'),
    ('LABEL_E24A02', 'DkMdlyPly_Str05', 'Disk medley play mode string entry 5'),
    ('LABEL_E24A04', 'DkMdlyPly_Str06', 'Disk medley play mode string entry 6'),
    ('LABEL_E24A06', 'DkMdlyPly_Str07', 'Disk medley play mode string entry 7'),
    ('LABEL_E24A08', 'DkMdlyPly_Str08', 'Disk medley play mode string entry 8'),
    ('LABEL_E24A0A', 'DkMdlyPly_Str09', 'Disk medley play mode string entry 9'),
    ('LABEL_E24A0C', 'DkMdlyPly_Str10', 'Disk medley play mode string entry 10'),
    ('LABEL_E24A0E', 'DkMdlyPly_Str11', 'Disk medley play mode string entry 11'),
    ('LABEL_E24A10', 'DkMdlyPly_Str12', 'Disk medley play mode string entry 12'),
    ('LABEL_E24A12', 'DkMdlyPly_Str13', 'Disk medley play mode string entry 13'),
    ('LABEL_E24A14', 'DkMdlyPly_Str14', 'Disk medley play mode string entry 14'),
    ('LABEL_E24A16', 'DkMdlyPly_Str15', 'Disk medley play mode string entry 15'),
    ('LABEL_E24A18', 'DkMdlyPly_Str16', 'Disk medley play mode string entry 16'),
    ('LABEL_E24A1A', 'DkMdlyPly_Str17', 'Disk medley play mode string entry 17'),
    ('LABEL_E24A1C', 'DkMdlyPly_Str18', 'Disk medley play mode string entry 18'),
    ('LABEL_E24A1E', 'DkMdlyPly_Str19', 'Disk medley play mode string entry 19'),
    ('LABEL_E24A20', 'DkMdlyPly_Str20', 'Disk medley play mode string entry 20'),
    ('LABEL_E24A22', 'DkMdlyPly_Str21', 'Disk medley play mode string entry 21'),
    ('LABEL_E24A24', 'DkMdlyPly_Str22', 'Disk medley play mode string entry 22'),
    ('LABEL_E24A26', 'DkMdlyPly_Str23', 'Disk medley play mode string entry 23'),
    ('LABEL_E24A28', 'DkMdlyPly_Str24', 'Disk medley play mode string entry 24'),
    ('LABEL_E24A2A', 'DkMdlyPly_Str25', 'Disk medley play mode string entry 25'),
    ('LABEL_E24A2C', 'DkMdlyPly_Str26', 'Disk medley play mode string entry 26'),
    ('LABEL_E24A2E', 'DkMdlyPly_Str27', 'Disk medley play mode string entry 27'),
    ('LABEL_E24A30', 'DkMdlyPly_Str28', 'Disk medley play mode string entry 28'),
    ('LABEL_E24A32', 'DkMdlyPly_Str29', 'Disk medley play mode string entry 29'),
    # "DkMdlyPly" named string — last in table (already named, skip renaming)
    ('LABEL_E24A34', 'DkMdlyPly_Name', 'Disk medley play mode title string "DkMdlyPly"'),

    # -----------------------------------------------------------------------
    # DkMdlyPly sub-table (E24A3E) — 13 entries for sub-options
    # Followed by SqMdlyPly mode entries
    # -----------------------------------------------------------------------
    ('LABEL_E24A3E', 'DkMdlyPly_SubTable', 'Disk medley play sub-option string pointer table'),
    ('LABEL_E24A72', 'DkMdlyPly_SubStr00', 'Disk medley play sub-option string 0'),
    ('LABEL_E24A74', 'DkMdlyPly_SubStr01', 'Disk medley play sub-option string 1'),
    ('LABEL_E24A76', 'DkMdlyPly_SubStr02', 'Disk medley play sub-option string 2'),
    ('LABEL_E24A78', 'DkMdlyPly_SubStr03', 'Disk medley play sub-option string 3'),
    ('LABEL_E24A7A', 'DkMdlyPly_SubStr04', 'Disk medley play sub-option string 4'),
    ('LABEL_E24A7C', 'DkMdlyPly_SubStr05', 'Disk medley play sub-option string 5'),
    ('LABEL_E24A7E', 'DkMdlyPly_SubStr06', 'Disk medley play sub-option string 6'),
    ('LABEL_E24A80', 'DkMdlyPly_SubStr07', 'Disk medley play sub-option string 7'),
    ('LABEL_E24A82', 'DkMdlyPly_SubStr08', 'Disk medley play sub-option string 8'),
    ('LABEL_E24A84', 'DkMdlyPly_SubStr09', 'Disk medley play sub-option string 9'),
    ('LABEL_E24A86', 'DkMdlyPly_SubStr10', 'Disk medley play sub-option string 10'),
    ('LABEL_E24A88', 'DkMdlyPly_SubStr11', 'Disk medley play sub-option string 11'),
    ('LABEL_E24A8A', 'SqMdlyPly_Name', 'Sequencer medley play title string "SqMdlyPly"'),

    # -----------------------------------------------------------------------
    # SqMdlyPly sub-table (E24A98) — 5 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24A98', 'SqMdlyPly_SubTable', 'Sequencer medley play sub-option string pointer table'),
    ('LABEL_E24AAC', 'SqMdlyPly_SubStr00', 'Sequencer medley play sub-option string 0'),
    ('LABEL_E24AAE', 'SqMdlyPly_SubStr01', 'Sequencer medley play sub-option string 1'),
    ('LABEL_E24AB0', 'SqMdlyPly_SubStr02', 'Sequencer medley play sub-option string 2'),
    ('LABEL_E24AB2', 'SqMdlyPly_SubStr03', 'Sequencer medley play sub-option string 3'),
    ('LABEL_E24AB4', 'SqMdlyPly_SubStr04', 'Sequencer medley play sub-option string 4'),
    # SqTrSel named string follows
    ('LABEL_E24AB6', 'SqTrSel_Name', 'Sequencer track select title string "SqTrSel"'),
    ('LABEL_E24AC6', 'SqTrSel_Str00', 'Sequencer track select string 0'),
    ('LABEL_E24AC8', 'SqTrSel_Str01', 'Sequencer track select string 1'),

    # -----------------------------------------------------------------------
    # SqTrAs (sequencer track assign) mode string table (E24ACA)
    # 22 string entries for track assignment options
    # -----------------------------------------------------------------------
    ('LABEL_E24ACA', 'SqTrAs_StrTable', 'Sequencer track assign string pointer table'),
    ('LABEL_E24B26', 'SqTrAs_Str00', 'Seq track assign string 0'),
    ('LABEL_E24B28', 'SqTrAs_Str01', 'Seq track assign string 1'),
    ('LABEL_E24B2A', 'SqTrAs_Str02', 'Seq track assign string 2'),
    ('LABEL_E24B2C', 'SqTrAs_Str03', 'Seq track assign string 3'),
    ('LABEL_E24B2E', 'SqTrAs_Str04', 'Seq track assign string 4'),
    ('LABEL_E24B30', 'SqTrAs_Str05', 'Seq track assign string 5'),
    ('LABEL_E24B32', 'SqTrAs_Str06', 'Seq track assign string 6'),
    ('LABEL_E24B34', 'SqTrAs_Str07', 'Seq track assign string 7'),
    ('LABEL_E24B36', 'SqTrAs_Str08', 'Seq track assign string 8'),
    # SqTrAsSure named string
    ('LABEL_E24B38', 'SqTrAsSure_Name', 'Seq track assign sure (confirm) title "SqTrAsSure"'),
    ('LABEL_E24B44', 'SqTrAs_Str09', 'Seq track assign string 9'),
    ('LABEL_E24B46', 'SqTrAs_Str10', 'Seq track assign string 10'),
    ('LABEL_E24B48', 'SqTrAs_Str11', 'Seq track assign string 11'),
    # TrAsPartSelSw named string
    ('LABEL_E24B4A', 'TrAsPartSelSw_Name', 'Track assign part select switch title "TrAsPartSelSw"'),
    ('LABEL_E24B58', 'TrAsGrid_Str00', 'Track assign grid string 0'),
    ('LABEL_E24B5A', 'TrAsGrid_Str01', 'Track assign grid string 1'),
    ('LABEL_E24B5C', 'TrAsGrid_Str02', 'Track assign grid string 2'),
    ('LABEL_E24B5E', 'TrAsGrid_Str03', 'Track assign grid string 3'),
    # TrAsGrid named string
    ('LABEL_E24B60', 'TrAsGrid_Name', 'Track assign grid title "TrAsGrid"'),
    # TrAsOkSw named string
    ('LABEL_E24B6A', 'TrAsOkSw_Name', 'Track assign OK switch title "TrAsOkSw"'),
    ('LABEL_E24B74', 'SqTrAs_Str12', 'Seq track assign string 12'),
    ('LABEL_E24B76', 'SqTrAs_Str13', 'Seq track assign string 13'),
    # SqTrAs named string
    ('LABEL_E24B78', 'SqTrAs_Name', 'Sequencer track assign title "SqTrAs"'),

    # -----------------------------------------------------------------------
    # SqTrAsPs (sequencer track assign patch select) string table (E24B80)
    # 29 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24B80', 'SqTrAsPs_StrTable', 'Seq track assign patch select string pointer table'),
    ('LABEL_E24BF4', 'SqTrAsPs_Str00', 'Seq track assign patch select string 0'),
    ('LABEL_E24BF6', 'SqTrAsPs_Str01', 'Seq track assign patch select string 1'),
    ('LABEL_E24BF8', 'SqTrAsPs_Str02', 'Seq track assign patch select string 2'),
    ('LABEL_E24BFA', 'SqTrAsPs_Str03', 'Seq track assign patch select string 3'),
    ('LABEL_E24BFC', 'SqTrAsPs_Str04', 'Seq track assign patch select string 4'),
    ('LABEL_E24BFE', 'SqTrAsPs_Str05', 'Seq track assign patch select string 5'),
    ('LABEL_E24C00', 'SqTrAsPs_Str06', 'Seq track assign patch select string 6'),
    ('LABEL_E24C02', 'SqTrAsPs_Str07', 'Seq track assign patch select string 7'),
    ('LABEL_E24C04', 'SqTrAsPs_Str08', 'Seq track assign patch select string 8'),
    # SqTrAsPsSure2 named string
    ('LABEL_E24C06', 'SqTrAsPsSure2_Name', 'Seq track assign patch sure2 title "SqTrAsPsSure2"'),
    ('LABEL_E24C14', 'SqTrAsPs_Str09', 'Seq track assign patch select string 9'),
    ('LABEL_E24C16', 'SqTrAsPs_Str10', 'Seq track assign patch select string 10'),
    ('LABEL_E24C18', 'SqTrAsPs_Str11', 'Seq track assign patch select string 11'),
    ('LABEL_E24C1A', 'SqTrAsPs_Str12', 'Seq track assign patch select string 12'),
    ('LABEL_E24C1C', 'SqTrAsPs_Str13', 'Seq track assign patch select string 13'),
    ('LABEL_E24C1E', 'SqTrAsPs_Str14', 'Seq track assign patch select string 14'),
    ('LABEL_E24C20', 'SqTrAsPs_Str15', 'Seq track assign patch select string 15'),
    ('LABEL_E24C22', 'SqTrAsPs_Str16', 'Seq track assign patch select string 16'),
    # SqTrAsPsSure1 named string
    ('LABEL_E24C24', 'SqTrAsPsSure1_Name', 'Seq track assign patch sure1 title "SqTrAsPsSure1"'),
    ('LABEL_E24C32', 'SqTrAsPs_Str17', 'Seq track assign patch select string 17'),
    ('LABEL_E24C34', 'SqTrAsPs_Str18', 'Seq track assign patch select string 18'),
    ('LABEL_E24C36', 'SqTrAsPs_Str19', 'Seq track assign patch select string 19'),
    # TrAsPsGmSel named string
    ('LABEL_E24C38', 'TrAsPsGmSel_Name', 'Track assign patch GM select title "TrAsPsGmSel"'),
    # TrAsPsTechSel named string
    ('LABEL_E24C44', 'TrAsPsTechSel_Name', 'Track assign patch tech select title "TrAsPsTechSel"'),
    # TrAsPsIniSel named string
    ('LABEL_E24C52', 'TrAsPsIniSel_Name', 'Track assign patch initial select title "TrAsPsIniSel"'),
    ('LABEL_E24C60', 'SqTrAsPs_Str20', 'Seq track assign patch select string 20'),
    ('LABEL_E24C62', 'SqTrAsPs_Str21', 'Seq track assign patch select string 21'),
    ('LABEL_E24C64', 'SqTrAsPs_Str22', 'Seq track assign patch select string 22'),
    # SqTrAsPs named string
    ('LABEL_E24C66', 'SqTrAsPs_Name', 'Seq track assign patch select title "SqTrAsPs"'),

    # -----------------------------------------------------------------------
    # SqSngSel (sequencer song select) string table (E24C70) — 6 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24C70', 'SqSngSel_StrTable', 'Sequencer song select string pointer table'),
    ('LABEL_E24C88', 'SqSngSel_Str00', 'Sequencer song select string 0'),
    ('LABEL_E24C8A', 'SqSngSel_Str01', 'Sequencer song select string 1'),
    ('LABEL_E24C8C', 'SqSngSel_Str02', 'Sequencer song select string 2'),
    ('LABEL_E24C8E', 'SqSngSel_Str03', 'Sequencer song select string 3'),
    ('LABEL_E24C90', 'SqSngSel_Str04', 'Sequencer song select string 4'),
    # SqSngSel named string
    ('LABEL_E24C92', 'SqSngSel_Name', 'Sequencer song select title "SqSngSel"'),

    # -----------------------------------------------------------------------
    # SqNameing (sequencer naming) string table (E24CA0) — 6 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24CA0', 'SqNameing_StrTable', 'Sequencer naming string pointer table'),
    ('LABEL_E24CB8', 'SqNameing_Str00', 'Sequencer naming string 0'),
    ('LABEL_E24CBA', 'SqNameing_Str01', 'Sequencer naming string 1'),
    ('LABEL_E24CBC', 'SqNameing_Str02', 'Sequencer naming string 2'),
    ('LABEL_E24CBE', 'SqNameing_Str03', 'Sequencer naming string 3'),
    ('LABEL_E24CC0', 'SqNameing_Str04', 'Sequencer naming string 4'),
    ('LABEL_E24CC2', 'SqNameing_Str05', 'Sequencer naming string 5'),
    # SqNameing named string
    ('LABEL_E24CC4', 'SqNameing_Name', 'Sequencer naming title "SqNameing"'),

    # -----------------------------------------------------------------------
    # AfterTouchSet string table (E24CCE) — 5 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24CCE', 'AfterTouchSet_StrTable', 'After touch set string pointer table'),
    ('LABEL_E24CE2', 'AfterTouchSet_Str00', 'After touch set string 0'),
    ('LABEL_E24CE4', 'AfterTouchSet_Str01', 'After touch set string 1'),
    ('LABEL_E24CE6', 'AfterTouchSet_Str02', 'After touch set string 2'),
    ('LABEL_E24CE8', 'AfterTouchSet_Str03', 'After touch set string 3'),
    # AfterTouchSet named string
    ('LABEL_E24CEA', 'AfterTouchSet_Name', 'After touch set title "AfterTouchSet"'),

    # -----------------------------------------------------------------------
    # AfterTouchSet single-entry pointer (E24CFC) and StepPartBal table
    # -----------------------------------------------------------------------
    ('LABEL_E24CFC', 'AfterTouchSet_Pad', 'After touch set padding/terminator entry'),

    # StepPartBal string table (E24CFE) — 7 entries
    ('LABEL_E24CFE', 'StepPartBal_StrTable', 'Step part balance string pointer table'),
    ('LABEL_E24D1A', 'StepPartBal_Str00', 'Step part balance string 0'),
    ('LABEL_E24D1C', 'StepPartBal_Str01', 'Step part balance string 1'),
    ('LABEL_E24D1E', 'StepPartBal_Str02', 'Step part balance string 2'),
    ('LABEL_E24D20', 'StepPartBal_Str03', 'Step part balance string 3'),
    ('LABEL_E24D22', 'StepPartBal_Str04', 'Step part balance string 4'),
    ('LABEL_E24D24', 'StepPartBal_Str05', 'Step part balance string 5'),
    # StepPartBal named string
    ('LABEL_E24D26', 'StepPartBal_Name', 'Step part balance title "StepPartBal"'),

    # -----------------------------------------------------------------------
    # DemoMenu string table (E24D32) — 5 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24D32', 'DemoMenu_StrTable', 'Demo menu string pointer table'),
    ('LABEL_E24D46', 'DemoMenu_Str00', 'Demo menu string 0'),
    ('LABEL_E24D48', 'DemoMenu_Str01', 'Demo menu string 1'),
    ('LABEL_E24D4A', 'DemoMenu_Str02', 'Demo menu string 2'),
    ('LABEL_E24D4C', 'DemoMenu_Str03', 'Demo menu string 3'),
    # DemoMenu named string
    ('LABEL_E24D4E', 'DemoMenu_Name', 'Demo menu title "DemoMenu"'),

    # -----------------------------------------------------------------------
    # DemoStyle string table (E24D58) — 13 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24D58', 'DemoStyle_StrTable', 'Demo style string pointer table'),
    ('LABEL_E24D8C', 'DemoMed1_Str00', 'Demo med1 string 0'),
    # DemoMed1 named string
    ('LABEL_E24D8E', 'DemoMed1_Name', 'Demo medley1 label "DemoMed1"'),
    ('LABEL_E24D98', 'DemoStyle_Str00', 'Demo style string 0'),
    ('LABEL_E24D9A', 'DemoStyle_Str01', 'Demo style string 1'),
    ('LABEL_E24D9C', 'DemoStyle_Str02', 'Demo style string 2'),
    ('LABEL_E24D9E', 'DemoStyle_Str03', 'Demo style string 3'),
    # DemoSong5 named string
    ('LABEL_E24DA0', 'DemoSong5_Name', 'Demo song 5 title "DemoSong5"'),
    # DemoSong4 named string
    ('LABEL_E24DAA', 'DemoSong4_Name', 'Demo song 4 title "DemoSong4"'),
    # DemoSong3 named string
    ('LABEL_E24DB4', 'DemoSong3_Name', 'Demo song 3 title "DemoSong3"'),
    # DemoSong2 named string
    ('LABEL_E24DBE', 'DemoSong2_Name', 'Demo song 2 title "DemoSong2"'),
    # DemoSong1 named string
    ('LABEL_E24DC8', 'DemoSong1_Name', 'Demo song 1 title "DemoSong1"'),
    # DemoSong0 named string
    ('LABEL_E24DD2', 'DemoSong0_Name', 'Demo song 0 title "DemoSong0"'),
    # DemoStyle named string
    ('LABEL_E24DDC', 'DemoStyle_Name', 'Demo style title "DemoStyle"'),

    # -----------------------------------------------------------------------
    # DemoSound string table (E24DE6) — 13 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24DE6', 'DemoSound_StrTable', 'Demo sound string pointer table'),
    ('LABEL_E24E1A', 'DemoMed2_Str00', 'Demo med2 string 0'),
    # DemoMed2 named string
    ('LABEL_E24E1C', 'DemoMed2_Name', 'Demo medley2 label "DemoMed2"'),
    ('LABEL_E24E26', 'DemoSound_Str00', 'Demo sound string 0'),
    ('LABEL_E24E28', 'DemoSound_Str01', 'Demo sound string 1'),
    ('LABEL_E24E2A', 'DemoSound_Str02', 'Demo sound string 2'),
    ('LABEL_E24E2C', 'DemoSound_Str03', 'Demo sound string 3'),
    # DemoSong11 named string
    ('LABEL_E24E2E', 'DemoSong11_Name', 'Demo song 11 title "DemoSong11"'),
    # DemoSong10 named string
    ('LABEL_E24E3A', 'DemoSong10_Name', 'Demo song 10 title "DemoSong10"'),
    # DemoSong9 named string
    ('LABEL_E24E46', 'DemoSong9_Name', 'Demo song 9 title "DemoSong9"'),
    # DemoSong8 named string
    ('LABEL_E24E50', 'DemoSong8_Name', 'Demo song 8 title "DemoSong8"'),
    # DemoSong7 named string
    ('LABEL_E24E5A', 'DemoSong7_Name', 'Demo song 7 title "DemoSong7"'),
    # DemoSong6 named string
    ('LABEL_E24E64', 'DemoSong6_Name', 'Demo song 6 title "DemoSong6"'),
    # DemoSound named string
    ('LABEL_E24E6E', 'DemoSound_Name', 'Demo sound title "DemoSound"'),

    # -----------------------------------------------------------------------
    # DemoRhy string table (E24E78) — 13 entries
    # -----------------------------------------------------------------------
    ('LABEL_E24E78', 'DemoRhy_StrTable', 'Demo rhythm string pointer table'),
    ('LABEL_E24EAC', 'DemoMed3_Str00', 'Demo med3 string 0'),
    # DemoMed3 named string
    ('LABEL_E24EAE', 'DemoMed3_Name', 'Demo medley3 label "DemoMed3"'),
    ('LABEL_E24EB8', 'DemoRhy_Str00', 'Demo rhythm string 0'),
    ('LABEL_E24EBA', 'DemoRhy_Str01', 'Demo rhythm string 1'),
    ('LABEL_E24EBC', 'DemoRhy_Str02', 'Demo rhythm string 2'),
    ('LABEL_E24EBE', 'DemoRhy_Str03', 'Demo rhythm string 3'),
    # DemoSong17 named string
    ('LABEL_E24EC0', 'DemoSong17_Name', 'Demo song 17 title "DemoSong17"'),
    # DemoSong16 named string
    ('LABEL_E24ECC', 'DemoSong16_Name', 'Demo song 16 title "DemoSong16"'),
    # DemoSong15 named string
    ('LABEL_E24ED8', 'DemoSong15_Name', 'Demo song 15 title "DemoSong15"'),
    # DemoSong14 named string
    ('LABEL_E24EE4', 'DemoSong14_Name', 'Demo song 14 title "DemoSong14"'),
    # DemoSong13 named string
    ('LABEL_E24EF0', 'DemoSong13_Name', 'Demo song 13 title "DemoSong13"'),
    # DemoSong12 named string
    ('LABEL_E24EFC', 'DemoSong12_Name', 'Demo song 12 title "DemoSong12"'),
    # DemoRhy named string
    ('LABEL_E24F08', 'DemoRhy_Name', 'Demo rhythm title "DemoRhy"'),

    # -----------------------------------------------------------------------
    # Title function pointer table (E250C2) — 32 entries pointing to TtlFunc strings
    # This is a table of function descriptor strings for all display modes
    # -----------------------------------------------------------------------
    ('LABEL_E250C2', 'TtlFunc_PtrTable', 'Title function pointer table (all display modes)'),
    ('LABEL_E25142', 'ApPlaySyori_Str00', 'ApPlaySyori pad string 0'),
    # ApPlaySyori named string
    ('LABEL_E25144', 'ApPlaySyori_Name', 'AP play syori (process) title "ApPlaySyori"'),
    # NameGetFuncCall named string
    ('LABEL_E25150', 'NameGetFuncCall_Name', 'Name get function call title "NameGetFuncCall"'),
    # MiddleFuncCall named string
    ('LABEL_E25160', 'MiddleFuncCall_Name', 'Middle function call title "MiddleFuncCall"'),
    # DemoRhyTtlFunc named string
    ('LABEL_E25170', 'DemoRhyTtlFunc_Name', 'Demo rhythm title func name "DemoRhyTtlFunc"'),
    # DemoSoundTtlFunc named string
    ('LABEL_E25180', 'DemoSoundTtlFunc_Name', 'Demo sound title func name "DemoSoundTtlFunc"'),
    # DemoStyleTtlFunc named string
    ('LABEL_E25192', 'DemoStyleTtlFunc_Name', 'Demo style title func name "DemoStyleTtlFunc"'),
    # DemoMenuTtlFunc named string
    ('LABEL_E251A4', 'DemoMenuTtlFunc_Name', 'Demo menu title func name "DemoMenuTtlFunc"'),
    # DemoModeFunc named string
    ('LABEL_E251B4', 'DemoModeFunc_Name', 'Demo mode function name "DemoModeFunc"'),
    # SqStepTtlFunc named string
    ('LABEL_E251C2', 'SqStepTtlFunc_Name', 'Seq step title func name "SqStepTtlFunc"'),
    # SqTrSelTtlFunc named string
    ('LABEL_E251D0', 'SqTrSelTtlFunc_Name', 'Seq track sel title func name "SqTrSelTtlFunc"'),
    # SeqStepModeFunc named string
    ('LABEL_E251E0', 'SeqStepModeFunc_Name', 'Seq step mode function name "SeqStepModeFunc"'),
    # DpSmfLyrTtlFunc named string
    ('LABEL_E251F0', 'DpSmfLyrTtlFunc_Name', 'Disp SMF lyrics title func name "DpSmfLyrTtlFunc"'),
    # DpSmfTtlFunc named string
    ('LABEL_E25200', 'DpSmfTtlFunc_Name', 'Disp SMF title func name "DpSmfTtlFunc"'),
    # DpPdTtlFunc named string
    ('LABEL_E2520E', 'DpPdTtlFunc_Name', 'Disp PD title func name "DpPdTtlFunc"'),
    # DpDocTtlFunc named string
    ('LABEL_E2521A', 'DpDocTtlFunc_Name', 'Disp DOC title func name "DpDocTtlFunc"'),
    # DpMdlySmfLyrTtlFunc named string
    ('LABEL_E25228', 'DpMdlySmfLyrTtlFunc_Name', 'Disp medley SMF lyrics title func "DpMdlySmfLyrTtlFunc"'),
    # DpMdlySmfTtlFunc named string
    ('LABEL_E2523C', 'DpMdlySmfTtlFunc_Name', 'Disp medley SMF title func "DpMdlySmfTtlFunc"'),
    # DpMdlyPdTtlFunc named string
    ('LABEL_E2524E', 'DpMdlyPdTtlFunc_Name', 'Disp medley PD title func "DpMdlyPdTtlFunc"'),
    # DpMdlyDocTtlFunc named string
    ('LABEL_E2525E', 'DpMdlyDocTtlFunc_Name', 'Disp medley DOC title func "DpMdlyDocTtlFunc"'),
    # DkMdlyPlyTtlFunc named string
    ('LABEL_E25270', 'DkMdlyPlyTtlFunc_Name', 'Disk medley play title func "DkMdlyPlyTtlFunc"'),
    # SqMdlyPlyTtlFunc named string
    ('LABEL_E25282', 'SqMdlyPlyTtlFunc_Name', 'Seq medley play title func "SqMdlyPlyTtlFunc"'),
    # SqTrAsPsSureFunc named string
    ('LABEL_E25294', 'SqTrAsPsSureFunc_Name', 'Seq track assign patch sure func "SqTrAsPsSureFunc"'),
    # SqTrAsPsTtlFunc named string
    ('LABEL_E252A6', 'SqTrAsPsTtlFunc_Name', 'Seq track assign patch title func "SqTrAsPsTtlFunc"'),
    # SqTrAsSureFunc named string
    ('LABEL_E252B6', 'SqTrAsSureFunc_Name', 'Seq track assign sure func "SqTrAsSureFunc"'),
    # SqTrAsTtlFunc named string
    ('LABEL_E252C6', 'SqTrAsTtlFunc_Name', 'Seq track assign title func "SqTrAsTtlFunc"'),
    # SqSngNameTtlFunc named string
    ('LABEL_E252D4', 'SqSngNameTtlFunc_Name', 'Seq song name title func "SqSngNameTtlFunc"'),
    # SqSngSelTtlFunc named string
    ('LABEL_E252E6', 'SqSngSelTtlFunc_Name', 'Seq song select title func "SqSngSelTtlFunc"'),
    # SqAftSetTtlFunc named string
    ('LABEL_E252F6', 'SqAftSetTtlFunc_Name', 'Seq after touch set title func "SqAftSetTtlFunc"'),
    # CDlikeSwTtlFunc named string
    ('LABEL_E25306', 'CDlikeSwTtlFunc_Name', 'CD-like switch title func "CDlikeSwTtlFunc"'),
    # SeqSongMemoryFunc named string
    ('LABEL_E25316', 'SeqSongMemoryFunc_Name', 'Seq song memory func "SeqSongMemoryFunc"'),
    # SeqSongNameFunc named string
    ('LABEL_E25328', 'SeqSongNameFunc_Name', 'Seq song name func "SeqSongNameFunc"'),

    # -----------------------------------------------------------------------
    # Multilanguage UI message strings (step record instructions)
    # E25338: English (base), then German/French/Spanish/Indonesian variants
    # -----------------------------------------------------------------------
    ('LABEL_E25338', 'MsgStepRec_En', 'Step record instruction string (English)'),
    ('LABEL_E2539C', 'MsgStepRec_De', 'Step record instruction string (German)'),
    ('LABEL_E25414', 'MsgStepRec_Fr', 'Step record instruction string (French)'),
    ('LABEL_E25478', 'MsgStepRec_Es', 'Step record instruction string (Spanish)'),
    ('LABEL_E254DC', 'MsgStepRec_Id', 'Step record instruction string (Indonesian)'),
    ('LABEL_E25540', 'MsgStepRec_En2', 'Step record instruction string (English variant 2)'),

    # After touch recording selection strings (multilanguage)
    ('LABEL_E255A4', 'MsgAftTchRec_En', 'After touch recording selection string (English)'),
    ('LABEL_E255E0', 'MsgAftTchRec_De', 'After touch recording selection string (German)'),
    ('LABEL_E2562E', 'MsgAftTchRec_Fr', 'After touch recording selection string (French)'),
    ('LABEL_E2566A', 'MsgAftTchRec_Es', 'After touch recording selection string (Spanish)'),
    ('LABEL_E256A6', 'MsgAftTchRec_Id', 'After touch recording selection string (Indonesian)'),
    ('LABEL_E256E2', 'MsgAftTchRec_En2', 'After touch recording selection string (English variant 2)'),

    # Song clear confirmation strings (multilanguage)
    ('LABEL_E2571E', 'MsgSongClr_En', 'Song clear confirmation string (English)'),
    ('LABEL_E25756', 'MsgSongClr_De', 'Song clear confirmation string (German)'),
    ('LABEL_E257A4', 'MsgSongClr_Fr', 'Song clear confirmation string (French)'),
    ('LABEL_E257DC', 'MsgSongClr_Es', 'Song clear confirmation string (Spanish)'),
    ('LABEL_E25814', 'MsgSongClr_Id', 'Song clear confirmation string (Indonesian)'),
    ('LABEL_E2584C', 'MsgSongClr_En2', 'Song clear confirmation string (English variant 2)'),

    # "ATTENTION!" label strings (multilanguage)
    ('LABEL_E25884', 'MsgAttention_En', 'Attention header string (English)'),
    ('LABEL_E25890', 'MsgAttention_De', 'Attention header string (German)'),
    ('LABEL_E2589A', 'MsgAttention_Fr', 'Attention header string (French)'),
    ('LABEL_E258A6', 'MsgAttention_Es', 'Attention header string (Spanish)'),
    ('LABEL_E258B2', 'MsgAttention_Id', 'Attention header string (Indonesian)'),
    ('LABEL_E258BE', 'MsgAttention_Id2', 'Attention header string (Indonesian variant 2)'),

    # "Are You Sure?" confirmation strings (multilanguage)
    ('LABEL_E258CA', 'MsgAreYouSure_En', 'Are you sure confirmation string (English)'),
    ('LABEL_E258D8', 'MsgAreYouSure_De', 'Are you sure confirmation string (German)'),
    ('LABEL_E258EA', 'MsgAreYouSure_Fr', 'Are you sure confirmation string (French)'),
    ('LABEL_E258FA', 'MsgAreYouSure_Es', 'Are you sure confirmation string (Spanish)'),
    ('LABEL_E25908', 'MsgAreYouSure_Id', 'Are you sure confirmation string (Indonesian)'),
    ('LABEL_E25916', 'MsgAreYouSure_Id2', 'Are you sure confirmation string (Indonesian variant 2)'),

    # General MIDI mode ON strings (multilanguage)
    ('LABEL_E25932', 'MsgGmModeOn_En', 'General MIDI mode ON warning string (English)'),
    ('LABEL_E2598E', 'MsgGmModeOn_De', 'General MIDI mode ON warning string (German)'),
    ('LABEL_E259FC', 'MsgGmModeOn_Fr', 'General MIDI mode ON warning string (French)'),
    ('LABEL_E25A68', 'MsgGmModeOn_Es', 'General MIDI mode ON warning string (Spanish)'),
    ('LABEL_E25AD8', 'MsgGmModeOn_En2', 'General MIDI mode ON warning string (English variant 2)'),
    ('LABEL_E25B34', 'MsgGmModeOn_Id', 'General MIDI mode ON warning string (Indonesian)'),

    # General MIDI mode OFF strings (multilanguage)
    ('LABEL_E25B86', 'MsgGmModeOff_En', 'General MIDI mode OFF warning string (English)'),
    ('LABEL_E25BF0', 'MsgGmModeOff_De', 'General MIDI mode OFF warning string (German)'),
    ('LABEL_E25C68', 'MsgGmModeOff_Fr', 'General MIDI mode OFF warning string (French)'),
    ('LABEL_E25CD8', 'MsgGmModeOff_Es', 'General MIDI mode OFF warning string (Spanish)'),
    ('LABEL_E25D5E', 'MsgGmModeOff_En2', 'General MIDI mode OFF warning string (English variant 2)'),
    ('LABEL_E25DC8', 'MsgGmModeOff_Id', 'General MIDI mode OFF warning string (Indonesian)'),

    # -----------------------------------------------------------------------
    # Track assignment change warning strings (multilanguage) + pointer table
    # -----------------------------------------------------------------------
    ('LABEL_E25E50', 'MsgTrkAssignChg_PtrTable', 'Track assignment change warning pointer table (by language)'),
    ('LABEL_E25E68', 'MsgTrkAssignChg_Id', 'Track assign change warning (Indonesian)'),
    ('LABEL_E25EC2', 'MsgTrkAssignChg_En', 'Track assign change warning (English)'),
    ('LABEL_E25F16', 'MsgTrkAssignChg_Es', 'Track assign change warning (Spanish)'),
    ('LABEL_E25F6E', 'MsgTrkAssignChg_Fr', 'Track assign change warning (French)'),
    ('LABEL_E25FCC', 'MsgTrkAssignChg_De', 'Track assign change warning (German)'),
    ('LABEL_E26024', 'MsgTrkAssignChg_En2', 'Track assign change warning (English variant 2)'),

    # -----------------------------------------------------------------------
    # Large multilanguage message pointer table (E26078)
    # Contains pointers to all the message strings above
    # -----------------------------------------------------------------------
    ('LABEL_E26078', 'Msg_LangPtrTable', 'Large multilanguage UI message pointer table'),

    # -----------------------------------------------------------------------
    # Track/part name short strings (E26170 area)
    # Used in track assignment display
    # -----------------------------------------------------------------------
    ('LABEL_E26170', 'TrkName_Part15', 'Track name string "PART15"'),
    ('LABEL_E26178', 'TrkName_Part14', 'Track name string "PART14"'),
    ('LABEL_E26180', 'TrkName_Part13', 'Track name string "PART13"'),
    ('LABEL_E26188', 'TrkName_Rhythm', 'Track name string "RHYTHM"'),
    ('LABEL_E26190', 'TrkName_Control', 'Track name string "CONTROL"'),
    ('LABEL_E26198', 'TrkName_APC', 'Track name string "APC"'),
    ('LABEL_E2619C', 'TrkName_Chord', 'Track name string "CHORD"'),
    ('LABEL_E261A2', 'TrkName_Drums', 'Track name string "DRUMS"'),
    ('LABEL_E261A8', 'TrkName_Part4', 'Track name string "PART4"'),
    ('LABEL_E261AE', 'TrkName_Part7', 'Track name string "PART7"'),
    ('LABEL_E261B4', 'TrkName_Part6', 'Track name string "PART6"'),
    ('LABEL_E261BA', 'TrkName_Part5', 'Track name string "PART5"'),
    ('LABEL_E261C0', 'TrkName_Part12', 'Track name string "PART12"'),
    ('LABEL_E261C8', 'TrkName_Part11', 'Track name string "PART11"'),
    ('LABEL_E261D0', 'TrkName_Part10', 'Track name string "PART10"'),
    ('LABEL_E261D8', 'TrkName_Part9', 'Track name string "PART9"'),
    ('LABEL_E261DE', 'TrkName_Part8', 'Track name string "PART8"'),
    ('LABEL_E261E4', 'TrkName_Right2', 'Track name string "RIGHT2"'),
    ('LABEL_E261EC', 'TrkName_Left', 'Track name string "LEFT"'),
    ('LABEL_E261F2', 'TrkName_Right1', 'Track name string "RIGHT1"'),

    # -----------------------------------------------------------------------
    # ExMD part name wide-format strings table (E262CA)
    # 20 entries — padded names for display in extended MIDI mode
    # -----------------------------------------------------------------------
    ('LABEL_E262CA', 'ExMD_PartName_PtrTable', 'ExMD part name wide-format string pointer table'),
    ('LABEL_E2631A', 'ExMD_PartName_Part15', 'ExMD part name wide string " PART 15 "'),
    ('LABEL_E26324', 'ExMD_PartName_Part14', 'ExMD part name wide string " PART 14 "'),
    ('LABEL_E2632E', 'ExMD_PartName_Part13', 'ExMD part name wide string " PART 13 "'),
    ('LABEL_E26338', 'ExMD_PartName_Rhythm', 'ExMD part name wide string " RHYTHM  "'),
    ('LABEL_E26342', 'ExMD_PartName_Control', 'ExMD part name wide string " CONTROL "'),
    ('LABEL_E2634C', 'ExMD_PartName_APC', 'ExMD part name wide string " APC     "'),
    ('LABEL_E26356', 'ExMD_PartName_Chord', 'ExMD part name wide string " CHORD   "'),
    ('LABEL_E26360', 'ExMD_PartName_Drums', 'ExMD part name wide string " DRUMS   "'),
    ('LABEL_E2636A', 'ExMD_PartName_Part4', 'ExMD part name wide string " PART 4  "'),
    ('LABEL_E26374', 'ExMD_PartName_Part7', 'ExMD part name wide string " PART 7  "'),
    ('LABEL_E2637E', 'ExMD_PartName_Part6', 'ExMD part name wide string " PART 6  "'),
    ('LABEL_E26388', 'ExMD_PartName_Part5', 'ExMD part name wide string " PART 5  "'),
    ('LABEL_E26392', 'ExMD_PartName_Part12', 'ExMD part name wide string " PART 12 "'),
    ('LABEL_E2639C', 'ExMD_PartName_Part11', 'ExMD part name wide string " PART 11 "'),
    ('LABEL_E263A6', 'ExMD_PartName_Part10', 'ExMD part name wide string " PART 10 "'),
    ('LABEL_E263B0', 'ExMD_PartName_Part9', 'ExMD part name wide string " PART 9  "'),
    ('LABEL_E263BA', 'ExMD_PartName_Part8', 'ExMD part name wide string " PART 8  "'),
    ('LABEL_E263C4', 'ExMD_PartName_Right2', 'ExMD part name wide string " RIGHT2  "'),
    ('LABEL_E263CE', 'ExMD_PartName_Left', 'ExMD part name wide string " LEFT    "'),
    ('LABEL_E263D8', 'ExMD_PartName_Right1', 'ExMD part name wide string " RIGHT1  "'),

    # -----------------------------------------------------------------------
    # Song number string table (E26510) — 16 entries " 1 " .. " 16 "
    # -----------------------------------------------------------------------
    ('LABEL_E26510', 'SongNum_PtrTable', 'Song number string pointer table (1-16)'),
    ('LABEL_E26550', 'SongNum_16', 'Song number string " 16 "'),
    ('LABEL_E26556', 'SongNum_15', 'Song number string " 15 "'),
    ('LABEL_E2655C', 'SongNum_14', 'Song number string " 14 "'),
    ('LABEL_E26562', 'SongNum_13', 'Song number string " 13 "'),
    ('LABEL_E26568', 'SongNum_12', 'Song number string " 12 "'),
    ('LABEL_E2656E', 'SongNum_11', 'Song number string " 11 "'),
    ('LABEL_E26574', 'SongNum_10', 'Song number string " 10 "'),
    ('LABEL_E2657A', 'SongNum_09', 'Song number string "  9 "'),
    ('LABEL_E26580', 'SongNum_08', 'Song number string "  8 "'),
    ('LABEL_E26586', 'SongNum_07', 'Song number string "  7 "'),
    ('LABEL_E2658C', 'SongNum_06', 'Song number string "  6 "'),
    ('LABEL_E26592', 'SongNum_05', 'Song number string "  5 "'),
    ('LABEL_E26598', 'SongNum_04', 'Song number string "  4 "'),
    ('LABEL_E2659E', 'SongNum_03', 'Song number string "  3 "'),
    ('LABEL_E265A4', 'SongNum_02', 'Song number string "  2 "'),
    ('LABEL_E265AA', 'SongNum_01', 'Song number string "  1 "'),

    # -----------------------------------------------------------------------
    # Song name string table (E265C8) — 10 entries " SONG 1 " .. " SONG10 "
    # -----------------------------------------------------------------------
    ('LABEL_E265C8', 'SongName_PtrTable', 'Song name string pointer table (SONG1-SONG10)'),
    ('LABEL_E265F0', 'SongName_All', 'Song name string "  ALL   "'),
    ('LABEL_E265FA', 'SongName_10', 'Song name string " SONG10 "'),
    ('LABEL_E26604', 'SongName_09', 'Song name string " SONG 9 "'),
    ('LABEL_E2660E', 'SongName_08', 'Song name string " SONG 8 "'),
    ('LABEL_E26618', 'SongName_07', 'Song name string " SONG 7 "'),
    ('LABEL_E26622', 'SongName_06', 'Song name string " SONG 6 "'),
    ('LABEL_E2662C', 'SongName_05', 'Song name string " SONG 5 "'),
    ('LABEL_E26636', 'SongName_04', 'Song name string " SONG 4 "'),
    ('LABEL_E26640', 'SongName_03', 'Song name string " SONG 3 "'),
    ('LABEL_E2664A', 'SongName_02', 'Song name string " SONG 2 "'),
    ('LABEL_E26654', 'SongName_01', 'Song name string " SONG 1 "'),

    # ON/OFF toggle string pair
    ('LABEL_E2667A', 'ToggleStr_ON', 'Toggle display string " ON  "'),
    ('LABEL_E26680', 'ToggleStr_OFF', 'Toggle display string " OFF "'),

    # -----------------------------------------------------------------------
    # MIDI channel name string table (E266A6) — 16 entries " CH 1 " .. " CH16 "
    # -----------------------------------------------------------------------
    ('LABEL_E266A6', 'MidiCh_PtrTable', 'MIDI channel name string pointer table (CH1-CH16)'),
    ('LABEL_E266E6', 'MidiCh_16', 'MIDI channel string " CH16 "'),
    ('LABEL_E266EE', 'MidiCh_15', 'MIDI channel string " CH15 "'),
    ('LABEL_E266F6', 'MidiCh_14', 'MIDI channel string " CH14 "'),
    ('LABEL_E266FE', 'MidiCh_13', 'MIDI channel string " CH13 "'),
    ('LABEL_E26706', 'MidiCh_12', 'MIDI channel string " CH12 "'),
    ('LABEL_E2670E', 'MidiCh_11', 'MIDI channel string " CH11 "'),
    ('LABEL_E26716', 'MidiCh_10', 'MIDI channel string " CH10 "'),
    ('LABEL_E2671E', 'MidiCh_09', 'MIDI channel string " CH 9 "'),
    ('LABEL_E26726', 'MidiCh_08', 'MIDI channel string " CH 8 "'),
    ('LABEL_E2672E', 'MidiCh_07', 'MIDI channel string " CH 7 "'),
    ('LABEL_E26736', 'MidiCh_06', 'MIDI channel string " CH 6 "'),
    ('LABEL_E2673E', 'MidiCh_05', 'MIDI channel string " CH 5 "'),
    ('LABEL_E26746', 'MidiCh_04', 'MIDI channel string " CH 4 "'),
    ('LABEL_E2674E', 'MidiCh_03', 'MIDI channel string " CH 3 "'),
    ('LABEL_E26756', 'MidiCh_02', 'MIDI channel string " CH 2 "'),
    ('LABEL_E2675E', 'MidiCh_01', 'MIDI channel string " CH 1 "'),

    # Medley display label strings
    ('LABEL_E26792', 'MedleyDisp_Blank', 'Medley display blank padding string'),
    ('LABEL_E267BE', 'PlayModeStr_Play', 'Play mode display string "    PLAY"'),
    ('LABEL_E267DE', 'PlayModeStr_Pause', 'Play mode display string "     PAUSE"'),

    # -----------------------------------------------------------------------
    # Large function descriptor name table (E26930) — 80+ func/proc name strings
    # Used by the display system to identify which function is active
    # Ordered from highest to lowest address in the table
    # -----------------------------------------------------------------------
    ('LABEL_E26930', 'FuncDesc_PtrTable', 'Display function descriptor name pointer table'),
    ('LABEL_E26A54', 'AutoPunchTtlRqFunc_Pad', 'AutoPunchTtlRqFunc pad string'),
    ('LABEL_E26A56', 'AutoPunchTtlRqFunc_Name', 'Function name string "AutoPunchTtlRqFunc"'),
    ('LABEL_E26A6A', 'PanicFunc_Name', 'Function name string "PanicFunc"'),
    ('LABEL_E26A74', 'SureJudgeFunc_Name', 'Function name string "SureJudgeFunc"'),
    ('LABEL_E26A82', 'EdMenuPageFunc_Name', 'Function name string "EdMenuPageFunc"'),
    ('LABEL_E26A92', 'StsAtPunchCheck_Name', 'Function name string "StsAtPunchCheck"'),
    ('LABEL_E26AA2', 'HelpFuncChkFunc_Name', 'Function name string "HelpFuncChkFunc"'),
    ('LABEL_E26AB2', 'HelpOkSwFunc_Name', 'Function name string "HelpOkSwFunc"'),
    ('LABEL_E26AC0', 'HelpMenuCheck_Name', 'Function name string "HelpMenuCheck"'),
    ('LABEL_E26ACE', 'HelpStsP4Check_Name', 'Function name string "HelpStsP4Check"'),
    ('LABEL_E26ADE', 'HelpStsP3Check_Name', 'Function name string "HelpStsP3Check"'),
    ('LABEL_E26AEE', 'HelpStsP2Check_Name', 'Function name string "HelpStsP2Check"'),
    ('LABEL_E26AFE', 'HelpStsCheck_Name', 'Function name string "HelpStsCheck"'),
    ('LABEL_E26B0C', 'HelpLangChkFunc_Name', 'Function name string "HelpLangChkFunc"'),
    ('LABEL_E26B1C', 'HelpTtlFunc_Name', 'Function name string "HelpTtlFunc"'),
    ('LABEL_E26B28', 'AcIndexWideToggleFunc_Name', 'Function name string "AcIndexWideToggleFunc"'),
    ('LABEL_E26B3E', 'AttSongClrCheck_Name', 'Function name string "AttSongClrCheck"'),
    ('LABEL_E26B4E', 'AttTrkClrCheck_Name', 'Function name string "AttTrkClrCheck"'),
    ('LABEL_E26B5E', 'StsNtDrEditCheck_Name', 'Function name string "StsNtDrEditCheck"'),
    ('LABEL_E26B70', 'StsTrkClr2Check_Name', 'Function name string "StsTrkClr2Check"'),
    ('LABEL_E26B80', 'StsTrkClr1Check_Name', 'Function name string "StsTrkClr1Check"'),
    ('LABEL_E26B90', 'StsPnlWrtCheck_Name', 'Function name string "StsPnlWrtCheck"'),
    ('LABEL_E26BA0', 'StsEasyRec2Check_Name', 'Function name string "StsEasyRec2Check"'),
    ('LABEL_E26BB2', 'StsEasyRec1Check_Name', 'Function name string "StsEasyRec1Check"'),
    ('LABEL_E26BC4', 'StsSeqMenu2Check_Name', 'Function name string "StsSeqMenu2Check"'),
    ('LABEL_E26BD6', 'StsSeqMenu1Check_Name', 'Function name string "StsSeqMenu1Check"'),
    ('LABEL_E26BE8', 'AttAttentionCheck_Name', 'Function name string "AttAttentionCheck"'),
    ('LABEL_E26BFA', 'AttAreYouSureCheck_Name', 'Function name string "AttAreYouSureCheck"'),
    ('LABEL_E26C0E', 'MimeOnOffFunc_Name', 'Function name string "MimeOnOffFunc"'),
    ('LABEL_E26C1C', 'BitmapDredt0k_Name', 'Function name string "BitmapDredt0k"'),
    ('LABEL_E26C2A', 'BitmapDredt0d_Name', 'Function name string "BitmapDredt0d"'),
    ('LABEL_E26C38', 'BitmapNtedt0k_Name', 'Function name string "BitmapNtedt0k"'),
    ('LABEL_E26C46', 'BitmapNtedt0d_Name', 'Function name string "BitmapNtedt0d"'),
    ('LABEL_E26C54', 'TrkMixerIntTtlFunc_Name', 'Function name string "TrkMixerIntTtlFunc"'),
    ('LABEL_E26C68', 'EqInOutFunc_Name', 'Function name string "EqInOutFunc"'),
    ('LABEL_E26C74', 'NoteEditFunc_Name', 'Function name string "NoteEditFunc"'),
    ('LABEL_E26C82', 'PunchInOutFunc_Name', 'Function name string "PunchInOutFunc"'),
    ('LABEL_E26C92', 'PlySngSel2Func_Name', 'Function name string "PlySngSel2Func"'),
    ('LABEL_E26CA2', 'PlySngSelFunc_Name', 'Function name string "PlySngSelFunc"'),
    ('LABEL_E26CB0', 'SngSelFunc_Name', 'Function name string "SngSelFunc"'),
    ('LABEL_E26CBC', 'EntertainerGridCheck_Name', 'Function name string "EntertainerGridCheck"'),
    ('LABEL_E26CD2', 'SqplyFunc_Name', 'Function name string "SqplyFunc"'),
    ('LABEL_E26CDC', 'MetroOnOffFunc_Name', 'Function name string "MetroOnOffFunc"'),
    ('LABEL_E26CEC', 'CycleOnOffFunc_Name', 'Function name string "CycleOnOffFunc"'),
    ('LABEL_E26CFC', 'MainExeFunc_Name', 'Function name string "MainExeFunc"'),
    ('LABEL_E26D08', 'SqedtFunc_Name', 'Function name string "SqedtFunc"'),
    ('LABEL_E26D12', 'EqualizerCngFunc_Name', 'Function name string "EqualizerCngFunc"'),
    ('LABEL_E26D24', 'DspItem0CngFunc_Name', 'Function name string "DspItem0CngFunc"'),
    ('LABEL_E26D34', 'IvRealRecExitProc_Name', 'Procedure name string "IvRealRecExitProc"'),
    ('LABEL_E26D46', 'AcPanicEditSwProc_Name', 'Procedure name string "AcPanicEditSwProc"'),
    ('LABEL_E26D58', 'IvAutoPunchExitProc_Name', 'Procedure name string "IvAutoPunchExitProc"'),
    ('LABEL_E26D6C', 'IvPunchExitProc_Name', 'Procedure name string "IvPunchExitProc"'),
    ('LABEL_E26D7C', 'IvSdaccProc_Name', 'Procedure name string "IvSdaccProc"'),
    ('LABEL_E26D88', 'IvSddspProc_Name', 'Procedure name string "IvSddspProc"'),
    ('LABEL_E26D94', 'IvSdrevProc_Name', 'Procedure name string "IvSdrevProc"'),
    ('LABEL_E26DA0', 'IvPnlWrExitProc_Name', 'Procedure name string "IvPnlWrExitProc"'),
    ('LABEL_E26DB0', 'HelpTtlProc_Name', 'Procedure name string "HelpTtlProc"'),
    ('LABEL_E26DBC', 'IvPlayExitProc_Name', 'Procedure name string "IvPlayExitProc"'),
    ('LABEL_E26DCC', 'AcIndexWideToggleProc_Name', 'Procedure name string "AcIndexWideToggleProc"'),
    ('LABEL_E26DE2', 'MsgToTtlProc_Name', 'Procedure name string "MsgToTtlProc"'),
    ('LABEL_E26DF0', 'EqOnOffFuncToggleProc_Name', 'Procedure name string "EqOnOffFuncToggleProc"'),
    ('LABEL_E26E06', 'NoteEditBoxProc_Name', 'Procedure name string "NoteEditBoxProc"'),
    ('LABEL_E26E16', 'SngSel2Proc_Name', 'Procedure name string "SngSel2Proc"'),
    ('LABEL_E26E22', 'SngSelProc_Name', 'Procedure name string "SngSelProc"'),
    ('LABEL_E26E2E', 'AcEntertainerGridBoxProc_Name', 'Procedure name string "AcEntertainerGridBoxProc"'),
    ('LABEL_E26E48', 'AccIllProc_Name', 'Procedure name string "AccIllProc"'),
    ('LABEL_E26E54', 'SqedtVal3Proc_Name', 'Procedure name string "SqedtVal3Proc"'),
    ('LABEL_E26E62', 'SqplyValProc_Name', 'Procedure name string "SqplyValProc"'),
    ('LABEL_E26E70', 'IvSongCopyExitProc_Name', 'Procedure name string "IvSongCopyExitProc"'),
    ('LABEL_E26E84', 'SqedtFixProc_Name', 'Procedure name string "SqedtFixProc"'),
    ('LABEL_E26E92', 'SqedtVal2Proc_Name', 'Procedure name string "SqedtVal2Proc"'),
    ('LABEL_E26EA0', 'SqedtValProc_Name', 'Procedure name string "SqedtValProc"'),
    ('LABEL_E26EAE', 'EqualizerBoxProc_Name', 'Procedure name string "EqualizerBoxProc"'),
    ('LABEL_E26EC0', 'EffectBoxProc_Name', 'Procedure name string "EffectBoxProc"'),

    # -----------------------------------------------------------------------
    # UI descriptor structs — field name string tables for naka UI widget types
    # Each table defines the field names of a specific widget descriptor struct.
    # Named by the widget type they describe, based on which naka_header they're paired with.
    # -----------------------------------------------------------------------

    # Widget descriptor A: {func, data, data2, ttl_no, ""} — used by naka_e24ECE (NAKA_TYPE_0x11)
    ('LABEL_E26ECE', 'NakaDesc_FuncData2TtlNo', 'Naka widget descriptor: func/data/data2/ttl_no fields'),
    ('LABEL_E26EE2', 'NakaFld_FuncData2TtlNo_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26EE4', 'NakaFld_TtlNo_A', 'Naka field name string "ttl_no"'),
    ('LABEL_E26EEC', 'NakaFld_Data2', 'Naka field name string "data2"'),
    ('LABEL_E26EF2', 'NakaFld_Data', 'Naka field name string "data"'),
    ('LABEL_E26EF8', 'NakaFld_Func_A', 'Naka field name string "func"'),

    # Widget descriptor B: {func, ttl_no, ""} — used by naka NAKA_TYPE_0x11
    ('LABEL_E26EFE', 'NakaDesc_FuncTtlNo', 'Naka widget descriptor: func/ttl_no fields'),
    ('LABEL_E26F0A', 'NakaFld_FuncTtlNo_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26F0C', 'NakaFld_TtlNo_B', 'Naka field name string "ttl_no"'),
    ('LABEL_E26F14', 'NakaFld_Func_B', 'Naka field name string "func"'),

    # Widget descriptor C: {color, fontcolor, func, ttl_no, ""} — used by NAKA_TYPE_0x10
    ('LABEL_E26F1A', 'NakaDesc_ColorFontFuncTtlNo', 'Naka widget descriptor: color/fontcolor/func/ttl_no fields'),
    ('LABEL_E26F2E', 'NakaFld_ColorFontFuncTtlNo_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26F30', 'NakaFld_TtlNo_C', 'Naka field name string "ttl_no"'),
    ('LABEL_E26F38', 'NakaFld_Func_C', 'Naka field name string "func"'),
    ('LABEL_E26F3E', 'NakaFld_Fontcolor_A', 'Naka field name string "fontcolor"'),
    ('LABEL_E26F48', 'NakaFld_Color_A', 'Naka field name string "color"'),

    # Widget descriptor D: {color, fontcolor, func, ""} — used by NAKA_TYPE_0x10
    ('LABEL_E26F4E', 'NakaDesc_ColorFontFunc', 'Naka widget descriptor: color/fontcolor/func fields'),
    ('LABEL_E26F5E', 'NakaFld_ColorFontFunc_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26F60', 'NakaFld_Func_D', 'Naka field name string "func"'),
    ('LABEL_E26F66', 'NakaFld_Fontcolor_B', 'Naka field name string "fontcolor"'),
    ('LABEL_E26F70', 'NakaFld_Color_B', 'Naka field name string "color"'),

    # Widget descriptor E: {color, fontcolor, border, ""} — used by NAKA_TYPE_0x10
    ('LABEL_E26F76', 'NakaDesc_ColorFontBorder', 'Naka widget descriptor: color/fontcolor/border fields'),
    ('LABEL_E26F86', 'NakaFld_ColorFontBorder_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26F88', 'NakaFld_Border', 'Naka field name string "border"'),
    ('LABEL_E26F90', 'NakaFld_Fontcolor_C', 'Naka field name string "fontcolor"'),
    ('LABEL_E26F9A', 'NakaFld_Color_C', 'Naka field name string "color"'),

    # Widget descriptor F: {""} — single-field empty descriptor — NAKA_TYPE_0x47
    ('LABEL_E26FA0', 'NakaDesc_Empty_A', 'Naka widget descriptor: empty (no fields)'),
    ('LABEL_E26FA4', 'NakaFld_Empty_A', 'Naka field name padding (empty)'),

    # Widget descriptor G: {color, fontcolor, func, ttl_no, ""} — NAKA_TYPE_0x10
    ('LABEL_E26FA6', 'NakaDesc_ColorFontFuncTtlNo_B', 'Naka widget descriptor B: color/fontcolor/func/ttl_no'),
    ('LABEL_E26FBA', 'NakaFld_ColorFontFuncTtlNo_B_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26FBC', 'NakaFld_TtlNo_D', 'Naka field name string "ttl_no"'),
    ('LABEL_E26FC4', 'NakaFld_Func_E', 'Naka field name string "func"'),
    ('LABEL_E26FCA', 'NakaFld_Fontcolor_D', 'Naka field name string "fontcolor"'),
    ('LABEL_E26FD4', 'NakaFld_Color_D', 'Naka field name string "color"'),

    # Widget descriptor H: {color, fontcolor, func, ""} — NAKA_TYPE_0x10
    ('LABEL_E26FDA', 'NakaDesc_ColorFontFunc_B', 'Naka widget descriptor B: color/fontcolor/func'),
    ('LABEL_E26FEA', 'NakaFld_ColorFontFunc_B_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E26FEC', 'NakaFld_Func_F', 'Naka field name string "func"'),
    ('LABEL_E26FF2', 'NakaFld_Fontcolor_E', 'Naka field name string "fontcolor"'),
    ('LABEL_E26FFC', 'NakaFld_Color_E', 'Naka field name string "color"'),

    # Widget descriptor I: {color, fontcolor, func, ttl_no, ""} — NAKA_TYPE_0x10
    ('LABEL_E27002', 'NakaDesc_ColorFontFuncTtlNo_C', 'Naka widget descriptor C: color/fontcolor/func/ttl_no'),
    ('LABEL_E27016', 'NakaFld_ColorFontFuncTtlNo_C_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E27018', 'NakaFld_TtlNo_E', 'Naka field name string "ttl_no"'),
    ('LABEL_E27020', 'NakaFld_Func_G', 'Naka field name string "func"'),
    ('LABEL_E27026', 'NakaFld_Fontcolor_F', 'Naka field name string "fontcolor"'),
    ('LABEL_E27030', 'NakaFld_Color_F', 'Naka field name string "color"'),

    # Widget descriptor J: {fixedcol, fixedrow, func, ""} — NAKA_TYPE_0x54
    ('LABEL_E27036', 'NakaDesc_FixedColRow', 'Naka widget descriptor: fixedcol/fixedrow/func fields'),
    ('LABEL_E27046', 'NakaFld_FixedColRow_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E27048', 'NakaFld_Func_H', 'Naka field name string "func"'),
    ('LABEL_E2704E', 'NakaFld_Fixedrow', 'Naka field name string "fixedrow"'),
    ('LABEL_E27058', 'NakaFld_Fixedcol', 'Naka field name string "fixedcol"'),

    # Widget descriptor K: {font, color, fontcolor, func, ttl_no, ""} — NAKA_TYPE_0x10
    ('LABEL_E27062', 'NakaDesc_FontColorFuncTtlNo', 'Naka widget descriptor: font/color/fontcolor/func/ttl_no'),
    ('LABEL_E2707A', 'NakaFld_FontColorFuncTtlNo_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E2707C', 'NakaFld_TtlNo_F', 'Naka field name string "ttl_no"'),
    ('LABEL_E27084', 'NakaFld_Func_I', 'Naka field name string "func"'),
    ('LABEL_E2708A', 'NakaFld_Fontcolor_G', 'Naka field name string "fontcolor"'),
    ('LABEL_E27094', 'NakaFld_Color_G', 'Naka field name string "color"'),
    ('LABEL_E2709A', 'NakaFld_Font_A', 'Naka field name string "font"'),

    # Widget descriptor L: {""} — single-field empty — NAKA_TYPE_0x10
    ('LABEL_E270A0', 'NakaDesc_Empty_B', 'Naka widget descriptor: empty (no fields) B'),
    ('LABEL_E270A4', 'NakaFld_Empty_B', 'Naka field name padding (empty) B'),

    # Widget descriptor M: {func, ttl_no, ""} — NAKA_TYPE_GROUP
    ('LABEL_E270A6', 'NakaDesc_FuncTtlNo_B', 'Naka widget descriptor B: func/ttl_no'),
    ('LABEL_E270B2', 'NakaFld_FuncTtlNo_B_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E270B4', 'NakaFld_TtlNo_G', 'Naka field name string "ttl_no"'),
    ('LABEL_E270BC', 'NakaFld_Func_J', 'Naka field name string "func"'),

    # Widget descriptor N: {""} — single-field empty — NAKA_TYPE_0x44
    ('LABEL_E270C2', 'NakaDesc_Empty_C', 'Naka widget descriptor: empty (no fields) C'),
    ('LABEL_E270C6', 'NakaFld_Empty_C', 'Naka field name padding (empty) C'),

    # Widget descriptor O: {""} — single-field empty — NAKA_TYPE_0x10
    ('LABEL_E270C8', 'NakaDesc_Empty_D', 'Naka widget descriptor: empty (no fields) D'),
    ('LABEL_E270CC', 'NakaFld_Empty_D', 'Naka field name padding (empty) D'),

    # Widget descriptor P: {func, index/tab, ""} — NAKA_TYPE_0x45
    ('LABEL_E270CE', 'NakaDesc_FuncIndex', 'Naka widget descriptor: func/index/tab fields'),
    ('LABEL_E270DE', 'NakaFld_FuncIndex_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E270E0', 'NakaFld_Func_K', 'Naka field name string "func"'),
    ('LABEL_E270E6', 'NakaFld_TabIndex', 'Naka field name bytes for "tab"/"index"'),

    # Widget descriptor Q: {mode, ""} — NAKA_TYPE_0x47
    ('LABEL_E270F0', 'NakaDesc_Mode', 'Naka widget descriptor: mode field'),
    ('LABEL_E270F8', 'NakaFld_Mode_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E270FA', 'NakaFld_Mode', 'Naka field name string "mode"'),

    # Widget descriptor R: {color, fontcolor, font, page, func, ""} — NAKA_TYPE_0x10
    ('LABEL_E27100', 'NakaDesc_ColorFontPageFunc', 'Naka widget descriptor: color/fontcolor/font/page/func'),
    ('LABEL_E27118', 'NakaFld_ColorFontPageFunc_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E2711A', 'NakaFld_Func_L', 'Naka field name string "func"'),
    ('LABEL_E27120', 'NakaFld_Page', 'Naka field name string "page"'),
    ('LABEL_E27126', 'NakaFld_Font_B', 'Naka field name string "font"'),
    ('LABEL_E2712C', 'NakaFld_Fontcolor_H', 'Naka field name string "fontcolor"'),
    ('LABEL_E27136', 'NakaFld_Color_H_Data', 'Naka field data bytes for color field (end of R descriptor)'),

    # Widget descriptor S: {""} — single-field empty — NAKA_TYPE_0x27
    ('LABEL_E27142', 'NakaDesc_Empty_E', 'Naka widget descriptor: empty E (IvRealRecExit context)'),
    ('LABEL_E27146', 'NakaFld_Empty_E', 'Naka field name padding (empty) E'),

    # Widget descriptor T: {""} — single-field empty — NAKA_TYPE_0x27
    ('LABEL_E27148', 'NakaDesc_Empty_F', 'Naka widget descriptor: empty F (IvAutoPunchExit context)'),
    ('LABEL_E2714C', 'NakaFld_Empty_F', 'Naka field name padding (empty) F'),

    # Widget descriptor U: {""} — single-field empty — NAKA_TYPE_0x27
    ('LABEL_E2714E', 'NakaDesc_Empty_G', 'Naka widget descriptor: empty G (IvPunchExit context)'),
    ('LABEL_E27152', 'NakaFld_Empty_G', 'Naka field name padding (empty) G'),

    # Widget descriptor V: {""} — single-field empty — NAKA_TYPE_0x47
    ('LABEL_E27154', 'NakaDesc_Empty_H', 'Naka widget descriptor: empty H (IvSdacc context)'),
    ('LABEL_E27158', 'NakaFld_Empty_H', 'Naka field name padding (empty) H'),

    # Widget descriptor W: {""} — single-field empty — NAKA_TYPE_0x47
    ('LABEL_E2715A', 'NakaDesc_Empty_I', 'Naka widget descriptor: empty I (AcIndexWideToggle context)'),
    ('LABEL_E2715E', 'NakaFld_Empty_I', 'Naka field name padding (empty) I'),

    # Widget descriptor X: {style, func, ""} — NAKA_TYPE_0x21
    ('LABEL_E27160', 'NakaDesc_StyleFunc', 'Naka widget descriptor: style/func fields'),
    ('LABEL_E2716C', 'NakaFld_StyleFunc_Pad', 'Naka field name padding (empty)'),
    ('LABEL_E2716E', 'NakaFld_Func_M', 'Naka field name string "func"'),
    ('LABEL_E27174', 'NakaFld_Style', 'Naka field name string "style"'),

    # Widget descriptor Y: {""} — single-field empty — NAKA_TYPE_0x47
    ('LABEL_E2717A', 'NakaDesc_Empty_J', 'Naka widget descriptor: empty J (final naka context)'),
    ('LABEL_E2717E', 'NakaFld_Empty_J', 'Naka field name padding (empty) J'),

    # -----------------------------------------------------------------------
    # Naka descriptor object labels from naka_e27408_e27556.s
    # These are the per-widget instance data (not field descriptors)
    # Each corresponds to a naka_header in the included file
    # -----------------------------------------------------------------------
    ('LABEL_E274D8', 'NakaInst_SngSel2', 'Naka instance: SngSel2 widget instance data'),
    ('LABEL_E274E2', 'NakaInst_SngSel', 'Naka instance: SngSel widget instance data'),
    ('LABEL_E274F0', 'NakaInst_AcEntertainerGridBox', 'Naka instance: AcEntertainerGridBox widget data'),
    ('LABEL_E2750A', 'NakaInst_AccIll', 'Naka instance: AccIll widget instance data'),
    ('LABEL_E27518', 'NakaInst_SqedtVal3', 'Naka instance: SqedtVal3 widget instance data'),
    ('LABEL_E27526', 'NakaInst_SqplyVal', 'Naka instance: SqplyVal widget instance data'),
    ('LABEL_E27536', 'NakaInst_IvSongCopyExit', 'Naka instance: IvSongCopyExit widget data'),
    ('LABEL_E27548', 'NakaInst_SqedtFix', 'Naka instance: SqedtFix widget instance data'),
    ('LABEL_E27556', 'NakaInst_SqedtVal2_End', 'Naka instance end marker for SqedtVal2'),
    ('LABEL_E27564', 'NakaInst_SqedtVal', 'Naka instance: SqedtVal widget instance data'),
    ('LABEL_E27574', 'NakaInst_SqedtVal_B', 'Naka instance: SqedtVal B widget instance data'),
    ('LABEL_E27586', 'NakaInst_EqualizerBox', 'Naka instance: EqualizerBox widget instance data'),

    # -----------------------------------------------------------------------
    # Event name string pointer table for effect/graph draw events (E27598)
    # -----------------------------------------------------------------------
    ('LABEL_E27598', 'EvtEffDraw_PtrTable', 'Effect/graph draw event name pointer table'),
    ('LABEL_E275B0', 'EvtName_GraphDraw', 'Event name string "EV_GRAPHDRAW"'),
    ('LABEL_E275BE', 'EvtName_EqStrDraw', 'Event name string "EV_EQSTRDRAW"'),
    ('LABEL_E275CC', 'EvtName_EqLineDraw', 'Event name string "EV_EQLINEDRAW"'),
    ('LABEL_E275DA', 'EvtName_EffParaDraw', 'Event name string "EV_EFFPARADRAW"'),
    ('LABEL_E275EA', 'EvtName_EffFixDraw', 'Event name string "EV_EFFFIXDRAW"'),

    # -----------------------------------------------------------------------
    # MT_ (message table) function name pointer table (E275FA)
    # Large table of all sequencer editor function/message names
    # -----------------------------------------------------------------------
    ('LABEL_E275FA', 'MT_FuncName_PtrTable', 'MT_ function name string pointer table'),

    # MT_ function name strings — panic/flash/language
    ('LABEL_E277DA', 'MT_Panic_Name', 'MT function name string "MT_PANIC"'),
    ('LABEL_E277E4', 'MT_FlashLoad_Name', 'MT function name string "MT_FLASHLOAD"'),
    ('LABEL_E277F2', 'MT_FlashWrite_Name', 'MT function name string "MT_FLASHWRITE"'),
    ('LABEL_E27800', 'MT_GetTSngNameString_Name', 'MT function name "MT_GetTSngNameString"'),
    ('LABEL_E27816', 'MT_GetFSngNameString_Name', 'MT function name "MT_GetFSngNameString"'),
    ('LABEL_E2782C', 'MT_ChkLang_Name', 'MT function name string "MT_ChkLang"'),
    ('LABEL_E27838', 'MT_SetLang_Name', 'MT function name string "MT_SetLang"'),
    ('LABEL_E27844', 'MT_GetLang_Name', 'MT function name string "MT_GetLang"'),
    ('LABEL_E27850', 'MT_ChkToggleEditSw_Name', 'MT function name "MT_ChkToggleEditSw"'),

    # MT_ drum/keyboard string getters
    ('LABEL_E27864', 'MT_GetDrNameString_Name', 'MT function name "MT_GetDrNameString"'),
    ('LABEL_E27878', 'MT_GetDrNumString_Name', 'MT function name "MT_GetDrNumString"'),
    ('LABEL_E2788A', 'MT_GetKb2Str_Name', 'MT function name string "MT_GetKb2Str"'),
    ('LABEL_E27898', 'MT_GetKb1Str_Name', 'MT function name string "MT_GetKb1Str"'),
    ('LABEL_E278A6', 'MT_GetTtlNow_Name', 'MT function name string "MT_GetTtlNow"'),

    # MT_ equalizer string getters (7 bands)
    ('LABEL_E278B4', 'MT_GetEq7Str_Name', 'MT function name string "MT_GetEq7Str"'),
    ('LABEL_E278C2', 'MT_GetEq6Str_Name', 'MT function name string "MT_GetEq6Str"'),
    ('LABEL_E278D0', 'MT_GetEq5Str_Name', 'MT function name string "MT_GetEq5Str"'),
    ('LABEL_E278DE', 'MT_GetEq4Str_Name', 'MT function name string "MT_GetEq4Str"'),
    ('LABEL_E278EC', 'MT_GetEq3Str_Name', 'MT function name string "MT_GetEq3Str"'),
    ('LABEL_E278FA', 'MT_GetEq2Str_Name', 'MT function name string "MT_GetEq2Str"'),
    ('LABEL_E27908', 'MT_GetEq1Str_Name', 'MT function name string "MT_GetEq1Str"'),
    ('LABEL_E27916', 'MT_GetEq0Str_Name', 'MT function name string "MT_GetEq0Str"'),

    # MT_ note display functions
    ('LABEL_E27924', 'MT_NoteHilightDisp_Name', 'MT function name "MT_NoteHilightDisp"'),
    ('LABEL_E27938', 'MT_NoteBarDisp2_Name', 'MT function name string "MT_NoteBarDisp2"'),
    ('LABEL_E27948', 'MT_NoteBarDisp_Name', 'MT function name string "MT_NoteBarDisp"'),

    # MT_ measure/position string getters
    ('LABEL_E27958', 'MT_GetMeasCngSv_Name', 'MT function name "MT_GetMeasCngSv"'),
    ('LABEL_E27968', 'MT_GetMeasTopNumSv_Name', 'MT function name "MT_GetMeasTopNumSv"'),
    ('LABEL_E2797C', 'MT_GetInputLenString_Name', 'MT function name "MT_GetInputLenString"'),
    ('LABEL_E27992', 'MT_GetLenString_Name', 'MT function name "MT_GetLenString"'),
    ('LABEL_E279A2', 'MT_GetInputVelString_Name', 'MT function name "MT_GetInputVelString"'),
    ('LABEL_E279B8', 'MT_GetVelString_Name', 'MT function name "MT_GetVelString"'),
    ('LABEL_E279C8', 'MT_GetNoteString_Name', 'MT function name "MT_GetNoteString"'),
    ('LABEL_E279DA', 'MT_GetIncString_Name', 'MT function name "MT_GetIncString"'),
    ('LABEL_E279EA', 'MT_GetPosString_Name', 'MT function name "MT_GetPosString"'),
    ('LABEL_E279FA', 'MT_GetHakuString_Name', 'MT function name "MT_GetHakuString"'),
    ('LABEL_E27A0C', 'MT_GetLinePos_Name', 'MT function name string "MT_GetLinePos"'),
    ('LABEL_E27A1A', 'MT_GetTriPos_Name', 'MT function name string "MT_GetTriPos"'),
    ('LABEL_E27A28', 'MT_GetEndPos_Name', 'MT function name string "MT_GetEndPos"'),

    # MT_ punch/measure string getters
    ('LABEL_E27A36', 'MT_GetPCntInString_Name', 'MT function name "MT_GetPCntInString"'),
    ('LABEL_E27A4A', 'MT_GetPOutMeasString_Name', 'MT function name "MT_GetPOutMeasString"'),
    ('LABEL_E27A60', 'MT_GetPInMeasString_Name', 'MT function name "MT_GetPInMeasString"'),
    ('LABEL_E27A74', 'MT_GetPMeasString_Name', 'MT function name "MT_GetPMeasString"'),

    # MT_ accordion/scaler functions
    ('LABEL_E27A86', 'MT_GetAccLvlStr_Name', 'MT function name "MT_GetAccLvlStr"'),
    ('LABEL_E27A96', 'MT_GetSclrPerString_Name', 'MT function name "MT_GetSclrPerString"'),
    ('LABEL_E27AAA', 'MT_GetSclrKbString_Name', 'MT function name "MT_GetSclrKbString"'),
    ('LABEL_E27ABE', 'MT_GetSclrNameString_Name', 'MT function name "MT_GetSclrNameString"'),
    ('LABEL_E27AD4', 'MT_GetSclrNoString_Name', 'MT function name "MT_GetSclrNoString"'),
    ('LABEL_E27AE8', 'MT_GetSoloEnString_Name', 'MT function name "MT_GetSoloEnString"'),

    # MT_ playback control setters
    ('LABEL_E27AFC', 'MT_SetPunch_Name', 'MT function name string "MT_SetPunch"'),
    ('LABEL_E27B08', 'MT_SetMetro_Name', 'MT function name string "MT_SetMetro"'),
    ('LABEL_E27B14', 'MT_SetCycle_Name', 'MT function name string "MT_SetCycle"'),

    # MT_ cycle string getters
    ('LABEL_E27B20', 'MT_GetCycEndMString_Name', 'MT function name "MT_GetCycEndMString"'),
    ('LABEL_E27B34', 'MT_GetCycSrtMString_Name', 'MT function name "MT_GetCycSrtMString"'),
    ('LABEL_E27B48', 'MT_GetCycEnString_Name', 'MT function name "MT_GetCycEnString"'),
    ('LABEL_E27B5A', 'MT_GetMemString_Name', 'MT function name "MT_GetMemString"'),
    ('LABEL_E27B6A', 'MT_GetBeatString_Name', 'MT function name "MT_GetBeatString"'),
    ('LABEL_E27B7C', 'MT_GetMeasString_Name', 'MT function name "MT_GetMeasString"'),

    # MT_ cursor position functions
    ('LABEL_E27B8E', 'MT_SetToCur_Name', 'MT function name string "MT_SetToCur"'),
    ('LABEL_E27B9A', 'MT_GetToCur_Name', 'MT function name string "MT_GetToCur"'),
    ('LABEL_E27BA6', 'MT_SetFromCur_Name', 'MT function name string "MT_SetFromCur"'),
    ('LABEL_E27BB4', 'MT_GetFromCur_Name', 'MT function name string "MT_GetFromCur"'),
    ('LABEL_E27BC2', 'MT_ChkCur2_Name', 'MT function name string "MT_ChkCur2"'),
    ('LABEL_E27BCE', 'MT_ChkCur_Name', 'MT function name string "MT_ChkCur"'),
    ('LABEL_E27BD8', 'MT_CurToParam_Name', 'MT function name string "MT_CurToParam"'),
    ('LABEL_E27BE6', 'MT_GetCurPos_Name', 'MT function name string "MT_GetCurPos"'),
    ('LABEL_E27BF4', 'MT_SetCurPos_Name', 'MT function name string "MT_SetCurPos"'),

    # MT_ song copy/paste string getters
    ('LABEL_E27C02', 'MT_GetScpTtrString_Name', 'MT function name "MT_GetScpTtrString"'),
    ('LABEL_E27C16', 'MT_GetScpTsngString_Name', 'MT function name "MT_GetScpTsngString"'),
    ('LABEL_E27C2A', 'MT_GetScpFtrString_Name', 'MT function name "MT_GetScpFtrString"'),
    ('LABEL_E27C3E', 'MT_GetScpFsngString_Name', 'MT function name "MT_GetScpFsngString"'),

    # MT_ MINS (minutes?) and MCP string getters
    ('LABEL_E27C52', 'MT_GetMinsRepString_Name', 'MT function name "MT_GetMinsRepString"'),
    ('LABEL_E27C66', 'MT_GetMinsSMString_Name', 'MT function name "MT_GetMinsSMString"'),
    ('LABEL_E27C7A', 'MT_GetMinsTrBString_Name', 'MT function name "MT_GetMinsTrBString"'),
    ('LABEL_E27C8E', 'MT_GetMinsLMString_Name', 'MT function name "MT_GetMinsLMString"'),
    ('LABEL_E27CA2', 'MT_GetMinsFMString_Name', 'MT function name "MT_GetMinsFMString"'),
    ('LABEL_E27CB6', 'MT_GetMinsTrAString_Name', 'MT function name "MT_GetMinsTrAString"'),
    ('LABEL_E27CCA', 'MT_GetMcpRepString_Name', 'MT function name "MT_GetMcpRepString"'),
    ('LABEL_E27CDE', 'MT_GetMcpSMString_Name', 'MT function name "MT_GetMcpSMString"'),
    ('LABEL_E27CF0', 'MT_GetMcpTrBString_Name', 'MT function name "MT_GetMcpTrBString"'),
    ('LABEL_E27D04', 'MT_GetMcpLMString_Name', 'MT function name "MT_GetMcpLMString"'),
    ('LABEL_E27D16', 'MT_GetMcpFMString_Name', 'MT function name "MT_GetMcpFMString"'),
    ('LABEL_E27D28', 'MT_GetMcpTrAString_Name', 'MT function name "MT_GetMcpTrAString"'),

    # MT_ merge track string getters
    ('LABEL_E27D3C', 'MT_GetMrgTrCString_Name', 'MT function name "MT_GetMrgTrCString"'),
    ('LABEL_E27D50', 'MT_GetMrgTrBString_Name', 'MT function name "MT_GetMrgTrBString"'),
    ('LABEL_E27D64', 'MT_GetMrgTrAString_Name', 'MT function name "MT_GetMrgTrAString"'),

    # MT_ channel/track string getters
    ('LABEL_E27D78', 'MT_GetCnString_Name', 'MT function name string "MT_GetCnString"'),
    ('LABEL_E27D88', 'MT_GetTnString_Name', 'MT function name string "MT_GetTnString"'),

    # MT_ quantize string getters
    ('LABEL_E27D98', 'MT_GetQtzWinString_Name', 'MT function name "MT_GetQtzWinString"'),
    ('LABEL_E27DAC', 'MT_GetQtzStrString_Name', 'MT function name "MT_GetQtzStrString"'),
    ('LABEL_E27DC0', 'MT_GetQtzValString_Name', 'MT function name "MT_GetQtzValString"'),

    # MT_ event/note edit string getters
    ('LABEL_E27DD4', 'MT_GetMersString_Name', 'MT function name "MT_GetMersString"'),
    ('LABEL_E27DE6', 'MT_GetVeloString_Name', 'MT function name "MT_GetVeloString"'),
    ('LABEL_E27DF8', 'MT_GetTrnsString_Name', 'MT function name "MT_GetTrnsString"'),
    ('LABEL_E27E0A', 'MT_GetAdlyString_Name', 'MT function name "MT_GetAdlyString"'),
    ('LABEL_E27E1C', 'MT_GetLMString_Name', 'MT function name string "MT_GetLMString"'),
    ('LABEL_E27E2C', 'MT_GetFMString_Name', 'MT function name string "MT_GetFMString"'),
    ('LABEL_E27E3C', 'MT_GetTrkString_Name', 'MT function name "MT_GetTrkString"'),

    # MT_ value increment/decrement
    ('LABEL_E27E4C', 'MT_DecVal_Name', 'MT function name string "MT_DecVal"'),
    ('LABEL_E27E56', 'MT_IncVal_Name', 'MT function name string "MT_IncVal"'),
    # MT_GetDispPos — last in region (line 7500)
    ('LABEL_E27E60', 'MT_GetDispPos_Name', 'MT function name string "MT_GetDispPos"'),

    # -----------------------------------------------------------------------
    # Beyond line 7500 boundary — included for completeness of referenced labels
    # These appear as .long targets from the table at E275FA
    # -----------------------------------------------------------------------
    ('LABEL_E27E6E', 'MT_CngEffPara_Name', 'MT function name "MT_CngEffPara"'),
    ('LABEL_E27E7C', 'MT_CngEffType_Name', 'MT function name "MT_CngEffType"'),
    ('LABEL_E27E8A', 'MT_GetParaSize_Name', 'MT function name "MT_GetParaSize"'),
    ('LABEL_E27E9A', 'MT_RetEffPara_Name', 'MT function name "MT_RetEffPara"'),
    ('LABEL_E27EA8', 'MT_RetEffFix_Name', 'MT function name string "MT_RetEffFix"'),
    ('LABEL_E27EB6', 'MT_GetItemTop_Name', 'MT function name "MT_GetItemTop"'),
    ('LABEL_E27EC4', 'MT_SetItemTop_Name', 'MT function name "MT_SetItemTop"'),
    ('LABEL_E27ED2', 'MT_GetItemOff_Name', 'MT function name "MT_GetItemOff"'),
    ('LABEL_E27EE0', 'MT_SetItemOff_Name', 'MT function name "MT_SetItemOff"'),
    ('LABEL_E27EEE', 'MT_GetItemExist_Name', 'MT function name "MT_GetItemExist"'),
    ('LABEL_E27EFE', 'MT_GetEffDlt7Str_Name', 'MT function name "MT_GetEffDlt7Str"'),
    ('LABEL_E27F10', 'MT_GetEffDlt6Str_Name', 'MT function name "MT_GetEffDlt6Str"'),
    ('LABEL_E27F22', 'MT_GetEffDlt5Str_Name', 'MT function name "MT_GetEffDlt5Str"'),
    ('LABEL_E27F34', 'MT_GetEffDlt4Str_Name', 'MT function name "MT_GetEffDlt4Str"'),
    ('LABEL_E27F46', 'MT_GetEffDlt3Str_Name', 'MT function name "MT_GetEffDlt3Str"'),
    ('LABEL_E27F58', 'MT_GetEffDlt2Str_Name', 'MT function name "MT_GetEffDlt2Str"'),
    ('LABEL_E27F6A', 'MT_GetEffDlt1Str_Name', 'MT function name "MT_GetEffDlt1Str"'),
    ('LABEL_E27F7C', 'MT_GetEffDlt0Str_Name', 'MT function name "MT_GetEffDlt0Str"'),
    ('LABEL_E27F8E', 'MT_GetEffFixString_Name', 'MT function name "MT_GetEffFixString"'),
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
