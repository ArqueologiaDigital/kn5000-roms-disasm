/**
 * sepaout_config.c -- SepaOut (separate output) configuration data
 *
 * Contains MIDI/audio separate-output port configuration, screen layout
 * parameters, bitmask tables, format strings, channel/parameter mappings,
 * and handler function pointer tables.
 *
 * Base ROM address: 0xE1FFE6 (SepaOut_Config_0)
 * Total size: 826 bytes
 *
 * NOTE: RESOURCE_INFO_HANDLER_OFFSETS (20 bytes before this block) remains
 * in assembly because it uses label-difference arithmetic.
 */

#include <stdint.h>

/* ---- 24-bit ROM pointer macro ---- */
#define SEPA_ADDR(sym) ((uint32_t)(unsigned long)&(sym))

/* ---- External symbols (resolved by linker script) ---- */

/* Display/UI handler pointers */
extern const char Display_InitGraphicsAndScreen;
extern const char Display_CallConditionalCompare;
extern const char Display_CallPollAudioUpdate;
extern const char SqTrSel_CaseA;

/* Language check string pointers */
extern const char PartSelLangCheck;
extern const char AfterLangCheck;
extern const char TrAsPreLangCheck;
extern const char AtentionLangCheck;
extern const char AreYouSureLangCheck;
extern const char GmOnSureLangCheck;
extern const char GmOffSureLangCheck;
extern const char TrAsSureLangCheck;

/* Sequencer/song function handlers */
extern const char SqTrAsPsSongFunc;
extern const char DemoSongSelFunc;
extern const char SmfMuteChSelFunc;
extern const char SqAftSetFunc;
extern const char MuteChSetFunc;
extern const char SMFMuteOnOffFunc;
extern const char Rt1MuteFunc;
extern const char Rt2MuteFunc;
extern const char DocOrchMuteFunc;
extern const char PdOrchMuteFunc;
extern const char SeqNamingCheck;
extern const char SeqNameOKFunc;
extern const char TrAsGridCheck;
extern const char DemoMedDspCheck;
extern const char DPPlayDspCheck;
extern const char DPPauseDspCheck;

/* UI box region boundary/end labels */
extern const char ComposerBox_End;
extern const char MeasureBoxFunc;
extern const char MeasureBoxFunc_End;
extern const char AcDiskFileName_End;
extern const char AcDocSongName_End;
extern const char AcPDSongName_End;
extern const char AcSmfFileName_End;
extern const char AcSmfSongName_End;
extern const char AcDocFileNo_End;
extern const char IvNamingExitProc;
extern const char TrAsGridChk_End;
extern const char AcDemoSong_End;
extern const char AcCurSong_End;
extern const char VoiceConfig_End;
extern const char TrAsGrid_BoxProc;
extern const char SqAftSetFunc_End;
extern const char Audio_ExternalCallback_End;
extern const char LyricsBoxFuncProc_Boundary;
extern const char LyricsBoxFunc_End;
extern const char SongNameBox_End;
extern const char SeqNameOK_End;
extern const char DemoMedDsp_End;

/* Debug string pointer */
extern const char DbgStr_PartSelLangCheck;

/* ---- Type definitions ---- */

typedef struct __attribute__((packed)) {
    uint16_t base;
    uint16_t flags;
} sepa_config_entry_t;

typedef struct __attribute__((packed)) {
    uint16_t channel;
    uint16_t param;
} sepa_channel_param_t;

/* ---- Main data structure ---- */

