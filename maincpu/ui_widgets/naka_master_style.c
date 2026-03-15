/* naka_master_style.c — Master Style Grid screen data (28 widgets, 944 bytes)
 * ROM address range: 0xED27E8-0xED2B98
 *
 * 28 compact dispatch widgets for the Master Style screen layout.
 * Widgets w0-w17 reference external NakaInst/NakaDesc string blocks.
 * Widgets w18-w27 have inline trailing strings (inst code + name pairs).
 */

#include "naka_types.h"

/* External symbol declarations (resolved by linker) */
extern const char AcBkNoBox_Boundary;
extern const char AcChordBoxProc_Entry;
extern const char AcMstStyleAlp_Boundary;
extern const char AcPmBkNoBox_Boundary;
extern const char AcTranspose_ParamData_End;
extern const char FSWAssGrid_Boundary;
extern const char GmOnOff_Boundary;
extern const char IsHalfRangeAbove_End;
extern const char IvPmemWindow_Boundary;
extern const char IvWindowPgCtl_Boundary;
extern const char MainMssSetUp_End;
extern const char MsaMode_Boundary;
extern const char MssName_Boundary;
extern const char MstGrid2_Boundary;
extern const char MstSong1Grid_Boundary;
extern const char MstSong2Grid_Boundary;
extern const char MstStyle1Grid_Boundary;
extern const char MstStyle1SubGrid_Boundary;
extern const char MstStyle2Grid_Boundary;
extern const char NakaDesc_AcBkNoBox;
extern const char NakaDesc_AcChordBox;
extern const char NakaDesc_AcDispTimeSetGridBox;
extern const char NakaDesc_AcFSWAssGridBox;
extern const char NakaDesc_AcFreeSplitBox;
extern const char NakaDesc_AcPmBkEditBox;
extern const char NakaDesc_AcPmBkNoBox;
extern const char NakaDesc_AcPmExpFilterGridBox;
extern const char NakaDesc_AcTchSensGridBox;
extern const char NakaDesc_AcTransposeBox;
extern const char NakaDesc_IvMstStyleWindowPgCtl;
extern const char NakaDesc_IvPmemWindowPageCtl;
extern const char NakaDesc_IvWindowPageControl;
extern const char NakaDesc_MsaModeScreen;
extern const char NakaDesc_PmBankScreen;
extern const char NakaDesc_PmemModeBox;
extern const char NakaDesc_RVariScreen;
extern const char NakaDesc_VariScreen;
extern const char NakaInst_AcBkNoBox;
extern const char NakaInst_AcChordBox;
extern const char NakaInst_AcDispTimeSetGridBox;
extern const char NakaInst_AcFSWAssGridBox;
extern const char NakaInst_AcFreeSplitBox;
extern const char NakaInst_AcMstSugAlpGridBox;
extern const char NakaInst_AcPmBkEditBox;
extern const char NakaInst_AcPmBkNoBox;
extern const char NakaInst_AcPmExpFilterGridBox;
extern const char NakaInst_AcTchSensGridBox;
extern const char NakaInst_AcTransposeBox;
extern const char NakaInst_IvMstStyleWindowPgCtl;
extern const char NakaInst_IvPmemWindowPageCtl;
extern const char NakaInst_IvWindowPageControl;
extern const char NakaInst_MsaModeScreen;
extern const char NakaInst_PmBankScreen;
extern const char NakaInst_PmemModeBox;
extern const char NakaInst_RVariScreen;
extern const char NakaInst_VariScreen;
extern const char NakaParam_AcBkNoBox;
extern const char NakaParam_AcChordBox;
extern const char NakaParam_AcFreeSplitBox;
extern const char NakaParam_AcMstSong2GridBox;
extern const char NakaParam_AcMstStyle1SubGridBox;
extern const char NakaParam_AcMstStyleAlpGridBox;
extern const char NakaParam_AcPmBkNoBox;
extern const char NakaParam_AcTchSensGridBox;
extern const char NakaParam_IvMstStyleWindowPgCtl;
extern const char NakaParam_IvPmemWindowPageCtl;
extern const char NakaParam_PmBankScreen;
extern const char NakaParam_RVariScreen;
extern const char NakaParam_VariScreen;
extern const char NormScreen_Boundary;
extern const char ParamStr_Table_09;
extern const char ParamStr_Table_10;
extern const char ParamStr_Table_11;
extern const char ParamStr_Table_12;
extern const char ParamStr_Table_13;
extern const char ParamStr_Table_14;
extern const char ParamStr_Table_15;
extern const char ParamStr_Table_16;
extern const char ParamStr_Table_17;
extern const char ParamStr_Table_18;
extern const char ParamStr_Table_20;
extern const char ParamStr_Table_21;
extern const char ParamStr_Table_22;
extern const char ParamStr_Table_23;
extern const char ParamStr_Table_24;
extern const char PmBank_Boundary;
extern const char PmExpFilterCheck_Boundary;
extern const char PmemExpLng_Boundary;
extern const char PmemMode_Boundary;
extern const char PmemPageCtl_Boundary;
extern const char RVari_UpdateNotify_End;
extern const char TchSensGrid_Boundary;

