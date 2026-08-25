#!/usr/bin/env python3
"""Every site in CPU 1's ROMs that names an address -- ALL TWELVE direct spellings.

QUESTION IT ANSWERS
    "Which instructions in prom_a + prom_b touch memory address X, and which of
     those hits are real instruction boundaries rather than bytes that happen to
     lie inside another instruction?"

WHY IT EXISTS (audit round 1, findings F4 and F6)
    Two headers in this tree censused an address by grepping for ONE spelling --
    `F2 <lo> <mid> <hi>`, the 24-bit form -- and then wrote "every site that
    touches it" / "a census of every reference".  The TLCS-900 has three direct
    address widths in each of four prefix groups, so one spelling is one twelfth
    of the search.  prom_c's 0x00F2F3 census missed two real reads that way.

THE TWELVE SPELLINGS
    The memory-operand prefix groups are 0xC0 (byte operand), 0xD0 (word),
    0xE0 (long) and 0xF0 (memory-destination ops: `ld (mem),#`, bit ops, ...).
    Within each group the low three bits pick the addressing mode, and modes
    0/1/2 are an 8-, 16- and 24-bit ABSOLUTE address, little-endian
    (../mame/src/devices/cpu/tlcs900/dasm900.cpp:1525-1543 -- `case 0x00`
    reads one byte, `0x01` two, `0x02` three).  So the twelve are
    {0xC0,0xD0,0xE0,0xF0} x {+0, +1, +2}.  An 8-bit form can only spell an
    address below 0x100 and a 16-bit form one below 0x10000; the script emits
    only the spellings that can reach the requested address.

THE CONVERGENCE TEST -- what makes a hit believable
    A byte match is not an instruction.  For each candidate the script starts a
    linear disassembly at site-1, site-2, ... site-BACK and asks how many of
    those streams step exactly onto the site.  A real instruction is reached by
    nearly all of them (self-synchronising code); a coincidence inside a longer
    instruction or inside data is reached by few or none.  The instruction
    length table is unidasm's, built once per byte phase exactly as
    scripts/analysis/trace_code.py builds it (a TLCS-900 instruction decodes the
    same wherever the sweep that found it started).

    Nothing here is a proof.  A site with 0/24 convergence has still not been
    shown to be data, and a site with 24/24 has still not been shown to be
    reached.  It is a filter, and the raw byte hits are always printed too.

USAGE
    python3 notes/prom_a_addr_census.py 0x00008A
    python3 notes/prom_a_addr_census.py 0xBE 0x00F2F3
    python3 notes/prom_a_addr_census.py --min-converge 12 0x00008A
    python3 notes/prom_a_addr_census.py --selftest

    --selftest re-derives the two numbers this script was written to fix:
    the (0x8A) site list of notes/FINDINGS-interprocessor-link.md and the
    (0xBE) claim of notes/FINDINGS-interrupt-vectors.md.  Exits non-zero if
    either disagrees with what those notes now say.
"""
import os
import pickle
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
PHASES = 32
BACK = 64
MIN_CONV = 10   # observed separation: real sites 17-64/64, byte coincidences 0/64

