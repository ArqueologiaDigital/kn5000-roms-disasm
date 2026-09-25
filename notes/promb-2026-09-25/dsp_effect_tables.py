#!/usr/bin/env python3
r"""prom_b 0xF13124-0xF13D33: the DSP-effect editor's data tables, re-derived from their readers.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s carried the second half of the DSP-effect module
    as objects a content classifier had cut out and could not explain:
    `Data_F13124` (192 B), eleven ByteMap_/Data_/IndexMap_ pieces over
    0xF133E4-0xF135FC, `Data_F13659` (27 B), `DataPtrTable_F13674` ("Unknown:
    what indexes it, and what the entries mean"), `Data_F13874` (219 B) and
    `Data_F139AB` (905 B, "Unknown: everything about it except its bytes").
    This script re-derives what each is, from the ROM bytes and the reader
    instructions, and (with --apply) writes them back typed:

      A. 0xF13124: 32 records [min s16][max s16][step u16], one per effect VALUE
         TYPE (descriptor byte 1).  Reader shape: sub_F1071B & siblings take
         `6*type`, +0 -> E (lower bound), +2 -> D (upper bound), +4 -> H (the
         step when (0x28B0) bit 2 is set, else 1), then clamp the stepped value
         into [E, D].  Checked: every type a live descriptor group uses has
         min <= max, and the gain type 5 spans exactly the 49 gain strings.
      B. 0xF133E4-0xF135FC: for each of the three DSP effect BLOCKS (IndexedTable
         entries 97, 98, 99; (0x2797) = entry - 97) a 128-byte map algorithm ->
         list position (0xFF = not offered in this block), the inverse list
         position -> algorithm, and an 0xFF after it; then six bytes indexed by
         (0x2790).  Reader: sub_F10476 steps the position by one and reads the
         inverse list back.  Checked: inverse[forward[a]] == a for every offered
         algorithm, the inverse list is exactly the offered algorithms in
         ascending position, the byte after it is 0xFF, the forward map is 0xFF
         from index 100 on.
      C. 0xF13659: three 9-byte records, each an 8-byte IndexedParam_AdjustField
         descriptor (layout in that routine's header) plus one byte the routine
         never reads.  Readers: `lda XBC,0xF13659/+9/+0x12` at 0xF101CF,
         0xF101FB, 0xF10212.
      D. 0xF13674: 128 pointers, indexed by the ALGORITHM number (4*E after
         the block's validity map, sub_F11365), to per-algorithm DEFAULT
         records.
      E. 0xF13874: 73 records [IndexedTable entry][byte offset][mask], indexed
         by a PARAMETER NUMBER (3*n) in sub_F11C30 and sub_F1220B.
      F. 0xF139AB-0xF13CFF: the 57 default records D points at, tiling the span
         exactly: [selected-parameter index][4 bytes][values...][0xFF][0xFF];
         then 0xF13D00-0xF13D33, two 16x12 bitmaps and the first four bytes of
         a third (their records and the column-major reading are the res02f
         note that follows in the source).

RUN
    python3 notes/promb-2026-09-25/dsp_effect_tables.py            # checks + summary
    python3 notes/promb-2026-09-25/dsp_effect_tables.py --apply    # write the source
Always follow --apply with `make gate-wsa1`.
"""
import io
import os
import re
import sys
import contextlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import effect_descriptor_pool as EDP     # noqa: E402

ROOT = EDP.ROOT
SRC = EDP.SRC
BASE = 0xF00000
RANGES, MAPS, ADJ, DEFPTR, PNUM, DEFS, BITMAPS, END = (
    0xF13124, 0xF133E4, 0xF13659, 0xF13674, 0xF13874, 0xF139AB, 0xF13D00, 0xF13D34)
BLOCKS = [(97, 0xF133E4, 0xF13464), (98, 0xF13491, 0xF13511), (99, 0xF1353E, 0xF135BE)]
PAGEMAP = 0xF135F7
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def s16(b):
    return int.from_bytes(b, "little", signed=True)


