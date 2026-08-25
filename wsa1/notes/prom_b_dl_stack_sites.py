#!/usr/bin/env python3
"""The display-list call sites that pass their arguments ON THE STACK.

QUESTION IT ANSWERS
  `scripts/analysis/prom_b_display_lists.py` finds a display list by looking for
  ONE instruction shape:

      ld XIY,<start>  (45 ..)   ld XIX,<end>  (44 ..)   call 0xF417F0 / 0xF417F4

  That shape is blind to the 7,258 bytes of display lists at prom_b
  0xF58000-0xF59C59 -- the DISK and FILE menus, which is where gap V of
  `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` says to look.  Not one of
  those lists is entered by the register form.  They are entered through STACK
  VENEERS, of which this image has six:

      prom_b 0xF31800  DisplayList_Run_Stack       -> 0xF31A09 (interpreter A)
      prom_b 0xF31814  DisplayListB_Run_Stack      -> 0xF31AF0 (interpreter B)
      prom_b 0xF31828  DisplayList_RunOne_Stack    -> A, one record
      prom_b 0xF3183D  DisplayListB_RunOne_Stack   -> B, one record
      prom_a 0xFF75D3  the same frame as 0xF31800, plus `ld (0x2540),E`
      prom_a 0xFF75EF  the same frame as 0xF31814

  and the two-ended ones are called in three shapes, all of which push the SAME
  two arguments in the SAME order:

      pushw <flag>                      ; interpreter A only; -> (0x2540)
      lda XBC,<end>   / push XBC
      lda XWA,<start> / push XWA        ; last push  = lowest slot = (XIZ+0x08)
   1.   call 0xFF75D3                                        ... 33 sites
   2.   lda XIY,<return> / push XIY / jp (XIX)               ... 97 sites
   3.   jr / jrl to one of the above                         ... (shares them)

  Shape 2 is a call through a cached function pointer: `lda XIX,<veneer>` is
  issued once per routine and every list in that routine is then run with a
  hand-built return address and `jp (XIX)`.  Three pointers are cached this way
  in prom_a -- 0xFF75D3 (40 uses), thunk T_F42E00 = DisplayList_Run_Stack (38)
  and T_F42E04 = DisplayListB_Run_Stack (19) -- and no other value is ever
  cached in XIX ahead of this shape.
  ★ That also answers `DisplayList_Run_Stack`'s own header, which says
  "Called from: through the thunk table; NOT YET TRACED TO A SPECIFIC CALLER".

HOW A SITE IS CONFIRMED, AND WHY IT IS NOT JUST A PATTERN MATCH
  The push pair alone proves nothing -- two 24-bit constants and two pushes are
  a common shape.  A site counts only when the flow LEAVES it into a veneer:
  from the byte after the pair the resolver walks forward, follows `jr cc,d8`
  (0x60-0x6F) and `jrl cc,d16` (0x70-0x7F) up to MAX_HOPS times, and accepts
  either a `call` to a veneer or the `push <ret> / jp (XIX)` quad with a cached
  veneer pointer.  Anything else is reported UNRESOLVED rather than assumed.
  Then every confirmed span is put through the framing walk: the record length
  bytes read from `start` must land EXACTLY on `end`, with no opcode above the
  interpreter's own bound.  61 of 61 do.

WHAT IT ESTABLISHES, AND WHAT IT DOES NOT
  ESTABLISHED: 109 confirmed sites -- 70 of the `call` shape and 39 of the
  `jp (XIX)` shape -- naming 61 distinct (start, end, interpreter) triples in
  0xF58000-0xF59C59; all 61 frame; 0 unresolved push pairs into that region; the
  veneer -> interpreter map is re-read out of prom_a and prom_b rather than
  tabulated by hand; and the A/B attribution is CROSS-CHECKED against the two
  interpreters' own opcode bounds -- 50 A spans reach opcode 0x23 against A's
  bound of 0x24, the 11 B spans never exceed 0x08 against B's 0x0F, no record is
  claimed by both, and 19 of the 50 A spans hold an opcode >= 0x0F that
  interpreter B could not dispatch at all.
  NOT ESTABLISHED: that these are the only shapes anywhere.  The resolver knows
  three, found from one region's call sites.  A fourth shape elsewhere in the
  image would be silently absent, not reported -- which is why `--global` prints
  what the same scan finds outside the region, for the next pass to judge.

RUN
  python3 notes/prom_b_dl_stack_sites.py             # sites and spans, this region
  python3 notes/prom_b_dl_stack_sites.py --global    # ... and what it finds elsewhere
  python3 notes/prom_b_dl_stack_sites.py --selftest  # 23 checks, exit 1 on any failure
"""
import bisect
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL

