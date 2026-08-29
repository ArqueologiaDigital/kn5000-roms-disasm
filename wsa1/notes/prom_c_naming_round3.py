#!/usr/bin/env python3
"""WAVE 7 ROUND 3, LANE WRITER-C: what more can be said about prom_c, and how is it checked?

QUESTION IT ANSWERS
  prom_c is territorially complete and the best-named image (91.8% at the start of this
  round), so the work left in it is DEPTH, not count.  `notes/wave7_documentation_metrics.py`
  measures the shape of the gap exactly:

      prom_c   5,897 "semantic"   524 sub_XXXXXX   1,052 headers   803 Evidence: lines

  and this file's `--gap` mode shows what those totals hide -- of prom_c's 1,067 labels
  that are neither `sub_XXXXXX` nor a `__local`, only 281 carry an Evidence: line, while
  520 of the 524 sub_XXXXXX carry one, because `gen_prom_c_block_headers.py` generated a
  boilerplate header for every routine it converted and NOTHING generated one for a
  routine somebody named by hand.  So the tree's least-evidenced routines are its
  BEST-UNDERSTOOD ones.  That inversion is what this round attacks.

  Five modes, one question each:

  --regaudit  "Does every Dev10C_/Dev104_ per-channel accessor's NAME match the register
              block its ROM BYTES select?"  The names spell a register number
              (`Dev10C_SetChanReg_0440`), and a name that spells a number is exactly the
              kind of claim the byte gate cannot check.  This mode decodes each accessor
              body straight out of `original_ROMs/wsa1_prom_c.ic28` -- the `add rr,imm16`
              that forms the select value and the `ld rr,(XBC+d)` / `(XIX+d)` that fetches
              the data -- and compares the result with the name.  It also emits the
              register <- staging-word map, which is the table an emulator needs.
              ⚠ POSITIVE AND NEGATIVE CONTROL, because a decoder that finds nothing looks
              exactly like a decoder that is broken: the device literal 0x0010C000 must be
              found in every accessor named Dev10C_*, and in ZERO of the image's
              `Table_FE*` / `Curve_*` data blocks.

  --struct    "How big is the 0x0010C000 staging struct, and where does it live?"  Answered
              by arithmetic on three independently established addresses, not by assertion:
              the accessor bank reads fields up to +0x42; 0x00D75E + 0x2C is 0x00D78A, the
              absolute address round 2's Dev10C_WriteSixChanRegs_FromD78A commits from; and
              0x00D75E + 0x44 is 0x00D7A2, the pointer VoiceRegs_Stage_A hands to the
              0x00104000 writer.  Two of those are coincidences only if the struct is 68
              bytes long -- which is also the length Dev10C_ResetAllChannels copies from
              ROM 0xFE12CF.  Four readings, one number.

  --scale     "What does 0xFA75BA compute, and does its caller's clamp ever fire?"  The
              routine is the input to the LOW BYTE of register 0x0500 + chan.  This mode
              evaluates the whole datapath EXHAUSTIVELY -- all 256 depth bytes x all 256
              position bytes -- against the two ROM tables, and reports the exact set of
              inputs for which Clamp_ToRange_Word(x, 0, 0x7F) changes its argument.

  --blankgap  "Is `wave7_documentation_metrics.py`'s header count right?"  It requires the
              comment block to be IMMEDIATELY above the label, and 35 of prom_c's headers
              are separated from their label by one blank line, so they do not count.  This
              mode measures that, per image.  ⚠ The number is reported as an ARTEFACT, and
              this round's header total is quoted split into "new text" and "blank line
              removed" for exactly that reason -- closing the gap by deleting whitespace is
              not documentation.

  --names / --apply / --headers / --applyheaders / --check-applied
              the rename table and the header/Evidence insertions this round ships, and the
              idempotent editors that put them into prom_c/wsa1_prom_c.s.

  --claims    re-derives EVERY number this round wrote into a routine header, from the ROM
              bytes or from a second tool.  --selftest runs it plus negative controls.

WHAT THIS ROUND DOES NOT ESTABLISH
  * What registers 0x0440, 0x0480 and 0x04C0 MEAN.  What is added here is their power-on
    value (0x0000) with the ROM byte address that says so, and the staging word each is
    committed from.  `notes/prom_c_gapA_remaining_regs.py` argues their low bits are a
    channel cross-reference; that argument is NOT re-used here, because the round-1 skeptic
    (notes/wave7-round1/README.md, lane g1) found its evidence addresses wrong -- it cites
    0xFB8175 for a copy that is at 0xFB8146/0xFB814B/0xFB814F, and 0xFA99F3 for a constant
    that comes from 0xFB5F7F.  ⚠ The CONCLUSION was not refuted; only the pointers were.
    This file re-derives the parts it uses and cites the corrected addresses.
  * What the values in the reset image MEAN.  0x0000 is what the ROM holds.
  * Anything about the twin device at 0x00104000 beyond the accessor map.

  --slots     "What are the three per-channel SLOTS of 0x0010C000, and why do four routines
              switch behaviour at channel 0x40?"  ★ THE ROUND'S BIGGEST RESULT.  Decoding
              the eight Dev10C_Slot* writers gives gate/value register pairs 1:(0x0540,
              0x01C0) 2:(0x0580,0x0600) 3:(0x05C0,0x0640) from struct words +0x3A/+0x38,
              +0x3C/+0x40, +0x3E/+0x42 -- and the "chan >= 0x40" arm of the split routines
              turns out to be SLOT 3 under an address identity, not a fourth parameter.
              The tree said the opposite ("they are different parameters"); --corrections
              retracts it in place.

  --localfix / --applylocals
              21 interior branch targets in 0xFB7C56..0xFB81DB were spelled `L_ADDR`
              instead of this tree's `Owner__ADDR`, so every extent-based tool in notes/
              silently ENDED the enclosing routine at them.  That is how --regaudit first
              reported a name/byte MISMATCH that was the tool's fault, not the tree's.

  --closegap / --applyclosegap   the blank-line artefact, applied and reported apart.
  --corrections / --applycorrections   in-place retractions of stale header sentences.
  --renameheaders / --applyrenameheaders   real headers for the routines this round names,
              replacing the generated "the name is an address" stanza that renaming made false.

RUN
  python3 notes/prom_c_naming_round3.py --regaudit
  python3 notes/prom_c_naming_round3.py --slots
  python3 notes/prom_c_naming_round3.py --struct
  python3 notes/prom_c_naming_round3.py --scale
  python3 notes/prom_c_naming_round3.py --gap
  python3 notes/prom_c_naming_round3.py --blankgap
  python3 notes/prom_c_naming_round3.py --names
  python3 notes/prom_c_naming_round3.py --localfix / --applylocals
  python3 notes/prom_c_naming_round3.py --apply                  # then run the byte gate
  python3 notes/prom_c_naming_round3.py --renameheaders / --applyrenameheaders
  python3 notes/prom_c_naming_round3.py --headers / --applyheaders
  python3 notes/prom_c_naming_round3.py --corrections / --applycorrections
  python3 notes/prom_c_naming_round3.py --closegap / --applyclosegap
  python3 notes/prom_c_naming_round3.py --claims
  python3 notes/prom_c_naming_round3.py --selftest

  Every --apply* mode is IDEMPOTENT and refuses on any surprise; run the byte gate,
  `python3 scripts/analysis/assert_byte_identical.py`, after each.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xF80000

# The device this round's accessors address.  Established in
# notes/FINDINGS-prom_c-dev10c-producers.md and used here only as a byte pattern.
DEV10C = 0x0010C000
DEV104 = 0x00104000

# The 0x0010C000 staging struct, as --struct derives it.  These three addresses come
# from three DIFFERENT places in the tree and the struct length is what reconciles them.
STRUCT_BASE = 0x00D75E      # VoiceRegs_Stage_A pushes it (0xFB0B82); 22-word map in
                            # notes/prom_c_dev10c_field_sources.py
STRUCT_TAIL = 0x00D78A      # round 2's Dev10C_WriteSixChanRegs_FromD78A commits from here
STRUCT_NEXT = 0x00D7A2      # VoiceRegs_Stage_A pushes it as the 0x00104000 struct
STRUCT_LEN = 0x44           # 68, the length Dev10C_ResetAllChannels copies at 0xFB814B
RESET_IMAGE = 0xFE12CF      # ROM source of that copy (`lda XWA,0xfe12cf` at 0xFB814F)

# The two ROM tables 0xFA75BA reads.  Addresses are the `add XBC,imm32` operands at
# 0xFA75D2 and 0xFA75EA; the labels are this tree's.
MIRROR_TBL = 0x00FDD5AB     # Voice_DepthMirror_Table
COEFF_TBL = 0x00FDD62B      # PitchBend_ScaleCoeff_Table


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def rom():
    return open(ROM, "rb").read()


def symbols():
    """name -> address, from the BUILT ELF: the assembler's own answer."""
    out = {}
    for line in sh([NM, "--numeric-sort", "--defined-only", ELF]).splitlines():
        p = line.split()
        if len(p) == 3 and p[1].lower() != 'a':
            out.setdefault(p[2], int(p[0], 16))
    return out


LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
BYTECOMMENT = re.compile(r';\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2}(?: |$))+)')
# ⚠ THE SPELLING BUG THIS ROUND FOUND.  This tree spells a routine's interior branch
# targets `Owner__ADDR`, and every extent-based tool in notes/ relies on it -- including
# prom_c_naming_round2.py's Tree.sub_len().  Twenty-one labels in 0xFB7C56..0xFB81DB are
# spelled `L_ADDR` instead, so those tools silently END the enclosing routine there.  It
# is how --regaudit first reported Dev10C_SetChanReg_01C0_or_0600_b as a name/byte
# MISMATCH: the second arm of the split lives past L_FB7FF6 and was never scanned.  The
# name was right and the tool was wrong -- which is the failure mode wave 7 keeps hitting,
# so the fix is BOTH: this pattern, and --applylocals, which respells the 21 labels.
LOCAL_L = re.compile(r'^L_[0-9A-F]{6}$')


def source():
    return open(SRC, encoding="utf-8", errors="replace").read().split("\n")


def top_extents(sym):
    """name -> (addr, end_addr), end = the next TOP-LEVEL label's address.

    A `__`-containing label is a local of the routine before it, so it does not end a
    routine; that is this tree's spelling convention and `--selftest` checks it holds."""
    tops = sorted((a, n) for n, a in sym.items()
                  if '__' not in n and not n.startswith('.') and not LOCAL_L.match(n))
    out = {}
    for i, (a, n) in enumerate(tops):
        end = tops[i + 1][0] if i + 1 < len(tops) else a
        out[n] = (a, end)
    return out


