/* sepaout_config_link.ld -- Linker script for sepaout_config.c
 *
 * Provides absolute symbol addresses for extern references used in the
 * SepaOut configuration data's function pointer tables.
 *
 * Addresses obtained from: llvm-nm --no-sort rebuilt_ROMs/kn5000_v10_program.llvm.elf
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Display/UI handler pointers */
Display_InitGraphicsAndScreen  = 0x00F22262;
Display_CallConditionalCompare = 0x00F22288;
Display_CallPollAudioUpdate    = 0x00F22295;
SqTrSel_CaseA                 = 0x00F222A2;

/* Language check string pointers */
PartSelLangCheck      = 0x00F2A92C;
AfterLangCheck        = 0x00F2A93D;
TrAsPreLangCheck      = 0x00F2A94E;
AtentionLangCheck     = 0x00F2A95F;
AreYouSureLangCheck   = 0x00F2A970;
GmOnSureLangCheck     = 0x00F2A981;
GmOffSureLangCheck    = 0x00F2A992;
TrAsSureLangCheck     = 0x00F2A9A3;

/* Sequencer/song function handlers */
SqTrAsPsSongFunc      = 0x00F2CC88;
DemoSongSelFunc       = 0x00F2CC16;
SmfMuteChSelFunc      = 0x00F2CC27;
SqAftSetFunc          = 0x00F2CCE8;
MuteChSetFunc         = 0x00F2CD4D;
SMFMuteOnOffFunc      = 0x00F2CE36;
Rt1MuteFunc           = 0x00F2CEBB;
Rt2MuteFunc           = 0x00F2CEFA;
DocOrchMuteFunc       = 0x00F2CF39;
PdOrchMuteFunc        = 0x00F2CF79;
SeqNamingCheck        = 0x00F2CFE3;
SeqNameOKFunc         = 0x00F2CFB9;
TrAsGridCheck         = 0x00F2C477;
DemoMedDspCheck       = 0x00F2D0B2;
DPPlayDspCheck        = 0x00F2D12A;
DPPauseDspCheck       = 0x00F2D1A2;

/* UI box region boundary/end labels */
ComposerBox_End               = 0x00F2B5A3;
MeasureBoxFunc                = 0x00F2B69A;
MeasureBoxFunc_End            = 0x00F2B6D0;
AcDiskFileName_End            = 0x00F2B777;
AcDocSongName_End             = 0x00F2B96C;
AcPDSongName_End              = 0x00F2BABA;
AcSmfFileName_End             = 0x00F2B81E;
AcSmfSongName_End             = 0x00F2B8C5;
AcDocFileNo_End               = 0x00F2BA13;
IvNamingExitProc              = 0x00F2BB61;
TrAsGridChk_End               = 0x00F2C99D;
AcDemoSong_End                = 0x00F2CAFB;
AcCurSong_End                 = 0x00F2CB6F;
VoiceConfig_End               = 0x00F2CA5C;
TrAsGrid_BoxProc              = 0x00F2BF1E;
SqAftSetFunc_End              = 0x00F2CDDA;
Audio_ExternalCallback_End    = 0x00F2AA32;
LyricsBoxFuncProc_Boundary    = 0x00F2B20A;
LyricsBoxFunc_End             = 0x00F2B3C5;
SongNameBox_End               = 0x00F2B4B4;
SeqNameOK_End                 = 0x00F2D03C;
DemoMedDsp_End                = 0x00F2D21A;

/* Debug string pointer */
DbgStr_PartSelLangCheck       = 0x00E206FC;
