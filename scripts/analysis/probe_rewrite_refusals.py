#!/usr/bin/env python3
"""Which of convert_reachable_ranges.py's refusals could EVER be accepted?

THE QUESTION.  The converter's rewrite stage prints a refusal tally under
`--apply`.  Three of its buckets stopped moving across six closure rounds:

    refused  23  range extends past its blocks
    refused   6  replaced span holds a non-.byte, non-label line
    refused   1  touched blocks do not tile contiguously

A stalled bucket has two very different explanations and the tally cannot tell
them apart: the ranges are genuinely unconvertible, or the check is one they can
never pass however correct they are.  That distinction already cost 18,412 bytes
once -- anti-pattern 12 in docs/DISASSEMBLY-COMPLETENESS-SPEC.md, where the
whole-block re-check gated on "no local labels" when it meant "no branches", so
every range branching to an external symbol was byte-compared against a
link-time placeholder and could not pass.  So: dump the ACTUAL ranges in each
bucket and look at them.

WHAT THIS DOES.  It runs the real converter through the real `--apply` code
path, so every bucket assignment is the converter's own, not a
re-implementation that might disagree.  Three things are added:

  * every write into the repo is intercepted and DISCARDED (self-tested at
    startup), so the run cannot change a source file.  Writes outside the repo
    -- the converter's private unidasm scratch dir -- go through untouched,
    because the decode depends on them;
  * `rewrite()` is wrapped: before each call the probe records the range and the
    blocks and lines it would touch, and after the call it reads which REFUSED
    counter moved;
  * a SECOND pass runs the converter again with a synthetic block index that
    covers the whole ROM, so that every range the converter accepted reaches the
    wrapper.  That is what makes the accounting exact: comparing the two passes
    shows how many accepted ranges never reach rewrite() at all in the real run,
    a loss no counter reports.

WHAT IT PRINTS.
  1. reconciliation: of the N ranges the converter says decode and re-assemble
     cleanly, how many are applied, how many land in each refusal bucket, and
     how many disappear silently -- in RANGES and in BYTES;
  2. every refused range with its concrete cause: the offending source line, the
     gap between two blocks, or the bytes past the last indexed block together
     with the `.byte` run that really holds them and why that run has no
     address;
  3. a census of `.byte` runs the block index cannot address at all;
  4. the silent label check: whether the labels that block a range are
     instruction boundaries under any framing, and whether anything in the tree
     references them;
  5. what an address-by-arithmetic fix would recover;
  6. where the ranges that never reach rewrite() actually live (`.incbin` ROM
     slices vs unaddressed `.byte` runs).

Every byte counted here is PROVEN CODE: a range only reaches rewrite() after it
decoded from a call target, ended at a `ret` or at a code boundary, and had
every instruction re-assembled to the ROM bytes.  These refusals are about
SOURCE LAYOUT, not about whether the bytes are instructions.

REQUIRES  rebuilt_ROMs/kn5000_v7_program.llvm.elf (a completed `make all`); the
converter reads block addresses from it.  Takes about two minutes.

Run:  python3 scripts/analysis/probe_rewrite_refusals.py [--json OUT.json]
      (extra args are forwarded to the converter, e.g. --limit 40)

⚠ Do not run this while a closure round is writing v7/ -- it cannot corrupt the
tree, but it would be reading a moving target.  Copy the tree and run it there.
"""
import contextlib, glob, importlib.util, io, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
BASE = 0xE00000
ROMSIZE = 0x200000
TERMINATORS = ("ret", "reti", "retd")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


# ---------------------------------------------------------------- write guard
_real_open = open
SUPPRESSED = []


class _Sink:
    """Swallows a write. Returned instead of a file handle for any repo path."""

    def __init__(self, path):
        self.path = path

    def write(self, data):
        SUPPRESSED.append((self.path, len(data)))
        return len(data)

    def close(self):
        pass

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


def guarded_open(path, mode="r", *a, **kw):
    if any(c in mode for c in "wax+"):
        p = os.path.abspath(str(path))
        if p.startswith(os.path.abspath(REPO) + os.sep):
            return _Sink(p)                       # a repo write: discard it
    return _real_open(path, mode, *a, **kw)       # scratch write / read: real


