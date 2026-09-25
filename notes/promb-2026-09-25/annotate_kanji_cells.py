#!/usr/bin/env python3
r"""Put each ideograph's reading on its own cell line in prom_b's two kanji faces.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s lists Font_Svc1A_16x16 (set A, codes 0x10-0xEF)
    and Font_Svc1F_16x16 (set B, 0x10-0x3A) one 32-byte cell per line, ending
    `; <addr>  [0xNN] `.  wsa1/notes/fonts-kanji/kanji_transcription.txt reads
    every defined cell by eye from the lossless contact sheets.  The set A
    header said the characters "cannot be written here: this source is
    latin-1"; that is not so -- the sources carry UTF-8 prose (they are only
    READ as latin-1, which round-trips any byte), so the reading can sit on the
    line it describes.

    --apply appends the transcribed character to each non-blank cell line (only
    to a line that ends exactly `[0xNN] `); the default run CHECKS that every
    annotated line carries the transcription's character for its code, and that
    the defined cells and the transcription agree one for one.

GRADE
    The characters are HUMAN OCR of a 16x16 bitmap (see the transcription's
    own header): a single reading is a proposal.  Set A 0x38 is `〓` there,
    "could not be settled", and is written as such.

RUN
    python3 notes/promb-2026-09-25/annotate_kanji_cells.py            # check
    python3 notes/promb-2026-09-25/annotate_kanji_cells.py --apply    # write
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
TRANS = os.path.join(ROOT, "wsa1", "notes", "fonts-kanji", "kanji_transcription.txt")
SETS = {"A": (0xF22840, 0xF24640), "B": (0xF24640, 0xF24DC0)}
CELL = re.compile(r'; (F2[2-4][0-9A-F]{3})  \[0x([0-9A-F]{2})\] (.*)$')


def transcription():
    out = {"A": {}, "B": {}}
    for ln in open(TRANS, encoding="utf-8"):
        if ln.startswith("#") or not ln.strip():
            continue
        s, base, chars = ln.split(None, 2)
        chars = chars.strip()
        for i, ch in enumerate(chars):
            out[s][int(base, 16) + i] = ch
    return out


def main():
    apply = "--apply" in sys.argv
    tr = transcription()
    raw = open(SRC, "rb").read()
    lines = raw.split(b"\n")
    bad, done, todo = 0, 0, 0
    seen = {"A": set(), "B": set()}
    for k, bl in enumerate(lines):
        t = bl.decode("utf-8", errors="replace")
        m = CELL.search(t)
        if not m:
            continue
        addr, code = int(m.group(1), 16), int(m.group(2), 16)
        which = [s for s, (lo, hi) in SETS.items() if lo <= addr < hi]
        if not which:
            continue
        s = which[0]
        tail = m.group(3)
        if tail.startswith("blank"):
            if code in tr[s]:
                print("  FAIL set %s 0x%02X is blank in the ROM but transcribed %s" % (s, code, tr[s][code]))
                bad += 1
            continue
        seen[s].add(code)
        want = tr[s].get(code)
        if want is None:
            print("  FAIL set %s 0x%02X is defined in the ROM but not transcribed" % (s, code))
            bad += 1
            continue
        if tail == "":
            todo += 1
            if apply:
                lines[k] = bl + want.encode("utf-8")
        elif tail.split()[0] == want:
            done += 1
        else:
            print("  FAIL set %s 0x%02X line says %r, transcription says %s" % (s, code, tail, want))
            bad += 1
    for s in "AB":
        missing = set(tr[s]) - seen[s]
        if missing:
            print("  FAIL set %s: transcribed but not a defined cell: %s" % (s, sorted(missing)))
            bad += 1
    print("set A %d cells, set B %d cells; annotated %d, to annotate %d, mismatches %d"
          % (len(seen["A"]), len(seen["B"]), done, todo, bad))
    if apply and todo and not bad:
        open(SRC, "wb").write(b"\n".join(lines))
        print("applied")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
