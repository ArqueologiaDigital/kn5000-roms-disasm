#!/usr/bin/env python3
"""prom_a byte-range -> llvm-mc assembly text, certified by re-assembly.

QUESTION IT ANSWERS: "what source text, fed to llvm-mc -triple=tlcs900,
assembles back to exactly the bytes at 0xF8xxxx..0xF8yyyy?"

Same discipline as ../kn5000-roms-disasm/scripts/converters/roundtrip_byte_blocks.py:
nothing is emitted that has not already been assembled and compared byte for byte,
so this tool cannot break the gate.  It says nothing about what the code MEANS --
labels and comments are added by hand afterwards.

METHOD
  1. unidasm (MAME's disassembler) supplies the instruction BOUNDARIES: it prints
     address + raw bytes + text.  It is also the DECODE AUTHORITY -- its text is
     what the header comments are written from.
  2. Four candidate spellings are tried per instruction, in order:
       (a) unidasm's own text            -- the readable one
       (b) llvm-mc's disassembler text   -- guaranteed to be in llvm-mc's dialect
       (c) a macro from the MACRO PRELUDE inside prom_a/wsa1_prom_a.s, for the
           8-bit-direct "(n)" operand forms that llvm-mc's tlcs900 backend has no
           encoding for (see that prelude for why, and for the encoding source)
       (d) .byte -- give up, keep the bytes, with unidasm's text in a comment
  3. Each candidate is assembled with `llvm-mc --show-encoding` (the macro prelude
     is prepended, so macro candidates resolve) and compared byte for byte.

USAGE
    python3 prom_a/roundtrip.py 0xF82CFF 0xF82D60          # emit assembly
    python3 prom_a/roundtrip.py 0xF82CFF 0xF82D60 --stats  # + strategy counts
    python3 prom_a/roundtrip.py 0xF82CFF 0xF82D60 --survey # only the failures,
                                                           # grouped by form
"""
import re
import subprocess
import sys
import os
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
BASE = 0xF80000

PRELUDE_BEGIN = "; MACRO-PRELUDE-BEGIN"
PRELUDE_END = "; MACRO-PRELUDE-END"


def macro_prelude():
    """The .macro block from wsa1_prom_a.s, so this tool and the ROM source
    can never disagree about what a macro emits."""
    try:
        text = open(SRC).read()
    except OSError:
        return ""
    i = text.find(PRELUDE_BEGIN)
    j = text.find(PRELUDE_END)
    if i < 0 or j < 0:
        return ""
    return text[i:j]


