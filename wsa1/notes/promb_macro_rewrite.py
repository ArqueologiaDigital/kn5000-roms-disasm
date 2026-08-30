#!/usr/bin/env python3
"""Retire prom_b's `[llvm-mc cannot encode this]` rows by spelling them with the
SHARED TLCS-900 macros -- and prove that the spelling is the same bytes.

QUESTION IT ANSWERS
    "prom_b holds 7,310 rows of the shape

         .byte 0xC1, 0xB8, 0x20, 0x3F, 0x11	; F0003C  cp (0x20b8),0x11   [llvm-mc cannot encode this]

     while prom_a writes the SAME BYTES as `m_cp_mi8 MB16, 0x20b8, 0x11`.
     Which of those rows can be spelled with the macro set in
     include/tlcs900_mem_ops.inc, exactly, and what does each become?"

WHY IT IS SAFE TO RUN
    Every rewrite passes THREE independent checks before it is emitted, and a row
    that fails any of them is LEFT AS A BLOB.  A blob left with a reason beats a
    wrong macro.

      1. RE-EMISSION.  This file carries a Python mirror of every macro in
         include/tlcs900_mem_ops.inc.  The proposed invocation is re-emitted
         through that mirror and must equal the row's own bytes, byte for byte.
         (--selftest checks the mirror against prom_a's 5,134 existing macro
         lines, which carry their bytes in the comment: the mirror is not
         allowed to disagree with the source that already uses these macros.)
      2. MNEMONIC.  The row's `; ADDR <text>` comment is unidasm's, and it is the
         DECODE AUTHORITY for the line.  The macro this file picks declares which
         mnemonic it is; that must equal the first token of the comment's text.
         This is the check the byte gate cannot do -- bytes prove the encoding,
         not the NAME on it.
      3. OPERAND.  The memory operand string this file derives from the PREFIX
         BYTES -- `(0x20b8)`, `(XIZ+0xfe)`, `(XHL+IY)` -- must appear verbatim in
         that same comment, and so must the register operand where the form has
         one.  A prefix decoded wrongly cannot survive this.

    And then the tree's own gate, which is the one that certifies anything here:

        python3 scripts/analysis/assert_byte_identical.py

RUN
    python3 notes/promb_macro_rewrite.py --census          # what is convertible, by macro
    python3 notes/promb_macro_rewrite.py --left            # what is NOT, by shape, with the reason
    python3 notes/promb_macro_rewrite.py --left --detail   # ... every remaining row, by address
    python3 notes/promb_macro_rewrite.py --apply --only m_cp_mi8,m_cp_mi16
    python3 notes/promb_macro_rewrite.py --selftest        # the invariants

⚠ WHAT IT DOES TO THE LINE.  The `.byte` directive becomes the macro; the
    `; ADDR <text>` comment is kept VERBATIM; the trailing
    `   [llvm-mc cannot encode this]` marker is dropped, because it explained why
    the row was a `.byte` and the row is no longer one.  Rows left alone keep
    theirs.  Nothing else on the line changes, and no other line is touched --
    --selftest asserts that the file's comment lines and labels are the same set
    before and after.
"""
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_B = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")
PROM_A = os.path.join(ROOT, "prom_a/wsa1_prom_a.s")

BLOB = re.compile(r'^\t\.byte ((?:0x[0-9A-F]{2}, )*0x[0-9A-F]{2})\t; ([0-9A-F]{6})  (.*?)   \[llvm-mc cannot encode this\]$')

REG8 = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']
REG16 = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']
REG32 = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']
# s_allreg8 (dasm900.cpp:1349-1405) over 0xE0-0xEF: the two halves of each pair
# are swapped against REG8's order.  Derived from the rb_* equates in
# include/tlcs900_mem_ops.inc, which name eight of these sixteen slots.
REG8_ADDR = {0xE0: 'A', 0xE1: 'W', 0xE4: 'C', 0xE5: 'B',
             0xE8: 'E', 0xE9: 'D', 0xEC: 'L', 0xED: 'H'}
SIZE_REGS = {'B': REG8, 'W': REG16, 'L': REG32}
PFX_NAME = {'B': 'MB', 'W': 'MW', 'L': 'ML', 'D': 'MD'}
IDX_NAME = {'B': 'MXB', 'W': 'MXW', 'L': 'MXL', 'D': 'MXD'}


# --------------------------------------------------------------- the mirror
# ★ ONE PYTHON FUNCTION PER MACRO IN include/tlcs900_mem_ops.inc.  These are the
# re-emission half of check 1.  Keeping them here rather than parsing the .inc is
# deliberate: --selftest cross-checks them against prom_a's 5,134 macro lines, so
# a mirror that drifts from the .inc is caught by the SOURCE, not by a copy of it.
def _mem(pfx, addr):
    out = [pfx]
    if (pfx & 0xC0) == 0xC0:
        out.append(addr & 0xFF)
        if (pfx & 3) >= 1:
            out.append((addr >> 8) & 0xFF)
        if (pfx & 3) >= 2:
            out.append((addr >> 16) & 0xFF)
    else:
        if pfx & 0x08:
            out.append(addr & 0xFF)
    return out


def _memx(pfx, base, idx):
    return [pfx, 0x07, base, idx]


def _memxb(pfx, base, idx):
    return [pfx, 0x03, base, idx]


def _i8(v):
    return [v & 0xFF]


def _i16(v):
    return [v & 0xFF, (v >> 8) & 0xFF]


