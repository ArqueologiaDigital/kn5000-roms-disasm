# SysEx receive probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |
| `sysex_error_codes.py` | Which internal status code raises `ERROR 40!`, `ERROR 41!` or `ERROR 42!`, and where in prom_a is each one raised? | `python3 wsa1/notes/sysex-probes/sysex_error_codes.py` (table) or `--sites` (every raise site) |

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
