#!/usr/bin/env python3
"""Does every address a "Called from:" line names actually START a call to that routine?

WHY THIS EXISTS
  This tree's own history includes "call sites cited one byte past the instruction, ~20 times,
  systematically".  The cause is easy to see once you know it: `notes/prom_c_xrefs.py` prints
  the address of the LITERAL it matched, and the instruction that owns the literal begins one
  or two bytes earlier.  Copying the tool's address into a header is therefore wrong by
  default, and the byte gate cannot see it.

  This re-checks every such claim mechanically:

    1. it parses `prom_c/wsa1_prom_c.s` for `; Called from:` blocks, collecting every
       0xXXXXXX address mentioned before the next `; Inputs:` / `; Evidence:` line;
    2. it takes the routine's own address from the `; ADDR` comment on the first instruction
       line after the label;
    3. it disassembles ONE instruction at each cited address and checks that it is a
       call/calr/jp/jrl whose target is that routine.

  Anything that is not is printed.  Some of what it prints is legitimate -- a header may cite
  the address of a *pointer table entry*, or the caller may reach the routine through a
  register -- so the output is a list to READ, not a pass/fail.  It is the tool for a
  self-audit before shipping a pass, and its value is that it cannot be fooled by prose.

  ★ 2026-08-25: "29 did not decode" was a NUMBER WITHOUT A MEANING.  A `Called from:`
  paragraph is prose, and this tool harvests EVERY 0xXXXXXX in it, so a data address, a
  RAM variable or the address of the calling ROUTINE all land in the same bucket as a
  genuinely mis-cited call site.  Each non-decoding row is now CLASSIFIED against the
  ROM, and only the last class is a defect:

    RAM       the address is outside this ROM image entirely (< 0xF80000).  It cannot be
              a call site here; it is a variable or a scheduler byte named in the prose.
    PTR32     the little-endian 24/32-bit word AT the cited address IS the routine's
              address -- a pointer-table entry, which is how the routine is reached.
    IN-ROUTINE  a literal transfer to the routine begins later inside [addr, addr+0x400).
              The header cited the CALLING ROUTINE, not the call instruction.  The real
              site is printed next to it.
    OFF-BY-N  ★ THE DEFECT THIS TOOL EXISTS FOR: a literal transfer to the routine begins
              within 8 bytes of the cited address but NOT at it.  This tree's history has
              ~20 of these, all from copying prom_c_xrefs.py's literal address instead of
              the instruction start.  MUST BE ZERO.
    PROSE     none of the above -- an address mentioned for context.  Read it.

  "Literal transfer" here is a byte scan for `1D` + 24-bit target (call), `1B` + 24-bit
  target (jp) and `1E dd dd` (calr, target = addr + 3 + disp), the same three forms
  notes/prom_c_xrefs.py documents.  Short `jr`/8-bit `calr` and register-indirect calls
  are invisible to it, so PROSE never means "nothing reaches this from there".

RUN
  python3 notes/prom_c_audit_callsites.py
  python3 notes/prom_c_audit_callsites.py --quiet     # only the rows that did not check out
  python3 notes/prom_c_audit_callsites.py --strict    # exit 1 if any OFF-BY-N row exists
  python3 notes/prom_c_audit_callsites.py --selftest  # negative controls on the classifier
"""
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠ prom_c is 26 files now (notes/prom_c_split.py): the master alone is 2% of
# the image, and this scan passed VACUOUSLY over it until this line changed.
# notes/probe_health.py is the check; notes/asm_source.py is the reader,
# and it absorbed the prom_c-only shim that used to stand here.
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
IMG = open(ROM, "rb").read()

ADDR = re.compile(r'0x([0-9A-Fa-f]{6})')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
INSTR_ADDR = re.compile(r';\s*([0-9A-F]{6})\s')


def dis1(addr):
    off = addr - BASE
    if not (0 <= off < len(IMG)):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(IMG[off:off + 12])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    first = p.stdout.splitlines()
    return first[0] if first else None


_SITES = {}


def transfer_sites(routine):
    """Addresses where a LITERAL control transfer to `routine` begins.

    Three byte forms, the ones notes/prom_c_xrefs.py documents:
        1D <24-bit LE target>     call
        1B <24-bit LE target>     jp
        1E <16-bit LE disp>       calr, target = site + 3 + disp
    A byte pattern is not a proven instruction; this is used only to EXPLAIN a
    row, never to add one.
    """
    if routine in _SITES:
        return _SITES[routine]
    out = set()
    tgt = struct.pack("<I", routine)[:3]
    for op in (0x1D, 0x1B):
        pat = bytes([op]) + tgt
        i = IMG.find(pat)
        while i >= 0:
            out.add(BASE + i)
            i = IMG.find(pat, i + 1)
    i = 0
    while True:
        i = IMG.find(b"\x1e", i)
        if i < 0 or i + 3 > len(IMG):
            break
        disp = int.from_bytes(IMG[i + 1:i + 3], "little", signed=True)
        if BASE + i + 3 + disp == routine:
            out.add(BASE + i)
        i += 1
    _SITES[routine] = out
    return out


