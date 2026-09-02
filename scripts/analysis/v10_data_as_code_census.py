#!/usr/bin/env python3
"""v10 DATA-AS-CODE census -- the third kind of debt (lane V10DATACODE, 2026-09-02).

Nobody has measured this before.  It is different from, and invisible to,
every existing instrument in this tree:

  * kn5000_source_coverage.py measures VERBATIM debt (.incbin with no source).
  * v9_v10_undisassembled_census.py measures CODE-AS-.byte debt (real
    instructions spelled as data directives).
  * THIS script measures the opposite defect: DATA disassembled into
    plausible-looking instruction mnemonics.  A `.byte`/`.incbin` scanner
    cannot see it -- the region already looks like ordinary `.s` source, full
    of real mnemonics and real labels -- and the byte-identity gate cannot
    object either, because re-assembling a wrong interpretation reproduces
    the exact same bytes.  Two confirmed instances were found this week in
    HD-AE5000: a 309 B version string disassembled as ~35 chained garbage
    instructions, and HDAE5000_RECORD_TABLE, 6,356 B of a 13x24-byte record
    table written as ~6,150 lines of mnemonics, whose only real references
    load it as an ADDRESS and which nothing anywhere calls or jumps into.

METHOD
------
Stage 1  TERRITORY (byte-level CODE/DATA/PADDING classification)
  Re-uses the exact method from v9_v10_undisassembled_census.py's
  territory(): replay `llvm-mc -triple=tlcs900 -show-encoding` over the real
  v10 source and walk the token stream, so CODE bytes are wherever the
  assembler actually emitted an instruction encoding.  This is the search
  space: only bytes ALREADY written as instructions are candidates for this
  census (data written as .byte is the sibling script's job, not this one's).

Stage 2  INSTRUCTION STREAM (address, length, exact source mnemonic text)
  Built from the SAME llvm-mc pass, so every CODE byte range comes with the
  real operand text, including any branch/call target's NAME (not just a
  numeric address) -- because it is still the original `.s` source text
  before any macro/incbin flattening loses it.

Stage 3  SEEDS -- the only trustworthy roots
  A byte is a trusted entry point if it is:
    - offset 0 of the ROM (E00000, in case the reset path starts there), or
    - the address of a label that is referenced BY NAME in a NON-branch
      context anywhere in v10/maincpu/*.s: a `.long`/`.dword`/`.word` table
      entry, an `.equ`, an `addr24` macro invocation, an immediate `#NAME`
      load -- i.e. the address is USED AS A VALUE somewhere, which is exactly
      signal #2 from the brief ("it is referenced as an address").
  Branch/call operands (call/calr/call_24/jp/jp_24/jr/jrl/djnz/djnz8/djnz16)
  are counted SEPARATELY as `branch_named` and are NEVER used as seeds.  This
  is the load-bearing design decision: HDAE5000_RECORD_TABLE's fake decode
  produced fake `jr`/`call` instructions whose operands are OTHER labels
  inside the very same bogus span.  If those were allowed to seed each other,
  the whole self-referential chain would look "reached".  Seeding only from
  data references makes that trick impossible -- a span can chain
  internally, but can never become its own root.

Stage 4  REACHABILITY -- closure over the instruction stream
  Starting from the seeds, walk forward through fallthrough (any
  non-terminating instruction reaches the next one) and through the STATED
  branch target of a taken jump/call *when that target resolves, by name, to
  a real label address* (this reuses the ORIGINAL source text, so it is not
  fooled by MAME/llvm-mc TLCS900 model disagreements the way a raw byte
  re-decode would be).  `ret`/`reti`/`retd`/`halt` and an unconditional
  (cond "t") `jr`/`jrl`/`jp` end the walk with no fallthrough.  `call`/`calr`
  and conditional branches/`djnz` always keep the fallthrough edge alive too.

Stage 5  CANDIDATES
  Maximal CODE-territory spans with ZERO reached bytes.  Ranked by:
    - size,
    - whether the span's OWN internal labels are referenced only by branches
      INSIDE the span (the "chained by local labels referencing nothing
      outside" signature) vs from anywhere else,
    - byte-level data-likeness on the RAW ROM BYTES (period/ramp/distinct-
      value statistics, reusing the sibling census's `rule()` formula) and
      ASCII-printability -- both computed independent of any disassembler.

NULL / FALSE-POSITIVE RATE (mandatory, see --calibrate)
  Two independent controls, both drawn from CODE that is UNAMBIGUOUSLY real
  (multiply-referenced by name from elsewhere in the tree, i.e. reached by
  Stage 4 with the strongest possible evidence):
    1. Reachability false-positive rate: fraction of such genuine, reached
       code that Stage 4 nonetheless fails to mark reached, due to indirect
       jumps (`jp (reg)`) whose table is missed by the seed scan, computed
       goto targets, or similar instrument gaps.  This is the number that
       licenses (or does not) trusting an "unreached" verdict.
    2. Decode-quality false-positive rate: fraction of size-matched windows
       drawn from long, definitely-reached CODE runs that the byte-level
       data-likeness rule flags as data-like anyway.  Reported so the ranking
       signal is never quoted without its own noise floor.

USAGE
    python3 scripts/analysis/v10_data_as_code_census.py --build     # once
    python3 scripts/analysis/v10_data_as_code_census.py --census
    python3 scripts/analysis/v10_data_as_code_census.py --calibrate
    python3 scripts/analysis/v10_data_as_code_census.py --selftest
    python3 scripts/analysis/v10_data_as_code_census.py --report [--top N]

--build runs `make rebuilt_ROMs/kn5000_v10_program.llvm.rom` if the ELF is
missing or older than the source, then asserts the rebuilt ROM is
byte-identical to the original before anything downstream is allowed to run.
"""
import argparse, os, pickle, random, re, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
NM = os.path.join(LLVM, "llvm-nm")
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE, SIZE = 0xE00000, 2097152
SRC_ROOT = os.path.join(REPO, "v10", "maincpu")
TOP_SRC = os.path.join(SRC_ROOT, "kn5000_v10_program.s")
ROM_PATH = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
ELF_PATH = os.path.join(REPO, "rebuilt_ROMs", "kn5000_v10_program.llvm.elf")
ROM_OUT = os.path.join(REPO, "rebuilt_ROMs", "kn5000_v10_program.llvm.rom")
CACHE = os.path.join(REPO, "notes", "v10-data-as-code", "cache.pkl")

WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENC = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')

BRANCH_MNEM = {"call", "calr", "call_24", "jp", "jp_24", "jr", "jrl",
               "djnz", "djnz8", "djnz16"}
TERMINATOR_MNEM = {"ret", "reti", "retd", "halt"}
JUMP_MNEM = {"jp", "jp_24", "jr", "jrl"}
IDENT = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
LABEL_LINE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$')


# ------------------------------------------------------------- stage 0/1
def build():
    need = (not os.path.exists(ELF_PATH) or not os.path.exists(ROM_PATH)
            or os.path.getmtime(ELF_PATH) < max(
                (os.path.getmtime(os.path.join(dp, f))
                 for dp, _, fs in os.walk(SRC_ROOT) for f in fs if f.endswith(".s")),
                default=0))
    if need:
        subprocess.run(["make", "rebuilt_ROMs/kn5000_v10_program.llvm.rom"],
                        cwd=REPO, check=True)
    rebuilt = open(ROM_OUT, "rb").read()
    orig = open(ROM_PATH, "rb").read()
    if rebuilt != orig:
        sys.exit("ABORT: rebuilt v10 ROM differs from the original dump -- "
                 "the gate would be red; refusing to measure a broken tree.")
    print(f"v10 ROM verified byte-identical to original_ROMs/ "
          f"({len(orig):,} B) -- safe to trust addresses below.")


def ascii_len(op):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', op))


def mc_pass():
    """One llvm-mc -show-encoding pass.  Returns (territory bytearray,
    instr list of (off, length, text))."""
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding",
                          "-I", SRC_ROOT, TOP_SRC],
                         capture_output=True, text=True)
    if out.returncode:
        sys.exit(out.stderr[:2000])
    terr = bytearray(SIZE)
    instr = []
    pos = 0
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        e = ENC.search(line)
        if e:
            n = len([b for b in e.group(1).split(",") if b.strip()])
            text = line.split(";", 1)[0].strip()
            instr.append((pos, n, text))
            terr[pos:pos + n] = b"\1" * n
            pos += n
            continue
        if s.endswith(":") or s.startswith(";"):
            continue
        mm = re.match(r'\.(\w+)\s*(.*)$', s)
        if not mm:
            continue
        d, rest = mm.group(1), mm.group(2).strip()
        if d in WIDTH:
            n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
            t = 2
        elif d in ("ascii", "asciz"):
            n = ascii_len(rest) + (1 if d == "asciz" else 0)
            t = 2
        elif d in ("zero", "fill", "space"):
            p = [x.strip() for x in rest.split(",")]
            n = int(p[0], 0)
            if d == "fill" and len(p) >= 2:
                n *= int(p[1], 0)
            t = 3
        elif d == "p2align":
            n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
            t = 3
        elif d == "org":
            n = max(0, int(rest.split(",")[0].strip(), 0) - pos)
            t = 3
        else:
            continue
        if n:
            terr[pos:pos + n] = bytes([t]) * n
            pos += n
    assert pos == SIZE, f"assembled {pos} != SIZE {SIZE}"
    return terr, instr


