# prom_a: how notes reach the voices -- note frames (2026-10-04)

prom_a 0xFC80E2-0xFCB3xx is where every note and controller event is processed, whatever its source. Each
source has a processor that drains its ring into **frames** and passes each frame through the same stages.

## 1. The four sources

| processor | directory slot | ring | gatherer |
|---|---|---|---|
| `MidiInA_ProcessRing` | `T_MidiInA_ProcessRing` | `MidiInARing` (MIDI IN A) | `MidiInA_GatherFrame` |
| `MidiInB_ProcessRing` | | `MidiInBRing` (MIDI IN B) | `MidiInB_GatherFrame` |
| `TimedEvents_ProcessRing` | `T_TimedEvents_ProcessRing` | `TimedEvents_Ring` (sequencer playback, auditions, ...) | `TimedEvents_GatherFrame` |
| `Ring601850_ProcessNoteEvents` | `T_F413B8` | `Ring601850`, pairs (note, velocity) | `Ring601850_GatherFrame` |

## 2. The frame

A gatherer fills a frame on the processor's stack:

| offset | holds |
|---|---|
| +0 | the number of entries |
| +1 | the kind: 0x90 notes, 0xB0 a control change |
| +2 | 1 |
| +3 | the channel |
| +7 | the entries, 9 bytes each: +0 the note, +1 the velocity (0 = note off); the later stages fill the rest |

The MIDI gatherers collect consecutive note-on / note-off messages on **one** channel, up to 32, into one
frame. A control change is a frame of its own. A message on another channel ends the frame, and is kept in
a 5-byte "pending" record for the next call: kind, channel, a constant 1, data 1, data 2. A pending byte
of 0xFF means the ring is empty. The `Ring601850` gatherer takes up to 16 pairs.

`TimedEvents_ProcessRing` maps a frame's channel to a part through `BStore_TrackToPart` (workspace +0x22,
16 bytes, 0xFF = no part) before the voice stages.

## 3. Not established yet

- What the later stages (`sub_FC9C1D`, `sub_FC9EA3`, `sub_FC9F8B`, `sub_FCA6BB`, `sub_FCAE76`, `sub_FCB1BB`)
  do with an entry.
- What the state at 0x602200 / 0x6020D4 / 0x602492 / 0x602493 holds.
- Three of the sinks are visible: the tone generator over the link (`T_Link_SendBlockIn32ByteChunks`), the
  MIDI OUT rings 0x601432 / 0x60153C (`sub_FCAA98`), and the sequencer's record buffer (`sub_FCACAA` puts
  5-byte 0x90 events on `SeqBufRing` with `Seq_BeatTick`).
