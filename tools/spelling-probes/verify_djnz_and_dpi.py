#!/usr/bin/env python3
"""Prove the llvm-mc spellings for `djnz r,imm` and `ld (r+),r` byte-for-byte.

QUESTION IT ANSWERS
    For every site of the two forms the blocking-forms census reports as
    unspellable (`djnz r,imm`, `ld (r+),r`), does the proposed llvm-mc spelling
    assemble to EXACTLY the bytes the KN5000 v7 ROM holds at that address?

SIGNAL READ
    original_ROMs/kn5000_v7_program.rom at addr-0xE00000, 3 bytes per site.
    PASS = llvm-mc's output bytes are identical to those 3 ROM bytes.

    `djnz` is a PC-RELATIVE BRANCH, so its third byte is a link-time fixup and
    `--show-encoding` prints a placeholder `A`.  Each djnz site is therefore
    assembled to an OBJECT with a real label planted at the branch target's
    distance, and the bytes are read back out of `.text` -- the displacement is
    checked, not assumed.

NEGATIVE CONTROLS (must FAIL, or the test cannot fail)
    * djnz written with a NUMERIC target, `djnz16 bc, 0xef8480`: llvm-mc takes
      the low byte of the address as the displacement, exactly as it does for
      `jr nz, 0x...`.  Every site must mismatch.
    * the 8-bit post-increment store written with the natural-looking
      `stb_dpi a, 0xec`: that def sits on sub-opcode 0x30, which the hardware
      uses for LDA.  Every 8-bit site must mismatch.

RUN
    python3 tools/spelling-probes/verify_djnz_and_dpi.py
    (needs ~/compartilhado/llvm-project/build/bin/{llvm-mc,llvm-objcopy})
"""
import os, re, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
ROM = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
WORK = tempfile.mkdtemp(prefix="djnz_dpi_")

# ---------------------------------------------------------------- the sites
# Produced by replaying convert_reachable_ranges' decode loop over every entry
# in analysis/v7-reachability/v7_call_targets.json; see README-djnz_and_dpi.md.
# (address, unidasm text, branch target or None)
DJNZ = [
    (0xEF8484, "djnz BC,0xef8480", 0xEF8480),
    (0xEF852F, "djnz BC,0xef850d", 0xEF850D),
    (0xEF870C, "djnz BC,0xef86d6", 0xEF86D6),
    (0xEFF455, "djnz BC,0xeff452", 0xEFF452),
    (0xF0FA00, "djnz C,0xf0f9af",  0xF0F9AF),
    (0xF50EF4, "djnz IZ,0xf50eb3", 0xF50EB3),
    (0xF97839, "djnz IZ,0xf97833", 0xF97833),
]
DPI = [
    (0xEFF452, "ld (XIX+),WA"),
    (0xF50ED0, "ld (XWA+),E"),
    (0xF5114A, "ld (XDE+),C"),
    (0xF96851, "ld (XIZ+),L"),
    (0xFD7DFB, "ld (XHL+),WA"),
    (0xFDAA34, "ld (XHL+),A"),
    (0xFDAA37, "ld (XHL+),C"),
    (0xFDAA3A, "ld (XHL+),E"),
    (0xFDAA40, "ld (XHL+),A"),
    (0xFDAA65, "ld (XHL+),A"),
    (0xFDAA68, "ld (XHL+),C"),
    (0xFDAA6B, "ld (XHL+),E"),
    (0xFDAA71, "ld (XHL+),A"),
    (0xFEFC14, "ld (XDE+),A"),
    (0xFEFCB4, "ld (XDE+),A"),
    (0xFF0526, "ld (XIX+),A"),
]

# ------------------------------------------------------------ the spellings
#
# djnz: the mnemonic carries the OPERAND WIDTH and the printed register name is
# written as-is.  `djnz` alone takes a 32-bit GPR (and still emits the D8 16-bit
# prefix), so a printed 16-bit name must use `djnz16` and an 8-bit name `djnz8`.
R8  = {"W", "A", "B", "C", "D", "E", "H", "L"}
R16 = {"WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"}


