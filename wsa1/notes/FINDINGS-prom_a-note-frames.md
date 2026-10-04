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

**Corrected 2026-10-04 (section 7).** Three rows of this table were wrong:
- "+0x22 + part | the part's MIDI OUT channel". It is the part's MIDI channel in both directions. MIDI OUT
  sends on it while the part's record has bit 5. The MIDI IN processors' per-channel path receives on it while the
  record has bit 6 (`MidiInA_ProcessRing` at 0xFC8222).
- "+0x152 + 10 x part | the MIDI OUT record of the part (bit 5: on)". It is the part's MIDI record: bit 5
  transmit, bit 6 receive.
- "+0x293 | ... bit 5 no tone-generator output". Bit 5 turns the per-part MIDI OUT off
  (`NoteRouting_ForPart` 0xFCAEEE sets out+1 = 0xFF). Instead, `Ring601850_ProcessNoteEvents` (0xFC8893) sends
  source 0's notes on the single channel +0x292. Bits 6-7 are the MIDI IN mode. +0x292 and +0x293 are now
  `NoteRouting_SingleChannel` and `NoteRouting_MidiFlags`.

Step 4 below also said `NoteRouting_RebuildOutputs` "rebuilds the output tables `NoteRouting_RebuildFlags`
(0x4C04) selects" and that "the output rebuilders read that previous copy". There are no output tables. The
routine queues and applies note releases (section 7). It is now `NoteRouting_CommitChanges`, and 0x4C04 is
`NoteRouting_ChangeFlags`.

A missing output points at the default record 0x602ACA.

**Rebuilding it.** Three entry points rebuild the block:
- `NoteRouting_RebuildForSong` (`T_NoteRouting_RebuildForSong`): boot, leaving SONG SELECT, CYCLE PLAY EDIT.
- `NoteRouting_Rebuild` (`T_NoteRouting_Rebuild`): COMBINATION MODE's part step, mode changes.
- `NoteRouting_SetSoloAndRebuild` (`T_NoteRouting_SetSoloAndRebuild`): COMBINATION MODE's SOLO key, the screen's leave, COMPARE.
  It sets or clears `NoteRouting_Mode` (0x602498) bit 5, the solo flag. Bit 6 forces the tone-generator
  outputs on, and bit 7 means recording.

Each entry point:
1. sets byte +0 = (0x4C22) | (0x4C21);
2. runs the per-mode builder `NoteRouting_BuildByPanelMode[PanelMode]`;
3. refreshes `NoteRouting_ActivePartMask` (0x4C06), which is `BitMask32_Table_FC64C6[+1]`, or the +0 byte
   when +1 is 0xFF; the part masks are re-sent when it changes;
4. runs `NoteRouting_CommitChanges`. It releases the notes whose routing changed (section 7), then copies
   the block to `NoteRouting_Previous` (0x602600) and clears `NoteRouting_ChangeFlags` (0x4C04).

## 6. Not established yet

- What the later stages (`NoteList_ApplyFrame`, `NoteFrame_SelectForPart`, `PartNotes_ApplyFrame`, `PartFrame_SendToToneGen`, `NoteRouting_ForPart`, `NoteRouting_ForTrack`)
  do with an entry.
- What the state at 0x602200 / 0x6020D4 / 0x602492 / 0x602493 holds. (0x602492 / 0x602493: section 7.)
- Three of the sinks are visible: the tone generator over the link (`T_Link_SendBlockIn32ByteChunks`), the
  MIDI OUT rings 0x601432 / 0x60153C (`PartFrame_SendToMidiOut`), and the sequencer's record buffer (`PartFrame_RecordToSeqBuf` puts
  5-byte 0x90 events on `SeqBufRing` with `Seq_BeatTick`).

## 7. Releasing the notes a routing change orphans (2026-10-04)

A rebuild can move a part to another channel, a track to another part, or MIDI IN to another path.
`NoteRouting_CommitChanges` (0xFC5C7C) sends note-offs for the notes still sounding on the old route. The
evident purpose, not verified on hardware, is that their own note-offs will now arrive by the new route.

1. It zeroes `NoteRouting_ChangeCount` (0x602A00).
2. It runs the differs that `NoteRouting_ChangeFlags` selects. Each one compares the block with
   `NoteRouting_Previous` and queues a 4-byte record (kind, a, b, c) for each difference through
   `NoteRouting_QueueChange` into `NoteRouting_ChangeQueue` (0x602A02).
3. It applies the queue (`T_NoteRouting_ApplyQueuedChanges`).
4. It copies the block to the previous one and clears the flags.

