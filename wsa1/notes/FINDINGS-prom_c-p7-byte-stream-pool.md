# The 65,972-byte pool at prom_c 0xFCD0F7, and the port its bytes leave by

Wave 5 round 2, 2026-08-25.  Reproduce everything with

```
python3 notes/gen_prom_c_p7stream_pool.py --verify   # the container: framing, tiling, counts
python3 notes/gen_prom_c_p7stream_pool.py --census   # objects, opcodes, which streams are clean
python3 notes/prom_c_dsp_port.py --verify            # the transport: which port, which lines
python3 notes/prom_c_dsp_port.py --diff              # the three writers, byte for byte
python3 notes/prom_c_pool_frontier_delta.py          # what this did to the frontier tool
python3 scripts/analysis/assert_byte_identical.py    # PASS
```

Two things were established, and they are independent of each other: **what the bytes are**
(a relocatable byte-code container) and **where they go** (port P7).

---

## 0. ⚠ What is NOT established, first

* **Which chip is on the other end.**  The bytes leave by P7 — that is an instruction
  operand — to one of three destinations selected by an argument.  The SX-WSA1R carries
  three uPD6383GF DSPs, and three-and-three is *consistent*; it is not proof, and no ROM
  byte names a part.  Nothing in this file calls the destination a DSP.
* **What any stream MEANS.**  The opcodes are named for what the interpreter DOES with the
  payload — how many bytes it consumes, which base it adds — never for a musical role.
* **The second consumer.**  130 of the 297 streams contain at least one record whose payload
  is not a whole number of the interpreter's groups.  Those cannot be what `P7Stream_Run`
  runs.  The container is the same; the payload convention is not, and the routine that
  reads them has not been found.
* **The six DATA tables** inside the pool are byte-exact and labelled; only one of them
  (`P7Stream_Data_FD4B85`) has a layout an instruction fixes.

---

## 1. The framing, and why round 3's walk desynchronised

Round 3 left the region as one `.incbin` with this header:

> "a 16-bit big-endian length followed by that many bytes walks `0xFCD0F7 → 0xFCD0FE →
> 0xFCD105 → 0xFCD10C → 0xFCD119` … the walk then desynchronises at `0xFCD119`."

The length is **12 bits, not 16**.  The top nibble of the first byte is an OPCODE:

```
    byte 0:  bits 7:4 = opcode        bits 3:0 = length[11:8]
    byte 1:                           length[ 7:0]
    length counts the two header bytes.   opcode 0xF = END, record length 2.
```

read straight out of the interpreter at `0xF9A6C4-0xF9A702`:

```
  F9A6C4  ld A,(XBC) / and A,0xf0 / cp A,0xf0 / jrl Z,<ret>     opcode 0xF ends the stream
  F9A6D9  ld A,(XBC+1)                       -> HL              length[7:0]
  F9A6E3  ld A,(XBC) / and A,0x0f / sll 8,WA / add WA,HL        length[11:8]
  F9A6EF  dec 2,WA                                              payload = length - 2
  F9A6F4  inc 2,XBC                                             cursor += 2
  F9A6F9  ld IY,(XIZ+0xec) / srl 4,IY                           opcode -> dispatch
