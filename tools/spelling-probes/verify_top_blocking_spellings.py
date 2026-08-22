#!/usr/bin/env python3
"""Do the proposed spellings for the TOP blocking forms reproduce the ROM bytes
at EVERY site, in every KN5000 ROM -- not just at the sites that happen to block
the converter today?

WHY
  scripts/analysis/v7_blocking_forms_census.py ranks what still blocks
  `convert_reachable_ranges.py` by bytes.  A ranking is only actionable if the
  proposed fix actually assembles, so this probe takes each proposed rule and
  runs it over every site of that form in the four ROMs, byte-comparing against
  the ROM.  "It assembled" is NOT a pass; only equal bytes are.

  Four claims of "no spelling exists" were made in this tree and all four were
  false -- the mnemonic existed under another name.  A fifth was made while
  writing THIS probe and was also false: see the d8 = 0 note below.  So every
  rule here was found by grepping TLCS900InstrInfo.td (and the code emitter) for
  the family and assembling it, and this script is the standing check.

THE RULES
  A  `<op> (<mem>),<imm8>`      -> `<op>mi8 <mem>, <imm>`     op in
     add adc sub sbc and or xor.
  B  `ld (<X..>+<r16>),<src>`   -> `st_rrb <src>, <base>, <idx>` for a BYTE
     source; `stw_dri`/`stl_dri <src>, 0x07, <base_byte>, <idx_byte>` for word
     and long.  ⚠ `st_rrw` and `st_rrl` LOOK right and are not: all three
     `st_rr*` defs carry SubOpc 0x40, and the 0xF3 prefix skips the OpSize
     adjustment, so the word and long spellings silently emit the BYTE
     sub-opcode.  The `--negative` run measures that.
  C  `lda <X..>,<X..>+<r16>`    -> `lda_rr <rd>, <base>, <idx>`
  D  `cp (<abs>),<reg>`         -> keyed on the PREFIX BYTE, which carries both
     the operand width and the address width:
        c1 -> `cpdm8 <a16>, <r8>`      c2 -> `cpdm8_24 <a24>, <r8>`
        d1 -> `cpdm16 <a16>, <XR>`     d2 -> `cpdm16_24 <a24>, <XR>`
        e1 -> `cpdm32 <a16>, <XR>`     e2 -> `cpdm32_24 <a24>, <XR>`
     ⚠ note the 32-bit NAME for a 16-bit register: the backend types that
     operand GPR and the register-number field is identical, so
     `cpdm16 0xf1ea, xwa` is the byte-exact way to write `cp (0xf1ea),WA`.
     The 8-bit-address prefixes (c0/d0/e0) have NO mnemonic and are declined.
  E  `pushw (<mem>)`            -> `pushm <mem>`
  F  `ld (<X..>+<d8>),<src>`    -> `ld (<base> <signed d8>), <src>`
  G  `inc|dec <n>,(<abs>)`      -> `incdi8`/`decdi8` (prefix c1/c2, byte size),
     `incdi16`/`decdi16` (prefix d1/d2, word size), each with a `_24` variant
     for a 24-bit address.  ⚠ `decdd8 1, 0x0de7` looks like the same thing and
     emits `f1 e7 0d 69`, which unidasm reads back as `db` -- an INVALID
     encoding, not a synonym.

⚠ TWO DISPLACEMENT TRAPS, both silent, both measured by `--negative`:
  * unidasm prints the d8 as a RAW BYTE and llvm-mc wants it SIGNED, so
    `(XSP+0xfc)` must be written `(xsp - 0x04)`.  Unsigned assembles CLEANLY to
    a longer, different instruction.
  * d8 = 0x00 needs the SENTINEL `(xsp + 256)`.  Writing `(xsp + 0x00)`
    assembles to the SHORTER `(xsp)` encoding -- a real instruction one byte
    short of the ROM's.  The sentinel is deliberate and documented in
    TLCS900MCCodeEmitter.cpp: "displacement of 256 means force d8 form with
    displacement 0 ... used by the assembly converter to reproduce exact ROM
    encoding".  This firmware is full of explicit d8 = 0 encodings, so the
    sentinel is not a curiosity -- it is most of rule F.

RUN
  python3 tools/spelling-probes/verify_top_blocking_spellings.py
  python3 tools/spelling-probes/verify_top_blocking_spellings.py --negative
      Runs the spelling each rule REPLACES -- the one the converter offers
      today, or the obvious wrong guess -- to prove the check can fail.
  python3 tools/spelling-probes/verify_top_blocking_spellings.py --rom v7

SIGNAL READ
  the raw bytes of original_ROMs/kn5000_{v7,v9,v10}_program.rom at load base
  0xE00000 and kn5000_table_data.rom at 0x200000, against
  `llvm-mc -triple=tlcs900 --show-encoding`.  PASS = identical bytes.
  Sites come from a LINEAR unidasm scan, so some of them are data decoded as
  instructions; that does not matter here -- the question is whether the
  spelling reproduces the bytes, and a data site answers it just as well.
"""
import os, re, subprocess, sys

REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.+)$')

ROMS = [("v7", "original_ROMs/kn5000_v7_program.rom", 0xE00000),
        ("v9", "original_ROMs/kn5000_v9_program.rom", 0xE00000),
        ("v10", "original_ROMs/kn5000_v10_program.rom", 0xE00000),
        ("table", "original_ROMs/kn5000_table_data.rom", 0x200000)]

GR8 = "W A B C D E H L".split()
GR16 = "WA BC DE HL IX IY IZ SP".split()
GPR = "XWA XBC XDE XHL XIX XIY XIZ XSP".split()
R16_TO_R32 = dict(zip(GR16, GPR))
# ⚠ the backend's GR16 class EXCLUDES SP -- the same gap README-inc_reg.md
# records for `inc n, sp`. A 16-bit SP source therefore has no register NAME to
# write, and both rules that emit one decline it. Costs nothing in the three
# program ROMs (0 sites); 18 sites in the table-data ROM, all linear-scan noise.
GR16_NAMED = [r for r in GR16 if r != "SP"]


def mem_llvm(m, naive=False):
    """unidasm memory operand -> the llvm-mc spelling of the SAME encoding.

    `(XHL)`        -> `(xhl)`
    `(XSP+0xfc)`   -> `(xsp - 0x04)`      d8 is SIGNED in llvm-mc
    `(XIY+0x00)`   -> `(xiy + 256)`       the force-d8 SENTINEL
    `naive=True` returns what a reader of the unidasm text would write, which is
    what `--negative` measures.
    """
    mm = re.match(r'^\((X[A-Z]{2})\)$', m)
    if mm:
        return f"({mm.group(1).lower()})"
    mm = re.match(r'^\((X[A-Z]{2})\+0x([0-9a-f]{2})\)$', m)
    if mm:
        d, r = int(mm.group(2), 16), mm.group(1).lower()
        if naive:
            return f"({r} + 0x{d:02x})"
        if d == 0:
            return f"({r} + 256)"
        return f"({r} " + (f"- 0x{0x100 - d:02x}" if d >= 0x80
                           else f"+ 0x{d:02x}") + ")"
    mm = re.match(r'^\((X[A-Z]{2})\+0x([0-9a-f]{4})\)$', m)
    if mm:
        d, r = int(mm.group(2), 16), mm.group(1).lower()
        if naive:
            return f"({r} + 0x{d:04x})"
        return f"({r} " + (f"- 0x{0x10000 - d:04x}" if d >= 0x8000
                           else f"+ 0x{d:04x}") + ")"
    return None


# ---------------------------------------------------------------- the rules
A_OPS = ("add", "adc", "sub", "sbc", "and", "or", "xor")
A_RE = re.compile(r'^(%s) (\(X[A-Z]{2}(?:\+0x[0-9a-f]{2})?\)),(0x[0-9a-f]{2})$'
                  % "|".join(A_OPS))
B_RE = re.compile(r'^ld \((X[A-Z]{2})\+([A-Z]{2})\),([A-Z]{1,3})$')
C_RE = re.compile(r'^lda (X[A-Z]{2}),(X[A-Z]{2})\+([A-Z]{2})$')
D_RE = re.compile(r'^cp \((0x[0-9a-f]+)\),([A-Z]{1,3})$')
E_RE = re.compile(r'^pushw (\(X[A-Z]{2}(?:\+0x[0-9a-f]{2})?\))$')
F_RE = re.compile(r'^ld (\(X[A-Z]{2}\+0x[0-9a-f]{2}\)),([A-Z]{1,3})$')
G_RE = re.compile(r'^(inc|incw|dec|decw) (\d+),\((0x[0-9a-f]+)\)$')