class Tee(io.TextIOBase):
    def __init__(self, *streams):
        self.streams = streams

    def write(self, s):
        for st in self.streams:
            st.write(s)
        return len(s)

    def flush(self):
        for st in self.streams:
            st.flush()


# ------------------------------------------------------------ source scanning
def raw_byte_runs(lines):
    """EVERY `.byte` run in a file, including those blocks_of() discards.

    Mirrors convert_corroborated_blocks.blocks_of()'s label rules (a label stops
    applying at the first non-.byte, non-comment line) but KEEPS runs with no
    label and runs holding a symbolic `.byte` -- precisely the runs that become
    address holes.  Returns (label, first_line, last_line, values), value None
    for a symbolic byte.
    """
    runs, cur, start, label = [], [], None, None
    for i, ln in enumerate(lines):
        m = re.match(r'^\s*\.byte\s+(.*)$', ln)
        if m:
            if start is None:
                start = i
            body = re.split(r'[;#]', m.group(1))[0]
            for tok in body.split(","):
                tok = tok.strip()
                if not tok:
                    continue
                try:
                    cur.append(int(tok, 0))
                except ValueError:
                    cur.append(None)
            continue
        if cur:
            runs.append((label, start, i - 1, cur))
            cur, start, label = [], None, None
        lm = re.match(r'^([A-Za-z_][\w]*):', ln)
        if lm:
            label = lm.group(1)
        elif ln.strip() and not ln.lstrip().startswith((';', '#')):
            label = None
    if cur:
        runs.append((label, start, len(lines) - 1, cur))
    return runs


def why_no_address(label, values, name2addr):
    if any(v is None for v in values):
        return "symbolic .byte -- blocks_of() discards the whole run"
    if label is None:
        return "NO LABEL (run follows instructions or a blank line) -- no address"
    if label not in name2addr:
        return f"label {label} is not a .text symbol in the ELF"
    return f"label {label} -> 0x{name2addr[label]:06X}"


def locate_in_rom(vals, rom, lo=None, hi=None):
    """Where do these bytes live in the ROM? Unique hit, or ambiguous."""
    if not vals or any(v is None for v in vals):
        return None
    blob = bytes(v & 0xFF for v in vals)
    hits, i = [], rom.find(blob)
    while i >= 0 and len(hits) < 9:
        hits.append(BASE + i)
        i = rom.find(blob, i + 1)
    if len(hits) == 1:
        return {"addr": hits[0], "how": "unique in the ROM"}
    inside = [h for h in hits if (lo is None or h >= lo) and (hi is None or h < hi)]
    if len(inside) == 1:
        return {"addr": inside[0], "how": f"unique between its neighbours "
                                          f"({len(hits)} hits ROM-wide)"}
    return {"addr": None, "how": f"{len(hits)} hits, {len(inside)} between neighbours"}


def unidasm_boundaries(rom, start, nbytes, scratch):
    """Instruction start addresses when the SAME bytes are framed at `start`.

    A mis-framed decode still reproduces the ROM bytes exactly -- the assembler
    writes back whatever it is handed -- so the byte-match gate is blind to it.
    The only local evidence about framing is whether the labels the sources
    already define land on instruction boundaries, so this re-frames the bytes
    from a different start and asks the same question again.
    """
    tmp = os.path.join(scratch, "_frame.bin")
    _real_open(tmp, "wb").write(rom[start - BASE: start - BASE + nbytes])
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(start)],
                         capture_output=True, text=True, timeout=120).stdout
    bounds = []
    for line in out.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if not m:
            continue
        if m.group(3).strip().split()[0].lower() == "db":
            break
        bounds.append(int(m.group(1), 16))
    return bounds


