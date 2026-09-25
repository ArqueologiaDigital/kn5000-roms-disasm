#!/usr/bin/env python3
r"""carve_v142_dsp_zone_tail.py -- type the tail of the v1.42 sub-CPU DSP zone.

QUESTION THIS ANSWERS
    What are the 4,761 bytes 0x01E17F-0x01F417 of the sub-CPU payload?  Until
    2026-09-25 they were four `.byte` runs (DSP_Eff9_Param_Values, 620 B, and
    DSP_EffA_Param_Values, 3,183 B -- the largest name-only object in the
    subcpu lane -- plus the two pointer arrays) whose labels described only
    their first few bytes.  The zone header in subcpu_data_tables.s already
    said the four 100-entry effect pointer arrays "live further down this file,
    currently inside the DSP_EffA_Param_Values byte run".

    This script carves the range into the objects the firmware actually reads,
    each with its reader, and re-emits it as typed source:
      * DSP bytecode STREAMS (grammar of DSP_BytecodeInterpreter_Loop: [b0,b1,..],
        length = ((b0 & 0x0f) << 8) | b1, stop at a peeked high nibble 0xF);
      * parameter RECORD TABLES (grammar of DSP_TableWalk_Search: [len_hi,len_lo,
        id,..], stop at a 0xf0 byte);
      * the six coefficient LUT blobs of DSP_WriteLUTParamSet;
      * three 5-byte per-slot byte tables;
      * nine u32 POINTER ARRAYS, emitted as `.long <label>`.

HOW EVERY OBJECT BOUNDARY IS PINNED
    Every start address below comes from a READER: a code site that loads it
    (`lda xNN,(addr:24)` / `ld xNN,addr`), or an entry of one of the pointer
    arrays.  The script asserts, before emitting anything, that
      (a) walking each object by its own grammar ends EXACTLY at the next
          object's start, except for the explicitly listed unread tail bytes
          (1 pad byte after 8 of the small programs, 3 after each chip-1 LUT);
      (b) the objects tile 0x01E17F..0x01F418 with no gap and no overlap;
      (c) every non-zero entry of the nine pointer arrays resolves to a label
          in the freshly built ELF, and every in-range entry is an object start;
      (d) (--apply) the rebuilt ROM is byte-identical to the dump.

RUN
    python3 scripts/converters/carve_v142_dsp_zone_tail.py            # dry: checks + stats
    python3 scripts/converters/carve_v142_dsp_zone_tail.py --print    # show the emitted text
    python3 scripts/converters/carve_v142_dsp_zone_tail.py --apply    # rewrite the source

    Idempotent: on a tree where the carve is already applied it re-derives the
    same text and reports "already applied".
"""
import argparse
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "v142/subcpu/subcpu_data_tables.s")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
LO, HI = 0x01E17F, 0x01F418

rom = open(ROM, "rb").read()


def off(a):
    return a - 0xF000 + 0x100 if a >= 0xF000 else a - 0x400


def b(a):
    return rom[off(a)]


def u32(a):
    return struct.unpack("<I", rom[off(a):off(a) + 4])[0]


def walk_stream(a):
    ins = []
    while True:
        if b(a) >> 4 == 0xF:
            return a + 1, ins
        n = ((b(a) & 0x0F) << 8) | b(a + 1)
        assert n >= 2, hex(a)
        ins.append((a, b(a) >> 4, n))
        a += n


def walk_table(a):
    recs = []
    while True:
        if b(a) == 0xF0:
            return a + 1, recs
        n = (b(a) << 8) | b(a + 1)
        assert n >= 3, hex(a)
        recs.append((a, b(a + 2), n))
        a += n


