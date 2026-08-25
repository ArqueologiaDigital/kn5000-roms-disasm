#!/usr/bin/env python3
"""Are the 341 "length-rule violations" in prom_b's display lists really violations?

QUESTION ANSWERED
  `FINDINGS-ui-display-list.md` carried a correction: of the 4,011 walked prom_b
  display-list records, 341 declare a length byte that does not match the length
  their handler implies.  That correction was right that the earlier "zero
  exceptions" claim was false.  It was wrong about what the exceptions ARE.

  This script tests one hypothesis and it survives:

      THERE ARE TWO INTERPRETERS, AND THE 341 RECORDS BELONG TO THE OTHER ONE.

  Interpreter A (0xF31A09, bound 0x24, handler table 0xF31D21) and interpreter B
  (0xF31AF0, bound 0x0F, handler table 0xF31DB1) share the (opcode, length, ...)
  record SHAPE but not the opcode space, not the handler table, and not the field
  layout.  The earlier audit checked every record against A's field layout,
  including the records that only B ever runs.

  Attribute each record to the interpreter of the call site that reaches it, and
  check it against THAT interpreter's implied length, and the exception count
  goes to zero.

HOW A RECORD IS ATTRIBUTED
  Call sites are the committed scanner's: `ld XIY,imm32 / ld XIX,imm32 / call nnn`
  with nnn in {0xF417F0, 0xF417F4} -- the two interpreter thunks.  Each site is
  walked SEPARATELY (the committed summary merges overlapping sites into spans
  before walking, which is what mixed the two interpreters together).  A record is
  "A only" if every site that reaches it calls 0xF417F0, "B only" if every site
  calls 0xF417F4.

WHERE THE IMPLIED LENGTHS COME FROM
  Each handler is disassembled and the highest record byte its own instructions
  touch is read off.  Implied length = that offset + 1.  No handler consults the
  length byte except the two text handlers of interpreter A, which compute a
  character count from it (`sub BC,4` / `sub BC,6`), so for those the rule is a
  minimum, not an equality.

  INTERPRETER A (table 0xF31D21, 36 entries)
    0xF31A3A ops 06 07 08 16 18 19 1A 1D 1E 1F 20 21  BC=len-4, XIY+=4   min 4
    0xF31A52 ops 17 1C                                BC=len-6, XIY+=6   min 6
    0xF31A75 ops 00 01 02 05 09 0A 11 12 13 15 1B 22  words +2 +4 +6 +8   = 10
    0xF31A9F op  0E                                   words +2 +4 +6      =  8
    0xF31AAC op  0B                                   words +2 +4         =  6
    0xF31ABE ops 03 04             long +2, words +6 +8 +0x0A             = 12
    0xF31ACE op  23                byte +2, word +3                       =  5
    0xF31AEB ops 0C 0D 0F 10 14    bare `ret`                             min 2

  INTERPRETER B (table 0xF31DB1, 15 entries).  Every handler first calls one of
  two field extractors, which is where the +2..+5 fields come from:
    0xF31CC5 ExtractField        IX=(XIY+2) word, A=(IX), A&=(XIY+4), C=(XIY+5)&7,
                                 A>>=C                          -> touches +5
    0xF31CE4 ExtractFieldSigned  the same, then reads (XIY+0x0A), or (XIY+0x0C)
                                 when the opcode is 0x0B, as a sign flag: bit 7
                                 set => leave zero-extended, clear => `exts WA`
                                                                -> touches +0x0A / +0x0C
    0xF31BA1 ops 00 06   +6, IX=(XIY+7) word, C=(XIY+9)                   = 10
    0xF31B21 op  02      +6, XIY=(XIY+7) long, BC=(XIY+0x0B), IX=(XIY+0x0D)= 15
    0xF31B39 op  07      as 02 plus IX=(XIY+0x0F)                          = 17
    0xF31B57 ops 03 08   +6, XIX=(XIY+7) long, indexed by WA<<3            = 11
    0xF31B86 op  04      +6, XIX=(XIY+7) long, indexed by WA*6             = 11
    0xF31BD7 op  05      ExtractFieldSigned(+0x0A), +6, IX=(XIY+7), C=(XIY+9)= 11
    0xF31C14 ops 09 0A   +6, IX=(XIY+7), IX=(XIY+9), C=(XIY+0x0B)          = 12
    0xF31C56 op  0B      ExtractFieldSigned(+0x0C), +6, +7, +9, C=(XIY+0x0B)= 13
    0xF31C9E op  01      +6, +8, HL=(XIY+0x0A)                             = 12
    0xF31D20 ops 0C 0D 0E   bare `ret`                                min  2

RESULT (2026-08-24, this script)
  A only 3603 records, 0 records whose length disagrees with A's implied length
  B only  494 records, 0 records whose length disagrees with B's implied length
  both      0 records

  The last record of the last B span is tested as well as the first: run with
  --records to see every record, --edges to print the first and last of each class.

RUN
  python3 notes/prom_b_dl_length_audit.py
  python3 notes/prom_b_dl_length_audit.py --edges
  python3 notes/prom_b_dl_length_audit.py --records
  python3 notes/prom_b_dl_length_audit.py --bspans     # B-only spans, for the .s
"""
import collections
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL          # reuse the committed walker verbatim

