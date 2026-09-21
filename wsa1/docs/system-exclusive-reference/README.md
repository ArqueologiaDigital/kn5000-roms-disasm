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

30 pages. Needs only a standard TeX Live.

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
| `sec-blocks.tex` | block signatures and where the names are |
| `sec-settings.tex` | the EXCLUSIVE filter, which sockets carry what, memory protect |
| `sec-parameters.tex` | the 2B/2C parameter address space |
| `tbl-parameters.tex` | **generated** — the 108-parameter tables |
| `sec-models.tex` | the two features the rack does not support |
| `sec-family.tex` | what the SX-KN5000 and SX-KN1500 share and do not |
| `sec-examples.tex` | worked messages, byte by byte |
| `tbl-examples.tex` | **generated** — the example bytes |
| `sec-limitations.tex` | what this edition does not cover |

## Regenerating the parameter tables

`tbl-parameters.tex` is written by a probe and must not be edited by hand:

```sh
python3 ../../notes/sysex-probes/sysex_param_table_tex.py tbl-parameters.tex
```

`tbl-examples.tex` is generated the same way:

```sh
python3 ../../notes/sysex-probes/sysex_examples_tex.py tbl-examples.tex
```

It reads the addresses from `sysex_param_addresses.py` and the names from
`param_names.json`, so a name added to that file, or a change in the decode, reaches the
document by rerunning the command. The script fails if a name no longer matches a
parameter.

## Scope

The document describes the protocol, not how it was determined. The evidence behind it —
the probes that read the grammar tables, the transmit path and the status map out of the
program ROMs, and the raw decode findings — lives in `../../notes/sysex-probes/`.
