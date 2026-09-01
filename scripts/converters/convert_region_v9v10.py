#!/usr/bin/env python3
"""convert_region_v9v10.py -- surgically convert ONE pre-vetted .byte run to
real instructions, in v9 AND v10 at once.

QUESTION ANSWERED: v9_v10_undisassembled_census.py's `--judge` stage ranks
non-.incbin DATA regions by a calibrated CODE-likeness rule and hand-audits
the hits (see scripts/analysis/README-v9v10-census.md). That produces a list
of addresses believed to be genuine undisassembled code. This script is the
next step: given one such region (identified by its file, 1-indexed start
line, and expected byte count -- all three read straight off the census
output), decode it with convert_code_bytes.py's per-instruction disassembler
and, if every resulting instruction round-trips through llvm-mc byte-exactly,
splice the result back into the source.

⚠ WHY THIS IS A SEPARATE TOOL FROM convert_code_bytes.py --all / --file:
running the bulk converter over a WHOLE FILE also "converts" long stretches
that are genuinely DATA (widget tables, etc.) whenever a byte sequence
happens to decode into a syntactically valid, round-trippable instruction by
coincidence -- confirmed 2026-09-01 on audio_control_engine.s, which produced
nonsense like "normal", "max", "push 0x7f" a few hundred bytes away from the
real code. This script never looks past the exact line range of ONE region
that was already vetted by the census's statistical rule (ends on
ret/reti/jp, low `db`% under unidasm, etc.) -- it does not go looking for
candidates on its own.

WHY SOME REGIONS ONLY PARTIALLY CONVERT: convert_code_bytes.py decodes
byte-for-byte and only emits a mnemonic when verify_roundtrip confirms
llvm-mc reassembles it identically; anything else is left as `.byte` in
place, in order. Both language coverage AND framing therefore fail closed:
an unsupported TLCS-900 form (e.g. `push QIZ`, `and C,(rADL+..)`) or a
misdecoded instruction boundary just leaves a shorter `.byte` run rather than
emitting wrong bytes.

WHY v9 AND v10 TOGETHER: `.map.pkl` census data showed v9 and v10 hide the
IDENTICAL 31 undisassembled regions at the SAME addresses with the SAME
file:line (they were disassembled in lockstep from the same firmware
lineage). Checked directly here too: every region converted in this session
had byte-identical source in both trees before conversion. So one decode is
applied to both files, and the assertion `raw9 == raw10` is what licenses
that reuse -- it refuses to touch a region where the two revisions actually
differ.

VERIFICATION: after any batch of these, rebuild BOTH ROMs
(`make rebuilt_ROMs/kn5000_v9_program.llvm.rom rebuilt_ROMs/kn5000_v10_program.llvm.rom`)
and `cmp` against `original_ROMs/`. This script cannot move a byte by
construction (concatenating instructions that individually round-trip
reproduces the original byte string exactly, in order) but the ROM-level
`cmp` is the check that actually proves it, and is cheap enough to run after
every batch.

Run (single region, dry run -- prints the replacement, changes nothing):
    python3 scripts/converters/convert_region_v9v10.py \\
        maincpu/audio/audio_control_engine.s 46 264

Run for real (also requires --apply):
    python3 scripts/converters/convert_region_v9v10.py \\
        maincpu/audio/audio_control_engine.s 46 264 --apply

2026-09-01: applied to 14 of the 31 judge() hits, all of them regions whose
.byte run is NOT interrupted by an .ascii/.long directive or a pre-existing
instruction (see scripts/analysis/README-v9v10-census.md for the other 17,
which need that interruption handled first and were left alone this session):
    audio/audio_control_engine.s:46 (264B), :8566 (232B), :8643 (405B)
    sequencer/accompaniment_engine.s:12883 (448B), :12942 (534B),
        :13248 (111B), :24990 (64B)
    sequencer/bmdredit_routines.s:1521 (112B), :3910 (194B)
    sequencer/seq_step_routines.s:3029 (120B)
    sequencer/smf_config_routines.s:2237 (76B)
    ui/drawbar_panel_ui.s:1169 (240B), :1380 (66B)
    ui/ui_widget_defs.s:7903 (77B)
Total 2,943B of candidate regions, 2,306B (78.4%) converted to real
instructions, 637B left as (shorter, still-genuine) .byte residue -- an
unsupported form or an unrecognised sub-opcode, never a wrong guess.
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_code_bytes as cb  # noqa: E402

BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')


def parse_block(lines, start_idx):
    """start_idx is 0-indexed. Returns (end_idx_inclusive, raw_bytes)."""
    raw = []
    i = start_idx
    while i < len(lines):
        m = BYTE_RE.match(lines[i])
        if not m:
            break
        raw.extend(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1)))
        i += 1
    return i - 1, raw


def build_replacement(raw_bytes):
    results = cb.convert_block(raw_bytes, base_pc=0, verbose=False)
    new_lines = []
    undecoded = []

    def flush():
        if undecoded:
            hexs = ', '.join(f'0x{b:02x}' for b in undecoded)
            new_lines.append(f'\t.byte {hexs}')
            undecoded.clear()

    for mnem, off, nb in results:
        if mnem is None:
            undecoded.extend(raw_bytes[off:off + nb])
        else:
            flush()
            new_lines.append(f'\t{mnem}')
    flush()
    remaining = sum(nb for mnem, _, nb in results if mnem is None)
    return new_lines, remaining


def process(relpath, start_line, expected_size, apply=False):
    p9 = REPO / 'v9' / relpath
    p10 = REPO / 'v10' / relpath
    lines9 = p9.read_text(encoding='latin-1').split('\n')
    lines10 = p10.read_text(encoding='latin-1').split('\n')
    start_idx = start_line - 1
    end9, raw9 = parse_block(lines9, start_idx)
    end10, raw10 = parse_block(lines10, start_idx)
    assert raw9 == raw10, f"v9/v10 byte mismatch at {relpath}:{start_line}"
    assert len(raw9) == expected_size, (
        f"size mismatch at {relpath}:{start_line}: got {len(raw9)} expected "
        f"{expected_size} -- the block is interrupted by something other "
        f"than .byte (an .ascii/.long run, or a real instruction); this tool "
        f"refuses rather than guess the boundary")
    new_lines, remaining = build_replacement(raw9)
    print(f"=== {relpath}:{start_line}  {len(raw9)}B  ->  "
          f"{len(raw9) - remaining}B converted, {remaining}B left as .byte ===")
    for nl in new_lines:
        print("   ", nl)
    if apply:
        lines9[start_idx:end9 + 1] = new_lines
        lines10[start_idx:end10 + 1] = new_lines
        p9.write_text('\n'.join(lines9), encoding='latin-1')
        p10.write_text('\n'.join(lines10), encoding='latin-1')
        print(f"APPLIED to {p9} and {p10}")
    return remaining


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('relpath', help='path relative to v9/ and v10/, e.g. '
                                     'maincpu/audio/audio_control_engine.s')
    ap.add_argument('start_line', type=int, help='1-indexed line of the '
                                                  'first .byte directive')
    ap.add_argument('expected_size', type=int, help='region size in bytes, '
                                                      'from the census output')
    ap.add_argument('--apply', action='store_true',
                     help='write the change (default: dry run, prints only)')
    a = ap.parse_args()
    process(a.relpath, a.start_line, a.expected_size, apply=a.apply)
