#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF62C00-0xF64FFF -- the BLOCK-STORE module.

QUESTION IT ANSWERS
    "What is the assembly text for the module that thunk run T_F42770-T_F42830
     names, in a form the byte gate accepts, with every label and header
     attached to the right address?"  This is the emitter whose output is
     pasted into prom_b/wsa1_prom_b.s.

WHY THIS MODULE
    notes/prom_b_call_graph.py ranks it first and second among ALL unconverted
    prom_b thunk targets: T_F4279C -> 0xF635C9 (x43) and T_F427BC -> 0xF63BAE
    (x42).  49 thunk slots point into it and none of it was converted.

HOW
    * code runs are transcribed by notes/llvm_roundtrip_autoforce.py, which
      assembles the candidate listing and compares it byte for byte with the ROM
      before printing;
    * the THREE data islands are emitted as `.byte`.  They are data because
      notes/prom_b_module_trace.py never reaches them by following control flow
      from the module's own entry points, and because in the 0xF63441 case a
      linear decode steps straight over 0xF63489 -- which is the target of thunk
      slot T_F42790 and therefore must be an instruction;
    * the 1008-byte 0x0E tail is emitted as `.fill`;
    * labels come from LABELS below, keyed by ADDRESS, and the script asserts
      that every label address is an instruction boundary in the transcription
      (or the first byte of a data island).  A name not in LABELS becomes
      `sub_XXXXXX`, which is the tree's rule: a stated gap beats a guess.

RUN
    python3 notes/gen_prom_b_blockstore_module.py            # the assembly
    python3 notes/gen_prom_b_blockstore_module.py --layout   # the segment table
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
A_BASE = 0xF80000

# (kind, start, length).  The three data islands are the runs
# notes/prom_b_module_trace.py reports as never reached from any entry point.
LAYOUT = [
    ("code", 0xF62C00, 0x841),
    ("data", 0xF63441, 0x048),
    ("code", 0xF63489, 0x837),
    ("data", 0xF63CC0, 0x020),
    ("code", 0xF63CE0, 0x47E),
    ("data", 0xF6415E, 0x030),
    ("code", 0xF6418E, 0xA82),
    ("fill", 0xF64C10, 0x3F0),
]

DATA_NOTE = {
    0xF63441: ("BStore_ErrorStatusTable", 12,
               "indexed by the error code (0x0D4A); the byte it yields is stored "
               "to (0x2880).  Read by BStore_ErrorToStatusByte (0xF6342C), the "
               "only site in prom_a+prom_b that names 0x00F63441.  Extent is "
               "abutment: the next byte, 0xF63489, is thunk T_F42790's target.  "
               "72 bytes lay out as 6 rows of 12 with only four distinct non-0xFF "
               "values (0x23 at row+0 and row+7, 0x0F at row+5, and row+9 taking "
               "0xFF,0xFF,0x35,0x1D,0x1C,0x1B).  What the value MEANS is not "
               "established."),
    0xF63CC0: ("BStore_Map32", 16,
               "32 bytes, the identity map 0x00..0x1F.  Read as "
               "`ld L,(0x00F63CC0+L)` at 0xF63C97 and 0xF64040, in both cases "
               "with L already fetched from the 16-byte array at 0x00603422, and "
               "in both cases the result is tested against 0xFF and the operation "
               "skipped when it matches.  No entry IS 0xFF, so in this firmware "
               "the map skips nothing; that is a fact about these 32 bytes, not "
               "a claim about the design."),
    0xF6415E: ("BStore_Table_F6415E", 12,
               "48 bytes.  NO site in prom_a or prom_b spells the address "
               "0x00F6415E, so what reads it is unknown and its extent rests only "
               "on abutment: 0xF6418E is thunk T_F42804's target and 0xF6415D is "
               "the `ret` of the routine above.  It reads as two 24-byte rows, "
               "each `07 08 09 FF FF FF FF` / `00 01 02 FF FF FF FF` twice, six "
               "0xFF, then `90 FF` and a repeated byte (0x51 / 0x50).  Structure "
               "NOT established."),
}