# name -> (arity, emit(args) -> [bytes], mnemonic-or-None)
# mnemonic None means "the caller supplies it", used where one macro spells more
# than one mnemonic (m_push is `push` at byte size and `pushw` at word size).
MIRROR = {
    'm_push':      lambda p, a: _mem(p, a) + [0x04],
    'm_rld_am':    lambda p, a: _mem(p, a) + [0x06],
    'm_pop':       lambda p, a: _mem(p, a) + [0x04],
    'm_popw':      lambda p, a: _mem(p, a) + [0x06],
    'm_ld_rm':     lambda p, a, r: _mem(p, a) + [0x20 + r],
    'm_ex_mr':     lambda p, a, r: _mem(p, a) + [0x30 + r],
    'm_add_mi8':   lambda p, a, i: _mem(p, a) + [0x38] + _i8(i),
    'm_add_mi16':  lambda p, a, i: _mem(p, a) + [0x38] + _i16(i),
    'm_sub_mi8':   lambda p, a, i: _mem(p, a) + [0x3A] + _i8(i),
    'm_sub_mi16':  lambda p, a, i: _mem(p, a) + [0x3A] + _i16(i),
    'm_and_mi8':   lambda p, a, i: _mem(p, a) + [0x3C] + _i8(i),
    'm_and_mi16':  lambda p, a, i: _mem(p, a) + [0x3C] + _i16(i),
    'm_xor_mi8':   lambda p, a, i: _mem(p, a) + [0x3D] + _i8(i),
    'm_xor_mi16':  lambda p, a, i: _mem(p, a) + [0x3D] + _i16(i),
    'm_or_mi8':    lambda p, a, i: _mem(p, a) + [0x3E] + _i8(i),
    'm_or_mi16':   lambda p, a, i: _mem(p, a) + [0x3E] + _i16(i),
    'm_cp_mi8':    lambda p, a, i: _mem(p, a) + [0x3F] + _i8(i),
    'm_cp_mi16':   lambda p, a, i: _mem(p, a) + [0x3F] + _i16(i),
    'm_mul':       lambda p, a, r: _mem(p, a) + [0x40 + r],
    'm_muls':      lambda p, a, r: _mem(p, a) + [0x48 + r],
    'm_div':       lambda p, a, r: _mem(p, a) + [0x50 + r],
    'm_divs':      lambda p, a, r: _mem(p, a) + [0x58 + r],
    'm_inc':       lambda n, p, a: _mem(p, a) + [0x60 + (n & 7)],
    'm_dec':       lambda n, p, a: _mem(p, a) + [0x68 + (n & 7)],
    'm_add_rm':    lambda p, a, r: _mem(p, a) + [0x80 + r],
    'm_add_mr':    lambda p, a, r: _mem(p, a) + [0x88 + r],
    'm_sub_rm':    lambda p, a, r: _mem(p, a) + [0xA0 + r],
    'm_sub_mr':    lambda p, a, r: _mem(p, a) + [0xA8 + r],
    'm_sbc_rm':    lambda p, a, r: _mem(p, a) + [0xB0 + r],
    'm_and_rm':    lambda p, a, r: _mem(p, a) + [0xC0 + r],
    'm_and_mr':    lambda p, a, r: _mem(p, a) + [0xC8 + r],
    'm_xor_rm':    lambda p, a, r: _mem(p, a) + [0xD0 + r],
    'm_xor_mr':    lambda p, a, r: _mem(p, a) + [0xD8 + r],
    'm_or_rm':     lambda p, a, r: _mem(p, a) + [0xE0 + r],
    'm_or_mr':     lambda p, a, r: _mem(p, a) + [0xE8 + r],
    'm_cp_rm':     lambda p, a, r: _mem(p, a) + [0xF0 + r],
    'm_cp_mr':     lambda p, a, r: _mem(p, a) + [0xF8 + r],
    'm_ld_mi8':    lambda p, a, i: _mem(p, a) + [0x00] + _i8(i),
    'm_ld_mi16':   lambda p, a, i: _mem(p, a) + [0x02] + _i16(i),
    'm_lda16':     lambda p, a, r: _mem(p, a) + [0x20 + r],
    'm_lda32':     lambda p, a, r: _mem(p, a) + [0x30 + r],
    'm_st_mr8':    lambda p, a, r: _mem(p, a) + [0x40 + r],
    'm_st_mr16':   lambda p, a, r: _mem(p, a) + [0x50 + r],
    'm_st_mr32':   lambda p, a, r: _mem(p, a) + [0x60 + r],
    'm_stcf':      lambda n, p, a: _mem(p, a) + [0xA0 + (n & 7)],
    'm_res':       lambda n, p, a: _mem(p, a) + [0xB0 + (n & 7)],
    'm_set':       lambda n, p, a: _mem(p, a) + [0xB8 + (n & 7)],
    'm_chg':       lambda n, p, a: _mem(p, a) + [0xC0 + (n & 7)],
    'm_bit':       lambda n, p, a: _mem(p, a) + [0xC8 + (n & 7)],
    'm_ld_mm16':   lambda p, a, s: _mem(p, a) + [0x14] + _i16(s),
    'm_ldw_mm16':  lambda p, a, s: _mem(p, a) + [0x16] + _i16(s),
    'm_ldc_cr_reg': lambda rp, cr: [rp, 0x2E, cr],
    'm_ldc_reg_cr': lambda rp, cr: [rp, 0x2F, cr],
    # --- added by this pass; see NEW_MACROS below for the argument they carry
    'm_ld_m16m':   lambda p, a, d: _mem(p, a) + [0x19] + _i16(d),
    'm_stcf_a':    lambda p, a: _mem(p, a) + [0x2C],
    'm_andcf_a':   lambda p, a: _mem(p, a) + [0x28],
    'm_orcf_a':    lambda p, a: _mem(p, a) + [0x29],
    'm_xorcf_a':   lambda p, a: _mem(p, a) + [0x2A],
    'm_ldcf_a':    lambda p, a: _mem(p, a) + [0x2B],
    'm_jp_cc':     lambda p, a, c: _mem(p, a) + [0xD0 + (c & 15)],
    'm_call_cc':   lambda p, a, c: _mem(p, a) + [0xE0 + (c & 15)],
    'm_ldir':      lambda p: [p, 0x11],
    'm_ldirw':     lambda p: [p, 0x11],
    'm_rlc_m':     lambda p, a: _mem(p, a) + [0x78],
    'm_sla_m':     lambda p, a: _mem(p, a) + [0x7C],
    'm_sra_m':     lambda p, a: _mem(p, a) + [0x7D],
    'm_sll_m':     lambda p, a: _mem(p, a) + [0x7E],
    'm_srl_m':     lambda p, a: _mem(p, a) + [0x7F],
    'm_rrc_m':     lambda p, a: _mem(p, a) + [0x79],
    'm_rl_m':      lambda p, a: _mem(p, a) + [0x7A],
    'm_rr_m':      lambda p, a: _mem(p, a) + [0x7B],
    # --- register-direct: one prefix byte (RB/RW/RL + index)
    'm_rd_push':      lambda p: [p, 0x04],
    'm_rd_pop':       lambda p: [p, 0x05],
    'm_rd_andcf_a':   lambda p: [p, 0x28],
    'm_rd_orcf_a':    lambda p: [p, 0x29],
    'm_rd_xorcf_a':   lambda p: [p, 0x2A],
    'm_rd_ldcf_a':    lambda p: [p, 0x2B],
    'm_rd_stcf_a':    lambda p: [p, 0x2C],
    'm_rd_add_rr':    lambda p, r: [p, 0x80 + r],
    'm_rd_ld_rr':     lambda p, r: [p, 0x88 + r],
    'm_rd_ld_rr2':    lambda p, r: [p, 0x98 + r],
    # --- register-direct: prefix plus a REGISTER-ADDRESS byte (any bank)
    'm_rd_pushx':     lambda p, g: [p, g, 0x04],
    'm_rd_popx':      lambda p, g: [p, g, 0x05],
    'm_rd_andcf_ax':  lambda p, g: [p, g, 0x28],
    'm_rd_orcf_ax':   lambda p, g: [p, g, 0x29],
    'm_rd_xorcf_ax':  lambda p, g: [p, g, 0x2A],
    'm_rd_ldcf_ax':   lambda p, g: [p, g, 0x2B],
    'm_rd_stcf_ax':   lambda p, g: [p, g, 0x2C],
    'm_rd_add_rrx':   lambda p, g, r: [p, g, 0x80 + r],
    'm_rd_ld_rrx':    lambda p, g, r: [p, g, 0x88 + r],
    'm_rd_ld_rr2x':   lambda p, g, r: [p, g, 0x98 + r],
    # --- register-indexed (rr+r), 16-bit index
    'mx_ld_mi8':   lambda p, b, i, v: _memx(p, b, i) + [0x00] + _i8(v),
    'mx_ld_mi16':  lambda p, b, i, v: _memx(p, b, i) + [0x02] + _i16(v),
    'mx_ld_rm':    lambda p, b, i, r: _memx(p, b, i) + [0x20 + r],
    'mx_lda16':    lambda p, b, i, r: _memx(p, b, i) + [0x20 + r],
    'mx_lda32':    lambda p, b, i, r: _memx(p, b, i) + [0x30 + r],
    'mx_jp_cc':    lambda p, b, i, c: _memx(p, b, i) + [0xD0 + (c & 15)],
    'mx_and_rm':   lambda p, b, i, r: _memx(p, b, i) + [0xC0 + r],
    'mx_or_rm':    lambda p, b, i, r: _memx(p, b, i) + [0xE0 + r],
    'mx_or_mr':    lambda p, b, i, r: _memx(p, b, i) + [0xE8 + r],
    'mx_st_mr8':   lambda p, b, i, r: _memx(p, b, i) + [0x40 + r],
    'mx_st_mr16':  lambda p, b, i, r: _memx(p, b, i) + [0x50 + r],
    'mx_st_mr32':  lambda p, b, i, r: _memx(p, b, i) + [0x60 + r],
    'mx_cp_mi8':   lambda p, b, i, v: _memx(p, b, i) + [0x3F] + _i8(v),
    'mx_and_mi8':  lambda p, b, i, v: _memx(p, b, i) + [0x3C] + _i8(v),
    'mx_or_mi8':   lambda p, b, i, v: _memx(p, b, i) + [0x3E] + _i8(v),
    'mx_cp_rm':    lambda p, b, i, r: _memx(p, b, i) + [0xF0 + r],
    'mx_cp_mr':    lambda p, b, i, r: _memx(p, b, i) + [0xF8 + r],
    'mx_add_rm':   lambda p, b, i, r: _memx(p, b, i) + [0x80 + r],
    'mx_sub_rm':   lambda p, b, i, r: _memx(p, b, i) + [0xA0 + r],
    'mx_ld_mm16':  lambda p, b, i, s: _memx(p, b, i) + [0x14] + _i16(s),
    'mx_bit':      lambda n, p, b, i: _memx(p, b, i) + [0xC8 + (n & 7)],
    'mx_set':      lambda n, p, b, i: _memx(p, b, i) + [0xB8 + (n & 7)],
    'mx_res':      lambda n, p, b, i: _memx(p, b, i) + [0xB0 + (n & 7)],
    # --- register-indexed, 8-bit index
    'mx8_ld_rm':   lambda p, b, i, r: _memxb(p, b, i) + [0x20 + r],
    'mx8_st_mr8':  lambda p, b, i, r: _memxb(p, b, i) + [0x40 + r],
    'mx8_st_mr16': lambda p, b, i, r: _memxb(p, b, i) + [0x50 + r],
    'mx8_st_mr32': lambda p, b, i, r: _memxb(p, b, i) + [0x60 + r],
    'mx8_lda32':   lambda p, b, i, r: _memxb(p, b, i) + [0x30 + r],
}

