# SysEx probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |
| `sysex_error_codes.py` | Which internal status code raises `ERROR 40!`, `ERROR 41!` or `ERROR 42!`, and where in prom_a is each one raised? | `python3 wsa1/notes/sysex-probes/sysex_error_codes.py` (table) or `--sites` (every raise site) |
| `sysex_bulkdump_tx.py` | What does the machine put on the wire when SYSEX BULK DUMP -> SEND is pressed: which menu row dumps what, what the frame header says, and how the checksum and the block size are computed? | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py` (tables) or `--frames` (block arithmetic + a worked checksum) |
| `sysex_command_map.py` | Walking the grammar to the BOTTOM (not depth 8): what does each accepted sequence make the instrument DO? Covers `25`, `7E`-as-third-byte, the `2D` subtree and the dump request. | `python3 wsa1/notes/sysex-probes/sysex_command_map.py` (tables) or `--paths` (all 7542 sequences) |
| `sysex_param_wire_format.py` | The COMPLETE byte layout of a `2B` / `2C` message: where the data sits, what the count triple means, what a request carries instead of data, what the reply looks like, and what a receiver must compute for the checksum. Ends with worked examples it verifies. | `python3 wsa1/notes/sysex-probes/sysex_param_wire_format.py` (tables + examples), `--lengths` (every multi-byte parameter) or `--capture` (re-check the checksum rule against the real dump) |
| `sysex_param_space.py` | The `2B` and `2C` families: what the bytes after the model id `11` mean, which command id each sequence terminates in, and how `2B` differs from `2C`. | `python3 wsa1/notes/sysex-probes/sysex_param_space.py` (tables), `--params` (every parameter with its accepted value range) or `--paths` (all 7512 sequences) |
| `sysex_dump_categories.py` | WHICH of the five bulk-dump categories emits WHICH data header, in what order, and what the header's 21-bit address field means. | `python3 wsa1/notes/sysex-probes/sysex_dump_categories.py` (tables) or `--wire` (each header as transmitted) |
| `sysex_bulkdump_rx.py` | The RECEIVE side: what picks the destination of an incoming data message, whether an arbitrary address is honoured, what bounds the write, what order the messages must come in, and whether the panel has to be on the SYSEX BULK DUMP screen. | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_rx.py` (tables) or `--order` (the whole in-session dispatch table) |
| `sysex_cross_product.py` | Is this the SAME protocol in the sibling Technics products? Reads the WSA1R, KN5000 and KN1500 grammars out of raw ROM side by side, prints each one's model triple, fixed messages and bulk-dump regions, and asserts what is shared and what is not. | `python3 wsa1/notes/sysex-probes/sysex_cross_product.py` (summary), `--paths` (every accepted sequence), `--kn7000` (the later, incompatible dialect) |
| `sysex_wire_capture_check.py` | Does a dump a REAL machine put on the wire obey the frame format decoded from the ROMs? Checks the handshake, header, nibble payload, 0xFC cap, continuation flag, checksum and declared length of all 2883 messages of a captured SOUND+COMBINATION dump. | `python3 wsa1/notes/sysex-probes/sysex_wire_capture_check.py` (summary) or `--frames` |

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

* **★★★ The DUMP REQUEST names a category BY ITS ADDRESS.** The `2B`
  subtree accepts `F0 50 2B 04 <unit> 11 <addr> <three 0xFE wildcards> F7`
  for exactly four addresses — `20 00 00`, `40 00 00`, `50 00 00`,
  `60 00 00` — and each one's handler writes that category's own SEND-menu
  job code to `(0x60F802)`. The script asserts the four requested addresses
  are exactly the four categories' FIRST-part addresses and that the job
  codes agree with the menu's row→job table. A message with no payload
  still identifies the category by address: that is a second, independent
  witness that the address is a category identifier and not an offset.
  There is no request for TOTAL KEYBOARD, and `0x1D` (job 1, a bare RET)
  has no accepted sequence.

### Pass criterion

