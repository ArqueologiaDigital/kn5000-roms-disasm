#!/usr/bin/env python3
"""Name prom_b 0xF48C1A: the routine that checks a loaded file's signature.

WHAT IT DOES, read off its own instructions
    It copies the 16 bytes at 0xF48C00 -- `WSA SOUND RAM S0` -- into its stack
    frame at XIZ+0xC6, and the four bytes at 0xF48C10 -- `WSA1` -- into
    XIZ+0xDC.  It then points XIX at work DRAM 0x60A700 and takes one of two
    arms on the screen id:

      (0x207C) == 0x54   compare all SIXTEEN bytes against 0x60A700 + n,
                         n = 0..15 (`cp H,0x10` at 0xF48C89)
      otherwise          `inc 6,XIX` and compare FOUR bytes against
                         0x60A706 + n, n = 0..3 (`cp H,4` at 0xF48CB9), with
                         0xFF accepted as a wildcard (0xF48CAD) and error code
                         0x2B returned on a mismatch (0xF48CB2)

    0x60A700 is the same 1,024-byte input window Smf_ReadFile reads through
    InputStream_GetByte, so all three of this machine's file signatures --
    `MThd`, `WSA SOUND RAM S0`, `WSA1` -- are checked in the same buffer.

WHAT THE NAME CLAIMS
    That it compares a signature.  NOT which of the two file kinds is which,
    and not what screen 0x54 is.

RUN
    python3 notes/prom_b_apply_diskfile_name.py            # re-derive
    python3 notes/prom_b_apply_diskfile_name.py --apply
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B = 0xF00000
RENAMES = [("sub_F48C1A", "DiskFile_CheckSignature")]

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)

NOTE = """; Name:    DiskFile_CheckSignature -- named 2026-08-31.
; Evidence (STRING): it copies the 16 bytes of Table_WsaSoundRamS0Wsa1 at
;          0xF48C00, `WSA SOUND RAM S0`, into its own frame at XIZ+0xC6 and the
;          four at 0xF48C10, `WSA1`, into XIZ+0xDC (0xF48C21-0xF48C33), then
;          points XIX at work DRAM 0x60A700 (0xF48C60) and compares.  Which
;          comparison it makes is decided by the screen id:
;            (0x207C) == 0x54  -> all SIXTEEN bytes at 0x60A700+n, n = 0..15
;                                 (`cp H,0x10`, 0xF48C89)
;            otherwise         -> `inc 6,XIX` and FOUR bytes at 0x60A706+n,
;                                 n = 0..3 (`cp H,4`, 0xF48CB9), with 0xFF
;                                 accepted as a wildcard (0xF48CAD) and error
;                                 code 0x2B returned on a mismatch (0xF48CB2).
;          0x60A700 is the same 1,024-byte input window Smf_ReadFile reads
;          through InputStream_GetByte, so the machine's three file signatures
;          -- `MThd`, `WSA SOUND RAM S0`, `WSA1` -- are all checked there.
; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; Unknown: which of the two file kinds is which, and what screen 0x54 is.  The
;          name claims that a signature is compared and nothing more.
"""


def check():
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as f:
        rom = f.read()
    a = rom[0xF48C00 - B:0xF48C10 - B]
    b = rom[0xF48C10 - B:0xF48C14 - B]
    print(f"  0xF48C00 = {a!r}\n  0xF48C10 = {b!r}")
    ok = a == b"WSA SOUND RAM S0" and b == b"WSA1"
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


def apply():
    with open(SRC) as f:
        s = f.read()
    SEP = re.compile(r"^; -{10,}\n", re.M)
    for old, new in RENAMES:
        i = s.index("\n" + old + ":") + 1
        st = [m.start() for m in SEP.finditer(s, 0, i)]
        h = st[-2] if len(st) >= 2 else st[-1]
        blk = s[h:i]
        assert OLD_UNKNOWN in blk, old
        blk = blk.replace(OLD_UNKNOWN, NOTE).replace(f"; {old}\n", f"; {new} -- 0x{old[4:]}\n", 1)
        s = s[:h] + blk + s[i:]
        s = re.sub(r"\b" + old + r"\b", new, s)
    with open(SRC, "w") as f:
        f.write(s)
    print(f"renamed {len(RENAMES)}")
    return 0


if __name__ == "__main__":
    sys.exit(apply() if "--apply" in sys.argv else check())
