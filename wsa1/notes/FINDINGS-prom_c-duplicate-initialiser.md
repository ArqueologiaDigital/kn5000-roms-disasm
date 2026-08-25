# prom_c carries its power-on initialiser image TWICE, relocated, with one object dropped

> **Renamed in round 4.**  The labels this note cites were prefixed `TG_` / `TG2_`; they are
> now `Dev10C_` / `Dev104_`, because the tone-generator role those prefixes asserted is an
> unproven inference.  See `notes/FINDINGS-prom_c-tone-generator.md` §0.  Nothing else changed.

**Image:** `prom_c` (IC28, CPU 2, base 0xF80000).
**Region:** `0xFE0A6D-0xFE21E5`, plus 118,298 bytes of filler behind it.

Everything here is reproducible from one script:

```
python3 notes/prom_c_dup_image.py --extent
python3 notes/prom_c_dup_image.py --diff
python3 notes/prom_c_dup_image.py --refs
python3 notes/prom_c_dup_image.py --fill
python3 notes/prom_c_dup_image.py --selftest
```

---

## 1. What was known, and why it was wrong-shaped

`notes/FINDINGS-prom_c-tone-generator.md` §9 recorded that the 68-byte reset image at
`0xFE12CF` reappears `0xC2B` bytes later, that a pointer table reappears with its entries
relocated by the same `0xC2B`, and left it for later. A later pass described the region as
*"2,259 bytes repeated at +0xC2B with 37 differing bytes"*.

That description **splits on one delta**, so it necessarily stops where the alignment changes,
and it does change. The real shape:

| segment | bytes | delta | maps to | differing bytes |
|---|---:|---:|---|---:|
| `0xFE0A6D-0xFE133A` | 2,254 | `0xC2B` | `0xFE1698-0xFE1F65` | 33 |
| `0xFE133B-0xFE1360` | 38 | — | **no counterpart at all** | — |
| `0xFE1361-0xFE15E0` | 640 | `0xC05` | `0xFE1F66-0xFE21E5` | 8 |

```
copy A   0xFE0A6D-0xFE15E0   2,932 bytes
copy B   0xFE1698-0xFE21E5   2,894 bytes
```

**`0xC2B - 0xC05 = 0x26 = 38`, which is exactly the size of the object with no counterpart.**
That single arithmetic fact is the whole explanation of the shifting alignment: copy B is
copy A minus the 38-byte block at `0xFE133B`.

⚠ Copy B's last byte, `0xFE21E5`, holds `0x0E`, which is also the filler value that follows, so
the end of copy B is ambiguous by exactly one byte.

⚠ Copy A's start is a real edge: the byte identity does **not** extend one byte backwards
(`--extent` reports the backward walk explicitly).

---

## 2. ★ The missing object is the 0x00104000 reset image, and its size checks out twice

`0xFE133B` is the source of `MemCopyWords(0xFE133B, 0x00D91F, 0x26)` at 0xFB8163 inside
`Dev10C_ResetAllChannels`, and `0x00D91F` is the struct that routine then hands to
`Dev104_WriteAllChanRegs` for each of the 64 channels.

`0x26 = 38 bytes = 19 words`, and `Dev104_WriteAllChanRegs` writes exactly **19** registers of the
0x00104000 device from 19 consecutive words of that struct
(`python3 notes/prom_c_tg_regmap.py --dev104`). The **count argument of a block copy** and the
**field count of an unrolled register writer**, in different routines, give the same 19.

So copy A carries the tone generator's second-device reset image and copy B stops one object
short of it.

---

## 3. ★ Forty of the forty-one differing bytes are relocated pointers

`--diff` decodes every difference:

* **sixteen** 24-bit pointers at stride **6**, at `0xFE1220` onward, each larger by exactly
  `0xC2B` in copy B. That stride is the record size of `Voice_SearchOrder_Records` and the
  count of relocated pointers is its record count — the table's shape is *measured by the
  relocation*, which is a nicer proof than anything in the data itself.
* **four** 24-bit pointers at stride **4**, at `0xFE150F-0xFE151E`, each larger by exactly
  `0xC05`.

Copy B is therefore not a stale duplicate that merely resembles copy A: it is a **relocated**
image whose internal pointers were rewritten to point inside itself.

### The forty-first difference is a single tone-generator parameter

`0xFE12C9` holds `0x0030` in copy A and `0x0020` in copy B. That word is item 10 of
`Dev10C_GlobalRegs_ResetImage`, and `Dev10C_WriteGlobalRegs` (0xFB7715) sends item 10 to **global
register 0x0C04** of the 0x0010C000 device.

Two images of the same initialiser differing in exactly one global register is the shape of a
configuration variant. ⚠ **What the variant is, is NOT ESTABLISHED** — nothing says which one
the machine uses, or why there are two.

---

## 4. ★ Nothing reaches copy B

`--refs` searches every 24-bit little-endian address inside each copy across the whole 512 KiB
image and classifies each hit by the bytes **around** it — an `ld <X..>,#imm32` (`0x40|r` in
front, `0x00` behind), one of the four direct-address prefixes `0xC2/0xD2/0xE2/0xF2`, or a
`call`/`jp` (`0x1D`/`0x1B`). Anything else straddles an instruction boundary.

