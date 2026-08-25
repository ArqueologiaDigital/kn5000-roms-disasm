#!/usr/bin/env python3
"""prom_c / prom_d PROSE CITATION CHECK -- does `<instruction>` at 0xADDR start at 0xADDR?

WHAT QUESTION THIS ANSWERS
--------------------------
Round-1 audit finding F6 (and F2 on another lane) is this tree's named recurring defect:
a header quotes an instruction and cites an address one or two bytes PAST the opcode --
normally the first byte of an immediate operand.  `prom_c_audit_callsites.py --evidence`
cannot see those: it inspects only citations that name a CALL SITE, and classifies a
sentence like

    ; Evidence: `mul BC,0x012C / add BC,0x0010` at 0xFAD850.

as PROSE.  Both of prom_c's two real off-by citations (0xFAD850 and 0xFAD86E, audit F6)
were of exactly that shape.

WHAT IT CHECKS
--------------
Only citations of the exact form  `<quoted instruction run>` at 0x<ADDR>  -- backtick,
whitespace, "at", whitespace, a six-hex-digit address, nothing else in between.  The
address -> instruction map is not decoded: it is read out of the trailing
`; FAD84D  mul BC,0x012c` comment that every converted line already carries, i.e. the
assembler's own view of where each instruction starts.

    ok           the quoted run sits contiguously starting at the cited address.
    ★ OFF-BY-n   the run sits at ADDR-n instead, 1 <= n <= 8.  ★ THIS IS THE DEFECT.
                 THE COUNT MUST BE ZERO.
    anchor-last  the run's LAST element sits at the cited address -- the convention
                 "`cp X / jr Z` at <the jr>".  Legal here; reported, never failed.
    not-found    the quote is abbreviated or paraphrased and no contiguous match was
                 found within the window.  Reported, never failed -- it is a limit of
                 this checker, not a finding about the source.
    outside      the cited address is not in this image's converted text (a data
                 address, a RAM address, or an address in prom_a/prom_b).

⚠ WHAT THIS DOES NOT CHECK.  A citation with no backticked instruction beside it -- a
bare "at 0xNNNNNN" -- is invisible here, because nothing in the sentence says what is
supposed to be there.  Those still need reading by hand.

Matching is prefix-based on a normalisation that lowercases, removes whitespace and
strips leading zeros from hex literals, so `call` matches `call 0xfca746` and
`cp BC,0x80` matches `cp BC,0x0080`.

USAGE
    python3 notes/prom_c_prose_citation_check.py             # summary; exit != 0 on OFF-BY
    python3 notes/prom_c_prose_citation_check.py --verbose   # every citation, classified
    python3 notes/prom_c_prose_citation_check.py --selftest  # inject the audit's own
                                                             # 0xFAD850 and require a catch
"""
import re
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = [
    os.path.join(ROOT, "prom_c", "wsa1_prom_c.s"),
    os.path.join(ROOT, "prom_d", "wsa1_prom_d.s"),
]

INSN = re.compile(r";\s([0-9A-F]{6})\s\s(.+?)\s*$")
CITE = re.compile(r"`([^`]{2,140})`\s+at\s+0x([0-9A-Fa-f]{6})(?![0-9A-Fa-f])")
WINDOW = 8          # how far back an off-by citation is looked for


BYTELIST = re.compile(r"^(?:[0-9a-f]{2}\s+)+(?=[A-Za-z.])")


def strip_bytes(text):
    """Some converted lines print the raw bytes between the address and the
    disassembly (`; FB817E  1e b9 ef          calr 0xfb713a`).  Drop them."""
    return BYTELIST.sub("", text)


def norm(text):
    text = text.split("[llvm-mc")[0]
    text = re.sub(r"\s+", "", text).lower()
    return re.sub(r"0x0+([0-9a-f])", r"0x\1", text)


