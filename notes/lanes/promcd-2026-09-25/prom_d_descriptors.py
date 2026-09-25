#!/usr/bin/env python3
r"""Which wave reaches each 14-byte descriptor at prom_d slots +0x30 and +0x38?

QUESTION THIS ANSWERS
    ToneDB_EnvDescTable (+0x30, 318 descriptors) and ToneDB_EnvDescTable_Perc
    (+0x38, 161) frame every 14-byte descriptor under a numbered label and a
    `tag A= B=` comment, and their banners still said "no prom_c instruction
    that reads THIS block has been found".  The reader is
    ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0): it returns
        base + dir[+0x30 | +0x34 | +0x38] + 14 * map[i]
    with map = ToneDB_ToneIndexMapC (+0x24, family 0x00/0xC0), ToneIndexMapD
    (+0x28, family 0x80) or DrumToneIndexMap (+0x2C, family 0x40), i the wave
    selector key (notes/lanes/promcd-2026-09-25/prom_d_index_maps.py).  Its
    selector pairs come from a wave-select record's +0x03..+0x0A
    (WaveSelRec_ResolveEnvDescriptor 0xFB474E), and 1,776 of the 1,804 such
    pairs in the melodic tone records are selectors of a wave-catalogue row
    (1,739 equal the element's own selector) -- measured here.

    So a descriptor is named by the catalogue waves whose selector reaches it.
    This script computes that per descriptor, and --apply writes one header
    above each descriptor label plus the banner corrections.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_descriptors.py          # checks
    python3 notes/lanes/promcd-2026-09-25/prom_d_descriptors.py --apply  # + edit
    PASS = "ALL CHECKS HOLD".
"""
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
D = open(os.path.join(W, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
SRC = os.path.join(W, "prom_d", "tone_database_aux.s")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
S = u32
M = {s: [u16(S(s) + 2 * i) for i in range(1024)] for s in (0x24, 0x28, 0x2C)}
PTR = [u32(0xB80 + 4 * i) for i in range(274)]


def rows(slot, n):
    b = S(slot)
    return [D[b + 16 * i:b + 16 * i + 16] for i in range(n)]


def key(r):
    return (r[15] & 0x0F) * 128 + (r[14] & 0x7F)


def nm(r):
    return r[:13].decode("latin-1").strip()


def pairs_census():
    cat = {(r[14], r[15]) for r in rows(0x50, 307)}
    inc = eq = tot = 0
    for p in sorted(set(PTR)):
        if D[p + 0x10] in (0x80, 0x71):
            continue
        N = sum(1 for k in range(4) if (D[p + 0x11] >> (2 * k)) & 3)
        for k in range(N):
            e = p + 0xD9 + 81 * k
            w = p + 0xD9 + 81 * N + 43 * k
            for j in range(4):
                pr = (D[w + 3 + 2 * j], D[w + 4 + 2 * j])
                tot += 1
                inc += pr in cat
                eq += pr == (D[e + 2], D[e + 3])
    return inc, eq, tot


def waves():
    mel = collections.defaultdict(list)
    for r in rows(0x50, 307):
        m = M[0x28] if r[15] & 0xC0 == 0x80 else M[0x24]
        mel[m[key(r)]].append(nm(r))
    ent = collections.Counter(M[0x24] + M[0x28])
    perc = collections.defaultdict(list)
    for r in rows(0x94, 161) + rows(0x8C, 208):
        x = nm(r)
        n = M[0x2C][key(r)]
        if x not in perc[n]:
            perc[n].append(x)
    pent = collections.Counter(M[0x2C])
    return mel, ent, perc, pent


def fmt(names):
    q = ["'%s'" % x for x in names[:4]]
    return ", ".join(q) + (" and %d more" % (len(names) - 4) if len(names) > 4 else "")


def entries(k):
    return "the only map entry holding it" if k == 1 else "%d map entries hold it" % k


def headers():
    mel, ent, perc, pent = waves()
    out = {}
    for n in range(318):
        t = ["; descriptor %d = base + dir[+0x30] + 14*%d, returned by ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0)." % (n, n)]
        if mel[n]:
            t.append("; Reached through ToneDB_ToneIndexMapC/D by the selector of wave %s (%s)."
                     % (fmt(mel[n]), entries(ent[n])))
        elif ent[n]:
            t.append("; %d entries of ToneDB_ToneIndexMapC/D hold %d; none is the selector of a ToneDB_SourceNameList1 wave." % (ent[n], n))
        else:
            t.append("; No entry of ToneDB_ToneIndexMapC or D holds %d, so no selector reaches it through them." % n)
        out[("ToneDB_EnvDescTable_Desc%03d" % n)] = t
    for n in range(161):
        t = ["; descriptor %d = base + dir[+0x38] + 14*%d, returned by ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0)." % (n, n)]
        assert perc[n], n
        t.append("; Reached through ToneDB_DrumToneIndexMap by the selector of drum wave %s (%s)."
                 % (fmt(perc[n]), entries(pent[n])))
        out[("ToneDB_EnvDescTable_Perc_Desc%03d" % n)] = t
    return out, mel, ent, perc


OLD_NOREAD = ("; ⚠ And no prom_c instruction that reads THIS block has been found; the Evidence\n"
              "; note below states what that leaves standing and what it does not.\n")
NEW_NOREAD = ("; ★ CORRECTED 2026-09-25 (lane promcd): this block IS read -- by\n"
              "; ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0), see the reader paragraph at\n"
              "; the end of this banner; each descriptor below names the waves that reach it.\n")


def old_none(slot):
    return ("; ⚠ Readers: NONE IN THE CENSUS.  notes/prom_d_documentation_round3.py\n"
            "; walks every load of prom_d's base (0x00F00000, RAM 0x00D7ED /\n"
            "; 0x00D7F1) in prom_c and every directory slot read through it -- 99\n"
            "; reads over 33 slots -- and directory slot +0x%02X is not among them.\n"
            "; The census is a LOWER BOUND: by its own rule it does not follow a\n"
            "; base parked in a frame slot.\n" % slot)


def new_none(slot):
    return ("; Round 3's base-load census (notes/prom_d_documentation_round3.py, 99\n"
            "; reads over 33 slots) did not list directory slot +0x%02X: it does not\n"
            "; follow a base parked in a frame slot, which is what the reader does.\n" % slot)


def old_nofound(stride, sites):
    return ("; ⚠ No reader was found for THIS block.  What round 3 adds is indirect and\n"
            "; is stated as such: the stride word this block uses (directory +0x%02X = 14)\n"
            "; IS read by prom_c -- at %s -- and at 0xFC299A the SAME stride word is\n"
            "; multiplied by a record index to walk the descriptor array at slot +0x70,\n"
            "; which is the same record class.  That corroborates the 14-byte array; it\n"
            "; does NOT show anything reading this block, and the label stays a KN5000\n"
            "; transplant on that basis.\n" % (stride, sites))


def new_nofound(stride, sites):
    return ("; Round 3's indirect evidence stands: the stride word this block uses\n"
            "; (directory +0x%02X = 14) is read by prom_c at %s, and at\n"
            "; 0xFC299A the same stride word walks the descriptor array at slot +0x70.\n"
            "; The DIRECT reader is the one above (corrected 2026-09-25, lane promcd:\n"
            "; this paragraph said none had been found and kept the name a transplant).\n"
            % (stride, sites))


def wrap(text):
    import textwrap
    body = " ".join(t[2:] for t in text)
    return ["; " + x for x in textwrap.wrap(body, 90, break_long_words=False,
                                            break_on_hyphens=False)]


def apply(out):
    src = open(SRC, "rb").read().decode("utf-8")
    if "returned by ToneDB_ResolveEnvDescriptor (prom_c 0xFB45C0)." in src:
        sys.exit("already applied")
    for head, slot, stride, sites in (("; ToneDB_EnvDescTable -- directory slot +0x30\n", 0x30, 0xEC,
                                       "0xFB4679, 0xFB46C4, 0xFC299A"),
                                      ("; ToneDB_EnvDescTable_Perc -- directory slot +0x38\n", 0x38, 0xF2,
                                       "0xFB469D")):
        a = src.index(head)
        z = src.index("\n; " + "=" * 74 + "\n", a + len(head) + 200)
        ban = src[a:z + 1]
        for old, new in ((OLD_NOREAD, NEW_NOREAD), (old_none(slot), new_none(slot)),
                         (old_nofound(stride, sites), new_nofound(stride, sites))):
            assert ban.count(old) == 1, (hex(slot), old[:60])
            ban = ban.replace(old, new)
        src = src[:a] + ban + src[z + 1:]
    lines = src.split("\n")
    res, done = [], 0
    for ln in lines:
        m = re.match(r"^(ToneDB_EnvDescTable(?:_Perc)?_Desc\d{3}):", ln)
        if m:
            res.extend(wrap(out[m.group(1)]))
            done += 1
        res.append(ln)
    assert done == len(out), (done, len(out))
    open(SRC, "wb").write("\n".join(res).encode("utf-8"))
    print("applied: 2 banners, %d descriptor headers" % done)


if __name__ == "__main__":
    inc, eq, tot = pairs_census()
    print("  wave-select +0x03..+0x0A pairs in melodic tone records: %d, catalogue selectors %d, "
          "equal to the element's own selector %d" % (tot, inc, eq))
    assert (tot, inc, eq) == (1804, 1776, 1739)
    out, mel, ent, perc = headers()
    print("  +0x30: %d of 318 descriptors named by a wave, %d reached by some map entry"
          % (sum(1 for n in range(318) if mel[n]), sum(1 for n in range(318) if ent[n])))
    print("  +0x38: %d of 161 named by a drum wave" % sum(1 for n in range(161) if perc[n]))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(out)
