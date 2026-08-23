#!/usr/bin/env python3
"""What is actually INSIDE the converter's two biggest refusal buckets?

QUESTION ANSWERED
-----------------
`convert_reachable_ranges.py` refuses ranges with

    "decoded fewer than 3 instructions"          (200 on the seed target list)
    "no `ret`, and does not end at a code boundary"  (160 on the seed list)

and nothing said what those ranges ARE. This classifies every member of both
buckets by the MECHANICAL REASON the decode stopped where it did, and attaches
the data-shape evidence separately, so a human can check each verdict.

Run:
    python3 tools/spelling-probes/refusal-buckets/classify.py            # seed list, 687 targets
    python3 tools/spelling-probes/refusal-buckets/classify.py --closure  # branch-closure list
    python3 tools/spelling-probes/refusal-buckets/classify.py --spelling # + can llvm-mc spell the decoded prefix?
    python3 tools/spelling-probes/refusal-buckets/classify.py --dump out.tsv

READ-ONLY. It never invokes the converter's `--apply` path; `main()` is called
once, with `decode_range` replaced by the cache, only to re-derive the official
bucket counts and ASSERT they equal this script's membership. That assertion is
the thing that can fail: if the converter's rules move, this probe stops
agreeing and says so instead of quietly describing a different question.

THE TAXONOMY, and why it is mechanical
--------------------------------------
Both buckets are decided BEFORE the converter tries to spell anything, so the
posed hypothesis "the LLVM backend cannot spell an instruction" cannot be the
cause of a refusal here -- the spelling loop has not run yet. The analogous
blocker is the DISASSEMBLER: `decode_range()` stops at the first line unidasm
prints as `db`. So the taxonomy is built on the stop:

  C-SHORT-STUB          the decode ENDED IN A TERMINATOR (`ret`/`reti`/`retd`)
                        after one or two instructions. Nothing is wrong with
                        these; the `< 3` threshold is the whole objection.
  D-TILES-INTO-CODE     the decode consumed the entire undisassembled run and
                        ends exactly where already-disassembled code begins --
                        the converter's own `ends_at_code` rule, which `< 3`
                        pre-empts.
  D-OVERRUN             the last instruction STRADDLES that boundary: unidasm
                        over-reads its input file, so a run of N bytes can come
                        back holding N+1 or N+2 bytes of "instructions", built
                        partly from bytes that were never in the buffer.
  D-TRUNCATED-BUFFER    unidasm printed `db` for the last bytes of the buffer,
                        and the SAME BYTES decode cleanly when it is given the
                        following ROM bytes as well. The `db` is an artefact of
                        the buffer ending, not a property of the bytes.
  A-DECODER-GAP         unidasm printed `db` mid-run, but llvm-mc's independent
                        TLCS-900 disassembler decodes those bytes. A hole in
                        MAME's table -- actionable, and the only genuinely
                        "the tool cannot express this" cause in these buckets.
  B-UNDECODABLE         unidasm printed `db` mid-run and llvm-mc refuses the
                        same bytes too. TWO INDEPENDENT DECODERS agree there is
                        no instruction there.
  B-RUNAWAY             the decode ran to the converter's 16,384-byte cap with
                        no terminator and no `db` -- the shape its own docstring
                        names as "a runaway decode through data".

DATA-SHAPE EVIDENCE is reported as separate COLUMNS, never folded into the
cause, because the cause is a fact about the decode and the shape is an
inference about the bytes:

  ascii       >= 8 consecutive printable bytes starting within the first 4
  ptrtable    >= 3 of the first 4 little-endian u32 words land in 0xE00000..0xFFFFFF
  implausible the converter's OWN plausibility screen (`swi`/`normal`/`max`/
              `halt`/`ldio`/`ldwio`/`retd` > 0xff) fires on the decoded text

⚠ Both shape rules are calibrated against a control that CAN fail -- see
`--controls` output. The ptrtable rule was written knowing anti-pattern 10:
a uniform u32 lands in that 2 MB window with probability 1/2048, so a control
drawn from uniform noise would be incapable of exposing a loose rule. The
controls used are (i) CODE-territory addresses, which are real instructions and
must not be called pointer tables, and (ii) a byte-shuffle of the refused
ranges themselves -- same byte distribution, no arrangement.

WHAT THIS CANNOT DISTINGUISH -- stated up front:
  * B-UNDECODABLE means "no instruction under either decoder AT THAT OFFSET".
    It does not prove the range is data: a MIS-FRAMED entry into real code
    produces exactly the same signature. The classifier cannot separate "data"
    from "code decoded from the wrong offset", and never claims to.
  * C-SHORT-STUB says the decode ends in `ret`. Whether those one or two
    instructions are a stub the firmware really calls, or two table bytes that
    happen to decode with a 0x0E in them, is not decidable from the decode --
    which is anti-pattern 13 restated. The `implausible` and `ascii` columns are
    the only counter-evidence offered.
  * A-DECODER-GAP proves the two decoders DISAGREE. Which one is right is a
    question for the Toshiba manual, not for this script.
"""
import collections, hashlib, importlib.util, json, os, random, re, subprocess, sys, tempfile

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
HERE = os.path.dirname(os.path.abspath(__file__))
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
os.chdir(REPO)

