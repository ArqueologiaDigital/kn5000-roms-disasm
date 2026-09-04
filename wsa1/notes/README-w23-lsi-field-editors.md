# Wave 23 tool — lane `w23/dial-editors`

One script, and the question it answers. It reads only
`original_ROMs/wsa1_prom_a.ic12` and the committed
`original_ROMs/wsa1_prom_a.ic12.unidasm` (framing only, see
`original_ROMs/README-unidasm.md`); no `.s` file is an input. Run it from the
`wsa1/` directory. Findings: `notes/FINDINGS-l7a1429-field-editors.md`.

| script | the question it answers | command |
|---|---|---|
| `notes/wsa1_toneedit_field_editors.py` | *Where is the DATA-dial / value-key EDIT routine for each field of the tone editor's MODELING pages, and what are that field's limits and step?* Finds, by byte pattern, the thirty `ldb C,4 / mul / add XBC,<TABLE> / ld XBC,(XBC) / jp (XBC)` **computed-call dispatchers** in prom_a and reads each one's 17-entry table of handler pointers plus its NULL sentinel; walks every handler as a CFG over the unidasm framing with a small abstract interpreter, so a `call` yields its actual arguments; recovers the 11-byte EDIT DESCRIPTOR (`MASK`, `SHIFT`, `MAX`, `MIN`, `STEP`) that `sub_FD6CE1` consumes, whether the editor commits inline or through the shared `sub_FD7435` / `sub_FDA3E2`; and cross-checks every `(screen, RAM index, parameter)` triple against the read-back-order page map of `FINDINGS-l7a1429-editor-pages.md`. | `python3 notes/wsa1_toneedit_field_editors.py` · `--raw` · `--selftest` |

**What the signal is, and what a pass means.** Section 4 of the printed output
is a disagreement test between two independent instruments: the ORDER of a
page's read-back requests (wave 21) and the `(index, parameter)` immediates the
per-field editors carry (this wave). A pass is **33 AGREEMENTS, 0
CONTRADICTIONS, 5 declared exceptions** — and each exception prints its reason
rather than being skipped silently. `--selftest` is 58 checks and currently
reports `FAILURES: 0`.

★ **The control.** `--selftest` runs the cross-check a second time against a
page map with `MAIN FITTING` and `SUB FITTING` deliberately swapped and
requires exactly 2 clashes to appear. An agreement from an instrument that
cannot register a disagreement is not evidence.
