#!/usr/bin/env python3
"""twin_framed_spans.py -- which v7 `.byte` spans are ALREADY FRAMED AS CODE in
the v9/v10 twin, and does a linear decode of the v7 bytes agree with the twin's
framing instruction for instruction?

THE QUESTION THIS ANSWERS
-------------------------
`notes/DATA-CENSUS-2026-09-02.md` §8 locates 222,810 B of `embedded-in-code`
debt -- undocumented data sitting between two instruction regions -- of which
139,927 B is in v7.  The census is explicit that this is "a disassembly job,
not a data job", and equally explicit that the flag is NOT a verdict.

Converting on decodability alone is forbidden and would be wrong: the TLCS-900
opcode space is dense enough that random bytes decode cleanly ~24 % of the time
(`scripts/analysis/blind_run_decode_census.py`).  What this script supplies
instead is an argument that comes from OUTSIDE the span:

  * v7, v9 and v10 are three versions of ONE firmware.  Where a span in v7 is
    `.byte` under a label L, and the SAME label L in v9 or v10 covers a span of
    the SAME byte length whose source is written as instructions, the twin has
    already fixed both boundaries -- the start (L is a defined symbol in both)
    and the end (the next label is a defined symbol in both, at the same
    distance).  Neither boundary is taken from inside the span, which is the
    trap the lane brief warns about: a misaligned decode RESYNCHRONISES, so
    agreement downstream of a wrong start proves nothing about the start.

FIVE GATES, ALL OF WHICH MUST PASS
----------------------------------
  A  SAME LABEL, SAME LENGTH.  L and the next emitting label after it exist in
     both images' flattened streams, and (next - L) is identical.  A span whose
     length differs between versions is refused: the routine changed.
  B  THE TWIN'S SOURCE IS CODE THERE.  Built the same way as
     l1_territory_map.py -- llvm-mc -show-encoding over the twin's whole tree,
     walking the emitted byte stream, reconciled against the ROM size so a
     mis-sized directive cannot pass silently.  Requires >= 95 % of the twin
     span's bytes to be instruction bytes.
  C  THE TWIN'S LINEAR DECODE REPRODUCES THE TWIN'S SOURCE FRAMING.  Decode the
     twin's ROM bytes over the span with `llvm-mc --disassemble` and require the
     instruction START OFFSETS to equal the twin source's own.  This is the
     control: it proves linear decode is the right instrument FOR THIS BYTE
     STREAM before it is used on v7, rather than assuming it.
  D  v7's LINEAR DECODE AGREES WITH THE TWIN'S, BOUNDARY FOR BOUNDARY, AND
     ACCOUNTS FOR EVERY BYTE OF THE SPAN.  Reported as a fraction; default
     threshold 0.98.  v7 and its twin differ in the operand VALUES of calls and
     jumps (the images are laid out differently), so byte equality is NOT
     required and is reported separately as context.
  E  SAME REFUSAL PATTERN.  Bytes the decoder cannot spell must occur at the
     same relative offsets in v7 as in the twin.  A v7 span that refuses where
     its twin does not is refused: something is different there and the twin's
     framing is not evidence about it.

WHAT THIS SCRIPT DOES NOT ESTABLISH
-----------------------------------
It inherits the twin's judgement.  If v9/v10's source is wrong about a span
being code, this makes the same error in v7 -- tidily, and byte-exactly.  Gate C
limits that only to the extent that the twin's framing must be self-consistent
under an independent decode, and every emitted region's header names the twin
symbol it was framed from so the inheritance is visible rather than implied.

⚠ It also inherits the decoder's gaps.  Where `llvm-mc` refuses a byte, the
twin's own source spells it `.byte` and resumes one byte later; this script does
the same, so those bytes stay debt and are counted as such.  They are NOT
claimed as converted.

RUN
    python3 scripts/analysis/twin_framed_spans.py --selftest
    python3 scripts/analysis/twin_framed_spans.py --report --min 64
    python3 scripts/analysis/twin_framed_spans.py --emit LABEL

`make all` must have been run: the flatten walks are reconciled against the
rebuilt ROM sizes.
"""
import argparse
import bisect
import collections
import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MC = os.environ.get("LLVM_MC") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJDUMP = os.environ.get("LLVM_OBJDUMP") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-objdump")
BASE = 0xE00000

IMAGES = {
    "v7":  dict(root="v7/maincpu/kn5000_v7_program.s",  inc="v7/maincpu",
                elf="rebuilt_ROMs/kn5000_v7_program.llvm.elf",
                rom="original_ROMs/kn5000_v7_program.rom"),
    "v9":  dict(root="v9/maincpu/kn5000_v9_program.s",  inc="v9/maincpu",
                elf="rebuilt_ROMs/kn5000_v9_program.llvm.elf",
                rom="original_ROMs/kn5000_v9_program.rom"),
    "v10": dict(root="v10/maincpu/kn5000_v10_program.s", inc="v10/maincpu",
                elf="rebuilt_ROMs/kn5000_v10_program.llvm.elf",
                rom="original_ROMs/kn5000_v10_program.rom"),
}

WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):')


def ascii_len(operand):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand))


_FLAT = {}


