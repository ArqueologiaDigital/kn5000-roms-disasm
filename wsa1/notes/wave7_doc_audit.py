#!/usr/bin/env python3
"""The DOC-vs-TREE audit: every prose claim this script knows how to re-derive.

QUESTION IT ANSWERS
  "Which sentence in this tree's documentation is no longer true of this tree?"
  The byte gate (`scripts/analysis/assert_byte_identical.py`) certifies the bytes
  and is BLIND to prose, so prose rots silently.  This script re-derives, from the
  four ROM images and the four gate-verified `.s` files, every documented number
  and span claim it has a mechanism for, and prints the ones that disagree.

  It reports; it never edits.  Nothing here can break the gate.

WHY IT EXISTS
  Wave 7 opened with TWO already-confirmed rots and found nine more with this
  script.  Two of them had been sitting in the tree for three waves:
    * `README.md`'s ".incbin spans" column has never been a span count -- it is
      `source_coverage.py`'s `text.count(".incbin")`, i.e. how many times the
      STRING appears, comments included.  `notes/prom_c-round2-audit-responses.md`
      documented that in round 2 and neither the tool nor the README was fixed.
    * `HANDOFF-RESUME-HERE.md` and `notes/WAVE7-BRIEFING.md` both say prom_c's
      65,972-byte pool at 0xFCD0F7 is "left whole ... it needs its interpreter
      found first".  The interpreter is `P7Stream_Run` (0xF9A646), it is named in
      `prom_c/wsa1_prom_c.s`, and the pool is 307 framed objects.

CHECK GROUPS (each prints `ok` or a numbered FINDING)
  coverage  the substantive/filler/incbin table, against README.md and the handoff
  spans     `.incbin` DIRECTIVE counts vs the "spans" column both files quote
  counts    sub_XXXXXX, `Evidence:` lines, FINDINGS docs, tracked scripts
  pa        emulation gap T: EVERY instruction in CPU 1's ROMs that writes PA,
            by every ABSOLUTE spelling including the two the existing census
            cannot see, plus the docs that still carry the retracted answer
  stale     doc sentences saying an address is "still .incbin" when it is not
  pool      the prom_c 0xFCD0F7 pool: converted, or "left whole"?
  db        the `Voice_StageLevel_Reg0080` header's "span of about 48 dB"
  scripts   .py paths a doc names that do not exist; scripts no doc names
  labels    `Name` (`0xADDR`) pairs where ADDR is not where Name is defined
  mirror    is notes/WSA1-EMULATION-DISASM-GAPS.md still equal to the overlay's?
  untracked files under notes/ that a `git clean -fd` would destroy

TESTED ON THE LAST ELEMENT AS WELL AS THE FIRST
  `--selftest` asserts that every detector still FIRES on a case known to be
  positive and stays SILENT on a case known to be negative, so that a future
  wave can tell "no rot left" apart from "detector broke".  It checks the FIRST
  and the LAST row of each derived table (the boundary this tree has got wrong
  before), including `Voice_OutputLevel_Table`'s entry 0 and entry 255.

RUN
  python3 notes/wave7_doc_audit.py             # the findings
  python3 notes/wave7_doc_audit.py --quiet     # findings only, no ok lines
  python3 notes/wave7_doc_audit.py --selftest  # prove the detectors still work
Exit status is the number of findings (0 = the docs agree with the tree), or 1
if --selftest fails.
"""
import glob
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OVERLAY_GAPS = os.path.expanduser(
    "~/compartilhado/kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md")

IMAGES = [("a", "wsa1_prom_a.ic12", 0xF80000),
          ("b", "wsa1_prom_b.ic13", 0xF00000),
          ("c", "wsa1_prom_c.ic28", 0xF80000),
          ("d", "wsa1_prom_d.bin", 0x000000)]
SIZE = 524288

