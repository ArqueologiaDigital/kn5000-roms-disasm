#!/usr/bin/env python3
"""Is the uPD6383GF host protocol the SAME on the KN5000 and the SX-WSA1R?

QUESTION IT ANSWERS
    Both instruments are said to run their effects on the NEC uPD6383GF family,
    and MAME has no device for it.  Before anyone writes one: which parts of the
    host-side protocol are a property of the CHIP (the same on both products)
    and which are a property of the PRODUCT (they differ)?  And how much of the
    DSP payload is literally the same data?

    Everything printed here is derived from the dumped ROMs alone:

        original_ROMs/kn5000_subprogram_v142.rom   KN5000 Sub CPU (TMP94C241)
        wsa1/original_ROMs/wsa1_prom_c.ic28        WSA1R CPU 2  (TMP95C061)
        wsa1/original_ROMs/wsa1_prom_a.ic12        WSA1R CPU 1  (TMP95C061)
        wsa1/original_ROMs/wsa1_prom_b.ic13        WSA1R CPU 1, second EPROM
        wsa1/original_ROMs/wsa1_prom_d.bin         WSA1R prom_d

    No hardware, no capture, no datasheet is behind any number below.

SECTIONS

  grammar    Walks the KN5000 bytecode streams (the 100 algorithm streams at
             ALGO_TABLE and the 100 coefficient streams at COEF_TABLE) and the
             WSA1R prom_c stream pool (0xFCD0F7-0xFDD2AA) with ONE framer --
             opcode = high nibble of byte 0, 12-bit big-endian length -- and
             asks, per opcode, which group size each machine's payloads are
             consistent with.  Separates "same container" from "same record".

             The residue test is evidence only where it can FAIL: a payload that
             is a multiple of 60 fits 3, 4 and 5 at once.  Every row therefore
             also prints how many records DISCRIMINATE.

  params     Closes an OPEN question in the WSA1R tree.
             wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md says "130 of the
             297 streams contain at least one record whose payload is not a
             whole number of the interpreter's groups. ... the routine that
             reads them has not been found."  This section shows those records
             are PARAMETER records in the KN5000's parameter-record grammar --
             [len_hi, len_lo, id, ...] with id in the translator dispatch set
             {0x21, 0x24, 0x40, 0x61..0x79}, value records ending 0x7A -- and
             calibrates the signature on the KN5000's own value and descriptor
             tables, where the two kinds separate 445/445 against 0/258.

  handlers   How many bytes each machine's opcode arm actually puts ON THE
             WIRE -- one command byte plus N data bytes -- counted from the ROM
             bytes.  This is the level a device model needs, and it is where the
             op-2 container difference is reconciled.

  shared     How much DSP payload the two products share VERBATIM, measured as
             the fraction of L-byte windows of one corpus occurring anywhere in
             the other image, with a SHUFFLE NULL (the same bytes permuted) on
             every figure.  Reported per corpus kind, because "the two machines
             share microcode" and "the two machines share parameter tables" are
             different claims with different consequences.

  runs       The longest verbatim prefix of each WSA1R pool stream in the KN5000
             image -- the published four-run finding, re-derived and extended.
             Its per-row control is WEAK and the section says so: the two images
             share so much material that a random pool window is often found
             too.  `shared` is the sound instrument; this is the index.

  commands   The command byte heading each record -- the byte the host sends
             with the command/data qualifier asserted -- per machine, per
             opcode.  Records whose third byte is a parameter-translator id are
             split out, because those are not commands at all.

  transport  The per-byte handshake on both machines, censused from raw bytes:
             the 0x1F40 timeout literal and the SFR bit-manipulation forms.
             A byte-window scan is an UPPER bound -- a hit can be bytes inside
             another instruction or inside data -- but its ZEROES are exact.

RUN
    python3 notes/sound/dsp_protocol_cross_product.py            # everything
    python3 notes/sound/dsp_protocol_cross_product.py grammar
    python3 notes/sound/dsp_protocol_cross_product.py params
    python3 notes/sound/dsp_protocol_cross_product.py handlers
    python3 notes/sound/dsp_protocol_cross_product.py shared
    python3 notes/sound/dsp_protocol_cross_product.py runs
    python3 notes/sound/dsp_protocol_cross_product.py commands
    python3 notes/sound/dsp_protocol_cross_product.py transport
    python3 notes/sound/dsp_protocol_cross_product.py --selftest

    --selftest re-derives figures other notes already published (297 WSA1R
    streams, 1,832 records, the nine KN5000 IC310 effects, the four shared runs)
    and exits non-zero if any has moved.  It is the guard that says this script
    reads the same tree those notes were written from.

    `shared` takes about a minute; everything else is seconds.

stdlib only.
"""
import argparse
import os
import random
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# ---------------------------------------------------------------- the images
KN_ROM = os.path.join(ROOT, "original_ROMs", "kn5000_subprogram_v142.rom")
KN_BASE = 0xEF00                    # file offset = address - 0xEF00
WS_C = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_c.ic28")
WS_A = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
WS_B = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
WS_D = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_d.bin")
WS_BASE = 0xF80000                  # prom_a and prom_c both

# KN5000 Sub CPU: the four parallel 100-entry u32 pointer arrays
# (v142/subcpu/subcpu_data_tables.s, "INDEXING")
ALGO_TABLE = 0x0001ED7C             # algorithm (microprogram) bytecode streams
COEF_TABLE = 0x0001EF0C             # coefficient bytecode streams
PVAL_TABLE = 0x0001F09C             # parameter VALUE record tables
PDSC_TABLE = 0x0001F22C             # parameter DESCRIPTOR record tables
N_ALGOS = 100

# WSA1R prom_c relocatable stream pool
# (wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md)
POOL_LO, POOL_HI = 0xFCD0F7, 0xFDD2AB
POOL_DIRLO = 0xFDBFD9               # the four directory objects start here

VALID_OPS = {0, 1, 2, 3, 4, 5, 14}   # the WSA1R dispatcher's arms, 0xF9AD84
KN_OPS = {0, 1, 2, 3, 4, 5, 13, 14}  # the KN5000 adds 0x0D, whose record is
                                     # TWO bytes, not three
