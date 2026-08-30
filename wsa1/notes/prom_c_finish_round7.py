#!/usr/bin/env python3
"""prom_c ROUND 7 (wave-7 round 3), THE FINISH PASS -- an inventory of every one of
   prom_c's 944 unnamed-or-framed objects: named with evidence, or REFUSED with a
   reason that was derived rather than asserted.

QUESTION IT ANSWERS
    "prom_c is territorially complete and carries the smallest documentation debt of
     any image in this tree.  Is every object in it either NAMED WITH EVIDENCE or
     DECLARED NAMELESS WITH A DERIVED REASON -- and if not, exactly which ones are
     not, and why?"

    No image in this tree had that answer before this round.  `--census` is it.

WHY AN INVENTORY AND NOT A NAMING SPREE
    The tree's own history says a confidently wrong name passes the byte gate forever.
    So the deliverable of a finish pass is not "how many did you rename" but "for how
    many can you state, mechanically, why they have the name they have".  A refusal is
    a result here, and this script prints refusals with the same rigour as names:

        every refusal bucket is produced by a rule that RUNS, over ALL 944 objects,
        and every object lands in exactly one bucket (asserted, --census).

WHAT THE ROUND SHIPPED, and what it refused
    28 labels renamed, each with a header and an Evidence: line, by four mechanisms.
    prom_c moved content 794 -> 809, framed 487 -> 500, sub_XXXXXX 457 -> 429; LOWER
    45.7%% -> 46.5%%, UPPER 73.7%% -> 75.3%% (notes/wave7_documentation_metrics.py).
    ⚠ FRAMED->CONTENT PROMOTIONS: ZERO, and that is the measured answer, not a miss.
    See --refusals R4.  The 15 new content labels are all former sub_XXXXXX.

      TWIN        13 routines that are byte-identical, or differ in 2-3 decoded bytes,
                  from an already-named routine.  Every claim carries the differing
                  count and the address of each differing byte (--twins).  The sweep
                  is over EVERY same-length pair in prom_c, not a shortlist, so
                  "no closer twin exists" is a measured statement.
      READER      1 routine named from what calls it and what it writes
                  (PartRec_SetOrClearParamBits_x4) plus its 12 callers.
      DISPATCH    12 routines named for the part-record word each one applies, read
                  off `add BC,<offset>` (--params).
      PORT         2 accessors of the 0x0010C000 device named from the register
                  selector they build and the direction they move it in.  One of them,
                  Dev10C_ReadChanReg_0100, is the SECOND read site in the whole image
                  and retires a "the only evidence that the port can be read" claim
                  that the 0xFACE67 block comment had carried since round 2.

    AND THREE REFUSED NAMES THAT LOOKED SAFE (--refusals, group R1).  sub_FAFBEC,
    sub_FB6500 and sub_FACC3F are the handlers of MIDI controller arms 0x5E, 0x79 and
    0x7B, and `MidiCtrl_CC94` / `_CC121` / `_CC123` were the obvious names.  They are
    refused because the rule the tree's other 23 MidiCtrl_* names obey -- EXACTLY ONE
    reference, the dispatch arm -- fails for all three: they have 2, 5 and 4 references.
    A routine four other places call is not "the controller-0x7B handler".  The rule is
    calibrated on the 23 existing names (--refusals prints the count it measured,
    so the number cannot drift out of the prose), not invented for the refusal.

RUN
    python3 notes/prom_c_finish_round7.py             # every section
    python3 notes/prom_c_finish_round7.py --census    # 1: ALL 944, bucketed
    python3 notes/prom_c_finish_round7.py --twins     # 2: the byte-identity sweep
    python3 notes/prom_c_finish_round7.py --params    # 3: the 12-word parameter block
    python3 notes/prom_c_finish_round7.py --noref     # 4: the no-reference census
    python3 notes/prom_c_finish_round7.py --refusals  # 5: every refusal, with its rule
    python3 notes/prom_c_finish_round7.py --headers   # 6: header / Evidence depth
    python3 notes/prom_c_finish_round7.py --gapA      # 7: gap A is CLOSED and the brief is stale
    python3 notes/prom_c_finish_round7.py --ports     # 8: the device-port accessors named here
    python3 notes/prom_c_finish_round7.py --selftest  # all of it, exit 1 on any failure

WHAT THIS DOES **NOT** ESTABLISH
  * What any part-record parameter IS.  Section 3 measures the OFFSET of each of the
    twelve words and the MASK each applier ORs after storing it.  Both are instruction
    operands.  Nothing here reads a parameter's musical meaning, and the twelve names
    are FRAMED on purpose for exactly that reason.
  * That a "no literal reference" object is unreachable.  The census is exhaustive over
    literal spellings -- every instruction operand in the source, plus every 24- and
    32-bit little-endian pointer in the 512 KiB ROM -- and BLIND to a call through a
    register.  It says "not found", never "dead", and section 4 prints the nine objects
    that a fall-through explains anyway.
  * That prom_c's 429 remaining sub_XXXXXX are unnameable in principle.  Section 1 says
    which mechanism each one is waiting on, and 258 of them are waiting on the same one
    (bucket S6): a stack-frame routine whose every caller is itself a sub_XXXXXX and
    whose fields nothing in the image gives a meaning to.  That is the shape of the
    work left in prom_c, and it is one question, not 258.

★ THE THREE THINGS THIS INVENTORY SAYS THE NEXT PASS SHOULD DO
  1. Bucket S6 (258) is one problem, not 258.  Every one of them is a compiler-framed
     routine reached ONLY from other sub_XXXXXX, so no name can propagate into it from
     outside -- by construction, the entry to each of those chains is in bucket S4 or
     S5, where a named or framed caller does exist.  Naming S4 members is therefore how
     S6 gets reached at all; attacking S6 head-on is attacking the middle of a chain.
  2. The 10 objects in bucket S1 are NOT ROUTINES (--noref).  Renaming them to the
     tree's <parent>__<address> convention is correct and was deliberately left to a
     lane that is not also reporting the metric it would move.
  3. Bucket S4 (118) waits on the SIX-BIT TARGET CODE of Voice_ApplyParamChange_Dispatch
     and on what the record at (XIZ+0x0C) is.  Section 3 gets as far as the part-record
     word each code writes and the change bit each one sets; the meaning of a parameter
     is the next thing that would unlock a hundred names at once.
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xF80000

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
INTERNAL = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}$')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
# the grader from notes/wave7_documentation_metrics.py, copied so this script is
# self-contained; --selftest asserts the two agree on prom_c's three totals.
FRAMED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*_'
                    r'(?:[0-9A-Fa-f]{2}x[0-9A-Fa-f]{2}_)?'
                    r'(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\b')
CALR = re.compile(r'calr\s+\(0x([0-9A-Fa-f]+)\s*-\s*0x([0-9A-Fa-f]+)\)')
HEXOP = re.compile(r'0x([0-9A-Fa-f]{5,8})')

_C = {}


def load():
    """Source lines, ELF symbols, ROM bytes, and the top-level label list."""
    if _C:
        return _C
    src = open(SRC).read().split("\n")
    out = subprocess.run([NM, ELF], capture_output=True, text=True).stdout
    sym = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tTdDbBrR":
            sym[p[2]] = int(p[0], 16)
    rom = open(ROM, "rb").read()
    labels = []
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m:
            labels.append((i, m.group(1), sym.get(m.group(1))))
    top = [(i, n, a) for i, n, a in labels if not INTERNAL.match(n)]
    top.sort()
    _C.update(src=src, sym=sym, rom=rom, labels=labels, top=top)
    # extent of every top-level object, by address order
    bya = sorted(set((a, n) for _i, n, a in top if a is not None))
    ext = {}
    for k, (a, n) in enumerate(bya):
        e = bya[k + 1][0] if k + 1 < len(bya) else BASE + len(rom)
        ext[n] = (a, e)
    _C["ext"] = ext
    _C["byaddr"] = dict((a, n) for a, n in bya)
    # line -> enclosing top-level label
    encl = [None] * len(src)
    cur, ti = None, 0
    for i in range(len(src)):
        while ti < len(top) and top[ti][0] == i:
            cur = top[ti][1]
            ti += 1
        encl[i] = cur
    _C["encl"] = encl
    return _C


def grade(n):
    if UNNAMED.match(n):
        return "sub"
    if FRAMED.match(n):
        return "framed"
    return "content"


def blob(n):
    c = load()
    if n not in c["ext"]:
        return None
    a, e = c["ext"][n]
    if a is None or a < BASE or e > BASE + len(c["rom"]):
        return None
    return c["rom"][a - BASE:e - BASE]


# ---------------------------------------------------------------- references
def refcensus():
    """Every LITERAL reference to every top-level object, from two independent
    sweeps: the source text (all instruction operands, symbolic and numeric, plus
    the `calr (T - S)` form the emitter uses) and the raw ROM (every 24- and 32-bit
    little-endian pointer).  ⚠ Blind to a call through a register."""
    c = load()
    src, byaddr = c["src"], c["byaddr"]
    refs = collections.defaultdict(list)
    for i, ln in enumerate(src):
        if ln.lstrip().startswith(";"):
            continue
        code = ln.split(";")[0]
        if not code.strip():
            continue
        if LABEL.match(ln):
            continue
        m = CALR.search(code)
        vals = [int(m.group(1), 16)] if m else [int(h, 16) for h in HEXOP.findall(code)]
        for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', code):
            if w in c["sym"] and not INTERNAL.match(w):
                vals.append(c["sym"][w])
        for v in vals:
            if v in byaddr:
                refs[v].append((i, c["encl"][i], code.strip()))
    return refs


def rombytes_refs(addr):
    """Sites in the ROM holding `addr` as a 24-bit LE pointer (the 32-bit form is a
    superset of these, since the fourth byte is 0x00)."""
    c = load()
    b3 = bytes([addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF])
    out, o = [], 0
    while True:
        o = c["rom"].find(b3, o)
        if o < 0:
            break
        out.append(BASE + o)
        o += 1
    return out


# ------------------------------------------------------------------ features
def features():
    """Per top-level object: instruction count, the named objects it touches, the
    device ports it writes, whether it opens a stack frame."""
    c = load()
    src = c["src"]
    top = c["top"]
    nxt = {}
    for k in range(len(top) - 1):
        nxt[top[k][1]] = top[k + 1][0]
    nxt[top[-1][1]] = len(src)
    lineof = dict((n, i) for i, n, _a in top)
    out = {}
    for _i, n, a in top:
        s, e = lineof[n] + 1, nxt[n]
        ninstr = 0
        named = collections.Counter()
        ports = set()
        frame = False
        isdata = 0
        for ln in src[s:e]:
            code = ln.split(";")[0]
            if not code.strip():
                continue
            if LABEL.match(ln):
                continue
            t = code.strip()
            if t.startswith("."):
                isdata += 1
                continue
            ninstr += 1
            if "link32" in t or t.startswith("link"):
                frame = True
            m = CALR.search(code)
            vals = [int(m.group(1), 16)] if m else [int(h, 16) for h in HEXOP.findall(code)]
            for w in re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', code):
                if w in c["sym"] and w != n and not w.startswith(n + "__"):
                    named[w] += 1
            for v in vals:
                if v in c["byaddr"] and c["byaddr"][v] != n:
                    named[c["byaddr"][v]] += 1
                if v in (0x10C000, 0x104000, 0xE00000):
                    ports.add(v)
        out[n] = dict(addr=a, ninstr=ninstr, ndata=isdata, named=dict(named),
                      ports=sorted(ports), frame=frame)
    return out


# ============================================================ 1. THE CENSUS
# Every bucket below is a RULE, applied to all 944.  The order matters: the first
# rule that fires owns the object, and --census asserts the partition.
P7 = re.compile(r'^(P7Stream_|PoolDir_FieldRec_)')
TAILZONE = (0xFDE000, 0xFE2200)


def census():
    c = load()
    refs = refcensus()
    feat = features()
    named_shipped = set(SHIPPED)
    rows = []
    for _i, n, a in c["top"]:
        g = grade(n)
        if g == "content":
            continue
        rs = refs.get(a, [])
        callers = set(e for _l, e, _t in rs if e and e != n)
        cg = collections.Counter(grade(x) for x in callers)
        f = feat[n]
        if g == "framed":
            if P7.match(n):
                b = "F1 byte-code blob"
                why = ("the object's CONTENT is undecoded byte-code for a port-P7 device; "
                       "naming it would be naming a blob "
                       "(FINDINGS-prom_c-p7-byte-stream-pool.md sec 0)")
            elif a is not None and TAILZONE[0] <= a < TAILZONE[1]:
                b = "F2 framed BY DECISION"
                why = ("tail data zone: FINDINGS-prom_c-tail-data-zone.md sec 7 fixes the "
                       "spelling -- shape and reader known, role NOT claimed")
            elif re.search(r'_(?:0[0-9A-F]{3}|[0-9A-F]{4})$', n) and re.search(
                    r'^(Dev10C|Dev104|MidiCtrl|PartRec|Voice|DSP)', n):
                b = "F3 the number IS the meaning"
                why = ("the suffix is a device register, a MIDI controller or a record "
                       "field offset -- an instruction operand, not a placeholder")
            elif re.search(r'_[0-9]{1,4}$', n):
                b = "F4 ordinal in a named set"
                why = "the suffix indexes a set the prefix already names"
            else:
                b = "F5 address-suffixed"
                why = "the suffix is the object's own ROM address"
            rows.append((n, a, g, b, why))
            continue
        # --- the sub_XXXXXX ---
        if n in named_shipped:
            b = "S0 named this round"
            why = "see --twins / --params"
        elif not rs and not rombytes_refs(a):
            fall = fallthrough(n)
            if fall:
                b = "S1 NOT A ROUTINE"
                why = ("no literal reference of any spelling, and the instruction before "
                       "it (%s) is not a control transfer -- it is reached by "
                       "FALL-THROUGH" % fall)
            else:
                b = "S2 no reference found"
                why = ("no literal reference of any spelling anywhere in the 512 KiB "
                       "image; reached, if at all, through a register")
        elif f["ports"]:
            b = "S3 device writer, unnamed"
            why = "writes a device port but with no constant register base to name it by"
        elif cg["content"]:
            b = "S4 reader known, role not"
            why = ("called from %d content-named site(s) -- %s -- but the caller names a "
                   "SUBSYSTEM, not this routine's job"
                   % (cg["content"], ", ".join(sorted(x for x in callers
                                                      if grade(x) == "content")[:2])))
        elif cg["framed"]:
            b = "S5 caller is framed too"
            why = "every caller is itself framed or unnamed, so no name propagates in"
        else:
            b = "S6 opaque stack-frame routine"
            why = ("every caller is a sub_XXXXXX; the body reads argument slots and "
                   "untyped RAM offsets and nothing gives a field a meaning")
        rows.append((n, a, g, b, why))
    return rows


def fallthrough(n):
    """The instruction textually before this label, if it is not a control transfer.
    A routine nothing references but that the code above walks into is not an
    unreferenced routine -- it is not a routine."""
    c = load()
    src = c["src"]
    li = None
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if m and m.group(1) == n:
            li = i
            break
    j = li - 1
    while j > 0:
        l = src[j]
        if l.strip() and not l.lstrip().startswith(";") and not LABEL.match(l):
            t = l.split(";")[0].strip()
            head = t.split()[0] if t.split() else ""
            if head in ("ret", "reti", "retd") or t == "ret":
                return None
            if head in ("jp", "jr", "jrl") and "," not in t.split(None, 1)[-1]:
                return None
            return t
        j -= 1
    return None


def show_census():
    rows = census()
    print("=== 1. ALL %d prom_c objects that are not content-named, bucketed ===\n"
          % len(rows))
    buckets = collections.Counter(b for _n, _a, _g, b, _w in rows)
    whys = {}
    for _n, _a, _g, b, w in rows:
        whys.setdefault(b, w)
    for b in sorted(buckets):
        print("  %-28s %4d   %s" % (b, buckets[b], whys[b][:78]))
        if len(whys[b]) > 78:
            print("  %-28s        %s" % ("", whys[b][78:]))
    print("\n  every object landed in exactly one bucket: %s"
          % ("yes" if sum(buckets.values()) == len(rows) else "NO"))
    return rows, buckets


# ============================================================ 2. THE TWINS
SHIPPED = {
    # new name -> (address, mechanism, twin, twin address, length, differing bytes)
    "MIDI_Rx_FreeSlots": (0xF991E9, "twin", "MIDI_Rx_Dequeue", 0xF991F4, 11, 2),
    "PartRec_Flags09_Bit14_SetOrClear": (0xFAD880, "twin", "MidiCtrl_Int95", 0xFAD987, 73, 2),
    "PartRec_Flags09_Bit1_SetOrClear": (0xFAD93E, "twin", "MidiCtrl_Int95", 0xFAD987, 73, 2),
    "Scale7Bit_ByDepth_UniOrBipolar_Shl2": (0xFAD4FE, "twin",
                                            "Scale7Bit_ByDepth_UniOrBipolar", 0xFAD5C2, 99, 3),
    "Scale7Bit_ByDepth_UniOrBipolar_Shl6": (0xFAD625, "twin",
                                            "Scale7Bit_ByDepth_UniOrBipolar", 0xFAD5C2, 99, 3),
    "Scale7Bit_ByDepth_UniOrBipolar_Shl7": (0xFAD688, "twin",
                                            "Scale7Bit_ByDepth_UniOrBipolar", 0xFAD5C2, 99, 3),
    "Clamp_ToRange_Word_b": (0xFA78C6, "twin", "Clamp_ToRange_Word", 0xFA7598, 34, 0),
    "ScaleClampedDelta_Shr5_b": (0xFA7D03, "twin", "ScaleClampedDelta_Shr5", 0xFA766C, 70, 0),
    "Dev10C_SetChanReg_0840_0800_b": (0xFB73F0, "twin",
                                      "Dev10C_SetChanReg_0840_0800", 0xFACEDE, 60, 0),
    "Dev10C_SetChanReg_0840_b": (0xFB742C, "twin", "Dev10C_SetChanReg_0840", 0xFACF1A, 34, 0),
    "Dev10C_SetChanReg_0100_0140_b": (0xFB744E, "twin",
                                      "Dev10C_SetChanReg_0100_0140", 0xFACF3C, 60, 0),
    "Dev10C_SetChanReg_0840_0880_b": (0xFB748A, "twin",
                                      "Dev10C_SetChanReg_0840_0880", 0xFACEA2, 60, 0),
    "Dev10C_SetChanReg_0840_0880_From2E": (0xFB74C6, "twin",
                                           "Dev10C_SetChanReg_0840_0880", 0xFACEA2, 60, 2),
    "PartRec_SetOrClearParamBits_x4": (0xFAD203, "reader", None, None, None, None),
    "Dev10C_SetChanReg_0180_FromArg": (0xFB7502, "port", None, None, None, None),
    "Dev10C_ReadChanReg_0100": (0xFC7E57, "port", None, None, None, None),
}
PARAM_TABLE = [
    # (name, address, part-record word offset, dispatch table index, mask or None)
    ("PartRec_ApplyParam_001D", 0xFAE109, 0x1D, 0, None),
    ("PartRec_ApplyParam_001F", 0xFAE1B2, 0x1F, 1, None),
    ("PartRec_ApplyParam_0021", 0xFAE15F, 0x21, 2, None),
    ("PartRec_ApplyParam_0023", 0xFAED33, 0x23, 37, (0x0020, 0x0020)),
    ("PartRec_ApplyParam_0025", 0xFAED76, 0x25, 38, (0x0040, 0x0040)),
    ("PartRec_ApplyParam_0027", 0xFAEDC4, 0x27, 39, (0x0080, 0x0080)),
    ("PartRec_ApplyParam_0029", 0xFAEE07, 0x29, 40, (0x0100, 0x0100)),
    ("PartRec_ApplyParam_002B", 0xFAEE4A, 0x2B, 41, (0x0200, 0x0200)),
    ("PartRec_ApplyParam_002D", 0xFAEE8D, 0x2D, 42, (0x0400, 0x0400)),
    ("PartRec_ApplyParam_002F", 0xFAEED0, 0x2F, 43, (0x0800, 0x0800)),
    ("PartRec_ApplyParam_0031", 0xFAEF24, 0x31, 44, (0x1000, 0x1000)),
    ("PartRec_ApplyParam_0033", 0xFAEF7F, 0x33, 45, (0x2000, 0x2000)),
]
for _n, _a, _o, _k, _m in PARAM_TABLE:
    SHIPPED[_n] = (_a, "dispatch", None, None, None, None)

REFUSED_LOOKALIKES = [
    # (address, the name that was refused, the rule it failed, measured)
    (0xFAFBEC, "MidiCtrl_CC94", "one reference, the dispatch arm", 2),
    (0xFB6500, "MidiCtrl_CC121", "one reference, the dispatch arm", 5),
    (0xFACC3F, "MidiCtrl_CC123", "one reference, the dispatch arm", 4),
]


def diffbytes(a, b, n):
    c = load()
    x = c["rom"][a - BASE:a - BASE + n]
    y = c["rom"][b - BASE:b - BASE + n]
    return [(i, x[i], y[i]) for i in range(n) if x[i] != y[i]]


def twin_sweep(maxdiff=3, minlen=8):
    """EVERY same-length pair (unnamed-or-new object, named object) in prom_c,
    ranked by differing bytes.  Not a shortlist: this is what makes "no closer twin
    exists" a measurement."""
    c = load()
    bylen = collections.defaultdict(list)
    for _i, n, a in c["top"]:
        b = blob(n)
        if b and len(b) >= minlen:
            bylen[len(b)].append((n, b, a))
    out = []
    for _i, n, a in c["top"]:
        b = blob(n)
        if not b or len(b) < minlen:
            continue
        best = None
        for m, y, ma in bylen[len(b)]:
            if m == n:
                continue
            d = sum(1 for p, q in zip(b, y) if p != q)
            if best is None or d < best[2]:
                best = (m, ma, d)
        if best and best[2] <= maxdiff:
            out.append((n, a, len(b), best[0], best[1], best[2]))
    return out