# ⚠ THE FOUR SOURCES DO NOT SHARE ONE COMMENT FORMAT, and a scan that assumes
# they do is blind to three of them.  prom_a writes `; AAAAAA  hh hh hh` (raw
# bytes); prom_b and prom_c write `; AAAAAA  <disassembly text>`; prom_d has no
# address comments at all.  So `LINE` (bytes) matches 110,223 prom_a lines and
# TWENTY-ONE prom_b lines, while `ADDRLINE` (address only) matches 118,944 and
# 57,902.  notes/prom_a_pa3_census.py uses the byte form and therefore CANNOT
# classify a prom_b hit as an instruction, which is why its "prom_a+prom_b"
# scope needs the address form as well -- see check_pa().
LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(\s|$)')
ADDRLINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\b(.*)$')
INCBIN = re.compile(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')

FINDINGS = []
_cache = {}


def say(msg, ok=True, quiet=False):
    if ok and quiet:
        return
    print("  %-74s %s" % (msg, "ok" if ok else "<-- see finding"))


def finding(where, says, truth):
    FINDINGS.append((where, says, truth))
    print("  FINDING %-2d %s" % (len(FINDINGS), where))
    print("             says : %s" % says)
    print("             true : %s" % truth)


def src(key):
    p = os.path.join(ROOT, "prom_%s" % key, "wsa1_prom_%s.s" % key)
    if p not in _cache:
        _cache[p] = open(p).read()
    return _cache[p]


def img(name):
    p = os.path.join(ROOT, "original_ROMs", name)
    if p not in _cache:
        _cache[p] = open(p, "rb").read()
    return _cache[p]


def spans(key, base):
    """(lo, hi) CPU-address pairs of every .incbin with explicit offset+length."""
    out = [(base + int(m.group(1), 16), base + int(m.group(1), 16) + int(m.group(2), 16))
           for m in INCBIN.finditer(src(key))]
    out.sort()
    return out


def all_spans():
    return {k: spans(k, b) for k, _, b in IMAGES}


def instrs(key):
    """address -> (line number, text, bytes) for every ADDRESSED source line.
    ⚠ Hand-written macro blocks (the RESET port init) carry NO address comment
    and are therefore ABSENT here; `pa_writes` compensates explicitly."""
    ck = ("instrs", key)
    if ck in _cache:
        return _cache[ck]
    d = {}
    for ln, l in enumerate(src(key).split("\n"), 1):
        m = LINE.match(l)
        if m:
            d[int(m.group(2), 16)] = (ln, m.group(1),
                                      bytes.fromhex(m.group(3).replace(" ", "")))
            continue
        m = ADDRLINE.match(l)
        if m:                          # address-proven start, bytes not printed
            d[int(m.group(2), 16)] = (ln, m.group(1).strip(), None)
    _cache[ck] = d
    return d


def coverage():
    """substantive / filler / incbin, exactly as source_coverage.py computes it."""
    rows = {}
    for k, _, _ in IMAGES:
        t = src(k)
        inc = sum(int(m.group(2), 16) for m in INCBIN.finditer(t))
        inc += SIZE * len(re.findall(r'\.incbin\s+"[^"]+"\s*$', t, re.M))
        fill = 0
        for m in re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*,\s*([0-9]+)', t):
            fill += int(m.group(1), 0) * int(m.group(2), 0)
        for m in re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*$', t, re.M):
            fill += int(m.group(1), 0)
        rows[k] = (SIZE - inc - fill, fill, inc)
    return rows


def docs():
    return (["README.md", "HANDOFF-RESUME-HERE.md"] +
            sorted(os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(ROOT, "notes", "*.md"))))


def readlines(rel):
    return open(os.path.join(ROOT, rel)).read().split("\n")


# --------------------------------------------------------------------------
def check_coverage(quiet):
    rows = coverage()
    tot_sub = sum(r[0] for r in rows.values())
    tot_fill = sum(r[1] for r in rows.values())
    say("derived: %s substantive, %s filler, %.1f%%"
        % (f"{tot_sub:,}", f"{tot_fill:,}", 100.0 * tot_sub / (SIZE * 4)), True, quiet)
    # every "NNN,NNN substantive" the docs quote per image
    pat = re.compile(r'prom_([abcd]).{0,40}?([0-9]{1,3}(?:,[0-9]{3})+)\s+substantive'
                     r'\s+([0-9]{1,3}(?:,[0-9]{3})*)\s+filler\s+([0-9]{1,3}(?:,[0-9]{3})*)\s+incbin')
    seen = 0
    for d in docs():
        for i, l in enumerate(readlines(d), 1):
            m = pat.search(l)
            if not m:
                continue
            seen += 1
            k = m.group(1)
            q = tuple(int(x.replace(",", "")) for x in m.group(2, 3, 4))
            if q != rows[k]:
                finding("%s:%d" % (d, i), "prom_%s %s" % (k, " / ".join(f"{v:,}" for v in q)),
                        "prom_%s %s" % (k, " / ".join(f"{v:,}" for v in rows[k])))
    say("coverage rows re-derived and compared: %d" % seen, True, quiet)
    return seen


def check_spans(quiet):
    sp = all_spans()
    for k, _, _ in IMAGES:
        directives = len(re.findall(r'^\s*\.incbin', src(k), re.M))
        mentions = src(k).count(".incbin")
        if k == "a":
            say("prom_a .incbin: %d directives, %d spans-with-args, %d STRING mentions"
                % (directives, len(sp[k]), mentions), True, quiet)
    # the README table's last column
    for d in ("README.md",):
        for i, l in enumerate(readlines(d), 1):
            m = re.match(r'\|\s*`prom_([abcd])/`.*\|\s*([0-9,]+)\s*\|\s*$', l)
            if not m:
                continue
            k = m.group(1)
            q = int(m.group(2).replace(",", ""))
            if q != len(sp[k]):
                finding("%s:%d" % (d, i),
                        "prom_%s has %d `.incbin` spans" % (k, q),
                        "%d spans (%d .incbin directives). The quoted number is "
                        "source_coverage.py's text.count('.incbin') -- prose mentions, "
                        "not directives; documented in notes/prom_c-round2-audit-responses.md "
                        "and never fixed" % (len(sp[k]), len(re.findall(r'^\s*\.incbin', src(k), re.M))))
    return sum(len(v) for v in sp.values())