# The KN5000 dispatcher (0x03C2CB) has arms 0..5 through OFFSETS_14739, plus
# special cases 0x0D (bus idle + task yield) and 0x0E (command + raw data), and
# ignores 6..0x0C.

# The KN5000 parameter translator's dispatch set: 0x21/0x24/0x40 have dedicated
# arms and 0x61..0x79 go through the 25-entry offset table at 0x014745.
TRANSLATOR_IDS = {0x21, 0x24, 0x40} | set(range(0x61, 0x7A))
VALUE_TERMINATOR = 0x7A             # every KN5000 parameter VALUE record ends
                                    # on it; no descriptor record does

KN = open(KN_ROM, "rb").read()
WC = open(WS_C, "rb").read()


# ===========================================================================
#  One framer, used on both corpora
# ===========================================================================
def walk(img, base, start, limit, ops_ok, min_len=3):
    """Follow the 12-bit length field.  Returns (end, [(addr, op, len)], ok).

    byte 0: bits 7:4 = opcode, bits 3:0 = length[11:8]
    byte 1: length[7:0];  the length counts the two header bytes
    opcode 0xF ends the stream; its record is 2 bytes.
    """
    a, recs = start, []
    while a < limit:
        h = img[a - base]
        if (h & 0xF0) == 0xF0:
            if a + 2 > limit:
                return a, recs, False
            recs.append((a, 0xF, 2))
            return a + 2, recs, True
        op = h >> 4
        ln = ((h & 0x0F) << 8) | img[a + 1 - base]
        if ln < min_len or op not in ops_ok or a + ln > limit:
            return a, recs, False
        recs.append((a, op, ln))
        a += ln
    return a, recs, False


# --------------------------------------------------------------- KN5000 side
def kn_table(tbl):
    """The distinct stream addresses one 100-entry pointer array names, each
    with the effect numbers that point at it."""
    out = {}
    for i in range(N_ALGOS):
        o = tbl - KN_BASE + 4 * i
        ptr = int.from_bytes(KN[o:o + 4], "little")
        if not (KN_BASE <= ptr < KN_BASE + len(KN)):
            continue
        out.setdefault(ptr, set()).add(i)
    return out


def kn_streams():
    """Every KN5000 bytecode stream the two bytecode arrays name.

    Returns {addr: [kind, {effect numbers}, records]}.  Streams are keyed by
    address because the arrays share them heavily (42 effects point at the one
    NO OPERATION trio)."""
    out = {}
    for tag, tbl in (("algo", ALGO_TABLE), ("coef", COEF_TABLE)):
        for ptr, effs in kn_table(tbl).items():
            _, recs, ok = walk(KN, KN_BASE, ptr, KN_BASE + len(KN),
                               KN_OPS, min_len=2)
            if not ok:
                continue
            e = out.setdefault(ptr, [tag, set(), recs])
            e[1] |= effs
    return out


def kn_param_records(tbl):
    """Walk one of the two parameter record arrays.

    RECORD TABLE GRAMMAR (DSP_TableWalk_Search, quoted in
    v142/subcpu/subcpu_data_tables.s): a table is a run of records
    [len_hi, len_lo, id, payload...] where len = (len_hi << 8) | len_lo counts
    the WHOLE record; a record whose first byte is 0xF0 ends the table."""
    seen, recs = set(), []
    for ptr in kn_table(tbl):
        if ptr in seen:
            continue
        seen.add(ptr)
        p, guard = ptr, 0
        while guard < 4000:
            guard += 1
            if KN[p - KN_BASE] == 0xF0:
                break
            ln = (KN[p - KN_BASE] << 8) | KN[p + 1 - KN_BASE]
            if ln < 3 or p + ln > KN_BASE + len(KN):
                break
            recs.append((p, ln))
            p += ln
    return len(seen), recs


# --------------------------------------------------------------- WSA1R side
def ws_seeds():
    """Addresses inside the pool that the prom_c image literally points at.

    Two spellings, both literal: a 32-bit little-endian pointer anywhere in the
    image, and the `lda rr,#addr24` form 0xF2 <addr24> <0x30..0x37>."""
    out = set()
    for i in range(len(WC) - 3):
        v = int.from_bytes(WC[i:i + 4], "little")
        if POOL_LO <= v < POOL_HI:
            out.add(v)
    for i in range(1, len(WC) - 4):
        if WC[i - 1] == 0xF2 and 0x30 <= WC[i + 3] <= 0x37:
            v = int.from_bytes(WC[i:i + 3], "little")
            if POOL_LO <= v < POOL_HI:
                out.add(v)
    return out


_WS_CACHE = None


def ws_streams():
    """Tile the pool the way wsa1/notes/gen_prom_c_p7stream_pool.py does, and
    return every object.  Re-derived here rather than imported, so this script
    reads the ROM itself; --selftest checks the counts against that note."""
    global _WS_CACHE
    if _WS_CACHE is not None:
        return _WS_CACHE
    seeds = sorted(s for s in ws_seeds()
                   if s < POOL_DIRLO
                   and walk(WC, WS_BASE, s, POOL_DIRLO, VALID_OPS)[2])
    objs, a = [], POOL_LO
    while a < POOL_DIRLO:
        e, recs, ok = walk(WC, WS_BASE, a, POOL_DIRLO, VALID_OPS)
        if ok:
            objs.append((a, e, "STREAM", recs))
            a = e
        else:
            nxt = min([s for s in seeds if s > a] + [POOL_DIRLO])
            objs.append((a, nxt, "DATA", None))
            a = nxt
    _WS_CACHE = objs
    return objs


def ws_only_streams():
    return [o for o in ws_streams() if o[2] == "STREAM"]


# ===========================================================================
#  grammar
# ===========================================================================
# What each machine's own handler code does with a record, read off the decoded
# source.  These are the CLAIMS the residue test below is allowed to contradict:
#
#   KN5000  DSP_Bytecode_Op02_Groups3_Raw (v142/subcpu/kn5000_subprogram_v142.s)
#           3 head bytes sent, then `dec 3,wa / div wa,3`   -> groups of THREE
#   WSA1R   prom_c sub_F9A86B__F9A9F0 (wsa1/prom_c/p7/p7_module.s:1421)
#           3 head bytes sent, then `dec 3,BC / srl 2,BC`   -> groups of FOUR
#
# and for op 0/1/5 both machines divide the same remainder by 5.  op 3 and op 14
# consume their whole payload; op 4 is a single command byte.
HEAD = {0: 3, 1: 3, 2: 3, 3: 3, 4: 1, 5: 3, 14: 1}
CLAIM = {"KN5000": {0: 5, 1: 5, 2: 3, 5: 5},
         "WSA1R": {0: 5, 1: 5, 2: 4, 5: 5}}


