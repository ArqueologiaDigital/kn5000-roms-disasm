#!/usr/bin/env python3
r"""Replace NUMERIC branch/call operands with symbolic labels, in any gated image.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
CLAUDE.md's Symbolic Cross-Referencing policy says every CALL/JP/JR/JRL/CALR
operand must be a label.  Measured 2026-09-25, before this tool ran:

    tree          numeric branch operands / all branch instructions
    v10/maincpu   13,344 / 74,282        v9/maincpu   14,217 / 75,164
    v7/maincpu    19,408 / 57,528        v142/subcpu     726 /  6,997
    hdae5000         877 /  7,146        table_data       83 /  1,280
    wsa1/prom_a    7,605 / 25,208        wsa1/prom_b  18,241 / 18,411
    wsa1/prom_c    2,479 / 10,241

(the counting one-liner is in scripts/converters/README-symbolize-branches.md).

A numeric `jr z, 17` / `calr 2716` / `jrl nc, 0x0f00` is a raw PC-relative
DISPLACEMENT (verified: `jr z, 17` -> [0x66,0x11]; target = next-PC + 17), and
`call 16569399` / `jp 15728660` is an absolute 24-bit address.  So every target
is computable once each source line's address is known.

HOW
---
1. The address of every source line comes from the same marker-label mirror the
   data census uses (scripts/analysis/data_range_census.py): mirror the image's
   tree, put `__drc_<n>:` in front of every non-blank line, assemble + LINK with
   the real linker script, read the markers back with llvm-nm.  The mirror is
   proven INERT (objcopy == the original dump) or the image is refused.
2. For each numeric branch the instruction length is checked against the
   encoding the mnemonic must have (jr 2, jrl/calr 3, call/jp 4).  A mismatch
   means the line is not what the regex thinks it is; it is skipped and counted.
3. The target is classified against the emitting-line spans:
     boundary-code   the target is the first byte of an instruction line -> LABEL
     R6              ROM around the site is text or a pointer table     -> refused
     boundary-data   the first byte of a data line (.byte/.long/...)      -> LABEL,
                     and reported: a branch into data-framed bytes is evidence
                     that the bytes are code (code-as-data)
     mid-line        inside an instruction or a multi-byte data line      -> NOT
                     converted; reported as MISFRAME EVIDENCE (either the
                     branch's own decode or the target's framing is wrong)
     external        outside this image's spans (another ROM, RAM)         -> NOT
                     converted
     shared-file     the target line is in a file another image also
                     includes (wsa1 kernel/ and dsp/)                       -> NOT
                     converted (a label there would be defined in both)
4. An existing label at the target address is REUSED (descriptive names win
   over `.L`/positional ones).  Otherwise a new label is named
   `<Parent>_<Role>`, Parent = the nearest ROUTINE ENTRY above the target (a
   label some call/calr, `.long` or addr24 references), else the nearest real
   label above the EARLIEST of the target and its same-file sources -- so a
   routine-wide exit is named after the routine, not after the last case label
   before it, Role derived ONLY from structure that is checkable in the source:
     Return    the target instruction is ret/reti/retd
     Epilogue  from the target, only pops / frame drops (`inc N,xsp`,
               `lda xsp,(xsp+N)`) run until a ret
     Helper    something CALLS it and it starts a routine of its own (it
               follows a terminator or data): named after its first caller's
               routine, `<Caller>_Helper` (WSA1 house style: `sub_<ADDR>`)
     Sub       called, but inside the parent's straight-line code
     Loop      a BACKWARD CONDITIONAL branch reaches it (an unconditional
               backward jump alone is a tail-merge, not a cycle -> Join)
     Join      some source is an unconditional jr/jrl/jp (a merge point)
     Skip      every source is a forward conditional branch
     Entry     the target line is DATA-framed (see boundary-data above)
   plus a numeric suffix for uniqueness.  These are structural names, not claims
   about purpose; they replace a NUMBER, and a later pass that understands the
   routine should rename them.
5. --apply rewrites the sources (latin-1 in, latin-1 out: several of these files
   carry raw high bytes in `.ascii` and a text-mode round trip corrupts them),
   then --verify re-mirrors the MODIFIED tree and requires the linked image to
   be byte-identical to the dump.  Because every new label is used as an
   operand, a label placed one byte wrong changes the displacement the assembler
   computes and the image stops matching: the byte gate DOES protect this edit
   (unlike a bare label move, which it cannot see).

RUN
    python3 scripts/converters/symbolize_numeric_branches.py --image v10            # dry run, summary
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --apply --verify
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --report out.json
    images: v10 v9 v7 v142 subboot tabledata customdata hdae5000 prom_a prom_b prom_c prom_d

Always follow an --apply with the real gate (`make gate-all`).
"""
import argparse
import bisect
import collections
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402

