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

## 3. The note lists (2026-10-04)

`MidiFrame_ToNoteFrame` turns a MIDI frame into a **note frame**:
- +0 is the count;
- +1 is the **source**: 0 for `Ring601850`, 1 for MIDI IN (both ports), 2 for the timed-event ring. The
  gatherers write it at the MIDI frame's +2.
- Then come 7-byte entries from +2: note, a byte `Note_TransposeFoldOctaves` fills, velocity, and a 32-bit
  voice mask.

`NoteList_ApplyFrame` keeps the sounding notes in doubly linked lists of 13-byte nodes:
- A node carries the 7-byte entry at +2, the previous link at +9 and the next link at +0x0B.
- `NoteList_Heads` (0x3823) holds three self-linked heads, one per source.
- The free nodes are the 33-node ring at 0x384A; nodes are taken after node 0x384A.
- `NoteList_FreeCount` (0x3820..0x3822) counts each source's remaining notes. Its image starts each at 16,
  so each source can hold 16 notes.
- `Ram3800_DataImage`'s header lists this layout and says "NOT claimed: what a slot, a queue ... MEANS".
  The queue, at least, is now established: one per note source.
- A **note-on** takes a free node, when its source still has a count, and moves it to the source's list
  (`NoteList_MoveNode`).
- A **note-off** finds the source's node with the same note, returns it to the free list, and adds its
  voice mask to the routine's result.
- An entry that cannot be placed is marked 0xFF.

`NoteFrame_SelectForPart` keeps, for one part, the entries:
- whose voice mask overlaps the part's mask, `Part_VoiceMasks` (0x602054, 32 bits per part);
- whose note and velocity lie inside the part's range record (6 bytes at +0x62 of the part block). These are
  the KEY / VELOCITY LAYER limits.

`Note_TransposeFoldOctaves` adds (shift - 0x40) to a note and folds the result back into 0..127 by
octaves.

## 4. Not established yet

- What the later stages (`NoteList_ApplyFrame`, `NoteFrame_SelectForPart`, `sub_FC9F8B`, `sub_FCA6BB`, `sub_FCAE76`, `sub_FCB1BB`)
  do with an entry.
- What the state at 0x602200 / 0x6020D4 / 0x602492 / 0x602493 holds.
- Three of the sinks are visible: the tone generator over the link (`T_Link_SendBlockIn32ByteChunks`), the
  MIDI OUT rings 0x601432 / 0x60153C (`sub_FCAA98`), and the sequencer's record buffer (`sub_FCACAA` puts
  5-byte 0x90 events on `SeqBufRing` with `Seq_BeatTick`).
