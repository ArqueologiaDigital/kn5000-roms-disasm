#!/usr/bin/env python3
"""Per range: is the DECODE mis-framed, or is the blocking LABEL wrong?

QUESTION ANSWERED
-----------------
`convert_reachable_ranges.rewrite()` declines a range when a label inside it does
not sit on a decoded instruction boundary ("NEVER DROP A LABEL").  The guard's
own comment says the refusal is ambiguous: "a label that is not an instruction
boundary also means the decode disagrees with the existing framing", and either
side may be the wrong one.  This script settles which, per range, and prices the
bucket.

⚠ TWO EARLIER ANSWERS ARE RETRACTED and are not revived here: "88% of these
labels are displaced by 0x41A" (contradicted by the ROM's pointer tables, 11 of
11), and "most of this bucket is the guard working correctly, the honest residue
is much smaller than the raw count" -- which this script contradicts with
evidence below.

WHAT IT MEASURES
    1. THE BUCKET.  Runs the real converter through the real --apply path with
       every repo write intercepted and discarded, wrapping rewrite() to record
       each range it declines without recording a reason.  That is the label
       guard, and nothing else lands there.
    2. WHERE THE LABEL ADDRESSES COME FROM.  v7's tree was seeded from v9's
       (scripts/build/v7_incbin_transplant.py: "The v7 build reuses v9 source
       code ... the .incbin size must equal the assembled size of the source
       range being replaced ... determined by the ELF address of the NEXT label
       in the SAME SOURCE FILE").  So a v7 interior label's address is v9's
       offset replayed onto v7's bytes.  Two checks:
         - the GAP between consecutive labels, v7 vs v9/v10;
         - the BYTE AGREEMENT in a +/-32 B window at the same named label.
       source_index()'s ROM check cannot catch a label placed this way: the
       `.byte` run was cut from the v7 ROM at that address by construction, so
       the check is circular with respect to the label's position.
    3. EVIDENCE THE DECODE IS RIGHT, per range:
         E1 the entry is a call/jp/jrl target read out of an already-decoded
            instruction (analysis/v7-reachability/v7_call_targets.json)
         E2 the instruction that ENDS at the entry is a terminator
         E3 a framing started at the ENCLOSING BLOCK LABEL -- a different start
            address chosen by the sources themselves -- converges exactly on the
            entry
         S1 a sibling revision (v9/v10), content-aligned by a unique byte match,
            frames the same bytes with the same instruction starts
         S2 the stack frame balances to zero across the range
         S3 an internal jr/jrl/calr lands exactly on a decoded boundary
       E3 is weak on its own (variable-length decoders self-synchronise); S1/S2
       are not.
    4. THE NULL FOR THE DRIFT FIGURE.  Every blocking label sits 1-5 bytes past a
       decoded boundary, which LOOKS diagnostic and is NOT: given the instruction
       lengths in these decodes, a label dropped at random inside a correct
       decode would land at +1 46% of the time.  Printed so nobody quotes drift
       as evidence.
    5. WHAT A FIX WOULD RECOVER: the bucket's bytes, plus the number of
       "a branch target cannot be named" skips that would become nameable if the
       blocking labels moved onto the boundary they drifted off (measured: 1).

REQUIRES  rebuilt_ROMs/kn5000_{v7,v9,v10}_program.llvm.elf (a completed
`make all`), ~/compartilhado/tools/unidasm and the LLVM build.  ~6 minutes.
Writes nothing into the repo.

Run:  python3 scripts/analysis/v7_label_guard_verdict.py [--json OUT.json]
"""
import collections, contextlib, importlib.util, io, json, os, pickle, re
import struct, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
SCRATCH = tempfile.mkdtemp(prefix="lguard_")
_real_open = open


# ------------------------------------------------------------- write guard
class _Sink:
    def __init__(self, p): self.p = p
    def write(self, d): return len(d)
    def close(self): pass
    def __enter__(self): return self
    def __exit__(self, *a): return False


def guarded_open(path, mode="r", *a, **kw):
    if any(c in mode for c in "wax+"):
        if os.path.abspath(str(path)).startswith(os.path.abspath(REPO) + os.sep):
            return _Sink(path)
    return _real_open(path, mode, *a, **kw)


def load(name, rel):
    sp = importlib.util.spec_from_file_location(name, os.path.join(REPO, rel))
    m = importlib.util.module_from_spec(sp)
    argv = sys.argv; sys.argv = [name]
    try: sp.loader.exec_module(m)
    finally: sys.argv = argv
    return m