def unidasm_range(start, end):
    """[(addr, bytes, text)] for the instructions in [start,end)."""
    data = open(ROM, "rb").read()[start - BASE:end - BASE]
    tmp = "/tmp/wsa1_rt_%d.bin" % os.getpid()
    open(tmp, "wb").write(data)
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(start)],
                         capture_output=True, text=True).stdout
    os.unlink(tmp)
    rows = []
    for line in out.splitlines():
        m = re.match(r"^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$", line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        bs = bytes(int(x, 16) for x in m.group(2).split())
        rows.append((addr, bs, m.group(3).strip()))
    return [r for r in rows if r[0] + len(r[1]) <= end]


def llvm_disasm_each(rows):
    """llvm-mc disassembler text for each instruction, one call for the lot."""
    out = []
    for _, bs, _ in rows:
        hx = " ".join("0x%02x" % b for b in bs)
        r = subprocess.run([LLVM_MC, "--triple=tlcs900", "--disassemble"],
                           input=hx, capture_output=True, text=True)
        txt = None
        for line in r.stdout.splitlines():
            line = line.strip()
            if line and not line.startswith("."):
                txt = re.sub(r"\s+", " ", line).strip()
                break
        out.append(txt)
    return out


def hexify(text):
    """llvm-mc's disassembler prints operands in decimal; these are almost always
    addresses or bit masks, so rewrite them as hex.  Only accepted if the hex
    form still assembles to the same bytes."""
    def sub(m):
        v = int(m.group(0))
        return "0x%02x" % v if v < 256 else "0x%04x" % v
    return re.sub(r"(?<![\w.$-])\d+(?![\w.])", sub, text)


def assemble_batch(texts, prelude):
    """Assemble every text on its own line.  Returns [encoding|None] per text.
    Lines llvm-mc rejects are dropped and the batch retried, so one bad
    candidate does not poison the rest."""
    idx = list(range(len(texts)))
    result = [None] * len(texts)
    while idx:
        pre = prelude + "\n\t.text\n"
        nlpre = pre.count("\n")
        src = pre + "\n".join(texts[i] for i in idx) + "\n"
        r = subprocess.run([LLVM_MC, "--triple=tlcs900", "--show-encoding"],
                           input=src, capture_output=True, text=True)
        bad = set()
        for m in re.finditer(r"^<stdin>:(\d+):\d+: error:", r.stderr, re.M):
            ln = int(m.group(1)) - nlpre - 1
            if 0 <= ln < len(idx):
                bad.add(ln)
        if bad:
            idx = [v for k, v in enumerate(idx) if k not in bad]
            continue
        encs = []
        for line in r.stdout.splitlines():
            m = re.search(r"[;#] encoding: \[([^\]]+)\]", line)
            if m:
                encs.append(bytes(int(h, 16) for h in m.group(1).split(",")))
        if len(encs) == len(idx):
            for k, v in enumerate(idx):
                result[v] = encs[k]
        return result
    return result


def assemble_emitted(text, prelude):
    """Total bytes emitted by ONE source line, whether llvm-mc reports them as an
    instruction encoding or as expanded .byte directives (which is what the
    macro prelude produces).  Used only for macro candidates."""
    src = prelude + "\n\t.text\n" + text + "\n"
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "--show-encoding"],
                       input=src, capture_output=True, text=True)
    if r.returncode != 0:
        return None
    out = bytearray()
    seen_text = False
    for line in r.stdout.splitlines():
        st = line.strip()
        if st == ".text":
            seen_text = True
            continue
        if not seen_text:
            continue
        m = re.search(r"[;#] encoding: \[([^\]]+)\]", line)
        if m:
            out += bytes(int(h, 16) for h in m.group(1).split(","))
            continue
        m = re.match(r"\.byte\s+(\d+)$", st)
        if m:
            out.append(int(m.group(1)) & 0xFF)
    return bytes(out)


# --- (c) macro candidates for the direct-address memory-operand forms --------
# The macros themselves, and the dasm900.cpp citation for every operation byte
# they emit, live in the MACRO PRELUDE inside prom_a/wsa1_prom_a.s.  This table
# only knows how to turn unidasm's text back into a call of one.
REG8 = ["W", "A", "B", "C", "D", "E", "H", "L"]
REG16 = ["WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"]
REG32 = ["XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"]
MULREG16 = {"WA": 1, "BC": 3, "DE": 5, "HL": 7}
PFXNAME = {0xC0: "MB8", 0xC1: "MB16", 0xC2: "MB24",
           0xD0: "MW8", 0xD1: "MW16", 0xD2: "MW24",
           0xE0: "ML8", 0xE1: "ML16", 0xE2: "ML24",
           0xF0: "MD8", 0xF1: "MD16", 0xF2: "MD24"}
# register-relative operand prefixes: base constant + register index
RPFX = {0x80: "MBI", 0x88: "MBD", 0x90: "MWI", 0x98: "MWD",
        0xA0: "MLI", 0xA8: "MLD", 0xB0: "MDI", 0xB8: "MDD"}