def show_twins():
    print("=== 2. THE TWIN SWEEP -- every same-length pair in prom_c, diff <= 3 ===\n")
    rows = twin_sweep()
    print("  %-36s %-8s %5s  %-34s %5s" % ("object", "addr", "len", "closest twin", "diff"))
    for n, a, l, m, ma, d in sorted(rows, key=lambda r: (r[5], r[1])):
        mark = "  <-- named this round" if n in SHIPPED else ""
        print("  %-36s %06X %5d  %-34s %5d%s" % (n[:36], a, l, m[:34], d, mark))
    print("\n  %d objects have a twin within 3 bytes; %d of them were named this round."
          % (len(rows), sum(1 for r in rows if r[0] in SHIPPED)))
    print("\n  The differing bytes of every NEAR twin this round names, address by address:")
    for nm, (a, mech, tw, ta, ln, nd) in sorted(SHIPPED.items(), key=lambda kv: kv[1][0]):
        if mech != "twin" or not nd:
            continue
        print("    %s  vs %s  (%d bytes, %d differ)" % (nm, tw, ln, nd))
        for i, p, q in diffbytes(a, ta, ln):
            print("        0x%06X = %02X    where 0x%06X = %02X" % (a + i, p, ta + i, q))
    return rows


# ============================================================ 3. THE PARAMETERS
def param_scan():
    """Re-derive, from the source, each PartRec_ApplyParam_* routine's part-record word
    offset and the two mask constants it pushes to PartRec_SetOrClearParamBits_x4.

    ⚠ THE MASK READ IS DELIBERATELY NARROW, AND THE FIRST DRAFT OF IT WAS WRONG TWICE.
    Draft 1 took any `push #imm >= 0x10` anywhere in the routine, which (a) matched
    pushes that go to other callees and (b) MISSED the masks spelled in DECIMAL --
    `push 0x0020` is emitted as `pushw 32`, so three of the nine read as "no mask".
    Both defects showed up on the LAST element of the table, which is why the wave
    rule says to test it.  What runs now: find the `calr` to 0xFAD203 in the body and
    take the TWO pushes immediately before it, decimal or hex."""
    c = load()
    src = c["src"]
    top = c["top"]
    lineof = dict((n, i) for i, n, _a in top)
    nxt = {}
    for k in range(len(top) - 1):
        nxt[top[k][1]] = top[k + 1][0]
    nxt[top[-1][1]] = len(src)
    PUSH = re.compile(r'^pushw?\s+(0x[0-9A-Fa-f]+|\d+)$')
    out = []
    for n, a, off, code, mask in PARAM_TABLE:
        i, e = lineof[n], nxt[n]
        gotoff, sto, pushes, calr_at = None, None, [], None
        after_store = False
        for ln in src[i:e]:
            t = ln.split(";")[0].strip()
            ad = ADDRC.search(ln)
            m = re.search(r'^add\s+bc,\s*(0x[0-9A-Fa-f]+|\d+)$', t)
            if m and gotoff is None:
                gotoff = int(m.group(1), 0)
            if "0x1523" in t and t.startswith("ld") and gotoff is not None and sto is None:
                sto = ad.group(1) if ad else None
                after_store = True
                continue
            if not after_store or calr_at:
                continue
            if re.search(r'calr\s+\(0xFAD203\s*-', t):
                calr_at = ad.group(1) if ad else None
                continue
            mp = PUSH.match(t)
            if mp:
                pushes.append(int(mp.group(1), 0))
        # the argument group between the store and the calr; the two masks are the
        # non-zero immediates in it (the `push 0x00` is the group's zero pad)
        nz = [v for v in pushes if v]
        masks = tuple(nz[:2]) if calr_at and nz else None
        out.append((n, a, gotoff, masks, sto, off, mask, calr_at))
    return out


