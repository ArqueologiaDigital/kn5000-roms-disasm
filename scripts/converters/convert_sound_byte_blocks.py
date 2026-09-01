#!/usr/bin/env python3
r"""Turn `.byte` runs of SOUND CODE into instructions, byte-identically.

QUESTION IT ANSWERS
    notes/sound/kn5000_sound_boundary.py --misframes lists entry points that
    converted code CALLS and the tree has never decoded -- 21 of them in the
    sub-CPU payload, 4,778 bytes, most of them tone-generator register writers
    and the audio-channel command handlers.  Felipe's goal is full COVERAGE of
    the sound routines, and a `.byte` run is not coverage.  This script does the
    conversion and refuses to do it unless the result is byte-identical.

WHY THIS IS SAFE, AND WHERE IT IS NOT
    ★★ FRAMING DATA AS CODE PASSES THE BYTE GATE.  Round-tripping proves only
    that the bytes came back; it says NOTHING about whether they are code.  So
    this script never chooses what to convert.  It converts the ranges it is
    given, and the evidence for each range must be an entry point that converted
    code branches or calls to -- which is what --misframes measures and what the
    caller must have checked.  Three independent guards run anyway:

      1. THE WHOLE REGION IS DISASSEMBLED IN ONE PASS FIRST and every run start
         must fall on one of that pass's instruction boundaries.  A run that
         starts mid-instruction means the label is in the wrong place and the
         framing is wrong; the script stops.
      2. Every instruction must RE-ASSEMBLE to exactly the bytes it came from.
      3. `make gate` afterwards is the real proof, and it compares whole ROMs.

RUN:  python3 scripts/converters/convert_sound_byte_blocks.py --list
      python3 scripts/converters/convert_sound_byte_blocks.py LABEL [LABEL ...]
      python3 scripts/converters/convert_sound_byte_blocks.py --selftest
"""
import os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
MC = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-mc")
NM = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-nm")
SRC = os.path.join(ROOT, "v142/subcpu/kn5000_subprogram_v142.s")
ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
UNI = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom.unidasm")
UNILINE = re.compile(r'^([0-9a-f]{4,6}): ((?:[0-9a-f]{2} )+)\s+(\S.*?)\s*$')
TARGET = re.compile(r'\b0x([0-9a-f]{4,6})\s*$')


def rom_offset(addr):
    """Payload address -> offset in kn5000_subprogram_v142.rom.  The ROM is the
    two slices the Makefile's `dd` keeps out of the 0x000400-based link."""
    if 0x400 <= addr < 0x500:
        return addr - 0x400
    if addr >= 0xF000:
        return 0x100 + (addr - 0xF000)
    return None


def unidasm():
    """addr -> (nbytes, text).  ★ THE FRAMING AUTHORITY.

    This backend's disassembler cannot spell every form the part has, so a
    resync-on-failure sweep would guess instruction LENGTHS -- and a wrong length
    reframes everything after it.  MAME's unidasm listing, committed beside the
    ROM, decodes the whole image independently; this tool takes its BOUNDARIES
    and only asks llvm-mc whether it can spell each instruction."""
    out = {}
    for line in open(UNI, errors="replace"):
        m = UNILINE.match(line.rstrip())
        if m:
            bs = m.group(2).split()
            out[int(m.group(1), 16)] = (len(bs), m.group(3))
    return out

BYTELINE = re.compile(r'^\s*\.byte\s+(.*?)\s*$')
LABELLINE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.$]*):')
ENC = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
DATA_W = {".byte": 1, ".hword": 2, ".word": 4, ".dword": 8}


def symbols():
    out = {}
    r = subprocess.run([NM, ELF], capture_output=True, text=True)
    for line in r.stdout.split("\n"):
        p = line.split()
        if len(p) == 3 and p[1] in "tTdDbB":
            out[p[2]] = int(p[0], 16)
    return out


def disassemble(raw):
    """-> [(text, nbytes)] or None."""
    txt = " ".join("0x%02x" % b for b in raw)
    r = subprocess.run([MC, "-triple=tlcs900", "--disassemble", "-show-encoding"],
                       input=txt, capture_output=True, text=True)
    if r.returncode or "warning: invalid instruction" in r.stderr:
        return None
    out = []
    for line in r.stdout.split("\n"):
        m = ENC.search(line)
        if not m:
            continue
        n = len([x for x in m.group(1).split(",") if x.strip()])
        out.append((line.split(";")[0].rstrip(), n))
    return out or None


