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
	uint8_t setup_control_data[580];

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

const screendata_main_t StyleUI_ScreenData_Main
	__attribute__((section(".text"), used)) = {

	/* Chord box 1 (x=10..70) */
	.box1_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 10, .y = 35 }, .p2 = { .x = 39, .y = 35 } },  /* (10,35)-(39,35) */
	.box1_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 48, .y = 35 }, .p2 = { .x = 70, .y = 35 } },  /* (48,35)-(70,35) */
	.box1_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 10, .y = 36 }, .p2 = { .x = 10, .y = 39 } },  /* (10,36)-(10,39) */
	.box1_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 70, .y = 36 }, .p2 = { .x = 70, .y = 39 } },  /* (70,36)-(70,39) */
	.box1_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04b5, .label = { 0x15 } },  /* addr=0x04b5 param=21 */
	/* Chord box 2 (x=74..134) */
	.box2_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 35 }, .p2 = { .x = 103, .y = 35 } },  /* (74,35)-(103,35) */
	.box2_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 112, .y = 35 }, .p2 = { .x = 134, .y = 35 } },  /* (112,35)-(134,35) */
	.box2_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 74, .y = 36 }, .p2 = { .x = 74, .y = 39 } },  /* (74,36)-(74,39) */
	.box2_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 134, .y = 36 }, .p2 = { .x = 134, .y = 39 } },  /* (134,36)-(134,39) */
	.box2_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04bd, .label = { 0x15 } },  /* addr=0x04bd param=21 */
	/* Chord box 3 (x=138..198) */
	.box3_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 35 }, .p2 = { .x = 167, .y = 35 } },  /* (138,35)-(167,35) */
	.box3_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 176, .y = 35 }, .p2 = { .x = 198, .y = 35 } },  /* (176,35)-(198,35) */
	.box3_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 138, .y = 36 }, .p2 = { .x = 138, .y = 39 } },  /* (138,36)-(138,39) */
	.box3_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 198, .y = 36 }, .p2 = { .x = 198, .y = 39 } },  /* (198,36)-(198,39) */
	.box3_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04c5, .label = { 0x15 } },  /* addr=0x04c5 param=21 */
	/* Chord box 4 (x=202..262, different element order) */
	.box4_vline_left  = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 202, .y = 36 }, .p2 = { .x = 202, .y = 39 } },  /* (202,36)-(202,39) */
	.box4_vline_right = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 262, .y = 36 }, .p2 = { .x = 262, .y = 39 } },  /* (262,36)-(262,39) */
	.box4_ref         = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x04cd, .label = { 0x15 } },  /* addr=0x04cd param=21 */
	.box4_hline_left  = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 35 }, .p2 = { .x = 231, .y = 35 } },  /* (202,35)-(231,35) */
	.box4_hline_right = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 240, .y = 35 }, .p2 = { .x = 262, .y = 35 } },  /* (240,35)-(262,35) */

	/* Grid row 1 (y=80) */
	.grid1_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 75 }, .p2 = { .x = 5, .y = 79 } },  /* (5,75)-(5,79) */
	.grid1_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 80 }, .p2 = { .x = 73, .y = 80 } },  /* (5,80)-(73,80) */
	.grid1_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 75 }, .p2 = { .x = 73, .y = 79 } },  /* (73,75)-(73,79) */
	.grid1_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 80 }, .p2 = { .x = 137, .y = 80 } },  /* (74,80)-(137,80) */
	.grid1_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 75 }, .p2 = { .x = 137, .y = 79 } },  /* (137,75)-(137,79) */
	.grid1_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 80 }, .p2 = { .x = 201, .y = 80 } },  /* (138,80)-(201,80) */
	.grid1_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 75 }, .p2 = { .x = 201, .y = 79 } },  /* (201,75)-(201,79) */
	.grid1_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 80 }, .p2 = { .x = 265, .y = 80 } },  /* (202,80)-(265,80) */
	.grid1_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 75 }, .p2 = { .x = 265, .y = 79 } },  /* (265,75)-(265,79) */
	/* Grid row 2 (y=125) */
	.grid2_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 120 }, .p2 = { .x = 5, .y = 124 } },  /* (5,120)-(5,124) */
	.grid2_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 125 }, .p2 = { .x = 73, .y = 125 } },  /* (5,125)-(73,125) */
	.grid2_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 120 }, .p2 = { .x = 73, .y = 124 } },  /* (73,120)-(73,124) */
	.grid2_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 125 }, .p2 = { .x = 137, .y = 125 } },  /* (74,125)-(137,125) */
	.grid2_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 120 }, .p2 = { .x = 137, .y = 124 } },  /* (137,120)-(137,124) */
	.grid2_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 125 }, .p2 = { .x = 201, .y = 125 } },  /* (138,125)-(201,125) */
	.grid2_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 120 }, .p2 = { .x = 201, .y = 124 } },  /* (201,120)-(201,124) */
	.grid2_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 125 }, .p2 = { .x = 265, .y = 125 } },  /* (202,125)-(265,125) */
	.grid2_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 120 }, .p2 = { .x = 265, .y = 124 } },  /* (265,120)-(265,124) */
	/* Grid row 3 (y=170) */
	.grid3_corner_1 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 5, .y = 165 }, .p2 = { .x = 5, .y = 169 } },  /* (5,165)-(5,169) */
	.grid3_bar_1    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 170 }, .p2 = { .x = 73, .y = 170 } },  /* (5,170)-(73,170) */
	.grid3_corner_2 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 73, .y = 165 }, .p2 = { .x = 73, .y = 169 } },  /* (73,165)-(73,169) */
	.grid3_bar_2    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 74, .y = 170 }, .p2 = { .x = 137, .y = 170 } },  /* (74,170)-(137,170) */
	.grid3_corner_3 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 137, .y = 165 }, .p2 = { .x = 137, .y = 169 } },  /* (137,165)-(137,169) */
	.grid3_bar_3    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 138, .y = 170 }, .p2 = { .x = 201, .y = 170 } },  /* (138,170)-(201,170) */
	.grid3_corner_4 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 201, .y = 165 }, .p2 = { .x = 201, .y = 169 } },  /* (201,165)-(201,169) */
	.grid3_bar_4    = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 202, .y = 170 }, .p2 = { .x = 265, .y = 170 } },  /* (202,170)-(265,170) */
	.grid3_corner_5 = { .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, .p1 = { .x = 265, .y = 165 }, .p2 = { .x = 265, .y = 169 } },  /* (265,165)-(265,169) */

	/* Row label references */
	.row_label_1 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x1187, .data = { 0x00, 0x00, 0x06, 0x41, 0x06, 0x03 } },  /* id=0x1187 row_label_1 */
	.row_label_2 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x1189, .data = { 0x00, 0x00, 0x06, 0x49, 0x0d, 0x03 } },  /* id=0x1189 row_label_2 */
	.row_label_3 = { .opcode = SD_OP_LABELED_REF, .length = 0x0a, .id = 0x118b, .data = { 0x00, 0x00, 0x06, 0x51, 0x14, 0x03 } },  /* id=0x118b row_label_3 */
	.row_ref_1   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x0641, .label = { 0x2d } },  /* addr=0x0641 param=45 param=45 */
	.row_ref_2   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x0d49, .label = { 0x2d } },  /* addr=0x0d49 param=45 param=45 */
	.row_ref_3   = { .opcode = SD_OP_LABELED_REF, .length = 5, .addr = 0x1451, .label = { 0x2d } },  /* addr=0x1451 param=45 param=45 */
	.nop_pad     = { .opcode = 0x00, .length = 0x0a, .data = { 0x8e, 0x11, 0xff, 0x00, 0x06, 0x95, 0x02, 0x02 } }, /* NOP/PAD */

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
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119b, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 33, .y = 8 },  /* param_value pos=(33,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119c, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 37, .y = 8 },  /* param_value pos=(37,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119d, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 41, .y = 8 },  /* param_value pos=(41,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119e, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 45, .y = 8 },  /* param_value pos=(45,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119f, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 49, .y = 8 },  /* param_value pos=(49,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a0, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 53, .y = 8 },  /* param_value pos=(53,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a1, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 57, .y = 8 },  /* param_value pos=(57,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a2, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 61, .y = 8 },  /* param_value pos=(61,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 41, .y = 15 },  /* param_value pos=(41,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 45, .y = 15 },  /* param_value pos=(45,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 49, .y = 15 },  /* param_value pos=(49,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 53, .y = 15 },  /* param_value pos=(53,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 57, .y = 15 },  /* param_value pos=(57,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 61, .y = 15 },  /* param_value pos=(61,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 65, .y = 15 },  /* param_value pos=(65,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 69, .y = 15 },  /* param_value pos=(69,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 49, .y = 22 },  /* param_value pos=(49,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 53, .y = 22 },  /* param_value pos=(53,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 57, .y = 22 },  /* param_value pos=(57,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 61, .y = 22 },  /* param_value pos=(61,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 65, .y = 22 },  /* param_value pos=(65,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 69, .y = 22 },  /* param_value pos=(69,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 73, .y = 22 },  /* param_value pos=(73,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0bd98, .param = 4, .x = 77, .y = 22 },  /* param_value pos=(77,22) */
	},

	/* Chord root/type/quality widgets (3 rows × 8 cells × 3 layers) */
	.chord_widgets = {
		/* Row 1 (y=8): 8 cells × (root + type + quality) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 33, .y = 8 },  /* chord_root pos=(33,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 35, .y = 8 },  /* chord_type pos=(35,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 35, .y = 8 },  /* chord_quality pos=(35,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 37, .y = 8 },  /* chord_root pos=(37,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 39, .y = 8 },  /* chord_type pos=(39,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 39, .y = 8 },  /* chord_quality pos=(39,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 41, .y = 8 },  /* chord_root pos=(41,8) */
		{ .opcode = 0x02, .subtype = 0x0d, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 43, .y = 8 },  /* chord_type pos=(43,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 43, .y = 8 },  /* chord_quality pos=(43,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 45, .y = 8 },  /* chord_root pos=(45,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 47, .y = 8 },  /* chord_type pos=(47,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 47, .y = 8 },  /* chord_quality pos=(47,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 49, .y = 8 },  /* chord_root pos=(49,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 51, .y = 8 },  /* chord_type pos=(51,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 51, .y = 8 },  /* chord_quality pos=(51,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 53, .y = 8 },  /* chord_root pos=(53,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 55, .y = 8 },  /* chord_type pos=(55,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 55, .y = 8 },  /* chord_quality pos=(55,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 57, .y = 8 },  /* chord_root pos=(57,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 59, .y = 8 },  /* chord_type pos=(59,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 59, .y = 8 },  /* chord_quality pos=(59,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 61, .y = 8 },  /* chord_root pos=(61,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 63, .y = 8 },  /* chord_type pos=(63,8) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 63, .y = 8 },  /* chord_quality pos=(63,8) */
		/* Row 2 (y=15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 41, .y = 15 },  /* chord_root pos=(41,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 43, .y = 15 },  /* chord_type pos=(43,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 43, .y = 15 },  /* chord_quality pos=(43,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 45, .y = 15 },  /* chord_root pos=(45,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 47, .y = 15 },  /* chord_type pos=(47,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 47, .y = 15 },  /* chord_quality pos=(47,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 49, .y = 15 },  /* chord_root pos=(49,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 51, .y = 15 },  /* chord_type pos=(51,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 51, .y = 15 },  /* chord_quality pos=(51,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 53, .y = 15 },  /* chord_root pos=(53,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 55, .y = 15 },  /* chord_type pos=(55,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 55, .y = 15 },  /* chord_quality pos=(55,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 57, .y = 15 },  /* chord_root pos=(57,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 59, .y = 15 },  /* chord_type pos=(59,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 59, .y = 15 },  /* chord_quality pos=(59,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 61, .y = 15 },  /* chord_root pos=(61,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 63, .y = 15 },  /* chord_type pos=(63,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 63, .y = 15 },  /* chord_quality pos=(63,15) */
		{ .opcode = 0x02, .subtype = 0x14, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 65, .y = 15 },  /* chord_root pos=(65,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 67, .y = 15 },  /* chord_type pos=(67,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 67, .y = 15 },  /* chord_quality pos=(67,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 69, .y = 15 },  /* chord_root pos=(69,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 71, .y = 15 },  /* chord_type pos=(71,15) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 71, .y = 15 },  /* chord_quality pos=(71,15) */
		/* Row 3 (y=22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a3, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 49, .y = 22 },  /* chord_root pos=(49,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a4, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 51, .y = 22 },  /* chord_type pos=(51,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 51, .y = 22 },  /* chord_quality pos=(51,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a5, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 53, .y = 22 },  /* chord_root pos=(53,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a6, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 55, .y = 22 },  /* chord_type pos=(55,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 55, .y = 22 },  /* chord_quality pos=(55,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a7, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 57, .y = 22 },  /* chord_root pos=(57,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a8, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 59, .y = 22 },  /* chord_type pos=(59,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 59, .y = 22 },  /* chord_quality pos=(59,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a9, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 61, .y = 22 },  /* chord_root pos=(61,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11aa, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 63, .y = 22 },  /* chord_type pos=(63,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 63, .y = 22 },  /* chord_quality pos=(63,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ab, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 65, .y = 22 },  /* chord_root pos=(65,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ac, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 67, .y = 22 },  /* chord_type pos=(67,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 67, .y = 22 },  /* chord_quality pos=(67,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ad, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 69, .y = 22 },  /* chord_root pos=(69,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ae, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 71, .y = 22 },  /* chord_type pos=(71,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 71, .y = 22 },  /* chord_quality pos=(71,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11af, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 73, .y = 22 },  /* chord_root pos=(73,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b0, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 75, .y = 22 },  /* chord_type pos=(75,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 75, .y = 22 },  /* chord_quality pos=(75,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b1, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3a6, .param = 2, .x = 77, .y = 22 },  /* chord_root pos=(77,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b2, .flags = 0x00ff, .ref_tag = 0x06, .handler = 0x00e0c3c6, .param = 5, .x = 79, .y = 22 },  /* chord_type pos=(79,22) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x0003, .ref_tag = 0x06, .handler = 0x00e0c506, .param = 2, .x = 79, .y = 22 },  /* chord_quality pos=(79,22) */
	},

	/* Chord root names: C Db D Eb E F F# G Ab A Bb B */
	.chord_root_names = {
		0x20, 0x20, 0x43, 0x20, 0x44, 0x88, 0x44, 0x20, 0x45, 0x88, 0x45, 0x20, 0x46, 0x20, 0x46, 0x8c,
		0x47, 0x20, 0x41, 0x88, 0x41, 0x20, 0x42, 0x88, 0x42, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	},

	/* Chord type names (Maj7, aug, min, dim, 7sus4, etc.) */
	.chord_type_names = {
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x37, 0x20, 0x20, 0x20, 0x20, 0x4d,
		0x61, 0x6a, 0x37, 0x20, 0x61, 0x75, 0x67, 0x20, 0x20, 0x6d, 0x69, 0x6e, 0x20, 0x20, 0x6d, 0x69,
		0x6e, 0x37, 0x20, 0x64, 0x69, 0x6d, 0x20, 0x20, 0x6d, 0x37, 0x88, 0x35, 0x20, 0x6d, 0x4d, 0x37,
		0x20, 0x20, 0x37, 0x73, 0x75, 0x73, 0x34, 0x36, 0x20, 0x20, 0x20, 0x20, 0x61, 0x75, 0x67, 0x37,
		0x20, 0x20, 0x20, 0x88, 0x35, 0x20, 0x37, 0x20, 0x88, 0x35, 0x20, 0x37, 0x39, 0x20, 0x20, 0x20,
		0x37, 0x20, 0x88, 0x39, 0x20, 0x4d, 0x37, 0x39, 0x20, 0x20, 0x36, 0x39, 0x20, 0x20, 0x20, 0x6d,
		0x36, 0x20, 0x20, 0x20, 0x6d, 0x20, 0x88, 0x35, 0x20, 0x6d, 0x37, 0x39, 0x20, 0x20, 0x6d, 0x36,
		0x39, 0x20, 0x20, 0x73, 0x75, 0x73, 0x34, 0x20, 0x37, 0x20, 0x8c, 0x39, 0x20, 0x4d, 0x37, 0x88,
		0x35, 0x20, 0x4d, 0x37, 0x8c, 0x35, 0x20, 0x6d, 0x4d, 0x37, 0x88, 0x35, 0x20, 0x20, 0x20, 0x31,
		0x33, 0x39, 0x8c, 0x35, 0x20, 0x20, 0x88, 0x39, 0x20, 0x31, 0x33, 0x8c, 0x39, 0x20, 0x31, 0x33,
		0x20, 0x20, 0x88, 0x31, 0x33, 0x88, 0x39, 0x88, 0x31, 0x33, 0x8c, 0x39, 0x88, 0x31, 0x33, 0x20,
		0x20, 0x20, 0x31, 0x33, 0x20, 0x20, 0x88, 0x31, 0x33, 0x37, 0x20, 0x8c, 0x31, 0x31, 0x6d, 0x37,
		0x20, 0x31, 0x31, 0x2b, 0x37, 0x8c, 0x31, 0x31, 0x20, 0x61, 0x64, 0x64, 0x39, 0x6d, 0x61, 0x64,
		0x64, 0x39, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20,
	},

	/* Footer labels and control bytes */
	.footer_labels = {
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	},

	/* SETUP/CONTROL blocks with coordinate arrays */
	.setup_control_data = {
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
		0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x5f, 0x20, 0x37, 0x20, 0x36, 0x20, 0x0e, 0x08,
		0x59, 0x11, 0x21, 0x00, 0x0b, 0x00, 0x1b, 0x0a, 0x08, 0x01, 0x6f, 0x00, 0x08, 0x01, 0x79, 0x00,
		0x03, 0x0b, 0x92, 0x11, 0x0c, 0x82, 0x05, 0x2b, 0xc5, 0xe0, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10,
		0x00, 0x79, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10, 0x00, 0x79, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10,
		0x00, 0x79, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10, 0x00, 0x79, 0x00, 0x03, 0x0b, 0x91, 0x11, 0xff,
		0x00, 0x05, 0x56, 0xc5, 0xe0, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10, 0x00, 0x79, 0x00, 0x28, 0x00,
		0x6f, 0x00, 0x30, 0x00, 0x79, 0x00, 0x48, 0x00, 0x6f, 0x00, 0x50, 0x00, 0x79, 0x00, 0x68, 0x00,
		0x6f, 0x00, 0x70, 0x00, 0x79, 0x00, 0x88, 0x00, 0x6f, 0x00, 0x90, 0x00, 0x79, 0x00, 0xa8, 0x00,
		0x6f, 0x00, 0xb0, 0x00, 0x79, 0x00, 0xc8, 0x00, 0x6f, 0x00, 0xd0, 0x00, 0x79, 0x00, 0xe8, 0x00,
		0x6f, 0x00, 0xf0, 0x00, 0x79, 0x00, 0x03, 0x0b, 0x8f, 0x11, 0xff, 0x00, 0x05, 0xa1, 0xc5, 0xe0,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x6f, 0x00, 0x10, 0x00, 0x79,
		0x00, 0x10, 0x00, 0x6f, 0x00, 0x18, 0x00, 0x79, 0x00, 0x18, 0x00, 0x6f, 0x00, 0x20, 0x00, 0x79,
		0x00, 0x20, 0x00, 0x6f, 0x00, 0x28, 0x00, 0x79, 0x00, 0x28, 0x00, 0x6f, 0x00, 0x30, 0x00, 0x79,
		0x00, 0x30, 0x00, 0x6f, 0x00, 0x38, 0x00, 0x79, 0x00, 0x38, 0x00, 0x6f, 0x00, 0x40, 0x00, 0x79,
		0x00, 0x40, 0x00, 0x6f, 0x00, 0x48, 0x00, 0x79, 0x00, 0x48, 0x00, 0x6f, 0x00, 0x50, 0x00, 0x79,
		0x00, 0x50, 0x00, 0x6f, 0x00, 0x58, 0x00, 0x79, 0x00, 0x58, 0x00, 0x6f, 0x00, 0x60, 0x00, 0x79,
		0x00, 0x60, 0x00, 0x6f, 0x00, 0x68, 0x00, 0x79, 0x00, 0x68, 0x00, 0x6f, 0x00, 0x70, 0x00, 0x79,
		0x00, 0x70, 0x00, 0x6f, 0x00, 0x78, 0x00, 0x79, 0x00, 0x78, 0x00, 0x6f, 0x00, 0x80, 0x00, 0x79,
		0x00, 0x80, 0x00, 0x6f, 0x00, 0x88, 0x00, 0x79, 0x00, 0x88, 0x00, 0x6f, 0x00, 0x90, 0x00, 0x79,
		0x00, 0x90, 0x00, 0x6f, 0x00, 0x98, 0x00, 0x79, 0x00, 0x98, 0x00, 0x6f, 0x00, 0xa0, 0x00, 0x79,
		0x00, 0xa0, 0x00, 0x6f, 0x00, 0xa8, 0x00, 0x79, 0x00, 0xa8, 0x00, 0x6f, 0x00, 0xb0, 0x00, 0x79,
		0x00, 0xb0, 0x00, 0x6f, 0x00, 0xb8, 0x00, 0x79, 0x00, 0xb8, 0x00, 0x6f, 0x00, 0xc0, 0x00, 0x79,
		0x00, 0xc0, 0x00, 0x6f, 0x00, 0xc8, 0x00, 0x79, 0x00, 0xc8, 0x00, 0x6f, 0x00, 0xd0, 0x00, 0x79,
		0x00, 0xd0, 0x00, 0x6f, 0x00, 0xd8, 0x00, 0x79, 0x00, 0xd8, 0x00, 0x6f, 0x00, 0xe0, 0x00, 0x79,
		0x00, 0xe0, 0x00, 0x6f, 0x00, 0xe8, 0x00, 0x79, 0x00, 0xe8, 0x00, 0x6f, 0x00, 0xf0, 0x00, 0x79,
		0x00, 0xf0, 0x00, 0x6f, 0x00, 0xf8, 0x00, 0x79, 0x00, 0xf8, 0x00, 0x6f, 0x00, 0x00, 0x01, 0x79,
		0x00, 0x00, 0x01, 0x6f, 0x00, 0x08, 0x01, 0x79, 0x00, 0x04, 0x0b, 0x9b, 0x11, 0xff, 0x00, 0x0e,
		0xca, 0xc6, 0xe0, 0x00, 0x04, 0x0b, 0x9c, 0x11, 0xff, 0x00, 0x0e, 0xe8, 0xc6, 0xe0, 0x00, 0x04,
		0x0b, 0x9d, 0x11, 0xff, 0x00, 0x0e, 0x06, 0xc7, 0xe0, 0x00, 0x51, 0x0a, 0x20, 0x00, 0x0a, 0x00,
		0x59, 0x0a, 0x18, 0x00, 0x0a, 0x00, 0x61, 0x0a, 0x10, 0x00, 0x0a, 0x00, 0x69, 0x0a, 0x08, 0x00,
		0x0a, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x59, 0x11, 0x20, 0x00, 0x0a, 0x00, 0x61, 0x11,
		0x18, 0x00, 0x0a, 0x00, 0x69, 0x11, 0x10, 0x00, 0x0a, 0x00, 0x71, 0x11, 0x08, 0x00, 0x0a, 0x00,
		0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x61, 0x18, 0x20, 0x00, 0x0a, 0x00, 0x69, 0x18, 0x18, 0x00,
		0x0a, 0x00, 0x71, 0x18, 0x10, 0x00, 0x0a, 0x00, 0x79, 0x18, 0x08, 0x00, 0x0a, 0x00, 0x00, 0x00,
		0x01, 0x00, 0x01, 0x00,
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
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b3, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 81, .y = 10 },  /* track_status pos=(81,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b4, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 85, .y = 10 },  /* track_status pos=(85,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b5, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 89, .y = 10 },  /* track_status pos=(89,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b6, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 93, .y = 10 },  /* track_status pos=(93,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b7, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 97, .y = 10 },  /* track_status pos=(97,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b8, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 101, .y = 10 },  /* track_status pos=(101,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11b9, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 105, .y = 10 },  /* track_status pos=(105,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11ba, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 109, .y = 10 },  /* track_status pos=(109,10) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1192, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 89, .y = 17 },  /* track_status pos=(89,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1193, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 93, .y = 17 },  /* track_status pos=(93,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1194, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 97, .y = 17 },  /* track_status pos=(97,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1195, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 101, .y = 17 },  /* track_status pos=(101,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1196, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 105, .y = 17 },  /* track_status pos=(105,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1197, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 109, .y = 17 },  /* track_status pos=(109,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1198, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 113, .y = 17 },  /* track_status pos=(113,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x1199, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 117, .y = 17 },  /* track_status pos=(117,17) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119a, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 97, .y = 24 },  /* track_status pos=(97,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119b, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 101, .y = 24 },  /* track_status pos=(101,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119c, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 105, .y = 24 },  /* track_status pos=(105,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119d, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 109, .y = 24 },  /* track_status pos=(109,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119e, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 113, .y = 24 },  /* track_status pos=(113,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x119f, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 117, .y = 24 },  /* track_status pos=(117,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a0, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 121, .y = 24 },  /* track_status pos=(121,24) */
		{ .opcode = 0x02, .subtype = 0x0f, .id = 0x11a1, .flags = 0x8560, .ref_tag = 0x06, .handler = 0x00e0c8cc, .param = 1, .x = 125, .y = 24 },  /* track_status pos=(125,24) */
	},

	/* Bottom bar marker */
	.bottom_bar_marker = {
		0x20, 0x2a, 0x91,
	},

	/* Bottom bar: 8 FILLED_RECTs at y=210-236 */
	.bottom_bar_rects = {
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 5, .y = 210 }, .bottom_right = { .x = 35, .y = 236 } },  /* (5,210)-(35,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 45, .y = 210 }, .bottom_right = { .x = 75, .y = 236 } },  /* (45,210)-(75,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 85, .y = 210 }, .bottom_right = { .x = 115, .y = 236 } },  /* (85,210)-(115,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 125, .y = 210 }, .bottom_right = { .x = 155, .y = 236 } },  /* (125,210)-(155,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 165, .y = 210 }, .bottom_right = { .x = 195, .y = 236 } },  /* (165,210)-(195,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 205, .y = 210 }, .bottom_right = { .x = 235, .y = 236 } },  /* (205,210)-(235,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 245, .y = 210 }, .bottom_right = { .x = 275, .y = 236 } },  /* (245,210)-(275,236) */
		{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, .top_left = { .x = 285, .y = 210 }, .bottom_right = { .x = 315, .y = 236 } },  /* (285,210)-(315,236) */
	},

	/* Bottom bar: 6 HLINE dividers at y=223 */
	.bottom_bar_dividers = {
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 5, .y = 223 }, .p2 = { .x = 35, .y = 223 } },  /* (5,223)-(35,223) */
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 45, .y = 223 }, .p2 = { .x = 75, .y = 223 } },  /* (45,223)-(75,223) */
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 85, .y = 223 }, .p2 = { .x = 115, .y = 223 } },  /* (85,223)-(115,223) */
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 125, .y = 223 }, .p2 = { .x = 155, .y = 223 } },  /* (125,223)-(155,223) */
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 165, .y = 223 }, .p2 = { .x = 195, .y = 223 } },  /* (165,223)-(195,223) */
		{ .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 205, .y = 223 }, .p2 = { .x = 235, .y = 223 } },  /* (205,223)-(235,223) */
	},
};
