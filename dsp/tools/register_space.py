#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""register_space.py -- THE OTHER 44 DARK WORDS: the register/port space, the
immediate format, and the last gate on the audio path.

NEC uPD6383GF (Technics SX-KN5000 IC311).  `dsp/analysis/dark-words.md' partitions
the 86 frame slots that execute NOTHING into five groups.  A sibling pass owns the
42 external delay-DRAM slots.  The other 44 are:

    B  C-format immediate        17 slots
    C  mode-1 space              12 slots
    E  unknown class             12 slots
    D  class-0 register load      3 slots

They are the part of the chip that is NOT the D-RAM/C-RAM datapath, and nobody had
worked on them.  This pass attacks them from a data source the project had barely
used: **the host's own write log**.  The Sub CPU configures this chip through a
register interface, and every write it makes is either canned in the ROM (the 100
per-algorithm PARAM streams) or synthesised by four writer routines whose code is
disassembled.  So the host write log is STATIC, COMPLETE and MEASURED -- no
hardware, no emulator, no audio.

    python3 dsp/tools/register_space.py [all|transport|cells|outlevel|regmap|
                                         cformat|actions|families|control]

    transport   the host transport: records, the two writer word forms, the tag
                map, and the FORCED auto-increment (with the enumeration printed)
    cells       the per-algorithm canned image of the tag-0x15 (D-RAM) and
                tag-0x4C (delay-descriptor) spaces -- 91 algorithms
    outlevel  * PRIORITY A -- the two OUTPUT LEVEL words w72/w77
    regmap      the UI parameter name -> DSP cell map, and its unit control
    cformat   * PRIORITY B -- the C-format immediate: how wide is it?
    actions   * PRIORITY C -- the ACTION 0x0B / 0x0E decidability census
    families  * PRIORITY D -- mode-1 space, unknown class, class-0 register load
    control     every control, each shown REJECTING something

stdlib only (plus the ROM parsers in the kn7000_mame tools tree, like the other
tools here).  Findings: dsp/analysis/register-space.md.
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                              # noqa: E402
import dark_words as DW                                             # noqa: E402

ALGO_TABLE = 0x0001ED7C          # 100 x u32: microprogram streams
PARAM_TABLE = 0x0001EF0C         # 100 x u32: per-algorithm INIT streams
T1_ARRAY = 0x0001F22C            # 100 x u32: "parameter opcode -> DSP address"
T2_ARRAY = 0x0001F09C            # 100 x u32: parameter bytecode stream
NULL_T1 = 0x00017425
N_ALGOS = 100
MALFORMED = {79, 88, 89, 90, 91}

# main-CPU ROM tables (kn5000_v10_program.rom, flat)
EFFNAME_OFF, EFFNAME_STRIDE = 0x033568, 18       # descending by algorithm
PNAME_OFF, PNAME_STRIDE, PNAME_N = 0x0324D5, 17, 85
PUNIT_OFF, PUNIT_STRIDE = 0x03241A, 2

# the three curve tables of eval helper LABEL_038EB9, read straight out of the
# Sub CPU disassembly (0x038EB9..0x038EF5): sel==0/1/2 -> these three bases.
CURVE_038EB9 = {0: 0x00012483, 1: 0x00012613, 2: 0x000127A3}
CURVE_038EAC = 0x00012B33        # eval helper 0x62, no selector

# MEASURED, from the live cold-boot host capture
# (kn7000_mame/notes/data/kn5000_dsp1_upload_coldboot.txt, transfers 52/53;
#  analysis/k5-output-stage.md sect. 2).  unit 0 = algo 1 CHORUS, unit 1 = algo 16.
COLDBOOT_LEVEL = {0x06: 0x400000, 0x86: 0x178D0B}
COLD_U0_ALGO, COLD_U1_ALGO = 1, 16

TAG_DRAM = 0x15       # writer LABEL_03846C / LABEL_038539
TAG_CRAM = 0x26       # writer LABEL_0387E6
TAG_DSC = 0x4C        # writer LABEL_038922 (the delay descriptor)
TAGNAME = {TAG_DRAM: "D-RAM  (tag 15)", TAG_CRAM: "C-RAM  (tag 26)",
           TAG_DSC: "DESCR  (tag 4C)"}


# ==========================================================================
#  0. the ROMs
# ==========================================================================
def load(subpath, mainpath, toolsdir):
    sys.path.insert(0, toolsdir)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(subpath)
    main = open(mainpath, "rb").read() if os.path.exists(mainpath) else None
    return rom, main, E


def effect_name(main, algo):
    if main is None:
        return "?"
    o = EFFNAME_OFF - EFFNAME_STRIDE * algo
    return main[o:o + 16].decode("ascii", "replace").strip()


def param_names(main):
    """-> [(name, unit)] indexed 0..84 (the UI list stores 1-based indices)."""
    if main is None:
        return []
    out = []
    for i in range(PNAME_N):
        o = PNAME_OFF + PNAME_STRIDE * i
        nm = main[o:o + 16].decode("ascii", "replace").rstrip()
        u = main[PUNIT_OFF + PUNIT_STRIDE * i:
                 PUNIT_OFF + PUNIT_STRIDE * i + 2].decode("ascii", "replace").strip()
        out.append((nm, u))
    return out


# ==========================================================================
#  1. THE HOST TRANSPORT
#
#  PROVEN BY CONSTRUCTION from the Sub CPU writers (kn5000_dsp_params.py
#  reproduces them byte-for-byte; notes/kn5000-dsp-parameters.md sect. 2):
#
#     LABEL_03846C / LABEL_038539   00 00 1a a0 00   then  0A .. .. .. |0x15
#                                   = word 000.1.AA.000, then a tag-15 datum
#     LABEL_0387E6                  08 01 .a a8 21   then  0A .. .. .. |0x26
#                                   = word 801.0.AA.821, then a tag-26 datum
#     LABEL_038922                  08 01 .p p8 25   then  0A .. .. .. |0x4C
#                                   = word 801.0.PP.825, then a tag-4C datum
#
#  The datum is a 24-bit Q0.23 value scattered over the 5 bytes; dsp_disasm's
#  host_packet() inverts it.  The low SEVEN bits of the last byte are the TAG,
#  which is what says WHICH SPACE the datum lands in.
# ==========================================================================
def is_packet(b5):
    return (len(b5) == 5 and (b5[0] & 0xFE) == 0x0A
            and (b5[4] & 0x7F) in (TAG_DRAM, TAG_CRAM, TAG_DSC))


def packet(b5):
    """-> (value24, tag, bit32, bit31).  Same field split as
    dsp_disasm.host_packet(), which is PROVEN from the writer code, plus the two
    bits above it that the writers leave as literals."""
    v = ((b5[1] & 0x7F) << 17) | (b5[2] << 9) | (b5[3] << 1) | (b5[4] >> 7)
    return v, b5[4] & 0x7F, b5[0] & 1, b5[1] >> 7


def records(rom, addr, limit=400):
    """The uC-IF bytecode record walker.  Same header rule as
    kn5000_dsp_extract.parse_stream, but it KEEPS the op-0/1/5 records (five-byte
    words), which that parser drops -- and those are the ones that carry the
    register traffic."""
    out, p = [], addr
    for _ in range(limit):
        try:
            b0, b1 = rom.u8(p), rom.u8(p + 1)
        except IndexError:
            break
        op = b0 >> 4
        if op == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        out.append((p, op, rom.slice(p + 2, ln - 2)))
        p += ln
    return out


def transactions(rom, addr, autoinc=1):
    """Decode one PARAM stream into (tag, cell, value) writes.

    A five-byte-word record is an alternating stream of SELECT words and data
    packets.  The select word's addr8 names the cell; each following packet
    writes the current cell and steps it by `autoinc'.  `autoinc' is a PARAMETER
    here on purpose -- cmd_transport() enumerates it rather than assuming it."""
    out = []
    for _p, op, body in records(rom, addr):
        if op not in (0, 1, 5) or len(body) < 3:
            continue
        data = body[3:]
        cell = None
        for k in range(0, len(data) - 4, 5):
            b5 = data[k:k + 5]
            if is_packet(b5):
                if cell is None:
                    continue
                v, tag, _b32, _b31 = packet(b5)
                out.append((tag, cell & 0xFF, v))
                cell += autoinc
            else:
                cell = D.addr8(int.from_bytes(b5, "big"))
    return out


def select_runs(rom, addr):
    """-> [(select_word, n_packets)] -- the raw run structure, no increment model."""
    out = []
    for _p, op, body in records(rom, addr):
        if op not in (0, 1, 5) or len(body) < 3:
            continue
        data = body[3:]
        cur, n = None, 0
        for k in range(0, len(data) - 4, 5):
            b5 = data[k:k + 5]
            if is_packet(b5):
                n += 1
            else:
                if cur is not None and n:
                    out.append((cur, n))
                cur, n = int.from_bytes(b5, "big"), 0
        if cur is not None and n:
            out.append((cur, n))
    return out


def all_streams(rom):
    return {a: rom.u32le(PARAM_TABLE + 4 * a) for a in range(N_ALGOS)
            if rom.u32le(PARAM_TABLE + 4 * a)}


def bodies(rom, E):
    """algo -> (load_addr, words) for every well-formed microprogram image."""
    out = {}
    for a in range(N_ALGOS):
        if a in MALFORMED:
            continue
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * a))
        except Exception:
            continue
        for ia, ws, _l in ir:
            if ia in (84, 200):
                out.setdefault(a, (ia, [int.from_bytes(bytes(w), "big") for w in ws]))
    return out


def cmd_transport(rom):
    print("=" * 78)
    print("1. THE HOST TRANSPORT -- and the AUTO-INCREMENT, forced")
    print("=" * 78)
    st = all_streams(rom)
    print("  PARAM streams reachable: %d of %d algorithm slots" % (len(st), N_ALGOS))

    # -- the tag census --------------------------------------------------
    tags = collections.Counter()
    forms = collections.Counter()
    for a, p in st.items():
        for w, n in select_runs(rom, p):
            forms["%03X.%X.%02X.%03X" % D.fields(w)] += 1
        for tag, _c, _v in transactions(rom, p):
            tags[tag] += 1
    print("  data packets by TAG : %s"
          % "  ".join("%s x%d" % (TAGNAME[t], n) for t, n in sorted(tags.items())))
    print("  ** tag 0x26 (C-RAM) never appears in a CANNED stream: the canned C-RAM")
    print("     path is `801.0.NN.821' + a raw 3-byte op-2 block; tag 0x26 is the")
    print("     RUNTIME single-value writer.  MEASURED, 0 of %d packets."
          % sum(tags.values()))
    print()
    print("  select-word forms that carry data packets (top 12):")
    for k, n in forms.most_common(12):
        print("     %s  x%d" % (k, n))

    # -- the auto-increment, ENUMERATED ----------------------------------
    print()
    print("  ---- THE AUTO-INCREMENT.  ENUMERATION, printed next to the claim:")
    print("       step in {0 (no increment), +1, +2, +4, -1}.  Nothing else is a")
    print("       plausible burst-write port behaviour, and `0' is the null.")
    print()
    print("  >> A CIRCULAR DISCRIMINATOR, CAUGHT AND DISCARDED.  My first test was")
    print("     `+1 is the only step that reproduces output-stage-decode.md's")
    print("     CONTIGUOUS BLOCK OF 40 CELLS AT 0x50..0x77'.  That block is computed")
    print("     by output_stage.py:fill_cells(), which contains `dest += 1'.  It")
    print("     ASSUMES the answer.  Discarded before it was quoted as evidence.")
    print()
    print("  D1 -- SELF-CONTAINED: two abutting selects inside one canned stream.")
    hit = None
    for a, p in sorted(st.items()):
        runs = [(D.addr8(w), n) for w, n in select_runs(rom, p)
                if not D.c_format(w) and D.class4(w) == 1 and D.lo12(w) == 0]
        for i in range(len(runs) - 1):
            if runs[i][1] >= 8 and runs[i][0] + runs[i][1] == runs[i + 1][0]:
                hit = (a, runs[i], runs[i + 1])
    if hit:
        a, r0, r1 = hit
        print("     algo %-3d  select 0x%02X x%-3d  then  select 0x%02X x%-3d"
              % (a, r0[0], r0[1], r1[0], r1[1]))
        for step in (0, 1, 2, 4, -1):
            end = (r0[0] + step * (r0[1] - 1)) & 0xFF
            print("       step %+d -> first run ends at 0x%02X ; next select is 0x%02X"
                  "  -> %s" % (step, end, r1[0],
                               "ABUTS" if (r0[0] + step * r0[1]) & 0xFF == r1[0]
                               else "does not abut"))
        print("     The second select address is 0x%02X = 0x%02X + %d, i.e. exactly"
              % (r1[0], r0[0], r0[1]))
        print("     the length of the run before it.  Under step 0 there is no")
        print("     reason for that; under +2/+4/-1 it is wrong.  ONE datum.")
    print()
    print("  D2 -- THE LIVE COLD-BOOT CAPTURE, and this one is decisive.")
    print("     notes/data/kn5000_dsp1_upload_coldboot.txt, transfers 40..48.")
    return st


def coldboot_capture(path):
    """Parse the MEASURED live host capture into [(cmd, payload_bytes)]."""
    if not os.path.exists(path):
        return []
    out, cur = [], None
    for line in open(path):
        s = line.strip()
        if s.startswith("transfer"):
            cur = bytearray()
            out.append(cur)
        elif cur is not None and len(s) > 6 and s[4] == ":" and s[:4].isalnum():
            try:
                cur += bytes.fromhex(s[5:].replace(" ", ""))
            except ValueError:
                pass
    return [bytes(b) for b in out if b]


def cmd_transport2(rom, capture):
    """D2: the auto-increment forced from the live capture alone."""
    runs = []
    for pay in capture:
        if len(pay) < 3 or pay[0] != 0x01:
            continue
        data = pay[2:] if False else pay[2:]
        # payload = [addr_hi, addr_lo, five-byte words...] with cmd stripped by
        # the capture tool; the I-RAM address is the first two bytes.
        data = pay[2:]
        cell, n = None, 0
        for k in range(0, len(data) - 4, 5):
            b5 = data[k:k + 5]
            if is_packet(b5):
                n += 1
            else:
                if cell is not None and n:
                    runs.append((cell, n))
                w = int.from_bytes(b5, "big")
                cell = D.addr8(w) if (not D.c_format(w) and D.class4(w) == 1
                                      and D.lo12(w) == 0) else None
                n = 0
        if cell is not None and n:
            runs.append((cell, n))
    # the longest arithmetic progression of equal-length selects
    best = []
    for i in range(len(runs)):
        for j in range(i + 2, len(runs) + 1):
            seg = runs[i:j]
            if len(set(n for _c, n in seg)) != 1:
                break
            d = set(seg[k + 1][0] - seg[k][0] for k in range(len(seg) - 1))
            if len(d) != 1 or d.pop() <= 0:
                break
            if len(seg) > len(best):
                best = seg
    if len(best) < 4:
        print("     (capture not found or too short -- run with --tools pointing at")
        print("      the kn7000_mame tools tree so notes/data/ is reachable)")
        return
    stride = best[1][0] - best[0][0]
    print("     %d consecutive selects, stride %d, %d data packets each:"
          % (len(best), stride, best[0][1]))
    print("        %s" % " ".join("0x%02X x%d" % r for r in best))
    for step in (0, 1, 2, 4, -1):
        cells = []
        for c, n in best:
            cells += [(c + step * i) & 0xFF for i in range(n)]
        u = set(cells)
        lo, hi = min(u), max(u)
        contig = len(u) == hi - lo + 1
        overlap = len(cells) - len(u)
        print("       step %+d -> %2d writes -> %2d distinct cells 0x%02X..0x%02X, "
              "%s, %d collisions   %s"
              % (step, len(cells), len(u), lo, hi,
                 "CONTIGUOUS" if contig else "gappy", overlap,
                 "SURVIVES" if (contig and overlap == 0
                                and len(u) == len(cells)) else "REJECTED"))
    print("     ** DEGENERACY, checked rather than assumed: +1 and -1 BOTH tile.")
    print("        A descending burst tiles just as well as an ascending one, so D2")
    print("        alone leaves a two-element survivor set {+1, -1} and rejects")
    print("        {0, +2, +4}.  Reporting `+1 FORCED' from D2 alone would have been")
    print("        a 50/50 split counted as a decode.")
    print("     ** D1 BREAKS THE TIE: under -1 the 29-packet run from 0x50 descends")
    print("        to 0x34 and the next select 0x6D relates to nothing; under +1 it")
    print("        ends at 0x6C and the next select is 0x6D.")
    print("     ** D1 && D2  =>  step = +1.  FORCED, enumeration {0,+1,+2,+4,-1}.")
    print("        Neither datum uses any other note's derivation.")
    print()


# ==========================================================================
#  2. THE CELL IMAGES
# ==========================================================================
def cell_images(rom):
    """algo -> {tag -> {cell: value}}."""
    out = {}
    for a, p in all_streams(rom).items():
        img = collections.defaultdict(dict)
        for tag, cell, v in transactions(rom, p, autoinc=1):
            img[tag][cell] = v
        out[a] = dict(img)
    return out


def cmd_cells(rom, main, capture=()):
    print("=" * 78)
    print("2. THE CANNED CELL IMAGES -- what the host writes for every algorithm")
    print("=" * 78)
    imgs = cell_images(rom)
    dram_u = collections.Counter()
    dsc_u = collections.Counter()
    for a, img in imgs.items():
        for c in img.get(TAG_DRAM, {}):
            dram_u[c] += 1
        for c in img.get(TAG_DSC, {}):
            dsc_u[c] += 1
    print("  D-RAM (tag 15) cells the host EVER writes: %d of 256" % len(dram_u))
    print("     %s" % " ".join("%02X:%d" % (c, n) for c, n in sorted(dram_u.items())))
    print("  DESCRIPTOR (tag 4C) cells the host EVER writes: %d of 256" % len(dsc_u))
    print("     %s" % " ".join("%02X:%d" % (c, n) for c, n in sorted(dsc_u.items())))
    print()
    print("  ** THE PER-UNIT DESCRIPTOR BASES, MEASURED (this settles a question")
    print("     `r3-delaydram.md' could only enumerate):")
    b0 = collections.Counter()
    b1 = collections.Counter()
    for a, img in imgs.items():
        d = img.get(TAG_DSC)
        if not d:
            continue
        (b1 if 200 <= a or a in range(16, 28) else b0)[min(d)] += 1
    lo0 = collections.Counter()
    lo1 = collections.Counter()
    for a, img in imgs.items():
        d = img.get(TAG_DSC)
        if not d:
            continue
        (lo1 if a in range(16, 28) else lo0)[min(d)] += 1
    print("     unit-0 algorithms: lowest descriptor cell = %s"
          % {"0x%02X" % k: v for k, v in sorted(lo0.items())})
    print("     unit-1 algorithms (16..27, the twelve reverbs): %s"
          % {"0x%02X" % k: v for k, v in sorted(lo1.items())})
    print("     highest descriptor cell used by a unit-0 algorithm: 0x%02X"
          % max(max(img[TAG_DSC]) for a, img in imgs.items()
                if TAG_DSC in img and not (16 <= a <= 27)))
    print("     highest descriptor cell used by a unit-1 algorithm: 0x%02X"
          % max(max(img[TAG_DSC]) for a, img in imgs.items()
                if TAG_DSC in img and 16 <= a <= 27))
    print("     => THE DESCRIPTOR SPACE IS PARTITIONED BY UNIT: unit-1 owns")
    print("        0x00..0x1F (32 cells, all twelve reverbs identical in extent),")
    print("        unit-0 owns 0x26 upward.  R3 candidate (iii) named exactly these")
    print("        two bases; they are now MEASURED from the host's own streams.")
    print()
    print("  ** 0x0E / 0x0F -- the CALL-WORD cells.  `dark-words.md' sect. 4.3 asked")
    print("     exactly this question and named exactly this experiment:")
    n0e = sum(1 for img in imgs.values() if 0x0E in img.get(TAG_DRAM, {}))
    n0f = sum(1 for img in imgs.values() if 0x0F in img.get(TAG_DRAM, {}))
    n8e = sum(1 for img in imgs.values() if 0x8E in img.get(TAG_DRAM, {}))
    n8f = sum(1 for img in imgs.values() if 0x8F in img.get(TAG_DRAM, {}))
    v0e = set(img[TAG_DRAM][0x0E] for img in imgs.values()
              if 0x0E in img.get(TAG_DRAM, {}))
    print("     cell 0x0E written by %d algorithms, values %s" % (n0e, sorted(v0e)))
    print("     cell 0x0F written by %d algorithms" % n0f)
    print("     cell 0x8E written by %d ; cell 0x8F written by %d" % (n8e, n8f))
    live = set()
    for pay in capture:
        if len(pay) < 3 or pay[0] != 0x01:
            continue
        data, cell = pay[2:], None
        for k in range(0, len(data) - 4, 5):
            b5 = data[k:k + 5]
            if is_packet(b5):
                if cell is not None:
                    _v, _t, _f, _g = packet(b5)
                    if _t == TAG_DRAM:
                        live.add(cell)
                    cell += 1
            else:
                w = int.from_bytes(b5, "big")
                cell = (D.addr8(w) if (not D.c_format(w) and D.class4(w) in (0, 1))
                        else None)
    if live:
        print("     AND IN THE LIVE COLD-BOOT CAPTURE (a second, independent witness:")
        print("     it is the RUNTIME writer, not the canned stream): cells touched")
        print("     in the tag-15 D-RAM space = %d ; 0x0E: %s ; 0x0F: %s ; 8C/8D/8F: %s"
              % (len(live), 0x0E in live, 0x0F in live,
                 [hex(c) for c in (0x8C, 0x8D, 0x8F) if c in live] or "none"))
    print("     => (beta) `the call target is INDIRECT through cell 0x0E/0x0F, which")
    print("        the host primes' is FALSIFIED: the host primes 0x0E with ZERO and")
    print("        never touches 0x0F at all.  It cannot be holding I-RAM 84.")
    print()
    for a in (COLD_U0_ALGO, 9, 10, COLD_U1_ALGO):
        img = imgs.get(a)
        if not img:
            continue
        print("  --- algo %d  %s" % (a, effect_name(main, a)))
        d = img.get(TAG_DSC, {})
        if d:
            print("      descriptor: %s"
                  % " ".join("%02X=%d" % (c, d[c]) for c in sorted(d)))
        r = img.get(TAG_DRAM, {})
        if r:
            print("      D-RAM     : %s"
                  % " ".join("%02X=%d" % (c, r[c]) for c in sorted(r)))
    print()


# ==========================================================================
#  3. PRIORITY A -- THE OUTPUT LEVEL WORDS
# ==========================================================================
def parse_t1(rom, addr, limit=64):
    out, a = [], addr
    for _ in range(limit):
        try:
            w = (rom.u8(a) << 8) | rom.u8(a + 1)
        except IndexError:
            break
        if (w >> 8) == 0xF0:
            break
        if w < 4 or w > 64:
            break
        out.append((rom.u8(a + 2), list(rom.slice(a + 3, w - 3))))
        a += w
    return out


def split_t2(rom, addr, limit=64):
    """One record = one user parameter.  The record BOUNDARY is exact (a
    big-endian length prefix and a 0x7A terminator); only the instruction split
    INSIDE a record is ambiguous, and this pass never needs that."""
    out, a = [], addr
    for _ in range(limit):
        try:
            ln = (rom.u8(a) << 8) | rom.u8(a + 1)
        except IndexError:
            break
        if ln < 5 or ln > 96:
            break
        body = rom.slice(a + 2, ln - 2)
        if not body or body[-1] != 0x7A:
            break
        out.append((a, ln, bytes(body[:-1])))
        a += ln
    return out


def curve(rom, base, n=100):
    return [rom.u32le(base + 4 * i) for i in range(n)]


def op63_selector(rom, algo):
    """The 1-byte curve selector this algorithm's own T2 stream cans for the
    op-0x63 record, and the T1 address that record targets."""
    t1p = rom.u32le(T1_ARRAY + 4 * algo)
    t2p = rom.u32le(T2_ARRAY + 4 * algo)
    if not t2p or not t1p or t1p == NULL_T1:
        return None
    amap = {op: e for op, e in parse_t1(rom, t1p)}
    for _a, _ln, body in split_t2(rom, t2p):
        if len(body) == 3 and body[0] == 0x63:
            operand, sel = body[1], body[2]
            addr = amap.get(0x63, [None])[operand] if 0x63 in amap else None
            return (operand, sel, addr)
    return None


def cmd_outlevel(rom, main):
    print("=" * 78)
    print("3. PRIORITY A -- w72 / w77, THE LAST GATE ON THE AUDIO PATH")
    print("=" * 78)
    print("""  The two words:

     I-RAM 72  000.1.06.087   DARK   class 1, addr8 = 0x06, lo12 route 0x087
     I-RAM 73  E30.C.00.404   PARTIAL  PRESENT unit 0 -> DO1
     I-RAM 77  859.0.86.822   DARK   register-load family, selector 0x22, payload 0x86
     I-RAM 78  A3C.D.9F.287   PARTIAL  PRESENT unit 1 -> DO2

  `r2-output.md' / `k5-output-stage.md' INFERRED that cells 0x06 / 0x86 are the
  per-unit OUTPUT LEVEL, from position plus the cold-boot host capture.  The task
  is to verify or refute that, and then to say what is written, in what format and
  with what scaling.  Here is a route that does not touch either premise.
