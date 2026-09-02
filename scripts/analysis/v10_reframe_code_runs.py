#!/usr/bin/env python3
"""Question answered: which `.byte` runs inside CODE can be re-spelled as
correctly framed instructions by the current backend, and how many bytes of
wrong framing does each one hide?

Why a `.byte` inside code is worse than it looks.  These sources were produced
by an earlier toolchain that could not encode several TLCS-900 forms (the
`ld_rrl` / `ld_sril3` indexed-load family above all).  Where it hit one it
emitted `.byte <first opcode byte>` and then RESUMED DECODING ONE BYTE LATER --
so the two or three "instructions" printed after the `.byte` are the tail of
the real instruction re-read at the wrong offset.  They re-assemble to the same
bytes, so `make gate-all` cannot see them.  A file can therefore be 100%
byte-exact and still describe instructions the CPU never executes.

Method.  For each label-delimited region that contains a `.byte`:

  1. Refuse the region outright if the pointer-array test of
     v10_byte_run_classifier.py fires on it -- data disassembles into plausible
     instructions and would be entrenched as code by this pass.  That test's
     measured false-DATA rate on known-code regions is reported by
     `v10_byte_run_classifier.py --control`.
  2. Linear-sweep the region from its label (a label address is an instruction
     boundary: something references it) with `llvm-mc -disassemble`.
  3. For each maximal `.byte` run, take the smallest span [A,B) such that A and
     B are BOTH a source-line address AND a sweep boundary.  Requiring the
     sweep to re-converge on the existing framing on both sides is the check
     that the sweep is right and the source is wrong, rather than the reverse.
  4. Refuse the span if the sweep leaves any byte in it undecodable.
  5. Emit the sweep's instructions for [A,B), preserving any comment lines that
     were inside it, and preserving symbolic operands where an operand value
     is exactly a defined label address.

Everything is then verified by rebuilding the whole image byte-for-byte
(v10_reframe.py's verify()), and finally by `make gate-all`.

WHERE THIS CAN STILL BE WRONG: it cannot turn data into code -- it only
re-frames spans the tree ALREADY spells as instructions -- but if the tree was
already wrong about a span being code, this pass makes that error tidier
rather than fixing it. It is a framing fix, not a reachability proof.

Exact commands (from the repo root):

    python3 scripts/analysis/v10_line_address_map.py <file.s> --out /tmp/lm.json
    python3 scripts/analysis/v10_reframe_code_runs.py --linemap /tmp/lm.json \
        --report <file.s>                 # measure only, touch nothing
    python3 scripts/analysis/v10_reframe_code_runs.py --linemap /tmp/lm.json \
        --apply <file.s>                  # rewrite, then verify byte-identity
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v10_byte_run_classifier as C
import v10_reframe as R

ROM_BASE = 0xE00000
ROOT = R.ROOT

# Leading opcode bytes with no decode in the backend, which MAME's unidasm
# decodes as real TLCS-900 instructions.  They are BACKEND GAPS, not reserved
# silicon -- see byte_run_start_enrichment.py and
# notes/DEBT-INVENTORY-2026-09-02.md.  The set started as
# {0x01, 0x04, 0x17, 0x1a, 0x1c}; tlcs900_backend 6f456a19f05b added ldf (0x17),
# jp16 (0x1a) and call16 (0x1c) while this lane was running, leaving 0x01
# (normal) and 0x04 (max).  RE-CHECK THIS SET against the installed decoder
# before quoting any number from this script -- the exact command is in
# leading_byte_reserved_probe.py.  A span that would swallow one of these into
# an operand is refused: that reading round-trips through the byte gate and is
# still wrong, and two of the original five were control flow.
BLIND = {0x01, 0x04}


def sweep(rom, a, b):
    """-> (boundaries set, {addr: text}, set of undecodable addrs)"""
    data = rom[a - ROM_BASE:b - ROM_BASE]
    segs = R.disassemble(data)
    bounds, texts, bad = set(), {}, set()
    off = a
    for n, text in segs:
        bounds.add(off)
        texts[off] = (n, text)
        if text.strip().startswith(".byte"):
            bad.add(off)
        off += n
    bounds.add(b)
    return bounds, texts, bad


def byte_runs(lines, lm, ln0, ln1):
    """maximal runs of consecutive .byte source lines -> (first_line, last_line,
    start_addr, end_addr)"""
    runs, cur = [], None
    for i in range(ln0, ln1):
        s = lines[i - 1].strip()
        if s.startswith(".byte"):
            if cur is None:
                cur = [i, i]
            cur[1] = i
        elif s == "" or s.startswith(";"):
            continue
        else:
            if cur:
                runs.append(cur)
            cur = None
    if cur:
        runs.append(cur)
    out = []
    for f, l in runs:
        nxt = None
        for j in range(l + 1, ln1 + 40):
            if j in lm:
                nxt = lm[j]
                break
        if f in lm and nxt:
            out.append((f, l, lm[f], nxt))
    return out



def encode_map(texts):
    """text -> encoding bytes, for every instruction text the assembler accepts.

    The disassembler is NOT a bijection: it prints a few forms the assembler
    rejects (`and (xiz), sp`, `and sp, de`) and could in principle print a form
    that assembles to different bytes.  Both would sail past a per-instruction
    eyeball and be caught only by the whole-image gate, at which point the
    offending span is unknown.  So every distinct instruction text this pass
    wants to emit is assembled here first, and any span containing a text that
    is rejected -- or that re-encodes to different bytes -- is refused.
    """
    import tempfile
    texts = sorted(set(texts))
    bad = set()
    while True:
        cand = [t for t in texts if t not in bad]
        with tempfile.TemporaryDirectory() as td:
            src = os.path.join(td, "e.s")
            open(src, "w").write(".text\n" + "\n".join(cand) + "\n")
            r = subprocess.run([os.path.join(R.LLVM, "llvm-mc"), "-triple=tlcs900",
                                "-show-encoding", src],
                               capture_output=True, text=True)
        errs = set()
        for m in re.finditer(r"^\S+:(\d+):\d+: error:", r.stderr, re.M):
            errs.add(int(m.group(1)) - 2)   # -1 for .text, -1 for 1-based
        if not errs:
            encs = [bytes(int(x, 16) for x in m.group(1).replace("0x", "").split(","))
                    for m in re.finditer(r"encoding: \[([^\]]*)\]", r.stdout)]
            if len(encs) != len(cand):
                raise SystemExit("encode_map: %d encodings for %d texts"
                                 % (len(encs), len(cand)))
            return dict(zip(cand, encs)), bad
        for i in errs:
            if 0 <= i < len(cand):
                bad.add(cand[i])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--linemap", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    rom = R.rom_bytes()
    syms = R.elf_symbols()
    symnames = set(syms.values())
    maps = json.load(open(args.linemap))
    grand = [0, 0, 0, 0, 0]
    for rel in args.files:
        lm = {int(k): v for k, v in maps[rel].items()}
        path = os.path.join(ROOT, rel)
        lines, regions = C.parse(path, lm)
        edits = []   # [first_line, last_excl, newlines, bytes, bytedebt, addr]
        blocked = []  # (first_line, last_line, [blind byte values])
        blockers = {}  # undecodable byte value -> how many times it blocked a span
        stat = dict(conv=0, convb=0, reframed=0, refused=0, refusedb=0, data=0,
                        datab=0, lostsym=0, notround=0,
                        blind=0, blindb=0, absorb=0, absorbb=0, labelcross=0,
                        hasascii=0)
        for reg in regions:
            runs = byte_runs(lines, lm, reg["ln"], reg["end_line"])
            if not runs or reg["end"] <= reg["addr"]:
                continue
            data = rom[reg["addr"] - ROM_BASE:reg["end"] - ROM_BASE]
            prun, _, _ = C.ptr_run(data)
            if prun >= C.MIN_PTRS:
                stat["data"] += 1
                stat["datab"] += sum(C.byte_bytes(lines, f, l + 1) for f, l, _, _ in runs)
                continue
            bounds, texts, bad = sweep(rom, reg["addr"], reg["end"])
            lineaddr = sorted(set(lm[k] for k in lm if reg["ln"] <= k < reg["end_line"]))
            anchors = sorted(bounds & set(lineaddr))
            inv = {}
            for k in lm:
                if reg["ln"] <= k < reg["end_line"]:
                    inv.setdefault(lm[k], []).append(k)
            # --- collect one accepted address interval per run -------------
            cand = []
            for f, l, s, e in runs:
                nb = C.byte_bytes(lines, f, l + 1)
                lo = [x for x in anchors if x <= s]
                hi = [x for x in anchors if x >= e]
                if not lo or not hi:
                    stat["refused"] += 1
                    stat["refusedb"] += nb
                    continue
                A, B = lo[-1], hi[0]
                badhere = [x for x in bad if A <= x < B]
                if badhere:
                    blind = sorted({rom[x - ROM_BASE] for x in badhere} & BLIND)
                    if blind:
                        stat["blind"] += 1
                        stat["blindb"] += nb
                        blocked.append((f, l, blind))
                    else:
                        stat["refused"] += 1
                        stat["refusedb"] += nb
                        for x in badhere:
                            blockers[rom[x - ROM_BASE]] = \
                                blockers.get(rom[x - ROM_BASE], 0) + 1
                    continue
                # A span that SWALLOWS a blind byte into an instruction operand
                # is exactly the reading that would round-trip while being
                # wrong, so it waits for the backend to gain the five forms.
                if any(rom[x - ROM_BASE] in BLIND for x in range(A, B)
                       if x not in texts):
                    stat["absorb"] += 1
                    stat["absorbb"] += nb
                    continue
                cand.append((A, B, nb))
            # ⚠ Two runs a few bytes apart resolve to OVERLAPPING spans. Applying
            # both as separate line-range splices deletes whatever lies between
            # them -- that is how a first attempt at this pass silently dropped
            # 30 label definitions, caught by the LINKER (undefined symbol), not
            # by the byte gate. Merge to disjoint intervals before emitting.
            cand.sort()
            merged = []
            for A, B, nb in cand:
                if merged and A <= merged[-1][1]:
                    merged[-1][1] = max(merged[-1][1], B)
                    merged[-1][2] += nb
                else:
                    merged.append([A, B, nb])
            for A, B, nb in merged:
                first = min(inv[A])
                last = min(inv[B])
                # preserved lines: comments keep their position relative to the
                # next code line; a LABEL must land exactly on its own address,
                # and if the new framing does not have a boundary there the new
                # framing contradicts something that references the label, so
                # the whole span is refused.
                pre = {}
                pending = []
                conflict = False
                for i in range(first, last):
                    t = lines[i - 1]
                    st = t.strip()
                    if st.startswith(";") or st == "":
                        pending.append(t)
                    elif C.LABEL_RE.match(t):
                        ad = lm.get(i)
                        if ad is None or ad not in texts:
                            conflict = True
                            break
                        pre.setdefault(ad, []).extend(pending + [t])
                        pending = []
                    else:
                        ad = lm.get(i)
                        if pending and ad is not None:
                            pre.setdefault(ad, []).extend(pending)
                        pending = []
                if conflict:
                    stat["labelcross"] += 1
                    stat["refusedb"] += nb
                    continue
                new = []
                off = A
                while off < B:
                    new += pre.pop(off, [])
                    n, text = texts[off]
                    m = re.search(r"\b(\d{6,})\b", text)
                    if m and int(m.group(1)) in syms:
                        text = text.replace(m.group(1), syms[int(m.group(1))])
                    new.append(text)
                    off += n
                new += [x for k in sorted(pre) for x in pre[k]] + pending
                old_names = set()
                for i in range(first, last):
                    t = lines[i - 1].split(";")[0]
                    old_names |= {w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", t)
                                  if w in symnames}
                new_names = set()
                for t in new:
                    new_names |= {w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*",
                                                        t.split(";")[0])
                                  if w in symnames}
                # ⚠ REFUSE any span containing a string literal. The first run
                # of this pass re-framed 14 `.ascii` lines into instructions,
                # among them "TEMPO   ", "Y SHIFT=" and "ADE-IN ON OFF" -- real
                # UI text turned into fake code, byte-exact and invisible to the
                # gate. A string is evidence about the region that the decoder
                # does not have, so it wins.
                if any(lines[i - 1].strip().startswith((".ascii", ".asciz",
                                                        ".string"))
                       for i in range(first, last)):
                    stat["hasascii"] += 1
                    stat["refusedb"] += nb
                    continue
                if old_names - new_names:
                    # the re-frame would replace a symbolic operand with a bare
                    # number: that is a loss of information, so refuse it
                    stat["lostsym"] += 1
                    stat["refusedb"] += nb
                    continue
                edits.append([first, last, new, B - A, nb, A])
                stat["conv"] += 1
                stat["convb"] += nb
                stat["reframed"] += B - A
        # --- reject any edit whose text the assembler will not reproduce ---
        allt = [t for e in edits for t in e[2]
                if t.strip() and not t.strip().startswith(";")
                and not C.LABEL_RE.match(t)]
        emap, badtexts = encode_map(allt)
        kept = []
        for e in edits:
            ins = [t for t in e[2]
                   if t.strip() and not t.strip().startswith(";")]
            if any(t in badtexts for t in ins):
                stat["conv"] -= 1; stat["convb"] -= e[4]
                stat["reframed"] -= e[3]; stat["notround"] += 1
                stat["refusedb"] += e[4]
                continue
            ins = [t for t in ins if not C.LABEL_RE.match(t)]
            blob = b"".join(emap[t] for t in ins)
            if blob != rom[e[5] - ROM_BASE:e[5] - ROM_BASE + e[3]]:
                stat["conv"] -= 1; stat["convb"] -= e[4]
                stat["reframed"] -= e[3]; stat["notround"] += 1
                stat["refusedb"] += e[4]
                continue
            kept.append(e)
        edits = kept
        print("%s\n"
              "  (a) converted            %4d spans, %5d B of .byte, %6d B re-framed\n"
              "  (b) in-data, left to the data pass  %4d regions, %5d B\n"
              "  (d) blocked on a backend gap        %4d runs,    %5d B\n"
              "      would swallow a blind byte      %4d runs,    %5d B\n"
              "  refused: %d undecodable, %d symbol-losing, %d not-round-tripping,\n"
              "           %d label-crossing, %d string-containing  (%d B total)"
              % (os.path.basename(rel), stat["conv"], stat["convb"],
                 stat["reframed"], stat["data"], stat["datab"],
                 stat["blind"], stat["blindb"], stat["absorb"], stat["absorbb"],
                 stat["refused"], stat["lostsym"], stat["notround"],
                 stat["labelcross"], stat["hasascii"], stat["refusedb"]))
        top = sorted(blockers.items(), key=lambda kv: -kv[1])[:12]
        print("      undecodable byte values that blocked a span: "
              + ", ".join("0x%02x x%d" % kv for kv in top))
        grand[0] += stat["conv"]; grand[1] += stat["convb"]
        grand[2] += stat["reframed"]; grand[3] += stat["refusedb"]
        grand[4] += stat["datab"]
        if args.apply and (edits or blocked):
            src = open(path, encoding="latin-1").read().split("\n")
            before = {l for l in src if C.LABEL_RE.match(l)}
            spans = [(e[0], e[1]) for e in edits]
            blocked = [b for b in blocked
                       if not any(f <= b[0] < l for f, l in spans)]
            work = ([(e[0], e[1], e[2]) for e in edits] +
                    [(f, f, ["\t; (d) BLOCKED: this run cannot be framed until the "
                             "backend gains %s"
                             % ", ".join("0x%02x" % b for b in bl),
                             "\t; (byte_run_start_enrichment.py blind set; lane "
                             "w10/missinginsns). Forcing a reading that round-trips "
                             "would pass the byte gate and still be wrong."])
                     for f, l, bl in blocked])
            for first, last, new in sorted(work, key=lambda x: -x[0]):
                src = src[:first - 1] + new + src[last - 1:]
            after = {l for l in src if C.LABEL_RE.match(l)}
            if before != after:
                raise SystemExit("REFUSED: label definitions changed in %s: %s"
                                 % (rel, sorted(before ^ after)[:8]))
            open(path, "w", encoding="latin-1").write("\n".join(src))
    print("TOTAL converted %d spans covering %d B of .byte; %d B re-framed; "
          "%d B refused; %d B left to the data pass"
          % tuple(grand))
    if args.apply:
        if not R.verify():
            sys.exit("REJECTED: rebuilt image differs from the ROM")
        print("VERIFIED: rebuilt v10 image is byte-identical to the ROM")


if __name__ == "__main__":
    main()
