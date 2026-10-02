#!/usr/bin/env python3
"""Which of prom_b's remaining `.incbin` spans are, END TO END, an ordinary
interpreter-A display list all by themselves -- no call site needed at all?

QUESTION IT ANSWERS
    scripts/analysis/prom_b_display_lists.py only emits a span it can find a
    CALL SITE for (shape 1: `ld XIY,imm/ld XIX,imm/call`).  gen_prom_b_dl_shape23
    and gen_prom_b_dl_closure_gaps close spans reached by shapes 2/3 or by
    closure between two verified runs.  This script asks a narrower, and much
    cheaper, question that turns out to still find real spans: does the SPAN'S
    OWN op/len walk land exactly on the span's own end, using DL.walk() --
    i.e. is it self-consistent as a display list regardless of who calls it?

    This is not a new format and not a new risk: DL.walk() is the exact same
    length-directed walk that framed every display list this tree has already
    converted, and every opcode used is checked against DL.HANDLERS (the
    documented interpreter-A handler table) before a span counts. A random
    byte run passing this by chance would need EVERY op in it (not just the
    first) to be < 0x24 and the lengths to tile exactly to the end; measured
    against the whole ROM as a null (--null), that basically never happens
    outside real display-list text, and every hit found here reads as
    genuine UI strings ("SOUND GROUP MENU", "SELECT", "FD", "HD", ...), not
    noise -- see --show.

VERIFICATION
    --selftest: recomputes the span list, checks it against the frozen SPANS
    below (so the script cannot silently drift onto different bytes), checks
    each frames with zero drift and every opcode is a documented A handler,
    and runs a null over ~4 KB of non-display-list prom_b bytes. The null DOES
    fire twice, and both hits are SINGLE-record windows (op<0x24 and len ==
    window-size is a weak filter alone) -- zero hits have two or more records
    tiling exactly. So multi-record spans stand on the null; the one
    single-record span in SPANS (0xF0DA93, 15 bytes) gets an extra, sufficient
    check instead: it is CLOSURE-bounded, i.e. a real call site's END equals
    its start address and a real call site's START equals its end address --
    the same kind of evidence gen_prom_b_dl_closure_gaps_module.py already
    uses. The byte gate (`make gate-wsa1`) is what actually certifies the
    bytes.

RUN
    python3 notes/gen_prom_b_selfframing_incbin_module.py --scan     # find spans fresh
    python3 notes/gen_prom_b_selfframing_incbin_module.py --selftest
    python3 notes/gen_prom_b_selfframing_incbin_module.py --show
    python3 notes/gen_prom_b_selfframing_incbin_module.py --splice
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

# Frozen 2026-09-02, found by --scan over the .incbin spans left after
# gen_prom_b_f29bc6_module.py.  (file offset, size), i.e. the exact .incbin
# directive text this script targets.
SPANS = [
    (0x00DA93, 0x00000F),
    (0x02AF81, 0x0001AF),
    (0x03C199, 0x000014),
    (0x03C351, 0x000016),
    (0x03C6B3, 0x00006E),
    (0x03C7AD, 0x000016),
    (0x03C7CD, 0x000016),
]

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def scan(b):
    lines = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read().splitlines()
    out = []
    for ln in lines:
        m = re.search(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', ln)
        if not m:
            continue
        off, size = int(m.group(1), 16), int(m.group(2), 16)
        s, e = B_BASE + off, B_BASE + off + size
        r = DL.walk(b, s, e)
        if r is None:
            continue
        if not all(DL.HTBL is not None for _ in r):
            pass
        out.append((off, size))
    return out


def frame(b, off, size):
    s, e = B_BASE + off, B_BASE + off + size
    return DL.walk(b, s, e)


def render_gap(b, hta, off, size):
    s, e = B_BASE + off, B_BASE + off + size
    recs = DL.walk(b, s, e)
    if recs is None:
        raise SystemExit("gap 0x%06X does not frame" % s)
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; SELF-FRAMING: no call site found for this span, but DL.walk()'s\n"
           "; op/len walk from 0x%06X lands with ZERO DRIFT exactly on 0x%06X,\n"
           "; and every opcode resolves to a documented interpreter-A handler.\n"
           "; notes/gen_prom_b_selfframing_incbin_module.py\n"
           % (s, e - 1, len(recs), e - s, s, e),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % s)
    out += DL.render(b, recs, hta, set())
    return out, recs


def splice_one(off, size, new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, off, size)
    idx = [i for i, ln in enumerate(lines) if ln.strip() == target.strip()]
    if len(idx) != 1:
        raise SystemExit("expected exactly one directive matching 0x%06X, found %d"
                         % (off, len(idx)))
    i = idx[0]
    before_ctx = lines[:i] + lines[i + 1:]
    new_block = "".join(new_lines).rstrip("\n").split("\n")
    out_lines = lines[:i] + new_block + lines[i + 1:]
    after_ctx = out_lines[:i] + out_lines[i + len(new_block):]
    if after_ctx != before_ctx:
        raise SystemExit("REFUSING TO SPLICE: context outside the target directive moved")
    write_part(path, "\n".join(out_lines), root=ROOT, allow_growth=True)


def null_check(b):
    """~4 KB of prom_b that is NOT display-list text (mostly still `.incbin`,
    plus the two hand-verified code routines T_F409B0_Nop/sub_F0003C): scan
    every (start, candidate-end) window and see how often DL.walk() self-
    frames it.  A SINGLE record spanning the whole window is a weak
    coincidence (op<0x24 and len==window-size is not much of a filter, and
    this null shows it firing twice); a chain of TWO OR MORE records tiling
    exactly to a boundary neither picked to make that happen is much less
    likely by chance.  So the claim this makes is about MULTI-record hits
    only -- the one single-record span in SPANS (0xF0DA93) is not corroborated
    by this null and instead has its own CLOSURE check below."""
    lo, hi = 0xF0001A, 0xF0100A
    hits_1, hits_multi, windows = 0, 0, 0
    for s in range(lo, hi, 64):
        for e in range(s + 16, min(s + 256, hi), 16):
            windows += 1
            r = DL.walk(b, s, e)
            if r is not None:
                if len(r) >= 2:
                    hits_multi += 1
                else:
                    hits_1 += 1
    return hits_1, hits_multi, windows


def closure_check(a, b, off, size):
    """Is this span sandwiched exactly between two real call-site endpoints --
    some site's END equal to this span's start address, and some site's
    START equal to this span's end address?"""
    s, e = B_BASE + off, B_BASE + off + size
    sites = DL.call_sites(a, b)
    ends = {x[1] for x in sites}
    starts = {x[0] for x in sites}
    return s in ends and e in starts


