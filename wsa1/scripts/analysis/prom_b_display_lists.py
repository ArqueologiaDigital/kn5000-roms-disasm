#!/usr/bin/env python3
"""Emit prom_b's UI DISPLAY LISTS as assembly, and prove the record framing first.

QUESTION ANSWERED
  Where is the WSA1's UI text, and what is the structure it sits inside?

  It is not a string table.  It is a byte-coded DISPLAY LIST, run by the
  interpreter at 0xF31A09 (reached through thunk T_F417F0, the most-referenced
  slot in the whole image).  A list is a sequence of records:

      +0  opcode   (< 0x24; the interpreter bounds-checks it)
      +1  length   of the WHOLE record, in bytes
      +2  operands, and for the text opcodes a run of characters

  The interpreter advances by the length byte, so the framing is self-checking.

WHAT MAKES THE DECODE CHECKABLE, RATHER THAN A STORY
  1. Call sites pass BOTH ends: `ld XIY,<start>` / `ld XIX,<end>` / `call
     0xF417F0`.  Walking the length bytes from <start> must land EXACTLY on
     <end>.  Across the prom_b lists this holds for 243 of 244.
  2. The per-opcode handler table at 0xF31D21 (36 entries -- exactly the 0x24
     bound) says how many operand bytes each opcode has.  Every opcode whose
     handler reads a FIXED number of operands has exactly the matching length
     byte, in all ~4,400 records, with zero exceptions.
  3. The opcode is ALSO the `swi 7` function number: handler 0xF31A3A does
     `ld A,(XIY)` and then `swi 7`.  The SWI7 vector (prom_a 0xFFFF1C) reaches
     0xF8E9A5, which masks A with 0x3F and indexes a 64-entry table at 0xF8E9C6;
     entries 0x00-0x22 are real handlers and 0x23-0x3F are all the same bare
     `ret` at 0xF8EAC6.  The display-list bound 0x24 and the service table's
     live range 0x00-0x22 agree.

  Only spans that survive check 1 are emitted as records here.  Spans that fail
  are left as .incbin and named in the summary; four of the five failures are
  lists belonging to the OTHER interpreter (0xF31AF0, bound 0x0F, table
  0xF31DB1), whose record layout has not been worked out.

CHARACTER SET
  Payload bytes >= 0x20 are ASCII.  Bytes < 0x20 also occur inside payloads
  (0x10, 0x11, 0x12 ...); they are emitted as .byte and are almost certainly
  custom glyphs in the same font -- but that is NOT established here, only that
  they sit inside a payload the text handler passes to the character service.

RUN
  python3 scripts/analysis/prom_b_display_lists.py --summary
  python3 scripts/analysis/prom_b_display_lists.py --asm > /tmp/dl.s
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B_BASE, A_BASE = 0xF00000, 0xF80000
RUN_A, RUN_B = 0xF417F0, 0xF417F4          # the two interpreter thunks
HTBL = 0x31D21                              # file offset of the 36-entry table

# handler -> (list of (offset, width) operand fields, text offset or None)
HANDLERS = {
    0xF31A3A: ([(2, 2)], 4),                       # IX; then characters
    0xF31A52: ([(2, 2), (4, 2)], 6),               # ->(0x2530),(0x2532); characters
    0xF31A75: ([(2, 2), (4, 2), (6, 2), (8, 2)], None),   # ->(0x2530..0x2536)
    0xF31A9F: ([(2, 2), (4, 2), (6, 2)], None),    # IY, BC, HL
    0xF31AAC: ([(2, 2), (4, 2)], None),            # ->(0x2530),(0x2532)
    0xF31ABE: ([(2, 4), (6, 2), (8, 2), (10, 2)], None),  # XIY ptr, IX, BC, HL
    0xF31ACE: ([(2, 1), (3, 2)], None),            # glyph index, IX
    0xF31AEB: ([], None),                          # `ret` -- record ignored
}


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


def call_sites(a, b):
    """(start, end, which_interpreter) from `ld XIY,imm32 / ld XIX,imm32 / call`."""
    out = set()
    for img in (a, b):
        for o in range(len(img) - 24):
            if (img[o] == 0x45 and img[o + 4] == 0x00 and img[o + 5] == 0x44
                    and img[o + 9] == 0x00 and img[o + 10] == 0x1D):
                t = img[o + 11] | img[o + 12] << 8 | img[o + 13] << 16
                if t in (RUN_A, RUN_B):
                    s = img[o + 1] | img[o + 2] << 8 | img[o + 3] << 16
                    e = img[o + 6] | img[o + 7] << 8 | img[o + 8] << 16
                    if e > s:
                        out.add((s, e, t))
    return out


def spans(sites):
    iv = sorted((s, e) for s, e, t in sites if B_BASE <= s < A_BASE)
    m = []
    for s, e in iv:
        if m and s <= m[-1][1]:
            m[-1][1] = max(m[-1][1], e)
        else:
            m.append([s, e])
    return [tuple(x) for x in m]


def walk(b, s, e):
    """Records in [s,e), or None if the length bytes do not land exactly on e."""
    recs, p = [], s
    while p < e:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def render(b, recs, htab, starts):
    out = []
    for p, op, ln in recs:
        raw = b[p - B_BASE:p - B_BASE + ln]
        h = htab[op]
        fields, txt = HANDLERS.get(h, ([], None))
        if p in starts:
            out.append("DL_%06X:\n" % p)
        out.append("\t.byte 0x%02X, 0x%02X\t; op %02X, %d bytes -> handler 0x%06X\n"
                   % (op, ln, op, ln, h))
        used = 2
        for off, w in fields:
            if off + w > ln:
                break
            v = int.from_bytes(raw[off:off + w], "little")
            out.append("\t%s 0x%0*X\n" % ({1: ".byte", 2: ".short", 4: ".long"}[w], w * 2, v))
            used = max(used, off + w)
        if txt is not None and ln > txt:
            used = max(used, txt)
            i = txt
            while i < ln:
                j = i
                if 0x20 <= raw[i] <= 0x7E:
                    while j < ln and 0x20 <= raw[j] <= 0x7E:
                        j += 1
                    out.append('\t.ascii "%s"\n' % esc(raw[i:j].decode("ascii")))
                else:
                    while j < ln and not (0x20 <= raw[j] <= 0x7E):
                        j += 1
                    out.append("\t.byte %s\t; character codes below 0x20\n"
                               % ", ".join("0x%02X" % c for c in raw[i:j]))
                i = j
            used = ln
        if used < ln:
            out.append("\t.byte %s\t; operand bytes the handler does not read\n"
                       % ", ".join("0x%02X" % c for c in raw[used:ln]))
    return out


def main():
    a, b = load()
    sites = call_sites(a, b)
    htab = [int.from_bytes(b[HTBL + i * 4:HTBL + i * 4 + 4], "little") for i in range(36)]
    starts = {s for s, e, t in sites}
    sp = spans(sites)
    ok, bad, nrec, nbytes = [], [], 0, 0
    for s, e in sp:
        r = walk(b, s, e)
        if r:
            ok.append((s, e, r))
            nrec += len(r)
            nbytes += e - s
        else:
            bad.append((s, e))

    if "--asm" not in sys.argv:
        print("display-list call sites: %d  (%d via 0xF417F0, %d via 0xF417F4)"
              % (len(sites), sum(1 for x in sites if x[2] == RUN_A),
                 sum(1 for x in sites if x[2] == RUN_B)))
        print("prom_b spans: %d framed OK (%d records, %d bytes), %d NOT framed"
              % (len(ok), nrec, nbytes, len(bad)))
        for s, e in bad:
            print("   not framed: 0x%06X-0x%06X" % (s, e))
        return 0

    def opt(flag, dflt):
        return int(sys.argv[sys.argv.index(flag) + 1], 0) if flag in sys.argv else dflt
    lo, hi = opt("--lo", 0x00000), opt("--hi", 0x80000)
    out, cur = [], lo
    for s, e, r in ok:
        fs, fe = s - B_BASE, e - B_BASE
        if fs < lo or fe > hi:
            continue
        if fs > cur:
            out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (B_BASE + cur, B_BASE + fs - 1))
            out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n' % (cur, fs - cur))
        ends = sorted({x[1] for x in sites if s <= x[0] < e})
        out.append("\n; ------------------------------------------------------------------\n")
        out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes\n" % (s, e - 1, len(r), e - s))
        out.append(";   entered at: %s\n" % ", ".join("0x%06X" % x for x in sorted({y[0] for y in sites if s <= y[0] < e})))
        out.append(";   ends used:  %s\n" % ", ".join("0x%06X" % x for x in ends))
        out.append("; ------------------------------------------------------------------\n")
        out += render(b, r, htab, starts)
        cur = fe
    if cur < hi:
        out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (B_BASE + cur, B_BASE + hi - 1))
        out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n' % (cur, hi - cur))
    sys.stdout.write("".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
