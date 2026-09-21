# Technics SX-WSA1R — System Exclusive Reference

**Unofficial.** Not published, endorsed or checked by Technics or Panasonic. Written by
inspecting a disassembly of the SX-WSA1R's program ROMs, operating system version 2, and
checking the result against a bulk dump captured from a real instrument.

A byte-level reference for how the SX-WSA1R communicates over MIDI System Exclusive:
message framing, the Technics message set, the bulk-dump transfer protocol, the universal
messages it honours, and what it reports when a transfer fails.

Technics *did* publish a MIDI implementation chart and a System Exclusive specification for
this instrument, in the separate **Reference Guide** (pages 34–35 and 41–56). This document
uses that guide's field names and follows its statements; it exists to cover the
instrument's *behaviour*, which the guide does not describe — what raises each error, when a
dump can be received, what the EXCLUSIVE filter actually governs, and what the rack
refuses. `../../notes/sysex-probes/manual_reference_guide.py` pins the guide by hash and
lists which page carries what.

## Build

```sh
pdflatex wsa1r-system-exclusive-reference.tex
pdflatex wsa1r-system-exclusive-reference.tex     # twice, for the table of contents
```

55 pages. Needs only a standard TeX Live.

## Files

| file | |
|---|---|
| `wsa1r-system-exclusive-reference.tex` | the document |
| `style.tex` | page style and macros |
| `sec-overview.tex` | ports, conventions, applicability |
| `sec-glance.tex` | the one-page summary card |
| `sec-framing.tex` | identifiers, termination, length limit |
| `sec-message-set.tex` | message families, model triple, short messages |
| `sec-bulk-dump.tex` | categories, data message, encoding, checksum, handshake |
| `sec-universal.tex` | what is and is not honoured |
| `sec-errors.tex` | the five screens and their causes |
| `sec-blocks.tex` | block signatures and where the names are |
| `tbl-signatures.tex` | **generated** — the block signatures, from a real dump |
| `sec-settings.tex` | the EXCLUSIVE filter, which sockets carry what, memory protect |
| `sec-parameters.tex` | the 2B/2C parameter address space |
| `sec-sound.tex` | the NORMAL SOUND and DRUM SOUND areas |
| `sec-effects.tex` | the 56 effects and their VALUE bytes |
| `tbl-effects.tex` | **generated** — the effect catalogue |
| `sec-enums.tex` | control functions and filter values |
| `tbl-sound.tex` | **generated** — the sound parameter tables |
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

`tbl-signatures.tex` and `tbl-examples.tex` are generated the same way:

```sh
python3 ../../notes/sysex-probes/sysex_block_signatures.py --tex tbl-signatures.tex
python3 ../../notes/sysex-probes/sysex_sound_layout.py --tex tbl-sound.tex
python3 ../../notes/sysex-probes/sysex_effects.py --tex tbl-effects.tex
```


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