BRANCH_RE = re.compile(
    r'^(?P<pre>\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?)'
    r'(?P<mn>jr|jrl|calr|call|jp)(?P<ws>\s+)'
    r'(?:(?P<cc>[a-z]+)(?P<ccsep>\s*,\s*))?'
    r'(?P<num>-?0x[0-9a-fA-F]+|-?\d+|\(\s*0x[0-9a-fA-F]+\s*-\s*0x[0-9a-fA-F]+\s*\))'
    r'(?P<post>\s*(?:;.*)?)$')
SIZE = {"jr": 2, "jrl": 3, "calr": 3, "call": 4, "jp": 4}
RET_RE = re.compile(r'^(ret|reti|retd)\b')
POP_OK = re.compile(r'^(pop\w*|ld\s+xsp|lda\s+xsp|inc\s+\d+\s*,\s*xsp|add\s+xsp|ld\s+hl\s*,\s*iz|nop)\b')
DEF_RE = re.compile(r'^\s*\.(?:set|equ|equiv)\s+([A-Za-z_.$][\w.$@]*)\s*,', re.I)
DEF2_RE = re.compile(r'^\s*([A-Za-z_.$][\w.$@]*)\s*=')
LOCALISH = re.compile(r'^(\.L|__|L_[0-9a-fA-F]+$)')


def image_by_key(key):
    for img in drc.IMAGES:
        if img["key"] == key:
            return img
    sys.exit("unknown image %r" % key)


def own_prefix(img):
    """WSA1 images share one mirror dir; only the image's own subdir may be edited."""
    if img["mirror"] == "wsa1":
        return img["root"].split("/")[0] + "/"
    return ""


def build_map(img, srcroot):
    """-> (marks, addr_of_mark, spans, rom_ok).  spans: sorted list of
    (start, end, rel, li) for EMITTING lines only (census rule)."""
    tmp = tempfile.mkdtemp(prefix="symbr-")
    try:
        mdir = os.path.join(tmp, "mirror")
        marks = drc.mirror_tree(srcroot, mdir)
        elf = drc.link_mirror(mdir, img, tmp)
        raw = os.path.join(tmp, "img.bin")
        drc.sh([drc.OBJCOPY, "-O", "binary", elf, raw])
        got = open(raw, "rb").read()
        if "split" in img:
            head, skip = img["split"]
            got = got[:head] + got[skip:]
        rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
        rom_ok = (got == rom)
        addrs = drc.marker_addresses(elf)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    src = drc.Sources(srcroot)
    macros = drc.collect_macros(srcroot)
    ent = sorted(((a, i) for i, a in addrs.items()))
    kept, k = [], 0
    while k < len(ent):
        j = k
        while j + 1 < len(ent) and ent[j + 1][0] == ent[k][0]:
            j += 1
        scored = []
        for (a, i) in ent[k:j + 1]:
            rel, li = marks[i]
            bk, _ = drc.classify_line(src.text(rel, li), macros)
            scored.append((0 if bk in ("data", "code") else 1 if bk == "fill" else 2, i, a))
        scored.sort()
        if scored[0][0] <= 1:
            kept.append((scored[0][2], scored[0][1]))
        k = j + 1
    spans = []
    for n, (a, i) in enumerate(kept):
        end = kept[n + 1][0] if n + 1 < len(kept) else a + (1 << 30)
        rel, li = marks[i]
        spans.append((a, end, rel, li))
    return marks, addrs, spans, rom_ok, src, macros