`NoteRouting_ApplyQueuedChanges` dispatches each record's kind through `NoteChange_HandlerTable` (0xFC8DB2,
nine entries) with (a, b, c). Handlers 0, 2, 3, 5 and 6 do nothing when the old value c is 0xFF. Every handler
except 1 and 4 (bare rets) builds note-offs with `PartNotes_BuildReleaseFrame` or `NoteList_BuildReleaseAllFrame`
and sends them.

| kind | queued by (flag bit) | record | handler: what gets note-offs |
|---|---|---|---|
| 0 | `NoteRouting_QueueMidiInChanges` (5) | part, new / 0xFF, old channel | `NoteChange_ReleasePartReceivedNotes`: the part's MIDI IN notes on the old channel; all three outputs |
| 1 | none found | | a bare ret |
| 2 | `NoteRouting_QueueTrackChanges` (6 or 7) | track, new, old MIDI OUT channel (+0x52) | `NoteChange_ReleaseTrackMidiOutNotes`: the track's notes on its part; MIDI OUT only |
| 3 | `NoteRouting_QueueTrackChanges` (6 or 7) | track, new, old part (+0x42) | `NoteChange_ReleaseTrackNotesOfOldPart`: the track's notes on the old part; tone generator and MIDI OUT |
| 4 | `NoteRouting_QueueToneGenPartChanges` (never called) | part, new, old tone-generator part (+0x02) | a bare ret |
| 5 | `NoteRouting_QueuePartTransmitChanges` (5) | part, new / 0xFF, old channel | `NoteChange_ReleasePartTransmittedNotes`: the part's note-list notes (sources 0 and 1); MIDI OUT only |
| 6 | `NoteRouting_QueueTrackPartChanges` (6) | track, new, old part | `NoteChange_ReleaseRecordedNotesOfOldPart`: the old part's note-list notes; record buffer only |
| 7 | `NoteRouting_QueueMidiInChanges` (5) | path, 0xFF, channel | `NoteChange_ReleaseMidiInChannelNotes`: path 1, MIDI IN's note-list notes through each part as the previous block routed them; path 0, each part that received on the channel |
| 8 | `NoteRouting_QueueMidiOutSchemeChange` (5) | old bit 5, 0xFF, old channel | `NoteChange_ReleaseOldMidiOutScheme`: source 0's notes, per part (0) or on the old channel (1) |

**Two MIDI IN paths.** `MidiInA_ProcessRing` and `MidiInB_ProcessRing` handle a note frame in one of two ways.
`NoteRouting_MidiFlags` bits 6-7 (the MIDI IN mode) and `NoteRouting_SingleChannel` choose which:
- The **note-list path** is the one `Ring601850`'s notes take. It runs `NoteList_ApplyFrame`, then
  `NoteFrame_SelectForPart` by voice mask and range, then `NoteRouting_ForPartFromMidiIn`. Mode 2 sends every
  channel this way. Mode 1 sends only the channel `NoteRouting_SingleChannel`.
- The **per-channel path** handles the other channels. Every part whose +0x22 is the frame's channel and whose
  record has bit 6 gets the frame. Its outputs come from `NoteRouting_ForReceivingPart`: the tone generator and
  the record buffer, never MIDI OUT.

**Channel keys.** A part note node keeps the source and a channel key at +0 / +1:
- `NoteFrame_SelectForPart` writes the part's own number as the key, for the note-list path.
- The per-channel path keeps the MIDI channel.
- Timed events keep the track.

`PartNotes_BuildReleaseFrame` matches on (source, key), and source 0xFF matches any source. That is how
kinds 5 and 6 find a part's note-list notes and kinds 2 and 3 find a track's notes.

**Two MIDI OUT schemes.** `NoteRouting_MidiFlags` bit 5 chooses:
- Clear: each part sends on its own +0x22 channel while its record has bit 5.
- Set: per-part MIDI OUT is off. `Ring601850_ProcessNoteEvents` sends source 0's notes on `NoteRouting_SingleChannel`.

`NoteRouting_ForPartFromMidiIn` gives MIDI IN's note-list notes a MIDI OUT output only when `Variant_Flag` is 2,
bit 5 is clear and the mode is 1.

Not established:
- What `Ring601850` carries. Its producer has not been read.
- Whether a commit can queue more than 50 records. 0x602A02 + 50 x 4 = 0x602ACA, which is the default output
  record. `NoteRouting_QueueChange` flushes only above 0x7F records. `NoteRouting_QueueMidiInChanges` alone can
  queue 32 kind-7 records plus 32 kind-0 records.
- Who sets each `NoteRouting_ChangeFlags` bit. The immediate writes set bits 0, 1, 2, 3, 6, 7 and 15:
  0xFC5740 `orw 0x8004`, 0xFC5B80 `orw 0x0003`, 0xFC5ABC and 0xFC5BA3 `set`, 0xFC6343 `orw 0x00C0`. Six more
  `or` writes take their bits from BC.

