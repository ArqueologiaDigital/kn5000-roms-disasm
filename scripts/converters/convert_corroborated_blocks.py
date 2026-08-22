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
  EVIDENCE  the block's exact byte sequence must appear SOMEWHERE in v9 at a
            place v9 disassembles as code. Matching by ADDRESS was tried first
            and is wrong -- functions move between revisions, and converting on
            it rewrote obvious data tables as instructions. Matching by CONTENT
            says something about these bytes; matching by address does not.
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
    """Read .text symbols from a built ELF. FAILS LOUDLY if there are none.

    `make clean-all` deletes rebuilt_ROMs/, and this returned {} when the ELF was
    missing. Every block then resolved to "no address", nothing matched, and the
    converter printed its usual summary and "rewrote 0 file(s)" -- a completely
    successful-looking run over nothing. That happened twice before this guard
    existed. A missing input must be an error, not an empty result.
    """
    if not os.path.exists(os.path.join(REPO, elf)):
        sys.exit(f"{elf} does not exist -- run `make all` first.\n"
                 f"(A previous `make clean-all` removes it.)")
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
            # Strip trailing comments. Real lines look like
            #   .byte 0xff\t; call Malloc (v7 addr)
            # and int(tok, 0) throws on them -- which crashed this script on
            # whole files. The tree-wide sweep ran with 2>/dev/null and counted
            # every crash as "nothing to convert", reporting a clean zero.
            body = re.split(r'[;#]', m.group(1))[0]
            for tok in body.split(","):
                tok = tok.strip()
                if not tok:
                    continue
                try:
                    cur.append(int(tok, 0))
                except ValueError:
                    # A symbolic .byte, e.g. `.byte FW_VERSION_BYTE`. Its value
                    # is not known here, so the block cannot be checked against
                    # the ROM and must not be converted. Mark it unusable rather
                    # than crashing -- an exception here previously took out
                    # whole files, and with stderr suppressed that read as
                    # "nothing to convert".
                    cur.append(None)
        else:
            if cur:
                if None not in cur:
                    out.append((label, name2addr.get(label), start, i - 1, bytes(cur)))
                cur, start = [], None
                # A label names ONE contiguous run. Blank lines separate .byte
                # runs all through this tree, and carrying the label past the
                # first run gave every later run the same base address -- the
                # second half of the lead-path corruption.
                label = None
            lm = re.match(r'^([A-Za-z_][\w]*):', ln)
            if lm:
                label = lm.group(1)
            elif ln.strip() and not ln.lstrip().startswith((';', '#')):
                # ROOT CAUSE of the lead-path corruption. A pending label must
                # STOP applying once a non-.byte line intervenes: after earlier
                # rounds convert something, a label can be followed by
                # instructions and only THEN by .byte lines, and those bytes do
                # not live at the label's address -- they live after the
                # instructions. Carrying the label across gave the block a base
                # address short by the size of that code, so lead/tail
                # arithmetic wrote the right number of bytes in the wrong
                # places. It could not appear before any conversion existed,
                # which is why this path seemed to work and then did not.
                label = None
    if cur and None not in cur:
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


def canonical(text):
    """Apply the known unidasm->llvm-mc rules deterministically, one result.

    Same rules as translate(), but picking the single spelling rather than
    yielding candidates, so a whole block can be assembled in one call.
    """
    parts = text.split(None, 1)
    if len(parts) != 2:
        return text
    mn, rest = parts[0], parts[1]
    if "/" in rest:
        rest = re.sub(r'\b(\w+)/\w+', r'\1', rest).lower()
    if rest.count(",") == 1:
        a, b = [x.strip() for x in rest.split(",")]
        if a.upper() in REG_BYTE and mn.lower() in ERPB_OPS:
            return f"{ERPB_OPS[mn.lower()]} 0x{REG_BYTE[a.upper()]:02x}, {b}"
        if mn.lower() == "lda" and not b.startswith("("):
            return f"{mn} {a}, ({b})"
        if mn.lower() in SHIFTS:
            return f"{mn} {b}, {a}"
        if a.upper() == "T" and mn.lower() in ("call", "jp", "jr", "jrl"):
            return f"{mn} ({b})"
    t = REGDISP.sub(lambda m: f"({m.group(1)})", f"{mn} {rest}")
    return t


