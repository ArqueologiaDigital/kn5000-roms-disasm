#!/usr/bin/env python3
"""Is every quantified sentence in prom_a 0xFC0000-0xFC2FFF's headers still true?

QUESTION IT ANSWERS.  The byte gate proves prom_a/wsa1_prom_a.s rebuilds the ROM
and is blind to what a comment claims.  This is the complement for the
parameter-edit module: each check is named after the sentence it backs, reads
the ROM (and, for the reference counts, prom_a + prom_b) and fails loudly.

  python3 notes/prom_a_fc0000_module_check.py
  python3 notes/prom_a_fc0000_module_check.py -v          # print every check
  python3 notes/prom_a_fc0000_module_check.py --selftest   # negative controls

Exit status is non-zero if any check fails.  The script prints its own check
count as its LAST line; that is the only figure to quote.

⚠ It is a claim checker, not a decoder oracle.  Where a sentence rests on an
instruction boundary it re-decodes the span with unidasm (through
notes/prom_a_linear_decode_check.decode) rather than trusting the listing.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import prom_a_linear_decode_check as LD                       # noqa: E402
import prom_a_ringbuf_map as MAP                              # noqa: E402

A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE, B_BASE = 0xF80000, 0xF00000
LO, HI = 0xFC0000, 0xFC25EE            # code+data; the pad to 0xFC3000 follows

FAILED = []
N = [0]
VERBOSE = "-v" in sys.argv


def check(name, got, want):
    N[0] += 1
    ok = got == want
    if not ok:
        FAILED.append(name)
    if VERBOSE or not ok:
        print(("  ok   " if ok else "  FAIL ") + name + ": " + repr(got) +
              ("" if ok else "   expected " + repr(want)))
    return ok


def a(x, n=1):
    return A[x - A_BASE:x - A_BASE + n]


def u32(x):
    return int.from_bytes(a(x, 4), "little")


# ----------------------------------------------------------------- decoding
_rows = None


def rows():
    """Every instruction of the module, decoded span by span so that the
    declared data regions never desynchronise the disassembler."""
    global _rows
    if _rows is None:
        spans = [(0xFC0000, 0xFC0890), (0xFC0990, 0xFC09CE), (0xFC0BDA, 0xFC1162),
                 (0xFC11FB, 0xFC1AFA), (0xFC1B09, 0xFC1C49), (0xFC1C59, 0xFC1CC1),
                 (0xFC1CD1, 0xFC2135), (0xFC2155, 0xFC21F3), (0xFC2213, 0xFC25EE)]
        _rows = []
        for lo, hi in spans:
            _rows += [r for r in LD.decode(lo, hi) if r[0] < hi]
    return _rows


def boundaries():
    return {r[0] for r in rows()}


def text_at(addr):
    for x, n, t in rows():
        if x == addr:
            return t
    return None


# --------------------------------------------------------------- references
def calr_targets():
    """{target: [sites]} for every `calr`/`jr`/`jrl` and absolute call/jp the
    module's own decode shows.  Anchored on DECODED instructions, so unlike
    notes/prom_a_xref.py these are not opcode coincidences."""
    out = {}
    for x, n, t in rows():
        m = re.match(r"^(?:calr|call|jp|jr\w*|jrl\w*)\s+.*?0x([0-9a-f]{6})$", t)
        if m:
            out.setdefault(int(m.group(1), 16), []).append(x)
    return out


def all_external_refs(target):
    """Every site in prom_a+prom_b naming `target`, over the same spellings
    notes/prom_a_ringbuf_map.all_refs() covers (absolute call/jp/lda, a bare
    LE32 pointer, and every PC-relative displacement in prom_a)."""
    return MAP.all_refs().get(target, [])


def thunk_slots():
    out = {}
    for off in range(0x40000, 0x44018, 4):
        if B[off] == 0x1B:
            out.setdefault(int.from_bytes(B[off + 1:off + 4], "little"),
                           []).append(0xF00000 + off)
    return out


# =========================================================================== 1
def sec_bounds():
    print("1  MODULE BOUNDS -- the ROM's, not a choice")
    check("0xFBFFD4-0xFBFFFF is 44 bytes of 0x0E",
          set(A[0xFBFFD4 - A_BASE:0xFC0000 - A_BASE]), {0x0E})
    check("...and 0xFBFFD3 is not 0x0E", A[0xFBFFD3 - A_BASE] == 0x0E, False)
    check("0xFC25EE-0xFC2FFF is 2578 bytes of 0x0E",
          (set(A[0xFC25EE - A_BASE:0xFC3000 - A_BASE]), 0xFC3000 - 0xFC25EE),
          ({0x0E}, 2578))
    check("0xFC25EC, the last SUBSTANTIVE byte, is not 0x0E",
          A[0xFC25EC - A_BASE] == 0x0E, False)
    check("0xFC25ED is 0x0E -- it is the last routine's own `ret`, given back "
          "to the code by gen_prom_a_block.pad_runs",
          A[0xFC25ED - A_BASE], 0x0E)
    # no 8-byte run of 0x0E in between
    longest, run = 0, 0
    for x in range(LO, HI):
        run = run + 1 if A[x - A_BASE] == 0x0E else 0
        longest = max(longest, run)
    check("longest 0x0E run strictly inside the module (bytes)", longest, 11)
    check("...which is under the 32-byte floor gen_prom_a_block.py pads at",
          longest < 32, True)


# =========================================================================== 2
def sec_frontier():
    print("2  WHAT THE DIRECTORY PUBLISHES INTO THIS SPAN")
    slots = thunk_slots()
    ins = [(s, t) for t, ss in slots.items() for s in ss if LO <= t < 0xFC3000]
    check("directory slots whose target is in 0xFC0000-0xFC3000", len(ins), 165)
    check("distinct targets", len(set(t for _, t in ins)), 164)
    bnd = boundaries()
    bad = sorted({t for _, t in ins if t not in bnd})
    check("targets that are NOT an instruction boundary of this module",
          [hex(x) for x in bad],
          ['0xfc0427', '0xfc043d', '0xfc0452', '0xfc0453', '0xfc0454'])
    for t in bad:
        ss = [s for s, tt in ins if tt == t]
        check("  0x%06X is published by exactly one slot" % t, len(ss), 1)
    check("the five bad slots",
          sorted(hex(s) for s, t in ins if t in bad),
          ['0xf41184', '0xf4118c', '0xf41190', '0xf41194', '0xf41198'])
    # all five sit inside the 16-byte veneers at 0xFC0420-0xFC0460
    check("all five lie inside 0xFC0420-0xFC0460",
          all(0xFC0420 <= t < 0xFC0460 for t in bad), True)
    # ...and each has a reference upper bound of zero
    def upper_bound(slot):
        n = 0
        for img, base in ((A, A_BASE), (B, B_BASE)):
            for i in range(len(img) - 3):
                if img[i] in (0x1D, 0x1B) and \
                        int.from_bytes(img[i + 1:i + 4], "little") == slot:
                    n += 1
        return n
    check("reference upper bound of the five slots, summed",
          sum(upper_bound(s) for s in
              (0xF41184, 0xF4118C, 0xF41190, 0xF41194, 0xF41198)), 0)
    # published slots that jump to a bare RET
    ret_slots = sorted({t for _, t in ins if A[t - A_BASE] == 0x0E})
    check("published targets whose first byte is 0x0E (RET)", len(ret_slots), 34)
    check("...which is more than a fifth of the 164", len(ret_slots) * 5 > 164, True)


# =========================================================================== 3
def sec_dispatch():
    print("3  THE TWO DISPATCHERS AND THE TEN HANDLER TABLES")
    check("0xFC0990 and 0xFC09AF are byte-identical over 31 bytes",
          a(0xFC0990, 31) == a(0xFC09AF, 31), True)
    check("...and 31 is maximal: byte 32 differs",
          a(0xFC0990 + 31, 1) == a(0xFC09AF + 31, 1), False)
    check("the dispatcher reads (0x20B8)", a(0xFC0990, 4).hex(), "c1b82027")
    check("...bounds the cursor with `cp L,A` / `jr UGT`",
          a(0xFC0994, 4).hex(), "c9f76b16")
    check("...clears bit 1 of (0x070F)", a(0xFC0998, 5).hex(), "c10f073cfd")
    check("...loads XIX = 0x00000716", a(0xFC099D, 5).hex(), "4416070000")
    check("...scales the index by 4 (`sla 0x02,HL`)", a(0xFC09A4, 3).hex(), "dbec02")

    tgt = calr_targets()
    check("`calr` sites reaching 0xFC0990", len(tgt.get(0xFC0990, [])), 64)
    check("`calr` sites reaching 0xFC09AF", len(tgt.get(0xFC09AF, [])), 8)

    # the ten (table, limit, dispatcher) declarations, parsed from the code
    decls, rws = [], rows()
    for i, (x, n, t) in enumerate(rws):
        m = re.match(r"^ld XIY,0x00(fc[0-9a-f]{4})$", t)
        if not m:
            continue
        tbl, lim, disp = int(m.group(1), 16), None, None
        for j in range(i + 1, min(i + 5, len(rws))):
            m2 = re.match(r"^ld A,0x([0-9a-f]{2})$", rws[j][2])
            if m2:
                lim = int(m2.group(1), 16)
            m3 = re.match(r"^calr 0x(fc[0-9a-f]{4})$", rws[j][2])
            if m3:
                disp = int(m3.group(1), 16)
                break
        if lim is not None and disp in (0xFC0990, 0xFC09AF):
            decls.append((tbl, lim, disp))
    check("callers with the full `ld XIY / ld A / calr dispatcher` shape",
          len(decls), 72)
    check("...which is exactly the 64 + 8 calr sites", len(decls), 64 + 8)
    tabs = sorted(set(decls))
    check("distinct (table, limit, dispatcher) declarations", len(tabs), 10)
    check("the ten declarations",
          [(hex(t), l, hex(d)) for t, l, d in tabs],
          [('0xfc09ce', 0x0D, '0xfc0990'), ('0xfc0a06', 0x1A, '0xfc0990'),
           ('0xfc0a72', 0x06, '0xfc09af'), ('0xfc0a8e', 0x0D, '0xfc09af'),
           ('0xfc0ac6', 0x07, '0xfc09af'), ('0xfc0ae6', 0x02, '0xfc09af'),
           ('0xfc0af2', 0x0E, '0xfc09af'), ('0xfc0b2e', 0x04, '0xfc09af'),
           ('0xfc0b42', 0x13, '0xfc09af'), ('0xfc0b92', 0x11, '0xfc09af')])
    # they tile the span with no gap and no overlap
    at, gaps = 0xFC09CE, []
    for t, l, d in tabs:
        if t != at:
            gaps.append((hex(at), hex(t)))
        at = t + 4 * (l + 1)
    check("gaps or overlaps between the ten extents", gaps, [])
    check("total entries", sum(l + 1 for t, l, d in tabs), 131)
    check("the extents end at", hex(at), hex(0xFC0BDA))
    check("...which is the VALUE of entry 0 -- the last-entry test",
          hex(u32(0xFC09CE)), hex(0xFC0BDA))
    check("a 132nd entry would read the first 4 bytes of that handler",
          u32(0xFC0BDA), int.from_bytes(a(0xFC0BDA, 4), "little"))
    check("every one of the 131 entries is inside the module",
          all(LO <= u32(0xFC09CE + 4 * k) < HI for k in range(131)), True)
    check("...and every one is an instruction boundary of it",
          sorted({hex(u32(0xFC09CE + 4 * k)) for k in range(131)}
                 - {hex(x) for x in boundaries()}), [])
    check("distinct handlers among the 131 entries",
          len({u32(0xFC09CE + 4 * k) for k in range(131)}), 50)
    runs = {}
    prev, n_run = None, 0
    for k in range(131):
        v = u32(0xFC09CE + 4 * k)
        n_run = n_run + 1 if v == prev else 1
        runs[v] = max(runs.get(v, 0), n_run)
        prev = v
    top = sorted(runs.items(), key=lambda kv: -kv[1])[:3]
    check("longest runs of a repeated handler",
          [(hex(v), n) for v, n in top],
          [('0xfc0ce2', 20), ('0xfc0e20', 18), ('0xfc0e52', 14)])


# =========================================================================== 4
def sec_records():
    print("4  Msg0716_ObjectRecords -- 32 records of 8 bytes")
    bad = []
    for n in range(32):
        r = a(0xFC0890 + 8 * n, 8)
        want = bytes([(8 * n) & 0xFF, 0x06, 0x00, 0x00,
                      (1 << (n % 16)) & 0xFF, (1 << (n % 16)) >> 8, n, 0x0E])
        if r != want:
            bad.append((n, r.hex(), want.hex()))
    check("all 32 records match +0=8n, +1=6, +2..3=0, +4..5=1<<(n%16), +6=n, "
          "+7=0x0E", bad, [])
    check("record 31 (the LAST) is", a(0xFC0890 + 8 * 31, 8).hex(),
          "f806000000801f0e")
    check("a 33rd record would start at 0xFC0990, the dispatcher",
          hex(0xFC0890 + 8 * 32), hex(0xFC0990))
    check("0xFC0990 is reached by `calr`, so there is no room for one",
          len(calr_targets().get(0xFC0990, [])) > 0, True)
    named = sorted({int(m.group(1), 16)
                    for x, n, t in rows()
                    for m in [re.match(r"^ld XIZ,0x00(fc[0-9a-f]{4})$", t)]
                    if m})
    inrange = [x for x in named if 0xFC0890 <= x < 0xFC0990]
    check("record addresses the module actually forms: first and last",
          (hex(min(inrange)), hex(max(inrange))), ('0xfc0890', '0xfc0988'))
    check("...all of them 8-byte aligned to the table",
          all((x - 0xFC0890) % 8 == 0 for x in inrange), True)
    check("XIZ constants outside the record table", 
          [hex(x) for x in named if not (0xFC0890 <= x < 0xFC0990)], [])


# =========================================================================== 5
def sec_ptrtable():
    print("5  Msg0716_RecordPtrTable -- 32 pointers, one step of 0x80")
    vals = [u32(0xFC1162 + 4 * k) for k in range(32)]
    check("entry 0", hex(vals[0]), hex(0x76A2))
    check("entry 31 (the LAST)", hex(vals[31]), hex(0x7EA2))
    steps = [vals[k + 1] - vals[k] for k in range(31)]
    check("steps that are not 0x40",
          [(k, hex(s)) for k, s in enumerate(steps) if s != 0x40],
          [(7, '0x80')])
    check("the address the sequence skips", hex(vals[7] + 0x40), hex(0x78A2))
    check("a 33rd entry would read 0x03020100, not 0x00007EE2",
          hex(u32(0xFC1162 + 4 * 32)), hex(0x03020100))
    # 0x78A2 is named directly more often than any other 0x76xx-0x7Exx address
    counts = {}
    for x, n, t in rows():
        for m in re.finditer(r"\(0x([0-9a-f]{4})\)", t):
            v = int(m.group(1), 16)
            if 0x7600 <= v < 0x7F00:
                counts[v] = counts.get(v, 0) + 1
    top = sorted(counts.items(), key=lambda kv: -kv[1])[:1]
    check("most-named RAM address in 0x7600-0x7EFF",
          [(hex(v), n) for v, n in top], [('0x78a2', 6)])
    check("readers of the table (index scaled by 4 then indexed)",
          sorted(hex(x) for x, n, t in rows()
                 if t == "ld XIY,0x00fc1162"), ['0xfc1156', '0xfc1737'])
    check("the second reader takes its index from record field +6",
          text_at(0xFC172F), "ld E,(XIZ+0x06)")

    print("   Msg0716_IdentityRamp_0_24")
    check("25 bytes 0x00..0x18", list(a(0xFC11E2, 25)), list(range(0x19)))
    check("the byte after it starts a directory target",
          hex(0xFC11FB) in [hex(t) for t in thunk_slots()], True)
    # ⚠ a searched negative, so it is stated as what the search RETURNED.
    refs = all_external_refs(0xFC11E2)
    check("the only site all_refs() returns for 0xFC11E2",
          [(k, hex(s)) for k, s in refs], [('jrl', '0xfc11df')])
    check("...and 0xFC11DF is not an instruction -- it is inside the table's "
          "own last entry, so the hit is an opcode coincidence",
          0xFC11DF in boundaries(), False)
    check("no call/jp/lda/pointer site names it at all",
          [k for k, s in refs if k != "jrl"], [])


# =========================================================================== 6
def sec_messages():
    print("6  THE MESSAGE SENDERS")
    check("Msg0716_Post is `push XIX / ld XIX,0x716 / push XIX / push BC "
          "/ push 0 / call T_F40ED4 / add XSP,8 / pop XIX / ret`",
          a(0xFC1A1E, 23).hex(),
          "3c" "4416070000" "3c" "29" "0b0000" "1dd40ef4" "efc808000000" "5c" "0e")
    check("Msg0716_PostFromXIX_Stream1 takes the pointer in XIX (no `ld XIX`)",
          a(0xFC1B09, 16).hex(),
          "3c" "29" "0b0100" "1dd40ef4" "efc808000000" "0e")
    x, y = a(0xFC1A24, 15), a(0xFC1B09, 15)
    check("the two senders' 15 shared bytes differ at exactly one offset",
          [i for i in range(15) if x[i] != y[i]], [3])
    check("...and that byte is the stream number", (x[3], y[3]), (0x00, 0x01))
    check("Msg0716_Post_Trampoline is `calr Msg0716_Post; ret`",
          a(0xFC1A1A, 4).hex(), "1e01000e")
    tgt = calr_targets()
    check("`calr` sites reaching the trampoline", len(tgt.get(0xFC1A1A, [])), 30)
    check("`calr` sites reaching Msg0716_Post itself",
          len(tgt.get(0xFC1A1E, [])), 1)
    check("`calr` sites reaching Msg0716_PostFromXIX_Stream1",
          len(tgt.get(0xFC1B09, [])), 5)
    check("T_F40ED4 resolves to prom_a 0xF8E02C",
          hex(int.from_bytes(B[0x40ED4 + 1:0x40ED4 + 4], "little")), hex(0xF8E02C))
    check("the callee turns its third word into bits 5-7 of the link header "
          "(`sll c,0x05` at 0xF8E0A7)", a(0xF8E0A7, 3).hex(), "cbee05")
    check("...and writes it to the 0x7C0000 port",
          (a(0xF8E0AF, 5).hex(), a(0xF8E0B7, 2).hex()), ("4100007c00", "b141"))

    print("   Msg0716_BiasOpcodeByMode")
    check("three `cp (0x207a),imm` with 0x39, 0x66, 0xCA",
          [a(x, 5).hex() for x in (0xFC1B19, 0xFC1B20, 0xFC1B27)],
          ["c17a203f39", "c17a203f66", "c17a203fca"])
    check("...into one `add (0x0716),0x08`", a(0xFC1B2E, 5).hex(), "c116073808")
    check("`calr` sites reaching it", len(tgt.get(0xFC1B19, [])), 4)
    check("nothing else in the module names 0x207A",
          sum(1 for x, n, t in rows() if "(0x207a)" in t), 3)

    print("   Msg0716_DefaultMessages -- five 3-byte records")
    check("the five records", a(0xFC1AFA, 15).hex(),
          "800001" "810018" "820018" "830018" "870004")
    loaders = sorted(x for x, n, t in rows()
                     if re.match(r"^ld XIY,0x00fc1(afa|afd|b00|b03|b06)$", t))
    check("five loaders, one per record", len(loaders), 5)
    check("each copies exactly 3 bytes",
          {text_at(x + 10) for x in loaders}, {"ld BC,0x0003"})
    check("each copies into 0x00000716",
          {text_at(x + 5) for x in loaders}, {"ld XIX,0x00000716"})
    check("the record after the last would start at Msg0716_PostFromXIX_Stream1",
          hex(0xFC1B06 + 3), hex(0xFC1B09))


# =========================================================================== 7
def sec_strings():
    print("7  THE FOUR STRINGS, all of them fallbacks")
    check("0xFC1C49", a(0xFC1C49, 16), b"Sound Name *****")
    check("0xFC1CC1", a(0xFC1CC1, 16), b"Combi Name *****")
    check("0xFC2135", a(0xFC2135, 32), b"Combi Group NameEXT Silent Group")
    check("0xFC21F3 is a byte-identical second copy",
          a(0xFC21F3, 32) == a(0xFC2135, 32), True)
    check("no NUL terminator on any of them",
          [A[x - A_BASE + 16] for x in (0xFC1C49, 0xFC1CC1)], [0x3C, 0x0E])
    # the sentinel guards
    check("Sound Name is loaded after `cp XIY,0xffffffff`",
          a(0xFC1BA6, 6).hex(), "edcfffffffff")
    check("Combi Name is loaded after `cp WA,0xffff`",
          a(0xFC1C66, 4).hex(), "d8cfffff")
    check("the group pair's second half is formed as an address",
          sorted(hex(x) for x, n, t in rows() if t == "ld XIY,0x00fc2145"),
          ['0xfc20c3'])
    check("every ASCII run of 6+ printable bytes in the module",
          _ascii_runs(),
          [('0xfc150b', 6), ('0xfc1b7f', 7), ('0xfc1c49', 21),
           ('0xfc1cc1', 16), ('0xfc2135', 32), ('0xfc2191', 6),
           ('0xfc21f3', 32)])


def _ascii_runs():
    out, run = [], None
    for x in range(LO, HI + 1):
        ok = x < HI and 32 <= A[x - A_BASE] < 127
        if ok and run is None:
            run = x
        elif not ok and run is not None:
            if x - run >= 6:
                out.append((hex(run), x - run))
            run = None
    return out


# =========================================================================== 8
def sec_entries():
    print("8  THE TWO NAMED ENTRY POINTS")
    check("0xFC0000 is `jp 0xFC0018`", a(0xFC0000, 4).hex(), "1b1800fc")
    check("0xFC0008 is `jp 0xFC018E`", a(0xFC0008, 4).hex(), "1b8e01fc")
    check("0xFC000C is `jp 0xFC0076`", a(0xFC000C, 4).hex(), "1b7600fc")
    for slot, tgt in ((0xFC0000, 0xFC0018), (0xFC000C, 0xFC0076)):
        sites = [s for s in all_external_refs(tgt)]
        check("sites naming 0x%06X, other than the veneer at 0x%06X" % (tgt, slot),
              [hex(s) for k, s in sites if s != slot], [])
    print("   Msg0716_InitAllRecords")
    check("the loop runs the index 0..0x1F inclusive",
          (text_at(0xFC002D), text_at(0xFC002F), text_at(0xFC0033)),
          ("inc 1,HL", "cp HL,0x001f", "jr ULE,0xfc001b"))
    check("...32 iterations, one per Msg0716_ObjectRecords record", 0x1F + 1, 32)
    check("the message it then stages is C0 20 78 20 00",
          [a(x, 1)[0] for x in (0xFC003C, 0xFC0040, 0xFC0044, 0xFC0048, 0xFC004C)],
          [0xC0, 0x20, 0x78, 0x20, 0x00])
    check("...with length 5", text_at(0xFC004D), "ld BC,0x0005")
    check("...sent through the trampoline", text_at(0xFC0050), "calr 0xfc1a1a")
    check("then two more stagings, handed to two OTHER routines",
          (text_at(0xFC0061), text_at(0xFC0072)),
          ("calr 0xfc151b", "calr 0xfc1679"))
    check("(0x20B9) is 0x7F, then 0x64, then 0x7F",
          [a(x + 4, 1)[0] for x in (0xFC0020, 0xFC0058, 0xFC0069)],
          [0x7F, 0x64, 0x7F])
    print("   RemoteImage_LoadHeader")
    check("two 16-iteration 0xFF fills, over 0x08C0 and 0x08D0",
          [text_at(0xFC0076), text_at(0xFC0085), text_at(0xFC008A), text_at(0xFC0099)],
          ["ld XIY,0x000008c0", "cp C,0x10", "ld XIY,0x000008d0", "cp C,0x10"])
    check("the 0x5A guard", text_at(0xFC009E), "cp (0xc5),0x5a")
    check("...jumps to 0xFC018C on failure", text_at(0xFC00A2), "jrl NZ,0xfc018c")
    check("...which is a `ret`", text_at(0xFC018C), "ret")
    check("the remote request passes 0x00C00000 and 0x34 bytes",
          [text_at(0xFC00A5), text_at(0xFC00AB), text_at(0xFC00AE), text_at(0xFC00B4)],
          ["ld XIX,0x00000860", "push 0x0034", "ld XIX,0x00c00000",
           "call 0xf40ef0"])
    check("...then waits and tests 0xFFFF",
          [text_at(0xFC00BE), text_at(0xFC00C2)],
          ["call 0xf4123c", "cp WA,0xffff"])
    check("the two 16-bit offsets it adds 0x00C00000 to",
          [text_at(0xFC00CB), text_at(0xFC00D9)],
          ["ld XWA,(0x0874)", "ld XWA,(0x087c)"])
    check("NO instruction in prom_a+prom_b dereferences 0x00C00000",
          _addr_hits(0xC00000), 0)


def _addr_hits(addr):
    """The twelve absolute-address spellings, as notes/prom_a_addr_census.py
    counts them: prefix groups 0xC0/0xD0/0xE0/0xF0 with an 8-, 16- or 24-bit
    address field."""
    n = 0
    for img, base in ((A, A_BASE), (B, B_BASE)):
        for i in range(len(img) - 4):
            p = img[i]
            if p in (0xC0, 0xD0, 0xE0, 0xF0):
                if int.from_bytes(img[i + 1:i + 2], "little") == addr:
                    n += 1
            if p in (0xC1, 0xD1, 0xE1, 0xF1):
                if int.from_bytes(img[i + 1:i + 3], "little") == addr:
                    n += 1
            if p in (0xC2, 0xD2, 0xE2, 0xF2):
                if int.from_bytes(img[i + 1:i + 4], "little") == addr:
                    n += 1
    return n


# =========================================================================== 9
def sec_flags():
    print("9  THE FLAG BYTES")
    check("four nine-byte entry points set bits 0-3 of (0x070E)",
          [a(x, 9).hex() for x in (0xFC065A, 0xFC0663, 0xFC066C, 0xFC0675)],
          ["f10e07b8" "f10f07b8" "0e", "f10e07b9" "f10f07b8" "0e",
           "f10e07ba" "f10f07b8" "0e", "f10e07bb" "f10f07b8" "0e"])
    check("all four are published directory targets",
          all(x in thunk_slots() for x in
              (0xFC065A, 0xFC0663, 0xFC066C, 0xFC0675)), True)
    n20b9 = sum(1 for x, n, t in rows() if "(0x20b9)" in t)
    check("sites naming (0x20B9)", n20b9, 17)
    n20b8 = sum(1 for x, n, t in rows() if "(0x20b8)" in t)
    check("sites naming (0x20B8)", n20b8, 15)
    ops = sorted({int(t.split(",0x")[1], 16) for x, n, t in rows()
                  if t.startswith("ld (XIX),0x")})
    check("message opcodes written as `ld (XIX),imm`",
          [hex(v) for v in ops],
          ['0x0', '0x80', '0x88', '0x90', '0xb0', '0xc0', '0xd0', '0xe0',
           '0xf0'])
    check("...all of them a multiple of 8", all(v % 8 == 0 for v in ops), True)
    check("the OTHER five opcodes come from Msg0716_DefaultMessages, not "
          "from an immediate", [a(0xFC1AFA + 3 * k, 1)[0] for k in range(5)],
          [0x80, 0x81, 0x82, 0x83, 0x87])


# ========================================================================== 10
def sec_left():
    """Why the TOP-ranked module 0xF86000 was left this round -- as numbers."""
    print("10  WHAT WAS LEFT: the 0xF86000 module, measured")
    lo, hi = 0xF86000, 0xF8969B
    longest, run = 0, 0
    for x in range(lo, hi):
        run = run + 1 if A[x - A_BASE] == 0x0E else 0
        longest = max(longest, run)
    check("longest 0x0E run inside 0xF86000-0xF8969A", longest, 4)
    check("...so the module has no readable end before", hi - lo, 13979)
    rows2 = LD.decode(lo, hi)
    bad = [x for x, n, t in rows2 if t == "db"]
    check("undecodable bytes in a linear decode of it", len(bad), 408)
    cl = []
    for x in bad:
        if cl and x - cl[-1][-1] <= 96:
            cl[-1].append(x)
        else:
            cl.append([x])
    check("clusters they fall into", len(cl), 12)
    spans = sorted((c[-1] - c[0] + 1) for c in cl)
    check("the two widest clusters span", spans[-2:], [1021, 3554])
    slots = thunk_slots()
    ins = [(s, t) for t, ss in slots.items() for s in ss if lo <= t < 0xF89800]
    check("directory slots into 0xF86000-0xF89800", len(ins), 24)
    check("...distinct targets", len(set(t for _, t in ins)), 23)


def selftest():
    print("\nNEGATIVE CONTROLS")
    N[0] += 1
    ok = a(0xFC0890 + 8 * 31, 8) != a(0xFC0890 + 8 * 30, 8)
    print(("  ok   " if ok else "  FAIL ") +
          "the LAST record is not a copy of the one before")
    if not ok:
        FAILED.append("selftest last record")
    N[0] += 1
    # a 132nd handler-table entry must NOT be an address inside the module
    v = u32(0xFC09CE + 4 * 131)
    ok = not (LO <= v < HI)
    print(("  ok   " if ok else "  FAIL ") +
          "a 132nd handler entry (0x%08X) is not a module address" % v)
    if not ok:
        FAILED.append("selftest 132nd entry")
    N[0] += 1
    # the ramp must fail if read one byte early
    ok = list(A[0xFC11E1 - A_BASE:0xFC11E1 - A_BASE + 25]) != list(range(0x19))
    print(("  ok   " if ok else "  FAIL ") +
          "the 0x00..0x18 ramp does not also start one byte early")
    if not ok:
        FAILED.append("selftest ramp offset")


def main():
    sec_bounds()
    sec_frontier()
    sec_dispatch()
    sec_records()
    sec_ptrtable()
    sec_messages()
    sec_strings()
    sec_entries()
    sec_flags()
    sec_left()
    if "--selftest" in sys.argv:
        selftest()
    print("\n%d checks, %d failed" % (N[0], len(FAILED)))
    for f in FAILED:
        print("   - " + f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
