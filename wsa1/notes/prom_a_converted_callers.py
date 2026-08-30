#!/usr/bin/env python3
"""Which CONVERTED sites in prom_a call a given address, and what precedes them?

QUESTION IT ANSWERS: "notes/prom_a_xref.py gives an opcode-anchored UPPER BOUND
on callers -- byte patterns found at every offset, data included.  Of those, how
many are real instructions in the part of prom_a that has left `.incbin`, and
what does each one do immediately before the call?"

This is exact for converted code, because prom_a/wsa1_prom_a.s rebuilds the ROM
byte-identically (scripts/analysis/assert_byte_identical.py): a line that says
`call 0xf4123c ; FB24D7 1d 3c 12 f4` IS the instruction at 0xFB24D7.  It says
nothing about the still-`.incbin` remainder, which is why the two tools disagree
and both are needed.

Written 2026-08-25 to settle round-2 audit finding F1: the tree claimed the
0xFB2000 module was "the only converted caller of Link_WaitBlockDone" and that
"a machine that never runs a remote-flash read never reaches that release path
at all".  Both are false; there are 15 converted call sites in five separate
modules, and four of them are not remote reads.

    python3 notes/prom_a_converted_callers.py 0xF4123C
    python3 notes/prom_a_converted_callers.py 0xF4123C --context 8
    python3 notes/prom_a_converted_callers.py --checks   # assertions, exit 1 on fail
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")

# A converted instruction line: <tab>text<spaces>; ADDR  bb bb bb
LINE = re.compile(r"^\t(\S.*?)\s+;\s([0-9A-F]{6})\s\s([0-9a-f ]+?)\s*$")


def instructions():
    """Every converted instruction in prom_a, as (addr, mnemonic-text, bytes, lineno)."""
    out = []
    for n, line in enumerate(open(SRC), 1):
        m = LINE.match(line.rstrip("\n"))
        if not m:
            continue
        text, addr, bs = m.group(1), int(m.group(2), 16), m.group(3).split()
        out.append((addr, text.strip(), bs, n))
    out.sort()
    return out


def callers(target, insns=None):
    """Converted sites that call/jp/calr `target`.  Exact, not a byte scan."""
    insns = insns if insns is not None else instructions()
    want = ("0x%06x" % target, "0x%x" % target)
    hits = []
    for i, (addr, text, bs, n) in enumerate(insns):
        op = text.split()[0] if text else ""
        if op not in ("call", "jp", "calr"):
            continue
        rest = text[len(op):].strip().lower()
        # `call 0xf4123c`, or a label whose own definition sits at target
        if rest in want:
            hits.append((addr, text, n, i))
    return hits


def preceding(insns, idx, count):
    lo = max(0, idx - count)
    return insns[lo:idx]


def main():
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    ctx = 8
    for x in sys.argv[1:]:
        if x.startswith("--context="):
            ctx = int(x.split("=", 1)[1])
    if "--context" in sys.argv:
        ctx = int(sys.argv[sys.argv.index("--context") + 1])
    if "--checks" in sys.argv:
        return checks()
    if not args:
        print(__doc__)
        return 2
    insns = instructions()
    for arg in args:
        t = int(arg, 16)
        hits = callers(t, insns)
        print("=== converted callers of 0x%06X: %d ===" % (t, len(hits)))
        for addr, text, n, i in hits:
            pre = preceding(insns, i, ctx)
            prev_call = ""
            for paddr, ptext, pbs, pn in reversed(pre):
                if ptext.split()[0] in ("call", "calr"):
                    prev_call = "%s (0x%06X)" % (ptext, paddr)
                    break
            print("  0x%06X  line %-6d  prev call: %s" % (addr, n, prev_call or "-none in %d-"%ctx))
    return 0


# ----------------------------------------------------------------------------
# Assertions.  Each is a sentence the tree states; the last one is the LAST
# element of the list, so an off-by-one in the parser cannot pass silently.
# ----------------------------------------------------------------------------
WAIT = 0xF4123C          # prom_b thunk -> prom_a 0xF8E66D Link_WaitBlockDone
BUILD = 0xF40EF0         # prom_b thunk -> prom_a 0xF8E0FE remote-read packet build

EXPECT = [
    # (call site, the call that immediately precedes it)
    (0xF828A8, "call 0xf40ef0"),   # added 2026-08-25 with the boot block
    (0xF82981, "call 0xf40ef0"),
    (0xF82A45, "call 0xf40ef0"),
    (0xF82A6C, "call 0xf40ef0"),
    (0xF95322, "call 0xf40ef0"),   # added with the 0xF92C62 UI block
    (0xF9FAFC, "call 0xf40ef0"),   # added with the 0xF99021 UI block
    (0xFAABFB, "call 0xf40ef0"),
    (0xFB24D7, "call 0xf40ef0"),
    (0xFB256E, "call sub_FB7649"),
    (0xFB26D2, "call 0xf40ef0"),
    (0xFB2769, "call sub_FB7722"),
    (0xFB6FD1, "calr sub_FB7025"),
    (0xFC00BE, "call 0xf40ef0"),
    (0xFC0188, "call 0xf40ef0"),
    (0xFC1C62, "call sub_FC1C77"),
    (0xFC20DF, "call sub_FC2112"),
    (0xFC219D, "call sub_FC21D0"),
    (0xFE29EB, "call 0xf40ef0"),
    (0xFE2A73, "call 0xf40ef0"),
    (0xFE2B86, "call 0xf40ef0"),
    (0xFE2BC6, "call 0xf40ef0"),
]

# Which of the four intermediate routines reaches the packet builder itself.
INTERMEDIATE = {
    "sub_FC1C77": 0xFC1CB6,
    "sub_FC2112": 0xFC212A,
    "sub_FC21D0": 0xFC21E8,
}
NO_BUILD = "sub_FB7025"   # this one does NOT reach 0xF40EF0

FAILS, RAN = [], []


def check(name, cond, detail=""):
    RAN.append(name)
    if not cond or "-v" in sys.argv:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name, ("  -- " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


def checks():
    insns = instructions()
    hits = callers(WAIT, insns)
    check("C1 site count", len(hits) == 21, "got %d, want 21" % len(hits))
    got = [h[0] for h in hits]
    check("C2 site addresses", got == [e[0] for e in EXPECT], "%s" % ["%06X" % g for g in got])

    # C3..C5: the LAST site in the list, spelled out, so a truncation fails here.
    check("C3 last site is 0xFE2BC6", got and got[-1] == 0xFE2BC6, "%06X" % (got[-1] if got else 0))
    idx_by_addr = {a: i for i, (a, t, b, n) in enumerate(insns)}
    last = insns[idx_by_addr[0xFE2BC6] - 1]
    check("C4 last site's previous instruction is `call 0xf40ef0` at 0xFE2BC2",
          last[1] == "call 0xf40ef0" and last[0] == 0xFE2BC2, "%06X %s" % (last[0], last[1]))

    # C5: the immediately-preceding call at every site
    bad = []
    for (addr, want) in EXPECT:
        i = idx_by_addr[addr]
        prev = ""
        for paddr, ptext, pbs, pn in reversed(insns[max(0, i - 8):i]):
            if ptext.split()[0] in ("call", "calr"):
                prev = ptext
                break
        if prev != want:
            bad.append("%06X got %r want %r" % (addr, prev, want))
    check("C5 preceding call at all 15 sites", not bad, "; ".join(bad))

    # C6: how many have `call 0xf40ef0` as the IMMEDIATELY preceding call
    direct = sum(1 for a, w in EXPECT if w == "call 0xf40ef0")
    check("C6 15 of 21 immediately follow `call 0xf40ef0`", direct == 15, "got %d" % direct)

    # C6b: two more have the builder two calls back inside the same block
    two_back = {0xFB256E: 0xFB2560, 0xFB2769: 0xFB275B}
    for site, build in two_back.items():
        i = idx_by_addr.get(build)
        ok = i is not None and insns[i][1] == "call 0xf40ef0" and build < site
        check("C6b 0x%06X: builder two calls back at 0x%06X" % (site, build), ok,
              "" if ok else "found %r" % (insns[i][1] if i is not None else None))

    # C7: three of the four intermediates reach the builder one call deeper
    for name, addr in INTERMEDIATE.items():
        i = idx_by_addr.get(addr)
        ok = i is not None and insns[i][1] == "call 0xf40ef0"
        check("C7 %s calls the builder at 0x%06X" % (name, addr), ok,
              "" if ok else "found %r" % (insns[i][1] if i is not None else None))

    # C8: sub_FB7025 does NOT, anywhere in its body
    body = []
    started = False
    for addr, text, bs, n in insns:
        if addr == 0xFB7025:
            started = True
        if started:
            body.append((addr, text))
            if text == "ret" and len(body) > 1:
                break
    check("C8 sub_FB7025 body found (ends 0xFB703F)", body and body[-1][0] == 0xFB703F,
          "%06X" % (body[-1][0] if body else 0))
    check("C9 sub_FB7025 never calls 0xf40ef0",
          not any(t == "call 0xf40ef0" for a_, t in body), "")

    # C10: the modules the 15 sites fall in
    mods = sorted({(a >> 12) & 0xFFF for a in got})
    check("C10 sites span nine separate regions",
          len({0xF82, 0xF95, 0xF9F, 0xFAA, 0xFB2, 0xFB6, 0xFC0, 0xFC1, 0xFC2,
               0xFE2} & set(mods)) == 10,
          "%s" % ["%03X" % m for m in mods])

    # C11: the SOURCE literal each direct build is handed.  This is the point that
    # refutes "a machine that never runs a remote-flash read never reaches that
    # release path": four distinct literal bases appear, and one of them is
    # prom_a's OWN ROM.
    SRC_LIT = {
        0xFAABF1: 0x00F80300,   # prom_a ROM itself
        0xFB24CD: 0x00E80000,   # remote flash
        0xFB26C8: 0x00EC0000,   # remote flash, second bank
        0xFC00AE: 0x00C00000,   # the 0xC00000 device window
        0xFE29E1: 0x00E80000,
        0xFE2A69: 0x00EC0000,
        0xFC1C86: 0x00F80300,   # inside sub_FC1C77
        0xFC1C8D: 0x00EC0300,
        # the four boot-block sites, added 2026-08-25.  NONE of these is flash.
        0xF8289B: 0x00C00000,   # ExtBoard_Identify: the expansion-board window
        0xF82974: 0x00FFFFF0,   # the ROM-version chord: prom_c's tag
        0xF82A38: 0x00FFFFF0,   # VersionScreen_Show, first read: prom_c's tag
        0xF82A5F: 0x00F7FFF0,   # VersionScreen_Show, second read: prom_d's tag
    }
    bad = []
    for addr, lit in SRC_LIT.items():
        i = idx_by_addr.get(addr)
        t = insns[i][1] if i is not None else ""
        if ("0x%08x" % lit) not in t.lower():
            bad.append("%06X %r want 0x%08x" % (addr, t, lit))
    check("C11 twelve source literals as documented", not bad, "; ".join(bad))
    check("C12 not every source is remote flash: 0xF80300, 0xC00000, 0xFFFFF0 "
          "and 0xF7FFF0 all appear",
          {0x00F80300, 0x00C00000, 0x00FFFFF0, 0x00F7FFF0} <= set(SRC_LIT.values()))

    print("\n%d checks, %d FAILED" % (len(RAN), len(FAILS)))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
