# Lane `w16/conv-width` — the direct-address family

**Done.** Sixteen synthetic mnemonics retired to their native LLVM spelling with
the address width in the operand, **51,030 sites in 242 files**, gated one
family at a time. The seventeenth, `ldda32` (4,991 sites), was already retired
on `main` by `w16/conv-size` to the identical spelling, so the family as a whole
is 56,021 sites and is now **closed**.

This is section 8 of `notes/ASSESSMENT-syntax-convergence-2026-09-02.md`
(Option B) for the part that needed **no backend change at all**.

## The map — the finding

| synthetic | native spelling | addr width | data size | sites |
|---|---|---:|---|---:|
| `stdi8`   | `ld (addr:16), imm8`   | 16 | 8  | 10,895 |
| `stda16`  | `ld (addr:16), r16`    | 16 | 16 |  7,764 |
| `cpdi8`   | `cp (addr:16), imm8`   | 16 | 8  |  5,191 |
| `ldda32`  | `ld r32, (addr:16)`    | 16 | 32 |  4,991 (conv-size) |
| `bitda`   | `bit n, (addr:16)`     | 16 | –  |  3,669 |
| `ldw_da`  | `ld r16, (addr:24)`    | 24 | 16 |  3,329 |
| `ldl_da`  | `ld r32, (addr:24)`    | 24 | 32 |  2,924 |
| `stdi16`  | `ldw (addr:16), imm16` | 16 | 16 |  2,652 |
| `ldb_da`  | `ld r8, (addr:24)`     | 24 | 8  |  2,425 |
| `stib_da` | `ld (addr:24), imm8`   | 24 | 8  |  1,967 |
| `stw_da`  | `ld (addr:24), r16`    | 24 | 16 |  1,829 |
| `anddi8`  | `and (addr:16), imm8`  | 16 | 8  |  1,791 |
| `stda32`  | `ld (addr:16), r32`    | 16 | 32 |  1,780 |
| `stiw_da` | `ldw (addr:24), imm16` | 24 | 16 |  1,300 |
| `ordi8`   | `or (addr:16), imm8`   | 16 | 8  |  1,279 |
| `cpdi16`  | `cpw (addr:16), imm16` | 16 | 16 |  1,119 |
| `stb_da`  | `ld (addr:24), r8`     | 24 | 8  |  1,116 |

The machine-readable form is `MAP` in
`scripts/converters/convert_direct_address_family.py`; the human form is `SPELL`
in `scripts/converters/run_direct_address_convergence.sh`.

⚠ **The width is read off the MNEMONIC, never off the address.** UPDATE 7: this
firmware writes `set 7,(0x00008a)` as a 24-bit field for an 8-bit address. The
`width` column above is the prefix the mnemonic is *defined* to emit in
`TLCS900InstrInfo.td` (C0/D0/E0/F0 = 8, C1/D1/E1/F1 = 16, C2/D2/E2/F2 = 24).