def flatten(key):
    """-> (kinds, starts, labels, order, size), memoised.

    kinds   bytearray per ROM byte: 1 = instruction byte, 0 = data or padding
    starts  bytearray: 1 at each instruction's FIRST byte
    labels  {name: offset}
    order   [(offset, name)] sorted, so `the next label` is meaningful

    The walk must consume exactly the ROM's size; it raises otherwise, so a
    directive this script sizes wrongly cannot pass silently.
    """
    if key in _FLAT:
        return _FLAT[key]
    img = IMAGES[key]
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", "-I", img["inc"],
                          img["root"]], capture_output=True, text=True, cwd=ROOT)
    if out.returncode != 0:
        raise SystemExit("llvm-mc failed on %s:\n%s" % (key, out.stderr[:600]))
    size = os.path.getsize(os.path.join(ROOT, img["rom"]))
    kinds = bytearray(size)
    starts = bytearray(size)
    instrs = []                 # [(offset, nbytes, statement text)] in emission order
    labels, order, pos = {}, [], 0
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            if pos < size:
                starts[pos] = 1
            for i in range(pos, min(pos + n, size)):
                kinds[i] = 1
            # ⚠ An operand that is a SYMBOL shows up in -show-encoding as an
            # `A` placeholder byte.  Recording that is what makes it safe to
            # rewrite symbols when porting: without it, `ldb c, 210` gets its
            # `c` replaced by the address of a v10 label that happens to be
            # called `c`.  (It exists.  It cost one debugging round.)
            reloc = "A" in enc.group(1)
            instrs.append((pos, n, line.split(";")[0].rstrip(), reloc))
            pos += n
            continue
        m = LABEL.match(s)
        if m:
            nm = m.group(1)
            if nm not in labels:
                labels[nm] = pos
                order.append((pos, nm))
            continue
        if s.startswith(";"):
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            pos += WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
        elif d in ("ascii", "asciz"):
            pos += ascii_len(rest) + (1 if d == "asciz" else 0)
        elif d in ("zero", "fill", "space"):
            parts = [p.strip() for p in rest.split(",")]
            n = int(parts[0], 0)
            if d == "fill" and len(parts) >= 2:
                n *= int(parts[1], 0)
            pos += n
        elif d == "p2align":
            pos += (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0)
            if t > pos:
                pos = t
    if pos != size:
        raise SystemExit("%s: flatten consumed %d bytes, ROM is %d -- refusing "
                         "to report from an unreconciled walk" % (key, pos, size))
    order.sort()
    _FLAT[key] = (kinds, starts, labels, order, size, instrs)
    return _FLAT[key]


OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')


def decode(blob):
    """Linear disassembly of `blob`.  -> (starts, refused, text, pos).

    starts   sorted offsets at which an instruction begins
    refused  sorted offsets the decoder could not spell
    text     [(offset, nbytes, mnemonic-text)] -- mnemonic is "" for a refusal
    pos      bytes accounted for; a caller MUST require pos == len(blob)

    ⚠ THIS DELIBERATELY DOES NOT USE `llvm-mc --disassemble --show-encoding`.
    That prints a RE-ENCODING of the instruction, which is not always the byte
    span the disassembler consumed -- `notes/DEBT-INVENTORY-2026-09-02.md`
    records a 407 B figure that was retracted for exactly this reason -- and it
    reports a refused byte only on stderr, without saying how many bytes the
    decoder skipped.  Measured here on v10 0x1808E6+7134: summing its encoding
    lengths plus its stderr warnings gives 7,115 B for a 7,134 B span, and a
    greedy re-sync against the real bytes desynchronises at instruction 105.

    `llvm-objdump -d` instead prints the ADDRESS and the RAW CONSUMED BYTES of
    every instruction, and prints `<unknown>` with its raw bytes where it
    refuses.  The walk is still self-checked: the addresses must be contiguous
    from 0 and the raw bytes must equal the blob, or pos comes back -1.
    """
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        binp = os.path.join(td, "b.bin")
        open(binp, "wb").write(blob)
        srcp = os.path.join(td, "b.s")
        open(srcp, "w").write('.text\n.incbin "%s"\n' % binp)
        objp = os.path.join(td, "b.o")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", objp, srcp],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return [], [], [], -1
        r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", objp],
                           capture_output=True, text=True)
    starts, refused, text, pos = [], [], [], 0
    for line in r.stdout.split("\n"):
        m = OBJDUMP_RE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        raw = bytes(int(x, 16) for x in m.group(2).split())
        mn = m.group(3).strip()
        if addr != pos or blob[pos:pos + len(raw)] != raw:
            return [], [], [], -1
        if mn.startswith("<unknown>"):
            refused.extend(range(pos, pos + len(raw)))
            text.append((pos, len(raw), ""))
        else:
            starts.append(pos)
            text.append((pos, len(raw), mn))
        pos += len(raw)
    if pos != len(blob):
        return [], [], [], -1
    return starts, sorted(refused), text, pos


def label_spans(order, size):
    out = []
    for i, (off, nm) in enumerate(order):
        end = order[i + 1][0] if i + 1 < len(order) else size
        if end > off:
            out.append((nm, off, end - off))
    return out


