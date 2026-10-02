# v7 / v9 labels harmonized with v10 (2026-10-02)

`python3 scripts/renaming/harmonize_version_labels.py --to v7 --apply --report v7_from_v10.json`
(and `--to v9`), then `make gate-all` (13/13).  What it answers: which v10 labels name code
that v7 (v9) holds at a corresponding address under ANOTHER name, or under none?

Correspondence: labels defined under the same name in both linked ELFs are anchors; a v10
label between two anchors with equal v10->target deltas maps to (address - delta), and only
if the 12 ROM bytes at both addresses are identical.

| target | same name already | renamed | inserted | left: parent differs | left: both named | left: v10 name taken | left: mid-line |
|---|---:|---:|---:|---:|---:|---:|---:|
| v7 | 29,415 | 189 | 183 | 488 | 19 | 29 | 37 |
| v9 | 46,533 | 6 | 3 | 31 | 12 | 0 | 4 |

(A second v7 pass, with the new labels as anchors, found nothing more: same 29,787.)

Rules: a target name that says something is never replaced (structural names only:
`_Skip`, `_Join`, `_Helper3`, positional `_0x..`); a structural v10 name is used only when its
parent is the target's enclosing routine at that address.  "parent differs" (488 in v7) is
therefore where the two versions disagree about the ENCLOSING routine -- its name or its
start -- e.g. v7's HexCharToNibble around v10's FontGlyph_ByteData: the next thing to look
at, one parent at a time.  The reports list every row with its result.
Renames: scripts/renaming/harmonize_v7_from_v10.sed, harmonize_v9_from_v10.sed.