def residue_table(name, recs_by_op):
    print(f"\n  {name}")
    print(f"    {'op':>3} {'recs':>6} {'g=3':>6} {'g=4':>6} {'g=5':>6} "
          f"{'discriminating':>15}  claimed")
    for op in (0, 1, 2, 5):
        rs = recs_by_op.get(op, [])
        if not rs:
            continue
        cnt = {g: 0 for g in (3, 4, 5)}
        disc = 0
        for ln in rs:
            p = ln - 2 - HEAD[op]
            fits = [g for g in (3, 4, 5) if p >= 0 and p % g == 0]
            for g in fits:
                cnt[g] += 1
            if len(fits) == 1:
                disc += 1
        print(f"    {op:>3} {len(rs):>6} {cnt[3]:>6} {cnt[4]:>6} {cnt[5]:>6} "
              f"{disc:>15}  {CLAIM[name].get(op, '-')}")


def cmd_grammar():
    print("=" * 74)
    print("GRAMMAR -- one framer over both corpora")
    print("=" * 74)
    kn = kn_streams()
    objs = ws_streams()
    ws = ws_only_streams()

    print(f"\n  KN5000  {len(kn)} distinct bytecode streams from "
          f"{2 * N_ALGOS} pointer-array entries")
    print(f"  WSA1R   {len(ws)} streams + "
          f"{len([o for o in objs if o[2]=='DATA'])} data objects tile "
          f"0x{POOL_LO:06X}-0x{POOL_DIRLO-1:06X}")

    kop, wop = defaultdict(list), defaultdict(list)
    kall, wall = Counter(), Counter()
    for _, (_, _, recs) in kn.items():
        for _, op, ln in recs:
            kall[op] += 1
            kop[op].append(ln)
    for _, _, _, recs in ws:
        for _, op, ln in recs:
            wall[op] += 1
            wop[op].append(ln)

    print("\n  RECORD OPCODE CENSUS")
    print(f"    {'op':>3} {'KN5000':>8} {'WSA1R':>8}   meaning (each machine's "
          f"own dispatcher)")
    mean = {0: "3 head + groups", 1: "3 head + groups", 2: "3 head + groups",
            3: "3 head + raw tail", 4: "one command byte",
            5: "3 head + groups",
            13: "bus idle + task yield -- KN5000 ONLY, no WSA1R arm",
            14: "1 head byte + raw tail", 15: "END"}
    for op in sorted(set(kall) | set(wall)):
        print(f"    {op:>3} {kall.get(op,0):>8} {wall.get(op,0):>8}   "
              f"{mean.get(op,'?')}")

    print("\n  GROUP-SIZE RESIDUE TEST  (payload = len - 2 - head)")
    residue_table("KN5000", kop)
    residue_table("WSA1R", wop)
    print("""
  READ THE 'discriminating' COLUMN FIRST.  A record whose payload is a multiple
  of 60 is consistent with every group size and votes for nothing.

  ** THE WSA1R op-0 ROW IS CONTAMINATED ** and must not be read as a group-size
  result.  Run the `params` section: most WSA1R "op 0" records are not bytecode
  at all -- they are parameter records, whose 16-bit length field has a zero
  high nibble and so LOOKS like opcode 0 to this framer.""")
    return kn, ws


# ===========================================================================
#  params -- the WSA1R pool's second payload convention
# ===========================================================================
def cmd_params(kn=None, ws=None):
    print("=" * 74)
    print("PARAMS -- the WSA1R pool's SECOND payload convention")
    print("=" * 74)
    print("""
  wsa1/notes/FINDINGS-prom_c-p7-byte-stream-pool.md, section 0:

      "130 of the 297 streams contain at least one record whose payload is not
       a whole number of the interpreter's groups.  Those cannot be what
       P7Stream_Run runs.  The container is the same; the payload convention is
       not, and the routine that reads them has not been found."

  THE SIGNATURE, calibrated on the KN5000 where both kinds are already named.
  A KN5000 parameter record is [len_hi, len_lo, id, payload...]; a VALUE record
  ends on 0x7A and a DESCRIPTOR record does not.""")
    ntv, rv = kn_param_records(PVAL_TABLE)
    ntd, rd = kn_param_records(PDSC_TABLE)
    print(f"\n    {'KN5000 corpus':>22} {'tables':>7} {'records':>8} "
          f"{'translator id':>14} {'end 0x7A':>9}")
    for nm, nt, rs in (("PARAM VALUES", ntv, rv),
                       ("PARAM DESCRIPTORS", ntd, rd)):
        idok = sum(1 for p, ln in rs if KN[p + 2 - KN_BASE] in TRANSLATOR_IDS)
        e7a = sum(1 for p, ln in rs
                  if KN[p + ln - 1 - KN_BASE] == VALUE_TERMINATOR)
        print(f"    {nm:>22} {nt:>7} {len(rs):>8} {idok:>14} {e7a:>9}")
    print("""
  The two signatures separate perfectly on the KN5000: every value record has a
  translator id AND ends 0x7A; every descriptor record has a translator id and
  NEVER ends 0x7A.  That is the instrument.
""")

    if ws is None:
        ws = ws_only_streams()
    tot, e7a = Counter(), Counter()
    for a, e, _, recs in ws:
        for ad, op, ln in recs:
            if op == 0xF:
                continue
            cb = WC[ad + 2 - WS_BASE]
            k = "translator id" if cb in TRANSLATOR_IDS else f"cmd 0x{cb:02X}"
            tot[k] += 1
            if WC[ad + ln - 1 - WS_BASE] == VALUE_TERMINATOR:
                e7a[k] += 1
    print("  APPLIED TO THE WSA1R POOL\n")
    print(f"    {'third byte':>16} {'records':>8} {'end 0x7A':>9}")
    for k in sorted(tot, key=lambda k: -tot[k]):
        print(f"    {k:>16} {tot[k]:>8} {e7a[k]:>9}")
    par = tot["translator id"]
    other = sum(v for k, v in tot.items() if k != "translator id")
    print(f"""
  {par} of the pool's records carry a parameter-translator id, and
  {e7a['translator id']} of those end on 0x7A -- the value/descriptor mixture
  the KN5000 shows.  NOT ONE of the {other} records with a command byte ends on
  0x7A, which is the negative control: the signature could have fired on them
  and does not.

  WHAT THIS DOES AND DOES NOT SAY.  It says the WSA1R pool holds parameter
  records in the KN5000's parameter-record grammar, with the KN5000's own
  translator opcode set -- so the "second consumer" is a parameter-record
  walker, not a second microcode format.  It does NOT locate that walker in the
  WSA1R ROMs; nobody has pointed at the routine.  And three of the four
  published byte-identical runs are KN5000 objects named *_Param_Values, which
  is consistent and is not independent evidence.""")