```

⚠ **"Framing CONFIRMED for the first four records" was true and still misled.**  Four is
exactly how many records a 16-bit reading gets right when the opcode of all four is zero.
The first record whose opcode is non-zero breaks it, and the first record whose length
exceeds 255 breaks it the other way.

## 2. The opcodes, from their own dispatch arms

The dispatcher at `0xF9AD84` has arms for 0, 1, 2, 3, 4, 5 and 14 and for nothing else —
and eight of the sixteen opcode values never occur in the whole 65,972 bytes.

| op | arm | payload shape | relocation |
|---:|---|---|---|
| 0 | `0xF9A705` | 3 head bytes, then groups of 5 | 12-bit field += record byte 1 |
| 1 | `0xF9A905` | 3 head bytes, then groups of 5 | 12-bit field += record byte 0 |
| 2 | `0xF9A9F0` | 3 head bytes, then groups of 4 | middle byte += record byte 4 |
| 3 | `0xF9AAFB` | 1 head byte, a 16-bit field, then raw bytes | 16-bit field += record byte 3 |
| 4 | `0xF9AB91` | exactly one byte | none |
| 5 | `0xF9ABA8` | 3 head bytes, then groups of 5 | 12-bit field += record byte 2 |
| 14 | `0xF9AD40` | 1 head byte, then raw bytes | none |
| 15 | — | END | — |

So this is a **relocatable object format**.  `P7Stream_Run(stream, index, record_table)`
reads a SIX-byte record at `record_table + 6*index - 6` — the stride and the 1-based index
are the instruction operands `ld A,0x06 / mul WA,(XIZ+0x0c) / dec 6,XWA` at `0xF9A652` — and
uses bytes 0..4 as five relocation bases and byte 5 as the DESTINATION unit.  The same
stream is loaded somewhere else by changing one six-byte record.

## 3. Why the framing is believed — four independent checks

All four are assertions in `gen_prom_c_p7stream_pool.py --verify`, which exits non-zero on
any failure.

1. **It tiles.**  Walking the length field from `0xFCD0F7`, and treating a walk that never
   reaches an END record as a data object bounded by the next pointed-at address that does,
   produces **307 objects covering 0xFCD0F7-0xFDD2AA with no gap and no overlap** (`0xFDD2AB`
   is the exclusive end, and the first byte of the table zone that follows) — 297
   streams (60,385 B), 6 data tables (769 B) and 4 directory objects (4,818 B).  One wrong
   length anywhere desynchronises everything after it.
2. **Opcodes.**  All **1,832** records carry a known opcode — but not all of them through
   the dispatcher.  ⚠ CORRECTED 2026-08-25 (round-2 audit F4): the **297** END records carry
   opcode 15, and opcode 15 has **no arm at `0xF9AD84`**.  `P7Stream_Run` tests for it itself
   — `ld A,(XBC) / and A,0xf0 / cp A,0xf0 / jrl Z,0xf9adb0` at `0xF9A6C4-0xF9A6CC`, and
   `0xF9ADB0` is its own `pop XIX / pop HL / unlk XIZ / ret` epilogue — so an END record
   returns before the dispatch chain is reached.  The other **1,535** carry one of the seven
   opcodes (0, 1, 2, 3, 4, 5, 14) the chain at `0xF9AD84` does have an arm for, and **eight**
   of the sixteen opcode values never occur at all.  The script's `VALID_OPS = {0,1,2,3,4,5,14}`
   always had this right; only the prose said "every opcode has an arm".
3. **Pointers.**  Every 32-bit pointer into the region from anywhere in the ROM lands on a
   record boundary or an object start, with thirteen exceptions — all thirteen in a
   record's raw payload, **none** on a record's second header byte, which is the case that
   would refute the framing.  The thirteen are labelled `P7Stream_Inner_XXXXXX` in the
   source and listed by `--verify`.
4. **The interpreter's own arithmetic, which is the strongest of the four.**  Opcode 4's arm
   consumes exactly ONE payload byte, so every opcode-4 record must have length 3 — and all
   **266** of them do.  And for the **30** streams that a literal call site provably hands to
   the interpreter (74 sites match the compiler's six-instruction argument pattern), every
   opcode-0/1/5 record's payload is a whole number of the interpreter's five-byte groups:
   **14 of 14, zero exceptions.**  Two framings derived from different halves of the
   machine agree exactly where they can be compared.

### ★ The relocation-record tables pass a last-entry test the call sites supply

`P7Stream_Data_FD4B85` is 42 bytes and holds SEVEN six-byte records; two tables start inside
it, at `0xFD4B85` and `0xFD4B97`, because both addresses appear as the third argument at call
sites.  The highest index any call site passes is **3** for `0xFD4B85` and **4** for
`0xFD4B97`, and

```
0xFD4B85 + 6*3 = 0xFD4B97     exactly the start of the second table
0xFD4B97 + 6*4 = 0xFD4BAF     exactly the end of the object
```

so each table's record count is fixed by the call sites' own arithmetic and lands on a
boundary that was derived independently.  Both are asserted by `--verify`.  Record byte 5 —
the destination — reads 0, 0, 1 down the first table and 0, 0, 1, 2 down the second, i.e. all
three destinations are used and neither table indexes past its own data.

## 4. The four directory objects at the end, which tile the last 4,818 bytes

| object | extent | shape |
|---|---|---|
| `PoolDir_Records` | `0xFDBFD9-0xFDC550` | 56 × 25 B: four stream pointers, two `DescriptorStrings` pointers, one byte |
| `PoolDir_IndexMap128` | `0xFDC551-0xFDC5D0` | 128 bytes, each a record index 0..55 |
| `PoolDir_FieldRecords` | `0xFDC5D1-0xFDD1CA` | 56 records, **every length a multiple of 7** |
| `PoolDir_FieldRec_PtrTable` | `0xFDD1CB-0xFDD2AA` | 56 × u32, ending on the region's last byte |

**The stride 25 is an instruction operand**, not a guess: `0xFA2B44` is
`ld A,(XBC) / mul A,0x19 / extz XWA / inc 8,XWA / add XWA,0x00FDBFD9 / ld XBC,(XWA)`, and
`0xFA2B6D` is the same without the `inc`, so the two sites read fields +8 and +0 of the same
25-byte record.  **The count 56 has three independent witnesses**: 56 × 25 reaches `0xFDC551`
exactly, the 128-byte index map takes every value 0..55 and no other, and the 56-entry
pointer table ends exactly **at** `0xFDD2AB` — the exclusive end of the region, whose last
byte is `0xFDD2AA`.  Last-entry test: the last record (`0xFDC538`)
still carries four in-region stream pointers, and the last pointer-table entry is
`0xFDCE2F`.

The 56 pointers are distinct and, laid end to end, tile `0xFDC5D1-0xFDD1CA` exactly — so the
records' lengths are fixed by the pointers themselves and not by a chosen stride.  That every
one of those 56 lengths is a multiple of 7 is then a property of the data.

---

## 5. ★ EMULATION GAP G ADVANCED (not closed): the bytes leave by PORT P7

`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap G asks *"which port do the microcode
BYTES leave by — `0x00E00000`, or something not yet reached?"*  **Neither.**  There is no
memory-mapped path at all: it is a hand-rolled parallel handshake.

