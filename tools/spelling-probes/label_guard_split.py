#!/usr/bin/env python3
"""What is `rewrite declined silently` actually declining, and what does it COST?

QUESTION ANSWERED
-----------------
`convert_reachable_ranges.py --apply` ends with a refusal tally whose largest
BYTE bucket is a bucket with no stated reason:

    refused   64  rewrite declined silently (usually a label it will not drop)
    ... 6,005 bytes behind: rewrite declined silently (usually a label ...)

"Usually" is not a measurement.  This probe splits that bucket into causes and
prices each one SEPARATELY:

  (a) a CORRECT refusal -- something in the range is corroborated evidence that
      the converter's framing is wrong, or there is simply nothing convertible
      before the obstacle;
  (b) a LIMITATION of the rewriting code -- the range holds a prefix that is
      already proven code and is thrown away together with the part that is
      blocked.

⚠ THE TWO NUMBERS ARE NOT ADDED TOGETHER ANYWHERE IN THE OUTPUT, and neither is
the bucket's 6,005 bytes ever reported as "recoverable".  What (b) could recover
is the PREFIX bytes, which this probe measures with the converter's own
`rewrite()`, not the whole range.  (spec anti-patterns 3 and 9.)

WHERE THE BUCKET COMES FROM
    `rewrite()` has eight ways to decline.  Six record a REFUSED reason; two do
    not, and main() counts exactly those two here:
      S1  the NEVER-DROP-A-LABEL guard -- a labelled `.byte` block starts strictly
          inside [entry, entry+span) at an address the decode does not treat as
          an instruction start;
      S2  the fall-through `return None` at the end of the function (no covering
          block in the index it was handed).
    S2 should be unreachable, because main() only calls rewrite() for a file it
    has already checked has a covering block.  The probe counts it anyway --
    "should be unreachable" is how the 103 ranges that vanished from an earlier
    report were lost (see the comment in main()).

WHAT IT MEASURES

  1. RECONCILIATION.  The converter's own printed counter versus the ranges the
     probe saw declined silently.  These MUST be equal; if they are not, the
     probe is measuring something else and says so.  This control can fail.

  2. THE BLOCKING LABELS, per range: address, span, and every label the guard
     objected to.

  3. IS THE LABEL'S ADDRESS CORROBORATED?  Two kinds of evidence that are NOT
     interchangeable, and the difference is the whole point:
       ADDRESS evidence, v7 only -- the label's v7 address appears as a
         little-endian u32 somewhere in the v7 ROM (a pointer table entry the
         firmware dereferences), or the name is used on a `.long`-family
         directive in v7, or the address is in the reachability entry set.
         A pointer the firmware follows outranks any cross-revision heuristic
         (spec anti-pattern 16).
       NAME evidence, v9/v10 -- the same name is referenced in a sibling tree.
         v7's tree was seeded from v9's, so a v7 interior label's ADDRESS is
         v9's offset replayed onto v7's bytes; a v9 reference therefore says the
         label must not be DELETED and says NOTHING about whether its v7 address
         is an instruction boundary.  (spec anti-pattern 12: 8,203 of 9,975
         v7 labels that nothing in v7 references ARE referenced in v9/v10.)
     The u32 scan gets its NULL printed next to it, computed exactly rather than
     sampled: |{in-band u32 values in the ROM}| / 2^21 is the probability that an
     arbitrary in-band address would "hit" (spec anti-pattern 10).

  4. WHAT A CUT AT THE FIRST BLOCKING LABEL WOULD RECOVER.  For each range, keep
     only the instructions that END AT OR BEFORE the first blocking label and
     hand that truncated range to the REAL `rewrite()`, with every repo write
     intercepted.  Cutting there is compatible with BOTH readings of the
     conflict -- if the label is a real instruction start the kept instructions
     all lie before it, and if the label is spurious the kept instructions are
     unaffected -- and it moves, deletes and adds NO label, so it is byte-neutral
     by construction.  The verdict per range is the converter's own.

  5. THE CAUSE SPLIT, printed as separate lines with separate byte totals.

WHAT THIS PROBE DOES NOT DO
    It does not modify the tree.  Every write whose path is inside the repo is
    intercepted and discarded (self-tested at startup, including the negative
    control that a write OUTSIDE the repo still goes through).  It never runs the
    converter's `--apply` for real.

REQUIRES  rebuilt_ROMs/kn5000_{v7,v9,v10}_program.llvm.elf (a completed
`make all`), ~/compartilhado/tools/unidasm, and the LLVM build.  ~4 minutes.

⚠ Do not run it while a conversion round is in flight (`tools/closure-loop.sh`):
the sources are then a moving target and the bucket changes under the probe.
Section 0 prints the tree state it measured so a number can be tied to a tree.

Run:  python3 tools/spelling-probes/label_guard_split.py [--fast] [--json OUT]
        --fast   skip the .incbin site index (it costs an llvm-mc + ld.lld pass
                 over the whole tree).  The silent bucket is produced entirely
                 by the `.byte` pass, so this does not change it -- section 1
                 re-checks that against the converter's own counter either way.
"""
import collections, contextlib, hashlib, importlib.util, io, json, os, re
import struct, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
_real_open = open