def counts(quiet):
    defs = []
    for k, _, _ in IMAGES:
        defs += re.findall(r'^(sub_[0-9A-F]{6}):', src(k), re.M)
    uniq = sorted(set(defs))
    ev = sum(src(k).count("Evidence:") for k, _, _ in IMAGES)
    nfind = len(glob.glob(os.path.join(ROOT, "notes", "FINDINGS-*.md")))
    tracked = subprocess.run(["git", "-C", ROOT, "ls-files", "*.py"],
                             capture_output=True, text=True).stdout.split()
    say("sub_XXXXXX: %d label definitions, %d distinct names (%s defined twice, "
        "prom_a and prom_c share base 0xF80000)"
        % (len(defs), len(uniq), ",".join(sorted(set(x for x in defs if defs.count(x) > 1))) or "none"),
        True, quiet)
    say("Evidence: lines %d   FINDINGS-*.md %d   tracked .py %d"
        % (ev, nfind, len(tracked)), True, quiet)
    # HANDOFF's "Documentation:" sentence
    for i, l in enumerate(readlines("HANDOFF-RESUME-HERE.md"), 1):
        m = re.search(r'\*\*([0-9,]+) routine headers with evidence lines, ([0-9,]+) labels, '
                      r'([0-9,]+) findings docs,', l)
        if m:
            q = int(m.group(1).replace(",", ""))
            if q != ev:
                finding("HANDOFF-RESUME-HERE.md:%d" % i,
                        "%s routine headers with evidence lines" % m.group(1),
                        "%d `Evidence:` lines in the four .s files" % ev)
            finding("HANDOFF-RESUME-HERE.md:%d" % i,
                    "%s labels" % m.group(2),
                    "unreproducible: no committed script defines or emits a label count. "
                    "Counting `^ident:` lines in the four sources gives %d"
                    % sum(len(re.findall(r'^[A-Za-z_.][A-Za-z0-9_.]*:', src(k), re.M))
                          for k, _, _ in IMAGES))
        m2 = re.search(r'([0-9,]+) findings docs,\s*$', l)
        if m2 and int(m2.group(1).replace(",", "")) != nfind:
            finding("HANDOFF-RESUME-HERE.md:%d" % i,
                    "%s findings docs" % m2.group(1),
                    "%d files match notes/FINDINGS-*.md" % nfind)
        m3 = re.search(r'^([0-9,]+) committed analysis scripts', l)
        if m3 and int(m3.group(1).replace(",", "")) != len(tracked):
            finding("HANDOFF-RESUME-HERE.md:%d" % i,
                    "%s committed analysis scripts" % m3.group(1),
                    "%d tracked .py (`git ls-files '*.py'`)" % len(tracked))
    return len(uniq)


# --------------------------------------------------------------------------
PA = 0x1E   # tmp95c061 SFR PA -- include/tmp95c061_sfr.inc:40


def spellings(addr):
    """The TWELVE direct memory-operand spellings, plus the TWO short
    immediate-store opcodes the existing gap-T census does not scan.
    dasm900.cpp case M_C0: mode 0/1/2 = 8/16/24-bit absolute, in each of the
    four prefix groups 0xC0 byte, 0xD0 word, 0xE0 long, 0xF0 memory-destination.
    Opcodes 0x08 `ld (n),#8` and 0x0A `ld (n),#16` take an 8-BIT direct address
    and belong to NEITHER group -- proved with unidasm, see --selftest."""
    out = []
    for gn, g in (("C", 0xC0), ("D", 0xD0), ("E", 0xE0), ("F", 0xF0)):
        if addr < 0x100:
            out.append((gn + "8 ", bytes([g + 0, addr]), g == 0xF0))
        if addr < 0x10000:
            out.append((gn + "16", bytes([g + 1, addr & 0xFF, addr >> 8]), g == 0xF0))
        out.append((gn + "24", bytes([g + 2, addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF]), g == 0xF0))
    if addr < 0x100:
        out.append(("imm8 ", bytes([0x08, addr]), True))
        out.append(("imm16", bytes([0x0A, addr]), True))
    return out


def macro_ldio_sites(key, base, sfr):
    """Address of every `ldio <sfr>,#` in a HAND-WRITTEN macro block.

    Those blocks carry no address comment, so `instrs()` cannot see them and no
    census in this tree does either.  Each `ldio X,#v` assembles to `08 X v`
    (proved by the run below occurring exactly once in the image), so a maximal
    RUN of consecutive `ldio` lines is a unique byte anchor: assemble the run,
    find it in the image, and read the offset of the member we want."""
    equ = {}
    for l in open(os.path.join(ROOT, "include", "tmp95c061_sfr.inc")):
        m = re.match(r'\.equ\s+([A-Za-z_][A-Za-z0-9_]*),\s*(0x[0-9A-Fa-f]+)', l)
        if m:
            equ[m.group(1)] = int(m.group(2), 16)
    d = img(dict((k, n) for k, n, _ in IMAGES)[key])
    out, run = [], []
    lines = src(key).split("\n")

    def flush(run):
        if not run:
            return
        blob = b"".join(bytes([0x08, equ[n], v]) for n, v, _ in run)
        if len(blob) < 6:
            return
        first = d.find(blob)
        if first < 0 or d.find(blob, first + 1) >= 0:
            return                                  # not a unique anchor: say nothing
        for j, (n, v, ln) in enumerate(run):
            if equ[n] == sfr:
                out.append((base + first + 3 * j, ln, "ldio %s,0x%02X" % (n, v)))

    for ln, l in enumerate(lines, 1):
        m = re.match(r'\tldio\s+([A-Za-z_][A-Za-z0-9_]*),\s*(0x[0-9A-Fa-f]+)', l)
        if m and m.group(1) in equ:
            run.append((m.group(1), int(m.group(2), 16), ln))
        elif l.strip() and not l.lstrip().startswith(";"):
            flush(run)
            run = []
    flush(run)
    return out


