# Lane `hdae`, semantic push 2026-09-25 -- tools and evidence

Every number this lane quotes in a commit message or source header was produced
by one of the scripts below.  Each answers one question; run from the repo root
after any build of `rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom` (the generated image
blobs must exist).

| script | question it answers | command |
|---|---|---|
| `scripts/analysis/hdae5000_line_map.py` | which hdae5000 source line emits the byte at address X (and at what address does line N assemble)? The mirror it links is asserted byte-identical to the dump, so the map describes the tree it was run on. | `python3 scripts/analysis/hdae5000_line_map.py 0x2974DD 0x297500` or `--dump OUT.tsv` |
