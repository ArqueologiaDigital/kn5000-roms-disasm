#!/usr/bin/env python3
r"""Is there Japanese text in the WSA1R firmware?  Yes: two messages in prom_b's DL_F2E91A.

QUESTION THIS ANSWERS
    The font headers (Font_Svc1A_16x16 et al.) and wsa1/notes/FINDINGS-fonts.md
    say the firmware's Japanese faces are never shown any Japanese text:
    scripts/analysis/japanese_text_census.py "finds no Japanese kana anywhere".
    That census looks for RUNS of kana codes.  Interpreter-A display lists do
    not store runs: every record is `op, length, IX, characters`, and a record
    holds only the characters one `swi 7` service draws -- one script, one
    font -- so a Japanese sentence is cut into 1..9-character pieces with four
    header bytes between them.

    The display list at 0xF2E91A-0xF2E9E2 (28 records) is made of exactly
    such pieces: ops 0x19 (LCD_Svc_19, katakana, Font_Svc19_16x16), 0x1D
    (hiragana, Font_Svc1D_16x16), 0x1A (kanji set A, Font_Svc1A_16x16) and
    0x07 (Latin 8x16).  This probe walks it by its own length bytes, decodes
    each record with the kana layout of wsa1/notes/FINDINGS-fonts.md sec. 4.2
    and the kanji transcription wsa1/notes/fonts-kanji/kanji_transcription.txt,
    and puts the pieces in reading order by IX -- the text's display address,
    read as row * 40 + byte column (40 bytes per 320-pixel line).

    It checks:
      * the walk consumes 0xF2E91A-0xF2E9E2 exactly and splits into two
        14-record halves at 0xF2E97A, one message each;
      * the small-kana order: FINDINGS-fonts.md gives "0x3E-0x46 the small
        kana" without an order; the text needs 0x46 to be ッ (トラ?ク), and the
        katakana glyphs are checked structurally -- 0x46 has the three strokes
        of ッ, 0x3E the hooked top of ァ;
      * who runs the lists: prom_a's PtrTable_F99121 holds (start, end) pairs
        of prom_b display lists for T_DisplayListB_Run_Stack; 0xF2E91A occurs
        in it only as the END of DL_Error's pair (0xF2E910, 0xF2E91A), and
        0xF2E97A occurs in neither image at all -- so no start of either
        Japanese list is named anywhere (the shapes searched: the 24- and
        32-bit little-endian spellings of both addresses in prom_a and prom_b).

    It also counts the source's op-0x1C records: Font_Svc1C_16x16's header
    said nothing calls that service; display lists do.

RUN
    python3 notes/promb-2026-09-25/japanese_messages_probe.py            # checks
    python3 notes/promb-2026-09-25/japanese_messages_probe.py --apply    # headers, split, notes
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
KANJI = os.path.join(ROOT, "wsa1", "notes", "fonts-kanji", "kanji_transcription.txt")
LO, MID, HI = 0xF2E91A, 0xF2E97A, 0xF2E9E3
KATA_FONT = 0xF21940
FAIL = []

GOJUON_H = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
GOJUON_K = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
SMALL_H, SMALL_K = "ぁぃぅぇぉゃゅょっ", "ァィゥェォャュョッ"
VOICED_H = "がぎぐげござじずぜぞだぢづでどばびぶべぼ"
VOICED_K = "ガギグゲゴザジズゼゾダヂヅデドバビブベボ"
SEMI_H, SEMI_K = "ぱぴぷぺぽ", "パピプペポ"
PUNCT = "。、「」〜"


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def kana(c, kata):
    g, s, v, p = (GOJUON_K, SMALL_K, VOICED_K, SEMI_K) if kata else (GOJUON_H, SMALL_H, VOICED_H,
                                                                     SEMI_H)
    if 0x10 <= c <= 0x3D:
        return g[c - 0x10]
    if 0x3E <= c <= 0x46:
        return s[c - 0x3E]
    if c == 0x47:
        return "ー"
    if 0x48 <= c <= 0x5B:
        return v[c - 0x48]
    if 0x5C <= c <= 0x60:
        return p[c - 0x5C]
    if 0x61 <= c <= 0x65:
        return PUNCT[c - 0x61]
    return "[%02X]" % c


def kanji_table():
    t = {}
    for ln in open(KANJI, encoding="utf-8"):
        f = ln.split()
        if len(f) == 3 and f[0] in ("A", "B"):
            for i, ch in enumerate(f[2]):
                t[(f[0], int(f[1], 16) + i)] = ch
    return t


def decode(op, bs, kt):
    if op == 0x19:
        return "".join(kana(c, True) for c in bs)
    if op == 0x1D:
        return "".join(kana(c, False) for c in bs)
    if op in (0x1A, 0x1F):
        return "".join(kt.get(("A" if op == 0x1A else "B", c), "[%02X]" % c) for c in bs)
    return bs.decode("latin-1")


def walk(rom, lo, hi):
    a, recs = lo, []
    while a < hi:
        op, ln = rom[a - 0xF00000], rom[a - 0xF00000 + 1]
        ix = int.from_bytes(rom[a - 0xF00000 + 2:a - 0xF00000 + 4], "little")
        recs.append((a, op, ln, ix, rom[a - 0xF00000 + 4:a - 0xF00000 + ln]))
        a += ln
    return recs, a


def glyph(rom, code):
    g = rom[KATA_FONT - 0xF00000 + 32 * code:KATA_FONT - 0xF00000 + 32 * code + 32]
    return [((g[2 * r] << 8) | g[2 * r + 1]) for r in range(16)]


def main():
    b = open(ROMB, "rb").read()
    a = open(ROMA, "rb").read()
    kt = kanji_table()
    recs, end = walk(b, LO, HI)
    check("the length-byte walk from 0xF2E91A ends exactly at 0xF2E9E3 (%d records)" % len(recs),
          end == HI and len(recs) == 28)
    halves = [[r for r in recs if r[0] < MID], [r for r in recs if r[0] >= MID]]
    check("it splits at 0xF2E97A into two 14-record lists",
          len(halves[0]) == 14 and len(halves[1]) == 14 and halves[1][0][0] == MID)
    check("every record's op is 0x19/0x1D/0x1A (kana/kanji faces) or 0x07 (Latin 8x16)",
          all(r[1] in (0x19, 0x1D, 0x1A, 0x07) for r in recs))
    # small kana: ッ has three separate strokes; count connected "ink runs" per glyph row loosely
    g46, g3e = glyph(b, 0x46), glyph(b, 0x3E)
    check("katakana 0x46's top rows hold two short separate dots and a stroke (ッ), "
          "0x3E's a horizontal bar with a hook (ァ)",
          bin(g46[6]).count("1") >= 5 and g46[6] & 0x3000 and g46[6] & 0x00C0 and
          bin(g3e[6]).count("1") >= 7)
    msgs = []
    for h in halves:
        rows = {}
        for (ad, op, ln, ix, bs) in h:
            row, col = divmod(ix, 40)
            if op == 0x07:
                row -= 2            # an 8x16 Latin glyph sits 2 rows below the 16x16 line it joins
            rows.setdefault(row, []).append((col, decode(op, bs, kt).rstrip("\x0f")
                                             .replace("[0F]", "")))
        text = "".join("".join(t for _, t in sorted(rows[r])) for r in sorted(rows))
        msgs.append(text)
        for r in sorted(rows):
            print("     row %3d: %s" % (r, " | ".join("c%d %s" % (c, t) for c, t in sorted(rows[r]))))
        print("     => %s" % text)
    check("message 1 reads コードトラックがすでにあります。2つのトラックをコードトラックに指定できません。",
          msgs[0] == "コードトラックがすでにあります。2つのトラックをコードトラックに指定できません。")
    check("message 2 reads コントロールトラックがすでにあります。2つのトラックをコントロールトラックに"
          "指定できません。", msgs[1] ==
          "コントロールトラックがすでにあります。2つのトラックをコントロールトラックに指定できません。")
    # readers
    e = [int.from_bytes(a[0xF99121 - 0xF80000 + 4 * k:0xF99121 - 0xF80000 + 4 * k + 4], "little")
         for k in range(169)]
    as_end = [k for k in range(1, 169) if e[k] == LO and e[k - 1] == 0xF2E910]
    as_any = [k for k in range(169) if e[k] == LO]
    check("in prom_a's PtrTable_F99121, 0xF2E91A occurs %d times, every time as the END of the pair "
          "(0xF2E910, 0xF2E91A) = DL_Error" % len(as_any),
          as_any and all(k in as_end and k % 2 == 1 for k in as_any))
    nowhere = all(rom.find(MID.to_bytes(n, "little")) < 0 for rom in (a, b) for n in (3, 4))
    check("0xF2E97A is spelled nowhere in prom_a or prom_b (24- or 32-bit)", nowhere)
    # service 0x1C: how many interpreter-A records this source frames with op 0x1C
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    n1c = sum(1 for t in L if re.search(r'\bop 1C, \d+ bytes -> handler 0xF31A52', t)
              and re.match(r"^\s*\.byte\s+0x1[cC],", t))
    check("this source frames %d interpreter-A records with op 0x1C (DLHandler_2Words_Text, "
          "`ld A,(XIY)` (85 21) ... `swi 7` (ff) = service 0x1C)" % n1c, n1c >= 100 and
          b[0xF31A52 - 0xF00000:0xF31A54 - 0xF00000].hex() == "8521" and
          b[0xF31A73 - 0xF00000] == 0xFF)
    print("\nVERDICT:", "PASS" if not FAIL else "FAIL (%d)" % len(FAIL))
    if FAIL:
        return 1
    if "--apply" in sys.argv:
        apply(n1c)
    return 0


SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
HDR1 = """; ------------------------------------------------------------------
; 0xF2E91A-0xF2E9E2 -- 28 records, 201 bytes -- interpreter A
; ------------------------------------------------------------------
; DL_JpChordTrackAlreadyExists -- 0xF2E91A-0xF2E979, 14 interpreter-A
;   records: a message in JAPANESE, the only Japanese text found in the
;   firmware.  In reading order (IX = row*40 + byte column):
;     row  84  コードトラックがすでにあります。
;     row 110  2つのトラックをコードトラックに
;     row 136  指定できません。
;   "A chord track already exists.  Two tracks cannot be designated as the
;   chord track." -- the Japanese twin of DLTable_ARhythmTrackAlreadyExists
;   [1] "A Chord Track already exists." and the "Tracks to Chord." string
;   after it.  The next list, DL_JpControlTrackAlreadyExists, is the same
;   sentence for the CONTROL track.
; Records: op 0x19 = LCD_Svc_19 katakana (Font_Svc19_16x16), op 0x1D =
;   hiragana (Font_Svc1D_16x16), op 0x1A = kanji set A (Font_Svc1A_16x16: 指
;   0x8D, 定 0x44 in notes/fonts-kanji/kanji_transcription.txt), op 0x07 =
;   the 8x16 Latin "2" -- each a DLHandler_IX_Text record: op, length,
;   IX, characters.  A sentence is cut into one-script pieces of 1..9
;   characters, which is why a search for RUNS of kana finds nothing.
; Read by: no start is named anywhere.  prom_a's PtrTable_F99121 holds the
;   (start, end) pairs T_DisplayListB_Run_Stack is given, and 0xF2E91A occurs
;   in it only as the END of DL_Error's pair (0xF2E910, 0xF2E91A); 0xF2E97A
;   is spelled in neither image (24- or 32-bit).  So the two lists look like
;   a Japanese build's text left in place, not a screen this build draws --
;   an inference from the absence of a reader, stated as such.
; Evidence: python3 notes/promb-2026-09-25/japanese_messages_probe.py walks
;   the records by their own length bytes (ending exactly at 0xF2E9E3),
;   decodes them and checks both sentences and the reader search.
; ------------------------------------------------------------------"""
HDR2 = """; DL_JpControlTrackAlreadyExists -- 0xF2E97A-0xF2E9E2, 14 records, the
;   same message for the CONTROL track:
;     row  84  コントロールトラックがすでにあります。
;     row 110  2つのトラックをコントロールトラックに
;     row 136  指定できません。
;   (DLTable_ARhythmTrackAlreadyExists [2] "A Control Track already
;   exists.").  Its last record carries three 0x0F bytes after 。 that no
;   hiragana cell defines.  See DL_JpChordTrackAlreadyExists above."""
FONT_NOTES = {
    "Font_Svc1A_16x16": """; ⚠ CORRECTED 2026-09-25 (lane promb): "It is not in any of the four images"
;   is wrong for prom_b.  DL_JpChordTrackAlreadyExists and
;   DL_JpControlTrackAlreadyExists (0xF2E91A) are two Japanese messages that
;   use this face (指 0x8D, 定 0x44) with the kana faces; the census looks for
;   RUNS and a display list stores 1..9-character pieces between 4-byte
;   record headers.  Two kanji cannot be the text the ORDER came from, so
;   that question stands.  notes/promb-2026-09-25/japanese_messages_probe.py.
""",
    "Font_Svc19_16x16": """; Used by: DL_JpChordTrackAlreadyExists / DL_JpControlTrackAlreadyExists
;   (op 0x19 records), the one Japanese text in the firmware.  Its
;   トラック fixes 0x46 as small ッ, so the small-kana block 0x3E-0x46 reads
;   ァィゥェォャュョッ -- 0x3E's hooked bar (ァ) and 0x46's three strokes (ッ)
;   are checked by notes/promb-2026-09-25/japanese_messages_probe.py.
""",
    "Font_Svc1D_16x16": """; Used by: DL_JpChordTrackAlreadyExists / DL_JpControlTrackAlreadyExists
;   (op 0x1D records: がすでにあります。, つの, を, に, できません。).
""",
    "Font_Svc1C_16x16": """; ⚠ ANSWERED 2026-09-25 (lane promb): the service IS used, through display
;   lists rather than a literal `ld A,0x1C / swi 7`.  An interpreter-A record
;   with op 0x1C runs DLHandler_2Words_Text, which loads A = the op and does
;   `swi 7`; this file frames {n1c} such records -- the screen titles, e.g.
;   DL_SoundEditWriteCopy's "SOUND EDIT".
""",
}


def apply(n1c):
    raw = open(SRC, "rb").read()
    txt = raw.decode("latin-1")
    L = txt.split("\n")
    i = [k for k, t in enumerate(L) if t.startswith("DL_F2E91A:")]
    assert len(i) == 1
    i = i[0]
    assert L[i - 2].startswith("; 0xF2E91A-0xF2E9E2 -- 28 records")
    # the 15th record header after the label is 0xF2E97A
    k, n = i + 1, 0
    while True:
        if re.match(r'^\t\.byte 0x[0-9A-F]{2}, 0x[0-9A-F]{2}\t; op [0-9A-F]{2}, \d+ bytes', L[k]):
            n += 1
            if n == 15:
                break
        k += 1
    assert "op 19" in L[k], L[k]
    L = L[:k] + HDR2.split("\n") + ["DL_JpControlTrackAlreadyExists:"] + L[k:]
    L = L[:i - 3] + HDR1.split("\n") + ["DL_JpChordTrackAlreadyExists:"] + L[i + 1:]
    txt = "\n".join(L)
    for name, note in FONT_NOTES.items():
        note = note.replace("{n1c}", str(n1c))
        anchor = "; --------------------------------------------------------------------------\n%s:" % name
        assert txt.count(anchor) == 1, name
        txt = txt.replace(anchor, note + anchor)
    out = txt.encode("latin-1") if False else None
    # the notes are UTF-8 text: splice them as bytes
    data = b""
    for chunk in re.split(r'([^\x00-\xff]+)', txt):
        data += chunk.encode("utf-8") if chunk and ord(max(chunk)) > 0xFF else chunk.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


if __name__ == "__main__":
    sys.exit(main())
