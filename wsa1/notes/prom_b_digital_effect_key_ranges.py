#!/usr/bin/env python3
"""Name the switch arms of the SOUND EDIT DIGITAL EFFECT soft keys by the range each one gives the edited field.

QUESTION IT ANSWERS
  Seven of the eight SoftKeyColN_SoundEditDigitalEffect handlers (prom_b 0xF0ADD4-0xF0B3xx) read
      Arr27A6_Get(0) & 0x0F                      -- the DIGITAL EFFECT type: SoundEditDigitalEffect_Paint
                                                    keeps the same nibble in (0x27B6) and indexes the
                                                    page's label and value lists by it
      Arr27A6_Get(N)                             -- the packed byte of field N, into an edit descriptor at XIX
  and then `cp BC,<n> / jrl UGT / sll 2,BC / add XBC,<table> / ld XBC,(XBC) / jp (XBC)` on the type.  Every arm
  writes the descriptor's MAX (`ld (XIX+8),n`) and MIN (`ld (XIX+9),n`), directly or at a shared join, and then
  falls into the common tail that calls ToneEdit_CommitField.  notes/FINDINGS-l7a1429-field-editors.md section 1
  gives the descriptor: D[8] = MAX, D[9] = MIN, and a MIN with bit 7 set selects the SIGNED stepping worker.
  So each arm is fully described by the range it sets, and it is named for it:
      <handler>_Range<min>To<max>          (a negative bound spelled M<n>: MIN 0xCE -> M50)
  and the table <handler>_RangeByType.  An arm whose first instruction is `pop XIX` goes straight to the
  handler's epilogue -- that type has no field on that key -- and is <handler>_NoFieldForType.
  The range is read by walking the source from the arm's label: `ld (xix+8),n` / `ld (xix+9),n` are recorded,
  `jr`/`jrl` to a label continues there, labels in between are passed, and the walk stops at `push xix`.
  REFUSED: a walk that meets any other instruction, misses MIN or MAX, or two arms of one table with one range.

RUN
  python3 notes/prom_b_digital_effect_key_ranges.py          # the plan, with each table's type -> range map
  python3 notes/prom_b_digital_effect_key_ranges.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
L = B.split("\n")
G = re.compile(r'^([A-Za-z_][\w$]*):')
IDX = {G.match(l).group(1): i for i, l in enumerate(L) if G.match(l)}
HANDLER = re.compile(r'^SoftKeyCol\d_SoundEditDigitalEffect$')


def code(i):
    return re.sub(r'\s+', ' ', L[i].split(";")[0]).strip()


def handler_of(i):
    """The SoftKeyColN_SoundEditDigitalEffect whose body holds line i (sub_ arms and locals are passed)."""
    while i >= 0:
        m = G.match(L[i])
        if m and not m.group(1).startswith("sub_") and not re.search(r'_(Skip|Join|Loop|Resume)\d*$', m.group(1)):
            return m.group(1)
        i -= 1
    return None


def tables():
    out = []
    for i, l in enumerate(L):
        m = re.match(r'^\s*add\s+xbc, (\w+)\s*;', l)
        if not m or m.group(1) not in IDX:
            continue
        h = handler_of(i)
        if not h or not HANDLER.match(h):
            continue
        # the index is the type nibble: Arr27A6_Get(0), then `and (XIZ-2),0x0F` -- checked, not assumed
        back = "\n".join(code(k) for k in range(i - 30, i))
        if not re.search(r'pushw 0\ncall Arr27A6_Get\nm_and_mi8 MBD\+r6, 0xfe, 0x0f', back):
            continue
        ents = []
        for ll in L[IDX[m.group(1)] + 1:IDX[m.group(1)] + 20]:
            mm = re.match(r'^\s*\.long\s+(\w+)', ll)
            if mm:
                ents.append(mm.group(1))
            elif ll.strip() and not ll.startswith(";"):
                break
        out.append((h, m.group(1), ents))
    return out


def walk(label):
    """(min, max) set from `label` to `push xix`; 'exit' for an arm that is the epilogue; None if refused."""
    i, mn, mx, hops, first = IDX[label] + 1, None, None, 0, True
    while i < len(L) and hops < 4:
        c = code(i)
        i += 1
        if not c or G.match(c + ":") or re.match(r'^[A-Za-z_][\w$]*:$', c):
            continue
        if first and c == "pop xix":
            return "exit"
        first = False
        m = re.match(r'^ld \(xix\+([89])\), (\d+)$', c)
        if m:
            if m.group(1) == "8":
                mx = int(m.group(2))
            else:
                mn = int(m.group(2))
            continue
        m = re.match(r'^jrl? (\w+)$', c)
        if m and m.group(1) in IDX:
            i, hops = IDX[m.group(1)] + 1, hops + 1
            continue
        if c == "push xix":
            return (mn, mx) if mn is not None and mx is not None else None
        return None
    return None


def spell(v):
    v = v - 0x100 if v >= 0x80 else v
    return "M%d" % -v if v < 0 else "%d" % v


def plan():
    rows, refused, maps = [], [], []
    for h, tab, ents in tables():
        rows.append((tab, h + "_RangeByType", "%s_RangeByType: %s's switch on the DIGITAL EFFECT type (Arr27A6[0] & 0x0F), %d entries; each arm\\n"
                     "  sets the edit descriptor's MIN / MAX for that type (notes/prom_b_digital_effect_key_ranges.py)." % (h, h, len(ents))))
        names, typemap = {}, []
        for e in dict.fromkeys(ents):
            w = walk(e)
            if w is None:
                refused.append((e, "walk refused"))
                continue
            types = [k for k, x in enumerate(ents) if x == e]
            if w == "exit":
                new = h + "_NoFieldForType"
                why = "goes straight to the epilogue: type(s) %s have no field on this key" % ",".join(map(str, types))
            else:
                new = "%s_Range%sTo%s" % (h, spell(w[0]), spell(w[1]))
                why = "MIN %s, MAX %s for type(s) %s" % (spell(w[0]).replace("M", "-"), w[1], ",".join(map(str, types)))
            if new in names.values():
                refused.append((e, "range shared with %s" % [o for o, n in names.items() if n == new]))
                continue
            names[e] = new
            typemap.append("%s: %s" % (",".join(map(str, types)), new.split("_")[-1]))
            if not e.startswith("sub_"):
                continue
            rows.append((e, new, "%s: an arm of %s_RangeByType -- %s\\n"
                         "  (notes/prom_b_digital_effect_key_ranges.py)." % (new, h, why)))
        maps.append((h, tab, typemap))
    return rows, refused, maps


def main():
    rows, refused, maps = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    news = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = news.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-16s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for h, tab, tm in maps:
            print("%s via %s:  %s" % (h, tab, "; ".join(tm)))
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (news.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