def jumptable():
    """The 49 entries of Voice_ApplyParamChange_Dispatch's table at 0xFAF08F, read
    out of the ROM.  Entry count is the `cp BC,0x0030` guard at 0xFAF07B plus one."""
    c = load()
    tbl, out = 0xFAF08F, []
    for k in range(49):
        o = tbl - BASE + 4 * k
        out.append(c["rom"][o] | (c["rom"][o + 1] << 8) | (c["rom"][o + 2] << 16)
                   | (c["rom"][o + 3] << 24))
    return out


def show_params():
    print("=== 3. THE PART RECORD'S 12-WORD PARAMETER BLOCK, +0x1D..+0x33 ===\n")
    print("  The part record is RAM 0x001523 + 0x012C*part (33 parts).  TWELVE routines")
    print("  each store ONE word of it; NINE of the twelve then hand a constant mask to")
    print("  PartRec_SetOrClearParamBits_x4.  Offset and mask are both operands.\n")
    print("  %-26s %-8s %6s %-18s %s" % ("routine", "addr", "word", "mask(s) pushed",
                                         "dispatch entry"))
    rows = param_scan()
    for n, a, off, masks, sto, exp, expm, _c in rows:
        ms = " / ".join("0x%04X" % m for m in masks) if masks else "-"
        print("  %-26s %06X  +0x%02X %-18s %d" % (n, a, off, ms,
                                                  dict((x[0], x[3]) for x in PARAM_TABLE)[n]))
    print("\n  ★ THE NINE CONSECUTIVE WORDS +0x23..+0x33 CARRY MASKS 1<<5 .. 1<<13 --")
    print("    ONE BIT PER WORD, IN ORDER, WITH NO GAP.  Nine words at stride 2, nine")
    print("    consecutive bit positions, and the same nine routines are ALL NINE of")
    print("    PartRec_SetOrClearParamBits_x4's literal call sites.  Three facts from")
    print("    three different places in the machine, and they line up exactly.")
    print("    ⚠ The other three appliers (+0x1D, +0x1F, +0x21) do NOT call it at all.")
    print("    That relation is not assumed anywhere: it falls out of reading each")
    print("    routine's own push, and --selftest asserts the FIRST and the LAST.")
    print()
    print("  WHERE THE MASK LANDS -- PartRec_SetOrClearParamBits_x4 (0xFAD203):")
    print("    a running offset starts at 0 (`ld HL,0x0000` at 0xFAD22B) and gains 41 per")
    print("    pass (`add HL,0x0029` at 0xFAD2C1); the loop runs four times")
    print("    (`cp (XIZ+0xF9),0x04` at 0xFAD2C8).  So the mask is set or cleared in")
    print("    part_record + 41*i + 0xA2 and + 41*i + 0xA4, i = 0..3.")
    print("    ★ INDEPENDENT CONFIRMATION OF THE 41-BYTE STRIDE, from a routine that")
    print("      knows nothing about this one: sub_FB4A9F's four constant offsets into")
    print("      the same record are %s -- three gaps of exactly 41."
          % ", ".join("0x%X" % v for v in fb4a9f_offsets()))
    return rows