def derive(rom):
    with contextlib.redirect_stdout(io.StringIO()):
        pool = EDP.derive(rom, quiet=True)
    if EDP.FAIL:
        check("effect_descriptor_pool.py checks pass", False)
    names = pool["names"]
    lab_desc = {r["start"]: r["label"] for r in pool["records"]}
    d = dict(pool=pool, names=names)

    # A. value-type ranges
    rng = []
    for k in range(32):
        r = rom.at(RANGES + 6 * k, 6)
        rng.append((s16(r[0:2]), s16(r[2:4]), int.from_bytes(r[4:6], "little")))
    d["ranges"] = rng
    used = {}
    for rec in pool["records"]:
        for g in rec["groups"]:
            if g[2] != 0xFF:
                used.setdefault(g[1], set()).add(pool["pn"][g[0]])
    d["used"] = used
    check("value-type range table: min <= max for every type a live group uses (%d types)"
          % len(used), all(rng[t][0] <= rng[t][1] for t in used))
    check("type 0x05 (the gain column, DLBTable_F15C93's 49 strings) spans 0..48",
          rng[5][:2] == (0, 48))
    check("types 0x00 and 0x1F (used by no group) are all-zero records",
          rng[0] == (0, 0, 0) and rng[31] == (0, 0, 0) and 0 not in used and 31 not in used)
    code = rom.at(0xF1072D, 0x2C).hex()
    check("sub_F1071B 0xF1072D: `ld C,6 / mul BC,(XIZ+8) / ... inc 4 / add XBC,0xF13124 / ld H`,"
          " then `inc 2 / add XBC,0xF13124 / ld D`, then `lda XBC,0xF13124` for +0",
          code.startswith("23068e0843") and code.count("2431f1") == 3)

    # B. per-block algorithm maps
    blocks = []
    for ent, fwd, inv in BLOCKS:
        f = list(rom.at(fwd, 128))
        offered = [a for a in range(128) if f[a] != 0xFF]
        n = len(offered)
        iv = list(rom.at(inv, n + 1))
        ok = all(iv[f[a]] == a for a in offered) and sorted(f[a] for a in offered) == list(range(n))
        check("block %d: map 0x%06X (128 B) and inverse 0x%06X (%d B) are mutual inverses"
              % (ent, fwd, inv, n), ok)
        check("block %d: the byte after the inverse list is 0xFF, and the map is 0xFF from 100"
              % ent, iv[n] == 0xFF and all(x == 0xFF for x in f[100:]))
        check("block %d: every offered algorithm has a named EffectNames_F147AC entry" % ent,
              all(names[a] != "----------" for a in offered))
        blocks.append(dict(ent=ent, fwd=fwd, inv=inv, f=f, offered=offered, iv=iv))
    check("the three maps tile 0xF133E4-0xF135F6 with nothing between them",
          BLOCKS[0][2] + len(blocks[0]["offered"]) + 1 == BLOCKS[1][1] and
          BLOCKS[1][2] + len(blocks[1]["offered"]) + 1 == BLOCKS[2][1] and
          BLOCKS[2][2] + len(blocks[2]["offered"]) + 1 == PAGEMAP)
    d["blocks"] = blocks
    fbv = tuple(rom.at(a, 2)[1] for a in (0xF104F1, 0xF10545, 0xF10598))
    check("sub_F10476's fall-backs for an algorithm the block does not offer: `ld L,n` (27 n) at "
          "0xF104F1 / 0xF10545 / 0xF10598 read 1, 35, 20 = %s" % (fbv,),
          all(rom.at(a, 1) == b"\x27" for a in (0xF104F1, 0xF10545, 0xF10598)) and
          fbv == (1, 35, 20))
    check("  ... and each fall-back is offered by its block",
          all(blocks[i]["f"][v] != 0xFF for i, v in enumerate(fbv)))
    d["fallback"] = fbv
    pm = list(rom.at(PAGEMAP, 6))
    check("0xF135F7: six bytes %s, every one a block index 0..2" % pm, all(x <= 2 for x in pm))
    check("0xF0F056: `add XBC,0x00F135F7` indexed by (0x2790), result -> (0x2797)",
          rom.at(0xF0F056, 6).hex() == "e9c8f735f100")
    d["pagemap"] = pm

    # C. adjust descriptors
    adj = [rom.at(ADJ + 9 * k, 9) for k in range(3)]
    check("0xF13659: three 9-byte records whose 9th byte is 0x00", all(a[8] == 0 for a in adj))
    for k, a in enumerate(adj):
        check("  record %d: +0 offset %d, +1 mask 0x%02X, +2 shift %d, bounds %d..%d"
              % (k, a[0], a[1], a[2], a[4], a[3]), a[4] <= a[3])
    d["adj"] = adj

    # F. default records (read before D so D can name them)
    ptrs = [rom.l(DEFPTR + 4 * k) for k in range(128)]
    targets = sorted(set(ptrs))
    users = {}
    for k, p in enumerate(ptrs):
        users.setdefault(p, []).append(k)
    check("DataPtrTable_F13674: 57 distinct targets, the first 0xF139AB", len(targets) == 57
          and targets[0] == DEFS)
    unused = [p for p in targets if len(users[p]) > 1]
    check("one target serves the 72 placeholder algorithms, and it is 0xF139AB", unused == [DEFS]
          and len(users[DEFS]) == 72 and all(names[k] == "----------" for k in users[DEFS]))
    recs = []
    a = DEFS + 3
    ok = rom.at(DEFS, 3) == b"\xff\xff\xff"
    for p in targets[1:]:
        ok &= (a == p)
        sel = rom.at(p, 1)[0]
        w1, w2 = rom.w(p + 1), rom.w(p + 3)
        vals = []
        q = p + 5
        while rom.at(q, 1)[0] != 0xFF:
            vals.append(rom.at(q, 1)[0])
            q += 1
        ok &= rom.at(q, 2) == b"\xff\xff"
        a = q + 2
        k = users[p][0]
        recs.append(dict(start=p, alg=k, sel=sel, w1=w1, w2=w2, vals=vals, end=a,
                         label="EffectDefaults_" + EDP.camel(names[k])))
    check("the 56 named default records tile 0xF139AE..0xF13CFF, each "
          "[sel][4 B][values][FF][FF], after a 3-byte 0xFF placeholder at 0xF139AB",
          ok and a == BITMAPS)
    # cross-check against the descriptors: sel is a markable group index or 0xFF,
    # and the value count covers the slots the descriptor names
    desc_of = {k: r for r in pool["records"] for k in r["users"]}
    selok, cntok, extra = True, True, []
    for r in recs:
        dr = desc_of[r["alg"]]
        marks = [g[3] for g in dr["groups"] if g[2] != 0xFF and g[3] != 0xFF]
        selok &= (r["sel"] == 0xFF and not marks) or r["sel"] in marks
        cntok &= len(r["vals"]) >= dr["w"] - 1
        if len(r["vals"]) != dr["w"] - 1:
            extra.append((names[r["alg"]], len(r["vals"]), dr["w"] - 1))
    check("every record's +0 is 0xFF or the +3 mark of one of its algorithm's groups", selok)
    check("every record carries at least W-1 values (one per slot its descriptor names)", cntok)
    print("     records carrying MORE values than W-1: %d %s" % (len(extra), extra[:8]))
    d["defs"] = recs
    d["def_ptrs"] = ptrs
    d["def_label"] = {r["start"]: r["label"] for r in recs}
    d["def_label"][DEFS] = "EffectDefaults_Unused"
    wpairs = sorted(set((r["w1"], r["w2"]) for r in recs))
    print("     the two words at +1/+3 take %d distinct pairs" % len(wpairs))
    check("sub_F11365: `mul BC,E` by 4 / `add XBC,0xF13674` at 0xF113F6; `ld H,0x11` at 0xF11440 "
          "... `cp H,0x14` at 0xF11475 (bytes 17..20); `ld H,1` at 0xF11487 (bytes 1..)",
          rom.at(0xF113F6, 12).hex() == "2304cd43e912e9c87436f100" and
          rom.at(0xF11440, 2).hex() == "2611" and rom.at(0xF11475, 3).hex() == "cecf14" and
          rom.at(0xF11487, 2).hex() == "2601")

    # E. parameter-number map
    pn = [tuple(rom.at(PNUM + 3 * k, 3)) for k in range(73)]
    check("0xF13874: 73 records of 3 bytes end exactly at DispatchTable_F1394F",
          PNUM + 3 * 73 == 0xF1394F)
    bands = all(pn[1 + i] == (0x61, i, 0xFF) for i in range(23)) and \
        all(pn[47 + i] == (0x63, i if i < 21 else i + 1, 0xFF) for i in range(22))
    check("parameter numbers 1-23 are block 97 bytes 0-22, 47-68 block 99 bytes 0-20 and 22",
          bands)
    b98 = [pn[24 + i] for i in range(23)]
    check("parameter numbers 24-46 are block 98 bytes 0-22 EXCEPT 17-20, which are absent "
          "(0xFF 0xFF 0xFF) -- the four bytes sub_F11365 does not write for block 98",
          all(b98[i] == (0x62, i, 0xFF) for i in range(23) if not 17 <= i <= 20) and
          all(b98[i] == (0xFF, 0xFF, 0xFF) for i in range(17, 21)))
    check("parameter number 0 is entry 96 byte 0 bit 0; 69 entry 121 byte 5; 70 absent; "
          "71/72 entry 0 bytes 5/7 masked 0x7F",
          pn[0] == (0x60, 0, 1) and pn[69] == (0x79, 5, 0xFF) and pn[70] == (0xFF,) * 3 and
          pn[71] == (0, 5, 0x7F) and pn[72] == (0, 7, 0x7F))
    check("sub_F11C30 refuses a parameter number above 0x48 (`cp (XIZ+8),0x0048` 0xF11C37) and "
          "indexes with `ldw bc,3 / mul XBC,(XIZ+8) / ld XIX,XBC / add XIX,0xF13874` at 0xF11C3F",
          rom.at(0xF11C37, 5).hex()[-4:] == "4800" and
          rom.at(0xF11C3F, 14).hex() == "3103009e0841e98cecc87438f100")
    d["pnum"] = pn
    return d