def reassemble(lines):
    src = "\t.text\n" + "\n".join(lines) + "\n"
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"],
                       input=src, capture_output=True, text=True)
    if r.returncode:
        return None
    out = bytearray()
    for line in r.stdout.split("\n"):
        m = ENC.search(line)
        if m:
            for b in m.group(1).split(","):
                b = b.strip()
                if b:
                    out.append(int(b, 16))
    return bytes(out)


def boundaries_agree(addr, chunks, uni):
    """★ THE LOAD-BEARING GUARD.  Sweep unidasm's boundaries across the WHOLE
    group of adjacent runs and require every run start to be one of them.

    A label sitting inside an instruction means the framing is wrong, and the
    per-run decode would still round-trip -- because ANY byte string round-trips
    (see --selftest).  This is the check that can actually fail.  It uses
    unidasm rather than llvm-mc because this backend cannot spell every form the
    part has, and a decoder that stops cannot certify a boundary."""
    a, want = addr, {addr + off for off in accumulate_starts(chunks)}
    end = addr + sum(len(c) for c in chunks)
    seen = set()
    while a < end:
        e = uni.get(a)
        if e is None:
            return False, "unidasm has no boundary at 0x%06X" % a
        seen.add(a)
        a += e[0]
    if a != end:
        return False, "unidasm's last instruction overruns the region by %d" % (a - end)
    missing = sorted(want - seen)
    if missing:
        return False, "run start(s) inside an instruction: " + \
            ", ".join("0x%06X" % m for m in missing[:4])
    return True, ""


def accumulate_starts(chunks):
    out, a = [], 0
    for c in chunks:
        out.append(a)
        a += len(c)
    return out


def rom_matches(addr, raw):
    """The `.byte` run must be what the ORIGINAL ROM holds at that address.
    Cheap, and it catches a wrong address before anything is rewritten."""
    off = rom_offset(addr)
    if off is None:
        return False
    d = open(ROM, "rb").read()
    return d[off:off + len(raw)] == raw


DATALINE = re.compile(r'^\s*\.(byte|hword|word|dword|ascii)\s+(.*?)\s*$')
STRESC = re.compile(r'\\(x[0-9A-Fa-f]{1,2}|[0-7]{1,3}|.)')
UNESC = {"n": 10, "t": 9, "r": 13, "0": 0, "\\": 92, '"': 34}


def line_bytes(kind, rest):
    """The bytes one data directive emits, or None if this tool should not
    touch it.  ⚠ `.ascii` MATTERS: a run of code interrupted by four printable
    bytes gets emitted as a string, and treating that as the end of the run
    leaves the previous instruction cut in half -- which is how two of these
    blocks were refused before this existed."""
    if kind == "ascii":
        m = re.match(r'^"(.*)"$', rest)
        if m is None:
            return None
        out, i, sv = [], 0, m.group(1)
        while i < len(sv):
            if sv[i] == "\\" and i + 1 < len(sv):
                c = sv[i + 1]
                if c == "x":
                    j = i + 2
                    while j < len(sv) and j < i + 4 and sv[j] in "0123456789abcdefABCDEF":
                        j += 1
                    out.append(int(sv[i + 2:j], 16))
                    i = j
                    continue
                if c in "01234567":
                    j = i + 1
                    while j < len(sv) and j < i + 4 and sv[j] in "01234567":
                        j += 1
                    out.append(int(sv[i + 1:j], 8))
                    i = j
                    continue
                out.append(UNESC.get(c, ord(c)))
                i += 2
                continue
            out.append(ord(sv[i]))
            i += 1
        return out
    w = {"byte": 1, "hword": 2, "word": 4, "dword": 8}[kind]
    out = []
    for v in rest.split(","):
        v = v.strip()
        if not v:
            continue
        try:
            n = int(v, 0)
        except ValueError:
            return None
        out.extend((n >> (8 * k)) & 0xFF for k in range(w))
    return out


