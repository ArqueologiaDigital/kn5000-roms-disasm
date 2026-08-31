#!/usr/bin/env python3
"""Which SCREEN shows a given RAM variable, and what words sit next to it?

QUESTION IT ANSWERS
  Converting a module leaves you holding bare RAM addresses -- `(0x0d4a)`,
  `(0x0c8a)`, `(0x345c)`.  A name for one of those has to rest on something.
  Interpreter B of the display-list VM reads a 16-bit RAM address out of every
  record it runs (`IX=(XIY+2)` inside `DisplayListB_ExtractField`, 0xF31CC5), so
  the display lists are a REVERSE INDEX from a RAM variable to the place on
  screen where the firmware prints it.  This script builds that index, and for
  each hit prints the interpreter-A text drawn by the SAME routine -- i.e. the
  labels around the number.

  Everything it prints is a byte in the ROM, not an inference.  The link from a
  variable to a caption is "this routine draws both"; that is proximity in the
  CODE, and it is stated as such.  It is evidence for a name, never a proof of
  one.

HOW
  * A call site is the committed scanner's shape -- `ld XIY,imm32 /
    ld XIX,imm32 / call {0xF417F0|0xF417F4}` -- but this scanner also KEEPS the
    address of the call site itself, which the committed one throws away.  That
    address is what makes "the same routine draws both" measurable.
  * B records are walked with the committed walker (`prom_b_display_lists.walk`)
    and their fields read with interpreter B's layout, which
    `notes/prom_b_dl_length_audit.py` established:
        +2 u16  RAM address     +4 u8 mask     +5 u8 shift (&7)
        +7 u32  table pointer   (opcodes 02 and 07 only)
        +0x0B u16 entry width   (opcodes 02 and 07 only)
  * "The same routine" is approximated by a WINDOW in the code, default 0x200
    bytes either side of the B call site, in the same image.  It is a window,
    not a call-graph fact; --window changes it and a wider window is noisier,
    not more correct.

SELF-CHECKS (all run on every invocation; exits non-zero on failure)
  1. the number of B records this script walks equals the 494 that
     notes/prom_b_dl_length_audit.py reports for "B only";
  2. every field this script reads back is re-read straight from the ROM image;
  3. the worked example from FINDINGS-ui-display-list-interpreter-b.md --
     the opcode-07 record at 0xF0302A, whose +7 pointer is 0xF03241 (the 64
     resonator names) and whose entry width is 8 -- comes back out of the index.

RUN
  python3 notes/prom_b_var_screens.py --census            # every variable, ranked
  python3 notes/prom_b_var_screens.py --var 0x0C8A        # one variable, in context
  python3 notes/prom_b_var_screens.py --var 0x0C8A --window 0x400
  python3 notes/prom_b_var_screens.py --table 0xF03241    # who points at a table
  python3 notes/prom_b_var_screens.py --site 0xF62C00-0xF65000   # vars a code range draws
"""
import collections
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                  # noqa: E402

B_BASE, A_BASE = 0xF00000, 0xF80000
RUN_A, RUN_B = DL.RUN_A, DL.RUN_B
# interpreter B handler table (file offset) and the opcodes whose handler is a
# bare `ret` -- those records carry no variable.
HTBL_B = 0x31DB1
B_RET_HANDLER = 0xF31D20
# opcodes whose handler re-points XIY at a table: 0xF31B21 (op 02), 0xF31B39 (op 07)
B_TABLE_HANDLERS = {0xF31B21, 0xF31B39}


def imgs():
    a, b = DL.load()
    return {"a": (a, A_BASE), "b": (b, B_BASE)}


def rd(img, base, addr, n):
    o = addr - base
    if o < 0 or o + n > len(img):
        return None
    return int.from_bytes(img[o:o + n], "little")


