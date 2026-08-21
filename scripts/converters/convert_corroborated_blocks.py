#!/usr/bin/env python3
"""Convert v7 .byte blocks to instructions -- but only where v9 CORROBORATES.

Replaces the guesswork in convert_roundtrip_blocks.py, which is marked unsafe:
its "does this block contain control flow" test rejects clean fall-through basic
blocks (they have none, by construction, in a tree delimited by labels), and its
output is non-symbolic decimal, which is a readability regression the byte-match
gate cannot catch.

This one decides with evidence instead of shape:

  ADDRESS   a block's ROM address is the address of the label directly above it,
            read from rebuilt_ROMs/kn5000_v7_program.llvm.elf.
  EVIDENCE  the block is converted only if v9 disassembles the SAME offsets as
            CODE (per scripts/analysis/v7_undisassembled_spans.py's territory
            map). v9 is an independent revision, so this is corroboration, not
            a guess about what the bytes look like.
  SAFETY    every instruction is re-assembled and must reproduce the original
            bytes; any mismatch, or any invalid-encoding warning, drops the
            whole block.
  READABLE  branch targets and absolute addresses are emitted as SYMBOLS where
            the ELF has one, so converted code matches the surrounding style.

Run:  python3 scripts/converters/convert_corroborated_blocks.py --file <path.s> [--apply]
      Default is a dry run that reports what it would convert and why not.

STANDING RESULT on v7/maincpu/midi/midi_dispatch_handlers.s (2026-08-21), after
the toolchain learned the real mnemonics (tlcs900_backend@6c3c6d755ba2):

    623 .byte blocks
        124  v9 does not call these offsets code   -- no corroboration
        203  contain `db` -- unidasm declines to decode them, so data
        283  fail the byte round-trip              -- see the gaps below
         13  CONVERTIBLE, 462 bytes
      (invalid encodings: 0, down from 487 before the mnemonic fix)

WHAT STILL BLOCKS THE 283 are genuine backend gaps, not syntax:

    QIZH / QIZL / QIXH ...   the 8-bit halves of the Q register bank. MAME's
                             dasm900.cpp names them; the LLVM backend defines
                             QWA..QSP but not their byte halves. 46 instances.
    incw 1,(XSP+0x04)        unrecognized mnemonic in this form
    ld E,(XWA+)              post-increment addressing

⚠ THIS SCRIPT DOES NOT WRITE ANYTHING YET, deliberately. Verifying that 13
blocks round-trip is not the same as being able to emit them well: the decoded
text has raw numeric branch targets (`call 0xfd814f`), and writing that into a
tree whose neighbouring lines read `call FileIO_BuildFilePath` is the same
readability regression that got convert_roundtrip_blocks.py marked unsafe. The
missing piece is symbolisation from the ELF, not more round-trip checking.

⚠ Byte-exactness is necessary, not sufficient. A block can round-trip perfectly
and still be data that happens to decode. That is what the v9 corroboration is
for, and it is still not proof -- v7 and v9 are different revisions, so the same
offset need not be the same function. Read the diff before applying.
"""
import os, re, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
NM = os.path.join(LLVM, "llvm-nm")
BASE = 0xE00000
ENC_RE = re.compile(r'[;#] encoding: \[([^\]]+)\]')


def elf_syms(elf):
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, cwd=REPO)
    syms = {}
    for line in out.stdout.split("\n"):
        f = line.split()
        if len(f) == 3 and f[1] in ("t", "T"):
            syms.setdefault(int(f[0], 16), f[2])
    return syms


def v9_code_map():
    """Byte map of v9 territory, 1 where v9 has CODE."""
    spec = os.path.join(REPO, "scripts", "analysis", "v7_undisassembled_spans.py")
    import importlib.util
    s = importlib.util.spec_from_file_location("spans", spec)
    m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
    return m.territory(m.runs("v9/maincpu/kn5000_v9_program.s", "v9/maincpu"))