# ===========================================================================
#  shared -- how much payload the two products share verbatim
# ===========================================================================
def windows(buf, L):
    return {buf[i:i + L] for i in range(len(buf) - L + 1)} if len(buf) >= L \
        else set()


def coverage(buf, S, L):
    if len(buf) < L:
        return 0, 0
    n = len(buf) - L + 1
    return sum(1 for i in range(n) if buf[i:i + L] in S), n


def kn_corpus(tbl, bytecode=True):
    """The bytes of every distinct object one KN5000 pointer array names."""
    out = bytearray()
    for ptr in kn_table(tbl):
        if bytecode:
            _, recs, ok = walk(KN, KN_BASE, ptr, KN_BASE + len(KN),
                               KN_OPS, min_len=2)
            if not recs:
                continue
            ln = recs[-1][0] + recs[-1][2] - ptr
        else:
            p, guard = ptr, 0
            while guard < 4000:
                guard += 1
                if KN[p - KN_BASE] == 0xF0:
                    break
                n = (KN[p - KN_BASE] << 8) | KN[p + 1 - KN_BASE]
                if n < 3 or p + n > KN_BASE + len(KN):
                    break
                p += n
            ln = p - ptr
        out += KN[ptr - KN_BASE:ptr - KN_BASE + ln]
    return bytes(out)


def cmd_shared():
    print("=" * 74)
    print("SHARED -- how much DSP payload the two products carry VERBATIM")
    print("=" * 74)
    print("""
  METHOD.  For a window length L, build the set of every L-byte window of the
  TARGET image, then count how many of the SOURCE corpus's L-byte windows are in
  it.  The null is the same source bytes randomly PERMUTED: that keeps the byte
  histogram and destroys the structure, so a non-zero null would mean the
  measure is counting the alphabet rather than shared content.
""")
    rng = random.Random(20260902)

    pool = WC[POOL_LO - WS_BASE:POOL_DIRLO - WS_BASE]
    print("  DIRECTION 1: the WSA1R prom_c stream pool, sought in the KN5000 "
          "Sub CPU ROM")
    print(f"    pool = {len(pool)} bytes "
          f"(0x{POOL_LO:06X}-0x{POOL_DIRLO-1:06X})")
    print(f"\n    {'L':>5} {'windows':>9} {'found':>9} {'%':>7} {'null':>6}")
    for L in (16, 32, 64, 128):
        S = windows(KN, L)
        h, n = coverage(pool, S, L)
        sh = bytearray(pool)
        rng.shuffle(sh)
        hn, _ = coverage(bytes(sh), S, L)
        print(f"    {L:>5} {n:>9} {h:>9} {100*h/n:>6.1f}% {hn:>6}")

    print("\n  DIRECTION 2: each KN5000 DSP corpus, sought in WSA1R prom_c")
    L = 32
    S = windows(WC, L)
    print(f"    window length {L}\n")
    print(f"    {'KN5000 corpus':>22} {'bytes':>7} {'windows':>8} "
          f"{'found':>7} {'%':>7} {'null':>6}")
    for nm, tbl, bc in (("ALGO  (microprograms)", ALGO_TABLE, True),
                        ("COEF  (coefficients)", COEF_TABLE, True),
                        ("PARAM VALUES", PVAL_TABLE, False),
                        ("PARAM DESCRIPTORS", PDSC_TABLE, False)):
        buf = kn_corpus(tbl, bc)
        h, n = coverage(buf, S, L)
        sh = bytearray(buf)
        rng.shuffle(sh)
        hn, _ = coverage(bytes(sh), S, L)
        print(f"    {nm:>22} {len(buf):>7} {n:>8} {h:>7} "
              f"{100*h/max(n,1):>6.1f}% {hn:>6}")

    print("""
  THE ALGO ROW IS THE LOAD-BEARING ONE.  ALGO holds the DSP MICROPROGRAMS -- the
  op-3 records that carry 36-bit instruction words in 5-byte containers to a
  named I-RAM word address.  A third of that corpus occurring verbatim in the
  other product's ROM, against a null of zero, is firmware-side evidence that
  the two machines execute the SAME microcode: the same instruction encoding,
  the same I-RAM addressing, the same core.

  IT IS STILL NOT A PART NUMBER.  Shared microcode identifies a shared core; it
  cannot distinguish a uPD6383GF from a second source or another member of the
  same family, and no ROM byte in either machine names a chip.

  AND IT IS NOT A CLAIM ABOUT THE PARAM DESCRIPTOR ROW.  That corpus is small
  and scores zero; a zero on a few hundred windows is weak, not a demonstrated
  absence.""")


# ===========================================================================
#  runs
# ===========================================================================
def longest_prefix_in(hay, needle, lo=16):
    """Longest prefix of `needle` (>= lo bytes) occurring in `hay`.

    Monotone in length, so the binary search is exact."""
    if len(needle) < lo or hay.find(needle[:lo]) < 0:
        return 0, -1
    a, b = lo, len(needle)
    while a < b:
        mid = (a + b + 1) // 2
        if hay.find(needle[:mid]) >= 0:
            a = mid
        else:
            b = mid - 1
    return a, hay.find(needle[:a])