_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
cc = crr.cc
_c = importlib.util.spec_from_file_location("_cache", os.path.join(HERE, "_cache.py"))
cm = importlib.util.module_from_spec(_c); _c.loader.exec_module(cm)

WHICH = "closure" if "--closure" in sys.argv else "seed"
DO_SPELLING = "--spelling" in sys.argv
DUMP = sys.argv[sys.argv.index("--dump") + 1] if "--dump" in sys.argv else None

targets, prov = cm.targets(WHICH)
rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
_spec = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

print("=" * 78)
print("REFUSAL-BUCKET CLASSIFIER")
print(f"  target list      {prov['file']}")
print(f"                   {prov['count']} entries, sha256 {prov['sha256']}...")
print(f"  ROM              original_ROMs/kn5000_v7_program.rom "
      f"sha256 {hashlib.sha256(rom).hexdigest()[:16]}...")
print(f"  decoder A        {crr.UNIDASM} -arch tlcs900   (MAME)")
print(f"  decoder B        {LLVM_MC} -disassemble -triple=tlcs900")
print("=" * 78)

decodes = cm.load(crr, targets)
raws = cm.load_raw(crr, targets)


def run_full(t):
    """Length of the undisassembled run at `t`, UNCAPPED -- as main() computes it."""
    off, r = t - crr.BASE, 0
    while off + r < len(terr) and terr[off + r] == 2:
        r += 1
    return r


def stop_of(t):
    """(reason, index of the stopping line) over the FULL unidasm listing."""
    for i, (_a, _n, x) in enumerate(raws[t]["lines"]):
        mn = x.split()[0].lower() if x.split() else ""
        if mn == "db":
            return "db", i
        if mn in crr.TERMINATORS:
            return "terminator", i
    return "exhausted", len(raws[t]["lines"])


# --------------------------------------------------- bucket membership
b1, b2 = [], []
for t in targets:
    ins = decodes[t]
    if len(ins) < 3:
        b1.append(t); continue
    span = sum(n for _, n, _ in ins)
    last = ins[-1][2].strip()
    if (last.split()[0].lower() not in crr.TERMINATORS
            and not crr.UNCOND_JUMP.match(last) and span != run_full(t)):
        b2.append(t)

# SELF-CHECK: the converter's own tally must agree, or this probe is describing
# a rule that no longer exists.
import io, contextlib
_orig_dr = crr.decode_range
crr.decode_range = lambda _rom, _terr, start, limit=16384: decodes.get(start, [])
_argv = sys.argv[:]
sys.argv = [_argv[0]]
if WHICH == "seed":
    _ex = os.path.exists
    crr.os.path.exists = lambda p: False if p.endswith("v7_branch_closure_targets.json") else _ex(p)
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    crr.main()
if WHICH == "seed":
    crr.os.path.exists = _ex
