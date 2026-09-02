#!/usr/bin/env python3
"""decode_encode_asymmetry.py -- which TLCS-900 byte sequences does the backend
DECODE into a text that ENCODES back to different bytes?

WHY THIS MATTERS MORE THAN A DECODER GAP
----------------------------------------
A byte the decoder refuses is loud: `<unknown>` in the listing, a `.byte` in the
source, a number in a debt column.  An asymmetric form is silent.  The decoder
prints a plausible mnemonic, a human reads it, and the text means a DIFFERENT
instruction from the one in the ROM.  The byte gate cannot object, because the
source that carries such a text does not reassemble -- so the error surfaces
only if somebody re-derives that region, which is exactly what a conversion lane
does.

Found 2026-09-02 by the per-span round trip in `twin_framed_spans.py`: 15 of 87
v7 spans that had passed every framing gate failed to reassemble.  Three of the
four forms below were localised as the cause; ⚠ THE FRAMING WAS RIGHT AND THE
SPELLING WAS WRONG, and a lane converting without a round trip would have
written these into the tree and blamed the boundaries.

★ NOTE WHAT IS AND IS NOT BROKEN.  In every case llvm-objdump consumes the
RIGHT NUMBER OF BYTES and prints the WRONG TEXT -- `9e 04 04` is three bytes and
is reported as three bytes, but it is spelled `push xiz`, which is the one-byte
0x3e.  So instruction BOUNDARIES, which is what the framing gates use, are not
affected; only the mnemonic is.  That is why the framing evidence survived and
only the emission had to be refused.

⚠ One site is NOT explained by these forms: `WndEvt_EventCodeDispatch +0x4C5`
round-trips correctly when decoded standalone with context, so its span failed
for some other reason and is still open.

WHAT IT REPORTS, per case: the ROM bytes, the text `llvm-objdump` prints for
them, and the bytes `llvm-mc` produces from that text.

RUN
    python3 scripts/analysis/decode_encode_asymmetry.py            # the cases
    python3 scripts/analysis/decode_encode_asymmetry.py --selftest
"""
import os
import re
import subprocess
import sys
import tempfile

LLVM = os.environ.get("LLVM_BIN",
                      os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
MC = os.path.join(LLVM, "llvm-mc")
OBJDUMP = os.path.join(LLVM, "llvm-objdump")
OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')

# Byte sequences taken from KN5000 v7 ROM sites that the twin-framing pass
# adjudicated as code and then could not reassemble.  Each is (rom bytes,
# where it was seen).
# ⚠ Each blob carries TRAILING CONTEXT and only its FIRST instruction is
# judged.  Without it llvm-objdump refuses a two-byte form at the end of its
# input (measured: `7f da` alone is <unknown>, `7f da 61 2a 1d` is not), and
# the case would be reported as a decoder gap instead of an asymmetry.
CASES = [
    (bytes([0x85, 0x11, 0xec, 0x61, 0xc9]), "v7 RhythmROM_PatternDisp_Check91 +0x02"),
    (bytes([0xbb, 0x01, 0xcf, 0x76, 0x85, 0x00]), "v7 AccTuning_LoadFromROM +0x0C"),
    (bytes([0x7f, 0xda, 0x61, 0x2a, 0x1d, 0xa3]), "v7 WndEvt_EventCodeDispatch +0x4C5"),
    (bytes([0x9e, 0x04, 0x04, 0x0b, 0xe7, 0x00]), "v7 Data_InOutGridDispatch +0x372"),
    (bytes([0x9c, 0x20, 0x04, 0xec, 0x88, 0x98]), "v7 PsGridBox_Scroll_Render +0x11"),
]


def disassemble(blob):
    with tempfile.TemporaryDirectory() as td:
        b = os.path.join(td, "b.bin")
        open(b, "wb").write(blob)
        s = os.path.join(td, "b.s")
        open(s, "w").write('.text\n.incbin "%s"\n' % b)
        o = os.path.join(td, "b.o")
        subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s], check=True)
        r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", o],
                           capture_output=True, text=True)
    out = []
    for line in r.stdout.split("\n"):
        m = OBJDUMP_RE.match(line)
        if m:
            out.append((bytes(int(x, 16) for x in m.group(2).split()),
                        m.group(3).strip()))
    return out


def assemble(text):
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "a.s")
        open(s, "w").write(".text\n" + text + "\n")
        o = os.path.join(td, "a.o")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                           capture_output=True, text=True)
        if r.returncode:
            return None, r.stderr.strip().split("\n")[0][:100]
        b = os.path.join(td, "a.bin")
        subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary",
                        "-j", ".text", o, b], check=True)
        return open(b, "rb").read(), ""


def run():
    print("toolchain: %s" % subprocess.run(
        ["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
         "log", "-1", "--format=%h"], capture_output=True, text=True).stdout.strip())
    print("%-14s %-30s %-14s %s" % ("rom bytes", "llvm-objdump prints", "re-encodes to", "site"))
    bad = 0
    for blob, site in CASES:
        ins = disassemble(blob)
        if not ins:
            print("%-14s %-30s %-14s %s" % (blob.hex(" "), "(nothing decoded)", "-", site))
            bad += 1
            continue
        raw, text = ins[0]
        got, err = assemble(text)
        gs = got.hex(" ") if got is not None else "REJECTED: " + err
        flag = "" if got == raw else "  <-- ASYMMETRIC"
        bad += got != raw
        print("%-14s %-30s %-14s %s%s" % (raw.hex(" "), text, gs, site, flag))
    print("\n%d of %d cases do not round-trip." % (bad, len(CASES)))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("llvm-mc exists", os.path.exists(MC))
    ck("llvm-objdump exists", os.path.exists(OBJDUMP))
    # a control: a form that IS symmetric must be reported as such, or this
    # script would flag everything and mean nothing.
    t = disassemble(bytes([0x11, 0x11]))
    got, _ = assemble(t[0][1])
    ck("a symmetric form round-trips (0x11 scf)", got == bytes([0x11]),
       "%s -> %s" % (t[0][1] if t else "?", got.hex() if got else "?"))
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else run())