def adjudicate(nm, off, n, twin_keys, thresh):
    """-> dict verdict for one v7 span."""
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    rom7 = ROMS["v7"]
    chosen, why = None, "no twin symbol"
    for tk in twin_keys:
        kt, st, lt, ot, szt = flatten(tk)[:5]
        if nm not in lt:
            continue
        idx = [i for i, (o, x) in enumerate(ot) if x == nm]
        if not idx:
            continue
        i = idx[0]
        toff = ot[i][0]
        tend = ot[i + 1][0] if i + 1 < len(ot) else szt
        if tend - toff != n:
            why = "twin %s span is %d B, v7's is %d" % (tk, tend - toff, n)
            continue
        frac = sum(kt[toff:toff + n]) / float(n)
        if frac < 0.95:
            why = "twin %s is only %.0f%% instruction bytes" % (tk, 100 * frac)
            continue
        chosen = (tk, toff)
        break
    if chosen is None:
        return dict(name=nm, off=off, n=n, verdict="REFUSED", why=why)
    tk, toff = chosen
    kt, st, lt, ot, szt = flatten(tk)[:5]
    tstarts_src = set(i - toff for i in range(toff, toff + n) if st[i])
    tblob = ROMS[tk][toff:toff + n]
    tdec, tref, ttext, tpos = decode(tblob)
    if tpos != n:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate C: twin %s decode accounts for %d of %d B" % (tk, tpos, n))
    agreeC = len(tstarts_src & set(tdec)) / float(max(len(tstarts_src), 1))
    if agreeC < thresh:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate C: twin %s decode vs its own source framing %.3f"
                        % (tk, agreeC))
    blob = rom7[off:off + n]
    dec, ref, text, pos = decode(blob)
    if pos != n:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate D: v7 decode accounts for %d of %d B" % (pos, n))
    agreeD = len(set(dec) & set(tdec)) / float(max(len(tdec), 1))
    if agreeD < thresh:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate D: v7 decode vs twin %s framing %.3f" % (tk, agreeD))
    if set(ref) != set(tref):
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="gate E: v7 refuses %d bytes, twin %s refuses %d, at "
                        "different offsets" % (len(ref), tk, len(tref)))
    same = sum(1 for a, b in zip(blob, tblob) if a == b)
    return dict(name=nm, off=off, n=n, verdict="PASS", twin=tk, toff=toff,
                agreeC=agreeC, agreeD=agreeD, refusals=len(ref),
                byte_same=same, ninstr=len(text), text=text, refset=ref)


ROMS = {}


def load_roms():
    for k in IMAGES:
        ROMS[k] = open(os.path.join(ROOT, IMAGES[k]["rom"]), "rb").read()


def analyse(min_size, twin_keys=("v10", "v9"), thresh=0.98):
    load_roms()
    for k in ("v7",) + tuple(twin_keys):
        sys.stderr.write("flattening %s ...\n" % k)
        flatten(k)
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    res, stats = [], dict(total=0, bytes_total=0, pass_=0, bytes_pass=0)
    for nm, off, n in label_spans(o7, sz7):
        if n < min_size:
            continue
        if sum(k7[off:off + n]) > 0.02 * n:
            continue                    # already code in v7
        stats["total"] += 1
        stats["bytes_total"] += n
        r = adjudicate(nm, off, n, twin_keys, thresh)
        if r["verdict"] == "PASS":
            stats["pass_"] += 1
            stats["bytes_pass"] += n
        res.append(r)
    return res, stats



# ----------------------------------------------------------------- emission
CALLJP = re.compile(r'^(call|jp|calr)(\s+)((?:\w+,\s*)?)(\d+)$')
BYTELINE = re.compile(r'^\s*\.byte\s+(.*?)\s*(?:;.*)?$')


def symbolise(mn, addr_to_name):
    """`call 16421459` -> `call MainDrawText` when a label is defined at that
    address.  Only a BARE numeric operand of an absolute call/jp is touched:
    a parenthesised operand is a data address and `jrl`'s operand is a raw
    DISPLACEMENT in this assembler's syntax (measured: `jrl z, 2252` assembles
    back to 76 cc 08), so neither may be rewritten as a symbol."""
    m = CALLJP.match(mn.replace("\t", " ").strip())
    if not m:
        return mn
    nm = addr_to_name.get(int(m.group(4)))
    if not nm:
        return mn
    return "%s\t%s%s" % (m.group(1), m.group(3), nm)


def render(r, addr_to_name):
    """The source lines for one PASSING span, label line excluded."""
    out = []
    base = BASE + r["off"]
    for o, ln, mn in r["text"]:
        if not mn:
            blob = ROMS["v7"][r["off"] + o:r["off"] + o + ln]
            out.append("\t.byte " + ", ".join("0x%02x" % b for b in blob)
                       + "\t; llvm-mc cannot spell this byte")
            continue
        t = symbolise(mn, addr_to_name)
        if re.match(r'^(jrl|jr|djnz)\b', t.replace("\t", " ")):
            # the operand is a displacement; say where it lands so the reader
            # does not have to add it up
            m = re.search(r'(-?\d+)$', t)
            if m:
                t += "\t; -> 0x%06X" % (base + o + ln + int(m.group(1)))
        out.append("\t" + t)
    return out


_ELFSYMS = {}