def address_runs_by_arithmetic(lines, blocks, rom):
    """Give a `.byte` run an address without needing a label of its own.

    THE FIX THIS MEASURES.  blocks_of() can only address a run preceded by a
    label the ELF knows, and it deliberately stops a label carrying across an
    intervening line -- which is right, because bytes after an instruction do
    not live at the label's address.  But when only BLANK or COMMENT lines
    separate one run from the next, the next run's address is simply the
    previous run's end: those lines emit nothing.  Every address derived that
    way is then checked against the ROM, the same check source_index() already
    applies to labelled blocks, so a wrong guess cannot survive.

    Returns (label, first_line, last_line, addr, nbytes, source), source being
    "label" for runs the block index already places.
    """
    indexed = {bk[2]: bk for bk in blocks}
    out, cursor, prev_end_line = [], None, None
    for (lb, s, e, vals) in raw_byte_runs(lines):
        if s in indexed:
            bk = indexed[s]
            cursor, prev_end_line = bk[1] + len(bk[4]), e
            out.append((lb, s, e, bk[1], len(bk[4]), "label"))
            continue
        if any(v is None for v in vals):
            cursor, prev_end_line = None, e
            continue
        gap_ok = cursor is not None and prev_end_line is not None and all(
            (not ln.strip()) or ln.lstrip().startswith((';', '#'))
            for ln in lines[prev_end_line + 1:s])
        if gap_ok:
            blob = bytes(v & 0xFF for v in vals)
            if rom[cursor - BASE: cursor - BASE + len(blob)] == blob:
                out.append((lb, s, e, cursor, len(blob), "arithmetic"))
                cursor, prev_end_line = cursor + len(blob), e
                continue
        cursor, prev_end_line = None, e       # lost the thread; wait for a label
    return out


def incbin_regions(files, rom):
    """Address and size of every `.incbin` ROM slice, located BY ITS CONTENT.

    An .incbin's address cannot be read off the source line, but the file's
    bytes are in the ROM: a slice that occurs exactly once is placed beyond
    doubt.  Used to say what the ranges that never reach rewrite() are sitting
    inside.
    """
    regions, ambiguous, seen = [], [], set()
    for f in files:
        for ln in _real_open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^\s*\.incbin\s+"([^"]+)"', ln)
            if not m:
                continue
            # the assembler is run with -I v7/maincpu, so a path resolves either
            # against the including file or against that include root
            cands = [os.path.join(os.path.dirname(f), m.group(1)),
                     os.path.join(REPO, "v7/maincpu", m.group(1))]
            p = next((c for c in cands if os.path.exists(c)), None)
            if p is None or p in seen:
                continue
            seen.add(p)
            blob = _real_open(p, "rb").read()
            if not blob:
                continue
            hits, i = [], rom.find(blob)
            while i >= 0 and len(hits) < 3:
                hits.append(i)
                i = rom.find(blob, i + 1)
            if len(hits) == 1:
                regions.append((BASE + hits[0], len(blob), p))
            else:
                ambiguous.append((p, len(blob), len(hits)))
    return regions, ambiguous, len(seen)


# --------------------------------------------------------------------- driver
def run_converter(conv, extra, rewrite_hook, fake_index=False, quiet=False):
    """One full `--apply` run of the real converter, writes discarded.

    fake_index=True replaces the block index with a single block covering the
    whole ROM, so that EVERY range the converter accepts is handed to the hook.
    That is the only way to enumerate the ranges the real run drops before
    rewrite() without re-implementing its gates.
    """
    mod = load("crr_" + ("fake" if fake_index else "real"), conv)
    mod.open = guarded_open                 # module globals shadow the builtin
    mod.cc.open = guarded_open
    state = {"decodes": {}}
    real_index, real_decode = mod.source_index, mod.decode_range

    def w_index(s):
        if fake_index:
            idx = {"<whole ROM>": (["<none>"],
                                   [(None, BASE, 0, 0, b"\x00" * ROMSIZE)])}
        else:
            idx = real_index(s)
        state["idx"] = idx
        return idx

    def w_decode(r, terr, start, limit=16384):
        state["terr"] = terr
        insns = real_decode(r, terr, start, limit)
        state["decodes"][start] = insns
        return insns

    mod.source_index, mod.decode_range = w_index, w_decode
    # Keep THIS module instance's own rewrite: it writes REFUSED in its own
    # globals, and a copy borrowed from another instance would update the wrong
    # counters, making every refusal look like a silent one.
    mod._orig_rewrite = mod.rewrite
    mod.rewrite = lambda *a, **k: rewrite_hook(mod, *a, **k)
    cap = io.StringIO()
    sys.argv = [conv, "--apply"] + extra
    sink = io.StringIO() if quiet else sys.stdout
    with contextlib.redirect_stdout(Tee(sink, cap)):
        mod.main()
    state["log"] = cap.getvalue()
    state["mod"] = mod
    return state


