# prom_d's base address, and three stale comments in `wsa1.cpp`

Lane `drvpromd`, worktree `~/compartilhado/disasm-lanes/drvpromd`, 2026-09-02.
**No driver file was modified by this lane.** This note is the hand-off.

## Verdict on the base: **PROVEN** — `0x00F00000` on CPU 2's bus

The lane was sent to ask whether the completed prom_d disassembly can prove or
refute the `0xE80000` reading. It does not need to: **the question was already
settled in wave 7 round 3, and by evidence that is not prom_d's own.** The
honest framing of the result is therefore in two parts.

### Part 1 — prom_d, taken alone, CANNOT prove its base (BASE-AGNOSTIC)

The image is a 0-based tone database. Its 48-slot directory holds **file
offsets, not addresses**, and what shows that is not a statistic but an
instruction sequence: prom_c reads a tone-record entry out of the table at slot
`+0x08` (`0xFB429D`) and then **adds the base to it** (`0xFB429F`), having
already added the base to reach the table (`0xFB4298`). A stored absolute
address needs neither add.

The self-reference scan the lane was asked to run had already been run and is
committed as **round 3 Q8**, and its result is negative and is documented as
negative in `prom_d/prom_d.ld`: aligned LE32 words with top byte `0x00` and
value `>= 0x1000` show flat bank noise in prom_d (`0x40`:1267, `0x1E`:784,
`0x64`:722 of 20076). Measured as the share of such words landing in the
image's own bank window it is prom_a 20.4%, prom_b 18.6%, prom_c 3.4%, prom_d
1.5% — **and prom_c is a code ROM that scores like prom_d**, so the profile does
not discriminate and the `.ld` correctly refuses to rest on it. That refusal is
the right call and I did not disturb it.

So: on the image alone the answer is **BASE-AGNOSTIC**, exactly as the brief
anticipated is possible for a pure data ROM addressed by offset.

### Part 2 — the readers prove it, twice, from two different processors

* **prom_c.** `ExtBoard_ProbeAndInstallBases` loads `0x00F00000` at `0xFB051E`
  and stores it to RAM `0x00D7ED` (`0xFB0523`) and `0x00D7F1` (`0xFB0528`).
  Those two stores are the **only** instructions in prom_c that write either
  address, so the base is a compile-time constant at every use. prom_c then
  reads this image's directory through that base at 99 instruction pairs over
  33 slots.
* **prom_a**, independently. `VersionScreen_Show` (`0xF82A28`) issues two
  **remote** block reads over the inter-CPU link — the address is pushed as an
  argument to the link reader at `0xF40EF0`, so it is an address on *CPU 2's*
  bus, not a local fetch:

      dst RAM 0x2640, count 11, src remote 0x00FFFFF0   -> prom_c's tag
      dst RAM 0x264C, count 11, src remote 0x00F7FFF0   -> prom_d's tag

  `0x00F7FFF0 - 0x7FFF0 = 0x00F00000`, and `0x7FFF0` is exactly where the tag
  `wsad_54.ssf` sits in the 512 KiB image — **the size and the base agree.**

  ⚠ I checked the one way this could be circular and it is not. On CPU 1's own
  bus `0xF00000-0xF7FFFF` is **prom_b**, and prom_b at file `0x7FFF0` reads
  `1d 78 2a f4 1e 8f 00 0e ...` — no tag. So a local reading of that literal
  would find nothing; only the remote reading works. The tie is also stronger
  than the string: `cp (XIX+0x15),0x6673` at `0xF82A93` tests the second
  buffer's bytes +9/+10 for ASCII `"sf"`, which only `wsad_54.ssf` has
  (`wsac_230\x02ss` has `"ss"`), and on a match `0xF82A9A-0xF82AA3` shifts the
  field right and pads. **A firmware that did not expect prom_d's exact
  one-byte-shorter tag could not contain that branch.**

### The `0xE80000` reading is **REFUTED**

