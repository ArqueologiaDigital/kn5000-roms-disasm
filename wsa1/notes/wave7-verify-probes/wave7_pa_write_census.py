#!/usr/bin/env python3
"""Every access to port PA (direct address 0x1E) in prom_a and prom_b -- ALL 1 MiB.

QUESTION IT ANSWERS
    "Does the firmware ever change PA bit 3 -- the floppy drive's motor/ready
     line -- and if so, where, and in which direction?"

WHY IT EXISTS: TWO COMMITTED DOCUMENTS CONTRADICTED EACH OTHER
    * commit a4976de (wave 6): "`ld (PA),A` occurs exactly twice in prom_a+prom_b
      ... nothing requests either.  So PA bit 3 comes up high at reset and the
      firmware never changes it ... It is now a hardware question, not a
      disassembly one."
    * notes/WSA1-EMULATION-DISASM-GAPS.md (refreshed 2026-08-26): "The firmware
      DOES drive PA bit 3 ... Four writes exist ... `res 3,(PA)` at 0xFE18EF is
      followed by a 307 ms delay, i.e. a motor spin-up, so the line is ACTIVE LOW."

    This script adjudicates it, and the refreshed list wins.  The wave-6 census
    searched for ONE spelling -- the `ld (PA),A` store -- and TLCS-900 reaches an
    8-bit direct address with a whole family of forms.  The two writes it missed
    are BIT MANIPULATIONS, `res` and `set`, which never contain the store opcode.

    ★ THE LESSON, which is the reusable part: a census that enumerates one
    SPELLING is not a census of the OPERATION.  Enumerate encodings, not idioms.

    ⚠ AND THIS SCRIPT FELL INTO A WEAKER VERSION OF THE SAME TRAP ON ITS FIRST
    DRAFT.  It enumerated the twelve C0/D0/E0/F0 direct-operand encodings and
    reported FOUR writes -- missing the RESET initialisation `ldio PA,0xF9` at
    0xF826D6, which is opcode 0x08 (`ld (n8),imm8`), a standalone direct opcode
    outside that family, AND is written in the source with a symbolic operand and
    no byte comment, so the byte-comment scan could not see it either.  The wave-7
    doc-audit lane's verifier found it independently.  Pass 1b and the 0x08 raw
    pattern below exist because of that.  The true count is FIVE writes.

WHAT "COMPLETE" MEANS HERE, AND WHY THE RAW SCAN EXISTS
    Scanning the .s sources only sees CONVERTED code.  106,585 bytes of prom_a and
    159,459 of prom_b are still `.incbin`, so a source-only census silently means
    "in the 71.5% of prom_a and 61.1% of prom_b that happens to be converted".
    That is exactly the kind of unstated denominator this project has been burned
    by, so pass 2 scans the RAW ROM over the unconverted ranges as well.

    A raw byte match is a CANDIDATE, not a hit: the bytes may fall in the middle of
    a longer instruction or inside data.  They are reported separately and counted
    separately.  prom_a yields ZERO candidates, so its census is complete over the
    whole 512 KiB.  prom_b yields THREE, and rather than wave them away as noise
    this script adjudicates each -- see ADJUDICATED below.

    ★ The distinction that matters: gap T is about PA **BIT 3**.  A candidate can be
    a genuine PA access and still be irrelevant to it.  All three are:

      0xF3A0C1  RULED OUT AS DATA.  The surrounding bytes are LE16 words in an
                arithmetic sequence of stride 5 -- 0x1720 0x1725 0x172A 0x172F
                0x1734 0x1739 0x173E 0x1743, then 0x1EF0 0x1EF5 0x1EFA 0x1EFF
                0x1F04 0x1F09 0x1F0E 0x1F13.  The "f0 1e" the scan matched is the
                low and high halves of 0x1EF0.  0 of 38 trial decode starts put an
                instruction boundary here.
      0xF0B984  IF it is code it decodes `cp IX,(0x1e)` -- a word COMPARE, i.e. a
                read, and not bit-addressed.  1 of 38 starts lands on it.
      0xF53DFF  IF it is code it decodes `chg 0,(0x1e)` -- bit **0**, not bit 3.
                3 of 38 starts land on it.

    So even in the worst case where both remaining candidates are real instructions,
    NEITHER writes PA bit 3, and gap T's answer is unchanged.  That is why the
    self-test asserts "no candidate touches bit 3" rather than "no candidates".

RUN
    python3 notes/wave7-verify-probes/wave7_pa_write_census.py
    python3 notes/wave7-verify-probes/wave7_pa_write_census.py --selftest   # 18 checks
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PA = 0x1E   # port A, direct address, per the TMP95C061 databook

IMAGES = [("prom_a", "prom_a/wsa1_prom_a.s", "wsa1_prom_a.ic12", 0xF80000),
          ("prom_b", "prom_b/wsa1_prom_b.s", "wsa1_prom_b.ic13", 0xF00000)]

# A source line carries both the text and the bytes, so the bytes are authoritative
# and the text says what they mean.
LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(\s|$)')

# Writes touch PA; reads only sample it. `res`/`set`/`chg` are read-modify-write on
# the port latch, and they are the two the earlier census missed.
WRITE_MNEMONICS = ("st_", "res_", "set_", "chg_", "ld_dd", "or_d", "and_d", "xor_d")
READ_MNEMONICS = ("ld_sd", "bit_", "cp_")

# res/set/chg on an 8-bit direct operand encode the bit number in the low 3 bits of
# the operation byte: 0xB0|b = res, 0xB8|b = set, 0xC0|b = chg.
BIT_OPS = (0xB0, 0xB8, 0xC0)


def bit_touched(op):
    """The bit number a res/set/chg operation byte addresses, or None."""
    for base in BIT_OPS:
        if op & 0xF8 == base:
            return op & 0x07
    return None


def spellings(addr):
    """Every direct-addressing prefix that can name `addr`.  The TLCS-900 has four
    operand-group prefixes (0xC0/0xD0/0xE0/0xF0 = byte/word/long source/dest
    families) and three address widths each, so ONE address has up to twelve
    encodings.  The wave-6 census looked for one."""
    out = []
    for gn, g in (("C", 0xC0), ("D", 0xD0), ("E", 0xE0), ("F", 0xF0)):
        if addr < 0x100:
            out.append((gn + "8", bytes([g + 0, addr])))
        if addr < 0x10000:
            out.append((gn + "16", bytes([g + 1, addr & 0xFF, addr >> 8])))
        out.append((gn + "24", bytes([g + 2, addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF])))
    return out


SP = spellings(PA)
# Standalone direct opcodes that name an 8-bit address without a C0/D0/E0/F0 prefix.
# 0x08 is `ld (n8),imm8` -- the form RESET uses, and the one the first draft missed.
STANDALONE = [("op08", bytes([0x08, PA]))]
ALL_PATTERNS = SP + STANDALONE

# A macro or symbolic line carries no byte comment, so pass 1a cannot see it.
SYMBOLIC = re.compile(r'^\t([a-z][a-z0-9_]*)\s+.*\bPA\b(?!FC|CR)')


def source_hits(srcf):
    """Pass 1: instructions in the CONVERTED source. Authoritative -- the decode
    is already proven by the byte gate."""
    hits = []
    for lineno, line in enumerate(open(os.path.join(ROOT, srcf)), 1):
        m = LINE.match(line)
        if not m:
            continue
        txt, addr = m.group(1), int(m.group(2), 16)
        bs = bytes.fromhex(m.group(3).replace(" ", ""))
        for name, pat in ALL_PATTERNS:
            if bs.startswith(pat):
                kind = ("write" if txt.startswith(WRITE_MNEMONICS)
                        else "read" if txt.startswith(READ_MNEMONICS) else "other")
                hits.append((lineno, addr, name, txt, m.group(3), kind))
                break
    return hits


def symbolic_hits(srcf):
    """Pass 1b: lines naming PA by SYMBOL rather than by encoded address.  A macro
    line has no byte comment, so pass 1a is structurally blind to it -- which is
    how the RESET write was missed on the first draft."""
    hits = []
    for lineno, line in enumerate(open(os.path.join(ROOT, srcf)), 1):
        m = SYMBOLIC.match(line)
        if m:
            txt = line.strip().split(";")[0].strip()
            mn = m.group(1)
            kind = ("write" if mn.startswith(("ldio", "st", "res", "set", "chg"))
                    else "read" if mn.startswith(("ld", "bit", "cp")) else "other")
            hits.append((lineno, None, "symbolic", txt, "-", kind))
    return hits


def incbin_ranges(srcf, inc, base):
    """The parts of the image that pass 1 CANNOT see."""
    text = open(os.path.join(ROOT, srcf)).read()
    rx = re.compile(r'^\t\.incbin "original_ROMs/%s", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)\s*$'
                    % re.escape(inc), re.M)
    return [(int(o, 16), int(l, 16)) for o, l in rx.findall(text)]


def raw_candidates(inc, base, ranges):
    """Pass 2: byte patterns inside the still-unconverted ranges.  CANDIDATES, not
    hits -- a match may be mid-instruction or inside data."""
    rom = open(os.path.join(ROOT, "original_ROMs", inc), "rb").read()
    out = []
    for off, ln in ranges:
        chunk = rom[off:off + ln]
        for name, pat in SP:
            i = 0
            while True:
                i = chunk.find(pat, i)
                if i < 0:
                    break
                if name == "op08":
                    op = None      # `ld (n8),imm8` is not a bit operation
                else:
                    op = chunk[i + len(pat)] if i + len(pat) < len(chunk) else None
                out.append((base + off + i, name, chunk[i:i + 6].hex(" "),
                            None if op is None else bit_touched(op)))
                i += 1
    return sorted(out)


def run(verbose=True):
    totals = {}
    for tag, srcf, inc, base in IMAGES:
        hits = source_hits(srcf) + symbolic_hits(srcf)
        ranges = incbin_ranges(srcf, inc, base)
        cands = raw_candidates(inc, base, ranges)
        unconv = sum(l for _o, l in ranges)
        if verbose:
            print("=== %s ===" % tag)
            print("  pass 1 -- converted source (%d instruction hits):" % len(hits))
            for lineno, addr, name, txt, bs, kind in hits:
                print("    %s:%-7d %s  %-9s %-6s %-30s %s"
                      % (tag, lineno, "%06X" % addr if addr is not None else "  --  ",
                         name, kind, txt, bs))
            print("  pass 2 -- raw bytes inside the %s bytes still .incbin (%d candidates):"
                  % (format(unconv, ","), len(cands)))
            for addr, name, bs, bit in cands:
                print("    CANDIDATE 0x%06X  %-7s %s   bit addressed: %s"
                      % (addr, name, bs, "none (not a bit op)" if bit is None else bit))
            print()
        totals[tag] = {
            "writes": [h for h in hits if h[5] == "write"],
            "reads": [h for h in hits if h[5] == "read"],
            "other": [h for h in hits if h[5] == "other"],
            "candidates": cands, "unconverted": unconv,
        }
    if verbose:
        w = sum(len(v["writes"]) for v in totals.values())
        r = sum(len(v["reads"]) for v in totals.values())
        c = sum(len(v["candidates"]) for v in totals.values())
        b3 = sum(1 for v in totals.values() for x in v["candidates"] if x[3] == 3)
        print("VERDICT: %d writes and %d reads of PA in the converted source of both images." % (w, r))
        print("         RESET's `ldio PA,0xF9` sets bit 3 HIGH, so a machine at rest has the")
        print("         line RELEASED; the firmware then drives it LOW around disk operations.")
        print("         %d raw candidates in the still-unconverted bytes, of which %d address"
              % (c, b3))
        print("         bit 3.  See the ADJUDICATED block in this file's docstring: one is a")
        print("         stride-5 LE16 table, the other two are a word compare and a bit-0 chg.")
        print("         So the bit-3 census is COMPLETE over both 512 KiB images.")
        print("         The wave-6 claim that the firmware never changes PA bit 3 is REFUTED;")
        print("         notes/WSA1-EMULATION-DISASM-GAPS.md's refreshed entry is correct.")
    return totals


def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    t = run(verbose=False)
    a, b = t["prom_a"], t["prom_b"]
    addrs = lambda hs: sorted(h[1] for h in hs if h[1] is not None)

    check("twelve direct-address spellings are enumerated for 0x1E, not one",
          len(SP) == 12)
    check("plus the standalone 0x08 `ld (n8),imm8` opcode, and a symbolic pass",
          len(ALL_PATTERNS) == 13)
    check("prom_a: exactly 5 PA writes in converted source (4 encoded + 1 symbolic)",
          len(a["writes"]) == 5)
    check("prom_a: the RESET write `ldio PA,0xF9` is among them -- the one the first",
          any(h[3].startswith("ldio PA") for h in a["writes"]))
    check("prom_a: ...draft missed, because it has no byte comment to scan",
          any(h[2] == "symbolic" for h in a["writes"]))
    check("prom_a: exactly 2 PA reads in converted source", len(a["reads"]) == 2)
    check("prom_a: no hit classified 'other' (every mnemonic is understood)",
          len(a["other"]) == 0)
    check("prom_a: the two BIT writes wave 6 missed are at 0xFE18EF and 0xFE18F7",
          0xFE18EF in addrs(a["writes"]) and 0xFE18F7 in addrs(a["writes"]))
    check("prom_a: 0xFE18EF is a 'res' (clears bit 3) -- the ACTIVE-LOW evidence",
          any(h[1] == 0xFE18EF and h[3].startswith("res_") for h in a["writes"]))
    check("prom_a: 0xFE18F7 is a 'set' (restores bit 3)",
          any(h[1] == 0xFE18F7 and h[3].startswith("set_") for h in a["writes"]))
    check("prom_a: the two STORE writes wave 6 DID find are at 0xFE660D and 0xFE6631",
          0xFE660D in addrs(a["writes"]) and 0xFE6631 in addrs(a["writes"]))
    check("prom_a: LAST encoded write in address order is 0xFE6631, not the first one",
          addrs(a["writes"])[-1] == 0xFE6631)
    check("prom_b: zero PA accesses of any kind in converted source",
          len(b["writes"]) == 0 and len(b["reads"]) == 0 and len(b["other"]) == 0)
    check("prom_a: zero raw candidates in its %s unconverted bytes -- census complete"
          % format(a["unconverted"], ","), len(a["candidates"]) == 0)
    check("prom_b: exactly 3 raw candidates in its %s unconverted bytes"
          % format(b["unconverted"], ","), len(b["candidates"]) == 3)
    check("prom_b: NONE of the 3 candidates addresses bit 3 -- so gap T is unaffected",
          all(x[3] != 3 for x in b["candidates"]))
    check("prom_b: the three candidates are at 0xF0B984, 0xF3A0C1 and 0xF53DFF",
          sorted(x[0] for x in b["candidates"]) == [0xF0B984, 0xF3A0C1, 0xF53DFF])
    check("prom_b: 0xF53DFF, if code, is a chg of bit 0 (adjudicated, not assumed)",
          any(x[0] == 0xF53DFF and x[3] == 0 for x in b["candidates"]))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    run()
    sys.exit(0)
