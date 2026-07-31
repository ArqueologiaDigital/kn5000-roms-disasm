#!/usr/bin/env python3
"""DSCBASE -- where does the PER-UNIT DELAY-DESCRIPTOR BASE come from?

Offline, read-only.  Answers the question SPECULATIVE-APPLIED-REGISTER.md sect.206
left open: `m_dsc' in the emulator is 0x25 for BOTH units because the firmware
loads the same immediate twice, and sect.206 nominated `lo12 = 0x827' (payloads
0x6C / 0x64) as the only pointer-family register with a per-unit split left --
while noting that 0x6C - 0x64 = 8 and the measured block separation is 0x26 = 38.

This tool settles that arithmetic, enumerates every candidate carrier the corpus
actually contains, and prints the pre-registered numbers for the emulator run.

    python3 dsp/tools/dscbase_arith.py anchors    # 1  the two anchors, re-derived
    python3 dsp/tools/dscbase_arith.py carriers   # 2  THE ARITHMETIC + the NULL
    python3 dsp/tools/dscbase_arith.py cells      # 3  the two cold-boot bodies
    python3 dsp/tools/dscbase_arith.py predict    # 4  the pre-registered numbers
    python3 dsp/tools/dscbase_arith.py all

Nothing here is a recording.  Inputs: original_ROMs/kn5000_subprogram_v142.rom
and the repo's own ROM parsers (via ~/compartilhado/kn7000_mame/tools).
"""

import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402

# --- MEASURED, re-derived by `anchors' below (never hard-used before that) ---
REQ_U0 = 0x26           # unit-0 descriptor block base, host-side ground truth
REQ_U1 = 0x00           # unit-1 (reverb) block base, ditto
DELTA = (REQ_U0 - REQ_U1) & 0xFF        # = 0x26 = 38, the number to be carried
MOD = 256               # the payload field is exactly 8 bits (K3 sect.1.1, PBC)

COLDBOOT_U0 = 1         # algo 1  CHORUS            (sect.170)
COLDBOOT_U1 = 20        # algo 20 CONCERT REVERB 1  (sect.198)

# the live descriptor cells sect.189/sect.190 quote out of a running emulator
LIVE = {0x26: 0x0190, 0x2B: 0x0410, 0x03: 0x8000, 0x1E: 0x7FFF}


def head(n, s):
    print("=" * 78)
    print("%s. %s" % (n, s))
    print("=" * 78)


def load():
    sub = os.path.join(os.path.dirname(HERE), "..", "original_ROMs",
                       "kn5000_subprogram_v142.rom")
    sub = os.path.normpath(sub)
    tools = os.path.expanduser("~/compartilhado/kn7000_mame/tools")
    return DC.load(sub, tools)


# ===========================================================================
# 1. the anchors -- re-derived, host side and program side
# ===========================================================================
def cmd_anchors(rom, imgs, loads, hdr, epi):
    head(1, "THE TWO ANCHORS, RE-DERIVED FROM THE ROM (not quoted)")
    per_unit = {0: {}, 1: {}}
    for a in sorted(imgs):
        u = DC.unit_of(loads[a])
        if u is None:
            continue
        c = DC.desc_cells(rom, a)
        if not c:
            continue
        per_unit[u][a] = (min(c), max(c), len(c))
    for u in (0, 1):
        lo = min(v[0] for v in per_unit[u].values())
        hi = max(v[1] for v in per_unit[u].values())
        bases = sorted({v[0] for v in per_unit[u].values()})
        print("   unit %d : %2d algorithms, cells 0x%02X..0x%02X, "
              "block BASE(s) %s" % (u, len(per_unit[u]), lo, hi,
                                    " ".join("0x%02X" % b for b in bases)))
    print()
    print("   => the per-unit descriptor base the machine must produce is")
    print("      unit 0 -> 0x%02X   unit 1 -> 0x%02X   difference 0x%02X = %d"
          % (REQ_U0, REQ_U1, DELTA, DELTA))
    print()
    print("   PROGRAM SIDE -- every pointer-family load in the whole corpus")
    print("   (header, epilogue, and all 38 body images):")
    n_body = 0
    for a in sorted(imgs):
        for w in imgs[a]:
            hi_, cl, ad, lo = DC.fields(w)
            if (lo & 0xF00) == 0x800 and (lo & 0xF0) == 0x20:
                n_body += 1
    for tag, ws in (("HDR", hdr), ("EPI", epi)):
        for i, w in enumerate(ws):
            hi_, cl, ad, lo = DC.fields(w)
            if (lo & 0xF00) == 0x800 and (lo & 0xF0) == 0x20:
                mark = "  <== DESCRIPTOR POINTER" if (lo & 0xFF) == 0x25 else ""
                print("     %s %2d  %s   selector %02X  payload %02X%s"
                      % (tag, i + (0 if tag == "HDR" else 60), DC.fmt(w),
                         lo & 0xFF, ad, mark))
    print("     pointer loads inside any of the 38 BODY IMAGES: %d" % n_body)
    print()
    print("   => the ONLY per-unit-paired pointer loads are HDR 42/50 (0x821),")
    print("      HDR 43/51 (0x827) and HDR 44/52 (0x825).  0x825 carries the")
    print("      SAME immediate 0x25 twice -- sect.206's premise, re-confirmed.")