prom_c's own `Flash_SectorErase` holds device base `0x00E80000` (`0xFC864B`),
tests the requested sector against `0x00EF0000` for the top-boot sub-sector map
(`0xFC86CF`), and its highest sub-sector base is `base+0x7C000`. So the
**firmware's own model of that part ends at `0x00EFFFFF`, below prom_d's base**;
a 1 MiB part would have compared against `0x00F70000`. And the same routine
installs `0x00F00000` and `0x00E80000` into **separate** slots (`0x00D7ED`/
`0x00D7F1` and `0x00D7F5`).

Re-run, 12 checks, 0 failures:

    cd wsa1 && python3 notes/prom_d_base_checks.py --verbose

## The three stale comments in `wsa1.cpp`

The tip-of-development driver is
`~/compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp`. It already **maps
prom_d correctly** (`map(0xf00000, 0xf7ffff).rom().region("prom_d", 0)`, line
2737) and states the corrected evidence at lines 2717-2732. Three comments in
the same file were not updated with it, and two of them contradict the map 40
lines below.

### A. line 280-282 — the TODO. **Strike the entry entirely.**

Current:

>       - fix the base address of the fourth EPROM image, which is strongly
>         supported as the content of the 512 KiB flash at 0xE80000 on the second
>         processor but not proven

There is nothing left to fix: the base is established twice over in the body of
the same file, and the map already uses it. Deleting the entry is the whole
correction.

### B. line 2695-2696 — inside the "not mapped, deliberately" note on the flash.

Current:

>     //    0xEFFFFF - but the part is not dumped, and the
>     //    fourth EPROM image is only strongly supported as its content, not
>     //    proven.  Mapping it would put undumped bytes on the bus as if they
>     //    were read from the machine.

Suggested:

>     //    0xEFFFFF - but the part is NOT DUMPED, and mapping it would put
>     //    undumped bytes on the bus as if they were read from the machine.
>     //    (It is NOT prom_d: prom_d is the tone database at 0xF00000, mapped
>     //    below.  The firmware's own erase map bounds this part at 0xEFFFFF,
>     //    below prom_d's base, and ExtBoard_ProbeAndInstallBases installs the
>     //    two bases into separate slots.  wsa1-roms-disasm/notes/
>     //    prom_d_base_checks.py, 12 checks.)

The rest of that bullet — the size derivation from `Flash_SectorErase` — is
correct and independently reconfirmed; keep it. The unlock addresses it cites,
byte offsets `0xAAAA`/`0x5554`, are word offsets `0x5555`/`0x2AAA`, the
canonical JEDEC pair for an x16 device, which is consistent with the AM29F400T
the parts list names.

### C. line 2734-2736 — the warning about the disassembly tree. **Now itself stale.**

Current:

>     // ⚠ prom_d's own linker script in the disassembly tree still carries the
>     // superseded 0xE80000 hypothesis and says "BASE -- NOT ESTABLISHED".  That
>     // file is stale; the corrected reading is the one cited above.

`wsa1/prom_d/prom_d.ld` was **rewritten in wave 7 round 3**. It now opens
"ORIGIN STAYS 0, AND THAT IS NOW A DECISION RATHER THAN AN ADMISSION", states
`0x00F00000` on CPU 2's bus with the same two derivations, and explains that the
`0xE80000` part is a different, smaller device. The warning should simply be
deleted; nothing needs to replace it.

## Reproducibility

Every number above comes from `wsa1/notes/prom_d_base_checks.py` (12 checks,
committed before this lane) plus the direct byte reads quoted inline, which
anyone can repeat with:

    cd wsa1/original_ROMs
    xxd -s 0x7ffe0 -l 32 wsa1_prom_d.bin     # wsad_54.ssf at 0x7FFF0
    xxd -s 0x7ffe0 -l 32 wsa1_prom_b.ic13    # NOT a tag -- the local reading fails

This lane added no new script for the base question because the existing one
answers it; the numbers it prints were re-run, not quoted from the notes.