# ----------------------------------------------------------- write interception
class _Sink:
    """A file object that accepts writes and drops them."""
    def __init__(self, path): self.path = path
    def write(self, data): return len(data)
    def writelines(self, seq): return None
    def flush(self): return None
    def close(self): return None
    def __enter__(self): return self
    def __exit__(self, *a): return False


def guarded_open(path, mode="r", *a, **kw):
    if any(c in mode for c in "wax+") and \
            os.path.abspath(str(path)).startswith(os.path.abspath(REPO) + os.sep):
        return _Sink(path)
    return _real_open(path, mode, *a, **kw)


def selftest_write_guard():
    """Prove the interception both BLOCKS and PASSES THROUGH. Exits on failure."""
    victim = os.path.join(REPO, "__label_guard_split_selftest__")
    fh = guarded_open(victim, "wb")
    fh.write(b"this must never reach the disk")
    fh.close()
    if not isinstance(fh, _Sink) or os.path.exists(victim):
        sys.exit("write guard FAILED: a repo write was not intercepted")
    outside = os.path.join("/tmp", "__label_guard_split_selftest__")
    fh = guarded_open(outside, "wb")
    fh.write(b"x")
    fh.close()
    if isinstance(fh, _Sink) or not os.path.exists(outside):
        sys.exit("write guard FAILED: a NON-repo write was intercepted "
                 "(the converter's scratch decode would break)")
    os.remove(outside)
    return "repo write discarded, non-repo write passed through"


def load(name, rel, argv=None):
    sp = importlib.util.spec_from_file_location(name, os.path.join(REPO, rel))
    m = importlib.util.module_from_spec(sp)
    saved, sys.argv = sys.argv, argv or [name]
    try:
        sp.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


# ------------------------------------------- 1. run the converter, watch rewrite
def collect(fast):
    """Every range rewrite() declined WITHOUT recording a reason, plus its inputs.

    Runs the real `--apply` path.  Nothing is re-implemented here: the bucket
    membership is decided by the converter's own code, and the probe only reads
    which REFUSED counter moved (or did not).
    """
    os.chdir(REPO)
    argv = ["convert_reachable_ranges.py", "--apply"] + (["--no-incbin"] if fast else [])
    mod = load("crr", "scripts/converters/convert_reachable_ranges.py", argv)
    mod.open = guarded_open
    mod.cc.open = guarded_open
    real = mod.rewrite
    cases, seen_all = [], []

    def hook(idx, t, span, insns, texts, addr2name, branch_labels=None):
        rec = {"entry": t, "span": span}
        hit = None
        for path, (lines, blocks) in idx.items():
            if not any(bk[1] <= t < bk[1] + len(bk[4]) for bk in blocks):
                continue
            touched = sorted([bk for bk in blocks
                              if bk[1] < t + span and bk[1] + len(bk[4]) > t],
                             key=lambda bk: bk[2])
            ia = {a for a, _n, _x in insns}
            # EXACTLY the guard's own predicate, copied from rewrite():
            #   la != first[1] and not (la < t or la >= t+span) and la not in insn_addrs
            first = touched[0]
            hit = (path, lines, blocks)
            rec.update(path=path,
                       blocks_touched=[(bk[0], bk[1], len(bk[4])) for bk in touched],
                       off=sorted((bk[1], bk[0]) for bk in touched
                                  if bk[0] and bk[1] != first[1]
                                  and t <= bk[1] < t + span and bk[1] not in ia))
            break
        before = dict(mod.REFUSED)
        res = real(idx, t, span, insns, texts, addr2name, branch_labels)
        silent = (res is None and mod.REFUSED == before)
        seen_all.append({"entry": t, "span": span,
                         "silent": silent, "applied": res is not None})
        if silent:
            # SNAPSHOT ONLY NOW.  rewrite() mutates `lines` in place when it
            # SUCCEEDS, and a declined call cannot have mutated anything, so the
            # list is still exactly what this call saw -- and copying only the 60-odd
            # declined cases keeps this from holding a copy of every source file
            # once per range.
            if hit is not None:
                rec.update(lines=list(hit[1]), blocks=list(hit[2]),
                           insns=[(a, n, x) for a, n, x in insns], texts=list(texts),
                           addr2name=addr2name, br=dict(branch_labels or {}))
            cases.append(rec)
        return res

    mod.rewrite = hook
    buf = io.StringIO()
    saved, sys.argv = sys.argv, argv
    try:
        with contextlib.redirect_stdout(buf):
            mod.main()
    finally:
        sys.argv = saved
        mod.rewrite = real          # trial_cut() must reach the REAL rewrite()
    return mod, cases, seen_all, buf.getvalue()