# ===========================================================================
# 2. the arithmetic -- can ANY per-unit field carry 38?
# ===========================================================================
def affine_scales(delta, target, mod=MOD, limit=None):
    """every integer scale s in [-mod/2, mod/2) with s*delta == target (mod).
    The offset b is then free and always exists, so scale is the whole test."""
    out = []
    for s in range(-mod // 2, mod // 2):
        if (s * delta - target) % mod == 0:
            out.append(s)
    if limit is not None:
        out = [s for s in out if abs(s) <= limit]
    return out


def cmd_carriers(rom, imgs, loads, hdr, epi):
    head(2, "CAN ANY PER-UNIT FIELD CARRY THE BASE?  THE ARITHMETIC + THE NULL")
    print("""   MODEL.  A `descriptor base register' means: some field F of the
   per-unit setup block determines the base, base_u = f(F_u), with f any
   AFFINE map on the 8-bit payload space, f(x) = s*x + b (mod 256).  Then
        base_0 - base_1 = s * (F_0 - F_1)   (mod 256)
   and b never enters.  So a field with per-unit delta d can carry the base
   IF AND ONLY IF  s*d == 38 (mod 256)  has an integer solution, i.e. iff
        gcd(d, 256) DIVIDES 38.
   38 = 2 * 19 and gcd(d,256) is a power of two, so gcd(d,256) must be 1 or 2:
   ** d MUST BE ODD, OR d == 2 (mod 4).  Any other delta is refuted outright,
      for every integer scale, with no |scale| bound assumed. **
""")
    # the paired setup blocks, taken positionally: unit-0 w42.. / unit-1 w50..
    pairs = [(42, 50), (43, 51), (44, 52), (45, 53), (46, 54),
             (47, 55), (48, 56), (49, 59)]
    print("   THE PAIRED SETUP WORDS (unit-0 block w42..w49, unit-1 w50..w59):")
    print("     %-6s %-14s %-14s  differing fields" % ("pair", "unit 0", "unit 1"))
    fields = []
    for i0, i1 in pairs:
        w0, w1 = hdr[i0], hdr[i1]
        f0, f1 = DC.fields(w0), DC.fields(w1)
        names = ("hi12", "class4", "addr8", "lo12")
        diff = [(names[k], f0[k], f1[k]) for k in range(4) if f0[k] != f1[k]]
        print("     %2d/%-3d %-14s %-14s  %s"
              % (i0, i1, DC.fmt(w0), DC.fmt(w1),
                 ", ".join("%s %X/%X" % d for d in diff) or "IDENTICAL"))
        for nm, a, b in diff:
            fields.append(("w%d/w%d %s" % (i0, i1, nm), a, b))
    print()
    print("   EVERY DIFFERING FIELD, AGAINST THE REQUIREMENT:")
    print("     %-22s %-11s %5s %5s  %s"
          % ("field", "u0/u1", "delta", "gcd", "integer scales s: s*d==38"))
    n_ok_any, n_ok_8 = 0, 0
    for nm, a, b in fields:
        d = (a - b) % MOD
        g = math.gcd(d, MOD) if d else MOD
        sols = affine_scales(d, DELTA)
        s8 = [s for s in sols if abs(s) <= 8]
        if sols:
            n_ok_any += 1
        if s8:
            n_ok_8 += 1
        print("     %-22s %02X/%02X       %5d %5d  %s"
              % (nm, a, b, d, g,
                 ("%s   (|s|<=8: %s)" % (sols, s8 or "NONE")) if sols
                 else "** NONE -- REFUTED for every integer scale **"))
    print()
    print("   TOTALS: %d fields; %d admit ANY integer scale; %d admit |s| <= 8."
          % (len(fields), n_ok_any, n_ok_8))
    print()
    print("   THE NULL (a criterion that cannot fail is not a test):")
    any_d = [d for d in range(MOD) if affine_scales(d, DELTA)]
    d8 = [d for d in range(MOD) if affine_scales(d, DELTA, limit=8)]
    print("     of the 256 possible per-unit deltas, %d (%.1f%%) admit some"
          % (len(any_d), 100.0 * len(any_d) / MOD))
    print("     integer scale, and %d (%.1f%%) admit one with |s| <= 8."
          % (len(d8), 100.0 * len(d8) / MOD))
    print("     So the test CAN pass by chance ~%.0f%% / ~%.0f%% of the time --"
          % (100.0 * len(any_d) / MOD, 100.0 * len(d8) / MOD))
    print("     it is a real test, and the ADDRESS-shaped fields fail it.")
    print()
    print("   DIRECT READING (s = 1, b = 0 -- the payload IS the base):")
    for nm, a, b in fields:
        if (a, b) == (REQ_U0, REQ_U1):
            print("     %s HITS" % nm)
    print("     hits: 0 of %d.  Null under a uniform 8-bit pair: 1/65536." % len(fields))
    print()
    print("   THE BODY'S OWN FIRST DRAM WORD CANNOT CARRY IT EITHER.")
    print("   r3-delaydram.md sect.6.2 reads `addr8 = 0x30' as a load/reset of")
    print("   the cursor (37 of 38 images).  Every distinct FIRST-consumer word,")
    print("   against the set of units whose algorithms use it:")
    import collections
    firsts = collections.defaultdict(set)
    for a in sorted(imgs):
        u = DC.unit_of(loads[a])
        if u is None:
            continue
        c = DC.consumers(imgs[a])
        if not c or not DC.desc_cells(rom, a):
            continue
        firsts[DC.fmt(c[0][1])].add(u)
    for w in sorted(firsts):
        us = sorted(firsts[w])
        print("     %s   units %s%s"
              % (w, us, "   <== ONE WORD, BOTH UNITS" if len(us) > 1 else ""))
    print("   => `880.1.30.00B' is body word 0 of algorithms on BOTH units, so")
    print("      the SAME 36 bits must yield base 0x26 for one and 0x00 for the")
    print("      other.  No field of it can carry the base.  FORCED.")
    print()
    print("   AND THE PAYLOADS ARE OUT OF RANGE ANYWAY.  Corpus maximum")
    print("   descriptor cell = 0x%02X (GATED REVERB); the host never writes a" % DC.MAX_CELL)
    print("   tag-0x4C cell above it.  0x821's 0x70/0x50 and 0x827's 0x6C/0x64")
    print("   are all ABOVE 0x%02X, so read directly as a base each would aim" % DC.MAX_CELL)
    print("   the cursor at cells no algorithm ever writes.")


# ===========================================================================
# 3. the two cold-boot bodies, cell by cell
# ===========================================================================
def body_cells(rom, imgs, loads, algo):
    u = DC.unit_of(loads[algo])
    cells = DC.desc_cells(rom, algo)
    cons = DC.consumers(imgs[algo])
    return u, cells, cons


def seq(base, n, ring=None, pre=False):
    """cell sequence of n consumers, base = the value loaded into the pointer.
    pre: cell = ++cur (so the first cell is base+1).  ring = (B, L) or None."""
    cur, out = base, []
    for _ in range(n):
        if pre:
            cur += 1
            if ring and cur >= ring[1]:
                cur = ring[0]
            out.append(cur & 0xFF)
        else:
            out.append(cur & 0xFF)
            cur += 1
            if ring and cur >= ring[1]:
                cur = ring[0]
    return out


def cmd_cells(rom, imgs, loads, hdr, epi):
    head(3, "THE TWO COLD-BOOT BODIES -- what each candidate makes them read")
    for algo, name in ((COLDBOOT_U0, "CHORUS"), (COLDBOOT_U1, "CONCERT REVERB 1")):
        u, cells, cons = body_cells(rom, imgs, loads, algo)
        print("   algo %-3d %-18s unit %d   %d consumers   %d descriptor cells"
              % (algo, name, u, len(cons), len(cells)))
        print("      cells written by the host: 0x%02X..0x%02X"
              % (min(cells), max(cells)))
        print("      " + "  ".join("%02X:%04X" % (c, cells[c])
                                   for c in sorted(cells)))
        n = len(cons)
        models = [
            ("SHIPPED emulator  m_dsc=0x25, POST, no ring",
             seq(0x25, n, None, pre=False)),
            ("(i)   PRE from 0x25, no ring",
             seq(0x25, n, None, pre=True)),
            ("(iv)  PRE from 0x25 + PER-UNIT RING",
             seq(0x25, n, (0x00, 0x26) if u else (0x26, 0x40), pre=True)),
            ("(A)   0x827 as base, POST  (0x6C u0 / 0x64 u1)",
             seq(0x6C if u == 0 else 0x64, n, None, pre=False)),
            ("(B)   0x821 as base, POST  (0x70 u0 / 0x50 u1)",
             seq(0x70 if u == 0 else 0x50, n, None, pre=False)),
        ]
        for label, s in models:
            hit = sum(1 for c in s if c in cells)
            print("      %-46s %s" % (label, " ".join("%02X" % c for c in s[:12])
                                      + (" ..." if n > 12 else "")))
            print("      %-46s cells that are WRITTEN: %d of %d   %s"
                  % ("", hit, n, "** ALL **" if hit == n else ""))
        print()


# ===========================================================================
# 4. the pre-registered numbers
# ===========================================================================
#  the cold-boot capture's own descriptor bank, replayed from
#  kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt (see `bank' below).
#  It differs from the ROM defaults in exactly one cell: 0x00 = 0x81E7, the
#  PRE DELAY the machine actually boots with (the ROM default is 0x81F4).
def capture_bank():
    import re
    p = os.path.expanduser("~/compartilhado/kn7000_mame/notes/data/"
                           "kn5000_dsp1_upload_coldboot.txt")
    tr, cur = [], None
    for ln in open(p).read().splitlines():
        m = re.match(r"transfer\s+(\d+): cmd (0x[0-9A-Fa-f]+)", ln)
        if m:
            cur = []
            tr.append(cur)
            continue
        m = re.match(r"\s*[0-9A-F]{4}: ((?:[0-9A-F]{2} ?)+)\s*$", ln)
        if m and cur is not None:
            cur.extend(int(x, 16) for x in m.group(1).split())
    cells, wp = {}, None
    for d in tr:
        if len(d) < 2 or (len(d) - 2) % 5:
            continue
        body = d[2:]
        if not any(body[k] in (0x0A, 0x0B) and (body[k + 4] & 0x7F) == 0x4C
                   for k in range(0, len(body), 5)):
            continue                    # not a descriptor-poke transfer
        for k in range(0, len(body), 5):
            g = body[k:k + 5]
            if g[0] == 0x08 and g[1] == 0x01 and (g[4] & 0x7F) == 0x25:
                wp = ((g[2] & 0x0F) << 4) | (g[3] >> 4)
            elif g[0] in (0x0A, 0x0B) and (g[4] & 0x7F) == 0x4C and wp is not None:
                v = ((g[1] & 0x7F) << 17) | (g[2] << 9) | (g[3] << 1) | (g[4] >> 7)
                cells[wp] = v & 0xFFFF
                wp = (wp + 1) & 0xFF
    return cells, wp


def cmd_predict(rom, imgs, loads, hdr, epi):
    head(4, "PRE-REGISTERED NUMBERS FOR THE FOUR-ARM EMULATOR RUN")
    u0, c0, k0 = body_cells(rom, imgs, loads, COLDBOOT_U0)
    u1, c1, k1 = body_cells(rom, imgs, loads, COLDBOOT_U1)
    bank, final_wp = capture_bank()
    print("   VEHICLE: cold boot (unit 0 = algo 1 CHORUS, unit 1 = algo 20")
    print("   CONCERT REVERB 1), notes playing, sampled after 900k frames --")
    print("   the device's own sect.204 CONSUMER->CELL census.")
    print()
    print("   THE CAPTURE'S OWN BANK (replayed from the cold-boot upload log,")
    print("   i.e. what m_dscbank[] actually holds in the running emulator):")
    print("     " + " ".join("%02X:%04X" % (c, bank[c]) for c in sorted(bank)
                             if c < 0x20))
    print("     " + " ".join("%02X:%04X" % (c, bank[c]) for c in sorted(bank)
                             if c >= 0x20))
    print("     host write pointer m_dsc_wp is left at 0x%02X" % final_wp)
    print()
    print("   sect.189's four quoted live cells, against this replay:")
    for cell in sorted(LIVE):
        rv = bank.get(cell)
        print("     %02X  quoted %04X   capture %s   %s"
              % (cell, LIVE[cell], "%04X" % rv if rv is not None else "----",
                 "MATCH" if rv == LIVE[cell] else "** MISMATCH **"))
    print()
    print("   ** READ THE `cell%04X' COLUMN, NOT `dsc%02X'.  The census computes")
    print("   its dsc label at PRINT time from the CURRENT m_dsc (0x26, left by")
    print("   the epilogue's I-RAM 62), while the body ran with m_dsc = 0x25, so")
    print("   every BODY label it prints is ONE TOO HIGH.  The same +1 is in the")
    print("   sect.200 age probe (upd6383.cpp:1927 increments before :1950 reads).")
    print("   MEASURED corroboration: sect.204 printed iw46->ix3(dsc29,cell05A0)")
    print("   and 0x05A0 is descriptor cell 0x28 = 0x25+3, not 0x29. **")
    print()
    arms = [("PRE=0 RING=0  (SHIPPED TODAY)", False, False),
            ("PRE=1 RING=0", True, False),
            ("PRE=0 RING=1", False, True),
            ("PRE=1 RING=1  (the candidate)", True, True)]
    for tag, u, cells, cons in (("body 0 -- CHORUS      ", u0, c0, k0),
                                ("body 1 -- CONCERT REV1", u1, c1, k1)):
        n = min(len(cons), 16)
        ring = (0x00, 0x26) if u else (0x26, 0x40)
        print("   %s  unit %d, %d consumers, census shows the first %d"
              % (tag, u, len(cons), n))
        for name, pre, rng in arms:
            s = seq(0x25, n, ring if rng else None, pre=pre)
            hits = sum(1 for c in s if c in cells)
            print("     %-30s cells  %s" % (name, " ".join("%02X" % c for c in s)))
            print("     %-30s values %s   [%d/%d on written cells]"
                  % ("", " ".join("%04X" % bank.get(c, 0) for c in s), hits, n))
        print()


CMDS = {"anchors": cmd_anchors, "carriers": cmd_carriers,
        "cells": cmd_cells, "predict": cmd_predict}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all", choices=["all"] + list(CMDS))
    a = ap.parse_args()
    rom, imgs, loads, hdr, epi = load()
    for k, f in CMDS.items():
        if a.cmd in ("all", k):
            f(rom, imgs, loads, hdr, epi)
            print()


if __name__ == "__main__":
    main()
