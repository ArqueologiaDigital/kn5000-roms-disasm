#!/usr/bin/env python3
r"""PtrTable_F98DE5 (0xF98DE5-0xF98FFF) is a dead second copy of the MessageScreen_* tables.

QUESTION THIS ANSWERS
    The table's header ended "NOT ESTABLISHED: what indexes the table", after a
    whole-image scan found no base.  Now that MessageScreen_ListPairs and its
    three sibling tables at 0xF99121 are read (gen_message_pairs.py), the span
    below them can be laid against that structure word for word:

      words   0..76   the tail of a (start,end) pair table -- old pair words
                      49..125 of a table whose base was 0xF98D21
      words  77..82   3 interpreter-B pairs, identical to MessageScreen_ListPairsB
      words  83..114  32 handler pointers: 0xF98D20 x31 and 0xF98C85 in slot 15
                      -- MessageScreen_ArgHandlers' pattern with every value
                      0x400 lower (0xF99120 / 0xF99085)
      words 115..117  3 x 0xF98D21 -- MessageScreen_PairTableByLanguage's
                      pattern, the old base, again 0x400 lower
      words 118..133  + 3 bytes: more (start,end) words, German-language lists,
                      cut by the module boundary at 0xF99000

    Its own pointers are STALE: 0xF98D20, 0xF98D21 and 0xF98C85 are not
    instruction starts in this image (the old base lies under the routine that
    ends at 0xF98DE4, which is why the first 49 words are gone), and nothing
    in either CPU-1 image names an address in the span.  Nothing indexes it
    because nothing can: it is an unreachable leftover, like the 0x400-lower
    dead copies at 0xF8A44B and 0xFAA000.

CHECKS (against wsa1/original_ROMs and the source's statement starts)
    T1  words 77..82 == the six words of MessageScreen_ListPairsB (0xF99321)
    T2  words 83..114 == MessageScreen_ArgHandlers' 32 words - 0x400
    T3  words 115..117 == 0xF99121 - 0x400; 0xF98D21 + 0x1F8 == word 77's address
    T4  0xF98D20, 0xF98D21, 0xF98C85 are not statement starts in the source
    T5  every LE24 value in [0xF98D00, 0xF99000) found in prom_a outside the
        span lies inside an instruction line (a byte coincidence, not a
        pointer); prom_b's one hit is a window that starts on a `calr` opcode

RUN
    python3 notes/proma-2026-09-25/gen_message_stale.py          # checks
    python3 notes/proma-2026-09-25/gen_message_stale.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
S = 0xF98DE5


def l32(r, a):
    return int.from_bytes(r[a - B:a - B + 4], "little")


def checks(m):
    r = m.rom
    w = [l32(r, S + 4 * k) for k in range(134)]
    assert w[77:83] == [l32(r, 0xF99321 + 4 * k) for k in range(6)]
    print("T1 ok: words 77..82 are MessageScreen_ListPairsB's six words")
    live = [l32(r, 0xF99339 + 4 * k) for k in range(32)]
    assert w[83:115] == [x - 0x400 for x in live]
    print("T2 ok: words 83..114 are MessageScreen_ArgHandlers - 0x400 (slot 15 = 0xF98C85)")
    assert w[115:118] == [0xF99121 - 0x400] * 3 and 0xF98D21 + 0x1F8 == S + 4 * 77
    print("T3 ok: words 115..117 = 0xF98D21; old pair table 0xF98D21 + 0x1F8 = 63 pairs")
    for a in (0xF98D20, 0xF98D21, 0xF98C85):
        assert m.line_of(a) is None, hex(a)
    print("T4 ok: the copy's own pointers land on no statement start")
    L = m.lines
    starts = m.sorted
    import bisect
    n = 0
    for i in range(len(r) - 2):
        v = int.from_bytes(r[i:i + 3], "little")
        a = B + i
        if 0xF98D00 <= v < 0xF99000 and not (S <= a < 0xF99000):
            k = bisect.bisect_right(starts, a) - 1
            line = L[m.line_of(starts[k])].split(";")[0].strip()
            assert line and not line.startswith("."), (hex(a), line)
            n += 1
    rb = open(os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    hits = [0xF00000 + i for i in range(len(rb) - 2)
            if 0xF98D00 <= int.from_bytes(rb[i:i + 3], "little") < 0xF99000]
    assert all(rb[h - 0xF00000] == 0x1E for h in hits), [hex(h) for h in hits]  # window = `calr` + disp
    print("T5 ok: %d prom_a coincidences, all inside instruction lines; prom_b %s are calr"
          % (n, [hex(h) for h in hits]))
    return w


HDR = {
    77: ["; MessageScreenStale_ListPairsB -- 3 (start,end) pairs, the older build's",
         ";          MessageScreen_ListPairsB: the same six words (check T1)."],
    83: ["; MessageScreenStale_ArgHandlers -- 32 LE32, the older build's",
         ";          MessageScreen_ArgHandlers: every value is the live one - 0x400",
         ";          (check T2).  Left numeric on purpose: 0xF98D20 and 0xF98C85 are",
         ";          not instruction starts in THIS image (check T4)."],
    115: ["; MessageScreenStale_PairTableByLanguage -- 3 x 0xF98D21, the older build's",
          ";          pair-table base (live 0xF99121 - 0x400; check T3).  Numeric for",
          ";          the same reason: 0xF98D21 is mid-instruction here."],
    118: ["; MessageScreenStale_ExtraListPairs -- (start,end) words the live layout does",
          ";          not have, naming prom_b's German-language lists; the last word",
          ";          is cut by the module boundary at 0xF99000 (see the header above)."],
}
NAMES = {77: "MessageScreenStale_ListPairsB", 83: "MessageScreenStale_ArgHandlers",
         115: "MessageScreenStale_PairTableByLanguage", 118: "MessageScreenStale_ExtraListPairs"}


def apply(m):
    L = m.lines
    dash = "; ---------------------------------------------------------------------"
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    for k in sorted(HDR, reverse=True):
        i = m.line_of(S + 4 * k)
        assert re.match(r"^\t\.long ", L[i]), L[i]
        L[i:i] = [u8(x) for x in [dash] + HDR[k] + [dash, NAMES[k] + ":"]]
    old = [
        "; NOT ESTABLISHED: what indexes the table.  No literal 0x00F98DE5, nor any",
        "; base inside 0xF98D00-0xF99010, exists in any of the four images.",
        "; PtrTable_F99121 has the same gap and was converted anyway.",
    ]
    i = L.index(old[0])
    assert L[i:i + 3] == old
    L[i:i + 3] = [u8(x) for x in [
        "; WHAT IT IS -- established 2026-09-25 (lane proma), checks T1-T5 of",
        ";   notes/proma-2026-09-25/gen_message_stale.py: a SECOND COPY of the four",
        ";   MessageScreen_* tables at 0xF99121, 0x400 lower and unreachable -- the",
        ";   shape of the dead copies at 0xF8A44B and 0xFAA000.  Whether it is an",
        ";   older build or a variant's (its extra pairs name the GERMAN lists, see",
        ";   wsa1/notes/sysex-probes/decode-findings.json) is a reading, not shown.",
        ";   Laid against that structure, words 77..82 are its",
        ";   interpreter-B pairs verbatim, words 83..114 its 32 argument handlers",
        ";   and 115..117 its language pointers with every local value 0x400 lower,",
        ";   so the copy's pair table started at 0xF98D21 (63 pairs): its first 49",
        ";   words lie under the routine that ends at 0xF98DE4 and are gone, and",
        ";   words 0..76 here are its words 49..125.  Its own pointers (0xF98D20,",
        ";   0xF98D21, 0xF98C85) are not instruction starts in this image, and no",
        ";   address in the span is named anywhere in either CPU-1 image.",
        "; ★ CORRECTED: this paragraph said \"what indexes the table\" was open and",
        ";   that the 0xF99121 table (then PtrTable_F99121) had \"the same gap\".",
        ";   That table's readers are found (MessageScreen_ListPairs); this one has",
        ";   none because it is dead, and its sub-tables are labelled below.",
    ]]
    txt = "\n".join(L)
    txt, k = re.subn(r"(?<![\w.$])PtrTable_F98DE5(?![\w$])", "MessageScreenStale_ListPairsTail", txt)
    assert k >= 2, k
    open(srcmap.SRC, "wb").write(txt.encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    M = srcmap.load()
    checks(M)
    if "--apply" in sys.argv:
        apply(M)
