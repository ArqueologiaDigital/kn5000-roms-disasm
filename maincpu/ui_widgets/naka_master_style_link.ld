/* naka_master_style_link.ld — Linker script for naka_master_style.c */

ENTRY(0)

SECTIONS {
    .text 0xED27E8 : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Linked widget descriptors */
NakaParam_VariScreen                     = 0x00ED20C6;
NakaParam_RVariScreen                    = 0x00ED20CC;
ParamStr_Table_09                        = 0x00ED2138;
NakaParam_AcChordBox                     = 0x00ED21A4;
NakaParam_AcFreeSplitBox                 = 0x00ED21AA;
NakaParam_AcBkNoBox                      = 0x00ED21B0;
NakaParam_AcPmBkNoBox                    = 0x00ED21B6;
NakaParam_PmBankScreen                   = 0x00ED21BC;
ParamStr_Table_10                        = 0x00ED21C2;
ParamStr_Table_11                        = 0x00ED220C;
ParamStr_Table_12                        = 0x00ED2226;
ParamStr_Table_13                        = 0x00ED226E;
NakaParam_IvPmemWindowPageCtl            = 0x00ED22B6;
NakaParam_IvMstStyleWindowPgCtl          = 0x00ED22C6;
NakaParam_AcTchSensGridBox               = 0x00ED22D6;
ParamStr_Table_14                        = 0x00ED22E6;
ParamStr_Table_15                        = 0x00ED2312;
ParamStr_Table_16                        = 0x00ED233E;
ParamStr_Table_17                        = 0x00ED236A;
NakaParam_AcMstStyleAlpGridBox           = 0x00ED2396;
ParamStr_Table_18                        = 0x00ED2438;
NakaParam_AcMstStyle1SubGridBox          = 0x00ED24B4;
ParamStr_Table_20                        = 0x00ED2520;
ParamStr_Table_21                        = 0x00ED2596;
NakaParam_AcMstSong2GridBox              = 0x00ED265E;
ParamStr_Table_22                        = 0x00ED26C8;
ParamStr_Table_23                        = 0x00ED2788;
ParamStr_Table_24                        = 0x00ED27C8;

/* NakaInst/NakaDesc string blocks */
NakaInst_AcMstSugAlpGridBox              = 0x00ED2B9A;
NakaDesc_AcDispTimeSetGridBox            = 0x00ED2BB0;
NakaInst_AcDispTimeSetGridBox            = 0x00ED2BB4;
NakaDesc_AcPmExpFilterGridBox            = 0x00ED2BCA;
NakaInst_AcPmExpFilterGridBox            = 0x00ED2BCE;
NakaDesc_AcFSWAssGridBox                 = 0x00ED2BDE;
NakaInst_AcFSWAssGridBox                 = 0x00ED2BE2;
NakaDesc_AcTchSensGridBox                = 0x00ED2BF4;
NakaInst_AcTchSensGridBox                = 0x00ED2BF6;
NakaDesc_IvMstStyleWindowPgCtl           = 0x00ED2C0C;
NakaInst_IvMstStyleWindowPgCtl           = 0x00ED2C0E;
NakaDesc_IvPmemWindowPageCtl             = 0x00ED2C22;
NakaInst_IvPmemWindowPageCtl             = 0x00ED2C24;
NakaDesc_IvWindowPageControl             = 0x00ED2C38;
NakaInst_IvWindowPageControl             = 0x00ED2C3E;
NakaDesc_PmemModeBox                     = 0x00ED2C4A;
NakaInst_PmemModeBox                     = 0x00ED2C50;
NakaDesc_MsaModeScreen                   = 0x00ED2C5E;
NakaInst_MsaModeScreen                   = 0x00ED2C62;
NakaDesc_AcPmBkEditBox                   = 0x00ED2C70;
NakaInst_AcPmBkEditBox                   = 0x00ED2C78;
NakaDesc_PmBankScreen                    = 0x00ED2C86;
NakaInst_PmBankScreen                    = 0x00ED2C88;
NakaDesc_AcPmBkNoBox                     = 0x00ED2C92;
NakaInst_AcPmBkNoBox                     = 0x00ED2C94;
NakaDesc_AcBkNoBox                       = 0x00ED2C9C;
NakaInst_AcBkNoBox                       = 0x00ED2C9E;
NakaDesc_AcFreeSplitBox                  = 0x00ED2CAC;
NakaInst_AcFreeSplitBox                  = 0x00ED2CAE;
NakaDesc_AcChordBox                      = 0x00ED2CB8;
NakaInst_AcChordBox                      = 0x00ED2CBA;
NakaDesc_AcTransposeBox                  = 0x00ED2CC8;
NakaInst_AcTransposeBox                  = 0x00ED2CD2;
NakaDesc_RVariScreen                     = 0x00ED2CDE;
NakaInst_RVariScreen                     = 0x00ED2CE8;
NakaDesc_VariScreen                      = 0x00ED2CF4;
NakaInst_VariScreen                      = 0x00ED2CF6;

/* Proc handler functions */
PmemExpLng_Boundary                      = 0x00FB8021;
AcMstStyleAlp_Boundary                   = 0x00FB8028;
MstStyle1Grid_Boundary                   = 0x00FB8B0B;
MstStyle1SubGrid_Boundary                = 0x00FB903D;
MstStyle2Grid_Boundary                   = 0x00FB978D;
MstGrid2_Boundary                        = 0x00FBA6E1;
MstSong1Grid_Boundary                    = 0x00FBA6E8;
MstSong2Grid_Boundary                    = 0x00FBA6EF;
TchSensGrid_Boundary                     = 0x00FBA7BB;
FSWAssGrid_Boundary                      = 0x00FBAD9B;
IvPmemWindow_Boundary                    = 0x00FBB9D0;
PmemPageCtl_Boundary                     = 0x00FBBB4C;
PmExpFilterCheck_Boundary                = 0x00FBC412;
NormScreen_Boundary                      = 0x00FBCDF1;
IvWindowPgCtl_Boundary                   = 0x00FBD022;
MssName_Boundary                         = 0x00FBD3EC;
AcPmBkNoBox_Boundary                     = 0x00FBD4EB;
AcBkNoBox_Boundary                       = 0x00FBD5C3;
MsaMode_Boundary                         = 0x00FBD841;
PmemMode_Boundary                        = 0x00FBDB3D;
GmOnOff_Boundary                         = 0x00FBE1E7;
IsHalfRangeAbove_End                     = 0x00FBF518;
RVari_UpdateNotify_End                   = 0x00FC1A22;
PmBank_Boundary                          = 0x00FC1F26;
MainMssSetUp_End                         = 0x00FC2D0B;
AcTranspose_ParamData_End                = 0x00FC2EC3;
AcChordBoxProc_Entry                     = 0x00FC2FBB;
