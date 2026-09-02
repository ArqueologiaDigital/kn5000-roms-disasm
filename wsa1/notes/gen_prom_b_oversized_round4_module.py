#!/usr/bin/env python3
"""Close 10 MORE instances of the same "oversized Data_Fxxxxxx object"
defect, found by re-running the round-2/round-3 scan (every `Data_Fxxxxxx:`
label immediately followed by its own `.incbin`, tested with DL.walk() from
the object's own start) against the tree AFTER rounds 2 and 3 landed.

QUESTION IT ANSWERS
    Rounds 2 and 3 closed 13 sites; re-running the same scan on the result
    finds 10 more, some in COVER-R1 blocks rounds 2/3 already partly touched
    (0xF04574-0xF04672 held round 2's Data_F0459F fix AND two more untouched
    objects), some new. Every one frames end to end with ZERO DRIFT from the
    object's own declared start onto an already-named or already-converted
    neighbour, with every opcode a documented interpreter-A handler and no
    same-byte fill record:

        object       span               records  landing
        Data_F339BC  0xF339BC-0xF33A1B  11       Data_F33A1B (named)
        Data_F03107  0xF03107-0xF03133  5        Data_F03133 (named, itself fixed below)
        Data_F03133  0xF03133-0xF0315F  5        Data_F0315F (named; itself a weak
                                                   1-record hit, left untouched)
        Data_F02F36  0xF02F36-0xF02F52  4        Data_F02F52 (named)
        Data_F04574  0xF04574-0xF0459F  4        DL_F0459F, already real (round 2)
        Data_F04632  0xF04632-0xF04650  3        Data_F04650 (named, itself fixed below)
        Data_F04650  0xF04650-0xF04668  3        Data_F04668 (named; itself a weak
                                                   1-record hit, left untouched)
        Data_F054B1  0xF054B1-0xF054D9  4        Data_F054D9 (named)
        Data_F03D4A  0xF03D4A-0xF03D68  3        already-real display-list records
        Data_F3C873  0xF3C873-0xF3C89D  3        already-real display-list records

    Two of the ten (Data_F03D4A, Data_F3C873) are their own entire COVER-R1
    block -- markers removed along with the stale measurement. The other
    eight share a COVER-R1 block with at least one object that does NOT
    frame (a single-record hit, excluded per the lane brief's caution about
    single-record matches needing extra evidence beyond DL.walk() alone) --
    only their own divider-delimited comment is replaced, block markers left.

    NOT included, all single-record DL.walk() hits with no second signal
    (the exact shape the brief's "the trap" and the committed self-framing
    script's null test both warn produces noise): 0xF0315F, 0xF04668,
    0xF05031, 0xF34968, 0xF34CA2, 0xF351F9, 0xF3A0D9, 0xF3A433.

VERIFICATION
    --selftest: every OLD block is present verbatim (extracted live, never
    hand-transcribed), every walk frames end to end with zero drift, every
    opcode is a documented interpreter-A handler, no record is a same-byte
    run, and each of the 8 excluded single-record addresses is confirmed
    to still be a single-record DL.walk() hit (so leaving them out remains
    the documented, checked call, not silent omission). The byte gate
    (`make gate-wsa1`) is what actually certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_oversized_round4_module.py --selftest
    python3 notes/gen_prom_b_oversized_round4_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-72s %-10s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def extract_old_block(text, name, wraps, end=None):
    lines = text.split("\n")
    label = "Data_%s:" % name
    lidx = [i for i, l in enumerate(lines) if l.strip() == label]
    if len(lidx) != 1:
        raise SystemExit("%s: expected exactly one %s, found %d" % (name, label, len(lidx)))
    lidx = lidx[0]
    eidx = [i for i, l in enumerate(lines)
            if ("Data_%s -- " % name) in l and "EMITTED AS DATA" in l]
    if len(eidx) != 1:
        raise SystemExit("%s: expected exactly one EMITTED AS DATA comment, found %d"
                         % (name, len(eidx)))
    divider = eidx[0] - 1
    j = lidx
    while ".incbin" not in lines[j]:
        j += 1
    if wraps:
        rng = "0x%s-0x%06X" % (name, end)
        starts = [i for i, l in enumerate(lines) if l.strip() == "; === COVER-R1 %s ===" % rng]
        ends = [i for i, l in enumerate(lines) if l.strip() == "; === END COVER-R1 %s ===" % rng]
        if len(starts) != 1 or len(ends) != 1:
            raise SystemExit("%s: expected exactly one COVER-R1 start/end pair, found %d/%d"
                             % (name, len(starts), len(ends)))
        lo, hi = starts[0], ends[0]
    else:
        lo, hi = divider, j
    return "\n".join(lines[lo:hi + 1])


# Each site: (name, start, end, wraps_own_cover_r1_markers)
SITE_KEYS = [
    ("F339BC", 0xF339BC, 0xF33A1B, False),
    ("F03107", 0xF03107, 0xF03133, False),
    ("F03133", 0xF03133, 0xF0315F, False),
    ("F02F36", 0xF02F36, 0xF02F52, False),
    ("F04574", 0xF04574, 0xF0459F, False),
    ("F04632", 0xF04632, 0xF04650, False),
    ("F04650", 0xF04650, 0xF04668, False),
    ("F054B1", 0xF054B1, 0xF054D9, False),
    ("F03D4A", 0xF03D4A, 0xF03D68, True),
    ("F3C873", 0xF3C873, 0xF3C89D, True),
]

EXCLUDED_SINGLE_RECORD = [
    ("F0315F", 0xF0315F, 0xF03169),
    ("F04668", 0xF04668, 0xF04672),
    ("F05031", 0xF05031, 0xF0503B),
    ("F34968", 0xF34968, 0xF34970),
    ("F34CA2", 0xF34CA2, 0xF34CAD),
    ("F351F9", 0xF351F9, 0xF35208),
    ("F3A0D9", 0xF3A0D9, 0xF3A0E4),
    ("F3A433", 0xF3A433, 0xF3A43E),
]


def build_dl_text(b, name, start, end):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, start, end)
    if recs is None:
        raise SystemExit("%s: display list does not frame end to end" % name)
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; Formerly Data_%s -- that was the LEADING BYTES of this list, not a\n"
           "; separate object.  Zero-drift walk, notes/gen_prom_b_oversized_round4_module.py\n"
           % (start, end - 1, len(recs), end - start, name),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % start)
    out += DL.render(b, recs, hta, set())
    return "".join(out).rstrip("\n"), recs


def splice_all(b):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    total_recs, total_bytes = 0, 0
    for name, start, end, wraps in SITE_KEYS:
        old = extract_old_block(text, name, wraps, end)
        if text.count(old) != 1:
            raise SystemExit("REFUSING %s: expected exactly one match, found %d"
                             % (name, text.count(old)))
        new_block, recs = build_dl_text(b, name, start, end)
        text = text.replace(old, new_block, 1)
        total_recs += len(recs)
        total_bytes += end - start
    write_part(path, text, root=ROOT, allow_growth=True)
    return total_recs, total_bytes


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_oversized_round4_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
        for name, start, end, wraps in SITE_KEYS:
            old = extract_old_block(text, name, wraps, end)
            check("%s: old block present verbatim, exactly once" % name,
                  text.count(old), 1)
            recs = DL.walk(b, start, end)
            check("%s: frames end to end with zero drift" % name, recs is not None, True)
            if recs:
                all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
                check("%s: every opcode is a documented interpreter-A handler" % name,
                      all_known, True)
                no_fill = all(len(set(b[p - B_BASE:p - B_BASE + ln])) > 1 for p, op, ln in recs)
                check("%s: no record is a same-byte fill run" % name, no_fill, True)
                consumed = sum(ln for _p, _op, ln in recs)
                check("%s: consumed bytes == span length" % name, consumed, end - start)

        for name, start, end in EXCLUDED_SINGLE_RECORD:
            recs = DL.walk(b, start, end)
            check("excluded %s: still exactly one record (no second signal)" % name,
                  len(recs) if recs else 0, 1)

        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--splice" in sys.argv:
        nrec, nbytes = splice_all(b)
        print("spliced 10 sites: %d display-list records, %d bytes total; "
              "8 single-record candidates left untouched"
              % (nrec, nbytes))
        return 0

    print("usage: --selftest | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
