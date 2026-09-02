# The assembler that certified tonight's results

**Status: CLOSED, 2026-09-02, by equivalence.** The gap described below was
real for about two hours. It is recorded rather than deleted, because the
mitigation is worth reusing and because the closing argument is the interesting
part.

## How it closed

The backend lane committed its work as `86332721969d` and left `llvm-project`
**clean**, so `build/bin/llvm-mc` (sha256 `850b013e`) is now reproducible from a
commit. Running the full gate under it, on the tree that the *preserved* binary
had certified:

    make LLVM_MC=<clean-commit build> gate-all    ->  13/13 IDENTICAL, 8/8 assembling

So two different assemblers — `53c6621d`, built from a **dirty** `7e541b8ddb07`,
and `850b013e`, built from a **clean** `86332721969d` — produce byte-identical
ROMs from the same sources. That does not prove the two binaries are the same
program, and it is not meant to: it proves the uncommitted state the snapshot
was carrying **made no difference to any of the 12,386,304 bytes under test**,
which is the only property tonight's results depended on.

★ Closing by *equivalence* rather than by *identity* is the honest move when the
sha cannot match by construction — the clean commit contains features the dirty
tree was mid-way through adding, so an identical hash was never available. State
which of the two you have.

`toolchain-snapshot/llvm-mc.snap` has been re-taken at `850b013e` and is now
reproducible: rebuild `86332721969d` and compare.

---

*The original note follows, describing the gap as it stood.*

## What is pinned

    /home/fsanches/compartilhado/toolchain-snapshot/llvm-mc.snap
    sha256 53c6621d5f6dd3c13e21e087fb88a19cf97bc93e304f4169035fbf8e9ebcecd7

Every gate run and every per-site byte comparison from 2026-09-02 23:21 onward
uses this file, passed explicitly:

    make LLVM_MC=/home/fsanches/compartilhado/toolchain-snapshot/llvm-mc.snap gate-all

## Why a snapshot was needed

`~/compartilhado/llvm-project` is a **shared** working tree, and one lane
develops the backend in it while other lanes gate against its output. On the
night of 2026-09-02 the built `llvm-mc` was re-linked at least five times —

    52563be1 -> ... -> 8c211d2f -> 53c6621d (snapshotted)

— while `git rev-parse HEAD` reported an unchanged `7e541b8ddb07` throughout,
because the tree carried **eight uncommitted modified backend files**. A lane
could therefore verify a rename against one assembler and gate it with another,
and nothing in either result would show the difference.

Per-lane build directories are the clean fix and are not currently affordable:
`/home` sits at 95–96%, with under 1 GB free. A 10.9 MB snapshot is.

## The gap that remains

`llvm-project` at `7e541b8ddb07` is **dirty**, so a clean checkout of that
commit does not necessarily rebuild this binary. Until the backend lane commits
its work:

* the snapshot is the only copy of the assembler that produced these numbers —
  **do not delete it**;
* `TOOLCHAIN_VERSION`'s commit line names a tree state that is not what built
  the binary, which is why this note exists beside it;
* the honest description of tonight's byte gates is *"green under a preserved
  assembler"*, not *"green under llvm-project 7e541b8ddb07"*.

**To close the gap:** once the backend lane commits, rebuild from the clean rev,
compare the sha against the snapshot, and re-run `gate-all`. If the sha differs
but the gate stays green on all thirteen images, record both shas here and the
gap is closed by equivalence rather than by identity. If the gate goes red, the
snapshot was carrying an uncommitted behaviour change and every result measured
under it needs re-derivation.

## Related

* `scripts/analysis/assert_toolchain_is_a_prerequisite.py` — asserts that a
  changed assembler actually rebuilds every image, in both trees. Before its
  fix, the WSA1R Makefile rebuilt **0 of 4**.
* `notes/lanes/BRIEF-2026-09-01.md` — the standing rule for lanes.
