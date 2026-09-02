#!/usr/bin/env python3
"""leading_byte_reserved_probe.py -- is a given LEADING opcode byte genuinely
unmapped in the tlcs900 decoder, or does it merely need the right FOLLOWING
bytes?

QUESTION THIS ANSWERS
----------------------
`notes/DEBT-INVENTORY-2026-09-02.md` and `TOOLCHAIN_VERSION` UPDATE 11 assert
that six single-byte opcodes -- 0x01, 0x04, 0x17, 0x1a, 0x1c, 0x1f -- are
"confirmed unmapped anywhere in the decoder", i.e. REAL RESERVED OPCODE SPACE.
That claim is load-bearing: it is the sole support for the much stronger
conclusion that v7's blocked slice tails ARE NOT CODE, and therefore that no
assembler change can ever make them round-trip. That conclusion reframed the
whole v7 remainder from a spelling problem into a typing problem, so it needs a
falsifiable test rather than a source reading.

⚠ THE OBVIOUS TEST IS WRONG, AND THIS SCRIPT EXISTS BECAUSE I SHIPPED IT FIRST.
Disassembling `<byte> 00 00 00 00 00` and reading "invalid instruction
encoding" proves NOTHING. 0xC1 -- a prefix byte introducing a whole family of
register-indexed memory forms, and the blocker census's own #2 entry -- refuses
that exact input, because 0x00 is not a valid MODE byte after it. So do 0xC0,
0xE3 and 0xAD. A leading byte that is merely PICKY is indistinguishable from one
that is RESERVED under a single-input probe. A first version of this script swept
only the SECOND byte and its own control caught it: four known-mapped foils came
back "RESERVED".

WHAT THIS DOES INSTEAD
-----------------------
For each candidate leading byte, sweep ALL 65,536 value combinations for EVERY
PAIR of positions drawn from the first FOUR continuation bytes -- six pairs,
393,216 candidates per leading byte -- holding the other continuation bytes at
0x00. A byte that decodes for at least one of those is MAPPED; it just needed
the right operand.

⚠ THE DEPTH IS THE WHOLE DIFFICULTY, AND THE CONTROL CAUGHT ME TWICE. Version 1
swept only the second byte: four known-mapped foils came back "RESERVED".
Version 2 swept the second and third: 0xC1 STILL came back "RESERVED", and 0xC1
is the 16-bit direct-address prefix (`decodeDirectAddr` with AddrBytes=2, reached
from `FirstByte >= 0xC0 && FirstByte <= 0xC7` with SubType 1). Its layout is
prefix, TWO ADDRESS BYTES, then the sub-opcode -- so a sweep of bytes 2 and 3
only ever varied the ADDRESS and left the sub-opcode at 0x00, which is invalid.
`c1 34 12 22` decodes as `ldb_d8 b, (4660)`. Sweeping PAIRS across four
positions reaches a sub-opcode sitting behind up to three address bytes.

⚠ AND THIS IS STILL NOT EXHAUSTIVE. A form needing THREE specific non-zero
continuation bytes at once would be missed. That is why the verdict below is
phrased as "no decode found", and why the foil group is not optional.

BATCHING, AND WHY THE LINE ATTRIBUTION IS SOUND
-----------------------------------------------
One llvm-mc process per candidate would be ~900k spawns. Instead every candidate
is one LINE of a single disassembly stream, padded with 8 trailing 0x00 bytes,
and llvm-mc's diagnostics carry a line number (`<stdin>:N:1`).

The padding is what makes per-line attribution valid. llvm-mc decodes the input
as ONE continuous stream and does not treat a newline as a decode boundary, so
alignment could in principle drift from line to line. It cannot here, because:
  * 0x00 is `nop`, a ONE-byte instruction, so any leftover padding is consumed
    one byte at a time and the stream always lands exactly on the next line's
    first byte;
  * the pad is longer than the longest TLCS-900 encoding, so an instruction
    starting at a line's first byte always ends inside that line;
  * on a FAILED decode llvm-mc advances by one byte and continues, so a failure
    also realigns through the padding.
Therefore "an error reported at line N, column 1" means exactly "the candidate
on line N did not decode from its first byte". Verified directly against a mixed
batch of known-good and known-bad candidates before this script was written.

⚠ WHAT THIS STILL DOES NOT PROVE. It measures THE DECODER, not the SILICON. An
opcode this backend does not implement could still be a real TMP94C241 /
TMP95C061 instruction nobody has taught it -- this project has repeatedly found
that "the backend cannot do this" meant "a spelling I had not tried". So the
honest claim is "unmapped in tlcs900_backend at the pinned commit", and any
conclusion drawn about v7 must be stated as resting on that, not on the hardware.

THE CONTROL -- REQUIRED READING BEFORE QUOTING A RESULT
--------------------------------------------------------
Three groups are scored together and printed together:

  claimed  the six bytes asserted to be reserved.
  foil     bytes KNOWN to be mapped but PICKY -- 0xC1, 0x95, 0xAD (the census's
           other top blockers) and prefix bytes 0xC0, 0xF3, 0xE3. ⚠ IF A FOIL
           COMES BACK "RESERVED", THE PROBE IS BROKEN, NOT THE FOIL: these are
           demonstrably reachable elsewhere in the tree. The script exits
           non-zero and tells you not to quote the result.
  mapped   bytes that decode trivially (0x00 nop, 0x08 ldio) -- a floor check
           that the harness can see a success at all.

A criterion that cannot fail is not evidence. This one has already failed once,
which is the only reason to trust it now.

RUN
    python3 scripts/analysis/leading_byte_reserved_probe.py
    needs $LLVM_MC, else ~/compartilhado/llvm-project/build/bin/llvm-mc
"""
import os
import re
import subprocess
import sys

