# SysEx receive probes

| script | question it answers | run |
|---|---|---|
| `sysex_grammar_dump.py` | After `F0 <50\|7E>`, which byte sequences does the firmware accept, and which internal command number does each one produce? | `python3 wsa1/notes/sysex-probes/sysex_grammar_dump.py` (tables) or `--paths` (accepted sequences) |

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
