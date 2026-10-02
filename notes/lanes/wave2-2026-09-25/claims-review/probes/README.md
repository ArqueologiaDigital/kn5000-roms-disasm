# Claims-review probes

| script | question it answers | run |
|---|---|---|
| `unreached_naka_spans.py` | What are the spans the nakarest headers call "purpose not established ... that no registered NAKA table ... points into"?  Classifies each against the registered tables (class-definition tail, table end marker, record tail) or prints its bytes. | `make all; python3 notes/lanes/wave2-2026-09-25/claims-review/probes/unreached_naka_spans.py v10` |

The fix itself is `scripts/tools/fix_unreached_naka_headers.py` (same classification, plus
merging table continuations and retiring `EmbeddedPtrTable_*` labels).

Results on 2026-10-02, once `scripts/analysis/nakarest_objtab_map.py` saw the registrations
again (it had parsed 0 since the event-constant pass spelled the classes `NAKA_CLASS_*`):

| tree | spans | class-def tail | end marker | merged into the table above | pointer-table tail | split since | left |
|---|---|---|---|---|---|---|---|
| v10 | 22 | 4 (+1 in block_007.s, not assembled) | 11 | 4 | 2 | 0 | 0 |
| v9  | 22 | 4 (+1) | 11 | 4 | 2 | 0 | 0 |
| v7  | 42 | 4 (+1) | 11 | 4 | 2 | 19 | 1 (0xeb78ff, 51 B) |

End markers, measured over v10's 496 registered non-Class tables: every Viewable (209),
ResEvent (10), ResMethod (10) and function code table (29) is followed by a zero word; every
ResName (209) and function name table (29) by a pointer to an empty string right after it.
No table ends otherwise.