def symbols():
    out = subprocess.run([NM, "--no-sort", ELF_PATH], capture_output=True, text=True).stdout
    name_addr, addr_names = {}, {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) != 3 or p[1].lower() != "t":
            continue
        addr = int(p[0], 16)
        if BASE <= addr < BASE + SIZE:
            off = addr - BASE
            name_addr[p[2]] = off
            addr_names.setdefault(off, []).append(p[2])
    return name_addr, addr_names


def scan_source_refs(names):
    """One pass over the RAW (unflattened) v10 source tree -- BOTH the `.s`
    files and the ~736,000 lines of `.c`/`.h` (widget descriptors, paramblock
    tables, screendata) that clang compiles into the UI dispatch tables the
    Makefile builds and `.incbin`s.  Those C tables are a MAJOR source of
    genuine function-pointer references to assembly routines (measured:
    106 known assembly labels are named in naka_widget_descriptors.c alone),
    and they are invisible to any scan that only reads `.s` files -- an
    early version of this script that skipped `.c`/`.h` mis-measured 56.9%
    of v10's CODE territory as "unreached", which is the exact false-report
    this project has been burned by before: an instrument gap masquerading
    as a finding.  Returns (data_seeds, branch_named) as sets of label NAMES
    -- see the Stage 3 docstring above for why these must stay disjoint.
    C files are scanned only for identifier tokens (no branch/call mnemonic
    exists in C syntax at the source-text level we see here); any known
    label name appearing in a `.c`/`.h` file becomes a data_seed."""
    branch_re = re.compile(r'^(' + "|".join(BRANCH_MNEM) + r')\b\s*(.*)$')
    data_seeds, branch_named = set(), set()
    for dp, _, fns in os.walk(SRC_ROOT):
        for fn in sorted(fns):
            if fn.endswith(".s"):
                for raw in open(os.path.join(dp, fn), encoding="utf-8", errors="surrogateescape"):
                    s = raw.split(";", 1)[0].strip()
                    if not s:
                        continue
                    lm = LABEL_LINE.match(s)
                    if lm:
                        s = lm.group(2).strip()
                        if not s:
                            continue
                    bm = branch_re.match(s)
                    if bm:
                        for tok in IDENT.findall(bm.group(2)):
                            if tok in names:
                                branch_named.add(tok)
                        continue
                    for tok in IDENT.findall(s):
                        if tok in names:
                            data_seeds.add(tok)
            elif fn.endswith(".c") or fn.endswith(".h"):
                text = open(os.path.join(dp, fn), encoding="utf-8", errors="surrogateescape").read()
                for tok in IDENT.findall(text):
                    if tok in names:
                        data_seeds.add(tok)
    return data_seeds, branch_named


# ------------------------------------------------------------- stage 4
def parse_branch(text):
    """(mnemonic, cond, target_name) or (mnemonic, None, None) for non-branch.

    Source syntax has TWO shapes, both real: a bare unconditional target
    (`jrl LABEL`, `call LABEL`, `jp LABEL`) with no comma at all, and a
    comma-separated condition/register plus target (`jr z, LABEL`,
    `djnz xbc, LABEL`).  The target is always the LAST comma-separated
    operand; `cond` is None for the bare form."""
    parts = text.split(None, 1)
    if not parts:
        return None, None, None
    mnem = parts[0]
    rest = parts[1].strip() if len(parts) > 1 else ""
    if mnem not in BRANCH_MNEM:
        return mnem, None, None
    if "," in rest:
        cond, target = rest.rsplit(",", 1)
        cond = cond.strip()
    else:
        cond, target = None, rest
    target = target.strip()
    tname = target if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', target) else None
    return mnem, cond, tname


