/**
 * se_rhythm_transport_tables — Rhythm/DrumSound Screen Data with Dispatch Tables
 *
 * Base address: 0xF1440B
 * Size: 220 bytes (16 commands + 2 dispatch tables)
 *
 * Layout:
 *   STRING data (28 bytes): transport position labels ("1ST", "2ND", "3RD", "4TH")
 *   RhythmTransport_Control_Table (24 bytes): 6-entry dispatch table
 *   SETUP data (48 bytes): drum sound parameter setup blocks
 *   DrumSound_ParamEdit_Table (40 bytes): 10-entry dispatch table
 *   Selection indicators (80 bytes): RECT/HLINE pairs for 4 selection positions
 */

#include "screendata_types.h"
#include <stddef.h>

typedef struct __attribute__((packed)) {
	/* STRING data: transport position labels */
	SD_STRING_TYPE(3)              string_0;  /* "1ST" at (6,10) */
	SD_STRING_TYPE(3)              string_1;  /* "2ND" at (222,14) */
	SD_STRING_TYPE(3)              string_2;  /* "3RD" at (182,19) */
	SD_STRING_TYPE(3)              string_3;  /* "4TH" at (182,24) */

	/* RhythmTransport_Control_Table: 6 dispatch entries */
	uint32_t                       rhythm_table[6];

	/* SETUP data: drum sound parameter blocks */
	sd_nop_12_t                    setup_0;
	sd_nop_12_t                    setup_1;
	sd_nop_12_t                    setup_2;
	sd_nop_12_t                    setup_3;

	/* DrumSound_ParamEdit_Table: 10 dispatch entries */
	uint32_t                       drum_table[10];

	/* Selection indicators: RECT/HLINE pairs */
	sd_rect_t                      rect_0;   /* (79,65)-(88,74) */
	sd_hline_t                     hline_0;  /* (77,69)-(79,69) */
	sd_rect_t                      rect_1;   /* (79,96)-(88,105) */
	sd_hline_t                     hline_1;  /* (77,100)-(79,100) */
	sd_rect_t                      rect_2;   /* (79,127)-(88,136) */
	sd_hline_t                     hline_2;  /* (77,131)-(79,131) */
	sd_rect_t                      rect_3;   /* (79,158)-(88,167) */
	sd_hline_t                     hline_3;  /* (77,162)-(79,162) */
} screendata_se_rhythm_transport_tables_t;

_Static_assert(sizeof(screendata_se_rhythm_transport_tables_t) == 220,
	"se_rhythm_transport_tables must be exactly 220 bytes");

#define SE_RHYTHM_TRANSPORT_TABLES_BASE  0x00F1440Bu
#define SD_PTR(field)  (SE_RHYTHM_TRANSPORT_TABLES_BASE + offsetof(screendata_se_rhythm_transport_tables_t, field))

const screendata_se_rhythm_transport_tables_t se_rhythm_transport_tables
	__attribute__((section(".text"), used)) = {
	.string_0 = { .opcode = SD_OP_STRING, .length = 7, .x = 6, .y = 10, .text = { '1', 'S', 'T' } },
	.string_1 = { .opcode = SD_OP_STRING, .length = 7, .x = 222, .y = 14, .text = { '2', 'N', 'D' } },
	.string_2 = { .opcode = SD_OP_STRING, .length = 7, .x = 182, .y = 19, .text = { '3', 'R', 'D' } },
	.string_3 = { .opcode = SD_OP_STRING, .length = 7, .x = 182, .y = 24, .text = { '4', 'T', 'H' } },
	.rhythm_table = {
		SD_PTR(string_0),       /* [0] → "1ST" */
		SD_PTR(string_0),       /* [1] → "1ST" (duplicate) */
		SD_PTR(string_1),       /* [2] → "2ND" */
		SD_PTR(string_2),       /* [3] → "3RD" */
		SD_PTR(string_3),       /* [4] → "4TH" */
		SD_PTR(rhythm_table),   /* [5] → self-reference */
	},
	.setup_0 = { .opcode = 0x03, .length = 0x0c, .data = { 0x06, 0x0c, 0xf1, 0x00, 0x06, 0x0a, 0x03, 0x00, 0x0a, 0x00 } },
	.setup_1 = { .opcode = 0x03, .length = 0x0c, .data = { 0x24, 0x0c, 0xf1, 0x00, 0xde, 0x0e, 0x03, 0x00, 0x0a, 0x00 } },
	.setup_2 = { .opcode = 0x03, .length = 0x0c, .data = { 0x42, 0x0c, 0xf1, 0x00, 0xb6, 0x13, 0x03, 0x00, 0x0a, 0x00 } },
	.setup_3 = { .opcode = 0x03, .length = 0x0c, .data = { 0x60, 0x0c, 0xf1, 0x00, 0xb6, 0x18, 0x03, 0x00, 0x0a, 0x00 } },
	.drum_table = {
		SD_PTR(setup_0),        /* [0] → setup block 0 */
		SD_PTR(setup_0),        /* [1] → setup block 0 (duplicate) */
		SD_PTR(setup_1),        /* [2] → setup block 1 */
		SD_PTR(setup_2),        /* [3] → setup block 2 */
		SD_PTR(setup_3),        /* [4] → setup block 3 */
		SD_PTR(drum_table),     /* [5] → self-reference */
		SD_PTR(rect_0),         /* [6] → selection rect 0 */
		SD_PTR(rect_1),         /* [7] → selection rect 1 */
		SD_PTR(rect_2),         /* [8] → selection rect 2 */
		SD_PTR(rect_3),         /* [9] → selection rect 3 */
	},
	.rect_0 = { .opcode = SD_OP_RECT, .length = 0x0a, .top_left = { .x = 79, .y = 65 }, .bottom_right = { .x = 88, .y = 74 } },
	.hline_0 = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 77, .y = 69 }, .p2 = { .x = 79, .y = 69 } },
	.rect_1 = { .opcode = SD_OP_RECT, .length = 0x0a, .top_left = { .x = 79, .y = 96 }, .bottom_right = { .x = 88, .y = 105 } },
	.hline_1 = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 77, .y = 100 }, .p2 = { .x = 79, .y = 100 } },
	.rect_2 = { .opcode = SD_OP_RECT, .length = 0x0a, .top_left = { .x = 79, .y = 127 }, .bottom_right = { .x = 88, .y = 136 } },
	.hline_2 = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 77, .y = 131 }, .p2 = { .x = 79, .y = 131 } },
	.rect_3 = { .opcode = SD_OP_RECT, .length = 0x0a, .top_left = { .x = 79, .y = 158 }, .bottom_right = { .x = 88, .y = 167 } },
	.hline_3 = { .opcode = SD_OP_HLINE, .length = 0x0a, .p1 = { .x = 77, .y = 162 }, .p2 = { .x = 79, .y = 162 } },
};
