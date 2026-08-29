#!/usr/bin/env python3
"""Make prom_a's 0xFAD800 module UNDERSTOOD, and name the layer it publishes into.

QUESTION IT ANSWERS
    "prom_a is the least-understood image in the tree -- 1,342 labels that state
     content against 278 framed and 2,989 `sub_XXXXXX`.  The 0xFAD800 span was
     converted in wave 7 round 1 WITHOUT names.  What, mechanically, does that
     module do, which of its routines can be named from evidence already in the
     tree, and which cannot?"

    Three things came out of asking it, and each is reproduced below by a check
    rather than asserted:

  ★ 1. THE MODULE'S TWENTY PUBLISHED ENTRY POINTS HAD NO LABEL AT ALL.
       `T_F40850`-`T_F4089C` is a run of twenty prom_b directory slots, every one
       of which `jp`s into 0xFAD800-0xFAE000, and not one of those twenty target
       addresses carried a label in prom_a/wsa1_prom_a.s.  (⚠ The SPAN as a whole
       carries 33 published entry points in three runs -- this run of 20, the
       twelve of `T_F41F10`-`T_F41F3C` for the second module at 0xFAE800 upward,
       and `T_F40840` for the tail at 0xFB1800.  --slots prints all 33 and none
       of the 33 had a label either; this pass names the first run.)  The emitter that
       converted the span (notes/gen_prom_a_fad800_module.py) labels a routine
       only when its own descent reaches it, and a `jp` that lives in the OTHER
       image is invisible to that descent.  So the module read as one unbroken
       4,000-byte instruction stream.  --slots lists the twenty.

  ★ 2. THE MODULE IS THE PARAMETER-APPLY LAYER, and its data structure was
       already in the tree under a name that says it is NOT one.
       prom_a 0xFACDEA is named `Lookup32_By_Arg8` and its header says
       "Unknown: what the 16-bit values ARE.  They are NOT addresses in any image
       of this machine ... and 0xFFFFFFFF reads as 'absent' but nothing in the
       module tests for it."  Both halves are wrong and --table proves it:

         * the values ARE addresses -- 16-bit WORK-RAM addresses, exactly the
           form prom_b's `RamPtrTable_F7554D` header already describes ("74
           32-bit words, every one below 0x10000, i.e. a 16-bit RAM address
           stored one per long word");
         * three instructions DO test for 0xFFFFFFFF after reading through this
           table -- `cp XIX,0xffffffff` at 0xFAA5BF, 0xFAA63B and 0xFAA682;
         * entry k + 0x0D == `MidiOut_PartRecordPtrs_00`[k] for ALL 32 of that
           already-named table's entries, so entries 0x00-0x1F are the 32 PART
           RECORDS the tree names elsewhere, at their base rather than at +0x0D;
         * entry[0x20+i] == entry[i] + 0x20 for all 32, which is why
           `Evt2030_ClassHandlers` sends parameter numbers 0x00-0x1F and
           0x20-0x3F to two different handlers: they are the two halves of one
           0x40-byte record;
         * `Evt2030_ClassHandlers` has a handler for exactly eleven parameter
           numbers that this table leaves empty, and those eleven are EXACTLY the
           eleven `Evt2030_ClassXX_Fwd` forwarders round 3 named from the other
           table.  Two independently-derived objects agreeing on an eleven-element
           set is the strongest evidence in this file.

       So the name becomes `ParamNumber_RecordPtrs` and the header says what it
       holds.  The old name and its two false sentences are replaced, not
       supplemented -- correcting the old text in the same change is the rule.

  ★ 3. ONE 2-BIT SELECTOR RUNS SIX SEPARATE DISPATCH TABLES IN THIS SPAN.
       `(0x7F32) & 3` chooses the arm at 0xFADDE6, 0xFADF6C, 0xFAE03D, 0xFAE284,
       0xFAE302 and 0xFAF6AB.  (0x7F32) is parameter number 0x80's record byte
       (entry[0x80] of the table above IS 0x7F32), its bit 2 is the already-named
       follow-external-clock bit, and prom_b 0xF6F858 writes its low two bits
       from (0x1380) and then publishes them as {parameter 0x80, field 0, mask
       0x03}.  ⚠ WHAT THE FOUR VALUES MEAN IS NOT ESTABLISHED, so the 24 arms
       KEEP their `sub_XXXXXX` names and get a header that says which table,
       which index, which selector, and that the selector's meaning is open.
       A stated gap beats a plausible guess.

HOW A LABEL GETS INSERTED INTO A SPAN WITH NO ADDRESS COMMENTS
    gen_prom_a_fad800_module.py emits code lines with no `; ADDR` comment, so
    there is nothing to search for.  `--map` rebuilds the line -> address map
    from scratch: it seeds at the region banner, resynchronises at every one of
    the 42 `; --- 0xLO-0xHI ... ---` data banners, sizes `.byte`/`.long`/`.fill`
    lines from their own operands, and sizes every instruction line by decoding
    the ROM at the current address.  It then CHECKS itself against every
    `.LXXXXXX:`/`sub_XXXXXX:` label and every `; ADDR` comment inside the region,
    and against the region end.  0 mismatches, ending exactly on 0xFB2000, is
    what licenses an insertion; --apply refuses if that is not what it gets.

  ★ 4. TWENTY FRAMED NAMES BECAME CONTENT NAMES, mechanically.
       `MidiOut_PartRecordPtrs_00`..`_24` are TWENTY-FIVE BYTE-IDENTICAL tables,
       so the number in each name says only "the Nth in address order" -- the one
       thing that distinguishes a block is the routine whose `ld XIX,<base>`
       names it.  Eleven blocks have exactly one such reader and that reader
       already has a name, so eleven become `..._CC07Volume`, `..._Rpn01FineTune`
       and so on; block 0 (five readers) and blocks 16/17 (one reader between
       them) are left alone and --gaps says why.  Likewise the eleven
       `MidiOut_ChangeRecord_NN` carry a routine pointer in their own bytes
       [4:8]; nine of those point at a named routine, so nine become
       `..._CC0BExpression` and the like.  Both families are generated from the
       ROM, not typed.

  ★ 5. SEVEN LABELS GLOSSED A CONTROLLER WITH A WORD THIS MACHINE DOES NOT USE.
       prom_a 0xFA2BC3 and 0xFA2CC3 hold two lists of sixteen-byte ASCII
       controller names, and every entry carries its own controller number in
       its own text (`MODULATION2(# 2)`, `HOLD       (#64)`).  Against that list:

         CC 0x02  named `Breath`    -- the ROM says MODULATION2 (# 2)
         CC 0x04  named `Foot`      -- the ROM says CTRL.PEDAL (# 4)
         CC 0x10  named `General1`  -- the ROM says R.T.CREAT.X(#16)
         CC 0x11  named `General2`  -- the ROM says R.T.CREAT.Y(#17)
         CC 0x12  named `General3`  -- the ROM says R.T.CTRL. X(#18)
         CC 0x13  named `General4`  -- the ROM says R.T.CTRL. Y(#19)
         CC 0x40  named `Damper`    -- the ROM says HOLD       (#64)

       Every one of those seven glosses is the MIDI 1.0 spec's word for the
       controller NUMBER, which is why they looked right; none is this
       instrument's word for it, and `BREATH` and `DAMPER` occur ZERO times in
       all four images while `GENERAL`'s 23 occurrences are all in prom_b and
       none of them is a controller name (check W2).  That is the same failure
       the round-3 reviewers found with the invented morpheme "Home", one step
       milder: a plausible word, not carried by the ROM, that a reader cannot
       chase.  Twenty-two labels are renamed to the machine's own word; the
       controller NUMBER in each name is untouched, because that is the half
       that was already proven.  --controllers prints both lists from the ROM.

⚠ WHAT THIS FILE DELIBERATELY DOES NOT DO
    It does not name a routine from a call count, does not rename
    `MidiOut_CC01_Modulation` or `MidiOut_CC0B_Expression` (the ROM agrees with
    both), does not touch `CC51_General6` (controller #81 is in neither ROM
    list), and it does not name the four
    values of the (0x7F32) selector, the four `(0x60F308) & 3` arms, or the two
    unreferenced handlers at 0xFADD60/0xFADD89.  Those get headers stating the
    gap.  It also does not touch the second module in the span (the
    `T_F41F10`-`T_F41F3C` run at 0xFAE800 upward) beyond the arm headers: its two
    pointer tables at 0xFAE802 and 0xFAE83E are loaded by NOTHING in any of the
    four transcriptions (--tables), and a table nobody reads names nothing.

  ★ 6. THE CHECK THAT CAUGHT THIS PASS'S OWN WORST DEFECT.
       `--selftest`'s check Z1 pulls every `` `text` at 0xADDR `` citation out of
       every header this file defines -- 112 of them -- decodes the ROM AT that
       address and compares.  On its first run it FAILED on EIGHT of this pass's
       own citations, all in the ParamShadow_FlushAll / Evt2030_RunList cluster,
       each sitting a few bytes off the instruction (`cp A,0xff` cited at
       0xFADB4D when it is at 0xFADB50; `ld W,0xb3` at 0xFADA31 when it is at
       0xFADA2B; and six more).  That is the same defect wave 7 round 1 shipped
       about 31 times and it happened here because the citations were read off a
       listing of the emitted span, which carries NO address comments.  All eight
       are corrected and the corrections are pushed back into the `.s` by
       HEADER_REWRITE.  ⚠ A pass that cites instructions inside this span without
       running Z1 will make the same mistake.
       Check I1/I2 -- the instruction counts, taken across a routine's whole
       ADDRESS EXTENT rather than to the next label -- then caught a NINTH: this
       pass's first ParamShadow_FlushAll header opened `Body: \`ldio 0x10,0x20\`
       (interrupt level), then five sweeps`, and that instruction is at 0xFADA23,
       six bytes BEFORE the routine starts -- it is not an instruction at all but
       the last three bytes of OrdinalToBitMask6, which the emitter spelled as
       code.  Corrected too.

⚠ WHAT MOVED, MEASURED
    `python3 notes/wave7_documentation_metrics.py`, prom_a row, before -> after:

        content 1,342 -> 1,395   framed 278 -> 258   sub_XXXXXX 2,989 -> 2,979
        headers   861 ->   974   evidence 966 -> 1,066   LOWER 29.1% -> 30.1%

    The framed column falls by exactly the 20 promotions of point 4; the content
    column rises by more than that because 22 routines that had no label at all
    now have one.  ⚠ `--range a 0xFAD800 0xFB2000` UNDERCOUNTS this span badly
    (it reads 91 labels where the span has 105): that tool attributes a label to
    the last `; ADDR` comment it saw, and the emitted span has none, so labels
    there inherit an address from before the span.  The IMAGE row is the honest
    number.  The metrics selftest's own invariant -- that the named-as-it-went
    span 0xFA5AEB still leads 0xFAD800 -- still holds, so no constant there
    needs changing.

RUN
    python3 notes/prom_a_understanding_round4.py             # the module map
    python3 notes/prom_a_understanding_round4.py --slots     # the 20 entry points
    python3 notes/prom_a_understanding_round4.py --table     # the record-pointer table
    python3 notes/prom_a_understanding_round4.py --tables    # every dispatch table in the span
    python3 notes/prom_a_understanding_round4.py --controllers  # the ROM's own controller names
    python3 notes/prom_a_understanding_round4.py --map       # line -> address, with its checks
    python3 notes/prom_a_understanding_round4.py --plan      # what --apply would write
    python3 notes/prom_a_understanding_round4.py --twins     # the byte-identical-twin
                                                             # lever, and why it is empty
    python3 notes/prom_a_understanding_round4.py --gaps      # what is left, and why
    python3 notes/prom_a_understanding_round4.py --apply     # rewrite prom_a/wsa1_prom_a.s
    python3 notes/prom_a_understanding_round4.py --selftest  # every number above, re-derived,
                                                             # on the LAST element as well as
                                                             # the first
"""
import collections
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARGV = list(sys.argv)
A_BASE, B_BASE = 0xF80000, 0xF00000
SRC = {"a": os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"),
       "b": os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"),
       "c": os.path.join(ROOT, "prom_c", "wsa1_prom_c.s"),
       "d": os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")}
ROMS = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
        "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}
UNIDASM = os.environ.get(
    "UNIDASM", os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm"))

LO, HI = 0xFAD800, 0xFB2000          # the module span this lane documents
PARAMPTRS = 0xFACDEA                 # the record-pointer table, 256 LE32 entries
EVT2030 = 0xFAE3A2                   # parameter number -> handler, 192 LE32 entries
PARTPTRS = "MidiOut_PartRecordPtrs_00"

_rom = {}


def rom(img):
    if img not in _rom:
        _rom[img] = open(os.path.join(ROOT, "original_ROMs", ROMS[img]), "rb").read()
    return _rom[img]


def base(img):
    return {"a": A_BASE, "b": B_BASE, "c": A_BASE, "d": 0}[img]


def w32(img, a):
    d, b = rom(img), base(img)
    return int.from_bytes(d[a - b:a - b + 4], "little")


def by(img, a, n=1):
    d, b = rom(img), base(img)
    return d[a - b:a - b + n]


# ---------------------------------------------------------------- disassembly
def dis_run(img, lo, hi):
    """{addr: (nbytes, text)} for one CONTIGUOUS code run, one unidasm call.

    Decoding a run in one call rather than an instruction at a time is what
    makes --map cheap enough to run on every --apply.  The run must be code all
    the way through; --map only ever asks for runs it derived from the data
    banners, so a data byte never enters one."""
    d, b = rom(img), base(img)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[lo - b:hi - b])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(lo)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    res = {}
    for ln in out.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            res[int(m.group(1), 16)] = (len(m.group(2).split()), m.group(3).strip())
    return res


def dis_at(img, addr, window=0x30):
    return dis_run(img, addr, addr + window).get(addr)


# --------------------------------------------------------------------- labels
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
UNNAMED = re.compile(r'^sub_([0-9A-Fa-f]{6})$')
SELFADDR = re.compile(r'^(?:sub|T)_([0-9A-Fa-f]{6})$')
LOCALADDR = re.compile(r'^\.L([0-9A-Fa-f]{6})$')
ADDRC = re.compile(r';\s*([0-9A-F]{6})\b')
BANNER = re.compile(r'^;\s*---\s*0x([0-9A-F]{6})-0x([0-9A-F]{6})\s')
REGION = re.compile(r'^;\s*====\s*0x([0-9A-F]{6})-0x([0-9A-F]{6})\s')
D_BYTE = re.compile(r'^\s*\.byte\s+(.*)$')
D_LONG = re.compile(r'^\s*\.long\s')
D_SHORT = re.compile(r'^\s*\.short\s')
D_FILL = re.compile(r'^\s*\.fill\s+0x([0-9a-fA-F]+)\s*,\s*(\d+)')
D_ASCII = re.compile(r'^\s*\.ascii\s+"(.*)"\s*$')

_lines = {}


def lines(img):
    if img not in _lines:
        _lines[img] = open(SRC[img], encoding="utf-8").read().split("\n")
    return _lines[img]


def labels(img):
    """[(name, addr)] for every column-0 label, `.L` locals excluded.

    A `sub_`/`T_` label carries its own address; any other takes the address
    comment of the next line, but ONLY if no line WITHOUT one intervenes -- the
    condition prom_a_naming_round3.py added after the naive scan collapsed 2,153
    prom_b thunk labels onto one address."""
    out, pending = [], []
    for ln in lines(img):
        m = LABEL.match(ln)
        if m:
            nm = m.group(1)
            if nm.startswith(".L"):
                continue
            sa = SELFADDR.match(nm)
            if sa:
                out.append((nm, int(sa.group(1), 16)))
            else:
                pending.append(nm)
            continue
        if not ln.strip() or ln.lstrip().startswith(";"):
            continue
        am = ADDRC.search(ln)
        if pending:
            if am:
                a = int(am.group(1), 16)
                for nm in pending:
                    out.append((nm, a))
            pending = []
    return out


def name_at(img):
    d = {}
    for n, a in labels(img):
        d.setdefault(a, []).append(n)
    return d


# ------------------------------------------------------------- the line map
def region_bounds():
    """(first_line, last_line) of the 0xFAD800 emitted region in prom_a."""
    src = lines("a")
    start = None
    for i, l in enumerate(src):
        m = REGION.match(l)
        if m and int(m.group(1), 16) == LO:
            start = i
            break
    if start is None:
        raise SystemExit("the 0xFAD800 region banner is gone from prom_a")
    end = len(src)
    for i in range(start + 1, len(src)):
        if src[i].startswith("; 0x%06X-" % HI):
            end = i
            break
    return start, end


def region_map():
    """({line: addr}, [mismatch, ...], final_addr).

    The walker described in the module docstring.  `mismatches` empty AND
    final_addr == HI is the licence to insert a label by address."""
    src = lines("a")
    start, end = region_bounds()
    banners = []
    for i in range(start + 1, end):
        m = BANNER.match(src[i])
        if m:
            lo, hi = int(m.group(1), 16), int(m.group(2), 16)
            if LO <= lo < HI:
                banners.append((i, lo, hi))
    runs, cur = [], LO
    for _i, lo, hi in banners:
        if lo > cur:
            runs.append((cur, lo))
        cur = max(cur, hi)
    if cur < HI:
        runs.append((cur, HI))
    lens = {}
    for lo, hi in runs:
        for a, (n, _t) in dis_run("a", lo, hi).items():
            lens[a] = n

    addr, lmap, bad = LO, {}, []
    for i in range(start + 1, end):
        l = src[i]
        m = BANNER.match(l)
        if m:
            lo = int(m.group(1), 16)
            if addr != lo:
                bad.append((i, "data banner", "0x%06X" % addr, "0x%06X" % lo))
            addr = lo
            continue
        if not l.strip() or l.startswith(";"):
            continue
        lm = LABEL.match(l)
        if lm:
            nm = lm.group(1)
            am = SELFADDR.match(nm) or LOCALADDR.match(nm)
            if am:
                want = int(am.group(1), 16)
                if want != addr:
                    bad.append((i, "label " + nm, "0x%06X" % addr, "0x%06X" % want))
                addr = want
            lmap[i] = addr
            continue
        lmap[i] = addr
        am = ADDRC.search(l)
        if am:
            want = int(am.group(1), 16)
            if want != addr:
                bad.append((i, "addr comment", "0x%06X" % addr, "0x%06X" % want))
            addr = want
        b = D_BYTE.match(l)
        if b:
            addr += len([x for x in b.group(1).split(";")[0].split(",") if x.strip()])
        elif D_LONG.match(l):
            addr += 4
        elif D_SHORT.match(l):
            addr += 2
        elif D_FILL.match(l):
            f = D_FILL.match(l)
            addr += int(f.group(1), 16) * int(f.group(2))
        elif D_ASCII.match(l):
            addr += len(D_ASCII.match(l).group(1).encode().decode("unicode_escape"))
        else:
            n = lens.get(addr)
            if n is None:
                bad.append((i, "no decode", "0x%06X" % addr, l.strip()[:40]))
                break
            addr += n
    return lmap, bad, addr


def line_of(addr):
    """The FIRST line of the region whose address is `addr`, or None."""
    lmap, bad, fin = region_map()
    if bad or fin != HI:
        return None
    for i in sorted(lmap):
        if lmap[i] == addr:
            return i
    return None


# ----------------------------------------------------- the twenty entry points
# Derived, not typed: every prom_b directory slot whose `jp` lands inside the
# span.  The directory's own text is the authority.
THUNK = re.compile(r'^T_([0-9A-F]{6}):\s*jp\s+0x([0-9A-F]{6})')


def slots(lo=None, hi=None):
    """[(slot, target)] for every prom_b directory slot whose `jp` lands in the
    span, optionally restricted to a run of SLOT addresses."""
    out = []
    for ln in lines("b"):
        m = THUNK.match(ln)
        if m:
            s, t = int(m.group(1), 16), int(m.group(2), 16)
            if LO <= t < HI and (lo is None or lo <= s <= hi):
                out.append((s, t))
    return sorted(out)


MODULE_RUN = (0xF40850, 0xF4089C)      # the parameter-apply module's own run


def module_slots():
    return slots(*MODULE_RUN)


CALLISH = re.compile(r'\b(call|calr|jp|jr|jrl)\b')


def slot_refs(slot):
    """How many call/jump instruction lines in ANY of the four transcriptions
    name this directory slot.  An upper bound on call sites -- it counts the
    text, not a decode -- and it is reported as such."""
    pat = "0x%06x" % slot
    n = 0
    for img in "abcd":
        for l in lines(img):
            if pat in l.lower() and CALLISH.search(l) and not l.lstrip().startswith(";"):
                n += 1
    return n


_REGCACHE = {}


def region_labels():
    """{addr: [names]} for every column-0 label inside the emitted region,
    resolved through the line map rather than through an address comment --
    the region has no address comments on its code lines, so labels() cannot
    place the named ones and reports them at no address at all."""
    if "r" in _REGCACHE:
        return _REGCACHE["r"]
    lmap, bad, fin = region_map()
    src, out = lines("a"), {}
    for i, a in lmap.items():
        m = LABEL.match(src[i])
        if m and not m.group(1).startswith(".L"):
            out.setdefault(a, []).append(m.group(1))
    _REGCACHE["r"] = out
    return out


def labels_at(addr):
    if LO <= addr < HI:
        return region_labels().get(addr, [])
    return name_at("a").get(addr, [])


def show_slots():
    s = slots()
    ms = module_slots()
    print("prom_b directory slots that publish an entry point inside "
          "0x%06X-0x%06X: %d, in three runs." % (LO, HI, len(s)))
    print("  T_%06X-T_%06X  %d slots -- the parameter-apply module this pass "
          "documents" % (MODULE_RUN[0], MODULE_RUN[1], len(ms)))
    print("  T_F41F10-T_F41F3C  12 slots -- the SECOND module at 0xFAE800 upward")
    print("  T_F40840            1 slot  -- 0xFB1800, the span's tail\n")
    print("%-10s %-10s %6s  %s" % ("slot", "target", "refs", "label in prom_a today"))
    reg = region_labels()
    for slot, t in s:
        print("T_%06X  0x%06X %6d  %s"
              % (slot, t, slot_refs(slot), ", ".join(reg.get(t, ["-- none --"]))))
    print("\n`refs` counts call/jump LINES naming the slot in any of the four "
          "transcriptions,\nincluding the directory's own `jp`; it is an upper "
          "bound on call sites, not a count.")
    return 0


# ----------------------------------------------- the parameter-record pointers
def param_table():
    """The 0xFACDEA analysis.  Everything --table prints and every claim the
    new header makes comes from here."""
    e = [w32("a", PARAMPTRS + 4 * i) for i in range(256)]
    live = [i for i, v in enumerate(e) if v != 0xFFFFFFFF]
    steps = [e[i + 1] - e[i] for i in range(31)]
    # MidiOut_PartRecordPtrs_00, read out of the .s where it is already named
    src = lines("a")
    k = [i for i, l in enumerate(src) if l.startswith(PARTPTRS + ":")]
    part = []
    if k:
        for l in src[k[0] + 1:k[0] + 40]:
            m = re.match(r'\s*\.long\s+0x([0-9A-Fa-f]+)', l)
            if not m:
                break
            part.append(int(m.group(1), 16))
    h = [w32("a", EVT2030 + 4 * i) for i in range(192)]
    rec = set(i for i in range(192) if e[i] != 0xFFFFFFFF)
    hnd = set(i for i in range(192) if h[i] != 0xFFFFFFFF)
    return dict(e=e, live=live, steps=steps, part=part, h=h, rec=rec, hnd=hnd)


def show_table():
    t = param_table()
    e, live, part = t["e"], t["live"], t["part"]
    print("prom_a 0x%06X -- 256 LE32 words." % PARAMPTRS)
    print("  live entries (not 0xFFFFFFFF): %d;  empty: %d" % (len(live), 256 - len(live)))
    print("  every live value is below 0x10000: %s   range 0x%04X..0x%04X"
          % (all(e[i] < 0x10000 for i in live),
             min(e[i] for i in live), max(e[i] for i in live)))
    print("  entries 0xC0-0xFF are ALL empty: %s"
          % all(e[i] == 0xFFFFFFFF for i in range(0xC0, 0x100)))
    print("  entries 0x00-0x1F step by 0x40 except ONE step of 0x80, after index %s"
          % [i for i, s in enumerate(t["steps"]) if s == 0x80])
    print("  entry[0x20+i] == entry[i] + 0x20 for all 32: %s"
          % all(e[0x20 + i] == e[i] + 0x20 for i in range(32)))
    print("  %s[i] == entry[i] + 0x0D for all %d: %s  (last: 0x%04X vs 0x%04X)"
          % (PARTPTRS, len(part),
             all(part[i] == e[i] + 0x0D for i in range(len(part))),
             part[-1] if part else 0, e[len(part) - 1] + 0x0D if part else 0))
    rec, hnd = t["rec"], t["hnd"]
    print("\n  against Evt2030_ClassHandlers (0x%06X, 192 entries):" % EVT2030)
    print("    parameter numbers with a record        : %d" % len(rec))
    print("    parameter numbers with a handler       : %d" % len(hnd))
    print("    with BOTH                              : %d" % len(rec & hnd))
    print("    record but NO handler (%2d): %s"
          % (len(rec - hnd), " ".join("%02X" % x for x in sorted(rec - hnd))))
    print("    handler but NO record (%2d): %s"
          % (len(hnd - rec), " ".join("%02X" % x for x in sorted(hnd - rec))))
    print("    ...and those are exactly the eleven Evt2030_ClassXX_Fwd forwarders.")
    print("\n  the three instructions that test a fetched entry for 0xFFFFFFFF:")
    for a in FFFF_TESTS:
        print("    0x%06X  %s" % (a, dis_at("a", a)[1]))
    print("\n  the three instructions that load 0x%06X into (0x60F018):" % PARAMPTRS)
    for a in PTR_WRITERS:
        print("    0x%06X  %s" % (a, dis_at("a", a)[1]))
    return 0


FFFF_TESTS = (0xFAA5BF, 0xFAA63B, 0xFAA682)
PTR_WRITERS = (0xFAA873, 0xFAA94E, 0xFAB7F4)


# ---------------------------------------------------- the span's jump tables
# (table, entries, reader, selector, owner).  `reader` is the address of the
# `ld XIX/XIY,<table>` instruction; None means NOTHING in any of the four
# transcriptions contains the table's address as a 32-bit little-endian word.
DISPATCH = [
    (0xFADBA9, 12, "B, bounded by `cp L,0x0b` at 0xFADB95", "Evt2030_Class00to1F"),
    (0xFADCBE, 3, "B - 0x18, bounded by `cp L,2` at 0xFADCAB", "Evt2030_Class20to3F"),
    (0xFADD77, 4, "B, bounded by `cp L,3` at 0xFADD64",
     "the handler at 0xFADD60, which NOTHING references"),
    (0xFADDA0, 2, "B, bounded by `cp L,1` at 0xFADD8D",
     "the handler at 0xFADD89, which NOTHING references"),
    (0xFADDC1, 2, "B, bounded by `cp L,1` at 0xFADDAE", "Evt2030_Class98"),
    (0xFADDF1, 4, "(0x7F32) & 3", "Evt2030_Class98_Op01"),
    (0xFADF77, 4, "(0x7F32) & 3", "ParamApply_ByModeOfParam80"),
    (0xFAE04D, 4, "(0x7F32) & 3", "the tail of ParamApply_ByModeOfParam80"),
    (0xFAE28F, 4, "(0x7F32) & 3", "ParamApply_StorePairAndDerive"),
    (0xFAE30E, 4, "(0x7F32) & 3", "Evt2030_Class00to1F_Op00"),
    (0xFAE802, 8, "-- no reader found --", "nothing"),
    (0xFAE83E, 3, "-- no reader found --", "nothing"),
    (0xFAE9D0, 16, "W & 0x0F", "the routine at 0xFAE921"),
    (0xFAEDF0, 8, "((0x60F308) & 0x70) >> 2", "the routine at 0xFAED76"),
    (0xFAEE5C, 16, "(0x60F327) & 0x0F", "the routine at 0xFAEE10"),
    (0xFAF16C, 4, "(0x60F308) & 3", "the routine at 0xFAF148"),
    (0xFAF410, 4, "(0x60F308) & 3", "the routine at 0xFAF332"),
    (0xFAF6B8, 4, "(0x7F32) & 3", "the routine at 0xFAF5C1"),
]


def table_readers(t):
    """Every address in prom_a whose four bytes are `t` little-endian."""
    d, pat, out, off = rom("a"), t.to_bytes(4, "little"), [], 0
    while True:
        k = d.find(pat, off)
        if k < 0:
            return out
        out.append(A_BASE + k)
        off = k + 1


def reader_of(t):
    """(instruction address, text) of the ONE `ld XIX/XIY/XIZ,<table>` that
    loads this table, or None.

    ⚠ DERIVED, NOT TYPED.  A byte scan finds the OPERAND; the instruction starts
    one byte earlier, and citing the operand instead of the instruction is a bug
    this project has shipped twice (~31 citations in wave 7 round 1 alone).  So
    the address is computed as hit-1 and then CHECKED: the opcode byte must be
    0x44/0x45/0x46 and the decode must be a 5-byte `ld <reg>,0x00<table>`."""
    hits = table_readers(t)
    if len(hits) != 1:
        return None
    a = hits[0] - 1
    if by("a", a, 1)[0] not in (0x44, 0x45, 0x46):
        return None
    dec = dis_at("a", a)
    if dec is None or dec[0] != 5 or ("%06x" % t) not in dec[1]:
        return None
    return a, dec[1]


def show_tables():
    print("Every jump table inside 0x%06X-0x%06X, its reader and its selector."
          % (LO, HI))
    print("%-10s %5s %-11s %-28s %s"
          % ("table", "n", "reader", "index", "owner"))
    for t, n, sel, own in DISPATCH:
        rd = reader_of(t)
        print("0x%06X %5d %-11s %-28s %s"
              % (t, n, "0x%06X" % rd[0] if rd else "-- none --", sel, own))
    print("\nThe reader column is the address of the `ld XIX/XIY,<table>` "
          "INSTRUCTION, not of\nits operand: the table address is found by a "
          "byte scan of prom_a and the opcode\nbyte one earlier is checked to be "
          "0x44/0x45/0x46 and to decode as a 5-byte load\nof exactly that "
          "constant.  0xFAE802 and 0xFAE83E have NO such word anywhere in\n"
          "prom_a -- they are tables nothing loads.")
    return 0


def arms(t, n):
    """[(target, [indices])] for a pointer table, merged over repeated targets."""
    seen = {}
    for i in range(n):
        v = w32("a", t + 4 * i)
        seen.setdefault(v, []).append(i)
    return sorted(seen.items())


# ------------------------------------- a naming lever that is EMPTY, and the proof
def twins():
    """Is there a byte-identical-routine naming lever in or into prom_a?

    Round 4's brief points at the prom_a/prom_c shared kernel as the strongest
    naming lever in the tree.  It is already fully exploited: all 36 pairs
    notes/prom_c_kernel_map.py --pairs reports are named on BOTH sides.  This
    asks the wider question -- is any prom_a `sub_XXXXXX` routine byte-identical
    to a NAMED routine somewhere, so that the name could be borrowed with a diff
    of zero?  It reports the answer rather than the hope."""
    res = {}
    for src_img in ("a", "c"):
        lab = {}
        for n, a in labels(src_img):
            lab.setdefault(a, []).append(n)
        xs = sorted(lab)
        ext = dict((a, (xs[i + 1] if i + 1 < len(xs) else a + 0x40))
                   for i, a in enumerate(xs))
        idx = collections.defaultdict(list)
        d = rom(src_img)
        b = base(src_img)
        for a, ns in lab.items():
            if all(UNNAMED.match(n) for n in ns):
                continue
            n = ext[a] - a
            if not (16 <= n <= 2048) or a - b < 0 or a - b + n > len(d):
                continue
            idx[bytes(d[a - b:a - b + n])].append((a, [x for x in ns
                                                       if not UNNAMED.match(x)]))
        hits = []
        la = {}
        for n, a in labels("a"):
            la.setdefault(a, []).append(n)
        ax = sorted(la)
        aext = dict((a, (ax[i + 1] if i + 1 < len(ax) else a + 0x40))
                    for i, a in enumerate(ax))
        da = rom("a")
        for a, ns in la.items():
            subs = [n for n in ns if UNNAMED.match(n)]
            if not subs or any(not UNNAMED.match(n) for n in ns):
                continue
            n = aext[a] - a
            if not (16 <= n <= 2048) or a - A_BASE + n > len(da):
                continue
            k = bytes(da[a - A_BASE:a - A_BASE + n])
            if k in idx:
                hits.append((a, n, subs[0], idx[k]))
        res[src_img] = hits
    return res


def show_twins():
    r = twins()
    print("prom_a sub_XXXXXX routines byte-identical to a NAMED routine, at the")
    print("same label-to-label extent, so a name could be borrowed with 0 differing:")
    for img in ("a", "c"):
        print("  against prom_%s: %d" % (img, len(r[img])))
        for a, n, sub, cs in sorted(r[img], key=lambda h: -h[1])[:10]:
            print("    prom_a 0x%06X %4d B  %-14s <- %s"
                  % (a, n, sub, ", ".join("0x%06X %s" % (x, "/".join(y))
                                          for x, y in cs)))
    print("\n★ THE LEVER IS EMPTY, and that is the finding.  prom_a's own labels")
    print("  do not split routines at the same boundaries prom_c's do, so an")
    print("  extent-for-extent byte match is vanishingly rare; the ONE hit against")
    print("  prom_c is already named on both sides.  A pass that plans to name")
    print("  prom_a from byte-identical siblings should read this first.")
    return 0


# ------------------------------------------------------------------ the plan
# Every entry is (addr, old-or-None, new, [header lines]).
#   old is None    -> INSERT a new label at that address
#   old is a name  -> RENAME that label and every textual reference to it
#
# Nothing below is justified by a call count.  Each header names the mechanism
# and the addresses that pin it, and --selftest re-derives every number in it.

RENAMES = [
    (PARAMPTRS, "Lookup32_By_Arg8", "ParamNumber_RecordPtrs", [
        "ParamNumber_RecordPtrs -- 256 LE32 words: the WORK-RAM address of the",
        "                          record that parameter number k's fields live",
        "                          in, or 0xFFFFFFFF when k has no record",
        "",
        "★ THIS REPLACES THE NAME `Lookup32_By_Arg8` AND CORRECTS ITS HEADER.",
        "         That header said `Unknown: what the 16-bit values ARE.  They",
        "         are NOT addresses in any image of this machine ... and",
        "         0xFFFFFFFF reads as \"absent\" but nothing in the module tests",
        "         for it.`  Both halves are wrong:",
        "           * the values are 16-bit WORK-RAM addresses, the same form",
        "             prom_b's RamPtrTable_F7554D header already describes;",
        "           * `cp XIX,0xffffffff` at 0xFAA5BF, 0xFAA63B and 0xFAA682",
        "             tests a fetched entry for exactly that value and skips the",
        "             whole operation when it matches.",
        "         The old header's shape facts -- 256 entries, 1024 bytes, 179",
        "         empty, values in 0x7622..0x7F5A -- are re-derived here and all",
        "         four still hold.",
        "Read by: (0x60F018) holds this table's base.  Three instructions load",
        "         it -- `lda XBC,0xfacdea` at 0xFAA873, 0xFAA94E and 0xFAB7F4 --",
        "         and every reader of (0x60F018) therefore reads THIS table,",
        "         including prom_b's IndexedTable_GetPtr (0xF55321) and",
        "         IndexedTable_GetByte (0xF5533C), whose own headers say",
        "         `Unknown: what the table holds and who writes 0x60F018`.",
        "         The reader the old header named, 0xFAC8AA, is one of several.",
        "★ Evidence, four independent pins, all re-derived by",
        "         notes/prom_a_understanding_round4.py --table:",
        "         1. entry[k] + 0x0D == MidiOut_PartRecordPtrs_00[k] for all 32",
        "            of that already-named table's entries, last included.  So",
        "            entries 0x00-0x1F ARE the 32 part records, given at their",
        "            base rather than at the +0x0D channel byte.",
        "         2. entries 0x00-0x1F step by 0x40 with one step of 0x80 after",
        "            index 7 -- the same irregularity MidiOut_PartRecordPtrs_00's",
        "            header records for itself.",
        "         3. entry[0x20+i] == entry[i] + 0x20 for all 32, which is why",
        "            Evt2030_ClassHandlers routes 0x00-0x1F and 0x20-0x3F to two",
        "            different handlers: they are two halves of one 0x40 record.",
        "         4. entry[0x80] == 0x7F32, and (0x7F32) is the byte whose bit 2",
        "            MIDI_RT_ExternalOff already names; prom_b 0xF6F858 writes",
        "            its low two bits and then posts {0x80, 0, value, 0x03}.",
        "Unknown:  the field layout inside a record.  Only three offsets are",
        "         established anywhere in the tree: +0x0D (the MIDI channel,",
        "         from MidiIn_BuildChannelRouteTable) and +0x1B..+0x1D (written",
        "         by 0xFAA6B1).  The 0x40-byte size is a step, not a proof."]),
    (0xFAA4A0, "sub_FAA4A0", "Queue2C00_PublishStagedIfPending", [
        "Queue2C00_PublishStagedIfPending -- append the staged 4-byte record at",
        "                          (0x60F080..0x60F083) to the 0x2C00 queue, but",
        "                          only when (0x60F083) is non-zero",
        "",
        "Called from: prom_b directory slot T_F407B4.",
        "Body:    return at once when (0x60F083) == 0.  Otherwise: if the queue",
        "         cursor (0x60F000) has reached 0x01FC, drain the queue through",
        "         T_F40018 and restart the cursor at 0; then store (0x60F080) and",
        "         (0x60F082) as two 16-bit words at 0x2C00 + cursor, write 0xFF",
        "         one past, advance the cursor by 4 and clear (0x60F083).",
        "Evidence: `cp (0x60f083),0x00` at 0xFAA4A0, `cp HL,0x01fc` at 0xFAA4B0,",
        "         `call 0xf40018` at 0xFAA4BD, `ld XIX,0x00002c00` at 0xFAA4CA,",
        "         `ld (0x60f000),HL` at 0xFAA4ED, `ld (0x60f083),0x00` at",
        "         0xFAA4F2.  The record shape -- four bytes plus an 0xFF one past",
        "         and a cursor step of 4 -- is the shape Queue2C00_AppendRegs",
        "         (0xF86A81) already documents for the same buffer and the same",
        "         cursor cell, and T_F40018 is sub_F823AC, which empties 0x2C00",
        "         and rezeroes (0x60F000).",
        "Note:    (0x60F083) is the record's mask byte, so \"a mask of 0\" is what",
        "         \"nothing staged\" means here; the writers that stage a record",
        "         (ParamRecord_WriteFieldAndStage and the ParamApply_ entries in",
        "         the 0xFAD800 module) all set it last."]),
    (0xFAA4FC, "sub_FAA4FC", "Queue2C00_PublishStaged", [
        "Queue2C00_PublishStaged -- the same, with no (0x60F083) test",
        "",
        "Called from: no directory slot and no proven call site found; it is",
        "         reached by falling out of Queue2C00_PublishStagedIfPending's",
        "         `ret` only if something jumps here, which nothing does.  Stated",
        "         as a searched negative, not as a fact about the hardware.",
        "Body:    identical to Queue2C00_PublishStagedIfPending from its second",
        "         instruction on, including the same `jr c` into that routine's",
        "         own tail at 0xFAA4CA, and then a SECOND copy of the same tail",
        "         inline at 0xFAA51E.",
        "Evidence: `jr C,0xfaa4ca` at 0xFAA508 targets the other routine's body;",
        "         `ld XIX,0x00002c00` appears twice, at 0xFAA4CA and 0xFAA51E."]),
    (0xFAA550, "Queue2C00_PublishStagedDrainQuiet",
     "Queue2C00_PublishStagedDrainPassB", [
        "Queue2C00_PublishStagedDrainPassB -- the same again, draining through",
        "                          Queue2C00_DrainPassB instead of",
        "                          Queue2C00_DrainPassAB",
        "",
        "Called from: prom_b directory slot T_F407B8.",
        "Evidence: `call 0xf40038` at 0xFAA565 where the other two call",
        "         0xf40018.  T_F40018 is Queue2C00_DrainPassAB and T_F40038 is",
        "         Queue2C00_DrainPassB; the only difference between those two is",
        "         the `call 0xf40f5c` -- UiEventList_RunPassA -- that the second",
        "         omits.  So what this entry point skips is PASS A over the",
        "         queue, and nothing else.",
        "⚠ CORRECTION: an earlier header of this same pass called this routine",
        "         `Queue2C00_PublishStagedDrainQuiet` and said `the difference is",
        "         one notification`.  It is not a notification; T_F40F5C is",
        "         UiEventList_RunPassA, which prom_a already names, and the",
        "         earlier header simply had not looked it up."]),
    (0xFAA623, "sub_FAA623", "ParamRecord_WriteFieldAndStage", [
        "ParamRecord_WriteFieldAndStage -- write masked bits into one byte of a",
        "                          parameter's record and stage the change",
        "",
        "Called from: prom_b directory slot T_F407D4.",
        "Inputs:  C = the parameter number, B = the byte offset inside that",
        "         parameter's record, E = the new value, D = the bit mask.",
        "Body:    return when D == 0; XIX = ParamNumber_RecordPtrs[C] through",
        "         (0x60F018); return when that entry is 0xFFFFFFFF; then",
        "         (XIX+B) = ((XIX+B) & ~D) | (E & D), and finally",
        "         (0x60F080) = BC and (0x60F082) = DE, i.e. the four staged bytes",
        "         {C, B, E, D} that Queue2C00_PublishStagedIfPending publishes.",
        "Evidence: `cp D,0` at 0xFAA626, `ld XIX,(0x60f018)` at 0xFAA631,",
        "         `cp XIX,0xffffffff` at 0xFAA63B, `xor W,0xff / and A,W /",
        "         and E,D / or E,A` at 0xFAA64E-0xFAA655, `ld (XIX+HL),E` at",
        "         0xFAA657, `ld (0x60f080),BC` at 0xFAA65C.",
        "★ THE STAGED RECORD IS THE SAME FOUR BYTES the 0x2030 list, the 0x2C00",
        "         queue and the 0x2E00 queue all carry: List2030_AppendRegs",
        "         (0xF86AC7) stores {E,D,A,W} and the Evt2030 runner reads byte",
        "         +0 as the parameter number and hands +1..+3 to the handler in",
        "         B, E and D."]),
    (0xFAA66A, "sub_FAA66A", "ParamRecord_WriteFieldAndStage_Copy", [
        "ParamRecord_WriteFieldAndStage_Copy -- a second copy of the routine",
        "                          above, published as its own directory slot",
        "",
        "Called from: prom_b directory slot T_F407D8.",
        "★ BORROWED NAME, WITH THE DIFF: 0xFAA623 and 0xFAA66A are 71 bytes with",
        "         exactly TWO differing -- offset +2 (0x3B `push XHL` against",
        "         0x2B `push HL`) and offset +67 (0x5B `pop XHL` against 0x4B",
        "         `pop HL`).  Every other byte, including both `jr` displacements,",
        "         is identical, so the two routines differ only in whether the",
        "         saved HL is 32 or 16 bits wide.  Check C1 recomputes the length",
        "         and the differing count and prints both offsets.",
        "Unknown:  why the firmware publishes both.  Nothing here explains it."]),
    (0xFAA5FE, "sub_FAA5FE", "ParamChange_NotifyClearSource", [
        "ParamChange_NotifyClearSource -- clear (0x60F007), then notify",
        "",
        "Called from: prom_b directory slot T_F407CC, and it is the target of",
        "         all eleven Evt2030_ClassXX_Fwd forwarders.",
        "Body:    `ld (0x60f007),0x00` and then falls straight into",
        "         ParamChange_Notify -- the two are one routine with two entry",
        "         points, which is why the directory publishes both.",
        "Evidence: `ld (0x60f007),0x00` at 0xFAA5FE is five bytes and 0xFAA604 is",
        "         the next address; the forwarders are `call 0xf407cc / ret`.",
        "Note:    (0x60F007) is the byte MidiOut_ParamChanged clears bit 7 of on",
        "         its way out (`res 7,(0x60f007)` at 0xFA7123), and the byte",
        "         ParamReset_SixParamsForIndex sets before each of its six posts.",
        "         So it is a per-call source/flags byte and this entry is the",
        "         \"no source\" one.  What its bits SELECT is not established."]),
    (0xFAA604, "sub_FAA604", "ParamChange_Notify", [
        "ParamChange_Notify -- hand the register-face parameter change to",
        "                          MidiOut_ParamChanged, unless it is gated off",
        "",
        "Called from: prom_b directory slot T_F407D0, and by falling in from",
        "         ParamChange_NotifyClearSource.",
        "Body:    return when bit 0 of (0x0922) is set AND bit 1 is clear;",
        "         otherwise save all seven register pairs, `call 0xf40748`, and",
        "         restore them.",
        "Evidence: `bit 0,(0x0922)` at 0xFAA604 and `bit 1,(0x0922)` at 0xFAA60A;",
        "         T_F40748 is MidiOut_ParamChanged (prom_a 0xFA70F5), already",
        "         named, and that routine opens with the SAME two bit tests on",
        "         the SAME cell -- so the gate is duplicated, not delegated."]),
]
RENAMES += [
    (0xFBA10D, "sub_FBA10D", "Multiply32", [
        "Multiply32 -- 32x32 -> 32 multiply, the two low-by-high partial products",
        "                          shifted 16 and added, the high-by-high dropped",
        "",
        "★ BORROWED FROM prom_c, WITH THE DIFF: prom_c 0xFCB11B carries this name",
        "         already and the two routines are the same 38 bytes with **0",
        "         differing** -- ROM_A[0xFBA10D..0xFBA132] ==",
        "         ROM_C[0xFCB11B..0xFCB140].  Check T1 of --twins recomputes both",
        "         numbers; a borrowed name with no diff behind it is exactly what",
        "         this tree's rules forbid.",
        "★ AND IT IS THE ONLY ONE.  --twins asks the general question -- is any",
        "         prom_a sub_XXXXXX byte-identical, at the same label-to-label",
        "         extent, to a NAMED routine in prom_a or prom_c? -- and the",
        "         answer is one routine, this one.  The byte-identical-twin lever",
        "         that the round-4 brief points at is otherwise empty, because the",
        "         two images do not split routines at the same boundaries.",
        "Inputs:  (XIZ+0x08) and (XIZ+0x0C) longs.  Outputs: XIY.  `retd 0x0008`.",
        "Evidence: `mul XIY,IX` at 0xFBA11A on the two low halves, then",
        "         `mul XIX,(XIZ+0x0a)` at 0xFBA11C and `mul XIX,(XIZ+0x0e)` at",
        "         0xFBA126, each shifted left 16 by `sll A,XIX` with A = 0x10",
        "         loaded once at 0xFBA112, and added.  The high-by-high product is",
        "         never computed, which is right for a result truncated to 32",
        "         bits -- the same sentence prom_c's header already carries.",
        "Called from: 3 textual references in prom_a."]),
    (0xF823AC, "sub_F823AC", "Queue2C00_DrainPassAB", [
        "Queue2C00_DrainPassAB -- run pass A and pass B over the 0x2C00 event",
        "                          queue, then empty it",
        "",
        "Called from: prom_b directory slot T_F40018.",
        "Body:    return at once when (0x2C00) is already 0xFF (empty).",
        "         Otherwise `call 0xf40f5c` and `call 0xf40f60`, then write 0xFF",
        "         to 0x2C00 and zero the cursor (0x60F000).",
        "Evidence: `cp (0x2c00),0xff` at 0xF823AC; `call 0xf40f5c` at 0xF823B3 and",
        "         `call 0xf40f60` at 0xF823B7, and prom_b's directory says",
        "         T_F40F5C is UiEventList_RunPassA (0xF8697E) and T_F40F60 is",
        "         UiEventList_RunPassB (0xF8699D) -- both already named, both",
        "         setting (0x20AD) to 0x2C00, i.e. running over THIS queue.",
        "         `ld (0x2c00),0xff` at 0xF823BB and `ld (0x60f000),0x0000` at",
        "         0xF823C0 are the emptying."]),
    (0xF823C8, "sub_F823C8", "Queue2C00_DrainPassB", [
        "Queue2C00_DrainPassB -- the same, running pass B ONLY",
        "",
        "Called from: prom_b directory slot T_F40038.",
        "★ BORROWED SHAPE, WITH THE DIFF: 0xF823AC and 0xF823C8 do the same four",
        "         things and 0xF823C8 omits ONE call.  They are 28 and 24 bytes;",
        "         the difference is the four bytes `1d 5c 0f f4` (`call 0xf40f5c`,",
        "         pass A) at 0xF823B3, and the remaining 24 bytes are identical",
        "         except for the two `jr` displacements that the missing four",
        "         bytes shift.  Check Y1 recomputes that.",
        "Evidence: `cp (0x2c00),0xff` at 0xF823C8, `call 0xf40f60` at 0xF823CF,",
        "         `ld (0x2c00),0xff` at 0xF823D3."]),
    (0xFADDC9, "sub_FADDC9", "Evt2030_Class98_Op00", [
        "Evt2030_Class98_Op00 -- operation 0 of parameter number 0x98: do nothing",
        "",
        "Called from: `jp T,XIX` at 0xFADDBF; index 0 of the 2-entry table at",
        "         0x00FADDC1, which Evt2030_Class98 indexes with B after",
        "         `cp L,1` at 0xFADDAE.",
        "Body:    one `ret`.",
        "Evidence: the LE32 word at 0xFADDC1 reads 0x00FADDC9 and the word at",
        "         0xFADDC5 reads 0x00FADDCA, so the two arms are one byte apart",
        "         and the first is the `ret`."]),
    (0xFADDCA, "sub_FADDCA", "Evt2030_Class98_Op01", [
        "Evt2030_Class98_Op01 -- operation 1 of parameter number 0x98",
        "",
        "Called from: `jp T,XIX` at 0xFADDBF; index 1 of the table at 0x00FADDC1.",
        "Body:    return unless bit 3 of (0x7F32) is set; bump (0x1965) and",
        "         return if its bit 0 is now set; otherwise dispatch on",
        "         (0x7F32) & 3 through the 4-entry table at 0x00FADDF1.",
        "Evidence: `bit 3,(0x7f32)` at 0xFADDCA, `inc 1,(0x1965)` at 0xFADDD1,",
        "         `ld L,(0x7f32)` at 0xFADDDB and `and L,0x03` at 0xFADDDF,",
        "         `ld XIX,0x00faddf1` at 0xFADDE5.",
        "★ (0x7F32) is parameter number 0x80's own record -- see",
        "         ParamNumber_RecordPtrs -- so this handler for parameter 0x98",
        "         is gated by, and dispatched on, ANOTHER parameter's value.",
        "Unknown:  what bit 3 of (0x7F32) is, and what (0x1965) counts."]),
]

# Labels the module never had.  These are INSERTS: `old` is None.
INSERTS = [
    (0xFAA5A7, "ParamRecord_WriteFieldIfChanged", [
        "ParamRecord_WriteFieldIfChanged -- the same masked write as",
        "                          ParamRecord_WriteFieldAndStage, staged ONLY",
        "                          when the masked bits actually change",
        "",
        "Called from: no directory slot; it sits between sub_FAA4FC's tail and",
        "         ParamChange_NotifyClearSource and had no label at all.",
        "Body:    as ParamRecord_WriteFieldAndStage, except that the old byte is",
        "         saved to (0x60F08B), the new one is XORed against it and ANDed",
        "         with D, and the store and the staging are skipped when that",
        "         comes out zero.",
        "Evidence: `ld (0x60f08b),A` at 0xFAA5D0, `xor W,(0x60f08b)` at 0xFAA5E2,",
        "         `and W,D` at 0xFAA5E7, `jr Z,0xfaa5fa` at 0xFAA5E9 -- the jump",
        "         that skips both `ld (XIX+HL),A` and the two staging stores."]),
    (0xFAD80A, "ParamApply_MaskedWriteAndPublish", [
        "ParamApply_MaskedWriteAndPublish -- apply {C,B,E,D} to the parameter",
        "                          record and publish the change",
        "",
        "Called from: prom_b directory slot T_F40858.  ⚠ This address had NO",
        "         LABEL before this pass; the emitter that converted the span",
        "         labels only what its own descent reaches, and a `jp` in prom_b",
        "         is invisible to it.",
        "Inputs:  C, B, E, D, passed straight through in registers.",
        "Body:    `ld (0x60f01e),0xff`, then T_F407D8",
        "         (ParamRecord_WriteFieldAndStage_Copy) and T_F407B4",
        "         (Queue2C00_PublishStagedIfPending).",
        "Evidence: the three instructions at 0xFAD80A, 0xFAD810 and 0xFAD814.",
        "Unknown:  what (0x60F01E) means.  Every entry point of this module",
        "         except the four ParamShadow_ ones writes 0xFF to it first, and",
        "         0xFAA86D seeds it with 0x7F at start-up; nothing here says what",
        "         reads it."]),
    (0xFAD81D, "ParamShadow_SetField3", [
        "ParamShadow_SetField3 -- remember a value for field 3 of parameter C,",
        "                          to be published later by ParamShadow_FlushAll",
        "",
        "Called from: prom_b directory slot T_F40874.",
        "Body:    when BC == 0x00B0 (C = 0xB0, B = 0), write E to (0x24F1) and",
        "         go out immediately through T_F407EC; otherwise, when C <= 0x1F,",
        "         store E with bit 7 forced into the 32-byte array at 0x60F610,",
        "         indexed by C, and return.",
        "Evidence: `cp BC,0x00b0` at 0xFAD81D, `cp C,0x1f` at 0xFAD823,",
        "         `set 0x07,E` at 0xFAD828, `ld XIX,0x0060f610` at 0xFAD82B.",
        "★ WHY \"field 3\": ParamShadow_FlushAll's arm for this array emits the",
        "         record with `ld C,L` at 0xFADB14 and `ld B,0x03` at 0xFADB16,",
        "         so the deferred write is byte 3 of the record",
        "         of the parameter whose number is the array index.  Bit 7 is the",
        "         pending flag: the flush tests it and clears it.",
        "Unknown:  what field 3 of a part record holds."]),
    (0xFAD84A, "ParamShadow_SetExpression", [
        "ParamShadow_SetExpression -- remember an EXPRESSION value (parameter",
        "                          number 0xB3) for index B, to be published later",
        "",
        "Called from: prom_b directory slot T_F4086C.",
        "Body:    when C == 0xB0, store E with bit 7 forced into the single byte",
        "         at 0x60F650; otherwise, when B <= 0x1F, into the 32-byte array",
        "         at 0x60F590 indexed by B.",
        "Evidence: `cp C,0xb0` at 0xFAD84A, `ld (0x60f650),E` at 0xFAD852,",
        "         `cp B,0x1f` at 0xFAD859, `ld XIX,0x0060f590` at 0xFAD861.",
        "★ WHY 0xB3 and 0xB0: ParamShadow_FlushAll walks 0x60F590 with W = 0xB3",
        "         (`ld W,0xb3` at 0xFADA2B) and emits {W, index, value, 0x7F};",
        "         it walks 0x60F650 separately and emits {0xB0, 0x01, value,",
        "         0x7F} (`ld (0x60f080),0xb0` at 0xFADA9E and `ld (0x60f081),0x01` at",
        "         0xFADA9E and 0xFADAA4).  Both are parameter numbers with an",
        "         Evt2030 handler and NO record -- see ParamNumber_RecordPtrs."]),
    (0xFAD870, "ParamShadow_SetPitchBend", [
        "ParamShadow_SetPitchBend -- remember a PITCH BEND value and mask",
        "                          (parameter number 0xB1) for index B",
        "",
        "Called from: prom_b directory slot T_F40864.",
        "Body:    when B <= 0x1F, store the 16-bit DE -- with bit 7 of E forced --",
        "         at 0x60F5D0 + 2*B.  This is the only one of the four shadows",
        "         that is 16 bits wide, and the high byte is the mask.",
        "Evidence: `cp B,0x1f` at 0xFAD870, `set 0x07,E` at 0xFAD875,",
        "         `ld XIX,0x0060f5d0` at 0xFAD878, `sll 0x01,B` at 0xFAD87D,",
        "         `ld (XIX+B),DE` at 0xFAD880.  The flush arm reads the pair back",
        "         with `ld WA,(XIY+HL)` at 0xFADAC3, clears bit 7 of the",
        "         low byte and emits {0xB1, index, A, W} -- so W, the high byte,",
        "         lands in the record's mask slot."]),
    (0xFAD88A, "ParamShadow_SetModulation1", [
        "ParamShadow_SetModulation1 -- remember a MODULATION 1 value (parameter",
        "                          number 0xB2) for index B",
        "",
        "Called from: prom_b directory slot T_F40868.",
        "Body:    when B <= 0x1F, store E with bit 7 forced into the 32-byte",
        "         array at 0x60F5B0 indexed by B.",
        "Evidence: `cp B,0x1f` at 0xFAD88A, `ld XIX,0x0060f5b0` at 0xFAD892.",
        "         ParamShadow_FlushAll walks the same array with W = 0xB2",
        "         (`ld W,0xb2` at 0xFADA38) through the same shared loop it uses",
        "         for 0x60F590, which is what pins the parameter number."]),
    (0xFAD8A1, "ParamApply_WriteStagedAndPublish", [
        "ParamApply_WriteStagedAndPublish -- take {C,B,E,D} from the 0x1950",
        "                          staging cells, apply it and publish it",
        "",
        "Called from: prom_b directory slot T_F40878.",
        "Body:    `ld (0x60f01e),0xff`, BC = (0x1950), DE = (0x1952), then",
        "         T_F407D4 (ParamRecord_WriteFieldAndStage) and T_F407B4.",
        "Evidence: the six instructions at 0xFAD8A1-0xFAD8B3.",
        "★ (0x1950..0x1953) is the four-byte staging area the MIDI-in handlers",
        "         fill: MidiIn_CC5B_Effect1Depth and its neighbours end in",
        "         `ld (0x1950),BC / ld (0x1952),DE` and then call one of this",
        "         module's slots -- 0xFA6D1A and 0xFA6D1E are one such pair."]),
    (0xFAD8BC, "ParamApply_PublishStagedPair", [
        "ParamApply_PublishStagedPair -- copy the 0x1950 staging cells into the",
        "                          publish record and publish, with NO record",
        "                          write",
        "",
        "Called from: prom_b directory slot T_F40884.",
        "Body:    `ld (0x60f01e),0xff`; (0x60F080) = (0x1950); (0x60F082) =",
        "         (0x1952); T_F407B4.  Nothing reads ParamNumber_RecordPtrs on",
        "         this path, so a parameter number with no record can use it.",
        "Evidence: the six instructions at 0xFAD8BC-0xFAD8D8; the absence of any",
        "         `call 0xf407d4`/`0xf407d8` between them."]),
    (0xFAD8DD, "ParamApply_PublishStagedPair_Copy", [
        "ParamApply_PublishStagedPair_Copy -- a second copy, published as its own",
        "                          directory slot",
        "",
        "Called from: prom_b directory slot T_F4088C.",
        "★ BORROWED NAME, WITH THE DIFF: 0xFAD8BC and 0xFAD8DD are 29 bytes with",
        "         ZERO differing -- byte for byte the same routine, `ret`",
        "         included.  Check C2 recomputes both numbers.  (At 33 bytes the",
        "         count is 1, and that byte is the `calr` displacement of the",
        "         four-byte stub that FOLLOWS each routine; 29 is where both",
        "         routines end.)"]),
    (0xFAD8FE, "ParamApply_PublishStagedAndPostSeven", [
        "ParamApply_PublishStagedAndPostSeven -- publish the staged pair, then",
        "                          post seven fixed records for the same index",
        "",
        "Called from: prom_b directory slot T_F4087C.",
        "Body:    the ParamApply_PublishStagedPair sequence, then seven",
        "         Queue2E00_AppendRegs (T_F40F3C) calls with E = 0xB1, 0xB4,",
        "         0xB2, 0xB3, 0xB5, 0xB6, 0xB7 in that order, D = (0x1951) each",
        "         time and WA = 0x4000, 0x7F00, 0x7F00, 0x7F7F, 0x7F00, 0x7F00,",
        "         0x7F00; then (0x1980 + 2*(0x1951)) = 0x7F7F.",
        "Evidence: the seven `ld E,0xbN` immediates at 0xFAD91A, 0xFAD927,",
        "         0xFAD934, 0xFAD941, 0xFAD94E, 0xFAD95B and 0xFAD968, each",
        "         followed by `call 0xf40f3c`; `ld XIX,0x00001980` at 0xFAD97E.",
        "         Check C3 reads the seven parameter numbers and the seven WA",
        "         immediates out of the ROM rather than trusting this list.",
        "★ All seven are parameter numbers that have an Evt2030 handler and NO",
        "         record, so the seven posts go out as queue traffic only.",
        "Unknown:  what 0x1980 is.  A 16-bit array indexed by the same index."]),
    (0xFAD98F, "ParamApply_PublishStagedPairBCDE", [
        "ParamApply_PublishStagedPairBCDE -- the same publish, staged through",
        "                          BC/DE instead of WA",
        "",
        "Called from: prom_b directory slot T_F40880.",
        "Body:    BC = (0x1950); DE = (0x1952); `ld (0x60f01e),0xff`;",
        "         (0x60F080) = BC; (0x60F082) = DE; T_F407B4.  Same effect as",
        "         ParamApply_PublishStagedPair, different register file and a",
        "         different order, so the two are NOT a byte match -- the name",
        "         says which spelling this is and claims nothing more.",
        "Evidence: `ld BC,(0x1950)` at 0xFAD98F against `ld WA,(0x1950)` at",
        "         0xFAD8C2; 28 bytes here against 29 there."]),
    (0xFAD9B0, "ParamApply_WriteStagedAndPublish_Copy", [
        "ParamApply_WriteStagedAndPublish_Copy -- a second copy of 0xFAD8A1",
        "",
        "Called from: prom_b directory slot T_F40888.",
        "★ BORROWED NAME, WITH THE DIFF: 0xFAD8A1 and 0xFAD9B0 are 23 bytes with",
        "         ZERO differing.  Check C2 recomputes both numbers."]),
    (0xFAD9CB, "ParamApply_OneHotOfSix", [
        "ParamApply_OneHotOfSix -- apply a value whose low six bits are an",
        "                          ORDINAL, as a one-hot bit in the next field",
        "",
        "Called from: prom_b directory slot T_F4089C.",
        "Body:    A = (0x1952) & 0x3F; return when A >= 6.  Then write bit 6 of",
        "         the value, INVERTED, into field B under the staged mask, and",
        "         publish.  Then reload BC = (0x1950), advance B by 1 -- or by 2",
        "         when bit 7 of the value is clear -- look the ordinal up in",
        "         OrdinalToBitMask6, set D = 0x3F, and write and publish that.",
        "Evidence: `and A,0x3f` at 0xFAD9CF and `cp A,6` at 0xFAD9D2 bound the",
        "         ordinal; `srl 0x06,E / xor E,0xff / and E,0x01` at",
        "         0xFAD9E4-0xFAD9EA is the inverted bit 6; `inc 1,B` at 0xFAD9F9",
        "         and 0xFADA06 with `srl 0x07,A / jr C` between them is the",
        "         +1-or-+2; `ld XIX,0x00fada20` at 0xFADA0B is the table.",
        "         Two independent pins on the 6: the `cp A,6` bound and the",
        "         table's own six bytes.",
        "Unknown:  which parameter this is for -- C comes from (0x1950) and is",
        "         not constrained here."]),
    (0xFADA20, "OrdinalToBitMask6", [
        "OrdinalToBitMask6 -- six bytes, 0x01 0x02 0x04 0x08 0x10 0x20: ordinal",
        "                          k (0..5) as a one-hot bit",
        "",
        "Read by: `ld E,(XIX+E)` at 0xFADA10, with XIX loaded from",
        "         `ld XIX,0x00fada20` at 0xFADA0B, inside ParamApply_OneHotOfSix.",
        "★ It is the exact inverse of BitMaskToOrdinal6 at 0xFADD30: for every",
        "         k in 0..5, BitMaskToOrdinal6[OrdinalToBitMask6[k]] == k.  Check",
        "         C4 asserts that round trip on all six, last included -- which is",
        "         what makes both names something better than a reading of six",
        "         bytes.",
        "Evidence: the six bytes, re-read from the ROM by check C4.",
        "⚠ THE EMITTER SPELLED THEM AS INSTRUCTIONS.  The four lines below this",
        "         label -- `normal`, `push SR`, `max`, `ld (0x10),0x20` (the .s",
        "         spells the last one `ldio 0x10, 0x20`) -- are",
        "         0x01 0x02 0x04 0x08 0x10 0x20, this table, decoded as code by",
        "         notes/gen_prom_a_fad800_module.py.  The byte gate cannot tell",
        "         the difference and never will; only this header can."]),
    (0xFADA26, "ParamShadow_FlushAll", [
        "ParamShadow_FlushAll -- publish every shadow entry whose bit 7 is set,",
        "                          then clear the bit",
        "",
        "Called from: prom_b directory slot T_F40898.",
        "Body:    five sweeps, starting immediately with `ld XIY,0x0060f590`:",
        "           0x60F590[0..0x1F]  as parameter 0xB3, mask 0x7F",
        "           0x60F650           as parameter 0xB0 index 1, mask 0x7F,",
        "                              also copied to (0x24F0) and sent through",
        "                              T_F407EC",
        "           0x60F5B0[0..0x1F]  as parameter 0xB2, mask 0x7F",
        "           0x60F5D0[0..0x1F]  as parameter 0xB1, 16-bit: the stored high",
        "                              byte becomes the mask (T_F407B8)",
        "           0x60F610[0..0x1F]  as parameter <index>, field 3, mask 0x7F",
        "                              (T_F407D4 then T_F407B4)",
        "         Each sweep tests bit 7, clears it, writes the record and calls",
        "         a publish entry.",
        "Evidence: `ld XIY,0x0060f590` at 0xFADA26, `ld W,0xb3` at 0xFADA2B,",
        "         `ld XIY,0x0060f5b0` at 0xFADA33, `ld W,0xb2` at 0xFADA38,",
        "         `ld XIY,0x0060f650` at 0xFADA7F, `ld XIY,0x0060f5d0` at",
        "         0xFADABA, `ld XIY,0x0060f610` at 0xFADAF5; `bit 0x07,A` and",
        "         `res 0x07,A` in each loop; `cp L,0x1f`/`cp B,0x1f` bound each",
        "         sweep at 32 entries.",
        "★ 0xB3 is EXPRESSION, 0xB2 is MODULATION 1 and 0xB1 is PITCH BEND --",
        "         see ParamShadow_SetExpression, ParamShadow_SetModulation1 and",
        "         ParamShadow_SetPitchBend for the witnesses.  0xB0 has no",
        "         outbound handler (MidiOut_ParamNumberTable[0xB0] is a bare",
        "         `ret` at 0xFA767D), so nothing here names it.",
        "★ These five arrays are the deferred half of this module: the four",
        "         ParamShadow_Set* entries write them and only this routine reads",
        "         them.  Nothing else in prom_a names 0x60F590, 0x60F5B0,",
        "         0x60F5D0, 0x60F610 or 0x60F650."]),
    (0xFADB2C, "Evt2030_RunList", [
        "Evt2030_RunList -- walk the 0x2030 event list and dispatch every record",
        "                          through Evt2030_ClassHandlers",
        "",
        "Called from: prom_b directory slot T_F40850.",
        "Body:    return when bit 0 of (0x0922) is set and bit 1 is clear;",
        "         otherwise (0x60F08C) = 0 and loop: A = byte +0 of the record at",
        "         0x2030 + (0x60F08C); stop at 0xFF; skip when A > 0xBF; else",
        "         XIY = Evt2030_ClassHandlers[A]; skip when that is 0xFFFFFFFF;",
        "         load BC and DE from the record, save them to (0x60F0BC) and",
        "         (0x60F0BE), `call XIY`, advance (0x60F08C) by 4.",
        "Evidence: `ld (0x60f08c),0x0000` at 0xFADB3A, `ld XIX,0x00002030` at",
        "         0xFADB41, `cp A,0xff` at 0xFADB50, `cp A,0xbf` at 0xFADB55,",
        "         `ld XIY,0x00fae3a2` at 0xFADB5F, `cp XIY,0xffffffff` at",
        "         0xFADB69, `call T,XIY` at 0xFADB87, `inc 4,(0x60f08c)` at",
        "         0xFADB89.  The 0x2030 list itself is List2030_AppendRegs'",
        "         (0xF86AC7) buffer, whose header already names this loop as one",
        "         of its three consumers.",
        "★ 0xBF is the same bound MidiOut_ParamChanged uses on the SAME byte",
        "         (`cp C,0xbf` at 0xFA710B), and both tables have 192 entries."]),
    (0xFADD30, "BitMaskToOrdinal6", [
        "BitMaskToOrdinal6 -- 48 bytes indexed by a one-hot byte: 0x01 -> 0,",
        "                          0x02 -> 1, 0x04 -> 2, 0x08 -> 3, 0x10 -> 4,",
        "                          0x20 -> 5, every other index 0",
        "",
        "Read by: `ld A,(XIX+A)` at 0xFADD1D, with XIX loaded from",
        "         `ld XIX,0x00fadd30` at 0xFADD18, inside the shared tail at",
        "         0xFADCE5 that all three Evt2030_Class20to3F arms call.",
        "★ The inverse of OrdinalToBitMask6 at 0xFADA20 -- check C4 asserts the",
        "         round trip on all six, last included.",
        "Extent:  48 bytes, from 0xFADD30 to the code at 0xFADD60.  The largest",
        "         index it can be reached with is 0x3F (`and A,0x3f` at 0xFADD0A",
        "         and 0xFADD15), so 0x40 bytes would be the natural size and the",
        "         table is 0x30; indices 0x30..0x3F would run into the code.",
        "         ⚠ Stated as measured, not explained."]),
    (0xFADE8D, "ParamReset_SixParamsForIndex", [
        "ParamReset_SixParamsForIndex -- post six fixed parameter records for one",
        "                          index, through ParamChange_Notify",
        "",
        "Called from: prom_b directory slot T_F40890.  No call/jump line in any",
        "         of the four transcriptions names that slot, so nothing recorded",
        "         calls it; stated as a searched negative.",
        "Inputs:  A = the index, W = a source byte.",
        "Body:    return when A == 0x48.  W = (W & 0x0F) | 0x80, saved on the",
        "         stack; then six times: (0x60F007) = W, C = the parameter number,",
        "         B = A, DE = the fixed pair, `call 0xf407d0`.  The six parameter",
        "         numbers are 0xB5, 0xB7, 0xB6, 0xB1, 0xB2, 0xB4 in that order",
        "         and the pairs are 0x7F00 except 0xB1's 0x4000.",
        "Evidence: `cp A,0x48` at 0xFADE8D; `and W,0x0f` at 0xFADE92 and",
        "         `or W,0x80` at 0xFADE95; the six `ld C,0xbN` immediates at",
        "         0xFADEA0, 0xFADEB2, 0xFADEC4, 0xFADED6, 0xFADEE8 and 0xFADEFA, each",
        "         followed by `call 0xf407d0`.  Check C3 reads all six numbers",
        "         and all six pairs out of the ROM.",
        "Unknown:  why 0x48 is the excluded index."]),
    (0xFADF0D, "Dev7F_WriteAllFourSlots", [
        "Dev7F_WriteAllFourSlots -- call all four Dev7F_WriteSlot8 slot entries",
        "                          in order",
        "",
        "Called from: thirteen four-byte `calr <here> / ret` stubs inside this",
        "         module, at 0xFAD801, 0xFAD806, 0xFAD819, 0xFAD846, 0xFAD86C,",
        "         0xFAD886, 0xFAD89D, 0xFAD8B8, 0xFAD8D9, 0xFAD8FA, 0xFAD98B,",
        "         0xFAD9AC and 0xFAD9C7 -- one immediately after each of the",
        "         module's first thirteen entry points.  Check C5 re-derives that",
        "         list from the ROM and reports that NOTHING references any of the",
        "         thirteen stubs.",
        "Body:    `call 0xf40004 / call 0xf40008 / call 0xf4000c / call 0xf40010`",
        "         and `ret`, four directory slots that are",
        "         Dev7F_WriteSlot8_Slot0..Slot3 (prom_a 0xF83171, 0xF83179,",
        "         0xF83181, 0xF83189), all four already named.",
        "Evidence: the five instructions at 0xFADF0D-0xFADF1D.",
        "Unknown:  what device 0x7F is -- FINDINGS-memory-map.md already records",
        "         that as open, and this routine does not settle it."]),
    (0xFADF08, "sub_FADF08", [
        "sub_FADF08 -- a five-byte veneer: `call 0xf40fd0 / ret`",
        "",
        "Called from: prom_b directory slot T_F40894.",
        "★ IT KEEPS A sub_XXXXXX NAME ON PURPOSE.  It is a published entry point",
        "         and so it needs a label -- before this pass the twenty slots of",
        "         T_F40850-T_F4089C pointed at twenty addresses with no label at",
        "         all -- but its whole body is one call to T_F40FD0, which is",
        "         prom_a 0xFC10DD, and that routine is `sub_FC10DD`.  A veneer",
        "         can be named no better than its target, so this one is not",
        "         named.  A stated gap beats a plausible guess.",
        "Evidence: `call 0xf40fd0` at 0xFADF08 and `ret` at 0xFADF0C; prom_b's",
        "         directory line `T_F40FD0: jp 0xFC10DD`.",
        "Unknown:  everything 0xFC10DD does."]),
    (0xFADF1E, "ParamApply_ByModeOfParam80", [
        "ParamApply_ByModeOfParam80 -- apply the staged record through one of",
        "                          four arms chosen by (0x7F32) & 3",
        "",
        "Called from: prom_b directory slot T_F40854.",
        "Body:    `ld (0x60f01e),0xff`.  When C != 0x98 the routine jumps to",
        "         0xFAE032, which dispatches on (0x7F32) & 3 through the table at",
        "         0xFAE04D.  When C == 0x98 it first requires (0x7F02) & 0xF0 to",
        "         be 0x10, then builds a byte out of (0x60F652) and dispatches on",
        "         (0x7F32) & 3 through the table at 0xFADF77.",
        "Evidence: `cp C,0x98` at 0xFADF24, `ld A,(0x7f02)` at 0xFADF2A,",
        "         `cp A,0x10` at 0xFADF31, `ld WA,(0x60f652)` at 0xFADF37,",
        "         `ld L,(0x7f32)` at 0xFADF61 and `and L,0x03` at 0xFADF65,",
        "         `ld XIX,0x00fadf77` at 0xFADF6B; and the same three-instruction",
        "         selector again at 0xFAE032-0xFAE03C with 0xFAE04D.",
        "★ (0x7F32) is parameter number 0x80's record -- ParamNumber_RecordPtrs",
        "         entry 0x80 IS 0x7F32 -- and 0x7F02 is parameter 0x98's.",
        "Unknown:  ⚠ WHAT THE FOUR VALUES OF (0x7F32) & 3 MEAN IS NOT",
        "         ESTABLISHED.  Six separate tables in this span are indexed by",
        "         it (--tables lists them); bit 2 of the same byte is the",
        "         already-named follow-external-clock bit and prom_b 0xF6F858",
        "         writes the low two bits from (0x1380) before posting them as",
        "         {0x80, 0, value, 0x03}.  That names the PRODUCER, not the",
        "         meaning, and the arms keep their sub_XXXXXX names because of",
        "         it."]),
    (0xFAE223, "ParamApply_StorePairAndDerive", [
        "ParamApply_StorePairAndDerive -- store the staged value in a 16-bit",
        "                          table, then derive a byte from it by mode",
        "",
        "Called from: prom_b directory slot T_F40870.",
        "Body:    BC = (0x1950), DE = (0x1952); XIX = 0x60F530, XIZ = 0x60F570,",
        "         HL = 2*C -- or, when C == 0x98, XIX = 0x60F652, XIZ = 0x60F654,",
        "         HL = 0.  Store E at (XIX+HL) when E != 0xFF, otherwise D at",
        "         (XIX+HL+1), each with bit 7 cleared; mask the 16-bit pair with",
        "         0x7F7F; then dispatch on (0x7F32) & 3 through the table at",
        "         0xFAE28F and store the resulting A at (XIZ + C).",
        "Evidence: `ld XIX,0x0060f530` at 0xFAE22B, `ld XIZ,0x0060f570` at",
        "         0xFAE230, `cp C,0x98` at 0xFAE23C, `ld XIX,0x0060f652` at",
        "         0xFAE241, `cp E,0xff` at 0xFAE24D, `and WA,0x7f7f` at 0xFAE26D,",
        "         `ld B,(0x7f32)` at 0xFAE279 and `and B,0x03` at 0xFAE27D,",
        "         `ld XIY,0x00fae28f` at 0xFAE283, `ld (XIZ+HL),A` at 0xFAE2D8.",
        "Unknown:  what 0x60F530 and 0x60F570 hold, and what the four arms",
        "         compute.  The arms keep their sub_XXXXXX names."]),
    (EVT2030, "Evt2030_ClassHandlers", [
        "Evt2030_ClassHandlers -- 192 LE32 words: the handler for each parameter",
        "                          number 0x00-0xBF, or 0xFFFFFFFF for none",
        "",
        "★ THIS NAME WAS ALREADY IN THE TREE -- thirteen routine headers in this",
        "         module cite `Evt2030_ClassHandlers` -- but the table itself had",
        "         no label, so every citation pointed at a name that did not",
        "         exist.  This adds the label the prose already assumed.",
        "Read by: Evt2030_RunList, `ld XIY,0x00fae3a2` at 0xFADB5F, its only",
        "         reader (the table's address appears as a 32-bit little-endian",
        "         word at exactly one place in prom_a).",
        "Layout:  15 distinct values.  All 32 entries 0x00-0x1F hold",
        "         Evt2030_Class00to1F; all 32 entries 0x20-0x3F hold",
        "         Evt2030_Class20to3F; 0x98 holds Evt2030_Class98; eleven single",
        "         entries hold the eleven five-byte forwarders at",
        "         0xFADE56-0xFADE8C; the other 116 are 0xFFFFFFFF.",
        "★ Evidence, against ParamNumber_RecordPtrs and re-derived by check C6:",
        "         76 parameter numbers have a handler and 77 have a record; 65",
        "         have both; the eleven with a handler and NO record are exactly",
        "         0xB1-0xB5, 0xB8-0xBD, i.e. exactly the eleven forwarders.  Two",
        "         tables derived from different parts of the ROM agreeing on an",
        "         eleven-element set is what makes both of them readable."]),
]


# ------------------------------------- the old text this pass has to correct
# The rule is: if a measurement contradicts an earlier documented claim, commit
# the new evidence AND correct the old text in the same change.  Two pieces of
# prose in prom_a say something this pass disproves.

STRIP_HEADER = ["Lookup32_By_Arg8",      # its whole comment block is replaced
                "ParamShadow_SetParamB1", "ParamShadow_SetParamB2",
                "ParamShadow_SetParamB3",
                "Queue2C00_PublishStagedDrainQuiet",
                "ParamApply_PublishStagedAndSeedSeven"]

OLD_HEADER_MARK = ("; Lookup32_By_Arg8 -- 256 LE32 values, indexed by a "
                   "caller's byte argument")

PROSE_FIXES = [
    # the shared header over the eleven change records opens by naming record 00,
    # and record 00 is one of the nine this pass renames.
    ("; MidiOut_ChangeRecord_00 .. _10 -- eleven 12-byte records",
     "; The eleven MidiOut_ChangeRecord_* -- eleven 12-byte records"),
    # prom_a 0xFC6626's header, which spotted the same family of values in a
    # SECOND table and drew the same wrong conclusion from it.
    ("""          quantities that Lookup32_By_Arg8 (0xFACDEA, the other module) holds,
;          and neither module says what they mean.""",
     """          quantities that ParamNumber_RecordPtrs (0xFACDEA, the other
;          module) holds: 16-bit WORK-RAM addresses, 0x76A2 + 0x40*k being
;          parameter number k's record.  ⚠ That is established for THAT table
;          only (see its header); what THIS block, which nothing reads, is for
;          is still open."""),
]


def prose_state():
    """(fixes still to make, fixes already made) -- so a check can pass both
    before and after --apply instead of punishing the change it documents."""
    t = open(SRC["a"], encoding="utf-8").read()
    todo = [i for i, (o, _n) in enumerate(PROSE_FIXES) if t.count(o) == 1]
    done = [i for i, (_o, n) in enumerate(PROSE_FIXES) if t.count(n) == 1]
    return todo, done


# ------------------------------------------------ headers rewritten in place
# (label, address, new header).  The label KEEPS its name; its whole existing
# comment block is deleted and replaced.  Used where a later finding in this same
# pass made an earlier header of this same pass incomplete -- the three parameter
# numbers whose MEANING only became derivable once the change records and
# MidiOut_ParamNumberTable were read against each other.
HEADER_UPGRADES = [
    ("ParamShadow_SetExpression", 0xFAD84A, [
        "ParamShadow_SetExpression -- remember an EXPRESSION value (parameter",
        "                          number 0xB3) for index B, to be published",
        "                          later by ParamShadow_FlushAll",
        "",
        "Called from: prom_b directory slot T_F4086C.",
        "Body:    when C == 0xB0, store E with bit 7 forced into the single byte",
        "         at 0x60F650; otherwise, when B <= 0x1F, into the 32-byte array",
        "         at 0x60F590 indexed by B.  Bit 7 is the pending flag.",
        "Evidence: `cp C,0xb0` at 0xFAD84A, `ld (0x60f650),E` at 0xFAD852,",
        "         `cp B,0x1f` at 0xFAD859, `ld XIX,0x0060f590` at 0xFAD861.",
        "★ WHY 0xB3: ParamShadow_FlushAll walks 0x60F590 with W = 0xB3 (`ld",
        "         W,0xb3` at 0xFADA2B) and emits {W, index, value, 0x7F}.",
        "★ WHY \"EXPRESSION\", with three witnesses:",
        "         1. MidiOut_ParamNumberTable[0xB3] is MidiOut_CC0B_Expression;",
        "         2. the change record at 0xFA81A2 carries parameter number",
        "            0x00B3 in bytes [8:10] and the SAME routine in [4:8];",
        "         3. prom_a's own controller list spells controller #11 --",
        "            which is CC 0x0B -- `EXPRESSION (#11)` at 0xFA2C03.",
        "         Check R2 re-derives 1 and 2 for all eleven records; check W1",
        "         re-reads 3 from the ROM.",
        "Note:    the C == 0xB0 arm defers parameter number 0xB0 instead, whose",
        "         MidiOut_ParamNumberTable entry is a bare `ret` (0xFA767D), so",
        "         nothing echoes it and nothing here names it."]),
    ("ParamShadow_SetModulation1", 0xFAD88A, [
        "ParamShadow_SetModulation1 -- remember a MODULATION 1 value (parameter",
        "                          number 0xB2) for index B",
        "",
        "Called from: prom_b directory slot T_F40868.",
        "Body:    when B <= 0x1F, store E with bit 7 forced into the 32-byte",
        "         array at 0x60F5B0 indexed by B.",
        "Evidence: `cp B,0x1f` at 0xFAD88A, `ld XIX,0x0060f5b0` at 0xFAD892.",
        "         ParamShadow_FlushAll walks the same array with W = 0xB2",
        "         (`ld W,0xb2` at 0xFADA38) through the same shared loop it uses",
        "         for 0x60F590, which is what pins the parameter number.",
        "★ WHY \"MODULATION 1\", with three witnesses:",
        "         1. MidiOut_ParamNumberTable[0xB2] is MidiOut_CC01_Modulation;",
        "         2. the change record at 0xFA812A carries parameter number",
        "            0x00B2 and the same routine in [4:8];",
        "         3. prom_a's controller list spells controller #1 -- CC 0x01 --",
        "            `MODULATION1(# 1)` at 0xFA2BD3, and #2 `MODULATION2(# 2)`,",
        "            which is why the name carries the 1."]),
    ("ParamShadow_SetPitchBend", 0xFAD870, [
        "ParamShadow_SetPitchBend -- remember a PITCH BEND value AND its mask",
        "                          (parameter number 0xB1) for index B",
        "",
        "Called from: prom_b directory slot T_F40864.",
        "Body:    when B <= 0x1F, store the 16-bit DE -- with bit 7 of E forced --",
        "         at 0x60F5D0 + 2*B.  This is the ONLY 16-bit shadow of the four,",
        "         and on the flush the high byte becomes the record's mask.",
        "Evidence: `cp B,0x1f` at 0xFAD870, `set 0x07,E` at 0xFAD875,",
        "         `ld XIX,0x0060f5d0` at 0xFAD878, `sll 0x01,B` at 0xFAD87D,",
        "         `ld (XIX+B),DE` at 0xFAD880; ParamShadow_FlushAll reads the pair",
        "         back with `ld WA,(XIY+HL)` at 0xFADAC3 and emits",
        "         {0xB1, index, A, W}.",
        "★ WHY \"PITCH BEND\", and this one is weaker than the other two -- it has",
        "         no named handler to borrow from, so it is spelled out:",
        "         1. MidiOut_ParamNumberTable[0xB1] is sub_FA767E, and the code",
        "            that routine reaches builds its MIDI status byte with",
        "            `and A,0x0f` at 0xFA7703 and `or A,0xe0` at 0xFA7706 and sets a",
        "            three-byte length with `ld DE,0x0300` at 0xFA76F5.  0xEn is",
        "            the pitch-bend status in MIDI 1.0 -- ⚠ that last step is a",
        "            fact about the PROTOCOL, not about this ROM;",
        "         2. the change record at 0xFA8196 carries parameter number",
        "            0x00B1 with value bytes 0x4000, and 0x4000 is the pitch-bend",
        "            centre;",
        "         3. pitch bend is the only 14-bit channel message, and this is",
        "            the only one of the four shadows that stores 16 bits.",
        "         The `or A,0xe0` has two siblings and no others: `or A,0xc0` at",
        "         0xFA7612 and `or A,0xd0` at 0xFA7882 -- program change and",
        "         channel pressure -- so the idiom is the status-byte builder and",
        "         not a coincidence (check V1).",
        "Unknown:  sub_FA767E itself is still unnamed; naming it would retire",
        "         MidiOut_ChangeRecord_09's positional suffix as well."]),
]


# ⚠ Names whose header this same pass first wrote and then CORRECTED.  Check Z1
# decodes every `text` at 0xADDR citation in every header this file defines, and
# it caught EIGHT of this pass's own citations sitting a few bytes off the
# instruction -- the exact defect wave 7 round 1 shipped ~31 times.  Listing a
# name here makes --apply delete its stale block and write the corrected one.
HEADER_REWRITE = [
    "ParamShadow_FlushAll", "Evt2030_RunList", "ParamShadow_SetField3",
    "ParamShadow_SetExpression", "ParamShadow_SetModulation1",
    "ParamShadow_SetPitchBend", "ParamReset_SixParamsForIndex",
    "Evt2030_Class98_Op01", "ParamApply_ByModeOfParam80",
    "ParamApply_StorePairAndDerive", "Queue2C00_PublishStaged",
    "OrdinalToBitMask6",
]
STRIP_HEADER = list(dict.fromkeys(
    STRIP_HEADER + [n for n, _a, _h in HEADER_UPGRADES] + HEADER_REWRITE))


def header_for(name):
    """(address, header lines) for a name this file defines, wherever it is."""
    for n, a, h in HEADER_UPGRADES:
        if n == name:
            return a, h
    for a, n, h in INSERTS:
        if n == name:
            return a, h
    for a, _o, n, h in RENAMES:
        if n == name:
            return a, h
    raise SystemExit("HEADER_REWRITE names %s, which this file does not define"
                     % name)


def _hdr_ok(h):
    return any(l.startswith(("Evidence:", "Called from:", "★", "Read by:"))
               for l in h)


def dispatch_arm_headers():
    """Headers for the sub_XXXXXX arms of every jump table in the span.

    Generated from DISPATCH and the ROM rather than typed, so the indices and
    the Evidence: line come from the table's own bytes.  Only labels that are
    STILL sub_XXXXXX get one, and each is emitted once even when several indices
    share the arm."""
    have = region_labels()
    named = set(a for a, _o, _n, _h in plan_raw())
    out, seen = [], set()
    for t, n, sel, own in DISPATCH:
        rd = reader_of(t)
        for tgt, idx in arms(t, n):
            if tgt == 0xFFFFFFFF or not (LO <= tgt < HI) or tgt in seen:
                continue
            if tgt in named:
                continue
            nm = [x for x in have.get(tgt, []) if UNNAMED.match(x)]
            if not nm:
                continue
            seen.add(tgt)
            body = dis_at("a", tgt)
            ent = ", ".join("0x%06X" % (t + 4 * i) for i in idx)
            h = ["%s -- arm %s of the %d-entry jump table at 0x%06X"
                 % (nm[0], ", ".join(str(i) for i in idx), n, t),
                 "",
                 "Called from: %s, through XIX/XIY."
                 % ("the reader `%s` at 0x%06X" % (rd[1], rd[0]) if rd else
                    "NOTHING -- no instruction in prom_a loads this table"),
                 "         Index: %s." % sel,
                 "Owner:   %s." % own,
                 "Body:    starts `%s`." % (body[1] if body else "?"),
                 "Evidence: the LE32 word%s at %s reads 0x00%06X, and no other"
                 % ("" if len(idx) == 1 else "s", ent, tgt),
                 "         entry of that table does."]
            if "0x7F32" in sel:
                h += ["Unknown:  ⚠ WHAT THE FOUR VALUES OF (0x7F32) & 3 SELECT.",
                      "         SIX tables in this span are indexed by that same",
                      "         2-bit field; prom_b 0xF6F858 copies it from",
                      "         (0x1380) & 3 and posts it as {0x80, 0, v, 0x03}.",
                      "         That names the producer, not the meaning, so this",
                      "         label stays sub_XXXXXX.  A stated gap beats a",
                      "         plausible guess."]
            elif rd is None:
                h += ["Unknown:  everything.  Nothing loads the table, so nothing",
                      "         is known to reach this arm at all."]
            else:
                h += ["Unknown:  what the selector means.  Nothing in the tree",
                      "         names %s, so this label stays sub_XXXXXX." % sel]
            out.append((tgt, nm[0], nm[0], h))
    return out


# ---------------------------------------------------- the instrument's OWN words
# prom_a 0xFA2BC3 and 0xFA2CC3 are two lists of 16-byte ASCII names for the
# assignable controllers, and each entry carries its own controller number in the
# text.  They are inside the still-unconverted `.incbin` 0xFA1404-0xFA5400, so
# there is nowhere to hang a label; --controllers prints them from the ROM.
CTRL_LISTS = [(0xFA2BC3, 16), (0xFA2CC3, 8)]
CTRL_NUM = re.compile(r'\(#\s*(\d+)\)')


def controller_names():
    """{controller number: this machine's own word for it}, read from the ROM."""
    out = {}
    for base, n in CTRL_LISTS:
        for i in range(n):
            t = by("a", base + 16 * i, 16).decode("ascii", "replace")
            m = CTRL_NUM.search(t)
            if m:
                out.setdefault(int(m.group(1)), t.split("(")[0].strip())
    return out


def show_controllers():
    print("prom_a's own ASCII lists of assignable controllers.\n")
    for base, n in CTRL_LISTS:
        print("  0x%06X, %d entries of 16 bytes:" % (base, n))
        for i in range(n):
            print("    [%2d] 0x%06X  %r"
                  % (i, base + 16 * i,
                     by("a", base + 16 * i, 16).decode("ascii", "replace")))
        print()
    print("  controller number -> the word THIS INSTRUMENT uses:")
    for k, v in sorted(controller_names().items()):
        print("    #%-3d = CC 0x%02X  %s" % (k, k, v))
    print("\n  ⚠ Both lists sit inside the .incbin at 0xFA1404-0xFA5400, so nothing")
    print("  in prom_a/wsa1_prom_a.s can carry a label for them yet.  Whoever")
    print("  converts that span should name them from this.")
    return 0


# The MIDI 1.0 spec name and the word the ROM uses are not the same for seven
# controllers, and for two of them the spec word appears NOWHERE in any of the
# four images.  (old word, new word, controller number, ROM address of the string)
CC_WORDS = [
    ("CC02", "Breath", "Modulation2", 2, 0xFA2BE3),
    ("CC04", "Foot", "CtrlPedal", 4, 0xFA2BF3),
    ("CC10", "General1", "RTCreatX", 16, 0xFA2C23),
    ("CC11", "General2", "RTCreatY", 17, 0xFA2C33),
    ("CC12", "General3", "RTCtrlX", 18, 0xFA2C43),
    ("CC13", "General4", "RTCtrlY", 19, 0xFA2C53),
    ("CC40", "Damper", "Hold", 64, 0xFA2C13),
]


def cc_word_renames():
    """Rename every prom_a label whose name glosses a controller with a word the
    ROM does not use for it.  Generated from the label list, so a sibling like
    `__emit` or `_ParamTable` cannot be missed."""
    out = []
    names = sorted(set(n for n, _a in labels("a")))
    for cc, old_w, new_w, num, sa in CC_WORDS:
        txt = by("a", sa, 16).decode("ascii", "replace")
        hits = [n for n in names if ("_%s_%s" % (cc, old_w)) in n]
        for n in hits:
            new = n.replace("_%s_%s" % (cc, old_w), "_%s_%s" % (cc, new_w))
            addr = dict((x, y) for x, y in labels("a")).get(n)
            out.append((addr, n, new, [
                "★ RENAMED FROM %s.  Controller %d is what this" % (n, num),
                "         instrument's own on-screen list at 0x%06X calls" % sa,
                "         `%s` -- the string is 16 bytes and carries the" % txt.strip(),
                "         controller number in its own text.  `%s` is the MIDI 1.0"
                % old_w,
                "         spec's word for the same controller number, not this",
                "         machine's, and for `Breath` and `General` the spec word",
                "         occurs ZERO times in all four images (check W2).  The",
                "         controller NUMBER in the label is unchanged and is still",
                "         the thing that is proven; only the gloss moved to the",
                "         word the ROM itself uses.",
                "Evidence: notes/prom_a_understanding_round4.py --controllers prints",
                "         both lists straight from the ROM; check W1 re-reads this",
                "         entry and re-extracts the number from the parentheses."]))
    return out


def final_name(n):
    """A label name with the CC_WORDS substitutions already applied, so a suffix
    generated from it agrees with what that label will be called after --apply."""
    for cc, old_w, new_w, _num, _sa in CC_WORDS:
        n = n.replace("_%s_%s" % (cc, old_w), "_%s_%s" % (cc, new_w))
    return n


def part_ptr_renames():
    """MidiOut_PartRecordPtrs_NN -> named after the routine that loads it.

    The 25 blocks are BYTE-IDENTICAL, so the ONLY thing that distinguishes one
    from another is which routine's `ld XIX,<base>` names it -- which is exactly
    what the number in the old name does NOT say.  A block is renamed only when
    the byte scan finds exactly ONE occurrence of its address and the routine
    that occurrence falls in already has a name."""
    src = lines("a")
    nm_a = name_at("a")
    starts = sorted(set(a for _n, a in labels("a")))
    out, used = [], collections.Counter()
    rows = []
    for i, l in enumerate(src):
        m = re.match(r'^MidiOut_PartRecordPtrs_(\d+):', l)
        if not m:
            continue
        am = ADDRC.search(src[i + 1])
        if not am:
            continue
        t = int(am.group(1), 16)
        hits = table_readers(t)
        rows.append((m.group(0)[:-1], t, hits))
    for old, t, hits in rows:
        if len(hits) != 1:
            continue
        a = hits[0] - 1
        j = 0
        for x in starts:
            if x <= a:
                j = x
            else:
                break
        owner = [n for n in nm_a.get(j, []) if not UNNAMED.match(n)]
        if not owner:
            continue
        used[owner[0]] += 1
    for old, t, hits in rows:
        if len(hits) != 1:
            continue
        a = hits[0] - 1
        j = 0
        for x in starts:
            if x <= a:
                j = x
            else:
                break
        owner = [n for n in nm_a.get(j, []) if not UNNAMED.match(n)]
        if not owner or used[owner[0]] != 1:
            continue
        suffix = final_name(owner[0]).replace("MidiOut_", "").replace("_", "")
        out.append((t, old, "MidiOut_PartRecordPtrs_" + suffix, [
            "MidiOut_PartRecordPtrs_%s -- the copy %s loads"
            % (suffix, final_name(owner[0])),
            "",
            "★ RENAMED FROM %s.  All 25 of these blocks are" % old,
            "         BYTE-IDENTICAL (their shared header says so and check B2 of",
            "         notes/gen_prom_a_fa5aeb_module.py proves it), so the number",
            "         in the old name said only \"the Nth in address order\".  What",
            "         actually distinguishes this block is the routine that loads",
            "         it, and that routine has a name.",
            "Read by: `ld XIX,0x00%06x` at 0x%06X, inside %s.  The table's address"
            % (t, a, owner[0]),
            "         occurs EXACTLY ONCE as a 32-bit little-endian word anywhere",
            "         in prom_a, and the byte at 0x%06X is the `ld` opcode -- the"
            % a,
            "         instruction address, not the operand address one byte later.",
            "Evidence: check R1 re-runs the scan and the owner lookup for every one",
            "         of the 25 blocks and reports which are renamed and which are",
            "         not; the eleven that are not are listed by --gaps."]))
    return out


def change_record_renames():
    """MidiOut_ChangeRecord_NN -> named after the handler in its own bytes [4:8].

    The old suffix is the record's index in the table.  Bytes [4:8] of each
    record are a routine pointer -- the existing header calls it \"a routine
    called with the parameter staged\" -- and nine of the eleven point at a
    routine prom_a already names."""
    src = lines("a")
    nm_a = name_at("a")
    out = []
    rows = []
    for i, l in enumerate(src):
        m = re.match(r'^MidiOut_ChangeRecord_(\d+):', l)
        if not m:
            continue
        am = ADDRC.search(src[i + 1])
        if am:
            rows.append((m.group(0)[:-1], int(am.group(1), 16)))
    for old, a in rows:
        r = by("a", a, 12)
        p2 = int.from_bytes(r[4:8], "little")
        pid = int.from_bytes(r[8:10], "little")
        nm = [n for n in nm_a.get(p2, []) if not UNNAMED.match(n)]
        if not nm:
            continue
        suffix = final_name(nm[0]).replace("MidiOut_", "").replace("_", "")
        out.append((a, old, "MidiOut_ChangeRecord_" + suffix, [
            "MidiOut_ChangeRecord_%s -- the record whose handler is %s"
            % (suffix, final_name(nm[0])),
            "",
            "★ RENAMED FROM %s, whose suffix was the record's position" % old,
            "         in the table and nothing else.",
            "Body:    12 bytes at 0x%06X.  [0:4] = 0x%08X, [4:8] = 0x%08X"
            % (a, int.from_bytes(r[0:4], "little"), p2),
            "         (%s), [8:10] = parameter number 0x%04X, [10:12] = 0x%04X."
            % (final_name(nm[0]), pid, int.from_bytes(r[10:12], "little")),
            "★ Evidence, and it is a THIRD independent derivation of the same",
            "         eleven-element set: the eleven records' [8:10] fields are",
            "         exactly {0xB1..0xB5, 0xB8..0xBD} -- the eleven parameter",
            "         numbers that have an Evt2030 handler and no record in",
            "         ParamNumber_RecordPtrs, and the eleven the forwarders at",
            "         0xFADE56-0xFADE8C serve.  And for this record",
            "         MidiOut_ParamNumberTable[0x%02X] is %s too, so the pairing"
            % (pid & 0xFF, nm[0]),
            "         has two witnesses.  Check R2 re-derives both for all eleven."]))
    return out


def plan_raw():
    """The renames and inserts, before the generated arm headers.

    ⚠ Entries whose change is ALREADY IN THE FILE are dropped, so --apply is
    idempotent and --selftest passes both before and after it.  A check that
    only passes before the change it documents is not a check."""
    have = set(n for n, _a in labels("a")) | set(
        sum(region_labels().values(), []))
    out = []
    for a, old, new, h in RENAMES:
        if new in have:
            continue
        # ⚠ resolve the OLD name against what the address carries TODAY.  Some
        # of these entries rename a name an EARLIER draft of this same file
        # applied, so from a pristine tree the label is still its sub_XXXXXX and
        # the entry would find nothing to rename.
        cur = labels_at(a) if a is not None else []
        if old not in cur and cur:
            old = cur[0]
        out.append((a, old, new, h))
    for a, new, h in INSERTS:
        if new in have:
            continue
        cur = labels_at(a)
        if cur:
            # the address already carries a label -- an earlier --apply of an
            # older name for the same routine.  Rename it rather than inserting
            # a second label at one address.
            out.append((a, cur[0], new, h))
        else:
            out.append((a, None, new, h))
    for n in dict.fromkeys([x[0] for x in HEADER_UPGRADES] + HEADER_REWRITE):
        a, h = header_for(n)
        out.append((a, n, n, h))
    for a, old, new, h in (part_ptr_renames() + change_record_renames()
                           + cc_word_renames()):
        if new in have:
            continue
        cur = labels_at(a) if a is not None else []
        if old not in cur and cur:
            old = cur[0]
        out.append((a, old, new, h))
    return out


def plan():
    """Everything --apply would write, minus anything already written.

    ⚠ The last filter matters: the arm headers are keyed by a label that KEEPS
    its name, so nothing else stops --apply from adding them a second time.  An
    entry whose header's first line is already in the file is already done."""
    txt = open(SRC["a"], encoding="utf-8").read()
    upg = set(n for n, _a, _h in HEADER_UPGRADES) | set(HEADER_REWRITE)
    out = []
    for e in plan_raw() + dispatch_arm_headers():
        # a HEADER_UPGRADE is exempt: its old block is deleted by STRIP_HEADER
        # first, so re-writing it is idempotent rather than a duplicate.
        if e[2] not in upg and ("; " + e[3][0]) in txt:
            continue
        out.append(e)
    return out


def show_plan():
    p = plan()
    have = set(n for n, _a in labels("a"))
    ren = [x for x in p if x[1] is not None and x[1] != x[2]]
    ins = [x for x in p if x[1] is None]
    hdr = [x for x in p if x[1] is not None and x[1] == x[2]]
    clash = sorted(set(n for _a, _o, n, _h in ren + ins) & have)
    dup = collections.Counter(n for _a, _o, n, _h in ren + ins)
    print("%d renames, %d new labels, %d header-only entries" % (len(ren), len(ins), len(hdr)))
    print("new names that already exist in prom_a: %s" % (clash or "none"))
    print("duplicate new names: %s" % ([n for n, c in dup.items() if c > 1] or "none"))
    print("headers with no Evidence:/Called from:/★/Read by: line: %s"
          % ([n for _a, _o, n, h in p if not _hdr_ok(h)] or "none"))
    for a, old, new, _h in sorted(p):
        print("  0x%06X  %-34s -> %s" % (a, old or "(no label)", new))
    return 1 if clash or any(c > 1 for c in dup.values()) else 0


# ------------------------------------------------------------------- applying
def apply():
    """Rewrite prom_a/wsa1_prom_a.s.  Idempotent: running it twice is a no-op.

    ⚠ THE ORDER MATTERS AND IT IS NOT THE OBVIOUS ONE.
      * The renames run BEFORE the headers are inserted.  The first draft did it
        the other way and the rename then rewrote its OWN header text: the note
        `★ RENAMED FROM MidiOut_CC40_Damper` came out as `★ RENAMED FROM
        MidiOut_CC40_Hold`, a sentence that says nothing.  So headers go in last,
        keyed by the NEW label name.
      * A header is APPENDED to an existing comment block rather than stacked on
        top of it.  The same first draft left two blocks above every renamed
        MidiOut_CC* label, the older one still glossing the controller with the
        word this pass had just replaced.  Where a label already has a block,
        these lines join it before its closing rule; where it has none, a fresh
        block is written.
      * PROSE_FIXES run before the renames, because they are written against the
        old label names."""
    src_a = SRC["a"]
    p = plan()
    have = set(n for n, _a in labels("a"))
    ren = [x for x in p if x[1] is not None and x[1] != x[2]]
    ins = [x for x in p if x[1] is None]
    bad = sorted(set(n for _a, _o, n, _h in ren + ins) & have)
    if bad:
        sys.exit("REFUSING TO APPLY: these names already exist in prom_a: %s"
                 % ", ".join(bad))
    lmap, mism, fin = region_map()
    if mism or fin != HI:
        sys.exit("REFUSING TO APPLY: the region line map does not verify "
                 "(%d mismatches, ends 0x%06X)" % (len(mism), fin))

    # 1. label insertions, by line, deepest first so earlier indices stay valid
    src = list(lines("a"))
    ins_by_line = {}
    for a, _old, new, h in ins:
        if LO <= a < HI:
            cands = [i for i in sorted(lmap) if lmap[i] == a]
            if not cands:
                sys.exit("REFUSING TO APPLY: no line in the region holds "
                         "0x%06X" % a)
            ins_by_line[cands[0]] = new
        else:
            # outside the emitted region every line carries a `; ADDR` comment
            cands = [i for i, l in enumerate(src)
                     if not l.startswith(";") and l.strip()
                     and ADDRC.search(l)
                     and int(ADDRC.search(l).group(1), 16) == a]
            if len(cands) != 1:
                sys.exit("REFUSING TO APPLY: 0x%06X matched %d lines outside the "
                         "region, need exactly 1" % (a, len(cands)))
            ins_by_line[cands[0]] = new
    for i in sorted(ins_by_line, reverse=True):
        src[i:i] = [ins_by_line[i] + ":"]

    # 2. delete the comment block above any label whose header is REPLACED
    for nm in STRIP_HEADER:
        k = [i for i, l in enumerate(src) if l.startswith(nm + ":")]
        if not k:
            continue                      # already renamed by an earlier --apply
        if len(k) != 1:
            sys.exit("REFUSING TO APPLY: %s: found %d labels, need 1" % (nm, len(k)))
        j = k[0]
        while j > 0 and src[j - 1].startswith(";"):
            j -= 1
        del src[j:k[0]]

    # 3. the prose elsewhere in prom_a that this pass disproves, THEN the renames
    text = "\n".join(src)
    fixed = 0
    for o, n in PROSE_FIXES:
        if text.count(n) == 1:
            continue
        if text.count(o) != 1:
            sys.exit("REFUSING TO APPLY: a prose fix matched %d times, need 1"
                     % text.count(o))
        text = text.replace(o, n)
        fixed += 1
    nref = 0
    for _a, old, new, _h in ren:
        text, k = re.subn(r"\b%s\b" % re.escape(old), new, text)
        nref += k

    # 4. the headers, keyed by the NEW name, appended to an existing block
    hdr = {n: h for _a, _o, n, h in p}
    src, out, appended, prepended = text.split("\n"), [], 0, 0
    for ln in src:
        m = LABEL.match(ln)
        if m and m.group(1) in hdr:
            h = hdr.pop(m.group(1))
            body = [("; " + l).rstrip() for l in h]
            # is there already a comment block directly above?
            k = len(out)
            while k > 0 and out[k - 1].startswith(";"):
                k -= 1
            if k < len(out):
                # yes -- join it, before its closing rule if it has one
                at = len(out)
                if out[-1].startswith("; ---"):
                    at -= 1
                out[at:at] = [";"] + body
                appended += 1
            else:
                out += ["; " + "-" * 69] + body + ["; " + "-" * 69]
                prepended += 1
        out.append(ln)
    if hdr:
        sys.exit("REFUSING TO APPLY: no label found for %s" % ", ".join(sorted(hdr)))
    open(src_a, "w", encoding="utf-8").write("\n".join(out))
    print("%d prose corrections applied elsewhere in prom_a" % fixed)
    print("%d labels renamed (%d textual references), %d new labels inserted"
          % (len(ren), nref, len(ins)))
    print("%d header blocks written fresh, %d appended to an existing block"
          % (prepended, appended))
    print("NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


# ---------------------------------------------------------------------- gaps
def show_gaps():
    print("What this pass did NOT settle, and what would settle it.\n")
    for t, txt in GAPS:
        print("  %-34s %s" % (t, txt))
    return 0


GAPS = [
    ("MidiOut_PartRecordPtrs_00", "five routines read it -- MidiOut_ProgramChange "
     "and the four MidiOut_BankSelect_* halves -- so no single reader names it; "
     "it keeps its positional suffix."),
    ("MidiOut_PartRecordPtrs_16/_17", "ONE routine, MidiOut_CC40_Hold__emit, "
     "loads both (0xFA790E and 0xFA793E), so a reader-derived name would "
     "collide; both keep their positional suffix."),
    ("MidiOut_PartRecordPtrs_11..15, 18..23", "each has exactly one reader and "
     "that reader is still a sub_XXXXXX.  Name those eleven routines and these "
     "eleven tables name themselves."),
    ("MidiOut_ChangeRecord_08, _09", "their [4:8] handlers, sub_FA77FA and "
     "sub_FA767E, have no name.  sub_FA767E is parameter 0xB1's outbound "
     "handler and the code it reaches builds a MIDI status byte with "
     "`or A,0xe0` at 0xFA7706 -- see the ParamShadow_SetPitchBend header."),
    ("the 0xFA2BC3 / 0xFA2CC3 name lists", "they are inside the .incbin at "
     "0xFA1404-0xFA5400 and so cannot carry a label at all yet; --controllers "
     "prints them from the ROM."),
    ("(0x7F32) & 3", "six jump tables in this span are indexed by it and its "
     "four values name nothing.  prom_b 0xF6F848-0xF6F862 is the only producer "
     "found: it copies (0x1380) & 3 into it.  Name (0x1380) and this closes."),
    ("(0x60F308) & 3", "two more tables (0xFAF16C, 0xFAF410) and an eight-way "
     "one (0xFAEDF0, on bits 4-6 of the same byte).  No producer looked for."),
    ("0xFAE802, 0xFAE83E", "two pointer tables whose address appears NOWHERE in "
     "prom_a as a 32-bit word, so nothing loads them.  Their eight and three "
     "arms are 1-byte `ret`s.  Dead, or reached by arithmetic."),
    ("0xFADD60, 0xFADD89", "two handlers shaped exactly like Evt2030_Class98 "
     "that nothing references, and every arm of both is a `ret`."),
    ("the record field layout", "ParamNumber_RecordPtrs gives each parameter's "
     "record base; only +0x0D and +0x1B..+0x1D have a documented meaning."),
    ("(0x60F01E)", "written 0xFF by every ParamApply_ entry and seeded 0x7F at "
     "0xFAA86D.  No reader identified."),
    ("(0x60F007)", "a source/flags byte set before each ParamChange_Notify and "
     "bit-7-cleared by MidiOut_ParamChanged.  Bits unnamed."),
    ("the second module in the span", "T_F41F10-T_F41F3C publishes twelve entry "
     "points from 0xFAE800 upward; this pass only headered its jump-table arms."),
]


# ------------------------------------------------------------------- selftest
_RUN = [0]


def check(msg, got, want):
    ok = got == want
    _RUN[0] += 1
    print("  %-72s %-22s %s" % (msg, repr(got)[:22],
                                "OK" if ok else "FAILED (want %r)" % (want,)))
    return 0 if ok else 1


def selftest():
    bad = 0
    print("M. the line map -- what licenses inserting a label by address")
    lmap, mism, fin = region_map()
    bad += check("M1 mismatches against every banner, label and address comment",
                 len(mism), 0)
    bad += check("M2 the walk ends exactly on the region end", "0x%06X" % fin,
                 "0x%06X" % HI)
    bad += check("M3 the map covers this many lines", len(lmap) > 3000, True)
    bad += check("M4 the FIRST entry point resolves to a line",
                 line_of(0xFAD80A) is not None, True)
    bad += check("M5 the LAST insert address inside the region resolves too",
                 line_of(max(a for a, _n, _h in INSERTS if LO <= a < HI))
                 is not None, True)

    print("S. the published entry points")
    allsl, s = slots(), module_slots()
    bad += check("S1 directory slots pointing anywhere into the span", len(allsl), 33)
    bad += check("S1 ...of which this module's own run", len(s), 20)
    bad += check("S2 the first is T_F40850 -> 0xFADB2C",
                 ("T_%06X" % s[0][0], "0x%06X" % s[0][1]), ("T_F40850", "0xFADB2C"))
    bad += check("S3 the LAST is T_F4089C -> 0xFAD9CB",
                 ("T_%06X" % s[-1][0], "0x%06X" % s[-1][1]), ("T_F4089C", "0xFAD9CB"))
    reg = region_labels()
    named_by_us = set(a for a, _n, _h in INSERTS)
    unl = sorted(set(t for _s, t in allsl if t not in reg))
    # ⚠ NOT a "before" count.  All 33 were unlabelled when this pass started;
    # pinning 33 would make the check fail the moment the pass succeeds, which
    # is the mistake wave 7 already made once.  The INVARIANT is which ones this
    # pass deliberately leaves alone: the two bare `ret` entries of this
    # module's run, the twelve of the second module at 0xFAE800 upward, and
    # T_F40840's 0xFB1800 in the span's tail.
    bad += check("S4 published entry points this pass leaves unlabelled "
                 "(33 were unlabelled before it)",
                 len([t for t in set(t for _s, t in allsl)
                      if t not in reg and t not in named_by_us]), 15)
    bad += check("S4 ...and twelve of those fifteen are the SECOND module's",
                 len([t for _s, t in slots(0xF41F10, 0xF41F3C)
                      if t not in reg and t not in named_by_us]), 12)
    bad += check("S5 ...and after it, the only ones in THIS module's run still "
                 "unlabelled are the two bare `ret` entries",
                 ["0x%06X" % t for t in
                  sorted(t for _s, t in s if t not in reg and t not in named_by_us)],
                 ["0xFAD800", "0xFAD805"])
    bad += check("S6 0xFAD800 and 0xFAD805 really are one `ret` each",
                 [dis_at("a", 0xFAD800)[1], dis_at("a", 0xFAD805)[1]],
                 ["ret", "ret"])

    print("T. ParamNumber_RecordPtrs, the table whose old header was wrong")
    t = param_table()
    e, part = t["e"], t["part"]
    bad += check("T1 live entries", len([i for i in range(256) if e[i] != 0xFFFFFFFF]), 77)
    bad += check("T1 ...empty entries (the old header's 179)",
                 256 - len([i for i in range(256) if e[i] != 0xFFFFFFFF]), 179)
    bad += check("T2 every live value is a 16-bit quantity",
                 all(e[i] < 0x10000 for i in t["live"]), True)
    bad += check("T2 ...and they span this range",
                 ("0x%04X" % min(e[i] for i in t["live"]),
                  "0x%04X" % max(e[i] for i in t["live"])), ("0x7622", "0x7F5A"))
    bad += check("T3 entries 0xC0-0xFF are all empty",
                 all(e[i] == 0xFFFFFFFF for i in range(0xC0, 0x100)), True)
    bad += check("T4 %s has 32 entries" % PARTPTRS, len(part), 32)
    bad += check("T4 ...and entry[k] + 0x0D == that table[k] for ALL 32",
                 all(part[i] == e[i] + 0x0D for i in range(32)), True)
    bad += check("T4 ...LAST element checked explicitly",
                 ("0x%04X" % part[31], "0x%04X" % (e[31] + 0x0D)),
                 ("0x7EAF", "0x7EAF"))
    bad += check("T5 entries 0x00-0x1F step 0x40 except one 0x80 after index 7",
                 sorted(set(t["steps"])) == [0x40, 0x80]
                 and [i for i, s in enumerate(t["steps"]) if s == 0x80] == [7], True)
    bad += check("T6 entry[0x20+i] == entry[i] + 0x20 for all 32",
                 all(e[0x20 + i] == e[i] + 0x20 for i in range(32)), True)
    bad += check("T7 entry[0x80] is (0x7F32), the mode byte",
                 "0x%04X" % e[0x80], "0x7F32")
    for a in FFFF_TESTS:
        bad += check("T8 0x%06X really tests a fetched entry for 0xFFFFFFFF" % a,
                     dis_at("a", a)[1], "cp XIX,0xffffffff")
    for a in PTR_WRITERS:
        bad += check("T9 0x%06X really loads 0x%06X" % (a, PARAMPTRS),
                     dis_at("a", a)[1], "lda XBC,0x%06x" % PARAMPTRS)
    bad += check("T9 ...and 0xFAA878 stores it in (0x60F018)",
                 dis_at("a", 0xFAA878)[1], "ld (0x60f018),XBC")

    print("C. the routine-level claims each header makes")
    d = rom("a")

    def diff(x, y, n):
        return sum(1 for i in range(n)
                   if d[x - A_BASE + i] != d[y - A_BASE + i])
    bad += check("C1 0xFAA623 vs 0xFAA66A: length, differing count",
                 (71, diff(0xFAA623, 0xFAA66A, 71)), (71, 2))
    bad += check("C1 ...and the two offsets that differ",
                 [i for i in range(71)
                  if d[0xFAA623 - A_BASE + i] != d[0xFAA66A - A_BASE + i]], [2, 67])
    bad += check("C1 ...they are push/pop width, not logic",
                 [hex(d[0xFAA623 - A_BASE + 2]), hex(d[0xFAA66A - A_BASE + 2]),
                  hex(d[0xFAA623 - A_BASE + 67]), hex(d[0xFAA66A - A_BASE + 67])],
                 ["0x3b", "0x2b", "0x5b", "0x4b"])
    bad += check("C2 0xFAD8BC vs 0xFAD8DD: 29 bytes, differing count",
                 diff(0xFAD8BC, 0xFAD8DD, 29), 0)
    bad += check("C2 ...both end in `ret` at +28",
                 (d[0xFAD8BC - A_BASE + 28], d[0xFAD8DD - A_BASE + 28]), (0x0E, 0x0E))
    bad += check("C2 ...at 33 bytes the count is 1, and that byte is the "
                 "FOLLOWING stub's calr displacement",
                 (diff(0xFAD8BC, 0xFAD8DD, 33),
                  [i for i in range(33)
                   if d[0xFAD8BC - A_BASE + i] != d[0xFAD8DD - A_BASE + i]]), (1, [30]))
    bad += check("C2 0xFAD8A1 vs 0xFAD9B0: 23 bytes, differing count",
                 diff(0xFAD8A1, 0xFAD9B0, 23), 0)
    bad += check("C2 ...both end in `ret` at +22",
                 (d[0xFAD8A1 - A_BASE + 22], d[0xFAD9B0 - A_BASE + 22]), (0x0E, 0x0E))
    seven = [d[a - A_BASE + 1] for a in (0xFAD91A, 0xFAD927, 0xFAD934, 0xFAD941,
                                         0xFAD94E, 0xFAD95B, 0xFAD968)]
    bad += check("C3 the seven parameter numbers 0xFAD8FE posts",
                 ["0x%02X" % x for x in seven],
                 ["0xB1", "0xB4", "0xB2", "0xB3", "0xB5", "0xB6", "0xB7"])
    pairs = [int.from_bytes(d[a - A_BASE + 1:a - A_BASE + 3], "little")
             for a in (0xFAD920, 0xFAD92D, 0xFAD93A, 0xFAD947, 0xFAD954,
                       0xFAD961, 0xFAD96E)]
    bad += check("C3 ...and the seven WA immediates, LAST included",
                 ["0x%04X" % x for x in pairs],
                 ["0x4000", "0x7F00", "0x7F00", "0x7F7F", "0x7F00", "0x7F00", "0x7F00"])
    six = [d[a - A_BASE + 1] for a in (0xFADEA0, 0xFADEB2, 0xFADEC4, 0xFADED6,
                                       0xFADEE8, 0xFADEFA)]
    bad += check("C3 the six parameter numbers ParamReset_SixParamsForIndex posts",
                 ["0x%02X" % x for x in six],
                 ["0xB5", "0xB7", "0xB6", "0xB1", "0xB2", "0xB4"])
    o2b = list(d[0xFADA20 - A_BASE:0xFADA20 - A_BASE + 6])
    b2o = list(d[0xFADD30 - A_BASE:0xFADD30 - A_BASE + 48])
    bad += check("C4 OrdinalToBitMask6 is the six one-hot bytes",
                 [hex(x) for x in o2b],
                 ["0x1", "0x2", "0x4", "0x8", "0x10", "0x20"])
    bad += check("C4 ...and BitMaskToOrdinal6 inverts it on all six, LAST included",
                 [b2o[o2b[k]] for k in range(6)], [0, 1, 2, 3, 4, 5])
    bad += check("C4 ...every other index of the 48 is 0",
                 sum(1 for i in range(48) if b2o[i] and i not in o2b), 0)
    stubs = [a for a in range(LO, 0xFADF0D)
             if d[a - A_BASE] == 0x1E and d[a - A_BASE + 3] == 0x0E
             and a + 3 + int.from_bytes(d[a - A_BASE + 1:a - A_BASE + 3],
                                        "little", signed=True) == 0xFADF0D]
    bad += check("C5 four-byte `calr Dev7F_WriteAllFourSlots / ret` stubs", len(stubs), 13)
    bad += check("C5 ...first and LAST",
                 ("0x%06X" % stubs[0], "0x%06X" % stubs[-1]),
                 ("0xFAD801", "0xFAD9C7"))
    pat = [(a.to_bytes(4, "little") in d) for a in stubs]
    bad += check("C5 ...and NOTHING in prom_a names any of the thirteen",
                 any(pat), False)
    rec, hnd = t["rec"], t["hnd"]
    bad += check("C6 parameter numbers with a record / with a handler / both",
                 (len(rec), len(hnd), len(rec & hnd)), (77, 76, 65))
    bad += check("C6 handler but NO record -- the eleven forwarders",
                 sorted("0x%02X" % x for x in hnd - rec),
                 ["0xB1", "0xB2", "0xB3", "0xB4", "0xB5", "0xB8", "0xB9", "0xBA",
                  "0xBB", "0xBC", "0xBD"])
    bad += check("C6 ...and every one of those eleven really is a 5-byte "
                 "`call 0xf407cc / ret`",
                 sorted(set(bytes(d[t["h"][k] - A_BASE:t["h"][k] - A_BASE + 5])
                            for k in sorted(hnd - rec))),
                 [bytes.fromhex("1dcc07f40e")])
    bad += check("C6 record but NO handler (12)",
                 sorted("0x%02X" % x for x in rec - hnd),
                 ["0x60", "0x61", "0x62", "0x63", "0x78", "0x79", "0x7A", "0x80",
                  "0x91", "0x92", "0x93", "0x99"])

    print("D. the jump tables and their readers")
    noread = []
    for tb, n, _sel, _own in DISPATCH:
        rd = reader_of(tb)
        if rd is None:
            noread.append("0x%06X" % tb)
            bad += check("D 0x%06X: no `ld XIX/XIY,<table>` loads it" % tb,
                         table_readers(tb), [])
        else:
            bad += check("D 0x%06X's reader instruction decodes as its own load"
                         % tb, rd[1], "ld %s,0x00%06x"
                         % ({0x44: "XIX", 0x45: "XIY", 0x46: "XIZ"}[by("a", rd[0], 1)[0]],
                            tb))
            bad += check("D ...and the byte at cited-1 is NOT another operand "
                         "byte (the off-by-one test)",
                         by("a", rd[0], 1)[0] in (0x44, 0x45, 0x46), True)
    bad += check("D exactly two tables in the span have no reader at all",
                 noread, ["0xFAE802", "0xFAE83E"])
    bad += check("D the LAST table in the list still has %d entries"
                 % DISPATCH[-1][1],
                 len(arms(DISPATCH[-1][0], DISPATCH[-1][1])) <= DISPATCH[-1][1], True)

    print("I. the two INSTRUCTION COUNTS this pass claims, counted across the")
    print("   routine's whole ADDRESS EXTENT -- a label-bounded count gave 17 for")
    print("   a 30-instruction routine in round 3")
    n_i, x = 0, 0xFADF0D
    while x < 0xFADF1E:
        d = dis_at("a", x)
        n_i, x = n_i + 1, x + d[0]
    bad += check("I1 Dev7F_WriteAllFourSlots, 0xFADF0D up to 0xFADF1E: "
                 "instructions", n_i, 5)
    bad += check("I1 ...and the extent ends exactly on the next entry point",
                 "0x%06X" % x, "0xFADF1E")
    n_i, x = 0, 0xFADA20
    while x < 0xFADA26:
        d = dis_at("a", x)
        n_i, x = n_i + 1, x + d[0]
    bad += check("I2 OrdinalToBitMask6's six DATA bytes render as this many "
                 "instruction lines", n_i, 4)
    bad += check("I2 ...and they are these", [dis_at("a", a)[1] for a in
                                              (0xFADA20, 0xFADA21, 0xFADA22, 0xFADA23)],
                 ["normal", "push SR", "max", "ld (0x10),0x20"])

    print("TW. the one byte-identical twin, and the lever behind it")
    xa = rom("a")[0xFBA10D - A_BASE:0xFBA10D - A_BASE + 38]
    xc = rom("c")[0xFCB11B - A_BASE:0xFCB11B - A_BASE + 38]
    bad += check("TW1 prom_a 0xFBA10D vs prom_c 0xFCB11B: length, differing count",
                 (len(xa), sum(1 for i in range(38) if xa[i] != xc[i])), (38, 0))
    bad += check("TW1 ...and both really end in `retd 0x0008`, in their OWN image",
                 (dis_at("a", 0xFBA10D + 35)[1], dis_at("c", 0xFCB11B + 35)[1]),
                 ("retd 0x0008", "retd 0x0008"))
    tw = twins()
    # ⚠ an INVARIANT, not a pin: before --apply the prom_c side yields exactly
    # this one routine and afterwards it yields none, because the routine is no
    # longer a sub_XXXXXX.  Both states are correct; two or more would not be.
    bad += check("TW1 ...and the whole lever yields at most that one routine, "
                 "in either direction",
                 (len(tw["a"]), len(tw["c"]) <= 1), (0, True))

    print("Y. the two 0x2C00 drains")
    da_ = rom("a")
    x = list(da_[0xF823AC - A_BASE:0xF823AC - A_BASE + 28])
    y = list(da_[0xF823C8 - A_BASE:0xF823C8 - A_BASE + 24])
    bad += check("Y1 both really end in `ret`", (x[-1], y[-1]), (0x0E, 0x0E))
    bad += check("Y1 the four bytes 0xF823AC+7 are `call 0xf40f5c`",
                 ["0x%02x" % b for b in x[7:11]], ["0x1d", "0x5c", "0x0f", "0xf4"])
    xr = x[:7] + x[11:]
    bad += check("Y1 with those four removed the two are the same length",
                 (len(xr), len(y)), (24, 24))
    diffs = [i for i in range(24) if xr[i] != y[i]]
    bad += check("Y1 ...and differ in exactly ONE byte, the jr displacement",
                 diffs, [6])
    bad += check("Y1 ...whose two values differ by the four removed bytes",
                 (xr[6], y[6], xr[6] - y[6]), (0x14, 0x10, 4))

    print("Z. every instruction this pass cites, decoded AT the cited address")
    cite = re.compile(r'`([^`]+)`\s+at\s+0x([0-9A-F]{6})')
    MNEM = re.compile(r'^[a-z][a-z0-9_]*(?:\s|$)')
    allh = ([(a, o, n, h) for a, o, n, h in RENAMES]
            + [(a, None, n, h) for a, n, h in INSERTS]
            + [(a, n, n, h) for n, a, h in HEADER_UPGRADES]
            + part_ptr_renames() + change_record_renames() + cc_word_renames()
            + dispatch_arm_headers())
    seen_c, wrong, checked = set(), [], 0
    for _a, _o, _n, h in allh:
        for l in h:
            for m in cite.finditer(l):
                txt, ad = m.group(1), int(m.group(2), 16)
                if not MNEM.match(txt):       # an ASCII string, not an instruction
                    continue
                if (txt, ad) in seen_c:
                    continue
                seen_c.add((txt, ad))
                # `A / B` cites two CONSECUTIVE instructions from one address
                want, x = txt.split(" / "), ad
                for w in want:
                    d = dis_at("a", x)
                    checked += 1
                    if d is None or d[1] != w:
                        wrong.append("0x%06X cited `%s`, decodes `%s`"
                                     % (x, w, d[1] if d else "??"))
                        break
                    x += d[0]
    bad += check("Z1 citations of the form `text` at 0xADDR that do NOT decode "
                 "to that text at that address (%d checked)" % checked, wrong, [])
    bad += check("Z1 ...and the count is not zero, i.e. the check can fail",
                 checked > 40, True)

    print("V. the MIDI status-byte builders, which is what names 0xB1")
    d0 = rom("a")
    ors = [(0xF80000 + i, d0[i + 2]) for i in range(0xFA7600 - A_BASE, 0xFA7C00 - A_BASE)
           if d0[i] == 0xC9 and d0[i + 1] == 0xCE]
    bad += check("V1 `or A,0xNN` instructions in 0xFA7600-0xFA7C00",
                 ["0x%06X or A,0x%02X" % x for x in ors],
                 ["0xFA7612 or A,0xC0", "0xFA7706 or A,0xE0", "0xFA7882 or A,0xD0"])
    bad += check("V1 ...0xFA7706 is preceded by `and A,0x0f`, i.e. a channel",
                 dis_at("a", 0xFA7703)[1], "and A,0x0f")
    bad += check("V1 ...and the message length set just before it is three bytes",
                 dis_at("a", 0xFA76F5)[1], "ld DE,0x0300")
    bad += check("V1 MidiOut_ParamNumberTable[0xB1] is the routine that reaches it",
                 "0x%06X" % w32("a", 0xFA8CC8 + 4 * 0xB1), "0xFA767E")
    bad += check("V1 ...and its change record's value bytes are the bend centre",
                 "0x%04X" % int.from_bytes(by("a", 0xFA8196 + 10, 2), "little"),
                 "0x4000")

    print("W. the instrument's own controller words")
    cn = controller_names()
    bad += check("W1 controller names extracted from the two ASCII lists",
                 sorted(cn), [1, 2, 4, 11, 16, 17, 18, 19, 64])
    bad += check("W1 ...the FIRST and the LAST, read from the ROM",
                 (cn[1], cn[64]), ("MODULATION1", "HOLD"))
    for cc, old_w, new_w, num, sa in CC_WORDS:
        txt = by("a", sa, 16).decode("ascii", "replace")
        bad += check("W1 #%d's string at 0x%06X names controller %d" % (num, sa, num),
                     int(CTRL_NUM.search(txt).group(1)), num)
    for w in (b"BREATH", b"GENERAL", b"DAMPER"):
        tot = sum(rom(i).count(w) for i in "abcd")
        bad += check("W2 `%s` occurs this many times in ALL FOUR images"
                     % w.decode(), tot, {b"BREATH": 0, b"GENERAL": 23,
                                         b"DAMPER": 0}[w])
    bad += check("W2 ...and `GENERAL`'s 23 are all in prom_b, none in prom_a",
                 (rom("a").count(b"GENERAL"), rom("b").count(b"GENERAL")), (0, 23))
    for w in (b"MODULATION", b"EXPRESSION", b"HOLD", b"CTRL.PEDAL", b"R.T.CREAT",
              b"R.T.CTRL"):
        bad += check("W2 ...while `%s` IS in prom_a" % w.decode(),
                     rom("a").count(w) > 0, True)

    print("R. the two generated rename families")
    # ⚠ Derived from the ROM, not from the label names, so the check survives
    # its own --apply: the 25 blocks are 128 bytes apart from 0xFA8FF8.
    nm_a, owners = name_at("a"), []
    starts = sorted(set(a for _n, a in labels("a")))
    for k in range(25):
        blk = 0xFA8FF8 + 0x80 * k
        hits = table_readers(blk)
        if len(hits) != 1:
            owners.append(None)
            continue
        a = hits[0] - 1
        j = 0
        for x in starts:
            if x <= a:
                j = x
            else:
                break
        o = [n for n in nm_a.get(j, []) if not UNNAMED.match(n)]
        owners.append(o[0] if o else None)
    shared = collections.Counter(o for o in owners if o)
    ok11 = [k for k, o in enumerate(owners) if o and shared[o] == 1]
    bad += check("R1 the 25 PartRecordPtrs blocks are 128 bytes apart from "
                 "0xFA8FF8", "0x%06X" % (0xFA8FF8 + 0x80 * 24), "0xFA9BF8")
    bad += check("R1 ...blocks with exactly ONE reader in a named, unshared "
                 "routine", len(ok11), 11)
    bad += check("R1 ...the first and the LAST of those eleven",
                 (ok11[0], ok11[-1]), (1, 24))
    bad += check("R1 ...block 0 is excluded because FIVE routines read it",
                 len(table_readers(0xFA8FF8)), 5)
    bad += check("R1 ...blocks 16 and 17 are excluded because ONE routine reads "
                 "both", owners[16] == owners[17] and owners[16] is not None, True)
    cr = [k for k in range(11)
          if [n for n in nm_a.get(int.from_bytes(
              by("a", 0xFA812A + 12 * k + 4, 4), "little"), [])
              if not UNNAMED.match(n)]]
    bad += check("R2 ChangeRecords whose own [4:8] handler has a name",
                 len(cr), 9)
    ids = sorted(int.from_bytes(by("a", 0xFA812A + 12 * k + 8, 2), "little")
                 for k in range(11))
    bad += check("R2 ...and the eleven records' parameter numbers are exactly the "
                 "eleven forwarders",
                 ["0x%02X" % (x & 0xFF) for x in ids],
                 ["0x%02X" % x for x in sorted(t["hnd"] - t["rec"])])
    tbl = 0xFA8CC8
    agree = [k for k in range(11)
             if int.from_bytes(by("a", 0xFA812A + 12 * k + 4, 4), "little")
             == w32("a", tbl + 4 * (int.from_bytes(
                 by("a", 0xFA812A + 12 * k + 8, 2), "little") & 0xFF))]
    bad += check("R2 ...and for ALL ELEVEN the record's handler equals "
                 "MidiOut_ParamNumberTable[its parameter number]",
                 len(agree), 11)

    print("X. the old text this pass corrects")
    txt = open(SRC["a"], encoding="utf-8").read()
    bad += check("X1 the old Lookup32_By_Arg8 header is either still there or "
                 "replaced, never doubled", txt.count(OLD_HEADER_MARK) <= 1, True)
    todo, done = prose_state()
    bad += check("X2 every prose fix is either pending or made, exactly once "
                 "each, never both", sorted(todo + done), list(range(len(PROSE_FIXES))))
    bad += check("X2 ...and no fix is both pending and made",
                 sorted(set(todo) & set(done)), [])

    print("P. the plan")
    p = plan()
    la = labels("a")
    have = set(n for n, _a in la)
    ren = [x for x in p if x[1] is not None and x[1] != x[2]]
    ins = [x for x in p if x[1] is None]
    dup = collections.Counter(n for _a, _o, n, _h in ren + ins)
    bad += check("P1 new names that already exist in prom_a",
                 sorted(set(n for _a, _o, n, _h in ren + ins) & have), [])
    bad += check("P2 duplicate new names", [n for n, c in dup.items() if c > 1], [])
    bad += check("P3 every renamed address really carries that label today",
                 ["0x%06X" % a for a, o, _n, _h in ren
                  if a is not None and o not in labels_at(a)], [])
    bad += check("P4 every header carries an Evidence:/Called from:/★/Read by: line",
                 [n for _a, _o, n, h in p if not _hdr_ok(h)], [])
    bad += check("P5 no entry the plan treats as an INSERT lands on an address "
                 "that already has a label",
                 ["0x%06X" % a for a, o, _n, _h in p if o is None and labels_at(a)],
                 [])
    print("\n%d checks, %d failures" % (_RUN[0], bad))
    return 1 if bad else 0


# --------------------------------------------------------------------- report
def show_map():
    lmap, mism, fin = region_map()
    print("prom_a 0x%06X-0x%06X: %d source lines mapped to an address."
          % (LO, HI, len(lmap)))
    print("mismatches against banners, labels and address comments: %d" % len(mism))
    for m in mism[:20]:
        print("   line %d  %s: walker says %s, source says %s" % m)
    print("the walk ends at 0x%06X (region end 0x%06X)" % (fin, HI))
    return 0 if (not mism and fin == HI) else 1


def report():
    print("prom_a's 0x%06X module -- what it is.\n" % LO)
    print("It is the PARAMETER-APPLY layer.  A parameter change is four bytes --")
    print("  {parameter number, field offset, value, mask} -- and it travels three ways:")
    print("    * applied now      : ParamRecord_WriteFieldAndStage writes the masked")
    print("                         bits into ParamNumber_RecordPtrs[number] + offset")
    print("                         and stages the record at (0x60F080..0x60F083);")
    print("    * published        : Queue2C00_PublishStagedIfPending appends the")
    print("                         staged record to the 0x2C00 queue;")
    print("    * deferred         : the four ParamShadow_Set* entries write a shadow")
    print("                         byte with bit 7 as a pending flag, and")
    print("                         ParamShadow_FlushAll publishes them later.")
    print("  Evt2030_RunList reads the same four-byte records back out of the 0x2030")
    print("  list and dispatches each through Evt2030_ClassHandlers.\n")
    show_slots()
    print()
    show_table()
    return 0


def main():
    if "--map" in ARGV:
        return show_map()
    if "--slots" in ARGV:
        return show_slots()
    if "--table" in ARGV:
        return show_table()
    if "--tables" in ARGV:
        return show_tables()
    if "--controllers" in ARGV:
        return show_controllers()
    if "--twins" in ARGV:
        return show_twins()
    if "--plan" in ARGV:
        return show_plan()
    if "--gaps" in ARGV:
        return show_gaps()
    if "--apply" in ARGV:
        return apply()
    if "--selftest" in ARGV:
        return selftest()
    return report()


if __name__ == "__main__":
    sys.exit(main())
