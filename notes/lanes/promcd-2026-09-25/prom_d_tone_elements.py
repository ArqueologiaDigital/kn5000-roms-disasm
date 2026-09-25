#!/usr/bin/env python3
r"""Which wave does each element of each melodic tone record play?

QUESTION THIS ANSWERS
    wsa1/prom_d/tone_database_records.s frames 451 81-byte ELEMENT BLOCKS
    (`ToneRec_<n>_<Name>_Elem<k>`) and 451 43-byte WAVE-SELECT RECORDS
    (`..._WaveSel<k>`) under names and nothing else.  This script establishes,
    per object, (a) that the object sits exactly where prom_c's locator puts
    it, (b) which wave the element plays -- its selector pair +0x02/+0x03
    resolved through the index maps to a named wave-catalogue row -- and (c)
    whether the wave-select record is that wave's default record, and with
    --apply writes one short header above each of the 902 labels.

EVIDENCE CHAIN (every link has its own proof; nothing here is new code reading)
    locators   ToneRec_GetElementBlock (prom_c 0xFB4324): record + 0xD9 + 81*k,
               `ld C,0x51` 0xFB436D / `add XBC,0x000000d9` 0xFB4373;
               ToneRec_GetWaveSelectRecord (prom_c 0xFB43CB): record + 0xD9 +
               81*N + 43*k, `ld A,0x2b` 0xFB4439 and the 81*N arms 0x51/0xA2/
               0xF3/0x144 (0xFB443F, 0xFB445C, 0xFB4479, 0xFB4496).  Both pack
               k through the element mask at +0x11 (ToneRec_MapElementIndex_ByMask).
    selector   element +0x02/+0x03 = (sel_program, sel_bank_family): prom_c
               0xFB9150/0xFB9173 store a catalogue row's bytes 14/15 there, and
               0xFB918E-0xFB919D push the pair into ToneDB_ResolveWaveSelectRecord
               (wsa1/prom_d/wsa1_prom_d.s, wave-17 block).
    names      the name maps are exact inverses of the catalogues
               (notes/lanes/promcd-2026-09-25/prom_d_index_maps.py T2), so the
               row returned carries the element's own selector: asserted here
               for all 451.
    default    ToneDB_ResolveWaveSelectRecord's record for the selector is the
               wave's default wave-select record; compared here with the tone's
               own record, byte +0x0B (tail preset, rewritten by prom_c) excluded.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_tone_elements.py          # checks
    python3 notes/lanes/promcd-2026-09-25/prom_d_tone_elements.py --apply  # + edit
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
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(W, "prom_d", "tone_database_records.s")
AUX = os.path.join(W, "prom_d", "tone_database_aux.s")
u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
S = u32
MAP = {s: [u16(S(s) + 2 * i) for i in range(1024)] for s in (0x0C, 0x10, 0x44, 0x48, 0x58, 0x5C)}
PTR = [u32(0xB80 + 4 * i) for i in range(274)]

CODE = [(0xFB436D, "23 51"), (0xFB4373, "e9 c8 d9 00 00 00"), (0xFB4439, "21 2b"),
        (0xFB443F, "e8 c8 51 00 00 00"), (0xFB445C, "e8 c8 a2 00 00 00"),
        (0xFB4479, "e8 c8 f3 00 00 00"), (0xFB4496, "e8 c8 44 01 00 00"),
        (0xFB433D, "89 11 21")]


def row(slot, i):
    b = S(slot)
    return D[b + 16 * i:b + 16 * i + 16]


def name(r):
    return r[:13].decode("latin-1").rstrip()


def nelem(p):
    return sum(1 for k in range(4) if (D[p + 0x11] >> (2 * k)) & 3)


def mixer_labels():
    lab = {}
    for ln in open(AUX, encoding="latin-1"):
        m = re.match(r"^(ToneDB_MixerDefaultTable_(\d{3})\w*):", ln)
        if m:
            lab[int(m.group(2))] = m.group(1)
    assert len(lab) == 322
    return lab


def facts():
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        got = C[a - 0xF80000:a - 0xF80000 + len(want)]
        assert got == want, "prom_c 0x%06X: %s, want %s" % (a, got.hex(" "), enc)
    lab = mixer_labels()
    out = {}                       # file offset -> (kind, text lines)
    stats = collections.Counter()
    for p in sorted(set(PTR)):
        if D[p + 0x10] in (0x80, 0x71):
            continue               # drum kits and drawbar records live in aux
        N = nelem(p)
        for k in range(N):
            e = p + 0xD9 + 81 * k
            w = p + 0xD9 + 81 * N + 43 * k
            sp, sf = D[e + 2], D[e + 3]
            i = (sf & 0x0F) * 128 + (sp & 0x7F)
            f = sf & 0xC0
            m1, m2, mw = ((0x48, 0x5C, 0x10) if f == 0x80 else (0x44, 0x58, 0x0C))
            assert f in (0x00, 0x80) and not sf & 0x30
            r1, r2 = MAP[m1][i], MAP[m2][i]
            a1, a2 = row(0x50, r1), row(0x64, r2)
            assert a1[14:16] == bytes([sp, sf]), (hex(p), k)
            n1, n2 = name(a1), name(a2)
            if a2[14:16] != bytes([sp, sf]):
                wave = "'%s' (ToneDB_SourceNameList1 row %d; not in List2)" % (n1, r1)
                stats["absent-from-list2"] += 1
            elif n1 == n2:
                wave = "'%s' (ToneDB_SourceNameList1 row %d)" % (n1, r1)
                stats["same-name"] += 1
            else:
                wave = "'%s' / '%s' (ToneDB_SourceNameList1 row %d / List2 row %d)" % (n1, n2, r1, r2)
                stats["list2-finer"] += 1
            out[e] = ("Elem", k, [
                "; element %d of %d: record + 0xD9 + 81*%d, ToneRec_GetElementBlock (prom_c 0xFB4324)." % (k, N, k),
                "; Plays wave %s: selector +0x02/+0x03 = 0x%02X/0x%02X," % (wave, sp, sf),
                "; bank %d program %d, through ToneDB_%s (+0x%02X)."
                % (sf & 0x0F, sp & 0x7F, "SourceIndexMapB" if f == 0x80 else "SourceIndexMapA", m1)])
            n = MAP[mw][i]
            a = S(0x18) + 43 * n
            diff = [j for j in range(43) if D[a + j] != D[w + j] and j != 11]
            if not diff:
                how = "equals its wave's default record %s in every byte but +0x0B" % lab[n]
                stats["default"] += 1
            else:
                how = "differs from its wave's default record %s in %d of the 42 bytes other than +0x0B" % (lab[n], len(diff))
                stats["edited"] += 1
            out[w] = ("WaveSel", k, [
                "; wave-select record %d of %d: record + 0xD9 + 81*%d + 43*%d, ToneRec_GetWaveSelectRecord" % (k, N, N, k),
                "; (prom_c 0xFB43CB).  Element %d's selector resolves (ToneDB_ResolveWaveSelectRecord," % k,
                "; +0x%02X) to record %d; this one %s." % (mw, n, how)])
    return out, stats


OLD_FIELDS = ("; \u26a0 NOT established: the meaning of any field inside the head, the element\n"
              "; block or the wave-select record.  Round 3 reads a consumer's ADDRESS\n"
              "; arithmetic; it does not read a field.\n")
NEW_FIELDS = ("; \u26a0 CORRECTED 2026-09-25 (lane promcd).  This paragraph said no field\n"
              "; meaning inside the head, the element block or the wave-select record was\n"
              "; known, and that round 3 read address arithmetic only.  Readers have since\n"
              "; named a few.  prom_d/wsa1_prom_d.s's wave-17 block lists, with the\n"
              "; instruction for each: head +0x010 kind, +0x011 element mask, +0x0D0\n"
              "; dsp_algo, +0x0D1..+0x0D8 dsp_param; element +0x02/+0x03 the WAVE SELECTOR\n"
              "; (resolved per element below) and +0x4D..+0x50; wave-select +0x0B the tail\n"
              "; preset.  prom_c/voice/note_engine.s adds wave-select +0x03..+0x0A: four\n"
              "; envelope selector pairs, read by WaveSelRec_ResolveEnvDescriptor (prom_c\n"
              "; 0xFB474E) into ToneDB_ResolveEnvDescriptor (0xFB45C0).  Most other bytes\n"
              "; still carry no name.\n")


OLD_COMMON = ";     +0x012 199 B   common part, fields unidentified\n"
NEW_COMMON = (";     +0x012 199 B   common part; its last nine bytes, +0x0D0 dsp_algo and\n"
              ";                    +0x0D1..+0x0D8 dsp_param, are named by readers (see the\n"
              ";                    CORRECTED paragraph below); the rest carry no name yet\n")


def wrap(text):
    """Re-flow a header's sentences into comment lines of at most 92 columns."""
    import textwrap
    body = " ".join(t[2:] for t in text)
    return ["; " + x for x in textwrap.wrap(body, 90, break_long_words=False,
                                            break_on_hyphens=False)]