typedef struct __attribute__((packed)) {
    /* [0] SepaOut_Config: 5 port config entries (20 bytes) */
    sepa_config_entry_t config[5];

    /* [20] SepaOut_LayoutParams_0: row/column layout (54 bytes) */
    uint16_t layout0_row_heights_a[3];  /* {0x0000, 0x000E, 0x001A} */
    uint8_t  layout0_interleaved[7];    /* 0x1A,0x00,0x1A,0x00,0x1A,0x00,0x00 -- includes LayoutByte_0..5 */
    uint8_t  layout0_separator;         /* 0x00 */
    uint16_t layout0_row_heights_b[5];  /* {0x000E, 0x001A, 0x001A, 0x001A, 0x001A} */
    uint16_t layout0_col_widths_a[6];   /* {0x0000, 0x0033, 0x00A3, 0x004C, 0x00A3, 0x00A3} */
    uint16_t layout0_col_widths_b[6];   /* {0x0000, 0x003E, 0x0060, 0x0060, 0x0060, 0x0060} */
    uint16_t layout0_tail[3];           /* {0x0000, 0x0000, 0x0101} */

    /* [74] SepaOut_LayoutParams_1: additional layout params (40 bytes) */
    uint16_t layout1[20];

    /* [114] SepaOut_BitMaskTable: bit masks for channel selection (28 bytes) */
    uint16_t bitmask_table[14];

    /* [142] Channel index table: sequential 0x0000..0x001F (64 bytes) */
    uint16_t channel_index[32];

    /* [206] Extra layout dimension groups (57 bytes) */
    uint16_t dim_positions[7];          /* {0x0000, 0x001E, 0x007A, 0x00B8, 0x000F, 0x004C, 0x0098} */
    uint16_t dim_row_a[6];             /* {0x0000, 0x001B, 0x0074, 0x0074, 0x0074, 0x0074} */
    uint16_t dim_row_b[6];             /* {0x0000, 0x001B, 0x0074, 0x0074, 0x0074, 0x0074} */
    uint16_t dim_row_c[6];             /* {0x0000, 0x0028, 0x0081, 0x0081, 0x0081, 0x0081} */
    uint16_t dim_row_d[3];             /* {0x0000, 0x0049, 0x00A7} */
    uint8_t  dim_tail_byte;            /* 0x5A */

    /* [263] SepaOut_FormatData_Tail: format data + strings (563 bytes) */
    uint8_t  fmt_tail_zero;            /* 0x00 */
    uint16_t fmt_tail_dims[2];         /* {0x00A7, 0x00A7} */

    /* Format strings (null-terminated, 0xFF padding for even alignment) */
    char     fmt_number_name[9];       /* "%2d : %s" */
    uint8_t  fmt_number_name_pad;      /* 0xFF (alignment) */
    char     fmt_file_number[12];      /* "FILE%02d:%s" */
    char     fmt_3digit[8];            /* "%03d:%s" */
    char     fmt_2digit_a[8];          /* "%02d:%s" */
    char     fmt_2digit_b[8];          /* "%02d:%s" */

    /* [314] File list column metrics (14 entries, 28 bytes) */
    uint16_t file_col_metrics[14];

    /* [342] Screen position groups: 3 repeated blocks + extensions (120 bytes) */
    uint16_t screen_group_a[10];       /* x-positions and widths (group A) */
    uint16_t screen_gap_a[6];          /* gap/height values (group A) */
    uint16_t screen_group_b[10];       /* x-positions and widths (group B) */
    uint16_t screen_gap_b[6];          /* gap/height values (group B) */
    uint16_t screen_group_c[10];       /* x-positions and widths (group C) */
    uint16_t screen_ext_a[6];          /* extended positions (D) */
    uint16_t screen_ext_b[6];          /* extended positions (E) */
    uint16_t screen_ext_c[6];          /* extended positions (F) */

    /* [462] Display handler function pointers (4 entries, 16 bytes) */
    uint32_t display_handlers[4];

    /* [478] Screen dimension arrays (62 bytes) */
    uint16_t dim_group_e[6];           /* {0x0000, 0x008F x5} */
    uint16_t dim_group_f[6];           /* {0x0000, 0x008A x5} */
    uint16_t dim_group_g[6];           /* {0x0000, 0x008A x5} */
    uint16_t y_coords[13];            /* Y-coordinate table */

    /* [540] Percentage format string (6 bytes) */
    char     fmt_percent[5];           /* "%3d%%" */
    uint8_t  fmt_percent_null;         /* 0x00 (null terminator stored explicitly) */

    /* [546] Channel/parameter mapping table (18 entries, 72 bytes) */
    sepa_channel_param_t channel_params[18];

    /* [618] Sequencer part count table (8 bytes) */
    uint16_t seq_part_counts[4];

    /* [626] UI position offsets (8 bytes) */
    uint16_t ui_pos_offsets[4];

    /* [634] Language check string pointer table (8 entries, 32 bytes) */
    uint32_t lang_check_ptrs[8];

    /* [666] Function handler pointer table (38 entries, 152 bytes) */
    uint32_t handler_ptrs[38];

    /* [818] Null terminator + debug string pointer (8 bytes) */
    uint32_t handler_null;
    uint32_t dbg_str_ptr;
} sepaout_data_t;

