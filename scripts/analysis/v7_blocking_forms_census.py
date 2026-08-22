#!/usr/bin/env python3
"""What still blocks the v7 `.byte` -> instruction converter, ranked by BYTES?

QUESTION THIS ANSWERS
  `convert_reachable_ranges.py` truncates a range at the first instruction it
  cannot spell so that llvm-mc reproduces the ROM bytes exactly.  Which forms
  are those, and -- the number that should decide what to work on next -- how
  many BYTES would each one release if it were spellable?

WHY NOT `convert_reachable_ranges.py --forms`
  That counter records at most ONE form per RANGE: the converter stops at the
  first unspellable instruction, so a range that also holds three more of a
  different form attributes nothing to them.  It UNDERCOUNTS, and it counts
  instances, not bytes.  This script decodes every range to its full extent and
  collects EVERY unspellable instruction in it, then re-runs the converter's own
  byte accounting once per candidate form.

UNITS -- every column says what it counts, because confusing them has caused
real errors here:
  RANGE     one reachable call target and the run of instructions decoded from
            it.  A range is the unit the converter converts or skips.
  SITE      one decoded INSTRUCTION occurrence that cannot be spelled.  A range
            can hold many sites, of the same form or of different forms.
  BYTE      a ROM byte that would move from `.byte` to an instruction.  This is
            the ranking key.  "marginal" = bytes gained if THAT ONE form became
            spellable and nothing else changed; it is a counterfactual re-run of
            the converter's accounting, not a byte count of the sites.

HOW THE MARGINAL BYTES ARE COMPUTED
  For each range the converter keeps the instructions BEFORE its first
  unspellable one (and drops the range entirely if fewer than 3 survive).  For
  candidate form F the same accounting is re-run with F's sites treated as
  spellable, so the range now truncates at its first blocker whose form is not
  F.  marginal(F) = sum over ranges of (bytes with F fixed - bytes today).
  That is an honest per-form figure: fixing F alone really does yield it.  The
  figures do NOT add up across forms -- a range blocked by F then G gives its
  bytes to whichever is fixed first -- so a greedy cumulative table is printed
  too, and that one is the right one to read for "the next five rules".

  ⚠ One optimism in the counterfactual: it assumes the hypothetical spelling
  assembles byte-exactly.  If the form turns out to be data, or to have no
  encoding at all, the bytes are not really there.  Hence the code check.

NOT EVERYTHING THAT BLOCKS IS A SPELLING
  The converter runs one more gate after spelling: it re-assembles the kept
  prefix as ONE block and requires the bytes back.  This census replays that
  gate and reports it separately, because it turns out to hold back more bytes
  than every spelling form put together -- and it is a DEFECT, not a property of
  the ROM.  A branch to an external symbol assembles to
  `; encoding: [0x6e,A]`: the displacement is a placeholder the LINKER fills in.
  `cc.encode_block` reads that `A` as 0x0A, so any block containing such a
  branch fails the byte comparison no matter what.  The converter already knows
  this -- `resolve_branches` deliberately checks only the LENGTH of a symbolic
  branch -- and then compares the bytes anyway in the last gate.
  The "bytes convert today" line therefore has two levels, and both are printed.

IS IT ACTUALLY CODE?
  Several past "blockers" were data being decoded as instructions, and a
  spelling rule for a form that only occurs in data is wasted work.  Two
  independent checks are reported per form:

  v9-CODE   the site's exact bytes appear in the v9 ROM at an address the
            byte-exact v9 build emits an INSTRUCTION at.  The v9 sources
            re-assemble byte-identical to the original ROM; built with
            `llvm-mc -g` their DWARF line table carries one row per emitting
            source STATEMENT, and `.byte` directives emit NO row (verified
            directly -- see README-blocking-forms-census.md).  So a row address
            is an instruction boundary in real, human-checked source.  Same
            leading bytes at a real boundary decode to the same instruction,
            because a byte-stream decoder is deterministic.
            ⚠ Direction: a hit PROVES code.  A miss proves nothing on its own --
            v9 is a different revision and is itself only ~48% expressed as
            instructions, so the form may simply still be inside a v9 `.byte`
            blob.  Read the miss together with the framing column.
  FRAMING   how the range containing the site ends.  `ret` means the decode ran
            from a proven call target to a return instruction; `code` means it
            landed exactly on the first byte of territory the sources ALREADY
            express as instructions.  Either is strong evidence that the whole
            decode, the site included, is correctly framed -- a mis-framed
            decode of data almost never lands on such a boundary.

CONCURRENCY
  A `convert_to_fixpoint.sh` run rewrites the v7 sources while it works, which
  moves the territory map, the call targets and the ELF under a long census.
  So this script SNAPSHOTS its inputs into a private temp dir first and measures
  that.  `--live` measures the working tree instead (faster, but only safe when
  nothing is converting).

RUN
  python3 scripts/analysis/v7_blocking_forms_census.py            # full census
  python3 scripts/analysis/v7_blocking_forms_census.py --limit 40 # smoke test
  python3 scripts/analysis/v7_blocking_forms_census.py --no-oracle
  python3 scripts/analysis/v7_blocking_forms_census.py --json out.json

  Needs `make all` to have produced rebuilt_ROMs/kn5000_v7_program.llvm.elf,
  ~/compartilhado/tools/unidasm and ~/compartilhado/llvm-project/build/bin.
  A full run takes tens of minutes: it decodes ~1100 ranges and probes every
  instruction against llvm-mc.
"""
import collections, importlib.util, json, os, re, shutil, subprocess, sys, tempfile, time

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
BASE = 0xE00000
V7_ELF = "rebuilt_ROMs/kn5000_v7_program.llvm.elf"
TARGETS_JSON = "analysis/v7-reachability/v7_call_targets.json"
ROM_SIZE = 2097152

