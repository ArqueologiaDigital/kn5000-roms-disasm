; World Percussion Patch Data
; Audio subsystem: pointer table + patch entries for world percussion category
; Descriptor slot +0x2C (MODE 1 twin of slot +0x1C, see sound_data_brass.s):
; VOICE INDEX -> (PROGRAM, BANK) LISTS.  The old third header line said "33
; patch entries (WorldPerc_PatchPtrTable), each a variable-length byte
; sequence"; replaced 2026-09-25: there are 128 entries of ONE 3-byte record
; {program, bank, 0xFF} each, and nothing ties the table to World Percussion.
;
; Every record is {i, 0, 0xFF} for voice index i: in this mode the voice
; index IS the program number, in bank 0.
;
; COUNT 128: 512-byte pointer table, 128 distinct pointers, records tiling
; exactly from 0xE0AFD0 to 0xE0B150 (the next object).
;
; INVERSE of slot +0x28 (SOUND_DATA_MALLET_ORCH_PERC): 128 of 128 voice
; indices round-trip (scripts/analysis/sound_data_map_proof.py).
;
; No reader found, so the record layout above rests on the slot +0x1C
; twin's reader and on the round trip, not on a reader of this table.
; Searched: all 14 loads of the descriptor cell (RAM 0xE14E; v7 0xE0B2) and
; the offset each applies (+0x00/04/08, +0x10..+0x28 via XBC, +0x1C, +0x30,
; +0x34, +0x38, +0x3C..+0x4C); the 24-bit values 0xE023CC (the slot) and
; 0xE0ADD0 (this table) anywhere in the v10 dump -- only the slot holds
; 0xE0ADD0; and any `ld xr, 0x2c` or (xr+0x2c) operand in v10
; 0xFEE000-0xFEEFFF.  In mode 1, SndParam_CheckAndApplyMode (v10/v9
; 0xFEE99F, v7 0xFEE1D0) calls SndParam_ApplyVoiceValue, which uses no table,
; where mode 0 calls SndParam_LookupOscEnvelope: the natural reader of this
; slot is simply not called.