def cmd_runs(ws=None, lo=32, show=24):
    print("=" * 74)
    print("RUNS -- the longest verbatim prefix of each WSA1R stream in the "
          "KN5000")
    print("=" * 74)
    print(f"""
  wsa1/notes/FINDINGS-prom_c-p7-is-dsp-effects.md section 3 names FOUR shared
  runs.  They are prefixes of pool streams, not whole streams, so this measures
  the longest prefix (>= {lo} B) of every stream.

  ** THE OBVIOUS PER-ROW CONTROL DOES NOT WORK HERE **, and saying so matters
  more than the table.  "A random run of the same length is not found" is the
  control one would reach for -- and it FAILS, because the two images share so
  much material (see `shared`) that a random pool window often IS found.  Read
  this as an INDEX of where the shared material sits, not as evidence that any
  one row is significant.  `shared` is the instrument whose null holds.
""")
    if ws is None:
        ws = ws_only_streams()
    hits = []
    for a, e, _, recs in ws:
        body = WC[a - WS_BASE:e - WS_BASE]
        n, off = longest_prefix_in(KN, body, lo)
        if n:
            covered = sorted({op for ad, op, ln in recs if ad + ln <= a + n})
            hits.append((a, e - a, n, off + KN_BASE, covered))
    hits.sort(key=lambda h: -h[2])
    print(f"  {len(hits)} of {len(ws)} streams have a prefix of >= {lo} bytes "
          f"in the KN5000 image; longest {hits[0][2] if hits else 0}\n")
    print(f"    {'WSA1R':>9} {'stream':>7} {'shared':>7} {'KN5000':>9}  "
          f"opcodes of the records wholly inside the shared run")
    for a, ln, n, kaddr, ops in hits[:show]:
        print(f"    0x{a:06X} {ln:>7} {n:>7} 0x{kaddr:05X}  {ops}")
    if len(hits) > show:
        print(f"    ... {len(hits)-show} more")
    with2 = [h for h in hits if 2 in h[4]]
    print("\n  THE ONE THING THIS TABLE CAN SETTLE: does any shared run contain "
          "a whole\n  op-2 record, whose group size the two firmwares read "
          "differently (3 vs 4)?")
    if with2:
        print(f"    YES -- {len(with2)} run(s).  The two readings CONTRADICT on "
              f"real bytes and\n    the difference must be resolved before any "
              f"device model interprets op 2.")
        for h in with2[:10]:
            print(f"      WSA1R 0x{h[0]:06X} = KN5000 0x{h[3]:05X} ({h[2]} B)")
    else:
        print("    NO.  Every shared run is built from opcodes the two "
              "firmwares read\n    identically, so the shared bytes are "
              "consistent with BOTH readings and\n    cannot arbitrate the "
              "op-2 difference.  That is a limit of the evidence,\n    not a "
              "finding that op 2 agrees.")
    return hits


# ===========================================================================
#  commands
# ===========================================================================
def cmd_commands(kn=None, ws=None):
    print("=" * 74)
    print("COMMANDS -- the byte that heads each record")
    print("=" * 74)
    print("""
  A record's first payload byte is the one the host sends with the command/data
  qualifier asserted (KN5000: C/D low; WSA1R: P5 bit 3 low), for opcodes 0,1,2,3
  and 5 (head byte 0) and for opcode 14, whose single head byte is the command.
  Opcode 4's ONE payload byte is a bare command.  Opcode 13 has NO payload and
  is excluded.

  Records whose third byte is a parameter-translator id are counted separately:
  those are parameter records, not commands (see `params`).
""")
    if kn is None:
        kn = kn_streams()
    if ws is None:
        ws = ws_only_streams()

    def census(img, base, recs_iter):
        c, par = Counter(), Counter()
        for addr, op, ln in recs_iter:
            if op in (0xF, 13):
                continue
            b = img[addr + 2 - base]
            (par if b in TRANSLATOR_IDS else c)[(op, b)] += 1
        return c, par

    kc, kp = census(KN, KN_BASE,
                    (r for _, (_, _, recs) in kn.items() for r in recs))
    wc, wp = census(WC, WS_BASE,
                    (r for _, _, _, recs in ws for r in recs))

    print(f"    {'op':>3} {'cmd':>5} {'KN5000':>8} {'WSA1R':>8}")
    for op, cb in sorted(set(kc) | set(wc)):
        print(f"    {op:>3}  0x{cb:02X} {kc.get((op,cb),0):>8} "
              f"{wc.get((op,cb),0):>8}")
    print(f"\n    records with a translator id instead: "
          f"KN5000 {sum(kp.values())}, WSA1R {sum(wp.values())}")

    kk = {cb for _, cb in kc}
    ww = {cb for _, cb in wc}

    def fmt(s):
        return "{" + ", ".join(f"0x{c:02X}" for c in sorted(s)) + "}"

    print(f"\n  KN5000 command bytes: {fmt(kk)}")
    print(f"  WSA1R  command bytes: {fmt(ww)}")
    print(f"  in both:      {fmt(kk & ww)}")
    print(f"  KN5000 only:  {fmt(kk - ww)}")
    print(f"  WSA1R only:   {fmt(ww - kk)}")
    print("""
  On the KN5000, command 0x30 is the SECOND effects chip -- IC310, an MN19413 --
  proven in dsp/analysis/second-dsp-and-ready.md.  It is NOT a uPD6383GF command
  and must not be read across.""")
    return kc, wc


# ===========================================================================
#  transport
# ===========================================================================
def bitops(img, sfr):
    """(res, set, bit) counts per bit of one SFR, as a BYTE census.

    TLCS-900 bit manipulation on an 8-bit internal address is
        F0 <addr> <op>,  op = 0xB0|n RES n, 0xB8|n SET n, 0xC8|n BIT n
    (../mame/src/devices/cpu/tlcs900/dasm900.cpp `oprg` tables -- the same
    encoding wsa1/notes/prom_a_p7_link_census.py cites)."""
    r = {n: [0, 0, 0] for n in range(8)}
    for i in range(len(img) - 2):
        if img[i] == 0xF0 and img[i + 1] == sfr:
            op = img[i + 2]
            if 0xB0 <= op <= 0xB7:
                r[op & 7][0] += 1
            elif 0xB8 <= op <= 0xBF:
                r[op & 7][1] += 1
            elif 0xC8 <= op <= 0xCF:
                r[op & 7][2] += 1
    return r