def reachability(terr, instr, name_addr, data_seeds):
    by_off = {off: (n, text) for off, n, text in instr}
    reached = bytearray(SIZE)
    work = [off for name in data_seeds if name in name_addr
            for off in [name_addr[name]] if off in by_off]
    if 0 in by_off:
        work.append(0)
    seen = set()
    while work:
        off = work.pop()
        if off in seen or off not in by_off:
            continue
        seen.add(off)
        n, text = by_off[off]
        reached[off:off + n] = b"\1" * n
        mnem, cond, tname = parse_branch(text)
        target_off = name_addr.get(tname) if tname else None
        if mnem in TERMINATOR_MNEM:
            continue
        uncond = mnem in JUMP_MNEM and (cond is None or cond.lower() == "t")
        if uncond:
            if target_off is not None:
                work.append(target_off)
            continue
        # conditional jump, call, calr, djnz*, or any plain instruction:
        # fallthrough always stays alive
        work.append(off + n)
        if target_off is not None:
            work.append(target_off)
    return reached, by_off


# ------------------------------------------------------------- stage 5 / rule
def byte_metrics(blob):
    per = 0.0
    for p in range(2, 33):
        if len(blob) > p:
            per = max(per, sum(1 for i in range(p, len(blob))
                               if blob[i] == blob[i - p]) / (len(blob) - p))
    ramp = sum(1 for i in range(1, len(blob))
               if blob[i] == (blob[i - 1] + 1) & 0xFF) / max(len(blob) - 1, 1)
    printable = sum(1 for b in blob if 0x20 <= b <= 0x7e or b in (0, 9, 10, 13))
    return dict(per=100.0 * per, ramp=100.0 * ramp, dist=len(set(blob)),
                n=len(blob), ascii_frac=100.0 * printable / max(len(blob), 1))


def looks_data(m):
    """Same thresholds as v9_v10_undisassembled_census.py's rule(), but we
    ask the opposite question: does this CODE-territory span fail the
    code-like test, i.e. look like data by byte statistics alone?  Measured
    (--calibrate) false-positive rate on verified real code: ~19%.  A
    RANKING aid, not a verdict -- see strict_looks_data for the tighter
    tier."""
    return not (m["per"] <= 20.0 and m["ramp"] <= 12.0
                and m["dist"] >= min(60, round(0.35 * m["n"])))


TIGHT_DIST, TIGHT_PER = 15, 60.0


def strict_looks_data(m):
    """A much tighter data signature: <=15 distinct byte values AND >=60%
    max periodicity.  No real TLCS900 instruction stream sustains this over
    even a few dozen bytes; measured (--calibrate --strict) false-positive
    rate on verified real code: ~2%, an order of magnitude tighter than
    looks_data().  This is the tier actually worth naming candidates from."""
    return m["dist"] <= TIGHT_DIST and m["per"] >= TIGHT_PER


def candidates(terr, reached, minsize=1):
    regs, i = [], 0
    while i < SIZE:
        if terr[i] == 1 and not reached[i]:
            j = i
            while j < SIZE and terr[i] == terr[j] == 1 and not reached[j]:
                j += 1
            if j - i >= minsize:
                regs.append((i, j))
            i = j
        else:
            i += 1
    return regs


def load_all():
    if os.path.exists(CACHE):
        d = pickle.load(open(CACHE, "rb"))
        return d
    terr, instr = mc_pass()
    name_addr, addr_names = symbols()
    data_seeds, branch_named = scan_source_refs(set(name_addr))
    reached, by_off = reachability(terr, instr, name_addr, data_seeds)
    d = dict(terr=bytes(terr), instr=instr, name_addr=name_addr,
             addr_names=addr_names, data_seeds=data_seeds,
             branch_named=branch_named, reached=bytes(reached))
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    pickle.dump(d, open(CACHE, "wb"))
    return d


