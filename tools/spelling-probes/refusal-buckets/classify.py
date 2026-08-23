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

  C-SHORT-STUB          the decode ended in an UNCONDITIONAL `ret`/`reti`/
                        `retd` after one or two instructions. Nothing is wrong
                        with these; the `< 3` threshold is the whole objection.
  D-COND-RET-STOP       the decode ended in a CONDITIONAL `ret <cc>`, which is
                        not the end of a routine at all -- execution continues
                        at the next instruction. `decode_range` stops on the
                        MNEMONIC, so `ret Z` truncates a decode exactly as a
                        bare `ret` does. These look like (c) and are (d).
  D-TILES-INTO-CODE     the decode consumed the entire undisassembled run and
                        ends exactly where already-disassembled code begins --
                        the converter's own `ends_at_code` rule, which `< 3`
                        pre-empts.
  D-OVERRUN             the last instruction STRADDLES that boundary: unidasm
                        over-reads its input file, so a run of N bytes can come
                        back holding N+1 or N+2 bytes of "instructions", built
                        partly from bytes that were never in the buffer.
  D-TRUNCATED-BUFFER    unidasm printed `db` for the last bytes of the buffer,
                        and the SAME BYTES decode cleanly once it is given the
                        following ROM bytes too (VERIFIED per range, counted in
                        the report). The `db` is an artefact of the buffer
                        ending, not a property of the bytes.
  A-DECODER-GAP         unidasm printed `db` mid-run, llvm-mc's independent
                        TLCS-900 disassembler decodes those bytes, AND llvm-mc's
                        own assembler turns that text back into the same bytes.
                        A hole in MAME's table -- the only genuinely "the tool
                        cannot express this" cause available in these buckets.
  B-LLVM-DECODER-BUG    unidasm printed `db`, llvm-mc's disassembler printed
                        something, and llvm-mc's ASSEMBLER rejects its own
                        output. Not a MAME gap: an over-permissive decode. The
                        round trip is what separates this from A-DECODER-GAP,
                        and without it this probe reported an actionable
                        "missing form" that does not exist (anti-pattern 11).
  B-UNDECODABLE         unidasm printed `db` mid-run and llvm-mc refuses the
                        same bytes too. TWO INDEPENDENT DECODERS agree there is
                        no instruction there.