def sites_with_code(images):
    """(code_img_key, code_addr, list_start, list_end, thunk) for every call site."""
    out = []
    for k, (img, base) in images.items():
        for o in range(len(img) - 24):
            if (img[o] == 0x45 and img[o + 4] == 0x00 and img[o + 5] == 0x44
                    and img[o + 9] == 0x00 and img[o + 10] == 0x1D):
                t = img[o + 11] | img[o + 12] << 8 | img[o + 13] << 16
                if t in (RUN_A, RUN_B):
                    s = img[o + 1] | img[o + 2] << 8 | img[o + 3] << 16
                    e = img[o + 6] | img[o + 7] << 8 | img[o + 8] << 16
                    if e > s:
                        out.append((k, base + o, s, e, t))
    return out


def btable(b):
    return [int.from_bytes(b[HTBL_B + i * 4:HTBL_B + i * 4 + 4], "little")
            for i in range(15)]


def b_records(b, sites):
    """{record addr: (op, len, code sites that reach it)} for interpreter-B sites."""
    recs = {}
    for k, code, s, e, t in sites:
        if t != RUN_B or not (B_BASE <= s < A_BASE):
            continue
        r = DL.walk(b, s, e)
        if r is None:
            continue
        for p, op, ln in r:
            recs.setdefault(p, (op, ln, []))[2].append((k, code))
    return recs


def a_text(b, s, e, ta):
    """The ASCII a framing interpreter-A list draws, as a list of strings."""
    r = DL.walk(b, s, e)
    if r is None:
        return []
    out = []
    for p, op, ln in r:
        h = ta[op] if op < len(ta) else 0
        off = 4 if h == 0xF31A3A else 6 if h == 0xF31A52 else None
        if off is None or ln <= off:
            continue
        raw = b[p - B_BASE + off:p - B_BASE + ln]
        t = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in raw)
        if t.strip("."):
            out.append(t)
    return out


def atables(b):
    return [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little")
            for i in range(36)]


def build(images):
    a, b = images["a"][0], images["b"][0]
    sites = sites_with_code(images)
    tb, ta = btable(b), atables(b)
    recs = b_records(b, sites)
    rows = []
    for p, (op, ln, code) in sorted(recs.items()):
        h = tb[op] if op < len(tb) else 0
        if h == B_RET_HANDLER:
            continue
        var = rd(b, B_BASE, p + 2, 2)
        mask = rd(b, B_BASE, p + 4, 1)
        shift = rd(b, B_BASE, p + 5, 1) & 7
        tbl = wid = None
        if h in B_TABLE_HANDLERS:
            tbl = rd(b, B_BASE, p + 7, 4)
            wid = rd(b, B_BASE, p + 0x0B, 2)
        rows.append(dict(addr=p, op=op, len=ln, handler=h, var=var, mask=mask,
                         shift=shift, table=tbl, width=wid, code=code))
    return sites, recs, rows, ta


def context(images, ta, code_sites, window):
    """ASCII drawn by interpreter-A lists whose call site is within `window`."""
    a, b = images["a"][0], images["b"][0]
    allsites = context.cache
    out = []
    for k, code in code_sites:
        for k2, c2, s2, e2, t2 in allsites:
            if t2 != RUN_A or k2 != k or abs(c2 - code) > window:
                continue
            if not (B_BASE <= s2 < A_BASE):
                continue
            out.extend(a_text(b, s2, e2, ta))
    seen, uniq = set(), []
    for t in out:
        if t not in seen:
            seen.add(t)
            uniq.append(t)
    return uniq


# The 13 interpreter-B tables that live in RAM rather than in a ROM, as
# (pointer, entry width).  Ten distinct addresses; 0x0022F0 appears at three
# widths and 0x002661 at two.  Asserted by selfcheck() check 4.
RAM_TABLES = [
    (0x0012F6, 6), (0x0012F7, 6), (0x0012F8, 6), (0x0012FE, 6),
    (0x0022F0, 2), (0x0022F0, 13), (0x0022F0, 16),
    (0x002300, 13), (0x002310, 13), (0x002320, 13),
    (0x00264C, 6), (0x002661, 2), (0x002661, 3),
]


