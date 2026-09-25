#!/usr/bin/env python3
r"""seqeng_reframe.py -- re-frame MISFRAMED code spans using unidasm's framing.

QUESTION ANSWERED
-----------------
"This span of source lines is written as instructions starting at the wrong
bytes (a lone `.byte 0xd1` prefix followed by its operand bytes decoded as
bogus instructions).  What is the span written with the framing an
independent decoder (MAME unidasm, linear over the dump) sees, with every
instruction the LLVM backend can spell written as an instruction?"

HOW
---
For each requested zone (a source-line span whose first byte and end are
both instruction boundaries in the unidasm listing):
  * the zone's bytes are taken from the ORIGINAL dump at the addresses the
    line map (scripts/analysis/seqeng_line_map.py, a proven-inert mirror
    build) assigns to the lines -- never reconstructed from the directives;
  * the span is walked instruction by instruction on unidasm's framing and
    each instruction is offered to `llvm-mc --disassemble`; it is written as
    an instruction only when llvm decodes EXACTLY those bytes as ONE
    instruction AND re-assembling the printed text returns the same bytes;
    otherwise it is written as `.byte` with unidasm's decode as a comment;
  * every label in the span is re-placed at its address.  A label that lands
    INSIDE a re-framed instruction was a phantom boundary: if nothing outside
    the zone references it, it is dropped (reported); otherwise the zone is
    REFUSED for hand treatment;
  * every comment in the span is kept, as a full-line comment in front of the
    instruction that holds the byte its line used to start at.

Branch operands come out numeric (llvm-mc's own spelling); run
scripts/converters/symbolize_numeric_branches.py afterwards.

RUN
    python3 scripts/converters/seqeng_reframe.py v10 sequencer/sequencer_engine.s \
        --zones 12213-12254 [--zones ...] [--unidasm v10.unidasm] [--apply]
    python3 scripts/converters/seqeng_reframe.py v10 sequencer/sequencer_engine.s --auto [--apply]

  --zones L0-L1 are 1-based INCLUSIVE source line numbers of the CURRENT file.
  --auto takes every zone scripts/analysis/seqeng_misframe_zones.py reports.
  Dry run prints the before/after text; --apply writes (latin-1 bytes).
  The byte gate (make gate) is the certification, run it after --apply.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
from seqeng_line_map import line_map, strip_comment, ROOT, MC, IMAGES  # noqa: E402
from seqeng_misframe_zones import load_unidasm, zones as find_zones  # noqa: E402

LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi|reti|ex_ff|pop_f|push_f|push\s+sr|pop\s+sr)\b'
                 r'|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$|^(jr|jrl)\s+f\s*,')


def llvm_decode(bs):
    """-> text if llvm decodes bs as exactly one instruction, else None."""
    arg = " ".join("0x%02x" % b for b in bs)
    r = subprocess.run([MC, "-triple=tlcs900", "--disassemble", "-show-encoding"],
                       input=arg, capture_output=True, text=True)
    if "warning" in r.stderr or "error" in r.stderr:
        return None
    ins = [l for l in r.stdout.split("\n") if l.strip() and not l.strip().startswith(".text")]
    if len(ins) != 1:
        return None
    m = re.match(r'^\s*(.*?)\s*;\s*encoding:\s*\[(.*)\]', ins[0])
    if not m:
        return None
    enc = [int(x, 16) for x in m.group(2).split(",") if x.strip()]
    if enc != list(bs):
        return None
    text = re.sub(r'\s+', ' ', m.group(1).strip())
    text = re.sub(r'^(\S+) ', r'\1\t', text)
    return text


def llvm_encode(texts):
    """assemble a list of instruction texts, return list of byte lists (or None)."""
    src = "\n".join(texts) + "\n"
    r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding"], input=src,
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    encs = []
    for l in r.stdout.split("\n"):
        m = re.search(r';\s*encoding:\s*\[(.*)\]', l)
        if m:
            encs.append([int(x, 16) for x in m.group(1).split(",") if x.strip()])
    return encs if len(encs) == len(texts) else None


def refs_outside(name, image, rel, l0, l1):
    """count references to `name` in the image tree, excluding lines l0..l1 of rel
    and the label's own definition."""
    root = os.path.join(ROOT, image, "maincpu")
    r = subprocess.run(["grep", "-rnaw", "--include=*.s", name, root],
                       capture_output=True, text=True)
    n = 0
    for ln in r.stdout.split("\n"):
        if not ln:
            continue
        path, lno, text = ln.split(":", 2)
        code = strip_comment(text)
        if not re.search(r'\b%s\b' % re.escape(name), code):
            continue
        if re.match(r'^\s*%s:' % re.escape(name), code):
            continue
        if os.path.relpath(path, root) == rel and l0 <= int(lno) <= l1:
            continue
        n += 1
    return n


