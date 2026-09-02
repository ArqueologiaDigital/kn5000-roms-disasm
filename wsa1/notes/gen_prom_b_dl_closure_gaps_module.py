#!/usr/bin/env python3
"""Splice the three prom_b `.incbin` gaps that frame end-to-end BETWEEN two
already-converted display-list runs -- found while closing the shape-2/3 span.

QUESTION IT ANSWERS
    After notes/gen_prom_b_dl_shape23_module.py spliced the shape-2/3 records
    into 0xF13D34-0xF147AB, three `.incbin` gaps remained between the new
    record groups: 0xF13F32-0xF140B1 (384 B), 0xF14168-0xF141D2 (107 B), and
    0xF1428D-0xF143CF (156 B) [.incbin sizes 0x180/0x6B/0x9C].  None of them is
    named by any known call shape (1, 2 or 3) -- but a PLAIN op/len walk
    (op < 0x24, length at +1, self-checking, the same rule the whole display-
    list format rests on) run from the exact byte where the PRECEDING verified
    run ends lands, with ZERO DRIFT, exactly on the exact byte where the
    FOLLOWING verified run begins.  Both endpoints are independently
    established (one by a real call site, the other by a real call site), so a
    walk that starts at one and lands exactly on the other without a single
    byte of slack is the same "closure" evidence this tree already treats as
    proof elsewhere (e.g. gen_prom_b_cover_round1.py's CLOSURE checks) -- not a
    coincidence of a generic decoder wandering through unrelated data.

WHY INTERPRETER A, NOT B, AND NOT A GUESS
    Every record in these three gaps decodes to a KNOWN, ALREADY-DOCUMENTED
    interpreter-A handler (table 0xF31D21) -- see --show-evidence.  Several
    records use opcodes 0x11, 0x17, 0x1B, 0x20, 0x22, all >= interpreter B's
    own bound of 0x0F, so interpreter B's runner (0xF31AF0, which masks/rejects
    anything >= 0x0F) could not have executed them: the opcode range itself
    rules B out, not a judgement call.  The runs immediately either side of
    each gap are also interpreter A (their shape-2 sites call 0xF42E00 =
    STACK_A), so the gap is the middle of a single interpreter-A list whose
    call sites only ever named PART of it.

VERIFICATION
    --selftest checks: the three gaps still have the exact (offset, size) this
    script expects (so it cannot silently drift onto the wrong bytes), the
    walk from each gap's start frames EXACTLY to its end with zero remainder,
    and every opcode used resolves to a documented interpreter-A handler.
    The byte gate (`make gate-wsa1`) is what actually certifies the bytes.

RUN
    python3 notes/gen_prom_b_dl_closure_gaps_module.py --selftest
    python3 notes/gen_prom_b_dl_closure_gaps_module.py --show
    python3 notes/gen_prom_b_dl_closure_gaps_module.py --splice
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
ROM = "original_ROMs/wsa1_prom_b.ic13"

# (file offset, size) of the three gaps, read verbatim off the committed
# `.incbin` directives left by gen_prom_b_dl_shape23_module.py --splice.
GAPS = [
    (0x013F32, 0x000180),
    (0x014168, 0x00006B),
    (0x01428D, 0x00009C),
]

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


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
           "; NOT reached by any known call shape (1/2/3): found because the plain\n"
           "; op/len walk from the end of the verified run before it lands, with\n"
           "; ZERO DRIFT, exactly on the start of the verified run after it, and\n"
           "; every opcode used resolves to a documented interpreter-A handler --\n"
           "; several (0x11/0x17/0x1B/0x20/0x22) exceed interpreter B's 0x0F bound,\n"
           "; which rules B out by construction, not by guess.  This is the middle\n"
           "; of one interpreter-A list whose known call sites only named its ends.\n"
           "; Regenerate: python3 notes/gen_prom_b_dl_closure_gaps_module.py --splice\n"
           % (s, e - 1, len(recs), size),
           "; ------------------------------------------------------------------\n"]
    for p, op, ln in recs:
        out.append("DL_%06X:\n" % p)
        out += DL.render(b, [(p, op, ln)], hta, set())
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


def main():
    a, b = DL.load()
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    KNOWN_A = set(DL.HANDLERS.keys())

    if "--selftest" in sys.argv:
        print("gen_prom_b_dl_closure_gaps_module.py --selftest")
        check("three gaps declared", len(GAPS), 3)
        total = 0
        for off, size in GAPS:
            path_line = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, off, size)
            present = path_line.strip() in open(os.path.join(ROOT, S_FILE)).read()
            check("0x%06X directive still present verbatim" % (B_BASE + off), present, True)
            recs = frame(b, off, size)
            check("0x%06X frames end-to-end" % (B_BASE + off), recs is not None, True)
            if recs is None:
                continue
            consumed = sum(ln for _p, _op, ln in recs)
            check("  consumed bytes == gap size", consumed, size)
            all_a = all(hta[op] in KNOWN_A for _p, op, _ln in recs)
            check("  every opcode resolves to a documented A handler", all_a, True)
            b_impossible = any(op >= 0x0F for _p, op, _ln in recs)
            check("  at least one opcode exceeds interpreter B's bound (rules out B)",
                  b_impossible, True)
            total += size
        check("total bytes across the three gaps", total, 0x180 + 0x6B + 0x9C)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        for off, size in GAPS:
            text, recs = render_gap(b, hta, off, size)
            sys.stdout.write("".join(text))
        return 0

    if "--splice" in sys.argv:
        total_bytes, total_recs = 0, 0
        for off, size in GAPS:
            text, recs = render_gap(b, hta, off, size)
            splice_one(off, size, text)
            total_bytes += size
            total_recs += len(recs)
        print("spliced %d records, %d bytes across %d gaps into %s"
              % (total_recs, total_bytes, len(GAPS), S_FILE))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
