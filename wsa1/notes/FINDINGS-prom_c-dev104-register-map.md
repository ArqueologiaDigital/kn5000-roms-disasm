# The 0x00104000 register map, and three counts that need correcting

Wave 17, 2026-09-03, lane `w17/sound-devices`.  Everything here is re-derived from
`original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/prom_c_dev104_regmap_checks.py --selftest      # 13 sections, FAILURES: 0
python3 notes/sound/wsa1_dsp_regfile_map_checks.py --selftest #  5 sections, FAILURES: 0
```

The maps themselves live where they are used, in the file headers of
`prom_c/devices/dev10c_dev104_drivers.s` (0x00104000, the part record, the signal flow),
`prom_c/devices/dev10c_reg_writers.s` (0x0010C000, consolidated and graded) and
`dsp/dsp_channel_regs.s` (the 4 x 32 file).  This note records only the things another
lane has to adjudicate.

---

## 1. ⚠⚠ Four sites are attributed to the wrong object, and three published counts follow

`notes/prom_c_dev10c_field_sources.py --dev104` reports nineteen writes into the
0x00104000 staging struct.  **Four of them do not touch the struct at all:**

| site | what it really is |
|---|---|
| `0xFC5522` | `ld WA,(0x00e086) / extz XWA / ld (XWA+0x1c),0x01` |
| `0xFC55AF` | `ld WA,(0x00e086) / extz XWA / ld (XWA+0x1d),H` |
| `0xFC55C5` | `ld WA,(0x00e086) / extz XWA / ld (XWA+0x1e),H` |
| `0xFC5657` | `ld WA,(0x00e086) / extz XWA / ld (XWA+0x14),BC` |

All four load their base from the **absolute global `0x00E086`** — the 37-byte per-voice
record — where every real struct store loads `ld X??,(XIZ+0x08)`, the packer's only
argument.  The discriminator is the first two bytes: `d2 86 e0 00 20` against `ae 08 2x`.
Checker section 5 asserts the split both ways, including that no real struct store starts
`d2`.

**What follows, and where it is written down:**

1. `prom_c/field_accessors.s`, above `Dev104_PackStagingStruct`, and
   `notes/FINDINGS-prom_c-dev10c-producers.md` §3 say the packer writes **16 distinct
   offsets, "15 even and one (+0x1D) a high-byte write"**.  The true figure is **15
   offsets, all even**; `+0x1D` is not a struct offset at all.
2. The same correction lists `+0x06`, `+0x08`, `+0x12` and `+0x16` as fields *"not written
   by this routine's own instructions"*.  **`+0x16` is** — `0xFC51AA`,
   `ld (XBC+0x16),0xff00`, and that literal is the only value word 11 ever takes.
3. The scanner also **misses five real struct stores** in the class its own docstring
   warns about — `0xFC50D5`, `0xFC50DD`, `0xFC51AD`, `0xFC51EF` (extended-prefix immediate
   stores) and `0xFC51E6` (`and (XBC),0xff7f`, a read-modify-write).  With those added the
   packer makes **20 stores over 15 offsets**, and its two callees `sub_FC49AD` (+0x06,
   +0x08, +0x12) and `sub_FC4AED` (+0x14) supply the other four — **24 stores, 19 words,
   no word unaccounted for**.

⚠ **NOT EDITED.**  Both texts are in files this lane does not own.  Reported for
adjudication.

---

## 2. The four `sub_XXXXXX` in the sound-device files: decoded, still unnamed

`sub_FB6F2C`, `sub_FB707E`, `sub_FB7521` and `sub_FB762F` are four of the six routines
round 12 put in bucket **S3** and formally refused to name, on a rule it had calibrated
against 36 already-named accessors (`notes/prom_c_finish_round12.py --regblocks`).  That
refusal stands and this lane did not overturn it; each routine's header now carries a full
decode in the register names rounds 7 and 9 established, plus a **proposed name graded
WEAK** and the reason it was not applied.

The two that gained the most are `sub_FB7521` and `sub_FB762F`, whose headers were still
auto-generated boilerplate (*"Unknown: what the routine is FOR"*).  Both are short
per-channel sequences driven from `sub_FAC08D`'s dispatch on bits 14..12 of
`voice_record[+0x2D]`; both load register block `0x0800` — `(envelope level << 8) |
(envelope rate)` — and its companion `0x0840` from record fields `+0x39` and `+0x3B`, a
**second** pair to the `+0x18`/`+0x1A` the full writer uses, and both send `rec[+0x29]` to
register block 0.  Only `sub_FB7521` then drives the output-level gate LOW and shadows the
ungated word, which is what `Dev10C_WriteAllChanRegs` ends with.

⚠ *"A second envelope pair plus a falling gate is a note-off"* is an INFERENCE and is
flagged as one in the source.  Adopting either proposed name would need the `Calls:`
citations in `prom_c/wsa1_prom_c.s` and `prom_c/midi/midi_controllers.s` updated and
`notes/prom_c_finish_round12.py`'s `regblocks("sub_FB762F")` check re-pointed.

---

## 3. What is left UNIDENTIFIED, and what would settle it

* **Seventeen of 0x00104000's nineteen registers.**  Every row of the map says how the
  number is BUILT; only `0x0100` (a constant `0x0100` from a 251-entry table that holds
  nothing else) and `0x02C0` (the literal `0xFF00`) have a value the firmware fixes.
  ⚠ There is **no reader**: the whole image holds nine `0x00104000` literals and not one
  reads the device, and the sibling argument that named five `0x0010C000` registers is
  unavailable because the KN5000 has no counterpart device.  The open routes are the
  tone-editor UI, which must display these parameters under names, and the localisation
  strings.
* **Twelve of 0x0010C000's twenty-two**, plus the six blocks (`0x01C0`, `0x0540`, `0x0580`,
  `0x05C0`, `0x0600`, `0x0640`) that the accessor banks write and the full writer never
  stages — those six have no staged word and so no entry in the producer index at all.
* **All nine registers of the 4 x 32 file** at `0x007F0000` / `0x00E00000`.  Nothing reads
  it either; the routes are the producers of its eight data bytes (`0xFC8719`
  `DSP_WriteChans0to3_FromE29D` on CPU 2) and the schematic net names on whichever LSI
  carries its chip select.
* **Whether `srl 0x00,XIY` is a shift by 16.**  Three 0x00104000 registers (`0x01C0`,
  `0x0200`, `0x0240`) are the product of a 32-bit multiply passed through that instruction.
  The TLCS-900 encoding rule that a shift count of 0 means 16 makes them the product's
  HIGH half; if the rule were wrong they would be its LOW half.  ⚠ The toolchain is not a
  witness: `llvm-mc --arch=tlcs900` encodes `srl xiy,0` as `ed ef 00` and `srl xiy,16` as
  `ed ef 10`, passing the immediate through.  A hardware trace of one of those three
  registers would settle it in one shot.
