#!/usr/bin/env python3
r"""Regenerate the v7 copies of the 0x41A-DISPLACED midi files from v10's structure.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
In v7, `midi/midi_serial_routines.s`, `midi/midi_dispatch_handlers.s` and
`midi/midipkt_routines.s` reproduce the ROM byte-exactly but describe it
wrongly: 28 KB of it is `.byte` plus 26 verbatim romslices, and every label
sits 0x41A bytes PAST the code it names.  Measured 2026-09-25 (midi lane):

  * a 12-byte n-gram alignment of v7 0xFCED00-0xFDA600 against v10 finds every
    matching run at ONE delta, v10 = v7 + 0x7D1 (20 KB of exact matches; the
    gaps between runs are absolute call/jump operands, which differ between
    the versions) -- so v7 holds the same code, in the same order, with the
    same instruction lengths;
  * the v7 labels are at v10 - 0x3B7, i.e. 0x41A after the real routine:
    e.g. v7 `MidiPkt_ArpConfigChain_Data` is at 0xFD7356 but the bytes of
    v10's routine of that name (0xFD770D: `1e 0c 00 1e 7a 00 ...`) are at v7
    0xFD6F3C; the file boundaries are displaced the same way (the first 0x41A
    bytes of real v7 serial code sit at the end of audio/sndparam_routines.s,
    and the last 0x41A bytes of v7 midipkt_routines.s are v10
    dsp_config_sysex.s code).

This tool rewrites the three v7 files, WITHIN THEIR CURRENT ADDRESS RANGES
(file boundaries are other lanes' business), line by line from the v10 line
that emits the corresponding bytes (v10 address = v7 address + 0x7D1):

  code   v7's own bytes are decoded (llvm-objdump, one section per line so a
         bad line cannot desync the next) and must be ONE instruction of the
         v10 line's length; the spelling is re-encoded and must give v7's
         bytes; v10's text is reused verbatim when the bytes are identical and
         it names no symbol.  Otherwise the line becomes `.byte` with a note.
  data   v7's own bytes, in the v10 line's directive type; `.long` values are
         named only by labels this tool places (below) or by a v7 symbol with
         the same name v10 uses.
  labels v10's label names are placed at v7 = v10 - 0x7D1 when that name is
         not defined in any OTHER v7 file.  v7 labels that another v7 file
         references are KEPT at their current (displaced) addresses -- moving
         them would change the bytes of those references -- and get a comment
         naming the v10 routine that is really at that address.  All other
         v7 labels of these files (unreferenced, displaced) are dropped.
  comments  the v7 files' own comments are kept (file headers, the one block
         comment, the trailer); v10's headers are carried over (their
         addresses are v10's -- a note at the top of each file says so).

Then the v7 image is rebuilt and must be byte-identical to the dump, or every
file is restored.

RUN (repo root, after `make all`)
    python3 scripts/tools/midi_lane_v7_from_v10.py [--dry-run]
    # an ALIGNED file (v7 labels correct) with its own delta, e.g. the PcgOut
    # romslice in computer_interface_pcg.s (v10 = v7 + 0x404 there):
    python3 scripts/tools/midi_lane_v7_from_v10.py --delta 0x404 \
        --v7file midi/computer_interface_pcg.s --v10file midi/computer_interface_pcg.s
"""
import argparse
import collections
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import midi_lane_rewrite as rw  # noqa: E402

drc = rw.drc
ROOT = rw.ROOT
DELTA = 0x7D1
BASE = rw.BASE
V7FILES = ["midi/midi_serial_routines.s", "midi/midi_dispatch_handlers.s", "midi/midipkt_routines.s"]
V10FILES = ["midi/midi_serial_routines.s", "midi/midi_dispatch_handlers.s", "midi/midipkt_routines.s",
            "audio/dsp_config_sysex.s"]
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
IDENT = re.compile(r"(?<![\w.$])([A-Za-z_][\w.$]*)")
REGS = set("""a w c b e d l h ia iw ic ib ie id il ih wa bc de hl ix iy iz sp xwa xbc xde xhl
xix xiy xiz xsp qwa qbc qde qhl qix qiy qiz qsp qa qw qc qb qe qd ql qh sr f pc
t z nz c nc lt le gt ge ule ugt ov nov mi pl eq ne ult uge
opc i3 io f_ ixl ixh iyl iyh izl izh spl sph""".split())


