# The message module, the service-mode screens, and the call shape that hid them

**Round 9, 2026-08-25.** prom_b `0xF2BE35-0xF317FF` — 22,987 bytes, the image's
third-largest `.incbin` — is converted, and so is the `0xF0C800-0xF0D060` screen
module the same discovery turned up. **20,839 bytes substantive** in total, plus
4,496 of `0x0E` `ret` padding. prom_b's `.incbin` total went
184,794 → 159,459 and its substantive coverage 57.1% → 61.1%.

Everything below is re-derived from the ROM by two committed scripts:

    python3 notes/prom_b_message_module.py            # the layout, object by object
    python3 notes/prom_b_message_module.py --selftest # 76 checks, 0 failures
    python3 notes/gen_prom_b_message_module.py        # the assembly in the .s
    python3 notes/prom_b_dl_call_shapes.py            # the census below
    python3 notes/prom_b_dl_call_shapes.py --selftest # 13 checks, 0 failures
    python3 notes/prom_b_anchored_tiler.py 0xF0C800 0xF0D061   # §6
    python3 notes/prom_b_anchored_tiler.py --selftest # 10 checks, 0 failures
    python3 notes/gen_prom_b_anchored_module.py 0xF0C800 0xF0D061

The build gate (`python3 scripts/analysis/assert_byte_identical.py`) passed after
each of the two splices.

---

## 1. ★★ Why 22,987 bytes survived eight rounds: THE SCANNER ONLY KNOWS ONE CALL SHAPE

`scripts/analysis/prom_b_display_lists.py` finds a display list only where the
caller spells both ends as immediates:

    SHAPE 1   ld XIY,imm32 / ld XIX,imm32 / call {0xF417F0, 0xF417F4}
              45 s0 s1 s2 00   44 e0 e1 e2 00   1d t0 t1 t2

That is 614 sites, and every list they name has been converted for rounds. It is
not the only shape. Three more exist, and between them they name **6,879 bytes
that are still `.incbin` today** plus the 22,987 this round closed:

| shape | bytes | what it looks like |
|---|---|---|
| 2 | `lda XBC,<end> / push XBC / lda XWA,<start> / push XWA / call {0xF42E00, 0xF42E04}` — the **stack** entry points `DisplayList_Run_Stack` / `DisplayListB_Run_Stack` | `f2 e0 e1 e2 31  39  f2 s0 s1 s2 30  38  1d t0 t1 t2` |
| 3 | `lda XBC,<record> / push XBC / call 0xF42E0C` — `DisplayListB_RunOne_Stack`, **one** interpreter-B record, no end pointer at all | `f2 p0 p1 p2 31  39  1d 0c 2e f4` |
| 4 | a table of 8-byte `(start,end)` entries in prom_a, indexed by a **message id** and a **language** | data, not code — §2 |

Census, `python3 notes/prom_b_dl_call_shapes.py`:

```
shape 1:  614 sites,  609 usable,    795 bytes still `.incbin`
shape 2:  179 sites,  179 usable,   6361 bytes still `.incbin`
shape 3:   84 sites,   50 usable,    518 bytes still `.incbin`
```

⚠ It is a byte-level scan, so the framing walk is the filter: a shape-1 or
shape-2 site counts only if the walk from its start lands **exactly** on its end.
Shape 3 has no end to land on, so its records are checked against interpreter B's
implied length for their opcode instead; a record that disagrees is printed as
SUSPECT rather than counted, and none currently does. The 34 shape-3 sites the
summary does not count are the ones whose record is in **prom_a**
(`0xFA3398` upward), which this lane does not walk.

★ **For the prom_a lane:** 48 shape-2 sites name display lists in **prom_a**, from
`0xFA1F21` to `0xFA4D9A`. They are that lane's to convert and are listed by
`python3 notes/prom_b_dl_call_shapes.py --sites`.

---

## 2. The message module, `0xF2D800-0xF317FF`

### 2.1 The reader, and what indexes it