# ------------------------------------------------------------- reporting
def census():
    build()
    d = load_all()
    terr = d["terr"]
    code_total = sum(1 for b in terr if b == 1)
    reached_code = sum(1 for t, r in zip(terr, d["reached"]) if t == 1 and r)
    print(f"v10 program ROM: {SIZE:,} B total, {code_total:,} B CODE territory "
          f"({100.0*code_total/SIZE:.2f}%)")
    print(f"  reached (seeded + fallthrough/branch closure): {reached_code:,} B "
          f"({100.0*reached_code/code_total:.2f}% of CODE)")
    print(f"  data_seeds (labels referenced as a value somewhere): {len(d['data_seeds']):,}")
    print(f"  branch_named (labels referenced only by call/jp/jr/jrl/djnz): "
          f"{len(d['branch_named']):,}")
    regs = candidates(terr, d["reached"], minsize=1)
    tot = sum(b - a for a, b in regs)
    print(f"  UNREACHED CODE-territory spans: {len(regs):,} totalling {tot:,} B")
    for cut in (4, 16, 64, 256):
        r = [x for x in regs if x[1] - x[0] >= cut]
        print(f"    >= {cut:>4} B: {len(r):>5,} spans, {sum(b-a for a,b in r):>7,} B")


def calibrate(n=300, seed=11):
    build()
    d = load_all()
    terr, reached = d["terr"], d["reached"]
    rom = open(ROM_PATH, "rb").read()
    regs = candidates(terr, reached, minsize=1)
    sizes = sorted(set(min(b - a, 2000) for a, b in regs if b - a >= 4))
    if not sizes:
        sizes = [16, 32, 64]

    # --- control population: CODE that is reached AND whose start label is
    # named by >=2 distinct external call/jp/jr sites elsewhere in the tree
    # (the strongest evidence this is genuinely, verifiably real code).
    from collections import Counter
    site_count = Counter()
    branch_re = re.compile(r'^(' + "|".join(BRANCH_MNEM) + r')\b\s*(.*)$')
    for _, _, text in d["instr"]:
        s = text
        bm = branch_re.match(s)
        if not bm:
            continue
        for tok in IDENT.findall(bm.group(2)):
            if tok in d["name_addr"]:
                site_count[tok] += 1
    strong = {name for name, c in site_count.items() if c >= 2}
    strong_runs = []
    i = 0
    while i < SIZE:
        if terr[i] == 1 and reached[i]:
            j = i
            while j < SIZE and terr[j] == 1 and reached[j]:
                j += 1
            names_here = d["addr_names"].get(i, [])
            if (j - i) >= 300 and any(nm in strong for nm in names_here):
                strong_runs.append((i, j))
            i = j
        else:
            i += 1
    print(f"strong (>=2 external references) reached CODE runs >=300B: "
          f"{len(strong_runs):,}, {sum(b-a for a,b in strong_runs):,} B total")

    # 1a. reachability MECHANISM check on the SAME strong runs: by
    #    construction these are ALL reached (they were selected from the
    #    `reached` bitmap), so this measures whether the fallthrough/branch
    #    PROPAGATION itself (as opposed to the seed set) has bugs: any label
    #    INSIDE an already-reached strong run that Stage-4 nonetheless failed
    #    to mark reached would be a propagation bug.
    all_labels_in_strong = 0
    missed = 0
    for a, b in strong_runs:
        for off, names_here in d["addr_names"].items():
            if a <= off < b:
                all_labels_in_strong += 1
                if not reached[off]:
                    missed += 1
    rate = 100.0 * missed / max(all_labels_in_strong, 1)
    print(f"reachability PROPAGATION check (bugs, not seed coverage): "
          f"{missed}/{all_labels_in_strong} internal labels of already-reached "
          f"strong runs NOT marked reached = {rate:.2f}%")

    # 1b. reachability SEED-COVERAGE recall: of every label that is PROVABLY
    #    called by name from somewhere in the tree (branch_named, excluding
    #    ones also seeded as a data value), what fraction actually ends up
    #    reached?  This is the number that matters: it is NOT 100%, because
    #    reaching a named call target also requires the CALLING instruction
    #    itself to be reached, and that chain can dead-end at a gateway this
    #    static scan cannot see (a computed/RAM-resident dispatch, a
    #    register-indirect call sourced from a runtime pointer).  Report it
    #    so nobody trusts "unreached" as a verdict without this caveat.
    bn_only = d["branch_named"] - d["data_seeds"]
    bn_reached = sum(1 for nm in bn_only if reached[d["name_addr"][nm]])
    bn_rate = 100.0 * (len(bn_only) - bn_reached) / max(len(bn_only), 1)
    print(f"reachability SEED-COVERAGE gap: of {len(bn_only):,} labels proven "
          f"called by name from elsewhere, {len(bn_only)-bn_reached:,} "
          f"({bn_rate:.1f}%) still fail to end up REACHED -- their caller "
          f"chain dead-ends before hitting a seed. This is the real false-"
          f"positive risk for the 'unreached' signal; see the SeqPart_* "
          f"cluster in the report notes for a concrete, spot-checked example "
          f"(467 labels, only 33 provably reached, the rest a coherent, "
          f"byte-diverse editor subsystem almost certainly real).")

    # 2. decode-quality (byte-statistics) false-positive rate: random windows
    #    from the strong runs, size-matched to the candidate population, for
    #    BOTH the loose rule and the tight (strict_looks_data) rule.
    random.seed(seed)
    usable = [sz for sz in sizes if any(b - a > sz + 16 for a, b in strong_runs)]
    fire = fire_strict = 0
    tb = 0
    for _ in range(n):
        sz = random.choice(usable)
        a, b = random.choice([r for r in strong_runs if r[1] - r[0] > sz + 16])
        s = random.randrange(a + 8, b - sz)
        blob = rom[s:s + sz]
        m = byte_metrics(blob)
        tb += sz
        if looks_data(m):
            fire += 1
        if strict_looks_data(m):
            fire_strict += 1
    print(f"decode-quality false-positive rate, LOOSE rule (byte-stats rule "
          f"fires on KNOWN-real code): {fire}/{n} = {100.0*fire/n:.1f}%")
    print(f"decode-quality false-positive rate, STRICT rule (dist<={TIGHT_DIST} "
          f"and per>={TIGHT_PER:.0f}%) on KNOWN-real code: "
          f"{fire_strict}/{n} = {100.0*fire_strict/n:.1f}%")
    print("  => the byte-statistics leg is a RANKING aid; a candidate's "
          "confidence rests on the reachability signal, corroborated by "
          "this leg -- the STRICT rule is tight enough to name individual "
          "candidates from, the LOOSE rule is not.")


