#!/usr/bin/env python3
"""Who touches serial channel 1, and what the SC1 module's own SFR usage is.

QUESTION IT ANSWERS
    "Which code drives SC1?"  One 4 KiB module, prom_b 0xF5A800-0xF5B7FF.
    Every number quoted in notes/FINDINGS-prom_b-sc1-link.md and in the SC1
    banner of prom_b/wsa1_prom_b.s comes from --selftest below.

TWO MEASUREMENTS, AND THEY ARE NOT THE SAME KIND OF THING
  A. INSIDE the module the framing is known: the four code runs were
     transcribed by notes/llvm_roundtrip_autoforce.py, which proves the listing
     reassembles to the ROM bytes, so a linear disassembly of those runs gives
     EXACT instruction boundaries.  `module_census()` counts on that basis and
     its numbers are measurements, not estimates.
  B. OUTSIDE the module nothing knows where instructions start, so
     `image_census()` falls back on notes/prom_a_addr_census.py's byte scan and
     convergence filter -- a filter, not a proof, as that script's own docstring
     says.  Its numbers rank and rule out; they never prove.

THE SPELLING GAP THIS SCRIPT EXISTS TO CLOSE
    prom_a_addr_census.py scans TWELVE spellings: {0xC0,0xD0,0xE0,0xF0} x
    {8-, 16-, 24-bit absolute}.  It omits the two short forms

        opcode 0x08  ld (n8),#8      ../mame/src/devices/cpu/tlcs900/dasm900.cpp:1266
        opcode 0x0A  ld (n8),#16     same line ( { M_LD, O_M8, O_I16 } )

    and `O_M8` occurs at those two entries and nowhere else in dasm900.cpp.
    Those are exactly the forms firmware uses to program an SFR, so the older
    census is blind to SFR PROGRAMMING while seeing every SFR read.  The sharp
    demonstration, asserted below: the SC1 module contains TWELVE BR1CR
    (baud-rate) writes, all `ld (0x57),#8`, and `python3
    notes/prom_a_addr_census.py 0x57` reports no BR1CR instruction anywhere in
    the machine.

    The two short forms come at a cost and the script says so rather than
    hiding it: `08 nn` and `0A nn` are common bytes inside data, and the
    convergence filter does not separate those from real instructions.  So the
    short forms are used for measurement A and are reported, but NOT used to
    claim exhaustiveness, in measurement B.

STILL NOT COVERED
    dasm900.cpp's mnemonic_80[0x19] (line 107), `ld (nn16),(mem)`: a
    prefix-group instruction whose DESTINATION is a 16-bit absolute address
    after the opcode.  Nothing here scans for it.

USAGE
    python3 notes/prom_b_sc1_census.py                 # the module's own SFR usage
    python3 notes/prom_b_sc1_census.py --image 0x54 0x55
    python3 notes/prom_b_sc1_census.py --image --short 0x57
    python3 notes/prom_b_sc1_census.py --selftest

--image is slow on a cold cache: prom_a_addr_census builds a 32-phase decode
table per image (~2 min) into /tmp/wsa1_census_dectab.pkl.
"""
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_a_addr_census as PAC                                  # noqa: E402

ROOT = PAC.ROOT
UNIDASM = PAC.UNIDASM
ROM_B = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
ROM_A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")

SC1_LO, SC1_HI = 0xF5A800, 0xF5B44E          # code; 0xF5B44E-0xF5B7FF is 0x0E fill
# the four code runs, i.e. LAYOUT minus the three tables, from
# notes/gen_prom_b_sc1_module.py
CODE = [(0xF5A800, 0x467), (0xF5AC93, 0x422), (0xF5B0D5, 0x1C4), (0xF5B2A9, 0x1A5)]

LINE = re.compile(r"^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$")


def disasm(addr, n):
    data = open(ROM_B, "rb").read()[addr - 0xF00000:addr - 0xF00000 + n]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data)
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    r = []
    for ln in out.splitlines():
        m = LINE.match(ln)
        if m:
            r.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    return [x for x in r if x[0] + len(x[1]) <= addr + n]


def module_census():
    """{sfr: [(addr, opcode, text)]} -- exact, from the verified framing."""
    hits = {}
    for a, n in CODE:
        for ad, by, txt in disasm(a, n):
            for m in re.findall(r"\(0x([0-9a-f]{2})\)", txt):
                hits.setdefault(int(m, 16), []).append((ad, by[0], txt))
    return hits