#define SELF(field) \
    NAKA_SELF(&master_style_data, master_style_t, field)

typedef struct __attribute__((packed)) {
    naka_dispatch_t w[28];     /* 28 × 24 = 672 bytes */
    uint8_t padding[20];       /* zero padding */
    char w27_inst[4];
    char w27_name[14];
    char w26_inst[6];
    char w26_name[16];
    char w25_inst[12];
    char w25_name[18];
    char w24_inst[8];
    char w24_name[18];
    char w23_inst[12];
    char w23_name[20];
    char w22_inst[8];
    char w22_name[22];
    char w21_inst[8];
    char w21_name[20];
    char w20_inst[10];
    char w20_name[22];
    char w19_inst[12];
    char w19_name[20];
    char w18_inst[2];
} master_style_t;

_Static_assert(sizeof(master_style_t) == 944, "master_style_t must be 944 bytes");

const master_style_t master_style_data = {
    .w = {
        /* w0 */ {
            .header   = NAKA_HDR(0x34),
            .field_04 = 0x002A,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_VariScreen),
            .inst_ptr  = NAKA_ADDR(NakaDesc_VariScreen),
            .link_ptr  = NAKA_ADDR(NakaParam_VariScreen),
            .proc_addr = NAKA_ADDR(GmOnOff_Boundary),
        },
        /* w1 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0044,
            .field_06 = 0x0022,
            .name_ptr  = NAKA_ADDR(NakaInst_RVariScreen),
            .inst_ptr  = NAKA_ADDR(NakaDesc_RVariScreen),
            .link_ptr  = NAKA_ADDR(NakaParam_RVariScreen),
            .proc_addr = NAKA_ADDR(IsHalfRangeAbove_End),
        },
        /* w2 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0044,
            .field_06 = 0x0022,
            .name_ptr  = NAKA_ADDR(NakaInst_AcTransposeBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcTransposeBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_09),
            .proc_addr = NAKA_ADDR(AcTranspose_ParamData_End),
        },
        /* w3 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_AcChordBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcChordBox),
            .link_ptr  = NAKA_ADDR(NakaParam_AcChordBox),
            .proc_addr = NAKA_ADDR(AcChordBoxProc_Entry),
        },
        /* w4 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_AcFreeSplitBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcFreeSplitBox),
            .link_ptr  = NAKA_ADDR(NakaParam_AcFreeSplitBox),
            .proc_addr = NAKA_ADDR(MainMssSetUp_End),
        },
        /* w5 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_AcBkNoBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcBkNoBox),
            .link_ptr  = NAKA_ADDR(NakaParam_AcBkNoBox),
            .proc_addr = NAKA_ADDR(AcPmBkNoBox_Boundary),
        },
        /* w6 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_AcPmBkNoBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcPmBkNoBox),
            .link_ptr  = NAKA_ADDR(NakaParam_AcPmBkNoBox),
            .proc_addr = NAKA_ADDR(MssName_Boundary),
        },
        /* w7 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaInst_PmBankScreen),
            .inst_ptr  = NAKA_ADDR(NakaDesc_PmBankScreen),
            .link_ptr  = NAKA_ADDR(NakaParam_PmBankScreen),
            .proc_addr = NAKA_ADDR(RVari_UpdateNotify_End),
        },
        /* w8 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0038,
            .field_06 = 0x0016,
            .name_ptr  = NAKA_ADDR(NakaInst_AcPmBkEditBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcPmBkEditBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_10),
            .proc_addr = NAKA_ADDR(PmemMode_Boundary),
        },
        /* w9 */ {
            .header   = NAKA_HDR(0x15),
            .field_04 = 0x003A,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaInst_MsaModeScreen),
            .inst_ptr  = NAKA_ADDR(NakaDesc_MsaModeScreen),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_11),
            .proc_addr = NAKA_ADDR(AcBkNoBox_Boundary),
        },
        /* w10 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0034,
            .field_06 = 0x0012,
            .name_ptr  = NAKA_ADDR(NakaInst_PmemModeBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_PmemModeBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_12),
            .proc_addr = NAKA_ADDR(MsaMode_Boundary),
        },
        /* w11 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x002C,
            .field_06 = 0x0012,
            .name_ptr  = NAKA_ADDR(NakaInst_IvWindowPageControl),
            .inst_ptr  = NAKA_ADDR(NakaDesc_IvWindowPageControl),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_13),
            .proc_addr = NAKA_ADDR(NormScreen_Boundary),
        },
        /* w12 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaInst_IvPmemWindowPageCtl),
            .inst_ptr  = NAKA_ADDR(NakaDesc_IvPmemWindowPageCtl),
            .link_ptr  = NAKA_ADDR(NakaParam_IvPmemWindowPageCtl),
            .proc_addr = NAKA_ADDR(IvPmemWindow_Boundary),
        },
        /* w13 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaInst_IvMstStyleWindowPgCtl),
            .inst_ptr  = NAKA_ADDR(NakaDesc_IvMstStyleWindowPgCtl),
            .link_ptr  = NAKA_ADDR(NakaParam_IvMstStyleWindowPgCtl),
            .proc_addr = NAKA_ADDR(MstSong2Grid_Boundary),
        },
        /* w14 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaInst_AcTchSensGridBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcTchSensGridBox),
            .link_ptr  = NAKA_ADDR(NakaParam_AcTchSensGridBox),
            .proc_addr = NAKA_ADDR(TchSensGrid_Boundary),
        },
        /* w15 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x004A,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaInst_AcFSWAssGridBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcFSWAssGridBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_14),
            .proc_addr = NAKA_ADDR(FSWAssGrid_Boundary),
        },
        /* w16 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x004A,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaInst_AcPmExpFilterGridBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcPmExpFilterGridBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_15),
            .proc_addr = NAKA_ADDR(PmemPageCtl_Boundary),
        },
        /* w17 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x004A,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaInst_AcDispTimeSetGridBox),
            .inst_ptr  = NAKA_ADDR(NakaDesc_AcDispTimeSetGridBox),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_16),
            .proc_addr = NAKA_ADDR(PmExpFilterCheck_Boundary),
        },
        /* w18 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x004A,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaInst_AcMstSugAlpGridBox),
            .inst_ptr  = SELF(w18_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_17),
            .proc_addr = NAKA_ADDR(PmemExpLng_Boundary),
        },
        /* w19 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0066,
            .field_06 = 0x0028,
            .name_ptr  = SELF(w19_name),
            .inst_ptr  = SELF(w19_inst),
            .link_ptr  = NAKA_ADDR(NakaParam_AcMstStyleAlpGridBox),
            .proc_addr = NAKA_ADDR(AcMstStyleAlp_Boundary),
        },
        /* w20 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x005E,
            .field_06 = 0x0020,
            .name_ptr  = SELF(w20_name),
            .inst_ptr  = SELF(w20_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_18),
            .proc_addr = NAKA_ADDR(MstStyle1Grid_Boundary),
        },
        /* w21 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0056,
            .field_06 = 0x0018,
            .name_ptr  = SELF(w21_name),
            .inst_ptr  = SELF(w21_inst),
            .link_ptr  = NAKA_ADDR(NakaParam_AcMstStyle1SubGridBox),
            .proc_addr = NAKA_ADDR(MstStyle1SubGrid_Boundary),
        },
        /* w22 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0056,
            .field_06 = 0x0018,
            .name_ptr  = SELF(w22_name),
            .inst_ptr  = SELF(w22_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_20),
            .proc_addr = NAKA_ADDR(MstStyle2Grid_Boundary),
        },
        /* w23 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0066,
            .field_06 = 0x0028,
            .name_ptr  = SELF(w23_name),
            .inst_ptr  = SELF(w23_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_21),
            .proc_addr = NAKA_ADDR(MstGrid2_Boundary),
        },
        /* w24 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0056,
            .field_06 = 0x0018,
            .name_ptr  = SELF(w24_name),
            .inst_ptr  = SELF(w24_inst),
            .link_ptr  = NAKA_ADDR(NakaParam_AcMstSong2GridBox),
            .proc_addr = NAKA_ADDR(MstSong1Grid_Boundary),
        },
        /* w25 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x0066,
            .field_06 = 0x0028,
            .name_ptr  = SELF(w25_name),
            .inst_ptr  = SELF(w25_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_22),
            .proc_addr = NAKA_ADDR(PmBank_Boundary),
        },
        /* w26 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0034,
            .field_06 = 0x0012,
            .name_ptr  = SELF(w26_name),
            .inst_ptr  = SELF(w26_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_23),
            .proc_addr = NAKA_ADDR(IvWindowPgCtl_Boundary),
        },
        /* w27 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001C,
            .field_06 = 0x0006,
            .name_ptr  = SELF(w27_name),
            .inst_ptr  = SELF(w27_inst),
            .link_ptr  = NAKA_ADDR(ParamStr_Table_24),
            .proc_addr = 0,
        },
    },
    .padding = {0},
    .w27_inst = ALIGNED_STRING("At"),
    .w27_name = ALIGNED_STRING("IvPageOverWr"),
    .w26_inst = "kc^nn",
    .w26_name = ALIGNED_STRING("SineWaveScreen"),
    .w25_inst = ALIGNED_STRING("XXjnnnnnnn"),
    .w25_name = "AcMstSong2GridBox",
    .w24_inst = ALIGNED_STRING("XXjnnn"),
    .w24_name = "AcMstSong1GridBox",
    .w23_inst = ALIGNED_STRING("XXjnnnnnnn"),
    .w23_name = ALIGNED_STRING("AcMstStyle2GridBox"),
    .w22_inst = ALIGNED_STRING("XXjnnn"),
    .w22_name = "AcMstStyle1SubGridBox",
    .w21_inst = ALIGNED_STRING("XXjnnn"),
    .w21_name = ALIGNED_STRING("AcMstStyle1GridBox"),
    .w20_inst = ALIGNED_STRING("XXjnnnnn"),
    .w20_name = ALIGNED_STRING("AcMstStyleAlpGridBox"),
    .w19_inst = ALIGNED_STRING("XXjnnnnnnn"),
    .w19_name = ALIGNED_STRING("AcMstSugAlpGridBox"),
    .w18_inst = "XX",
};
