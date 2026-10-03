# WSA1 routines with a KN5000 twin, and why the KN5000's names are not copied

2026-10-04. Instrument: `notes/kn5000_twin_routines.py`, which reuses
`kernel_structural_match.py`'s decoder (MAME unidasm on the ROM bytes, every `0x…` literal
masked), cuts each routine at its first `ret`, and scores LCS / the longer length against
every KN5000 symbol not shaped like an address: 46,497 candidates in main v10 and the sub-CPU
payload.

```
python3 notes/kn5000_twin_routines.py --min 0.7            # unnamed WSA1 routines
python3 notes/kn5000_twin_routines.py --min 0.9 --named    # the control
```

## What it measured (run of 2026-10-04, after commit a23b2dd5)

| query set | queries (>= 12 instructions) | pairs >= 0.70 | pairs >= 0.90 |
|---|---:|---:|---:|
| still-unnamed WSA1 `sub_` | 1,866 | 230 | 107 |
| named WSA1 routines (control) | 2,424 | — | 123 |

**The kernel is not the only shared code.** Twins cluster in KN5000's `SMF_*` writer, its
`SeMenu_*` (the sound-edit menu: WSA1's SOUND EDIT paints), `Scoop_*` / `Display_*` title-bar
code, the MIDI CC receivers and the control-panel packet handlers (`SC1_TxOp0_TwoByte` =
`CPanel_LED_HandlePacket2`, 35 of 35). Many are identical at score 1.000.

## The control says the names cannot be transplanted

Of the 123 named pairs at >= 0.90, **79 share at least one word of three or more letters**
(`--named`'s last line), and 44 share none. That is an upper bound on agreement; two wrong
names can also share a word. Examples where identical code has different names in the two
trees:

* WSA1 `BStore_AppendBytes` = KN5000 `VoiceSlot_AssignToChannel`, 79 of 79 instructions.
* WSA1 `SoundEditToneLayerVelocityLayer_Paint` (named from the text it draws) = KN5000
  `SeMenu_FxEdit_DataBlock1`: KN5000 calls code a "DataBlock".
* WSA1 `SeqBuf_PutByte` = KN5000 `TempoRingBuf_DequeueOne`: put vs. dequeue.

So a twin shows that two routines are one routine. It does not show that either tree's name
is right. The SMF writer pass (`notes/prom_b_smf_writer_names.py`) used twins this way. The
twin confirmed that the four WSA1 copies are the KN5000's SMF module. Every role was then
read from the WSA1 body, and the KN5000 name was rejected where the body contradicts it.
Example: the routine that writes the sorted due note-offs is KN5000's `SMF_UpdateTempo`.

## What this opens, and what is not done

* The reverse direction: a WSA1 name backed by evidence, on a routine whose KN5000 twin has
  a guessed name (`*_Helper`, `*_DataBlock*`, `*_Sub`), is a candidate correction to the
  KN5000 tree. None is made here. KN5000 names reach its documentation site and notes, and
  each would need its own reading.
* The 107 unnamed WSA1 routines at >= 0.90 that are not in the SMF writer. Their twins'
  names are leads, not evidence.
