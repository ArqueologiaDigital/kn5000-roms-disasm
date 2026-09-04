#!/usr/bin/env python3
"""
QUESTION IT ANSWERS: can the direct-address family of SYNTHETIC mnemonics --
the ones that carry the address WIDTH and the operand SIZE in the mnemonic --
be respelled with the NATIVE mnemonic plus the width annotation the assembler
already supports (`(0x2075:16)`, TOOLCHAIN_VERSION UPDATE 7), without changing
a single ROM byte?

    ldb_da  a, (0x120000)   ->   ld  a, (0x120000:24)
    stda16  61458, xwa      ->   ld  (61458:16), wa
    cpdi16  10215, 48       ->   cpw (10215:16), 48

This implements section 8 of notes/ASSESSMENT-syntax-convergence-2026-09-02.md
("Option B, one mnemonic family at a time").

⚠ THE ADDRESS WIDTH IS NOT DERIVABLE FROM THE ADDRESS VALUE.  This firmware
writes `set 7,(0x00008a)` as a 24-bit field for an 8-bit address.  The width
below is read off the MNEMONIC -- i.e. off the prefix byte the mnemonic is
defined to emit in TLCS900InstrInfo.td -- never off the number.

⚠ EVERY SITE IS VERIFIED INDIVIDUALLY, not per family.  The old and the new
spelling of each line are assembled in isolation by llvm-mc and their encodings
(including relocation fixups) must be identical byte for byte before the line
is written.  A family-level byte gate can be green while one site changed and
another compensated; this cannot.

EXACT COMMANDS (from the tree root):

    # dry run: report only, writes nothing
    python3 scripts/converters/convert_direct_address_family.py --mnemonic stdi8

    # convert and write
    python3 scripts/converters/convert_direct_address_family.py --mnemonic stdi8 --apply

    # all seventeen at once
    python3 scripts/converters/convert_direct_address_family.py --all --apply

Then, always:  make gate-all
"""
import argparse, collections, csv, hashlib, os, re, shutil, subprocess, sys, tempfile

HOME = os.path.expanduser("~")
LLVM_MC = os.environ.get(
    "LLVM_MC", os.path.join(HOME, "compartilhado/llvm-project/build/bin/llvm-mc"))