WorldPerc_PatchPtrTable:
	.long WorldPerc_PatchEntry_000
	.long WorldPerc_PatchEntry_001
	.long WorldPerc_PatchEntry_002
	.long WorldPerc_PatchEntry_003
	.long WorldPerc_PatchEntry_004
	.long WorldPerc_PatchEntry_005
	.long WorldPerc_PatchEntry_006
	.long WorldPerc_PatchEntry_007
	.long WorldPerc_PatchEntry_008
	.long WorldPerc_PatchEntry_009
	.long WorldPerc_PatchEntry_010
	.long WorldPerc_PatchEntry_011
	.long WorldPerc_PatchEntry_012
	.long WorldPerc_PatchEntry_013
	.long WorldPerc_PatchEntry_014
	.long WorldPerc_PatchEntry_015
	.long WorldPerc_PatchEntry_016
	.long WorldPerc_PatchEntry_017
	.long WorldPerc_PatchEntry_018
	.long WorldPerc_PatchEntry_019
	.long WorldPerc_PatchEntry_020
	.long WorldPerc_PatchEntry_021
	.long WorldPerc_PatchEntry_022
	.long WorldPerc_PatchEntry_023
	.long WorldPerc_PatchEntry_024
	.long WorldPerc_PatchEntry_025
	.long WorldPerc_PatchEntry_026
	.long WorldPerc_PatchEntry_027
	.long WorldPerc_PatchEntry_028
	.long WorldPerc_PatchEntry_029
	.long WorldPerc_PatchEntry_030
	.long WorldPerc_PatchEntry_031
	.long WorldPerc_PatchEntry_032
	.long WorldPerc_PatchEntry_033
	.long WorldPerc_PatchEntry_034
	.long WorldPerc_PatchEntry_035
	.long WorldPerc_PatchEntry_036
	.long WorldPerc_PatchEntry_037
	.long WorldPerc_PatchEntry_038
	.long WorldPerc_PatchEntry_039
	.long WorldPerc_PatchEntry_040
	.long WorldPerc_PatchEntry_041
	.long WorldPerc_PatchEntry_042
	.long WorldPerc_PatchEntry_043
	.long WorldPerc_PatchEntry_044
	.long WorldPerc_PatchEntry_045
	.long WorldPerc_PatchEntry_046
	.long WorldPerc_PatchEntry_047
	.long WorldPerc_PatchEntry_048
	.long WorldPerc_PatchEntry_049
	.long WorldPerc_PatchEntry_050
	.long WorldPerc_PatchEntry_051
	.long WorldPerc_PatchEntry_052
	.long WorldPerc_PatchEntry_053
	.long WorldPerc_PatchEntry_054
	.long WorldPerc_PatchEntry_055
	.long WorldPerc_PatchEntry_056
	.long WorldPerc_PatchEntry_057
	.long WorldPerc_PatchEntry_058
	.long WorldPerc_PatchEntry_059
	.long WorldPerc_PatchEntry_060
	.long WorldPerc_PatchEntry_061
	.long WorldPerc_PatchEntry_062
	.long WorldPerc_PatchEntry_063
	.long WorldPerc_PatchEntry_064
	.long WorldPerc_PatchEntry_065
	.long WorldPerc_PatchEntry_066
	.long WorldPerc_PatchEntry_067
	.long WorldPerc_PatchEntry_068
	.long WorldPerc_PatchEntry_069
	.long WorldPerc_PatchEntry_070
	.long WorldPerc_PatchEntry_071
	.long WorldPerc_PatchEntry_072
	.long WorldPerc_PatchEntry_073
	.long WorldPerc_PatchEntry_074
	.long WorldPerc_PatchEntry_075
	.long WorldPerc_PatchEntry_076
	.long WorldPerc_PatchEntry_077
	.long WorldPerc_PatchEntry_078
	.long WorldPerc_PatchEntry_079
	.long WorldPerc_PatchEntry_080
	.long WorldPerc_PatchEntry_081
	.long WorldPerc_PatchEntry_082
	.long WorldPerc_PatchEntry_083
	.long WorldPerc_PatchEntry_084
	.long WorldPerc_PatchEntry_085
	.long WorldPerc_PatchEntry_086
	.long WorldPerc_PatchEntry_087
	.long WorldPerc_PatchEntry_088
	.long WorldPerc_PatchEntry_089
	.long WorldPerc_PatchEntry_090
	.long WorldPerc_PatchEntry_091
	.long WorldPerc_PatchEntry_092
	.long WorldPerc_PatchEntry_093
	.long WorldPerc_PatchEntry_094
	.long WorldPerc_PatchEntry_095
	.long WorldPerc_PatchEntry_096
	.long WorldPerc_PatchEntry_097
	.long WorldPerc_PatchEntry_098
	.long WorldPerc_PatchEntry_099
	.long WorldPerc_PatchEntry_100
	.long WorldPerc_PatchEntry_101
	.long WorldPerc_PatchEntry_102
	.long WorldPerc_PatchEntry_103
	.long WorldPerc_PatchEntry_104
	.long WorldPerc_PatchEntry_105
	.long WorldPerc_PatchEntry_106
	.long WorldPerc_PatchEntry_107
	.long WorldPerc_PatchEntry_108
	.long WorldPerc_PatchEntry_109
	.long WorldPerc_PatchEntry_110
	.long WorldPerc_PatchEntry_111
	.long WorldPerc_PatchEntry_112
	.long WorldPerc_PatchEntry_113
	.long WorldPerc_PatchEntry_114
	.long WorldPerc_PatchEntry_115
	.long WorldPerc_PatchEntry_116
	.long WorldPerc_PatchEntry_117
	.long WorldPerc_PatchEntry_118
	.long WorldPerc_PatchEntry_119
	.long WorldPerc_PatchEntry_120
	.long WorldPerc_PatchEntry_121
	.long WorldPerc_PatchEntry_122
	.long WorldPerc_PatchEntry_123
	.long WorldPerc_PatchEntry_124
	.long WorldPerc_PatchEntry_125
	.long WorldPerc_PatchEntry_126
	.long WorldPerc_PatchEntry_127
