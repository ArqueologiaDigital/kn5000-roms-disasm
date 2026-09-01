#!/usr/bin/env python3
"""Does a NATIVE llvm-mc spelling emit the same bytes as the macro it would replace?

QUESTION IT ANSWERS: `wsa1/include/tlcs900_mem_ops.inc` works around llvm-mc with
122 byte-emitting macros.  As gaps in the assembler are closed, each macro call
site becomes retireable -- but only if the native spelling emits BYTE-IDENTICAL
code.  "llvm-mc accepted it" is not evidence (see llvm_encoding_gaps.py, class C).
This tool assembles BOTH spellings of every real call site in the tree and
compares them byte for byte.

RUN:  python3 wsa1/notes/llvm/llvm_native_equivalence.py            # summary
      python3 wsa1/notes/llvm/llvm_native_equivalence.py -v         # + mismatches
      python3 wsa1/notes/llvm/llvm_native_equivalence.py --selftest # exit 1 on any
                                                                   # covered mismatch

HOW IT ATTRIBUTES A BYTE RUN TO A LINE.  Both sides are assembled as one file
each, with `.balign 16, 0x00` after every instruction, so instruction i of each
side occupies slot i of a 16-byte grid (no encoding here exceeds 7 bytes).  Two
llvm-mc runs per macro, and still per-line attribution.

WHAT "COVERED" MEANS.  Only the macros in TABLE below have a native spelling
written for them, and only for the addressing classes noted.  Everything else is
reported as NOT COVERED -- an honest "no native form is claimed", not a pass.
"""
import os, re, subprocess, sys, tempfile, collections

HERE = os.path.dirname(os.path.abspath(__file__))
WSA1 = os.path.abspath(os.path.join(HERE, "..", ".."))
INC = os.path.join(WSA1, "include")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")

# prefix name -> (operand size letter, direct-address bytes or None)
DIRECT = {}
for base, size in (("MB", "b"), ("MW", "w"), ("ML", "l"), ("MD", "d")):
    for w, n in (("8", 1), ("16", 2), ("24", 3)):
        DIRECT[base + w] = (size, n)
INDIRECT = {"MBI": "b", "MWI": "w", "MLI": "l", "MDI": "d"}
DISP8 = {"MBD": "b", "MWD": "w", "MLD": "l", "MDD": "d"}

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
XR = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
REGS = {"b": R8, "w": R16, "l": R32}


def mem(pfx, addr):
    """Render the memory operand named by a macro's prefix argument.

    ⚠ The MBD/MWD/MLD/MDD prefixes take ONE RAW displacement byte, so the
    macro's argument is an UNSIGNED byte -- 0xfe means -2.  llvm-mc reads a
    displacement as a signed number and escalates anything outside -128..127
    to the (Xrr+d16) form, so the byte has to be sign-extended here or the
    two sides disagree for every negative frame offset.  A displacement of
    zero is a second special case: the macro still emits the two-byte d8
    prefix, and the backend spells that with its documented `+256` sentinel.
    """
    head = pfx.split("+")[0].strip()
    idx = pfx.split("+")[1].strip() if "+" in pfx else None
    if head in DIRECT:
        size, nbytes = DIRECT[head]
        return size, "(%s:%d)" % (addr, nbytes * 8)
    if head in INDIRECT:
        return INDIRECT[head], "(%s)" % XR[int(idx[1])]
    if head in DISP8:
        d = addr
        try:
            v = int(addr, 0)
        except (TypeError, ValueError):
            return None, None          # symbolic d8: no spelling claimed
        if v == 0:
            d = "256"                  # force-d8-with-zero sentinel
        elif 0x80 <= v <= 0xFF:
            d = str(v - 256)
        elif not (-128 <= v <= 127):
            return None, None
        else:
            d = str(v)
        return DISP8[head], "(%s+%s)" % (XR[int(idx[1])], d)
    return None, None


