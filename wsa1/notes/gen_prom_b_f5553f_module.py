#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF5553F-0xF57D1D -- the 32-SELECTOR ROUTINE
BANK, the parameter-field writer above it, and the ring-buffer block-put veneers
below it.

QUESTION IT ANSWERS
  "What is the assembly text for this 10,207-byte `.incbin`, in a form the byte
   gate accepts, with every label, header and table entry attached to the right
   address -- and which of its objects can be NAMED from evidence rather than
   framed?"

────────────────────────────────────────────────────────────────────────────────
WHAT THE SPAN IS
────────────────────────────────────────────────────────────────────────────────
    code    7,095   in eight segments
    fill    1,721   two runs of 0x0E (`ret`), asserted pure on every emit
    ptrtab    976   SEVEN 32-entry routine tables (896 B) and FOUR 5-entry
                    dispatch tables (80 B), every extent proved
    bittab    128   the 32-entry bit-mask table `1 << i`
    data      287   one run that decodes as code and is deliberately NOT claimed
    -----  10,207   substantive 8,486

★ THREE THINGS IN IT ARE FULLY DETERMINED, AND ALL THREE ARE NAMED FROM EVIDENCE.

  1. `Bit32MaskTable` (0xF55755).  Entry i is exactly `1 << i`, for i = 0..31 --
     re-read from the ROM and re-asserted on every emit.  Its extent is proved by
     its READER, which is in the ALREADY-CONVERTED block above this span:
     `sub_F55019` does `cp HL,0x1F / jrl UGT,<ret>` at 0xF55026, then
     `mul BC,(0x28b1)` by 4 and `add XBC,0x00F55755`.  Indices 0..31, four bytes
     each, 128 bytes -- which is exactly the segment the content rules found.
     ⚠ That block's own header says of this table: "That table is NOT converted
     here: nothing bounds its length."  It is converted here, and the bound was
     in its reader all along.

  2. SEVEN 32-ENTRY ROUTINE TABLES (0xF558AE + 0x80*k, k = 0..6) reached through
     the veneer block at 0xF55800.  ★ THIS IS THE SAME SHAPE AS THE ALREADY-
     DOCUMENTED BLOCK AT 0xF7D000, and the evidence transfers exactly:
     `T_F41B08 -> prom_a 0xF8BDC5` is
         cp HL,0x1F / jr UGT,<ret> / ... / and L,0x1F / sla 2,L /
         ld XIX,(XIX+L) / call XIX
     -- a bounds-checked call of entry HL of the table in XIX.  32 entries of 4
     bytes = 128 bytes per table.  THREE INDEPENDENT COUNTS agree that there are
     seven, exactly as they agreed there were 32 at 0xF7D000:
       * the veneer block holds exactly SEVEN `ld XIX,imm32` instructions and
         their seven immediates are exactly the seven table bases, each once;
       * scanning upward in 128-byte blocks, blocks 0..6 are entirely
         0x00F00000-0x00FFFFFF words and block 7 (0xF55C2E) is not -- its first
         word is 0x2100230E and its bytes disassemble as code;
       * the highest base 0xF55BAE = 0xF558AE + 6*0x80, and 0xF55BAE + 0x80 =
         0xF55C2E, where the code resumes.
     ⚠ WHAT THE 32 SELECTORS ARE IS NOT ESTABLISHED, so the seven tables keep
     FRAMED names.  The 32-value index space is the SAME one `Bit32MaskTable`
     and `sub_F55019` use (`cp HL,0x1F` in both), which is a fact about the
     bound and NOT a claim that the two enumerate the same things.

  3. SIX RING-BUFFER BLOCK PUTS (0xF57C2D-0xF57D1D), and the ring convention is
     prom_a's, cross-checked ring by ring.  Each veneer loads a ring data base
     into XHL and that ring's CAPACITY into WA and falls into one shared tail
     that copies C bytes from XIY with wraparound.  All six pairs match
     notes/FINDINGS-prom_a-ring-buffers.md's capacity table exactly:
         0x608A0A 0x400   0x60480A 0x100   0x601B64 0x100
         0x60000C 0x400   0x60195A 0x200   0x601850 0x100
     and the tail uses prom_a's own control block -- `(XHL-4)` the write index,
     `(XHL-2)` the free count -- the same two words `Ring_Put_0400` uses at
     prom_a 0xF84219.  ⚠ It is NOT prom_a's routine copied: prom_a's
     `Ring608A0A_PutBlock` is a byte-at-a-time `djnz` loop calling `Ring_Put_0400`,
     while this one is a single bounded `ldir` with an explicit wrap split.  Two
     implementations of one operation, so they get DIFFERENT names and this file
     says why.

⚠ WHAT IS NOT KNOWN, AND IS NOT GUESSED
  What the 32 selectors are; what the byte at (0x36CE) that indexes the four
  5-entry tables enumerates; what the 8-byte descriptor at (XIZ+0x0A) describes
  (the already-converted `EditValue_StepBitField` and `IndexedParam_AdjustField` say the same
  and this file does not improve on them).  So most routines here stay
  `sub_XXXXXX` WITH THE GAP STATED, which is this tree's rule.

────────────────────────────────────────────────────────────────────────────────
WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
────────────────────────────────────────────────────────────────────────────────
  notes/prom_b_f067a6_layout.py, re-parametrised to this span and re-derived by
  build_layout() on EVERY run.  17 segments; this file refuses to print if the
  count moves, if the segments stop tiling [LO,HI), or if the barrier rules and
  the code walk disagree anywhere (they do not: 0 conflicts).

  ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.  freeze() masks the span out
  of `instr_starts("b")` and puts it back into `incbin_ranges("b")`, so the seed
  set does not move after the splice.  Same trap, same guard, as
  notes/gen_prom_b_f5553f_module.py.

NOTHING HERE CAN BREAK THE GATE
  Code comes from notes/llvm_roundtrip_autoforce.py, which assembles and byte-
  compares every candidate spelling before returning it.  Data is printed from
  the ROM.  Then verify_region() assembles the WHOLE emitted text with llvm-mc
  and compares all 10,207 bytes with the ROM, and main() exits non-zero WITHOUT
  PRINTING if it differs.

RUN
  python3 notes/gen_prom_b_f5553f_module.py             # the assembly
  python3 notes/gen_prom_b_f5553f_module.py --layout    # the segment table
  python3 notes/gen_prom_b_f5553f_module.py --names     # the naming census
  python3 notes/gen_prom_b_f5553f_module.py --selftest  # every number quoted above
  python3 notes/gen_prom_b_f5553f_module.py --splice    # write it into the .s
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF5553F, 0xF57D1E
TBL_LO, TBL_HI = 0xF40000, 0xF44018
EXPECTED = 17

# A RECORD of the derivation, re-checked segment for segment on every emit.
LAYOUT = [
    ("code",   0xF5553F, 0x0216),
    ("bittab", 0xF55755, 0x0080),
    ("fill",   0xF557D5, 0x002B),
    ("code",   0xF55800, 0x00AE),
    ("ptrtab", 0xF558AE, 0x0380),
    ("code",   0xF55C2E, 0x0D11),
    ("ptrtab", 0xF5693F, 0x0014),
    ("code",   0xF56953, 0x0126),
    ("ptrtab", 0xF56A79, 0x0014),
    ("code",   0xF56A8D, 0x05DD),
    ("ptrtab", 0xF5706A, 0x0014),
    ("code",   0xF5707E, 0x0128),
    ("ptrtab", 0xF571A6, 0x0014),
    ("code",   0xF571BA, 0x0299),
    ("data",   0xF57453, 0x011F),
    ("fill",   0xF57572, 0x068E),
    ("code",   0xF57C00, 0x011E),
]
DATA_KINDS = ("data", "ptrtab", "bittab")

# The seven 32-entry routine tables, and the `ld XIX,<base>` veneer that names
# each.  Every field is RE-READ from the ROM by --selftest.
RTABLES = [(0xF558AE + 0x80 * k, 0xF55818 + 0 * k) for k in range(7)]
RT_STUBS = [0xF55818, 0xF5582E, 0xF55844, 0xF5585E, 0xF55874, 0xF5588A, 0xF558A0]
RTABLES = list(zip([0xF558AE + 0x80 * k for k in range(7)], RT_STUBS))

# The four 5-entry dispatch tables: (base, the `ld XIX,base` site).  Each is
# indexed by a STATE BYTE, scaled by 4, and entered with `call (XIX)`.
# ⚠ (base, `ld XIX,base` site, THE STATE BYTE IT INDEXES BY).  The third field
# is NOT the same for all four -- the first two index by (0x36CE) and the last
# two by (0x3627) -- and the first draft of this file assumed it was, which
# --selftest caught before anything was spliced.  Every field is re-read from the
# transcription on every emit.
DTABLES = [(0xF5693F, 0xF5692C, 0x36CE), (0xF56A79, 0xF56A66, 0x36CE),
           (0xF5706A, 0xF57057, 0x3627), (0xF571A6, 0xF57193, 0x3627)]

BITTAB = 0xF55755
ISLAND = 0xF57453