## 8. The tone-generator senders, all-notes-off, and test notes (2026-10-04)

**Messages on the link.** `PartFrame_SendToToneGen` sends a part frame as 4-byte messages
`[status, part, data 1, data 2]` over `T_Link_SendBlockIn32ByteChunks`, built in `NoteSend_MsgBuffer`
(0x602000). The status bytes seen are:
- 0x90 for a note, with velocity 0 for a note-off;
- 0xB0 with 0x78 or 0x7B for all sound off / all notes off. These are the MIDI controller numbers.
- 0x88: `Drawbar_SendPartParams` sends it as a 6-byte block `[0x88, part, p, 0, value, 0]`.

On screen 0xDA (SINE WAVE CHECK) the part byte is `SoundSel_Group | 0xF0`. Status bit 3 is added when
(0x7F02) & 0xF0 is 0x10 and the frame came by the note-list path. What it selects on the link is not established.

**Poly and mono.** `PartToneGen_State` (0x6020D4) keeps one byte per part:
- 0x80: nothing sounds;
- 0xFF: poly notes were sent;
- otherwise: the note a mono part sounds.

A part whose tone-generator record (block +0x92) has bit 6, and whose state is not 0xFF, goes to
`PartFrame_SendMonoToToneGen`. That sender sounds only the note at the tail of the part's note list. A change of
note is a note-off plus a note-on in one block. When the list empties, the note-off is followed by CC 0x7B.
Every other part goes to `PartFrame_SendPolyToToneGen`. It sends each entry and follows with CC 0x7B when the
list has emptied. A part still in the poly state (0xFF) stays poly until it falls silent, even after bit 6 is
set.

**All-notes-off, per source.** Three directory slots release every sounding note of one source:

| slot | routine | releases | outputs |
|---|---|---|---|
| `T_PartNotes_ReleaseAllReceivedMidiIn` | `PartNotes_ReleaseAllReceivedMidiIn` | MIDI IN notes on the per-channel path, each channel 0..31 | tone generator, record |
| `T_NoteList_ReleaseAllSource0` | `NoteList_ReleaseAllSource0` | source 0's note list, through the parts | all three |
| `T_PartNotes_ReleaseAllTrackNotes` | `PartNotes_ReleaseAllTrackNotes` | each track's notes on its part | tone generator, MIDI OUT |

A fourth slot (0xF413CC) calls a bare ret.
- The first has six call sites: `MidiFilePlay_Stop`, `MainTask_PhaseVector`,
  `Transport_StopAllRunning_SaveRegs2`, `LcdKeyRow1_SoundEditMemoryWrite`, PartNotes_ReleaseReceivedOnScreenChange and Notes_ReleaseAllSources.
- The second has three: `Transport_StopAllRunning_SaveRegs2`, `LcdKeyRow1_SoundEditMemoryWrite` and
  Notes_ReleaseAllSources.
- The third has eleven. Seven are in prom_b, five of them in 0xF44C37..0xF4AF51. The others are
  `MainTask_PhaseVector`, `MainTask_PanelTimersTick`, Notes_ReleaseAllSources and a SaveRegs wrapper.

**Re-sounding after a parameter change.** `PartNotes_ResoundOnToneGen` (`T_PartNotes_ResoundOnToneGen`)
collects a part's notes without releasing them (`PartNotes_CollectFrame`). If any of them sounds on the tone
generator, it:
1. sends CC 0x7B;
2. sets bits 6-7 of each tone-generator velocity;
3. resets the part's state;
4. sends the notes again.

Its only caller is the DRAWBAR screen's `Drawbar_SendPartParams`. That routine first sends CC 0x78, then seven
values from 0x2890. What velocity bits 6-7 mean on the link is not established.

**Test notes.** SINE WAVE CHECK (`SineWaveCheck_ServiceSwitches`) plays notes 0x3C..0x3F while one of four
switches is held. Each note goes both to the tone generator, through `ToneGen_SendSoundSelNote` (part byte
`SoundSel_Group | 0xF0`), and to MIDI OUT channel 0, through `MidiOut_SendNote`. `MidiOut_SendNote` writes the
3-byte message to the port A ring for channels 0-15 and to the port B ring for 16-31.

## 9. Where the routing block's settings come from (2026-10-04)

The block is filled from the instrument's parameter records. A parameter change posts a 4-byte event: class =
the record id, then byte index, new value, changed-bit mask (notes/sysex-probes/README.md, the GM-mode
section). Pass B of the event lists (`UiEventClass_ListTable_B`) calls these handlers. The parameter names
are the Technics Reference Guide's (`notes/sysex-probes/param_names.json`, matched on record, offset and mask):