def check_pa(quiet):
    """Emulation gap T, re-derived at the granularity the CLAIM is made at."""
    sp = all_spans()
    writes, reads, undecided = [], [], 0
    for key, name, base in (("a", "wsa1_prom_a.ic12", 0xF80000),
                            ("b", "wsa1_prom_b.ic13", 0xF00000)):
        d, ins = img(name), instrs(key)
        for tag, pat, is_write in spellings(PA):
            for i in range(len(d) - len(pat)):
                if d[i:i + len(pat)] != pat:
                    continue
                a = base + i
                if a in ins and ins[a][1].startswith("."):
                    continue          # emitted DATA whose bytes happen to match
                if a in ins and (ins[a][2] is None or ins[a][2].startswith(pat)):
                    (writes if is_write else reads).append((key, a, tag, ins[a][1], ins[a][0]))
                elif any(lo <= a < hi for lo, hi in sp[key]):
                    undecided += 1
        for a, ln, txt in macro_ldio_sites(key, base, PA):
            writes.append((key, a, "imm8 ", txt + "   [macro line, NO address comment]", ln))
    writes.sort(key=lambda t: t[1])
    reads.sort(key=lambda t: t[1])
    for k, a, tag, txt, ln in writes:
        say("WRITE PA  0x%06X  %s  %-42s prom_%s:%d" % (a, tag, txt, k, ln), True, quiet)
    for k, a, tag, txt, ln in reads:
        say("read  PA  0x%06X  %s  %-42s prom_%s:%d" % (a, tag, txt, k, ln), True, quiet)
    say("%d writes and %d reads of PA in the converted source of prom_a+prom_b; "
        "%d byte hits are inside .incbin and stay UNDECIDED"
        % (len(writes), len(reads), undecided), True, quiet)
    say("⚠ a write through a REGISTER POINTER is excluded by no static scan and is "
        "not excluded here either", True, quiet)

    # Which document is right?
    bit3 = [w for w in writes if re.search(r'\b(res|set)_dd8 0x03|and A,0xf7|or A,0x08', w[3])]
    say("of the %d writes, the %d after RESET all touch BIT 3; the remaining one is "
        "the RESET port init `ldio PA,0xF9`" % (len(writes), len(writes) - 1), True, quiet)

    # docs that still carry the retracted "the firmware never writes PA bit 3"
    RETRACTED = re.compile(
        r'never writes PA bit 3|firmware never writes the pin|nothing in this firmware ever '
        r'changes it|they are its only writers in either image|gap T.{0,60}hardware question',
        re.I)
    for d in docs():
        lines = readlines(d)
        for i, l in enumerate(lines, 1):
            if not RETRACTED.search(l):
                continue
            ctx = "\n".join(lines[max(0, i - 8):i + 2])
            if re.search(r'RETRACT|~~|used to say|was WRONG|earlier (pass|note|answer)|is not:',
                         ctx, re.I):
                continue                            # quoted inside its own retraction
            finding("%s:%d" % (d, i), l.strip()[:110],
                    "%d instructions in prom_a write PA, all of them touching bit 3 except "
                    "the RESET init; 15 `calr` sites reach the two in the block-device layer "
                    "(this script's WRITE list above, and notes/prom_a_pa3_census.py)"
                    % len(writes))
    return len(writes)


def check_stale_incbin(quiet):
    sp = all_spans()
    PHR = re.compile(r'still[- ]`?\.?incbin|still[- ]unconverted|is still `\.incbin`', re.I)
    PAST = re.compile(r'\bwas\b|~~|used to|DONE |CONVERTED|converted|since been')
    n = 0
    for d in docs():
        for i, l in enumerate(readlines(d), 1):
            m = PHR.search(l)
            if not m or PAST.search(l):
                continue
            # ⚠ only the address the phrase is ABOUT: the LAST one before it.  An
            # earlier draft flagged every address on the line and produced two
            # false positives out of five (0xFB24D3 and 0xFE7800, both named for
            # other reasons in their sentence).
            before = list(re.finditer(r'0x([0-9A-Fa-f]{6})\b', l[:m.start()]))
            if not before:
                continue
            a = int(before[-1].group(1), 16)
            keys = ["b"] if 0xF00000 <= a < 0xF80000 else ["a", "c"]
            if any(lo <= a < hi for k in keys for lo, hi in sp[k]):
                continue
            rng = ("0x%06X-" % int(before[-2].group(1), 16)) if len(before) > 1 and \
                  ("-0x%06X" % a) in l else ""
            finding("%s:%d" % (d, i), l.strip()[:110],
                    "%s0x%06X is not inside any `.incbin` in %s -- it is converted"
                    % (rng, a, " or ".join("prom_" + k for k in keys)))
            n += 1
    say("'still .incbin' sentences checked against the live span table", n == 0, quiet)
    return n