def reg(size, r, width=None):
    """Register named by an r0..r7 macro argument.

    `size` is the operand size the PREFIX chose; `width` overrides it for the
    forms whose sub-opcode fixes the register width independently of the
    prefix (the destination table's `ld (mem),R8` / `R16` / `R32` trio, say).
    """
    size = width or size
    r = r.strip()
    # Call sites write the register index either as the file's r0..r7
    # constants or as a bare number; both mean the same field.
    m = re.fullmatch(r"r?([0-7])", r)
    if not m:
        return None
    return REGS.get("l" if size == "d" else size, R8)[int(m.group(1))]


# --- native spellings ------------------------------------------------------
# Each entry maps a macro to a function (args) -> native assembly text, or None
# when this call site has no native spelling claimed.
def _mi(mnem, sizes=("b",)):
    def f(a):
        size, op = mem(a[0], a[1])
        if size not in sizes:
            return None
        return "%s %s, %s" % (mnem, op, a[2])
    return f


def _rm(mnem, width=None):
    def f(a):
        size, op = mem(a[0], a[1])
        if op is None:
            return None
        r = reg(size, a[2], width)
        return None if r is None else "%s %s, %s" % (mnem, r, op)
    return f


def _mr(mnem, width=None):
    def f(a):
        size, op = mem(a[0], a[1])
        if op is None:
            return None
        r = reg(size, a[2], width)
        return None if r is None else "%s %s, %s" % (mnem, op, r)
    return f


def _mi_dst(mnem):
    """`ld (mem),#imm` and friends: prefix is from the destination table, so the
    operand size does not name the immediate width -- the macro does."""
    def f(a):
        _size, op = mem(a[0], a[1])
        return None if op is None else "%s %s, %s" % (mnem, op, a[2])
    return f


CC = ["f", "lt", "le", "ule", "ov", "mi", "z", "c",
      "t", "ge", "gt", "ugt", "nov", "pl", "nz", "nc"]


def _cc(mnem):
    def f(a):
        _size, op = mem(a[0], a[1])
        if op is None:
            return None
        try:
            n = int(a[2], 0)
        except ValueError:
            return None
        return "%s %s, %s" % (mnem, CC[n & 15], op)
    return f


def _sized(byte_mnem, word_mnem):
    """A memory-only form whose mnemonic carries the operand size."""
    def f(a):
        size, op = mem(a[0], a[1])
        if op is None:
            return None
        m = byte_mnem if size == "b" else (word_mnem if size == "w" else None)
        return None if m is None else "%s %s" % (m, op)
    return f


def _bitop_sized(byte_mnem, word_mnem):
    def f(a):
        size, op = mem(a[1], a[2])
        if op is None:
            return None
        m = byte_mnem if size == "b" else (word_mnem if size == "w" else None)
        return None if m is None else "%s %s, %s" % (m, a[0], op)
    return f


def _bitop(mnem):
    # macro signature is (n, pfx, addr) -- the bit number comes first
    def f(a):
        size, op = mem(a[1], a[2])
        if op is None:
            return None
        return "%s %s, %s" % (mnem, a[0], op)
    return f


def _unary(byte_mnem, word_mnem=None):
    def f(a):
        size, op = mem(a[0], a[1])
        if op is None:
            return None
        m = word_mnem if (size == "w" and word_mnem) else byte_mnem
        return None if m is None else "%s %s" % (m, op)
    return f


