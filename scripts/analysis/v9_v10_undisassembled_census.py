#!/usr/bin/env python3
"""Do v9 and v10 carry undisassembled CODE as .byte, the way v7 does?

v7_undisassembled_spans.py answered that for v7 by diffing v7's territory
against v9's.  That trick cannot be reused for v9 vs v10: MEASURED 2026-08-22,
their per-byte territory maps differ in 581 bytes out of 2,097,152 (285 where v9
is DATA and v10 CODE, 282 the other way).  v9 and v10 were disassembled in
lockstep, so they hide the SAME residue and cannot corroborate each other.

This script answers it directly instead, in three stages.

STAGE 1  --prepare
  Copies v7/ v9/ v10/ into a scratch dir, injects a `.globl` label pair around
  every literal `.byte` run and around every `.incbin`, assembles and links, and
  CHECKS THE REBUILT ROM IS BYTE-IDENTICAL to the original.  Labels emit no
  bytes, so that check is what makes the extracted addresses trustworthy.  The
  labels then give every blob an exact ROM address AND its source file:line --
  which the flattened -show-encoding stream alone cannot provide, because
  llvm-mc expands .include, .incbin and macros away.

STAGE 2  --census TAG
  Per-byte territory map (same rules as l1_territory_map.py) plus the marker
  map, so DATA can be split into
      .incbin        C-compiled structs, fonts, indexed images -- data by
                     construction, audited by audit_incbin_legitimacy.py
      literal .byte  what a human or a converter wrote out as raw bytes
      .ascii/.word/.hword literals
  and regions are taken as maximal runs of DATA that are NOT inside an .incbin,
  so that the 3-4 byte `.ascii` runs the converter emits for printable bytes do
  not split one undisassembled function into three.

STAGE 3  --judge TAG
  A CODE/DATA rule, CALIBRATED BEFORE USE on two controls (--calibrate):
      db%    <= 5     share of bytes unidasm cannot decode at all
      per%   <= 20    max over lags 2..32 of the fraction of bytes equal to the
                      byte that many earlier -- fixed-width records score high
      ramp%  <= 12    fraction of positions where b[i] == b[i-1]+1 -- index and
                      permutation tables score high (this criterion was ADDED
                      after 765 B of glyph-index table passed the other three)
      dist   >= min(60, 0.35*n)   distinct byte values
  Controls, on v9, size-matched to the regions being judged:
      CODE control (windows from long contiguous CODE runs):
          fires on 214/300 windows = 71.3%,  82.5% byte-weighted
      DATA control (windows from .incbin interiors):
          fires on   3/300 windows =  1.0%,   0.2% byte-weighted
  So the rule UNDER-reports code by roughly a fifth and almost never calls data
  code.  Treat its output as a floor.

MEASURED 2026-08-22, repo at 43be47d, llvm-mc 21.0.0git, MAME unidasm:

                                    v7            v9            v10
  CODE / DATA / PADDING         27.26%        47.83%        47.83%
  literal .byte, whole ROM     407,788 B      84,484 B      84,481 B
  .incbin                      968,006 B     848,809 B     848,809 B
  non-.incbin DATA regions     490,636 B     170,558 B     170,555 B
  regions >= 64 B judged       416,346 B     111,368 B     111,368 B
  rule fires                   276,423 B      10,712 B      10,712 B
  ends on ret/reti/jp          40% vs 25%    35% vs 3%     35% vs 3%
      (hits vs the regions the rule rejects -- data tables do not end on ret)

  HAND-AUDITING all 31 v9 hits rejects 5 as data (348 B): German and French UI
  strings at 0xED1A36 / 0xED1A7A, factory-test strings at 0xE1FE6E / 0xE1FF68,
  and an 0xFF-filled widget table at 0xEED1B0.  The surviving 26 regions,
  10,364 B, are real undisassembled functions.  Verified openings:
      0xFC5A94  2,752 B  ld (XIZ+0x01),0x20 ... calr 0xFC5874, and it ENDS at
                         its last byte with `pop XIZ ; ret` (0xFC6552)
      0xFC5874    264 B  cp (XWA),0xff ; ret Z ; ld C,(0x8e8e) ; cp C,0x0f
                         -- reached by 18 `calr` sites, yet the source labels it
                         `FileIO_BytecodeData`, i.e. the label is a misnomer
      0xEFA031    749 B  push XWA ; push XHL ; push XBC ... ends on `ret`
      0xF5DEFC  1,062 B  ld (0x33e0),0x00 ; ld A,(0x3421) ; extz WA
      0xF776BD    637 B  call 0xfa44d0 ; ld XWA,XHL ; ld XBC,0x01e0008f

  Second shape, invisible to the region view: 15,765 literal .byte runs SHORTER
  than 64 B are flanked by instructions on BOTH sides (24,972 B).  8,138 of them
  (12,188 B in v9, 12,085 B in v10) sit in a window the rule calls genuine code.
  They are single TLCS-900 instructions llvm-mc cannot spell -- `bit 0,(0x0459)`,
  `set 0,(0x160004)`, `call NZ,0xef489f`, `ld (XIX+HL),0x81`, `push QIZ`,
  `cp QIZH,1`.  67% are FRAGMENTS: the real instruction runs PAST the .byte run,
  so the source's next "instruction" is MIS-FRAMED.  Union of the real
  instructions they belong to: 23,547 B (v9) / 23,527 B (v10).
  Worked example, v9 0xFC65FC:
        source      .byte 0xf1 / swi 1 / .byte 0x90 / ld (xbc-74),152
        ROM         f1 f9 90 b9  =  set 1,(0x90f9)
  Both round-trip byte-exactly, so the build gate cannot tell them apart.

  TOTAL undisassembled code still carried as raw bytes:
        v9  10,364 + 12,188 = 22,552 B      v10  10,364 + 12,085 = 22,449 B
  i.e. 1.08% of the ROM, against v7's 276,423 B before hand-auditing.
  Correcting for the rule's 82.5% byte-weighted sensitivity puts the true figure
  near 27 KB per revision.

Run:
    python3 v9_v10_undisassembled_census.py --prepare  /path/to/scratch
    python3 v9_v10_undisassembled_census.py --census   v9 --work /path/to/scratch
    python3 v9_v10_undisassembled_census.py --calibrate v9 --work /path/to/scratch
    python3 v9_v10_undisassembled_census.py --judge    v9 --work /path/to/scratch
    python3 v9_v10_undisassembled_census.py --diff     v9 v10 --work /path/to/scratch
"""
import argparse, json, os, pickle, random, re, shutil, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if not os.path.isdir(os.path.join(REPO, "v9")):
    REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC   = os.path.join(LLVM, "llvm-mc")
