#!/usr/bin/env python3
"""Who references this address in prom_c?  -- so a routine header's "Called from:" is not a guess.

QUESTION ANSWERED
  Every routine header in this tree has a "Called from:" line, and the honest default is
  "not yet traced".  This narrows that down mechanically for one address at a time.

  Four reference forms are searched, and they are NOT equally trustworthy:

    ABS   the 24-bit or 32-bit little-endian address appears as a literal.  Reported with
          the byte in front of it, because `1D` = call and `1B` = jp make it a control
          transfer while anything else makes it (probably) a data operand -- `lda`, `ld
          XBC,#imm`, or a pointer inside a table.
    DIRn  a memory-operand PREFIX byte followed by the address in n bits, n in {8,16,24}.
          On TLCS-900 a direct-address memory operand is spelled

              prefix  =  0xC0 | (size << 4) | width
              size    :  0 = byte (0xC.), 1 = word (0xD.), 2 = long (0xE.), 3 = dst (0xF.)
              width   :  0 = (n)   one address byte      -- only if addr <= 0x0000FF
                         1 = (nn)  two address bytes     -- only if addr <= 0x00FFFF
                         2 = (nnn) three address bytes

          so there are TWELVE spellings of one address, not one.  All twelve that can
          encode the requested address are searched.  ⚠ THIS IS THE POINT OF THE TOOL: an
          earlier census of 0x00F2F3 in this tree reported NINETEEN references and was
          wrong, because 0x00F2F3 also fits in 16 bits and the two `0xD1`-prefixed sites at
          prom_c 0xF99FC2 and 0xF99FCD were invisible to a 24-bit-only search.  The DIR24
          rows are the same hits the ABS24 search finds (the literal follows the prefix);
          they are printed once, under whichever tag matched first.  ⚠ That also means
          a 24-bit literal that merely HAPPENS to sit behind a 0xC2/0xD2/0xE2/0xF2 byte is
          reported as DIR24 rather than as an operand -- read the window, as always.
    CALR  `1E dd dd` (calr, signed 16-bit displacement) whose target is this address.
    JRL   `1C cc dd dd`? NOT searched.  See LIMITS.

  Prefix-byte meanings are read off this tree's own verified round-trips in
  notes/prom_c-llvm-mc-spellings.md: `f0 20 b2` = res 2,(0x20) is width 0; `d1 f3 f2 23` =
  ld HL,(0xf2f3) is width 1; `e2 f3 f2 00 21` = ld XBC,(0x00f2f3) is width 2.

LIMITS -- read before quoting a result
  * A hit is a byte pattern, not a proven instruction.  The image is not linearly decodable
    (notes say prom_c holds an IEEE-754 pool that disassembles into 280 phantom registers),
    so `1E xx xx` can occur inside data and inside the middle of a longer instruction.
    EVERY hit is therefore printed with unidasm's rendering of a window ending at it, and
    a hit whose window does not decode to a call/jump at the right place must be discarded
    by the person reading it.  This tool narrows; it does not certify.
  * Short PC-relative forms (jr, and calr's 8-bit relatives) are not searched at all, so an
    empty result NEVER means "nothing calls this".
  * A reference through a POINTER REGISTER (`lda XBC,addr` far away, then `ld (XBC),A`) is
    invisible to every search here.  A count from this tool is therefore always a count of
    LITERAL-ADDRESSED references, and must be quoted that way.
  * The 8-bit width is a single byte after the prefix, so for a low address DIR8 is mostly
    noise -- read the windows.

RUN
  python3 notes/prom_c_xrefs.py 0xF9806D
  python3 notes/prom_c_xrefs.py 0xF9806D --img a --no-window
"""
import argparse
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
IMAGES = {"a": ("wsa1_prom_a.ic12", 0xF80000), "b": ("wsa1_prom_b.ic13", 0xF00000),
          "c": ("wsa1_prom_c.ic28", 0xF80000), "d": ("wsa1_prom_d.bin", 0x000000)}


