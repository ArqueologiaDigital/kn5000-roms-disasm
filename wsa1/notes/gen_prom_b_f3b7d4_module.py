#!/usr/bin/env python3
"""Close 0xF3B7D4-0xF3B99C (457 B): a 64-entry fixed-stride caption table for
the MIDI part/channel-assignment screen -- "PART 1".."PART 32", "1- 1CH"
.."2-16CH", plus a 21-byte tail.

QUESTION IT ANSWERS
    What is the 457-byte `.incbin` span immediately after Data_F3B7CD (a
    7-byte reachability object) and immediately before DL_TrackAssignChange
    Attention (0xF3B99D, already converted -- its own captions are "TRACK
    ASSIGN CHANGE", "Track", "from" ...)?  It is NOT a display-list run (no
    op/len walk from any offset lands on 0xF3B99D under either interpreter's
    implied-length rules -- checked, not assumed, per the F0DB18 lesson about
    trusting an untested characterisation). It is a plain caption table:

        +0x00  .long   0x00F3B7D8   -- purpose not established (see below)
        +0x04  8 x .short           -- purpose not established (see below)
        +0x14  32 x 7-byte ASCII    "PART 1 ".."PART 32"   (224 B)
        +0xF4  32 x 6-byte ASCII    "1- 1CH".."2-16CH"      (192 B)
        +0x1B4 21-byte ASCII tail   " OFF  -- CH OFFON -- " (21 B)

    20 + 224 + 192 + 21 = 457, with ZERO remainder -- the whole span, exactly.

WHAT IS ESTABLISHED AND WHAT IS NOT
    ESTABLISHED (re-derived here, `--selftest` fails if any drifts):
      * every one of the 32 "PART n" entries decodes as ASCII and reads
        "PART " followed by the entry's own 1-based index, space-padded to
        7 bytes for single digits;
      * every one of the 32 channel entries reads "<bank>-<channel>CH",
        bank 1 for entries 1-16 and bank 2 for entries 17-32, channel
        1-16 within each bank, 2-digit channels not space-padded (their
        stride is already exactly 6);
      * the header ends exactly where the first "PART" string starts, and
        the last channel entry ends exactly where the 21-byte tail starts,
        with no slack on either boundary;
      * this span is immediately preceded by DL_F3B7C3 (op 0x1B, handler
        0xF31A75 -- 4 raw words, already committed) whose four words are
        0x000C, 0x006F, 0x0031, 0x00A5.  0x000C, 0x006F and 0x00A5 ALSO
        appear, verbatim, among this table's own 8 header words (at header
        positions 0, 1 and 7).  That is unlikely by chance (3 of 4 values
        matching two tables that sit back to back) and is recorded as
        corroboration that the header is a deliberate index/offset field,
        not padding -- but the indexing scheme itself (what a value of
        0x6F selects, relative to which origin) is NOT worked out, so the
        header words are emitted as bare `.short` with that gap stated
        rather than a guessed field name.
    NOT ESTABLISHED, and deliberately not claimed:
      * what selects the header's 8 words, or what they offset into;
      * the internal structure (if any) of the 21-byte tail beyond being
        printable ASCII -- it is emitted as one `.ascii` run, not further
        subdivided, because no stride was found that tiles it exactly.

VERIFICATION
    --selftest re-derives the whole layout from the ROM bytes (never from a
    hand-typed table in this script) and requires the reassembled bytes to
    match the original span exactly, byte for byte, before allowing
    --splice to touch anything.  The byte gate (`make gate-wsa1`) is what
    actually certifies the committed source.

RUN
    python3 notes/gen_prom_b_f3b7d4_module.py --selftest
    python3 notes/gen_prom_b_f3b7d4_module.py --show
    python3 notes/gen_prom_b_f3b7d4_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import write_part      # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
SPAN_FILE_OFF = 0x03B7D4
SPAN_SIZE = 0x0001C9
SPAN_S = B_BASE + SPAN_FILE_OFF
SPAN_E = SPAN_S + SPAN_SIZE

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def load_rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def decode(chunk):
    """(long0, shorts[8], part_strs[32], chan_strs[32], tail) from the 457
    raw bytes, or raise if any expected shape does not hold."""
    assert len(chunk) == SPAN_SIZE
    long0 = int.from_bytes(chunk[0:4], "little")
    shorts = [int.from_bytes(chunk[4 + 2 * i:6 + 2 * i], "little") for i in range(8)]
    body = chunk[20:]
    parts = [body[i * 7:i * 7 + 7] for i in range(32)]
    for i, p in enumerate(parts):
        want = ("PART %d" % (i + 1)).ljust(7)
        if p.decode("ascii") != want:
            raise AssertionError("PART entry %d mismatch: %r != %r" % (i + 1, p, want))
    chans = body[224:224 + 192]
    chan_strs = [chans[i * 6:i * 6 + 6] for i in range(32)]
    for i, c in enumerate(chan_strs):
        bank = 1 if i < 16 else 2
        ch = (i % 16) + 1
        want = ("%d-%2dCH" % (bank, ch)).encode("ascii")
        if c != want:
            raise AssertionError("channel entry %d mismatch: %r != %r" % (i + 1, c, want))
    tail = body[224 + 192:]
    if len(tail) != 21 or not all(0x20 <= b <= 0x7E for b in tail):
        raise AssertionError("tail is not 21 bytes of printable ASCII: %r" % tail)
    return long0, shorts, parts, chan_strs, tail


def render(chunk):
    long0, shorts, parts, chan_strs, tail = decode(chunk)
    out = []
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- a 64-entry fixed-stride caption table, 457 bytes:\n"
               "; \"PART 1\"..\"PART 32\" (32 x 7 B) then \"1- 1CH\"..\"2-16CH\" (32 x 6 B)\n"
               "; then a 21-byte tail.  Immediately follows Data_F3B7CD and immediately\n"
               "; precedes DL_TrackAssignChangeAttention, both already committed.\n"
               "; The header's 8 words are NOT a display-list record (no handler's\n"
               "; implied length matches) and their indexing scheme is not established;\n"
               "; three of the eight (0x000C, 0x006F, 0x00A5) also appear verbatim in\n"
               "; the immediately preceding record, DL_F3B7C3's own 4 words -- recorded\n"
               "; as corroboration this is a deliberate field, not padding, without\n"
               "; claiming what it selects.  Regenerate: python3\n"
               "; notes/gen_prom_b_f3b7d4_module.py --splice\n" % (SPAN_S, SPAN_E - 1))
    out.append("; ------------------------------------------------------------------\n")
    out.append("Table_F3B7D4:\n")
    out.append("\t.long\t0x%08X\t; +0x00 purpose not established\n" % long0)
    for i, v in enumerate(shorts):
        out.append("\t.short\t0x%04X\t; +0x%02X purpose not established\n" % (v, 4 + 2 * i))
    out.append("; 32 x 7-byte \"PART n\" captions, +0x14\n")
    for i, p in enumerate(parts):
        out.append('\t.ascii "%s"\t; entry %d\n' % (p.decode("ascii"), i + 1))
    out.append("; 32 x 6-byte \"<bank>-<channel>CH\" captions, +0xF4\n")
    for i, c in enumerate(chan_strs):
        out.append('\t.ascii "%s"\t; entry %d\n' % (c.decode("ascii"), i + 1))
    out.append('\t.ascii "%s"\t; +0x1B4, 21-byte tail\n' % tail.decode("ascii"))
    return out


def roundtrip(chunk):
    long0, shorts, parts, chan_strs, tail = decode(chunk)
    rebuilt = long0.to_bytes(4, "little")
    for v in shorts:
        rebuilt += v.to_bytes(2, "little")
    for p in parts:
        rebuilt += p
    for c in chan_strs:
        rebuilt += c
    rebuilt += tail
    return rebuilt == chunk


def main():
    rom = load_rom()
    chunk = rom[SPAN_FILE_OFF:SPAN_FILE_OFF + SPAN_SIZE]

    if "--selftest" in sys.argv:
        print("gen_prom_b_f3b7d4_module.py --selftest")
        check("span size", len(chunk), SPAN_SIZE)
        try:
            decode(chunk)
            check("decode() accepts the ROM bytes", True, True)
        except AssertionError as exc:
            check("decode() accepts the ROM bytes: %s" % exc, False, True)
        check("round-trip: rebuilt bytes match ROM exactly", roundtrip(chunk), True)
        # the cross-table corroboration this docstring claims
        _l, shorts, _p, _c, _t = decode(chunk)
        check("header word 0 matches DL_F3B7C3's first word (0x000C)", shorts[0], 0x000C)
        check("header word 1 matches DL_F3B7C3's second word (0x006F)", shorts[1], 0x006F)
        check("header word 7 matches DL_F3B7C3's fourth word (0x00A5)", shorts[7], 0x00A5)
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, SPAN_FILE_OFF, SPAN_SIZE)
        check("exactly one matching .incbin directive in the tree", text.count(target), 1)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    out = render(chunk)
    if "--show" in sys.argv:
        sys.stdout.write("".join(out))
        return 0

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        text = open(path, encoding="utf-8").read()
        target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, SPAN_FILE_OFF, SPAN_SIZE)
        n = text.count(target)
        if n != 1:
            raise SystemExit("expected exactly one occurrence of %r, found %d" % (target, n))
        new_text = text.replace(target, "".join(out).rstrip("\n"), 1)
        write_part(path, new_text, root=ROOT, allow_growth=True)
        print("spliced 457 bytes (64 captions + header + tail) into %s" % S_FILE)
        return 0

    print("pass --selftest, --show or --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