def rule_a(text, raw, neg):
    m = A_RE.match(text)
    if not m:
        return None
    # BYTE-DRIVEN, not text-driven. `xor (XWA),0x43` is printed by BOTH the
    # short 0x80-group encoding and the extended-register-byte form
    # `c3 e0 3d 43`; spelling the second one with the first one's mnemonic
    # assembles happily and emits 3 bytes where the ROM has 4. Caught in
    # kn5000_table_data.rom, 1 site, by this probe.
    if not 0x80 <= raw[0] <= 0x8F:
        return None
    mem = mem_llvm(m.group(2), naive=neg)
    return None if mem is None else f"{m.group(1)}mi8 {mem}, {m.group(3)}"


def rule_b(text, raw, neg):
    m = B_RE.match(text)
    if not m or raw[0] != 0xF3:
        return None
    base, idx, src = m.group(1), m.group(2), m.group(3)
    if idx not in GR16:
        return None
    bb = f"0x{0xE0 + GPR.index(base) * 4:02x}, 0x{0xE0 + GR16.index(idx) * 4:02x}"
    if neg:
        # what the converter offers today (stb_dri, SubOpc 0x30 = LDA), and for
        # the word/long cases the plausible-looking st_rrw / st_rrl.
        if src in GR8:
            return f"stb_dri {src.lower()}, 0x07, {bb}"
        return (f"st_rrw {src.lower()}, {base.lower()}, {idx.lower()}" if src in GR16
                else f"st_rrl {src.lower()}, {base.lower()}, {idx.lower()}"
                if src in GPR else None)
    if src in GR8:
        return f"st_rrb {src.lower()}, {base.lower()}, {idx.lower()}"
    if src in GR16_NAMED:
        return f"stw_dri {src.lower()}, 0x07, {bb}"
    if src in GPR:
        return f"stl_dri {src.lower()}, 0x07, {bb}"
    return None


def rule_c(text, raw, neg):
    m = C_RE.match(text)
    if not m or raw[0] != 0xF3:
        return None
    rd, base, idx = m.group(1), m.group(2), m.group(3)
    if idx not in GR16:
        return None
    if neg:                       # what the converter offers today
        return f"lda {rd.lower()}, ({base.lower()}+{idx.lower()})"
    return f"lda_rr {rd.lower()}, {base.lower()}, {idx.lower()}"


D_PREFIX = {0xC1: ("cpdm8", 8), 0xC2: ("cpdm8_24", 8),
            0xD1: ("cpdm16", 16), 0xD2: ("cpdm16_24", 16),
            0xE1: ("cpdm32", 32), 0xE2: ("cpdm32_24", 32)}


def rule_d(text, raw, neg):
    m = D_RE.match(text)
    if not m:
        return None
    addr, reg = m.group(1), m.group(2)
    fam = D_PREFIX.get(raw[0])
    if fam is None:                    # 8-bit address (c0/d0/e0): no mnemonic
        return None
    mn, width = fam
    if width == 8:
        return f"{mn} {addr}, {reg.lower()}" if reg in GR8 else None
    if neg:                            # the printed 16-bit NAME -- rejected
        return f"{mn} {addr}, {reg.lower()}"
    name = R16_TO_R32.get(reg, reg)
    return f"{mn} {addr}, {name.lower()}" if name in GPR else None


def rule_e(text, raw, neg):
    m = E_RE.match(text)
    if not m or not 0x90 <= raw[0] <= 0x9F:
        return None
    mem = mem_llvm(m.group(1), naive=neg)
    if mem is None:
        return None
    if neg:                       # what the converter's canonical() produces
        return f"pushw {mem}"
    return f"pushm {mem}"


def rule_f(text, raw, neg):
    m = F_RE.match(text)
    if not m or not 0xB8 <= raw[0] <= 0xBF:
        return None
    mem, src = mem_llvm(m.group(1), naive=neg), m.group(2)
    if mem is None or not (src in GR8 or src in GR16_NAMED or src in GPR):
        return None
    return f"ld {mem}, {src.lower()}"


G_PREFIX = {0xC1: ("di8", 8), 0xC2: ("di8_24", 8),
            0xD1: ("di16", 16), 0xD2: ("di16_24", 16)}


def rule_g(text, raw, neg):
    m = G_RE.match(text)
    if not m:
        return None
    op, n, addr = m.group(1)[:3], m.group(2), m.group(3)
    fam = G_PREFIX.get(raw[0])
    if fam is None:
        return None
    sfx, width = fam
    if neg:                       # the other width -- assembles, wrong prefix
        sfx = sfx.replace("8", "16") if width == 8 else sfx.replace("16", "8")
    return f"{op}{sfx} {n}, {addr}"