sys.argv = _argv
crr.decode_range = _orig_dr
official = {}
for ln in buf.getvalue().split("\n"):
    m = re.match(r'^\s+(\d+)\s+(decoded fewer than 3 instructions|'
                 r'no `ret`, and does not end at a code boundary)$', ln)
    if m:
        official[m.group(2)] = int(m.group(1))
mine = {"decoded fewer than 3 instructions": len(b1),
        "no `ret`, and does not end at a code boundary": len(b2)}
print("\nSELF-CHECK against the converter's own tally (this is what can fail):")
for k in mine:
    got = official.get(k)
    flag = "OK " if got == mine[k] else "MISMATCH"
    print(f"  {flag}  {mine[k]:4} classified   {got if got is not None else '??':>4} reported"
          f"   {k}")
assert official == mine, ("bucket membership disagrees with the converter -- "
                          "its rules moved; fix this probe before quoting it")

# --------------------------------------------------- decoder B: llvm-mc
_LLVM_MEMO = {}


def llvm_refuses(addr, nbytes=16):
    """Does llvm-mc's TLCS-900 disassembler also refuse the byte AT `addr`?

    llvm-mc -disassemble reports `<stdin>:1:C:` where C = 1 + 5*byte_index for
    the token it could not decode, because every byte is written as `0xNN `.
    Column 1 therefore means "the FIRST byte is not the start of any instruction
    llvm knows".  Returns (refuses, first_decoded_text).
    """
    if addr in _LLVM_MEMO:
        return _LLVM_MEMO[addr]
    off = addr - crr.BASE
    src = " ".join(f"0x{b:02x}" for b in rom[off:off + nbytes])
    r = subprocess.run([LLVM_MC, "-disassemble", "-triple=tlcs900"],
                       input=src, capture_output=True, text=True, timeout=60)
    refuses = bool(re.search(r'^<stdin>:1:1:', r.stderr, re.M))
    first = ""
    for ln in r.stdout.split("\n"):
        if ln.strip():
            first = " ".join(ln.split()); break
    _LLVM_MEMO[addr] = (refuses, first)
    return _LLVM_MEMO[addr]


# --------------------------------------------------- data-shape evidence
def ascii_run(buf, off, window=4):
    """Longest printable-ASCII run beginning within `window` bytes of `off`."""
    best = 0
    for s in range(window):
        n = 0
        while off + s + n < len(buf) and 0x20 <= buf[off + s + n] <= 0x7E:
            n += 1
        best = max(best, n)
    return best


def ptr_words(buf, off, n=4):
    """How many of the first `n` little-endian u32 words land in the ROM window."""
    hits = 0
    for i in range(n):
        w = int.from_bytes(buf[off + 4 * i: off + 4 * i + 4], "little")
        if 0xE00000 <= w <= 0xFFFFFF:
            hits += 1
    return hits


def shape(t):
    off = t - crr.BASE
    return {"ascii": ascii_run(rom, off) >= 8,
            "ptrtable": ptr_words(rom, off) >= 3,
            "implausible": crr.implausible([x for _a, _n, x in decodes[t]])}


# --------------------------------------------------- classify
rows = []
for bucket, members in (("B1", b1), ("B2", b2)):
    for t in members:
        rf = run_full(t)
        bufl = min(rf, 16384)
        ins = decodes[t]
        span = sum(n for _, n, _ in ins)
        reason, i = stop_of(t)
        stop_off = span                      # bytes consumed before the stop
        blocked_byte, gap_text = "", ""
        if reason == "db":
            a, n, _x = raws[t]["lines"][i]
            stop_off = a - t
            blocked_byte = rom[a - crr.BASE: a - crr.BASE + n].hex()
            if stop_off + n >= bufl:
                cause = "D-TRUNCATED-BUFFER"
            else:
                ref, first = llvm_refuses(a)
                if ref:
                    cause = "B-UNDECODABLE"
                else:
                    cause = "A-DECODER-GAP"; gap_text = first
        elif reason == "terminator":
            cause = "C-SHORT-STUB"
        else:
            if span > bufl:
                cause = "D-OVERRUN"
            elif rf > 16384:
                cause = "B-RUNAWAY"
            else:
                cause = "D-TILES-INTO-CODE"
        sh = shape(t)
        rows.append({"bucket": bucket, "target": t, "cause": cause,
                     "n_insns": len(ins), "span": span, "run": rf,
                     "after_stop": max(0, rf - stop_off),
                     "blocked": blocked_byte, "gap_text": gap_text,
                     "sym": addr2name.get(t, ""), **sh,
                     "text": " ; ".join(x for _a, _n, x in ins[:4])})