def selfcheck(images, rows, recs):
    b = images["b"][0]
    fails = []
    # 1. record count against the length audit's "B only"
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import prom_b_dl_length_audit as AU
    own, _, _ = AU.per_site(b, set((s, e, t) for k, c, s, e, t in
                                   sites_with_code(images)))
    bonly = sum(1 for p, (which, op, ln) in own.items() if which == {RUN_B})
    if bonly != len(recs):
        fails.append("B record count %d != length audit's B-only %d" % (len(recs), bonly))
    # 2. every field re-read from the ROM
    for r in rows:
        o = r["addr"] - B_BASE
        if b[o] != r["op"] or b[o + 1] != r["len"]:
            fails.append("record 0x%06X does not re-read" % r["addr"])
            break
        if r["var"] != int.from_bytes(b[o + 2:o + 4], "little"):
            fails.append("var of 0x%06X does not re-read" % r["addr"])
            break
    # 3. the worked example
    hit = [r for r in rows if r["addr"] == 0xF0302A]
    if not hit:
        fails.append("worked example 0xF0302A not in the index")
    elif hit[0]["table"] != 0xF03241 or hit[0]["width"] != 8 or hit[0]["mask"] != 0x3F:
        fails.append("worked example 0xF0302A: table/width/mask changed")

    # 4. the RAM tables, EXACTLY -- quoted in FINDINGS-prom_b-ui-variable-index.md
    #    as "13 rows, 10 distinct addresses".  An earlier revision of that note
    #    guessed the list ("around 0x22F0, 0x2640, 0x2661"); it omitted the whole
    #    0x12Fx cluster and wrote 0x264C as 0x2640.  Pinned here so the note can
    #    never drift from the tool again.
    ram = sorted(set((r["table"], r["width"]) for r in rows
                     if r["table"] and r["table"] < B_BASE))
    if ram != RAM_TABLES:
        fails.append("RAM (table,width) rows changed: %d rows %s"
                     % (len(ram), ["0x%06X w%d" % x for x in ram]))
    if len(set(t for t, w in ram)) != 10:
        fails.append("distinct RAM table addresses = %d, note says 10"
                     % len(set(t for t, w in ram)))
    return fails


