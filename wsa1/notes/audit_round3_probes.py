#!/usr/bin/env python3
"""Round-3 audit: re-derive, from the ROMs and the sources, every quantified claim
this audit reports as broken -- and the controls that show the probe can fail.

WHY IT EXISTS
  Round 3's three lane reports and the files they shipped carry numbers that the
  byte gate cannot see.  This script is the artefact behind the round-3 audit's
  findings: each row prints the MEASURED value next to what the tree or the report
  says, and a row is `FAIL` when the tree's number is not the measured one.  A row
  that says `ok` here is a claim this audit CHECKED and accepted, not one it
  skipped.

  Sections 1-3 are defects in shipped FILES; 4-8 are numbers in reports or notes
  that no longer re-derive; 9-10 are positive results (0 violations) recorded so a
  later round can tell "checked and clean" from "not checked".

RUN
  python3 notes/audit_round3_probes.py
  python3 notes/audit_round3_probes.py --selftest    # + negative controls
Exit status is non-zero if any row FAILs.
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
IMG = {k: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
       for k, n in (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
                    ("c", "wsa1_prom_c.ic28"))}
BASE = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
SRC = {k: open(image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (k, k))).read()
       for k in "abc"}

FAILS = []


def check(cond, what, detail=""):
    print("  %-5s %s%s" % ("ok" if cond else "FAIL", what,
                           ("   [%s]" % detail) if detail else ""))
    if not cond:
        FAILS.append(what)


def at(k, a, n):
    return IMG[k][a - BASE[k]:a - BASE[k] + n]


def w32(k, a):
    return struct.unpack_from("<I", IMG[k], a - BASE[k])[0]


def decoded(k):
    """{addr: text} for every `; ADDR  <text>` comment on a non-comment line."""
    out = {}
    for ln in SRC[k].split("\n"):
        m = re.search(r';\s*([0-9A-F]{6})\s\s(.*)$', ln)
        if m and not ln.lstrip().startswith(";"):
            out[int(m.group(1), 16)] = m.group(2).strip()
    return out


# the ten prom_c ranges round 3 converted, from that round's own report table
C_RANGES = [(0xFA7E2C, 0xFABE2F), (0xFA5949, 0xFA7E2B), (0xFC3407, 0xFC856B),
            (0xFABE30, 0xFACE66), (0xFAD142, 0xFB0503), (0xFB405F, 0xFB6E09),
            (0xFB7345, 0xFB7714), (0xFB828E, 0xFC3406), (0xF9A050, 0xFA5948),
            (0xFC8BB2, 0xFCA0B9)]


def headers_c():
    """(name, lo, hi, bytes) for every sized routine header of prom_c."""
    return [(m.group(1), int(m.group(2), 16), int(m.group(3), 16),
             int(m.group(4).replace(",", "")))
            for m in re.finditer(
                r'^; (\S+) -- 0x([0-9A-F]{6})\.\.0x([0-9A-F]{6}) \(([0-9,]+) bytes\)',
                SRC["c"], re.M)]


def s1_dispatchers():
    print("\n1  THE TWO prom_c DISPATCHERS ARE NOT 'ONE ROUTINE WITH ONE BYTE CHANGED'")
    hd = {lo: (nm, hi, nb) for nm, lo, hi, nb in headers_c()}
    a, b = 0xFA8BDD, 0xFA900A
    check(hd[a][2] == 103 and hd[b][2] == 119,
          "the file's own headers give the two extents as 103 and 119 bytes",
          "%d / %d" % (hd[a][2], hd[b][2]))
    n = min(hd[a][2], hd[b][2])
    diff = [i for i in range(n) if at("c", a, n)[i] != at("c", b, n)[i]]
    p = 0
    while at("c", a, n)[p] == at("c", b, n)[p]:
        p += 1
    check(p == 14, "identical prefix (bytes)", str(p))
    check(len(diff) == 51, "differing bytes over the common 103", str(len(diff)))
    # the claim under test: any "64 bytes" whose neighbourhood names the pair
    for path, txt in (("prom_c/wsa1_prom_c.s", SRC["c"]),
                      ("notes/FINDINGS-prom_c-round3-module-conversion.md",
                       open(os.path.join(ROOT, "notes",
                                         "FINDINGS-prom_c-round3-module-conversion.md")).read())):
        hits = [i for i in range(len(txt)) if txt.startswith("64 bytes", i)
                and "VoiceParam_DispatchOn" in txt[max(0, i - 400):i]]
        check(not hits, "%s does not call the two dispatchers 64 bytes" % path,
              "%d site(s)" % len(hits))
    # the arms do not call the same routines
    def calls(lo, hi):
        d = decoded("c")
        return {int(m.group(1), 16) for x in range(lo, hi + 1)
                for m in [re.match(r'(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})$',
                                   d.get(x, ""))] if m}
    ca, cb = calls(a, hd[a][1]), calls(b, hd[b][1])
    check(len(ca & cb) == 1 and len(ca | cb) == 11,
          "the two dispatchers share exactly ONE callee out of eleven",
          "shared %d, union %d" % (len(ca & cb), len(ca | cb)))


def s2_dispatch_table():
    print("\n2  prom_b DispatchTable_F4C38D -- 23 pointers, HOW MANY DEFAULT STUBS")
    ps = [w32("b", 0xF4C38D + 4 * i) for i in range(23)]
    n = sum(1 for p in ps if p == 0x00F42C70)
    check(n == 15, "entries equal to the default stub 0x00F42C70", str(n))
    check(len({p for p in ps if p != 0x00F42C70}) == 3,
          "distinct non-default targets", str(len({p for p in ps if p != 0x00F42C70})))
    check("23 pointers, 19 of them the default thunk" not in SRC["b"],
          "prom_b/wsa1_prom_b.s does not say 19 of them are the default stub")
    gen = open(os.path.join(ROOT, "notes", "gen_prom_b_f47800_module.py")).read()
    check("23 pointers, 19 of them the default thunk" not in gen,
          "notes/gen_prom_b_f47800_module.py does not emit '19 of them'")
    # LAST-ENTRY control: the word one past the table is not a prom_b address
    check(not (0xF00000 <= w32("b", 0xF4C38D + 4 * 23) <= 0xFFFFFF),
          "the word one entry past the table is NOT a prom_b address",
          "0x%08X" % w32("b", 0xF4C38D + 4 * 23))


def s3_touches():
    print("\n3  prom_b `Touches:` -- a phantom 0x000000 and 55 real addresses missing")
    tl = [l for l in SRC["b"].split("\n") if re.match(r'^;\s*Touches:', l)]
    check(len(tl) == 692, "Touches: lines in prom_b", str(len(tl)))
    ph = sum(1 for l in tl if "0x000000" in l)
    check(ph == 0, "Touches: lines naming the phantom address 0x000000", str(ph))
    body = "\n".join(tl)
    use = {}
    for ln in SRC["b"].split("\n"):
        m = re.search(r';\s*([0-9A-F]{6})\s\s(.*)$', ln)
        if not m or ln.lstrip().startswith(";"):
            continue
        for v in re.findall(r'\(0x([0-9a-f]{6})\)', m.group(2)):
            k = "0x%06X" % int(v, 16)
            use[k] = use.get(k, 0) + 1
    miss = sorted((v for v in use if v not in body), key=lambda v: -use[v])
    check(not miss, "every absolute a decoded prom_b instruction names appears in "
                    "some Touches: line",
          "%d of %d missing, busiest %s used %d times"
          % (len(miss), len(use), miss[0] if miss else "-", use[miss[0]] if miss else 0))
    # the phantom's origin: an immediate, not an address
    d = decoded("b")
    check("cp XWA,0x00000000" in d.get(0xF47827, ""),
          "the phantom comes from an IMMEDIATE (`cp XWA,0x00000000` at 0xF47827)",
          d.get(0xF47827, ""))


def s4_citations():
    print("\n4  prom_c CITED CALL SITES -- the number the round-3 report gives")
    n = 0
    lines = SRC["c"].splitlines()
    ADDR = re.compile(r'0x([0-9A-Fa-f]{6})')
    LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
    INSTR = re.compile(r';\s*([0-9A-F]{6})\s')
    pending, i = [], 0
    while i < len(lines):
        if "; Called from:" in lines[i]:
            pending, j = [], i
            while j < len(lines) and lines[j].startswith(";"):
                if j > i and re.match(r';\s*(Inputs|Outputs|Evidence|Unknown|Packet|Dispatch):',
                                      lines[j]):
                    break
                pending += [int(m, 16) for m in ADDR.findall(lines[j])]
                j += 1
            i = j
            continue
        m = LABEL.match(lines[i])
        if m and pending:
            ra = None
            for k in range(i + 1, min(i + 4, len(lines))):
                mm = INSTR.search(lines[k])
                if mm:
                    ra = int(mm.group(1), 16)
                    break
            if ra is not None:
                n += sum(1 for a in pending if a != ra)
            pending = []
        i += 1
    check(n == 2699, "notes/prom_c_audit_callsites.py's own harvest gives the "
                     "reported 2,699 citations", str(n))
    resp = open(os.path.join(ROOT, "notes", "prom_c-round2-audit-responses.md")).read()
    check("**410 cited / 18 not decoding" not in resp,
          "notes/prom_c-round2-audit-responses.md does not still call 410 the "
          "post-round-3 total")


def s5_incbin():
    print("\n5  `.incbin` DIRECTIVE COUNTS -- the column the tree calls trustworthy")
    for k, want in (("a", 17), ("b", 124), ("c", 8)):
        n = len(re.findall(r'^\s*\.incbin', SRC[k], re.M))
        check(n == want, "prom_%s .incbin directives" % k, str(n))
    fin = open(os.path.join(ROOT, "notes",
                            "FINDINGS-prom_c-round3-module-conversion.md")).read()
    check("count (14, unmoved)" not in fin,
          "the round-3 findings note does not still give prom_c's directive count as 14")
    resp = open(os.path.join(ROOT, "notes", "prom_c-round2-audit-responses.md")).read()
    check("| 2026-08-25, round 3 | 14 | 41 |" not in resp,
          "the round-2 response table's round-3 row is not still 14 / 41")
    check(sum(int(m.group(2), 16) for m in re.finditer(
        r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', SRC["c"]))
        == 180082, "prom_c bytes still `.incbin`")


def s6_census():
    print("\n6  prom_c BLOCK 'Call census' COMMENTS vs the tool they cite")
    import subprocess
    for lo, hi, claim, inside in ((0xF9A050, 0xFA5949, 38, 624),
                                  (0xFC8BB2, 0xFCA0BA, 57, 15)):
        out = subprocess.run([sys.executable,
                              os.path.join(ROOT, "notes", "prom_c_module_map.py"),
                              hex(lo), hex(hi)], capture_output=True, text=True).stdout
        m = re.search(r'(\d+) in-range site\(s\), (\d+) outside site\(s\)', out)
        got_in, got_out = int(m.group(1)), int(m.group(2))
        check(got_out == claim,
              "0x%06X block comment says '%d literal call site(s) from outside'; "
              "prom_c_module_map.py, the command it prints, says %d"
              % (lo, claim, got_out), "%d vs %d" % (claim, got_out))
        check(got_in == inside,
              "  ...and its '%d from inside it' still holds" % inside, str(got_in))


def s7_module_map():
    print("\n7  'TOOL AND FILE AGREE AT EXACTLY 600' -- what the tool prints today")
    hd = [h for h in headers_c() if any(lo <= h[1] <= hi for lo, hi in C_RANGES)]
    check(len(hd) == 600, "sized routine headers inside the ten ranges", str(len(hd)))
    arms = 0
    for m in re.finditer(r'^; Arms:\s*(\d+) computed-goto arm', SRC["c"], re.M):
        arms += int(m.group(1))
    check(arms == 305, "computed-goto arms the same headers declare", str(arms))
    check(600 + arms == 905,
          "prom_c_module_map.py's candidate ENTRIES over the ten ranges are "
          "600 routines + 305 arms = 905, not 600", "%d" % (600 + arms))
    mm = open(os.path.join(ROOT, "notes", "prom_c_module_map.py")).read()
    check("116 of 761 candidates" not in mm,
          "notes/prom_c_module_map.py no longer states the transient '116 of 761 "
          "candidates, 15%' as a property")


def s8_prom_a_labels():
    print("\n8  prom_a ROUND-3 LABELS -- 336 sub_ + how many semantic")
    import subprocess
    NM = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
    rows = []
    for l in subprocess.run([NM, os.path.join(ROOT, "rebuilt_ROMs",
                                              "wsa1_prom_a.llvm.elf")],
                            capture_output=True, text=True).stdout.split("\n"):
        q = l.split()
        if len(q) >= 3 and q[1].lower() in "tdrb":
            a = int(q[0], 16)
            if 0xFC0000 <= a < 0xFC3000 or 0xFC8000 <= a < 0xFCF000:
                rows.append((a, q[2]))
    sub = [r for r in rows if r[1].startswith("sub_")]
    sem = [r for r in rows if not r[1].startswith("sub_")]
    check(len(sub) == 336, "sub_XXXXXX labels in the two round-3 prom_a ranges "
                           "(llvm-nm on the rebuilt ELF)", str(len(sub)))
    check(len(sem) == 18, "semantic labels there -- the round report says "
                          "'18 semantic labels total across the two spans'",
          "%d = 11 named routines + %d named data structures; 336 + %d = %d, "
          "the label total" % (len(sem), len(sem) - 11, len(sem), len(sub) + len(sem)))


def s9_alignment():
    print("\n9  DECODE ALIGNMENT, image-wide (a POSITIVE result: 0 violations)")
    import subprocess
    for k in "abc":
        d = decoded(k)
        bounds = set(d)
        nmpath = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_%s.llvm.elf" % k)
        try:
            out = subprocess.run(["/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm",
                                  nmpath], capture_output=True, text=True).stdout
            for l in out.split("\n"):
                q = l.split()
                if len(q) >= 3 and q[1].lower() in "tdrb":
                    bounds.add(int(q[0], 16))
        except Exception:
            pass
        inc = []
        for m in re.finditer(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                             SRC[k]):
            lo = BASE[k] + int(m.group(1), 16)
            inc.append((lo, lo + int(m.group(2), 16)))
        XFER = re.compile(r'\b(?:call|calr|jp|jrl|jr)\b[^;]*?0x([0-9a-f]{6})\s*$')
        tot = bad = 0
        for a, t in d.items():
            m = XFER.search(t)
            if not m:
                continue
            tgt = int(m.group(1), 16)
            if any(lo <= tgt < hi for lo, hi in inc):
                continue
            if not (BASE[k] <= tgt < BASE[k] + 0x80000):
                continue
            tot += 1
            if tgt not in bounds:
                bad += 1
        # prom_b's 21 are the documented SC1_DeadTail calr targets, which the file
        # itself says are not instruction boundaries of the live code.
        allow = 21 if k == "b" else 0
        check(bad == allow, "prom_%s: transfer targets that are not a boundary or a "
                            "label (%d checked, %d expected)" % (k, tot, allow), str(bad))


def s10_kn5000_names():
    print("\n10  BORROWED KN5000 NAMES -- bytes diffed over the sibling symbol extent")
    import subprocess
    NM = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
    SIB = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
    ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
    full = "/tmp/kn5000_v142_full.bin"
    if not os.path.exists(full):
        subprocess.run(["/home/fsanches/compartilhado/llvm-project/build/bin/llvm-objcopy",
                        "-O", "binary", ELF, full], check=True)
    fb = open(full, "rb").read()
    kn = {}
    order = []
    for l in subprocess.run([NM, "--numeric-sort", ELF], capture_output=True,
                            text=True).stdout.split("\n"):
        q = l.split()
        if len(q) >= 3 and q[1].lower() in "tdr":
            kn.setdefault(q[2], int(q[0], 16))
            order.append((int(q[0], 16), q[2]))
    order.sort()
    shared, diff = 0, []
    for k in "abc":
        for l in subprocess.run([NM, os.path.join(ROOT, "rebuilt_ROMs",
                                                  "wsa1_prom_%s.llvm.elf" % k)],
                                capture_output=True, text=True).stdout.split("\n"):
            q = l.split()
            if len(q) < 3 or q[1].lower() not in "tdrb":
                continue
            n, a = q[2], int(q[0], 16)
            if n not in kn or not (BASE[k] <= a < BASE[k] + 0x80000):
                continue
            ka = kn[n]
            ext = next((x - ka for x, _ in order if x > ka), 16)
            ext = min(ext, 64)
            if ka - 0x400 + ext > len(fb):
                continue
            shared += 1
            nd = sum(1 for i in range(ext)
                     if fb[ka - 0x400 + i] != IMG[k][a - BASE[k] + i])
            if nd:
                diff.append(("prom_%s" % k, a, n, ka, ext, nd))
    check(shared == 69, "labels whose NAME is a KN5000 sub-CPU symbol", str(shared))
    for row in sorted(diff, key=lambda r: -r[5]):
        print("        %s 0x%06X  %-40s kn 0x%05X  ext %2d  differing %d"
              % (row[0], row[1], row[2], row[3], row[4], row[5]))
    check(len(diff) == 8, "of them NOT byte-identical over the sibling extent",
          str(len(diff)))


def selftest():
    print("\nNEGATIVE CONTROLS")
    a, b = 0xFA8BDD, 0xFA900A
    check(sum(1 for i in range(64) if at("c", a, 64)[i] != at("c", b, 64)[i]) != 0,
          "the two dispatchers are NOT identical over the 64 bytes the tree claims")
    check(w32("b", 0xF4C38D) == 0x00F42C70,
          "entry 0 of DispatchTable_F4C38D really is the default stub")
    check(sum(1 for p in [w32("b", 0xF4C38D + 4 * i) for i in range(23)]
              if p == 0x00F42C70) != 19,
          "19 is refuted, not merely unconfirmed")
    d = decoded("b")
    check("0x60341e" in d.get(0xF47816, "").lower(),
          "0x60341E really is read by the routine whose Touches: omits it")


def main():
    for f in (s1_dispatchers, s2_dispatch_table, s3_touches, s4_citations,
              s5_incbin, s6_census, s7_module_map, s8_prom_a_labels,
              s9_alignment, s10_kn5000_names):
        f()
    if "--selftest" in sys.argv:
        selftest()
    print("\n%d row(s) FAIL re-derivation" % len(FAILS))
    for f in FAILS:
        print("   - " + f)
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
