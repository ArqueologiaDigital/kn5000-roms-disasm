#!/usr/bin/env python3
"""Spec for retype_data_objects.py: maincpu 0xEEDD36-0xEEE077 -- what the tree
called ScaleNote_Display_Table.  These bytes are part of WorkRamInit_Image:
Boot_InitWorkRAM_ROMCopy1_Start copies them to RAM 0x3D992..0x3DCD3, and the
UI code reads the RAM copy.  So each object's reader is found by the RAM
address, not the ROM one (RAM = ROM - 0xEED8C8 + 0x3D524)."""
import json

O = []
RAM = lambda a: a - 0xEED8C8 + 0x3D524


def ptrs(lo, n, label, what, reader, raddr, how):
    O.append(dict(lo="0x%06X" % lo, hi="0x%06X" % (lo + 4 * n), label=label, type="long",
                  header=["Initial value of RAM 0x%05X: %d x u32 pointers to %s." % (RAM(lo), n, what),
                          "Read from RAM by %s (0x%06X): %s." % (reader, raddr, how)]))


ptrs(0xEEDD36, 13, "RamInit_NumStrPtrs", "the number strings NumStr_0..11 and NoteStepDisplayData",
     "CmpBndRng_BoundCase", 0xF1A35A, "`cp bc,12; jr gt`, `sla bc,2; lda xde,(0x3D992); ld_rrl xbc,xde,bc`")
ptrs(0xEEDD6A, 12, "RamInit_NoteNamePtrs", "the note-name strings (C, Db, D ... B)",
     "UI_COMPONENT_DISPATCH_CASE2", 0xF1A820, "`ld xwa,0x3D9C6` (also GridCheck_SetMode1 0xF1A98B)")
ptrs(0xEEDD9A, 2, "RamInit_DisableEnablePtrs", "StrDisable / StrEnable",
     "UI_COMPONENT_DISPATCH_CASE1", 0xF1A7E5, "`sla wa,2; lda xbc,(0x3D9F6); ld_rrl xwa,xbc,wa`")
ptrs(0xEEDDA2, 2, "RamInit_MajorMinorPtrs", "StrMajor / StrMinor",
     "UI_COMPONENT_DISPATCH_CASE3", 0xF1A82B, "`ld xwa,0x3D9FE`, index = bit 4 of RAM 0x34EA")
ptrs(0xEEDDAA, 2, "RamInit_NormalSeventhPtrs", "StrNormal / StrSeventh",
     "CmpSetP1_GridCheck_Return", 0xF1A78B, "`lda xhl,(0x3DA06)`, index = value - 1")
ptrs(0xEEDDB2, 16, "RamInit_TimeSigPtrs", "the time-signature strings 1/2 .. 4/8",
     "UI_COMPONENT_DISPATCH_CASE1", 0xF1A7E5, "`ldb_d8 a,(0x34D8); sla wa,2; lda xbc,(0x3DA0E); ld_rrl`")
ptrs(0xEEDDF2, 128, "RamInit_PanStrPtrs", "the pan strings StrPanLeft64 .. StrPanCenter .. StrPanRight63",
     "CmpSet_GridCheck_Dispatch", 0xF1A95C, "`ld xiz,0x3DA4E` then a lookup by pan value")
ptrs(0xEEDFF2, 17, "RamInit_BeatStrPtrs", "StrBeatOff, StrBeat01 .. StrBeat16",
     "S2c_GridCheck_Dispatch", 0xF1B341, "`sla wa,2; lda xbc,(0x3DC4E); ld_rrl xwa,xbc,wa`")
ptrs(0xEEE036, 10, "RamInit_GenreStrPtrs", "the style-genre strings (8 Beat .. Waltz)",
     "EasyCmp_GridCheck_EventEnc", 0xF1C372, "`sla wa,2; lda xbc,(0x3DC92); ld_rrl xwa,xbc,wa`")
O.append(dict(lo="0x%06X" % 0xEEE05E, hi="0x%06X" % 0xEEE078, label="RamInit_WidgetState_3DCBA",
              type="byte", per_line=13, row_ram="0x3DCBA",
              header=["Initial values of RAM 0x3DCBA..0x3DCD3: per-widget state cells named by",
                      "32-bit pointers in NAKA widget descriptors (NakaData_SeqChannels+0x1E,",
                      "FDTest_DiagList_Total/NG/OK+0x2E, FDTest_Container_DebugHDAE1/2+0x1E,",
                      "FDTest_ConsoleArea1/2+0x26, FDTest_StatusBar1+0x16).  The image continues",
                      "in ui_widgets/sequencer_channel_containers.s."]))

O[0]["retire"] = ["ScaleNote_Display_Table"]
print(json.dumps({"objects": O}, indent=1))
