# The WSA1 has twelve character generators, and it is a Japanese machine

**Established 2026-08-24, substantially corrected and extended 2026-08-25.**
Every glyph table lives in **prom_b**; their bases run from `0xF1B400` to
`0xF25590`. Every number below is re-derived from the ROM by
`python3 notes/font_layout_check.py`, which exits non-zero if any of it drifts.

---

## ⚠ Two corrections to the first version of this note

The first version was headed *"The WSA1 has ten character generators, and five
of them are ASCII"*. Both halves were artefacts of the window it looked
through, and both are now wrong:

1. **There are twelve tables, not ten.** The census that found ten looked only
   at the ten *byte-aligned* text services. The two **proportional** services,
   SWI7 `0x17` and `0x1C`, carry two more faces — `0xF1E470` (8 bytes/glyph)
   and `0xF1EAB0` (32) — and load their bases into `XIX` about `0x50` bytes
   into the routine, past the fixed `0x40`-byte window the census searched.
   Those two services were converted later and their fonts recorded in
   `prom_a/wsa1_prom_a.s`; this note had not caught up.

2. **The "ASCII test" tested the middle third of a code page.** It asked only
   about codes `0x20-0x7E`. Every one of the twelve tables also defines codes
   *below* `0x20`, and the Latin ones define a large block *above* `0x7E`. Five
   tables "failed" that test. None of them was broken; the test was pointed at
   the wrong range. **All five are now identified** — §4.

⚠ **The old figure survives in another lane's note.**
`notes/FINDINGS-prom_b-thunk-table.md` still says "six of the ten character
generators". The count is twelve; six of them are still in bank `0xF2`, so only
the word "ten" is wrong. Left for whoever owns that file — prom_b is another
lane and its notes are being edited concurrently.

A third, smaller correction: the note said the tables were "indexed by
something other than ASCII" and left it there. They are indexed by a **private
encoding**, and that is still true and still unresolved — but it is a different
statement from "unknown what they are".

---

## 1. ★ The table lengths are arithmetic, not inspection

This is the single strongest fact in this note and it required no pixel to be
looked at.

The twelve tables are laid **end to end in prom_b with no padding between
them**. For all eleven that have a successor, `next_base - base` is an exact
multiple of that table's own glyph pitch — and the quotient is the cell count.

| base | pitch | geometry | cells | script |
|---|---:|---|---:|---|
| `0xF1B400` | 14 | 8 x 14 | **200** | Latin |
| `0xF1BEF0` | 16 | 8 x 16 | **200** | Latin |
| `0xF1CB70` | 32 | 16 x 16 | **200** | Latin |
| `0xF1E470` | 8 | 8 x 8, proportional | **200** | Latin |
| `0xF1EAB0` | 32 | 11 x 16, proportional | **200** | Latin |
| `0xF203B0` | 32 | 16 x 16 | **120** | **hiragana** |
| `0xF212B0` | 14 | 8 x 14 | **120** | **half-width katakana** |
| `0xF21940` | 32 | 16 x 16 | **120** | **katakana** |
| `0xF22840` | 32 | 16 x 16 | **240** | **kanji, set A** |
| `0xF24640` | 32 | 16 x 16 | **60** | **kanji, set B** |
| `0xF24DC0` | 10 | 8 x 10 | **200** | Latin |
| `0xF25590` | 48 | 16 x 24 | — | Latin |

Six Latin faces come out at **exactly 200 cells each** despite using five
different pitches (8, 10, 14, 16, 32 bytes per glyph). The three kana faces
come out at **exactly 120**. That two independent groupings each land on a
round number, from eleven independent divisions, is what makes the method
trustworthy: a mistaken pitch or a mistaken base would produce a fraction.

`0xF25590` is last and has no successor, so **its cell count is not
established**. Its glyph data occupies `0x21-0x7F` and is followed by zeros and
then 1200 bytes of `0x0E` filler at `0xF27750-0xF27C00`. ⚠ An earlier draft of
this section read that filler as glyph data and reported the table running to
code `0x1FF`. It does not; `0x0E` is simply non-zero.

Reproduce the whole table with `python3 notes/font_sheet.py --extent`, and the
abutment arithmetic with `python3 notes/font_layout_check.py -v`.

---

## 2. The code page, and why codes below `0x20` matter

`0x10-0x1F` are **not control codes here**. Four of the six Latin faces
(`0xF1B400`, `0xF1BEF0`, `0xF1CB70`, `0xF1EAB0`) define **all sixteen**; the
8x8 proportional face defines **twelve** of them, missing exactly `0x1B-0x1E`;
the 8x10 face defines **none**.