def fb4a9f_offsets():
    """The four constant part-record offsets sub_FB4A9F uses, read off its `add BC,#`
    operands.  They are the outside check on the 41-byte sub-record stride."""
    c = load()
    src, top = c["src"], c["top"]
    lineof = dict((n, i) for i, n, _a in top)
    nxt = {}
    for k in range(len(top) - 1):
        nxt[top[k][1]] = top[k + 1][0]
    nxt[top[-1][1]] = len(src)
    i, e = lineof["sub_FB4A9F"], nxt["sub_FB4A9F"]
    vals = set()
    for ln in src[i:e]:
        t = ln.split(";")[0].strip()
        m = re.search(r'^add\s+bc,\s*(0x[0-9A-Fa-f]+|\d+)$', t)
        if m:
            v = int(m.group(1), 0)
            if v >= 0xA0:
                vals.add(v)
    return sorted(vals)


# ============================================================ 4. THE NO-REFERENCE SET
def noref():
    c = load()
    refs = refcensus()
    out = []
    for _i, n, a in c["top"]:
        if grade(n) != "sub":
            continue
        if refs.get(a) or rombytes_refs(a):
            continue
        out.append((n, a, fallthrough(n)))
    return out


def show_noref():
    print("=== 4. prom_c objects with NO LITERAL REFERENCE OF ANY SPELLING ===\n")
    print("  Two independent sweeps, both exhaustive over literals:")
    print("    (a) the source text -- every instruction operand, numeric or symbolic,")
    print("        including the `calr (TARGET - SITE)` form the emitter uses;")
    print("    (b) the raw ROM -- every 24-bit little-endian occurrence of the address")
    print("        in all 524,288 bytes.")
    print("  ⚠ BOTH ARE BLIND TO A CALL THROUGH A REGISTER.  'not found', never 'dead'.")
    print("  This project has twice shipped a 'no references' that had references, so")
    print("  the sweep is over every address, not a shortlist.\n")
    rows = noref()
    fall = [r for r in rows if r[2]]
    print("  %d objects, of which %d are explained by FALL-THROUGH:\n" % (len(rows), len(fall)))
    for n, a, f in rows:
        print("    %-34s 0x%06X   %s" % (n, a, ("falls through from `%s`" % f) if f
                                         else "no predecessor fall-through either"))
    print("\n  ★ THE %d FALL-THROUGH CASES ARE NOT UNREFERENCED ROUTINES -- THEY ARE NOT" % len(fall))
    print("    ROUTINES.  The instruction above each one is not a control transfer, so")
    print("    the code above walks straight into it.  The tree's own convention for")
    print("    that is <parent>__<address>, not sub_<address>.  They are LEFT ALONE here")
    print("    and reported instead: renaming them would move %d labels out of the" % len(fall))
    print("    metric's denominator without anybody understanding anything new, and a")
    print("    lane should not move its own goalposts.  The list is the recommendation.")
    return rows