def load(path):
    insn, blocks, cur, cur_start = {}, [], [], None
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            stripped = line.lstrip()
            if stripped.startswith(";"):
                if cur_start is None:
                    cur_start = lineno
                cur.append(stripped.lstrip(";").strip())
                continue
            if cur_start is not None:
                blocks.append((cur_start, " ".join(cur)))
                cur, cur_start = [], None
            m = INSN.search(line)
            if m:
                insn[int(m.group(1), 16)] = strip_bytes(m.group(2))
    if cur_start is not None:
        blocks.append((cur_start, " ".join(cur)))
    return insn, sorted(insn), blocks


def run_matches(parts, start, insn, addrs, index):
    """True iff the quoted run sits contiguously with its first element at `start`."""
    if start not in index:
        return False
    i = index[start]
    for part in parts:
        if i >= len(addrs):
            return False
        if not norm(insn[addrs[i]]).startswith(norm(part)):
            return False
        i += 1
    return True


def classify(path, extra_blocks=()):
    insn, addrs, blocks = load(path)
    index = {a: i for i, a in enumerate(addrs)}
    known = {v.split()[0].lower() for v in insn.values() if v.split()}
    lo, hi = (addrs[0], addrs[-1]) if addrs else (0, -1)
    rows = []
    for start_line, text in list(blocks) + list(extra_blocks):
        for m in CITE.finditer(text):
            quoted, addr = m.group(1), int(m.group(2), 16)
            parts = [p.strip() for p in quoted.split(" / ") if p.strip()]
            if not parts or parts[0].split()[0].lower() not in known:
                continue                       # not an instruction quote
            if addr < lo or addr > hi:
                rows.append(("outside", start_line, quoted, addr, 0))
                continue
            if run_matches(parts, addr, insn, addrs, index):
                rows.append(("ok", start_line, quoted, addr, 0))
                continue
            hit = None
            for back in range(1, WINDOW + 1):
                if run_matches(parts, addr - back, insn, addrs, index):
                    hit = back
                    break
            if hit is not None:
                rows.append(("OFF-BY", start_line, quoted, addr, hit))
                continue
            if addr in index and norm(insn[addr]).startswith(norm(parts[-1])):
                rows.append(("anchor-last", start_line, quoted, addr, 0))
            else:
                rows.append(("not-found", start_line, quoted, addr, 0))
    return rows, os.path.basename(path)


def main():
    verbose = "--verbose" in sys.argv
    selftest = "--selftest" in sys.argv
    offby = 0
    injected = 0
    for path in SOURCES:
        extra = ()
        if selftest and path.endswith("prom_c.s"):
            # audit finding F6 verbatim: the address is the first immediate byte of the
            # `mul BC,0x012c` that starts at 0xFAD84D.
            extra = ((0, "SELFTEST `mul BC,0x012C / add BC,0x0010` at 0xFAD850"),)
        rows, name = classify(path, extra_blocks=extra)
        tally = {}
        for kind, line, quoted, addr, n in rows:
            tally[kind] = tally.get(kind, 0) + 1
            if kind == "OFF-BY":
                offby += 1
                if selftest and line == 0:
                    injected += 1
                print(f"  ★ OFF-BY-{n}   {name}:{line}  `{quoted}` cited at 0x{addr:06X}"
                      f" -- the run starts at 0x{addr - n:06X}")
            elif verbose:
                print(f"    {kind:<12} {name}:{line}  `{quoted}` at 0x{addr:06X}")
        summary = " · ".join(f"{k} {v}" for k, v in sorted(tally.items()))
        print(f"--- {name}: {len(rows)} citation(s) -- {summary or 'none'}")
    print()
    if selftest:
        if injected != 1:
            print("SELFTEST FAILED: the injected 0xFAD850 citation was NOT caught.")
            return 1
        print(f"selftest: the injected 0xFAD850 citation was caught "
              f"({offby} OFF-BY total, 1 of them injected).")
        return 0
    print(f"OFF-BY citations: {offby}" + ("  ★ MUST BE ZERO" if offby else ""))
    return 1 if offby else 0


if __name__ == "__main__":
    sys.exit(main())
