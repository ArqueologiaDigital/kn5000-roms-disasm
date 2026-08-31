# The panel event-code map, replicated from prom_a's side — and applied to
# prom_a's own screen-control tables

**2026-08-31.** Reproduce with

```
python3 notes/prom_a_panel_control_map.py --checks    # the corroborations
python3 notes/prom_a_panel_control_map.py --map       # code -> control
python3 notes/prom_a_panel_control_map.py --variant   # the coverage argument
python3 notes/prom_a_naming_wave8_apply.py --plan     # the 81 edits it justifies
```

## ⚠ First: what was already known, and by whom

This lane composed the code→control map, wrote it up as new, and only then
grepped the tree. It was not new. The record, so the lap is not run a third
time:

| round | file | what it established |
|---|---|---|
| 9 | `notes/wave7_panel_button_codes.py` | **layer 1** — the wire numbering, `SW = 8*segment + bit + 1`, and the manual's legend per SWnn, graded |
| 10 | `notes/wave7_panel_event_index.py` | the **layer-2 machinery** — the wire→group map and the per-group event lists |
| 11 | `notes/wave7_panel_names_round11.py --variant` | **which variant this machine is**, settled three independent ways |
| 12 | `notes/prom_b_panel_names_round12.py` | `SLOT_CONTROL`, and **131 labels already applied in prom_b** — `SoftKeyColN`, `LcdKeyRowN`, `ExitKey` — for exactly these codes |

Everything below is either a **replication** of that, or the **application of it
to prom_a**, which is the part that had not been done.

## 1. The replication, and why the agreement is the result

The route taken here is prom_a-side and different in kind. Compose

```
segment  --PanelWireGroupMap_Variant2 (0xF8A189)-->  group
group    --PanelGroupEventLists_Variant2 (0xF8B4B2)-->  [class, code, shift, mask]*
(segment, bit)  --SW = 8*seg + bit + 1-->  the manual's legend  (imported from round 9)
```

and read the **pair position** out of the shift byte:
`PanelEvent_ShiftThenRunAction` (`0xF8A8A1`) takes bit 4 as a direction and bits
0-2 as a count and normalises a single-bit mask onto bit 0 or bit 1 of a two-bit
field. So "which of the two keys" is computed from the ROM, not read off the
panel.

`--checks` then asserts the outcome **matches round 12's `SLOT_CONTROL` on all
16 shared codes**. That check is looking for a *disagreement*: two maps built by
different routes that disagree would mean one is wrong and every name resting on
it is unsafe. They do not disagree.

★ **And there is a consumer-side check that knew nothing of the derivation.**
In each of the four sibling tables of §3, slot `0x0F`'s handler is the *same*
five-instruction shape: test bit 7 of the forwarded argument and, if it is
**clear**, write the screen-request pair `(0x2070)`/`(0x2071)` — leave for
another screen, which is what an EXIT key does. Better: bit 7 of the delivered
code is *set* at pair position 0, and code `0x0F` exists at position **1 only**,
so the guard admits exactly the one position a wire on this panel can produce.
Four handlers, one shape, and the shape agrees with the map's pair arithmetic.

| code | control | pair position | in round 12? |
|---|---|---|---|
| 0x00-0x07 | SOFT KEY columns 1..8 | 0 = lower, 1 = upper | yes |
| 0x08-0x0C | the five LCD-row key pairs | 0 = CP2 (left) column, 1 = CP1 (right) | yes |
| 0x0D | the **-1 / +1** pair | 0 = -1, 1 = +1 | as `MinusPlusKey`, with round 12's caveat |
| 0x0E | nothing on this panel raises it | | yes (its "no producer" gap) |
| 0x0F | EXIT | 1 | yes |
| 0x10 | PAGE v / PAGE ^ | 0 = v, 1 = ^ | yes |
| 0x1B | NUMBER PAD, whole field | — | yes (as its remapped slot 0x12) |
| **0x1E** | **COMPARE** | 1 | **no** |
| **0x20** | **mode/menu select** — PLAY & EDIT MODE ×2, MENU PART/SYSTEM/MIDI/DISK | | **no** (but `PanelEvent_Code20_SetScreen` was already named for it) |

Outside class 0xA9 and so never indexing a per-screen table: `A8/07` the four
BANK buttons (bits 4-6 as one three-way field, RE-MAP on bit 7), `A8/05`
REALTIME CREATOR, `B8/00` RESET.