_cr = importlib.util.spec_from_file_location(
    "cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
cc = cr.cc
_sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)


# ---------------------------------------------------------------- form naming
def form_of(text):
    """The converter's OWN form key, so this census is comparable with --forms.

    Registers collapse to `r` and hex literals to `imm`, e.g.
    `ld L,(0x0462)` -> `ld r,(imm)`.
    """
    parts = text.split(None, 1)
    mn = parts[0]
    rest = parts[1] if len(parts) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                            re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


# ------------------------------------------------------------------ snapshot
def snapshot():
    """Copy every input the census reads into a private dir and return it.

    The concurrent converter rewrites v7/maincpu/*.s, regenerates
    v7_call_targets.json and deletes+rebuilds rebuilt_ROMs/.  A census that
    reads those over half an hour would be measuring several different trees at
    once.
    """
    dest = tempfile.mkdtemp(prefix="kn5000_census_")
    for sub in ("v7/maincpu", "v9/maincpu"):
        shutil.copytree(os.path.join(REPO, sub), os.path.join(dest, sub))
    for rel in (V7_ELF, TARGETS_JSON, "original_ROMs/kn5000_v7_program.rom",
                "original_ROMs/kn5000_v9_program.rom"):
        src = os.path.join(REPO, rel)
        if not os.path.exists(src):
            sys.exit(f"missing input {rel} -- run `make all` first (a concurrent\n"
                     f"`make clean-all` also removes it; wait for the build).")
        os.makedirs(os.path.join(dest, os.path.dirname(rel)), exist_ok=True)
        shutil.copy2(src, os.path.join(dest, rel))
    return dest


def territory_of(root):
    """Per-byte territory map (1 CODE, 2 DATA, 3 PADDING) of a source tree."""
    old = spans.l1.ROOT
    spans.l1.ROOT = root
    try:
        rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
    finally:
        spans.l1.ROOT = old
    total = sum(b - a for a, b, _ in rs)
    if total != ROM_SIZE:
        sys.exit(f"the source tree classifies {total:,} bytes, not {ROM_SIZE:,} -- "
                 "it is mid-write or inconsistent; re-run.")
    return spans.territory(rs)