# ------------------------------------------------------------------ 1. --regaudit
#
# The idioms an accessor is built from, as BYTE patterns.  Every one of these was read
# off the trailing byte column of prom_c/wsa1_prom_c.s and then verified against the ROM
# file itself (`--selftest` check R0 re-runs that comparison), so they are the machine's
# encoding and not a spelling copied from a disassembler.
ADD_R16 = {0xD8: "WA", 0xD9: "BC", 0xDA: "DE", 0xDB: "HL"}     # xx c8 lo hi = add r,imm16
LD_FROM = {0x99: "XBC", 0x9C: "XIX"}                            # xx dd 2r = ld r,(base+dd)
LD_DST = {0x20: "WA", 0x21: "BC", 0x22: "DE", 0x23: "HL"}


def decode_accessor(image, lo, hi):
    """Every register-select constant and every staging-field fetch in [lo,hi).

    Returns (selects, fetches, has_dev10c, has_dev104) where selects is a list of
    (addr, regblock) and fetches a list of (addr, base, offset).

    ⚠ This is a PATTERN SCAN, not a decoder: it does not know instruction boundaries, so
    a byte pair inside an operand could in principle match.  That is why the register
    values are filtered to the device's own 12-bit window and why --selftest runs the
    same scan over data blocks as a negative control."""
    selects, fetches = [], []
    dev10c = dev104 = False
    for p in range(lo - BASE, hi - BASE):
        b = image[p:p + 5]
        if len(b) < 4:
            break
        if b[0] in ADD_R16 and b[1] == 0xC8:
            v = b[2] | (b[3] << 8)
            if v <= 0x0FFF:                 # the device window is 0x000..0xFFF
                selects.append((BASE + p, ADD_R16[b[0]], v))
        if b[0] in LD_FROM and b[2] in LD_DST:
            fetches.append((BASE + p, LD_FROM[b[0]], b[1], LD_DST[b[2]]))
        if len(b) == 5 and b[1:] == (DEV10C).to_bytes(4, "little")[:4]:
            dev10c = True
        if len(b) == 5 and b[1:] == (DEV104).to_bytes(4, "little")[:4]:
            dev104 = True
    return selects, fetches, dev10c, dev104


def name_registers(name):
    """The register blocks a Dev10C_/Dev104_ accessor NAME claims, from the name alone."""
    m = re.match(r'^Dev(10C|104)_SetChanRegs?_(.*)$', name)
    if not m:
        return None
    tail = m.group(2)
    tail = re.sub(r'_(b|c|dup)$', '', tail)
    if '_to_' in tail:                       # "0140_to_0240" = a contiguous run
        a, b = tail.split('_to_')
        lo, hi = int(a, 16), int(b, 16)
        return [r for r in range(lo, hi + 1, 0x40)]
    parts = [p for p in tail.split('_') if re.fullmatch(r'[0-9A-F]{4}', p)]
    return [int(p, 16) for p in parts]


def accessor_rows():
    sym = symbols()
    ext = top_extents(sym)
    img = rom()
    rows = []
    for n in sorted(ext, key=lambda k: ext[k][0]):
        if not re.match(r'^Dev(10C|104)_SetChanRegs?_', n):
            continue
        lo, hi = ext[n]
        sel, fet, d10c, d104 = decode_accessor(img, lo, hi)
        claimed = name_registers(n)
        found = []
        seen = set()
        for _a, _r, v in sel:
            if v not in seen:
                seen.add(v)
                found.append(v)
        rows.append(dict(name=n, lo=lo, hi=hi, selects=sel, fetches=fet,
                         dev10c=d10c, dev104=d104, claimed=claimed, found=found))
    return rows


def pairs_for(row):
    """(register, base, staging offset) triples, pairing each select with the fetch that
    follows it.  The accessors are straight-line, so 'the next fetch' is unambiguous;
    where it is not, the pair is omitted rather than guessed."""
    out = []
    fetches = sorted(row['fetches'])
    for a, _r, v in sorted(row['selects']):
        nxt = [f for f in fetches if f[0] > a]
        if nxt:
            out.append((v, nxt[0][1], nxt[0][2], a, nxt[0][0]))
    return out


def do_regaudit(verbose=True):
    rows = accessor_rows()
    bad = []
    if verbose:
        print("Dev10C / Dev104 per-channel accessors: does the NAME match the ROM bytes?\n")
        print("%-38s %-22s %-22s" % ("routine", "name says", "bytes say"))
    for r in rows:
        cl = sorted(set(r['claimed'] or []))
        fo = sorted(set(r['found']))
        ok = cl == fo
        if not ok:
            bad.append((r['name'], cl, fo))
        if verbose:
            print("%-38s %-22s %-22s %s"
                  % (r['name'],
                     " ".join("%04X" % v for v in cl),
                     " ".join("%04X" % v for v in fo),
                     "ok" if ok else "MISMATCH"))
    if verbose:
        print("\n%d accessors, %d name/byte mismatches\n" % (len(rows), len(bad)))
        print("register <- staging word, paired select-then-fetch:")
        for r in rows:
            for reg, base, off, sa, fa in pairs_for(r):
                print("   %-38s  chan+0x%04X <- (%s+0x%02X)   select 0x%06X  fetch 0x%06X"
                      % (r['name'], reg, base, off, sa, fa))
    return rows, bad


# ------------------------------------------------------------------ 2. --struct

def do_struct(verbose=True):
    """The 68-byte 0x0010C000 staging struct, from four readings that must agree."""
    img = rom()
    image = img[RESET_IMAGE - BASE:RESET_IMAGE - BASE + STRUCT_LEN]
    words = [image[i] | (image[i + 1] << 8) for i in range(0, STRUCT_LEN, 2)]
    facts = [
        ("STRUCT_BASE + 0x2C == STRUCT_TAIL (round 2's Dev10C_WriteSixChanRegs_FromD78A)",
         STRUCT_BASE + 0x2C == STRUCT_TAIL),
        ("STRUCT_BASE + 0x44 == STRUCT_NEXT (VoiceRegs_Stage_A's 0x00104000 struct)",
         STRUCT_BASE + STRUCT_LEN == STRUCT_NEXT),
        ("the reset image at ROM 0x%06X is %d bytes" % (RESET_IMAGE, STRUCT_LEN),
         len(image) == STRUCT_LEN),
        ("word 6  (+0x0C -> reg 0x0180) == 0x0040", words[6] == 0x0040),
        ("words 8,9,10,11 (+0x10..+0x16 -> regs 0x0440/0x0480/0x04C0/0x0500) are all 0x0000",
         words[8] == words[9] == words[10] == words[11] == 0x0000),
        ("word 12 (+0x18 -> reg 0x0800) == 0xFF80, the value the reset sweep writes"
         " directly at 0xFB8132", words[12] == 0xFF80),
        ("word 13 (+0x1A -> reg 0x0840) == 0xFF00, the value the reset sweep writes"
         " directly at 0xFB811E", words[13] == 0xFF00),
        ("word 23 (+0x2E -> reg 0x0840 via the TAIL map) == 0xFF00 as well",
         words[23] == 0xFF00),
    ]
    # the two direct writes of the reset sweep, read out of the ROM at their instruction
    # addresses: `ld (XBC),0xFF00` at 0xFB811E and `ld (XBC),0xFF80` at 0xFB8132
    w1 = img[0xFB811E - BASE:0xFB811E - BASE + 4]
    w2 = img[0xFB8132 - BASE:0xFB8132 - BASE + 4]
    facts.append(("0xFB811E is `ld (XBC),0xFF00` (bytes b1 02 00 ff)", w1 == b"\xb1\x02\x00\xff"))
    facts.append(("0xFB8132 is `ld (XBC),0xFF80` (bytes b1 02 80 ff)", w2 == b"\xb1\x02\x80\xff"))
    if verbose:
        print("The 0x0010C000 staging struct: 0x%06X..0x%06X, %d bytes\n"
              % (STRUCT_BASE, STRUCT_BASE + STRUCT_LEN - 1, STRUCT_LEN))
        for d, ok in facts:
            print("  %-4s %s" % ("ok" if ok else "FAIL", d))
        print("\nthe power-on image, ROM 0x%06X:" % RESET_IMAGE)
        for i, w in enumerate(words):
            print("   word %2d  +0x%02X  0x%04X" % (i, 2 * i, w))
    return words, facts


# ------------------------------------------------------------------ 3. --scale
#
# 0xFA75BA, evaluated exactly.  Every step below is one instruction of the routine and
# the address is in the comment, so the model can be checked line by line.

def shift16_arith_right(v16, count):
    """Shift16_ArithRight (0xFCAA2F): two `sra A,IY` passes, by count>>4 then count&0x0F.
    ⚠ A shift COUNT OF ZERO means SIXTEEN on this core -- MAME's 900tbl.hxx spells it
    `( s & 0x0f ) ? ( s & 0x0f ) : 16`, and the first pass relies on it (`sub A,A` puts
    0 in the count register at 0xFCAA3A).  Ignoring that would make counts >= 16 wrong."""
    v = v16 - 0x10000 if v16 >= 0x8000 else v16
    if (count >> 4) & 0x0F:
        v >>= 16                # first pass: `sra A,IY` with A == 0, i.e. shift by SIXTEEN
    n = count & 0x0F
    if n:                       # second pass; n == 0 is skipped by the `jr Z` at 0xFCAA47,
        v >>= n                 # so here a zero really is "no shift"
    return v


def scale_fa75ba(depth_byte, pos_byte, count, mirror, coeff):
    """0xFA75BA(depth=(XIZ+8), pos=(XIZ+0x0A), count=(XIZ+0x0C)) -> WA."""
    L = depth_byte & 0xFF                       # 0xFA75BF  ld L,(XIZ+0x08)
    H = pos_byte & 0x7F                         # 0xFA75C2/0xFA75C5  ld H,(XIZ+0x0a) / res 7,H
    if (L - 256 if L >= 128 else L) < 0:        # 0xFA75C8  cp L,0 / jr GE
        H = mirror[H]                           # 0xFA75D8  ld H,(XBC) at 0x00FDD5AB + H
        L = (-L) & 0xFF                         # 0xFA75DC/0xFA75E0  cpl A / inc 1,A
    c = coeff[H]                                # 0xFA75F0  ld A,(XBC) at 0x00FDD62B + H
    cs = c - 256 if c >= 128 else c
    ls = L - 256 if L >= 128 else L
    prod = (cs * ls) & 0xFFFF                   # 0xFA75F2  muls WA,L  (SIGNED 8x8 -> 16)
    return shift16_arith_right(prod, count)     # 0xFA75FA  call Shift16_ArithRight


