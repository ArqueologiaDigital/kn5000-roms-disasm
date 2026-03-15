/* naka_block_012.c — Block 012 dispatch widgets (78 widgets, 1942 bytes)
 * ROM address range: 0xEACCDA-0xEAD470
 *
 * 78 compact dispatch widgets for various UI screens.
 * Widgets w0-w74 reference external NakaName/NakaCode strings.
 * Widgets w75-w77 have inline trailing strings.
 */

#include "naka_types.h"

extern const char AcBitEditBoxProc;
extern const char AcFuncEditSwProc;
extern const char AcFuncToggleProc;
extern const char AcGridBoxProc;
extern const char AcIndexEditSwProc;
extern const char AcIndexToggleProc;
extern const char AcLanguageTextProc;
extern const char AcListBoxProc;
extern const char AcMixerVolProc;
extern const char AcNamingWindowProc;
extern const char AcPmemNameProc;
extern const char AcRamBoxProc;
extern const char AcRhythmNameProc;
extern const char AcSoundNameProc;
extern const char AcStrRadioBoxProc;
extern const char AcTitleMenuProc;
extern const char AcTrackSwitchProc;
extern const char AcWindowPageProc;
extern const char BitmapProc;
extern const char BoxProc;
extern const char DbDebugMenuProc;
extern const char DbMemoProc;
extern const char DbMemoryDumpProc;
extern const char EditSwProc;
extern const char FrameProc;
extern const char GroupBoxProc;
extern const char IconProc;
extern const char IvCatchEventProc;
extern const char IvDirmdScreenProc;
extern const char IvExitModeProc;
extern const char IvExitProc;
extern const char IvExitScreenProc;
extern const char IvExitWindowProc;
extern const char IvFixWinProc;
extern const char IvIntCompleteProc;
extern const char IvIntEasySetProc;
extern const char IvIntErrorProc;
extern const char IvIntReminderProc;
extern const char IvIntVariProc;
extern const char IvIntWelcomeProc;
extern const char IvInterruptProc;
extern const char IvMainEditSwProc;
extern const char IvNamingProc;
extern const char IvPageControlProc;
extern const char IvScreenProc;
extern const char IvShowHideProc;
extern const char IvTrackSwitchProc;
extern const char LabelProc;
extern const char LineProc;
extern const char ModeEditProc;
extern const char NakaCode_AA;
extern const char NakaCode_AA_D61E;
extern const char NakaCode_At;
extern const char NakaCode_Grr;
extern const char NakaCode_XG;
extern const char NakaCode_XNb;
extern const char NakaCode_XXj;
extern const char NakaCode_Xb;
extern const char NakaCode_Xb_D6F0;
extern const char NakaCode_Xb_D720;
extern const char NakaCode_Xc;
extern const char NakaCode_Xcd;
extern const char NakaCode_XcdB;
extern const char NakaCode_Xtb;
extern const char NakaCode_akNlX;
extern const char NakaCode_ar;
extern const char NakaCode_cXXme;
extern const char NakaCode_cdB;
extern const char NakaCode_cdBBGnnsss;
extern const char NakaCode_cdBn;
extern const char NakaCode_cdemA;
extern const char NakaCode_ejA;
extern const char NakaCode_fX;
extern const char NakaCode_fX_D700;
extern const char NakaCode_fj;
extern const char NakaCode_fj_D882;
extern const char NakaCode_hA;
extern const char NakaCode_jm;
extern const char NakaCode_jr;
extern const char NakaCode_kalX;
extern const char NakaCode_ue;
extern const char NakaCode_vmnn;
extern const char NakaData_WidgetNames;
extern const char NakaLink_EAC296;
extern const char NakaLink_EAC2A6;
extern const char NakaLink_EAC2C0;
extern const char NakaLink_EAC2D2;
extern const char NakaLink_EAC2E2;
extern const char NakaLink_EAC2FC;
extern const char NakaLink_EAC30C;
extern const char NakaLink_EAC32A;
extern const char NakaLink_EAC366;
extern const char NakaLink_EAC36C;
extern const char NakaLink_EAC388;
extern const char NakaLink_EAC398;
extern const char NakaLink_EAC3A8;
extern const char NakaLink_EAC3CE;
extern const char NakaLink_EAC3DC;
extern const char NakaLink_EAC3EC;
extern const char NakaLink_EAC40A;
extern const char NakaLink_EAC42E;
extern const char NakaLink_EAC454;
extern const char NakaLink_EAC470;
extern const char NakaLink_EAC476;
extern const char NakaLink_EAC492;
extern const char NakaLink_EAC4AC;
extern const char NakaLink_EAC4D2;
extern const char NakaLink_EAC512;
extern const char NakaLink_EAC546;
extern const char NakaLink_EAC57E;
extern const char NakaLink_EAC5B4;
extern const char NakaLink_EAC5BA;
extern const char NakaLink_EAC5C0;
extern const char NakaLink_EAC5DC;
extern const char NakaLink_EAC5F4;
extern const char NakaLink_EAC60C;
extern const char NakaLink_EAC624;
extern const char NakaLink_EAC646;
extern const char NakaLink_EAC66A;
extern const char NakaLink_EAC68E;
extern const char NakaLink_EAC6A8;
extern const char NakaLink_EAC6B8;
extern const char NakaLink_EAC6CA;
extern const char NakaLink_EAC6D0;
extern const char NakaLink_EAC6D6;
extern const char NakaLink_EAC6E6;
extern const char NakaLink_EAC6F8;
extern const char NakaLink_EAC70A;
extern const char NakaLink_EAC710;
extern const char NakaLink_EAC722;
extern const char NakaLink_EAC732;
extern const char NakaLink_EAC74A;
extern const char NakaLink_EAC764;
extern const char NakaLink_EAC7AE;
extern const char NakaLink_EAC7BC;
extern const char NakaLink_EAC7CC;
extern const char NakaLink_EAC80A;
extern const char NakaLink_EAC886;
extern const char NakaLink_EAC8A0;
extern const char NakaLink_EAC8CC;
extern const char NakaLink_EAC8DC;
extern const char NakaLink_EAC90C;
extern const char NakaLink_EAC912;
extern const char NakaLink_EAC918;
extern const char NakaLink_EAC91E;
extern const char NakaLink_EAC924;
extern const char NakaLink_EAC932;
extern const char NakaLink_EAC942;
extern const char NakaLink_EAC948;
extern const char NakaLink_EAC94E;
extern const char NakaLink_EAC954;
extern const char NakaLink_EAC95A;
extern const char NakaLink_EAC960;
extern const char NakaLink_EAC970;
extern const char NakaLink_EAC9A6;
extern const char NakaLink_EAC9B6;
extern const char NakaLink_EAC9BC;
extern const char NakaLink_EAC9C2;
extern const char NakaLink_EAC9D2;
extern const char NakaLink_EAC9D8;
extern const char NakaLink_EAC9DE;
extern const char NakaName_AcBitEditBox;
extern const char NakaName_AcFuncEditSw;
extern const char NakaName_AcFuncToggle;
extern const char NakaName_AcFuncWideES;
extern const char NakaName_AcGridBox;
extern const char NakaName_AcIndexEditSw;
extern const char NakaName_AcIndexToggle;
extern const char NakaName_AcIndexWideES;
extern const char NakaName_AcLanguageText;
extern const char NakaName_AcListBox;
extern const char NakaName_AcMixerVol;
extern const char NakaName_AcModeMenu;
extern const char NakaName_AcNamingWindow;
extern const char NakaName_AcPmemName;
extern const char NakaName_AcRamBox;
extern const char NakaName_AcRhythmName;
extern const char NakaName_AcScreenMenu;
extern const char NakaName_AcSoundName;
extern const char NakaName_AcStrRadioBox;
extern const char NakaName_AcTrackSwitch;
extern const char NakaName_AcWindowMenu;
extern const char NakaName_AcWindowPage;
extern const char NakaName_Bitmap;
extern const char NakaName_Box;
extern const char NakaName_DbDebugMenu;
extern const char NakaName_DbMemo;
extern const char NakaName_DbMemoryDump;
extern const char NakaName_EditSw;
extern const char NakaName_Frame;
extern const char NakaName_GroupBox;
extern const char NakaName_Icon;
extern const char NakaName_IvCatchEvent;
extern const char NakaName_IvDirmdScreen;
extern const char NakaName_IvExit;
extern const char NakaName_IvExitMode;
extern const char NakaName_IvExitScreen;
extern const char NakaName_IvExitWindow;
extern const char NakaName_IvFixWin;
extern const char NakaName_IvIntComplete;
extern const char NakaName_IvIntEasySet;
extern const char NakaName_IvIntError;
extern const char NakaName_IvIntReminder;
extern const char NakaName_IvIntVari;
extern const char NakaName_IvInterrupt;
extern const char NakaName_IvMainEditSw;
extern const char NakaName_IvNaming;
extern const char NakaName_IvPageControl;
extern const char NakaName_IvShowHide;
extern const char NakaName_IvTrackSwitch;
extern const char NakaName_Label;
extern const char NakaName_Line;
extern const char NakaName_ModeEdit;
extern const char NakaName_PsCursorBox;
extern const char NakaName_PsGridBox;
extern const char NakaName_PsInvisibleBox;
extern const char NakaName_PsListBox;
extern const char NakaName_PsPageBox;
extern const char NakaName_PsRadioBox;
extern const char NakaName_PsTextBox;
extern const char NakaName_PsToggleBox;
extern const char NakaName_PsTrackSwitch;
extern const char NakaName_PsWideESBox;
extern const char NakaName_PsWideToggle;
extern const char NakaName_Screen;
extern const char NakaName_StringBox;
extern const char NakaName_TextBox;
extern const char NakaName_TitleEdit;
extern const char NakaName_TrChordBox;
extern const char NakaName_TrTransposeBox;
extern const char NakaName_TtlScreen;
extern const char NakaName_VwEditSwBox;
extern const char NakaName_VwMenuBox;
extern const char NakaName_VwUserBitmap;
extern const char NakaName_VwWideESBox;
extern const char NakaName_Window;
extern const char NakaStr_EAD480;
extern const char NakaStr_EAD48E;
extern const char NakaStr_EAD4A0;
extern const char NakaStr_EAD4C2;
extern const char NakaStr_EAD4D0;
extern const char NakaStr_EAD4E0;
extern const char NakaStr_EAD4EC;
extern const char NakaStr_EAD4FC;
extern const char NakaStr_EAD50A;
extern const char NakaStr_EAD51A;
extern const char NakaStr_EAD528;
extern const char NakaStr_EAD538;
extern const char NakaStr_EAD548;
extern const char NakaStr_EAD558;
extern const char NakaStr_EAD568;
extern const char NakaStr_EAD58C;
extern const char NakaStr_EAD5DC;
extern const char NakaStr_EAD5EC;
extern const char NakaStr_EAD630;
extern const char NakaStr_EAD63C;
extern const char NakaStr_EAD64A;
extern const char NakaStr_EAD65C;
extern const char NakaStr_EAD668;
extern const char NakaStr_EAD678;
extern const char NakaStr_EAD686;
extern const char NakaStr_EAD690;
extern const char NakaStr_EAD69A;
extern const char NakaStr_EAD6AA;
extern const char NakaStr_EAD73E;
extern const char NakaStr_EAD74C;
extern const char NakaStr_EAD7C0;
extern const char NakaStr_EAD7CC;
extern const char NakaStr_EAD7EA;
extern const char NakaStr_EAD7F4;
extern const char NakaStr_EAD7FC;
extern const char NakaStr_EAD810;
extern const char NakaStr_EAD81E;
extern const char NakaStr_EAD840;
extern const char NakaStr_EAD876;
extern const char NakaStr_EAD894;
extern const char NakaStr_EAD8A4;
extern const char NakaStr_EAD8C4;
extern const char PsCursorBoxProc;
extern const char PsGridBoxProc;
extern const char PsInvisibleBoxProc;
extern const char PsListBoxProc;
extern const char PsPageBoxProc;
extern const char PsRadioBoxProc;
extern const char PsTextBoxProc;
extern const char PsToggleBoxProc;
extern const char PsTrackSwitchProc;
extern const char PsWideESBoxProc;
extern const char PsWideToggleProc;
extern const char ScreenProc;
extern const char StringBoxProc;
extern const char TextBoxProc;
extern const char TitleEditProc;
extern const char TrChordBoxProc;
extern const char TrTransposeBoxProc;
extern const char TtlScreenProc;
extern const char VwEditSwBoxProc;
extern const char VwMenuBoxProc;
extern const char VwUserBitmapByNameProc;
extern const char VwUserBitmapProc;
extern const char WindowProc;