def translate(text):
    """Yield candidate llvm-mc spellings of a unidasm instruction, best first.

    Confirmed rules, each checked by hand against llvm-mc before being added:
        lda XHL,XDE+0x0a  -> lda XHL,(XDE+0x0a)    parenthesise reg+disp
        lda XWA,0xf980    -> lda XWA,(0xf980)      parenthesise absolute
        lda XHL,XDE+XBC   -> lda XHL,(XDE+XBC)     parenthesise reg+reg
        sla 0x07,A        -> sla A, 0x07           shifts take the register first
    """
    yield text
    parts0 = text.split(None, 1)
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a, _b = [x.strip() for x in parts0[1].split(",")]
        _mn = parts0[0].lower()
        # unidasm prints a stack/register displacement as a RAW BYTE; llvm-mc
        # wants it SIGNED. `lda XSP,XSP+0xf2` is `bf f2 37` and spells as
        # `lda xsp, (xsp - 0x0e)`, because 0xf2 is -14. Parenthesising without
        # sign-extending gives a 5-byte encoding for a 3-byte instruction --
        # it assembles cleanly and is a different instruction.
        _m = re.match(r'^([A-Za-z]+)\+0x([0-9a-fA-F]{2})$', _b)
        if _m:
            _d = int(_m.group(2), 16)
            _sign = f"- 0x{0x100 - _d:02x}" if _d >= 0x80 else f"+ 0x{_d:02x}"
            yield f"{_mn} {_a.lower()}, ({_m.group(1).lower()} {_sign})"
        # 24-bit absolute address operands take the _24 / _da forms this tree
        # already uses (lda_24 appears 1,509 times in v9, ldw_da 477).
        if re.match(r'^0x[0-9a-fA-F]{5,6}$', _b):
            yield f"{_mn}_24 {_a.lower()}, ({_b})"
        _mp = re.match(r'^\(0x[0-9a-fA-F]{5,6}\)$', _b)
        if _mp and _mn == "ld":
            yield f"ldw_da {_a.lower()}, {_b}"
        if _mn == "ld" and re.match(r'^0x[0-9a-fA-F]{3,4}$', _b):
            yield f"ldw {_a}, {_b}"
    # Absolute memory operands take a SUFFIXED mnemonic in this tree, and which
    # suffix is right depends on operand width and direction:
    #   ld WA,(0x0460)   -> ldw_d16 wa, (0x0460)     [0xd1,0x60,0x04,0x20]
    #   ld (0x045e),WA   -> stda16 (0x045e), wa      [0xf1,0x5e,0x04,0x50]
    # Rather than encode a table of which applies when, offer every plausible
    # suffix and let the BYTE MATCH decide -- a wrong candidate simply does not
    # reproduce the bytes and is discarded. That is safe precisely because
    # selection never trusts "it assembled".
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a2, _b2 = [x.strip() for x in parts0[1].split(",")]
        _mn2 = parts0[0].lower()
        _absmem = re.compile(r'^\(0x[0-9a-fA-F]{2,6}\)$')
        if _absmem.match(_b2):                      # load from absolute
            # ldb_d8/ldb_da carry the BYTE-register forms:
            #   ld L,(0x0462) -> ldb_d8 l, (0x0462)   [0xc1,0x62,0x04,0x27]
            for suf in ("b_d8", "b_da", "_d16", "w_d16", "_da", "w_da",
                        "b_d16", "_24", "_d8", "w_d8"):
                yield f"{_mn2}{suf} {_a2.lower()}, {_b2}"
        # An immediate operated on an ABSOLUTE address takes the *di8/*di16
        # family, which is how this tree writes them (stdi8 appears 1,185 times
        # in v9, cpdi8 761, anddi8 266):
        #   cp (0xbca0),0xff  -> cpdi8 (0xbca0), 0xff   [0xc1,0xa0,0xbc,0x3f,0xff]
        #   ld (0x0ef0),0x01  -> stdi8 (0x0ef0), 0x01
        if _absmem.match(_a2) and re.match(r'^0x[0-9a-fA-F]+$', _b2):
            _base = "st" if _mn2 == "ld" else _mn2
            for suf in ("di8", "di16"):
                yield f"{_base}{suf} {_a2}, {_b2}"
        if _absmem.match(_a2):                      # store to absolute
            # stb_d8 carries the byte-register store:
            #   ld (0x0d57),A -> stb_d8 (0x0d57), a   [0xf1,0x57,0x0d,0x41]
            for pre in ("stb_d8", "stda16", "stw_da", "stb_d16", "stda8",
                        "stw_d16", "stb_da", "stw_d8"):
                yield f"{pre} {_a2}, {_b2.lower()}"
            for suf in ("_d16", "w_d16", "_da", "w_da", "b_d16"):
                yield f"{_mn2}{suf} {_a2}, {_b2.lower()}"

    # `pop IZ` has a ONE-byte form spelled `popw` ([0x4e]) alongside the
    # two-byte `pop iz` ([0xde,0x05]). Same trap as cps/lds: both assemble,
    # only one matches.
    if len(parts0) == 2 and parts0[1].count(",") == 0 and parts0[0].lower() in ("pop", "push"):
        yield f"{parts0[0].lower()}w {parts0[1].strip().lower()}"

    # A 16-bit address operand to `lda` takes lda_d16 with the address
    # PARENTHESISED: lda XIY,0x045b -> lda_d16 xiy, (0x045b)  [0xf1,0x5b,0x04,0x35]
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a6, _b6 = [x.strip() for x in parts0[1].split(",")]
        if parts0[0].lower() == "lda" and re.match(r'^0x[0-9a-fA-F]{3,4}$', _b6):
            yield f"lda_d16 {_a6.lower()}, ({_b6})"

    # REGISTER-INDEXED addressing, `ld A,(XIX+HL)`. The _dri forms take the
    # addressing bytes as plain immediates, so the register names have to be
    # translated: base and index each become their entry in the TLCS-900
    # register-byte table, and 0x07 is the sub-mode. Widths from the ROM:
    #   ld A,(XIX+HL)    -> ldb_dri a,   0x07, 0xf0, 0xec   c3 07 f0 ec 21
    #   ld WA,(XIX+HL)   -> ldw_dri wa,  0x07, 0xf0, 0xec   d3 07 f0 ec 20
    #   ld XIY,(XHL+IY)  -> ldl_dri xiy, 0x07, 0xec, 0xf4   e3 07 ec f4 25
    # The 32-bit base registers use the byte of their LOW half (XIX -> IXL).
    _RIDX = {"XIX": 0xF0, "XIY": 0xF4, "XIZ": 0xF8, "XSP": 0xFC,
             "XWA": 0xE0, "XBC": 0xE4, "XDE": 0xE8, "XHL": 0xEC,
             "IX": 0xF0, "IY": 0xF4, "IZ": 0xF8, "SP": 0xFC,
             "WA": 0xE0, "BC": 0xE4, "DE": 0xE8, "HL": 0xEC,
             "A": 0xE0, "C": 0xE4, "E": 0xE8, "L": 0xEC}
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a5, _b5 = [x.strip() for x in parts0[1].split(",")]
        _rr = re.match(r'^\(([A-Za-z]{2,3})\+([A-Za-z]{1,3})\)$', _b5)
        if parts0[0].lower() == "ld" and _rr:
            _base = _RIDX.get(_rr.group(1).upper())
            _index = _RIDX.get(_rr.group(2).upper())
            if _base is not None and _index is not None:
                for pre in ("ldb_dri", "ldw_dri", "ldl_dri"):
                    yield f"{pre} {_a5.lower()}, 0x07, 0x{_base:02x}, 0x{_index:02x}"

    # SHORT-IMMEDIATE forms. TLCS-900 encodes small immediates in two bytes and
    # this tree spells those `cps`/`lds` (284 and 176 uses in v9). The long form
    # assembles too -- `cp HL,0` gives a 4-byte [0xdb,0xcf,0x00,0x00] where the
    # ROM has the 2-byte [0xdb,0xd8] -- so only the byte match tells them apart.
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a4, _b4 = [x.strip() for x in parts0[1].split(",")]
        _mn4 = parts0[0].lower()
        if _mn4 in ("cp", "ld") and re.match(r'^(0x[0-9a-fA-F]+|\d+)$', _b4):
            yield f"{'cps' if _mn4 == 'cp' else 'lds'} {_a4.lower()}, {_b4}"
        # `bit N,(abs)` is bitda in this tree (547 uses in v9):
        #   bit 0,(0x0dd3) -> bitda 0, (0x0dd3)   [0xf1,0xd3,0x0d,0xc8]
        if _mn4 == "bit" and re.match(r'^\(0x[0-9a-fA-F]+\)$', _b4):
            yield f"bitda {_a4}, {_b4}"

    # SIZE SUFFIXES. This backend spells operand width with a b/w/l suffix, and
    # the short form is often a different, shorter encoding than the unsuffixed
    # one -- `ldb W, 0x68` is [0x20,0x68] where `ld W, 0x68` is [0xc8,0x03,0x68].
    # Both assemble; only one matches the ROM. Offer all three and let the byte
    # comparison choose, which is safe exactly because selection never trusts
    # "it assembled".
    if len(parts0) == 2 and parts0[1].count(",") == 1:
        _a3, _b3 = [x.strip() for x in parts0[1].split(",")]
        _mn3 = parts0[0].lower()
        if not _mn3.endswith(("b", "w", "l")) and "_" not in _mn3:
            for suf in ("b", "w", "l"):
                yield f"{_mn3}{suf} {_a3}, {_b3}"
        # 32-bit register loads from an absolute address take ldl_da:
        #   ld XDE,(0x1d5a) -> ldl_da xde, (0x1d5a)  [0xe2,0x5a,0x1d,0x00,0x22]
        if re.match(r'^\(0x[0-9a-fA-F]+\)$', _b3):
            for pre in ("ldl_da", "ldl_d8", "ldw_da", "ldb_da"):
                yield f"{pre} {_a3.lower()}, {_b3}"

    # `push 0x0004` is `0b 04 00` -- a 16-bit immediate push, which llvm-mc
    # spells `pushw`. Plain `push 0x0004` assembles to `09 04`, a different
    # (byte) instruction, so this must be selected by byte match, not by name.
    if len(parts0) == 2 and parts0[0].lower() == "push":
        yield f"pushw {parts0[1].strip()}"
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