def _pfx_and_operand(bs, u):
    """(prefix expression, operand expression, unidasm text with the memory
    operand rewritten to a plain (0x..) so the shared patterns below match)."""
    import re as _re
    b0 = bs[0]
    if b0 in PFXNAME:
        return PFXNAME[b0], None, u
    base = b0 & 0xF8
    if base in RPFX and 0x80 <= b0 <= 0xBF:
        pfx = "%s+r%d" % (RPFX[base], b0 & 7)
        if b0 & 0x08:
            g = _re.search(r"\((X[A-Z]{2})\+(0x[0-9a-f]+)\)", u)
            if not g:
                return None, None, u
            return pfx, g.group(2), _re.sub(r"\(X[A-Z]{2}\+0x[0-9a-f]+\)",
                                           "(0xffff)", u)
        g = _re.search(r"\((X[A-Z]{2})\)", u)
        if not g:
            return None, None, u
        return pfx, "0", _re.sub(r"\(X[A-Z]{2}\)", "(0xffff)", u)
    return None, None, u
A = r"\((0x[0-9a-f]+)\)"          # the memory operand as unidasm prints it
I = r"(0x[0-9a-f]+)"
N = r"(\d)"
R = r"([A-Z][A-Z0-9]*)"


def _ri(name):
    for tbl in (REG8, REG16, REG32):
        if name in tbl:
            return tbl.index(name)
    return None


BLOCK_XFER = {0x80: "", 0x83: "83", 0x85: "85", 0x93: "93", 0x95: "w"}


REGPFX = {0xC8: "RB", 0xD8: "RW", 0xE8: "RL"}
# the only control-register numbers MAME decodes for this part
# (900tbl.hxx:3931-4030, the TMP96C141/TMP95C061/TMP95C063 cases)
CRNAME = {}
for _i, _n in enumerate(("DMAS", "DMAD")):
    for _c in range(4):
        CRNAME[_i * 0x10 + _c * 4] = "CR_%s%d" % (_n, _c)
for _c in range(4):
    CRNAME[0x20 + _c * 4] = "CR_DMAC%d" % _c
    CRNAME[0x22 + _c * 4] = "CR_DMAM%d" % _c


def ldc_candidate(u, bs):
    """`ldc unknown,R` / `ldc R,unknown` -- the control-register moves, which
    llvm-mc has no encoding for.  See the LDC macros in the prelude."""
    import re as _re
    if len(bs) != 3 or bs[1] not in (0x2E, 0x2F):
        return None
    base = bs[0] & 0xF8
    if base not in REGPFX:
        return None
    pfx = "%s+r%d" % (REGPFX[base], bs[0] & 7)
    cr = CRNAME.get(bs[2], "0x%02x" % bs[2])
    if bs[1] == 0x2E and _re.match(r"^ldc unknown,", u):
        return "m_ldc_cr_reg %s, %s" % (pfx, cr)
    if bs[1] == 0x2F and _re.match(r"^ldc \w+,unknown$", u):
        return "m_ldc_reg_cr %s, %s" % (pfx, cr)
    return None


def native_candidate(u, bs):
    """Spellings llvm-mc's ASSEMBLER accepts but its DISASSEMBLER never prints,
    so strategy (b) cannot find them."""
    import re as _re
    g = _re.match(r"^minc(1|2|4) (0x[0-9a-f]+),([A-Z]{2})$", u)
    if g:
        return "minc%s_16 %s, %s" % (g.group(1), g.group(3).lower(), g.group(2))
    if len(bs) == 2 and u in ("ldi", "ldir", "ldd", "lddr"):
        sfx = BLOCK_XFER.get(bs[0])
        if sfx is not None:
            return u + sfx
    return None


