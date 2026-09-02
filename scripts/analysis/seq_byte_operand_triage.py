#!/usr/bin/env python3
r"""WHICH OF v10/maincpu/sequencer's 11,096 `.byte` OPERANDS ARE REAL DEBT?
(lane v10seq, 2026-09-02)

QUESTION ANSWERED
-----------------
`scripts/analysis/kn5000_source_coverage.py` reports v10 at 0 verbatim debt /
100.0% source.  It counts `.incbin` and is BLIND to `.byte`.  The sequencer
directory holds 11,096 `.byte` operands, and a raw count of them is NOT
automatically debt: a genuine byte-valued table is already correctly
represented source.  This script splits those operands three ways:

  (a) CODE-AS-BYTE   -- real instructions spelled as data, inside a routine
                        that control flow actually reaches.  Debt.  Fixing it
                        needs a decoder that can spell the opcode.
  (b) UNTYPED-DATA   -- structured data written as an undifferentiated byte
                        soup: ASCII text, LE16/LE32 element tables, or the
                        `.byte` residue of a DATA-AS-CODE misframe (fake
                        mnemonics with unspellable bytes between them).  Debt,
                        and fixable in source alone.
  (c) BYTE-TABLE-OK  -- a genuine byte-valued table, already correct.  Not
                        debt.  Counting it as debt is the error this script
                        exists to avoid.

and one cross-cutting tag, reported as a fourth bucket:

  (d) BLOCKED        -- the run STARTS with one of the five leading bytes the
                        pinned tlcs900 backend cannot decode at all --
                        {0x01 normal, 0x04 max, 0x17 ldf, 0x1a JP nnnn,
                        0x1c CALL nnnn} (leading_byte_reserved_probe.py over
                        393,216 operand continuations each; unidasm decodes
                        all five, so they are BACKEND GAPS, not reserved
                        silicon).  `byte_run_start_enrichment.py` measures v10
                        starting runs with one of those 19.2% of the time
                        against 0.4% for decodable bytes of the same
                        magnitude, with all four WSA1R images flat -- so a
                        blind start RAISES THE PRIOR that a run is undecoded
                        code.  ⚠ It does not adjudicate one, and a blocked run
                        must NOT be forced into instructions until lane
                        w10/missinginsns lands those five: a wrong reading
                        that re-assembles to the same bytes passes the byte
                        gate.  The tag is reported CROSSED with (a)/(b)/(c),
                        never instead of it.

METHOD
------
Unit of analysis = a maximal RUN of consecutive `.byte` source lines (blank and
comment-only lines do not break a run; any other emitting line does).

Each run gets:

  * ADDRESSES, from `scripts/analysis/address_line_map.py --dump`.  That tool
    inserts a label before every emitting line, relinks, and reads the label
    addresses off the ELF, self-testing that the probe build is still
    byte-identical to the dump.  No text matching anywhere.

  * A REGION: the enclosing label (greatest label address <= run start) through
    to the next label address.  Labels come from `llvm-nm` on the real linked
    ELF, so a region is defined by the BUILD, not by source line order.

  * A REFERENCE KIND for that region, over the WHOLE v10/maincpu tree: every
    textual use of any label whose address falls inside the region is scored
    BRANCH (the mnemonic is call/calr/call_24/jp/jp_24/jr/jrl/djnz/... ) or
    ADDR (anything else -- `ld xhl, L`, `.long L`, `lda`, `.word L`).  This is
    the brief's own test: "if every reference loads its ADDRESS and nothing
    calls or jumps to it, it is DATA".

  * NEIGHBOUR KIND: whether the emitting lines immediately before/after the run
    are instructions.  An `.byte` run wedged between two instructions is an
    ISLAND; a run whose neighbours are labels/other data is a BLOCK.

  * CONTENT: printable-ASCII fraction, distinct byte count, and two structure
    probes -- `le16_hi_zero` (fraction of even-offset 16-bit words whose high
    byte is 0, i.e. the run reads as small LE16 scalars) and `ptr24` (fraction
    of 4-byte groups that read as a plausible in-ROM 24-bit pointer).

RULE (deliberately conservative: when in doubt, (c), never (a))

  (a) island AND region is BRANCH-referenced      -> CODE-AS-BYTE
  (b) region is ADDR-only AND (ascii>=0.60 over >=8 B, or the run sits among
      fake instructions in an ADDR-only region, or le16_hi_zero>=0.90 with a
      stride-2 reader, or ptr24>=0.90)            -> UNTYPED-DATA
  (c) everything else                             -> BYTE-TABLE-OK

HOW THIS COULD BE WRONG, AND THE CONTROL
----------------------------------------
Failure modes, all invisible to the byte gate:

  1. A region reached ONLY by fallthrough from a branch-referenced predecessor
     has no reference of its own and looks ADDR-only/unreferenced -> real code
     mislabelled (b) or (c).
  2. A DATA-AS-CODE misframe manufactures fake `jr`/`call` operands naming
     labels inside itself, so a data region can look BRANCH-referenced -> data
     mislabelled (a).  (Self-reference is why the sibling census refuses to
     seed from branch operands at all.)
  3. `ascii>=0.60` fires on binary data that happens to sit in 0x20-0x7E.

CONTROL: `--control` scores this same rule against the 266 spans in
notes/v10-data-as-code/v10dac_conversion_manifest.json, which lanes V10DAC and
V10DAC2 adjudicated BY HAND: 196 `converted` (judged DATA) and 70 `excluded`
(judged real CODE).  It reports the confusion matrix.  A rule that cannot tell
those two populations apart cannot be trusted on the 11,096 either.

RUN
    # 1. address map (≈4 min; self-tests byte-identity of its probe build)
    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    # 2. the split
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json
    # 3. the control
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json --control
    # 4. the runs blocked on the five missing instructions
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json --blocked
    # optional: per-run detail
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json --json out.json
"""
import argparse
import bisect
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAINCPU = os.path.join(ROOT, "v10", "maincpu")
SEQDIR = os.path.join(MAINCPU, "sequencer")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_v10_program.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
MANIFEST = os.path.join(ROOT, "notes", "v10-data-as-code",
                        "v10dac_conversion_manifest.json")