LLD  = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM   = os.path.join(LLVM, "llvm-nm")
UNI  = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE, SIZE = 0xE00000, 2097152
TAGS = ("v7", "v9", "v10")

WIDTH  = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENC    = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
DATA_RE = re.compile(r'^\s*\.byte\b')
INCB_RE = re.compile(r'^\s*\.incbin\b')
DASM   = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


# ---------------------------------------------------------------- stage 1
def inject(root, tag, work):
    index, nid = [], 0
    for dp, _, fns in os.walk(root):
        for fn in sorted(fns):
            if not fn.endswith(".s"):
                continue
            p = os.path.join(dp, fn); rel = os.path.relpath(p, root)
            lines = open(p, encoding="utf-8", errors="surrogateescape").read().split("\n")
            out, i, n, in_macro, changed = [], 0, len(lines), False, False
            while i < n:
                s = lines[i].strip()
                if s.startswith(".macro"): in_macro = True
                elif s.startswith(".endm"): in_macro = False
                if in_macro:
                    out.append(lines[i]); i += 1; continue
                if INCB_RE.match(lines[i]) or DATA_RE.match(lines[i]):
                    kind = "incbin" if INCB_RE.match(lines[i]) else "byteblob"
                    if kind == "incbin":
                        last = i
                    else:                       # maximal run of .byte lines
                        j = last = i
                        while j < n:
                            t = lines[j].strip()
                            if DATA_RE.match(lines[j]): last = j; j += 1
                            elif t == "" or t.startswith(";") or t.startswith("#") \
                                 or (t.endswith(":") and not t.startswith(".")): j += 1
                            else: break
                    labels = [lines[k].strip()[:-1] for k in range(i, last + 1)
                              if lines[k].strip().endswith(":")
                              and not lines[k].strip().startswith(".")]
                    index.append({"id": nid, "kind": kind, "file": rel,
                                  "line": i + 1, "labels": labels[:6]})
                    out.append(f"\t.globl _MK{nid}_S\n_MK{nid}_S:")
                    out.extend(lines[i:last + 1])
                    out.append(f"\t.globl _MK{nid}_E\n_MK{nid}_E:")
                    nid += 1; changed = True; i = last + 1
                    continue
                out.append(lines[i]); i += 1
            if changed:
                open(p, "w", encoding="utf-8", errors="surrogateescape").write("\n".join(out))
    json.dump(index, open(os.path.join(work, f"index_{tag}.json"), "w"), indent=0)
    return nid