# ------------------------------------------------------------------ emit
def hx(v):
    return "0x%02x" % v


def emit_ranges(d):
    out = [r""";--------------------------------------------------------------------------
; EffectValueRanges -- 0xF13124-0xF131E3, 32 records of 6 bytes, one per
;   effect VALUE TYPE (byte +1 of an EffectDesc_* parameter group):
;     +0  s16  lower bound      +2  s16  upper bound
;     +4  u16  the COARSE step
; Read by: sub_F1071B (0xF1071B) and its siblings sub_F107D0, sub_F10885,
;   sub_F10985, sub_F10A97, sub_F10BA9 -- the value editors ScreenTable_F131E4
;   dispatches to by type -- with `ld C,6 / mul BC,(XIZ+8)` on the type: +4
;   becomes the step when (0x28B0) bit 2 is set (else the step is 1), +0 the
;   floor and +2 the ceiling the stepped value is clamped to (0xF1078D-0xF107A1:
;   `sub (XIX),H` unless below floor+step, `add (XIX),H` unless above
;   ceiling-step).  sub_F1195A (0xF1195A) and its siblings sub_F119A9,
;   sub_F119F8, sub_F11A61, sub_F11AF3 and sub_F11B85 read +0/+2 again and
;   reset a value outside [+0, +2] from a default array.
; Why these are the parameters' ranges: type 0x05 (the three BAND EMPHASIS G
;   groups) spans 0..48 and its units column is DLBTable_F15C93, exactly 49
;   strings "-12.0".."+12.0"; type 0x07 (LFO/OSC WAVEFORM) spans 0..2; type
;   0x0C (PITCH L/R) spans -36..+36.
; Types 0x00 and 0x1F are all-zero and used by no descriptor group.  Each
;   record's comment lists the parameter names whose groups carry that type.
; Re-derived by python3 notes/promb-2026-09-25/dsp_effect_tables.py.
; ⚠ REPLACES `Data_F13124`, whose header said "Unknown: everything about it
;   except its bytes".
;--------------------------------------------------------------------------
EffectValueRanges:"""]
    for k, (lo, hi, st) in enumerate(d["ranges"]):
        u = sorted(d["used"].get(k, []))
        out.append("\t.short\t%d, %d, %d\t; %06X  type 0x%02X%s" % (
            lo, hi, st, RANGES + 6 * k, k, ("  " + ", ".join(u)) if u else "  (no group)"))
    return "\n".join(out) + "\n\n\n"


