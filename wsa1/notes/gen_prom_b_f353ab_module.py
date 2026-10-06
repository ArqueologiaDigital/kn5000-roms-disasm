#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF353AB-0xF3934B -- the PARAMETER-RANGE CLAMP
module and the confirmation-prompt display list above it.

QUESTION IT ANSWERS
  "What is the assembly text for this 16,289-byte `.incbin`, in a form the byte
   gate accepts, with every label, header and table entry attached to the right
   address -- and which of its objects can be NAMED from evidence rather than
   framed?"

────────────────────────────────────────────────────────────────────────────────
WHAT THE SPAN IS.  Half of it is padding.
────────────────────────────────────────────────────────────────────────────────
    fill    8,079   three runs of 0x0E (`ret`), asserted pure on every emit
    code    5,426   in eight segments; 29 `link XIZ` routines and the arm runs
                    of six jump tables
    ptrtab  1,764   SIX jump tables, and every one of their extents is proved by
                    the `cp` bound in its own indexer
    data    1,020   one display list that frames exactly, and one 176-byte run
                    that decodes as code and is deliberately NOT claimed
    -----  16,289   substantive 8,210

★ WHAT THE MODULE DOES, and it is derived, not guessed.
  `ClampFieldToRange` (0xF3702F) takes five 16-bit words off the stack --
  value, mask, shift, max, min -- and computes

      merge( clamp( (value & mask) >> shift , min, max ) )

  masking with `~mask` and OR-ing the clamped field back, so the caller's other
  bits survive.  `jr LE` / `jr GE` make the clamp SIGNED, and one arm pushes
  0xFFC4/0x003C, i.e. -60..+60, which only makes sense signed.

  Everything else in the module feeds it.  `ClampParamValueById_From541`
  (0xF37069) and `ClampParamValueById_From408` (0xF37594) take a PARAMETER ID
  and a raw value, reduce the id to a small index, and `jp` into one of six
  tables of ARMS.  Each arm is two `push`es -- that parameter's minimum and
  maximum -- and a jump to a shared tail that pushes the mask and the shift and
  calls `ClampFieldToRange`.  So the six tables ARE the instrument's
  per-parameter range table, spelled as code.

  The id spaces, read off the `cp`/`sub` constants:
      0xF37069:  id >= 541 -> (id-541) mod 43, bound 41  -> ParamRangeArms_F370A7
                 id >= 217 -> (id-217) mod 81, bound 76  -> ParamRangeArms_F3719C
                 else         id itself,       bound 137 -> ParamRangeArms_F37312
      0xF37594:  id >= 408 -> (id-408) / 150, then a residue mod 43 (bound 41)
                              -> ParamRangeArms_F3760E, or mod 60 (bound 59)
                              -> ParamRangeArms_F37705
                 else         id itself,       bound 81  -> ParamRangeArms_F3782E
  and 0xF36888 computes the FORWARD map, `id = 541 + 43*n`, with the same 43 and
  the same 541.  --selftest re-reads all of those constants from the ROM.

⚠ WHAT IS NOT KNOWN, AND IS NOT GUESSED
  WHICH parameters these are.  Nothing in the span carries a name, a caption or
  a display list for any of them; the ids arrive from outside through six thunk
  slots.  So no arm and no table entry is given a parameter name, the six tables
  keep FRAMED names (a kind plus an address), and 45 of the 53 code labels stay
  `sub_XXXXXX` with the gap stated.  A range table whose rows are unnamed is
  still worth having: the ROWS are the evidence a later lane will match names to.

────────────────────────────────────────────────────────────────────────────────
WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
────────────────────────────────────────────────────────────────────────────────
  notes/prom_b_f067a6_layout.py, re-parametrised to this span and re-derived by
  build_layout() on EVERY run.  19 segments; this file refuses to print if the
  count moves, if the segments stop tiling [LO,HI), or if the barrier rules and
  the code walk disagree anywhere (they do not: 0 conflicts).

  ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.  freeze() masks the span out
  of `instr_starts("b")` and puts it back into `incbin_ranges("b")`, so
  `site_status()` still calls the span UNCONVERTED after the splice and the
  FARSITE seed set does not move.  Without it this file would stop reproducing
  its own output the moment it succeeded -- the trap
  notes/gen_prom_b_f067a6_module.py documents.

  ⚠ AND THE LAYOUT MODULE IS PARAMETRISED BY MODULE GLOBALS, NOT BY ARGUMENTS.
  `prom_b_f067a6_layout.seeds()` takes `lo=LO, hi=HI` as DEFAULTS, bound when the
  module was imported, so setting `M.LO` alone leaves the seed scan pointed at
  0xF067A6.  This file replaces `M.seeds` outright.  --selftest checks that the
  seeds really are inside this span.

NOTHING HERE CAN BREAK THE GATE
  Code comes from notes/llvm_roundtrip_autoforce.py, which assembles and byte-
  compares every candidate spelling before returning it.  Data is printed from
  the ROM.  Then verify_region() assembles the WHOLE emitted text with llvm-mc
  and compares all 16,289 bytes with the ROM, and main() exits non-zero WITHOUT
  PRINTING if it differs.

