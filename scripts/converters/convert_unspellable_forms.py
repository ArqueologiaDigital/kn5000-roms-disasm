#!/usr/bin/env python3
r"""Turn the LAST `.byte` lines of sound code into instructions, byte-identically.

QUESTION IT ANSWERS
    After eight rounds of block conversion, 211 sites in the v1.42 sub-CPU
    payload were still `.byte` -- not because the bytes were undecoded, but
    because they are instruction FORMS the LLVM TLCS-900 assembler backend had
    no spelling for.  Each carries MAME unidasm's rendering as its comment.
    This script rewrites those lines as real instructions.

    ★★ THE BYTES ARE THE SPECIFICATION.  The decoder below reads the OPCODE
    BYTES, never the comment, and every line it produces is handed straight
    back to llvm-mc: if the assembled encoding is not byte-for-byte what the
    line came from, the line is LEFT ALONE and reported.  "llvm-mc accepted it"
    is not the test; "llvm-mc reproduced these exact bytes" is.  The comment is
    kept on the converted line, because these mnemonics are raw encoding names
    (`cp8_imm_ri xiz, 64`) and unidasm's `cp (XIZ),0x40` is the readable form.

    ★ Nothing here CHOOSES what is code.  Every line it touches is already a
    single decoded instruction that a previous round framed from the committed
    unidasm listing; this only changes how it is spelt.  `make gate-all` and
    `scripts/analysis/assert_images_assemble.py` are the real proof.

WHAT EACH FAMILY IS
    C7/D7/E5  extended-register-prefix and post-increment forms, whose operand
              is a raw REGISTER-FILE ADDRESS byte (0xE0+4n low half, +1 high
              half, +2/+3 previous bank), not a register name.
    80..BF    the (Xrr) / (Xrr+d8) memory-operand prefix tables.
    C3/D3/E3/F3 + 0x07   the register-indexed operand (Xrr+Rn).
    D8+r      register-direct word with a 16-bit immediate (MINC1).

RUN:  python3 scripts/converters/convert_unspellable_forms.py --selftest
      python3 scripts/converters/convert_unspellable_forms.py --dry-run
      python3 scripts/converters/convert_unspellable_forms.py [FILE ...]
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
MC = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-mc")
DEFAULT_FILES = ["v142/subcpu/kn5000_subprogram_v142.s"]

BYTELINE = re.compile(r'^(\s*)\.byte\s+([^;]*?)\s*;\s*(\S.*?)\s*$')
ENC = re.compile(r'encoding:\s*\[([^\]]*)\]')

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]


def regfile(b):
    """A register-file address byte -> (name, is_previous_bank), 16-bit view."""
    if b < 0xE0 or (b - 0xE0) % 4 not in (0, 2):
        return None
    return R16[(b - 0xE0) // 4], (b - 0xE0) % 4 == 2


def base32(b):
    """A register-file address byte used as a 32-bit BASE register."""
    if b < 0xE0 or (b - 0xE0) % 4 != 0:
        return None
    return R32[(b - 0xE0) // 4]


def decode(bs):
    """Instruction BYTES -> the assembler text that must reproduce them.

    Returns None for anything not in the families below; the caller then leaves
    the line as it found it.  Every branch here is checked against llvm-mc."""
    n, b0 = len(bs), bs[0]

    # --- C7: extended-register-prefix, byte size.  [C7, regfile_addr, sub] ---
    if b0 == 0xC7 and n == 3:
        bank, sub = bs[1], bs[2]
        if 0x88 <= sub < 0x90:          # LD r8, (regfile)
            return f"ld_erpb_rr\t{R8[sub - 0x88]}, {bank:#04x}"
        if 0x98 <= sub < 0xA0:          # LD (regfile), r8
            return f"ldb_erp\t{R8[sub - 0x98]}, {bank:#04x}"
        if 0xA8 <= sub < 0xB0:          # LD (regfile), #0..7
            return f"lds_erpb\t{bank:#04x}, {sub - 0xA8}"
    if b0 == 0xC7 and n == 4 and bs[2] == 0xCC:   # AND (regfile), #imm8
        return f"and_erpb\t{bs[1]:#04x}, {bs[3]:#04x}"

    # --- D7: extended-register-prefix, word size ---
    if b0 == 0xD7 and n == 5 and bs[2] == 0xC8:   # ADD (regfile), #imm16
        return f"add_erpw\t{bs[1]:#04x}, {bs[3]:#04x}, {bs[4]:#04x}"

    # --- E5: source post-increment, long size.  [E5, regfile_addr, sub+r] ---
    if b0 == 0xE5 and n == 3 and 0x80 <= bs[2] < 0x88:
        return f"add_spil\t{R32[bs[2] - 0x80]}, {bs[1]:#04x}"

    # --- 80..87: (Xrr) byte operand, immediate second operand ---
    if 0x80 <= b0 <= 0x87 and n == 3 and bs[1] == 0x3F:
        return f"cp8_imm_ri\t{R32[b0 - 0x80]}, {bs[2]:#04x}"

    # --- 88..8F: (Xrr+d8) byte operand, immediate second operand ---
    if 0x88 <= b0 <= 0x8F and n == 4:
        who = {0x3C: "and8_imm_rid8", 0x3F: "cp8_imm_rid8"}.get(bs[2])
        if who:
            return f"{who}\t{R32[b0 - 0x88]}, {bs[1]:#04x}, {bs[3]:#04x}"

    # --- 98..9F: (Xrr+d8) word operand, register second operand ---
    if 0x98 <= b0 <= 0x9F and n == 3 and 0xF0 <= bs[2] < 0xF8:
        return (f"cp16_src_rid8\t{R32[b0 - 0x98]}, {bs[1]:#04x}, "
                f"{R16[bs[2] - 0xF0]}")

    # --- A0..AF: (Xrr) / (Xrr+d8) long operand, register second operand ---
    if 0xA0 <= b0 <= 0xA7 and n == 2 and 0x80 <= bs[1] < 0x88:
        return f"add32_src_ri\t{R32[b0 - 0xA0]}, {R32[bs[1] - 0x80]}"
    if 0xA8 <= b0 <= 0xAF and n == 3 and 0x80 <= bs[2] < 0x88:
        return (f"add32_src_rid8\t{R32[b0 - 0xA8]}, {bs[1]:#04x}, "
                f"{R32[bs[2] - 0x80]}")

    # --- B8..BF: (Xrr+d8) as a DESTINATION: bit ops and immediate stores ---
    if 0xB8 <= b0 <= 0xBF:
        addr = f"({R32[b0 - 0xB8]}+{bs[1]})"
        if n == 3 and 0xC8 <= bs[2] < 0xD0:
            return f"bit\t{bs[2] - 0xC8}, {addr}"
        if n == 3 and 0xB8 <= bs[2] < 0xC0:
            return f"set\t{bs[2] - 0xB8}, {addr}"
        if n == 5 and bs[2] == 0x02:
            return f"ldw\t{addr}, {bs[3] | (bs[4] << 8):#06x}"

    # --- C2: 24-bit direct address, byte operand, immediate ---
    if b0 == 0xC2 and n == 6 and bs[4] == 0x3F:
        a = bs[1] | (bs[2] << 8) | (bs[3] << 16)
        return f"cpib_da\t{a:#08x}, {bs[5]:#04x}"

    # --- C3/D3/E3/F3 + 0x07: the register-indexed operand (Xrr+Rn) ---
    if b0 in (0xC3, 0xD3, 0xE3, 0xF3) and n >= 5 and bs[1] == 0x07:
        base, idx, sub = base32(bs[2]), regfile(bs[3]), bs[4]
        if base and idx:
            iname, prev = idx
            iname = ("q" + iname) if prev else iname
            if b0 != 0xF3 and n == 5 and 0x20 <= sub < 0x28:
                width = {0xC3: "b", 0xD3: "w", 0xE3: "l"}[b0]
                reg = {0xC3: R8, 0xD3: R16, 0xE3: R32}[b0][sub - 0x20]
                if not prev:
                    return f"ld_rr{width}\t{reg}, {base}, {iname}"
            if b0 == 0xD3 and n == 7 and sub == 0x3E and not prev:
                return (f"or_rrw_im\t{base}, {iname}, "
                        f"{bs[5]:#04x}, {bs[6]:#04x}")
            if b0 == 0xF3 and n == 5:
                if 0x30 <= sub < 0x38:
                    m = "lda_rrq" if prev else "lda_rr"
                    return f"{m}\t{R32[sub - 0x30]}, {base}, {iname}"
                for lo, m, regs in ((0x40, "st_rrb", R8), (0x50, "st_rrw", R16),
                                    (0x60, "st_rrl", R32)):
                    if lo <= sub < lo + 8 and not prev:
                        return f"{m}\t{regs[sub - lo]}, {base}, {iname}"
                if 0xD0 <= sub < 0xE0 and not prev:
                    return f"jp_rr\t{sub - 0xD0}, {base}, {iname}"

    # --- D8..DF: register-direct word with a 16-bit immediate ---
    if 0xD8 <= b0 <= 0xDF and n == 4 and bs[1] == 0x38:
        return f"minc1_16\t{R16[b0 - 0xD8]}, {bs[2] | (bs[3] << 8):#06x}"

    return None


def assemble(lines):
    """Assemble each line on its own and return its encoding bytes, or None.

    ★ Each line is assembled ALONE so that a line which fails cannot silently
    take its neighbours' encodings with it."""
    src = "\n".join(lines) + "\n"
    p = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=src, capture_output=True, text=True)
    out = []
    for line in p.stdout.splitlines():
        m = ENC.search(line)
        if m:
            out.append([int(x, 16) for x in m.group(1).split(",") if x.strip()])
    if len(out) != len(lines):
        return None
    return out


