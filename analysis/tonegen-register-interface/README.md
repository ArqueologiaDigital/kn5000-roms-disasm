# Tone-generator (IC303) register-interface probes

Three scripts. Run all of them **from the repository root**. Together they answer
"what does the firmware actually tell the tone generator, and does any ROM table go
straight into its registers?". The write-up is `FINDINGS-tg-register-interface.md`.

## `tg_register_census.py`

**Question:** which IC303 registers does the firmware write, *from which named routine*, and
what is the data source of each write? Also: does the MAIN CPU ever touch the chip?

Reads the disassembly sources, so it can attribute every write to a routine — but it
UNDERCOUNTS, because parts of the sub-CPU payload are still carried as `.byte` blobs.

```sh
python3 analysis/tonegen-register-interface/tg_register_census.py            # summary + main-CPU check
python3 analysis/tonegen-register-interface/tg_register_census.py --routines # grouped by routine
python3 analysis/tonegen-register-interface/tg_register_census.py --sites    # every site
python3 analysis/tonegen-register-interface/tg_register_census.py --csv      # machine readable
```

Signal read: stores to sub-CPU `0x100000` (register address latch, value = `(reg << 6) | ch`)
paired with stores to `0x100002` (register data). Pass = 137 matched sites in the v142 payload
and 28 in the boot ROM; **0** bus accesses from v7/v9/v10.

## `tg_rom_opcode_scan.py`

**Question:** the same, but counted in the ROM BYTES so nothing hides in a `.byte` blob.

```sh
python3 analysis/tonegen-register-interface/tg_rom_opcode_scan.py
python3 analysis/tonegen-register-interface/tg_rom_opcode_scan.py --sites
```

Signal read: `F2 00 00 10 50|02` (latch) paired with `F2 02 00 10 50|02` (data) inside a
24-byte window, and `D8 C8 lo hi` (`add WA,#imm16`) immediately before for the bank; reads are
`D2 00 00 10 2r`. Pass = **176** paired writes and exactly **1** read (sub-CPU `0x02102B`,
`ToneGen_Read_Register`). Cross-check: 24 sites on bank `+0x800` and 29 on `+0x840`, matching
the figures already recorded in the `0x0451CC` staging-block header of
`v142/subcpu/kn5000_subprogram_v142.s`.

## `tonedb_root_check.py`

**Question:** is the structure MAME's `build_pitch_constants()` walks at `table_data` offset
`0x30000` the same one the sub-CPU firmware calls `ToneDB_RootPtr`?

```sh
python3 analysis/tonegen-register-interface/tonedb_root_check.py
python3 analysis/tonegen-register-interface/tonedb_root_check.py --roms /path/to/dumps
```

Needs the two `table_data` dumps (default `~/compartilhado/kn5000_original_roms/kn5000`);
their SHA1s are checked against the values in MAME's `ROM_LOAD32_WORD` lines. Pass = every
root pointer field lands inside the 0x50000-byte block `SubCPU_Send_Payload` transfers to
sub-CPU `0x050000`, and the SET descriptor count divides exactly: **487**, the number the
driver logs. Printed verdict: *the driver's ROOT is the sub-CPU's ToneDB root.*
