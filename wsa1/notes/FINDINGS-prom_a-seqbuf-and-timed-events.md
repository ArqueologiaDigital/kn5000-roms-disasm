# prom_a: the sequencer buffer, the timed-event ring and the 96-tick counter (2026-10-03)

From round-1 pack prom_a-s00 (read and applied 2026-10-03), re-checked against the code.

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x93 | `Seq_BeatTick` | the tick within the beat, 0..0x5F: INTTR4_SequencerTick increments it and wraps at 0x60; MIDI_RT_Start_ResetCounters clears it; MIDI_Clock_CatchUp steps it | TimedEvents_IsNotYetDue compares an event's stamp with it `mod 0x60` (an event is due unless it lies 1..47 ticks ahead) |
| 0xC2 | `MainTask_TickCountdown` | ticks until the main loop's periodic pass: INTTR4_SequencerTick decrements it, MainTask_RearmTickCountdown reloads 10 | MainTask_RearmTickCountdown |
| 0xAA | `SeqBuf_Flags` | bit 0: append through the staging buffer (the trace path) | SeqBuf_AppendEvent / _AppendMarker test it, SeqBuf_FlushStaged clears it |
| 0xAC | `SeqBuf_StagedCount` | bytes staged at SeqBuf_Staged (word) | SeqBuf_FlushStaged, SeqBuf_Append*__trace |
| 0xAE | `SeqBuf_Staged` | the staged bytes | SeqBuf_FlushStaged (`ld XIX,0xae`) |
| 0x600A14 | `SeqBuf_Ring` | the 0x200-byte ring SeqBuf_PutByte writes; its descriptor sits below it (base - 8 .. base - 2) | Ring600A14_* (Init / Put / Get / Scan), SeqBuf_PutByte |
| 0x600A10 | `SeqBuf_RingPut` | the ring's write index (base - 4) | SeqBuf_PutByte: byte at SeqBuf_Ring + index, index + 1 mod 0x200 |
| 0x600A12 | `SeqBuf_RingFree` | the ring's free count (base - 2) | SeqBuf_PutByte decrements it, drops the byte at 0; SeqBuf_AppendEvent `cp (..),2` |
| 0x60080A | `TimedEvents_Ring` | the timed-event ring TimedEvents_DrainDue / _DispatchDueRun walk | Ring60080A_* (Init / Put / Get / Scan), TimedEvents_Service |

## 2. The MIDI-in rings, and the ring routines renamed (same day)

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x600C1E | `MidiIn_PortARing` | the 0x400-byte ring of MIDI port A's received bytes | MidiIn_PumpPortA drains it (ScanRewind + MidiIn_FetchMessage_PortA); MidiIn_RoutePortA splits it at the first class change |
| 0x601028 | `MidiIn_PortBRing` | the same for port B | MidiIn_PumpPortB, MidiIn_RoutePortB |

The ring class's per-instance routines (FINDINGS-prom_a-ring-buffers.md section 2) were named after the
ring address; the four rings whose contents are now known have semantic families: `Ring600A14_*` ->
`SeqBufRing_*`, `Ring60080A_*` -> `TimedEventRing_*`, `Ring600C1E_*` -> `MidiInARing_*`, `Ring601028_*`
-> `MidiInBRing_*` (37 routines, and their 36 prom_b thunks `T_...`).  The other ten rings keep their
address names: what they carry is still not established.

## MIDI Song Position Pointer and Song Select (2026-10-05)

The MIDI IN handlers `MidiIn_SongPosition` (0xF2) and `MidiIn_SongSelect` (0xF3) store the message and set bit 7
as a "pending" flag. Bit 7 is set only when that message's receive enable is on: (0x7F34) bit 2 for the
position, (0x7F33) bit 3 for the select.
- `MidiIn_SongPositionLo` / `_Hi` (0xA4 / 0xA5) hold the 14-bit position in sixteenth notes.
- `MidiIn_SongSelectValue` (0xA3) holds the song number.

Two consumers handle them:
- **The sequencer tick**, through `Seq_LocateToSongPosition`, while tracks are playing and transport B is
  stopped:
  - beats = position >> 2;
  - tick in the beat = `WorkspaceDefaults+0x77[position & 3]`, the bytes 0 / 24 / 48 / 72 (a sixteenth at 96
    ticks a beat);
  - position 0 rewinds (`Seq_RewindToStart`);
  - any other position locates each of the 17 tracks.
- **The MIDI file player**, through `MidiFilePlay_OnSongSelect` (`T_MidiFilePlay_OnSongSelect`), while transport C is stopped: the
  song number selects directory entry N (at most 0x13), and that file is loaded.

Related: `Seq_StopPlaybackOnRequest` ((0x34D2) bit 1) releases the tracks' notes and resets the controllers of
the playing slots (`SeqEvt_ResetPlayingSlotControllers`: pressure 0, modulation 0, pitch bend centre, expression
127). Then it clears the playing-track mask (0x60341E).
