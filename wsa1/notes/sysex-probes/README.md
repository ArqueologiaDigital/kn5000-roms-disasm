# SysEx probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |
| `sysex_error_codes.py` | Which internal status code raises `ERROR 40!`, `ERROR 41!` or `ERROR 42!`, and where in prom_a is each one raised? | `python3 wsa1/notes/sysex-probes/sysex_error_codes.py` (table) or `--sites` (every raise site) |
| `sysex_bulkdump_tx.py` | What does the machine put on the wire when SYSEX BULK DUMP -> SEND is pressed: which menu row dumps what, what the frame header says, and how the checksum and the block size are computed? | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py` (tables) or `--frames` (block arithmetic + a worked checksum) |

## Signal being read

`sysex_grammar_dump.py` reads `original_ROMs/wsa1_prom_b.ic13` at load base
`0xF00000` (asserted, not assumed: the literal template block at `0xF4FEB4`
must start `F0 50 23 7E F7`).

* ROOT table `0xF5115B` — named by prom_a `0xFB63FC` `add XBC,0x00f5115b`,
  bounded to 15 records by `ld L,0x0f` (`0xFB63F2`) / `dec 1,L` (`0xFB649A`),
  stride 6 from `inc 6,DE`.
* Record = `[0]` match byte, `[1]` command id (`0` = descend), `[2..5]` LE32
  next node. `0xFF` in `[0]` ends a node (`0xFB6407`); `0xFE` is a wildcard
  (`0xFB64C9`).
* Handler tables `0xF4F800` (message arrived on the interrupt-side ring) and
  `0xF4F888` (foreground ring), 34 entries each, bound `cp A,0x22 / jr nc` at
  `0xFB2194` and `0xFB2291`. The two tables tile — that is the last-entry test.

## Pass criterion

Base check prints OK; the ROOT prints exactly 14 command bytes plus the
`0xFF` terminator; the tiling assert does not fire.

## Trap

A `next` pointer may aim into the **middle** of a record list. A node is
"from here forward to the first `0xFF` match byte" and can be far longer
than a short record cap allows — with a 64-record cap one node's tail runs
into the next node's records and manufactures command ids that are not
reachable. The default cap is deliberately generous.

## `sysex_error_codes.py` — signal being read

The status byte is **field 4 of the parse record** whose pointer is RAM
`(0x60FCD8)`; prom_a `sub_FB6219` (0xFB6219) is the setter and `sub_FB62D3`
(0xFB62D3) the getter, both 16-way jump tables over offsets +0..+15.

* `sub_FB7DFE` (0xFB7DFE) reads field 4 at the end of a session:
  `0` -> message `0x23` (`COMPLETED!`), `0x21` -> screen 0xB3 with no popup,
  anything else -> `STATUS_MAP[field4]`.
* `STATUS_MAP` = prom_b `0xF511C7`, named by the ONE instruction
  `add XWA,0x00f511c7` at prom_a `0xFB7E54`. The message id lands in RAM
  `(0x2880)` at `0xFB7E5C`.
* `sub_F99098` (0xF99098) paints `(0x2880)`: bound `cp C,0x40`, base
  `*(0xF993B9 + 4*(0x7FC1))` (all three language slots hold `0x00F99121`),
  pair `(start, end) = *(base + 8*code), *(base + 8*code + 4)`.

### Pass criterion

Every assert is silent and the script prints `OK`. The headline ones are
`0x08/0x09/0x0A -> ERROR 40!`, `0x20 -> ERROR 42!`, `0x07 -> ERROR 41!`,
`0x14 (checksum) -> ERROR 41!`, `0x16 -> ERROR 21! (Memory full)`.

### Two independent checks on the index origin

1. `sub_FB7DFE` special-cases `field4 == 0` to message `0x23`, and
   `STATUS_MAP[0]` is `0x23` too — so the table is indexed by the raw
   status with no bias.
2. Each node of the grammar trie ends in a `0xFF` record whose **second**
   byte repeats the depth-specific code the parser pushes (`0x07` at the
   root, `0x08`, `0x09`, `0x0A` below it). The ROM states the depth→code
   map twice, in a table and in ten literals.

### Trap

The `.s` declares only 22 bytes at `0xF511C7` (`AsciiRun_F511C7`) because
the ASCII heuristic stops at the first non-printable byte, `0x0F` at
`0xF511DD`. **The reader has no bound at all**, and statuses up to `0x21`
are raised, so the table is 34 bytes. Reading only 22 loses `ERROR 42`
entirely.

## `sysex_bulkdump_tx.py` — signal being read

Both load bases are asserted first: prom_b must hold `F0 50 23 7E F7` at
`0xF4FEB4`, prom_a must hold `00 03 05 04 02` at `0xF99AE3`.

* **Menu row -> job.** `0xF99AE3` is a 5-byte table the screen-0x79 button
  handler at `0xF99A8F` indexes with `(0x2720) & 7`; the value becomes
  `(0x60F802) | 0x80` and prom_b thunk `T_F408E4` runs `0xFB2049`, which
  jumps through `JumpTable_FB2081` (6 entries, bound `cp BC,5 / jr ugt`).
* **Templates.** Nine fixed messages at `0xF4FEB4`-`0xF4FEE2` and ten data
  headers at `0xF4FEF2`-`0xF4FF60`, each named by exactly one `lda xbc,(imm24)`
  in prom_a; the script prints the naming site next to each one.
* **Address / size.** The six bytes after the model id `0x11` are two
  MSB-first 21-bit septet triples. The script does not assume that: it
  checks that each triple's value equals the byte extent the corresponding
  prom_a descriptor-writer stores (`end - start == size`, then
  `size x blocks == septets`), and that for every category sent in more than
  one part, `addr(part N+1) - addr(part N) == size(part N)`. Four
  independent agreements.
* **Checksum.** `sub_FB7111` (`0xFB7111`) sums from buffer `+0x0F` — i.e.
  every byte of the message except the leading `0xF0` — to the write cursor,
  then `sub WA,WA / sub WA,BC / res 7,A`, and appends that byte plus the
  `0xF7` that sits beside it in the word at `0xF4FE68` (`00 F7`).
* **Block size.** The pack loop `sub_FB7040` stops when the message byte
  count reaches `0xFC` (`cp WA,0x00FC` at `0xFB70A3`). Each source byte
  becomes two nibbles, high first.

### Pass criterion

Every assert is silent and the script prints `OK`. The headline numbers are
`0x20`/`0x960`/`0x40000`/`0xC00`/`0x7800`/`0x300`/`0x16000` for the seven
static transfers, `0xFC` for the block cap, `(0 - sum) & 0x7F` for the
checksum, and 120 / 125 source bytes per frame.

### ★ The cap and the ring agree

A continuation frame is exactly 256 bytes and MIDI-out ring `0x601432` holds
exactly `0x100`. `Ring_Put_0100` does **not** block — it drops the byte and
returns `0xFFFF`, which `Ring601432_PutBlock` ignores — so `0xFC` is the
largest cap that cannot lose a byte. The script asserts the coincidence.

### Trap

One template does **not** agree with its descriptor: `0xF4FF10` says 16
bytes while `0xFB7629` sets size 0, because that template belongs to the
unreferenced routine at `0xFB248A`, which passes count `0x0000` to the link
read. The tree already flags `0xFB248A` as named by nothing. The script
asserts the anomaly explicitly instead of skipping it, so it will fire if
either half ever changes.