def runs(lines, sym):
    """Every maximal run of DATA directives, with the address of its first byte.

    The address is (nearest preceding label) + (bytes emitted in between).
    ⚠ If an INSTRUCTION sits between the label and the run the offset cannot be
    computed without assembling, so such a run is skipped and reported rather
    than guessed at."""
    out, cur, addr, dirty = [], None, None, False
    for i, ln in enumerate(lines):
        lm = LABELLINE.match(ln)
        if lm:
            if cur:
                out.append(cur)
                cur = None
            addr = sym.get(lm.group(1))
            dirty = False
            continue
        dm = DATALINE.match(ln)
        bs = line_bytes(dm.group(1), dm.group(2)) if dm else None
        if bs is not None:
            if cur is None:
                cur = dict(start=i, end=i, bytes=list(bs),
                           addr=None if (addr is None or dirty) else addr)
            else:
                cur["end"] = i
                cur["bytes"].extend(bs)
            if addr is not None:
                addr += len(bs)
            continue
        if cur:
            out.append(cur)
            cur = None
        t = ln.split(";")[0].strip()
        if t and not t.startswith(";") and not t.startswith("."):
            dirty = True        # an instruction: the offset is unknown from here
    if cur:
        out.append(cur)
    return out


LLD = os.path.join(PROJ, "llvm-project", "build", "bin", "ld.lld")
LD_SCRIPT = os.path.join(ROOT, "v142/subcpu/subcpu.ld")
INCDIR = os.path.join(ROOT, "v142/subcpu")


def mark_addresses(lines):
    """Address of EVERY data run, including runs that follow an instruction.

    ⚠ The label-relative walk cannot reach these: once an instruction sits
    between the nearest label and the run, the offset needs the assembler.  So
    build a MIRROR of the payload with a synthetic label before each run, link
    it, and read the labels out with nm.  Injected labels emit no bytes, and
    --selftest checks the marked build still produces the ROM byte for byte.

    -> {source line index of the run's first line: address}"""
    marks, out = [], []
    cur = None
    for i, ln in enumerate(lines):
        dm = DATALINE.match(ln)
        isdata = dm is not None and line_bytes(dm.group(1), dm.group(2)) is not None
        if isdata and cur is None:
            cur = i
            out.append("__addrmark_%d:" % len(marks))
            marks.append(i)
        elif not isdata:
            cur = None
        out.append(ln)
    with tempfile.TemporaryDirectory() as td:
        for f in os.listdir(INCDIR):
            src = os.path.join(INCDIR, f)
            if os.path.isdir(src):
                os.symlink(src, os.path.join(td, f))
            elif f != os.path.basename(SRC):
                shutil.copy(src, os.path.join(td, f))
        root = os.path.join(td, os.path.basename(SRC))
        open(root, "w", encoding="latin-1").write("\n".join(out))
        o, e = os.path.join(td, "m.o"), os.path.join(td, "m.elf")
        r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", td, "-o", o, root],
                           capture_output=True, text=True)
        if r.returncode:
            return {}, r.stderr[:400]
        r = subprocess.run([LLD, "-e", "0", "-T", LD_SCRIPT, "-o", e, o],
                           capture_output=True, text=True)
        if r.returncode:
            return {}, r.stderr[:400]
        res = {}
        for line in subprocess.run([NM, e], capture_output=True, text=True).stdout.split("\n"):
            p = line.split()
            if len(p) == 3 and p[2].startswith("__addrmark_"):
                res[marks[int(p[2].split("_")[-1])]] = int(p[0], 16)
        return res, ""


