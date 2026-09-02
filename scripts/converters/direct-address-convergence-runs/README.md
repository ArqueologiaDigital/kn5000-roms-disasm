# Direct-address convergence — the run of 2026-09-03

Produced by `scripts/converters/run_direct_address_convergence.sh`, which is
the recipe; these are its outputs, kept because their numbers are quoted in the
sixteen family commits and in the lane report.

| file | the question it answers |
|---|---|
| `RUN-2026-09-03.log` | how many sites and files each family converted, and what the byte gate said after each one |
| `refused-2026-09-03.csv` | every site the converter would NOT rewrite, with the reason — six, all `ldw_da xwa, (\ParamC)` inside `.macro` bodies, which cannot be assembled in isolation and so cannot be certified per-site |
| `VERIFY-2026-09-03.log` | `verify_direct_address_convergence.py --base e6e075f4` — all 51,030 changed lines re-checked from git under ONE assembler, after the fact |

Regenerate with:

    scripts/converters/run_direct_address_convergence.sh /tmp/conv-out \
        stdi8 stda16 cpdi8 bitda ldw_da ldl_da stdi16 ldb_da stib_da \
        stw_da anddi8 stda32 stiw_da ordi8 cpdi16 stb_da ldda32
    python3 scripts/converters/verify_direct_address_convergence.py \
        --base <the base it was run on> \
        --llvm-mc ~/compartilhado/toolchain-snapshot/llvm-mc.snap

⚠ `ldda32` is in the list for completeness but was already retired on main by
lane `w16/conv-size`, to the identical spelling `ld r32, (addr:16)`; on a tree
that already has it the script stops with "NOTHING CONVERTED", which is the
correct answer, not a failure.

⚠ THE ASSEMBLER MOVED UNDER THIS RUN, twice over. The shared
`llvm-project/build/bin/llvm-mc` was relinked at least five times during the
lane — sha256 `d338b73ef5232fc9`, `4356ff9f56a1ee37`, `40e0268cfa11f05c`,
`52563be155f9bfaf`, `8c211d2fdddcfe13` — every one of them while `git log -1`
said `7e541b8ddb07`, and one of those links parsed `ld a, (0x120000:24)` while
rejecting `ldw (0xe0b4:16), 0`. Even the coordinator's *snapshot* copy at
`~/compartilhado/toolchain-snapshot/llvm-mc.snap` changed content mid-lane
(`53c6621d5f6dd3c1` -> `850b013e0e8f14d9`). So the verify log names the sha256
of the binary it actually opened, and that is the number to quote — not the
git commit, which did not move at all.

## ⚠ This is the SECOND run of the same 16 families

The first, on base `8851285e`, converted the identical 51,030 sites and gated
green — and then `main` moved 24 commits (two whole lanes merged) while it was
running, so it was regenerated from scratch on `e6e075f4` rather than rebased.
That is the point of committing the driver: a mechanical, per-site-verified
conversion is cheaper to re-run on a new base than to merge, and re-running it
also re-verifies it against whatever the backend has become in the meantime.
The two runs produced the same counts, mnemonic for mnemonic.