RUN
  python3 notes/gen_prom_b_f353ab_module.py             # the assembly
  python3 notes/gen_prom_b_f353ab_module.py --layout    # the segment table
  python3 notes/gen_prom_b_f353ab_module.py --names     # the naming census
  python3 notes/gen_prom_b_f353ab_module.py --selftest  # every number quoted above
  python3 notes/gen_prom_b_f353ab_module.py --splice    # write it into the .s
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
LO, HI = 0xF353AB, 0xF3934C
TBL_LO, TBL_HI = 0xF40000, 0xF44018
EXPECTED = 19

# A RECORD of the derivation, re-checked segment for segment on every emit.
LAYOUT = [
    ("fill",   0xF353AB, 0x1455),
    ("code",   0xF36800, 0x08A7),
    ("ptrtab", 0xF370A7, 0x00A8),
    ("code",   0xF3714F, 0x004D),
    ("ptrtab", 0xF3719C, 0x0134),
    ("code",   0xF372D0, 0x0042),
    ("ptrtab", 0xF37312, 0x0228),
    ("code",   0xF3753A, 0x00D4),
    ("ptrtab", 0xF3760E, 0x00A8),
    ("code",   0xF376B6, 0x004F),
    ("ptrtab", 0xF37705, 0x00F0),
    ("code",   0xF377F5, 0x0039),
    ("ptrtab", 0xF3782E, 0x0148),
    ("code",   0xF37976, 0x0651),
    ("fill",   0xF37FC7, 0x0839),
    ("code",   0xF38800, 0x044F),
    ("data",   0xF38C4F, 0x00B0),
    ("fill",   0xF38CFF, 0x0301),
    ("data",   0xF39000, 0x034C),
]
DATA_KINDS = ("data", "ptrtab")

# The six jump tables: (base, entries, bound `cp` site, bound value, default arm).
# Every field is RE-READ from the ROM by --selftest; the extent of each table is
# proved by the bound in its own indexer, not asserted here.
ARM_TABLES = [
    (0xF370A7, 42, 0xF37093, 0x29, 0xF3758D),
    (0xF3719C, 77, 0xF37188, 0x4C, 0xF3758D),
    (0xF37312, 138, 0xF372FE, 0x89, 0xF3758D),
    (0xF3760E, 42, 0xF375FA, 0x29, 0xF379A3),
    (0xF37705, 60, 0xF376F1, 0x3B, 0xF379A3),
    (0xF3782E, 82, 0xF3781A, 0x51, 0xF379A3),
]

OBJECTS = [
    (0xF370A7, None, "armtab"),
    (0xF3719C, None, "armtab"),
    (0xF37312, None, "armtab"),
    (0xF3760E, None, "armtab"),
    (0xF37705, None, "armtab"),
    (0xF3782E, None, "armtab"),
    (0xF38C4F, None, "island"),
    (0xF39000, "DL_YesAreYouSure", "dlist"),
]
FRAMED_NAMES = dict((b, "ParamRangeArms_%06X" % b) for b, _n, _s, _v, _d in ARM_TABLES)
FRAMED_NAMES[0xF38C4F] = "Unclaimed_F38C4F"

CODE_NAMES = {
    0xF36800: "Pack3x7BitFields_Bytes9To11",
    0xF36849: "Pack3x7BitFields_Bytes6To8",
    0xF3702F: "ClampFieldToRange",
    0xF37069: "ClampParamValueById_From541",
    0xF37594: "ClampParamValueById_From408",
    0xF37F3A: "Divide32_Unsigned_Quotient",
    0xF37F91: "Divide32_Unsigned_Remainder",
}