# --------------------------------------------------- 2. references for a label
LABEL_DEF = re.compile(r'^([A-Za-z_][\w]*):')
WORD = re.compile(r'[A-Za-z_][\w]*')
PTR_DIRECTIVE = re.compile(r'^\s*\.(long|word|quad|int|short|hword)\b')


def tree_refs(tree, names):
    """(refs, ptr_refs, defs) counters for `names` over one source tree.

    ⚠ Files are read as BYTES and decoded latin-1: 65 of this project's 506
    sources hold bytes above 127 and a text-mode recursive grep skips them
    silently (spec anti-pattern 9).  A reference is any occurrence of the name
    that is not its own definition; ptr_refs additionally requires the line to
    be a `.long`-family directive, i.e. an address baked into the ROM's bytes.
    """
    refs, ptr, defs = collections.Counter(), collections.Counter(), collections.Counter()
    if not names:
        return refs, ptr, defs
    hunt = re.compile(r'\b(?:' + "|".join(re.escape(n) for n in sorted(names)) + r')\b')
    root = os.path.join(REPO, tree)
    nfiles = 0
    for dirpath, _d, files in os.walk(root):
        for fn in sorted(files):
            if not fn.endswith(".s"):
                continue
            nfiles += 1
            with _real_open(os.path.join(dirpath, fn), "rb") as fh:
                text = fh.read().decode("latin-1")
            for line in text.split("\n"):
                m = LABEL_DEF.match(line)
                if m:
                    if m.group(1) in names:
                        defs[m.group(1)] += 1
                    rest = line[m.end():]
                else:
                    rest = line
                if not rest:
                    continue
                hits = hunt.findall(rest)
                if not hits:
                    continue
                isptr = bool(PTR_DIRECTIVE.match(rest))
                for w in hits:
                    refs[w] += 1
                    if isptr:
                        ptr[w] += 1
    return refs, ptr, defs, nfiles


def rom_u32_index(rom):
    """Every in-band 32-bit LE value in the ROM, and the exact null hit rate."""
    vals = set()
    top = BASE + len(rom)
    for i in range(0, len(rom) - 3):
        w = struct.unpack_from("<I", rom, i)[0]
        if BASE <= w < top:
            vals.add(w)
    return vals, len(vals) / float(len(rom))