Rendered, they are **music notation and UI symbols**:

```
python3 notes/font_sheet.py 0xF1B400 14 --range 0x10-0x1f
```

`0x10` `0x11` `0x12` are solid triangles pointing right, left and down; `0x14`
through `0x18` are a note stem with a hollow head, a filled head, then one, two
and three flags — the note-value ladder; `0x1C`-`0x1E` are beamed pairs. ⚠ Those
are read off the rendering by eye. What the script checks is the structural
claim only: which faces define all sixteen, and that `0x20` (the space) is blank
in every face that does.

### ★ Above `0x7E`: accented ASCII, proved by byte identity

The upper block is not read off the pixels. **An accented lower-case glyph is
the plain ASCII letter's bitmap, byte for byte unchanged in rows 2..13, with
the accent drawn in rows 0 and 1** — which the plain letter leaves blank.

```
plain 'e'  0x65 :  00 00 3e 7f 63 7f 7f 60 7e 3e 00 00 00 00
acute 'e'  0xA0 :  04 08 3e 7f 63 7f 7f 60 7e 3e 00 00 00 00
plain 'u'  0x75 :  00 00 63 63 63 63 63 63 7f 3f 00 00 00 00
grave 'u'  0xA3 :  10 08 63 63 63 63 63 63 7f 3f 00 00 00 00
```

Seventeen codes of `0xF1B400` match a plain letter this way, and
`notes/font_layout_check.py` asserts all seventeen:

| code | mark | letter | | code | mark | letter |
|---|---|---|---|---|---|---|
| `0x9C` | circumflex | o | | `0xA5` | circumflex | u |
| `0x9D` | grave | a | | `0xA6` | circumflex | i |
| `0x9E` | circumflex | a | | `0xB4` | acute | a |
| `0x9F` | grave | e | | `0xB5` | acute | o |
| `0xA0` | acute | e | | `0xB6` | acute | u |
| `0xA1` | diaeresis | e | | `0xB7` | tilde | n |
| `0xA2` | circumflex | e | | `0xB8` | acute | i |
| `0xA3` | grave | u | | `0xB9` | grave | o |
| `0xA4` | diaeresis | u | | | | |

Exactly **five distinct accent marks** are used across them, and two of them are
mirror images of each other: acute is `04 08`, grave is `10 08`.

★ **The 'i' is the check worth having.** Every plain letter in that list leaves
rows 0..1 blank so the accent has somewhere to go — *except* `i`, whose dot is
in exactly those two rows (`0c 0c`). An accented i has no dot, and the accent
takes the dot's place. That is a prediction the typography makes before any
byte is read, and the bytes keep it.

⚠ **The capitals do not match, and should not.** `0xB1` `0xB2` `0xB3` are
Á, É, Ñ, but a capital fills rows 2..11, so there is no room above it: those
three are the capital **redrawn one row shorter**, not the plain capital
shifted. The script asserts that too — no vertical shift of the plain letter
reproduces them.

The remaining defined codes in `0x80`-`0xC7` are capitals with diaeresis
(`0x80`-`0x82` = Ä Ö Ü), cedilla forms, ligatures and a few shading patterns
(`0x87`, `0x94`/`0x95`). ⚠ Those are eyeballed, not byte-proved.

Nineteen of the sixty defined codes above `0x7F` are pinned by byte identity;
the rest are not. Either way the block is a **Western-European extension**,
which is what a 200-cell page with 95 ASCII codes in the middle of it is for.

---

## 3. Where the width comes from — it is read, not guessed

Unchanged from the first version, and still the reason any of the renderings
are legible. There are two byte-aligned blitters, and each one *is* a storage
layout:

* **`LCD_BlitGlyph8`** (prom_a `0xF8F0D8`) sets CSRDIR **DOWN**, issues one CSRW
  at `IX`, one MWRITE, then writes the glyph's bytes consecutively (`inc 1,IZ`).
  With the cursor advancing downward, consecutive bytes are consecutive rows of
  one 8-pixel column. **8 wide, one byte per row.**
* **`LCD_BlitGlyph16`** (prom_a `0xF8F2F1`) writes the **even** bytes down one
  column (`inc 2,IZ` from 0), then `inc 1,IX`, a fresh CSRW, and the **odd**
  bytes down the next. **16 wide, two bytes per row, row-major, left byte
  first.**

Render the 16-wide tables that way and the glyphs are legible; render them any
other way and they are noise. That is the check.

