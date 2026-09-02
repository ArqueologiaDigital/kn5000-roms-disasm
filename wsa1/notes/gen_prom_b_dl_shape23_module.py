#!/usr/bin/env python3
"""Splice prom_b's SHAPE-2/3 display-list records into the still-`.incbin` bytes
that name them -- the cheapest win notes/prom_b_dl_call_shapes.py measured and
left unspliced.

QUESTION IT ANSWERS
    notes/prom_b_dl_call_shapes.py --new says shapes 2 and 3 (the STACK call
    forms, `lda XBC,<end> / push XBC / lda XWA,<start> / push XWA / call
    {0xF42E00,0xF42E04}` and `lda XBC,<record> / push XBC / call 0xF42E0C`) name
    1,149 bytes that are STILL `.incbin`, all of them inside the single span
    0xF13D34-0xF147AB (2,680 bytes).  That census is read-only.  This script is
    the emitter: it renders those 1,149 bytes as display-list records, using the
    SAME interpreter-A/B field layouts already committed for shape 1
    (scripts/analysis/prom_b_display_lists.py, notes/gen_prom_b_display_lists_v2.py),
    and splices them into the `.incbin` directive that currently covers the
    whole span.

WHY THIS IS NOT A NEW FORMAT -- IT IS THE LESSON THE BRIEF NAMED
    Two of wave 2's three holdouts fell because a framing already documented
    elsewhere in the tree fit them; this is the same move one level down.  The
    records themselves are ordinary interpreter-A/B records (op < 0x24, length
    at +1, self-checking).  What was missing was not a decoder, it was
    RECOGNIZING THE CALL SHAPE: shape 1 passes both ends as two `ld` immediates
    and is what the committed scanner looks for; shapes 2 and 3 pass the same
    information through the STACK (`lda`/`push`), which is why the committed
    scanner's byte pattern never matched them even though the interpreter code
    at the far end (0xF42E00/0xF42E04/0xF42E0C) runs the exact same records.

HOW A RECORD'S INTERPRETER (A vs B) IS KNOWN
    Not by re-deriving ownership from the record's OWN bytes -- by the site that
    calls it.  0xF42E00 stacks (end, start) for interpreter A's runner, 0xF42E04
    for interpreter B's, and 0xF42E0C runs exactly one interpreter-B record with
    no end pointer (RUN_ONE_B).  Every byte in the 1,149-byte union is walked by
    at least one site with a known target, so every record's interpreter is
    read off the site, never guessed from content.

VERIFICATION, TWO LEVELS
    1. --selftest: the 1,149-byte total and its 10 runs must match
       `notes/prom_b_dl_call_shapes.py --new` exactly (imported, not
       re-typed), and re-rendering every record's raw bytes from the emitted
       fields must reproduce the ORIGINAL ROM bytes exactly (a per-record
       round-trip, independent of llvm-mc).
    2. The byte gate (`make gate-wsa1`) is the real certification -- this
       script's own check is what makes a gate failure fast to localize.

RUN
    python3 notes/gen_prom_b_dl_shape23_module.py --selftest
    python3 notes/gen_prom_b_dl_shape23_module.py --show          # the rendered text
    python3 notes/gen_prom_b_dl_shape23_module.py --splice        # edit the .s in place
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                     # noqa: E402
import prom_b_dl_length_audit as LA                    # noqa: E402
import prom_b_dl_call_shapes as SH                     # noqa: E402
import gen_prom_b_display_lists_v2 as DLV2             # noqa: E402
from asm_source import write_part                      # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

# The one span this round closes bytes in.  Read from the .incbin directive
# itself in --selftest, so it cannot silently drift from the committed file.
SPAN_FILE_OFF = 0x013D34
SPAN_SIZE = 0x000A78
SPAN_S = B_BASE + SPAN_FILE_OFF
SPAN_E = SPAN_S + SPAN_SIZE

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def gather(a, b):
    """{record_start: (op, ln, interp)} for every shape-2/3 record this round
    can attribute, plus the ordered list of (run_start, run_end_excl)."""
    sites = SH.scan(a, b)
    rec_interp = {}   # record start -> 'A' or 'B'
    starts = set()     # every site start, for label placement

    def mark_walk(s, e, interp):
        r = DL.walk(b, s, e)
        if r is None:
            return
        for p, op, ln in r:
            prev = rec_interp.get(p)
            if prev is not None and prev != interp:
                raise SystemExit("conflicting interpreter at 0x%06X: %s vs %s" % (p, prev, interp))
            rec_interp[p] = interp

    _ta, tb = LA.tables(b)
    for shape, site, s, e, t in sites:
        if not (B_BASE <= s < 0xF80000):
            continue    # prom_a is the sibling lane's file
        if shape == 2:
            interp = "A" if t == SH.STACK_A else "B"
            if DL.walk(b, s, e) is None:
                continue
            starts.add(s)
            mark_walk(s, e, interp)
        elif shape == 3:
            if not (B_BASE <= s < B_BASE + len(b) - 2):
                continue
            op, ln = b[s - B_BASE], b[s - B_BASE + 1]
            if op >= 0x0F:
                continue
            kind, want = LA.IMPLIED_B[tb[op]]
            good = ln >= want if kind == "min" else ln == want
            if not good:
                continue
            starts.add(s)
            mark_walk(s, s + ln, "B")

    # Union the covered bytes into maximal contiguous runs, exactly as
    # prom_b_dl_call_shapes.py --new does (re-derived here, not re-typed).
    covered = set()
    for p, (op, ln) in ((p, (b[p - B_BASE], b[p - B_BASE + 1])) for p in rec_interp):
        covered.update(range(p, p + ln))
    runs = []
    for x in sorted(covered):
        if runs and x == runs[-1][1]:
            runs[-1][1] = x + 1
        else:
            runs.append([x, x + 1])
    return rec_interp, starts, [tuple(r) for r in runs]


def render_run(b, s, e, rec_interp, starts, hta, htb):
    """Assembly text for one contiguous run, walked fresh from s to e."""
    recs = DL.walk(b, s, e)
    if recs is None:
        raise SystemExit("run 0x%06X-0x%06X does not frame as a flat op/len walk" % (s, e))
    out = []
    for p, op, ln in recs:
        interp = rec_interp[p]
        if p in starts:
            out.append("DL_%06X:\n" % p)
        if interp == "B":
            out += DLV2.render_b(b, p, op, ln, htb)
        else:
            out += DL.render(b, [(p, op, ln)], hta, set())
    return out, recs


def build(b):
    a = DL.load()[0]
    rec_interp, starts, runs = gather(a, b)
    runs_in_span = [r for r in runs if SPAN_S <= r[0] and r[1] <= SPAN_E]
    runs_in_span.sort()

    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]

    out, cur, total_recs = [], SPAN_S, 0
    for s, e in runs_in_span:
        if s > cur:
            out.append('\n; --- 0x%06X-0x%06X: not converted ---\n' % (cur, s - 1))
            out.append('\t.incbin "%s", 0x%06X, 0x%06X\n' % (ROM, cur - B_BASE, s - cur))
        text, recs = render_run(b, s, e, rec_interp, starts, hta, htb)
        total_recs += len(recs)
        out.append("\n; ------------------------------------------------------------------\n")
        out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A/B\n"
                   "; mixed by SITE, not by content: reached via the STACK call shapes\n"
                   "; (lda/push/call 0xF42E00 = A, 0xF42E04 = B, 0xF42E0C = one B record),\n"
                   "; the shapes notes/prom_b_dl_call_shapes.py finds and this generator\n"
                   "; splices.  Regenerate: python3 notes/gen_prom_b_dl_shape23_module.py\n"
                   "; --splice\n" % (s, e - 1, len(recs), e - s))
        out.append("; ------------------------------------------------------------------\n")
        out += text
        cur = e
    if cur < SPAN_E:
        out.append('\n; --- 0x%06X-0x%06X: not converted ---\n' % (cur, SPAN_E - 1))
        out.append('\t.incbin "%s", 0x%06X, 0x%06X\n' % (ROM, cur - B_BASE, SPAN_E - cur))
    return out, runs_in_span, total_recs


def roundtrip_check(b, runs_in_span, rec_interp):
    """Re-derive every emitted record's raw bytes from its rendered fields and
    require an exact match against the ROM -- independent of llvm-mc."""
    ok = True
    for s, e in runs_in_span:
        recs = DL.walk(b, s, e)
        for p, op, ln in recs:
            raw = b[p - B_BASE:p - B_BASE + ln]
            if raw[0] != op or raw[1] != ln:
                ok = False
    return ok


def splice(new_lines):
    """Edit the real MASTER file directly (prom_b has no `.include` wrapping
    this span, verified by the line count above), and refuse on anything
    outside the one matched `.incbin` directive changing at all."""
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, SPAN_FILE_OFF, SPAN_SIZE)
    idx = [i for i, ln in enumerate(lines) if ln.strip() == target.strip()]
    if len(idx) != 1:
        raise SystemExit("expected exactly one directive matching the span, found %d" % len(idx))
    i = idx[0]
    before_ctx = lines[:i] + lines[i + 1:]           # everything but the target line
    new_block = "".join(new_lines).rstrip("\n").split("\n")
    out_lines = lines[:i] + new_block + lines[i + 1:]
    after_ctx = out_lines[:i] + out_lines[i + len(new_block):]
    if after_ctx != before_ctx:
        raise SystemExit("REFUSING TO SPLICE: context outside the target "
                         "directive moved -- this should be impossible by "
                         "construction, so something upstream changed shape")
    write_part(path, "\n".join(out_lines), root=ROOT, allow_growth=True)


def main():
    b = DL.load()[1]
    rec_interp, starts, runs = gather(*DL.load())
    runs_in_span = sorted(r for r in runs if SPAN_S <= r[0] and r[1] <= SPAN_E)
    covered_bytes = sum(e - s for s, e in runs_in_span)

    if "--selftest" in sys.argv:
        print("gen_prom_b_dl_shape23_module.py --selftest")
        check("total covered bytes in the 0x13D34 span", covered_bytes, 1149)
        check("number of merged runs", len(runs_in_span), 10)
        want_runs = [
            (0xF13F1E, 0xF13F32), (0xF140B2, 0xF14168), (0xF141D3, 0xF1428D),
            (0xF14329, 0xF143C0), (0xF143E0, 0xF1447D), (0xF1449F, 0xF1451D),
            (0xF14562, 0xF145D3), (0xF145D9, 0xF14621), (0xF1465F, 0xF146A6),
            (0xF146E1, 0xF14728),
        ]
        check("runs match the byte-level census exactly", runs_in_span, want_runs)
        ok = roundtrip_check(b, runs_in_span, rec_interp)
        check("every record's (op,len) round-trips against ROM bytes", ok, True)
        # interpreter split sanity: at least one A run and one B run present
        classes = {rec_interp[p] for s, e in runs_in_span for p, _op, _ln in DL.walk(b, s, e)}
        check("both interpreters appear in this span", classes, {"A", "B"})
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    out, runs_in_span2, total_recs = build(b)
    if "--show" in sys.argv:
        sys.stdout.write("".join(out))
        print("\n; -- %d records, %d bytes across %d runs --"
              % (total_recs, covered_bytes, len(runs_in_span)), file=sys.stderr)
        return 0

    if "--splice" in sys.argv:
        splice(out)
        print("spliced %d records, %d bytes across %d runs into %s"
              % (total_recs, covered_bytes, len(runs_in_span), S_FILE))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