NAMED_WHY = {
    0xF3702F: ("five 16-bit words are read off the caller's stack -- (XIZ+0x08) "
               "value, (XIZ+0x0A) mask, (XIZ+0x0C) shift, (XIZ+0x0E) maximum, "
               "(XIZ+0x10) minimum.  The body is `ld DE,(XIZ+0x0a) / and "
               "DE,(XIZ+0x08)` then a shift by (XIZ+0x0C) through Asr16ByCount, "
               "then `cp WA,(XIZ+0x0e) / jr LE` and `cp HL,(XIZ+0x10) / jr GE` "
               "-- a SIGNED clamp, which is what one arm's 0xFFC4/0x003C pair "
               "(-60..+60) requires -- then `cpl BC / and BC,(XIZ+0x08) / or "
               "BC,HL`, which puts the clamped field back under the same mask "
               "and leaves every other bit of the value alone."),
    0xF37069: ("`ld XIX,(XIZ+0x08) / cp XIX,0x0000021d`: an id of 541 or more is "
               "reduced by `sub XBC,0x21d` and Divide32_Unsigned_Remainder with "
               "a divisor of 0x2B, bounded `cp IY,0x0029`, and indexes "
               "ParamRangeArms_F370A7; below that, `cp XIX,0x000000d9` splits "
               "217-and-up (mod 0x51, bound 0x4C, ParamRangeArms_F3719C) from "
               "the rest (the id itself, bound 0x89, ParamRangeArms_F37312).  "
               "The name says the FIRST of the three bases; the other two are in "
               "the table headers below and in --selftest."),
    0xF37594: ("the same shape with a different id space: `cp XBC,0x00000198` "
               "(408), then Divide32_Unsigned_Quotient by 0x96 (150), `ld A,0x96 "
               "/ mul WA,E / add XWA,0x000001d8` to rebuild the row base, and a "
               "residue taken mod 0x2B (bound 0x29, ParamRangeArms_F3760E) or "
               "mod 0x3B+1 (bound 0x3B, ParamRangeArms_F37705); an id below 408 "
               "indexes ParamRangeArms_F3782E directly, bound 0x51.  It returns "
               "through 0xF379A3, the OTHER default arm, where 0xF37069 returns "
               "through 0xF3758D."),
    0xF37F3A: ("a 32-iteration restoring division.  `ld B,0x20` is the loop "
               "count; `sllw (XIZ+0x08)` / `sllw (XIZ+0x0a)` shift the 32-bit "
               "dividend left one bit per iteration through the carry, `cp "
               "XIX,(XIZ+0x0c) / sub XIX,(XIZ+0x0c)` compares and conditionally "
               "subtracts the 32-bit divisor, and `inc 1,XIY` sets the quotient "
               "bit.  XIX -- the running remainder -- is `pop`ped back at the "
               "end, so what survives is XIY, the QUOTIENT.  `retd 0x0008` "
               "removes the two 32-bit arguments.  ★ CONFIRMED FROM THE OTHER "
               "SIDE: 0xF375BA divides (id - 408) by 150 with this routine and "
               "then multiplies the answer by 150 again to rebuild a row base, "
               "which only works if the answer is a quotient."),
    0xF37F91: ("the same 32-iteration restoring division with the two "
               "accumulators exchanged: here XIY holds the running remainder and "
               "XIX the quotient bits, and XIX is the one `pop`ped back, so what "
               "survives is the REMAINDER.  ★ CONFIRMED FROM THE OTHER SIDE: "
               "0xF3708D calls it with a divisor of 0x2B and immediately bounds "
               "the answer `cp IY,0x0029` -- 41 -- which is exactly the largest "
               "residue mod 43, and would be wrong for a quotient."),
    0xF36800: ("three bytes are read from the record at (XIZ+0x08): (XIX+0x09), "
               "(XIX+0x0A), (XIX+0x0B).  Each has bit 7 cleared by `res 0x07`, "
               "and they are shifted left by 14, by 7 and by 0 before being "
               "OR-ed together.  Seven-bit fields at those three shifts is the "
               "MIDI-style split of one value across three bytes, and the name "
               "says only that."),
    0xF36849: ("identical to Pack3x7BitFields_Bytes9To11 three bytes earlier in "
               "the record: (XIX+0x06), (XIX+0x07), (XIX+0x08), `res 0x07` on "
               "each, shifts of 14, 7 and 0.  It differs only in returning "
               "through XIY rather than WA."),
}
NAMED_GAP = {
    0xF36800: ("the last two ORs are 16-bit (`or DE,WA` / `or BC,DE`), and "
               "`ld IY,(XIZ+0xfc)` takes only the low half of the 14-bit-shifted "
               "field, so the value this routine returns is 16 bits wide and the "
               "top five bits of the first field do not survive.  That is what "
               "the instructions do; whether it is intended is NOT decoded here, "
               "and no 21-bit claim is made."),
    0xF36849: ("the same 16-bit truncation as its twin, and the same open "
               "question about it."),
    0xF3702F: ("what the value IS.  The routine is a generic field clamp; the "
               "meaning of the mask, the shift and the range comes from whichever "
               "arm called it, and no arm carries a name."),
    0xF37069: ("what the parameter ids ENUMERATE.  They arrive from outside the "
               "span through T_F41250-T_F41264 and nothing decoded here says what "
               "any of them is."),
    0xF37594: ("the same gap, and additionally why there are TWO id spaces with "
               "two default arms."),
    0xF37F3A: ("nothing -- the routine is fully determined by its own "
               "instructions."),
    0xF37F91: ("nothing -- the routine is fully determined by its own "
               "instructions."),
}

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
    """{target: [slot, ...]} for the `jp addr24` slots of 0xF40000 landing here."""
    if "th" in _cache:
        return _cache["th"]
    out = {}
    for a in range(TBL_LO, TBL_HI, 4):
        if at(a, 1)[0] == 0x1B:
            t = w32(a) >> 8
            if LO <= t < HI:
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
    """{target: [(table, index), ...]} over the six arm tables."""
    if "ae" in _cache:
        return _cache["ae"]
    out = {}
    for base, n, _s, _v, _d in ARM_TABLES:
        for i in range(n):
            v = w32(base + 4 * i)
            if LO <= v < HI:
                out.setdefault(v, []).append((base, i))
    _cache["ae"] = out
    return out


# ------------------------------------------------------------------- labels
def seg_of(a):
    for kind, s, n in LAYOUT:
        if s <= a < s + n:
            return kind, s, n
    return None, None, None


def labels():
    if "lab" in _cache:
        return _cache["lab"]
    b = boundaries()
    got = {}
    # ⚠ far_sites() IS NOT A LABEL SOURCE.  It is an opcode-anchored scan of both
    # whole images: every 0x1D/0x1B byte whose next three bytes happen to spell an
    # address in this span counts, whether or not that byte is an instruction.  It
    # is good enough to SEED a walk (that is what the layout uses it for) and much
    # too loose to justify a label.  Using it here produced 200 labels where the
    # three real sources produce far fewer, and every extra one would have been a
    # sub_XXXXXX with a header citing a site that may be a data byte.
    for src in (thunks(), internal_calls(), arm_entries(), graded_far()):
        for t in src:
            if t in b:
                got[t] = None
    for a, name, _kind in OBJECTS:
        got[a] = name
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


