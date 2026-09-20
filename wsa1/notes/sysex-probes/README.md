# SysEx probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |
| `sysex_error_codes.py` | Which internal status code raises `ERROR 40!`, `ERROR 41!` or `ERROR 42!`, and where in prom_a is each one raised? | `python3 wsa1/notes/sysex-probes/sysex_error_codes.py` (table) or `--sites` (every raise site) |
| `sysex_bulkdump_tx.py` | What does the machine put on the wire when SYSEX BULK DUMP -> SEND is pressed: which menu row dumps what, what the frame header says, and how the checksum and the block size are computed? | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py` (tables) or `--frames` (block arithmetic + a worked checksum) |
| `sysex_command_map.py` | Walking the grammar to the BOTTOM (not depth 8): what does each accepted sequence make the instrument DO? Covers `25`, `7E`-as-third-byte, the `2D` subtree and the dump request. | `python3 wsa1/notes/sysex-probes/sysex_command_map.py` (tables) or `--paths` (all 7542 sequences) |
| `sysex_dump_categories.py` | WHICH of the five bulk-dump categories emits WHICH data header, in what order, and what the header's 21-bit address field means. | `python3 wsa1/notes/sysex-probes/sysex_dump_categories.py` (tables) or `--wire` (each header as transmitted) |

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


## `sysex_command_map.py` — signal being read

Both load bases are asserted before anything is read: prom_b must hold
`F0 50 23 7E F7` at `0xF4FEB4`, prom_a must hold `00 03 05 04 02` at
`0xF99AE3`.

* **A THIRD handler table.** `0xF4F916`, 34 entries, named by the one
  instruction `add XWA,0x00f4f916` at prom_a `0xFB28A1`.  `0xF4F800` /
  `0xF4F888` send almost everything to the *same* default, `0xFB2820`,
  which is the bulk-transfer **session loop**; inside that loop
  `sub_FB2877` re-dispatches the very same command number through
  `0xF4F916`.  So a command's real behaviour is in the THIRD table, not
  the first two.  Nine slots of `0xF4F916` are the `2D` category
  handlers; one is the `7E` continuation; two are the handshake.
* **`25` = tempo, proven from three independent directions.** The
  receiver (`0xFB33FE`) and the transmitter (`0xFB3355`) each bound the
  value to `0x0028..0x012C`, and so does the **sequencer clock
  programmer** at `0xFAA350`, whose out-of-range default `ldw WA,0x78`
  is 120.  The sender's 3-byte prefill at prom_b `0xF4FA76` is
  `08 07 F7`, which under the receiver's own `lo | hi<<4` decodes to
  exactly 120.
* **The `2D` subtree is the receive side of the SEND button.** The
  script checks every accepted sequence's address and size septets
  against the nine literal transmit templates at `0xF4FEF8..0xF4FF55`;
  all eight categories match, including the one template whose size is
  appended at run time (SEQUENCER part 3) being the one sequence the
  trie pins only three septets deep.
* **The dump request.** Five arms at `0xFB5122..0xFB514A` each write a
  job code to `(0x60F802)`; the script reads the codes out of the
  instruction bytes and checks them against the SEND menu's own row→job
  table at `0xF99AE3`, and checks each request's area byte against that
  category's dump address top septet.  Four of the five arms are
  reachable from the wire; `0x1D` is not.

### Pass criterion

Every assert is silent and the script prints `OK`.  The headline numbers
are **16** sequences under `2D` over **8** command numbers, **7542**
accepted sequences over **27** command numbers, tempo bounds **40..300**
with default **120**, and **six** command numbers (`0x06 0x0D 0x0F 0x10
0x11 0x1D`) that have a handler and no accepted sequence.

### Trap

A node's `0xFF` record carries the parser's **depth-specific error
code** in the same byte position a match record carries the command
number — `0x07` at the root, then `0x08`, `0x09` … up to `0x10`.  Those
overlap the real command numbers `0x07`-`0x10`.  A walk that does not
break on `0xFF` invents commands.  The script breaks on it and asserts
the root terminator is `0x07`.

The other trap is `sysex_grammar_dump.py --paths`, which truncates at
depth 8 and therefore **cannot see** commands `0x0B`, `0x0C`, `0x0E`,
`0x12`-`0x17`, `0x19` or `0x1B`-`0x1F` at all.  Reading its output as a
complete list is how the `2D` subtree and the dump request were missed.

### Two gates the `25` message passes through

Both are checked from the instruction bytes, and both sit in the
receiver *and* the transmitter, identically:

1. **The model-variant strap `(0x0000C4)`.** `sub_FB5FF5` picks
   `0xF4FE6A` (six zero words, everything allowed) when the strap is 1
   and `0xF4FE76` (`0xFFFF` at indices 3 and 5) otherwise.  Index 5 is
   the `25` message; index 3 is the SEQUENCER **block store** — so on
   the other variant a SEQUENCER dump is still acknowledged but its
   bytes are never written.  The SYSTEM/PART&MIDI handler calls the
   same store unconditionally; the script asserts both call sites.
2. **MIDI filter byte `(0x7F38)` bit 3.** The eight-entry row
   dispatcher `JumpTable_F9AB84` ends on the editor that writes
   `(0x7F38)` with mask `0x0F`, and the matching painter reads
   `(0x7F38) & 0x0F` — so the eighth row of the MIDI INPUT&OUTPUT
   FILTER page, whose caption list ends `EXCLUSIVE`, is this byte, and
   "ON" sets bit 3.  ⚠ The row→caption binding is by POSITION (two
   independent orderings agree: the eight setters and the eight
   painters) — no instruction quotes the caption.


## `sysex_dump_categories.py` — signal being read

Both load bases are asserted first, as above.

* **The transmit call graph is DECODED, not assumed.** Menu row → job code
  (`0xF99AE3`) → job routine (`JumpTable_FB2081`) → category routine → part
  emitters. Every edge is a `calr` (`1E disp16`) or `call` (`1D imm24`) whose
  target the script computes from the bytes, and every chain is closed by the
  `RET` that follows it, so the number of parts is the ROM's statement, not a
  guess.
* **TOTAL KEYBOARD's order is the `calr` chain** in `sub_FB23E2`:
  SYSTEM,PART & MIDI → SOUND → COMBINATION → SEQUENCER. The script asserts
  that the four routines the four single-category jobs run are exactly the
  four in that chain.
* **Each part emitter names one template, one descriptor writer and one step
  id.** The scan window for each emitter is bounded by the NEXT routine in
  the module — no fixed window length is guessed — and the counts are
  asserted, so a window that ran into a neighbour would fire.
* **★ The address field is NOT an internal address.** The script prints the
  source extent beside the dump address for every part, and asserts they
  differ. The clincher is a negative that kills any affine map at once:
  SOUND and COMBINATION **abut in CPU 2's flash**
  (`0xE80000 + 0x40000 == 0xEC0000`, asserted) and are **0x0C0000 apart** in
  the dump address space.
* **★★ The receive side matches the address+size pair LITERALLY.** The
  grammar trie's `2D` subtree accepts exactly the eight byte strings the
  transmitter sends and nothing else; the script asserts set equality
  between the two sides, and that each accepted string's command number
  reaches a handler that calls the **same descriptor writer** the transmit
  side used. Nothing anywhere decodes the address arithmetically.
* **The one field that IS a number** is SEQUENCER part 3's size. The
  transmit encoder (`sub_FB6EE9`) splits it `>>14, >>7, >>0` masked to seven
  bits; the receive decoder (`sub_FB741A`) rebuilds it `<<14, <<7, <<0` from
  parse-record fields `0x0C/0x0D/0x0E`. Both shift literals are asserted.
  The value itself is `0x10 ×` the sequencer's own memory-use counter
  (`mul XBC,(0x603452)` at `0xFB7757`), capped by the static extent 0x50C00.
* **The SEQUENCER availability gate.** `sub_FB5FF5(3)` returns a word from
  `0xF4FE6A` when the model-variant strap `(0x00C4)` is 1 and from
  `0xF4FE76` otherwise; the second table holds `0xFFFF` at index 3, and on
  that arm `sub_FB2587` returns before sending anything — **including the
  end-of-category message**, which is inside the guarded block.

### Pass criterion

Every assert is silent and the script prints `OK`. The headline results are
the four dump-address bases `0x080000` SOUND / `0x100000` SYSTEM,PART & MIDI
/ `0x140000` COMBINATION / `0x180000` SEQUENCER, the eight accepted receive
strings, and the TOTAL KEYBOARD order.

### Trap

`62 08 00` is `0x188400`, not `0x188000` — the middle septet carries
`0x08 << 7 = 0x400`. Dropping it breaks the one arithmetic the addresses do
satisfy, `addr(part N+1) − addr(part N) == size(part N)`, which the script
asserts for all three multi-part categories.

The other trap is printing a dump address as three hex bytes of its VALUE
(`18 84 00` for `0x188400`). Those are not the bytes on the wire, and
`0x84` cannot appear in a SysEx data byte at all. The wire bytes are the
septets: `62 08 00`.