MC = os.environ.get("LLVM_MC") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc")

# Longer than the longest TLCS-900 encoding, and all `nop`, so the stream
# realigns on every line boundary. See the header before changing either fact.
PAD = [0x00] * 8

# Continuation positions swept, pairwise. Position 1 is the byte right after the
# leading opcode. Four is enough to reach a sub-opcode behind three address
# bytes, which is the deepest prefix layout in this decoder.
SWEEP_POSITIONS = [1, 2, 3, 4]

GROUPS = [
    ("claimed", [0x01, 0x04, 0x17, 0x1a, 0x1c, 0x1f]),
    ("foil",    [0xc1, 0x95, 0xad, 0xc0, 0xf3, 0xe3]),
    ("mapped",  [0x00, 0x08]),
]

ERR_RE = re.compile(r"^<stdin>:(\d+):1: (?:warning|error)")


def sweep_pair(lead, pi, pj):
    """Sweep both positions pi,pj over 0..255 with other bytes 0. -> (n_ok, first)."""
    width = max(SWEEP_POSITIONS) + 1
    lines = []
    combos = []
    for vi in range(256):
        for vj in range(256):
            seq = [lead] + [0x00] * (width - 1)
            seq[pi] = vi
            seq[pj] = vj
            combos.append((vi, vj))
            lines.append(" ".join("0x%02x" % b for b in seq + PAD))
    r = subprocess.run([MC, "--disassemble", "--arch=tlcs900"],
                       input="\n".join(lines) + "\n",
                       capture_output=True, text=True)
    failed = set()
    for line in r.stderr.splitlines():
        m = ERR_RE.match(line)
        if m:
            failed.add(int(m.group(1)))
    n_ok = 0
    first = None
    for i, combo in enumerate(combos, start=1):
        if i not in failed:
            n_ok += 1
            if first is None:
                first = (pi, combo[0], pj, combo[1])
    return n_ok, first


def probe(lead):
    """Pairwise sweep over SWEEP_POSITIONS. Return (n_ok, first_ok_description)."""
    total = 0
    first = None
    for a in range(len(SWEEP_POSITIONS)):
        for b in range(a + 1, len(SWEEP_POSITIONS)):
            n, f = sweep_pair(lead, SWEEP_POSITIONS[a], SWEEP_POSITIONS[b])
            total += n
            if first is None and f is not None:
                first = f
    return total, first


def main():
    if not os.path.exists(MC):
        sys.exit("llvm-mc not found at %s (set $LLVM_MC)" % MC)
    npairs = len(SWEEP_POSITIONS) * (len(SWEEP_POSITIONS) - 1) // 2
    print("probe: %d position-pairs x 65,536 = %s candidates per leading byte, "
          "pad %s" % (npairs, format(npairs * 65536, ","),
                      " ".join("%02x" % b for b in PAD)))
    print()
    verdicts = {}
    for group, leads in GROUPS:
        for lead in leads:
            n, first = probe(lead)
            verdict = "RESERVED" if n == 0 else "mapped"
            verdicts[lead] = (group, n, verdict)
            note = ("" if first is None else
                    "  (first: byte%d=%02x byte%d=%02x)" % first)
            print("  %-8s 0x%02x  %7d decode  %-9s%s" %
                  (group, lead, n, verdict, note))
    print()

    broken = ["0x%02x" % b for b, (g, n, v) in verdicts.items()
              if g in ("foil", "mapped") and v == "RESERVED"]
    if broken:
        print("⚠ CONTROL FAILED: %s came back RESERVED. These are known-mapped "
              "bytes, so the PROBE is wrong, not them. Do NOT quote the "
              "'claimed' column." % ", ".join(broken))
        return 1

    reserved = sorted(b for b, (g, n, v) in verdicts.items()
                      if g == "claimed" and v == "RESERVED")
    mapped = sorted(b for b, (g, n, v) in verdicts.items()
                    if g == "claimed" and v == "mapped")
    print("CONTROL PASSED: every foil and every known-mapped byte decoded for "
          "at least one continuation, so a 'RESERVED' verdict below is not an "
          "artefact of the method.")
    print("claimed reserved, CONFIRMED unmapped in this backend: %s" %
          (", ".join("0x%02x" % b for b in reserved) or "none"))
    if mapped:
        print("⚠ claimed reserved but ACTUALLY MAPPED: %s -- the inventory's "
              "claim is WRONG for these, and any v7 conclusion resting on them "
              "must be withdrawn." % ", ".join("0x%02x" % b for b in mapped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
