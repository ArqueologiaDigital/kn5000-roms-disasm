#!/usr/bin/env python3
r"""hdae5000_symbolize_ram.py -- named RAM variables for the HD-AE5000 code.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
The code addresses its RAM (0x200000-0x23FFFF, the expansion's SRAM) by
number: `ld xwa,(0x23a1a2)` 957 times, `cp (0x200222:24),0` after every disk
operation, `(0x23a092:24)` for the selected directory.  This tool gives a
curated set of those addresses a name -- only variables whose role the code
shows, each with the evidence in its `.equ` comment -- and rewrites every
operand that is exactly that address (`(N)`, `(N:24)`, `N` immediates, hex or
decimal).  The values are unchanged, so the encodings are too.

The `.equ` block is written right after the `.include "shared/event_codes.s"`
line of hd-ae5000_v2_06i.s, before any code, so every use is a backward
reference.

RUN
    python3 scripts/converters/hdae5000_symbolize_ram.py [--apply]
--apply re-links through scripts/analysis/hdae5000_line_map.py (refuses unless
the tree is byte-identical).
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

# address: (name, evidence)
RAM = {
    0x23A1A2: ("MainWorkspacePtr", "the main CPU's workspace; every call into it is (this)->0x0E88 or"
                                   " ->0x0E0A table + offset (init image: 4 bytes after HDAE5000_LyricBoxObj_Init;"
                                   " the object table at 0x027ED2)"),
    0x200222: ("AtaError", "drive error byte: 0 = ok; set by the HDAE5000_ATA_* routines, tested"
                           " after every disk operation"),
    0x229D92: ("HdInitResult", "HDAE5000_HD_Init's step code, returned by HDAE5000_Check_HD_Present"),
    0x229D98: ("HdSignatureOk", "1 when sector 1 carries AA55AA55 F4F1F2F3 (HDAE5000_HD_CheckSignature)"),
    0x229C58: ("ClusterBytes", "cluster size in bytes (HDAE5000_HD_ParseIdentify)"),
    0x229C5C: ("SectorsPerCluster", "0x20, or 0x40 on drives of >= 0x14DC93 sectors (HD_ParseIdentify)"),
    0x229C64: ("TablesStartSector", "first of the 323 filesystem-table sectors, 3908 (HD_ParseIdentify)"),
    0x229C68: ("FatStartSector", "2 (HD_ParseIdentify)"),
    0x229C6C: ("DataStartSector", "4231, cluster 1's first sector (HD_ParseIdentify)"),
    0x229C70: ("FatEntryCount", "FAT entries, whole 128-entry sectors (HD_ParseIdentify)"),
    0x229C80: ("FreeClusters", "free-cluster count (HDAE5000_HD_CountFreeClusters, WriteFile, FreeChain)"),
    0x229C94: ("DataSectorCount", "sectors from DataStartSector to the end (HD_ParseIdentify)"),
    0x229D99: ("WriteProtect", "\"WRITE PROTECTION\" of HDAE5000_TitleInfo_Template, 0/1 = OFF/ON"),
    0x229D9A: ("WriteConfirm", "\"WRITE CONFIRM\" of HDAE5000_TitleInfo_Template, 0/1 = OFF/ON"),
    0x229DA9: ("QuickLoadMode", "\"QUICK LOAD MODE\" (TitleInfo); one of the six setting bytes of sector 1"),
    0x229DAA: ("LoadByNumberMode", "\"LOAD BY NUMBER MODE\" (TitleInfo); sector-1 setting byte"),
    0x229DAB: ("JumpAfterLoad", "\"JUMP AFTER LOAD\" (TitleInfo); sector-1 setting byte"),
    0x201632: ("DirNames", "directory names, 16 B x 120 (HDAE5000_HD_GetBlockInfo block 0)"),
    0x201DB2: ("SongRecords", "song records, 76 B x 1920 (HDAE5000_HD_GetBlockInfo block 1)"),
    0x2257B2: ("FlsRecords", "FLS records, 144 B x 120 (HDAE5000_HD_GetBlockInfo block 2)"),
    0x23A08E: ("DirPageBase", "first directory of the list page (HDAE5000_DirList_BuildPage)"),
    0x23A090: ("FlsPageBase", "first FLS of the list page (HDAE5000_FlsList_BuildPage)"),
    0x23A092: ("CurDir", "selected directory (HDAE5000_SongScreen_Refresh, Song_PartMask callers)"),
    0x23A094: ("CurSong", "selected song within CurDir (HDAE5000_SongScreen_Refresh)"),
    0x23A096: ("CurFls", "selected FLS (HDAE5000_FlsScreen_Refresh)"),
    0x22AA4C: ("SaveOptions", "12-byte part-selection record of the save options: u16 mask, then"
                              " flags 0x22AA4E+k (HDAE5000_TypeSel_*)"),
    0x22ABE6: ("DeleteOptions", "12-byte part-selection record of the delete options (HDAE5000_DelOpt_*)"),
    0x22AA5C: ("LbnDigitPos", "load-by-number digit position 0..5 (HDAE5000_Lbn_TypeDigit)"),
    0x22AA5E: ("LbnDir", "load-by-number directory number being typed (HDAE5000_Lbn_TypeDigit)"),
    0x22AA60: ("LbnSong", "load-by-number song number being typed (HDAE5000_Lbn_TypeDigit)"),
    0x22B2F4: ("SeparateOutputMode", "0..3 = OFF / DRUMS L/R / BASS+DRUMS MIX / BASS/DRUMS MONO"
                                     " (HDAE5000_SeparateOutput_Apply)"),
    0x23A0A0: ("SeparateDrumPart", "drum part, 0 = NONE (SeparateDrumPartCheck's value; _Apply)"),
    0x23A09E: ("SeparateBassPart", "bass part, 0 = NONE (SeparateBassPartCheck's value; _Apply)"),
    0x23A0A2: ("SeparateDrumPartSent", "drum part last sent by HDAE5000_SeparateOutput_Apply"),
    0x23A0A4: ("SeparateBassPartSent", "bass part last sent by HDAE5000_SeparateOutput_Apply"),
    0x230F1C: ("HdStreamBuffer", "0x8000-byte buffer of the streamed file writes/reads"
                                 " (HDAE5000_HD_WriteStream, the part loaders/savers)"),
    0x238F1C: ("HdStreamBufferEnd", "end of HdStreamBuffer (HDAE5000_HD_WriteStream)"),
    0x238F24: ("HdStreamFill", "fill pointer into HdStreamBuffer (HDAE5000_HD_WriteOpen/_WriteStream)"),
    0x238F28: ("HdStreamSlot", "the first-cluster slot of the open buffered write (HD_WriteOpen)"),
    0x238F2C: ("HdStreamState", "0 closed, 1 open and nothing written, 2 written (HD_WriteOpen)"),
    0x239168: ("PportPacket", "the 256-byte PC-link packet (HDAE5000_PPORT_SendPacket/RecvPacket)"),
    0x2390D4: ("PportError", "PC-link error flag, set to 1 by PPORT_RecvByte/SendByte/EndBlock"),
    0x2390FC: ("PportChecksum", "32-bit running sum of the PC-link block in transfer"),
    # second run (lyrics player; the three setting names are the firmware's
    # own handler names in HDAE5000_ObjHandler_Table, each returning the
    # address of its byte)
    0x229DAC: ("LyricJump", "sector-1 setting byte; handler \"LyricJumpEditCheck\" returns its address"),
    0x229DAD: ("LyricForeColor", "sector-1 setting byte 0..4; \"LyricForeColorCheck\"; palette code"
                                 " via HDAE5000_Lyrics_ResetState"),
    0x229DAE: ("LyricBackColor", "sector-1 setting byte 0..4; \"LyricBackColorCheck\"; palette code"
                                 " via HDAE5000_Lyrics_ResetState"),
    0x22B430: ("LyricBuffer", "the lyric file, 0x5000 bytes: TLhd/TLtr chunks, events from +22"
                              " (HDAE5000_Lyrics_ClearBuffer, _ParseEvent)"),
    0x23A0AA: ("LyricLines", "six 40-byte text lines of the lyric window (HDAE5000_Lyrics_FillLines)"),
    0x23A19C: ("LyricLoaded", "1 once a lyric file passed its checks (HDAE5000_Lyrics_CheckFile)"),
    0x23A19E: ("LyricBoxObj", "the open lyric box's object id, 0xFFFFFFFF when closed"
                              " (HDAE5000_LyricBoxProc); redraw events go to it"),
}
FILE_MAIN = "hd-ae5000_v2_06i.s"
NUM = re.compile(r"(?<![\w.$+\-])(0x[0-9a-fA-F]+|\d{6,})(?![\w.$])")


def main(apply):
    src = {rel: open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n") for rel in hlm.FILES}
    sym = {a: "HDAE5000_RAM_" + n for a, (n, ev) in RAM.items()}
    counts = collections.Counter()
    for rel in ("hd-ae5000_v2_06i.s", "hdae5000_hd_driver.s", "hdae5000_filesystem.s",
                "hdae5000_ui_display.s", "hdae5000_utilities.s"):
        L = src[rel]
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")
            s = code.strip()
            if not s or s.startswith(".") or s.endswith(":"):
                continue
            if re.match(r"^[.\w$]+:\s*$", s):
                continue
            mn = s.split()[0].lower() if not re.match(r"^[.\w$]+:", s) else s.split(":", 1)[1].split()[0].lower() if s.split(":", 1)[1].split() else ""
            if mn.startswith("."):
                continue

            def sub(m):
                v = int(m.group(1), 16) if m.group(1).lower().startswith("0x") else int(m.group(1))
                if v in sym:
                    counts[sym[v]] += 1
                    return sym[v]
                return m.group(0)
            new = NUM.sub(sub, code)
            if new != code:
                L[i] = new + sep + com
    print("RAM names %d; operands replaced %d" % (len(sym), sum(counts.values())))
    for k, v in counts.most_common():
        print("  %5d %s" % (v, k))
    if not apply:
        return
    L = src[FILE_MAIN]
    have = [i for i, ln in enumerate(L) if ln.startswith("\t.equ HDAE5000_RAM_")]
    if have:
        # a block from an earlier run exists: add only the missing names, in
        # address order, after its last line (re-running is idempotent)
        present = {re.match(r"\t\.equ (\w+),", L[i]).group(1) for i in have}
        new = ["\t.equ %s, 0x%06x\t; %s" % (sym[a], a, RAM[a][1]) for a in sorted(RAM) if sym[a] not in present]
        L[have[-1] + 1:have[-1] + 1] = new
        print("added %d .equ lines to the existing block" % len(new))
        for rel, L2 in src.items():
            open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write("\n".join(L2))
        hlm.build_map()
        print("applied; relinked mirror byte-identical")
        return
    at = next(i for i, ln in enumerate(L) if ln.strip().startswith('.include "shared/event_codes.s"'))
    block = ["",
             "; ----------------------------------------------------------------------------",
             "; RAM variables (the expansion's SRAM 0x200000-0x23FFFF) whose role the code",
             "; shows; each comment names the evidence.  Operands equal to one of these",
             "; addresses were rewritten by scripts/converters/hdae5000_symbolize_ram.py.",
             "; ----------------------------------------------------------------------------"]
    for a in sorted(RAM):
        n, ev = RAM[a]
        block.append("\t.equ %s, 0x%06x\t; %s" % (sym[a], a, ev))
    L[at + 1:at + 1] = block
    for rel, L in src.items():
        open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write("\n".join(L))
    hlm.build_map()
    print("applied; relinked mirror byte-identical")


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