def window(data, base, off, back=12, n=24):
    lo = max(0, off - back)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[lo:lo + n])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(base + lo)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    return [l for l in p.stdout.splitlines() if l.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("addr", type=lambda x: int(x, 0))
    ap.add_argument("--img", default="c", choices=list(IMAGES))
    ap.add_argument("--no-window", action="store_true")
    ap.add_argument("--classify", action="store_true",
                    help="for each ABS hit print ONE unidasm line decoded from the byte in "
                         "front of the literal -- which is where the instruction that uses it "
                         "starts for every 32-bit-direct form on this CPU (prefix 0xE2/0xD2/"
                         "0xC2/0xF2 + 3 address bytes + sub-opcode).  Turns a list of hits "
                         "into a read/write census.  ⚠ Still a heuristic: it assumes the "
                         "literal is the operand of a prefixed direct-address instruction, "
                         "and prints whatever unidasm makes of the bytes if it is not.")
    a = ap.parse_args()
    fn, base = IMAGES[a.img]
    data = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()

    lit24 = struct.pack("<I", a.addr)[:3]
    lit32 = struct.pack("<I", a.addr)
    print(f"references to 0x{a.addr:06X} in prom_{a.img}")

    seen = set()
    # ---- the twelve direct-address spellings (see the docstring) -----------------
    # Emitted FIRST so that a hit is tagged with the prefix that produced it; the ABS
    # sweep below then skips it, which keeps every hit counted exactly once.
    pats = []
    for size, sc in enumerate("CDEF"):
        base_pfx = 0xC0 + (size << 4)
        if a.addr <= 0xFF:
            pats.append((f"DIR8/{sc}0", bytes([base_pfx + 0, a.addr])))
        if a.addr <= 0xFFFF:
            pats.append((f"DIR16/{sc}1", bytes([base_pfx + 1]) + struct.pack("<H", a.addr)))
        pats.append((f"DIR24/{sc}2", bytes([base_pfx + 2]) + lit24))
    n_dir = 0
    for tag, pat in pats:
        i = data.find(pat)
        while i >= 0:
            if i + 1 not in seen:          # key on the LITERAL's offset, as the ABS sweep does
                seen.add(i + 1)
                n_dir += 1
                print(f"  {tag:<9} at 0x{base + i:06X}  (instruction starts here)")
                if a.classify:
                    w = window(data, base, i, back=0, n=10)
                    if w:
                        print(f"        {w[0]}")
                if not a.no_window:
                    for l in window(data, base, i):
                        print(f"        {l}")
            i = data.find(pat, i + 1)

    for tag, pat in (("ABS32", lit32), ("ABS24", lit24)):
        i = data.find(pat)
        while i >= 0:
            if i not in seen:
                seen.add(i)
                prev = data[i - 1] if i else -1
                kind = {0x1D: "call", 0x1B: "jp", 0x1E: "?"}.get(prev, "operand/data")
                # ⚠ The address printed is the LITERAL's, which is one byte past the
                # start of a `call`/`jp`.  Quoting the literal address as "called from"
                # is an off-by-one that is easy to make and hard to see, so the
                # instruction address is spelled out for exactly the two opcodes where
                # it is known.
                where = (f"  {tag} at 0x{base + i:06X}  prev byte 0x{prev:02X} -> {kind}")
                if prev in (0x1D, 0x1B):
                    where += f"   [instruction starts at 0x{base + i - 1:06X}]"
                print(where)
                if a.classify and i:
                    w = window(data, base, i - 1, back=0, n=10)
                    if w:
                        print(f"        {w[0]}")
                if not a.no_window:
                    for l in window(data, base, i):
                        print(f"        {l}")
            i = data.find(pat, i + 1)

    n = 0
    for i in range(len(data) - 3):
        if data[i] != 0x1E:
            continue
        d = struct.unpack("<h", data[i + 1:i + 3])[0]
        if base + i + 3 + d == a.addr:
            n += 1
            print(f"  CALR  at 0x{base + i:06X}  (disp {d:+d})")
            if not a.no_window:
                for l in window(data, base, i, back=8, n=16):
                    print(f"        {l}")
    if not seen and not n:
        print("  (no absolute literal and no calr displacement found -- this does NOT mean")
        print("   nothing calls it; short PC-relative forms are not searched)")
    print(f"  TOTAL literal-addressed sites: {len(seen)}"
          f"   (of which {n_dir} matched a direct-address prefix), CALR: {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
