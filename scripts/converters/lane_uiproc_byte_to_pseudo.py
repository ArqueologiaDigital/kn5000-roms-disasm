#!/usr/bin/env python3
r"""Replace the last `.byte` instruction lines of lane uiproc's files by the backend's raw-operand forms.

QUESTION / JOB
--------------
After re-framing, the only `.byte` lines left in the lane's files are two
instruction families this backend cannot spell in plain syntax (each line
carries MAME unidasm's reading as its comment):

  e3 07 R1 R2 F0+r   cp  X<r>, (X<R1>+<R2>)   register-indexed 32-bit compare
  f3 fd LO HI 30+r   lda X<r>, XSP+0xHHLL     16-bit displacement off XSP

The second is not merely unspellable but MIS-spelt: `lda xwa, (xsp+256)`
assembles to the 3-byte `bf 00 30` (xsp+0) -- the displacement is silently
truncated -- while the backend's own disassembler prints f3 fd 00 01 30 that
way.  Both families do have a raw-operand form the assembler encodes exactly:
`cpl_sri_rm xwa, 0x07, 0xf0, 0xf4` and `lda_dri xwa, 0xfd, 0x00, 0x01`
(the same forms used elsewhere in this tree, e.g. `cpl_sri_rm XWA, 0xfd,
0x10, 0x01`).  Those are instructions to the census and to a reader of the
mnemonic; the unidasm reading stays as the comment.  Every replacement is
checked with llvm-mc to encode to the same bytes before it is written.

RUN
    python3 scripts/converters/lane_uiproc_byte_to_pseudo.py v10/maincpu/ui/ui_mode_handlers.s [...]
"""
import re
import subprocess
import sys
import os

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
LINE = re.compile(r'^(\s*)\.byte\s+((?:0x[0-9a-f]{2}\s*,\s*)*0x[0-9a-f]{2})(\s*;.*)?$')


def enc(t):
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=t + "\n",
                       capture_output=True, text=True)
    m = re.search(r'encoding:\s*\[(.*?)\]', r.stdout)
    return [int(x, 16) for x in re.findall(r'0x([0-9a-f]{2})', m.group(1))] if m else None


def convert(bs):
    if len(bs) == 5 and bs[0] == 0xe3 and bs[1] == 0x07 and 0xf0 <= bs[4] <= 0xf7:
        return "cpl_sri_rm\t%s, 0x07, 0x%02x, 0x%02x" % (R32[bs[4] - 0xf0], bs[2], bs[3])
    if len(bs) == 5 and bs[0] == 0xf3 and bs[1] == 0xfd and 0x30 <= bs[4] <= 0x37:
        return "lda_dri\t%s, 0xfd, 0x%02x, 0x%02x" % (R32[bs[4] - 0x30], bs[2], bs[3])
    return None


def main():
    for path in sys.argv[1:]:
        raw = open(path, "rb").read()
        lines = raw.decode("latin-1").split("\n")
        n = 0
        for i, l in enumerate(lines):
            m = LINE.match(l)
            if not m:
                continue
            bs = [int(x, 16) for x in re.findall(r'0x([0-9a-f]{2})', m.group(2))]
            c = convert(bs)
            if c and enc(c.replace("\t", " ")) == bs:
                lines[i] = m.group(1) + c + (m.group(3) or "")
                n += 1
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
        print("%s: %d .byte lines -> raw-operand instructions" % (path, n))


if __name__ == "__main__":
    main()