| class | record byte | parameter | goes to | handler |
|---|---|---|---|---|
| 0x00-0x1F (part) | 0 | PROGRAM CHANGE & BANK | the part's three record pointers reset to 0x602ACA | `NoteRouting_OnPartMidiEvent` |
| | 13 bits 0-4 | BASIC CHANNEL | +0x22 + part | |
| | 13 bit 5 | LOCAL CONTROL | tone-generator record bit 5 = NOT the bit | |
| | 13 bit 6 | MIDI OUT SETTING | MIDI record bit 5 = NOT the bit | |
| | 13 bit 7 | MIDI IN SETTING | MIDI record bit 6 = NOT the bit | |
| 0x20-0x3F (part, 2nd record) | 5 | VELOCITY OFFSET | tone-generator record +1 = value - 0x18 | `NoteRouting_OnPartPlayParamEvent` |
| | 6 | ASSIGN MODE | tone-generator record bit 6 = (value == 1): mono | |
| | 7 / 8 | KEY LAYER LOW / HIGH | range record +2 / +1 (parts 0-7 only) | |
| | 9 / 10 | VELOCITY LAYER LOW / HIGH | range record +4 / +3 (parts 0-7 only) | |
| | 23 | MIDI OUT KEY TRANSPOSE | MIDI record +1 = value - 0x40 | |
| 0x80 (MIDI system) | 3 low nibble | MIDI INPUT MODE 0 / 1 / 2 | `NoteRouting_MidiFlags` bits 6-7 | `NoteRouting_SetMidiInOutModes` |
| | 3 high nibble | MIDI OUTPUT MODE 0 / 1 | `NoteRouting_MidiFlags` bit 5 | |
| | 4 bits 0-4 | SINGLE CHANNEL | `NoteRouting_SingleChannel` (+0x292) | `NoteRouting_SetSingleChannelAndLocal` |
| | 4 bit 5 | LOCAL TOTAL | `NoteRouting_Mode` bit 9: no tone-generator output | |
| | 9 bit 7 | (no descriptor) | `NoteRouting_ChangeFlags` bit 3 | `NoteRouting_OnMidiSystemByte9` |
| 0x98 | 0 high nibble | PLAY MODE REQUEST | `NoteRouting_Mode` bit 4 | `NoteRouting_OnPlayModeRequest` |
| 0xA8 | 0x10 bits 0 / 1 | (no descriptor) | `NoteRouting_MidiFlags` bit 4 / 3 = NOT the bit: MIDI OUT port A / B allowed | `NoteRouting_SetMidiOutPorts` |

The part classes are indexed as `Bytes_00_to_1F_x3_FC65C6[0x40 + class]`.

So the "MIDI IN mode" and the two "MIDI OUT schemes" of section 7 are the guide's MIDI INPUT MODE and MIDI OUTPUT
MODE, and the "list channel" is SINGLE CHANNEL. Four settings store OFF as 1 and the handler stores the inverse:
LOCAL CONTROL, MIDI OUT SETTING, MIDI IN SETTING, and LOCAL TOTAL, which sets a "no output" bit. That reading
follows the code. The guide's value table has not been checked against it.

The range record that `NoteFrame_SelectForPart` tests is +1 key high, +2 key low, +3 velocity high and
+4 velocity low.

**When the block is rebuilt.** Each handler sets `NoteRouting_ChangeFlags` bit 15. Most also set a bit that
selects a differ (section 7). `NoteRouting_RebuildIfPending` (`T_NoteRouting_RebuildIfPending`, in
`UiEventPassB_TailList`) runs after the pass-B lists. When bit 15 is set, it runs the per-mode builder, then
`NoteRouting_UpdateActivePartMask` and `NoteRouting_CommitChanges`.

**Start-up.** `NoteRouting_PhaseVector` is entry 21 of `ModuleInitDirectory_F82641`. Its phase 0 runs:
1. `NoteRouting_InitRam`: fills 0x784 bytes from 0x602200 with 0xFF and zeroes 0x4C20..0x4C22.
2. `NoteRouting_InitDefaults`: every part plays its own tone-generator part, with transmit and receive on and
   all pointers at 0x602ACA. Both MIDI OUT ports are allowed, every mode is 0 and the single channel is 0.

**Tracks.** `NoteRouting_BuildTrackRouting` fills +0x42 / +0x52 for the 16 tracks from `BStore_TrackToPart`
and the track MIDI channels at 0x603433. It sets `NoteRouting_Mode` bit 8 (playback) from (0x133A) | (0x60341E)
and bit 7 (recording) from (0x1336) | (0x3000). Not established: what those four RAM words hold, beyond
being track masks.
