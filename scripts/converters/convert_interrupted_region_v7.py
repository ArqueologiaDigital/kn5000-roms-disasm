#!/usr/bin/env python3
"""convert_interrupted_region_v7.py -- v7 single-tree adaptation of
convert_interrupted_region.py, the same way convert_region_v7.py adapted
convert_region.py.

WHY A SEPARATE FILE INSTEAD OF PARAMETERIZING THE ORIGINAL
  convert_interrupted_region.py's process() hard-codes v9+v10 in lockstep:
  it reads original_ROMs/kn5000_v9_program.rom AND kn5000_v10_program.rom,
  asserts they are byte-identical at the target address, and writes both
  v9/<relpath> and v10/<relpath> in one shot. v7 has no v9/v10-style sibling
  tree to cross-check against -- it is the ONLY copy -- so this variant reads
  and writes ONLY v7/<relpath> and kn5000_v7_program.rom, exactly the same
  single-tree narrowing convert_region_v7.py already applied to
  convert_region.py's process().

  Everything else -- find_span/rewind_to_true_start (the directive-size
  walk that locates the region's true start and end even when a `.byte` run
  is interrupted by `.ascii`/`.word`/`.long`), build_replacement (interior
  label re-insertion), and the underlying convert_code_bytes.convert_block
  decode/round-trip engine -- is REUSED, unmodified, by importing the
  original module and calling its functions directly. Only the top-level
  process() that reads/writes the tree(s) is reimplemented.

RUN
    python3 scripts/converters/convert_interrupted_region_v7.py <relpath> <start_line> <address> <size>
    python3 scripts/converters/convert_interrupted_region_v7.py <relpath> <start_line> <address> <size> --apply

⚠ A CLEAN DECODE IS NOT PROOF -- see convert_region.py's header. Corroborate
  with scripts/analysis/verify_converted_call_targets.py --tag v7 after
  applying, same as convert_region_v7.py's conversions were.

PROVENANCE
  Lane V7CODE2 of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/v7code2 (branch w6/v7code2).
"""
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_interrupted_region as cir  # noqa: E402


CONSUMED_RE = __import__('re').compile(r'consumed (\d+)/(\d+) B')


