#!/usr/bin/env python3
r"""Name the seven value editors ScreenTable_F131E4 dispatches to, from their instruction bytes.

QUESTION THIS ANSWERS
    ScreenTable_F131E4 (32 code pointers) is indexed by an effect parameter's
    VALUE TYPE -- byte +1 of its EffectDesc_* group -- by sub_F1069A (`mul
    BC,H` by 4 / `add XBC,0xF131E4` / `jp (XBC)` at 0xF106FC-0xF1070E), which
    pushes (type, slot) first.  Its seven distinct targets were all
    `sub_XXXXXX`.  Each one reads EffectValueRanges[type] and steps one value
    of the current effect block (IndexedTable entry 97 + (0x2797)); what
    differs is the WIDTH and the FIELD it steps, and that is read here from
    the ROM bytes of each routine:

      sub_F1071B  8-bit unsigned: `ld L,(XIX)`, unsigned `cp L,C / jr C` / `jr UGT`
      sub_F107D0  8-bit SIGNED:   the same, compared with `jr LT` (61 xx) at 0xF10840
      sub_F10885  16-bit:         `ld IX,(XBC)` bounds (0xF108BB), `ld BC,(XIY)` value
      sub_F10985  bits 6..10 of a 16-bit word: `and BC,0x07C0 / srl 6,BC` (0xF109F3)
      sub_F10A97  bits 11..15:    `and BC,0xF800 / srl 11,BC` (0xF10B05)
      sub_F10BA9  bits 0..5:      `and L,0x3F` (0xF10C14)
      sub_F10CAF  a wrapper: pushes its own two arguments and `calr sub_F1071B`

    and which types each serves is read from the table itself.  Types 2/3
    (EMPHASIS Fc / BAND EMPHASIS Fc), 4 (Q) and 5 (G) are the PARAMETRIC EQ's
    fields, which is why the EQ's three groups per band share one slot: the
    band is one 16-bit word, G in bits 0-5 (0..48), Fc in 6-10 (1..26), Q in
    11-15 (0..31) -- the ranges EffectValueRanges gives those types.

RUN
    python3 notes/promb-2026-09-25/name_effect_editors.py            # checks
    python3 notes/promb-2026-09-25/name_effect_editors.py --apply    # rename + headers
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
TABLE = 0xF131E4
FAIL = []

EDITORS = {
    0xF1071B: ("DspEffect_StepU8", "an UNSIGNED 8-BIT value: `ld L,(XIX)` of the slot, "
               "the unsigned tests `cp L,C / jr C` (down) and `jr UGT` (up), `sub (XIX),H` / "
               "`add (XIX),H`"),
    0xF107D0: ("DspEffect_StepS8", "a SIGNED 8-BIT value: the same shape as DspEffect_StepU8 "
               "but the floor test is `jr LT` (61 04 at 0xF10840) -- PITCH L/R (-36..36) and "
               "FEEDBACK/RESONANCE (-99..99) are the types it serves"),
    0xF10885: ("DspEffect_StepU16", "a 16-BIT value: the bounds are read as words (`ld "
               "IX,(XBC)` at 0xF108BB) and the slot as a word (`ld BC,(XIY)` at 0xF108E8) -- "
               "the delay-time types, 0..350 / 500 / 700 ms"),
    0xF10985: ("DspEffect_StepEqFc", "BITS 6..10 of the 16-bit word at the slot: `and "
               "BC,0x07C0 / srl 6,BC` at 0xF109F3 -- a PARAMETRIC EQ band's Fc (1..26)"),
    0xF10A97: ("DspEffect_StepEqQ", "BITS 11..15 of the word: `and BC,0xF800 / srl 11,BC` at "
               "0xF10B05 -- a band's Q (0..31)"),
    0xF10BA9: ("DspEffect_StepEqGain", "BITS 0..5 of the word: `and L,0x3F` at 0xF10C14 -- a "
               "band's G (0..48, i.e. -12.0..+12.0 dB)"),
    0xF10CAF: ("DspEffect_StepSlowFast", "nothing itself: it re-pushes its two arguments and "
               "`calr DspEffect_StepU8`.  It serves type 0x0B alone, which only ROTARY "
               "SPEAKER's SLOW/FAST group carries (0..1)"),
}


# the two routines that drive the steppers: named with their own header text
DRIVERS = {
    0xF1069A: ("DspEffect_StepCursorValue", """; Name: DspEffect_StepCursorValue -- named 2026-09-25 (lane promb).