def main():
    argv = sys.argv[1:]

    def opt(flag, dflt=None):
        return argv[argv.index(flag) + 1] if flag in argv else dflt

    images = imgs()
    sites, recs, rows, ta = build(images)
    context.cache = sites
    window = int(opt("--window", "0x200"), 0)

    fails = selfcheck(images, rows, recs)
    if fails:
        for f in fails:
            print("SELF-CHECK FAILED: " + f)
        return 1

    if "--selftest" in argv:
        print("prom_b_var_screens.py --selftest")
        print("  records: %d   display-list rows with a table: %d"
              % (len(recs), sum(1 for r in rows if r["table"])))
        ram = sorted(set((r["table"], r["width"]) for r in rows
                         if r["table"] and r["table"] < B_BASE))
        print("  RAM tables: %d rows, %d distinct addresses"
              % (len(ram), len(set(t for t, w in ram))))
        for t, w in ram:
            print("    0x%06X w%d" % (t, w))
        print("  all four checks in selfcheck() PASSED (it runs on every "
              "invocation and would have aborted above otherwise)")
        return 0

    if "--var" in argv:
        want = int(opt("--var"), 0)
        hits = [r for r in rows if r["var"] == want]
        print("variable 0x%04X -- %d display-list record(s)" % (want, len(hits)))
        for r in hits:
            print("  record 0x%06X op %02X len %2d  mask 0x%02X shift %d%s"
                  % (r["addr"], r["op"], r["len"], r["mask"], r["shift"],
                     ("  table 0x%06X width %d" % (r["table"], r["width"]))
                     if r["table"] else ""))
            if r["table"] and B_BASE <= r["table"] < A_BASE and r["width"]:
                n = (r["mask"] >> r["shift"]) + 1
                b = images["b"][0]
                for i in range(min(n, 40)):
                    o = r["table"] - B_BASE + i * r["width"]
                    s = "".join(chr(c) if 0x20 <= c < 0x7F else "."
                                for c in b[o:o + r["width"]])
                    print("        [%2d] %s" % (i, s))
            for txt in context(images, ta, r["code"], window)[:24]:
                print("      near: %s" % txt)
        return 0

    if "--families" in argv:
        # Which displayed variables form an arithmetic progression?  A run of
        # equally spaced addresses each drawn the same way is an ARRAY OF
        # RECORDS, and the spacing is the record size.  Reported, not assumed:
        # the script prints the family and its stride and says nothing about
        # what the record is.
        vs = sorted(set(r["var"] for r in rows))
        vset = set(vs)
        fams = []
        used = set()
        for stride in (0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01):
            for v in vs:
                if (v, stride) in used or v - stride in vset:
                    continue
                run = [v]
                while run[-1] + stride in vset:
                    run.append(run[-1] + stride)
                if len(run) >= 4:
                    for x in run:
                        used.add((x, stride))
                    fams.append((stride, run))
        print("arithmetic progressions among the %d displayed variables" % len(vs))
        print("  (length >= 4; longest stride first; a variable may appear twice)")
        print("  ⚠ A CONTIGUOUS run of displayed variables generates a spurious")
        print("    family at every stride that divides its length.  0x12F6-0x1305")
        print("    and 0x27A6-0x27B7 are contiguous, so their stride-1/2/4 rows are")
        print("    arithmetic, not structure.  A family is evidence only when the")
        print("    stride is LARGER than the gaps between its members, as the")
        print("    stride-0x40 rows are.")
        for stride, run in sorted(fams, key=lambda f: (-f[0], f[1][0])):
            print("  stride 0x%02X  x%-2d  %s"
                  % (stride, len(run), " ".join("0x%04X" % x for x in run)))
        return 0

    if "--tables" in argv:
        # every distinct string/parameter table an interpreter-B record points at
        b = images["b"][0]
        per = {}
        for r in rows:
            if not r["table"]:
                continue
            n = (r["mask"] >> r["shift"]) + 1
            k = (r["table"], r["width"])
            e = per.setdefault(k, dict(n=0, maxidx=0, vars=set()))
            e["n"] += 1
            e["maxidx"] = max(e["maxidx"], n)
            e["vars"].add(r["var"])
        print("interpreter-B tables: %d distinct (pointer, entry width) pairs"
              % len(per))
        print("  'bound' is (mask >> shift) + 1 -- an UPPER BOUND on the index,")
        print("  not a measurement of the array.  See FINDINGS-ui-display-list-"
              "interpreter-b.md.")
        print()
        for (t, w), e in sorted(per.items()):
            where = ("prom_b ROM" if B_BASE <= t < A_BASE else
                     "prom_a ROM" if A_BASE <= t <= 0xFFFFFF else "RAM")
            first = ""
            if where == "prom_b ROM" and w:
                o = t - B_BASE
                first = "".join(chr(c) if 0x20 <= c < 0x7F else "."
                                for c in b[o:o + min(w * 3, 24)])
            print("  0x%06X w%-2d bound %3d  x%-2d %-10s vars %s  %s"
                  % (t, w, e["maxidx"], e["n"], where,
                     ",".join("0x%04X" % v for v in sorted(e["vars"]))[:40],
                     first))
        return 0

    if "--table" in argv:
        want = int(opt("--table"), 0)
        for r in rows:
            if r["table"] == want:
                print("  record 0x%06X op %02X var 0x%04X mask 0x%02X width %d"
                      % (r["addr"], r["op"], r["var"], r["mask"], r["width"]))
        return 0

    if "--site" in argv:
        lo, hi = [int(x, 0) for x in opt("--site").split("-")]
        seen = collections.Counter()
        for r in rows:
            for k, c in r["code"]:
                if lo <= c < hi:
                    seen[r["var"]] += 1
        for v, n in sorted(seen.items()):
            print("  0x%04X  x%d" % (v, n))
        return 0

    # --census (default)
    per = collections.Counter(r["var"] for r in rows)
    print("interpreter-B display-list records: %d (%d carry a variable)"
          % (len(recs), len(rows)))
    print("distinct RAM variables displayed: %d" % len(per))
    print()
    for v, n in per.most_common(60):
        ops = sorted(set(r["op"] for r in rows if r["var"] == v))
        print("  0x%04X  x%-3d ops %s" % (v, n, " ".join("%02X" % o for o in ops)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