# Per-routine headers.  Every "Evidence:" line names bytes in the ROM, and every
# quantity in one is re-derivable from a script named in notes/README-prom_b.md.
HEADERS = {
 0xF62C00: ('BStore_Veneers -- three long-branch veneers',
  ['Evidence: three unconditional branches and nothing else -- `jr T,0xF62C66`,',
   '  `jrl T,0xF64A7A`, `jrl T,0xF64A9F`.',
   'Unknown: why the module needs veneers at all when the thunk table could',
   '  name the three targets directly.']),
 # 0xF62C08 -- BStore_StubTable -- is NOT listed here.  It is BUILT BY THIS
 # SCRIPT further down, in main(), from stub_census() of the transcription's own
 # instruction boundaries.  A hand-typed version that used to sit here said
 # "24 stubs / 22 of 4 bytes / 0xF62C31 is 6"; every one of those four figures
 # was wrong (the truth is 28 / 26 / 5, see the census) and every one of them
 # was silently overwritten at run time, so the wrong text shipped nowhere but
 # still sat here looking authoritative.  Deleted 2026-08-25 rather than
 # corrected: a hand-typed count next to a computed one is a trap, not a
 # cross-check.
 0xF62C7E: ("BStore_ValidateSavedCursor -- is entry n's saved cursor still valid?",
  ['Inputs:  A = entry number, 1-based.',
   'Outputs: (0x0D4A) = 0 on success, else an error code; on success',
   "  (0x345C) = the cursor's block number and (0x126E) = that block's address.",
   'What it does: L = A-1; C = the byte at 0x006034A0[L]; requires 5 <= C <= 0xFF;',
   '  WA = the 16-bit word at 0x0060347E[L*2]; requires WA <= (0x0CA4) (the block',
   '  count); seeks that block; requires its bit 7 set; requires the payload byte',
   '  at offset C to be tag 0x82 or 0x84.',
   'Evidence: 0xF62C96 `ld XDE,0x006034A0`, 0xF62CB6 `ld XDE,0x0060347E`,',
   '  0xF62CA1 `cp BC,5`, 0xF62CC1 `cp WA,(0x0CA4)`, 0xF62CDB `bit 7,(XHL)`,',
   '  0xF62CE8/0xF62CF0 `cp (XHL+IY),0x82` / `0x84`.  The pair (word at +0x7E,',
   '  byte at +0xA0) is a CURSOR because BStore_SaveCursor writes exactly that',
   '  pair from the live block number and offset.',
   'Unknown: 5 as the lower bound on C is the 5-byte block header, but the',
   '  UPPER bound is odd: BC was cleared with `xor BC,BC` before the byte was',
   '  loaded into C, so `cp BC,0x00FF` can never fail.  Dead as written.']),
 0xF62D8C: ('BStore_CountMarkersForward -- walk forward over B tag-0x81 markers',
  ['Inputs:  B = how many 0x81 markers to pass, IY = the byte offset in the',
   '  current block, (0x126E) = the current block.',
   'Outputs: IX += C (the markers actually passed); (0x0D4A) = 8 if tag 0x82 was',
   '  found first.',
   'Evidence: 0xF62D9B `cp A,0x82` -> `ld (0x0D4A),0x08`, 0xF62DA7 `cp A,0x81`',
   '  -> `inc 1,C`; both arms call BStore_CursorAdvance.',
   'Unknown: what a 0x81 marker delimits.']),
 0xF6342C: ('BStore_ErrorToStatusByte -- (0x2880) = ErrorStatusTable[(0x0D4A)]',
  ['Evidence: the whole routine is five instructions -- 0xF6342C',
   '  `ld XIY,0x00F63441`, `xor HL,HL`, `ld L,(0x0D4A)`, `ld A,(XIY+HL)`,',
   '  `ld (0x2880),A`.  It is the only site in prom_a+prom_b that spells',
   '  0x00F63441.',
   'Unknown: what (0x2880) is consumed by.  No interpreter-B display-list record',
   '  names it (notes/prom_b_var_screens.py --var 0x2880 prints nothing).']),
 0xF635C9: ('BStore_CursorAdvance -- ++cursor, following the chain at a block end',
  ['Inputs:  IY = byte offset in the current block, (0x126E) = block address.',
   'Outputs: IY, (0x126E), (0x345C) advanced; (0x0D4A) = 0, or 0x0A / 0x0B.',
   'What it does: `inc 1,IY`; while IY is still <= 0xFF it returns; otherwise it',
   '  reads the 16-bit NEXT-block number at header offset +3, range-checks it',
   "  against (0x0CA4), seeks it, checks bit 7 of the new block's byte 0, and",
   '  restarts the offset at 5.',
   'Evidence: 0xF635CB `cp IY,0x00FF`, 0xF635D5 `ld WA,(XHL+0x03)`,',
   '  0xF635E5 `cp WA,(0x0CA4)`, 0xF635FF `bit 7,(XHL)`, 0xF6360A `ld IY,0x0005`.',
   '  The constant 5 is the same 5 that BStore_AllocChain subtracts from 0x100',
   '  (0xF639BB `sub HL,0x0005`) to get the payload capacity of a block.',
   'Unknown: 0xF635D8 `cp WA,0xFFFF / jr ULE` is a comparison that can never',
   '  fail on a 16-bit register, so the `ld (0x0D4A),0x08` at 0xF635DE is',
   '  UNREACHABLE.  Error 8 is still produced -- by BStore_CountMarkersForward',
   '  and 0xF62DA0 -- so the code is dead, not the code path.']),
 0xF638BB: ('BStore_OpenChain -- directory lookup: entry n -> cursor at its head',
  ['Inputs:  A = entry number, 1-based.',
   'Outputs: (0x345C) = head block number, (0x126E) = its address, (0x0D4A) = 0',
   '  or 0x01 / 0x02 / 0x0A / 0x0B.',
   'THE DIRECTORY, and this routine is where its shape is read off:',
   '  base 0x00603500, stride 3 (`muls WA,0x0003` at 0xF638CA),',
   '  +0 flags -- bit 7 set means the entry is in use (`bit 7,(XDE+IY)`),',
   '  +1..+2 the 16-bit head BLOCK NUMBER, 0xFFFF meaning empty',
   '         (`inc 1,IY` then `ld WA,(XDE+IY)`, then `cp WA,0xFFFF`).',
   'Evidence: 0xF638D1 and 0xF638E8 both `ld XDE,0x00603500`.  IMMEDIATE_CENSUS',
   '  So this directory is not private to this module.',
   'Unknown: how many directory entries there are.  (0x0C90) bounds a loop over',
   '  them at 0xF62D3C, but nothing here fixes its value.']),
 0xF63924: ("BStore_SaveCursor -- store entry n's cursor, in RAM and in its bank",
  ['Inputs:  (0x0D1A) = entry number 1-based; IX = the byte offset; (0x0C57) =',
   '  the block number.',
   'What it does: writes the offset byte to 0x006034A0[n-1] and the block-number',
   '  word to 0x0060347E[(n-1)*2], and then writes the SAME two values into the',
   '  saved copy of the workspace at 0x00610000 + (0x360A)*0xC00 + 0xA0 / + 0x7E.',
   'Evidence: 0xF6392E and 0xF6393F name the two RAM arrays; 0xF6394E',
   '  `ld XIZ,0x00610000` with `sla 0x0B,XWA` + `sla 0x0A,XBC` (i.e. n*0x800 +',
   '  n*0x400 = n*0xC00) and then the same two offsets 0xA0 and 0x7E as literals.',
   '  This routine is why the (+0x7E word, +0xA0 byte) pair is called a cursor:',
   '  it is written here from a live block number and offset, and read back by',
   '  BStore_ValidateSavedCursor.']),
 0xF63988: ('BStore_AllocChain -- allocate a chain long enough for N bytes',
  ['Inputs:  (0x0CAE) = byte count wanted, (0x0CC6) = bytes already in the last',
   '  block, (0x0CC0) = the block to link the new chain onto.',
   'Outputs: (0x0CAC) = blocks allocated, (0x0D08) = bytes free in the last one,',
   "  (0x0CC2) = the last block's address, (0x0D4A) = 0 or 0x05.",
   'THE BLOCK CAPACITY, and this is where it is read off: 0xF639B8-0xF639BB',
   '  `ld HL,0x0100 / sub HL,0x0005` and then `div XWA,HL` -- 0x100 bytes per',
   '  block, 5 of them header, 251 payload.  The same `0x100 - 5` appears at',
   '  0xF62E3F-0xF62E42.',
   "THE BLOCK HEADER's two link fields are written here:",
   '  0xF63A3A `ld (XHL+0x03),IX`      -- the NEXT block number,',
   '  0xF63A46 `ld (XHL+0x03),0xFFFF`  -- end of chain,',
   '  0xF63A4B `ld (XHL+0x01),DE`      -- the PREVIOUS block number.',
   '  So the chain is DOUBLY linked and 0xFFFF is the terminator, which is the',
   '  same 0xFFFF BStore_OpenChain tests the directory head against.',
   'Evidence: also 0xF639EA `cp WA,(0x6034BA)` -> error 5, which is what makes',
   '  the workspace word at +0xBA the free-block count.',
   'Unknown: the allocator itself is not here -- 0xF63A18 calls thunk T_F42884',
   '  -> 0xF7A402, in another module.']),
 0xF63BAE: ('BStore_SeekBlock -- point the cursor at block n',
  ['Inputs:  HL = block number, 1-based.   Outputs: (0x126E) = its address.',
   'What it does: (0x126E) = (0x3604) + (HL-1) * 0x100.',
   'Evidence: the four instructions `dec 1,HL / extz XHL / sla 0x08,XHL /',
   '  add XHL,(0x3604)`.',
   'AND (0x3604) IS 0x00617800.  That is not read off here -- it is forced by',
   '  the INVERSE, which two other prom_b modules spell with a literal:',
   '    0xF5E2F0  ld XHL,(0x126E) / sub XHL,0x00617800 / srl 0x08,XHL / inc 1,HL',
   '    0xF61F1C  ld XHL,(0x0E1F) / ld (0x126E),XHL / sub XHL,0x00617800 /',
   '              sra 0x08,XHL / inc 1,HL',
   '  Both recover a 1-based block number from (0x126E); composing either with',
   '  this routine gives n back if and only if (0x3604) = 0x00617800.',
   '  notes/FINDINGS-memory-map.md already had `0x617800 + n*0x100 -- a 256-byte',
   "  record array' from 0xF61F5B; this identifies the array."]),
 0xF63BC0: ('BStore_CopyAcrossBlocks -- ldir between two blocks, by block number',
  ['Inputs:  BC = byte count; IX = offset in the destination block; IY = offset',
   '  in the source block; (0x0C59) = destination block address, (0x0C63) =',
   '  source block address.  Returns at once when BC = 0.',
   'Evidence: `extz XIX / extz XIY / add XIY,XHL / add XIX,XDE / ldir` with',
   '  XHL = (0x0C63) and XDE = (0x0C59), then both bases subtracted again so the',
   "  caller's offsets survive.  TLCS-900 `ldir` copies (XIX)+ <- (XIY)+ --",
   '  ../mame/src/devices/cpu/tlcs900/900tbl.hxx:2483 writes through p1 and reads',
   '  p2, and :5437-5438 set p1 = reg(op-1) = XIX and p2 = reg(op) = XIY for the',
   '  0x85 prefix.  So (0x0C59) is the DESTINATION.',
   '  0xF62DC9 sets them: (0x0C63) from block (0x0C61), (0x0C59) from block',
   '  (0x0C57).']),
 0xF63BE5: ("BStore_LoadGeometry -- copy the store's geometry into the 0x0Cxx page",
  ['What it does: (0x0CA2) = 0x11; (0x0CA4) = (0x3608) (the block COUNT);',
   '  (0x0CA6) = (0x3604) (the block store BASE); (0x0CA3) = 0x10.',
   'Evidence: six instructions, all immediates or direct moves.',
   '  (0x0CA4) being the block count is what makes the `cp WA,(0x0CA4)` bounds',
   '  checks in BStore_CursorAdvance and BStore_OpenChain range checks.',
   'Unknown: what 0x11 and 0x10 are.  0x10 is used as a loop bound over the',
   '  16-byte array at 0x00603422 (0xF63620 `cp L,(0x0CA3)`), so 0x10 = 16',
   '  entries there; 0x11 has no established use.']),
 0xF64B3D: ('BStore_Workspace_LoadFromBank -- 0x603400 <- bank (0x360A)',
  ['What it does: `ldir` of 0x0C00 bytes from 0x00610000 + (0x360A)*0xC00 to',
   '  0x00603400, then (0x360C) = the long at 0x0060341E.',
   'Evidence: 0xF64B4E `ld XIY,0x00610000` (source), 0xF64B54 `ld XIX,0x00603400`',
   '  (destination -- see the ldir direction citation on BStore_CopyAcrossBlocks),',
   '  `ld BC,0x0C00`; the index is `sla 0x0B` + `sla 0x0A` of (0x360A), i.e.',
   '  n*0x800 + n*0x400 = n*0xC00.',
   'WHAT THIS SAYS ABOUT THE MEMORY MAP.  0x603400-0x603FFF is exactly the 3 KiB',
   '  that notes/FINDINGS-memory-map.md records as `work DRAM, deliberately NOT',
   "  cleared and live' -- the one hole in prom_a's two boot clear loops.  This",
   '  routine and its mirror are what that hole is for.  prom_a bounds (0x360A):',
   '  0xF8143F `cp A,0` refuses to decrement below 0 and 0xF814D2 `cp A,0x09`',
   '  refuses to increment past 9, so n is 0..9 -- TEN banks.  Ten banks of 0xC00',
   "  starting at 0x610000 end at 0x617800, which is the block store's base.",
   '  Two independently derived constants abut with no slack.',
   'Unknown: that abutment is consistency, not proof that the two regions were',
   '  laid out as one.']),
 0xF64BE3: ('BStore_Workspace_SaveToBank -- bank (0x360A) <- 0x603400',
  ['What it does: the exact mirror of BStore_Workspace_LoadFromBank, and it',
   '  first writes (0x360C) out to 0x0060341E so the reload can restore it.',
   'Evidence: 0xF64BE3 `ld XWA,(0x360C)` / `ld (0x0060341E),XWA`, then',
   '  `ld XIX,0x00610000` (destination) and `ld XIY,0x00603400` (source) --',
   '  the two registers swapped relative to the load.']),
}