# Leading bytes with no decode anywhere in the pinned backend.  See the (d)
# bucket note above and scripts/analysis/byte_run_start_enrichment.py.
BLIND_LEAD = {0x01: "normal", 0x04: "max", 0x17: "ldf",
              0x1a: "JP nnnn", 0x1c: "CALL nnnn"}
# The control set that instrument scores the blind set against: decodable,
# similar magnitude.  Kept here so this script can report the same contrast.
CONTROL_LEAD = {0x02, 0x03, 0x05, 0x16, 0x1b}

BRANCH_MNEMONICS = {
    "call", "calr", "call_24", "jp", "jp_24", "jr", "jrl", "djnz", "djnz8",
    "djnz16", "jp_cc", "callr",
}
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
IDENT_RE = re.compile(r"[A-Za-z_.$][\w.$]*")
DIRECTIVE_NONEMIT = (
    ".include", ".macro", ".endm", ".equ", ".set", ".globl", ".global",
    ".section", ".text", ".data", ".if", ".else", ".endif", ".ifdef",
    ".ifndef", ".end", ".type", ".size", ".extern",
)


def read_latin1(path):
    with open(path, encoding="latin-1") as fh:
        return fh.read().split("\n")


def emits(stripped):
    """True if this source line emits at least one byte."""
    if not stripped or stripped.startswith(";") or stripped.startswith("#"):
        return False
    if LABEL_RE.match(stripped) and stripped.split(":", 1)[1].strip() == "":
        return False
    if stripped.startswith("."):
        return not stripped.split()[0].lower().startswith(DIRECTIVE_NONEMIT)
    return True


def load_symbols():
    out = subprocess.run([NM, ELF], capture_output=True, text=True, check=True).stdout
    syms = {}
    for line in out.split("\n"):
        parts = line.split()
        if len(parts) != 3:
            continue
        addr, kind, name = parts
        if kind.lower() == "a":          # .equ constants, not locations
            continue
        try:
            syms[name] = int(addr, 16)
        except ValueError:
            pass
    return syms


def load_amap(path):
    """(file, 1-based line) -> address, for every emitting line of v10/maincpu."""
    m = {}
    for e in json.load(open(path)):
        m[(e["src"], e["line"])] = e["addr"]
    return m


