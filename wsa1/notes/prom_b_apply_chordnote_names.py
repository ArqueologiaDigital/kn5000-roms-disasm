#!/usr/bin/env python3
"""Two more prom_b names, both from a table the routine indexes.

  0xF6E463 -> MsgLine_NoteName
      Sets (0x0EF5) = 1, clears the line tail, writes a space at 0x0FE8, then
      copies FOUR bytes of entry `(0x125A) & 15` of Text_GAbABbBCDbDEbEFF
      (0xF6E4B2) to 0x0FE9 -- `<G >`, `<Ab>`, `<A >`, `<Bb>`, `<B >`, `<C >`,
      `<Db>`, `<D >`, `<Eb>`, `<E >`, `<F >`, `<F#>`, twelve entries and four
      blanks -- and calls the painter through slot 0xF431B4.  It is a MsgLine
      routine; the reason prom_b_msgline.py's writer table does not show a copy
      for it is that it moves the four bytes with two `ld (XIX),WA` stores
      rather than an `ldir`.

  0xF6DAA6 -> Format_ChordName
      Copies TWO bytes of entry `(0x0E6C) & 15` of the 2-wide table at 0xF6DB19
      to (XIX) -- the chord ROOT, `  `, `C `, `C#`, `D `, ... `B ` -- and then
      FIVE bytes of entry `(0x0E6D) & 31` of the 5-wide table at 0xF6DB39 to
      (XIX+2) -- the chord TYPE, `7    `, `Maj7 `, `aug  `, `min  `, `min7 `,
      `dim  `, `m7b5 `, `mM7  `, `7sus4`, `6    `, `aug7 `, ... .  XIX is the
      caller's, so this is a FORMATTER, not a MsgLine routine, and it is named
      the way prom_a's Format_HexByte is.

RUN
    python3 notes/prom_b_apply_chordnote_names.py
    python3 notes/prom_b_apply_chordnote_names.py --apply
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B = 0xF00000
RENAMES = [("sub_F6E463", "MsgLine_NoteName"), ("sub_F6DAA6", "Format_ChordName")]

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)

NOTES = {
    "sub_F6E463": """; Name:    MsgLine_NoteName -- named 2026-08-31 for the table it indexes.
; Evidence (TABLE): `ld L,(0x125a) / and L,0x0f / sla 0x02,HL /
;          ld XIY,0x00f6e4b2 / ld WA,(XIY+HL)` and two `ld (XIX),WA` stores put
;          FOUR bytes of entry (0x125A) & 15 of Text_GAbABbBCDbDEbEFF at
;          0x00000FE9, inside the 30-character on-screen text line at 0x0FE4
;          (notes/FINDINGS-prom_b-message-line.md), after writing a space at
;          0x0FE8; it then calls the painter through slot 0xF431B4.  That table
;          is `<G >`, `<Ab>`, `<A >`, `<Bb>`, `<B >`, `<C >`, `<Db>`, `<D >`,
;          `<Eb>`, `<E >`, `<F >`, `<F#>` and four blanks.  It claims (0x0EF5)
;          = 1 like the rest of the family.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; Unknown: what (0x125A) is a note OF -- transpose, key, root, split point.
;          The name claims the twelve names it draws and nothing else.
""",
    "sub_F6DAA6": """; Name:    Format_ChordName -- named 2026-08-31 for the two tables it indexes,
;          in the style of prom_a's Format_HexByte.
; Evidence (TABLE): two copies into the caller's XIX --
;            (XIX+0)  two bytes of entry (0x0E6C) & 15 of the 2-wide table at
;                     0xF6DB19, the chord ROOT: `  `, `C `, `C#`, `D `, `Eb`,
;                     `E `, `F `, `F#`, `G `, `Ab`, `A `, `Bb`, `B `
;                     (the accidentals are the panel font's own glyphs, not
;                     ASCII);
;            (XIX+2)  five bytes of entry (0x0E6D) & 31 of the 5-wide table at
;                     0xF6DB39, the chord TYPE: `7    `, `Maj7 `, `aug  `,
;                     `min  `, `min7 `, `dim  `, `m7b5 `, `mM7  `, `7sus4`,
;                     `6    `, `aug7 `, `b5   `, `7b5  `, `79   `, `7b9  `,
;                     `M79  `, `69   `, `m6   `, ... .
;          XIX is the caller's, so this formats INTO a buffer it is given; the
;          neighbouring sub_F6DAED pads (XIX+7) with two spaces.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; Unknown: which chord (0x0E6C)/(0x0E6D) hold -- the one being played, the one
;          the accompaniment recognised, or one being edited.
""",
}


def txt(rom, a, n):
    return "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in rom[a - B:a - B + n])


def check():
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as f:
        rom = f.read()
    rows = [
        ("0xF6E4B2 notes, 4-wide", [txt(rom, 0xF6E4B2 + 4 * i, 4) for i in range(12)],
         ["<G >", "<Ab>", "<A >", "<Bb>", "<B >", "<C >", "<Db>", "<D >", "<Eb>", "<E >", "<F >", "<F#>"]),
        ("0xF6DB39 chord types, 5-wide", [txt(rom, 0xF6DB39 + 5 * i, 5) for i in (2, 3, 4, 5, 6, 7)],
         ["7    ", "Maj7 ", "aug  ", "min  ", "min7 ", "dim  "]),
    ]
    ok = True
    for what, got, want in rows:
        good = got == want
        ok &= good
        print(("  ok   " if good else "  FAIL ") + what + "  " + " ".join(repr(x) for x in got[:6]))
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def apply():
    with open(SRC) as f:
        s = f.read()
    SEP = re.compile(r"^; -{10,}\n", re.M)
    for old, new in RENAMES:
        i = s.index("\n" + old + ":") + 1
        st = [m.start() for m in SEP.finditer(s, 0, i)]
        h = st[-2] if len(st) >= 2 else st[-1]
        blk = s[h:i]
        assert OLD_UNKNOWN in blk, old
        blk = blk.replace(OLD_UNKNOWN, NOTES[old]).replace(f"; {old}\n", f"; {new} -- 0x{old[4:]}\n", 1)
        s = s[:h] + blk + s[i:]
        s = re.sub(r"\b" + old + r"\b", new, s)
    with open(SRC, "w") as f:
        f.write(s)
    print(f"renamed {len(RENAMES)}")
    return 0


if __name__ == "__main__":
    sys.exit(apply() if "--apply" in sys.argv else check())
