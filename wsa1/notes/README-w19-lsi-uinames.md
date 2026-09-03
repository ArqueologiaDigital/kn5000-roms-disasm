# Wave 19 tools — lane `w19/lsi-uinames`

Two scripts, and the question each answers. Both read only
`original_ROMs/*` and no `.s` file. Run them from the `wsa1/` directory.
Findings: `notes/FINDINGS-l7a1429-parameter-names.md`.

| script | the question it answers | command |
|---|---|---|
| `notes/wsa1_toneedit_vocabulary.py` | *What does the WSA1R's tone editor call its parameters, and where do those names live?* Walks prom_b's display lists with the committed walker and prints the captions each SOUND EDIT screen actually draws, so a caption is evidence by execution and not by proximity. Also computes the two nulls the naming argument needs: what fraction of upper-case ASCII runs in prom_b are NOT inside a drawn record, and what fraction of drawn caption bytes are outside ASCII (the positive control for the image's kana and kanji faces). | `python3 notes/wsa1_toneedit_vocabulary.py` · `--nulls` · `--selftest` |
| `notes/wsa1_tone_record_probe.py` | *Is the byte the tone editor writes at record offset N really the parameter the UI calls it?* Finds prom_d's 223 melodic tone records by chaining their 17-byte names on a legal `217 + 124*N` stride, then reports the 81 element-block and 43 wave-select byte columns and two joins: element `+0x02`/`+0x03` names an entry of the 307-entry wave catalogue (392 of 392; 1.8 expected by chance), and wave-select parameters `21..30` / `31..42` are the same parameter set twice (8 of 10 against a per-pair null of 0.0166). `--sender` prints the CPU-1 message-builder bytes, the 64 resonator names and the note-name table. | `python3 notes/wsa1_tone_record_probe.py --records` · `--columns` · `--wave` · `--wavesel` · `--twins` · `--sender` · `--selftest` |

Both `--selftest` runs re-read every instruction the findings note quotes —
prom_c's two tone-edit write arms and prom_a's message builder — as bytes at
the addresses cited, and exit non-zero on any drift. Both currently report
`FAILURES: 0`.