LABELS = {
    0xF62C00: "BStore_Veneers",
    0xF62C08: "BStore_StubTable",
    0xF62C7E: "BStore_ValidateSavedCursor",
    0xF62D8C: "BStore_CountMarkersForward",
    0xF635C9: "BStore_CursorAdvance",
    0xF6342C: "BStore_ErrorToStatusByte",
    0xF63924: "BStore_SaveCursor",
    0xF63988: "BStore_AllocChain",
    0xF638BB: "BStore_OpenChain",
    0xF63BAE: "BStore_SeekBlock",
    0xF63BC0: "BStore_CopyAcrossBlocks",
    0xF63BE5: "BStore_LoadGeometry",
    0xF64B3D: "BStore_Workspace_LoadFromBank",
    0xF64BE3: "BStore_Workspace_SaveToBank",
}

# Entry points: every thunk-table `jp` target inside the module, plus every
# intra-module `call`/`calr` target, both from notes/prom_b_module_trace.py.
ENTRIES = [
    0xF62C00, 0xF62C02, 0xF62C05, 0xF62C08, 0xF62C0C, 0xF62C10, 0xF62C14,
    0xF62C18, 0xF62C1C, 0xF62C20, 0xF62C7E, 0xF62CFE, 0xF62D8C, 0xF62DC9,
    0xF62FFA, 0xF63031, 0xF6306A, 0xF63280, 0xF632A9, 0xF632E0, 0xF63317,
    0xF63383, 0xF633F5, 0xF633FF, 0xF63408, 0xF63411, 0xF6341A, 0xF63423,
    0xF6342C, 0xF63489, 0xF63510, 0xF6353E, 0xF635C9, 0xF6360E, 0xF6364D,
    0xF63749, 0xF6382B, 0xF638BB, 0xF63924, 0xF63988, 0xF63A59, 0xF63BAE,
    0xF63BC0, 0xF63BE5, 0xF63C02, 0xF63C06, 0xF63C41, 0xF63CE0, 0xF63F88,
    0xF63F90, 0xF6411C, 0xF6418E, 0xF6452B, 0xF64594, 0xF6466E, 0xF647DD,
    0xF64838, 0xF6487D, 0xF648F2, 0xF6498D, 0xF64A34, 0xF64A7A, 0xF64B1B,
    0xF64B3D, 0xF64B7A, 0xF64BB6, 0xF64BE3,
]