def elf_symbols(key):
    """name -> address, from the LINKED image.

    ⚠ Not the same set as flatten()'s labels: `.set NAME, OTHER + n` defines a
    symbol that never appears as `NAME:` in any source line, and this tree uses
    that heavily (`shared/positional_labels.s`).  A round-trip harness that
    knows only the label set leaves such a name undefined, assembles it as 0,
    and reports a byte difference that is its own fault -- which is exactly what
    happened to `lda_24 xbc, (MixerPartTable_Start_0x80)`."""
    if key in _ELFSYMS:
        return _ELFSYMS[key]
    out = subprocess.run([os.path.join(os.path.dirname(MC), "llvm-nm"),
                          "--defined-only",
                          os.path.join(ROOT, IMAGES[key]["elf"])],
                         capture_output=True, text=True, check=True).stdout
    d = {}
    for line in out.split("\n"):
        parts = line.split()
        if len(parts) == 3:
            try:
                d[parts[2]] = int(parts[0], 16)
            except ValueError:
                pass
    _ELFSYMS[key] = d
    return d


def roundtrip(lines, blob, addr_to_name):
    """Assemble the rendered text on its own and require the ORIGINAL bytes.

    ⚠ This is the check that must exist per span rather than per image.  A
    whole-image rebuild says only that SOMETHING is wrong; with 87 spans in
    flight that is not a diagnosis.  Every symbol the rendering substituted is
    re-declared with `.set` at the address it was taken from, so a name that
    resolves to a different address here would also fail.
    """
    import tempfile
    used = set()
    for ln in lines:
        for w in re.findall(r'[A-Za-z_][\w.$]*', ln.split(";")[0]):
            used.add(w)
    name_to_addr = {}
    for a, nm in addr_to_name.items():
        if nm in used:
            name_to_addr[nm] = a
    for nm, a in elf_symbols("v7").items():
        if nm in used:
            name_to_addr.setdefault(nm, a)
    text = "".join(".set %s, 0x%X\n" % (n, a) for n, a in name_to_addr.items())
    text += ".text\n" + "\n".join(lines) + "\n"
    with tempfile.TemporaryDirectory() as td:
        srcp, objp, binp = (os.path.join(td, x) for x in ("s.s", "s.o", "s.bin"))
        open(srcp, "w", encoding="latin-1").write(text)
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", objp, srcp],
                           capture_output=True, text=True)
        if r.returncode:
            return False, r.stderr.strip().split("\n")[0][:120]
        subprocess.run([os.path.join(os.path.dirname(MC), "llvm-objcopy"),
                        "-O", "binary", "-j", ".text", objp, binp], check=True)
        got = open(binp, "rb").read()
    if got != blob:
        n = min(len(got), len(blob))
        d = next((i for i in range(n) if got[i] != blob[i]), n)
        return False, "differs at +0x%X (%d B emitted, %d expected)" % (d, len(got), len(blob))
    return True, ""


def load_linemap(path):
    d = json.load(open(path))
    return {rel: {int(k): v for k, v in m.items()} for rel, m in d.items()}


def guard_linemap(lm):
    """⚠ A STALE ADDRESS MAP IS INVISIBLE TO EVERY CHECK EXCEPT THE REBUILT ROM
    (lane brief, 2026-09-02).  So every `.byte` line the map places is checked
    against the ROM: the first literal on the line must equal the byte at the
    mapped address.  -> (checked, bad).  A non-zero `bad` must abort the run."""
    checked = bad = 0
    for rel, m in lm.items():
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            continue
        lines = io.open(path, encoding="latin-1").read().split("\n")
        for ln, addr in m.items():
            if not (1 <= ln <= len(lines)):
                continue
            mm = BYTELINE.match(lines[ln - 1])
            if not mm:
                continue
            tok = mm.group(1).split(",")[0].strip()
            try:
                v = int(tok, 0) & 0xFF
            except ValueError:
                continue
            checked += 1
            off = addr - BASE
            if not (0 <= off < len(ROMS["v7"])) or ROMS["v7"][off] != v:
                bad += 1
    return checked, bad