UNIDASM = os.path.join(drc.PROJECTS, "tools", "unidasm")
# R4 (refuse code glued onto data with no label between) is OFF: measured on
# v9 it refused 10,229 sites, overwhelmingly real code following `.byte`
# islands that spell instructions the backend cannot express; the case that
# motivated it (prom_a 0xFF0BF0, a display-list byte read as `jrl z`) is
# already refused by R5, because the second decoder sees no instruction there.
USE_R4 = False
UNI_LINE = re.compile(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(\S+)\s*(.*)$')


def independent_decode(img):
    """A SECOND decoder's opinion: MAME's unidasm run linearly over the dump.
    -> {addr: (mnemonic, operand_text)} for every instruction start it sees.
    A linear sweep re-synchronises within a few instructions inside real code,
    so a genuine branch is an instruction start here; a phantom branch made of
    another instruction's operand bytes is not."""
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    pieces = [(0, img["base"], rom)]
    if "split" in img:
        head, skip = img["split"]
        pieces = [(0, img["base"], rom[:head]), (head, img["base"] + skip, rom[head:])]
    out = {}
    tmp = tempfile.mkdtemp(prefix="symbr-uni-")
    try:
        for n, (_, base, blob) in enumerate(pieces):
            f = os.path.join(tmp, "p%d.bin" % n)
            open(f, "wb").write(blob)
            r = subprocess.run([UNIDASM, f, "-arch", "tlcs900", "-basepc", "0x%x" % base],
                               capture_output=True, text=True)
            for ln in r.stdout.split("\n"):
                m = UNI_LINE.match(ln)
                if m:
                    out[int(m.group(1), 16)] = (m.group(3).lower(), m.group(4).strip())
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return out


def uni_agrees(uni, s):
    """The independent decoder must see an instruction start at the site, of
    the same branch kind, whose last operand is the same absolute target."""
    d = uni.get(s["addr"])
    if not d:
        return False
    mn, ops = d
    if mn != s["mn"]:
        return False
    last = ops.split(",")[-1].strip()
    try:
        return int(last, 16) == s["target"]
    except ValueError:
        return False


def code_of(text):
    c = drc.strip_comment(text).strip()
    while True:
        m = drc.LABEL_RE.match(c)
        if not m:
            break
        c = c[m.end():].strip()
    return c


def labels_on(text):
    c = drc.strip_comment(text).strip()
    out = []
    while True:
        m = drc.LABEL_RE.match(c)
        if not m:
            break
        out.append(m.group(1))
        c = c[m.end():].strip()
    return out


def signed(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if v >= 1 << (bits - 1) else v


def label_rank(name):
    """Lower is better for reuse."""
    if name.startswith(drc.MARK):
        return 9
    if name.startswith(".L") or name.startswith("__"):
        return 5
    if re.search(r'(_|^)[0-9A-Fa-f]{6}$', name) or re.match(r'^(Data|Sub|Loc|Code|Label|LABEL)_', name):
        return 3
    return 0


def analyse(img, only=None):
    """only: optional set of source paths RELATIVE TO THE IMAGE'S MIRROR DIR;
    when given, only branches in those files are converted and labels are only
    inserted into those files (a lane edits its own files and no others)."""
    srcroot = os.path.join(ROOT, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = build_map(img, srcroot)
    if not rom_ok:
        sys.exit("%s: marked mirror is NOT byte-identical to the dump; refusing" % img["key"])
    starts = [s[0] for s in spans]
    span_of_line = {(s[2], s[3]): s for s in spans}
    prefix = own_prefix(img)

    # every label with an address, and every defined name in the tree
    label_addr = {}            # name -> addr
    labels_at = collections.defaultdict(list)   # addr -> [(rank, name, rel, li)]
    defined = set()
    rels = sorted({m[0] for m in marks})
    for rel in rels:
        for li, text in enumerate(src.lines(rel)):
            for nm in labels_on(text):
                defined.add(nm)
            m = DEF_RE.match(text) or DEF2_RE.match(drc.strip_comment(text))
            if m:
                defined.add(m.group(1))
    for i, (rel, li) in enumerate(marks):
        if i not in addrs:
            continue
        for nm in labels_on(src.text(rel, li)):
            label_addr.setdefault(nm, addrs[i])
            labels_at[addrs[i]].append((label_rank(nm), nm, rel, li))

    # which files are included by other images too (wsa1 shared dirs)
    shared = set()
    if img["mirror"] == "wsa1":
        for rel in rels:
            if not rel.startswith(prefix):
                shared.add(rel)

    # ---------------------------------------------------------------- sources
    stats = collections.Counter()
    report = collections.defaultdict(list)
    refused = report
    sites = []                  # dicts
    for (a, end, rel, li) in spans:
        if prefix and not rel.startswith(prefix):
            continue
        if only is not None and rel not in only:
            continue
        text = src.text(rel, li)
        c = drc.strip_comment(text)
        m = BRANCH_RE.match(text.rstrip("\r"))
        if not m:
            continue
        mn = m.group("mn")
        size = end - a
        stats["numeric_" + mn] += 1
        if size != SIZE[mn]:
            stats["skip_size_mismatch"] += 1
            continue
        numtxt = m.group("num")
        if numtxt.startswith("("):
            # address-difference spelling `(0xTGT - 0xNEXT)`: only trusted when
            # 0xNEXT really is the next instruction's address
            ta, tb = [int(x, 0) for x in numtxt.strip("() ").split("-")]
            if tb != a + size:
                stats["skip_difference_form_mismatch"] += 1
                continue
            v = ta - tb
        else:
            v = int(numtxt, 0)
        cc = (m.group("cc") or "").lower()
        if cc == "f":
            stats["refuse_never_taken_cc_f"] += 1
            report["never-taken"].append(dict(src="%s:%d" % (rel, li + 1), src_addr="0x%06X" % a))
            continue
        if mn == "jr":
            t = a + 2 + signed(v, 8)
        elif mn in ("jrl", "calr"):
            t = a + 3 + signed(v, 16)
        else:
            if cc:
                stats["skip_conditional_abs"] += 1
                continue
            t = v
        sites.append(dict(rel=rel, li=li, addr=a, mn=mn, cc=cc, target=t, m=m))

    # ------------------------------------------------------ source blocks
    # A BLOCK is the run of lines from one label to the next in one file.
    # Data decoded as instructions (e.g. `{u8,u8,0xFF}` patch records spelled
    # `jr lt, 0 / swi 7`) produces numeric "branches" whose targets are
    # meaningless; symbolising them would plant labels the byte gate cannot
    # object to.  Two refusal rules, both reported with counts:
    #   R1 a SMALL block (< 24 instructions) any of whose numeric branches
    #      lands mid-line or outside the image has an incoherent decode --
    #      trust none of its branches.  (Large real-code blocks are not
    #      poisoned wholesale by one bad target: a mid-line target is as
    #      often a misframe on the TARGET side as a fake source.)
    #   R2 a block of < 3 instructions that holds data or sits between
    #      data-only blocks is the fragment-in-a-table shape.
    #   R3 an ABSURD NEIGHBOURHOOD -- within 12 instruction lines of the
    #      source, an instruction real code in these
    #      images essentially never contains -- is data decoded as code:
    #      halt, incf/decf, ldf, a branch to the very next instruction
    #      (`jr cc, 0`), two or more `nop`, a `reti` not preceded by a `pop`,
    #      and (outside WSA1, where `swi 7` is the LCD service call) any
    #      `swi` -- 0xFF padding decodes as `swi 7`.
    wsa = img["mirror"] == "wsa1"
    ABSURD = re.compile(r'^(halt|incf|decf|ldf|normal|max|min)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                        r'|^(jr|jrl)\s+f\s*,'
                        + ('' if wsa else r'|^swi\b'))
    block_of = {}
    blocks = collections.defaultdict(lambda: dict(insn=0, data=0))
    insn_idx = {}                              # (rel, li) -> k within its file
    absurd_at = collections.defaultdict(list)  # rel -> sorted insn indices
    for rel in rels:
        bid = (rel, 0)
        prev = ""
        k = 0
        for li, text in enumerate(src.lines(rel)):
            if labels_on(text):
                bid = (rel, li)
            block_of[(rel, li)] = bid
            bk, _ = drc.classify_line(text, macros)
            if bk == "code":
                blocks[bid]["insn"] += 1
                c = code_of(text).lower()
                insn_idx[(rel, li)] = k
                if ABSURD.match(c) or (c == "nop" and prev == "nop") or (
                        c == "reti" and not prev.startswith("pop")):
                    absurd_at[rel].append(k)
                    stats["absurd_marker_" + c.split()[0]] += 1
                prev = c
                k += 1
            elif bk in ("data", "fill"):
                blocks[bid]["data"] += 1
                prev = ""

    WINDOW = 12

    def near_absurd(rel, li):
        k = insn_idx.get((rel, li))
        L = absurd_at.get(rel)
        if k is None or not L:
            return False
        j = bisect.bisect_left(L, k - WINDOW)
        return j < len(L) and L[j] <= k + WINDOW
    order = collections.defaultdict(list)
    for bid in blocks:
        order[bid[0]].append(bid)
    for rel in order:
        order[rel].sort()

    def neighbours_data(bid):
        L = order[bid[0]]
        k = L.index(bid)
        prev_d = k > 0 and blocks[L[k - 1]]["insn"] == 0 and blocks[L[k - 1]]["data"] > 0
        next_d = k + 1 < len(L) and blocks[L[k + 1]]["insn"] == 0 and blocks[L[k + 1]]["data"] > 0
        return prev_d or next_d

    def tkind(t):
        k = bisect.bisect_right(starts, t) - 1
        if k < 0 or not (spans[k][0] <= t < spans[k][1]):
            return "external"
        return "boundary" if t == spans[k][0] else "mid"
    bad_blocks = set()
    for s in sites:
        s["block"] = block_of[(s["rel"], s["li"])]
        if tkind(s["target"]) != "boundary":
            bad_blocks.add(s["block"])
    uni = independent_decode(img)

    def after_data_unlabelled(rel, li):
        """R4: walking up from the source, a DATA line is met before any label
        -- the source sits in an unlabelled code run glued onto data, the shape
        of a record whose trailing bytes were decoded as instructions."""
        L = src.lines(rel)
        for j in range(li - 1, -1, -1):
            if labels_on(L[j]):
                return False
            bk, _ = drc.classify_line(L[j], macros)
            if bk in ("data", "fill"):
                return True
        return False
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    off = drc.rom_offset_fn(img)
    lo_rom, hi_rom = img["base"], img["base"] + (1 << 24)
    if img["mirror"] != "wsa1" and img["key"] in ("v10", "v9", "v7"):
        lo_rom, hi_rom = 0xE00000, 0x1000000

    def looks_like_table_or_text(a):
        """R6: data that BOTH decoders read the same wrong way (a string, a
        pointer table) survives R5.  Refuse when the ROM around the site is
        >= 80% printable ASCII, or holds 4 consecutive little-endian 32-bit
        words that all point into the image's ROM range."""
        o = off(a)
        if o is None:
            return False
        w = rom[max(0, o - 16):o + 16]
        if w and sum(0x20 <= c < 0x7F for c in w) >= 0.8 * len(w):
            return True
        for st in range(max(0, o - 16), min(len(rom) - 16, o + 1)):
            vals = [int.from_bytes(rom[st + 4 * k:st + 4 * k + 4], "little") for k in range(4)]
            if all(lo_rom <= v < hi_rom for v in vals):
                return True
        return False
    kept_sites = []
    for s in sites:
        b = blocks[s["block"]]
        if looks_like_table_or_text(s["addr"]):
            stats["refuse_R6_text_or_pointer_table"] += 1
            refused["R6"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                      src_addr="0x%06X" % s["addr"],
                                      target="0x%06X" % s["target"]))
            continue
        if not uni_agrees(uni, s):
            stats["refuse_R5_second_decoder_disagrees"] += 1
            refused["R5"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                      src_addr="0x%06X" % s["addr"],
                                      target="0x%06X" % s["target"],
                                      unidasm=" ".join(uni.get(s["addr"], ("-", "")))))
            continue
        if USE_R4 and after_data_unlabelled(s["rel"], s["li"]):
            stats["refuse_R4_code_glued_to_data"] += 1
            refused["R4"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                      src_addr="0x%06X" % s["addr"],
                                      target="0x%06X" % s["target"]))
            continue
        if near_absurd(s["rel"], s["li"]):
            if tkind(s["target"]) == "boundary":
                stats["refuse_R3_absurd_block"] += 1
                refused["R3"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                          src_addr="0x%06X" % s["addr"],
                                          target="0x%06X" % s["target"]))
            else:
                kept_sites.append(s)     # still reported as misframe evidence
            continue
        if s["block"] in bad_blocks and b["insn"] < 24 and tkind(s["target"]) == "boundary":
            stats["refuse_R1_incoherent_small_block"] += 1
            refused["R1"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                      src_addr="0x%06X" % s["addr"],
                                      target="0x%06X" % s["target"]))
            continue
        if b["insn"] < 3 and (b["data"] > 0 or neighbours_data(s["block"])):
            stats["refuse_R2_fragment"] += 1
            refused["R2"].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                      src_addr="0x%06X" % s["addr"], target="0x%06X" % s["target"]))
            continue
        kept_sites.append(s)
    sites[:] = kept_sites

    # ---------------------------------------------------------------- targets
    by_target = collections.defaultdict(list)
    for s in sites:
        by_target[s["target"]].append(s)

    plans = {}      # target -> dict(kind, name, new(bool), rel, li)
    for t, srcs in sorted(by_target.items()):
        k = bisect.bisect_right(starts, t) - 1
        if k < 0 or not (spans[k][0] <= t < spans[k][1]):
            kind = "external"
        else:
            s0, e0, trel, tli = spans[k]
            bk, _ = drc.classify_line(src.text(trel, tli), macros)
            if t != s0:
                kind = "mid-line-" + bk
            elif trel in shared:
                kind = "shared-file"
            elif bk == "code":
                kind = "boundary-code"
            elif bk == "data":
                d = code_of(src.text(trel, tli)).split()[0].lower() if code_of(src.text(trel, tli)) else ""
                kind = "boundary-incbin" if d == ".incbin" else "boundary-data"
            else:
                kind = "boundary-" + bk
        if kind not in ("boundary-code", "boundary-data", "boundary-incbin"):
            for s in srcs:
                report[kind].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                         src_addr="0x%06X" % s["addr"],
                                         target="0x%06X" % t))
            stats["target_" + kind] += 1
            stats["site_" + kind] += len(srcs)
            continue
        if only is not None and trel not in only and not any(
                c[1] for c in labels_at.get(t, []) if not c[1].startswith(drc.MARK)):
            stats["target_outside_only"] += 1
            continue
        # reuse an existing label at exactly this address?
        cands = sorted(c for c in labels_at.get(t, []) if not c[1].startswith(drc.MARK))
        if cands and cands[0][0] < 9:
            plans[t] = dict(kind=kind, name=cands[0][1], new=False, rel=trel, li=tli)
            stats["target_reuse"] += 1
        else:
            plans[t] = dict(kind=kind, name=None, new=True, rel=trel, li=tli)
            stats["target_new"] += 1
        stats["site_" + kind] += len(srcs)
        if kind != "boundary-code":
            for s in srcs:
                report[kind].append(dict(src="%s:%d" % (s["rel"], s["li"] + 1),
                                         src_addr="0x%06X" % s["addr"],
                                         target="0x%06X" % t,
                                         label=plans[t]["name"]))

    # ---------------------------------------------------------------- naming
    # ROUTINE ENTRIES: names something CALLS, or a pointer table / addr24 holds.
    # A new label is named after the nearest routine entry above it.
    entry_names = set()
    ENTRY_REF = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(?:(?:call|calr)\s+(?:[a-z]+\s*,\s*)?'
                           r'|\.(?:long|4byte|int)\s+|addr24\s+)([A-Za-z_][\w.$@]*)')
    for rel in rels:
        for text in src.lines(rel):
            c = drc.strip_comment(text)
            m = ENTRY_REF.match(c)
            if m:
                entry_names.add(m.group(1))
                if ".long" in c or ".4byte" in c:
                    for nm in re.findall(r'[A-Za-z_][\w.$@]*', c.split(None, 1)[1] if len(c.split(None, 1)) > 1 else ""):
                        entry_names.add(nm)
    # ...and labels already sitting at the target of a NUMERIC call/calr
    # (their callers are exactly the operands this tool is about to rewrite)
    for s_ in sites:
        if s_["mn"] in ("call", "calr"):
            for c_ in labels_at.get(s_["target"], []):
                entry_names.add(c_[1])
    TERMINATOR = re.compile(r'^(ret|reti|retd|halt)\b|^(jp|jr|jrl)\s+(t\s*,\s*)?[^,]+$')

    def label_is_data(rel, j):
        """True when the first EMITTING line at/after label line j is data."""
        L = src.lines(rel)
        for k in range(j, min(len(L), j + 40)):
            bk, _ = drc.classify_line(L[k], macros)
            if bk == "code":
                return False
            if bk in ("data", "fill"):
                return True
        return False

    def routine_of(rel, li):
        """Nearest routine entry above a line.  Crossing a DATA-framed label
        means the line sits in code that follows a table, not inside the
        routine above the table: then the answer is `<Table>_Code`."""
        L = src.lines(rel)
        for j in range(li, max(-1, li - 4000), -1):
            for nm in reversed(labels_on(L[j])):
                if nm.startswith(drc.MARK) or nm.startswith(".L") or nm.startswith("__"):
                    continue
                if label_is_data(rel, j):
                    return nm + "_Code"
                if nm in entry_names:
                    return nm
        return None

    def real_label_above(rel, li):
        L = src.lines(rel)
        for j in range(li, -1, -1):
            for nm in reversed(labels_on(L[j])):
                if not (nm.startswith(".L") or nm.startswith("__") or nm.startswith(drc.MARK)) \
                        and not label_is_data(rel, j):
                    return nm
        return None

    def standalone(rel, li):
        """The target follows a terminator (or data): it starts a routine of its own."""
        L = src.lines(rel)
        for j in range(li - 1, -1, -1):
            bk, _ = drc.classify_line(L[j], macros)
            if bk == "code":
                return bool(TERMINATOR.match(code_of(L[j]).lower()))
            if bk in ("data", "fill"):
                return True
        return True

    taken = set(defined)
    for t in sorted(plans):
        p = plans[t]
        if not p["new"]:
            continue
        trel, tli = p["rel"], p["li"]
        lines = src.lines(trel)
        srcs = by_target[t]
        calls = sorted((s for s in srcs if s["mn"] in ("call", "calr")), key=lambda s: s["addr"])
        tcode = code_of(lines[tli]).lower()
        # ---- role (structural facts only)
        if calls and (p["kind"] != "boundary-code" or standalone(trel, tli)):
            role = "HELPER"          # a routine of its own that something calls
        elif p["kind"] != "boundary-code":
            role = "Entry"
        elif RET_RE.match(tcode):
            role = "Return"
        elif calls:
            role = "Sub"
        elif any(s["addr"] > t and s["cc"] not in ("", "t") for s in srcs):
            role = "Loop"            # a backward CONDITIONAL branch closes a cycle
        else:
            role = None
            j, seen = tli, 0
            while j < len(lines) and seen < 12:
                c = code_of(lines[j]).lower()
                if c:
                    seen += 1
                    if RET_RE.match(c):
                        role = "Epilogue" if seen > 1 else "Return"
                        break
                    if not POP_OK.match(c):
                        break
                j += 1
            if role is None:
                uncond = any((s["mn"] in ("jr", "jrl", "jp") and s["cc"] in ("", "t"))
                             for s in srcs)
                role = "Join" if uncond else "Skip"
        # ---- parent
        if role == "HELPER":
            if img["mirror"] == "wsa1":
                base = "sub_%06X" % t          # WSA1 house style for an unnamed routine
            else:
                c0 = calls[0]
                caller = routine_of(c0["rel"], c0["li"]) or real_label_above(c0["rel"], c0["li"]) \
                    or re.sub(r'\W', '_', os.path.splitext(os.path.basename(c0["rel"]))[0])
                base = "%s_Helper" % caller
        else:
            # The parent is the ROUTINE ENTRY above the target, else the real
            # code label above the EARLIEST line involved: a routine-wide exit
            # reached from the prologue's range checks and from every case
            # must not be named after the nearest intermediate `_Case0` label,
            # and arm code after an inline jump table must not be named after
            # the TABLE (data-framed labels are skipped).
            parent = routine_of(trel, tli)
            if not parent:
                startl = min([tli] + [s["li"] for s in srcs if s["rel"] == trel])
                parent = real_label_above(trel, startl)
            if not parent:
                parent = re.sub(r'\W', '_', os.path.splitext(os.path.basename(trel))[0])
            base = "%s_%s" % (parent, role)
        name, n = base, 1
        while name in taken:
            n += 1
            name = "%s%d" % (base, n)
        taken.add(name)
        p["name"] = name
    return dict(img=img, srcroot=srcroot, src=src, sites=sites, plans=plans,
                stats=stats, report=report)


