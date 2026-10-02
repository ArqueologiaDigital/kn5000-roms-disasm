# Source files no build assembles

`orphan_sources.py` (run: `python3 notes/orphan-sources-2026-10-02/orphan_sources.py`) walks
the `.include` graph from each top-level source.  On 2026-10-02 each maincpu tree (v10, v9,
v7) has 17 `.s` files that nothing includes; the other images have none:

* `audio/sound_data_*.s` (15): the sound-category tables.  The build compiles
  `audio/sound_data_*.c` to `includes/generated/sound_data_*.bin`, which `audio/sound_data.s`
  includes; the `.s` renderings are not assembled.
* `includes/gui_display_struct_data.s`: same story with `gui_display_struct_data.c`.
* `ui_widgets/block_007.s`: its bytes are emitted through `ui_widgets/widget_descriptors.s`
  (`.set NakaData_Block007, East_ClassTable_163 + 76`).

They are not deleted: some carry derived notes (block_007.s has nakarest headers) and that
is the owner's call.  Until then, claims in them describe nothing the build emits; the
claims review of 2026-10-02 met one (block_007.s, the class-definition tail at 0xe55a36,
which `scripts/tools/fix_unreached_naka_headers.py` therefore skips).
