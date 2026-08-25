#!/usr/bin/env python3
"""Generate the LABEL MAP and the ROUTINE HEADERS for one prom_c address range.

Defaults to 0xFA7E2C-0xFABE2F, the voice-parameter module it was written for.

QUESTION IT ANSWERS
  "The voice-parameter module has 60-odd routines.  What goes in each header, and how
   is every line of it read off the ROM rather than guessed?"

WHAT EACH HEADER FIELD COMES FROM -- nothing here is inferred
  Called from:  every LITERAL transfer site in the whole image (notes/
                prom_c_module_map.py's scan of `1D`/`1B` abs24 and `1E` calr rel16),
                split into sites inside this module and sites outside it, with the
                outside ones resolved to the name of the converted routine that
                CONTAINS them -- taken from prom_c/wsa1_prom_c.s's own labels and
                `; ADDR` comments, never from a guess.  A site with no enclosing
                converted routine is printed as a bare address.
  Inputs:       the frame size from the routine's own `link XIZ,imm16`, and the set
                of positive frame slots `(XIZ+0xNN)` its instructions read -- those
                are the arguments, because the caller pushes them below the link.
  Outputs:      the absolute data addresses it WRITES (`ld (0xNNNN),...` shape),
                separated from the ones it only reads.
  Calls:        every `call`/`calr` target, marked (converted) or (UNCONVERTED)
                against the `.incbin` spans of the source file at generation time.
  Evidence:     the generator plus the fragment verifier; the listing under the
                header is the byte-identical round-trip of the ROM.

  ⚠ A field this cannot read is left out rather than filled in.  No header produced
  here claims to know what a routine is FOR.  Names are `sub_FAxxxxx` for that
  reason; the two exceptions are the pair of computed-goto dispatchers, whose names
  state only the field they switch on, which is an instruction operand.

RUN
  python3 notes/gen_prom_c_block_headers.py --labels  > /tmp/vp.labels
  python3 notes/gen_prom_c_block_headers.py --headers > /tmp/vp.headers
  python3 notes/gen_prom_c_block_headers.py --start 0xFA5949 --end 0xFA7E2C --headers
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTES = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
sys.path.insert(0, NOTES)
import prom_c_module_map as mm            # noqa: E402

START, END = 0xFA7E2C, 0xFABE30
for _i, _a in enumerate(sys.argv):
    if _a == "--start":
        START = int(sys.argv[_i + 1], 0)
    elif _a == "--end":
        END = int(sys.argv[_i + 1], 0)
SPECIAL = {0xFA8BDD: "VoiceParam_DispatchOn_17_36",
           0xFA900A: "VoiceParam_DispatchOn_17_11"}

# The only two hand-written header bodies in this block.  Both names claim ONLY what
# an instruction operand says: which field the routine switches on.  Every sentence is
# asserted by notes/prom_c_voiceparam_checks.py section 5.
EXTRA = {
    0xFA8BDD: [
        "; ★ THE NAME CLAIMS ONLY WHAT THE OPERANDS SAY.  The routine does",
        ";      ld HL,(XIZ+0x08) / ld XBC,(XHL+0x17) / ld A,(XBC+0x36) / and A,0x07",
        ";  -- follow the pointer field at +0x17 of the argument, take the byte at +0x36",
        ";  of what it points to, keep three bits -- and switches on the result.  It does",
        ";  NOT claim to know what field 0x36 means; nothing here reads that.",
        "; ★ IT IS THE SAME ROUTINE AS VoiceParam_DispatchOn_17_11 (0xFA900A) WITH ONE",
        ";  BYTE CHANGED.  The two are 64 bytes long, share their first twelve bytes and",
        ";  their `ld XBC,(XHL+0x17)`, and differ semantically in exactly one byte: the",
        ";  +0x36 here is +0x11 there.  Their remaining differences are the relocated",
        ";  addresses of their own six-entry tables.  Checked byte by byte by",
        ";  notes/prom_c_voiceparam_checks.py section 5.",
        "; ⚠ INDEX 0 AND INDEX > 5 GO TO THE SAME PLACE.  Table entry 0 is 0xFA8C1D,",
        ";  which is also the `jr UGT` target, so a zero field and an out-of-range field",
        ";  are not distinguished.",
    ],
    0xFA900A: [
        "; ★ Same shape as VoiceParam_DispatchOn_17_36 (0xFA8BDD): follow the pointer at",
        ";  +0x17 of the argument, take the byte at +0x11 of the target, mask with 7, and",
        ";  switch.  See that routine's header; the two differ in one semantic byte.",
        "; ⚠ Table entry 0 is 0xFA904A, which is also the `jr UGT` target.",
    ],
}


def converted_spans():
    """(lo, hi) ROM address ranges the source file still leaves as .incbin."""
    out = []
    for m in re.finditer(r'^\s*\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                         open(SRC).read(), re.M):
        lo = 0xF80000 + int(m.group(1), 16)
        out.append((lo, lo + int(m.group(2), 16)))
    return out


UNCONV = converted_spans()


def is_unconverted(a):
    return any(lo <= a < hi for lo, hi in UNCONV)


def source_routines():
    """{addr: label} for every label in prom_c/wsa1_prom_c.s that owns an address."""
    out, pend = {}, []
    for ln in open(SRC):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            pend.append(m.group(1))
            continue
        m = re.search(r';\s*([0-9A-F]{6})\s', ln)
        if m and pend:
            out[int(m.group(1), 16)] = pend[-1]
            pend = []
    return out


def enclosing(addr, labelled):
    """The converted routine label whose address range contains `addr`, or None.

    ⚠ An address inside an `.incbin` span has NO enclosing routine, however close a
    label happens to sit below it.  Checking that first is not a nicety: without it,
    converting a block silently re-attributes every unconverted call site within
    0x800 above it to that block's last routine, and a caller census then names
    routines that do not contain the site.  That happened -- the voice-parameter
    conversion moved 0xFAC368 from "(caller not yet converted)" to "sub_FABDAC",
    which is 0x539 bytes and one `.incbin` boundary away from it.
    """
    if is_unconverted(addr):
        return None
    best = None
    for a in labelled:
        if a <= addr and (best is None or a > best):
            best = a
    if best is None or addr - best > 0x800:
        return None
    return labelled[best]


def listing():
    """{addr: unidasm text} for the module, from the byte-verified generator."""
    import subprocess
    env = dict(os.environ)
    out = subprocess.run([sys.executable, os.path.join(NOTES, "gen_prom_c_block.py"),
                          "--start", hex(START), "--end", hex(END)],
                         capture_output=True, text=True, cwd=ROOT, env=env)
    if out.returncode:
        sys.stderr.write(out.stderr)
        raise SystemExit("module generator failed")
    d, labs = {}, []
    for ln in out.stdout.splitlines():
        lm = re.match(r'^KX_([0-9A-F]{6}):$', ln.strip())
        if lm:
            labs.append(int(lm.group(1), 16))
            continue
        m = re.search(r';\s*([0-9A-F]{6})\s\s(.*)$', ln)
        if m:
            d[int(m.group(1), 16)] = m.group(2).replace("   [llvm-mc cannot encode this]", "")
    return d, labs


def classify():
    ents, xfer, spans = mm.entries(START, END)
    routines, arms = [], []
    for a in ents:
        sites = xfer.get(a, [])
        has_link = mm.IMG[a - mm.BASE:a - mm.BASE + 2] == b"\xee\x0c"
        (routines if (sites or has_link) else arms).append(a)
    return routines, arms, xfer, spans


def names(routines):
    return {a: SPECIAL.get(a, "sub_%06X" % a) for a in routines}


def block_comment(routines, arms, xfer, spans):
    """The standard block comment: every number in it produced here, from the ROM."""
    import prom_c_jumptables as jt
    from collections import Counter
    labelled = source_routines()
    ins = sum(len([s for s in v if START <= s < END]) for k, v in xfer.items()
              if START <= k < END)
    outs = []
    for k, v in xfer.items():
        if START <= k < END:
            outs += [s for s in v if not (START <= s < END)]
    tally = Counter()
    for s in outs:
        e = enclosing(s, labelled)
        tally[(e.split("__")[0] if e else "(caller not yet converted)")] += 1
    tabs = [(t, g, n) for _, t, g, n, _ in jt.tables() if START <= t < END]
    L = []
    L.append("")
    L.append("; " + "=" * 78)
    L.append("; 0x%06X-0x%06X -- %d routines, %d computed-goto arm(s), %d table(s), %s bytes"
             % (START, END - 1, len(routines), len(arms), len(tabs), "{:,}".format(END - START)))
    L.append("; " + "=" * 78)
    L.append(";")
    import prom_c_module_map as _mm
    prev = _mm.IMG[START - _mm.BASE - 1]
    head = _mm.IMG[START - _mm.BASE:START - _mm.BASE + 2]
    tail = _mm.IMG[END - _mm.BASE - 1]
    nxt = _mm.IMG[END - _mm.BASE:END - _mm.BASE + 2]
    L.append("; Boundaries, read off the bytes rather than asserted:")
    L.append(";   0x%06X = 0x%02X%s   0x%06X = %s%s"
             % (START - 1, prev, " (`ret`)" if prev == 0x0E else " (NOT `ret`)",
                START, " ".join("%02X" % b for b in head),
                " (`link XIZ`)" if head == b"\xee\x0c" else " (NOT a `link XIZ` prologue)"))
    L.append(";   0x%06X = 0x%02X%s   0x%06X = %s%s"
             % (END - 1, tail, " (`ret`)" if tail == 0x0E else " (NOT `ret`)",
                END, " ".join("%02X" % b for b in nxt),
                " (`link XIZ`)" if nxt == b"\xee\x0c" else " (NOT a `link XIZ` prologue)"))
    L.append(";   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between")
    L.append(";   routines; anything else on those lines is a cut that needs reading.")
    L.append(";")
    L.append("; Call census (`python3 notes/prom_c_module_map.py 0x%06X 0x%06X`):"
             % (START, END))
    L.append(";   %d literal call site(s) from outside this block, %d from inside it."
             % (len(outs), ins))
    for name, k in tally.most_common(10):
        L.append(";       %4d  %s" % (k, name))
    if len(tally) > 10:
        L.append(";       ... and %d further caller(s)" % (len(tally) - 10))
    L.append(";   ⚠ Sites in code that is still `.incbin` are counted under")
    L.append(";   \"(caller not yet converted)\"; that row shrinks as conversion proceeds,")
    L.append(";   so every named row is a FLOOR.")
    L.append(";")
    if tabs:
        L.append("; Computed-goto tables (`python3 notes/prom_c_jumptables.py 0x%06X 0x%06X`):"
                 % (START, END))
        for t, g, n in tabs:
            L.append(";   0x%06X  %d entries -- the `cp rr,%d` guard and the contents walk"
                     % (t, n, g))
            L.append(";             both give %d, and the word after the last entry is not a"
                     % n)
            L.append(";             plausible one.  Emitted as `.long`, not decoded.")
    else:
        L.append("; No computed-goto table: `python3 notes/prom_c_jumptables.py 0x%06X 0x%06X`"
                 % (START, END))
        L.append(";   prints none, so the whole range is decoded linearly.")
    L.append(";")
    L.append("; ★ DECODE ALIGNMENT.  notes/gen_prom_c_block.py requires every")
    L.append(";   call/calr/jp/jrl/jr target that a DECODED INSTRUCTION in this file names")
    L.append(";   and that lands inside this range to be the start of a listing line.  A")
    L.append(";   byte round trip cannot show that -- a misaligned decode of data can")
    L.append(";   re-encode to the same bytes -- so this is the test that says the listing")
    L.append(";   was read at the right offsets, and it is what found the BC-form jump")
    L.append(";   table at 0xFAF08F that the table scanner had missed.")
    L.append(";")
    L.append("; ⚠ NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Each header states the frame")
    L.append(";   size, the argument slots read, the absolute addresses read and written,")
    L.append(";   the routines called and the call sites -- operands and decoded-instruction")
    L.append(";   scans, nothing interpreted.")
    L.append(";")
    L.append("; ★ REGENERATE:")
    L.append(";     python3 notes/gen_prom_c_block.py --start 0x%06X --end 0x%06X > /tmp/b.s"
             % (START, END))
    L.append(";     python3 notes/gen_prom_c_block_headers.py --start 0x%06X --end 0x%06X \\"
             % (START, END))
    L.append(";         --labels > /tmp/b.labels")
    L.append(";     python3 notes/gen_prom_c_block_headers.py --start 0x%06X --end 0x%06X \\"
             % (START, END))
    L.append(";         --headers > /tmp/b.headers")
    L.append(";     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \\")
    L.append(";         /tmp/b.headers > /tmp/b.final.s")
    L.append(";     python3 notes/prom_c_verify_fragment.py c 0x%06X /tmp/b.final.s" % START)
    L.append("; " + "=" * 78)
    return "\n".join(L) + "\n"


def main():
    want_labels = "--labels" in sys.argv
    want_headers = "--headers" in sys.argv
    want_block = "--blockcomment" in sys.argv
    routines, arms, xfer, spans = classify()
    nm = names(routines)
    labelled = source_routines()
    txt, KX_LABELS = listing()

    if want_block:
        sys.stdout.write(block_comment(routines, arms, xfer, spans))
        return 0

    if want_labels:
        # the label set is exactly: the labels prom_c_listing_prep.py emitted (branch
        # targets), plus every routine entry, plus every computed-goto arm.  Routine
        # entries get their name; everything else becomes <owner>__ADDR, so a branch
        # into the middle of a routine reads as such.
        owners = sorted(routines)
        for a in sorted(set(KX_LABELS) | set(routines) | set(arms)):
            if a in nm:
                print("%06X %s" % (a, nm[a]))
            else:
                own = max((r for r in owners if r <= a), default=START)
                print("%06X %s__%06X" % (a, nm.get(own, "sub_%06X" % own), a))
        return 0

    if not want_headers:
        print(__doc__)
        return 2

    order = sorted(routines)
    for k, a in enumerate(order):
        nxt = order[k + 1] if k + 1 < len(order) else END
        body = {x: t for x, t in txt.items() if a <= x < nxt}
        frame = None
        m = re.match(r'link XIZ,0x([0-9a-f]{4})', txt.get(a, ""))
        if m:
            v = int(m.group(1), 16)
            frame = v - 0x10000 if v >= 0x8000 else v
        args, calls, wr, rd = set(), [], set(), set()
        for x in sorted(body):
            t = body[x]
            for s in re.findall(r'\(XIZ\+0x([0-9a-f]{2})\)', t):
                if int(s, 16) < 0x80:
                    args.add(int(s, 16))
            for s in re.findall(r'\b(?:call|calr)\s+(?:T,)?0x([0-9a-f]{6})', t):
                calls.append(int(s, 16))
            for s in re.findall(r'ld\w*\s+\(0x([0-9a-f]{4,8})\)', t):
                wr.add(int(s, 16))
            for s in re.findall(r'\(0x([0-9a-f]{4,8})\)', t):
                rd.add(int(s, 16))
        rd -= wr
        sites = xfer.get(a, [])
        ins = [s for s in sites if START <= s < END]
        outs = [s for s in sites if not (START <= s < END)]
        arms_here = [x for x in arms if a <= x < nxt]

        print("@@ 0x%06X" % a)
        print("; --------------------------------------------------------------------------")
        print("; %s -- 0x%06X..0x%06X (%d bytes)" % (nm[a], a, nxt - 1, nxt - a))
        print(";")
        if outs:
            named = []
            for s in outs:
                e = enclosing(s, labelled)
                named.append("0x%06X%s" % (s, (" in " + e) if e else ""))
            print("; Called from: %d site(s) outside this module:" % len(outs))
            for j in range(0, len(named), 2):
                print(";          " + ", ".join(named[j:j + 2]))
        else:
            print("; Called from: no site outside this module.")
        if ins:
            print(";          %d site(s) inside this module:" % len(ins))
            for j in range(0, len(ins), 6):
                print(";          " + " ".join("0x%06X" % s for s in ins[j:j + 6]))
        if not sites:
            print(";          ⚠ NOT FOUND -- no literal call/calr/jp reaches this address"
                  " anywhere")
            print(";          in the image.  A register-indirect call would be invisible to"
                  " that")
            print(";          scan, so this is \"not found\", not \"dead\".")
        if frame is not None:
            print("; Inputs:  frame `link XIZ,%d`%s"
                  % (frame, ("; argument slots read: "
                             + ", ".join("(XIZ+0x%02X)" % s for s in sorted(args)))
                     if args else "; no positive frame slot is read"))
        elif args:
            print("; Inputs:  no frame; argument slots read: "
                  + ", ".join("(XIZ+0x%02X)" % s for s in sorted(args)))
        else:
            print("; Inputs:  no frame and no argument slot read.")
        if wr:
            print("; Outputs: writes " + ", ".join("0x%06X" % v for v in sorted(wr)))
        else:
            print("; Outputs: no absolute-addressed write.")
        if rd:
            print(";          reads " + ", ".join("0x%06X" % v for v in sorted(rd)))
        if calls:
            uniq = sorted(set(calls))
            shown = []
            for c in uniq:
                if is_unconverted(c) and not (START <= c < END):
                    shown.append("0x%06X (UNCONVERTED)" % c)
                elif START <= c < END:
                    shown.append("0x%06X = %s" % (c, nm.get(c, "in-module")))
                else:
                    shown.append("0x%06X = %s" % (c, labelled.get(c, "converted")))
            for j in range(0, len(shown), 2):
                print(("; Calls:   " if j == 0 else ";          ") + ", ".join(shown[j:j + 2]))
        if arms_here:
            print("; Arms:    %d computed-goto arm(s) inside this routine: %s"
                  % (len(arms_here), " ".join("0x%06X" % x for x in arms_here)))
        for extra in EXTRA.get(a, []):
            print(extra)
        print("; Evidence: the listing below is the byte-identical round-trip of"
              " 0x%06X-0x%06X" % (a, nxt - 1))
        print(";          (notes/gen_prom_c_block.py, cleared by")
        print(";          notes/prom_c_verify_fragment.py before insertion).  Every field"
              " above")
        print(";          is an instruction operand, listed by"
              " notes/gen_prom_c_block_headers.py;")
        print(";          the call sites are notes/prom_c_module_map.py's image-wide scan.")
        if a in EXTRA:
            print("; Unknown:  what the field it switches on MEANS, and what any of the six"
                  " arms")
            print(";          does.  The name states the operand, not a purpose.")
        else:
            print("; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a"
                  " field,")
            print(";          so the name is an address.")
        print("; --------------------------------------------------------------------------")
    return 0


if __name__ == "__main__":
    sys.exit(main())
