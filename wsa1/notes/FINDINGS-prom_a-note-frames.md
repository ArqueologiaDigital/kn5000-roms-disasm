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

## 4. Parts and their three outputs (2026-10-04)

Every processor walks the 32 parts in the frame's voice mask. For each part, `NoteFrame_SelectForPart` picks
its entries, and `PartNotes_ApplyFrame` does the per-part bookkeeping:
- `PartNote_Budget` (0x3800) is 32 bytes, 24 each at start.
- `PartNoteList_Heads` (0x39F7) are 32 self-linked heads of 15-byte nodes, over the 129-node pool at 0x3BD7.
- A note-on takes a node while the part's budget allows. A note-off finds the part's node by note, source
  and channel, replays it with velocity 0, and frees it.

Each entry goes to up to three outputs, given by the part block:

| bit | output | the note sent | sender |
|---|---|---|---|
| 0 | the tone generator | `PartNote_MapForToneGen` (T_F41044), velocity + offset (`PartNote_ApplyVelocityOffset`) | `PartFrame_SendToToneGen` |
| 1 | MIDI OUT (skipped while 0x602493 bit 5 is set) | `PartNote_TransposeForMidiOut`, octave-folded | `PartFrame_SendToMidiOut` |
| 2 | the sequencer's record buffer | the note as received | `PartFrame_RecordToSeqBuf` |

On screen 0x28 (DRUM EDIT) the tone-generator and MIDI OUT notes are replaced by `EditCursor_Note`. That is
why a DRUM EDIT row audition sounds the row's drum.

## 5. The routing block at 0x602200 (2026-10-04)

`NoteRouting` (0x602200) is the "part block" the stages above pass around. Read off `NoteRouting_ForPart` and
`NoteRouting_ForTrack`:

| offset | holds |
|---|---|
| +0x02 + part | the tone-generator part the part plays (0xFF = none) |
| +0x22 + part | the part's MIDI OUT channel: 0..15 port A, 16..31 port B |
| +0x42 + track | the part a sequencer track feeds (bit 7 when recording), 0xFF = none |
| +0x52 + track | a sequencer track's MIDI OUT channel |
| +0x62 + 6 x part | the part's key / velocity range record |
| +0x92 + 6 x part | the tone-generator record of the part (bit 5 of its first byte: the output is on) |
| +0x152 + 10 x part | the MIDI OUT record of the part (bit 5: on) |
| +0x293 | bit 3 MIDI OUT port B allowed, bit 4 port A, bit 5 no tone-generator output |
| +0x298 | bit 9 (word): no tone-generator output |

A missing output points at the default record 0x602ACA.

**Rebuilding it.** Three entry points rebuild the block:
- `NoteRouting_RebuildForSong` (`T_NoteRouting_RebuildForSong`): boot, leaving SONG SELECT, CYCLE PLAY EDIT.
- `NoteRouting_Rebuild` (`T_NoteRouting_Rebuild`): COMBINATION MODE's part step, mode changes.
- `NoteRouting_SetSoloAndRebuild` (`T_NoteRouting_SetSoloAndRebuild`): COMBINATION MODE's SOLO key, the screen's leave, COMPARE.
  It sets or clears `NoteRouting_Mode` (0x602498) bit 5, the solo flag. Bit 6 forces the tone-generator
  outputs on, and bit 7 means recording.

Each entry point:
1. sets byte +0 = (0x4C22) | (0x4C21);
2. runs the per-mode builder `Dispatch32_FC6546[PanelMode]`;
3. refreshes `NoteRouting_ActivePartMask` (0x4C06), which is `BitMask32_Table_FC64C6[+1]`, or the +0 byte
   when +1 is 0xFF; the part masks are re-sent when it changes;
4. runs `NoteRouting_RebuildOutputs`, which rebuilds the output tables `NoteRouting_RebuildFlags` (0x4C04)
   selects and copies the block to `NoteRouting_Previous`
   (0x602600). The output rebuilders read that previous copy.

## 6. Not established yet

- What the later stages (`NoteList_ApplyFrame`, `NoteFrame_SelectForPart`, `PartNotes_ApplyFrame`, `PartFrame_SendToToneGen`, `NoteRouting_ForPart`, `NoteRouting_ForTrack`)
  do with an entry.
- What the state at 0x602200 / 0x6020D4 / 0x602492 / 0x602493 holds.
- Three of the sinks are visible: the tone generator over the link (`T_Link_SendBlockIn32ByteChunks`), the
  MIDI OUT rings 0x601432 / 0x60153C (`PartFrame_SendToMidiOut`), and the sequencer's record buffer (`PartFrame_RecordToSeqBuf` puts
  5-byte 0x90 events on `SeqBufRing` with `Seq_BeatTick`).
