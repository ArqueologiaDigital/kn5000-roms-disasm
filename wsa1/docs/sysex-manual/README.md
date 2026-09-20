# SX-WSA1R System Exclusive Reference

A byte-level reference for the Technics SX-WSA1R's System Exclusive implementation,
reconstructed from the **OS v2.0** firmware. Technics published a user guide describing the
SYSEX BULK DUMP feature and its error numbers, but no MIDI implementation chart and no
message format — everything here was read out of the program ROMs.

## Build

```sh
pdflatex manual.tex && pdflatex manual.tex     # twice, for the table of contents
```

29 pages, no external packages beyond a standard TeX Live. `gen_appendix.py` regenerates
the two appendices from `decode-findings.json`; the narrative chapters are hand-written.

```sh
./gen_appendix.py decode-findings.json         # -> appendix-evidence.tex, appendix-open.tex
```

## What it establishes

| | |
|---|---|
| accepted identifiers | `0x50` (Matsushita) and `0x7E` (Universal Non-Real Time), and only those |
| device/unit number | **none at the identifier level** — the byte after the identifier is already body |
| product id | the WSA1's own is `0x2D`; 14 third-byte values are accepted, `0x26` is not |
| bulk dump frame | `F0 50 2D 04 nn 11 a2 a1 a0 l2 l1 l0 [data] c sum F7` |
| address and length | three bytes each, base 128 |
| payload | nibble encoded, high nibble first — twice the stated length on the wire |
| checksum | `(0 - Σ) & 0x7F` over the identifier through the continuation flag |
| universal messages | GM System On/Off only; Master Volume and Identity Request are rejected |

## Two things a naive reading gets wrong

* **`MIDI_SysExHeader` (`F0 50` at `0xFA5CB8`) is a transmit template, not the identifier
  test.** No compare instruction reads it. The acceptance decision is two immediate
  comparisons in `MIDI_RX_SysExStart`. The value is the same; the evidence is not. This
  project cited it wrongly before the decode.
* **Not every bulk-dump failure is a 40/41/42 error.** Status `0x16` — incoming dump larger
  than the destination — raises **ERROR 21 "Memory full"**.

## Provenance and honesty

91 findings from a five-way decode of the disassembly at `../../prom_a`, `../../prom_b`:
81 established, 9 likely, 1 unverified. Every one is listed in the manual's evidence
appendix with the firmware symbols that establish it, and the 43 things the decode could
**not** settle are listed in the open-questions appendix rather than glossed.

`decode-findings.json` is the raw decode output, kept so the appendices can be regenerated
and so a later pass can see what was claimed and on what basis.