# ---------------------------------- 3. would a cut at the first blocking label help?
def trial_cut(mod, case):
    """Hand the real rewrite() the range TRUNCATED at its first blocking label.

    Kept instructions are those that END AT OR BEFORE that label, so the cut is
    valid under both readings of the conflict.  No label is added, moved or
    dropped, and the byte count is preserved by rewrite()'s own invariant, which
    still runs here.  Returns (verdict, kept_instructions, kept_bytes, detail).
    """
    t, span = case["entry"], case["span"]
    la = min(a for a, _n in case["off"])
    insns, texts = case["insns"], case["texts"]
    k = 0
    for a, n, _x in insns:
        if a + n <= la:
            k += 1
        else:
            break
    span2 = sum(n for _a, n, _x in insns[:k])
    if k < 3:
        return "NO-PREFIX", k, span2, f"only {k} instruction(s) end at or before 0x{la:06X}"
    insns2, texts2 = insns[:k], texts[:k]
    br2 = {a: l for a, l in case["br"].items() if t <= a < t + span2}
    live = set(br2.values())
    orphan = [x for x in texts2 if x and ".Lc_" in x and x.rsplit(None, 1)[-1] not in live]
    if orphan:
        return "ORPHAN-BRANCH", k, span2, f"{len(orphan)} branch(es) target past the cut"
    saved_r, saved_b = dict(mod.REFUSED), dict(mod.REFUSED_BYTES)
    idx = {case["path"]: (list(case["lines"]), case["blocks"])}
    try:
        res = mod.rewrite(idx, t, span2, insns2, texts2, case["addr2name"], br2)
    except Exception as exc:                       # noqa: BLE001 - report, never mask
        mod.REFUSED.clear(); mod.REFUSED.update(saved_r)
        mod.REFUSED_BYTES.clear(); mod.REFUSED_BYTES.update(saved_b)
        return "EXCEPTION", k, span2, f"{type(exc).__name__}: {exc}"
    moved = [r for r, n in mod.REFUSED.items() if n != saved_r.get(r, 0)]
    mod.REFUSED.clear(); mod.REFUSED.update(saved_r)
    mod.REFUSED_BYTES.clear(); mod.REFUSED_BYTES.update(saved_b)
    if res is not None:
        return "ACCEPTED", k, span2, os.path.relpath(res, REPO)
    return "STILL-REFUSED", k, span2, (moved[0] if moved else "silent again")


def tree_state():
    def git(*args):
        return subprocess.run(["git"] + list(args), cwd=REPO,
                              capture_output=True, text=True).stdout.strip()
    head = git("rev-parse", "--short", "HEAD")
    dirty = git("status", "--porcelain")
    conv = os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py")
    with _real_open(conv, "rb") as fh:
        md5 = hashlib.md5(fh.read()).hexdigest()[:12]
    return head, len([x for x in dirty.split("\n") if x.strip()]), md5


