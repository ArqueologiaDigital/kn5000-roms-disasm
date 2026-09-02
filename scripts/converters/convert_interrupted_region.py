#!/usr/bin/env python3
"""convert_interrupted_region.py -- convert a whole undisassembled DATA
region whose `.byte` run is INTERRUPTED mid-block by an `.ascii` string, a
`.word`/`.hword`/`.long` literal, or a run of several such directives --
the shape `convert_region.py` cannot handle because it stops at the first
non-`.byte` line.

QUESTION ANSWERED
  Does the region's ENTIRE byte span (pulled from the ORIGINAL ROM at its
  ROM address, not reconstructed from the directives) decode end-to-end as
  real TLCS-900 code with every instruction spellable by llvm-mc, and does
  it round-trip byte-exact? If so, replace the WHOLE source line range
  (every `.byte`/`.ascii`/`.word`/... line in the span, in one shot) with
  the decoded instructions.

WHY A SEPARATE TOOL FROM convert_region.py
  convert_region.py's parse_block() stops at the first line that is not
  `.byte`. These 12 regions (the ones v9_v10_undisassembled_census.py's
  --judge flagged as CODE-like DATA regions >= 64 B, confirmed real by hand
  audit, left unconverted by the 2026-09-01 session specifically because of
  this shape) have a short `.ascii`/`.word` directive sitting inside an
  otherwise-`.byte` span -- 4 printable bytes the census's own `inject()`
  emits as `.ascii` rather than `.byte`, or a raw pointer/`.long`. Skip only
  because of that directive is exactly the trap the lane brief calls out.

SAFETY MODEL (aborts rather than guesses)
  * Pulls the candidate bytes from `original_ROMs/kn5000_<tag>_program.rom`
    at the given absolute ROM address -- never reconstructed from `.ascii`
    escapes or existing `.byte` values, so a corrupted directive cannot
    poison the input.
  * Walks the source forward from the true start (see rewind_to_true_start),
    one line at a time, summing each DATA-directive line's emitted byte
    count (same width table as territory() in
    v9_v10_undisassembled_census.py) until the running total equals `size`
    EXACTLY. Any line that is not a recognized DATA directive (a real
    instruction, most likely) encountered before the total is reached
    ABORTS -- a region computed as pure DATA territory should never
    contain one.
  * Asserts the v9 and v10 raw ROM bytes at the given address are IDENTICAL
    before ever touching v10 -- same discipline as convert_region.py.
  * Every instruction convert_code_bytes.py emits was already verified to
    round-trip byte-exact through llvm-mc (that verification lives in
    convert_code_bytes.convert_block / verify_roundtrip, not repeated here).
  * Nothing outside [true_start_line, end_line) is touched.

⚠ LABELS ARE NOT SPECIAL-CASED, AND THAT BIT ONCE -- a label line costs 0
  bytes to directive_size(), same as a blank line, so a label sitting
  anywhere in the span (most commonly at byte offset 0, where census's own
  reporting often points a few lines PAST it) is silently DROPPED by the
  wholesale line-range replacement, with no error at apply time. It only
  surfaces if something ELSE in the tree references that label by name, as
  an `undefined symbol` at link time -- and even that is not universal, an
  unreferenced label would vanish with zero symptoms. See the README's
  post-`--apply` diff check; this tool does not (yet) do it for you.

⚠ A CLEAN DECODE IS NOT PROOF -- see convert_region.py's header. Corroborate
  with scripts/analysis/verify_converted_call_targets.py after applying.

RUN
    python3 scripts/converters/convert_interrupted_region.py <relpath> <start_line> <address> <size>
    python3 scripts/converters/convert_interrupted_region.py <relpath> <start_line> <address> <size> --apply

PROVENANCE
  Lane ISLANDS of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/islands (branch w2/islands).
"""
import sys
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_code_bytes as cb

LLVM_MC = cb.LLVM_MC

BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
# llvm-mc's tlcs900 target normalizes `.long` to `.word` in -show-encoding
# (verified: `.long 0x12345678` -> `.word 305419896`), so it is a 4-byte
# alias here, same as `.word` -- NOT the generic-GNU 2-byte/4-byte split.
WIDTH = {"byte": 1, "hword": 2, "word": 4, "long": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
LABEL_RE = re.compile(r'^[A-Za-z_.$][A-Za-z0-9_.$]*:\s*$')


def ascii_len(op):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', op))


def directive_size(line):
    """Return (bytes_emitted, is_data) for one source line, or (None, None)
    if it is an encoding (instruction) line -- checked by the caller via
    llvm-mc, this function only recognizes DATA directives and comments."""
    s = line.strip()
    if s == "" or s.startswith(";") or s.startswith("#"):
        return 0, True
    if LABEL_RE.match(s):
        return 0, True
    mm = re.match(r'\.(\w+)\s*(.*)$', s)
    if not mm:
        return None, None  # not a directive -- likely an instruction
    d, rest = mm.group(1), mm.group(2).strip()
    if d in WIDTH:
        n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
        return n, True
    if d in ("ascii", "asciz"):
        return ascii_len(rest) + (1 if d == "asciz" else 0), True
    if d in ("globl", "global", "type", "size"):
        return 0, True
    return None, None  # unrecognized directive -- do not guess


def rewind_to_true_start(lines, start_idx):
    """census's reported line is the nearest *.byte*-kind blob to the
    region's true start -- if the region's first bytes are an `.ascii` (or
    other non-.byte DATA) directive instead, the true start is a few lines
    EARLIER. Walk backward while the preceding line is still a recognized
    DATA directive (blanks/labels do not stop it, they emit 0 bytes); stop
    at the first real instruction or the top of the file. Safe because
    census's own region is defined as one MAXIMAL contiguous DATA span --
    if two `.byte` blocks were truly separate regions, a CODE byte would
    already sit between them and this walk would stop there."""
    i = start_idx
    while i > 0:
        n, is_data = directive_size(lines[i - 1])
        if n is None:
            break
        i -= 1
    return i


def find_span(lines, start_idx, size):
    """start_idx is 0-indexed and may be a few lines INTO the true region
    (see rewind_to_true_start). Returns (true_start_idx, end_idx, labels)
    such that the DATA directives from true_start_idx..end_idx-1 emit
    exactly `size` bytes, or raises with a diagnostic. `labels` is a list
    of (byte_offset, label_text) for every label line found in the span --
    a label costs 0 bytes to directive_size() so it does NOT stop the scan,
    but silently dropping it would break any other code that references it
    by name (see the module docstring's "LABELS ARE NOT SPECIAL-CASED" note
    -- this list is what lets the caller put it back)."""
    true_start = rewind_to_true_start(lines, start_idx)
    total = 0
    i = true_start
    labels = []
    while i < len(lines) and total < size:
        n, is_data = directive_size(lines[i])
        if n is None:
            raise ValueError(f"line {i+1} is not a recognized DATA directive "
                              f"({lines[i]!r}) -- aborting rather than guessing "
                              f"(consumed {total}/{size} B from true start "
                              f"line {true_start+1})")
        s = lines[i].strip()
        if n == 0 and LABEL_RE.match(s):
            labels.append((total, s[:-1]))
        total += n
        i += 1
        if total == size:
            return true_start, i, labels
    raise ValueError(f"consumed {total} B by line {i+1}, expected {size} B "
                      f"-- boundary does not land cleanly (true start line "
                      f"{true_start+1})")


def build_replacement(raw_bytes, base_pc, labels=()):
    """labels: (byte_offset, label_text) pairs, offsets relative to the
    start of raw_bytes -- each is re-emitted as its own line immediately
    before whatever new content starts at that same offset, so a label
    that used to mark a byte in the old `.byte` stream keeps marking the
    same byte in the new instruction stream instead of silently vanishing."""
    results = cb.convert_block(raw_bytes, base_pc=base_pc, verbose=False)
    pending = sorted(labels)
    new_lines = []
    undecoded = []
    def emit_labels_at(pos):
        # only labels whose offset EXACTLY matches a real segment boundary
        # -- a label that fell strictly inside what the new decode treats
        # as one instruction is a red flag (the old framing and the new one
        # disagree about where an addressable boundary is), not something
        # to place approximately.
        while pending and pending[0][0] == pos:
            _, text = pending.pop(0)
            new_lines.append(f'{text}:')
    def flush():
        if undecoded:
            hexs = ', '.join(f'0x{b:02x}' for b in undecoded)
            new_lines.append(f'\t.byte {hexs}')
            undecoded.clear()
    for mnem, off, nb in results:
        emit_labels_at(off)
        if mnem is None:
            undecoded.extend(raw_bytes[off:off + nb])
        else:
            flush()
            new_lines.append(f'\t{mnem}')
    flush()
    # a label at offset == len(raw_bytes) is a zero-width end-of-region
    # marker (legitimate: some other span's label sits right at this
    # region's tail) and belongs after everything else.
    emit_labels_at(len(raw_bytes))
    if pending:
        raise ValueError(f"label(s) {pending} do not land on any decoded "
                          f"segment boundary -- aborting rather than "
                          f"guessing where to put them")
    remaining = sum(nb for mnem, _, nb in results if mnem is None)
    return new_lines, remaining


def process(relpath, start_line, address, size, apply=False):
    p9 = REPO / 'v9' / relpath
    p10 = REPO / 'v10' / relpath
    rom9 = (REPO / 'original_ROMs' / 'kn5000_v9_program.rom').read_bytes()
    rom10 = (REPO / 'original_ROMs' / 'kn5000_v10_program.rom').read_bytes()
    BASE = 0xE00000
    off = address - BASE
    raw9 = rom9[off:off + size]
    raw10 = rom10[off:off + size]
    assert len(raw9) == size, f"short read from v9 ROM at {address:#x}"
    assert raw9 == raw10, f"v9/v10 ROM byte mismatch at {address:#x}:{size}"

    lines9 = p9.read_text(encoding='latin-1').split('\n')
    lines10 = p10.read_text(encoding='latin-1').split('\n')
    start_idx = start_line - 1
    true9, end9, labels9 = find_span(lines9, start_idx, size)
    true10, end10, labels10 = find_span(lines10, start_idx, size)
    if true9 != start_idx:
        print(f"note: true region start is line {true9+1}, not the hinted "
              f"{start_line} (census points at the nearest .byte-kind blob, "
              f"not necessarily the region's first directive)")
    # v9/v10 source line counts for this span may legitimately differ in
    # count only if their directive shapes differ; but since raw bytes are
    # identical and both source trees were built in lockstep, require an
    # identical line-count span too, as an extra guard.
    assert true9 == true10 and end9 - true9 == end10 - true10, (
        f"v9 span is lines [{true9+1},{end9}], v10 span is "
        f"[{true10+1},{end10}] -- trees have diverged here, aborting")
    assert labels9 == labels10, (
        f"v9 labels in span: {labels9}; v10 labels: {labels10} -- differ, "
        f"aborting rather than guessing which is right")
    if labels9:
        print(f"note: re-inserting {len(labels9)} label(s) found in the "
              f"span: {labels9}")

    new_lines, remaining = build_replacement(list(raw9), address, labels9)
    print(f"=== {relpath}:{start_line}  addr {address:#x}  {size}B  "
          f"lines [{true9+1},{end9}]  ->  {size-remaining}B converted, "
          f"{remaining}B left as .byte ===")
    for nl in new_lines:
        print("   ", nl)
    if apply:
        lines9[true9:end9] = new_lines
        lines10[true10:end10] = new_lines
        p9.write_text('\n'.join(lines9), encoding='latin-1')
        p10.write_text('\n'.join(lines10), encoding='latin-1')
        print(f"APPLIED to {p9} and {p10}")
    return remaining


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('relpath')
    ap.add_argument('start_line', type=int)
    ap.add_argument('address', type=lambda s: int(s, 0))
    ap.add_argument('size', type=int)
    ap.add_argument('--apply', action='store_true')
    a = ap.parse_args()
    process(a.relpath, a.start_line, a.address, a.size, apply=a.apply)
