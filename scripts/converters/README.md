
## `convert_region.py`

**Question:** does this one pre-vetted `.byte` block decode as real TLCS-900
code, and what are the instructions? Dry run by default; `--apply` writes, to
the v9 and v10 copies together after asserting their bytes match.

    python3 scripts/converters/convert_region.py <relpath> <start_line> <size>

⚠ Anchors on a 1-indexed line number, which goes stale as soon as an earlier
block in the same file is converted. The size assert is the only guard; read
the dry run before applying. ⚠ A clean decode is a candidate, not a verdict —
data decodes as plausible instructions in this ROM family, and the byte gate
cannot tell the difference. See `scripts/analysis/verify_converted_call_targets.py`
below for a check that goes beyond the byte gate.

## `convert_code_bytes.py`

**Question:** for an arbitrary `.byte` block (not just one pre-vetted region),
which bytes decode into real TLCS-900 instructions via MAME's `unidasm` +
llvm-mc round-trip verification? The engine `convert_region.py` calls.

    python3 scripts/converters/convert_code_bytes.py --file <path> [--dry-run] [--verbose]

⚠ Do not run `--all` or `--file` over a WHOLE file that mixes code and data —
confirmed 2026-09-01 on `audio_control_engine.s`, where it "converted" long
stretches of a genuine widget-data table into nonsense like `normal`, `max`,
`push 0x7f`, because those bytes happen to decode into syntactically valid,
round-trippable instructions by coincidence. `convert_region.py` exists
specifically to bound this to one pre-vetted line range. 2026-09-01 also
fixed several of its direct-address and shift/rotate mnemonics that were
never real llvm-mc syntax (`ldda8`/`ldda16`/`stda8`/`ldada` and the
register-prefix shift/rotate branch) — every one of them silently fell back
to `.byte` before the fix, with no visible symptom.

## `scripts/analysis/verify_converted_call_targets.py`

**Question:** does a region `convert_region.py` just converted actually
behave like code, independent of the byte gate (which cannot distinguish a
real routine from data that happens to decode into a closed loop of
plausible instructions — see the HD-AE5000 lane's 309 B "version string"
misread as ~35 instructions)? Checks whether the region's `call` targets
land on routines that were ALREADY named in the tree before the conversion.

    python3 scripts/analysis/verify_converted_call_targets.py --git-diff [REV [REV2]]

## `fill_verified_islands.py` / `list_ready_islands.py`

**Question:** of the census's island `.byte` runs (a run flanked by real CODE on
both sides), which can be filled touching ONLY that run — no reframing of any
neighbouring line?

    python3 scripts/converters/list_ready_islands.py v10    # dry-run work list
    python3 scripts/converters/fill_verified_islands.py     # see its own header

It decodes forward from a point *earlier in the surrounding established code*,
rather than feeding the run's bytes in isolation — an isolated decode cannot
tell a genuine short instruction from a coincidental one that happens to tile to
the exact length. ⚠ Even so, tiling is not proof that the bytes are code: a
wrong frame reproduces the same bytes and the gate cannot object. Corroborate
with call targets before converting.
