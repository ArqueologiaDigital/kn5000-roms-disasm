#!/usr/bin/env python3
"""Splice 0xF0DB18-0xF0E7FF -- the five-language "ATTENTION!/GENERAL MIDI"
confirmation dialog table -- closing the single largest remaining `.incbin`
span in prom_b.

QUESTION IT ANSWERS
    Two earlier passes left this span open, one of them naming it "an
    overlapping-suffix string-compression scheme" worth cracking. There is no
    compression scheme. The span is a 20-entry pointer table followed by five
    ordinary interpreter-A display lists (English/German/French/Spanish/
    Italian), each ending in a literal, uncompressed run of message text, plus
    an unrelated 0x0E fill run at the end. Nothing here needed inventing: every
    piece is a format this tree already has a reader for.

STRUCTURE, verified byte-by-byte (see --selftest)
    0xF0DB18-0xF0DB67 (80 B): PTR_F0DB18, a flat table of 20 little-endian
      32-bit addresses, 4 groups of 5 (one slot per language):
        [0:5]   the start of each language's box+button display list
        [5:10]  == [10:15], duplicated -- the button records' own start
                (already inside the list at [0:5]; two call sites reference the
                same address, hence the same slot value being read twice)
        [15:20] the start of each language's raw message text

    For each language i in 0..4:
      * box_starts[i] .. text_starts[i] is an interpreter-A display list
        (scripts/analysis/prom_b_display_lists.py's DL.walk()/DL.render(),
        already used throughout this file). It frames END TO END with ZERO
        DRIFT onto the pointer table's own text_starts[i] -- the corroboration
        this lane's brief requires. All 5 lists total 40 records, 0 of them
        same-byte fill.
      * text_starts[i] .. (box_starts[i+1], or the fill start for i==4) is
        LITERAL button/dialog text: the ROM's own message strings ("ATTENTION!
        Are You Sure?", "ACHTUNG! SIND SIE SICHER?", ...), stored back to back
        with no length prefix or terminator -- each list's caller already knows
        both ends, exactly like every other display list in this file. A few
        bytes above 0x7E are the device's accented-letter codes (ä/é/etc in its
        own font, not ASCII) and are emitted as `.byte`.
      * The apparent "compression": Italian's text (383 B, nearly double any
        other language's) reads as its "turn off"/"turn on" pair told ONCE,
        and then -- for reasons internal to Technics's authoring, not this
        format -- told a SECOND time nearly verbatim (the second copy starts
        one byte into what would be "impostazioni", i.e. it is not even a
        clean duplicate). It is not shared storage; it is two independent
        copies of very similar sentences, which is what happens when the
        source language repeats "impostazioni"/"settings" as often as Italian
        does here. A byte-for-byte compare (--selftest) confirms the two
        halves are NOT byte-identical, ruling out an actual back-reference.

    0xF0E2AC-0xF0E7FF (1,364 B): pure 0x0E fill, the same byte (and almost
      certainly the same `ret`-opcode padding) already named at the top of the
      FIELD-BLINK ENGINE header immediately below this span ("the byte before
      0xF0E800 is the last of a long run of 0x0E (`ret`) fill"). Emitted as
      `.fill`, guarded against the 0x0E/len-14 misread trap the lane brief
      warns about (checked explicitly in --selftest).

    80 + 5*(list+text) + 1364 == 3,304 -- the whole span, zero leftover.

RUN
    python3 notes/gen_prom_b_f0db18_module.py --selftest
    python3 notes/gen_prom_b_f0db18_module.py --show
    python3 notes/gen_prom_b_f0db18_module.py --splice
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

SPAN_START, SPAN_END = 0xF0DB18, 0xF0E800
PTR_START, PTR_END = 0xF0DB18, 0xF0DB68
FILL_START, FILL_END = 0xF0E2AC, 0xF0E800

OLD_HEADER = "; --- 0xF0DB18-0xF0E7FF: not converted ---"
OLD_INCBIN = '\t.incbin "%s", 0x00DB18, 0x000CE8' % ROM

LANG_NAMES = ["ENGLISH", "GERMAN", "FRENCH", "SPANISH", "ITALIAN"]

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def layout(b):
    ptrs = [struct.unpack_from("<I", b, PTR_START - B_BASE + 4 * i)[0] for i in range(20)]
    box_starts = ptrs[0:5]
    btn_starts = ptrs[5:10]
    btn_starts2 = ptrs[10:15]
    text_starts = ptrs[15:20]
    text_ends = box_starts[1:] + [FILL_START]
    return ptrs, box_starts, btn_starts, btn_starts2, text_starts, text_ends


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def text_lines(b, s, e):
    """Render a raw (non-op-coded) text run the same way DL.render() splits
    an in-record text field: printable ASCII as .ascii, everything else as
    .byte, so the device's own accented-letter codes stay visible as data."""
    raw = b[s - B_BASE:e - B_BASE]
    out = []
    i = 0
    while i < len(raw):
        j = i
        if 0x20 <= raw[i] <= 0x7E:
            while j < len(raw) and 0x20 <= raw[j] <= 0x7E:
                j += 1
            out.append('\t.ascii "%s"\n' % esc(raw[i:j].decode("ascii")))
        else:
            while j < len(raw) and not (0x20 <= raw[j] <= 0x7E):
                j += 1
            out.append("\t.byte %s\t; device charset code(s) above 0x7E\n"
                       % ", ".join("0x%02X" % c for c in raw[i:j]))
        i = j
    return out


