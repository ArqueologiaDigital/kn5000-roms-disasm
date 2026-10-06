#!/usr/bin/env python3
"""verify_mislabel_markers.py -- did the three self-tagged MISLABELLED markers in
kn5000_subprogram_v142.s (VoiceCC_DataTable_0280FE, TVF_Refresh_Sounding_Voices,
VoiceModWheel_DataTable_02A061) actually get closed, and does the rebuilt ROM still
match the original byte-for-byte across exactly those spans?

QUESTION IT ANSWERS
    kn5000_source_coverage.py flags these three spans as "self-tagged still-undecoded
    markers needing human adjudication" (the tree's own "MISLABELLED, THIS IS CODE"
    text). This script is the reproducibility artefact for the lane report's numbers:
      - how many `.byte` directive LINES remain inside each address range in the
        current source (should be 0 for all three after the 2026-09-02 conversion)
      - whether the rebuilt ROM (rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom) is
        byte-identical to original_ROMs/kn5000_subprogram_v142.rom across exactly
        those byte ranges (not just "the whole ROM cmp'd clean", which proves nothing
        about these three spans specifically if something else changed too)

    File-offset formula for this ROM: the linker script (v142/subcpu/subcpu.ld) maps
    address space 0x0400-0x04FF and 0xF000-0x3EAFF onto the final image via the two
    `dd` extractions in the Makefile's kn5000_subprogram_v142.llvm.rom rule. All three
    marker addresses are >= 0xF000, where file_offset = address - 0xF000 + 256
    = address - 61184 (verified against the rebuilt ROM before this script existed;
    see the lane report for kn5000-roms-disasm w2/mislabel, 2026-09-02).

RUN
    make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom   # from the repo root first
    python3 scripts/lanes/verify_mislabel_markers.py
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SRC = REPO / "v142/subcpu/kn5000_subprogram_v142.s"
REBUILT = REPO / "rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom"
ORIGINAL = REPO / "original_ROMs/kn5000_subprogram_v142.rom"

# (label, start_addr, end_addr_exclusive) -- end taken from each marker's own
# "0xSTART-0xEND" header text in the source.
REGIONS = [
    ("VoiceCC_DataTable_0280FE", 0x0280FE, 0x028839),
    ("TVF_Refresh_Sounding_Voices", 0x028F75, 0x029E31),
    ("VoiceModWheel_DataTable_02A061", 0x02A061, 0x02A0E9),
]


def addr_to_offset(addr):
    if 0x0400 <= addr <= 0x04FF:
        return addr - 0x0400
    if addr >= 0xF000:
        return addr - 61184
    raise ValueError(f"address {addr:#x} outside the two known ROM windows")


def count_byte_lines(lines, addr_lo, addr_hi):
    """Count `.byte` directive lines textually between the two marker headers
    that bracket [addr_lo, addr_hi) -- approximated by scanning between the
    label's start line and the next top-level '; ---' marker or next label at
    a colon that isn't a local sub-label, whichever comes first. Simpler and
    robust for this file: just scan from the marker header to the next
    "; --- 0x" header or EOF."""
    header_re = re.compile(r'^; --- 0x([0-9A-Fa-f]+)-0x([0-9A-Fa-f]+)')
    start_i = None
    for i, l in enumerate(lines):
        m = header_re.match(l)
        if m and int(m.group(1), 16) == addr_lo:
            start_i = i
            break
    if start_i is None:
        return None
    end_i = len(lines)
    for i in range(start_i + 1, len(lines)):
        if header_re.match(lines[i]):
            end_i = i
            break
    return sum(1 for l in lines[start_i:end_i] if re.match(r'^\s*\.byte\s', l))


def main():
    lines = SRC.read_text(encoding="latin-1").splitlines(keepends=True)
    print("--- .byte directive lines remaining in each marker's span (source text) ---")
    for label, lo, hi in REGIONS:
        n = count_byte_lines(lines, lo, hi)
        print(f"  {label:32} 0x{lo:06X}-0x{hi-1:06X}  .byte lines: {n}")

    if not REBUILT.exists():
        print(f"\n{REBUILT} does not exist -- run "
              f"`make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom` first.")
        sys.exit(1)
    if not ORIGINAL.exists():
        print(f"\n{ORIGINAL} does not exist.")
        sys.exit(1)

    rebuilt = REBUILT.read_bytes()
    original = ORIGINAL.read_bytes()
    print(f"\n--- byte match, rebuilt vs original, exactly across each marker's range ---")
    all_ok = True
    for label, lo, hi in REGIONS:
        o_lo, o_hi = addr_to_offset(lo), addr_to_offset(hi)
        a = rebuilt[o_lo:o_hi]
        b = original[o_lo:o_hi]
        ok = a == b
        all_ok &= ok
        print(f"  {label:32} {hi - lo} bytes  {'MATCH' if ok else 'MISMATCH'}")
        if not ok:
            for i, (x, y) in enumerate(zip(a, b)):
                if x != y:
                    print(f"      first diff at +{i}: rebuilt={x:#04x} original={y:#04x}")
                    break

    print(f"\nOverall: {'PASS' if all_ok else 'FAIL'}")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