def djnz_spelling(text):
    reg = text.split(None, 1)[1].split(",")[0].strip().upper()
    mn = "djnz8" if reg in R8 else ("djnz16" if reg in R16 else "djnz")
    return mn, reg.lower()


# ld (r+),r : F5 prefix, [F5, base_reg_byte, SubOpc + reg_code].
#   base_reg_byte = XRR's register byte + (increment size - 1):
#     XWA=0xE0 XBC=0xE4 XDE=0xE8 XHL=0xEC XIX=0xF0 XIY=0xF4 XIZ=0xF8 XSP=0xFC
#     +0 for a byte store, +1 for a word store, +3 for a long store.
#   SubOpc = 0x40 (byte) / 0x50 (word) / 0x60 (long), + the register's code.
#
# ⚠ THE 8-BIT STORE HAS NO CORRECTLY-NAMED DEF.  The backend's F5 block still
# carries the LDA/byte-store swap that was fixed for the F3 (DRI) block in
# tlcs900_backend 1b9432474daa: `stb_dpi` sits on 0x30 (which the hardware uses
# for LDA) and `lda_dpi` sits on 0x40 (the byte store).  So the spelling that
# emits the right bytes today is `lda_dpi <GPR whose code equals the 8-bit
# register's code>`.  Both spellings are emitted below and the ROM decides,
# which is also what makes the rule survive the backend being fixed.
XBASE = {"XWA": 0xE0, "XBC": 0xE4, "XDE": 0xE8, "XHL": 0xEC,
         "XIX": 0xF0, "XIY": 0xF4, "XIZ": 0xF8, "XSP": 0xFC}
R8_CODE = {"W": 0, "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "H": 6, "L": 7}
R16_CODE = {"WA": 0, "BC": 1, "DE": 2, "HL": 3, "IX": 4, "IY": 5, "IZ": 6, "SP": 7}
GPR_BY_CODE = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]


def dpi_spellings(text):
    """Every candidate spelling for `ld (<XRR>+),<reg>`, best first."""
    m = re.match(r'^ld\s+\((X[A-Z]{2})\+\),([A-Z]{1,3})$', text)
    assert m, text
    base, reg = m.group(1), m.group(2)
    b = XBASE[base]
    out = []
    if reg in R8_CODE:                      # byte store: base+0, SubOpc 0x40+r
        out.append(f"lda_dpi {GPR_BY_CODE[R8_CODE[reg]]}, 0x{b:02x}")
        out.append(f"stb_dpi {reg.lower()}, 0x{b:02x}")        # after a backend fix
    if reg in R16_CODE:                     # word store: base+1, SubOpc 0x50+r
        out.append(f"stw_dpi {reg.lower()}, 0x{b + 1:02x}")
    if reg.startswith("X"):                 # long store: base+3, SubOpc 0x60+r
        out.append(f"stl_dpi {reg.lower()}, 0x{b + 3:02x}")
    return out


# ------------------------------------------------------------------ assembly
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')


def encode_flat(text):
    """Bytes of one instruction with no fixup, or None."""
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=text, capture_output=True, text=True, timeout=30)
    m = ENC.search(r.stdout)
    if not m or "A" in m.group(1).replace("0x", ""):
        return None
    return bytes(int(b, 16) for b in m.group(1).split(",") if b.strip())


