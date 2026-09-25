; Brass Sound Patch Data
; Audio subsystem: pointer table + patch entries for brass instrument category
; Descriptor slot +0x1C (mode 0): VOICE INDEX -> (PROGRAM, BANK) LISTS.
; The old third header line said "35 patch entries (BrassSound_SamplePtr_Table),
; each a variable-length byte sequence"; that was wrong on both counts and is
; replaced (2026-09-25): there are 128 entries, each exactly ONE 3-byte record.
; Nothing ties the table to the Brass category either -- it is reached only as
; slot +0x1C of the sound-data descriptor (see audio/sound_data.s).
;
; READER  SndParam_LookupOscEnvelope (v10/v9 0xFEE8F1, v7 0xFEE122), called by
; SndParam_CheckAndApplyMode in mode 0, with a sound-selection record in XIZ:
;     xhl = the pointer at BrassSound_SamplePtr_Table + 4*record[+2]
;           (record[+2] = voice index)
;     c   = record[+1]
;     walk 3-byte records from xhl: advance while c >= rec[+2], or while
;     rec[+2] != 0xFF; stop on the first rec[+2] == 0xFF (with c < 0xFF)
;     record[+3] = rec[+0],  record[+4] = rec[+1]
; (It uses slot +0x30 instead when record[+5] == 15 or
; SndParam_LookupViaEncode(record[+5], 0) >= 0xF0.)
;
; RECORD  +0 program number (0..127), +1 bank number (0..5 here), +2 0xFF.
; The walk as written stops only on an 0xFF limit, and every entry holds a
; single record, so each entry resolves to its one record.
;
; COUNT   128: the pointer table is 512 B = 128 x 4, the index is the voice
; index 0..127 that slot +0x18 produces, and the 128 records tile exactly from
; 0xE06DB0 to 0xE06F30 (the next object).  All 128 pointers are distinct.
;
; INVERSE of slot +0x18 (SOUND_DATA_STRINGS_VOCAL): feeding each record's
; (bank, program) through slot +0x18 gives back its own voice index for
; 128 of 128 (scripts/analysis/sound_data_map_proof.py, v10/v9/v7).
;
; The label numbers skip 083, so from voice index 83 on a label's number is
; its index + 1.  The labels are kept: CLAUDE.md cites Brass_PatchEntry_084 as
; the example of this prefix.