Every assert is silent and the script prints `OK`. The headline results are
the four dump-address bases `0x080000` SOUND / `0x100000` SYSTEM,PART & MIDI
/ `0x140000` COMBINATION / `0x180000` SEQUENCER, the eight accepted receive
strings, the four dump-request addresses, and the TOTAL KEYBOARD order.

### Trap

`62 08 00` is `0x188400`, not `0x188000` — the middle septet carries
`0x08 << 7 = 0x400`. Dropping it breaks the one arithmetic the addresses do
satisfy, `addr(part N+1) − addr(part N) == size(part N)`, which the script
asserts for all three multi-part categories.

The other trap is printing a dump address as three hex bytes of its VALUE
(`18 84 00` for `0x188400`). Those are not the bytes on the wire, and
`0x84` cannot appear in a SysEx data byte at all. The wire bytes are the
septets: `62 08 00`.


## `sysex_param_space.py` — signal being read

prom_b at `0xF00000` (the `F0 50 23 7E F7` literal at `0xF4FEB4` **and** the
`F0 50 2C 04 00 11` reply header at `0xF4FEF2` are both asserted) plus prom_a
at `0xF80000` for the menu table and the four job-code stores.

* **The address.** prom_b `Pack3x7BitFields_Bytes6To8` (`0xF36849`) computes
  `(b6&7F)<<14 | (b7&7F)<<7 | (b8&7F)`; bytes 9-11 are the byte count the same
  way. A descriptor's **first six bytes are exactly that address triple and
  that count triple**, and `0xFB4DBC` puts those same six bytes on the wire
  behind the `2C` header — the reply's header *is* the descriptor.
* **The trie's terminal record is a KEY, not a node.** `0xFB645F`/`0xFB647B`
  read `*(next)` and `*(next+1)` into parse-record fields 1 and 2 = the
  **group** and the **index**. The group is bounded to 1..7 by
  `dec 1,WA / cp wa,0x06 / jr ugt` at `0xFB34F1`+ (cmd `0x18`) and `0xFB42AB`+
  (cmd `0x1A`), and each arm bounds the index with its own `cp A,<n> / jr nc`.
* **★ The twelve descriptor tables TILE** from `0xF51E8E` to `0xF5220E`,
  alternating `2C`-arm / `2B`-arm per group. That single chain is the
  last-entry test on all twelve bounds at once, and it is what proves the two
  families address the *same* parameter set through two method slots
  (`+0x14` and `+0x18` of the descriptor).
* **Direction, three witnesses.** `+0x14` (cmd `0x18`, family `2C`) reaches
  `sub_FB77F3`, which **reads two bytes off the message** and returns
  `(b0<<4)|(b1&0x0F)`. `+0x18` (cmd `0x1A`, family `2B`) reaches e.g.
  `0xFB4562`, which reads the *instrument* (`sub_FB7A02`) and calls
  `sub_FB4D62`, the transmitter. And the length check at `0xFB6D5F` admits
  only `0x7E`/`0x2D`/`0x2C` — `2B` is not length-checked because it carries
  no data.
* **The count triple is always on the wire.** The trie spells it out only when
  it is not 1. For the rest, `0xFB6CA6` catches command ids `0x18` and `0x1A`,
  tests parse field `0x0C` for the untouched `0xFF`, reads the three bytes
  itself and requires their OR to be 1 (`0xFB6CE1`), else status `0x0E` →
  `ERROR 41!`.
* **The trailing flag.** `0xFB6DE8` admits `0x7E`/`0x2D`/`0x2C`/`0x2B`, reads
  one byte that must be `0` or `1` (else status `0x12`), stores it in field
  `0x0F` and only then checksums. The reply builder emits it as the third byte
  of its data block, prefilled from prom_b `0xF4FA84` (`00 00 00`).

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers: **3756**
accepted sequences under *each* of `2B` and `2C`; `0x1A` x3742 / `0x19` x6 /
`0x1B`,`0x1C`,`0x1E`,`0x1F` x2 for `2B` and `0x18` x3750 / `0x17` x6 for `2C`;
**32** part blocks of **57** parameters (18 + 39 across two groups); the four
whole-area request arms carry job codes **4/3/5/2**, which are the SEND menu's
own row→job values at prom_a `0xF99AE3`.