# ------------------------------------------------------------ per-range decode
def analyse(rom, terr, t, addr2name):
    """Decode one range and label EVERY instruction spellable or not.

    Returns (status, detail, record).  status 'skip' means the converter would
    never convert this range whatever spellings exist, so its unspellable
    instructions are not blockers and are excluded from the ranking.
    """
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3:
        return "skip", "decoded fewer than 3 instructions", None
    off = t - BASE
    run = 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    span = sum(n for _, n, _ in insns)
    ends_at_code = (span == run)
    ends_at_ret = insns[-1][2].split()[0].lower() in cr.TERMINATORS
    if not ends_at_ret and not ends_at_code:
        return "skip", "no `ret`, and does not end at a code boundary", None
    br = cr.resolve_branches(insns, t, span, addr2name)
    if br is None:
        return "skip", "a branch target cannot be named", None
    br_texts, br_labels = br
    want = rom[off:off + span]
    items, pos = [], 0
    for i, (a, n, x) in enumerate(insns):
        tgt = want[pos:pos + n]; pos += n
        spell = None
        if br_texts[i] is not None:
            e = cc.encode(br_texts[i])
            ok = e is not None and len(e) == n
            # A branch the converter cannot encode at the right LENGTH stops the
            # range exactly like an unspellable instruction, so it is a blocker
            # too -- tagged apart because the fix is different work.
            form = None if ok else "BRANCH(len) " + form_of(x)
            spell = br_texts[i] if ok else None
        else:
            ok = False
            for c in list(cc.translate(x)) + [cc.canonical(x)]:
                if cc.encode(c) == tgt:
                    ok, spell = True, c
                    break
            form = None if ok else form_of(x)
        items.append({"addr": a, "n": n, "text": x, "bytes": tgt.hex(),
                      "ok": ok, "form": form, "spell": spell})
    rec = {"target": t, "items": items, "span": span,
           "framing": "ret" if ends_at_ret else "code", "want": want,
           "br_texts": br_texts, "br_labels": br_labels}
    return "ok", rec["framing"], rec


def converted_bytes(rec, fixed):
    """Bytes this range converts, treating every form in `fixed` as spellable.

    Replicates the converter's accounting: truncate at the first blocker, drop
    the range if fewer than 3 instructions survive, and drop it if truncation
    would orphan a `.Lc_` branch label.
    """
    items = rec["items"]
    k = cut_index(rec, fixed)
    if k < len(items) and k < 3:
        return 0
    span = sum(it["n"] for it in items[:k])
    if k < len(items):
        end = rec["target"] + span
        live = {l for a, l in rec["br_labels"].items() if rec["target"] <= a < end}
        for bt in rec["br_texts"][:k]:
            if bt and ".Lc_" in bt and bt.rsplit(None, 1)[-1] not in live:
                return 0
    return span


def cut_index(rec, fixed):
    """Index the converter truncates at, treating `fixed` forms as spellable."""
    for i, it in enumerate(rec["items"]):
        if not it["ok"] and it["form"] not in fixed:
            return i
    return len(rec["items"])


def reassembly_gate(rec):
    """Replay the converter's LAST gate: re-assemble the kept prefix as ONE block.

    Returns "pass", "skipped" (the range has intra-range .Lc_ labels, so the
    converter does not run this check at all), "fixup" or "mismatch".

    ⚠ "fixup" is a DEFECT, not a property of the ROM. A branch to an external
    symbol assembles to `; encoding: [0x6e,A]` -- the displacement byte is the
    literal letter A, a placeholder the linker fills in. cc.encode_block reads
    that as 0x0A, so the byte comparison can never succeed for such a block.
    The converter already knows this (`resolve_branches` checks only the LENGTH
    of a symbolic branch, for exactly this reason) and then compares the bytes
    anyway in this last gate.
    """
    items = rec["items"]
    k = cut_index(rec, frozenset())
    if k < len(items) and k < 3:
        return "n/a"
    span = sum(it["n"] for it in items[:k])
    end = rec["target"] + span
    live = {a: l for a, l in rec["br_labels"].items() if rec["target"] <= a < end}
    if live:
        return "skipped"
    texts = [it["spell"] for it in items[:k]]
    if any(t is None for t in texts):
        return "n/a"
    encs = cc.encode_block(texts)
    if encs is not None and b"".join(encs) == rec["want"][:span]:
        return "pass"
    symbolic = any(bt is not None and ".Lc_" not in bt
                   for bt in rec["br_texts"][:k])
    return "fixup" if symbolic else "mismatch"


# --------------------------------------------------------------- v9 CODE oracle
def v9_instruction_rows(root, tmp):
    """Addresses at which the byte-exact v9 build emits an INSTRUCTION.

    Aborts unless the -g rebuild is still byte-identical to the original v9 ROM;
    a line table from a build that does not match the ROM says nothing about it.
    """
    o, elf, rom = (os.path.join(tmp, n) for n in ("v9g.o", "v9g.elf", "v9g.rom"))
    subprocess.run([f"{LLVM}/llvm-mc", "-triple=tlcs900", "-filetype=obj", "-g",
                    "-I", "v9/maincpu", "-o", o,
                    "v9/maincpu/kn5000_v9_program.s"], cwd=root, check=True)
    subprocess.run([f"{LLVM}/ld.lld", "-e", "0", "-T", "v9/maincpu/maincpu.ld",
                    "-o", elf, o], cwd=root, check=True)
    subprocess.run([f"{LLVM}/llvm-objcopy", "-O", "binary", elf, rom], check=True)
    orig = os.path.join(root, "original_ROMs/kn5000_v9_program.rom")
    if open(rom, "rb").read() != open(orig, "rb").read():
        sys.exit("ABORT: the -g rebuild is NOT byte-identical to the original v9 "
                 "ROM, so its line table says nothing about the real ROM.")
    dl = subprocess.run([f"{LLVM}/llvm-dwarfdump", "--debug-line", elf],
                        capture_output=True, text=True).stdout
    return {int(m, 16) for m in re.findall(r'^0x([0-9a-f]{16})', dl, re.M)}