## 2. The variant — round 11's answer, re-derived by one of its three arguments

`cp (0xC4),0x01 / jr z` at `0xF8A851` takes variant 1 when `(0xC4) == 1`;
`Variant_SetFromPB0` (`0xF82882`) makes `(0xC4)` **1 when PORT B bit 0 reads
HIGH and 2 when it reads LOW**. Round 11 settles that **variant 2 is the
SX-WSA1R**, three ways: diode coverage, the three power-on service chords, and
the number-pad value tables (only variant 2's, at `0xF8AE57`, makes segment-1
bit *b* the key printed *b*).

`--variant` re-derives the first of those from scratch, segment by segment:

| seg | fitted bits | variant 1 covers | variant 2 covers |
|---|---|---|---|
| 2 | 0-6 (SW24 has no diode) | **0-7** | **0-6** |
| 6 | none | **0-7** | **none** |
| 7 | 0-3 (SW57-60) | **0-7** | **0-3** |
| 8 | 0-1 (SW65-66) | **0-6** | **0-1** |
| 9 | 0-4 (SW73-77) | **0-7** | **0-4** |
| 10 | none | **0-7** | **none** |

Variant 2 agrees on all twelve segments; variant 1 contradicts the manual on
six. **So on the rack, PORT B bit 0 reads LOW** — which is a hardware fact a
driver can act on, and is now recorded next to `Variant_SetFromPB0`, whose own
header had said "Unknown: which physical variant is 1 and which is 2" for
eleven rounds.

## 3. ★ What is new: prom_a's 0xFF3800 module

Fourteen dispatch-table headers in `prom_a/wsa1_prom_a.s` ended
**"⚠ Not one entry is tied to a legend"** — two rounds after prom_b's tables had
been named. Check C9 is the prediction that closed it:

> `Dispatch_FF3800`, `_FF3880`, `_FF3900` and `_FF3980` have live entries **only
> at indices 0x08-0x0C and 0x0F**.

Under this map that reads "this screen answers the five LCD-row keys and EXIT",
which is what a WSA1 menu screen looks like. Under any other assignment of the
code space it is a coincidence four sibling tables share.

### ★★ And each table's SCREEN, from the screen object

`PanelScreen_VtableTable` (prom_a `0xF86EC1`) holds 256 three-method screen
objects — **+0 Enter, +4 Leave, +8 Button** — and that listing's own header
establishes the three offsets from three different call sites. So:

> **the screen whose BUTTON method is a reader is the screen that reader
> serves, and the same object's ENTER method is what paints it.**

The mapping comes out **one to one** — ten readers, ten screen ids, no reader
named by two screens — which is asserted rather than assumed, because a
many-to-one mapping would mean a table could not carry a screen name at all.
Seven screens are then named by an *existing* label: their Enter method already
carries a `Paint_*` name an earlier round derived from the screen's own text.

| table | screen id | screen | how |
|---|---|---|---|
| `Dispatch_FF3800` | 0x60 | **DiskMenu** | Enter draws "DISK" / "MIDI FILE LOAD" / "LOAD", choosing on the model strap at 0xFF42EE — the site this module's banner already calls the disk menu |
| `Dispatch_FF3880` | 0x65 | **MidiFileDirectPlay** | Enter **is** `Paint_MidiFileDirectPlay` |
| `Dispatch_FF3900` | 0x67 | **DiskL0adFile** | Enter **is** `Paint_DiskL0adFile` |
| `Dispatch_FF3980` | 0x69 | **MidiFileL0ad** | Enter **is** `Paint_MidiFileL0ad` |
| `Dispatch_FF3A29` | 0x6C | **DiskSaveFile** | Enter is `PageDispatch_DiskSaveFile`, four of whose six pages are `Paint_DiskSaveFile` |
| `Dispatch_FF3D39` | 0x6E | **MidiFileSave** | its pages draw the lists at 0xF58A21 "MIDI FILE SAVE : FILE NAMING" and 0xF59222 "MIDI FILE SAVE : FILE SELECTI0N" |
| `Dispatch_FF3F39` | 0x70 | **FloppyDiskFormatSelectType** | Enter **is** `Paint_FloppyDiskFormatSelectType` |
| `Dispatch_FF3FB9` | 0x71 | **FloppyDiskFormatAreYouSure** | Enter **is** `Paint_FloppyDiskFormatAreYouSure` |
| `Dispatch_FF4049` | 0x74 | **L0adSingleS0und** | its page 0 draws the list at 0xF58C53, "LOAD SINGLE SOUND" |
| `Dispatch_FF4151` | 0x73 | **L0adSingleC0mbination** | its page 1 draws the list at 0xF58F55, "LOAD SINGLE COMBINATION" |