def count(img, pat):
    n, i = 0, 0
    while True:
        i = img.find(pat, i)
        if i < 0:
            return n
        n += 1
        i += 1


def cmd_transport():
    print("=" * 74)
    print("TRANSPORT -- the per-byte handshake, censused from raw bytes")
    print("=" * 74)
    imgs = [("KN5000 subcpu v1.42", KN),
            ("WSA1R prom_c (CPU 2)", WC),
            ("WSA1R prom_a (CPU 1)", open(WS_A, "rb").read()),
            ("WSA1R prom_b (CPU 1)", open(WS_B, "rb").read()),
            ("WSA1R prom_d", open(WS_D, "rb").read())]

    print("\n  THE 0x1F40 TIMEOUT LITERAL -- 8000 poll iterations")
    print("  UPPER BOUND: a 16-bit literal can occur inside data.  The zeroes "
          "are exact.")
    print(f"    {'image':>22}  {'40 1f':>8}  {'1f 40':>8}")
    for nm, img in imgs:
        print(f"    {nm:>22}  {count(img, bytes([0x40, 0x1F])):>8}  "
              f"{count(img, bytes([0x1F, 0x40])):>8}")

    print("""
  KN5000, IC311 command/data send (0x036331; reached through
  DSP_DispatchCommand 0x036A2E and DSP_DispatchData 0x036A4F, which take the
  chip id in BC -- 0 = IC311, 1 = IC310 at 0x03666B / 0x0368BA):

      ld (XSP+0x02),0x1f40                        the timeout
      ei 0x06 ... ei 0x00                         masked to level 6 per step
      release /RD, release /WR, assert /CS(chip), read READY, release /CS
        -> repeat until READY != 0, or the counter reaches 0  => ERROR 1
      release /CS, release /RD, assert /WR, C/D <- COMMAND, assert /CS
      read READY;  if 0  => ERROR 1 (the record is ABANDONED)
                   else  ld (0x68),A              <- PZ, the 8-bit data latch
      release /CS, release /WR, C/D <- DATA

  WSA1R, prom_c P7Byte_SendCmd (0xF9A163), destination-0 arm:

      res 4,(P5)                                  strobe low
      wait P9.3 != 0, <= 0x1f40 spins             peer ready
      set 4,(P5)
      ld (0x0013),byte                            <- P7, the 8-bit data latch
      res 5,(PB) / res 3,(P5) / res 4,(P5)
      wait P9.3 != 0, <= 0x1f40 spins             peer took it
      set 4,(P5) / set 3,(P5) / set 5,(PB)
      on timeout: (0x00F35C) := 1 AND THE BYTE IS SENT ANYWAY
""")

    print("  SFR BIT-MANIPULATION CENSUS (F0 <sfr> <op>) -- UPPER BOUNDS")
    sets = [("KN5000 subcpu", KN,
             [(0x1C, "P7   3=/WR  4=/RD  5=/CS1  6=C/D"),
              (0x38, "PE   6=/CS2 (IC310)"),
              (0x44, "PH   0=READY in  1=/RESET DSP1  2=/RESET DSP2  3=strap"),
              (0x68, "PZ   the 8-bit data latch (written whole)")]),
            ("WSA1R prom_c", WC,
             [(0x13, "P7   the 8-bit data latch (written whole)"),
              (0x0D, "P5   3=cmd/data  4=strobe dest0  5=strobe dest1"),
              (0x06, "P2   7=strobe dest2"),
              (0x1F, "PB   5=data valid  6=enable"),
              (0x19, "P9   3=READY in   0=a strap sampled once")])]
    for nm, img, rows in sets:
        print(f"\n    {nm}")
        for sfr, what in rows:
            r = bitops(img, sfr)
            cells = " ".join(f"b{n}:{r[n][0]}/{r[n][1]}/{r[n][2]}"
                             for n in range(8) if any(r[n]))
            print(f"      SFR 0x{sfr:02X}  {what}")
            print(f"        res/set/bit  {cells or '(none)'}")

    print("\n  ** THE READY LINE IS LIVE ON ONE MACHINE AND DEAD ON THE OTHER **")
    phcr = count(KN, bytes([0x08, 0x46, 0x07]))
    boot = open(os.path.join(ROOT, "original_ROMs",
                             "kn5000_subcpu_boot.ic30"), "rb").read()
    print(f"""
    KN5000: `ld (0x46),0x07` -- PHCR := 0x07, i.e. PH0/1/2 are OUTPUTS --
      occurs {phcr} time(s) in the v1.42 payload and """
          f"{count(boot, bytes([0x08, 0x46, 0x07]))} time(s) in the boot ROM."
          """
      On the TLCS-900 a read of a bit configured as an output returns the
      OUTPUT LATCH, and DSP_Read_Status is `SET 0,(PH)` then `LDCF 0,(PH)` --
      it sets the bit and reads back what it just set.  So the 8000-poll
      handshake ALWAYS SUCCEEDS on the first try and the chip's RDY pin (IC311
      pin 8, schematic p.35, wired to TMP94C241 pin 146 = PH0) is INVISIBLE to
      this firmware.  Established in dsp/analysis/second-dsp-and-ready.md A2;
      re-measured here from the byte pattern in both images.

    WSA1R:  the ready bit is P9 bit 3, and P9 (SFR 0x19) is an INPUT-ONLY port
      on the TMP95C061 -- MAME's tmp95c061.cpp maps 0x000019 with `.r(...)` and
      no writer, and there is no P9CR anywhere in the SFR map
      (wsa1/include/tmp95c061_sfr.inc jumps 0x19 P9 -> 0x1A P8CR).  So this
      poll reads a real external pin, and the emulated machine demonstrably
      sits in the timeout loop when nothing answers it.

    ⚠ SAME ROLE, OPPOSITE CONSEQUENCE FOR A DEVICE MODEL: a KN5000 device need
      not drive its ready pin at all, and a WSA1R device MUST.  Neither fact is
      a property of the chip; both are host-side port-direction decisions.
""")
    print("""
  NEITHER MACHINE BIT-BANGS THE DATA BYTE.  The KN5000 writes the whole port PZ
  (`ld (0x68),A`) and puts its strobes on P7/PE/PH; the WSA1R writes the whole
  port P7 and puts its strobes on P5/P2/PB.  Same shape, different pins -- which
  is exactly what a PRODUCT difference looks like.""")