B_BASE = 0xF00000
HTBL_A = 0x31D21
HTBL_B = 0x31DB1

# handler -> (kind, n).  'fixed': length must equal n.  'min': length must be >= n.
IMPLIED_A = {
    0xF31A3A: ("min", 4), 0xF31A52: ("min", 6), 0xF31A75: ("fixed", 10),
    0xF31A9F: ("fixed", 8), 0xF31AAC: ("fixed", 6), 0xF31ABE: ("fixed", 12),
    0xF31ACE: ("fixed", 5), 0xF31AEB: ("min", 2),
}
IMPLIED_B = {
    0xF31BA1: ("fixed", 10), 0xF31B21: ("fixed", 15), 0xF31B39: ("fixed", 17),
    0xF31B57: ("fixed", 11), 0xF31B86: ("fixed", 11), 0xF31BD7: ("fixed", 11),
    0xF31C14: ("fixed", 12), 0xF31C56: ("fixed", 13), 0xF31C9E: ("fixed", 12),
    0xF31D20: ("min", 2),
}


def tables(b):
    ta = [int.from_bytes(b[HTBL_A + i * 4:HTBL_A + i * 4 + 4], "little") for i in range(36)]
    tb = [int.from_bytes(b[HTBL_B + i * 4:HTBL_B + i * 4 + 4], "little") for i in range(15)]
    return ta, tb


def per_site(b, sites):
    """{record start: (set of interpreter thunks reaching it, op, len)} and the
    per-site framing tally, from an UN-MERGED walk of every call site."""
    own, ok, bad = {}, collections.Counter(), []
    for s, e, t in sorted(sites):
        if not (B_BASE <= s < 0xF80000):
            continue
        r = DL.walk(b, s, e)
        if r is None:
            bad.append((s, e, t))
            continue
        ok[t] += 1
        for p, op, ln in r:
            own.setdefault(p, [set(), op, ln])[0].add(t)
    return own, ok, bad


def check(op, ln, htab, implied):
    h = htab[op]
    if h not in implied:
        return None, h                      # handler we have not disassembled
    kind, n = implied[h]
    good = (ln == n) if kind == "fixed" else (ln >= n)
    return good, h