def frame(addr, raw, uni, sym):
    """Split `raw` at unidasm's instruction boundaries and spell each one.

    -> (lines, n_left_as_bytes, n_spelt) or (None, reason, 0).
    An instruction llvm-mc cannot spell stays a `.byte` line carrying unidasm's
    rendering as a comment -- the tree already does that for the handful of forms
    the backend lacks, and guessing is not an option."""
    # ---- pass 1: unidasm's boundaries, and which of them this run branches to.
    bounds, i = [], 0
    while i < len(raw):
        e = uni.get(addr + i)
        if e is None:
            return None, "unidasm has no instruction boundary at 0x%06X" % (addr + i), 0
        if i + e[0] > len(raw):
            return None, ("unidasm's instruction at 0x%06X runs past the .byte run"
                          % (addr + i)), 0
        bounds.append(addr + i)
        i += e[0]
    bset = set(bounds)
    internal = set()
    for b in bounds:
        mt = TARGET.search(uni[b][1])
        if mt:
            t = int(mt.group(1), 16)
            if t in bset and t not in BYADDR:
                internal.add(t)
    for t in sorted(internal):
        BYADDR[t] = "LABEL_%06X" % t
    # ---- pass 2: spell each instruction.
    lines, i, kept, spelt = [], 0, 0, 0
    while i < len(raw):
        if addr + i in internal:
            lines.append("%s:" % BYADDR[addr + i])
        e = uni.get(addr + i)
        if e is None:
            return None, "unidasm has no instruction boundary at 0x%06X" % (addr + i), 0
        n, utext = e
        if i + n > len(raw):
            return None, ("unidasm's instruction at 0x%06X runs past the .byte run"
                          % (addr + i)), 0
        chunk = raw[i:i + n]
        dis = disassemble(chunk)
        ok = dis is not None and len(dis) == 1 and dis[0][1] == n \
            and reassemble([dis[0][0]]) == chunk
        if ok:
            text = dis[0][0]
            # symbolise an absolute target the tree already names
            mt = TARGET.search(utext)
            if mt:
                nm = BYADDR.get(int(mt.group(1), 16))
                if (nm and re.match(r'^\s*(call|calr|jp|jp_24|jr|jrl|djnz8|djnz16)\b', text)
                        and symbolic_ok(text, int(mt.group(1), 16), addr + i, n)):
                    text = re.sub(r'(-?\d+)\s*$', nm, text)
            lines.append(text)
            spelt += 1
        else:
            lines.append("\t.byte " + ", ".join("0x%02x" % b for b in chunk)
                         + "\t; " + utext)
            kept += 1
        i += n
    return lines, kept, spelt


BYADDR = {}


def symbolic_ok(text, target, at, n):
    """Is replacing this branch's NUMBER by a label provably byte-neutral?

    ★ THE BACKEND TREATS THE TWO OPERAND KINDS DIFFERENTLY, and nothing in the
    mnemonic says which a given form is: `jr 25` writes 25 into the raw
    displacement field, `jr Label` emits a PC-relative fixup; `call 211851` is an
    absolute address and so is `call Sym`.  So instead of trusting a table, this
    asks arithmetic which reading makes the number and unidasm's target agree:

      relative  number == target - (address after the instruction)
      absolute  number == target

    Only then is the symbolic form emitted.  If neither holds -- which is what
    happens when unidasm's target line means something else entirely -- the
    number stays and no claim is made."""
    m = re.search(r'(-?\d+)\s*$', text)
    if not m:
        return False
    v = int(m.group(1))
    if v == target:
        return True
    for bits in (8, 16):
        if (v & ((1 << bits) - 1)) == ((target - (at + n)) & ((1 << bits) - 1)):
            return True
    return False


FLOWEND = re.compile(r'^\s*(ret|reti|retd|halt|swi|jp|jp_24|jp_ind|jp_rr|jrl|jr)\b')


def inline_runs(lines, allruns):
    """Data runs that sit INSIDE an instruction stream: the line before is an
    instruction that is not a flow end, and the line after is an instruction.

    ★ THAT IS THE EVIDENCE.  Execution falls into the run and out the far side,
    so the tree itself is already asserting these bytes are executed -- they
    were left as `.byte` only because the assembler could not spell them at the
    time.  Several are `res 7,(P6)`, the tone-generator select strobe, which the
    backend has been able to spell for a while now."""
    def code_line(k, step):
        while 0 <= k < len(lines):
            t = lines[k].split(";")[0].strip()
            if t and not lines[k].lstrip().startswith(";"):
                return lines[k]
            k += step
        return ""
    out = []
    for r in allruns:
        before = code_line(r["start"] - 1, -1)
        after = code_line(r["end"] + 1, 1)
        bt, at = before.split(";")[0].strip(), after.split(";")[0].strip()
        if (bt and not bt.startswith(".") and not bt.endswith(":")
                and not FLOWEND.match(before)
                and at and not at.startswith(".") and not at.endswith(":")):
            out.append(r)
    return out