_Static_assert(sizeof(sepaout_data_t) == 826,
    "SepaOut data must be exactly 826 bytes");

const sepaout_data_t SepaOut_Config_0
    __attribute__((section(".text"), used)) = {

    /* ---- SepaOut port config entries ---- */
    .config = {
        { .base = 0x00B0, .flags = 0x019B },
        { .base = 0x00B0, .flags = 0x209B },
        { .base = 0x00B0, .flags = 0x009D },
        { .base = 0x00B0, .flags = 0x019D },
        { .base = 0x00B0, .flags = 0x029D },
    },

    /* ---- SepaOut_LayoutParams_0 ---- */
    .layout0_row_heights_a = { 0x0000, 0x000E, 0x001A },
    .layout0_interleaved = { 0x1A, 0x00, 0x1A, 0x00, 0x1A, 0x00, 0x00 },
    .layout0_separator = 0x00,
    .layout0_row_heights_b = { 0x000E, 0x001A, 0x001A, 0x001A, 0x001A },
    .layout0_col_widths_a  = { 0x0000, 0x0033, 0x00A3, 0x004C, 0x00A3, 0x00A3 },
    .layout0_col_widths_b  = { 0x0000, 0x003E, 0x0060, 0x0060, 0x0060, 0x0060 },
    .layout0_tail          = { 0x0000, 0x0000, 0x0101 },

    /* ---- SepaOut_LayoutParams_1 ---- */
    .layout1 = {
        0x0000, 0x0101, 0x0000, 0x0001, 0x000C,
        0x0000, 0x0000, 0x000E, 0x005A, 0x005A,
        0x005A, 0x005A, 0x0000, 0x000E, 0x005A,
        0x005A, 0x005A, 0x005A, 0x0001, 0x0002,
    },

    /* ---- SepaOut_BitMaskTable (bits 2..15) ---- */
    .bitmask_table = {
        0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080, 0x0100,
        0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000,
    },

    /* ---- Channel index (0..31) ---- */
    .channel_index = {
        0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007,
        0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F,
        0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017,
        0x0018, 0x0019, 0x001A, 0x001B, 0x001C, 0x001D, 0x001E, 0x001F,
    },

    /* ---- Extra layout dimension groups ---- */
    .dim_positions = { 0x0000, 0x001E, 0x007A, 0x00B8, 0x000F, 0x004C, 0x0098 },
    .dim_row_a     = { 0x0000, 0x001B, 0x0074, 0x0074, 0x0074, 0x0074 },
    .dim_row_b     = { 0x0000, 0x001B, 0x0074, 0x0074, 0x0074, 0x0074 },
    .dim_row_c     = { 0x0000, 0x0028, 0x0081, 0x0081, 0x0081, 0x0081 },
    .dim_row_d     = { 0x0000, 0x0049, 0x00A7 },
    .dim_tail_byte = 0x5A,

    /* ---- SepaOut_FormatData_Tail ---- */
    .fmt_tail_zero     = 0x00,
    .fmt_tail_dims     = { 0x00A7, 0x00A7 },

    .fmt_number_name     = "%2d : %s",
    .fmt_number_name_pad = 0xFF,
    .fmt_file_number     = "FILE%02d:%s",
    .fmt_3digit          = "%03d:%s",
    .fmt_2digit_a        = "%02d:%s",
    .fmt_2digit_b        = "%02d:%s",

    /* ---- File list column metrics ---- */
    .file_col_metrics = {
        0x0000, 0x0048, 0x0081, 0x00C1, 0x02B9, 0x013B, 0x010D,
        0x01B5, 0x0187, 0x02B9, 0x02B9, 0x02B9, 0x01FD, 0x0259,
    },

    /* ---- Screen position groups ---- */
    .screen_group_a = {
        0x0000, 0x0005, 0x0029, 0x006B, 0x002E,
        0x006B, 0x006B, 0x006B, 0x003A, 0x0035,
    },
    .screen_gap_a = {
        0x0000, 0x0013, 0x00E1, 0x00E1, 0x00E1, 0x00E1,
    },
    .screen_group_b = {
        0x0000, 0x0005, 0x0029, 0x006B, 0x002E,
        0x006B, 0x006B, 0x006B, 0x003A, 0x0035,
    },
    .screen_gap_b = {
        0x0000, 0x0013, 0x00E1, 0x00E1, 0x00E1, 0x00E1,
    },
    .screen_group_c = {
        0x0000, 0x0005, 0x0029, 0x006B, 0x002E,
        0x006B, 0x006B, 0x006B, 0x003A, 0x0035,
    },
    .screen_ext_a = {
        0x0000, 0x0021, 0x0107, 0x0107, 0x0107, 0x0107,
    },
    .screen_ext_b = {
        0x0000, 0x000E, 0x00D5, 0x0014, 0x00D5, 0x00D5,
    },
    .screen_ext_c = {
        0x0000, 0x000E, 0x001A, 0x001A, 0x001A, 0x001A,
    },

    /* ---- Display handler function pointers ---- */
    .display_handlers = {
        SEPA_ADDR(Display_InitGraphicsAndScreen),   /* 0x00F22262 */
        SEPA_ADDR(Display_CallConditionalCompare),   /* 0x00F22288 */
        SEPA_ADDR(Display_CallPollAudioUpdate),      /* 0x00F22295 */
        SEPA_ADDR(SqTrSel_CaseA),                   /* 0x00F222A2 */
    },

    /* ---- Screen dimension arrays ---- */
    .dim_group_e = { 0x0000, 0x008F, 0x008F, 0x008F, 0x008F, 0x008F },
    .dim_group_f = { 0x0000, 0x008A, 0x008A, 0x008A, 0x008A, 0x008A },
    .dim_group_g = { 0x0000, 0x008A, 0x008A, 0x008A, 0x008A, 0x008A },

    /* ---- Y-coordinate table ---- */
    .y_coords = {
        0x0000, 0x0013, 0x0097, 0x0097, 0x002E, 0x003C, 0x0066,
        0x0074, 0x004A, 0x0058, 0x0082, 0x0088, 0x008D,
    },

    /* ---- Percentage format string ---- */
    .fmt_percent      = "%3d%%",
    .fmt_percent_null = 0x00,

    /* ---- Channel/parameter mappings (ch 1-6, params 0xE1-0xE3) ---- */
    .channel_params = {
        { 1, 0x00E1 }, { 2, 0x00E1 }, { 3, 0x00E1 },
        { 4, 0x00E1 }, { 5, 0x00E1 }, { 6, 0x00E1 },
        { 1, 0x00E2 }, { 2, 0x00E2 }, { 3, 0x00E2 },
        { 4, 0x00E2 }, { 5, 0x00E2 }, { 6, 0x00E2 },
        { 1, 0x00E3 }, { 2, 0x00E3 }, { 3, 0x00E3 },
        { 4, 0x00E3 }, { 5, 0x00E3 }, { 6, 0x00E3 },
    },

    /* ---- Sequencer part count table ---- */
    .seq_part_counts = { 0x0000, 0x0003, 0x0006, 0x0000 },

    /* ---- UI position offsets ---- */
    .ui_pos_offsets = { 0x0009, 0x0023, 0x0030, 0x0016 },

    /* ---- Language check string pointers ---- */
    .lang_check_ptrs = {
        SEPA_ADDR(PartSelLangCheck),
        SEPA_ADDR(AfterLangCheck),
        SEPA_ADDR(TrAsPreLangCheck),
        SEPA_ADDR(AtentionLangCheck),
        SEPA_ADDR(AreYouSureLangCheck),
        SEPA_ADDR(GmOnSureLangCheck),
        SEPA_ADDR(GmOffSureLangCheck),
        SEPA_ADDR(TrAsSureLangCheck),
    },

    /* ---- Function handler pointer table ---- */
    .handler_ptrs = {
        SEPA_ADDR(SqTrAsPsSongFunc),             /*  0 */
        SEPA_ADDR(DemoSongSelFunc),               /*  1 */
        SEPA_ADDR(SmfMuteChSelFunc),              /*  2 */
        SEPA_ADDR(SqAftSetFunc),                  /*  3 */
        SEPA_ADDR(MuteChSetFunc),                 /*  4 */
        SEPA_ADDR(SMFMuteOnOffFunc),              /*  5 */
        SEPA_ADDR(Rt1MuteFunc),                   /*  6 */
        SEPA_ADDR(Rt2MuteFunc),                   /*  7 */
        SEPA_ADDR(DocOrchMuteFunc),               /*  8 */
        SEPA_ADDR(PdOrchMuteFunc),                /*  9 */
        SEPA_ADDR(SeqNamingCheck),                /* 10 */
        SEPA_ADDR(SeqNameOKFunc),                 /* 11 */
        SEPA_ADDR(TrAsGridCheck),                 /* 12 */
        SEPA_ADDR(DemoMedDspCheck),               /* 13 */
        SEPA_ADDR(DPPlayDspCheck),                /* 14 */
        SEPA_ADDR(DPPauseDspCheck),               /* 15 */
        SEPA_ADDR(ComposerBox_End),               /* 16 */
        SEPA_ADDR(MeasureBoxFunc),                /* 17 */
        SEPA_ADDR(MeasureBoxFunc_End),            /* 18 */
        SEPA_ADDR(AcDiskFileName_End),            /* 19 */
        SEPA_ADDR(AcDocSongName_End),             /* 20 */
        SEPA_ADDR(AcPDSongName_End),              /* 21 */
        SEPA_ADDR(AcSmfFileName_End),             /* 22 */
        SEPA_ADDR(AcSmfSongName_End),             /* 23 */
        SEPA_ADDR(AcDocFileNo_End),               /* 24 */
        SEPA_ADDR(IvNamingExitProc),              /* 25 */
        SEPA_ADDR(TrAsGridChk_End),               /* 26 */
        SEPA_ADDR(AcDemoSong_End),                /* 27 */
        SEPA_ADDR(AcCurSong_End),                 /* 28 */
        SEPA_ADDR(VoiceConfig_End),               /* 29 */
        SEPA_ADDR(TrAsGrid_BoxProc),              /* 30 */
        SEPA_ADDR(SqAftSetFunc_End),              /* 31 */
        SEPA_ADDR(Audio_ExternalCallback_End),    /* 32 */
        SEPA_ADDR(LyricsBoxFuncProc_Boundary),    /* 33 */
        SEPA_ADDR(LyricsBoxFunc_End),             /* 34 */
        SEPA_ADDR(SongNameBox_End),               /* 35 */
        SEPA_ADDR(SeqNameOK_End),                 /* 36 */
        SEPA_ADDR(DemoMedDsp_End),                /* 37 */
    },

    /* ---- Null terminator + debug string pointer ---- */
    .handler_null  = 0x00000000,
    .dbg_str_ptr   = SEPA_ADDR(DbgStr_PartSelLangCheck),
};