⚠ **CORRECTED 2026-09-04: the 8-bit rule below holds for the LD-direct class
ONLY.** The ALU-direct class encodes a 32-bit name written in an 8-bit slot
index-preservingly instead — `ldb_da xbc` is C (the pair's low byte) but
`cpda8 xbc` is A (the same index). Two conventions live in one backend, split by
instruction class. The converter no longer asserts either: it offers candidate
spellings and keeps the one whose encoding matches the line it replaces. See
`notes/lanes/conv-alu-2026-09-04.md`.

⚠ **The 16-bit register rename is a correction, not cosmetics.**
`stda16 (X), xwa` named a **32-bit** register for a **16-bit** store; the
sub-opcode is `0x50 + index`, so the operand is really WA. The mapping is
index-preserving and was measured by encoding all eight names both ways, and
this tree already wrote the 16-bit name at about half of those sites. On the
8-bit forms a 32-bit name denotes the pair's **low byte** — `ldb_da xwa` is
`ld a` — corroborated by the source's own comment at
`hdae5000/hdae5000_hd_driver.s:403`. Same class as UPDATE 5's `stb_dri`: bytes
right, name wrong. The four x-names with no 8-bit half are refused, not guessed.

## Evidence

* **Per site, before writing.** Old and new spelling assembled in isolation,
  encoding bytes *and* relocation fixups compared. A family-level gate can be
  green while one site changed and another compensated.
* **After the fact, over the whole branch, under ONE named binary.**
  `verify_direct_address_convergence.py --base e6e075f4` reads the change out of
  git rather than out of the converter: 51,030 of 51,030 line pairs encode
  identically, 242 files, all line-for-line.
* **Comments.** 12,480 trailing comments on those 51,030 lines, before and
  after, **0 text mismatches** — asserted by the same verifier.
* **The gate.** `make gate-all` green after **every one** of the sixteen
  families: 13/13 ROMs byte-identical, 8/8 images assembling, and the
  toolchain-prerequisite assertion 8/8 + 4/4.
* **The gate was shown to go red on these lines.** Changing one converted
  address in `wsa1/prom_b/wsa1_prom_b.s` by one makes the WSA1R gate report
  `wsa1_prom_b.ic13: 1 byte(s), first at 0x11B` and nothing else move. Restored,
  green again. (Chosen in WSA1R deliberately, because those four images had been
  certifiable stale until `07db0cc2`.)
* **The converter was shown to be able to refuse.** `--foil width` states the
  other address width and refuses 56,027 of 56,027 sites. `--foil reg` leaves
  the 32-bit register name and refuses exactly the 6,252 sites that use one,
  passing the 6,670 already written with a 16-bit name — a control that must
  reject *some* and accept the rest, not everything.

## Refused: 6 sites, and why

`ldw_da xwa, (\ParamC)` in `.macro` bodies — v7/v9/v10
`display/scoop_display.s` and `factory_test/test_init.s`. A macro parameter
cannot be assembled in isolation, so the per-site guard cannot certify it, and
the lane brief puts macro definitions out of scope. Listed in
`scripts/converters/direct-address-convergence-runs/refused-2026-09-03.csv`.

## Residual — what is left of the direct-address shape

⚠ **CORRECTED 2026-09-04 by lane `w26/conv-alu`, which converted this residue:
the real figure is 11,881 sites over 95 names, not 9,748 over 66.** The count
below was taken by grouping census names that *look* like direct-address forms;
the actual set is every backend mnemonic whose `(ins ...)` list contains
`directaddr`, intersected with tree usage, and the 29 names the name-shape rule
missed are `jp_24`, `call_24`, `lda_24`, `pushdi_24`, `chgda_24` and their `_24`
siblings — which take the same operand but do not look like the others. A census
keyed on a naming convention measures the naming convention. The follow-up
converted 11,840 of them; see `notes/lanes/conv-alu-2026-09-04.md`.

`mnemonic_census.py` after this lane: **9,748 sites over 66 names** still spell a
direct address in the mnemonic. None was in this lane's assignment. They are, in
size order, the **ALU-direct** family (`cpda8` 804, `cpda16` 666, `andda16`,
`subda16`, `orda8`, `addda32_24`, …), **bit set/res** (`resda` 867, `setda` 703),
**inc/dec-direct** (`incdi8` 494, `incdi16` 379, …), `stl_da` 792, `cpib_da` 468,
`cpw_da` 442, and a handful of 8-bit-address `_d8` forms. Every one of them is
the same shape as this lane's work and should convert the same way; the `_24`
suffixed names are the 24-bit siblings and carry their width in the name
already.

⚠ Not counted there: `ldb_d8` (17,406), `ldw_d16` (8,948), `stb_d8` (9,064) and
the other 16-bit-address load/store names, which are another lane's.

## ⚠ What cost this lane the most time, and is not about the sources

**The assembler moved under the measurements, repeatedly and silently.** The
shared `llvm-project/build/bin/llvm-mc` was relinked at least five times —
sha256 `d338b73ef5232fc9`, `4356ff9f56a1ee37`, `40e0268cfa11f05c`,
`52563be155f9bfaf`, `8c211d2fdddcfe13` — every one of them while
`git log -1` said `7e541b8ddb07`. Two consequences, both real:

* one link **parsed `ld a, (0x120000:24)` while rejecting `ldw (0xe0b4:16), 0`**,
  turning two already-committed, already-gated families red with
  `expected ')'`. The next link accepted both. Nothing in the tree changed
  between the two runs.
* two gate runs died on a transient `Permission denied` on `llvm-mc` / `ld.lld`,
  and one reported `hd-ae5000` STALE.

Even the coordinator's pinned *snapshot* changed content mid-lane
(`53c6621d5f6dd3c1` → `850b013e0e8f14d9`).

★ **So quote the binary's sha256, not the git commit.** The commit did not move
at all across every one of those. The final verification names
`850b013e0e8f14d9a90b95ff1995a858ad8575b8c35a8749970b47ffc613f1a1`.

## ⚠ Regenerating beat rebasing, twice over

This conversion was run **twice**: once on base `8851285e`, gated green, and
then `main` moved 24 commits (two lanes merged) while it was running. Rebasing
17 commits that each touch ~100 files across the whole tree conflicted
immediately. Resetting to the new `main` and re-running the driver took ~25
minutes, produced **identical counts mnemonic for mnemonic**, and re-verified
the result against the newer backend as a bonus.

★ A mechanical, per-site-verified mass edit is cheaper to **re-run** on a new
base than to merge. That is the argument for committing the driver, not just
the converter.
