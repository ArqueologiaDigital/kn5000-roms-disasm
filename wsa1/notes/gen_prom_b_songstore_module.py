#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF7A400-0xF7CFFF -- the BLOCK-STORE ALLOCATOR
and the SONG-STORE COMMAND module that sits on top of it.

QUESTION IT ANSWERS
    "What is the assembly text for the two thunk-table runs T_F42880-T_F42894
     (6 slots) and T_BStore_AppendBytes_Join3_Veneer-T_F42ABC (132 slots), in a form the byte gate
     accepts, with every label and header attached to the right address?"
    This is the emitter whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK
    notes/prom_b_module_frontier.py joins notes/prom_b_thunk_modules.py's run
    decomposition with notes/prom_b_call_graph.py's converted/unconverted split.
    T_BStore_AppendBytes_Join3_Veneer-T_F42ABC is the run with the most unconverted prom_b targets in the
    image -- 132 of them, all inside ONE .incbin span, 8,906 bytes of target
    extent, summed reference upper bound 172.  T_F42880-T_F42894 is the run
    immediately below it in the same span, and notes/FINDINGS-prom_b-block-store.md
    already named its target as "the natural next conversion":
        "T_F42884 -> 0xF7A402 is the block allocator itself -- it is what
         BStore_AllocChain calls at 0xF63A18 for each block of a new chain."

HOW THE CODE/DATA SPLIT WAS MADE
    * notes/prom_b_module_trace.py 0xF7A400 0xF7D000 does a recursive descent
      from the range's own thunk entry points and reports the runs it never
      reaches.  84.2% of the range is reached directly.
    * Every unreached run was then read.  Two are 0x0E (`ret`) padding, six are
      5-entry pointer tables whose reader is 12 bytes in front of them, and
      three are data.  The code that follows a pointer table is unreached only
      because the descent cannot follow `call XHL`.
    * THE CHECK THAT MATTERS, and it is asserted on every emit: all 138 thunk
      targets in the range must land on an instruction boundary of the
      transcription.  A data island mistaken for code resynchronises silently;
      a thunk target off a boundary is the symptom that catches it.
    * Code runs go through notes/llvm_roundtrip_autoforce.py, which assembles
      the candidate listing and compares it byte for byte with the ROM before
      printing.  The `.fill` runs are re-asserted to be pure 0x0E.

RUN
    python3 notes/gen_prom_b_songstore_module.py            # the assembly
    python3 notes/gen_prom_b_songstore_module.py --layout   # the segment table
    python3 notes/gen_prom_b_songstore_module.py --checks   # the assertions only
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF7A400, 0xF7D000
TBL_LO, TBL_HI = 0x40000, 0x44018

# (kind, start, length).  Contiguity, the 0xF7D000 end and the purity of both
# `fill` runs are asserted in checks() -- this table is never trusted as typed.
LAYOUT = [
    ("code", 0xF7A400, 0x3EB),
    ("fill", 0xF7A7EB, 0x215),
    ("code", 0xF7AA00, 0x55A),
    ("data", 0xF7AF5A, 0x07E),
    ("code", 0xF7AFD8, 0x1322),
    ("data", 0xF7C2FA, 0x011),
    ("code", 0xF7C30B, 0x3DB),
    ("data", 0xF7C6E6, 0x014),
    ("code", 0xF7C6FA, 0x035),
    ("data", 0xF7C72F, 0x014),
    ("code", 0xF7C743, 0x209),
    ("data", 0xF7C94C, 0x018),
    ("code", 0xF7C964, 0x034),
    ("data", 0xF7C998, 0x018),
    ("code", 0xF7C9B0, 0x1CC),
    ("data", 0xF7CB7C, 0x014),
    ("code", 0xF7CB90, 0x03D),
    ("data", 0xF7CBCD, 0x014),
    ("code", 0xF7CBE1, 0x1B7),
    ("data", 0xF7CD98, 0x008),
    ("code", 0xF7CDA0, 0x0C8),
    ("fill", 0xF7CE68, 0x198),
]

# {table: (entry count, the `cp L,<max>` site that fixes it, that operand)}.
# The count is NOT the table's byte extent divided by 4 -- it is read off the
# reader's own upper-bound test, twelve bytes in front of the table, and the
# emitter asserts that a further entry would not be an address in this module.
# Getting this wrong is not hypothetical: the first draft of this file gave all
# six tables 5 entries, and the "a further entry is not an address" check is
# what caught the two that have 6.
PTR_TABLES = {
    0xF7C6E6: (5, 0xF7C6CD, 4),
    0xF7C72F: (5, 0xF7C716, 4),
    0xF7C94C: (6, 0xF7C933, 5),
    0xF7C998: (6, 0xF7C97F, 5),
    0xF7CB7C: (5, 0xF7CB63, 4),
    0xF7CBCD: (5, 0xF7CBB4, 4),
}

_cache = {}


def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1):
    return rom("b")[addr - B_BASE: addr - B_BASE + n]


def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        out = subprocess.run(
            [sys.executable, AUTOFORCE, "b", hex(start), hex(length), "--quiet"],
            capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr))
        _cache[key] = out.stdout.rstrip("\n").split("\n")
    return _cache[key]


def code_lines():
    """[(addr, text_line)] over every code segment, in address order."""
    out = []
    for kind, s, n in LAYOUT:
        if kind != "code":
            continue
        for ln in transcribe(s, n):
            m = re.search(r";\s*([0-9A-F]{6})\s", ln)
            out.append((int(m.group(1), 16), ln))
    return out


def boundaries():
    return {a for a, _ in code_lines()}


