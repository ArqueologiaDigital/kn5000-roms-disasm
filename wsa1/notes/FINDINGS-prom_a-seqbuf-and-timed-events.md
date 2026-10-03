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