def apply_spans(linemap_path, min_size, thresh):
    lm = load_linemap(linemap_path)
    load_roms()
    checked, bad = guard_linemap(lm)
    print("line-map guard: %d `.byte` lines checked against the ROM, %d disagree"
          % (checked, bad))
    if bad:
        sys.exit("REFUSED: the line map does not describe this source tree")
    res, st = analyse(min_size, thresh=thresh)
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    addr_to_name = {}
    for nm, off in l7.items():
        if not nm.startswith("."):
            addr_to_name.setdefault(BASE + off, nm)
    # address -> (rel, line) for every mapped line
    where = {}
    for rel, m in lm.items():
        for ln, addr in m.items():
            where.setdefault(addr, []).append((rel, ln))
    edits = {}      # rel -> [(first_line, last_line_excl, newlines)]
    done = converted = refusedbytes = 0
    for r in sorted([x for x in res if x["verdict"] == "PASS"],
                    key=lambda x: -x["n"]):
        lo, hi = BASE + r["off"], BASE + r["off"] + r["n"]
        rels = set()
        for a in range(lo, hi):
            for rel, ln in where.get(a, []):
                rels.add(rel)
        if len(rels) != 1:
            print("  skip %-40s: %d source files claim its bytes"
                  % (r["name"], len(rels)))
            continue
        rel = rels.pop()
        m = lm[rel]
        lns = sorted(ln for ln, a in m.items() if lo <= a < hi)
        if not lns:
            print("  skip %-40s: no mapped lines" % r["name"])
            continue
        src = io.open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
        # The label line maps to the span's first address and emits nothing, so
        # the replaceable block starts at the first `.byte` LINE, not the first
        # mapped line.  Keeping the label is not cosmetic: it is the boundary
        # the whole adjudication rests on.
        byte_lns = [ln for ln in lns if BYTELINE.match(src[ln - 1])]
        if not byte_lns:
            print("  skip %-40s: no `.byte` lines in range" % r["name"])
            continue
        first, last = byte_lns[0], byte_lns[-1]
        block = src[first - 1:last]
        if not all(BYTELINE.match(x) or not x.strip() or x.strip().startswith(";")
                   for x in block):
            print("  skip %-40s: block is not pure `.byte`" % r["name"])
            continue
        # ⚠ The block must emit EXACTLY the span, or the rewrite would move a
        # byte that belongs to a neighbour.  Counted from the directives, not
        # assumed from the map.
        emitted = 0
        for x in block:
            mm = BYTELINE.match(x)
            if mm:
                emitted += len([t for t in mm.group(1).split(",") if t.strip()])
        if emitted != r["n"] or m[first] != lo:
            print("  skip %-40s: block emits %d B at 0x%06X, span is %d B at 0x%06X"
                  % (r["name"], emitted, m[first], r["n"], lo))
            continue
        comments = [x for x in block if x.strip().startswith(";")]
        body = render(r, addr_to_name)
        ok, why = roundtrip(body, ROMS["v7"][r["off"]:r["off"] + r["n"]], addr_to_name)
        if not ok:
            print("  skip %-40s: does not round-trip -- %s" % (r["name"], why))
            continue
        new = comments + body
        edits.setdefault(rel, []).append((first, last + 1, new))
        done += 1
        converted += r["n"] - r["refusals"]
        refusedbytes += r["refusals"]
    for rel, es in edits.items():
        path = os.path.join(ROOT, rel)
        src = io.open(path, encoding="latin-1").read().split("\n")
        for first, last, new in sorted(es, key=lambda x: -x[0]):
            src = src[:first - 1] + new + src[last - 1:]
        io.open(path, "w", encoding="latin-1").write("\n".join(src))
    print("\nrewrote %d spans in %d files: %d B now instructions, %d B still "
          "`.byte` (bytes llvm-mc cannot spell)"
          % (done, len(edits), converted, refusedbytes))
    if not verify_v7():
        for rel in edits:
            subprocess.run(["git", "checkout", "--", rel], cwd=ROOT)
        sys.exit("REJECTED: rebuilt v7 is not byte-identical; edits rolled back")
    print("VERIFIED: rebuilt v7 image is byte-identical to the ROM")
    return 0


def verify_v7():
    import tempfile
    td = tempfile.mkdtemp(prefix="twinframe-")
    inc = os.path.join(ROOT, "v7/maincpu")
    obj, elf, binf = (os.path.join(td, x) for x in ("a.o", "a.elf", "a.bin"))
    LB = os.path.dirname(MC)
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", inc, "-o", obj,
                        os.path.join(inc, "kn5000_v7_program.s")],
                       cwd=ROOT, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-3000:])
        return False
    subprocess.run([os.path.join(LB, "ld.lld"), "-e", "0", "-T",
                    os.path.join(inc, "maincpu.ld"), "-o", elf, obj], check=True)
    subprocess.run([os.path.join(LB, "llvm-objcopy"), "-O", "binary", elf, binf],
                   check=True)
    return open(binf, "rb").read() == ROMS["v7"]



# --------------------------------------------------------------- PORT MODE
# ★ WHY A SECOND MODE EXISTS, AND WHAT IT FIXES
#
# The five gates above adjudicate v7 by DECODING it and comparing the decode to
# the twin.  That makes the whole method hostage to the DISASSEMBLER, and the
# disassembler is the weaker half of this backend.  The largest single
# embedded-in-code entry in the census -- v7 `AudioCtrl_DataBlock`, 7,134 B --
# is refused at gate C for exactly that reason, and the reason is worth stating
# precisely because it is NOT a framing doubt:
#
#     llvm-mc ENCODES `add bc, (xsp+6)` to 9f 06 81 correctly.
#     llvm-objdump DECODES 0x9f as <unknown>, skips it, and reads `06 81` as
#     `ei 1`.
#
# So v10's source is right, the independent decode is wrong, and gate C scores
# the disagreement against v10.  (⚠ Checked in both directions before being
# called a gap -- "the toolchain cannot spell it" has been wrong repeatedly in
# this project, so the encode was run as well as the decode.)
#
# PORT MODE takes the twin's SOURCE framing instead of a decode of it.  The
# twin's span must be covered end to end by instruction statements; those
# statements give an exact length sequence, which is walked over v7's bytes:
#
#   * slot bytes IDENTICAL to the twin's  -> reuse the twin's own statement,
#     with any symbol operand rewritten to the address it had in the twin (the
#     bytes are identical, so the value is identical), then re-symbolised
#     against a v7 label at that same address if one is defined.
#   * slot bytes DIFFER                   -> decode that slot alone and require
#     the decode to consume exactly the slot; otherwise the slot stays `.byte`.
#
# Everything is then assembled as one block and required to reproduce v7's
# bytes exactly, so a wrong length sequence or a mis-substituted symbol cannot
# survive.
IDENT = re.compile(r'[A-Za-z_][\w.$]*')


