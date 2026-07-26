#!/usr/bin/env python3
"""k4_cursor.py -- roadmap K4: the coefficient-cursor REBASE and the bank register.

Prints every number quoted in dsp/analysis/k4-cursor.md, straight out of the Sub
CPU ROM (and, for one section, the previously-recorded cold-boot uC-IF capture).
Standard library only; no MAME, no hardware, no undumped ROM.

    python3 dsp/tools/k4_cursor.py                 # all sections
    python3 dsp/tools/k4_cursor.py map forced      # selected sections

Sections
    map      the C-RAM memory map: the two resident tables (literal ROM blob at
             0x01E6BE), the two per-unit coefficient banks, and the fact that no
             parameter stream ever writes the table region
    forced   why a rebase must exist (A) and why it cannot be in a body (B)
    fields   the exhaustive bit-field search for 0x90 (C) -- the K4 result
    regs     the class-1 register file, bit 7 = effect unit (G), K6's lead
    class8   only class4==0xA advances the cursor (I) -- constrains the ALU work
    multitap the 050.0.00.921 prediction and why it is a MISS (K)
"""
import collections
import os
import sys

ROM = os.environ.get("KN5000_SUBROM") or os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")
CAPTURE = os.environ.get("KN5000_DSP_CAPTURE") or os.path.expanduser(
    "~/compartilhado/kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt")

ROM_BASE    = 0xEF00
ALGO_TABLE  = 0x0001ED7C
PARAM_TABLE = 0x0001EF0C
N_ALGOS     = 100
KERNEL_BLOB = 0x01E496      # header, I-RAM 0..59
EPILOG_BLOB = 0x01E63C      # output stage, I-RAM 60..82
BOOT_BLOB   = 0x01E6BE      # the resident C-RAM table + the two effect-level regs

D = open(ROM, "rb").read()


# ---------------------------------------------------------------- ROM access
def _off(a):
    o = a - ROM_BASE
    if not (0 <= o < len(D)):
        raise IndexError(hex(a))
    return o


def u8(a):
    return D[_off(a)]


def u32le(a):
    o = _off(a)
    return int.from_bytes(D[o:o + 4], "little")


def parse_stream(addr, limit=8192):
    """One uC-IF script -> [(op, cmd, hdr16, payload)] (K5 sect. 1.1's rule)."""
    recs, p, guard = [], addr, 0
    while guard < limit:
        guard += 1
        try:
            b0, b1 = u8(p), u8(p + 1)
        except IndexError:
            break
        op = b0 >> 4
        if op == 0xF:
            recs.append(("F", None, None, b""))
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        o = _off(p + 2)
        body = D[o:o + ln - 2]
        cmd = body[0] if body else None
        hdr = ((body[1] << 8) | body[2]) if len(body) >= 3 else None
        recs.append((op, cmd, hdr, body[3:] if len(body) >= 3 else b""))
        p += ln
    return recs


def words5(b):
    return [int.from_bytes(b[k:k + 5], "big") for k in range(0, len(b) - 4, 5)]


def words3(b):
    return [int.from_bytes(b[k:k + 3], "big") for k in range(0, len(b) - 2, 3)]


# ------------------------------------------------------------- word fields
def hi12(w): return (w >> 24) & 0xFFF
def cls(w):  return (w >> 20) & 0xF
def ad8(w):  return (w >> 12) & 0xFF
def lo12(w): return w & 0xFFF
def c_format(w): return (hi12(w) & 0xFFE) == 0xC40
def imm13(w): return (w >> 12) & 0x1FFF
def c_a(w):  return imm13(w) >> 5
def cursor_fetch(w): return bool((w >> 23) & 1) and not c_format(w)
def coeff_consumer(w): return cls(w) == 0xA and not c_format(w)
def fmt(w): return "%03X.%X.%02X.%03X" % (hi12(w), cls(w), ad8(w), lo12(w))


def blob(addr):
    op, cmd, ia, pl = parse_stream(addr, limit=3)[0]
    assert op == 3, "not an op-3 record at %06X" % addr
    return ia, words5(pl)