def build_reference_index():
    """label -> Counter({'BRANCH': n, 'ADDR': n}) over ALL of v10/maincpu."""
    refs = defaultdict(Counter)
    for dirpath, _dirs, files in os.walk(MAINCPU):
        for fn in files:
            if not fn.endswith(".s"):
                continue
            for raw in read_latin1(os.path.join(dirpath, fn)):
                line = raw.split(";", 1)[0]
                s = line.strip()
                if not s:
                    continue
                if LABEL_RE.match(s):                       # drop the definition
                    s = s.split(":", 1)[1]
                toks = s.split(None, 1)
                if not toks:
                    continue
                mnem = toks[0].lower()
                kind = "BRANCH" if mnem in BRANCH_MNEMONICS else "ADDR"
                operands = toks[1] if len(toks) > 1 else ""
                for ident in IDENT_RE.findall(operands):
                    refs[ident][kind] += 1
    return refs


def collect_runs(amap, files):
    """Maximal runs of consecutive `.byte` lines, with addresses and neighbours."""
    runs = []
    for path in files:
        rel = os.path.relpath(path, ROOT)
        lines = read_latin1(path)
        cur = None
        prev_emit_kind = None          # 'INSN' | 'DATA' | None
        for i, raw in enumerate(lines):
            s = raw.split(";", 1)[0].strip()
            lab = LABEL_RE.match(s)
            if lab and s.split(":", 1)[1].strip() == "":
                if cur:
                    cur["next_kind"] = "LABEL"
                    runs.append(cur)
                    cur = None
                prev_emit_kind = "LABEL"
                continue
            if not emits(s):
                continue
            if s.startswith(".byte"):
                vals = [v.strip() for v in s[5:].split(",") if v.strip()]
                try:
                    b = [int(v, 0) & 0xFF for v in vals]
                except ValueError:
                    b = []
                if cur is None:
                    cur = {"file": rel, "line_lo": i + 1, "line_hi": i + 1,
                           "bytes": [], "prev_kind": prev_emit_kind,
                           "next_kind": None,
                           "addr_lo": amap.get((rel, i + 1))}
                cur["line_hi"] = i + 1
                cur["bytes"].extend(b)
            else:
                kind = "DATA" if s.startswith(".") else "INSN"
                if cur:
                    cur["next_kind"] = kind
                    runs.append(cur)
                    cur = None
                prev_emit_kind = kind
        if cur:
            runs.append(cur)
    return runs


def features(b):
    n = len(b)
    if n == 0:
        return {}
    printable = sum(1 for x in b if 0x20 <= x <= 0x7E)
    f = {
        "n": n,
        "ascii": printable / n,
        "distinct": len(set(b)),
        "zero": b.count(0) / n,
    }
    if n >= 8:
        words = [(b[i], b[i + 1]) for i in range(0, n - 1, 2)]
        f["le16_hi_zero"] = sum(1 for lo, hi in words if hi == 0) / len(words)
        quads = [b[i:i + 4] for i in range(0, n - 3, 4)]
        ok = sum(1 for q in quads
                 if len(q) == 4 and q[3] == 0 and 0xE0 <= q[2] <= 0xFF)
        f["ptr24"] = ok / len(quads) if quads else 0.0
    else:
        f["le16_hi_zero"] = 0.0
        f["ptr24"] = 0.0
    return f


def region_of(addr, sym_addrs, addr_to_names):
    """(region_start, region_end, [labels inside]) for the region holding addr."""
    if addr is None:
        return None
    j = bisect.bisect_right(sym_addrs, addr) - 1
    if j < 0:
        return None
    start = sym_addrs[j]
    end = sym_addrs[j + 1] if j + 1 < len(sym_addrs) else start + 1
    return start, end, addr_to_names[start]


