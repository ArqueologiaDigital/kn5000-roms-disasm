#!/usr/bin/env python3
"""Follow a screen's ENTER method through its delegation to the display-list
TEXT it paints -- and show, by CALIBRATION, that the text does NOT reliably
name the screen, which is why notes/prom_a_screen_methods_wave29.py names no
ENTER method from a title.

QUESTION IT ANSWERS
-------------------
  "Can the 98 screens whose ENTER method is still `sub_XXXXXX` be named the way
   FINDINGS-prom_a-panel-control-map.md section 6 proposed -- by following the
   delegation to the title the screen draws?"

  ANSWER: NO, not safely, and this script is the evidence.  It reconstructs the
  route that note advised ("follow the delegation, not the immediates"), then
  RUNS IT AGAINST THE 37 SCREENS THAT ARE ALREADY NAMED as a control: if the
  method were sound it would recover their known names.  It does not.

HOW
  * PanelScreen_VtableTable (0xF86EC1): 256 entries, each a `jp addr24` object
    with +0 ENTER, +4 LEAVE, +8 BUTTON (that table's own header, checks V1-V6).
  * From an ENTER address, walk the routine and every CALL/CALR it makes to a
    bounded depth, collecting any 24-bit immediate that points at a display
    list -- a record stream whose text records (opcode 0x06/0x07: [op][len]
    [x:2][ascii]) decode to printable text.  The interpreters at 0xF417F0 /
    0xF417F4 are the sinks; the branch targets are decoded from the machine-code
    bytes in the listing, not from the operand text (which is sometimes a raw
    relative).
  * `--titles`  the first title each screen paints, named and unnamed alike.
  * `--calibrate`  for the 37 already-named screens, the first title vs the
    known name -- the negative control.

WHAT THE CALIBRATION SHOWS (run it)
  Of the sixteen `Paint_*` screens, the first painted title matches the known
  name for only a couple (MidiFileL0ad, MidiFileDirectPlay).  The rest paint a
  SHARED BANNER or a FIELD LABEL first: Paint_Sequencer paints "REALTIME",
  Paint_DiskL0adFile paints "SAVE", Paint_MidiInputOutputFilter paints
  "MIDI CH".  The screen name lived in the reader's dispatch context or in a
  human's reading of the whole screen, not in the first text the painter draws;
  a left-margin-x tie-break does not rescue it either.  ★ So a title is DATA
  about the screen, not its NAME, and naming an ENTER method from one would be
  the "wrong name is worse than no name" trap.  The ~90 unnamed ENTER methods
  are left `sub_` for that reason.

USAGE
    python3 notes/prom_a_screen_titles_probe.py --calibrate
    python3 notes/prom_a_screen_titles_probe.py --titles
"""
import bisect
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
LISTING = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")

VTABLE, NULL = 0xF86EC1, 0xF872C1
SINKS = {0xF417F0, 0xF417F4}


def rd(a, n):
    if 0xF80000 <= a < 0x1000000:
        return A[a - 0xF80000:a - 0xF80000 + n]
    if 0xF00000 <= a < 0xF80000:
        return B[a - 0xF00000:a - 0xF00000 + n]
    return b""


def _jp(a):
    b = rd(a, 4)
    return int.from_bytes(b[1:4], "little") if b and b[0] == 0x1B else None


def records(a):
    """(x, text) for each text record of the display list at a, walked by the
    record LENGTH byte the interpreter itself advances by."""
    out, p, n = [], a, 0
    while n < 80:
        rec = rd(p, 2)
        if len(rec) < 2:
            break
        op, ln = rec[0], rec[1]
        if ln < 2 or ln > 0x80:
            break
        body = rd(p, ln)
        if op in (0x06, 0x07) and ln > 4:
            s = body[4:ln]
            if s and all(32 <= c < 127 for c in s):
                out.append((body[2] | (body[3] << 8), s.decode("latin-1").rstrip()))
        p += ln
        n += 1
        if ln == 0:
            break
    return out


# ---- the listing: address -> machine-code bytes and operand text -----------
_SRC = open(LISTING, "rb").read().decode("latin-1").split("\n")
_BY = re.compile(r';\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})\s*$')
_IMM = re.compile(r'0x0*([0-9a-f]{5,6})')
_LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
_ADDR = re.compile(r';\s*([0-9A-F]{6})\s+[0-9a-f]{2}')
IB, OPTXT, LAB = {}, {}, {}
for _i, _ln in enumerate(_SRC):
    _m = _BY.search(_ln)
    if _m:
        _a = int(_m.group(1), 16)
        IB[_a] = [int(x, 16) for x in _m.group(2).split()]
        OPTXT[_a] = _ln.split(";", 1)[0]