prom_a `0xF99098` (quoted, not edited — prom_a is another lane's file):

```
lda XIX,0x2880 / ld C,(XIX)              C = MESSAGE ID
cp C,0x40 / jrl NC,0xF9911C              ids >= 0x40 draw nothing
ld A,0x04 / mul WA,(0x7FC1)              (0x7FC1) = LANGUAGE
add XWA,0x00F993B9 / ld XWA,(XWA)        -> that language's pair table
mul C,0x08 / add XWA,XBC / ld XIY,(XWA)  + id*8   -> list START
inc 4,XBC / add XBC,(XIZ-8) / ld XWA,(XBC)        -> list END
push XWA / push XIY / call 0xF42E00      -> DisplayList_Run_Stack, interpreter A
```

So **RAM `0x2880` is the message id** and **RAM `0x7FC1` is the language**. The
table that reaches this range is prom_a `0xF99121`: 64 entries of 8 bytes,
`0xF99121-0xF99320`. Checked: all 64 name a list inside `0xF2D800-0xF317FF`, all
64 frame, and none is an empty `(X,X)` entry — every one of the 64 messages
exists. `0xF99121 + 64*8 = 0xF99321`, which is where the second reader's table
starts, so the entry count is fixed by the table's own end as well as by the
`cp C,0x40` bound.

A second reader at prom_a `0xF990F1` indexes `0xF99321` by `8*(0x7FC1)` with no
message id at all and calls `0xF42E04`, `DisplayListB_Run_Stack`. That is why two
of the 81 lists in this span are interpreter-B lists.

⚠ **NOT established:** how many languages this particular table set serves. The
language-table base `0xF993B9` holds three usable pointers before `0x0E` padding
begins at `0xF993C5`, and **all three are the same table**, `0xF99121` — while a
different, five-entry language object exists at prom_b `0xF0DB18` (four tables of
five `.long`s, feeding five "ATTENTION!" lists at `0xF0DB68`, `0xF0DC97`,
`0xF0DDDB`, `0xF0DF54`, `0xF0E0BA`). English, German and French text are all
present in this span. Reconciling "five languages at `0xF0DB18`" with "three
identical pointers at `0xF993B9`" is left open rather than guessed.

### 2.2 What tiles it

74 anchor intervals from the 75 framing pairs, plus the objects below, tile
`0xF2D800-0xF317FF` with **no hole and nothing unexplained**:

| object | evidence for its extent |
|---|---|
| 76 display lists, 776 records | the framing walk lands exactly on the end the table gives |
| string table `0xF2DE89`, 3 × 31 | width = the `+0x0B` word of the interpreter-B record at `0xF2DE6B`, whose `+7` long is `0xF2DE89`; last entry `"A Control Track already exists."` |
| string table `0xF2DEE6`, 3 × 18 | the same, from the record at `0xF2DE7A`; last entry `"Tracks to Control."` |
| RAM image `0xF30800-0xF3167F`, 3,712 B | prom_a's four `ld BC,n / ld XIY,src / ld XIX,dst / ldir` setups at `0xFC019B`, `0xFC01B1`, `0xFC01C7`, `0xFC01DD`; `0x10 + 0x650 + 0x650 + 0x1D0 = 0xE80` tiles the range exactly |
| 37 bytes of orphan text | see §2.4 |

**The RAM image is not display lists at all** — it is the SOUND RE-MAP, COMBI
RE-MAP and USER DRUM MAP defaults, copied to RAM `0x5200`, `0x5210`, `0x5860`
and `0x5EB0`. Its first 16 bytes are a directory of the other three
(`0x00000010`, `0x00000660`, `0x00000CB0` — the offsets), and the drum-map block
ends on a 128-byte `0x00..0x7F` identity run, checked byte by byte.

### 2.3 Interpreter attribution

Every record is checked against the implied length of its own handler, using
`notes/prom_b_dl_length_audit.py`'s tables. **79 of the span's 81 lists are interpreter A, 2 are
interpreter B, and none is ambiguous or fits neither.** The two B lists are
`0xF2DE6B` and `0xF2F857`, both `op 02, 15 bytes` — exactly handler `0xF31B21`'s
implied length, and 5 bytes longer than interpreter A's `op 02` allows.

### 2.4 ⚠ A READING, not a decode: the orphan text

Five short runs (`0xF2F2AF` `"rmat0 file"`, `0xF2F2CD` `"ile"`, `0xF2F2E4`
`"aten auf"`, `0xF31680` `"de la"`, and 11 spaces at `0xF2BE35`) are not the
start of any list. The reading is that they are the **tail of a record belonging
to an overlapping list** — several messages end in the same sentence, and
`"for direct play."` appears twice inside 40 bytes with fragments between. Only
one tiling can be written down. What is CERTAIN is only that no `(start,end)`
pair found anywhere names those bytes.

### 2.5 ⚠ The last record in the image is truncated

`0xF317DD` is `op 07` and declares `0x24` = 36 bytes, but only 35 lie inside the
ROM object: its text `"Impossible de modifier le set d"` stops mid-word and
`0xF31800` is the start of the converted interpreter block. The machine survives
it — the loop's `cp XIX,XIY / jr ULE` stops as soon as `XIY` passes the end
pointer — and this is the **second** record in the image known to over-declare,
after `0xF3B651` in
`notes/FINDINGS-ui-display-list-interpreter-b.md`. The `.s` emits the declared
length byte and only the 35 bytes that exist.

---

## 3. The service-mode screens, `0xF2C800-0xF2CB58`

Reached by shape 2 from prom_a `0xF9574E`, `0xF9577B`, `0xF95808`, `0xF9581D`,
`0xF959A3`, and by shape 3 from `0xF9585C`, `0xF95866`, `0xF95870`, `0xF9587A`.

★★ **This is the firmware's own self-diagnostic menu, and it answers part of what
gap O asks for.** `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap O says
*"The service manual's self-diagnostic section maps six wave-ROM tests onto six
buttons and the OCR loses the circled digits."* The firmware spells them out, and
there are **seven**, not six:

```
SINE WAVE CHECK / CHECK MODE
  (1) SINE WAVE & ROM CHECK
  (2) GENERATOR IC OUTSEL CHECK
  (3) HIGH SOUND CHECK
  (4) LOW SOUND CHECK
  (5) NORMAL SOUND WITH TOUCH CHECK
  (6) SINE WAVE & ROM CHECK 16dB DOWN
  (7) EXT BOARD WAVE CHECK
```

plus `GATE ARRAY CHECK` ("Please check with osciloscope / check point are P07."
— the ROM's spelling), `PANEL CPU CHECK` ("Please check the CPU port / LED
flash.") and `PANEL SW&LED CHECK` ("Please push a any button. / If LED near the
button turn / ON/OFF. It is working OK.").

⚠ **What this does NOT give is a (legend, bit) pair.** These are the screens the
tests draw; which button enters which test is in the code that pushes them, in
prom_a, and was not followed. Gap O is narrowed, not closed.

Three operand objects hang off these screens, and each has **two independent
witnesses to its entry count** — the record's AND mask and the extent:

| object | count from the mask | count from the extent |
|---|---|---|
| `0xF2C9CD`, 8-byte entries | `+4` mask `0x07` on the record at `0xF2C9C2` ⇒ 8 | `0xF2CA0D - 0xF2C9CD = 64 = 8 × 8` |
| `0xF2CA48`, 3-byte strings `"OFF" "ON " "ON " "ON "` | `+4` mask `0x03` on the record at `0xF2CA15` ⇒ 4 | `0xF2CA54 - 0xF2CA48 = 12 = 4 × 3` |
| `0xF2CAC3`, a bitmap | — | three A `op 03` records at `0xF2C981`/`0xF2C98D`/`0xF2C999` pass `BC = 5`, `HL = 30`; opcode 03 IS SWI7 service 3, `LCD_Svc_03_BlitColumns`, whose prom_a header reads *"BC = number of columns; HL = bytes down each column"*, and `5 × 30 = 150` = the extent |

The three blits place the same 5-column bitmap at `0x208F`, `0x2094` and
`0x2099` — five apart, i.e. side by side.

---

## 4. The screen-id field index, `0xF2D000-0xF2D5A1`

prom_a `0xF9940B`:

```
ld L,(0x207C) / xor H,H / sla 0x02,HL     screen id, x4
ld XIY,0x00F2D000 / ld XHL,(XIY+HL)       -> a list
cp (XHL),0xFF / jr Z,<out>                0xFF = this screen has none
...
ld BC,(XHL+IX) / cp BC,0xFFFF / jr Z,...  16-bit entries, 0xFFFF terminator
cp BC,WA                                  compared against a word from RAM 0x2C00
```

* `0xF2D000-0xF2D3FF` = **256 `.long`s**, indexed by the byte at RAM `0x207C`.
  256 because the index is a byte and nothing bounds it; the count is confirmed
  by where the table stops — every one of the 256 entries points into
  `0xF2D400-0xF2D5A1`, which is where the table's own data begins.
* `0xF2D400-0xF2D5A1` = the 127 distinct lists, each `0xFFFF`-terminated. **They
  tile the 418 bytes exactly, with no hole and no byte left over**, which is what
  fixes the range's end. The highest pointer, `0xF2D5A0`, is a list whose single
  word is the terminator.

⚠ **NOT established:** what a 16-bit entry IS. It is compared against a word read
from RAM `0x2C00`, and the walk stops on a match — the shape of "is this field on
this screen?" — but neither the RAM structure nor the meaning of the match is
decoded here.

---

## 6. The method, written down once — and a screen module it converts

`notes/prom_b_anchored_tiler.py` is §2 and §3 generalised: give it a module's two
ends and it produces the tiling, or refuses.

    ANCHORS   every (start,end) any of the three code shapes gives, plus the ends
    RECORDS   an anchor interval is a record run if the framing walk from its
              start lands EXACTLY on its end
    TABLES    a non-record interval is tiled by the objects records POINT AT.
              The width comes from the record — the `+0x0B` word for interpreter
              B's two string-table handlers, the fixed stride 8 or 6 for its two
              array handlers, `HL` for interpreter A's opcode 03/04 blit.  The
              COUNT comes from the EXTENT.

⚠⚠ **Two traps this tool exists to avoid, both of which caught a draft of it.**

1. **The AND mask is not a count.** A record's `+4` mask bounds the *index*.
   Masks of `0xFF` are everywhere in these modules and no array in them has 256
   entries. A solver that trusted the mask emitted a 1,536-byte "table" where the
   anchors say **304**.
2. **Without anchors the tiling is not unique.** `--count` on the unanchored
   4,004-byte module `0xF0C800-0xF0D79C` reports **25,692,504** tilings that all
   satisfy the record and table constraints. Anchors are not a convenience; they
   are the whole difference between a decode and a preference.

Calibration, which is what makes the tool trustworthy: run on the two modules
this round converted by hand, it reproduces both exactly — the `0xF2C800`
service block including the 5 × 30 bitmap, and `0xF0C800-0xF0D060` including all
twelve of its tables.

### 6.1 `0xF0C800-0xF0D060` — the MIDI / INPUT & OUTPUT screen module, 2,145 bytes

41 anchors, 49 objects, **0 untiled**: 37 lists (152 records) and 12 tables.
Bounded below by 203 bytes of `0x0E` padding at `0xF0C735-0xF0C7FF`, which is why
the module starts where it does.

Its tables are the value lists behind the MIDI screens, and their counts are the
extents:

| table | entries × width | what is in it |
|---|---|---|
| `0xF0CA9F` | 3 × 6 | `MULTI ` `SINGLE` … |
| `0xF0CAB1` | 2 × 6 | `OMNI  ` `MULTI ` |
| `0xF0CABD` | **32** × 6 | `1 - 1 ` … `2 - 16` — the 2 × 16 MIDI channel grid |
| `0xF0CB7D` | 2 × 3 | `ON ` `OFF` |
| `0xF0CB83` | 3 × 6 | `NORMAL` `TECH  ` `REMAP ` |
| `0xF0CB95` | 2 × 5 | `SOUND` `COMBI` |
| `0xF0CB9F` | 6 × 8 | four-word screen-position records |
| `0xF0CCC5` | 3 × 3 | `OFF` `ON ` `OFF` |
| `0xF0CCCE`, `0xF0CCDE` | 2 × 8 each | `INTERNAL` / `MIDI    `, and positions |
| `0xF0CE75` | 2 × 3 | `OFF` `ON ` |
| `0xF0CE7B` | 8 × 8 | eight four-word position records |

⚠ **One list is left ambiguous and is labelled so in the `.s`:** `0xF0D023`, a
single `op 00` record of 10 bytes. No call site names it, and 10 is the implied
length of opcode 0 under **both** interpreters, so nothing in the ROM decides it.
Its neighbours on both sides are site-named interpreter-B lists, which is a
reading, not a decode.

⚠ **`0xF0D061-0xF0D79B`, 1,851 bytes, is left as `.incbin`.** The tiler produces a
tiling for it, and that tiling is one of the 25,692,504.

---

## 5. What was left, and why

* **The bytes shapes 2 and 3 still name elsewhere.** `--new` lists them; the
  `0xF0C800` cluster is now converted, and what remains is mostly in
  `0xF13D34-0xF147AB`, `0xF17559-0xF1B3FF` and `0xF4F000-0xF54FFF`. Each needs
  the module's two ends established first — `0xF0C800`'s came from a 203-byte
  `0x0E` pad — because §6 shows that an unanchored tail cannot be tiled honestly.
* **`0xF0D061-0xF0D79B`**, §6.1.
* **The language question in §2.1.** Three pointers where five languages exist.
  Answering it means reading prom_a's language setting, which is that lane's file.
* **What indexes the 256-entry screen table (`0x207C`) and what RAM `0x2C00`
  holds.** Both are RAM, so both need the other images.