ORDER = ["C-SHORT-STUB", "D-TILES-INTO-CODE", "D-OVERRUN", "D-TRUNCATED-BUFFER",
         "A-DECODER-GAP", "B-UNDECODABLE", "B-RUNAWAY"]
HYP = {"A-DECODER-GAP": "(a)", "B-UNDECODABLE": "(b)", "B-RUNAWAY": "(b)",
       "C-SHORT-STUB": "(c)", "D-TILES-INTO-CODE": "(d)", "D-OVERRUN": "(d)",
       "D-TRUNCATED-BUFFER": "(d)"}

for bucket, label, total in (("B1", "decoded fewer than 3 instructions", len(b1)),
                             ("B2", "no `ret`, and does not end at a code boundary", len(b2))):
    print(f"\n{'='*78}\nBUCKET {bucket}: {label}   ({total} ranges)\n{'='*78}")
    print(f"  {'cause':<20} {'hyp':<4} {'ranges':>6} {'bytes decoded':>14} "
          f"{'bytes past stop':>16}   evidence flags")
    for cause in ORDER:
        sel = [r for r in rows if r["bucket"] == bucket and r["cause"] == cause]
        if not sel:
            continue
        na = sum(1 for r in sel if r["ascii"])
        np_ = sum(1 for r in sel if r["ptrtable"])
        ni = sum(1 for r in sel if r["implausible"])
        print(f"  {cause:<20} {HYP[cause]:<4} {len(sel):>6} "
              f"{sum(r['span'] for r in sel):>14,} {sum(r['after_stop'] for r in sel):>16,}"
              f"   ascii {na}  ptrtable {np_}  implausible {ni}")
    print(f"  {'-'*20} {'':4} {'-'*6} {'-'*14} {'-'*16}")
    sel = [r for r in rows if r["bucket"] == bucket]
    print(f"  {'TOTAL':<20} {'':<4} {len(sel):>6} {sum(r['span'] for r in sel):>14,}"
          f" {sum(r['after_stop'] for r in sel):>16,}")
print("\n⚠ 'bytes decoded' and 'bytes past stop' measure DIFFERENT things and are"
      "\n  never added: the first is what the range would contribute if accepted;"
      "\n  the second is how much of its run sits beyond the stopping point, an"
      "\n  UPPER BOUND on what removing the blocker could reach -- and only if"
      "\n  those bytes turn out to be code at all.")

# --------------------------------------------------- (a): which forms
print(f"\n{'='*78}\nHYPOTHESIS (a): forms the DECODER cannot spell\n{'='*78}")
gaps = [r for r in rows if r["cause"] == "A-DECODER-GAP"]
if not gaps:
    print("  NONE. Every mid-run `db` in both buckets is refused by llvm-mc's")
    print("  TLCS-900 disassembler as well, so no range in either bucket is held")
    print("  up by a hole in MAME's opcode table.")
else:
    agg = collections.defaultdict(lambda: [0, 0, 0, ""])
    for r in gaps:
        k = r["blocked"]
        agg[k][0] += 1; agg[k][1] += r["span"]; agg[k][2] += r["after_stop"]
        agg[k][3] = agg[k][3] or r["gap_text"]
    print(f"  {'bytes':<12} {'ranges':>6} {'decoded':>9} {'past stop':>10}   llvm-mc says")
    for k, v in sorted(agg.items(), key=lambda kv: -kv[1][2]):
        print(f"  {k:<12} {v[0]:>6} {v[1]:>9,} {v[2]:>10,}   {v[3]}")