def split_line(t):
    """-> (labels, stmt, trailing_comment)"""
    code = drc.strip_comment(t)
    tail = t[len(code):]
    rest = code.strip()
    labs = []
    while True:
        m = LABEL_RE.match(rest)
        if not m:
            break
        labs.append(m.group(1))
        rest = rest[m.end():].strip()
    return labs, rest, tail.strip()


def v10_items(la10):
    items = {}
    for rel in V10FILES:
        L = open(os.path.join(ROOT, "v10/maincpu", rel), encoding="latin-1").read().split("\n")
        A = la10[rel]
        pend_l, pend_c = [], []
        emit = [i for i, t in enumerate(L)
                if A[i] is not None and drc.classify_line(t, {})[0] in ("code", "data", "fill")]
        nxt = {}
        for k, i in enumerate(emit):
            nxt[i] = A[emit[k + 1]] if k + 1 < len(emit) else None
        for i, t in enumerate(L):
            labs, stmt, tail = split_line(t)
            kind = drc.classify_line(t, {})[0]
            if kind in ("code", "data", "fill") and A[i] is not None:
                n = (nxt[i] - A[i]) if nxt[i] is not None else None
                items[A[i]] = dict(addr=A[i], len=n, kind=kind, stmt=stmt, tail=tail,
                                   labels=pend_l + labs, comments=pend_c, rel=rel, line=i + 1)
                pend_l, pend_c = [], []
            else:
                pend_l += labs
                s = t.strip()
                if s.startswith(";") and not labs:
                    pend_c.append(t.rstrip())
                elif not s and pend_c:
                    pend_c.append("")
    # a line's length runs to the next emitting line of ANY loaded file (a
    # file's last line is followed by the first line of the next file)
    order = sorted(items)
    for k, ad in enumerate(order):
        items[ad]["len"] = (order[k + 1] - ad) if k + 1 < len(order) else None
    return items


