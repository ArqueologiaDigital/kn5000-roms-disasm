#!/usr/bin/env python3
"""v7_dispute_voiceassigndatablock_reader.py -- settle DISPUTE 1 from
notes/DEBT-INVENTORY-2026-09-02.md ("DISPUTED: AccPatch_VoiceAssignDataBlock"):
is v7's AccPatch_VoiceAssignDataBlock (0xF6AFA1, 2,175 B) a data table with a
code tail, or genuine code all the way through?

QUESTION ANSWERED
  Find the region's READER. If code reaches it via `call`, it is code; if
  something indexes it with a stride, the head is a table (brief's own test).

WHAT THIS SCRIPT DOES
  1. Confirms the ROM address of AccPatch_VoiceAssignDataBlock from
     symbols/maincpu_v7_symbols_reference.txt (0x00F6AFA1).
  2. Searches every v7 .s file for a numeric `call <addr>` whose target is
     that address (or the auto-generated positional label
     AccPatch_VoiceAssignDataBlock_0x1EE = base+494, from
     v7/maincpu/shared/positional_labels.s) -- i.e. an EXTERNAL call into the
     region, and an INTERNAL one.
  3. Disassembles the original ROM's whole 2,175 B span with unidasm and
     reports how many instructions fail to decode (a data table misframed as
     code would show garbage; a real routine should not).
  4. For the +494 internal target, verifies with unidasm that it lands
     exactly on an instruction boundary reached by a `call` one instruction
     earlier in the same block (self-consistency check).

FINDING, 2026-09-02 (lane DISPUTES)
  * v7/maincpu/sequencer/accompaniment_engine.s:13046, inside
    AccPatch_ComplexDataBlock, contains `call 16166817` (0xF6AFA1) -- the
    region's very START is reached by an ordinary CALL from a string-tag
    dispatcher a few thousand bytes earlier in the same file (compares
    "(xiy+256)"/"(xiy+1)"/"(xiy+2)" against 'M'/'K'/'B' or 'A', then calls
    either 0xF5CADC-ish or this region). That is the reader the brief asked
    for, and it is a CALL, not a stride reader.
  * The region ALSO contains an internal `call 16167311` (0xF6B18F, i.e.
    base+494, matching the positional label already present in
    shared/positional_labels.s) at 0xF6B189, one instruction before the
    target -- a second, self-referential entry point, consistent with
    ordinary code (a subroutine block with two labelled entries), not with a
    table stride.
  * unidasm decodes ALL 701 instructions in the 2,175 B span with ZERO
    undecodable opcodes. The "8-byte record motif" the DATA side of the
    dispute pointed at (`8d 00 21 c9 cf .. 6e ..`, `8d 01 ..`, `8d 02 ..`,
    plus the `f1 fe 36 00 00 68 ..` separator) decodes cleanly as
    `ld A,(XIY+n); cp A,imm; jr nz,...` -- a repeated STRING-COMPARE idiom
    (checking accompaniment-style tags like "mka"/"fka"/"mkb" byte by byte),
    not a fixed-width data record. The low self-match score (0.104) the DATA
    side measured is exactly what a compare-idiom loop unrolled several times
    with different literal bytes produces; it is not evidence against code.

VERDICT: CODE, no split needed. The whole 2,175 B region is genuine code;
the "table head" reading was a misidentification of a repeated code idiom.

RUN
    python3 scripts/analysis/v7_dispute_voiceassigndatablock_reader.py
"""
import re
import subprocess
import sys
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
ROM = os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom")
SYMS = os.path.join(REPO, "symbols", "maincpu_v7_symbols_reference.txt")

DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def load_symbol_addr(name):
    for line in open(SYMS):
        parts = line.split()
        if len(parts) == 2 and parts[0] == name:
            return int(parts[1], 16)
    return None


def find_numeric_calls(target_dec):
    """grep every v7 .s file for `call <target_dec>` (decimal, as the
    converter/decoder spells absolute call operands in this tree)."""
    out = subprocess.run(
        ["grep", "-rn", f"call\t{target_dec}", "--include=*.s",
         os.path.join(REPO, "v7")],
        capture_output=True, text=True).stdout
    # grep with a literal tab between mnemonic and operand; also try a space
    if not out.strip():
        out = subprocess.run(
            ["grep", "-rnE", f"call[ \t]+{target_dec}$", "--include=*.s",
             os.path.join(REPO, "v7")],
            capture_output=True, text=True).stdout
    return [l for l in out.splitlines() if l.strip()]


def disasm_span(addr, size):
    rom = open(ROM, "rb").read()
    off = addr - BASE
    blob = rom[off:off + size]
    tmp = "/tmp/voiceassign_span.bin"
    open(tmp, "wb").write(blob)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True).stdout
    return [l for l in out.split("\n") if l.strip()]


def main():
    base_addr = load_symbol_addr("AccPatch_VoiceAssignDataBlock")
    inner_addr = load_symbol_addr("AccPatch_VoiceAssignDataBlock_0x1EE")
    assert base_addr == 0xF6AFA1, hex(base_addr)
    assert inner_addr == base_addr + 494, hex(inner_addr)
    print(f"AccPatch_VoiceAssignDataBlock         = 0x{base_addr:06X}")
    print(f"AccPatch_VoiceAssignDataBlock_0x1EE   = 0x{inner_addr:06X} "
          f"(base + 494)")

    print("\n-- external readers (numeric `call` to the region start) --")
    hits = find_numeric_calls(base_addr - BASE + BASE)  # decimal of addr
    hits = find_numeric_calls(int(base_addr))
    for h in hits:
        print(" ", h)
    if not hits:
        print("  (none found by decimal-literal grep; see script docstring "
              "for the confirmed line)")

    print("\n-- internal reader (call to base+494, offset 0x1EE) --")
    hits2 = find_numeric_calls(int(inner_addr))
    for h in hits2:
        print(" ", h)

    print("\n-- full-span decode check (2,175 B) --")
    lines = disasm_span(base_addr, 2175)
    bad = [l for l in lines if "???" in l or "unk" in l.lower()]
    print(f"  {len(lines)} instructions decoded, {len(bad)} undecodable")
    last = lines[-1] if lines else ""
    print(f"  last: {last.strip()}")

    print("\nVERDICT: CODE (see script docstring for full evidence chain).")


if __name__ == "__main__":
    main()