# ---------------------------------------------------------------- the mapping
#
# width  = the ADDRESS field width the mnemonic is defined to emit
#          (C0/D0/E0/F0 = 8, C1/D1/E1/F1 = 16, C2/D2/E2/F2 = 24).
# addr   = which operand (0-based) is the direct address.
# regmap = the register class the OTHER operand really denotes, which the
#          synthetic mnemonic did not say.  None = the other operand is an
#          immediate and is copied through untouched.
MAP = {
    # 8-bit data
    "ldb_da":  dict(native="ld",  width=24, addr=1, regmap="r8"),
    "stb_da":  dict(native="ld",  width=24, addr=0, regmap="r8"),
    "stib_da": dict(native="ld",  width=24, addr=0, regmap=None),
    "stdi8":   dict(native="ld",  width=16, addr=0, regmap=None),
    "cpdi8":   dict(native="cp",  width=16, addr=0, regmap=None),
    "anddi8":  dict(native="and", width=16, addr=0, regmap=None),
    "ordi8":   dict(native="or",  width=16, addr=0, regmap=None),
    # 16-bit data
    "ldw_da":  dict(native="ld",  width=24, addr=1, regmap="r16"),
    "stw_da":  dict(native="ld",  width=24, addr=0, regmap="r16"),
    "stda16":  dict(native="ld",  width=16, addr=0, regmap="r16"),
    "stiw_da": dict(native="ldw", width=24, addr=0, regmap=None),
    "stdi16":  dict(native="ldw", width=16, addr=0, regmap=None),
    "cpdi16":  dict(native="cpw", width=16, addr=0, regmap=None),
    # 32-bit data
    "ldl_da":  dict(native="ld",  width=24, addr=1, regmap="r32"),
    "ldda32":  dict(native="ld",  width=16, addr=1, regmap="r32"),
    "stda32":  dict(native="ld",  width=16, addr=0, regmap="r32"),
    # bit, no data size
    "bitda":   dict(native="bit", width=16, addr=1, regmap=None),

    # ---------------------------------------------------------------------
    # w26/conv-alu, 2026-09-04: the ALU-direct / bit-direct / inc-dec-direct
    # remainder.  Same shape as the seventeen above -- the mnemonic spells the
    # ADDRESS WIDTH and, where the other operand is an immediate, the DATA
    # SIZE.  Read off TLCS900InstrInfo.td, never off the address value:
    #   width  = AddrWidth (0 => 16-bit field, 1 => 24-bit field)
    #   native = the operation; the `w` suffix appears only where no register
    #            operand exists to carry the 16-bit size (addw/subw/andw/orw/
    #            cpw/incw/decw), exactly as `ldw`/`cpw` above.
    #   addr   = operand index in the SOURCE line, i.e. in the .td asm string.
    # ---------------------------------------------------------------------

    # ALU  reg, (addr)   -- sub-opcode = ALU_base + reg index
    "addda8":     dict(native="add", width=16, addr=1, regmap="r8"),
    "addda8_24":  dict(native="add", width=24, addr=1, regmap="r8"),
    "addda16":    dict(native="add", width=16, addr=1, regmap="r16"),
    "addda16_24": dict(native="add", width=24, addr=1, regmap="r16"),
    "addda32":    dict(native="add", width=16, addr=1, regmap="r32"),
    "addda32_24": dict(native="add", width=24, addr=1, regmap="r32"),
    "subda8":     dict(native="sub", width=16, addr=1, regmap="r8"),
    "subda8_24":  dict(native="sub", width=24, addr=1, regmap="r8"),
    "subda16":    dict(native="sub", width=16, addr=1, regmap="r16"),
    "subda16_24": dict(native="sub", width=24, addr=1, regmap="r16"),
    "subda32":    dict(native="sub", width=16, addr=1, regmap="r32"),
    "sub32_24":   dict(native="sub", width=24, addr=1, regmap="r32"),
    "andda8":     dict(native="and", width=16, addr=1, regmap="r8"),
    "andda8_24":  dict(native="and", width=24, addr=1, regmap="r8"),
    "andda16":    dict(native="and", width=16, addr=1, regmap="r16"),
    "andda16_24": dict(native="and", width=24, addr=1, regmap="r16"),
    "andda32_24": dict(native="and", width=24, addr=1, regmap="r32"),
    "orda8":      dict(native="or",  width=16, addr=1, regmap="r8"),
    "orda8_24":   dict(native="or",  width=24, addr=1, regmap="r8"),
    "orda16":     dict(native="or",  width=16, addr=1, regmap="r16"),
    "orda32_24":  dict(native="or",  width=24, addr=1, regmap="r32"),
    "xorda8":     dict(native="xor", width=16, addr=1, regmap="r8"),
    "xorda8_24":  dict(native="xor", width=24, addr=1, regmap="r8"),
    "xorda16_24": dict(native="xor", width=24, addr=1, regmap="r16"),
    "cpda8":      dict(native="cp",  width=16, addr=1, regmap="r8"),
    "cpda8_24":   dict(native="cp",  width=24, addr=1, regmap="r8"),
    "cpda16":     dict(native="cp",  width=16, addr=1, regmap="r16"),
    "cpda16_24":  dict(native="cp",  width=24, addr=1, regmap="r16"),
    "cpda32":     dict(native="cp",  width=16, addr=1, regmap="r32"),
    "cpda32_24":  dict(native="cp",  width=24, addr=1, regmap="r32"),

    # ALU  (addr), reg   -- sub-opcode = ALU_base + 8 + reg index
    "adddm8":     dict(native="add", width=16, addr=0, regmap="r8"),
    "adddm16":    dict(native="add", width=16, addr=0, regmap="r16"),
    "adddm16_24": dict(native="add", width=24, addr=0, regmap="r16"),
    "adddm32":    dict(native="add", width=16, addr=0, regmap="r32"),
    "addl_da":    dict(native="add", width=24, addr=0, regmap="r32"),
    "subdm8":     dict(native="sub", width=16, addr=0, regmap="r8"),
    "subdm8_24":  dict(native="sub", width=24, addr=0, regmap="r8"),
    "subdm16":    dict(native="sub", width=16, addr=0, regmap="r16"),
    "subdm16_24": dict(native="sub", width=24, addr=0, regmap="r16"),
    "subdm32":    dict(native="sub", width=16, addr=0, regmap="r32"),
    "subdm32_24": dict(native="sub", width=24, addr=0, regmap="r32"),
    "anddm8":     dict(native="and", width=16, addr=0, regmap="r8"),
    "anddm8_24":  dict(native="and", width=24, addr=0, regmap="r8"),
    "anddm16":    dict(native="and", width=16, addr=0, regmap="r16"),
    "anddm16_24": dict(native="and", width=24, addr=0, regmap="r16"),
    "anddm32_24": dict(native="and", width=24, addr=0, regmap="r32"),
    "orddm8":     dict(native="or",  width=16, addr=0, regmap="r8"),
    "orddm16":    dict(native="or",  width=16, addr=0, regmap="r16"),
    "ordm8_24":   dict(native="or",  width=24, addr=0, regmap="r8"),
    "ordm16_24":  dict(native="or",  width=24, addr=0, regmap="r16"),
    "ordm32_24":  dict(native="or",  width=24, addr=0, regmap="r32"),
    "xordm8":     dict(native="xor", width=16, addr=0, regmap="r8"),
    "xordm16_24": dict(native="xor", width=24, addr=0, regmap="r16"),
    "cpdm8":      dict(native="cp",  width=16, addr=0, regmap="r8"),
    "cpdm8_24":   dict(native="cp",  width=24, addr=0, regmap="r8"),
    "cpdm16":     dict(native="cp",  width=16, addr=0, regmap="r16"),
    "cpdm16_24":  dict(native="cp",  width=24, addr=0, regmap="r16"),
    "cpdm32":     dict(native="cp",  width=16, addr=0, regmap="r32"),
    "cpdm32_24":  dict(native="cp",  width=24, addr=0, regmap="r32"),

    # ALU  (addr), imm   -- no register operand, so the 16-bit size stays in
    # the mnemonic as the `w` suffix
    "adddi8":     dict(native="add",  width=16, addr=0, regmap=None),
    "adddi16":    dict(native="addw", width=16, addr=0, regmap=None),
    "adddi16_24": dict(native="addw", width=24, addr=0, regmap=None),
    "subdi8":     dict(native="sub",  width=16, addr=0, regmap=None),
    "subdi16":    dict(native="subw", width=16, addr=0, regmap=None),
    "subdi16_24": dict(native="subw", width=24, addr=0, regmap=None),
    "anddi8_24":  dict(native="and",  width=24, addr=0, regmap=None),
    "anddi16":    dict(native="andw", width=16, addr=0, regmap=None),
    "anddi16_24": dict(native="andw", width=24, addr=0, regmap=None),
    "ordi8_24":   dict(native="or",   width=24, addr=0, regmap=None),
    "ordi16":     dict(native="orw",  width=16, addr=0, regmap=None),
    "ordi16_24":  dict(native="orw",  width=24, addr=0, regmap=None),
    "xordi8":     dict(native="xor",  width=16, addr=0, regmap=None),
    "xordi8_24":  dict(native="xor",  width=24, addr=0, regmap=None),
    "cpib_da":    dict(native="cp",   width=24, addr=0, regmap=None),
    "cpw_da":     dict(native="cpw",  width=24, addr=0, regmap=None),

    # INC / DEC  count, (addr)
    "incdi8":     dict(native="inc",  width=16, addr=1, regmap=None),
    "incdi8_24":  dict(native="inc",  width=24, addr=1, regmap=None),
    "incdi16":    dict(native="incw", width=16, addr=1, regmap=None),
    "incdi16_24": dict(native="incw", width=24, addr=1, regmap=None),
    "decdi8":     dict(native="dec",  width=16, addr=1, regmap=None),
    "decdi8_24":  dict(native="dec",  width=24, addr=1, regmap=None),
    "decdi16":    dict(native="decw", width=16, addr=1, regmap=None),
    "decdi16_24": dict(native="decw", width=24, addr=1, regmap=None),

    # BIT / RES / SET / CHG  bit, (addr)
    "resda":      dict(native="res", width=16, addr=1, regmap=None),
    "resda_24":   dict(native="res", width=24, addr=1, regmap=None),
    "setda":      dict(native="set", width=16, addr=1, regmap=None),
    "setda_24":   dict(native="set", width=24, addr=1, regmap=None),
    "bitda_24":   dict(native="bit", width=24, addr=1, regmap=None),
    # ⚠ chg's parser path does not accept a width-annotated direct operand;
    # every site is refused with new-does-not-assemble.  Kept in the map so
    # the refusal is measured rather than assumed.
    "chgda_24":   dict(native="chg", width=24, addr=1, regmap=None),

    # LD  (addr:24), r32 -- the 24-bit-address sibling of stda32
    "stl_da":     dict(native="ld", width=24, addr=0, regmap="r32"),

    # control transfer and address computation through a direct operand
    "jp_24":      dict(native="jp",    width=24, addr=1, regmap=None),
    "call_24":    dict(native="call",  width=24, addr=1, regmap=None),
    "lda_24":     dict(native="lda",   width=24, addr=1, regmap=None),
    "pushdi_24":  dict(native="pushw", width=24, addr=0, regmap=None, nops=1),
}