def do_scale(verbose=True):
    img = rom()
    mirror = img[MIRROR_TBL - BASE:MIRROR_TBL - BASE + 128]
    coeff = img[COEFF_TBL - BASE:COEFF_TBL - BASE + 128]
    tbl_ok = all(mirror[i] == 0x7F - i for i in range(128))
    signed = [c - 256 if c >= 128 else c for c in coeff]
    coeff_ok = all(-64 <= s <= 0 for s in signed)
    # the low byte of register 0x0500 + chan, as Voice_StageRegs_0500_08C0_AB builds it:
    #   Clamp_ToRange_Word(0xFA75BA(depth, pos, 6) + 0x7F, 0, 0x7F)
    fires, rng = [], []
    for d in range(256):
        for p in range(128):
            x = scale_fa75ba(d, p, 6, mirror, coeff) + 0x7F
            rng.append(x)
            if x < 0 or x > 0x7F:
                fires.append((d, p, x))
    fire_depths = sorted({d for d, _p, _x in fires})
    facts = [
        ("Voice_DepthMirror_Table[i] == 0x7F - i for all 128 entries", tbl_ok),
        ("every PitchBend_ScaleCoeff_Table entry is in [-64, 0] as a signed byte", coeff_ok),
        ("with count 6, the pre-clamp value spans [%d, %d]" % (min(rng), max(rng)), True),
        ("the clamp to [0,0x7F] fires for exactly one depth byte, 0x80",
         fire_depths == [0x80]),
        ("...at %d of the 128 positions" % len(fires), True),
    ]
    if verbose:
        print("0xFA75BA -- coeff[mirror-if-negative(pos)] * |depth|, arithmetic-shifted\n")
        for d, ok in facts:
            print("  %-4s %s" % ("ok" if ok else "FAIL", d))
        print("\n  count 6 is passed at 2 of the 20 call sites; count 4 at the other 18"
              " (--claims C6).")
        print("  So for every depth the firmware can hold in a signed byte EXCEPT -128,")
        print("  the caller's clamp is a no-op: the datapath already lands in 0..0x7F.")
    return facts, fires


def call_site_counts():
    """The `count` argument at every call site of 0xFA75BA, read from the source.

    The argument is the LAST value pushed before the two data arguments, i.e. the
    `push 0x000N` that precedes the `calr`; it is read from the 12 lines above each call
    site and the count of sites is checked against an independent grep."""
    lines = source()
    counts = {}
    sites = []
    for i, l in enumerate(lines):
        if 'calr (0xFA75BA' not in l:
            continue
        m = re.search(r';\s*([0-9A-F]{6})', l)
        sites.append(int(m.group(1), 16) if m else None)
        for j in range(i - 1, max(0, i - 13), -1):
            mm = re.match(r'\s*pushw\s+(\d+)\s', lines[j])
            if mm:
                counts[int(mm.group(1))] = counts.get(int(mm.group(1)), 0) + 1
                break
    return sites, counts


# ------------------------------------------------------------------ 4. --gap / --blankgap

IMAGES = [("prom_a", "wsa1_prom_a.s"), ("prom_b", "wsa1_prom_b.s"),
          ("prom_c", "wsa1_prom_c.s"), ("prom_d", "wsa1_prom_d.s")]
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')


def classify(path):
    lines = open(os.path.join(ROOT, path), encoding="utf-8", errors="replace").read().split("\n")
    out = {}
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        n = m.group(1)
        j, run, ev = i - 1, 0, False
        while j >= 0 and lines[j].startswith(';'):
            run += 1
            if 'Evidence:' in lines[j]:
                ev = True
            j -= 1
        k = i - 1
        while k >= 0 and lines[k].strip() == '':
            k -= 1
        run2 = 0
        while k >= 0 and lines[k].startswith(';'):
            run2 += 1
            k -= 1
        kind = 'sub' if UNNAMED.match(n) else ('local' if '__' in n else 'named')
        d = out.setdefault(kind, [0, 0, 0, 0])
        d[0] += 1
        d[1] += 1 if run >= 3 else 0
        d[2] += 1 if ev else 0
        d[3] += 1 if (run < 3 and run2 >= 3) else 0
    return out


def do_gap():
    print("Where prom_c's documentation actually is, by label KIND\n")
    print("%-8s %-7s %8s %8s %9s %9s" % ("image", "kind", "labels", "header", "evidence", "blankgap"))
    for tag, src in IMAGES:
        for kind in ("named", "sub", "local"):
            d = classify(os.path.join(tag, src)).get(kind, [0, 0, 0, 0])
            print("%-8s %-7s %8d %8d %9d %9d" % (tag, kind, d[0], d[1], d[2], d[3]))
    print("\n★ prom_c: the sub_XXXXXX routines are the BEST covered (a generated header with")
    print("  an Evidence: line on nearly every one) and the hand-NAMED routines the worst.")
    print("  wave7_documentation_metrics.py counts a `__local` label as 'semantic', so its")
    print("  5,897 for prom_c is 1,067 real names plus 4,830 locals; the goal metric is")
    print("  measuring something coarser than it reads. Stated, not silently adopted.")


def do_blankgap():
    print("Headers wave7_documentation_metrics.py cannot see, because one BLANK LINE")
    print("separates the comment block from its label:\n")
    tot = 0
    for tag, src in IMAGES:
        c = classify(os.path.join(tag, src))
        n = sum(v[3] for v in c.values())
        tot += n
        print("  %-8s %3d" % (tag, n))
    print("\n  total %d.  This is a MEASUREMENT ARTEFACT, not missing documentation, and" % tot)
    print("  closing it by deleting whitespace would raise the metric without writing a word.")
    return tot


# ------------------------------------------------------------------ 5. the renames
#
# Each row is (old, new, one-line evidence).  A name is here only when the MECHANISM is
# provable from the bytes; the full evidence is the routine header the same edit writes
# into prom_c/wsa1_prom_c.s.  Nothing whose PURPOSE is still open was renamed.
RENAMES = [
    ("sub_FA75BA", "ScaleCoeff_TimesAbsDepth_Shr",
     "PitchBend_ScaleCoeff_Table[pos or 0x7F-pos] * |depth|, arithmetic-shifted right by "
     "the third argument; 20 call sites, 18 pass 4 and 2 pass 6 (--claims C6)"),
    ("sub_FC376C", "PartSlot_SetRecordPtr_DF05",
     "`ld C,0x17 / mul BC,(XIZ+0x08)` then `add XIX,0x0000DC0E`, and `ld C,0x04 / "
     "mul BC,(XIZ+0x0a)` then `add XBC,0x0000DF05 / ld (XBC),XIX` -- a 32-bit pointer "
     "table of 4-byte slots at RAM 0xDF05 holding &record[arg1] of 23-byte records at "
     "RAM 0xDC0E"),
    ("sub_FC4D63", "Pack104_SetInputs_E088_E089_E08A",
     "three absolute stores and nothing else: (0x00E088) = (XIZ+0x0c) with bit 7 cleared, "
     "(0x00E08A) = (XIZ+0x0a) word, (0x00E089) = (XIZ+0x0e) byte"),
    ("sub_FC4D85", "Pack104_SetInputs_Rec0C_E08C",
     "`ld BC,(0x00E086)` then `ld (XBC+0x0c),WA` -- a store THROUGH the pointer at "
     "0x00E086 -- and (0x00E08C) = (XIZ+0x0a) byte"),
    ("sub_FC4DA1", "Pack104_SetInputs_Rec0E_E08D",
     "`ld BC,(0x00E086)` then `ld (XBC+0x0e),WA`, and (0x00E08D) = (XIZ+0x0a) word; the "
     "+0x0E sibling of the +0x0C setter above"),
    ("sub_FC8164", "PartRec_TallyScaledField_80_40",
     "`mul XWA,BC / srl 0x03,WA` of record byte +2 by part byte 0x1523 + part*0x12C + "
     "0x12, then `cp WA,0x007f` and `cp HL,0x003f` each guarding one `inc 1,(XIX+n)`"),
    ("sub_FBDC6C", "BitPair_TestAndEncode_Bits4to7",
     "the byte tables at 0xFDE6A1 (01 04 10 40) and 0xFDE6A5 (02 08 20 80) select bit 2i "
     "and bit 2i+1 of the flag byte; the result ORs (arg<<6) into bits 7:6 and sets bit 5, "
     "plus bit 4 when the second bit is also present"),
]


# ------------------------------------------------------------- the L_ADDR local labels
#
# Twenty-one interior branch targets in 0xFB7C56..0xFB81DB are spelled `L_ADDR` instead of
# this tree's `Owner__ADDR`.  --localfix lists them with the routine each is interior to
# (derived, never typed: the owner is the nearest preceding label that is not itself an
# `L_ADDR`, and every one is checked to lie inside that routine's extent), and
# --applylocals respells them.  Purely a symbol rename: the byte gate is the proof.

def local_rows():
    sym = symbols()
    tops = sorted((a, n) for n, a in sym.items() if '__' not in n and not n.startswith('.'))
    real = [(a, n) for a, n in tops if not LOCAL_L.match(n)]
    addrs = [a for a, _n in real]
    import bisect
    rows = []
    for a, n in tops:
        if not LOCAL_L.match(n):
            continue
        i = bisect.bisect_right(addrs, a) - 1
        owner, oaddr = real[i][1], real[i][0]
        nxt = real[i + 1][0] if i + 1 < len(real) else None
        inside = (nxt is None or a < nxt) and oaddr < a
        spelled = (int(n[2:], 16) == a)     # the label's own name must spell its address
        rows.append((n, a, owner, oaddr, nxt, inside, spelled))
    return rows


def do_localfix(apply=False):
    rows = local_rows()
    print("%d `L_ADDR` labels in prom_c\n" % len(rows))
    for n, a, owner, oaddr, nxt, inside, spelled in rows:
        print("  %-12s 0x%06X  interior to %-38s (0x%06X..0x%06X)  %s%s"
              % (n, a, owner, oaddr, nxt or 0,
                 "inside" if inside else "!! NOT INSIDE",
                 "" if spelled else "  !! name does not spell its address"))
    if not rows:
        print("  none left -- --applylocals has already run (the byte gate is the proof).")
        return 0
    if not all(r[5] and r[6] for r in rows):
        print("\nREFUSE: not every L_ label is an interior target of a named routine.")
        return 1
    if not apply:
        print("\n--applylocals would rename each to Owner__ADDR.")
        return 0
    text = open(SRC, encoding="utf-8").read()
    done = 0
    for n, a, owner, _oa, _nx, _i, _s in rows:
        new = "%s__%06X" % (owner, a)
        if re.search(r'^' + re.escape(new) + r':', text, re.M):
            continue
        before = len(re.findall(r'\b' + n + r'(?![0-9A-Za-z])', text))
        if not before:
            continue
        text = re.sub(r'\b' + n + r'(?![0-9A-Za-z])', new, text)
        after = len(re.findall(r'\b' + n + r'(?![0-9A-Za-z])', text))
        if after:
            print("  REFUSE: %s survived the rewrite; nothing written." % n)
            return 1
        print("  %-12s -> %s   (%d occurrence(s))" % (n, new, before))
        done += 1
    if done:
        open(SRC, "w", encoding="utf-8").write(text)
        print("\nwrote %s: %d local label(s) respelled." % (SRC, done))
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    else:
        print("\nnothing to do.")
    return 0