def process(relpath, start_line, address, size, apply=False, auto_shrink=True,
            min_start_line=None):
    """min_start_line (OPTIONAL, default None = previous behaviour exactly):
    refuse if rewind_to_true_start() walks the span's start ABOVE this line.

    WHY IT EXISTS, and the bug it stops.  rewind_to_true_start() walks backward
    "while the preceding line is still a recognized DATA directive (blanks and
    labels do not stop it)".  When the region ABOVE the one being converted is
    itself a raw `.byte` run, that walk crosses the intervening label and keeps
    going -- so find_span() then sums `size` bytes from the WRONG region and the
    converter rewrites the neighbour with this region's instructions.

    Caught 2026-09-02 by lane rq-codeshape on
    sequencer_engine.s:4621 `AccPedalConfig_StoreCtrl6ValsAlt` (0xF3B526, 20 B):
    its decode was written into `AccPedalConfig_StoreCtrl6Vals` (0xF3B512, 20 B)
    one region above.  The two are near-clones, so the rebuilt ROM differed by
    exactly ONE byte -- the `jrl` displacement, 0x0161 where the dump has 0x0175.
    Had the two regions been exact clones the byte gate would have stayed GREEN
    on a conversion that rewrote the wrong region.

    Pass the region's own label line to make that refusal loud."""
    p7 = REPO / 'v7' / relpath
    rom7 = (REPO / 'original_ROMs' / 'kn5000_v7_program.rom').read_bytes()
    BASE = 0xE00000
    off = address - BASE

    lines7 = p7.read_text(encoding='latin-1').split('\n')
    start_idx = start_line - 1
    if min_start_line is not None:
        t = cir.rewind_to_true_start(lines7, start_idx)
        # Only a rewind that crosses BYTE-EMITTING lines above the label is a
        # problem.  Crossing blanks, comments and the label line itself is
        # normal and harmless -- those emit nothing, and build_replacement()
        # re-inserts the label.
        stolen = 0
        for k in range(t, min_start_line - 1):
            n, _ = cir.directive_size(lines7[k])
            stolen += n or 0
        if stolen:
            raise ValueError(
                f"rewind_to_true_start walked to line {t+1}, {stolen} B above "
                f"this region's own label at line {min_start_line} -- the run "
                f"above is raw `.byte` too, so find_span would size the span "
                f"from the WRONG region; refusing")
    try:
        true7, end7, labels7 = cir.find_span(lines7, start_idx, size)
    except ValueError as e:
        # 2026-09-02 (lane V7CODE2): a census region's reported size can
        # legitimately overrun into an ALREADY-TYPED symbolic .long/.word
        # table sitting right after a raw .byte run with no intervening
        # CODE byte -- census's coarse DATA-territory map does not
        # distinguish the two (see the LITERAL_OPERAND_RE comment in
        # convert_interrupted_region.py for the two confirmed instances:
        # 0xEF97B6 and 0xEFAAB1, both in scoop_display.s). find_span()
        # now aborts exactly there instead of corrupting it. Auto-shrink to
        # the maximal SAFE prefix it proved consumable (the "consumed N/M"
        # count in its own error) rather than making the caller re-run by
        # hand for every such region -- this is strictly a NARROWING of
        # what gets touched, never a guess past a boundary the walk itself
        # did not verify.
        m = CONSUMED_RE.search(str(e))
        if not (auto_shrink and m):
            raise
        consumed = int(m.group(1))
        if consumed == 0:
            raise
        print(f"note: requested {size}B overruns into already-typed content "
              f"({e}); auto-shrinking to the verified safe prefix {consumed}B")
        size = consumed
        true7, end7, labels7 = cir.find_span(lines7, start_idx, size)

    raw7 = rom7[off:off + size]
    assert len(raw7) == size, f"short read from v7 ROM at {address:#x}"

    if true7 != start_idx:
        print(f"note: true region start is line {true7+1}, not the hinted "
              f"{start_line} (census points at the nearest .byte-kind blob, "
              f"not necessarily the region's first directive)")
    if labels7:
        print(f"note: re-inserting {len(labels7)} label(s) found in the "
              f"span: {labels7}")

    new_lines, remaining = cir.build_replacement(list(raw7), address, labels7)
    print(f"=== v7/{relpath}:{start_line}  addr {address:#x}  {size}B  "
          f"lines [{true7+1},{end7}]  ->  {size-remaining}B converted, "
          f"{remaining}B left as .byte ===")
    for nl in new_lines:
        print("   ", nl)
    if apply:
        lines7[true7:end7] = new_lines
        p7.write_text('\n'.join(lines7), encoding='latin-1')
        print(f"APPLIED to {p7}")
    # Return (actual_size_processed, remaining) rather than just `remaining`.
    # `size` here is the POSSIBLY-SHRUNK value (see the auto_shrink branch
    # above, which reassigns it to `consumed`) -- a caller that instead
    # subtracts `remaining` from the ORIGINAL worklist size silently
    # overstates the converted byte count whenever a shrink happened.
    # Confirmed 2026-09-02, lane V7REGIONS3: a 139B region auto-shrunk to a
    # 2B untouched-as-.byte prefix (0 bytes actually converted, no file
    # change at all) was tallied by run_v7_worklist_batch.py as "137B
    # converted" because it used the pre-shrink 139 instead of this 2.
    return size, remaining


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('relpath')
    ap.add_argument('start_line', type=int)
    ap.add_argument('address', type=lambda s: int(s, 0))
    ap.add_argument('size', type=int)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--no-auto-shrink', action='store_true',
                     help='fail instead of auto-shrinking to the verified '
                          'safe prefix when the requested size overruns '
                          'into already-typed symbolic data')
    a = ap.parse_args()
    process(a.relpath, a.start_line, a.address, a.size, apply=a.apply,
            auto_shrink=not a.no_auto_shrink)