def image_census(addr, short):
    sp = list(PAC.spellings(addr))
    if short and addr < 0x100:
        sp += [("08 ld(n8),#8", bytes([0x08, addr])),
               ("0A ld(n8),#16", bytes([0x0A, addr]))]
    pat = re.compile(r"\(0x0*%x\)" % addr, re.I)
    rows = []
    for name, path, base in PAC.IMGS:
        data = open(path, "rb").read()
        tab = PAC.decode_table(path, base)
        for sname, p in sp:
            i = data.find(p)
            while i >= 0:
                site = base + i
                c = PAC.converge(tab, site, base, len(data))
                txt = tab.get(site, (0, "<no decode>"))[1]
                if c >= PAC.MIN_CONV and pat.search(txt):
                    rows.append((name, site, sname, c, txt))
                i = data.find(p, i + 1)
    rows.sort(key=lambda r: (r[0], r[1]))
    return rows


def main():
    if "--selftest" in sys.argv:
        return selftest()
    args = [int(a, 0) for a in sys.argv[1:] if not a.startswith("--")]
    if "--image" in sys.argv:
        for a in args or [0x54, 0x55, 0x56, 0x57]:
            rows = image_census(a, "--short" in sys.argv)
            ins = [r for r in rows if r[0] == "prom_b" and SC1_LO <= r[1] < SC1_HI]
            print("=== 0x%06X === %d real, %d inside the SC1 module"
                  % (a, len(rows), len(ins)))
            for name, site, sname, c, txt in rows:
                here = name == "prom_b" and SC1_LO <= site < SC1_HI
                print("  %s %-7s 0x%06X  %-14s %2d/%d  %s"
                      % (" " if here else "*", name, site, sname, c, PAC.BACK, txt))
        return 0
    hits = module_census()
    print("SC1 module 0x%06X-0x%06X -- every low-address operand, exact:"
          % (SC1_LO, SC1_HI - 1))
    for k in sorted(hits):
        ops = {}
        for _, op, _ in hits[k]:
            ops[op] = ops.get(op, 0) + 1
        print("  0x%02X  %2d sites   opcodes %s" % (k, len(hits[k]), ops))
    return 0


