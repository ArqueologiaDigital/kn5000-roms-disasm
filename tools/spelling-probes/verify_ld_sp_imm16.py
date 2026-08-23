#!/usr/bin/env python3
"""RIGOROUS NEGATIVE for `ld SP,#imm16` (0x37 lo hi): the backend cannot spell it.

QUESTION THIS ANSWERS
  convert_reachable_ranges.py --forms lists `ld r,imm` as a blocker, whose
  example is `ld SP,0x0000`.  Is that a spelling nobody tried, or a real gap?

WHAT THE ENCODING IS
  0x30+r, imm16 is the 3-byte short form of LD r16,#nn.  r=7 is SP, so the ROM's
  `37 00 00` is `LD SP,#0x0000`.  Every other register in that family already
  spells: `ldw iz, 0x0000` -> [0x36,0x00,0x00].

WHY IT CANNOT BE SPELLED -- and it is NOT a naming trap
  TLCS900InstrInfo.td:1778
      def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16:$rd),
                                              (ins i16imm:$imm), "ldw", ...>
  GR16 is (WA BC DE HL IX IY IZ) -- SEVEN registers.  SP lives only in GR16SP
  (TLCS900RegisterInfo.td:99), the class PUSH16_short/POP16_short already use
  for exactly this 0x28+r / 0x48+r shape.  So r=7 has no operand to name.

  ⚠ THE DISASSEMBLER ALREADY DECODES IT.  TLCS900Disassembler.cpp:2198 builds
  LD16ri_short with decodeGR16(7) = TLCS900::SP, and `llvm-mc -disassemble`
  prints `ldw sp, 0`.  Feeding that text straight back to llvm-mc fails with
  "invalid operand for instruction".  The two directions disagree; this probe's
  round-trip check is what proves it rather than asserting it.

  ⚠ THE PARSER DOES KNOW THE NAME `sp`: `pushw sp` assembles to [0x2f].  So the
  failure is the operand CLASS on this one def, not an unknown register.

THE SHAPE OF THE FIX (proposed, not applied)
      -  def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16:$rd),
      +  def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16SP:$rd),
  Sibling to mirror: POP16_short (TLCS900InstrInfo.td:796), which is
  `(outs GR16SP:$rd)` on the same single-byte-plus-register shape.  Safe for
  codegen: LD16ri_short has an empty pattern and is referenced only by the
  disassembler and TLCS900SchedInstRW.td, so no ISel rule can allocate SP here.

⚠ DO NOT "FIX" THIS WITH extpfx.  `extpfx3 0x37, 0x00, 0x00` assembles to
exactly [0x37,0x00,0x00] -- the extpfx<N> family is an unconditional raw-byte
emitter, so it would make EVERY form trivially spellable and turn converted
code back into `.byte` wearing a mnemonic.  It is used nowhere in v7/v9/v10.

MEASURED 2026-08-23
  v7 1092 printed `ld SP,imm16` sites -> 0 spellable
  v9 1073 -> 0        v10 1073 -> 0
  Brute force over all 664 mnemonics in TLCS900InstrInfo.td x {sp,xsp} x
  {imm, imm16} shapes: 0 accepted spellings whose first byte is 0x37.

RUN
  python3 tools/spelling-probes/verify_ld_sp_imm16.py \
      original_ROMs/kn5000_v7_program.rom [more ROMs...]
"""
import os, re, subprocess, sys, tempfile

LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
TD = os.path.expanduser(
    "~/compartilhado/llvm-project/llvm/lib/Target/TLCS900/TLCS900InstrInfo.td")
BASE = 0xE00000
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$')
SP = re.compile(r'^ld\s+SP,(0x[0-9a-fA-F]{1,4})$')
_C = {}


def enc(t):
    if t not in _C:
        r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                           input=t, capture_output=True, text=True)
        m = ENC.search(r.stdout)
        _C[t] = bytes(int(b, 16) for b in m.group(1).split(",") if b.strip()) if m else None
    return _C[t]


def candidates(v):
    """Every spelling a reader might reach for, including the naming traps."""
    return [f"ldw sp, {v}", f"ldw SP, {v}", f"ld sp, {v}", f"ld SP, {v}",
            f"lds sp, {v}", f"lds16 sp, {v}", f"ldw xsp, {v}", f"ld xsp, {v}",
            f"lds32 xsp, {v}", f"ldw_erp sp, {v}", f"ldi_erpb 0xfc, {v}",
            f"ldw (sp), {v}"]


def roundtrip(raw):
    """What `llvm-mc -disassemble` prints for these bytes (the asymmetry)."""
    src = " ".join(f"0x{b:02x}" for b in raw)
    r = subprocess.run([MC, "-triple=tlcs900", "-disassemble"],
                       input=src, capture_output=True, text=True)
    for ln in r.stdout.splitlines():
        if ln.strip() and not ln.startswith("."):
            return re.sub(r'\s+', ' ', ln.strip())
    return "<disassembler declined>"


def brute_force_all_mnemonics():
    """No mnemonic in the whole backend spells an SP 16-bit immediate load."""
    mns = sorted(set(re.findall(r'"([a-z][a-z0-9_]*)",\s*"\$', open(TD).read())))
    hits = []
    for m in mns:
        for f in (f"{m} sp, 0x0000", f"{m} sp, 0", f"{m} xsp, 0x0000"):
            e = enc(f)
            if e is not None and e[:1] == b"\x37":
                hits.append((f, e.hex()))
    return len(mns), hits


def main(argv):
    print("== is `ld SP,#imm16` spellable at all?")
    for t in candidates("0x0000") + ["extpfx3 0x37, 0x00, 0x00"]:
        e = enc(t)
        print(f"   {t:26} -> {e.hex() if e else 'REJECTED'}")
    print(f"   disassembler round-trip of 37 00 00 -> {roundtrip(b'\x37\x00\x00')}")
    n, hits = brute_force_all_mnemonics()
    print(f"\n== brute force: {n} mnemonics x 3 operand shapes, "
          f"{len(hits)} emit a leading 0x37")
    for f, e in hits:
        print(f"   {f} -> {e}")
    if not argv:
        return 1 if hits else 0
    print()
    with tempfile.TemporaryDirectory(prefix="ldsp_probe_") as tmp:
        for rom_path in argv:
            lst = os.path.join(tmp, os.path.basename(rom_path) + ".lst")
            with open(lst, "w") as fh:
                subprocess.run([UNIDASM, rom_path, "-arch", "tlcs900",
                                "-basepc", hex(BASE)], stdout=fh,
                               stderr=subprocess.DEVNULL, check=True)
            n_sites = n_ok = 0
            for line in open(lst):
                m = LINE.match(line)
                if not m:
                    continue
                s = SP.match(m.group(3).strip())
                if not s:
                    continue
                raw = bytes(int(b, 16) for b in m.group(2).split())
                n_sites += 1
                if any(enc(c) == raw for c in candidates(s.group(1))):
                    n_ok += 1
            print(f"{os.path.basename(rom_path)}: {n_sites} `ld SP,imm16` site(s) "
                  f"-> {n_ok} spellable  (0 = the gap is real)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