```
copy A   98 coincidences, 54 hits in an address-operand position
copy B   17 coincidences,  1 hit  in an address-operand position
```

And the one surviving hit for copy B is not a reference either: it is at `0xFE05DC`, inside the
descending 16-bit table at `0xFE05B0` (`... e7 ff | e2 ff | 18 fe | 68 fc | d4 fa ...`), where
the bytes `e2 ff 18 fe` are the boundary between two table **entries**.

⚠ The search is for literals only. A pointer already in RAM, or an address computed at run
time, would be invisible. This is **"no literal reference"**, not "unreachable".

---

## 5. 118,298 bytes of `ret`

`0xFE21E6-0xFFEFFF` contains the single byte value `0x0E` and nothing else — checked over all
118,298 bytes, not sampled (`--fill` prints "1 distinct value"). `0x0E` is the one-byte `ret`
opcode, the same filler as the 3,611-byte run before the vector table. It is now emitted as
`.fill` in `prom_c/wsa1_prom_c.s`, which is why prom_c's converted percentage jumps; that
number should always be quoted with the split, **316 bytes of structured data plus 118,298
bytes of verified filler**.

---

## 6. What is now emitted, and what is still `.incbin`

Emitted with headers in `prom_c/wsa1_prom_c.s`:

| object | address | size | how the size was fixed |
|---|---|---:|---|
| `Voice_KeyTable_Remapping` | 0xFE11F0 | 8 | 0xFF terminator |
| `Voice_Search_Order_List_1` | 0xFE11F8 | 15 | 0xFF terminator; pointed at by record 0 |
| `Voice_Search_Order_List_2` | 0xFE1207 | 14 | 0xFF terminator; pointed at by record 1 |
| `Voice_Search_Order_List_3` | 0xFE1215 | 11 | 0xFF terminator; pointed at by records 2-15 |
| `Voice_SearchOrder_Records` | 0xFE1220 | 96 | 16 relocated pointers at stride 6 |
| `Dev10C_GlobalRegs_ResetImage` | 0xFE12B5 | 26 | 13 fields in `Dev10C_WriteGlobalRegs`; `0xFE12CF - 0xFE12B5` |
| `Dev10C_StagingStruct_ResetImage` | 0xFE12CF | 68 | `MemCopyWords` count argument |
| `Dev104_Reg0800_ResetValue` | 0xFE1313 | 2 | its two neighbours |
| `unexplained_FE1315` | 0xFE1315 | 38 | its two neighbours |
| `Dev104_StagingStruct_ResetImage` | 0xFE133B | 38 | `MemCopyWords` count argument; 19 registers |

★ The four 0xFF-terminated lists total **48 bytes**, which is *exactly* the backing-run length
the KN5000 transplant table quotes for those four names
(`notes/kn5000-label-transplant-generated.md`, run len 48). That is the first independent
thing in this tree to agree with a transplanted name's extent rather than just its bytes.

⚠ The three search lists are **nested**: list 2 is list 1 without its last entry (`0x00`), and
list 3 is list 2 without its last two (`0x81 0x80 0x01`). Entries `0x80-0x86` have the high bit
set and `0x00-0x06` do not, so the lists read as two interleaved groups of seven. Nothing here
says what the entries index.

⚠ Records 3..15 of `Voice_SearchOrder_Records` are all identical
`{Voice_Search_Order_List_3, 02, 05}`; only the first three differ. What indexes the sixteen
records, and what the two trailing bytes are, is not established.

Still `.incbin`, and why:

* `0xFDF7E0-0xFE11EF` — the reference census finds **no** address-operand citation into the
  first 1,787 bytes of copy A (`0xFE0A6D-0xFE1167`; the earliest is `0xFE1168`), and the
  1,923-byte `.incbin` chunk `0xFE0A6D-0xFE11EF` has no established object boundary.
* `0xFE1280-0xFE12B4` (53 bytes) — twenty citations, every one of them a **byte** at a fixed
  address (0xFE1286, 0xFE128A, 0xFE12A9 … 0xFE12B4). That pins fields, not edges.
* `0xFE1361-0xFE1697` and the whole of copy B — copy B is left as one labelled `.incbin`,
  because emitting it as a second set of named objects would double every name in the file for
  an image nothing calls.

---

## 7. What the next pass needs

* The first 1,787 bytes of copy A. Nothing cites them by literal, so their consumer reaches
  them through a pointer — probably one of the sixteen `Voice_SearchOrder_Records`, or one of
  the four relocated pointers at `0xFE150F`.
* Why there are two images. The single differing parameter (global register `0x0C04`,
  `0x0030` vs `0x0020`) is the only handle.
* The four pointers at `0xFE150F-0xFE151E` point at `0xFE14CB`, `0xFE14DC`, `0xFE14ED` and
  `0xFE14FE` — four targets exactly 17 bytes apart, starting 0x2B past the transplant-named
  `Voice_DefaultToneRecord` at `0xFE14A0`. Decoding one would name the group.
