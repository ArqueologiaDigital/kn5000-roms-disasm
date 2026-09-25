#!/usr/bin/env python3
r"""Name every P7 directory record, field array and stream by the DSP EFFECT it belongs to.

QUESTION THIS ANSWERS
    notes/prom_c_p7_program_is_effect.py established that a P7 unit's PROGRAM
    0..127 is a DSP effect number: PoolDir_RecordForUnitProgram (prom_c
    0xFDC551) maps program -> PoolDir_Records index, prom_b's EffectNames_F147AC
    (0xF147AC, 128 x 16) names the program, and the 56 real names map onto 56
    distinct records.  prom_c/p7/p7_stream_pool.s nevertheless labels the 56
    records, their 56 field-descriptor arrays and their 224 streams by address
    only.  This script carries the effect name down to each of them, and marks
    the streams NO record points at.

    * PoolDir_Records[r]: its four pointers are four CONSECUTIVE streams in all
      56 records (asserted) -- +0 block A, +4 stream A, +8 block B, +12 stream B
      (the PoolDirRecord struct at the top of the file: +0/+8 are what
      P7Block_Run walks, +4/+12 what P7Stream_Run plays).
    * PoolDir_FieldRec_PtrTable[r] (0xFDD1CB, "slot k belongs with
      PoolDir_Records[k]") -> record r's 7-byte field descriptors, read by
      P7Unit_EmitChangedParams, P7Unit_SendFieldParamZero and sub_FA2784.
    * streams that no PoolDir record, no `.long`, and no instruction operand
      names, and whose address is found as no LE24/LE32 word in prom_c, no LE32
      word in prom_a/prom_b, and no pool-relative LE16: stated as unreferenced,
      with the quartet shape they share with the directory's sets.

RUN
    python3 notes/lanes/promcd-2026-09-25/p7_effect_names.py [--apply]
"""
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
A = open(os.path.join(W, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(W, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(W, "prom_c", "p7", "p7_stream_pool.s")
PROG, NAMES, DIRR, FPTR, POOL0, POOL1 = 0xFDC551, 0xF147AC, 0xFDBFD9, 0xFDD1CB, 0xFCD0F7, 0xFDD2AB
ROLE = {0: "block A (+0, walked by P7Block_Run)", 4: "stream A (+4, played by P7Stream_Run)",
        8: "block B (+8, walked by P7Block_Run)", 12: "stream B (+12, played by P7Stream_Run)"}


def c(a, n):
    return C[a - 0xF80000:a - 0xF80000 + n]


def facts():
    names = [B[NAMES - 0xF00000 + 16 * k:NAMES - 0xF00000 + 16 * k + 16].decode("latin-1").strip()
             for k in range(128)]
    prog = list(c(PROG, 128))
    eff = collections.defaultdict(list)
    for k in range(128):
        if not names[k].startswith("---"):
            eff[prog[k]].append((k, names[k]))
    assert len(eff) == 56 and all(len(v) == 1 for v in eff.values()), "not a bijection"
    streams, heads = [], []
    for ln in open(SRC, encoding="latin-1"):
        m = re.match(r"; ---- 0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+\d+ bytes, \d+ records\s+\[(.*?)\]", ln)
        if m:
            streams.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3)))
    starts = [s[0] for s in streams]
    role = {}
    for r in range(56):
        p = struct.unpack("<4I", c(DIRR + 25 * r, 16))
        n0 = starts.index(p[0])
        assert [starts.index(x) for x in p] == [n0, n0 + 1, n0 + 2, n0 + 3], r
        for f, x in zip((0, 4, 8, 12), p):
            role.setdefault(x, []).append((r, f))
    fptr = [struct.unpack("<I", c(FPTR + 4 * r, 4))[0] for r in range(56)]
    # unreferenced streams
    orphan = {}
    for a, b, kind in streams:
        if a in role:
            continue
        found = False
        # prom_c (which plays the streams) may hold a 24- or 32-bit address; prom_a
        # and prom_b could only reach prom_c's space over the link, with a full
        # 32-bit remote address (as their reads of the preset bank are spelled)
        for img, widths in ((A, (4,)), (B, (4,)), (C, (3, 4))):
            for w in widths:
                if a.to_bytes(4, "little")[:w] in img:
                    found = True
        if (a - POOL0).to_bytes(2, "little") in c(POOL0, POOL1 - POOL0):
            found = True
        orphan[a] = (b - a + 1, kind, found)
    return names, prog, eff, role, fptr, orphan, streams


def effect_of(eff, r):
    k, nm = eff[r][0]
    return "'%s' (program %d)" % (nm, k)