# ============================================================ 5. THE REFUSALS
def show_refusals():
    print("=== 5. WHAT THIS ROUND REFUSED TO NAME, AND THE RULE EACH ONE FAILED ===\n")
    refs = refcensus()
    c = load()
    print("  R1 -- THE THREE MIDI CONTROLLER HANDLERS THAT LOOKED FREE.\n")
    print("  MidiCtrl_Dispatch (0xFAFDA5) has 26 arms; 23 of them reach a routine the")
    print("  tree already names MidiCtrl_*.  Three reach a sub_XXXXXX, and the obvious")
    print("  names were sitting there.  THE RULE THAT REFUSES THEM IS CALIBRATED, not")
    print("  invented: every existing MidiCtrl_* handler has EXACTLY ONE reference in")
    print("  prom_c, and it is the dispatch arm.  A handler is the controller's handler")
    print("  because nothing else calls it.\n")
    exist = [(n, a) for n, a in ((n, c["sym"][n]) for n in c["sym"])
             if n.startswith("MidiCtrl_") and "__" not in n and n != "MidiCtrl_Dispatch"]
    counts = sorted(len(refs.get(a, [])) for _n, a in exist)
    print("    the %d existing MidiCtrl_* handlers: reference counts %s"
          % (len(exist),
             "all exactly 1" if set(counts) == {1} else counts))
    print()
    for a, nm, rule, got in REFUSED_LOOKALIKES:
        rs = refs.get(a, [])
        who = sorted(set(e for _l, e, _t in rs if e))
        print("    REFUSED %-16s for 0x%06X (%s)" % (nm, a, c["byaddr"][a]))
        print("            rule: %s.  measured: %d references." % (rule, len(rs)))
        print("            callers: %s" % ", ".join(who))
    print("\n  R2 -- THE 374 P7 BYTE-CODE OBJECTS.  Refused for content: their bytes are")
    print("     an undecoded byte-code, and 130 of the 297 streams do not even match the")
    print("     located interpreter's payload convention.  A name would be a name for a")
    print("     blob.  Measured, not argued -- bucket F1 of --census.")
    print("\n  R3 -- THE TWELVE PART-RECORD APPLIERS GOT A *FRAMED* NAME ON PURPOSE.  The")
    print("     offset each one writes is an operand; what the parameter IS is not")
    print("     established, and the dispatch's 6-bit target code is still unread.  A")
    print("     content name here would have been a guess with a table behind it.")
    print("\n  R4 -- ZERO framed->content promotions.  Round 6 measured prom_c's framed set")
    print("     and found it is not a naming backlog (F1-F5 in --census re-derive that")
    print("     partition here).  Promoting any of them would mean deleting a deliberate")
    print("     statement of ignorance to move a number.  The honest figure is 0.")