def encode_block(texts):
    """Assemble a whole block in ONE llvm-mc call.

    The per-instruction path costs a process per line, which makes a tree-wide
    sweep take hours. Here the block goes in as one source and the encodings
    come back in order. Returns None if any line fails, so the caller can fall
    back to the slow path that tries alternative spellings line by line.
    """
    src = "\n".join(texts) + "\n"
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=src, capture_output=True, text=True, timeout=120)
    encs = ENC_RE.findall(r.stdout) if hasattr(ENC_RE, "findall") else []
    if len(encs) != len(texts):
        return None
    return [bytes(int(b, 16) for b in e.split(",") if b.strip()) for e in encs]


_ENCODE_CACHE = {}


def encode(text):
    """Assemble one instruction, memoised.

    Each candidate spelling costs a process, and the candidate list has grown as
    more addressing forms were learned. The same text recurs constantly across a
    2 MB image -- `ret`, `push XIZ`, `ld (XBC),XWA` -- so caching turns a
    quadratic-feeling sweep back into a linear one.
    """
    if text in _ENCODE_CACHE:
        return _ENCODE_CACHE[text]
    _ENCODE_CACHE[text] = _encode_uncached(text)
    return _ENCODE_CACHE[text]


def _encode_uncached(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=text, capture_output=True, text=True, timeout=30)
    m = ENC_RE.search(r.stdout)
    if not m:
        return None
    return bytes(int(b, 16) for b in m.group(1).split(",") if b.strip())


