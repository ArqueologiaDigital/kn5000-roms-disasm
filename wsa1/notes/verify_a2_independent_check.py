#!/usr/bin/env python3
"""VERIFY-A2: an independent re-derivation of kernel_three_way_v2.py's byte tiers.

QUESTION IT ANSWERS
  "Does the WSA1 kernel's BYTE evidence for the KN5000 survive being recomputed by
  code that shares nothing with notes/kernel_three_way_v2.py?"  Written by the
  verification lane, deliberately naive: plain bytes.find, no anchors, no phases,
  no unidasm.  It re-derives T1 (whole-routine byte-identical) and T2 (longest
  byte-identical window) and prints the ADDRESSES so they can be compared with v2's.

WHAT IT SHARES WITH v2, AND WHY THAT IS ALL
  Only the routine extents, and those come from notes/prom_c_kernel_map.py, which is
  COMMITTED (2707125), unmodified, and whose --pairs tiling is checked from the first
  row through the last against the published block end.  Everything downstream --
  the corpus enumeration, the address mapping, the search, the null -- is rewritten
  here from the KN5000 Makefile and .ld files:
      maincpu        addr = 0xE00000 + file offset          (v7/maincpu/maincpu.ld)
      subcpu boot    addr = 0xFE0000 + file offset          (subcpu/boot/subcpu_boot.ld)
      subcpu payload SPLICED, Makefile:635-641 builds it as .full[0:256] ++
                     .full[60416:] with .full based at 0x0400, so
                        off <  256 : addr = 0x0400 + off
                        off >= 256 : addr = off + 0x0400 + 60160
  The null is the same routine bytes shuffled with a fixed seed: same length, same
  byte histogram, no structure.

RUN
  python3 notes/verify_a2_independent_check.py
"""
import ast, glob, os, random, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KN_ROMS = "/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs"
PROM_BASE = 0xF80000


def pairs_from_kernel_map():
    """The PAIRS table out of notes/prom_c_kernel_map.py, parsed with ast so no
    regex over source text is involved.  Rows are (name, prom_c addr, prom_a addr,
    length)."""
    tree = ast.parse(open(os.path.join(ROOT, "notes", "prom_c_kernel_map.py")).read())
    got = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name) and t.id in ("PAIRS", "INTT3_PAIR"):
                    got[t.id] = ast.literal_eval(node.value)
    if "PAIRS" not in got or "INTT3_PAIR" not in got:
        raise SystemExit("PAIRS/INTT3_PAIR not found in prom_c_kernel_map.py")
    # the file's own tuple order is (prom_c addr, prom_a addr, length, name, expected)
    rows = [(r[3], r[0], r[1], r[2]) for r in list(got["PAIRS"]) + [got["INTT3_PAIR"]]]
    rows.sort(key=lambda r: r[1])          # by prom_c address; INTT3 sits BELOW the block
    return rows


def addr_of(fname, off):
    """File offset -> CPU address, from the .ld / Makefile facts quoted above."""
    if fname.startswith("kn5000_v") and fname.endswith("_program.rom"):
        return 0xE00000 + off
    if fname == "kn5000_subcpu_boot.ic30":
        return 0xFE0000 + off
    if fname.startswith("kn5000_subprogram_v") and fname.endswith(".rom") \
            and "compressed" not in fname:
        return (0x0400 + off) if off < 256 else (off + 0x0400 + 60160)
    if fname.startswith("wsa1_prom_a"):
        return 0xF80000 + off
    if fname.startswith("wsa1_prom_b"):
        return 0xF00000 + off
    return off


def longest_window(pat, img):
    """Longest substring of pat that occurs in img, by brute force over lengths.
    Naive on purpose: it is the check, not the product."""
    best, bestoff = 0, None
    n = len(pat)
    for i in range(n):
        if n - i <= best:
            break
        lo, hi = best, n - i          # try to beat `best` from this start
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if img.find(pat[i:i + mid]) >= 0:
                lo = mid
            else:
                hi = mid - 1
        if lo > best:
            best, bestoff = lo, img.find(pat[i:i + lo])
    return best, bestoff


