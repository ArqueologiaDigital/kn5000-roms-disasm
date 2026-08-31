#!/usr/bin/env python3
"""Which prom_b routines name an ASCII string -- and which of those are CAPTIONS?

WHAT QUESTION THIS ANSWERS
    "Name from a string the routine points at" is the strongest naming rule this
    tree has, and applying it naively is a trap.  A census of prom_b's unnamed
    routines whose non-transfer operands land on printable ROM bytes returns
    seventy-odd, and a large share of them are NOT caption writers at all: they
    are display-list PAINTERS whose `ld XIX,imm` is the list's END POINTER,
    which merely happens to sit on the operand table the list indexes.  Naming
    one of those after "the string it loads" would produce a confident wrong
    name that the byte gate cannot see.

    This script prints both columns, so the trap is visible rather than stepped
    into:

      CAPTION   the routine COPIES the bytes -- `ld XIY,<ascii>` ... `ldir` --
                into RAM.  The string is content the routine puts on screen.
      DL-RUN    the routine's shape is `ld XIY,<start> / ld XIX,<end> /
                call 0xF417F0|F4|F8` -- a display-list run.  The "string" is
                where the list ENDS, not what the routine says.
      OTHER     neither shape matched; look before naming.

    Wave 8 named the CAPTION column (38 routines, notes/prom_b_msgline.py) and
    left the DL-RUN column alone.

RUN
    python3 notes/prom_b_string_refs.py             # the census, by class
    python3 notes/prom_b_string_refs.py --unnamed   # only sub_XXXXXX routines
Exit status is 0 always; this is a census, not a gate.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines  # noqa: E402

B_BASE, A_BASE = 0xF00000, 0xF80000
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s(.*)$")
XFER = re.compile(r"^(call|calr|jp|jr|jrl|djnz)\b")
HEX = re.compile(r"0x([0-9a-fA-F]+)")
DL_RUNNERS = (0xF417F0, 0xF417F4, 0xF417F8, 0xF41800, 0xF42E04, 0xF42E0C)

ROM = {}
for _n, _f in (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13")):
    with open(os.path.join(ROOT, "original_ROMs", _f), "rb") as _h:
        ROM[_n] = _h.read()


def ascii_at(a, maxlen=48):
    if B_BASE <= a < A_BASE:
        r, o = ROM["b"], a - B_BASE
    elif A_BASE <= a < 0x1000000:
        r, o = ROM["a"], a - A_BASE
    else:
        return None
    s = bytearray()
    for i in range(maxlen):
        c = r[o + i]
        if 0x20 <= c < 0x7F:
            s.append(c)
        else:
            break
    return s.decode() if len(s) >= 4 else None


def routines():
    seq = collections.OrderedDict()
    cur = None
    for ln in image_lines(ROOT, "prom_b/wsa1_prom_b.s"):
        m = LABEL.match(ln)
        if m:
            cur = m.group(1)
            seq.setdefault(cur, [])
        if ln.lstrip().startswith(";"):
            continue
        m2 = ADDRC.search(ln)
        if m2 and cur is not None:
            seq[cur].append(m2.group(2).strip())
    return seq


def classify(rows):
    """-> ('CAPTION'|'DL-RUN'|'OTHER', [strings])"""
    hits, xiy, bc = [], None, None
    caption = False
    for t in rows:
        m = re.fullmatch(r"ld XIY,0x([0-9a-f]+)", t)
        if m:
            xiy = int(m.group(1), 16)
            continue
        m = re.fullmatch(r"ld BC,0x([0-9a-f]+)", t)
        if m:
            bc = int(m.group(1), 16)
            continue
        if t in ("ldir", "ldirw") and xiy is not None and bc and ascii_at(xiy):
            caption = True
            hits.append(xiy)
            xiy = None
    for h in {int(x, 16) for t in rows if not XFER.match(t) for x in HEX.findall(t)}:
        s = ascii_at(h)
        if s and h not in hits:
            hits.append(h)
    if not hits:
        return None, []
    if caption:
        return "CAPTION", hits
    # a `ld XIY,S / ld XIX,E / call <runner>` triple anywhere in the body
    for i in range(len(rows) - 2):
        if (rows[i].startswith("ld XIY,0x") and rows[i + 1].startswith("ld XIX,0x")
                and rows[i + 2].startswith("call 0x")
                and int(rows[i + 2].split()[1], 16) in DL_RUNNERS):
            return "DL-RUN", hits
    return "OTHER", hits


def main():
    only_unnamed = "--unnamed" in sys.argv
    seq = routines()
    by = collections.defaultdict(list)
    for name, rows in seq.items():
        if only_unnamed and not re.fullmatch(r"sub_[0-9A-F]{6}", name):
            continue
        k, hits = classify(rows)
        if k:
            by[k].append((name, hits))
    for k in ("CAPTION", "DL-RUN", "OTHER"):
        print(f"=== {k}  ({len(by[k])})")
        for name, hits in by[k]:
            print(f"  {name:36s} " + "; ".join(f"0x{h:06X} {ascii_at(h)!r}" for h in hits[:2]))
    print(f"\ntotal routines naming printable bytes: {sum(len(v) for v in by.values())}")
    print("  ⚠ only the CAPTION column may be named for its string.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