HEXNUM = re.compile(r'0x([0-9a-fA-F]{4,8})')


def symbolise(text, addr2name):
    """Replace numeric addresses with ELF symbol names where one matches exactly.

    Emitting `call 0xfd814f` beside lines that read `call FileIO_BuildFilePath`
    is a readability regression even when the bytes match -- it is what got
    convert_roundtrip_blocks.py marked unsafe. Only EXACT symbol addresses are
    substituted; a near miss is left numeric rather than guessed at.

    Verification order matters: the NUMERIC form is what gets round-tripped, so
    the decode is proven byte-for-byte. The SYMBOLIC form is what gets written,
    and llvm-mc emits a fixup for it, so its bytes are only settled at link
    time -- which the full `make clean-all && make all` byte-match gate checks.
    """
    def sub(m):
        v = int(m.group(1), 16)
        return addr2name.get(v, m.group(0))
    return HEXNUM.sub(sub, text)


def write_back(path, lines, todo, addr2name):
    """Replace each converted block's .byte lines with instruction lines."""
    for label, addr, a, b, raw, insns in sorted(todo, key=lambda t: -t[2]):
        out = ["\t" + symbolise(i, addr2name) for i in insns]
        lines[a:b + 1] = out
    open(path, "wb").write("\n".join(lines).encode("latin-1"))