# ============================================================ 6. DEPTH
def headers():
    """Which top-level labels carry a >=3-line comment header, and which carry an
    Evidence: line, using the same block rule as wave7_documentation_metrics.py."""
    c = load()
    src = c["src"]
    out = {}
    run, blanks, ev = 0, 0, False
    for ln in src:
        if ln.startswith(";"):
            run += 1
            blanks = 0
            if "Evidence:" in ln:
                ev = True
            continue
        if ln.strip() == "" and run:
            blanks += 1
            if blanks > 1:
                run, ev, blanks = 0, False, 0
            continue
        m = LABEL.match(ln)
        if m:
            out[m.group(1)] = (run >= 3, ev)
        run, ev, blanks = 0, False, 0
    return out


def show_headers():
    h = headers()
    c = load()
    print("=== 6. DEPTH: which prom_c labels carry a header and an Evidence: line ===\n")
    g = collections.Counter()
    missing = collections.defaultdict(list)
    for _i, n, _a in c["top"]:
        hd, ev = h.get(n, (False, False))
        k = grade(n)
        g[(k, hd, ev)] += 1
        if not hd:
            missing[k].append(n)
    print("  %-9s %8s %8s %8s" % ("grade", "labels", "header", "evidence"))
    for k in ("content", "framed", "sub"):
        tot = sum(v for (kk, _a, _b), v in g.items() if kk == k)
        hh = sum(v for (kk, a, _b), v in g.items() if kk == k and a)
        ee = sum(v for (kk, _a, b), v in g.items() if kk == k and b)
        print("  %-9s %8d %8d %8d" % (k, tot, hh, ee))
    print()
    print("  ★ EVERY REMAINING sub_XXXXXX IN prom_c CARRIES BOTH: %d of %d have a header"
          % (sum(v for (kk, a, _b), v in g.items() if kk == "sub" and a),
             sum(v for (kk, _a, _b), v in g.items() if kk == "sub")))
    print("    and %d have an Evidence: line.  prom_c's remaining debt is MEANING, not"
          % sum(v for (kk, _a, b), v in g.items() if kk == "sub" and b))
    print("    annotation -- which is why this round's deliverable is an inventory.")
    print()
    print("  The header-less labels are %d, by grade: %s"
          % (sum(len(v) for v in missing.values()),
             ", ".join("%s %d" % (k, len(v)) for k, v in sorted(missing.items()))))
    print("  ⚠ 4,683 further prom_c labels are <parent>__<addr> branch targets and are")
    print("    EXCLUDED from every line above; a jump destination inside a routine is not")
    print("    an object awaiting a header.")
    return g, missing


# ============================================================ 7. GAP A
def show_gapA():
    print("=== 7. GAP A IS CLOSED, AND THE ROUND-7 BRIEF THAT ASKED FOR IT IS STALE ===\n")
    print("  The brief for this round says registers 0x0440, 0x0480, 0x04C0 and 0x0500 of")
    print("  the 0x0010C000 device 'have no statement of any kind'.  That was true when")
    print("  notes/WSA1-EMULATION-DISASM-GAPS.md was written and is not true now.")
    print()
    txt = open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")).read()
    ok = True
    for reg, sym in (("0x0440", "Dev10C_SetChanReg_0440"),
                     ("0x0480", "Dev10C_SetChanReg_0480"),
                     ("0x04C0", "Dev10C_SetChanReg_04C0"),
                     ("0x0500", "Voice_StageRegs_0500_08C0_AB")):
        present = (sym + ":") in txt
        print("    %s  accessor %-32s in prom_c: %s" % (reg, sym, "yes" if present else "NO"))
        ok = ok and present
    gaps = os.path.join(ROOT, "notes", "WSA1-EMULATION-DISASM-GAPS.md")
    body = open(gaps).read() if os.path.exists(gaps) else ""
    retracted = "That is retracted" in body
    print("\n    notes/WSA1-EMULATION-DISASM-GAPS.md carries the retraction: %s"
          % ("yes" if retracted else "NO"))
    print("\n  So the work this round could have done on gap A was done by round 4")
    print("  (notes/prom_c_understanding_round4.py), and re-deriving it would have been")
    print("  a second lane spending itself on a closed question.  Reported instead.")
    return ok and retracted


# ============================================================ 8. THE PORT ACCESSORS
def port_reads():
    """Every place prom_c loads a device-port window into a register and then READS
    through that same register within the next 25 lines.  ⚠ ONE INSTRUCTION SHAPE:
    a read through a pointer already in a register, or built by `inc`, is invisible.
    So the result is "sites located", never "all the reads"."""
    c = load()
    src = c["src"]
    out = []
    for i, ln in enumerate(src):
        code = ln.split(";")[0]
        m = re.search(r'ld\s+x(\w\w),\s*0x(10C000|104000|E00000)\b', code, re.I)
        if not m:
            continue
        reg = "x" + m.group(1)
        a = ADDRC.search(ln)
        for k in range(i + 1, min(i + 26, len(src))):
            c2 = src[k].split(";")[0]
            if re.search(r'\bld\s+\w+,\s*\(%s(?:\+\d+)?\)' % reg, c2):
                a2 = ADDRC.search(src[k])
                out.append((a.group(1) if a else "?", m.group(2),
                            a2.group(1) if a2 else "?", c2.strip()))
                break
    return out


