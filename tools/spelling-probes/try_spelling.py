#!/usr/bin/env python3
"""Does this llvm-mc text assemble to exactly these ROM bytes?

The one question every spelling claim in this tree turns on, asked directly.
Five "no spelling exists" claims have been made here and all five were false --
the mnemonic existed under another name -- so the workflow is: grep
~/compartilhado/llvm-project/llvm/lib/Target/TLCS900/TLCS900InstrInfo.td for the
family, then run this on each candidate. "It assembled" is NOT a pass; the
script only says MATCH when the bytes are identical.

RUN
    python3 tools/spelling-probes/try_spelling.py <hexbytes> "<spelling>" ...

    $ python3 tools/spelling-probes/try_spelling.py 833d60 \\
          "xor (xhl), 0x60" "xormi8 (xhl), 0x60"
    want 833d60   (unidasm: xor (XHL),0x60)
      xor (xhl), 0x60       -> ERR: invalid operand for instruction
      xormi8 (xhl), 0x60    -> 833d60   <== MATCH

With no spelling arguments it just decodes the bytes with unidasm, which is how
you find out what you are trying to spell.

This is the spot-check tool.  A rule that survives it should then be swept over
every site in the ROMs by verify_top_blocking_spellings.py -- one site proves a
spelling exists, not that a RULE is right.
"""
import os, re, subprocess, sys, tempfile

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
ENC = re.compile(r'[;#] encoding: \[([^\]]+)\]')


def assemble(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"], input=text,
                       capture_output=True, text=True, timeout=60)
    m = ENC.search(r.stdout)
    if not m:
        err = (r.stderr.strip().split("\n") or [""])[0]
        return None, re.sub(r'^<stdin>:\d+:\d+:\s*', '', err)[:100]
    return "".join(f"{int(b, 16):02x}" for b in m.group(1).split(",") if b.strip()), ""


def decode(hexbytes):
    d = tempfile.mkdtemp(prefix="try_spelling_")
    p = os.path.join(d, "b.bin")
    open(p, "wb").write(bytes.fromhex(hexbytes))
    out = subprocess.run([UNI, p, "-arch", "tlcs900", "-basepc", "0x0"],
                         capture_output=True, text=True).stdout
    for line in out.split("\n"):
        if ":" in line:
            return line.split(":", 1)[1].strip()
    return "?"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    want = sys.argv[1].lower().replace(" ", "")
    print(f"want {want}   (unidasm: {decode(want)})")
    bad = 0
    for cand in sys.argv[2:]:
        got, err = assemble(cand)
        if got == want:
            print(f"  {cand:44} -> {got}   <== MATCH")
        else:
            bad += 1
            print(f"  {cand:44} -> {got if got else 'ERR: ' + err}")
    return 0 if sys.argv[2:] and bad < len(sys.argv[2:]) else 0


if __name__ == "__main__":
    sys.exit(main())
