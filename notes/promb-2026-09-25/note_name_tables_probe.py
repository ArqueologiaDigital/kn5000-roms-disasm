#!/usr/bin/env python3
r"""prom_b 0xF6DD17-0xF6DDB6: MsgLine_FormatNoteAndVelocity and its two name tables.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s carried 0xF6DD17 as the last byte of a text object
    (`Text_4Tenunormstaccuttd`), 0xF6DD18-0xF6DD9E as `Data_F6DD18` ("Unknown:
    everything about it except its bytes") and 0xF6DD9F-0xF6DDB6 as one string
    `Text_B21012345678`.  This probe re-derives from the ROM bytes alone every
    claim the 2026-09-25 re-framing rests on:

      1. the callers: every `call 0xF6DD17` (1D ..) and `calr` (1E ..) in prom_b
         that MAME unidasm also sees as an instruction start; each must be
         followed, within 8 instructions, by `call 0xF431B4` (the message-line
         painter slot);
      2. the routine, decoded by unidasm from 0xF6DD17 to its first `ret`: it
         must load XIX = 0x00000FE9, divide by L = 12, index two tables at
         0xF6DD89 and 0xF6DDA1, and write 'V' (0x56) at XIX+5;
      3. the two tables: 12 two-byte entries at 0xF6DD89 (ends where the second
         begins), 11 at 0xF6DDA1 (ends where MsgLine_PartVolume, 0xF6DDB7,
         begins -- an address a `jp`/`call` operand in prom_b names; unidasm's
         linear sweep is desynchronised there by the table text);
      4. the glyphs: Font_Svc06_8x14 (base 0xF1B400, 14 bytes/cell) cells 0x88
         and 0x8C are rendered, and checked structurally -- the flat has ONE
         vertical stem, the sharp TWO.

RUN
    python3 notes/promb-2026-09-25/note_name_tables_probe.py
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
UNI = os.path.join(os.path.expanduser("~/compartilhado"), "tools", "unidasm")
BASE = 0xF00000
ROUT, T1, T2, NEXT = 0xF6DD17, 0xF6DD89, 0xF6DDA1, 0xF6DDB7
PAINTER = 0xF431B4
FONT, PITCH = 0xF1B400, 14
LINE = re.compile(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(\S+)\s*(.*)$')
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def unidasm(blob, base):
    with tempfile.NamedTemporaryFile(suffix=".bin") as f:
        f.write(blob)
        f.flush()
        out = subprocess.run([UNI, f.name, "-arch", "tlcs900", "-basepc", hex(base)],
                             capture_output=True, text=True).stdout
    res = {}
    for ln in out.split("\n"):
        m = LINE.match(ln)
        if m:
            res[int(m.group(1), 16)] = (m.group(3).lower(), m.group(4).strip().lower(),
                                        len(m.group(2).split()))
    return res


def main():
    rom = open(B, "rb").read()
    uni = unidasm(rom, BASE)
    at = lambda a, n=1: rom[a - BASE:a - BASE + n]
    # 1. callers
    sites = []
    for i in range(len(rom) - 4):
        site = BASE + i
        if rom[i] == 0x1D and int.from_bytes(rom[i + 1:i + 4], "little") == ROUT:
            kind = "call"
        elif rom[i] == 0x1E:
            d = int.from_bytes(rom[i + 1:i + 3], "little")
            d = d - 0x10000 if d & 0x8000 else d
            if site + 3 + d != ROUT:
                continue
            kind = "calr"
        else:
            continue
        u = uni.get(site)
        if u and u[0] == kind:
            sites.append(site)
    print("callers of 0x%06X: %s" % (ROUT, " ".join("0x%06X" % s for s in sites)))
    check("four callers", len(sites) == 4)
    for s in sites:
        a, hit = s, False
        for _ in range(8):
            mn, ops, n = uni[a]
            if mn == "call" and ops == "0x%06x" % PAINTER:
                hit = True
                break
            a += n
        check("0x%06X is followed by call 0x%06X" % (s, PAINTER), hit)
    # 2. the routine
    a, text = ROUT, []
    while True:
        mn, ops, n = uni[a]
        text.append("%s %s" % (mn, ops))
        if mn == "ret":
            break
        a += n
    end = a
    body = "\n".join(text)
    print("routine 0x%06X-0x%06X, %d instructions" % (ROUT, end, len(text)))
    for want in ("ld xix,0x00000fe9", "ld l,0x0c", "divs wa,l", "ld xiy,0x00f6dd89",
                 "ld xiy,0x00f6dda1", "ld (xix+0x05),0x56", "call 0xf41af0"):
        check("routine contains `%s`" % want, want in body)
    check("its ret is the byte before table 1", end + 1 == T1)
    # 3. tables
    t1 = [at(T1 + 2 * k, 2) for k in range(12)]
    t2 = [at(T2 + 2 * k, 2) for k in range(11)]
    print("table 1:", " | ".join(x.decode("latin-1").replace("\x88", "b").replace("\x8c", "#") for x in t1))
    print("table 2:", " | ".join(x.decode("latin-1") for x in t2))
    check("12 entries end exactly where table 2 starts", T1 + 24 == T2)
    check("11 entries end exactly at 0x%06X" % NEXT, T2 + 22 == NEXT)
    # unidasm's linear sweep is still desynchronised by the table text at 0xF6DDB7,
    # so the boundary is proven by MsgLine_PartVolume's own references instead
    refs = [BASE + i for i in range(len(rom) - 4)
            if rom[i] in (0x1B, 0x1D) and int.from_bytes(rom[i + 1:i + 4], "little") == NEXT]
    check("0x%06X is named by %d jp/call operand(s) (MsgLine_PartVolume): %s"
          % (NEXT, len(refs), " ".join("0x%06X" % r for r in refs)), len(refs) >= 1)
    check("table 1 letters run C D D E E F F G A A B B",
          bytes(x[1] if x[0] == 0x20 else x[0] for x in t1) == b"CDDEEFFGAABB")
    check("table 1 marks are exactly 0x88 x4 (D E A B) and 0x8C x1 (F)",
          sorted(x[1] for x in t1 if x[0] != 0x20) == [0x88] * 4 + [0x8C])
    check("table 2 is -2 -1 0 .. 8", [x.decode() for x in t2] ==
          ["-2", "-1"] + ["%d " % k for k in range(9)])
    # 4. glyphs
    for code, stems in ((0x88, 1), (0x8C, 2)):
        cell = at(FONT + code * PITCH, PITCH)
        rows = ["".join("#" if b & (0x80 >> i) else "." for i in range(8)) for b in cell]
        print("Font_Svc06_8x14 cell 0x%02X:" % code)
        for r in rows[:11]:
            print("     " + r)
        cols = [c for c in range(8) if sum(r[c] == "#" for r in rows[:10]) >= 7]
        check("cell 0x%02X has %d full-height stem(s) (columns %s)" % (code, stems, cols),
              len(cols) == stems)
    print("\nVERDICT:", "PASS" if not FAIL else "FAIL (%d)" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
