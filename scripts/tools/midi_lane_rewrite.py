#!/usr/bin/env python3
r"""Re-express an ADDRESS RANGE of a maincpu source file (v10, v9 or v7) as
correctly framed code or as typed data, and prove the image is unchanged.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
The midi lane (2026-09-25) had three kinds of edit to make, in three images:

  * data spelled as instructions (`jrl nc, 1793` x 21, `swi 7`, `max`...) to be
    re-typed as `.byte`/`.short`/`.long` records whose layout comes from the
    reader routine;
  * code spelled as `.byte` runs, or MISFRAMED (a lone `.byte 0xf1` followed by
    its operand bytes decoded as instructions), to be re-decoded at the right
    boundaries with the current backend;
  * a v10 rendering to be ported to v9/v7 where the bytes are the same.

Every one of these is invisible to the byte gate in BOTH directions, so this
tool never decides WHAT a range is -- the spec says so, and the spec's comment
must carry the evidence.  Its job is to render faithfully and to refuse:

  * a range whose ends are not source-line boundaries (it would split a line);
  * a label inside the range that the new rendering would not place on an
    item/instruction boundary (it would move the symbol);
  * a code line whose chosen spelling does not re-assemble, ALONE, to the ROM
    bytes the decoder read (the decoder and assembler are not a bijection);
  * any result where the rebuilt image differs from the dump by one byte
    (every file touched in the run is restored).

Interior labels and comment lines are KEPT and re-emitted before the item that
starts at their address.  A comment can be dropped only by naming it in the
spec's `drop_comments` (substring match) -- used only where the comment's
claim was proven false, and the commit message must say so.

HOW ADDRESSES ARE KNOWN
    The data census's marker mirror (scripts/analysis/data_range_census.py):
    every non-blank line gets a synthetic label, the mirror is linked with the
    real linker script and the ROM rebuilt from it must equal the dump (else
    REFUSED).  A comment-only line takes the address of the next marked line.

CODE RENDERING
    llvm-objdump -d -z over the ROM bytes of the range (the shared toolchain;
    its commit is printed).  For each instruction the tool tries, in order, a
    house-style spelling (`ld l, (0x964c:16)` for `ldb_d8 l, (38476)`, hex
    for addresses, labels for ROM targets) and the decoder's own text, and
    keeps the first that `llvm-mc -show-encoding` turns back into exactly the
    instruction's bytes; branch/call operands are named when a label sits at
    the target (ELF symbols of the last build, positional `_0x..` aliases
    avoided), otherwise left numeric for symbolize_numeric_branches.py.
    Bytes the backend cannot decode are emitted as `.byte`.

SPEC (JSON list; addresses as strings):
    {"file": "midi/midi_dispatch_handlers.s",    # relative to <image>/maincpu
     "start": "0xFD16E7", "end": "0xFD175E",
     "kind": "code" | "data",
     "labels":  {"0xFD1722": "NewName"},          # optional, new labels
     "comment": ["...", ...],                     # optional, header at start
     "segments": [                                # data only
        {"len": 128, "type": "byte"|"short"|"long", "per_line": 16,
         "label": "Name" (optional), "comment": [...] (optional),
         "symbols": true (long only: name ROM pointers)}, ...],
     "drop_comments": ["substring", ...]}         # optional

RUN (repo root; `make all` first so includes/generated/ exists)
    python3 scripts/tools/midi_lane_rewrite.py --image v10 --spec S.json --dry-run
    python3 scripts/tools/midi_lane_rewrite.py --image v10 --spec S.json
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402

LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
LABEL_RE = re.compile(r"^([A-Za-z_.$][A-Za-z0-9_.$]*):")
BASE = 0xE00000


def image(key):
    return [i for i in drc.IMAGES if i["key"] == key][0]


# ------------------------------------------------------------------ line map
def line_addresses(key, rels):
    """{rel: [addr or None per line]} for the requested files (0-based lines).
    Marked lines get their marker address; comment-only/blank lines inherit the
    address of the next marked line in the same file."""
    img = image(key)
    tmp = tempfile.mkdtemp(prefix="midirw-")
    mdir = os.path.join(tmp, "mirror")
    marks = drc.mirror_tree(os.path.join(ROOT, img["mirror"]), mdir)
    elf = drc.link_mirror(mdir, img, tmp)
    raw = os.path.join(tmp, "m.bin")
    drc.sh([drc.OBJCOPY, "-O", "binary", elf, raw])
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    if open(raw, "rb").read() != rom:
        sys.exit("REFUSED: marked mirror of %s does not rebuild the dump" % key)
    addrs = drc.marker_addresses(elf)
    out = {}
    for rel in rels:
        n = len(open(os.path.join(ROOT, img["mirror"], rel), encoding="latin-1").read().split("\n"))
        out[rel] = [None] * n
    for i, (rel, li) in enumerate(marks):
        if rel in out and i in addrs:
            out[rel][li] = addrs[i]
    for rel, L in out.items():
        nxt = None
        for li in range(len(L) - 1, -1, -1):
            if L[li] is None:
                L[li] = nxt
            else:
                nxt = L[li]
    return out, rom


def elf_symbols(key):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % key)
    out = subprocess.run([os.path.join(LLVM, "llvm-nm"), "--defined-only", elf],
                         capture_output=True, text=True, check=True).stdout
    syms = {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith((".L", "__")):
            a = int(p[0], 16)
            pos = re.search(r"_0x[0-9A-Fa-f]+$", p[2])
            if a not in syms or (re.search(r"_0x[0-9A-Fa-f]+$", syms[a]) and not pos):
                syms[a] = p[2]
    return syms


# ------------------------------------------------------------------ encoding
def encodings(texts):
    """-> list of byte-lists (or None) for each single instruction text."""
    src = "\n".join("\t" + t for t in texts) + "\n"
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=src,
                       capture_output=True, text=True)
    res = []
    ok = r.returncode == 0
    if ok:
        for line in r.stdout.split("\n"):
            m = re.search(r"encoding: \[([^\]]*)\]", line)
            if m:
                res.append([int(x, 16) for x in m.group(1).split(",") if x.strip()])
        if len(res) == len(texts):
            return res
    # fall back one by one (an error aborts the whole batch)
    out = []
    for t in texts:
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input="\t" + t + "\n",
                           capture_output=True, text=True)
        m = re.search(r"encoding: \[([^\]]*)\]", r.stdout) if r.returncode == 0 else None
        out.append([int(x, 16) for x in m.group(1).split(",") if x.strip()] if m else None)
    return out


def objdump(data):
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "d.s")
        o = os.path.join(td, "d.o")
        with open(s, "w") as f:
            f.write(".text\n")
            for i in range(0, len(data), 16):
                f.write(".byte " + ",".join("0x%02x" % c for c in data[i:i + 16]) + "\n")
        subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s], check=True)
        out = subprocess.run([os.path.join(LLVM, "llvm-objdump"), "-d", "-z", o],
                             capture_output=True, text=True, check=True).stdout
    segs = []
    pat = re.compile(r"^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$")
    for line in out.split("\n"):
        m = pat.match(line)
        if not m:
            continue
        raw = [int(x, 16) for x in m.group(2).split()]
        text = m.group(3).strip()
        if text.startswith("<unknown>"):
            segs.append((raw[:1], None))
        else:
            segs.append((raw, re.sub(r"\s+", " ", text, count=1)))
    if sum(len(r) for r, _ in segs) != len(data):
        raise SystemExit("objdump covered %d of %d bytes" % (sum(len(r) for r, _ in segs), len(data)))
    return segs


REL_BR = re.compile(r"^(jr|jrl|calr|djnz)\b")
ABS_BR = re.compile(r"^(call|jp)\b")


def hexaddr(v, width):
    return "0x%x:%d" % (v, width)


def canon(text):
    """House-style candidate for a decoder spelling (verified by the caller)."""
    mn, _, ops = text.partition(" ")
    ops = ops.strip()
    m = re.fullmatch(r"(\w+), (\w+), (\w+)", ops)
    if mn in ("ld_rrl", "ld_rrw", "ld_rrb", "ld_rr8b", "ld_rr8w", "ld_rr8l") and m:
        return "ld\t%s, (%s+%s)" % m.groups()
    if mn == "lda_rr" and m:
        return "lda\t%s, (%s+%s)" % m.groups()
    if mn in ("st_rrb", "st_rrw", "st_rrl") and m:
        return "ld\t(%s+%s), %s" % (m.group(2), m.group(3), m.group(1))
    m = re.fullmatch(r"(\w+), \((\d+)\)", ops)
    if m and mn in ("ldb_d8", "ldw_d16", "ldl_d16"):
        return "ld\t%s, (%s)" % (m.group(1), hexaddr(int(m.group(2)), 16))
    if m and mn in ("ldb_da", "ldw_da", "ldl_da"):
        return "ld\t%s, (%s)" % (m.group(1), hexaddr(int(m.group(2)), 24))
    if m and mn == "lda_d16":
        return "lda\t%s, (%s)" % (m.group(1), hexaddr(int(m.group(2)), 16))
    if m and mn == "lda_24":
        return "lda\t%s, (%s)" % (m.group(1), hexaddr(int(m.group(2)), 24))
    if m and mn in ("bitda", "bitm"):
        return "bit\t%s, (%s)" % (m.group(1), hexaddr(int(m.group(2)), 16))
    m = re.fullmatch(r"\((\d+)\), (\w+)", ops)
    if m and mn in ("stb_d8", "stw_d16", "stl_d16"):
        return "ld\t(%s), %s" % (hexaddr(int(m.group(1)), 16), m.group(2))
    return None


def hexify(text):
    """Large decimal immediates -> hex (addresses/masks), keep small ones."""
    def rep(m):
        v = int(m.group(0))
        return m.group(0) if v < 256 else "0x%x" % v
    mn, sp, ops = text.partition(" ")
    ops = re.sub(r"(?<![\w+-])\d+(?![\w:])", rep, ops)
    ops = re.sub(r"\((\d+)\)", lambda m: "(0x%x)" % int(m.group(1)) if int(m.group(1)) >= 256 else m.group(0), ops)
    return mn + sp + ops


def branch_target(text, addr, n):
    """Target of a numeric branch/call in the DECODER's text, else None."""
    mn = text.split()[0]
    if REL_BR.match(mn):
        m = re.search(r"(-?\d+)$", text)
        return addr + n + int(m.group(1)) if m else None
    if ABS_BR.match(mn):
        m = re.search(r"(\d+)$", text)
        return int(m.group(1)) if m else None
    return None