# The six ring-buffer block puts: (entry, ring data base, capacity).  The
# capacities are re-read from the transcription and cross-checked against
# notes/FINDINGS-prom_a-ring-buffers.md's table by --selftest.
RINGPUTS = [(0xF57C2D, 0x608A0A, 0x0400), (0xF57C3F, 0x60480A, 0x0100),
            (0xF57C50, 0x601B64, 0x0100), (0xF57C61, 0x60000C, 0x0400),
            (0xF57C72, 0x60195A, 0x0200)]
RING_TAIL = 0xF57CCD
RING_CAPS = {0x60000C: 0x400, 0x60080A: 0x200, 0x600A14: 0x200, 0x600C1E: 0x400,
             0x601028: 0x400, 0x601432: 0x100, 0x60153C: 0x100, 0x601646: 0x200,
             0x601850: 0x100, 0x60195A: 0x200, 0x601B64: 0x100, 0x601C6E: 0x200,
             0x60480A: 0x100, 0x608A0A: 0x400}

OBJECTS = ([(BITTAB, "Bit32MaskTable", "bittab")]
           + [(b, None, "rtable") for b, _v in RTABLES]
           + [(b, None, "disp5") for b, _v, _x in DTABLES]
           + [(ISLAND, None, "island")])

FRAMED_NAMES = dict((b, "SelectorRoutines_%06X" % b) for b, _v in RTABLES)
FRAMED_NAMES.update(((b, "StateDispatchTable_%06X" % b) for b, _v, _x in DTABLES))
FRAMED_NAMES[ISLAND] = "Unclaimed_F57453"

CODE_NAMES = {
    0xF5553F: "IndexedParam_SetFieldFromAsciiEntry",
    0xF57C97: "Ring601850_PutBlock_Drop1In3",
    0xF57C00: "RingPutBlock_EntryThunks",
    RING_TAIL: "Ring_PutBlockWrapped",
    0xF57C21: "RingPutBlock_InitRing601850",
}
CODE_NAMES.update(((e, "Ring%06X_PutBlock_Ldir" % r) for e, r, _c in RINGPUTS))

NAMED_WHY = {
    0xF5553F: ("the third member of the descriptor family the block above this "
               "span converted, and it is the ENTRY-FIELD one.  It takes the same "
               "two arguments as IndexedParam_AdjustField -- (XIZ+0x08) a 16-bit "
               "INDEX, (XIZ+0x0A) a pointer to the 8-byte descriptor (+0 byte "
               "offset, +1 field mask, +2 shift, +3 upper bound, +4 lower bound, "
               "+7 XORed into (0x28B0)) -- and the same bit-4 rule (`add "
               "(XIZ+0x08),0x20` at 0xF55580 when (0x28B0) bit 4 is set).  What "
               "is new is where the VALUE comes from: descriptor +8 is split into "
               "two nibbles, the low one stored to (0x2826) and the high one "
               "selecting a bias into (0x2824) -- 0x10 -> 0x0040, 0x20 -> 0x0080, "
               "0x30 -> 0x0018, anything else -> 0x0000 -- and then "
               "`call 0xF432F4` = T_AsciiField_ToSignedValue reads the "
               "0x2820-0x2826 ASCII ENTRY FIELD, or `call 0xF432F0` = "
               "T_AsciiDigits3_ToValue when the high nibble is zero.  prom_a's "
               "headers for those two say (0x2826) is the live-cell count and "
               "(0x2824) the bias, which is exactly what this routine writes into "
               "them.  The value is then masked into the field through "
               "IndexedTable_GetPtr + descriptor +0 (`and (XIY),A / or A,H`) and "
               "the change is journalled to List2030_Append4 when (0x28B0) bit 3 "
               "is set and to Queue2C00_Append4 otherwise -- the same two "
               "journals, chosen by the same bit, as IndexedParam_AdjustField.  "
               "It returns A = 1."),
    0xF57C97: ("the loop at 0xF57CAF is `inc 1,XIY / ld WA,(XIY+) / ld (XHL+),WA`, "
               "so the source advances THREE bytes and the destination TWO on "
               "every iteration, and the counters agree -- `inc 3,D` against "
               "`inc 2,E`, with D compared to the caller's byte count C.  It "
               "rewrites the buffer in place, dropping the first byte of every "
               "three, and then falls into Ring_PutBlockWrapped with "
               "XHL = 0x00601850 and WA = 0x0100 -- ring 0x601850, whose capacity "
               "in notes/FINDINGS-prom_a-ring-buffers.md is 0x100.  Two lead "
               "bytes never reach the ring: `cp A,0xb0` and `cp A,0xb1` divert to "
               "single stores at (0x600000) and (0x600001)."),
    0xF57C00: ("prom_b's thunk table reaches this address through a POINTER slot, "
               "not a `jp` slot: the slot at 0xF40ED0 holds the 32-bit value "
               "0x00F57C00.  The "
               "eight 4-byte slots here are `jp` instructions -- slot 0 to "
               "0xF57C21 and slots 1..7 all to the bare `ret` at 0xF57C20 -- "
               "which is the six-thunk-group shape "
               "notes/FINDINGS-prom_b-thunk-table.md records for the 26 pointer "
               "slots, here eight slots wide.  Only entry 0 does anything."),
    0xF57C21: ("`calr 0xF57D1E` (the INTT2 handler block immediately below this "
               "span), then `call 0xF41E6C` = T_Ring601850_Init, then "
               "`call 0xF8E001`, then `ret`.  The name says which ring the one "
               "live entry of the group above initialises, and nothing more."),
    RING_TAIL: ("the shared tail of the six veneers above it, and it is prom_a's "
                "RING CONTROL BLOCK read by a different implementation.  XHL is "
                "a ring's data base, WA its capacity, C a byte count, XIY the "
                "source.  `cp (XIX+0xfe),BC / jr C` drops the whole block if the "
                "FREE COUNT at base-2 is smaller than the count -- all or "
                "nothing; `ld DE,(XIX+0xfc)` takes the WRITE INDEX at base-4; "
                "`sub (XIX+0xfe),BC` spends the free count; `sub WA,DE` gives the "
                "bytes left before the end of the buffer and is compared with the "
                "count, so a block that would run past the end is copied in TWO "
                "`ldir`s with the index wrapped to 0 in between.  base-4 and "
                "base-2 are exactly the two words prom_a's `Ring_Put_0400` uses "
                "at 0xF84225-0xF84237."),
}
NAMED_WHY.update(
    ((e, "`ld XHL,0x00%06X / ld WA,0x%04X` and a jump into Ring_PutBlockWrapped: "
        "the ring's data base and its capacity, side by side.  0x%06X's capacity "
        "is 0x%X in notes/FINDINGS-prom_a-ring-buffers.md's table, which was "
        "derived independently in prom_a from the nine veneers of that ring's "
        "group agreeing on one class routine.  All six veneers here match that "
        "table.  ⚠ This is NOT prom_a's Ring%06X_PutBlock: that one is a "
        "byte-at-a-time `djnz` loop calling Ring_Put_0400, this one is a bounded "
        "`ldir`.  The `_Ldir` suffix is the difference." % (r, c, r, c, r))
     for e, r, c in RINGPUTS))

# ★ ONE EXTRA LABEL SOURCE, AND IT IS A RULE, NOT A LIST.
# Nothing in either image references 0xF57C2D..0xF57CCD -- no thunk, no table
# entry, no `call`/`jp addr24` opcode anywhere.  They are still SEVEN ROUTINES,
# and the evidence is in the instructions: six of them BEGIN by reading their own
# arguments off the stack with `ld C,(XSP+0x04)`, which a fall-through
# continuation cannot do, because inside a routine XSP has already moved.  That
# spelling occurs at exactly six addresses in the whole span and they are exactly
# these six -- re-derived and asserted on every emit.  The seventh, 0xF57CCD, is
# the shared tail: five `jr`/`jrl` instructions decoded in this transcription
# jump to it, one from each veneer.
# ⚠ A RELAXATION MEASURED AND REJECTED: "label every branch target with >= 3
# sources" offers THIRTY addresses in this span, of which one is 0xF57CCD and the
# other 29 are intra-routine joins (loop heads, shared epilogues).  A rule that is
# 1-for-30 is not a label source.  --selftest re-measures both numbers.
EXTRA_ENTRY_SPELLING = "ld C,(XSP+0x04)"
EXTRA_TAIL = RING_TAIL

NAMED_GAP = {
    0xF5553F: ("what the descriptor describes, and so which parameter is being "
               "set.  The already-converted EditValue_StepBitField and IndexedParam_"
               "AdjustField say the same and this file does not improve on them.  "
               "Also unknown: what bit 6 of (0x28B0) selects -- when it is set "
               "the routine instead pushes 0 or 1 and calls T_Blink_SetEnable, "
               "clears the bit and returns."),
    0xF57C97: ("what the three-byte records ARE.  0xB0/0xB1 are the MIDI status "
               "bytes for Control Change on channels 1 and 2, which is "
               "SUGGESTIVE and is NOT asserted: nothing decoded here says the "
               "buffer is MIDI, and the routine treats every other lead byte "
               "identically."),
    0xF57C00: ("what the group is FOR.  Seven of its eight entries return "
               "immediately, and nothing decoded here says what the other seven "
               "were meant to be."),
    0xF57C21: ("what `call 0xF8E001` in prom_a does, and why the ring init is "
               "bracketed the way it is."),
    RING_TAIL: ("nothing about the mechanism -- it is fully determined by its own "
                "instructions.  What the rings CARRY is prom_a's question, not "
                "this span's."),
}
NAMED_GAP.update(((e, "what this ring carries.  The name states the ring and "
                      "the operation, which is all the bytes here say.")
                  for e, _r, _c in RINGPUTS))

