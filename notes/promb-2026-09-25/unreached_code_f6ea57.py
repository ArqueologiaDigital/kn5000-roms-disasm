#!/usr/bin/env python3
r"""prom_b 0xF6EA57-0xF6EC30 (`Data_F6EA57`, 474 bytes): five unreached routines and a 3-word table, not data.

QUESTION THIS ANSWERS
    `Data_F6EA57` sits between sub_F6EA15's `ret` (0xF6EA56) and sub_F6EC31,
    filed as "Unknown: everything about it except its bytes".  It decodes --
    llvm-mc round trip, line by line, against the ROM -- into

      0xF6EA57  a routine ending `calr 0xF6EAA8 / ret`
      0xF6EAA8  a routine ending `ret` at 0xF6EB1A
      0xF6EB1B  the same shape as 0xF6EA57 (writes 4 where it writes 3)
      0xF6EB6C  the same shape as 0xF6EAA8 (steps (0x0FDA) by 1, not 2)
      0xF6EBDD  3 LE32 words 0x00000F5E, 0x00000F60, 0x00000F62, read by
                `ld XDE,0x00F6EBDD / ld XHL,(XDE+HL)` at 0xF6EAD0 and 0xF6EB92
                with HL = 4 * (L + 1) after `cp L,2` has sent L = 2 away: so
                entries 1 and 2 are read, entry 0 is not
      0xF6EBE9  a routine that calls sub_F6E9E6 and sub_F6EA15 -- the live
                routines just above -- storing bytes from 0x0FCD up, ending
                `popw (0x0FD6) / popw (0x0FD4) / ret` at 0xF6EC30, exactly the
                byte before sub_F6EC31

    Every routine ends in `ret`, they share the RAM cells 0x0FD3-0x0FE0 and
    0x1010 with each other, and 0x0FD4/0x0FD6/0x0FCD with the live code
    beside them.  But NOTHING in prom_a or prom_b branches to, calls or names
    any address in 0xF6EA57-0xF6EC30 (every jr/jrl/calr displacement of the
    converted code, every call/jp imm24, every 24- or 32-bit spelling
    searched; two raw 3-byte coincidences, in a bitmap at 0xF78413 and in the
    `jp 0xF9F6EC` slot at 0xF4340B, are not operands), so they are recorded as UNREACHED code: code because they decode
    as such and fit their neighbours, not because anything runs them.

RUN
    python3 notes/promb-2026-09-25/unreached_code_f6ea57.py            # checks
    python3 notes/promb-2026-09-25/unreached_code_f6ea57.py --apply    # write the source
    python3 notes/promb-2026-09-25/symbolize_prom_b_r3.py --apply --verify
    python3 notes/promb-2026-09-25/unreached_code_f6ea57.py --post     # re-parent its labels
    make gate-wsa1
    The branch symboliser parents a new branch label to the nearest routine IT
    knows, which is none of the three unreferenced ones here; --post renames
    those labels onto their own routine (sub_F6EA57, sub_F6EB1B, sub_F6EBE9).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import effect_paint_jobs as EPJ     # noqa: E402

SRC, check, FAIL = EPJ.SRC, EPJ.check, EPJ.FAIL
ROMA = os.path.join(os.path.dirname(os.path.dirname(HERE)), "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF00000
LO, HI = 0xF6EA57, 0xF6EC31
TAB = 0xF6EBDD
ROUTINES = [0xF6EA57, 0xF6EAA8, 0xF6EB1B, 0xF6EB6C, 0xF6EBE9]
_orig = EPJ.respell


def respell(ins):
    """The house spelling where effect_paint_jobs has one; else the transcriber's own LLVM
    spelling (ld_rrb, st_rrb, lda_rr ... already used in this file) -- house_island assembles
    every line and compares it with the ROM either way."""
    try:
        return _orig(ins)
    except SystemExit:
        return re.sub(r'\s+', "\t", ins.strip(), count=1)


EPJ.respell = respell


def target(rom, a):
    o = rom.at(a, 1)[0]
    if o in (0x1D, 0x1B):
        return int.from_bytes(rom.at(a + 1, 3), "little")
    if o == 0x1E or 0x70 <= o <= 0x7F:
        return (a + 3 + int.from_bytes(rom.at(a + 1, 2), "little", signed=True)) & 0xFFFFFF
    if 0x60 <= o <= 0x6F:
        return (a + 2 + int.from_bytes(rom.at(a + 1, 1), "little", signed=True)) & 0xFFFFFF
    return None


def derive(rom):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    ins = []
    for t in L:
        m = re.search(r';\s*([0-9A-F]{6})\s', t)
        if m and t.startswith("\t") and not t.startswith(("\t.", "\t;")):
            ins.append(int(m.group(1), 16))
    code1 = EPJ.house_island(rom, LO, TAB)
    code2 = EPJ.house_island(rom, 0xF6EBE9, HI)
    starts = set(a for a, _, _ in code1 + code2)
    check("0xF6EA57-0xF6EBDC decodes to %d instructions and 0xF6EBE9-0xF6EC30 to %d (llvm-mc "
          "round trip per line)" % (len(code1), len(code2)), code1 and code2)
    rets = [a for a, h, _ in code1 + code2 if h == "ret"]
    check("the five routines end in `ret` at 0xF6EAA7, 0xF6EB1A, 0xF6EB6B, 0xF6EBDC, 0xF6EC30",
          [0xF6EAA7, 0xF6EB1A, 0xF6EB6B, 0xF6EBDC, 0xF6EC30] == rets and all(r in starts for r in ROUTINES))
    check("0xF6EC31 (sub_F6EC31) and 0xF6EA56 (`ret` of sub_F6EA15) are instruction lines of the source",
          0xF6EC31 in ins and 0xF6EA56 in ins and rom.at(0xF6EA56, 1) == b"\x0e")
    check("`calr` at 0xF6EAA4 -> 0xF6EAA8 and at 0xF6EB68 -> 0xF6EB6C",
          target(rom, 0xF6EAA4) == 0xF6EAA8 and target(rom, 0xF6EB68) == 0xF6EB6C)
    check("0xF6EBE9's routine calls the live sub_F6E9E6 (0xF6EBF9, 0xF6EC0E) and sub_F6EA15 (0xF6EC0B)",
          target(rom, 0xF6EBF9) == 0xF6E9E6 and target(rom, 0xF6EC0E) == 0xF6E9E6
          and target(rom, 0xF6EC0B) == 0xF6EA15)
    words = [int.from_bytes(rom.at(TAB + 4 * k, 4), "little") for k in range(3)]
    check("0xF6EBDD: 3 LE32 words %s; `ld XDE,0x00F6EBDD` (42 dd eb f6 00) at 0xF6EAD0 and 0xF6EB92, "
          "each followed by `ld XHL,(XDE+HL)`" % [hex(w) for w in words],
          words == [0xF5E, 0xF60, 0xF62] and rom.at(0xF6EAD0, 5).hex() == "42ddebf600"
          and rom.at(0xF6EB92, 5).hex() == "42ddebf600")
    check("  ... with HL = 4 * (L + 1) after `cp L,2 / jr Z` (0xF6EAC4 / 0xF6EB86): entries 1 and 2",
          rom.at(0xF6EAC4, 4).hex() == "cfda6619" and rom.at(0xF6EAC8, 2).hex() == "cf61"
          and rom.at(0xF6EACC, 3).hex() == "dbec02")
    # nothing reaches in
    refs = [(hex(a), hex(target(rom, a))) for a in ins
            if not LO <= a < HI and target(rom, a) is not None and LO <= target(rom, a) < HI]
    ba = open(ROMA, "rb").read()
    spelt = []
    for t in range(LO, HI):
        for img, r, base in (("prom_b", rom.b, BASE), ("prom_a", ba, 0xF80000)):
            p = t.to_bytes(3, "little")
            i = r.find(p)
            while i >= 0:
                # an operand spelling: after call/jp (1D/1B) or an F2 24-bit memory prefix,
                # or the low three bytes of a 32-bit word whose high byte is 0x00
                operand = i >= 1 and (r[i - 1] in (0x1B, 0x1D, 0xF2) or r[i + 3] == 0x00)
                if operand and not (img == "prom_b" and LO <= base + i < HI):
                    spelt.append((img, hex(base + i), hex(t)))
                i = r.find(p, i + 1)
    check("no branch of the converted code lands in 0xF6EA57-0xF6EC30 %s" % refs[:3], not refs)
    check("no call/jp/24-bit-memory/32-bit operand spelling of any address in it outside it %s"
          % spelt[:3],
          not spelt)
    return dict(code1=code1, code2=code2, words=words)


BANNER = """; --------------------------------------------------------------------------
; 0xF6EA57-0xF6EC30 -- UNREACHED CODE: five routines and a 3-word table
;   Decoded (llvm-mc round trip, line by line) from what was `Data_F6EA57`.
;   Every routine ends in `ret`; they share RAM 0x0FD3-0x0FE0 and 0x1010, and
;   sub_F6EBE9 calls the live sub_F6E9E6 / sub_F6EA15 above and fills from
;   0x0FCD up.  Nothing in prom_a or prom_b branches to, calls or spells any
;   address in the span (notes/promb-2026-09-25/unreached_code_f6ea57.py
;   searches every branch displacement and every 24-bit spelling): it is
;   recorded as code because it decodes as such and fits its neighbours, not
;   because anything is shown to run it.
; --------------------------------------------------------------------------"""

HDR = {
    0xF6EA57: "clears (0x1010); with HL = 4 * (0x0FDA) and XIY = (0x0FDC), sets byte 0 of the 4-byte "
              "entry at XIY+HL to 0x20 when its bits 5-6 are clear, byte 1 to 3 and word 2 to 0; then "
              "falls into sub_F6EAA8 by `calr`.",
    0xF6EAA8: "clears (0x1010); advances (0x0FDA) by 2 and, once it reaches 2 * (0x0FD3), moves on "
              "through RamPtrTable_F6EBDD to the next of (0x0FE0) = 1, 2: (0x0FD3) = (0x0F65) or "
              "(0x0F66), (0x0FDC) = 0x0F87 or 0x0FA7; sets (0x1010) = 1 when there is none.",
    0xF6EB1B: "sub_F6EA57's shape, writing 4 where it writes 3.",
    0xF6EB6C: "sub_F6EAA8's shape, advancing (0x0FDA) by 1.",
    0xF6EBE9: "saves (0x0FD4)/(0x0FD6); stores the bytes sub_F6E9E6 returns from 0x0FCD up, "
              "stopping at 0x81 or 0x82 or at a byte with bit 7 set, and restarts while (0x0FCE) is "
              "0x2F or 0x5F.",
}


def apply(d):
    import textwrap
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    i = [k for k, t in enumerate(L) if t == "Data_F6EA57:"][0]
    k = i - 1
    while not L[k].startswith("; Unknown: everything about it except its bytes."):
        k -= 1
    L[k] = ("; ⚠ ANSWERED 2026-09-25 (the \"nothing but its bytes\" verdict that stood "
            "here):").encode("utf-8").decode("latin-1")
    L.insert(k + 1, ";   code, not data -- see the block below; `Data_F6EA57` is retired.")
    i = [k for k, t in enumerate(L) if t == "Data_F6EA57:"][0]
    e = i + 1
    while L[e].startswith("\t.byte"):
        e += 1
    j = [x for x in range(i - 40, i) if L[x].startswith("; Data_F6EA57 -- 474 bytes")]
    assert len(j) == 1
    L[j[0]] = L[j[0]].replace("; Data_F6EA57 -- 474 bytes", "; 0xF6EA57 -- 474 bytes")
    new = [x.encode("utf-8").decode("latin-1") for x in BANNER.split("\n")]

    def rows(code):
        out = []
        for a, h, text in code:
            if a in ROUTINES:
                out += textwrap.wrap("sub_%06X -- UNREACHED: %s" % (a, HDR[a]), width=78,
                                     initial_indent="; ", subsequent_indent=";   ")
                out.append("sub_%06X:" % a)
            out.append("\t%s\t; %06X  %s" % (h, a, text))
        return out
    new += rows(d["code1"])
    new += textwrap.wrap("RamPtrTable_F6EBDD -- 3 LE32 RAM addresses 0x0F5E, 0x0F60, 0x0F62.  Read by "
                         "sub_F6EAA8 / sub_F6EB6C: `ld XDE,this / ld XHL,(XDE+HL)` at 0xF6EAD0 and "
                         "0xF6EB92 with HL = 4 * (L + 1), L = (0x0FE0) < 2 -- entries 1 and 2; nothing "
                         "reads entry 0.  The word read through the entry, `ld WA,(XHL)`, is tested "
                         "for 0.", width=78, initial_indent="; ", subsequent_indent=";   ")
    new.append("RamPtrTable_F6EBDD:")
    for n, w in enumerate(d["words"]):
        new.append("\t.long\t0x%08X\t; %06X  [%d]" % (w, TAB + 4 * n, n))
    new += rows(d["code2"])
    L = L[:i] + new + L[e:]
    open(SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("wrote", SRC)


POST = [("sub_F6EA15_Skip2", "sub_F6EA57_Skip"), ("sub_F6EA15_Return", "sub_F6EA57_Return"),
        ("sub_F6EAA8_Skip3", "sub_F6EB1B_Skip"), ("sub_F6EAA8_Return2", "sub_F6EB1B_Return"),
        ("RamPtrTable_F6EBDD_Code_Loop", "sub_F6EBE9_Loop"),
        ("RamPtrTable_F6EBDD_Code_Loop2", "sub_F6EBE9_Loop2"),
        ("RamPtrTable_F6EBDD_Code_Skip", "sub_F6EBE9_Skip")]


def post():
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    where = {}
    for i, t in enumerate(L):
        m = re.match(r'^([A-Za-z_]\w*):', t)
        if m:
            where[m.group(1)] = i
    for old, new in POST:
        assert old in where and new not in where, (old, new)
        owner = new.rsplit("_", 1)[0]
        assert where[owner] < where[old], (owner, old)
        between = [k for k, i in where.items() if where[owner] < i < where[old] and
                   k.startswith("sub_") and not re.search(r'_(Skip|Join|Loop|Return)\d*$', k)]
        assert not between, (old, between)          # no other routine starts in between
        txt = re.sub(r'\b%s\b' % old, new, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("re-parented", len(POST))


def main():
    if "--post" in sys.argv:
        post()
        return 0
    rom = EPJ.Rom()
    d = derive(rom)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