def corroborate(root, seqs):
    """seq -> address in v9 where those exact bytes are ONE real instruction.

    Two conditions, both needed:
      * the match address is a DWARF source-statement row, i.e. an instruction
        starts there in sources that rebuild byte-identical to the ROM;
      * NO row falls strictly inside the match, so v9 does not express those
        bytes as two or more instructions.  Without this a long encoding could
        be "corroborated" by a pair of short ones that happen to share its bytes.
    """
    import bisect
    with tempfile.TemporaryDirectory() as tmp:
        rows = v9_instruction_rows(root, tmp)
    srows = sorted(rows)
    rom9 = open(os.path.join(root, "original_ROMs/kn5000_v9_program.rom"), "rb").read()
    hit = {}
    for seq in seqs:
        raw, i = bytes.fromhex(seq), 0
        while True:
            i = rom9.find(raw, i)
            if i < 0:
                break
            a = BASE + i
            if a in rows:
                j = bisect.bisect_right(srows, a)
                if j >= len(srows) or srows[j] >= a + len(raw):
                    hit[seq] = a
                    break
            i += 1
    return hit, len(rows)


# ---------------------------------------------------------------------- main
def main():
    argv = sys.argv
    live = "--live" in argv
    top = int(argv[argv.index("--top") + 1]) if "--top" in argv else 20
    limit = int(argv[argv.index("--limit") + 1]) if "--limit" in argv else 0
    oracle = "--no-oracle" not in argv
    out_json = argv[argv.index("--json") + 1] if "--json" in argv else None

    root = REPO if live else snapshot()
    head = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=REPO,
                          capture_output=True, text=True).stdout.strip()
    print(f"census of what blocks convert_reachable_ranges.py")
    print(f"  repo HEAD {head}   {'LIVE working tree' if live else 'snapshot ' + root}")
    print(f"  taken     {time.strftime('%Y-%m-%d %H:%M:%S')}")

    rom = open(os.path.join(root, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    terr = territory_of(root)
    targets = json.load(open(os.path.join(root, TARGETS_JSON)))["targets"]
    syms = cc.elf_syms(os.path.join(root, V7_ELF))
    addr2name = dict(syms)
    code_now = sum(1 for b in terr if b == 1)
    print(f"  inputs    {len(targets)} reachable call targets, {len(syms)} ELF symbols, "
          f"{code_now:,} bytes already CODE")
    if limit:
        targets = sorted(targets)[:limit]
        print(f"  ⚠ --limit {limit}: partial census, not quotable")

    recs, skips = [], collections.Counter()
    t0 = time.time()
    for i, t in enumerate(sorted(targets)):
        st, detail, rec = analyse(rom, terr, t, addr2name)
        if st == "skip":
            skips[detail] += 1
        else:
            recs.append(rec)
        if (i + 1) % 100 == 0:
            print(f"    ... {i+1}/{len(targets)} ranges, {time.time()-t0:.0f}s",
                  file=sys.stderr)

    # ---- baseline and ceiling, in BYTES
    base_bytes = sum(converted_bytes(r, frozenset()) for r in recs)
    all_forms = {it["form"] for r in recs for it in r["items"] if not it["ok"]}
    ceiling = sum(converted_bytes(r, all_forms) for r in recs)
    blocked_ranges = [r for r in recs
                      if any(not it["ok"] for it in r["items"])]
    print(f"\nRANGES  {len(recs)} pass the converter's pre-spelling gates; "
          f"{len(blocked_ranges)} hold at least one unspellable instruction")
    for k, v in skips.most_common():
        print(f"        {v:5} ranges skipped before spelling: {k}")
    print(f"BYTES   {base_bytes:,} pass the SPELLING stage today · {ceiling:,} if "
          f"every form below were\n        spellable · {ceiling - base_bytes:,} on "
          f"the table for spelling work")

    # ---- the converter's LAST gate, which is not about spelling at all
    gate, gate_bytes, landed_ranges = collections.Counter(), collections.Counter(), 0
    for r in recs:
        g = reassembly_gate(r)
        b = converted_bytes(r, frozenset())
        gate[g] += 1
        gate_bytes[g] += b
        if g in ("pass", "skipped") and b:
            landed_ranges += 1
    landed = gate_bytes["pass"] + gate_bytes["skipped"]
    print(f"\nBLOCK RE-ASSEMBLY GATE (`cc.encode_block`, run only on ranges with no "
          f"intra-range label):")
    for g in ("pass", "skipped", "fixup", "mismatch", "n/a"):
        if gate[g]:
            print(f"        {gate[g]:5} ranges  {gate_bytes[g]:8,} B  {g}")
    print(f"        ⚠ {gate_bytes['fixup']:,} B sit behind `fixup`: the range holds a "
          f"branch to an EXTERNAL\n          symbol, which llvm-mc encodes as a "
          f"placeholder byte (`encoding: [0x6e,A]`),\n          so the byte "
          f"comparison in that gate CANNOT succeed. Not a spelling problem.")
    print(f"        {landed:,} B in {landed_ranges} ranges actually reach the source "
          f"tree today -- this\n        reproduces `convert_reachable_ranges.py`'s "
          f"own headline figure exactly.")

    # ---- per-form measures
    sites = collections.Counter()
    first_blocker = collections.Counter()
    example, framing = {}, collections.Counter()
    site_seqs = collections.defaultdict(collections.Counter)   # form -> seq -> sites
    for r in recs:
        seen_first = False
        for it in r["items"]:
            if it["ok"]:
                continue
            f = it["form"]
            sites[f] += 1
            example.setdefault(f, (it["addr"], it["bytes"], it["text"]))
            site_seqs[f][it["bytes"]] += 1
            framing[(f, r["framing"])] += 1
            if not seen_first:
                first_blocker[f] += 1
                seen_first = True
    marginal = {f: sum(converted_bytes(r, frozenset([f])) for r in recs) - base_bytes
                for f in sites}

    # ---- is it code?
    verdict = {}
    if oracle:
        print("\nasking the byte-exact v9 build whether these bytes are real "
              "instructions ...", file=sys.stderr)
        allseq = {s for f in sites for s in site_seqs[f]}
        try:
            hit, nrows = corroborate(root, allseq)
        except subprocess.CalledProcessError:
            # `make clean-all` deletes v9/maincpu/includes/generated/*.bin, and a
            # snapshot taken while a build is between clean and all carries the
            # hole. Say so instead of dying after minutes of work.
            print("⚠ the v9 -g rebuild FAILED -- most likely v9/maincpu/includes/"
                  "generated/\n  was missing when the snapshot was taken (a "
                  "concurrent `make clean-all`).\n  Re-run after `make all` "
                  "finishes; the ranking below stands, the code column does not.")
            oracle = False
        else:
            print(f"v9 ORACLE  {nrows:,} instruction-start addresses in the "
                  f"byte-exact v9 build (`.byte` emits none)")
            for f in sites:
                got = sorted(s for s in site_seqs[f] if s in hit)
                verdict[f] = {
                    "sites_ok": sum(n for s, n in site_seqs[f].items() if s in hit),
                    "seqs_ok": len(got), "seqs": len(site_seqs[f]),
                    "where": hit[got[0]] if got else None}
    if not oracle:
        print("\n⚠ the code/data column is not filled in (--no-oracle, or the "
              "v9 build failed).")

    # ---- the table
    order = sorted(sites, key=lambda f: (-marginal[f], -sites[f]))
    print(f"\n{'form':30} {'sites':>6} {'1st':>5} {'marginal B':>11} "
          f"{'ret/code':>9}   is it CODE?")
    print("-" * 100)
    for f in order[:top]:
        fr = f"{framing[(f,'ret')]}/{framing[(f,'code')]}"
        if oracle:
            d = verdict[f]
            v = (f"YES {d['sites_ok']}/{sites[f]} sites, "
                 f"{d['seqs_ok']}/{d['seqs']} byte-seqs" if d["sites_ok"] else
                 f"no v9 hit (0 of {d['seqs']} byte-seqs)")
        else:
            v = "-"
        print(f"{f:30} {sites[f]:6} {first_blocker[f]:5} {marginal[f]:11,} "
              f"{fr:>9}   {v}")

    print(f"\nUNITS: sites = unspellable INSTRUCTION occurrences · 1st = RANGES "
          f"where this form is the\nfirst blocker · marginal B = ROM BYTES the "
          f"converter would additionally emit as\ninstructions if this ONE form "
          f"became spellable · ret/code = how the containing\nranges end "
          f"(both are framing evidence; see the module docstring)")

    # ---- greedy: what to actually do next
    print("\ngreedy cumulative -- fix these in this order:")
    fixed, cum = set(), base_bytes
    for step in range(min(8, len(order))):
        best, best_b = None, cum
        for f in sites:
            if f in fixed:
                continue
            b = sum(converted_bytes(r, frozenset(fixed | {f})) for r in recs)
            if b > best_b:
                best, best_b = f, b
        if best is None:
            break
        fixed.add(best)
        print(f"  {step+1}. {best:30} +{best_b-cum:8,} B   "
              f"(running total {best_b:,} of {ceiling:,})")
        cum = best_b

    # ---- --explain FORM: WHY a form is worth what it is worth
    for i, a in enumerate(argv):
        if a == "--explain" and i + 1 < len(argv):
            want_f = argv[i + 1]
            print(f"\nranges where {want_f!r} is the FIRST blocker "
                  f"(this is where its marginal bytes come from):")
            for r in recs:
                k = cut_index(r, frozenset())
                if k >= len(r["items"]) or r["items"][k]["form"] != want_f:
                    continue
                b0 = converted_bytes(r, frozenset())
                b1 = converted_bytes(r, frozenset([want_f]))
                k1 = cut_index(r, frozenset([want_f]))
                nxt = (r["items"][k1]["form"] if k1 < len(r["items"])
                       else "(runs to the end of the range)")
                it = r["items"][k]
                print(f"  0x{r['target']:06X} {addr2name.get(r['target'], ''):30} "
                      f"span={r['span']:5} insns={len(r['items']):4} "
                      f"framing={r['framing']:4}\n"
                      f"      cut {k}->{k1}  bytes {b0}->{b1} (+{b1-b0})  "
                      f"next blocker {nxt!r}\n"
                      f"      blocker at 0x{it['addr']:06X}: {it['bytes']} "
                      f"`{it['text']}`")

    # ---- named RULE SETS: one spelling rule usually covers several forms
    sets = []
    for i, a in enumerate(argv):
        if a == "--set" and i + 1 < len(argv):
            nm, _, body = argv[i + 1].partition("=")
            sets.append((nm, frozenset(x.strip() for x in body.split(";") if x.strip())))
    if sets:
        print("\nnamed rule sets, applied cumulatively in the order given "
              "(one RULE usually covers\nseveral FORMS, and their marginals are "
              "not additive):")
        acc, cum = set(), base_bytes
        for nm, forms in sets:
            unknown = forms - set(sites)
            acc |= forms
            b = sum(converted_bytes(r, frozenset(acc)) for r in recs)
            print(f"  {nm:16} +{b-cum:8,} B   (running total {b:,} of {ceiling:,})"
                  + (f"   ⚠ not a blocking form: {sorted(unknown)}" if unknown else ""))
            cum = b

    print("\nexemplars (address, ROM bytes, unidasm text):")
    for f in order[:top]:
        a, b, x = example[f]
        extra = ""
        if oracle and verdict[f]["where"]:
            extra = f"   same bytes = a v9 instruction at 0x{verdict[f]['where']:06X}"
        print(f"  {f:30} 0x{a:06X}  {b:<14} {x}{extra}")

    if out_json:
        json.dump({"head": head, "taken": time.strftime("%Y-%m-%d %H:%M:%S"),
                   "base_bytes": base_bytes, "ceiling_bytes": ceiling,
                   "ranges": len(recs), "skips": dict(skips),
                   "forms": [{"form": f, "sites": sites[f],
                              "first_blocker_ranges": first_blocker[f],
                              "marginal_bytes": marginal[f],
                              "framing_ret": framing[(f, "ret")],
                              "framing_code": framing[(f, "code")],
                              "byte_seqs": dict(site_seqs[f]),
                              "v9": verdict.get(f) if oracle else None,
                              "example": example[f]} for f in order]},
                  open(out_json, "w"), indent=1)
        print(f"\nwrote {out_json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