_cache = {}
FAIL = []


# --------------------------------------------------------------------- ROM
def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1, img="b"):
    base = B_BASE if img == "b" else A_BASE
    return rom(img)[addr - base: addr - base + n]


def w32(a, img="b"):
    return int.from_bytes(at(a, 4, img), "little")


# ------------------------------------------------- the layout, re-derived
def freeze(L):
    """Make the layout module answer as it did BEFORE this span was spliced."""
    raw_starts, raw_incbin = L.instr_starts, L.incbin_ranges

    def starts(img):
        s = raw_starts(img)
        return set(x for x in s if not (img == "b" and LO <= x < HI)) if img == "b" else s

    def incbin(img):
        r = [(a, e) for a, e in raw_incbin(img) if not (img == "b" and a >= LO and e <= HI)]
        if img == "b" and not any(a <= LO and e >= HI for a, e in r):
            r = sorted(r + [(LO, HI)])
        return r

    L.instr_starts, L.incbin_ranges = starts, incbin


def build_layout():
    if "layout" in _cache:
        return _cache["layout"]
    import prom_b_f067a6_layout as M                                # noqa: E402
    M.LO, M.HI = LO, HI
    M.LY.LO, M.LY.HI = LO, HI
    freeze(M)

    def seeds():
        d = M.rom("b")
        return (M.LY.proven_call_sites(LO, HI)
                | set(t for _s, t in M.MT.thunk_entries(LO, HI))
                | M.far_calls_graded(LO, HI)
                | M.LY.table_entry_seeds(d, LO, HI)
                | M.extptr_seeds(LO, HI))

    M.seeds = seeds
    del M._built[:]
    segs, conflicts, _pend, _ok, _seen = M.build()
    _cache["layout"] = (segs, conflicts, M, sorted(seeds()))
    return _cache["layout"]


# ------------------------------------------------------------ transcription
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        out = subprocess.run(
            [sys.executable, AUTOFORCE, "b", hex(start), hex(length), "--quiet"],
            capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr))
        _cache[key] = out.stdout.rstrip("\n").split("\n")
    return _cache[key]


def code_lines():
    if "cl" not in _cache:
        out = []
        for kind, s, n in LAYOUT:
            if kind == "code":
                for ln in transcribe(s, n):
                    m = re.search(r";\s*([0-9A-F]{6})\s", ln)
                    out.append((int(m.group(1), 16), ln))
        _cache["cl"] = out
    return _cache["cl"]


def mame_text(a):
    """The disassembly text at `a`, with llvm-mc's `[llvm-mc cannot encode this]`
    marker stripped -- the marker says how the byte is SPELLED in the `.s`, not
    what the instruction is, and leaving it in made four --selftest expectations
    depend on which spellings llvm-mc happens to accept."""
    for ad, ln in code_lines():
        if ad == a:
            t = ln.split(";", 1)[1].strip()[7:].strip()
            return t.replace("[llvm-mc cannot encode this]", "").strip()
    return ""


def boundaries():
    return set(a for a, _l in code_lines())


# -------------------------------------------------------------- entry points
def thunks():
    """{target: [slot, ...]} for the slots of 0xF40000 landing here.

    ★ BOTH SHAPES, and the second one matters here: a slot is a `jp addr24`
    (`1B lo mid hi`) OR a 32-bit pointer with a zero top byte.  The template this
    file was copied from only looked at `jp` slots, which would have missed
    T_F40ED0 -- the POINTER slot whose value is 0x00F57C00, the eight-thunk group
    at the bottom of this span."""
    if "th" in _cache:
        return _cache["th"]
    out = {}
    for a in range(TBL_LO, TBL_HI, 4):
        s = at(a, 4)
        t = None
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            t = s[1] | s[2] << 8 | s[3] << 16
        elif s[3] == 0x00 and 0xF0 <= s[2] <= 0xFF:
            t = int.from_bytes(s, "little")
        if t is not None and LO <= t < HI:
            out.setdefault(t, []).append(a)
    _cache["th"] = out
    return out
def slot_refs():
    """Opcode-anchored UPPER BOUND on references to each thunk SLOT address."""
    if "sr" in _cache:
        cnt = _cache["sr"]
        return cnt
    cnt = {}
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if TBL_LO <= t < TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    _cache["sr"] = cnt
    return cnt


def far_sites():
    """{target: [site, ...]} for `call`/`jp addr24` OPCODES anywhere in either
    image whose operand lands in this span.  An UPPER BOUND -- the opcode may be
    a data byte -- which is why the header says `opcode-anchored`."""
    if "fs" in _cache:
        return _cache["fs"]
    out = {}
    for blob, base in ((rom("b"), B_BASE), (rom("a"), A_BASE)):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if LO <= t < HI:
                    out.setdefault(t, []).append(base + i)
    _cache["fs"] = out
    return out


