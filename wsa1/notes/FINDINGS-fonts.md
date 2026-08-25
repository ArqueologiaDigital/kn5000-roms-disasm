# The WSA1 has ten character generators, and five of them are ASCII

**Established 2026-08-24 while converting prom_a `0xF8F039-0xF8F3A3`.**
Every one of them lives in **prom_b**; their bases run from `0xF1B400` to
`0xF25590`.

★ **Six of the ten are in bank `0xF2`**, and that corrects a parenthesis in
`notes/FINDINGS-prom_b-thunk-table.md`: "No target in bank `0xF2` — that bank is
display-list data". No *thunk* targets it, which is true and is all that census
measured, but the bank is not all display-list data — `0xF203B0`, `0xF212B0`,
`0xF21940`, `0xF22840`, `0xF24640`, `0xF24DC0` and `0xF25590` are character
generators, reached as data by an immediate load in prom_a and so invisible to a
thunk census.

## How they were found

Ten of the thirty-four live `SWI7` services are the same routine with different
constants. Stripped of the LCD busy-polling, each one is:

```
    if BC == 0: return
    LCD_SelectCurrentLayer            ; (0x2555) := the current layer's base
    IX += (0x2555)                    ; the caller's offset -> a display address
    IZ  = HL * BC                     ; the offset of the first character code
    repeat BC times:
        A    = (XIY + IZ)             ; the character code
        XIY' = <font base> + A * <bytes per glyph>
        blit <bytes per glyph> bytes at IX
        XIY++ ;  IX++                 ; next code, next byte-column
```

Only the **font base**, the **bytes per glyph** and **which blitter** vary. That
is what makes them a family and what fixes the argument convention:

| register | meaning |
|---|---|
| `IX` | byte offset of the top-left corner **within the current layer** |
| `BC` | number of characters |
| `HL` | a stride added to the source pointer as `HL*BC` once, before the loop |
| `XIY` | the string |

## The inventory

| svc | prom_a | font base | bytes | w x h | blitter | ASCII test |
|---|---|---|---:|---|---|---|
| `0x06` | `0xF8F039` | `0xF1B400` | 14 | 8 x 14 | `LCD_BlitGlyph8` | **passes** |
| `0x20` | `0xF8F06E` | `0xF24DC0` | 10 | 8 x 10 | `LCD_BlitGlyph8` | **passes** |
| `0x16` | `0xF8F0A3` | `0xF212B0` | 14 | 8 x 14 | `LCD_BlitGlyph8` | fails |
| `0x07` | `0xF8F130` | `0xF1BEF0` | 16 | 8 x 16 | `LCD_BlitGlyph8_ExtraWait` | **passes** |
| `0x08` | `0xF8F1C3` | `0xF1CB70` | 32 | 16 x 16 | `LCD_BlitGlyph16` | **passes** |
| `0x21` | `0xF8F1F7` | `0xF25590` | 48 | 16 x 24 | `LCD_BlitGlyph16` | **passes** |
| `0x1A` | `0xF8F229` | `0xF22840` | 32 | 16 x 16 | `LCD_BlitGlyph16` | fails |
| `0x1F` | `0xF8F25B` | `0xF24640` | 32 | 16 x 16 | `LCD_BlitGlyph16` | fails |
| `0x19` | `0xF8F28D` | `0xF21940` | 32 | 16 x 16 | `LCD_BlitGlyph16` | fails |
| `0x1D` | `0xF8F2BF` | `0xF203B0` | 32 | 16 x 16 | `LCD_BlitGlyph16` | fails |

## Where the width comes from — it is read, not guessed

There are two blitters, and each one *is* a storage layout:

* **`LCD_BlitGlyph8`** (prom_a `0xF8F0D8`) sets CSRDIR **DOWN**, issues one CSRW
  at `IX`, one MWRITE, and then writes the glyph's bytes consecutively —
  `inc 1,IZ`. With the cursor advancing downward, consecutive bytes are
  consecutive rows of one 8-pixel column. **8 wide, one byte per row.**