# The register-indexed operand `(R32+R16)`.  dasm900.cpp:1543-1584: prefix
# 0xC3/0xD3/0xE3/0xF3, sub-mode byte 0x07, base and index register-address
# bytes, operation byte.  The prelude's mx_* macros emit exactly that; this
# turns unidasm's text back into a call of one.
XPFX = {0xC3: "MXB", 0xD3: "MXW", 0xE3: "MXL", 0xF3: "MXD"}
# s_allreg32 (base) and s_allreg16 (index) carry the same numbers here
RA = {0xE0: "ra_WA", 0xE4: "ra_BC", 0xE8: "ra_DE", 0xEC: "ra_HL",
      0xF0: "ra_IX", 0xF4: "ra_IY", 0xF8: "ra_IZ", 0xFC: "ra_SP"}


def indexed_candidate(u, bs):
    """`ld A,(XHL+IX)` and friends -- the register-INDEXED memory operand."""
    import re as _re
    if len(bs) not in (5, 6) or bs[0] not in XPFX or bs[1] != 0x07:
        return None
    if bs[2] not in RA or bs[3] not in RA:
        return None
    pfx = XPFX[bs[0]]
    base, idx = RA[bs[2]], RA[bs[3]]
    # the operand as unidasm prints it, e.g. "(XHL+IX)"
    g = _re.match(r"^(ld|ldw) (.+)$", u)
    if not g:
        return None
    mem = "(X%s+%s)" % (base[3:], idx[3:])   # s_allreg32 name is X-prefixed
    dst, _, src = g.group(2).partition(",")
    if dst == mem and _re.match(r"^0x[0-9a-f]{2}$", src) and len(bs) == 6 and bs[4] == 0x00:
        return "mx_ld_mi8 %s, %s, %s, %s" % (pfx, base, idx, src)
    if len(bs) != 5:
        return None
    if src == mem and _ri(dst) is not None:
        return "mx_ld_rm %s, %s, %s, r%d" % (pfx, base, idx, _ri(dst))
    if dst == mem and _ri(src) is not None:
        mac = ("mx_st_mr8" if src in REG8 else
               "mx_st_mr16" if src in REG16 else "mx_st_mr32")
        return "%s %s, %s, %s, r%d" % (mac, pfx, base, idx, _ri(src))
    return None


# s_allreg8 (dasm900.cpp:1349), sub-mode 0x03: an 8-bit index register
RB = {0xE0: "rb_A", 0xE1: "rb_W", 0xE4: "rb_C", 0xE5: "rb_B",
      0xE8: "rb_E", 0xE9: "rb_D", 0xEC: "rb_L", 0xED: "rb_H"}


def indexed8_candidate(u, bs):
    """`ld L,(XHL+W)`, `ld XIX,(XIX+L)` -- the same operand with an 8-bit index."""
    import re as _re
    if len(bs) != 5 or bs[0] not in XPFX or bs[1] != 0x03:
        return None
    if bs[2] not in RA or bs[3] not in RB:
        return None
    pfx, base, idx = XPFX[bs[0]], RA[bs[2]], RB[bs[3]]
    mem = "(X%s+%s)" % (base[3:], idx[3:])
    g = _re.match(r"^(ld|ldw) ([^,]+),(.+)$", u)
    if not g:
        return None
    dst, src = g.group(2), g.group(3)
    if src == mem and _ri(dst) is not None and bs[4] == 0x20 + _ri(dst):
        return "mx8_ld_rm %s, %s, %s, r%d" % (pfx, base, idx, _ri(dst))
    if dst == mem and _ri(src) is not None:
        for op, mac in ((0x40, "mx8_st_mr8"), (0x50, "mx8_st_mr16"),
                        (0x60, "mx8_st_mr32")):
            if bs[4] == op + _ri(src):
                return "%s %s, %s, %s, r%d" % (mac, pfx, base, idx, _ri(src))
    return None


COND = ["F", "LT", "LE", "ULE", "PE/OV", "M/MI", "Z", "C",
        "T", "GE", "GT", "UGT", "PO/NOV", "P/PL", "NZ", "NC"]  # dasm900.cpp:1348