def main():
    rows = pairs_from_kernel_map()
    prom_c = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
    print("routine extents from notes/prom_c_kernel_map.py PAIRS+INTT3_PAIR: %d rows, "
          "0x%06X-0x%06X" % (len(rows), min(r[1] for r in rows),
                             max(r[1] + r[3] for r in rows) - 1))

    bodies = []
    for name, ca, aa, n in rows:
        bodies.append((name, prom_c[ca - PROM_BASE:ca - PROM_BASE + n]))
    print("total bytes: %d" % sum(len(b) for _, b in bodies))

    rnd = random.Random(20260830)
    nulls = []
    for name, b in bodies:
        lb = list(b)
        rnd.shuffle(lb)
        nulls.append((name, bytes(lb)))

    # ⚠ the six images v2 says carry the kernel, plus in-corpus negatives.  The full
    # 40-image sweep is v2's job; this script exists to recompute the byte tiers, and a
    # naive longest-window is O(len(routine) * log) finds per image.
    files = ["kn5000_v7_program.rom", "kn5000_v9_program.rom", "kn5000_v10_program.rom",
             "kn5000_subprogram_v140.rom", "kn5000_subprogram_v141.rom",
             "kn5000_subprogram_v142.rom", "kn5000_subcpu_boot.ic30",
             "kn5000_custom_data.ic19", "kn5000_table_data.rom",
             "kn5000_subprogram_v142_compressed.rom", "hd-ae5000_v2_06i.ic4"]
    files = [f for f in files if os.path.isfile(os.path.join(KN_ROMS, f))]
    extra = [("wsa1_prom_a.ic12", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")),
             ("wsa1_prom_b.ic13", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"))]
    targets = extra + [(f, os.path.join(KN_ROMS, f)) for f in files]

    print("\n%-46s %4s %5s %5s   %s" % ("image", "T1", "T2", "null", "T1 hits (addr)"))
    for fname, path in targets:
        img = open(path, "rb").read()
        t1 = []
        for name, b in bodies:
            o = img.find(b)
            if o >= 0:
                t1.append((name, len(b), addr_of(fname, o)))
        t2 = max(longest_window(b, img)[0] for _, b in bodies)
        nl = max(longest_window(b, img)[0] for _, b in nulls)
        note = ""
        if t1:
            note = ", ".join("%s %dB @0x%06X" % x for x in t1)
        print("%-46s %4d %5d %5d   %s" % (fname[:46], len(t1), t2, nl, note))

    # ★ the LAST row of the table, not just the first -- this project's signature failure
    lastname, lb = bodies[-1]
    firstname, fb = bodies[0]
    print("\nFIRST row %-28s %3d bytes at prom_c 0x%06X" % (firstname, len(fb), rows[0][1]))
    print("LAST  row %-28s %3d bytes at prom_c 0x%06X" % (lastname, len(lb), rows[-1][1]))
    for fname in ("kn5000_v7_program.rom", "kn5000_subprogram_v142.rom"):
        img = open(os.path.join(KN_ROMS, fname), "rb").read()
        for nm, bb in ((firstname, fb), (lastname, lb)):
            w, o = longest_window(bb, img)
            print("  %-30s in %-30s longest window %3d B at 0x%06X"
                  % (nm, fname, w, addr_of(fname, o) if o is not None else 0))
    provenance()
    return 0


def provenance():
    """The three things the byte tiers do not settle, each a searched negative.

    (a) v2's --selftest asserts the naming agreement is independent by globbing
        prom_*/*.s -- but the kernel body has MOVED to kernel/kernel.s, so that glob
        no longer covers it.  Re-run over EVERY .s in the tree.
    (b) v2 checks that direction only.  Check the REVERSE echo too: if the KN5000 tree
        had imported a WSA1 kernel name, the agreement would be circular that way.
    (c) the corpus arithmetic v2 prints: 44 files, 4 listings, 40 binaries, and v1's 41
        = 40 - (binaries under 4,096 B) + 4.
    """
    print("\nPROVENANCE OF THE NAMING AGREEMENT")
    kn_tags = ("TaskSched_", "TaskMsgQ_", "TaskTimer_", "TaskMsg_", "TaskQueue_")
    hits = []
    for f in glob.glob(os.path.join(ROOT, "**", "*.s"), recursive=True):
        txt = open(f, errors="replace").read()
        hits += [(os.path.relpath(f, ROOT), t) for t in kn_tags if t in txt]
    print("  (a) KN5000 scheduler names in ANY .s of the WSA1 tree "
          "(%d files incl. kernel/): %s"
          % (len(glob.glob(os.path.join(ROOT, "**", "*.s"), recursive=True)),
             hits or "NONE"))

    wsa_tags = ("Kernel_InitRam", "Kernel_ResumeTask", "MsgQueue_Send", "SoftTimer_Register")
    kn_root = os.path.dirname(KN_ROMS)
    rhits = []
    for pat in ("**/*.s", "symbols/*.txt"):
        for f in glob.glob(os.path.join(kn_root, pat), recursive=True):
            txt = open(f, errors="replace").read()
            rhits += [(os.path.relpath(f, kn_root), t) for t in wsa_tags if t in txt]
    print("  (b) WSA1 kernel names anywhere in the KN5000 sources/symbols: %s"
          % (rhits or "NONE"))

    files = sorted(os.listdir(KN_ROMS))
    lis = [f for f in files if f.endswith(".unidasm")]
    bins = [f for f in files if not f.endswith(".unidasm")]
    small = [f for f in bins if os.path.getsize(os.path.join(KN_ROMS, f)) < 4096]
    print("  (c) corpus: %d files = %d binaries + %d text listings; %d binaries < 4096 B"
          % (len(files), len(bins), len(lis), len(small)))
    print("      v1's \"41 images\" = %d - %d + %d = %d"
          % (len(bins), len(small), len(lis), len(bins) - len(small) + len(lis)))


if __name__ == "__main__":
    sys.exit(main())