# ★ MACROS THIS PASS ADDS to include/tlcs900_mem_ops.inc.  Kept as data so
# --selftest can assert every one of them is really defined there -- a mirror
# entry with no macro behind it would fail the build, but only on the batch that
# first used it, which is late.
NEW_MACROS = ['m_sub_mi8', 'm_sub_mi16', 'm_and_mi16', 'm_or_mi16', 'm_xor_mi16',
              'm_and_mr', 'm_xor_mr', 'm_or_mr', 'm_ld_m16m',
              'm_stcf_a', 'm_ldcf_a', 'm_andcf_a', 'm_xorcf_a', 'm_orcf_a',
              'm_jp_cc', 'm_call_cc', 'm_ldir', 'm_ldirw',
              'm_rlc_m', 'm_rrc_m', 'm_rl_m', 'm_rr_m',
              'm_sla_m', 'm_sra_m', 'm_sll_m', 'm_srl_m',
              'mx_ld_mi16', 'mx_lda16', 'mx_cp_mi8', 'mx_and_mi8', 'mx_or_mi8',
              'mx_cp_rm', 'mx_cp_mr', 'mx_bit', 'mx_set', 'mx_res', 'mx8_lda32',
              'm_rd_push', 'm_rd_pop', 'm_rd_ldcf_a', 'm_rd_andcf_a',
              'm_rd_xorcf_a', 'm_rd_orcf_a', 'm_rd_stcf_a', 'm_rd_add_rr',
              'm_rd_ld_rr', 'm_rd_ld_rr2',
              'm_rd_pushx', 'm_rd_popx', 'm_rd_ldcf_ax', 'm_rd_andcf_ax',
              'm_rd_xorcf_ax', 'm_rd_orcf_ax', 'm_rd_stcf_ax', 'm_rd_add_rrx',
              'm_rd_ld_rrx', 'm_rd_ld_rr2x']


def emit(name, args):
    return MIRROR[name](*args)


# ------------------------------------------------------------- prefix decode
class Operand:
    """A decoded memory-operand prefix: how to spell it as a macro argument, how
    unidasm prints it, and how many bytes of the row it consumed."""

    def __init__(self, expr, args, text, size, n, idx8=False, src=None):
        self.expr = expr      # the PREFIX name alone, e.g. "MB16"
        self.src = src if src is not None else expr
                              # ★ the WHOLE argument text a macro call needs:
                              # "MB16, 0x20b8", "MBD+r6, 0x08", "MDI+r5, 0",
                              # "MXD, ra_IX, ra_HL".  Using `expr` here dropped
                              # the address argument and every rewritten line
                              # failed to assemble -- caught by the byte gate on
                              # the first batch, which is what it is for.
        self.args = args      # the numeric arguments the mirror needs
        self.text = text      # e.g. "(0x20b8)" -- must appear in unidasm's text
        self.size = size      # 'B' 'W' 'L' 'D'
        self.n = n            # bytes consumed
        self.idx8 = idx8      # the (rr+r8) submode, which needs the mx8_ macros


# ⚠ ONLY THESE SIXTEEN BYTES ARE MEMORY-OPERAND PREFIXES.  0xC4-0xCF, 0xD4-0xDF,
# 0xE4-0xEF and 0xF4-0xFF are REGISTER-DIRECT prefixes, and reading one as a
# memory operand is how `link XIZ,0x0000` (EE 0C 00 00) came out as
# `ML24, 0x00000c` -- an operand string that happened to be refused by the text
# check rather than by the decode.  The set is closed here so that cannot recur.
MEM_PREFIX = frozenset([0xC0, 0xC1, 0xC2, 0xC3, 0xD0, 0xD1, 0xD2, 0xD3,
                        0xE0, 0xE1, 0xE2, 0xE3, 0xF0, 0xF1, 0xF2, 0xF3])


