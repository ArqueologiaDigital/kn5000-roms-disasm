# The committed MAME `unidasm` listings

`*.unidasm` beside each ROM is a reference disassembly produced by MAME's
`unidasm`, committed for the same reason `../../original_ROMs/*.unidasm` are in
the sibling tree: **it is the framing authority**. When a tool asks "is this
byte string one instruction, and which one?", the answer comes from here and not
from the LLVM backend's `--disassemble`, which refuses most extended forms and
mis-decodes some of the rest.

Regenerate with (`unidasm` is `../../../tools/unidasm`, a MAME build):

```
unidasm wsa1_prom_a.ic12 -arch tlcs900 -basepc 0xF80000 > wsa1_prom_a.ic12.unidasm
unidasm wsa1_prom_b.ic13 -arch tlcs900 -basepc 0xF00000 > wsa1_prom_b.ic13.unidasm
unidasm wsa1_prom_c.ic28 -arch tlcs900 -basepc 0xF80000 > wsa1_prom_c.ic28.unidasm
```

The base addresses are the ones each image's linker script establishes and
argues for — `prom_a/prom_a.ld`, `prom_b/prom_b.ld`, `prom_c/prom_c.ld`.

## What a listing does and does not certify

* **It is a LINEAR decode from the base.** Where it starts a run inside data, or
  half an instruction late, every line after it is misframed until it resyncs.
  So a listing line at address X is **not** evidence that X is an instruction.
* **What it does certify is a BYTE STRING.** TLCS-900 decoding is context-free,
  so "these N bytes decode as exactly one instruction, rendered R" is a property
  of the bytes alone, and holds wherever in the listing those bytes were met.
  That is the only way `../notes/sound/wsa1_unspellable_forms.py` reads it: it
  builds `{byte string: rendering}` and looks byte strings up.
* **`db` is not an instruction.** It is unidasm's marker for bytes it cannot
  decode, and it consumes bytes like a mnemonic does — `f8add8: 80 0f  db`.
  Anything reading these files has to reject it explicitly.

## Why prom_d has none

`wsa1_prom_d.bin` is a data image linked at ORIGIN 0 (see `../prom_d/prom_d.ld`
for the whole argument). It holds no instructions, so a linear decode of it
would be 12 MB of noise with nothing to certify.