def encode_branch(spelling_fmt, addr, target, length):
    """Assemble a PC-relative branch with its label planted at the real distance.

    `spelling_fmt` must contain `{L}` where the target label goes.  Returns the
    instruction's bytes with the displacement RESOLVED by the assembler.
    """
    if target < addr:
        src = (".text\nLt:\n\t.space %d\n\t%s\n"
               % (addr - target, spelling_fmt.format(L="Lt")))
        off = addr - target
    else:
        src = (".text\n\t%s\n\t.space %d\nLt:\n"
               % (spelling_fmt.format(L="Lt"), target - addr - length))
        off = 0
    s = os.path.join(WORK, "b.s"); o = os.path.join(WORK, "b.o")
    bn = os.path.join(WORK, "b.bin")
    open(s, "w").write(src)
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                       capture_output=True, text=True)
    if r.returncode:
        return None, r.stderr.strip()
    r = subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", o, bn],
                       capture_output=True, text=True)
    if r.returncode:
        return None, r.stderr.strip()
    return open(bn, "rb").read()[off:off + length], ""


def main():
    fails = 0
    print("=== `djnz r,imm` -- 7 sites ===")
    print(f"{'site':>9}  {'ROM':10}  {'unidasm':22}  {'llvm-mc spelling':30}  "
          f"{'emitted':10}  ok")
    for addr, text, tgt in DJNZ:
        rom = ROM[addr - BASE: addr - BASE + 3]
        mn, reg = djnz_spelling(text)
        fmt = f"{mn} {reg}, {{L}}"
        got, err = encode_branch(fmt, addr, tgt, 3)
        ok = got == rom
        fails += not ok
        print(f"0x{addr:06X}  {rom.hex(' '):10}  {text:22}  "
              f"{fmt.format(L=f'.Lc_{tgt:06x}'):30}  "
              f"{(got.hex(' ') if got else err):10}  {'OK' if ok else 'MISMATCH'}")

    print("\n=== `djnz r,imm` NEGATIVE CONTROL: numeric target ===")
    ncbad = 0
    for addr, text, tgt in DJNZ:
        rom = ROM[addr - BASE: addr - BASE + 3]
        mn, reg = djnz_spelling(text)
        got = encode_flat(f"{mn} {reg}, 0x{tgt:06x}")
        same = got == rom
        ncbad += same
        print(f"0x{addr:06X}  {rom.hex(' '):10}  {mn} {reg}, 0x{tgt:06x}"
              f"  -> {(got.hex(' ') if got else 'no form'):10}  "
              f"{'!! MATCHED (control broken)' if same else 'differs (expected)'}")

    print("\n=== `ld (r+),r` -- 16 sites ===")
    print(f"{'site':>9}  {'ROM':10}  {'unidasm':16}  {'llvm-mc spelling':24}  "
          f"{'emitted':10}  ok")
    for addr, text in DPI:
        rom = ROM[addr - BASE: addr - BASE + 3]
        chosen, got = None, None
        for cand in dpi_spellings(text):
            e = encode_flat(cand)
            if e == rom:
                chosen, got = cand, e
                break
        ok = chosen is not None
        fails += not ok
        print(f"0x{addr:06X}  {rom.hex(' '):10}  {text:16}  {(chosen or '-'):24}  "
              f"{(got.hex(' ') if got else '-'):10}  {'OK' if ok else 'NO SPELLING'}")

    print("\n=== `ld (r+),r` NEGATIVE CONTROL: stb_dpi on the 8-bit sites ===")
    for addr, text in DPI:
        reg = text.split(",")[1]
        if reg not in R8_CODE:
            continue
        rom = ROM[addr - BASE: addr - BASE + 3]
        base = re.match(r'^ld\s+\((X[A-Z]{2})\+\),', text).group(1)
        cand = f"stb_dpi {reg.lower()}, 0x{XBASE[base]:02x}"
        got = encode_flat(cand)
        same = got == rom
        ncbad += same
        print(f"0x{addr:06X}  {rom.hex(' '):10}  {cand:24} -> "
              f"{(got.hex(' ') if got else 'no form'):10}  "
              f"{'!! MATCHED (control broken)' if same else 'differs (expected)'}")

    print(f"\n{fails} site(s) with no byte-exact spelling; "
          f"{ncbad} negative control(s) wrongly matched")
    return 1 if (fails or ncbad) else 0


if __name__ == "__main__":
    sys.exit(main())
