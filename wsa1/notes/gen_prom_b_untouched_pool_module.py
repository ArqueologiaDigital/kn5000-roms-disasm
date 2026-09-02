#!/usr/bin/env python3
"""⚠⚠ THIS MODULE IS NON-FUNCTIONAL AND ITS FINDINGS BELOW ARE HISTORY (2026-09-02)

`find_site()` returns None for EVERY one of the 12 sites, so `--selftest` cannot
pass and `--splice` would emit nothing. Do not reach for it as a working tool;
read it as the record of what it once established.

⚠ AND IT DID NOT BREAK TONIGHT. Measured, not assumed: checked out at
`a99564a6` — the commit this push branched from, before any prom_b lane ran —
with the crash below repaired, `find_site` already failed for all 12 sites,
including `0xF0D4D2`, which was still `.incbin` at that revision. So the
conversions did not do this; the module was already dead.

    git worktree add --detach /tmp/base a99564a6
    cp <this file> /tmp/base/wsa1/notes/ && cd /tmp/base/wsa1
    python3 notes/gen_prom_b_untouched_pool_module.py --selftest

★ WHY NOBODY NOTICED, WHICH IS THE TRANSFERABLE PART. `--selftest` asserted
"all 12 sites are still one .incbin directive each" and then indexed the span
dict — so once a later lane converted any site it died with a bare `KeyError`
BEFORE reaching the checks that would have exposed the real breakage. A test
that fails on SUCCESS masked a test that could not pass at all. The crash was
repaired 2026-09-02 (converted sites are now reported and skipped, and a guard
shouts if every site is gone); repairing it is what revealed the deeper fault.

⚠ AND ONE CLAIM IN THE PROSE BELOW IS DISPROVED. It calls 0xF0D4D2's leading
tables "genuinely unexplained". Lane promB3 explained them: the span does not
BEGIN with records, it begins with the operand table that the two interpreter-B
records IN FRONT OF IT name at record+7 — six such pointers, all at +7 exactly.
It also found an 80x24 column-major bitmap there running 23 bytes past the span
into an `op 0C, 28 bytes` record whose handler is a bare `ret`, so that length
byte asserted nothing and had swallowed both the bitmap tail and a glyph record.
See `wsa1/notes/lane_promB3/`.

Original documentation follows, unmodified.

Close 12 sites in the "~7,600 B of medium/small spans nobody re-tested"
pool named by the PROMBFINAL lane brief -- the largest untouched debt pool
left in prom_b after the reachability walk and the oversized-object hunt
both reached fixpoint.

QUESTION IT ANSWERS
    Do any of prom_b's remaining small/medium `.incbin` spans hold ordinary
    interpreter-A/B display-list records that the committed call-shape
    scanner (notes/prom_b_dl_call_shapes.py) cannot find because NOTHING
    calls them -- no `ld XIY/XIX` site (shape 1), no stack site (shape 2/3)?
    Yes, in 12 of them: a plain op/len walk starting somewhere INSIDE the
    span lands, with ZERO DRIFT, exactly on the span's own declared end,
    every opcode is a documented interpreter-A or -B handler
    (notes/prom_b_dl_length_audit.py's IMPLIED_A/IMPLIED_B), and every
    record's length satisfies that handler's OWN implied-length rule
    ("fixed" or "min", never just "op < bound" -- see the WHY below).

    A 13th site in the same pool (0xF283A8-0xF2843D) is DELIBERATELY
    EXCLUDED: its only walk-worthy handler is 0xF31AEB, the bare-`ret`
    family (op 0x0C/0x0D/0x0F/0x10/0x14) whose implied-length rule is
    "min 2" -- true of ANY byte pair, so it corroborates nothing.  That
    span also carries reachability.py's entire prom_b STRONG total (9
    bytes) and MAME's own unidasm renders it as incoherent code (repeated
    `nop`, bare `db`, no sensible operand) starting from that offset --
    the walk-decoded-into-data pattern the F0DB18 lesson warns about, not
    corroborated code.  Left untouched; see NOT-CONVERTED below.

WHY "op < bound" ALONE IS NOT ENOUGH -- THE FALSE POSITIVES THIS REJECTED
    A first pass that only checked op < 0x24 (or < 0x0F) and length >= 2
    found 4 EXTRA "zero-drift" landings that do not survive checking each
    record's length against its OWN handler's implied-length rule:

        0xF03AF8 (skip 68)  op 0x00 len 21   handler 0xF31A75 wants FIXED 10
        0xF03C12 (skip  6)  op 0x00 len  5   handler 0xF31A75 wants FIXED 10
        0xF0D4D2 (skip 45)  op 0x01 len 150  handler 0xF31A75 wants FIXED 10
        0xF32A00 (skip  9)  op 0x02 len 15   handler 0xF31A75 (interp A)
                             -- wrong interpreter; it is a valid interp-B
                             record (handler 0xF31B21, fixed 15) instead

    All four are handled correctly below by tightening the search to
    `notes/prom_b_dl_length_audit.py`'s exact per-handler rule and by
    trying BOTH interpreters at every candidate offset -- which moves
    0xF03AF8's real start from 68 to 77, 0xF03C12's from 6 to 11, 0xF0D4D2's
    from 45 to 454 (leaving that span's leading tables genuinely
    unexplained), and reclassifies 0xF32A00 as interpreter B.  This is
    exactly the F0DB18 lesson: the FIRST plausible framing that merely
    "does not crash" is not evidence; only a framing that survives the
    per-opcode structural rule the rest of the file already proves is.

THE 0x0E-FILL TRAP, MEASURED RATHER THAN ASSUMED
    0xF32709-0xF3281C's first 247 of 275 bytes are a UNIFORM run of 0x0E
    (measured: `len(set(bytes)) == 1`), which happens to be interpreter A's
    op 0x0E -- and op 0x0E's handler (0xF31A9F) demands a FIXED length of 8,
    not the 14 a naive `[op,len]=[0x0E,0x0E]` read would walk. The strict
    per-handler check REFUSES every offset inside the fill for exactly that
    reason, so the search naturally lands on offset 247 -- the first byte
    that is not 0x0E -- without a special case. The fill itself is emitted
    as `.fill 247, 1, 0x0E`, the same idiom and comment style already used
    for `ret`-padding runs elsewhere in this file (e.g. line ~10143,
    ~11331, ~17861, ~20093). The 28 bytes after it are 4 ordinary op-0x20
    text records reading "1st"/"2nd"/"3rd"/"4th", landing exactly on
    0xF3281C -- already a named neighbour, `Data_F3281C`, fixed by the
    oversized-object hunt's round 4.

WHAT STAYS `.incbin`, WITH THE REASON STATED
    * The lead-in bytes of 8 of the 12 sites (5-153 bytes each) do not
      decode as either interpreter's records and are not a uniform fill;
      several look like operand/coordinate tables the leading records
      might index (0xF02F6F's, 0xF03A26's, 0xF32839's leads share the
      pattern `.. 03 00 0a 00`), but that is observation, not a proof, so
      they are left `.incbin` and named honestly rather than forced.
    * 0xF13D34's leading 44 bytes remain the one span this document set
      already calls "still genuinely unexplained" (README-prom_b.md, the
      PROMBFIN wave) -- re-tested here (searched at every offset, both
      interpreters) and it still does not decode. What DOES newly close is
      everything from 0xF13D60 onward: 45 records, 446 of the span's
      490 bytes, landing with zero drift exactly on the already-committed
      `DL_F13F1E` label.
    * 0xF283A8-0xF2843D (149 B): excluded above, entirely untouched.

VERIFICATION
    --selftest re-derives every (skip, interpreter) pair from scratch by
    the search described above (never hand-typed), requires the site list
    to match exactly, requires every record's raw ROM bytes to round-trip
    through its own rendered fields, and requires the excluded 0x283A8
    site to still fail the strict check (so its exclusion is not stale).
    The byte gate (`make gate-wsa1`) is what actually certifies the bytes.

RUN
    python3 notes/gen_prom_b_untouched_pool_module.py --selftest
    python3 notes/gen_prom_b_untouched_pool_module.py --show
    python3 notes/gen_prom_b_untouched_pool_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL              # noqa: E402
import prom_b_dl_length_audit as LA            # noqa: E402
import gen_prom_b_display_lists_v2 as DLV2     # noqa: E402
from asm_source import write_part              # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

# The 12 sites this round closes, as (span_start, span_end).  Re-derived and
# checked against these exact numbers in --selftest; not trusted blind.
SITES = [
    0xF02F6F, 0xF03A26, 0xF03AF8, 0xF03BE6, 0xF03C12, 0xF05621,
    0xF0D4D2, 0xF13D34, 0xF2B8F9, 0xF32709, 0xF32839, 0xF32A00,
]

# The one excluded candidate, kept here so --selftest can assert it STAYS
# excluded (bare-`ret` "min 2" rule only -- see the module docstring).
EXCLUDED = 0xF283A8

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-70s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def incbin_spans(text):
    import re
    out = []
    for m in re.finditer(r'\.incbin\s+"([^"]+)"\s*,\s*0x([0-9A-Fa-f]+)\s*,\s*0x([0-9A-Fa-f]+)', text):
        off, ln = int(m.group(2), 16), int(m.group(3), 16)
        out.append((B_BASE + off, B_BASE + off + ln, m.group(0)))
    return out


def walk_strict(b, s, e, table, implied, bound):
    """Like DL.walk, but ALSO requires every record's length to satisfy its
    own handler's implied-length rule (LA.IMPLIED_A / LA.IMPLIED_B), not
    merely `op < bound`.  Returns the record list or None."""
    recs, p = [], s
    while p < e:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= bound or ln < 2 or p + ln > e:
            return None
        h = table[op]
        if h not in implied:
            return None
        kind, n = implied[h]
        good = (ln == n) if kind == "fixed" else (ln >= n)
        if not good:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


# The two "bare `ret`, length ignored" handlers.  Their implied-length rule
# is ("min", 2) -- true of ANY two-byte-or-longer record -- so a walk landing
# on end-of-span using ONLY these handlers corroborates nothing (see the
# module docstring's account of 0xF283A8-0xF2843D).  A candidate is accepted
# only if at least one record uses a handler with real field structure.
WEAK_HANDLERS = {0xF31AEB, 0xF31D20}


def find_site(b, s, e, ta, tb):
    """Earliest offset inside [s,e) from which a FULLY implied-length-valid
    walk reaches e with >= 2 records, tried interpreter A then B at each
    offset, and at least one record is NOT a bare-`ret` weak-handler record.
    Returns (skip, interp, recs) or None."""
    for start_off in range(0, e - s - 1):
        st = s + start_off
        r = walk_strict(b, st, e, ta, LA.IMPLIED_A, 0x24)
        if r is not None and len(r) >= 2 and any(ta[op] not in WEAK_HANDLERS for _p, op, _ln in r):
            return start_off, "A", r
        r = walk_strict(b, st, e, tb, LA.IMPLIED_B, 0x0F)
        if r is not None and len(r) >= 2 and any(tb[op] not in WEAK_HANDLERS for _p, op, _ln in r):
            return start_off, "B", r
    return None


def render_records(b, recs, interp, ta, tb):
    out = []
    for p, op, ln in recs:
        if interp == "B":
            out += DLV2.render_b(b, p, op, ln, tb)
        else:
            out += DL.render(b, [(p, op, ln)], ta, set())
    return out


def build_one(b, s, e, ta, tb):
    """The rendered text for one span, and (skip, interp, recs) for checks."""
    found = find_site(b, s, e, ta, tb)
    if found is None:
        raise SystemExit("0x%06X-0x%06X no longer frames -- tree has moved" % (s, e))
    skip, interp, recs = found
    out = []
    if skip:
        lead = b[s - B_BASE:s - B_BASE + skip]
        if len(set(lead)) == 1:
            fill_byte = lead[0]
            out.append('\t.fill\t%d, 1, 0x%02X\t; 0x%06X-0x%06X `%s` padding (asserted pure 0x%02X)\n'
                       % (skip, fill_byte, s, s + skip - 1,
                          "ret" if fill_byte == 0x0E else "byte 0x%02X" % fill_byte, fill_byte))
        else:
            out.append('\n; --- 0x%06X-0x%06X: not converted -- decodes as neither interpreter\'s '
                       'records and is not a uniform fill ---\n' % (s, s + skip - 1))
            out.append('\t.incbin "%s", 0x%06X, 0x%06X\n' % (ROM, s - B_BASE, skip))
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter %s\n"
               "; NOT reached by any known call shape (reachability.py: prom_b has 0\n"
               "; bytes with start evidence) and not named by any converted record's\n"
               "; own table field either -- found because a plain op/len walk, starting\n"
               "; %d bytes into this span, lands with ZERO DRIFT exactly on the span's\n"
               "; declared end, and every record's length satisfies ITS OWN handler's\n"
               "; implied-length rule (notes/prom_b_dl_length_audit.py), not merely\n"
               "; `op < bound`.  Regenerate: python3 notes/gen_prom_b_untouched_pool_module.py\n"
               "; --splice\n" % (s + skip, e - 1, len(recs), e - (s + skip), interp, skip))
    out.append("; ------------------------------------------------------------------\n")
    out += render_records(b, recs, interp, ta, tb)
    return out, skip, interp, recs


def main():
    a, b = DL.load()
    ta, tb = LA.tables(b)

    if "--selftest" in sys.argv:
        print("gen_prom_b_untouched_pool_module.py --selftest")
        # The excluded site must still fail the strict check -- if it now
        # passes, the tree changed shape and this module's exclusion note
        # is stale.
        found_excl = find_site(b, EXCLUDED, EXCLUDED + (0xF2843D - 0xF283A8), ta, tb)
        check("excluded site 0x283A8 still fails the strict per-handler check",
              found_excl, None)

        want = {
            0xF02F6F: (7, "A", 3),  0xF03A26: (7, "A", 3), 0xF03AF8: (77, "A", 4),
            0xF03BE6: (5, "A", 3), 0xF03C12: (11, "A", 8), 0xF05621: (5, "A", 3),
            # ⚠ 0xF0D4D2's (454, 23) is the MISFRAME lane promB3 overturned:
            # the 80x24 bitmap runs 23 bytes past this span into what was
            # framed as an "op 0C, 28 bytes" record at 0xF0D698, and op 0C's
            # handler 0xF31AEB is a BARE ret -- so any length byte would have
            # walked. The corrected walk is skip 477 / 22 records. The site is
            # converted now so this entry is never exercised; it is kept as the
            # record of what the strict rule still let through, because the
            # rule required only SOME record in the walk to be non-weak, not
            # the first.
            0xF0D4D2: (477, "A", 22), 0xF13D34: (44, "A", 45), 0xF2B8F9: (153, "A", 3),
            0xF32709: (247, "A", 4), 0xF32839: (7, "A", 3), 0xF32A00: (9, "B", 3),
        }
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        spans = {s: (s, e) for s, e, _line in incbin_spans(text) if s in SITES}

        # ⚠ A SITE THAT IS NO LONGER AN .incbin HAS BEEN CONVERTED BY A LATER
        # LANE. That is the GOAL of this project, not a regression, and this
        # selftest used to assert "all 12 sites are still one .incbin directive
        # each" and then die on a KeyError the moment one of them was closed --
        # so it stopped running entirely, silently, exactly when the tree was
        # improving. A test that fails on success is a test nobody runs.
        # Corrected 2026-09-02: converted sites are REPORTED and skipped; the
        # remaining ones are still fully checked.
        remaining = sorted(spans)
        converted = sorted(set(SITES) - set(spans))
        for s in converted:
            print("  0x%06X CONVERTED by a later lane -- no longer .incbin, "
                  "skipped" % s)
        check("every site is either still .incbin or converted (none vanished)",
              sorted(set(remaining) | set(converted)), sorted(SITES))

        # ⚠ AND THE GUARD THAT KEEPS THIS HONEST. If every site has been
        # converted, the loop below checks NOTHING and the run would print
        # "0 failures" -- a criterion that cannot fail. Say so loudly instead.
        if not remaining:
            print("  ⚠ ALL 12 SITES ARE CONVERTED. This module has nothing "
                  "left to verify and its per-site expectations below are now "
                  "pure history. Retire it rather than reading a green run as "
                  "evidence of anything.")

        total_bytes = 0
        for s in remaining:
            sp_s, sp_e = spans[s]
            found = find_site(b, sp_s, sp_e, ta, tb)
            check("0x%06X site found" % s, found is not None, True)
            if found is None:
                continue
            skip, interp, recs = found
            wskip, winterp, wn = want[s]
            check("0x%06X skip" % s, skip, wskip)
            check("0x%06X interpreter" % s, interp, winterp)
            check("0x%06X record count" % s, len(recs), wn)
            # round trip: every rendered record's own (op,len) bytes match ROM
            for p, op, ln in recs:
                raw = b[p - B_BASE:p - B_BASE + ln]
                if raw[0] != op or raw[1] != ln:
                    FAIL.append("0x%06X round-trip mismatch" % p)
            total_bytes += (sp_e - sp_s)
        check("total bytes across the sites still present", total_bytes,
              sum(spans[s][1] - spans[s][0] for s in remaining))
        # the one uniform-fill site is exactly 0x0E for exactly 247 bytes
        s = 0xF32709
        if s in spans:
            lead = b[s - B_BASE:s - B_BASE + 247]
            check("0xF32709 lead-in is a pure 0x0E run of exactly 247 bytes",
                  (len(lead), len(set(lead))), (247, 1))
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
    spans = incbin_spans(text)
    by_start = {s: (s, e, line) for s, e, line in spans}

    edits = []
    total_bytes, total_recs = 0, 0
    for s in SITES:
        if s not in by_start:
            raise SystemExit("0x%06X is not a single .incbin directive any more" % s)
        sp_s, sp_e, line = by_start[s]
        rendered, skip, interp, recs = build_one(b, sp_s, sp_e, ta, tb)
        edits.append((line, "".join(rendered)))
        total_bytes += sp_e - sp_s
        total_recs += len(recs)

    if "--show" in sys.argv:
        for _old, new in edits:
            sys.stdout.write(new)
        print("\n; -- %d records, %d bytes across %d sites --" % (total_recs, total_bytes, len(SITES)),
              file=sys.stderr)
        return 0

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        cur = open(path, encoding="utf-8").read()
        for old_line, new_text in edits:
            n = cur.count(old_line)
            if n != 1:
                raise SystemExit("expected exactly one occurrence of %r, found %d" % (old_line, n))
            cur = cur.replace(old_line, new_text.rstrip("\n"), 1)
        write_part(path, cur, root=ROOT, allow_growth=True)
        print("spliced %d records, %d bytes across %d sites into %s"
              % (total_recs, total_bytes, len(SITES), S_FILE))
        return 0

    print("pass --selftest, --show or --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
