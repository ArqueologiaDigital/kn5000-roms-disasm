#!/usr/bin/env python3
"""Close 6 MORE instances of the "oversized Data_Fxxxxxx object" defect,
all six found inside ONE COVER-R1 block: 0xF3B3B2-0xF3B7C3.

QUESTION IT ANSWERS
    That block already held DL_F3B3DA (closed by gen_prom_b_f3b3da_module.py,
    landing on Data_F3B5A9) and, past this fix's far end, an already-real
    DL_F3B7C3. Between those two lie SEVEN round-1 Data_Fxxxxxx objects, each
    immediately followed by its own tiny `.incbin`. Six of the seven are the
    same shape round 2 closed: the object's own declared bytes are the
    LEADING BYTES of a display list that reaches the NEXT Data_Fxxxxxx
    object's start (or, for the last one, DL_F3B7C3) with ZERO DRIFT:

        object       span               records  landing (already real)
        Data_F3B5A9  0xF3B5A9-0xF3B5D1  5        Data_F3B5D1
        Data_F3B5D1  0xF3B5D1-0xF3B611  8        Data_F3B611
        Data_F3B611  0xF3B611-0xF3B651  8        Data_F3B651 (itself untouched, see below)
        Data_F3B65B  0xF3B65B-0xF3B6D3  8        Data_F3B6D3
        Data_F3B6D3  0xF3B6D3-0xF3B74B  8        Data_F3B74B
        Data_F3B74B  0xF3B74B-0xF3B7C3  8        DL_F3B7C3, already real

    The SEVENTH, Data_F3B651 (0xF3B651-0xF3B65B, 10 B total), does NOT frame:
    its first declared byte pair is `op 0x00, len 0x0B` and 0x0B (11) exceeds
    the 10 bytes available. It is left exactly as committed -- untouched by
    this script, and still `.incbin` for its own 5 trailing bytes.

    All six sites are the SAME divider-delimited `Data_Fxxxxxx` comment shape
    round 2 used for its `wraps=False` cases (no per-object COVER-R1 markers
    of their own -- they all share the one enclosing 0xF3B3B2-0xF3B7C3 block,
    which also covers the untouched Data_F3B651 and is therefore left alone).

VERIFICATION
    --selftest: every OLD block is present verbatim (extracted from the live
    tree, never hand-transcribed -- see extract_old_block()), every walk
    frames end to end with zero drift, every opcode is a documented
    interpreter-A handler, no record is a same-byte run, and Data_F3B651 is
    confirmed to still NOT frame (so excluding it stays the right call if the
    tree changes). The byte gate (`make gate-wsa1`) is what actually
    certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_oversized_round3_module.py --selftest
    python3 notes/gen_prom_b_oversized_round3_module.py --splice
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


def extract_old_block(text, name):
    """The divider-delimited `Data_Fxxxxxx -- N bytes` comment plus its
    `.byte`/`.incbin` lines, pulled verbatim out of the CURRENT tree (never
    hand-transcribed)."""
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
    return "\n".join(lines[divider:j + 1])


# Each site: (name, start, end)
SITE_KEYS = [
    ("F3B5A9", 0xF3B5A9, 0xF3B5D1),
    ("F3B5D1", 0xF3B5D1, 0xF3B611),
    ("F3B611", 0xF3B611, 0xF3B651),
    ("F3B65B", 0xF3B65B, 0xF3B6D3),
    ("F3B6D3", 0xF3B6D3, 0xF3B74B),
    ("F3B74B", 0xF3B74B, 0xF3B7C3),
]

UNTOUCHED_NAME, UNTOUCHED_START, UNTOUCHED_END = "F3B651", 0xF3B651, 0xF3B65B


def build_dl_text(b, name, start, end):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, start, end)
    if recs is None:
        raise SystemExit("%s: display list does not frame end to end" % name)
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; Formerly Data_%s -- that was the LEADING BYTES of this list, not a\n"
           "; separate object.  Zero-drift walk, notes/gen_prom_b_oversized_round3_module.py\n"
           % (start, end - 1, len(recs), end - start, name),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % start)
    out += DL.render(b, recs, hta, set())
    return "".join(out).rstrip("\n"), recs


def splice_all(b):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    total_recs, total_bytes = 0, 0
    for name, start, end in SITE_KEYS:
        old = extract_old_block(text, name)
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
        print("gen_prom_b_oversized_round3_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
        for name, start, end in SITE_KEYS:
            old = extract_old_block(text, name)
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

        r = DL.walk(b, UNTOUCHED_START, UNTOUCHED_END)
        check("Data_F3B651 still correctly does NOT frame (left untouched)",
              r is None, True)

        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--splice" in sys.argv:
        nrec, nbytes = splice_all(b)
        print("spliced 6 sites: %d display-list records, %d bytes total; "
              "Data_F3B651 (10 B) left untouched, does not frame"
              % (nrec, nbytes))
        return 0

    print("usage: --selftest | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