def indexed_misc_candidate(u, bs):
    """`lda XIZ,XBC+WA` and `jp T,XIX+WA` -- mnemonic_f0's 0x30 and 0xD0 rows
    reached through the register-indexed operand.  ⚠ unidasm prints THIS operand
    without the brackets it uses everywhere else, hence the second spelling."""
    import re as _re
    if len(bs) != 5 or bs[0] not in XPFX or bs[1] != 0x07:
        return None
    if bs[2] not in RA or bs[3] not in RA:
        return None
    pfx, base, idx = XPFX[bs[0]], RA[bs[2]], RA[bs[3]]
    mem = "X%s+%s" % (base[3:], idx[3:])
    g = _re.match(r"^lda ([A-Z][A-Z0-9]*),(.+)$", u)
    if g and g.group(2) == mem and g.group(1) in REG32 \
            and bs[4] == 0x30 + REG32.index(g.group(1)):
        return "mx_lda32 %s, %s, %s, r%d" % (pfx, base, idx,
                                             REG32.index(g.group(1)))
    g = _re.match(r"^jp ([A-Z/]+),(.+)$", u)
    if g and g.group(2) == mem and g.group(1) in COND \
            and bs[4] == 0xD0 + COND.index(g.group(1)):
        return "mx_jp_cc %s, %s, %s, %d" % (pfx, base, idx,
                                            COND.index(g.group(1)))
    return None


ALU_RM = {0xC0: "mx_and_rm", 0xE0: "mx_or_rm"}     # op 0x??+r, R <- R op (mem)
ALU_MR = {0xE8: "mx_or_mr"}                        # op 0x??+r, (mem) <- ... R


def indexed_alu_candidate(u, bs):
    """`and A,(XHL+DE)`, `or C,(XHL+DE)`, `or (XIX+IZ),E` -- the same operand,
    the ALU rows of mnemonic_c0 (dasm900.cpp:679)."""
    import re as _re
    if len(bs) != 5 or bs[0] not in XPFX or bs[1] != 0x07:
        return None
    if bs[2] not in RA or bs[3] not in RA:
        return None
    pfx, base, idx = XPFX[bs[0]], RA[bs[2]], RA[bs[3]]
    mem = "(X%s+%s)" % (base[3:], idx[3:])
    g = _re.match(r"^(and|or|xor|add|sub|cp) ([^,]+),(.+)$", u)
    if not g:
        return None
    dst, src = g.group(2), g.group(3)
    op = bs[4] & 0xF8
    if src == mem and op in ALU_RM and _ri(dst) is not None \
            and bs[4] == op + _ri(dst):
        return "%s %s, %s, %s, r%d" % (ALU_RM[op], pfx, base, idx, _ri(dst))
    if dst == mem and op in ALU_MR and _ri(src) is not None \
            and bs[4] == op + _ri(src):
        return "%s %s, %s, %s, r%d" % (ALU_MR[op], pfx, base, idx, _ri(src))
    return None