_BYPOS = {}


def twin_slots(tk, toff, n):
    """The twin's own framing of [toff, toff+n), as [(off, len, text)].

    `text` is the twin's statement for an INSTRUCTION slot and None for a byte
    the twin does not spell as one -- the twin's own residue, which stays
    `.byte` here too rather than being invented.  Returns None only if an
    instruction would run past the span's end, which would mean the two images
    do not agree about where the span ends after all."""
    if tk not in _BYPOS:
        _BYPOS[tk] = {o: (ln, txt, rl) for o, ln, txt, rl in flatten(tk)[5]}
    bypos = _BYPOS[tk]
    out, pos = [], toff
    while pos < toff + n:
        if pos in bypos:
            ln, txt, rl = bypos[pos]
            if pos + ln > toff + n:
                return None
            out.append((pos - toff, ln, txt, rl))
            pos += ln
        else:
            out.append((pos - toff, 1, None, False))
            pos += 1
    return out


def port_span(nm, off, n, twin_keys=("v10", "v9")):
    """-> dict verdict.  Same gate A as above; then the twin's framing is
    PORTED rather than reproduced by decoding."""
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    chosen, why = None, "no twin symbol"
    for tk in twin_keys:
        kt, st, lt, ot, szt = flatten(tk)[:5]
        if nm not in lt:
            continue
        idx = [i for i, (o, x) in enumerate(ot) if x == nm]
        if not idx:
            continue
        i = idx[0]
        toff = ot[i][0]
        tend = ot[i + 1][0] if i + 1 < len(ot) else szt
        if tend - toff != n:
            why = "twin %s span is %d B, v7's is %d" % (tk, tend - toff, n)
            continue
        slots = twin_slots(tk, toff, n)
        if slots is None:
            why = "twin %s span is not covered end to end by instructions" % tk
            continue
        chosen = (tk, toff, slots)
        break
    if chosen is None:
        return dict(name=nm, off=off, n=n, verdict="REFUSED", why=why)
    tk, toff, slots = chosen
    # ★★ THE GATE THAT PORT MODE CANNOT DO WITHOUT, added after it was caught
    # producing 342 spans whose MEDIAN byte agreement with the twin was ZERO.
    #
    # Gate A only says the two labels are the same distance apart.  Two spans of
    # equal length whose bytes have nothing in common are not the same routine;
    # porting a length sequence onto them frames v7 by a coincidence of label
    # spacing.  The whole-span round trip cannot object -- it only proves the
    # emission reproduces v7's bytes, which any framing that decodes will.
    #
    # The five-gate passes ran at 69-98 % byte agreement; the floor here is set
    # well below that (0.60) so it excludes the coincidences without demanding
    # the versions be near-identical.
    n_same = sum(1 for a, b in zip(ROMS["v7"][off:off + n], ROMS[tk][toff:toff + n])
                 if a == b)
    if n_same < 0.60 * n:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="byte agreement with twin %s is only %.0f%% -- same span "
                        "length, different code" % (tk, 100.0 * n_same / n))
    tlabels = flatten(tk)[2]
    tname_to_addr = {x: BASE + a for x, a in tlabels.items()}
    v7addr_to_name = {}
    for x, a in l7.items():
        if not x.startswith("."):
            v7addr_to_name.setdefault(BASE + a, x)
    blob7 = ROMS["v7"][off:off + n]
    blobT = ROMS[tk][toff:toff + n]
    lines, reused, redecoded, bytes_byte = [], 0, 0, 0
    for (o, ln, txt, rl) in slots:
        b7 = blob7[o:o + ln]
        bT = blobT[o:o + ln]
        if txt is None:
            # the twin does not spell this byte either -- do not invent one
            lines.append("\t.byte 0x%02x\t; %s does not spell this byte either"
                         % (b7[0], tk))
            bytes_byte += ln
            continue
        if b7 == bT:
            lines.append(port_text(txt, rl, tname_to_addr, v7addr_to_name))
            reused += 1
            continue
        starts, ref, text, pos = decode(b7)
        if pos == ln and len(text) == 1 and text[0][1] == ln and text[0][2]:
            lines.append("\t" + symbolise(text[0][2], v7addr_to_name))
            redecoded += 1
        else:
            lines.append("\t.byte " + ", ".join("0x%02x" % x for x in b7)
                         + "\t; differs from %s here and llvm-objdump cannot "
                           "read it" % tk)
            bytes_byte += ln
    # ⚠ AND A SECOND FLOOR, on the RESULT rather than the input: a span where
    # most slots had to be re-decoded or left as `.byte` has not really been
    # framed by the twin, whatever its byte agreement.
    if reused < 0.60 * len(slots):
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="only %d of %d slots are byte-identical to twin %s"
                        % (reused, len(slots), tk))
    ok, err = roundtrip(lines, blob7, v7addr_to_name)
    if not ok:
        return dict(name=nm, off=off, n=n, verdict="REFUSED",
                    why="port round trip: " + err)
    return dict(name=nm, off=off, n=n, verdict="PASS", twin=tk, lines=lines,
                reused=reused, redecoded=redecoded, bytes_byte=bytes_byte,
                slots=len(slots))