def main():
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    ta, tb = tables(b)
    own, ok, bad = per_site(b, sites)

    rows = {"A only": [], "B only": [], "both": []}
    for p, (which, op, ln) in own.items():
        k = ("A only" if which == {DL.RUN_A} else
             "B only" if which == {DL.RUN_B} else "both")
        rows[k].append((p, op, ln))
    for k in rows:
        rows[k].sort()

    print("prom_b display lists, per-call-site (UN-MERGED) walk")
    print("  call sites: %d total, %d via 0xF417F0 (interpreter A), %d via 0xF417F4 (B)"
          % (len(sites), sum(1 for x in sites if x[2] == DL.RUN_A),
             sum(1 for x in sites if x[2] == DL.RUN_B)))
    nbad = {DL.RUN_A: sum(1 for x in bad if x[2] == DL.RUN_A),
            DL.RUN_B: sum(1 for x in bad if x[2] == DL.RUN_B)}
    tot = {t: ok[t] + nbad[t] for t in (DL.RUN_A, DL.RUN_B)}
    # The DENOMINATORS are printed here on purpose: quoting "243 of 244" used to
    # require the reader to add 243 + 1 by hand, which is exactly how a wrong
    # count gets into a header.  Nothing below is the reader's arithmetic.
    print("  sites in prom_b that FRAME: A %d of %d, B %d of %d      that do NOT frame: %d"
          % (ok[DL.RUN_A], tot[DL.RUN_A], ok[DL.RUN_B], tot[DL.RUN_B], len(bad)))
    for s, e, t in bad:
        print("      not framed: 0x%06X-0x%06X  (interpreter %s)"
              % (s, e, "A" if t == DL.RUN_A else "B"))
    print("  distinct records reached: %d" % len(own))
    print()

    bad_recs = {"A only": [], "B only": [], "both": []}
    unknown = collections.Counter()
    for k, lst in rows.items():
        for p, op, ln in lst:
            if k == "A only":
                good, h = check(op, ln, ta, IMPLIED_A)
            elif k == "B only":
                good, h = check(op, ln, tb, IMPLIED_B)
            else:
                ga, _ = check(op, ln, ta, IMPLIED_A)
                gb, h = check(op, ln, tb, IMPLIED_B)
                good = bool(ga) or bool(gb)
            if good is None:
                unknown[h] += 1
            elif not good:
                bad_recs[k].append((p, op, ln, h))

    print("checked against the OWNING interpreter's implied length:")
    for k in ("A only", "B only", "both"):
        print("  %-7s %5d records   %4d disagree" % (k, len(rows[k]), len(bad_recs[k])))
    if unknown:
        print("  handlers not in the implied table: %s"
              % ", ".join("0x%06X x%d" % kv for kv in unknown.items()))
    print()

    print("cross-check -- the same records against the WRONG interpreter's rule:")
    n = sum(1 for p, op, ln in rows["B only"]
            if check(op, ln, ta, IMPLIED_A)[0] is False)
    print("  B-only records judged by interpreter A's layout: %d of %d disagree"
          % (n, len(rows["B only"])))
    print("  (this is the population the '341 violations' figure came from)")

    if "--edges" in sys.argv:
        print()
        for k in ("A only", "B only"):
            if not rows[k]:
                continue
            print("%s: first and last record, both tested above" % k)
            for p, op, ln in (rows[k][0], rows[k][-1]):
                htab, imp = (ta, IMPLIED_A) if k == "A only" else (tb, IMPLIED_B)
                good, h = check(op, ln, htab, imp)
                raw = b[p - B_BASE:p - B_BASE + ln]
                print("   0x%06X op %02X len %2d handler 0x%06X %s : %s"
                      % (p, op, ln, h, "OK" if good else "DISAGREES",
                         " ".join("%02X" % c for c in raw)))

    if "--records" in sys.argv:
        print()
        for k in ("A only", "B only", "both"):
            for p, op, ln in rows[k]:
                htab, imp = (ta, IMPLIED_A) if k == "A only" else (tb, IMPLIED_B)
                good, h = check(op, ln, htab, imp)
                print("  %-7s 0x%06X op %02X len %2d handler 0x%06X %s"
                      % (k, p, op, ln, h, "ok" if good else "DISAGREES"))

    if "--bspans" in sys.argv:
        print()
        print("B-only call sites that frame, merged into maximal spans:")
        for s, e in bspans(b, sites, own):
            print("  0x%06X-0x%06X  %d bytes" % (s, e - 1, e - s))

    return 1 if any(bad_recs.values()) else 0


def bspans(b, sites, own):
    """Maximal merged spans whose every record is reached only by interpreter B."""
    iv = []
    for s, e, t in sorted(sites):
        if t != DL.RUN_B or not (B_BASE <= s < 0xF80000):
            continue
        if DL.walk(b, s, e) is None:
            continue
        if any(own[p][0] != {DL.RUN_B} for p, op, ln in DL.walk(b, s, e)):
            continue
        if iv and s <= iv[-1][1]:
            iv[-1][1] = max(iv[-1][1], e)
        else:
            iv.append([s, e])
    return [tuple(x) for x in iv]


if __name__ == "__main__":
    sys.exit(main())