B_BASE, A_BASE = 0xF00000, 0xF80000
REGION = (0xF58000, 0xF59C5A)             # the span this file was written for

# veneer entry -> interpreter thunk.  Checked against the ROM by veneer_bodies().
VENEERS = {0xFF75D3: DL.RUN_A, 0xFF75EF: DL.RUN_B,
           0xF42E00: DL.RUN_A, 0xF42E04: DL.RUN_B}
MAX_HOPS = 3
WINDOW = 24                               # bytes to walk before giving up on a hop


def veneer_bodies(a, b):
    """Re-derive the veneer -> interpreter map from the two images.

    A stack veneer is `push XIZ / ld XIZ,XSP / ... / ld XIY,(XIZ+0x08) /
    ld XIX,(XIZ+0x0C) / <call>`.  Returns {entry: called address}.  The two
    prom_b entries are thunk slots (`jp <veneer>`), so they are followed first.
    """
    out = {}
    for v in VENEERS:
        img, base = (a, A_BASE) if v >= A_BASE else (b, B_BASE)
        o = v - base
        if img[o] == 0x1B:                                  # thunk: jp imm24
            v2 = int.from_bytes(img[o + 1:o + 4], "little")
            img, base = (a, A_BASE) if v2 >= A_BASE else (b, B_BASE)
            o = v2 - base
        body = img[o:o + 0x20]
        if body[0] != 0x3E or body[1:3] != b"\xef\x8e":      # push XIZ / ld XIZ,XSP
            continue
        i = body.find(b"\xae\x08\x25")                       # ld XIY,(XIZ+0x08)
        j = body.find(b"\xae\x0c\x24")                       # ld XIX,(XIZ+0x0c)
        if i < 0 or j < 0 or i > j:
            continue
        # the call is the first transfer AFTER the two argument loads; 0xFF75D3
        # has `ld DE,(XIZ+0x10)` and `ld (0x2540),E` in between, so scan.
        for k in range(j + 3, len(body) - 3):
            if body[k] == 0x1D:                              # call imm24
                out[v] = int.from_bytes(body[k + 1:k + 4], "little")
                break
            if body[k] == 0x1E:                              # calr disp16
                d = int.from_bytes(body[k + 1:k + 3], "little")
                out[v] = base + o + k + 3 + (d - 0x10000 if d > 0x7FFF else d)
                break
    return out


def _cached_xix(loads, lofs, o):
    """Value of the nearest PRECEDING `lda XIX,imm24`, or None."""
    i = bisect.bisect_left(lofs, o) - 1
    return loads[i][1] if i >= 0 else None


def _resolve(img, loads, lofs, o):
    """Which veneer does the push pair at file offset `o` reach?  None = unresolved."""
    p = o + 12
    for _ in range(MAX_HOPS):
        stop = min(p + WINDOW, len(img) - 8)
        while p < stop:
            if (img[p] == 0xF2 and img[p + 4] == 0x35 and img[p + 5] == 0x3D
                    and img[p + 6] == 0xB4 and img[p + 7] == 0xD8):   # push ret / jp (XIX)
                return VENEERS.get(_cached_xix(loads, lofs, o))
            if img[p] == 0x1D:                                        # call imm24
                t = int.from_bytes(img[p + 1:p + 4], "little")
                if t in VENEERS:
                    return VENEERS[t]
                return None
            if 0x60 <= img[p] <= 0x6F:                                # jr cc,d8
                d = img[p + 1]
                p = p + 2 + (d - 256 if d > 127 else d)
                break
            if 0x70 <= img[p] <= 0x7F:                                # jrl cc,d16
                d = int.from_bytes(img[p + 1:p + 3], "little")
                p = p + 3 + (d - 0x10000 if d > 0x7FFF else d)
                break
            p += 1
        else:
            return None
        if not (0 <= p < len(img) - 8):
            return None
    return None