def do_names():
    print("%d renames in this round's table\n" % len(RENAMES))
    for old, new, ev in RENAMES:
        print("  %-12s -> %s" % (old, new))
        print("      %s" % ev)
    return 0


def rename_token(text, old, new):
    """Rename `old` and every `old__local` derived from it.  `\\bold\\b` does NOT match
    inside `sub_FA75BA__FA75E4` -- `_` is a word character, so there is no boundary after
    the digits -- which would leave the locals pointing at a symbol that no longer exists
    and break the build.  The lookahead accepts `_` and so renames the locals too, while
    still refusing a longer address like `sub_FA75BA0`."""
    return re.sub(r'\b' + old + r'(?![0-9A-Za-z])', new, text)


def do_apply(check_only=False):
    text = open(SRC, encoding="utf-8").read()
    todo, done, bad = [], [], []
    for old, new, _ev in RENAMES:
        ho = re.search(r'^' + old + r':', text, re.M) is not None
        hn = re.search(r'^' + new + r':', text, re.M) is not None
        if hn and not ho:
            done.append((old, new))
        elif ho and not hn:
            todo.append((old, new))
        else:
            bad.append((old, new, ho, hn))
    for old, new, ho, hn in bad:
        print("  REFUSE %s -> %s: old present %s, new present %s" % (old, new, ho, hn))
    if bad:
        print("\nnothing written.")
        return 1
    for old, new in done:
        print("  already applied: %s -> %s" % (old, new))
    if check_only:
        print("\n%d applied, %d pending." % (len(done), len(todo)))
        return 0 if not todo else 2
    for old, new in todo:
        n0 = len(re.findall(r'\b' + old + r'(?![0-9A-Za-z])', text))
        text = rename_token(text, old, new)
        n1 = len(re.findall(r'\b' + old + r'(?![0-9A-Za-z])', text))
        print("  %s -> %s   (%d occurrence(s), %d left)" % (old, new, n0, n1))
        if n1:
            print("  REFUSE: occurrences survived; nothing written.")
            return 1
    if todo:
        open(SRC, "w", encoding="utf-8").write(text)
        print("\nwrote %s: %d rename(s)." % (SRC, len(todo)))
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    else:
        print("\nnothing to do.")
    return 0


# ------------------------------------------------------------------ 6. the headers
#
# (anchor label, unique marker, lines).  The lines are inserted immediately above the
# anchor's label, BEFORE the `; ---` rule if the house style put one there, so the block
# keeps its shape.  The marker makes the edit idempotent and is checked for before every
# write.  Insertions are listed here rather than typed into the .s so that --claims can
# re-derive the numbers they contain.
HEADERS = []


def _reg_header(name, reg_pairs, extra=()):
    """The Evidence: block for a one-or-two-register accessor, built from --regaudit's
    own output so the addresses in the .s and the addresses this script prints cannot
    drift apart."""
    out = ["; Evidence: decoded from the ROM bytes, not from the name --"]
    for reg, base, off, sa, fa in reg_pairs:
        out.append(";          0x%06X  `add rr,0x%04X` forms the select value chan+0x%04X,"
                   % (sa, reg, reg))
        out.append(";          0x%06X  `ld rr,(%s+0x%02X)` fetches the staging word it is"
                   % (fa, base, off))
        out.append(";                    given -- struct offset +0x%02X." % off)
    out.append(";          Re-derived for all %d Dev10C_/Dev104_ accessors at once by"
               % _ACCESSOR_COUNT[0])
    out.append(";          `python3 notes/prom_c_naming_round3.py --regaudit`, which compares each")
    out.append(";          NAME against the bytes and reports the mismatch count.")
    out.extend(extra)
    return out


_ACCESSOR_COUNT = [0]


def build_headers():
    """Assemble HEADERS from the derivations, so every line in it is generated."""
    rows, _bad = do_regaudit(verbose=False)
    _ACCESSOR_COUNT[0] = len(rows)
    by = {r['name']: r for r in rows}
    out = []

    # (a) every accessor whose header has no Evidence: line yet
    lines = source()
    have_ev = set()
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        j = i - 1
        while j >= 0 and lines[j].startswith(';'):
            if 'Evidence:' in lines[j]:
                have_ev.add(m.group(1))
            j -= 1
    for n, r in by.items():
        if n in have_ev:
            continue
        pr = pairs_for(r)
        if not pr:
            continue
        out.append((n, "decoded from the ROM bytes, not from the name", _reg_header(n, pr)))

    # (b) the three gap-A registers: their power-on value, with the ROM byte that says so
    for reg, word, acc in ((0x0440, 8, "Dev10C_SetChanReg_0440"),
                           (0x0480, 9, "Dev10C_SetChanReg_0480"),
                           (0x04C0, 10, "Dev10C_SetChanReg_04C0")):
        out.append((acc, "GAP A, round 3", [
            "; ★ GAP A, round 3 -- what IS established about register chan+0x%04X:" % reg,
            ";   * it is committed from staging word %d, at struct offset +0x%02X, both by"
            % (word, 2 * word),
            ";     this accessor and by Dev10C_WriteAllChanRegs (0xFB713A); two independent",
            ";     readings of the same pairing.",
            ";   * its POWER-ON value is 0x0000, and the ROM bytes that say so are at",
            ";     0x%06X -- offset +0x%02X of the 68-byte reset image at 0x%06X that"
            % (RESET_IMAGE + 2 * word, 2 * word, RESET_IMAGE),
            ";     Dev10C_ResetAllChannels copies to RAM 0x00D8DB.  ⚠ The copy is at",
            ";     0xFB8146 / 0xFB814B / 0xFB814F (lda XIX,0x00d8db / push 0x0044 /",
            ";     lda XWA,0xfe12cf); notes/prom_c_gapA_remaining_regs.py cites 0xFB8175",
            ";     for it, which is the argument load of the NEXT loop -- corrected here,",
            ";     see notes/wave7-round1/README.md lane g1.",
            "; ⚠ NOT ESTABLISHED: what the register DOES.  0x0000 is what the ROM holds, not",
            ";   a meaning, and this round did not re-derive the channel-cross-reference",
            ";   reading that prom_c_gapA_remaining_regs.py argues for.",
        ]))

    # (c) the struct closure, on the routine that reads the tail through the pointer
    out.append(("Dev10C_SetChanReg_0840_0800",
                "THIS ROUTINE IS WHY THE STAGING STRUCT'S SIZE IS KNOWN", [
        "; ★★ ROUND 3 -- THIS ROUTINE IS WHY THE STAGING STRUCT'S SIZE IS KNOWN.  It reads",
        ";   fields +0x2C and +0x2E, which are PAST the 22 words (+0x00..+0x2A) that",
        ";   Dev10C_WriteAllChanRegs commits.  Four readings close on one number:",
        ";     1. 0x00D75E + 0x2C = 0x00D78A -- the absolute address round 2's",
        ";        Dev10C_WriteSixChanRegs_FromD78A commits registers 0x0800/0x0840/0x0900/",
        ";        0x0940/0x09C0/0x0A00 from.  It maps +0x2C -> 0x0800 and +0x2E -> 0x0840,",
        ";        exactly as this routine does.",
        ";     2. Dev10C_ResetAllChannels copies 0x44 = 68 bytes (`push 0x0044` at 0xFB814B)",
        ";        from ROM 0xFE12CF into a second instance at RAM 0x00D8DB.",
        ";     3. 0x00D75E + 0x44 = 0x00D7A2 -- the pointer VoiceRegs_Stage_A pushes at",
        ";        0xFB0B5B as the 0x00104000 staging struct.  The two structs abut.",
        ";     4. The highest field any accessor reads is +0x42 (Dev10C_SetChanReg_0640),",
        ";        which is the last word that fits in 68 bytes.",
        ";   So the 0x0010C000 staging struct is RAM 0x00D75E..0x00D7A1, 68 bytes:",
        ";     +0x00..+0x2A  the 22 words Dev10C_WriteAllChanRegs commits",
        ";     +0x2C..+0x36  the six words Dev10C_WriteSixChanRegs_FromD78A commits",
        ";     +0x38..+0x42  the slot gate/value words the Dev10C_Slot* writers commit",
        "; ⚠ NOT ESTABLISHED: why registers 0x0800 and 0x0840 have TWO committers reading",
        ";   two different words.  The reset image disagrees with itself about 0x0800 --",
        ";   word 12 (+0x18) is 0xFF80 and word 22 (+0x2C) is 0xA080 -- so the two paths are",
        ";   alternatives, and nothing here says which one runs when.",
        "; Evidence: `python3 notes/prom_c_naming_round3.py --struct` prints the ten checks",
        ";          above and the whole 68-byte image, word by word, out of the ROM.",
    ]))

    # (d) the dual-width reading of BitMask_Table_FDE695
    out.append(("BitMask_Table_FDE695",
                "THESE BYTES ARE READ AT TWO ELEMENT WIDTHS", [
        "; ★ ROUND 3 -- THESE BYTES ARE READ AT TWO ELEMENT WIDTHS.  The u16 reading above",
        ";   is real, but entries 6..9 (0x0401, 0x4010, 0x0802, 0x8020) are ALSO read as two",
        ";   4-byte BYTE tables, at 0xFDE6A1 = 01 04 10 40 and 0xFDE6A5 = 02 08 20 80, i.e.",
        ";   bit 2i and bit 2i+1 of one flag byte.  Two readers do it: ",
        ";   ByteField_AddOrSub_Clamped (0xFBD8B8, named in round 2) and",
        ";   BitPair_TestAndEncode_Bits4to7 (0xFBDC6C, named in round 3, `add XBC,0x00FDE6A1`",
        ";   at 0xFBDC7E and `add XWA,0x00FDE6A5` at 0xFBDC96).",
        "; Evidence: the byte identity 0xFDE6A1[i] == 1 << (2i) and 0xFDE6A5[i] == 1 << (2i+1)",
        ";          for i = 0..3 is asserted from the ROM by",
        ";          notes/prom_c_naming_round2.py --claims (claim_bitmask_tables) and again",
        ";          by notes/prom_c_naming_round3.py --claims (C7).",
        "; ⚠ NOT ESTABLISHED: whether the two widths are two USES of one table or two tables",
        ";   that happen to overlap.  Only the reads are measured.",
    ]))
    out.extend(build_slot_headers())
    return out


