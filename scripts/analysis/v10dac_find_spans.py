#!/usr/bin/env python3
"""v10dac_find_spans.py -- Locate candidate data-as-code spans in v10 by text anchor over the cached instruction stream.

RUN
    python3 scripts/analysis/v10dac_find_spans.py

⚠ A clean decode is NOT proof the bytes are code, and the byte-identity gate
  cannot help: re-assembling a wrong interpretation reproduces the same bytes.
  Corroborate with call targets landing on routines already named in the tree.

⚠ `--show-encoding`'s `encoding:` field is NOT reliably the bytes the
  disassembler consumed -- it can be a re-encode, shorter than the true
  consumed length. Summing shown-encoding lengths silently desyncs and then
  fabricates a PARTIAL DECODE for everything downstream; that produced a
  phantom 407-byte "decoder gap" which was retracted on 2026-09-02. Verify per
  instruction against the true byte slice.

PROVENANCE
  Lane V10DAC of the 2026-09-02 push; recovered from session scratch,
  which is volatile, before it was lost.
"""
import pickle, re, sys, os, bisect, glob, json, collections

REPO = os.path.expanduser("~/compartilhado/disasm-lanes/v10dac")
CACHE = os.path.join(REPO, "notes/v10-data-as-code/cache.pkl")
SRC_ROOT = os.path.join(REPO, "v10/maincpu")

d = pickle.load(open(CACHE, "rb"))
terr = d["terr"]; reached = d["reached"]

def candidates(minsize=1):
    regs, i = [], 0
    SIZE = len(terr)
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

def byte_metrics(blob):
    per = 0.0
    for p in range(2, 33):
        if len(blob) > p:
            per = max(per, sum(1 for i in range(p, len(blob)) if blob[i]==blob[i-p]) / (len(blob)-p))
    return dict(per=100.0*per, dist=len(set(blob)))

TIGHT_DIST, TIGHT_PER = 15, 60.0
rom = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()

regs = candidates(minsize=16)
strict = []
for a,b in regs:
    m = byte_metrics(rom[a:b])
    if m["dist"] <= TIGHT_DIST and m["per"] >= TIGHT_PER:
        strict.append((a,b))
strict.sort(key=lambda x: -(x[1]-x[0]))
print(f"{len(strict)} strict spans, {sum(b-a for a,b in strict):,} B", file=sys.stderr)

instr = sorted(d["instr"])
starts = [x[0] for x in instr]

def entries_for(a,b):
    i = bisect.bisect_left(starts, a)
    out = []
    off = a
    while off < b:
        if i >= len(instr) or instr[i][0] != off:
            return None
        out.append(instr[i])
        off += instr[i][1]
        i += 1
    if off != b:
        return None
    return out

def preceding_entries(a, k):
    i = bisect.bisect_left(starts, a)
    lo = max(0, i-k)
    return instr[lo:i]

WS = re.compile(r'\s+')
TOKRE = re.compile(r'0[xX][0-9a-fA-F]+|-?\d+|[A-Za-z_][A-Za-z0-9_]*|\S')
def tokenize(text):
    code = text.split(";",1)[0]
    return TOKRE.findall(code)

def tok_key(tok):
    if re.fullmatch(r'-?\d+', tok):
        return ('#', int(tok))
    if re.fullmatch(r'-?0[xX][0-9a-fA-F]+', tok):
        return ('#', int(tok, 16))
    return ('s', tok.lower())

def line_key_seq(line):
    return tuple(tok_key(t) for t in tokenize(line))

def is_code_line(s):
    code = s.split(";",1)[0].strip()
    if not code:
        return False
    if re.match(r'^[A-Za-z_][A-Za-z0-9_]*:\s*$', code):
        return False
    return True

print("indexing source tree...", file=sys.stderr)
all_s_files = sorted(glob.glob(os.path.join(SRC_ROOT, "**/*.s"), recursive=True))
file_lines = {}
file_codeidx = {}
file_keys = {}
mnem_index = collections.defaultdict(list)

