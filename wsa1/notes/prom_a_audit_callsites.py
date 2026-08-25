#!/usr/bin/env python3
"""Does every address a prom_a "Called from:" line names actually START a transfer
to that routine -- and if not, WHICH nearby address does?

WHY THIS EXISTS
  The round-2 audit's closing paragraph: "three of the four worst findings are
  address and identity claims in prose that no committed script reads.  prom_c
  has the one tool that closes that hole (notes/prom_c_audit_callsites.py) and
  prom_c is the image whose new citations came through at 148-for-149.  prom_a
  and prom_b have no such tool, and both shipped defects of exactly the kind it
  detects."  This is prom_a's.

  The defect is systematic, not careless: a reference scan matches the 24-bit
  LITERAL, and the instruction that owns the literal begins one or two bytes
  EARLIER (`1D lo mid hi` -> the `call` is at the 0x1D).  Copying a scan's
  address into a header is therefore wrong by default, and the byte gate is
  blind to it.

  ⚠ AND THE CHECKER MUST NOT KNOW THE ANSWER.  F2's checker hard-coded the +1
  values it was meant to catch, so it could never fail.  This one decodes from
  the ROM and knows nothing about any header's claim.

WHAT IT DOES
  1. parses prom_a/wsa1_prom_a.s for `; Called from:` blocks, collecting every
     0xXXXXXX address named before the block's next `; Inputs:`/`; Evidence:`
     line (the same block shape prom_c's tool uses, so the two are comparable);
  2. takes the routine's own address from the `; ADDR` comment on the first
     instruction line after its label;
  3. disassembles ONE instruction at each cited address -- in prom_a or prom_b,
     chosen by range, because prom_a routines are called from both -- and checks
     it is a call/calr/jp/jr/jrl whose target is that routine;
  4. when it is not, it RE-DECODES at addr-1 and addr-2 and says whether one of
     those is the instruction.  "cited one byte past the instruction" then
     appears in the output as a diagnosis instead of having to be noticed.

  Rows that do not check out are a list to READ, not a failure: a header may
  legitimately cite a POINTER-TABLE entry, a directory slot's data word, or a
  site that reaches the routine through a register.  Say which, in the header.

★ AND `Called from:` IS NOT WHERE MOST OF THE ADDRESSES ARE.
  Round-2 audit F3: "the 654 dispatch slots, the three bitmaps, the 17 KB name
  table, the boot sector and the MBR carry `Read by:` / `Evidence:` citations
  that NO TOOL IN THIS TREE CHECKS", and only 4 of that round's ~35 new labels
  appeared in the default run at all.  `--evidence` closes that hole.  It takes
  EVERY 0xXXXXXX in EVERY header field except `Called from:` and asks one
  objective question of each: **is it an instruction boundary of this source?**
  No mnemonic matching, no guessing what the prose meant -- the source's own
  address comments are what the byte gate re-derives, so "0xABCDEF is not a
  boundary but 0xABCDEE is" is a fact about the ROM, and it is exactly the
  shape of the defect this tree keeps shipping (a scan matches the 24-bit
  literal; the instruction begins one or two bytes earlier).
  Rows are classified, and only OFF-BY-N is automatically a defect:
    INSTR       the citation is an instruction boundary               -- fine
    DATA        it is the first byte of an emitted .byte/.long/.ascii -- fine,
                that is what a table-base citation looks like
    OFF-BY-N    it lands INSIDE an instruction; the instruction is N bytes
                earlier                                              -- DEFECT
    IN-DATA     it lands inside a data directive, N bytes past its start -- read
                it: a citation into the middle of a record is often deliberate
    INCBIN      still unconverted, so the source cannot say           -- unknown
    prom_b      out of this image; `notes/prom_b_audit_callsites.py --evidence`
    non-ROM     below 0xF00000 -- a RAM or SFR address, not checkable here

RUN
  python3 notes/prom_a_audit_callsites.py
  python3 notes/prom_a_audit_callsites.py --quiet   # only rows that did not check out
  python3 notes/prom_a_audit_callsites.py --evidence
  python3 notes/prom_a_audit_callsites.py --evidence --quiet
  python3 notes/prom_a_audit_callsites.py --selftest
Exit status is non-zero only for --selftest failures.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
A_BASE, B_BASE = 0xF80000, 0xF00000
IMGS = {
    "a": (A_BASE, open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()),
    "b": (B_BASE, open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()),
}

ADDR = re.compile(r'0x([0-9A-Fa-f]{6,8})(?![0-9A-Fa-f])')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
INSTR_ADDR = re.compile(r';\s*([0-9A-F]{6})\s')
SECTION = re.compile(r';\s*(Inputs|Outputs|Evidence|Unknown|Note|Packet|Dispatch|Reads|Writes):')
XFER = re.compile(r'\b(call|calr|jp|jrl|jr)\b')


def which(addr):
    for k, (base, img) in IMGS.items():
        if base <= addr < base + len(img):
            return k
    return None


def dis1(addr):
    """The single instruction starting at `addr`, as unidasm prints it."""
    k = which(addr)
    if k is None:
        return None
    base, img = IMGS[k]
    off = addr - base
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(img[off:off + 12])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    out = p.stdout.splitlines()
    return out[0] if out else None


def le(addr, n):
    """The n-byte little-endian word at `addr`, or None if outside both images."""
    k = which(addr)
    if k is None:
        return None
    base, img = IMGS[k]
    o = addr - base
    if o + n > len(img):
        return None
    return int.from_bytes(img[o:o + n], "little")


TARGET = re.compile(r'0x([0-9a-f]{6})\b')
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018


def xfer_target(text):
    """The printed target of a transfer instruction, or None."""
    if not text:
        return None
    body = text.split(":", 1)[1] if ":" in text else text
    if not XFER.search(body):
        return None
    m = TARGET.search(body)
    return int(m.group(1), 16) if m else None


def classify(at, ra):
    """Why does the cited address `at` not decode to a transfer to `ra`?

    Returns (tag, note).  The tags that are NOT defects are stated as such:
      POINTER   the 24/32-bit word AT the citation IS the routine address --
                a pointer-table or vector-table entry, legitimately cited
      THUNK     that word is an address whose instruction transfers to `ra` --
                the citation is a table slot one indirection away
      VIA-DIR   the instruction here calls a prom_b DIRECTORY slot whose own
                `jp` lands on `ra`.  This is how nearly every cross-module call
                in the machine is spelled, so it is a CORRECT citation, not a
                defect -- added 2026-08-25 after round-2 audit F9 showed the
                tool was reporting ~30 of them as unresolved
      VIA-JP    the instruction here transfers to some other address whose own
                instruction transfers to `ra` -- a two-hop veneer, also correct
      RAM SLOT  the citation is a RAM address (0x600000-0x6FFFFF): a runtime
                function-pointer slot, outside both ROM images by construction
      OFF BY n  the instruction that transfers to `ra` starts n bytes EARLIER;
                this is the defect this script exists for
      ??        none of the above: read the header
    """
    for n in (3, 4):
        if (le(at, n) or 0) & 0xFFFFFF == ra:
            return "POINTER", "the %d-byte word here IS 0x%06X" % (n, ra)
    for n in (3, 4):
        w = (le(at, n) or 0) & 0xFFFFFF
        if w and w != ra and reaches(dis1(w), ra):
            return "THUNK", "-> 0x%06X, which transfers to 0x%06X" % (w, ra)
    t = xfer_target(dis1(at))
    if t is not None and t != ra:
        if THUNK_LO <= t < THUNK_HI and reaches(dis1(t), ra):
            return "VIA-DIR", "-> directory slot T_%06X -> 0x%06X" % (t, ra)
        if reaches(dis1(t), ra):
            return "VIA-JP", "-> 0x%06X -> 0x%06X" % (t, ra)
    if which(at) is None and 0x600000 <= at < 0x700000:
        return "RAM SLOT", "runtime function-pointer slot in RAM"
    for d in (1, 2):
        if reaches(dis1(at - d), ra):
            return "OFF BY %d" % d, "the instruction is at 0x%06X" % (at - d)
    return "??", ""


def reaches(text, target):
    """Is `text` a transfer whose printed target is `target`?"""
    if not text:
        return False
    body = text.split(":", 1)[1] if ":" in text else text
    return bool(XFER.search(body)) and ("%06x" % target) in body.lower()


def cited_blocks(path):
    """[(name, routine_addr, {label_addr, ...}, [cited addresses])] from a .s file.

    ⚠ A routine's extent, not just its first label.  A header often introduces
    SEVERAL labels -- an alternate entry two bytes in, a `__jrentry`, a tail --
    and its `Called from:` line cites the callers of whichever of them they call.
    Taking only the first label turns every such citation into a false "??".  So
    every label between the header and the NEXT `; -----` header separator is
    collected, and a transfer to any of them counts.

    ⚠ AND THAT MAKES THE TOOL CONSERVATIVE WHERE HEADERS ARE SPARSE.  In a run
    of unnamed `sub_XXXXXX` routines with no separators between them, the extent
    swallows all of them, so a citation of any one is filtered out as "a label
    of this routine" and never checked.  Measured case: Disk_PortA3_Release's
    header cites 0xFE1CC4 and this tool prints no row for it (0xFE1CC4 is a
    `calr` to the routine -- verified by hand).  The failure mode is a MISSING
    row, never a wrong one, but it means the checked count is a lower bound.
    """
    lines = open(path, encoding="utf-8").read().splitlines()
    out, i = [], 0
    sep = re.compile(r'^;\s*-{10,}')
    while i < len(lines):
        if "; Called from:" not in lines[i]:
            i += 1
            continue
        # 1. the citations, to the end of this header field
        cites, j = [], i
        while j < len(lines) and lines[j].lstrip().startswith(";"):
            if j > i and SECTION.search(lines[j]):
                break
            cites += [int(m, 16) & 0xFFFFFF for m in ADDR.findall(lines[j])]
            j += 1
        # 2. the routine's extent: every label up to the next header separator
        labels, first, name = set(), None, None
        k = j
        while k < len(lines):
            if sep.match(lines[k]) and labels:
                break
            m = LABEL.match(lines[k])
            if m:
                for q in range(k + 1, min(k + 6, len(lines))):
                    mm = INSTR_ADDR.search(lines[q])
                    if mm:
                        at = int(mm.group(1), 16)
                        labels.add(at)
                        if first is None:
                            first, name = at, m.group(1)
                        break
            k += 1
        if first is not None:
            out.append((name, first, labels, [c for c in cites if c not in labels]))
        i = j
    return out


def selftest():
    """Negative controls: the checker must FAIL on a known-bad citation and the
    off-by-one diagnosis must FIRE on one, or it is not testing anything."""
    fails = []

    def t(msg, cond):
        print("  %-64s %s" % (msg, "ok" if cond else "FAIL"))
        if not cond:
            fails.append(msg)

    # 0xF830C6 is called by nothing; 0xF84000's Get family is called from the
    # instance bank.  Take a real `call` and its operand, from the ROM.
    a_img = IMGS["a"][1]
    site = None
    for off in range(0x42DF, 0x4C6C):                 # the ring instance bank
        if a_img[off] == 0x1D:
            tgt = a_img[off + 1] | a_img[off + 2] << 8 | a_img[off + 3] << 16
            if 0xF84000 <= tgt <= 0xF842DE:
                site = (A_BASE + off, tgt)
                break
    t("found a real `call` site inside the ring instance bank", site is not None)
    if site:
        at, tgt = site
        t("the instruction address decodes to a transfer to its target",
          reaches(dis1(at), tgt))
        t("NEGATIVE CONTROL: the SAME site cited one byte late does NOT",
          not reaches(dis1(at + 1), tgt))
        t("and the -1 re-decode diagnoses it", reaches(dis1(at + 1 - 1), tgt))
    # --evidence's classifier, and its NEGATIVE CONTROL.  A known instruction
    # must classify INSTR and the byte after it must classify OFF-BY-1; if the
    # second passed as INSTR the mode would be measuring nothing.
    starts, ents, spans = source_map()
    import bisect

    def klass(at):
        if at in ents:
            return "DATA" if ents[at][1] else "INSTR"
        j = bisect.bisect_right(starts, at) - 1
        if j >= 0 and starts[j] <= at < starts[j] + ents[starts[j]][0]:
            return ("IN-DATA" if ents[starts[j]][1]
                    else "OFF-BY-%d" % (at - starts[j]))
        return "no line"

    t("--evidence: 0xF95A05 (`add XBC,0x00F95D15`) classifies INSTR",
      klass(0xF95A05) == "INSTR")
    t("--evidence NEGATIVE CONTROL: 0xF95A07, two bytes in, classifies OFF-BY-2",
      klass(0xF95A07) == "OFF-BY-2")
    t("--evidence: a data-directive base classifies DATA",
      klass(0xFEB330) == "DATA")
    t("--evidence: an address inside a still-.incbin span is not claimed",
      klass(0xFAD900) == "no line"
      and any(lo <= 0xFAD900 < hi for lo, hi in spans))
    t("an address in prom_b is routed to the prom_b image", which(0xF41CD0) == "b")
    t("an address in prom_a is routed to the prom_a image", which(0xF84000) == "a")
    t("an address in neither is rejected", which(0x001234) is None)
    print("SELFTEST %s" % ("PASS" if not fails else "FAIL: %d" % len(fails)))
    return 1 if fails else 0


SRC_LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(\s|$)')
INCBIN_D = re.compile(r'\.incbin\s+"original_ROMs/wsa1_prom_a\.ic12",\s*'
                      r'0x([0-9A-Fa-f]+),\s*0x([0-9A-Fa-f]+)')
DIRECTIVE = re.compile(r'^\.(byte|short|long|ascii|asciz|fill|space)\b')


DIR_ADDR = re.compile(r'^\t(\.(?:byte|short|long|ascii|asciz)\b.*?)\s*;\s*'
                      r'([0-9A-F]{6})\b')


def directive_len(txt):
    """How many BYTES a `.byte` / `.short` / `.long` / `.ascii` line emits.

    ⚠ This is a source-text count, not a ROM count, and it is the only place
    this mode could silently mis-frame a data region -- so it is deliberately
    strict: anything it does not recognise returns None and the citation is
    reported as `no line` rather than being given a made-up extent.
    """
    m = re.match(r'\.(byte|short|long)\s+(.*)$', txt)
    if m:
        w = {"byte": 1, "short": 2, "long": 4}[m.group(1)]
        body = m.group(2).split(";")[0]
        return w * len([x for x in body.split(",") if x.strip()])
    m = re.match(r'\.ascii[z]?\s+"(.*)"\s*$', txt)
    if m:
        return len(m.group(1).encode("latin1", "replace")) + (
            1 if txt.startswith(".asciz") else 0)
    return None


def source_map():
    """(sorted starts, {start: (len, is_data, text)}, [(lo, hi) still .incbin]).

    Two kinds of line carry an address: an INSTRUCTION line, whose comment also
    carries its raw bytes, and a DATA directive, whose comment carries only the
    address.  Both are mapped -- an earlier draft of this mode read only the
    first, and 571 citations into the splash bitmaps and the name table came
    back as "no source line covers this address" when the source covers them
    perfectly well.
    """
    ents, spans = {}, []
    for line in open(SRC, encoding="utf-8"):
        m = INCBIN_D.search(line)
        if m:
            off, ln = int(m.group(1), 16), int(m.group(2), 16)
            spans.append((A_BASE + off, A_BASE + off + ln))
            continue
        raw = line.rstrip("\n")
        m = SRC_LINE.match(raw)
        if m:
            txt = m.group(1).strip()
            ents[int(m.group(2), 16)] = (len(m.group(3).split()),
                                         bool(DIRECTIVE.match(txt)), txt)
            continue
        m = DIR_ADDR.match(raw)
        if m:
            txt = m.group(1).strip()
            n = directive_len(txt)
            if n:
                ents[int(m.group(2), 16)] = (n, True, txt[:60])
    return sorted(ents), ents, spans


HDR_FIELD = re.compile(r';\s*Called from:')
RANGE = re.compile(r'0x([0-9A-Fa-f]{6,8})\s*(?:[-\u2013]|to)\s*'
                   r'0x([0-9A-Fa-f]{6,8})')
ACK_WORDS = ("not an instruction", "not instruction boundaries",
             "not a boundary", "not boundaries", "coincidence",
             "bytes past", "byte past", "lie inside", "lies inside",
             "cannot be entry points", "second byte of", "third byte",
             "fourth byte", "last byte", "the last of", "byte before",
             "middle bytes", "low halves", "is not pinned",
             "not pinned as the start", "resynchronise",
             "not an entry point", "and wrong", "operand at",
             "does not exist", "cited an instruction", "link group")
LONG_LIT = re.compile(r'0x00[0-9A-Fa-f]{6}(?![0-9A-Fa-f])')


def evidence_citations():
    """[(routine_name, field, cited_addr, source_line_no)] for every address in
    a header field OTHER than `Called from:`."""
    lines = open(SRC, encoding="utf-8").read().splitlines()
    out, name, field = [], "(file header)", "(preamble)"
    # ⚠ strip the leading `; ` before joining, or a keyword that straddles a
    # line break ("... are not / ; instruction boundaries ...") never matches.
    # ⚠ and COLLAPSE WHITESPACE: this file indents continuation lines deeply, so
    # a keyword split across a line break arrives as "third<23 spaces>byte" and
    # matches nothing.  That cost one false OFF-BY-N before it was noticed.
    lows = [re.sub(r'\s+', ' ', re.sub(r'^\s*;\s?', '', l)).lower().strip()
            for l in lines]
    for i, ln in enumerate(lines, 1):
        st = ln.lstrip()
        if not st.startswith(";"):
            m = LABEL.match(ln)
            if m:
                name = m.group(1)
            continue
        m = SECTION.search(ln)
        if m:
            field = m.group(1)
        elif HDR_FIELD.search(ln):
            field = "Called from"
        elif re.search(r';\s*(Called from|Read by|Blitted by|Written by|'
                       r'Referenced by|Used by):', ln):
            field = "Called from"
        elif re.match(r';\s*-{10,}', ln):
            field = "(header)"
        if field == "Called from":
            continue
        # ★ Range ENDS are not citations of an instruction.  "0xF85606-0xF856EB
        # 230  the kernel: idle loop, ..." names an INCLUSIVE last byte, which
        # lands inside the final instruction by construction.  A first draft of
        # this mode reported 93 OFF-BY-N and most of them were this.  They are
        # still checked, but against the right question: is the cited byte the
        # LAST byte of something the source emits?
        # A range may straddle a line break ("0xF85917-" / "; 0xF85922 is ..."),
        # so the previous comment line is prepended before matching.
        bare = re.sub(r'^\s*;\s?', '', ln)
        joined = (re.sub(r'^\s*;\s?', '', lines[i - 2]) + " " + bare) \
            if i >= 2 else bare
        ends, begins = set(), set()
        for m in RANGE.finditer(joined):
            begins.add(int(m.group(1), 16) & 0xFFFFFF)
            ends.add(int(m.group(2), 16) & 0xFFFFFF)
        # ★ An "acknowledged" citation is one whose own paragraph SAYS the
        # address is not an instruction boundary -- "0xFC61C4 is not an
        # instruction -- it is the second byte of ...", "all five lie INSIDE the
        # 16-byte veneers and are not instruction boundaries of them".  Those
        # are the tool WORKING, not the tree being wrong, so they are counted
        # separately.  The keyword list is printed by the mode so a reader can
        # see exactly what was set aside; it is deliberately narrow.
        ctx = " ".join(lows[max(0, i - 4):i + 3])
        ack = any(k in ctx for k in ACK_WORDS)
        # A citation written as a full 32-bit literal (0x00FB7048) is a DATA
        # WORD being quoted -- a pointer inside a record, a directory slot's
        # value -- not a claim that an instruction starts there.  Heuristic,
        # and stated as one.
        longs = {int(x, 16) & 0xFFFFFF for x in LONG_LIT.findall(ln)}
        for a in ADDR.findall(ln):
            v = int(a, 16) & 0xFFFFFF
            if v in longs:
                continue
            out.append((name, field, v, i,
                        ("end" if v in ends else "start" if v in begins else ""),
                        ack))
    return out


def evidence_mode(quiet):
    starts, ents, spans = source_map()
    import bisect
    cites = evidence_citations()
    tally, rows = {}, []
    for name, field, at, lineno, role, ack in cites:
        is_end = role == "end"
        if at < 0xF00000:
            tag, note = "non-ROM", ""
        elif at < A_BASE:
            tag, note = "prom_b", "checked by notes/prom_b_audit_callsites.py"
        elif is_end:
            # An inclusive range end must be the LAST byte of an emitted line.
            j = bisect.bisect_right(starts, at) - 1
            if j >= 0 and starts[j] + ents[starts[j]][0] - 1 == at:
                tag, note = "RANGE-END", ents[starts[j]][2]
            elif any(lo <= at < hi for lo, hi in spans):
                tag, note = "INCBIN", "still unconverted"
            elif j >= 0 and starts[j] <= at < starts[j] + ents[starts[j]][0]:
                tag = "END-INSIDE-%d" % (starts[j] + ents[starts[j]][0] - 1 - at)
                note = ("the range ends %d byte(s) before the end of `%s` at "
                        "0x%06X" % (starts[j] + ents[starts[j]][0] - 1 - at,
                                    ents[starts[j]][2], starts[j]))
            else:
                tag, note = "no line", "no source line covers this address"
        elif at in ents:
            nb, isdata, txt = ents[at]
            tag, note = ("DATA" if isdata else "INSTR"), txt
        elif any(lo <= at < hi for lo, hi in spans):
            tag, note = "INCBIN", "still unconverted"
        else:
            j = bisect.bisect_right(starts, at) - 1
            if j >= 0 and starts[j] <= at < starts[j] + ents[starts[j]][0]:
                own = starts[j]
                nb, isdata, txt = ents[own]
                if isdata:
                    tag = "IN-DATA"
                elif role == "start":
                    # A range START that is not a boundary.  Legitimate when the
                    # claim is about BYTES (a byte-identical run against another
                    # image does not have to begin on an instruction); a defect
                    # when the claim is about code.  Separated so it is read,
                    # not counted as the citation defect.
                    tag = "START-INSIDE-%d" % (at - own)
                else:
                    tag = "OFF-BY-%d" % (at - own)
                note = "the %s starts at 0x%06X: %s" % (
                    "directive" if isdata else "instruction", own, txt)
            else:
                tag, note = "no line", "no source line covers this address"
        if ack and (tag.startswith("OFF-BY") or tag.startswith("END-INSIDE")
                    or tag.startswith("START-INSIDE")):
            tag = "ACK-" + tag
        tally[tag] = tally.get(tag, 0) + 1
        rows.append((name, field, at, lineno, tag, note))
    for name, field, at, lineno, tag, note in rows:
        if quiet and tag in ("INSTR", "DATA", "non-ROM", "RANGE-END"):
            continue
        print("%-34s %-9s 0x%06X  line %-7d %-13s %s"
              % (name[:34], field[:9], at, lineno, tag, note))
    print()
    print("%d address citation(s) in header fields other than `Called from:`"
          % len(rows))
    for tag in sorted(tally, key=lambda t: -tally[t]):
        print("   %-10s %4d" % (tag, tally[tag]))
    off = sum(v for k, v in tally.items() if k.startswith("OFF-BY"))
    ackd = sum(v for k, v in tally.items() if k.startswith("ACK-OFF-BY"))
    ends_in = sum(v for k, v in tally.items() if k.startswith("END-INSIDE"))
    print("OFF-BY-N %d  ★ MUST BE ZERO -- a citation that lands inside an "
          "instruction and whose own paragraph does NOT say so" % off)
    print("ACK-OFF-BY-N %d -- lands inside an instruction and the header SAYS "
          "it does (keywords: %s)" % (ackd, ", ".join(ACK_WORDS[:6]) + ", ..."))
    st = sum(v for k, v in tally.items() if k.startswith("START-INSIDE"))
    print("START-INSIDE-N %d -- a range START that is not an instruction "
          "boundary.  Legitimate for a BYTE-identity claim, a defect for a code "
          "one; each is a row to read." % st)
    print("END-INSIDE-N %d -- an inclusive range END that is not the last byte "
          "of an emitted line.  Read each: it is either a range that stops "
          "mid-instruction or a line this mode failed to frame." % ends_in)
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    quiet = "--quiet" in sys.argv
    if "--evidence" in sys.argv:
        return evidence_mode(quiet)
    rows = cited_blocks(SRC)
    n = 0
    tally = {}
    for name, ra, labels, cites in rows:
        for at in cites:
            n += 1
            txt = dis1(at)
            hit = [x for x in sorted(labels) if reaches(txt, x)]
            if hit:
                tag = "CALL" if hit[0] == ra else "CALL-ALT"
                note = "" if hit[0] == ra else "to 0x%06X, another label of this routine" % hit[0]
            else:
                tag, note = classify(at, ra)
            tally[tag] = tally.get(tag, 0) + 1
            if tag == "CALL" and quiet:
                continue
            print("%-40s -> 0x%06X  cited 0x%06X  %-8s %s%s"
                  % (name, ra, at, tag, (txt or "<outside both images>").strip(),
                     ("   " + note) if note else ""))
    print()
    print("%d headed routine(s) with a `Called from:` block, %d cited site(s) checked"
          % (len([r for r in rows if r[3]]), n))
    for tag in sorted(tally, key=lambda t: -tally[t]):
        print("   %-10s %4d" % (tag, tally[tag]))
    off = sum(v for k, v in tally.items() if k.startswith("OFF BY"))
    print("%d citation(s) are one or two bytes PAST the instruction -- the defect "
          "this script exists for" % off)
    # ★ Round-2 audit F9: prom_a used to report only the OFF-BY-N line and stay
    # silent about the citations that do not resolve at all.  State both.
    unres = tally.get("??", 0)
    print("%d citation(s) DO NOT RESOLVE (`??`) -- %.1f%% of the %d checked.  Each "
          "is a header to read, not automatically a defect, but the number belongs "
          "in every report that quotes the OFF-BY-N line."
          % (unres, 100.0 * unres / n if n else 0.0, n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