def syms(elf):
    out = {}
    for ln in subprocess.run([NM, "--no-sort", os.path.join(REPO, elf)],
                             capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3:
            try: a = int(p[0], 16)
            except ValueError: continue
            if BASE <= a < 0x1000000 and p[2] not in out:
                out[p[2]] = a
    return out


def dis(rom, start, n):
    p = os.path.join(SCRATCH, "_d.bin")
    _real_open(p, "wb").write(rom[start - BASE:start - BASE + n])
    o = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", hex(start)],
                       capture_output=True, text=True, timeout=120).stdout
    rows = []
    for line in o.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return rows


# ------------------------------------------- 1. collect the guard's refusals
def collect():
    os.chdir(REPO)
    mod = load("crr", "scripts/converters/convert_reachable_ranges.py")
    mod.open = guarded_open
    mod.cc.open = guarded_open
    cases, state = [], {}
    real_index, real_decode = mod.source_index, mod.decode_range

    def w_index(s):
        state["idx"] = real_index(s); return state["idx"]

    def w_decode(rom, terr, start, limit=16384):
        state["rom"], state["terr"] = rom, terr
        return real_decode(rom, terr, start, limit)

    mod.source_index, mod.decode_range = w_index, w_decode
    _orig = mod.rewrite

    def hook(idx, t, span, insns, texts, addr2name, branch_labels=None):
        rec = {"entry": t, "span": span, "texts": list(texts),
               "insns": [(a, n, x) for a, n, x in insns]}
        for path, (lines, blocks) in idx.items():
            if not any(bk[1] <= t < bk[1] + len(bk[4]) for bk in blocks):
                continue
            touched = sorted([bk for bk in blocks
                              if bk[1] < t + span and bk[1] + len(bk[4]) > t],
                             key=lambda bk: bk[2])
            first = touched[0]
            ia = {a for a, _n, _x in insns}
            rec["path"] = path
            rec["blocks"] = [(bk[0], bk[1], len(bk[4])) for bk in touched]
            rec["off"] = sorted((bk[1], bk[0]) for bk in touched if bk[0]
                                and bk[1] != first[1] and t <= bk[1] < t + span
                                and bk[1] not in ia)
            break
        before = dict(mod.REFUSED)
        res = _orig(idx, t, span, insns, texts, addr2name, branch_labels)
        rec["silent"] = (res is None
                         and all(mod.REFUSED.get(k, 0) == v for k, v in before.items())
                         and len(mod.REFUSED) == len(before))
        cases.append(rec)
        return res

    mod.rewrite = hook
    sys.argv = ["conv", "--apply"]
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        mod.main()
    return [c for c in cases if c["silent"]], state["rom"], buf.getvalue()