def classify(run, refs, sym_addrs, addr_to_names):
    b = run["bytes"]
    f = features(b)
    reg = region_of(run["addr_lo"], sym_addrs, addr_to_names)
    branch = addr = 0
    names = []
    if reg:
        start, end, names = reg
        # every label anywhere in the enclosing region counts
        i = bisect.bisect_left(sym_addrs, start)
        while i < len(sym_addrs) and sym_addrs[i] < end:
            for nm in addr_to_names[sym_addrs[i]]:
                branch += refs.get(nm, {}).get("BRANCH", 0)
                addr += refs.get(nm, {}).get("ADDR", 0)
            i += 1
    island = run["prev_kind"] == "INSN" and run["next_kind"] == "INSN"
    addr_only = branch == 0
    if island and not addr_only:
        cls, why = "a", "island between instructions, region is branch-referenced"
    elif island and addr_only:
        cls, why = "b", "island among mnemonics in an address-only region (data-as-code residue)"
    elif addr_only and f["n"] >= 8 and f["ascii"] >= 0.60:
        cls, why = "b", "address-only region, %.0f%% printable ASCII" % (100 * f["ascii"])
    elif addr_only and f["n"] >= 8 and f["ptr24"] >= 0.90:
        cls, why = "b", "address-only region, reads as a 24-bit pointer table"
    elif addr_only and f["n"] >= 16 and f["le16_hi_zero"] >= 0.90 and f["distinct"] > 2:
        cls, why = "b", "address-only region, reads as LE16 scalars (high byte 0)"
    elif not addr_only and not island:
        cls, why = "c", "branch-referenced region but the run is a block, not an island"
    else:
        cls, why = "c", "byte-valued table, no wider element type evidenced"
    run.update(f)
    run["branch_refs"] = branch
    run["addr_refs"] = addr
    run["island"] = island
    run["labels"] = names[:3]
    run["cls"] = cls
    run["why"] = why
    run["blind"] = BLIND_LEAD.get(b[0]) if b else None
    run["ctrl_lead"] = bool(b) and b[0] in CONTROL_LEAD
    return run