def emit_maps(d):
    out = [r""";--------------------------------------------------------------------------
; EffectAlgoMaps -- 0xF133E4-0xF135FC: which effect ALGORITHMS each DSP effect
;   BLOCK offers, and in what order the editor steps through them.
; A block is IndexedTable entry 97, 98 or 99 ((0x2797) = entry - 97); its byte
;   0 is the algorithm number (0..127, an EffectNames_F147AC row).  Per block:
;     EffectAlgoToPos_BlockNN   128 bytes: algorithm -> position in the block's
;                               list, 0xFF = not offered (0xFF from 100 on)
;     EffectPosToAlgo_BlockNN   position -> algorithm, one byte per offered
;                               algorithm, then an 0xFF that ends the list
; Read by: sub_F10476 = DspEffect_StepAlgorithm (0xF10476): position =
;   AlgoToPos[current]; (0x28B0) bit 0 set steps down to 0, clear steps up
;   unless PosToAlgo[position+1] is 0xFF; the new algorithm is
;   PosToAlgo[position].  An algorithm the block does not offer is replaced by
;   1, 35 or 20 (blocks 97/98/99).  sub_F11365 = DspEffect_SetAlgorithm makes
;   the same substitution, and sub_F11C30 refuses a SysEx algorithm number
;   whose AlgoToPos byte is 0xFF.
; Checked by python3 notes/promb-2026-09-25/dsp_effect_tables.py: each pair
;   is mutually inverse, every offered algorithm has a real name, the lists
;   end in 0xFF and the three pairs tile the span with nothing between.
; ⚠ REPLACES ByteMap_F133E4, Data_F13448, ByteMap_F13464, Data_F13490,
;   ByteMap_F13491, Data_F134F5, ByteMap_F13511, Data_F1353D, ByteMap_F1354E,
;   Data_F135A2, IndexMap_F135BF, ByteMap_F135CB and Data_F135F6.  The two
;   ByteMap headers said "Unknown: what the two index spaces ARE" -- they are
;   algorithm numbers and list positions -- and the block-99 pair was split
;   across five objects because its map starts one byte after an 0xFF.
;--------------------------------------------------------------------------"""]
    for b in d["blocks"]:
        out.append("; block %d: %d algorithms offered, fall-back %d `%s`" % (
            b["ent"], len(b["offered"]), d["fallback"][b["ent"] - 97],
            d["names"][d["fallback"][b["ent"] - 97]]))
        out.append("EffectAlgoToPos_Block%d:" % b["ent"])
        f = b["f"]
        for r in range(0, 128, 16):
            out.append("\t.byte\t%s\t; %06X  algorithms %d..%d" % (
                ", ".join(hx(x) for x in f[r:r + 16]), b["fwd"] + r, r, r + 15))
        out.append("EffectPosToAlgo_Block%d:" % b["ent"])
        for i, a in enumerate(b["iv"][:-1]):
            out.append("\t.byte\t%d\t; %06X  [%d] %s" % (a, b["inv"] + i, i, d["names"][a]))
        out.append("\t.byte\t0xff\t; %06X  end of list" % (b["inv"] + len(b["iv"]) - 1))
    out.append(r""";--------------------------------------------------------------------------
; EffectPage_BlockIndex -- 0xF135F7, 6 bytes indexed by (0x2790).
; Read by: sub_F0F047 (0xF0F047): when (0x2790) is non-zero, `add XBC,this /
;   ld (0x2797),(XBC)` -- so the byte is the effect-block index (0..2, entry
;   97 + it) the page numbered (0x2790) edits.  Entry 0 is never read (the
;   routine returns first when (0x2790) is 0).
;--------------------------------------------------------------------------
EffectPage_BlockIndex:""")
    out.append("\t.byte\t%s\t; %06X  pages 0..5" % (", ".join("%d" % x for x in d["pagemap"]),
                                                    PAGEMAP))
    return "\n".join(out) + "\n\n\n"


ADJ_NAMES = ["AdjustDesc_EffectBlockByte21", "AdjustDesc_Entry121Byte5Low",
             "AdjustDesc_Entry121Byte5High"]


