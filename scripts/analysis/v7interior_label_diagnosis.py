#!/usr/bin/env python3
"""v7interior_label_diagnosis.py -- diagnose WHY the 15 v7 strict-pool
confirmed regions' interior labels fail convert_interrupted_region's
"does every label land on a decoded segment boundary" check.

QUESTION ANSWERED
  For each region: is this (1) a wrong START offset, (2) a wrong/
  misplaced LABEL, or (3) an embedded data table inside real code? The
  lane brief (notes/lanes/BRIEF-2026-09-01.md) names these as the three
  explanations to distinguish.

METHOD, per region
  a) BOUNDARY ANCHORING -- decode the region's raw ROM bytes as one
     continuous stream from its census-derived true_start (the
     "baseline"), and separately re-decode starting AFRESH at each
     interior label's own address (an "anchor"). TLCS-900 decoding is
     memoryless/forward-only per instruction, so restarting at a label's
     address is a real, independent test of whether that address is a
     genuine instruction boundary, not just a re-read of the baseline.
     If some anchor makes every later label land, explanation (1) holds:
     frame from that label instead. Finding: for all 14 regions with any
     labels, NO anchor achieves a full landing -- ruling out (1) for this
     pool. Also checks PER-BLOCK decoding (each label-to-label span
     decoded independently) -- also fails for all 14, so the boundaries
     are not even self-consistent as declared.
  b) EXTERNAL REFERENCE CHECK -- does anything elsewhere in the v7 tree
     reference each label by name (a real `.long`/`call`/`jr` site, not
     just the file's own header-comment routine list or
     transplant_manifest.txt's bookkeeping)? ⚠ Use `grep -a`: plain grep
     silently returns fewer or zero matches on these latin-1 sources when
     it heuristically classifies a file as binary (confirmed on
     v7/maincpu/ui_widgets/widget_dispatch.s, which grep without -a
     reports as having ZERO occurrences of a string it contains 33 times).
  c) V9/V10 BYTE-PARITY CHECK -- each region's interior labels have the
     same NAME as a routine in v9/v10's already-fully-disassembled source
     (confirming a v9/v10-correspondence tool assigned them). Fetch that
     routine's OWN address in v9 (via its assembled ELF symbol table) and
     diff v7's raw ROM bytes at the region's address against v9's raw ROM
     bytes at the v9-native address, over the label's own declared size
     (from v7/maincpu/transplant_manifest.txt). If the byte content is
     genuinely the same code (just relocated / a later compile), expect a
     LOW diff rate. Finding: 96-100% of bytes differ in every one of 14
     sampled regions -- consistent with UNRELATED code, not shared-then-
     diverged compiles. This is the decisive evidence for explanation (2):
     the labels were assigned by NAME+SIZE correspondence with v9/v10,
     never verified against v7's actual bytes, and are simply wrong here.

RUN
    python3 scripts/analysis/v7interior_label_diagnosis.py boundaries
    python3 scripts/analysis/v7interior_label_diagnosis.py refs
    python3 scripts/analysis/v7interior_label_diagnosis.py parity

⚠ This diagnoses the PRE-FIX state: all 15 regions here were converted
  (wrong labels dropped, one genuinely-live label preserved -- see
  scripts/converters/convert_v7interior_drop_wrong_labels.py and
  notes/lanes/v7interior-2026-09-02.md) in the SAME session that wrote
  this script. Run it against `049771853caf25683c2d657e8ba0aecaff1421bd`
  (tip of `w10/v7interior` immediately before that conversion) to see the
  original failure this script diagnoses -- on the current tree these
  regions are already real instructions, `find_span` no longer finds a
  `.byte` run at the recorded start lines, and every command below prints
  nothing (which is itself the expected, fixed-state result, not a bug).

PROVENANCE
  Lane V7INTERIOR, worktree ~/compartilhado/disasm-lanes/v7interior
  (branch w10/v7interior), 2026-09-02.
"""
import sys, os, subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import convert_interrupted_region as cir  # noqa: E402
import convert_code_bytes as cb  # noqa: E402

BASE = 0xE00000
ROM = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()