def macro_candidate(u, bs):
    """unidasm text + raw bytes -> a macro call, or None."""
    if not bs:
        return None
    p, roperand, u = _pfx_and_operand(bs, u)
    if p is None:
        return None
    import re as _re
    def m(pat):
        return _re.match("^" + pat + "$", u)
    dst = (bs[0] & 0xF0) == 0xF0 or (bs[0] & 0xF0) == 0xB0

    def a(x):
        return x if roperand is None else roperand

    if not dst:
        for pat, mac in ((r"(?:push|pushw) " + A, "m_push"),):
            g = m(pat)
            if g:
                if bs[-1] == 0x06:
                    mac = "m_pushw"
                return "%s %s, %s" % (mac, p, a(g.group(1)))
        g = m(r"(?:ld|ldw) " + R + "," + A)
        if g and _ri(g.group(1)) is not None:
            return "m_ld_rm %s, %s, r%d" % (p, a(g.group(2)), _ri(g.group(1)))
        g = m(r"ex " + A + "," + R)
        if g and _ri(g.group(2)) is not None:
            return "m_ex_mr %s, %s, r%d" % (p, a(g.group(1)), _ri(g.group(2)))
        for op, mac in (("add", "m_add_mi8"), ("and", "m_and_mi8"),
                        ("xor", "m_xor_mi8"), ("or", "m_or_mi8"),
                        ("cp", "m_cp_mi8")):
            g = m(op + " " + A + "," + I)
            if g:
                # MAME prints an 8-bit immediate as 0xNN and a 16-bit one as
                # 0xNNNN (dasm900.cpp O_I8 vs O_I16), which is what picks the
                # operation byte's width here.
                w16 = len(g.group(2)) > 4
                mac2 = mac[:-1] + ("16" if w16 else "8")
                return "%s %s, %s, %s" % (mac2, p, a(g.group(1)), g.group(2))
        # ⚠ The destination of mul/muls/div/divs prints from TWO different MAME
        # tables: s_mulreg16 (dasm900.cpp:1348, "WA"/"BC"/"DE"/"HL" at the ODD
        # indices) for the byte-operand prefixes, and s_reg32 for the word ones,
        # where `muls XWA,(XSP+0x08)` is a 16x16->32 multiply.  Both spell the
        # same operation byte, so both have to be accepted here; taking only the
        # first left ten `.byte` lines in the 0xFE0000 module.
        for op, mac in (("mul", "m_mul"), ("muls", "m_muls"),
                        ("div", "m_div"), ("divs", "m_divs")):
            g = m(op + " " + R + "," + A)
            if g:
                if g.group(1) in MULREG16:
                    return "%s %s, %s, %d" % (mac, p, a(g.group(2)),
                                              MULREG16[g.group(1)])
                if g.group(1) in REG32:
                    return "%s %s, %s, %d" % (mac, p, a(g.group(2)),
                                              REG32.index(g.group(1)))
        for op, mac in (("inc", "m_inc"), ("dec", "m_dec"),
                        ("incw", "m_inc"), ("decw", "m_dec")):
            g = m(op + " " + N + "," + A)
            if g:
                return "%s %s, %s, %s" % (mac, g.group(1), p, a(g.group(2)))
        for op, macs in (("add", ("m_add_rm", "m_add_mr")),
                         ("sub", ("m_sub_rm", "m_sub_mr")),
                         ("sbc", ("m_sbc_rm", None)),
                         ("and", ("m_and_rm", None)),
                         ("xor", ("m_xor_rm", None)),
                         ("or", ("m_or_rm", None)),
                         ("cp", ("m_cp_rm", "m_cp_mr"))):
            g = m(op + " " + R + "," + A)
            if g and macs[0] and _ri(g.group(1)) is not None:
                return "%s %s, %s, r%d" % (macs[0], p, a(g.group(2)), _ri(g.group(1)))
            g = m(op + " " + A + "," + R)
            if g and macs[1] and _ri(g.group(2)) is not None:
                return "%s %s, %s, r%d" % (macs[1], p, a(g.group(1)), _ri(g.group(2)))
        return None

    # --- destination table (prefix 0xF0/0xF1/0xF2) ---------------------------
    g = m(r"(?:ld|ldw) " + A + "," + I)
    if g:
        mac = "m_ld_mi16" if len(g.group(2)) > 4 else "m_ld_mi8"
        return "%s %s, %s, %s" % (mac, p, a(g.group(1)), g.group(2))
    g = m(r"lda " + R + "," + I)
    if g:
        i = _ri(g.group(1))
        if i is not None:
            mac = "m_lda32" if g.group(1) in REG32 else "m_lda16"
            return "%s %s, %s, r%d" % (mac, p, a(g.group(2)), i)
    g = m(r"ld " + A + "," + R)
    if g:
        r = g.group(2)
        i = _ri(r)
        if i is not None:
            mac = ("m_st_mr32" if r in REG32 else
                   "m_st_mr16" if r in REG16 else "m_st_mr8")
            return "%s %s, %s, r%d" % (mac, p, a(g.group(1)), i)
    g = m(r"(?:ld|ldw) " + A + "," + A)
    if g:
        mac = "m_ldw_mm16" if u.startswith("ldw") else "m_ld_mm16"
        return "%s %s, %s, %s" % (mac, p, a(g.group(1)), g.group(2))
    g = m(r"(?:pop|popw) " + A)
    if g:
        return "%s %s, %s" % ("m_popw" if bs[-1] == 0x06 else "m_pop",
                              p, a(g.group(1)))
    for op, mac in (("stcf", "m_stcf"), ("res", "m_res"), ("set", "m_set"),
                    ("chg", "m_chg"), ("bit", "m_bit")):
        g = m(op + " " + N + "," + A)
        if g:
            return "%s %s, %s, %s" % (mac, g.group(1), p, a(g.group(2)))
    return None


