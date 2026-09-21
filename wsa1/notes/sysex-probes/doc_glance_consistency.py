#!/usr/bin/env python3
"""Does the reference's summary card still agree with the chapters?

QUESTION IT ANSWERS
  `sec-glance.tex` repeats, in one page, byte sequences that the body chapters
  state in full.  A summary that drifts from the text it summarises is worse
  than no summary, because it is the page a reader will actually copy from --
  and drift is silent: both pages still compile, and both still look right.

  This checks that every fixed byte sequence printed on the card also appears
  in some other chapter.  It is a one-directional test: it catches the card
  claiming something the body does not say.  It cannot catch the body changing
  a value the card never mentioned, which is why it reports its coverage.

METHOD
  Every `\\bytes{...}` on the card is reduced to its leading run of literal hex
  bytes -- so `F0 50 2B \\ldots` reduces to `F0 50 2B`, and a group that begins
  with a variable reduces to nothing and is skipped.  That run must occur
  inside some `\\bytes{...}` in another .tex file of the document.

RUN
  python3 wsa1/notes/sysex-probes/doc_glance_consistency.py

PASS CRITERION
  Every checkable sequence on the card is found in the body, the counts are
  printed, and OK.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DOC = os.path.abspath(os.path.join(HERE, "..", "..", "docs",
                                   "system-exclusive-reference"))
CARD = "sec-glance.tex"

BYTES = re.compile(r"\\bytes\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}")
HEXTOK = re.compile(r"^[0-9A-F]{2}$")


def groups(text):
    return BYTES.findall(text)


def prefix(group):
    """The leading run of literal hex bytes, as a string."""
    out = []
    for tok in group.replace("\\,", " ").split():
        if HEXTOK.match(tok):
            out.append(tok)
        else:
            break
    return " ".join(out)


def main():
    card_path = os.path.join(DOC, CARD)
    if not os.path.exists(card_path):
        raise SystemExit("no summary card at %s" % card_path)
    card = open(card_path).read()

    body = []
    for fn in sorted(os.listdir(DOC)):
        if fn.endswith(".tex") and fn not in (CARD, "style.tex"):
            body.append(open(os.path.join(DOC, fn)).read())
    body_groups = [g for t in body for g in groups(t)]
    assert body_groups, "no byte groups found in the body chapters"

    checked, skipped, missing = 0, 0, []
    for g in groups(card):
        p = prefix(g)
        if len(p.split()) < 2:          # nothing literal enough to check
            skipped += 1
            continue
        checked += 1
        if not any(p in b for b in body_groups):
            missing.append((p, g))

    print("\nSUMMARY CARD vs THE CHAPTERS")
    print("  %d byte groups on the card" % (checked + skipped))
    print("  %d checkable (two or more literal bytes), %d too variable to check"
          % (checked, skipped))
    print("  %d body byte groups searched" % len(body_groups))
    if missing:
        print("\n  NOT FOUND IN ANY CHAPTER:")
        for p, g in missing:
            print("    card says   : %s" % g)
            print("    reduced to  : %s" % p)
    assert not missing, "%d sequence(s) on the card are in no chapter" % len(missing)
    print("\n  every checkable sequence on the card is stated in a chapter too")
    print("OK")


if __name__ == "__main__":
    main()
