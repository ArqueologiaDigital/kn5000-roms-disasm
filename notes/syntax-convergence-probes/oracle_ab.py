#!/usr/bin/env python3
"""
QUESTION 1: on the SAME BYTES, where do this tree's backend and MAME unidasm
            disagree -- about the instruction, not about the spelling?
QUESTION 2: what would "converge on unidasm" actually cost?  i.e. if every
            source line were rewritten in unidasm's own text, how many of them
            would the backend assemble, and to the same bytes?

METHOD (no desync, no build required)

  A. Assemble each root source with `llvm-mc -show-encoding`.  Every
     instruction line comes back with the bytes it emits.  Lines whose
     encoding carries a relocation (`[0x66,A]`) are EXCLUDED -- their bytes
     are not final at assembly time.  ⚠ In an unbuilt worktree the only
     assembler errors are "Could not find incbin file"; those drop DATA, never
     an instruction encoding, so the harvest is complete either way (the run
     prints the error census so this stays checkable).

  B. Lay every harvested instruction into its own 16-byte slot, padded with
     0x00 = NOP.  Run unidasm ONCE over the blob.  Because NOP is one byte,
     unidasm resynchronises at the next slot boundary even when it consumes a
     different number of bytes than llvm-mc emitted -- so a length disagreement
     is VISIBLE instead of desynchronising the rest of the file.

  C. Classify each site:
       AGREE_LEN     both decoders consume the same bytes
       LEN_DIFFER    they do not -- a genuine decoder disagreement
       UNIDASM_DB    unidasm prints "db", i.e. it refuses these bytes
     and within AGREE_LEN, compare the mnemonics after case folding:
       SAME_MNEMONIC / DIFF_MNEMONIC.

  D. Take unidasm's own text for every distinct site, hand it back to
     llvm-mc, and compare the bytes:
       UNI_ASSEMBLES_SAME  the backend already accepts unidasm's spelling
       UNI_ASSEMBLES_DIFF  it accepts it and emits DIFFERENT bytes  (⚠ the
                           dangerous class: a silent misencode)
       UNI_REJECTS         the backend would have to learn this spelling

  D is the cost of converging on unidasm, in call sites and in distinct
  spellings.

EXACT COMMAND (from the tree root):

    python3 notes/syntax-convergence-probes/oracle_ab.py \
        --out notes/syntax-convergence-probes/out

Tools it shells out to, both live, neither vendored:
    ~/compartilhado/llvm-project/build/bin/llvm-mc   (this tree's backend)
    ~/compartilhado/mame/unidasm                     (the independent oracle)
"""
import argparse, collections, os, re, shutil, subprocess, sys, json, tempfile, hashlib

HOME = os.path.expanduser("~")
# ⚠ SNAPSHOT THE ASSEMBLER.  Other lanes rebuild ~/compartilhado/llvm-project
# while this runs; a run that harvests with one binary and re-assembles with
# the next one is measuring two backends.  The run copies llvm-mc aside first
# and records its sha256 with the results.
LLVM_MC = os.path.join(HOME, "compartilhado/llvm-project/build/bin/llvm-mc")
UNIDASM = os.path.join(HOME, "compartilhado/mame/unidasm")
SLOT = 16

# (source dir, root file) for every image whose root assembles standalone
ROOTS = [
    ("v10/maincpu", "kn5000_v10_program.s"),
    ("v9/maincpu", "kn5000_v9_program.s"),
    ("v7/maincpu", "kn5000_v7_program.s"),
    ("v142/subcpu", "kn5000_subprogram_v142.s"),
    ("subcpu/boot", "kn5000_subcpu_boot.s"),
    ("hdae5000", "hd-ae5000_v2_06i.s"),
    ("table_data", "kn5000_table_data.s"),
    ("custom_data", "kn5000_custom_data.s"),
]
WSA1_ROOTS = [
    ("prom_a", "prom_a/wsa1_prom_a.s"),
    ("prom_b", "prom_b/wsa1_prom_b.s"),
    ("prom_c", "prom_c/wsa1_prom_c.s"),
    ("prom_d", "prom_d/wsa1_prom_d.s"),
]

ENC = re.compile(r'^\t([A-Za-z_][\w.]*)\t?(.*?)\s*; encoding: \[([^\]]*)\]\s*$')
PUREHEX = re.compile(r'^(?:0x[0-9a-f]{2})(?:,0x[0-9a-f]{2})*$')
UNILINE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(\S.*?)\s*$')


