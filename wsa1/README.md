# Technics SX-WSA1R ROM disassembly

Sibling of `../kn5000-roms-disasm`, same practices.

## What certifies this tree

**Only one thing: reassembling the sources reproduces the original ROMs byte for byte.**

    python3 scripts/analysis/assert_byte_identical.py

That script rebuilds first and compares bytes. Do not substitute a similarity
percentage, and do not run it with `--no-build` unless you have just built --
both shortcuts have already cost the sibling tree real retractions, and the
reasons are written into the script's docstring.

Every commit must keep the gate green, and every commit message must carry the
`LLVM: <branch>@<short> (<full>)` line (enforced by `.githooks/commit-msg`).

## The four images

| source | file | base | status |
|---|---|---|---|
| `prom_a/` | `wsa1_prom_a.ic12` | `0xF80000` **established** | program, boot image of CPU 1 |
| `prom_b/` | `wsa1_prom_b.ic13` | `0xF00000` **confirmed** | program, low half of the same 1 MiB image |
| `prom_c/` | `wsa1_prom_c.ic28` | `0xF80000` **established** | program, boot image of CPU 2 |
| `prom_d/` | `wsa1_prom_d.bin` | `0x00F00000` (CPU 2) | the tone database; data only |

## The sources that are not images

| source | included by | contents |
|---|---|---|
| `kernel/kernel.s` | `prom_a` **and** `prom_c` | the multitasking kernel both CPUs run |
| `kernel/kernel_maincpu.inc` | `prom_a` | the 21 values that are CPU 1's |
| `kernel/kernel_subcpu.inc` | `prom_c` | the same 21 values for CPU 2 |
| `dsp/dsp_channel_regs.s` | `prom_a` **and** `prom_c` | the DSP channel-register driver both CPUs run |
| `dsp/dsp_channel_regs_maincpu.inc` | `prom_a` | the ONE value that is CPU 1's |
| `dsp/dsp_channel_regs_subcpu.inc` | `prom_c` | the same one value for CPU 2 |

The two processors run **the same 2,180-byte kernel**, at `0xF85606` on CPU 1 and
`0xF9816B` on CPU 2 — every pair of addresses differing by exactly `0x12B65`. It
is written once. Everything that genuinely differs between the two copies is a
`.equ` in one of the two `.inc` files: a stack top, two low-RAM cells, nine array
bases and their sizes, and three ROM pointers.

★ **The byte gate is what makes that a proof.** One source assembling to bytes
identical to *both* EPROMs is not a claim that two listings look alike; if a
single equate were wrong, both images would stop rebuilding.

    python3 notes/kernel_join_probe.py --pairs     # how the two blocks compare
    python3 notes/kernel_join_probe.py --symbols   # the 21 values, per CPU
    python3 notes/kernel_join_probe.py --selftest  # + proves the merge lost nothing
    python3 notes/kernel_join_probe.py --metrics   # header/label figures, before and after
    python3 notes/kernel_join_probe.py --reachability  # coverage tool's inputs, before and after

### And the same thing again, at 234 bytes

The two processors also run **the same DSP channel-register driver**, at
`0xF85F0F` on CPU 1 and `0xF98000` on CPU 2 — every pair of addresses differing
by exactly `0x120F1`. 231 of its 234 bytes are the same byte in the two EPROMs,
and the three that differ are A23..A16 of the register file's address, `0x7F`
against `0xE0`. So there is exactly **one** per-CPU value in the whole driver,
`DSP_REGS_BASE`, used at three sites — and no `.if` anywhere, as in the kernel.

    python3 notes/sound/wsa1_dsp_join_probe.py           # 231 of 234, from the ROMs alone
    python3 notes/sound/wsa1_dsp_join_probe.py --pairs   # the 97 instruction pairs
    python3 notes/sound/wsa1_dsp_join_probe.py --verify  # + proves the merge lost nothing
    python3 notes/sound/wsa1_dsp_join_probe.py --images  # what each image's text gained

⚠ Its lines carry **both** images' addresses — `; F85788/F982ED` — which is a
line shape no `prom_*.s` file uses. **Any tool that scans a source by address has
to be told about it**, or it silently measures a tree with no kernel in it. These
already know: `notes/reachability.py`, `notes/wave7_documentation_metrics.py`,
`notes/prom_a_byte_checks.py`, `notes/kernel_shared_source_probe.py`,
`notes/kernel_three_way.py`, `scripts/analysis/source_coverage.py`. Older
round-specific probes under `notes/` do not, and read the two images as if the
kernel were absent.

