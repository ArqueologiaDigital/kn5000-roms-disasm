# Control-panel serial link: probes

Scripts that answer questions about the KN5000 <-> control-panel link by reading the shipped ROM
images only. None of them reads the disassembly sources, so a misreading of the sources cannot
make a check pass. Findings are written up in `docs/kn5000-control-panel-panel-side.md`;
the KN5000 end of the link is in `docs/kn5000-control-panel-serial.md`.

Run everything from the repository root.

## `cpserial_two_implementations.py`

**Question:** `docs/kn5000-control-panel-serial.md` states in bold that the bootloader's CP-serial
driver "is INDEPENDENT of the runtime `CPanel_*` protocol stack ... nothing proven here transfers
to the runtime driver, and vice versa." Is that true?

    python3 analysis/cpanel-protocol-probes/cpserial_two_implementations.py

Exits **non-zero** if any check disagrees, so it is a gate, not a report. Six families of check,
each an exact byte encoding with an exact expected hit count, over
`kn5000_table_data.rom` (bootloader) and the v7/v9/v10 program ROMs.

Answer, 2026-08-22: **not true — it is one implementation at two link addresses.** All checks
pass. The 15 host->panel control frames occur with identical multiplicity in all four images; the
frame-length rule appears exactly twice per image; the receive and transmit dispatch tables have
identical shapes; and the 2-byte report handler is byte-identical across all four apart from one
32-bit immediate, the button-state array base (boot `0x1022`, v7 `0x8dae`, v9/v10 `0x8e4a`). Using
each image's own base, the four power-on button combos and the startup-poll mode block are each
found exactly once in all four.

Negative control (a check that cannot fail is not a check): changing one expected combo constant
from `0x6c` to `0x6d`, or one byte of the frame-length encoding from `cp a,0x30` to `cp a,0x31`,
makes the script exit 1. Both were run on 2026-08-22.

The consequence that matters: the bootloader's `Boot_ClassifyDeviceID` is not a device probe, it
is the boot copy of `CPanel_CheckSpecialCombos`, and the bootloader's "XOR-scramble buffer at
0x1022" is the button-state array.

## `panel_message_space.py`

**Question:** what is the complete set of messages the panel can put on the wire, and what does
the KN5000 do with each?

    python3 analysis/cpanel-protocol-probes/panel_message_space.py

The receive path is a total function of the frame's first byte, so enumerating 256 first bytes
enumerates the whole inbound message space. The script extracts the three addresses it needs (the
button-state array base, the receive dispatch table, the analog-handler table) by byte pattern
rather than hard-coding them, and fails loudly if a revision does not match.

Answer, 2026-08-22: of the 256 possible first bytes, **64 are button-segment reports, 32 are
analog-controller reports, 96 are sync/ACK frames that are consumed and discarded, and 64 open a
variable-length run**. The analog handler table has 32 entries of which **26 share one default
handler**; the six distinguished analog sources are encoder ids 2, 5, 25, 26, 27 and 31, reachable
as first bytes `0x12`, `0x15`, `0xd1`, `0xd2`, `0xd3`, `0xd7`. Identical in v7/v9/v10. The
bootloader copy has **no** analog handler table: its analog decode hook is a stub that always
reports failure, so the panel's analog controllers are read and discarded during boot.