def harvest(root, cwd, incdir, src):
    """Assemble one root source; return [(mnemonic, operands, bytes)]."""
    p = subprocess.run([LLVM_MC, "-triple=tlcs900", "-show-encoding",
                        "-I", incdir, src],
                       cwd=cwd, capture_output=True, text=True,
                       errors="replace")
    errs = collections.Counter(
        re.sub(r"'[^']*'", "'X'", m)
        for m in re.findall(r'error: (.*)', p.stderr))
    sites, reloc = [], 0
    for line in p.stdout.split("\n"):
        m = ENC.match(line)
        if not m:
            continue
        mnem, ops, enc = m.group(1), m.group(2).strip(), m.group(3)
        if not PUREHEX.match(enc):
            reloc += 1
            continue
        data = bytes(int(b, 16) for b in enc.split(","))
        sites.append((mnem, ops, data))
    return sites, reloc, errs


def unidasm_slots(sites, workdir, tag):
    """One unidasm pass over a NOP-padded slot blob.  Returns per-slot
    (consumed_bytes, text) or None where unidasm produced no line."""
    blob = bytearray()
    for _, _, data in sites:
        assert len(data) <= SLOT
        blob += data + b"\x00" * (SLOT - len(data))
    path = os.path.join(workdir, "slots_%s.bin" % tag)
    open(path, "wb").write(bytes(blob))
    p = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", "0"],
                       capture_output=True, text=True, errors="replace")
    out = {}
    for line in p.stdout.split("\n"):
        m = UNILINE.match(line)
        if not m:
            continue
        off = int(m.group(1), 16)
        nb = len(m.group(2).split())
        out[off] = (nb, m.group(3))
    res = []
    for i in range(len(sites)):
        res.append(out.get(i * SLOT))
    os.unlink(path)
    return res


def uni_to_llvm(text):
    """unidasm text -> a candidate llvm-mc source line.  Only the mechanical
    part: fold case, put a space after the operand comma.  NOTHING is
    translated -- the whole point is to find out what the backend accepts."""
    t = text.strip()
    parts = t.split(None, 1)
    mnem = parts[0].lower()
    ops = parts[1] if len(parts) > 1 else ""
    ops = re.sub(r',\s*', ', ', ops)
    return (mnem + " " + ops).strip(), mnem


def reassemble(cands, workdir, pc_shift=0):
    """cands: list of unidasm source lines.  Returns {line: bytes|None|"RELOC"}.

    ⚠ llvm-mc PRINTS AN ENCODING FOR A LINE IT REJECTED.  `calr 0x0185f8` is
    diagnosed ("immediate does not fit") and still shows `encoding: [0x1e]`.
    Reading stdout alone therefore scores a REJECTED spelling as one that
    assembles to different bytes.  Errors are taken from stderr by LINE NUMBER
    and win over anything stdout says.

    pc_shift moves every candidate to a different address.  It was added to
    detect PC-RELATIVE spellings automatically and IT CANNOT WORK HERE, which
    is worth recording: this backend's `jr`/`jrl`/`calr` take a DISPLACEMENT,
    not a target, when handed a bare number -- `jr 99832` becomes [0x68,0xf8],
    the operand's low byte used as the displacement -- so moving the origin
    changes nothing.  The run keeps the second pass as a live control (it must
    report zero) and classifies branches by unidasm's own mnemonic instead.
    ⚠ If ever re-used elsewhere: the shift must NOT be a multiple of 256, or
    the low byte of an 8-bit displacement is unchanged and the detector
    silently reports none.
    """
    lines, order = [], []
    lead = 0
    if pc_shift:
        lines.append("\t.space %d" % pc_shift)
        lead = 1
    for i, c in enumerate(cands):
        lines.append("L%d:" % i)
        lines.append("\t" + c)
        order.append(c)
    path = os.path.join(workdir, "cand%d.s" % pc_shift)
    open(path, "w").write("\n".join(lines) + "\n")
    p = subprocess.run([LLVM_MC, "-triple=tlcs900", "-show-encoding", path],
                       capture_output=True, text=True, errors="replace")
    # a candidate occupies file lines (lead + 2i + 1) and (lead + 2i + 2)
    bad = set()
    for m in re.finditer(r'^[^\n:]*:(\d+):\d+: error:', p.stderr, re.M):
        ln = int(m.group(1))
        idx = (ln - lead - 1) // 2
        if 0 <= idx < len(order):
            bad.add(idx)
    got = {}
    cur = None
    for line in p.stdout.split("\n"):
        lm = re.match(r'^L(\d+):', line)
        if lm:
            cur = int(lm.group(1))
            got.setdefault(cur, None)
            continue
        m = ENC.match(line)
        if m and cur is not None:
            enc = m.group(3)
            if PUREHEX.match(enc):
                got[cur] = bytes(int(b, 16) for b in enc.split(","))
            else:
                got[cur] = "RELOC"
            cur = None
    for i in bad:
        got[i] = None
    os.unlink(path)
    return {order[i]: got.get(i) for i in range(len(order))}