def convert(start, end):
    rows = unidasm_range(start, end)
    prelude = macro_prelude()

    # (a) unidasm text
    cand_a = [re.sub(r"\s+", " ", t).strip() for _, _, t in rows]
    cand_a = ["" if (not t or t.startswith("db")) else t for t in cand_a]
    enc_a = assemble_batch([t or "nop" for t in cand_a], prelude)

    need = [i for i in range(len(rows)) if enc_a[i] != rows[i][1] or not cand_a[i]]

    # (b) llvm-mc disassembler text.  Its operands print in decimal
    # (`ldio 144, 0`); a hex rewrite is tried first because these are addresses.
    sub = [rows[i] for i in need]
    cand_b_txt = llvm_disasm_each(sub) if sub else []
    cand_b_hex = [hexify(t) if t else None for t in cand_b_txt]
    enc_bh = assemble_batch([t or "nop" for t in cand_b_hex], prelude) if sub else []
    for i, t in enumerate(cand_b_hex):
        if t and enc_bh[i] == rows[need[i]][1]:
            cand_b_txt[i] = t
    enc_b = assemble_batch([t or "nop" for t in cand_b_txt], prelude) if sub else []

    # (c) macro
    cand_c_txt = [(native_candidate(cand_a[i], rows[i][1])
                   or ldc_candidate(cand_a[i], rows[i][1])
                   or indexed_candidate(cand_a[i], rows[i][1])
                   or indexed_alu_candidate(cand_a[i], rows[i][1])
                   or indexed8_candidate(cand_a[i], rows[i][1])
                   or indexed_misc_candidate(cand_a[i], rows[i][1])
                   or macro_candidate(cand_a[i], rows[i][1])) if cand_a[i] else None
                  for i in need]
    enc_c = [assemble_emitted(t, prelude) if t else None for t in cand_c_txt]

    out, stats = [], collections.Counter()
    for i, (addr, bs, utext) in enumerate(rows):
        u = cand_a[i]
        if enc_a[i] == bs and u:
            out.append((addr, bs, u, "unidasm", u)); stats["unidasm"] += 1; continue
        k = need.index(i)
        if cand_b_txt[k] and enc_b[k] == bs:
            out.append((addr, bs, cand_b_txt[k], "llvm", u)); stats["llvm"] += 1; continue
        if cand_c_txt[k] and enc_c[k] == bs:
            out.append((addr, bs, cand_c_txt[k], "macro", u)); stats["macro"] += 1; continue
        out.append((addr, bs, ".byte " + ", ".join("0x%02x" % b for b in bs),
                    "byte", u)); stats["byte"] += 1
    return out, stats


# --- block emission with labels ---------------------------------------------
# A relative branch, as unidasm prints it: the mnemonic, an optional condition,
# and the ABSOLUTE target.  Used only to find the target -- the label is then
# substituted into whichever spelling the round-trip actually chose, by
# replacing that line's last operand token.
BRANCH = re.compile(r"^(jr|jrl|calr|djnz)\b.*?(0x[0-9a-f]{6})$")
LAST_OPERAND = re.compile(r"[-+\w.$]+$")