MODULE_HEADER = """
; ==============================================================================
; 0xF62C00-0xF64FFF -- THE BLOCK STORE
;   a chained 256-byte record heap, its 3-byte directory, and the banked 3 KiB
;   workspace that both live in
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_call_graph.py ranks unconverted prom_b thunk
; targets by an opcode-anchored reference upper bound.  The top two in the whole
; image are BOTH in this module -- T_F4279C -> 0xF635C9 (x43) and
; T_F427BC -> 0xF63BAE (x42) -- and 49 thunk slots, the contiguous run
; T_F42770-T_F42830, point into it.  None of it was converted before.
;
; EXTENT.  0xF62C00-0xF64C0F is code and data; 0xF64C10-0xF64FFF is 1008 bytes
; of 0x0E (`ret`) padding to the 4 KiB boundary, where the next module starts.
; The module is preceded by 2,347 bytes of the same padding (0xF622D5-0xF62BFF).
;
; WHAT IT MANAGES -- three objects, all established from the bytes:
;
;  1. A HEAP OF 256-BYTE BLOCKS based at (0x3604), (0x3608) of them.
;         +0        flags; bit 7 set = allocated
;         +1..+2    PREVIOUS block number, 16-bit
;         +3..+4    NEXT block number, 16-bit; 0xFFFF terminates the chain
;         +5..+0xFF payload, 251 bytes
;     The 5 is not a guess: BStore_AllocChain computes the capacity as
;     `ld HL,0x0100 / sub HL,0x0005` (0xF639B8) and BStore_CursorAdvance
;     restarts the offset at exactly 5 when it steps into a new block.
;     (0x3604) = 0x00617800 -- forced by the INVERSE arithmetic that two other
;     prom_b modules spell with a literal (0xF5E2F0, 0xF61F1C); see the header
;     on BStore_SeekBlock.
;
;  2. A DIRECTORY of 3-byte entries at 0x00603500.
;         +0        flags; bit 7 set = entry in use
;         +1..+2    head block number, 16-bit; 0xFFFF = empty
;     Read off BStore_OpenChain, which is the only routine here that touches it.
;
;  3. A 3 KiB WORKSPACE at 0x00603400-0x00603FFF, banked into
;     0x00610000 + n*0xC00 with n = (0x360A).
;     notes/FINDINGS-memory-map.md already recorded 0x603400-0x603FFF as the one
;     3 KiB hole prom_a's two boot clear loops deliberately skip.  This module is
;     what the hole is for.  prom_a bounds n to 0..9 (0xF8143F `cp A,0` on the
;     way down, 0xF814D2 `cp A,0x09` on the way up), so there are TEN banks --
;     and 0x610000 + 10*0xC00 = 0x617800, the heap base.  The two regions abut
;     with no slack.  That is consistency between two independently derived
;     constants, not proof that they were laid out together.
;     Fields of the workspace this module names: +0x1E (a copy of (0x360C)),
;     +0x22 (16 bytes, values 0x00-0x1F with 0x20 meaning empty), +0x7E (16-bit
;     saved cursor block numbers), +0xA0 (saved cursor byte offsets), +0xB8,
;     +0xBA (the free-block count), +0xC6, +0xD4, +0xD7.
;
; THE CURSOR is the pair ((0x126E) = block address, IY = byte offset), with
; (0x345C) carrying the block number.  BStore_CursorAdvance is the only thing
; that moves it across a block boundary.
;
; THE PAYLOAD IS A TAGGED BYTE STREAM.  The tag values this module compares
; against, with the number of comparison sites for each (census emitted by the
; generator, not typed):
TAG_TABLE
; 0x82 and 0x84 are what BStore_ValidateSavedCursor requires a saved cursor to
; be pointing at.
; ⚠ What the tags MEAN is not established.  0x81 is counted (a delimiter of
; something) and 0x82 stops a forward walk with error 8; that is all the bytes
; say.
;
; ERROR CODES, in (0x0D4A).  The table below is the complete census of
; `ld (0x0D4A),imm` in this module: every code, how many sites write it, and
; where.  It is emitted by the generator from the proven transcription, so the
; counts cannot drift from the bytes.
;
ERRORCODE_TABLE
; ⚠ These are the values this module WRITES.  Nothing here shows that no other
; module writes (0x0D4A), and BStore_ErrorToStatusByte indexes a 72-entry table
; with it, which would allow codes up to 0x47.
;
; ⚠ WHAT THIS MODULE IS FOR is NOT established.  The obvious reading -- that a
; directory of chained byte streams with delimiter tags, in the one RAM region
; that survives a warm restart, is the sequencer's song memory -- is a reading.
; What supports it is only circumstantial: (0x126E), the cursor, sits in the same
; 0x12xx page as (0x12F6) and (0x12FC), which interpreter-B display-list records
; draw on the screen whose interpreter-A text reads "SEQUENCER PLAY", "S0NG",
; "CYCLE:", "MEASURE = " and "TIME SIG.= "
; (`python3 notes/prom_b_var_screens.py --var 0x12F6`).  Adjacency in a RAM page
; is not evidence about a routine, so the names below say "BStore", not "Song".
;
; REPRODUCE THIS WHOLE BLOCK:
;     python3 notes/gen_prom_b_blockstore_module.py
; Its code runs come from notes/llvm_roundtrip_autoforce.py, which proves the
; listing rebuilds the range byte for byte before printing it; its three data
; islands are the runs notes/prom_b_module_trace.py never reaches by following
; control flow from the module's own entry points; and every caller list and
; every count in a header below is computed by the generator, not typed.
; ==============================================================================
"""