def aligned(rom, addr, backs=(0x40, 0x80, 0x100)):
    """Is `addr` a real instruction boundary?

    A LABEL IS NOT NECESSARILY ONE. Converting a block that starts mid-instruction
    yields garbage that still round-trips byte-exactly, because the assembler
    reproduces whatever bytes it is given -- the gate cannot catch it. Two real
    examples caught this way, both reverted:

        ClampAndStoreParam_LoadReg3   6 bytes -> `max` + `ld XSP,0xf8c7c568`,
                                      loading SP with a constant that is
                                      literally the bytes that follow
        VoiceClaimExt2_Slot3_LoopBody2  opened `adc (XBC),L / ei 0x20` because
                                      the preceding block ends `...0x64, 0xee`
                                      and `ee 81` is ONE instruction spanning
                                      the label

    So: decode from several earlier points and require an instruction boundary to
    land exactly on `addr` from every one of them. A self-synchronising decode
    that converges from 0x40, 0x80 and 0x100 bytes back is good evidence.
    """
    off = addr - BASE
    for back in backs:
        if off - back < 0:
            return False
        tmp = os.path.join(tempfile.gettempdir(), "_align.bin")
        open(tmp, "wb").write(rom[off - back: off + 16])
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr - back)],
                             capture_output=True, text=True, timeout=60).stdout
        addrs = {int(m.group(1), 16) for m in re.finditer(r'^([0-9a-f]+):', out, re.M)}
        if addr not in addrs:
            return False
    return True


