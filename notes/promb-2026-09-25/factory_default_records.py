#!/usr/bin/env python3
r"""prom_b 0xF3F400-0xF3FD5F: the FACTORY-DEFAULT image of the parameter records -- what each record is, from its readers.

QUESTION THIS ANSWERS
    wsa1/notes/gen_prom_b_f3f400_module.py cracked the FRAMING of the last 3 KB
    of prom_b -- `[id, len, len bytes of payload]` records, 0xFF section
    terminators -- and left the meaning open ("Field semantics are deferred";
    77 `Rec_F3Fxxx` labels with no header).  prom_a reads these records, and
    its readers say what they are:

      * PtrTable_FAD28A (prom_a, 64 LE32) holds, at index k, the address of
        the record whose id is k (0x00-0x3F) -- checked for all 64;
      * ByteTable_FAD38A (13 bytes) + PtrTable_FAD397 (13 LE32) hold the id
        and the address of each of the 13 other records -- the byte table's
        j-th id IS the id byte of the record the pointer table's j-th entry
        names, checked for all 13;
      * the loaders copy each record's payload, byte for byte from offset 0,
        into the RAM record ParamNumber_RecordPtrs (0xFACDEA, the table
        (0x60F018) points at) gives for that id -- `calr 0xFAC8AA` = "XIY =
        ParamNumber_RecordPtrs[id]", then `record[H] = payload[H]` for
        H < len:
          sub_FAAE2A (prom_a, via routine-directory slot T_F43440): all 64
            ids 0x00-0x3F (`add XBC,0x00FAD28A` at 0xFAAE46, `add
            XBC,0x00FAD30A` at 0xFAAEA7 for the second 32);
          sub_FAAF91 (T_F43444): the 13 others (`add XBC,0x00FAD38A` at
            0xFAAFCE, `add XBC,0x00FAD397` at 0xFAAFE0), then for ids
            0x61/0x62/0x63 hands the record's byte 0 to sub_F114DA (T_F42F58);
          sub_FAA967 (T_F4077C): bytes 0x0D-0x15 only, of ids 0x00-0x1F.
      So each record is the factory default of one parameter record, and this
    block is what a reset copies into RAM.  prom_a's ParamNumber_RecordPtrs
    header already establishes that ids 0x00-0x1F are the 32 PART records
    and 0x20-0x3F their second halves (+0x20), with +0x0D the MIDI channel:
    and indeed record k's payload byte 0x0D is k for every part, so part k
    defaults to channel k.  This file's DSP-effect headers establish that
    IndexedTable entries 97-99 (0x61-0x63) are the three effect blocks (byte
    0 = algorithm): their defaults are algorithms 1, 35 and 20.

RUN
    python3 notes/promb-2026-09-25/factory_default_records.py            # checks
    python3 notes/promb-2026-09-25/factory_default_records.py --apply    # write the source
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE, BASE_A = 0xF00000, 0xF80000
LO, END = 0xF3F400, 0xF3FD60
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    a = open(ROMA, "rb").read()
    atb = lambda x, n: b[x - BASE:x - BASE + n]
    ata = lambda x, n: a[x - BASE_A:x - BASE_A + n]
    ua = lambda x: int.from_bytes(ata(x, 4), "little")
    recs, p = [], LO
    while p < END:
        i, n = atb(p, 2)
        if i == 0xFF:
            p += 2
            continue
        recs.append((p, i, n))
        p += 2 + n
    check("the walk from 0xF3F400 lands on 0xF3FD60: %d records" % len(recs), p == END and len(recs) == 77)
    by_id = {i: (p, n) for p, i, n in recs}
    check("every id occurs once", len(by_id) == len(recs))
    check("PtrTable_FAD28A[k] = the record whose id is k, k = 0x00-0x3F",
          all(ua(0xFAD28A + 4 * k) == by_id[k][0] for k in range(64)))
    ids13 = list(ata(0xFAD38A, 13))
    ptr13 = [ua(0xFAD397 + 4 * j) for j in range(13)]
    check("ByteTable_FAD38A[j] = the id byte at PtrTable_FAD397[j], j = 0..12 (ids %s)"
          % " ".join("%02X" % x for x in ids13),
          all(atb(p, 1)[0] == i for i, p in zip(ids13, ptr13)))
    check("  ... and together the two prom_a tables name all 77 records exactly once",
          sorted(list(range(64)) + ids13) == sorted(by_id))
    ram = {i: ua(0xFACDEA + 4 * i) for i in by_id}
    check("ParamNumber_RecordPtrs (0xFACDEA) has a RAM record for every id (none 0xFFFFFFFF); "
          "part k at 0x%04X.., id 0x20+k = id k + 0x20" % ram[0],
          all(v != 0xFFFFFFFF and v < 0x10000 for v in ram.values()) and
          all(ram[0x20 + k] == ram[k] + 0x20 for k in range(32)))
    check("the loaders: `add XBC,0x00FAD28A` at 0xFAAE46 and 0xFAA9A8, `add XBC,0x00FAD30A` at "
          "0xFAAEA7, `add XBC,0x00FAD38A` at 0xFAAFCE and 0xFAB031, `add XBC,0x00FAD397` at 0xFAAFE0",
          ata(0xFAAE46, 6).hex() == "e9c88ad2fa00" and ata(0xFAA9A8, 6).hex() == "e9c88ad2fa00"
          and ata(0xFAAEA7, 6).hex() == "e9c80ad3fa00" and ata(0xFAAFCE, 6).hex() == "e9c88ad3fa00"
          and ata(0xFAB031, 6).hex() == "e9c88ad3fa00" and ata(0xFAAFE0, 6).hex() == "e9c897d3fa00")
    check("  `calr 0xFAC8AA` (XIY = ParamNumber_RecordPtrs[id]: `add XBC,0x00FACDEA` at 0xFAC8B5) "
          "before each; the stores `ld (XBC),W` at 0xFAAE82 and 0xFAB01D",
          ata(0xFAC8B5, 6).hex() == "e9c8eacdfa00" and ata(0xFAAE82, 2).hex() == "b140"
          and ata(0xFAB01D, 2).hex() == "b140")
    check("  sub_FAA967 copies offsets 0x0D-0x15: `ld H,0x0D` at 0xFAA9B5, `cp H,0x15` at 0xFAA9E4",
          ata(0xFAA9B5, 2).hex() == "260d" and ata(0xFAA9E4, 3).hex() == "cecf15")
    check("routine directory: T_F43440 = jp 0xFAAE2A, T_F43444 = jp 0xFAAF91, T_F4077C = jp 0xFAA967, "
          "T_F42F58 = jp 0xF114DA",
          atb(0xF43440, 4).hex() == "1b2aaefa" and atb(0xF43444, 4).hex() == "1b91affa"
          and atb(0xF4077C, 4).hex() == "1b67a9fa" and atb(0xF42F58, 4).hex() == "1bda14f1")
    pay = lambda i: atb(by_id[i][0] + 2, by_id[i][1])
    check("parts: payload byte 0x0D of id k is k, k = 0x00-0x1F (the MIDI channel byte)",
          all(pay(k)[0x0D] == k for k in range(32)))
    odd = [k for k in range(32) if pay(k)[1] != 0x00]
    check("  payload byte 1 is 0x00 for every part but part 9 (0x%02X) -- channel 10" % pay(9)[1],
          odd == [9])
    # whole first halves, the channel byte masked (claims review 2026-10-02, item 46: byte 1
    # alone could not see part 0's +0x0C)
    def masked(k):
        b = bytearray(pay(k))
        b[0x0D] = 0
        return bytes(b)
    diffA = {k: [i for i in range(len(pay(k))) if masked(k)[i] != masked(1)[i]] for k in range(32)}
    check("  first halves, +0x0D masked, equal part 1's but for part 0 (+0x0C = 0x%02X) and part 9 "
          "(+0x01)" % pay(0)[0x0C],
          {k: v for k, v in diffA.items() if v} == {0: [0x0C], 9: [0x01]})
    diffB = [k for k in range(32) if pay(0x20 + k) != pay(0x20)]
    check("  the 32 second halves (ids 0x20-0x3F) are identical but for part 9's (id 0x29)",
          diffB == [9])
    check("effect blocks: ids 0x61/0x62/0x63 byte 0 (algorithm) = 1, 35, 20",
          [pay(i)[0] for i in (0x61, 0x62, 0x63)] == [1, 35, 20])
    return dict(recs=recs, by_id=by_id, ram=ram, ids13=ids13)


def name_of(i):
    if i < 0x20:
        return "Default_Part%02d_A" % i
    if i < 0x40:
        return "Default_Part%02d_B" % (i - 0x20)
    if i in (0x61, 0x62, 0x63):
        return "Default_DspEffect%d" % (i - 0x60)
    return "Default_Record%02X" % i


def header(i, p, n, ram, ids13):
    if i < 0x40:
        k = i & 0x1F
        who = ("sub_FAAE2A copies it via PtrTable_FAD28A[0x%02X]%s" %
               (i, "; sub_FAA967 bytes 0x0D-0x15" if i < 0x20 else ""))
        what = ("part %d, first half; +0x0D (channel) = %d" % (k, k) if i < 0x20 else
                "part %d, second half (id 0x%02X + 0x20)" % (k, k))
    else:
        j = ids13.index(i)
        who = "sub_FAAF91 copies it via PtrTable_FAD397[%d]" % j
        what = {0x61: "DSP effect block 1, algorithm 1", 0x62: "DSP effect block 2, algorithm 35",
                0x63: "DSP effect block 3, algorithm 20"}.get(i, "record 0x%02X" % i)
    import textwrap
    what = "" if what.startswith("record ") else ": " + what
    return textwrap.wrap("%s -- id 0x%02X, %d bytes, the factory default of RAM 0x%04X "
                         "(ParamNumber_RecordPtrs[0x%02X])%s; prom_a %s."
                         % (name_of(i), i, n, ram[i], i, what, who),
                         width=78, initial_indent="; ", subsequent_indent=";   ")


BANNER = r"""; ==============================================================================
; ⚠ WHAT THE RECORDS ARE (2026-09-25): the FACTORY DEFAULTS of the parameter
; records.  Each `[id, len, payload]` is copied, payload byte H to record byte
; H, into the RAM record ParamNumber_RecordPtrs (prom_a 0xFACDEA, the table
; (0x60F018) points at) gives for its id -- by prom_a sub_FAAE2A (routine slot
; T_F43440; ids 0x00-0x3F, through PtrTable_FAD28A), sub_FAAF91 (T_F43444; the
; 13 others, through ByteTable_FAD38A + PtrTable_FAD397, then ids 0x61-0x63 on
; to sub_F114DA via T_F42F58) and sub_FAA967 (T_F4077C; bytes 0x0D-0x15 of ids
; 0x00-0x1F).  Ids 0x00-0x1F / 0x20-0x3F are the two halves of the 32 PART
; records (prom_a's ParamNumber_RecordPtrs header): part k's channel byte
; (+0x0D) defaults to k.  The first halves are otherwise identical except part
; 0 (+0x0C = 0x08, all others 0x00) and part 9 -- channel 10 -- (+0x01 = 0x20);
; the second halves except part 9's (+0x19, +0x1C, +0x1D).  Ids 0x61-0x63 are the three DSP effect blocks (IndexedTable entries
; 97-99), defaulting to algorithms 1, 35 and 20.  What the other 11 ids hold is
; for their readers to say.  notes/promb-2026-09-25/factory_default_records.py.
; =============================================================================="""


def apply(d):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    ren = {}
    for p, i, n in d["recs"]:
        old = "Rec_%06X" % p
        k = [x for x, t in enumerate(L) if t == old + ":"]
        assert len(k) == 1, old
        k = k[0]
        L[k:k] = header(i, p, n, d["ram"], d["ids13"])
        ren[old] = name_of(i)
    b = [x for x, t in enumerate(L) if t.startswith("; Full proof: notes/gen_prom_b_f3f400_module.py.")]
    assert len(b) == 1
    L[b[0] + 2:b[0] + 2] = [x.encode("utf-8").decode("latin-1") for x in BANNER.split("\n")]
    txt = "\n".join(L)
    for o, nn in ren.items():
        txt = re.sub(r'\b%s\b' % o, nn, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    with open(os.path.join(HERE, "factory_default_records.map"), "w") as f:
        f.write("".join("%s=%s\n" % kv for kv in ren.items()))
    print("wrote", SRC, "and factory_default_records.map (%d renames)" % len(ren))


def main():
    d = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
