# prom_b's Standard MIDI File WRITER, and the template nobody could frame

**Lane:** `w14/rq-midi`, 2026-09-02.
**Instrument:** `notes/gen_prom_b_smf_writer_module.py` — 87 checks, all
re-derived from the ROM on every run.

    python3 notes/gen_prom_b_smf_writer_module.py --selftest   # the evidence
    python3 notes/gen_prom_b_smf_writer_module.py --layout     # the segment table
    python3 notes/gen_prom_b_smf_writer_module.py --debt <rev> # before/after bytes
    python3 notes/gen_prom_b_smf_writer_module.py --splice     # write it into the .s

Toolchain: `tlcs900_backend @ 6f456a19f05b`
(`6f456a19f05bf94696728e89e74a53ed62dc9adf`) — stated because every code byte
here is decided by a decoder, and this tree has already been burnt by two lanes
measuring with two different builds.

---

## The question

`notes/DATA-CENSUS-2026-09-02.md` §8 lists **prom_b `0x07669D-0x0779D5`, 4,920
bytes**, graded *self-admitted*, shape hint *MIDI, ptr-table*. Inside it, at
file offset `0x077836`, sits a Standard MIDI File header:

    4D 54 68 64  00 00 00 06  00 00  00 01  00 60      MThd, len 6, format 0, 1 trk, 96 ppqn
    4D 54 72 6B  00 00 00 00                           MTrk, length field = ZERO
    00 FF 03 0F  "WSA    " ...                         then a meta event

**The zero length is why no walker ever found it.** Every tool that reads a
chunk length and steps forward reads 0 and goes nowhere.

## The answer, in one line

It is an **export template**, not music: 33 bytes of file opening that the
firmware copies into its output buffer, followed by a **separate 66-byte word
table** that is not MIDI at all. The zero length is a placeholder the writer
backfills from a byte count when the track is closed.

## Why 33 and not 99, and not 415

The extent is not read off the bytes — it is **the difference between two
addresses the firmware itself names**. prom_b holds four byte-identical 99-byte
copies (0xF7493F, 0xF760BF, 0xF768F0, 0xF77836) and, for each of the three live
ones, the image spells exactly four interior offsets as 32-bit immediates:

| offset | instruction | then | bytes |
|---|---|---|---|
| +0x00 | `ld XIY,<tpl>` | `ld BC,0x0007` / `ldirw` | 14 |
| +0x0E | `ld XIY,<tpl+0x0E>` | `ld BC,0x0004` / `ldirw` | 8 |
| +0x16 | `ld XIY,<tpl+0x16>` | `ld BC,0x000B` / `ldir` | 11 |
| +0x21 | read **five** times as `<base>+HL` | | the word table |

14 + 8 + 11 = 33 = 0x21. The third copy run ends exactly where the fourth
address begins.

The declared meta length is 15 and only 7 name bytes are in ROM. The next
instruction supplies the rest: `ld XIY,0x000021C8` / `ld BC,0x0008` / `ldir`.
**7 from ROM + 8 from RAM = 15.** So `"WSA    "` is a prefix and the song or
file name is appended at export time.

## Why the MTrk length is zero — with a witness

`0xF7789A` computes

    (0x126C) * 1024  +  (cursor - 0x60A700)  -  22

and stores it **most significant byte first** into `(0x10C4)`–`(0x10C7)` — the
SMF chunk-length byte order, not this CPU's. `(0x126C)` counts the 1,024-byte
output windows already flushed; 22 is `MThd` + its 6 payload bytes + `MTrk`.

★ The witness that those four RAM bytes ARE the length is **copy A**, which is
not identical to the others in how it is used: at +0x0E it runs `ldir` with
BC=4 — copying `MTrk` **only** — and then writes `(0x10C4)` and `(0x10C6)` into
the file, in the placeholder's four bytes. Copies B and D run `ldirw` with BC=4
and ship the zeros.

[Named in the source 2026-10-03 (`wsa1/include/wsa1_ram.inc`): `SmfOut_WindowsFlushed` (0x126C),
`SmfOut_TrackLength` (0x10C4..0x10C7), `SmfOut_Tempo` (0x108C..0x108E) and, from
FINDINGS-prom_b-for-the-mame-driver.md, `Disk_FileName` (the 8.3 field 0x21C8..0x21D2) -- 245 operands.
`(0x119A)` stays a number: one use builds a Control Change status from it, but others compare it with
0x7F and write it as a word.]

## It really is a MIDI writer

* `0xF77918` emits a variable-length delta time from `(0x1193)` and then
  `0xFF, 0x51, 0x03` followed by `(0x108E)`, `(0x108D)`, `(0x108C)` —
  **`FF 51 03 tttttt`, the SMF Set Tempo meta event**, most significant byte
  first. `0xF778D2` stages those three bytes with 60000·x, 40000·x/24000 and
  ·1000 — a tempo conversion.