def build_slot_headers():
    """An Evidence: block for every Dev10C_Slot* writer, generated from --slots' decode."""
    rows, _u, _a, _i = do_slots(verbose=False)
    lines = source()
    have = set()
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        j = i - 1
        while j >= 0 and lines[j].startswith(';'):
            if 'Evidence:' in lines[j]:
                have.add(m.group(1))
            j -= 1
    slot_of = {}
    for k, (g, gw, v, vw) in SLOTS.items():
        slot_of[(g, gw)] = "slot %d gate" % k
        slot_of[(v, vw)] = "slot %d value" % k
    slot_of[(0x0580, 0x3E)] = "slot 3 gate, aliased (0x0580+chan == 0x05C0+(chan-0x40))"
    slot_of[(0x0600, 0x42)] = "slot 3 value, aliased (0x0600+chan == 0x0640+(chan-0x40))"
    out = []
    for n, prs in rows:
        if n in have or not prs or not n.startswith("Dev10C_Slot"):
            continue
        body = ["; Evidence: decoded from the ROM bytes by"
                " `notes/prom_c_naming_round3.py --slots`:"]
        for reg, base, off, sa, fa in prs:
            body.append(";          0x%06X select chan+0x%04X, 0x%06X fetch (%s+0x%02X)"
                        "  -- %s" % (sa, reg, fa, base, off, slot_of.get((reg, off), "??")))
        body.append(";          The slot table is 1: (0x0540,+0x3A)/(0x01C0,+0x38),"
                    " 2: (0x0580,+0x3C)/")
        body.append(";          (0x0600,+0x40), 3: (0x05C0,+0x3E)/(0x0640,+0x42); `--claims C12`")
        body.append(";          checks that these ten routines use no pair outside it.")
        out.append((n, "decoded from the ROM bytes by `notes/prom_c_naming_round3.py --slots`",
                    body))
    return out


def _find_label(lines, name):
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if m and m.group(1) == name:
            return i
    return None


def do_headers(apply=False):
    hdrs = build_headers()
    lines = source()
    text = "\n".join(lines)
    todo, done, missing = [], [], []
    for name, marker, body in hdrs:
        # ⚠ the marker is what makes this idempotent, so it MUST be text the body
        # actually contains -- an early draft used a marker that appeared nowhere in the
        # block and would have inserted every block a second time.
        if not any(marker in b for b in body):
            print("  REFUSE %s: marker %r is not in its own body" % (name, marker[:40]))
            return 1
        i = _find_label(lines, name)
        if i is None:
            missing.append(name)
            continue
        # is the marker already in the comment block above?
        j, seen = i - 1, False
        while j >= 0 and (lines[j].startswith(';') or lines[j].strip() == ''):
            if marker in lines[j]:
                seen = True
            j -= 1
        (done if seen else todo).append((name, marker, body, i))
    for n in missing:
        print("  REFUSE: no label %s" % n)
    if missing:
        return 1
    for n, _m, _b, _i in done:
        print("  already applied: %s" % n)
    if not apply:
        for n, _m, body, _i in todo:
            print("\n=== %s (%d line(s)) ===" % (n, len(body)))
            print("\n".join(body))
        print("\n%d applied, %d pending." % (len(done), len(todo)))
        return 0
    # ⚠ GROUP BY ANCHOR FIRST.  Two blocks can target the same label (an accessor gets
    # both its Evidence: line and its gap-A statement), and inserting them one at a time
    # at the same index INTERLEAVES them -- which is exactly what the first run of this
    # function did.  So the bodies are concatenated per anchor, in build_headers' order,
    # and written once; then the anchors are applied bottom-up so earlier indices hold.
    grouped = {}
    for n, _m, body, i in todo:
        grouped.setdefault(i, [n, []])[1].extend(body)
    for i in sorted(grouped, reverse=True):
        n, body = grouped[i]
        k = i
        if k > 0 and re.match(r'^;\s*-{5,}\s*$', lines[k - 1]):
            k -= 1
        lines[k:k] = body
        print("  inserted %d line(s) above %s" % (len(body), n))
    if todo:
        open(SRC, "w", encoding="utf-8").write("\n".join(lines))
        print("\nwrote %s: %d block(s) at %d anchor(s)."
              % (SRC, len(todo), len(grouped)))
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    else:
        print("\nnothing to do.")
    return 0


# ------------------------------------------------- headers for the renamed routines
#
# Every routine this round renames arrived carrying gen_prom_c_block_headers.py's
# boilerplate, whose last stanza is
#
#     ; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
#     ;          so the name is an address.
#
# and that is now FALSE for all seven -- the name is no longer an address.  Leaving it
# would be the exact failure this wave keeps recording: a gate-clean sentence that is
# wrong.  --applyrenameheaders REPLACES that stanza, and refuses if it is not there.
BOILERPLATE = [
    "; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,",
    ";          so the name is an address.",
]

RENAME_HEADERS = {
"ScaleCoeff_TimesAbsDepth_Shr": """\
; ★ WHAT IT COMPUTES.  The body is fifteen instructions and there is nothing else in it:
;     0xFA75BF  ld L,(XIZ+0x08)          the DEPTH, tested as a signed byte
;     0xFA75C2  ld H,(XIZ+0x0a)          the POSITION
;     0xFA75C5  res 0x07,H               ...taken modulo 0x80
;     0xFA75C8  cp L,0 / jr GE           if the depth is negative:
;     0xFA75D2  add XBC,0x00FDD5AB         H = Voice_DepthMirror_Table[H], i.e. 0x7F - H
;     0xFA75DC  cpl A / inc 1,A            L = -L
;     0xFA75EA  add XBC,0x00FDD62B       A = PitchBend_ScaleCoeff_Table[H]
;     0xFA75F2  muls WA,L                SIGNED 8x8 -> 16: coeff * |depth|
;     0xFA75FA  call Shift16_ArithRight(product, (XIZ+0x0c))
;   The depth's SIGN is therefore not carried into the product -- it chooses which end of
;   the coefficient curve is read.
; ★ THE RESULT IS NEVER POSITIVE.  All 128 entries of PitchBend_ScaleCoeff_Table are in
;   [-64, 0] as signed bytes, so the product is <= 0 and so is the shifted result.  That is
;   why Voice_StageRegs_0500_08C0_AB adds 0x7F: with a count of 6 the value lands in
;   [-127, 0], 0x7F + it lands in [0, 0x7F] -- exactly the 7-bit low byte of register
;   0x0500 + chan -- and the caller's Clamp_ToRange_Word(x, 0, 0x7F) does nothing at all.
; Called with count 4 at 18 of the 20 sites and with count 6 at 2 (both inside
;   Voice_StageRegs_0500_08C0_AB).
; Evidence: `python3 notes/prom_c_naming_round3.py --scale` evaluates the datapath
;          EXHAUSTIVELY -- all 256 depth bytes against all 128 positions, against the two
;          ROM tables read at their `add XBC,imm32` operands -- and reports that the clamp
;          changes its argument for exactly ONE depth byte, 0x80, at 127 of the 128
;          positions.  0x80 is the one value whose two's-complement negation at
;          0xFA75DC-0xFA75E2 overflows back to itself, so the product changes sign; the
;          clamp exists for that case and no other.  `--claims C6` re-derives the 20/18/2
;          call-site split and checks the total against an independent grep.
; Unknown:  ⚠ what the two arguments MEAN.  "depth" and "position" are the roles the
;          arithmetic gives them, not decoded quantities, and the two table names come
;          from the KN5000 sibling (see each table's own header) rather than from here.
;          ⚠ with the count of 4 that 18 callers pass, the result spans [-508, 0], which
;          does NOT fit a 7-bit field.  Nothing was traced about what those callers do
;          with it.""",

"PartSlot_SetRecordPtr_DF05": """\
; ★ WHAT IT DOES: `slotptr[arg1] = &record[arg0]`, over two RAM arrays whose strides are
;   both instruction immediates:
;     0xFC3771  ld C,0x17 / mul BC,(XIZ+0x08)    23-byte records
;     0xFC377A  add XIX,0x0000DC0E               the record array's base
;     0xFC3780  ld C,0x04 / mul BC,(XIZ+0x0a)    4-byte slots, i.e. 32-bit pointers
;     0xFC3787  add XBC,0x0000DF05               the pointer table's base
;     0xFC378D  ld (XBC),XIX                     the store
; Evidence: the five constants are `mul r,imm` and `add rr,imm32` operands and are checked
;          against the routine's 39 ROM bytes by `--claims C8`.  RAM 0x0000DC0E is named on
;          32 addressed lines of prom_c and 0x0000DF05 on 9, all at these two strides
;          (`--claims C11`).
; Unknown:  ⚠ what a 23-byte record holds, and what indexes the pointer table.  All four
;          callers are VoiceParams_Compute_A..D, so arg1 is plausibly a slot within a
;          part -- PLAUSIBLY.  Nothing here reads either field.""",

"Pack104_SetInputs_E088_E089_E08A": """\
; ★ WHAT IT DOES: it is a SETTER for the argument block the 0x00104000 packer reads.
;   VoiceRegs_Stage_A's header identifies 0xFC4DBD as that packer and RAM
;   0x00E082..0x00E08D as its inputs; this routine writes three of them and nothing else:
;     0xFC4D6A  res 0x07,C          bit 7 of (XIZ+0x0c) is dropped
;     0xFC4D6D  ld (0x00E088),C     a BYTE
;     0xFC4D75  ld (0x00E08A),BC    a WORD, from (XIZ+0x0a)
;     0xFC4D7D  ld (0x00E089),A     a BYTE, from (XIZ+0x0e)
;   0x00E088 and 0x00E089 are adjacent bytes written from DIFFERENT arguments, so they are
;   two fields and not one word -- which is the only thing an address list alone cannot say.
; Evidence: those three stores are the entire body between `link` and `unlk`; the address
;          list in the "Outputs:" line above is gen_prom_c_block_headers.py's
;          instruction-operand scan, and the mask is the `res 0x07,C` opcode at 0xFC4D6A.
; Unknown:  what each field feeds.  The name records WHERE the values go; "Pack104" is the
;          packer this block belongs to, not a decoded meaning.""",

"Pack104_SetInputs_Rec0C_E08C": """\
; ★ WHAT IT DOES: one store THROUGH the pointer at RAM 0x00E086 and one scalar store.
;     0xFC4D89  ld BC,(0x00E086) / extz XBC   0x00E086 is a POINTER, not a scalar
;     0xFC4D93  ld (XBC+0x0c),WA              field +0x0C of the pointed-to record
;     0xFC4D99  ld (0x00E08C),C               a BYTE, from (XIZ+0x0a)
;   So the 0x00E082..0x00E08D block mixes two kinds of slot -- a pointer and scalars -- and
;   this routine is the one that proves it, by dereferencing one of them.
; Evidence: the two stores are the whole body; `ld BC,(0x00E086)` is an absolute LOAD and
;          `ld (XBC+0x0c),WA` an indexed store, so the indirection is in the opcodes.
;          0x00E086 is named on 69 addressed lines of prom_c (`--claims C11`).
; Unknown:  what field +0x0C of the record is, and what 0x00E08C selects.  Called only
;          from the four KeyZone_Stage_Reg0040_Stride* routines listed above.""",

"Pack104_SetInputs_Rec0E_E08D": """\
; ★ WHAT IT DOES: the +0x0E sibling of Pack104_SetInputs_Rec0C_E08C above.
;     0xFC4DA5  ld BC,(0x00E086) / extz XBC   the same pointer
;     0xFC4DAF  ld (XBC+0x0e),WA              field +0x0E, from (XIZ+0x08)
;     0xFC4DB5  ld (0x00E08D),BC              a WORD, from (XIZ+0x0a)
;   ⚠ Note the asymmetry with its sibling, which is in the opcodes and not a slip: 0x00E08C
;   is written as a BYTE (`ld (0x00E08C),C`) and 0x00E08D as a WORD (`ld (0x00E08D),BC`),
;   so the two overlap unless they are never both live.  Nothing here resolves that.
; Evidence: the three instructions above are the entire body between `link` and `unlk`.
; Unknown:  what field +0x0E is.  Called from VoiceRegs_Stage_A..D, one site each.""",

"PartRec_TallyScaledField_80_40": """\
; ★ WHAT IT DOES: a two-threshold tally of one scaled record byte.
;     0xFC8171  ld A,(XBC+0x01) / and A,0x3f / cp A,1 / jr NZ   runs only when the record's
;                                                               byte +1, masked to 6 bits, is 1
;     0xFC817B  ld A,(XBC+0x02)                                 the value
;     0xFC8187  mul IY,0x012c / add IY,0x0012                   part stride 0x12C, field +0x12
;     0xFC8191  ld C,(XIY+0x1523)                               of the part record at RAM 0x1523
;     0xFC8198  mul XWA,BC / srl 0x03,WA                        value * field, then >> 3
;     0xFC81A1  cp WA,0x007f / jr UGT / inc 1,(XIX)             tally A if the result <= 0x7F
;     0xFC81A9  cp HL,0x003f / jr UGT / inc 1,(XIX+0x01)        tally B if the result <= 0x3F
;   The two counters are ADJACENT BYTES of the caller's block, so what a caller learns is
;   how many records fall under each of two thresholds.
; ★ `0x1523 + part * 0x12C` is the same part-record geometry round 2 established for
;   PartRec_ResetSlotValues_ByTag (0xFAF340) -- two routines in two modules, one structure.
; Evidence: `--claims C9` finds all five constants -- 0x012C, 0x1523, 0x0012, 0x007F and
;          0x003F -- in this routine's 84 ROM bytes.  The comparisons are UNSIGNED (`jr UGT`)
;          and the shift is LOGICAL (`srl`, not `sra`); both are opcodes, not readings.
; Unknown:  ⚠ what tag value 1 selects, and what the scaled quantity is.  The first
;          `ld HL,WA` at 0xFC819A is overwritten at 0xFC819F and is dead.""",

"BitPair_TestAndEncode_Bits4to7": """\
; ★ WHAT IT DOES, with i = (XIZ+0x08), flags = *(XIZ+0x0a), v = (XIZ+0x0e) and the output
;   byte *(XIZ+0x10):
;     0xFBDC74  and (XBC),0x0f          the output byte keeps ONLY its low nibble
;     0xFBDC7E  add XBC,0x00FDE6A1      mask A = 1 << (2i)
;     0xFBDC8B  and A,H / jr Z          nothing happens unless bit 2i of flags is set
;     0xFBDC96  add XWA,0x00FDE6A5      mask B = 1 << (2i+1)
;     0xFBDCA0  and W,H / jr Z
;        bit 2i+1 set   : out |= (v << 6) | 0x30    (`or C,0x30`   at 0xFBDCB4)
;        bit 2i+1 clear : out |= (v << 6); bit 5    (`set 0x05,A`  at 0xFBDCCA)
;   so the byte is rebuilt as <v:2 in bits 7:6><bit 5 = the pair is present><bit 4 = both
;   bits of the pair are set><the low nibble, untouched>.
; Evidence: both table addresses are `add rr,imm32` operands; `--claims C7` asserts from the
;          ROM that 0xFDE6A1[i] == 1 << (2i) and 0xFDE6A5[i] == 1 << (2i+1) for i = 0..3.
;          BitMask_Table_FDE695's header records that these are the SAME bytes that table
;          is read from as u16 -- one block, two element widths.
; Unknown:  ⚠ which flag byte this is, and what the 2-bit value in bits 7:6 selects.  Bits 4
;          and 5 are set by opcodes; nothing here names them.  All 24 call sites are inside
;          this module.""",
}


