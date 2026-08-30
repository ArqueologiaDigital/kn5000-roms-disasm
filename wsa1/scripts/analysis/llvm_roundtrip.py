#!/usr/bin/env python3
"""Turn a byte range of a WSA1 ROM into assembly that llvm-mc PROVABLY re-assembles.

QUESTION ANSWERED
  "What does this range say, in a form the gate will accept?"  Hand-transcribing a
  disassembly is where byte-identity dies: MAME's unidasm and LLVM's TLCS-900
  backend do not spell instructions the same way, and the LLVM backend does not
  even encode every instruction MAME decodes.  This script does the transcription
  mechanically and then PROVES it, so nothing reaches a .s file on trust.

HOW
  1. `unidasm -arch tlcs900` gives the instruction boundaries (byte lengths).
  2. Each instruction's bytes are fed to `llvm-mc -triple=tlcs900 -disassemble`
     to learn LLVM's own spelling.  Results are cached, so a 400-instruction
     block costs far fewer subprocesses than it looks.
  3. The whole candidate listing is assembled with llvm-mc + objcopy and the
     output is compared BYTE FOR BYTE with the input range.  On a mismatch the
     offending instruction is demoted to `.byte` (with the MAME mnemonic kept in
     the comment) and the assemble/compare is repeated until it is exact.
  4. Only then is the listing printed.  A listing this script printed is
     guaranteed to rebuild the range it came from.

  So `.byte` lines are not laziness: each one marks an instruction that this
  LLVM build cannot encode.  They are counted in the summary on stderr.

  PC-relative operands (`jr`, `calr`) are printed by LLVM as raw DISPLACEMENTS,
  not target addresses, so the listing is position-independent and no label is
  invented.  The MAME comment carries the absolute target.

RUN
  python3 scripts/analysis/llvm_roundtrip.py b 0xF31800 0x120
  python3 scripts/analysis/llvm_roundtrip.py b 0xF31800 0x120 --label-prefix ui_
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.environ.get("LLVM_BIN", "/home/fsanches/compartilhado/llvm-project/build/bin")
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
IMAGES = {"a": ("wsa1_prom_a.ic12", 0xF80000), "b": ("wsa1_prom_b.ic13", 0xF00000),
          "c": ("wsa1_prom_c.ic28", 0xF80000), "d": ("wsa1_prom_d.bin", 0x000000)}

_cache = {}


def llvm_spell(bs):
    """LLVM's spelling of exactly these bytes, or None if it will not decode them."""
    if bs in _cache:
        return _cache[bs]
    p = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-disassemble"],
                       input=" ".join("0x%02x" % b for b in bs),
                       capture_output=True, text=True)
    txt = [l.strip() for l in p.stdout.splitlines() if l.strip()]
    ok = ("warning" not in p.stderr) and len(txt) == 1
    _cache[bs] = txt[0] if ok else None
    return _cache[bs]


def unidasm(data, base):
    """[(addr, nbytes, mame_text)] for the whole buffer."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data)
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(base)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    out = []
    for line in p.stdout.splitlines():
        m = re.match(r"^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$", line)
        if m:
            out.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return out


def assemble(lines):
    # ⚠ THE `finally` IS LOAD-BEARING, not tidiness.  Until 2026-08-30 this
    # function called mkdtemp() and never removed the directory, on ANY path --
    # including the early `return None, p.stderr` above, which is the one the
    # force loop takes repeatedly.  Each leak is 4 inodes (the directory plus
    # t.s/t.o/t.bin), the callers run it thousands of times per round, and it
    # accumulates on a tmpfs that is never swept: a wave-7 lane found /tmp at
    # 261,907 leaked directories and 1,048,576 of 1,048,576 inodes used, which
    # fails every later mkdtemp AND the shell's own cwd file, with a message
    # ("No space left on device") that names a full disk when 13G was free.
    # The bytes are read into memory before the return, so removing the
    # directory here cannot affect any caller.
    d = tempfile.mkdtemp()
    try:
        s, o, b = (os.path.join(d, n) for n in ("t.s", "t.o", "t.bin"))
        open(s, "w").write("\t.text\n" + "".join(lines))
        p = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                            "-filetype=obj", "-o", o, s], capture_output=True, text=True)
        if p.returncode:
            return None, p.stderr
        subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", o, b],
                       check=True)
        return open(b, "rb").read(), ""
    finally:
        shutil.rmtree(d, ignore_errors=True)


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    img, addr, ln = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0)
    name, base = IMAGES[img]
    data = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    off = addr - base
    blk = data[off:off + ln]

    ins = unidasm(blk, addr)
    forced = set()
    while True:
        lines, meta = [], []
        for a, n, txt in ins:
            bs = bytes(blk[a - addr:a - addr + n])
            sp = None if a in forced else llvm_spell(bs)
            if sp:
                lines.append("\t%s\t; %06X  %s\n" % (sp, a, txt))
            else:
                lines.append("\t.byte %s\t; %06X  %s   [llvm-mc cannot encode this]\n"
                             % (", ".join("0x%02X" % x for x in bs), a, txt))
            meta.append((a, n))
        out, err = assemble(lines)
        if out is None:
            print(err, file=sys.stderr)
            return 3
        if out == blk:
            break
        # first differing byte -> the instruction that owns it -> demote it
        i = next(k for k in range(min(len(out), len(blk))) if out[k] != blk[k]) \
            if len(out) == len(blk) else 0
        cum, victim = 0, None
        for a, n in meta:
            if cum <= i < cum + n:
                victim = a
                break
            cum += n
        if victim is None or victim in forced:
            print("  cannot converge at byte %d" % i, file=sys.stderr)
            return 4
        forced.add(victim)

    nb = sum(1 for l in lines if l.lstrip().startswith(".byte"))
    print("  %d instructions, %d verified by llvm-mc, %d left as .byte"
          % (len(lines), len(lines) - nb, nb), file=sys.stderr)
    sys.stdout.write("".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
