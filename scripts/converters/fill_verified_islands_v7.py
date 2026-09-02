#!/usr/bin/env python3
"""fill_verified_islands_v7.py -- v7 single-tree adaptation of
fill_verified_islands.py, the same narrowing convert_region_v7.py already
applied to convert_region.py.

WHY A SEPARATE FILE
  fill_verified_islands.py's main() hard-codes `tag in {v9, v10}` and its
  --apply path always tries to mirror the edit into a v9/v10 sibling file
  (`other_tag`), asserting the sibling's ROM bytes match first. v7 has no
  such sibling. This variant reuses bounds_from_context(), which does its
  own context-decode purely from `rom`/`terr` passed in (a v7 pickle load
  is precisely their inputs) and needs no v9/v10 knowledge, and
  looks_like_a_table_tail() the SAME WAY, unmodified -- the fixed-width
  DATA-record-tail trap it guards against (see that function's docstring
  for the two confirmed incidents on v9/v10) is a property of the ROM
  bytes and the calibrated CODE/DATA rule, not of which image it runs on.
  Only main()'s tree-walking and the single-tree write path are new.

RUN
    python3 scripts/converters/fill_verified_islands_v7.py --work WORKDIR \
        [--exclude-file NAME.s ...] [--start N] [--count N] [--apply] [--limit N]

  Dry run by default. --apply writes ONLY v7/<relpath>.

  --start/--count slice the CANDIDATE LIST (sorted by ROM address) BEFORE
  the expensive per-candidate unidasm classification loop runs, not after
  it like --limit does. 2026-09-02: v7's current island population is
  6,874 code-flanked byteblobs (up from the 2,268 measured before this
  session's confirmed-region conversions widened the island set -- see
  notes/lanes/ISLANDS-V7-2026-09-02.md), and classifying the whole list in
  one process before converting or committing anything already cost one
  budget its entire run with zero commits to show for it. Slice into
  batches of ~150-300, convert+gate+commit each slice, and resume with the
  next --start. The address sort makes slices stable across runs (nothing
  else in this tool's candidate selection is randomised).

PROVENANCE
  Lane V7CODE2 of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/v7code2 (branch w6/v7code2).

  Sliced batching + the near-uniform-run guard added by lane V7ISLANDS,
  worktree ~/compartilhado/disasm-lanes/v7islands (branch w7/v7islands),
  2026-09-02, after a coordinator review of the first (unsliced) run: (1)
  classifying all ~6,874 candidates before converting or committing any of
  them risks losing the whole computation if the session ends mid-run, and
  (2) no converter in this tree previously defended against a uniform or
  near-uniform byte run decoding cleanly (e.g. a run of 0xFF as repeated
  `swi 7`) -- context tiling, looks_like_a_table_tail and call-target
  corroboration all aim at OTHER failure shapes and none of them grips
  this one, because a uniform run re-encodes byte-exact and a short run
  can sit inside looks_like_a_table_tail's 150 B window dominated by real
  preceding code, diluting the periodicity signal below its threshold.
"""
import argparse
import os
import re
import sys
import tempfile
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
from convert_interrupted_region import build_replacement  # noqa: E402
from fill_verified_islands import bounds_from_context, looks_like_a_table_tail, load  # noqa: E402
import subprocess
LLVM_MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
ENCODING_RE = re.compile(r'[;#]\s*encoding:\s*\[([^\]]*)\]')


def verify_whole_span_roundtrip(new_lines, raw_bytes):
    """Assemble every emitted instruction line in ORDER and check the
    concatenated encoded bytes equal raw_bytes EXACTLY -- length included.
    build_replacement's own remaining==0 only proves no line was left as a
    .byte fallback; it does not prove the emitted instructions, decoded
    from unidasm's own instruction boundaries with no trailing context,
    actually span the WHOLE candidate (see the 2026-09-02 finding in this
    file's caller -- a short buffer's last instruction can be silently
    dropped by unidasm instead of decoded or flagged). This is the same
    check verify_roundtrip() in convert_code_bytes.py already does per
    INSTRUCTION, extended to the whole multi-instruction block."""
    insns = [l.strip() for l in new_lines if l.strip() and not l.strip().endswith(':')]
    if not insns:
        return len(raw_bytes) == 0
    try:
        out = subprocess.run([LLVM_MC, '--triple=tlcs900', '--show-encoding'],
                             input='\n'.join(insns) + '\n', capture_output=True,
                             text=True, timeout=10).stdout
    except Exception:
        return False
    got = []
    for line in out.splitlines():
        m = ENCODING_RE.search(line)
        if m:
            got.extend(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1)))
    return got == list(raw_bytes)

