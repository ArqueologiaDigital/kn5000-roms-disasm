# prom_a: the MIDI-in message being routed, and five small cells whose headers already say what they are (2026-10-03)

Every row rests on an existing prom_a header (quoted) and was re-counted with:

    python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x1940 0x1941 0x1942 0x1943 0x1974 0x1975 0x1976 0x1977 0x197e 0x60f018 0x20c8 0x20ca 0x20cc 0x20ce 0x259a 0x259f 0x0932 --sites

Hits on `.short` lines are display-list data that happens to equal the address, and stay numbers.

## 1. The staged MIDI-in message and its routing (`MidiIn_*`)

`MidiIn_FetchMessage_PortA` / `_PortB` copy one message out of the port's ring to 0x1940. Their
header: "(0x1940) status, (0x1941..) the data bytes, and (0x1943) = 0x00, the PORT TAG". Port B
writes 0x10 there instead.

`MidiIn_RouteChannelMessage` then runs the message once per listening part. Its header:
"(0x197E) = channel | port tag, (0x1974/0x1975/0x1977) the list cursor and count, (0x1976) the
current part index". The cursor is incremented at 0xFA620B, and (0x1977) is decremented at 0xFA623B
until it reaches zero.

| address | name | holds | uses |
|---|---|---|---|
| 0x1940 | `MidiIn_MsgStatus` | the status byte; `and 0x0F` = channel, `and 0x70` = the status class | 5 |
| 0x1941 | `MidiIn_MsgData1` | the first data byte: the controller number for a CC, the program for a program change, the LSB of a song position | 6 |
| 0x1942 | `MidiIn_MsgData2` | the second data byte: the controller value for a CC | 29 |
| 0x1943 | `MidiIn_MsgPortTag` | 0x00 for port A, 0x10 for port B, ORed into the channel to index the 32-entry route map | 28 |
| 0x1974 | `MidiIn_RouteCursor` | offset into the part list at 0x1820, incremented per part | 3 |
| 0x1975 | `MidiIn_RouteCount` | the list's part count, as read from 0x1820[offset]; written once, and no reader found | 1 (+4 `.short`) |
| 0x1976 | `MidiIn_CurrentPart` | the part the message is being applied to. Every `MidiIn_CC*_ParamTable` is indexed by it; 0xFF / >= 0x1F are tested as "no part" | 41 |
| 0x1977 | `MidiIn_RouteRemaining` | parts left in the list, decremented to zero | 9 |
| 0x197E | `MidiIn_ChannelTag` | channel \| port tag of the message (0..0x1F) | 29 |

(0x197D) is left a number. It is set to 0xFF per message, and the handlers store
`MidiIn_ChannelTag` into it and compare it 14 times. What that guard means was not pinned down.

## 2. Five more cells

| address | name | holds | from the header of |
|---|---|---|---|
| 0x60F018 | `IndexedTable_Base` | the 32-bit base of the pointer table that prom_b's `IndexedTable_GetPtr` / `IndexedTable_GetByte` index; the part records are entries 0x20+part | FINDINGS-prom_b-thunk-table.md; the PanelAction_BankRemap header (`(0x60F018)+0x80+4*(0x2250)`) |
| 0x20C8 | `EditValue_Max` | the ceiling (signed 16-bit) | EditValue_ApplyStep |
| 0x20CA | `EditValue_Min` | the floor | EditValue_ApplyStep |
| 0x20CC | `EditValue_Value` | the value a step is applied to | EditValue_ApplyStep |
| 0x20CE | `EditValue_Step` | the step, written by `EditStep_Lookup` | EditValue_ApplyStep, EditStep_Lookup |
| 0x259A | `LCD_TextCharsLeft` | characters left to draw (`decw 1`, `cp 0`) | the packed-text banner above LCD_Svc_17_DrawText8x8Packed; LCD_Svc_17 / LCD_Svc_1C |
| 0x259F | `LCD_TextGlyphPtr` | 32-bit pointer to the current glyph's bitmap; `TextShift_LoadGlyph8/16` read it | the same banner; TextShift_LoadGlyph8/16 |
| 0x0932 | `MIDI_RX_OverflowCount` | "an 8-bit counter, bumped on every input-queue overflow"; nothing reads it | the MIDI_RX banner above MIDI_RX_DataByte |

The packed-text neighbours 0x259C `LCD_TextColumnAddr` and 0x259E `LCD_TextBitOffset` were already
named.

## 3. The rest of the MIDI_RX banner's RAM list

The banner above `MIDI_RX_DataByte` lists the RAM the interrupt parser owns. It saves seven
registers between interrupts: "(0x0900)-(0x091B) the seven saved 32-bit registers, in the order XWA
XBC XDE XHL XIX XIY XIZ. Cleared by MIDI_Parser_ClearContext". It also lists "(0x216F) bit 0 set
on every byte actually delivered -- a MIDI-activity flag".

| address | name | uses |
|---|---|---|
| 0x0900 / 0x0904 / 0x0908 / 0x090C / 0x0910 / 0x0914 / 0x0918 | `MIDI_Parser_SavedXWA` / `_SavedXBC` / `_SavedXDE` / `_SavedXHL` / `_SavedXIX` / `_SavedXIY` / `_SavedXIZ` | 3 each: `MIDI_Parser_LoadContext`, `_SaveContext`, `_ClearContext` |
| 0x216F | `MIDI_ActivityFlags` | 4 `set 0` (MIDI_RX_DeliverTwo, MIDI_RX_SecondDataByte, MIDI_RX_SysExData, MIDI_Fg_SysExData) and 1 `bit 0` (PanelLed_RequestIfBlinkEnableChanged) |

The census also lists `.short 0x0900`-style hits in prom_a's `KeyValueList_*` tables. Those
are table values, not these cells.