def emit_adj(d):
    out = [r""";--------------------------------------------------------------------------
; AdjustDesc_* -- 0xF13659-0xF13673: three IndexedParam_AdjustField descriptors,
;   9 bytes apart.  Bytes +0..+7 are the descriptor that routine documents
;   (+0 byte offset, +1 mask, +2 right shift, +3 upper bound, +4 lower bound,
;   +5/+6 the two coarse steps, +7 XORed into (0x28B0)); +8 is 0x00 in all
;   three and IndexedParam_AdjustField does not read it.
; Read by: sub_F101C8 (0xF101C8) passes the first with entry 97 + (0x2797)
;   unless (0x2797) is 2 -- byte 21 of effect blocks 97/98, 0..99, which is
;   also why the SysEx parameter map (EffectParamNumberMap) has a byte-21
;   parameter for blocks 97 and 98 and none for 99.  sub_F101E7 (0xF101E7)
;   passes the second (block index 0) or the third (block index 1, when
;   IndexedTable_GetByte(96, 0) is 0) with entry 121 (`push 0x0079`): the low
;   and the high nibble of that entry's byte 5, each 1..4.
; What byte 21 and entry 121's byte 5 MEAN is not decoded here; the names
;   say where the bytes are, which the readers establish.
;--------------------------------------------------------------------------"""]
    for k, a in enumerate(d["adj"]):
        out.append("%s:" % ADJ_NAMES[k])
        out.append("\t.byte\t%d, 0x%02x, %d, %d, %d, %d, %d, 0x%02x\t; %06X  offset, mask, shift, "
                   "upper, lower, step, step, xor" % (a[0], a[1], a[2], a[3], a[4], a[5], a[6],
                                                      a[7], ADJ + 9 * k))
        out.append("\t.byte\t0x00\t; %06X  not read" % (ADJ + 9 * k + 8))
    return "\n".join(out) + "\n\n\n"


def emit_pnum(d):
    out = [r""";--------------------------------------------------------------------------
; EffectParamNumberMap -- 0xF13874-0xF1394E, 73 records of 3 bytes, indexed by
;   an effect PARAMETER NUMBER n (0..72):
;     +0  IndexedTable entry (0xFF = no such parameter)
;     +1  byte offset in that entry's object
;     +2  mask
; Read by: sub_F11C30 = DspParam_WriteByNumber (0xF11C30, thunk T_F434A0) and
;   sub_F1220B = DspParam_ReadByNumber (0xF1220B, thunk T_F434A4), both with
;   `ldw bc,3 / mul XBC,(XIZ+8) / add XIX,this`; the writer refuses n > 0x48.
;   prom_a calls the two thunks at 0xFB3AFD and 0xFB4A41 with n taken from
;   IndexMap_F4FA9B + 1 (0xF4FA9C) -- the dense index that map gives the
;   result of prom_a sub_FB62D3.
; Layout, checked by python3 notes/promb-2026-09-25/dsp_effect_tables.py:
;   n = 0 entry 96 byte 0 bit 0; n = 1-23 block 97 bytes 0-22; n = 24-46
;   block 98 bytes 0-22 with 17-20 ABSENT (exactly the four bytes
;   DspEffect_SetAlgorithm does not write for block 98); n = 47-68 block 99
;   bytes 0-20 and 22 (no byte 21, as AdjustDesc_EffectBlockByte21's reader
;   skips block 99); n = 69 entry 121 byte 5; n = 70 absent in the table --
;   the reader special-cases it from entries 6 and 32; n = 71/72 entry 0
;   bytes 5 and 7, masked 0x7F.
; ⚠ REPLACES `Data_F13874` ("Unknown: everything about it except its bytes").
;--------------------------------------------------------------------------
EffectParamNumberMap:"""]
    for k, (e, o, m) in enumerate(d["pnum"]):
        if e == 0xFF:
            what = "(none)"
        elif 97 <= e <= 99:
            what = "block %d byte %d" % (e, o)
        else:
            what = "entry %d byte %d" % (e, o)
        out.append("\t.byte\t%s, %s, %s\t; %06X  n=%d  %s%s" % (
            ("%d" % e) if e != 0xFF else "0xff", ("%d" % o) if o != 0xFF else "0xff", hx(m),
            PNUM + 3 * k, k, what, "" if m == 0xFF or e == 0xFF else ", mask 0x%02X" % m))
    return "\n".join(out) + "\n\n\n"