def classify(routine, a):
    """Why does the cited address `a` not decode to a transfer to `routine`?"""
    if not (BASE <= a < BASE + len(IMG)):
        return "RAM", ""
    sites = transfer_sites(routine)
    near = sorted(s for s in sites if s != a and abs(s - a) <= 8)
    if near:
        return "OFF-BY-N", "real site 0x%06X (%+d)" % (near[0], near[0] - a)
    off = a - BASE
    if off + 4 <= len(IMG):
        w32 = struct.unpack_from("<I", IMG, off)[0]
        if w32 == routine or (w32 & 0xFFFFFF) == (routine & 0xFFFFFF):
            return "PTR32", "the word at 0x%06X IS 0x%06X" % (a, routine)
    inside = sorted(s for s in sites if a < s < a + 0x400)
    if inside:
        return "IN-ROUTINE", "real site 0x%06X, %d byte(s) in" % (inside[0], inside[0] - a)
    return "PROSE", ""


def selftest():
    """Negative controls -- the classifier must not agree with everything."""
    fails = []
    # 1. a KNOWN pointer-table entry classifies as PTR32
    if classify(0xF98D9A, 0xFCC53F)[0] != "PTR32":
        fails.append("entry 0 of Link_ClassHandlerTable is not seen as PTR32")
    # 2. a RAM address classifies as RAM
    if classify(0xF98A75, 0x007ED1)[0] != "RAM":
        fails.append("0x007ED1 is not seen as RAM")
    # 3. a REAL call site is found by the scanner (Kernel_SemaSignal, two sites)
    if 0xFA2DE1 + 3 not in transfer_sites(0xF98510):
        fails.append("the known `call 0xf98510` at 0xFA2DE4 is not in transfer_sites")
    # 4. LAST-ELEMENT control: the highest site of the compiler block move
    bm = transfer_sites(0xF9A038)
    if not bm or max(bm) != 0xFC575B:
        fails.append("the LAST `call 0xf9a038` site is not 0xFC575B (got %s)"
                     % (("0x%06X" % max(bm)) if bm else "none"))
    # 5. an address one byte past a real site must be OFF-BY-N, not PROSE
    if classify(0xF98510, 0xFA2DE5)[0] != "OFF-BY-N":
        fails.append("one byte past a real site is not flagged OFF-BY-N")
    # 6. an address with nothing near it must be PROSE
    if classify(0xF98510, 0xFE0000)[0] != "PROSE":
        fails.append("0xFE0000 is not seen as PROSE for Kernel_SemaSignal")
    for f in fails:
        print("  FAIL " + f)
    print("SELFTEST %s (6 controls)" % ("FAIL" if fails else "PASS"))
    return 1 if fails else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    quiet = "--quiet" in sys.argv
    strict = "--strict" in sys.argv
    lines = open(SRC).read().splitlines()
    pending, rows = [], []
    i = 0
    while i < len(lines):
        ln = lines[i]
        if "; Called from:" in ln:
            pending = []
            j = i
            while j < len(lines) and lines[j].startswith(";"):
                if j > i and re.match(r';\s*(Inputs|Outputs|Evidence|Unknown|Packet|Dispatch):',
                                      lines[j]):
                    break
                pending += [int(m, 16) for m in ADDR.findall(lines[j])]
                j += 1
            i = j
            continue
        m = LABEL.match(ln)
        if m and pending:
            # the routine's address is on the first instruction line after the label
            ra = None
            for k in range(i + 1, min(i + 4, len(lines))):
                mm = INSTR_ADDR.search(lines[k])
                if mm:
                    ra = int(mm.group(1), 16)
                    break
            if ra is not None:
                for a in pending:
                    if a == ra:
                        continue
                    rows.append((m.group(1), ra, a))
            pending = []
        i += 1

    bad = 0
    census = {}
    for name, ra, a in rows:
        txt = dis1(a) or "<undecodable>"
        body = txt.split(":", 1)[1] if ":" in txt else txt
        ok = re.search(r'\b(call|calr|jp|jrl|jr)\b', body) and ("%06x" % ra) in body.lower()
        cls, why = ("SITE", "") if ok else classify(ra, a)
        if not ok:
            bad += 1
            census[cls] = census.get(cls, 0) + 1
        if ok and quiet:
            continue
        print("%-38s -> 0x%06X  cited 0x%06X  %-10s %s%s"
              % (name, ra, a, cls if not ok else "OK", txt.strip(),
                 ("   <- " + why) if why else ""))
    print("\n%d cited call site(s) checked, %d did not decode to a transfer to the routine"
          % (len(rows), bad))
    print("  of those %d, classified against the ROM:" % bad)
    for k in ("OFF-BY-N", "RAM", "PTR32", "IN-ROUTINE", "PROSE"):
        print("      %-11s %3d%s" % (k, census.get(k, 0),
                                     "   ★ MUST BE ZERO" if k == "OFF-BY-N" else ""))
    if strict and census.get("OFF-BY-N", 0):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
