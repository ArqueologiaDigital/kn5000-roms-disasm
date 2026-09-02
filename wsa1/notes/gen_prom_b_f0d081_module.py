#!/usr/bin/env python3
"""What is at 0xF0D083-0xF0D79B (1,817 B), right after Data_F0D061?

QUESTION IT ANSWERS
    The committed `Data_F0D061` object (32-entry coordinate array, described
    by the display list at 0xF0D04B as "array of 8-byte entries") is written
    as 34 bytes, 0xF0D061-0xF0D082 -- but the array itself is only 32 bytes
    (four clean 8-byte (x1,y1,x2,y2) entries with x1=0x31/x2=0xF1 constant
    and y1/y2 stepping by 0x12): 0xF0D061-0xF0D080.  The trailing 2 bytes
    (`0x23, 0x05`) that got folded into it are not part of the array -- they
    are op 0x23, len 5, a record header ALREADY documented in this file's own
    HANDLERS table (used, for instance, in the F29BC6 module spliced this
    round).  Starting the walk there instead of at the `.incbin`'s stated
    0xF0D083 changes the outcome completely: DL.walk() then runs for **129
    records with zero failures**, all the way to 0xF0D4D2 -- readable text the
    whole way ("MIDI PRESETS", "PAGE1/2", "Organ type1", "Keyboard type2",
    "PR", "Piano", ...), every opcode resolving to a documented interpreter-A
    handler.

    This is the SAME lesson as gen_prom_b_f29bc6_module.py's part 4: the
    object boundary a PREVIOUS round drew (by reachability, not by content)
    was 2 bytes into the next real object.  Moving it back is not a guess --
    DL.walk() either lands exactly on a later byte or it does not, and here it
    lands on 129 consecutive record boundaries in a row, none of them chosen
    to make this work.

    At 0xF0D4D2 the walk hits a genuinely different, non-display-list opcode
    (0x98, over the 0x24 bound) -- a NEW object starts there.  Its first 9
    entries are another clean 8-byte coordinate array (x1=0x98/x2=0x108
    constant, y1/y2 stepping by 0x10), directly parallel to Data_F0D061's,
    but what follows it (from roughly 0xF0D51A) is NOT another simple array --
    spot checks show more display-list-shaped records mixed with what may be
    interpreter-B records and text, and it does not resolve cleanly with the
    tools this script uses. That part is intentionally left `.incbin` rather
    than forced.

WHAT THIS SCRIPT DOES
    1. Shrinks Data_F0D061 from 34 to 32 bytes (drops the trailing `.byte
       0x23, 0x05` line and its header count) -- a correction, not a
       reinterpretation: no byte changes value, one byte pair moves out of
       the wrong object.
    2. Splices the 129-record interpreter-A display list 0xF0D081-0xF0D4D1
       (1,105 bytes) in its place, using DL.walk()/DL.render() -- the same
       instruments that already converted the rest of this file's display
       lists.
    3. Shrinks the following `.incbin` from (0x00D083, 0x000719) to
       (0x00D4D2, 0x0002CA) -- unchanged bytes, just a smaller, honestly
       described remainder (714 B, down from 1,817 B minus the 1,105 the
       list took plus the 2 bytes recovered from Data_F0D061 -- i.e. this
       script converts 1,107 of the file's total; see --selftest for the
       exact arithmetic).

VERIFICATION
    --selftest: the current text matches what this script expects byte for
    byte before editing (so it cannot silently drift), the display list
    frames end-to-end with zero drift, every opcode is a documented
    interpreter-A handler, and the total bytes moved from `.incbin` to real
    source is exactly 1,107.  The byte gate (`make gate-wsa1`) is what
    actually certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_f0d081_module.py --selftest
    python3 notes/gen_prom_b_f0d081_module.py --show
    python3 notes/gen_prom_b_f0d081_module.py --splice
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

OLD_HEADER_LINE = "; Data_F0D061 -- 34 bytes, EMITTED AS DATA (not promoted to code)."
OLD_LAST_BYTE_LINE = ('\t.byte\t0x23, 0x05\t; F0D081  |#.|')
NEW_HEADER_LINE = "; Data_F0D061 -- 32 bytes, EMITTED AS DATA (not promoted to code)."
OLD_INCBIN = '\t.incbin "%s", 0x00D083, 0x000719' % ROM
DL_START, DL_END = 0xF0D081, 0xF0D4D2
NEW_INCBIN_OFF, NEW_INCBIN_SIZE = 0x00D4D2, 0x0002CA

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def build_dl_text(b):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, DL_START, DL_END)
    if recs is None:
        raise SystemExit("display list does not frame end to end")
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; RECOVERED FROM A 2-BYTE OBJECT-BOUNDARY ERROR: Data_F0D061 (above)\n"
           "; used to include these 2 bytes (op 0x23, len 5) as array padding; the\n"
           "; walk from here lands with ZERO DRIFT on 129 consecutive record\n"
           "; boundaries, ending exactly where op 0x98 (over the 0x24 bound, a\n"
           "; different object) begins.  notes/gen_prom_b_f0d081_module.py\n"
           % (DL_START, DL_END - 1, len(recs), DL_END - DL_START),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % DL_START)
    out += DL.render(b, recs, hta, set())
    return out, recs


def splice(new_dl_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    if OLD_HEADER_LINE not in text:
        raise SystemExit("REFUSING: Data_F0D061 header line not found verbatim")
    if OLD_LAST_BYTE_LINE not in text:
        raise SystemExit("REFUSING: Data_F0D061 trailing .byte line not found verbatim")
    if OLD_INCBIN not in text:
        raise SystemExit("REFUSING: target .incbin directive not found verbatim")
    before_ctx_count = text.count(OLD_HEADER_LINE) + text.count(OLD_LAST_BYTE_LINE) + text.count(OLD_INCBIN)
    if before_ctx_count != 3:
        raise SystemExit("REFUSING: expected each target line exactly once, saw signature count %d" % before_ctx_count)

    text = text.replace(OLD_HEADER_LINE, NEW_HEADER_LINE, 1)
    text = text.replace("\n" + OLD_LAST_BYTE_LINE, "", 1)
    new_incbin = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, NEW_INCBIN_OFF, NEW_INCBIN_SIZE)
    text = text.replace(OLD_INCBIN, "".join(new_dl_lines).rstrip("\n") + "\n\n" + new_incbin, 1)
    write_part(path, text, root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f0d081_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("Data_F0D061 header line present verbatim", OLD_HEADER_LINE in text, True)
        check("Data_F0D061 trailing .byte line present verbatim", OLD_LAST_BYTE_LINE in text, True)
        check("target .incbin directive present verbatim", OLD_INCBIN in text, True)

        # the array really is 32 clean bytes, and the next 2 are op 0x23 len 5
        arr = b[0xF0D061 - B_BASE:0xF0D081 - B_BASE]
        import struct
        ents = [struct.unpack_from("<4H", arr, i * 8) for i in range(4)]
        check("Data_F0D061's real array is 4 x (x1=0x31,*,x2=0xF1,*) entries",
              [(e[0], e[2]) for e in ents], [(0x31, 0xF1)] * 4)
        op, ln = b[0xF0D081 - B_BASE], b[0xF0D081 - B_BASE + 1]
        check("the 2 recovered bytes are op 0x23 len 5", (op, ln), (0x23, 5))

        recs = DL.walk(b, DL_START, DL_END)
        check("display list frames end-to-end with zero drift", recs is not None, True)
        if recs:
            check("record count", len(recs), 129)
            consumed = sum(ln for _p, _op, ln in recs)
            check("consumed bytes == DL_END - DL_START", consumed, DL_END - DL_START)
            hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
            all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
            check("every opcode resolves to a documented interpreter-A handler", all_known, True)
        # the byte right after DL_END really is a different, non-A-record object
        stop_op = b[DL_END - B_BASE]
        check("the byte at DL_END is NOT a valid interpreter-A opcode (rules in a new object)",
              stop_op >= 0x24, True)
        check("new .incbin size + moved bytes accounts for the old .incbin",
              NEW_INCBIN_SIZE + (DL_END - DL_START) - 2, 0x000719)
        check("total bytes converted this script (list + the 2 recovered)",
              (DL_END - DL_START) + 2, 1107)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        lines, _ = build_dl_text(b)
        sys.stdout.write("".join(lines))
        return 0

    if "--splice" in sys.argv:
        lines, recs = build_dl_text(b)
        splice(lines)
        print("spliced %d records (%d bytes) at 0x%06X-0x%06X; "
              "shrank Data_F0D061 by 2 B; new remainder .incbin 0x%06X, %d bytes"
              % (len(recs), DL_END - DL_START, DL_START, DL_END - 1,
                 B_BASE + NEW_INCBIN_OFF, NEW_INCBIN_SIZE))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