BASE, SIZE = 0xE00000, 2097152
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
# 2026-09-02: 192 `.byte` runs across this tree carry a trailing
# `; call SomeName (v7 addr)` comment -- a PRIOR pass already decoded these
# as absolute `call` instructions and resolved the target by name, but left
# the bytes as `.byte` (this exact regex, anchored with no trailing content
# allowed, is why: BYTE_RE alone always failed to match the line and
# collect_span silently reported "0 B collected", the same SKIP every other
# stale-line-hint case produces, with no way to tell the two apart without
# reading the line). Recognised narrowly -- ONLY the `(v7 addr)` suffix,
# never the unrelated and unexplained `(v7 patched)` annotation (380
# instances elsewhere in this tree, left alone: no note anywhere records
# why those were kept as .byte, so this tool does not guess).
#
# ⚠ 2026-09-02 FINDING: the `(v7 addr)` comment's NAME is frequently WRONG.
# Three checked by hand against symbols/maincpu_v7_symbols_reference.txt --
# `; call ApplyProgramChangeAs_Prologue2 (v7 addr)` on bytes 1d 43 df fe
# (absolute target 0xFEDF43) actually names MidiRingBuf_WriteByte
# (ApplyProgramChangeAs_Prologue2 is really at 0xFEE35D); `; call
# Audio_CheckSubsystemReady (v7 addr)` on 1d 9e d6 fd (target 0xFDD69E) --
# the real Audio_CheckSubsystemReady is at 0xFDDAB8, and 0xFDD69E has no
# symbol at all; `; call AddswbWr (v7 addr)` on 1d 53 aa fd (target
# 0xFDAA53) -- the real AddswbWr is at 0xFDAE6D. None of the three
# comments name the routine actually at the encoded address. This does NOT
# make the CONVERSION unsafe -- build_replacement decodes the raw ROM
# bytes only, never reads the comment text, and the byte gate + call-target
# corroboration both check the real thing -- but it does mean this tool
# throws the wrong comment away rather than preserving it, which is the
# right call: keeping a verified-wrong label would be worse than dropping
# it. Left as a finding for whoever generated `(v7 addr)` originally to
# investigate; not this lane's tool to fix retroactively everywhere it
# still stands unconverted.
BYTE_RE_CALL_ADDR_COMMENT = re.compile(
    r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+);\s*call\s+\S+\s*\(v7 addr\)\s*$')
# 2026-09-02, lane V7ISLANDS2: same stale-line-hint trap as BYTE_RE_CALL_ADDR_
# COMMENT above, for the RELATIVE-branch sibling annotation. 178 `.byte` runs
# tree-wide carry a trailing `; calr NAME (v7 displacement)` or `; jrl NAME
# (v7 displacement)` comment instead of `(v7 addr)` -- same prior pass, same
# reason the bytes were never converted, same silent "0 B collected" SKIP.
# Recognised the same way and just as narrowly (only this exact suffix,
# `calr` or `jrl` only); collect_span's VALUES check against the ROM is the
# actual safety net either way, so widening recognition here does not weaken
# anything -- it only lets already-safe candidates reach that check instead
# of being skipped for a comment-format reason alone.
BYTE_RE_DISP_COMMENT = re.compile(
    r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+);\s*(?:calr|jrl)\s+\S+\s*\(v7 displacement\)\s*$')