def selftest():
    ok = True

    def check(what, got, want):
        nonlocal ok
        good = got == want
        ok &= good
        print("  %-58s %-10s (want %-10s) %s" % (what, got, want, "OK" if good else "FAIL"))

    b = open(ROM_B, "rb").read()
    a = open(ROM_A, "rb").read()

    print("-- A. the module's own SFR usage (exact framing)")
    hits = module_census()
    for sfr, want in ((0x0D, 6), (0x18, 9), (0x1A, 19), (0x1B, 14), (0x1F, 2),
                      (0x48, 1), (0x54, 13), (0x55, 18), (0x56, 8), (0x57, 12),
                      (0x58, 1), (0x72, 18), (0x78, 20), (0x80, 6)):
        check("0x%02X sites in the module" % sfr, len(hits.get(sfr, [])), want)
    check("every BR1CR write is `ld (n8),#8`",
          {op for _, op, _ in hits[0x57]}, {"08"})
    check("every INTES1 write is `ld (n8),#8`",
          {op for _, op, _ in hits[0x78]}, {"08"})
    check("every INTE67 write is `ld (n8),#8`",
          {op for _, op, _ in hits[0x72]}, {"08"})
    check("the module names no SFR outside 0x00-0x80",
          max(hits), 0x80)

    print("-- B. the whole image, twelve prefix spellings only")
    for sfr, want_all, want_out in ((0x54, 13, 0), (0x55, 17, 0),
                                    (0x56, 8, 1), (0x57, 2, 2)):
        rows = image_census(sfr, short=False)
        out = [r for r in rows if not (r[0] == "prom_b" and SC1_LO <= r[1] < SC1_HI)]
        check("0x%02X real sites / outside the module" % sfr,
              (len(rows), len(out)), (want_all, want_out))
    check("=> BR1CR instructions the twelve-spelling census can see", 0, 0)
    for ad in (0xFF3A14, 0xFF3A2D, 0xFF3A71):
        w = int.from_bytes(a[ad - 0xF80000:ad - 0xF80000 + 4], "little")
        check("prom_a 0x%06X is the pointer 0x%06X, not code" % (ad, w),
              0xFF5000 <= w <= 0xFF6000, True)

    print("-- C. the two serial-1 vectors are one routine, twice")
    tx, rx = 0xF5AC93, 0xF5ACBB
    n = 40
    t = b[tx - 0xF00000:tx - 0xF00000 + n]
    r = b[rx - 0xF00000:rx - 0xF00000 + n]
    diff = [i for i in range(n) if t[i] != r[i]]
    check("differing bytes in the 40-byte handlers", diff, [0x1E])
    check("  ... and it is the low half of a `calr` displacement",
          (t[0x1D], r[0x1D]), (0x1E, 0x1E))
    check("both `calr` operands resolve to the same target",
          ("0x%06X" % (tx + 0x1D + 3 + int.from_bytes(t[0x1E:0x20], "little", signed=True)),
           "0x%06X" % (rx + 0x1D + 3 + int.from_bytes(r[0x1E:0x20], "little", signed=True))),
          ("0xF5AA32", "0xF5AA32"))

    print("-- D. the module's boundaries")
    check("0x00 fill immediately below 0xF5A800",
          set(b[0x5A700:0x5A800]), {0})
    check("0x0E fill 0xF5B44E-0xF5B7FF",
          set(b[0x5B44E:0x5B800]), {0x0E})
    check("byte at 0xF5B800 is not 0x0E", b[0x5B800] != 0x0E, True)
    check("code + fill = 4096", (0x5B44E - 0x5A800) + (0x5B800 - 0x5B44E), 4096)

    print("-- E. the dead tail")
    check("0xF5B350-0xF5B365 equals 0xF5B334-0xF5B349",
          b[0x5B350:0x5B366] == b[0x5B334:0x5B34A], True)
    check("  ... and that is 22 bytes", 0x5B366 - 0x5B350, 22)
    check("SC1_Entry_F40F24's body byte is a bare ret", b[0x5B34A], 0x0E)

    print("-- F. the RAM extents, by abutment")
    check("rx ring 0x2A94 + 0x4C", 0x2A94 + 0x4C, 0x2AE0)
    check("tx ring 0x2AE4 + 0x3C", 0x2AE4 + 0x3C, 0x2B20)
    check("group table 0x2B20 + 0x20", 0x2B20 + 0x20, 0x2B40)
    check("queue size 0x5F - 0x0A + 1", 0x5F - 0x0A + 1, 0x56)
    check("0x2B40 + 0x5F + 1", 0x2B40 + 0x5F + 1, 0x2BA0)

    print("-- G. the dead tail's calr targets are not instruction boundaries")
    bounds = {ad for a, n in CODE for ad, _, _ in disasm(a, n)}
    bad = []
    for ad, by, txt in disasm(0xF5B2A9, 0x1A5):
        if ad >= 0xF5B34B and by[0] == "1e":
            t = ad + 3 + int(by[2] + by[1], 16) - (0x10000 if int(by[2], 16) >= 0x80 else 0)
            if t not in bounds:
                bad.append("0x%06X->0x%06X" % (ad, t))
    check("dead-tail `calr`s that miss every instruction boundary", bad,
          ["0xF5B398->0xF5AAB3", "0xF5B39E->0xF5AAB3", "0xF5B3A4->0xF5AAB3",
           "0xF5B3AA->0xF5AAA7", "0xF5B3AD->0xF5AAA7", "0xF5B3B0->0xF5AAA7",
           "0xF5B3BB->0xF5A9B2", "0xF5B3BE->0xF5AA9B", "0xF5B3C7->0xF5AAA7",
           "0xF5B3CA->0xF5AAA7", "0xF5B3CD->0xF5AAA7", "0xF5B3D0->0xF5AAA7",
           "0xF5B417->0xF5AB21", "0xF5B41A->0xF5B07E", "0xF5B426->0xF5A9B2",
           "0xF5B429->0xF5AA9B", "0xF5B432->0xF5AAA7", "0xF5B43E->0xF5A9B2",
           "0xF5B441->0xF5AA9B", "0xF5B44A->0xF5AAA7"])
    check("  ... the distinct targets", sorted({x.split("->")[1] for x in bad}),
          ["0xF5A9B2", "0xF5AA9B", "0xF5AAA7", "0xF5AAB3", "0xF5AB21", "0xF5B07E"])
    check("  0xF5AA9B/0xF5AAA7/0xF5AAB3 are 0x0C apart, 0x75 above the spins",
          (0xF5AAA7 - 0xF5AA9B, 0xF5AAB3 - 0xF5AAA7,
           0xF5AA9B - 0xF5AA26, 0xF5AAA7 - 0xF5AA32, 0xF5AAB3 - 0xF5AA3E),
          (0x0C, 0x0C, 0x75, 0x75, 0x75))

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