WorldPerc_PatchEntry_000:	.byte 0, 0, 0xff
WorldPerc_PatchEntry_001:	.byte 1, 0, 0xff
WorldPerc_PatchEntry_002:	.byte 2, 0, 0xff
WorldPerc_PatchEntry_003:	.byte 3, 0, 0xff
WorldPerc_PatchEntry_004:	.byte 4, 0, 0xff
WorldPerc_PatchEntry_005:	.byte 5, 0, 0xff
WorldPerc_PatchEntry_006:	.byte 6, 0, 0xff
WorldPerc_PatchEntry_007:	.byte 7, 0, 0xff
WorldPerc_PatchEntry_008:	.byte 8, 0, 0xff
WorldPerc_PatchEntry_009:	.byte 9, 0, 0xff
WorldPerc_PatchEntry_010:	.byte 10, 0, 0xff
WorldPerc_PatchEntry_011:	.byte 11, 0, 0xff
WorldPerc_PatchEntry_012:	.byte 12, 0, 0xff
WorldPerc_PatchEntry_013:	.byte 13, 0, 0xff
WorldPerc_PatchEntry_014:	.byte 14, 0, 0xff
WorldPerc_PatchEntry_015:	.byte 15, 0, 0xff
WorldPerc_PatchEntry_016:	.byte 16, 0, 0xff
WorldPerc_PatchEntry_017:	.byte 17, 0, 0xff
WorldPerc_PatchEntry_018:	.byte 18, 0, 0xff
WorldPerc_PatchEntry_019:	.byte 19, 0, 0xff
WorldPerc_PatchEntry_020:	.byte 20, 0, 0xff
WorldPerc_PatchEntry_021:	.byte 21, 0, 0xff
WorldPerc_PatchEntry_022:	.byte 22, 0, 0xff
WorldPerc_PatchEntry_023:	.byte 23, 0, 0xff
WorldPerc_PatchEntry_024:	.byte 24, 0, 0xff
WorldPerc_PatchEntry_025:	.byte 25, 0, 0xff
WorldPerc_PatchEntry_026:	.byte 26, 0, 0xff
WorldPerc_PatchEntry_027:	.byte 27, 0, 0xff
WorldPerc_PatchEntry_028:	.byte 28, 0, 0xff
WorldPerc_PatchEntry_029:	.byte 29, 0, 0xff
WorldPerc_PatchEntry_030:	.byte 30, 0, 0xff
WorldPerc_PatchEntry_031:	.byte 31, 0, 0xff
WorldPerc_PatchEntry_032:	.byte 32, 0, 0xff
WorldPerc_PatchEntry_033:	.byte 33, 0, 0xff
WorldPerc_PatchEntry_034:	.byte 34, 0, 0xff
WorldPerc_PatchEntry_035:	.byte 35, 0, 0xff
WorldPerc_PatchEntry_036:	.byte 36, 0, 0xff
WorldPerc_PatchEntry_037:	.byte 37, 0, 0xff
WorldPerc_PatchEntry_038:	.byte 38, 0, 0xff
WorldPerc_PatchEntry_039:	.byte 39, 0, 0xff
WorldPerc_PatchEntry_040:	.byte 40, 0, 0xff
WorldPerc_PatchEntry_041:	.byte 41, 0, 0xff
WorldPerc_PatchEntry_042:	.byte 42, 0, 0xff
WorldPerc_PatchEntry_043:	.byte 43, 0, 0xff
WorldPerc_PatchEntry_044:	.byte 44, 0, 0xff
WorldPerc_PatchEntry_045:	.byte 45, 0, 0xff
WorldPerc_PatchEntry_046:	.byte 46, 0, 0xff
WorldPerc_PatchEntry_047:	.byte 47, 0, 0xff
WorldPerc_PatchEntry_048:	.byte 48, 0, 0xff
WorldPerc_PatchEntry_049:	.byte 49, 0, 0xff
WorldPerc_PatchEntry_050:	.byte 50, 0, 0xff
WorldPerc_PatchEntry_051:	.byte 51, 0, 0xff
WorldPerc_PatchEntry_052:	.byte 52, 0, 0xff
WorldPerc_PatchEntry_053:	.byte 53, 0, 0xff
WorldPerc_PatchEntry_054:	.byte 54, 0, 0xff
WorldPerc_PatchEntry_055:	.byte 55, 0, 0xff
WorldPerc_PatchEntry_056:	.byte 56, 0, 0xff
WorldPerc_PatchEntry_057:	.byte 57, 0, 0xff
WorldPerc_PatchEntry_058:	.byte 58, 0, 0xff
WorldPerc_PatchEntry_059:	.byte 59, 0, 0xff
WorldPerc_PatchEntry_060:	.byte 60, 0, 0xff
WorldPerc_PatchEntry_061:	.byte 61, 0, 0xff
WorldPerc_PatchEntry_062:	.byte 62, 0, 0xff
WorldPerc_PatchEntry_063:	.byte 63, 0, 0xff
WorldPerc_PatchEntry_064:	.byte 64, 0, 0xff
WorldPerc_PatchEntry_065:	.byte 65, 0, 0xff
WorldPerc_PatchEntry_066:	.byte 66, 0, 0xff
WorldPerc_PatchEntry_067:	.byte 67, 0, 0xff
WorldPerc_PatchEntry_068:	.byte 68, 0, 0xff
WorldPerc_PatchEntry_069:	.byte 69, 0, 0xff
WorldPerc_PatchEntry_070:	.byte 70, 0, 0xff
WorldPerc_PatchEntry_071:	.byte 71, 0, 0xff
WorldPerc_PatchEntry_072:	.byte 72, 0, 0xff
WorldPerc_PatchEntry_073:	.byte 73, 0, 0xff
WorldPerc_PatchEntry_074:	.byte 74, 0, 0xff
WorldPerc_PatchEntry_075:	.byte 75, 0, 0xff
WorldPerc_PatchEntry_076:	.byte 76, 0, 0xff
WorldPerc_PatchEntry_077:	.byte 77, 0, 0xff
WorldPerc_PatchEntry_078:	.byte 78, 0, 0xff
WorldPerc_PatchEntry_079:	.byte 79, 0, 0xff
WorldPerc_PatchEntry_080:	.byte 80, 0, 0xff
WorldPerc_PatchEntry_081:	.byte 81, 0, 0xff
WorldPerc_PatchEntry_082:	.byte 82, 0, 0xff
WorldPerc_PatchEntry_083:	.byte 83, 0, 0xff
WorldPerc_PatchEntry_084:	.byte 84, 0, 0xff
WorldPerc_PatchEntry_085:	.byte 85, 0, 0xff
WorldPerc_PatchEntry_086:	.byte 86, 0, 0xff
WorldPerc_PatchEntry_087:	.byte 87, 0, 0xff
WorldPerc_PatchEntry_088:	.byte 88, 0, 0xff
WorldPerc_PatchEntry_089:	.byte 89, 0, 0xff
WorldPerc_PatchEntry_090:	.byte 90, 0, 0xff
WorldPerc_PatchEntry_091:	.byte 91, 0, 0xff
WorldPerc_PatchEntry_092:	.byte 92, 0, 0xff
WorldPerc_PatchEntry_093:	.byte 93, 0, 0xff
WorldPerc_PatchEntry_094:	.byte 94, 0, 0xff
WorldPerc_PatchEntry_095:	.byte 95, 0, 0xff
WorldPerc_PatchEntry_096:	.byte 96, 0, 0xff
WorldPerc_PatchEntry_097:	.byte 97, 0, 0xff
WorldPerc_PatchEntry_098:	.byte 98, 0, 0xff
WorldPerc_PatchEntry_099:	.byte 99, 0, 0xff
WorldPerc_PatchEntry_100:	.byte 100, 0, 0xff
WorldPerc_PatchEntry_101:	.byte 101, 0, 0xff
WorldPerc_PatchEntry_102:	.byte 102, 0, 0xff
WorldPerc_PatchEntry_103:	.byte 103, 0, 0xff
WorldPerc_PatchEntry_104:	.byte 104, 0, 0xff
WorldPerc_PatchEntry_105:	.byte 105, 0, 0xff
WorldPerc_PatchEntry_106:	.byte 106, 0, 0xff
WorldPerc_PatchEntry_107:	.byte 107, 0, 0xff
WorldPerc_PatchEntry_108:	.byte 108, 0, 0xff
WorldPerc_PatchEntry_109:	.byte 109, 0, 0xff
WorldPerc_PatchEntry_110:	.byte 110, 0, 0xff
WorldPerc_PatchEntry_111:	.byte 111, 0, 0xff
WorldPerc_PatchEntry_112:	.byte 112, 0, 0xff
WorldPerc_PatchEntry_113:	.byte 113, 0, 0xff
WorldPerc_PatchEntry_114:	.byte 114, 0, 0xff
WorldPerc_PatchEntry_115:	.byte 115, 0, 0xff
WorldPerc_PatchEntry_116:	.byte 116, 0, 0xff
WorldPerc_PatchEntry_117:	.byte 117, 0, 0xff
WorldPerc_PatchEntry_118:	.byte 118, 0, 0xff
WorldPerc_PatchEntry_119:	.byte 119, 0, 0xff
WorldPerc_PatchEntry_120:	.byte 120, 0, 0xff
WorldPerc_PatchEntry_121:	.byte 121, 0, 0xff
WorldPerc_PatchEntry_122:	.byte 122, 0, 0xff
WorldPerc_PatchEntry_123:	.byte 123, 0, 0xff
WorldPerc_PatchEntry_124:	.byte 124, 0, 0xff
WorldPerc_PatchEntry_125:	.byte 125, 0, 0xff
WorldPerc_PatchEntry_126:	.byte 126, 0, 0xff
WorldPerc_PatchEntry_127:	.byte 127, 0, 0xff
