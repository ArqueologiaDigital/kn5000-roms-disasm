#!/usr/bin/env python3
"""What do the `djnz` and `ld (r+),r` rules actually UNBLOCK?

QUESTION IT ANSWERS
    convert_reachable_ranges.py accepts a range only if EVERY instruction in it
    can be spelled to match its ROM bytes.  Adding the two rules proposed in
    README-djnz_and_dpi.md changes that set.  By how much -- ranges, bytes,
    bytes no longer lost to truncation -- and which forms block next?

HOW
    Replays the converter's OWN accept loop (decode_range -> resolve_branches ->
    translate/canonical -> byte compare) twice over the same decodes: once
    unmodified, once with the two rules monkey-patched in AT RUNTIME.  Nothing
    under scripts/converters/ is edited; the patched functions live here.

    ⚠ This measures ACCEPTANCE, which is the converter's front half.  It does
    NOT predict how many of those ranges the apply loop can actually place --
    that depends on .byte/.incbin placement and is reported by --apply itself.

RUN
    python3 tools/spelling-probes/measure_djnz_dpi_gain.py
"""
import importlib.util, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)
BASE = 0xE00000

spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
cc = crr.cc

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verify_djnz_and_dpi as V

rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(sp); sp.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addr2name = dict(syms)

# ------------------------------------------------------------- the two rules
DJNZ_RE = re.compile(r'^djnz\s+([A-Za-z]{1,3})\s*,\s*0x([0-9a-fA-F]+)$', re.I)
DPI_RE = re.compile(r'^ld\s+\(X[A-Z]{2}\+\),[A-Z]{1,3}$')


def patched_resolve_branches(insns, t, span, addr2name):
    """crr.resolve_branches + `djnz`.

    djnz is PC-relative exactly as jr is, so it must be named symbolically:
    written numerically llvm-mc takes the LOW BYTE of the address as the
    displacement (proved wrong at all 7 sites by verify_djnz_and_dpi.py).
    The mnemonic must also carry the OPERAND WIDTH -- `djnz` alone takes a
    32-bit GPR, so a 16-bit register needs `djnz16` and an 8-bit one `djnz8`.
    """
    addrs = {a for a, _n, _x in insns}
    needed, texts = {}, []
    for a, n, x in insns:
        s = x.strip()
        m = crr.BRANCH_RE.match(s)
        d = DJNZ_RE.match(s)
        if not m and not d:
            texts.append(None); continue
        if m:
            mn, cc_, tgt = m.group(1).lower(), m.group(2), int(m.group(3), 16)
        else:
            reg = d.group(1).upper()
            mn = "djnz8" if reg in V.R8 else ("djnz16" if reg in V.R16 else "djnz")
            cc_, tgt = reg, int(d.group(2), 16)
        if t <= tgt < t + span:
            if tgt not in addrs:
                return None
            needed[tgt] = f".Lc_{tgt:06x}"
            name = needed[tgt]
        elif tgt in addr2name:
            name = addr2name[tgt]
        else:
            return None
        texts.append(f"{mn} {cc_.lower()}, {name}" if cc_ else f"{mn} {name}")
    return texts, needed


_orig_translate = cc.translate


def patched_translate(text):
    yield from _orig_translate(text)
    if DPI_RE.match(text.strip()):
        yield from V.dpi_spellings(text.strip())


# ------------------------------------------------------------------ the loop
def run(resolve, translate, label):
    ok = skipped = total = trunc = 0
    why, forms = {}, {}
    for t in sorted(targets):
        insns = DECODES[t]
        if len(insns) < 3:
            skipped += 1; why["<3 insns"] = why.get("<3 insns", 0) + 1; continue
        span = sum(n for _, n, _ in insns)
        want = rom[t - BASE: t - BASE + span]
        _off, _run = t - BASE, 0
        while _off + _run < len(terr) and terr[_off + _run] == 2:
            _run += 1
        ends_at_code = span == _run
        _last = insns[-1][2].strip()
        if (_last.split()[0].lower() not in crr.TERMINATORS
                and not crr.UNCOND_JUMP.match(_last) and not ends_at_code):
            skipped += 1; why["no ret / code boundary"] = why.get("no ret / code boundary", 0) + 1
            continue
        br = resolve(insns, t, span, addr2name)
        if br is None:
            skipped += 1; why["branch target unnameable"] = why.get("branch target unnameable", 0) + 1
            continue
        br_texts, br_labels = br
        full_span = span
        texts, pos, bad = [], 0, False
        for bi, (_a, n, x) in enumerate(insns):
            tgtb = want[pos:pos + n]
            if br_texts[bi] is not None:
                e = cc.encode(br_texts[bi])
                if e is None or len(e) != n:
                    bad = True; break
                texts.append(br_texts[bi]); pos += n; continue
            chosen = None
            for cand in list(translate(x)) + [cc.canonical(x)]:
                if cc.encode(cand) == tgtb:
                    chosen = cand; break
            if chosen is None:
                bad = True
                mn = x.split()[0]
                rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
                k = mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                      re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))
                forms[k] = forms.get(k, 0) + 1
                break
            texts.append(chosen); pos += n
        if bad:
            kept = len(texts)
            if kept < 3:
                skipped += 1; why["unspellable insn"] = why.get("unspellable insn", 0) + 1
                continue
            insns2 = insns[:kept]
            span = sum(n for _, n, _ in insns2)
            end = t + span
            br_labels = {a: l for a, l in br_labels.items() if t <= a < end}
            live = set(br_labels.values())
            if any(bt and ".Lc_" in bt and bt.rsplit(None, 1)[-1] not in live
                   for bt in br_texts[:kept]):
                skipped += 1; why["truncation orphans a label"] = why.get("truncation orphans a label", 0) + 1
                continue
            trunc += full_span - span
            why["truncated"] = why.get("truncated", 0) + 1
        if crr.implausible(texts):
            skipped += 1; why["reads as table data"] = why.get("reads as table data", 0) + 1
            continue
        ok += 1; total += span
    print(f"--- {label}")
    print(f"    accepted {ok} range(s), {total:,} bytes; "
          f"{trunc:,} bytes lost to truncation; {skipped} skipped")
    for r, n in sorted(why.items(), key=lambda kv: -kv[1]):
        print(f"        {n:5}  {r}")
    return ok, total, trunc, forms


print("decoding 687 call targets once ...")
DECODES = {t: crr.decode_range(rom, terr, t) for t in sorted(targets)}

a = run(crr.resolve_branches, cc.translate, "BASELINE (converter as committed)")
b = run(patched_resolve_branches, patched_translate, "WITH djnz + ld (r+),r rules")
print(f"\ndelta: {b[0] - a[0]:+d} range(s), {b[1] - a[1]:+,} bytes, "
      f"{b[2] - a[2]:+,} bytes of truncation")
print("\ntop blocking forms AFTER the two rules:")
for k, v in sorted(b[3].items(), key=lambda kv: -kv[1])[:12]:
    print(f"  {v:4}  {k}")
