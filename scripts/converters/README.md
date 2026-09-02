
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

## `v10_widget_dispatch_ptr_entries.py`

**Question:** which of the `.byte` runs in `v10/maincpu/ui_widgets/widget_dispatch.s`
are entries of a 4-byte-strided pointer table, and can therefore be typed as
`.long` byte-exactly?

    python3 scripts/converters/v10_widget_dispatch_ptr_entries.py --dry-run
    python3 scripts/converters/v10_widget_dispatch_ptr_entries.py

The automatic rule proposes ~1.8 KB; hand review accepted 688 B in five windows
and refused the rest, and the script's header records both, with the evidence
for each window's element width. The most important refusal:
`WidgetParam_Entry_*` / `DisplayScript_Node_*` are SIX-byte `{u16 tag, u32
pointer}` records, and the tree's existing `.long AudioInit_PartConfig_CheckCarry`
at 0xEE45D0 already straddles a record boundary -- byte-exact, invisible to the
gate, and a warning against typing more of that region.

## `seq_type_data_region.py` (lane v10seq, 2026-09-02)

**Question:** this span is data, and the tree spells it as garbage mnemonics or
as an undifferentiated `.byte` soup -- what is the byte-exact typed source for
it?

It never reads the existing directives. It turns the source LINE RANGE into a
ROM ADDRESS RANGE with the linked address map, reads the bytes out of
`original_ROMs/`, and emits the requested segment types, so the replacement
cannot drift from the dump and the byte gate is a real check of the LAYOUT.

    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/converters/seq_type_data_region.py --amap /tmp/amap.json \
        --file v10/maincpu/sequencer/seq_event_playback.s --lines 943-1102 \
        --layout '256:w' --dry-run

⚠ `.word` is FOUR bytes in this assembler; 16-bit is `.short`. ⚠ The map is
keyed on line numbers, so apply several conversions to one file in DESCENDING
line order, or regenerate the map between them. It writes latin-1 through a
temp file, because `open(path,'w')` truncates before a failed encode can be
caught -- that mistake destroyed this script's own first version.