def apply(res):
    src, plans, sites = res["src"], res["plans"], res["sites"]
    edits = collections.defaultdict(dict)     # rel -> {li: newtext}
    inserts = collections.defaultdict(dict)   # rel -> {li: [labels]}
    n_sites = 0
    for s in sites:
        p = plans.get(s["target"])
        if not p:
            continue
        m = s["m"]
        text = src.text(s["rel"], s["li"])
        new = "%s%s%s%s%s%s" % (m.group("pre"), m.group("mn"), m.group("ws"),
                                (m.group("cc") + m.group("ccsep")) if m.group("cc") else "",
                                p["name"], m.group("post"))
        # keep a trailing \r if the file had one
        if text.endswith("\r"):
            new += "\r"
        edits[s["rel"]][s["li"]] = new
        n_sites += 1
    for t, p in plans.items():
        if p["new"]:
            inserts[p["rel"]].setdefault(p["li"], []).append(p["name"])
    files = set(edits) | set(inserts)
    for rel in sorted(files):
        path = os.path.join(res["srcroot"], rel)
        raw = open(path, "rb").read().decode("latin-1")
        lines = raw.split("\n")
        assert lines == src.lines(rel), "source changed under us: " + rel
        out = []
        for li, ln in enumerate(lines):
            for nm in inserts[rel].get(li, []):
                out.append("%s:" % nm)
            out.append(edits[rel].get(li, ln))
        open(path, "wb").write("\n".join(out).encode("latin-1"))
    return n_sites, sum(len(v) for v in inserts.values()), len(files)


