#!/usr/bin/env python3
"""FIX a misframe this same lane introduced: 0xF2B8F9-0xF2BA0B is one
interpreter-B string-table-readout record plus its OWN 65-entry, 4-byte
stride caption table -- not 122 bytes of "interpreter-A display-list
records" landing on a 275-byte-span end by coincidence.

WHAT WENT WRONG, AND HOW IT WAS FOUND
    gen_prom_b_untouched_pool_module.py's search only accepted a walk if it
    covered >= 2 consecutive interpreter-A/B header-shaped records reaching
    all the way to a span's declared end. Applied to 0xF2B8F9-0xF2BA0C
    (275 B), it found a start 153 bytes in (0xF2B992) that produced 3
    superficially valid op-0x20 "text" records and landed exactly on the
    span end -- because the caption table's own literal bytes (0x20 = ' ',
    then whatever numeral follows) happen to look like an op/len pair at
    that offset. Every length happened to satisfy op 0x20's ("min", 4)
    rule, which is WEAK for exactly this reason: op 0x20 accepts almost any
    length >= 4, so it does not corroborate its own start the way a FIXED
    rule does. That combination -- a "min" rule plus a coincidental start
    -- slipped past the check that caught the four OTHER false positives in
    that same round (which were all rejected because they used a FIXED-length
    handler with the wrong length). It reassembled byte-exact and passed
    the gate, exactly the kind of misframe the tree's own F0DB18 lesson and
    HD-AE5000 "data-as-code" finding warn is invisible to the gate.

    Re-reading the SAME 275 bytes from their true start (0xF2B8F9, not
    0xF2B992) finds: byte 0 is op 0x02, length 0x0F (15) -- a FIXED-15
    handler (0xF31B21, interpreter B, "string-table readout"), and its own
    +0x07 field is 0x00F2B908: the address of the very next byte, i.e. the
    record NAMES its own continuation. From there, (0xF2BA0C - 0xF2B908) =
    260 bytes divides EXACTLY by the record's own +0x0B stride field (4)
    into 65 entries -- "R1 :", "R2 :", ..., "M1 :", "M2 :", "M3 :", ...,
    "RD1:", "RD2:", ..., "UD1:", "UD2:", ..., "ED1:", then all-blank
    padding entries to 65. 15 + 260 = 275, the WHOLE original span, zero
    remainder -- a much stronger self-check than the false framing's
    "reaches the incbin boundary", because the boundary here comes from
    the record's OWN declared entry count and stride, not from where a
    human or a prior generator happened to draw the `.incbin` line.

VERIFICATION
    --selftest re-derives the record fields and all 65 entries from the ROM
    bytes (never hand-typed), requires the reassembled bytes to match the
    original 275-byte span exactly, and requires the OLD (wrong) text this
    script replaces to still be present verbatim before touching anything.
    The byte gate (`make gate-wsa1`) recertifies the whole image afterward,
    which is necessary here but was not sufficient to catch the original
    mistake -- see above.

RUN
    python3 notes/gen_prom_b_f2b8f9_fix_module.py --selftest
    python3 notes/gen_prom_b_f2b8f9_fix_module.py --show
    python3 notes/gen_prom_b_f2b8f9_fix_module.py --splice
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

SPAN_S = 0xF2B8F9
SPAN_E = 0xF2BA0C
REC_S = SPAN_S
TABLE_S = 0xF2B908       # REC_S + 15, and also the record's own +0x07 field
ENTRY_STRIDE = 4
N_ENTRIES = 65

# The exact OLD text this fix replaces, verbatim from the tree the
# untouched-pool round committed.  --selftest requires this to still be
# present, byte for byte, before --splice is allowed to touch anything.
OLD_TEXT = '''
; --- 0xF2B8F9-0xF2BA0B: not converted ---
\t
; --- 0xF2B8F9-0xF2B991: not converted -- decodes as neither interpreter's records and is not a uniform fill ---
\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02B8F9, 0x000099

; ------------------------------------------------------------------
; 0xF2B992-0xF2BA0B -- 3 display-list records, 122 bytes -- interpreter A
; NOT reached by any known call shape (reachability.py: prom_b has 0
; bytes with start evidence) and not named by any converted record's
; own table field either -- found because a plain op/len walk, starting
; 153 bytes into this span, lands with ZERO DRIFT exactly on the span's
; declared end, and every record's length satisfies ITS OWN handler's
; implied-length rule (notes/prom_b_dl_length_audit.py), not merely
; `op < bound`.  Regenerate: python3 notes/gen_prom_b_untouched_pool_module.py
; --splice
; ------------------------------------------------------------------
\t.byte 0x20, 0x3A\t; op 20, 58 bytes -> handler 0xF31A3A
\t.short 0x2020
\t.ascii " :   :   :   :   :UD1:UD2:   :   :   :   :   :   :ED1:"
\t.byte 0x20, 0x20\t; op 20, 32 bytes -> handler 0xF31A3A
\t.short 0x3A20
\t.ascii "   :   :   :   :   :   :   :"
\t.byte 0x20, 0x20\t; op 20, 32 bytes -> handler 0xF31A3A
\t.short 0x3A20
\t.ascii "   :   :   :   :   :   :   :"
'''

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def decode(b):
    op, ln = b[REC_S - B_BASE], b[REC_S - B_BASE + 1]
    raw = b[REC_S - B_BASE:REC_S - B_BASE + ln]
    xiy = int.from_bytes(raw[7:11], "little")
    bc = int.from_bytes(raw[11:13], "little")
    entries = [b[TABLE_S - B_BASE + i * ENTRY_STRIDE:TABLE_S - B_BASE + i * ENTRY_STRIDE + ENTRY_STRIDE]
              for i in range(N_ENTRIES)]
    return op, ln, xiy, bc, entries


def render(b, ta, tb):
    op, ln, xiy, bc, entries = decode(b)
    out = []
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- one interpreter-B string-table-readout record (op 0x02,\n"
               "; handler 0xF31B21) plus its OWN 65-entry, 4-byte-stride caption table --\n"
               "; NOT 3 interpreter-A records, which was this lane's own earlier misframe\n"
               "; (see this generator's docstring). The record's +0x07 field names\n"
               "; 0x%06X, the address of the very next byte, and 65 entries of the\n"
               "; record's own +0x0B stride (%d) exactly fill the rest of this span with\n"
               "; zero remainder: 15 + %d*%d = %d, the whole original span.\n"
               "; Regenerate: python3 notes/gen_prom_b_f2b8f9_fix_module.py --splice\n"
               % (SPAN_S, SPAN_E - 1, xiy, bc, N_ENTRIES, ENTRY_STRIDE, 15 + N_ENTRIES * ENTRY_STRIDE))
    out.append("; ------------------------------------------------------------------\n")
    out += DLV2.render_b(b, REC_S, op, ln, tb)
    out.append("; 65 x 4-byte entries, +0x00 of the string table above\n")
    for i, ent in enumerate(entries):
        txt = "".join(chr(c) if 0x20 <= c <= 0x7E else "\\x%02X" % c for c in ent)
        out.append('\t.ascii "%s"\t; entry %d\n' % (txt, i))
    return out


def roundtrip(b):
    op, ln, xiy, bc, entries = decode(b)
    raw_rec = b[REC_S - B_BASE:REC_S - B_BASE + ln]
    rebuilt = raw_rec + b"".join(entries)
    orig = b[SPAN_S - B_BASE:SPAN_E - B_BASE]
    return rebuilt == orig


def main():
    a, b = DL.load()
    ta, tb = LA.tables(b)

    if "--selftest" in sys.argv:
        print("gen_prom_b_f2b8f9_fix_module.py --selftest")
        op, ln, xiy, bc, entries = decode(b)
        check("record op", op, 0x02)
        check("record length (fixed-15 handler)", ln, 15)
        check("handler is the interpreter-B string-table readout", tb[op], 0xF31B21)
        check("+0x07 field names the very next byte", xiy, TABLE_S)
        check("+0x0B stride", bc, ENTRY_STRIDE)
        check("15 + 65*4 == whole span", 15 + N_ENTRIES * ENTRY_STRIDE, SPAN_E - SPAN_S)
        check("round-trip: rebuilt bytes match ROM exactly", roundtrip(b), True)
        check("first 6 entries read the routing labels", [e.decode("ascii") for e in entries[:6]],
              ["R1 :", "R2 :", "   :", "   :", "   :", "   :"])
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("the OLD (misframed) text is present verbatim, exactly once",
              text.count(OLD_TEXT), 1)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    out = render(b, ta, tb)
    if "--show" in sys.argv:
        sys.stdout.write("".join(out))
        return 0

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        text = open(path, encoding="utf-8").read()
        n = text.count(OLD_TEXT)
        if n != 1:
            raise SystemExit("expected exactly one occurrence of the old misframed text, found %d" % n)
        new_text = text.replace(OLD_TEXT, "".join(out), 1)
        write_part(path, new_text, root=ROOT, allow_growth=True)
        print("fixed 0xF2B8F9-0xF2BA0B: replaced 3 fake A-records with 1 real B-record + 65 table entries")
        return 0

    print("pass --selftest, --show or --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
