#!/usr/bin/env python3
"""Turn `llvm_roundtrip_autoforce.py` output into this tree's house listing style.

QUESTION IT ANSWERS
  "I have a byte-verified listing from the round-trip wrapper.  How do I get it into
   the form the rest of prom_c/wsa1_prom_c.s is written in, without hand-editing 400
   lines and hand-computing 60 branch displacements?"

WHAT IT CHANGES, AND WHY EACH CHANGE IS SAFE
  * `.byte 0xAA, 0xBB, ...`  ->  `extpfxN 0xAA, 0xBB, ...`
        notes/prom_c-llvm-mc-spellings.md: extpfx2..extpfx10 emit their operands as
        raw bytes, so this is the SAME bytes with the instruction boundary preserved.
  * `jr <cc>, <int>` / `jrl <cc>, <int>`  ->  `jr <cc>, L_XXXXXX`
        The wrapper prints raw displacements; llvm-mc relocates a LABEL correctly
        (same note).  The label address is taken from unidasm's own rendering in the
        trailing comment, not recomputed, so a wrong displacement cannot be invented
        here -- and if it were, the listing would no longer assemble to the ROM and
        the byte gate would fail.
  * `calr <int>`  ->  `calr (0xTARGET - 0xNEXT)`
        calr does NOT relocate; the constant-folded difference is the tree's idiom.
  * decimal immediates >= 256  ->  hex.
  * a label line is emitted for every intra-range branch target.

  ⚠ It changes SPELLING only.  Nothing here is evidence for anything; the proof that
  the result is right remains `scripts/analysis/assert_byte_identical.py`.

RUN
  python3 notes/llvm_roundtrip_autoforce.py c 0xF9973D 0x481 --quiet > /tmp/blk.s
  python3 notes/prom_c_listing_prep.py /tmp/blk.s --prefix KS > /tmp/blk.pretty.s
"""
import argparse
import re
import sys

LINE = re.compile(r'^\t(?P<code>.*?)\t; (?P<addr>[0-9A-F]{6})  (?P<txt>.*)$')
BYTES = re.compile(r'^\.byte (?P<b>(0x[0-9A-F]{2}(, )?)+)')
BRANCH = re.compile(r'^(?P<m>jrl?|jp)\s+(?P<rest>.*)$')
TXTTGT = re.compile(r'0x([0-9a-f]{6})\s*$')
CALR = re.compile(r'^calr\s+(?P<d>\d+)$')

# --- hand-verified spellings for instructions the LLVM disassembler will not spell ----
# Every row here comes from notes/prom_c-llvm-mc-spellings.md; the pattern is matched on
# the RAW BYTES the wrapper demoted to `.byte`, so a row can only ever change spelling,
# never bytes -- and notes/prom_c_verify_fragment.py re-proves that after every run.
def _sd(b):
    return b - 256 if b >= 128 else b


def known_spelling(bs):
    n = len(bs)
    if n == 2 and bs[0] == 0xEE and bs[1] == 0x0D:
        return "unlk32 xiz"
    if n == 4 and bs[0] == 0xEE and bs[1] == 0x0C:
        return "link32 0xEE, 0x0C, 0x%02X, 0x%02X" % (bs[2], bs[3])
    if n == 6 and bs[0] == 0xC2 and bs[4] == 0x3F:                      # cp (addr24),#imm8
        return "cpib_da 0x%06X, 0x%02X" % (bs[1] | bs[2] << 8 | bs[3] << 16, bs[5])
    if n == 5 and bs[0] == 0xBE and bs[2] == 0x02:                      # ld (xiz+d),#imm16
        return "ldw (xiz%+d), 0x%04X" % (_sd(bs[1]), bs[3] | bs[4] << 8)
    if n == 5 and bs[0] == 0x9E and bs[2] == 0x3F:                      # cp (xiz+d),#imm16
        return "cpw (xiz%+d), 0x%04X" % (_sd(bs[1]), bs[3] | bs[4] << 8)
    if n == 4 and bs[0] == 0x8E and bs[2] == 0x3F:                      # cp (xiz+d),#imm8
        return "cp (xiz%+d), 0x%02X" % (_sd(bs[1]), bs[3])
    if n == 5 and bs[0] == 0xF2 and bs[4] & 0xF8 == 0xB8:               # set b,(addr24)
        return "setda_24 %d, 0x%06X" % (bs[4] & 7, bs[1] | bs[2] << 8 | bs[3] << 16)
    return None



