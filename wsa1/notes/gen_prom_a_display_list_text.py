#!/usr/bin/env python3
"""Render prom_a's raw-byte display lists as interpreter-A records, with their text as `.ascii`.

QUESTION IT ANSWERS
  prom_a carries its own display lists (DisplayList_FXXXXX), most written as raw `.byte` rows ("Coverage
  only ... does not interpret the payload").  54 of them hold readable text -- the SYSTEM menu's
  "TUNE & SCALE", "C0NTR0LLER ASSIGN", ... -- which this tree's string-literal rule says must be
  `.ascii`, and which is what names a list (prom_b's DL_<text> labels, notes/prom_b_dl_screens_round5.py).
  A list is rendered here only when
    * every reference to it in prom_a runs it through interpreter A: the runner the code after the
      reference reaches within 16 lines -- following up to two `jr .L` hops, and for `jp (xix)` the
      `lda xix, (T_DisplayList...)` before it -- is T_DisplayList_Run or T_DisplayList_Run_Stack
      (interpreter B's handlers and field layout differ: notes/gen_prom_b_display_lists_v2.py);
    * its bytes, from the label to the next label, are `.byte` rows that equal the ROM and tile
      exactly as interpreter-A records (opcode < 0x24, length >= 2, the last record ends on the block's
      end), the walk scripts/analysis/prom_b_display_lists.py applies to prom_b;
    * at least one record is a text record (handler 0xF31A3A: a 16-bit screen position at +2, characters
      from +4; handler 0xF31A52: two words, characters from +6 -- interpreter A's table at prom_b
      0xF31D21) holding two adjacent letters.
  Each record becomes one `.byte op, len` row (with the screen row / column of a text record's position,
  40 bytes to a row), its operand words as `.short` / `.long`, its characters as `.ascii` (bytes below
  0x20, custom glyphs, stay `.byte`), and any byte the handler does not read as `.byte`.  Every row keeps
  its `; ADDR` comment.  The bytes do not change; make gate-all is the check.

RUN
  python3 notes/gen_prom_a_display_list_text.py            # which lists, and why the others are skipped
  python3 notes/gen_prom_a_display_list_text.py --apply    # rewrite prom_a/wsa1_prom_a.s
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
ROMA = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
ROMB = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE = 0xF80000
HTAB = [int.from_bytes(ROMB[0x31D21 + i * 4:0x31D25 + i * 4], "little") for i in range(36)]
# interpreter-A handler -> (operand fields (offset, width), text offset or None) -- prom_b_display_lists.HANDLERS
HANDLERS = {
    0xF31A3A: ([(2, 2)], 4),
    0xF31A52: ([(2, 2), (4, 2)], 6),
    0xF31A75: ([(2, 2), (4, 2), (6, 2), (8, 2)], None),
    0xF31A9F: ([(2, 2), (4, 2), (6, 2)], None),
    0xF31AAC: ([(2, 2), (4, 2)], None),
    0xF31ABE: ([(2, 4), (6, 2), (8, 2), (10, 2)], None),
    0xF31ACE: ([(2, 1), (3, 2)], None),
    0xF31AEB: ([], None),
}
RUN_A = ("T_DisplayList_Run", "T_DisplayList_Run_Stack")
RUN_B = ("T_DisplayListB_Run", "T_DisplayListB_Run_Stack", "T_DisplayListB_RunOne_Stack")


def blocks(L):
    """{label: (i_label, i_first_row, i_end, start, end)} for raw-.byte DisplayList_ blocks."""
    out = {}
    for i, l in enumerate(L):
        m = re.match(r'^(DisplayList_F[0-9A-F]{5}):\s*$', l)
        if not m:
            continue
        rows, j, start, nxt = [], i + 1, None, None
        while j < len(L) and not re.match(r'^[A-Za-z_.][\w$.]*:', L[j]) and not L[j].startswith(";"):
            mm = re.match(r'^\t\.byte\s+([0-9a-fx, ]+?)\s*;\s*(F[0-9A-F]{5})\s*$', L[j])
            if not mm:
                break
            bs = [int(x, 16) for x in re.findall(r'0x([0-9a-f]{2})', mm.group(1))]
            a = int(mm.group(2), 16)
            if start is None:
                start = a
            elif a != nxt:
                break
            nxt = a + len(bs)
            rows.append((a, bs))
            j += 1
        if not rows or (j < len(L) and L[j].strip() and not L[j].startswith(";")
                        and not re.match(r'^[A-Za-z_.][\w$.]*:', L[j])):
            continue
        out[m.group(1)] = (i, i + 1, j, start, nxt)
    return out


LOCALIDX = {}


def runner(L, i):
    """The interpreter the code after line i calls: follows up to two unconditional `jr .L` hops, and for
    `jp (xix)` / `call (xix)` the runner XIX was loaded with (`lda xix, (T_DisplayList...:24)` in the 30 lines
    before).  None if no runner is reached within 16 lines."""
    if not LOCALIDX:
        LOCALIDX.update({m.group(1): k for k, l in enumerate(L) for m in [re.match(r'^(\.L[0-9A-F]+):', l)] if m})
    hops, j, n = 0, i + 1, 0
    while n < 16 and j < len(L):
        code = L[j].split(";")[0]
        m = re.search(r'\bcall\s+(T_DisplayList\w*)', code)
        if m:
            return m.group(1)
        if re.search(r'\b(?:jp|call)\s+\(xix\)', code, re.I):
            for k in range(i, max(0, i - 30), -1):
                mm = re.search(r'\blda\s+xix,\s*\((T_DisplayList\w*):24\)|\bld\s+XIX,\s*(T_DisplayList\w*)', L[k].split(";")[0], re.I)
                if mm:
                    return mm.group(1) or mm.group(2)
            return None
        m = re.match(r'^\s*jrl?\s+(?:T,)?(\.L[0-9A-F]+)\s*$', code)
        if m and hops < 2 and m.group(1) in LOCALIDX:
            j, hops = LOCALIDX[m.group(1)] + 1, hops + 1
            continue
        j, n = j + 1, n + 1
    return None


def interpreter(L, name):
    kinds = set()
    for i, l in enumerate(L):
        code = l.split(";")[0]
        if not re.search(r'\b%s\b' % name, code) or re.match(r'^%s:' % name, l):
            continue
        r = runner(L, i)
        kinds.add("A" if r in RUN_A else "B" if r in RUN_B else "?")
    return kinds


def walk(s, e):
    recs, p = [], s
    while p < e:
        op, ln = ROMA[p - A_BASE], ROMA[p - A_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def row(text, addr):
    return "\t%-48s; %06X" % (text, addr)


def render(recs):
    out = []
    for p, op, ln in recs:
        raw = ROMA[p - A_BASE:p - A_BASE + ln]
        h = HTAB[op]
        fields, txt = HANDLERS.get(h, ([], None))
        note = ""
        if txt is not None and ln >= 4:
            pos = raw[2] | raw[3] << 8
            note = "  text at row %d, col %d" % (pos // 40, pos % 40)
        out.append(row(".byte 0x%02x, 0x%02x" % (op, ln), p) + "  op %02x, %d bytes -> handler 0x%06X%s" % (op, ln, h, note))
        used = 2
        for off, w in fields:
            if off + w > ln:
                break
            v = int.from_bytes(raw[off:off + w], "little")
            out.append(row("%s 0x%0*x" % ({1: ".byte", 2: ".short", 4: ".long"}[w], w * 2, v), p + off))
            used = max(used, off + w)
        if txt is not None and ln > txt:
            i = txt
            while i < ln:
                j = i
                if 0x20 <= raw[i] <= 0x7E:
                    while j < ln and 0x20 <= raw[j] <= 0x7E:
                        j += 1
                    out.append(row('.ascii "%s"' % esc(raw[i:j].decode("ascii")), p + i))
                else:
                    while j < ln and not (0x20 <= raw[j] <= 0x7E):
                        j += 1
                    out.append(row(".byte %s" % ", ".join("0x%02x" % c for c in raw[i:j]), p + i) + "  glyph codes below 0x20")
                i = j
            used = ln
        if used < ln:
            out.append(row(".byte %s" % ", ".join("0x%02x" % c for c in raw[used:ln]), p + used) + "  bytes the handler does not read")
    return out


def plan(L):
    done, skipped = [], []
    for name, (il, i0, i1, s, e) in sorted(blocks(L).items(), key=lambda kv: kv[1][3]):
        rows = L[i0:i1]
        bs = bytes(int(x, 16) for r in rows for x in re.findall(r'0x([0-9a-f]{2})', r.split(";")[0]))
        if bs != ROMA[s - A_BASE:e - A_BASE]:
            skipped.append((name, "rows differ from the ROM"))
            continue
        k = interpreter(L, name)
        if k != {"A"}:
            skipped.append((name, "run by %s" % (sorted(k) or "nothing found")))
            continue
        recs = walk(s, e)
        if recs is None:
            skipped.append((name, "does not tile as interpreter-A records"))
            continue
        texts = [ROMA[p - A_BASE + HANDLERS[HTAB[op]][1]:p - A_BASE + ln] for p, op, ln in recs
                 if HANDLERS.get(HTAB[op], ([], None))[1] is not None]
        if not any(re.search(rb'[A-Za-z]{2}', t) for t in texts):
            skipped.append((name, "no text record with two adjacent letters"))
            continue
        done.append((name, i0, i1, render(recs)))
    return done, skipped


def main():
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    done, skipped = plan(L)
    if "--apply" in sys.argv:
        for name, i0, i1, new in sorted(done, key=lambda d: -d[1]):
            L[i0:i1] = new
        data = "\n".join(L).encode("latin-1")         # encode BEFORE opening: a failed encode must not truncate
        with open(SRC + ".tmp", "wb") as fh:
            fh.write(data)
        os.replace(SRC + ".tmp", SRC)
    for name, _i0, _i1, new in done:
        print("RENDER %s (%d rows)" % (name, len(new)))
    for name, why in skipped:
        print("SKIP   %s: %s" % (name, why))
    print("rendered %d, skipped %d" % (len(done), len(skipped)))


if __name__ == "__main__":
    main()