# for context: what DOES block, ranked the same way
print(f"\n  For contrast -- B-UNDECODABLE byte patterns, ranked by bytes past the")
print(f"  stop. These are NOT actionable as spellings: both decoders refuse them.")
und = collections.defaultdict(lambda: [0, 0, 0])
for r in rows:
    if r["cause"] == "B-UNDECODABLE":
        k = r["blocked"]
        und[k][0] += 1; und[k][1] += r["span"]; und[k][2] += r["after_stop"]
print(f"  {'bytes':<12} {'ranges':>6} {'decoded':>9} {'past stop':>10}")
for k, v in sorted(und.items(), key=lambda kv: -kv[1][2])[:12]:
    print(f"  {k:<12} {v[0]:>6} {v[1]:>9,} {v[2]:>10,}")

# --------------------------------------------------- (c): the < 3 threshold
print(f"\n{'='*78}\nHYPOTHESIS (c): ranges rejected only by the `< 3` threshold\n{'='*78}")
stubs = [r for r in rows if r["cause"] == "C-SHORT-STUB"]
tiles = [r for r in rows if r["cause"] == "D-TILES-INTO-CODE"]
for name, sel in (("end in a terminator (`ret`/`reti`/`retd`)", stubs),
                  ("tile exactly into already-disassembled code", tiles)):
    print(f"\n  {len(sel)} ranges {name}:")
    by = collections.Counter(r["n_insns"] for r in sel)
    for n in sorted(by):
        s = [r for r in sel if r["n_insns"] == n]
        clean = [r for r in s if not r["implausible"] and not r["ascii"]]
        print(f"    {n} instruction(s): {by[n]:4} ranges, {sum(r['span'] for r in s):5,} B"
              f"   -- {len(clean)} with no data-shape flag")
print(f"\n  ARGUABLY-ARBITRARY REJECTIONS, the answer to the question as posed:")
clean_stubs = [r for r in stubs if not r["implausible"] and not r["ascii"] and not r["ptrtable"]]
print(f"    {len(clean_stubs)} ranges / {sum(r['span'] for r in clean_stubs):,} B are 1-2"
      f" instructions ending in a terminator with NO data-shape flag.")
print(f"    {len(stubs) - len(clean_stubs)} more end in a terminator but DO carry one"
      f" (listed by --dump).")

# --------------------------------------------------- controls
print(f"\n{'='*78}\nCONTROLS for the two data-shape rules\n{'='*78}")
print("  What would falsify each: a control drawn from bytes that CANNOT be a")
print("  string or a pointer table must score near zero. If it does not, the")
print("  rule is loose and its counts above are inflated.")
random.seed(20260823)
code_addrs = [i for i in range(0, len(terr) - 64, 997) if terr[i] == 1][:4000]
fp_a = sum(1 for i in code_addrs if ascii_run(rom, i) >= 8)
fp_p = sum(1 for i in code_addrs if ptr_words(rom, i) >= 3)
print(f"\n  control 1 -- {len(code_addrs)} addresses inside CODE territory"
      f" (real instructions):")
print(f"      ascii     {fp_a:4} / {len(code_addrs)}  ({100*fp_a/len(code_addrs):.2f}%)")
print(f"      ptrtable  {fp_p:4} / {len(code_addrs)}  ({100*fp_p/len(code_addrs):.2f}%)")
shuf_a = shuf_p = 0
for r in rows:
    off = r["target"] - crr.BASE
    win = bytearray(rom[off:off + 64])
    random.shuffle(win)
    if ascii_run(win, 0) >= 8:
        shuf_a += 1
    if ptr_words(win, 0) >= 3:
        shuf_p += 1