def thunks():
    b = open(IMG, "rb").read()
    m = {}
    for slot in range(0x40000, 0x44018, 4):
        if b[slot] == 0x1B:
            t = b[slot + 1] | b[slot + 2] << 8 | b[slot + 3] << 16
            m.setdefault(t, []).append(B_BASE + slot)
    return m


CALLERS = {}


def callers_of(lines):
    """{target: [call-site addresses]} read off the MAME text the transcription
    carries in its own comments.  Hand-counting these is exactly the mistake
    this tree keeps making, so nothing here is typed by hand."""
    out = {}
    for l in lines:
        m = re.search(r";\s*([0-9A-F]{6})\s+(calr|call)\s+0x([0-9a-f]{6})\s*$", l)
        if m:
            out.setdefault(int(m.group(3), 16), []).append(int(m.group(1), 16))
    return out


def addr_sites(images, word):
    """Every offset in CPU 1's two ROMs holding `word` as a 32-bit little-endian
    value, returned as CPU addresses.  This is what backs the "only site that
    names 0x......" / "NO site names 0x......" sentences in DATA_NOTE: they used
    to be TYPED.  Scanning at every byte offset (not only at instruction
    boundaries) can only OVER-count, so a result of zero is a real zero."""
    w = word.to_bytes(4, "little")
    out = {}
    for nm, img, base in images:
        hits, i = [], img.find(w)
        while i >= 0:
            hits.append(base + i)
            i = img.find(w, i + 1)
        out[nm] = hits
    return out