def build_symbols():
    """Assemble + link the CURRENT tree into a temp dir; return {addr: [labels]}."""
    d = tempfile.mkdtemp(prefix="carve_tail_")
    o, e = os.path.join(d, "v.o"), os.path.join(d, "v.elf")
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                    "-I", "v142/subcpu", "-o", o, "v142/subcpu/kn5000_subprogram_v142.s"],
                   cwd=ROOT, check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", "v142/subcpu/subcpu.ld", "-o", e, o],
                   cwd=ROOT, check=True, capture_output=True)
    out = subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], check=True,
                         capture_output=True, text=True).stdout
    syms = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t" and not p[2].startswith("__"):
            syms.setdefault(int(p[0], 16), []).append(p[2])
    return syms, e


# --------------------------------------------------------------------------- the carve
# Each object: (addr, label, kind, header lines, extra).  kind is one of
#   table / stream / lut0 / lut1 / bytes5 / ptrs.  `pad` = unread bytes after the object.
R = "0x%06X"


def objects():
    O = []

    def add(addr, label, kind, hdr, **kw):
        O.append(dict(addr=addr, label=label, kind=kind, hdr=hdr, **kw))

    add(0x01E17F, "DSP_Eff9_Param_Descriptors", "table", [
        "; Parameter DESCRIPTOR table used INSTEAD of DSP_Param_Block_Ptrs_B[9] when DSP_WriteParameter",
        "; is called with WA = 1, BC = 9: DSP_WriteParam_EFFCase loads it with `lda xhl,(..:24)` and",
        "; hands it to DSP_ParameterWriteEngine as XDE.  Record grammar: DSP_TableWalk_Search (zone header).",
    ])
    add(0x01E19E, "DSP_Eff9_Param_Values", "table", [
        "; The pair pushed by DSP_WriteParam_EFFCase when the effect selector bc == 9: XHL = 0x01E17F",
        "; (the descriptor stream handed to DSP_ParameterWriteEngine as XDE) and 0x01E19E pushed as the",
        "; second argument. 0x1E19E - 0x1E17F = 31 bytes of descriptors.",
        "; Parameter VALUE table (the pushed argument): ends at its 0xf0 sentinel, 64 bytes.",
    ])
    add(0x01E1DE, "DSP_Eff10_Slot1_Algo_Bytecode", "stream", [
        "; ----- effect 10 MULTI TAP DELAY -- slot-1 override microprograms -----",
        "; Algorithm stream uploaded by EFF_Change_Case0xA (inside EFF_Change_WithDebug) INSTEAD of",
        "; EFF_AlgoProgram_PtrTable[10] when the target slot is 1: `lda xbc,(DSP_Eff10_Slot1_Algo_Bytecode:24)`",
        "; then DSP_WriteEFFConfig(slot 1, stream).  Stream grammar: DSP_BytecodeInterpreter_Loop.",
    ])
    add(0x01E342, "DSP_Eff10_Slot1_Coef_Bytecode", "stream", [
        "; Coefficient stream uploaded second by EFF_Change_Case0xA, in place of",
        "; EFF_CoefProgram_PtrTable[10], same DSP_WriteEFFConfig path.",
    ])
    add(0x01E40A, "DSP_EffA_Param_Descriptors", "table", [
        "; DESCRIPTOR table used instead of DSP_Param_Block_Ptrs_B[10] by DSP_WriteParam_EFFCase0xA",
        "; (DSP_WriteParameter with WA = 1, BC = 0x0A), passed to DSP_ParameterWriteEngine as XDE.",
    ])
    add(0x01E42D, "DSP_EffA_Param_Values", "table", [
        "; Same pair for effect selector bc == 0x0A (DSP_WriteParam_EFFCase0xA). 0x1E42D - 0x1E40A = 35.",
        "; VALUE table (the pushed argument), 105 bytes to its 0xf0 sentinel.  Until 2026-09-25 this label",
        "; ran on as ONE 3,183-byte .byte run over everything down to DSP_Param_Block_Ptrs_A: the",
        "; programs, LUTs, slot tables and two pointer arrays that follow are carved out of it by",
        "; scripts/converters/carve_v142_dsp_zone_tail.py, each from its own reader.",
    ])
    add(0x01E496, "EFF_Header_Program", "stream", [
        "; ----- fixed programs uploaded by the effect-slot layer (all streams: DSP_BytecodeInterpreter_Loop grammar) -----",
        "; EFF_WriteHeader(slot) uploads this with DSP_WriteGlobalConfig(0, ..) -- ONLY when",
        "; EFF_SlotToChip_Table[slot] == 0 (slots 0/1, IC311).",
    ])
    for i, a in enumerate((0x01E5C8, 0x01E5D3, 0x01E5DE, 0x01E5EA, 0x01E5F6)):
        add(a, "EFF_Disconnect_Program_Slot%d" % i, "stream",
            (["; EFF_Disconnect(slot, mode) uploads EFF_Disconnect_Program_PtrTable[..] to chip",
              "; EFF_SlotToChip_Table[slot] with DSP_WriteGlobalConfig.  Five programs, one per slot."]
             if i == 0 else []) +
            ["; Read by EFF_Disconnect as EFF_Disconnect_Program_PtrTable entry %d (slot %d, mode 0)." % (i, i)])
    for i, a in enumerate((0x01E602, 0x01E60D, 0x01E618, 0x01E624, 0x01E630)):
        add(a, "EFF_Link_Program_Slot%d" % i, "stream",
            (["; EFF_Link(slot, mode): same shape as EFF_Disconnect through EFF_Link_Program_PtrTable."]
             if i == 0 else []) +
            ["; Read by EFF_Link as EFF_Link_Program_PtrTable entry %d (slot %d, mode 0)." % (i, i)])
    add(0x01E63C, "DSP_AlgoChange_Program", "stream", [
        "; DSP_AlgorithmChange uploads this first, to chip 0 (IZ = 0), before EFF_LoadConfigs_ForChannel.",
    ])
    add(0x01E6BE, "DSP1_BootProgram", "stream", [
        "; Resident microcode, EFF_LoadConfigs_ForChannel upload #1: chip 0 (IC311).",
    ])
    boot = {0x01E7C5: 3, 0x01E891: 5, 0x01E8A7: 4, 0x01E947: 6, 0x01E996: 1, 0x01EA12: 2}
    first = True
    for a in sorted(boot):
        h = ["; Resident microcode for chip 1 (IC310), EFF_LoadConfigs_ForChannel chip-1 upload #%d%s." %
             (boot[a], " (after DSP_WaitForDelay(1))" if boot[a] == 3 else "")]
        if first:
            h = ["; EFF_LoadConfigs_ForChannel uploads the six chip-1 programs in the order",
                 "; 0x01E996, 0x01EA12, DSP_WaitForDelay(1), 0x01E7C5, 0x01E8A7, 0x01E891, 0x01E947 --",
                 "; not memory order; the StepN suffix is the upload position."] + h
            first = False
        add(a, "DSP2_BootProgram_Step%d" % boot[a], "stream", h)
    for i, a in enumerate((0x01EA24, 0x01EA39, 0x01EA4E, 0x01EA63)):
        add(a, "DSP_Mute_Program_Chip%d" % i, "stream",
            (["; DSP_Mute_WithDebug(chip) uploads DSP_Mute_Program_PtrTable[chip] with DSP_WriteGlobalConfig.",
              "; Four entries although only chips 0 and 1 exist.  Each program is followed by ONE 0x00 byte",
              "; that the interpreter never reads (it stops on the peeked 0xf0)."] if i == 0 else []) +
            ["; Read by DSP_Mute_WithDebug as DSP_Mute_Program_PtrTable entry %d (chip %d)." % (i, i)],
            pad=1)
    for i, a in enumerate((0x01EA78, 0x01EA87, 0x01EA96, 0x01EAA5)):
        add(a, "DSP_Unmute_Program_Chip%d" % i, "stream",
            (["; DSP_Unmute_WithDebug(chip) -> DSP_Unmute_Program_PtrTable[chip]; same one-byte unread tail."]
             if i == 0 else []) +
            ["; Read by DSP_Unmute_WithDebug as DSP_Unmute_Program_PtrTable entry %d (chip %d)." % (i, i)],
            pad=1)
    for i, a in enumerate((0x01EAB4, 0x01EAC8, 0x01EADC, 0x01EAE6, 0x01EAF0)):
        add(a, "EFF_Mute_Program_Slot%d" % i, "stream",
            (["; EFF_Mute_WithDebug(slot) uploads EFF_Mute_Program_PtrTable[slot] with DSP_WriteEFFConfig.",
              "; Slots 0/1 (IC311) carry the one-byte unread 0x00 tail; slots 2-4 (IC310) do not."]
             if i == 0 else []) +
            ["; Read by EFF_Mute_WithDebug as EFF_Mute_Program_PtrTable entry %d (slot %d)." % (i, i)],
            pad=1 if i < 2 else 0)
    lut = [(0x01EAFA, 9, 0), (0x01EB67, 9, 1), (0x01EBD4, 9, 2), (0x01EC41, 8, 0), (0x01ECA5, 8, 1), (0x01ED09, 8, 2)]
    for a, rows, var in lut:
        h = []
        if (rows, var) == (9, 0):
            h = ["; ----- the six coefficient tables of DSP_WriteLUTParamSet (0x03869B), the writer of translator",
                 "; opcode 0x74 (DSP_Op_0x74_LUTParamSet) -----",
                 "; Selection, from the reader: C = the NEXT BYTE OF THE CALLER'S VALUE STREAM (`ld c,(xwa+)` at",
                 "; 0x0386AD), i.e. the operand of the op74 value record `00 06 74 00 <C> 7a`; C == 1 picks the",
                 "; 8-row family (size word 0x20), anything else the 9-row family (0x24); XDE = variant 0/1/2",
                 "; picks one of three.  Measured over all 100 DSP_Param_Block_Ptrs_A value tables: 26 effects",
                 "; carry an op74 record; C == 1 for effects 15 32 33 34 35 53 96 97 98 99 (the distortion group,",
                 "; both rotaries, the four PEQ+COMPR/DIST/OVERDR combos) and C == 0 for the other 16.",
                 "; Layout, from the reader: +0 = base index byte (0x1D, the register number every op74",
                 "; DESCRIPTOR record carries); then ROWS of four 3-byte coefficients, each decoded by",
                 "; DSP_UnpackParam3B as big-endian 24-bit (b0 << 16 | b1 << 8 | b2 -- its `sla xbc,0` is a",
                 "; shift by 16).  Per row: DSP_WriteFreqParam(base + 4*row, coef0), three",
                 "; DSP_WriteCoeffData_5B(coef1..3), separated by COMMAND 0x01 / DATA 0x01 / DATA 0x60 and",
                 "; closed by COMMAND 0x03.  9 rows = 109 bytes; 8 rows = 97 bytes, and each 8-row table",
                 "; carries 3 MORE bytes (a 33rd coefficient) that the loop never reads."]
        h.append("; %d-row table, variant %d: read by DSP_WriteLUTParamSet when C %s 1 and XDE == %d." %
                 (rows, var, "!=" if rows == 9 else "==", var))
        add(a, "DSP_Op74_LUT_Rows%d_Var%d" % (rows, var), "lut0" if rows == 9 else "lut1", h,
            pad=0 if rows == 9 else 3)
    add(0x01ED6D, "EFF_SlotToChip_Table", "bytes5", [
        "; ----- per-effect-slot byte tables, indexed by slot 0..4 -----",
        "; Chip id of each effect slot: 0 = IC311 (uPD6383), 1 = IC310 (MN19413).  Read `ld xNN,table /",
        "; add xNN,slot / ld r,(xNN)` by DSP_WriteEFFConfig, DSP_ParameterWriteEngine, EFF_WriteHeader,",
        "; EFF_Disconnect and EFF_Link (five sites, all displacement 0).",
    ], comment="slots 0-1 -> chip 0, slots 2-4 -> chip 1")
    add(0x01ED72, "EFF_SlotSettleTime_Table", "bytes5", [
        "; Per-slot settle time, folded into a running maximum through Unsigned_Max_Select by",
        "; EFF_HeaderChangeLoop_ActiveSlot and EFF_SecLinkPath_Pass2MaxVol (`lda xwa,(table:24)` then",
        "; `ld a,(xwa+iz)`, IZ = slot).",
    ])
    add(0x01ED77, "EFF_SlotByteTable_Unreferenced", "bytes5", [
        "; Five more per-slot-shaped bytes (00 01 00 01 00).  Purpose not established: no reader found.",
        "; Searched: every 24-bit little-endian occurrence of 0x01ED77..0x01ED7B anywhere in the ROM (covers",
        "; lda :24, ld imm32, .long and d24 operands) -- none; the five 0x01ED6D and two 0x01ED72 loads all",
        "; index with displacement 0 and slot 0..4, so they cannot reach here.",
    ])
    arrays = [
        (0x01ED7C, "EFF_AlgoProgram_PtrTable", "algo", 100, [
            "; ----- the effect pointer arrays: u32, indexed by EFFECT NUMBER 0..99 -----",
            "; ALGORITHM bytecode stream per effect.  Read by EFF_Change_GenericLookup and",
            "; EFF_Change_ChannelNot1 (`sll xwa,2 / ld xbc,EFF_AlgoProgram_PtrTable / add xbc,xwa /",
            "; ld xbc,(xbc)`), uploaded with DSP_WriteEFFConfig.  Entry count 100: the zone header's",
            "; carve verification found all 400 entries of the four arrays on block starts, and the",
            "; arrays abut (0x190 = 400 bytes apart)."]),
        (0x01EF0C, "EFF_CoefProgram_PtrTable", "coef", 100, [
            "; COEFFICIENT bytecode stream per effect.  Read by EFF_Change_GenericLookup,",
            "; EFF_Change_ChannelNot1 and EFF_DataChange_WithDebug (same idiom), then DSP_WriteEFFConfig."]),
        (0x01F09C, "DSP_Param_Block_Ptrs_A", "vals", 100, [
            "; u32 pointer array indexed by the effect id (`sll xbc,2 / ld xiy,0x1F09C / add xiy,xbc /",
            "; ld xbc,(xiy)`) in DSP_WriteParam_Generic. Entries seen: 0, 0x01561A, 0x01591F, 0x015CD8,",
            "; 0x015F6C, 0x01633B, 0x017A92, 0, 0x01776C, 0x0180D0, 0x018359, 0 -- all pointing back into the",
            "; 0x014777.. blob, with 0 meaning \"no parameter block\".",
            "; These are the parameter VALUE record tables (the argument DSP_WriteParam_Generic pushes for",
            "; DSP_ParameterWriteEngine).  100 entries, abutting DSP_Param_Block_Ptrs_B."]),
        (0x01F22C, "DSP_Param_Block_Ptrs_B", "desc", 100, [
            "; The parallel array, same call site (`ld hl,bc / extz xhl / sll xhl,2 / ld xiy,0x1F22C`).",
            "; CORRECTED: an earlier header said it is \"indexed by the parameter id\".  It is not: HL is",
            "; copied from BC, the EFFECT id, which also indexes DSP_Param_Block_Ptrs_A two instructions",
            "; later -- both arrays are per effect.  These are the parameter DESCRIPTOR record tables,",
            "; passed to DSP_ParameterWriteEngine in XDE.",
            "; Entries: 0x017425, 0x01564B, 0x015969, 0x015D1B, 0x015FD3, 0x0163A2, 0x017AE3, 0x017425,",
            "; 0x01779F, 0x01811E, 0x0183CE, 0x017425 -- 0x017425 recurs as the default/fallback block.",
            "; The recurring 0x017425 is DSP_Eff00_Param_Descriptors,",
            "; the NO OPERATION stub shared by the 42 stub effects (zone header).  100 entries: the array",
            "; ends where EFF_Mute_Program_PtrTable, a separately-read table, begins."]),
        (0x01F3BC, "EFF_Mute_Program_PtrTable", "effmute", 5, [
            "; ----- per-slot / per-chip program pointer tables (u32) -----",
            "; EFF_Mute_WithDebug: `sll xwa,2 / ld xbc,EFF_Mute_Program_PtrTable / add xbc,xwa`, slot 0..4."]),
        (0x01F3D0, "DSP_Mute_Program_PtrTable", "dspmute", 4, [
            "; DSP_Mute_WithDebug, indexed by chip (four entries, two chips)."]),
        (0x01F3E0, "DSP_Unmute_Program_PtrTable", "dspunmute", 4, [
            "; DSP_Unmute_WithDebug, indexed by chip."]),
        (0x01F3F0, "EFF_Disconnect_Program_PtrTable", "disc", 5, [
            "; EFF_Disconnect: entry = table + 12*mode + 4*slot.  Five entries per mode run, but the code's",
            "; mode stride is 12, not 20 -- see the NOTE THE STRIDE in EFF_Disconnect: with mode 1, slots 2-4",
            "; read EFF_Link_Program_PtrTable[0..2]."]),
        (0x01F404, "EFF_Link_Program_PtrTable", "link", 5, [
            "; EFF_Link: same 12*mode + 4*slot indexing; with mode 1, slots 2-4 would read past this table."]),
    ]
    for a, lab, key, n, hdr in arrays:
        add(a, lab, "ptrs", hdr, n=n, key=key)
    return O