def emit_block(start, end, label_prefix=".L"):
    """Assembly for [start,end) with local labels on every in-range branch
    target.  Returns (lines, ok) where ok is True only when re-assembling the
    whole block reproduces the ROM bytes exactly."""
    rows, stats = convert(start, end)
    if not rows:
        return [], False, stats
    # the window may cut the last instruction in half; compare only what the
    # decoder actually covered
    covered = rows[-1][0] + len(rows[-1][1])
    data = open(ROM, "rb").read()[start - BASE:covered - BASE]

    targets = set()
    for addr, bs, text, why, u in rows:
        g = BRANCH.match(u or "")
        if g:
            t = int(g.group(2), 16)
            if start <= t < end:
                targets.add(t)
    labels = {t: "%s%06X" % (label_prefix, t) for t in targets}

    body = []
    for addr, bs, text, why, u in rows:
        g = BRANCH.match(u or "")
        cand = None
        if g and int(g.group(2), 16) in labels and why != "byte":
            cand = LAST_OPERAND.sub(labels[int(g.group(2), 16)], text)
            if cand == text:
                cand = None
        body.append((addr, bs, text, why, u, cand))

    # try the labelled version first, whole-block
    for use_labels in (True, False):
        lines, out = [], []
        for addr, bs, text, why, u, cand in body:
            if addr in labels:
                lines.append((labels[addr] + ":", None, None, None))
            t = cand if (use_labels and cand) else text
            w = why if not (use_labels and cand) else "label"
            lines.append(("\t" + t, addr, bs, w))
            out.append(t)
        src = macro_prelude() + "\n\t.text\n"
        for l, addr, bs, w in lines:
            src += l.lstrip("\t") + "\n" if addr is None else l + "\n"
        got = assemble_block(src)
        if got == data:
            return lines, True, stats
    return lines, False, stats


def assemble_block(src):
    import tempfile
    d = tempfile.mkdtemp()
    a_s, a_o, a_b = d + "/a.s", d + "/a.o", d + "/a.bin"
    open(a_s, "w").write(src)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "-filetype=obj",
                        "-o", a_o, a_s], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    oc = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")
    r = subprocess.run([oc, "-O", "binary", "--only-section=.text", a_o, a_b],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return open(a_b, "rb").read()


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    start, end = int(args[0], 16), int(args[1], 16)
    rows, stats = convert(start, end)
    if "--survey" in sys.argv:
        forms = collections.Counter()
        for addr, bs, text, why, u in rows:
            if why == "byte":
                forms[re.sub(r"0x[0-9a-f]+", "#", u) or "(no text)"] += 1
        for f, n in forms.most_common():
            print("%5d  %s" % (n, f))
        sys.stderr.write("  %r\n" % (dict(stats),))
        return
    if "--block" in sys.argv:
        lines, ok, stats = emit_block(start, end)
        if not ok:
            print("; !! BLOCK DID NOT ROUND-TRIP -- do not paste this")
        for l, addr, bs, why in lines:
            if addr is None:
                print(l)
            else:
                raw = " ".join("%02x" % b for b in bs)
                print("%-46s ; %06X  %s" % (l, addr, raw))
        sys.stderr.write("  round-trip: %s   %r\n" % ("OK" if ok else "FAIL",
                                                       dict(stats)))
        return
    for addr, bs, text, why, u in rows:
        raw = " ".join("%02x" % b for b in bs)
        note = ("\t\t; %s" % u) if why == "byte" and u else ""
        print("\t%-44s ; %06X  %-22s [%s]%s" % (text, addr, raw, why, note))
    if "--stats" in sys.argv:
        sys.stderr.write("  %r\n" % (dict(stats),))


if __name__ == "__main__":
    main()
