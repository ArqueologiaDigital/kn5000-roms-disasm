# The WSA1R's private Japanese encoding — transcription, and the ordering test

Lane `rq-fonts`, 2026-09-02.  These four files exist to answer one question the
disassembly had left open in as many words:

> prom_a `LCD_Svc_1A_DrawKanjiSetA16x16`: *"Unknown: ⚠ the ENCODING. 224
> contiguous codes from 0x10 match no standard Japanese encoding … Nothing in
> prom_a says which ideograph a given code is, and prom_a cannot say."*

| file | what question it answers |
|---|---|
| `kanji_transcription.txt` | **which ideograph each code is** — all 224 cells of set A and all 43 of set B, read off the committed contact sheets |
| `wordlist_2char.txt` | the ORACLE for the ordering test: every EDICT2 headword that is exactly two kanji from that alphabet |
| `../../scripts/analysis/kanji_order_hypothesis.py` | **is the encoding ordered by the text it was collected from?** |
| `../../scripts/analysis/japanese_text_census.py` | **is there any Japanese text in the firmware at all?** |

## Exact commands

    # 1. the transcription is data; it is checked for shape by
    python3 scripts/analysis/kanji_order_hypothesis.py --selftest

    # 2. the ordering test (the word list is committed, so this needs no network)
    python3 scripts/analysis/kanji_order_hypothesis.py

    # 3. rebuild the word list from scratch (7.8 MB download)
    curl -o /tmp/edict2.gz https://ftp.edrdg.org/pub/Nihongo/edict2.gz
    python3 scripts/analysis/kanji_order_hypothesis.py --build-wordlist /tmp/edict2.gz

    # 4. is there Japanese text in the four images?  The instrument first
    #    proves it can find text that IS there:
    python3 scripts/analysis/japanese_text_census.py --selftest
    python3 scripts/analysis/japanese_text_census.py --all            # list candidates
    python3 scripts/analysis/japanese_text_census.py --build-dict /tmp/edict2.gz
    python3 scripts/analysis/japanese_text_census.py --all --dict-test
    python3 scripts/analysis/japanese_text_census.py --all --dict-test --plant 20

`--build-dict` writes `kana_words.txt` (151,357 words, 2.7 MB).  That file is
**regenerable and therefore not committed**; the run quoted in
`../FINDINGS-fonts.md` used

    sha256  33f92e0892bbc4b925bee27aa5291a487edf53ca57f52d7ca17926fe3d0174ec
    edict2.gz as published 2026-09-02, 7,827,080 bytes

## What the numbers were, on 2026-09-02

* ordering test, set A: **72** adjacent-code pairs are dictionary words, against
  a shuffle null of **24.8 ± 4.8** over 10,000 permutations of the same 224
  characters — 9.9 sd, 0/10000 permutations reach it.  Distance-2 through
  distance-8 controls sit on the null (18–28).
* ordering test, set B (43 cells): 6 against a null of 2.6 ± 1.5, p = 0.041 —
  the same direction, not on its own conclusive.
* text census: the four images hold **no Japanese kana text**.  The real kana
  layout scores no better than random re-mappings of the same 87 codes, while
  planting 20 real sentences separates instantly (prom_a 4 → 54, 24/200 → 0/200).

EDICT2 is © Electronic Dictionary Research and Development Group, Monash
University, licensed CC BY-SA 4.0.  Only a derived word list is used here.