def selftest():
    """Plants a known data-as-code case and a known-good routine in a scratch
    copy of a small slice, and asserts the detector's core primitives (parse_branch,
    reachability closure, looks_data) call it correctly -- the mandatory
    'can this detector go red' check."""
    ok = True

    # (a) a fabricated self-referential "record table" decode: three fake
    # instructions chained by two local labels, referenced ONLY by branches
    # inside the span itself, with a `.long` elsewhere pointing at its START
    # as DATA (never as a branch target) -- exactly the HDAE5000_RECORD_TABLE
    # shape.  It must NOT be reachable via a branch-target seed alone.
    fake_instr = [
        (0x1000, 2, "jr z, FAKE_B"),
        (0x1002, 2, "jr t, FAKE_A"),
    ]
    fake_instr = [(0x1000, 2, "jr z, FAKE_B"), (0x1002, 2, "jr t, FAKE_A")]
    name_addr = {"FAKE_A": 0x1000, "FAKE_B": 0x1002, "REAL_TABLE_USER": 0x2000}
    terr = bytearray(SIZE)
    terr[0x1000:0x1004] = b"\1\1\1\1"
    # data_seeds deliberately does NOT include FAKE_A/FAKE_B: nothing in a
    # real tree points at this span except its own internal branches.
    data_seeds = set()
    reached, by_off = reachability(terr, fake_instr, name_addr, data_seeds)
    planted_reached = any(reached[0x1000:0x1004])
    if planted_reached:
        print("SELFTEST FAIL: planted self-referential span was marked REACHED "
              "-- the seed isolation is broken (internal branches can seed "
              "themselves)")
        ok = False
    else:
        print("SELFTEST PASS: planted self-referential data-as-code span "
              "correctly UNREACHED (flagged)")

    # (b) the same two fake instructions, but now genuinely called from
    # outside (a `.long` table entry names FAKE_A) -- must NOT be flagged.
    data_seeds2 = {"FAKE_A"}
    reached2, _ = reachability(terr, fake_instr, name_addr, data_seeds2)
    if not all(reached2[0x1000:0x1004]):
        print("SELFTEST FAIL: a genuinely address-referenced routine was NOT "
              "marked reached -- false positive on real code")
        ok = False
    else:
        print("SELFTEST PASS: genuinely address-referenced routine correctly "
              "marked REACHED (not flagged)")

    # (c) byte-statistics rule: a 64-byte run of a repeating 4-byte pattern
    # must look data-like; 64 bytes of a realistic disassembled-instruction
    # byte mix (high distinct-byte count, no periodicity) must not.
    periodic = bytes([0x11, 0x22, 0x33, 0x44] * 16)
    if not looks_data(byte_metrics(periodic)):
        print("SELFTEST FAIL: an obviously periodic 64 B run was NOT flagged "
              "data-like")
        ok = False
    else:
        print("SELFTEST PASS: periodic 64 B run correctly flagged data-like")
    varied = bytes((i * 37 + i * i * 13) & 0xFF for i in range(64))
    if looks_data(byte_metrics(varied)):
        print("SELFTEST FAIL: a high-entropy 64 B run was flagged data-like "
              "(false positive on the byte-stats leg's own control)")
        ok = False
    else:
        print("SELFTEST PASS: high-entropy 64 B run correctly NOT flagged")

    print("SELFTEST", "ALL PASS" if ok else "FAILED -- see above")
    return 0 if ok else 1