def apply(names, prog, eff, role, fptr, orphan, streams):
    lines = open(SRC, "rb").read().decode("latin-1").split("\n")
    if any("effect record" in ln and "PoolDir_FieldRec_PtrTable[" in ln for ln in lines):
        sys.exit("already applied")
    # which labelled references exist anywhere in prom_c (symbolic operands, .long)
    refs = set()
    for dp, _, fn in os.walk(os.path.join(W, "prom_c")):
        for f in fn:
            if f.endswith(".s"):
                for ln in open(os.path.join(dp, f), encoding="latin-1"):
                    code = re.sub(r"^[\w.$]+:", "", ln.split(";")[0])
                    refs.update(re.findall(r"\bP7Stream_[0-9A-F]{6}\b", code))
    quart = collections.defaultdict(list)
    orph_sorted = sorted(orphan)
    out, n_rec, n_fld, n_str, n_orph = [], 0, 0, 0, 0
    cur_head = None
    for ln in lines:
        m = re.match(r"; ---- 0x([0-9A-F]{6})-", ln)
        if m:
            cur_head = int(m.group(1), 16)
        lab = re.match(r"^(P7Stream_([0-9A-F]{6})):$", ln)
        if lab and int(lab.group(2), 16) == cur_head:
            a = cur_head
            if a in role:
                for r, f in role[a]:
                    out.append(";      effect %s: PoolDir_Records[%d] %s" % (effect_of(eff, r), r, ROLE[f]))
                    n_str += 1
            elif a in orphan and lab.group(1) not in refs:
                size, kind, found = orphan[a]
                if not found:
                    i = orph_sorted.index(a)
                    out.append(";      ⚠ UNREFERENCED (lane promcd, 2026-09-25): no reader of this stream has been"
                               .encode("utf-8").decode("latin-1"))
                    out.append(";      found.  No PoolDir record points at it, no `.long` or instruction operand in")
                    out.append(";      prom_c names it, and its address occurs as no LE24/LE32 word in prom_c, no LE32")
                    out.append(";      word in prom_a or prom_b, and no pool-relative LE16 (notes/lanes/promcd-2026-09-25/")
                    import textwrap
                    body = "p7_effect_names.py).  " + quartet_note(a, orphan, streams)
                    out.extend(";      " + x for x in textwrap.wrap(body, 84, break_on_hyphens=False))
                    n_orph += 1
        m = re.match(r"^\t; record\s+(\d+)\s+0x([0-9A-F]{6})$", ln)
        out.append(ln)
        if m:
            r = int(m.group(1))
            ks = [k for k in range(128) if prog[k] == r]
            out.append("\t;   effect %s -- PoolDir_RecordForUnitProgram[%d] = %d, name from prom_b EffectNames_F147AC[%d]"
                       % (effect_of(eff, r), eff[r][0][0], r, eff[r][0][0])
                       + ("; also the catch-all of %d unnamed programs" % (len(ks) - 1) if len(ks) > 1 else ""))
            n_rec += 1
        m = re.match(r"^; 0x([0-9A-F]{6})\s+\d+ bytes = \d+ x 7\s+\(table slot\(s\) \[([\d, ]+)\]\)$", ln)
        if m:
            a = int(m.group(1), 16)
            slots = [int(x) for x in m.group(2).split(",")]
            assert all(fptr[s] == a for s in slots), (hex(a), slots)
            for s in slots:
                out.append("; field descriptors of effect record %d %s: PoolDir_FieldRec_PtrTable[%d] (0xFDD1CB +"
                           " 4*%d), read by P7Unit_EmitChangedParams, P7Unit_SendFieldParamZero, sub_FA2784"
                           % (s, effect_of(eff, s), s, s))
                n_fld += 1
    data = "\n".join(out).encode("latin-1")      # encode BEFORE opening: a failed encode must not truncate
    open(SRC, "wb").write(data)
    print("applied: %d record lines, %d field-array lines, %d stream lines, %d unreferenced" %
          (n_rec, n_fld, n_str, n_orph))


def quartet_note(a, orphan, streams):
    starts = [s[0] for s in streams]
    i = starts.index(a)
    for q0 in range(i - 3, i + 1):
        if q0 < 0 or q0 + 4 > len(streams):
            continue
        q = streams[q0:q0 + 4]
        if all(s[0] in orphan for s in q) and [s[2].startswith("NOT") for s in q] == [True, False, True, False]:
            pos = i - q0
            return ("It is member %d of 4 of an orphan quartet at 0x%06X (block, stream, block, stream -- NOT"
                    "/clean/NOT/clean, the shape of every PoolDir_Records set), so it reads as an effect's"
                    " stream set with no directory record." % (pos, q[0][0]))
    return "It is not part of such a quartet."


if __name__ == "__main__":
    names, prog, eff, role, fptr, orphan, streams = facts()
    unref = [a for a, v in orphan.items() if not v[2]]
    print("  56 records <-> 56 effect names; %d streams pointed at by the directory; %d not, of which %d"
          " have no address word anywhere" % (len(role), len(orphan), len(unref)))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(names, prog, eff, role, fptr, orphan, streams)
