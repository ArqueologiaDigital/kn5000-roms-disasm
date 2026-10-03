"""prom_a round 7: THE CENSUS OF ALL 2,923 `sub_XXXXXX`, and the one call shape
rounds 5 and 6 were structurally blind to.

QUESTION IT ANSWERS
    "prom_a has moved 30.1 -> 30.9 -> 31.4 over three rounds and holds the
     largest block of unnamed routines in the tree.  Which of the 2,923 CAN be
     named, by what, and -- the part no image in this tree has -- which ones
     CANNOT, with the reason, counted?"

★★ THE HEADLINE: 73% OF prom_a's UNNAMED ROUTINES HAVE NOTHING TO NAME THEM
    FROM.  2,144 of the 2,923 at round 7's barrier (73.3%); 2,122 of the 2,898
    left after this round's 25 names (73.2%) when this docstring was written.
    ⚠ QUOTE THE RATIO, NOT THE COUNT: the count falls whenever another lane
    converts a prom_b span and reveals a caller, and --census prints the live
    pair.  The ratio has not moved.
    `--census` puts every one of the 2,923 in exactly one bucket and `--nameless`
    lists the terminal one.  A routine lands there when ALL FOUR hold: its body
    is none of the seven recognised shapes (no display list, no SWI7, not a
    stub, not a forwarder); it loads the start address of no CONTENT-named
    object in either image; no caller -- direct OR through prom_b's directory --
    carries a content name; so nothing in either image says what it is for.
    That is the CEILING of this image under every mechanism this tree owns, and
    it is the number the next round should plan against instead of re-searching
    ground six rounds have already searched.

★ AND THE ONE NUMBER THAT EXPLAINS IT.  Across every reference to every one of
    them, FEWER THAN EIGHTY distinct content-named labels appear as a caller at
    all, out of roughly 2,400 distinct caller labels -- 64 of 2,420 at the
    barrier, 78 of 2,406 after this round's names and another lane's prom_b
    work.  The call graph above these routines is sub_XXXXXX calling
    sub_XXXXXX.  There is no named neighbourhood to inherit from, and that is
    the mechanical reason "name it from its caller" does not scale here.
    ⚠ NOT CLAIMED: how many names earlier rounds got from callers.  This file
      did not measure that and does not guess it.

────────────────────────────────────────────────────────────────────────────────
THE CENSUS -- both axes, measured at round 7's barrier
────────────────────────────────────────────────────────────────────────────────
    BY WHAT THE BODY IS (first match wins, in this order)
        283  one-byte object that is a single 0x0E `ret`     (round 6's 283)
         53  returns immediately, extent longer than a byte   (283+53 = round 6's 336)
         67  ★ pushes a display list ON THE STACK -- this round's lever
         80  runs a display list in the XIY/XIX register form (rounds 5-6's)
         40  issues SWI7, the graphics service                (round 6's lever)
        119  a forwarder: one call/calr and a `ret`
          9  a bare tail jump
      2,272  none of the above
    BY WHAT REACHES IT (`calr` resolved, AND the hop through the directory)
        301  no reference in EITHER listing
        685  published by a prom_b thunk slot nothing in either listing calls
        134  published by a slot that IS called
      1,803  called or pointed at directly
    ⚠ The last two columns fall as other lanes convert prom_b spans -- converting
      can only REVEAL a caller -- so --selftest checks them as CEILINGS and
      prints the current value.  They were 300/672 an hour later.

★ A CORRECTION TO A COMMITTED NUMBER.  Round 6 published "302 reached by
    nothing".  It is 301.  `sub_FADF08` is published as prom_b slot
    `T_F40894: jp 0xFADF08` and called from prom_a 0xF82071, and an
    address-keyed census cannot see it because its label carries NO ADDRESS in
    the listing -- it is one of 61 labels inside gen_prom_a_fad800_module.py's
    range, whose emitter prints no address column.  Every count in this file
    therefore takes a routine's address from its LABEL, and --selftest checks
    that the label and the listing agree on all 2,862 where the listing has one.

★ AND IS AN UNREFERENCED ROUTINE DEAD, OR IS ITS CALLER MERELY UNCONVERTED?
    --unreached answers it, because "no reference" without that split is not an
    answer.  Of the 300, THIRTY-TWO have an opcode-anchored candidate reference
    (`1D <a24>`, `1B <a24>`, or an LE32 pointer slot) inside the 115 KB of
    `.incbin` still left in the two listings, and 268 have none anywhere in
    either ROM image.  Those 268 are the floor.
    ⚠ The scan is at every byte offset, so it is an UPPER bound on candidates,
      never a call count; it can only say "a caller could still turn up here".

────────────────────────────────────────────────────────────────────────────────
★★ THE LEVER THAT PAID: DISPLAY LISTS PASSED ON THE STACK
────────────────────────────────────────────────────────────────────────────────
    Rounds 5 and 6 named painters by looking for ONE shape --
    `ld XIY,<start> / ld XIX,<end> / call 0xF417F0`.  A display list can also be
    run with its two ends PUSHED (notes/prom_b_dl_stack_sites.py established six
    veneers for it; notes/prom_a_dl_stack_map.py proved the 12-byte push idiom
    frames 368 times out of 368 in the two images).  The register-form scan is
    blind to that shape, and the wave-7 briefing already warns that a region
    reached that way "scores 0 while being well-evidenced".

    Of the 368 idioms, 72 sit inside some prom_a routine's OWN body (scoped to
    its own `ret`, which is round 5's retraction fix), 67 of those routines were
    still `sub_XXXXXX`, and 31 draw a list carrying a real word.
        NAMED  24, every morpheme checked against that routine's own ROM text
        REFUSED 7, each with the reason written into the listing
        the other 36 draw only glyph/icon records with no `.ascii` at all --
        which is the correct answer for them, not a failure.

    ★ WHAT THE NAMES FOUND.  Four of them are the machine's SERVICE MODE:
      Paint_GateArrayCheck ("Please check with osciloscope / check point are
      P07."), Paint_PanelCpuCheck, Paint_SineWaveCheckMode and
      Paint_PanelSwLedCheck.  The rest are the MIDI configuration pages, the
      sound/combination/drum-map naming and WRITE screens, and the DISK
      load/save/format screens.  ⚠ CAREFULLY: gap V of
      notes/WSA1-EMULATION-DISASM-GAPS.md is "How does a user reach
      `Fdc_Request` at all?" -- these five routines are the PAINTERS of the
      screens on that path, which is a step toward that question and not an
      answer to it.
    ⚠ `Paint_` is a structural verb; everything after it is quoted firmware, and
      the ROM's own spelling is kept (`L0AD`, `MEM0RY`, `F0RMAT` are drawn with
      a zero, and --morphemes checks the name against the digits as written).

────────────────────────────────────────────────────────────────────────────────
★ THE SECOND LEVER, SMALL AND HONEST: A POINTER STRAIGHT AT ROM TEXT
────────────────────────────────────────────────────────────────────────────────
    The SWI7 text services take XIY = a character table, so a routine can hand
    text to the screen without a display list at all.  Rounds 5 and 6 only ever
    read text out of a display list.  26 routines outside the painter population
    load a pointer at a printable run of >= 5 bytes with >= 4 letters.
        NAMED 1 -- `Print_DebugMonitor`.  ★ prom_a contains a DEBUG MONITOR: the
        40 characters at 0xF94C67 read " --- DEBUG MONITOR BY (c)masa,toshi --- "
        and the routine zeroes the row cursor (0x284F) and calls
        LCD_PrintLine40_AdvanceRow, whose own header records BC = 0x28 = 40.
        The length is the proof, not the reader's eye.
        HEADERS on 20 more, quoting the exact string and its address; the other
        six already carry round 5's headers and are NOT overwritten, because
        clobbering another round's evidence to raise a header count is the trade
        this wave keeps catching.
    ⚠ NOT NAMED from the other 25, deliberately: what a routine READS is not
      what it DOES.  Among the strings now recorded in the listing are `MThd` /
      `MTrk` (the Standard MIDI File chunk magics, at 0xFBA169), the file
      extension list `.ALL.SEQ.CMB.SND.PNL.MDS.SRM.CRM.DRM`, the four tone-group
      name tables, `WSA1 EXTBD` and the `wsaa_822` tag at 0xFFFFF0.

────────────────────────────────────────────────────────────────────────────────
THE LEVERS THAT DID NOT PAY, WITH THEIR MEASURED REACH -- `--levers`
────────────────────────────────────────────────────────────────────────────────
    L1  a CONTENT-named prom_b thunk slot naming its prom_a target ...... 0
        Every named slot was named FROM its target's prom_a label (the slot
        headers say DERIVATIVE); the arrow only points the other way.
    L2  a routine that touches a NAMED SFR by symbol .................... 0
        All 23 SFR-symbol operands in prom_a are inside RESET, already named.
    L3  a forwarder whose target is CONTENT-named ...................... 14 of 119
        NOT TAKEN: `Veneer_<target>` restates the target and adds no fact.
    L4  a FRAMED label promoted from its unique CONTENT-named reader ..... 4
        And all four already say what they are, so the real reach is 0.  Of
        prom_a's 253 framed labels, 73 have NO reader site at all and 159 have
        exactly one reader which is itself `sub_XXXXXX`.
        ⚠ 253 is the goal metric's own count.  This file grades a label with
          EXACTLY notes/wave7_documentation_metrics.py's test and nothing
          stricter -- its first draft also rejected a structural KIND prefix,
          which graded `sub_FA64E5_ParamTable` framed and put every number here
          two out of step with the metric it is supposed to move.
    L5  ⚠ ROUND 6 CALLED THE `Ring_*` FAMILY "THE CHEAPEST PROMOTION IN THE
        IMAGE".  THIS ROUND DECLINES IT AND SAYS WHY.  The suffix of
        `Ring_Get_0080` IS the capacity -- it wraps with `minc1_16 ix,0x007f` at
        0xF84014, `Ring_Get_0100` with 0x00ff at 0xF84033 -- and the listing
        already states all five masks in a table above the family.  Re-spelling
        `_0080` as `_Cap0080` would move prom_a's LOWER bound +0.54 points while
        changing NOTHING that is known about the objects.  That is the
        +35-headers-that-were-really-removed-blank-lines trade a round-3
        reviewer caught, moved into the label column.
    L6  widening the stack idiom to ANY register pair .................... 0
        The general form finds 111 sites beyond the exact XBC/XWA one; 3 frame;
        0 of those carry a caption.  The narrow scan is CORRECT, not narrow.

────────────────────────────────────────────────────────────────────────────────
WHAT THIS FILE DOES NOT CLAIM
────────────────────────────────────────────────────────────────────────────────
    * A `Paint_` name claims the routine draws that screen's lists.  It says
      nothing about input handling, and nothing about whether another routine
      paints the same screen.  Both are written into every header as Unknown.
    * The census's "nothing to name them from" is a statement about THIS TREE'S
      evidence, not about the machine.  A converted prom_b span, a schematic or
      Felipe at the keyboard could name any of them tomorrow.
    * `--unreached`'s byte scan is an upper bound on candidate references, not a
      call count; it is scanned at every byte offset, not at instruction
      boundaries.
    * 0xF94C67-0xF94C8E is TEXT that the listing still decodes as instructions.
      The bytes are right and the gate is green either way; the data/code split
      there is left for a round that owns it.

WHAT IT MOVED, notes/wave7_documentation_metrics.py before and after

        prom_a   content  framed  sub_XXXX   LOWER   UPPER   headers  evidence
        before     1,456     253     2,923   31.4%   36.9%     1,108     1,200
        after      1,481     253     2,898   32.0%   37.4%     1,159     1,251

    25 renames, all `sub_XXXXXX` -> content, 0 framed -> content (L4 says why),
    and 51 header blocks, every one newly written prose: 24 for the names, 7
    stating a refusal, 20 recording a string.  0 bytes converted -- this round
    named and classified, it did not convert, so it added no `sub_XXXXXX` of its
    own.

RUN
    python3 notes/prom_a_understanding_round7.py --census      # all 2,923, bucketed
    python3 notes/prom_a_understanding_round7.py --nameless    # the terminal bucket
    python3 notes/prom_a_understanding_round7.py --unreached   # dead, or unconverted?
    python3 notes/prom_a_understanding_round7.py --painters    # the lever, with refusals
    python3 notes/prom_a_understanding_round7.py --strings     # the second lever
    python3 notes/prom_a_understanding_round7.py --morphemes   # the invented-word guard
    python3 notes/prom_a_understanding_round7.py --levers      # every reach, including 0
    python3 notes/prom_a_understanding_round7.py --stale       # old spellings elsewhere
    python3 notes/prom_a_understanding_round7.py --apply       # 24 names + 31 headers
    python3 notes/prom_a_understanding_round7.py --apply-strings  # 1 name + 20 headers
    python3 notes/prom_a_understanding_round7.py --verify
    python3 notes/prom_a_understanding_round7.py --selftest    # 38 checks
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_a_understanding_round6 as R6          # noqa: E402  Image/body/references
import prom_a_dl_stack_map as SM                  # noqa: E402  the 12-byte idiom
import wave7_documentation_metrics as MET         # noqa: E402  the FRAMED grader

# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
S_A_MASTER = os.path.join(ROOT, "prom_a/wsa1_prom_a.s")   # the WRITE path: write_part() guards it
S_A = image_path(ROOT, "prom_a/wsa1_prom_a.s")  # the READ path: the image, not the master
RULE = "; ---------------------------------------------------------------------"

# The six stack veneers (notes/prom_b_dl_stack_sites.py) and the prom_b thunk
# slots that reach the first four of them.
VENEERS = {0xF31800, 0xF31814, 0xF31828, 0xF3183D, 0xFF75D3, 0xFF75EF}
VENEER_SLOTS = {0xF42E00, 0xF42E04, 0xF42E08, 0xF42E0C}
REG_INTERP = {0xF417F0, 0xF417F4}                 # the form rounds 5-6 scanned
HEX6 = re.compile(r'0x([0-9a-fA-F]{6,8})')

OK = FAIL = 0


def check(label, got, want):
    global OK, FAIL
    if got == want:
        OK += 1
        print("  ok    %-66s %r" % (label, got))
    else:
        FAIL += 1
        print("  FAIL  %-66s got %r want %r" % (label, got, want))


# ===========================================================================
# 1. the population, and the addresses of it
# ===========================================================================
_C = {}


def subs():
    """Every `sub_XXXXXX` label in prom_a, in listing order."""
    A, _B = R6.images()
    if "subs" not in _C:
        _C["subs"] = [n for n in A.order if R6.SUB.match(n)]
    return _C["subs"]


def sub_addr(name):
    """★ The address comes from the LABEL, not from the listing.

    61 of the 2,923 carry no address comment at all -- they are inside
    gen_prom_a_fad800_module.py's range, whose emitter prints instructions
    without the `; ADDR bytes` column.  A census that reads the address out of
    the listing silently drops those 61.  --selftest checks that the label name
    and the listing agree on all 2,862 where the listing has one.
    """
    return int(name[4:], 16)


def extent_ends():
    """name -> the address of the NEXT LOCATABLE top label.

    Not "the next top label": 20 top labels carry no address anywhere (their
    emitter prints no address column and their name is not `sub_XXXXXX`), and a
    rule that stops at one of those returns None and silently drops the object
    from every extent-based count.  So the end is the next address in the sorted
    set of top-label addresses, which is defined for all but the last label.
    """
    if "ends" in _C:
        return _C["ends"]
    A, _B = R6.images()
    known = {}
    for k, (li, nm) in enumerate(A.tops):
        if R6.SUB.match(nm):
            known[nm] = sub_addr(nm)
        else:
            ea = A.routines[nm][2]
            if ea is None:
                for q in range(li, min(li + 12, len(A.lines))):
                    if A.addr[q] is not None:
                        ea = A.addr[q]
                        break
            if ea is not None:
                known[nm] = ea
    order = sorted(set(known.values()))
    out = {}
    for nm, a in known.items():
        i = order.index(a) if False else None
        out[nm] = a
    # one pass with bisect instead of index()
    import bisect
    for nm, a in known.items():
        j = bisect.bisect_right(order, a)
        out[nm] = order[j] if j < len(order) else None
    _C["ends"] = out
    return out


def content_objects():
    """address -> label, for every label in either image that is CONTENT.

    The grade is wave7_documentation_metrics.py's own, so "named" here means
    exactly what the goal metric means by it and not something looser.
    """
    if "cobj" in _C:
        return _C["cobj"]
    A, B = R6.images()
    out = {}
    for img in (A, B):
        for n in img.order:
            ea = img.routines[n][2]
            if ea is None and R6.SUB.match(n):
                ea = sub_addr(n) if img is A else None
            if ea is None or not is_content(n):
                continue
            out.setdefault(ea, n)
    _C["cobj"] = out
    return out


def is_content(name):
    """CONTENT by wave7_documentation_metrics.py's grade: not sub_, not an
    internal branch target, and not a structural KIND plus an address."""
    if not name or R6.SUB.match(name) or R6.INTERNAL.match(name) or name.startswith(".L"):
        return False
    # ⚠ EXACTLY the metric's own test, and nothing stricter.  The first draft of
    # this file ALSO rejected a structural KIND prefix (the metric defines
    # FRAMED_KIND but does not use it in the classification), which graded
    # `sub_FA64E5_ParamTable` and `sub_FA6526_ParamTable` as framed and made
    # every count here disagree with the goal metric by two.  A census that uses
    # its own grade is measuring its own opinion.
    return not MET.FRAMED.match(name)


# ===========================================================================
# 2. who reaches a routine -- INCLUDING THE HOP THROUGH prom_b's DIRECTORY
# ===========================================================================
def thunk_slots():
    """prom_b thunk slot address -> (target address, slot label)."""
    if "slots" in _C:
        return _C["slots"]
    _A, B = R6.images()
    TH = re.compile(r'^(T_[A-Za-z0-9_]+):\s*jp\s+0x([0-9A-Fa-f]{6})\b')
    WAS = re.compile(r'\(was T_([0-9A-F]{6})\)')
    out = {}
    for ln in B.lines:
        m = TH.match(ln)
        if not m:
            continue
        nm, tgt = m.group(1), int(m.group(2), 16)
        w = WAS.search(ln)
        sa = int(w.group(1), 16) if w else (
            int(nm[2:], 16) if re.match(r'^T_[0-9A-F]{6}$', nm) else None)
        if sa is not None:
            out[sa] = (tgt, nm)
    _C["slots"] = out
    return out


def indirect_refs():
    """★ THE HOP ROUND 6'S CENSUS DOES NOT TAKE.

    prom_b's thunk table is CPU 1's routine directory: a caller calls a SLOT and
    the slot `jp`s to the routine.  R6.references() records the slot's own `jp`
    as the routine's reference and stops, so a routine reached only that way
    looks published-but-never-called.  This resolves the second hop: every
    `call`/`jp`/`jrl` whose operand is a thunk slot is credited to the routine
    the slot names, with the CALLER's own label kept.
    """
    if "ind" in _C:
        return _C["ind"]
    A, B = R6.images()
    slots = thunk_slots()
    by_addr = {}
    for n in A.order:
        ea = A.routines[n][2] if not R6.SUB.match(n) else sub_addr(n)
        if ea is not None:
            by_addr.setdefault(ea, n)
    out = collections.defaultdict(list)
    for img in (A, B):
        cur = None
        for i, ln in enumerate(img.lines):
            m = R6.TOPLABEL.match(ln)
            if m:
                cur = m.group(1)
            mh = R6.CALLHEX.match(ln)
            if not mh:
                continue
            kind, v = mh.group(1), int(mh.group(2), 16)
            if kind in ("call", "jp", "jrl") and v in slots:
                t = slots[v][0]
                if t in by_addr:
                    out[by_addr[t]].append((img.tag, img.addr[i], cur, kind, slots[v][1]))
    _C["ind"] = dict(out)
    return _C["ind"]


def ref_class():
    """name -> one of none / dir_only / dir_called / direct, for every sub_."""
    if "rc" in _C:
        return _C["rc"]
    refs, _c = R6.references()
    ind = indirect_refs()
    out = {}
    for n in subs():
        d = refs.get(n, [])
        i = ind.get(n, [])
        directory = [x for x in d if x[3] == "jp" and x[0] == "prom_b"]
        other = [x for x in d if x not in directory]
        if not d and not i:
            out[n] = "none"
        elif other:
            out[n] = "direct"
        elif i:
            out[n] = "dir_called"
        else:
            out[n] = "dir_only"
    _C["rc"] = out
    return out


# ===========================================================================
# 3. the lever: display lists passed to the interpreter ON THE STACK
# ===========================================================================
def idiom_index():
    if "idm" not in _C:
        _C["idm"] = {a: (s, e) for a, s, e in SM.idioms()}
    return _C["idm"]


def list_strings(s, e):
    """The printable-ASCII runs of >= 3 characters inside a display list."""
    d, b = SM.img(s)
    if d is None:
        return []
    out, cur = [], b""
    for c in bytes(d[s - b:e - b]):
        if 0x20 <= c < 0x7F:
            cur += bytes([c])
        else:
            if len(cur) >= 3:
                out.append(cur.decode())
            cur = b""
    if len(cur) >= 3:
        out.append(cur.decode())
    return out


def painters():
    """label -> [(site, start, end, how it leaves, [captions])] for every
    routine whose OWN body pushes a display list on the stack.

    ★ SCOPED TO THE ROUTINE'S OWN `ret` (R6.body), not label-to-label.  Round 5
    retracted two painter names that were scoped label-to-label and so credited
    a later, unlabelled routine's list to an earlier label.
    """
    if "pnt" in _C:
        return _C["pnt"]
    A, _B = R6.images()
    idm = idiom_index()
    out = collections.OrderedDict()
    for n in A.order:
        rows = []
        b = R6.body(A, n)
        for k, (a, _mn, _txt, _j) in enumerate(b):
            if a not in idm:
                continue
            s, e = idm[a]
            how = "?"
            for x in b[k + 3:k + 9]:
                t = x[2]
                m = re.match(r'call\s+(?:0x([0-9a-f]+)|([A-Za-z_][A-Za-z0-9_]*))', t)
                if m:
                    if m.group(1):
                        v = int(m.group(1), 16)
                    else:
                        nm2 = m.group(2)
                        v = sub_addr(nm2) if R6.SUB.match(nm2) else \
                            A.routines.get(nm2, (0, 0, None))[2]
                    how = "call" if (v in VENEER_SLOTS or v in VENEERS) else "call?"
                    break
                if t.startswith("jp (xix)"):
                    how = "jp(XIX)"
                    break
                if t.startswith("jr"):
                    how = "jr"
                    break
            rows.append((a, s, e, how, list_strings(s, e)))
        if rows:
            out[n] = rows
    _C["pnt"] = out
    return out


def camel(caption):
    """The ROM's caption as one CamelCase run, KEEPING ITS SPELLING.

    The firmware's font draws capital O as `0` in some lists and as `O` in
    others, so `L0ad` and `Load` are both literal.  --morphemes is what keeps
    them literal.
    """
    toks = [t for t in re.split(r'[^0-9A-Za-z]+', caption) if t]
    return "".join(t[0].upper() + t[1:].lower() for t in toks)


def alpha_run(tok):
    return max([len(x) for x in re.findall(r'[A-Za-z]+', tok)] or [0])


def usable(caption):
    """A caption names a screen only if it carries a real word.

    ⚠ This is what REFUSES the glyph lists.  Half of these lists draw icons, and
    a run like `@) P) `) p)` is printable ASCII without being text.  The bar is
    one token with >= 3 consecutive letters.
    """
    return alpha_run(caption) >= 3


def current_label(old):
    """`old` if --apply has not run, otherwise the name it now carries.

    ★ Without this every count in --selftest would FALL the moment --apply ran,
    which is a check that punishes the work it is meant to certify.  The trap is
    documented in notes/wave7_documentation_metrics.py's own selftest and round
    6 hit it first.
    """
    A, _B = R6.images()
    if old in A.routines:
        return old
    for o, n, _w in NAMES:
        if o == old:
            return n
    return old


def painter_population():
    """Every painter this round is allowed to speak about: still sub_XXXXXX, or
    renamed by THIS round.  Constant across --apply."""
    new = {n for _o, n, _w in NAMES}
    return [n for n in painters() if R6.SUB.match(n) or n in new]


def candidates():
    """The MECHANICAL candidate set: painters with a usable caption.

    A name is CURATED from this set (see NAMES) rather than generated from it,
    because a mechanical rule picks the first caption and the first caption is
    sometimes a field label and not the screen title.  --selftest asserts every
    curated name comes from a routine that is IN this set and that every one of
    its morphemes is in that routine's own captions.
    """
    out = collections.OrderedDict()
    pop = set(painter_population())
    for n, lists in painters().items():
        if n not in pop:
            continue
        caps = [c for _a, _s, _e, _h, cs in lists for c in cs]
        if any(usable(c) for c in caps):
            out[n] = (lists, caps)
    return out


def morphemes(new, caps):
    """Round 5's guard: EVERY morpheme of a proposed name must occur VERBATIM in
    the ROM text that named it.  Round 3 of this wave invented the morpheme
    "Home", which occurs zero times in all four images; this is what makes that
    impossible.  `Paint_` is a structural verb and is exempt.
    ⚠ Digits are NOT stripped: the ROM writes `L0AD` and `MEM0RY`, so `L0ad` is
    checked as `l0ad` and fails if the ROM spells it `LOAD`.
    """
    body = new.split("_", 1)[1]
    text = " ".join(caps).lower()
    return [m for m in re.findall(r'[A-Z0-9]?[a-z0-9]+', body)
            if m.lower() not in text]


# ===========================================================================
# 4. THE NAMES -- curated from candidates(), every morpheme checked
# ===========================================================================
# (old label, new label, what the header's first line says)
NAMES = [
    ("sub_F95734", "Paint_GateArrayCheck",
     'paints the service screen whose own text reads "GATE ARRAY CHECK"'),
    ("sub_F95768", "Paint_PanelCpuCheck",
     'paints the service screen whose own text reads "PANEL CPU CHECK"'),
    ("sub_F95798", "Paint_SineWaveCheckMode",
     'paints the service screen whose own text reads "SINE WAVE CHECK" / "CHECK MODE"'),
    ("sub_F95990", "Paint_PanelSwLedCheck",
     'paints the service screen whose own text reads "PANEL SW&LED CHECK"'),
    ("sub_F9A1A8", "Paint_MidiTotalMode",
     'paints the screen whose own text reads "MIDI" / "TOTAL" / "MODE"'),
    ("sub_F9A6C0", "Paint_MidiRealtimeMessages",
     'paints the screen whose own text reads "REALTIME MESSAGES" / "MIDI"'),
    ("sub_F9A998", "Paint_MidiInputOutputFilter",
     'paints the screen whose own text reads "INPUT&OUTPUT" / "FILTER" / "MIDI"'),
    ("sub_F9AF61", "Paint_MidiOutProgramChange",
     'paints the screen whose own text reads "PROGRAM" / "CHANGE" / "MIDI" / "OUT"'),
    ("sub_F9C4FC", "Paint_ReMapEdit",
     'paints the screen whose own text reads "RE-MAP EDIT"'),
    ("sub_F9CDE4", "Paint_SoundGroupNaming",
     'paints the screen whose own text reads "SOUND GROUP NAMING"'),
    ("sub_F9CE1B", "Paint_SoundGroupNamingWrite",
     'paints the "SOUND GROUP NAMING" screen\'s "WRITE" state'),
    ("sub_F9D24C", "Paint_CombinationGroupNaming",
     'paints the screen whose own text reads "COMBINATION GROUP NAMING"'),
    ("sub_F9D283", "Paint_CombinationGroupNamingWrite",
     'paints the "COMBINATION GROUP NAMING" screen\'s "WRITE" state'),
    ("sub_F9F39C", "Paint_DrumsMapNaming",
     'paints the screen whose own text reads "DRUMS MAP" / "NAMING"'),
    ("sub_F9F3BC", "Paint_DrumsMapWrite",
     'paints the "DRUMS MAP" screen\'s "WRITE" state'),
    ("sub_F9F3D4", "Paint_ErrorImpossibleDrumMap",
     'paints the error box "It is impossible to set a drum map for a Sound '
     'other than a Drum Kit."'),
    ("sub_FBF0EE", "Paint_CombinationNaming",
     'paints the screen whose own text reads "COMBINATION NAMING" / "MEM0RY WRITE"'),
    ("sub_FBF2C2", "Paint_CombinationNamingWrite",
     'paints the "COMBINATION NAMING" screen\'s "WRITE" state'),
    ("sub_FF4408", "Paint_MidiFileDirectPlay",
     'paints the screen whose own text reads "MIDI FILE DIRECT PLAY"'),
    ("sub_FF4786", "Paint_DiskL0adFile",
     'paints the screen whose own text reads "L0AD FILE" / "L0AD 0PTI0N" over the '
     'FLOPPY DISK file list'),
    ("sub_FF4FFA", "Paint_MidiFileL0ad",
     'paints the screen whose own text reads "MIDI FILE L0AD"'),
    ("sub_FF557A", "Paint_DiskSaveFile",
     'paints the screen whose own text reads "SAVE FILE" / "SAVE 0PTI0N" over the '
     'FLOPPY DISK file list'),
    ("sub_FF6512", "Paint_FloppyDiskFormatSelectType",
     'paints the screen whose own text reads "FLOPPY DISK FORMAT" / "Select the '
     'F0RMAT type for your disk."'),
    ("sub_FF6613", "Paint_FloppyDiskFormatAreYouSure",
     'paints the "FLOPPY DISK FORMAT" confirmation whose own text reads '
     '"ATTENTION!" / "Are You Sure?"'),
]

# Painter-bucket routines this round REFUSES to name, and the reason each keeps
# `sub_XXXXXX`.  A refusal is a deliverable: it stops the next round paying for
# the same search.  Every one of these still gets a header quoting what it draws.
REFUSALS = {
    "sub_F99F24": "its list is the MIDI menu's INDEX of thirteen captions "
                  "(T0TAL M0DE, C0NFIGURE, PR0G CHANGE, MIDI 0UT, SYSEX BULK DUMP, "
                  "GENERAL MIDI, REALTIME MESSAGE, INPUT&0UTPUT FILTER); no one of "
                  "them names the routine, and naming it after any would claim a "
                  "screen that another routine paints",
    "sub_F9E519": "it draws seven lists spanning TWO screens -- SOUND COPY and "
                  "COMBINATION COPY -- plus the shared ATTENTI0N!/Are You Sure? box. "
                  "No single caption names the routine",
    "sub_FF42CD": "its list is the DISK menu's INDEX of seven captions (DISK L0AD, "
                  "DISK SAVE, MIDI FILE DIRECT PLAY, FL0PPY DISK F0RMAT); naming it "
                  "after one would claim a screen another routine paints",
    "sub_FF4ACB": "it and sub_FF4D5D draw the SAME caption set (FROM S0NG NUMBER, "
                  "TO S0NG NUMBER, 1-10) and nothing in their own lists tells the "
                  "two apart",
    "sub_FF4D5D": "it and sub_FF4ACB draw the SAME caption set (FROM S0NG NUMBER, "
                  "TO S0NG NUMBER, 1-10) and nothing in their own lists tells the "
                  "two apart",
    "sub_F9A724": "the only text it draws is `ON` / `OFF`, a two-state field and "
                  "not a screen",
    "sub_F9B2E2": "the caption belongs to its SECOND list; its first draws `---`, "
                  "so a name taken from the text would name the wrong list",
}


# ===========================================================================
# 5. THE CENSUS -- every one of the 2,923 in exactly one bucket
# ===========================================================================
SHAPES = [
    ("ret1", "a ONE-BYTE object that is a single 0x0E `ret`"),
    ("retimm", "returns immediately (body is one `ret`, extent is longer)"),
    ("dlstack", "pushes a display list ON THE STACK -- this round's lever"),
    ("dlreg", "runs a display list in the XIY/XIX register form"),
    ("swi7", "issues SWI7, the graphics service"),
    ("fwd", "a forwarder: one call/calr and a `ret`"),
    ("tail", "a bare tail jump"),
    ("plain", "none of the above"),
]
REFCLASS = [
    ("none", "no reference in EITHER listing"),
    ("dir_only", "published by a prom_b thunk slot; nothing in either listing "
                 "calls that slot"),
    ("dir_called", "published by a thunk slot that IS called"),
    ("direct", "called or pointed at directly"),
]


def census():
    """name -> (shape, ref class, {content objects it loads}, {swi numbers})."""
    if "cen" in _C:
        return _C["cen"]
    A, _B = R6.images()
    pnt = painters()
    cobj = content_objects()
    ends = extent_ends()
    rc = ref_class()
    out = {}
    for n in subs():
        b = R6.body(A, n)
        mns = [m for _a, m, _t, _j in b]
        named, swis, reg = set(), set(), False
        for _a, mn, txt, _j in b:
            if mn == "swi":
                m = re.search(r'swi\s+(\d)', txt)
                if m:
                    swis.add(int(m.group(1)))
            if mn in ("call", "calr", "jp", "jr", "jrl"):
                for h in HEX6.findall(txt):
                    if int(h, 16) & 0xFFFFFF in REG_INTERP:
                        reg = True
                continue
            for h in HEX6.findall(txt):
                o = cobj.get(int(h, 16) & 0xFFFFFF)
                if o:
                    named.add(o)
        if mns and mns[0] in R6.RETS and len(b) == 1:
            # ★ round 6's own criterion, so the two counts are comparable: the
            # whole listed extent holds exactly ONE instruction line.  (Address
            # arithmetic over the extent gives 282, not 283, because two of
            # these labels have no locatable successor; the line count is the
            # published number and is the one used here.)
            i, end, _ea = A.routines[n]
            k = sum(1 for j in range(i, end)
                    if not A.lines[j].startswith(";") and A.lines[j].strip()
                    and R6.MNEM.match(A.lines[j]))
            s = "ret1" if k == 1 else "retimm"
        elif n in pnt:
            s = "dlstack"
        elif reg:
            s = "dlreg"
        elif 7 in swis:
            s = "swi7"
        elif len(b) == 2 and mns[0] in ("call", "calr") and mns[1] in R6.RETS:
            s = "fwd"
        elif len(b) == 1 and mns[0] in ("jp", "jrl", "jr"):
            s = "tail"
        else:
            s = "plain"
        out[n] = (s, rc[n], named, swis)
    _C["cen"] = out
    return out


def nameless():
    """★ THE HONEST INVENTORY: the routines with NOTHING to name them from.

    A routine is in this bucket when ALL FOUR are true:
      * its body is none of the seven recognised shapes (no display list, no
        SWI7, not a stub, not a forwarder),
      * it loads the start address of no CONTENT-named object in either image,
      * no caller -- direct OR through prom_b's directory -- carries a content
        name,
      * so nothing in either image says what it is for.
    This is the ceiling: no mechanism in this tree reaches these without new
    evidence, and re-searching them is wasted rounds.
    """
    refs, _c = R6.references()
    ind = indirect_refs()
    out = []
    for n, (shape, rcl, named, swis) in census().items():
        if shape != "plain" or named or swis:
            continue
        callers = {c for _t, _s, c, _k in refs.get(n, [])}
        callers |= {c for _t, _s, c, _k, _sl in ind.get(n, [])}
        if any(is_content(c) for c in callers):
            continue
        out.append(n)
    return out


def mode_census():
    cen = census()
    print("prom_a `sub_XXXXXX` CENSUS -- %d routines, each in exactly one bucket"
          % len(cen))
    print("  (at round 7's barrier this population was %d; %d of them carry a"
          % (len(cen) + len(NAMES) + len(STRING_NAMES), len(NAMES) + len(STRING_NAMES)))
    print("   content name from THIS round and have left the count.)")
    print()
    print("BY WHAT THE BODY IS (first match wins, in this order):")
    sc = collections.Counter(v[0] for v in cen.values())
    for key, what in SHAPES:
        print("  %5d  %-9s %s" % (sc[key], key, what))
    print("  %5d  TOTAL" % sum(sc.values()))
    print()
    print("BY WHAT REACHES IT (`calr` resolved, AND the hop through prom_b's directory):")
    rc = collections.Counter(v[1] for v in cen.values())
    for key, what in REFCLASS:
        print("  %5d  %-11s %s" % (rc[key], key, what))
    print("  %5d  TOTAL" % sum(rc.values()))
    print()
    print("THE CROSS -- shape against reference class:")
    print("      %-9s %s" % ("", "".join("%12s" % k for k, _w in REFCLASS)))
    cross = collections.Counter((v[0], v[1]) for v in cen.values())
    for key, _w in SHAPES:
        print("      %-9s %s" % (key, "".join("%12d" % cross[(key, r)]
                                              for r, _w2 in REFCLASS)))
    print()
    nl = nameless()
    print("★ NOTHING TO NAME THEM FROM: %d of %d (%.1f%%)"
          % (len(nl), len(cen), 100.0 * len(nl) / len(cen)))
    print("  no recognised body shape, no content-named object loaded, no")
    print("  content-named caller directly or through the directory.")
    print("  --nameless lists every one.")
    print()
    named = sum(1 for _n, (s, _r, o, w) in cen.items() if o or w)
    print("  For scale: %d load at least one CONTENT-named object or issue a SWI,"
          % named)
    print("  and %d have at least one CONTENT-named caller." % _named_caller_count())
    print()
    direct_only, all_lab = _caller_label_counts()
    print("★ AND THE ONE NUMBER THAT EXPLAINS WHY 'NAME IT FROM ITS CALLER' DOES")
    print("  NOT SCALE IN prom_a: across every reference to every one of the %d,"
          % len(cen))
    print("  only %d DISTINCT content-named labels appear as a caller at all"
          % _distinct_content_callers())
    print("  (%d if the hop through prom_b's directory is not taken), out of %d"
          % (direct_only, all_lab))
    print("  distinct caller labels.  The call graph above these routines is")
    print("  overwhelmingly sub_XXXXXX calling sub_XXXXXX; there is no named")
    print("  neighbourhood to inherit from.")
    return 0


def _named_caller_count():
    refs, _c = R6.references()
    ind = indirect_refs()
    k = 0
    for n in subs():
        callers = {c for _t, _s, c, _kk in refs.get(n, [])}
        callers |= {c for _t, _s, c, _kk, _sl in ind.get(n, [])}
        if any(is_content(c) for c in callers):
            k += 1
    return k


def mode_nameless():
    nl = nameless()
    ends = extent_ends()
    print("%d routines with no distinguishing evidence of any kind." % len(nl))
    print("addr      bytes  refs  emitter that would revert a name")
    rc = ref_class()
    for n in nl:
        ea = sub_addr(n)
        nxt = ends.get(n)
        print("  %06X  %5s  %-11s %s"
              % (ea, (nxt - ea) if nxt else "?", rc[n], R6.emitter_of(ea) or "-"))
    return 0


# ===========================================================================
# 6. the levers that did NOT pay, measured
# ===========================================================================
def mode_levers():
    A, B = R6.images()
    cen = census()
    print("EVERY LEVER THIS ROUND MEASURED, INCLUDING THE ZEROS.")
    print()
    # L1 named thunk slot -> unnamed prom_a routine
    slots = thunk_slots()
    by = {}
    for n in A.order:
        ea = sub_addr(n) if R6.SUB.match(n) else A.routines[n][2]
        if ea is not None:
            by.setdefault(ea, n)
    l1 = [(nm, t) for _sa, (t, nm) in slots.items()
          if not re.match(r'^T_[0-9A-F]{6}$', nm) and R6.SUB.match(by.get(t, ""))]
    print("L1  a CONTENT-named prom_b thunk slot whose prom_a target is still")
    print("    sub_XXXXXX -- the directory naming the routine.   REACH %d." % len(l1))
    print("    Every named slot in prom_b was named FROM its target's prom_a label")
    print("    (the slot headers say DERIVATIVE), so the arrow only ever points the")
    print("    other way.  ⚠ Do not spend a round on this.")
    print()
    # L2 SFR
    sfr = {}
    for ln in open(os.path.join(ROOT, "include", "tmp95c061_sfr.inc")):
        m = re.match(r'\.equ\s+([A-Z0-9_]+),', ln.strip())
        if m:
            sfr[m.group(1)] = 1
    rx = re.compile(r'\b(%s)\b' % "|".join(sorted(sfr, key=len, reverse=True)))
    l2 = [n for n in subs() if any(rx.search(t) for _a, _m, t, _j in R6.body(A, n))]
    print("L2  a routine that touches a NAMED SFR by its symbol.   REACH %d." % len(l2))
    print("    All 23 SFR-symbol operands in prom_a are in RESET's own block, which")
    print("    is fully named.  Everything else addresses the peripherals by number,")
    print("    so 'what hardware does it touch' names nothing here.")
    print()
    # L3 forwarders
    cobj = content_objects()
    fwd_named = fwd_un = 0
    for n, (s, _r, _o, _w) in cen.items():
        if s != "fwd":
            continue
        b = R6.body(A, n)
        t = _call_target(b[0])
        fwd_named += 1 if (t is not None and is_content(by.get(t, ""))) else 0
        fwd_un += 0 if (t is not None and is_content(by.get(t, ""))) else 1
    print("L3  a forwarder (`call X` + `ret`) whose X is CONTENT-named.")
    print("    REACH %d of %d forwarders; the other %d forward to something that is"
          % (fwd_named, fwd_named + fwd_un, fwd_un))
    print("    itself sub_XXXXXX.  NOT TAKEN: `Veneer_<target>` restates the")
    print("    target's name and adds no fact -- it is the `RetStub_<addr>` trade")
    print("    round 6 refused, one hop further out.")
    print()
    # L4 framed -> content
    fr = [n for n in A.order if not is_content(n) and not R6.SUB.match(n)
          and not R6.INTERNAL.match(n) and not n.startswith(".L")]
    tgt = {}
    for n in fr:
        ea = A.routines[n][2]
        if ea is not None:
            tgt[ea] = n
    sites = collections.defaultdict(set)
    for img in (A, B):
        cur = None
        for i, ln in enumerate(img.lines):
            m = R6.TOPLABEL.match(ln)
            if m:
                cur = m.group(1)
            if img.addr[i] is None:
                continue
            for h in HEX6.findall(ln.split(";")[0]):
                v = int(h, 16) & 0xFFFFFF
                if v in tgt:
                    sites[tgt[v]].add(cur)
    l4 = [n for n in fr if len(sites.get(n, ())) == 1
          and is_content(list(sites[n])[0])]
    print("L4  a FRAMED label (a kind plus an address) promoted from its READER.")
    print("    prom_a framed labels: %d.  With exactly one reader and that reader"
          % len(fr))
    print("    CONTENT-named: %d.  %d have no reader site at all, and %d have"
          % (len(l4), sum(1 for n in fr if not sites.get(n)),
             sum(1 for n in fr if len(sites.get(n, ())) == 1
                 and not is_content(list(sites[n])[0]))))
    print("    exactly one reader which is itself sub_XXXXXX.")
    for n in l4:
        print("      %-32s read only by %s" % (n, list(sites[n])[0]))
    print("    ⚠ ALL of them already say what they are; the promotion would be a")
    print("      spelling change.  REACH FOR THIS ROUND: 0.")
    print()
    cont = sum(1 for n in A.order if is_content(n))
    fr = sum(1 for n in A.order if not is_content(n) and not R6.SUB.match(n)
             and not R6.INTERNAL.match(n) and not n.startswith(".L"))
    tot = cont + fr + len(subs())
    print("L5  ⚠ ROUND 6 CALLED THE Ring_* FAMILY 'THE CHEAPEST PROMOTION IN THE")
    print("    IMAGE'.  IT IS A SPELLING CHANGE AND THIS ROUND DECLINES IT.")
    print("    The 25 labels are Ring_{Get,Put,Init,Scan,ScanToPut}_{0080,0100,0200,")
    print("    0400,1000}.  The suffix IS the capacity -- Ring_Get_0080 wraps with")
    print("    `minc1_16 ix,0x007f` at 0xF84014 and Ring_Get_0100 with 0x00ff at")
    print("    0xF84033 -- and the listing states that above the family, in a table")
    print("    of all five masks.  So re-spelling `_0080` as `_Cap0080` would move")
    print("    prom_a's LOWER bound from %.2f%% to %.2f%% (+%.2f points) while changing"
          % (100.0 * cont / tot, 100.0 * (cont + 25) / tot, 100.0 * 25 / tot))
    print("    NOTHING that is known about the objects.  That is the")
    print("    +35-headers-that-were-really-removed-blank-lines trade a round-3")
    print("    reviewer caught, in the label column.  Recorded as a REJECTION so no")
    print("    later round pays for it again.")
    print()
    strict = {a for a, _s, _e in SM.idioms()}
    extra = [x for x in relaxed_idioms() if x[0] not in strict]
    frames = [x for x in extra if SM.records(x[1], x[2])]
    withtext = [x for x in frames if any(usable(c) for c in list_strings(x[1], x[2]))]
    print("L6  WIDENING THE STACK IDIOM TO ANY REGISTER PAIR.   REACH %d."
          % len(withtext))
    print("    prom_a_dl_stack_map.py scans for the XBC/XWA form only.  The general")
    print("    form `F2 <a24> 3R / 3R+8 / F2 <a24> 3S / 3S+8` finds %d sites, %d of"
          % (len(relaxed_idioms()), len(extra)))
    print("    them beyond the exact form -- but only %d of those FRAME (the record"
          % len(frames))
    print("    walk from start lands on end), and %d of the %d carry any caption."
          % (len(withtext), len(frames)))
    print("    So the exact form is not missing painters; the extra matches are two")
    print("    unrelated pointer loads that happen to sit next to two pushes.")
    print("    ⚠ Recorded as a rejection: the narrow scan is CORRECT, not narrow.")
    return 0


def relaxed_idioms():
    """The stack-push idiom with ANY register pair, not just XBC/XWA.

    `lda XBC,(a24)` is `F2 <a24> 31` and `push XBC` is `39`; the register digit
    is the low nibble and push is +8.  So the general shape is
    `F2 <a24> 3R / (3R+8) / F2 <a24> 3S / (3S+8)`.  This asks whether the exact
    XBC/XWA form notes/prom_a_dl_stack_map.py scans for is missing sites.
    """
    if "rid" in _C:
        return _C["rid"]
    out = []
    for d, base in ((SM.A, SM.A_BASE), (SM.B, SM.B_BASE)):
        for i in range(len(d) - 12):
            if d[i] != 0xF2 or d[i + 6] != 0xF2:
                continue
            r1, p1, r2, p2 = d[i + 4], d[i + 5], d[i + 10], d[i + 11]
            if not (0x30 <= r1 <= 0x37 and p1 == r1 + 8):
                continue
            if not (0x30 <= r2 <= 0x37 and p2 == r2 + 8):
                continue
            e = d[i + 1] | d[i + 2] << 8 | d[i + 3] << 16
            st = d[i + 7] | d[i + 8] << 8 | d[i + 9] << 16
            out.append((base + i, st, e))
    _C["rid"] = out
    return out


def _call_target(instr):
    """The absolute target of a `call`/`calr` body instruction, or None."""
    A, _B = R6.images()
    a, mn, txt, _j = instr
    ops = txt.split(None, 1)[1].strip() if len(txt.split(None, 1)) > 1 else ""
    m = re.match(r'^\(\s*0x([0-9A-Fa-f]+)\s*-\s*0x[0-9A-Fa-f]+\s*\)$', ops)
    if m:
        return int(m.group(1), 16)
    m = re.match(r'^(?:[a-z]+,\s*)?([A-Za-z_][A-Za-z0-9_]*)$', ops)
    if m:
        nm = m.group(1)
        if R6.SUB.match(nm):
            return sub_addr(nm)
        return A.routines.get(nm, (0, 0, None))[2]
    m = re.match(r'^(?:[a-z]+,\s*)?0x([0-9A-Fa-f]+)$', ops)
    if m and a is not None:
        v = int(m.group(1), 16)
        if mn == "calr":
            return R6.calr_target(a, v)
        slots = thunk_slots()
        return slots[v][0] if v in slots else v
    return None


# ===========================================================================
# 6b. is an unreferenced routine DEAD, or is its caller just not converted yet?
# ===========================================================================
INCBIN = re.compile(r'^\s*\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')


def unconverted_spans():
    """[(image tag, base, file offset, length)] for every `.incbin` still in the
    two listings -- the bytes no census that reads the listing can see."""
    out = []
    for tag, path, base in (("prom_a", S_A, 0xF80000),
                            ("prom_b", os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"),
                             0xF00000)):
        for ln in open(path):
            m = INCBIN.match(ln)
            if m:
                out.append((tag, base, int(m.group(1), 16), int(m.group(2), 16)))
    return out


def unconverted_hits():
    """address -> how many opcode-anchored candidate references to it live in
    UNCONVERTED bytes.

    ⚠ AN UPPER BOUND, NOT A COUNT.  The scan is at every byte offset, not at
    instruction boundaries, so a hit can be bytes inside another instruction or
    inside data.  It answers one question only: could the caller simply be a
    span nobody has converted yet?  The three shapes are `1D <a24>` (call),
    `1B <a24>` (jp) and `<a24> 00` (an LE32 pointer slot).
    """
    if "uh" in _C:
        return _C["uh"]
    roms = {"prom_a": SM.A, "prom_b": SM.B}
    hits = collections.Counter()
    for tag, _base, off, ln in unconverted_spans():
        d = roms[tag]
        blob = d[off:off + ln]
        for i in range(len(blob) - 4):
            a = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
            if blob[i] in (0x1D, 0x1B) and 0xF00000 <= a <= 0xFFFFFF:
                hits[a] += 1
            a2 = blob[i] | blob[i + 1] << 8 | blob[i + 2] << 16
            if blob[i + 3] == 0x00 and 0xF00000 <= a2 <= 0xFFFFFF:
                hits[a2] += 1
    _C["uh"] = hits
    return hits


def mode_unreached():
    rc = ref_class()
    hits = unconverted_hits()
    none = [n for n in subs() if rc[n] == "none"]
    dirs = [n for n in subs() if rc[n] == "dir_only"]
    slots = {t: sa for sa, (t, _nm) in thunk_slots().items()}
    live = [n for n in none if hits.get(sub_addr(n))]
    dead = [n for n in none if not hits.get(sub_addr(n))]
    print("Is an unreferenced routine DEAD, or is its caller simply not converted?")
    print()
    print("  unconverted `.incbin` spans still in the two listings: %d, %d bytes"
          % (len(unconverted_spans()), sum(x[3] for x in unconverted_spans())))
    print()
    print("  reached by NOTHING in either listing ................. %d" % len(none))
    print("    with an opcode-anchored candidate in unconverted bytes  %d" % len(live))
    print("    with NO candidate anywhere in either ROM image ....... %d" % len(dead))
    print()
    dlive = [n for n in dirs if hits.get(slots.get(sub_addr(n), -1), 0)]
    print("  published by a thunk slot nothing in either listing calls  %d" % len(dirs))
    print("    whose SLOT has a candidate caller in unconverted bytes   %d" % len(dlive))
    print()
    print("  ★ So %d prom_a routines are reached by nothing this project can see"
          % len(dead))
    print("    ANYWHERE -- not in the listings, not as a byte pattern in the")
    print("    unconverted remainder.  They are the honest floor of the image, and")
    print("    no naming mechanism reaches them without new evidence.")
    print()
    for n in dead[:40]:
        print("      %s" % n)
    if len(dead) > 40:
        print("      ... and %d more" % (len(dead) - 40))
    return 0


# ===========================================================================
# 6c. THE SECOND LEVER: a routine that loads a pointer STRAIGHT AT ROM TEXT
# ===========================================================================
# Not through a display list -- the SWI7 text services take XIY = a character
# table, so a routine that points XIY at printable bytes is handing that text to
# the screen (or comparing against it).  Rounds 5 and 6 only ever read text out
# of a DISPLAY LIST, so this path was never searched.
STRING_MIN = 5          # printable run length
STRING_ALPHA = 4        # of which at least this many letters


def ascii_at(a, maxlen=48):
    d, b = SM.img(a)
    if d is None:
        return ""
    out = b""
    for c in d[a - b:a - b + maxlen]:
        if not 0x20 <= c < 0x7F:
            break
        out += bytes([c])
    return out.decode()


def string_loaders():
    """label -> [(site, target, the ASCII there)] for routines OUTSIDE the
    painter population whose own body loads a pointer at ROM text."""
    if "sl" in _C:
        return _C["sl"]
    A, _B = R6.images()
    pop = set(painter_population())
    out = collections.OrderedDict()
    for n in A.order:
        if n in pop or not (R6.SUB.match(n) or n in {nn for _o, nn, _w in STRING_NAMES}):
            continue
        rows = []
        for a, mn, txt, _j in R6.body(A, n):
            if mn in ("call", "calr", "jp", "jr", "jrl", "swi"):
                continue
            for h in HEX6.findall(txt):
                v = int(h, 16) & 0xFFFFFF
                if v < 0xF00000:
                    continue
                t = ascii_at(v)
                if len(t) >= STRING_MIN and sum(c.isalpha() for c in t) >= STRING_ALPHA:
                    rows.append((a, v, t))
        if rows:
            out[n] = rows
    _C["sl"] = out
    return out


STRING_NAMES = [
    ("sub_F94C4C", "Print_DebugMonitor",
     "prints the line ` --- DEBUG MONITOR BY (c)masa,toshi --- `"),
]

# Extra evidence lines for a named string-loader, appended to its header.
STRING_WHY = {
    "sub_F94C4C": [
        "★ THE LENGTH IS THE PROOF, not the reader's eye.  The routine first",
        "  zeroes the row cursor (0x284F) and then calls",
        "  LCD_PrintLine40_AdvanceRow, whose own header records BC = 0x28 = 40",
        "  characters per line.  The printable run at 0xF94C67 is 45 bytes, and",
        "  its first 40 are exactly ` --- DEBUG MONITOR BY (c)masa,toshi --- `;",
        "  the five that follow (`><;:D`) are the next object, not this line.",
        "  So this routine draws the FIRST line of a debug screen, and the",
        "  machine's own firmware names that screen DEBUG MONITOR.",
        "⚠ NOT CLAIMED: how the monitor is entered, what else it prints, or that",
        "  `masa,toshi` are the authors of anything beyond this string.",
        "⚠ 0xF94C67-0xF94C8E, the 40 bytes the printer draws, is TEXT that",
        "  this listing still decodes as instructions (`ldb w,0x2d` ...).  The",
        "  bytes are right and the gate is green either way; the decode is",
        "  misleading and is left for a round that owns the data/code split.",
    ],
}


def string_current(old):
    """`old`, or the name --apply-strings gave it."""
    A, _B = R6.images()
    if old in A.routines:
        return old
    for o, n, _w in STRING_NAMES:
        if o == old:
            return n
    return old


def string_orig(cur):
    """The inverse: the sub_XXXXXX a current label came from."""
    for o, n, _w in STRING_NAMES:
        if n == cur:
            return o
    return cur


def _string_header(old, new, what):
    rows = string_loaders()[string_current(old)]
    if new:
        lines = [RULE, "; %s -- %s" % (new, what), ";"]
    else:
        lines = [RULE,
                 "; %s -- loads a pointer straight at ROM TEXT.  NOT NAMED." % old,
                 ";"]
    cf = _callers_line(old)
    lines.append("; Called from: %s" % cf[0])
    for x in cf[1:4]:
        lines.append(";          %s" % x)
    if len(cf) > 4:
        lines.append(";          ... and %d more" % (len(cf) - 4))
    lines.append(";")
    for a, v, t in rows[:5]:
        lines.append(";     0x%06X loads 0x%06X, where the ROM reads:" % (a, v))
        lines.append(';        "%s"' % t[:64])
    if len(rows) > 5:
        lines.append(";     ... and %d more such loads" % (len(rows) - 5))
    lines.append("; Evidence: the immediate at the cited instruction, and the bytes")
    lines.append(";          at that address in original_ROMs/, read as printable")
    lines.append(";          ASCII until the first non-printable byte.")
    for x in STRING_WHY.get(old, []):
        lines.append(";          %s" % x)
    if not new:
        lines += _wrap("; NOT NAMED because ", ";          ",
                       "the text says what the routine READS, not what it DOES with "
                       "it; a name taken from it would claim a role nothing here "
                       "establishes.  The string is recorded so the next round starts "
                       "from evidence instead of a search.")
    lines.append("; Recorded by notes/prom_a_understanding_round7.py --apply-strings.")
    lines.append(RULE)
    return lines


def apply_strings():
    """Headers for the string-loading routines.  ⚠ SKIPS any routine that
    ALREADY carries its own header -- six of them are round 5's `SCREEN IS NOT
    ESTABLISHED` painters, and overwriting another round's evidence to raise a
    header count is exactly the trade this wave keeps catching."""
    A, _B = R6.images()
    src = open(S_A).read()
    rows = string_loaders()
    names = {o: (n, w) for o, n, w in STRING_NAMES}
    lines = src.split("\n")
    plan, skipped = [], []
    for cur in rows:
        old = string_orig(cur)
        li = A.routines[cur][0]
        j, blanks = li - 1, 0
        while j >= 0:
            if lines[j].startswith(";"):
                j -= 1
                blanks = 0
                continue
            if lines[j].strip() == "" and blanks == 0:
                blanks += 1
                j -= 1
                continue
            break
        block = "\n".join(lines[j + 1:li])
        mine = "--apply-strings" in block
        if j + 1 < li and not mine:
            skipped.append(old)
            continue
        plan.append((li, old, (j + 1, li) if mine else None))
    done = 0
    for li, old, span in sorted(plan, reverse=True):
        new, what = names.get(old, (None, None))
        hdr = _string_header(old, new, what)
        if span:
            lines[span[0]:span[1]] = hdr
        else:
            lines[li:li] = hdr
        done += 1
    src = "\n".join(lines)
    total = 0
    for old, new, _w in STRING_NAMES:
        if re.search(r'^%s:' % old, src, re.M):
            src, k = re.subn(r'\b%s\b' % old, new, src)
            total += k
    write_part(S_A_MASTER, src)
    print("%d string-lever headers written, %d skipped because the routine already"
          % (done, len(skipped)))
    print("carries another round's header: %s" % ", ".join(skipped))
    print("%d rename(s), %d textual occurrences" % (len(STRING_NAMES), total))
    print("⚠ NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


def mode_strings():
    rows = string_loaders()
    print("★ SECOND LEVER: a routine whose own body points at ROM TEXT directly,")
    print("  not through a display list.  Rounds 5 and 6 only read text out of")
    print("  display lists, so this path was never searched.")
    print()
    print("  routines outside the painter population that load such a pointer: %d"
          % len(rows))
    print("  NAMED from it: %d.  The rest get a header quoting the string and keep"
          % len(STRING_NAMES))
    print("  sub_XXXXXX, because what a routine READS is not what it DOES.")
    print()
    for n, r in rows.items():
        print("  %-20s %s" % (n, "" if string_orig(n) == n else "(named this round)"))
        for a, v, t in r[:4]:
            print('      0x%06X -> 0x%06X  "%s"' % (a, v, t[:60]))
    return 0


# ===========================================================================
# 7. reporting modes for the lever
# ===========================================================================
def mode_painters():
    rows = painters()
    cand = candidates()
    pop = set(painter_population())
    subrows = {n: r for n, r in rows.items() if n in pop}
    print("★ THE LEVER: a display list handed to the interpreter ON THE STACK.")
    print()
    print("  exact 12-byte push idioms in both ROM images:              %d"
          % len(SM.idioms()))
    print("  ...inside some prom_a routine's OWN body (to its own ret): %d" % len(rows))
    print("  ...whose routine is still sub_XXXXXX:                      %d" % len(subrows))
    print("  ...drawing at least one list with a real word in it:       %d" % len(cand))
    print("  NAMED here:                                                %d" % len(NAMES))
    print("  REFUSED with a stated reason:                              %d"
          % (len(subrows) - len(NAMES)))
    print()
    tags = {}
    for o, nn, _w in NAMES:
        tags[current_label(o)] = nn
    for n, (lists, caps) in cand.items():
        tag = tags.get(n)
        print("  %-14s %s" % (n, tag if tag else "REFUSED"))
        for a, s, e, how, cs in lists:
            print("      site 0x%06X  list 0x%06X-0x%06X  leaves by %-7s %s"
                  % (a, s, e, how, "; ".join('"%s"' % c.strip() for c in cs)[:92]))
        if tag:
            bad = morphemes(tag, caps)
            if bad:
                print("      ⚠ MORPHEME NOT IN THIS ROUTINE'S ROM TEXT: %s" % bad)
        else:
            print("      why: %s" % REFUSALS.get(n, "(no reason recorded)"))
    print()
    textless = [n for n in subrows if n not in cand]
    print("  %d more draw only textless lists -- glyph/icon records with no .ascii."
          % len(textless))
    print("  That is the correct answer for them, not a failure: %s"
          % ", ".join(sorted(textless)[:6]) + ", ...")
    return 0


def mode_morphemes():
    cand = candidates()
    print("MORPHEME GUARD -- every morpheme of every name, against the ROM text")
    print("of that routine's OWN lists.  A miss is a name this round invented.")
    bad = 0
    for old, new, _w in NAMES:
        caps = cand[current_label(old)][1]
        miss = morphemes(new, caps)
        bad += len(miss)
        print("  %-36s %-14s %s" % (new, old, "ok" if not miss else "MISSING %s" % miss))
    print("  morphemes not found in the ROM: %d" % bad)
    return 1 if bad else 0


# ===========================================================================
# 8. apply / verify
# ===========================================================================
def _wrap(prefix, cont, text, width=74):
    """Comment prose wrapped at a word boundary.  A header line that runs to 200
    characters is prose nobody reads in a listing 9.6 MB long."""
    out, line = [], prefix
    for w in text.split():
        if len(line) + 1 + len(w) > width and line.strip() not in (prefix.strip(),):
            out.append(line.rstrip())
            line = cont + w
        else:
            line = (line + " " + w) if line not in (prefix,) else line + w
    if line.strip():
        out.append(line.rstrip())
    return out


def _textline(cs, width=70):
    """The captions of one list, cut at a caption boundary, never mid-string."""
    parts, out, n = ['"%s"' % c.strip() for c in cs], [], 0
    for p in parts:
        if n + len(p) + 2 > width:
            out.append("...")
            break
        out.append(p)
        n += len(p) + 2
    return "; ".join(out)


def _callers_line(old):
    """⚠ Looks the routine up under BOTH spellings.  After a rename the
    reference census is keyed by the NEW label, and a header that reports
    "nothing names this address" because it asked under the old one is a false
    statement the byte gate cannot catch."""
    refs, _c = R6.references()
    ind = indirect_refs()
    keys = {old, current_label(old), string_current(old)}
    out = []
    rr = [x for k in keys for x in refs.get(k, [])]
    ii = [x for k in keys for x in ind.get(k, [])]
    for tag, addr, caller, kind in rr:
        out.append("%s %s (`%s`)%s" % (tag, caller or "?", kind,
                                       "" if addr is None else " at 0x%06X" % addr))
    for tag, addr, caller, kind, slot in ii:
        out.append("%s %s (`%s` through %s)%s"
                   % (tag, caller or "?", kind, slot,
                      "" if addr is None else " at 0x%06X" % addr))
    return out or ["nothing in either image names this address."]


def _header(old, new, what):
    lists, caps = candidates()[current_label(old)]
    lines = [RULE, "; %s -- %s" % (new, what), ";"]
    cf = _callers_line(old)
    lines.append("; Called from: %s" % cf[0])
    for x in cf[1:6]:
        lines.append(";          %s" % x)
    if len(cf) > 6:
        lines.append(";          ... and %d more" % (len(cf) - 6))
    lines.append(";")
    lines.append("; It hands %d display list(s) to the interpreter ON THE STACK --"
                 % len(lists))
    lines.append(";          lda XBC,<end> / push XBC / lda XWA,<start> / push XWA,")
    lines.append(";          then the stack veneer.  The lists, and the text each draws:")
    for a, s, e, how, cs in lists:
        lines.append(";     site 0x%06X  list 0x%06X-0x%06X (%d B, leaves by %s)"
                     % (a, s, e, e - s, how))
        if cs:
            lines.append(";        text: %s" % _textline(cs))
    # ⚠ The per-list text above is TRUNCATED at a caption boundary, so the very
    # caption a name rests on can fall off the end.  This line cannot: it is
    # built from the name's own morphemes.
    src_caps = []
    for m in re.findall(r'[A-Z0-9]?[a-z0-9]+', new.split("_", 1)[1]):
        for c in caps:
            if m.lower() in c.lower() and c.strip() not in src_caps:
                src_caps.append(c.strip())
                break
    lines += _wrap("; From the captions: ", ";          ",
                   "; ".join('"%s"' % c for c in src_caps))
    lines.append("; Evidence: the list bounds are the two 24-bit IMMEDIATES of the")
    lines.append(";          12-byte push idiom at the cited site, and the record")
    lines.append(";          length bytes walked from <start> land EXACTLY on <end>")
    lines.append(";          (368 of 368 in both images do -- notes/prom_a_dl_stack_map.py).")
    lines.append(";          The quoted text is the `.ascii` the interpreter draws")
    lines.append(";          verbatim.  Every morpheme of this name occurs in it;")
    lines.append(";          notes/prom_a_understanding_round7.py --morphemes checks that.")
    lines.append(";          `Paint_` is a structural verb, not ROM text.")
    lines.append("; Unknown: whether this routine also handles input for the screen,")
    lines.append(";          and whether another routine paints it too.  Neither was")
    lines.append(";          searched.  ⚠ The register-form scan of rounds 5 and 6 does")
    lines.append(";          not see this call shape at all, which is why this routine")
    lines.append(";          was sub_XXXXXX until round 7.")
    lines.append("; Named by notes/prom_a_understanding_round7.py --apply; the byte gate")
    lines.append(";          is blind to this name, --verify reads it back.")
    lines.append(RULE)
    return lines


def _refusal_header(old):
    lists, caps = candidates()[current_label(old)]
    lines = [RULE, "; %s -- a screen painter this round REFUSED to name." % old, ";"]
    lines.append("; It hands %d display list(s) to the interpreter ON THE STACK."
                 % len(lists))
    for a, s, e, how, cs in lists:
        lines.append(";     site 0x%06X  list 0x%06X-0x%06X (%d B, leaves by %s)"
                     % (a, s, e, e - s, how))
        if cs:
            lines.append(";        text: %s" % _textline(cs))
    lines.append("; Evidence: the two 24-bit immediates of the 12-byte push idiom at")
    lines.append(";          the cited site; the record walk from <start> lands exactly")
    lines.append(";          on <end>; the text is the `.ascii` the interpreter draws.")
    lines += _wrap("; NOT NAMED because ", ";          ",
                   REFUSALS.get(old, "no reason was recorded") + ".")
    lines.append(";          A wrong name passes the byte gate forever, so this keeps")
    lines.append(";          sub_XXXXXX and states the gap.")
    lines.append("; Recorded by notes/prom_a_understanding_round7.py --apply.")
    lines.append(RULE)
    return lines


def _own_header_span(lines, label_line, old, new=None):
    j, blanks = label_line - 1, 0
    while j >= 0:
        if lines[j].startswith(";"):
            blanks = 0
            j -= 1
            continue
        if lines[j].strip() == "" and blanks == 0:
            blanks += 1
            j -= 1
            continue
        break
    start = j + 1
    if start >= label_line:
        return None
    block = "\n".join(lines[start:label_line])
    for nm in (old, new):
        if nm and ("; %s --" % nm) in block:
            return (start, label_line)
    return None


def apply():
    """Idempotent: headers are REBUILT every run (so a wording fix lands), and a
    rename happens only while the old label is still there."""
    A, _B = R6.images()
    src = open(S_A).read()
    todo = []
    for old, new, what in NAMES:
        here = bool(re.search(r'^%s:' % old, src, re.M))
        done = bool(re.search(r'^%s:' % new, src, re.M))
        if not here and not done:
            print("REFUSED: neither %s nor %s is a label in prom_a" % (old, new))
            return 1
        if here and re.search(r'\b%s\b' % new, src):
            print("REFUSED: %s already occurs in prom_a but %s is still a label"
                  % (new, old))
            return 1
        todo.append((old, new, what, here))
    lines = src.split("\n")
    plan = []
    for old, new, what, here in todo:
        cur = old if here else new
        plan.append((A.routines[cur][0], old, new, what))
    for old in REFUSALS:
        if old in A.routines:
            plan.append((A.routines[old][0], old, None, None))
    renamed = headers = 0
    for li, old, new, what in sorted(plan, reverse=True):
        hdr = _header(old, new, what) if new else _refusal_header(old)
        span = _own_header_span(lines, li, old, new)
        if span:
            lines[span[0]:span[1]] = hdr
        else:
            lines[li:li] = hdr
        headers += 1
    src = "\n".join(lines)
    total = 0
    for old, new, _w, here in todo:
        if not here:
            continue
        src, k = re.subn(r'\b%s\b' % old, new, src)
        total += k
        renamed += 1
    write_part(S_A_MASTER, src)
    print("applied %d renames (%d textual occurrences) and rebuilt %d headers, "
          "%d of them refusal headers" % (renamed, total, headers, len(REFUSALS)))
    print("⚠ NOW RUN: python3 scripts/analysis/assert_byte_identical.py")
    return 0


def verify():
    src = open(S_A).read()
    bad = 0
    for old, new, _w in NAMES:
        ok = bool(re.search(r'^%s:' % new, src, re.M)) and not re.search(r'\b%s\b' % old, src)
        bad += 0 if ok else 1
        print("  %-36s %s" % (new, "ok" if ok else "MISSING"))
    for old in REFUSALS:
        ok = ("; %s -- a screen painter this round REFUSED" % old) in src
        bad += 0 if ok else 1
        print("  %-36s %s" % (old + " (refusal header)", "ok" if ok else "MISSING"))
    print("  %d of %d present" % (len(NAMES) + len(REFUSALS) - bad, len(NAMES) + len(REFUSALS)))
    return 1 if bad else 0


def mode_stale():
    """Names renamed here that other files still spell the old way.  This lane
    may not edit those files; the list is so the next round can."""
    olds = [o for o, _n, _w in NAMES] + [o for o, _n, _w in STRING_NAMES]
    hits = []
    for dirpath, _d, files in os.walk(ROOT):
        if ".git" in dirpath or "rebuilt_ROMs" in dirpath:
            continue
        # ⚠ skip asm_source expansion caches (notes/.image-*.s): derived copies
        # of whole images, with a .s extension, inside this walk.  They silently
        # double every figure (seen 2026-09-01).
        files = [f for f in files if not f.startswith(".")]
        for fn in files:
            if not fn.endswith((".md", ".py", ".s", ".txt")):
                continue
            p = os.path.join(dirpath, fn)
            if p == S_A:
                continue
            try:
                t = open(p, errors="ignore").read()
            except OSError:
                continue
            for o in olds:
                if o in t and "round7" not in fn:
                    hits.append((os.path.relpath(p, ROOT), o))
    for p, o in sorted(set(hits)):
        print("  %-60s %s" % (p, o))
    print("  %d stale spellings in %d files"
          % (len(set(hits)), len({p for p, _o in set(hits)})))
    return 0


# ===========================================================================
# 9. selftest
# ===========================================================================
def selftest():
    A, _B = R6.images()
    cen = census()
    cand = candidates()
    print("SELFTEST")
    # ★ INVARIANT ACROSS --apply: the population this round speaks about is the
    # 2,923 sub_XXXXXX prom_a carried at the round-7 barrier.  After --apply, 24
    # of them are content names, so the sum is what must hold, not the count.
    check("sub_XXXXXX now + every name this round applied",
          len(subs()) + len(NAMES) + len(STRING_NAMES), 2923)
    check("label-name address disagrees with the listing", 
          len([n for n in subs()
               if A.routines[n][2] is not None and A.routines[n][2] != sub_addr(n)]), 0)
    check("sub_ labels with NO address in the listing", 
          len([n for n in subs() if A.routines[n][2] is None]), 61)
    check("every sub_ is in exactly one census bucket", len(cen), len(subs()))
    check("exact 12-byte stack idioms (both images)", len(SM.idioms()), 368)
    check("...that sit in some prom_a routine's own body", len(painters()), 72)
    check("...whose routine is sub_XXXXXX or was renamed by this round",
          len(painter_population()), 67)
    check("...with a caption carrying a word", len(cand), 31)
    check("names applied by this round", len(NAMES), 24)
    check("refusals with a recorded reason", len(REFUSALS), 7)
    check("named + refused = the caption-carrying candidates",
          len(NAMES) + len(REFUSALS), len(cand))
    check("every named routine is IN the mechanical candidate set",
          [o for o, _n, _w in NAMES if current_label(o) not in cand], [])
    check("every refused routine is IN it too",
          [o for o in REFUSALS if o not in cand], [])
    check("morphemes of every name that are NOT in its own ROM text",
          sum(len(morphemes(n, cand[current_label(o)][1])) for o, n, _w in NAMES), 0)
    # ★ tested on the LAST element as well as the first
    last = NAMES[-1]
    check("LAST name's routine really draws its caption",
          any("Are You Sure?" in c for c in cand[current_label(last[0])][1]), True)
    check("LAST name's morphemes",
          morphemes(last[1], cand[current_label(last[0])][1]), [])
    check("FIRST name's morphemes",
          morphemes(NAMES[0][1], cand[current_label(NAMES[0][0])][1]), [])
    check("LAST refusal (sorted) has a reason", 
          bool(REFUSALS[sorted(REFUSALS)[-1]]), True)
    # negative control: a name the ROM does not carry must FAIL the guard
    check("negative control -- 'Home' is refused by the morpheme guard",
          morphemes("Paint_Home", cand[current_label(NAMES[0][0])][1]), ["Home"])
    # the reference census
    rc = ref_class()
    # ★ round 6 published 302 here.  It is 301, and the one that moved is a
    # CORRECTION, not a drift: sub_FADF08 has no address in the listing (its
    # emitter prints no address column), so an address-keyed census cannot see
    # that prom_b slot `T_F40894: jp 0xFADF08` publishes it and that prom_a
    # 0xF82071 calls that slot.  --selftest pins both halves.
    # ⚠ THE THREE COUNTS BELOW DEPEND ON prom_b's LISTING, WHICH OTHER LANES
    # CONVERT.  Converting a prom_b span can only REVEAL a caller, never hide
    # one, so they can only fall.  They are therefore checked as CEILINGS
    # against the value measured at round 7's barrier, and the current value is
    # printed: a drop is the tree improving, not this file rotting.
    check("no reference in either listing <= 301 (round 6 said 302)",
          sum(1 for v in rc.values() if v == "none") <= 301, True)
    print("        (currently %d)" % sum(1 for v in rc.values() if v == "none"))
    check("the one round 6 counted as unreferenced that is not",
          rc["sub_FADF08"], "dir_called")
    check("...and its single caller", 
          [(t, "0x%06X" % a, c, k, sl) for t, a, c, k, sl in indirect_refs()["sub_FADF08"]],
          [("prom_a", "0xF82071", "sub_F82028", "call", "T_F40894")])
    check("published by a thunk slot nothing in either listing calls <= 685",
          sum(1 for v in rc.values() if v == "dir_only") <= 685, True)
    print("        (currently %d)" % sum(1 for v in rc.values() if v == "dir_only"))
    check("the four reference classes partition the population",
          sum(collections.Counter(rc.values()).values()), len(subs()))
    check("one-byte `ret` objects", 
          sum(1 for v in cen.values() if v[0] == "ret1"), 283)
    check("nothing-to-name-them-from bucket <= 2144", len(nameless()) <= 2144, True)
    print("        (currently %d)" % len(nameless()))
    check("distinct CONTENT-named labels that call ANY sub_XXXXXX >= 64",
          _distinct_content_callers() >= 64, True)
    print("        (currently %d)" % _distinct_content_callers())
    # --- the second lever, and its own negative control -------------------
    check("routines that load a pointer straight at ROM text", len(string_loaders()), 26)
    check("...named from it", len(STRING_NAMES), 1)
    check("the named one's string", ascii_at(0xF94C67)[:18], " --- DEBUG MONITOR")
    check("its first 40 characters (the printer draws BC=0x28)",
          len(" --- DEBUG MONITOR BY (c)masa,toshi --- "), 40)
    # ⚠ THE CONTROL HAS TO TEST THE WHOLE PREDICATE.  The first draft asked only
    # whether the run at 0xF94C4C was short; it is `3E 3C 3B 3A 40` = "><;:@",
    # five PRINTABLE bytes of pushes, and the control passed for the wrong
    # reason.  The letter count is what rejects it.
    def _txtpred(a):
        t = ascii_at(a)
        return len(t) >= STRING_MIN and sum(c.isalpha() for c in t) >= STRING_ALPHA
    check("negative control -- the push run at 0xF94C4C is not text", _txtpred(0xF94C4C), False)
    check("negative control -- 0xF94C46 (`swi 7`, byte 0xFF) is not text",
          _txtpred(0xF94C46), False)
    check("positive control -- 0xF94C67 IS text", _txtpred(0xF94C67), True)
    # --- the widened idiom, a measured zero -------------------------------
    strict = {a for a, _s, _e in SM.idioms()}
    extra = [x for x in relaxed_idioms() if x[0] not in strict]
    check("relaxed stack idioms beyond the exact form", len(extra), 111)
    check("...that FRAME", len([x for x in extra if SM.records(x[1], x[2])]), 3)
    check("...that frame AND carry a caption",
          len([x for x in extra if SM.records(x[1], x[2])
               and any(usable(c) for c in list_strings(x[1], x[2]))]), 0)
    check("every named routine leaves its idiom by a known veneer path",
          sorted({h for o, _n, _w in NAMES
                  for _a, _s, _e, h, _c in painters()[current_label(o)]}
                 - {"call", "jp(XIX)", "jr"}), [])
    print("\n%d ok, FAILURES: %d" % (OK, FAIL))
    return 1 if FAIL else 0


def _caller_label_counts():
    """(distinct CONTENT callers via direct references only, distinct callers)."""
    refs, _c = R6.references()
    lab, cont = set(), set()
    for n in subs():
        for _t, _s, c, _k in refs.get(n, []):
            if c:
                lab.add(c)
                if is_content(c):
                    cont.add(c)
    return len(cont), len(lab)


def _distinct_content_callers():
    """★ WHY 'NAME IT FROM ITS CALLER' DOES NOT SCALE HERE, IN ONE NUMBER."""
    refs, _c = R6.references()
    ind = indirect_refs()
    out = set()
    for n in subs():
        for _t, _s, c, _k in refs.get(n, []):
            if is_content(c):
                out.add(c)
        for _t, _s, c, _k, _sl in ind.get(n, []):
            if is_content(c):
                out.add(c)
    return len(out)


if __name__ == "__main__":
    a = sys.argv[1:]
    if "--census" in a:
        sys.exit(mode_census())
    if "--nameless" in a:
        sys.exit(mode_nameless())
    if "--painters" in a:
        sys.exit(mode_painters())
    if "--morphemes" in a:
        sys.exit(mode_morphemes())
    if "--strings" in a:
        sys.exit(mode_strings())
    if "--apply-strings" in a:
        sys.exit(apply_strings())
    if "--unreached" in a:
        sys.exit(mode_unreached())
    if "--levers" in a:
        sys.exit(mode_levers())
    if "--stale" in a:
        sys.exit(mode_stale())
    if "--apply" in a:
        sys.exit(apply())
    if "--verify" in a:
        sys.exit(verify())
    if "--selftest" in a:
        sys.exit(selftest())
    print(__doc__)