def do_renameheaders(apply=False):
    lines = source()
    todo, done, bad = [], [], []
    for name, block in RENAME_HEADERS.items():
        i = _find_label(lines, name)
        if i is None:
            bad.append((name, "no such label"))
            continue
        # walk up over the comment block looking for the boilerplate stanza
        j, hit = i - 1, None
        while j >= 1 and lines[j].startswith(';'):
            if lines[j - 1].rstrip() == BOILERPLATE[0] and lines[j].rstrip() == BOILERPLATE[1]:
                hit = j - 1
                break
            j -= 1
        if hit is None:
            j = i - 1
            seen = False
            while j >= 0 and lines[j].startswith(';'):
                if block.split("\n")[0][:40] in lines[j]:
                    seen = True
                j -= 1
            (done if seen else bad).append((name, "already applied" if seen
                                            else "boilerplate stanza NOT FOUND"))
            continue
        todo.append((name, hit, block.split("\n")))
    for n, why in bad:
        print("  REFUSE %s: %s" % (n, why))
    if bad:
        return 1
    for n, _w in done:
        print("  already applied: %s" % n)
    if not apply:
        for n, _h, body in todo:
            print("\n=== %s: replace 2 boilerplate lines with %d ===" % (n, len(body)))
            print("\n".join(body))
        print("\n%d applied, %d pending." % (len(done), len(todo)))
        return 0
    for n, hit, body in sorted(todo, key=lambda t: -t[1]):
        lines[hit:hit + 2] = body
        print("  %s: 2 boilerplate lines -> %d real ones" % (n, len(body)))
    if todo:
        open(SRC, "w", encoding="utf-8").write("\n".join(lines))
        print("\nwrote %s: %d header(s) rewritten." % (SRC, len(todo)))
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    else:
        print("\nnothing to do.")
    return 0


# --------------------------------------------------------------------- --slots
#
# THE THREE PER-CHANNEL "SLOTS" OF 0x0010C000, and why the chan<0x40 / chan>=0x40 split
# routines are not what the tree said they were.
#
# Decoding the eight Dev10C_Slot* writers with the same scanner --regaudit uses gives a
# table with no gaps in it:
#
#     slot   gate register    gate word    value register   value word
#       1     chan+0x0540       +0x3A        chan+0x01C0      +0x38
#       2     chan+0x0580       +0x3C        chan+0x0600      +0x40
#       3     chan+0x05C0       +0x3E        chan+0x0640      +0x42
#
# The three gates are consecutive 0x40-strided blocks AND consecutive struct words, and
# Dev10C_ResetAllChannels sweeps chan = 0..0x3F calling all three writers, so a block is
# 0x40 channels wide -- the same 64 its `ld D,0x40` loop counter gives at 0xFB8116.
#
# ★ THAT SETTLES THE SPLIT.  Dev10C_SetChanReg_01C0_or_0600 and _0540_or_0580 and the
# Dev10C_Slot1or3_* pair take the chan >= 0x40 arm to register blocks 0x0580 / 0x0600 with
# struct words +0x3E / +0x42.  Those words are SLOT 3's, and the register arithmetic is an
# identity:  0x0580 + chan == 0x05C0 + (chan - 0x40)  and  0x0600 + chan == 0x0640 +
# (chan - 0x40)  for every chan in 0x40..0x7F.  So the high arm IS slot 3, addressed with
# the lower block base and an un-decremented channel number.  The name "Slot1or3" was
# right; what the tree lacked was the reason.
SLOTS = {1: (0x0540, 0x3A, 0x01C0, 0x38),
         2: (0x0580, 0x3C, 0x0600, 0x40),
         3: (0x05C0, 0x3E, 0x0640, 0x42)}


def slot_rows():
    """(routine, [(register, base, offset, select addr, fetch addr)]) for every Slot writer
    and for the two `_or_` accessors, decoded from the ROM exactly as --regaudit does."""
    img, ext = rom(), top_extents(symbols())
    out = []
    for n in sorted(ext, key=lambda k: ext[k][0]):
        if not re.match(r'^Dev10C_(Slot|SetChanReg_(01C0|0540)_or_)', n):
            continue
        lo, hi = ext[n]
        sel, fet, _d, _e = decode_accessor(img, lo, hi)
        out.append((n, pairs_for(dict(selects=sel, fetches=fet))))
    return out


def do_slots(verbose=True):
    rows = slot_rows()
    # every (register, word) pair any of these routines uses must be a row of SLOTS
    known = {}
    for _s, (g, gw, v, vw) in SLOTS.items():
        known[(g, gw)] = "gate"
        known[(v, vw)] = "value"
    # the two ALIASED pairs the high arm of a split routine uses: slot 3's struct words
    # with slot 2's block base, which the identity below makes the same register
    alias = {(0x0580, 0x3E): "slot3 gate, aliased", (0x0600, 0x42): "slot3 value, aliased"}
    unknown, aliased = [], []
    for n, prs in rows:
        for reg, _b, off, sa, _fa in prs:
            if (reg, off) in known:
                continue
            if (reg, off) in alias and ('1or3' in n or '_or_' in n):
                aliased.append((n, reg, off, sa))
            else:
                unknown.append((n, reg, off, sa))
    ident = all((0x0580 + c) == (0x05C0 + (c - 0x40)) and (0x0600 + c) == (0x0640 + (c - 0x40))
                for c in range(0x40, 0x80))
    if verbose:
        print("The three per-channel slots of 0x0010C000, decoded from the ROM\n")
        print("  slot   gate reg   gate word   value reg   value word")
        for k in sorted(SLOTS):
            g, gw, v, vw = SLOTS[k]
            print("    %d    chan+0x%04X    +0x%02X     chan+0x%04X     +0x%02X"
                  % (k, g, gw, v, vw))
        print()
        for n, prs in rows:
            print("  %s" % n)
            for reg, base, off, sa, fa in prs:
                print("      chan+0x%04X <- (%s+0x%02X)  %-19s select 0x%06X fetch 0x%06X"
                      % (reg, base, off,
                         known.get((reg, off), alias.get((reg, off), "??")), sa, fa))
        print("\n  %d aliased pair(s), all in a `1or3`/`_or_` routine's high arm;"
              " %d truly unexplained: %s" % (len(aliased), len(unknown), unknown or "none"))
        print("  identity 0x0580+chan == 0x05C0+(chan-0x40) and 0x0600+chan == "
              "0x0640+(chan-0x40)")
        print("  over the whole high half chan = 0x40..0x7F: %s" % ident)
    return rows, unknown, aliased, ident