PAIRS = []
DISAGREE = []

# ★ OPERATION AGREEMENT.  A round trip proves llvm can re-emit the bytes; it
# cannot tell an LDA printed as a store from an LDA (seen here: f5 e0 31 is
# `lda xbc,(xwa+)` to unidasm and `stb_dpi a, 224` to llvm -- the C idiom
# `p = q++`, so unidasm is right).  So each llvm spelling must also AGREE with
# unidasm on the operation family, and every register llvm names must be one
# unidasm names.  Otherwise the instruction is written as `.byte` + unidasm's
# decode.  FAMILY maps an llvm mnemonic to the unidasm mnemonic(s) it may be.
FAMILY = {
    "ld": {"ld"}, "ldw": {"ldw", "ld"}, "ldb": {"ld"}, "cp": {"cp"}, "cpw": {"cp"},
    "jr": {"jr"}, "jrl": {"jrl"}, "call": {"call"}, "calr": {"calr"}, "jp": {"jp"},
    "add": {"add"}, "adc": {"adc"}, "sub": {"sub"}, "sbc": {"sbc"}, "and": {"and"},
    "or": {"or"}, "xor": {"xor"}, "mul": {"mul"}, "muls": {"muls"}, "div": {"div"},
    "divs": {"divs"}, "push": {"push"}, "pushw": {"push", "pushw"}, "pop": {"pop"},
    "popw": {"pop", "popw"}, "extz": {"extz"}, "exts": {"exts"}, "srl": {"srl"},
    "sll": {"sll"}, "sla": {"sla"}, "sra": {"sra"}, "rl": {"rl"}, "rr": {"rr"},
    "rlc": {"rlc"}, "rrc": {"rrc"}, "inc": {"inc"}, "dec": {"dec"}, "ret": {"ret"},
    "retd": {"retd"}, "lda": {"lda"}, "ldir": {"ldir"}, "ldirw": {"ldirw"},
    "ldi": {"ldi"}, "ldiw": {"ldiw"}, "neg": {"neg"}, "cpl": {"cpl"},
    "bit": {"bit"}, "set": {"set"}, "res": {"res"}, "tset": {"tset"}, "chg": {"chg"},
    "djnz": {"djnz"}, "scf": {"scf"}, "rcf": {"rcf"}, "zcf": {"zcf"}, "ccf": {"ccf"},
    "cpdi8": {"cp"}, "cpdi16": {"cp"}, "bitm": {"bit"}, "bitda": {"bit"},
    "resm": {"res"}, "resda": {"res"}, "setm": {"set"}, "setda": {"set"},
    "pushm": {"pushw", "push"}, "andmi8": {"and"}, "ormi16": {"or"}, "ormi8": {"or"},
    "submi16": {"sub"}, "addiw_da": {"add"}, "cpib_da": {"cp"}, "cpw_da": {"cp"},
    "stiw_da": {"ld"}, "stdi8": {"ld"}, "stda16": {"ld"}, "stb_erp": {"ld"},
    "ldb_erp": {"ld"}, "ldib_erp": {"ld"}, "ldmm8": {"ld"}, "ldmm16": {"ldw"},
    "ldda32": {"ld"}, "ldb_d8": {"ld"}, "ldw_d16": {"ld"}, "lda_d16": {"lda"},
    "lda_24": {"lda"}, "lda_rr": {"lda"}, "ld_rrw": {"ld"}, "ld_rrb": {"ld"},
    "ld_rrl": {"ld"}, "st_rrb": {"ld"}, "st_rrw": {"ld"}, "st_rrl": {"ld"},
    "call_24": {"call"}, "call16": {"call"}, "jp16": {"jp"}, "jp_rr": {"jp"},
    # extended-register (ERP) forms: llvm prints the register as its bank code
    # (251 = 0xFB = QIZH, 250 = QIZL, 230 = QC, ...); the text gets unidasm's
    # decode as a comment so a reader does not need the code table.
    "bit_erpb": {"bit"}, "res_erpb": {"res"}, "set_erpb": {"set"},
    "inc1b_erp": {"inc"}, "dec1b_erp": {"dec"}, "cp_erpb": {"cp"}, "cpib_erp": {"cp"},
    "incm": {"incw"}, "decm": {"decw"}, "incm8": {"inc"}, "decm8": {"dec"},
    "ex": {"ex"}, "mirr": {"mirr"}, "paa": {"paa"}, "link": {"link"}, "unlk": {"unlk"},
}
REGS = re.compile(r'\b(q?(?:x?(?:wa|bc|de|hl|ix|iy|iz|sp))|[wabcdehl]|q?[abcdehlw]|q?i[xyz][hl]|sr|f)\b', re.I)


