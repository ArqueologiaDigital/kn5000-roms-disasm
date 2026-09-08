# The WSA1R DSP body-upload path exists — behind the untriggered GROUP-SELECT command

**Date 2026-09-08.** Correcting an over-strong prior claim. The earlier note
(`FINDINGS-dsp-runtime-effect-uploads.md`) concluded that at runtime the WSA1R uploads
only the boot kernel and never re-programs I-RAM per effect. Felipe challenged this
("I think you merely were still unable to trigger the submission of other DSP programs").
He is right: the prior sweep exercised only **one** of the link handler's sub-commands.

## What the prior sweep actually drove — and what it missed

`Link_Ch1_WriteParamBlock` (`prom_c/link/link_key_events.s`, dispatch `command − 0x80`,
16-entry table) has these arms:

| command | writes | change flag | meaning |
|---|---|---|---|
| **0x80 / 0x88** | **`(0xF361) = payload[0]`** | **`0x7ECC` bit 0** | **stream GROUP selector** |
| 0x81 | `0x7E7E`, `(0x7E97)=1` | `0x7ECC` bit 1 | effect PROGRAM, unit 0 |
| 0x82 | `0x7E98`, `(0x7EB1)=1` | `0x7ECC` bit 2 | effect PROGRAM, unit 1 |
| 0x83 | `0x7EB2`, `(0x7ECB)=1` | `0x7ECC` bit 3 | effect PROGRAM, unit 2 |

The sweep rig (`wsa1_dsp_effect_sweep.lua`) drove **0x81/0x82/0x83 only** — it writes the
twin program byte and sets `0x7ECC` bit `1<<(unit+1)`. **It never issued 0x80/0x88**, so
`0xF361` was never changed and the group-reload path never ran. The prior note's aside
that I-RAM was byte-identical "across every group reload" was therefore unsupported: no
group reload was ever triggered.

## The path the group-select command reaches (static, prom_c)

`0x7ECC` bit 0 makes `P7Units_ResolveProgramsAndReload` (`p7/p7_module.s`) copy
**`0xF361 → 0xF35D`** (the group selector, clamped to {0,1}, `0xFA5709`/`0xFA5715`), and if
`0xF35D` differs from its shadow `0xF35E` it calls **`P7Units_ReloadForGroup` (0xFA3802)**.
That handler is a *much heavier* reload than the per-effect path:

- it re-runs `P7Unit_LoadProgramStreams` for **all three units** (coefficient blocks +0/+8), and
- it issues a series of `P7Stream_Run` (`0xF9A646`) calls over canned streams, **including
  `0xFCD2C6`** — which is `dsp/disasm/struct_30_fcd2c6.dsm`, a **command-0x01 I-RAM LOAD at
  address 0x30**.

So a group change **does emit I-RAM program loads at runtime** (to 0x30 at minimum) — a path
the effect sweep never exercised. "Only the boot kernel is ever uploaded" is refuted.

## The bodies are real command-0x01 loads, and they target 0x6E

The static pool (`prom_c/p7/p7_stream_pool.s`) contains, by command header
(`01 UU AA`, AA = load address):

    unit0 load 0x30 ×6   0x34 ×2   0x3D ×2   0x60 ×2   **0x6E ×57**   |   unit1 load 0x60 ×260

The **57 command-01 loads at 0x6E** are exactly the per-effect I-RAM bodies
(`PoolDir_Records` field +12, the op-3 stream; `gen_wsa1_dsp_disasm.py`). Command 0x01 is
the same "open/load" the boot kernel uses (`01 00 30`). The op-3 arm that emits them lives
in `P7Stream_Run` at `0xF9AAFB`. So the machinery to upload the 0x6E bodies is present and
opcode-framed; the open question is only which caller feeds `PoolDir_Records[idx]+12` to it
— the per-effect path feeds +0/+8, and the group path feeds a fixed table (0xFCD2C6 …),
so the exact trigger for the +12 body is still being pinned.

## Status / honest grading

- **REFUTED (static, decisive):** "runtime uploads only the boot kernel, never re-programs
  I-RAM." A group change (command 0x80) runs `P7Units_ReloadForGroup`, which re-issues
  command-01 I-RAM loads (0x30 stream `0xFCD2C6`). The prior sweep never triggered it.
- **OPEN (to confirm in-emulator):** whether a group change (or a group change combined
  with an effect select) also emits the 0x6E **bodies**. Experiment: on the
  `WSA1R_ENABLE_DSP=1` build, poke `0xF361` to the opposite of its current value and set
  `0x7ECC` bit 0 (mimicking command 0x80, exactly as the sweep mimics 0x81/82/83), then diff
  each DSP's I-RAM. Rig: `wsa1_dsp_group_toggle.lua` (this session).

Builds on [[wsa1r-dsp-runtime-effects]]; corrects `FINDINGS-dsp-runtime-effect-uploads.md`.
