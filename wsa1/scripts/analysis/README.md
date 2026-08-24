# scripts/analysis

Tools that produce the numbers quoted in the WSA1 notes. One entry per script:
what question it answers, and the exact command.

## `assert_byte_identical.py`
**THE GATE.** "Do the sources still rebuild the four ROMs byte for byte?"

    python3 scripts/analysis/assert_byte_identical.py

Must print `PASS: every rebuilt ROM is byte-identical.` after any edit to the
assembly sources. Nothing else certifies this tree.

## `derive_system_clock.py`
**"What crystal frequency do the two TMP95C061AF processors run at?"** (added by
a parallel session; see its own docstring for the claim list)

    python3 scripts/analysis/derive_system_clock.py

## `refute_memory_map.py`
**"Which claims of the 2026-08-24 WSA1 memory-map report survive an independent
re-derivation, and which do not?"**

    python3 scripts/analysis/refute_memory_map.py

Reads only `original_ROMs/`. Prints PASS/FAIL for every byte the refutation
cites, including deliberate `as-predicted-FAIL` lines where the report's cited
address does not hold what the report says. Exits non-zero if any assertion --
including a predicted mismatch that unexpectedly matches -- goes the wrong way.

Headline results it establishes: `0x7E` is **DMA2V**, not DMA3V, and CPU 2
programs the same engine (`0xF99A2A`); the flash size **is** established at
0xE80000-0xEFFFFF = 512 KB from the sector-erase addresses (`0xFC86A8`ff and
`0xFC86DA`ff); bit 3 of BnCS is set on the DRAM area too; prom_b does contain
"WSA" strings; and the MAMR window table (as the report had it) was the
sibling project's already-recorded, self-graded-unproven reconstruction, not a
new derivation. ⚠ That last point has since been *answered* rather than merely
sustained -- see `mamr_reading_elimination.py` above -- and the script's closing
note about `MSAR0 = 0x78` being unexplained is marked superseded in place.

## `mamr_reading_elimination.py`
**"Which reading of the MSAR/MAMR memory-controller registers survives the
WSA1's OWN firmware?"**

    python3 scripts/analysis/mamr_reading_elimination.py

This is the answer to the standing objection that the window sizes in the memory
map were imported from the sibling project's self-graded-unproven reconstruction
rather than derived.  It imports nothing.  It enumerates 8 candidate decoders
(32 KB vs 64 KB per MAMR unit x base truncated-to-window vs literal x higher-
numbered-CS-wins vs lower) and tests each against eight facts taken from the two
boot blocks and from ordinary code:

  the work DRAM must be on CS3 (its pin is LCAS), 0x7E0000 must be on CS0
  (B0CS is retuned around 256 reads of it), the static RAM must be on CS1, the
  EPROMs and the flash must be on CS2, the expansion board must NOT be, the link
  port must be on CS0.

Result: **2 of 8 survive**, and they are `32K/trunc/hi-wins` and
`32K/literal/hi-wins`.  So the 64 KB granularity is DEAD -- eliminated under
every base convention and every priority order -- and lower-numbered-CS-wins is
DEAD.  The two survivors agree on seven of the eight windows and disagree on
exactly one: CPU 1's CS0 is either 0x600000-0x7FFFFF or 0x780000-0x97FFFF.

It re-reads every byte it argues from and exits non-zero if any of them is not
what it claims.  Read it as elimination, never as proof: all eight candidates
assume size = unit*(MAMR+1) with a contiguous bottom-up mask, and a semantics
outside that family is untested.

## `dis.sh`
**"What is at CPU address X in ROM {a,b,c,d}?"** — unidasm does not seek, so this
`dd`s the window first and sets `-basepc` to the real CPU address.

    scripts/analysis/dis.sh a 0xF826A9 200      # prom_a reset path
    scripts/analysis/dis.sh c 0xFFF000 260      # prom_c reset path
    scripts/analysis/dis.sh b 0xF42D60 48       # prom_b thunk table