def agree(lt, ut):
    lm = lt.split()[0].lower()
    um = ut.split()[0].lower() if ut.split() else ""
    fam = FAMILY.get(lm)
    if fam is None:
        # generic rule for the backend's many operand-form suffixes
        # (stda32, addda16, cpdm16, ex16, ...): the leading operation word
        # must be unidasm's, `st` counting as `ld`; registers are still checked.
        mm = re.match(r'^(ld|st|cp|add|adc|sub|sbc|and|or|xor|inc|dec|ex|push|pop|bit|set|res|mul|div)', lm)
        if not mm:
            return False
        op = "ld" if mm.group(1) == "st" else mm.group(1)
        fam = {op, op + "w"}
    if um not in fam:
        return False
    lops = lt.split(None, 1)[1] if len(lt.split(None, 1)) > 1 else ""
    uops = ut.split(None, 1)[1] if len(ut.split(None, 1)) > 1 else ""
    lr = {r.lower() for r in REGS.findall(lops)}
    ur = {r.lower() for r in REGS.findall(uops)}
    if lm in ("mul", "muls", "div", "divs"):
        # llvm names the 16-bit half (`div bc,(m)`), Toshiba/unidasm the 32-bit
        # register pair that holds dividend/product (`div XBC,(m)`): same register
        ur |= {r[1:] for r in ur if r.startswith("x")}
        lr = {r[1:] if r.startswith("x") and r[1:] in ur else r for r in lr}
    return lr <= ur
# `ei N` is only suspect when N is not an interrupt level (0..7): `ei 6 ... ei 0`
# brackets are real critical sections in the sequencer (v7 SeqPlay_DeactivateParts).
SUSPECT_NEW = re.compile(r'^db\b|\+\)|\(-|call 0x00|^(swi|halt|ldf|incf|decf|max|min|normal|reti)\b'
                         r'|^ei\s+0x(?!0[0-7]$)[0-9a-f]+$')


UNIDASM = os.environ.get("UNIDASM", os.path.expanduser("~/compartilhado/tools/unidasm"))