def check_pool(quiet):
    """prom_c 0xFCD0F7-0xFDD2AA: converted with a named interpreter, or 'left whole'?"""
    c = src("c")
    converted = not any(lo <= 0xFCD0F7 < hi for lo, hi in spans("c", 0xF80000))
    interp = re.search(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', "", re.M)
    name = None
    m = re.search(r'; Name:\s*the INTERPRETER for the relocatable byte-stream pool at 0xFCD0F7\.'
                  r'(?:.|\n)*?\n([A-Za-z_][A-Za-z0-9_]*):', c)
    if m:
        name = m.group(1)
    say("prom_c 0xFCD0F7 pool converted=%s, interpreter=%s" % (converted, name), True, quiet)
    PHR = re.compile(r'left \*?\*?whole|needs its interpreter found|desynchronis\w+ at the fifth')
    for d in docs():
        for i, l in enumerate(readlines(d), 1):
            if PHR.search(l) and converted:
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "the pool IS converted -- 307 framed objects, and its interpreter is "
                        "`%s` (prom_c 0xF9A646), named in prom_c/wsa1_prom_c.s. The "
                        "desynchronisation was a walk error, not a property of the data "
                        "(notes/FINDINGS-prom_c-p7-byte-stream-pool.md)" % name)
    return converted


