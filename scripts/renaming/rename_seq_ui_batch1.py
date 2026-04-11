#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in sequencer_ui.s (batch 1, lines 1-2010)"""
import sys
import os

# Mapping of old label -> new label
RENAMES = {
    # Language check return-zero blocks (lines 98-201)
    "LABEL_F2A93A": "PartSelLang_ReturnZero",
    "LABEL_F2A94B": "AfterLang_ReturnZero",
    "LABEL_F2A95C": "TrAsPreLang_ReturnZero",
    "LABEL_F2A96D": "AtentionLang_ReturnZero",
    "LABEL_F2A97E": "AreYouSureLang_ReturnZero",
    "LABEL_F2A98F": "GmOnSureLang_ReturnZero",
    "LABEL_F2A9A0": "GmOffSureLang_ReturnZero",
    "LABEL_F2A9FF": "TrAsSureLang_ReturnZero",

    # Audio_ExternalCallback end / LyricsBoxProc boundary
    "LABEL_F2AA32": "Audio_ExternalCallback_End",

    # LyricsBoxProc event dispatch branches (lines 220-625)
    "LABEL_F2AA72": "LyricsBox_HandleEvent9",
    "LABEL_F2AA8A": "LyricsBox_MatchedTitle",
    "LABEL_F2AA98": "LyricsBox_ClearBuffers",
    "LABEL_F2AAA4": "LyricsBox_ClearOuterLoop",
    "LABEL_F2AAA9": "LyricsBox_ClearInnerLoop",
    "LABEL_F2AABB": "LyricsBox_HandleEventA",
    "LABEL_F2AAED": "LyricsBox_DrawClientArea",
    "LABEL_F2AB15": "LyricsBox_DrawLineLoop",
    "LABEL_F2AB6C": "LyricsBox_CheckCurrentLine",
    "LABEL_F2AC23": "LyricsBox_CopyAndDraw",
    "LABEL_F2AC56": "LyricsBox_DrawAndAdvance",
    "LABEL_F2AC6C": "LyricsBox_HandleEventB",
    "LABEL_F2AC98": "LyricsBox_DrawCurrentLine",
    "LABEL_F2AD29": "LyricsBox_UpdateCursors46",
    "LABEL_F2AD36": "LyricsBox_HandleEventC",
    "LABEL_F2AD62": "LyricsBox_DrawSelLine",
    "LABEL_F2ADF1": "LyricsBox_UpdateCursors3E",
    "LABEL_F2ADFB": "LyricsBox_StoreCursorPos",
    "LABEL_F2AE01": "LyricsBox_HandleEventD",
    "LABEL_F2AE22": "LyricsBox_ScrollAndDraw",
    "LABEL_F2AE82": "LyricsBox_Epilogue",

    # SongEdit_CheckBounds subroutine (lines 627-731)
    "LABEL_F2AEE6": "SongEdit_OverflowCheck",
    "LABEL_F2AF8C": "SongEdit_SendAndReturnOK",
    "LABEL_F2AF94": "SongEdit_ReturnOverflow",
    "LABEL_F2AF96": "SongEdit_CheckBounds_Epilogue",

    # Lyrics track data read and parse (lines 733-882)
    "LABEL_F2AF99": "LyricsTrack_ReadAndParse",
    "LABEL_F2AFBA": "LyricsTrack_CheckEmpty",
    "LABEL_F2AFE6": "LyricsTrack_HandleNewline",
    "LABEL_F2B002": "LyricsTrack_HandleSingleChar",
    "LABEL_F2B074": "LyricsTrack_HandleNormalChar",
    "LABEL_F2B07E": "LyricsTrack_JmpCheckBounds",
    "LABEL_F2B081": "LyricsTrack_ResetAllBuffers",
    "LABEL_F2B084": "LyricsTrack_ResetBufferLoop",
    "LABEL_F2B0BC": "LyricsTrack_ZeroFillLoop",

    # LyricsFile validate and store (lines 884-964)
    "LABEL_F2B122": "LyricsFile_ValidateAndInsert",
    "LABEL_F2B144": "LyricsFile_CheckFirstByte",
    "LABEL_F2B171": "LyricsFile_CheckLinefeed",
    "LABEL_F2B18D": "LyricsFile_InsertNormalChar",
    "LABEL_F2B205": "LyricsFile_ResetBuffers",

    # LyricsBoxFuncProc (lines 965-1134)
    "LABEL_F2B20A": "LyricsBoxFuncProc_Boundary",
    "LABEL_F2B256": "LyricsBoxFunc_CopyString",
    "LABEL_F2B266": "LyricsBoxFunc_ResetCursors",
    "LABEL_F2B2AA": "LyricsBoxFunc_SendEvent12",
    "LABEL_F2B2B6": "LyricsBoxFunc_SendAndReturn",
    "LABEL_F2B2BD": "LyricsBoxFunc_HandleInput",
    "LABEL_F2B2E7": "LyricsBoxFunc_HandleNewline",
    "LABEL_F2B319": "LyricsBoxFunc_HandleSingleChar",
    "LABEL_F2B38D": "LyricsBoxFunc_HandleNormalChar",
    "LABEL_F2B3AB": "LyricsBoxFunc_SendEventB",
    "LABEL_F2B3AF": "LyricsBoxFunc_ReadTrack",
    "LABEL_F2B3B6": "LyricsBoxFunc_ValidateFile",
    "LABEL_F2B3BD": "LyricsBoxFunc_InheritedProc",
    "LABEL_F2B3C3": "LyricsBoxFunc_Epilogue",
    "LABEL_F2B3C5": "LyricsBoxFunc_End",

    # SongNameBoxProc (lines 1137-1228)
    "LABEL_F2B40C": "SongNameBox_HandleSize",
    "LABEL_F2B414": "SongNameBox_InheritAndDraw",
    "LABEL_F2B439": "SongNameBox_HandleEvent9",
    "LABEL_F2B44A": "SongNameBox_HandleEventF",
    "LABEL_F2B4A3": "SongNameBox_DefaultHandler",
    "LABEL_F2B4AF": "SongNameBox_Epilogue",
    "LABEL_F2B4B4": "SongNameBox_End",

    # ComporserNameBoxProc (lines 1231-1322)
    "LABEL_F2B4FB": "ComposerBox_HandleSize",
    "LABEL_F2B503": "ComposerBox_InheritAndDraw",
    "LABEL_F2B528": "ComposerBox_HandleEvent9",
    "LABEL_F2B539": "ComposerBox_HandleEventE",
    "LABEL_F2B592": "ComposerBox_DefaultHandler",
    "LABEL_F2B59E": "ComposerBox_Epilogue",
    "LABEL_F2B5A3": "ComposerBox_End",

    # MeasureBoxProc (lines 1325-1419)
    "LABEL_F2B5CE": "MeasureBox_HandleFocusGained",
    "LABEL_F2B5EB": "MeasureBox_HandleEventF",
    "LABEL_F2B660": "MeasureBox_ZeroFillLoop",
    "LABEL_F2B693": "MeasureBox_ReturnZero",
    "LABEL_F2B695": "MeasureBox_Epilogue",

    # MeasureBoxFunc (lines 1421-1447)
    "LABEL_F2B6B1": "MeasureBoxFunc_DrawMeasure",
    "LABEL_F2B6CA": "MeasureBoxFunc_LoadAddr",
    "LABEL_F2B6CE": "MeasureBoxFunc_Epilogue",
    "LABEL_F2B6D0": "MeasureBoxFunc_End",

    # AcDiskFileNameBoxProc (lines 1450-1518)
    "LABEL_F2B708": "AcDiskFileName_HandleEvent2",
    "LABEL_F2B70C": "AcDiskFileName_HandleEvent1",
    "LABEL_F2B70E": "AcDiskFileName_CallInherited",
    "LABEL_F2B72C": "AcDiskFileName_HandleEventF",
    "LABEL_F2B76E": "AcDiskFileName_ReturnZero",
    "LABEL_F2B770": "AcDiskFileName_Epilogue",
    "LABEL_F2B777": "AcDiskFileName_End",

    # AcSmfFileNameBoxProc (lines 1521-1589)
    "LABEL_F2B7AF": "AcSmfFileName_HandleEvent2",
    "LABEL_F2B7B3": "AcSmfFileName_HandleEvent1",
    "LABEL_F2B7B5": "AcSmfFileName_CallInherited",
    "LABEL_F2B7D3": "AcSmfFileName_HandleEventF",
    "LABEL_F2B815": "AcSmfFileName_ReturnZero",
    "LABEL_F2B817": "AcSmfFileName_Epilogue",
    "LABEL_F2B81E": "AcSmfFileName_End",

    # AcSmfSongNameBoxProc (lines 1592-1660)
    "LABEL_F2B856": "AcSmfSongName_HandleEvent2",
    "LABEL_F2B85A": "AcSmfSongName_HandleEvent1",
    "LABEL_F2B85C": "AcSmfSongName_CallInherited",
    "LABEL_F2B862": "AcSmfSongName_HandleFocusGained",
    "LABEL_F2B87A": "AcSmfSongName_HandleEventF",
    "LABEL_F2B8BC": "AcSmfSongName_ReturnZero",
    "LABEL_F2B8BE": "AcSmfSongName_Epilogue",
    "LABEL_F2B8C5": "AcSmfSongName_End",

    # AcDocSongNameBoxProc (lines 1663-1731)
    "LABEL_F2B8FD": "AcDocSongName_HandleEvent2",
    "LABEL_F2B901": "AcDocSongName_HandleEvent1",
    "LABEL_F2B903": "AcDocSongName_CallInherited",
    "LABEL_F2B909": "AcDocSongName_HandleFocusGained",
    "LABEL_F2B921": "AcDocSongName_HandleEventF",
    "LABEL_F2B963": "AcDocSongName_ReturnZero",
    "LABEL_F2B965": "AcDocSongName_Epilogue",
    "LABEL_F2B96C": "AcDocSongName_End",

    # AcDocFileNoBoxProc (lines 1734-1802)
    "LABEL_F2B9A4": "AcDocFileNo_HandleEvent2",
    "LABEL_F2B9A8": "AcDocFileNo_HandleEvent1",
    "LABEL_F2B9AA": "AcDocFileNo_CallInherited",
    "LABEL_F2B9B0": "AcDocFileNo_HandleFocusGained",
    "LABEL_F2B9C8": "AcDocFileNo_HandleEventF",
    "LABEL_F2BA0A": "AcDocFileNo_ReturnZero",
    "LABEL_F2BA0C": "AcDocFileNo_Epilogue",
    "LABEL_F2BA13": "AcDocFileNo_End",

    # AcPDSongNameBoxProc (lines 1805-1873)
    "LABEL_F2BA4B": "AcPDSongName_HandleEvent2",
    "LABEL_F2BA4F": "AcPDSongName_HandleEvent1",
    "LABEL_F2BA51": "AcPDSongName_CallInherited",
    "LABEL_F2BA57": "AcPDSongName_HandleFocusGained",
    "LABEL_F2BA6F": "AcPDSongName_HandleEventF",
    "LABEL_F2BAB1": "AcPDSongName_ReturnZero",
    "LABEL_F2BAB3": "AcPDSongName_Epilogue",
    "LABEL_F2BABA": "AcPDSongName_End",

    # AcPDFileNoBoxProc (lines 1876-1944)
    "LABEL_F2BAF2": "AcPDFileNo_HandleEvent2",
    "LABEL_F2BAF6": "AcPDFileNo_HandleEvent1",
    "LABEL_F2BAF8": "AcPDFileNo_CallInherited",
    "LABEL_F2BAFE": "AcPDFileNo_HandleFocusGained",
    "LABEL_F2BB16": "AcPDFileNo_HandleEventF",
    "LABEL_F2BB58": "AcPDFileNo_ReturnZero",
    "LABEL_F2BB5A": "AcPDFileNo_Epilogue",

    # IvNamingExitProc (lines 1946-2008)
    "LABEL_F2BB86": "IvNamingExit_CopyString",
    "LABEL_F2BB9A": "IvNamingExit_ReturnZero",
    "LABEL_F2BBCA": "IvNamingExit_CheckTitleA7",
    "LABEL_F2BBE5": "IvNamingExit_PostTitleEvent",
    "LABEL_F2BBF1": "IvNamingExit_CallInherited",
    "LABEL_F2BBF5": "IvNamingExit_Epilogue",
    "LABEL_F2BBF9": "IvNamingExit_ScreenData",
}

def main():
    files_to_update = [
        'maincpu/sequencer/sequencer_ui.s',
        # External references
        'maincpu/kn5000_v10_program.s',  # LABEL_F2BBF9
    ]

    for filepath in files_to_update:
        full_path = os.path.join('/home/fsanches/compartilhado/kn5000-roms-disasm', filepath)
        if not os.path.exists(full_path):
            continue
        with open(full_path, 'rb') as f:
            data = f.read()

        original = data
        for old, new in RENAMES.items():
            data = data.replace(old.encode('ascii'), new.encode('ascii'))

        if data != original:
            with open(full_path, 'wb') as f:
                f.write(data)
            count = sum(1 for old in RENAMES if old.encode('ascii') in original)
            print(f"  Updated {filepath}: {count} label(s) renamed")

    print(f"\nTotal renames: {len(RENAMES)}")

if __name__ == '__main__':
    main()
