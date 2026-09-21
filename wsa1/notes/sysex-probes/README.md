# SysEx probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |
| `sysex_error_codes.py` | Which internal status code raises `ERROR 40!`, `ERROR 41!` or `ERROR 42!`, and where in prom_a is each one raised? | `python3 wsa1/notes/sysex-probes/sysex_error_codes.py` (table) or `--sites` (every raise site) |
| `sysex_bulkdump_tx.py` | What does the machine put on the wire when SYSEX BULK DUMP -> SEND is pressed: which menu row dumps what, what the frame header says, and how the checksum and the block size are computed? | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_tx.py` (tables) or `--frames` (block arithmetic + a worked checksum) |
| `sysex_command_map.py` | Walking the grammar to the BOTTOM (not depth 8): what does each accepted sequence make the instrument DO? Covers `25`, `7E`-as-third-byte, the `2D` subtree and the dump request. | `python3 wsa1/notes/sysex-probes/sysex_command_map.py` (tables) or `--paths` (all 7542 sequences) |
| `sysex_param_wire_format.py` | The COMPLETE byte layout of a `2B` / `2C` message: where the data sits, what the count triple means, what a request carries instead of data, what the reply looks like, and what a receiver must compute for the checksum. Ends with worked examples it verifies. | `python3 wsa1/notes/sysex-probes/sysex_param_wire_format.py` (tables + examples), `--lengths` (every multi-byte parameter) or `--capture` (re-check the checksum rule against the real dump) |
| `sysex_param_space.py` | The `2B` and `2C` families: what the bytes after the model id `11` mean, which command id each sequence terminates in, and how `2B` differs from `2C`. | `python3 wsa1/notes/sysex-probes/sysex_param_space.py` (tables), `--params` (every parameter with its accepted value range) or `--paths` (all 7512 sequences) |
| `sysex_third_region.py` | The THIRD region of the `2B`/`2C` families (`byte 6 = 10/18/19`), which `sysex_param_space.py` can only name: what that address space CONTAINS, what a write does, what a request is answered with, and how it is bounded. | `python3 wsa1/notes/sysex-probes/sysex_third_region.py` (tables) or `--map` (every block of both regions) |
| `sysex_dump_categories.py` | WHICH of the five bulk-dump categories emits WHICH data header, in what order, and what the header's 21-bit address field means. | `python3 wsa1/notes/sysex-probes/sysex_dump_categories.py` (tables) or `--wire` (each header as transmitted) |
| `sysex_bulkdump_rx.py` | The RECEIVE side: what picks the destination of an incoming data message, whether an arbitrary address is honoured, what bounds the write, what order the messages must come in, and whether the panel has to be on the SYSEX BULK DUMP screen. | `python3 wsa1/notes/sysex-probes/sysex_bulkdump_rx.py` (tables) or `--order` (the whole in-session dispatch table) |
| `sysex_cross_product.py` | Is this the SAME protocol in the sibling Technics products? Reads the WSA1R, KN5000 and KN1500 grammars out of raw ROM side by side, prints each one's model triple, fixed messages and bulk-dump regions, and asserts what is shared and what is not. | `python3 wsa1/notes/sysex-probes/sysex_cross_product.py` (summary), `--paths` (every accepted sequence), `--kn7000` (the later, incompatible dialect) |
| `sysex_wire_capture_check.py` | Does a dump a REAL machine put on the wire obey the frame format decoded from the ROMs? Checks the handshake, header, nibble payload, 0xFC cap, continuation flag, checksum and declared length of all 2883 messages of a captured SOUND+COMBINATION dump. | `python3 wsa1/notes/sysex-probes/sysex_wire_capture_check.py` (summary) or `--frames` |
| `sysex_model_variant.py` | What the keyboard/rack setting changes about the SysEx implementation: all six entries of the feature table and every reader of it, every other place the SysEx engine reads the setting, and the transmit-time rewrite of the model triple that makes a real rack's dump carry `04 01 11`. | `python3 wsa1/notes/sysex-probes/sysex_model_variant.py` (tables) or `--sites` (every compare site in prom_a) |
| `sysex_unreachable_commands.py` | The command numbers that have a handler and NO accepted wire sequence (`0x06 0x0D 0x0F 0x10 0x11 0x1D`) — dead code, or reachable another way? — plus what `F0 50 7E` does when it is the WHOLE message, and what family `25` does besides carry a number. | `python3 wsa1/notes/sysex-probes/sysex_unreachable_commands.py` (tables) or `--steps` (every continuation slot) |
| `sysex_param_addresses.py` | WHERE does each `00`-area parameter live: the WORK-RAM byte its descriptor names, the BULK-DUMP address of that byte, and -- for the eight on the mixer strip -- the screen caption that edits it. | `python3 wsa1/notes/sysex-probes/sysex_param_addresses.py` (the table), `--dump` (with dump addresses), `--strip` (the eight named parameters), `--named` (every name the ROM itself supplies), `--lists` (the value white-lists) |
| `sysex_user_settings.py` | WHICH USER SETTINGS change whether System Exclusive works: does an EXCLUSIVE filter exist for input, for output or both; exactly what it suppresses; whether it touches bulk dump, parameter messages or the General MIDI messages; and whether any MIDI channel / mode / device-number setting takes part in System Exclusive at all. | `python3 wsa1/notes/sysex-probes/sysex_user_settings.py` (tables), `--sites` (every instruction that names a settings byte) or `--census` (the reference count per byte) |
| `sysex_signature_checks.py` | The leading bytes of a block — `WA0`, `WSA1`, `WSA SOUND RAM S0`: do they encode a format or OS version, who checks them, and what happens on a mismatch? Also collects every piece of evidence in the four images bearing on an OS other than the dumped v2.0. | `python3 wsa1/notes/sysex-probes/sysex_signature_checks.py` (tables) or `--artefacts` (confront the ROM literals with a real dump and real disk files) |
| `sysex_general_midi.py` | Does GENERAL MIDI mode change System Exclusive behaviour: which messages stop being accepted, whether bulk dump or the parameter families are affected, whether the instrument TRANSMITS on entering or leaving GM, and where the GM state sits inside a bulk dump. | `python3 wsa1/notes/sysex-probes/sysex_general_midi.py` (tables) or `--records` (all 77 records of the SYSTEM,PART & MIDI part-2 block) |

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
anywhere in the four WSA1 images**.

⚠ **RESOLVED by `sysex_model_variant.py`, and the earlier reading of it was
too weak.** The `01` is written at transmit time: `sub_FB5F65` (0xFB5F65)
runs on every outgoing message, and when the model-variant strap `(0x00C4)`
is 2 it overwrites message byte 4 with `0x01` for families `21`, `22`, `2C`
and `2D`, then recomputes the checksum over `sub_FB7111`'s own window. So the
middle byte **does** distinguish the two models on transmission — the
capture is a strap-2 machine — even though reception is model-blind and both
values reach the same handlers. The note that used to stand here, that the
byte is "not derived from the keyboard/rack setting", was wrong; the
published chapters `sec-message-set.tex` and `sec-models.tex` were corrected
in the same commit. A librarian must still accept both.
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

## `sysex_third_region.py` — signal being read

All three load bases are asserted by content first (prom_a `00 03 05 04 02` at
`0xF99AE3`, prom_b `F0 50 23 7E F7` at `0xF4FEB4`, prom_c `add XWA,0x4a1` at
`0xFB459E`).

* **Command slots.** Entries `0x17` (family `2C`) and `0x19` (family `2B`) of
  **both** outer tables `0xF4F800` / `0xF4F888` hold prom_a `0xFB3483` /
  `0xFB3495`. Both routines are `ld XBC,(0x60FC80) / add XBC,0x0E / push /
  call <thunk>`: `0x60FC80` is the collector struct and `+0x0E` is the received
  message's own `F0`, so everything below indexes **wire** byte numbers.
  ⚠ Neither routine tests the panel-mode byte `(0x207A)`, while the bulk-dump
  default handler `0xFB2820` tests it at its second instruction — the script
  asserts the contrast, which is what establishes that these messages need no
  session and no screen.
* **The request** is prom_b `sub_F36F8C` (`0xF36F8C`, thunk `T_F41254`):
  `Pack3x7BitFields_Bytes6To8` → address, `..._Bytes9To11` → count,
  `cp XBC,0x00060000` splits the two regions, and
  `sub XWA,0x00040000 / cp XWA,0x000002c9` and
  `sub XWA,0x00060000 / cp XWA,0x00004c98` bound them. Accepted → state word
  `(0x000A00) |= 5` and return 0; refused → return 1, and prom_a `0xFB34AD`
  transmits the five bytes at prom_b `0xF4FEC8`, which are the **abort**
  message the reference already names.
* **The write** is prom_b `sub_F379AB` (`0xF379AB`, thunk `T_F41258`): the same
  split, `cp (0x000A07),0x0001` (the count must be exactly 1), the value is
  `(msg[12]<<4) | (msg[13]&0x0F)`, and a ladder of `cp XIX,<n>` turns the
  offset into (block, index) for prom_a `0xFD616A` (melodic) or `0xFD6704`
  (drum) — **the same two routines the panel's own tone editor commits
  through** (`FINDINGS-l7a1429-field-editors.md` §1c). That is what identifies
  what the region contains.
* **The layouts are read, not restated.** Every threshold is an `EC CF imm32`
  operand and every selector a `0B imm16` operand. The melodic ladder yields
  four 43-byte blocks (selectors `0x11/0x21/0x31/0x41`) and four 81-byte blocks
  (selectors 1–4); the script asserts `0xD9 + 4*81 == 0x21D` and
  `0x21D + 4*43 == 713`, so the region **ends on its last block** — the
  last-entry test. The drum ladder yields `408 + 150*n` with sub-blocks at
  `+0 / +64 / +107`, and `(19608 - 408) / 150 == 128` exactly.
* **★ The cross-check is a different image.** prom_c's
  `Part_GetPercWaveSelectRecord` computes `0x0087D2 + 0x4A1 + 150*inst +
  43*idx` and `ToneMsg_WriteWaveSelectParam` computes `0x0087D2 + 0x21D +
  43*element`. The script asserts `0x4A1 == 713 + 408 + 64` — i.e. the two
  protocol regions are **contiguous, in this order**, in CPU 2's staging image,
  which no byte of prom_b knows.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers: **713**
bytes at `0x040000` and **19608** at `0x060000`; `217 + 4x81 + 4x43`;
`408 + 128x150` with `150 = 64 + 43 + 43`; count **1** on a write; **120**
bytes per reply message (255 on the wire, inside the receiver's 256-byte
ceiling); refusal answer `F0 50 29 7E F7`.

### Traps

1. **The write bound is `<=`, the request bound is `address + count <=`.** So
   the write path accepts one offset past the end of each region (713 and
   19608), which lands one index past the last block. The script computes the
   region sizes from the request path, where the arithmetic is unambiguous.
2. **A request's reply cannot be replayed as a write.** The reply is a `2C`
   message with a count of up to 120, and the write path refuses any count but
   1 — silently. Restoring a region takes one message per byte.
3. **73 offsets of the melodic region and 70 of the drum region never reach the
   sound engine**; they are answered by the panel processor through thunk
   `T_F434A0`, and they are the same 69 parameters the `byte 7 = 11` wildcard
   record of the parameter area reaches (`sysex_param_space.py` trap 2).

## `sysex_model_variant.py` — signal being read

One firmware serves two boxes. The discriminator is the direct-page byte
`(0x0000C4)`, written **once** at RESET by `Variant_SetFromPB0`
(`0xF82882`) from **PORT B bit 0** — HIGH → 1, LOW → 2 — and read 109 times
in prom_a and twice in prom_b. The script asserts the store idiom `F0 C4 41`
occurs exactly once in either CPU-1 image, and that every compare site tests
1 or 2 and nothing else.

* **The feature table.** `sub_FB5FF5` (`0xFB5FF5`) bounds its argument with
  `cp (XIZ+0x08),0x06 / jr NC` → `0xFFFF`, picks prom_b `0xF4FE6A` when the
  strap is 1 and `0xF4FE76` otherwise, and indexes with stride 2. Both table
  addresses occur in **exactly one instruction each** in 1 MiB, so nothing
  else reads them; the two tables are contiguous (`0xF4FE6A`+12 = `0xF4FE76`)
  and sit immediately after the `00 F7` word the checksum routine appends.
* **Every caller, and the index each passes.** `refs_to()` scans the raw
  image for `call imm24`, `calr disp16` and every relative branch, then
  filters the candidates through the instruction boundaries of this tree's
  own byte-exact `prom_a/wsa1_prom_a.s`. Six callers; the `pushw imm16`
  before each one is read from the bytes. ★ **All six pass 3 or 5** —
  entries **0, 1, 2 and 4 have no reader at all**. They are `0x0000` in both
  tables, i.e. permitted, and nothing ever asks.
* **★★ The other strap reader in the engine.** Exactly two `C0 C4 3F` sites
  exist in `0xFB2000-0xFB8200`: the selector above and `sub_FB5F65`
  (`0xFB5F65`). On strap 2 only, and for families `21`, `22`, `2C` and `2D`
  only, it overwrites **message byte 4** — the middle byte of the model
  triple — with `0x01`, and for `2C`/`2D` recomputes the checksum over
  `+0x0F .. len-3`, storing `(-sum) & 0x7F` at `len-2`. The script asserts
  that window and that arithmetic against `sub_FB7111`'s own, so a patched
  message checksums as if it had been built that way.
* **It is on every transmit path.** `sub_FB5F65`'s two callers sit at the
  head of `sub_FB7165` and `sub_FB71BB`, and those two are the only routines
  in the engine that reach the MIDI-out block write (`0xF41DF8`). All 19
  calls to them are inside the engine.
* **Reception is model-blind.** The trie accepts model byte `00` and `01` for
  all five families that carry the triple (`21 22 2B 2C 2D`), with identical
  continuations and identical command numbers on both.
* **What the user sees.** Three display lists and one soft key swap on the
  strap; the script proves the dropped tails byte for byte — ` SEQUENCER`
  from the SYSEX BULK DUMP menu (`0xF0D77F-0xF0D79C`), ` SEQUENCER     :`
  from the transfer-progress screen (`0xF0D81B-0xF0D82E`), `REALTIME
  MESSAGE` from the MIDI menu index — and reads the dead row-4 key gate at
  `0xF99B3D`.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline results: **6**
feature entries, **1** reader, **6** call sites, indices **{3, 5}** only;
**4** patched families; model byte `00` → `01`; checksum window `+0x0F .. -2`.

### What it does NOT establish

**Which physical box is variant 1 and which is 2.** No string in any of the
four images names either model. The tree's assignment (2 = SX-WSA1R) rests on
the SX-WSA1R service manual — see `notes/WSA1-EMULATION-DISASM-GAPS.md` — and
the script deliberately prints "variant 1" / "variant 2" and never a model
name. A third, weaker corroboration now exists: the community capture
`SND_CMBI.syx`, filed under WSA1R, carries `04 01 11`, which only a strap-2
machine transmits.

### Trap

A raw byte scan for a branch displacement matches inside other instructions —
`0xFB71B3` is the second byte of `inc 6,XSP` and reads as a `jr Z` to
`0xFB71BB`. Counting those makes `sub_FB71BB` look like it has 15 callers
instead of 14. Every candidate must be checked against an instruction
boundary before it is believed.

## `sysex_unreachable_commands.py` — signal being read

Both load bases asserted by content, and then a third, stronger base check:
every instruction line this script reads out of `prom_a/wsa1_prom_a.s` is
compared against the raw image before it is used (119 331 lines, 0
mismatches), so the instruction boundaries are the tree's, not a guess.

* **The orphans are unreachable, and the argument is a negative.** A command
  number reaches a handler only out of parse-record field 0, and field 0 is
  written at exactly **19** sites, **all** of them inside the grammar walker
  `0xFB63D1-0xFB6B87`. The script finds those sites by locating every
  call/`calr` to the setter `sub_FB6219` and reading the `pushw` immediates
  behind it, so "no accepted sequence" really does mean "no way in".
* **0x0D is the receive half of the transmitter at `0xFB248A`**, which has no
  caller in prom_a. Its header prom_b `0xF4FF10` is `20 00 00 / 00 00 10` —
  the SOUND address with a length of 16 — and the trie accepts the SOUND
  address only with `10 00 00`. The descriptor writer both halves call,
  `sub_FB7629`, sets `start == end` and size 0.
* **0x0F / 0x10 / 0x11 are a whole three-part category that was stubbed out.**
  They demand steps 0 / 8 / 9 where SEQUENCER demands 0 / 12 / 13, they arm
  continuation slots 7 / 8 / 9, 0x11 calls the same run-time length decoder
  `sub_FB741A` that SEQUENCER part 3 does — and every routine that would move
  data is a single `ret`: `0xFB753D`, `0xFB766C`, `0xFB766D`, `0xFB766E`,
  the entry hook `0xFB7EE3` and the error recovery `0xFB7EE4`. Each stub sits
  one byte before a real routine of the same shape, which is why the script
  asserts the entry byte rather than trusting a name.
* **0x1D is a dump request for job 1**, and `JumpTable_FB2081[1]` runs
  `sub_FB22E6`, a single `ret` — the one job slot with no body. The other
  four request arms carry jobs 4/3/2/5, which are in the SEND menu's own
  row→job table.
* **0x06 is below the session loop's floor**: `cp a,0x07 / jr c` at
  `0xFB283C`, and its session slot `0xFB3233` is a `ret`.
* **`F0 50 7E` needs a flag and a checksum.** `sub_FB6CFC` sets the parity
  limit to *write pointer − 3* and starts from the payload cursor; the parse
  record is initialised from prom_b `0xF511E9` = `00 00 00 00 00` then eleven
  `FF`, so the count triple is never zero and the parity rule always runs for
  a `7E`. A bare `F0 50 7E F7` therefore takes status `0x11`, and BOTH
  dispatchers (`0xFB217D`, `0xFB2887`) refuse to run a handler once a status
  is set — so command 0x0A never executes and nothing is transmitted.
* **Command 0x0A dispatches a second time, on the session step**, through
  the 18-entry table `0xF4F99E` (bound `cp A,0x12` at `0xFB2C7E`). Twelve
  slots accept a frame; six — 0, 3, 6, 10, 14, 17, the states in which a
  *header* is expected — raise status `0x13`, which `STATUS_MAP` sends to
  the same screen as every other `ERROR 41!`.
* **Family 25, both directions, five gates each**, read as instruction bytes:
  the model-variant feature slot 5, `(0x207A) != 0x79`, `(0x7F32)` bit 2
  clear, `(0x7F38)` bit 3 set, and on the send side `(0x0922)` bit 0 clear.
  The value is `lo | hi<<4`, bounded 40..300 in both. The **sender clamps**
  (`0xFB33B8` / `0xFB33C6` store 40 and 300); the **receiver clamps nothing** —
  the script asserts there is no `ldw WA,0x78` anywhere in the receiver, and
  that the one that exists is in the sequencer clock programmer at
  `0xFAA368`, which rewrites the *stored* tempo.
* **The write-protect class table** prom_b `0xF4FE82`, indexed by command and
  read against `(0x7FD6)`: bit 0 refuses `0x0D 0x0E 0x17`, bit 1 refuses
  `0x15 0x16`, either bit refuses `0x0A 0x0B 0x0C`. SEQUENCER and the
  ordinary parameter write `0x18` are class 0 and are never refused.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers: **7542**
accepted sequences over **27** command numbers with **6** orphans; **19**
writers of the command field, **0** outside the walker; **0** callers of
`0xFB248A`; **6** `ret` stubs behind 0x0F/0x10/0x11; **12 of 18**
continuation slots live; tempo `40 → F0 50 25 08 02 F7`, `120 → 08 07`,
`300 → 0C 12`.

### ⚠ A correction to the published reference

`sec-message-set.tex` says of family `25` that "a value outside that range is
treated as 120". **The receiver does no such thing** — it drops the message,
changing nothing and reporting nothing. The 120 belongs to the sequencer
clock programmer, which rewrites the *stored* tempo if it ever finds it out
of range, and to the sender's own prefill `08 07 F7`.

### Traps

1. `sub_FB741A` appears in the call list of 0x11 and of 0x14 and is **not** a
   descriptor writer — it is the run-time length decoder. Asserting that
   every routine 0x11 calls is a stub fails on it.
2. A routine that is "a single `ret`" must be tested by its **entry byte**,
   not by its name: `sub_FB753D` and `sub_FB753E` differ by one byte and one
   of them is the SEQUENCER's real descriptor writer.
3. The parse record is **double buffered** (`0x60FCD8` and `0x60FCDC` swap in
   `sub_FB8028`), which is why a data handler reads the session step out of
   one record and writes its status into the other. Reading both out of the
   same pointer makes every step test look wrong.

## `sysex_signature_checks.py` — signal being read

Both load bases are asserted by content: prom_b must hold `F0 50 23 7E F7` at
`0xF4FEB4`, prom_a must hold `WSA SOUND RAM S0` at `0xFE7027`.

* **The preambles are ROM literals.** `0xFE7027` `"WSA SOUND RAM S0"`,
  `0xFE7049` `"WSA1"`, and the 32-byte SYSTEM,PART & MIDI default at
  `0xFE704E`, whose head is `5A 5A 01 00 "WA0" 00`. The COMBINATION
  preamble `5A 5A 5A 5A 00 00 "WSA1  " 01 00 00 02` is not a prom_a/prom_b
  literal at all — it is the first sixteen bytes of **prom_c**, which the
  combination flash bank repeats.
* **★ Five comparators, three called, and every call site is a DISK LOAD.**
  The script finds every encoded reference to each of the five in all four
  images — `calr`, `call`, `jp` and any 24-bit data pointer — and asserts
  the result. `0xFE2DF8` (`"WSA"`) and `0xFE2E24` (`0x01,0x06`) have **zero**
  references in 2 MiB of ROM. The three live ones are reached from routines
  that first write a three-character file extension (`"TM "`, `"CMB"`,
  `"LSW"`) into the file descriptor at `0x21C8+8`, and each answers a
  mismatch with `ld a,0x10` before the transfer.
* **★★ No comparator reads a version.** The COMBINATION check covers bytes
  6..9 only and never reaches the `01 00 00 02` at byte 12; the SYSTEM check
  covers bytes 4..5 only and never reaches the `0` of `"WA0"`. The SOUND
  check is the only one that covers its tag in full, all sixteen bytes.
  `0xFE2E3D` also passes a block whose four bytes are all `0xFF`.
* **The MIDI path never looks.** The script asserts the part-1 receive
  descriptor (`0x7600 .. 0x7620`, size `0x20`, written by `sub_FB75BA`)
  and that nothing in prom_a or prom_b reads `0x7600`-`0x7607` as a value.
* **The model triple's middle byte**, read out of the trie at all five
  nodes that carry it: two records, `00` and `01`, both descending to the
  same node. The literal counts are `04 00 11` ×86 and `04 01 11` ×0 —
  ⚠ which is **not** a transmit count: `sub_FB5F65` writes the `01` in at
  transmit time when `(0xC4) == 2`. The script asserts that patcher is
  present so the literal count can never be misread as one.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers: **5**
comparators, **3** referenced, **2** with zero references; **3** disk-load
call sites all answering `0x10`; **0** readers of the signature bytes on
the MIDI path; **4** unreachable bulk-dump command numbers (`0x0D`, `0x0F`,
`0x10`, `0x11`) and the 16-byte orphan template at `0xF4FF10`.

### ⚠ What it establishes about OS version 1

**Nothing exists.** No instruction compares a firmware or format version;
no message carries one; the instrument has no Identity Reply; and the only
run-time switch that changes SysEx behaviour is `(0xC4)`, which
`Variant_SetFromPB0` (`0xF82882`) derives from PORT B bit 0 at reset — a
hardware strap. The one observation that looked like v1 evidence — a real
dump carrying `04 01 11` when no such literal exists in the ROM — is the
rack's transmit-time substitution, decoded in `sysex_model_variant.py`.

### Trap

`b"\x5A\x5A\x5A\x5A\x00\x00WSA1  "` is **12** bytes, not 16 — comparing it
against a 16-byte slice is a false failure, and the first version of this
script did exactly that.

The other trap is treating the two unreferenced comparators as behaviour.
They are shaped for block headers this firmware never tests; a manual that
described them would describe something the instrument does not do.

## `manual_model_markers.py` — the outside source for the model naming

The firmware names neither model: it reads a hardware input and compares it against 1 or 2.
The reference's "Which machine is which" note therefore rests on sources outside the
program, and this makes one of them recheckable — Technics' own user guide marks
keyboard-only features `(WSA1)`, **59** times, including the heading `Part VII Sequencer
(WSA1)`.

A model with no sequencer has nothing to put in a SEQUENCER bulk dump and no use for a
tempo message, which is exactly the pair the other model refuses.

```sh
python3 wsa1/notes/sysex-probes/manual_model_markers.py
```

⚠ Only `WSA1-Practical Applications.pdf` has a usable text layer. The service manual and
the technical guide are page images and `pdftotext` returns nothing from them — see
`technics_roms/tools/render_service_manual_sheet.py` for those.

## `sysex_general_midi.py` — signal being read

Both load bases are asserted by content first: prom_b must hold
`F0 50 23 7E F7` at `0xF4FEB4`, prom_a `00 03 05 04 02` at `0xF99AE3`.

* **The two messages.** The trie ROOT `0xF5115B` is applied to message byte
  **2** — `sub XWA,XWA / inc 2,XWA / add (XBC+0x02),XWA` at `0xFB63DD`
  skips the `0xF0` and the identifier — so `7F` → `09` → `01`/`02` yields
  commands `0x20`/`0x21`. ⚠ The identifier is tested only while the message
  is COLLECTED (`cp H,0x50 / cp H,0x7E` at `0xFB210E`) and never again, so
  the grammar itself does not distinguish `F0 7E …` from `F0 50 …`.
* **Three dispatch tables, two answers.** `0xF4F800` (interrupt-side) and
  `0xF4F888` (foreground) both hold `0xFB51E7`/`0xFB520C`; the in-session
  table `0xF4F916` holds `0xFB3230`, whose byte is `0x0E`, a bare `ret`.
  The script asserts the opcode, not the address.
* **GM mode is ONE BIT**, bit 2 of `(0x7F4D)`. The receive handlers are
  asserted byte for byte: `set 7,(0x60F020)`, `or/and (0x7F4D)`, then the
  posted event `{0x91, 0x03, value, 0x04}`. The OFF handler reaches the
  same bit as `(0x7F4A)+3` and returns at once when it is already clear;
  the ON handler has no guard at all.
* **★ The echo lock.** Bit 7 of `(0x60F020)` is SET at exactly two sites
  (both receive handlers), read with mask `0x80` at exactly one
  (`0xFB5F36`), has no `bit 7,(…)` form anywhere, is cleared by no
  instruction, and no `and` of that cell clears it. prom_b and prom_c never
  touch the cell. RESET zeroes it — the single `ld XBC,0x3000 /
  ld XIX,0x00604000` clear at `0xF827AF` covers `0x604000..0x610000`.
* **★★ The instrument transmits.** `sub_FB5F2E` builds
  `{0xB0, 0x11|0x10, 0x00, 0x7F}` and calls `sub_FB4CAE`, which selects the
  6-byte literal at `0xF4FEE6` or `0xF4FEEC` by the record's byte +1. Index
  `0xB0` of the 192-entry class table `0xF4FB38` is the same emitter. The
  builder is called from `sub_FB590A`, which `UiListA_Class91` (`0xF87B02`)
  names as the ONLY handler of internal event class `0x91` — the class the
  receive handlers, the panel toggle, the boot restore and the SMF loader
  all post — 20 sites in all, every one of them carrying the same record id
  `0x91` and byte index `0x03`. It is NOT gated by the EXCLUSIVE transmit
  filter (`(0x7F38)` bit 3), which guards only `sub_FB4B7D`; it IS dropped
  while `sub_FB590A` is already inside itself (bit 0 of `(0x60F01F)`,
  set at `0xFB5929` and cleared at `0xFB5958`).
* **★★★ Where GM sits in a dump.** `sub_FB75E4` sizes SYSTEM,PART & MIDI
  part 2 from the constants `0x7620` and `0x7F7E`; the same two bound the
  record walk at `0xFAAAD4`/`0xFAAADA`, whose stride is
  `ld C,(XIX+1) / inc 2,XBC / add XIX,XBC`. The block is a list of
  `{id, length, payload}` records: walking the factory default image at
  prom_b `0xF3F400` gives **77 records ending exactly on `0x7F7E`** — the
  last-entry test. `0x7F4D` falls in the record whose id is `0x91`, at
  payload byte **3**: the SAME `0x91`/`0x03` pair the internal event
  carries. Block offset **2349** of 2400, factory default `0x00` = off.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers:
commands `0x20`/`0x21`; flag bit `0x04` of `0x7F4D`; echo lock set 2× /
read 1× / cleared 0×; literals `0xF4FEE6` and `0xF4FEEC`; **77** records
ending on `0x7F7E`; GM at block offset **2349**, record id `0x91`, payload
byte 3; **3** GM-bit sites in the whole engine span and **0** data-table
references to `0x7F4D`.

### Traps

1. **`0x60F020` has other tenants.** `0xFABA46` reads the same cell and
   tests bit 1. Counting reads of the cell instead of reads that mask with
   `0x80` makes the lock look like it has two readers.
2. **The two 6-byte literals sit just past the nine fixed messages** at
   `0xF4FEB4-0xF4FEE2`, inside the same run of template bytes. They are not
   part of that table and no template index reaches them; only
   `sub_FB4CAE`'s two `lda` operands do.
3. A GM message arriving **while a bulk dump session is open** is not
   ignored — the in-session collector at `0xFB60EE` demands identifier
   `0x50`, raises status `0x02`, and `STATUS_MAP[2]` is the `ERROR 41!`
   screen. The transfer dies; GM mode does not change.

## `sysex_param_addresses.py` — signal being read

Both load bases asserted by content first (prom_b `F0 50 23 7E F7` at
`0xF4FEB4`, prom_a `00 03 05 04 02` at `0xF99AE3`).

* **The descriptor's `+6` and `+7` are a RECORD NUMBER and a BYTE OFFSET**, not
  an address. `sub_FB7890` (`0xFB7890`) takes a four-byte record
  `{record, offset, value, mask}`, resolves the record number through
  `IndexedTable_GetPtr`, and does `base[offset] = (base[offset] & ~mask) |
  (value & mask)`. The setters fill that record from the descriptor: common
  `0xFB3778` reads `+6` at `0xFB37E5` and `+7` at `0xFB37EB`; part `0xFB38E4`
  does the same at `0xFB3957`/`0xFB3971` and ORs `byte7 - 0x20` — the PART
  NUMBER — into the record number (`sub A,0x20` at `0xFB3969`).
* **The record table is `ParamNumber_RecordPtrs`, prom_a `0xFACDEA`**, 256 LE32
  work-RAM addresses. Named by the three `lda XBC,0xfacdea` instructions at
  `0xFAA873`, `0xFAA94E` and `0xFAB7F4`, each followed by
  `ld (0x60f018),XBC`, and `(0x60F018)` is exactly what `IndexedTable_GetPtr`
  loads (`0xFB77DD`) and indexes by 4 (`0xFB77E2`).
* **★ THREE CONFIRMATIONS FROM CODE THAT NEVER READS A DESCRIPTOR.**
  `0xFB9D88` does `and (0x7f35),0xf0` and then posts `{0x80, 3, 0, 0x0F}`;
  `RecordPtrs[0x80] + 3 == 0x7F35`. `0xFB9C31` does `or (0x7f4a+3),0x04` and
  then posts `{0x91, 3, 4, 0xFF}`; `RecordPtrs[0x91] == 0x7F4A`. `0xFB9C1A`
  loops records 0..15 writing offset `0x0D` with mask `0x0F` — the MIDI channel
  nibble of the first sixteen parts. Two of the three pin the arithmetic
  exactly; the third pins the offset.
* **★ THE PARAMETER AREA AND ONE BULK-DUMP CATEGORY ARE THE SAME BYTES.** The
  two SYSTEM,PART & MIDI templates at prom_b `0xF4FEF8`/`0xF4FF04` carry
  `0x100000`/`0x20` and `0x100020`/`0x960`, which abut; prom_a `0xF9603C`
  copies `0x4B0` WORDS from `0x7620` with `ldirw`, and `0x4B0 * 2 == 0x960`,
  so the block is one object. Every resolved parameter lands inside
  `0x7600..0x7F80`, and its dump address is `0x100000 + (RAM - 0x7600)`.
* **★ A SECOND BLOCK THE ROM NAMES ITSELF.** prom_a's
  `ScaleTuning_PostAllTwelveSemitones` (`0xFC0D41`) tests `(0x78A2)` against
  `0x80` and, on a match, reads twelve bytes from `0x78A4`
  (`ScaleTuning_PostSemitoneFromUserRam`, `ld XHL,0x000078a4` at `0xFC0DB4`);
  otherwise it indexes twelve-byte rows of `ScaleTuningOffsets` at prom_b
  `0xF06800`. `RecordPtrs[0x92] == 0x78A2`, so `00 10 11` is the temperament
  selector and `00 10 13`..`00 10 1E` are the twelve USER offsets in semitone
  order — and `0x80`, the last value of the white-list `00 10 11` uses, is the
  one the routine sends to the USER row.
* **The names come from the instrument's own mixer strip.** Eight interpreter-A
  text records at `0xF28A56..0xF28A97` (COMBINATION MODE) and
  `0xF28160..0xF281A1` (SOUND MODE) draw eight captions at **y = 212** and
  x = 10, 50, 90, 128, 168, 210, 250, 288. Eight interpreter-B value records
  draw at **y = 226** within 3 px of those same eight columns, and the paint
  code at `0xF91D55..0xF91E28` loads each one from a literal part-record offset
  first. The caption directly above a cell names the parameter the cell shows.

### Pass criterion

Every assert is silent and the script prints `OK`. Headline numbers: **108**
parameter descriptors, **99** resolved to a RAM byte, RAM block
`0x7600..0x7F80` = dump `0x100000..0x100980`, part records **0x40** bytes with
parts 0-7 at `0x76A2 + 0x40p` and parts 8-31 at `0x78E2 + 0x40(p-8)`, and
**8** screen-named parameters.

### Traps

1. **The part records are not one uniform array.** Parts 0-7 sit at
   `0x76A2 + 0x40*p`, then a `0x40`-byte hole holds two COMMON blocks (records
   `0x92` and `0x79`), and parts 8-31 resume at `0x78E2`. Computing a part's
   base as `0x76A2 + 0x40*part` is right for eight parts and wrong for
   twenty-four.
2. **Not every setter uses `+6`/`+7`.** `0xFB3882`, which serves only
   `00 00 00` and `00 00 01`, takes the 32-bit word at
   `0xF51E58 + 6*desc[0x0E] + 2` as the target ADDRESS. Those two are bits 0
   and 1 of `0x7FD6` — **outside** the block the bulk dump carries. Nine
   further parameters have setters this script has not read, and it prints `?`
   for them rather than assume the rule.
3. **`+0x0E` does not mean the same thing to every setter.** For `0xFB3778`,
   `0xFB38E4` and `0xFB3882` it indexes six-byte records at `0xF51E58`; for
   `0xFB3B04` it indexes four-byte records at `0xF51E70`, and for `0xFB3D13`
   four-byte records at `0xF51E84`. Only the first family is a VALUE
   WHITE-LIST, which `sub_FB374D` walks and which refuses a value that is not
   in it.


## `sysex_user_settings.py` — signal being read

Both load bases are asserted by content, as above.  The object under test is
the **MIDI settings block at `0x007F32`**, which is *one parameter record* —
number `0x80` — and not a set of loose bytes.

* **Row → RAM byte, three ways at once.**  Each row of the INPUT & OUTPUT
  FILTER page has an editor and a painter; the editor hands the generic field
  editor `sub_F9A165` a (mask, address) pair and then commits through prom_b
  `0xF41B18` with the quadruple *(parameter number, byte offset, value, mask)*.
  The script reads all three out of the instruction bytes and asserts that the
  editor's address, the painter's address and `0x7F32 + offset` are the same
  byte, for all eight rows.  Every commit carries number `0x80`.
* **Row → caption is GEOMETRIC.**  One display list draws the eight captions;
  each row's value comes from a 15-byte interpreter-B record of its own whose
  `+0x0D` word is the screen position.  The script asserts each value position
  lies after the end of its own caption and before the start of the next.  The
  split caption `RESET ALL CTRL` + `  :` is re-joined by the same rule.
* **★ Two witnesses that never touch the screen.**  `MidiIn_ControlChange`
  indexes an enable table (`0xFA8468`) whose entries are *(byte offset from
  `0x7F39`, bit mask)*.  The bit the BANK SELECT row writes gates exactly
  controllers **0 and 32** — Bank Select MSB and LSB — and the bit the RESET
  ALL CTRL row writes gates exactly controller **121**, Reset All Controllers.
  Two rows named by the wire, not by the panel.
* **★ The filter is ONE switch acting in BOTH directions.**  `MidiIn_ProgramChange`
  (`0xFA6D58`) and `MidiOut_ProgramChange` (`0xFA71C4`) open with the *same*
  `bit 4,(0x7F39)`.  There is exactly one `EXCLUSIVE` caption in prom_b, one
  editor and one painter — there is no separate input and output setting.
* **★ The census is CLOSED, which is what makes the negatives worth anything.**
  Three ways an address of this size can be formed are all swept, at
  instruction boundaries taken from this tree's byte-exact `.s` files: the
  16-bit absolute operand forms (`C0/C1/D1/E1/F1 lo hi`), the address as a 16-
  or 32-bit immediate, and register-indexed loads off such a base.  The only
  indexed bases inside the block are `0x7F36` (used at offset 0) and `0x7F39`
  (two tables, offsets 0/1/2 only), so **nothing can reach `0x7F38`
  indirectly**.  `(0x7F38)` therefore has exactly **six** references in 1 MiB
  × 2 and prom_b has none.

### Pass criterion

Every assert is silent and the script prints `OK`.  Headline results: eight
filter rows on parameter record `0x80` (base `0x7F32`); `EXCLUSIVE` =
`(0x7F38)` mask `0x0F` with **only bit 3 read**; six references, three of them
consumers — `25` tempo transmit `0xFB3355`, `25` tempo receive `0xFB33FE`, and
the staged-parameter emitter `0xFB4B7D`; 187 of that emitter's 192 dispatch
slots a bare `RET` and four of the remaining five landing on the placeholder
descriptor; default `0x0F` = **ON**.

### ⚠ The trap this probe exists to close

`0xFB4B7D` dispatches to `0xFB4CAE`, which is the **only** code in either
CPU-1 image that can put `F0 7E 7F 09 01 F7` or `F0 7E 7F 09 02 F7` on the
wire — the literals occur once each in prom_b and are named by one instruction
each, both inside it.  From that alone one concludes "EXCLUSIVE off stops
General MIDI being transmitted".  **That is wrong.**  `0xFB4CAE` has a second
caller, `0xFB5F2E`, which builds the same four-byte record itself (number
`0xB0`, byte `0x11` for ON and `0x10` for OFF) and calls it *directly* at
`0xFB5F5C`, never passing the gate.  What holds that path back is bit 7 of
`(0x60F020)`, set by the two General MIDI *receive* handlers and by nothing
else — an echo interlock, not a user setting.  The script asserts **both**
callers, so the wrong claim cannot come back.

⚠ A raw scan for `1D AE 4C FB` also matches inside `3C 1D` at `0xFB5F5B`-ish
offsets in other code; every candidate is filtered through the instruction
boundaries before it is believed.  That is the same trap
`sysex_model_variant.py` records.

### What it does NOT establish

* **What fills the `0x2C00` staged-parameter queue.**  Four of the emitter's
  five live slots are provably dead (placeholder descriptor lists) and the
  fifth only fires for byte offsets `0x10`/`0x11`; whether any queued record
  ever carries those is not decided here.  So "the tempo message is the only
  thing the EXCLUSIVE filter actually withholds" is stated as a *likely*
  reading, not a proven one.
* **Where bit 7 of `(0x60F020)` is cleared.**  Two `set 7` sites exist and no
  `res 7` anywhere; no block initialiser covering it was found either.
* **The exact trigger of the transmitted General MIDI message.**  The panel's
  GENERAL MIDI confirm handler (`0xF99E85`) and both receive handlers post the
  same record — number `0x91`, offset 3 — and `sub_FB590A` consumes it and
  calls the emitter; that `sub_FB590A` is the handler *for* number `0x91` is
  read off a prom_b directory slot (`T_F408F0`) with no located caller.
* **`(0x7F32)` bit 4**, a fifth condition the received tempo value must pass
  (`0xFB57FC`) before it reaches the tempo itself.  It is on no MIDI page.

## `sysex_screen_fields.py` — signal being read

A menu screen is a stream of compact records. A caption is
`[style?] [len] [col] [row] <ASCII…>` and an editable field is
`[kind] [len] [addr lo] [addr hi] [mask] [shift] … [col] [row]`, where `addr`
is a 16-bit work-RAM address and `shift` is the bit position of `mask`'s
lowest set bit. Caption and field carry the **same row**, so the caption on a
field's row is the label the instrument itself prints for that RAM byte — and
`(addr, mask, shift)` identifies the SysEx parameter exactly.

This script scans both images for that shape and prints every hit beside the
captions on its row.

### Pass criterion

None: it is a search. The rows worth keeping are the ones whose `y=` column is
not `None`.

### Trap

It finds only the fields that name their RAM byte as a **16-bit literal**. A
per-part screen reaches the part record through an index register, so none of
the 57 part parameters appears here; those are named by the MIDI they gate or
emit instead (see below). A hit is a lead, not a fact — pin it as a literal
byte string in `sysex_param_screen_names.py` before calling it established.

### The position is ONE 16-bit number

MEMORY PROTECT's `SOUND         :` caption sits at column 240 and is 15
characters long, so its value cell lands at 240+15+2 = **257** — which the
record stores as column 1 of the *next* row. Read the trailing pair as two
independent bytes and that field looks like it belongs to a different line.

## `sysex_param_screen_names.py` — signal being read

Names the `00`-area parameters from the instrument itself, by two mechanisms,
with every claim pinned as a literal byte string at a literal address:

* **The menu screens** — the caption/field row pairing above, for 19
  parameters across TUNE & SCALE, TOUCH SENSITIVITY, DATA LOAD FILTER,
  MEMORY PROTECT, DRUMS MAP and MIDI TOTAL MODE.
* **The MIDI they gate or emit** — a part-record bit that gates a routine
  which builds a control-change message names itself, because the routine
  writes the controller number as a literal and the manual's CONTROLLER ASSIGN
  page prints the same numbers: MODULATION1 #1, MODULATION2 #2, CTRL.PEDAL #4,
  HOLD #64, R.T.CREAT.X #16, .Y #17, R.T.CTRL.X #18, .Y #19, plus status 0xE0
  for PITCH BEND and 0xD0 for AFTER TOUCH. Likewise the three MIDI-input
  filters, reached from the status-nibble table at `0xFA6242` (program change)
  and the controller map at `0xFA83E8` (bank select, volume).

### Pass criterion

Every assert silent, `OK`, then the 39 established rows.

### ★ MASTER TUNE, proved to the last digit

`0xFA0525` fills the two MASTER TUNE display cells `0x264C`/`0x264D` from a
reverse lookup of `(0x7F4A)` — parameter `00/08` — in the table at `0xFA1C5C`:
index *H* gives `H/3 + 27` whole hertz and `H % 3` the tenth. The loop starts
at H=1, giving **427.3 Hz**, and the table's last entry is H=78, giving
**453.0 Hz** — the published range exactly.

### ★ The controller routines feed CPU 2, not the MIDI port

`0xFC1A1A` hands its 4-byte message to `0xF40ED4`, the CPU1↔CPU2 link. So the
ten bits at record `0x20` offsets 0x0B/0x0C/0x0E (`20/70`…`20/79`) are the
**INTERNAL SOUND** controller page, and their bit-for-bit mirror at offsets
0x13/0x14/0x16 (`20/55`…`20/5E`) is the MIDI OUTPUT FILTER page — not the
other way round.

### Trap

`SOUND MUTE` reads `0x7F0B` and `FOOT SW1/2 POLARITY` read `0x7F12`; neither
is one of the 108 parameters. A published setting having no parameter address
is a real result, not a gap in the search.

---

## The published specification, and the document generators

### `manual_reference_guide.py`

**Question:** where is Technics' own System Exclusive specification, and what is on
each page?

It is **not** in either user manual. It is the third volume, the *Reference Guide*,
inside `KN7000/WSA1R_files/OM.zip` at `OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf`.
The script checks the archive and the PDF by sha256, asserts the guide is still
image-only (so nobody concludes "not documented" from a text search of it), and prints
the page index plus the field and address-map tables this project relies on.

```sh
python3 wsa1/notes/sysex-probes/manual_reference_guide.py
pdftoppm -r 150 -png -f 41 -l 41 <the pdf> /tmp/rg     # then LOOK at it
```

Pass: both hashes match, 56 pages, empty text layer, `OK`.

### `sysex_param_table_tex.py` and `param_names.json`

**Question:** what goes in the reference's parameter chapter?

Runs `sysex_param_addresses.py`, keeps only what is visible on the wire — accepted
values, data length, bit mask, position in the bulk dump — discards every internal
address, merges the names from `param_names.json`, and writes the chapter's tables. No
number in that chapter is typed by hand. A name in the JSON whose address is not a
parameter is a hard error, which is how a stale name gets caught.

All 108 names come from the guide's tables (pages 46–47); none is inferred.

```sh
python3 wsa1/notes/sysex-probes/sysex_param_table_tex.py \
    wsa1/docs/system-exclusive-reference/tbl-parameters.tex