def main():
    argv = sys.argv
    if "--file" not in argv:
        sys.exit(__doc__)
    path = os.path.abspath(argv[argv.index("--file") + 1])
    apply_ = "--apply" in argv

    syms = elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    REACHABLE = None
    if "--reachable" in argv:
        import json
        REACHABLE = set(json.load(open(argv[argv.index("--reachable") + 1]))["targets"])
    v9 = v9_code_map()
    V9ROM = open(os.path.join(REPO, "original_ROMs", "kn5000_v9_program.rom"), "rb").read()
    V7ROM = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    lines, blocks = blocks_of(path, syms)

    stats = {"no-addr": 0, "not-corroborated": 0, "too-short": 0, "misaligned": 0,
             "warn": 0, "contains-data": 0, "roundtrip": 0, "ok": 0}
    todo = []
    for label, addr, a, b, raw in blocks:
        if addr is None:
            stats["no-addr"] += 1; continue
        off = addr - BASE
        # REACHABILITY, when a target list is supplied: something already
        # disassembled calls this address, so it is code, and a call target is an
        # instruction boundary by construction. Strictly better evidence than
        # matching bytes against another firmware revision, and it does not need
        # the alignment probe because alignment is guaranteed.
        if REACHABLE is not None:
            if addr not in REACHABLE:
                stats["not-corroborated"] += 1; continue
            insns, warn = disassemble(raw, addr)
            if warn or not insns:
                stats["warn"] += 1; continue
            if any(i.split()[0].lower() == "db" for i in insns if i.split()):
                stats["contains-data"] += 1; continue
            canon = [canonical(i) for i in insns]
            fast = encode_block(canon)
            if fast is not None and b"".join(fast) == raw:
                stats["ok"] += 1
                todo.append((label, addr, a, b, raw, canon))
            else:
                stats["roundtrip"] += 1
            continue

        # CORROBORATION BY CONTENT, not by address. Functions move between
        # revisions, so "v9 calls this OFFSET code" says nothing about this v7
        # block -- and acting on it produced demonstrably wrong conversions (a
        # repeating `fc 00 a2 f4` record became `swi 4 / nop / cp XIX,(XDE)`,
        # a lone 0x04 under a BitMask_* label became `max`). Instead: find this
        # exact byte sequence ANYWHERE in v9, and require v9 to disassemble it
        # as code there. Same bytes + independently classified as code in the
        # other revision is evidence about the bytes themselves.
        if len(raw) < 6:
            stats["too-short"] = stats.get("too-short", 0) + 1; continue
        if not aligned(V7ROM, addr):
            stats["misaligned"] = stats.get("misaligned", 0) + 1; continue
        where, corroborated = 0, False
        while True:
            j = V9ROM.find(raw, where)
            if j < 0:
                break
            if all(v9[j + k] == 1 for k in range(len(raw)) if j + k < len(v9)):
                corroborated = True; break
            where = j + 1
        if not corroborated:
            stats["not-corroborated"] += 1; continue
        # STRONGER: v9 must also have the SAME BYTES there. "v9 calls this offset
        # code" alone is far too weak -- v7 and v9 are different revisions, so the
        # same offset need not hold the same content. Applying on the weak
        # criterion produced demonstrably wrong output: a repeating `fc 00 a2 f4`
        # record became `swi 4 / nop / cp XIX,(XDE)` three times, a lone 0x04
        # under a label named BitMask_* became `max`, and a 3-byte table
        # (04 40 0a, 04 40 0b, 04 40 0c ...) became instructions. All round-tripped
        # byte-exactly. Byte-exactness is necessary and nowhere near sufficient.
        insns, warn = disassemble(raw, addr)
        if warn or not insns:
            stats["warn"] += 1; continue
        # `db` is unidasm declining to decode. A block containing one is data,
        # or partly data, and must not be rewritten as instructions.
        if any(i.split()[0].lower() == "db" for i in insns if i.split()):
            stats["contains-data"] = stats.get("contains-data", 0) + 1; continue
        # Fast path: canonicalise every line with the known rules, then assemble
        # the whole block in one call. Falls through to the per-line search only
        # when that does not reproduce the bytes.
        canon = [next(iter(translate(i))) if False else canonical(i) for i in insns]
        fast = encode_block(canon)
        if fast is not None and b"".join(fast) == raw:
            stats["ok"] += 1
            todo.append((label, addr, a, b, raw, canon))
            continue
        out, accepted = [], []
        for i in insns:
            enc, used = None, i
            for cand in translate(i):
                enc = encode(cand)
                if enc:
                    used = cand
                    break
            out.append(enc or b"\xff\xff\xff\xff\xff")
            accepted.append(used)
        rebuilt = b"".join(out)
        if rebuilt != raw:
            stats["roundtrip"] += 1; continue
        stats["ok"] += 1
        # Write the ACCEPTED spelling, not unidasm's. They differ -- unidasm
        # prints `sla 0x07,A` where llvm-mc needs `sla A, 0x07` -- and writing
        # the unverified text would emit a file that does not assemble.
        todo.append((label, addr, a, b, raw, accepted))

    addr2name = {a: n for a, n in syms.items()}
    if apply_ and todo:
        write_back(path, lines, todo, addr2name)
    print(f"{len(blocks)} .byte blocks in {os.path.basename(path)}"
          + ("   [WRITTEN]" if apply_ and todo else ""))
    print(f"   no address (label not in ELF) ... {stats['no-addr']}")
    print(f"   v9 does NOT call it code ....... {stats['not-corroborated']}")
    print(f"   under 6 bytes (too weak) ....... {stats['too-short']}")
    print(f"   label is not an insn boundary .. {stats['misaligned']}")
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