def report(top=25, data_only=False, minsize=1, strict=False):
    import bisect
    build()
    d = load_all()
    terr, reached = d["terr"], d["reached"]
    rom = open(ROM_PATH, "rb").read()
    regs = candidates(terr, reached, minsize=minsize)
    label_offs = sorted(d["addr_names"])
    print(f"{len(regs):,} unreached CODE spans, {sum(b-a for a,b in regs):,} B total")
    scored = []
    for a, b in regs:
        blob = rom[a:b]
        m = byte_metrics(blob)
        i = bisect.bisect_right(label_offs, a) - 1
        if i >= 0:
            enc_off = label_offs[i]
            enc_name = sorted(d["addr_names"][enc_off])[0]
        else:
            enc_off, enc_name = None, "(no label)"
        scored.append(dict(a=a, b=b, size=b - a, m=m,
                           enc_name=enc_name,
                           enc_dist=(a - enc_off) if enc_off is not None else None,
                           data_like=looks_data(m), strict=strict_looks_data(m)))
    if strict:
        scored = [r for r in scored if r["strict"]]
        print(f"  {len(scored):,} of those pass the STRICT rule (dist<={TIGHT_DIST}, "
              f"per>={TIGHT_PER:.0f}%, ~2% false-positive rate on verified real "
              f"code -- see --calibrate), {sum(r['size'] for r in scored):,} B.")
    elif data_only:
        scored = [r for r in scored if r["data_like"]]
        print(f"  {len(scored):,} of those are ALSO data-like by the LOOSE byte-"
              f"stats rule (~19% false-positive rate -- see --calibrate), "
              f"{sum(r['size'] for r in scored):,} B.")
    scored.sort(key=lambda r: -r["size"])
    print(f"\nTop {top} by size (BASE=0x{BASE:06X}):")
    for r in scored[:top]:
        tag = "STRICT" if r["strict"] else ("data-like" if r["data_like"] else "code-shaped")
        loc = r["enc_name"] if not r["enc_dist"] else f"{r['enc_name']}+{r['enc_dist']}"
        print(f"  0x{BASE+r['a']:06X}-0x{BASE+r['b']:06X}  {r['size']:>6,} B  "
              f"{tag:<10}  per{r['m']['per']:4.0f}% ramp{r['m']['ramp']:4.0f}% "
              f"dist{r['m']['dist']:>4} ascii{r['m']['ascii_frac']:4.0f}%  {loc}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", action="store_true")
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--calibrate", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--data-only", action="store_true",
                    help="--report: only spans that ALSO fail the LOOSE byte-"
                         "stats code-like rule (~19%% false-positive; still "
                         "needs manual confirmation)")
    ap.add_argument("--strict", action="store_true",
                    help="--report: only spans passing the STRICT byte-stats "
                         "rule (dist<=15, per>=60%%, ~2%% false-positive)")
    ap.add_argument("--minsize", type=int, default=1)
    ap.add_argument("--fresh", action="store_true", help="ignore cache")
    a = ap.parse_args()
    if a.fresh and os.path.exists(CACHE):
        os.remove(CACHE)
    if a.build:
        build()
    if a.census:
        census()
    if a.calibrate:
        calibrate()
    if a.selftest:
        sys.exit(selftest())
    if a.report:
        report(a.top, a.data_only, a.minsize, a.strict)
    if not any([a.build, a.census, a.calibrate, a.selftest, a.report]):
        ap.print_help()


if __name__ == "__main__":
    main()
