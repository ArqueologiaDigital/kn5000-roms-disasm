/* sepaout_config_link.ld -- Linker script for sepaout_config.c
 *
 * Provides absolute symbol addresses for extern references used in the
 * SepaOut configuration data's function pointer tables.
 *
 * Addresses obtained from: llvm-nm --no-sort rebuilt_ROMs/kn5000_v10_program.llvm.elf
  * v7 addresses where v7's own bytes agree:
 * scripts/generators/generate_v7_naka_link_scripts.py
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Display/UI handler pointers */
Display_InitGraphicsAndScreen  = 0x00F22238;
Display_CallConditionalCompare = 0x00F2225E;
Display_CallPollAudioUpdate    = 0x00F2226B;
SqTrSel_CaseA                 = 0x00F22278;

/* Language check string pointers */
PartSelLangCheck      = 0x00F2A902;
AfterLangCheck        = 0x00F2A913;
TrAsPreLangCheck      = 0x00F2A924;
AtentionLangCheck     = 0x00F2A935;
AreYouSureLangCheck   = 0x00F2A946;
GmOnSureLangCheck     = 0x00F2A957;
GmOffSureLangCheck    = 0x00F2A968;
TrAsSureLangCheck     = 0x00F2A979;

/* Sequencer/song function handlers */
SqTrAsPsSongFunc      = 0x00F2CC5E;
DemoSongSelFunc       = 0x00F2CBEC;
SmfMuteChSelFunc      = 0x00F2CBFD;
SqAftSetFunc          = 0x00F2CCBE;
MuteChSetFunc         = 0x00F2CD23;
SMFMuteOnOffFunc      = 0x00F2CE0C;
Rt1MuteFunc           = 0x00F2CE91;
Rt2MuteFunc           = 0x00F2CED0;
DocOrchMuteFunc       = 0x00F2CF0F;
PdOrchMuteFunc        = 0x00F2CF4F;
SeqNamingCheck        = 0x00F2CFB9;
SeqNameOKFunc         = 0x00F2CF8F;
TrAsGridCheck         = 0x00F2C44D;
DemoMedDspCheck       = 0x00F2D088;
DPPlayDspCheck        = 0x00F2D100;
DPPauseDspCheck       = 0x00F2D178;

/* UI box region boundary/end labels */
ComposerBox_End               = 0x00F2B579;
MeasureBoxFunc                = 0x00F2B670;
MeasureBoxFunc_End            = 0x00F2B6A6;
AcDiskFileName_End            = 0x00F2B74D;
AcDocSongName_End             = 0x00F2B942;
AcPDSongName_End              = 0x00F2BA90;
AcSmfFileName_End             = 0x00F2B7F4;
AcSmfSongName_End             = 0x00F2B89B;
AcDocFileNo_End               = 0x00F2B9E9;
IvNamingExitProc              = 0x00F2BB37;
TrAsGridChk_End               = 0x00F2C973;
AcDemoSong_End                = 0x00F2CAD1;
AcCurSong_End                 = 0x00F2CB45;
VoiceConfig_End               = 0x00F2CA32;
TrAsGrid_BoxProc              = 0x00F2BEF4;
SqAftSetFunc_End              = 0x00F2CDB0;
Audio_ExternalCallback_End    = 0x00F2AA08;
LyricsBoxFuncProc_Boundary    = 0x00F2B1E0;
LyricsBoxFunc_End             = 0x00F2B39B;
SongNameBox_End               = 0x00F2B48A;
SeqNameOK_End                 = 0x00F2D012;
DemoMedDsp_End                = 0x00F2D1F0;

/* Debug string pointer */
DbgStr_PartSelLangCheck       = 0x00E206FC;