def is_near_uniform_run(raw, byte_frac=0.4, min_len=3):
    """2026-09-02: a run of a single repeated byte (or dominated by one
    byte value) can decode as a chain of identical, perfectly-spellable,
    byte-round-tripping instructions -- 0xFF repeated is `swi 7` repeated,
    and a lane elsewhere in this push found a converter about to turn 55 of
    64 B of pure padding into a fake program this exact way. Context
    tiling and looks_like_a_table_tail() do not catch it: the run re-
    encodes byte-exact (so tiling "succeeds" the same way real code does),
    and looks_like_a_table_tail's periodicity window reaches back up to
    150 B into whatever precedes the run, which for a short island is
    mostly real established CODE -- diluting a short uniform run's own
    repetition below the window-level threshold. This checks the
    candidate's OWN bytes directly, no window, no context: any run at
    least `min_len` bytes long where a single byte value accounts for
    `byte_frac` or more of it is treated as data regardless of how cleanly
    it decodes. Runs shorter than min_len are left to the other checks --
    at that length "one byte value repeats" is not yet a meaningful signal
    (e.g. a single legitimate 2-byte instruction with equal operand
    bytes).

    ⚠ 2026-09-02, lane V7ISLANDS2: hit the EXACT gap this docstring warned
    about, live -- slice [4800:5400) accepted `Rhythm_NoteRangeData:
    .byte 0x00, 0x00` (2 B, below min_len=3) as context-verified, and
    build_replacement spelled it `nop; nop`. This is the SAME shape as one
    of the four hand-reverted conversions from the immediately preceding
    session (a 2-byte zero field "below the uniform-run guard's floor",
    per notes/DEBT-INVENTORY-2026-09-02.md) -- caught here only because
    the label itself says `..._Data`, not by any byte-level check, and
    reverted by hand before commit. A 2-byte run where BOTH bytes are
    identical is now rejected outright regardless of min_len: the "single
    legitimate 2-byte instruction with equal operand bytes" counter-case
    this function was written to protect is real but rare, and the cost
    of missing a few such instructions is far lower than a second
    confirmed silent data-as-nop corruption of this precise shape."""
    if len(raw) == 2 and raw[0] == raw[1]:
        return True
    if len(raw) < min_len:
        return False
    common = Counter(raw).most_common(1)[0][1]
    return (common / len(raw)) >= byte_frac


def collect_span(lines, start_idx, size):
    """Returns (collected_byte_count, n_lines_consumed, collected_byte_VALUES).
    The values are the caller's job to check against the census blob's own
    ROM-derived bytes before writing anything -- see the 2026-09-02 finding
    in main(): a blob's recorded (start, end) ROM address and its recorded
    (file, line) can independently be WRONG for each other (a mismatch
    between index_{tag}.json, built by inject()'s pure text scan, and
    {tag}.marks.txt, built from `llvm-nm`'s symbol addresses -- root cause
    not fully chased down, but the effect is unambiguous: one committed
    instance had start/end pointing at a 16 B span 135 B away from the
    line/file it claimed, byte-identical in COUNT to the true span at that
    line but completely different in CONTENT). Matching byte COUNT alone,
    which is all this function used to report, cannot detect that -- only
    comparing the actual VALUES against the blob's own `raw` can, and nothing
    upstream of this function (bounds_from_context, looks_like_a_table_tail,
    is_near_uniform_run, verify_whole_span_roundtrip) checks this, because
    all of them work from `rom[start:end]` as ground truth and never touch
    the source file's line-based text at all until this point."""
    i = start_idx
    collected = 0
    n_lines = 0
    values = []
    while i < len(lines):
        m = (BYTE_RE.match(lines[i]) or BYTE_RE_CALL_ADDR_COMMENT.match(lines[i])
             or BYTE_RE_DISP_COMMENT.match(lines[i]))
        if not m:
            break
        vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
        values.extend(int(v, 16) for v in vals)
        collected += len(vals)
        n_lines += 1
        i += 1
        if collected == size:
            break
    return collected, n_lines, values