def main():
    jsonout = sys.argv[sys.argv.index("--json") + 1] if "--json" in sys.argv else None
    # The guard is the only thing between this probe and the tree it measures,
    # so prove it works before using it, not after.
    _t = os.path.join(REPO, ".probe-write-guard-selftest")
    _h = guarded_open(_t, "wb")
    _h.write(b"x")
    assert isinstance(_h, _Sink) and not os.path.exists(_t), "WRITE GUARD IS NOT WORKING"
    print("write guard self-test: a repo write returns a sink and creates no file -- ok")

    conv = os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py")
    rom = _real_open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    extra = [a for a in sys.argv[1:] if a not in ("--json", jsonout)]

    cases = []
    name2addr = {}

    def snapshot(idx, t, span, insns, addr2name):
        (path, (lines, blocks)), = idx.items()
        touched = sorted([bk for bk in blocks
                          if bk[1] < t + span and bk[1] + len(bk[4]) > t],
                         key=lambda bk: bk[2])
        d = {"entry": t, "span": span, "insns": len(insns), "name": addr2name.get(t, ""),
             "file": os.path.relpath(path, REPO) if os.path.isabs(path) else path,
             "last_insn": insns[-1][2] if insns else "",
             "blocks": [{"label": bk[0], "addr": bk[1], "len": len(bk[4]),
                         "lines": [bk[2] + 1, bk[3] + 1]} for bk in touched]}
        if not touched:
            return d
        first, last = touched[0], touched[-1]
        last_end = last[1] + len(last[4])
        d["lead"], d["tail"] = t - first[1], last_end - (t + span)
        d["gaps"] = [{"after": touched[i][1] + len(touched[i][4]), "next": touched[i + 1][1]}
                     for i in range(len(touched) - 1)
                     if touched[i][1] + len(touched[i][4]) != touched[i + 1][1]]
        d["odd_lines"] = [{"n": first[2] + 1 + k, "text": ln}
                          for k, ln in enumerate(lines[first[2]:last[3] + 1])
                          if not re.match(r'^\s*\.byte\s', ln)
                          and not re.match(r'^[A-Za-z_][\w]*:', ln)]
        insn_addrs = {a for a, _n, _x in insns}
        d["labels_off_instruction"] = [
            {"label": bk[0], "addr": bk[1]} for bk in touched
            if bk[0] and bk[1] != first[1] and t <= bk[1] < t + span
            and bk[1] not in insn_addrs]
        if d["tail"] < 0:                  # what really holds the bytes past the end?
            need = rom[last_end - BASE: t + span - BASE]
            d["hole"] = {"from": last_end, "bytes": len(need),
                         "rom": " ".join(f"{b:02x}" for b in need[:16])}
            for (lb, s, e, vals) in raw_byte_runs(lines):
                if s > last[3]:
                    got = bytes(v & 0xFF for v in vals if v is not None)
                    d["hole"]["run"] = {
                        "label": lb, "lines": [s + 1, e + 1], "len": len(vals),
                        "matches_rom": bool(got) and got[:len(need)] == need[:len(got)],
                        "why": why_no_address(lb, vals, name2addr),
                        "where": locate_in_rom(vals, rom)}
                    break
        return d

    def hook(mod, idx, t, span, insns, texts, addr2name, branch_labels=None):
        pre = snapshot(idx, t, span, insns, addr2name)
        before = dict(mod.REFUSED)
        res = mod._orig_rewrite(idx, t, span, insns, texts, addr2name, branch_labels)
        moved = [k for k, v in mod.REFUSED.items() if v != before.get(k, 0)]
        pre["bucket"] = moved[0] if moved else (
            "APPLIED" if res else "SILENT: rewrite returned None with no counter")
        cases.append(pre)
        return res

    # symbol table first: the per-range diagnosis needs it during pass 1
    cc = load("cc_probe", os.path.join(REPO, "scripts/converters/"
                                             "convert_corroborated_blocks.py"))
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    name2addr.update({n: a for a, n in syms.items()})

    # -- pass 1: the real run --------------------------------------------
    st = run_converter(conv, extra, hook)
    log, idx, terr = st["log"], st["idx"], st["terr"]
    scratch = st["mod"]._SCRATCH

    # -- pass 2: same run, synthetic whole-ROM index ----------------------
    pending = []

    def hook2(mod, idx2, t, span, insns, texts, addr2name, branch_labels=None):
        pending.append((t, span))
        return None

    print("\n[second pass: same converter, synthetic whole-ROM block index, "
          "to enumerate\n every range it accepts -- output suppressed]")
    run_converter(conv, extra, hook2, fake_index=True, quiet=True)

    print("\n" + "=" * 78)
    print(f"repo writes intercepted and discarded: {len(SUPPRESSED)} "
          f"({len({p for p, _ in SUPPRESSED})} distinct file(s))")
    for _p in sorted({p for p, _ in SUPPRESSED}):
        print(f"    would have been written: {os.path.relpath(_p, REPO)}")

    m = re.search(r'^(\d+) ranges decode to a clean .ret. and re-assemble exactly, '
                  r'([\d,]+) bytes', log, re.M)
    ok_n, ok_b = (int(m.group(1)), int(m.group(2).replace(",", ""))) if m else (0, 0)
    buckets = {}
    for c in cases:
        buckets.setdefault(c["bucket"], []).append(c)
    reached = {c["entry"] for c in cases}
    never = [(t, s) for t, s in pending if t not in reached]

    # ---- 1. reconciliation ----------------------------------------------
    print("\n### 1. where do the accepted ranges go?   (unit: ranges / bytes of ROM)")
    print(f"the converter accepted {ok_n} range(s), {ok_b:,} bytes. Every one decoded from")
    print("a call target and every instruction was re-assembled to the ROM bytes. Of those:")
    rows = [(b, len(cs), sum(c["span"] for c in cs)) for b, cs in buckets.items()]
    rows.append(("NEVER REACHED rewrite() -- entry in no indexed block, NO COUNTER",
                 len(never), sum(s for _t, s in never)))
    for b, n, by in sorted(rows, key=lambda r: -r[2]):
        print(f"   {n:5} range(s)  {by:7,} bytes   {b}")
    print(f"   {'-' * 70}\n   {sum(r[1] for r in rows):5} range(s)  "
          f"{sum(r[2] for r in rows):7,} bytes   total "
          f"(pass 2 enumerated {len(pending)} accepted range(s))")

    # ---- 2. per-bucket detail -------------------------------------------
    print("\n### 2. every refused range, with its cause")
    for b, cs in sorted(buckets.items(), key=lambda kv: -sum(c["span"] for c in kv[1])):
        union = set()
        for c in cs:
            union |= set(range(c["entry"], c["entry"] + c["span"]))
        print(f"\n--- {b}")
        print(f"    {len(cs)} range(s), {sum(c['span'] for c in cs):,} bytes summed, "
              f"{len(union):,} bytes as a union of ROM addresses")
        if b == "APPLIED":
            continue
        for c in sorted(cs, key=lambda c: -c["span"]):
            print(f"  0x{c['entry']:06X}  {c['span']:5} B  {c['insns']:3} insns  "
                  f"{c['file']}  {c['name']}")
            print(f"      lead {c.get('lead')}  tail {c.get('tail')}  "
                  f"blocks {len(c['blocks'])}  last insn: {c['last_insn']}")
            for bk in c["blocks"]:
                print(f"        block {bk['label'] or '(unlabelled)'} @0x{bk['addr']:06X} "
                      f"{bk['len']} B  lines {bk['lines'][0]}..{bk['lines'][1]}")
            for g in c.get("gaps", []):
                print(f"        GAP 0x{g['after']:06X}..0x{g['next']:06X} "
                      f"({g['next'] - g['after']} bytes held by no indexed block)")
            for o in c.get("odd_lines", [])[:6]:
                print(f"        NON-.byte LINE {o['n']}: {o['text'][:100]!r}")
            for lo in c.get("labels_off_instruction", []):
                print(f"        LABEL {lo['label']} @0x{lo['addr']:06X} is not on an "
                      f"instruction boundary")
            h = c.get("hole")
            if h:
                print(f"        HOLE from 0x{h['from']:06X}, {h['bytes']} bytes: {h['rom']}")
                r = h.get("run")
                if r:
                    print(f"          next .byte run, lines {r['lines'][0]}..{r['lines'][1]}, "
                          f"{r['len']} values, bytes match the ROM there: {r['matches_rom']}")
                    print(f"          it has no address because: {r['why']}")

    # ---- 3. census of unaddressable runs --------------------------------
    print("\n### 3. `.byte` runs the block index cannot address at all")
    files = sorted(glob.glob(os.path.join(REPO, "v7/maincpu/*/*.s"))
                   + glob.glob(os.path.join(REPO, "v7/maincpu/*.s")))
    tot_runs = tot_bytes = 0
    kinds = {}
    for f in files:
        lines = _real_open(f, "rb").read().decode("latin-1").split("\n")
        blocks = idx.get(f, (None, []))[1]
        indexed = {bk[2] for bk in blocks}
        for (lb, s, e, vals) in raw_byte_runs(lines):
            if s in indexed:
                continue
            tot_runs += 1
            tot_bytes += len(vals)
            why = why_no_address(lb, vals, name2addr)
            k = ("symbolic .byte" if "symbolic" in why else
                 "no label of its own" if "NO LABEL" in why else
                 "label not a .text symbol in the ELF" if "not a .text" in why else
                 "label resolves, but source_index() dropped the block (ROM mismatch)")
            kinds[k] = kinds.get(k, 0) + 1
    print(f"    {tot_runs} run(s), {tot_bytes:,} bytes have no address in the block index")
    for k, n in sorted(kinds.items(), key=lambda kv: -kv[1]):
        print(f"      {n:5}  {k}")

    # ---- 4. the silent label check --------------------------------------
    print("\n### 4. the silent label check: is the decode wrong, or the label?")
    print("    A label that is a call or branch target MUST be an instruction boundary.")
    print("    If the blocking labels are boundaries under NO framing and NOTHING in the")
    print("    tree references them, they are not code structure -- they are names left")
    print("    on mid-instruction addresses, and the check is refusing correct decodes.")
    silent = [c for c in cases if c["bucket"].startswith("SILENT")]
    names = {lo["label"] for c in silent for lo in c.get("labels_off_instruction", [])}
    refs = {n: 0 for n in names}
    if names:
        pat = re.compile(r'\b(' + "|".join(sorted(map(re.escape, names))) + r')\b')
        for f in files:
            for ln in _real_open(f, "rb").read().decode("latin-1").split("\n"):
                if re.match(r'^([A-Za-z_][\w]*):', ln):
                    continue                       # its own definition
                for mm in pat.finditer(ln):
                    refs[mm.group(1)] += 1
    explained = unreferenced = 0
    for c in silent:
        off = c.get("labels_off_instruction")
        if not off or not c["blocks"]:
            continue
        b0 = c["blocks"][0]
        bounds = set(unidasm_boundaries(rom, b0["addr"],
                                        (c["entry"] + c["span"]) - b0["addr"], scratch))
        hit = sum(1 for lo in off if lo["addr"] in bounds)
        nref = sum(refs.get(lo["label"], 0) for lo in off)
        explained += (hit == len(off))
        unreferenced += (nref == 0)
        print(f"  0x{c['entry']:06X} {c['span']:5} B  lead {c['lead']:4}  "
              f"{len(off)} blocking label(s), {hit} of which become instruction "
              f"boundaries when\n              the same bytes are framed at the block "
              f"start; {nref} reference(s) in v7/maincpu/*.s")
    print(f"    {explained}/{len(silent)} range(s) explained by a different framing; "
          f"{unreferenced}/{len(silent)} have blocking labels\n    that NOTHING in the tree "
          f"references (a .s definition line is not counted as a reference;\n    "
          f"transplant_manifest.txt is not a .s file and is not counted either)")

    # ---- 5. what an addressing fix would recover ------------------------
    print("\n### 5. what an address-by-arithmetic fix would recover")
    aug, gained_runs, gained_bytes = {}, 0, 0
    for f in files:
        lines = _real_open(f, "rb").read().decode("latin-1").split("\n")
        for (_lb, _s, _e, a, n, src) in address_runs_by_arithmetic(
                lines, idx.get(f, (None, []))[1], rom):
            aug.setdefault(a, n)
            if src == "arithmetic":
                gained_runs += 1
                gained_bytes += n
    print(f"    {gained_runs} run(s) / {gained_bytes:,} bytes gain a ROM-verified address "
          f"from\n    'previous run's end, blank or comment lines only in between' "
          f"(of {tot_runs} / {tot_bytes:,})")
    cov = bytearray(ROMSIZE)
    for a, n in aug.items():
        cov[a - BASE:a - BASE + n] = b"\x01" * n

    def covered(t, span):
        return all(cov[t - BASE + i] for i in range(span))
    per = [(b, [(c["entry"], c["span"]) for c in cs])
           for b, cs in buckets.items() if b != "APPLIED"]
    per.append(("NEVER REACHED rewrite()", never))
    print("    would the ranges then be TILED by addressed runs, per bucket?")
    for nm, rows2 in sorted(per, key=lambda r: -sum(s for _t, s in r[1])):
        okc = [(t, s) for t, s in rows2 if covered(t, s)]
        print(f"      {len(okc):3}/{len(rows2):3} range(s)  "
              f"{sum(s for _t, s in okc):6,}/{sum(s for _t, s in rows2):6,} bytes   {nm}")
    print("    ⚠ tiled is NECESSARY, not sufficient: a tiled range still has to pass the")
    print("      remaining checks, and the blank lines between the runs it now spans make")
    print("      it fail the non-.byte-line check, so that check has to be fixed with it.")

    # ---- 6. where do the never-placed ranges live? ----------------------
    print("\n### 6. the ranges that never reach rewrite(): what holds their bytes?")
    regions, ambiguous, nseen = incbin_regions(files, rom)
    inc = bytearray(ROMSIZE)
    for a, n, _p in regions:
        inc[a - BASE:a - BASE + n] = b"\x01" * n
    print(f"    {nseen} .incbin file(s) referenced; {len(regions)} placed uniquely by "
          f"content\n    ({sum(n for _a, n, _p in regions):,} bytes of ROM), "
          f"{len(ambiguous)} not uniquely placeable")
    inside = [(t, s) for t, s in never if inc[t - BASE]]
    whole = [(t, s) for t, s in never if all(inc[t - BASE + i] for i in range(s))]
    out = [(t, s) for t, s in never if not inc[t - BASE]]
    print(f"    entry inside an .incbin ROM slice: {len(inside)} range(s), "
          f"{sum(s for _t, s in inside):,} bytes "
          f"({len(whole)} of them lie wholly inside)")
    print(f"    entry elsewhere (unaddressed .byte run, or a dropped block): "
          f"{len(out)} range(s), {sum(s for _t, s in out):,} bytes")
    for t, s in sorted(never, key=lambda x: -x[1])[:14]:
        print(f"      0x{t:06X}  {s:5} B  {'in .incbin' if inc[t - BASE] else 'elsewhere':<10}"
              f"  {syms.get(t, '')}")

    if jsonout:
        _real_open(jsonout, "w").write(json.dumps(
            {"cases": cases, "ok_ranges": ok_n, "ok_bytes": ok_b,
             "pending": pending, "never_placed": never}, indent=1))
        print(f"\nwrote {jsonout}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
