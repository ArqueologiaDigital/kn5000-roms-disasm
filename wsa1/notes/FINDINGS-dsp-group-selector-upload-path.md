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

## In-emulator test (2026-09-08, WSA1R_ENABLE_DSP=1 build, I-RAM/C-RAM write-taps)

I rebuilt the DSP-instantiated emulator and drove both paths under a write-tap that counts
every I-RAM and C-RAM write event (so an identical re-upload is visible), with a handshake
confirming each trigger landed. Rigs: `wsa1_dsp_group_toggle.lua` (state diff),
`wsa1_dsp_group_writetap.lua`, `wsa1_dsp_group_writetap2.lua` (handshake + write count).

| trigger | I-RAM writes | C-RAM writes | notes |
|---|---|---|---|
| **boot** | **630** to IC30, **words 48..110** (= load 0x30..0x6E, the 63-word kernel) | IC6 108, IC5 59 | the kernel upload |
| effect change (unit 0/2) | **0** | 0–2 coeffs | landed=true; coefficient-only |
| **group toggle** (`0xF361`+`0x7ECC.0`) | **0** (every run) | 0–12 coeffs | see caveat |

- The **only I-RAM upload ever observed is the boot kernel** (words 48..110). **No trigger
  produced a single further I-RAM write** — in particular nothing was written above word 110
  (where the +12 bodies would land). So no body upload was observed in the emulator.
- ⚠ **CORRECTION of this note's first draft:** I earlier wrote that a group change "re-issues
  command-01 I-RAM loads (0x30 stream 0xFCD2C6)" and called "boot-kernel-only" *refuted*.
  That was inferred from static control flow and is **NOT supported by measurement** — the
  write-tap shows **zero** I-RAM writes on a group toggle. Retracted.
- ⚠ **But my triggering is not airtight, so this does not refute Felipe either.** The RAM-poke
  of command 0x80 is **timing-sensitive**: `0xF35D` tracked `0xF361` in one run but in another
  the group step showed `landed=false` (F35D never flipped) while still causing 12 C-RAM
  writes. So the group *resolve/reload* was not reliably driven by the poke, and I have **not**
  cleanly exercised `P7Units_ReloadForGroup`. An opcode-fetch exec-tap to confirm it runs
  failed (TLCS-900 fetches bypass program-space read taps).

## Status / honest grading

- **CONFIRMED (static):** command **0x80/0x88** (group select, writes `0xF361`, sets
  `0x7ECC.0`) is a real link sub-command the effect sweep (0x81/82/83) never issued — Felipe
  is right that the trigger space was not exhausted. The 57 command-01 loads at 0x6E (the
  bodies) and the `P7Stream_Run` op-3 arm (`0xF9AAFB`) are real.
- **MEASURED (emulator):** across effect-change and group-select triggers, **no I-RAM body
  upload occurs**; only the boot kernel is ever written to I-RAM. Effect/group changes write
  C-RAM coefficients only.
- **OPEN / needs a better instrument:** whether a *faithfully-delivered* command 0x80 (via
  the real link channel, not a RAM poke) drives `P7Units_ReloadForGroup` to emit I-RAM — and
  whether any path feeds `PoolDir_Records[idx]+12` to the op-3 arm. Settling it needs either
  real link-command injection or hardware (unreachable). I did **not** find a body-upload
  trigger; I did find that the trigger space is larger than the prior sweep exercised.

Builds on [[wsa1r-dsp-runtime-effects]]; refines `FINDINGS-dsp-runtime-effect-uploads.md`
(which stands: effect selection is coefficient-driven).