TABLE = {
    "m_cp_mi8":  _mi("cp"),
    "m_and_mi8": _mi("and"),
    "m_or_mi8":  _mi("or"),
    "m_xor_mi8": _mi("xor"),
    "m_add_mi8": _mi("add"),
    "m_sub_mi8": _mi("sub"),
    "m_cp_mi16":  _mi("cpw", ("w",)),
    "m_and_mi16": _mi("andw", ("w",)),
    "m_or_mi16":  _mi("orw", ("w",)),
    "m_add_mi16": _mi("addw", ("w",)),
    "m_bit": _bitop("bit"),
    "m_set": _bitop("set"),
    "m_res": _bitop("res"),
    "m_chg": _bitop("chgm"),
    "m_cp_rm":  _rm("cp"),
    "m_ld_rm":  _rm("ld"),
    "m_add_rm": _rm("add"),
    "m_sub_rm": _rm("sub"),
    "m_and_rm": _rm("and"),
    "m_or_rm":  _rm("or"),
    "m_xor_rm": _rm("xor"),
    "m_cp_mr":  _mr("cp"),
    "m_add_mr": _mr("add"),
    "m_sub_mr": _mr("sub"),
    "m_push": _unary("push", "pushw"),
    # POP and the carry-flag group sit in the DESTINATION table, so their
    # prefixes are MD* and the operand size comes from the mnemonic.
    "m_popw": _unary("popw"),
    "m_pop": _unary("pop"),
    "m_andcf_a": _unary("andcf a,"),
    "m_orcf_a": _unary("orcf a,"),
    "m_xorcf_a": _unary("xorcf a,"),
    "m_ldcf_a": _unary("ldcf a,"),
    "m_stcf_a": _unary("stcf a,"),
    "m_ld_mi8": _mi_dst("ld"),
    "m_ld_mi16": _mi_dst("ldw"),
    "m_st_mr8": _mr("ld", "b"),
    "m_st_mr16": _mr("ld", "w"),
    "m_st_mr32": _mr("ld", "l"),
    "m_lda16": _rm("lda", "w"),
    "m_lda32": _rm("lda", "l"),
    "m_stcf": _bitop("stcf"),
    "m_mul": _rm("mul"),
    "m_muls": _rm("muls"),
    "m_div": _rm("div"),
    "m_divs": _rm("divs"),
    "m_ex_mr": _mr("ex"),
    "m_and_mr": _mr("and"),
    "m_or_mr": _mr("or"),
    "m_xor_mr": _mr("xor"),
    "m_inc": _bitop_sized("inc", "incw"),
    "m_dec": _bitop_sized("dec", "decw"),
    "m_rlc_m": _sized("rlc", "rlcw"),
    "m_rrc_m": _sized("rrc", "rrcw"),
    "m_rl_m": _sized("rl", "rlw"),
    "m_rr_m": _sized("rr", "rrw"),
    "m_sla_m": _sized("sla", "slaw"),
    "m_sra_m": _sized("sra", "sraw"),
    "m_sll_m": _sized("sll", "sllw"),
    "m_srl_m": _sized("srl", "srlw"),
    "m_jp_cc": _cc("jp"),
    "m_call_cc": _cc("call"),
}


def parse_macros():
    out = {}
    for line in open(os.path.join(INC, "tlcs900_mem_ops.inc")):
        m = re.match(r"\.macro\s+([a-z0-9_]+)\s*(.*)", line.split(";")[0])
        if m:
            out[m.group(1)] = [a.strip() for a in m.group(2).split(",") if a.strip()]
    return out


def call_sites(known):
    sites = []
    for dp, _, fns in os.walk(WSA1):
        for fn in sorted(fns):
            if not fn.endswith(".s"):
                continue
            path = os.path.join(dp, fn)
            for n, line in enumerate(open(path, errors="replace"), 1):
                code = line.split(";")[0]
                m = re.match(r"\s+([a-z][a-z0-9_]*)\s+(.*)", code)
                if not m or m.group(1) not in known:
                    continue
                sites.append((m.group(1), [a.strip() for a in m.group(2).split(",")],
                              path, n))
    return sites