### The batch

`notes/prom_a_naming_wave8_apply.py` derives all of it at run time and refuses
anything ambiguous:

* **14 readers** — `PanelButtonDispatch_<Screen>` for the ten that index with
  the control code, `PageDispatch_<Screen>` for the four that index with the
  page byte `(0x2229)` alone and take no argument. Giving one of *those* a
  PanelButton name is the mistake the distinction exists to prevent.
* **6 renames + 59 new labels** — the handlers, in round 12's exact form
  `<Control>_<Screen>`: `LcdKeyRow1_DiskMenu`, `ExitKey_MidiFileL0ad`,
  `SoftKeyCol3_MidiFileSave_Page1`, …
* Fifty-nine of the sixty-five handler addresses **had no label at all**: the
  ROM's own table points at them and nothing in the listing named them.

**Refused, and this is the point:** a target reached at two *different* control
indices (32 of the module's 97 live targets are, always as `c` and `c+0x11` —
round 11's variant-1 `add (XIX-1),0x11` rewrite), a target outside prom_a (eight
are prom_b directory slots), and any address that is not the start of a listing
line.

## 3b. The same screen object names two more methods per screen

A screen object has three slots and the module above uses one of them. The other
two answer for **every** screen whose `+0` already carries a `Paint_*` label —
sixteen of the 175 live objects:

* `+4` **Leave** — called by `PanelScreen_CallLeave_A/B` with the id that has
  just *stopped* being current (`ld BC,0x0004`);
* `+8` **Button** — called by `PanelButton_Route` (`0xF8621E`) with the current
  id and a button index.

The offsets are established by three *different* call sites, checked as V1-V6
in `PanelScreen_VtableTable`'s own header, so `ScreenLeave_PanelCpuCheck` and
`ScreenButton_MidiTotalMode` are claims about a call convention and not about a
layout. **27 more names**, refusing any address two live objects share, and
refusing any address the reader batch already claimed — six screens' Button
method *is* a control-table reader, and `PanelButtonDispatch_X` says everything
`ScreenButton_X` says and more.

Thirteen of the 27 are a bare `ret`: that screen does nothing on leave, and the
header says so rather than implying a routine.

## 4. ★ A refusal from round 7, resolved

Round 7 refused to name `sub_FF4ACB` and `sub_FF4D5D`:

> *"NOT NAMED because it and sub_FF4D5D draw the SAME caption set (FROM S0NG
> NUMBER, TO S0NG NUMBER, 1-10) and nothing in their own lists tells the two
> apart."*

Nothing in their lists does. The **dispatch slot** does: they are
`Dispatch_FF3900` entries **[11]** and **[12]** — LCD row 4 and LCD row 5 of one
screen. They are now `LcdKeyRow4_FF3900` and `LcdKeyRow5_FF3900`, and round 7's
block is left below the new one verbatim, refusal included, as the record of how
the gap closed.

## 5. One thing offered as an observation, not an answer

`ScreenDispatch_FE8077`'s header says *"Unknown: what the index in HL selects"*.
Its shape is exactly what this map predicts of a screen — `[00]-[07]` all one
target, `[08]-[0C]` five distinct, `[0D]/[0E]` one, `[0F]` its own, `[10]-[1F]`
all one. **That is not enough.** Its reader is published as prom_b thunk slot
`T_F402B4` and nothing in either image names that slot, so no caller establishes
what HL holds. A shape that fits is a coincidence until a caller says otherwise;
the handlers there are left `sub_XXXXXX` and the note says why.

## 6. What is still not claimed

* A code names a **control**, not a **function**. What each handler does, and
  which screen each table serves, are open.
* Which *side* of a pair a particular handler sees. The pair position reaches it
  as an argument the reader forwards (`(XIZ+0x0A)`); this pass did not trace a
  caller that fixes that argument's bit layout.
* Variant 1's panel is not identified. The keyboard SX-WSA1 is the obvious
  candidate and no SX-WSA1 material exists in these trees.