def calls_out(lo, hi, lab):
    out = []
    for a, _ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r"^(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", mame_text(a))
        if m:
            t = int(m.group(1), 16)
            x = lab.get(t) or ("T_%06X" % t if TBL_LO <= t < TBL_HI else "0x%06X" % t)
            if x not in out:
                out.append(x)
    return out


def code_header(a, end, lab):
    th, sr, ic, ae, fs = thunks(), slot_refs(), internal_calls(), arm_entries(), far_sites()
    L = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    if a in ae:
        parts.append("arm table " + ", ".join("0x%06X[%d]" % t for t in ae[a][:6]) +
                     (" +%d more" % (len(ae[a]) - 6) if len(ae[a]) > 6 else ""))
    out_sites = [x for x in fs.get(a, []) if not (LO <= x < HI)]
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
        L += wrap("; Evidence: ", "entry [%d] of the arm table at 0x%06X reads "
                  "0x00%06X, that table's indexer ends `jp (Xrr)`, and 0x%06X is "
                  "an instruction boundary of this transcription."
                  % (i_, b_, a, a))
    else:
        L += wrap("; Evidence: ", "reached by a branch decoded in this "
                  "transcription (the sites are listed above), so 0x%06X is an "
                  "instruction boundary." % a)
    gap = NAMED_GAP.get(a)
    if gap and gap.startswith("nothing"):
        pass
    elif gap:
        L += wrap("; Unknown: ", gap)
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


DL_TEXT_1 = {0x06, 0x07, 0x08, 0x16, 0x18, 0x19, 0x1A, 0x1D, 0x1E, 0x1F, 0x20, 0x21}
DL_TEXT_2 = {0x17, 0x1C}


def dl_records(lo, hi):
    """[(addr, opcode, length, text)] by walking the length bytes, exactly as
    DisplayList_Run does.  The walk is the framing CHECK, not an assumption: it
    must land on `hi` and nowhere else."""
    out, p = [], lo
    while p < hi:
        op, ln = at(p, 1)[0], at(p + 1, 1)[0]
        if op >= 0x24 or ln < 2 or p + ln > hi:
            return None
        if op in DL_TEXT_1:
            raw = at(p + 4, ln - 4)
        elif op in DL_TEXT_2:
            raw = at(p + 6, ln - 6)
        else:
            raw = b""
        out.append((p, op, ln, "".join(chr(x) for x in raw if 32 <= x < 127)))
        p += ln
    return out if p == hi else None


def longest_repeat(lo, hi):
    """(length, first offset, second offset) of the longest byte run that occurs
    twice inside [lo,hi).  O(n^2) over 176 bytes, which is free, and it means the
    number in the header is MEASURED rather than eyeballed off a hex dump -- the
    first draft eyeballed it and was wrong by a byte and an address."""
    seg = at(lo, hi - lo)
    best = (0, lo, lo)
    for i in range(len(seg)):
        for j in range(i + 1, len(seg)):
            k = 0
            while j + k < len(seg) and seg[i + k] == seg[j + k]:
                k += 1
            if k > best[0]:
                best = (k, lo + i, lo + j)
    return best


def link_prologues(lo, hi):
    return [x for x in range(lo, hi - 1) if at(x, 2) == b"\xee\x0c"]


