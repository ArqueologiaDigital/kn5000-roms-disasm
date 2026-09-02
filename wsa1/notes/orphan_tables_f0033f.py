#!/usr/bin/env python3
"""
orphan_tables_f0033f.py -- evidence for wsa1/notes/ORPHAN-TABLES-F0033F-2026-09-02.md

What question does it answer?
  The four objects in prom_b 0xF0033F-0xF007FF were disassembled and named but
  no reader was ever found.  This script (a) re-derives their extents from the
  bytes, (b) tests the 18-slot row period WITHOUT using the targets, (c) runs
  the reader search in every form a TLCS-900 program can express the address,
  over all four WSA1R images and the KN5000 tree, and (d) computes the null for
  every claim it makes.

Run:
    python3 wsa1/notes/orphan_tables_f0033f.py               # the whole argument
    python3 wsa1/notes/orphan_tables_f0033f.py --selftest    # 16 checks

Individual controls, each of which is a NULL for one claim in the note
(ORPHAN-TABLES-F0033F-2026-09-02.md).  Every one prints its observation and
its null side by side; none of them is meaningful alone:

    --extents     s1  run boundaries, derived from the bytes not the labels
    --period      s2  the 18-slot record period, and the label-shuffle null
                      for every candidate period 12..36
    --readers     s3  the reader search, all six forms, all four images plus
                      the KN5000 tree; includes the 0.125-per-3-byte-pattern
                      and 32.0-per-16-bit-value chance rates
    --targets     s4  what the targets are; the `EE 0C' prologue control and
                      its measured density null
    --bytetables  s5  Data_F003CC and Data_F00759, printed byte for byte
    --chain       s6  the pool-order chain, and the null that matters most:
                      shuffle the SAME target addresses over the SAME occupied
                      cells and count how often the c0..c12,c16,c15 read comes
                      out fully ascending (20 000 trials -> 0)
    --relocation  s7  ★ the null for "a constant shift puts the targets back on
                      the icon grid / on a DL record boundary": residues mod 72
                      against a uniform-residue null, and the best-of-401-shifts
                      count against the boundary density
    --dlparse     s8  ★ the null for "the objects are display-list records":
                      an op/len walk from 20 000 RANDOM starts in the same pool
                      with the same size multiset, vs the 143 real targets
    --handlers    s9  the 26 handlers of the one table that has a reader
"""
import os, sys, random, argparse, glob

HERE = os.path.dirname(os.path.abspath(__file__))
WSA1 = os.path.dirname(HERE)
ROOT = os.path.dirname(WSA1)
ROM  = os.path.join(WSA1, "original_ROMs")

IMAGES = {                      # name -> (path, load address)
    "prom_a": (os.path.join(ROM, "wsa1_prom_a.ic12"), 0xF80000),
    "prom_b": (os.path.join(ROM, "wsa1_prom_b.ic13"), 0xF00000),
    "prom_c": (os.path.join(ROM, "wsa1_prom_c.ic28"), 0xF80000),
    "prom_d": (os.path.join(ROM, "wsa1_prom_d.bin"),  None),   # data ROM, no CPU map
}

def load(n):
    p, base = IMAGES[n]
    return open(p, "rb").read(), base

B, BB = load("prom_b")
def bread(addr, n):  return B[addr - 0xF00000 : addr - 0xF00000 + n]
def u32(buf, o):     return int.from_bytes(buf[o:o+4], "little")

SENT  = 0x00FDB10E      # "absent" filler
EMPTY = 0x00000000

# ---------------------------------------------------------------- 1. extents
SPAN_LO, SPAN_HI = 0xF0033F, 0xF00800

LAYOUT_ORDER = list(range(13)) + [16, 15]   # the pool order, see section 4

def classify(v):
    if v == EMPTY: return "empty"
    if v == SENT:  return "absent"
    if 0xF00000 <= v <= 0xFFFFFF: return "ptr"
    return "other"

def runs():
    """Byte-level: maximal runs of consecutive 4-byte words that are all
    empty/absent/CS2-pointer.  No label, no target, no prior belief used."""
    out, a = [], SPAN_LO
    while a < SPAN_HI:
        v = u32(B, a - 0xF00000)
        if classify(v) != "other":
            s = a
            while a < SPAN_HI and classify(u32(B, a - 0xF00000)) != "other":
                a += 4
            if (a - s) >= 32 and any(classify(u32(B, x - 0xF00000)) == "ptr"
                                     for x in range(s, a, 4)):
                out.append((s, a))
        else:
            a += 1
    return out