def symbol_preamble():
    """`.equ` definitions found in the tree.

    Call sites name addresses symbolically (`m_ld_rm MW8, KERNEL_CURRENT_TASK,
    r5`).  Assembling a single line out of context leaves those undefined, and
    a macro that does `.byte (\\addr) & 0xFF` then fails with "expected
    relocatable expression" -- so the real values are collected and replayed
    here.  Both sides see the same definitions, so this cannot make a
    mismatch look like agreement.
    """
    seen, out = set(), []
    for dp, _, fns in os.walk(WSA1):
        for fn in sorted(fns):
            if not (fn.endswith(".s") or fn.endswith(".inc")):
                continue
            for line in open(os.path.join(dp, fn), errors="replace"):
                m = re.match(r"\s*\.(?:equ|set)\s+([A-Za-z_][A-Za-z0-9_]*)\s*,\s*([^;]+)",
                             line)
                if not m:
                    continue
                name, val = m.group(1), m.group(2).strip()
                if name in seen or not re.fullmatch(r"(0x[0-9a-fA-F]+|\d+)", val):
                    continue
                seen.add(name)
                out.append(".ifndef %s\n.equ %s, %s\n.endif" % (name, name, val))
    return "\n".join(out) + "\n"


PREAMBLE = None
HEADER_LINES = None  # set once PREAMBLE is known


def assemble(lines):
    """Assemble one line per 16-byte slot; -> list of 16-byte slots, or None."""
    src = "\n".join("\t%s\n\t.balign 16, 0x00" % l for l in lines)
    with tempfile.TemporaryDirectory() as d:
        s, o, b = (os.path.join(d, n) for n in ("t.s", "t.o", "t.bin"))
        open(s, "w").write('.include "tlcs900_mem_ops.inc"\n' + PREAMBLE +
                           ".text\n.balign 16, 0x00\n" + src + "\n")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", INC,
                            "-o", o, s], capture_output=True, text=True)
        if r.returncode != 0:
            return None, r.stderr
        subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", o, b],
                       capture_output=True)
        data = open(b, "rb").read()
    return [data[i * 16:(i + 1) * 16] for i in range(len(lines))], ""


def refused_slots(stderr, nlines):
    """Slot indices llvm-mc refused, read out of its error line numbers."""
    bad = set()
    # Both a direct error (`t.s:N:`) and the "while in macro instantiation"
    # note that follows an error inside a macro carry the outer line number.
    for m in re.finditer(r"t\.s:(\d+):", stderr, re.M):
        ln = int(m.group(1))
        slot = (ln - HEADER_LINES - 1) // 2
        if 0 <= slot < nlines:
            bad.add(slot)
    return bad


ADDR_CLASS = {}
for _b, _n in (("MB", 1), ("MW", 1), ("ML", 1), ("MD", 1)):
    pass
for _base in ("MB", "MW", "ML", "MD"):
    for _w, _bytes in (("8", 1), ("16", 2), ("24", 3)):
        ADDR_CLASS[_base + _w] = "direct%d" % _bytes
for _p in ("MBI", "MWI", "MLI", "MDI"):
    ADDR_CLASS[_p] = "reg-indirect"
for _p in ("MBD", "MWD", "MLD", "MDD"):
    ADDR_CLASS[_p] = "reg+d8"
for _p in ("MXB", "MXW", "MXL", "MXD"):
    ADDR_CLASS[_p] = "reg-indexed"
for _p in ("RB", "RW", "RL", "RBX", "RWX", "RLX"):
    ADDR_CLASS[_p] = "reg-direct"


def classes(known, sites):
    """Split the call sites by ADDRESSING CLASS.

    This is the number that says how much work is left: the direct* and
    reg+d8/reg-indirect classes are the ones a native memory operand can
    spell, while reg-indexed, reg-direct and the prefixless block transfers
    need features the assembler does not have.
    """
    counts = collections.Counter()
    for name, args, _p, _n in sites:
        params = known[name]
        pi = params.index("pfx") if "pfx" in params else (
            params.index("rp") if "rp" in params else None)
        if pi is None or pi >= len(args):
            counts["no prefix argument"] += 1
            continue
        counts[ADDR_CLASS.get(args[pi].split("+")[0].strip(), "literal prefix byte")] += 1
    return counts