def apply(out):
    lines = open(SRC, "rb").read().decode("utf-8").split("\n")
    if any("ToneRec_GetElementBlock (prom_c 0xFB4324)." in ln for ln in lines):
        sys.exit("already applied")
    res, done = [], 0
    for idx, ln in enumerate(lines):
        m = re.match(r"^ToneRec_[0-9A-F]{3}_\w+_(Elem|WaveSel)(\d):$", ln)
        if m:
            nxt = lines[idx + 1]
            off = int(re.search(r";\s*([0-9A-F]{5})\b", nxt).group(1), 16)
            kind, k, text = out[off]
            assert kind == m.group(1) and k == int(m.group(2)), (ln, kind, k)
            res.extend(wrap(text))
            done += 1
        res.append(ln)
    assert done == len(out), (done, len(out))
    txt = "\n".join(res)
    assert txt.count(OLD_FIELDS) == 1
    txt = txt.replace(OLD_FIELDS, NEW_FIELDS)
    assert txt.count(OLD_COMMON) == 1
    txt = txt.replace(OLD_COMMON, NEW_COMMON)
    open(SRC, "wb").write(txt.encode("utf-8"))
    print("applied: %d object headers" % done)


if __name__ == "__main__":
    out, stats = facts()
    print("  %d objects: %s" % (len(out), dict(stats)))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply(out)