# ⚠ CONTROL for the operation claim (--foil op).  Every entry is a sibling of
# its key in the SAME encoding class -- same prefix byte, same operand shape,
# sub-opcode differing only in the ALU/bit selector -- so the foil spelling is
# always something the assembler will happily accept.  That is the point: it
# must be refused on BYTES, not on a parse error.
FOIL_OP = {
    "add": "sub", "sub": "add", "and": "or", "or": "and", "xor": "and",
    "cp": "and", "adc": "sbc", "sbc": "adc",
    "addw": "subw", "subw": "addw", "andw": "orw", "orw": "andw",
    "cpw": "andw", "ldw": "cpw",
    "inc": "dec", "dec": "inc", "incw": "decw", "decw": "incw",
    "res": "set", "set": "res", "bit": "res", "chg": "bit",
    "jp": "call", "call": "jp", "lda": "ld", "pushw": "push",
    "ld": "cp",
}

R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]

# A 32-bit register NAME written against a 16-bit form denotes the 16-bit
# register with the SAME FILE INDEX -- verified by encoding all eight, both
# spellings, and comparing the sub-opcode byte.
X_TO_16 = dict(zip(R32, R16))
# Against an 8-bit form it denotes that register pair's LOW BYTE.  Corroborated
# by the source's own comment at hdae5000/hdae5000_hd_driver.s:403,
#     ldb_da xwa, (0x229d99); c2 99 9d 22 21 - ld a, (0x229d99)
X_TO_8_LOW = {"xwa": "a", "xbc": "c", "xde": "e", "xhl": "l"}
# ...but ONLY for the LD-direct class.  ⚠ MEASURED 2026-09-04, w26/conv-alu:
# the ALU-direct class encodes a 32-bit name written in an 8-bit slot
# INDEX-PRESERVINGLY instead --
#     ldb_da xbc,(0x120000)  ->  0x23  = LD  base 0x20 + 3  = C   (low byte)
#     cpda8  xbc,(0x1000)    ->  0xf1  = CP  base 0xf0 + 1  = A   (same index)
# Two conventions live in one backend, split by instruction class.  So the
# converter must NOT assert either: it offers candidate spellings and keeps the
# one whose ENCODING matches the line it is replacing.  Which rule won is
# counted and reported, never assumed.
X_TO_8_IDX = dict(zip(R32, R8))