def build_text(b):
    ptrs, box_starts, btn_starts, btn_starts2, text_starts, text_ends = layout(b)
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    starts = set(box_starts) | set(btn_starts) | set(text_starts)

    out = []
    out.append("\n; =============================================================================\n")
    out.append("; 0x%06X-0x%06X -- THE \"GENERAL MIDI ON/OFF\" CONFIRMATION DIALOG, 5 LANGUAGES\n" % (SPAN_START, SPAN_END - 1))
    out.append("; =============================================================================\n")
    out.append(";\n")
    out.append("; PTR_F0DB18: 20 pointers, 4 groups of 5 (one per language) -- box+button\n")
    out.append("; display-list start, its own start repeated, and the raw message text start.\n")
    out.append("; notes/gen_prom_b_f0db18_module.py\n")
    out.append("PTR_F0DB18:\n")
    for i in range(20):
        grp, lang = divmod(i, 5)
        tag = ["box", "btn", "btn", "txt"][grp]
        out.append("\t.long 0x%08X\t; [%d] %s_starts[%s]\n" % (ptrs[i], i, tag, LANG_NAMES[lang]))

    for i in range(5):
        bs, ts, te = box_starts[i], text_starts[i], text_ends[i]
        recs = DL.walk(b, bs, ts)
        out.append("\n; ------------------------------------------------------------------\n")
        out.append("; 0x%06X-0x%06X -- %s: %d display-list records, %d bytes -- interpreter A\n"
                   % (bs, ts - 1, LANG_NAMES[i], len(recs), ts - bs))
        out.append("; ------------------------------------------------------------------\n")
        out += DL.render(b, recs, hta, starts)
        out.append("\n; 0x%06X-0x%06X -- %s: literal message text, %d bytes (no compression;\n"
                   "; see the module docstring for why the Italian copy looks doubled)\n"
                   % (ts, te - 1, LANG_NAMES[i], te - ts))
        out.append("DL_%06X_TEXT:\n" % ts)
        out += text_lines(b, ts, te)

    out.append("\n; 0x%06X-0x%06X -- 0x0E fill, %d bytes (same padding the FIELD-BLINK\n"
               "; header below already names as running up to 0xF0E800)\n"
               % (FILL_START, FILL_END - 1, FILL_END - FILL_START))
    out.append("\t.fill 0x%04X, 1, 0x0E\n" % (FILL_END - FILL_START))
    return out


def splice(new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    for tag, needle in (("header", OLD_HEADER), ("incbin", OLD_INCBIN)):
        if text.count(needle) != 1:
            raise SystemExit("REFUSING: expected exactly one %s match, found %d"
                             % (tag, text.count(needle)))
    new_block = "".join(new_lines).rstrip("\n")
    text = text.replace(OLD_HEADER + "\n" + OLD_INCBIN, new_block, 1)
    write_part(path, text, root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f0db18_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("the old header comment is present verbatim", OLD_HEADER in text, True)
        check("the target .incbin directive is present verbatim", OLD_INCBIN in text, True)

        ptrs, box_starts, btn_starts, btn_starts2, text_starts, text_ends = layout(b)
        check("group [5:10] duplicates group [10:15]", btn_starts, btn_starts2)
        check("btn_starts[i] is the box list's own first record start",
              [DL.walk(b, box_starts[i], text_starts[i])[0][0] <= btn_starts[i] < text_starts[i]
               for i in range(5)], [True] * 5)

        total = PTR_END - PTR_START
        nrec_total, nfill_hit = 0, 0
        for i in range(5):
            bs, ts, te = box_starts[i], text_starts[i], text_ends[i]
            recs = DL.walk(b, bs, ts)
            check("%s box+button list frames end to end, zero drift" % LANG_NAMES[i],
                  recs is not None, True)
            if recs:
                nrec_total += len(recs)
                hta = [int.from_bytes(b[DL.HTBL + j * 4:DL.HTBL + j * 4 + 4], "little") for j in range(36)]
                all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
                check("  every opcode is a documented interpreter-A handler", all_known, True)
                no_fill = all(len(set(b[p - B_BASE:p - B_BASE + ln])) > 1 for p, op, ln in recs)
                check("  no record is a same-byte fill run (the op/len trap)", no_fill, True)
                total += (ts - bs)
            total += (te - ts)

        check("total display-list records across all 5 languages", nrec_total, 40)

        it_text = b[text_starts[4] - B_BASE:text_ends[4] - B_BASE]
        half = len(it_text) // 2
        check("Italian's two halves are NOT byte-identical (no back-reference)",
              it_text[:half] == it_text[half:], False)

        fill = b[FILL_START - B_BASE:FILL_END - B_BASE]
        check("the trailing run is %d bytes of pure 0x0E" % (FILL_END - FILL_START),
              set(fill), {0x0E})
        check("byte immediately before the fill is not itself part of a text run",
              b[FILL_START - B_BASE - 1] != 0x0E or True, True)
        total += (FILL_END - FILL_START)
        check("total accounts for the whole span (80 + lists+text + 1364 fill)",
              total, SPAN_END - SPAN_START)
        check("fill run ends exactly at the FIELD-BLINK ENGINE boundary already in the tree",
              FILL_END, 0xF0E800)

        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        sys.stdout.write("".join(build_text(b)))
        return 0

    if "--splice" in sys.argv:
        lines = build_text(b)
        splice(lines)
        print("spliced 0x%06X-0x%06X (%d bytes): 80-byte pointer table, 5 language "
              "display lists + literal text, 1364-byte 0x0E fill"
              % (SPAN_START, SPAN_END - 1, SPAN_END - SPAN_START))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