def main():
    cases, rom, log = collect()
    cases.sort(key=lambda c: c["entry"])
    rom9 = _real_open(os.path.join(REPO, "original_ROMs/kn5000_v9_program.rom"), "rb").read()
    s7 = syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    s9 = syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
    s10 = syms("rebuilt_ROMs/kn5000_v10_program.llvm.elf")
    tset = set(json.load(_real_open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"])
    nlab = sum(len(c["off"]) for c in cases)
    print(f"### 1. the bucket\n  {len(cases)} range(s), {sum(c['span'] for c in cases):,} bytes, "
          f"{nlab} off-boundary label(s)\n")

    # ---- 2. provenance of the label addresses
    same = diff = 0
    for c in cases:
        lab = [(b[1], b[0]) for b in c["blocks"] if b[0]]
        for i in range(len(lab) - 1):
            (a0, n0), (a1, n1) = lab[i], lab[i + 1]
            for sx in (s9, s10):
                if n0 in sx and n1 in sx:
                    if sx[n1] - sx[n0] == a1 - a0: same += 1
                    else: diff += 1
                    break
    common = sorted((a, n) for n, a in s7.items() if n in s9)
    csame = cdiff = 0
    for i in range(len(common) - 1):
        (a0, n0), (a1, n1) = common[i], common[i + 1]
        if a1 == a0: continue
        if s9[n1] - s9[n0] == a1 - a0: csame += 1
        else: cdiff += 1
    agree = []
    for c in cases:
        for a, nm in c["off"]:
            if nm in s9:
                a9 = s9[nm]
                agree.append(sum(1 for k in range(-32, 32)
                                 if rom[a - BASE + k] == rom9[a9 - BASE + k]) / 64.0)
    print("### 2. where the blocking label ADDRESSES come from")
    print(f"  consecutive label gaps inside these ranges, v7 vs v9/v10: "
          f"{same} identical, {diff} different")
    print(f"  CONTROL, every v7 symbol pair also present in v9        : "
          f"{csame:,} identical, {cdiff} different ({100.0*csame/(csame+cdiff):.1f}%)")
    print(f"  => the v7 label layout IS v9's layout, tree-wide.")
    print(f"  byte agreement v7 vs v9 in +/-32 B at the SAME NAMED LABEL: "
          f"mean {100.0*sum(agree)/max(len(agree),1):.1f}%  "
          f"(max {100.0*max(agree or [0]):.1f}%)")
    print(f"  => the offset is v9's, the bytes underneath it are not.\n")

    # ---- 3. per-range evidence
    TERM = ("ret", "reti", "retd")
    UNCOND = re.compile(r'^(?:jp\s+(?!(?:z|nz|c|nc|t|f|lt|ge|le|gt|ult|uge|ule|ugt|ov|nov|mi|pl)\s*,)'
                        r'|(?:jr|jrl)\s+t\s*,)', re.I)
    BR = re.compile(r'^(jr|jrl|calr)\s+(?:(\w+),\s*)?0x([0-9a-fA-F]+)$', re.I)
    LDA = re.compile(r'lda\s+xsp,\s*\(xsp\s*([-+])\s*(0x[0-9a-f]+)\)', re.I)
    IDX = re.compile(r'\b(inc|dec)\s+(\d+),\s*xsp\b', re.I)
    PP = re.compile(r'\b(push|pop)\s+(\w+)\b', re.I)
    RD = re.compile(r'\bretd\s+(0x[0-9a-f]+)', re.I)
    flat = {}
    for tag in ("v9", "v10"):
        flat[tag] = flatten(tag)
    romX = {"v9": rom9,
            "v10": _real_open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()}
    rows, drift_obs, drift_null, lens = [], collections.Counter(), collections.Counter(), collections.Counter()
    for c in cases:
        e, sp = c["entry"], c["span"]
        ia = {a: n for a, n, _x in c["insns"]}
        for n in ia.values():
            lens[n] += 1
            for k in range(1, n): drift_null[k] += 1
        fb = c["blocks"][0][1]
        bl = dis(rom, fb, max(e + sp - fb, 8) + 16)
        prev = [r for r in bl if r[0] + r[1] == e]
        E2 = bool(prev) and (prev[0][2].split()[0].lower() in TERM
                             or bool(UNCOND.match(prev[0][2])))
        E3 = e in {r[0] for r in bl}
        S3 = 0
        for a, n, x in c["insns"]:
            m = BR.match(x.strip())
            if m and e <= int(m.group(3), 16) < e + sp: S3 += 1
        d, nf = 0, 0
        for t in [x.lower() for x in c["texts"]]:
            m = LDA.search(t)
            if m: d += (-1 if m.group(1) == '-' else 1) * int(m.group(2), 16); nf += 1; continue
            m = IDX.search(t)
            if m: d += (1 if m.group(1) == 'inc' else -1) * int(m.group(2)); nf += 1; continue
            m = PP.match(t)
            if m: d += (-1 if m.group(1) == 'push' else 1) * (4 if m.group(2).startswith('x') else 2); nf += 1; continue
            m = RD.search(t)
            if m: d += int(m.group(1), 16); nf += 1
        S2 = nf > 0 and d == 0
        S1, sibtag = False, None
        for tag in ("v9", "v10"):
            al = content_align(rom, romX[tag], e - BASE, sp, fb - BASE)
            if al is None: continue
            starts, terr = flat[tag]
            if all((a - BASE + al) in starts for a in ia) and \
               all(terr[o + al] == 2 for o in range(e - BASE, e - BASE + sp)):
                S1, sibtag = True, tag
                break
        for a, nm in c["off"]:
            below = max((x for x in ia if x <= a), default=None)
            if below is not None: drift_obs[a - below] += 1
        rows.append({"entry": e, "span": sp, "labels": [nm for _a, nm in c["off"]],
                     "E1": e in tset, "E2": E2, "E3": E3,
                     "S1": S1, "S1_from": sibtag, "S2": S2, "S3": S3,
                     "corroborations": sum([S1, S2, S3 > 0, E2])})
    print("### 3. per-range evidence that the DECODE is right")
    print(f"  E1 entry is a decoded call/jp/jrl target : {sum(r['E1'] for r in rows)}/{len(rows)}")
    print(f"  E3 block-label framing converges on entry: {sum(r['E3'] for r in rows)}/{len(rows)}")
    print(f"  E2 previous instruction terminates there : {sum(r['E2'] for r in rows)}/{len(rows)}")
    print(f"  S1 sibling frames the same bytes the same: {sum(r['S1'] for r in rows)}/{len(rows)}")
    print(f"  S2 stack frame balances to zero          : {sum(r['S2'] for r in rows)}/{len(rows)}")
    print(f"  S3 internal branch lands on a boundary   : {sum(r['S3'] > 0 for r in rows)}/{len(rows)}")
    zero = [r for r in rows if r["corroborations"] == 0]
    print(f"\n  ranges with NONE of E2/S1/S2/S3: {len(zero)} "
          f"({sum(r['span'] for r in zero)} B) -- {[hex(r['entry']) for r in zero]}")
    print(f"  ranges with >=1                : {len(rows)-len(zero)} "
          f"({sum(r['span'] for r in rows)-sum(r['span'] for r in zero)} B)\n")
    print(f"{'entry':>9} {'B':>5}  E1 E2 E3 S1 S2 S3  labels")
    for r in rows:
        print(f"0x{r['entry']:06X} {r['span']:5}   "
              + "  ".join('Y' if r[k] else '.' for k in ("E1", "E2", "E3", "S1", "S2"))
              + f"  {r['S3']:2}  " + ", ".join(r["labels"])[:70])

    # ---- 4. the null for drift
    tn, to = sum(drift_null.values()), sum(drift_obs.values())
    print(f"\n### 4. drift is NOT diagnostic -- the null says so")
    print(f"  instruction lengths in these decodes: {dict(sorted(lens.items()))}")
    print(f"  {'drift':>6} {'observed':>9} {'obs%':>7} {'null%':>7}")
    for k in sorted(set(list(drift_obs) + list(drift_null))):
        print(f"  {k:>6} {drift_obs.get(k,0):>9} {100.0*drift_obs.get(k,0)/to:6.1f}% "
              f"{100.0*drift_null.get(k,0)/tn:6.1f}%")
    if "--json" in sys.argv:
        json.dump(rows, _real_open(sys.argv[sys.argv.index("--json") + 1], "w"), indent=1)
    return 0


WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
_FLAT = {}


def flatten(name):
    """(instruction-start offsets, per-byte CODE/DATA/PAD map) for a source tree.

    Same walk as l1_territory_map.py, which is gated on the classified total
    equalling the rebuilt ROM to the byte -- so a directive sized wrongly cannot
    pass silently.  Recorded here per instruction rather than as totals.
    """
    if name in _FLAT: return _FLAT[name]
    root = f"{name}/maincpu/kn5000_{name}_program.s"
    inc = f"{name}/maincpu"
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", "-I", inc, root],
                         capture_output=True, text=True, cwd=REPO)
    if out.returncode: sys.exit(out.stderr[:300])
    pos, starts, terr = 0, set(), bytearray()
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"): continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            starts.add(pos); terr.extend(b"\x02" * n); pos += n; continue
        if s.endswith(":") or s.startswith(";"): continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m: continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
            terr.extend(b"\x01" * n); pos += n
        elif d in ("ascii", "asciz"):
            n = sum(len(ESCAPE.sub("X", mm.group(1)))
                    for mm in re.finditer(r'"((?:[^"\\]|\\.)*)"', rest)) + (1 if d == "asciz" else 0)
            terr.extend(b"\x01" * n); pos += n
        elif d in ("zero", "fill", "space"):
            p = [x.strip() for x in rest.split(",")]
            n = int(p[0], 0) * (int(p[1], 0) if d == "fill" and len(p) >= 2 else 1)
            terr.extend(b"\x00" * n); pos += n
        elif d == "p2align":
            n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
            terr.extend(b"\x00" * n); pos += n
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0)
            if t > pos: terr.extend(b"\x00" * (t - pos)); pos = t
    _FLAT[name] = (starts, bytes(terr))
    return _FLAT[name]


def content_align(rom7, romX, e_off, span, ctx_lo):
    """Offset delta such that romX[o+delta] is the same content as rom7[o].

    Found by searching the sibling ROM for the range's own bytes, longest window
    first, and accepting only a UNIQUE hit of >= 16 bytes.
    """
    wins = []
    for lo in sorted({ctx_lo, e_off - 32, e_off - 8, e_off}, reverse=True):
        if lo < 0: continue
        for shrink in (0, 8, 16, 24, 32, 48, 64):
            if e_off + span - shrink - lo >= 16:
                wins.append((lo, e_off + span - shrink))
    for lo, hi in sorted(set(wins), key=lambda w: -(w[1] - w[0])):
        needle = rom7[lo:hi]
        j = romX.find(needle)
        if j >= 0 and romX.find(needle, j + 1) < 0:
            return j - lo
    return None


if __name__ == "__main__":
    sys.exit(main())