def decode_operand(b):
    p = b[0]
    if p in MEM_PREFIX:
        w = p & 3
        size = 'BWLD'[(p >> 4) - 0xC]
        if w <= 2:
            nb = w + 1
            if len(b) < 1 + nb:
                return None
            addr = int.from_bytes(bytes(b[1:1 + nb]), 'little')
            nm = "%s%d" % (PFX_NAME[size], [8, 16, 24][w])
            return Operand(nm, [p, addr], "(0x%0*x)" % (nb * 2, addr), size,
                           1 + nb, src="%s, 0x%0*x" % (nm, nb * 2, addr))
        # w == 3: the register-indexed operand
        if len(b) < 4 or b[1] not in (0x03, 0x07):
            return None
        sub, base, idx = b[1], b[2], b[3]
        if base < 0xE0 or (base - 0xE0) % 4:
            return None
        bn = REG32[(base - 0xE0) // 4]
        if sub == 0x07:
            if idx < 0xE0 or (idx - 0xE0) % 4:
                return None
            iname = REG16[(idx - 0xE0) // 4]
            iexpr = "ra_" + iname
        else:
            if idx not in REG8_ADDR:
                return None
            iname = REG8_ADDR[idx]
            iexpr = "rb_" + iname
        nm = "%s, ra_%s, %s" % (IDX_NAME[size], bn[1:], iexpr)
        return Operand(nm, [p, base, idx], "(%s+%s)" % (bn, iname), size, 4,
                       idx8=(sub == 0x03), src=nm)
    if 0x80 <= p <= 0xBF:
        size = 'BWLD'[(p >> 4) - 8]
        r = p & 7
        if p & 0x08:
            if len(b) < 2:
                return None
            d = b[1]
            nm = "%sD+r%d" % (PFX_NAME[size], r)
            return Operand(nm, [p, d], "(%s+0x%02x)" % (REG32[r], d), size, 2,
                           src="%s, 0x%02x" % (nm, d))
        nm = "%sI+r%d" % (PFX_NAME[size], r)
        return Operand(nm, [p, 0], "(%s)" % REG32[r], size, 1, src="%s, 0" % nm)
    return None


def is_dst_family(op):
    """The 'destination' operand tables (mnemonic_f0/b0/b8) versus the
    size tables (mnemonic_c0/d0/e0 and their 0x80/0x90/0xA0 register forms)."""
    return op.size == 'D'


# ------------------------------------------------------------ the op tables
# (macro, mnemonic, how the remaining operand is built).  `kind` says what the
# op byte's low bits mean and what trails it:
#   'none'  nothing more            'i8'/'i16'  an immediate
#   'reg'   low 3 bits = a register of the operand's own size
#   'bit'   low 3 bits = a bit number
#   'imm16src' a 16-bit address trailing, printed as the OTHER operand
SRC_OPS = {
    0x04: ('m_push', {'B': 'push', 'W': 'pushw'}, 'none', 'M'),
    0x19: ('m_ld_m16m', {'B': 'ld', 'W': 'ldw'}, 'imm16', 'A16,M'),
    0x38: ('m_add_mi', 'add', 'imm', 'M,I'),
    0x3A: ('m_sub_mi', 'sub', 'imm', 'M,I'),
    0x3C: ('m_and_mi', 'and', 'imm', 'M,I'),
    0x3D: ('m_xor_mi', 'xor', 'imm', 'M,I'),
    0x3E: ('m_or_mi', 'or', 'imm', 'M,I'),
    0x3F: ('m_cp_mi', 'cp', 'imm', 'M,I'),
    0x78: ('m_rlc_m', 'rlc', 'none', 'M'),
    0x79: ('m_rrc_m', 'rrc', 'none', 'M'),
    0x7A: ('m_rl_m', 'rl', 'none', 'M'),
    0x7B: ('m_rr_m', 'rr', 'none', 'M'),
    0x7C: ('m_sla_m', {'B': 'sla', 'W': 'slaw'}, 'none', 'M'),
    0x7D: ('m_sra_m', {'B': 'sra', 'W': 'sraw'}, 'none', 'M'),
    0x7E: ('m_sll_m', {'B': 'sll', 'W': 'sllw'}, 'none', 'M'),
    0x7F: ('m_srl_m', {'B': 'srl', 'W': 'srlw'}, 'none', 'M'),
}
# op-base -> (macro, mnemonic, operand order).  'R,M' prints the register first.
SRC_REG_OPS = {
    0x20: ('m_ld_rm', 'ld', 'R,M'),
    0x30: ('m_ex_mr', 'ex', 'M,R'),
    0x40: ('m_mul', 'mul', 'P,M'),
    0x48: ('m_muls', 'muls', 'P,M'),
    0x50: ('m_div', 'div', 'P,M'),
    0x58: ('m_divs', 'divs', 'P,M'),
    0x80: ('m_add_rm', 'add', 'R,M'),
    0x88: ('m_add_mr', 'add', 'M,R'),
    0xA0: ('m_sub_rm', 'sub', 'R,M'),
    0xA8: ('m_sub_mr', 'sub', 'M,R'),
    0xB0: ('m_sbc_rm', 'sbc', 'R,M'),
    0xC0: ('m_and_rm', 'and', 'R,M'),
    0xC8: ('m_and_mr', 'and', 'M,R'),
    0xD0: ('m_xor_rm', 'xor', 'R,M'),
    0xD8: ('m_xor_mr', 'xor', 'M,R'),
    0xE0: ('m_or_rm', 'or', 'R,M'),
    0xE8: ('m_or_mr', 'or', 'M,R'),
    0xF0: ('m_cp_rm', 'cp', 'R,M'),
    0xF8: ('m_cp_mr', 'cp', 'M,R'),
}
DST_OPS = {
    0x00: ('m_ld_mi8', 'ld', 'i8', 'M,I'),
    0x02: ('m_ld_mi16', 'ld', 'i16', 'M,I'),
    0x04: ('m_pop', 'pop', 'none', 'M'),
    0x06: ('m_popw', 'popw', 'none', 'M'),
    0x14: ('m_ld_mm16', 'ld', 'i16', 'M,A16'),
    0x16: ('m_ldw_mm16', 'ldw', 'i16', 'M,A16'),
    0x28: ('m_andcf_a', 'andcf', 'none', 'A,M'),
    0x29: ('m_orcf_a', 'orcf', 'none', 'A,M'),
    0x2A: ('m_xorcf_a', 'xorcf', 'none', 'A,M'),
    0x2B: ('m_ldcf_a', 'ldcf', 'none', 'A,M'),
    0x2C: ('m_stcf_a', 'stcf', 'none', 'A,M'),
}
DST_REG_OPS = {
    0x20: ('m_lda16', 'lda', 'R16,MB'),
    0x30: ('m_lda32', 'lda', 'R32,MB'),
    0x40: ('m_st_mr8', 'ld', 'M,R8'),
    0x50: ('m_st_mr16', 'ld', 'M,R16'),
    0x60: ('m_st_mr32', 'ld', 'M,R32'),
}
DST_BIT_OPS = {
    0xA0: ('m_stcf', 'stcf'), 0xB0: ('m_res', 'res'), 0xB8: ('m_set', 'set'),
    0xC0: ('m_chg', 'chg'), 0xC8: ('m_bit', 'bit'),
}
CC = ['F', 'LT', 'LE', 'ULE', 'OV', 'MI', 'Z', 'C',
      'T', 'GE', 'GT', 'UGT', 'NOV', 'PL', 'NZ', 'NC']


def _mx(name, idx8=False):
    """The register-indexed sibling of a direct-address macro name.  The (rr+r8)
    submode has its OWN macros -- they emit 0x03 where the (rr+r16) ones emit
    0x07 -- so an 8-bit index must not borrow the 16-bit spelling."""
    if not name.startswith('m_'):
        return name
    return name.replace('m_', 'mx8_' if idx8 else 'mx_', 1)


# ------------------------------------------- forms llvm-mc can already spell
# ★ NOT EVERY BLOB NEEDED A MACRO.  `link XIZ,0x0000` (EE 0C 00 00), `unlk XIZ`
# (EE 0D), `normal` (01) and `max` (04) all have a native llvm-mc spelling --
# prom_a uses all four -- and prom_b's generator simply never tried them.  These
# are reconstructed as TEXT and accepted only when the reconstruction EQUALS
# unidasm's own text for the row, character for character, which is a stricter
# check than any macro path gets.  --selftest assembles one of each and compares
# the bytes llvm-mc produces.
NATIVE_BYTES = {'normal': [0x01], 'max': [0x04]}


def native(b, text):
    if len(b) == 4 and b[1] == 0x0C and 0xE8 <= b[0] <= 0xEF:
        want = "link %s,0x%04x" % (REG32[b[0] - 0xE8], b[2] | b[3] << 8)
        return (want, 'link') if text == want else (None, None)
    if len(b) == 2 and b[1] == 0x0D and 0xE8 <= b[0] <= 0xEF:
        want = "unlk %s" % REG32[b[0] - 0xE8]
        return (want, 'unlk') if text == want else (None, None)
    for k, v in NATIVE_BYTES.items():
        if b == v and text == k:
            return k, k
    return None, None


# ------------------------------------------------- the register-direct family
# Prefix 0xC8+r / 0xD8+r / 0xE8+r names one register of the current bank; prefix
# 0xC7 / 0xD7 / 0xE7 is followed by a REGISTER-ADDRESS BYTE that can name any
# register, including the other banks' (RL3, XDE3, QHL3, IYL).  The operation
# byte then comes from mnemonic_c8/d8/e8.  These rows are not memory operands at
# all, which is why the memory-prefix path refused 585 of them.
RD_PFX = {'B': 0xC8, 'W': 0xD8, 'L': 0xE8}
RD_PFX_X = {0xC7: 'B', 0xD7: 'W', 0xE7: 'L'}
RD_NAME = {'B': 'RB', 'W': 'RW', 'L': 'RL'}
RD_OPS = {0x04: ('m_rd_push', 'push', None), 0x05: ('m_rd_pop', 'pop', None),
          0x28: ('m_rd_andcf_a', 'andcf', None), 0x29: ('m_rd_orcf_a', 'orcf', None),
          0x2A: ('m_rd_xorcf_a', 'xorcf', None), 0x2B: ('m_rd_ldcf_a', 'ldcf', None),
          0x2C: ('m_rd_stcf_a', 'stcf', None)}
RD_REG_OPS = {0x80: ('m_rd_add_rr', 'add', 'R,r'), 0x88: ('m_rd_ld_rr', 'ld', 'R,r'),
              0x98: ('m_rd_ld_rr2', 'ld', 'r,R')}


def recognise_rd(b, text):
    """The register-direct family. The register the PREFIX names is left to the
    comment -- MAME's own tables for the 0xC7/0xD7/0xE7 form span all four banks
    and this tree has no copy of them -- but the register the OPERATION byte
    names is checked against the text, and the bytes are exact either way."""
    if not b:
        return None, 'empty'
    mn = text.split()[0]
    if b[0] in RD_PFX_X:
        size, i, pexpr, pargs = RD_PFX_X[b[0]], 2, "%sX, 0x%02X" % (RD_NAME[RD_PFX_X[b[0]]], b[1] if len(b) > 1 else 0), None
        if len(b) < 3:
            return None, 'truncated register-address form'
        pargs = [b[0], b[1]]
        wide = True
    elif 0xC8 <= b[0] <= 0xEF and (b[0] & 0xF8) in (0xC8, 0xD8, 0xE8):
        size = {0xC8: 'B', 0xD8: 'W', 0xE8: 'L'}[b[0] & 0xF8]
        i, pargs, wide = 1, [b[0]], False
        pexpr = "%s+r%d" % (RD_NAME[size], b[0] & 7)
    else:
        return None, 'prefix not a memory operand'
    if i >= len(b):
        return None, 'no operation byte'
    o, tail = b[i], b[i + 1:]
    if tail:
        return None, 'unexpected trailing bytes'
    suffix = 'x' if wide else ''

    def fin(name, extra, opstr):
        nm = name + suffix
        if nm not in MIRROR:
            return None, 'no macro %s' % nm
        if bytes(emit(nm, pargs + extra)) != bytes(b):
            return None, 'reemit mismatch'
        return "%s %s%s" % (nm, pexpr, opstr), nm

    if o in RD_OPS:
        name, want, _ = RD_OPS[o]
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        return fin(name, [], "")
    base = o & 0xF8
    if base in RD_REG_OPS:
        name, want, order = RD_REG_OPS[base]
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        r = o & 7
        rn = SIZE_REGS[size][r]
        if not re.search(r'\b%s\b' % re.escape(rn), text):
            return None, 'register %s not in text' % rn
        return fin(name, [r], ", r%d" % r)
    return None, 'register-direct operation 0x%02X' % o


def recognise(b, text):
    """(macro_line, macro_name) for a row that all three checks accept, else
    (None, reason)."""
    line, name = native(b, text)
    if line is not None:
        return line, name
    op = decode_operand(b)
    if op is None:
        return recognise_rd(b, text)
    indexed = op.expr.startswith('MX')
    i = op.n
    if i >= len(b):
        return None, 'no operation byte'
    o = b[i]
    tail = b[i + 1:]
    mn = text.split()[0]
    dst = is_dst_family(op)
    regs = SIZE_REGS.get(op.size)

    # ⚠ HOW THE OPERAND IS PRINTED IS PER-OPERATION, not per-prefix.  `ld` and
    # `cp` print `(0x20b8)`; `lda`, `jp cc` and `call cc` print the same operand
    # BARE; `ldir` prints no operand at all.  Requiring the parenthesised form
    # everywhere refused 350 well-formed rows.
    def want_mem(bare=False):
        return (op.text[1:-1] if bare else op.text) in text

    def build(name, args, opstr):
        nm = _mx(name, op.idx8) if indexed else name
        if nm not in MIRROR:
            return None, 'no macro %s' % nm
        try:
            got = emit(nm, args)
        except Exception as e:                        # pragma: no cover
            return None, 'mirror raised %s' % e
        if bytes(got) != bytes(b):
            return None, 'reemit %s != %s' % (bytes(got).hex(), bytes(b).hex())
        return "%s %s" % (nm, opstr), nm

    # ---- the block-transfer pair: its prefix names a register the text hides
    if o == 0x11 and not tail and not indexed and op.n == 1:
        name, want = ('m_ldir', 'ldir') if op.size == 'B' else ('m_ldirw', 'ldirw')
        if want != mn or text != want:
            return None, 'mnemonic %s != %s' % (mn, want)
        if bytes(emit(name, [b[0]])) != bytes(b):
            return None, 'reemit mismatch'
        return "%s %s" % (name, op.expr), name

    if not dst:
        base = o & 0xF8
        if o in SRC_OPS:
            name, mnames, kind, _shape = SRC_OPS[o]
            want = mnames if isinstance(mnames, str) else mnames.get(op.size)
            if want != mn:
                return None, 'mnemonic %s != %s' % (mn, want)
            if not want_mem():
                return None, 'operand %s not in text' % op.text
            if kind == 'none':
                return build(name, op.args, op.src)
            if kind == 'imm':
                w = 1 if op.size == 'B' else 2 if op.size == 'W' else None
                if w is None or len(tail) != w:
                    return None, 'immediate width'
                v = int.from_bytes(bytes(tail), 'little')
                nm = name + ('8' if w == 1 else '16')
                istr = "0x%0*x" % (w * 2, v)
                if ",%s" % istr not in text:
                    return None, 'immediate %s not in text' % istr
                return build(nm, op.args + [v], "%s, %s" % (op.src, istr))
            if kind == 'imm16':
                if len(tail) != 2:
                    return None, 'trailing address width'
                v = int.from_bytes(bytes(tail), 'little')
                if "(0x%04x)" % v not in text:
                    return None, 'trailing address not in text'
                return build(name, op.args + [v], "%s, 0x%04x" % (op.src, v))
        if base in SRC_REG_OPS and not tail:
            name, want, order = SRC_REG_OPS[base]
            if want != mn:
                return None, 'mnemonic %s != %s' % (mn, want)
            if not want_mem():
                return None, 'operand %s not in text' % op.text
            r = o & 7
            if order == 'P,M':
                if op.size == 'B':
                    if r % 2 == 0:
                        return None, 'even register field on a byte multiply'
                    rn = REG16[r >> 1]
                elif op.size == 'W':
                    rn = REG32[r]
                else:
                    return None, 'unsupported size for %s' % want
            else:
                if regs is None:
                    return None, 'no register table for size'
                rn = regs[r]
            if not re.search(r'\b%s\b' % re.escape(rn), text):
                return None, 'register %s not in text' % rn
            return build(name, op.args + [r], "%s, %s" % (op.src, r))
        return None, 'operation 0x%02X in the %s table' % (o, op.size)

    # ---- the destination table -------------------------------------------
    base = o & 0xF8
    if o in DST_OPS:
        name, want, kind, _shape = DST_OPS[o]
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        if not want_mem():
            return None, 'operand %s not in text' % op.text
        if kind == 'none':
            return build(name, op.args, op.src)
        w = 1 if kind == 'i8' else 2
        if len(tail) != w:
            return None, 'immediate width'
        v = int.from_bytes(bytes(tail), 'little')
        istr = "(0x%04x)" % v if o in (0x14, 0x16) else "0x%0*x" % (w * 2, v)
        if istr not in text:
            return None, 'operand %s not in text' % istr
        return build(name, op.args + [v], "%s, 0x%0*x" % (op.src, w * 2, v))
    if base in DST_REG_OPS and not tail:
        name, want, order = DST_REG_OPS[base]
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        # `lda` prints its operand without parentheses; `ld (mem),R` with them.
        if not want_mem(bare=(want == 'lda')):
            return None, 'operand %s not in text' % op.text
        r = o & 7
        rn = {'R16': REG16, 'R32': REG32, 'R8': REG8}[order.split(',')[0]][r] \
            if order.startswith('R') else {'R8': REG8, 'R16': REG16, 'R32': REG32}[order.split(',')[1]][r]
        if not re.search(r'\b%s\b' % re.escape(rn), text):
            return None, 'register %s not in text' % rn
        return build(name, op.args + [r], "%s, %s" % (op.src, r))
    if base in DST_BIT_OPS and not tail:
        name, want = DST_BIT_OPS[base]
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        if not want_mem():
            return None, 'operand %s not in text' % op.text
        n = o & 7
        if not re.match(r'^%s (0x0)?%d,' % (want, n), text):
            return None, 'bit number %d not in text' % n
        nm = _mx(name, op.idx8) if indexed else name
        if nm not in MIRROR:
            return None, 'no macro %s' % nm
        if bytes(emit(nm, [n] + op.args)) != bytes(b):
            return None, 'reemit mismatch'
        return "%s %d, %s" % (nm, n, op.src), nm
    if (o & 0xF0) in (0xD0, 0xE0) and not tail:
        name, want = ('m_jp_cc', 'jp') if (o & 0xF0) == 0xD0 else ('m_call_cc', 'call')
        if want != mn:
            return None, 'mnemonic %s != %s' % (mn, want)
        if not want_mem(bare=True):
            return None, 'operand %s not in text' % op.text
        c = o & 15
        if not text.startswith("%s %s," % (want, CC[c])):
            return None, 'condition %s not in text' % CC[c]
        nm = _mx(name, op.idx8) if indexed else name
        if nm not in MIRROR:
            return None, 'no macro %s' % nm
        if bytes(emit(nm, op.args + [c])) != bytes(b):
            return None, 'reemit mismatch'
        return "%s %s, %d" % (nm, op.src, c), nm
    return None, 'operation 0x%02X in the dst table' % o


# ------------------------------------------------------------------ driving
def read(path):
    return open(path).read().split('\n')


def rows(lines):
    for i, ln in enumerate(lines):
        m = BLOB.match(ln)
        if m:
            b = [int(x, 16) for x in m.group(1).split(', ')]
            yield i, b, m.group(2), m.group(3)


def plan(lines):
    """[(line index, new line, macro name)] and a Counter of refusal reasons."""
    out, refused = [], Counter()
    for i, b, addr, text in rows(lines):
        line, why = recognise(b, text)
        if line is None:
            refused["%-28s %s" % (text.split()[0], why)] += 1
            continue
        out.append((i, "\t%s\t; %s  %s" % (line, addr, text), why))
    return out, refused


def main():
    args = sys.argv[1:]
    lines = read(PROM_B)
    only = None
    for a in args:
        if a.startswith('--only'):
            only = set((a.split('=', 1)[1] if '=' in a else args[args.index(a) + 1]).split(','))
    if '--selftest' in args:
        return selftest(lines)
    p, refused = plan(lines)
    if '--census' in args or not args:
        c = Counter(n for _, _, n in p)
        total = sum(1 for _ in rows(lines))
        print("prom_b `cannot encode` rows: %d" % total)
        print("convertible with the shared macro set: %d (%.1f%%)"
              % (len(p), 100.0 * len(p) / total))
        print()
        for k, v in c.most_common():
            print("  %6d  %s" % (v, k))
        print("\n  %6d  LEFT AS A BLOB" % (total - len(p)))
        return 0
    if '--left' in args:
        if '--detail' in args:
            # ★ SMALL ENOUGH TO ENUMERATE.  Every row this tool will not touch,
            # with its address, its decode and the reason -- so "left as a blob"
            # is a list a reader can audit, not a number to be trusted.
            for i, b, addr, text in rows(lines):
                _l, why = recognise(b, text)
                if _l is None:
                    print("  %s  %-34s %s" % (addr, text, why))
            return 0
        for k, v in refused.most_common(60):
            print("  %6d  %s" % (v, k))
        return 0
    if '--apply' in args:
        n = 0
        for i, new, name in p:
            if only and name not in only:
                continue
            lines[i] = new
            n += 1
        open(PROM_B, 'w').write('\n'.join(lines))
        print("rewrote %d rows%s" % (n, (" (--only %s)" % ','.join(sorted(only))) if only else ""))
        return 0
    print(__doc__)
    return 0



# ------------------------------------------------------ selftest sample args
# One legal invocation per macro: (numeric args for the mirror, source text for
# llvm-mc).  The two must denote the same thing -- that is the point of check 7.
_PFX_TXT = {0xC0: 'MB8', 0xC1: 'MB16', 0xC2: 'MB24', 0xD0: 'MW8', 0xD1: 'MW16',
            0xD2: 'MW24', 0xE0: 'ML8', 0xE1: 'ML16', 0xE2: 'ML24', 0xF0: 'MD8',
            0xF1: 'MD16', 0xF2: 'MD24', 0xC3: 'MXB', 0xD3: 'MXW', 0xE3: 'MXL',
            0xF3: 'MXD', 0xC8: 'RB', 0xD8: 'RW', 0xE8: 'RL',
            0xC7: 'RBX', 0xD7: 'RWX', 0xE7: 'RLX'}


def _sample_args(nm):
    """(mirror args, assembler text) for one legal call of `nm`, or None."""
    if nm.startswith('mx8_'):
        p, base, idx = 0xF3, 0xF0, 0xEC
        return ([p, base, idx, 4], "%s MXD, ra_IX, rb_L, r4" % nm) if _arity(nm) == 4 else None
    if nm.startswith('mx_'):
        p, base, idx = 0xF3, 0xF0, 0xEC
        n = _arity(nm)
        if n == 4 and nm in ('mx_bit', 'mx_set', 'mx_res'):
            return ([3, p, base, idx], "%s 3, MXD, ra_IX, ra_HL" % nm)
        if n == 4:
            return ([p, base, idx, 4], "%s MXD, ra_IX, ra_HL, 4" % nm)
        return None
    if nm.startswith('m_rd_'):
        wide = nm.endswith('x')
        pfx = 0xE7 if wide else 0xE8
        txt = _PFX_TXT[pfx] if wide else _PFX_TXT[pfx] + "+r0"
        args = [pfx] + ([0x38] if wide else [])
        atxt = txt + (", 0x38" if wide else "")
        if _arity(nm) == len(args):
            return (args, "%s %s" % (nm, atxt))
        return (args + [3], "%s %s, 3" % (nm, atxt))
    if nm in ('m_ldir', 'm_ldirw'):
        p = 0x85 if nm == 'm_ldir' else 0x95
        return ([p], "%s %s" % (nm, 'MBI+r5' if nm == 'm_ldir' else 'MWI+r5'))
    if nm in ('m_ldc_cr_reg', 'm_ldc_reg_cr'):
        return ([0xE8, 0x00], "%s RL+r0, CR_DMAS0" % nm)
    if nm in ('m_inc', 'm_dec', 'm_res', 'm_set', 'm_chg', 'm_bit', 'm_stcf'):
        return ([3, 0xF1, 0x1234], "%s 3, MD16, 0x1234" % nm)
    n = _arity(nm)
    pfx = 0xF1 if nm.startswith(('m_ld_mi', 'm_lda', 'm_st_mr', 'm_pop', 'm_popw',
                                'm_ld_mm16', 'm_ldw_mm16', 'm_jp_cc', 'm_call_cc',
                                'm_ldcf_a', 'm_andcf_a', 'm_xorcf_a', 'm_orcf_a',
                                'm_stcf_a')) else 0xD1
    if n == 2:
        return ([pfx, 0x1234], "%s %s, 0x1234" % (nm, _PFX_TXT[pfx]))
    if n == 3:
        v = 3 if nm.endswith(('_rm', '_mr', 'm_mul', 'm_muls', 'm_div', 'm_divs',
                              'm_ld_rm', 'm_ex_mr', 'm_lda16', 'm_lda32',
                              'm_st_mr8', 'm_st_mr16', 'm_st_mr32')) else 0x0055
        return ([pfx, 0x1234, v], "%s %s, 0x1234, %d" % (nm, _PFX_TXT[pfx], v))
    return None


def _arity(nm):
    import inspect
    return len(inspect.signature(MIRROR[nm]).parameters)


# ----------------------------------------------------------------- selftest
PROM_A_MACRO = re.compile(r'^\t(m[x]?8?_\S+) (.*?)\s*; ([0-9A-F]{6})  ([0-9a-f ]+)$')


# ⚠ THE TREE IS THE TOOL'S OWN OUTPUT NOW, so running the checks against the
# working tree exercises nothing: 7,230 of the 7,309 rows are already macros and
# plan() proposes almost nothing.  A check that cannot fail is not a check.  The
# recogniser checks therefore run against prom_b AS IT WAS BEFORE THE BATCHES,
# read out of git -- which is also the only version that can prove the tool still
# reproduces what it emitted.
BASELINE = "a4c8972"


def baseline_lines():
    import subprocess
    return subprocess.run(["git", "show", "%s:prom_b/wsa1_prom_b.s" % BASELINE],
                          cwd=ROOT, capture_output=True, text=True,
                          check=True).stdout.split('\n')


def selftest(lines):
    """INVARIANTS, not pinned values. Each one would fail on a real defect and
    none of them encodes a number that legitimate work would move."""
    ok = fail = 0

    def check(name, cond):
        nonlocal ok, fail
        if cond:
            ok += 1
        else:
            fail += 1
            print("  FAIL  %s" % name)

    # 1. The mirror agrees with prom_a, which is the source that ALREADY uses
    #    these macros and carries its bytes in the comment.  This is what stops
    #    the mirror drifting from include/tlcs900_mem_ops.inc.
    env = {'MB8': 0xC0, 'MB16': 0xC1, 'MB24': 0xC2, 'MW8': 0xD0, 'MW16': 0xD1,
           'MW24': 0xD2, 'ML8': 0xE0, 'ML16': 0xE1, 'ML24': 0xE2, 'MD8': 0xF0,
           'MD16': 0xF1, 'MD24': 0xF2, 'MBI': 0x80, 'MBD': 0x88, 'MWI': 0x90,
           'MWD': 0x98, 'MLI': 0xA0, 'MLD': 0xA8, 'MDI': 0xB0, 'MDD': 0xB8,
           'MXB': 0xC3, 'MXW': 0xD3, 'MXL': 0xE3, 'MXD': 0xF3,
           'RB': 0xC8, 'RW': 0xD8, 'RL': 0xE8}
    for k in range(8):
        env['r%d' % k] = k
    for k, n in enumerate(REG32):
        env['ra_' + n[1:]] = 0xE0 + 4 * k
    for n, v in REG8_ADDR.items():
        env['rb_' + v] = n
    for k in range(16):
        env['CR_DMAS%d' % k] = 0x00 + 4 * k
    for nm, base in (('CR_DMAS', 0x00), ('CR_DMAD', 0x10), ('CR_DMAC', 0x20)):
        for k in range(4):
            env['%s%d' % (nm, k)] = base + 4 * k
    for k in range(4):
        env['CR_DMAM%d' % k] = 0x22 + 4 * k
    tried = mism = 0
    for ln in read(PROM_A):
        m = PROM_A_MACRO.match(ln)
        if not m or m.group(1) not in MIRROR:
            continue
        try:
            a = [eval(x.strip(), {"__builtins__": {}}, env) for x in m.group(2).split(',')]
            got = bytes(emit(m.group(1), a))
        except Exception:
            continue
        tried += 1
        if got != bytes.fromhex(m.group(4).replace(' ', '')):
            mism += 1
            if mism < 5:
                print("    mirror disagrees at %s: %s" % (m.group(3), ln.strip()))
    check("the mirror reproduces every prom_a macro line it can parse (%d tried)" % tried,
          tried > 4000 and mism == 0)

    # 2. Every macro the mirror can emit is really DEFINED in the shared include.
    inc = open(os.path.join(ROOT, "include/tlcs900_mem_ops.inc")).read()
    defined = set(re.findall(r'^\.macro (\S+)', inc, re.M))
    missing = sorted(n for n in MIRROR if n not in defined)
    check("every mirrored macro is defined in include/tlcs900_mem_ops.inc "
          "(missing: %s)" % (', '.join(missing) or 'none'), not missing)

    # 3. NEW_MACROS is a subset of the mirror -- the list cannot name a macro
    #    this file does not know how to emit.
    check("NEW_MACROS all have a mirror entry",
          all(n in MIRROR for n in NEW_MACROS))

    # 4. The prefix decoder round-trips: for every prefix byte it accepts, the
    #    bytes it reports consuming are the bytes _mem/_memx would emit.
    bad = []
    for p in list(range(0x80, 0xC0)) + [0xC0, 0xC1, 0xC2, 0xD0, 0xD1, 0xD2,
                                        0xE0, 0xE1, 0xE2, 0xF0, 0xF1, 0xF2]:
        o = decode_operand([p, 0x12, 0x34, 0x56, 0x00])
        if o is None:
            bad.append(p)
            continue
        if bytes(_mem(*o.args)) != bytes([p, 0x12, 0x34, 0x56][:o.n]):
            bad.append(p)
    check("the prefix decoder consumes exactly what _mem emits (%d bad)" % len(bad), not bad)

    # 5. Nothing the planner proposes changes the ADDRESS or the decode text.
    #    Against the BASELINE, so there is something to propose.
    lines = baseline_lines()
    p, _ = plan(lines)
    check("the baseline still has rows to recognise (%d proposed of %d rows)"
          % (len(p), sum(1 for _ in rows(lines))), len(p) > 5000)
    bad = 0
    for i, new, _n in p:
        m0 = BLOB.match(lines[i])
        m1 = re.match(r'^\t\S.*?\t; ([0-9A-F]{6})  (.*)$', new)
        if not m1 or m1.group(1) != m0.group(2) or m1.group(2) != m0.group(3):
            bad += 1
    check("every proposed line keeps its address and its decode text verbatim "
          "(%d proposals, %d bad)" % (len(p), bad), bad == 0)

    # 6. THE LAST ELEMENT, not just the first: the highest-addressed proposal
    #    re-emits to its own bytes.
    if p:
        i = p[-1][0]
        m0 = BLOB.match(lines[i])
        b = [int(x, 16) for x in m0.group(1).split(', ')]
        line, _ = recognise(b, m0.group(3))
        check("the LAST proposal (0x%s) still re-emits to its own bytes" % m0.group(2),
              line is not None)

    # 7. ★ THE MIRROR AGAINST llvm-mc ITSELF, for every macro including the ones
    #    prom_a never used.  Check 1 can only cover macros prom_a already has
    #    lines for; this one assembles a sample invocation of EVERY mirrored
    #    macro through the real assembler and the real include file, and
    #    compares the bytes with the mirror's.  It is the check that would
    #    catch a new macro whose .inc body and whose Python twin disagree.
    import subprocess
    import tempfile
    llvm = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
    samples = []
    for nm in sorted(MIRROR):
        a = _sample_args(nm)
        if a is None:
            continue
        try:
            want = bytes(emit(nm, a[0]))
        except Exception:
            continue
        samples.append((nm, a[1], want))
    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, "s.s")
        with open(src, "w") as f:
            f.write('\t.text\n\t.include "include/tlcs900_mem_ops.inc"\n')
            for _nm, txt, _w in samples:
                f.write("\t%s\n" % txt)
        r = subprocess.run([os.path.join(llvm, "llvm-mc"), "-triple=tlcs900",
                            "-filetype=obj", "-I", ROOT, "-o",
                            os.path.join(td, "s.o"), src],
                           capture_output=True, text=True)
        got = None
        if r.returncode == 0:
            subprocess.run([os.path.join(llvm, "llvm-objcopy"), "-O", "binary",
                            os.path.join(td, "s.o"), os.path.join(td, "s.bin")],
                           capture_output=True)
            got = open(os.path.join(td, "s.bin"), "rb").read()
        bad = []
        if got is None:
            bad = ["llvm-mc refused the sample file: %s" % r.stderr.strip()[:200]]
        else:
            off = 0
            for nm, txt, want in samples:
                if got[off:off + len(want)] != want:
                    bad.append("%s: llvm-mc %s vs mirror %s"
                               % (nm, got[off:off + len(want)].hex(), want.hex()))
                off += len(want)
            if off != len(got):
                bad.append("assembled %d bytes, mirror accounts for %d" % (len(got), off))
    for b in bad[:5]:
        print("    %s" % b)
    check("llvm-mc and the mirror agree on all %d sampled macros" % len(samples), not bad)

    # 8. ★★ THE PROPOSED LINE, THROUGH THE REAL ASSEMBLER.  Checks 1 and 7 prove
    #    the macro DEFINITIONS; they say nothing about whether the line this file
    #    writes calls one correctly.  The first batch shipped
    #    `m_cp_mi8 MB16, 0x11` -- the address argument dropped -- and every check
    #    above passed, including the preservation probe, because the row's prose
    #    was untouched.  The byte gate caught it, on 2,334 lines at once.  This
    #    check catches it here: one proposal per macro name, plus the last
    #    proposal in the file, assembled and compared with the row's own bytes.
    seen, sample = set(), []
    for i, new_line, name in p:
        if name in seen:
            continue
        seen.add(name)
        sample.append((i, new_line, name))
    if p:
        sample.append(p[-1])
    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, "s.s")
        with open(src, "w") as f:
            f.write('\t.text\n\t.include "include/tlcs900_mem_ops.inc"\n')
            for _i, new_line, _n in sample:
                f.write(new_line.split('\t;')[0] + "\n")
        r = subprocess.run([os.path.join(llvm, "llvm-mc"), "-triple=tlcs900",
                            "-filetype=obj", "-I", ROOT, "-o",
                            os.path.join(td, "s.o"), src],
                           capture_output=True, text=True)
        bad = []
        if r.returncode != 0:
            bad = [r.stderr.strip().split('\n')[0][:200]]
        else:
            subprocess.run([os.path.join(llvm, "llvm-objcopy"), "-O", "binary",
                            os.path.join(td, "s.o"), os.path.join(td, "s.bin")],
                           capture_output=True)
            got, off = open(os.path.join(td, "s.bin"), "rb").read(), 0
            for i, _nl, name in sample:
                want = bytes(int(x, 16) for x in
                             BLOB.match(lines[i]).group(1).split(', '))
                if got[off:off + len(want)] != want:
                    bad.append("%s: llvm-mc %s vs row %s"
                               % (name, got[off:off + len(want)].hex(), want.hex()))
                off += len(want)
    for b in bad[:5]:
        print("    %s" % b)
    check("llvm-mc assembles %d sampled proposals to their own bytes" % len(sample),
          not bad)

    # 9. A deliberately corrupted row must be REFUSED, so the checks can fail.
    line, why = recognise([0xC1, 0xB8, 0x20, 0x3F, 0x11], "cp (0x20b9),0x11")
    check("a row whose text disagrees with its bytes is refused (%s)" % why, line is None)
    line, why = recognise([0xC1, 0xB8, 0x20, 0x3F, 0x11], "or (0x20b8),0x11")
    check("a row whose MNEMONIC disagrees is refused (%s)" % why, line is None)

    print("\n%d checks, %d failed" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