# --- SFR names, read out of include/tmp95c061_sfr.inc at run time --------------------
# The wrapper prints internal-I/O addresses as bare numbers.  Substituting the .equ name
# is a rename only: the assembler resolves the symbol to the same byte.
def _sfr_map():
    import os
    m = {}
    inc = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "include", "tmp95c061_sfr.inc")
    for line in open(inc):
        line = line.split(";")[0].strip()
        if line.startswith(".equ"):
            name, val = line[4:].split(",", 1)
            try:
                m[int(val.strip(), 0)] = name.strip()
            except ValueError:
                pass
    return m


SFR = _sfr_map()
SFR_OPS = ("ldio", "res_dd8", "set_dd8", "bit_dd8", "st_dd8b", "stw_dd8")


def name_sfr(code):
    head = code.split(None, 1)
    if len(head) != 2 or head[0] not in SFR_OPS:
        return code
    args = [x.strip() for x in head[1].split(",")]
    idx = 0 if head[0] == "ldio" else 1
    if idx < len(args):
        try:
            v = int(args[idx], 0)
        except ValueError:
            return code
        if v in SFR:
            args[idx] = SFR[v]
            return "%s\t%s" % (head[0], ", ".join(args))
    return code


DEC = re.compile(r'(?<![\w.])(\d{3,})(?![\w])')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--prefix", default="L")
    a = ap.parse_args()

    rows = []
    for line in open(a.src):
        m = LINE.match(line.rstrip("\n"))
        if not m:
            rows.append((None, None, None, line.rstrip("\n")))
            continue
        rows.append((int(m.group("addr"), 16), m.group("code"), m.group("txt"), None))

    addrs = [r[0] for r in rows if r[0] is not None]
    lo, hi = min(addrs), max(addrs)

    # pass 1: collect branch targets inside the range
    targets = set()
    for addr, code, txt, _ in rows:
        if addr is None:
            continue
        if BRANCH.match(code) or code.startswith("calr"):
            t = TXTTGT.search(txt)
            if t:
                v = int(t.group(1), 16)
                if lo <= v <= hi and BRANCH.match(code):
                    targets.add(v)

    def lbl(v):
        return "%s_%06X" % (a.prefix, v)

    # pass 2: emit
    out = []
    order = [r for r in rows if r[0] is not None]
    for i, (addr, code, txt, _) in enumerate(order):
        nxt = order[i + 1][0] if i + 1 < len(order) else None
        if addr in targets:
            out.append("%s:" % lbl(addr))
        b = BYTES.match(code)
        if b:
            bs = [x.strip() for x in b.group("b").split(",")]
            raw = [int(x, 16) for x in bs]
            # extpfx2..extpfx10 only (TLCS900InstrInfo.td:5255-5305) -- a 1-byte or >10-byte
            # run has no extpfx form and must stay a `.byte`, or llvm-mc rejects the line with
            # "unrecognized instruction mnemonic".  Hit on the 16-entry jump table at 0xF98F91,
            # where unidasm decodes single stray bytes as `db`.
            if 2 <= len(bs) <= 10:
                code = known_spelling(raw) or "extpfx%d %s" % (len(bs), ", ".join(bs))
            else:
                code = known_spelling(raw) or code
        else:
            mb = BRANCH.match(code)
            mc = CALR.match(code)
            if mb:
                t = TXTTGT.search(txt)
                if t:
                    v = int(t.group(1), 16)
                    if v in targets:
                        rest = mb.group("rest")
                        cc = rest.rsplit(",", 1)[0].strip() if "," in rest else None
                        code = "%s %s%s" % (mb.group("m"),
                                            (cc + ", ") if cc else "", lbl(v))
            elif mc and nxt is not None:
                t = TXTTGT.search(txt)
                if t:
                    code = "calr (0x%06X - 0x%06X)" % (int(t.group(1), 16), nxt)
            code = DEC.sub(lambda m: "0x%X" % int(m.group(1)), code)
            code = name_sfr(code)
        out.append("\t%-38s ; %06X  %s" % (code, addr, txt))
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