def find_jump_table_labels(v7_root):
    """2026-09-02 FINDING: three earlier conversions this session were
    genuine DATA, not code -- each byte-verified and gate-clean, so no
    byte-level check (context tiling, table-tail, near-uniform,
    whole-span/values round-trip) could ever have caught them. All three
    shared one shape: `lda_24 xix, (LABEL)` immediately followed by
    `jp_ind ...` -- "load this table's address, jump into a generic
    dispatcher that reads entries from it". A tree-wide scan for that
    exact shape found ~190 such labels; every one still `.byte` elsewhere
    in this tree is a real jump/dispatch table by construction. Scanning
    for it ONCE here and refusing any candidate whose immediately-
    preceding label (the line just above its first `.byte` line -- NOT
    captured by inject()'s own per-blob `labels` field, which only
    covers labels INSIDE the byte run, never the one introducing it)
    appears in this set closes the gap the byte-level checks cannot see.
    This is necessarily incomplete -- a table referenced only through a
    register-computed address, not a literal `lda_24 ..., (NAME)`, would
    not show up here -- so it raises confidence, it does not replace
    reading the diff."""
    import glob
    labels = set()
    lda_re = re.compile(r'lda(?:_24|_d16)?\s+\w+,\s*\(?([A-Za-z_][A-Za-z0-9_]*)\)?')
    for path in glob.glob(os.path.join(v7_root, '**', '*.s'), recursive=True):
        try:
            lines = open(path, encoding='latin-1').read().split('\n')
        except OSError:
            continue
        for i, line in enumerate(lines):
            m = lda_re.search(line)
            if m and i + 1 < len(lines) and 'jp_ind' in lines[i + 1]:
                labels.add(m.group(1))
    return labels


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--limit', type=int, default=None)
    ap.add_argument('--exclude-file', action='append', default=[])
    ap.add_argument('--start', type=int, default=0,
                     help='slice the candidate list (sorted by ROM address) '
                          'starting at this index, BEFORE the expensive '
                          'per-candidate unidasm classification loop -- '
                          'unlike --limit, which only trims the ALREADY-'
                          'classified accepted list.')
    ap.add_argument('--count', type=int, default=None,
                     help='classify at most this many candidates from '
                          '--start onward (default: all remaining).')
    ap.add_argument('--max-size', type=int, default=63,
                     help='exclude any candidate run LARGER than this '
                          '(default 63 = the <64 B "island" shape this '
                          'lane owns, per the 2026-09-01 brief -- v7\'s '
                          '>=64 B code-flanked runs are the CONFIRMED-'
                          'REGION shape owned by a sibling lane\'s '
                          'judge()/worklist pipeline, w7/v7regions2. '
                          'Without this cap the unbounded byteblob scan '
                          'below picks up ~876 of those too, which would '
                          'double-count / collide with that lane\'s '
                          'territory -- the same trap the census tool\'s '
                          'own --max-island flag exists to avoid.')
    a = ap.parse_args()

    terr, blobs, rom = load('v7', a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    jump_table_labels = find_jump_table_labels(str(REPO / 'v7'))
    print(f"   ({len(jump_table_labels):,} labels identified tree-wide as "
          f"lda+jp_ind jump-table targets -- candidates immediately under "
          f"one of these are refused regardless of any other check)")

    isl_all = sorted(
        (b for b in blobs if b["kind"] == "byteblob" and 0 < b["start"]
         and b["end"] < SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1
         and b["size"] <= a.max_size),
        key=lambda b: b["start"])
    isl = isl_all[a.start:a.start + a.count] if a.count else isl_all[a.start:]
    print(f"v7: {len(isl_all):,} code-flanked byteblobs total (<= {a.max_size} B, "
          f"this lane's island territory); classifying slice "
          f"[{a.start}:{a.start + len(isl)}) = {len(isl):,}")

    excluded_names = set(a.exclude_file)
    excluded_count = excluded_bytes = 0
    accepted = []
    counts = {}
    table_tail_rejects = 0
    uniform_rejects = 0
    jump_table_rejects = 0
    for b in isl:
        if os.path.basename(b["file"]) in excluded_names:
            excluded_count += 1
            excluded_bytes += b["size"]
            continue
        raw = rom[b["start"]:b["end"]]
        if is_near_uniform_run(raw):
            uniform_rejects += 1
            continue
        preceding_label = None
        p7_peek = REPO / 'v7' / b["file"]
        try:
            peek_lines = p7_peek.read_text(encoding='latin-1').split('\n')
            s0 = peek_lines[b["line"] - 2].strip() if b["line"] >= 2 else ''
            if s0.endswith(':') and not s0.startswith('.'):
                preceding_label = s0[:-1]
        except (OSError, IndexError):
            pass
        if preceding_label and preceding_label in jump_table_labels:
            jump_table_rejects += 1
            continue
        fr, ok = bounds_from_context(rom, terr, b["start"], b["end"], tmp)
        key = (fr, ok)
        counts[key] = counts.get(key, 0) + 1
        if fr == "ONE_INSN" or (fr == "MULTI" and ok):
            if looks_like_a_table_tail(rom, b["end"], tmp):
                table_tail_rejects += 1
                continue
            accepted.append(b)
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"   {k}: {v}")
    if excluded_names:
        print(f"   (skipped {excluded_count} runs / {excluded_bytes} B in "
              f"excluded files: {sorted(excluded_names)})")
    print(f"   ({uniform_rejects} rejected outright as a near-uniform byte "
          f"run -- see is_near_uniform_run, never reaches unidasm)")
    print(f"   ({jump_table_rejects} rejected because the immediately preceding "
          f"label is a known lda+jp_ind jump-table target)")
    print(f"   (of the tiling ones, {table_tail_rejects} also rejected as a "
          f"likely DATA-record tail -- see looks_like_a_table_tail)")
    print(f"=> {len(accepted):,} context-verified candidates (no reframing needed)")

    if a.limit:
        accepted = accepted[:a.limit]

    ready = []
    whole_span_rejects = 0
    for b in accepted:
        raw = rom[b["start"]:b["end"]]
        try:
            new_lines, remaining = build_replacement(list(raw), BASE + b["start"])
        except Exception:
            continue
        if remaining == 0:
            if not verify_whole_span_roundtrip(new_lines, raw):
                # 2026-09-02 FINDING: build_replacement's remaining==0 does
                # NOT guarantee the emitted instructions cover the whole
                # span -- convert_code_bytes.convert_block segments raw
                # bytes using UNIDASM's OWN instruction boundaries, run on
                # the CANDIDATE'S BYTES ALONE with no trailing context ('
                # bounds_from_context gives unidasm 24 B of lookahead;
                # convert_block gives it none). If the last instruction in
                # the span needs more bytes than remain in that short
                # buffer, unidasm can silently emit NOTHING for the tail --
                # not even a None-mnemonic placeholder -- so `results`
                # covers fewer bytes than len(raw) while still reporting
                # remaining==0 (zero UNDECODED bytes, as opposed to zero
                # MISSING bytes). Caught here on
                # maincpu/file_io/medley.s:3290 (DocMed_CheckRepeat, 16 B):
                # 4 instructions decoded totalling 14 B, 2 B of the
                # original span silently dropped -- gate failure at ROM
                # offset 1653335 traced it back to exactly this hunk. This
                # is a latent defect in the SHARED convert_code_bytes.py /
                # convert_interrupted_region.build_replacement used by
                # every conversion tool in this tree, not specific to
                # islands; scoped-fixing it here (whole-span re-assembly
                # against the ORIGINAL bytes, the same discipline
                # verify_roundtrip() already applies per-instruction) is
                # this lane's responsibility for what it emits, not a fix
                # to the shared module itself.
                whole_span_rejects += 1
                continue
            ready.append((b, new_lines))
    print(f"=> {len(ready):,} fully spellable by llvm-mc "
          f"({sum(b['size'] for b, _ in ready):,} B)")
    if whole_span_rejects:
        print(f"   ({whole_span_rejects} more rejected by verify_whole_span_roundtrip "
              f"-- build_replacement silently dropped trailing bytes)")

    if not a.apply:
        for b, nl in ready[:20]:
            print(f"   {BASE+b['start']:#08x} {b['size']}B {b['file']}:{b['line']} "
                  f"-> {'; '.join(l.strip() for l in nl)}")
        print("(dry run -- pass --apply to write)")
        return

    by_file = {}
    for b, nl in ready:
        by_file.setdefault(b["file"], []).append((b, nl))

    total_applied = 0
    for relpath, items in by_file.items():
        items.sort(key=lambda t: -t[0]["line"])  # highest line first
        p7 = REPO / 'v7' / relpath
        lines_self = p7.read_text(encoding='latin-1').split('\n')
        applied_here = 0
        for b, nl in items:
            addr, size = b["start"], b["size"]
            start_idx = b["line"] - 1
            collected, n_lines, values = collect_span(lines_self, start_idx, size)
            if collected != size:
                print(f"SKIP {relpath}:{b['line']} -- collected {collected}B, expected {size}B")
                continue
            expected_values = list(rom[b["start"]:b["end"]])
            if values != expected_values:
                # 2026-09-02 FINDING (see collect_span's docstring): the
                # blob's (start,end) ROM address and its (file,line) source
                # position can independently be WRONG for each other -- same
                # byte COUNT at this line, but DIFFERENT VALUES than what
                # the ROM actually holds at the address this blob claims.
                # Applying here would silently overwrite unrelated, correct
                # bytes with instructions decoded from a DIFFERENT address's
                # content -- caught concretely at maincpu/file_io/medley.s
                # DocMed_CheckRepeat (line 3290): blob claimed ROM address
                # 0xF93ADD (16 B), but line 3290's own bytes matched ROM
                # address 0xF93A56 instead, 135 B away -- byte gate failure
                # traced directly back to this exact mismatch. Never trust
                # byte COUNT alone; always compare the VALUES too.
                print(f"SKIP {relpath}:{b['line']} -- {size}B collected but VALUES "
                      f"mismatch the blob's own ROM address {BASE+b['start']:#x} "
                      f"(line/address desync -- see collect_span docstring)")
                continue
            end_idx = start_idx + n_lines
            lines_self[start_idx:end_idx] = nl
            total_applied += size
            applied_here += 1
        p7.write_text('\n'.join(lines_self), encoding='latin-1')
        print(f"applied {relpath}: {applied_here}/{len(items)} run(s) (v7 only)")

    print(f"TOTAL applied: {total_applied:,} B")


if __name__ == '__main__':
    main()