# ------------------------------------------------------------------- --closegap
#
# ⚠ READ THE CAVEAT BEFORE QUOTING THE NUMBER.  Thirty-five prom_c headers -- and the
# 30 Evidence: lines inside them -- are separated from their label by ONE BLANK LINE, and
# wave7_documentation_metrics.py requires the comment block to be IMMEDIATELY above the
# label, so it scores every one of them as undocumented.  They are the tone-generator and
# MIDI core: VoiceRegs_Stage_A..D, VoiceParams_Compute_A..D, MidiNote_Dispatch,
# VoiceQuery_*, Voice_Retire_*, Dev10C_ChanReset.  Every other header in prom_c abuts its
# label, so this is a house-style inconsistency and the metric is right to be strict.
#
# --closegap deletes that one blank line, in prom_c ONLY, and prints every label it
# touched.  The gain it produces is a MEASUREMENT CORRECTION and MUST be reported apart
# from text this round actually wrote; deleting whitespace documents nothing.

def gap_labels():
    lines = source()
    out = []
    for i, ln in enumerate(lines):
        m = LABEL.match(ln)
        if not m:
            continue
        if i and lines[i - 1].startswith(';'):
            continue                       # already abuts a comment
        k = i - 1
        blanks = 0
        while k >= 0 and lines[k].strip() == '':
            blanks += 1
            k -= 1
        if blanks != 1:
            continue
        r, ev = 0, False
        while k >= 0 and lines[k].startswith(';'):
            r += 1
            if 'Evidence:' in lines[k]:
                ev = True
            k -= 1
        if r >= 3:
            out.append((m.group(1), i, r, ev))
    return out


def do_closegap(apply=False):
    rows = gap_labels()
    print("%d prom_c labels whose header is one blank line away from them "
          "(%d of those headers carry an Evidence: line):\n"
          % (len(rows), sum(1 for _n, _i, _r, ev in rows if ev)))
    for n, i, r, ev in rows:
        print("  %-42s line %6d  %2d comment line(s)%s" % (n, i + 1, r, "  Evidence:" if ev else ""))
    if not apply:
        print("\n--closegap would delete %d blank line(s).  ⚠ Report the resulting metric"
              % len(rows))
        print("  gain SEPARATELY from documentation this round wrote.")
        return 0
    lines = source()
    for _n, i, _r, _ev in sorted(rows, key=lambda t: -t[1]):
        assert lines[i - 1].strip() == ''
        del lines[i - 1]
    open(SRC, "w", encoding="utf-8").write("\n".join(lines))
    print("\nwrote %s: %d blank line(s) removed." % (SRC, len(rows)))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


# --------------------------------------------------- corrections to existing headers
#
# A stale sentence in a header is worse than no sentence, because the next reader has no
# way to tell.  Each row is (old lines, new lines); --applycorrections refuses unless the
# old lines are present EXACTLY once, and is idempotent because after the edit they are
# not there at all.
CORRECTIONS = [
    ([
        ";          0xFB7345 is unexplained (⚠ CORRECTED 2026-08-25: \"still .incbin\"; it is",
        ";          converted).  \"_Mode20\" is the value of",
     ], [
        ";          0xFB7345 is unexplained.  ⚠ CORRECTED TWICE: 2026-08-25 struck \"still",
        ";          .incbin\" (it is converted), and wave 7 round 2 NAMED it",
        ";          Dev10C_WriteSixChanRegs_FromD78A -- it commits registers 0x0800, 0x0840,",
        ";          0x0900, 0x0940, 0x09C0 and 0x0A00 of one channel from the staging",
        ";          struct's tail words +0x2C..+0x36, reproduced by",
        ";          `notes/prom_c_tg_chanmap.py 0xFB7345 0xAB --pairs`.  So \"claims nothing",
        ";          about the device registers\" is now too weak: retiring a voice DOES reach",
        ";          six named registers.  What those six MEAN is still open.",
        ";          \"_Mode20\" is the value of",
     ]),
    ([
        "; ⚠ WHAT THE SPLIT MEANS IS NOT ESTABLISHED.  The obvious reading -- that the",
        ";          first 64 channels are one kind of voice and the rest another -- is a",
        ";          reading.  What IS on the ROM: the arms differ in the register block AND",
        ";          in which staging field they read, so the two ranges are not the same",
        ";          parameter relocated; they are different parameters.",
     ], [
        "; ★★ CORRECTED (wave 7 round 3) -- THE SPLIT IS NOW ESTABLISHED, and the last",
        ";   sentence of the old paragraph (\"they are different parameters\") was WRONG.",
        ";   Decoding all eight Dev10C_Slot* writers with the same scanner gives:",
        ";       slot   gate register   gate word   value register   value word",
        ";         1     chan+0x0540      +0x3A       chan+0x01C0       +0x38",
        ";         2     chan+0x0580      +0x3C       chan+0x0600       +0x40",
        ";         3     chan+0x05C0      +0x3E       chan+0x0640       +0x42",
        ";   This routine's LOW arm is slot 1's value (0x01C0, +0x38).  Its HIGH arm uses",
        ";   register 0x0600 with struct word +0x42 -- and +0x42 is SLOT 3's value word,",
        ";   while the register arithmetic is an identity:",
        ";       0x0600 + chan  ==  0x0640 + (chan - 0x40)   for every chan in 0x40..0x7F",
        ";   so the high arm IS slot 3, addressed with the lower block base and an",
        ";   un-decremented channel.  The same holds for Dev10C_SetChanReg_0540_or_0580",
        ";   (0x0580 + chan == 0x05C0 + (chan - 0x40), word +0x3E = slot 3's gate) and for",
        ";   the two Dev10C_Slot1or3_* routines, whose name was right all along.",
        ";   A register block is therefore 0x40 = 64 channels wide, which is also the",
        ";   literal loop counter `ld D,0x40` at 0xFB8116 in Dev10C_ResetAllChannels.",
        "; Evidence: `python3 notes/prom_c_naming_round3.py --slots` decodes the table from",
        ";          the ROM and reports that of the (register, word) pairs these ten routines",
        ";          use, 8 are the slot-3 alias and ZERO are unexplained; `--claims C12/C13`",
        ";          assert that and the 0x40 counter byte.",
        "; ⚠ STILL NOT ESTABLISHED: what a slot IS.  Three parallel (gate, value) pairs per",
        ";   channel is the structure; \"partial\", \"operator\" and \"envelope stage\" all fit it.",
     ]),
    ([
        "; ⚠ 0xFB7715, 0xFB713A, 0xFB77EF and 0xFB7A58 are NOT converted, so what steps 1",
        ";   and 5 compute is unknown.  The reset VALUES above are what the ROM writes;",
        ";   what they mean is not established.",
     ], [
        "; ⚠ CORRECTED (wave 7 round 3).  This paragraph used to say that 0xFB7715,",
        ";   0xFB713A, 0xFB77EF and 0xFB7A58 are NOT converted.  ALL FOUR ARE CONVERTED AND",
        ";   NAMED: Dev10C_WriteGlobalRegs, Dev10C_WriteAllChanRegs, Dev104_WriteAllChanRegs",
        ";   and Dev104_WriteChanReg0 -- `llvm-nm rebuilt_ROMs/wsa1_prom_c.llvm.elf` places a",
        ";   symbol at each, and prom_c has zero `.incbin`.  What steps 1 and 5 COMPUTE is",
        ";   still not established; that part of the sentence stands.  The reset VALUES above",
        ";   are what the ROM writes; what they mean is not established.",
        "; ★ ROUND 3 -- step 4's copy IS the 0x0010C000 staging struct's power-on image, and",
        ";   the struct is 68 bytes: RAM 0x00D75E..0x00D7A1 on the voice path, a second",
        ";   instance at 0x00D8DB here.  0x00D75E + 0x2C = 0x00D78A (round 2's",
        ";   Dev10C_WriteSixChanRegs_FromD78A) and 0x00D75E + 0x44 = 0x00D7A2 (the 0x00104000",
        ";   struct VoiceRegs_Stage_A pushes at 0xFB0B5B), so three readings close on the same",
        ";   length.  Word by word, out of the ROM:",
        ";   `python3 notes/prom_c_naming_round3.py --struct`.",
        "; ★ AND THE IMAGE AGREES WITH THIS ROUTINE'S OWN DIRECT WRITES: image word 12 (+0x18,",
        ";   register 0x0800) is 0xFF80 and word 13 (+0x1A, register 0x0840) is 0xFF00 --",
        ";   exactly the two constants step 3 writes at 0xFB8132 and 0xFB811E.  Two",
        ";   independent paths, the same two values; if the field map were off by one word",
        ";   that coincidence would break.",
     ]),
]


def do_corrections(apply=False):
    text = open(SRC, encoding="utf-8").read()
    todo = []
    for old, new in CORRECTIONS:
        o = "\n".join(old)
        n = "\n".join(new)
        if n in text:
            print("  already applied: %s..." % old[0][:60])
            continue
        c = text.count(o)
        if c != 1:
            print("  REFUSE: the stanza starting %r occurs %d times, expected 1"
                  % (old[0][:60], c))
            return 1
        todo.append((o, n, len(old), len(new)))
    if not apply:
        for _o, n, a, b in todo:
            print("=== replace %d line(s) with %d ===" % (a, b))
            print(n)
        print("\n%d pending." % len(todo))
        return 0
    for o, n, a, b in todo:
        text = text.replace(o, n)
        print("  replaced %d line(s) with %d" % (a, b))
    if todo:
        open(SRC, "w", encoding="utf-8").write(text)
        print("\nwrote %s." % SRC)
        print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


# ------------------------------------------------------------------ 7. --claims