def control(refs, sym_addrs, addr_to_names, amap):
    """Score the same address-only test against 266 hand-adjudicated spans."""
    man = json.load(open(MANIFEST))
    truth = [("DATA", e) for e in man["converted"]] + \
            [("CODE", e) for e in man["excluded"]]
    conf = Counter()
    for label, e in truth:
        lo = int(e["addr_lo"], 16)
        reg = region_of(lo, sym_addrs, addr_to_names)
        branch = 0
        if reg:
            start, end, _ = reg
            i = bisect.bisect_left(sym_addrs, start)
            while i < len(sym_addrs) and sym_addrs[i] < end:
                for nm in addr_to_names[sym_addrs[i]]:
                    branch += refs.get(nm, {}).get("BRANCH", 0)
                i += 1
        verdict = "CODE" if branch else "DATA"
        conf[(label, verdict)] += 1
    print("CONTROL -- address-only test vs 266 hand-adjudicated v10 spans")
    print("(rows = hand verdict, cols = this script's branch-reference test)")
    print("%-10s %10s %10s" % ("", "says CODE", "says DATA"))
    for t in ("CODE", "DATA"):
        print("%-10s %10d %10d" % (t, conf[(t, "CODE")], conf[(t, "DATA")]))
    tot = sum(conf.values())
    agree = conf[("CODE", "CODE")] + conf[("DATA", "DATA")]
    print("agreement %d/%d = %.1f%%" % (agree, tot, 100.0 * agree / tot))
    print("false CODE (data called code): %d" % conf[("DATA", "CODE")])
    print("false DATA (code called data): %d" % conf[("CODE", "DATA")])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--dir", default=SEQDIR)
    ap.add_argument("--json")
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--list", choices=["a", "b", "c"])
    ap.add_argument("--blocked", action="store_true",
                    help="list every run tagged (d) BLOCKED with its blocking byte")
    args = ap.parse_args()

    amap = load_amap(args.amap)
    syms = load_symbols()
    addr_to_names = defaultdict(list)
    for nm, a in syms.items():
        addr_to_names[a].append(nm)
    sym_addrs = sorted(addr_to_names)
    refs = build_reference_index()

    if args.control:
        control(refs, sym_addrs, addr_to_names, amap)
        return

    files = []
    for dirpath, _d, fns in os.walk(args.dir):
        files += [os.path.join(dirpath, f) for f in sorted(fns) if f.endswith(".s")]
    runs = [classify(r, refs, sym_addrs, addr_to_names) for r in collect_runs(amap, sorted(files))]

    by_cls = Counter()
    by_file = defaultdict(Counter)
    noaddr = 0
    blind_cross = Counter()
    blind_lead = Counter()
    n_runs_blind = n_runs_ctrl = 0
    for r in runs:
        by_cls[r["cls"]] += r["n"]
        by_file[r["file"]][r["cls"]] += r["n"]
        if r["addr_lo"] is None:
            noaddr += r["n"]
        if r["blind"]:
            blind_cross[r["cls"]] += r["n"]
            blind_lead[r["bytes"][0]] += 1
            n_runs_blind += 1
        if r["ctrl_lead"]:
            n_runs_ctrl += 1
    isl = [r for r in runs if r["island"]]
    isl_blind = sum(1 for r in isl if r["blind"])
    isl_ctrl = sum(1 for r in isl if r["ctrl_lead"])
    total = sum(by_cls.values())
    NAME = {"a": "(a) CODE-AS-BYTE", "b": "(b) UNTYPED-DATA", "c": "(c) BYTE-TABLE-OK"}
    print("v10/maincpu/sequencer -- .byte operand triage")
    print("runs=%d  operands=%d  (%d operands had no address in the map)"
          % (len(runs), total, noaddr))
    for c in "abc":
        print("  %-20s %6d  %5.1f%%" % (NAME[c], by_cls[c], 100.0 * by_cls[c] / total))
    print()
    print("%-46s %7s %7s %7s" % ("file", "a", "b", "c"))
    for f in sorted(by_file, key=lambda x: -sum(by_file[x].values())):
        cc = by_file[f]
        print("%-46s %7d %7d %7d" % (f.replace("v10/maincpu/sequencer/", ""),
                                     cc["a"], cc["b"], cc["c"]))

    print()
    print("(d) BLOCKED -- runs starting with an undecodable leading byte")
    print("  %d of %d runs (%.1f%%) start with one of {01,04,17,1a,1c};"
          % (n_runs_blind, len(runs), 100.0 * n_runs_blind / len(runs)))
    print("  %d of %d runs (%.1f%%) start with the control set {02,03,05,16,1b}"
          % (n_runs_ctrl, len(runs), 100.0 * n_runs_ctrl / len(runs)))
    if n_runs_ctrl:
        print("  enrichment over control: %.1fx" % (n_runs_blind / n_runs_ctrl))
    print("  blocked operands by structural class: " + ", ".join(
        "%s=%d" % (c, blind_cross[c]) for c in "abc"))
    print("  blocking byte: " + ", ".join(
        "0x%02x %s x%d" % (b, BLIND_LEAD[b], n) for b, n in blind_lead.most_common()))

    print("  ISLAND-ONLY (runs wedged between two instructions -- the only")
    print("  population where the enrichment argument's premise holds, since a")
    print("  run this lane MADE by typing a data region has a leading byte the")
    print("  decoder never chose): %d/%d blind (%.1f%%) vs %d/%d control (%.1f%%)"
          % (isl_blind, len(isl), 100.0 * isl_blind / max(1, len(isl)),
             isl_ctrl, len(isl), 100.0 * isl_ctrl / max(1, len(isl))))

    if args.blocked:
        print()
        for r in sorted(runs, key=lambda x: -x["n"]):
            if r["blind"]:
                print("%6d B  cls=%s  0x%06X  %s:%d-%d  %s  blocked by 0x%02x (%s)"
                      % (r["n"], r["cls"], r["addr_lo"] or 0, r["file"],
                         r["line_lo"], r["line_hi"], (r["labels"] or ["?"])[0],
                         r["bytes"][0], r["blind"]))

    if args.list:
        print()
        for r in sorted(runs, key=lambda x: -x["n"]):
            if r["cls"] == args.list:
                print("%6d B  %s:%d-%d  %s  branch=%d addr=%d  %s"
                      % (r["n"], r["file"], r["line_lo"], r["line_hi"],
                         (r["labels"] or ["?"])[0], r["branch_refs"],
                         r["addr_refs"], r["why"]))
    if args.json:
        with open(args.json, "w") as fh:
            json.dump(runs, fh, indent=1)
        print("\nwrote", args.json)


if __name__ == "__main__":
    main()