### Value ranges

`--params` prints each parameter's minimum and maximum, which are bytes `+9`
and `+0x0A` of its descriptor. Those two bytes are compared against the value
the message carries and the write is **skipped silently** when it falls
outside — `0xFB3906`/`0xFB3911` in the part setter, `0xFB3797`/`0xFB37A2` in
the common one. The script prints a range only for the three `+0x14` methods
whose bodies were read instruction by instruction (`0xFB3778`, `0xFB38E4`,
`0xFB3882`); for every other method it prints a dash rather than assume the
same two fields mean the same thing.

### Traps

1. `sysex_grammar_dump.py --paths` truncates at depth 8 and therefore cannot
   show the count triple at all; this script walks to the bottom and asserts
   the depth never reaches 24.
2. **One record in the whole space is a wildcard**: byte 7 = `11`, byte 8 =
   `0xFE`. `0xFB3AD1` reads byte 8 back out of the parse record and looks it
   up in prom_b `0xF4FA9C`; `0xFF` there means *drop the message silently*.
   Only 68 of the 128 byte-8 values are admitted (`20..36`, `40..56`,
   `60..75`). Comparing that record's address against its descriptor without
   special-casing it is a false failure.
3. Index **0** of every group is the same placeholder descriptor `0xF511F9`,
   which `0xFB4D92` refuses *by address*. The wire indices are therefore
   1-based and index 0 is unreachable.

## `sysex_cross_product.py` — signal being read

Three images, three copies of the same three structures. Each load base is
asserted by content (`F0 50 23 7E F7` must sit at the stated address), never
assumed.

| product | image | base | templates | grammar root |
|---|---|---|---|---|
| WSA1R | `wsa1_prom_b.ic13` | `0xF00000` | `0xF4FEB4` | `0xF5115B` |
| KN5000 | `kn5000_v10_program.rom` | `0xE00000` | `0xEE3594` | `0xEE493E` |
| KN1500 | IC15 `…9649eai.ic15.rest` | `0xD80000` | `0xF5278E` | `0xF53838` |

* The KN5000 root is named by `lda XBC,0xee493e` at `0xFD5F6F` and `0xFD5FB0`,
  bounded to **16** records by `cp QIZH,0x10` (`0xFD6015`), stride 6 from
  `muls WA,0x0006` — one record more than the WSA1R's 15, and the extra one is
  a `0xFE` **wildcard**.
* Status maps: WSA1R `0xF511C7` (34 bytes), KN5000 `0xEE49B4` (35 bytes then
  `0xFF`). 32 of the 34 shared entries are identical.
* KN5000 transmit side, for the checksum claim: `0xFD6B7A` sums from buffer
  `+0x0F` to the write cursor, `neg E` / `res 7,E`, then appends that byte plus
  the `0xF7` beside it in the word at `0xEE2D6A` (`00 F7`) — the same routine,
  the same constants and the same 2-byte literal as the WSA1R's `0xFB7111` /
  `0xF4FE68`. Receive side `0xFD6959` gates the checksum on the same four
  families `{0x7E,0x2B,0x2C,0x2D}` and raises the same statuses `0x12`/`0x14`.

### Pass criterion

Every assert silent, `OK` printed. Headline numbers: three roots with the same
14 family bytes; KN5000 and KN1500 carry a 15th, wildcard record and the WSA1R
does not; triples `04 00|01 11` / `01 28 12` / `01 24|25|26 11`; 32/34 status
entries identical; 11 of 13 KN5000 dump regions unchanged in the KN1500.

### Trap

A product that answers to more than one model triple repeats its whole
address table once per triple. Counting rows without de-duplicating makes the
WSA1R look like it has 16 transfers and the KN1500 39; the real counts are 8
and 13.

## `sysex_wire_capture_check.py` — signal being read

