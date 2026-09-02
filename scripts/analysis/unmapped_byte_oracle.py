#!/usr/bin/env python3
"""unmapped_byte_oracle.py -- for a byte that tlcs900_backend cannot decode,
ask an INDEPENDENT decoder what it actually is.

QUESTION THIS ANSWERS
----------------------
`leading_byte_reserved_probe.py` establishes that a leading opcode byte has no
decode ANYWHERE in tlcs900_backend. That is a fact about OUR BACKEND. It was
then used to support a much stronger claim -- that such bytes are RESERVED
OPCODE SPACE, therefore NOT CODE, therefore v7's blocked slice tails are data
and no assembler work could ever convert them.

⚠ THAT INFERENCE IS INVALID, AND THIS SCRIPT IS THE DISPROOF. MAME's `unidasm`
is an independent TLCS-900 decoder and this project's standing decode authority.
Asked about the six bytes claimed to be reserved, it answers:

    0x01  normal        real TLCS-900/H instruction
    0x04  max           real TLCS-900/H instruction
    0x17  ldf 0xnn      real TLCS-900/H instruction
    0x1a  jp 0xnnnn     real -- a 16-bit ABSOLUTE JUMP
    0x1c  call 0xnnnn   real -- a 16-bit ABSOLUTE CALL
    0x1f  db            unidasm's unknown-byte marker: genuinely undefined

Five of the six are real instructions this backend has simply never been taught.
Two of them are CONTROL FLOW. Bytes that decode as `jp` and `call` are the most
code-like bytes there are, so "the backend cannot decode it" carried no evidence
about whether the region is code.

⚠ THE SAME MISTAKE IS EASY TO REPEAT, and it has a documented history here. 0xC1
looked unmapped under two successive versions of the probe and is in fact the
16-bit direct-address prefix. This project's TOOLCHAIN_VERSION log records SEVEN
separate occasions where "the backend cannot do this" meant "a spelling I had not
tried". The rule that follows: **never conclude anything about the ROM from a
backend refusal without asking a second decoder.**

RUN
    python3 scripts/analysis/unmapped_byte_oracle.py [0x01 0x04 ...]
    defaults to the six bytes the inventory claimed were reserved.
    needs MAME's unidasm; set $UNIDASM, else ~/compartilhado/mame/unidasm
"""
import os
import re
import subprocess
import sys
import tempfile

UNIDASM = os.environ.get("UNIDASM") or os.path.expanduser(
    "~/compartilhado/mame/unidasm")

# The bytes DEBT-INVENTORY-2026-09-02.md and TOOLCHAIN_VERSION UPDATE 11
# asserted were "unmapped anywhere in the decoder", i.e. reserved space.
CLAIMED = [0x01, 0x04, 0x17, 0x1a, 0x1c, 0x1f]

# unidasm's marker for a byte it does not recognise. If a future unidasm uses a
# different spelling this script must be updated, or it will silently call an
# undefined byte a real instruction.
UNKNOWN_MARKERS = ("db", ".db", "???", "illegal", "invalid")


def decode(byte):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes([byte] + [0x00] * 7))
        path = f.name
    try:
        r = subprocess.run([UNIDASM, path, "-arch", "tlcs900"],
                           capture_output=True, text=True)
        first = next((l for l in r.stdout.splitlines() if l.strip()), "")
        # unidasm prints "ADDR: <hex bytes><2+ spaces><mnemonic> <operands>".
        # ⚠ Do NOT try to find the mnemonic by skipping hex-looking tokens:
        # unidasm's unknown-byte marker is spelled "db", which is entirely hex
        # digits, so that heuristic silently reports 0x1f as a real instruction
        # -- the exact error this script exists to catch. Split on the
        # two-or-more-space column separator instead.
        body = first.split(":", 1)[1] if ":" in first else first
        cols = re.split(r"\s{2,}", body.strip())
        text = cols[1].strip() if len(cols) > 1 else ""
        return first.strip(), text
    finally:
        os.unlink(path)


def main():
    if not os.path.exists(UNIDASM):
        sys.exit("unidasm not found at %s (set $UNIDASM)" % UNIDASM)
    args = sys.argv[1:]
    targets = [int(a, 0) for a in args] if args else CLAIMED

    print("independent decoder: %s" % UNIDASM)
    print()
    real, undefined = [], []
    for b in targets:
        raw, text = decode(b)
        toks = text.split()
        mnem = toks[0] if toks else ""
        is_unknown = (not mnem) or mnem.lower() in UNKNOWN_MARKERS
        (undefined if is_unknown else real).append((b, mnem))
        print("  0x%02x  %-40s %s" %
              (b, raw, "UNDEFINED" if is_unknown else "REAL INSTRUCTION"))
    print()
    if real:
        print("⚠ %d of %d are REAL TLCS-900 instructions this backend lacks: %s"
              % (len(real), len(targets),
                 ", ".join("0x%02x=%s" % (b, m) for b, m in real)))
        flow = [(b, m) for b, m in real if m.lower() in ("jp", "call", "jr", "ret")]
        if flow:
            print("  ★ and %s are CONTROL FLOW -- a region gated by these is "
                  "code, not data." %
                  ", ".join("0x%02x=%s" % (b, m) for b, m in flow))
    print("genuinely undefined: %s" %
          (", ".join("0x%02x" % b for b, _ in undefined) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