def blocks_of(path, syms):
    """Yield (label, addr, line_start, line_end, raw_bytes) for each .byte run."""
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    out, cur, start, label = [], [], None, None
    name2addr = {n: a for a, n in syms.items()}
    for i, ln in enumerate(lines):
        m = re.match(r'^\s*\.byte\s+(.*)$', ln)
        if m:
            if start is None:
                start = i
            for tok in m.group(1).split(","):
                tok = tok.strip()
                if tok:
                    cur.append(int(tok, 0))
        else:
            if cur:
                out.append((label, name2addr.get(label), start, i - 1, bytes(cur)))
                cur, start = [], None
            lm = re.match(r'^([A-Za-z_][\w]*):', ln)
            if lm:
                label = lm.group(1)
    if cur:
        out.append((label, name2addr.get(label), start, len(lines) - 1, bytes(cur)))
    return lines, out


# unidasm and llvm-mc disagree on SYNTAX for some operands. These are not
# backend gaps -- the same bytes assemble fine once the text is in llvm-mc's
# form -- so the converter translates rather than giving up:
#
#   lda XHL,XDE+0x0a   ->  lda XHL,(XDE+0x0a)     parenthesise reg+disp
#   sla 0x07,A         ->  sla A, 0x07            shift takes the register first
#
# The tree's own sources already write `sla xhl, 8`, so llvm-mc's order is the
# convention here and unidasm is the outlier. Every translated line is still
# re-assembled and must reproduce the original bytes, so a bad translation
# cannot slip through -- it just fails the round-trip.
SHIFTS = ("sla", "sra", "srl", "sll", "rl", "rr", "rlc", "rrc")

# The TLCS-900 "register byte", from MAME's dasm900.cpp s_reg8 table. These name
# the byte halves of the index registers and the Q (previous-bank) set, which
# llvm-mc has no register operands for -- but which it CAN encode through the
# _erpb forms, where the register byte is passed as a plain immediate:
#
#     cp_erpb 0xfb, 0x10   ->  [0xc7,0xfb,0xcf,0x10]  =  unidasm's `cp QIZH,0x10`
#
# ⚠ Verified by round-trip, after I twice reported these as a missing-register
# gap in the backend. They are not missing; they are spelled differently. Do not
# reintroduce that claim without assembling one first.
REG_BYTE = {}
for _i, _n in enumerate(
        "A W QA QW C B QC QB E D QE QD L H QL QH "
        "IXL IXH QIXL QIXH IYL IYH QIYL QIYH "
        "IZL IZH QIZL QIZH SPL SPH QSPL QSPH".split()):
    REG_BYTE[_n] = 0xE0 + _i

# unidasm mnemonic -> the _erpb spelling llvm-mc accepts, where a verified
# sub-opcode exists. `ld`/`inc` have no _erpb equivalent found yet.
ERPB_OPS = {"cp": "cp_erpb", "add": "add_erpb", "sub": "sub_erpb",
            "and": "and_erpb", "xor": "xor_erpb", "or": "or_erpb"}
REGDISP = re.compile(r'(?<![\w(])(X?[A-Za-z]{2,3}\s*[+-]\s*0x[0-9a-fA-F]+)(?![\w)])')


def translate(text):
    """Yield candidate llvm-mc spellings of a unidasm instruction, best first.

    Confirmed rules, each checked by hand against llvm-mc before being added:
        lda XHL,XDE+0x0a  -> lda XHL,(XDE+0x0a)    parenthesise reg+disp
        lda XWA,0xf980    -> lda XWA,(0xf980)      parenthesise absolute
        lda XHL,XDE+XBC   -> lda XHL,(XDE+XBC)     parenthesise reg+reg
        sla 0x07,A        -> sla A, 0x07           shifts take the register first
    """
    yield text
    t = REGDISP.sub(lambda m: f"({m.group(1)})", text)
    if t != text:
        yield t
    parts = text.split(None, 1)
    if len(parts) != 2:
        return
    if parts[1].count(",") == 1:
        a, b = [x.strip() for x in parts[1].split(",")]
        # lda's source operand is always a memory reference; unidasm omits the
        # parentheses that llvm-mc requires.
        if parts[0].lower() == "lda" and not b.startswith("("):
            yield f"{parts[0]} {a}, ({b})"
        if parts[0].lower() in SHIFTS:
            yield f"{parts[0]} {b}, {a}"
        # `T` is the always-true condition; llvm-mc spells an unconditional
        # transfer without it, and wants the target as a memory reference.
        if a.upper() == "T" and parts[0].lower() in ("call", "jp", "jr", "jrl"):
            yield f"{parts[0]} ({b})"
            yield f"{parts[0]} {b}"
    # unidasm prints both names of a doubled condition code, `PE/OV`, `PO/NOV`;
    # llvm-mc takes either one alone.
    if "/" in parts[1]:
        yield f"{parts[0]} " + re.sub(r'\b(\w+)/\w+', r'\1', parts[1]).lower()
    # A byte-half or Q-bank register operand goes through the _erpb form with the
    # register byte as an immediate.
    if parts[1].count(",") == 1:
        a, b = [x.strip() for x in parts[1].split(",")]
        mn = parts[0].lower()
        if a.upper() in REG_BYTE and mn in ERPB_OPS:
            yield f"{ERPB_OPS[mn]} 0x{REG_BYTE[a.upper()]:02x}, {b}"


UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
_DIS_RE = re.compile(r'^[0-9a-f]+:\s+((?:[0-9a-f]{2} )+)\s*(.+)$')


def disassemble(raw, addr):
    """Decode with unidasm, not llvm-mc.

    llvm-mc's TLCS-900 DISASSEMBLER still cannot read these encodings even
    after the assembler learned their mnemonics -- `84 3C 7F` comes back as
    `push xix` plus garbage. The two directions are separate tables. unidasm
    decodes them correctly, so it is the decoder here and llvm-mc is used only
    to re-assemble and prove the bytes come back identical.
    """
    tmp = os.path.join(tempfile.gettempdir(), "_corrob_block.bin")
    open(tmp, "wb").write(raw)
    r = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                       capture_output=True, text=True, timeout=60)
    insns, warn = [], 0
    for line in r.stdout.split("\n"):
        m = _DIS_RE.match(line)
        if m:
            insns.append(m.group(2).strip())
        elif line.strip() and ":" in line:
            warn += 1
    return insns, warn


def encode(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=text, capture_output=True, text=True, timeout=30)
    m = ENC_RE.search(r.stdout)
    if not m:
        return None
    return bytes(int(b, 16) for b in m.group(1).split(",") if b.strip())


def main():
    argv = sys.argv
    if "--file" not in argv:
        sys.exit(__doc__)
    path = os.path.abspath(argv[argv.index("--file") + 1])
    apply_ = "--apply" in argv

    syms = elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    v9 = v9_code_map()
    lines, blocks = blocks_of(path, syms)

    stats = {"no-addr": 0, "not-corroborated": 0, "warn": 0, "contains-data": 0,
             "roundtrip": 0, "ok": 0}
    todo = []
    for label, addr, a, b, raw in blocks:
        if addr is None:
            stats["no-addr"] += 1; continue
        off = addr - BASE
        if not all(v9[off + k] == 1 for k in range(len(raw)) if off + k < len(v9)):
            stats["not-corroborated"] += 1; continue
        insns, warn = disassemble(raw, addr)
        if warn or not insns:
            stats["warn"] += 1; continue
        # `db` is unidasm declining to decode. A block containing one is data,
        # or partly data, and must not be rewritten as instructions.
        if any(i.split()[0].lower() == "db" for i in insns if i.split()):
            stats["contains-data"] = stats.get("contains-data", 0) + 1; continue
        out = []
        for i in insns:
            enc = None
            for cand in translate(i):
                enc = encode(cand)
                if enc:
                    break
            out.append(enc or b"\xff\xff\xff\xff\xff")
        rebuilt = b"".join(out)
        if rebuilt != raw:
            stats["roundtrip"] += 1; continue
        stats["ok"] += 1
        todo.append((label, addr, a, b, raw, insns))

    print(f"{len(blocks)} .byte blocks in {os.path.basename(path)}")
    print(f"   no address (label not in ELF) ... {stats['no-addr']}")
    print(f"   v9 does NOT call it code ....... {stats['not-corroborated']}")
    print(f"   invalid encodings .............. {stats['warn']}")
    print(f"   contains db (data, not code) ... {stats['contains-data']}")
    print(f"   failed byte round-trip ......... {stats['roundtrip']}")
    print(f"   CONVERTIBLE .................... {stats['ok']}"
          f"  ({sum(len(t[4]) for t in todo):,} bytes)")
    for label, addr, a, b, raw, insns in todo[:10]:
        print(f"     0x{addr:06X}  {label:44} {len(raw):5} B  {len(insns)} insns")
    return 0


if __name__ == "__main__":
    sys.exit(main())