BrassSound_SamplePtr_Table:
	.long Brass_PatchEntry_000
	.long Brass_PatchEntry_001
	.long Brass_PatchEntry_002
	.long Brass_PatchEntry_003
	.long Brass_PatchEntry_004
	.long Brass_PatchEntry_005
	.long Brass_PatchEntry_006
	.long Brass_PatchEntry_007
	.long Brass_PatchEntry_008
	.long Brass_PatchEntry_009
	.long Brass_PatchEntry_010
	.long Brass_PatchEntry_011
	.long Brass_PatchEntry_012
	.long Brass_PatchEntry_013
	.long Brass_PatchEntry_014
	.long Brass_PatchEntry_015
	.long Brass_PatchEntry_016
	.long Brass_PatchEntry_017
	.long Brass_PatchEntry_018
	.long Brass_PatchEntry_019
	.long Brass_PatchEntry_020
	.long Brass_PatchEntry_021
	.long Brass_PatchEntry_022
	.long Brass_PatchEntry_023
	.long Brass_PatchEntry_024
	.long Brass_PatchEntry_025
	.long Brass_PatchEntry_026
	.long Brass_PatchEntry_027
	.long Brass_PatchEntry_028
	.long Brass_PatchEntry_029
	.long Brass_PatchEntry_030
	.long Brass_PatchEntry_031
	.long Brass_PatchEntry_032
	.long Brass_PatchEntry_033
	.long Brass_PatchEntry_034
	.long Brass_PatchEntry_035
	.long Brass_PatchEntry_036
	.long Brass_PatchEntry_037
	.long Brass_PatchEntry_038
	.long Brass_PatchEntry_039
	.long Brass_PatchEntry_040
	.long Brass_PatchEntry_041
	.long Brass_PatchEntry_042
	.long Brass_PatchEntry_043
	.long Brass_PatchEntry_044
	.long Brass_PatchEntry_045
	.long Brass_PatchEntry_046
	.long Brass_PatchEntry_047
	.long Brass_PatchEntry_048
	.long Brass_PatchEntry_049
	.long Brass_PatchEntry_050
	.long Brass_PatchEntry_051
	.long Brass_PatchEntry_052
	.long Brass_PatchEntry_053
	.long Brass_PatchEntry_054
	.long Brass_PatchEntry_055
	.long Brass_PatchEntry_056
	.long Brass_PatchEntry_057
	.long Brass_PatchEntry_058
	.long Brass_PatchEntry_059
	.long Brass_PatchEntry_060
	.long Brass_PatchEntry_061
	.long Brass_PatchEntry_062
	.long Brass_PatchEntry_063
	.long Brass_PatchEntry_064
	.long Brass_PatchEntry_065
	.long Brass_PatchEntry_066
	.long Brass_PatchEntry_067
	.long Brass_PatchEntry_068
	.long Brass_PatchEntry_069
	.long Brass_PatchEntry_070
	.long Brass_PatchEntry_071
	.long Brass_PatchEntry_072
	.long Brass_PatchEntry_073
	.long Brass_PatchEntry_074
	.long Brass_PatchEntry_075
	.long Brass_PatchEntry_076
	.long Brass_PatchEntry_077
	.long Brass_PatchEntry_078
	.long Brass_PatchEntry_079
	.long Brass_PatchEntry_080
	.long Brass_PatchEntry_081
	.long Brass_PatchEntry_082
	.long Brass_PatchEntry_084
	.long Brass_PatchEntry_085
	.long Brass_PatchEntry_086
	.long Brass_PatchEntry_087
	.long Brass_PatchEntry_088
	.long Brass_PatchEntry_089
	.long Brass_PatchEntry_090
	.long Brass_PatchEntry_091
	.long Brass_PatchEntry_092
	.long Brass_PatchEntry_093
	.long Brass_PatchEntry_094
	.long Brass_PatchEntry_095
	.long Brass_PatchEntry_096
	.long Brass_PatchEntry_097
	.long Brass_PatchEntry_098
	.long Brass_PatchEntry_099
	.long Brass_PatchEntry_100
	.long Brass_PatchEntry_101
	.long Brass_PatchEntry_102
	.long Brass_PatchEntry_103
	.long Brass_PatchEntry_104
	.long Brass_PatchEntry_105
	.long Brass_PatchEntry_106
	.long Brass_PatchEntry_107
	.long Brass_PatchEntry_108
	.long Brass_PatchEntry_109
	.long Brass_PatchEntry_110
	.long Brass_PatchEntry_111
	.long Brass_PatchEntry_112
	.long Brass_PatchEntry_113
	.long Brass_PatchEntry_114
	.long Brass_PatchEntry_115
	.long Brass_PatchEntry_116
	.long Brass_PatchEntry_117
	.long Brass_PatchEntry_118
	.long Brass_PatchEntry_119
	.long Brass_PatchEntry_120
	.long Brass_PatchEntry_121
	.long Brass_PatchEntry_122
	.long Brass_PatchEntry_123
	.long Brass_PatchEntry_124
	.long Brass_PatchEntry_125
	.long Brass_PatchEntry_126
	.long Brass_PatchEntry_127
	.long Brass_PatchEntry_128