def fresh_unidasm(rom, base, a0, a1):
    """unidasm over [a0, a1) only, starting AT a0: the framing a routine that
    begins at a0 has, independent of whatever precedes it in the dump."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(bytes(rom[a0 - base:a1 - base]))
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", "%x" % a0],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    d = {}
    for ln in out.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln.strip())
        if m:
            d[int(m.group(1), 16)] = (len(m.group(2).split()), m.group(3).strip())
    d[a1] = (0, "<end>")
    return d


_LABELS = {}


def rom_labels(image):
    """address -> [names] of text symbols in the last build of the image
    (rebuilt_ROMs/, produced by `make`).  Addresses do not move under a
    byte-identical edit, so a slightly stale ELF still maps correctly."""
    if image not in _LABELS:
        nm = os.path.join(os.path.dirname(MC), "llvm-nm")
        elf = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % image)
        d = {}
        if os.path.exists(elf):
            for ln in subprocess.run([nm, "-n", elf], capture_output=True, text=True).stdout.split("\n"):
                p = ln.split()
                if len(p) >= 3 and p[1] in "tT" and not p[2].startswith((".", "__")):
                    d.setdefault(int(p[0], 16), []).append(p[2])
        _LABELS[image] = d
    return _LABELS[image]


def symbolize_imm(txt, image, prefer):
    """`ld xwa, 14961522` -> `ld xwa, FontPalette_Gradient7` when a label sits
    exactly at that ROM address.  Only 32-bit register loads / lda of a value in
    the maincpu ROM window; a name already used in the old text of the zone is
    preferred, then a non-positional name.  The byte gate checks the result."""
    m2 = re.match(r'^(add|sub|cp|and|or)\t(x\w+), (\d+)$', txt)
    if m2:
        # arithmetic on an address: only when the OLD text of the zone already
        # named a label at exactly that value (e.g. `.long MidiPart_ColWidthData`
        # that was the operand of this very `add`)
        val = int(m2.group(3))
        names = [n for n in rom_labels(image).get(val, []) if n in prefer]
        return "%s\t%s, %s" % (m2.group(1), m2.group(2), names[0]) if names else txt
    m = re.match(r'^(ld|lda|lda_24)\t(x\w+), \(?(\d+)\)?$', txt)
    if not m:
        return txt
    val = int(m.group(3))
    if not (0xE00000 <= val <= 0xFFFFFF):
        return txt
    names = rom_labels(image).get(val, [])
    if not names:
        return txt
    pick = [n for n in names if n in prefer] or \
           [n for n in names if not re.search(r'_0x[0-9A-Fa-f]+$', n)] or names
    name = pick[0]
    if m.group(1) == "ld":
        return "ld\t%s, %s" % (m.group(2), name)
    return "lda\t%s, (%s:24)" % (m.group(2), name) if m.group(1) == "lda_24" else txt


def reframe(image, rel, zlist, uni, rom, rows, src, require_sig=True, fresh=False):
    base = IMAGES[image]["base"]
    by_line = {ln: (a, sz) for ln, a, sz in rows}
    marked = sorted(by_line)
    edits = []
    for (l0, l1) in zlist:
        # address of first byte / end
        first = [ln for ln in marked if l0 <= ln <= l1]
        if not first:
            print("REFUSE %d-%d: no byte-emitting line" % (l0, l1))
            continue
        a0 = by_line[first[0]][0]
        last = first[-1]
        a1 = by_line[last][0] + (by_line[last][1] or 0)
        if fresh:
            uni = fresh_unidasm(rom, base, a0, a1)
        if a0 not in uni or a1 not in uni:
            print("REFUSE %d-%d: ends 0x%06X/0x%06X not unidasm boundaries" % (l0, l1, a0, a1))
            continue
        # walk unidasm framing
        insns = []
        x = a0
        ok = True
        while x < a1:
            if x not in uni:
                ok = False
                break
            n, t = uni[x]
            insns.append((x, bytes(rom[x - base:x - base + n]), t))
            x += n
        if not ok or x != a1:
            print("REFUSE %d-%d: unidasm walk does not land on 0x%06X" % (l0, l1, a1))
            continue
        starts = {a for a, _, _ in insns}
        # misframe signature: the source spells part of the span as a data
        # directive (.byte/.ascii fragment) or as an absurd mnemonic.  A zone
        # with neither may be unidasm being out of sync (after a table), not
        # the source being wrong -- refused unless --no-signature.
        sig = 0
        for ln in range(l0, l1 + 1):
            c = strip_comment(src[ln - 1]).strip()
            while LABEL_RE.match(c):
                c = c[LABEL_RE.match(c).end():].strip()
            if not c:
                continue
            if c.startswith(".") and ln in by_line:
                sig += 1
            elif ABS.match(c.lower()):
                sig += 1
        # shape guard: a misframed instruction leaves SHORT `.byte` fragments
        # (a prefix, an operand tail).  A long `.byte` run, a `.long`/`.short`
        # or an `.ascii` line inside a zone is more likely real data that
        # unidasm ran through out of sync (seen: a pointer table followed by
        # a `ret`) -- refused for hand treatment.
        shape_bad = None
        for ln in range(l0, l1 + 1):
            c = strip_comment(src[ln - 1]).strip()
            while LABEL_RE.match(c):
                c = c[LABEL_RE.match(c).end():].strip()
            if c.startswith(".") and ln in by_line:
                d = c.split()[0].lower()
                if d != ".byte" or len(c.split(None, 1)[1].split(",")) > 4:
                    shape_bad = c
                    break
        if shape_bad and require_sig and not fresh:
            print("REFUSE %d-%d: data-shaped line in zone: %s" % (l0, l1, shape_bad[:60]))
            continue
        if not sig and require_sig and not fresh:
            print("REFUSE %d-%d: no misframe signature (no .byte/.ascii fragment, no absurd mnemonic)" % (l0, l1))
            continue
        # label / comment / directive positions
        pre = {}     # addr -> list of lines to emit before the insn at addr
        tail = []    # items at a1 (after the last insn)
        refuse = None
        dropped = []
        for ln in range(l0, l1 + 1):
            text = src[ln - 1]
            # the address this line "sits at": its own if marked, else the next marked line's
            nxt = [m for m in marked if m >= ln]
            at = by_line[nxt[0]][0] if nxt and nxt[0] <= l1 else a1
            code = strip_comment(text).strip()
            cm = text[len(strip_comment(text)):].strip() if ";" in text else ""
            items = []
            lm = LABEL_RE.match(code)
            while lm:
                items.append(("label", lm.group(1)))
                code = code[lm.end():].strip()
                lm = LABEL_RE.match(code)
            if not code and not cm and not items:
                items.append(("raw", ""))
            if code and ln not in by_line:
                # non-emitting directive (.set etc): keep verbatim
                items.append(("raw", "\t" + code))
            if cm:
                items.append(("raw", cm if text.lstrip().startswith(";") else "\t" + cm))
            for kind_, val in items:
                if kind_ == "label" and at not in starts and at != a1:
                    # the label's address may be mid-instruction
                    k = refs_outside(val, image, rel, l0, l1)
                    if k:
                        refuse = "label %s at 0x%06X is mid-instruction and has %d outside refs" % (val, at, k)
                    else:
                        dropped.append((val, at))
                    continue
                line = (val + ":") if kind_ == "label" else val
                if at == a1:
                    tail.append(line)
                else:
                    # place in front of the insn that holds `at`
                    host = max(a for a in starts if a <= at)
                    pre.setdefault(host, []).append(line)
        if refuse:
            print("REFUSE %d-%d: %s" % (l0, l1, refuse))
            continue
        # decode-absurdity guard: if unidasm's OWN framing of the span reads as
        # data (db, auto-increment stores, low-memory calls, absurd mnemonics),
        # the span is data typed as code, not a misframe -- refuse it.
        bad_new = [t for _, _, t in insns if SUSPECT_NEW.search(t.lower())]
        if bad_new and require_sig:
            print("REFUSE %d-%d: unidasm framing also looks like data: %s" % (l0, l1, bad_new[0]))
            continue
        out = []
        n_insn = n_byte = 0
        prefer = set()
        for ln in range(l0, l1 + 1):
            prefer |= set(re.findall(r'\b[A-Za-z_]\w+\b', strip_comment(src[ln - 1])))
        for a, bs, t in insns:
            out += pre.get(a, [])
            txt = llvm_decode(bs)
            if txt is not None:
                enc = llvm_encode([txt])
                if enc is None or enc[0] != list(bs):
                    txt = None
            if txt is not None and not agree(txt, t):
                DISAGREE.append((a, txt, t))
                txt = respell(t, bs)
            elif txt is None:
                txt = respell(t, bs)
            if txt is not None:
                txt = symbolize_imm(txt, image, prefer)
                if "_erp" in txt.split()[0]:
                    txt += "\t; " + t.lower()
                out.append("\t" + txt)
                PAIRS.append((a, txt, t))
                n_insn += 1
            else:
                out.append("\t.byte " + ", ".join("0x%02x" % b for b in bs) +
                           "\t; " + t.lower())
                n_byte += 1
        out += tail
        edits.append((l0, l1, out, a0, a1, n_insn, n_byte, dropped))
    return edits


def respell(ut, bs):
    """Transliterate unidasm's text into llvm-mc syntax and keep the first
    variant that assembles to EXACTLY bs.  Used when llvm's own spelling of
    the bytes disagrees with unidasm (e.g. llvm prints `cpda8 xbc, (8990)`
    for `cp A,(0x231e)` -- right bytes, misleading register) -- the result
    then says what unidasm says, and the byte check proves it is the same
    instruction."""
    t = ut.strip().lower()
    if not t or " " not in t:
        return None
    m, ops = t.split(None, 1)
    ops = re.sub(r'\+0x([0-9a-f]+)\)', lambda mm: "+%d)" % int(mm.group(1), 16), ops)
    mems = re.findall(r'\((0x[0-9a-f]+)\)', ops)
    variants = [ops]
    for mem in mems:
        nv = []
        for v in variants:
            val = int(mem, 16)
            for suf in ((":16", ":24") if val > 0xff else (":8", ":16", ":24")):
                nv.append(v.replace("(%s)" % mem, "(0x%x%s)" % (val, suf), 1))
        variants = nv
    cands = []
    for mm in (m, m + "w", m + "b"):
        for v in variants:
            cands.append("%s\t%s" % (mm, re.sub(r'\s*,\s*', ', ', v)))
    for c in cands:
        enc = llvm_encode([c])
        if enc and enc[0] == list(bs):
            return c
    return None


def selftest():
    """pure-function control on synthetic pairs (not on tree data)."""
    cases = [("stb_dpi a, 224", "lda XBC,XWA+", False),     # llvm misreads f5 e0 31
             ("ldb_erp a, 251", "ld QIZH,A", True),
             ("ld xwa, (xsp+4)", "ld XWA,(XSP+0x04)", True),
             ("ld xbc, (xsp+4)", "ld XWA,(XSP+0x04)", False),
             ("jr c, 5", "jr C,0xf00000", True),
             ("and (xhl), xwa", "bit 0,(XHL)", False),        # the b3 c8 bug shape
             ("ldmm16 10377, 9830", "ldw (0x2889),(0x2666)", True),
             ("div bc, (xwa+38)", "div XBC,(XWA+0x26)", True),
             ("ld bc, (xwa+38)", "ld XBC,(XWA+0x26)", False),
             ("div xwa, xbc", "div XWA,BC", True),
             ("incm 1, (xsp+4)", "incw 1,(XSP+0x04)", True),
             ("incm8 1, (xwa+51)", "inc 1,(XWA+0x33)", True),
             ("incm 1, (xsp+4)", "inc 1,(XSP+0x04)", False),
             ("ex16 iz, ix", "ex IZ,IX", True),
             ("stda32 (32119), xhl", "ld (0x7d77),XHL", True),
             ("addda16 xwa, (1134)", "add WA,(0x046e)", False),   # llvm names WA as xwa
             ("cpda8 xbc, (8990)", "cp A,(0x231e)", False),       # llvm names A as xbc
             ("stb_dpi a, 224", "lda XBC,XWA+", False)]
    bad = [(l, u) for l, u, want in cases if agree(l, u) != want]
    for l, u in bad:
        print("SELFTEST FAIL", l, "|", u)
    print("SELFTEST", "PASS" if not bad else "FAIL")
    sys.exit(1 if bad else 0)


def main():
    if "--selftest" in sys.argv:
        selftest()
    ap = argparse.ArgumentParser()
    ap.add_argument("image", choices=sorted(IMAGES))
    ap.add_argument("file")
    ap.add_argument("--zones", action="append", default=[])
    ap.add_argument("--auto", action="store_true")
    ap.add_argument("--unidasm")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument("--no-signature", action="store_true")
    ap.add_argument("--fresh", action="store_true",
                    help="CODE-AS-DATA mode: decode each zone with unidasm starting AT its first "
                         "byte (not the global listing); skips the misframe-signature and shape "
                         "guards, KEEPS the decode-absurdity guard and the agreement check")
    ap.add_argument("--pairs", help="write llvm-text / unidasm-text pairs here for review")
    a = ap.parse_args()
    up = a.unidasm or os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom.unidasm" % a.image)
    uni = load_unidasm(up)
    rom = open(os.path.join(ROOT, IMAGES[a.image]["rom"]), "rb").read()
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    raw = open(path, "rb").read()
    src = raw.decode("latin-1").split("\n")
    zl = []
    for z in a.zones:
        l0, l1 = z.split("-")
        zl.append((int(l0), int(l1)))
    if a.auto:
        for l0, l1, _, _ in find_zones(a.image, a.file, uni):
            zl.append((l0, l1 - 1))
    rows = line_map(a.image, [a.file])[a.file]
    edits = reframe(a.image, a.file, zl, uni, rom, rows, src, not a.no_signature, a.fresh)
    tot = ni = nb = 0
    for l0, l1, out, a0, a1, n_insn, n_byte, dropped in edits:
        tot += a1 - a0
        ni += n_insn
        nb += n_byte
        print("ZONE %d-%d 0x%06X-0x%06X %d B -> %d insns, %d .byte%s" % (
            l0, l1, a0, a1, a1 - a0, n_insn, n_byte,
            ("  dropped phantom labels: " + ", ".join("%s@0x%06X" % d for d in dropped)) if dropped else ""))
        if not a.quiet:
            for ln in range(l0, l1 + 1):
                print("   - " + src[ln - 1])
            for o in out:
                print("   + " + o)
    if a.pairs:
        with open(a.pairs, "w") as f:
            for ad, lt, ut in PAIRS:
                f.write("%06x\t%-40s\t%s\n" % (ad, lt.replace("\t", " "), ut))
    for ad, lt, ut in DISAGREE:
        print("DISAGREE 0x%06X llvm=%r unidasm=%r -> respelled from unidasm, else .byte" % (ad, lt, ut))
    print("TOTAL %d zones %d B, %d insns, %d .byte" % (len(edits), tot, ni, nb))
    if a.apply and edits:
        for l0, l1, out, *_ in sorted(edits, key=lambda e: -e[0]):
            src[l0 - 1:l1] = out
        open(path, "wb").write("\n".join(src).encode("latin-1"))
        print("written", path)


if __name__ == "__main__":
    main()