def name_operand(chosen, text, addr, n, syms):
    """Replace a numeric ROM target/immediate in `chosen` by the label there."""
    tgt = branch_target(text, addr, n)
    if tgt is not None:
        if tgt in syms:
            return re.sub(r"(-?(0x)?[0-9a-f]+)$", syms[tgt], chosen)
        return chosen
    for m in re.finditer(r"(?<![\w(])(0x[0-9a-f]{6}|\d{7,8})(?![\w:])", chosen):
        v = int(m.group(1), 0)
        if BASE <= v < BASE + 0x200000 and v in syms:
            return chosen[:m.start()] + syms[v] + chosen[m.end():]
    return chosen


def render_code(rom, a, b, boundaries, syms):
    """-> list of (addr, text).  Refuses if a boundary is not an insn start."""
    data = rom[a - BASE:b - BASE]
    items, off = [], 0
    for raw, text in objdump(data):
        items.append((a + off, raw, text))
        off += len(raw)
    starts = {x[0] for x in items}
    bad = [hex(x) for x in boundaries if a <= x < b and x not in starts]
    if bad:
        raise SystemExit("REFUSED: labels/boundaries %s are not instruction starts" % bad)
    tests = []
    for k, (ad, raw, text) in enumerate(items):
        if text is None:
            continue
        if REL_BR.match(text.split()[0]) or ABS_BR.match(text.split()[0]):
            tests.append((k, text))
            continue
        c = canon(text)
        seen = []
        bare = re.sub(r":(opc|i3)\b", "", hexify(text))
        for t in ([hexify(c), c] if c else []) + [bare, hexify(text), text]:
            if t not in seen:
                seen.append(t)
                tests.append((k, t))
    enc = encodings([t for _, t in tests])
    good = {}
    for (k, t), e in zip(tests, enc):
        if k not in good and e == items[k][1]:
            good[k] = t
    out = []
    for k, (ad, raw, text) in enumerate(items):
        if k not in good:
            out.append((ad, "\t.byte " + ", ".join("0x%02x" % x for x in raw)))
            continue
        t = name_operand(good[k], text, ad, len(raw), syms)
        mn, sp, ops = t.replace("\t", " ").partition(" ")
        out.append((ad, "\t" + mn + ("\t" + ops.strip() if ops.strip() else "")))
    return out


