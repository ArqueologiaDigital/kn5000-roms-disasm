#!/usr/bin/env python3
r"""sequi_reframe.py -- re-frame MISFRAMED code in a maincpu source file.

QUESTION THIS ANSWERS / JOB IT DOES
-----------------------------------
Several sequencer files carry code whose earlier linear sweep lost sync: a real
multi-byte instruction survives as a lone `.byte` prefix and its operand bytes
are "decoded" as nonsense (`.byte 0x94` / `push xsp` / `nop` / `nop` is really
`cpw (xix), 0`), or an instruction the old assembler could not spell was left
as `.byte 0x9a, 0x04, 0x81` (`add bc, (xde+4)`).  The census counts every such
fragment as an embedded-in-code research target.  This tool re-frames one
address span:

1. The address of every emitting source line comes from the symboliser's
   inert marker mirror (`symbolize_numeric_branches.build_map`), which refuses
   an image whose marked mirror is not byte-identical to the dump.
2. The span [lo, hi) is decoded TWICE: by the LLVM backend (llvm-objdump, via
   `v10_reframe.disassemble`) and by MAME `unidasm`.  Both must report the SAME
   instruction boundaries over the whole span, neither may report an undecodable
   byte, and the new decode may not contain an absurd marker (halt / swi / ldf /
   incf / decf / normal / max / min / `jr cc,0`).  Otherwise: REFUSED.
3. An old line is KEPT VERBATIM when it is an instruction (not a directive, not
   a macro call) whose byte span is exactly one new instruction -- so correct
   code, its symbolic operands and its spelling are untouched.  Every other
   emitting line in the span is DIRTY and is replaced by the new decode of the
   bytes it covered.  A dirty stretch must begin and end on a boundary common
   to both framings (it does by construction) and must not be entered by
   fall-through from an unconditional transfer unless --allow-after-terminator
   (a data island after `ret` decodes as code too; that case needs a human).
4. Each new instruction is re-assembled on its own and must give back the ROM
   bytes; absolute ROM addresses in its operands are replaced by the label the
   linked ELF has at exactly that address (non-positional names preferred) and
   re-verified with that label `.set`.  An instruction that does not round-trip
   is emitted as `.byte` with the decode in a comment.
5. Labels inside a dirty stretch must land on a new boundary.  A label that
   lands mid-instruction was CREATED by the misframe: it is dropped only if no
   file under the repo references its name (git grep -w), else REFUSED.
   Comment-only lines are kept, placed before the instruction at or after the
   address they preceded; inline comments of dirty lines are carried onto the
   new instruction that contains their first byte.
6. --apply rewrites the file (latin-1 in/out), rebuilds the image with make and
   compares it with the dump; on any difference the file is restored and the
   run fails.

RUN
    python3 scripts/converters/sequi_reframe.py --image v10 \
        --file sequencer/sequencer_ui.s --span 0xF2F2CB:0xF2F380 [--apply]
    python3 scripts/converters/sequi_reframe.py --image v10 \
        --file sequencer/sequencer_ui.s --auto [--apply]
      --auto: one span per embedded `.byte/.short/.long` fragment inside code,
      widened until old and new framing agree on 4 instructions either side.

Afterwards run the branch symboliser on the file so the new numeric branches
become labels.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import symbolize_numeric_branches as SNB  # noqa: E402
import data_range_census as drc          # noqa: E402
import v10_reframe as VR                 # noqa: E402

LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
NM = os.path.join(LLVM, "llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
ABSURD = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*0+$')
TERM = re.compile(r'^(ret|reti|retd)\b|^(jp|jr|jrl)\s+(t\s*,\s*)?[^,]+$')
DROP_COMMENT = None     # --drop-comment REGEX: inline comments PROVEN false by the re-frame
LBL = re.compile(r'^\s*([A-Za-z_.$][\w.$@]*):\s*(;.*)?$')


def unidasm(data, pc):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data)
        p = f.name
    try:
        out = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", "%x" % pc],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(p)
    res = []
    for ln in out.splitlines():
        m = re.match(r'([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(.*)$', ln.strip())
        if m:
            res.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return res


def encode(lines):
    """-> list of byte-lists (or None) for each single-instruction source line."""
    out = []
    for t in lines:
        r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=t + "\n",
                           capture_output=True, text=True)
        enc = None
        for ln in r.stdout.splitlines():
            m = re.search(r'encoding:\s*\[(.*?)\]', ln)
            if m:
                enc = (enc or []) + [int(x, 16) for x in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
        out.append(enc if r.returncode == 0 else None)
    return out


def elf_labels(image):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True,
                         check=True).stdout
    syms = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) != 3 or p[1] not in "tTaA":
            continue
        a, n = int(p[0], 16), p[2]
        if n.startswith(("__", ".L")):
            continue
        if p[1] in "aA" and (not BASE <= a <= 0xFFFFFF
                             or re.match(r"^Str_[0-9a-f]{8,}$", n)):
            # absolute .set names are accepted for ROM addresses only, and
            # never the hex-digest `Str_<hex>` names a misframe produced
            continue
        pos = bool(re.search(r"_0x[0-9A-Fa-f]+$", n))
        if a not in syms or (syms[a][1] and not pos):
            syms[a] = (n, pos)
    return {a: n for a, (n, _) in syms.items()}


def symbolize_operands(text, syms):
    """Replace a decimal absolute ROM address with the label at it, if any."""
    def rep(m):
        v = int(m.group(0))
        if BASE <= v <= 0xFFFFFF and v in syms:
            return syms[v]
        return m.group(0)
    mn = text.split()[0] if text.split() else ""
    if mn in ("jr", "jrl", "calr", "djnz"):
        return text, None
    new = re.sub(r'(?<![\w.$])\d{7,8}(?![\w.$])', rep, text)
    used = [s for s in re.findall(r'[A-Za-z_][\w.$@]*', new) if s in syms.values()
            and s not in re.findall(r'[A-Za-z_][\w.$@]*', text)]
    return new, used


class Ctx:
    def __init__(self, image, rel):
        self.image, self.rel = image, rel
        img = SNB.image_by_key(image)
        self.srcroot = os.path.join(ROOT, img["mirror"])
        marks, addrs, spans, rom_ok, src, macros = SNB.build_map(img, self.srcroot)
        if not rom_ok:
            sys.exit("mirror of %s is not inert; refusing" % image)
        self.macros = macros
        self.rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
        self.path = os.path.join(self.srcroot, rel)
        self.lines = open(self.path, encoding="latin-1").read().split("\n")
        # emitting lines of THIS file: li -> (start, end)
        self.span = {}
        for a, e, r, li in spans:
            if r == rel:
                self.span[li] = (a, min(e, a + 0x10000))
        self.syms = elf_labels(image)

    def kind(self, li):
        bk, det = drc.classify_line(self.lines[li], self.macros)
        c = drc.strip_comment(self.lines[li]).strip()
        while drc.LABEL_RE.match(c):
            c = c[drc.LABEL_RE.match(c).end():].strip()
        tok = re.split(r'[\s,]', c, maxsplit=1)[0] if c else ""
        if tok in self.macros:
            return "macro", c
        return bk, c


def refs_elsewhere(name, defining_path):
    r = subprocess.run(["git", "grep", "-l", "-w", "-a", "-F", name], cwd=ROOT,
                       capture_output=True, text=True)
    files = [f for f in r.stdout.split() if f]
    n = 0
    for f in files:
        txt = open(os.path.join(ROOT, f), encoding="latin-1").read()
        cnt = len(re.findall(r'(?<![\w.$@])%s(?![\w.$@])' % re.escape(name), txt))
        if os.path.abspath(os.path.join(ROOT, f)) == os.path.abspath(defining_path):
            cnt -= 1           # its own definition
        n += max(cnt, 0)
    return n


def fallback_spellings(udm, raw):
    """Assembler spellings for forms the LLVM DISASSEMBLER cannot decode but
    the assembler can encode.  Each candidate is only used if it re-encodes to
    the ROM bytes."""
    out = []
    m = re.match(r'^ld \((0x[0-9a-f]+)\),\((0x[0-9a-f]+)\)$', udm)
    if m:
        w = "24" if raw[0] == 0xf2 else "16" if raw[0] == 0xf1 else "8"
        out.append("ld (%s:%s), (%s:16)" % (m.group(1), w, m.group(2)))
        out.append("ldw (%s:%s), (%s:16)" % (m.group(1), w, m.group(2)))
    m = re.match(r'^(\w+) (\w+),\((X\w\w)\+(\w+)\)$', udm)
    if m and len(raw) == 5 and raw[1] == 0x07 and raw[0] in (0xc3, 0xd3, 0xe3):
        sz = {0xc3: "b", 0xd3: "w", 0xe3: "l"}[raw[0]]
        op, reg = m.group(1).lower(), m.group(2).lower()
        b = ", ".join("0x%02x" % x for x in raw[1:4])
        for form in ("%s%s_sri_rm", "%s_sri%s_rm", "%s%s_sri_mr", "%s_sri%s_mr"):
            out.append("%s %s, %s" % (form % (op, sz), reg, b))
    m = re.match(r'^(\w+) \((X\w\w)\+(\w+)\),(0x[0-9a-f]+)$', udm)
    if m and raw[0] == 0xc3 and raw[1] == 0x07 and len(raw) == 6:
        op = m.group(1).lower()
        b = ", ".join("0x%02x" % x for x in raw[1:4])
        for form in ("%sib_sri", "%s_srib_im", "%sib_dri"):
            out.append("%s %s, %s" % (form % op, b, m.group(4)))
    return out


def plan(ctx, lo, hi, allow_after_term=False):
    """-> (new_lines, first_li, last_li_exclusive, report) or raises SystemExit."""
    data = ctx.rom[lo - BASE:hi - BASE]
    # FRAMING comes from unidasm; TEXT from the LLVM disassembler wherever it
    # decodes the same instruction with the same length.  Where LLVM cannot
    # decode an instruction unidasm frames, a small table of spellings the
    # assembler accepts is tried (fallback_spellings) and must round-trip.
    ud = unidasm(data, lo)
    if sum(n for _, n, _ in ud) != len(data):
        raise SystemExit("REFUSED 0x%06X: unidasm coverage differs" % lo)
    for a, n, m in ud:
        if m.startswith("db") or "undefined" in m.lower():
            raise SystemExit("REFUSED 0x%06X: unidasm cannot decode 0x%06X" % (lo, a))
    segs = VR.disassemble(data)
    llvm_at, off = {}, lo
    for n, t in segs:
        llvm_at[off] = (n, t.strip())
        off += n
    new = []
    for a, n, m in ud:
        got = llvm_at.get(a)
        if got and got[0] == n and not got[1].startswith(".byte"):
            t = got[1]
        else:
            t = None
            raw = list(ctx.rom[a - BASE:a - BASE + n])
            alone = VR.disassemble(bytes(raw))
            if len(alone) == 1 and alone[0][0] == n and not alone[0][1].strip().startswith(".byte"):
                t = alone[0][1].strip()      # LLVM framing was out of step here only
            for cand in ([] if t else fallback_spellings(m, raw)):
                if encode([cand])[0] == raw:
                    t = cand
                    break
            if t is None:
                t = ".byte %s\t; %s (no assembler spelling found)" % (
                    ", ".join("0x%02x" % x for x in raw), m)
        if ABSURD.match(t):
            raise SystemExit("REFUSED 0x%06X: absurd decode %r at 0x%06X" % (lo, t, a))
        new.append((a, n, t))
    newat = {a: (n, t) for a, n, t in new}
    # evidence that bytes after an unconditional transfer are still code: a
    # relative branch in the span targets them, or a computed jump
    # (`jp T,XIX+r`, a switch over case stubs) precedes them in the span
    targets, computed = set(), []
    for x, n, m in ud:
        mm = re.match(r'^(jr|jrl|calr|djnz)\b.*(0x[0-9a-f]{6})$', m)
        if mm:
            targets.add(int(mm.group(2), 16))
        if re.match(r'^jp T,X\w+\+\w+$', m):
            computed.append(x)
    # old lines in the span
    lis = sorted(li for li, (a, e) in ctx.span.items() if lo <= a < hi)
    if not lis:
        raise SystemExit("no source lines in span")
    if ctx.span[lis[0]][0] != lo:
        raise SystemExit("span start 0x%06X is not a line start" % lo)
    last_end = ctx.span[lis[-1]][1]
    if last_end != hi:
        raise SystemExit("span end 0x%06X is not a line end (0x%06X)" % (hi, last_end))
    first_li, end_li = lis[0], lis[-1] + 1
    # classify old lines
    keep = {}
    for li in lis:
        a, e = ctx.span[li]
        k, c = ctx.kind(li)
        if k == "macro":
            raise SystemExit("REFUSED: macro call in span at line %d" % (li + 1))
        if k == "fill":
            raise SystemExit("REFUSED: fill directive in span at line %d" % (li + 1))
        keep[li] = (k == "code" and a in newat and newat[a][0] == e - a)
    # new instruction text for every new instruction not covered by a kept line
    kept_addrs = {ctx.span[li][0] for li in lis if keep[li]}
    need = [(a, n, t) for a, n, t in new if a not in kept_addrs]
    texts = []
    for a, n, t in need:
        s, used = symbolize_operands(t, ctx.syms)
        texts.append((a, n, t, s, used))
    encs = encode([t for _, _, t, _, _ in texts])
    rendered = {}
    report = []
    fallbacks = 0
    for (a, n, t, s, used), enc in zip(texts, encs):
        want = list(ctx.rom[a - BASE:a - BASE + n])
        if t.startswith(".byte"):
            fallbacks += 1
            rendered[a] = "\t" + t
            continue
        if enc != want:
            fallbacks += 1
            rendered[a] = "\t.byte %s\t; %s (llvm-mc does not re-encode this spelling)" % (
                ", ".join("0x%02x" % x for x in want), t)
            continue
        if s != t:
            pre = "".join("\t.set %s, %d\n" % (u, [k for k, v in ctx.syms.items() if v == u][0])
                          for u in used)
            r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"],
                               input=pre + "\t" + s + "\n", capture_output=True, text=True)
            e2 = []
            for ln in r.stdout.splitlines():
                m = re.search(r'encoding:\s*\[(.*?)\]', ln)
                if m:
                    e2 += [int(x, 16) for x in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
            if r.returncode == 0 and e2 == want:
                t = s
        t = house_hex(t)
        rendered[a] = "\t" + t
    udm = {x: m for x, _, m in ud}
    for a, n, t, s, used in texts:
        report.append("    0x%06X  %-40s || unidasm: %s" % (a, rendered[a].strip(), udm.get(a)))
    # emit
    out, dropped, dropped_comments = [], [], []
    newstarts = {a for a, _, _ in new}
    li = first_li
    prev_code = None
    # find the instruction before the span (for the terminator guard)
    j = first_li - 1
    while j >= 0 and j not in ctx.span:
        j -= 1
    if j >= 0:
        k, c = ctx.kind(j)
        prev_code = c if k == "code" else None
    pending_comments = []
    emitted_upto = lo
    inline = {}
    for li in range(first_li, end_li):
        text = ctx.lines[li]
        if li in ctx.span:
            a, e = ctx.span[li]
            if keep[li]:
                # flush new instructions before a
                out.extend(render_range(rendered, new, emitted_upto, a, inline))
                out.extend(pending_comments)
                pending_comments = []
                out.append(text)
                emitted_upto = e
                prev_code = drc.strip_comment(text).strip()
            else:
                labelled_target = False
                k2 = li - 1
                while k2 >= first_li and k2 not in ctx.span:
                    mm = LBL.match(ctx.lines[k2])
                    if mm and refs_elsewhere(mm.group(1), ctx.path) > 0:
                        labelled_target = True
                    k2 -= 1
                if emitted_upto == a and prev_code and TERM.match(prev_code.lower()) \
                        and not allow_after_term and a not in targets \
                        and not labelled_target \
                        and not any(x < a for x in computed):
                    raise SystemExit("REFUSED: dirty stretch at 0x%06X follows a terminator "
                                     "(%s) -- could be a data island" % (a, prev_code))
                c0 = drc.strip_comment(text)
                if len(c0) < len(text):
                    cm = text[len(c0) + 1:].strip()
                    if cm and DROP_COMMENT and re.search(DROP_COMMENT, cm):
                        dropped_comments.append(cm)
                        cm = ""
                    if cm and cm in inline.get(max(x for x in newstarts if x <= a), []):
                        cm = ""          # the same comment already rides on this instruction
                    if cm:
                        # carry onto the new instruction containing a
                        host = max(x for x in newstarts if x <= a)
                        inline.setdefault(host, []).append(cm)
                m = drc.LABEL_RE.match(c0.strip())
                if m:
                    raise SystemExit("REFUSED: label on an emitting dirty line %d" % (li + 1))
            continue
        # non-emitting line: label / comment / blank
        m = LBL.match(text)
        if m:
            # address of the label = start of next emitting line
            nxt = next((ctx.span[x][0] for x in range(li + 1, len(ctx.lines)) if x in ctx.span), None)
            if nxt is None:
                nxt = hi
            if nxt in newstarts or nxt == hi:
                out.extend(render_range(rendered, new, emitted_upto, nxt, inline))
                emitted_upto = max(emitted_upto, nxt)
                out.extend(pending_comments)
                pending_comments = []
                out.append(text)
            else:
                name = m.group(1)
                nref = refs_elsewhere(name, ctx.path)
                if nref:
                    raise SystemExit("REFUSED: label %s at 0x%06X lands mid-instruction and is "
                                     "referenced %d time(s)" % (name, nxt, nref))
                dropped.append((name, nxt))
            continue
        pending_comments.append(text)
    out.extend(render_range(rendered, new, emitted_upto, hi, inline))
    out.extend(pending_comments)
    ndirty = sum(1 for li in lis if not keep[li])
    report.insert(0, "0x%06X-0x%06X: %d old lines (%d dirty) -> %d new instrs replaced, "
                  "%d .byte fallbacks, dropped labels %s"
                  % (lo, hi, len(lis), ndirty, len(need), fallbacks,
                     ", ".join("%s@0x%06X" % d for d in dropped) or "-")
                  + ("; dropped %d comment(s) matching --drop-comment" % len(dropped_comments)
                     if dropped_comments else ""))
    return out, first_li, end_li, report


def house_hex(t):
    """Hex for what the project writes in hex: `pushw` immediates (address
    halves), absolute memory operands >= 256 (RAM addresses), and immediates
    >= 0x10000 (addresses, event codes).  Branch displacements are left alone
    (the branch symboliser turns them into labels)."""
    mn = t.split()[0] if t.split() else ""
    if mn in ("jr", "jrl", "calr", "djnz", "call", "jp"):
        return t
    m = re.match(r"^pushw (\d+)$", t)
    if m:
        return "pushw 0x%04x" % int(m.group(1))
    t = re.sub(r"\((\d+)\)", lambda m: "(0x%x)" % int(m.group(1))
               if int(m.group(1)) >= 256 else m.group(0), t)
    t = re.sub(r"(?<![\w.$(+-])(\d{5,})(?![\w.$])", lambda m: "0x%08x" % int(m.group(1))
               if int(m.group(1)) >= 0x10000 else m.group(0), t)
    return t


def render_range(rendered, new, a, b, inline):
    out = []
    for x, n, t in new:
        if a <= x < b:
            line = rendered[x]
            if x in inline:
                line += "\t; " + "; ".join(inline.pop(x))
            out.append(line)
    return out


def auto_spans(ctx, maxrun=4096):
    """One span per RUN of data lines sitting inside code (code within 3
    emitting lines on both sides), widened until old and new framing agree on
    4 consecutive instruction lines after it."""
    lis = sorted(ctx.span)
    kinds = [ctx.kind(li)[0] for li in lis]
    runs, i = [], 0
    while i < len(lis):
        if kinds[i] != "data":
            i += 1
            continue
        j = i
        while j + 1 < len(lis) and kinds[j + 1] == "data":
            j += 1
        before = kinds[max(0, i - 3):i]
        after = kinds[j + 1:j + 4]
        nbytes = ctx.span[lis[j]][1] - ctx.span[lis[i]][0]
        if before and after and "code" in before and "code" in after \
                and all(k in ("code", "data") for k in before + after) and nbytes <= maxrun:
            runs.append((i, j))
        i = j + 1
    out = []
    for i, j in runs:
        s = max(0, i - 6)
        while s > 0 and kinds[s] != "code":
            s -= 1
        lo = ctx.span[lis[s]][0]
        top = min(len(lis) - 1, j + 60)
        data = ctx.rom[lo - BASE:ctx.span[lis[top]][1] + 16 - BASE]
        starts = {a for a, _, _ in unidasm(data, lo)}
        hi = None
        for e in range(j + 1, top - 3):
            lo_e = ctx.span[lis[e]][0]
            if lo_e in starts and all(ctx.span[lis[x]][0] in starts and kinds[x] == "code"
                                      for x in range(e, e + 4)):
                hi = lo_e
                break
        if hi:
            out.append((lo, hi))
    out.sort()
    merged = []
    for lo, hi in out:
        if merged and lo <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(hi, merged[-1][1]))
        else:
            merged.append((lo, hi))
    return merged


def build_and_compare(image):
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % image], cwd=ROOT,
                       capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-3000:])
        return False
    a = open(os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % image), "rb").read()
    b = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % image), "rb").read()
    if a != b:
        d = next(i for i in range(len(a)) if a[i] != b[i])
        print("first difference at 0x%06X" % (BASE + d))
    return a == b


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--span", action="append", default=[])
    ap.add_argument("--auto", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--allow-after-terminator", action="store_true")
    ap.add_argument("--drop-comment", help="regex: inline comments on DIRTY lines that the "
                    "re-frame proves false (e.g. 'cannot be spelled') are dropped, not carried")
    a = ap.parse_args()
    global DROP_COMMENT
    DROP_COMMENT = a.drop_comment
    ctx = Ctx(a.image, a.file)
    spans = [tuple(int(x, 0) for x in s.split(":")) for s in a.span]
    if a.auto:
        spans += auto_spans(ctx)
    plans = []
    for lo, hi in sorted(spans, reverse=True):
        try:
            p = plan(ctx, lo, hi, a.allow_after_terminator)
        except SystemExit as e:
            print(str(e))
            continue
        plans.append(p)
        for r in p[3]:
            print(r)
        if not a.apply:
            for ln in p[0][:40]:
                print("    |" + ln)
    if not a.apply or not plans:
        return
    orig = open(ctx.path, encoding="latin-1").read()
    L = ctx.lines[:]
    for out, f, e, _ in sorted(plans, key=lambda p: p[1], reverse=True):
        L[f:e] = out
    open(ctx.path, "w", encoding="latin-1").write("\n".join(L))
    if not build_and_compare(a.image):
        open(ctx.path, "w", encoding="latin-1").write(orig)
        sys.exit("REJECTED: image differs; file restored")
    print("VERIFIED: %s byte-identical after %d span(s)" % (a.image, len(plans)))


if __name__ == "__main__":
    main()