```

Pass: `57 part parameters, 51 common, 108 named, 3 white-listed`, then `OK`.

### `sysex_examples_tex.py`

**Question:** are the worked examples in the appendix actually correct?

Builds them rather than transcribing them. The parameter messages come from
`sysex_param_wire_format.py` and every printed checksum is re-verified against the rule
the document states. The bulk-dump example is a frame from a real machine, and the
script **re-encodes that frame from its own decoded payload and asserts the result is
byte-identical to the capture** — so the encoder printed in the appendix is demonstrably
the one the instrument used.

```sh
python3 wsa1/notes/sysex-probes/sysex_examples_tex.py \
    wsa1/docs/system-exclusive-reference/tbl-examples.tex
```

Pass: 5 examples re-verified, the frame re-encodes identically, `OK`.

### `sysex_param_vs_capture.py`

**Question:** does the published parameter map survive a dump from real hardware?

Reassembles the `SYSTEM,PART & MIDI` category out of `SND_CMBI.syx` and reads each
parameter's own field — `(byte & mask) >> shift` — for all 32 parts, checking it against
the declared range.

**It is a test that can fail.** The same scan is run a second time against a deliberately
wrong map — one uniform `0x40` stride for all 32 parts, instead of the two runs the real
layout has — and that run must produce far more violations, or the test is not measuring
anything. It does: **1833 fields checked, 1 out of range on the real map and 69 on the
wrong one.**

The one exception is `00 00 08` `MASTER TUNING` holding `00`. That is not a fault in the
map: the guide gives its range as `C0-00-3F`, signed around concert pitch, so `00` is the
default. It is pinned so a *second* such field would show up as a change.

It also prints two **self-labelling** fields, which are the strongest evidence in the set:

* every part's `BASIC CHANNEL` holds its own part number, so the 32 parts read an
  unbroken `0..31` ramp — and the wrong map interrupts it at part 9, the first past the
  gap. One ramp confirms both the parameter and the record layout.
* every part's `PANPOT` reads 64, the entry the instrument's own pan scale labels `CTR`.

```sh
python3 wsa1/notes/sysex-probes/sysex_param_vs_capture.py
python3 wsa1/notes/sysex-probes/sysex_param_vs_capture.py --values   # every field
```

The capture is not committed — it is a regenerable capture, not a ROM, and it ships in
`KN7000/WSA1R_files/SND_CMBI_syx.zip` (`.syx` sha256 `a7a83a08…`). Point `SYSEX_CAPTURE`
at it or drop it beside the script.

### Trap, recorded because it cost several sessions

The `SND_CMBI.syx` capture is **three** categories, not the two its name suggests: it
opens with `SYSTEM,PART & MIDI`, then `SOUND`, then `COMBINATION`. That first one is the
category the parameter chapter maps, which is why the check above is possible at all.

### `sysex_names_crosscheck.py`

**Question:** do the names read out of the *firmware* agree with the names Technics
*published*?

Two independent sources name the `00`-area parameters: `sysex_param_screen_names.py`
derives 39 of them from the instrument's own menu screens — the caption printed on the
same row as the field that edits a byte — and this was done **before** anyone here had
seen the published tables. `param_names.json` holds all 108 as the *Reference Guide*
prints them.

The document publishes the guide's names. This script exists because a public claim was
made about the other source — that reading names off the machine had worked — and that
claim should be checkable by someone who was not here. It is also a live guard: a future
mis-transcription of the published tables will make the screens disagree.

It prints two numbers, and the reason there are two matters. The sources differ in *form*:
the firmware gives a menu path, `PART > INTERNAL SOUND (PAGE2/3) > HOLD1`; the guide gives
a grouped name, `CONTROLLER INTERNAL FILTER: HOLD1`. Comparing whole strings scores
**21/39**, and most of what it rejects is a difference of heading, not of name. Comparing
only the leaf — what each source calls the parameter itself — scores **35/39**, and that is
the question actually being asked.

The first criterion was not loosened until rows passed; a second, better-specified question
was asked, and both answers are printed. The four whose leaves differ are printed in full,
and all four are the instrument abbreviating on a small screen: `MASTER TUNE` /
`MASTER TUNING`, `R.T.CREATOR` / `REAL-TIME CREATOR`, `CTL. PEDAL` / `CONTROL PEDAL`, and
one where both words sit on the stop list so nothing was left to match.

```sh
python3 wsa1/notes/sysex-probes/sysex_names_crosscheck.py
```

Pass: all 39 addresses are ones the guide also names, both counts are printed, `OK`.

### `doc_glance_consistency.py`

**Question:** does the reference's one-page summary card still agree with the chapters it
summarises?

A summary that drifts from its source is worse than none, because it is the page a reader
copies from, and the drift is silent — both pages still compile and both still look right.
This reduces every `\bytes{...}` on `sec-glance.tex` to its leading run of literal hex
bytes and requires that run to appear in some other chapter.

One-directional by construction: it catches the card claiming something no chapter says,
and it cannot catch a chapter changing a value the card never mentioned. It prints its
coverage so that limit is visible — currently **20 checkable sequences of 40 groups**, the
other 20 beginning with a variable field.

```sh
python3 wsa1/notes/sysex-probes/doc_glance_consistency.py
```

Pass: every checkable sequence found, counts printed, `OK`.

### `sysex_block_signatures.py --tex <file>`

The probe now also writes the reference's signature table.

⚠ **A defect it used to have, and the document inherited:** it printed 8 hex bytes beside
16 characters of text, inviting the reader to match two columns that do not correspond. It
now prints all sixteen bytes, in two rows of eight with the matching eight characters
beside each, and the document's table is generated from it rather than typed.

```sh
python3 wsa1/notes/sysex-probes/sysex_block_signatures.py --tex \
    wsa1/docs/system-exclusive-reference/tbl-signatures.tex
