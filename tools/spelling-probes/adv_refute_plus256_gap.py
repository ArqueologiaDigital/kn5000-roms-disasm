#!/usr/bin/env python3
"""Question: is `f3 e5 00 01 41` -- `ld (XBC+0x0100),A`, a register store with a
GENUINE +256 displacement -- a real TLCS-900 backend gap?

The 2026-08-23 spelling report claimed it was: "no mnemonic reaches
f3 e5 00 01 41 ... there is no st{b,w,l}_ind sibling for the register
direction".  That search was by MNEMONIC STRING.  Searched by ENCODING SHAPE
instead, the defs are already there:

    TLCS900InstrInfo.td:4738  ST_DRI3B : RIRegInst<0xF3, 0x40, 5, ...> "stb_dri"
    TLCS900InstrInfo.td:4744  ST_DRI3W : RIRegInst<0xF3, 0x50, 5, ...> "stw_dri"
    TLCS900InstrInfo.td:4747  ST_DRI3L : RIRegInst<0xF3, 0x60, 5, ...> "stl_dri"

PASS = every expected encoding is produced.  It also shows that the plain `ld`
mnemonic really cannot reach it (the force-d8 sentinel at 256 wins), which is
what made the gap look real, and that the CONVERTER still cannot spell it --
a converter gap, not a backend gap.

Run:  python3 tools/spelling-probes/adv_refute_plus256_gap.py
"""
import os, re, subprocess, sys, tempfile, importlib.util

MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
UNI = "/home/fsanches/compartilhado/tools/unidasm"
REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"


def enc(line):
    fd, p = tempfile.mkstemp(suffix=".s"); os.write(fd, (line + "\n").encode()); os.close(fd)
    r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding", p],
                       capture_output=True, text=True)
    os.unlink(p)
    m = re.search(r'encoding:\s*\[([^\]]*)\]', r.stdout)
    if not m:
        return None
    return bytes(int(x, 16) for x in m.group(1).replace(" ", "").split(",") if x)


CASES = [
    ("stb_dri a, 0xe5, 0x00, 0x01",   "f3e5000141"),   # ld (XBC+0x0100),A
    ("stw_dri wa, 0xe5, 0x00, 0x01",  "f3e5000150"),   # ld (XBC+0x0100),WA
    ("stl_dri xwa, 0xe5, 0x00, 0x01", "f3e5000160"),   # ld (XBC+0x0100),XWA
]

ok = True
for line, want in CASES:
    got = enc(line)
    good = got == bytes.fromhex(want)
    ok &= good
    print(f"{'PASS' if good else 'FAIL'}  {line:34} -> {got.hex(' ') if got else None}"
          f"   (want {bytes.fromhex(want).hex(' ')})")

print("\nWhy it looked like a gap -- the plain `ld` mnemonic collides with the")
print("force-d8 sentinel, which reads a displacement of 256 as 'wide form, disp 0':")
for line in ("ld (xbc + 0x0100), a", "ld (xbc + 0x00ff), a"):
    e = enc(line)
    print(f"   {line:24} -> {e.hex(' ') if e else None}")

print("\nunidasm round-trip of the three encodings:")
tmp = os.path.join(tempfile.gettempdir(), "_adv_plus256.bin")
open(tmp, "wb").write(b"".join(bytes.fromhex(w) for _, w in CASES))
print(subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", "0x0"],
                     capture_output=True, text=True).stdout.rstrip())
os.unlink(tmp)

print("\nThe CONVERTER, however, still cannot spell it (a converter gap):")
_a = sys.argv[:]; sys.argv = [sys.argv[0]]
spec = importlib.util.spec_from_file_location(
    "cc", os.path.join(REPO, "scripts/converters/convert_corroborated_blocks.py"))
cc = importlib.util.module_from_spec(spec); spec.loader.exec_module(cc); sys.argv = _a
t = "ld (XBC+0x0100),A"; raw = bytes.fromhex("f3e5000141")
for c in list(cc.translate(t)) + [cc.canonical(t)]:
    e = cc.encode(c)
    print(f"   {'MATCH' if e == raw else '     '}  {c!r:34} {e.hex(' ') if e else None}")

sys.exit(0 if ok else 1)