def prepare(work):
    os.makedirs(work, exist_ok=True)
    for t in TAGS:
        dst = os.path.join(work, t)
        if os.path.exists(dst): shutil.rmtree(dst)
        shutil.copytree(os.path.join(REPO, t), dst)
    shutil.copytree(os.path.join(REPO, "original_ROMs"),
                    os.path.join(work, "original_ROMs"), dirs_exist_ok=True)
    for t in TAGS:
        nid = inject(os.path.join(work, t), t, work)
        o, elf, rom = (os.path.join(work, t + x) for x in (".o", ".elf", ".rom"))
        subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", f"{t}/maincpu",
                        "-o", o, f"{t}/maincpu/kn5000_{t}_program.s"], cwd=work, check=True)
        subprocess.run([LLD, "-e", "0", "-T", f"{t}/maincpu/maincpu.ld", "-o", elf, o],
                       cwd=work, check=True)
        subprocess.run([OBJCOPY, "-O", "binary", elf, rom], check=True)
        orig = os.path.join(work, "original_ROMs", f"kn5000_{t}_program.rom")
        same = open(rom, "rb").read() == open(orig, "rb").read()
        print(f"{t}: {nid:,} markers injected -- rebuilt ROM "
              f"{'IDENTICAL to the original (markers are byte-neutral)' if same else 'DIFFERS -- ABORT'}")
        if not same: sys.exit(1)
        out = subprocess.run([NM, "--no-sort", elf], capture_output=True, text=True).stdout
        with open(os.path.join(work, f"{t}.marks.txt"), "w") as f:
            for line in out.split("\n"):
                if re.search(r'_MK\d+_[SE]$', line): f.write(line + "\n")


# ---------------------------------------------------------------- stage 2
def ascii_len(op):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', op))


def territory(tag, work):
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding",
                          "-I", f"{tag}/maincpu", f"{tag}/maincpu/kn5000_{tag}_program.s"],
                         capture_output=True, text=True, cwd=work)
    if out.returncode: sys.exit(out.stderr[:500])
    m = bytearray(SIZE); pos = 0; tal = {"CODE": 0, "DATA": 0, "PADDING": 0}
    kinds = {}
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"): continue
        e = ENC.search(line)
        if e:
            n = len([b for b in e.group(1).split(",") if b.strip()]); t, k = 1, "CODE"; d = "insn"
        else:
            if s.endswith(":") or s.startswith(";"): continue
            mm = re.match(r'\.(\w+)\s*(.*)$', s)
            if not mm: continue
            d, rest = mm.group(1), mm.group(2).strip()
            if d in WIDTH:
                n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1); t, k = 2, "DATA"
            elif d in ("ascii", "asciz"):
                n = ascii_len(rest) + (1 if d == "asciz" else 0); t, k = 2, "DATA"
            elif d in ("zero", "fill", "space"):
                p = [x.strip() for x in rest.split(",")]; n = int(p[0], 0)
                if d == "fill" and len(p) >= 2: n *= int(p[1], 0)
                t, k = 3, "PADDING"
            elif d == "p2align":
                n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0)); t, k = 3, "PADDING"
            elif d == "org":
                n = max(0, int(rest.split(",")[0].strip(), 0) - pos); t, k = 3, "PADDING"
            else: continue
        if n:
            m[pos:pos + n] = bytes([t]) * n; tal[k] += n; kinds[d] = kinds.get(d, 0) + n; pos += n
    return m, tal, kinds