def objdump_sections(chunks):
    """chunks: list of bytes -> list of [(len, text)] per chunk (one section each)."""
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "d.s")
        o = os.path.join(td, "d.o")
        with open(s, "w") as f:
            for k, b in enumerate(chunks):
                f.write('.section .c%d,"ax"\n.byte %s\n' % (k, ",".join("0x%02x" % x for x in b)))
        subprocess.run([rw.MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s], check=True)
        out = subprocess.run([os.path.join(rw.LLVM, "llvm-objdump"), "-d", "-z", o],
                             capture_output=True, text=True, check=True).stdout
    res = [[] for _ in chunks]
    cur = None
    pat = re.compile(r"^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$")
    for line in out.split("\n"):
        m = re.match(r"^Disassembly of section \.c(\d+):", line)
        if m:
            cur = int(m.group(1))
            continue
        m = pat.match(line)
        if m and cur is not None:
            raw = m.group(2).split()
            text = m.group(3).strip()
            res[cur].append((len(raw), None if text.startswith("<unknown>") else re.sub(r"\s+", " ", text, count=1)))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--delta", help="v10 - v7 address delta for these files (default 0x7D1)")
    ap.add_argument("--v7file", action="append", help="v7 files to regenerate (default: the 3 displaced ones)")
    ap.add_argument("--v10file", action="append", help="v10 files supplying the structure")
    ap.add_argument("--range", nargs=2, metavar=("START", "END"),
                    help="ONLY re-express v7 [START, END) of the (single) --v7file, splicing the "
                         "rest of the file untouched -- for an aligned file where one romslice "
                         "or `.byte` run is the only problem")
    a = ap.parse_args()
    global DELTA, V7FILES, V10FILES
    if a.delta:
        DELTA = int(a.delta, 0)
    if a.v7file:
        V7FILES = a.v7file
    if a.v10file:
        V10FILES = a.v10file
    la10, rom10 = rw.line_addresses("v10", V10FILES)
    la7, rom7 = rw.line_addresses("v7", V7FILES)
    items = v10_items(la10)
    syms7 = rw.elf_symbols("v7")
    # every name defined in the v7 tree, and where
    v7root = os.path.join(ROOT, "v7/maincpu")
    defined_other = set()
    refs = collections.defaultdict(set)
    mine_labels = {}
    for dp, _, fn in os.walk(v7root):
        for f in fn:
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, v7root)
            for t in open(p, encoding="latin-1"):
                labs, stmt, _ = split_line(t)
                m = re.match(r"^\.(set|equ)\s+([A-Za-z_][\w.$]*)\s*,", stmt)
                if m:
                    (defined_other if rel not in V7FILES else set()).add(m.group(2))
                    stmt = stmt[m.end():]
                for l in labs:
                    if rel in V7FILES:
                        mine_labels[l] = rel
                    else:
                        defined_other.add(l)
                for tok in IDENT.findall(stmt):
                    refs[tok].add(rel)
    kept = {n for n in mine_labels if refs[n] - set(V7FILES)}
    syms10 = {}
    for ad, nm in rw.elf_symbols("v10").items():
        syms10.setdefault(nm, ad)
    # addresses of kept labels (current, displaced)
    kept_addr = {}
    for rel in V7FILES:
        L = open(os.path.join(v7root, rel), encoding="latin-1").read().split("\n")
        for i, t in enumerate(L):
            labs, _, _ = split_line(t)
            for l in labs:
                if l in kept:
                    kept_addr[l] = la7[rel][i]
    # the new label map (v7 address -> v10 names allowed here)
    newlab = {}
    for ad10, it in items.items():
        for n in it["labels"]:
            if n in defined_other or n in kept:
                continue
            newlab.setdefault(ad10 - DELTA, []).append(n)
    name_at = {ad: ns[0] for ad, ns in newlab.items()}
    for n, ad in kept_addr.items():
        name_at.setdefault(ad, n)
    all_new_names = {n for ns in newlab.values() for n in ns}

    def v7name_for(value, v10name=None):
        if value in name_at:
            return name_at[value]
        if v10name and syms7.get(value) == v10name:
            return v10name
        return None

    stats = collections.Counter()
    plans = {}
    if a.range:
        return ranged(a, items, la7, rom7, rom10, syms7, defined_other, mine_labels)
    for rel in V7FILES:
        path = os.path.join(v7root, rel)
        raw = open(path, "rb").read()
        L = raw.decode("latin-1").split("\n")
        A = la7[rel]
        emit = [i for i, t in enumerate(L) if A[i] is not None and
                drc.classify_line(t, {})[0] in ("code", "data", "fill")]
        s7 = A[emit[0]]
        last = emit[-1]
        e7 = next((A[j] for j in range(last + 1, len(A)) if A[j] is not None and A[j] > A[last]), None)
        if e7 is None:     # the file's last line: its end is where the next file starts
            _, st, _ = split_line(L[last])
            m = re.match(r'^\.incbin\s+"([^"]+)"', st)
            if m:
                e7 = A[last] + os.path.getsize(os.path.join(v7root, m.group(1)))
            else:
                e7 = sorted(v for v in syms7 if v > A[last])[0]
        # v7 comments to keep: file header (before the first emitting line) and
        # any comment line below it, at its own address
        head = []
        for t in L[:emit[0]]:
            s = t.strip()
            if s.startswith(";") or not s:
                head.append(t.rstrip())
        keep_c = collections.defaultdict(list)
        for i in range(emit[0], len(L)):
            s = L[i].strip()
            labs, st, tl = split_line(L[i])
            nonemit = drc.classify_line(L[i], {})[0] == "none"
            if s.startswith(";") or (nonemit and st.startswith(".")):
                # comments, and directives that emit nothing (`.include` above all)
                keep_c[A[i] if A[i] is not None else e7].append(L[i].rstrip())
        # walk v7 addresses
        seq = []    # (addr, kind, payload)
        p = s7
        pending_bytes = []
        kept_here = {ad for n, ad in kept_addr.items() if mine_labels[n] == rel}
        while p < e7:
            if p in kept_here:
                pending_bytes = []
            it = items.get(p + DELTA)
            if it is None or it["len"] is None or p + it["len"] > e7:
                if not pending_bytes:
                    seq.append((p, "raw", pending_bytes))
                pending_bytes.append(rom7[p - BASE])
                p += 1
                stats["raw_B"] += 1
                continue
            pending_bytes = []
            seq.append((p, "item", it))
            p += it["len"]
        plans[rel] = dict(path=path, raw=raw, head=head, keep_c=keep_c, seq=seq, s7=s7, e7=e7, L=L)
    # only names that WILL be placed (their v7 address is an item start inside
    # one of the three files) may be used as operands
    placeable = {q for pl in plans.values() for q, kind, _ in pl["seq"] if kind == "item"}
    for ad in list(newlab):
        if ad not in placeable:
            del newlab[ad]
    name_at.clear()
    name_at.update({ad: ns[0] for ad, ns in newlab.items()})
    for n, ad in kept_addr.items():
        name_at.setdefault(ad, n)
    all_new_names.clear()
    all_new_names.update(n for ns in newlab.values() for n in ns)
    # decode every code item of every file in one objdump run
    code_idx = []
    for rel, pl in plans.items():
        for k, (p, kind, it) in enumerate(pl["seq"]):
            if kind == "item" and it["kind"] == "code" and not it["stmt"].startswith("."):
                code_idx.append((rel, k, p, it))
    decoded = objdump_sections([rom7[p - BASE:p - BASE + it["len"]] for _, _, p, it in code_idx])
    dmap = {}
    for (rel, k, p, it), d in zip(code_idx, decoded):
        dmap[(rel, k)] = d
    # candidate spellings, verified in one batch
    cand = []
    for (rel, k, p, it), d in zip(code_idx, decoded):
        if len(d) == 1 and d[0][0] == it["len"] and d[0][1]:
            text = d[0][1]
            c = rw.canon(text)
            opts = []
            if rw.REL_BR.match(text.split()[0]) or rw.ABS_BR.match(text.split()[0]):
                opts = [text]
            else:
                for t in ([rw.hexify(c), c] if c else []) + [re.sub(r":(opc|i3)\b", "", rw.hexify(text)),
                                                              rw.hexify(text), text]:
                    if t not in opts:
                        opts.append(t)
            for t in opts:
                cand.append(((rel, k), t))
    enc = rw.encodings([t for _, t in cand])
    good = {}
    for (key, t), e in zip(cand, enc):
        rel, k = key
        p = plans[rel]["seq"][k][0]
        it = plans[rel]["seq"][k][2]
        if key not in good and e == list(rom7[p - BASE:p - BASE + it["len"]]):
            good[key] = t

    def render_item(rel, k, p, it):
        n = it["len"]
        b7 = rom7[p - BASE:p - BASE + n]
        b10 = rom10[it["addr"] - BASE:it["addr"] - BASE + n]
        stmt, tail = it["stmt"], it["tail"]
        idents = [x for x in IDENT.findall(stmt.split(None, 1)[1] if " " in stmt or "\t" in stmt else "")
                  if x.lower() not in REGS]
        if it["kind"] in ("data", "fill") or stmt.startswith("."):
            d = stmt.split()[0].lower() if stmt else ""
            if b7 == b10 and not idents:
                stats["data_same"] += n
                return "\t" + stmt + (("\t" + tail) if tail else "")
            if d == ".long" and n % 4 == 0:
                vals = []
                v10names = [x for x in idents]
                for j in range(0, n, 4):
                    v = int.from_bytes(b7[j:j + 4], "little")
                    nm = v7name_for(v, v10names[j // 4] if j // 4 < len(v10names) else None)
                    vals.append(nm if nm else "0x%08x" % v)
                stats["data_long"] += n
                return "\t.long " + ", ".join(vals)
            if d in (".short", ".word", ".2byte") and n % 2 == 0:
                stats["data_short"] += n
                return "\t.short " + ", ".join("0x%04x" % int.from_bytes(b7[j:j + 2], "little")
                                               for j in range(0, n, 2))
            stats["data_bytes"] += n
            note = "" if b7 == b10 else "\t; v7 bytes; v10 has: %s" % stmt[:60]
            if b7 == b10 and tail:
                note = "\t" + tail
            return "\t.byte " + ", ".join("0x%02x" % x for x in b7) + note
        # code
        if b7 == b10 and not idents:
            stats["code_same"] += n
            return "\t" + stmt + (("\t" + tail) if tail else "")
        key = (rel, k)
        if key in good:
            t = good[key]
            text = dmap[key][0][1]
            tgt = rw.branch_target(text, p, n)
            v10n = idents[-1] if idents else None
            if tgt is not None:
                nm = v7name_for(tgt, v10n)
                if nm:
                    t = re.sub(r"(-?(0x)?[0-9a-f]+)$", nm, t)
            else:
                for m in re.finditer(r"(?<![\w(])(0x[0-9a-f]{6}|\d{7,8})(?![\w:])", t):
                    v = int(m.group(1), 0)
                    if BASE <= v < BASE + 0x200000:
                        nm = v7name_for(v, v10n)
                        if nm:
                            t = t[:m.start()] + nm + t[m.end():]
                        break
            mn, _, ops = t.replace("\t", " ").partition(" ")
            stats["code_decoded"] += n
            return "\t" + mn + ("\t" + ops.strip() if ops.strip() else "")
        stats["code_bytes"] += n
        return "\t.byte " + ", ".join("0x%02x" % x for x in b7) + \
            "\t; v7 bytes do not decode as v10's `%s`" % stmt[:50]

    placed = set()
    for rel, pl in plans.items():
        out = list(pl["head"])
        out += [";",
                "; v7 REGENERATED FROM v10's STRUCTURE (midi lane, 2026-09-25,",
                "; scripts/tools/midi_lane_v7_from_v10.py): every line below was derived",
                "; from the v10 line emitting the same bytes at v10 = v7 + 0x%X, with v7's" % DELTA,
                "; own bytes decoded and re-encoded.  Addresses quoted in carried-over",
                "; headers are v10's."]
        if any(mine_labels[n] == rel for n in kept_addr):
            out += ["; Labels marked `v7 NAME DISPLACED` are the old v7 names, kept because",
                    "; another v7 file references them; see that note."]
        out += [";"]
        last_lab = None
        inside = collections.defaultdict(list)     # item start -> kept labels strictly inside it
        starts = [q for q, _, _ in pl["seq"]]
        import bisect
        for n, ad in kept_addr.items():
            if mine_labels[n] != rel:
                continue
            j = bisect.bisect_right(starts, ad) - 1
            if j >= 0 and starts[j] != ad:
                inside[starts[j]].append((n, ad))
        for k, (p, kind, payload) in enumerate(pl["seq"]):
            # v7 comments go before the line that CONTAINS their old address (the
            # old framing's boundaries are not the new ones)
            n_here = payload["len"] if kind == "item" else len(payload)
            for ad in sorted(x for x in pl["keep_c"] if p <= x < p + max(n_here, 1)):
                for c in pl["keep_c"].pop(ad):
                    out.append(c)
                    if "rather than re-sliced from the ROM each build." in c:
                        out.append("\t; (midi lane 2026-09-25: no longer a romslice -- these bytes are the MIDI")
                        out.append("\t; receive mapping tables (here MidiCC_PartTargets_CC93_Chorus), typed from v10's layout by")
                        out.append("\t; scripts/tools/midi_lane_v7_from_v10.py.)")
            for n, ad in kept_addr.items():
                if ad == p and n not in placed and mine_labels[n] == rel:
                    v10n = next((x for x in items.get(p + DELTA, {}).get("labels", [])), None)
                    out.append("; v7 NAME DISPLACED: `%s` sits where v10 has %s (v10 0x%06X)."
                               % (n, "`%s`" % v10n if v10n else "no label", p + DELTA))
                    if n in syms10 and syms10[n] - DELTA == p - 0x41A:
                        out.append("; The v7 code v10 calls `%s` is 0x41A earlier, at v7 0x%06X."
                                   % (n, p - 0x41A))
                    elif n in syms10:
                        out.append("; v10 defines `%s` at 0x%06X." % (n, syms10[n]))
                    out.append("; Kept because another v7 file references this address by this name.")
                    out.append(n + ":")
                    placed.add(n)
                    last_lab = (n, p)
            if kind == "raw":
                bs = payload
                if k == 0:
                    out.append("; The first bytes of this file are the TAIL of an instruction whose head")
                    out.append("; is the last bytes of the previous file: the v7 file boundary sits 0x41A")
                    out.append("; bytes off the v10 one, so it cuts an instruction.")
                elif k == len(pl["seq"]) - 1:
                    out.append("; The last bytes of this file are the HEAD of an instruction that the next")
                    out.append("; file finishes (the v7 file boundary cuts it; see the note at the top).")
                for j in range(0, len(bs), 12):
                    out.append("\t.byte " + ", ".join("0x%02x" % x for x in bs[j:j + 12]))
            else:
                it = payload
                for c in it["comments"]:
                    out.append(c)
                for n in it["labels"]:
                    if n in all_new_names and n not in placed:
                        out.append(n + ":")
                        placed.add(n)
                        last_lab = (n, p)
                out.append(render_item(rel, k, p, it))
            # a kept (referenced) v7 name that falls INSIDE this line in the
            # correct framing: keep its exact address as an alias of the last
            # label, so the other file's `.long NAME + k` keeps its bytes
            for n, ad in inside.get(p, []):
                if last_lab is None:
                    continue
                v10n = next((x for x in items.get(ad + DELTA, {}).get("labels", [])), None)
                out.append("; v7 NAME DISPLACED: `%s` (0x%06X) falls inside the line above in the" % (n, ad))
                out.append("; correct framing (v10 0x%06X%s).  Kept as an alias because another v7" %
                           (ad + DELTA, ", `%s`" % v10n if v10n else ""))
                out.append("; file references this address by this name.")
                out.append("\t.set %s, %s + %d" % (n, last_lab[0], ad - last_lab[1]))
                placed.add(n)
        for ad in sorted(pl["keep_c"]):
            out += pl["keep_c"][ad]
        pl["out"] = out
    missing = [n for n in kept_addr if n not in placed]
    print("kept (referenced) v7 labels: %d, placed: %d, NOT placed: %s" %
          (len(kept_addr), len(kept_addr) - len(missing), missing[:20]))
    print("new v10-named labels available: %d, placed: %d" % (len(all_new_names), len(placed) - (len(kept_addr) - len(missing))))
    print("bytes:", dict(stats))
    if missing:
        sys.exit("REFUSED: kept labels fall inside an item (see list)")
    if a.dry_run:
        for rel, pl in plans.items():
            dst = "/tmp/claude-1000/lane-midi/v7gen_" + os.path.basename(rel)
            open(dst, "wb").write("\n".join(pl["out"]).encode("latin-1"))
            print("dry-run: wrote", dst)
        return
    for rel, pl in plans.items():
        txt = "\n".join(pl["out"]) + "\n"
        open(pl["path"], "wb").write(txt.encode("latin-1"))   # every line was read as latin-1
    if not rw.verify("v7"):
        for rel, pl in plans.items():
            open(pl["path"], "wb").write(pl["raw"])
        sys.exit("REJECTED: rebuilt v7 differs from the dump; all three files restored")
    print("VERIFIED: rebuilt v7 is byte-identical to the dump")


def ranged(a, items, la7, rom7, rom10, syms7, defined_other, mine_labels):
    """Re-express only v7 [START, END) of one file, from the v10 lines at +DELTA."""
    rel = V7FILES[0]
    st, en = int(a.range[0], 0), int(a.range[1], 0)
    taken = defined_other | set(mine_labels)
    newlab = {}
    for ad10, it in items.items():
        if st <= ad10 - DELTA < en:
            for n in it["labels"]:
                if n not in taken:
                    newlab.setdefault(ad10 - DELTA, []).append(n)
    syms = dict(syms7)
    for ad, ns in newlab.items():
        syms[ad] = ns[0]
    out, p = [], st
    while p < en:
        it = items.get(p + DELTA)
        if it is None or it["len"] is None or p + it["len"] > en:
            sys.exit("REFUSED: v10 has no line starting at 0x%X (v7 0x%X)" % (p + DELTA, p))
        for c in it["comments"]:
            out.append((p, c))
        for n in newlab.get(p, []):
            out.append((p, n + ":"))
        n = it["len"]
        b7, b10 = rom7[p - BASE:p - BASE + n], rom10[p + DELTA - BASE:p + DELTA - BASE + n]
        if it["kind"] == "code" and not it["stmt"].startswith("."):
            r = rw.render_code(rom7, p, p + n, [], syms)
            if len(r) != 1:
                sys.exit("REFUSED: v7 0x%X does not decode as one instruction like v10's `%s`" % (p, it["stmt"]))
            out.append(r[0])
        elif b7 == b10:
            out.append((p, "\t" + it["stmt"] + (("\t" + it["tail"]) if it["tail"] else "")))
        else:
            out.append((p, "\t.byte " + ", ".join("0x%02x" % x for x in b7)))
        p += n
    path = os.path.join(ROOT, "v7/maincpu", rel)
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    lines, _, dropped = rw.splice(lines, la7[rel], st, en, out, {})
    print("v7 %s 0x%X..0x%X -> %d lines, %d new labels" % (rel, st, en, len(out), len(newlab)))
    if a.dry_run:
        for ad, t in out[:60]:
            print("   %06X %s" % (ad, t))
        return
    open(path, "wb").write("\n".join(lines).encode("latin-1"))
    if not rw.verify("v7"):
        open(path, "wb").write(raw)
        sys.exit("REJECTED: rebuilt v7 differs; restored")
    print("VERIFIED: rebuilt v7 is byte-identical to the dump")


if __name__ == "__main__":
    main()
