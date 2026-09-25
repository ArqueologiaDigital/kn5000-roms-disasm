#!/usr/bin/env python3
r"""PtrTables_F95C95 (0xF95C95-0xF95E81): two screens' button tables and a stale copy of both.

QUESTION THIS ANSWERS
    The old header split the span into 32 + 32 LE32 pointers (two readers),
    one stray 0x00 byte, and 59 pointers with "NO reader located", ending
    "Unknown: what the third table is for, and what the stray byte is."

    * The two readers are the BUTTON methods (+8 slot) of two screen objects
      in prom_b's screen table: ScreenButton_SineWaveCheckMode (0xF95891,
      object 0xF400F0) and sub_F959E2 (object 0xF40130).  Each bounds the
      button code with `cp (XIZ+8),0x1F` and calls table[code] -- so these are
      per-screen BUTTON HANDLER tables, one entry per panel event code.
    * The 59-word table is a STALE COPY of both, laid out 0x400-style after
      them: its last 32 words are the second table with every value + 0xED
      (default 0xF95C2C -> 0xF95D19), and its first 27 are the first table's
      words 5..31 with the same default and the same live handlers at the same
      button codes -- except code 27, a handler only the live table has.  The
      copy's default, 0xF95D19, is INSIDE the live second table (data), so it
      cannot run in this image; and nothing names an address in it.
    * The stray 0x00 is the top byte of that copy's word 4: every pointer here
      has a 0x00 top byte, and 0xF95D95 + 1 = the copy's word 5.  The copy's
      first 19 bytes lie under the live second table.

CHECKS (against wsa1/original_ROMs)
    K1  both readers: `cp (XIZ+8),0x001F / jr ugt`, `ldw BC,4 / mul
        BC,(XIZ+8)`, `add XBC,<table>`, `jp (XBC)`; prom_b slots 0xF400F8 and
        0xF40138 are `jp` to them (+8 of objects 0xF400F0 / 0xF40130)
    K2  every live entry is an instruction start in the source
    K3  stale[27+j] == t2[j] + 0xED for all 32 j
    K4  stale[k], k < 27, is default exactly where t1[k+5] is default, except
        k = 22 (t1[27] = 0xF95971); its non-defaults sit at the codes of t1's
    K5  0xF95D19 lies inside t2 (0xF95D15-0xF95D94); no LE24 value in
        0xF95D95-0xF95E81 occurs in prom_a outside the span or in prom_b

RUN
    python3 notes/proma-2026-09-25/gen_button_tables.py          # checks
    python3 notes/proma-2026-09-25/gen_button_tables.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
T1, T2, ST = 0xF95C95, 0xF95D15, 0xF95D96
DEF, SDEF = 0xF95C2C, 0xF95D19


def w(r, a, n):
    return [int.from_bytes(r[a - B + 4 * k:a - B + 4 * k + 4], "little") for k in range(n)]


def at(r, a, h):
    return r[a - B:a - B + len(bytes.fromhex(h))] == bytes.fromhex(h)


def checks(m):
    r = m.rom
    for base, cp, ml, ad, jp in ((T1, 0xF95896, 0xF958AE, 0xF958B4, 0xF958C2),
                                 (T2, 0xF959E7, 0xF959FF, 0xF95A05, 0xF95A13)):
        assert at(r, cp, "9e083f1f00") and r[cp - B + 5] == 0x6B
        assert at(r, ml, "3104009e0841")
        assert at(r, ad, "e9c8" + base.to_bytes(4, "little").hex())
        assert at(r, jp, "b1d8")
    rb = open(os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    assert rb[0xF400F8 - 0xF00000:0xF400FC - 0xF00000] == bytes.fromhex("1b9158f9")
    assert rb[0xF40138 - 0xF00000:0xF4013C - 0xF00000] == bytes.fromhex("1be259f9")
    assert rb[0xF40130 - 0xF00000:0xF40134 - 0xF00000] == bytes.fromhex("1bc859f9")
    print("K1 ok: both readers are BUTTON methods bounding the code by 0x1F")
    t1, t2, st = w(r, T1, 32), w(r, T2, 32), w(r, ST, 59)
    for x in set(t1) | set(t2):
        assert m.line_of(x) is not None, hex(x)
    print("K2 ok: %d distinct live handlers, all instruction starts" % len(set(t1) | set(t2)))
    assert st[27:] == [x + 0xED for x in t2]
    print("K3 ok: stale[27..58] = t2 + 0xED")
    for k in range(27):
        if k == 22:
            assert t1[27] == 0xF95971 and st[22] == SDEF
            continue
        assert (st[k] == SDEF) == (t1[k + 5] == DEF), k
    assert st[10] == 0xF95C15 + 0xED and t1[15] == 0xF95C15
    print("K4 ok: stale[0..26] follows t1[5..31] (default/non-default), code 27 new in t1")
    assert T2 <= SDEF < T2 + 128
    ra = r
    for name, img, base in (("prom_a", ra, B), ("prom_b", rb, 0xF00000)):
        for i in range(len(img) - 2):
            v = int.from_bytes(img[i:i + 3], "little")
            if 0xF95D95 <= v < 0xF95E82 and not (name == "prom_a" and 0xF95C95 <= base + i < 0xF95E82):
                raise AssertionError((name, hex(base + i)))
    assert r[0xF95D95 - B] == 0x00
    print("K5 ok: the copy's default is inside t2; nothing names the copy; stray byte 0x00")
    return t1, t2, st


def apply(m, t1, t2, st):
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    dash = "; ---------------------------------------------------------------------"
    i0 = L.index("; PtrTables_F95C95 -- 493 bytes holding THREE pointer tables and one stray byte") - 1
    assert L[i0] == dash
    iL = L.index("PtrTables_F95C95:", i0)
    # the table's .byte lines end where the next statement (the RET pad) starts
    j = iL + 1
    while re.match(r"^\t\.byte ", L[j]):
        j += 1
    old_hdr = L[i0 + 1:iL - 1]
    names = {}
    for x in sorted(set(t1) | set(t2)):
        names[x] = m.best_label(x) or "sub_%06X" % x
    new = [dash,
           "; ScreenButtonHandlers_SineWaveCheckMode -- 32 LE32 handlers, one per panel",
           ";          event code, for the screen object at prom_b 0xF400F0",
           ";          (Paint_SineWaveCheckMode / ScreenLeave_ / ScreenButton_).",
           "; Read by: ScreenButton_SineWaveCheckMode (0xF95891, the object's +8",
           ";          BUTTON slot T_F400F8): `cp (XIZ+8),0x001F / jr ugt` -- COUNT 32 --",
           ";          then `ldw BC,4 / mul BC,(XIZ+8) / add XBC,<this> / ld XBC,(XBC)`",
           ";          and a call with H = bit 7 of (XIZ+0x0A).  Codes as",
           ";          PanelButton_Route produces them (see Dispatch_FF3D39's legend).",
           ";          %d slots are the default 0xF95C2C, a lone `ret`." % t1.count(DEF),
           "; (notes/proma-2026-09-25/gen_button_tables.py, checks K1-K5)"]
    new += [u8(x) for x in [
        "; ★ 2026-09-25 (lane proma): this span was PtrTables_F95C95; its header,",
        ";          kept verbatim above ScreenButtonHandlers_StaleCopy, left the third",
        ";          table and the stray byte open.  Both are answered there."]]
    new += [dash, "ScreenButtonHandlers_SineWaveCheckMode:"]
    for k, x in enumerate(t1):
        new.append("\t.long %-40s ; %06X  [code 0x%02X]" % (names[x], T1 + 4 * k, k))
    new += ["", dash,
            "; ScreenObjF40130_ButtonHandlers -- 32 LE32 handlers, one per panel event",
            ";          code, for the screen object at prom_b 0xF40130 (+0 sub_F959C8,",
            ";          +4 sub_F959E1, +8 sub_F959E2).",
            "; Read by: sub_F959E2 (0xF959E2, slot T_F40138), the same five instructions",
            ";          as ScreenButton_SineWaveCheckMode with this base at 0xF95A05.",
            ";          %d slots are the default 0xF95C2C." % t2.count(DEF),
            "; (checks K1, K2)",
            dash, "ScreenObjF40130_ButtonHandlers:"]
    for k, x in enumerate(t2):
        new.append("\t.long %-40s ; %06X  [code 0x%02X]" % (names[x], T2 + 4 * k, k))
    new += ["", dash] + [u8(x) for x in [
        "; ScreenButtonHandlers_StaleCopy -- 1 byte + 59 LE32: a copy of BOTH tables",
        ";          above from another build, unreachable here.",
        ";   +0      0x00, the top byte of the copy's word 4 (every pointer here has",
        ";           a 0x00 top byte); its first 19 bytes lie under the live table.",
        ";   words 0..26   = the first table's words 5..31: default exactly where it",
        ";           is default, handlers at the same codes -- except code 27, whose",
        ";           handler (0xF95971) only the live table has (check K4).",
        ";   words 27..58  = the second table, every value + 0xED (check K3).",
        "; Its default, 0xF95D19, lies INSIDE ScreenObjF40130_ButtonHandlers -- data",
        ";          in this image -- and no address in this span is named in either",
        ";          CPU-1 image (check K5): nothing reads it.  Values stay numeric on",
        ";          purpose: they are the other build's addresses.",
        "; ★ This answers the old header's closing question about the third table",
        ";          and the stray byte; that line is replaced, the rest of the old",
        ";          header follows verbatim.",
        "; (checks K3-K5)"]] + [dash, "; The former span's header (PtrTables_F95C95), verbatim:"] + \
        [x for x in old_hdr if not x.startswith("; Unknown:  what the third table is for")] + \
        [dash, "ScreenButtonHandlers_StaleCopy:",
                                "\t.byte 0x00                                       ; F95D95  top byte of copy word 4"]
    for k, x in enumerate(st):
        new.append("\t.long 0x%08x                                 ; %06X  [%2d]" % (x, ST + 4 * k, k))
    L[i0:j] = new
    txt = "\n".join(L)
    assert txt.count("add XBC,PtrTables_F95C95+0x80") == 1
    txt = txt.replace("add XBC,PtrTables_F95C95+0x80", "add XBC,ScreenObjF40130_ButtonHandlers")
    assert txt.count("add XBC,PtrTables_F95C95 ") == 1
    txt = txt.replace("add XBC,PtrTables_F95C95 ", "add XBC,ScreenButtonHandlers_SineWaveCheckMode ")
    L = txt.split("\n")
    for x, nm in sorted(names.items(), reverse=True):
        if m.labels_at(x):
            continue
        i = next(k for k, l in enumerate(L) if re.search(r";\s*%06X\s" % x, l) and not l.startswith(";"))
        L[i:i] = ["%s:   ; entry: screen button-handler table" % nm]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    M = srcmap.load()
    A = checks(M)
    if "--apply" in sys.argv:
        apply(M, *A)