⚠ **What is established and what is not.**  Gap G's title is *"What does the DSP microcode
upload do, and what answers READY?"*  This section answers the BYTE PATH and identifies the
pin the firmware treats as ready.  It does **not** say what is on the other end — three
destinations and three uPD6383GF DSPs in the parts list is a consistency, not a proof — and
for gap G's second half it locates `bit 0,(P9)` and what the firmware does with it, which is
not the same as knowing what the pin is wired to.  "Advanced", not "closed"
(round-2 audit F6).

| line | pin | evidence |
|---|---|---|
| data | **P7** (SFR 0x13), written whole | 9 × `ld (0x0013),(XIZ+0x08)` in prom_c, all inside `0xF9A163-0xF9A645` — three writers × three destination arms |
| destination strobe | **P5 bit 4** / **P5 bit 5** / **P2 bit 7** | 6 `res` + 7 `set` each; two of each per arm plus one `set` in the entry preamble |
| data valid | **PB bit 5** | 9 `res` — one in every one of the nine arms |
| command / data | **P5 bit 3** | only **3** `res` against nine arms, and all three are in `P7Byte_SendCmd` |
| enable | **PB bit 6** | 1 `set`, 0 `res`, in the whole module |
| ready in | **P9 bit 3** | the 18 poll sites gap G counts, 6/6/6 across the three writers |
| timeout | `0x1F40` = 8000 spins | 18 sites arm it; on expiry `(0x00F35C) := 1` **and the byte is sent anyway** |

The per-byte sequence, from `P7Byte_SendCmd`'s destination-0 arm (`0xF9A197-0xF9A210`):

```
  res 4,(P5)                     ; strobe low
  wait P9.3 != 0, <= 8000 spins  ; peer ready
  set 4,(P5)
  ld (P7),<byte>                 ; DATA ON THE BUS
  res 5,(PB) / res 3,(P5) / res 4,(P5)
  wait P9.3 != 0, <= 8000 spins  ; peer took it
  set 4,(P5) / set 3,(P5) / set 5,(PB)
```