```

### `sysex_sound_layout.py` and `sound_layout.json`

**Question:** is the transcribed `NORMAL SOUND` layout self-consistent, and does it agree
with what the program says?

`sound_layout.json` is a **transcription**, read by eye off rendered scans of the
Reference Guide's pages 48–51, which carry no text layer. That is exactly the kind of
artefact that looks right and is wrong — a `253` misread as `256` changes nothing on the
page and everything in a librarian. So it is checked by two things it cannot satisfy by
accident:

1. **The area must tile.** Every parameter number in a group is covered exactly once, no
   gap and no overlap. A misread digit leaves a hole somewhere and a collision somewhere
   else, and the assertion names both.
2. **The total must match the decode.** The three groups with their repeat counts must come
   to **713 bytes**, the size of the `NORMAL SOUND` area established separately from the
   program. The guide never prints that number and it was not used to build the
   transcription.

Together those pin every group boundary and both strides — and they did their job: the
strides they force (0x51 and 0x2B) reproduce the guide's own four columns
(`0D9/12A/17B/1CC`, `21D/248/273/29E`) exactly.

⚠ **What they do not check:** a parameter's name, bit field or range. A misreading there
survives, and the chapter says so rather than implying the whole table is verified.

```sh
python3 wsa1/notes/sysex-probes/sysex_sound_layout.py
python3 wsa1/notes/sysex-probes/sysex_sound_layout.py --tex \
    wsa1/docs/system-exclusive-reference/tbl-sound.tex