Bases baked in: `a`/`c` = 0xF80000, `b` = 0xF00000, `d` = 0 (file-relative;
prom_d's base is *not* established — see the notes).
Override the disassembler with `UNIDASM=/path/to/unidasm`.

## `trace_code.py`
**"Which bytes are really instructions, and which addresses does that code touch?"**

Recursive descent from the 33 reset/interrupt vectors at 0xFFFF00.  A TLCS-900
instruction decodes the same wherever the sweep that found it started, so the
length/text table is built by running unidasm once per byte phase (32 phases)
and merging.

    python3 scripts/analysis/trace_code.py a b    # CPU 1 address space
    python3 scripts/analysis/trace_code.py c      # CPU 2 address space

**Why this exists:** a straight linear sweep of these images is worthless for a
memory map. prom_c holds an IEEE-754 double table at file 0x4B27E
(CPU 0xFCB27E; the bytes `18 2d 44 54 fb 21 09 40` are pi) which linearly
disassembles into a tidy stride-4 register file that does not exist. 280 phantom
"registers" in 0xFCB27E-0xFCCA7E came out of that before this walker was written.

## `trace_code2.py`
Same walk, plus two **heuristic** seed sources, because vectors alone reach only
0.4% of prom_a+prom_b (the firmware dispatches through pointer tables):

* runs of >=4 consecutive 4-byte-aligned `1B lo mid hi` (`jp abs`) whose targets
  land in ROM — prom_b has one such thunk table at 0xF42D60;
* runs of >=4 consecutive 4-byte-aligned LE32 words pointing at addresses that
  already decode as instructions.

    python3 scripts/analysis/trace_code2.py a b   # 36.7% of 1 MB reached
    python3 scripts/analysis/trace_code2.py c     # 42.6% of 512 KB reached
    python3 scripts/analysis/trace_code2.py c --strict   # vectors only

Decode tables are cached in `$WSA1_CACHE` (default `/tmp/wsa1_dectab.pkl`);
delete it to rebuild (~25 s per ROM).

**Read the warning.** The heuristic seeds DO drag data in as code. Every address
this reports must be confirmed by looking at the disassembly around the site
before it is written down. Known false positives already caught this way:
`0x00028040` (11 "sites" in prom_a) and `0x00028028` (154 "sites" in prom_c) are
both a periodic byte pattern in a wave/table region decoding as
`ld XWA,0x000280xx` every 0x40 bytes; `0x00010201` in prom_a (F3F979 and every
0x40 after) is the same artefact; prom_c's `0x007A0000` sites (FD3562, FD9E4D)
sit in a run of `normal` / `halt` / `lddr` garbage.

## `kn5000_shared_runs.py`
**"Which WSA1 byte runs also occur in the KN5000 sub-CPU payload, and are they code?"**

    python3 scripts/analysis/kn5000_shared_runs.py

Result 2026-08-24: **32,795 B kept, 291,802 B rejected as low-entropy fill, shuffle null
0 B** (signal/null 32,795x). The entropy guard is the whole script -- without it the
"shared" mass is nine parts erase-fill and padding. **prom_c holds 28,916 of the 32,795**,
which is the structural finding: the KN5000 sub-CPU is *its* tone-generator controller, so
WSA1 CPU 2 and the KN5000 sub-CPU are the same design.

## `transplant_kn5000_labels.py`
**"Which KN5000 sub-CPU routine names apply to WSA1 addresses, by byte identity?"**

    python3 scripts/analysis/transplant_kn5000_labels.py

Writes `notes/kn5000-label-transplant.md`. Result 2026-08-24: **8 proposals** backed by
runs of 70-513 bytes -- `EGEnv_ValueCurve_Simple`, `EGEnv_BaseCurve_A`,
`DSP_EffParam_Copy_V4/V5`, and four DSP/voice jump tables.

⚠ Byte identity establishes the code is the same, not that the surrounding machine is.
And the byte gate is blind to a wrong NAME -- it only sees bytes -- so nothing here is
self-checking the way the build is. Proposals, not renames.