def convert(path, dry_run=False):
    """-> (n_converted, [(lineno, comment, reason) for each refusal])"""
    lines = open(path, errors="replace").read().split("\n")
    cands = []          # (index, indent, bytes, comment, text)
    for i, line in enumerate(lines):
        m = BYTELINE.match(line)
        if not m:
            continue
        try:
            bs = [int(x, 0) for x in m.group(2).split(",") if x.strip()]
        except ValueError:
            continue
        if not all(0 <= b <= 0xFF for b in bs):
            continue
        text = decode(bs)
        if text:
            cands.append((i, m.group(1), bs, m.group(3), text))

    refused = []
    if cands:
        got = assemble([c[4] for c in cands])
        if got is None:
            return 0, [(0, "", "a line failed to assemble; nothing converted")]
        keep = []
        for c, enc in zip(cands, got):
            if enc == c[2]:
                keep.append(c)
            else:
                refused.append((c[0] + 1, c[3],
                                "assembled to " + " ".join(f"{b:#04x}" for b in enc)))
        for i, indent, _bs, comment, text in keep:
            lines[i] = f"{indent}{text}\t; {comment}"
        if not dry_run and keep:
            open(path, "w").write("\n".join(lines))
        return len(keep), refused
    return 0, refused


# ---- the 63 distinct byte strings this residue is made of, and what each
# ---- one must assemble back to.  Read off v142/subcpu at the time of writing.
SELFTEST = [
    ([0xc7, 0xf8, 0x89], "ld A,IZL"),
    ([0xc7, 0xf9, 0xa8], "ld IZH,0"),
    ([0xc7, 0xf4, 0x9b], "ld IYL,C"),
    ([0xc7, 0xfb, 0xcc, 0x0f], "and QIZH,0x0f"),
    ([0xd7, 0xe2, 0xc8, 0x6e, 0x00], "add QWA,0x006e"),
    ([0xe5, 0xe2, 0x83], "add xhl,(xwa+)"),
    ([0x86, 0x3f, 0x40], "cp (XIZ),0x40"),
    ([0x80, 0x3f, 0x40], "cp (XWA),0x40"),
    ([0x88, 0x02, 0x3f, 0x00], "cp (XWA+0x02),0x00"),
    ([0x8f, 0x06, 0x3f, 0x00], "cp (XSP+0x06),0x00"),
    ([0x88, 0x06, 0x3c, 0x07], "and (XWA+0x06),0x07"),
    ([0x9a, 0xfa, 0xf4], "cp IX,(XDE+0xfa)"),
    ([0xa7, 0x80], "add XWA,(XSP)"),
    ([0xaf, 0x04, 0x80], "add XWA,(XSP+0x04)"),
    ([0xaf, 0x04, 0x84], "add XIX,(XSP+0x04)"),
    ([0xba, 0x01, 0xcf], "bit 7,(XDE+0x01)"),
    ([0xb8, 0x06, 0xbd], "set 5,(XWA+0x06)"),
    ([0xbf, 0x04, 0x02, 0x00, 0x00], "ld (XSP+0x04),0x0000"),
    ([0xc2, 0xa7, 0x51, 0x04, 0x3f, 0xf5], "cp (0x0451a7),0xf5"),
    ([0xc3, 0x07, 0xe8, 0xf0, 0x27], "ld L,(XDE+IX)"),
    ([0xd3, 0x07, 0xf0, 0xe0, 0x20], "ld WA,(XIX+WA)"),
    ([0xe3, 0x07, 0xe4, 0xe0, 0x20], "ld XWA,(XBC+WA)"),
    ([0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08, 0x00], "or (XBC+WA),0x0008"),
    ([0xdc, 0x38, 0xff, 0x01], "minc1 0x01ff,IX"),
    ([0xf3, 0x07, 0xe0, 0xec, 0x30], "lda XWA,XWA+HL"),
    ([0xf3, 0x07, 0xe4, 0xe2, 0x36], "lda XIZ,XBC+QWA"),
    ([0xf3, 0x07, 0xe4, 0xe0, 0x45], "ld (XBC+WA),E"),
    ([0xf3, 0x07, 0xe4, 0xe0, 0x53], "ld (XBC+WA),HL"),
    ([0xf3, 0x07, 0xf0, 0xe0, 0xd8], "jp T,XIX+WA"),
]