```

Pass: each group tiles its extent, the repeats land on the stride, the total is 713, `OK`.

### `sysex_effects.py` and `effects.json`

**Question:** does the transcribed effect catalogue agree with the one read out of the
ROMs?

An effect block's `TYPE` byte selects an effect and its twenty `VALUE` bytes mean whatever
that effect says they mean. `effects.json` transcribes both from the guide's DSP EFFECT
pages, which are image-only and had to be rendered and read.

The **numbers** are checkable against something entirely independent: this project had
already disassembled the effects DSP into `wsa1/dsp/programs.tsv`, a manifest of every
distinct effect program with the number that selects it. That came from the ROMs; the
guide is a printed book. The probe asserts **set equality** on the effect numbers — and
they are equal, 56 either side.

⚠ **Not checked:** the `VALUE` lists. Nothing independent states them, so a misreading
survives, and the chapter says so rather than implying the whole table is verified. The
two sources also differ in spelling by design — the ROM carries the short names the
instrument displays (`S.DELAY+CHORUS`), the guide the long ones — so the probe prints them
side by side and asserts only the numbers.

```sh
python3 wsa1/notes/sysex-probes/sysex_effects.py
python3 wsa1/notes/sysex-probes/sysex_effects.py --tex \
    wsa1/docs/system-exclusive-reference/tbl-effects.tex