def data_island_evidence(a_img, b):
    """The computed Evidence paragraph for each data island, keyed by address."""
    imgs = (("prom_a", a_img, A_BASE), ("prom_b", b, B_BASE))
    ev = {}
    for island in (0xF63441, 0xF63CC0, 0xF6415E):
        st = addr_sites(imgs, island)
        n = sum(len(v) for v in st.values())
        where = "; ".join("%s %s" % (nm, ", ".join("0x%06X" % x for x in st[nm]))
                          for nm in ("prom_a", "prom_b") if st[nm]) or "nowhere"
        ev[island] = ("Evidence: the bytes above, re-asserted by "
                      "assert_data_islands() in notes/gen_prom_b_blockstore_"
                      "module.py before this text can be emitted.  The literal "
                      "0x%08X appears %d time%s in CPU 1's two ROMs, counted by "
                      "addr_sites() at EVERY byte offset: %s.  Those are the "
                      "addresses of the LITERAL, which is one or more bytes "
                      "PAST the start of the instruction carrying it -- the "
                      "instruction addresses in the paragraph above are not the "
                      "same numbers and are not meant to be."
                      % (island, n, "" if n == 1 else "s", where))
    return ev


def assert_data_islands(b):
    """Every sentence in DATA_NOTE that states a PATTERN is re-checked here, so a
    wrong description stops the emit instead of reaching the .s.  The byte gate
    cannot see a comment; this is the substitute."""
    t = b[0x63441:0x63489]
    assert len(t) == 72
    for r in range(6):
        assert t[r * 12 + 0] == 0x23 and t[r * 12 + 7] == 0x23
        assert t[r * 12 + 5] == 0x0F
        for i in range(12):
            if i not in (0, 5, 7, 9):
                assert t[r * 12 + i] == 0xFF
    assert [t[r * 12 + 9] for r in range(6)] == [0xFF, 0xFF, 0x35, 0x1D, 0x1C, 0x1B]
    m = b[0x63CC0:0x63CE0]
    assert list(m) == list(range(32)) and 0xFF not in m
    u = b[0x6415E:0x6418E]
    for r, lead in ((0, bytes((7, 8, 9))), (1, bytes((0, 1, 2)))):
        row = u[r * 24:(r + 1) * 24]
        assert row[0:3] == lead and row[7:10] == lead
        assert row[3:7] == b"\xff" * 4 and row[10:20] == b"\xff" * 10
        assert row[20:22] == b"\x90\xff" and row[22] == row[23]