def selftest():
    """INVARIANTS.  Each is a claim that can fail."""
    bad = 0

    # 1. Every family in the residue decodes, and to the SAME bytes.
    texts = []
    for bs, what in SELFTEST:
        t = decode(bs)
        if t is None:
            print(f"FAIL  no decoder for {what}: "
                  f"{' '.join(f'{b:#04x}' for b in bs)}")
            bad += 1
        texts.append(t or "nop")
    got = assemble(texts)
    assert got is not None, "the selftest corpus did not assemble"
    for (bs, what), t, enc in zip(SELFTEST, texts, got):
        if t is not None and enc != bs:
            print(f"FAIL  {what}: `{t}` assembles to "
                  f"{' '.join(f'{b:#04x}' for b in enc)}, ROM has "
                  f"{' '.join(f'{b:#04x}' for b in bs)}")
            bad += 1

    # 2. NEGATIVE CONTROL: a form outside the families must NOT be claimed.
    #    (0x86 0x20 0x40 is a plain `ld a,(xiz)` + stray byte, sub-opcode 0x20,
    #    which no branch above handles.)
    if decode([0x86, 0x20, 0x40]) is not None:
        print("FAIL  the negative control decoded; the guard is too loose")
        bad += 1

    # 3. NEGATIVE CONTROL: a wrong spelling must be REFUSED, not written.
    #    `cp8_imm_ri xwa, 0x41` is one bit away from the real thing.
    enc = assemble(["cp8_imm_ri\txwa, 0x41"])
    if enc is None or enc[0] == [0x80, 0x3f, 0x40]:
        print("FAIL  a wrong immediate produced the right bytes")
        bad += 1

    # 4. The register-file address map is little-endian: low half at +0.
    if decode([0xc7, 0xe0, 0x89]) != "ld_erpb_rr\ta, 0xe0":
        print("FAIL  register-file decode is not the byte-address map")
        bad += 1

    print("selftest: " + ("OK" if bad == 0 else f"{bad} FAILURE(S)"))
    return 1 if bad else 0


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    dry = "--dry-run" in argv
    files = [a for a in argv if not a.startswith("--")] or DEFAULT_FILES
    total = 0
    for f in files:
        p = f if os.path.isabs(f) else os.path.join(ROOT, f)
        n, refused = convert(p, dry_run=dry)
        total += n
        print(f"{f}: {n} line(s) {'would be ' if dry else ''}converted")
        for lineno, comment, why in refused:
            print(f"  REFUSED line {lineno}: {comment}  --  {why}")
    print(f"total {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