REGSETS = {"r32": set(R32), "r16": set(R16), "r8": set(R8)}
CLASS_NAMES = {"r32": R32, "r16": R16, "r8": R8}

MARK = "zzConvWidthMark"


def line_re(mnemonics):
    return re.compile(r'^(\t)(%s)([ \t]+)([^;]*?)([ \t]*)(;.*)?$'
                      % "|".join(sorted(mnemonics, key=len, reverse=True)))


def split_ops(s):
    """Split on top-level commas, honouring parentheses."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out


def unparen(a):
    """Strip ONE enclosing pair of parentheses, only if it really encloses."""
    if not (a.startswith("(") and a.endswith(")")):
        return a
    depth = 0
    for i, ch in enumerate(a):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return a[1:-1].strip() if i == len(a) - 1 else a
    return a


def reg_candidates(rm, written):
    """Candidate spellings for a register operand of class `rm`, best first.

    ⚠ NEVER ASSERT ONE.  A 32-bit name written against a narrower form is a
    mis-spelling whose meaning is decided by the sub-opcode the old line
    already encodes, and the two known rules disagree (see X_TO_8_* above).
    So return every name of the right class, ordered by how likely the rule
    is, and let the byte comparison pick.  Each name has a distinct
    sub-opcode, so at most one can match; a match is a MEASUREMENT of what the
    ROM byte says, not a guess.  The label is carried through so the run can
    report which rule resolved each site."""
    r = written.lower()
    if r in REGSETS[rm]:
        return [(written, "as-written")]
    out, seen = [], set()

    def add(name, why):
        if name and name not in seen:
            seen.add(name)
            out.append((name, why))

    if rm == "r16" and r in X_TO_16:
        add(X_TO_16[r], "index-preserving")
    elif rm == "r8" and r in R32:
        add(X_TO_8_IDX[r], "index-preserving")
        add(X_TO_8_LOW.get(r), "low-byte")
    elif rm == "r32" and r in X_TO_16.values():
        add(R32[R16.index(r)], "index-preserving")
    if not out:
        return []
    for name in CLASS_NAMES[rm]:            # exhaustive fallback, byte-decided
        add(name, "byte-search")
    return out


def rewrite(mn, operands, foil=None):
    """Return (list of candidate operand texts, None), or (None, reason).

    ⚠ CONTROL.  foil="width" states the OTHER address width (16<->24),
    foil="reg" leaves a 32-bit register name where the form needs a narrower
    one, and foil="op" substitutes a sibling operation of the same encoding
    class (add<->sub, and<->or, res<->set, inc<->dec, jp<->call).  Each must
    make this script REFUSE every site it would otherwise convert; a verifier
    that cannot go red has certified nothing.  See the README beside this file
    for the runs and their counts."""
    spec = MAP[mn]
    if len(operands) != spec.get("nops", 2):
        return None, "operand-count-%d" % len(operands)
    ops = list(operands)
    inner = unparen(ops[spec["addr"]])
    if inner.startswith("(") or not inner:
        return None, "unparseable-address"
    w = spec["width"]
    if foil == "width":
        w = 24 if w == 16 else 16
    ops[spec["addr"]] = "(%s:%d)" % (inner, w)
    rm = spec["regmap"]
    if foil == "reg" and rm in ("r16", "r8"):
        rm = None
    if not rm:
        return [(", ".join(ops), "no-register")], None
    oi = 1 - spec["addr"]
    cands = reg_candidates(rm, ops[oi])
    if not cands:
        return None, "unrecognised-register:%s" % ops[oi].lower()
    out = []
    for name, why in cands:
        o = list(ops)
        o[oi] = name
        out.append((", ".join(o), why))
    return out, None


# ------------------------------------------------------------------ assembler
ENCRX = re.compile(r'encoding: \[([^\]]*)\]')
FIXRX = re.compile(r'fixup \w+ - (.*)$')


def assemble(lines, mc):
    """Assemble each line in isolation.  Returns a list of signatures; None
    means the assembler rejected it."""
    src = []
    for i, l in enumerate(lines):
        src.append("%s%d:" % (MARK, i))
        src.append("\t" + l)
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False,
                                     encoding="utf-8") as fh:
        fh.write("\n".join(src) + "\n")
        path = fh.name
    try:
        p = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", path],
                           capture_output=True, text=True, errors="replace")
    finally:
        os.unlink(path)
    bad = set()
    for m in re.finditer(r'^[^\n:]*:(\d+):\d+: error:', p.stderr, re.M):
        idx = (int(m.group(1)) - 1) // 2
        if 0 <= idx < len(lines):
            bad.add(idx)
    sig, cur = {}, None
    for line in p.stdout.split("\n"):
        lm = re.match(r'^%s(\d+):' % MARK, line)
        if lm:
            cur = int(lm.group(1))
            sig.setdefault(cur, [])
            continue
        if cur is None:
            continue
        m = ENCRX.search(line)
        if m:
            sig[cur].append("E:" + m.group(1))
            continue
        m = FIXRX.search(line)
        if m:
            sig[cur].append("F:" + m.group(1))
    out = []
    for i in range(len(lines)):
        out.append(None if i in bad or not sig.get(i) else "|".join(sig[i]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mnemonic", action="append", default=[])
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--manifest", default=None,
                    help="write the list of files actually rewritten here, so "
                         "the commit can name its FILES rather than use -u")
    ap.add_argument("--report", default=None,
                    help="CSV of every refused site")
    ap.add_argument("--chunk", type=int, default=4000)
    ap.add_argument("--foil", choices=("width", "reg", "op"), default=None,
                    help="deliberately break the rewrite; every site must be "
                         "refused with BYTES-DIFFER (the verifier's control). "
                         "width states the other address width, reg leaves a "
                         "32-bit register name where a narrower one is meant, "
                         "op substitutes a sibling operation of the same "
                         "encoding class (add<->sub, and<->or, res<->set ...)")
    args = ap.parse_args()

    mns = list(MAP) if args.all else args.mnemonic
    bad = [m for m in mns if m not in MAP]
    if bad or not mns:
        sys.exit("give --all or --mnemonic from: %s (unknown: %s)"
                 % (" ".join(sorted(MAP)), bad))

    work = tempfile.mkdtemp(prefix="conv_width_")
    mc = os.path.join(work, "llvm-mc")
    shutil.copy2(LLVM_MC, mc)          # the shared toolchain is rebuilt under us
    print("llvm-mc sha256 %s"
          % hashlib.sha256(open(mc, "rb").read()).hexdigest()[:16])

    files = subprocess.run(["git", "ls-files", "*.s"],
                           capture_output=True, text=True).stdout.split()
    rx = line_re(mns)

    sites = []          # dicts, one per candidate site
    refused = []        # (path, lineno, mn, oldline, reason)
    for f in files:
        src = open(f, encoding="latin-1").read()
        for n, line in enumerate(src.split("\n")):
            m = rx.match(line)
            if not m:
                continue
            mn = m.group(2)
            cands, reason = rewrite(mn, split_ops(m.group(4)), args.foil)
            if cands is None:
                refused.append((f, n + 1, mn, line, reason))
                continue
            native = MAP[mn]["native"]
            if args.foil == "op":
                native = FOIL_OP.get(native, native)
            sites.append(dict(
                f=f, n=n + 1, mn=mn, old=line,
                oldasm=mn + " " + m.group(4).strip(),
                cands=[(m.group(1) + native + m.group(3) + ops
                        + m.group(5) + (m.group(6) or ""),
                        native + " " + ops, why) for ops, why in cands]))

    print("candidate sites: %d   refused before assembly: %d"
          % (len(sites), len(refused)))

    # ---- per-site byte verification -------------------------------------
    # ⚠ A site may offer SEVERAL candidate spellings (see reg_candidates).
    # Every candidate is assembled in isolation and the FIRST whose encoding
    # and fixups equal the old line's is kept; if none matches the site is
    # refused.  The winning candidate's rule label is counted, so "which
    # register-naming rule applies to this class" is a measurement.
    ok = []
    byrule = collections.Counter()
    flat = [(i, j, c[1]) for i, s in enumerate(sites)
            for j, c in enumerate(s["cands"])]
    oldsig = {}
    for base in range(0, len(sites), args.chunk):
        chunk = sites[base:base + args.chunk]
        for s, sig in zip(chunk, assemble([s["oldasm"] for s in chunk], mc)):
            oldsig[id(s)] = sig
    newsig = {}
    for base in range(0, len(flat), args.chunk):
        chunk = flat[base:base + args.chunk]
        for (i, j, _), sig in zip(chunk, assemble([c[2] for c in chunk], mc)):
            newsig[(i, j)] = sig
        sys.stderr.write("\r  verified %d/%d candidate spellings"
                         % (min(base + args.chunk, len(flat)), len(flat)))
    sys.stderr.write("\n")
    for i, s in enumerate(sites):
        o = oldsig[id(s)]
        if o is None:
            refused.append((s["f"], s["n"], s["mn"], s["old"],
                            "old-does-not-assemble"))
            continue
        hit = None
        for j, c in enumerate(s["cands"]):
            if newsig[(i, j)] == o:
                hit = (j, c)
                break
        if hit is None:
            first = newsig[(i, 0)]
            if all(newsig[(i, j)] is None for j in range(len(s["cands"]))):
                refused.append((s["f"], s["n"], s["mn"], s["old"],
                                "new-does-not-assemble"))
            else:
                refused.append((s["f"], s["n"], s["mn"], s["old"],
                                "BYTES-DIFFER old=%s new=%s" % (o, first)))
            continue
        j, c = hit
        byrule[c[2]] += 1
        ok.append([s["f"], s["n"], s["mn"], s["old"], c[0]])
    shutil.rmtree(work, ignore_errors=True)

    per = collections.Counter(c[2] for c in ok)
    ref = collections.Counter(r[2] for r in refused)
    why = collections.Counter(r[4].split()[0] for r in refused)
    print("\n%-10s %8s %8s" % ("mnemonic", "convert", "refuse"))
    for mn in sorted(mns, key=lambda m: -per[m]):
        print("%-10s %8d %8d" % (mn, per[mn], ref[mn]))
    print("%-10s %8d %8d" % ("TOTAL", len(ok), len(refused)))
    print("\nregister spelling resolved by:")
    for k, v in byrule.most_common():
        print("   %-30s %6d" % (k, v))
    if refused:
        print("\nrefusal reasons:")
        for k, v in why.most_common():
            print("   %-30s %6d" % (k, v))

    if args.report:
        with open(args.report, "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["file", "line", "mnemonic", "source", "reason"])
            for r in refused:
                w.writerow(r)
        print("\nwrote %s" % args.report)

    if args.foil:
        print("\nFOIL RUN (--foil %s): --apply is refused." % args.foil)
        return
    if not args.apply:
        print("\ndry run -- nothing written.  Re-run with --apply.")
        return

    byfile = collections.defaultdict(dict)
    for c in ok:
        byfile[c[0]][c[1]] = (c[3], c[4])
    changed = 0
    for f, edits in byfile.items():
        src = open(f, encoding="latin-1").read()
        lines = src.split("\n")
        for n, (old, new) in edits.items():
            assert lines[n - 1] == old, "%s:%d moved under us" % (f, n)
            lines[n - 1] = new
        # ⚠ encode the WHOLE file first.  open(...,"w",encoding="latin-1")
        # truncates the file to zero bytes when a character will not encode.
        data = "\n".join(lines).encode("latin-1")
        tmp = f + ".convtmp"
        with open(tmp, "wb") as fh:
            fh.write(data)
        os.replace(tmp, f)
        changed += 1
    print("\nrewrote %d files, %d lines" % (changed, len(ok)))
    if args.manifest:
        with open(args.manifest, "w") as fh:
            fh.write("\n".join(sorted(byfile)) + "\n")
        print("wrote %s" % args.manifest)


if __name__ == "__main__":
    main()