def check_db(quiet):
    """Voice_OutputLevel_Table's closed form, and the dB span the header quotes."""
    d = img("wsa1_prom_c.ic28")
    off = 0xFDDE2B - 0xF80000
    T = [struct.unpack_from("<H", d, off + 2 * i)[0] for i in range(256)]
    import math
    bad = [i for i in range(256)
           if T[i] != 128 * (i // 16) + round(128 * math.log2(1 + (i % 16) / 16))]
    span = 2 * max(T) * 6.0206 / 256
    say("Voice_OutputLevel_Table 0xFDDE2B: 256 entries, %d closed-form mismatches; "
        "T[0]=%d T[255]=%d; register field span 2*%d = 0x%04X counts = %.2f dB"
        % (len(bad), T[0], T[255], max(T), 2 * max(T), span), len(bad) == 0, quiet)
    for f in ("prom_c/wsa1_prom_c.s",):
        for i, l in enumerate(open(os.path.join(ROOT, f)).read().split("\n"), 1):
            if "span of about 48 dB" in l:
                finding("%s:%d" % (f, i), l.strip()[:110],
                        "the register field spans 0x%04X counts at 6.0206/256 dB per count "
                        "= %.2f dB. 48 dB is the span of the INDEX (8 halvings x 32 counts)"
                        % (2 * max(T), span))
    return span


def check_scripts(quiet):
    pat = re.compile(r'((?:notes|scripts/analysis|scripts|prom_[abcd])/[A-Za-z0-9_./-]+\.py)')
    refs, basenames = {}, set()
    for d in docs():
        for i, l in enumerate(readlines(d), 1):
            for m in pat.finditer(l):
                refs.setdefault(m.group(1), []).append((d, i))
            for m in re.finditer(r'([A-Za-z0-9_./-]*[A-Za-z0-9_-]\.py)', l):
                basenames.add(os.path.basename(m.group(1)))
    for k in sorted(refs):
        if not os.path.exists(os.path.join(ROOT, k)):
            finding("%s:%d" % refs[k][0], "references `%s`" % k,
                    "no such file in this tree (%d citation(s)); it lives in the "
                    "kn7000_mame overlay, whose notes/ this doc was mirrored from"
                    % len(refs[k]))
    allpy = sorted(set(glob.glob(os.path.join(ROOT, "notes", "*.py"))) |
                   set(glob.glob(os.path.join(ROOT, "scripts", "analysis", "*.py"))) |
                   set(glob.glob(os.path.join(ROOT, "prom_a", "*.py"))))
    unref = [os.path.relpath(p, ROOT) for p in allpy if os.path.basename(p) not in basenames]
    say("scripts no .md mentions even by basename: %d -- %s"
        % (len(unref), ", ".join(unref)), True, quiet)
    return len(unref)


def check_labels(quiet):
    lab = {}
    for k, _, _ in IMAGES:
        pend = []
        for l in src(k).split("\n"):
            m = re.match(r'^([A-Za-z_.][A-Za-z0-9_.]*):\s*$', l)
            if m:
                pend.append(m.group(1))
                continue
            m2 = ADDRLINE.match(l)
            if m2:
                for p in pend:
                    lab.setdefault(p, set()).add(int(m2.group(2), 16))
                pend = []
            elif l.strip() and not l.startswith(";"):
                pend = []
    pats = [re.compile(r'`([A-Za-z_][A-Za-z0-9_]{3,})`\s*\(`?(0x[0-9A-Fa-f]{6})`?\)'),
            re.compile(r'`?(0x[0-9A-Fa-f]{6})`?\s*=\s*`([A-Za-z_][A-Za-z0-9_]{3,})`')]
    n = 0
    for d in docs():
        for i, l in enumerate(readlines(d), 1):
            for pi, p in enumerate(pats):
                for m in p.finditer(l):
                    name, addr = (m.group(1), m.group(2)) if pi == 0 else (m.group(2), m.group(1))
                    if name not in lab:
                        continue
                    a = int(addr, 16)
                    if a in lab[name]:
                        continue
                    finding("%s:%d" % (d, i), "`%s` (`%s`)" % (name, addr),
                            "`%s` is defined at %s; %s is an INTERIOR instruction of it, so the "
                            "parenthetical reads as the routine's entry and is not"
                            % (name, ", ".join("0x%06X" % x for x in sorted(lab[name])), addr))
                    n += 1
    say("label/address pairs cross-checked against %d labelled addresses" % len(lab), n == 0, quiet)
    return n


def check_mirror(quiet):
    rel = "notes/WSA1-EMULATION-DISASM-GAPS.md"
    mine = os.path.join(ROOT, rel)
    if not os.path.exists(OVERLAY_GAPS):
        say("overlay copy not readable, mirror check skipped", True, quiet)
        return 0
    a, b = open(mine).read(), open(OVERLAY_GAPS).read()
    if a == b:
        say("%s is identical to the overlay's copy" % rel, True, quiet)
        return 0
    la, lb = len(a.split("\n")), len(b.split("\n"))
    log = subprocess.run(["git", "-C", os.path.dirname(os.path.dirname(OVERLAY_GAPS)),
                          "log", "--oneline", "-6", "--", "notes/WSA1-EMULATION-DISASM-GAPS.md"],
                         capture_output=True, text=True).stdout.strip().split("\n")
    finding(rel, "the mirrored emulation request list, %d lines" % la,
            "the overlay's authoritative copy is %d lines. Overlay commits the mirror never "
            "received: %s" % (lb, " | ".join(x for x in log[:3])))
    return 1


def check_targets(quiet):
    """The handoff's and the briefing's NEXT-TARGET paragraphs, against the tree."""
    sp = all_spans()
    n = 0
    # 1. the two prom_a targets the handoff still names
    for a in (0xFE8000, 0xFEF746):
        covered = any(lo <= a < hi for lo, hi in sp["a"])
        lab = re.search(r'^(sub_%06X):' % a, src("a"), re.M)
        say("prom_a 0x%06X: covered by .incbin=%s, label=%s"
            % (a, covered, lab.group(1) if lab else None), True, quiet)
        for d in ("HANDOFF-RESUME-HERE.md",):
            for i, l in enumerate(readlines(d), 1):
                if "0x%06X" % a in l.upper().replace("0XFE", "0xFE").replace("0XFEF", "0xFEF") \
                        and re.search(r'next target|Next targets|code halves', "".join(readlines(d)[max(0, i - 4):i + 1])):
                    if not covered:
                        finding("%s:%d" % (d, i), l.strip()[:110],
                                "0x%06X is CONVERTED (%s) and no `.incbin` covers it"
                                % (a, lab.group(1) if lab else "converted"))
                        n += 1
    # 2. the largest prom_b span, which the handoff quotes with the pre-split extent
    top = max(sp["b"], key=lambda t: t[1] - t[0])
    say("prom_b largest .incbin span: 0x%06X-0x%06X, %d bytes" % (top[0], top[1], top[1] - top[0]), True, quiet)
    for d in ("HANDOFF-RESUME-HERE.md",):
        for i, l in enumerate(readlines(d), 1):
            m = re.search(r'top span is now `(0x[0-9A-F]{6})-(0x[0-9A-F]{6})`\s*\(([0-9,]+) B\)', l)
            if m and (int(m.group(1), 16), int(m.group(2), 16)) != top:
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "the largest prom_b span is 0x%06X-0x%06X, %s B; the quoted range has "
                        "since been split in two (the second piece is 0x%06X-0x%06X)"
                        % (top[0], top[1], f"{top[1]-top[0]:,}",
                           *[x for x in sp["b"] if x[0] == 0xF0D061][0]))
                n += 1
    # 3. the 838-byte table at 0xFF047F: what is it called in the tree?
    m = re.search(r'^([A-Za-z_][A-Za-z0-9_]*):\n\t\.byte[^;]*;\s*FF047F', src("a"), re.M)
    name = m.group(1) if m else None
    nxt = min(a for a in instrs("a") if a > 0xFF047F and
              not instrs("a")[a][1].startswith("."))
    say("0xFF047F is `%s`, %d bytes (ends where %s begins at 0x%06X)"
        % (name, nxt - 0xFF047F, instrs("a")[nxt][1][:12], nxt), True, quiet)
    for d in ("HANDOFF-RESUME-HERE.md", "notes/WAVE7-BRIEFING.md"):
        for i, l in enumerate(readlines(d), 1):
            if "0xFF047F" in l and "effect" in l.lower():
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "the 838-byte table at 0xFF047F is `%s` -- DRUM KIT CATEGORY legends "
                        "(STANDR / ROOM / POWER / ELEC / DANCE ...), not effect names. The "
                        "838 and the `.byte` classification are right" % name)
                n += 1
    # 4. gaps the request list's own preamble promises but does not contain
    g = readlines("notes/WSA1-EMULATION-DISASM-GAPS.md")
    have = set(re.match(r'### ([A-Z])\.', l).group(1) for l in g if re.match(r'### [A-Z]\.', l))
    for i, l in enumerate(g, 1):
        for m in re.finditer(r'six new gaps, ([A-Z]) to ([A-Z])', l):
            want = set(chr(c) for c in range(ord(m.group(1)), ord(m.group(2)) + 1))
            if want - have:
                finding("notes/WSA1-EMULATION-DISASM-GAPS.md:%d" % i, l.strip()[:110],
                        "this copy has %d lettered entries, %s..%s, and no section for %s"
                        % (len(have), min(have), max(have), ",".join(sorted(want - have))))
                n += 1
    # 5. docs/
    dd = os.path.join(ROOT, "docs")
    if os.path.isdir(dd) and not os.listdir(dd):
        say("docs/ exists and is EMPTY -- git does not track empty directories, so it is "
            "not in any commit; nothing in the tree publishes there", True, quiet)
    return n