The two proportional services shift glyphs into a staging buffer instead, and
their widths come out of the code as well: service `0x17` advances **6 pixels**
per character (`add (0x259e),0x06` at `0xF901F5`) and service `0x1C` advances
**11** (`0xF90367`), with `TextShift_LoadGlyph16`'s `and W,0xe0` keeping exactly
three bits of each row's second byte — 8 + 3 = 11.

---

## 4. ★ The five that "failed" — all five identified

### 4.1 `0xF212B0` — half-width katakana, 8 x 14 (service `0x16`)

120 cells, two blocks defined:

| codes | count | content |
|---|---:|---|
| `0x0F`-`0x16` | 8 | marks and punctuation |
| `0x21`-`0x58` | 56 | the kana |

The 56 decompose as **46 gojūon + 9 small kana + 1 prolonged sound mark**, in
Japanese dictionary order starting at `0x21`:

```
0x21 ア  0x22 イ  0x23 ウ  0x24 エ  0x25 オ  0x26 カ ... 0x4C ワ  0x4D ヲ  0x4E ン
0x4F-0x57  the nine small kana        0x58  ー
```

★ **The test that matters is the last cell, not the first.** Code `0x58` is
`00 00 00 00 00 7f 00 00 00 00 00 00 00 00` — one horizontal bar and nothing
else. That is the prolonged sound mark, and it is exactly what the gojūon
reading predicts at the **end** of the range. Checked by
`notes/font_layout_check.py`.

The mark block is what a half-width face needs and a full-width one does not:
`0x0F` is two ticks and `0x10` a small ring at the **top** of the cell — the
voiced and semi-voiced sound marks, carried as **separate characters** because
there is no room to compose them into an 8-pixel cell. `0x11` is that same ring
at the **bottom** (the full stop) and `0x12` a tick there (the comma); `0x13`
and `0x14` are the two corner brackets; `0x16` is the middle dot. ⚠ `0x15`
(`30 49 06`) is **not identified**.

### 4.2 `0xF203B0` hiragana and `0xF21940` katakana, 16 x 16 (services `0x1D`, `0x19`)

Both are 120-cell tables in the **same code space and the same order**:

| codes | count | content |
|---|---:|---|
| `0x10`-`0x3D` | 46 | the gojūon, あ/ア through ん/ン |
| `0x3E`-`0x46` | 9 | the small kana |
| `0x47` | 1 | ー, the prolonged sound mark |
| `0x48`-`0x5B` | 20 | the voiced (dakuten) forms |
| `0x5C`-`0x60` | 5 | the semi-voiced (handakuten) forms |
| `0x61`-`0x65` | 5 | 。 、 「 」 〜 |
| `0x66` | 1 | a small filled diamond — **katakana only** |

46 + 9 + 1 + 20 + 5 + 5 = **86**, which is exactly the number of defined cells
in the hiragana face; the katakana face has **87**, the extra being `0x66`,
which the hiragana face leaves blank.

★ **The cross-check, and it is a good one.** `notes/font_layout_check.py`
compares the two faces bitmap by bitmap, knowing nothing about kana, and finds
**exactly six codes** where they hold identical bytes: `0x47` and
`0x61`-`0x65`. Those are precisely the six rows in the table above that belong
to **neither script** — the prolonged sound mark and the punctuation. Every
other code both faces define differs. Two completely independent routes — count
the Japanese repertoire, or diff the bitmaps — arrive at the same six codes.

```
python3 notes/font_sheet.py 0xF203B0 32 --width 16 --range 0x10-0x17   # あいうえおかきく
python3 notes/font_sheet.py 0xF21940 32 --width 16 --range 0x10-0x17   # アイウエオカキク
```

### 4.3 `0xF22840` and `0xF24640` — two kanji sets, 16 x 16 (services `0x1A`, `0x1F`)

| base | cells | defined | codes |
|---|---:|---:|---|
| `0xF22840` | 240 | **224** | `0x10`-`0xEF`, contiguous, **no blank cell anywhere** |
| `0xF24640` | 60 | **43** | `0x10`-`0x3A`, contiguous |

The glyphs are multi-stroke CJK ideographs — `0xF22840` code `0x12` is a
triangular roof over a bar over a box (合); `0xF24640` code `0x33` is a box
inside a box (回). ⚠ That identification is **visual**, from the rendering, not
from anything the firmware says. It is corroborated structurally rather than
left bare: the same firmware carries a hiragana face and a katakana face at
these same 16x16 metrics (§4.2), so the two remaining 16x16 faces are the
ideographs those two scripts need.