def render_data(rom, a, b, segs, syms):
    out, off = [], a
    for sg in segs:
        n = sg["len"]
        d = rom[off - BASE:off - BASE + n]
        if sg.get("comment"):
            for c in sg["comment"]:
                out.append((off, ("\t; " + c) if c else ""))
        if sg.get("label"):
            out.append((off, sg["label"] + ":"))
        t = sg["type"]
        w = {"byte": 1, "short": 2, "long": 4}[t]
        if n % w:
            raise SystemExit("segment at 0x%X: %d bytes is not a whole number of %s" % (off, n, t))
        per = sg.get("per_line", 1)
        vals = []
        for i in range(0, n, w):
            v = int.from_bytes(d[i:i + w], "little")
            if t == "long" and sg.get("symbols") and v in syms:
                vals.append(syms[v])
            elif t == "byte":
                vals.append(sg.get("fmt", "0x%02x") % v)
            else:
                vals.append("0x%0*x" % (w * 2, v))
        for i in range(0, len(vals), per):
            out.append((off + i * w, "\t.%s %s" % (t, ", ".join(vals[i:i + per]))))
        off += n
    if off != b:
        raise SystemExit("segments cover 0x%X..0x%X, span ends 0x%X" % (a, off, b))
    return out


# ------------------------------------------------------------------ splice
def splice(lines, la, a, b, new, spec):
    """Replace the source lines emitting [a,b) with `new` (list of (addr,text))."""
    idx = [i for i, ad in enumerate(la) if ad is not None and a <= ad < b]
    if not idx:
        raise SystemExit("no source lines at 0x%X" % a)
    emit = [i for i in idx if drc.classify_line(lines[i], {})[0] in ("code", "data", "fill")]
    first = min(emit)
    # the line after the last emitting line must start at >= b
    last = max(emit)
    nxt = [ad for ad in la[last + 1:] if ad is not None]
    if la[first] != a:
        raise SystemExit("REFUSED: 0x%X is not the start of a source line (first line at 0x%X)" % (a, la[first]))
    if not nxt or nxt[0] != b:
        raise SystemExit("REFUSED: 0x%X is not the end of a source line (next line at %s)" %
                         (b, hex(nxt[0]) if nxt else None))
    # the region may include trailing non-emitting lines up to the next emitter
    keep = []          # (addr, text) interior labels/comments to re-emit
    drops = spec.get("drop_comments", [])
    dropped = []
    for i in range(first, last + 1):
        t = lines[i]
        kind = drc.classify_line(t, {})[0]
        s = t.strip()
        cmt = s.startswith(";")
        if LABEL_RE.match(s) and kind == "none":
            keep.append((la[i], t))
        elif cmt or (not s):
            if cmt and any(d in s for d in drops):
                dropped.append(s)
                continue
            keep.append((la[i], t))
        elif ";" in t and kind in ("code", "data", "fill"):
            tail = t[t.index(";"):]
            if any(d in tail for d in drops):
                dropped.append(tail)
            else:
                keep.append((la[i], "\t" + tail))
    starts = {ad for ad, tx in new if tx.startswith("\t") and not tx.startswith("\t;")}
    bad = [(hex(ad), tx) for ad, tx in keep if LABEL_RE.match(tx.strip()) and ad not in starts and ad != b]
    if bad:
        raise SystemExit("REFUSED: labels not on item boundaries: %s" % bad)
    out, oad = [], []
    keep.sort(key=lambda x: x[0])
    placed = set()
    for ad, tx in new:
        if tx.startswith("\t") and not tx.startswith("\t;"):
            for k, (kad, ktx) in enumerate(keep):
                if kad <= ad and k not in placed:
                    out.append(ktx)
                    oad.append(ad)
                    placed.add(k)
        out.append(tx)
        oad.append(ad)
    for k, (kad, ktx) in enumerate(keep):
        if k not in placed:
            out.append(ktx)
            oad.append(b)
    return (lines[:first] + out + lines[last + 1:], la[:first] + oad + la[last + 1:],
            dropped)