* `0xF76E64` and `0xF76E6C` are two 8-byte SMF SysEx events,
  `00 F0 05 7E 7F 09 01 F7` and `... 09 02 F7` — **GM System On** and **GM
  System Off**. `0xF76F4A` loads the first, `bit 2,(0x7F4D)` and `jr NZ` choose
  between them, and the loop at `0xF76F66` writes the chosen 8 bytes.
* `0xF77982` builds `0xB0 | channel` from `(0x119A)` — a Control Change status.
* `0xF77990` computes `(0x107E) + BC - (0x1082)` into `(0x11AA)` — a delta time
  as a tick difference — and calls `0xF77BDF`.

## The 66 bytes at +0x21 are not MIDI

32 little-endian 16-bit values plus `0xFFFF`: 0x0000, 0x0040 … 0x0800. The
reader is `ld XDE,<base>` / `ld HL,(XDE+HL)` at 0xF76FB9 with HL = (a byte from
the RAM table at 0x603422) × 2, and the value reaches `lda XIY,XIY+HL` on
XIY = 0x006036A0. So they are **byte offsets into a 0x40-strided array of
records in RAM**, and 0xFFFF means "no record".

⚠ The step is 0x40 everywhere **except** between slots 7 and 8, where it is
0x80: the record at 0x0200 is skipped. That is in the ROM and identical in all
four copies. **What occupies the skipped slot is not established.**

★ This retires the standing `Unknown: what the 0x40-strided bytes after offset
0x21 are. They are NOT claimed here.` on `SmfFileTemplate_F7493F` and
`SmfFileTemplate_F760BF`.

## The fourth copy is an orphan

Not one 32-bit word in prom_a, prom_b, prom_c or prom_d holds any address in
`[0xF768F0, 0xF76953)`, while each live copy is named at four interior offsets.
⚠ A computed address cannot be excluded by a scan; the claim is about the scan,
and the header says so.

## The trap this lane walked into, and how it was caught

A byte scan finds **12** 32-bit words in the four images landing inside the code
spans. Nine are coincidences — `78 f7 00` (`jrl T`) and `76 f7 00` (`jrl Z`)
put `f7 00` in the middle of a long branch, and this image is full of them. The
three real ones are operands, and each has an `ld XRR,imm32` opcode (0x40–0x47)
in the byte in front of it:

    ld XIX,0x00F7682E   ->  an 8-entry byte lookup table  00 00 00 40 40 60 60 7F
    ld XIY,0x00F76E64   ->  the GM System On SysEx record
    ld XIY,0x00F76E6C   ->  the GM System Off SysEx record

**All 24 of those bytes round-trip happily as instructions.** The byte gate
cannot object; the linear decode frames them as `nop`, an unencodable `db`,
`ldx` and `ld XWA,0x7f606040`. Only the operands say otherwise, and they are
now carved out as typed data.

⚠ One byte-scan hit is also a false positive on the template itself:
`0x00F77850` appears at prom_b 0xF47B0E, but 0xF47B0B is `ld (0x33e0),WA` and
0xF47B0F is `jrl T,0xf47c09`, so the "pointer" straddles two instructions.

## What the 4,920 bytes are

    code    4,186   six spans, EACH ENDING ON A `ret` AT ITS BLOCK BOUNDARY
    data      352   2 SMF headers (33), 2 word tables (66), 2 SysEx records (8),
                    1 byte table (8), and the 130 bytes already typed
    fallback  382   `.byte` rows standing in for instructions llvm-mc cannot
                    encode -- real source, produced by a verified round trip
    ------  -----
            4,920

Measured with `--debt`:

    08d0c4e8  raw `.byte` debt 4790  typed data 130  fallback   0  instr bytes    0 (0 lines)
    HEAD      raw `.byte` debt    0  typed data 352  fallback 382  instr bytes 4186 (1541 lines)

## What is still not known

* What the 0x40-strided RAM array at 0x006036A0 holds, and why slot 8 is
  skipped.
* What the eight bytes at RAM `(0x21C8)` are — the earlier pass called them a
  filename field; that is not re-derived here.
* What the 8-entry table at 0xF7682E maps. Its reader is a three-instruction
  routine and nothing else uses it.
* What distinguishes the three live writer modules from each other. They fall
  into two pairs by neighbourhood duplication — {0xF7493F, 0xF768F0} share 228
  bytes and {0xF760BF, 0xF77836} share 280 — but no caller was traced.
* Every routine in the 4,186 converted bytes is `sub_XXXXXX`. Semantic naming
  is deferred by the push's brief.