```

Pass: the number sets are equal, no effect declares more than 20 values, `OK`.

### `sysex_sound_memory.py`

**Question:** what is inside the `SOUND` and `COMBINATION` blocks of a bulk dump?

Chapter 8 lays out the sound being **edited** — 713 bytes at `ADR 10 00 00`. The `SOUND`
bulk dump is a different thing: 262144 bytes of sound **memory**. A librarian that wants
to show or edit the sounds inside a dump needs to know whether the two agree.

They do, and the dump proves it by itself. If a stored sound uses that layout then sounds
must sit at a 713-byte stride with a printable 16-character name at offset 0, because
`NAME` is parameter `000`–`00F`. They do — **64 in a row in every one of four banks** —
and a stored drum kit's 128 note records likewise sit at a 150-byte stride with their
13-character names.

The strides are **not hard-coded**: they are read out of `sound_layout.json`, so if the
parameter layout is ever corrected and the dump stops matching it, this fails.

The control is the arithmetic: a stride one byte either side of 713 breaks the run at the
first record, which the probe asserts.

```sh
python3 wsa1/notes/sysex-probes/sysex_sound_memory.py
python3 wsa1/notes/sysex-probes/sysex_sound_memory.py --names   # list every stored sound
```

It resolves `COMBINATION` the same way: 16 combinations of 5632 bytes, each of **eight**
parts of 704, every one of the 128 parts carrying a 16-character name two bytes in — the
sound loaded into it. Eight parts is what a combination has. The combinations' own names
are the last 256 bytes of the smaller block.

It then divides a part: a 128-byte header, **eight records of 64 bytes**, and a 64-byte
tail — 128 + 8×64 + 64 = 704. The stride is fixed by two things the probe asserts: every
record's bytes 23–31 are zero in all 128 parts, and each record begins with its own index
0–7. The firmware confirms the outer figures independently, computing a part address as
`base + 0x1600 × combination + 0x2C0 × part`.

⚠ 704 is **not** 713, so a combination part is not simply a stored sound, and what the
eight records *are* is not established — the probe reports the structure and stops there.

Pass: four banks of `0x10000`, 128 notes per drum run, at least 64 sounds per bank, all
128 combination parts named, `OK`.

### `sysex_conversion_tables.py` and `conversion_tables.json`

**Question:** do the transcribed effect data tables check out arithmetically?

A `VALUE` byte is not a quantity. The guide's page 33 carries eighteen tables; fifteen turn a parameter into seconds, hertz,
decibels or cents, and three describe how several fields share two bytes. Without them a
librarian can label a control but not display it. All of them are here.

Like every transcription in this project they are checked rather than trusted — this time
by the tables' own arithmetic. Each row gives a parameter span, a first value, a last value
and a step, and those four numbers are **not independent**:

```
v_lo + step × (p_hi − p_lo) == v_hi
```

The guide prints all four, so the identity is redundant information a correct reading must
satisfy and a wrong one almost certainly will not. **41 rows, 41 chances to fail**, and all
41 hold. It is the same shape as the tiling check on the sound layout: the source
over-determines itself and the redundancy is the test.

The packings check themselves a second way: a field's width must be wide enough for the
range of the table it carries, and every one is **exactly** wide enough — 5 bits for a
parameter reaching 31, 5 for one reaching 26, 6 for one reaching 48. A misread width
would not land on the boundary.

⚠ Not checked: a table's title, its unit, or an enumerated table's words — those carry no
arithmetic.

```sh
python3 wsa1/notes/sysex-probes/sysex_conversion_tables.py
python3 wsa1/notes/sysex-probes/sysex_conversion_tables.py --tex \
    wsa1/docs/system-exclusive-reference/tbl-conversions.tex