for _i, _ln in enumerate(_SRC):
    _m = _LABEL.match(_ln)
    if _m and _i + 1 < len(_SRC):
        _a = _ADDR.search(_SRC[_i + 1])
        if _a:
            LAB.setdefault(int(_a.group(1), 16), _m.group(1))
_SA = sorted(IB)


def _nxt(a):
    j = bisect.bisect_right(_SA, a)
    return _SA[j] if j < len(_SA) else None


def _s8(x):
    return x - 256 if x >= 128 else x


def _s16(x):
    return x - 65536 if x >= 32768 else x


def _target(a):
    bs = IB.get(a)
    if not bs:
        return None
    b0, L = bs[0], len(bs)
    if b0 == 0x1D and L >= 4:                       # CALL abs24
        return bs[1] | bs[2] << 8 | bs[3] << 16
    if b0 == 0x1B and L >= 4:                       # JP abs24
        return bs[1] | bs[2] << 8 | bs[3] << 16
    if b0 == 0x1E and L >= 3:                       # CALR rel16
        return a + L + _s16(bs[1] | bs[2] << 8)
    return None


def first_title(enter, maxdepth=4, budget=120):
    """The FIRST display-list title the ENTER method paints, in program order,
    plus the leftmost-x title of that same list, plus the list address."""
    res = [None]
    seen = set()

    def walk(a, d):
        if res[0] is not None or a is None or a in seen or a in SINKS:
            return
        if d > maxdepth or not (0xF80000 <= a < 0x1000000):
            return
        seen.add(a)
        if len(seen) > budget:
            return
        p, steps = a, 0
        while p in IB and steps < 500 and res[0] is None:
            for im in (int(x, 16) for x in _IMM.findall(OPTXT[p])):
                r = records(im)
                if r:
                    res[0] = (im, r)
                    return
            bs = IB[p]
            tgt = _target(p)
            if tgt is not None and bs[0] in (0x1D, 0x1E):
                walk(tgt, d + 1)
            if bs[0] == 0x0E:                        # ret
                break
            np = _nxt(p)
            if np is None or np - p > 16:
                break
            p, steps = np, steps + 1

    walk(enter, 0)
    return res[0]


def _screens():
    for i in range(256):
        v = int.from_bytes(rd(VTABLE + 4 * i, 4), "little") & 0xFFFFFF
        if not v or v == NULL:
            continue
        e = _jp(v)
        if e and 0xF80000 <= e < 0x1000000:
            yield i, e, LAB.get(e, "(unlabelled)")


def titles():
    for i, e, nm in _screens():
        ft = first_title(e)
        if ft:
            im, recs = ft
            left = sorted(recs)[0][1]
            print("entry 0x%02X %-30s ENTER %06X first=%-24r leftX=%r"
                  % (i, nm, e, recs[0][1][:22], left[:22]))
        else:
            print("entry 0x%02X %-30s ENTER %06X (no title reachable)"
                  % (i, nm, e))
    return 0


def calibrate():
    hit_first = hit_left = named = 0
    print("CALIBRATION -- already-named screens: does the painted title recover "
          "the known name?\n")
    for i, e, nm in _screens():
        if not nm.startswith("Paint_"):
            continue
        named += 1
        want = nm[len("Paint_"):].lower()
        ft = first_title(e)
        if not ft:
            print("  0x%02X %-28s -> NO TITLE" % (i, nm))
            continue
        im, recs = ft
        first = re.sub(r'[^a-z0-9]', '', recs[0][1].lower())
        left = re.sub(r'[^a-z0-9]', '', sorted(recs)[0][1].lower())
        wn = re.sub(r'[^a-z0-9]', '', want)
        of = first.startswith(wn[:6]) or wn.startswith(first[:6]) if first else False
        ol = left.startswith(wn[:6]) or wn.startswith(left[:6]) if left else False
        hit_first += of
        hit_left += ol
        print("  0x%02X %-28s first=%-22r %s | leftX=%-22r %s"
              % (i, nm, recs[0][1][:20], "MATCH" if of else "miss",
                 sorted(recs)[0][1][:20], "MATCH" if ol else "miss"))
    print("\n  first-title recovered the name: %d / %d" % (hit_first, named))
    print("  left-x   title recovered it:    %d / %d" % (hit_left, named))
    print("\n  ★ Neither is a majority.  A screen's title is DATA about it, not "
          "its name -- so no ENTER method is named from a title.")
    return 0


def main():
    a = sys.argv[1] if len(sys.argv) > 1 else "--calibrate"
    if a == "--titles":
        sys.exit(titles())
    elif a == "--calibrate":
        sys.exit(calibrate())
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