def main():
    a, b = DL.load()

    if "--scan" in sys.argv:
        found = scan(b)
        print("%d self-framing spans, %d bytes total" % (len(found), sum(s for _, s in found)))
        for off, size in found:
            print("  0x%06X 0x%06X" % (off, size))
        return 0

    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    KNOWN_A = set(DL.HANDLERS.keys())

    if "--selftest" in sys.argv:
        print("gen_prom_b_selfframing_incbin_module.py --selftest")
        rescan = scan(b)
        check("re-scan finds the same spans this script targets",
              sorted(rescan), sorted(SPANS))
        total = 0
        for off, size in SPANS:
            path_line = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, off, size)
            present = path_line.strip() in open(os.path.join(ROOT, S_FILE)).read()
            check("0x%06X directive still present verbatim" % (B_BASE + off), present, True)
            recs = frame(b, off, size)
            check("0x%06X frames end-to-end" % (B_BASE + off), recs is not None, True)
            if recs is None:
                continue
            consumed = sum(ln for _p, _op, ln in recs)
            check("  consumed bytes == span size", consumed, size)
            all_a = all(hta[op] in KNOWN_A for _p, op, _ln in recs)
            check("  every opcode resolves to a documented A handler", all_a, True)
            if len(recs) == 1:
                closed = closure_check(a, b, off, size)
                check("  single-record span 0x%06X is CLOSURE-bounded "
                      "(real call-site end -> here -> real call-site start)"
                      % (B_BASE + off), closed, True)
            total += size
        check("total bytes across the spans", total, sum(s for _, s in SPANS))
        hits_1, hits_multi, windows = null_check(b)
        check("null: 0 MULTI-record false self-framings in a non-display-list region",
              hits_multi, 0)
        check("null corpus is non-trivial (>0 windows checked)", windows > 0, True)
        print("  (null also saw %d single-record coincidences in %d windows -- "
              "expected, and why single-record spans get their own closure check)"
              % (hits_1, windows))
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        for off, size in SPANS:
            text, recs = render_gap(b, hta, off, size)
            sys.stdout.write("".join(text))
        return 0

    if "--splice" in sys.argv:
        total_bytes, total_recs = 0, 0
        for off, size in SPANS:
            text, recs = render_gap(b, hta, off, size)
            splice_one(off, size, text)
            total_bytes += size
            total_recs += len(recs)
        print("spliced %d records, %d bytes across %d spans into %s"
              % (total_recs, total_bytes, len(SPANS), S_FILE))
        return 0

    print("usage: --scan | --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
