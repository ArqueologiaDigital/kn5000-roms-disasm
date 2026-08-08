# Retired orphan binaries (2026-08-08, Wave 5 `w5-orphans`)

Every file listed here was tracked in git, participated in **no** build,
and was named by **no** `.s`, `.asm`, Makefile rule or script.  Each was
also a **byte-exact slice of a tracked original ROM**, so retiring it
destroyed no information: the `dd` in the last column reproduces it
byte-for-byte.  Sizes and offsets were re-verified at deletion time.

Run the `dd` from the repository root; it writes the file into the
current directory, so move it to the path in column 1 afterwards.

| file | bytes | source ROM | CPU address | regenerate |
|---|---:|---|---|---|
| `table_data/includes/bootcode_debug.bin` | 96 | `kn5000_table_data.rom` | 0x9FFE80 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FFE80)) count=96 of=bootcode_debug.bin` |
| `table_data/includes/bootcode_division.bin` | 207 | `kn5000_table_data.rom` | 0x9FFC0E | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FFC0E)) count=207 of=bootcode_division.bin` |
| `table_data/includes/bootcode_free2.bin` | 259 | `kn5000_table_data.rom` | 0x9FFD7D | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FFD7D)) count=259 of=bootcode_free2.bin` |
| `table_data/includes/bootcode_interrupts.bin` | 5187 | `kn5000_table_data.rom` | 0x9FEA9D | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FEA9D)) count=5187 of=bootcode_interrupts.bin` |
| `table_data/includes/bootcode_post_clearram.bin` | 18158 | `kn5000_table_data.rom` | 0x9FB7F2 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FB7F2)) count=18158 of=bootcode_post_clearram.bin` |
| `table_data/includes/bootcode_pre_clearram.bin` | 55 | `kn5000_table_data.rom` | 0x9FB709 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FB709)) count=55 of=bootcode_pre_clearram.bin` |
| `table_data/includes/bootcode_pre_lzss.bin` | 4304 | `kn5000_table_data.rom` | 0x9FB7F2 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FB7F2)) count=4304 of=bootcode_pre_lzss.bin` |
| `table_data/includes/lzss_routines.bin` | 872 | `kn5000_table_data.rom` | 0x9FC8C2 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FC8C2)) count=872 of=lzss_routines.bin` |
| `hdae5000/includes/code_280020_28030d.bin` | 750 | `hd-ae5000_v2_06i.ic4` | 0x280020 | `dd if=original_ROMs/hd-ae5000_v2_06i.ic4 bs=1 skip=$((0x20)) count=750 of=code_280020_28030d.bin` |
| `original_ROMs/table_data_bootcode.bin` | 19224 | `kn5000_table_data.rom` | 0x9FB4E8 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1FB4E8)) count=19224 of=table_data_bootcode.bin` |
| `v7/maincpu/audio/note_voice_mapping_v9_patch.bin` | 2900 | `kn5000_v9_program.rom` | 0xFEF99E | `dd if=original_ROMs/kn5000_v9_program.rom bs=1 skip=$((0x1EF99E)) count=2900 of=note_voice_mapping_v9_patch.bin` |
| `v9/maincpu/audio/note_voice_mapping_v9_patch.bin` | 2900 | `kn5000_v9_program.rom` | 0xFEF99E | `dd if=original_ROMs/kn5000_v9_program.rom bs=1 skip=$((0x1EF99E)) count=2900 of=note_voice_mapping_v9_patch.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_00_compressed.bin` | 22180 | `kn5000_table_data.rom` | 0x9C405E | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1C405E)) count=22180 of=demo_preset_00_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_01_compressed.bin` | 23737 | `kn5000_table_data.rom` | 0x9C9026 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1C9026)) count=23737 of=demo_preset_01_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_02_compressed.bin` | 14615 | `kn5000_table_data.rom` | 0x9CE18A | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1CE18A)) count=14615 of=demo_preset_02_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_03_compressed.bin` | 21433 | `kn5000_table_data.rom` | 0x9D1700 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1D1700)) count=21433 of=demo_preset_03_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_04_compressed.bin` | 16287 | `kn5000_table_data.rom` | 0x9D646A | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1D646A)) count=16287 of=demo_preset_04_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_05_compressed.bin` | 18295 | `kn5000_table_data.rom` | 0x9DA024 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1DA024)) count=18295 of=demo_preset_05_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_06_compressed.bin` | 11926 | `kn5000_table_data.rom` | 0x9DE080 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1DE080)) count=11926 of=demo_preset_06_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_07_compressed.bin` | 6207 | `kn5000_table_data.rom` | 0x9E0CF0 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1E0CF0)) count=6207 of=demo_preset_07_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_08_compressed.bin` | 17258 | `kn5000_table_data.rom` | 0x9E2366 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1E2366)) count=17258 of=demo_preset_08_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_09_compressed.bin` | 4598 | `kn5000_table_data.rom` | 0x9E61D0 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1E61D0)) count=4598 of=demo_preset_09_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_10_compressed.bin` | 12818 | `kn5000_table_data.rom` | 0x9E72F6 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1E72F6)) count=12818 of=demo_preset_10_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_11_compressed.bin` | 17329 | `kn5000_table_data.rom` | 0x9EA200 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1EA200)) count=17329 of=demo_preset_11_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_12_compressed.bin` | 3322 | `kn5000_table_data.rom` | 0x9EE00A | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1EE00A)) count=3322 of=demo_preset_12_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_13_compressed.bin` | 9125 | `kn5000_table_data.rom` | 0x9EEC70 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1EEC70)) count=9125 of=demo_preset_13_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_14_compressed.bin` | 3608 | `kn5000_table_data.rom` | 0x9F0E80 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1F0E80)) count=3608 of=demo_preset_14_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_15_compressed.bin` | 8635 | `kn5000_table_data.rom` | 0x9F1C7E | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1F1C7E)) count=8635 of=demo_preset_15_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_16_compressed.bin` | 3671 | `kn5000_table_data.rom` | 0x9F3B60 | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1F3B60)) count=3671 of=demo_preset_16_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_17_compressed.bin` | 3497 | `kn5000_table_data.rom` | 0x9F495C | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0x1F495C)) count=3497 of=demo_preset_17_compressed.bin` |
| `original_ROMs/demo_preset_compressed_refs/demo_preset_18_compressed.bin` | 33842 | `kn5000_table_data.rom` | 0x8E000E | `dd if=original_ROMs/kn5000_table_data.rom bs=1 skip=$((0xE000E)) count=33842 of=demo_preset_18_compressed.bin` |
| `original_ROMs/table_data_bootcode.unidasm` | 285339 | (listing of the row above) | 0xFFB4E8 alias | regenerate with `unidasm` over the .bin |

## Why each group went

* **table_data bootcode blobs + `lzss_routines.bin`** — superseded
  extraction generations of the 0x9FB4E8–0x9FFFFF boot region, which
  Wave 1 source-built in full (`table_data/boot_fdc.s`,
  `boot_cpserial*.s`, `boot_clib.s`, `boot_disk_probe.s`).
  `bootcode_pre_lzss.bin` and `bootcode_post_clearram.bin` even start at
  the same offset (0x9FB7F2) — two cuts of one region.
* **`hdae5000/includes/code_280020_28030d.bin`** — the one hdae5000
  include outside both builds; 0x280020–0x28030D is disassembled.
* **`original_ROMs/table_data_bootcode.bin` + `.unidasm`** — the whole
  bootloader region (0x9FB4E8 to the end of the ROM) as a reference
  extraction, plus its listing at the boot-time alias 0xFFB4E8.
* **`note_voice_mapping_v9_patch.bin` ×2** — residue of commit 9526be1
  ("Patch v9 maincpu: 99.96% byte-match"); both copies identical, and
  the v7/v9/v10 trees now byte-match at 100%.
* **`original_ROMs/demo_preset_compressed_refs/`** — 19 slices cut with
  the documentation's wrong 14-byte SLIDE4K header model (the header is
  11 bytes), so each begins 3 bytes inside its stream and overruns its
  block.  The authoritative, compare-covered references are
  `original_ROMs/demo_preset_NN_compressed.original.bin`.

## What was deliberately NOT deleted

Six `table_data/includes/bootcode_*.bin` and five
`hdae5000/includes/code_*.bin` are still `binclude`d by the legacy ASL
mirror in `archive/asl/`, which `make asl-all` builds and
`compare_roms.py` scores.  They look orphaned to a grep over
`*.s`/`*.py`/`Makefile`/`*.md` alone — that grep is what made the
2026-08-07 audit call them orphans.  They are live build inputs.