def scan(a, b, region=REGION):
    """(confirmed, unresolved).  confirmed = {(start,end,thunk): [site, ...]}."""
    lo, hi = region
    confirmed, unresolved = {}, []
    for img, base in ((a, A_BASE), (b, B_BASE)):
        loads = [(o, int.from_bytes(img[o + 1:o + 4], "little"))
                 for o in range(len(img) - 5) if img[o] == 0xF2 and img[o + 4] == 0x34]
        lofs = [x[0] for x in loads]
        for o in range(len(img) - 20):
            if not (img[o] == 0xF2 and img[o + 4] == 0x31 and img[o + 5] == 0x39
                    and img[o + 6] == 0xF2 and img[o + 10] == 0x30 and img[o + 11] == 0x38):
                continue
            e = int.from_bytes(img[o + 1:o + 4], "little")
            s = int.from_bytes(img[o + 7:o + 10], "little")
            if not (lo <= s < hi and lo < e <= hi and e > s):
                continue
            t = _resolve(img, loads, lofs, o)
            if t is None:
                unresolved.append((base + o, s, e))
            else:
                confirmed.setdefault((s, e, t), []).append(base + o)
    return confirmed, unresolved


def sites(a, b, region=REGION):
    """The (start, end, thunk) triples, in DL.call_sites' own format."""
    return set(scan(a, b, region)[0])


# ------------------------------------------------------------------ report/tests
def main():
    a, b = DL.load()
    if "--selftest" in sys.argv:
        return selftest(a, b)
    reg = (0xF00000, 0xF80000) if "--global" in sys.argv else REGION
    conf, unres = scan(a, b, reg)
    known = {(s, e) for s, e, _ in DL.call_sites(a, b)}
    print("stack-argument display-list sites in 0x%06X-0x%06X: %d, naming %d spans"
          % (reg[0], reg[1] - 1, sum(len(v) for v in conf.values()), len(conf)))
    print("  interp  start     end       bytes  recs  sites  also found by the register form?")
    for (s, e, t) in sorted(conf):
        r = DL.walk(b, s, e)
        print("  %s       0x%06X  0x%06X  %5d  %4s  %5d  %s"
              % ("A" if t == DL.RUN_A else "B", s, e, e - s,
                 len(r) if r else "NONE", len(conf[(s, e, t)]),
                 "yes" if (s, e) in known else "no"))
    print("\nunresolved push pairs: %d" % len(unres))
    for site, s, e in unres:
        print("  0x%06X -> 0x%06X-0x%06X" % (site, s, e))
    return 0


