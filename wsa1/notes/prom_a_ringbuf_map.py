#!/usr/bin/env python3
"""What is prom_a 0xF84000-0xF84C6B, and how many ring buffers does CPU 1 own?

QUESTION IT ANSWERS
  `notes/prom_a_call_graph.py --modules` ranks prom_b thunk module T_F41CD0-T_F41EC4
  (126 slots, reference upper bound 245) as the largest high-reference prom_a module
  still `.incbin`.  Its 126 slots land in 0xF842DF-0xF84BBC, and every one of them is
  a five-instruction veneer of the form

        push IX / push XHL / lda XHL,<object> / call <class routine> / pop / pop / ret

  This script reads BOTH halves out of the ROM and reports them as one object:

    1. the CLASS at 0xF84000-0xF842DE -- five operations x five ring capacities,
       recognised by exact byte template, with the capacity read out of the `minc1`
       wrap mask (or the `ld (XHL+0xfe),nn` initial value for Init);
    2. the INSTANCES at 0xF842DF-0xF84C6B -- for each veneer, the object address from
       its `lda XHL,nnn` and the class routine from its `call`/target;
    3. the capacity CONSISTENCY check that is the actual evidence: an instance's
       capacity is established only because every veneer of that instance names a
       class routine of the SAME capacity.  A ring whose veneers disagreed would be
       an unnamed object here, not a guessed one.

WHAT IT IS NOT
  It does not prove what any ring CARRIES.  Object addresses are RAM addresses; the
  producer and consumer of each ring are outside this module and outside this script.

RUN
  python3 notes/prom_a_ringbuf_map.py            # the class, the instances, checks
  python3 notes/prom_a_ringbuf_map.py --veneers  # every veneer, one per line
  python3 notes/prom_a_ringbuf_map.py --asm      # label names for the .s
Exit status is non-zero if any self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
BASE = 0xF80000
B_BASE = 0xF00000
CLASS_LO, CLASS_HI = 0xF84000, 0xF842DF
BANK_LO, BANK_HI = 0xF842DF, 0xF84C6C
TBL_LO, TBL_HI = 0x40000, 0x44018

FAIL = []


def chk(msg, cond):
    print("  %-64s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def by(a, n):
    return A[a - BASE:a - BASE + n]


def w16(a):
    return A[a - BASE] | A[a - BASE + 1] << 8


def a24(a):
    return A[a - BASE] | A[a - BASE + 1] << 8 | A[a - BASE + 2] << 16


# ---------------------------------------------------------------- the class
# Each class routine is a fixed byte template with ONE variable field: the wrap
# mask of `minc1 mask,IX` (dc 38 lo hi) or Init's `ld (XHL+0xfe),cap-1`.
# The templates are written out in full so a changed byte fails the match rather
# than being absorbed.
GET = ("20 00 9b F8 24 9b FC f4 6e 05 30 ff ff 68 0f c3 07 ec f0 21 dc 38 ?? ?? "
       "bb F8 54 9b fe 61 0e")
SCAN = ("20 00 9b F6 24 9b FA f4 6e 05 30 ff ff 68 0c c3 07 ec f0 21 dc 38 ?? ?? "
        "bb F6 54 0e")
PUT = ("9b fe 3f 00 00 6e 05 30 ff ff 68 15 9b FC 24 f3 07 ec f0 41 dc 38 ?? ?? "
       "bb FC 54 9b fe 69 9b fe 20 0e")
INIT = ("bb f6 02 00 00 bb f8 02 00 00 bb fc 02 00 00 bb fa 02 00 00 "
        "bb fe 02 ?? ?? 0e")


def match(tpl, addr, **fix):
    """Does the template match at addr?  Returns (length, [variable bytes]) or None.

    A field written as a capital letter in the template is substituted from **fix,
    so the three cursor-pair variants of Get/Scan share one template text."""
    toks = tpl.split()
    var = []
    for i, t in enumerate(toks):
        b = A[addr - BASE + i]
        if t == "??":
            var.append(b)
        elif t.isupper() and len(t) == 2 and not t[0].isdigit():
            if b != fix[t]:
                return None
        elif b != int(t, 16):
            return None
    return len(toks), var


def class_routines():
    """[(addr, family, capacity)] for 0xF84000-0xF842DE, walked with no gaps."""
    out = []
    a = CLASS_LO
    while a < CLASS_HI:
        for fam, tpl, fix in (
                # consuming read: cursor -8 against producer -4, bumps the free count
                ("Get", GET, dict(F8=0xf8, FC=0xfc)),
                # look-ahead read: cursor -10 against the snapshot limit -6
                ("Scan", SCAN, dict(F6=0xf6, FA=0xfa)),
                # look-ahead read: cursor -10 against the live producer index -4
                ("ScanToPut", SCAN, dict(F6=0xf6, FA=0xfc)),
                ("Put", PUT, dict(FC=0xfc)),
                ("Init", INIT, {})):
            m = match(tpl, a, **fix)
            if m:
                n, var = m
                cap = (var[0] | var[1] << 8) + 1
                out.append((a, fam, cap, n))
                a += n
                break
        else:
            out.append((a, "UNMATCHED", 0, 0))
            return out
    return out


# ------------------------------------------------------------- the instances
def bank_veneers(cls):
    """[(addr, len, kind, object, target)] for every routine in the veneer bank."""
    cls_at = {a: (f, c) for a, f, c, _ in cls}
    out = []
    a = BANK_LO
    while a < BANK_HI:
        b = by(a, 24)
        # 1) `push IX / push XHL / lda XHL,obj / call cls / pop XHL / pop IX / ret`
        if b[0] == 0x2C and b[1] == 0x3B and b[2] == 0xF2 and b[7] == 0x1D:
            obj = b[3] | b[4] << 8 | b[5] << 16
            tgt = b[8] | b[9] << 8 | b[10] << 16
            out.append((a, 14, cls_at.get(tgt, ("?", 0))[0], obj, tgt))
            a += 14
            continue
        # 2) `link / push IX / push XHL / ld A,(XIZ+8) / lda XHL,obj / call Put / ...`
        if b[:4] == bytes([0xEE, 0x0C, 0x00, 0x00]) and b[4] == 0x2C and b[6] == 0x8E:
            obj = b[10] | b[11] << 8 | b[12] << 16
            tgt = b[15] | b[16] << 8 | b[17] << 16
            out.append((a, 23, "Put1", obj, tgt))
            a += 23
            continue
        # 3) the block-put loop
        if b[:4] == bytes([0xEE, 0x0C, 0x00, 0x00]) and b[4] == 0x3D:
            obj = b[14] | b[15] << 8 | b[16] << 16
            tgt = b[21] | b[22] << 8 | b[23] << 16
            out.append((a, 35, "PutBlock", obj, tgt))
            a += 35
            continue
        # 4) IsEmpty: push BC / ld WA,0 / ld BC,(obj-4) / cp BC,(obj-8) / ...
        if b[0] == 0x29 and b[1] == 0x30 and b[4] == 0xD2:
            obj = (b[5] | b[6] << 8 | b[7] << 16) + 4
            out.append((a, 21, "IsEmpty", obj, 0))
            a += 21
            continue
        # 5) cursor copy: push WA / ld WA,(src) / ld (dst),WA / pop WA / ret
        if b[0] == 0x28 and b[1] == 0xD2 and b[6] == 0xF2:
            src = b[2] | b[3] << 8 | b[4] << 16
            dst = b[7] | b[8] << 8 | b[9] << 16
            # -10 := -8 is a scan rewind, -8 := -6 a commit; which one this is
            # cannot be told from the two addresses alone (both differ by 2), so
            # it is resolved below against the object its own group names.
            out.append((a, 13, "CursorCopy", src, dst))
            a += 13
            continue
        if b[0] == 0x0E:
            out.append((a, 1, "ret", 0, 0))
            a += 1
            continue
        out.append((a, 0, "UNMATCHED", 0, 0))
        return out
    return out


def all_refs():
    """{target: [(kind, site)]} for every literal control transfer in prom_a+prom_b.

    Three spellings, all of them: the absolute `call nnn` (0x1D) and `jp nnn`
    (0x1B), and the PC-relative `calr d16` (0x1E), `jr cc,d8` (0x60-0x6F) and
    `jrl cc,d16` (0x70-0x7F).  Opcode-anchored at every byte offset, so a hit is
    a CANDIDATE and the counts are upper bounds -- what the scan is exact about
    is ABSENCE.  This is the same discipline notes/prom_a_xref.py states, plus
    the relative forms that tool does not resolve.
    """
    out = {}
    for blob, base in ((A, BASE), (B, B_BASE)):
        n = len(blob)
        for i in range(n - 3):
            o = blob[i]
            t = k = None
            if o in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                k = "call" if o == 0x1D else "jp"
            elif o == 0x1E:
                d = int.from_bytes(blob[i + 1:i + 3], "little", signed=True)
                t, k = base + i + 3 + d, "calr"
            elif 0x60 <= o <= 0x6F:
                d = int.from_bytes(blob[i + 1:i + 2], "little", signed=True)
                t, k = base + i + 2 + d, "jr"
            elif 0x70 <= o <= 0x7F:
                d = int.from_bytes(blob[i + 1:i + 3], "little", signed=True)
                t, k = base + i + 3 + d, "jrl"
            if t is not None:
                out.setdefault(t, []).append((k, base + i))
    return out


def thunk_targets():
    """{target: [slot,...]} for the whole prom_b routine directory."""
    out = {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = B[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            out.setdefault(s[1] | s[2] << 8 | s[3] << 16, []).append(B_BASE + o)
    return out


def instances(ven):
    """Group the bank into instances: a new group starts at each Get veneer."""
    groups, cur = [], []
    for v in ven:
        if v[2] == "Get" and cur:
            groups.append(cur)
            cur = [v]
        else:
            cur.append(v)
    if cur:
        groups.append(cur)
    return groups


def main():
    cls = class_routines()
    ven = bank_veneers(cls)
    grp = instances(ven)
    th = thunk_targets()

    fams = {}
    for a, f, c, _ in cls:
        fams.setdefault(f, []).append((a, c))
    print("CLASS  0xF84000-0xF842DE   %d routines" % len(cls))
    caps = sorted({c for _, _, c, _ in cls})
    print("  capacities present: " + ", ".join("0x%X" % c for c in caps))
    print("  %-10s %s" % ("family", "  ".join("0x%X" % c for c in caps)))
    for f in ("Get", "Scan", "ScanToPut", "Put", "Init"):
        row = dict((c, a) for a, c in fams.get(f, []))
        print("  %-10s %s" % (f, "  ".join("0x%06X" % row[c] if c in row else "--"
                                           for c in caps)))
    print()

    if "--veneers" in sys.argv:
        for a, n, k, o, t in ven:
            print("  0x%06X %2d  %-11s obj 0x%06X  -> 0x%06X" % (a, n, k, o, t))
        print()

    cap_of = {a: c for a, f, c, _ in cls}
    print("INSTANCES  0xF842DF-0xF84C6B   %d group(s)" % len(grp))
    print("  %-8s %-10s %-9s %-6s %-6s %s"
          % ("group", "ring", "capacity", "start", "bytes", "published slots"))
    # resolve each group's cursor copies against the object the group names
    for gi, g in enumerate(grp):
        named = {v[3] for v in g if v[2] not in ("ret", "CursorCopy")}
        if len(named) != 1:
            continue
        obj = next(iter(named))
        for vi, v in enumerate(g):
            if v[2] != "CursorCopy":
                continue
            src, dst = v[3], v[4]
            kind = ("ScanRewind" if dst == obj - 10 and src == obj - 8 else
                    "GetCommit" if dst == obj - 8 and src == obj - 6 else "CursorCopy")
            g[vi] = (v[0], v[1], kind, obj, 0)

    rows = []
    for i, g in enumerate(grp):
        objs = {v[3] for v in g if v[2] != "ret"}
        cs = {cap_of[v[4]] for v in g if v[4] in cap_of}
        slots = sum(len(th.get(v[0], [])) for v in g)
        lo = g[0][0]
        n = sum(v[1] for v in g)
        obj = sorted(objs)[0] if len(objs) == 1 else 0
        cap = sorted(cs)[0] if len(cs) == 1 else 0
        rows.append((lo, n, obj, cap, cs, objs, slots))
        print("  %-8d 0x%06X   %-9s 0x%06X %-6d %d"
              % (i, obj, "0x%X" % cap if cap else "MIXED %s" % cs, lo, n, slots))
    print()

    if "--asm" in sys.argv:
        for a, f, c, _ in cls:
            print("Ring_%s_%X:            ; 0x%06X" % (f, c, a))
        for i, (lo, n, obj, cap, _, _, _) in enumerate(rows):
            print("; group %d  ring 0x%06X cap 0x%X at 0x%06X" % (i, obj, cap, lo))
        return 0

    refs = all_refs()
    if "--refs" in sys.argv:
        for a, f, c, _ in cls:
            r = [x for x in refs.get(a, []) if not (BANK_LO <= x[1] < BANK_HI)]
            print("  class 0x%06X %-10s cap 0x%-5X  outside-bank refs %d %s"
                  % (a, f, c, len(r), ["%s@0x%06X" % x for x in r][:4]))
        for g in grp:
            for v in g:
                r = refs.get(v[0], [])
                if r:
                    print("  bank  0x%06X %-11s refs %s"
                          % (v[0], v[2], ["%s@0x%06X" % x for x in r][:6]))
        return 0

    print("self-checks")
    chk("class walk reached 0xF842DE with no unmatched byte",
        all(f != "UNMATCHED" for _, f, _, _ in cls)
        and cls[-1][0] + cls[-1][3] == CLASS_HI)
    chk("class is exactly 5 families x 5 capacities = 25 routines",
        len(cls) == 25 and len(caps) == 5
        and all(len(fams[f]) == 5 for f in ("Get", "Scan", "ScanToPut", "Put", "Init")))
    chk("the five capacities are 0x80 0x100 0x200 0x400 0x1000",
        caps == [0x80, 0x100, 0x200, 0x400, 0x1000])
    chk("Init's free-space seed is capacity-1 for every capacity",
        all(w16(a + 23) == c - 1 for a, f, c, _ in cls if f == "Init"))
    chk("bank walk reached 0xF84C6B with no unmatched byte",
        all(v[2] != "UNMATCHED" for v in ven)
        and ven[-1][0] + ven[-1][1] == BANK_HI)
    chk("every instance names ONE ring object", all(r[2] for r in rows))
    chk("every instance names ONE capacity", all(r[3] for r in rows))
    chk("15 groups, 14 of them published, 9 slots each",
        len(rows) == 15 and sorted(r[6] for r in rows) == [0] + [9] * 14)
    chk("published slots total the module's 126",
        sum(r[6] for r in rows) == 126)
    # the unpublished 15th group is a byte-for-byte copy of the 14th
    g14, g15 = rows[13], rows[14]
    chk("the unpublished group is a byte copy of the previous one",
        g14[1] == g15[1] and by(g14[0], g14[1]) == by(g15[0], g15[1]))
    chk("... and both name the same ring", g14[2] == g15[2])
    # Every group is the same 11-routine template, in the same order.  Two of the
    # eleven are a bare `ret` and are the two slots the directory does not publish.
    SIG = ["Get", "Put1", "PutBlock", "IsEmpty", "Init", "ScanRewind", "Scan",
           "ret", "ScanToPut", "ret", "GetCommit"]
    chk("every group is the same 11-routine template in the same order",
        all([v[2] for v in g] == SIG for g in grp))
    chk("every group is 163 bytes", all(r[1] == 163 for r in rows))
    # LAST-ELEMENT TEST: the final routine of the final group, at the top of the
    # bank, must be that template's last entry and must sit exactly at 0xF84C5F.
    chk("last routine in the bank is 0xF84C5F, a GetCommit on the last ring",
        grp[-1][-1][2] == "GetCommit" and grp[-1][-1][0] == 0xF84C5F
        and grp[-1][-1][0] + grp[-1][-1][1] == BANK_HI)
    objs = sorted({r[2] for r in rows})
    chk("ring objects are distinct except for the duplicated one",
        len(objs) == 14)
    # ★ The control block is 10 bytes BELOW the object pointer and the ring is
    # `capacity` bytes above it -- so [obj-10, obj+capacity) is one allocation.
    # Eleven of the fourteen rings TILE a single RAM region under that reading,
    # end to end with no gap and no overlap.  Nothing forces that to be true, so
    # it is the strongest evidence in this note that the layout is what it says.
    cap_by_obj = {r[2]: r[3] for r in rows}
    chain = sorted(o for o in objs if 0x600800 <= o < 0x602000)
    ok, at = True, chain[0] - 10
    for o in chain:
        if o - 10 != at:
            ok = False
        at = o + cap_by_obj[o]
    chk("eleven rings tile 0x600800-0x601E6E end to end, no gap, no overlap",
        ok and len(chain) == 11 and chain[0] - 10 == 0x600800 and at == 0x601E6E)
    # ★ SEARCHED NEGATIVES.  Each is a claim about a SEARCH, so the search is
    # re-run here rather than quoted: all_refs() resolves absolute call/jp AND
    # the PC-relative calr/jr/jrl over both prom_a and prom_b.
    outside = {a: [x for x in refs.get(a, []) if not (BANK_LO <= x[1] < BANK_HI)]
               for a, f, c, _ in cls}
    chk("no site OUTSIDE the veneer bank calls any class routine",
        not any(outside.values()))
    used = {v[4] for g in grp for v in g if v[4]}
    chk("the bank uses only the 0x100/0x200/0x400 class routines",
        {c for a, f, c, _ in cls if a in used} == {0x100, 0x200, 0x400})
    chk("the 0x80 and 0x1000 class routines have NO reference anywhere",
        not any(refs.get(a) for a, f, c, _ in cls if c in (0x80, 0x1000)))
    chk("nothing in prom_a or prom_b names SeqBuf_AppendEvent (0xF830C6)",
        not refs.get(0xF830C6))
    chk("0xF83120 is named exactly once, by the jp at 0xF82EBF",
        [x for x in refs.get(0xF83120, []) if x[0] in ("jp", "call")]
        == [("jp", 0xF82EBF)])
    chk("0xF83197 is named only by the five calr sites inside its own module",
        {x[1] for x in refs.get(0xF83197, [])}
        == {0xF8318F, 0xF831C4, 0xF831D1, 0xF831DE, 0xF831EB})
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
