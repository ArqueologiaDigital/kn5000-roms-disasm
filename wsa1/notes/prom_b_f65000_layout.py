#!/usr/bin/env python3
"""The code/data/fill LAYOUT of prom_b 0xF65000-0xF6D001, derived from the ROM.

QUESTION IT ANSWERS
  "Which bytes of this block are instructions, which are tables, and which are
   padding?"  The answer is computed here and FROZEN into
   notes/gen_prom_b_f65000_module.py's LAYOUT, whose checks() re-derives it on
   every emit.  Nothing in the layout is typed by hand.

THE RULES, IN PRIORITY ORDER, AND THE NULL MEASURED FOR EACH
  1. FILL   -- a maximal run of at least 16 bytes of 0x0E.  0x0E is `ret`, so a
     SHORT run of it is ordinary inter-routine padding and stays inside a code
     segment; only the long runs that close a module become `.fill`.
  2. PTRTAB -- a maximal chain of at least THREE consecutive 4-byte little-endian
     words all inside 0x00F60000-0x00F6FFFF.  NULL (see below): ZERO.
  3. ASCII  -- a maximal run of at least TWENTY bytes in 0x20-0x7E (ASCII_MIN).
     NULL: ZERO at >= 20, THREE at >= 10, TWENTY-THREE at >= 8, which is why the
     threshold is 20 and not 10 or 8.  ⚠ It therefore MISSES short strings;
     `VOLUME = ` (9 bytes at 0xF67DC6) is one, and it stays inside a code segment
     rather than being promoted by a rule with a measured false-positive rate.

THE NULL CORPUS GROWS -- CITE IT WITH A REVISION
  The corpus is every maximal run of PROVEN instruction text in the CURRENT
  prom_b/wsa1_prom_b.s (`proven_code_runs()`), so it gets bigger every time any
  round converts anything, and a false-positive count quoted without a revision
  rots.  CORRECTED 2026-08-25: an earlier docstring here said "TEN" and "16,316
  bytes ... ONE at >= 8" while the code said 20; the note that cited it said
  "2,948 runs, 54,814 bytes, 7 at 8, 3 at 10".  Three different corpus sizes were
  in circulation and none matched the code.  The fix is `--rev`:

      python3 notes/prom_b_f65000_layout.py --null --rev 2707125

  reads the .s with `git show REV:prom_b/wsa1_prom_b.s`, so the numbers it prints
  are reproducible for as long as that commit exists.  Bare `--null` uses the
  working tree and prints the corpus size it used; quote BOTH or quote neither.
  4. CODE   -- reached by a recursive descent that treats every region rules 1-3
     found as a BARRIER: the walk will not decode into one and will not take a
     seed inside one.  Its seeds are the thunk targets, every opcode-anchored
     `call`/`jp` site in prom_a+prom_b, every 32-bit immediate an instruction it
     has already decoded LOADS, and every in-range entry of every table rule 2
     framed.
  Anything left over is `.byte` DATA, and the header says only that.

WHY THE BARRIER MATTERS (this script's first draft got it wrong)
  Seeding the descent with every 32-bit immediate an instruction loads is what
  makes it reach 78% instead of 45% -- but a loaded immediate is just as often a
  DATA-table address, and without the barrier the walk cheerfully decoded 980
  bytes of pointer table as instructions, including two complete 32-entry tables
  at 0xF6828B and 0xF685C1.  `--conflicts` is the count that caught it and it
  must stay at zero.

RUN
  python3 notes/prom_b_f65000_layout.py             # the LAYOUT table
  python3 notes/prom_b_f65000_layout.py --null      # the calibration (live corpus)
  python3 notes/prom_b_f65000_layout.py --null --rev 2707125   # pinned corpus
  python3 notes/prom_b_f65000_layout.py --conflicts # descent-vs-barrier overlaps
  python3 notes/prom_b_f65000_layout.py --residue   # data runs, with hex
  python3 notes/prom_b_f65000_layout.py --python    # paste-ready LAYOUT literal
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
from asm_source import image_text_at_rev  # noqa: E402  (the image at a revision)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import trace_code as TC                                            # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402

B_BASE = 0xF00000
LO, HI = 0xF65000, 0xF6D002
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
PTR_LO, PTR_HI = 0x00F60000, 0x00F70000
FILL_MIN, PTR_MIN, ASCII_MIN, IDENT_MIN, RAM_MIN, BIT_MIN = 16, 3, 20, 12, 4, 8
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")

_r = {}


def rom(which="b"):
    if which not in _r:
        _r[which] = open(IMGA if which == "a" else IMG, "rb").read()
    return _r[which]


def w32(d, a):
    return int.from_bytes(d[a - B_BASE:a - B_BASE + 4], "little")


def fill_runs(d, lo, hi, n=FILL_MIN):
    out, p = [], lo
    while p < hi:
        if d[p - B_BASE] == 0x0E:
            q = p
            while q < hi and d[q - B_BASE] == 0x0E:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ptr_tables(d, lo, hi, minent=PTR_MIN):
    best = {}
    for p in range(lo, hi - 3):
        k, q = 0, p
        while q <= hi - 4 and PTR_LO <= w32(d, q) < PTR_HI:
            k += 1
            q += 4
        if k >= minent:
            best[p] = k
    out, p = [], lo
    while p < hi - 3:
        if p in best:
            out.append((p, p + 4 * best[p]))
            p += 4 * best[p]
        else:
            p += 1
    return out


def ident_runs(d, lo, hi, n=IDENT_MIN):
    """Maximal runs where byte[k] == byte[0]+k, WITHOUT wrapping past 0xFF.

    The no-wrap clause is not cosmetic: at 0xF6A9A9 the byte before the index map
    is 0xFF, the last byte of a `jrl` displacement, and 0xFF,0x00,0x01... extends
    the run backwards into an instruction.  An index map counts up; it does not
    roll over."""
    out, p = [], lo
    while p < hi:
        q = p + 1
        while (q < hi and d[p - B_BASE] + (q - p) <= 0xFF
               and d[q - B_BASE] == d[p - B_BASE] + (q - p)):
            q += 1
        if q - p >= n:
            out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ram_tables(d, lo, hi, minent=RAM_MIN):
    """Maximal chains of >= minent consecutive 4-byte LE words in 0x0001-0xFFFF:
    a table of 16-bit RAM addresses stored one per long word."""
    out, p = [], lo
    while p < hi - 3:
        k, q = 0, p
        while q <= hi - 4 and 0 < w32(d, q) < 0x10000:
            k += 1
            q += 4
        if k >= minent:
            out.append((p, p + 4 * k))
            p = q
        else:
            p += 1
    return out


def bit_tables(d, lo, hi, minent=BIT_MIN):
    """Maximal chains of >= minent consecutive 4-byte LE words with
    w[k] == w[0] << k -- a table of BIT WEIGHTS.  It exists because the ramtab
    rule cannot see one: half a 32-entry 1<<k table has values above 0xFFFF, so
    the chain breaks three times and three single bytes fall out as code."""
    out, p = [], lo
    while p < hi - 3:
        w0 = w32(d, p)
        k, q = 0, p
        if w0:
            while q <= hi - 4 and w32(d, q) == (w0 << (q - p) // 4) & 0xFFFFFFFF \
                    and (w0 << (q - p) // 4) <= 0xFFFFFFFF:
                k += 1
                q += 4
        if k >= minent:
            out.append((p, p + 4 * k))
            p = q
        else:
            p += 1
    return out


def ascii_runs(d, lo, hi, n=ASCII_MIN):
    out, p = [], lo
    while p < hi:
        if 32 <= d[p - B_BASE] < 127:
            q = p
            while q < hi and 32 <= d[q - B_BASE] < 127:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ram_tables_ex(d, lo, hi):
    """ram_tables() minus any chain that overlaps a bit-weight table.

    A 1<<k table read one byte to the left is ALSO a chain of words below
    0x10000 -- 0x0000010E, 0x00000200, 0x00000400 ... -- so at 0xF6C7F6 the two
    rules both fire and disagree by one byte.  The bit-weight reading is the one
    that starts on the byte after a `ret`, so it wins and the ramtab chain that
    straddles it is dropped whole rather than truncated."""
    bt = bit_tables(d, lo, hi)
    out = []
    for a, e in ram_tables(d, lo, hi):
        if any(a < be and bs < e for bs, be in bt):
            continue
        out.append((a, e))
    return out


def barriers(d, lo=LO, hi=HI):
    b = set()
    for a, e in (fill_runs(d, lo, hi) + ptr_tables(d, lo, hi)
                 + ram_tables_ex(d, lo, hi) + bit_tables(d, lo, hi)
                 + ident_runs(d, lo, hi) + ascii_runs(d, lo, hi)):
        b |= set(range(a, e))
    return b


def far_calls(d, lo, hi):
    """`call addr24` / `jp addr24` sites in prom_a+prom_b targeting [lo,hi).
    Opcode-anchored, scanned at every byte: an UPPER BOUND, used only to SEED."""
    out = set()
    for blob in (rom("a"), d):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.add(t)
    return out


def descend(d, lo, hi, seeds, block):
    """Recursive descent that refuses to enter a barrier byte."""
    seen, work = set(), [s for s in seeds if s not in block]
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen and p not in block:
            dec = MT.decode_at(p)
            if dec is None:
                break
            n, txt = dec
            if any((p + i) in block for i in range(n)):
                break
            seen.update(range(p, p + n))
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            for m in re.findall(r"0x00([0-9a-f]{6})", txt):
                v = int(m, 16)
                if lo <= v < hi and v not in seen and v not in block:
                    work.append(v)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen


def gaps_of(lo, hi, seen, block):
    out, p = [], lo
    while p < hi:
        if p in seen or p in block:
            p += 1
            continue
        q = p
        while q < hi and q not in seen and q not in block:
            q += 1
        out.append((p, q))
        p = q
    return out


def selfconsistent(d, s, e, seen):
    """See notes/prom_b_f65000_trace.py -- decode must consume [s,e) exactly, hold
    no undefined opcode, and every relative branch must hit an instruction
    boundary (its own or one the descent already proved)."""
    p, bounds, ins = s, set(), []
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return False, 0
        bounds.add(p)
        ins.append((p, dec[0], dec[1]))
        p += dec[0]
    if p != e:
        return False, 0
    nb = 0
    for a, n, txt in ins:
        if txt.strip().startswith("db"):
            return False, nb
        if not re.match(r"^(jr|jrl|calr)\b", txt):
            continue
        for t in TC.branch_targets(txt):
            nb += 1
            if t not in bounds and t not in seen:
                return False, nb
    return True, nb


def decode_bounds(s, e):
    """Instruction start addresses of a linear decode of [s,e), or None if the
    decode does not consume the run exactly."""
    p, out = s, set()
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return None
        out.add(p)
        p += dec[0]
    return out if p == e else None


def ends_in_flow_end(s, e):
    """Does a linear decode of [s,e) consume it exactly AND end in a flow end?

    ⚠ ADDED 2026-08-25 (round 5), and it is a CORRECTION, not a refinement.
    `selfconsistent()` alone was calibrated in round 4 against pointer tables,
    strings and 0x0E padding only.  Measured against a corpus of proven DATA it
    had never seen -- the 4,011 display-list records of
    notes/FINDINGS-ui-display-list.md, 39,329 bytes whose framing is
    self-checking -- it accepts **13.9%** of record-aligned 16-byte-or-longer
    chunks as code.  Requiring the decode to END in a `ret`/`reti`/unconditional
    `jp`/`jr` -- what a real routine tail looks like -- drops that to **1 of
    1,884 chunks (0.1%)**, and to ZERO at 32 bytes and above.

        python3 notes/prom_b_f0ea9f_layout.py --null-accept

    is the measurement, and it is why `accept()` now requires this.  It cost the
    0xF65000 module four runs (76 bytes) that round 4 emitted as instructions,
    one of which -- 0xF6A475-0xF6A49C -- is a 40-byte lookup table."""
    p, last = s, None
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return False
        last = dec[1]
        p += dec[0]
    return p == e and last is not None and TC.is_flow_end(last)


def accept(d, gaps, seen):
    """Iterate selfconsistent() to a fixpoint over the WHOLE pending set.

    Per pass the candidate boundary set is `seen` plus the linear-decode
    boundaries of every run still pending, so two adjacent routines that branch
    into each other are accepted together.  Without that, three runs at
    0xF68DE1 / 0xF68E70 / 0xF68FC4 -- all obvious code, 52 relative branches
    between them -- deadlock and all three come out as `.byte`."""
    ok, pending = {}, list(gaps)
    for _ in range(20):
        cand = set(seen)
        for s, e in pending:
            b = decode_bounds(s, e)
            if b:
                cand |= b
        grew, still = False, []
        for s, e in pending:
            good, nb = selfconsistent(d, s, e, cand)
            if good and not ends_in_flow_end(s, e):
                good = False                        # see ends_in_flow_end()
            if good:
                ok[(s, e)] = nb
                p = s
                while p < e:
                    seen.add(p)
                    p += MT.decode_at(p)[0]
                grew = True
            else:
                still.append((s, e))
        pending = still
        if not grew:
            break
    return ok, pending


def table_entry_seeds(d, lo, hi):
    """Every in-range target of every entry of every table the PTRTAB rule frames.

    A table the rule frames has a measured false-positive rate of ZERO over
    54,814 bytes of proven code, so its entries are addresses the firmware
    transfers to -- which makes them entry points, and a descent that ignores
    them misses whole handlers.  It missed 4,688 bytes of them here: the 122-byte
    run at 0xF67D6F is entry [8] of FIVE tables and came out as `.byte` until
    this was added."""
    out = set()
    for a, e in ptr_tables(d, lo, hi):
        for x in range(a, e, 4):
            t = w32(d, x)
            if lo <= t < hi:
                out.add(t)
    return out


def build(lo=LO, hi=HI):
    d = rom()
    block = barriers(d, lo, hi)
    seeds = (set(t for _, t in MT.thunk_entries(lo, hi)) | far_calls(d, lo, hi)
             | table_entry_seeds(d, lo, hi))
    seen = descend(d, lo, hi, sorted(seeds), block)
    gaps = gaps_of(lo, hi, seen, block)
    ok, pend = accept(d, gaps, seen)
    kind = ["data"] * (hi - lo)
    for a in seen:
        if lo <= a < hi:
            kind[a - lo] = "code"
    for (a, e) in ok:
        for x in range(a, e):
            kind[x - lo] = "code"
    conflicts = []
    for a, e in ascii_runs(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "ascii"
    for a, e in ident_runs(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "ident"
    for a, e in ram_tables_ex(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "ramtab"
    for a, e in bit_tables(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "bittab"
    for a, e in ptr_tables(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "ptrtab"
    for a, e in fill_runs(d, lo, hi):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = "fill"
    segs, p = [], 0
    while p < hi - lo:
        q = p
        while q < hi - lo and kind[q] == kind[p]:
            q += 1
        segs.append((kind[p], lo + p, q - p))
        p = q
    return segs, conflicts, pend, ok, seen


def source_text(rev=None):
    """The prom_b transcription, from the working tree or from a git revision.

    `--rev REV` exists because the null corpus below is derived from the .s and
    therefore GROWS as rounds convert code; a quoted false-positive count is only
    reproducible if the revision it was measured on is named with it."""
    if rev is None:
        return open(SRC).read()
    import subprocess
    # ⚠ THE IMAGE, not the primary, on the git side too: the working-tree
    # branch above goes through image_path(), and comparing an image with a
    # 494- or 2,517-line master is not a calibration of anything.
    return image_text_at_rev(ROOT, "prom_b/wsa1_prom_b.s", rev)


def proven_code_runs(rev=None):
    """Maximal runs of PROVEN instruction text in prom_b/wsa1_prom_b.s.

    Every instruction line the transcription emits carries a `; ADDR  <mame
    text>` comment, and the byte gate proves the file rebuilds the ROM, so these
    addresses are code beyond argument.  Directive lines (`.byte`, `.ascii`,
    `.long`, `.fill`) carry the same comment shape and are excluded by requiring
    the mnemonic not to start with a dot -- without that exclusion the corpus
    silently includes the data islands it is meant to be a null for."""
    seq = []
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        m = re.search(r";\s*([0-9A-F]{6})\s\s", l)
        ok = bool(m) and body.startswith("\t") and not body.lstrip().startswith(".")
        seq.append(int(m.group(1), 16) if ok else None)
    runs, cur = [], []
    for a in seq:
        if a is None or (cur and a <= cur[-1]):
            if len(cur) > 1:
                runs.append((cur[0], cur[-1]))
            cur = []
        if a is not None:
            cur.append(a)
    if len(cur) > 1:
        runs.append((cur[0], cur[-1]))
    return runs


def barrier_effect(lo=LO, hi=HI):
    """(with_barrier, without_barrier, overlap) byte counts for the code walk.

    The third number is the point: how many bytes the SAME descent claims as
    instructions that the content rules say are a table, a string or padding.
    It is what the barrier removes, and checks() in the generator asserts the
    with-barrier figure is zero.  Recomputed here rather than typed."""
    d = rom()
    block = barriers(d, lo, hi)
    seeds = sorted(set(t for _, t in MT.thunk_entries(lo, hi)) | far_calls(d, lo, hi)
                   | table_entry_seeds(d, lo, hi))
    with_b = descend(d, lo, hi, seeds, block)
    without_b = descend(d, lo, hi, seeds, set())
    return len(with_b), len(without_b), len(without_b & block)


def null(rev=None):
    d = rom()
    runs = proven_code_runs(rev)
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: every maximal run of PROVEN instruction text in")
    print("prom_b/wsa1_prom_b.s @ %s -- %d runs, %d bytes.  A rule that fires"
          % (rev or "WORKING TREE", len(runs), tot))
    print("inside one of these runs is a FALSE POSITIVE.")
    if rev is None:
        print("  \u26a0 this corpus GROWS as rounds convert code; quote it with"
              " --rev REV.")
    tests = [("ptrtab >= %d" % PTR_MIN, lambda a, b: ptr_tables(d, a, b)),
             ("ramtab >= %d" % RAM_MIN, lambda a, b: ram_tables_ex(d, a, b)),
             ("bittab >= %d" % BIT_MIN, lambda a, b: bit_tables(d, a, b)),
             ("ident  >= %d" % IDENT_MIN, lambda a, b: ident_runs(d, a, b)),
             ("ascii  >= %d" % ASCII_MIN, lambda a, b: ascii_runs(d, a, b)),
             ("ascii  >= 10 (rejected)", lambda a, b: ascii_runs(d, a, b, 10)),
             ("ascii  >=  8 (rejected)", lambda a, b: ascii_runs(d, a, b, 8))]
    for name, f in tests:
        hits = []
        for s, e in runs:
            hits += f(s, e)
        print("  %-24s false positives: %2d   %s"
              % (name, len(hits), " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:4])))
    print("  The two rejected ASCII thresholds are printed so the choice of %d"
          % ASCII_MIN)
    print("  is visible as a measurement rather than a preference.")


def main():
    if "--null" in sys.argv:
        rev = None
        if "--rev" in sys.argv:
            rev = sys.argv[sys.argv.index("--rev") + 1]
        null(rev)
        return 0
    segs, conflicts, pend, ok, seen = build()
    d = rom()
    if "--seeds" in sys.argv:
        block = barriers(d, LO, HI)
        base = set(t for _, t in MT.thunk_entries(LO, HI)) | far_calls(d, LO, HI)
        extra = table_entry_seeds(d, LO, HI)
        a = descend(d, LO, HI, sorted(base), block)
        b = descend(d, LO, HI, sorted(base | extra), block)
        print("in-range targets of PTRTAB entries: %d (%d already seeds, "
              "%d inside a barrier)"
              % (len(extra), len(extra & base), len(extra & block)))
        print("descent WITHOUT table-entry seeds: %6d bytes" % len(a))
        print("descent WITH    table-entry seeds: %6d bytes" % len(b))
        print("the table entries are worth        %6d bytes" % (len(b) - len(a)))
        return 0
    if "--barrier" in sys.argv:
        wb, nb, ov = barrier_effect()
        print("code walk WITH the barrier:    %6d bytes (%.1f%% of %d)"
              % (wb, 100.0 * wb / (HI - LO), HI - LO))
        print("code walk WITHOUT the barrier: %6d bytes (%.1f%%)"
              % (nb, 100.0 * nb / (HI - LO)))
        print("of those, %d bytes are inside an object a content rule framed --"
              % ov)
        print("that is what the barrier removes.")
        return 0
    if "--conflicts" in sys.argv:
        print("descent bytes reclaimed by a barrier rule: %d  (MUST be 0)"
              % len(conflicts))
        for a in conflicts[:80]:
            print("  0x%06X" % a)
        return 0
    if "--residue" in sys.argv:
        print("runs that are neither code, table, string nor padding: %d (%d bytes)"
              % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - B_BASE:e - B_BASE]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "." for c in raw[i:i + 16])))
            print()
        return 0
    if "--python" in sys.argv:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        return 0
    tot = {}
    for k, s, n in segs:
        print("  %-6s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d"
          % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
    print("  segments %d   accepted self-consistent runs %d   barrier conflicts %d"
          % (len(segs), len(ok), len(conflicts)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
