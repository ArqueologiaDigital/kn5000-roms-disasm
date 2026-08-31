#!/usr/bin/env python3
"""Is prom_a 0xFF76B5 a FILENAME FORMAT or a SCREEN FIELD?  (round-2 audit F1)

QUESTION IT ANSWERS
    notes/FINDINGS-prom_b-disk-and-file-menus.md used to read the routine at
    prom_a 0xFF76B5 as "a saved file is NNNNNN.XXX-shaped with a fixed 6+4
    layout ... a directly usable fact about what a real WSA1 floppy contains".
    The round-2 audit called that wrong.  This re-derives the audit's case from
    the ROM bytes and the correction that replaced the claim.

    It is a SCREEN FIELD: both arms end in SWI7 service 0x06, the 8x14 text
    service, whose loop advances IX one cell per glyph.

WHAT EACH CHECK IS READING
    * the two `swi 7` arms and the service number they load;
    * SWI7_ServiceTable[6] in prom_a, so the service number resolves to
      LCD_Svc_06_DrawText8x14 and not to something disk-shaped;
    * that the drawing helper PUSHES and POPS XIX, which is what makes the
      caller's `add IX,0x0006` a cursor step rather than a buffer offset;
    * the glyph-source arithmetic IZ = HL * BC, which is what makes the
      extension table's row stride 4;
    * the blank arm's NINE cells against the 6+4 = 10 the retracted claim needs;
    * the extension table's rows, including row 9 and the constant after it.

RUN
    python3 notes/prom_b_filefield_checks.py
Exit status is non-zero if a check fails.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A_BASE, B_BASE = 0xF80000, 0xF00000
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-62s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def main():
    a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()

    def A(addr, n):
        return a[addr - A_BASE:addr - A_BASE + n]

    def B(addr, n):
        return b[addr - B_BASE:addr - B_BASE + n]

    print("prom_b_filefield_checks.py -- round-2 audit F1")
    # 1. the helper is a text draw, not a disk write
    check("0xFF76FE pushes XIX (so IX comes back unchanged)", A(0xFF7701, 1).hex(), "3c")
    check("0xFF7702 zeroes (0x2540)", A(0xFF7702, 5).hex(), "f140250000")
    check("0xFF7707 loads A = 0x06 and issues swi 7", A(0xFF7707, 3).hex(), "2106ff")
    check("0xFF770A pops XIX back", A(0xFF770A, 1).hex(), "5c")
    svc6 = struct.unpack_from("<I", A(0xF8E9C6 + 6 * 4, 4), 0)[0]
    check("SWI7_ServiceTable[6] = LCD_Svc_06_DrawText8x14", hex(svc6), "0xf8f039")

    # 2. the service's own loop: IZ = HL*BC, source (XIY+IZ), IX += 1 per glyph
    check("0xF8F044 ld WA,HL / mul xwa,xbc / ld IZ,WA", A(0xF8F044, 6).hex(), "db88d940d88e")
    check("0xF8F04A reads the glyph from (XIY+IZ)", A(0xF8F04A, 5).hex(), "c307f4f821")
    check("0xF8F068 advances IX by one CELL per glyph", A(0xF8F068, 2).hex(), "dc61")

    # 3. the caller's two arms
    check("0xFF76D1 draws BC = 6 name cells", A(0xFF76D1, 3).hex(), "310600")
    check("0xFF76DA draws BC = 4 extension cells", A(0xFF76DA, 3).hex(), "310400")
    check("0xFF76DD points XIY at the extension table", A(0xFF76DD, 5).hex(), "452586f500")
    check("0xFF76E2 steps the CURSOR six cells", A(0xFF76E2, 4).hex(), "dcc80600")
    check("0xFF76EF blank arm draws NINE cells, not 6+4 = 10", A(0xFF76EF, 3).hex(), "310900")
    check("0xFF76F2 points it at 0xF5864D", A(0xFF76F2, 5).hex(), "454d86f500")
    check("0xFF76C6 takes the content code from the LOW NIBBLE", A(0xFF76C6, 3).hex(), "cfcc0f")
    check("0xFF76B8 reads that code from record offset +6", A(0xFF76B8, 2).hex(), "ed66")

    # 4. the extension table, at stride 4 because BC = 4
    rows = [B(0xF58625 + 4 * i, 4).decode("ascii") for i in range(10)]
    check("rows 0-8", rows[:9],
          [".ALL", ".SEQ", ".CMB", ".SND", ".PNL", ".MDS", ".SRM", ".CRM", ".DRM"])
    check("LAST row, 9, is blank", repr(rows[9]), repr("    "))
    check("row 9 sits at 0xF58649", hex(0xF58625 + 9 * 4), "0xf58649")
    check("the nine-space constant begins at 0xF5864D, right after it",
          B(0xF5864D, 9).decode("ascii"), " " * 9)
    check("and ends at 0xF58655 -- 0xF58656 is not a space",
          B(0xF58656, 1) != b" ", True)
    check("so 0xF58649-0xF58655 is 13 spaces = one blank row + the constant",
          B(0xF58649, 13).decode("ascii"), " " * 13)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