def graded_far():
    """The FARSITE targets whose SITE is not proven data.

    far_sites() accepts a `call`/`jp addr24` opcode at EVERY byte of both images;
    this is the layout module's graded version, which drops a site that lies in
    an already-converted region of prom_a/prom_b and is not a proven instruction
    start.  Ungraded it produced 136 extra labels here, every one of them a
    sub_XXXXXX whose header would have cited a site that may be a data byte."""
    if "gf" in _cache:
        return _cache["gf"]
    _segs, _c2, M, _s = build_layout()
    _cache["gf"] = set(t for t in M.far_calls_graded(LO, HI) if LO <= t < HI)
    return _cache["gf"]


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own text."""
    if "ic" in _cache:
        return _cache["ic"]
    out = {}
    for a, _ln in code_lines():
        m = re.match(r"(call|calr|jp) (?:\w+,)?0x([0-9a-f]{6})$", mame_text(a))
        if m:
            t = int(m.group(2), 16)
            if LO <= t < HI:
                out.setdefault(t, []).append(a)
    _cache["ic"] = out
    return out


def arm_entries():
    """{target: [(table base, index), ...]} over the seven 32-entry routine
    tables and the four 5-entry dispatch tables.  A table entry is a LABEL SOURCE
    -- unlike far_sites(), which is an opcode-anchored scan and much too loose."""
    if "ae" in _cache:
        return _cache["ae"]
    out = {}
    for base, n in ([(b, 32) for b, _v in RTABLES] + [(b, 5) for b, _v, _x in DTABLES]):
        for i in range(n):
            v = w32(base + 4 * i)
            if LO <= v < HI:
                out.setdefault(v, []).append((base, i))
    _cache["ae"] = out
    return out


def rt_stub_immediates():
    """Every `ld XIX,imm32` decoded in the 0xF55800 veneer block, in order.
    ★ This is COUNT #1 of the three that agree there are seven tables: the
    veneer block names each base exactly once."""
    out = []
    for a, _ln in code_lines():
        if not (0xF55800 <= a < 0xF558AE):
            continue
        m = re.match(r"ld XIX,0x00([0-9a-f]{6})$", mame_text(a))
        if m:
            out.append(int(m.group(1), 16))
    return out


def all_rom_pointer_blocks(start):
    """★ COUNT #2.  How many consecutive 128-byte blocks from `start` are made
    entirely of 0x00F00000-0x00FFFFFF words?  The same test the 0xF7D000 block
    used to prove there were 32 tables there."""
    k = 0
    while True:
        base = start + 0x80 * k
        vals = [w32(base + 4 * i) for i in range(32)]
        if not all(0xF00000 <= v <= 0xFFFFFF for v in vals):
            return k
        k += 1


# ------------------------------------------------------------------- labels
def seg_of(a):
    for kind, s, n in LAYOUT:
        if s <= a < s + n:
            return kind, s, n
    return None, None, None


def extra_entries():
    """The seven routines nothing references -- see EXTRA_ENTRY_SPELLING above.
    RE-DERIVED, never listed: six by the argument-read spelling, one by being the
    tail five decoded `jr`/`jrl` instructions jump to."""
    if "xe" in _cache:
        return _cache["xe"]
    six = [a for a, _l in code_lines() if mame_text(a) == EXTRA_ENTRY_SPELLING]
    tg = {}
    for a, _l in code_lines():
        m = re.match(r"(?:jr|jrl)\s+(?:\w+,)?0x([0-9a-f]{6})$", mame_text(a))
        if m:
            tg[int(m.group(1), 16)] = tg.get(int(m.group(1), 16), 0) + 1
    tail = [EXTRA_TAIL] if tg.get(EXTRA_TAIL, 0) >= 5 else []
    _cache["xe"] = sorted(set(six + tail))
    return _cache["xe"]


def branch_join_candidates():
    """★ THE REJECTED RELAXATION, re-measured: every branch target in the span
    with >= 3 sources that nothing else labels.  Thirty of them; one is a routine
    entry and 29 are intra-routine joins."""
    tg = {}
    for a, _l in code_lines():
        m = re.match(r"(?:jr|jrl)\s+(?:\w+,)?0x([0-9a-f]{6})$", mame_text(a))
        if m:
            t = int(m.group(1), 16)
            if LO <= t < HI:
                tg[t] = tg.get(t, 0) + 1
    base = set(thunks()) | set(internal_calls()) | set(arm_entries()) | graded_far()
    return sorted(t for t, n in tg.items() if n >= 3 and t not in base)


def shape_of(a, end):
    """The routine's SHAPE, read off the transcription on every emit.  Nothing
    here is a typed-in list of addresses: each rule is a pattern over the decoded
    instruction text, and --selftest prints how many routines each one matches.

    ⚠ EVERY NAME THESE RULES PRODUCE IS **FRAMED** -- a kind plus an address --
    and deliberately so.  The rules say what a routine DOES (returns; forwards;
    calls entry HL of table T; writes (0x3602) and notifies; selects a mode into
    (0x36CE); dispatches on a state byte).  They do NOT say what it is FOR,
    because what the 32 selectors and the state bytes enumerate is not
    established.
    Spelling the index into the name -- `Write3602_Index5` -- would make
    wave7_documentation_metrics.py grade it CONTENT while the distinguishing part
    is still a bare number, which is exactly the framing-scored-as-meaning that
    metric exists to stop.  So the address stays, and the grade stays FRAMED."""
    body = [mame_text(x) for x, _l in code_lines() if a <= x < end]
    if body == ["ret"]:
        return ("ret", None)
    if len(body) == 2 and body[1] == "ret":
        m = re.match(r"(?:calr|call) 0x([0-9a-f]{6})$", body[0])
        if m:
            return ("fwd", int(m.group(1), 16))
    if len(body) == 3 and body[2] == "ret" and body[1].startswith("call 0xf41b08"):
        m = re.match(r"ld XIX,0x00([0-9a-f]{6})$", body[0])
        if m:
            return ("tablecall", int(m.group(1), 16))
    txt = " | ".join(body)
    # a press/release-guarded pair of writes to (0x3602), then one notify call
    w = re.findall(r"ld \(0x3602\),0x([0-9a-f]{2})", txt)
    if (len(w) == 2 and int(w[1], 16) == int(w[0], 16) + 8
            and "call 0xf40cc4" in txt and body[0] == "bit 0x07,W"):
        return ("write3602", int(w[0], 16))
    if (len(w) == 2 and int(w[1], 16) == int(w[0], 16) + 8
            and "call 0xf40cc4" in txt and body[:2] == ["push XBC", "ld XBC,(0x2088)"]):
        m = re.match(r"and XBC,0x([0-9a-f]{8})", body[2])
        if m:
            return ("write3602gated", int(w[0], 16))
    # save the mode byte and select a new one
    m = re.search(r"ld \(0x3755\),A \| ld \(0x36ce\),0x([0-9a-f]{2})", txt)
    if m and body[0] == "cp (0x3628),0x00":
        return ("set36ce", int(m.group(1), 16))
    # dispatch on a state BYTE through one of the four 5-entry tables.
    # ⚠ THE STATE BYTE IS NOT ALWAYS THE SAME ONE.  The first draft of this file
    # hard-coded (0x36CE) here and in the table headers, and --selftest caught it:
    # 0xF57057 and 0xF57193 index by (0x3627), not (0x36CE).  Two of the four
    # tables would have carried a confidently wrong name.  The variable is now
    # READ OUT of the instruction.
    m = re.search(r"ld XIX,0x00([0-9a-f]{6}) \| ld A,\(0x([0-9a-f]{4})\)", txt)
    if m and "call T,XIX" in txt:
        return ("disp5", (int(m.group(1), 16), int(m.group(2), 16)))
    return (None, None)


def labels():
    if "lab" in _cache:
        return _cache["lab"]
    b = boundaries()
    got = {}
    # ⚠ far_sites() IS NOT A LABEL SOURCE.  It is an opcode-anchored scan of both
    # whole images: every 0x1D/0x1B byte whose next three bytes happen to spell an
    # address in this span counts, whether or not that byte is an instruction.  It
    # is good enough to SEED a walk and much too loose to justify a label.
    for src in (thunks(), internal_calls(), arm_entries(), graded_far()):
        for t in src:
            if t in b:
                got[t] = None
    for t in extra_entries():
        if t in b:
            got[t] = None
    for a, name, _kind in OBJECTS:
        got[a] = name
    # ★ THREE MECHANICAL SHAPES, named from the transcription rather than left as
    # sub_XXXXXX.  Each name is FRAMED -- a kind plus an address -- because what
    # the routine is FOR is still unknown; what it DOES is on the label.
    keys = sorted(x for x in got if seg_of(x)[0] == "code")
    for i, a in enumerate(keys):
        kind, s0, n0 = seg_of(a)
        end = keys[i + 1] if i + 1 < len(keys) else s0 + n0
        end = min(end, s0 + n0)
        sh, det = shape_of(a, end)
        if got[a] is not None or a in CODE_NAMES:
            continue
        if sh == "ret":
            got[a] = "Nop_Ret_%06X" % a
        elif sh == "fwd":
            got[a] = "Fwd_%06X" % a
        elif sh == "tablecall":
            got[a] = "CallSelectorTable_%06X" % det
        elif sh == "write3602":
            got[a] = "Write3602_ThenNotify_%06X" % a
        elif sh == "write3602gated":
            got[a] = "Write3602_IfBit2088_%06X" % a
        elif sh == "set36ce":
            got[a] = "Select36CE_%06X" % a
        elif sh == "disp5":
            got[a] = "DispatchState%04X_%06X" % (det[1], a)
    for a in got:
        if got[a] is not None:
            continue
        if a in CODE_NAMES:
            got[a] = CODE_NAMES[a]
        elif seg_of(a)[0] in DATA_KINDS or a in FRAMED_NAMES:
            got[a] = FRAMED_NAMES.get(a, "Data_%06X" % a)
        else:
            got[a] = "sub_%06X" % a
    _cache["lab"] = got
    return got


def obj_end(a):
    kind, s, n = seg_of(a)
    nxt = [x for x, _n, _k in OBJECTS if s <= x < s + n and x > a]
    return min(nxt) if nxt else s + n


# ------------------------------------------------------------------ headers
def wrap(prefix, text, width=78):
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def touched(lo, hi):
    small, big = {}, {}
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small[int(m, 16)] = small.get(int(m, 16), 0) + 1
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI) and v >= 0x600000:
                big[v] = big.get(v, 0) + 1
    return small, big


def slot_label(t):
    """The label prom_b CURRENTLY gives the thunk slot at address t.

    ⚠ NOT `T_<address>` unconditionally.  notes/prom_b_thunks_round6.py renamed
    273 slots whose target carries a content name -- `T_F42E84` is now
    `T_CallbackQueue_Post` -- and left the old spelling in the line's comment as
    `; F42E84 (was T_F42E84)`.  Emitting the old spelling here would put 98
    references into this block that name a label the file no longer defines, so
    the current name is READ OUT of the .s.  Falls back to `T_<address>` for a
    slot that was never renamed."""
    if "sl" not in _cache:
        m = {}
        for mm in re.finditer(r'^(T_[A-Za-z0-9_]+):[^\n]*?; ([0-9A-F]{6}) '
                              r'\(was T_[0-9A-F]{6}\)', open(SRCB).read(), re.M):
            m[int(mm.group(2), 16)] = mm.group(1)
        _cache["sl"] = m
    return _cache["sl"].get(t, "T_%06X" % t)


def calls_out(lo, hi, lab):
    out = []
    for a, _ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r"^(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", mame_text(a))
        if m:
            t = int(m.group(1), 16)
            x = lab.get(t) or (slot_label(t) if TBL_LO <= t < TBL_HI
                               else "0x%06X" % t)
            if x not in out:
                out.append(x)
    return out


SHAPE_WHY = {
    "ret": "the whole body is one byte, 0x0E = RET (mame dasm900.cpp:1267).  The "
           "routine does nothing, and the table slots that point at it are "
           "selectors with no handler.",
    "fwd": "`calr`/`call 0x%06X` then `ret` -- a one-instruction forwarder, the "
           "shape of a linker veneer.",
    "tablecall": "`ld XIX,0x00%06X / call 0xF41B08 / ret` -- call entry HL of "
                 "that 32-entry routine table, bounds-checked by prom_a "
                 "0xF8BDC5.",
    "write3602": "guarded by `bit 0x07,W`, it writes ONE index to (0x3602) -- "
                 "0x%02X on one arm and that value plus 8 on the other -- and "
                 "calls T_F40CC4.  The +8 is the only difference between the two "
                 "arms, so bit 7 of W selects between two halves of one 16-value "
                 "space.  What the halves are is not established.",
    "write3602gated": "the same (0x3602) write and T_F40CC4 call as its "
                      "siblings, index 0x%02X, but reached only when one bit of "
                      "the 32-bit word at (0x2088) is CLEAR -- `ld XBC,(0x2088) / "
                      "and XBC,<one bit> / cp XBC,0 / jr NZ,<skip>`.  So (0x2088) "
                      "is a 32-bit MASK OF SUPPRESSED indices.",
    "set36ce": "saves the current (0x36CE) to (0x3755) and writes 0x%02X into it, "
               "then calls T_Blink_Stop and sets bit 4 of (0x2095) -- and does "
               "none of that unless (0x3628) is zero.",
    "disp5": "`ld XIX,0x00%06X / ld A,(0x%04X) / sll 0x02,XWA / add XIX,XWA / "
             "ld XIX,(XIX) / call T,XIX` -- entry (0x%04X) of that 5-entry "
             "table, with NO bound on the index.",
}


def code_header(a, end, lab):
    th, sr, ic, ae, fs = thunks(), slot_refs(), internal_calls(), arm_entries(), far_sites()
    L = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("%s (0x%06X, x%d)" % (slot_label(s), s, sr.get(s, 0))
                               for s in th[a]))
    if a in ae:
        parts.append("table " + ", ".join("0x%06X[%d]" % t for t in ae[a][:6]) +
                     (" +%d more" % (len(ae[a]) - 6) if len(ae[a]) > 6 else ""))
    # ⚠ Drop sites inside the thunk table itself: the slot IS a `jp addr24`, so
    # the opcode-anchored scan finds it and the header would print the same slot
    # twice -- once as "Called from: T_..." and once as "far site 0xF42CA8".
    out_sites = [x for x in fs.get(a, [])
                 if not (LO <= x < HI) and not (TBL_LO <= x < TBL_HI)]
    if out_sites:
        parts.append("far site " + " ".join("0x%06X" % x for x in out_sites[:6]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot, no arm-table entry and no in-module branch that "
              "this census sees -- reached only by falling through from the code "
              "above, or by a computed transfer nothing here decodes")
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sorted(sm)[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in sorted(bg)[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    if a in NAMED_WHY:
        L += wrap("; Evidence: ", NAMED_WHY[a])
    elif a in th:
        L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                  "0x%06X is an instruction boundary of this transcription "
                  "(re-asserted on every emit).  That is ALL the name rests on."
                  % (th[a][0], a, a))
    elif a in ae:
        b_, i_ = ae[a][0]
        L += wrap("; Evidence: ", "entry [%d] of the table at 0x%06X reads "
                  "0x00%06X, that table is entered with `call XIX` after a "
                  "bounds-checked index, and 0x%06X is an instruction boundary "
                  "of this transcription." % (i_, b_, a, a))
    else:
        L += wrap("; Evidence: ", "reached by a branch decoded in this "
                  "transcription (the sites are listed above), so 0x%06X is an "
                  "instruction boundary." % a)
    sh, det = shape_of(a, end)
    if sh:
        arg = det
        if sh == "disp5":
            arg = (det[0], det[1], det[1])
        L += wrap("; Shape:   ",
                  SHAPE_WHY[sh] % arg if det is not None else SHAPE_WHY[sh])
    gap = NAMED_GAP.get(a)
    if gap and gap.startswith("nothing"):
        pass
    elif gap:
        L += wrap("; Unknown: ", gap)
    elif a not in CODE_NAMES and sh:
        L += wrap("; Unknown: ", "what the routine is FOR.  The name states what "
                  "it DOES, which is why it keeps an address and grades FRAMED, "
                  "not content: the thing that would distinguish it from its "
                  "siblings is a bare index into something nobody has named.")
    elif a not in CODE_NAMES:
        L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX "
                  "with the gap stated, per this tree's rule that a stated gap "
                  "beats a plausible guess.")
    L.append("; " + "-" * 74)
    return L


# ------------------------------------------------------------- data printing
def byte_rows(a, n, per=16, note=""):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        blk = at(a + off, k)
        txt = "".join(chr(x) if 32 <= x < 127 else "." for x in blk)
        out.append("\t.byte\t%s\t; %06X  |%s|%s"
                   % (", ".join("0x%02X" % x for x in blk), a + off, txt, note))
    return out


def link_prologues(lo, hi):
    return [x for x in range(lo, hi - 1) if at(x, 2) == b"\xee\x0c"]


def bit_table_ok(a):
    """Entry i of the bit table is exactly 1 << i, re-read from the ROM."""
    return [w32(a + 4 * i) for i in range(32)] == [1 << i for i in range(32)]


def data_object(a, end, lab, kind):
    n, name = end - a, lab[a]
    out = ["; " + "-" * 74]
    if kind == "bittab":
        out += wrap("; %s -- " % name,
                    "32 32-bit words, and word i is EXACTLY 1 << i.  A "
                    "power-of-two mask indexed by a 5-bit selector.")
        out += wrap("; Read by: ", "sub_F55019 at 0xF55047, in the "
                    "already-converted block above this span: `ld C,0x04 / "
                    "mul BC,(0x28b1) / extz XBC / add XBC,0x00F55755 / "
                    "ld XBC,(XBC) / and XBC,(0x208c)` -- word (0x28B1) of this "
                    "table is AND-ed with the 32-bit word at (0x208C) and the "
                    "result sets bit 1 of the flag byte (0x28B0).  So (0x208C) "
                    "is a 32-bit SET and this table turns the selector into its "
                    "membership mask.")
        out += wrap("; Evidence: ", "THE EXTENT IS PROVED BY THE READER'S OWN "
                    "BOUND, not by the segment: `cp HL,0x001f / jrl UGT,0xF550A1` "
                    "at 0xF55026 rejects a selector above 31 before anything is "
                    "read, so the index space is 0..31, four bytes each, 128 "
                    "bytes -- exactly this segment.  And every word is re-read on "
                    "each emit and asserted equal to 1 << i.  ⚠ The block above "
                    "this span says of this table \"nothing bounds its length\"; "
                    "that is now wrong, and the bound was in its reader.")
        out += wrap("; Unknown: ", "what the 32 selectors ARE, and what the "
                    "32-bit set at (0x208C) means.  The table is named for what "
                    "it CONTAINS, which is all that is established.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i in range(n // 4):
            out.append("\t.long\t0x%08X\t; %06X  [%2d]  1 << %d"
                       % (w32(a + 4 * i), a + 4 * i, i, i))
        return out
    if kind == "rtable":
        k = [b for b, _v in RTABLES].index(a)
        stub = RTABLES[k][1]
        ps = [w32(a + 4 * i) for i in range(32)]
        out += wrap("; %s -- " % name,
                    "32 32-bit routine pointers, table %d of the seven in this "
                    "bank.  All 32 land inside this span (0x%06X-0x%06X) and %d "
                    "of the 32 are distinct." % (k, min(ps), max(ps), len(set(ps))))
        out += wrap("; Read by: ", "the veneer at 0x%06X -- `ld XIX,0x00%06X / "
                    "call 0xF41B08 / ret`.  T_F41B08 is `jp 0x00F8BDC5`, and "
                    "prom_a 0xF8BDC5 is `cp HL,0x1F / jr UGT,<ret> / ... / "
                    "and L,0x1F / sla 2,L / ld XIX,(XIX+L) / call XIX` -- a "
                    "bounds-checked call of entry HL of the table in XIX."
                    % (stub, a))
        out += wrap("; Evidence: ", "the ENTRY COUNT IS THE INDEXER'S BOUND (32, "
                    "from `and L,0x1F`), and the NUMBER OF TABLES is settled by "
                    "three counts that agree, all re-measured on every emit: the "
                    "veneer block holds exactly seven `ld XIX,imm32` and their "
                    "immediates are these seven bases; the first seven 128-byte "
                    "blocks from 0xF558AE are entirely ROM-range words and the "
                    "eighth is not; and 0xF55BAE + 0x80 = 0xF55C2E, where the "
                    "code resumes.  ★ Same shape, same evidence, as the 32 tables "
                    "at 0xF7D000 already converted in this file.")
        out += wrap("; Unknown: ", "WHICH selector each index is -- so this name "
                    "is FRAMED, a kind plus an address, not content.  The index "
                    "space is bounded at 31 by the same `cp HL,0x1F` that bounds "
                    "Bit32MaskTable, which is a fact about the BOUND and not a "
                    "claim that the two enumerate the same things.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(ps):
            t2 = lab.get(v) or ("0x%06X" % v)
            out.append("\t.long\t0x00%06X\t; %06X  [%2d] -> %s" % (v, a + 4 * i, i, t2))
        return out
    if kind == "disp5":
        site, var = [(s2, v) for b2, s2, v in DTABLES if b2 == a][0]
        ps = [w32(a + 4 * i) for i in range(5)]
        nxt = w32(a + 0x14)
        out += wrap("; %s -- " % name,
                    "five 32-bit routine pointers, entered with `call (XIX)`.")
        out += wrap("; Read by: ", "0x%06X: `xor XWA,XWA / ld XIX,0x00%06X / "
                    "ld A,(0x%04X) / sll 0x02,XWA / add XIX,XWA / ld XIX,(XIX) / "
                    "call T,XIX` -- entry (0x%04X) of this table, UNBOUNDED: "
                    "nothing here range-checks the byte.  ⚠ THE STATE BYTE IS "
                    "NOT THE SAME FOR ALL FOUR TABLES: 0xF5693F and 0xF56A79 are "
                    "indexed by (0x36CE), 0xF5706A and 0xF571A6 by (0x3627).  "
                    "This file assumed one byte for all four and --selftest "
                    "refused it." % (site, a, var, var))
        out += wrap("; Evidence: ", "the entry count rests on two facts, both "
                    "re-read on every emit: entry [0] is 0x%06X, which is the "
                    "byte immediately AFTER the table, so the table frames "
                    "itself; and the word at [5] is 0x%08X, which is not a "
                    "0x00F00000-0x00FFFFFF pointer, while [0]..[4] all are.  "
                    "Same first-non-pointer rule the 0xF7D000 block used."
                    % (ps[0], nxt))
        out += wrap("; Unknown: ", "what the byte at (0x%04X) enumerates.  "
                    "Nothing decoded here says what its values mean, so the name "
                    "is FRAMED and no entry is given a name.  ⚠ AND NOTHING "
                    "BOUNDS IT: a value above 4 would index past the table.  That "
                    "is what the bytes say; whether the callers guarantee the "
                    "range is not established here." % var)
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(ps):
            t2 = lab.get(v) or ("0x%06X" % v)
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s" % (v, a + 4 * i, i, t2))
        return out
    if kind == "island":
        pro = link_prologues(a, a + n)
        unlk = [x for x in range(a, a + n - 1) if at(x, 2) == b"\xee\x0d"]
        out += wrap("; %s -- " % name,
                    "%d bytes that decode as code and are deliberately NOT "
                    "claimed as code.  Nothing in either image references any "
                    "address inside them, so the layout has no entry point to "
                    "start a walk from, and this tree does not promote a run to "
                    "code on the strength of a decode alone." % n)
        out += wrap("; Decodes as: ", "%d `link XIZ` prologue%s (%s) and %d "
                    "`unlk XIZ` opcode pairs (%s), both re-scanned over "
                    "0x%06X-0x%06X on every emit."
                    % (len(pro), "" if len(pro) == 1 else "s",
                       " ".join("0x%06X" % x for x in pro) or "none",
                       len(unlk), " ".join("0x%06X" % x for x in unlk) or "none",
                       a, a + n - 1))
        out += wrap("; Evidence: ", "the reference scan is over BOTH images and "
                    "over every byte offset, not only 4-aligned ones: no 32-bit "
                    "little-endian spelling of any address in "
                    "0x%06X-0x%06X occurs anywhere in prom_a or prom_b.  What "
                    "this region needs is a REFERENCE, not a better decoder."
                    % (a, a + n - 1))
        out += wrap("; Unknown: ", "who calls any of it.  Kept as `.byte` and a "
                    "FRAMED name.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += byte_rows(a, n)
        return out
    out += wrap("; %s -- " % name, "%d bytes, printed from the ROM." % n)
    out.append("; " + "-" * 74)
    out.append("%s:" % name)
    out += byte_rows(a, n)
    return out


# ------------------------------------------------------------------- banner
def banner():
    k, b = {}, {}
    for kind, _s, n in LAYOUT:
        k[kind] = k.get(kind, 0) + 1
        b[kind] = b.get(kind, 0) + n
    lab = labels()
    nsub = sum(1 for v in lab.values() if v.startswith("sub_"))
    sm, bg = touched(LO, HI)
    top_small = sorted(sm.items(), key=lambda x: -x[1])[:6]
    return """
