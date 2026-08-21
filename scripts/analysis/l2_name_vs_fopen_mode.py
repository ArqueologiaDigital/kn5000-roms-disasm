#!/usr/bin/env python3
"""L2 quality: does a routine's NAME agree with the file mode it actually opens?

docs/IS-IT-DONE.md warns that the L2 percentage is a lower bound on naming
COVERAGE and says nothing about APTNESS -- a confidently wrong name scores as
semantic. This script makes one class of wrongness measurable instead of feared.

Ground truth: a routine that opens a file passes a mode string, and the mode is
not a matter of opinion. `"wb"` writes. `"rb"` reads. If a routine called
SomethingLoad/Read/Get opens `"wb"`, one of the two is lying.

Method (TLCS-900, v10 image):
    ld XBC, imm32   is  41 <LE32>     -- the mode string pointer
    call addr24     is  1D <LE24>     -- taken within 16 bytes after
The enclosing routine is the greatest symbol address <= the site, read from
symbols/maincpu_symbols_reference.txt (regenerate it first if the tree moved --
scripts/analysis/l2_symbol_reference.py --regen).

Run:  python3 scripts/analysis/l2_name_vs_fopen_mode.py [--all]
Exits non-zero if any routine's name contradicts its mode.

Standing result (2026-08-21): 57 sites, 3 flagged, 2 of them false positives on
inspection -- leaving ONE genuine oddity, `LoadFileVariant` at 0xF8805B, which
passes "wb" (mode string 0xEA0244, verified) despite its name. The script exits
non-zero while that stands, because it is real unfinished naming work.

⚠ A verb does not say what it acts on. Two of the three flags were routines that
"write" an extension into a NAME BUFFER. Any heuristic on names alone will hit
these; that is why flagged rows get read before they get believed.

⚠ Scope. This finds only name-vs-mode contradictions. It cannot see a routine
whose name is wrong in some other way -- FileIO_ReadHeader, which this session
proved builds a path and never reads a header, opens nothing and so does not
appear here at all. Absence from this list is not evidence a name is right.
"""
import os, re, struct, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
ROM = os.path.join(ROOT, "original_ROMs", "kn5000_v10_program.rom")
SYMS = os.path.join(ROOT, "symbols", "maincpu_symbols_reference.txt")
BASE = 0xE00000

READ_WORDS = ("read", "load", "get", "open", "import", "restore", "recall")

# Reviewed by hand and found BENIGN: "write" here means writing into a name
# BUFFER, not to a file. Both sit among StylCnv_*_FindDot / FindDot2 / FindDot3,
# i.e. they are filename builders. The heuristic cannot tell those apart -- a
# verb alone does not say what it acts on -- so they are listed rather than
# silently excluded.
REVIEWED_BENIGN = {
    "StylCnv_Single_WriteTMExtension": "writes the .TM extension into a name buffer",
    "StylCnv_LSW_WriteExtension": "writes the .LSW extension into a name buffer",
}
WRITE_WORDS = ("write", "save", "store", "put", "export", "dump")


def mode_strings(d):
    out = {}
    for m in re.finditer(rb'[rwa]b?\+?\x00', d):
        s = d[m.start():m.end() - 1]
        # separators here are 0x00 OR 0xFF -- an earlier version required 0x00
        # and so missed 7 of the 8 per-region mode strings at 0xEA01F0..0xEA020C.
        if len(s) <= 2 and (m.start() == 0 or d[m.start() - 1] in (0x00, 0xFF)):
            out[BASE + m.start()] = s.decode()
    return out


def symbols():
    syms = []
    for line in open(SYMS):
        if line.startswith("#") or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            syms.append((int(f[1], 16), f[0]))
    return sorted(syms)


def enclosing(syms, addr):
    lo, hi = 0, len(syms) - 1
    best = None
    while lo <= hi:
        mid = (lo + hi) // 2
        if syms[mid][0] <= addr:
            best = syms[mid]; lo = mid + 1
        else:
            hi = mid - 1
    return best


def selftest():
    """The detector must FIRE on a known-bad pairing, or it proves nothing."""
    cases = [("LoadPanelData", "wb", True), ("SavePanelData", "rb", True),
             ("LoadPanelData", "rb", False), ("FileIO_OpenDefault", "wb", False)]
    ok = True
    for name, mode, should_flag in cases:
        low = name.lower()
        says_r = any(w in low for w in READ_WORDS) and not any(w in low for w in WRITE_WORDS)
        says_w = any(w in low for w in WRITE_WORDS) and not any(w in low for w in READ_WORDS)
        flagged = ((mode.startswith("w") and says_r and "open" not in low) or
                   (mode.startswith("r") and says_w))
        mark = "ok" if flagged == should_flag else "SELF-TEST FAIL"
        if flagged != should_flag:
            ok = False
        print(f"  selftest {name:20} {mode:3} -> "
              f"{'flagged' if flagged else 'clean':8} (expected "
              f"{'flagged' if should_flag else 'clean'}) {mark}")
    return ok


def main():
    if "--selftest" in sys.argv:
        return 0 if selftest() else 1
    d = open(ROM, "rb").read()
    modes = mode_strings(d)
    syms = symbols()
    rows, bad = [], []
    for i in range(len(d) - 5):
        # any 32-bit reference to a mode string, not just `ld XBC,imm32` (0x41):
        # the operand may be loaded into other registers by other encodings.
        ptr = struct.unpack_from("<I", d, i)[0]
        if ptr not in modes:
            continue
        callee = None
        for j in range(i + 4, min(i + 21, len(d) - 4)):
            if d[j] == 0x1D:
                callee = int.from_bytes(d[j + 1:j + 4], "little"); break
        if callee is None:
            continue          # a reference with no call after it is not an fopen site
        site = BASE + i
        sym = enclosing(syms, site)
        name = sym[1] if sym else "?"
        mode = modes[ptr]
        low = name.lower()
        says_r = any(w in low for w in READ_WORDS) and not any(w in low for w in WRITE_WORDS)
        says_w = any(w in low for w in WRITE_WORDS) and not any(w in low for w in READ_WORDS)
        verdict = ""
        if mode.startswith("w") and says_r and "open" not in low:
            verdict = "CONTRADICTS (name says read, opens for write)"
        elif mode.startswith("r") and says_w:
            verdict = "CONTRADICTS (name says write, opens for read)"
        rows.append((site, name, mode, callee, verdict))
        if verdict and name in REVIEWED_BENIGN:
            verdict = f"reviewed benign -- {REVIEWED_BENIGN[name]}"
        elif verdict:
            bad.append((site, name, mode, verdict))
    print(f"{len(rows)} fopen-with-mode sites found; "
          f"{len({r[3] for r in rows if r[3]})} distinct callees\n")
    if "--all" in sys.argv:
        for site, name, mode, callee, v in rows:
            print(f"  0x{site:06X}  {mode:3}  {name:44} {v}")
    else:
        for site, name, mode, v in bad:
            print(f"  0x{site:06X}  {mode:3}  {name:44} {v}")
    print(f"\n{len(bad)} name/mode contradiction(s)")
    print("PASS: no routine's name contradicts the mode it opens." if not bad
          else "FAIL: names above disagree with the file mode they pass.")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
