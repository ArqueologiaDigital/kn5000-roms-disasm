# tonedb lane, 2026-09-25 -- probes and instruments

Lane `tonedb` of the semantic push (`notes/lanes/BRIEF-2026-09-25-semantic.md`).
Files owned: `table_data/style_records.s`, `table_data/tone_database_*.s`.
Every number quoted in those files' headers or in this lane's commits comes out
of one of the scripts below; each exits non-zero if a checked claim stops holding.

| script | question it answers | run |
|---|---|---|
| `style_record_field_map.py` | Where does each byte of a Music Stylist record's parameter block (+0x4D..) land in the live panel, according to the three maincpu readers (`EffectMode_UpdateBitFlags` + its table `WidgetStyleDataTable_0x2A8`, `BitMapOut_ByteData_PatchTable`, `EffectMode_CopyVoiceParams`)? Do v7/v9/v10 agree? Do the census facts quoted in `style_records.s` hold over all 1000 records? | `python3 notes/tonedb-2026-09-25/style_record_field_map.py` (needs a built tree for the ELF symbols) |
| `drum_chain_probe.py` | Is our reading of a drum kit's 128 note pairs right? The instrument path (DrumKit_NoteMapA -> PercInst) and the independent name path (DrumKit_NoteMapB -> PercName_Pack, `DSP_SetVoiceCoefficients`) must name the same instrument; also every census number in the DrumKit / PercInst / drawbar headers of `tone_database_aux.s`. | `python3 notes/tonedb-2026-09-25/drum_chain_probe.py` |
| `lane_census.py` | How many bytes of the four lane files does `data_range_census.py` grade KNOWN-A / KNOWN-B / UNKNOWN / FILLER, and how many are research targets? Before/after diff of two census runs. | `python3 scripts/analysis/data_range_census.py --images tabledata --json X.json` then `python3 notes/tonedb-2026-09-25/lane_census.py before.json X.json` |
| `comments_lost.py` | Which comments did an edit drop, as a multiset (so "x1000 `; +0x4d`" is one line), and is the order of the rest preserved? Linear-time stand-in for `scripts/analysis/assert_comments_preserved.py`, whose difflib matcher did not finish in 10 minutes on `style_records.s`. | `python3 notes/tonedb-2026-09-25/comments_lost.py --base <rev> <file>` |

Rewriting tools (dry run by default, `--write` to rewrite; each checks that every
object's old and new rows spell the ROM bytes before replacing anything, and each is
idempotent):

* `scripts/tools/style_records_field_rows.py` -- the 1000 Music Stylist records;
* `scripts/tools/tonedb_aux_typed_rows.py` -- ToneEnv key maps / zone records (typed
  `ToneEnvZone4/6` rows), the drawbar zone-record blocks, the 26 drum kits (note pairs
  with the instrument each resolves to) and the 610 PercInst records (per-record
  headers naming the kit notes that play them).

The rewriting tool for the style records is `scripts/tools/style_records_field_rows.py`
(dry run by default, `--write` to rewrite; it checks every record's old and new rows
spell the ROM bytes before replacing anything, and is idempotent).

## Signals read (so the numbers keep their meaning)

* **Style-record field map.** ROM table `WidgetStyleDataTable_0x2A8` at `0xEB7BDA`
  in all three program ROMs: 6-byte entries `{u32 offset from panel base 0xF9A0,
  u8 sub-offset, u8 count}`, terminated by `u32 0xFF`.  Destination address =
  mirror `0x03C2C4` + offset + sub-offset.  A panel address is turned into
  `(tag, payload offset)` by walking the block-0 TLV record list (tag, payload
  length) from `0xF9A0`, which must end at the `FF FF` terminator `0xFD5E`.
* **PatchTable map.** Parsed from the source text of
  `BitMapOut_ByteData_PatchTable` (identical in `v10/v9/v7
  ui/bitmap_out_routines.s`): `lda xhl,(abs)` / `lda xbc,(xhl+k)` / `inc n,xhl`
  set the destination, `ld c,(xwa+p)` the source byte, `and c,M` the mask, and a
  store or `orb_erp` emits the pair.
