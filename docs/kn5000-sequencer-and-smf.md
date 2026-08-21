# The KN5000 sequencer, its song storage, and its SMF import/export

Status: substantial, and explicit about its limits. Every address below is a ROM address in the
main-CPU program image (base 0xE00000, so file offset = address - 0xE00000) or a `file:line` in
this repository. Claims here survived an adversarial review in which 10 of 22 candidate claims
about this subsystem were **refuted**; only survivors are recorded.

This subsystem was graded SKETCHED for a long time: 446 `SeqStep_*`, 653 `SMF_*` and 1007
`StyleRec_*` symbols existed with no record layout written down anywhere.

## 1. The RAM cell heap -- the thing everything else is a snapshot of

The sequencer works in a cell heap at main-CPU RAM **0x0B0000**, 0x4D8 = **1240 cells** of 256
bytes. A cell is:

    +0x00  u8      bit 7 = ALLOCATED. Bits 0..6 are never written by the initialiser and are
                   therefore unspecified -- do not read them.
    +0x01  u16 LE  PREV cell, 1-based; 0x0000 = this is a chain head
    +0x03  u16 LE  NEXT cell, 1-based; 0xFFFF = this is a chain tail
    +0x05  251 B   payload

Cell numbering is **ONE-BASED**: cell *c* lives at `0x0B0000 + (c-1)*256`. The two null values are
**field-specific and not interchangeable** -- `0x0000` means "no predecessor", `0xFFFF` means "no
successor". Reading them zero-based, or assuming one sentinel serves both ends, makes a perfectly
consistent doubly-linked heap look broken; that error is on record in this project.

**This is why the disk and ROM containers look the way they do.** A `.SEQ` file and a demo-song
preset are snapshots of this heap, which is also why a demo cell's bytes `[0..2]` are not
meaningless filler as an earlier note claimed -- they are the heap's allocator state.

## 2. `.SEQ` on disk

A `.SEQ` is a headerless array of those cells written straight out. Verified over the seven
floppies in `KN7000/floppy-archive`: among 596 allocated cells (`byte0 & 0x80`),
**next->prev agrees 547/547 and prev->next agrees 547/547**, with no allocated-cell pointer leaving
the file. Unallocated blocks (byte 0 == 0x00) form a trailing free list.

Payload is 251 bytes from +0x05 and uses the **demo-song event grammar**, not the accompaniment
one: a strict argument-count parse gives 0 malformed over 44,795 events at 251 bytes, against
1199-2342 malformed at every neighbouring length.

Reproduce: `analysis/disk-format-probes/disk_seq_chains.py <dir>`.

## 3. `.SQF` -- the song bank

Ten slots of 0x800 bytes at `slot * 0x800`, each opening with the magic `5A 5A 5A 5A`, with an
8-character slot name at **slot + 0xC1**.

Confirmed from firmware rather than from shape: `ui/setwall_routines.s:2181` copies 0x800 bytes
from `0xAB000 + slot*0x800`, and `sequencer/smf_playback.s:31` iterates slots 0..9 at that same
base and stride. The 0x800-byte copy into RAM 0xF180 is `SongBank_LoadToWorkArea`
(`ui/ui_playback_modes.s:1034`, duplicated at `setwall_routines.s:2124` and `:2183`).

A slot carries a 16-entry track directory at **+0xD0**, each entry `{u8 flags (bit 7 = present),
u16 LE start cell}`. On all seven floppies exactly five tracks are enabled, with start cells
3,4,5,6,7 -- independently corroborated by five u16s at `.SQF + 0x78` which match each chain's last
cell **35/35**.

## 4. Tempo

Status `0x80` in the event stream is the TEMPO event: `80 pos lo hi`, and

    BPM = lo + 128 * hi

with `pos` the tick within the beat as for every other event family. Proven on the firmware's
RECORDING path, which is where a BPM is computed rather than consumed: `0xF2451D` computes
`BPM = 234375 / period` (234375 = 60,000,000 / 256), and `0xF2452A`/`0xF24537` clamp the result to
**0x28..0x12C, i.e. 40..300 BPM**.

Timebase is **96 ticks per beat**, and the Timer-4 ISR is the proof rather than a comment:
`v10/maincpu/boot/system_handlers.s:721-726` does `incdi8 1,(1051)` / `cpdi8 (1051),96` /
`stdi8 (1051),0` / `incdi16 1,(1052)`.

## 5. `0x85` and `0x86` -- beat-synchronised start and stop

A START/STOP pair, each carrying exactly one argument: the tick within the current beat (0..95).
Established from code, not from distributions -- the event-size table `SeqEvent_GetParamLength`
(`v10/maincpu/sequencer/sequencer_engine.s:9903`) gives both a total size of 2 bytes, status plus
one argument.

## 6. SMF import

The `MThd` magic check is **not one-shot**. On the first mismatch the code increments 0x10F7 and
retries the four-byte compare once with the read pointer advanced by 0x80
(`0xF23382`-`0xF2339D`); only the second mismatch aborts, and it reports status `0x1A2B = 0x0031`
rather than the `0x0030` used elsewhere. An importer that gives up on the first mismatch will
reject files this machine accepts.

⚠ A real defect worth knowing about: the variable-length-quantity collector at `0xF23963` is
**uncapped**. It stores every byte whose bit 7 is set, so a legal four-byte SMF VLQ writes a fourth
byte to 0x1071, one past the three-byte staging field at 0x106E..0x1070. Nothing else in the
sequencer reads 0x1071 or 0x1072, so the overrun is currently harmless -- but it means the machine
does not correctly parse the full legal VLQ range.

## 7. SMF export

The buffered writer at `0xF2718C` writes **format 0, one track, division 0x0060 = 96 ticks per
beat**, matching the native timebase exactly. The 14-byte `MThd` is copied verbatim from
`0xF2823E` -- `4D 54 68 64 00 00 00 06 00 00 00 01 00 60` -- with `ldirw`, BC=7, and the 4-byte
`MTrk` from `0xF282..`.

## 8. SysEx gating

Incoming SysEx is filtered twice, and in both places to exactly **three manufacturer IDs: 0x50,
0x41 and 0x7E** (Matsushita, Roland, and Universal Non-Realtime). In the serial RX path at
`0xFCF820` (v9 identical; v7 at `0xFCF054`) the byte after `0xF0` is compared against those three
and a mismatch returns immediately, so the message never reaches the ring buffer at `0x01F88F`.

## What an outsider could and could not implement from this

**Could**: read a `.SEQ` or a `.SQF` off a disk, walk its chains, decode note and tempo events,
and write an SMF the machine will re-import.

**Could not**: produce byte-identical output for every event type. The controller family is only
partly decoded (see `accompaniment-style-format.md`: `0xD3` is CC 0x40 and `0xD2` is pitch bend,
but `0xD1` is not decoded), and `NOTE2`'s two trailing bytes are traced to a firmware table without
their meaning being established. Those are the remaining gaps, and they are named rather than
papered over.