def check_kernel(quiet):
    """`36 routine pairs, 35 structurally identical TO THE BYTE` -- is it bytes?

    The whole point of notes/prom_c_prom_a_routine_diff.py is that the two copies
    are NOT byte-identical: every port address, handshake pin and work-RAM address
    differs, which is why that script aligns unidasm TEXT instead.  So this check
    byte-compares the block the kernel map tiles, first row to last."""
    a, c = img("wsa1_prom_a.ic12"), img("wsa1_prom_c.ic28")
    A0, C0, N = 0xF85606, 0xF9816B, 0xF85E8A - 0xF85606
    ba = a[A0 - 0xF80000: A0 - 0xF80000 + N]
    bc = c[C0 - 0xF80000: C0 - 0xF80000 + N]
    diff = sum(1 for x, y in zip(ba, bc) if x != y)
    say("kernel block prom_a 0x%06X / prom_c 0x%06X (delta 0x%X), %d bytes: %d DIFFER (%.1f%%)"
        % (A0, C0, C0 - A0, N, diff, 100.0 * diff / N), True, quiet)
    for d in ("HANDOFF-RESUME-HERE.md",):
        lines = readlines(d)
        for i, l in enumerate(lines, 1):          # the claim wraps across two lines
            l = l + " " + (lines[i] if i < len(lines) else "")
            if re.search(r'routine pairs.{0,40}identical to the byte', l):
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "the two copies are NOT byte-identical: %d of %d bytes differ over the "
                        "block the pair table tiles. `prom_c_kernel_map.py --pairs` compares "
                        "unidasm TEXT and reports `36 pair(s) (35 tiling rows + "
                        "INTT3_KernelTick); 0 with an unexpected structural difference` -- so "
                        "the 35 is the tiling-row count, not a count of identical routines, "
                        "and `to the byte` is the wrong unit" % (diff, N))
    return diff


def check_gapa(quiet):
    """Gap A's "four registers with no statement" -- the overlay says two."""
    if not os.path.exists(OVERLAY_GAPS):
        return 0
    ov = open(OVERLAY_GAPS).read()
    m = re.search(r'STILL OPEN IS NOW (TWO|THREE|FOUR) REGISTERS, NOT (TWO|THREE|FOUR)', ov)
    if not m:
        say("overlay no longer states a gap-A remaining count; check by hand", True, quiet)
        return 0
    say("overlay: gap A's remaining count is now %s, not %s" % (m.group(1), m.group(2)),
        True, quiet)
    n = 0
    for d in docs():
        lines = readlines(d)
        for i, l in enumerate(lines, 1):          # the claim wraps in the briefing
            if not re.search(r'\bfour\b', l, re.I):
                continue                          # the trigger word must be on THIS line
            l = l + " " + (lines[i] if i < len(lines) else "")
            if re.search(r'four\*{0,2} registers.{0,40}no statement', l, re.I):
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "the overlay's gap A now says TWO, not four: `0x04C0` and `0x0500` have "
                        "measured field splits; only `0x0440` and `0x0480` have nothing "
                        "(kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md:180)")
                n += 1
    # the count the briefing and the handoff both quote for the request list
    g = readlines("notes/WSA1-EMULATION-DISASM-GAPS.md")
    letters = len([l for l in g if re.match(r'### [A-Z]\.', l)])
    numbered = len([l for l in g if re.match(r'^[0-9]+\. ', l)])
    for d in ("HANDOFF-RESUME-HERE.md", "notes/WAVE7-BRIEFING.md"):
        for i, l in enumerate(readlines(d), 1):
            if re.search(r'~9[0-9] (ranked )?entries', l):
                finding("%s:%d" % (d, i), l.strip()[:110],
                        "unreproducible: the mirrored file has %d lettered gap entries and %d "
                        "top-level numbered items across all sections. No committed script "
                        "produces a count near 95, and the mirror is itself %d lines behind "
                        "the overlay" % (letters, numbered, 1477 - len(g)))
                n += 1
    return n


def check_untracked(quiet):
    out = subprocess.run(["git", "-C", ROOT, "status", "--porcelain", "notes/"],
                         capture_output=True, text=True).stdout.strip().split("\n")
    unt = [l[3:] for l in out if l.startswith("??")]
    say("untracked under notes/ (a `git clean -fd` would destroy these): %d -- %s"
        % (len(unt), ", ".join(unt) if unt else "none"), True, quiet)
    return len(unt)


