#!/usr/bin/env python3
"""convert_v7interior_drop_wrong_labels.py -- convert the 15 v7 strict-
pool confirmed regions that convert_interrupted_region_v7.py refused
with "label(s) do not land on any decoded segment boundary", by DROPPING
the interior labels rather than trying to relocate or preserve them.

WHY DROPPING IS THE RIGHT FIX HERE, NOT A WORKAROUND
  scripts/analysis/v7interior_label_diagnosis.py establishes, for every
  region in REGIONS below: (a) no anchor point and no per-block decode
  makes the declared labels land -- ruling out "wrong start offset"; (b)
  every label's raw ROM bytes in v7 are 96-100% different from the
  identically-named routine's bytes in v9/v10, at v9/v10's OWN address
  for that name -- inconsistent with shared-then-diverged code, and
  instead diagnostic of a v9/v10-NAME-correspondence tool that assigned
  these labels by matching size/position, never verified against v7's
  actual bytes; (c) `grep -a` (plain `grep` under-matches these latin-1
  sources -- see the diagnosis script) finds ZERO live references to any
  of these labels anywhere else in the v7 tree, with exactly ONE
  exception (see SPECIAL_CASES below). The labels are therefore simply
  wrong for v7, not a real, verifiable boundary this tool must preserve.
  Dropping an unreferenced, unverifiable label is explicitly safer than
  the alternative the lane brief warns against -- relocating a label
  without independent proof of where it belongs.

  The underlying bytes are NOT the problem: once the interior labels are
  no longer forced to land, decode+round-trip conversion (the same
  convert_code_bytes.convert_block engine every other v7 lane uses)
  succeeds on ~89% of these regions' bytes, all verified byte-exact
  through llvm-mc. Per the lane brief, "a region converted to correct,
  byte-exact, unnamed instructions... is a WIN" -- semantic labeling is
  explicitly deferred work, not required here.

SPECIAL CASE: a label that IS live must be kept, at its own address
  MidiCC_VoiceParam_8 (in the 994B midi_dispatch_handlers.s:82 region) is
  referenced 33 times as `.long MidiCC_VoiceParam_8 + 38/+59` from real
  jump tables in v7/maincpu/ui_widgets/widget_dispatch.s. It must stay at
  EXACTLY its original byte offset (854 within that region) so those
  table entries keep encoding the same address and the ROM stays byte-
  exact. Since offset 854 does not land on a clean decode boundary when
  the whole 994B span decodes as one stream, that ONE region is split
  into two independently-converted sub-spans at exactly 854 -- offset 0
  of any span trivially "lands", so the label can head the second half
  without the whole-span decode needing to agree with it.

RUN
    python3 scripts/converters/convert_v7interior_drop_wrong_labels.py           # dry run
    python3 scripts/converters/convert_v7interior_drop_wrong_labels.py --apply

Then verify the narrow gate:
    LLVM_BIN=~/compartilhado/llvm-project/build/bin
    make rebuilt_ROMs/kn5000_v7_program.llvm.rom \\
        LLVM_MC=$LLVM_BIN/llvm-mc LLVM_LLD=$LLVM_BIN/ld.lld \\
        LLVM_OBJCOPY=$LLVM_BIN/llvm-objcopy
    cmp rebuilt_ROMs/kn5000_v7_program.llvm.rom original_ROMs/kn5000_v7_program.rom

PROVENANCE
  Lane V7INTERIOR, worktree ~/compartilhado/disasm-lanes/v7interior
  (branch w10/v7interior), 2026-09-02. Applied at
  049771853caf25683c2d657e8ba0aecaff1421bd -> see
  notes/lanes/v7interior-2026-09-02.md for the full per-region report.
"""
import sys, os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import convert_interrupted_region as cir  # noqa: E402

BASE = 0xE00000
ROM = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()

