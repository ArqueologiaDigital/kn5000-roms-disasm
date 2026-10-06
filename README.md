[![semantic disasm](docs/badges/semantic-score.svg)](#how-semantic-is-it)
[![KN5000 semantic](docs/badges/semantic-score-kn5000.svg)](#how-semantic-is-it)
[![SX-WSA1R semantic](docs/badges/semantic-score-wsa1.svg)](#how-semantic-is-it)
[![bytes understood](docs/badges/semantic-bytes.svg)](#how-semantic-is-it)
[![semantic names](docs/badges/semantic-names.svg)](#how-semantic-is-it)
[![jump tables resolved](docs/badges/semantic-entry.svg)](#how-semantic-is-it)
[![C fields named](docs/badges/semantic-fields.svg)](#how-semantic-is-it)

It's been many many years that I've been studying the ROM code of the Technics KN5000 music keyboard with two major goals:

- [To emulate it on MAME](https://github.com/mamedev/mame/pull/14558)
- To be able to develop custom software to run on the real device.

There's much more info at https://forum.fiozera.com.br/t/technics-kn5000-homebrew-development/321

This repo started as a private one. But after putting so much effort into documenting the boot code, I decided to publish it, because it may be useful for other people interested in learning how this machine works.

I hope nobody gets mad at me for doing so. As this device was discontinued decades ago, I believe that there's no actual harm in doing so. It is much more like a museum item being studied by people interested in the history of electronic music equipment development.

Cheers,
Felipe Sanches


## How semantic is it?

Every image already rebuilds byte-identical to its dump, so byte-match says nothing about progress. The
badges above measure understanding instead, over every ROM of both models. They are produced by
`make semantic-score`, i.e. `scripts/analysis/semantic_score.py`, whose docstring defines each part:

- **bytes understood**: bytes whose purpose the source states with evidence: code, documented data and
  verified filler (`scripts/analysis/data_range_census.py`).
- **semantic names**: linked symbols whose name says what the thing is. Names that only restate an
  address (`sub_F4A2B0`) or a position (`Foo_Helper7`, `Foo_Case5`) do not count. Local branch labels
  (`Foo_Skip2`, prom_c's `Foo__F9A123`) are not rated, so each routine counts once.
- **jump tables resolved**: jump/call tables whose every entry lands on a labelled instruction, spelled
  symbolically (the committed dispatch census, `docs/coverage/`).
- **C fields named**: C struct members with a meaningful name rather than an index (`str_3`,
  `field_0a38`).

The score is the mean of these components, per model and overall. Every number behind it, with its
commit, is in `docs/badges/semantic-score.json`; the trend is in `docs/badges/semantic-score-history.csv`.

## This repository now holds two disassemblies

Since 2026-09-01 this tree also contains the **Technics SX-WSA1R** disassembly,
under `wsa1/`, migrated here from its own repository so that both products build
from one tree and can share code. That repository is decommissioned; all WSA1R
work continues here.

    make everything    build the KN5000 images and the WSA1R's four
    make gate-all      run both byte-identity gates
    make wsa1          the WSA1R alone

The byte-identity gate is the only thing that certifies either disassembly, so
neither is "built" until its gate is green.

All 206 WSA1R commits were rewritten to the `wsa1/` prefix before the merge, so
`git log wsa1/<path>` reaches the whole history rather than stopping at the
migration.

There is a real connection between the two machines, not just a shared
repository: the multitasking kernel that the WSA1R's two processors run is also
present in **both** of the KN5000's — one kernel, four processors, two products.
See `wsa1/notes/FINDINGS-kernel-in-the-kn5000.md`.

**Note:** I am using Alfred Arnold's **Macro assembler 1.42 Beta (Build 298)**.

Current state of this effort:

I am trying to rebuild the ROM and compare it with the original one with a 100% byte-matching goal.

As of 23rd Dec 2025, I'm at roughly 85% of that goal.

The main reason for not yet being able to get a perfect build is that the ASL assembler only supports the TLCS900 TMP96C141 CPU instruction set, while the KN5000 maincpu is a TMP94C241F.

So, my current goal is to get as close to 99.9% as possible, while leaving placeholder zero bytes on the unsupported instructions. Then, this will guide me to patch ASL to implement TMP94C241F support. And only after that there's hope of getting a perfect byte-matching rebuild of the ROM.

Once that is acchieved, I'll be able to use such assembler to resume my effort of developing homebrew software for the KN5000. My main project is to port Eric Chahi's Another World virtual machine to run on the musical keyboard (because we can! LOL).

There's some initial code in that direction available at:
https://github.com/felipesanches/kn5000_homebrew/blob/main/demos/anotherworld/another.asm