# ===========================================================================
#  handlers -- how many bytes each opcode arm actually puts ON THE WIRE
# ===========================================================================
# The record format is a HOST-SIDE container.  What the chip sees is the byte
# stream the handler emits: one COMMAND byte (command/data qualifier asserted)
# and then DATA bytes.  Counting the emit sites per arm therefore compares the
# two products at the level a device model actually needs -- and it can differ
# from the group size in the stream, because the host relocates and re-packs.
#
# Both sides are counted FROM THE ROM BYTES, not from the source text.
#
#   KN5000  `call addr24` is 1D <addr24>; the two targets are
#           DSP_DispatchCommand 0x036A2E and DSP_DispatchData 0x036A4F, each of
#           which selects IC311 or IC310 on the chip id in BC.
#   WSA1R   `calr disp16` is 1E <disp16>, target = pc_after + disp; the three
#           targets are P7Byte_SendCmd 0xF9A163, P7Byte_SendData 0xF9A31A and
#           P7Byte_SendArg 0xF9A4B0.  SendData and SendArg are the SAME
#           handshake -- 406 bytes each differing in two bytes, the trace-helper
#           displacement (wsa1/notes/prom_c_dsp_port.py --diff) -- so both are
#           DATA on the wire and are summed.
#
# The arm extents are each dispatcher's own:
#   KN5000  base 0x03C32E + the six offsets of OFFSETS_14739 (0x014739)
#   WSA1R   the seven arm addresses of the chain at 0xF9AD84
KN_DISPATCH = 0x036A2E              # DSP_DispatchCommand
KN_DISPDATA = 0x036A4F              # DSP_DispatchData
KN_ARMS = {0: (0x03C32E, 0x03C568), 1: (0x03C568, 0x03C661),
           2: (0x03C661, 0x03C708), 3: (0x03C708, 0x03C7A1),
           4: (0x03C7A1, 0x03C7BB), 5: (0x03C7BB, 0x03C97B)}
WS_SENDCMD, WS_SENDDATA, WS_SENDARG = 0xF9A163, 0xF9A31A, 0xF9A4B0
WS_ARMS = {0: (0xF9A705, 0xF9A905), 1: (0xF9A905, 0xF9A9F0),
           2: (0xF9A9F0, 0xF9AAFB), 3: (0xF9AAFB, 0xF9AB91),
           4: (0xF9AB91, 0xF9ABA8), 5: (0xF9ABA8, 0xF9AD40),
           14: (0xF9AD40, 0xF9AD84)}


def kn_emits(lo, hi):
    seg = KN[lo - KN_BASE:hi - KN_BASE]
    c = seg.count(bytes([0x1D]) + KN_DISPATCH.to_bytes(3, "little"))
    d = seg.count(bytes([0x1D]) + KN_DISPDATA.to_bytes(3, "little"))
    return c, d


def ws_emits(lo, hi):
    c = d = 0
    for a in range(lo, hi - 2):
        if WC[a - WS_BASE] != 0x1E:
            continue
        disp = int.from_bytes(WC[a + 1 - WS_BASE:a + 3 - WS_BASE],
                              "little", signed=True)
        t = (a + 3 + disp) & 0xFFFFFF
        if t == WS_SENDCMD:
            c += 1
        elif t in (WS_SENDDATA, WS_SENDARG):
            d += 1
    return c, d


def cmd_handlers():
    print("=" * 74)
    print("HANDLERS -- bytes each opcode arm puts ON THE WIRE")
    print("=" * 74)
    print("""
  The record container is HOST-SIDE.  What reaches the chip is one COMMAND byte
  per record and then DATA bytes.  This counts the emit sites in each machine's
  own opcode arm, from the ROM bytes -- the number that a device model has to
  reproduce, and the number the stream's group size does NOT give you.
""")
    print(f"    {'op':>3}  {'KN5000 cmd/data':>16}  {'WSA1R cmd/data':>16}  "
          f"{'verdict':>8}")
    for op in sorted(set(KN_ARMS) | set(WS_ARMS)):
        k = kn_emits(*KN_ARMS[op]) if op in KN_ARMS else None
        w = ws_emits(*WS_ARMS[op]) if op in WS_ARMS else None
        ks = f"{k[0]}/{k[1]}" if k else "-- no arm --"
        wss = f"{w[0]}/{w[1]}" if w else "-- no arm --"
        v = "SAME" if k and w and k == w else ("DIFFER" if k and w else "n/a")
        print(f"    {op:>3}  {ks:>16}  {wss:>16}  {v:>8}")
    print("""
  Read the DATA column as (head bytes) + (branches x bytes per group):

      op 0   2 + 3 x 5      three per-group branches, five wire bytes each
      op 1   2 + 1 x 5      one branch
      op 2   KN5000 2 + 1 x 3   WSA1R 2 + 2 x 3
      op 3   2 + 1          a two-byte address head, then a one-byte tail loop
      op 4   command only, no data at all
      op 5   2 + 2 x 5      two branches

  ★ EVERY ARM BUT op 2 EMITS THE SAME NUMBER OF WIRE BYTES WITH THE SAME BRANCH
    STRUCTURE ON BOTH PRODUCTS.  That is a much stronger statement than "the
    container framing matches": it says the two firmwares hand the chip the same
    shape of traffic for the same record.

  ★ AND op 2 IS RECONCILED RATHER THAN LEFT AS A CONTRADICTION.  The WSA1R's
    op-2 group is FOUR stream bytes but still THREE wire bytes: the extra byte
    is a per-group tag the host consumes to choose between a raw branch and a
    relocated one (prom_c 0xF9AA53 `ld A,(XIX) / cp A,0`), exactly as op 0/1/5
    already do on both machines.  The KN5000's op 2 has no tag and one branch.
    So the difference is in the HOST-SIDE CONTAINER, not in what the chip sees:
    on both products an op-2 record delivers command 0x02 and a whole number of
    THREE-BYTE words.

  ⚠ Opcodes 0x0D and 0x0E are outside the KN5000's offset-table arms and are
    counted separately: 0x0D emits NOTHING (bus idle + task yield, a host
    scheduling directive the chip never sees, and there is no WSA1R arm and no
    0x0D record anywhere in the WSA1R pool), and 0x0E is one command byte plus a
    raw tail loop, matching the WSA1R's op 14 exactly.""")