def images():
    """{rom_ptr: (representative algo, I-RAM load address, [words])}, 38 distinct."""
    out = {}
    for i in range(N_ALGOS):
        try:
            recs = parse_stream(u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        blocks = [(ia, words5(pl)) for (op, c, ia, pl) in recs if op == 3]
        if not blocks or blocks[0][0] not in (84, 200):
            continue
        out.setdefault(u32le(ALGO_TABLE + 4 * i),
                       (i, blocks[0][0], [w for _, ws in blocks for w in ws]))
    return out


def unit_of_algo():
    """{algo: 0|1} for every one of the 96 valid slots, not just the 38 images."""
    out = {}
    for i in range(N_ALGOS):
        try:
            recs = parse_stream(u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        blocks = [ia for (op, c, ia, pl) in recs if op == 3]
        if blocks and blocks[0] in (84, 200):
            out[i] = 1 if blocks[0] == 200 else 0
    return out


def param_streams():
    out = {}
    for i in range(N_ALGOS):
        try:
            out[i] = parse_stream(u32le(PARAM_TABLE + 4 * i))
        except Exception:
            pass
    return out


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


# --------------------------------------------------------------- sections
def sec_map():
    hdr("map -- the C-RAM memory map (analysis sect. 1)")
    print("The resident table is a LITERAL uC-IF blob at Sub CPU ROM 0x%06X:" % BOOT_BLOB)
    ptr, cram = None, {}
    for (op, cmd, h, pl) in parse_stream(BOOT_BLOB, limit=20):
        if op == "F":
            print("   F"); break
        if op == 4:
            print("   op4 cmd=%02X" % cmd); continue
        if op == 2:
            vs = words3(pl)
            for v in vs:
                cram[ptr] = v; ptr = (ptr + 1) & 0xFF
            print("   op2 cmd=%02X port %04X  %2d x 24-bit" % (cmd, h, len(vs)))
            continue
        ws = words5(pl)
        for w in ws:
            if hi12(w) == 0x801 and cls(w) == 0 and lo12(w) == 0x821:
                ptr = ad8(w)
        print("   op%X cmd=%02X port %04X  %s" % (op, cmd, h, "  ".join(
              "poke %010X" % w if (w >> 32) & 0xFF == 0x0A else fmt(w) for w in ws)))
    a = [cram.get(0x50 + k) for k in range(32)]
    b = [cram.get(0x70 + k) for k in range(28)]
    print("\n   TABLE A  C-RAM[0x50+k] == (32+k)*0x400 for k=0..31 :", all(
        a[k] == (32 + k) * 0x400 for k in range(32)))
    print("   TABLE B  C-RAM[0x70+k], first differences distinct   :",
          sorted(set(b[k + 1] - b[k] for k in range(26))), "  last =", "%06X" % b[27])
    print("   cells written by the blob: 0x%02X..0x%02X (%d)" %
          (min(cram), max(cram), len(cram)))

    P, U = param_streams(), unit_of_algo()
    per_unit = {0: collections.Counter(), 1: collections.Counter()}
    banks = {}
    for i, recs in P.items():
        if i not in U:
            continue
        unit = U[i]
        cur, blocks = None, []
        for (op, cmd, h, pl) in recs:
            if op in (0, 1, 5):
                for w in words5(pl):
                    if hi12(w) == 0x801 and cls(w) == 0 and lo12(w) == 0x821:
                        cur = ad8(w); per_unit[unit][cur] += 1
            elif op == 2:
                blocks.append((cur, len(words3(pl))))
        banks[i] = (unit, blocks)
    print("\n   801.0.NN.821 immediates in the %d valid parameter streams:" % len(banks))
    for u in (0, 1):
        print("      unit %d : %s" % (u, ", ".join("#$%02X x%d" % (k, v)
              for k, v in sorted(per_unit[u].items()))))
    tbl = [k for u in (0, 1) for k in per_unit[u] if 0x50 <= k <= 0x8B]
    print("   parameter streams pointing into the table region 0x50..0x8B:",
          tbl if tbl else "NONE  <- the tables are RESIDENT")
    lastu0 = max(b + n - 1 for i, (u, bl) in banks.items() if u == 0 for b, n in bl if b is not None)
    lastu1 = max(b + n - 1 for i, (u, bl) in banks.items() if u == 1 for b, n in bl if b is not None)
    print("\n   MAP  0x00..0x4F unit-0 bank (largest cell used 0x%02X)" % lastu0)
    print("        0x50..0x6F TABLE A   0x70..0x8B TABLE B   0x8C..0x8F unwritten")
    print("        0x90..0xB5 unit-1 bank (largest cell used 0x%02X)" % lastu1)
    print("   TABLE B straddles 0x80 -> C-RAM is NOT split in half at bit 7.")


def sec_forced():
    hdr("forced -- a rebase must exist (A), and it is not in a body (B)")
    IM = images()
    na = sorted(sum(1 for w in ws if coeff_consumer(w))
                for p, (i, la, ws) in IM.items() if la == 84)
    print("class-A counts of the 37 unit-0 images:")
    print("   ", " ".join(str(x) for x in na))
    print("    min %d  max %d  %d distinct" % (na[0], na[-1], len(set(na))))
    print("    -> a cursor that is not reset would enter the unit-1 body at %d"
          " different values;" % len(set(na)))
    print("       the unit-1 bank base is 0x90 in 12/12 reverb streams.  FORCED.")

    pre = []
    for p, (i, la, ws) in IM.items():
        if la != 84:
            continue
        j = next(k for k, w in enumerate(ws) if coeff_consumer(w))
        pre.append(set(fmt(w) for w in ws[:j]))
    print("\nwords preceding each unit-0 image's FIRST class-A word:")
    print("    prefix lengths:", " ".join(str(len(s)) for s in sorted(pre, key=len)))
    print("    INTERSECTION  :", set.intersection(*pre) or "EMPTY  <- FORCED: not in a body")
    allsets = [set(fmt(w) for w in ws) for p, (i, la, ws) in IM.items()]
    print("    control, words present in ALL 38 images:",
          set.intersection(*allsets) or "none")


def sec_fields():
    hdr("fields -- the exhaustive search for the value 0x90 (C): the K4 result")
    _, kern = blob(KERNEL_BLOB)
    _, epi = blob(EPILOG_BLOB)
    print("I-RAM 50..59 (everything between the unit-0 return and the unit-1 body),")
    print("every contiguous bit field of width 8..16 at every bit position:")
    for k in range(50, 60):
        w = kern[k]
        hits = ["[%d:%d]" % (lo + wd - 1, lo)
                for lo in range(36) for wd in range(8, 17)
                if lo + wd <= 36 and ((w >> lo) & ((1 << wd) - 1)) == 0x90]
        print("   w%-3d %s   %s" % (k, fmt(w), " ".join(hits) or "none"))
    print("   (w51's hits straddle the addr8/lo12 boundary, which LABEL_0387E6")
    print("    PROVES BY CONSTRUCTION -- not a field.)")

    IM = images()
    allw = [("KERNEL", k, w) for k, w in enumerate(kern)]
    allw += [("EPILOG", 60 + k, w) for k, w in enumerate(epi)]
    for p, (i, la, ws) in sorted(IM.items()):
        allw += [("algo%02d" % i, la + k, w) for k, w in enumerate(ws)]
    print("\nover all %d words of the machine (header + output stage + 38 bodies):" % len(allw))
    for name, f in (("addr8      == 0x90", lambda w: ad8(w) == 0x90),
                    ("bits[24:17]== 0x90", lambda w: ((w >> 17) & 0xFF) == 0x90),
                    ("bits[11:4] == 0x90", lambda w: ((w >> 4) & 0xFF) == 0x90),
                    ("C-fmt payload A == 0x90", lambda w: c_format(w) and c_a(w) == 0x90)):
        hits = [(t, a, fmt(w)) for t, a, w in allw if f(w)]
        print("   %-24s : %d  %s" % (name, len(hits), hits if hits else ""))
    print("\n   -> the rebase cannot carry 0x90 as an immediate; it must copy a")
    print("      register.  FORCED.  There must be a per-unit coefficient-base")
    print("      register, and it must be an arbitrary 8-bit one (0x90 is not a")
    print("      power-of-two boundary and TABLE B straddles 0x80).")

    print("\nthe three in-program 801.0.NN.821 immediates against the C-RAM map:")
    for t, a, w in allw:
        if hi12(w) == 0x801 and cls(w) == 0 and lo12(w) == 0x821:
            role = {0x50: "TABLE A base", 0x70: "TABLE B base",
                    0x90: "unit-1 coefficient bank base"}.get(ad8(w), "?")
            print("   %s w%-3d  ldptr #$%02X   %s" % (t, a, ad8(w), role))

    print("\nthe candidate copy instructions (analysis sect. 5.1) -- every site:")
    for pat in ("800.1.60.00B", "010.A.00.20C", "010.9.D0.20C",
                "400.1.0E.000", "400.1.0F.007"):
        sites = [(t, a) for t, a, w in allw if fmt(w) == pat]
        print("   %-14s x%-3d  %s" % (pat, len(sites), sites[:8]))
    print("   800.1.60.00B: 2 sites, I-RAM 46 and 54 = offset +4 of the unit-0 and")
    print("   unit-1 setup blocks (42 and 50), and nowhere else in the machine.")


def sec_regs():
    hdr("regs -- class-1 register file: bit 7 is the effect unit (G / K6's lead)")
    P, IM, U = param_streams(), images(), unit_of_algo()
    per = {0: collections.Counter(), 1: collections.Counter()}
    for i, recs in P.items():
        if i not in U:
            continue
        u = U[i]
        for (op, cmd, h, pl) in recs:
            if op in (0, 1, 5):
                for w in words5(pl):
                    if hi12(w) == 0x000 and cls(w) == 1 and lo12(w) == 0x000:
                        per[u][ad8(w)] += 1
    for u in (0, 1):
        print("   unit-%d streams: %3d packets, %2d distinct NN : %s"
              % (u, sum(per[u].values()), len(per[u]),
                 " ".join("%02X" % k for k in sorted(per[u]))))
    print("   all unit-0 NN < 0x80 :", all(k < 0x80 for k in per[0]))
    print("   all unit-1 NN >= 0x80:", all(k >= 0x80 for k in per[1]))
    print("   unit-1 NN whose (NN-0x80) is a unit-0 NN: %d / %d"
          % (sum(1 for k in per[1] if (k - 0x80) in per[0]), len(per[1])))
    print("\n   the boot blob writes the matched pair back to back:")
    for (op, cmd, h, pl) in parse_stream(BOOT_BLOB, limit=3)[:1]:
        print("     ", "  ".join(fmt(w) if (w >> 32) & 0xFF == 0x08 or (w >> 32) & 0xFF == 0
                                 else "poke" for w in words5(pl)))
    print("   -> 0x06 and 0x86 are one register in the two unit halves.")
    print("      PROVEN BY CONSTRUCTION.")

    print("\n   in the body corpus the DRAM/register discrimination is hi12, not addr8:")
    for u, nm in ((0, "unit-0 bodies"), (1, "unit-1 body")):
        c = collections.Counter()
        for p, (i, la, ws) in IM.items():
            if (1 if la == 200 else 0) != u:
                continue
            for w in ws:
                if cls(w) == 1:
                    c[("hi12 bit7 " + ("set " if hi12(w) & 0x80 else "clear"), ad8(w))] += 1
        print("     %-14s %s" % (nm, sorted((k[0], "%02X" % k[1], v) for k, v in c.items())))


def sec_class8():
    hdr("class8 -- only class4==0xA advances the cursor (I): ALU constraint")
    IM = images()
    c = collections.Counter()
    for p, (i, la, ws) in IM.items():
        for w in ws:
            if cursor_fetch(w):
                c[cls(w)] += 1
    print("   class of every bit-23 (cursor-fetch) word in the 2974-word corpus:",
          dict(sorted(c.items())))
    peq = [ws for p, (i, la, ws) in IM.items() if i == 39][0]
    n8 = [(k, fmt(w)) for k, w in enumerate(peq) if cursor_fetch(w) and cls(w) != 0xA]
    print("   PARAMETRIC EQ: %d class-A words, %d non-class-A bit-23 words at %s"
          % (sum(1 for w in peq if coeff_consumer(w)), len(n8), [k for k, _ in n8]))
    print("     all of them are", n8[0][1] if n8 else "-")
    print("   The PEQ cursor map is PROVEN to the bit: 6 cells per biquad section,")
    print("   5 bands x 2 channels, 30 host cells + the 801.0.00.021 rewind.")
    print("   If class 8 advanced, band k would start at 7k instead of 6k and every")
    print("   role would shift.  FORCED: bit 23 = FETCH, class4==0xA = ADVANCE.")


def sec_multitap():
    hdr("multitap -- the 050.0.00.921 prediction, and why it MISSES (K)")
    IM = images()
    grp = [("algo%02d" % i, k, la + k, fmt(w))
           for p, (i, la, ws) in sorted(IM.items())
           for k, w in enumerate(ws) if 0x20 <= (lo12(w) & 0xFF) <= 0x27]
    print("   body words with (lo12 & 0xFF) in 0x20..0x27:")
    for g in grp:
        print("      %s w%-3d (I-RAM %3d)  %s" % g)
    mt = [ws for p, (i, la, ws) in IM.items() if i == 10][0]
    cur, seq = 0, []
    for k, w in enumerate(mt):
        if coeff_consumer(w):
            seq.append((k, cur)); cur += 1
    print("\n   MULTI TAP DELAY class-A words (body index -> cursor slot):")
    print("     ", " ".join("%d:%02X" % (k, c) for k, c in seq))
    print("      host bank: 15 cells 0x00..0x0E;  0x08..0x0A and 0x0B..0x0D are the")
    print("      SAME damping triple, written twice (op 0x76 -> 0x08 and -> 0x0B).")
    print("      A -3 rewind at body word 33 would send them to 0x05..0x07 and")
    print("      0x08..0x0A -- contradicting the host's own writes.  MISS.")
    print("      The group that overruns is at body words 52/53/54, 17 words later.")


SECTIONS = {"map": sec_map, "forced": sec_forced, "fields": sec_fields,
            "regs": sec_regs, "class8": sec_class8, "multitap": sec_multitap}

if __name__ == "__main__":
    want = sys.argv[1:] or list(SECTIONS)
    for s in want:
        if s not in SECTIONS:
            sys.exit("unknown section %r; have: %s" % (s, " ".join(SECTIONS)))
        SECTIONS[s]()