def selftest(a, b):
    fail, n = [0], [0]

    def check(msg, got, want):
        n[0] += 1
        ok = got == want
        print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
        if not ok:
            fail[0] += 1

    print("prom_b_dl_stack_sites selftest")
    vb = veneer_bodies(a, b)
    check("prom_a 0xFF75D3's frame calls", "0x%06X" % vb.get(0xFF75D3, 0), "0x%06X" % DL.RUN_A)
    check("prom_a 0xFF75EF's frame calls", "0x%06X" % vb.get(0xFF75EF, 0), "0x%06X" % DL.RUN_B)
    check("prom_b T_F42E00 -> DisplayList_Run_Stack calls",
          "0x%06X" % vb.get(0xF42E00, 0), "0x%06X" % 0xF31A09)
    check("prom_b T_F42E04 -> DisplayListB_Run_Stack calls",
          "0x%06X" % vb.get(0xF42E04, 0), "0x%06X" % 0xF31AF0)
    check("...so all four are veneers for one of the two interpreters",
          {v: (DL.RUN_A if x in (DL.RUN_A, 0xF31A09) else DL.RUN_B) for v, x in vb.items()},
          dict(VENEERS))
    conf, unres = scan(a, b)
    check("confirmed sites into 0xF58000-0xF59C59", sum(len(v) for v in conf.values()), 109)
    check("distinct (start, end, interpreter)", len(conf), 61)
    check("UNRESOLVED push pairs into the region", len(unres), 0)
    check("every site is in prom_a", {s >= A_BASE for v in conf.values() for s in v}, {True})
    walks = {k: DL.walk(b, k[0], k[1]) for k in conf}
    check("every span FRAMES", sum(1 for v in walks.values() if v is None), 0)
    check("spans run by interpreter A", sum(1 for _, _, t in conf if t == DL.RUN_A), 50)
    check("spans run by interpreter B", sum(1 for _, _, t in conf if t == DL.RUN_B), 11)
    check("none of the 61 is also found by the register form",
          len({(s, e) for s, e, _ in conf} & {(s, e) for s, e, _ in DL.call_sites(a, b)}), 0)
    # ---- the A/B attribution is CHECKED against the two opcode bounds, not asserted
    own = {}
    for k in conf:
        for p, op, ln in walks[k]:
            own.setdefault(p, set()).add(k[2])
    check("no record is claimed by BOTH interpreters", sum(1 for v in own.values() if len(v) > 1), 0)
    aops = [op for k in conf if k[2] == DL.RUN_A for _, op, _ in walks[k]]
    bops = [op for k in conf if k[2] == DL.RUN_B for _, op, _ in walks[k]]
    check("highest opcode in an A span (A's bound is 0x24)", "0x%02X" % max(aops), "0x23")
    check("highest opcode in a B span (B's bound is 0x0F)", "0x%02X" % max(bops), "0x08")
    check("A spans holding an opcode >= 0x0F, i.e. B could NOT run them",
          sum(1 for k in conf if k[2] == DL.RUN_A and any(op >= 0x0F for _, op, _ in walks[k])), 19)
    # the three call shapes are each really present
    shapes = {"call": 0, "jp": 0}
    for img, base in ((a, A_BASE), (b, B_BASE)):
        for v in (0xFF75D3, 0xFF75EF):
            pat = b"\x1d" + v.to_bytes(3, "little")
            o = img.find(pat)
            while o >= 0:
                shapes["call"] += 1
                o = img.find(pat, o + 1)
    check("shape 1: `call <prom_a veneer>` sites in the image", shapes["call"], 35)
    for img in (a, b):
        for o in range(len(img) - 20):
            if (img[o] == 0xF2 and img[o + 4] == 0x31 and img[o + 5] == 0x39
                    and img[o + 6] == 0xF2 and img[o + 10] == 0x30 and img[o + 11] == 0x38
                    and img[o + 12] == 0xF2 and img[o + 16] == 0x35 and img[o + 17] == 0x3D
                    and img[o + 18] == 0xB4 and img[o + 19] == 0xD8):
                shapes["jp"] += 1
    check("shape 2: `push <ret> / jp (XIX)` sites in the image", shapes["jp"], 97)
    # ---- EVERY reported site address must START an instruction in prom_a's own
    # source.  This tree's oldest recurring defect is "~20 call sites cited one
    # byte past the instruction", and a census whose addresses go straight into
    # headers is exactly where it gets in.  The round-2 audit of this very file
    # caught eleven such citations in its first draft.
    import re
    asrc = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
    starts = {int(m, 16) for m in re.findall(r";\s+([0-9A-F]{6})\s+[0-9a-f]{2}", asrc)}
    allsites = [x for v in conf.values() for x in v]
    check("every site address STARTS an instruction in prom_a/wsa1_prom_a.s",
          sum(1 for x in allsites if x not in starts), 0)
    check("  ...checked over", len(allsites), 109)
    # ---- the LAST element on its own, per this tree's rule
    last = sorted(conf)[-1]
    check("LAST span is 0x%06X-0x%06X, and its record count" % (last[0], last[1]),
          (last[0], last[1], len(walks[last])), (0xF59B86, 0xF59C2C, 7))
    check("  ...its last record ends exactly on 0x%06X" % last[1],
          walks[last][-1][0] + walks[last][-1][2], last[1])
    print("\n%d checks ran, %d failed" % (n[0], fail[0]))
    return 1 if fail[0] else 0


if __name__ == "__main__":
    sys.exit(main())