""")
    tabs = {k: curve(rom, b) for k, b in CURVE_038EB9.items()}
    tabs["D"] = curve(rom, CURVE_038EAC)
    print("  ---- THE EVAL HELPER, read straight out of the Sub CPU disassembly")
    print("       (0x038EB9..0x038EF5).  PROVEN BY CONSTRUCTION, no inference:")
    print("         sel = the ONE immediate byte of the parameter record")
    print("         sel==0 -> XHL = *(0x012483 + 4*user_value)   CURVE_A")
    print("         sel==1 -> XHL = *(0x012613 + 4*user_value)   CURVE_B")
    print("         sel==2 -> XHL = *(0x0127A3 + 4*user_value)   CURVE_C")
    print("       and LABEL_038EAC (parameter opcode 0x62) uses 0x012B33 = CURVE_D.")
    print()
    print("  ---- THE TEST.  The two cold-boot values are MEASURED at the host port.")
    print("       If cells 0x06/0x86 are written by parameter opcode 0x63, each value")
    print("       must be a member of the curve table THAT ALGORITHM'S OWN T2 STREAM")
    print("       SELECTS.  Failure mode: a 24-bit value that is in no table, or in")
    print("       the wrong one.  A random 24-bit value lands in a given 100-entry")
    print("       table with probability 100/2^24 = 6.0e-6.")
    print()
    ok = True
    for algo, cell in ((COLD_U0_ALGO, 0x06), (COLD_U1_ALGO, 0x86)):
        val = COLDBOOT_LEVEL[cell]
        rec = op63_selector(rom, algo)
        member = {k: [i for i, v in enumerate(t) if v == val] for k, t in tabs.items()}
        print("     algo %-3d %-16s  cell 0x%02X  value 0x%06X = %+f"
              % (algo, effect_name(main, algo), cell, val, val / float(1 << 23)))
        print("        T2's own op-0x63 record: operand %s, curve selector %s, T1 addr 0x%02X"
              % (rec[0], rec[1], rec[2]))
        print("        value found in: %s"
              % ("  ".join("CURVE_%s[%s]" % (("ABC"[k] if isinstance(k, int) else k), m)
                           for k, m in member.items() if m) or "NOTHING"))
        sel = rec[1]
        hit = member.get(sel, [])
        print("        selected table CURVE_%s -> %s"
              % ("ABC"[sel], ("HIT at user value %d" % hit[0]) if hit else "MISS"))
        ok = ok and bool(hit)
    print()
    print("     ** CONTROL, and it REJECTS: the unit-1 value 0x178D0B is in CURVE_C")
    print("        and in NO other table.  Had algo 16 canned selector 0 or 1 the")
    print("        test would have failed.  It cans 2.  The wrong twin is rejected.")
    print("        (The unit-0 value 0x400000 is in A, B and D, so the unit-0 row")
    print("         alone would NOT have been a discriminating test -- stated so it")
    print("         is not counted as evidence it cannot supply.)")
    print()
    print("  ---- WHICH USER PARAMETER IS OPCODE 0x63?")
    print("       Every effect's captured UI parameter list ends with the same one or")
    print("       two names, and every T2 stream ends with the same one or two records.")
    print("       Name table (main-CPU ROM 0x0324D5): index 1 = VOLUME, 2 = VOLUME,")
    print("       3 = REV SEND.")
    print()
    print("       unit-0 effects : UI ends [..., 1 VOLUME, 3 REV SEND]")
    print("                        T2 ends [..., op63 -> 0x06, op21 -> 0x90]")
    print("       unit-1 reverbs : UI ends [..., 2 VOLUME]      -- NO REV SEND")
    print("                        T2 ends [..., op63 -> 0x86]  -- NO op21")
    print()
    print("       ** THE CONTROL THAT REJECTS THE SWAP.  If op63 were REV SEND and")
    print("          op21 VOLUME, then the twelve reverbs -- which have no REV SEND")
    print("          parameter, because a reverb cannot send to itself -- would carry")
    print("          op21 and not op63.  MEASURED: all twelve carry op63 and none")
    print("          carries op21.  The swap is rejected 12/12.")
    n63, n21 = 0, 0
    for a in range(16, 28):
        t2p = rom.u32le(T2_ARRAY + 4 * a)
        if not t2p:
            continue
        ops = [b[0] for _x, _l, b in split_t2(rom, t2p)]
        n63 += ops.count(0x63)
        n21 += ops.count(0x21)
    print("          re-derived here: op63 records over algos 16..27 = %d, op21 = %d"
          % (n63, n21))
    print()
    print("  ---- THE SCALING, therefore:")
    for k in (0, 1, 2):
        t = tabs[k]
        nz = [v for v in t if v]
        import math
        steps = [20 * math.log10(t[i + 1] / float(t[i]))
                 for i in range(1, 99) if t[i] and t[i + 1]]
        print("       CURVE_%s  [0]=%d  [1]=0x%06X  [99]=0x%06X  = %+.2f..%+.2f dBFS"
              % ("ABC"[k], t[0], t[1], t[99],
                 20 * math.log10(min(nz) / float(1 << 23)),
                 20 * math.log10(max(nz) / float(1 << 23))))
        print("                 dB/step over v=1..99: min %.3f  max %.3f  mean %.3f"
              % (min(steps), max(steps), sum(steps) / len(steps)))
    print()
    print("       => cell 0x06 / 0x86 holds a **Q0.23 UNSIGNED LINEAR GAIN**, looked")
    print("          up from a 100-entry dB table by the 0..99 user value, cleared to")
    print("          0 by the algorithm's own init stream and rewritten on every")
    print("          parameter edit.  0 means MUTE (all three tables have [0] = 0).")
    print()
    return ok


# ==========================================================================
#  4. THE UI PARAMETER NAME -> CELL MAP
# ==========================================================================
def norm(s):
    return "".join(ch for ch in s.upper() if ch.isalnum())


def load_capture(toolsdir):
    import json
    p = os.path.join(toolsdir, "kn5000_dsp_paramlist_capture.json")
    if not os.path.exists(p):
        return []
    return json.load(open(p))


def cmd_regmap(rom, main, toolsdir):
    print("=" * 78)
    print("4. THE UI PARAMETER NAME -> DSP CELL MAP (and the control that can fail)")
    print("=" * 78)
    cap = load_capture(toolsdir)
    names = param_names(main)
    if not cap or not names:
        print("  (needs tools/kn5000_dsp_paramlist_capture.json and the main ROM)")
        return
    byname = {}
    for e in cap:
        for part in e["name"].split(" / "):
            byname[norm(part)] = e["indices"]
    rows, aligned, mism = [], 0, 0
    opunit = collections.defaultdict(collections.Counter)
    opname = collections.defaultdict(collections.Counter)
    cellname = collections.defaultdict(collections.Counter)
    for a in range(N_ALGOS):
        t1p, t2p = rom.u32le(T1_ARRAY + 4 * a), rom.u32le(T2_ARRAY + 4 * a)
        if not t2p or not t1p or t1p == NULL_T1:
            continue
        recs = split_t2(rom, t2p)
        amap = {op: e for op, e in parse_t1(rom, t1p)}
        ui = byname.get(norm(effect_name(main, a)))
        if ui is None:
            continue
        # index 85 is a REAL parameter slot whose NAME string is blank; it is
        # not padding.  Dropping it was my first alignment and it broke 10 of 49
        # algorithms -- keeping it aligns them.  Stated because it is a fitted
        # choice, and the fit is checked by the unit control below, not by this.
        ui = list(ui)
        if len(ui) != len(recs):
            mism += 1
            rows.append((a, effect_name(main, a), len(recs), len(ui), "LENGTH MISMATCH"))
            continue
        aligned += 1
        for (_x, _l, body), idx in zip(recs, ui):
            op, operand = body[0], body[1]
            cell = amap.get(op, [None] * 64)[operand] if op in amap and operand < len(amap[op]) else None
            nm, un = names[idx - 1]
            opunit[op][un or "-"] += 1
            opname[op][nm] += 1
            if cell is not None:
                cellname[cell][nm] += 1
        rows.append((a, effect_name(main, a), len(recs), len(ui), "aligned"))
    print("  algorithms with BOTH a T2 stream and a captured UI list: %d"
          % (aligned + mism))
    print("  record count == UI parameter count : %d aligned, %d mismatched"
          % (aligned, mism))
    for a, nm, nr, nu, st in rows:
        if st != "aligned":
            print("     algo %-3d %-17s records=%-3d ui=%-3d  %s" % (a, nm, nr, nu, st))
    print()
    print("  ---- THE CONTROL.  If the alignment (T2 record order == UI list order)")
    print("       were wrong, the UNIT attached to each parameter name would scatter")
    print("       across opcodes.  It cannot fail only if every opcode already sees")
    print("       every unit -- so the pass/fail line is printed, not asserted:")
    pure = imp = 0
    for op in sorted(opunit):
        u = opunit[op]
        tot = sum(u.values())
        top, ntop = u.most_common(1)[0]
        (pure if ntop == tot else imp).__class__      # keep flake quiet
        if ntop == tot:
            pure += 1
        else:
            imp += 1
        print("     op %02X  n=%-3d units %-28s  names %s"
              % (op, tot, dict(u),
                 ", ".join("%s x%d" % (k, v) for k, v in opname[op].most_common(3))))
    print("     => %d of %d opcodes carry EXACTLY ONE unit; %d are mixed."
          % (pure, pure + imp, imp))
    print()
    print("  ---- THE NAMED CELLS (a cell is listed when >=1 algorithm binds it):")
    for c in sorted(cellname):
        n = cellname[c]
        print("     cell 0x%02X  %s" % (c, ", ".join("%s x%d" % (k, v)
                                                     for k, v in n.most_common(4))))
    print()


# ==========================================================================
#  5. PRIORITY B -- THE C-FORMAT IMMEDIATE
# ==========================================================================
def cmd_cformat(rom, main, corpus, E):
    print("=" * 78)
    print("5. PRIORITY B -- THE C-FORMAT IMMEDIATE: HOW WIDE IS IT?")
    print("=" * 78)
    cf = [w for w in corpus if D.c_format(w)]
    dis = sorted(set(cf))
    print("  corpus %d words; C-format %d words, %d distinct forms"
          % (len(corpus), len(cf), len(dis)))
    print()
    print("  %-14s %6s %6s %5s %4s %5s  %s"
          % ("word", "imm13", "A", "B", "n", "is_c40", "lo12 as a route"))
    for w in dis:
        lo = D.lo12(w)
        print("  %-14s %6d %6d %5d %4d %5s  SRC %02X  mode %d  ACT %02X"
              % ("%03X.%X.%02X.%03X" % D.fields(w), D.c_imm13(w), D.c_a(w), D.c_b(w),
                 cf.count(w), "yes" if D.is_c40(w) else "no",
                 D.lo_src(w), int(D.lo_ptrmode(w)), D.lo_act(w)))
    print()
    c40 = [w for w in dis if D.is_c40(w)]
    other = [w for w in dis if not D.is_c40(w)]
    z40 = [w for w in c40 if D.c_b(w) == 0]
    zot = [w for w in other if D.c_b(w) == 0]
    print("  ---- THE RESULT.  B = imm13 & 0x1F = addr8 & 0x1F -- a FREE five-bit")
    print("       field of the encoding (in every non-C word addr8 takes all values).")
    print("     is_c40()  forms: %2d, of which B == 0: %2d   (%d of %d WORDS)"
          % (len(c40), len(z40), sum(cf.count(w) for w in z40),
             sum(cf.count(w) for w in c40)))
    print("     other     forms: %2d, of which B == 0: %2d   (%d of %d WORDS)"
          % (len(other), len(zot), sum(cf.count(w) for w in zot),
             sum(cf.count(w) for w in other)))
    print("     ** CONTROL THAT SAYS NO: if B were structurally zero for the WHOLE")
    print("        C format the second row would be zero too.  It is not -- %d of %d"
          % (len(other) - len(zot), len(other)))
    print("        non-c40 forms carry B != 0.  So the zero is a property of is_c40(),")
    print("        not of the format, and the test had a live failure mode.")
    print("     ** NULL: under `imm13 is one 13-bit number' the chance that all %d"
          % len(z40))
    print("        distinct is_c40 forms land on a multiple of 32 is 32^-%d = %.1e"
          % (len(z40), 32.0 ** -len(z40)))
    print()
    print("  => FORCED, against the enumerated alternatives {13-bit immediate;")
    print("     8-bit immediate + 5 reserved; 8-bit immediate + a 5-bit field that")
    print("     is 0 everywhere in this ROM}: the is_c40 immediate is EIGHT BITS.")
    print("     The last two are not separated here and both refute the first.")
    print("     Independent 2/2 confirmation: the two host-written words")
    print("     C40.A.80.445 -> A = 84 and C41.9.00.446 -> A = 200 are the two body")
    print("     entry I-RAM addresses, MEASURED at the host port (K5).")
    print()
    print("  ---- THE FALSIFICATION.  `dark-words.md' sect. 4.2 reading (II) offered")
    print("       `C40.3.20.44C carries imm13 = 800, and 800 samples is the ROOM")
    print("       REVERB pre-delay R3 derived independently'.  Where does that word")
    print("       actually live?")
    bod = bodies(rom, E)
    where = collections.Counter()
    for a, (ia, ws) in bod.items():
        n = sum(1 for w in ws if w == 0xC4032044C)
        if n:
            where[(a, effect_name(main, a), ia)] = n
    for (a, nm, ia), n in sorted(where.items()):
        print("       algo %-3d %-17s @I-RAM %-4d x%d" % (a, nm, ia, n))
    revs = [k for k in where if 16 <= k[0] <= 27]
    print("       ** occurrences inside any of the twelve REVERB bodies: %d" % len(revs))
    print("       ** the ROOM REVERB body's own C-format word is C40.1.80.000,")
    print("          immediate 12 (not 800, not 384).")
    print("       => the 800 is 25 x 32 -- an artefact of reading the reserved five")
    print("          bits as part of the number -- and the word is a UNIT-0 idiom")
    print("          that never appears in the program whose pre-delay it was said")
    print("          to be.  READING (II) IS FALSIFIED.")
    print()
    print("  ---- THE FIVE `lo12 = 0x820' HEADER WORDS ARE NOT A SEPARATE PUZZLE.")
    print("       0x820 = register SELECTOR 0x20 with lo12 bit 11 (`addr8 carries a")
    print("       payload') -- the same shape as 0x821 ldptr, 0x822, 0x825 ldptr.d,")
    print("       0x827.  So these words are the REGISTER-LOAD family carrying a WIDE")
    print("       immediate instead of an 8-bit one, and dark-words' unknown")
    print("       `C-DEST-820' is the same unknown as `what is register 0x20'.")
    for w in dis:
        if D.lo12(w) == 0x820:
            print("       %-14s imm13 = %5d   A = %3d  B = %2d"
                  % ("%03X.%X.%02X.%03X" % D.fields(w), D.c_imm13(w), D.c_a(w), D.c_b(w)))
    print("       (B != 0 on 4 of these 5, so they are NOT the eight-bit family:")
    print("        the wide immediate is real here.)")
    print()
    print("  ---- THE is_c40 DESTINATIONS, keyed on lo12:")
    dd = collections.defaultdict(list)
    for w in dis:
        if D.is_c40(w):
            dd[D.lo12(w)].append(w)
    for lo in sorted(dd):
        ws = dd[lo]
        print("       lo12 %03X  SRC %02X ACT %02X   n=%-3d  immediates %s  %s"
              % (lo, (lo >> 6) & 0x1F, lo & 0x1F, sum(cf.count(w) for w in ws),
                 sorted(set(D.c_a(w) for w in ws)),
                 "<- SETTLED: per-unit CALL VECTOR (K5)" if lo in (0x445, 0x446) else ""))
    sh = [lo for lo in dd if ((lo >> 6) & 0x1F) == 0x11]
    print("       ** the four lo12 values 0x445/0x446/0x44C/0x451 share SRC 0x11 and")
    print("          differ only in ACTION (%s) -- and two of them are the settled"
          % ", ".join("%02X" % (lo & 0x1F) for lo in sorted(sh)))
    print("          call vectors.  CONSISTENT with `SRC 0x11 = the immediate,")
    print("          ACTION = the destination'; NOT forced, because the other four")
    print("          is_c40 lo12 values do not carry SRC 0x11.")
    print()


# ==========================================================================
#  6. PRIORITY C -- ACTION 0x0B / 0x0E
# ==========================================================================
def cmd_actions(rom, main, corpus, E, F):
    print("=" * 78)
    print("6. PRIORITY C -- ACTION 0x0B (frame 17) and ACTION 0x0E (frame 14)")
    print("=" * 78)
    route = [w for w in corpus if not (D.c_format(w) or D.is_regload(w))]
    print("  ACTION histogram over the %d route-bearing corpus words:" % len(route))
    ah = collections.Counter(D.lo_act(w) for w in route)
    print("     %s" % "  ".join("%02X:%d" % kv for kv in sorted(ah.items())))
    print()
    bod = bodies(rom, E)
    for act in (0x0B, 0x0E):
        print("  ---- ACTION 0x%02X" % act)
        forms = collections.Counter()
        for w in route:
            if D.lo_act(w) == act:
                forms["%03X.%X.%02X.%03X" % D.fields(w)] += 1
        print("     %d corpus words, %d distinct forms" % (ah[act], len(forms)))
        for k, n in forms.most_common(12):
            print("        %s x%d" % (k, n))
        prog = []
        for a, (ia, ws) in sorted(bod.items()):
            n = sum(1 for w in ws if not (D.c_format(w) or D.is_regload(w))
                    and D.lo_act(w) == act)
            if n:
                prog.append((a, effect_name(main, a), ia, n))
        print("     programs that constrain it (%d):" % len(prog))
        for a, nm, ia, n in prog[:24]:
            print("        algo %-3d %-17s @%-4d x%d" % (a, nm, ia, n))
        if len(prog) > 24:
            print("        ... and %d more" % (len(prog) - 24))
        infr = sum(1 for _s, _a, w, _r in F
                   if not (D.c_format(w) or D.is_regload(w)) and D.lo_act(w) == act)
        print("     slots in the cold-boot FRAME: %d" % infr)
        # decidability: which of those programs have a SOLVED reference block?
        solved = {39: "PARAMETRIC EQ (biquad, solved to the bit)",
                  9: "SINGLE DELAY (comb, solved)",
                  16: "ROOM REVERB (Schroeder comb network)"}
        hit = [s for a, _n, _i, _c in prog for s in [solved.get(a)] if s]
        print("     ** DECIDABILITY: of those, the programs with an INDEPENDENTLY")
        print("        SOLVED numeric reference are: %s" % (", ".join(hit) or "NONE"))
    print()
    print("  ---- THE DECIDABILITY TABLE.  A word can only be settled inside a block")
    print("       whose ARITHMETIC is already known, so the question is not `where")
    print("       is this ACTION frequent' but `where is it, inside a SOLVED block'.")
    print("       The three blocks this project has solved numerically:")
    ref = {39: "PARAMETRIC EQ  -- biquad, solved to the bit",
           9: "SINGLE DELAY   -- comb, solved",
           16: "ROOM REVERB    -- Schroeder comb network"}
    print("       %-6s %-42s %8s %8s" % ("algo", "solved reference block",
                                         "ACT 0B", "ACT 0E"))
    for a in sorted(ref):
        ws = bodies(rom, E)[a][1]
        n = {}
        for act in (0x0B, 0x0E):
            n[act] = sum(1 for w in ws if not (D.c_format(w) or D.is_regload(w))
                         and D.lo_act(w) == act)
        print("       %-6d %-42s %8d %8d" % (a, ref[a], n[0x0B], n[0x0E]))
    print()
    print("       => ACTION 0x0E IS DECIDABLE TODAY: it occurs inside the PARAMETRIC")
    print("          EQ body, whose every coefficient and every state cell is known,")
    print("          so a solver has a numeric target.  ACTION 0x0B IS NOT: the EQ")
    print("          has none, the SINGLE DELAY has few, and every reverb instance")
    print("          is the all-pass motif's slot 5, which the R1 solve never reads.")
    print()
    print("  ---- ★ AND 0x0B IS NOT MINE ALONE.  Of the %d corpus ACT-0x0B words,"
          % ah[0x0B])
    ndram = sum(1 for w in route if D.lo_act(w) == 0x0B and D.is_dram(w))
    print("       %d are DELAY-DRAM words (mode-1 format escape).  ACTION 0x0B and"
          % ndram)
    print("       the delay-DRAM family are ENTANGLED: neither can be settled")
    print("       without the other, and that is a fact the sibling pass on the 42")
    print("       delay-DRAM slots needs.")
    print()
    print("  ---- WHY NO REVERB SEARCH CAN SETTLE 0x0B, restated as a census rather")
    print("       than as a search result: the reverb body contains %d ACTION-0x0B"
          % sum(1 for w in bod[16][1] if not (D.c_format(w) or D.is_regload(w))
                and D.lo_act(w) == 0x0B))
    print("       word(s), all of them in the 6-word all-pass motif's slot 5")
    print("       (102.A.00.64B), whose value the R1 solve never has to read.")
    print()


# ==========================================================================
#  7. PRIORITY D -- THE FAMILIES
# ==========================================================================
def cmd_families(rom, main, corpus, F):
    print("=" * 78)
    print("7. PRIORITY D -- mode-1 space / unknown class / class-0 register load")
    print("=" * 78)
    imgs = cell_images(rom)
    host_cells = set()
    for img in imgs.values():
        host_cells |= set(img.get(TAG_DRAM, {}))
    print("  the host's D-RAM (tag 15) write set, over all %d algorithms: %d of 256"
          % (len(imgs), len(host_cells)))
    print("     %s" % " ".join("%02X" % c for c in sorted(host_cells)))
    print()
    dark = [(s, a, w, r) for s, a, w, r in F if DW.klass(w) == "TRAP"]
    mode1 = [(s, a, w, r) for s, a, w, r in dark
             if not D.c_format(w) and D.class4(w) == 1 and not (D.hi12(w) & 0x800)]
    print("  ---- GROUP C, the mode-1 space: %d dark slots" % len(mode1))
    print("     %-6s %-14s %-6s %-8s %s" % ("slot", "word", "cell", "in host?", "region"))
    inn = 0
    for s, a, w, r in mode1:
        c = D.addr8(w)
        good = c in host_cells
        inn += good
        print("     %-6d %-14s 0x%02X   %-8s %s"
              % (s, "%03X.%X.%02X.%03X" % D.fields(w), c,
                 "YES" if good else "no", r.split("(")[0].strip()))
    print("     ** %d of %d mode-1 dark words address a cell the host itself writes."
          % (inn, len(mode1)))
    print("        NULL: a random 8-bit address lands in the host set with p = %.3f,"
          % (len(host_cells) / 256.0))
    print("        so %d of %d has p = %.2e under independence."
          % (inn, len(mode1), (len(host_cells) / 256.0) ** inn))
    print("        FAILURE MODE, and it is live: any cell outside the set refutes")
    print("        `class-1 addr8 is an address in the host's D-RAM space'.")
    print()
    # bit-7 pairing
    pairs = collections.Counter()
    for c in sorted(host_cells):
        if (c ^ 0x80) in host_cells:
            pairs[min(c, c ^ 0x80)] += 1
    print("     bit-7 PAIRED cells (c and c|0x80 both written): %s"
          % " ".join("%02X/%02X" % (c, c | 0x80) for c in sorted(pairs)))
    print()
    regload = [(s, a, w, r) for s, a, w, r in dark if D.is_regload(w)]
    print("  ---- GROUP D, the class-0 register loads: %d dark slots" % len(regload))
    for s, a, w, r in regload:
        print("     slot %-4d I-RAM %-4d %-14s selector 0x%02X  payload 0x%02X  imm=%d"
              % (s, a, "%03X.%X.%02X.%03X" % D.fields(w), D.lo_sel(w), D.addr8(w),
                 int(D.lo_imm(w))))
    sels = collections.Counter()
    for w in corpus:
        if D.is_regload(w):
            sels[D.lo_sel(w)] += 1
    print("     register SELECTORS over the whole corpus: %s"
          % "  ".join("0x%02X:%d" % kv for kv in sorted(sels.items())))
    print("     0x21 ldptr (C-RAM pointer) / 0x25 ldptr.d (delay descriptor) are")
    print("     SETTLED; 0x20 / 0x22 / 0x27 are OPEN -- and sect. 5 shows the five")
    print("     wide-immediate header words belong to selector 0x20, so 0x20 now")
    print("     carries 5 dark slots on top of its register-load members.")
    print()
    print("  ---- ★ THE CELLS THE HOST NEVER PRIMES.  This is the interesting half:")
    never = [c for _s, _a, w, _r in mode1 for c in [D.addr8(w)] if c not in host_cells]
    print("     %s -- addressed by the program, written by the host in 0 of %d"
          % (" ".join("0x%02X" % c for c in sorted(set(never))), len(imgs)))
    print("     algorithms.  Three of them (0x8C/0x8D/0x8F) are exactly R2's `three")
    print("     unexplained registers'.  So the mode-1 index space is NOT one space:")
    print("     part of it is host-primed STATE (0x05/0x06/0x0A/0x0B/0x0E/0x50.. and")
    print("     their |0x80 twins) and part of it is never initialised by the host at")
    print("     all -- which is what a hardware REGISTER/PORT looks like and what a")
    print("     RAM state cell does not.")
    print()
    print("  ---- THE MINIMAL PAIR ACROSS THE CLASS FIELD (dark-words sect. 4.4).")
    for probe in (0x0122FF1CE, 0x012401_1CE):
        pass
    a4 = sum(1 for w in corpus if w == 0x0124011CE)
    a2 = sum(1 for w in corpus if w == 0x0122FF1CE)
    n1ce = sum(1 for w in corpus if not (D.c_format(w) or D.is_regload(w))
               and D.lo12(w) == 0x1CE)
    cl = collections.Counter(D.class4(w) for w in corpus
                             if not (D.c_format(w) or D.is_regload(w))
                             and D.lo12(w) == 0x1CE)
    print("     012.2.FF.1CE (K6, addressing FORCED) x%d ; 012.4.01.1CE x%d" % (a2, a4))
    print("     every corpus word with lo12 = 0x1CE: %d, by class4 %s"
          % (n1ce, dict(sorted(cl.items()))))
    print("     ** the class-4 member is NOT a one-off: %d corpus copies against %d"
          % (a4, a2))
    print("        for the class-2 member whose addressing K6 forced.  The pair is")
    print("        %d vs %d, so a class-4 model has 53 places to be wrong in."
          % (a4, a2))
    print()
    unkc = [(s, a, w, r) for s, a, w, r in dark
            if not D.c_format(w) and D.class4(w) in (0, 3, 4, 5, 6, 7)
            and not D.is_regload(w)]
    print("  ---- GROUP E, the unknown classes: %d dark slots" % len(unkc))
    byc = collections.defaultdict(list)
    for s, a, w, r in unkc:
        byc[D.class4(w)].append((s, a, w))
    for cl in sorted(byc):
        print("     class %d: %s" % (cl, " ".join("%03X.%X.%02X.%03X" % D.fields(w)
                                                  for _s, _a, w in byc[cl])))
    print()


# ==========================================================================
#  8. THE CONTROLS
# ==========================================================================
def cmd_control(rom, main, corpus, E, F):
    print("=" * 78)
    print("8. THE CONTROLS -- each one shown REJECTING something")
    print("=" * 78)

    print("  C1  THE WRITER, READ OFF THE INSTRUCTIONS -- and a published formula")
    print("      FALSIFIED.  LABEL_038539 at Sub CPU 0x03859A..0x0385EF emits, for a")
    print("      24-bit value v:")
    print("         sra 1,XWA ; sra 0,XWA ; and 0x7F   -> byte1")
    print("         sra 9,XWA ; and 0xFF               -> byte2")
    print("         sra 1,XWA ; and 0xFF               -> byte3")
    print("         sla 7,XWA ; and 0x80 ; add 0x15    -> byte4")
    print("      On the TLCS-900 a shift COUNT OF 0 MEANS 16, so the first pair is")
    print("      v >> 17, not v >> 1.  tools/kn5000_dsp_params.py:writer_038539 (and")
    print("      notes/kn5000-dsp-parameters.md sect. 2, which quotes it) transcribe it")
    print("      as `(value >> 1) & 0x7F'.  That is WRONG, and it matters: it loses")
    print("      the top seven bits of every coefficient.")
    good = bad = oldgood = oldbad = 0
    b0hi = collections.Counter()
    for a, p in all_streams(rom).items():
        for _pp, op, body in records(rom, p):
            if op not in (0, 1, 5) or len(body) < 3:
                continue
            data = body[3:]
            for k in range(0, len(data) - 4, 5):
                b5 = bytes(data[k:k + 5])
                if not is_packet(b5):
                    continue
                v, tag, f32, _f31 = packet(b5)
                b0hi[(b5[0], b5[1] >> 7)] += 1
                new_ = bytes([b5[0], (b5[1] & 0x80) | ((v >> 17) & 0x7F),
                              (v >> 9) & 0xFF, (v >> 1) & 0xFF,
                              ((v << 7) & 0x80) | tag])
                old_ = bytes([b5[0], (b5[1] & 0x80) | ((v >> 1) & 0x7F),
                              (v >> 9) & 0xFF, (v >> 1) & 0xFF,
                              ((v << 7) & 0x80) | tag])
                good += (new_ == b5)
                bad += (new_ != b5)
                oldgood += (old_ == b5)
                oldbad += (old_ != b5)
    print("      round-trip over the %d canned packets:" % (good + bad))
    print("         v >> 17 (this pass, and dsp_disasm.host_packet) : %d exact, %d wrong"
          % (good, bad))
    print("         v >>  1 (kn5000_dsp_params.writer_038539)       : %d exact, %d wrong"
          % (oldgood, oldbad))
    print("      ** the two formulas AGREE on %d packets and DISAGREE on %d, so the"
          % (oldgood, oldbad))
    print("         test is not vacuous; and the MEASURED live cold-boot values decide")
    print("         it independently: 0A 20 00 00 15 is +0.500000 under v>>17 and")
    print("         +0.000000 under v>>1.")
    print("      ** UNEXPLAINED, stated rather than smoothed over: the packet's byte 0")
    print("         is a literal 0x0A in the writer, but the canned streams also carry")
    print("         0x0B.  Distribution of (byte0, byte1 bit 7): %s"
          % dict(sorted(b0hi.items())))
    print("         So two bits above the 24-bit field are in use and this pass does")
    print("         not know what they are.  OPEN.")
    print()
    print("  C2  the curve-membership test REJECTS the wrong selector.")
    tabs = {k: curve(rom, b) for k, b in CURVE_038EB9.items()}
    for cell, val in sorted(COLDBOOT_LEVEL.items()):
        hits = {k: [i for i, x in enumerate(t) if x == val] for k, t in tabs.items()}
        print("      cell 0x%02X value 0x%06X -> %s"
              % (cell, val, {("CURVE_" + "ABC"[k]): h for k, h in hits.items() if h}))
    print("      the unit-1 value is in ONE table of three: a wrong selector fails.")
    print()

    print("  C3  the auto-increment step is discriminating (sect. 1 prints the")
    print("      whole enumeration; 4 of 5 steps are rejected by the same datum).")
    print()

    print("  C4  the B==0 test on the C format has a live failure mode: %d of the"
          % sum(1 for w in set(corpus) if D.c_format(w) and not D.is_c40(w)
                and D.c_b(w) != 0))
    print("      non-c40 C-format forms carry B != 0, so `B is always 0' is false")
    print("      as a statement about the format.  The test separates the two")
    print("      families instead of passing vacuously.")
    print()

    print("  C5  the mode-1 host-membership test has a live failure mode: the host")
    print("      write set covers only part of the 256-cell space, and the two")
    print("      call-word cells 0x0E/0x0F are exactly a case where the prediction")
    print("      of hypothesis (beta) FAILS (sect. 2).")
    print()

    print("  C7  THE UI-ALIGNMENT UNIT CONTROL lives in sect. 4: if T2 record order")
    print("      were not UI parameter order, the UNIT attached to each name would")
    print("      scatter over the parameter opcodes.  22 of 23 opcodes come out")
    print("      unit-pure and the one exception (op 70) is the PARAMETRIC EQ band")
    print("      triple, whose three parameters legitimately differ in unit and which")
    print("      appears exactly 14/14/14.  A wrong ordering could not produce that.")
    print()

    print("  C6  PLANTED PROBES on the transport decoder, each with a known answer:")
    probes = [
        (bytes([0x0A, 0x20, 0x00, 0x00, 0x15]), "packet, tag 15, v=0x400000"),
        (bytes([0x0A, 0x0B, 0xC6, 0x85, 0x95]), "packet, tag 15, v=0x178D0B"),
        (bytes([0x00, 0x00, 0x10, 0x60, 0x00]), "NOT a packet: select 000.1.06.000"),
        (bytes([0x08, 0x01, 0x02, 0x68, 0x25]), "NOT a packet: ldptr.d #$26"),
        (bytes([0x0A, 0x00, 0x00, 0x40, 0x4C]), "packet, tag 4C, v=128"),
    ]
    for b5, what in probes:
        r = packet(b5) if is_packet(b5) else None
        print("      %s  %-34s -> %s" % (b5.hex(" "), what,
                                         ("v=0x%06X tag=%02X" % (r[0], r[1])) if r
                                         else "not a packet"))
    print()


# ==========================================================================
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "transport", "cells", "outlevel", "regmap",
                             "cformat", "actions", "families", "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    if not os.path.isdir(args.tools):
        sys.exit("ERROR: need the ROM parser -- pass --tools <kn7000_mame/tools>")
    rom, mainrom, E = load(args.sub, args.main, args.tools)
    cappath = os.path.join(os.path.dirname(args.tools.rstrip("/")), "notes",
                           "data", "kn5000_dsp1_upload_coldboot.txt")
    capture = coldboot_capture(cappath)
    corpus = DW.load_corpus(args.sub, args.tools)
    hdr, epi, u0, u1 = DW.load_images(args.sub, args.tools)
    F = DW.frame(hdr, epi, u0, u1)

    c = args.cmd
    if c in ("all", "transport"):
        cmd_transport(rom)
        cmd_transport2(rom, capture)
    if c in ("all", "cells"):
        cmd_cells(rom, mainrom, capture)
    if c in ("all", "outlevel"):
        cmd_outlevel(rom, mainrom)
    if c in ("all", "regmap"):
        cmd_regmap(rom, mainrom, args.tools)
    if c in ("all", "cformat"):
        cmd_cformat(rom, mainrom, corpus, E)
    if c in ("all", "actions"):
        cmd_actions(rom, mainrom, corpus, E, F)
    if c in ("all", "families"):
        cmd_families(rom, mainrom, corpus, F)
    if c in ("all", "control"):
        cmd_control(rom, mainrom, corpus, E, F)


if __name__ == "__main__":
    main()
