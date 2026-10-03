# prom_a 0xF8C000-0xF97533: eight small items closed by inbound references
# already present in already-converted code (2026-09-02)

**Status: 231 bytes converted (7 items, 50-58 B each) + 48 B; none required a
fresh walk-plausibility argument.** Every one is licensed by something
already sitting in `prom_a/wsa1_prom_a.s` before this pass touched it: a
literal `ld XIY,<address>`, a `jp (xix)` through a register loaded from that
exact address, or a module-boundary padding run already verified byte by
byte. Converter: `notes/gen_prom_a_f8c000_cluster.py` (`--check` re-derives
every number below). Gate: `make gate-wsa1`, green.

## PanelLed_PhaseVector (50 B, CODE)

Preceded by 222 bytes of `.fill 0x0E` -- a module boundary already verified
byte-by-byte by `notes/gen_prom_a_block.py` -- and followed immediately by
the pre-existing `PanelLed_OnPartEvent`. `jp 0xf8c018` skips five dead
`ret/nop/nop/nop` veneer slots, then `0xF8C018` does five `ld (addr),0x05`
writes and returns. This is the same "unused vector slot" module-header shape
already accepted for `0xFE0000` (six `jp` veneers) on structural grounds
alone -- `FINDINGS-prom_a-fcf000-module.md` there: "what pins the start is
module structure, not the decode." A whole-ROM 3-byte scan for a pointer to
`0xF8C000` finds exactly one hit, at `0xFAD2C9`, already explained: it is
inside an already-converted `.long` stride table (`0x00f3f840, ...f880,
...f8c0, ...f900`) with no relation to this address -- a coincidence, not a
reference, the same shape the FC4000 investigation catalogued for its eleven
raw hits.

## Five CmdList_* tables (75 B total, DATA)

| table | bytes | records | reader (already-converted) |
|---|---:|---:|---|
| `CmdList_F8C046` | 8 | 1 | `0xF8C03D ld XIY,0x00f8c046` |
| `CmdList_F8C05B` | 22 | 3 | `0xF8C052 ld XIY,0x00f8c05b` |
| `CmdList_F8C086` | 15 | 2 | `0xF8C07D ld XIY,0x00f8c086` |
| `CmdList_F8C0A4` | 15 | 2 | `0xF8C09B ld XIY,0x00f8c0a4` |
| `CmdList_F8C0C1` | 15 | 2 | `0xF8C0B8 ld XIY,0x00f8c0c1` |

Every reader is an already-existing instruction, not something this pass
added. Each table is N x 7-byte records with **zero remainder**, terminated
by one `0xFF` byte. The strongest single piece of evidence: all five readers'
following `calr` -- real relative-displacement arithmetic already encoded in
the ROM, not recomputed by this pass -- resolve to the **identical** address,
`0xF8C16D`. That address is `.LF8C16D: cp (XIY),0xff` in already-converted
code: a shared parser that walks records via `XIY` and tests for exactly the
terminator byte this pass derived independently from the record structure.
Five independent call sites landing on one shared parser, whose own body
tests the exact sentinel value the data implies, is not a coincidence a walk
could manufacture.

## DispatchTable_F8C2B2 (58 B, DATA)

Variable-length entries: a 2-byte id, then either a 2-byte placeholder
(id == `0xFFFF`) or a 4-byte little-endian pointer (6 bytes total). The parse
consumes exactly 58 bytes with zero remainder. All **8** non-placeholder
pointers land inside the union of the two immediately following, still-
`.incbin` spans:

* `0xF8C485-0xF8C630` (427 B) -- entries at `0xF8C485` (the span's own START),
  `0xF8C4D8`, `0xF8C596`, `0xF8C5E3`
* `0xF8C652-0xF8C842` (496 B) -- entries at `0xF8C652` (the span's own START),
  `0xF8C707`, `0xF8C77D`, `0xF8C7AC`

**Neither neighbour is converted this pass.** `0xF8C485-0xF8C630` decodes
self-consistently overall (0 undecodable bytes, `0xF8C630` a boundary), but
one of the table's own targets, `0xF8C4D8`, lands 3 bytes off an instruction
boundary of that same decode, next to a cluster of suspicious mnemonics
(`normal`, `max`, several bare `nop`s) that do not occur elsewhere in this
tree's idiom -- exactly the subtle mid-span drift this project has been
burned by before. `0xF8C652-0xF8C842` fails outright: 8 undecodable bytes at
a roughly 16-byte stride (`0xF8C687` through `0xF8C708`), the signature of an
embedded fixed-stride table, not a misread of pure code. Both are left
`.incbin`, refused -- but the dispatch table itself is strong, externally
derived evidence that they ARE real entry points, and is recorded here as the
lead for whoever takes them next.

## MidiOut_PostPartPanpot (48 B, CODE)

`push XIZ/XIX/XHL/XDE ... pop XDE/XHL/XIX/XIZ / ret` -- the canonical
four-register save/restore shape used throughout this tree. Reached by a
COMPUTED jump, not a bare citation: already-converted code at `0xF98628` does
`lda_24 xix, (0xf97503)`, and the SAME routine later executes `push XIY /
jp (xix)` twice (`0xF98670`, `0xF986CF`) -- a manual call-with-return-address
idiom whose target is the address this pass converts. `XIX` is actually
jumped through, not merely loaded.

## What licenses these, and what does not

None of these needed a fifth walk. Every conversion rests on something
`notes/reachability.py`'s STRONG-seed walk does not credit (a bare
`ld Xrr,imm32`/`lda` is explicitly excluded, "round 1 proved it paints
pointer tables as instructions") but that is nonetheless a real, already-
existing, opcode-anchored citation in code this project has already verified
byte-exact. `reachability.py` still reports these as unreached; that is a
limitation of what that walk's seed classes count, not evidence against the
conversions above.

## Byte accounting

50 (`PanelLed_PhaseVector`) + 8 + 22 + 15 + 15 + 15 (five `CmdList_*`) + 58
(`DispatchTable_F8C2B2`) + 48 (`MidiOut_PostPartPanpot`) = 231 bytes converted.