def port_text(txt, has_reloc, tname_to_addr, v7addr_to_name):
    """The twin's statement, with any SYMBOL operand carried across by ADDRESS.

    A name means a different address in v7, so it cannot be copied as text.
    The slot's bytes are identical in both images, so the encoded value is the
    twin's symbol address; that address is re-named with v7's own label if one
    is defined there, and otherwise written numerically."""
    if not has_reloc:
        return txt if txt.startswith("\t") else "\t" + txt
    head, _, tail = txt.partition("\t") if "\t" in txt else (txt, "", "")
    def sub(m):
        w = m.group(0)
        a = tname_to_addr.get(w)
        if a is None:
            return w
        return v7addr_to_name.get(a) or ("0x%X" % a)
    return "\t" + (head + "\t" + IDENT.sub(sub, tail) if tail else head).strip("\t")


def apply_port(linemap_path, min_size):
    lm = load_linemap(linemap_path)
    load_roms()
    checked, bad = guard_linemap(lm)
    print("line-map guard: %d `.byte` lines checked against the ROM, %d disagree"
          % (checked, bad))
    if bad:
        sys.exit("REFUSED: the line map does not describe this source tree")
    for k in ("v7", "v9", "v10"):
        sys.stderr.write("flattening %s ...\n" % k)
        flatten(k)
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    where = {}
    for rel, m in lm.items():
        for ln, addr in m.items():
            where.setdefault(addr, []).append((rel, ln))
    cands = [(nm, o, n) for nm, o, n in label_spans(o7, sz7)
             if n >= min_size and sum(k7[o:o + n]) <= 0.02 * n]
    edits, done, conv, left = {}, 0, 0, 0
    quality = []
    refusals = collections.Counter()
    for nm, off, n in sorted(cands, key=lambda x: -x[2]):
        r = port_span(nm, off, n)
        if r["verdict"] != "PASS":
            refusals[r["why"].split(":")[0].split(",")[0][:44]] += 1
            continue
        lo, hi = BASE + off, BASE + off + n
        rels = {rel for a in range(lo, hi) for rel, ln in where.get(a, [])}
        if len(rels) != 1:
            refusals["%d source files claim the bytes" % len(rels)] += 1
            continue
        rel = rels.pop()
        m = lm[rel]
        lns = sorted(ln for ln, a in m.items() if lo <= a < hi)
        src = io.open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
        byte_lns = [ln for ln in lns if BYTELINE.match(src[ln - 1])]
        if not byte_lns:
            refusals["no `.byte` lines in range"] += 1
            continue
        first, last = byte_lns[0], byte_lns[-1]
        block = src[first - 1:last]
        emitted = 0
        for x in block:
            mm = BYTELINE.match(x)
            if mm:
                emitted += len([t for t in mm.group(1).split(",") if t.strip()])
        if emitted != n or m[first] != lo or not all(
                BYTELINE.match(x) or not x.strip() or x.strip().startswith(";")
                for x in block):
            refusals["block does not match the span"] += 1
            continue
        comments = [x for x in block if x.strip().startswith(";")]
        head = ["\t; framing ported from %s's source for the same label "
                "(same span length, statement for statement); "
                "%d of %d slots byte-identical" % (r["twin"], r["reused"], r["slots"])]
        edits.setdefault(rel, []).append((first, last + 1, comments + head + r["lines"]))
        done += 1
        conv += n - r["bytes_byte"]
        left += r["bytes_byte"]
        quality.append(r["reused"] / float(r["slots"]))
    for rel, es in edits.items():
        path = os.path.join(ROOT, rel)
        src = io.open(path, encoding="latin-1").read().split("\n")
        for f, l, new in sorted(es, key=lambda x: -x[0]):
            src = src[:f - 1] + new + src[l - 1:]
        io.open(path, "w", encoding="latin-1").write("\n".join(src))
    print("\nported %d spans in %d files: %d B now instructions, %d B still `.byte`"
          % (done, len(edits), conv, left))
    if quality:
        quality.sort()
        print("  slots byte-identical to the twin, per ported span: "
              "min %.2f  median %.2f  max %.2f"
              % (quality[0], quality[len(quality) // 2], quality[-1]))
    for k, v in refusals.most_common(12):
        print("  refused: %-46s %4d" % (k, v))
    if not verify_v7():
        for rel in edits:
            subprocess.run(["git", "checkout", "--", rel], cwd=ROOT)
        sys.exit("REJECTED: rebuilt v7 is not byte-identical; edits rolled back")
    print("VERIFIED: rebuilt v7 image is byte-identical to the ROM")
    return 0


def toolchain():
    return subprocess.run(["git", "-C", os.path.expanduser("~/compartilhado/llvm-project"),
                           "log", "-1", "--format=%h (%H)"],
                          capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--emit", default="")
    ap.add_argument("--min", type=int, default=64)
    ap.add_argument("--thresh", type=float, default=0.98)
    ap.add_argument("--apply", default="",
                    help="path to a v7 line map (v10_line_address_map.py --image v7); rewrite every passing span and verify byte-identity")
    ap.add_argument("--port", default="",
                    help="path to a v7 line map; PORT the twin's own source "
                         "framing instead of decoding v7 (see PORT MODE)")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if a.port:
        print("toolchain: %s" % toolchain())
        return apply_port(a.port, a.min)
    if a.apply:
        print("toolchain: %s" % toolchain())
        return apply_spans(a.apply, a.min, a.thresh)
    if a.emit:
        load_roms()
        flatten("v7")
        k7, s7, l7, o7, sz7 = flatten("v7")[:5]
        hit = [(nm, o, n) for nm, o, n in label_spans(o7, sz7) if nm == a.emit]
        if not hit:
            sys.exit("no v7 label span named %s" % a.emit)
        nm, off, n = hit[0]
        r = adjudicate(nm, off, n, ("v10", "v9"), a.thresh)
        if r["verdict"] != "PASS":
            sys.exit("%s: %s" % (nm, r["why"]))
        for o, ln, mn in r["text"]:
            print("\t%s" % mn)
        return 0
    print("toolchain: %s" % toolchain())
    res, st = analyse(a.min, thresh=a.thresh)
    ps = sorted([r for r in res if r["verdict"] == "PASS"], key=lambda r: -r["n"])
    import collections
    rc = collections.Counter()
    for r in res:
        if r["verdict"] == "REFUSED":
            rc[r["why"].split(":")[0].split(",")[0]] += 1
    print("\nv7 DATA label-spans >= %d B considered: %d (%d B)"
          % (a.min, st["total"], st["bytes_total"]))
    print("  PASS all five gates ......... %4d spans, %7d B"
          % (st["pass_"], st["bytes_pass"]))
    for k, v in rc.most_common():
        print("  refused: %-32s %4d" % (k[:32], v))
    print("\n  %-46s %7s %5s %6s %6s %6s %6s" %
          ("label", "bytes", "twin", "gateC", "gateD", "refus", "same%"))
    for r in ps:
        print("  %-46s %7d %5s %6.3f %6.3f %6d %5.1f%%"
              % (r["name"], r["n"], r["twin"], r["agreeC"], r["agreeD"],
                 r["refusals"], 100.0 * r["byte_same"] / r["n"]))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("llvm-mc exists", os.path.exists(MC), MC)
    load_roms()
    for k in IMAGES:
        ck("%s ROM loaded" % k, len(ROMS[k]) == 2097152)
    kinds, starts, labels, order, size = flatten("v10")[:5]
    ck("v10 flatten reconciles to the ROM size", True, "%d B" % size)
    ck("v10 flatten found labels", len(labels) > 1000, str(len(labels)))
    s, r, t, p = decode(bytes([0x11, 0x11, 0x11]))
    ck("three scf bytes decode as three instructions", len(t) == 3 and p == 3)
    # a byte the decoder cannot spell must be REPORTED, not silently absorbed
    s, r, t, p = decode(bytes([0x11, 0x95, 0x11]))
    ck("an unspellable byte is reported as a refusal at its own offset",
       r == [1] and p == 3 and s == [0, 2], "refused=%s pos=%d starts=%s" % (r, p, s))
    # the null the lane brief demands: random bytes must not sail through
    import random
    rnd = random.Random(4242)
    blob = bytes(rnd.randrange(256) for _ in range(2048))
    s2, r2, t2, p2 = decode(blob)
    ck("random 2 KiB is not fully accounted for", len(r2) > 0,
       "refusals %d" % len(r2))
    # AudioCtrl_DataBlock: the worked example the lane report cites
    k7, s7, l7, o7, sz7 = flatten("v7")[:5]
    hit = [(nm, o, n) for nm, o, n in label_spans(o7, sz7)
           if nm == "AudioCtrl_DataBlock"]
    ck("v7 AudioCtrl_DataBlock is a 7134 B span", hit and hit[0][2] == 7134,
       str(hit))
    if hit:
        r = adjudicate(*hit[0], twin_keys=("v10", "v9"), thresh=0.98)
        # ⚠ It is REFUSED by the decode-based gates, and that is the right
        # answer for them: llvm-objdump cannot read 0x9f (`add bc, (xsp+6)`,
        # which llvm-mc encodes fine), so an independent decode disagrees with
        # v10's correct source at ~4% of instruction starts.
        ck("AudioCtrl_DataBlock is refused by the decode-based gates",
           r["verdict"] == "REFUSED" and "gate C" in r.get("why", ""),
           r.get("why", ""))
        r = port_span(*hit[0])
        ck("AudioCtrl_DataBlock passes PORT mode", r["verdict"] == "PASS",
           str(r.get("why", ""))[:90])
    # ★ THE NULL FOR PORT MODE.  `AccMidi_DispatchLoop` is 67 B in both v7 and
    # v10 and shares NOT ONE BYTE with its twin: same label, same span length,
    # different code.  408 of 1,756 same-length twin spans are like it.  If this
    # check ever passes, port mode is framing v7 by a coincidence of label
    # spacing -- which it did, for 342 spans, before the agreement floor existed.
    hit2 = [(nm, o, n) for nm, o, n in label_spans(o7, sz7)
            if nm == "AccMidi_DispatchLoop"]
    if hit2:
        r = port_span(*hit2[0])
        ck("a same-length twin span with no byte agreement is REFUSED",
           r["verdict"] == "REFUSED" and "byte agreement" in r.get("why", ""),
           str(r.get("why", ""))[:90])
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    sys.exit(main())