`SND_CMBI.syx`, a real SOUND+COMBINATION bulk dump, 728254 bytes / 2883
messages, from the community archive `KN7000/WSA1R_files/SND_CMBI_syx.zip`
(zip sha256 `72e8d9b3…b055`, syx sha256 `a7a83a08…968e`). **Not committed** —
it is a capture, not a ROM; the hash above is the baseline and the script
refuses to assert against any other file unless `--any` is given.

Every rule is checked against the bytes, not restated: three unanswered
enquiries then the dump proceeds without acknowledgements; five data headers
whose `(address, length)` pairs are all five present in prom_b's own grammar;
2871 continuation frames re-opening `F0 50 7E`; every payload byte `< 0x10`;
`len(frame) - 4 == 0xFC` on every full frame (125 source bytes, 120 in a
header frame); flag `0x01` except once per transfer; **0 checksum failures in
2876 frames**; and every transfer delivering exactly the byte count its own
header declared.

### The one contradiction it found

Every message in the capture carries the model triple `04 01 11`, while the
dumped v2 `prom_b` transmits `04 00 11` and **no `04 01 11` literal exists
anywhere in the four WSA1 images**. Both are accepted on reception, and the
KN1500 accepts three consecutive values in the same position, so that byte is
a model/variant code rather than a constant of the product. A librarian must
accept both.
## `sysex_bulkdump_rx.py` — signal being read

Both load bases are asserted first, the same way `sysex_bulkdump_tx.py`
asserts them.

* **Screen gate.** `0xFB2820` is the DEFAULT slot of both outer dispatch
  tables, so every bulk-dump command lands there. Its first two tests are
  `cp (0x207A),0x79` (`0xFB2826`) and `cp a,0x07 / jr c` on the command
  number (`0xFB283C`). `(0x207A)` is the panel mode byte and screen id
  `0x79` is bound to the SYSEX BULK DUMP screen object by prom_a's own
  header on `ScreenLeave_SysexBulkDump_Entry` (`0xF99831`). The
  FOREGROUND table's default is `0xFB22C8`, a bare `ret`, which is what
  keeps a dump offered on MIDI 2 from ever being received.
* **Destination.** The six address/size septets are matched byte for byte
  by the trie; the eight forms that exist are exactly the eight the
  machine transmits, and the script checks each accepted sequence against
  the corresponding literal transmit template. The address is never read
  back — parse-record fields 9/0x0A/0x0B are fetched nowhere in the
  bulk-dump code, only in the `2B`/`2C` parameter handlers.
* **Bound.** The destination extent comes from the handler's own
  descriptor writer, not from the message. The single exception is
  SEQUENCER part 3, whose length the trie leaves free: `sub_FB6BF4`
  rejects it above `0x50C00` (`cp XBC,0x00050C00` at `0xFB6C69`) with
  status `0x16`, and `0x50C00` is exactly the extent `sub_FB76B5`
  reserves — the script asserts the two agree.
* **Order.** Each data handler compares parse-record field 3 (the session
  step) against one literal; the script finds that compare by scanning
  the handler entry for the first `cp a,imm3` / `cp A,imm8`. The step a
  handler writes is the index under which the same routine appears in the
  continuation table `0xF4F99E`, which is how an address-less
  `F0 50 7E …` frame finds the destination again.
* **Collector ceiling.** `cp WA,0x00FF` at `0xFB610A`, with the count set
  to 1 by the `F0` (`0xFB619A`) and the `F7` appended past the test
  (`0xFB612C`).

### Pass criterion

Every assert is silent and the script prints `OK`. The headline numbers
are **8** accepted header forms, `0x50C00` (330 752) for the one
variable-length message, **256** bytes as the longest message the
receiver will store, screen **0x79**, and **5** steps at which
`end of category` is legal.

### Trap

`0x50C00` is 330 752, not 331 776 — the difference is one `0xC00`, and
the arithmetic is easy to do wrong by hand. The script computes it from
the two ROM sites and asserts they match rather than quoting a number.

### ⚠ Two corrections to the published reference

