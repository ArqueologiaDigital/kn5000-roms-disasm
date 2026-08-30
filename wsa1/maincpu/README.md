# `maincpu` -- CPU 1's program, which lives in two EPROMs

The Technics SX-WSA1R has two Toshiba TMP95C061s.  This directory is about the
first of them: **CPU 1, "MICROCOMPUTER (MAIN)", IC1**, and the program it runs.

That program is in **two chips**, and it is **one program**:

| chip | source | address range |
|---|---|---|
| IC13 | `prom_b/wsa1_prom_b.s` | `0xF00000-0xF7FFFF` |
| IC12 | `prom_a/wsa1_prom_a.s` | `0xF80000-0xFFFFFF` |

They are contiguous, on the same chip select, with no banking: the boot block
programs CS2 as `MSAR2 = 0xE0 / MAMR2 = 0x3F / B2CS = 0x1B`, one 1 MiB window
(`prom_a/prom_a.ld`, `prom_b/prom_b.ld`, `notes/FINDINGS-memory-map.md`).

⚠ `prom_a` and `prom_b` are **this project's file names**, taken from the
redistributed firmware set, and the program's own structure does not follow
them.  Three things say so and each is a measurement: the boot block's
25-module initialisation directory lives in prom_a and every one of its entries
points into prom_b; `calr`, a 16-bit PC-relative call, crosses the boundary in
both directions; and every reference to a duplicated routine binds to the
nearest copy without regard to which chip it is in (below).

CPU 2 is `prom_c/`, and `prom_d/` is data.  The multitasking kernel **both**
processors run is written once, in `kernel/kernel.s`.

## What is joined, and what is not

The two images stay **separately linked**.  They are different chips with
different `ORIGIN`s and they are assembled by two rules in the `Makefile`.  The
join is not about producing one binary; it is about presenting one program:

* **One macro base.**  `include/tlcs900_mem_ops.inc` is the TLCS-900
  byte-emitter set, and `prom_a`, `prom_b` and `kernel/kernel.s` all include it.
  It used to be two copies of one encoder.
* **The duplication resolved.**  Three routines are in the image **twice**, at
  two addresses, byte for byte.  Each is now ONE source, `.include`d at both
  sites, in `maincpu/shared/`.
* **One end-of-image marker per image.**  Both files called it `end`; in one
  address space that is two labels of one name for two addresses, so they are
  `prom_a_image_end` and `prom_b_image_end`.

## The duplicated routines, and why they are duplicated

    python3 notes/maincpu_join_probe.py --collisions --callers --nearest
    python3 notes/maincpu_join_probe.py --selftest

Exactly four labels were defined in both images.  Three are byte-identical
routines:

| routine | prom_a | prom_b | bytes | differing |
|---|---|---|---:|---:|
| `IndexedTable_GetPtr` | `0xFB77D8` | `0xF55321` | 27 | 0 |
| `LCD_ScreenRedraw_Begin` | `0xF999F0` | `0xF7E2D9` | 14 | 0 |
| `LCD_ScreenRedraw_End` | `0xF999FE` | `0xF7E2E7` | 6 | 0 |

The fourth, `end`, is not a routine: it is the end-of-image marker, which
`prom_c` carries too and which nothing in the tree references.

**★ The obvious explanation is wrong.**  "Each ROM carries its own copy so it can
be called without a bank switch" does not survive contact with the call sites.
There is no bank -- the two chips are one flat window -- and **prom_a calls
prom_b's copies sixteen times**, thirteen of those with `calr`, a 16-bit
PC-relative call that could not cross a bank if there were one.

**What is true** is decidable and holds without exception: of the **63**
references to the six copies, **all 63 bind to the copy nearest in the address
space**.  prom_a's boot block at `0xF80000` calls the copy at `0xF7E2D9`, just
below it in prom_b; prom_a's UI block at `0xF99021` calls the copy at `0xF999F0`,
inside itself.  That is a routine emitted **once per link unit**, with each
unit's references bound to its own copy -- and it is why the chip boundary at
`0xF80000` is invisible to the call graph.

It is the same shape as `kernel/kernel.s` one level down.  There, one source
serves two **processors**; here, one source serves two **link units** of one
processor.  In both cases the byte gate is what makes it a proof rather than a
resemblance:

    python3 scripts/analysis/assert_byte_identical.py

## ⚠ The line shape

`maincpu/shared/*.s` carries **both** images' addresses on every line --
`; FB77D8/F55321` -- exactly as `kernel/kernel.s` does, and no `prom_*.s` file
does.  Any tool that scans a source by address must be told about these files or
it silently measures a tree with them missing.  `notes/reachability.py` knows;
`scripts/analysis/source_coverage.py` follows each image's own `.include`s.

## What this is NOT, yet

`prom_a/wsa1_prom_a.s` and `prom_b/wsa1_prom_b.s` are still **one listing each**,
11 MB and 8 MB, where `prom_c/` has been split into per-subject sources
(`prom_c/boot/`, `prom_c/midi/`, `prom_c/voice/`, ...) and the KN5000's
`v10/maincpu/` is split the same way.  Splitting these two the same way is the
obvious next step and the tooling supports it -- both `notes/reachability.py`
and `scripts/analysis/source_coverage.py` follow an image's own `.include`s.

It was **not** done in this pass, deliberately: **112 committed analysis scripts
open `prom_a/wsa1_prom_a.s` or `prom_b/wsa1_prom_b.s` by path** and read them
line by line, and a split moves the content out from under every one of them
without any of them failing.  Regenerate that figure, never retype it:

    python3 notes/maincpu_join_probe.py --split-cost  That is the same class of silent-emptying failure
`notes/reachability.py`'s own comments describe, at 112x the blast radius.  The
split is a wave, not a step, and its first job is that inventory.