print(f"\n  control 2 -- the {len(rows)} refused ranges with their own first 64 bytes")
print(f"               SHUFFLED (same byte distribution, no arrangement):")
print(f"      ascii     {shuf_a:4} / {len(rows)}  ({100*shuf_a/len(rows):.2f}%)")
print(f"      ptrtable  {shuf_p:4} / {len(rows)}  ({100*shuf_p/len(rows):.2f}%)")
print(f"\n  measured, unshuffled, over the same {len(rows)} ranges:")
print(f"      ascii     {sum(1 for r in rows if r['ascii']):4}")
print(f"      ptrtable  {sum(1 for r in rows if r['ptrtable']):4}")

# --------------------------------------------------- worked examples
print(f"\n{'='*78}\nONE WORKED EXAMPLE PER CAUSE -- check these by hand\n{'='*78}")
for cause in ORDER:
    sel = [r for r in rows if r["cause"] == cause]
    if not sel:
        continue
    r = max(sel, key=lambda r: r["after_stop"] + r["span"])
    print(f"\n{cause}  {HYP[cause]}   ({len(sel)} ranges)")
    print(f"  0x{r['target']:06X}  {r['sym'] or '(no ELF symbol)'}"
          f"   bucket {r['bucket']}  run {r['run']} B  decoded {r['span']} B"
          f"  {r['n_insns']} insn(s)")
    off = r["target"] - crr.BASE
    print(f"  ROM bytes : {rom[off:off+16].hex(' ')}")
    for a, n, x in decodes[r["target"]][:10]:
        print(f"    {a:06x}: {rom[a-crr.BASE:a-crr.BASE+n].hex(' '):<12} {x}")
    if len(decodes[r["target"]]) > 10:
        print(f"    ... {len(decodes[r['target']]) - 10} more decoded instructions")
    if r["blocked"]:
        print(f"    -- unidasm prints `db` for {r['blocked']}"
              + (f", llvm-mc reads it as `{r['gap_text']}`" if r["gap_text"] else
                 ", and llvm-mc refuses it too"))
    flags = [k for k in ("ascii", "ptrtable") if r[k]]
    if r["implausible"]:
        flags.append(f"implausible:{r['implausible']}")
    print(f"    shape flags: {', '.join(flags) if flags else 'none'}")

# --------------------------------------------------- optional: spelling
if DO_SPELLING:
    print(f"\n{'='*78}\nWOULD SPELLING BLOCK THEM ANYWAY?\n{'='*78}")
    print("  For every range in both buckets, try the converter's own spelling")
    print("  loop on the prefix it decoded. A range that no spelling covers would")
    print("  be refused by a LATER bucket even if these two gates were relaxed.")
    unspellable = collections.Counter()
    n_clean = 0
    for r in rows:
        t = r["target"]
        want = rom[t - crr.BASE: t - crr.BASE + r["span"]]
        pos, ok = 0, True
        for _a, n, x in decodes[t]:
            tgt = want[pos:pos + n]; pos += n
            if crr.BRANCH_RE.match(x.strip()):
                continue
            if not any(cc.encode(c) == tgt for c in
                       list(cc.translate(x)) + [cc.canonical(x)]):
                mn = x.split()[0]
                rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
                unspellable[mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                              re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))] += 1
                ok = False
        n_clean += ok
    print(f"\n  {n_clean} of {len(rows)} refused ranges are FULLY SPELLABLE as decoded;")
    print(f"  {len(rows)-n_clean} contain at least one instruction no spelling matches.")
    print(f"\n  forms, by instances:")
    for k, v in unspellable.most_common(15):
        print(f"    {v:5}  {k}")

if DUMP:
    with open(DUMP, "w") as f:
        cols = ["bucket", "target", "cause", "n_insns", "span", "run", "after_stop",
                "blocked", "gap_text", "ascii", "ptrtable", "implausible", "sym", "text"]
        f.write("\t".join(cols) + "\n")
        for r in sorted(rows, key=lambda r: (r["bucket"], r["cause"], r["target"])):
            f.write("\t".join(f"0x{r[c]:06X}" if c == "target" else str(r[c])
                              for c in cols) + "\n")
    print(f"\nper-range table written: {DUMP}  ({len(rows)} rows)")