def verify(key):
    img = image(key)
    td = tempfile.mkdtemp(prefix="midirw-v-")
    inc = os.path.join(ROOT, img["mirror"])
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", inc, "-o",
                        os.path.join(td, "o.o"), os.path.join(inc, img["root"])],
                       capture_output=True, text=True)
    if r.returncode:
        print("\n".join(l for l in r.stderr.split("\n") if "error" in l)[:3000])
        return False
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T", os.path.join(inc, img["ld"]),
                    "-o", os.path.join(td, "o.elf"), os.path.join(td, "o.o")], check=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary",
                    os.path.join(td, "o.elf"), os.path.join(td, "o.bin")], check=True)
    got = open(os.path.join(td, "o.bin"), "rb").read()
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    if got != rom:
        d = [i for i in range(min(len(got), len(rom))) if got[i] != rom[i]]
        print("first difference at 0x%X (%d bytes differ)" % (BASE + d[0], len(d)) if d else "length differs")
        return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--spec", required=True)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    specs = json.load(open(a.spec))
    rels = sorted({s["file"] for s in specs})
    la, rom = line_addresses(a.image, rels)
    syms = elf_symbols(a.image)
    tc = subprocess.run(["git", "log", "-1", "--format=%h"], cwd=os.path.dirname(LLVM) + "/..",
                        capture_output=True, text=True).stdout.strip()
    print("toolchain llvm-project@%s" % tc)
    img = image(a.image)
    backups = {}
    for rel in rels:
        path = os.path.join(ROOT, img["mirror"], rel)
        raw = open(path, "rb").read()
        backups[path] = raw
        lines = raw.decode("latin-1").split("\n")
        L = la[rel]
        group = sorted([s for s in specs if s["file"] == rel], key=lambda s: -int(s["start"], 16))
        for s in group:
            st, en = int(s["start"], 16), int(s["end"], 16)
            for k, v in s.get("labels", {}).items():
                syms[int(k, 16)] = v
            if s["kind"] == "code":
                bnd = [int(k, 16) for k in s.get("labels", {})]
                for i, ad in enumerate(L):
                    if ad is not None and st <= ad < en and LABEL_RE.match(lines[i].strip()) \
                            and drc.classify_line(lines[i], {})[0] == "none":
                        bnd.append(ad)
                new = render_code(rom, st, en, bnd, syms)
            else:
                new = render_data(rom, st, en, s["segments"], syms)
            # new labels
            ins = []
            for k, v in sorted(s.get("labels", {}).items(), key=lambda kv: int(kv[0], 16)):
                ins.append((int(k, 16), v + ":"))
            merged = []
            for ad, tx in new:
                for x in [i for i in ins if i[0] == ad]:
                    merged.append(x)
                    ins.remove(x)
                merged.append((ad, tx))
            if ins:
                raise SystemExit("REFUSED: new labels not on item boundaries: %s" % ins)
            hdr = [(st, ("\t; " + c) if c else "") for c in s.get("comment", [])]
            lines, L, dropped = splice(lines, L, st, en, hdr + merged, s)
            print("%s %s 0x%s..0x%s kind=%s -> %d lines%s" % (a.image, rel, s["start"][2:], s["end"][2:],
                  s["kind"], len(new), (", dropped %d comment(s)" % len(dropped)) if dropped else ""))
            for d in dropped:
                print("    dropped: " + d[:120])
            if a.dry_run:
                for ad, tx in (hdr + merged)[:400]:
                    print("   %06X %s" % (ad, tx))
        if not a.dry_run:
            open(path, "wb").write("\n".join(lines).encode("latin-1"))
    if a.dry_run:
        return
    if not verify(a.image):
        for p, t in backups.items():
            open(p, "wb").write(t)
        sys.exit("REJECTED: rebuilt %s differs from the dump; all edits restored" % a.image)
    print("VERIFIED: rebuilt %s is byte-identical to the dump" % a.image)


if __name__ == "__main__":
    main()