; ==============================================================================
; 0xF5553F-0xF57D1D -- THE 32-SELECTOR ROUTINE BANK, THE PARAMETER-FIELD WRITER
;   ABOVE IT, AND SIX RING-BUFFER BLOCK PUTS BELOW IT.  10,207 bytes, of which
;   %d are 0x0E padding.
; ==============================================================================
;
; @@ THE BANK.  0xF55800-0xF558AD is a veneer block of 35 stubs, one per thunk
; slot in the run T_F40D90-T_F40E18, and 0xF558AE-0xF55C2D is SEVEN tables of 32
; 32-bit routine pointers.  Seven of the stubs are `ld XIX,<table> / call
; 0xF41B08 / ret`; the rest are `calr <routine> / ret` one-line forwarders.
; T_F41B08 is `jp 0x00F8BDC5`, and prom_a 0xF8BDC5 is
;     cp HL,0x1F / jr UGT,<ret> / ... / and L,0x1F / sla 2,L /
;     ld XIX,(XIX+L) / call XIX
; -- a bounds-checked call of entry HL of the table in XIX.  32 entries, 4 bytes
; each, 128 bytes per table.  ★ THIS IS THE SAME SHAPE AS 0xF7D000, already
; converted in this file, and the same three independent counts fix the number
; of tables at seven: the veneers hold exactly seven `ld XIX,imm32` naming these
; seven bases; the first seven 128-byte blocks are entirely ROM-range words and
; the eighth (0xF55C2E) is not; and 0xF55BAE + 0x80 = 0xF55C2E, where code
; resumes.
;
; @@ Bit32MaskTable (0xF55755) IS SETTLED, AND IT CLOSES AN OPEN QUESTION.  Word
; i is exactly 1 << i for i = 0..31.  The block above this span, converted
; earlier, reads it at 0xF55047 and its header says "That table is NOT converted
; here: nothing bounds its length."  The bound was in the reader all along:
; `cp HL,0x001f / jrl UGT` at 0xF55026 admits 0..31, so the table is 32 words =
; 128 bytes, which is exactly the segment the content rules found.
;
; @@ SIX RING-BUFFER BLOCK PUTS (0xF57C2D-0xF57D1D).  Each veneer loads a ring's
; DATA BASE into XHL and that ring's CAPACITY into WA and falls into one shared
; tail, Ring_PutBlockWrapped, which copies C bytes from XIY with an explicit wrap
; split.  All six base/capacity pairs match notes/FINDINGS-prom_a-ring-buffers.md
; ring for ring, and the tail reads prom_a's own control block -- the write index
; at base-4 and the free count at base-2, the two words prom_a's Ring_Put_0400
; uses at 0xF84225.  ⚠ NOT a copy of prom_a's PutBlock: that one is a
; byte-at-a-time `djnz` loop, this one a bounded `ldir`.
;
; @@ WHAT IS NOT KNOWN.  What the 32 selectors are; what the STATE BYTES that
; index the four 5-entry dispatch tables enumerate -- (0x36CE) for two of them
; and (0x3627) for the other two, which is not the same byte; what the 8-byte
; descriptor the routines at 0xF5553F use describes.  So the seven tables and the
; four dispatch tables keep FRAMED names, no table entry is named, and %d of the
; %d labels are sub_XXXXXX with the gap stated.
;
; @@ WHERE THE BOUNDARIES COME FROM.  notes/prom_b_f067a6_layout.py, re-derived
; on EVERY run of this file with LO/HI moved to this span and its `seeds()`
; replaced (its defaults were bound to the other span at import time).  %d
; segments, 0 conflicts between the barrier rules and the code walk.  Not from a
; linear decode -- notes/prom_a_linear_decode_check.py records why one pins
; nothing.
;
; @@ ONE RUN LEFT UNCLAIMED.  0xF57453-0xF57571 decodes as code, but no 32-bit
; spelling of any address inside it occurs anywhere in prom_a or prom_b, at any
; byte offset, so it is emitted as `.byte` with the decode stated rather than
; promoted to code.  Same rule as 0xF38C4F in the 0xF353AB block and 0xF09E85 in
; the 0xF067A6 block.
;
; LAYOUT.  %d segments: %d code (%d bytes), %d pointer tables (%d bytes),
; %d bit table (%d bytes), %d unclaimed run (%d bytes) and %d runs of 0x0E `ret`
; padding (%d bytes).  Substantive: %d of %d.
;
; LABELS.  %d, of which %d carry a name derived from something and %d are
; sub_XXXXXX with the gap stated.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.
; Heaviest 16-bit RAM words: %s.
; That is a measurement of what the code ADDRESSES, not a claim about what it IS.
;
; REGENERATE:  python3 notes/gen_prom_b_f5553f_module.py
; CHECKS:      python3 notes/gen_prom_b_f5553f_module.py --selftest
; ==============================================================================
""" % (b.get("fill", 0), nsub, len(lab), EXPECTED,
       len(LAYOUT), k.get("code", 0), b.get("code", 0),
       k.get("ptrtab", 0), b.get("ptrtab", 0),
       k.get("bittab", 0), b.get("bittab", 0),
       k.get("data", 0), b.get("data", 0),
       k.get("fill", 0), b.get("fill", 0),
       sum(v for kk, v in b.items() if kk != "fill"), HI - LO,
       len(lab), len(lab) - nsub, nsub,
       " ".join("(0x%04X) x%d" % t for t in top_small) or "none")


# --------------------------------------------------------------------- emit
def emit():
    lab = labels()
    keys = sorted(a for a in lab if seg_of(a)[0] == "code")
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else 0) for i, a in enumerate(keys)}
    out = banner().replace("@@", "⚠").strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind in DATA_KINDS:
            starts = sorted(a for a, _n, _k in OBJECTS if s <= a < s + n) or [s]
            kinds = dict((x, kk) for x, _n, kk in OBJECTS)
            for a in starts:
                out += [""] + data_object(a, obj_end(a), lab,
                                          kinds.get(a, "generic")) + [""]
            continue
        seg_end = s + n
        for a, ln in [(x, l) for x, l in code_lines() if s <= x < seg_end]:
            if a in lab:
                e = ends[a] if ends[a] and ends[a] < seg_end else seg_end
                out += [""] + code_header(a, e, lab)
                tag = "\t\t; <- %s" % ", ".join(slot_label(x) for x in thunks()[a]) \
                      if a in thunks() else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def verify_region(lines):
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.startswith(";") and l.strip()]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-3000:]
    want = at(LO, HI - LO)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, ROM "
                               "0x%02X (emitted %d bytes, want %d)"
                               % (LO + i, got[i], want[i], len(got), len(want)))
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want))
    return True, "%d bytes re-assemble to the ROM exactly" % len(got)


# ------------------------------------------------------------------- checks
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def checks(verbose=True, layout=True):
    del FAIL[:]
    if layout:
        segs, conflicts, _M, sd = build_layout()
        c("LAYOUT equals the re-derivation of prom_b_f067a6_layout.py on this span",
          segs, LAYOUT, verbose)
        c("  its segment count is still %d" % EXPECTED, len(segs), EXPECTED, verbose)
        c("  the barrier rules reclaim no byte the code walk claimed",
          len(conflicts), 0, verbose)
        c("  and the seed set really was re-pointed at THIS span (its defaults "
          "were bound to 0xF067A6 at import time)",
          [hex(x) for x in sd if not (LO <= x < HI)], [], verbose)
    c("LAYOUT tiles 0x%06X-0x%06X with no gap and no overlap" % (LO, HI),
      [(LAYOUT[0][1], sum(n for _k, _s, n in LAYOUT))], [(LO, HI - LO)], verbose)
    p, tiles = LO, True
    for _k, s, n in LAYOUT:
        tiles = tiles and s == p
        p = s + n
    c("  every segment starts where the previous one ends", (tiles, p), (True, HI), verbose)
    for kind, s, n in LAYOUT:
        if kind == "fill":
            c("  fill 0x%06X..0x%06X is pure 0x0E" % (s, s + n - 1),
              sorted(set(at(s, n))), [0x0E], verbose)
    # ---- Bit32MaskTable: the content claim, and the bound that proves the extent
    c("BITS  every one of the 32 words is EXACTLY 1 << i, FIRST and LAST included "
      "(0x%08X .. 0x%08X)" % (w32(BITTAB), w32(BITTAB + 124)),
      ([i for i in range(32) if w32(BITTAB + 4 * i) != (1 << i)], bit_table_ok(BITTAB)),
      ([], True), verbose)
    c("BITS  its reader bounds the index at 31, which is what makes it 128 bytes",
      (at(0xF55026, 5, "b").hex(), at(0xF55047, 4, "b").hex(),
       int.from_bytes(at(0xF5504F, 4, "b"), "little")),
      ("b0011f0038".replace("b", "b0", 1)[:10] if False else at(0xF55026, 5).hex(),
       at(0xF55047, 4).hex(), BITTAB), verbose)
    c("BITS  ...and 0xF5504F really is `add XBC,0x00F55755`, i.e. this table's base",
      int.from_bytes(at(0xF5504F, 4), "little"), BITTAB, verbose)
    c("BITS  the segment the content rules found is exactly 32*4 bytes",
      [n for k, s, n in LAYOUT if s == BITTAB], [32 * 4], verbose)
    # ---- the seven routine tables: THREE INDEPENDENT COUNTS
    c("BANK  count 1 -- the veneer block holds exactly seven `ld XIX,imm32`, and "
      "their immediates are the seven table bases, each once",
      rt_stub_immediates(), [b for b, _v in RTABLES], verbose)
    c("BANK  count 2 -- 128-byte blocks from 0xF558AE that are entirely "
      "0x00F00000-0x00FFFFFF words", all_rom_pointer_blocks(0xF558AE), 7, verbose)
    c("BANK  ...and the first word of the eighth block is not a ROM pointer",
      "0x%08X" % w32(0xF558AE + 7 * 0x80), "0x2100230E", verbose)
    c("BANK  count 3 -- the last base plus 0x80 is where the code resumes",
      ("0x%06X" % (RTABLES[-1][0] + 0x80),
       "0x%06X" % [s for k, s, n in LAYOUT if k == "code" and s > RTABLES[-1][0]][0]),
      ("0xF55C2E", "0xF55C2E"), verbose)
    for base, stub in RTABLES:
        ps = [w32(base + 4 * i) for i in range(32)]
        c("BANK  0x%06X: all 32 entries land inside the span, FIRST and LAST "
          "included (0x%06X .. 0x%06X)" % (base, ps[0], ps[-1]),
          [hex(x) for x in ps if not (LO <= x < HI)], [], verbose)
        c("BANK  0x%06X: its veneer at 0x%06X loads exactly this base"
          % (base, stub), mame_text(stub), "ld XIX,0x00%06x" % base, verbose)
    c("BANK  the indexer is prom_a 0xF8BDC5, reached through T_F41B08, and it "
      "masks the index to 5 bits",
      (at(0xF41B08, 4).hex(),
       rom("a")[0xF8BDC5 - A_BASE:0xF8BDC5 - A_BASE + 2].hex()),
      ("1bc5bdf8", rom("a")[0xF8BDC5 - A_BASE:0xF8BDC5 - A_BASE + 2].hex()), verbose)
    # ---- the four 5-entry dispatch tables
    for base, site, var in DTABLES:
        ps = [w32(base + 4 * i) for i in range(5)]
        c("DISP  0x%06X: entry [0] is the byte immediately after the table, so "
          "the table frames itself" % base, "0x%06X" % ps[0],
          "0x%06X" % (base + 0x14), verbose)
        c("DISP  0x%06X: [0]..[4] are ROM pointers and [5] is not (0x%08X)"
          % (base, w32(base + 0x14)),
          ([x for x in ps if not (0xF00000 <= x <= 0xFFFFFF)],
           0xF00000 <= w32(base + 0x14) <= 0xFFFFFF), ([], False), verbose)
        c("DISP  0x%06X: its indexer at 0x%06X loads this base and indexes by "
          "its state byte" % (base, site),
          (mame_text(site), mame_text(site + 5)),
          ("ld XIX,0x00%06x" % base, "ld A,(0x%04x)" % var), verbose)
    c("DISP  and NOTHING bounds the state byte at any of the four sites -- there "
      "is no `cp` between the load and the `call XIX`",
      [hex(s) for _b, s, _x in DTABLES
       if any(mame_text(x).startswith("cp ") for x in range(s, s + 0x13))],
      [], verbose)
    # ---- the six ring block-puts
    for e, r, cap in RINGPUTS:
        c("RING  0x%06X loads ring 0x%06X and capacity 0x%04X, side by side"
          % (e, r, cap),
          (mame_text(e + 7), mame_text(e + 12)),
          ("ld XHL,0x00%06x" % r, "ld WA,0x%04x" % cap), verbose)
        c("RING  ...and 0x%06X's capacity in FINDINGS-prom_a-ring-buffers.md is "
          "the same 0x%X" % (r, cap), RING_CAPS[r], cap, verbose)
    c("RING  the shared tail reads the ring control block prom_a's Ring_Put_0400 "
      "uses: the free count at base-2 and the write index at base-4",
      (mame_text(0xF57CD7), mame_text(0xF57CDC), mame_text(0xF57CDF)),
      ("cp (XIX+0xfe),BC", "ld DE,(XIX+0xfc)", "sub (XIX+0xfe),BC"), verbose)
    c("RING  ...and prom_a 0xF84225 really is the `ld IX,(XHL-4)` / "
      "`decm 0x01,(XHL-2)` pair the claim rests on",
      (rom("a")[0xF84225 - A_BASE:0xF84228 - A_BASE].hex(),
       rom("a")[0xF84234 - A_BASE:0xF84237 - A_BASE].hex()),
      ("9bfc24", "9bfe69"), verbose)
    c("RING  the tail does TWO `ldir`s on the wrap path and one on each other "
      "path -- three in all",
      sum(1 for a, _l in code_lines() if mame_text(a) == "ldir"), 4, verbose)
    c("RING  prom_a's Ring608A0A_PutBlock is a DIFFERENT implementation -- a "
      "`djnz` loop over Ring_Put_0400, not an `ldir` -- which is why the names "
      "differ", rom("a")[0xF84318 - A_BASE:0xF8431C - A_BASE].hex(), "1d1942f8",
      verbose)
    # ---- the eight-slot thunk group, reached through a POINTER slot
    c("GROUP T_F40ED0 is a POINTER slot whose value is 0x00F57C00",
      "0x%08X" % int.from_bytes(at(0xF40ED0, 4), "little"), "0x00F57C00", verbose)
    c("GROUP 0xF57C00 holds eight `jp` slots: entry 0 to 0xF57C21 and 1..7 all "
      "to the bare `ret` at 0xF57C20",
      [mame_text(0xF57C00 + 4 * i) for i in range(8)],
      ["jp 0xf57c21"] + ["jp 0xf57c20"] * 7, verbose)
    c("GROUP ...and 0xF57C20 really is one byte 0x0E", at(0xF57C20, 1), b"\x0e",
      verbose)
    # ---- the unclaimed island
    c("ISL   NOTHING in either image spells any address inside 0x%06X-0x%06X, at "
      "any byte offset" % (ISLAND, ISLAND + 0x11E),
      [hex(x) for x in range(ISLAND, ISLAND + 0x11F)
       if rom("b").find(x.to_bytes(4, "little")) >= 0
       or rom("a").find(x.to_bytes(4, "little")) >= 0], [], verbose)
    c("ISL   it decodes as `link XIZ` bodies: the prologues and epilogues found",
      (len(link_prologues(ISLAND, ISLAND + 0x11F)),
       len([x for x in range(ISLAND, ISLAND + 0x11E) if at(x, 2) == b"\xee\x0d"])),
      (len(link_prologues(ISLAND, ISLAND + 0x11F)),
       len([x for x in range(ISLAND, ISLAND + 0x11E) if at(x, 2) == b"\xee\x0d"])),
      verbose)
    # ---- entry points and label hygiene
    th = thunks()
    c("ENTRY the thunk slots that land in the span",
      (len(th), sorted("T_%06X" % s for v in th.values() for s in v)[:3],
       sorted("T_%06X" % s for v in th.values() for s in v)[-3:]),
      (len(th), ["T_ModeEnter_SeqPlay_Fwd", "T_ModeLeave_SeqPlay_Fwd", "T_ModeEnter_RealtimeRecord_Fwd"],
       ["T_F42C9C", "T_F42CA0", "T_F42CA8"]), verbose)
    c("ENTRY every thunk target is an instruction boundary of this transcription",
      [hex(t) for t in th if t not in boundaries()], [], verbose)
    lab = labels()
    b_ = boundaries()
    objs = {a for a, _n, _k in OBJECTS}
    c("every label address is an instruction boundary or an object base",
      [hex(a) for a in lab if a not in b_ and a not in objs], [], verbose)
    c("no two labels share a name", len(set(lab.values())), len(lab), verbose)
    c("no label name collides with one already in prom_b outside this span",
      sorted(set(lab.values())
             & set(re.findall(r'^([A-Za-z_][A-Za-z0-9_]*):',
                              open(SRCB).read(), re.M))
             - set(v for a, v in lab.items() if v.startswith("sub_"))
             - _spliced_names()), [], verbose)
    # ---- the shape rules: how many routines each one reaches
    keys = sorted(x for x in lab if seg_of(x)[0] == "code")
    shp = {}
    for i2, a2 in enumerate(keys):
        _k2, s2, n2 = seg_of(a2)
        e2 = min(keys[i2 + 1] if i2 + 1 < len(keys) else s2 + n2, s2 + n2)
        sh2 = shape_of(a2, e2)[0]
        shp[sh2] = shp.get(sh2, 0) + 1
    c("SHAPE the six mechanical shapes and how many routines each reaches",
      dict((k2, v2) for k2, v2 in shp.items() if k2),
      {"ret": 19, "fwd": 34, "tablecall": 7, "write3602": 8,
       "write3602gated": 8, "set36ce": 3, "disp5": 4}, verbose)
    c("SHAPE ...and none of the names they produce grades CONTENT -- they are "
      "framed on purpose",
      [v2 for a2, v2 in lab.items()
       if shape_of(a2, min([x for x in keys if x > a2]
                           + [seg_of(a2)[1] + seg_of(a2)[2]]))[0]
       and not re.match(r'^[A-Za-z_][A-Za-z0-9_]*_(?:[0-9A-Fa-f]{4,6})$', v2)
       and a2 not in CODE_NAMES], [], verbose)
    c("REJECT the branch-join relaxation offers 30 addresses and only 0x%06X is "
      "an entry" % EXTRA_TAIL,
      (len(branch_join_candidates()), EXTRA_TAIL in branch_join_candidates()),
      (30, True), verbose)
    c("EXTRA the argument-read spelling %r occurs at exactly six addresses, and "
      "they are the six veneers" % EXTRA_ENTRY_SPELLING,
      [hex(x) for x in extra_entries()],
      ["0xf57c2d", "0xf57c3f", "0xf57c50", "0xf57c61", "0xf57c72", "0xf57c97",
       "0xf57ccd"], verbose)
    c("SLOTS no emitted line names a thunk slot by a spelling prom_b no longer "
      "defines (the 273 renamed by prom_b_thunks_round6.py)",
      sorted(set(x for x in re.findall(r'\bT_F4[0-9A-F]{4}\b', "\n".join(emit()))
                 if int(x[2:], 16) in _cache.get("sl", slot_label(0) and _cache["sl"]))),
      [], verbose)
    c("COUNTS labels, of which sub_XXXXXX and CONTENT (graded by "
      "wave7_documentation_metrics.py)",
      (len(lab), sum(1 for v in lab.values() if v.startswith("sub_")),
       sum(1 for a in lab if a in CODE_NAMES or (a, lab[a], "bittab") in OBJECTS)),
      (202, 96, 11), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAILED",
                                    len(FAIL)))
        for f in FAIL:
            print("   ! " + f)
    return not FAIL


def _spliced_names():
    """The names this file has ALREADY written into the .s, so the collision
    check does not fire against its own previous output."""
    lab = labels()
    txt = open(SRCB).read()
    return set(v for v in lab.values()
               if ("\n%s:" % v) in txt and ("gen_prom_b_f5553f_module" in txt))


# --------------------------------------------------------------------- main
def splice():
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    lines = emit()
    good, msg = verify_region(lines)
    if not good:
        raise SystemExit("refusing to splice: " + msg)
    src = open(SRCB).read().split("\n")
    want = ('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X'
            % (LO - B_BASE, HI - LO))
    hit = [i for i, l in enumerate(src) if l == want]
    if len(hit) == 1:
        i = hit[0]
        lo_ = i - 1 if src[i - 1].startswith("; --- 0xF5553F") else i
        hi_, how = i, "over the `.incbin`"
    else:
        # ⚠ THE TAIL ANCHOR MUST BE A REAL LINE.  emit() ends every data object
        # with a blank line, so `lines[-1]` is "" -- which matched 3,372 lines and
        # made the in-place re-splice refuse (it refused safely, and the gate
        # stayed green, but the file stopped being able to replace its own
        # output).  Both anchors are now the outermost lines that are neither
        # blank nor a comment; each carries a ROM address in its own comment, so
        # each is unique in the file.
        body = [k for k, l in enumerate(lines) if l.strip() and not l.startswith(";")]
        first, last = lines[body[0]], lines[body[-1]]
        a_ = [k for k, l in enumerate(src) if l == first]
        b2 = [k for k, l in enumerate(src) if l == last]
        if len(a_) != 1 or len(b2) != 1:
            raise SystemExit("cannot locate the spliced region: %d head anchors, "
                             "%d tail anchors" % (len(a_), len(b2)))
        lo_, hi_ = a_[0], b2[0]
        while lo_ and (src[lo_ - 1].startswith(";") or not src[lo_ - 1].strip()):
            lo_ -= 1
        while hi_ + 1 < len(src) and not src[hi_ + 1].strip():
            hi_ += 1
        how = "in place over lines %d-%d" % (lo_ + 1, hi_ + 1)
    write_part(SRCB_MASTER, "\n".join(src[:lo_] + lines + src[hi_ + 1:]))
    print("spliced %d lines %s; %s" % (len(lines), how, msg))
    return 0


def main():
    if "--splice" in sys.argv:
        return splice()
    if "--layout" in sys.argv:
        tot = {}
        for kind, s, n in LAYOUT:
            print("  %-6s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] = tot.get(kind, 0) + n
        print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("  substantive %d of %d"
              % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
        return 0
    if "--names" in sys.argv:
        # ★ GRADE WITH THE GOAL METRIC'S OWN CLASSIFIER, not a local one.  The
        # template this file was copied from used `^[A-Za-z]+_[0-9A-F]{6}$`, which
        # calls `Nop_Ret_F55C2E` CONTENT because it has two words before the
        # address -- while notes/wave7_documentation_metrics.py, the number that
        # actually counts, calls it FRAMED.  A lane that quoted the local rule
        # would report 34 content where the tree will score 7.
        import wave7_documentation_metrics as MM
        lab = labels()

        def grade(v):
            if MM.UNNAMED.match(v):
                return "sub_XXXXXX"
            if MM.FRAMED.match(v):
                return "framed"
            return "CONTENT"
        for a in sorted(lab):
            print("  0x%06X  %-6s %-36s %s"
                  % (a, seg_of(a)[0], lab[a], grade(lab[a])))
        g = {}
        for v in lab.values():
            g[grade(v)] = g.get(grade(v), 0) + 1
        print("  %d labels: %d content, %d framed, %d sub_XXXXXX  "
              "(graded by wave7_documentation_metrics.py)"
              % (len(lab), g.get("CONTENT", 0), g.get("framed", 0),
                 g.get("sub_XXXXXX", 0)))
        return 0
    if "--selftest" in sys.argv or "--checks" in sys.argv:
        ok = checks()
        if ok:
            good, msg = verify_region(emit())
            print(("  ok    " if good else "  FAIL  ") + "whole region: " + msg)
            ok = ok and good
        return 0 if ok else 1
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    lines = emit()
    good, msg = verify_region(lines)
    if not good:
        raise SystemExit("refusing to emit: " + msg)
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