```

Pass: every arithmetic row satisfies the identity, `OK`.

### `sysex_published_sizes.py`

**Question:** does the ROM accept exactly the dump sizes Technics published?

The bulk-dump table was decoded from the program — the eight `(ADR, SIZ)` pairs the
instrument matches literally on reception. Three of the four categories were then
confirmed against a capture. The fourth, `SEQUENCER`, could not be: the capture came from
a rack, and a rack refuses that category.

**It does not need a capture.** Technics printed the sizes on page 45 of the Reference
Guide, under "SIZ of data dump area". This asserts that the set the ROM accepts and the
set the guide prints are the **same set**, `SEQUENCER` included — two sources, a
disassembly and a printed book, sharing no path at all. They are identical, down to the
guide using the word *Variable* for the same block the ROM sizes at run time.

The guide also prints `SEQUENCER : WSA1 only` beside its request table, which is the same
restriction the firmware's feature table gives the rack.

⚠ What this does **not** settle: frame-level behaviour for `SEQUENCER` — checksums,
continuation, the acknowledgement handshake. Those are verified by capture on the other
three categories and the program runs all four through one path, but no `SEQUENCER`
transfer has been observed here.

```sh
python3 wsa1/notes/sysex-probes/sysex_published_sizes.py
```

Pass: the two sets are equal area by area, `OK`.

### `sysex_combination_layout.py`

**Question:** what is inside a stored combination?

⚠ **This probe corrected a structure two earlier commits had published.** A stored
combination is **704 bytes**, not 5632: `0x1600` is a *bank of eight*. What
`sysex_sound_memory.py` used to call a 704-byte "part" is a whole combination, and what it
called "eight 64-byte records" are the eight parts, two records each. The smaller
`COMBINATION` block's name tail is **bank** names, one per eight, not combination names.

The 704 bytes are a **tagged stream**: `{tag, length, payload}`, ending on `FF FF` and
filling 704 exactly. All 128 combinations in a real dump carry the same 23 records in the
same order.

The finding that makes it legible: **every tag is a record number in the parameter area**.
Tag `20` is part 1's own block — the same `20` that addresses part 1 in an `ITR` message —
so `param_names.json` names its fields directly. The records also run in RAM address order
with exactly two bytes between consecutive ones, which are the tag and length: the stream
is a copy of memory with its headers intact. That also explains the `78 10` this project
had recorded as the second `SYSTEM,PART & MIDI` block's *signature* — it is the first
record's tag and length.

★ It also surfaced something about one descriptor. `10/20` and `10/21` — `MAIN OUT
EQUALIZER LOW-FREQ` and `LOW-GAIN` — both name record `79` offset 1, with masks `1F` and
`3F`. Every stored combination holds 24 there, which is inside `LOW-GAIN`'s declared
`0..48` and outside `LOW-FREQ`'s `0..17`, in all 257 corpora. That is consistent with the
flag `sysex_param_addresses.py` already raises on `10/20` — its setter does not build its
target from `+6`/`+7`, so it writes somewhere the descriptor does not say. **The
reference is unaffected**: it reports no dump position for that parameter, and the name
and range it does print match the published table.

```sh
python3 wsa1/notes/sysex-probes/sysex_combination_layout.py
python3 wsa1/notes/sysex-probes/sysex_combination_layout.py --presets   # the 129 in ROM
python3 wsa1/notes/sysex-probes/sysex_combination_layout.py --fields
```

Pass: the stream tiles 704 in all corpora, every tag is a live record number, the range
and ordering tests hold, `OK`.

### `sysex_block_signatures.py --tex <file>` — and where the signature comes from

(The `--tex` mode is described above.) The probe also answers a second question:
**does anything check the signature?**

Block 1 of `SYSTEM,PART & MIDI` is 32 bytes held as a literal in prom_a at `0xFE704E`, and
two routines copy it into RAM — one of them into `0x7600`, which *is* that block. Both are
plain copy loops; **no comparison against the constant exists**, and none against its
leading `5A 5A` either. So the instrument writes its signature and never reads it back:
checking it is a librarian's job, not the instrument's.

Coverage of that negative, which the probe states and asserts: every three-byte pointer to
the constant (two sites, both copies, each verified to contain the load-store pair and a
bound at `0x20`), and every immediate compare against `5A 5A` across both 512 KiB images.
Code reaching the constant from another base would not be seen.

### `sysex_sequencer_layout.py`

**Question:** how is the `SEQUENCER` bulk-dump block arranged?

No capture here contains a `SEQUENCER` transfer — the one to hand came from a rack, which
refuses that category — so this project had recorded the arrangement as unknown and
waiting on a keyboard. **A capture is needed to see the data; the arrangement is in the
program**, and one routine gives it away.

`SongName_ResetToUnderscores` (prom_a `0xF818EA`) blanks a song's six-character name in
three places, and its destinations are literal: `0x6034CA` — the `LOCATION` block at
`+0xCA` — and `0x610000 + song*3072 + 0xCA`, the multiply written as `sla xwa,0x0b` plus
`sla xiy,0x0a`, added. So:

* the `HEADER` block is **ten song records of 3072 bytes** (10 × 3072 = 30720, the whole
  block, and the manual says ten songs);
* a song's **name is six characters at `+0xCA`** of its record;
* `LOCATION` carries the name at the **same** offset, so it is a song record too — the
  working copy of the one being edited, not a directory.

Every assertion is on literal instruction bytes, and the shift arithmetic is checked
against the block size rather than assumed.

⚠ Not settled: the other 3066 bytes of a record, and the variable-length `PERFORMANCE`
block that carries the recorded material.

```sh
python3 wsa1/notes/sysex-probes/sysex_sequencer_layout.py
```

Pass: the routine's bytes are as expected, `2^11 + 2^10 == 3072`, `30720/3072 == 10`, `OK`.

### `sysex_override_flags.py`

**Question:** what is byte `+0x15` of a part's first record?

One of the bytes no parameter reaches and no screen captions. It is a bit-field of **six
override flags**, one per `MIDI MULTIPLE MESSAGES OUTPUT` setting — each says whether the
part sends its own value or the internal one.

Six sibling gates in prom_a, each a `bit n,(XIY+0x15)` whose taken branch chooses between
a part's internal field and its override field:

| bit | gate | parameter |
|---|---|---|
| 0 | `0xF97459` | `20/60` PROGRAM CHANGE |
| 1 | `0xF974DB` | `20/63` VOLUME |
| 2 | `0xF9750B` | `20/64` PANPOT |
| 3 | `0xF9753B` | `20/66` CHORUS DEPTH |
| 4 | `0xF9756B` | `20/65` REVERB DEPTH |
| 5 | `0xF97489` | `20/61` BANK SELECT |

Not assigned by order: each gate is a distinct address whose displacement byte *is* `0x15`
and whose selector byte *is* the bit number, and the six parameters are independently
known to be exactly the six carrying a second write — `sysex_param_addresses.py` flags
those and only those.

⚠ Bits 6 and 7 are not named.

```sh
python3 wsa1/notes/sysex-probes/sysex_override_flags.py
```

Pass: all six are `bit n,(XIY+0x15)` at the stated bit, the bits are distinct, `OK`.

### `sysex_unnamed_bytes.py`

**Question:** what are the bytes of a combination that no parameter names?

`sysex_combination_layout.py` ends with a list of bytes some combination writes that no
parameter descriptor reaches. Four searches of the *program* had been run against them and
all four came back empty or powerless. This one asks from the **data** side: 257
combinations of eight parts is 2056 part records, each with its named neighbours beside it.

★ **Most of the list is not unknown, it is fixed.** Block A holds the same value in all
**3080 records across three independently produced corpora** — the presets in the program,
a user's flash dump, and the combination area of a native disk file — at `+02`, `+04`,
`+10` and `+15..+1A`; block B at `+00..+02`, `+0D`, `+11`, `+12` and `+15`. All read zero.
Adding the third corpus changed none of them, which is the point: a constancy claim is
worth exactly what its corpus is worth. "Reserved, write zero" is a stronger statement than
"unknown", and it is what the corpus supports.

★★★ **The trailing triple is a second `PROGRAM CHANGE & BANK`.** `+1B` and `+1C` are one
7-bit number split four bits and three; `+1D` is a bank from the same value set the part's
own bank uses. Of 890 parts carrying a non-zero one, number **and** bank both match the
part's own in 296, and **the number never matches without the bank matching too** (0
cases) — against a control, the same test against a neighbouring part, that lands 39 times.
The 4+3 split is confirmed from outside the dump by `sysex_remap_files.py`: a re-map is 16
groups of 8 holding `(number, source)` pairs.

★ An earlier hypothesis is refuted here rather than left standing: the triple is not a
*cache* of the sound, because the same program number carries two different triples in 36
cases. That is exactly what an indirection between the two copies produces.

★★★ **The equaliser is fully resolved — placement, bit layout and scale.** The guide's own
packing note says `EQ Fc` is **5 bits** and `EQ G` is **6 bits**: eleven bits do not fit in
a byte, so a band is a *two-byte* field and no single-byte descriptor could ever place it.
The declared ranges are the test — `GAIN` 0..48, `LOW` Fc 0..17, `HIGH` Fc 17..26, the last
two being sub-ranges of one 27-entry table (they overlap at 17).

The probe searches the **whole space**: every placement of a contiguous 6-bit gain and
5-bit index inside two bytes, both byte orders. **Exactly one of them** puts all 770 band
observations inside their declared ranges — little-endian, gain at bit 0, index at bit 6.
The low band's word is at dump `1002B3`, the high band's at `1002B5`. Factory setting
decodes to gain 24 (centre) in both bands, index 11 low and 17 high; the one instrument
that had moved its low band reads gain 18, index 7.

⚠ **One disagreement with the guide.** Its packed-field note for the pre/post equaliser
format gives the split as three bits in the first byte and two in the second. For
`MAIN OUT EQUALIZER` it is the other way round — that layout is inside the search and it
fails.

```sh
python3 wsa1/notes/sysex-probes/sysex_unnamed_bytes.py
```

Pass: a planted copy of `PANPOT` is found and a planted arithmetic column is not — without
both, "no copy found" would be worthless. The reserved sets, the triple's widths, the user
-data usage and the equaliser invariant are all asserted, `OK`.

### `sysex_firmware_generation.py`

**Question:** which generation of the firmware is the reference read from — measured
against a Technics document rather than against the ROM's own account of itself?

Technics issued a one-page multilingual erratum, `QQCG0279A`, whose single change renames
the second soft key of the `SOUND MODE` home screen from `VOL` to `LVL` and makes it adjust
the level relative to the current value, −30 to +30. **The dumped firmware already carries
the new caption**, so it post-dates that erratum. That is an external date for the dump;
the `ROM VERSION` screen only reports what the ROM says about itself.

★ The rename reached **one screen out of two**. The image holds four soft-key rows of this
shape: the two whose last key is `MIDI` — the screen the erratum photographs — read `LVL`,
and the two whose last key is `PART` still read `VOL`.

⚠ **An earlier draft of this probe asserted that no row says `VOL`, and the assertion
caught it.** The rows are therefore parsed whole and counted, not grepped: a bare search
for `VOL` hits `VOLUME` fourteen times in this image and would settle nothing. The probe
also checks that every row of the shape is accounted for, which is what turns "the rename
landed on one screen" from an impression into a count.

```sh
python3 wsa1/notes/sysex-probes/sysex_firmware_generation.py
```

Pass: exactly two rows of each form, all four rows of the shape accounted for, the erratum
scan matching its hash and confirmed image-only, `OK`.

### `sysex_song_layout.py`

**Question:** what is inside a song?

The largest thing the reference did not cover. No `SEQUENCER` dump exists for this project
— the rack refuses that category — but **a disk does just as well**: a community disk image
carries `01220497.SQF`, a native sequencer file of exactly 30 720 bytes, which is the
`HEADER` block. It decodes on the structure the firmware predicted with no adjustment:
ten records of 3072, each opening `5A 5A 5A 5A`, six printable characters at `+0xCA`.

★ **Most of a song record is material the reference already names.** From `+0x220` it is a
tagged stream in the combination's own form, in three parts: `+0220..+04DF` is a
**complete 704-byte combination**, `+04E0..+0AFF` carries parts 8–31 and record `7A`, and
`+0B00..+0B7F` holds records `98 99 80 91 93`.

★★ **A song has thirty-two parts** — tags `00..1F` block A and `20..3F` block B, complete
and without gaps, the same 32 the parameter grammar addresses. Eight arrive inside the
embedded combination and 24 follow it. That puts **2400 of 3072 bytes** under existing
names.

The check that carries the claim is an **equality against a structure derived from a
different source**: the first stream's `(tag, length)` list must equal `SHAPE` in
`sysex_combination_layout.py`, which was derived from the instrument's own uploads.
Agreement is not something this script can arrange for itself.

It also characterises the companion `.SEQ` (179 200 bytes), which is `PERFORMANCE`.
**Its format is decoded in `sysex_performance_stream.py`** — this probe keeps the two
negative results that preceded it, because both are instructive: a linear parse works for
85 records and then loses sync, and no column stands out as a status column at any width
or phase. Both are symptoms of the same thing — the file is blocks, and most of it is free
space holding stale bytes.

⚠ **A retraction this probe carries.** An earlier version argued that no chunk is empty and
the last byte is not padding, *therefore* all of it is live. That does not follow: one song
of ten is recorded here. Non-zero is not in use.

```sh
python3 wsa1/notes/sysex-probes/sysex_song_layout.py
```

Pass: ten records of 3072, three streams closing on their own terminators, 64 complete
part tags, the first stream equal to the combination shape and to 704 bytes, `OK`.

### `sysex_remap_files.py`

**Question:** what is a re-map, and why does it explain a combination's trailing triple?

A second copy of an address that usually differs from the first is an **indirection**, and
the instrument has one. The disk set carries RE-MAP files, and their shape is the evidence.

A re-map file is a 32-byte header — ASCII `WSA1 `, then three little-endian offsets and a
zero terminator — followed by three maps:

| file | kind | map size | layout |
|---|---|---|---|
| `.CRM` | COMBI RE-MAP | 528 | 1 name + **16 group names** of 16, then 128 entries of 2 |
| `.SRM` | SOUND RE-MAP | 528 | same |
| `.DRM` | USER DRUM MAP | 144 | 1 name of 16, then 128 entries of 1 |

★★ **Sixteen groups of eight is the same 4+3 split a part's trailing triple uses**, and the
entries are `(number, source)` pairs — which is what the triple holds. The source byte
takes 0,1,2,8,9 across these files; a part's `+1D` takes 0,1,8,9,0x20.

★ Eight of the nine maps are identities; the ninth is `GM RE-MAP`, and the probe asserts
that count so the non-identity one is *demonstrably* different rather than assumed to be.

★★ **The same format is in the firmware.** `prom_b` carries the three default map files
as literal images, `0x650` apart — which is 32 bytes of header plus three maps of 528. They
decode under the same rules with the same offsets and names, so the format is established
from **two sources that cannot have influenced each other**: a disk written by a user in
1997, and the ROM that wrote it. The one byte that differs is `+0x0F` — zero in every ROM
template, `0x31` in every saved file — so it is written at save time.

```sh
python3 wsa1/notes/sysex-probes/sysex_remap_files.py
```

Pass: offsets equally spaced, every name printable, `16*(groups+1) + 128*width == map size`
closes, eight identity maps, all three ROM templates matching, `OK`.

### `manual_sequencer_specs.py`

**Question:** what does the published manual say about the things this project measured?

The English owner's manual exists twice in the archive and **one copy carries an OCR text
layer** — the only Technics volume here that can be searched rather than rendered. It had
gone unread for the same reason the Reference Guide did: nobody looked inside the archive.

★★ It confirms, from a source that knew nothing of this decode:

| the manual says | what it confirms |
|---|---|
| "32 MIDI parts available (32-part multi-timbral)" | a song's part tags `00..1F` / `20..3F` — **32 parts** |
| "play back up to 10 performances" | `SEQUENCER` is **ten** song records of 3072 |
| "16 recording tracks" | the header's three 17-entry tables hold **one more than the tracks** |
| "16-track, 47,000 note Sequencer" | ~4 bytes a note — the only external constraint on the event encoding |

```sh
python3 wsa1/notes/sysex-probes/manual_sequencer_specs.py
```

Pass: all five phrases present in the extracted text, both hashes matching, `OK`.

### `sysex_triple_writer.py`

**Question:** what code writes and reads a part's trailing triple?

An earlier edition said naming those bytes needed "the writer caught in the act rather than
found by searching", and then searched four more times. ★ **The search that works is
neither of the ones tried.** Those bytes are never named by an absolute address — a part
record is reached through a pointer — so searching for their RAM addresses finds nothing,
which is exactly what happened. They *are* named by displacement off that pointer, and
`(XIY+0x1b)`, `(XIY+0x1c)`, `(XIY+0x1d)` are short distinctive byte strings.

★★ **Three sites write all three bytes, three read all three, and no site anywhere touches
one of them on its own** — the probe asserts that last part, so "they are one field" is a
measurement rather than an impression.

★★ At the writing site the values come back from a conversion whose input is written to a
fixed address as **two** bytes and whose result is read from another as **three**, with an
inverse beside it taking three and returning two. A three-byte form of a two-byte quantity
is what a program number plus a bank becomes.

⚠ H and L here are two byte registers, not a 16-bit pair — the consumer stores them to two
separate addresses. That matters because "one 16-bit HL" is the obvious rival to the 4+3
split, and the data rejects it 4 matches to 296.

```sh
python3 wsa1/notes/sysex-probes/sysex_triple_writer.py
```

Pass: 3 writing groups, 3 reading groups, zero loose sites, `OK`.

### `sysex_blockb_tail.py`

**Question:** does any code handle block B's `+0x18`, `+0x19` and `+0x1A`?

The data side was exhausted (no copy, no run copy, no determinant). This asks the program,
by displacement rather than by address — block B sits `0x20` past block A, so the bytes are
either `(reg+0x38..0x3A)` or `(reg+0x18..0x1A)`.

* From block A's base: **zero** groups touch all three, in either image.
* From block B's base: five groups, **none of them a part record**. Two are inside a
  64-entry uniform 3-byte table that unidasm refuses to decode as instructions at all.

★★ **The discriminator is controlled.** "Is this a part record" is tested by the step that
turns a table index into a part slot (`add IY,0x0080`). It **fires on the sites that write
the triple next door** and on none of these five. The probe asserts the control fires — a
negative from a test that cannot fire is worth nothing.

★★ **Every individual access is examined, across all four images** — including both of the
second processor's — not only groups of three, because a routine touching one byte alone
would slip past a grouping test. **127 accesses**; 3 come near the part pointer table and
all 3 are in *one* routine that indexes it **without** the `0x80` step that selects a part,
so they reach a sibling structure; **0 reach a part record**. Control: 6 of 91 accesses at
`+1B..+1D` do reach one, including the triple's writers.

★ **Conclusion, and it is actionable:** these three bytes are carried in stored data and
copied wholesale; no code on either processor treats them as fields. Preserve them, do not
compute them.

```sh
python3 wsa1/notes/sysex-probes/sysex_blockb_tail.py
```

Pass: 0 groups block-A-relative, 5 block-B-relative with none near the part-record step,
control firing, `OK`.

### `sysex_performance_stream.py`

**Question:** how is a recorded performance stored?

The reference's largest undecoded area, and **two earlier attempts on it failed in ways
worth recording**. A linear parse works for 85 records then loses sync. A block-chain
search — four block sizes × every link offset × both byte orders — returned nothing, and on
that basis this project **withdrew a correct hypothesis**.

★★★ **The firmware settles it in four instructions:**

```
sub  XWA,0x00617800     ; the base of PERFORMANCE in CPU 1 RAM
sra  0x08,XWA           ; >> 8   -- blocks are 256 bytes
inc  1,XWA              ; ...and are numbered from ONE
```

⚠⚠ **The chain search had numbered blocks from zero.** Every block it examined was the one
before the block it meant. The hypothesis was right and the test that appeared to kill it
was mis-specified — a more dangerous error than a wrong guess, because a negative result
looks like diligence.

**The format.** 256-byte blocks numbered from 1; 5-byte header; next block is a 16-bit LE
number at `+03` (where `ld HL,(XHL+0x03)` reads it); data `+05..+FF`. The song header's 17
entries are each track's first block — following them gives **560 blocks in 17 disjoint
chains**. A track is then a flat event stream, `[status ≥ 0x80][N data bytes < 0x80]`:

| status | data | |
|---|---|---|
| `81` | 0 | advance the clock one step (19 980 of the 41 646 events) |
| `90` | 5 | note: offset, note number, velocity, gate lo, gate hi |
| `B0`,`B4` | 5 | controller |
| `C0` | 5 | program change |
| `D2`,`E0` | 3 | |
| `D1` | 2 | |

★★★ **41 646 events parse with not one byte left over.** And every event's first data byte
is its offset within the step: within a step those offsets go backwards 11 times in 15 306
pairs (0.07%), where the same events **shuffled** go backwards 38.8%.

★★ **It also settles which entry is which track.** A `B0` event names the part it
addresses in its second data byte, and for **16 of the 17** entries *every* such event in
the chain names the entry's own index — control (each entry paired with the next entry's
chain): **0 of 17**. The 17th names no part at all, which matches Technics publishing
sixteen *recording* tracks.

⚠ A chain's last block is partly used and its tail holds stale bytes; excluding it is not a
convenience — with it left in, the stale events appear as the same `{1,2,5,12}` in every
chain, which is how the tail was noticed.

```sh
python3 wsa1/notes/sysex-probes/sysex_performance_stream.py
```

Pass: 17 disjoint chains totalling 560 blocks, zero stray bytes, the per-status lengths,
the offset ordering beating its shuffled control, and 16 entries naming themselves with the
control at 0, `OK`.