def marks(tag, work):
    idx = {e["id"]: e for e in json.load(open(os.path.join(work, f"index_{tag}.json")))}
    se = {}
    for line in open(os.path.join(work, f"{tag}.marks.txt")):
        a, _, name = line.split()
        mm = re.match(r'_MK(\d+)_([SE])$', name)
        se.setdefault(int(mm.group(1)), {})[mm.group(2)] = int(a, 16) - BASE
    out = []
    for i, dd in se.items():
        if "S" in dd and "E" in dd and dd["E"] > dd["S"]:
            e = idx[i]
            out.append(dict(start=dd["S"], end=dd["E"], size=dd["E"] - dd["S"],
                            kind=e["kind"], file=e["file"], line=e["line"],
                            labels=e.get("labels", [])))
    return sorted(out, key=lambda b: b["start"])


def census(tag, work):
    terr, tal, kinds = territory(tag, work)
    blobs = marks(tag, work)
    tot = sum(tal.values())
    print(f"--- {tag}   classified {tot:,} B  "
          f"{'MATCH' if tot == SIZE else 'MISMATCH %+d' % (tot - SIZE)}")
    for k in ("CODE", "DATA", "PADDING"):
        print(f"      {k:8} {tal[k]:>10,}  {100.0*tal[k]/tot:5.2f}%")
    lit = sum(b["size"] for b in blobs if b["kind"] == "byteblob")
    inc = sum(b["size"] for b in blobs if b["kind"] == "incbin")
    print(f"      DATA by directive: " +
          "  ".join(f".{k} {v:,}" for k, v in sorted(kinds.items()) if k != "insn"))
    print(f"      literal .byte blobs {len([b for b in blobs if b['kind']=='byteblob']):,} "
          f"= {lit:,} B      .incbin {len([b for b in blobs if b['kind']=='incbin'])} = {inc:,} B")
    incmap = bytearray(SIZE)
    for b in blobs:
        if b["kind"] == "incbin": incmap[b["start"]:b["end"]] = b"\1" * b["size"]
    byname = {b["start"]: b for b in blobs if b["kind"] == "byteblob"}
    regs, i = [], 0
    while i < SIZE:
        if terr[i] == 2 and not incmap[i]:
            j = i
            while j < SIZE and terr[j] == 2 and not incmap[j]: j += 1
            src = next((byname[k] for k in range(i, min(j, i + 64)) if k in byname),
                       {"file": "?", "line": 0, "labels": []})
            regs.append(dict(start=i, end=j, size=j - i, src=src)); i = j
        else: i += 1
    print(f"      non-.incbin DATA regions: {len(regs):,} covering "
          f"{sum(r['size'] for r in regs):,} B")
    pickle.dump({"terr": bytes(terr), "blobs": blobs, "regs": regs},
                open(os.path.join(work, f"{tag}.map.pkl"), "wb"))
    return terr, blobs, regs


# ---------------------------------------------------------------- stage 3
def metrics(rom, off, n, tmp):
    blob = rom[off:off + n]
    open(tmp, "wb").write(blob)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + off)],
                         capture_output=True, text=True).stdout
    db = 0
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m and m.group(3).strip() == "db": db += len(m.group(2).split())
    per = 0.0
    for p in range(2, 33):
        if len(blob) > p:
            per = max(per, sum(1 for i in range(p, len(blob))
                               if blob[i] == blob[i - p]) / (len(blob) - p))
    ramp = sum(1 for i in range(1, len(blob))
               if blob[i] == (blob[i - 1] + 1) & 0xFF) / max(len(blob) - 1, 1)
    return dict(db=100.0 * db / len(blob), per=100.0 * per, ramp=100.0 * ramp,
                dist=len(set(blob)), n=len(blob))


def rule(m):
    return (m["db"] <= 5.0 and m["per"] <= 20.0 and m["ramp"] <= 12.0
            and m["dist"] >= min(60, round(0.35 * m["n"])))