def main():
    fast = "--fast" in sys.argv
    guard = selftest_write_guard()
    head, ndirty, md5 = tree_state()
    print("### 0. what was measured")
    print(f"  repo               : {REPO}")
    print(f"  git HEAD           : {head}   working-tree entries modified/untracked: {ndirty}")
    print(f"  converter md5      : {md5}  (scripts/converters/convert_reachable_ranges.py)")
    print(f"  write guard        : {guard}")
    print(f"  .incbin site index : {'SKIPPED (--fast)' if fast else 'built'}")

    mod, cases, seen_all, log = collect(fast)
    cases.sort(key=lambda c: c["entry"])
    rom = _real_open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()

    # ---- 1. reconciliation -------------------------------------------------
    m = re.search(r'refused\s+(\d+)\s+rewrite declined silently', log)
    mb = re.search(r'\.\.\.\s+([\d,]+) bytes behind: rewrite declined silently', log)
    conv_n = int(m.group(1)) if m else -1
    conv_b = int(mb.group(1).replace(",", "")) if mb else -1
    obs_n, obs_b = len(cases), sum(c["span"] for c in cases)
    s1 = [c for c in cases if c.get("off")]
    s2 = [c for c in cases if "path" not in c or not c.get("off")]
    print("\n### 1. reconciliation -- is this bucket what the counter counts?")
    print(f"  converter printed  : {conv_n} range(s), {conv_b:,} bytes")
    print(f"  probe observed     : {obs_n} range(s), {obs_b:,} bytes")
    ok = (conv_n == obs_n and conv_b == obs_b)
    verdict = "MATCH" if ok else "*** MISMATCH -- the split below is about something else ***"
    print(f"  agreement          : {verdict}")
    print(f"  ranges reaching rewrite() at all: {len(seen_all)} "
          f"({sum(1 for c in seen_all if c['applied'])} applied)")
    print(f"  S1 NEVER-DROP-A-LABEL guard      : {len(s1)} range(s), "
          f"{sum(c['span'] for c in s1):,} bytes")
    print(f"  S2 no off-boundary label found   : {len(s2)} range(s), "
          f"{sum(c['span'] for c in s2):,} bytes")
    print(f"     (S2 means the fall-through `return None`, OR that the probe's copy of the")
    print(f"      guard predicate disagrees with rewrite()'s.  Either way it is a defect to")
    print(f"      chase, not a cause to quote -- it should be 0.)")
    if not ok:
        print("\n  ⚠ Reported anyway, but do not quote the split below until this line "
              "says MATCH.")

    # ---- 2/3. the labels and their corroboration ---------------------------
    names = sorted({n for c in cases for _a, n in c.get("off", [])})
    addrs = {n: a for c in cases for a, n in c.get("off", [])}
    r7, p7, d7, n7 = tree_refs("v7/maincpu", set(names))
    r9, p9, _d9, n9 = tree_refs("v9/maincpu", set(names))
    r10, p10, _d10, n10 = tree_refs("v10/maincpu", set(names))
    ptr, null = rom_u32_index(rom)
    tj = os.path.join(REPO, "analysis/v7-reachability/v7_branch_closure_targets.json")
    if not os.path.exists(tj):
        tj = os.path.join(REPO, "analysis/v7-reachability/v7_call_targets.json")
    with _real_open(tj) as fh:
        tset = {int(x, 16) if isinstance(x, str) else x for x in json.load(fh)["targets"]}

    def addr_evidence(n):
        """v7-side evidence that this label's ADDRESS is an instruction boundary."""
        a = addrs[n]
        e = []
        if a in ptr:
            e.append("u32")
        if p7[n]:
            e.append(f".long*{p7[n]}")
        if a in tset:
            e.append("entry")
        return e

    def name_evidence(n):
        """sibling-tree evidence that the NAME is live (says nothing about the address)."""
        e = []
        if r7[n] - d7[n] > 0:
            e.append(f"v7*{r7[n]-d7[n]}")
        if r9[n]:
            e.append(f"v9*{r9[n]}")
        if r10[n]:
            e.append(f"v10*{r10[n]}")
        return e

    print("\n### 2/3. the blocking labels, and what corroborates them")
    print(f"  distinct blocking labels: {len(names)} across {len(s1)} range(s)")
    print(f"  search window: every `.s` file under v7/maincpu ({n7}), v9/maincpu ({n9}) and "
          f"v10/maincpu ({n10}),\n  read as bytes and decoded latin-1; plus every byte offset "
          f"of the {len(rom):,}-byte v7 ROM for the u32 test.")
    print(f"  ADDRESS evidence (v7 only -- a pointer the firmware follows, a .long in a v7")
    print(f"  source, or membership of the reachability entry set):")
    na = sum(1 for n in names if addr_evidence(n))
    print(f"    labels with address evidence : {na}/{len(names)}")
    print(f"    NULL for the u32 test        : {100*null:.2f}% of ALL in-band addresses "
          f"appear as a u32 in this ROM")
    hit = sum(1 for n in names if addrs[n] in ptr)
    print(f"    observed u32 hit rate        : {hit}/{len(names)} = "
          f"{100.0*hit/max(len(names),1):.2f}%   (compare with the null on the line above)")
    nn = sum(1 for n in names if name_evidence(n))
    print(f"  NAME evidence (v7/v9/v10 references -- says the label must not be DELETED,")
    print(f"  says NOTHING about whether its v7 address is an instruction boundary, because")
    print(f"  v7's interior label offsets were transplanted from v9):")
    print(f"    labels referenced somewhere  : {nn}/{len(names)}")
    print(f"    referenced ONLY in v9/v10    : "
          f"{sum(1 for n in names if not (r7[n]-d7[n]) and (r9[n] or r10[n]))}")
    print(f"    referenced nowhere at all    : {len(names)-nn}")

    # ---- 4. the cut trial --------------------------------------------------
    rows = []
    for c in cases:
        if not c.get("off"):
            rows.append(dict(entry=c["entry"], span=c["span"], labels=[],
                             verdict="S2-FALL-THROUGH", kept=0, kept_bytes=0,
                             detail="rewrite() found no covering block", addr_ev=[], name_ev=[]))
            continue
        verdict, kept, kept_bytes, detail = trial_cut(mod, c)
        ln = [n for _a, n in c["off"]]
        rows.append(dict(entry=c["entry"], span=c["span"], labels=ln, verdict=verdict,
                         kept=kept, kept_bytes=kept_bytes, detail=detail,
                         addr_ev=sorted({e for n in ln for e in addr_evidence(n)}),
                         name_ev=sorted({e.split("*")[0] for n in ln for e in name_evidence(n)})))

    print("\n### 4. per range: the labels, the evidence, and what a cut at the first one keeps")
    print(f"{'entry':>9} {'B':>5} {'keep':>5} {'verdict':<14} {'addr-ev':<18} "
          f"{'name-ev':<12} labels")
    for r in rows:
        print(f"0x{r['entry']:06X} {r['span']:5} {r['kept_bytes']:5} {r['verdict']:<14} "
              f"{','.join(r['addr_ev']) or '-':<18} {','.join(r['name_ev']) or '-':<12} "
              f"{', '.join(r['labels'])[:60]}")

    # ---- 5. the split, reported per cause, never summed --------------------
    def tot(pred):
        sel = [r for r in rows if pred(r)]
        return len(sel), sum(r["span"] for r in sel), sum(r["kept_bytes"] for r in sel)

    print("\n### 5. THE CAUSE SPLIT.  Counts and bytes are per cause and are NOT added up.")
    print("  Column 'range B' is the bytes the refusal currently withholds; column 'prefix B'")
    print("  is the bytes a cut at the first blocking label would convert -- only the second")
    print("  is a recoverable number, and only for the rows marked (b).")
    print(f"\n  {'cause':<46} {'ranges':>6} {'range B':>8} {'prefix B':>9}")
    order = [
        ("(b) whole range dropped for a label near its end", lambda r: r["verdict"] == "ACCEPTED"),
        ("(a) nothing convertible before the first label", lambda r: r["verdict"] == "NO-PREFIX"),
        ("(a) cut would orphan an internal branch label", lambda r: r["verdict"] == "ORPHAN-BRANCH"),
        ("(?) cut still refused, for a NAMED reason", lambda r: r["verdict"] == "STILL-REFUSED"),
        ("(?) cut raised an exception", lambda r: r["verdict"] == "EXCEPTION"),
        ("(?) S2 fall-through, not the label guard", lambda r: r["verdict"] == "S2-FALL-THROUGH"),
    ]
    for label, pred in order:
        n, b, k = tot(pred)
        if n:
            print(f"  {label:<46} {n:6} {b:8,} {k:9,}")
    acc = [r for r in rows if r["verdict"] == "ACCEPTED"]
    haz = [r for r in rows if r["addr_ev"]]
    print(f"\n  CROSS-CUTTING, not part of the partition above:")
    print(f"    ranges holding >=1 label with ADDRESS evidence : {len(haz)} "
          f"({sum(r['span'] for r in haz):,} B)")
    print(f"      ...of those, the cut is still ACCEPTED       : "
          f"{sum(1 for r in haz if r['verdict'] == 'ACCEPTED')}")
    print(f"    a cut converts NOTHING past any blocking label, so it neither moves, deletes")
    print(f"    nor adds a label; the labels above keep their addresses whichever way this goes.")
    if acc:
        print(f"\n  If and only if the (b) rows are acted on, the gain is "
              f"{len(acc)} range(s) / {sum(r['kept_bytes'] for r in acc):,} bytes,")
        print(f"  NOT the {sum(r['span'] for r in acc):,} bytes those ranges span and NOT the "
              f"{obs_b:,} bytes of the bucket.")
    if "--json" in sys.argv:
        out = sys.argv[sys.argv.index("--json") + 1]
        with _real_open(out, "w") as fh:
            json.dump({"head": head, "converter_md5": md5,
                       "counter": {"ranges": conv_n, "bytes": conv_b},
                       "observed": {"ranges": obs_n, "bytes": obs_b},
                       "u32_null": null,
                       "rows": [dict(r, entry=f"0x{r['entry']:06X}") for r in rows]}, fh, indent=1)
        print(f"\n  json: {out}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