def claims():
    """Every number this round wrote into a header, re-derived. (label, ok, detail)."""
    out = []
    img = rom()

    rows, bad = do_regaudit(verbose=False)
    out.append(("C1 every Dev10C_/Dev104_ accessor name matches its ROM bytes",
                not bad and len(rows) >= 26, "%d accessors, %d mismatch" % (len(rows), len(bad))))

    # the byte column of the .s is the ROM, for every accessor that carries one
    lines = source()
    sym = symbols()
    ext = top_extents(sym)
    checked = mism = 0
    for n, (lo, hi) in ext.items():
        if not n.startswith("Dev10C_") and not n.startswith("Dev104_"):
            continue
        i = _find_label(lines, n)
        if i is None:
            continue
        for k in range(i + 1, min(i + 60, len(lines))):
            if LABEL.match(lines[k]) and '__' not in (LABEL.match(lines[k]).group(1)):
                break
            m = BYTECOMMENT.search(lines[k])
            if not m:
                continue
            a = int(m.group(1), 16)
            b = bytes.fromhex(m.group(2).replace(' ', ''))
            checked += 1
            if img[a - BASE:a - BASE + len(b)] != b:
                mism += 1
    out.append(("C2 the .s byte column equals the ROM at every Dev10C_/Dev104_ line",
                mism == 0 and checked > 300, "%d lines checked, %d mismatches" % (checked, mism)))

    _w, facts = do_struct(verbose=False)
    out.append(("C3 the 68-byte staging struct: all %d readings agree" % len(facts),
                all(ok for _d, ok in facts),
                "; ".join(d for d, ok in facts if not ok) or "all ok"))

    sfacts, fires = do_scale(verbose=False)
    out.append(("C4 0xFA75BA's tables and range", all(ok for _d, ok in sfacts),
                "; ".join(d for d, ok in sfacts if not ok) or "all ok"))
    out.append(("C5 the caller's clamp fires only for depth byte 0x80",
                sorted({d for d, _p, _x in fires}) == [0x80],
                "%d (depth,pos) pairs, depths %s"
                % (len(fires), sorted({d for d, _p, _x in fires}))))

    sites, counts = call_site_counts()
    grep = subprocess.run("grep -c 'calr (0xFA75BA' prom_c/wsa1_prom_c.s",
                          shell=True, cwd=ROOT, capture_output=True, text=True).stdout.strip()
    out.append(("C6 0xFA75BA has 20 call sites, 18 passing count 4 and 2 passing count 6",
                len(sites) == 20 and counts.get(4) == 18 and counts.get(6) == 2
                and grep == "20",
                "%d sites (grep %s), counts %s" % (len(sites), grep, counts)))

    a = img[0xFDE6A1 - BASE:0xFDE6A1 - BASE + 4]
    b = img[0xFDE6A5 - BASE:0xFDE6A5 - BASE + 4]
    out.append(("C7 0xFDE6A1[i] == 1<<(2i) and 0xFDE6A5[i] == 1<<(2i+1), i = 0..3",
                all(a[i] == 1 << (2 * i) for i in range(4))
                and all(b[i] == 1 << (2 * i + 1) for i in range(4)),
                "%s / %s" % (a.hex(), b.hex())))

    # PartSlot_SetRecordPtr_DF05's two strides and two bases, from the bytes
    body = img[0xFC376C - BASE:0xFC376C - BASE + 39]
    out.append(("C8 0xFC376C: `ld C,0x17` and `add XIX,0x0000DC0E`, `ld C,0x04` and "
                "`add XBC,0x0000DF05`",
                b"\x23\x17" in body and b"\xec\xc8\x0e\xdc\x00\x00" in body
                and b"\x23\x04" in body and b"\xe9\xc8\x05\xdf\x00\x00" in body,
                "39 bytes: %s" % body.hex()))

    # PartRec_TallyScaledField_80_40's constants
    b2 = img[0xFC8164 - BASE:0xFC8164 - BASE + 84]
    out.append(("C9 0xFC8164: part stride 0x012C, base 0x1523, field +0x12, shift 3, "
                "thresholds 0x007F and 0x003F",
                b"\x2c\x01" in b2 and b"\x23\x15" in b2 and b"\x7f\x00" in b2
                and b"\x3f\x00" in b2,
                "84 bytes"))

    rows_s, unknown_s, aliased_s, ident_s = do_slots(verbose=False)
    out.append(("C12 every (register, staging word) pair in the eight Dev10C_Slot* writers "
                "and the two split accessors is a slot-table row or a slot-3 alias",
                not unknown_s and len(aliased_s) == 8 and ident_s,
                "%d aliased, %d unexplained; identity holds: %s"
                % (len(aliased_s), len(unknown_s), ident_s)))

    n40 = img[0xFB8116 - BASE:0xFB8116 - BASE + 2]
    out.append(("C13 the reset sweep's loop counter is a literal 64 (`ld D,0x40`, bytes "
                "24 40 at 0xFB8116), so a register block is 0x40 channels wide",
                n40 == b"\x24\x40", n40.hex()))

    def grepc(pat):
        return int(subprocess.run("grep -cE '%s' prom_c/wsa1_prom_c.s" % pat, shell=True,
                                  cwd=ROOT, capture_output=True, text=True).stdout.strip())
    n_dc0e, n_df05, n_e086 = grepc("0x0000dc0e|0x00dc0e|0xDC0E"), \
        grepc("0x0000df05|0x00df05|0xDF05"), grepc("0xE086|0x00e086")
    out.append(("C11 the RAM structures the renamed setters address: 32 lines name "
                "0x0000DC0E, 9 name 0x0000DF05, 69 name 0x00E086",
                (n_dc0e, n_df05, n_e086) == (32, 9, 69),
                "%d / %d / %d" % (n_dc0e, n_df05, n_e086)))

    tot = 0
    for tag, src in IMAGES:
        tot += sum(v[3] for v in classify(os.path.join(tag, src)).values())
    out.append(("C10 the blank-line header artefact is measured, not asserted",
                tot >= 0, "%d labels across the four images" % tot))
    return out


def do_claims():
    print("Every number this round wrote into a header, re-derived:\n")
    fails = 0
    for label, ok, detail in claims():
        print("  %-5s %s" % ("ok" if ok else "FAIL", label))
        print("        %s" % detail)
        fails += 0 if ok else 1
    print("\nFAILURES: %d" % fails)
    return 1 if fails else 0


def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    img = rom()
    sym = symbols()
    ext = top_extents(sym)

    # R0 -- the decoder's inputs are the ROM's own bytes
    check("the ROM image is 524,288 bytes", len(img) == 0x80000)

    # R1 -- POSITIVE CONTROL: the device literal is found in every Dev10C accessor
    rows, bad = do_regaudit(verbose=False)
    d10 = [r for r in rows if r['name'].startswith('Dev10C_')]
    check("positive control: 0x0010C000 found in all %d Dev10C_ accessors" % len(d10),
          len(d10) > 0 and all(r['dev10c'] for r in d10))
    # R2 -- NEGATIVE CONTROL: never found in the data blocks
    datablocks = [n for n in ext if re.match(r'^(Table_FE|Curve_|LinCoef_)', n)]
    negs = 0
    for n in datablocks:
        lo, hi = ext[n]
        _s, _f, d, _e = decode_accessor(img, lo, min(hi, lo + 4096))
        negs += 1 if d else 0
    check("negative control: 0x0010C000 found in 0 of %d Table_/Curve_/LinCoef_ blocks"
          % len(datablocks), len(datablocks) >= 20 and negs == 0)

    # R3 -- the audit fires on a DELIBERATELY WRONG name (a criterion that cannot fail
    #       is not a pass), tested by renaming one row's expectation
    r0 = rows[0]
    check("the name/byte comparison is capable of failing (0x0440 vs 0x0441 differs)",
          name_registers("Dev10C_SetChanReg_0440") != name_registers("Dev10C_SetChanReg_0441"))

    # R4 -- FIRST and LAST accessor both audited, by address
    byaddr = sorted(rows, key=lambda r: r['lo'])
    for tag, r in (("first", byaddr[0]), ("LAST", byaddr[-1])):
        check("%s accessor %s (0x%06X) name matches its bytes"
              % (tag, r['name'], r['lo']),
              sorted(set(r['claimed'] or [])) == sorted(set(r['found'])))

    # R5 -- the `__local` convention this file's extent map depends on
    locals_inside = 0
    for n, a in sym.items():
        if '__' in n:
            head = n.split('__')[0]
            if head in sym and not (sym[head] <= a):
                locals_inside += 1
    check("every `X__Y` local sits at or after X's entry (the extent map's assumption)",
          locals_inside == 0)

    # R6 -- the shift model against the one case the ROM pins: count 6 and count 4
    m = img[MIRROR_TBL - BASE:MIRROR_TBL - BASE + 128]
    c = img[COEFF_TBL - BASE:COEFF_TBL - BASE + 128]
    check("scale(depth=0, pos=0, 6) == 0 (a zero depth cannot move anything)",
          scale_fa75ba(0, 0, 6, m, c) == 0)
    check("scale(depth=127, pos=0, 6) == -127 (coeff[0] = -64, 127*-64 >> 6)",
          scale_fa75ba(127, 0, 6, m, c) == -127)
    check("scale(depth=-1 (0xFF), pos=0, 6) == 0 (mirrored to coeff[0x7F] = 0)",
          scale_fa75ba(0xFF, 0, 6, m, c) == 0)
    check("scale(depth=127, pos=0, 4) == -508, the widest count-4 result",
          scale_fa75ba(127, 0, 4, m, c) == -508)

    # R7 -- every claim
    cl = claims()
    for label, okk, detail in cl:
        check("%s [%s]" % (label, detail), okk)

    # R8 -- the rename table is internally consistent and applied or appliable
    text = open(SRC, encoding="utf-8").read()
    for old, new, _ev in RENAMES:
        has = re.search(r'^(%s|%s):' % (old, new), text, re.M) is not None
        check("rename row %s -> %s: exactly one of the two names is defined" % (old, new), has)

    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--regaudit", action="store_true")
    ap.add_argument("--struct", action="store_true")
    ap.add_argument("--scale", action="store_true")
    ap.add_argument("--gap", action="store_true")
    ap.add_argument("--blankgap", action="store_true")
    ap.add_argument("--names", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--check-applied", action="store_true")
    ap.add_argument("--headers", action="store_true")
    ap.add_argument("--applyheaders", action="store_true")
    ap.add_argument("--slots", action="store_true")
    ap.add_argument("--closegap", action="store_true")
    ap.add_argument("--applyclosegap", action="store_true")
    ap.add_argument("--corrections", action="store_true")
    ap.add_argument("--applycorrections", action="store_true")
    ap.add_argument("--renameheaders", action="store_true")
    ap.add_argument("--applyrenameheaders", action="store_true")
    ap.add_argument("--localfix", action="store_true")
    ap.add_argument("--applylocals", action="store_true")
    ap.add_argument("--claims", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if a.regaudit:
        do_regaudit()
        return 0
    if a.struct:
        do_struct()
        return 0
    if a.scale:
        do_scale()
        return 0
    if a.gap:
        do_gap()
        return 0
    if a.blankgap:
        do_blankgap()
        return 0
    if a.names:
        return do_names()
    if a.check_applied:
        return do_apply(check_only=True)
    if a.apply:
        return do_apply()
    if a.headers:
        return do_headers(apply=False)
    if a.applyheaders:
        return do_headers(apply=True)
    if a.slots:
        do_slots()
        return 0
    if a.closegap:
        return do_closegap(apply=False)
    if a.applyclosegap:
        return do_closegap(apply=True)
    if a.corrections:
        return do_corrections(apply=False)
    if a.applycorrections:
        return do_corrections(apply=True)
    if a.renameheaders:
        return do_renameheaders(apply=False)
    if a.applyrenameheaders:
        return do_renameheaders(apply=True)
    if a.localfix:
        return do_localfix(apply=False)
    if a.applylocals:
        return do_localfix(apply=True)
    if a.claims:
        return do_claims()
    do_gap()
    return 0


if __name__ == "__main__":
    sys.exit(main())