# ===========================================================================
#  selftest
# ===========================================================================
def selftest():
    fails = []

    def chk(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)

    objs = ws_streams()
    st = [o for o in objs if o[2] == "STREAM"]
    da = [o for o in objs if o[2] == "DATA"]
    nrec = sum(len(o[3]) for o in st)
    print("WSA1R pool, against FINDINGS-prom_c-p7-byte-stream-pool.md")
    chk(len(st) == 297, f"297 streams; got {len(st)}")
    chk(len(da) == 6, f"6 data objects; got {len(da)}")
    chk(sum(o[1] - o[0] for o in st) == 60385,
        f"streams total 60,385 B; got {sum(o[1]-o[0] for o in st)}")
    chk(nrec == 1832, f"1,832 records; got {nrec}")
    chk(sum(1 for o in st for _, op, _ in o[3] if op == 0xF) == 297,
        "297 END records")
    chk(not any(op == 13 for o in st for _, op, _ in o[3]),
        "no opcode 0x0D record anywhere in the WSA1R pool")

    print("\nKN5000 streams, against dsp/README.md and the data-table header")
    dsp2 = set()
    for i in range(N_ALGOS):
        o = ALGO_TABLE - KN_BASE + 4 * i
        ptr = int.from_bytes(KN[o:o + 4], "little")
        _, recs, ok = walk(KN, KN_BASE, ptr, KN_BASE + len(KN),
                           KN_OPS, min_len=2)
        if not ok:
            continue
        for addr, op, ln in recs:
            if op not in (0xF, 13) and KN[addr + 2 - KN_BASE] == 0x30:
                dsp2.add(i)
    chk(dsp2 == {57, 58, 59, 60, 79, 88, 89, 90, 91},
        f"the nine IC310 effects carry command 0x30; got {sorted(dsp2)}")
    chk(len(kn_streams()) == 100,
        f"100 distinct KN5000 bytecode streams; got {len(kn_streams())}")

    print("\nKN5000 parameter records -- the params section's calibration")
    ntv, rv = kn_param_records(PVAL_TABLE)
    ntd, rd = kn_param_records(PDSC_TABLE)
    chk(all(KN[p + 2 - KN_BASE] in TRANSLATOR_IDS for p, _ in rv + rd),
        f"all {len(rv)+len(rd)} parameter records carry a translator id")
    chk(all(KN[p + n - 1 - KN_BASE] == VALUE_TERMINATOR for p, n in rv),
        f"all {len(rv)} VALUE records end on 0x7A")
    chk(not any(KN[p + n - 1 - KN_BASE] == VALUE_TERMINATOR for p, n in rd),
        f"no DESCRIPTOR record ends on 0x7A ({len(rd)} records)")

    print("\nCross-product byte identity, against "
          "FINDINGS-prom_c-p7-is-dsp-effects.md sec.3")
    want = {0xFD7764: (164, 0x007316), 0xFD0C4B: (95, 0x00A933),
            0xFD08CD: (49, 0x00A66C), 0xFD1399: (49, 0x00B499)}
    for addr, (n, koff) in sorted(want.items()):
        chk(KN[koff:koff + n] == WC[addr - WS_BASE:addr - WS_BASE + n],
            f"WSA1R 0x{addr:06X} +{n} == KN5000 file offset 0x{koff:06X}")
    chk(set(want) <= {o[0] for o in st},
        "all four published runs start at a walked stream boundary")

    print("\nHandler emit counts -- the handlers section")
    for op in (0, 1, 3, 4, 5):
        chk(kn_emits(*KN_ARMS[op]) == ws_emits(*WS_ARMS[op]),
            f"op {op}: both products emit "
            f"{kn_emits(*KN_ARMS[op])} (cmd/data)")
    chk(kn_emits(*KN_ARMS[2]) != ws_emits(*WS_ARMS[2]),
        f"op 2 DIFFERS: KN5000 {kn_emits(*KN_ARMS[2])}, "
        f"WSA1R {ws_emits(*WS_ARMS[2])}")
    chk(all(kn_emits(*r)[0] == 1 for r in KN_ARMS.values()),
        "every KN5000 arm emits exactly ONE command byte")
    chk(all(ws_emits(*r)[0] == 1 for r in WS_ARMS.values()),
        "every WSA1R arm emits exactly ONE command byte")

    print("\nTransport")
    chk(count(KN, bytes([0x08, 0x46, 0x07])) >= 1,
        "the KN5000 payload writes PHCR := 0x07 (PH0 an OUTPUT)")
    chk(count(WC, bytes([0x40, 0x1F])) >= 18,
        "prom_c carries the 0x1F40 literal")
    chk(count(KN, bytes([0x40, 0x1F])) >= 1, "the KN5000 carries it too")

    print(f"\n{'ALL PASS' if not fails else str(len(fails)) + ' FAILURE(S)'}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("section", nargs="?", default="all",
                    choices=["all", "grammar", "params", "handlers",
                             "shared", "runs", "commands", "transport"])
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    kn = ws = None
    if a.section in ("all", "grammar"):
        kn, ws = cmd_grammar()
        print()
    if a.section in ("all", "params"):
        cmd_params(kn, ws)
        print()
    if a.section in ("all", "handlers"):
        cmd_handlers()
        print()
    if a.section in ("all", "commands"):
        cmd_commands(kn, ws)
        print()
    if a.section in ("all", "runs"):
        cmd_runs(ws)
        print()
    if a.section in ("all", "transport"):
        cmd_transport()
        print()
    if a.section in ("all", "shared"):
        cmd_shared()


if __name__ == "__main__":
    main()