RULES = [("A  <op> (mem),imm8   -> <op>mi8", A_RE, rule_a),
         ("B  ld (r32+r16),r    -> st_rrb / stw_dri / stl_dri", B_RE, rule_b),
         ("C  lda r32,r32+r16   -> lda_rr", C_RE, rule_c),
         ("D  cp (abs),r        -> cpdm8 / cpdm16 (GPR name)", D_RE, rule_d),
         ("E  pushw (mem)       -> pushm", E_RE, rule_e),
         ("F  ld (r32+d8),r     -> ld (base + d), r", F_RE, rule_f),
         ("G  inc/dec n,(abs)   -> incdi8 / decdi16 ...", G_RE, rule_g)]


# --------------------------------------------------------------- assembling
_CACHE = {}


def encode_many(texts):
    """Assemble many one-line instructions, batched, memoised.

    One llvm-mc process per line makes a four-ROM sweep take hours. A batch of
    lines comes back in order; if ANY line in the batch fails, llvm-mc drops it
    from the output and the alignment is lost, so that batch is redone one line
    at a time. Normal batches succeed, so the slow path is rare.
    """
    todo = [t for t in dict.fromkeys(texts) if t not in _CACHE]
    for i in range(0, len(todo), 200):
        chunk = todo[i:i + 200]
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input="\n".join(chunk) + "\n",
                           capture_output=True, text=True, timeout=300)
        encs = ENC.findall(r.stdout)
        if len(encs) == len(chunk):
            for t, e in zip(chunk, encs):
                _CACHE[t] = bytes(int(b, 16) for b in e.split(",") if b.strip())
            continue
        for t in chunk:
            rr = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                                input=t, capture_output=True, text=True, timeout=60)
            m = ENC.search(rr.stdout)
            _CACHE[t] = (bytes(int(b, 16) for b in m.group(1).split(",")
                               if b.strip()) if m else None)
    return {t: _CACHE[t] for t in texts}


def sweep(path, base):
    out = subprocess.run([UNI, os.path.join(REPO, path), "-arch", "tlcs900",
                          "-basepc", hex(base)], capture_output=True, text=True).stdout
    for line in out.split("\n"):
        m = LINE.match(line)
        if m:
            yield (int(m.group(1), 16),
                   bytes(int(x, 16) for x in m.group(2).split()),
                   m.group(3).strip())


def main():
    neg = "--negative" in sys.argv
    only = (sys.argv[sys.argv.index("--rom") + 1] if "--rom" in sys.argv else None)
    print("verifying the proposed spellings for the top blocking forms")
    print(f"mode: {'NEGATIVE CONTROL -- the spellings these rules REPLACE' if neg else 'the proposed rules'}\n")
    grand = [0, 0, 0]
    for name, path, base in ROMS:
        if only and name != only:
            continue
        sites = list(sweep(path, base))
        print(f"--- {name}  ({len(sites):,} decoded instructions in a linear scan)")
        for label, rx, fn in RULES:
            cand, keep = [], []
            for a, raw, text in sites:
                c = fn(text, raw, neg)
                if c is None:
                    if rx.match(text):
                        keep.append((a, raw, text, None))
                    continue
                cand.append(c)
                keep.append((a, raw, text, c))
            enc = encode_many(cand)
            ok = wrong = noform = 0
            first_wrong = None
            for a, raw, text, c in keep:
                if c is None:
                    noform += 1
                    continue
                e = enc.get(c)
                if e == raw:
                    ok += 1
                else:
                    wrong += 1
                    if first_wrong is None:
                        first_wrong = (a, raw, text, c, e)
            grand[0] += ok; grand[1] += wrong; grand[2] += noform
            flag = "   ⚠ WRONG BYTES" if wrong else ""
            print(f"  {label:50} {ok:6} exact  {wrong:6} wrong  {noform:5} no rule{flag}")
            if first_wrong:
                a, raw, text, c, e = first_wrong
                print(f"       e.g. 0x{a:06X}  ROM {raw.hex(' ')}  `{text}`\n"
                      f"            spelled `{c}` -> "
                      f"{e.hex(' ') if e else 'REJECTED by llvm-mc'}")
    print(f"\nTOTAL {grand[0]:,} byte-exact · {grand[1]:,} wrong · {grand[2]:,} no rule")
    if neg:
        print("A negative control that reports 0 wrong would mean this check "
              "cannot fail;\nit reports wrongs, so it can.")
    else:
        print("0 wrong is the pass condition. `no rule` counts sites the rule "
              "deliberately\ndeclines (an operand shape outside it), not "
              "failures -- they stay .byte.")
    return 1 if (not neg and grand[1]) else 0


if __name__ == "__main__":
    sys.exit(main())