def stub_census(lines):
    """(number of stubs, {length: count}) for the stub table, read off the
    transcription's own instruction boundaries -- never counted by eye."""
    at = []
    for l in lines:
        m = re.search(r";\s*([0-9A-F]{6})\s+calr\s", l)
        if m:
            a = int(m.group(1), 16)
            if 0xF62C08 <= a < 0xF62C7E:
                at.append(a)
    at.sort()
    sizes = {}
    for i, a in enumerate(at):
        n = (at[i + 1] if i + 1 < len(at) else 0xF62C7E) - a
        sizes[n] = sizes.get(n, 0) + 1
    return len(at), sizes, at


ERROR_GLOSS = {
    0x00: "cleared on entry to a routine -- no error",
    0x01: "directory entry number is 0 (0xF638C1), or its bit 7 is clear (0xF638DE)",
    0x02: "the directory head block number is 0xFFFF -- the chain is empty",
    0x05: "more blocks needed than (0x6034BA) reports free (0xF639F1), or the "
          "allocator at thunk T_F42884 returned failure (0xF63A2F).  The two "
          "further sites are not read",
    0x06: "the tag byte at the cursor is 0x84 (`cp (XHL+IY),0x84` at 0xF63502)",
    0x07: "the tag byte at the cursor is 0x82 (`cp (XHL+IY),0x82` at 0xF6357F)",
    0x08: "tag 0x82 reached while walking forward (0xF62D9B).  The second site, "
          "0xF635DE, is UNREACHABLE -- see the header on BStore_CursorAdvance",
    0x0A: "block number greater than (0x0CA4), the block count",
    0x0B: "the block's bit 7 is clear, or the tag at the cursor is not one of "
          "the values the caller expected",
}


def error_census(all_lines):
    """{code: [sites]} for every `ld (0x0D4A),imm` in the module, off the
    transcription's own MAME text."""
    out = {}
    for l in all_lines:
        m = re.search(r";\s*([0-9A-F]{6})\s+ld \(0x0d4a\),0x([0-9a-f]{2})\s*$", l)
        if m:
            out.setdefault(int(m.group(2), 16), []).append(int(m.group(1), 16))
    for k in out:
        out[k] = sorted(set(out[k]))
    return out


def transcribe(addr, length):
    p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(addr), hex(length),
                        "--quiet"], capture_output=True, text=True)
    if p.returncode != 0:
        sys.stderr.write(p.stderr)
        raise SystemExit("autoforce failed on 0x%06X+0x%X" % (addr, length))
    return [l for l in p.stdout.splitlines() if l.strip()]