Base addresses for A and C: 33 of 64 words at file offset `0x7FF00` point into
`0xF00000-0xFFFFFF`, which is where a TMP95C061 fetches its reset PC
(`0xFFFF00`), and both reset words land on real boot blocks — now converted to
assembly. B lands 3 of 64 there and D lands 0, so neither is a boot image.
Evidence: `../technics_roms/tools/wsa1_rom_anatomy.py`.

**B's base is no longer inferred.** Four independent proofs — prom_a's vectors,
its reset path's jump, a PC-relative call across the boundary, and the
expansion-board probe's thunk — all land on well-formed code at exactly
`0xF00000`, and none survives a one-byte error in it. Written out in
`prom_b/prom_b.ld`.

**D's base IS established: `0x00F00000` on CPU 2's bus.** ⚠ This paragraph used to
read "still not established" and named the 512 KiB flash at `0xE80000` as the
leading hypothesis. **Both were refuted in wave 7 round 3** and the text simply
outlived the finding. What establishes the base, two independent ways:

* `prom_c` installs `0x00F00000` in RAM `0x00D7ED`/`0x00D7F1` (the only two
  instructions in `prom_c` that write either address, so it is a compile-time
  constant at every use), then reads this image's 48-slot directory through it at
  99 instruction pairs covering 33 slots.
* independently, `prom_a` `0xF82A5F` `ld XWA,0x00F7FFF0` reads eleven bytes that
  are this image's build tag at file `0x7FFF0`, `"wsad_54.ssf"`. The difference is
  `0x00F00000`. Two processors, two routes, one base.

The flash reading is refuted outright: `prom_c`'s own `Flash_SectorErase` bounds
that part at `0x00E80000..0x00EFFFFF`, *below* this image, and
`ExtBoard_ProbeAndInstallBases` installs the two addresses in **separate** slots.
Checked by `notes/prom_d_base_checks.py` (12 checks) and written into
`prom_d/prom_d.ld` and `prom_d/wsa1_prom_d.s`'s header.

## Provenance of the images

These are **not chip reads**. They are the publicly redistributed v2 firmware
set; see `../technics_roms/roms/wsa1/PROVENANCE.md`. That does not affect the
byte-match discipline here -- the bytes are what they are -- but it must not be
misreported downstream.

## Status

**Converted: 1,922,183 of 2,097,152 bytes (91.7%)** -- of which 1,501,152 substantive (71.6%) and 421,031 verified filler.

| source | image | substantive | filler | still `.incbin` | `.incbin` spans |
|---|---|---:|---:|---:|---:|
| `prom_a/` | `wsa1_prom_a.ic12` | 419,726 | 48,437 | 56,125 | 10 |
| `prom_b/` | `wsa1_prom_b.ic13` | 355,833 | 49,611 | 118,844 | 122 |
| `prom_c/` | `wsa1_prom_c.ic28` | 395,072 | 129,216 | 0 | 0 |
| `prom_d/` | `wsa1_prom_d.bin` | 330,521 | 193,767 | 0 | 0 |

⚠ **Quote the substantive column, not the total.** Wave 3 converted 123,151 bytes of prom_c of
which 118,298 were a verified run of 0x0E pad emitted as `.fill` -- that moved the headline from
4.3% to 27.7% while adding under 5 KB of decoded content. The pad is real and checked rather than
sampled, so it belongs in the source, but a number that treats it as equal to decoded code
flatters. Regenerate with `python3 scripts/analysis/source_coverage.py`; never retype it.

The gate is green at every commit; see the top of this file. Conversion is incremental and
reachability-driven, not linear, so a low percentage on an image does not mean nothing is
known about it -- `notes/` carries the structural findings.

⚠ This section was stale for one commit (it still claimed 4,639 bytes and "prom_b and
prom_d are still one .incbin each" after four agents had converted 604,523 bytes). Three of
the four lanes noticed and none edited it, because it was outside every lane. Hence the
script: the number is now derived from the sources, not maintained by hand.