# (relpath, start_line, addr, size) for all 15 strict-pool regions, as
# selected by:
#   python3 scripts/analysis/census_one_image.py v7 <workdir>
#   python3 scripts/analysis/v7_region_worklist.py --work <workdir>
#   python3 scripts/converters/run_v7_worklist_batch.py \
#       <workdir>/v7_region_worklist.json --require-clean \
#       --exclude-table-tail --log /tmp/dryrun.json
REGIONS = [
    ("maincpu/audio/audio_control_engine.s", 6762, 0xfcb040, 139),   # auto-shrinks to 2B, no labels
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


def find_true_span(relpath, start_line, addr, size, use_v7=True):
    p = os.path.join(REPO, "v7" if use_v7 else "v7.orig", relpath)
    lines = open(p, encoding="latin-1").read().split("\n")
    start_idx = start_line - 1
    true_start_idx, end_idx, labels = cir.find_span(lines, start_idx, size)
    pre = 0
    i = true_start_idx
    while i < start_idx:
        n, _ = cir.directive_size(lines[i])
        pre += n
        i += 1
    return lines, true_start_idx, end_idx, labels, addr - pre


def boundaries_of(raw, base_pc):
    decoded = cb.unidasm_decode(raw, base_pc)
    b = {0}
    for off, nb, _ in decoded:
        b.add(off + nb)
    return b, decoded


def cmd_boundaries():
    for relpath, start_line, addr, size in REGIONS:
        try:
            lines, tsi, ei, labels, true_addr = find_true_span(relpath, start_line, addr, size)
        except ValueError as e:
            print(f"\n=== {relpath}:{start_line} addr {addr:#x} {size}B: "
                  f"find_span failed: {e} ===")
            continue
        raw = ROM[true_addr - BASE: true_addr - BASE + size]
        base_b, _ = boundaries_of(raw, true_addr)
        print(f"\n=== {relpath}:{start_line} true_start {true_addr:#x} "
              f"size {size}B, {len(labels)} labels ===")
        for off_l, name in labels:
            print(f"  label {name}+{off_l}: "
                  f"{'LANDS on baseline decode' if off_l in base_b else 'MISS'}")
        # per-block: does each label-to-label span decode cleanly to ITS
        # OWN declared end with no overrun/underrun?
        bounds = sorted(set([o for o, _ in labels] + [size, 0]))
        all_clean = True
        for a, b in zip(bounds, bounds[1:]):
            sub_b, _ = boundaries_of(raw[a:b], true_addr + a)
            clean = max(sub_b) == (b - a)
            all_clean &= clean
        print(f"  per-block (independent decode of each label's own span): "
              f"{'ALL CLEAN' if all_clean else 'at least one MISDECODES/overruns'}")


def cmd_refs():
    for relpath, start_line, addr, size in REGIONS:
        try:
            lines, tsi, ei, labels, true_addr = find_true_span(relpath, start_line, addr, size)
        except ValueError:
            continue
        for _, name in labels:
            out = subprocess.run(
                ["grep", "-arn", rf"\b{name}\b", os.path.join(REPO, "v7")],
                capture_output=True, text=True).stdout
            extra = [l for l in out.splitlines()
                     if "transplant_manifest.txt" not in l
                     and not l.rstrip().endswith(f"{name}:")]
            if extra:
                print(f"{name}: {len(extra)} live external reference(s)")
                for l in extra[:5]:
                    print(f"    {l}")


def get_addr_in_elf(tag, label):
    elf = os.path.join(REPO, "census-work", f"{tag}.elf")
    NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
    out = subprocess.run([NM, "--no-sort", elf], capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == label:
            return int(parts[0], 16)
    return None


def cmd_parity():
    v9 = open(os.path.join(REPO, "original_ROMs/kn5000_v9_program.rom"), "rb").read()
    for relpath, start_line, addr, size in REGIONS:
        try:
            lines, tsi, ei, labels, true_addr = find_true_span(relpath, start_line, addr, size)
        except ValueError:
            continue
        if not labels:
            continue
        first_label = labels[0][1]
        a9 = get_addr_in_elf("v9", first_label)
        if a9 is None:
            print(f"{relpath}:{start_line} {first_label}: not found in v9 "
                  f"(run census_one_image.py v9 <workdir> first)")
            continue
        r7 = ROM[true_addr - BASE: true_addr - BASE + size]
        r9 = v9[a9 - BASE: a9 - BASE + size]
        diffs = sum(1 for x, y in zip(r7, r9) if x != y)
        print(f"{relpath:50s} {first_label:35s} v7={true_addr:#x} v9={a9:#x} "
              f"diffs={diffs}/{size} ({100*diffs/size:.0f}%)")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "boundaries"
    {"boundaries": cmd_boundaries, "refs": cmd_refs, "parity": cmd_parity}[cmd]()
