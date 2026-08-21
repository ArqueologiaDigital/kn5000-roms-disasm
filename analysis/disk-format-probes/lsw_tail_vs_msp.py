#!/usr/bin/env python3
"""What is the non-TLV tail of a .LSW file? Partly a verbatim copy of the .MSP.

QUESTION ANSWERED: docs/kn-disk-file-formats.md described .LSW 0x4E80..0x5800 as
"NOT TLV, unframed bytes" with a mysterious `5A 5A 5A "LKE" 80 00` magic. This
probe shows the last 0x380 bytes are the same disk's .MSP file, byte for byte,
and that "LKE" is the .MSP format's OWN signature rather than anything specific
to .LSW.

    LSW[0x5480 + k] == MSP[k]   for k in 0 .. 0x380     (896 bytes)

    .MSP header : 4C 4B 45 ... 5A 5A 5A     "LKE" at +0x00, "ZZZ" at +0x0B
    .LSW @0x4EB0: 5A 5A 5A 4C 4B 45 80 00   the same two tokens, reordered
    .LSW header : 5A 5A 01 00 "M60" 0A

⚠ TRAP, hit while writing this. Scanning for MSP windows inside the tail with a
fixed-size probe reports dozens of extra "matches" that are all at one offset
(0x552D) -- they are runs of 0x00 matching other runs of 0x00. A probe made of
constant bytes matches anywhere the same constant repeats. This script skips any
window that is a single repeated byte, which removes all of them.

Run:  python3 lsw_tail_vs_msp.py <dir-with-one-disk's-extracted-files>
Exits non-zero if the mapping is not exact on every disk given.
"""
import glob, os, sys

COPY_AT, COPY_LEN = 0x5480, 0x380


def check(d):
    lsws = glob.glob(os.path.join(d, "**", "*.LSW"), recursive=True)
    msps = glob.glob(os.path.join(d, "**", "*.MSP"), recursive=True)
    if not lsws or not msps:
        print(f"  {d}: no .LSW/.MSP pair"); return False
    lsw, msp = open(lsws[0], "rb").read(), open(msps[0], "rb").read()
    seg = lsw[COPY_AT:COPY_AT + COPY_LEN]
    exact = seg == msp[:COPY_LEN]
    print(f"  {os.path.basename(lsws[0])} ({len(lsw)} B) / "
          f"{os.path.basename(msps[0])} ({len(msp)} B): "
          f"LSW[0x{COPY_AT:X}:+0x{COPY_LEN:X}] == MSP[:0x{COPY_LEN:X}] -> {exact}")
    if not exact:
        return False
    # confirm the mapping is linear and not a coincidence of constant data
    informative = sum(1 for i in range(0, COPY_LEN - 64, 64)
                      if len(set(msp[i:i + 64])) > 1)
    print(f"     {informative} of {COPY_LEN // 64} 64-byte windows are non-constant "
          f"(constant ones cannot evidence a mapping)")
    return informative > 0


def main():
    dirs = sys.argv[1:] or ["."]
    ok = all([check(d) for d in dirs])
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
