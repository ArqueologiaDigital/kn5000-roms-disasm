/**
 * StyleUI_ScreenData_Main — Style UI Main Screen Layout
 *
 * Source: e0bb90_e0c95a.bin (3531 bytes)
 *
 * Screen layout for the accompaniment style editor main view.
 * The 320x240 LCD is divided into:
 *   - Top row (y=35): 4 chord name display boxes (HLINE/VLINE/REF)
 *   - 3 parameter grid rows at y=80, 125, 170 with 4 columns each
 *   - Row label references and control widgets
 *   - 24 parameter value widgets (handler 0xe0bd98)
 *   - 72 chord root/type/quality widgets (3 rows × 8 cells × 3 layers)
 *   - Chord name tables: 12 root names + ~48 type names
 *   - SETUP/CONTROL blocks with coordinate arrays
 *   - Chord recognition bitmap (64 bytes)
 *   - 24 track status widgets + bottom bar (8 FILLED_RECT + 6 HLINE)
 */

#include "screendata_types.h"
#include <stddef.h>

typedef struct __attribute__((packed)) {
	/* === Chord Name Boxes (180 bytes, y=35) === */
	/* Box 1 */
	sd_hline_t          box1_hline_left;
	sd_hline_t          box1_hline_right;
	sd_vline_t          box1_vline_left;
	sd_vline_t          box1_vline_right;
	sd_labeled_ref_1_t  box1_ref;
	/* Box 2 */
	sd_hline_t          box2_hline_left;
	sd_hline_t          box2_hline_right;
	sd_vline_t          box2_vline_left;
	sd_vline_t          box2_vline_right;
	sd_labeled_ref_1_t  box2_ref;
	/* Box 3 */
	sd_hline_t          box3_hline_left;
	sd_hline_t          box3_hline_right;
	sd_vline_t          box3_vline_left;
	sd_vline_t          box3_vline_right;
	sd_labeled_ref_1_t  box3_ref;
	/* Box 4 (different element order) */
	sd_vline_t          box4_vline_left;
	sd_vline_t          box4_vline_right;
	sd_labeled_ref_1_t  box4_ref;
	sd_hline_t          box4_hline_left;
	sd_hline_t          box4_hline_right;

	/* === Parameter Grid Lines (270 bytes, 3 rows × 9 segments) === */
	/* Row 1 (y=80): 5 corner VLINEs + 4 bar HLINEs */
	sd_vline_t  grid1_corner_1;
	sd_hline_t  grid1_bar_1;
	sd_vline_t  grid1_corner_2;
	sd_hline_t  grid1_bar_2;
	sd_vline_t  grid1_corner_3;
	sd_hline_t  grid1_bar_3;
	sd_vline_t  grid1_corner_4;
	sd_hline_t  grid1_bar_4;
	sd_vline_t  grid1_corner_5;
	/* Row 2 (y=125): 5 corner VLINEs + 4 bar HLINEs */
	sd_vline_t  grid2_corner_1;
	sd_hline_t  grid2_bar_1;
	sd_vline_t  grid2_corner_2;
	sd_hline_t  grid2_bar_2;
	sd_vline_t  grid2_corner_3;
	sd_hline_t  grid2_bar_3;
	sd_vline_t  grid2_corner_4;
	sd_hline_t  grid2_bar_4;
	sd_vline_t  grid2_corner_5;
	/* Row 3 (y=170): 5 corner VLINEs + 4 bar HLINEs */
	sd_vline_t  grid3_corner_1;
	sd_hline_t  grid3_bar_1;
	sd_vline_t  grid3_corner_2;
	sd_hline_t  grid3_bar_2;
	sd_vline_t  grid3_corner_3;
	sd_hline_t  grid3_bar_3;
	sd_vline_t  grid3_corner_4;
	sd_hline_t  grid3_bar_4;
	sd_vline_t  grid3_corner_5;

	/* === Row Label References (55 bytes) === */
	sd_ref_ex_t         row_label_1;
	sd_ref_ex_t         row_label_2;
	sd_ref_ex_t         row_label_3;
	sd_labeled_ref_1_t  row_ref_1;
	sd_labeled_ref_1_t  row_ref_2;
	sd_labeled_ref_1_t  row_ref_3;
	sd_nop_10_t         nop_pad;

	/* === Control Widgets (125 bytes, complex interleaved) === */
	uint8_t control_widgets[125];

	/* === Parameter Value Widgets (360 bytes, 24 × sd_widget_t) === */
	sd_widget_t param_widgets[24];

	/* === Chord Root/Type/Quality Widgets (1080 bytes, 72 × sd_widget_t) === */
	sd_widget_t chord_widgets[72];

	/* === Chord Root Names (32 bytes: C Db D Eb E F F# G Ab A Bb B) === */
	uint8_t chord_root_names[32];

	/* === Chord Type Names (242 bytes: Maj7, aug, min, dim, etc.) === */
	uint8_t chord_type_names[242];

	/* === Footer Labels (40 bytes) === */
	uint8_t footer_labels[40];

	/* === SETUP/CONTROL Blocks + Coordinate Arrays (580 bytes) === */
	uint8_t          setup_text[40];         /* blank text buffer */
	uint8_t          setup_label[6];         /* format label "_ 7 6 " */
	sd_config_block_t    setup_config;       /* config reference (8 bytes) */
	sd_boundary_block_t  setup_boundary;     /* cursor boundary (10 bytes) */
	sd_block_hdr_t   setup_row_hdr;          /* row-level cursor (11 bytes) */
	sd_cursor_rect_t setup_row_rects[4];     /* 4 default positions */
	sd_block_hdr_t   setup_col_hdr;          /* column-level cursor (11 bytes) */
	sd_cursor_rect_t setup_col_rects[8];     /* 8 column positions */
	sd_block_hdr_t   setup_char_hdr;         /* char-level cursor (11 bytes) */
	sd_cursor_rect_t setup_char_rects[33];   /* 33 character-cell positions */
	sd_block_hdr_t   ctrl_row[3];            /* 3 row control handlers */
	sd_value_entry_t value_table_row1[5];    /* row 1 value display (4 + terminator) */
	sd_value_entry_t value_table_row2[5];    /* row 2 value display (4 + terminator) */
	sd_value_entry_t value_table_row3[5];    /* row 3 value display (4 + terminator) */

	/* === Chord Recognition Bitmap (64 bytes: 0x91=enabled, 0x2a=disabled) === */
	uint8_t chord_bitmap[64];

	/* === Track Status Widgets (360 bytes, 24 × sd_widget_t) === */
	sd_widget_t track_status_widgets[24];

	/* === Bottom Bar (143 bytes) === */
	uint8_t bottom_bar_marker[3];
	sd_filled_rect_t bottom_bar_rects[8];
	sd_hline_t bottom_bar_dividers[6];
} screendata_main_t;