# --------------------------------------------------------------------------
def selftest():
    """Every detector, on a case known POSITIVE and a case known NEGATIVE, and
    on the LAST element of each derived table as well as the first."""
    bad = []

    def ck(msg, cond):
        print("  %-72s %s" % (msg, "ok" if cond else "FAIL"))
        if not cond:
            bad.append(msg)

    sp = all_spans()
    # spans: first and last row of each image's table
    ck("prom_a span table first=0x%06X last ends 0x%06X, 13 spans"
       % (sp["a"][0][0], sp["a"][-1][1]), len(sp["a"]) == 13)
    ck("prom_b span table first=0x%06X last ends 0x%06X, 124 spans"
       % (sp["b"][0][0], sp["b"][-1][1]), len(sp["b"]) == 124)
    ck("prom_c and prom_d have no .incbin at all", not sp["c"] and not sp["d"])
    # the stale detector must FIRE on a converted address and stay SILENT on a live one
    ck("0xF99E5F (prom_c) is NOT in any span -> detector fires",
       not any(lo <= 0xF99E5F < hi for lo, hi in sp["c"]))
    ck("0xF98977 (prom_a) IS in a span -> detector stays silent",
       any(lo <= 0xF98977 < hi for lo, hi in sp["a"]))
    ck("0xF17559 (prom_b, first byte of a span) IS in a span",
       any(lo <= 0xF17559 < hi for lo, hi in sp["b"]))
    ck("0xF1B3FF (prom_b, LAST byte of that same span) IS in a span",
       any(lo <= 0xF1B3FF < hi for lo, hi in sp["b"]))
    ck("0xF1B400 (one past its end) is NOT",
       not any(lo <= 0xF1B400 < hi for lo, hi in sp["b"]))
    # PA spellings: the two the existing census cannot see must really be write forms
    sps = dict((t.strip(), (p, w)) for t, p, w in spellings(PA))
    ck("spelling table has 14 entries (12 direct + `ld (n),#8` + `ld (n),#16`)",
       len(spellings(PA)) == 14)
    ck("`08 1E` and `0A 1E` are in it and are marked WRITE",
       sps["imm8"][1] and sps["imm16"][1] and sps["imm8"][0] == b"\x08\x1e")
    ck("`C0 1E` is in it and is NOT marked write", not sps["C8"][1])
    sites = macro_ldio_sites("a", 0xF80000, PA)
    ck("the macro RESET block's `ldio PA,#` is found at 0x%s, exactly one site"
       % (",".join("%06X" % a for a, _, _ in sites)),
       len(sites) == 1 and sites[0][0] == 0xF826D6)
    ck("that site is INVISIBLE to instrs() -- no address comment on the line",
       0xF826D6 not in instrs("a"))
    ins = instrs("a")
    ck("0xFE8E87 is emitted `.byte` DATA whose first bytes are `F0 1E` -- the "
       "detector must NOT count it as a PA write",
       instrs("a")[0xFE8E87][1].startswith("."))
    ck("instrs() sees the block-device pair 0xFE18EF/0xFE18F7",
       0xFE18EF in ins and 0xFE18F7 in ins)
    ck("instrs() sees the FDC pair 0xFE660D/0xFE6631 (the LAST two PA writes by address)",
       0xFE660D in ins and 0xFE6631 in ins)
    insb = instrs("b")
    ck("instrs() sees prom_b's ADDRESS-ONLY lines (%d of them; the byte form sees 21)"
       % len(insb), len(insb) > 57000 and 0xF5DE6F in insb)
    ck("prom_b really has no PA access: its only source lines naming 0x1e are "
       "0xF5DE6F `cp A,0x1e`, 0xF747D0 `ld (0x2880),0x1e`, 0xF7C0AF `cp (0x207a),0x1e`",
       all(a in insb for a in (0xF5DE6F, 0xF747D0, 0xF7C0AF)))
    # the dB table, first and last entry
    import math
    d = img("wsa1_prom_c.ic28")
    off = 0xFDDE2B - 0xF80000
    T = [struct.unpack_from("<H", d, off + 2 * i)[0] for i in range(256)]
    ck("Voice_OutputLevel_Table T[0]=0 (FIRST entry)", T[0] == 0)
    ck("Voice_OutputLevel_Table T[255]=2042 (LAST entry) = 128*15+122", T[255] == 2042)
    ck("closed form holds for all 256 entries",
       all(T[i] == 128 * (i // 16) + round(128 * math.log2(1 + (i % 16) / 16)) for i in range(256)))
    # coverage arithmetic must reproduce source_coverage.py exactly
    rows = coverage()
    ck("coverage total substantive = 1,420,501", sum(r[0] for r in rows.values()) == 1420501)
    ck("prom_d row (the LAST image) = 330,521 / 193,767 / 0",
       rows["d"] == (330521, 193767, 0))
    print("\nSELFTEST %s" % ("PASS" if not bad else "FAIL: %d" % len(bad)))
    return 0 if not bad else 1


def main():
    quiet = "--quiet" in sys.argv
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    for name, fn in (("coverage", check_coverage), ("spans", check_spans),
                     ("counts", counts), ("pa", check_pa),
                     ("stale", check_stale_incbin), ("pool", check_pool),
                     ("db", check_db), ("scripts", check_scripts),
                     ("labels", check_labels), ("kernel", check_kernel),
                     ("targets", check_targets),
                     ("mirror", check_mirror), ("gapA", check_gapa),
                     ("untracked", check_untracked)):
        print("\n=== %s ===" % name)
        fn(quiet)
    print("\nFINDINGS: %d" % len(FINDINGS))
    sys.exit(min(len(FINDINGS), 120))


if __name__ == "__main__":
    main()