def effect_names(text):
    names = {}
    for m in re.finditer(r"^; ----- effect (\d+):? ([^-\n]+?)\s*(?:--.*)?-----", text, re.M):
        names.setdefault(int(m.group(1)), m.group(2).strip())
    return names


def fmt_bytes(bs, per=8):
    out = []
    for i in range(0, len(bs), per):
        out.append("\t.byte " + ", ".join("0x%02x" % x for x in bs[i:i + per]))
    return out


def emit(O, syms, names):
    lines = []
    stats = {}
    for i, o in enumerate(O):
        a = o["addr"]
        nxt = O[i + 1]["addr"] if i + 1 < len(O) else HI
        k = o["kind"]
        lines += o["hdr"]
        body = []
        if k == "stream":
            end, ins = walk_stream(a)
            desc = " ".join("op%x(%d)" % (op, n) for _, op, n in ins)
            body.append("; %d instruction%s: %s; 0xf0 end." % (len(ins), "" if len(ins) == 1 else "s", desc))
            body.append(o["label"] + ":")
            for x, op, n in ins:
                body += fmt_bytes(rom[off(x):off(x) + n])
            body.append("\t.byte 0xf0")
        elif k == "table":
            end, recs = walk_table(a)
            body.append("; %d records, ids: %s; 0xf0 sentinel." % (len(recs), " ".join("%02x" % r[1] for r in recs)))
            body.append(o["label"] + ":")
            for x, rid, n in recs:
                body += fmt_bytes(rom[off(x):off(x) + n], per=12)
            body.append("\t.byte 0xf0")
        elif k in ("lut0", "lut1"):
            rows = 9 if k == "lut0" else 8
            end = a + 1 + 12 * rows
            body.append(o["label"] + ":")
            body.append("\t.byte 0x%02x\t\t\t\t\t\t\t\t; base index" % b(a))
            for r in range(rows):
                x = a + 1 + 12 * r
                trip = [", ".join("0x%02x" % b(x + 3 * c + j) for j in range(3)) for c in range(4)]
                body.append("\t.byte " + ",  ".join(trip) + "\t; row %d" % r)
        elif k == "bytes5":
            end = a + 5
            body.append(o["label"] + ":")
            body.append("\t.byte " + ", ".join("%d" % b(a + j) for j in range(5)) +
                        ("\t; " + o["comment"] if o.get("comment") else ""))
        elif k == "ptrs":
            end = a + 4 * o["n"]
            body.append(o["label"] + ":")
            for j in range(o["n"]):
                t = u32(a + 4 * j)
                if t == 0:
                    body.append("\t.long\t0\t\t\t\t\t; %d" % j)
                    continue
                if t not in syms:
                    sys.exit("pointer %s[%d] = 0x%06X has no label" % (o["label"], j, t))
                lab = pick(syms[t])
                cmt = "%d" % j
                if o["key"] in ("algo", "coef", "vals", "desc"):
                    nm = names.get(j)
                    cmt = "effect %d%s" % (j, (" " + nm) if nm else "")
                tabs = "\t" * max(1, 5 - (len(lab) + 8) // 8)
                body.append("\t.long\t%s%s; %s" % (lab, tabs, cmt))
        pad = o.get("pad", 0)
        if end + pad != nxt:
            sys.exit("%s at 0x%06X: grammar end 0x%06X + pad %d != next object 0x%06X" %
                     (o["label"], a, end, pad, nxt))
        if pad:
            body.append("\t.byte " + ", ".join("0x%02x" % b(end + j) for j in range(pad)) +
                        "\t; not read (%d byte%s after the object's last read byte)" % (pad, "" if pad == 1 else "s"))
        lines += body
        stats[o["label"]] = nxt - a
    return lines, stats


def pick(labels):
    good = [l for l in labels if not re.search(r"_(Skip|Join|Loop|Sub|Return|Epilogue|Entry)\d*$", l)]
    return (good or labels)[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--print", action="store_true")
    a = ap.parse_args()
    raw = open(SRC, "rb").read()
    text = raw.decode("latin-1")
    O = objects()
    # tiling of the object list itself
    assert O[0]["addr"] == LO
    addrs = [o["addr"] for o in O]
    assert addrs == sorted(addrs) and len(set(addrs)) == len(addrs)
    syms, elf = build_symbols()
    for o in O:                      # the carve's own labels win inside the tail
        syms[o["addr"]] = [o["label"]]
    # every in-range pointer-array entry must be an object start
    starts = set(addrs)
    for o in O:
        if o["kind"] != "ptrs":
            continue
        for j in range(o["n"]):
            t = u32(o["addr"] + 4 * j)
            if LO <= t < HI and t not in starts:
                sys.exit("%s[%d] = 0x%06X is inside the tail but not an object start" % (o["label"], j, t))
    lines, stats = emit(O, syms, effect_names(text))
    new = "\n".join(lines) + "\n"
    # splice: from the line holding `DSP_Eff9_Param_Descriptors:` up to (not incl.) the first
    # comment line of the ToneGen_VelCurve_Pivot header.
    first_hdr = O[0]["hdr"][0] + "\n"
    head = text.find(first_hdr)
    if head < 0:
        head = text.find("DSP_Eff9_Param_Descriptors:\n")
    e = text.find("ToneGen_VelCurve_Pivot:\n")
    e = text.rfind("; u16 = 0x004D (77).", 0, e)
    assert 0 < head < e
    old = text[head:e]
    total = sum(stats.values())
    print("objects: %d, bytes %d (0x%06X-0x%06X)" % (len(O), total, LO, HI - 1))
    kinds = {}
    for o in O:
        kinds[o["kind"]] = kinds.get(o["kind"], 0) + stats[o["label"]]
    for k, v in sorted(kinds.items()):
        print("  %-7s %5d B" % (k, v))
    if a.print:
        print(new)
    if old == new:
        print("already applied")
        return
    if a.apply:
        out = text[:head] + new + text[e:]
        open(SRC, "wb").write(out.encode("latin-1"))
        print("rewrote %s: %d -> %d bytes of source in the span" % (os.path.relpath(SRC, ROOT), len(old), len(new)))
    else:
        print("dry run: span differs from the carve (use --apply)")


if __name__ == "__main__":
    main()