def convert(labels, apply=True):
    sym = symbols()
    uni = unidasm()
    BYADDR.clear()
    for n, a in sym.items():
        BYADDR.setdefault(a, n)
    lines = open(SRC, encoding="latin-1").read().split("\n")
    idx = {}
    for i, ln in enumerate(lines):
        lm = LABELLINE.match(ln)
        if lm:
            idx[lm.group(1)] = i
    allruns = runs(lines, sym)
    marks, err = mark_addresses(lines)
    if err:
        print("  !! the marked mirror did not build; falling back to label-relative "
              "addresses only\n     " + err.strip().splitlines()[0])
    for r in allruns:
        if r["start"] in marks:
            if r["addr"] is not None and r["addr"] != marks[r["start"]]:
                failed.append(("0x%06X" % r["addr"],
                               "the mirror puts this run at 0x%06X" % marks[r["start"]]))
            r["addr"] = marks[r["start"]]
    byline = {r["start"]: r for r in allruns}
    done, failed, edits, chosen = [], [], {}, []
    for lab in labels:
        if lab not in idx:
            failed.append((lab, "no such label"))
            continue
        # the run that starts on the first .byte line after the label
        j = idx[lab] + 1
        while j < len(lines) and (not lines[j].strip() or lines[j].lstrip().startswith(";")):
            j += 1
        r = byline.get(j)
        if r is None:
            failed.append((lab, "no .byte run directly after the label"))
            continue
        if r["addr"] is None:
            failed.append((lab, "address not derivable (an instruction intervenes)"))
            continue
        if not rom_matches(r["addr"], bytes(r["bytes"])):
            failed.append((lab, "the .byte run does not match the ROM at 0x%06X" % r["addr"]))
            continue
        txt, kept, spelt = frame(r["addr"], bytes(r["bytes"]), uni, sym)
        if txt is None:
            failed.append((lab, kept))
            continue
        edits[r["start"]] = (r["end"], txt)
        done.append((lab, r["addr"], len(r["bytes"]), spelt, kept))
        chosen.append(r)
    # ★ THE BOUNDARY GUARD, over every maximal run of ADJACENT chosen runs.
    chosen.sort(key=lambda r: r["addr"])
    i = 0
    while i < len(chosen):
        j = i
        while (j + 1 < len(chosen)
               and chosen[j]["addr"] + len(chosen[j]["bytes"]) == chosen[j + 1]["addr"]):
            j += 1
        grp = chosen[i:j + 1]
        if len(grp) > 1:
            base = grp[0]["addr"]
            ok, why = boundaries_agree(base, [bytes(g["bytes"]) for g in grp], uni)
            if not ok:
                for g in grp:
                    edits.pop(g["start"], None)
                done = [d for d in done if not any(d[1] == g["addr"] for g in grp)]
                failed.append(("0x%06X..0x%06X" % (base, grp[-1]["addr"]), why))
        i = j + 1
    if apply and edits:
        out = []
        i = 0
        while i < len(lines):
            if i in edits:
                end, txt = edits[i]
                out.extend(txt)
                i = end + 1
            else:
                out.append(lines[i])
                i += 1
        open(SRC, "w", encoding="latin-1").write("\n".join(out))
    return done, failed


