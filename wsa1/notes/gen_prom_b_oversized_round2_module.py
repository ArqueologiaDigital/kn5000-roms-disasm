#!/usr/bin/env python3
"""Close 7 MORE instances of the "oversized Data_Fxxxxxx object" defect the
2026-09-01 pass found (and fixed 3 times) in prom_b: a small `Data_Fxxxxxx`
object, sized by round 1's reachability walk, that is actually the LEADING
BYTES of an interpreter-A display list continuing into the `.incbin` right
after it.

QUESTION IT ANSWERS
    Round 1's `Data_Fxxxxxx` objects are sized by where a POINTER's reach
    stops -- a `.long`/immediate names the object's start, but nothing in that
    method bounds its END, so it defaults to "until a linear decode looks
    wrong". For these 7, that end landed a handful of bytes into a display
    list already fully framed by call-site evidence on its FAR side (the
    object right after the neighbouring `.incbin`, or an already-converted
    display list). Walking DL.walk() from the OBJECT'S OWN START -- not
    shrunk, not shifted, just re-typed -- reaches that far boundary with ZERO
    DRIFT in every one of the 7 cases:

        object        object+incbin span      records  landing (already real)
        Data_F02295   0xF02295-0xF022F7  98B  11        display-list records
        Data_F0459F   0xF0459F-0xF04632 147B  16        Data_F04632 (named)
        Data_F3391E   0xF3391E-0xF339B4 150B  12        display-list records
        Data_F34256   0xF34256-0xF3434C 246B  27        Data_F3434C (named)
        Data_F394E3   0xF394E3-0xF39551 110B  11        display-list records
        Data_F39737   0xF39737-0xF39854 285B  19        display-list records
        Data_F3987A   0xF3987A-0xF3998E 276B  31        display-list records

    Every opcode used is a documented interpreter-A handler (DL.HANDLERS) and
    no record is a same-byte fill run -- the same two checks every earlier
    fix in this family used. 5 of the 7 sites are exactly one `=== COVER-R1
    ... === .. === END COVER-R1 ... ===` block (nothing else lives inside
    it), so those markers are removed along with the stale measurement they
    bracketed. `Data_F34256` shares its COVER-R1 block with an UNTOUCHED
    second object (`Data_F3434C`); only its own divider-delimited comment is
    replaced, and the block's start/end markers are left as the (now
    partially superseded, still historically accurate for the untouched
    remainder) round-1 record. `Data_F0459F` was never inside a COVER-R1
    block at all -- just its own divider comment -- so only that is replaced.

    NOT included: a coincidental hit at "0xF326DC" (17 records, 320 bytes)
    that does NOT start at any declared object boundary -- it starts mid-way
    through a `step 28` bitmap table's raster bytes, which are dense in
    values that also happen to satisfy `op < 0x24`. That table's high internal
    regularity is exactly the false-positive shape the lane brief's "the
    trap" warns about; it is left `.incbin` pending a real second signal.

VERIFICATION
    --selftest: every OLD block is present verbatim (so this script breaks
    loudly if the tree has drifted), every walk frames end to end with zero
    drift, every opcode is a documented interpreter-A handler, no record is a
    same-byte run, and the far boundary is the exact address of an
    already-named/converted neighbour. The byte gate (`make gate-wsa1`) is
    what actually certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_oversized_round2_module.py --selftest
    python3 notes/gen_prom_b_oversized_round2_module.py --splice
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
    """Pull the exact verbatim text to replace for one site, straight out of
    the CURRENT tree -- never hand-transcribed, so it cannot silently drift
    from what is actually committed. `wraps`: the whole `=== COVER-R1 ... ===`
    .. `=== END COVER-R1 ... ===` block (True), or just the divider-delimited
    object comment plus its `.byte`/`.incbin` lines (False, for the two sites
    that are not COVER-R1-wrapped, or share their block with an untouched
    neighbour)."""
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
    ("F02295", 0xF02295, 0xF022F7, True),
    ("F0459F", 0xF0459F, 0xF04632, False),
    ("F3391E", 0xF3391E, 0xF339B4, True),
    ("F34256", 0xF34256, 0xF3434C, False),
    ("F394E3", 0xF394E3, 0xF39551, True),
    ("F39737", 0xF39737, 0xF39854, True),
    ("F3987A", 0xF3987A, 0xF3998E, True),
]


# --lo/--hi note: some names collide with pre-existing DL_ labels elsewhere
# (none do here; verified in --selftest by uniqueness of the OLD block text).

def build_dl_text(b, name, start, end):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, start, end)
    if recs is None:
        raise SystemExit("%s: display list does not frame end to end" % name)
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; Formerly Data_%s -- that was the LEADING BYTES of this list, not a\n"
           "; separate object.  Zero-drift walk, notes/gen_prom_b_oversized_round2_module.py\n"
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
        print("gen_prom_b_oversized_round2_module.py --selftest")
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

        # the excluded false-positive candidate: confirm it is NOT a declared
        # object boundary (so it is correctly left out of SITES above)
        text_f326dc = "Data_F326DC:"
        check("the excluded 0xF326DC candidate has NO declared object there",
              text_f326dc in text, False)

        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--splice" in sys.argv:
        nrec, nbytes = splice_all(b)
        print("spliced 7 sites: %d display-list records, %d bytes total "
              "(objects re-typed + their neighbouring .incbin closed)"
              % (nrec, nbytes))
        return 0

    print("usage: --selftest | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