def emit_defs(d):
    pool = d["pool"]
    desc_of = {k: r for r in pool["records"] for k in r["users"]}
    out = [r"""; --------------------------------------------------------------------------
; EffectDefaults_* -- 0xF139AB-0xF13CFF: the DEFAULT PARAMETER VALUES of each
;   effect algorithm, 57 records, one per distinct entry of
;   EffectDefaultParams (above).  The 56 named records tile 0xF139AE-0xF13CFF
;   exactly behind a 3-byte 0xFF placeholder.  Record:
;     +0  the selected-parameter index: 0xFF or the +3 mark of one of the
;         algorithm's EffectDesc_* groups (checked for all 56)
;     +1  four bytes, written to fields 17..20 of the block (not for block 98)
;     +5  the parameter values, one byte per slot from slot 1, then 0xFF 0xFF
; Read by: sub_F11365 = DspEffect_SetAlgorithm (0xF11365), with E = the
;   algorithm: `mul BC,E` by 4 / `add XBC,EffectDefaultParams` / `ld XBC,(XBC)`
;   at 0xF113F6.  It stores +0 to byte 22 of the block (the byte
;   DspEffect_PaintParamEditor compares with each group's +3 mark), copies
;   +1..+4 to bytes 17..20 unless the block is 98, then copies values into
;   bytes 1..16 until the first 0xFF and zero-fills the rest; every byte it
;   writes is also queued with T_Queue2E00_Append4(block, byte, value, 0xFF).
; The values read correctly against EffectDesc_* and EffectValueRanges: CHORUS
;   gets WET 99, DEPTH 30, LFO SPEED 6, WAVEFORM 0, VOLUME 84; the PARAMETRIC
;   EQ's six bands are one 16-bit word each (Fc, Q and G share a slot:
;   sub_F10985, the type-2/3 editor, does `ld BC,(XIX)` and takes Fc from bits
;   6..10 with `and BC,0x07C0 / srl 6,BC` at 0xF109F3).  Some
;   records carry values past the descriptor's last slot (DISTORTION /
;   OVERDRIVE / FUZZ end 00 / 01 / 02) -- bytes no editor page shows.
; Re-derived by python3 notes/promb-2026-09-25/dsp_effect_tables.py.
; ⚠ REPLACES the defaults part of `Data_F139AB`, whose header said "Unknown:
;   everything about it except its bytes".
; --------------------------------------------------------------------------
EffectDefaults_Unused:
	.byte	0xff, 0xff, 0xff	; F139AB  the 72 placeholder algorithms -- never read: the
				;         block maps replace an unoffered algorithm first"""]
    for r in d["defs"]:
        dr = desc_of[r["alg"]]
        slots = {}
        for g in dr["groups"]:
            if g[2] != 0xFF:
                slots.setdefault(g[2], pool["pn"][g[0]])
        out.append("; %s -- algorithm %d `%s`: %d value bytes (W-1 = %d)" % (
            r["label"], r["alg"], d["names"][r["alg"]], len(r["vals"]), dr["w"] - 1))
        out.append("%s:" % r["label"])
        p = r["start"]
        out.append("\t.byte\t%s\t; %06X  selected parameter%s" % (
            ("%d" % r["sel"]) if r["sel"] != 0xFF else "0xff", p,
            "" if r["sel"] == 0xFF else " = group %d" % r["sel"]))
        out.append("\t.short\t0x%04x, 0x%04x\t; %06X  -> block bytes 17..20" % (r["w1"], r["w2"],
                                                                              p + 1))
        vals = r["vals"]
        s = 0
        while s < len(vals):
            nm = slots.get(s + 1, "")
            if not nm:
                nm = ("(second byte of slot %d's word)" % s) if s in slots and \
                    s + 1 < dr["w"] else "(no descriptor group names this slot)"
            out.append("\t.byte\t%d\t; %06X  slot %d  %s" % (vals[s], p + 5 + s, s + 1, nm))
            s += 1
        out.append("\t.byte\t0xff, 0xff\t; %06X  end" % (p + 5 + len(vals)))
    out.append(r"""; --------------------------------------------------------------------------
; Bitmap_Knob_16x12 / Bitmap_KnobWithLine_16x12 -- 0xF13D00 and 0xF13D18,
;   24 bytes each: 16 x 12, 1 bit per pixel, COLUMN-major (2 byte columns of
;   12 rows).  Drawn by the op-0x03 display-list records at 0xF13F50 /
;   0xF13F5C (0xF13D00) and 0xF14311 / 0xF1431D (0xF13D18) -- `03 0C`, BC = 2,
;   HL = 12 -> LCD_Svc_03_BlitColumns.  The pictures, the column-major reading
;   and its evidence are in the res02f note below; the NAMES are a visual
;   identification of those pictures (a circle with a pointer; the same with a
;   line through it) and claim nothing else.  Bitmap_F13D30 is the third of
;   the four; its first four bytes end this span.
; --------------------------------------------------------------------------""")
    rom = EDP.Rom()
    for lab, a in (("Bitmap_Knob_16x12", 0xF13D00), ("Bitmap_KnobWithLine_16x12", 0xF13D18)):
        out.append("%s:" % lab)
        for c in range(2):
            out.append("\t.byte\t%s\t; %06X  column %d, rows 0..11" % (
                ", ".join(hx(x) for x in rom.at(a + 12 * c, 12)), a + 12 * c, c))
    out.append("Bitmap_F13D30:\t\t; the 2 x 12 bitmap the record at 0xF14556 draws")
    out.append("\t.byte\t%s\t; F13D30  column 0, rows 0..3 (rows 4..11 follow the note below)"
               % ", ".join(hx(x) for x in rom.at(0xF13D30, 4)))
    return "\n".join(out) + "\n"


# ------------------------------------------------------------------ apply
UNKNOWN2 = (";          per this tree's rule that a stated gap beats a plausible guess.\n"
            "; --------------------------------------------------------------------------\n")
UNKNOWN1 = "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"

