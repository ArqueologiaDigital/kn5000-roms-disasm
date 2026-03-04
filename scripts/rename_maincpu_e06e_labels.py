#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E06EA9-E169F2.
Uses binary I/O to handle encoding safely.

Region coverage:
  E06EA9-E06F2D  BRASS sound patch data entries (index 84-128 in BRASS table)
  E078F2         FLUTE sound category extra data block
  E0ADD0         WORLD_PERC sound patch pointer table
  E0AFD0-E0B14D  WORLD_PERC sound patch data entries (tone 0x00-0x7F + variants)
  E0B4ED-E0B9ED  Style/sequencer UI parameter data blocks
  E0BA60         Style UI parameter data pointer table
  E0BB90         Style UI ring buffer / selection data
  E0C95B         Style UI data block (MEAS/CURSOR variant)
  E0CA13         Style UI data block (YES/CTL variant)
  E0CAF7         Style UI data block (CTL variant)
  E0CD1E         GUI format/layout data block
  E0CFDE         GUI display structure data block
  E0E407         Sound tone generation parameter table
  E15B80         MSP (Multi-Style Pad) default settings block
  E16184         Composer/style settings block with callback table
  E163AC         Composer callback function name string table
  E164D4-E169F2  Composer debug function name strings and string data structures
"""
import os, re

RENAMES = [
    # -------------------------------------------------------------------------
    # BRASS sound patch data entries (E06EA9-E06F2D)
    # Part of SOUND_DATA_BRASS_PTRS table; each entry is [tone_id, variant, 0xFF]
    # These are indices 84-128 (0-based: 83-127) in the BRASS pointer table.
    # -------------------------------------------------------------------------
    ('LABEL_E06EA9', 'Brass_PatchEntry_084', 'BRASS patch entry index 84: tone 0x75 variant 2'),
    ('LABEL_E06EAC', 'Brass_PatchEntry_085', 'BRASS patch entry index 85: tone 0x1b variant 3'),
    ('LABEL_E06EAF', 'Brass_PatchEntry_086', 'BRASS patch entry index 86: tone 0x6a variant 1'),
    ('LABEL_E06EB2', 'Brass_PatchEntry_087', 'BRASS patch entry index 87: tone 0x77 variant 0'),
    ('LABEL_E06EB5', 'Brass_PatchEntry_088', 'BRASS patch entry index 88: tone 0x2e variant 2'),
    ('LABEL_E06EB8', 'Brass_PatchEntry_089', 'BRASS patch entry index 89: tone 0x74 variant 3'),
    ('LABEL_E06EBB', 'Brass_PatchEntry_090', 'BRASS patch entry index 90: tone 0x6b variant 1'),
    ('LABEL_E06EBE', 'Brass_PatchEntry_091', 'BRASS patch entry index 91: tone 0x66 variant 2'),
    ('LABEL_E06EC1', 'Brass_PatchEntry_092', 'BRASS patch entry index 92: tone 0x6b variant 2'),
    ('LABEL_E06EC4', 'Brass_PatchEntry_093', 'BRASS patch entry index 93: tone 0x78 variant 0'),
    ('LABEL_E06EC7', 'Brass_PatchEntry_094', 'BRASS patch entry index 94: tone 0x6a variant 2'),
    ('LABEL_E06ECA', 'Brass_PatchEntry_095', 'BRASS patch entry index 95: tone 0x6b variant 3'),
    ('LABEL_E06ECD', 'Brass_PatchEntry_096', 'BRASS patch entry index 96: tone 0x3e variant 2'),
    ('LABEL_E06ED0', 'Brass_PatchEntry_097', 'BRASS patch entry index 97: tone 0x79 variant 3'),
    ('LABEL_E06ED3', 'Brass_PatchEntry_098', 'BRASS patch entry index 98: tone 0x77 variant 1'),
    ('LABEL_E06ED6', 'Brass_PatchEntry_099', 'BRASS patch entry index 99: tone 0x09 variant 2'),
    ('LABEL_E06ED9', 'Brass_PatchEntry_100', 'BRASS patch entry index 100: tone 0x15 variant 3'),
    ('LABEL_E06EDC', 'Brass_PatchEntry_101', 'BRASS patch entry index 101: tone 0x6c variant 3'),
    ('LABEL_E06EDF', 'Brass_PatchEntry_102', 'BRASS patch entry index 102: aligned_string "j" pad + tone 0x6a variant 3'),
    ('LABEL_E06EE2', 'Brass_PatchEntry_103', 'BRASS patch entry index 103: tone 0x6a variant 3'),
    ('LABEL_E06EE5', 'Brass_PatchEntry_104', 'BRASS patch entry index 104: tone 0x78 variant 1'),
    ('LABEL_E06EE8', 'Brass_PatchEntry_105', 'BRASS patch entry index 105: tone 0x26 variant 0'),
    ('LABEL_E06EEB', 'Brass_PatchEntry_106', 'BRASS patch entry index 106: tone 0x21 variant 0'),
    ('LABEL_E06EEE', 'Brass_PatchEntry_107', 'BRASS patch entry index 107: tone 0x24 variant 0'),
    ('LABEL_E06EF1', 'Brass_PatchEntry_108', 'BRASS patch entry index 108: tone 0x25 variant 0'),
    ('LABEL_E06EF4', 'Brass_PatchEntry_109', 'BRASS patch entry index 109: tone 0x27 variant 0'),
    ('LABEL_E06EF7', 'Brass_PatchEntry_110', 'BRASS patch entry index 110: aligned_string "I" pad + tone 0x60 variant 2'),
    ('LABEL_E06EFA', 'Brass_PatchEntry_111', 'BRASS patch entry index 111: tone 0x60 variant 2'),
    ('LABEL_E06EFD', 'Brass_PatchEntry_112', 'BRASS patch entry index 112: tone 0x49 variant 1'),
    ('LABEL_E06F00', 'Brass_PatchEntry_113', 'BRASS patch entry index 113: tone 0x0e variant 2'),
    ('LABEL_E06F03', 'Brass_PatchEntry_114', 'BRASS patch entry index 114: tone 0x7a variant 0'),
    ('LABEL_E06F06', 'Brass_PatchEntry_115', 'BRASS patch entry index 115: tone 0x0f variant 0'),
    ('LABEL_E06F09', 'Brass_PatchEntry_116', 'BRASS patch entry index 116: tone 0x7a variant 1'),
    ('LABEL_E06F0C', 'Brass_PatchEntry_117', 'BRASS patch entry index 117: tone 0x7b variant 3'),
    ('LABEL_E06F0F', 'Brass_PatchEntry_118', 'BRASS patch entry index 118: tone 0x7a variant 2'),
    ('LABEL_E06F12', 'Brass_PatchEntry_119', 'BRASS patch entry index 119: tone 0x7c variant 0'),
    ('LABEL_E06F15', 'Brass_PatchEntry_120', 'BRASS patch entry index 120: tone 0x7a variant 3'),
    ('LABEL_E06F18', 'Brass_PatchEntry_121', 'BRASS patch entry index 121: tone 0x7c variant 1'),
    ('LABEL_E06F1B', 'Brass_PatchEntry_122', 'BRASS patch entry index 122: tone 0x7c variant 2'),
    ('LABEL_E06F1E', 'Brass_PatchEntry_123', 'BRASS patch entry index 123: tone 0x7c variant 3'),
    ('LABEL_E06F21', 'Brass_PatchEntry_124', 'BRASS patch entry index 124: tone 0x7d variant 2'),
    ('LABEL_E06F24', 'Brass_PatchEntry_125', 'BRASS patch entry index 125: tone 0x7b variant 0'),
    ('LABEL_E06F27', 'Brass_PatchEntry_126', 'BRASS patch entry index 126: tone 0x7b variant 1'),
    ('LABEL_E06F2A', 'Brass_PatchEntry_127', 'BRASS patch entry index 127: tone 0x7d variant 3'),
    ('LABEL_E06F2D', 'Brass_PatchEntry_128', 'BRASS patch entry index 128: tone 0x7b variant 2'),

    # -------------------------------------------------------------------------
    # FLUTE extra data block (E078F2)
    # Referenced from SOUND_DATA_SECTION_PTRS; follows SOUND_DATA_FLUTE incbin.
    # -------------------------------------------------------------------------
    ('LABEL_E078F2', 'SoundData_Flute_Extra', 'Additional FLUTE category sound data block (referenced by pointer table)'),

    # -------------------------------------------------------------------------
    # WORLD_PERC pointer table (E0ADD0)
    # Points to 128 WORLD_PERC patch entries E0AFD0-E0B14D.
    # Immediately follows SOUND_DATA_WORLD_PERC label (no incbin — data inline).
    # -------------------------------------------------------------------------
    ('LABEL_E0ADD0', 'WorldPerc_PatchPtrTable', 'WORLD PERC sound category patch pointer table (128 entries)'),

    # -------------------------------------------------------------------------
    # WORLD_PERC sound patch data entries (E0AFD0-E0B14D)
    # Each entry is [tone_id, variant, 0xFF]. Tone IDs run 0x00-0x7F sequentially
    # with variant 0, but some entries use aligned_string padding for alignment.
    # -------------------------------------------------------------------------
    ('LABEL_E0AFD0', 'WorldPerc_PatchEntry_000', 'WORLD PERC patch entry 0: tone 0x00 variant 0'),
    ('LABEL_E0AFD3', 'WorldPerc_PatchEntry_001', 'WORLD PERC patch entry 1: tone 0x01 variant 0'),
    ('LABEL_E0AFD6', 'WorldPerc_PatchEntry_002', 'WORLD PERC patch entry 2: tone 0x02 variant 0'),
    ('LABEL_E0AFD9', 'WorldPerc_PatchEntry_003', 'WORLD PERC patch entry 3: tone 0x03 variant 0'),
    ('LABEL_E0AFDC', 'WorldPerc_PatchEntry_004', 'WORLD PERC patch entry 4: tone 0x04 variant 0'),
    ('LABEL_E0AFDF', 'WorldPerc_PatchEntry_005', 'WORLD PERC patch entry 5: tone 0x05 variant 0'),
    ('LABEL_E0AFE2', 'WorldPerc_PatchEntry_006', 'WORLD PERC patch entry 6: tone 0x06 variant 0'),
    ('LABEL_E0AFE5', 'WorldPerc_PatchEntry_007', 'WORLD PERC patch entry 7: tone 0x07 variant 0'),
    ('LABEL_E0AFE8', 'WorldPerc_PatchEntry_008', 'WORLD PERC patch entry 8: tone 0x08 variant 0'),
    ('LABEL_E0AFEB', 'WorldPerc_PatchEntry_009', 'WORLD PERC patch entry 9: tone 0x09 variant 0'),
    ('LABEL_E0AFEE', 'WorldPerc_PatchEntry_010', 'WORLD PERC patch entry 10: tone 0x0a variant 0'),
    ('LABEL_E0AFF1', 'WorldPerc_PatchEntry_011', 'WORLD PERC patch entry 11: tone 0x0b variant 0'),
    ('LABEL_E0AFF4', 'WorldPerc_PatchEntry_012', 'WORLD PERC patch entry 12: tone 0x0c variant 0'),
    ('LABEL_E0AFF7', 'WorldPerc_PatchEntry_013', 'WORLD PERC patch entry 13: tone 0x0d variant 0'),
    ('LABEL_E0AFFA', 'WorldPerc_PatchEntry_014', 'WORLD PERC patch entry 14: tone 0x0e variant 0'),
    ('LABEL_E0AFFD', 'WorldPerc_PatchEntry_015', 'WORLD PERC patch entry 15: tone 0x0f variant 0'),
    ('LABEL_E0B000', 'WorldPerc_PatchEntry_016', 'WORLD PERC patch entry 16: tone 0x10 variant 0'),
    ('LABEL_E0B003', 'WorldPerc_PatchEntry_017', 'WORLD PERC patch entry 17: tone 0x11 variant 0'),
    ('LABEL_E0B006', 'WorldPerc_PatchEntry_018', 'WORLD PERC patch entry 18: tone 0x12 variant 0'),
    ('LABEL_E0B009', 'WorldPerc_PatchEntry_019', 'WORLD PERC patch entry 19: tone 0x13 variant 0'),
    ('LABEL_E0B00C', 'WorldPerc_PatchEntry_020', 'WORLD PERC patch entry 20: tone 0x14 variant 0'),
    ('LABEL_E0B00F', 'WorldPerc_PatchEntry_021', 'WORLD PERC patch entry 21: tone 0x15 variant 0'),
    ('LABEL_E0B012', 'WorldPerc_PatchEntry_022', 'WORLD PERC patch entry 22: tone 0x16 variant 0'),
    ('LABEL_E0B015', 'WorldPerc_PatchEntry_023', 'WORLD PERC patch entry 23: tone 0x17 variant 0'),
    ('LABEL_E0B018', 'WorldPerc_PatchEntry_024', 'WORLD PERC patch entry 24: tone 0x18 variant 0'),
    ('LABEL_E0B01B', 'WorldPerc_PatchEntry_025', 'WORLD PERC patch entry 25: tone 0x19 variant 0'),
    ('LABEL_E0B01E', 'WorldPerc_PatchEntry_026', 'WORLD PERC patch entry 26: tone 0x1a variant 0'),
    ('LABEL_E0B021', 'WorldPerc_PatchEntry_027', 'WORLD PERC patch entry 27: tone 0x1b variant 0'),
    ('LABEL_E0B024', 'WorldPerc_PatchEntry_028', 'WORLD PERC patch entry 28: tone 0x1c variant 0'),
    ('LABEL_E0B027', 'WorldPerc_PatchEntry_029', 'WORLD PERC patch entry 29: tone 0x1d variant 0'),
    ('LABEL_E0B02A', 'WorldPerc_PatchEntry_030', 'WORLD PERC patch entry 30: tone 0x1e variant 0'),
    ('LABEL_E0B02D', 'WorldPerc_PatchEntry_031', 'WORLD PERC patch entry 31: tone 0x1f variant 0'),
    ('LABEL_E0B030', 'WorldPerc_PatchEntry_032', 'WORLD PERC patch entry 32: tone 0x20 variant 0'),
    ('LABEL_E0B033', 'WorldPerc_PatchEntry_033', 'WORLD PERC patch entry 33: tone 0x21 variant 0'),
    ('LABEL_E0B036', 'WorldPerc_PatchEntry_034', 'WORLD PERC patch entry 34: tone 0x22 variant 0'),
    ('LABEL_E0B039', 'WorldPerc_PatchEntry_035', 'WORLD PERC patch entry 35: tone 0x23 variant 0'),
    ('LABEL_E0B03C', 'WorldPerc_PatchEntry_036', 'WORLD PERC patch entry 36: tone 0x24 variant 0'),
    ('LABEL_E0B03F', 'WorldPerc_PatchEntry_037', 'WORLD PERC patch entry 37: aligned_string "%" pad + tone 0x25'),
    ('LABEL_E0B042', 'WorldPerc_PatchEntry_038', 'WORLD PERC patch entry 38: tone 0x26 variant 0'),
    ('LABEL_E0B045', 'WorldPerc_PatchEntry_039', 'WORLD PERC patch entry 39: tone 0x27 variant 0'),
    ('LABEL_E0B048', 'WorldPerc_PatchEntry_040', 'WORLD PERC patch entry 40: tone 0x28 variant 0'),
    ('LABEL_E0B04B', 'WorldPerc_PatchEntry_041', 'WORLD PERC patch entry 41: tone 0x29 variant 0'),
    ('LABEL_E0B04E', 'WorldPerc_PatchEntry_042', 'WORLD PERC patch entry 42: tone 0x2a variant 0'),
    ('LABEL_E0B051', 'WorldPerc_PatchEntry_043', 'WORLD PERC patch entry 43: tone 0x2b variant 0'),
    ('LABEL_E0B054', 'WorldPerc_PatchEntry_044', 'WORLD PERC patch entry 44: tone 0x2c variant 0'),
    ('LABEL_E0B057', 'WorldPerc_PatchEntry_045', 'WORLD PERC patch entry 45: aligned_string "-" pad + tone 0x2e'),
    ('LABEL_E0B05A', 'WorldPerc_PatchEntry_046', 'WORLD PERC patch entry 46: tone 0x2e variant 0'),
    ('LABEL_E0B05D', 'WorldPerc_PatchEntry_047', 'WORLD PERC patch entry 47: tone 0x2f variant 0'),
    ('LABEL_E0B060', 'WorldPerc_PatchEntry_048', 'WORLD PERC patch entry 48: tone 0x30 variant 0'),
    ('LABEL_E0B063', 'WorldPerc_PatchEntry_049', 'WORLD PERC patch entry 49: tone 0x31 variant 0'),
    ('LABEL_E0B066', 'WorldPerc_PatchEntry_050', 'WORLD PERC patch entry 50: tone 0x32 variant 0'),
    ('LABEL_E0B069', 'WorldPerc_PatchEntry_051', 'WORLD PERC patch entry 51: tone 0x33 variant 0'),
    ('LABEL_E0B06C', 'WorldPerc_PatchEntry_052', 'WORLD PERC patch entry 52: tone 0x34 variant 0'),
    ('LABEL_E0B06F', 'WorldPerc_PatchEntry_053', 'WORLD PERC patch entry 53: aligned_string "5" pad + tone 0x36'),
    ('LABEL_E0B072', 'WorldPerc_PatchEntry_054', 'WORLD PERC patch entry 54: tone 0x36 variant 0'),
    ('LABEL_E0B075', 'WorldPerc_PatchEntry_055', 'WORLD PERC patch entry 55: tone 0x37 variant 0'),
    ('LABEL_E0B078', 'WorldPerc_PatchEntry_056', 'WORLD PERC patch entry 56: tone 0x38 variant 0'),
    ('LABEL_E0B07B', 'WorldPerc_PatchEntry_057', 'WORLD PERC patch entry 57: tone 0x39 variant 0'),
    ('LABEL_E0B07E', 'WorldPerc_PatchEntry_058', 'WORLD PERC patch entry 58: tone 0x3a variant 0'),
    ('LABEL_E0B081', 'WorldPerc_PatchEntry_059', 'WORLD PERC patch entry 59: tone 0x3b variant 0'),
    ('LABEL_E0B084', 'WorldPerc_PatchEntry_060', 'WORLD PERC patch entry 60: tone 0x3c variant 0'),
    ('LABEL_E0B087', 'WorldPerc_PatchEntry_061', 'WORLD PERC patch entry 61: aligned_string "=" pad + tone 0x3e'),
    ('LABEL_E0B08A', 'WorldPerc_PatchEntry_062', 'WORLD PERC patch entry 62: tone 0x3e variant 0'),
    ('LABEL_E0B08D', 'WorldPerc_PatchEntry_063', 'WORLD PERC patch entry 63: tone 0x3f variant 0'),
    ('LABEL_E0B090', 'WorldPerc_PatchEntry_064', 'WORLD PERC patch entry 64: tone 0x40 variant 0'),
    ('LABEL_E0B093', 'WorldPerc_PatchEntry_065', 'WORLD PERC patch entry 65: tone 0x41 variant 0'),
    ('LABEL_E0B096', 'WorldPerc_PatchEntry_066', 'WORLD PERC patch entry 66: tone 0x42 variant 0'),
    ('LABEL_E0B099', 'WorldPerc_PatchEntry_067', 'WORLD PERC patch entry 67: tone 0x43 variant 0'),
    ('LABEL_E0B09C', 'WorldPerc_PatchEntry_068', 'WORLD PERC patch entry 68: tone 0x44 variant 0'),
    ('LABEL_E0B09F', 'WorldPerc_PatchEntry_069', 'WORLD PERC patch entry 69: aligned_string "E" pad + tone 0x46'),
    ('LABEL_E0B0A2', 'WorldPerc_PatchEntry_070', 'WORLD PERC patch entry 70: tone 0x46 variant 0'),
    ('LABEL_E0B0A5', 'WorldPerc_PatchEntry_071', 'WORLD PERC patch entry 71: tone 0x47 variant 0'),
    ('LABEL_E0B0A8', 'WorldPerc_PatchEntry_072', 'WORLD PERC patch entry 72: tone 0x48 variant 0'),
    ('LABEL_E0B0AB', 'WorldPerc_PatchEntry_073', 'WORLD PERC patch entry 73: tone 0x49 variant 0'),
    ('LABEL_E0B0AE', 'WorldPerc_PatchEntry_074', 'WORLD PERC patch entry 74: tone 0x4a variant 0'),
    ('LABEL_E0B0B1', 'WorldPerc_PatchEntry_075', 'WORLD PERC patch entry 75: tone 0x4b variant 0'),
    ('LABEL_E0B0B4', 'WorldPerc_PatchEntry_076', 'WORLD PERC patch entry 76: tone 0x4c variant 0'),
    ('LABEL_E0B0B7', 'WorldPerc_PatchEntry_077', 'WORLD PERC patch entry 77: aligned_string "M" pad + tone 0x4e'),
    ('LABEL_E0B0BA', 'WorldPerc_PatchEntry_078', 'WORLD PERC patch entry 78: tone 0x4e variant 0'),
    ('LABEL_E0B0BD', 'WorldPerc_PatchEntry_079', 'WORLD PERC patch entry 79: tone 0x4f variant 0'),
    ('LABEL_E0B0C0', 'WorldPerc_PatchEntry_080', 'WORLD PERC patch entry 80: tone 0x50 variant 0'),
    ('LABEL_E0B0C3', 'WorldPerc_PatchEntry_081', 'WORLD PERC patch entry 81: tone 0x51 variant 0'),
    ('LABEL_E0B0C6', 'WorldPerc_PatchEntry_082', 'WORLD PERC patch entry 82: tone 0x52 variant 0'),
    ('LABEL_E0B0C9', 'WorldPerc_PatchEntry_083', 'WORLD PERC patch entry 83: tone 0x53 variant 0'),
    ('LABEL_E0B0CC', 'WorldPerc_PatchEntry_084', 'WORLD PERC patch entry 84: tone 0x54 variant 0'),
    ('LABEL_E0B0CF', 'WorldPerc_PatchEntry_085', 'WORLD PERC patch entry 85: aligned_string "U" pad + tone 0x56'),
    ('LABEL_E0B0D2', 'WorldPerc_PatchEntry_086', 'WORLD PERC patch entry 86: tone 0x56 variant 0'),
    ('LABEL_E0B0D5', 'WorldPerc_PatchEntry_087', 'WORLD PERC patch entry 87: tone 0x57 variant 0'),
    ('LABEL_E0B0D8', 'WorldPerc_PatchEntry_088', 'WORLD PERC patch entry 88: tone 0x58 variant 0'),
    ('LABEL_E0B0DB', 'WorldPerc_PatchEntry_089', 'WORLD PERC patch entry 89: tone 0x59 variant 0'),
    ('LABEL_E0B0DE', 'WorldPerc_PatchEntry_090', 'WORLD PERC patch entry 90: tone 0x5a variant 0'),
    ('LABEL_E0B0E1', 'WorldPerc_PatchEntry_091', 'WORLD PERC patch entry 91: tone 0x5b variant 0'),
    ('LABEL_E0B0E4', 'WorldPerc_PatchEntry_092', 'WORLD PERC patch entry 92: tone 0x5c variant 0'),
    ('LABEL_E0B0E7', 'WorldPerc_PatchEntry_093', 'WORLD PERC patch entry 93: aligned_string "]" pad + tone 0x5e'),
    ('LABEL_E0B0EA', 'WorldPerc_PatchEntry_094', 'WORLD PERC patch entry 94: tone 0x5e variant 0'),
    ('LABEL_E0B0ED', 'WorldPerc_PatchEntry_095', 'WORLD PERC patch entry 95: tone 0x5f variant 0'),
    ('LABEL_E0B0F0', 'WorldPerc_PatchEntry_096', 'WORLD PERC patch entry 96: tone 0x60 variant 0'),
    ('LABEL_E0B0F3', 'WorldPerc_PatchEntry_097', 'WORLD PERC patch entry 97: tone 0x61 variant 0'),
    ('LABEL_E0B0F6', 'WorldPerc_PatchEntry_098', 'WORLD PERC patch entry 98: tone 0x62 variant 0'),
    ('LABEL_E0B0F9', 'WorldPerc_PatchEntry_099', 'WORLD PERC patch entry 99: tone 0x63 variant 0'),
    ('LABEL_E0B0FC', 'WorldPerc_PatchEntry_100', 'WORLD PERC patch entry 100: tone 0x64 variant 0'),
    ('LABEL_E0B0FF', 'WorldPerc_PatchEntry_101', 'WORLD PERC patch entry 101: aligned_string "e" pad + tone 0x66'),
    ('LABEL_E0B102', 'WorldPerc_PatchEntry_102', 'WORLD PERC patch entry 102: tone 0x66 variant 0'),
    ('LABEL_E0B105', 'WorldPerc_PatchEntry_103', 'WORLD PERC patch entry 103: tone 0x67 variant 0'),
    ('LABEL_E0B108', 'WorldPerc_PatchEntry_104', 'WORLD PERC patch entry 104: tone 0x68 variant 0'),
    ('LABEL_E0B10B', 'WorldPerc_PatchEntry_105', 'WORLD PERC patch entry 105: tone 0x69 variant 0'),
    ('LABEL_E0B10E', 'WorldPerc_PatchEntry_106', 'WORLD PERC patch entry 106: tone 0x6a variant 0'),
    ('LABEL_E0B111', 'WorldPerc_PatchEntry_107', 'WORLD PERC patch entry 107: tone 0x6b variant 0'),
    ('LABEL_E0B114', 'WorldPerc_PatchEntry_108', 'WORLD PERC patch entry 108: tone 0x6c variant 0'),
    ('LABEL_E0B117', 'WorldPerc_PatchEntry_109', 'WORLD PERC patch entry 109: aligned_string "m" pad + tone 0x6e'),
    ('LABEL_E0B11A', 'WorldPerc_PatchEntry_110', 'WORLD PERC patch entry 110: tone 0x6e variant 0'),
    ('LABEL_E0B11D', 'WorldPerc_PatchEntry_111', 'WORLD PERC patch entry 111: tone 0x6f variant 0'),
    ('LABEL_E0B120', 'WorldPerc_PatchEntry_112', 'WORLD PERC patch entry 112: tone 0x70 variant 0'),
    ('LABEL_E0B123', 'WorldPerc_PatchEntry_113', 'WORLD PERC patch entry 113: tone 0x71 variant 0'),
    ('LABEL_E0B126', 'WorldPerc_PatchEntry_114', 'WORLD PERC patch entry 114: tone 0x72 variant 0'),
    ('LABEL_E0B129', 'WorldPerc_PatchEntry_115', 'WORLD PERC patch entry 115: tone 0x73 variant 0'),
    ('LABEL_E0B12C', 'WorldPerc_PatchEntry_116', 'WORLD PERC patch entry 116: tone 0x74 variant 0'),
    ('LABEL_E0B12F', 'WorldPerc_PatchEntry_117', 'WORLD PERC patch entry 117: aligned_string "u" pad + tone 0x76'),
    ('LABEL_E0B132', 'WorldPerc_PatchEntry_118', 'WORLD PERC patch entry 118: tone 0x76 variant 0'),
    ('LABEL_E0B135', 'WorldPerc_PatchEntry_119', 'WORLD PERC patch entry 119: tone 0x77 variant 0'),
    ('LABEL_E0B138', 'WorldPerc_PatchEntry_120', 'WORLD PERC patch entry 120: tone 0x78 variant 0'),
    ('LABEL_E0B13B', 'WorldPerc_PatchEntry_121', 'WORLD PERC patch entry 121: tone 0x79 variant 0'),
    ('LABEL_E0B13E', 'WorldPerc_PatchEntry_122', 'WORLD PERC patch entry 122: tone 0x7a variant 0'),
    ('LABEL_E0B141', 'WorldPerc_PatchEntry_123', 'WORLD PERC patch entry 123: tone 0x7b variant 0'),
    ('LABEL_E0B144', 'WorldPerc_PatchEntry_124', 'WORLD PERC patch entry 124: tone 0x7c variant 0'),
    ('LABEL_E0B147', 'WorldPerc_PatchEntry_125', 'WORLD PERC patch entry 125: aligned_string "}" pad + tone 0x7e'),
    ('LABEL_E0B14A', 'WorldPerc_PatchEntry_126', 'WORLD PERC patch entry 126: tone 0x7e variant 0'),
    ('LABEL_E0B14D', 'WorldPerc_PatchEntry_127', 'WORLD PERC patch entry 127: tone 0x7f variant 0'),

    # -------------------------------------------------------------------------
    # Style/sequencer UI parameter data blocks (E0B4ED-E0B9ED)
    # Referenced via pointer table at E0BA60. Each block contains TUI widget
    # definitions (begin byte 0x06/0x07/0x20 sequences) with ASCII labels like
    # "BAL"=Balance, "ERS", "VALUE", "MEAS"=Measure, "REP"=Repeat, "YES", "CTL".
    # The table at E0BA60 is indexed by style/track type (76 entries, 2 rows).
    # -------------------------------------------------------------------------
    ('LABEL_E0B4ED', 'StyleUI_ParamBlock_BAL', 'Style UI parameter block: BAL/ERS widget definitions (row A)'),
    ('LABEL_E0B5E7', 'StyleUI_ParamBlock_VALUE', 'Style UI parameter block: VALUE display widget definitions'),
    ('LABEL_E0B60E', 'StyleUI_ParamBlock_Common', 'Style UI parameter block: common parameter widget layout'),
    ('LABEL_E0B6A6', 'StyleUI_ParamBlock_Short', 'Style UI parameter block: short variant parameter layout'),
    ('LABEL_E0B6CD', 'StyleUI_ParamBlock_Extended', 'Style UI parameter block: extended parameter widget layout'),
    ('LABEL_E0B784', 'StyleUI_ParamBlock_Medium', 'Style UI parameter block: medium parameter widget layout'),
    ('LABEL_E0B843', 'StyleUI_ParamBlock_MEAS', 'Style UI parameter block: MEAS/REP widget definitions'),
    ('LABEL_E0B8DE', 'StyleUI_ParamBlock_AltA', 'Style UI parameter block: alternate A widget definitions'),
    ('LABEL_E0B905', 'StyleUI_ParamBlock_AltB', 'Style UI parameter block: alternate B widget definitions'),
    ('LABEL_E0B92E', 'StyleUI_ParamBlock_AltC', 'Style UI parameter block: alternate C widget definitions'),
    ('LABEL_E0B99D', 'StyleUI_ParamBlock_AltD', 'Style UI parameter block: alternate D widget definitions'),
    ('LABEL_E0B9ED', 'StyleUI_ParamBlock_AltE', 'Style UI parameter block: alternate E widget definitions'),

    # -------------------------------------------------------------------------
    # Style UI parameter data pointer table (E0BA60)
    # 76 entries (2 rows of 38), each pointing to a StyleUI_ParamBlock above.
    # Indexed by style track type to select the correct UI layout block.
    # -------------------------------------------------------------------------
    ('LABEL_E0BA60', 'StyleUI_ParamBlockPtrTable', 'Style UI parameter block pointer table (76 entries, 2 rows of 38 by style type)'),

    # -------------------------------------------------------------------------
    # Additional style/sequencer UI data blocks (E0BB90-E0E407)
    # These large incbin blocks contain further TUI widget/screen data used by
    # the style recorder, step programmer, and related sequencer UI screens.
    # -------------------------------------------------------------------------
    ('LABEL_E0BB90', 'StyleUI_ScreenData_Main', 'Style/sequencer UI screen data main block (e0bb90-e0c95a)'),
    ('LABEL_E0C95B', 'StyleUI_ScreenData_MeasCursor', 'Style UI screen data: MEAS/CURSOR variant (e0c95b-e0ca12)'),
    ('LABEL_E0CA13', 'StyleUI_ScreenData_YesCtl', 'Style UI screen data: YES/CTL button variant (e0ca13-e0caf6)'),
    ('LABEL_E0CAF7', 'StyleUI_ScreenData_CtlOnly', 'Style UI screen data: CTL-only button variant (e0caf7-e0cd1d)'),
    ('LABEL_E0CD1E', 'GUI_FormatStrings', 'GUI format/layout data with printf-style format strings (%1d, %2d, etc.)'),
    ('LABEL_E0CFDE', 'GUI_DisplayStructData', 'GUI display structure data block (screen layout descriptors)'),
    ('LABEL_E0E407', 'ToneGen_ParamTable', 'Tone generation parameter table (f0-prefix hardware register data)'),

    # -------------------------------------------------------------------------
    # MSP (Multi-Style Pad) default settings block (E15B80)
    # Follows the naka UI container data at E0E974-E15B20 (included via
    # naka_e0e974_e15b20.s). Contains default initialization values for the
    # MSP system: pad assignments, velocity tables, voice layouts.
    # Header bytes 0x48,0x4b,0x00,0x00 = "HK\0\0" (Technics data block marker).
    # -------------------------------------------------------------------------
    ('LABEL_E15B80', 'MSP_DefaultSettings', 'MSP (Multi-Style Pad) default initialization settings block'),

    # -------------------------------------------------------------------------
    # Composer/style settings block (E16184)
    # Contains: Technics block header (0x48,0x4b), style compiler bank name
    # strings ("Compile Bank 1", "Compile Bank 2", "User Bank 1", "User Bank 2"),
    # followed by a callback function pointer table used by the style compiler UI.
    # -------------------------------------------------------------------------
    ('LABEL_E16184', 'Composer_SettingsBlock', 'Composer/style compiler settings block with bank names and UI callback table'),

    # -------------------------------------------------------------------------
    # Composer callback function name string table (E163AC)
    # Array of pointers to aligned_string entries (E164D4-E169AE).
    # Each string is the name of a composer/style UI callback function,
    # corresponding to the function pointers in the Composer_SettingsBlock above.
    # Used for debug/lookup: function pointer -> name string.
    # -------------------------------------------------------------------------
    ('LABEL_E163AC', 'Composer_CallbackNameTable', 'Composer UI callback function name string pointer table'),

    # -------------------------------------------------------------------------
    # Composer debug function name strings (E164D4-E169AE)
    # Individual aligned_string entries, each holding the ASCII name of one
    # composer UI callback function. Ordered to match the function pointer table
    # in Composer_SettingsBlock (reversed — table built from end to start).
    # -------------------------------------------------------------------------
    ('LABEL_E164D4', 'FuncName_Empty_0', 'Empty string (null function name placeholder)'),
    ('LABEL_E164D6', 'FuncName_PsStylCnvVerProc', 'Function name string: "PsStylCnvVerProc"'),
    ('LABEL_E164E8', 'FuncName_SndArrLangCheck', 'Function name string: "SndArrLangCheck"'),
    ('LABEL_E164F8', 'FuncName_StylCnvLangCheck', 'Function name string: "StylCnvLangCheck"'),
    ('LABEL_E1650A', 'FuncName_Memful2LangCheck', 'Function name string: "Memful2LangCheck"'),
    ('LABEL_E1651C', 'FuncName_MemfulLangCheck', 'Function name string: "MemfulLangCheck"'),
    ('LABEL_E1652C', 'FuncName_SndMem1LangCheck', 'Function name string: "SndMem1LangCheck"'),
    ('LABEL_E1653E', 'FuncName_SndMemLangCheck', 'Function name string: "SndMemLangCheck"'),
    ('LABEL_E1654E', 'FuncName_SureLangCheck', 'Function name string: "SureLangCheck"'),
    ('LABEL_E1655C', 'FuncName_AttLangCheck', 'Function name string: "AttLangCheck"'),
    ('LABEL_E1656A', 'FuncName_S2cGridBoxProc', 'Function name string: "S2cGridBoxProc"'),
    ('LABEL_E1657A', 'FuncName_PsCtmAttStrBoxProc', 'Function name string: "PsCtmAttStrBoxProc"'),
    ('LABEL_E1658E', 'FuncName_CmpNameMenuBoxProc', 'Function name string: "CmpNameMenuBoxProc"'),
    ('LABEL_E165A2', 'FuncName_PsSCTxtBox2Proc', 'Function name string: "PsSCTxtBox2Proc"'),
    ('LABEL_E165B2', 'FuncName_PsSCTxtBoxProc', 'Function name string: "PsSCTxtBoxProc"'),
    ('LABEL_E165C2', 'FuncName_PsParaListBoxProc', 'Function name string: "PsParaListBoxProc"'),
    ('LABEL_E165D4', 'FuncName_AcSndArgGridBoxProc', 'Function name string: "AcSndArgGridBoxProc"'),
    ('LABEL_E165E8', 'FuncName_PsMspNameBnkProc', 'Function name string: "PsMspNameBnkProc"'),
    ('LABEL_E165FA', 'FuncName_AcApcToggleProc', 'Function name string: "AcApcToggleProc"'),
    ('LABEL_E1660A', 'FuncName_PsCstmCpNameBoxProc', 'Function name string: "PsCstmCpNameBoxProc"'),
    ('LABEL_E1661E', 'FuncName_PsMspRecBnkBoxProc', 'Function name string: "PsMspRecBnkBoxProc"'),
    ('LABEL_E16632', 'FuncName_PsMspRecPadBoxProc', 'Function name string: "PsMspRecPadBoxProc"'),
    ('LABEL_E16646', 'FuncName_PsMspMemBoxProc', 'Function name string: "PsMspMemBoxProc"'),
    ('LABEL_E16656', 'FuncName_PsMspMeasBoxProc', 'Function name string: "PsMspMeasBoxProc"'),
    ('LABEL_E16668', 'FuncName_AcEasyCmpGridBoxProc', 'Function name string: "AcEasyCmpGridBoxProc"'),
    ('LABEL_E1667E', 'FuncName_PsMspBnkNameBoxProc', 'Function name string: "PsMspBnkNameBoxProc"'),
    ('LABEL_E16692', 'FuncName_PsRgpSetBnkBoxProc', 'Function name string: "PsRgpSetBnkBoxProc"'),
    ('LABEL_E166A6', 'FuncName_AcCmpSetGridBoxProc', 'Function name string: "AcCmpSetGridBoxProc"'),
    ('LABEL_E166BA', 'FuncName_PsNameMemBoxProc', 'Function name string: "PsNameMemBoxProc"'),
    ('LABEL_E166CC', 'FuncName_PsCmpCpFPtnBoxProc', 'Function name string: "PsCmpCpFPtnBoxProc"'),
    ('LABEL_E166E0', 'FuncName_PsCmpCpFVariBoxProc', 'Function name string: "PsCmpCpFVariBoxProc"'),
    ('LABEL_E166F4', 'FuncName_PsCmpCpFGrpBoxProc', 'Function name string: "PsCmpCpFGrpBoxProc"'),
    ('LABEL_E16708', 'FuncName_PsCstmCpSwBoxProc', 'Function name string: "PsCstmCpSwBoxProc"'),
    ('LABEL_E1671A', 'FuncName_PsCstmCpBnkBoxProc', 'Function name string: "PsCstmCpBnkBoxProc"'),
    ('LABEL_E1672E', 'FuncName_AcS2cMemNoBoxProc', 'Function name string: "AcS2cMemNoBoxProc"'),
    ('LABEL_E16740', 'FuncName_PsS2cTransBoxProc', 'Function name string: "PsS2cTransBoxProc"'),
    ('LABEL_E16752', 'FuncName_PsSeqSongNoBoxProc', 'Function name string: "PsSeqSongNoBoxProc"'),
    ('LABEL_E16766', 'FuncName_PsS2cLmeasBoxProc', 'Function name string: "PsS2cLmeasBoxProc"'),
    ('LABEL_E16778', 'FuncName_PsS2cFmeasBoxProc', 'Function name string: "PsS2cFmeasBoxProc"'),
    ('LABEL_E1678A', 'FuncName_PsCmpMemBoxProc', 'Function name string: "PsCmpMemBoxProc"'),
    ('LABEL_E1679A', 'FuncName_PsCmpMeasBoxProc', 'Function name string: "PsCmpMeasBoxProc"'),
    ('LABEL_E167AC', 'FuncName_PsCmpQtzBoxProc', 'Function name string: "PsCmpQtzBoxProc"'),
    ('LABEL_E167BC', 'FuncName_AcCmpRecBoxProc', 'Function name string: "AcCmpRecBoxProc"'),
    ('LABEL_E167CC', 'FuncName_AcCmpTempoBoxProc', 'Function name string: "AcCmpTempoBoxProc"'),
    ('LABEL_E167DE', 'FuncName_VwVariBoxProc', 'Function name string: "VwVariBoxProc"'),
    ('LABEL_E167EC', 'FuncName_AcMspBnkSlBoxProc', 'Function name string: "AcMspBnkSlBoxProc"'),
    ('LABEL_E167FE', 'FuncName_AcApcMdBoxProc', 'Function name string: "AcApcMdBoxProc"'),
    ('LABEL_E1680E', 'FuncName_AcCmpMdBoxProc', 'Function name string: "AcCmpMdBoxProc"'),
    ('LABEL_E1681E', 'FuncName_AcMemNoBoxProc', 'Function name string: "AcMemNoBoxProc"'),
    ('LABEL_E1682E', 'FuncName_MspRgpShowHideFunc', 'Function name string: "MspRgpShowHideFunc"'),
    ('LABEL_E16842', 'FuncName_S2cShowHideFunc', 'Function name string: "S2cShowHideFunc"'),
    ('LABEL_E16852', 'FuncName_MspBnkShow', 'Function name string: "MspBnkShow"'),
    ('LABEL_E1685E', 'FuncName_StylCnvStorOkFunc', 'Function name string: "StylCnvStorOkFunc"'),
    ('LABEL_E16870', 'FuncName_CmpSetPageFunc', 'Function name string: "CmpSetPageFunc"'),
    ('LABEL_E16880', 'FuncName_StylCnvStorBnkSel', 'Function name string: "StylCnvStorBnkSel"'),
    ('LABEL_E16892', 'FuncName_SndArgGridCheck', 'Function name string: "SndArgGridCheck"'),
    ('LABEL_E168A2', 'FuncName_SndArgTtlCheck', 'Function name string: "SndArgTtlCheck"'),
    ('LABEL_E168B2', 'FuncName_ApcOnBasFunc', 'Function name string: "ApcOnBasFunc"'),
    ('LABEL_E168C0', 'FuncName_ApcOnOffFunc', 'Function name string: "ApcOnOffFunc"'),
    ('LABEL_E168CE', 'FuncName_EasyCmpGridCheck', 'Function name string: "EasyCmpGridCheck"'),
    ('LABEL_E168E0', 'FuncName_MspPlayModeFunc', 'Function name string: "MspPlayModeFunc"'),
    ('LABEL_E168F0', 'FuncName_MspNameBnkFunc', 'Function name string: "MspNameBnkFunc"'),
    ('LABEL_E16900', 'FuncName_MspRGrpSetBnkFunc', 'Function name string: "MspRGrpSetBnkFunc"'),
    ('LABEL_E16912', 'FuncName_MspRGrpSetGridCheck', 'Function name string: "MspRGrpSetGridCheck"'),
    ('LABEL_E16926', 'FuncName_S2cGridCheck', 'Function name string: "S2cGridCheck"'),
    ('LABEL_E16934', 'FuncName_CmpSetGridCheck', 'Function name string: "CmpSetGridCheck"'),
    ('LABEL_E16944', 'FuncName_CmpSetP1GridCheck', 'Function name string: "CmpSetP1GridCheck"'),
    ('LABEL_E16956', 'FuncName_CmpClrNoFunc', 'Function name string: "CmpClrNoFunc"'),
    ('LABEL_E16964', 'FuncName_CmpClrYesFunc', 'Function name string: "CmpClrYesFunc"'),
    ('LABEL_E16972', 'FuncName_MspNameOkFunc', 'Function name string: "MspNameOkFunc"'),
    ('LABEL_E16980', 'FuncName_MspNamingCheck', 'Function name string: "MspNamingCheck"'),
    ('LABEL_E16990', 'FuncName_CmpNameOkFunc', 'Function name string: "CmpNameOkFunc"'),
    ('LABEL_E1699E', 'FuncName_CmpNamingCheck', 'Function name string: "CmpNamingCheck"'),
    ('LABEL_E169AE', 'FuncName_CmpBndRngFunc', 'Function name string: "CmpBndRngFunc"'),

    # -------------------------------------------------------------------------
    # Small string data structures (E169BC-E169F2)
    # Each is a small struct: a .long pointer to a nearby aligned_string,
    # used as single-entry string descriptor tables (pointer + string pairs).
    # These appear to be named field descriptors for the composer/style system.
    # -------------------------------------------------------------------------
    ('LABEL_E169BC', 'StrDesc_Empty_0', 'Single-entry string descriptor: pointer to empty string'),
    ('LABEL_E169C0', 'StrVal_Empty_0', 'Empty string value for StrDesc_Empty_0'),
    ('LABEL_E169C2', 'StrDesc_RecordBits', 'String descriptor table: "solobit"/"recbit" field names (3-entry)'),
    ('LABEL_E169CE', 'StrVal_Empty_RecordBits', 'Empty string value entry in StrDesc_RecordBits'),
    ('LABEL_E169D0', 'StrVal_SoloBit', 'String value: "solobit" field name'),
    ('LABEL_E169D8', 'StrVal_RecBit', 'String value: "recbit" field name'),
    ('LABEL_E169E0', 'StrDesc_Empty_1', 'Single-entry string descriptor: pointer to empty string'),
    ('LABEL_E169E4', 'StrVal_Empty_1', 'Empty string value for StrDesc_Empty_1'),
    ('LABEL_E169E6', 'StrDesc_Empty_2', 'Single-entry string descriptor: pointer to empty string'),
    ('LABEL_E169EA', 'StrVal_Empty_2', 'Empty string value for StrDesc_Empty_2'),
    ('LABEL_E169EC', 'StrDesc_Empty_3', 'Single-entry string descriptor: pointer to empty string'),
    ('LABEL_E169F0', 'StrVal_Empty_3', 'Empty string value for StrDesc_Empty_3'),
    ('LABEL_E169F2', 'StrDesc_Empty_4', 'Single-entry string descriptor: pointer to empty string (region end)'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')
    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
