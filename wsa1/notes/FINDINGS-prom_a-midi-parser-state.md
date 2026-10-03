# prom_a: the state bytes of the two MIDI parsers (2026-10-03)

The banner above prom_a's foreground MIDI consumer (0xFA5942) establishes that the firmware has two
MIDI state machines of the same shape. Each keeps a running status, a flag byte and a SysEx state:

- the interrupt-time parser `MIDI_RX_Byte` (0xFA5496 onwards), in the direct page;
- the foreground consumer `MIDI_Fg_*`, in its own private copies.

In both flag bytes, bit 6 is "a first data byte is pending". Bit 1 goes with it, and both are
cleared by the same `and ...,0xBD`. The routine headers named below give the rest. Operands
re-counted with:

    python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x9a 0x9e 0xa9 0x0960 0x0961 0x0963 0x0964 0x0931 --sites

That census also lists many `.byte` / `.short` / `pushw` hits for the direct-page values
0x9A / 0x9E / 0xA9. Those are immediates and table bytes that happen to equal the address.
`name_wsa1_ram.py` renames a value below 0x100 only in an address position, so they stay numbers.

| address | name | holds | evidence |
|---|---|---|---|
| 0x009A | `MIDI_RX_RunningStatus` | the interrupt parser's running status; 4 `ld (0x9A),0` plus one load and one store | the 0xFA5942 banner; MIDI_RX_Byte |
| 0x009E | `MIDI_RX_Flags` | its flag byte. Bit 6 = first data byte pending, cleared with bit 1 by `and (0x9E),0xBD` (3 sites). Bits 2, 3 and 5 are requests that `MainTask_Loop` services: `and A,0x2C`, then `MidiInARing_Init` and `and (0x9E),0xD3`. Bit 2 is set by the two queue-full paths, bit 3 by `MIDI_RX_ErrorReset`, bit 5 by `MIDI_Fg_RealTime__reset`. Bit 7 (`MIDI_RT_Received`) is what `INTT1_Tick` tests | the banner; MIDI_RX_DataByte / MIDI_RX_SecondDataByte; MainTask_Loop 0xF8205B |
| 0x00A9 | `MIDI_RX_SysExState` | its SysEx state: bits 0, 1 and 5 tested; `and (0xA9),0xCC` | the banner; MIDI_RX_SysExStart / MIDI_RX_SysExData |
| 0x0960 | `MIDI_Fg_RunningStatus` | the foreground consumer's running status | the banner |
| 0x0961 | `MIDI_Fg_FirstData` | the first data byte of a two-byte message, kept until the second arrives | MIDI_Fg_StashFirstData (`ld (0x0961),(XIZ+8)`), MIDI_Fg_Deliver3 |
| 0x0963 | `MIDI_Fg_Flags` | bit 6 = first data byte pending (set by MIDI_Fg_StashFirstData, tested by MIDI_Fg_DataByte); `and (0x0963),0xBD` clears bits 6 and 1 | the banner; MIDI_Fg_Deliver3 |
| 0x0964 | `MIDI_Fg_SysExState` | bit 0 = a SysEx is open; bit 1 = set by MIDI_Fg_SystemCommon (written 3) and the gate for MIDI_Fg_SysExData's ring put; 4 = a SysEx closed normally, 0 = abandoned | MIDI_DrainQueue__status, MIDI_Fg_SystemCommon, MIDI_Fg_SysExData |
| 0x0931 | `MIDI_RX_ErrorCount` | the 8-bit receive-error counter `MIDI_RX_ErrorReset` increments (`inc 1,(0x0931)`, 8-bit per its header) | MIDI_RX_ErrorReset |

⚠ Not established: what (0x0964) = 4 means to whoever reads it, as the `MIDI_DrainQueue` header
already states. Also open: why `PanelGroupQueue_Append` sets bit 3 of (0x9E), and why
`MidiOut_PostStagedMessage` sets bit 0. They are the two owners from outside the MIDI-in path.