RENAMES = {
    "sub_F10476": ("DspEffect_StepAlgorithm", """; Name:    DspEffect_StepAlgorithm -- named 2026-09-25 (lane promb).
; Evidence: for the block entry 97 + (0x2797) it looks the block's byte 0 (the
;          algorithm) up in EffectAlgoToPos_Block97/98/99, steps the position
;          down ((0x28B0) bit 0 set, not below 0) or up (not past the 0xFF
;          that ends EffectPosToAlgo_BlockNN), and reads the new algorithm
;          back from EffectPosToAlgo_BlockNN; an algorithm the block does not
;          offer becomes 1, 35 or 20.  If it changed, it is stored to byte 0
;          and DspEffect_SetAlgorithm (sub_F11365) is called with it, which
;          loads that algorithm's EffectDefaults_* record.
;          python3 notes/promb-2026-09-25/dsp_effect_tables.py checks the maps.
"""),
    "sub_F11365": ("DspEffect_SetAlgorithm", """; Name:    DspEffect_SetAlgorithm -- named 2026-09-25 (lane promb).
; Inputs:  (XIZ+8) = block entry 97..99 (anything else returns at once),
;          (XIZ+10) = algorithm.
; Evidence: an algorithm the block does not offer (EffectAlgoToPos_BlockNN
;          byte 0xFF) becomes 1 / 35 / 20; the algorithm is stored to byte 0
;          of the block's IndexedTable object and queued; then
;          EffectDefaultParams[algorithm] is fetched (`add XBC,this` at
;          0xF113FC) and its EffectDefaults_* record copied: +0 -> byte 22,
;          +1..+4 -> bytes 17..20 (skipped for block 98), values -> bytes 1..16
;          up to the first 0xFF, zero after it -- each byte also queued with
;          T_Queue2E00_Append4(block, byte, value, 0xFF).
;          python3 notes/promb-2026-09-25/dsp_effect_tables.py.
"""),
    "sub_F11C30": ("DspParam_WriteByNumber", """; Name:    DspParam_WriteByNumber -- named 2026-09-25 (lane promb).
; Inputs:  (XIZ+8) = parameter number n (refused above 0x48),
;          (XIZ+10) = value.
; Evidence: the record EffectParamNumberMap[n] (`ldw bc,3 / mul XBC,(XIZ+8) /
;          add XIX,EffectParamNumberMap` at 0xF11C3F) names the IndexedTable
;          entry, byte and mask; an entry of 0xFF ends at once; n is then
;          range-checked per parameter (the `cp BC,n` ladder from 0xF11C70)
;          and the value stored under the mask -- for n = 1/24/47, the
;          algorithm, only if EffectAlgoToPos_BlockNN offers it, and then
;          through DspEffect_SetAlgorithm.  Reached from prom_a 0xFB3AFD via
;          T_F434A0 with n from IndexMap_F4FA9B + 1 (0xF4FA9C).
"""),
    "sub_F1220B": ("DspParam_ReadByNumber", """; Name:    DspParam_ReadByNumber -- named 2026-09-25 (lane promb).
; Inputs:  (XIZ+8) = first parameter number, (XIZ+10) = count,
;          (XIZ+12) = destination.
; Evidence: for each n it reads EffectParamNumberMap[n] (`add XIX,this` at
;          0xF1221A, `inc 3,XIX` per step at 0xF122B7) and stores
;          IndexedTable_GetByte(entry, byte) AND mask to the destination; an
;          absent record gives 0, except n = 70, which is built from entry 6
;          byte 0 and the low nibbles of entry 32 bytes 3 and 4.  Reached from
;          prom_a 0xFB4A41 via T_F434A4 (count 1) with n from IndexMap_F4FA9B
;          + 1 (0xF4FA9C).
"""),
}


def corrected(old):
    return ("; ⚠ CORRECTED 2026-09-25: this header used to end `Unknown: what the routine\n"
            ";          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's\n"
            ";          rule that a stated gap beats a plausible guess.`\n")


def block_start(L, i):
    j = i
    while j > 0 and (L[j - 1].startswith(";") or not L[j - 1].strip()):
        j -= 1
    while j < i and not L[j].strip():
        j += 1
    return j


def replace_span(L, first_label, next_label, new_text):
    i = [k for k, t in enumerate(L) if re.match(r'^%s:' % re.escape(first_label), t)]
    j = [k for k, t in enumerate(L) if re.match(r'^%s:' % re.escape(next_label), t)]
    assert len(i) == 1 and len(j) == 1, (first_label, next_label, i, j)
    s, e = block_start(L, i[0]), block_start(L, j[0])
    new = new_text.encode("utf-8").decode("latin-1").rstrip("\n").split("\n") + ["", ""]
    return L[:s] + new + L[e:]


