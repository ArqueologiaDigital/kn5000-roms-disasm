#!/usr/bin/env python3
r"""ARE THE 25,211 `.byte` OPERANDS IN v10 widget_dispatch.s DEBT, OR ARE THEY
ALREADY CORRECT?  (three-way split, with a measured control)

QUESTION ANSWERED
-----------------
`scripts/analysis/kn5000_source_coverage.py` reports v10 as 0 bytes of verbatim
debt / 100.0% source.  That instrument counts `.incbin` with no generator; it is
BLIND to `.byte`.  So a `.byte` count is NOT automatically debt: a run that is
genuinely a byte-valued table is already correctly represented.  Debt is only
the subset that is un-decoded CODE or untyped STRUCTURED data.

This tool splits every `.byte` run in
`v10/maincpu/ui_widgets/widget_dispatch.s` into three classes:

  (a) CODE      -- real instructions still spelled as `.byte`.
  (b) STRUCT    -- structured data whose correct spelling is wider than a byte:
                   pointer tables (`.long`), 16-bit tables (`.word`), text
                   (`.ascii`).  Retyping these adds information.
  (c) BYTETABLE -- genuine byte-valued tables.  `.byte` is already right; these
                   are NOT debt and converting them would be noise.

and CROSSES all three with a fourth, orthogonal tag:

  (d) BLIND-START -- the run's first byte is one of {0x01, 0x04, 0x17, 0x1a,
                   0x1c}, which the pinned tlcs900_backend cannot decode at all
                   but MAME's unidasm reads as normal / max / ldf / JP nnnn /
                   CALL nnnn.  A conversion pass leaves behind what its decoder
                   refused, so across a whole image an excess of these starts is
                   evidence of undecoded CODE
                   (see scripts/analysis/byte_run_start_enrichment.py).
                   ⚠ It is a tag, NOT a class: it does not license converting a
                   run, and until the backend gains those five instructions any
                   attempt would have to find some OTHER reading that
                   round-trips -- data-as-code arriving from the far side.

HOW IT DECIDES
--------------
Addresses come from `scripts/analysis/address_line_map.py`, which self-tests
that its instrumented mirror still assembles to the original ROM, so every run
is located in the real image and its bytes are read from
`original_ROMs/kn5000_v10_program.rom`.

A run is a maximal sequence of `.byte` source lines, SPLIT AT EVERY LABEL, so
each run has exactly one owning label naming its first byte.

Per run, the evidence is:

  REF   every label of the run is looked up across all v10/maincpu `.s` files and
        each use site is classified by SYNTAX:
          CALLJUMP  `call/calr/jp/jr/jrl/djnz X`      -> control flow enters here
          PTR       `.long X` / `.word X`             -> the ADDRESS is stored
          IMM       `ld reg, X` etc.                  -> the ADDRESS is taken
        Per the push's standing rule: if every reference takes the ADDRESS and
        nothing calls or jumps to it, the run is DATA.
  FALL  can the IMMEDIATELY preceding byte-emitting source line fall through
        into the run?  (it is an instruction, and not a terminator).  An earlier
        version tracked "the last instruction seen", which is not the same thing
        -- with data in between, nothing falls through -- and it manufactured
        three spurious CODE verdicts.
  PTRTAB fraction of aligned 4-byte LE words lying in the ROM/RAM windows.
  WORDTAB fraction of aligned 2-byte LE words with a 0x00/0xFF high byte.
  TEXT  fraction of printable ASCII, and the longest printable run.

Decision order (first match wins):
  1. any label of the run has a CALLJUMP reference         -> CODE
  2. FALL and the run disassembles with no `<unknown>` and
     the last instruction ends exactly on the run boundary -> CODE
  3. PTRTAB >= 0.90 over >= 4 aligned words                -> STRUCT/ptr
  4. TEXT >= 0.90 and longest printable run >= 6           -> STRUCT/ascii
  5. WORDTAB >= 0.95 over >= 8 aligned words               -> STRUCT/word
  6. otherwise                                             -> BYTETABLE

THE CONTROL -- how this classifier could be WRONG
-------------------------------------------------
The failure that matters is rule 1 firing on data (a jump table round-trips as
code -- six conversions earlier in this push had to be reverted for exactly
this) or failing to fire on code.  Both are measured against corpora the tree
already labels, using the SAME reference index:

  POSITIVE corpus: every label in v10/maincpu that begins a region the tree
      spells as INSTRUCTIONS.  Rule 1 should fire.  Misses = false NEGATIVE
      rate for code -- code reached only by fall-through is invisible to rule 1.
  NEGATIVE corpus: every label in v10/maincpu that begins a region the tree
      spells as `.ascii` / `.asciz` / `.incbin` -- unambiguous data.  Rule 1
      firing on any of them is a false POSITIVE.

`--control` prints both rates and names the offenders.  A number from this tool
should never be quoted without them.

THE BUCKET-(d) CONTROL, AND WHY THIS FILE READS AS DATA
-------------------------------------------------------
A raw blind-start count means nothing on its own: 0x01 and 0x04 are common data
values.  The instrument is the CONTROL SET {0x02, 0x03, 0x05, 0x16, 0x1b} --
decodable bytes of the same magnitude.  For v10/maincpu as a whole the split is
19.3% blind against 0.4% control, a 46.5x enrichment.  For THIS FILE alone it is
10.9% blind against 5.1% control -- 2.1x, under the enrichment script's own 3x
threshold, i.e. "reads as data".  So widget_dispatch.s is NOT where v10's
undecoded-code residue lives; the concentrations are extension_data.s (58.3%),
sound_editor_ui.s (15.9%) and accompaniment_engine.s (15.1%).

And this file's residual blind starts are a CONFOUND, not a residue.  65 of its
74 blind-start runs begin with 0x01, and they sit at a regular cadence inside
the DisplayScript_Node_* / WidgetParam_Entry_* arrays, which are SIX-byte
records `{u16 tag, u32 pointer}`: the 0x01 is the low byte of a record tag, and
the run boundary in front of it was manufactured by an interposed `.long` for
the previous record's pointer.  `--list BLIND` shows them.  No blind-start run
in this file is a call/jump target, none is fall-through reachable, and none
lands in the CODE or STRUCT class.

RUN
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --control
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --selfcheck
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --list CODE
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --list BLIND
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --json out.json

Set AMAP_CACHE=<file> to cache the address map between runs (it is rebuilt from
the tree otherwise; that needs `make everything` to have produced the generated
`.bin` includes first).
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRCDIR = os.path.join(ROOT, "v10/maincpu")
TARGET = "v10/maincpu/ui_widgets/widget_dispatch.s"
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
OBJDUMP = os.path.join(LLVM, "llvm-objdump")
ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")

# Mnemonics that transfer control TO a named target.  A label appearing as the
# operand of one of these is entered by control flow -> it is code.
CALLJUMP = {"call", "calr", "jp", "jr", "jrl", "djnz", "ljp", "lcall"}
# Instructions after which execution does NOT continue to the next address.
TERMINATOR = {"ret", "retd", "reti", "retn", "jp", "jr", "jrl", "halt", "swi"}
PTR_DIRS = (".long", ".word", ".short", ".int", ".quad")
# Leading bytes with NO decode in the pinned tlcs900_backend that unidasm reads
# as real TLCS-900 instructions, and a decodable control set of comparable
# magnitude.  See scripts/analysis/byte_run_start_enrichment.py.
BLIND_START = {0x01: "normal", 0x04: "max", 0x17: "ldf",
               0x1a: "jp nnnn", 0x1c: "call nnnn"}
CONTROL_START = {0x02, 0x03, 0x05, 0x16, 0x1b}
# Macros defined in v10/maincpu/shared/macros.s that emit DATA, not code.  They
# have no leading dot, so a naive parser calls them instructions and then thinks
# the region after them is fall-through reachable -- which manufactured a CODE
# verdict for the byte table that follows `aligned_string "0123456789ABCDEF"`.
DATA_MACROS = {"aligned_string", "naka_header", "addr24"}
TEXT_DIRS = (".ascii", ".asciz", ".string")


# ---------------------------------------------------------------- source model
def parse_line(ln):
    """-> (kind, label).  kind in {None, 'LABELONLY', 'INSN', '.<directive>'}"""
    code = ln.split(";")[0].strip()
    if not code:
        return None, None
    lab = None
    m = re.match(r"^([A-Za-z_.][\w.$]*)\s*:", code)
    if m:
        lab = m.group(1)
        code = code[m.end():].strip()
    if not code:
        return "LABELONLY", lab
    m = re.match(r"^(\.[a-z_0-9]+)\b", code)
    if m:
        return m.group(1), lab
    m = re.match(r"^([A-Za-z_][\w]*)\b", code)
    if m and m.group(1) in DATA_MACROS:
        return ".macro-data", lab
    return "INSN", lab


def mnemonic(ln):
    code = ln.split(";")[0].strip()
    m = re.match(r"^[A-Za-z_.][\w.$]*\s*:", code)
    if m:
        code = code[m.end():].strip()
    m = re.match(r"^([a-z][a-z0-9_]*)\b", code)
    return m.group(1) if m else None


# ---------------------------------------------------------------- address map
def address_map():
    cache = os.environ.get("AMAP_CACHE", "")
    if cache and os.path.exists(cache):
        return json.load(open(cache))
    sys.path.insert(0, os.path.join(ROOT, "scripts/analysis"))
    import address_line_map as A
    ent, _, _ = A.build()
    out = [{"addr": a, "src": s, "line": l} for a, s, l, _ in ent]
    if cache:
        json.dump(out, open(cache, "w"))
    return out


# ------------------------------------------------------- whole-tree ref index
def build_ref_index():
    """label -> list of (kind, src, line).  kind in CALLJUMP / PTR / IMM."""
    idx = {}
    tok = re.compile(r"[A-Za-z_][\w.$]*")
    for dp, dn, fn in os.walk(SRCDIR):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, ROOT)
            for i, ln in enumerate(open(p, encoding="latin-1"), 1):
                code = ln.split(";")[0]
                if not code.strip():
                    continue
                m = re.match(r"^\s*([A-Za-z_.][\w.$]*)\s*:", code)
                defined = m.group(1) if m else None
                if m:
                    code = code[m.end():]
                code = code.strip()
                if not code:
                    continue
                mm = re.match(r"^(\.?[A-Za-z_][\w.$]*)\s*(.*)$", code)
                if not mm:
                    continue
                head, args = mm.group(1).lower(), mm.group(2)
                if head in CALLJUMP:
                    kind = "CALLJUMP"
                elif head in PTR_DIRS:
                    kind = "PTR"
                else:
                    kind = "IMM"
                for t in tok.findall(args):
                    if t == defined:
                        continue
                    idx.setdefault(t, []).append((kind, rel, i))
    return idx


# ---------------------------------------------------------------- run finding
def byte_runs(amap):
    """Maximal runs of consecutive `.byte` source lines in TARGET, split at every
    label so each run has exactly one owning label -- the one naming its first
    byte.

    WARNING, and the reason --selfcheck exists: the first version of this
    function dropped label-only lines on the floor.  No run ever carried a
    label, so rule 1 could never fire, and the tool reported 50 bytes of CODE
    from rule 2 alone.  --selfcheck asserts that the set of run-owning labels is
    exactly the set of labels in the file that name a `.byte` line.
    """
    addr = {e["line"]: e["addr"] for e in amap if e["src"] == TARGET}
    src = open(os.path.join(ROOT, TARGET), encoding="latin-1").read().split("\n")
    runs, cur = [], None
    prev_emit = None      # the IMMEDIATELY preceding byte-emitting line
    pending = []          # labels seen since the last byte-emitting line
    for i, ln in enumerate(src, 1):
        k, lab = parse_line(ln)
        if k is None:
            continue
        a = addr.get(i)
        if k == "LABELONLY":
            if cur is not None:            # a label splits the run
                cur["a1"] = a
                runs.append(cur)
                cur = None
            pending.append(lab)
            continue
        if k == ".byte":
            if cur is None:
                cur = {"l0": i, "a0": a, "labels": list(pending),
                       "prev": prev_emit}
                pending = []
            if lab:
                cur["labels"].append(lab)
            cur["l1"] = i
        else:
            if cur is not None:
                cur["a1"] = a
                runs.append(cur)
                cur = None
            pending = []
        prev_emit = (i, ln, k)
    if cur is not None:
        cur["a1"] = None
        runs.append(cur)
    for r in runs:
        r["size"] = (r["a1"] - r["a0"]) if r["a1"] else 0
        r["labels"] = sorted(set(r["labels"]))
    return [r for r in runs if r["size"] > 0]


def selfcheck(amap):
    """Assert the run model did not lose labels or bytes."""
    src = open(os.path.join(ROOT, TARGET), encoding="latin-1").read().split("\n")
    # every label that names a .byte line, directly or via a preceding
    # label-only line with no other directive in between
    want, pending = set(), []
    for ln in src:
        k, lab = parse_line(ln)
        if k is None:
            continue
        if k == "LABELONLY":
            pending.append(lab)
            continue
        if k == ".byte":
            want.update(pending)
            if lab:
                want.add(lab)
        pending = []
    runs = byte_runs(amap)
    got = set()
    for r in runs:
        got.update(r["labels"])
    # operand count must equal the byte total
    ops = 0
    for ln in src:
        k, _ = parse_line(ln)
        if k == ".byte":
            body = ln.split(";")[0]
            body = body[body.index(".byte") + 5:]
            ops += body.count(",") + 1
    tot = sum(r["size"] for r in runs)
    ok = True
    for desc, cond, extra in (
            ("run-owning labels == labels naming a .byte line",
             want == got, "missing=%s extra=%s" % (sorted(want - got)[:5],
                                                   sorted(got - want)[:5])),
            ("sum(run sizes) == .byte operand count",
             tot == ops, "%d vs %d" % (tot, ops))):
        print("  %-52s %s  %s" % (desc, "PASS" if cond else "FAIL", extra if not cond else ""))
        ok = ok and cond
    print("SELFCHECK", "PASS" if ok else "FAIL")
    return 0 if ok else 1


# ---------------------------------------------------------------- structure
def ptrtab_score(b, a0):
    off = (-a0) % 4
    n = (len(b) - off) // 4
    if n < 4:
        return 0.0, n
    good = 0
    for i in range(n):
        o = off + i * 4
        v = int.from_bytes(b[o:o + 4], "little")
        if 0xE00000 <= v <= 0xFFFFFF or v <= 0x00FFFF:
            good += 1
    return good / n, n


def text_score(b):
    printable = sum(1 for c in b if 0x20 <= c < 0x7F)
    best = run = 0
    for c in b:
        run = run + 1 if 0x20 <= c < 0x7F else 0
        best = max(best, run)
    return printable / len(b), best


def wordtab_score(b, a0):
    """fraction of aligned 2-byte words whose HIGH byte is 0x00 or 0xFF while the
    low byte varies -- the signature of a 16-bit table written as bytes."""
    off = (-a0) % 2
    n = (len(b) - off) // 2
    if n < 8:
        return 0.0, n
    lo = [b[off + i * 2] for i in range(n)]
    hi = [b[off + i * 2 + 1] for i in range(n)]
    if len(set(lo)) < 3:
        return 0.0, n
    return sum(1 for h in hi if h in (0x00, 0xFF)) / n, n


_DIS = {}


def disassembles_cleanly(a0, size):
    """objdump the run out of the linked ELF; True if it holds no `<unknown>`
    and the last instruction ends exactly on the run boundary."""
    key = (a0, size)
    if key in _DIS:
        return _DIS[key]
    r = subprocess.run([OBJDUMP, "-d", "--start-address=0x%X" % a0,
                        "--stop-address=0x%X" % (a0 + size), ELF],
                       capture_output=True, text=True)
    ok = False
    if r.returncode == 0 and "<unknown>" not in r.stdout:
        last = None
        for line in r.stdout.split("\n"):
            m = re.match(r"\s+([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)", line)
            if m:
                last = (int(m.group(1), 16), len(m.group(2).split()))
        ok = bool(last) and last[0] + last[1] == a0 + size
    _DIS[key] = ok
    return ok


# ---------------------------------------------------------------- classify
def classify(r, rom, refidx):
    a0, n = r["a0"], r["size"]
    b = rom[a0 - BASE:a0 - BASE + n]
    kinds, sites = set(), []
    for L in r["labels"]:
        for k, f, ln in refidx.get(L, []):
            kinds.add(k)
            sites.append([L, k, f, ln])
    ev = {"ref_kinds": sorted(kinds), "ref_sites": sites[:8]}
    fall = False
    if r["prev"] and r["prev"][2] == "INSN":
        mn = mnemonic(r["prev"][1])
        fall = mn is not None and mn not in TERMINATOR
    ev["fall"] = fall
    ev["ptrtab"], ev["ptrtab_n"] = ptrtab_score(b, a0)
    ev["wordtab"], ev["wordtab_n"] = wordtab_score(b, a0)
    ev["text"], ev["textrun"] = text_score(b)
    ev["unref"] = not kinds
    ev["start"] = b[0] if b else None
    ev["blind"] = ev["start"] in BLIND_START
    ev["ctrlstart"] = ev["start"] in CONTROL_START

    if "CALLJUMP" in kinds:
        return "CODE", "rule1: label is a call/jump target", ev
    if fall and disassembles_cleanly(a0, n):
        return "CODE", "rule2: falls through and decodes exactly", ev
    if ev["ptrtab"] >= 0.90 and ev["ptrtab_n"] >= 4:
        return "STRUCT", "rule3: %.0f%% of %d aligned words are pointers" % (
            100 * ev["ptrtab"], ev["ptrtab_n"]), ev
    if ev["text"] >= 0.90 and ev["textrun"] >= 6:
        return "STRUCT", "rule4: %.0f%% printable, longest run %d" % (
            100 * ev["text"], ev["textrun"]), ev
    if ev["wordtab"] >= 0.95 and ev["wordtab_n"] >= 8:
        return "STRUCT", "rule5: %.0f%% of %d aligned words have a 00/FF high byte" % (
            100 * ev["wordtab"], ev["wordtab_n"]), ev
    return "BYTETABLE", "no code entry, no wide-type signature", ev


# ---------------------------------------------------------------- control
def control(refidx):
    pos, neg = [], []
    for dp, dn, fn in os.walk(SRCDIR):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            lines = open(os.path.join(dp, f), encoding="latin-1").read().split("\n")
            pending = []
            for ln in lines:
                k, lab = parse_line(ln)
                if k is None:
                    continue
                if k == "LABELONLY":
                    pending.append(lab)
                    continue
                if lab:
                    pending.append(lab)
                for L in pending:
                    if k == "INSN":
                        pos.append(L)
                    elif k in TEXT_DIRS or k == ".incbin":
                        neg.append(L)
                pending = []

    def fires(L):
        return any(k == "CALLJUMP" for k, _, _ in refidx.get(L, []))

    ph = sum(1 for L in pos if fires(L))
    nh = [L for L in neg if fires(L)]
    print("RULE-1 CONTROL (does 'has a CALLJUMP reference' identify code?)")
    print("  POSITIVE corpus: %6d labels the tree spells as INSTRUCTIONS" % len(pos))
    print("     rule 1 fires on %6d  (%.1f%%)  -> false-NEGATIVE rate %.1f%%"
          % (ph, 100.0 * ph / len(pos), 100.0 - 100.0 * ph / len(pos)))
    print("     (code reached only by fall-through has no named call site;")
    print("      rule 2 is the backstop for that, and CODE is a LOWER bound.)")
    print("  NEGATIVE corpus: %6d labels the tree spells as .ascii/.asciz/.incbin"
          % len(neg))
    print("     rule 1 fires on %6d  (%.2f%%)  <- false-POSITIVE rate"
          % (len(nh), 100.0 * len(nh) / len(neg)))
    if nh:
        print("     offenders:", nh[:20])


# ---------------------------------------------------------------- main
def main():
    a = sys.argv[1:]
    amap = address_map()
    if "--selfcheck" in a:
        sys.exit(selfcheck(amap))
    refidx = build_ref_index()
    if "--control" in a:
        control(refidx)
        return

    rom = open(ROM, "rb").read()
    runs = byte_runs(amap)
    out, tot = [], {"CODE": [0, 0], "STRUCT": [0, 0], "BYTETABLE": [0, 0]}
    for r in runs:
        cls, why, ev = classify(r, rom, refidx)
        tot[cls][0] += 1
        tot[cls][1] += r["size"]
        out.append({"addr": r["a0"], "size": r["size"], "l0": r["l0"], "l1": r["l1"],
                    "class": cls, "why": why, "labels": r["labels"],
                    "ref_kinds": ev["ref_kinds"], "ref_sites": ev["ref_sites"],
                    "fall": ev["fall"], "unref": ev["unref"],
                    "start": ev["start"], "blind": ev["blind"],
                    "ctrlstart": ev["ctrlstart"],
                    "ptrtab": round(ev["ptrtab"], 3), "text": round(ev["text"], 3),
                    "textrun": ev["textrun"], "wordtab": round(ev["wordtab"], 3)})
    if "--json" in a:
        json.dump(out, open(a[a.index("--json") + 1], "w"), indent=1)
    if "--list" in a:
        want = a[a.index("--list") + 1]
        for o in sorted(out, key=lambda o: -o["size"]):
            if (o["blind"] if want == "BLIND" else o["class"] == want):
                print("0x%06X %6d B  lines %5d-%-5d  start=0x%02x refs=%-12s "
                      "%-46s %s"
                      % (o["addr"], o["size"], o["l0"], o["l1"],
                         o["start"] if o["start"] is not None else 0,
                         ",".join(o["ref_kinds"]) or "-", o["why"],
                         ",".join(o["labels"][:2])))
        return

    total = sum(v[1] for v in tot.values())
    print("v10 ui_widgets/widget_dispatch.s  --  %d `.byte` runs, %d operands"
          % (len(runs), total))
    print()
    for k in ("CODE", "STRUCT", "BYTETABLE"):
        n, b = tot[k]
        print("  %-10s %4d runs  %6d bytes  %5.1f%%" % (k, n, b, 100.0 * b / total))
    print()
    print("  (a) CODE      = real instructions still spelled as .byte  -> DEBT")
    print("  (b) STRUCT    = wants .long/.word/.ascii                  -> DEBT")
    print("      STRUCT is what the RULES PROPOSE.  Every remaining STRUCT run")
    print("      here is in SoundEffect_Dispatch_Table (0xEEAFC8-0xEEB960) and")
    print("      was REFUSED by hand: its words read equally well as 16-bit")
    print("      codes or as pairs of byte fields, and nothing in the tree")
    print("      settles the width.  See the converter's header.")
    print("  (c) BYTETABLE = byte-valued table, .byte is correct       -> NOT debt")
    nb = sum(1 for o in out if o["blind"])
    nc = sum(1 for o in out if o["ctrlstart"])
    print("  (d) BLIND-START tag -- crosses the three classes, does not replace them:")
    print("      %d of %d runs (%.1f%%) start with one of {01,04,17,1a,1c};"
          % (nb, len(out), 100.0 * nb / len(out)))
    print("      %d (%.1f%%) start with the decodable control set {02,03,05,16,1b}."
          % (nc, 100.0 * nc / len(out)))
    print("      enrichment %.1fx -- v10/maincpu as a whole is 46.5x.  Under the"
          % (nb / nc if nc else float("inf")))
    print("      enrichment script's 3x threshold this file reads as DATA.")
    for k in ("CODE", "STRUCT", "BYTETABLE"):
        n = sum(1 for o in out if o["class"] == k and o["blind"])
        b_ = sum(o["size"] for o in out if o["class"] == k and o["blind"])
        print("        %-10s %4d blind-start runs, %6d bytes" % (k, n, b_))
    print()
    unref = sum(r["size"] for r in out if r["unref"])
    print()
    print("  %d bytes (%.1f%%) sit in runs whose label NOTHING in v10 references."
          % (unref, 100.0 * unref / total))
    print()
    print("Run with --control before quoting any of these numbers.")


if __name__ == "__main__":
    main()
