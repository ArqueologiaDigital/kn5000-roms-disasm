#!/usr/bin/env python3
r"""DOES A DATA-AS-CODE MISFRAME INFLATE THE BLIND-START ENRICHMENT SIGNAL?
(lane v10seq, 2026-09-02)

QUESTION ANSWERED
-----------------
`scripts/analysis/byte_run_start_enrichment.py` reads an image's leftover
`.byte` runs as undecoded CODE when they start disproportionately often with a
byte the pinned backend cannot decode -- {0x01 normal, 0x04 max, 0x17 ldf,
0x1a JP nnnn, 0x1c CALL nnnn} -- against a decodable control set
{0x02,0x03,0x05,0x16,0x1b}.  Its premise is that a conversion pass leaves
behind exactly what the decoder refused.

This script asks whether a SECOND mechanism can produce the same signature:
a DATA table that is misframed AS CODE.  Such a region is written as mnemonics
with short `.byte` islands wherever the (wrong) instruction stream hit a byte
the decoder refuses.  If the table's data happens to use 0x01/0x04 as ordinary
values -- and byte-and-index tables do, constantly -- then every one of those
islands starts with a blind byte, for a reason that has nothing to do with any
instruction being present.

THE TEST
--------
Count blind-starting and control-starting `.byte` runs in one file at two
commits: before and after a region in it is re-typed from mnemonics to data on
independent cross-reference evidence (a reader that indexes it, and no call or
jump into it).  If the misframe was inflating the statistic, re-typing the
region -- which converts no run into any instruction, and cannot therefore
have removed any real undecoded code -- collapses the file's blind rate.

RESULT, v10/maincpu/sequencer/seq_event_playback.s, the highest-rate file in
v10 (40.9%, per the enrichment tool's own per-file table):

    BEFORE 9497e290   runs=137  blind= 56 (40.9%)  control=0
    AFTER  0061876e   runs= 76  blind=  4 ( 5.3%)  control=0

52 of the 56 blind-starting runs were fragments inside two lookup tables
(Voice_NoteChannelTable1 and its +0x43F grid) that were still spelled as
nop/di/ei/reti mnemonics.  The tables hold LE16 pairs whose high byte is a
small bank index, so 0x01 occurs at every other byte and any misframe of them
manufactures blind-starting runs in bulk.

WHAT THIS DOES AND DOES NOT SHOW
  * It does NOT refute the image-wide enrichment: the other high-rate files in
    this directory are untouched by it and may well be undecoded code.
  * It DOES show the instrument has a confound in the opposite direction, so a
    per-file rate cannot be read as a count of undecoded-code fragments until
    the file's data-as-code misframes have been cleared.

RUN
    python3 scripts/analysis/seq_blind_start_confound.py \
        --file v10/maincpu/sequencer/seq_event_playback.s \
        --before 9497e290 --after HEAD
"""
import argparse
import subprocess

BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "JP nnnn", 0x1c: "CALL nnnn"}
CONTROL = {0x02, 0x03, 0x05, 0x16, 0x1b}


def byte_runs(text):
    """Maximal runs of consecutive `.byte` lines; blanks/comments do not break."""
    out, cur = [], []
    for raw in text.split("\n"):
        s = raw.split(";", 1)[0].strip()
        if s.startswith(".byte"):
            cur += [int(v, 0) & 0xFF
                    for v in (x.strip() for x in s[5:].split(",")) if v]
        elif s == "":
            continue
        else:
            if cur:
                out.append(cur)
                cur = []
    if cur:
        out.append(cur)
    return out


def score(rev, path):
    blob = subprocess.run(["git", "show", "%s:%s" % (rev, path)],
                          capture_output=True, check=True).stdout
    runs = byte_runs(blob.decode("latin-1"))
    blind = [r for r in runs if r[0] in BLIND]
    ctrl = [r for r in runs if r[0] in CONTROL]
    return runs, blind, ctrl


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", help="one tracked path")
    ap.add_argument("--dir", help="score every tracked *.s under this path")
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", default="HEAD")
    a = ap.parse_args()
    if not a.file and not a.dir:
        ap.error("give --file or --dir")
    for rev, tag in ((a.before, "BEFORE"), (a.after, "AFTER ")):
        if a.file:
            paths = [a.file]
        else:
            listing = subprocess.run(["git", "ls-tree", "-r", "--name-only",
                                      rev, a.dir], capture_output=True,
                                     check=True).stdout.decode()
            paths = [p for p in listing.split("\n") if p.endswith(".s")]
        R = B = C = N = 0
        for p in paths:
            runs, blind, ctrl = score(rev, p)
            R += len(runs); B += len(blind); C += len(ctrl)
            N += sum(len(r) for r in runs)
        print("  %s %-10s files=%2d runs=%4d  blind=%3d (%4.1f%%)  control=%d  operands=%d"
              % (tag, rev, len(paths), R, B, 100.0 * B / max(1, R), C, N))


if __name__ == "__main__":
    main()