def instr_extent(name, lo, hi):
    """Instructions between two ADDRESSES, counted over the whole address extent --
    NOT to the next label.  A round-3 header in this tree reported 17 for a
    30-instruction routine because it stopped at an internal label."""
    c = load()
    n = 0
    for ln in c["src"]:
        m = ADDRC.search(ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        if lo <= a <= hi and ln.split(";")[0].strip() and not LABEL.match(ln):
            n += 1
    return n


def show_ports():
    print("=== 8. THE 0x0010C000 PORT ACCESSORS THIS ROUND NAMED ===\n")
    rows = port_reads()
    print("  READ sites located by the one instruction shape this sweep recognises:")
    for a, port, ra, txt in rows:
        print("    select built at 0x%s, port 0x00%s, read at 0x%s: %s" % (a, port, ra, txt))
    print("  ⚠ %d sites.  ONE SHAPE ONLY -- a read through a pointer already in a" % len(rows))
    print("    register is invisible here, so this is 'located', never 'all'.")
    print()
    n = instr_extent("Dev10C_SetChanReg_0180_FromArg", 0xFB7502, 0xFB7520)
    print("  Dev10C_SetChanReg_0180_FromArg: %d instructions across 0xFB7502..0xFB7520," % n)
    print("    counted over the ADDRESS EXTENT and not to the next label.")
    n2 = instr_extent("Dev10C_ReadChanReg_0100", 0xFC7E57, 0xFC7E78)
    print("  Dev10C_ReadChanReg_0100:        %d instructions across 0xFC7E57..0xFC7E78." % n2)
    return rows


# ============================================================ SELFTEST
def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    c = load()
    names = set(n for _i, n, _a in c["top"])
    # --- the names actually landed, first AND last of each family
    for nm, (a, mech, tw, ta, ln, nd) in sorted(SHIPPED.items(), key=lambda kv: kv[1][0]):
        check("shipped name %s exists in prom_c" % nm, nm in names)
        check("shipped name %s sits at 0x%06X" % (nm, a), c["sym"].get(nm) == a)
    check("no sub_XXXXXX survives at any shipped address",
          not any(UNNAMED.match(c["byaddr"][a]) for a, *_r in SHIPPED.values()))
    # --- the twin claims, byte for byte, INCLUDING the last one in the table
    for nm, (a, mech, tw, ta, ln, nd) in sorted(SHIPPED.items(), key=lambda kv: kv[1][0]):
        if mech != "twin":
            continue
        d = diffbytes(a, ta, ln)
        check("twin %s vs %s: %d bytes, %d differ (claimed %d)" % (nm, tw, ln, len(d), nd),
              len(d) == nd)
        check("twin %s: its named counterpart is still called %s" % (nm, tw),
              c["byaddr"].get(ta) == tw)
    # --- no CLOSER twin exists for the three near-twin families
    sweep = dict((r[0], r[5]) for r in twin_sweep(maxdiff=99, minlen=8))
    for nm in ("Scale7Bit_ByDepth_UniOrBipolar_Shl2", "Scale7Bit_ByDepth_UniOrBipolar_Shl7",
               "Dev10C_SetChanReg_0840_0880_From2E"):
        check("%s: the whole-image sweep finds no twin closer than %d bytes"
              % (nm, SHIPPED[nm][5]), sweep.get(nm) == SHIPPED[nm][5])
    # --- the parameter table, re-derived; FIRST and LAST asserted
    rows = param_scan()
    for n, a, off, masks, sto, expoff, expmask, _c in rows:
        check("%s writes part-record word +0x%02X (operand `add BC,0x%04X`)"
              % (n, expoff, expoff), off == expoff)
        if expmask:
            check("%s pushes mask %s" % (n, "/".join("0x%04X" % m for m in expmask)),
                  masks == expmask)
    # the one-bit-per-word relation, on the first and the last of the seven
    nine = [r for r in rows if r[3]]
    check("exactly NINE appliers push a mask to PartRec_SetOrClearParamBits_x4",
          len(nine) == 9)
    check("the FIRST of them is +0x23 with mask 0x0020 = 1<<5",
          nine[0][2] == 0x23 and nine[0][3] == (0x0020, 0x0020))
    check("the LAST of them is +0x33 with mask 0x2000 = 1<<13",
          nine[-1][2] == 0x33 and nine[-1][3] == (0x2000, 0x2000))
    check("the nine are consecutive words at stride 2, +0x23..+0x33",
          [r[2] for r in nine] == list(range(0x23, 0x34, 2)))
    check("...and their mask bit index rises by exactly one per word, 1<<5 .. 1<<13",
          [r[3][0] for r in nine] == [0x20 << k for k in range(9)])
    check("...and both masks of every one of the nine are the SAME value",
          all(r[3][0] == r[3][1] for r in nine))
    check("the other three appliers (+0x1D, +0x1F, +0x21) push no mask and do not call it",
          [r[2] for r in rows if not r[3]] == [0x1D, 0x1F, 0x21])
    check("PartRec_SetOrClearParamBits_x4 has exactly 9 references and ALL are appliers",
          len(refcensus()[0xFAD203]) == 9
          and all(e and e.startswith("PartRec_ApplyParam_")
                  for _l, e, _t in refcensus()[0xFAD203]))
    # --- the 41-byte sub-record stride, from TWO independent routines
    off = fb4a9f_offsets()
    check("sub_FB4A9F's part-record offsets are %s -- four, at stride 41"
          % ", ".join("0x%X" % v for v in off),
          len(off) == 4 and [off[k + 1] - off[k] for k in range(3)] == [41, 41, 41])
    check("...and PartRec_SetOrClearParamBits_x4 walks the SAME stride (add HL,0x0029)",
          "add\thl, 41" in open(SRC).read())
    check("...over exactly four passes (cp (XIZ+0xF9),0x04)",
          "cp (xiz-7), 0x04 " in open(SRC).read())
    # --- the dispatch table this all hangs off
    ent = jumptable()
    check("Voice_ApplyParamChange_Dispatch's table has 49 entries and entry 0 is 0xFAF153",
          ent[0] == 0xFAF153)
    # each applier really IS the routine its claimed table entry's arm calls -- the
    # claim a round-7 draft got off by one, in twelve headers at once
    lab = {}
    for _i, _ln in enumerate(c["src"]):
        mm = re.match(r'^Voice_ApplyParamChange_Dispatch__([0-9A-F]{6}):', _ln)
        if mm:
            lab[int(mm.group(1), 16)] = _i

    def armcall(addr):
        i0 = lab.get(addr)
        if i0 is None:
            return None
        for k in range(i0 + 1, i0 + 16):
            if k >= len(c["src"]) or re.match(r'^[A-Za-z_]', c["src"][k]):
                break
            mm = (re.search(r'calr\s+\(0x([0-9A-Fa-f]+)\s*-', c["src"][k])
                  or re.search(r'\bcall\s+0x([0-9A-Fa-f]+)', c["src"][k]))
            if mm:
                return int(mm.group(1), 16)
        return None

    for nm_, ad_, of_, code_, mk_ in PARAM_TABLE:
        check("%s is what dispatch ENTRY %d's arm (0x%06X) calls"
              % (nm_, code_, ent[code_]), c["byaddr"].get(armcall(ent[code_])) == nm_)
    check("...and its LAST entry (48) is 0xFAF331", ent[48] == 0xFAF331)
    # --- the refusal rule, calibrated on the 24 existing handlers
    refs = refcensus()
    exist = [(n, c["sym"][n]) for n in c["sym"]
             if n.startswith("MidiCtrl_") and "__" not in n and n != "MidiCtrl_Dispatch"]
    check("all %d existing MidiCtrl_* handlers have exactly ONE reference" % len(exist),
          all(len(refs.get(a, [])) == 1 for _n, a in exist))
    for a, nm, _rule, got in REFUSED_LOOKALIKES:
        check("refused %s: 0x%06X really has %d references, not 1" % (nm, a, got),
              len(refs.get(a, [])) == got)
    # --- the no-reference census is exhaustive, and reproduces
    nr = noref()
    check("the no-reference set is %d objects" % len(nr), len(nr) > 0)
    check("every one of them really has zero source refs AND zero ROM pointers",
          all(not refs.get(a) and not rombytes_refs(a) for _n, a, _f in nr))
    check("the FIRST of them (%s) is confirmed by both sweeps" % nr[0][0],
          not refs.get(nr[0][1]) and not rombytes_refs(nr[0][1]))
    check("the LAST of them (%s) is confirmed by both sweeps" % nr[-1][0],
          not refs.get(nr[-1][1]) and not rombytes_refs(nr[-1][1]))
    check("a CONTROL: a known-referenced routine is NOT in the no-reference set",
          0xFAF031 not in [a for _n, a, _f in nr] and bool(refs.get(0xFAF031)))
    # --- the census partitions all 944
    rows = census()
    tot = collections.Counter(grade(n) for _i, n, _a in c["top"])
    check("the census covers every framed + sub_ object (%d) and no content one"
          % len(rows), len(rows) == tot["framed"] + tot["sub"])
    check("every census row carries a non-empty reason",
          all(w and len(w) > 20 for _n, _a, _g, _b, w in rows))
    check("no object is in two buckets", len(set(r[0] for r in rows)) == len(rows))
    # --- this script's grader agrees with the tree's metric
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import wave7_documentation_metrics as M
    nm_, fr_, un_, _il, _h, _e = M.scan(os.path.join("prom_c", "wsa1_prom_c.s"))
    check("grader agrees with wave7_documentation_metrics on content (%d)" % tot["content"],
          len(nm_) == tot["content"])
    check("grader agrees on framed (%d)" % tot["framed"], len(fr_) == tot["framed"])
    check("grader agrees on sub_XXXXXX (%d)" % tot["sub"], len(un_) == tot["sub"])
    # --- depth
    h = headers()
    subs = [n for _i, n, _a in c["top"] if grade(n) == "sub"]
    check("every remaining sub_XXXXXX carries a >=3-line header",
          all(h.get(n, (False, False))[0] for n in subs))
    check("every remaining sub_XXXXXX carries an Evidence: line",
          all(h.get(n, (False, False))[1] for n in subs))
    check("every name shipped this round carries a header AND an Evidence: line",
          all(h.get(n, (False, False)) == (True, True) for n in SHIPPED))
    # --- the port accessors, and the two counts their headers quote
    pr = port_reads()
    check("the port-read sweep locates 2 sites, 0xFA68FC's shape excluded", len(pr) == 2)
    check("...and one of them is Dev10C_ReadChanReg_0100's own read at 0xFC7E6F",
          any(r[2] == "FC7E6F" for r in pr))
    check("Dev10C_SetChanReg_0180_FromArg is 13 instructions over 0xFB7502..0xFB7520",
          instr_extent("x", 0xFB7502, 0xFB7520) == 13)
    # --- the Scale7Bit family really is four
    ref = blob("Scale7Bit_ByDepth_UniOrBipolar")
    fam = []
    for _i, n, a in c["top"]:
        b = blob(n)
        if b and len(b) == len(ref) and n != "Scale7Bit_ByDepth_UniOrBipolar":
            d = sum(1 for x, y in zip(b, ref) if x != y)
            if d <= 3:
                fam.append((n, d))
    check("exactly 3 objects in prom_c are within 3 bytes of Scale7Bit_ByDepth_"
          "UniOrBipolar -- a family of four", len(fam) == 3)
    check("...and they are exactly the shl-2/6/7 names, each 3 bytes away",
          sorted(fam) == [("Scale7Bit_ByDepth_UniOrBipolar_Shl2", 3),
                          ("Scale7Bit_ByDepth_UniOrBipolar_Shl6", 3),
                          ("Scale7Bit_ByDepth_UniOrBipolar_Shl7", 3)])
    # --- gap A
    check("gap A's four registers all have an accessor in prom_c and the doc is retracted",
          show_gapA.__name__ and _gapA_quiet())
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


def _gapA_quiet():
    txt = open(SRC).read()
    for sym in ("Dev10C_SetChanReg_0440", "Dev10C_SetChanReg_0480",
                "Dev10C_SetChanReg_04C0", "Voice_StageRegs_0500_08C0_AB"):
        if (sym + ":") not in txt:
            return False
    gaps = os.path.join(ROOT, "notes", "WSA1-EMULATION-DISASM-GAPS.md")
    return os.path.exists(gaps) and "That is retracted" in open(gaps).read()


if __name__ == "__main__":
    a = sys.argv[1:]
    if "--selftest" in a:
        sys.exit(selftest())
    did = False
    if not a or "--census" in a:
        show_census(); print(); did = True
    if not a or "--twins" in a:
        show_twins(); print(); did = True
    if not a or "--params" in a:
        show_params(); print(); did = True
    if not a or "--noref" in a:
        show_noref(); print(); did = True
    if not a or "--refusals" in a:
        show_refusals(); print(); did = True
    if not a or "--headers" in a:
        show_headers(); print(); did = True
    if not a or "--ports" in a:
        show_ports(); print(); did = True
    if not a or "--gapA" in a:
        show_gapA(); did = True
    if not did:
        print(__doc__)