def main():
    b = open(IMG, "rb").read()
    th = thunks()
    if "--layout" in sys.argv:
        for k, s, n in LAYOUT:
            print("%-5s 0x%06X-0x%06X  %5d" % (k, s, s + n - 1, n))
        return 0

    # PASS 1: transcribe every code segment, and only then compute the caller
    # map.  Doing it inside the emit loop makes a routine's caller list depend
    # on which segment it happens to sit in, which is how the first draft of
    # this script under-counted BStore_CursorAdvance as 11 sites instead of 15.
    trans = {}
    for kind, start, length in LAYOUT:
        if kind == "code":
            trans[start] = transcribe(start, length)
    for start, lines in trans.items():
        for tgt, sites in callers_of(lines).items():
            CALLERS.setdefault(tgt, []).extend(sites)
    for tgt in CALLERS:
        CALLERS[tgt] = sorted(set(CALLERS[tgt]))

    assert_data_islands(b)
    a_img = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    global DATA_EVIDENCE
    DATA_EVIDENCE = data_island_evidence(a_img, b)
    nstub, sizes, stubs = stub_census(trans[0xF62C00])

    def sz(a):
        """Size of the stub starting at `a`, from the measured boundaries."""
        i = stubs.index(a)
        return (stubs[i + 1] if i + 1 < len(stubs) else 0xF62C7E) - a
    withthunk = sum(1 for a in stubs if th.get(a))
    withcall = sum(1 for a in stubs if CALLERS.get(a))
    ncen = sum(img.count(bytes((0x00, 0x35, 0x60, 0x00))) for img in (a_img, b))
    HEADERS[0xF62C08] = (
        "BStore_StubTable -- %d `calr <routine> / ret` entry stubs" % nstub,
        ["Layout, counted by this script from the transcription's own instruction",
         "  boundaries: %s."
         % ", ".join("%d stub%s of %d bytes" % (c, "" if c == 1 else "s", n)
                     for n, c in sorted(sizes.items())),
         "  The table runs 0x%06X-0x%06X, %d bytes, and abuts"
         % (stubs[0], 0xF62C7E - 1, 0xF62C7E - stubs[0]),
         "  BStore_ValidateSavedCursor at 0x%06X." % 0xF62C7E,
         "  It is NOT a fixed stride, and anything that assumes one walks off the",
         "  table -- notes/prom_b_module_trace.py did exactly that.  The two odd",
         "  ones, with the size this script MEASURED for each:",
         "    0x%06X is %d bytes -- it also does `ld (0x0E02),0x00`" % (0xF62C28, sz(0xF62C28)),
         "    0x%06X is %d bytes -- it also does `push WA`" % (0xF62C31, sz(0xF62C31)),
         "Entry points: %d of the %d stubs have their own thunk slot and %d are"
         % (withthunk, nstub, withcall),
         "  called from inside the module; the remaining %d are entered from"
         % (nstub - len(set(a for a in stubs if th.get(a) or CALLERS.get(a)))),
         "  outside by address.",
         "Evidence: every `calr` target in the table is also an entry point that",
         "  something else reaches."])

    alll = [l for seg in trans.values() for l in seg]
    ec = error_census(alll)
    tags = {}
    for l in alll:
        m = re.search(r";\s*[0-9A-F]{6}\s+cp (?:\(XHL\+IY\)|A|W|C),0x(8[0-9a-f])(\s|$)", l)
        if m:
            tags[int(m.group(1), 16)] = tags.get(int(m.group(1), 16), 0) + 1
    tagtbl = ";     " + "   ".join("0x%02X x%d" % (k, tags[k]) for k in sorted(tags))
    tbl = []
    for code in sorted(ec):
        sites = ec[code]
        tbl.append(";     0x%02X  %2d site%s: %s"
                   % (code, len(sites), " " if len(sites) == 1 else "s",
                      " ".join("0x%06X" % x for x in sites[:6])
                      + (" ..." if len(sites) > 6 else "")))
        g = ERROR_GLOSS.get(code)
        if g:
            for ln in textwrap.wrap(g, 66):
                tbl.append(";           " + ln)
    out = [MODULE_HEADER.strip("\n").replace("ERRORCODE_TABLE", "\n".join(tbl))
           .replace("TAG_TABLE", tagtbl)]
    for kind, start, length in LAYOUT:
        if kind == "fill":
            seg = b[start - B_BASE:start - B_BASE + length]
            assert set(seg) == {0x0E}, "fill run is not all 0x0E"
            out.append("\t.fill\t%d, 1, 0x0E\t; %06X-%06X  ret padding"
                       % (length, start, start + length - 1))
            continue
        if kind == "data":
            name, per, note = DATA_NOTE[start]
            out.append("")
            out.append("; --- %s: %d bytes at 0x%06X ---" % (name, length, start))
            for ln in textwrap.wrap(note, 72):
                out.append(";     " + ln)
            for ln in textwrap.wrap(DATA_EVIDENCE[start], 72):
                out.append(";     " + ln)
            out.append("%s:" % name)
            for i in range(0, length, per):
                chunk = b[start - B_BASE + i:start - B_BASE + i + per]
                out.append("\t.byte\t%s\t; +0x%02X"
                           % (", ".join("0x%02X" % c for c in chunk), i))
            continue
        lines = trans[start]
        at = {}
        for i, l in enumerate(lines):
            m = re.search(r";\s*([0-9A-F]{6})\s", l)
            if m:
                at.setdefault(int(m.group(1), 16), i)
        for a in ENTRIES:
            if not (start <= a < start + length):
                continue
            if a not in at:
                raise SystemExit("entry 0x%06X is not an instruction boundary" % a)
            nm = LABELS.get(a, "sub_%06X" % a)
            slots = "".join("  <- T_%06X" % s for s in th.get(a, []))
            pre = ""
            if a in HEADERS:
                title, body = HEADERS[a]
                body = [x.replace("IMMEDIATE_CENSUS",
                                  "The 32-bit immediate\n;   0x00603500 occurs %d "
                                  "times in prom_a+prom_b, counted here." % ncen)
                        for x in body]
                cf = ["Called from:"]
                if th.get(a):
                    cf.append("  thunk slots " + ", ".join("T_%06X" % s
                                                           for s in th[a]))
                cs = CALLERS.get(a, [])
                if cs:
                    cf.append("  %d call site%s inside the module:"
                              % (len(cs), "" if len(cs) == 1 else "s"))
                    for i in range(0, len(cs), 8):
                        cf.append("    " + " ".join("0x%06X" % c
                                                    for c in cs[i:i + 8]))
                if not th.get(a) and not cs:
                    cf.append("  no thunk slot and no caller inside the module")
                cf.append("  (both lists are emitted by this script, not typed)")
                pre = ("\n; " + "-" * 74 + "\n; " + title + "\n;\n"
                       + "\n".join("; " + x for x in cf) + "\n"
                       + "\n".join("; " + x for x in body)
                       + "\n; " + "-" * 74 + "\n")
            lines[at[a]] = "%s%s:%s\n%s" % (pre, nm,
                                            ("\t\t; " + slots.strip()) if slots else "",
                                            lines[at[a]])
        out.extend(lines)
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