IMGS = [
    ("prom_a", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    ("prom_b", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
]

LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*)$')
_TAB = {}


def decode_table(path, base):
    """addr -> (length, text), merged over all byte phases.  Same method as
    scripts/analysis/trace_code.py:decode_table.

    Building it costs ~60 s per image (32 unidasm runs), so it is cached on disk
    under $WSA1_CENSUS_CACHE (default /tmp/wsa1_census_dectab.pkl), keyed by the
    ROM's size and mtime.  Delete the file to rebuild."""
    key = (path, base)
    if key in _TAB:
        return _TAB[key]
    st = os.stat(path)
    ck = (path, base, st.st_size, int(st.st_mtime))
    cache = os.environ.get("WSA1_CENSUS_CACHE", "/tmp/wsa1_census_dectab.pkl")
    disk = {}
    if os.path.exists(cache):
        try:
            with open(cache, "rb") as fh:
                disk = pickle.load(fh)
        except Exception:                                        # noqa: BLE001
            disk = {}
    if ck in disk:
        _TAB[key] = disk[ck]
        return disk[ck]
    tab = {}
    data = open(path, "rb").read()
    with tempfile.TemporaryDirectory() as td:
        for ph in range(PHASES):
            chunk = os.path.join(td, "c.bin")
            open(chunk, "wb").write(data[ph:])
            out = subprocess.run([UNIDASM, chunk, "-arch", "tlcs900",
                                  "-basepc", hex(base + ph)],
                                 capture_output=True, text=True).stdout
            for ln in out.splitlines():
                m = LINE.match(ln)
                if not m:
                    continue
                a = int(m.group(1), 16)
                if a not in tab:
                    tab[a] = (len(m.group(2).split()), m.group(3).strip())
    _TAB[key] = tab
    disk[ck] = tab
    try:
        with open(cache, "wb") as fh:
            pickle.dump(disk, fh, protocol=4)
    except Exception:                                            # noqa: BLE001
        pass
    return tab


def spellings(addr):
    """[(name, bytes)] -- every direct-address encoding that can reach addr."""
    out = []
    for gname, g in (("C", 0xC0), ("D", 0xD0), ("E", 0xE0), ("F", 0xF0)):
        if addr < 0x100:
            out.append(("%02X+d8" % g, bytes([g + 0, addr & 0xFF])))
        if addr < 0x10000:
            out.append(("%02X+d16" % (g + 1),
                        bytes([g + 1, addr & 0xFF, (addr >> 8) & 0xFF])))
        out.append(("%02X+d24" % (g + 2),
                    bytes([g + 2, addr & 0xFF, (addr >> 8) & 0xFF,
                           (addr >> 16) & 0xFF])))
    return out


def converge(tab, site, base, size):
    """How many of the BACK backward starts step exactly onto `site`."""
    hits = 0
    for k in range(1, BACK + 1):
        a = site - k
        if a < base:
            continue
        while a < site:
            if a not in tab:
                break
            a += tab[a][0]
        if a == site:
            hits += 1
    return hits


def census(addr, min_converge=0, quiet=False):
    """[(image, site_addr, spelling, converged, text)] for one address."""
    rows = []
    for name, path, base in IMGS:
        data = open(path, "rb").read()
        tab = decode_table(path, base)
        for sname, pat in spellings(addr):
            i = data.find(pat)
            while i >= 0:
                site = base + i
                c = converge(tab, site, base, len(data))
                txt = tab.get(site, (0, "<no decode>"))[1]
                rows.append((name, site, sname, c, txt))
                i = data.find(pat, i + 1)
    rows.sort(key=lambda r: (r[0], r[1]))
    if not quiet:
        print("=== 0x%06X === (%d byte hits over %d spellings, BACK=%d)"
              % (addr, len(rows), len(spellings(addr)), BACK))
        for name, site, sname, c, txt in rows:
            mark = "  " if c >= min_converge else "??"
            print("  %s %-7s 0x%06X  %-7s  %2d/%d  %s"
                  % (mark, name, site, sname, c, BACK, txt))
    return rows


def selftest():
    """Re-derive the two counts this script was written to correct."""
    ok = True

    # (1) FINDINGS-interprocessor-link.md -- the (0x8A) sites.
    #     NINE instructions touch the byte; SIX of them touch bit 7.
    rows = census(0x00008A, min_converge=MIN_CONV, quiet=True)
    good = sorted(r[1] for r in rows if r[3] >= MIN_CONV)
    want_all = [0xF8E16C, 0xF8E1EA, 0xF8E22B, 0xF8E23C, 0xF8E25B,
                0xF8E4F7, 0xF8E5E6, 0xF8E671, 0xF8E68F]
    bit7 = sorted(r[1] for r in rows
                  if r[3] >= MIN_CONV and re.search(r"\b(set|res|bit) 7,", r[4]))
    want_b7 = [0xF8E16C, 0xF8E1EA, 0xF8E25B, 0xF8E5E6, 0xF8E671, 0xF8E68F]
    print("  (0x8A) all converged sites : %s" % ["0x%06X" % a for a in good])
    print("  (0x8A) bit-7 sites         : %s" % ["0x%06X" % a for a in bit7])
    print("  spellings that converged   : %s"
          % sorted({r[2] for r in rows if r[3] >= MIN_CONV}))
    if good != want_all:
        ok = False; print("  MISMATCH on the full site list")
    if bit7 != want_b7:
        ok = False; print("  MISMATCH on the bit-7 site list")

    # (2) FINDINGS-interrupt-vectors.md -- "only three accesses to (0xBE)".
    rows = census(0x0000BE, min_converge=MIN_CONV, quiet=True)
    good = sorted(r[1] for r in rows if r[3] >= MIN_CONV)
    print("  (0xBE) converged sites     : %s" % ["0x%06X" % a for a in good])
    if good != [0xF85600, 0xF85735, 0xF8573E]:
        ok = False; print("  MISMATCH: the note says exactly these three")

    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    if "--selftest" in sys.argv:
        return selftest()
    mc = MIN_CONV
    args = []
    it = iter(sys.argv[1:])
    for a in it:
        if a == "--min-converge":
            mc = int(next(it))
        else:
            args.append(a)
    if not args:
        print(__doc__)
        return 1
    for a in args:
        census(int(a, 16), min_converge=mc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
