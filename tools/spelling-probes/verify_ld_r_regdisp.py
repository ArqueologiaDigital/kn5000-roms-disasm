#!/usr/bin/env python3
"""PROBE: exhaustive check of the two `ld <r>,(<XRR>+d8)` spelling rules.

Question it answers
-------------------
unidasm prints a register+displacement load as `ld C,(XSP+0x00)` / `ld A,(XBC+0xff)`.
Neither text assembles to the ROM's bytes when written literally.  Is the form a
backend gap?  No -- it is two spelling rules:

  LD-1 ZERO-DISPLACEMENT SENTINEL.  d8 == 0 must be written as displacement
       0x100 (TLCS900MCCodeEmitter.cpp).  A literal `+0x00` folds to the 2-byte
       no-displacement form 0x80+r, a DIFFERENT instruction.
  LD-2 SIGNED DISPLACEMENT.  unidasm prints d8 as a raw byte; llvm-mc wants it
       signed.  A literal `+0xff` selects the 5-byte 16-bit-displacement form
       (prefix 0xC3/0xD3/0xE3), again a different instruction.

Encoding under test (TLCS-900):  [0x88 + 0x10*size + base, d8, 0x20 + dst]
  size 0/1/2 = byte/word/long,  base 0..7 = XWA..XSP,  dst 0..7 in that width.

Every (size, base, dst, d8) is assembled in ONE llvm-mc call and compared with
the bytes the encoding table says must appear.  NEGATIVE CONTROL: the literal
spelling of the same site is assembled too and must NOT produce those bytes.

Run:  python3 verify_ld_r_regdisp.py     -> exit 0 on success
"""
import os, re, subprocess, sys

MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC = re.compile(r'encoding: \[([^\]]+)\]')
ERR = re.compile(r'^<stdin>:(\d+):\d+: error:', re.M)
BASES = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]
DST = [["w", "a", "b", "c", "d", "e", "h", "l"],
       ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"],
       ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]]
DISPS = [0x00, 0x80, 0xf2, 0xfb, 0xff]

cases = []                                  # (text, expected_bytes, kind)
for size in range(3):
    for b, bn in enumerate(BASES):
        for d, dn in enumerate(DST[size]):
            for dv in DISPS:
                want = bytes([0x88 + 0x10 * size + b, dv, 0x20 + d])
                if dv == 0:
                    cases.append((f"ld {dn}, ({bn}+0x100)", want, "LD-1"))
                else:
                    cases.append((f"ld {dn}, ({bn} - 0x{0x100-dv:02x})", want, "LD-2"))
                cases.append((f"ld {dn}, ({bn}+0x{dv:02x})", want, "control"))

src = "\n".join(c[0] for c in cases) + "\n"
r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                   input=src, capture_output=True, text=True)
failed = {int(m) for m in ERR.findall(r.stderr)}
encs = [bytes(int(x, 16) for x in m.split(",") if x.strip()) for m in ENC.findall(r.stdout)]
got = {}
it = iter(encs)
for i in range(1, len(cases) + 1):
    got[i] = None if i in failed else next(it)

ok = bad = leak = rej = 0
for i, (text, want, kind) in enumerate(cases, 1):
    g = got[i]
    if kind == "control":
        if g == want:
            leak += 1
            print(f"CONTROL LEAK  {text:34} reproduced {want.hex(' ')}")
        continue
    if g is None:
        rej += 1
        print(f"REJECTED {kind} {text:34} (llvm-mc: invalid operand)")
    elif g == want:
        ok += 1
    else:
        bad += 1
        print(f"MISMATCH {kind} {text:34} want={want.hex(' ')} got={g.hex(' ')}")

n = ok + bad + rej
print(f"positive cases: {ok} byte-exact / {bad} wrong / {rej} rejected  (of {n})")
print(f"negative controls: {leak} leaked (must be 0)")
sys.exit(1 if (bad or leak) else 0)