def load(tag, work):
    d = pickle.load(open(os.path.join(work, f"{tag}.map.pkl"), "rb"))
    rom = open(os.path.join(work, "original_ROMs", f"kn5000_{tag}_program.rom"), "rb").read()
    return d["terr"], d["blobs"], d["regs"], rom


def calibrate(tag, work, n=300):
    terr, blobs, regs, rom = load(tag, work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    sizes = [r["size"] for r in regs if r["size"] >= 64]
    runs, i = [], 0
    while i < SIZE:
        if terr[i] == 1:
            j = i
            while j < SIZE and terr[j] == 1: j += 1
            if j - i >= 300: runs.append((i, j))
            i = j
        else: i += 1
    inc = [b for b in blobs if b["kind"] == "incbin" and b["size"] >= 300]
    random.seed(11)
    for name, kind in (("CODE control (long CODE runs)", "code"),
                       ("DATA control (.incbin interiors)", "data")):
        fire = fb = tb = 0
        for _ in range(n):
            sz = random.choice(sizes)
            if kind == "code":
                a, b = random.choice([r for r in runs if r[1] - r[0] > sz + 16])
                s = random.randrange(a + 8, b - sz)
            else:
                x = random.choice([x for x in inc if x["size"] > sz + 8])
                s = random.randrange(x["start"], x["end"] - sz)
            m = metrics(rom, s, sz, tmp); tb += sz
            if rule(m): fire += 1; fb += sz
        print(f"{name}: rule fires {fire}/{n} = {100.0*fire/n:.1f}%  "
              f"byte-weighted {fb:,}/{tb:,} = {100.0*fb/tb:.1f}%")


def judge(tag, work, minsize=64, top=40):
    terr, blobs, regs, rom = load(tag, work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    END = re.compile(r'^(ret|reti|retd|jp\b|jrl?\s+T,)', re.I)
    hit, miss, ends_hit, ends_miss = [], [], 0, 0
    for r in regs:
        if r["size"] < minsize: continue
        m = metrics(rom, r["start"], r["size"], tmp)
        open(tmp, "wb").write(rom[r["start"]:r["end"]])
        out = subprocess.run([UNI, tmp, "-arch", "tlcs900",
                              "-basepc", hex(BASE + r["start"])],
                             capture_output=True, text=True).stdout
        ls = [l.strip() for l in out.split("\n") if DASM.match(l.strip())]
        endok = False
        if ls:
            mm = DASM.match(ls[-1])
            endok = (int(mm.group(1), 16) - BASE + len(mm.group(2).split())
                     == r["end"]) and bool(END.match(mm.group(3).strip()))
        row = dict(r, **m, first=" ; ".join(l.split(None, 2)[-1] for l in ls[:3]))
        if rule(m): hit.append(row); ends_hit += endok
        else: miss.append(row); ends_miss += endok
    print(f"{tag}: {len(hit)+len(miss)} non-.incbin DATA regions >= {minsize} B, "
          f"{sum(r['size'] for r in hit+miss):,} B")
    print(f"   rule fires (CODE-like): {len(hit)} regions {sum(r['size'] for r in hit):,} B")
    print(f"   rule silent (DATA-like): {len(miss)} regions {sum(r['size'] for r in miss):,} B")
    print(f"   ends EXACTLY on ret/reti/jp: hits {ends_hit}/{len(hit)} "
          f"= {100.0*ends_hit/max(len(hit),1):.0f}%   "
          f"non-hits {ends_miss}/{len(miss)} = {100.0*ends_miss/max(len(miss),1):.0f}%")
    print("   HAND-AUDIT THESE -- the rule is a ranking, not a verdict:")
    for r in sorted(hit, key=lambda x: -x["size"])[:top]:
        print(f"   {BASE+r['start']:#09x} {r['size']:>6,} B db{r['db']:4.1f}% "
              f"per{r['per']:4.1f}% ramp{r['ramp']:4.1f}% dist{r['dist']:>4}  "
              f"{r['first'][:52]:<52} [{r['src']['file']}:{r['src']['line']}]")


def islands(tag, work, maxsize=1 << 30):
    """literal .byte runs flanked by instructions on BOTH sides"""
    terr, blobs, regs, rom = load(tag, work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    isl = [b for b in blobs if b["kind"] == "byteblob" and b["size"] <= maxsize
           and 0 < b["start"] and b["end"] < SIZE
           and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1]
    from collections import Counter
    cnt = Counter(); cov = set(); ex = []
    for r in isl:
        ctx = rule(metrics(rom, max(0, r["start"] - 100), 200, tmp))
        a, back = r["start"], 0
        while a > 0 and terr[a - 1] == 1 and back < 48: a -= 1; back += 1
        open(tmp, "wb").write(rom[a:r["end"] + 24])
        out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                             capture_output=True, text=True).stdout
        bnd = {}
        for line in out.split("\n"):
            m = DASM.match(line.strip())
            if m: bnd[int(m.group(1), 16) - BASE] = (len(m.group(2).split()),
                                                     m.group(3).strip())
        if r["start"] in bnd:
            L, txt = bnd[r["start"]]
            fr = "ONE_INSN" if L == r["size"] else ("SPANS" if L > r["size"] else "MULTI")
        else:
            L, txt, fr = 0, "", "UNSYNCED"
        key = ("ctx_code" if ctx else "ctx_data", fr)
        cnt[key] += 1; cnt[key + ("B",)] += r["size"]
        if ctx:
            cov.update(range(r["start"], r["start"] + L))
            if len(ex) < 12 and fr in ("ONE_INSN", "SPANS"):
                ex.append((BASE + r["start"], r["size"], L, txt))
    print(f"{tag}: {len(isl):,} CODE-flanked literal .byte runs, "
          f"{sum(r['size'] for r in isl):,} B")
    for k in sorted([k for k in cnt if len(k) == 2], key=lambda k: -cnt[k + ('B',)]):
        print(f"   {k[0]:<9} {k[1]:<9} {cnt[k]:>7,} runs {cnt[k+('B',)]:>8,} B")
    cc = sum(cnt[k + ('B',)] for k in cnt if len(k) == 2 and k[0] == "ctx_code")
    ci = sum(cnt[k] for k in cnt if len(k) == 2 and k[0] == "ctx_code")
    print(f"   => in genuine-code context: {ci:,} runs, {cc:,} B; the real "
          f"instructions they belong to cover {len(cov):,} B")
    for a, sz, L, txt in ex:
        print(f"      0x{a:06X}  {sz} B of .byte -> real {L} B instruction: {txt}")


def diff(a, b, work):
    ta = pickle.load(open(os.path.join(work, f"{a}.map.pkl"), "rb"))["terr"]
    tb = pickle.load(open(os.path.join(work, f"{b}.map.pkl"), "rb"))["terr"]
    d1 = sum(1 for i in range(SIZE) if ta[i] == 2 and tb[i] == 1)
    d2 = sum(1 for i in range(SIZE) if tb[i] == 2 and ta[i] == 1)
    print(f"{a} DATA where {b} CODE: {d1:,} B ; {b} DATA where {a} CODE: {d2:,} B ; "
          f"any territory difference: {sum(1 for i in range(SIZE) if ta[i] != tb[i]):,} B")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default=None)
    ap.add_argument("--prepare", nargs="?", const=True)
    ap.add_argument("--census"); ap.add_argument("--calibrate")
    ap.add_argument("--judge"); ap.add_argument("--islands")
    ap.add_argument("--max-island", type=int, default=1 << 30)
    ap.add_argument("--diff", nargs=2)
    a = ap.parse_args()
    work = a.work or (a.prepare if isinstance(a.prepare, str) else None)
    if not work: sys.exit("--work DIR is required (a scratch dir, several hundred MB)")
    if a.prepare: prepare(work)
    if a.census: census(a.census, work)
    if a.calibrate: calibrate(a.calibrate, work)
    if a.judge: judge(a.judge, work)
    if a.islands: islands(a.islands, work, a.max_island)
    if a.diff: diff(a.diff[0], a.diff[1], work)


if __name__ == "__main__":
    main()
