#!/usr/bin/env python3
"""PROBE: `or (<XRR>+d8),<imm>` is NOT a backend gap -- it is spelled ormi8/ormi16.

Question it answers
-------------------
convert_reachable_ranges.py --forms reports `or (r+imm),imm` as unspellable, and
`or (xsp+0x02), 0x03` really does fail with "invalid operand for instruction".
Is OR (mem),# missing from the TLCS-900 backend?

No.  OR8mi / OR16mi exist (TLCS900InstrInfo.td, sub-opcode 0x3E in the
memory-immediate ALU table 0x38..0x3F) but were never given their real mnemonic
the way AND8mi/CP8mi were, so they answer ONLY to the invented names
`ormi8` / `ormi16`.  Same for add/adc/sub/sbc/xor; `and` and `cp` are the two
that were renamed.

Encoding under test:  [0x88 + 0x10*size + base, d8, 0x3E, imm...]
  size 0 -> byte prefix 0x88+base, one immediate byte   -> ormi8
  size 1 -> word prefix 0x98+base, two immediate bytes  -> ormi16

Every base x every displacement x a set of immediates is assembled in ONE
llvm-mc call and compared with those bytes.  NEGATIVE CONTROLS: the plain `or`
spelling must be REJECTED, and the wrong-width mnemonic must not reproduce the
bytes.

Run:  python3 verify_or_mem_imm.py     -> exit 0 on success
"""
import os, re, subprocess, sys

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'encoding: \[([^\]]+)\]')
ERR = re.compile(r'^<stdin>:(\d+):\d+: error:', re.M)
BASES = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
DISPS = [0x00, 0x01, 0x02, 0x06, 0x0e, 0x7f, 0x80, 0xfb, 0xff]

def spell(dv):
    """MEMri displacement text: sentinel 0x100 for zero, SIGNED above 0x7f."""
    if dv == 0:
        return "+0x100"
    if dv >= 0x80:
        return f" - 0x{0x100 - dv:02x}"
    return f"+0x{dv:02x}"

IMM8 = [0x00, 0x03, 0x10, 0x20, 0x40, 0x80, 0xff]
IMM16 = [0x0000, 0x00f0, 0x8000, 0xffff]

cases = []                                   # (text, expected|None, kind)
for b, bn in enumerate(BASES):
    for dv in DISPS:
        for iv in IMM8:
            w = bytes([0x88 + b, dv, 0x3E, iv])
            cases.append((f"ormi8 ({bn}{spell(dv)}), 0x{iv:02x}", w, "OR-8"))
            cases.append((f"or ({bn}{spell(dv)}), 0x{iv:02x}", None, "control-plain"))
            cases.append((f"ormi16 ({bn}{spell(dv)}), 0x{iv:02x}", None, "control-width"))
        for iv in IMM16:
            w = bytes([0x98 + b, dv, 0x3E, iv & 0xff, iv >> 8])
            cases.append((f"ormi16 ({bn}{spell(dv)}), 0x{iv:04x}", w, "OR-16"))
            cases.append((f"ormi8 ({bn}{spell(dv)}), 0x{iv:04x}", None, "control-width"))

src = "\n".join(c[0] for c in cases) + "\n"
r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                   input=src, capture_output=True, text=True)
failed = {int(m) for m in ERR.findall(r.stderr)}
encs = [bytes(int(x, 16) for x in m.split(",") if x.strip()) for m in ENC.findall(r.stdout)]
it, got = iter(encs), {}
for i in range(1, len(cases) + 1):
    got[i] = None if i in failed else next(it)

ok = bad = rej = leak = 0
last = None
for i, (text, want, kind) in enumerate(cases, 1):
    g = got[i]
    if want is None:
        if g is not None and g == last:
            leak += 1
            print(f"CONTROL LEAK  {text:36} reproduced {last.hex(' ')}")
        continue
    last = want
    if g is None:
        rej += 1; print(f"REJECTED {kind} {text}")
    elif g == want:
        ok += 1
    else:
        bad += 1
        print(f"MISMATCH {kind} {text:36} want={want.hex(' ')} got={g.hex(' ')}")
print(f"positive cases: {ok} byte-exact / {bad} wrong / {rej} rejected")
print(f"negative controls: {leak} leaked (must be 0)")
sys.exit(1 if (bad or rej or leak) else 0)