; Evidence: does nothing while the block is bypassed (IndexedTable_GetByte(23,
;          97 + (0x2797)) != 0 -- block byte 23, the flag EqGraph_Draw prints
;          "BYPASS" for); on cursor row 8 (`cp (0x2794),0x08` at 0xF106B7) it
;          calls DspEffect_StepAlgorithm (0xF10713); otherwise it takes group
;          (0x2792) + (0x2794) of the algorithm's EffectDesc_* record, pushes its
;          slot (+2) and type (+1) and jumps through ScreenTable_F131E4[type]
;          (0xF10700) to that type's stepper, DspEffect_StepU8 .. StepEqGain.
;          So the effect page is eight parameter lines (rows 0-7, scrolled by
;          (0x2792)) plus the algorithm line (row 8).
"""),
    0xF105B8: ("DspEffect_MoveCursor", """; Name: DspEffect_MoveCursor -- named 2026-09-25 (lane promb).
; Evidence: works on the cursor row at (0x2794) (`lda XIX,0x2794` at 0xF105BE)
;          and the scroll offset (0x2792), and does nothing while the block is
;          bypassed (IndexedTable_GetByte(23, 97 + (0x2797)) != 0).  With (0x28B0)
;          bit 0 SET it moves on: row 8 (the algorithm line) wraps to 0, rows
;          below 7 step down, row 7 scrolls (0x2792) -- but only while the next
;          EffectDesc_* group's slot (+2, read at 4*(row+scroll)+6) is not 0xFF,
;          and for block 99 ((0x2797) = 2) not onto slot 21, the byte that block
;          lacks; with the bit CLEAR it moves back -- nothing on row 8, the
;          scroll (0x2792) steps back at row 0, and row 8 is reached from the
;          top.  Then it sets (0x2075) bit 3 and (0x2095) bit 4.
"""),
}


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def main():
    rom = open(ROMB, "rb").read()
    at = lambda a, n: rom[a - BASE:a - BASE + n]
    tab = [int.from_bytes(at(TABLE + 4 * k, 4), "little") for k in range(32)]
    types = {}
    for k, t in enumerate(tab):
        types.setdefault(t, []).append(k)
    check("sub_F1069A indexes ScreenTable_F131E4 with 4*type and jumps: `add XBC,0x00F131E4` "
          "at 0xF10700 / `jp (XBC)` at 0xF1070E",
          at(0xF10700, 6).hex() == "e9c8e431f100" and at(0xF1070E, 2).hex() == "b1d8")
    check("the table's seven distinct non-default targets are exactly these seven routines",
          set(t for t in tab if t != 0xF42C70) == set(EDITORS))
    check("DspEffect_StepS8's floor test is `jr LT` (61 04 at 0xF10840)", at(0xF10840, 2).hex() == "6104")
    check("DspEffect_StepU16 reads word bounds and a word value (91 24 at 0xF108BB, 95 21 at "
          "0xF108E8)", at(0xF108BB, 2).hex() == "9124" and at(0xF108E8, 2).hex() == "9521")
    check("DspEffect_StepEqFc: `and BC,0x07C0 / srl 6,BC` (d9 cc c0 07 / d9 ef 06)",
          at(0xF109F3, 4).hex() == "d9ccc007" and at(0xF109F7, 3).hex() == "d9ef06")
    check("DspEffect_StepEqQ: `and BC,0xF800 / srl 11,BC` (d9 cc 00 f8 / d9 ef 0b)",
          at(0xF10B05, 4).hex() == "d9cc00f8" and at(0xF10B09, 3).hex() == "d9ef0b")
    check("DspEffect_StepEqGain: `and L,0x3F` (cf cc 3f)", at(0xF10C14, 3).hex() == "cfcc3f")
    check("DspEffect_StepSlowFast: `calr 0xF1071B` at 0xF10CBD",
          at(0xF10CBD, 1) == b"\x1e" and
          0xF10CC0 + int.from_bytes(at(0xF10CBE, 2), "little", signed=True) == 0xF1071B)
    check("DspEffect_MoveCursor: `lda XIX,0x2794` (f1 94 27 34) at 0xF105BE, `cp H,0xFF` "
          "(ce cf ff) at 0xF1061B", at(0xF105BE, 4).hex() == "f1942734" and
          at(0xF1061B, 3).hex() == "cecfff")
    check("DspEffect_StepCursorValue: `cp (0x2794),0x08` (c1 94 27 3f 08) at 0xF106B7 and "
          "`calr 0xF10476` at 0xF10713", at(0xF106B7, 5).hex() == "c194273f08" and
          at(0xF10713, 1) == b"\x1e" and
          0xF10716 + int.from_bytes(at(0xF10714, 2), "little", signed=True) == 0xF10476)
    for a, (n, _) in EDITORS.items():
        print("     %-24s types %s" % (n, ", ".join("0x%02X" % k for k in types.get(a, []))))
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(types)
    print("\nVERDICT: PASS")
    return 0


UNK = ("; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
       ";          per this tree's rule that a stated gap beats a plausible guess.\n")


def apply(types):
    import textwrap
    txt = open(SRC, "rb").read().decode("latin-1")
    for a, (name, what) in EDITORS.items():
        old = "sub_%06X" % a
        if not re.search(r'^%s:' % old, txt, re.M):
            continue
        m = re.search(r'%s(; -{74}\n%s:)' % (re.escape(UNK), old), txt)
        assert m, old
        body = ("Name: %s -- named 2026-09-25 (lane promb).  ScreenTable_F131E4 sends value "
                "type(s) %s here; sub_F1069A pushes (type, slot) first, so (XIZ+8) is the type "
                "and (XIZ+10) the slot of the current effect block (IndexedTable entry 97 + "
                "(0x2797)).  It steps %s.  The step is 1, or EffectValueRanges[type].step when "
                "(0x28B0) bit 2 is set; down when (0x28B0) bit 0 is set, else up; clamped to that "
                "record's [lower, upper].  A change is queued with T_Queue2C00_Append4 and bit 3 "
                "of (0x2075) set.  python3 notes/promb-2026-09-25/name_effect_editors.py checks "
                "the bytes quoted." % (name, ", ".join("0x%02X" % k for k in types[a]), what))
        lines = textwrap.wrap(body, width=76, initial_indent="; ", subsequent_indent=";          ",
                              break_long_words=False, break_on_hyphens=False)
        new = "\n".join(lines) + "\n" + (
            "; ⚠ CORRECTED 2026-09-25: this header used to end `Unknown: what the routine\n"
            ";          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's\n"
            ";          rule that a stated gap beats a plausible guess.`\n")
        txt = txt[:m.start()] + new.encode("utf-8").decode("latin-1") + m.group(1) + txt[m.end():]
        txt = re.sub(r'\b%s(\w*)\b' % old, lambda mm, name=name: name + mm.group(1), txt)
    for a, (name, hdr) in DRIVERS.items():
        old = "sub_%06X" % a
        if not re.search(r'^%s:' % old, txt, re.M):
            continue
        m = re.search(r'%s(; -{74}\n%s:)' % (re.escape(UNK), old), txt)
        assert m, old
        new = hdr + ("; \u26a0 CORRECTED 2026-09-25: this header used to end `Unknown: what the routine\n"
                     ";          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's\n"
                     ";          rule that a stated gap beats a plausible guess.`\n")
        txt = txt[:m.start()] + new.encode("utf-8").decode("latin-1") + m.group(1) + txt[m.end():]
        txt = re.sub(r'\b%s(\w*)\b' % old, lambda mm, name=name: name + mm.group(1), txt)
    txt = reparent(txt, [n for n, _ in EDITORS.values()] + [n for n, _ in DRIVERS.values()])
    data = txt.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


STRUCT = re.compile(r'^(?P<p>\w+?)_(?P<k>Skip|Join|Loop|Return|Epilogue|Entry|Helper|Resume)(?P<n>\d*)$')


def reparent(txt, names):
    """A structural label `<P>_<Kind>N` whose line lies inside a DIFFERENT routine than P (the
    branch symboliser parents to the last CALLED entry, so the editors' branch labels hang under
    whichever of them came first) is renamed into the routine that contains it."""
    L = txt.split("\n")
    starts = []                 # (line, routine) for every non-structural label
    for i, t in enumerate(L):
        m = re.match(r'^([A-Za-z_]\w*):', t)
        if m and not STRUCT.match(m.group(1)):
            starts.append((i, m.group(1)))
    existing = set(re.findall(r'^([A-Za-z_]\w*):', txt, re.M))
    ren = {}
    import bisect
    keys = [i for i, _ in starts]
    for i, t in enumerate(L):
        m = re.match(r'^([A-Za-z_]\w*):', t)
        if not m:
            continue
        sm = STRUCT.match(m.group(1))
        if not sm or sm.group("p") not in names:
            continue
        owner = starts[bisect.bisect_right(keys, i) - 1][1]
        if owner == sm.group("p") or owner not in names:
            continue
        k = 1
        while True:
            cand = "%s_%s%s" % (owner, sm.group("k"), "" if k == 1 else k)
            if cand not in existing:
                break
            k += 1
        existing.add(cand)
        ren[m.group(1)] = cand
    for o in sorted(ren, key=len, reverse=True):
        txt = re.sub(r'\b%s\b' % re.escape(o), ren[o], txt)
        print("  %-30s -> %s" % (o, ren[o]))
    return txt


if __name__ == "__main__":
    sys.exit(main())