for fn in all_s_files:
    try:
        lines = open(fn, encoding="utf-8", errors="surrogateescape").read().split("\n")
    except Exception:
        continue
    file_lines[fn] = lines
    cidx = [i for i,l in enumerate(lines) if is_code_line(l)]
    keys = [line_key_seq(lines[i]) for i in cidx]
    file_codeidx[fn] = cidx
    file_keys[fn] = keys
    for pos, k in enumerate(keys):
        if k:
            mnem_index[k[0]].append((fn, pos))

print(f"indexed {len(all_s_files)} files, {sum(len(v) for v in file_codeidx.values()):,} code lines", file=sys.stderr)

def entry_key_seq(text):
    return line_key_seq(text)

def try_match(target_keys, ctx_len):
    """target_keys: list of key-seqs (one per source LINE, already tokenized).
    Returns list of (fn, pos_of_span_start_in_codeidx) for unique candidate,
    matching the WHOLE target_keys sequence contiguously in code-line order,
    with the span itself starting at index ctx_len of target_keys."""
    first = target_keys[0][0]
    cands = mnem_index.get(first, [])
    matches = []
    for fn,pos in cands:
        keys = file_keys[fn]
        if pos+len(target_keys) > len(keys):
            continue
        ok = True
        for k in range(len(target_keys)):
            if keys[pos+k] != target_keys[k]:
                ok = False; break
        if ok:
            matches.append((fn,pos))
    return matches

def locate(a, b, entries):
    n = min(12, len(entries))
    target = [entry_key_seq(t) for _,_,t in entries[:n]]
    matches = try_match(target, 0)
    if len(matches) == 1:
        fn,pos = matches[0]
    else:
        # try with preceding context, growing until unique or give up
        found = None
        for k in (2,4,6,8):
            ctx = preceding_entries(a, k)
            if len(ctx) < k:
                continue
            ctx_keys = [entry_key_seq(t) for _,_,t in ctx]
            full = ctx_keys + target
            m = try_match(full, len(ctx_keys))
            if len(m) == 1:
                found = (m[0][0], m[0][1] + len(ctx_keys))
                break
            if len(m) == 0:
                continue
        if found is None:
            return None, f"{len(matches)} matches (no unique context)"
        fn,pos = found
    cidx = file_codeidx[fn]
    keys = file_keys[fn]
    if pos + len(entries) > len(cidx):
        return None, "window exceeds file"
    for k,(off,ln,text) in enumerate(entries):
        if keys[pos+k] != entry_key_seq(text):
            return None, f"entry {k} mismatch at extension"
    l0 = cidx[pos]
    l1 = cidx[pos+len(entries)-1]
    if l1 - l0 > len(entries)*3:
        return None, "too sparse"
    return (fn, l0, l1), None

results = []
for a,b in strict:
    entries = entries_for(a,b)
    if entries is None:
        results.append((a,b,None,"misaligned")); continue
    loc, err = locate(a,b,entries)
    results.append((a,b,loc,err))

ok = [r for r in results if r[3] is None]
bad = [r for r in results if r[3] is not None]
print(f"LOCATED: {len(ok)} / {len(results)}  bytes {sum(b-a for a,b,_,_ in ok):,}", file=sys.stderr)
reasons = collections.Counter(re.sub(r'\d+', 'N', r[3]) for r in bad)
for reason,cnt in reasons.most_common(30):
    print(f"  {cnt:4d}  {reason}", file=sys.stderr)

# check for overlapping edit ranges across different spans (would be unsafe to apply blindly)
byfile = collections.defaultdict(list)
for a,b,loc,err in ok:
    fn,l0,l1 = loc
    byfile[fn].append((l0,l1,a,b))
overlap_flag = set()
for fn,ranges in byfile.items():
    ranges.sort()
    for i in range(1,len(ranges)):
        if ranges[i][0] <= ranges[i-1][1]:
            overlap_flag.add((fn,ranges[i-1]))
            overlap_flag.add((fn,ranges[i]))
print(f"overlapping line-range conflicts: {len(overlap_flag)}", file=sys.stderr)

out = []
for a,b,loc,err in results:
    out.append(dict(a=a,b=b,file=loc[0] if loc else None, l0=loc[1] if loc else None,
                     l1=loc[2] if loc else None, err=err))
json.dump(out, open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/span_plan.json","w"), indent=1)
print("wrote span_plan.json", file=sys.stderr)