Brass_PatchEntry_000:	.byte 0, 0, 0xff
Brass_PatchEntry_001:	.byte 1, 0, 0xff
Brass_PatchEntry_002:	.byte 3, 0, 0xff
Brass_PatchEntry_003:	.byte 1, 1, 0xff
Brass_PatchEntry_004:	.byte 5, 0, 0xff
Brass_PatchEntry_005:	.byte 6, 0, 0xff
Brass_PatchEntry_006:	.byte 16, 0, 0xff
Brass_PatchEntry_007:	.byte 17, 0, 0xff
Brass_PatchEntry_008:	.byte 12, 0, 0xff
Brass_PatchEntry_009:	.byte 9, 0, 0xff
Brass_PatchEntry_010:	.byte 7, 0, 0xff
Brass_PatchEntry_011:	.byte 8, 0, 0xff
Brass_PatchEntry_012:	.byte 10, 0, 0xff
Brass_PatchEntry_013:	.byte 11, 0, 0xff
Brass_PatchEntry_014:	.byte 14, 0, 0xff
Brass_PatchEntry_015:	.byte 38, 1, 0xff
Brass_PatchEntry_016:	.byte 89, 0, 0xff
Brass_PatchEntry_017:	.byte 88, 0, 0xff
Brass_PatchEntry_018:	.byte 92, 2, 0xff
Brass_PatchEntry_019:	.byte 84, 0, 0xff
Brass_PatchEntry_020:	.byte 86, 2, 0xff
Brass_PatchEntry_021:	.byte 80, 0, 0xff
Brass_PatchEntry_022:	.byte 83, 0, 0xff
Brass_PatchEntry_023:	.byte 80, 1, 0xff
Brass_PatchEntry_024:	.byte 21, 0, 0xff
Brass_PatchEntry_025:	.byte 22, 0, 0xff
Brass_PatchEntry_026:	.byte 25, 0, 0xff
Brass_PatchEntry_027:	.byte 26, 0, 0xff
Brass_PatchEntry_028:	.byte 29, 0, 0xff
Brass_PatchEntry_029:	.byte 27, 2, 0xff
Brass_PatchEntry_030:	.byte 30, 0, 0xff
Brass_PatchEntry_031:	.byte 27, 1, 0xff
Brass_PatchEntry_032:	.byte 43, 0, 0xff
Brass_PatchEntry_033:	.byte 40, 1, 0xff
Brass_PatchEntry_034:	.byte 42, 0, 0xff
Brass_PatchEntry_035:	.byte 40, 2, 0xff
Brass_PatchEntry_036:	.byte 41, 0, 0xff
Brass_PatchEntry_037:	.byte 41, 1, 0xff
Brass_PatchEntry_038:	.byte 46, 0, 0xff
Brass_PatchEntry_039:	.byte 46, 5, 0xff
Brass_PatchEntry_040:	.byte 96, 0, 0xff
Brass_PatchEntry_041:	.byte 97, 2, 0xff
Brass_PatchEntry_042:	.byte 97, 0, 0xff
Brass_PatchEntry_043:	.byte 98, 0, 0xff
Brass_PatchEntry_044:	.byte 100, 2, 0xff
Brass_PatchEntry_045:	.byte 99, 0, 0xff
Brass_PatchEntry_046:	.byte 32, 0, 0xff
Brass_PatchEntry_047:	.byte 126, 0, 0xff
Brass_PatchEntry_048:	.byte 100, 0, 0xff
Brass_PatchEntry_049:	.byte 101, 0, 0xff
Brass_PatchEntry_050:	.byte 103, 0, 0xff
Brass_PatchEntry_051:	.byte 103, 1, 0xff
Brass_PatchEntry_052:	.byte 104, 3, 0xff
Brass_PatchEntry_053:	.byte 109, 0, 0xff
Brass_PatchEntry_054:	.byte 107, 0, 0xff
Brass_PatchEntry_055:	.byte 127, 1, 0xff
Brass_PatchEntry_056:	.byte 48, 0, 0xff
Brass_PatchEntry_057:	.byte 52, 0, 0xff
Brass_PatchEntry_058:	.byte 55, 0, 0xff
Brass_PatchEntry_059:	.byte 50, 0, 0xff
Brass_PatchEntry_060:	.byte 54, 1, 0xff
Brass_PatchEntry_061:	.byte 56, 0, 0xff
Brass_PatchEntry_062:	.byte 60, 0, 0xff
Brass_PatchEntry_063:	.byte 62, 4, 0xff
Brass_PatchEntry_064:	.byte 76, 0, 0xff
Brass_PatchEntry_065:	.byte 77, 0, 0xff
Brass_PatchEntry_066:	.byte 78, 3, 0xff
Brass_PatchEntry_067:	.byte 79, 1, 0xff
Brass_PatchEntry_068:	.byte 66, 0, 0xff
Brass_PatchEntry_069:	.byte 67, 0, 0xff
Brass_PatchEntry_070:	.byte 70, 0, 0xff
Brass_PatchEntry_071:	.byte 68, 0, 0xff
Brass_PatchEntry_072:	.byte 64, 0, 0xff
Brass_PatchEntry_073:	.byte 65, 0, 0xff
Brass_PatchEntry_074:	.byte 74, 0, 0xff
Brass_PatchEntry_075:	.byte 72, 0, 0xff
Brass_PatchEntry_076:	.byte 72, 2, 0xff
Brass_PatchEntry_077:	.byte 75, 0, 0xff
Brass_PatchEntry_078:	.byte 111, 0, 0xff
Brass_PatchEntry_079:	.byte 74, 1, 0xff
Brass_PatchEntry_080:	.byte 117, 0, 0xff
Brass_PatchEntry_081:	.byte 118, 1, 0xff
Brass_PatchEntry_082:	.byte 72, 3, 0xff
Brass_PatchEntry_084:	.byte 117, 2, 0xff
Brass_PatchEntry_085:	.byte 27, 3, 0xff
Brass_PatchEntry_086:	.byte 106, 1, 0xff
Brass_PatchEntry_087:	.byte 119, 0, 0xff
Brass_PatchEntry_088:	.byte 46, 2, 0xff
Brass_PatchEntry_089:	.byte 116, 3, 0xff
Brass_PatchEntry_090:	.byte 107, 1, 0xff
Brass_PatchEntry_091:	.byte 102, 2, 0xff
Brass_PatchEntry_092:	.byte 107, 2, 0xff
Brass_PatchEntry_093:	.byte 120, 0, 0xff
Brass_PatchEntry_094:	.byte 106, 2, 0xff
Brass_PatchEntry_095:	.byte 107, 3, 0xff
Brass_PatchEntry_096:	.byte 62, 2, 0xff
Brass_PatchEntry_097:	.byte 121, 3, 0xff
Brass_PatchEntry_098:	.byte 119, 1, 0xff
Brass_PatchEntry_099:	.byte 9, 2, 0xff
Brass_PatchEntry_100:	.byte 21, 3, 0xff
Brass_PatchEntry_101:	.byte 108, 3, 0xff
Brass_PatchEntry_102:	.byte 106, 0, 0xff
Brass_PatchEntry_103:	.byte 106, 3, 0xff
Brass_PatchEntry_104:	.byte 120, 1, 0xff
Brass_PatchEntry_105:	.byte 38, 0, 0xff
Brass_PatchEntry_106:	.byte 33, 0, 0xff
Brass_PatchEntry_107:	.byte 36, 0, 0xff
Brass_PatchEntry_108:	.byte 37, 0, 0xff
Brass_PatchEntry_109:	.byte 39, 0, 0xff
Brass_PatchEntry_110:	.byte 73, 0, 0xff
Brass_PatchEntry_111:	.byte 96, 2, 0xff
Brass_PatchEntry_112:	.byte 73, 1, 0xff
Brass_PatchEntry_113:	.byte 14, 2, 0xff
Brass_PatchEntry_114:	.byte 122, 0, 0xff
Brass_PatchEntry_115:	.byte 15, 0, 0xff
Brass_PatchEntry_116:	.byte 122, 1, 0xff
Brass_PatchEntry_117:	.byte 123, 3, 0xff
Brass_PatchEntry_118:	.byte 122, 2, 0xff
Brass_PatchEntry_119:	.byte 124, 0, 0xff
Brass_PatchEntry_120:	.byte 122, 3, 0xff
Brass_PatchEntry_121:	.byte 124, 1, 0xff
Brass_PatchEntry_122:	.byte 124, 2, 0xff
Brass_PatchEntry_123:	.byte 124, 3, 0xff
Brass_PatchEntry_124:	.byte 125, 2, 0xff
Brass_PatchEntry_125:	.byte 123, 0, 0xff
Brass_PatchEntry_126:	.byte 123, 1, 0xff
Brass_PatchEntry_127:	.byte 125, 3, 0xff
Brass_PatchEntry_128:	.byte 123, 2, 0xff