⚠ D-OVERRUN and D-TRUNCATED-BUFFER are the same phenomenon twice: an
instruction that STRADDLES the end of the undisassembled run. unidasm
zero-pads past the end of its input file, so it sometimes prints that
instruction (built partly from bytes that are not the ROM's) and sometimes
prints `db`. Either way the decode and the SOURCES DISAGREE about where an
instruction boundary is, and the `next terr` column says what the sources put
immediately after the run.
  B-RUNAWAY             the decode ran to the converter's 16,384-byte cap with
                        no terminator and no `db` -- the shape its own docstring
                        names as "a runaway decode through data".

DATA-SHAPE EVIDENCE is reported as separate COLUMNS, never folded into the
cause, because the cause is a fact about the decode and the shape is an
inference about the bytes:

  ascii       >= 8 consecutive printable bytes starting within the first 4
  ptrtable    >= 3 of 4 consecutive little-endian u32 words land in
              0xE00000..0xFFFFFF, testing all FOUR PHASES (t-3 .. t) -- a
              target one byte inside a pointer table is exactly the shape a
              mis-derived entry point has, and a phase-0-only rule misses it
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
  * A-DECODER-GAP proves the two decoders disagree AND that llvm-mc is
    self-consistent about the bytes. It does NOT prove llvm-mc is right; only
    the Toshiba manual settles that.
  * `next terr` reports what the SOURCES say follows the run. It cannot say
    which side of a straddling instruction is wrong -- the entry point, or the
    existing disassembly's boundary.
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
_fp = cm.fingerprint()
print(f"  territory map    from v7/maincpu/*.s at git {_fp['head']}")
print(f"                   CODE {_fp['code_bytes']:,} B   DATA {_fp['data_bytes']:,} B"
      f"   fingerprint {_fp['sha256']}...")
print("  \u26a0 THE TERRITORY MAP IS PART OF THE QUESTION. Two runs 20 minutes")
print("    apart with the SAME targets sha256 gave bucket B1 = 169 and then")
print("    182 ranges, because an --apply round moved the map underneath.")
print("    Quote the fingerprint with the number, or the number means nothing.")
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


_UNI_MEMO = {}
_UNI_LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
_UNI_SCRATCH = tempfile.mkdtemp(prefix="kn5000_retry_")


def unidasm_retry(addr, nbytes=64):
    """Does unidasm decode the byte at `addr` when it is NOT starved of input?

    `decode_range()` hands unidasm only the undisassembled run, and unidasm
    zero-pads past the end of that file. This re-runs it on 64 real ROM bytes,
    which is the check behind D-TRUNCATED-BUFFER: same bytes, more of them.
    Returns (decoded_ok, text).
    """
    if addr in _UNI_MEMO:
        return _UNI_MEMO[addr]
    off = addr - crr.BASE
    tmp = os.path.join(_UNI_SCRATCH, "r.bin")
    open(tmp, "wb").write(rom[off:off + nbytes])
    txt = subprocess.run([crr.UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True, timeout=60).stdout
    first = ""
    for ln in txt.split("\n"):
        m = _UNI_LINE.match(ln)
        if m:
            first = m.group(3).strip(); break
    _UNI_MEMO[addr] = (not first.lower().startswith("db"), first)
    return _UNI_MEMO[addr]


def llvm_roundtrips(addr, text, nbytes):
    """Does llvm-mc's ASSEMBLER turn its own disassembly back into these bytes?

    ⚠ Anti-pattern 11 in reverse. `e8 33` at 0xED32F3 disassembles under llvm-mc
    as `bit 13, xwa`, and llvm-mc's assembler rejects that text outright -- so
    reporting it as "a form MAME cannot decode" would have invented an
    actionable spelling gap out of a decoder bug. Nothing is called a gap
    without this round trip.
    """
    want = rom[addr - crr.BASE: addr - crr.BASE + nbytes]
    got = cc.encode(text)
    return got is not None and want.startswith(got)


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


def ptr_words(buf, off, n=4, phases=4):
    """Best count, over all `phases` alignments, of u32 words in the ROM window.

    Phase matters: 0xED32F3 is one byte inside a table of `.long` ROM addresses,
    and at phase 0 it scores 0 while at phase 3 it scores 4.
    """
    best = 0
    for p in range(phases):
        base = off - p
        if base < 0:
            continue
        hits = sum(1 for i in range(n)
                   if 0xE00000 <= int.from_bytes(buf[base + 4*i: base + 4*i + 4],
                                                 "little") <= 0xFFFFFF)
        best = max(best, hits)
    return best


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
        # ⚠ A CONDITIONAL `ret` IS NOT A TERMINATOR. `TERMINATORS` is matched on
        # the mnemonic alone, so `ret NZ` -- after which execution continues at
        # the next instruction -- ends the decode exactly as a bare `ret` does.
        # That is the same mistake `UNCOND_JUMP` was written to avoid for `jr`.
        _p = (ins[-1][2].strip().split() if ins else [])
        cond_ret = (len(_p) > 1 and _p[0].lower() == "ret"
                    and _p[1].lower().rstrip(",") != "t")
        stop_off = span                      # bytes consumed before the stop
        blocked_byte, gap_text, confirmed = "", "", ""
        if reason == "db":
            a, n, _x = raws[t]["lines"][i]
            stop_off = a - t
            blocked_byte = rom[a - crr.BASE: a - crr.BASE + n].hex()
            uni_ok, uni_text = unidasm_retry(a)
            if stop_off + n >= bufl:
                # starved input, not a property of the bytes -- but VERIFY it
                cause = "D-TRUNCATED-BUFFER" if uni_ok else "B-UNDECODABLE"
                confirmed = uni_text if uni_ok else ""
            elif uni_ok:
                # unidasm decodes the same bytes with more input, yet stopped
                # mid-run: that would mean the run boundary, not the bytes.
                cause = "D-TRUNCATED-BUFFER"; confirmed = uni_text
            else:
                ref, first = llvm_refuses(a)
                if ref:
                    cause = "B-UNDECODABLE"
                elif llvm_roundtrips(a, first, n):
                    cause = "A-DECODER-GAP"; gap_text = first
                else:
                    cause = "B-LLVM-DECODER-BUG"; gap_text = first
        elif reason == "terminator":
            cause = "D-COND-RET-STOP" if cond_ret else "C-SHORT-STUB"
        else:
            if span > bufl:
                cause = "D-OVERRUN"
            elif rf > 16384:
                cause = "B-RUNAWAY"
            else:
                cause = "D-TILES-INTO-CODE"
        sh = shape(t)
        _n = t - crr.BASE + rf
        nxt = {0: "unmapped", 1: "CODE", 2: "DATA", 3: "PADDING"}.get(
            terr[_n] if _n < len(terr) else 0, "?")
        rows.append({"bucket": bucket, "target": t, "cause": cause,
                     "n_insns": len(ins), "span": span, "run": rf,
                     "after_stop": max(0, rf - stop_off), "next_terr": nxt,
                     "cond_ret": cond_ret,
                     "blocked": blocked_byte, "gap_text": gap_text,
                     "confirmed": confirmed,
                     "sym": addr2name.get(t, ""), **sh,
                     "text": " ; ".join(x for _a, _n, x in ins[:4])})

ORDER = ["C-SHORT-STUB", "D-COND-RET-STOP", "D-TILES-INTO-CODE", "D-OVERRUN",
         "D-TRUNCATED-BUFFER",
         "A-DECODER-GAP", "B-LLVM-DECODER-BUG", "B-UNDECODABLE", "B-RUNAWAY"]
HYP = {"A-DECODER-GAP": "(a)", "B-UNDECODABLE": "(b)", "B-RUNAWAY": "(b)",
       "B-LLVM-DECODER-BUG": "(b)", "C-SHORT-STUB": "(c)",
       "D-COND-RET-STOP": "(d)", "D-TILES-INTO-CODE": "(d)", "D-OVERRUN": "(d)",
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
        nx = collections.Counter(r["next_terr"] for r in sel)
        print(f"  {cause:<20} {HYP[cause]:<4} {len(sel):>6} "
              f"{sum(r['span'] for r in sel):>14,} {sum(r['after_stop'] for r in sel):>16,}"
              f"   ascii {na} ptr {np_} implaus {ni} | next "
              + " ".join(f"{k}:{v}" for k, v in nx.most_common()))
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
    print("  NONE. Every mid-run `db` in both buckets is either refused by")
    print("  llvm-mc's TLCS-900 disassembler as well, or decoded by it into text")
    print("  its own assembler will not accept. No range in either bucket is held")
    print("  up by a hole in MAME's opcode table.")
    bug = [r for r in rows if r["cause"] == "B-LLVM-DECODER-BUG"]
    if bug:
        print(f"\n  {len(bug)} range(s) reached the round-trip gate and failed it --")
        print("  i.e. would have been reported as an actionable gap without it:")
        for r in bug:
            print(f"    0x{r['target']:06X}  bytes {r['blocked']:<8} llvm-mc reads "
                  f"`{r['gap_text']}`, which llvm-mc will not assemble")
else:
    agg = collections.defaultdict(lambda: [0, 0, 0, ""])
    for r in gaps:
        k = r["blocked"]
        agg[k][0] += 1; agg[k][1] += r["span"]; agg[k][2] += r["after_stop"]
        agg[k][3] = agg[k][3] or r["gap_text"]
    print(f"  {'bytes':<12} {'ranges':>6} {'decoded':>9} {'past stop':>10}   llvm-mc says"
        f" (round-trips to the same bytes)")
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
print(f"\n{'='*78}\nHYPOTHESIS (d): the decode does not TILE the run\n{'='*78}")
print("  D-OVERRUN and D-TRUNCATED-BUFFER both mean: decoding straight from the")
print("  entry to the end of the undisassembled run, the instruction stream does")
print("  not land exactly on the boundary the sources put there. `decode_range`")
print("  stops only at `ret`/`reti`/`retd`, so a single run can carry several")
print("  routines and the mismatch may originate anywhere inside it -- this is a")
print("  disagreement about framing, and it does NOT say which side is wrong.")
ov = [r for r in rows if r["cause"] == "D-OVERRUN"]
tb = [r for r in rows if r["cause"] == "D-TRUNCATED-BUFFER"]
h = collections.Counter(r["span"] - min(r["run"], 16384) for r in ov)
print(f"\n  {len(ov)} D-OVERRUN: bytes the decode runs PAST the boundary")
for k in sorted(h):
    print(f"      +{k} byte(s): {h[k]:4} ranges")
h2 = collections.Counter(r["run"] - (r["run"] - r["after_stop"]) for r in tb)
print(f"\n  {len(tb)} D-TRUNCATED-BUFFER: bytes left OVER at the boundary,"
      f" too few to finish\n      the instruction that starts there")
for k in sorted(h2):
    print(f"      {k} byte(s) left: {h2[k]:4} ranges")
print(f"\n  Runs whose decode tiles PERFECTLY are not here at all -- they are the"
      f"\n  D-TILES-INTO-CODE rows above, which the `< 3` threshold refuses"
      f" anyway.")
tb = [r for r in rows if r["cause"] == "D-TRUNCATED-BUFFER"]
print(f"\n  D-TRUNCATED-BUFFER verification: {sum(1 for r in tb if r['confirmed'])}"
      f" of {len(tb)} confirmed by re-running unidasm on 64 real ROM bytes at the")
print(f"  same address -- the `db` disappears when the input is not starved.")

print(f"\n{'='*78}\nHYPOTHESIS (c): ranges rejected only by the `< 3` threshold\n{'='*78}")
stubs = [r for r in rows if r["cause"] == "C-SHORT-STUB"]
tiles = [r for r in rows if r["cause"] == "D-TILES-INTO-CODE"]
for name, sel in (("end in an unconditional terminator", stubs),
                  ("tile exactly into already-disassembled code", tiles)):
    print(f"\n  {len(sel)} ranges {name}:")
    by = collections.Counter(r["n_insns"] for r in sel)
    for n in sorted(by):
        g = [r for r in sel if r["n_insns"] == n]
        clean = [r for r in g if not r["implausible"] and not r["ascii"]]
        print(f"    {n} instruction(s): {by[n]:4} ranges, {sum(r['span'] for r in g):5,} B"
              f"   -- {len(clean)} with no data-shape flag")

# ⚠ THE `< 3` THRESHOLD IS NOT THE ONLY THING HOLDING THESE.
cond = [r for r in rows if r["cause"] == "D-COND-RET-STOP"]
print(f"\n  {len(cond)} further ranges, {sum(r['span'] for r in cond):,} B, stop at a"
      f" CONDITIONAL `ret <cc>`.")
print("    They are counted as D-COND-RET-STOP, not here: a conditional return")
print("    does not end a routine, so the code continues past the stop and the")
print("    `< 3` threshold is not what is holding them. Raising the threshold")
print("    would convert two instructions of a longer routine and stop there.")

uncond = stubs
clean = [r for r in uncond
         if not r["implausible"] and not r["ascii"] and not r["ptrtable"]]
print(f"\n  ARGUABLY-ARBITRARY REJECTIONS, the answer to the question as posed:")
print(f"    {len(clean)} ranges / {sum(r['span'] for r in clean):,} B are 1-2 instructions"
      f" ending in an UNCONDITIONAL")
print(f"    terminator with no data-shape flag -- rejected by the threshold alone.")
print(f"    {len(uncond) - len(clean)} more end in an unconditional terminator but carry"
      f" a flag (see --dump).")
tclean = [r for r in tiles
          if not r["implausible"] and not r["ascii"] and not r["ptrtable"]]
print(f"    {len(tclean)} ranges / {sum(r['span'] for r in tclean):,} B are 1-2 instructions"
      f" that TILE the run exactly")
print(f"    and abut code, with no data-shape flag -- these would pass the")
print(f"    converter's own `ends_at_code` rule if they had one more instruction.")
print(f"\n  Examples of the unconditional group, so the claim is checkable:")
for r in sorted(clean, key=lambda r: -r["span"])[:6]:
    print(f"    0x{r['target']:06X}  {r['span']} B  {r['sym'] or '(unnamed)':<38} {r['text']}")

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
m_a = sum(1 for r in rows if r["ascii"])
m_p = sum(1 for r in rows if r["ptrtable"])
print(f"\n  measured, unshuffled, over the same {len(rows)} ranges:")
print(f"      ascii     {m_a:4}")
print(f"      ptrtable  {m_p:4}")
print(f"\n  READ THIS BEFORE USING THE COLUMNS. `ptrtable` separates: {m_p} measured")
print(f"  against {shuf_p} shuffled and {fp_p} in {len(code_addrs)} CODE-territory samples.")
print(f"  `ascii` DOES NOT: {m_a} measured against {shuf_a} shuffled is not a signal,")
print(f"  so no conclusion in this report rests on the ascii column. It is kept")
print(f"  because a column that fails its control has to be visible to be")
print(f"  distrusted -- deleting it would leave the impression it was never tried.")

# --------------------------------------------------- worked examples
print(f"\n{'='*78}\nONE WORKED EXAMPLE PER CAUSE -- check these by hand\n{'='*78}")
for cause in ORDER:
    sel = [r for r in rows if r["cause"] == cause]
    if not sel:
        continue
    # prefer a range with NO data-shape flag: the point of an example is to be
    # representative of the cause, not to showcase its most doubtful member
    _pref = [x for x in sel if not (x["ascii"] or x["ptrtable"] or x["implausible"])]
    # rank by (has an ELF name, bytes decoded): a named range with real content
    # is what a reviewer can most cheaply check against the sources
    r = max(_pref or sel, key=lambda x: (bool(x["sym"]), x["span"]))
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
    print(f"    run ends at 0x{r['target']+r['run']:06X}, where the sources have "
          f"{r['next_terr']}")
    if r["blocked"]:
        note = ", and llvm-mc refuses it too"
        if r["gap_text"]:
            note = f", llvm-mc reads it as `{r['gap_text']}`"
        elif r["confirmed"]:
            note = f"; given 64 ROM bytes instead it decodes as `{r['confirmed']}`"
        print(f"    -- unidasm prints `db` for {r['blocked']}{note}")
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
    unspellable = {"all": collections.Counter(), "code-shaped": collections.Counter()}
    n_clean = {"all": 0, "code-shaped": 0}
    n_tot = {"all": 0, "code-shaped": 0}
    for r in rows:
        t = r["target"]
        groups = ["all"] + (["code-shaped"] if HYP[r["cause"]] in ("(c)", "(d)") else [])
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
                key = mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                        re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))
                for g in groups:
                    unspellable[g][key] += 1
                ok = False
        for g in groups:
            n_tot[g] += 1; n_clean[g] += ok
    print("\n  ⚠ Counted over ALL refused ranges this is a polluted number: most of")
    print("    the instances come from ranges two decoders say are not code, where")
    print("    'no spelling matches' is the expected answer. The second block is")
    print("    restricted to the (c)/(d) ranges -- the ones with a case for being")
    print("    code -- and is the only one worth acting on.")
    for g in ("all", "code-shaped"):
        print(f"\n  [{g}]  {n_clean[g]} of {n_tot[g]} ranges are FULLY SPELLABLE as decoded;"
              f" {n_tot[g]-n_clean[g]} are not.")
        for k, v in unspellable[g].most_common(12):
            print(f"    {v:5}  {k}")

if DUMP:
    with open(DUMP, "w") as f:
        cols = ["bucket", "target", "cause", "n_insns", "span", "run", "after_stop",
                "next_terr", "cond_ret", "blocked", "gap_text", "confirmed",
                "ascii", "ptrtable", "implausible", "sym", "text"]
        f.write("\t".join(cols) + "\n")
        for r in sorted(rows, key=lambda r: (r["bucket"], r["cause"], r["target"])):
            f.write("\t".join(f"0x{r[c]:06X}" if c == "target" else str(r[c])
                              for c in cols) + "\n")
    print(f"\nper-range table written: {DUMP}  ({len(rows)} rows)")