The two sets are **disjoint** — 0 shared glyph bitmaps out of 43 and 224 — and
neither shares a bitmap with any 16x16 kana face. That is now
`notes/font_layout_check.py`'s output rather than a sentence: it re-reads both
sets, checks 224 and 43 non-blank cells, checks that all 224 and all 43 bitmaps
are **distinct within their own set** (without which "0 shared" would also be
true of a set full of duplicates), and checks the intersection with each other
and with the two 16x16 kana faces. ⚠ Added 2026-08-25 after the round-1 audit
(F14) pointed out that the figure was true but reproduced by nothing. ⚠ **Why the firmware keeps
two separate kanji sets rather than one is not established.** "Set A" and
"Set B" are this disassembly's labels, not names the firmware uses.

---

## 5. ⚠ The encoding is private, and that is a finding, not a gap

None of the five Japanese tables is indexed by a standard encoding.

* The half-width katakana face has JIS X 0201's **repertoire** but not its
  **code points**: JIS puts ｦ and the nine small kana *before* the gojūon, at
  `0xA6`-`0xAF`; this face puts ヲ *inside* the gojūon at `0x4D` and the small
  kana *after* it, at `0x4F`-`0x57`.
* 224 and 43 contiguous kanji codes from `0x10` match nothing in JIS X 0208
  (two bytes) or Shift-JIS.
* The kanji sets are **subsets** — the ideographs this product's UI happens to
  need, numbered in whatever order they were collected.

So a code in these tables is meaningful only against a mapping that prom_a does
not contain. ⚠ **Anything that wants to read WSA1 Japanese strings needs that
mapping, and it has not been found.**

---

## 6. ★ Nothing calls the Japanese services

`python3 notes/swi7_call_sites.py` censuses the three bytes `21 nn ff` —
`ldb a,nn` then `swi 7`, which is exactly how prom_a issues its own service call
at `0xF83076`.

| | services with a literal call site |
|---|---|
| the seven **Latin** text services | **6 of 7** (`0x06` 18 sites, `0x20` 21, `0x17` 5, `0x08` 4, `0x07` 3, `0x21` 3; only `0x1C` has none) |
| the five **Japanese** text services | **0 of 5** |

★ The census **calibrates its own noise**: 30 of the 64 SWI7 slots are dead
(they point at a bare RET), and the pattern lands on a dead slot **7 times** out
of 188. That is the false-positive floor, measured on the same data rather than
assumed — and the Latin/Japanese asymmetry is far outside it.

⚠ **What this does NOT prove.** It is a byte-pattern census, not a
disassembly: it cannot show a hit is on an instruction boundary, and it is
**blind to any call whose service number came from a variable**. Two readings
survive it, and this note picks neither:

* the script is **selected at run time** from a language setting, so the service
  number is computed and no literal exists; or
* the Japanese faces are **not used by this firmware revision at all**, and the
  data ships unreferenced.

Deciding between them needs prom_b's UI code, which is another lane's territory
and 13.8% converted.

---

## 7. One oddity worth keeping

`LCD_BlitGlyph8_ExtraWait` (`0xF8F162`) is `LCD_BlitGlyph8` with **one extra
nine-byte BUSY poll** inserted before the CSRDIR command, and nothing else.
Byte-checked rather than eyeballed, by `notes/prom_a_byte_checks.py`:

* the first six bytes of each are equal;
* bytes 6..14 of the longer one are exactly `f0 c6 c8 6e 04 b3 ce 6e fc`, the
  poll sequence used ~30 times across the driver;
* bytes 6.. of the shorter equal bytes 15.. of the longer, all **82** of them;
* 88 bytes versus 97.

Only service `0x07` calls it. Whether that extra wait fixes a real timing
problem or is an accident of the build is **not established**.

---

## 8. What is still open

* **The encoding tables.** §5. The single most valuable thing to find next.
* **Any caller at all.** §6. Until one exists, the `HL` argument of the text
  services still has no established meaning — it is multiplied by `BC` once into
  `IZ` and never used again.
* `0xF25590`'s cell count (§1) and the 1200-byte `0x0E` run after it.
* Code `0x15` of the half-width katakana face (§4.1), and code `0x66` of the
  katakana face (§4.2).
* The fonts are in prom_b, so their bytes belong to that image's lane; this note
  records only what prom_a's code proves about them.

## The scripts

| script | what it answers |
|---|---|
| `notes/font_layout_check.py` | re-derives every number above; exits non-zero on drift |
| `notes/font_sheet.py` | contact sheet of a code range; `--extent` for real table extents |
| `notes/render_font.py` | one glyph, large |
| `notes/swi7_call_sites.py` | who calls which service, with a measured noise floor |
| `notes/prom_a_byte_checks.py` | the blitter comparison and the service/font wiring |