def apply(d):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    # spans, bottom-up so indices stay valid
    # F: Data_F139AB .. up to the res02f note: the span ends at the `.byte` run's last line,
    # which is followed by the `; --- 0xF13D34-...` banner lines; anchor on the first banner.
    i = [k for k, t in enumerate(L) if t.startswith("Data_F139AB:")]
    assert len(i) == 1
    s = block_start(L, i[0])
    e = i[0] + 1
    while L[e].startswith("\t.byte"):
        e += 1
    assert "F13D2B" in L[e - 1], L[e - 1]
    new = emit_defs(d).encode("utf-8").decode("latin-1").rstrip("\n").split("\n")
    L = L[:s] + new + L[e:]
    L = replace_span(L, "Data_F13874", "DispatchTable_F1394F", emit_pnum(d))
    # D: rewrite the 128 pointers of DataPtrTable_F13674
    t = [k for k, x in enumerate(L) if x.startswith("DataPtrTable_F13674:")][0]
    pat = re.compile(r'^(\t\.long\t)([^;]*?)(\t; ([0-9A-F]{6})  \[(\d+)\].*)$')
    for k in range(128):
        m = pat.match(L[t + 1 + k])
        assert m and int(m.group(4), 16) == DEFPTR + 4 * k and int(m.group(5)) == k, L[t + 1 + k]
        p = d["def_ptrs"][k]
        L[t + 1 + k] = "%s%s\t; %06X  [%d] -> 0x%06X  %s" % (m.group(1), d["def_label"][p],
                                                            DEFPTR + 4 * k, k, p, d["names"][k])
    # D header: answer the Unknown line in place
    hdr_unknown = "; Unknown: what indexes it, and what the entries mean."
    k = t - 1
    while not L[k].startswith(hdr_unknown):
        k -= 1
        assert k > t - 40
    ans = """; ⚠ ANSWERED 2026-09-25 (lane promb).  This header used to end `Unknown: what
;    indexes it, and what the entries mean.`  DspEffect_SetAlgorithm (0xF11365)
;    indexes it with 4 * the ALGORITHM number (`mul BC,E` / `add XBC,this` at
;    0xF113F6-0xF113FC; sub_F1162E does the same at 0xF11646), and an entry
;    points at that algorithm's DEFAULT PARAMETER record, EffectDefaults_* --
;    layout and checks in that block's header.  The 72 slots that share one
;    target are the 72 `----------` placeholder algorithms, as in
;    EffectParamDescriptors_F12F24.  Renamed EffectDefaultParams.""".encode(
        "utf-8").decode("latin-1").split("\n")
    L = L[:k] + ans + L[k + 1:]
    L = replace_span(L, "Data_F13659", "DataPtrTable_F13674", emit_adj(d))
    L = replace_span(L, "ByteMap_F133E4", "DispatchTable_F135FD", emit_maps(d))
    L = replace_span(L, "Data_F13124", "ScreenTable_F131E4", emit_ranges(d))
    txt = "\n".join(L)
    # numeric operands that name these objects' interiors
    for num, lab in ((15807806, "EffectAlgoToPos_Block99"), (15807934, "EffectPosToAlgo_Block99"),
                     (15807991, "EffectPage_BlockIndex")):
        txt, n = re.subn(r'(\tadd\txbc, )%d(\t)' % num, r'\g<1>%s\g<2>' % lab, txt)
        assert n >= 1, (num, n)
    # label renames of objects kept in place
    for old, new in (("DataPtrTable_F13674", "EffectDefaultParams"),
                     ("ByteMap_F133E4", "EffectAlgoToPos_Block97"),
                     ("ByteMap_F13464", "EffectPosToAlgo_Block97"),
                     ("ByteMap_F13491", "EffectAlgoToPos_Block98"),
                     ("ByteMap_F13511", "EffectPosToAlgo_Block98"),
                     ("Data_F13124", "EffectValueRanges"),
                     ("Data_F13874", "EffectParamNumberMap")):
        txt = re.sub(r'\b%s\b' % old, new, txt)
    txt = re.sub(r'\bData_F13659 \+ 0x9\b', ADJ_NAMES[1], txt)
    txt = re.sub(r'\bData_F13659 \+ 0x12\b', ADJ_NAMES[2], txt)
    txt = re.sub(r'\bData_F13659\b', ADJ_NAMES[0], txt)
    # routines
    for old, (new, block) in RENAMES.items():
        anchor = UNKNOWN1 + UNKNOWN2 + old + ":"
        assert txt.count(anchor) == 1, old
        repl = (block + corrected(old)).encode("utf-8").decode("latin-1") + \
            "; --------------------------------------------------------------------------\n" + \
            old + ":"
        txt = txt.replace(anchor, repl)
        txt = re.sub(r'\b%s(\w*)\b' % old, lambda m: new + m.group(1), txt)
    # the two bitmaps' display-list records, and the note that said the third was unlabelled
    for off, lab in (("0x355", "Bitmap_Knob_16x12"), ("0x36D", "Bitmap_KnobWithLine_16x12")):
        txt, n = re.subn(r'\.long Data_F139AB \+ %s\b' % off, ".long " + lab, txt)
        assert n == 2, (off, n)
    note = ("; the `.byte` run above and are NOT relabelled here (see the \u26a0 above).\n"
            .encode("utf-8").decode("latin-1"))
    assert txt.count(note) == 1
    txt = txt.replace(note, note + (
        "; \u26a0 2026-09-25 (lane promb): rows 0..3 now sit under the label Bitmap_F13D30, which\n"
        ";   ends the typed DSP-effect span above (notes/promb-2026-09-25/dsp_effect_tables.py);\n"
        ";   the boundary moved in this text only -- notes/prom_b_f0ea9f_layout.py is unchanged.\n"
    ).encode("utf-8").decode("latin-1"))
    banner = ("; CHECKS:      python3 notes/gen_prom_b_f0ea9f_module.py --checks\n")
    assert txt.count(banner) == 1
    txt = txt.replace(banner, banner + (
        "; \u26a0 2026-09-25 (lane promb): THIS TEXT IS NO LONGER THE EMITTER'S OUTPUT.  The\n"
        ";   emitter prints to stdout and never writes this file; since wave 8 its text has\n"
        ";   been edited in place, and 0xF124A6-0xF12F23 and 0xF13124-0xF13D33 are now typed\n"
        ";   from their readers by notes/promb-2026-09-25/effect_descriptor_pool.py and\n"
        ";   dsp_effect_tables.py.  Re-pasting the emitter's output would discard all of\n"
        ";   that; --checks (ROM framing only) still passes and is still worth running.\n"
    ).encode("utf-8").decode("latin-1"))
    data = txt.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


def main():
    rom = EDP.Rom()
    d = derive(rom)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--emit" in sys.argv:
        for f in (emit_ranges, emit_maps, emit_adj, emit_pnum, emit_defs):
            sys.stdout.write(f(d))
    elif "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