def thunks():
    """{target: [slot, ...]} for `jp nnn` slots landing in this range."""
    d, out = rom("b"), {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = d[o:o + 4]
        if s[0] == 0x1B:
            t = s[1] | s[2] << 8 | s[3] << 16
            if LO <= t < HI:
                out.setdefault(t, []).append(B_BASE + o)
    return out


def slot_refs():
    """Opcode-anchored upper bound on references to each thunk SLOT address."""
    cnt = {}
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if B_BASE + TBL_LO <= t < B_BASE + TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    return cnt


def direct_refs(addr):
    """Every byte offset in prom_a+prom_b that spells `addr` as a 32-bit LE word.
    An UPPER BOUND -- the scan is at every byte, not at instruction boundaries."""
    tgt = addr.to_bytes(4, "little")
    out = []
    for nm, blob, base in (("prom_a", rom("a"), A_BASE), ("prom_b", rom("b"), B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            out.append(base + i)
            i += 1
    return out


def reader_of(tbl):
    """(instruction address, operand address) of the ONE site that spells `tbl`.

    ⚠ THIS EXISTS BECAUSE OF A SHIPPED DEFECT.  The first version of this file
    printed `a - 12` -- the address of the 32-bit OPERAND, which is what
    direct_refs() returns -- and called it the reader's address, in twelve header
    lines; and the check below asserted the very same `a - 12`, so it could never
    catch it.  The audit of 2026-08-24 caught it instead (finding F2).

    The instruction is `ld XDE,imm32`, opcode 0x42 followed by the four operand
    bytes, so the instruction starts ONE byte before the word a byte scan finds,
    and the check that the byte there really is 0x42 is what makes that a
    derivation rather than another hard-coded offset.  Re-derived on every emit
    and on every --checks run; notes/prom_b_audit_callsites.py re-checks the
    EMITTED text independently, by disassembling at the address the header names."""
    refs = direct_refs(tbl)
    assert len(refs) == 1, "0x%06X: %d sites spell it, expected 1" % (tbl, len(refs))
    instr = refs[0] - 1
    op = at(instr, 1)[0]
    assert op == 0x42, ("0x%06X: the byte at 0x%06X is 0x%02X, not the 0x42 of "
                        "`ld XDE,imm32` -- the operand-to-instruction step is not "
                        "one byte here and must be re-derived" % (tbl, instr, op))
    return instr, refs[0]


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments.
    Exact, not a byte window: every entry comes off a decoded instruction."""
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            out.setdefault(int(m.group(2), 16), []).append(a)
    return out


def ptr_entries(tbl):
    return [int.from_bytes(at(tbl + 4 * i, 4), "little")
            for i in range(PTR_TABLES[tbl][0])]


def labels():
    """{addr: name}.  A label goes at every thunk target, every pointer-table
    entry, every intra-range call target, and every data object."""
    got = {}
    for t in thunks():
        got[t] = None
    for tbl in PTR_TABLES:
        for e in ptr_entries(tbl):
            if LO <= e < HI:
                got[e] = None
    for callee in internal_calls():
        if LO <= callee < HI:
            got[callee] = None
    got.update({a: None for a in DATA_LABEL})
    got.update({a: None for a in FORCE})
    for a in got:
        got[a] = NAMES.get(a) or DATA_LABEL.get(a) or "sub_%06X" % a
    return got


NAMES = {
    0xF7A41A: "BStore_LatchHeapBase",
    0xF7A428: "BStore_FreeList_Init",
    0xF7A4DB: "BStore_AllocBlock",
    0xF7A539: "BStore_FreeChain",
    0xF7A5FF: "BStore_SeekBlock_Alloc",
    0xF7A613: "BStore_AppendBytes_Veneer",
    0xF7A617: "BStore_AppendBytes",
    0xF7AA5E: "SongStore_LoadSongHeaderToDisplay",
}

DATA_LABEL = {
    0xF7AF5A: "SongStore_BitMask32",
    0xF7C2FA: "SongStore_Island_F7C2FA",
    0xF7C6E6: "SongStore_DispatchA_1",
    0xF7C72F: "SongStore_DispatchA_2",
    0xF7C94C: "SongStore_DispatchB_1",
    0xF7C998: "SongStore_DispatchB_2",
    0xF7CB7C: "SongStore_DispatchC_1",
    0xF7CBCD: "SongStore_DispatchC_2",
    0xF7CD98: "SongStore_StepSizeTable",
}


# Addresses that are neither a thunk target nor a call target but do start a
# routine.  Each one needs its own reason, stated here and re-checked in
# checks(): nothing may be forced into the label set on taste alone.
FORCE = {
    0xF7A41A: "target of `jr T,0xf7a41a` at 0xF7A408, the last slot of the "
              "veneer island; the four slots before it all reach a calr/ret pair",
    0xF7AFD8: "target of `calr 0xf7afd8` at 0xF7AC9D -- and it is the first "
              "instruction after the SongStore_BitMask32 island",
    0xF7C30B: "target of `jr T,0xf7c30b` at 0xF7C2F8, the jump that steps over "
              "the 17 bytes of SongStore_Island_F7C2FA",
}

# Curated headers.  Everything not listed here is emitted as a computed
# six-line header whose only claim is the entry point.
CURATED = {
    0xF7A41A: dict(
        what="copy the 32-bit heap base (0x3604) into (0x12A2)",
        inputs="none",
        outputs="(0x12A2) = (0x3604)",
        evidence="the five instructions at 0xF7A41A-0xF7A427.  (0x12A2) is where "
                 "BStore_SeekBlock_Alloc adds the block offset, so it is the "
                 "allocator's private copy of the heap base; "
                 "notes/FINDINGS-prom_b-block-store.md fixes (0x3604) = 0x00617800 "
                 "by inverse arithmetic at 0xF5E2F0 and 0xF61F1C",
        unknown="why the copy is remade at the head of FOUR routines here "
                "(0xF7A41A, 0xF7A428, 0xF7A4DB, 0xF7A539) instead of once at init"),
    0xF7A428: dict(
        what="build the free list over all (0x3608) blocks and clear the five "
             "per-song arrays.  Block n gets prev = n-1, next = n+1, tag 0x82 at "
             "payload offset 0; the last block gets next = 0xFFFF.  Free-list "
             "head (0x6034B8) = 1, free count (0x6034BA) = (0x3608)",
        inputs="(0x3604) heap base, (0x3608) block count",
        outputs="the whole heap, (0x6034B8), (0x6034BA), and 17 entries in each "
                "of 0x00603500 (3 bytes), 0x00603460 (2), 0x00603482 (1), "
                "0x0060347E (2), 0x006034A0 (1)",
        evidence="`ld (0x6034b8),0x0001` at 0xF7A43B; `ld BC,(0x3608) / "
                 "ld (0x6034ba),BC / dec 1,BC` at 0xF7A44B-0xF7A454 followed by a "
                 "`djnz BC` body that writes +0x01, +0x03, +0x05 and advances "
                 "`add XIY,0x00000100`; the 0xFFFF terminator at 0xF7A47A.  The "
                 "record layout is the one notes/FINDINGS-prom_b-block-store.md "
                 "reads off 0xF63A3A/0xF63A46/0xF63A4B",
        unknown="what the five arrays hold.  0x0060347E/0x006034A0 are the SAVED "
                "CURSOR pair that block-store routine 0xF63924 writes; "
                "0x00603460/0x00603482 have the same word+byte shape and the same "
                "0x22 separation but no reader was traced in this module"),
    0xF7A4DB: dict(
        what="allocate one block: pop the free-list head, unlink it, set its "
             "bit 7, decrement the free count",
        inputs="none",
        outputs="W = 0 on success and (0x126E) = the block's address; W = 0xFF "
                "when the free list is empty",
        evidence="`ld IY,(0x6034b8) / cp IY,0xffff / jr Z,0xf7a536` at "
                 "0xF7A4E8-0xF7A4F1 with 0xF7A536 doing `ld W,0xff / ret`; the "
                 "success path ends `ld W,0x00 / ret` at 0xF7A533.  `or (XHL),0x80` "
                 "at 0xF7A526 is the allocated bit that block-store's "
                 "`bit 7,(XHL)` tests, and `decw 1,(0x6034ba)` at 0xF7A529 is the "
                 "free count.  Its caller is named in "
                 "notes/FINDINGS-prom_b-block-store.md: BStore_AllocChain reads "
                 "the same W at 0xF63A2F and turns 0xFF into error code 5",
        unknown="nothing outstanding"),
    0xF7A539: dict(
        what="free a chain: walk it from block IY, clear each bit 7, splice the "
             "whole run back onto the free list, and add the number of blocks "
             "freed to (0x6034BA)",
        inputs="IY = first block of the chain, BC = the block to link on after",
        outputs="(0x6034B8) = IY, (0x6034BA) += the number of blocks freed",
        evidence="`ld BC,(0x6034b8) / ld (0x6034b8),IY` at 0xF7A54A-0xF7A54F is "
                 "the head swap; `and (XHL),0x7f` at 0xF7A5C2 and 0xF7A5FA clears "
                 "the allocated bit; the count accumulates in WA (`inc 1,WA` at "
                 "0xF7A5D8) and lands with `add (0x6034ba),WA` at 0xF7A5DA.  "
                 "0xF7A5C9 `ld (XHL+0x03),BC` is what re-attaches the old head",
        unknown="(0x0C88) is used as scratch for the loop bound (`ld (0x0c88),WA` "
                "at 0xF7A546, cleared at 0xF7A5F2); nothing else here reads it"),
    0xF7A5FF: dict(
        what="seek: (0x126E) = (0x12A2) + (IY-1)*0x100, i.e. address of 1-based "
             "block IY.  Returns XHL = 0",
        inputs="IY = block number, 1-based",
        outputs="(0x126E) = the block's address; XHL = 0",
        evidence="the seven instructions at 0xF7A5FF-0xF7A612.  This is the SAME "
                 "arithmetic notes/FINDINGS-prom_b-block-store.md attributes to "
                 "BStore_SeekBlock (0xF63BAE) -- `(0x126E) = base + (n-1)*0x100` -- "
                 "but the two are NOT one routine: this one takes its block number in "
                 "IY and adds (0x12A2), the allocator's own copy of the base, where "
                 "0xF63BAE takes HL and adds (0x3604) directly.  As BYTES they are 20 "
                 "and 18 long and differ at 18 of the first 20 offsets -- the diff is "
                 "printed by notes/prom_b_songstore_checks.py.  Two objects computing "
                 "the same thing, so this name carries a suffix instead of borrowing "
                 "0xF63BAE's outright",
        unknown="nothing outstanding"),
    0xF7A617: dict(
        what="append C bytes from (XIY) to the chain of DIRECTORY ENTRY "
             "(0x1008), allocating a new block when the cursor would overflow "
             "past offset 0xFF",
        inputs="XIY = source bytes, W = count (moved to C), A = directory entry "
               "number, 1-based",
        outputs="W = 0 on success; on failure it raises message 0x40AB, status "
                "(0x2880) = 0x0F and returns without appending",
        evidence="`ld (0x1272),XIY / ld (0x1008),A / ld C,W` at 0xF7A618-0xF7A620. "
                 "The cursor pair is indexed by the entry: XIZ = (n-1)*2 selects "
                 "a word in 0x0060347E and a byte in the array 0x22 further on "
                 "(0x006034A0) -- `ld A,(XIX+0x22)` at 0xF7A6A5 with XIX = "
                 "0x0060347E + XIZ/2.  The overflow test is `add WA,BC / cp WA,0xff "
                 "/ jr UGT` at 0xF7A6B0-0xF7A6B6 and the new-block offset is "
                 "`sub WA,0x00fb` at 0xF7A6F0 -- 251, exactly the payload size "
                 "0x100-5 that block-store computes at 0xF639B8.  The failure path "
                 "0xF7A76A writes (0x2880) = 0x0F, the same status byte "
                 "block-store's error table feeds.  That (0x1008) is a DIRECTORY "
                 "entry and not the song is read off 0xF7A7A8-0xF7A7CC: "
                 "`ld A,(0x1008) / dec 1,A / *3 / ld XIX,0x00603500 / "
                 "or (XIX+IZ),0x80 / ld (XDE3+0x0001),IY` sets that entry's "
                 "in-use bit and head block -- the 3-byte stride and the bit-7 "
                 "flag notes/FINDINGS-prom_b-block-store.md reads off "
                 "BStore_OpenChain at 0xF638BB",
        unknown="what the two thunk calls around the copy do: 0xF42EF8/0xF42EFC "
                "bracket it and 0xF427EC does the move.  Neither target is "
                "converted, so the copy itself is not read here"),
    0xF7AA5E: dict(
        what="read 6 bytes from bank (0x0E02)'s copy at 0x00610000 + n*0xC00 + "
             "0xCA into (0x12F7)-(0x12FC), the fields the SEQUENCER PLAY screen "
             "draws",
        inputs="(0x0E02) = bank/song index, 0-based",
        outputs="(0x12F7)..(0x12FC)",
        evidence="`sla 0x0b,XWA / sla 0x0a,XBC / add` at 0xF7AA6D-0xF7AA73 is the "
                 "n*0xC00 bank index notes/FINDINGS-prom_b-block-store.md reads at "
                 "0xF64B3D; `add XIY,0x000000ca` fixes the field offset and "
                 "`ld XIX,0x000012f7 / ld BC,0x0006 / ldir` the destination and "
                 "length.  DIRECTION: TLCS-900 `ldir` writes (XIX)+ and reads "
                 "(XIY)+ -- ../mame/src/devices/cpu/tlcs900/900tbl.hxx:2483 with "
                 ":5437-5438 -- so the bank is the SOURCE.  (0x12F7) is drawn by "
                 "14 interpreter-B display-list records "
                 "(`python3 notes/prom_b_var_screens.py --var 0x12F7`)",
        unknown="what the six bytes mean individually"),
}


# ---------------------------------------------------------------- assertions

FAIL = []
QUIET = False


def check(msg, got, want):
    ok = got == want
    if not QUIET or not ok:
        print("  %-64s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def checks(verbose=True):
    """Everything the byte gate cannot see.  Run on every emit."""
    global FAIL, QUIET
    FAIL, QUIET = [], not verbose
    d = rom("b")
    # 1. the layout is contiguous, covers exactly LO..HI, and both fills are pure
    a = LO
    tot = {"code": 0, "data": 0, "fill": 0}
    for kind, s, n in LAYOUT:
        check("segment %s 0x%06X abuts the previous" % (kind, s), s, a)
        if kind == "fill":
            check("0x%06X-0x%06X is pure 0x0E" % (s, s + n - 1),
                  sorted(set(at(s, n))), [0x0E])
        tot[kind] += n
        a = s + n
    check("the layout ends at 0xF7D000", "0x%06X" % a, "0x%06X" % HI)
    check("code + data + fill", tot["code"] + tot["data"] + tot["fill"], HI - LO)
    # 2. THE CHECK THAT MATTERS: every thunk target is on an instruction boundary
    b, th = boundaries(), thunks()
    check("thunk targets in 0xF7A400-0xF7D000", len(th), 138)
    check("thunk targets NOT on an instruction boundary",
          sorted("0x%06X" % t for t in th if t not in b), [])
    last = max(th)
    check("the LAST thunk target is 0xF7CCCA", "0x%06X" % last, "0xF7CCCA")
    check("its slot holds `jp 0x%06X`" % last,
          (d[th[last][-1] - B_BASE], int.from_bytes(at(th[last][-1] + 1, 3), "little")),
          (0x1B, last))
    check("the LAST thunk target is on a boundary", last in b, True)
    # 3. the six pointer tables: 5 entries each, entry 0 is the shared `ret`,
    #    every entry on a boundary, and a hypothetical 6th entry is NOT a pointer
    for tbl, (n, site, bound) in PTR_TABLES.items():
        e = ptr_entries(tbl)
        check("0x%06X: %d entries, all on an instruction boundary" % (tbl, n),
              all(x in b for x in e), True)
        check("0x%06X: entry 0 is the shared `ret` at 0xF7C6FA" % tbl,
              "0x%06X" % e[0], "0xF7C6FA")
        check("0x%06X: its reader's bound at 0x%06X is `cp L,%d`" % (tbl, site, bound),
              text_at(site), "cp L,%d" % bound)
        nxt = int.from_bytes(at(tbl + 4 * n, 4), "little")
        check("0x%06X: entry %d would be 0x%08X -- not an address here"
              % (tbl, n, nxt), LO <= nxt < HI, False)
        # ⚠ the check that shipped finding F2: it asserted `tbl - 12`, the same
        #    hard-coded value the header printed, so the two agreed with each
        #    other and with nothing else.  Now the instruction address is
        #    DERIVED (reader_of) and both the operand and the opcode are asserted.
        instr, operand = reader_of(tbl)
        check("0x%06X: exactly one site spells it, at 0x%06X" % (tbl, operand),
              ["0x%06X" % x for x in direct_refs(tbl)], ["0x%06X" % operand])
        check("0x%06X: the owning instruction is `ld XDE` (0x42) at 0x%06X"
              % (tbl, instr), (at(instr, 1)[0], operand - instr), (0x42, 1))
        check("0x%06X: the table starts %d bytes past that instruction"
              % (tbl, tbl - instr), tbl - instr, 13)
    # 4. the bit-mask island: what it IS, and the two bytes it is short
    ideal = b"".join((1 << k).to_bytes(4, "little") for k in range(32))
    got = at(0xF7AF5A, 0x7E)
    check("SongStore_BitMask32 is 126 bytes", len(got), 126)
    check("it equals the ideal 1<<k table with bytes [9:11] removed",
          got, ideal[:9] + ideal[11:])
    check("so entries 0 and 1 read 1 and 2",
          [int.from_bytes(got[4 * i:4 * i + 4], "little") for i in (0, 1)], [1, 2])
    check("and entry 2 reads 0x00080004, not 4",
          "0x%08X" % int.from_bytes(got[8:12], "little"), "0x00080004")
    check("entry 31 would start 2 bytes past the island",
          "0x%06X" % (0xF7AF5A + 31 * 4), "0x%06X" % (0xF7AFD8 - 2))
    check("its three readers", ["0x%06X" % x for x in direct_refs(0xF7AF5A)],
          ["0xF7AE9F", "0xF7AEEE", "0xF7AF3D"])
    # 5. the step-size island
    check("SongStore_StepSizeTable bytes", list(at(0xF7CD98, 8)),
          [0x00, 0x01, 0x02, 0x03, 0x0A, 0x32, 0x64, 0xC8])
    check("one site spells it", ["0x%06X" % x for x in direct_refs(0xF7CD98)],
          ["0xF7CD70"])
    # 6. the unexplained island
    check("SongStore_Island_F7C2FA is spelled by NO site",
          direct_refs(0xF7C2FA), [])
    check("no thunk target lands inside it",
          [t for t in th if 0xF7C2FA <= t < 0xF7C30B], [])
    # 7. every FORCE label has a reason, is on a boundary, AND is emitted.
    #    The last clause exists because the first draft of this file built
    #    FORCE, checked it here, and then never merged it into labels() -- so
    #    0xF7A41A's curated header was silently dropped and BStore_LatchHeapBase
    #    never appeared in the .s.  A check that does not follow the value
    #    through to the output is a check that cannot fail on the real mistake.
    lab_ = labels()
    for a_, why in FORCE.items():
        check("FORCE 0x%06X: boundary, reason, and IN the label set" % a_,
              (a_ in b, bool(why), a_ in lab_), (True, True, True))
    check("every CURATED address is in the label set",
          sorted("0x%06X" % x for x in CURATED if x not in lab_), [])
    # 8. the seek diff quoted in BStore_SeekBlock_Alloc's header
    x, y = at(0xF7A5FF, 0x14), at(0xF63BAE, 0x14)
    check("0xF7A5FF vs 0xF63BAE: differing bytes in the first 20",
          sum(1 for i in range(20) if x[i] != y[i]), 18)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


# ------------------------------------------------------------------- emitting

def text_at(addr):
    """The mame-syntax text this transcription proved for the instruction at
    `addr`, read out of the listing's own comment rather than re-decoded."""
    for a, ln in code_lines():
        if a == addr:
            return re.search(r";\s*[0-9A-F]{6}\s+(.*?)(?:\s+\[llvm-mc.*)?$",
                             ln).group(1).strip()
    return "<not an instruction boundary>"


def touched(lo, hi):
    """RAM/IO/ROM addresses the instructions in [lo,hi) spell, from the proven
    transcription's own comments.  A fact about the text, not an inference."""
    small, big = set(), set()
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small.add(int(m, 16))
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI):
                big.add(v)
    return sorted(small), sorted(big)


def calls_out(lo, hi, lab):
    out = []
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(1), 16)
            out.append(lab.get(t) or ("T_%06X" % t if 0xF40000 <= t < 0xF44018
                                      else "0x%06X" % t))
    seen = []
    for x in out:
        if x not in seen:
            seen.append(x)
    return seen


def wrap(prefix, text, width=76):
    body = textwrap.wrap(text, width - len(prefix))
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def veneer_of(a, end, lab):
    """If the routine at `a` is a one-instruction `jr` into a `calr X / ret`
    pair, return (hop, X).  Computed from the proven transcription, so a wrong
    description cannot survive an emit."""
    lines = {ad: text_at(ad) for ad, _ in code_lines() if a <= ad < a + 24}
    m = re.match(r"jr T,0x([0-9a-f]{6})$", lines.get(a, ""))
    if not m or end - a > 4:
        return None
    hop = int(m.group(1), 16)
    m2 = re.match(r"calr 0x([0-9a-f]{6})$", text_at(hop))
    if not m2 or text_at(hop + 3) != "ret":
        return None
    return hop, int(m2.group(1), 16)


def header(a, end, lab, th, sr, ic):
    """The six-field header.  Every list in it is computed, never typed."""
    L = ["; " + "-" * 74]
    cur = CURATED.get(a)
    name = lab[a]
    ven = veneer_of(a, end, lab)
    if cur:
        L += wrap("; %s -- " % name, cur["what"])
    elif ven:
        L += wrap("; %s -- " % name,
                  "veneer.  `jr T,0x%06X`, and 0x%06X is `calr 0x%06X / ret`, so "
                  "this entry point reaches %s."
                  % (ven[0], ven[0], ven[1], lab.get(ven[1], "0x%06X" % ven[1])))
    else:
        L.append("; %s" % name)
    # Called from
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    tb = [t for t in PTR_TABLES if a in ptr_entries(t)]
    if tb:
        parts.append("dispatch entry %s" %
                     ", ".join("%s[%d]" % (DATA_LABEL[t], ptr_entries(t).index(a))
                               for t in tb))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot, no in-module call site and no dispatch entry -- "
              "reached only by a branch from the routine above")
    if cur:
        L += wrap("; Inputs:  ", cur["inputs"])
        L += wrap("; Outputs: ", cur["outputs"])
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sm[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in bg[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    if cur:
        L += wrap("; Evidence: ", cur["evidence"])
        L += wrap("; Unknown: ", cur["unknown"])
    else:
        ev = FORCE.get(a)
        if ev:
            L += wrap("; Evidence: ", "the label is here because it is the " + ev +
                      "; the address is an instruction boundary of this "
                      "transcription (re-asserted on every emit)")
        elif ven:
            L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`; the "
                      "two instructions the hop passes through (0x%06X and "
                      "0x%06X) are read out of this transcription by the "
                      "emitter's veneer_of(), not typed."
                      % (th[a][0], a, ven[0], ven[0] + 3) if a in th else
                      "reached only by a branch; the hop is read out of this "
                      "transcription by the emitter's veneer_of().")
            L += wrap("; Unknown: ", "why the extra hop exists.  prom_b 0xF62C00 "
                      "opens with the same shape and neither module explains it.")
            L.append("; " + "-" * 74)
            return L
        elif a in th:
            L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                      "0x%06X is an instruction boundary of this transcription "
                      "(re-asserted on every emit).  That is ALL the name rests "
                      "on -- the name IS the address." % (th[a][0], a, a))
        elif tb:
            L += wrap("; Evidence: ", "0x%06X is stored as entry %d of %s, a "
                      "table whose reader ends `ld XHL,(XDE+HL) / call XHL`, and "
                      "it is an instruction boundary of this transcription "
                      "(re-asserted on every emit).  The name IS the address."
                      % (a, ptr_entries(tb[0]).index(a), DATA_LABEL[tb[0]]))
        else:
            L += wrap("; Evidence: ", "reached by a `call`/`calr` decoded in this "
                      "transcription (the sites are listed above), so 0x%06X is an "
                      "instruction boundary.  The name IS the address." % a)
        L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX "
                  "with the gap stated, per this tree's rule that a stated gap "
                  "beats a plausible guess.")
    L.append("; " + "-" * 74)
    return L


BANNER = """
; ==============================================================================
; 0xF7A400-0xF7CFFF -- THE BLOCK-STORE ALLOCATOR AND THE SONG-STORE COMMANDS
;   the free-list half of the 256-byte block heap, and the 132-entry command
;   module that drives it from the SEQUENCER screens
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_module_frontier.py joins the thunk table's run
; decomposition (notes/prom_b_thunk_modules.py) with the converted/unconverted
; split (notes/prom_b_call_graph.py) and ranks runs by contiguous unconverted
; target extent.  T_BStore_AppendBytes_Join3_Veneer-T_F42ABC comes out with the most unconverted prom_b
; targets of any run in the image -- 132, every one of them inside ONE .incbin
; span, 8,906 bytes of extent, summed reference upper bound 172.  Immediately
; below it in the same span sits T_F42880-T_F42894 (6 slots), whose target
; notes/FINDINGS-prom_b-block-store.md had already singled out:
;     "T_F42884 -> 0xF7A402 is the block allocator itself -- it is what
;      BStore_AllocChain calls at 0xF63A18 for each block of a new chain.
;      It is the natural next conversion."
; Both runs are converted here, in one contiguous span.
;
; EXTENT.  0xF7A400-0xF7A7EA and 0xF7AA00-0xF7CE67 are code and data;
; 0xF7A7EB-0xF7A9FF (533 bytes) and 0xF7CE68-0xF7CFFF (408 bytes) are 0x0E
; (`ret`) padding, re-asserted to be pure 0x0E on every emit.  Below 0xF7A400
; is the font/bitmap data that FINDINGS-fonts.md covers; it stays .incbin.
;
; THE TWO HALVES
;
;  1. 0xF7A400-0xF7A7EA -- THE ALLOCATOR the block store one module down does
;     not contain.  It owns the free list: head in (0x6034B8), count in
;     (0x6034BA), 0xFFFF for "empty".  BStore_FreeList_Init threads every one of
;     the (0x3608) blocks onto it; BStore_AllocBlock pops one; BStore_FreeChain
;     splices a whole chain back.  The 256-byte record layout is exactly the one
;     FINDINGS-prom_b-block-store.md reads off 0xF63A3A/0xF63A46/0xF63A4B:
;         +0 flags (bit 7 = allocated) | +1..2 prev | +3..4 next | +5.. payload
;     BStore_AppendBytes is the writer: it appends to the chain of DIRECTORY
;     ENTRY (0x1008) -- 1-based, 3-byte stride, the same directory
;     FINDINGS-prom_b-block-store.md reads off BStore_OpenChain -- and allocates
;     a new block when the cursor would pass offset 0xFF, the new one restarting
;     at 0x100-0xFB = 5.
;
;     BStore_FreeList_Init also clears FIVE 17-entry arrays, and 17 is read off
;     its own `ld BC,0x0011` loops, not guessed:
;         0x00603500  17 x 3  the DIRECTORY (flags byte + head word 0xFFFF)
;         0x0060347E  17 x 2  saved cursor BLOCK numbers, cleared to 0xFFFF
;         0x006034A0  17 x 1  saved cursor OFFSETS, cleared to 5
;         0x00003460  17 x 2  an internal-RAM twin of the pair above
;         0x00003482  17 x 1
;     The two pairs abut exactly at 17 (0x0060347E + 17*2 = 0x006034A0) and are
;     0x22 apart, which is the displacement the append path uses
;     (`ld A,(XIX+0x22)` at 0xF7A6A5).  At 16 entries they would NOT abut.
;     Re-read on demand by `python3 notes/prom_b_songstore_checks.py --arrays`.
;     ⚠ This CORRECTS two documents: FINDINGS-memory-map.md said "16 saved
;     cursors", and FINDINGS-prom_b-block-store.md said the directory's entry
;     count was not established.
;
;  2. 0xF7AA00-0xF7CE67 -- THE COMMAND MODULE.  ⚠ The `SongStore_` prefix on
;     the data objects below names the SCREEN GROUP these handlers serve, which
;     is what the evidence reaches; it is not a proven subsystem name.  132 thunk slots, mostly small
;     handlers that read a mode byte, edit one variable, and post a message.
;     The idiom repeats: `cp (0x207E),0x01` gates on an edit mode, `or (0x2075),n`
;     and `and (0x2075),n` set and clear request bits, (0x2070) takes a 16-bit
;     message code, (0x2880) a status byte and (0x0D4A) an error code -- the same
;     two bytes the block store's error table feeds.
;
; THE TEN BANKS ARE THE TEN SONGS.  FINDINGS-prom_b-block-store.md closed with
; "What this module is FOR -- not established", and this module answers it as far
; as the bytes can.  At 0xF7AA35 the bank index the block store banks on becomes
; the number the screen shows:
;         ld A,(0x360a) / ld (0x0e02),A / inc 1,A / ld (0x12f6),A
; (0x360A) is the bank selector FINDINGS-prom_b-block-store.md derives at
; 0xF64B3D, prom_a bounds it to 0..9, this module bounds (0x0E02) the same way
; (`cp A,0x0a` at 0xF7AA99, `cp A,0x0a` / `ld A,0x09` at 0xF7AAC3 for the wrap),
; and (0x12F6) is drawn by 23 interpreter-B display-list records on the screens
; whose interpreter-A text reads SEQUENCER PLAY, S0NG, MEASURE = , TIME SIG.= ,
; REALTIME RECORD (`python3 notes/prom_b_var_screens.py --var 0x12F6`).
; ⚠ The display-list proximity is the WEAK link and the tool says so: "near:" is
; nearness in the code, not a proof that this record labels that variable.  The
; assignment chain and the two bounds are the strong part.
;
; WHAT IS NOT ESTABLISHED.  What 122 of the 132 command handlers DO.  They are
; `sub_XXXXXX` with a computed header that claims only the entry point, per this
; tree's rule that a stated gap beats a plausible guess.  Naming them needs the
; message codes in (0x2070), and nothing in this lane decodes those yet.
;
; REGENERATE:  python3 notes/gen_prom_b_songstore_module.py
; CHECKS:      python3 notes/gen_prom_b_songstore_module.py --checks
; ==============================================================================
"""

DATA_HEADERS = {
    0xF7AF5A: """
; SongStore_BitMask32 -- 32-bit single-bit masks, and it is TWO BYTES SHORT
;
; Read by:  three sites, all in this module, all with the same four
;   instructions: `xor B,B / ld XIX,0x00F7AF5A / sla 0x02,C / ld XWA,(XIX+BC)`
;   at 0xF7AE9E, 0xF7AEED and 0xF7AF3C.  The value is then applied to the 32-bit
;   variable (0x360C) -- `xor XWA,0xFFFFFFFF / and (0x360C),XWA` at the first two
;   (clear bit C) and `or (0x360C),XWA` at the third (set bit C).
; Index:    C = (0x0C70)-1, (0x0C71)-1 and (0x0C72)-1 respectively.  The
;   surrounding code splits the same index across two 16-bit words with
;   `cp A,0x10 / sub A,0x10` (0xF7AE78, 0xF7AE81), reading (0x3010) below 16 and
;   (0x3012) at or above it -- i.e. the design's index range is 0..31.
; Layout:   4-byte little-endian entries, stride fixed by the `sla 0x02,C`.
; Extent:   126 bytes, 0xF7AF5A-0xF7AFD7.  0xF7AF59 is the `ret` that ends the
;   routine above and 0xF7AFD8 is `calr`ed from 0xF7AC9D, so both ends are
;   instructions.
;
;
; Evidence: the three `ld XIX,0x00F7AF5A` sites are a whole-image scan at every
;   byte offset, re-run on every emit -- it can only over-count, so three is an
;   upper bound that happens to be exact here (each one is followed by the same
;   `sla 0x02,C / ld XWA,(XIX+BC)` pair).  The malformation below is asserted as
;   a byte equality against a table this emitter constructs, so it cannot drift.
;
; ⚠ THE TABLE IS MALFORMED, AND THIS IS A MEASUREMENT, NOT A READING.
;   The 126 bytes are byte-for-byte the ideal table `1<<k` for k = 0..31, LE32,
;   with TWO 0x00 BYTES MISSING at byte offset 9 -- inside entry 2.  The emitter
;   asserts that equality on every run, so it cannot drift.  Consequences, as
;   arithmetic on the bytes:
;       index 0 -> 0x00000001   index 1 -> 0x00000002   (both correct)
;       index 2 -> 0x00080004   (not 4)
;       index 3 -> 0x00100000   ... every later entry is the ideal one shifted
;       index 31 -> starts at 0xF7AFD6, TWO BYTES PAST the island, so its top
;                   half is the first two bytes of the instruction at 0xF7AFD8
;   ⚠ What this lane has NOT established: whether C ever exceeds 1 at run time.
;   The `cp A,0x10 / sub A,0x10` split is evidence that 0..31 is intended, and
;   the three readers are reached from a code path that also writes (0x3010) and
;   (0x3012); none of that is a measurement of a live index.  Reported as a
;   defect in the DATA, with the run-time consequence left open.
""",
    0xF7C2FA: """
; SongStore_Island_F7C2FA -- 17 bytes, unexplained
;
; Read by:  NOTHING.  No site in prom_a or prom_b spells 0x00F7C2FA (checked on
;   every emit by a whole-image scan at every byte offset, which can only
;   over-count, so a zero is a real zero).
; Extent:   by abutment only.  The instruction at 0xF7C2F8 is `jr T,0xf7c30b`,
;   which steps over exactly these 17 bytes, and 0xF7C30B begins a routine that
;   ends in `ret`.  No thunk target lands inside the range.
; Evidence: the zero-reference result and the `jr` that steps over it are both
;   re-checked on every emit, as is "no thunk target lands inside it".  Nothing
;   else here is claimed.
; Unknown:  everything else.  It is emitted as `.byte` because a linear decode
;   would silently resynchronise past it; whether it is data, dead code or a
;   fragment left by the linker is not established.
""",
    0xF7CD98: """
; SongStore_StepSizeTable -- the increment ladder for a held +/- key
;
; Read by:  one site, 0xF7CD6F `ld XDE,0x00F7CD98` then `ld L,(XDE+HL)` at
;   0xF7CD74, with HL = (0x0E18) zero-extended.
; Layout:   8 bytes, one per entry: 0, 1, 2, 3, 10, 50, 100, 200.
; Extent:   8 bytes.  0xF7CD97 is the `ret` above it; 0xF7CDA0 is `call`ed from
;   0xF7B7E3, so it is an instruction.  ⚠ The reader zero-extends L with no
;   upper-bound test, so 8 is the extent of the OBJECT by abutment, not a bound
;   the code enforces on the index.
; What the value does: it is added to WA and the sum clamped to 999
;   (`cp WA,0x03e7` at 0xF7CD83), or subtracted and clamped to 1
;   (`cp WA,1` at 0xF7CD90), selected by `cp (0x0C4F),0x80` at 0xF7CD7A.
; Evidence: the eight byte values and the single reader are both re-read from
;   the image on every emit; the clamp constants 0x03E7 and 1 are read off
;   0xF7CD83 and 0xF7CD90 in this transcription.
; Unknown:  what (0x0E18) counts.  A ladder 1,2,3,10,50,100,200 over a 1..999
;   range is the shape of a held-key acceleration, but nothing here measures it.
""",
}


def data_block(a, n, lab):
    """`.byte` lines for a data island or pointer table, plus its header."""
    out = []
    if a in DATA_HEADERS:
        out += [x for x in DATA_HEADERS[a].strip("\n").split("\n")]
    elif a in PTR_TABLES:
        cnt, site, bound = PTR_TABLES[a]
        out += ["; %s -- %d pointers, dispatched on (0x%04X)" %
                (lab[a], cnt, {0xF7C6E6: 0x0DF6, 0xF7C72F: 0x0DF6,
                               0xF7C94C: 0x0DED, 0xF7C998: 0x0DED,
                               0xF7CB7C: 0x0DE5, 0xF7CBCD: 0x0DE5}[a])]
        instr, operand = reader_of(a)
        out += wrap("; Read by: ", "one site: the `ld XDE,0x00%06X` at 0x%06X, "
                    "%d bytes in front of the table.  (A byte scan for the "
                    "address reports 0x%06X, which is that instruction's OPERAND "
                    "field, one byte in -- the instruction is at 0x%06X.)  The "
                    "reader is `ld L,(var) / cp L,1 / jp C,<ret> / cp L,%d / "
                    "jp UGT,<ret> / xor H,H / sla 0x02,HL / ld XDE,0x00%06X / "
                    "ld XHL,(XDE+HL) / call XHL`."
                    % (a, instr, a - instr, operand, instr, bound, a))
        out += wrap("; Entry count: ", "%d, from the reader's OWN upper bound "
                    "`cp L,%d` at 0x%06X -- not from dividing the byte extent by "
                    "4.  Cross-checked two ways on every emit: all %d entries "
                    "land on an instruction boundary of this transcription, and "
                    "the word one entry further on (0x%08X) is not an address in "
                    "this module.  ⚠ index 0 is never selected: the reader's "
                    "lower bound is `cp L,1 / jp C,<ret>`."
                    % (cnt, bound, site, cnt,
                       int.from_bytes(at(a + 4 * cnt, 4), "little")))
        out += wrap("; Entry 0: ", "0xF7C6FA, which is a bare `ret` -- the 0x0E "
                    "padding byte doing duty as a do-nothing handler.  All six "
                    "tables in this module share it.")
        out += wrap("; Evidence: ", "the `ld XDE,0x00%06X` at 0x%06X is the only "
                    "site in prom_a or prom_b that spells this address (whole-"
                    "image scan at every byte offset, re-run on every emit; the "
                    "hit is at 0x%06X, the OPERAND field of that instruction, "
                    "which starts one byte earlier, where the byte is 0x42 = "
                    "`ld XDE,imm32` -- reader_of() re-checks that byte), and the "
                    "five instructions "
                    "after it are the index arithmetic quoted above.  The word "
                    "count comes from that reader's own `cp L,%d`, not from the "
                    "byte extent."
                    % (a, instr, operand, bound))
        out += wrap("; Unknown: ", "what selects (0x%04X), and what the four live "
                    "handlers do -- they are sub_XXXXXX below."
                    % {0xF7C6E6: 0x0DF6, 0xF7C72F: 0x0DF6, 0xF7C94C: 0x0DED,
                       0xF7C998: 0x0DED, 0xF7CB7C: 0x0DE5, 0xF7CBCD: 0x0DE5}[a])
    else:
        out.append("; %s" % lab[a])
    out.append("%s:" % lab[a])
    if a in PTR_TABLES:
        for i, e in enumerate(ptr_entries(a)):
            out.append("\t.long\t0x%08X\t; [%d] -> %s" %
                       (e, i, lab.get(e, "0x%06X" % e)))
    else:
        for o in range(0, n, 16):
            row = at(a + o, min(16, n - o))
            out.append("\t.byte\t" + ", ".join("0x%02X" % x for x in row) +
                       "\t; %06X" % (a + o))
    return out


def emit():
    lab, th, sr, ic = labels(), thunks(), slot_refs(), internal_calls()
    ends = {}
    keys = sorted(lab)
    for i, a in enumerate(keys):
        ends[a] = keys[i + 1] if i + 1 < len(keys) else HI
    out = BANNER.strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind == "data":
            out += [""] + data_block(s, n, lab) + [""]
            continue
        for a, ln in transcribe_pairs(s, n):
            if a in lab:
                out += [""] + header(a, ends[a], lab, th, sr, ic)
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in th[a]) \
                      if a in th else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def transcribe_pairs(s, n):
    for ln in transcribe(s, n):
        m = re.search(r";\s*([0-9A-F]{6})\s", ln)
        yield int(m.group(1), 16), ln


def main():
    if "--checks" in sys.argv:
        return 0 if checks() else 1
    if "--layout" in sys.argv:
        for kind, s, n in LAYOUT:
            print("  %-4s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
        return 0
    if not checks(verbose=False):
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