# (relpath, start_line, addr, size) -- the 14 label-bearing regions.
# audio_control_engine.s:6762 (the 15th) is excluded: it auto-shrinks to
# a 2B orphan gap between real code and an already-symbolic `.long`
# pointer table, carries no label at all, and has nothing to convert.
REGIONS = [
    ("maincpu/audio/note_voice_mapping.s", 11670, 0xfee831, 222),
    ("maincpu/audio/note_voice_mapping.s", 10849, 0xfedc84, 105),
    ("maincpu/audio/note_voice_mapping.s", 9637, 0xfec786, 75),
    ("maincpu/audio/note_voice_mapping.s", 9442, 0xfec43d, 149),
    ("maincpu/audio/note_voice_mapping.s", 8871, 0xfeba64, 94),
    ("maincpu/audio/note_voice_mapping.s", 8715, 0xfeb7d1, 169),
    ("maincpu/audio/note_voice_mapping.s", 3691, 0xfe4c48, 205),
    ("maincpu/audio/note_voice_mapping.s", 3626, 0xfe4b2c, 172),
    ("maincpu/audio/sndparam_routines.s", 1163, 0xfcea6a, 749),
    ("maincpu/midi/midi_dispatch_handlers.s", 5982, 0xfd7f87, 111),
    ("maincpu/midi/midi_dispatch_handlers.s", 3985, 0xfd5551, 123),
    ("maincpu/midi/midi_dispatch_handlers.s", 82, 0xfcf905, 994),
    ("maincpu/midi/midi_serial_routines.s", 438, 0xfcf4a6, 296),
    ("maincpu/midi/midi_serial_routines.s", 168, 0xfcefc0, 204),
]

# region address -> (split offset, label name) for the one live label
# that must be preserved instead of dropped.
SPECIAL_CASES = {
    0xfcf905: (854, "MidiCC_VoiceParam_8"),
}


def convert_region(lines, start_line, addr, size):
    start_idx = start_line - 1
    true_start_idx, end_idx, labels = cir.find_span(lines, start_idx, size)
    pre_bytes = 0
    i = true_start_idx
    while i < start_idx:
        n, _ = cir.directive_size(lines[i])
        pre_bytes += n
        i += 1
    true_addr = addr - pre_bytes
    raw = list(ROM[true_addr - BASE: true_addr - BASE + size])

    special = SPECIAL_CASES.get(addr)
    if special:
        split, keep_name = special
        found = dict(labels).get(split)
        assert found == keep_name, (
            f"expected {keep_name!r} at offset {split}, found {found!r} -- "
            f"region shape changed, re-derive SPECIAL_CASES")
        nl_a, rem_a = cir.build_replacement(raw[:split], true_addr, labels=[])
        nl_b, rem_b = cir.build_replacement(
            raw[split:], true_addr + split, labels=[(0, keep_name)])
        new_lines, remaining = nl_a + nl_b, rem_a + rem_b
    else:
        new_lines, remaining = cir.build_replacement(raw, true_addr, labels=[])

    return true_start_idx, end_idx, new_lines, remaining, labels, true_addr


def main():
    apply = "--apply" in sys.argv
    by_file = {}
    for relpath, start_line, addr, size in REGIONS:
        by_file.setdefault(relpath, []).append((start_line, addr, size))

    total_converted = total_size = 0
    for relpath, specs in by_file.items():
        p = os.path.join(REPO, "v7", relpath)
        lines = open(p, encoding="latin-1").read().split("\n")
        # descending start_line: an edit only ever touches line indices
        # AFTER the edited span, so earlier (smaller-line-number,
        # not-yet-processed) regions' indices stay valid.
        for start_line, addr, size in sorted(specs, key=lambda t: -t[0]):
            tsi, ei, new_lines, remaining, labels, true_addr = convert_region(
                lines, start_line, addr, size)
            converted = size - remaining
            total_converted += converted
            total_size += size
            dropped = [n for _, n in labels if not (
                addr in SPECIAL_CASES and n == SPECIAL_CASES[addr][1])]
            print(f"{relpath}:{start_line} addr {true_addr:#x} size {size}B -> "
                  f"{converted}B converted, {remaining}B left as .byte "
                  f"(dropped: {dropped})")
            if apply:
                lines[tsi:ei] = new_lines
        if apply:
            open(p, "w", encoding="latin-1").write("\n".join(lines))
            print(f"  wrote {p}")

    print(f"\nTOTAL: {total_converted}/{total_size} B converted "
          f"({100*total_converted/total_size:.1f}%)")
    if not apply:
        print("(dry run -- pass --apply to write)")


if __name__ == "__main__":
    main()