#define SELF(field) \
    NAKA_SELF(&block_012_data, block_012_t, field)

typedef struct __attribute__((packed)) {
    naka_dispatch_t w[78];     /* 78 × 24 = 1872 bytes */
    uint8_t trailing[70];    /* strings + padding */
} block_012_t;

_Static_assert(sizeof(block_012_t) == 1942, "block_012_t must be 1942 bytes");

const block_012_t block_012_data = {
    .w = {
        /* w0 */ {
            .header   = NAKA_HDR(0x1E),
            .field_04 = 0x0028,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_AcIndexEditSw),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD8C4),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC296),
            .proc_addr = NAKA_ADDR(AcFuncEditSwProc),
        },
        /* w1 */ {
            .header   = NAKA_HDR(0x1E),
            .field_04 = 0x002C,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_AcFuncEditSw),
            .inst_ptr  = NAKA_ADDR(NakaCode_fj),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC2A6),
            .proc_addr = NAKA_ADDR(PsWideESBoxProc),
        },
        /* w2 */ {
            .header   = NAKA_HDR(0x1E),
            .field_04 = 0x0028,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_PsWideESBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD8A4),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC2C0),
            .proc_addr = NAKA_ADDR(AcIndexEditSwProc),
        },
        /* w3 */ {
            .header   = NAKA_HDR(0x21),
            .field_04 = 0x002A,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_AcIndexWideES),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD894),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC2D2),
            .proc_addr = NAKA_ADDR(AcFuncEditSwProc),
        },
        /* w4 */ {
            .header   = NAKA_HDR(0x21),
            .field_04 = 0x002E,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_AcFuncWideES),
            .inst_ptr  = NAKA_ADDR(NakaCode_fj_D882),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC2E2),
            .proc_addr = NAKA_ADDR(PsPageBoxProc),
        },
        /* w5 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x0020,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_PsPageBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD876),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC2FC),
            .proc_addr = NAKA_ADDR(AcWindowPageProc),
        },
        /* w6 */ {
            .header   = NAKA_HDR(0x24),
            .field_04 = 0x0024,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcWindowPage),
            .inst_ptr  = NAKA_ADDR(NakaCode_AA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC30C),
            .proc_addr = NAKA_ADDR(PsToggleBoxProc),
        },
        /* w7 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x0028,
            .field_06 = 0x0012,
            .name_ptr  = NAKA_ADDR(NakaName_PsToggleBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_cXXme),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC32A),
            .proc_addr = NAKA_ADDR(PsInvisibleBoxProc),
        },
        /* w8 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x0016,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_PsInvisibleBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD840),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC366),
            .proc_addr = NAKA_ADDR(IvPageControlProc),
        },
        /* w9 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001C,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_IvPageControl),
            .inst_ptr  = NAKA_ADDR(NakaCode_At),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC36C),
            .proc_addr = NAKA_ADDR(IvMainEditSwProc),
        },
        /* w10 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvMainEditSw),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD81E),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC388),
            .proc_addr = NAKA_ADDR(AcSoundNameProc),
        },
        /* w11 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0026,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_AcSoundName),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD810),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC398),
            .proc_addr = NAKA_ADDR(LabelProc),
        },
        /* w12 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x0020,
            .field_06 = 0x000A,
            .name_ptr  = NAKA_ADDR(NakaName_Label),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xc),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC3A8),
            .proc_addr = NAKA_ADDR(BitmapProc),
        },
        /* w13 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_Bitmap),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD7FC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC3CE),
            .proc_addr = NAKA_ADDR(IconProc),
        },
        /* w14 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_Icon),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD7F4),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC3DC),
            .proc_addr = NAKA_ADDR(LineProc),
        },
        /* w15 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_Line),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD7EA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC3EC),
            .proc_addr = NAKA_ADDR(FrameProc),
        },
        /* w16 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001C,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_Frame),
            .inst_ptr  = NAKA_ADDR(NakaCode_hA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC40A),
            .proc_addr = NAKA_ADDR(EditSwProc),
        },
        /* w17 */ {
            .header   = NAKA_HDR(0x2B),
            .field_04 = 0x0028,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_EditSw),
            .inst_ptr  = NAKA_ADDR(NakaCode_ejA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC42E),
            .proc_addr = NAKA_ADDR(BoxProc),
        },
        /* w18 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_Box),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD7CC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC454),
            .proc_addr = NAKA_ADDR(GroupBoxProc),
        },
        /* w19 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x001A,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_GroupBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD7C0),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC470),
            .proc_addr = NAKA_ADDR(ScreenProc),
        },
        /* w20 */ {
            .header   = NAKA_HDR(0x32),
            .field_04 = 0x0022,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_Screen),
            .inst_ptr  = NAKA_ADDR(NakaCode_ar),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC476),
            .proc_addr = NAKA_ADDR(TtlScreenProc),
        },
        /* w21 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x002A,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_TtlScreen),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xb),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC492),
            .proc_addr = NAKA_ADDR(WindowProc),
        },
        /* w22 */ {
            .header   = NAKA_HDR(0x32),
            .field_04 = 0x0024,
            .field_06 = 0x000A,
            .name_ptr  = NAKA_ADDR(NakaName_Window),
            .inst_ptr  = NAKA_ADDR(NakaCode_Grr),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC4AC),
            .proc_addr = NAKA_ADDR(TextBoxProc),
        },
        /* w23 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x0028,
            .field_06 = 0x000E,
            .name_ptr  = NAKA_ADDR(NakaName_TextBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_XcdB),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC4D2),
            .proc_addr = NAKA_ADDR(StringBoxProc),
        },
        /* w24 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x0026,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaName_StringBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xcd),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC512),
            .proc_addr = NAKA_ADDR(ModeEditProc),
        },
        /* w25 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x002C,
            .field_06 = 0x0012,
            .name_ptr  = NAKA_ADDR(NakaName_ModeEdit),
            .inst_ptr  = NAKA_ADDR(NakaCode_kalX),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC546),
            .proc_addr = NAKA_ADDR(TitleEditProc),
        },
        /* w26 */ {
            .header   = NAKA_HDR(0x31),
            .field_04 = 0x002C,
            .field_06 = 0x0012,
            .name_ptr  = NAKA_ADDR(NakaName_TitleEdit),
            .inst_ptr  = NAKA_ADDR(NakaCode_akNlX),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC57E),
            .proc_addr = NAKA_ADDR(AcRhythmNameProc),
        },
        /* w27 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_AcRhythmName),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD74C),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC5B4),
            .proc_addr = NAKA_ADDR(AcPmemNameProc),
        },
        /* w28 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_AcPmemName),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD73E),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC5BA),
            .proc_addr = NAKA_ADDR(AcMixerVolProc),
        },
        /* w29 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x0020,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcMixerVol),
            .inst_ptr  = NAKA_ADDR(NakaCode_ue),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC5C0),
            .proc_addr = NAKA_ADDR(VwMenuBoxProc),
        },
        /* w30 */ {
            .header   = NAKA_HDR(0x1C),
            .field_04 = 0x0032,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_VwMenuBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xb_D720),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC5DC),
            .proc_addr = NAKA_ADDR(VwEditSwBoxProc),
        },
        /* w31 */ {
            .header   = NAKA_HDR(0x1E),
            .field_04 = 0x002C,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_VwEditSwBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_fX),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC5F4),
            .proc_addr = NAKA_ADDR(VwEditSwBoxProc),
        },
        /* w32 */ {
            .header   = NAKA_HDR(0x21),
            .field_04 = 0x002E,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_VwWideESBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_fX_D700),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC60C),
            .proc_addr = NAKA_ADDR(AcTitleMenuProc),
        },
        /* w33 */ {
            .header   = NAKA_HDR(0x1C),
            .field_04 = 0x0036,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaName_AcModeMenu),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xb_D6F0),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC624),
            .proc_addr = NAKA_ADDR(AcTitleMenuProc),
        },
        /* w34 */ {
            .header   = NAKA_HDR(0x1C),
            .field_04 = 0x0036,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaName_AcScreenMenu),
            .inst_ptr  = NAKA_ADDR(NakaCode_XNb),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC646),
            .proc_addr = NAKA_ADDR(AcTitleMenuProc),
        },
        /* w35 */ {
            .header   = NAKA_HDR(0x1C),
            .field_04 = 0x0036,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaName_AcWindowMenu),
            .inst_ptr  = NAKA_ADDR(NakaCode_Xtb),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC66A),
            .proc_addr = NAKA_ADDR(AcBitEditBoxProc),
        },
        /* w36 */ {
            .header   = NAKA_HDR(0x15),
            .field_04 = 0x003A,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_AcBitEditBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_jm),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC68E),
            .proc_addr = NAKA_ADDR(AcFuncToggleProc),
        },
        /* w37 */ {
            .header   = NAKA_HDR(0x26),
            .field_04 = 0x002C,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcFuncToggle),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD6AA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6A8),
            .proc_addr = NAKA_ADDR(PsWideToggleProc),
        },
        /* w38 */ {
            .header   = NAKA_HDR(0x26),
            .field_04 = 0x002A,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_PsWideToggle),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD69A),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6B8),
            .proc_addr = NAKA_ADDR(DbMemoProc),
        },
        /* w39 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x0016,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_DbMemo),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD690),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6CA),
            .proc_addr = NAKA_ADDR(IvExitProc),
        },
        /* w40 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x0016,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvExit),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD686),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6D0),
            .proc_addr = NAKA_ADDR(IvExitModeProc),
        },
        /* w41 */ {
            .header   = NAKA_HDR(0x47),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvExitMode),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD678),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6D6),
            .proc_addr = NAKA_ADDR(IvExitScreenProc),
        },
        /* w42 */ {
            .header   = NAKA_HDR(0x47),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvExitScreen),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD668),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6E6),
            .proc_addr = NAKA_ADDR(IvFixWinProc),
        },
        /* w43 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvFixWin),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD65C),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC6F8),
            .proc_addr = NAKA_ADDR(AcNamingWindowProc),
        },
        /* w44 */ {
            .header   = NAKA_HDR(0x35),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_AcNamingWindow),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD64A),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC70A),
            .proc_addr = NAKA_ADDR(PsCursorBoxProc),
        },
        /* w45 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0028,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_PsCursorBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD63C),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC710),
            .proc_addr = NAKA_ADDR(IvNamingProc),
        },
        /* w46 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvNaming),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD630),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC722),
            .proc_addr = NAKA_ADDR(AcIndexToggleProc),
        },
        /* w47 */ {
            .header   = NAKA_HDR(0x26),
            .field_04 = 0x002C,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcIndexToggle),
            .inst_ptr  = NAKA_ADDR(NakaCode_AA_D61E),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC732),
            .proc_addr = NAKA_ADDR(AcRamBoxProc),
        },
        /* w48 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x002C,
            .field_06 = 0x0008,
            .name_ptr  = NAKA_ADDR(NakaName_AcRamBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_jr),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC74A),
            .proc_addr = NAKA_ADDR(PsRadioBoxProc),
        },
        /* w49 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x002C,
            .field_06 = 0x0010,
            .name_ptr  = NAKA_ADDR(NakaName_PsRadioBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_cdemA),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC764),
            .proc_addr = NAKA_ADDR(AcStrRadioBoxProc),
        },
        /* w50 */ {
            .header   = NAKA_HDR(0x50),
            .field_04 = 0x0030,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcStrRadioBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD5EC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC7AE),
            .proc_addr = NAKA_ADDR(IvCatchEventProc),
        },
        /* w51 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvCatchEvent),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD5DC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC7BC),
            .proc_addr = NAKA_ADDR(PsListBoxProc),
        },
        /* w52 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x002A,
            .field_06 = 0x000E,
            .name_ptr  = NAKA_ADDR(NakaName_PsListBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_cdBn),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC7CC),
            .proc_addr = NAKA_ADDR(PsGridBoxProc),
        },
        /* w53 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x003E,
            .field_06 = 0x0022,
            .name_ptr  = NAKA_ADDR(NakaName_PsGridBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_cdBBGnnsss),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC80A),
            .proc_addr = NAKA_ADDR(AcListBoxProc),
        },
        /* w54 */ {
            .header   = NAKA_HDR(0x53),
            .field_04 = 0x0030,
            .field_06 = 0x0006,
            .name_ptr  = NAKA_ADDR(NakaName_AcListBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_XG),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC886),
            .proc_addr = NAKA_ADDR(AcGridBoxProc),
        },
        /* w55 */ {
            .header   = NAKA_HDR(0x54),
            .field_04 = 0x004A,
            .field_06 = 0x000C,
            .name_ptr  = NAKA_ADDR(NakaName_AcGridBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_XXj),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC8A0),
            .proc_addr = NAKA_ADDR(DbDebugMenuProc),
        },
        /* w56 */ {
            .header   = NAKA_HDR(0x1C),
            .field_04 = 0x002E,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_DbDebugMenu),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD58C),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC8CC),
            .proc_addr = NAKA_ADDR(PsTrackSwitchProc),
        },
        /* w57 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x0024,
            .field_06 = 0x000E,
            .name_ptr  = NAKA_ADDR(NakaName_PsTrackSwitch),
            .inst_ptr  = NAKA_ADDR(NakaCode_vmnn),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC8DC),
            .proc_addr = NAKA_ADDR(AcTrackSwitchProc),
        },
        /* w58 */ {
            .header   = NAKA_HDR(0x58),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_AcTrackSwitch),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD568),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC90C),
            .proc_addr = NAKA_ADDR(IvDirmdScreenProc),
        },
        /* w59 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0022,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvDirmdScreen),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD558),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC912),
            .proc_addr = NAKA_ADDR(IvTrackSwitchProc),
        },
        /* w60 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x0016,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvTrackSwitch),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD548),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC918),
            .proc_addr = NAKA_ADDR(IvExitWindowProc),
        },
        /* w61 */ {
            .header   = NAKA_HDR(0x47),
            .field_04 = 0x0016,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvExitWindow),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD538),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC91E),
            .proc_addr = NAKA_ADDR(DbMemoryDumpProc),
        },
        /* w62 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_DbMemoryDump),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD528),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC924),
            .proc_addr = NAKA_ADDR(IvInterruptProc),
        },
        /* w63 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x0018,
            .field_06 = 0x0002,
            .name_ptr  = NAKA_ADDR(NakaName_IvInterrupt),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD51A),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC932),
            .proc_addr = NAKA_ADDR(IvIntReminderProc),
        },
        /* w64 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvIntReminder),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD50A),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC942),
            .proc_addr = NAKA_ADDR(IvIntErrorProc),
        },
        /* w65 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvIntError),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4FC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC948),
            .proc_addr = NAKA_ADDR(IvIntCompleteProc),
        },
        /* w66 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvIntComplete),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4EC),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC94E),
            .proc_addr = NAKA_ADDR(IvIntVariProc),
        },
        /* w67 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvIntVari),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4E0),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC954),
            .proc_addr = NAKA_ADDR(IvIntEasySetProc),
        },
        /* w68 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_IvIntEasySet),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4D0),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC95A),
            .proc_addr = NAKA_ADDR(IvShowHideProc),
        },
        /* w69 */ {
            .header   = NAKA_HDR(0x27),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_IvShowHide),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4C2),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC960),
            .proc_addr = NAKA_ADDR(PsTextBoxProc),
        },
        /* w70 */ {
            .header   = NAKA_HDR(0x11),
            .field_04 = 0x0026,
            .field_06 = 0x000A,
            .name_ptr  = NAKA_ADDR(NakaName_PsTextBox),
            .inst_ptr  = NAKA_ADDR(NakaCode_cdB),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC970),
            .proc_addr = NAKA_ADDR(AcLanguageTextProc),
        },
        /* w71 */ {
            .header   = NAKA_HDR(0x65),
            .field_04 = 0x002A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_AcLanguageText),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD4A0),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9A6),
            .proc_addr = NAKA_ADDR(TrTransposeBoxProc),
        },
        /* w72 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_TrTransposeBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD48E),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9B6),
            .proc_addr = NAKA_ADDR(TrChordBoxProc),
        },
        /* w73 */ {
            .header   = NAKA_HDR(0x12),
            .field_04 = 0x0024,
            .field_06 = 0x0000,
            .name_ptr  = NAKA_ADDR(NakaName_TrChordBox),
            .inst_ptr  = NAKA_ADDR(NakaStr_EAD480),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9BC),
            .proc_addr = NAKA_ADDR(VwUserBitmapProc),
        },
        /* w74 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = NAKA_ADDR(NakaName_VwUserBitmap),
            .inst_ptr  = NAKA_ADDR(NakaData_WidgetNames),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9C2),
            .proc_addr = NAKA_ADDR(IvScreenProc),
        },
        /* w75 */ {
            .header   = NAKA_HDR(0x33),
            .field_04 = 0x0022,
            .field_06 = 0x0000,
            .name_ptr  = SELF(trailing[60]),
            .inst_ptr  = SELF(trailing[58]),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9D2),
            .proc_addr = NAKA_ADDR(IvIntWelcomeProc),
        },
        /* w76 */ {
            .header   = NAKA_HDR(0x5E),
            .field_04 = 0x0018,
            .field_06 = 0x0000,
            .name_ptr  = SELF(trailing[44]),
            .inst_ptr  = SELF(trailing[42]),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9D8),
            .proc_addr = NAKA_ADDR(VwUserBitmapByNameProc),
        },
        /* w77 */ {
            .header   = NAKA_HDR(0x10),
            .field_04 = 0x001A,
            .field_06 = 0x0004,
            .name_ptr  = SELF(trailing[22]),
            .inst_ptr  = SELF(trailing[20]),
            .link_ptr  = NAKA_ADDR(NakaLink_EAC9DE),
            .proc_addr = 0,
        },
    },
    .trailing = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x58, 0x00, 0x56, 0x77, 0x55, 0x73, 0x65, 0x72, 0x42, 0x69, 0x74, 0x6D,
        0x61, 0x70, 0x42, 0x79, 0x4E, 0x61, 0x6D, 0x65, 0x00, 0xFF, 0x00, 0xFF, 0x49, 0x76, 0x49, 0x6E,
        0x74, 0x57, 0x65, 0x6C, 0x63, 0x6F, 0x6D, 0x65, 0x00, 0xFF, 0x00, 0xFF, 0x49, 0x76, 0x53, 0x63,
        0x72, 0x65, 0x65, 0x6E, 0x00, 0xFF,
    },
};