**What this buys the emulator.**  The driver refuses to answer `0x08` on P9 because that
would be a fabricated ready signal on a pin nobody had read.  The pin is now read: it is the
acknowledge of a byte write on P7.  A device that raises P9 bit 3 *because it consumed a
byte* is a real handshake, not a constant, and gap G says that is worth "most of a minute"
of emulated boot.

### Three writers, one per byte ROLE

| routine | old name | trace it prints | role |
|---|---|---|---|
| `P7Byte_SendCmd` | `sub_F9A163` | `\n\r[XX]\n\r` | a record's first byte; holds P5 bit 3 low |
| `P7Byte_SendData` | `sub_F9A31A` | `XX ` | payload |
| `P7Byte_SendArg` | `sub_F9A4B0` | `[XX] ` | a record's header arguments |

`P7Byte_SendData` and `P7Byte_SendArg` are **406 bytes each and differ in exactly TWO
bytes** — the `calr` displacement at `0xF9A331` against `0xF9A4C7` — so they are the same
handshake and differ only in which trace helper they call.  `P7Byte_SendCmd` is 439 bytes;
its extra 33 are its six-instruction entry preamble (18 B) plus the three
`res 3,(P5)`/`set 3,(P5)` pairs in its arms (18 B), less the single `set 3,(P5)` the other
two do have at entry (3 B).

### The trace is real, and it is on MIDI OUT

When `(0x00F35A) != 0`, every byte is formatted as two ASCII hex digits by `Format_HexByte`
(`add C,0x30` for 0..9, `add C,0x37` above) and handed to `MIDI_Tx_SendUntilFF`.  A service
technician can watch the entire upload leave the MIDI port.  ⚠ What sets `(0x00F35A)` is not
established.

### Gap G's second half: P9 bit 0

`bit 0,(P9)` occurs **exactly once** in prom_c, at `0xFB050B`.  Its only effect is bit 2 of
the RAM word `(0x0014FF)` — set when the pin reads LOW, cleared when it reads HIGH.  The
routine then installs the bank base table at RAM `0x00D7ED`: `0x00F00000, 0x00F00000,
0x00E80000, 0x00E90000, 0x00EA0000, 0x00EB0000, 0x00010000, 0x00010000` — the flash and wave
banks.  So it is a **strap sampled once, beside the bank map**, and its flag is then read at
seven sites in the voice module (`0xFA72F0` to `0xFAD797`).  ⚠ Which physical option it
selects is NOT established.

---

## 6. What this did to the numbers

| | before | after |
|---|---:|---:|
| prom_c substantive | 318,095 (60.7%) | **384,067 (73.3%)** |
| prom_c `.fill` filler | 129,216 | 129,216 — **unchanged** |
| prom_c `.incbin` | 76,977 in 6 spans | **11,005 in 5 spans** |
| tree total substantive | 912,581 (43.5%) | **978,553 (46.7%)** |

The gain is **+65,972 substantive bytes and zero filler**.

### ⚠ And what it did to `prom_c_frontier.py`, which is a cost, not a gain

`python3 notes/prom_c_pool_frontier_delta.py` runs the frontier tool's own code against the
before and after span lists:

```
BEFORE (pool as .incbin): 132 distinct target(s) from 132 site(s); 111 land inside the pool
AFTER  (pool converted) :  49 distinct target(s) from  49 site(s);   0 land inside the pool
                          111 gone, 28 NEW targets invented by the pool's own data-decode
```

132 − 111 + 28 = 49, exactly.  **All 49 surviving from-sites are inside regions this tree has
established as DATA**, so every one is a phantom of linear disassembly and the frontier can
no longer rank anything in prom_c.  This is the same effect the f64-pool conversion had at a
smaller scale (`notes/FINDINGS-prom_c-f64-pool.md` §6).  Rank prom_c's remaining work by the
`.incbin` list instead:

```
0xFCC81A-0xFCCA81    616   fp constant pool, stride deliberately not established
0xFDF7E0-0xFE0A6C  4,749   head of the power-on initialiser image
0xFE0A6D-0xFE11EF  1,923   head of copy A
0xFE1361-0xFE1697    823   rest of copy A + the gap between the copies
0xFE1698-0xFE21E5  2,894   copy B, which nothing literally references
```
