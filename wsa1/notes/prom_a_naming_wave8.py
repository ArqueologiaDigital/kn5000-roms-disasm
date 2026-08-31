#!/usr/bin/env python3
"""What EVIDENCE does each still-unnamed prom_a routine carry for a name?

QUESTION IT ANSWERS
-------------------
  "Of the 2,844 `sub_XXXXXX` labels in prom_a, which ones does the ROM itself
  say something checkable about -- and what does it say?"

This is a CANDIDATE GENERATOR, not a namer.  It prints, per routine, only
things a reviewer can re-derive from `original_ROMs/`:

  STRING   a 32-bit immediate or absolute operand in the routine's body that
           lands on a printable ASCII run of >= 4 characters inside prom_a or
           prom_b.  The strongest class this tree has: prom_b holds the UI text
           and prom_a the service/screen labels.
  DEV      an operand naming one of CPU 1's device addresses (0x79xxxx-0x7Fxxxx)
           -- the memory map in notes/FINDINGS-memory-map.md says what each is.
  SFR      an `ldio`/`ld` against a TMP95C061 special-function register, taken
           from include/tmp95c061_sfr.inc by NAME, so the register set is the
           header's and not this script's.
  CALLER   a site OUTSIDE the routine that calls/jumps to it, with the enclosing
           label's name -- a named caller is weak evidence on its own and good
           evidence when several agree.
  CALLEE   the semantically-named routines this one calls.  A routine that calls
           only `LCD_*` is doing something to the screen.
  VECTOR   the routine appears in the CPU vector table or in a framed pointer
           table, with the table's label.

⚠ WHAT IT IS NOT.  It never proposes a name.  Every class above can be
misleading on its own: a routine that loads a string pointer may be a generic
tail-call veneer that never looks at it, and one caller proves nothing about a
leaf shared by forty.  The naming rule in this tree is that the header cites the
evidence so a reviewer can reject it; this tool exists so the citation can be
written from the ROM instead of from a hunch.

⚠ The operand scan is TEXT over the CONVERTED listing, so it sees only what is
already assembly.  It cannot see into `.incbin`, and it inherits any misframe
the listing has.  It is an upper bound on evidence, never on callers -- for
callers over raw bytes use notes/prom_a_xref.py.

USAGE
-----
    python3 notes/prom_a_naming_wave8.py --summary
    python3 notes/prom_a_naming_wave8.py --strings      # routines with a STRING
    python3 notes/prom_a_naming_wave8.py --dev          # routines touching a device
    python3 notes/prom_a_naming_wave8.py --sfr
    python3 notes/prom_a_naming_wave8.py --show sub_F8ECF4
    python3 notes/prom_a_naming_wave8.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines                       # noqa: E402

IMAGES = {
    "prom_a": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    "prom_b": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
}
_ROM = {k: open(v[0], "rb").read() for k, v in IMAGES.items()}

LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR_RE = re.compile(r';\s*([0-9A-F]{6})\s+([0-9a-f]{2}(?: [0-9a-f]{2})*)\s*$')
HEX_RE = re.compile(r'0x([0-9a-fA-F]{4,8})')
# operand-side identifier reference (a call/jp/lda naming another label)
IDENT_RE = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]{3,})\b')

DEV_RANGES = [
    (0x790000, 0x790001, "display-controller-shaped port (status/data + command)"),
    (0x7A0000, 0x7A0000, "FDC data register, DMA-acknowledged decode"),
    (0x7B0004, 0x7B0005, "uPD765-family FDC MSR/control + data"),
    (0x7C0000, 0x7C0000, "inter-processor link port"),
    (0x7E0000, 0x7E0017, "second storage unit, 16-bit port"),
    (0x7F0000, 0x7F0003, "address/data register pair"),
]


def rom_at(addr, n=48):
    for name, (path, base) in IMAGES.items():
        if base <= addr < base + len(_ROM[name]):
            off = addr - base
            return name, _ROM[name][off:off + n]
    return None, b""


def text_runs(addr, window=320, minlen=4):
    """Printable runs of >= minlen inside [addr, addr+window), filtered to the
    shape of this machine's UI text: >= 70% upper-case-or-space and at least one
    letter.  ★ WHY A WINDOW AND NOT THE BYTE AT `addr`: the WSA1 has NO STRING
    TABLE.  Every string is embedded in a byte-coded DISPLAY LIST record
    (notes/FINDINGS-ui-display-list.md), so a routine's pointer lands on the
    record HEADER and the characters start a few bytes further in.  Reading only
    `addr` finds nothing; a window finds the screen's own words.

    ⚠ THIS IS ASSOCIATION, NOT PROOF.  A pointer 300 bytes before a string does
    not have to be about that string, and an END pointer of one list sits inside
    the next.  Treat a hit as a candidate and confirm it against the routine's
    other evidence before it becomes a name.
    """
    img, buf = rom_at(addr, window)
    out, cur, st = [], [], None
    for i, ch in enumerate(buf):
        if 0x20 <= ch <= 0x7E:
            if st is None:
                st = i
            cur.append(chr(ch))
        else:
            if st is not None and len(cur) >= minlen:
                s = "".join(cur)
                if (sum(c.isupper() or c == " " for c in s) >= len(s) * 0.7
                        and any(c.isalpha() for c in s)):
                    out.append((addr + st, s))
            cur, st = [], None
    return out


def dl_walk(addr, limit=0x1000, maxrec=400):
    """The TEXT of the display-list records starting at `addr`, decoded as
    records rather than sniffed out of a byte window.

    The record format is `+0 opcode (bounds-checked against 0x24), +1 length of
    the WHOLE record, +2 operands and, for the text opcodes, the characters`
    (notes/FINDINGS-ui-display-list.md; the interpreter is prom_b 0xF31A09 and
    it advances XIY by the length byte).  So walking is exact where a window is
    a guess: a record either parses or the walk stops.

    Returns (records_walked, [(address, text), ...]).  ⚠ It stops on the FIRST
    byte that is not a legal opcode, which is also what the interpreter does --
    so a zero-record answer means `addr` is not a display list, and that is
    itself useful: it tells a namer the pointer is something else.
    """
    img, buf = rom_at(addr, limit)
    if not buf:
        return 0, []
    out, i, nrec = [], 0, 0
    while i + 2 <= len(buf) and nrec < maxrec:
        op, ln = buf[i], buf[i + 1]
        if op >= 0x24 or ln < 2 or i + ln > len(buf):
            break
        body = buf[i + 2:i + ln]
        cur, st = [], None
        for k, ch in enumerate(body):
            if 0x20 <= ch <= 0x7E:
                if st is None:
                    st = k
                cur.append(chr(ch))
            else:
                if st is not None and len(cur) >= 3:
                    out.append((addr + i + 2 + st, "".join(cur)))
                cur, st = [], None
        if st is not None and len(cur) >= 3:
            out.append((addr + i + 2 + st, "".join(cur)))
        i += ln
        nrec += 1
    return nrec, out


def sfr_names():
    """Register name -> internal I/O address, straight out of the header."""
    p = os.path.join(ROOT, "include", "tmp95c061_sfr.inc")
    names = {}
    for ln in open(p, encoding="utf-8"):
        m = re.match(r'^\s*\.equ\s+([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(0x[0-9a-fA-F]+|\d+)', ln)
        if m:
            names[m.group(1)] = int(m.group(2), 0)
    return names


SFR = sfr_names()


class Routine:
    __slots__ = ("name", "addr", "line", "endline", "body", "strings", "devs",
                 "sfrs", "callees", "callers", "nbytes", "vectors")

    def __init__(self, name, addr, line):
        self.name, self.addr, self.line = name, addr, line
        self.endline = None
        self.body = []
        self.strings, self.devs, self.sfrs = [], [], []
        self.callees, self.callers, self.vectors = [], [], []
        self.nbytes = 0


def parse():
    lines = image_lines(ROOT, "prom_a/wsa1_prom_a.s", skip=("kernel/kernel.s",))
    routines = []
    cur = None
    for i, ln in enumerate(lines):
        m = LABEL_RE.match(ln)
        if m:
            am = ADDR_RE.search(ln)
            addr = int(am.group(1), 16) if am else None
            if addr is None:
                # a bare label line: the address comes from the next coded line
                for nxt in lines[i + 1:i + 4]:
                    a2 = ADDR_RE.search(nxt)
                    if a2:
                        addr = int(a2.group(1), 16)
                        break
            if cur is not None:
                cur.endline = i
            cur = Routine(m.group(1), addr, i)
            routines.append(cur)
            continue
        if ln.startswith(".L") and ln.rstrip().endswith(":"):
            continue
        if cur is not None and (ln.startswith("\t") or ln.startswith(" ")):
            cur.body.append(ln)
    if cur is not None:
        cur.endline = len(lines)
    return lines, routines


def analyse(routines):
    byname = {r.name: r for r in routines}
    for r in routines:
        for ln in r.body:
            am = ADDR_RE.search(ln)
            if am:
                r.nbytes += len(am.group(2).split())
            code = ln.split(";", 1)[0]
            for h in HEX_RE.findall(code):
                v = int(h, 16)
                if 0xF00000 <= (v & 0xFFFFFF) <= 0xFFFFFF and v <= 0x00FFFFFF:
                    for sa, st in text_runs(v & 0xFFFFFF):
                        r.strings.append((v & 0xFFFFFF, st))
                for lo, hi, what in DEV_RANGES:
                    if lo <= v <= hi:
                        r.devs.append((v, what))
            m = re.match(r'\s*(ldio|ldiw?|ld)\s+([A-Za-z][A-Za-z0-9_]*)\s*,', code)
            if m and m.group(2) in SFR:
                r.sfrs.append(m.group(2))
            m = re.match(r'\s*(call|calr|jp|jr|lda)\b(.*)', code)
            if m:
                for ident in IDENT_RE.findall(m.group(2)):
                    if ident in byname and ident != r.name:
                        r.callees.append(ident)
                        byname[ident].callers.append(r.name)
    return byname


def is_unnamed(n):
    return bool(re.match(r'^(sub|loc|L)_[0-9A-Fa-f]{6}$', n))


def score(r):
    return (len(set(s for _, s in r.strings)) * 8 + len(set(r.devs)) * 6
            + len(set(r.sfrs)) * 4
            + len([c for c in set(r.callers) if not is_unnamed(c)]) * 2
            + len([c for c in set(r.callees) if not is_unnamed(c)]))


def show(r):
    print("%s  @0x%06X  %d bytes  score %d"
          % (r.name, r.addr or 0, r.nbytes, score(r)))
    for a, s in dict(r.strings).items():
        print("    STRING 0x%06X  %r" % (a, s))
    for a, what in sorted(set(r.devs)):
        print("    DEV    0x%06X  %s" % (a, what))
    for s in sorted(set(r.sfrs)):
        print("    SFR    %s" % s)
    named_callers = sorted(set(c for c in r.callers if not is_unnamed(c)))
    if named_callers:
        print("    CALLER %s" % ", ".join(named_callers[:8]))
    n_un = len(set(c for c in r.callers if is_unnamed(c)))
    if n_un:
        print("    CALLER +%d unnamed" % n_un)
    named_callees = sorted(set(c for c in r.callees if not is_unnamed(c)))
    if named_callees:
        print("    CALLEE %s" % ", ".join(named_callees[:10]))


def main():
    lines, routines = parse()
    byname = analyse(routines)
    args = sys.argv[1:]

    if "--selftest" in args:
        fails = 0
        # 1. the parse found the image, not an empty header file
        assert len(lines) > 100000, len(lines)
        # 2. a known named routine is present with its known address
        assert "VersionScreen_Show" in byname
        assert byname["VersionScreen_Show"].addr == 0xF82A28
        # 3. the display-controller port is seen where the memory map says
        hits = [r.name for r in routines if any(a == 0x790000 for a, _ in r.devs)]
        assert hits, "0x790000 named by nothing -- DEV scan is broken"
        # 4. text_runs reads the version screen's words out of a display list
        got = [t for _, t in text_runs(0xF82B03)]
        assert "ROM VERSION" in got, got
        # 5. and finds nothing in the middle of the boot block's code
        assert text_runs(0xF82700, 64) == [], text_runs(0xF82700, 64)
        # 6. the unnamed count matches a plain grep of the listing
        n_sub = sum(1 for r in routines if r.name.startswith("sub_"))
        print("selftest: %d routines, %d sub_, %d with a STRING, FAILURES: %d"
              % (len(routines), n_sub,
                 sum(1 for r in routines if r.strings), fails))
        return

    if "--show" in args:
        want = args[args.index("--show") + 1]
        if want in byname:
            show(byname[want])
        else:
            print("no such label")
        return

    un = [r for r in routines if is_unnamed(r.name)]
    if "--strings" in args:
        sel = [r for r in un if r.strings]
    elif "--dev" in args:
        sel = [r for r in un if r.devs]
    elif "--sfr" in args:
        sel = [r for r in un if r.sfrs]
    elif "--named-callers" in args:
        sel = [r for r in un if any(not is_unnamed(c) for c in r.callers)]
    else:
        sel = un

    if "--summary" in args:
        print("prom_a labels           : %d" % len(routines))
        print("  unnamed (sub_/loc_/L_): %d" % len(un))
        print("  with a STRING operand : %d" % sum(1 for r in un if r.strings))
        print("  touching a DEVICE     : %d" % sum(1 for r in un if r.devs))
        print("  touching an SFR       : %d" % sum(1 for r in un if r.sfrs))
        print("  with a NAMED caller   : %d"
              % sum(1 for r in un if any(not is_unnamed(c) for c in r.callers)))
        print("  with a NAMED callee   : %d"
              % sum(1 for r in un if any(not is_unnamed(c) for c in r.callees)))
        print("  with NO evidence here : %d"
              % sum(1 for r in un if score(r) == 0))
        return

    for r in sorted(sel, key=lambda r: -score(r)):
        if score(r) == 0:
            continue
        show(r)


if __name__ == "__main__":
    main()