1. The length limit is **256 bytes on the wire**, not 254: the stored
   count starts at 1 on the `F0`, a body byte is refused once the count
   reaches `0xFF`, and the closing `F7` bypasses the test — `F0` +
   identifier + 253 body bytes + `F7`.
2. `ERROR 42!` does **not** have a single, transmit-only cause. Status
   `0x18` is stored directly, not through the setter the error probe
   scans for, at `0xFB296D` — a `F0 50 22 04 nn 11 F7` arriving without a
   preceding `F0 50 21 …` enquiry — and again at `0xFB6063` on the send
   side. Likewise status `0x17` (`ERROR 41!`) is stored directly at
   `0xFB3249` when an abort is received.

## `sysex_param_wire_format.py` — signal being read

Both load bases asserted by content, as above.  Everything below is read out
of the instruction bytes and asserted, never quoted.

* **The frame.** The collector record's byte buffer starts at `record+0x0E`
  (`add XBC,0x0E` at `0xFB7FF9`) and the `F0` goes into it, so a checksum that
  sums from `record+0x0F` — which both `0xFB6E27` (receive) and `0xFB7126`
  (transmit) do — starts one byte after the `F0`.  That is the whole reason
  the rule reads "every byte after `F0`".  The rule is re-checked against the
  2876 checksummed frames of the real `SND_CMBI.syx` dump with `--capture`.
* **The count triple is the parameter's DATA LENGTH, and it is not always 1.**
  1809 parameters take one byte, 33 take two and 33 take three.  The grammar
  spells the triple out **iff** the parameter is multi-byte — the script
  asserts that biconditional over the whole space — and for the one-byte case
  `0xFB6BF4` reads the three bytes itself and requires their **bitwise OR** to
  equal 1 (`or L,H` / `or A,L` / `cp A,1` at `0xFB6CD3`/`0xFB6CDB`/`0xFB6CE1`).
  ⚠ That is an OR, not a value test: `00 00 01` is the right answer and six
  other combinations would also pass.
* **The data encoding is the bulk dump's, literally.** `0xFB77F3` (parameter)
  and `0xFB72B5` (bulk) run the same three instructions on the same cursor
  field: `sll h,4`, `and A,0x0F`, then `or`/`xor` — which agree because the
  nibbles do not overlap.  High nibble first, two wire bytes per data byte.
* **The reply.** Five builders checked (one per data length, plus the part
  and wildcard variants; there are others), each emitting
  6 header + 6 address-and-count + 2N nibble + 1 flag bytes.  The script reads
  the three `pushw` counts out of each builder and asserts them, asserts each
  one names the `F0 50 2C 04 00 11` literal at `0xF4FEF2`, and asserts the two
  part builders patch address byte 7 to `0x20 + part` (`set 5,A` / `add C,0x20`)
  and the wildcard builder writes the requested byte 8 back over its copy —
  so a reply always answers at the address that was **asked for**.
* **A refused `2B`/`2C` is answered `F0 50 29 7E F7`** — `0xFB5197`, gated on
  the family being `2B` or `2C`, reading the literal at `0xF4FEC8`.  No other
  family is answered when it is refused, and an accepted `2C` is not answered
  at all.
* **Both output rings.** The reply builders and the refusal call `0xFB71BB`,
  which puts the block into `Ring601432` *and* `Ring60153C`; the bulk-dump
  path calls `0xFB7165`, which uses the first only.

### Pass criterion

Every assert is silent and the script prints `OK`.  Headline numbers: message
length `13 + 2N` for a write or a reply and `15` for any request; the length
census 1809 / 33 / 33; and the three worked examples, which the script builds
with the instrument's own arithmetic and then compares against hard-coded
literals.

### Trap

The two `pushw 0x06` blocks a reply builder emits are **header then
descriptor** — six bytes of `F0 50 2C 04 00 11` and six bytes of address and
count.  Reading them as one twelve-byte header loses the fact that the second
six come from the descriptor and are therefore the *requested* address, and
hides the part patch that rewrites one of them.
