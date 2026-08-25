#!/usr/bin/env python3
"""Audit round 1 of wave 5 (prom_a FDC+control, prom_b 0xF65000, prom_c preset bank).

WHY THIS EXISTS
  The byte gate is blind to names and comments.  Every number below is one the
  round reports quote but no committed script re-derives; this script re-derives
  them from the ROM and from the .s, so the audit's findings can be re-run.

WHAT EACH CHECK ANSWERS
  1 curve shapes      Is `Ctrl_Curve_Expo128` (0xF89DB4) exponential?  It is not:
                      it sits ABOVE the 0..127 diagonal everywhere (concave /
                      log-like).  The two CONVEX tables in the same tiling are
                      0xF89E34 and 0xF89EB4, neither named "Expo".
  2 Plus1 delta       Is `Ctrl_Curve_Compressed_Plus1` "one higher"?  No:
                      21 bytes +1, 19 bytes -1, 88 equal -- which is what
                      notes/prom_a_ctrl_checks.py:171 already asserts, while
                      prom_a/wsa1_prom_a.s:6481 says "one higher".
  3 header depth      How many of the round's new prom_a labels carry the full
                      Called from / Inputs / Outputs / Evidence / Unknown header
                      the report claims for 53 of them?
  4 stale comments    Which comments still say "still .incbin" / "not converted"
                      about an address THIS round converted?
  5 frontier phantoms Where do prom_c's remaining frontier entries come FROM,
                      and did converting the f64 pool add any?
  6 coverage delta    substantive/filler/incbin at a git rev vs the worktree.

RUN
    python3 notes/audit_wave5_checks.py            # checks 1-4 (fast, local)
    python3 notes/audit_wave5_checks.py --coverage HEAD
Exit status is non-zero if any check's stated expectation fails.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
SIZE = 524288
fails = []


def check(label, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + label + (("   " + detail) if detail else ""))
    if not ok:
        fails.append(label)


def rom_a():
    return open(A, "rb").read()


# ---- 1. curve shapes -------------------------------------------------------
CURVES = [("Identity128", 0xF89AB4, 128), ("Compressed", 0xF89B34, 128),
          ("Compressed_Plus1", 0xF89BB4, 128), ("Identity128_Copy", 0xF89C34, 128),
          ("Wide256_A", 0xF89CB4, 256), ("Expo128", 0xF89DB4, 128),
          ("Unreferenced128", 0xF89E34, 128), ("Wide256_B", 0xF89EB4, 256)]


def curve_shapes():
    d = rom_a()
    print("1. curve shape vs the straight line from v[0] to v[last]")
    dev = {}
    for name, base, n in CURVES:
        v = list(d[base - 0xF80000:base - 0xF80000 + n])
        dev[name] = sum(v[i] - (i * v[-1]) // (n - 1) for i in range(n)) / n
        shape = ("CONCAVE/log-like" if dev[name] > 2 else
                 "CONVEX/expo-like" if dev[name] < -2 else "~linear")
        print("     %-18s n=%3d  v[1/4]=%3d v[1/2]=%3d v[3/4]=%3d  mean dev %+6.1f  %s"
              % (name, n, v[n // 4], v[n // 2], v[3 * n // 4], dev[name], shape))
    check("Expo128 is CONCAVE, i.e. NOT exponential", dev["Expo128"] > 2,
          "mean dev %+.1f" % dev["Expo128"])
    check("the CONVEX tables are Unreferenced128 and Wide256_B, not Expo128",
          dev["Unreferenced128"] < -2 and dev["Wide256_B"] < -2)
    check("Identity128 and Identity128_Copy are byte-identical",
          d[0xF89AB4 - 0xF80000:0xF89AB4 - 0xF80000 + 128]
          == d[0xF89C34 - 0xF80000:0xF89C34 - 0xF80000 + 128])


# ---- 2. the Plus1 delta ----------------------------------------------------
def plus1_delta():
    d = rom_a()
    a = d[0xF89B34 - 0xF80000:0xF89B34 - 0xF80000 + 128]
    b = d[0xF89BB4 - 0xF80000:0xF89BB4 - 0xF80000 + 128]
    up = sum(1 for i in range(128) if b[i] - a[i] == 1)
    dn = sum(1 for i in range(128) if b[i] - a[i] == -1)
    eq = sum(1 for i in range(128) if b[i] == a[i])
    print("2. Compressed_Plus1 - Compressed: %d equal, %d +1, %d -1" % (eq, up, dn))
    check("the differences are NOT all +1 (label and 0xF89BB4's comment say they are)",
          dn > 0, "%d of the %d differences are -1" % (dn, up + dn))
    check("...and the split is 21 up / 19 down, as prom_a_ctrl_checks.py asserts",
          (up, dn, eq) == (21, 19, 88))


# ---- 3. header depth -------------------------------------------------------
FIELDS = ("Called from", "Inputs", "Outputs", "Evidence", "Unknown")


def header_depth(new_labels):
    src = open(SRC_A).read().split("\n")
    blocks, i = [], 0
    while i < len(src):
        if re.match(r"^; -{10,}", src[i]):
            j, body = i + 1, []
            while j < len(src) and src[j].startswith(";") and not re.match(r"^; -{10,}", src[j]):
                body.append(src[j])
                j += 1
            blocks.append(body)
            i = j
        else:
            i += 1
    rows = []
    for b in blocks:
        if not b:
            continue
        m = re.match(r"^; (\w+)", b[0])
        if not m or m.group(1) not in new_labels:
            continue
        f = {m2.group(1) for m2 in
             (re.match(r"^;\s*(%s)\s*:" % "|".join(FIELDS), l) for l in b) if m2}
        rows.append((m.group(1), f))
    fdc = [r for r in rows if r[0].startswith("Fdc_")]
    ctrl = [r for r in rows if r[0].startswith("Ctrl")]
    full = lambda rs: sum(1 for _, f in rs if set(FIELDS) <= f)
    print("3. header depth over the labels this round ADDED to prom_a")
    print("     new Fdc_  labels with a header block: %d, of which FULL (all five fields): %d"
          % (len(fdc), full(fdc)))
    print("     new Ctrl  labels with a header block: %d, of which FULL: %d"
          % (len(ctrl), full(ctrl)))
    check("fewer than 53 FDC headers carry all five fields", full(fdc) < 53,
          "%d do" % full(fdc))
    return len(fdc), full(fdc), len(ctrl), full(ctrl)


# ---- 4. stale "still .incbin" comments -------------------------------------
ROUND_RANGES = [(0xFE54EC, 0xFE594C), (0xFE5A41, 0xFE6851),
                (0xFE6E3A, 0xFE6E84), (0xF89800, 0xF8A000)]


def stale_comments():
    print("4. comments calling an address THIS round converted 'still .incbin'/'not converted'")
    hits = []
    for i, l in enumerate(open(SRC_A), 1):
        low = l.lower()
        if "corrected 2026-08-25" in low:
            continue
        if not any(k in low for k in ("still `.incbin`", "still .incbin", "not converted")):
            continue
        for m in re.finditer(r"0x([0-9A-Fa-f]{6})\b", l):
            a = int(m.group(1), 16)
            if any(s <= a < e for s, e in ROUND_RANGES):
                hits.append((i, "0x%06X" % a, l.strip()[:100]))
                break
    for h in hits:
        print("     prom_a/wsa1_prom_a.s:%d  %s  %s" % h)
    check("no stale 'still .incbin' comment survives", not hits, "%d survive" % len(hits))
    return hits


# ---- 5. frontier phantom attribution ---------------------------------------
def frontier_sources():
    print("5. where prom_c's remaining frontier entries come FROM")
    try:
        out = subprocess.run([sys.executable, os.path.join(ROOT, "notes", "prom_c_frontier.py")],
                             capture_output=True, text=True, timeout=3600).stdout
    except Exception as e:
        print("     SKIP (%s)" % type(e).__name__)
        return
    frm = [int(x, 16) for x in re.findall(r"from (0x[0-9A-F]{6})", out)]
    tgt = [int(x, 16) for x in re.findall(r"^  (0x[0-9A-F]{6})", out, re.M)]
    zones = {"DescriptorStrings 0xFCCA82-0xFCD0F6": (0xFCCA82, 0xFCD0F6),
             "data zone 0xFDD2AB-0xFDF7DF": (0xFDD2AB, 0xFDF7DF),
             "byte-code zone 0xFCD0F7-0xFDD2AA": (0xFCD0F7, 0xFDD2AA),
             "Float64_ConstantPool 0xFCB27E-0xFCB4E5": (0xFCB27E, 0xFCB4E5)}
    print("     %d frontier entries" % len(tgt))
    named = 0
    for n, (lo, hi) in zones.items():
        f = sum(1 for x in frm if lo <= x <= hi)
        t = sum(1 for x in tgt if lo <= x <= hi)
        print("       from-sites in %-38s %3d   targets in it %3d" % (n, f, t))
        if "Descriptor" in n or "data zone" in n:
            named += f
    check("the two ranges the round names do NOT account for all the phantoms",
          named < len(tgt), "%d of %d" % (named, len(tgt)))
    check("the newly converted f64 pool itself emits frontier phantoms",
          any(0xFCB27E <= x <= 0xFCB4E5 for x in frm))


# ---- 6. coverage ------------------------------------------------------------
def measure(text):
    inc = sum(int(m.group(2), 16) for m in re.finditer(
        r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', text))
    inc += SIZE * len(re.findall(r'\.incbin\s+"[^"]+"\s*$', text, re.M))
    fill = sum(int(m.group(1), 0) * int(m.group(2), 0) for m in
               re.finditer(r"\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*,\s*([0-9]+)", text))
    fill += sum(int(m.group(1), 0) for m in
                re.finditer(r"\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*$", text, re.M))
    return SIZE - inc - fill, fill, inc


def coverage(rev):
    print("6. substantive coverage at %s vs the worktree" % rev)
    tot = [0, 0]
    for k in "abcd":
        p = "prom_%s/wsa1_prom_%s.s" % (k, k)
        old = subprocess.run(["git", "-C", ROOT, "show", "%s:%s" % (rev, p)],
                             capture_output=True, text=True).stdout
        new = open(os.path.join(ROOT, p)).read()
        so, fo, _ = measure(old)
        sn, fn, _ = measure(new)
        tot[0] += so
        tot[1] += sn
        print("     prom_%s  substantive %8d -> %8d  (%+d)   filler %7d -> %7d"
              % (k, so, sn, sn - so, fo, fn))
    print("     TOTAL   substantive %8d -> %8d  (%.1f%% -> %.1f%%)"
          % (tot[0], tot[1], 100.0 * tot[0] / (SIZE * 4), 100.0 * tot[1] / (SIZE * 4)))


def main():
    new_labels = set()
    if "--coverage" in sys.argv:
        coverage(sys.argv[sys.argv.index("--coverage") + 1])
        return 0
    base = subprocess.run(["git", "-C", ROOT, "show", "HEAD:prom_a/wsa1_prom_a.s"],
                          capture_output=True, text=True).stdout
    old = set(re.findall(r"^([A-Za-z_]\w*):$", base, re.M))
    cur = set(re.findall(r"^([A-Za-z_]\w*):$", open(SRC_A).read(), re.M))
    new_labels = cur - old
    curve_shapes()
    plus1_delta()
    header_depth(new_labels)
    stale_comments()
    if "--frontier" in sys.argv:
        frontier_sources()
    print()
    print("FAILED: %d" % len(fails) if fails else "ALL STATED EXPECTATIONS HELD")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