def data_object(a, end, lab, kind):
    n, name = end - a, lab[a]
    out = ["; " + "-" * 74]
    if kind == "armtab":
        base, cnt, site, bound, dflt = [t for t in ARM_TABLES if t[0] == a][0]
        ps = [w32(a + 4 * i) for i in range(n // 4)]
        tgt = sorted(set(ps))
        out += wrap("; %s -- " % name,
                    "%d 32-bit entries, all inside this block (0x%06X-0x%06X), "
                    "naming %d distinct arm%s.  Each arm is one or two `push "
                    "imm16` instructions -- that parameter's MINIMUM and MAXIMUM "
                    "-- and a jump to a shared tail that pushes the mask and the "
                    "shift and calls ClampFieldToRange."
                    % (len(ps), min(ps), max(ps), len(tgt),
                       "" if len(tgt) == 1 else "s"))
        # The `add Xr,<base>` site is FOUND, not offset from the bound: a fixed
        # +0x0A happens to be right for all six here, and a constant that is
        # right by coincidence is the kind of thing this tree has been bitten by.
        reg = mame_text(site).split(",")[0].split()[-1]
        want_add = "add X%s,0x00%06x" % (reg.lower(), a)
        addsite = [x for x, _l in code_lines() if mame_text(x).lower() == want_add.lower()]
        out += wrap("; Read by: ", "0x%06X, `sll 0x02,%s / add X%s,0x00%06X / "
                    "ld X%s,(X%s) / jp (X%s)`, with the index bounded by the "
                    "`cp %s,0x%04X / jrl UGT,0x%06X` at 0x%06X immediately above it."
                    % (addsite[0] if addsite else site, reg, reg, a, reg, reg,
                       reg, reg, bound, dflt, site))
        out += wrap("; Evidence: ", "the ENTRY COUNT IS PROVED BY THE INDEXER'S "
                    "OWN BOUND, not by the extent: `cp %s,0x%04X / jrl UGT,"
                    "0x%06X` at 0x%06X admits indices 0..%d, and %d x 4 = %d "
                    "bytes, which is exactly this segment.  Every word is re-read "
                    "on each emit and asserted to land inside 0x%06X-0x%06X."
                    % (reg, bound, dflt, site, bound, bound + 1, (bound + 1) * 4,
                       LO, HI))
        out += wrap("; Unknown: ", "WHICH parameter each index is.  Nothing in "
                    "this span names one, so the table keeps a FRAMED name and "
                    "not one arm is given a parameter's name.  ★ The ROWS are the "
                    "evidence a later lane will match names to: entry [i]'s arm "
                    "carries that parameter's legal range as two immediates.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, p in enumerate(ps):
            t2 = lab.get(p) or ("0x%06X" % p)
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s" % (p, a + 4 * i, i, t2))
        return out
    if kind == "island":
        pro = link_prologues(a, a + n)
        out += wrap("; %s -- " % name,
                    "%d bytes that decode as code and are deliberately NOT "
                    "claimed as code.  Nothing in either image references any "
                    "address inside them, so the layout has no entry point to "
                    "start a walk from, and this tree does not promote a run to "
                    "code on the strength of a decode alone." % n)
        unlk = [x for x in range(a, a + n - 1) if at(x, 2) == b"\xee\x0d"]
        rep = longest_repeat(a, a + n)
        out += wrap("; Decodes as: ", "ONE `link XIZ,0xfff4` prologue, at 0x%06X, "
                    "and THREE `unlk XIZ` opcode pairs, at %s -- so two of the "
                    "three bodies have no prologue of their own inside this run. "
                    " And the longest repeated byte run inside it is %d bytes "
                    "long, at 0x%06X and 0x%06X: the same code twice, which is "
                    "what a compiler emits for two copies of one function."
                    % (a, " ".join("0x%06X" % x for x in unlk),
                       rep[0], rep[1], rep[2]))
        out += wrap("; Evidence: ", "the `link`/`unlk` opcode pairs are "
                    "re-scanned over 0x%06X-0x%06X on every emit and the repeated "
                    "run is re-measured by an O(n^2) search; neither is typed in. "
                    " ⚠ AND THE FIRST DRAFT OF THIS HEADER WAS WRONG ABOUT BOTH: "
                    "it said three `link` prologues (there is one) and a 76-byte "
                    "repeat at 0xF38C53 (it is %d bytes at 0x%06X).  --selftest "
                    "now pins the measured values.  What this region needs is a "
                    "REFERENCE, not a better decoder." % (a, a + n - 1, rep[0], rep[1]))
        out += wrap("; Unknown: ", "who calls any of it.  Kept as `.byte` and a "
                    "FRAMED name.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += byte_rows(a, n)
        return out
    if kind == "dlist":
        recs = dl_records(a, end)
        lits = [t for _p, _o, _l, t in recs if re.search(r"[A-Za-z]{2}", t)]
        n0 = [t for p_, _o, _l, t in recs if p_ == 0xF39311]
        out += wrap("; %s -- " % name,
                    "a display list: %d records, framed by their own length "
                    "bytes.  The walk from 0x%06X consumes exactly %d bytes and "
                    "lands on 0x%06X, which is where the already-converted list "
                    "DL_F3934C begins."
                    % (len(recs), a, n, end))
        out += wrap("; Draws:   ", "%s -- and, at 0x%06X, %s.  ⚠ THE NAME USES "
                    "ONLY THE FIRST TWO.  Round 4's rule keeps a literal only if "
                    "it holds two ADJACENT letters, which is what stops a "
                    "coordinate byte being quoted as text; the ROM spells NO with "
                    "a digit zero, so that record does not pass it.  The list "
                    "draws it all the same, which is why it is named here."
                    % ("; ".join('"%s"' % t for t in lits), 0xF39311,
                       "; ".join('"%s"' % t for t in n0)))
        out += wrap("; Evidence: ", "the framing walk is re-run on every emit and "
                    "the file refuses to print if it does not land on 0x%06X; and "
                    "the NAME is the CamelCase of the literals above, which is the "
                    "rule notes/prom_b_dl_screens_round5.py and round 4's "
                    "--dl-names use for every other list in this image.  It says "
                    "what the list PUTS ON THE SCREEN and nothing more." % end)
        out += wrap("; Unknown: ", "who runs it.  No call site of any of the four "
                    "shapes in notes/prom_b_dl_call_shapes.py names 0x%06X, so "
                    "the list is framed and named but UNREACHED by the census -- "
                    "the same honest hole the tree records for other lists." % a)
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for p, op, ln, t in recs:
            out += byte_rows(p, ln, 16,
                             "  op %02X, %d bytes%s" % (op, ln, ('  "%s"' % t) if t else ""))
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
; 0xF353AB-0xF3934B -- THE PARAMETER-RANGE CLAMP MODULE, AND THE CONFIRMATION
;   PROMPT ABOVE IT.  16,289 bytes, of which %d are 0x0E padding.
; ==============================================================================
;
; @@ WHAT THE MODULE DOES.  ClampFieldToRange (0xF3702F) reads five 16-bit words
; off the caller's stack -- value, mask, shift, maximum, minimum -- and returns
; the value with ONE FIELD replaced by that field clamped, SIGNED, to [min,max]:
;   `and DE,(XIZ+0x08)` masks, Asr16ByCount shifts, `jr LE`/`jr GE` clamp, and
;   `cpl BC / and BC,(XIZ+0x08) / or BC,HL` merges the field back under the same
;   mask so every other bit survives.
; Everything else feeds it.  ClampParamValueById_From541 (0xF37069) and
; ClampParamValueById_From408 (0xF37594) take a PARAMETER ID, reduce it to a
; small index, and `jp` into one of SIX tables of arms; each arm pushes that
; parameter's minimum and maximum and falls into a shared tail.  The six tables
; are therefore the instrument's per-parameter RANGE TABLE, spelled as code.
;
; @@ WHAT IS NOT KNOWN.  WHICH parameter any index is.  The ids arrive from
; outside through six thunk slots and nothing in the span names one, so the six
; tables keep FRAMED names, not one arm is named, and %d of the %d labels are
; sub_XXXXXX with the gap stated.
;
; @@ WHERE THE BOUNDARIES COME FROM.  notes/prom_b_f067a6_layout.py, re-derived
; on EVERY run of this file with LO/HI moved to this span and its `seeds()`
; replaced (its defaults were bound to the other span at import time).  %d
; segments, 0 conflicts between the barrier rules and the code walk.  Not from a
; linear decode -- notes/prom_a_linear_decode_check.py records why one pins
; nothing.
;
; @@ SIX ARM TABLES, AND EACH EXTENT IS PROVED BY ITS OWN INDEXER.  A `cp r,N /
; jrl UGT,<default>` immediately above every `add Xr,<base>` bounds the index, so
; the entry count is N+1 and the byte extent is 4*(N+1) -- which is exactly the
; segment the content rules found, six times over.  Nothing about a table's size
; is asserted here.
;   0xF370A7 42   0xF3719C 77   0xF37312 138
;   0xF3760E 42   0xF37705 60   0xF3782E 82
;
; @@ ONE LEAD LEFT OPEN.  0xF37E23 is an instruction boundary seven bytes past
; the thunk entry 0xF37E1C, and prom_b 0xF7AE62 spells it as a 32-bit word -- but
; that byte is still inside an `.incbin`, so one spelling in unknown bytes is not
; evidence of an entry point and no label is given.  --selftest pins both facts.
;
; @@ ONE RUN LEFT UNCLAIMED.  0xF38C4F-0xF38CFE decodes as `link XIZ` routines
; and two of its runs are byte-identical for 76 bytes, but NOTHING references any
; address inside it, so it is emitted as `.byte` with the decode stated rather
; than promoted to code.  Same rule as 0xF09E85 in the 0xF067A6 block.
;
; LAYOUT.  %d segments: %d code (%d bytes), %d arm tables (%d bytes),
; %d data objects (%d bytes) and %d runs of 0x0E `ret` padding (%d bytes).
; Substantive: %d of %d.
;
; LABELS.  %d, of which %d carry a name derived from something and %d are
; sub_XXXXXX with the gap stated.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.
; Heaviest 16-bit RAM words: %s.
; That is a measurement of what the code ADDRESSES, not a claim about what it IS.
;
; REGENERATE:  python3 notes/gen_prom_b_f353ab_module.py
; CHECKS:      python3 notes/gen_prom_b_f353ab_module.py --selftest
; ==============================================================================
""" % (b.get("fill", 0), nsub, len(lab), EXPECTED,
       len(LAYOUT), k.get("code", 0), b.get("code", 0),
       k.get("ptrtab", 0), b.get("ptrtab", 0),
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
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in thunks()[a]) \
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
    # ---- the six arm tables, and the bound that proves each extent
    for base, cnt, site, bound, dflt in ARM_TABLES:
        seg = [(k, s, n) for k, s, n in LAYOUT if s == base]
        c("ARMS  0x%06X: the indexer's `cp r,0x%02X` bounds the index, so the "
          "table is %d entries = %d bytes, and that is the segment"
          % (base, bound, cnt, cnt * 4),
          (bound + 1, cnt * 4, seg[0][2] if seg else None), (cnt, cnt * 4, cnt * 4),
          verbose)
        c("ARMS  0x%06X: the bound really is at 0x%06X in the transcription"
          % (base, site), mame_text(site).lower().replace(" ", ""),
          ("cp%s,0x%04x" % (mame_text(site).split(",")[0].split()[-1], bound)).lower(),
          verbose)
        ps = [w32(base + 4 * i) for i in range(cnt)]
        c("ARMS  0x%06X: every entry lands inside the span, FIRST and LAST "
          "included (0x%06X .. 0x%06X)" % (base, ps[0], ps[-1]),
          [hex(x) for x in ps if not (LO <= x < HI)], [], verbose)
        c("ARMS  0x%06X: its default arm 0x%06X is an instruction boundary"
          % (base, dflt), dflt in boundaries(), True, verbose)
    # ---- the two id maps, re-read from the ROM
    c("ID    0xF37069 tests `cp XIX,0x0000021d` (541) and divides by 0x2B (43)",
      (mame_text(0xF37075), mame_text(0xF37080), mame_text(0xF37089)),
      ("cp XIX,0x0000021d", "sub XBC,0x0000021d", "push 0x002b"), verbose)
    c("ID    ...and 0xF36888 builds the SAME map forwards: 43 and 541",
      (mame_text(0xF368A1), mame_text(0xF368A8)),
      ("ld A,0x2b", "add XWA,0x0000021d"), verbose)
    c("ID    0xF37594 tests `cp XBC,0x00000198` (408) and divides by 0x96 (150)",
      (mame_text(0xF375A4), mame_text(0xF375AD), mame_text(0xF375B6),
       mame_text(0xF375C6)),
      ("cp XBC,0x00000198", "sub XBC,0x00000198", "push 0x0096", "ld A,0x96"), verbose)
    c("ID    the two chains end in DIFFERENT default arms",
      sorted(set(d for _b, _c2, _s, _v, d in ARM_TABLES)), [0xF3758D, 0xF379A3], verbose)
    # ---- the two divide routines, and the use that tells them apart
    c("DIV   both are 32-iteration loops (`ld B,0x20`) over two 32-bit arguments "
      "(`retd 0x0008`)",
      [(mame_text(0xF37F3F), mame_text(0xF37F6D)),
       (mame_text(0xF37F96), mame_text(0xF37FC4))],
      [("ld B,0x20", "retd 0x0008"), ("ld B,0x20", "retd 0x0008")], verbose)
    c("DIV   0xF37F3A keeps its answer in XIY and restores XIX (the remainder)",
      (mame_text(0xF37F64), mame_text(0xF37F6A)), ("inc 1,XIY", "pop XIX"), verbose)
    c("DIV   0xF37F91 increments XIX -- and restores it -- so XIY, the "
      "REMAINDER, is what survives",
      (mame_text(0xF37FBB), mame_text(0xF37FC1)), ("inc 1,XIX", "pop XIX"), verbose)
    c("DIV   and the callers agree: 0xF3708D divides by 43 then bounds the answer "
      "at 41, the largest residue; 0xF375BA divides by 150 and multiplies the "
      "answer by 150 again",
      (mame_text(0xF37093), mame_text(0xF375C6), mame_text(0xF375C8)),
      ("cp IY,0x0029", "ld A,0x96", "mul WA,E"), verbose)
    # ---- the clamp
    c("CLAMP 0xF3702F masks, shifts, clamps SIGNED and merges back",
      [mame_text(x) for x in (0xF37038, 0xF37040, 0xF37049, 0xF37053,
                              0xF3705B, 0xF3705D, 0xF37060)],
      ["and DE,(XIZ+0x08)", "call 0xf37f70", "jr LE,0xf37050", "jr GE,0xf37058",
       "cpl BC", "and BC,(XIZ+0x08)", "or BC,HL"], verbose)
    c("CLAMP and one arm pushes -60..+60, which is only a range if the compare "
      "is signed",
      (mame_text(0xF376D7), mame_text(0xF376DA)),
      ("push 0xffc4", "push 0x003c"), verbose)
    # ---- the two packers
    for a, off in ((0xF36800, 9), (0xF36849, 6)):
        c("PACK  0x%06X reads (XIX+0x%02x/%02x/%02x), clears bit 7 of each and "
          "shifts by 14, 7, 0" % (a, off, off + 1, off + 2),
          [mame_text(x) for x in ((0xF3680A, 0xF3680D, 0xF36814, 0xF36824)
                                  if a == 0xF36800 else
                                  (0xF36851, 0xF36854, 0xF3685B, 0xF3686B))],
          ["ld C,(XIX+0x%02x)" % off, "res 0x07,C", "sll 0x0e,XBC", "sll 0x07,XWA"],
          verbose)
    # ---- the display list
    recs = dl_records(0xF39000, 0xF3934C)
    c("DL    the walk from 0xF39000 frames EXACTLY onto 0xF3934C",
      recs is not None and len(recs), 70, verbose)
    c("DL    ...and a walk started one byte later does NOT frame",
      dl_records(0xF39001, 0xF3934C), None, verbose)
    lits = [t for _p, _o, _l, t in recs if re.search(r"[A-Za-z]{2}", t)]
    c("DL    the two literals the NAME is built from, and the third the ROM "
      "spells with a digit zero",
      ([t for t in lits], [t for p_, _o, _l, t in recs if p_ == 0xF39311]),
      (["YES ", "Are You Sure ?"], ["N0  "]), verbose)
    c("DL    ...and the name is the CamelCase of the first two",
      labels()[0xF39000], "DL_YesAreYouSure", verbose)
    c("DL    0xF3934C, where it ends, is the start of the already-converted "
      "DL_F3934C", "DL_F3934C:" in open(SRCB).read(), True, verbose)
    # ---- the unclaimed island
    pro = link_prologues(0xF38C4F, 0xF38CFF)
    unlk = [x for x in range(0xF38C4F, 0xF38CFE) if at(x, 2) == b"\xee\x0d"]
    c("ISL   0xF38C4F opens with `link XIZ,0xfff4`, and the run holds ONE `link` "
      "but THREE `unlk`",
      (at(0xF38C4F, 4), [hex(x) for x in pro], [hex(x) for x in unlk]),
      (b"\xee\x0c\xf4\xff", ["0xf38c4f"], ["0xf38ca0", "0xf38ced", "0xf38cfd"]),
      verbose)
    c("ISL   its longest repeated byte run is 77 bytes, at 0xF38C56 and 0xF38CA3",
      longest_repeat(0xF38C4F, 0xF38CFF), (77, 0xF38C56, 0xF38CA3), verbose)
    c("ISL   and NOTHING in either image spells any address inside it",
      [hex(x) for x in range(0xF38C4F, 0xF38CFF)
       if rom("b").find(x.to_bytes(4, "little")) >= 0
       or rom("a").find(x.to_bytes(4, "little")) >= 0], [], verbose)
    # ---- entry points and label hygiene
    th = thunks()
    # ⚠ AND ONE GRADED FAR TARGET IS A FALSE POSITIVE, WHICH IS WHY THE LABEL
    # RULE ALSO DEMANDS AN INSTRUCTION BOUNDARY.  0xF371FD is named by a
    # `call addr24` opcode at prom_b 0xF78AD1 and 0xF78BA9, and the grading keeps
    # those sites because they sit inside an `.incbin` where nothing is known.
    # But 0xF371FD is 0x61 bytes into the 4-byte-strided arm table at 0xF3719C --
    # not even an entry boundary -- so the opcode is a data byte and the target is
    # noise.  It gets no label, and this check says why.
    c("ENTRY 0xF371FD is a graded far target that is NOT an instruction boundary: "
      "it is 0x61 bytes into ParamRangeArms_F3719C, so the site is a data byte",
      (0xF371FD in graded_far(), 0xF371FD in boundaries(),
       (0xF371FD - 0xF3719C) % 4), (True, False, 1), verbose)
    # ⚠ CORRECTED BY THIS CHECK.  The draft said all three LE32 spellings of a
    # span address found outside the span are coincidences.  TWO are -- 0xF377F0
    # is mid-arm-table and 0xF37ECA is mid-instruction -- but 0xF37E23 IS an
    # instruction boundary, seven bytes past the thunk entry 0xF37E1C.  ★ LEAD:
    # 0xF7AE62 in prom_b spells it as a 32-bit word and that byte is still inside
    # an `.incbin`, so it may be a genuine entry point through a table nobody has
    # framed.  It is left UNLABELLED here because one spelling in unconverted
    # bytes is not evidence, and recorded so a later lane can settle it.
    c("ENTRY of the three LE32 spellings of a span address found outside the "
      "span, 0xF377F0 and 0xF37ECA are not instruction boundaries but 0xF37E23 "
      "IS -- a lead, not a label",
      [hex(x) for x in (0xF377F0, 0xF37E23, 0xF37ECA) if x in boundaries()],
      ["0xf37e23"], verbose)
    c("ENTRY ...and its one spelling is at prom_b 0xF7AE62",
      [hex(B_BASE + i) for i in range(len(rom("b")) - 3)
       if int.from_bytes(rom("b")[i:i + 4], "little") == 0xF37E23], ["0xf7ae62"],
      verbose)
    c("ENTRY six thunk slots and two more land in the span",
      sorted("T_%06X" % s for v in th.values() for s in v),
      ["T_SysExThirdRegion_FetchNextChunk", "T_SysExThirdRegion_AcceptRequest", "T_SysExToneImage_WriteByte", "T_SysExParam_ExecSoundWriteRequest", "T_F41260", "T_SysExThirdRegion_SendReplyChunk",
       "T_ParamImage_CopyToSongWorkspace", "T_F42664"], verbose)
    lab = labels()
    b_ = boundaries()
    objs = {a for a, _n, _k in OBJECTS}
    c("every label address is an instruction boundary or an object base",
      [hex(a) for a in lab if a not in b_ and a not in objs], [], verbose)
    c("no two labels share a name", len(set(lab.values())), len(lab), verbose)
    c("COUNTS labels, of which sub_XXXXXX, and code labels named",
      (len(lab), sum(1 for v in lab.values() if v.startswith("sub_")),
       sum(1 for a in lab if a in CODE_NAMES)),
      (len(lab), len(lab) - len(CODE_NAMES) - len(OBJECTS), len(CODE_NAMES)), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAILED",
                                    len(FAIL)))
        for f in FAIL:
            print("   ! " + f)
    return not FAIL


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
        lo_ = i - 1 if src[i - 1].startswith("; --- 0xF353AB") else i
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
        lab = labels()
        for a in sorted(lab):
            print("  0x%06X  %-6s %-32s %s"
                  % (a, seg_of(a)[0], lab[a],
                     "DERIVED" if not lab[a].startswith("sub_")
                     and not re.match(r'^[A-Za-z]+_[0-9A-F]{6}$', lab[a])
                     else ("framed" if lab[a][0].isupper() else "gap stated")))
        n = sum(1 for v in lab.values() if v.startswith("sub_"))
        f = sum(1 for v in lab.values()
                if re.match(r'^[A-Za-z]+_[0-9A-F]{6}$', v) and not v.startswith("sub_"))
        print("  %d labels: %d content, %d framed, %d sub_XXXXXX"
              % (len(lab), len(lab) - n - f, f, n))
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