_Static_assert(sizeof(screendata_main_t) == 3531,
	"ScreenData_Main must be exactly 3531 bytes");

/* ROM address where this struct is placed by the linker */
#define SCREENDATA_MAIN_BASE  0x00E0BB90u

/* Self-referential data pointer: handler fields that reference other parts of this struct */
#define SD_PTR(field)  (SCREENDATA_MAIN_BASE + offsetof(screendata_main_t, field))

const screendata_main_t StyleUI_ScreenData_Main
	__attribute__((section(".text"), used)) = {

	/* Chord box 1 (x=10..70) */
	.box1_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 10, .y = 35 }, .p2 = { .x = 39, .y = 35 } },
	.box1_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 48, .y = 35 }, .p2 = { .x = 70, .y = 35 } },
	.box1_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 10, .y = 36 }, .p2 = { .x = 10, .y = 39 } },
	.box1_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 70, .y = 36 }, .p2 = { .x = 70, .y = 39 } },
	.box1_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04b5, .label = { 0x15 } },
	/* Chord box 2 (x=74..134) */
	.box2_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 35 }, .p2 = { .x = 103, .y = 35 } },
	.box2_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 112, .y = 35 }, .p2 = { .x = 134, .y = 35 } },
	.box2_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 74, .y = 36 }, .p2 = { .x = 74, .y = 39 } },
	.box2_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 134, .y = 36 }, .p2 = { .x = 134, .y = 39 } },
	.box2_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04bd, .label = { 0x15 } },
	/* Chord box 3 (x=138..198) */
	.box3_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 35 }, .p2 = { .x = 167, .y = 35 } },
	.box3_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 176, .y = 35 }, .p2 = { .x = 198, .y = 35 } },
	.box3_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 138, .y = 36 }, .p2 = { .x = 138, .y = 39 } },
	.box3_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 198, .y = 36 }, .p2 = { .x = 198, .y = 39 } },
	.box3_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04c5, .label = { 0x15 } },
	/* Chord box 4 (x=202..262, different element order) */
	.box4_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 202, .y = 36 }, .p2 = { .x = 202, .y = 39 } },
	.box4_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 262, .y = 36 }, .p2 = { .x = 262, .y = 39 } },
	.box4_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04cd, .label = { 0x15 } },
	.box4_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 35 }, .p2 = { .x = 231, .y = 35 } },
	.box4_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 240, .y = 35 }, .p2 = { .x = 262, .y = 35 } },

	/* Grid row 1 (y=80) */
	.grid1_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 75 }, .p2 = { .x = 5, .y = 79 } },
	.grid1_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 80 }, .p2 = { .x = 73, .y = 80 } },
	.grid1_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 75 }, .p2 = { .x = 73, .y = 79 } },
	.grid1_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 80 }, .p2 = { .x = 137, .y = 80 } },
	.grid1_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 75 }, .p2 = { .x = 137, .y = 79 } },
	.grid1_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 80 }, .p2 = { .x = 201, .y = 80 } },
	.grid1_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 75 }, .p2 = { .x = 201, .y = 79 } },
	.grid1_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 80 }, .p2 = { .x = 265, .y = 80 } },
	.grid1_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 75 }, .p2 = { .x = 265, .y = 79 } },
	/* Grid row 2 (y=125) */
	.grid2_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 120 }, .p2 = { .x = 5, .y = 124 } },
	.grid2_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 125 }, .p2 = { .x = 73, .y = 125 } },
	.grid2_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 120 }, .p2 = { .x = 73, .y = 124 } },
	.grid2_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 125 }, .p2 = { .x = 137, .y = 125 } },
	.grid2_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 120 }, .p2 = { .x = 137, .y = 124 } },
	.grid2_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 125 }, .p2 = { .x = 201, .y = 125 } },
	.grid2_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 120 }, .p2 = { .x = 201, .y = 124 } },
	.grid2_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 125 }, .p2 = { .x = 265, .y = 125 } },
	.grid2_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 120 }, .p2 = { .x = 265, .y = 124 } },
	/* Grid row 3 (y=170) */
	.grid3_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 165 }, .p2 = { .x = 5, .y = 169 } },
	.grid3_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 170 }, .p2 = { .x = 73, .y = 170 } },
	.grid3_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 165 }, .p2 = { .x = 73, .y = 169 } },
	.grid3_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 170 }, .p2 = { .x = 137, .y = 170 } },
	.grid3_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 165 }, .p2 = { .x = 137, .y = 169 } },
	.grid3_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 170 }, .p2 = { .x = 201, .y = 170 } },
	.grid3_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 165 }, .p2 = { .x = 201, .y = 169 } },
	.grid3_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 170 }, .p2 = { .x = 265, .y = 170 } },
	.grid3_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 165 }, .p2 = { .x = 265, .y = 169 } },

	/* Row label references */
	.row_label_1 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x1187, .data = { 0x00, 0x00, 0x06, 0x41, 0x06, 0x03 } },
	.row_label_2 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x1189, .data = { 0x00, 0x00, 0x06, 0x49, 0x0d, 0x03 } },
	.row_label_3 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x118b, .data = { 0x00, 0x00, 0x06, 0x51, 0x14, 0x03 } },
	.row_ref_1   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x0641, .label = { 0x2d } },
	.row_ref_2   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x0d49, .label = { 0x2d } },
	.row_ref_3   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x1451, .label = { 0x2d } },
	.nop_pad     = { .opcode = 0x00, .length = 0x0a, .data = { 0x8e, 0x11, 0xff, 0x00, 0x06, 0x95, 0x02, 0x02 } },

	/* Control widgets (complex interleaved STRING + WIDGET data) */
	.control_widgets = {
		0x02, 0x0f, 0x9b, 0x11, 0x00, 0x00, 0x06, 0xca, 0x0e, 0x00, 0x00, 0x1e, 0x00, 0x21, 0x1c, 0x20,
		0x20, 0x20, 0x20, 0x45, 0x4e, 0x44, 0x20, 0x52, 0x45, 0x50, 0x20, 0x1b, 0x20, 0x20, 0x20, 0x1c,
		0x20, 0x20, 0x20, 0x02, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x06, 0xf8, 0x0e, 0x00, 0x00, 0x1e, 0x00,
		0x21, 0x08, 0x02, 0x0f, 0x91, 0x11, 0x03, 0x00, 0x06, 0xcc, 0xc8, 0xe0, 0x00, 0x01, 0x00, 0x51,
		0x0a, 0x02, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x06, 0x16, 0x0f, 0x00, 0x00, 0x1e, 0x00, 0x29, 0x0f,
		0x02, 0x0f, 0x92, 0x11, 0x0c, 0x82, 0x06, 0xcc, 0xc8, 0xe0, 0x00, 0x01, 0x00, 0x59, 0x11, 0x02,
		0x0f, 0x00, 0x00, 0x00, 0x00, 0x06, 0x34, 0x0f, 0x00, 0x00, 0x1e, 0x00, 0x31, 0x16, 0x02, 0x0f,
		0x93, 0x11, 0x30, 0x84, 0x06, 0xcc, 0xc8, 0xe0, 0x00, 0x01, 0x00, 0x61, 0x18,
	},

	/* Parameter value widgets (handler 0xe0bd98) */
	.param_widgets = {
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119b, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 33, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119c, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 37, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119d, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 41, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119e, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 45, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119f, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 49, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a0, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 53, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a1, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 57, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a2, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 61, .y = 8 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 41, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 45, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 49, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 53, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 57, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 61, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 65, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 69, .y = 15 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 49, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 53, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 57, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 61, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 65, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 69, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 73, .y = 22 },  /* param_value */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(control_widgets) + 15, .param = 4, .x = 77, .y = 22 },  /* param_value */
	},

	/* Chord root/type/quality widgets (3 rows × 8 cells × 3 layers) */
	.chord_widgets = {
		/* Row 1 (y=8): 8 cells × (root + type + quality) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 33, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 35, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 35, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 37, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 39, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 39, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 41, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0d, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 43, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 43, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 45, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 47, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 47, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 49, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 51, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 51, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 53, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 55, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 55, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 57, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 59, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 59, .y = 8 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 61, .y = 8 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 63, .y = 8 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 63, .y = 8 },  /* chord_quality */
		/* Row 2 (y=15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 41, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 43, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 43, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 45, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 47, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 47, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 49, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 51, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 51, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 53, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 55, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 55, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 57, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 59, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 59, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 61, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 63, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 63, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x14, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 65, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 67, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 67, .y = 15 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 69, .y = 15 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 71, .y = 15 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 71, .y = 15 },  /* chord_quality */
		/* Row 3 (y=22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 49, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 51, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 51, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 53, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 55, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 55, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 57, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 59, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 59, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 61, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 63, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 63, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 65, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 67, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 67, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 69, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 71, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 71, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 73, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 75, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 75, .y = 22 },  /* chord_quality */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_root_names), .param = 2, .x = 77, .y = 22 },  /* chord_root */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = SD_PTR(chord_type_names), .param = 5, .x = 79, .y = 22 },  /* chord_type */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = SD_PTR(setup_text) + 38, .param = 2, .x = 79, .y = 22 },  /* chord_quality */
	},

	.chord_root_names = {
		CHORD_ROOT(  ' ',   ' '),  /* pad */
		CHORD_ROOT(  'C',   ' '),  /* C */
		CHORD_ROOT(  'D',  FLAT),  /* Db */
		CHORD_ROOT(  'D',   ' '),  /* D */
		CHORD_ROOT(  'E',  FLAT),  /* Eb */
		CHORD_ROOT(  'E',   ' '),  /* E */
		CHORD_ROOT(  'F',   ' '),  /* F */
		CHORD_ROOT(  'F', SHARP),  /* F# */
		CHORD_ROOT(  'G',   ' '),  /* G */
		CHORD_ROOT(  'A',  FLAT),  /* Ab */
		CHORD_ROOT(  'A',   ' '),  /* A */
		CHORD_ROOT(  'B',  FLAT),  /* Bb */
		CHORD_ROOT(  'B',   ' '),  /* B */
		CHORD_ROOT(  ' ',   ' '),  /* pad */
		CHORD_ROOT(  ' ',   ' '),  /* pad */
		CHORD_ROOT(  ' ',   ' '),  /* pad */
	},

	.chord_type_names = {
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* (none) */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* (none) */
		CHORD_TYPE(  '7',   ' ',   ' ',   ' ',   ' '),  /* 7 */
		CHORD_TYPE(  'M',   'a',   'j',   '7',   ' '),  /* Maj7 */
		CHORD_TYPE(  'a',   'u',   'g',   ' ',   ' '),  /* aug */
		CHORD_TYPE(  'm',   'i',   'n',   ' ',   ' '),  /* min */
		CHORD_TYPE(  'm',   'i',   'n',   '7',   ' '),  /* min7 */
		CHORD_TYPE(  'd',   'i',   'm',   ' ',   ' '),  /* dim */
		CHORD_TYPE(  'm',   '7',  FLAT,   '5',   ' '),  /* m7♭5 */
		CHORD_TYPE(  'm',   'M',   '7',   ' ',   ' '),  /* mM7 */
		CHORD_TYPE(  '7',   's',   'u',   's',   '4'),  /* 7sus4 */
		CHORD_TYPE(  '6',   ' ',   ' ',   ' ',   ' '),  /* 6 */
		CHORD_TYPE(  'a',   'u',   'g',   '7',   ' '),  /* aug7 */
		CHORD_TYPE(  ' ',   ' ',  FLAT,   '5',   ' '),  /* ♭5 */
		CHORD_TYPE(  '7',   ' ',  FLAT,   '5',   ' '),  /* 7♭5 */
		CHORD_TYPE(  '7',   '9',   ' ',   ' ',   ' '),  /* 79 */
		CHORD_TYPE(  '7',   ' ',  FLAT,   '9',   ' '),  /* 7♭9 */
		CHORD_TYPE(  'M',   '7',   '9',   ' ',   ' '),  /* M79 */
		CHORD_TYPE(  '6',   '9',   ' ',   ' ',   ' '),  /* 69 */
		CHORD_TYPE(  'm',   '6',   ' ',   ' ',   ' '),  /* m6 */
		CHORD_TYPE(  'm',   ' ',  FLAT,   '5',   ' '),  /* m♭5 */
		CHORD_TYPE(  'm',   '7',   '9',   ' ',   ' '),  /* m79 */
		CHORD_TYPE(  'm',   '6',   '9',   ' ',   ' '),  /* m69 */
		CHORD_TYPE(  's',   'u',   's',   '4',   ' '),  /* sus4 */
		CHORD_TYPE(  '7',   ' ', SHARP,   '9',   ' '),  /* 7♯9 */
		CHORD_TYPE(  'M',   '7',  FLAT,   '5',   ' '),  /* M7♭5 */
		CHORD_TYPE(  'M',   '7', SHARP,   '5',   ' '),  /* M7♯5 */
		CHORD_TYPE(  'm',   'M',   '7',  FLAT,   '5'),  /* mM7♭5 */
		CHORD_TYPE(  ' ',   ' ',   ' ',   '1',   '3'),  /* 13 */
		CHORD_TYPE(  '9', SHARP,   '5',   ' ',   ' '),  /* 9♯5 */
		CHORD_TYPE( FLAT,   '9',   ' ',   '1',   '3'),  /* ♭9 13 */
		CHORD_TYPE(SHARP,   '9',   ' ',   '1',   '3'),  /* ♯9 13 */
		CHORD_TYPE(  ' ',   ' ',  FLAT,   '1',   '3'),  /* ♭13 */
		CHORD_TYPE( FLAT,   '9',  FLAT,   '1',   '3'),  /* ♭9♭13 */
		CHORD_TYPE(SHARP,   '9',  FLAT,   '1',   '3'),  /* ♯9♭13 */
		CHORD_TYPE(  ' ',   ' ',   ' ',   '1',   '3'),  /* 13 */
		CHORD_TYPE(  ' ',   ' ',  FLAT,   '1',   '3'),  /* ♭13 */
		CHORD_TYPE(  '7',   ' ', SHARP,   '1',   '1'),  /* 7♯11 */
		CHORD_TYPE(  'm',   '7',   ' ',   '1',   '1'),  /* m7 11 */
		CHORD_TYPE(  '+',   '7', SHARP,   '1',   '1'),  /* +7♯11 */
		CHORD_TYPE(  ' ',   'a',   'd',   'd',   '9'),  /* add9 */
		CHORD_TYPE(  'm',   'a',   'd',   'd',   '9'),  /* madd9 */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		CHORD_TYPE(  ' ',   ' ',   ' ',   ' ',   ' '),  /* pad */
		' ', ' ',
	},

	/* Footer labels (40 spaces) */
	.footer_labels = {
		' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ',
	},

	/* Setup text buffer (40 spaces) */
	.setup_text = {
		' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ',
	},
	.setup_label = {
		'_', ' ', '7', ' ', '6', ' ',
	},
	.setup_config = {
		.type = 0x0e, .length = 0x08,
		.id = 0x1159, .flags = 0x0021, .param = 0x000b,
	},
	.setup_boundary = {
		.type = 0x1b, .length = 0x0a,
		.p1 = { .x = 264, .y = 111 }, .p2 = { .x = 264, .y = 121 },
	},
	/* Row-level cursor (4 default positions) */
	.setup_row_hdr = {
		.type = SD_BLOCK_SETUP, .length = 0x0b,
		.id = 0x1192, .flags = 0x820c,
		.tag = 0x05, .handler = SD_PTR(setup_row_rects),
	},
	.setup_row_rects = {
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
	},
	/* Column-level cursor (8 columns, 32px spacing) */
	.setup_col_hdr = {
		.type = SD_BLOCK_SETUP, .length = 0x0b,
		.id = 0x1191, .flags = 0x00ff,
		.tag = 0x05, .handler = SD_PTR(setup_col_rects),
	},
	.setup_col_rects = {
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
		{ .x1 =  40, .y1 = 111, .x2 =  48, .y2 = 121 },
		{ .x1 =  72, .y1 = 111, .x2 =  80, .y2 = 121 },
		{ .x1 = 104, .y1 = 111, .x2 = 112, .y2 = 121 },
		{ .x1 = 136, .y1 = 111, .x2 = 144, .y2 = 121 },
		{ .x1 = 168, .y1 = 111, .x2 = 176, .y2 = 121 },
		{ .x1 = 200, .y1 = 111, .x2 = 208, .y2 = 121 },
		{ .x1 = 232, .y1 = 111, .x2 = 240, .y2 = 121 },
	},
	/* Character-level cursor (33 cells, 8px spacing) */
	.setup_char_hdr = {
		.type = SD_BLOCK_SETUP, .length = 0x0b,
		.id = 0x118f, .flags = 0x00ff,
		.tag = 0x05, .handler = SD_PTR(setup_char_rects),
	},
	.setup_char_rects = {
		{ .x1 =   0, .y1 =   0, .x2 =   0, .y2 =   0 },
		{ .x1 =   8, .y1 = 111, .x2 =  16, .y2 = 121 },
		{ .x1 =  16, .y1 = 111, .x2 =  24, .y2 = 121 },
		{ .x1 =  24, .y1 = 111, .x2 =  32, .y2 = 121 },
		{ .x1 =  32, .y1 = 111, .x2 =  40, .y2 = 121 },
		{ .x1 =  40, .y1 = 111, .x2 =  48, .y2 = 121 },
		{ .x1 =  48, .y1 = 111, .x2 =  56, .y2 = 121 },
		{ .x1 =  56, .y1 = 111, .x2 =  64, .y2 = 121 },
		{ .x1 =  64, .y1 = 111, .x2 =  72, .y2 = 121 },
		{ .x1 =  72, .y1 = 111, .x2 =  80, .y2 = 121 },
		{ .x1 =  80, .y1 = 111, .x2 =  88, .y2 = 121 },
		{ .x1 =  88, .y1 = 111, .x2 =  96, .y2 = 121 },
		{ .x1 =  96, .y1 = 111, .x2 = 104, .y2 = 121 },
		{ .x1 = 104, .y1 = 111, .x2 = 112, .y2 = 121 },
		{ .x1 = 112, .y1 = 111, .x2 = 120, .y2 = 121 },
		{ .x1 = 120, .y1 = 111, .x2 = 128, .y2 = 121 },
		{ .x1 = 128, .y1 = 111, .x2 = 136, .y2 = 121 },
		{ .x1 = 136, .y1 = 111, .x2 = 144, .y2 = 121 },
		{ .x1 = 144, .y1 = 111, .x2 = 152, .y2 = 121 },
		{ .x1 = 152, .y1 = 111, .x2 = 160, .y2 = 121 },
		{ .x1 = 160, .y1 = 111, .x2 = 168, .y2 = 121 },
		{ .x1 = 168, .y1 = 111, .x2 = 176, .y2 = 121 },
		{ .x1 = 176, .y1 = 111, .x2 = 184, .y2 = 121 },
		{ .x1 = 184, .y1 = 111, .x2 = 192, .y2 = 121 },
		{ .x1 = 192, .y1 = 111, .x2 = 200, .y2 = 121 },
		{ .x1 = 200, .y1 = 111, .x2 = 208, .y2 = 121 },
		{ .x1 = 208, .y1 = 111, .x2 = 216, .y2 = 121 },
		{ .x1 = 216, .y1 = 111, .x2 = 224, .y2 = 121 },
		{ .x1 = 224, .y1 = 111, .x2 = 232, .y2 = 121 },
		{ .x1 = 232, .y1 = 111, .x2 = 240, .y2 = 121 },
		{ .x1 = 240, .y1 = 111, .x2 = 248, .y2 = 121 },
		{ .x1 = 248, .y1 = 111, .x2 = 256, .y2 = 121 },
		{ .x1 = 256, .y1 = 111, .x2 = 264, .y2 = 121 },
	},

	/* Row control handlers */
	.ctrl_row = {
		{ .type = SD_BLOCK_CTRL, .length = 0x0b,
		  .id = 0x119b, .flags = 0x00ff,
		  .tag = 0x0e, .handler = SD_PTR(value_table_row1) },
		{ .type = SD_BLOCK_CTRL, .length = 0x0b,
		  .id = 0x119c, .flags = 0x00ff,
		  .tag = 0x0e, .handler = SD_PTR(value_table_row2) },
		{ .type = SD_BLOCK_CTRL, .length = 0x0b,
		  .id = 0x119d, .flags = 0x00ff,
		  .tag = 0x0e, .handler = SD_PTR(value_table_row3) },
	},

	/* Row 1 value display (4 widths + terminator, right-aligned) */
	.value_table_row1 = {
		{ .x =  81, .y = 10, .width = 32, .height = 10 },
		{ .x =  89, .y = 10, .width = 24, .height = 10 },
		{ .x =  97, .y = 10, .width = 16, .height = 10 },
		{ .x = 105, .y = 10, .width =  8, .height = 10 },
		{ .x = 0, .y = 0, .width = 1, .height = 1 },  /* terminator */
	},
	/* Row 2 value display (4 widths + terminator, right-aligned) */
	.value_table_row2 = {
		{ .x =  89, .y = 17, .width = 32, .height = 10 },
		{ .x =  97, .y = 17, .width = 24, .height = 10 },
		{ .x = 105, .y = 17, .width = 16, .height = 10 },
		{ .x = 113, .y = 17, .width =  8, .height = 10 },
		{ .x = 0, .y = 0, .width = 1, .height = 1 },  /* terminator */
	},
	/* Row 3 value display (4 widths + terminator, right-aligned) */
	.value_table_row3 = {
		{ .x =  97, .y = 24, .width = 32, .height = 10 },
		{ .x = 105, .y = 24, .width = 24, .height = 10 },
		{ .x = 113, .y = 24, .width = 16, .height = 10 },
		{ .x = 121, .y = 24, .width =  8, .height = 10 },
		{ .x = 0, .y = 0, .width = 1, .height = 1 },  /* terminator */
	},

	/* Chord recognition bitmap (0x91=enabled, 0x2a=disabled) */
	.chord_bitmap = {
		0x91, 0x91, 0x91, 0x91, 0x2a, 0x91, 0x91, 0x91, 0x91, 0x2a, 0x91, 0x91, 0x2a, 0x2a, 0x91, 0x91,
		0x91, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x91, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x2a, 0x91,
		0x91, 0x91, 0x91, 0x2a, 0x2a, 0x91, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x2a, 0x2a, 0x2a, 0x91, 0x2a,
		0x91, 0x91, 0x2a, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a,
	},

	/* Track status widgets (handler 0xe0c8cc, flags=0x8560) */
	.track_status_widgets = {
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 81, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b4, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 85, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b5, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 89, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b6, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 93, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b7, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 97, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b8, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 101, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b9, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 105, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ba, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 109, .y = 10 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1192, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 89, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1193, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 93, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1194, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 97, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1195, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 101, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1196, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 105, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1197, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 109, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1198, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 113, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1199, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 117, .y = 17 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119a, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 97, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119b, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 101, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119c, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 105, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119d, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 109, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119e, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 113, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119f, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 117, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a0, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 121, .y = 24 },  /* track_status */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a1, .flags = 0x8560, .ref_tag = 0x06, .handler = SD_PTR(bottom_bar_marker), .param = 1, .x = 125, .y = 24 },  /* track_status */
	},

	/* Bottom bar marker */
	.bottom_bar_marker = {
		0x20, 0x2a, 0x91,
	},

	/* Bottom bar: 8 FILLED_RECTs at y=210-236 */
	.bottom_bar_rects = {
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 5, .y = 210 }, .bottom_right = { .x = 35, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 45, .y = 210 }, .bottom_right = { .x = 75, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 85, .y = 210 }, .bottom_right = { .x = 115, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 125, .y = 210 }, .bottom_right = { .x = 155, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 165, .y = 210 }, .bottom_right = { .x = 195, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 205, .y = 210 }, .bottom_right = { .x = 235, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 245, .y = 210 }, .bottom_right = { .x = 275, .y = 236 } },
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 285, .y = 210 }, .bottom_right = { .x = 315, .y = 236 } },
	},

	/* Bottom bar: 6 HLINE dividers at y=223 */
	.bottom_bar_dividers = {
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 223 }, .p2 = { .x = 35, .y = 223 } },
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 45, .y = 223 }, .p2 = { .x = 75, .y = 223 } },
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 85, .y = 223 }, .p2 = { .x = 115, .y = 223 } },
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 125, .y = 223 }, .p2 = { .x = 155, .y = 223 } },
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 165, .y = 223 }, .p2 = { .x = 195, .y = 223 } },
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 205, .y = 223 }, .p2 = { .x = 235, .y = 223 } },
	},
};