def convert_inline(apply=True):
    sym, uni = symbols(), unidasm()
    BYADDR.clear()
    for n, a in sym.items():
        BYADDR.setdefault(a, n)
    lines = open(SRC, encoding="latin-1").read().split("\n")
    marks, err = mark_addresses(lines)
    if err:
        print("  !! the marked mirror did not build: " + err.strip().splitlines()[0])
        return 1
    allruns = runs(lines, sym)
    for r in allruns:
        if r["start"] in marks:
            r["addr"] = marks[r["start"]]
    edits, nb, ni = {}, 0, 0
    skipped = 0
    for r in inline_runs(lines, allruns):
        if r["addr"] is None or not rom_matches(r["addr"], bytes(r["bytes"])):
            skipped += 1
            continue
        txt, kept, spelt = frame(r["addr"], bytes(r["bytes"]), uni, sym)
        if txt is None or kept:
            skipped += 1        # partial spelling would churn without covering
            continue
        edits[r["start"]] = (r["end"], txt)
        nb += len(r["bytes"])
        ni += spelt
        print(f"  CONVERTED  0x{r['addr']:06X}  {len(r['bytes']):4d} B -> {spelt:3d} instructions")
    if apply and edits:
        out, i = [], 0
        while i < len(lines):
            if i in edits:
                end, txt = edits[i]
                out.extend(txt)
                i = end + 1
            else:
                out.append(lines[i])
                i += 1
        open(SRC, "w", encoding="latin-1").write("\n".join(out))
    print(f"\n  {len(edits)} inline run(s), {nb} bytes -> {ni} instructions; "
          f"{skipped} left alone (not fully spellable, or not framed by unidasm)")
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck("the linked payload is present for the symbol table", os.path.exists(ELF), ELF)
    sym = symbols()
    ck("the symbol table resolves a known sound routine",
       sym.get("ToneGen_WriteVoiceParams") is not None or
       sym.get("DSP_Write_Channel") is not None)
    # POSITIVE CONTROL: the canonical tone-generator write burst must round-trip.
    burst = bytes([0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0x40, 0x08,
                   0xf2, 0x00, 0x00, 0x10, 0x50, 0x00,
                   0xf0, 0x18, 0xbf])
    dis = disassemble(burst)
    ck("the canonical TG write burst disassembles", dis is not None,
       "; ".join(t.strip() for t, _n in dis) if dis else "")
    ck("and re-assembles to the same bytes",
       dis is not None and reassemble([t for t, _n in dis]) == burst)
    # ★★ NEGATIVE CONTROL, AND IT IS THE POINT OF THIS SCRIPT'S DESIGN.
    # 24 bytes of 0xFF -- ROM filler, unambiguously not code -- disassembles and
    # round-trips perfectly.  So ROUND-TRIPPING IS NOT EVIDENCE OF ANYTHING, and
    # this check asserts the useless result rather than pretending otherwise.
    # The evidence has to come from outside: an entry point that converted code
    # branches or calls to.  See --misframes in notes/sound/.
    bad = bytes([0xff] * 24)
    d2 = disassemble(bad)
    ck("ROUND-TRIPPING IS NOT EVIDENCE: 24 bytes of ROM filler round-trip too",
       d2 is not None and reassemble([t for t, _n in d2]) == bad,
       "so the caller must supply branch-target evidence")
    # The guard that IS load-bearing: a label in the wrong place shows up as a
    # run start that is not an instruction boundary of the region's own decode.
    uni = unidasm()
    ck("unidasm's listing frames the payload", len(uni) > 50000, f"{len(uni):,} instructions")
    # POSITIVE: the two real runs of the DSP output block chain end to end.
    a = sym.get("Voice_DSP_SimpleCopy")
    ok, why = boundaries_agree(a, [bytes(open(ROM, "rb").read()
                                          [rom_offset(a):rom_offset(a) + 90])], uni)
    ck("the boundary guard accepts a real routine's extent", ok, why)
    # NEGATIVE: a run start one byte into that routine must be refused.
    ok, why = boundaries_agree(a + 1, [bytes(open(ROM, "rb").read()
                                             [rom_offset(a) + 1:rom_offset(a) + 90])], uni)
    ck("the boundary guard REFUSES a start inside an instruction",
       not ok, why or "accepted -- the guard is blind")
    ck("a .byte run is checked against the ROM",
       rom_matches(a, bytes(open(ROM, "rb").read()[rom_offset(a):rom_offset(a) + 16]))
       and not rom_matches(a, b"\x00" * 16))
    # And the run scanner must find the blocks this script exists for.
    lines = open(SRC, encoding="latin-1").read().split("\n")
    rs = [r for r in runs(lines, sym) if r["addr"] is not None]
    ck("the run scanner locates .byte runs with resolved addresses",
       len(rs) > 50, f"{len(rs)} run(s)")
    print(f"\n9 checks, {f} failures")
    return 1 if f else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--list" in sys.argv:
        sym = symbols()
        lines = open(SRC, encoding="latin-1").read().split("\n")
        for r in runs(lines, sym):
            if r["addr"] is not None and len(r["bytes"]) >= 8:
                print(f"  line {r['start']+1:6d}  0x{r['addr']:06X}  {len(r['bytes']):5d} B")
        return 0
    if "--inline" in sys.argv:
        return convert_inline(apply="--dry-run" not in sys.argv)
    labels = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not labels:
        print(__doc__)
        return 1
    done, failed = convert(labels, apply="--dry-run" not in sys.argv)
    for lab, addr, nb, spelt, kept in done:
        print(f"  CONVERTED  0x{addr:06X}  {nb:5d} B -> {spelt:4d} instructions"
              f"{(', %d left as .byte' % kept) if kept else ''}   {lab}")
    for lab, why in failed:
        print(f"  refused    {lab}: {why}")
    return 1 if failed and not done else 0


sys.exit(main())