* **`LCD_BlitGlyph16`** (prom_a `0xF8F2F1`) writes the **even** bytes down one
  column (`inc 2,IZ` from 0), then `inc 1,IX`, a fresh CSRW, and the **odd**
  bytes down the next. **16 wide, two bytes per row, row-major, left byte
  first.**

Render the 16-wide tables that way and the glyphs are legible; render them any
other way and they are noise. That is the check.

## The test, and how to re-run it

`python3 notes/render_font.py <base> <bytes> [--width 16] --ascii-check` asks one
question of a table: is code `0x20` blank and is every code `0x21-0x7E` drawn?
A real ASCII font answers yes to both — the space is the only blank printable
character.

```
python3 notes/render_font.py 0xF1B400 14 --ascii-check
python3 notes/render_font.py 0xF1CB70 32 --width 16 --ascii-check
python3 notes/render_font.py 0xF25590 48 --width 16 --art 0x41   # draws an A
```

The five that pass have exactly **one blank glyph and 94 drawn ones**. So the
machine carries ASCII in **8x10, 8x14, 8x16, 16x16 and 16x24**.

Codes were checked at both ends of the range and in the middle, by eye against
the rendered art, not only by the blank/non-blank count:

| font | code | renders as |
|---|---|---|
| `0xF1B400` 8x14 | `0x41`, `0x42` | `A`, `B` |
| `0xF24DC0` 8x10 | `0x41`, `0x5A` | `A`, `Z` |
| `0xF1CB70` 16x16 | `0x41`, `0x39` | `A`, `9` |
| `0xF25590` 16x24 | `0x41` | `A` |

⚠ One caveat on the top of the range: code `0x7E` in the 16x24 font is a
**right-pointing arrow**, not a tilde. `--ascii-check` counts it as drawn, which
it is, and substituting arrows for the less-used punctuation is normal in an
embedded font — but "ASCII" here means "indexed by ASCII codes with the letters
and digits in the right places", not "glyph-for-glyph the ASCII repertoire".

## ⚠ The five that fail are NOT named here

They are indexed by something other than ASCII:

| base | drawn of 95 | note |
|---|---:|---|
| `0xF212B0` | 56 | everything from code `0x59` up is blank; the defined range is `0x21-0x58` |
| `0xF22840` | 95 | code `0x20` is **not** blank; code `0x41` is a single horizontal bar |
| `0xF21940` | 71 | code `0x20` is not blank |
| `0xF203B0` | 71 | |
| `0xF24640` | 63 | code `0x41` is blank |

Their glyphs are stroke figures that *look* Japanese — `0xF22840`'s code `0x41`
is one horizontal bar, which is the shape of 一 — but **nothing in this firmware
says what encoding indexes them**, and no half-width-katakana or JIS range lines
up with `0x21-0x58`. They are called "glyph sets", not "kana" or "kanji", in the
source and they should stay that way until something reads the other end.

## One oddity worth recording

`LCD_BlitGlyph8_ExtraWait` (`0xF8F162`) is `LCD_BlitGlyph8` with **one extra
nine-byte BUSY poll** inserted before the CSRDIR command, and nothing else. That
is byte-checked rather than eyeballed:

* the first six bytes of each are equal;
* bytes 6..14 of the longer one are exactly `f0 c6 c8 6e 04 b3 ce 6e fc`, the
  poll sequence used ~30 times across the driver;
* bytes 6.. of the shorter equal bytes 15.. of the longer, all **82** of them;
* 88 bytes versus 97.

Only service `0x07` calls it. Whether that extra wait is a fix for a real
timing problem or an accident of the build is **not established**.

## The numbers here are re-checked by a script

`python3 notes/prom_a_byte_checks.py` re-reads every row of the inventory out
of the ROM -- each service's font-base immediate, each SWI7 slot's target, the
88/97-byte blitter comparison, and the ASCII verdict for all ten tables -- and
exits non-zero if any of it has drifted. It is the complement of the byte gate,
which cannot see a wrong number in a comment.

## What this does not say

* Nothing here traces a CALLER of any text service, so the `HL` stride's meaning
  is still open — it is multiplied by `BC` once and never used again.
* Nothing here says which font the UI actually uses for what.
* The fonts are in prom_b, so their bytes belong to that image's lane; this note
  only records what prom_a's code proves about them.
