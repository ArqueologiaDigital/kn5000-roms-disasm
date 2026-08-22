# Probe: llvm-mc spelling for the unidasm form `ldir`

`ldir` prints with **no operands at all**, so the printed text carries none of
the information that distinguishes the encodings. A TLCS-900 block transfer is

    0x80 + (size << 4) + ridx ,  sub-opcode

with sub-opcode `0x11` = LDIR. The `ridx` nibble is ignored by the hardware but
it *is* in the ROM, so **eight** byte pairs `80 11 … 87 11` all print `ldir`,
and eight more `90 11 … 97 11` all print `ldirw`. Across the ten binaries in
`original_ROMs/` there are 2 160 such sites, and emitting the printed text
verbatim gets the **wrong bytes at 935 of them (43.3 %)**. Counting only the
849 sites that print `ldir` — this form — it is wrong at **827 of them
(97.4 %)**: just 22 sites in all ten binaries actually hold `[80 11]`.

| script | question it answers | command |
|---|---|---|
| `verify_ldir.py` | Which of the 16 encodings has a spelling, and is it byte-exact at every site in all ten binaries? | `python3 tools/spelling-probes/verify_ldir.py` |
| `verify_ldir.py --dangerous` | Which spellings assemble and emit the WRONG bytes, and how often? | `python3 tools/spelling-probes/verify_ldir.py --dangerous` |
| `verify_ldir.py --negative` | Can this check fail? Runs the rule with the size and index nibbles swapped. | `python3 tools/spelling-probes/verify_ldir.py --negative` |
| `blocking_ldir.py` | Which `ldir` sites actually block `convert_reachable_ranges.py`, at what addresses, with what bytes? | `python3 tools/spelling-probes/blocking_ldir.py` |
| `verify_ldir_blocked_ranges.py` | Do the 6 blocked ranges convert byte-exactly once the rule is applied — every instruction, not just the `ldir`? | `python3 tools/spelling-probes/verify_ldir_blocked_ranges.py` |
| `code_or_data_ldir.py` | Of the sites with no spelling, which are real instructions? | `python3 tools/spelling-probes/code_or_data_ldir.py` |

Signal read: the raw ROM bytes at each address, taken from the file in
`original_ROMs/` at its load base (program ROMs 0xE00000, table data 0x200000,
sub-CPU boot 0xFE0000, HD-AE5000 0x280000, sub-program and custom data 0).
PASS = `llvm-mc -triple=tlcs900 --show-encoding` emits exactly those bytes.
"Assembled without error" is NOT a pass: `ldir` assembles at all 2 160 sites.

## The rule

Keyed on the RAW BYTES `b0 b1`, never on the printed text:

    80 11  ->  ldir            (this is what the printed text assembles to)
    83 11  ->  ldir83
    85 11  ->  ldir85
    93 11  ->  ldirw93
    95 11  ->  ldirw
    81 82 84 86 87 + 11  ->  NO SPELLING EXISTS  (all print `ldir`)
    90 91 92 94 96 97 + 11  ->  NO SPELLING EXISTS  (all print `ldirw`)

The same prefix rule covers the neighbouring sub-opcodes already defined:
`10` LDI (`ldi`/`ldi85`/`ldiw`), `12` LDD (`ldd`), `13` LDDR
(`lddr`/`lddr83`/`lddr85`), `15` CPIR (`cpir`/`cpir83`).

## Three traps

* **The verbatim text is wrong 43 % of the time.** `ldir` assembles cleanly to
  `[80 11]` everywhere. In the *v7 reachable ranges* every single `ldir` the
  converter meets — all ten of them — holds `[85 11]`, so the verbatim text is
  wrong at **100 %** of the sites that matter.

* **The 6 blocking instances need no backend work.** `ldir85` already exists in
  `TLCS900InstrInfo.td` and encodes byte-exactly. What is missing is the
  `(prefix, sub-opcode) -> mnemonic` map inside
  `scripts/converters/convert_corroborated_blocks.py`: `translate('ldir')`
  yields only `['ldir']`. `scripts/converters/asl_to_llvm.py` already carries the
  map (Tier 39, `BLOCK_XFER_MAP`) — the two converters disagree.

* **Every unspellable site in the program ROMs is DATA.** `8n 11` is also what
  the low half of a little-endian pointer `0x00xx11nn` looks like, so a linear
  decode invents an `ldir` in the middle of a pointer table. `code_or_data_ldir.py`
  shows the tables. Two *spellable* `[80 11]` sites (0xF15416 and 0xF15C03) are
  data too — a UI resource stream around the strings `REVERB DEPTH  :` and
  `VIBRAT0 DEPTH:` — so "it round-trips byte-exactly" would have turned a string
  table into code there. Neither is in a reachable range.

## If the unspellable encodings are ever wanted

`BlockTransferInst` already takes the index as its last template argument and
`TLCS900MCCodeEmitter.cpp` emits `0x80 + (OpSize << 4) + RegIdx`, so each one is
a one-line definition next to `LDIR85`, e.g.

    def LDIR86 : BlockTransferInst<0x11, (outs), (ins), "ldir86", "", [], 6>;

Nothing in these ROMs' code needs them: the only sites are in data.