def main():
    global LLVM_MC
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--out", required=True)
    ap.add_argument("--llvm-mc", default=LLVM_MC)
    ap.add_argument("--limit-images", default=None,
                    help="comma-separated substrings; default = all")
    ap.add_argument("--foil", type=int, default=0, metavar="N",
                    help="FOIL CONTROL: append one extra 0x00 byte to every "
                         "Nth site's recorded encoding.  unidasm then reads "
                         "one byte FEWER than the record claims, so those "
                         "sites MUST come back LEN_DIFFER.  If they do not, "
                         "the length comparison is blind and every "
                         "LEN_DIFFER=0 result in this file is worthless.")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    work = tempfile.mkdtemp(prefix="oracle_ab_")
    snap = os.path.join(work, "llvm-mc")
    shutil.copy2(a.llvm_mc, snap)
    LLVM_MC = snap
    mc_sha = hashlib.sha256(open(snap, "rb").read()).hexdigest()
    llvm_head = subprocess.run(
        ["git", "-C", os.path.join(HOME, "compartilhado/llvm-project"),
         "log", "-1", "--format=%H"], capture_output=True, text=True).stdout.strip()
    uni_sha = hashlib.sha256(open(UNIDASM, "rb").read()).hexdigest()
    print("llvm-mc  sha256 %s  (llvm-project HEAD %s)" % (mc_sha[:16], llvm_head[:12]))
    print("unidasm  sha256 %s" % uni_sha[:16])

    jobs = [(a.root, d, os.path.join(d, f)) for d, f in ROOTS]
    jobs += [(os.path.join(a.root, "wsa1"), ".", f) for _, f in WSA1_ROOTS]
    if a.limit_images:
        pats = a.limit_images.split(",")
        jobs = [j for j in jobs if any(p in j[2] for p in pats)]

    all_rows = []
    per_image = {}
    for cwd, incdir, src in jobs:
        tag = os.path.basename(src).replace(".s", "")
        if not os.path.exists(os.path.join(cwd, src)):
            print("SKIP (absent): %s" % src); continue
        sites, reloc, errs = harvest(a.root, cwd, incdir, src)
        if a.foil:
            sites = [(m, o, d + b"\x00" if i % a.foil == 0 else d)
                     for i, (m, o, d) in enumerate(sites)]
        uni = unidasm_slots(sites, work, tag)
        c = collections.Counter()
        for (mnem, ops, data), u in zip(sites, uni):
            if u is None:
                cls = "UNIDASM_NOLINE"; utext = ""
            else:
                nb, utext = u
                if utext.split(None, 1)[0].lower() == "db":
                    cls = "UNIDASM_DB"
                elif nb != len(data):
                    cls = "LEN_DIFFER"
                else:
                    um = utext.split(None, 1)[0].lower()
                    cls = "SAME_MNEMONIC" if um == mnem.lower() else "DIFF_MNEMONIC"
            c[cls] += 1
            all_rows.append((tag, mnem, ops, data.hex(), utext, cls))
        per_image[tag] = dict(sites=len(sites), reloc_excluded=reloc,
                              errors=dict(errs), **c)
        print("%-26s sites=%7d reloc_excl=%6d  %s"
              % (tag, len(sites), reloc,
                 " ".join("%s=%d" % kv for kv in sorted(c.items()))))

    # ---- D: can the backend assemble unidasm's own text? -----------------
    # dedupe on the exact unidasm text; keep one representative's bytes
    rep = {}
    sitecount = collections.Counter()
    for tag, mnem, ops, hx, utext, cls in all_rows:
        if cls in ("UNIDASM_DB", "UNIDASM_NOLINE") or not utext:
            continue
        sitecount[utext] += 1
        rep.setdefault(utext, (mnem, ops, hx))
    cands = sorted(rep)
    print("\nre-assembly test: %d distinct unidasm spellings covering %d sites"
          % (len(cands), sum(sitecount.values())))
    conv = {}
    for c in cands:
        conv[c] = uni_to_llvm(c)[0]
    lines = [conv[c] for c in cands]
    got = reassemble(lines, work)
    got2 = reassemble(lines, work, pc_shift=0x123)
    # unidasm prints an ABSOLUTE TARGET for these; the tree writes a LABEL.
    # Neither side's number is comparable as text, so they are their own class
    # rather than a disagreement.
    BRANCH = {"jr", "jrl", "calr", "djnz"}
    dcount = collections.Counter()
    dsites = collections.Counter()
    detail = []
    for c in cands:
        want = bytes.fromhex(rep[c][2])
        g = got.get(conv[c])
        g2 = got2.get(conv[c])
        if c.split(None, 1)[0].lower() in BRANCH:
            k = "UNI_BRANCH_TARGET"  # not comparable as text; see above
        elif g is not None and g2 is not None and g != g2:
            k = "UNI_PCREL"          # live control: must stay 0, see reassemble()
        elif g is None:
            k = "UNI_REJECTS"
        elif g == "RELOC":
            k = "UNI_RELOC"
        elif g == want:
            k = "UNI_ASSEMBLES_SAME"
        else:
            k = "UNI_ASSEMBLES_DIFF"
        dcount[k] += 1
        dsites[k] += sitecount[c]
        detail.append((k, c, conv[c], rep[c][0], rep[c][2],
                       "" if not isinstance(g, bytes) else g.hex(),
                       sitecount[c]))
    print("%-22s %10s %10s" % ("verdict", "spellings", "sites"))
    for k in ("UNI_ASSEMBLES_SAME", "UNI_ASSEMBLES_DIFF", "UNI_REJECTS",
              "UNI_RELOC", "UNI_BRANCH_TARGET", "UNI_PCREL"):
        print("%-22s %10d %10d" % (k, dcount[k], dsites[k]))

    # ---- E: is either syntax AMBIGUOUS?  (the control, and the crux) -----
    # For each distinct printed text, how many DISTINCT byte strings in this
    # corpus print that way?  A text that stands for more than one encoding
    # cannot be re-assembled to the original bytes -- it is a rendering, not a
    # source language.  The tree's own LLVM text is measured the same way as
    # the control: it MUST be 1-to-1, because the byte gate depends on it.
    uni_enc = collections.defaultdict(set)
    llvm_enc = collections.defaultdict(set)
    uni_sites = collections.Counter()
    llvm_sites = collections.Counter()
    for tag, mnem, ops, hx, utext, cls in all_rows:
        line = (mnem + " " + ops).strip()
        llvm_enc[line].add(hx)
        llvm_sites[line] += 1
        if utext and cls not in ("UNIDASM_NOLINE",):
            uni_enc[utext].add(hx)
            uni_sites[utext] += 1

    def ambiguity(enc, sites, label):
        amb = {k: v for k, v in enc.items() if len(v) > 1}
        amb_sites = sum(sites[k] for k in amb)
        print("%-26s distinct texts=%7d  ambiguous texts=%6d  sites under them=%8d"
              % (label, len(enc), len(amb), amb_sites))
        return amb, amb_sites

    print()
    uamb, uamb_sites = ambiguity(uni_enc, uni_sites, "unidasm text")
    lamb, lamb_sites = ambiguity(llvm_enc, llvm_sites, "this tree's LLVM text")

    with open(os.path.join(a.out, "oracle_ab_ambiguous_unidasm.csv"), "w") as f:
        f.write("unidasm_text,n_encodings,sites,encodings\n")
        for k in sorted(uamb, key=lambda k: -uni_sites[k]):
            f.write("\"%s\",%d,%d,%s\n" % (k, len(uamb[k]), uni_sites[k],
                                            "|".join(sorted(uamb[k]))))
    with open(os.path.join(a.out, "oracle_ab_ambiguous_llvm.csv"), "w") as f:
        f.write("llvm_text,n_encodings,sites,encodings\n")
        for k in sorted(lamb, key=lambda k: -llvm_sites[k]):
            f.write("\"%s\",%d,%d,%s\n" % (k, len(lamb[k]), llvm_sites[k],
                                            "|".join(sorted(lamb[k]))))

    with open(os.path.join(a.out, "oracle_ab_per_image.json"), "w") as f:
        json.dump(per_image, f, indent=1)
    with open(os.path.join(a.out, "oracle_ab_sites.csv"), "w") as f:
        f.write("image,llvm_mnemonic,llvm_operands,bytes,unidasm_text,class\n")
        for r in all_rows:
            f.write("%s,%s,\"%s\",%s,\"%s\",%s\n" % r)
    with open(os.path.join(a.out, "oracle_ab_reassembly.csv"), "w") as f:
        f.write("verdict,unidasm_text,candidate_line,llvm_mnemonic,want_bytes,got_bytes,sites\n")
        for r in sorted(detail, key=lambda x: (-x[6], x[0])):
            f.write("%s,\"%s\",\"%s\",%s,%s,%s,%d\n" % r)
    with open(os.path.join(a.out, "oracle_ab_totals.json"), "w") as f:
        json.dump(dict(llvm_mc_sha256=mc_sha, llvm_project_head=llvm_head,
                       unidasm_sha256=uni_sha,
                       reassembly_spellings=dict(dcount),
                       reassembly_sites=dict(dsites),
                       unidasm_distinct_texts=len(uni_enc),
                       unidasm_ambiguous_texts=len(uamb),
                       unidasm_ambiguous_sites=uamb_sites,
                       llvm_distinct_texts=len(llvm_enc),
                       llvm_ambiguous_texts=len(lamb),
                       llvm_ambiguous_sites=lamb_sites), f, indent=1)
    print("\nwrote %s/oracle_ab_*.csv" % a.out)


if __name__ == "__main__":
    sys.exit(main())
