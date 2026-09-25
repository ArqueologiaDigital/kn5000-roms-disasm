# Lane `hdae`, semantic push 2026-09-25 -- tools and evidence

Every number this lane quotes in a commit message or source header was produced
by one of the scripts below.  Each answers one question; run from the repo root
after any build of `rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom` (the generated image
blobs must exist).

| script | question it answers | command |
|---|---|---|
| `scripts/analysis/hdae5000_line_map.py` | which hdae5000 source line emits the byte at address X (and at what address does line N assemble)? The mirror it links is asserted byte-identical to the dump, so the map describes the tree it was run on. | `python3 scripts/analysis/hdae5000_line_map.py 0x2974DD 0x297500` or `--dump OUT.tsv` |
| `scripts/converters/symbolize_abs24_cc_branches.py` | converts the numeric `jp/call cc, (N:24)` operands that `symbolize_numeric_branches.py` skips ("skip_conditional_abs"; its regex does not accept the `(N:24)` spelling). Guards: ROM encoding F2 <addr24> Dx/Ex matches, unidasm agrees, target is the first byte of an instruction line. Dry run prints the counts; `--apply` rewrites and re-links through the line-map tool (refuses unless byte-identical). | `python3 scripts/converters/symbolize_abs24_cc_branches.py [--apply]` |
| `scripts/renaming/sed_to_rename_map.py` | the `old=new` map a `scripts/renaming/*.sed` performs, for `assert_comments_preserved.py --rename-map` | `python3 scripts/renaming/sed_to_rename_map.py X.sed > X.map` |
| `scripts/generators/gen_hdae5000_ui_pool.py` | writes the 769 typed records of the UI object descriptor pool (0x29DC12-0x2A5D2B) and the symbolic `HDAE5000_UiObject_PtrTable`; refuses unless its byte model of the generated text equals the ROM, and the layout facts it relies on still hold. Idempotent on its own output. | `python3 scripts/generators/gen_hdae5000_ui_pool.py [--write]` |