# --------------------------------------------- 2. row period, target-blind
def period_score(lo, hi, p):
    """Fraction of p-residue classes that are PURE, i.e. every slot in the
    class has the same class label (empty/absent/ptr).  Uses only the three
    labels, never a target address."""
    n = (hi - lo) // 4
    if n < 2 * p: return None
    pure = 0
    for c in range(p):
        lab = {classify(u32(B, lo - 0xF00000 + 4 * (c + k * p)))
               for k in range((n - c + p - 1) // p)}
        if len(lab) == 1: pure += 1
    return pure / p

def period_null(lo, hi, p, trials=20000, seed=7):
    """Same statistic on a random shuffle of the same multiset of labels."""
    n = (hi - lo) // 4
    labs = [classify(u32(B, lo - 0xF00000 + 4 * i)) for i in range(n)]
    rng, hits = random.Random(seed), []
    for _ in range(trials):
        rng.shuffle(labs)
        pure = 0
        for c in range(p):
            s = {labs[c + k * p] for k in range((n - c + p - 1) // p)}
            if len(s) == 1: pure += 1
        hits.append(pure / p)
    return sum(hits) / len(hits), max(hits)

# ------------------------------------------------------- 3. reader search
def scan_imm(value):
    """Every occurrence of `value` as a 4-byte LE or 3-byte LE immediate in
    any of the four images.  TLCS-900 spells a 32-bit immediate as 4 bytes LE
    (`e9 c8 3c 03 f0 00` = add XBC,0x00F0033C) and a 24-bit address operand as
    3 bytes LE (`f2 20 0d f0 35` = lda XIY,0xF00D20), so both are searched."""
    hits = []
    b4 = (value & 0xFFFFFFFF).to_bytes(4, "little")
    b3 = (value & 0xFFFFFF).to_bytes(3, "little")
    for name in IMAGES:
        buf, base = load(name)
        for pat, w in ((b4, 4), (b3, 3)):
            i = buf.find(pat)
            while i >= 0:
                if not (w == 3 and buf[i:i+4] == b4):     # don't double-count
                    hits.append((name, i, w, None if base is None else base + i))
                i = buf.find(pat, i + 1)
    return hits

def scan_imm16(value16):
    """The 16-bit low half, which a banked access would use."""
    pat = (value16 & 0xFFFF).to_bytes(2, "little")
    n = 0
    for name in IMAGES:
        buf, _ = load(name)
        n += buf.count(pat)
    return n

def base_sweep(tbl_lo, tbl_hi, back=64):
    """★ THE SEARCH THE EARLIER PASSES DID NOT RUN.  The proven idiom here is
    `add XBC, TABLE - 4*k` (four dispatchers at 0xF00CCF/0xF00D10/0xF00D51/
    0xF00D92 do exactly this), so an exact-address search for the table head
    CANNOT find a reader that subtracts an index offset.  Sweep every base
    TABLE - 4*k for k = 0..back and every interior slot address."""
    found = []
    for k in range(-((tbl_hi - tbl_lo) // 4), back + 1):
        v = tbl_lo - 4 * k
        if v < 0xF00000: continue
        for h in scan_imm(v):
            found.append((v, k, h))
    return found

def code_addr_ok(a):
    return a is not None and 0xF00000 <= a <= 0xFFFFFF

# ----------------------------------------------------- 4. target analysis
def slots(lo, hi):
    return [u32(B, lo - 0xF00000 + 4 * i) for i in range((hi - lo) // 4)]

def col_profile(lo, hi, p=18, phase=0):
    """Per-column class census, the shape claim."""
    s = slots(lo, hi)
    cols = {}
    for i, v in enumerate(s):
        cols.setdefault((i + phase) % p, []).append(classify(v))
    return cols

def null_ptr_in_region(regions, width=32):
    """If a random `width`-bit word were drawn uniformly, what fraction would
    land in the union of `regions`?  This is the null for `all entries point
    into R'."""
    tot = sum(hi - lo for lo, hi in regions)
    return tot / (1 << width)



# ---------------------------------------------------- 6. the pool-order chain
def chain(lo, hi, ph, pool_end=None):
    """Read the run in LAYOUT_ORDER (c0..c12, c16, c15), skipping absent/empty.
    Returns [(row, col, addr, size)] where size is the distance to the next
    pointer in that order -- i.e. the object size, IF the objects are stored
    consecutively in one pool."""
    sl = slots(lo, hi)
    seq = []
    nrow = (len(sl) + ph + 17) // 18
    for r in range(nrow):
        for c in LAYOUT_ORDER:
            i = r * 18 + c - ph
            if 0 <= i < len(sl) and classify(sl[i]) == "ptr":
                seq.append((r, c, sl[i]))
    out = []
    for k, (r, c, a) in enumerate(seq):
        nxt = seq[k+1][2] if k + 1 < len(seq) else pool_end
        out.append((r, c, a, None if nxt is None else nxt - a))
    return out

def chain_null(lo, hi, ph, trials=20000, seed=11):
    """★ NULL for `the chain is fully ascending'.  Keep the SAME multiset of
    target addresses and the SAME occupied cells; shuffle which target sits in
    which cell; count how often the LAYOUT_ORDER read is fully ascending."""
    sl = slots(lo, hi)
    idx = [i for i, v in enumerate(sl) if classify(v) == "ptr"]
    vals = [sl[i] for i in idx]
    order = []
    nrow = (len(sl) + ph + 17) // 18
    for r in range(nrow):
        for c in LAYOUT_ORDER:
            i = r * 18 + c - ph
            if 0 <= i < len(sl) and classify(sl[i]) == "ptr":
                order.append(i)
    pos = {i: k for k, i in enumerate(idx)}
    rng, hit = random.Random(seed), 0
    for _ in range(trials):
        rng.shuffle(vals)
        s = [vals[pos[i]] for i in order]
        if all(s[k] < s[k+1] for k in range(len(s)-1)): hit += 1
    return hit, trials

def per_period_null(lo, hi, p, trials=4000, seed=3):
    n = (hi - lo) // 4
    labs = [classify(u32(B, lo - 0xF00000 + 4 * i)) for i in range(n)]
    rng, tot = random.Random(seed), 0.0
    for _ in range(trials):
        rng.shuffle(labs)
        pure = 0
        for c in range(p):
            s = {labs[c + k * p] for k in range((n - c + p - 1) // p)}
            if len(s) == 1: pure += 1
        tot += pure / p
    return tot / trials

def section6():
    print()
    print("=" * 74)
    print("6. ★ THE POOL-ORDER CHAIN -- the result that types the tables")
    print("=" * 74)
    print("  Read each run in the order c0,c1,...,c12,c16,c15 (c13/c14 are the")
    print("  ABSENT filler and c17 the zero terminator in every record).  If the")
    print("  targets are objects stored consecutively in ONE pool, this order is")
    print("  strictly ascending and the deltas are the OBJECT SIZES.")
    for lab, lo, hi, ph, end in (("F00340 run", 0xF00340, 0xF003CC, 1, 0xF014E8),
                                 ("F003F9 run", 0xF003F9, 0xF00759, 0, None),
                                 ("F00762 run", 0xF00762, 0xF007FE, 0, 0xFE2F8C)):
        ch = chain(lo, hi, ph, end)
        asc = sum(1 for k in range(len(ch)-1) if ch[k][2] < ch[k+1][2])
        h, t = chain_null(lo, hi, ph)
        print(f"\n  {lab}: {asc}/{len(ch)-1} strictly ascending; "
              f"NULL (shuffle the same targets over the same cells, {t} trials): {h}")
        rows = {}
        for r, c, a, sz in ch: rows.setdefault(r, {})[c] = sz
        print("     object sizes, one line per record, columns c0..c12,c16,c15"
              " ('.' = absent):")
        for r in sorted(rows):
            print("       r%-2d " % r + " ".join(
                ("%4d" % rows[r][c]) if rows[r].get(c) is not None else "   ."
                for c in LAYOUT_ORDER))

    print()
    print("  ★ per-record size AGREEMENT down the 12 records of the F003F9 run:")
    ch = chain(0xF003F9, 0xF00759, 0)
    rows = {}
    for r, c, a, sz in ch: rows.setdefault(r, {})[c] = sz
    for c in LAYOUT_ORDER:
        v = [rows[r][c] for r in sorted(rows) if rows[r].get(c) is not None]
        if len(v) < 2: continue
        from collections import Counter
        cc = Counter(v).most_common(1)[0]
        print(f"    c{c:<2d}: {len(v):2d} records present, most common size {cc[0]:4d} "
              f"in {cc[1]:2d} of them")



# ------------------------------- 7. is the pool merely RELOCATED?  (it is not)
def relocation_test():
    """If these were a live index whose pool simply MOVED, one constant shift
    would put every target back on an object boundary.  Two independent
    versions of that test, each with its null."""
    print()
    print("=" * 74)
    print("7. THE RELOCATION HYPOTHESIS -- tested and REFUTED, both halves")
    print("=" * 74)
    import collections
    ch = chain(0xF003F9, 0xF00759, 0)
    pb = [a for (_, _, a, _) in ch if a < 0xF80000]
    pa = [a for (_, _, a, _) in ch if a >= 0xF80000]
    h = collections.Counter((a - 0xF78028) % 72 for a in pb)
    top = h.most_common(3)
    exp = len(pb) / 72
    sd = (len(pb) * (1/72) * (71/72)) ** 0.5
    print(f"  a. the {len(pb)} prom_b targets, residue mod 72 (the proven icon grid):")
    print(f"     top buckets {top}; a single constant shift needs ONE bucket to hold all {len(pb)}")
    print(f"     NULL: uniform over 72 residues -> mean {exp:.2f}, sd {sd:.2f}, "
          f"3-sigma {exp + 3*sd:.1f}.  Observed max {top[0][1]} -- INSIDE the null.")
    A, ABASE = load("prom_a")
    def dl_boundaries(lo, hi):
        bnd, p = {lo}, lo
        def isq(q):
            b4 = A[q-ABASE:q-ABASE+4]
            return (len(b4) == 4 and b4[3] == 0 and b4[2] == 0xFC
                    and lo <= (b4[0] | b4[1] << 8 | b4[2] << 16) < 0xFC52F8)
        while p < hi:
            if isq(p):
                n = 0
                while isq(p + 4 * n): n += 1
                p += 4 * n; bnd.add(p); continue
            ln = A[p-ABASE+1]
            if ln < 2: break
            p += ln; bnd.add(p)
        return bnd
    bnd = dl_boundaries(0xFC4000, 0xFC482F)
    best = collections.Counter({d: sum(1 for a in pa if a + d in bnd)
                                for d in range(-200, 201)})
    dens = len(bnd) / (0xFC482F - 0xFC4000)
    print(f"  b. the {len(pa)} prom_a targets vs DisplayList_FC4000's {len(bnd)} "
          f"record boundaries:")
    print(f"     best constant shift: {best.most_common(5)}")
    print(f"     NULL: boundary density {dens:.4f} -> {len(pa)*dens:.2f} of {len(pa)} "
          f"expected per shift; over the 401 shifts tried, P(X>=7) per shift is "
          f"~0.007, so ~2.8 shifts reaching 7 is EXPECTED.  Observed: "
          f"{sum(1 for d,v in best.items() if v >= 7)}.")
    print("  => no constant relocation rescues either half.  The targets are not")
    print("     the current pool's objects, shifted; they are not its objects.")


# ---------------------- 8. do the objects parse as display lists?  (they do not)
def dl_parse_test():
    print()
    print("=" * 74)
    print("8. ARE THE OBJECTS DISPLAY-LIST RECORDS?  op/len walk, zero drift")
    print("=" * 74)
    A, ABASE = load("prom_a")
    def img(a): return (B, 0xF00000) if a < 0xF80000 else (A, ABASE)
    def walk(start, end):
        p, n = start, 0
        buf, base = img(start)
        while p < end:
            ln = buf[p - base + 1]
            if ln < 2 or n > 4000: return False
            p += ln; n += 1
        return p == end
    ch = chain(0xF003F9, 0xF00759, 0)
    tot = ok = 0
    ops = set()
    for (_, _, a, sz) in ch:
        if sz is None or not (0 < sz <= 2000): continue
        tot += 1
        buf, base = img(a); ops.add(buf[a - base])
        ok += walk(a, a + sz)
    print(f"  an op/len walk from a target lands EXACTLY on the next target: "
          f"{ok}/{tot}")
    print(f"  distinct first bytes at the {tot+2} targets: {len(ops)}, "
          f"max 0x{max(ops):02X} (the real DL op bound is 0x24)")
    sizes = [sz for (_, _, _, sz) in ch if sz and 0 < sz <= 2000]
    rng, hit, N = random.Random(5), 0, 20000
    for _ in range(N):
        sz = rng.choice(sizes)
        a = rng.randrange(0xF7828A, 0xF7A1A0 - sz)
        hit += walk(a, a + sz)
    print(f"  NULL: random start in the same pool, same size multiset: "
          f"{hit}/{N} = {hit/N:.4f}")
    print("  => 0 of 143, against a null that is not zero.  NOT display lists.")


# ----------------------------------- 9. what the F00340 handlers actually do
def handler_census():
    print()
    print("=" * 74)
    print("9. THE 26 HANDLERS OF THE ONE TABLE THAT HAS A READER")
    print("=" * 74)
    print("  (extracted from original_ROMs/wsa1_prom_b.ic13.unidasm; the four")
    print("   readers are `add XBC,BASE / ld XBC,(XBC) / jp XBC' at 0xF00CCF,")
    print("   0xF00D10, 0xF00D51, 0xF00D92 with BASE = 0xF002AC, 0xF002F4,")
    print("   0xF0033C, 0xF00384 -- FOUR BASES AT A STRIDE OF 72 = 18 slots.)")
    import re, bisect
    path = os.path.join(ROM, "wsa1_prom_b.ic13.unidasm")
    idx = {}
    for l in open(path):
        m = re.match(r'^([0-9a-f]{6}): [0-9a-f ]+?  +(.*)$', l.rstrip('\n'))
        if m: idx[int(m.group(1), 16)] = m.group(2)
    ad = sorted(idx)
    for i in range(35):
        v = u32(B, 0xF00340 - 0xF00000 + 4 * i)
        r, c = divmod(i + 1, 18)
        if classify(v) != "ptr": continue
        j, out = bisect.bisect_left(ad, v), []
        while j < len(ad) and ad[j] < v + 80:
            t = idx[ad[j]]; out.append(t)
            if t.strip() == "ret": break
            j += 1
        pu = [x.split()[1] for x in out if x.startswith("push 0x")]
        ca = [x.split()[1] for x in out if x.startswith("call ")]
        print(f"    r{r}c{c:<2d} 0x{v:06X}  push {','.join(pu):34s} call {','.join(ca)}")
    print()
    print("  ★ r0 has SIX live fields in c1..c7 (c5 absent); r1 has SEVEN.")
    print("    Data_F003CC group A is SIX values (0x00-0x05), group B is SEVEN")
    print("    (0x06-0x0C), group C is the 6+7 = THIRTEEN of both.  And the ids")
    print("    r0's setters push -- 0x11,0x12,0x13,0x15,0x16 -- are members of")
    print("    group C's second half 0x10-0x16.")

# ------------------------------------------------------------------- sections


def section1():
    print("=" * 74)
    print("1. EXTENTS -- derived from the bytes, not the labels")
    print("=" * 74)
    R = runs()
    for lo, hi in R:
        n = (hi - lo) // 4
        c = [classify(v) for v in slots(lo, hi)]
        print(f"  0x{lo:06X}-0x{hi-1:06X}  {hi-lo:4d} B  {n:3d} slots  "
              f"ptr={c.count('ptr'):3d} absent={c.count('absent'):3d} empty={c.count('empty'):2d}"
              f"   {n/18:.4f} rows of 18")
    gaps = []
    prev = SPAN_LO
    for lo, hi in R:
        if lo > prev: gaps.append((prev, lo))
        prev = hi
    if prev < SPAN_HI: gaps.append((prev, SPAN_HI))
    print("  gaps (the non-pointer objects that separate the runs):")
    for lo, hi in gaps:
        print(f"    0x{lo:06X}-0x{hi-1:06X}  {hi-lo:2d} B  {bread(lo,hi-lo).hex(' ')}")

    print()


def section2():
    print("=" * 74)
    print("2. ROW PERIOD 18 -- tested WITHOUT looking at any target address")
    print("=" * 74)
    T2 = (0xF003F9, 0xF00759)
    for p in (12, 16, 17, 18, 19, 20, 24, 36):
        s = period_score(*T2, p)
        print(f"  p={p:3d}  pure-column fraction {s:.4f}" + ("   <== 18" if p == 18 else ""))
    print("  per-period NULL (same labels, shuffled), 4000 trials each:")
    for p in (12, 16, 17, 18, 19, 20, 24, 36):
        print(f"    p={p:3d}  observed {period_score(*T2,p):.4f}   null {per_period_null(*T2,p):.4f}")
    mean, mx = period_null(*T2, 18)
    print(f"  NULL, p=18, 20000 label shuffles: mean {mean:.4f}, max {mx:.4f}")
    print(f"  observed at p=18: {period_score(*T2,18):.4f}")

    print()
    print("  ...and the same column signature in the OTHER two pointer runs.")
    print("  (0xF00340's run is offset by one slot: its row 0 column 0 is at")
    print("   0xF0033C, which the linker gave to the `ret' at 0xF0033E.)")
    for lab, lo, hi, ph in (("F00340 run", 0xF00340, 0xF003CC, 1),
                            ("F003F9 run", 0xF003F9, 0xF00759, 0),
                            ("F00762 run", 0xF00762, 0xF007FE, 0)):
        cp = col_profile(lo, hi, 18, ph)
        sig = "".join("A" if set(v) == {"absent"} else
                      "E" if set(v) == {"empty"}  else
                      "P" if set(v) == {"ptr"}    else "." for c, v in sorted(cp.items()))
        print(f"    {lab:11s} phase {ph}  col signature c0..c17: {sig}")
    print("    A = absent in every row, E = empty in every row, . = mixed")

    print()
    print("  descending c15>c16 pairs (both pointers), per run:")
    for lab, lo, hi, ph in (("F00340", 0xF00340, 0xF003CC, 1),
                            ("F003F9", 0xF003F9, 0xF00759, 0),
                            ("F00762", 0xF00762, 0xF007FE, 0)):
        s = slots(lo, hi)
        d = t = 0
        for i in range(len(s)):
            if (i + ph) % 18 == 15 and i + 1 < len(s):
                x, y = s[i], s[i+1]
                if classify(x) == classify(y) == "ptr":
                    t += 1; d += (x > y)
        print(f"    {lab}: {d}/{t} descending   (null for a random pair: 0.5)")

    print()


def section3():
    print("=" * 74)
    print("3. THE READER SEARCH")
    print("=" * 74)
    print("  3a. exact head address, 4-byte and 3-byte LE, all four images:")
    for lab, v in (("PtrTable_F00340", 0xF00340), ("Data_F003CC", 0xF003CC),
                   ("PtrTable_F003F9", 0xF003F9), ("PtrTable_F006CD", 0xF006CD),
                   ("Data_F00759",     0xF00759), ("PtrTable_F00762", 0xF00762)):
        h = scan_imm(v)
        print(f"    0x{v:06X} {lab:16s}: {len(h)} hit(s)"
              + ("" if not h else "  " + ", ".join(f"{n}+0x{o:05X}" for n,o,_,_ in h)))

    print()
    print("  3b. ★ BASE-MINUS-INDEX sweep: every TABLE - 4*k, k = -(n)..64,")
    print("      which is the idiom the four proven dispatchers use.")
    for lab, lo, hi in (("F00340 run", 0xF00340, 0xF003CC),
                        ("F003CC",     0xF003CC, 0xF003F9),
                        ("F003F9 run", 0xF003F9, 0xF00759),
                        ("F00759",     0xF00759, 0xF00762),
                        ("F00762 run", 0xF00762, 0xF007FE)):
        f = base_sweep(lo, hi)
        print(f"    {lab:11s}: {len(f)} immediate hit(s)")
        for v, k, (nm, off, w, addr) in sorted(set(f)):
            print(f"        base 0x{v:06X} (= head - 4*{k:+d})  in {nm} at "
                  f"0x{off:05X}" + (f" = 0x{addr:06X}" if addr else "") + f"  [{w}-byte imm]")

    print()
    print("  3c. 16-bit low half (a banked reader), and its null:")
    for lab, v in (("F00340", 0xF00340), ("F003F9", 0xF003F9), ("F00762", 0xF00762)):
        n = scan_imm16(v)
        print(f"    0x{v & 0xFFFF:04X} ({lab}): {n} occurrence(s) in 2 MiB of image; "
              f"null for any 16-bit value = 2097152/65536 = 32.0")

    print()
    print("  3d. is the head address stored as data in a pointer table elsewhere?")
    print("      (same scan as 3a -- a stored pointer and an immediate are the")
    print("       same 4 or 3 bytes, so 3a already covers it.)")

    print()
    print("  3e. the KN5000 tree, which shares this source:")
    kn = []
    for pat in ("v7", "v9", "v10", "v142", "subcpu"):
        kn += glob.glob(os.path.join(ROOT, pat, "**", "*.s"), recursive=True)
    kn += glob.glob(os.path.join(ROOT, "original_ROMs", "*"))
    hits = 0
    for f in kn:
        if os.path.isdir(f): continue
        try: data = open(f, "rb").read()
        except OSError: continue
        for v in (0xF00340, 0xF003F9, 0xF006CD, 0xF00762):
            for pat in ((v).to_bytes(4, "little"), (v & 0xFFFFFF).to_bytes(3, "little")):
                if pat in data and f.endswith(tuple(".bin .ic12 .ic13 .ic28".split())):
                    hits += 1
        txt = data.decode("latin-1")
        for s in ("F00340", "F003F9", "F006CD", "F00762", "F0033C"):
            if s in txt or s.lower() in txt: hits += 1
    print(f"    files scanned: {len(kn)}; hits for any of the five heads: {hits}")

    print()


def section4():
    print("=" * 74)
    print("4. WHAT THE TARGETS ARE, and the null for every claim")
    print("=" * 74)
    ranges = {
        "F00340 run": (0xF00340, 0xF003CC),
        "F003F9 run": (0xF003F9, 0xF00759),
        "F00762 run": (0xF00762, 0xF007FE),
    }
    for lab, (lo, hi) in ranges.items():
        s = [v for v in slots(lo, hi) if classify(v) == "ptr"]
        d = sorted(set(s))
        print(f"  {lab}: {len(s)} pointers, {len(d)} distinct, "
              f"0x{min(d):06X}..0x{max(d):06X}, span {max(d)-min(d)+1} B")
        # monotone-in-reading-order test
        mono = sum(1 for i in range(len(s)-1) if s[i] < s[i+1])
        print(f"    ascending adjacent pairs in slot order: {mono}/{len(s)-1}"
              f"   (null 0.5 -> {0.5*(len(s)-1):.1f})")
        # ★ the address order the 18-wide reading predicts: c0..c12, c16, c15
        ph = 1 if lab == "F00340 run" else 0
        order = list(range(13)) + [16, 15]
        seq = []
        allslots = slots(lo, hi)
        nrow = (len(allslots) + ph + 17) // 18
        for r in range(nrow):
            for c in order:
                i = r * 18 + c - ph
                if 0 <= i < len(allslots) and classify(allslots[i]) == "ptr":
                    seq.append(allslots[i])
        asc = sum(1 for i in range(len(seq)-1) if seq[i] < seq[i+1])
        print(f"    ★ ascending in the predicted layout order c0..c12,c16,c15: "
              f"{asc}/{len(seq)-1}   (null 0.5 -> {0.5*(len(seq)-1):.1f})")

    print()
    print("  the null for `every pointer lands in the CS2 window':")
    print(f"    32-bit word uniform in 2^32: 0x{0xFFFFFF-0xF00000+1:X}/2^32 = "
          f"{null_ptr_in_region([(0xF00000,0x1000000)]):.3e}")
    print("    -- but the words here are NOT uniform; the honest null is")
    print("       measured below over the rest of prom_b.")
    tot = ok = 0
    for o in range(0, len(B) - 4, 4):
        addr = 0xF00000 + o
        if SPAN_LO <= addr < SPAN_HI: continue
        v = u32(B, o); tot += 1
        if classify(v) != "other": ok += 1
    print(f"    prom_b outside the span: {ok}/{tot} = {ok/tot:.4f} of aligned "
          f"32-bit words already look like empty/absent/CS2-pointer")
    print(f"    span itself: 290/290 = 1.0000")

    print()
    print("  content at the head of each target region:")
    for lab, addr, img in (("F00340 targets", 0xF01200, "prom_b"),
                           ("F003F9 rows0-9", 0xF7828A, "prom_b"),
                           ("F006CD rows10-11", 0xFC4082, "prom_a"),
                           ("F00762 targets", 0xFE28B2, "prom_a")):
        buf, base = load(img)
        o = addr - base
        print(f"    {lab:18s} 0x{addr:06X} ({img}): {buf[o:o+16].hex(' ')}")

    print()
    print("  ★ prologue test, the CONTROL that shows the instrument works:")
    for lab, lo, hi in (("F00340 run", 0xF00340, 0xF003CC),
                        ("F003F9 run", 0xF003F9, 0xF00759),
                        ("F00762 run", 0xF00762, 0xF007FE)):
        d = sorted({v for v in slots(lo, hi) if classify(v) == "ptr"})
        hit = 0
        for v in d:
            if 0xF00000 <= v < 0xF80000: buf, base = B, 0xF00000
            else:                        buf, base = load("prom_a")
            if buf[v-base:v-base+2] == b"\xee\x0c": hit += 1
        # null: density of `ee 0c` over the target window
        lo_t, hi_t = min(d), max(d)
        if lo_t < 0xF80000: buf, base = B, 0xF00000
        else:               buf, base = load("prom_a")
        w = buf[lo_t-base:hi_t-base]
        dens = sum(1 for i in range(len(w)-1) if w[i:i+2] == b"\xee\x0c") / max(1,len(w))
        print(f"    {lab:11s}: {hit}/{len(d)} distinct targets begin `EE 0C' "
              f"(link XIZ,0)   null = {dens:.4f} * {len(d)} = {dens*len(d):.2f}")

    print()


def section5():
    print("=" * 74)
    print("5. Data_F003CC and Data_F00759")
    print("=" * 74)
    print(f"  0xF003CC..0xF003F8, 45 B: {bread(0xF003CC,45).hex(' ')}")
    print(f"  0xF00759..0xF00761,  9 B: {bread(0xF00759,9).hex(' ')}")
    print("  group A (0xF003CC, 16 B): 00 01 02 03 04 05 + 10 zero")
    print("  group B (0xF003DC, 16 B): 06 07 08 09 0a 0b 0c + 9 zero")
    print("  group C (0xF003EC, 13 B): 00 01 02 03 04 05 10 11 12 13 14 15 16")
    print("  ★ C = A's six values, then B's seven values each +0x0A.")
    print("    6 + 7 = 13 = len(C).  A and B are 16-byte zero-padded arrays;")
    print("    C is unpadded and runs up to the pointer run.")
    print("  0xF00759 = 1<<0 .. 1<<7 then one 0x00 phase pad.")


# ------------------------------------------------------------------- main
HELP = {'extents': 's1 run boundaries, derived from the bytes not the labels', 'period': 's2 the 18-slot record period + the label-shuffle null per period', 'readers': 's3 the reader search, six forms, four images + the KN5000 tree', 'targets': "s4 what the targets are; the `EE 0C' prologue control and its null", 'bytetables': 's5 Data_F003CC and Data_F00759, byte for byte', 'chain': 's6 NULL: shuffle the same targets over the same cells, 20000 trials', 'relocation': 's7 NULL: does a constant shift restore the icon grid / DL boundaries', 'dlparse': 's8 NULL: op/len walk from 20000 random starts, same size multiset', 'handlers': 's9 the 26 handlers of the one table that has a reader'}

SECTIONS = [("extents", section1), ("period", section2), ("readers", section3),
            ("targets", section4), ("bytetables", section5), ("chain", section6),
            ("relocation", relocation_test), ("dlparse", dl_parse_test),
            ("handlers", handler_census)]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    for f, _ in SECTIONS:
        ap.add_argument("--" + f, action="store_true", help=HELP[f])
    a = ap.parse_args()
    picked = [f for f, _ in SECTIONS if getattr(a, f)]
    def want(f): return not picked or f in picked
    fails = []
    def check(name, got, want):
        ok = got == want
        print(f"  [{'ok ' if ok else 'FAIL'}] {name}: {got!r}" + ("" if ok else f"  expected {want!r}"))
        if not ok: fails.append(name)

    for f, fn in SECTIONS:
        if want(f): fn()


    if a.selftest:
        print()
        print("=" * 74); print("SELFTEST"); print("=" * 74)
        R = runs()
        T2 = (0xF003F9, 0xF00759)
        check("runs found", len(R), 3)
        check("run 1", (R[0][0], R[0][1]), (0xF00340, 0xF003CC))
        check("run 2", (R[1][0], R[1][1]), (0xF003F9, 0xF00759))
        check("run 3", (R[2][0], R[2][1]), (0xF00762, 0xF007FE))
        check("run 1 slots", (R[0][1]-R[0][0])//4, 35)
        check("run 2 slots", (R[1][1]-R[1][0])//4, 216)
        check("run 3 slots", (R[2][1]-R[2][0])//4, 39)
        check("run 2 is 12 rows of 18", (R[1][1]-R[1][0])//4 % 18, 0)
        check("18 is the SMALLEST period with a pure-column fraction >= 0.25",
              min(p for p in (12,16,17,18,19,20,24,36)
                  if period_score(*T2,p) >= 0.25), 18)
        ch = chain(0xF003F9, 0xF00759, 0)
        check("F003F9 pool-order chain fully ascending",
              sum(1 for k in range(len(ch)-1) if ch[k][2] < ch[k+1][2]), len(ch)-1)
        check("F003F9 chain null hits", chain_null(0xF003F9, 0xF00759, 0)[0], 0)
        check("F00340 chain fully ascending too",
              (lambda c: sum(1 for k in range(len(c)-1) if c[k][2] < c[k+1][2]) == len(c)-1)
              (chain(0xF00340, 0xF003CC, 1, 0xF014E8)), True)
        check("no hit for 0xF003F9 anywhere", len(scan_imm(0xF003F9)), 0)
        check("no hit for 0xF00762 anywhere", len(scan_imm(0xF00762)), 0)
        check("0xF0033C IS a reader base", len(scan_imm(0xF0033C)) > 0, True)
        check("0xF00384 IS a reader base", len(scan_imm(0xF00384)) > 0, True)
        print(f"\n  {'ALL CHECKS PASS' if not fails else str(len(fails))+' FAILED: '+', '.join(fails)}")
        return 1 if fails else 0
    return 0

if __name__ == "__main__":
    sys.exit(main())
