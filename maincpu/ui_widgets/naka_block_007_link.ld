/* naka_block_007_link.ld — Linker script for naka_block_007.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Linked widget descriptors */
NakaDesc_OnOffStyle_Table           = 0x00E55790;
NakaDesc_PageGridBox1_Table         = 0x00E5597E;
NakaDesc_PmanOnOff1_Table           = 0x00E557C2;
NakaDesc_PmanOnOff2_Table           = 0x00E55806;

/* Proc handler functions */
AcCtlMsgGridBoxProc                 = 0x00F79ADC;
AcFadeSetGridBoxProc                = 0x00F75229;
AcGMOnOffBoxProc                    = 0x00F74710;
AcInOutGridBoxProc                  = 0x00F7575A;
AcLswFuncBoxProc                    = 0x00F74D8C;
AcLswFuncEditBoxProc                = 0x00F74FDF;
AcMidiPartGridBoxProc               = 0x00F7A1F4;
AcParaLoadOptGridBoxProc            = 0x00F76C5E;
AcPcgOutGridBoxProc                 = 0x00F773DA;
AcPmemOutLGridBoxProc               = 0x00F78329;
AcPmemOutRGridBoxProc               = 0x00F7867C;
AcVocalGridBoxProc                  = 0x00F73642;

/* NakaName/NakaCode/NakaLink string and data references */
NakaLink_E557BC                               = 0x00E557BC;
NakaLink_E5584A                               = 0x00E5584A;
NakaLink_E55876                               = 0x00E55876;
NakaLink_E558A2                               = 0x00E558A2;
NakaLink_E558CE                               = 0x00E558CE;
NakaLink_E558FA                               = 0x00E558FA;
NakaLink_E55926                               = 0x00E55926;
NakaLink_E55952                               = 0x00E55952;
NakaLink_E559B4                               = 0x00E559B4;
NakaCode_XXjn_5B82                            = 0x00E55B82;
NakaName_AcMidiPartGridBox                    = 0x00E55B88;
NakaCode_XXjn                                 = 0x00E55B9A;
NakaName_AcCtlMsgGridBox                      = 0x00E55BA0;
NakaCode_XXj_5BB0                             = 0x00E55BB0;
NakaName_AcPmemOutRGridBox                    = 0x00E55BB4;
NakaCode_XXj_5BC6                             = 0x00E55BC6;
NakaName_AcPmemOutLGridBox                    = 0x00E55BCA;
NakaCode_XXj_5BDC                             = 0x00E55BDC;
NakaName_AcPcgOutGridBox                      = 0x00E55BE0;
NakaCode_XXj_5BF0                             = 0x00E55BF0;
NakaName_AcParaLoadOptGridBox                 = 0x00E55BF4;
NakaCode_XXj_5C0A                             = 0x00E55C0A;
NakaName_AcInOutGridBox                       = 0x00E55C0E;
NakaCode_XXj_5C1E                             = 0x00E55C1E;
NakaName_AcVocalGridBox                       = 0x00E55C22;
NakaCode_XXj                                  = 0x00E55C32;
NakaName_AcFadeSetGridBox                     = 0x00E55C36;
NakaCode_nXXFB_5C48                           = 0x00E55C48;
NakaName_AcLswFuncBox                         = 0x00E55C4E;
NakaCode_nXXFB                                = 0x00E55C5C;
NakaName_AcLswFuncEditBox                     = 0x00E55C62;
NakaCode_E55C74                               = 0x00E55C74;
NakaName_AcGMOnOffBox                         = 0x00E55C76;
NakaCode_fjXn                                 = 0x00E55C84;
NakaName_AcSendEditSw                         = 0x00E55C8A;
