# Technics SX-WSA1R — System Exclusive Reference

A byte-level reference for how the SX-WSA1R communicates over MIDI System Exclusive:
message framing, the Technics message set, the bulk-dump transfer protocol, the universal
messages it honours, and what it reports when a transfer fails.

Technics published no MIDI implementation chart for this instrument.

## Build

```sh
pdflatex wsa1r-system-exclusive-reference.tex
pdflatex wsa1r-system-exclusive-reference.tex     # twice, for the table of contents
```

16 pages. Needs only a standard TeX Live.

## Files

| file | |
|---|---|
| `wsa1r-system-exclusive-reference.tex` | the document |
| `style.tex` | page style and macros |
| `sec-overview.tex` | ports, conventions, applicability |
| `sec-framing.tex` | identifiers, termination, length limit |
| `sec-message-set.tex` | message families, model triple, short messages |
| `sec-bulk-dump.tex` | categories, data message, encoding, checksum, handshake |
| `sec-universal.tex` | what is and is not honoured |
| `sec-errors.tex` | the five screens and their causes |
| `sec-family.tex` | what the SX-KN5000 and SX-KN1500 share and do not |
| `sec-limitations.tex` | what this edition does not cover |

## Scope

The document describes the protocol, not how it was determined. The evidence behind it —
the probes that read the grammar tables, the transmit path and the status map out of the
program ROMs, and the raw decode findings — lives in `../../notes/sysex-probes/`.