def verify(img):
    srcroot = os.path.join(ROOT, img["mirror"])
    _, _, _, rom_ok, _, _ = build_map(img, srcroot)
    return rom_ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--only", help="comma-separated source files, relative to the image's "
                    "mirror dir (e.g. sequencer/accompaniment_engine.s, or prom_b/wsa1_prom_b.s)")
    ap.add_argument("--kinds", default="boundary-code,boundary-data,boundary-incbin",
                    help="which target kinds to convert")
    a = ap.parse_args()
    img = image_by_key(a.image)
    res = analyse(img, set(a.only.split(",")) if a.only else None)
    allowed = set(a.kinds.split(","))
    for t in list(res["plans"]):
        if res["plans"][t]["kind"] not in allowed:
            del res["plans"][t]
    st = res["stats"]
    print("image %s" % img["key"])
    for k in sorted(st):
        print("  %-28s %7d" % (k, st[k]))
    conv = sum(1 for s in res["sites"] if s["target"] in res["plans"])
    print("  %-28s %7d" % ("SITES CONVERTIBLE", conv))
    if a.report:
        out = dict(image=img["key"], stats=dict(st),
                   labels_new=sorted((("0x%06X" % t), p["name"], "%s:%d" % (p["rel"], p["li"] + 1), p["kind"])
                                     for t, p in res["plans"].items() if p["new"]),
                   report=res["report"])
        json.dump(out, open(a.report, "w"), indent=1)
        print("wrote", a.report)
    if a.apply:
        n, nl, nf = apply(res)
        print("APPLIED: %d operands rewritten, %d labels inserted, %d files" % (n, nl, nf))
        if a.verify:
            ok = verify(img)
            print("VERIFY (re-mirrored modified tree == dump):", "PASS" if ok else "FAIL")
            if not ok:
                sys.exit(1)


if __name__ == "__main__":
    main()
