# Wave 21 tool — lane `w21/cpu1-hop`

One script, and the question it answers. It reads only
`original_ROMs/wsa1_prom_{a.ic12,b.ic13}` and no `.s` file. Run it from the
`wsa1/` directory. Findings: `notes/FINDINGS-l7a1429-editor-pages.md`.

| script | the question it answers | command |
|---|---|---|
| `notes/wsa1_toneedit_pages.py` | *Which editor page, and which field of it, does each tone-edit parameter of the 0x00104000 (L7A1429) modelling LSI belong to?* Reads prom_b's two 48-entry screen-dispatch tables and shows that code `0xC0+k` aliases `0xA0+k`; walks each MODELING page's paint routine for the display lists it runs; decodes every drawn value and fixed-pitch caption into a screen coordinate using the SED1330's own 40-byte line stride; then decodes, from prom_a's bytes, the ordered read-back run each page's ENTER routine fires and the eight `(RAM index, parameter)` pairs its per-field editors name, and compares the two. | `python3 notes/wsa1_toneedit_pages.py` · `--nulls` · `--selftest` |

**What the signal is, and what a pass means.** The page↔parameter map is read
off two things that must agree: the ORDER of a page's read-back requests (the
reply handler stores reply *n* at `((u8 *)0x27A6)[n]`) and the immediates the
per-field editors carry. Section 6 of the printed output prints one line per
editor binding; a pass is **8 of 8 AGREE**. `--selftest` is 22 checks and
currently reports `FAILURES: 0`; it also re-reads the PAGE1/3 grid (two rows at
display rows 156 and 187, five columns at x 48/88/128/160/208) and the `MAIN`
and `SUB` row labels at pixel y 152 and 183, which is the MAIN/SUB direction
argument in machine-checkable form.

`--nulls` prints three. NULL 1 sweeps the line stride 4..256 and shows the
structure alone leaves four candidates `{40, 124, 155, 248}` — the stride is
fixed by `LCD_Init_SED1330`'s SYSTEM SET bytes, not by the fit. NULL 2 shows
the MAIN/SUB row pairing has equal `+4` offsets and that the swap gives `+35`
and `-27`. NULL 3 measures how often a value record shares a display row with
its caption by chance: 5 of 5 measured, 0.19 of 5 over 100,000 random draws.

## The one source edit

`notes/w21-lsi-editor-page-renames.map` is the explicit `old=new` list for the
five page ENTER routines this lane named in `prom_a/wsa1_prom_a.s`. Pass it to
both halves of the gate:

```
python3 ../scripts/converters/sync_comments_to_renamed_labels.py \
    --map notes/w21-lsi-editor-page-renames.map --apply prom_a/wsa1_prom_a.s
python3 ../scripts/analysis/assert_comments_preserved.py --base main \
    --rename-map wsa1/notes/w21-lsi-editor-page-renames.map wsa1/prom_a/wsa1_prom_a.s
```