def main():
    verbose = "-v" in sys.argv
    if not os.path.exists(MC):
        print("llvm-mc not built at %s" % MC)
        return 2
    global PREAMBLE, HEADER_LINES
    PREAMBLE = symbol_preamble()
    HEADER_LINES = 3 + PREAMBLE.count("\n")  # .include + preamble + .text + .balign
    known = parse_macros()
    sites = call_sites(known)
    if "--classes" in sys.argv:
        cc = classes(known, sites)
        print("%d macro call sites, by ADDRESSING CLASS:" % len(sites))
        for k, v in cc.most_common():
            print("  %-20s %6d" % (k, v))
        return 0
    bymac = collections.defaultdict(list)
    for name, args, path, n in sites:
        bymac[name].append((args, path, n))

    tot = len(sites)
    covered = same = diff = norender = refused = 0
    rows = []
    for name in sorted(bymac, key=lambda k: -len(bymac[k])):
        group = bymac[name]
        fn = TABLE.get(name)
        if fn is None:
            rows.append((name, len(group), 0, 0, 0, "not covered"))
            continue
        pairs = []
        for args, path, n in group:
            try:
                native = fn(args)
            except Exception:
                native = None
            if native is None:
                continue
            pairs.append((args, native, path, n))
        norender += len(group) - len(pairs)
        if not pairs:
            rows.append((name, len(group), 0, 0, 0, "no native spelling rendered"))
            continue
        # Some individual sites are refused by one side or the other (a
        # symbolic operand the other spelling cannot take, say).  Drop those
        # -- reporting them as "refused" rather than as agreement or as a
        # mismatch -- and keep the rest, so one odd line does not hide a
        # thousand good ones.
        note = ""
        for _attempt in range(6):
            macro_lines = ["%s %s" % (name, ", ".join(a)) for a, _, _, _ in pairs]
            native_lines = [nat for _, nat, _, _ in pairs]
            ms, merr = assemble(macro_lines)
            ns, nerr = assemble(native_lines)
            bad = set()
            if ms is None:
                bad |= refused_slots(merr, len(pairs))
                note = "macro side refused some sites"
            if ns is None:
                bad |= refused_slots(nerr, len(pairs))
                note = "native side refused some sites"
            if not bad:
                break
            refused += len(bad)
            pairs = [p for i, p in enumerate(pairs) if i not in bad]
            if not pairs:
                break
        if not pairs or ms is None or ns is None:
            rows.append((name, len(group), 0, 0, 0,
                         (merr or nerr or "").strip().split("\n")[0][:60]))
            continue
        ok = bad = 0
        for i, (args, nat, path, n) in enumerate(pairs):
            if ms[i] == ns[i]:
                ok += 1
            else:
                bad += 1
                if verbose and bad <= 5:
                    print("  MISMATCH %s:%d\n    macro  %s -> %s\n    native %s -> %s"
                          % (os.path.relpath(path, WSA1), n,
                             macro_lines[i], ms[i].rstrip(b"\0").hex(),
                             nat, ns[i].rstrip(b"\0").hex()))
        covered += len(pairs)
        same += ok
        diff += bad
        rows.append((name, len(group), len(pairs), ok, bad,
                     ("RETIREABLE" if bad == 0 else "%d differ" % bad)
                     + ((" (" + note + ")") if note else "")))

    print("%-18s %6s %6s %6s %6s  %s" %
          ("macro", "sites", "tried", "same", "diff", "verdict"))
    for r in rows:
        print("%-18s %6d %6d %6d %6d  %s" % r)
    print("\n%d call sites total; %d attempted natively; %d BYTE-IDENTICAL, %d differ"
          % (tot, covered, same, diff))
    print("%d sites in covered macros had no native spelling rendered "
          "(addressing class not claimed)" % norender)
    print("%d sites were refused by one side and excluded from the comparison"
          % refused)
    if "--selftest" in sys.argv:
        print("\nselftest: %s" % ("PASS" if diff == 0 else "FAIL -- %d differ" % diff))
        return 1 if diff else 0
    return 0


sys.exit(main())
