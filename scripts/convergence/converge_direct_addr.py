#!/usr/bin/env python3
"""
QUESTION ANSWERED
-----------------
"Can the synthetic mnemonics of the direct-address / displacement family be
retired in favour of the NATIVE LLVM mnemonic with the form carried in the
OPERAND, without changing a single ROM byte -- and exactly which sites can
not?"

    ldb_d8  a, (0x2877)            ->   ld  a, (0x2877:16)
    ldw_d16 xwa, (0x28af)          ->   ld  wa, (0x28af:16)      <- register too
    stb_d8  (0x7f42), l            ->   ld  (0x7f42:16), l
    lda_d16 xbc, (0xf1a0)          ->   lda xbc, (0xf1a0:16)
    lda_24  xwa, (ViewableProc)    ->   lda xwa, (ViewableProc:24)
    ld_sril xwa, (xsp + 0x0118)    ->   ld  xwa, (xsp + 0x0118)

METHOD, and why it is trustworthy
---------------------------------
The rewrite is NEVER inferred from the mnemonic suffix.  For every distinct
source spelling the script

  1. generates a small ordered list of CANDIDATE native spellings,
  2. assembles the OLD spelling and every candidate with `llvm-mc
     -show-encoding`, in one batch,
  3. compares the full encoding record -- the byte list AND the fixup lines,
     so a spelling whose bytes depend on an undefined symbol is compared
     symbolically rather than by guessing the symbol's value,
  4. accepts the FIRST candidate that is byte-and-fixup identical, and
  5. REFUSES the site otherwise, with the reason recorded.

Refusal is the normal outcome for some sites and is a finding, not a failure.
Two real classes show up:

  * `ld_sril` with a displacement that fits a signed 8-bit field.  The native
    `ld` picks the SHORT 3-byte (Xrr+d8) encoding -- `ld xwa,(xsp+8)` is
    `af 08 20` where `ld_sril xwa,(xsp+8)` is `e3 fd 08 00 20`.  Different
    bytes, so the site stays as it is.  This is the assessment's SHORT_FORM
    class, and no operand syntax available today can request the long form.
  * anything whose operand this script does not dare to touch (a macro
    argument, an unbalanced paren, a `.macro` body).

⚠ A DISPLACEMENT IS SIGNED.  `ld_sril` sites are copied through verbatim --
the operand text is not reformatted at all -- so the sign cannot be lost.  The
per-site assembly is what proves it: `+151` and `-105` assemble to different
byte strings and would be refused, not silently accepted.

⚠ These sources are latin-1.  Read and write is explicit; nothing else in the
file is touched, and the mnemonic+operand span is replaced in place so
leading whitespace, inline `;` comments and alignment survive.

EXACT COMMANDS (from the tree root)
-----------------------------------
    # census + per-site verification only, writes nothing:
    python3 scripts/convergence/converge_direct_addr.py --family lda_24

    # same, then rewrite the accepted sites:
    python3 scripts/convergence/converge_direct_addr.py --family lda_24 --apply

    # every family this script knows:
    python3 scripts/convergence/converge_direct_addr.py --family all --apply

`--mc PATH` pins the assembler.  The default is the coordinator's stable
snapshot, NOT the shared build: backend lanes re-link
`llvm-project/build/bin/llvm-mc` in place from uncommitted sources, so its git
commit does not identify it and two runs minutes apart can disagree.  Gate with
the same binary -- `make LLVM_MC=<the same path> gate-all` -- or the per-site
proof and the gate are measuring different assemblers.
"""

import argparse
import collections
import hashlib
import os
import re
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
DEFAULT_MC = os.path.join(HOME, "compartilhado/toolchain-snapshot/llvm-mc.snap")

# XRR -> the 16-bit and 8-bit register names that name the SAME field of the
# same register.  XWA is W:A, so its low byte is A and its low word is WA.
LO16 = {"xwa": "wa", "xbc": "bc", "xde": "de", "xhl": "hl",
        "xix": "ix", "xiy": "iy", "xiz": "iz", "xsp": "sp"}
LO8 = {"xwa": "a", "xbc": "c", "xde": "e", "xhl": "l"}

ENC_LINE = re.compile(r'^\s*(\S.*?)\s*; encoding: \[([^\]]*)\]\s*$')
FIXUP_LINE = re.compile(r'^\s*;\s*fixup .*$')


def split_two(ops):
    """Split an operand list on the top-level comma (parens may contain none,
    but a symbolic expression could)."""
    depth = 0
    for i, ch in enumerate(ops):
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif ch == ',' and depth == 0:
            return ops[:i].strip(), ops[i + 1:].strip()
    return None


def address_text(tok):
    """The address an operand names, whether the source parenthesised it or
    not.  Both spellings occur in this tree -- `lda_24 xbc, (0x041368)` and
    `lda_24 xbc, 0x041368` are the same instruction, because the synthetic
    mnemonics take a bare `directaddr` immediate.  The native mnemonics take
    a memory operand, which must be parenthesised, so both forms converge on
    the same `(addr:width)` text.  Returns None for anything that is not a
    single balanced expression."""
    t = tok.strip()
    if not t:
        return None
    if t.startswith('('):
        if not t.endswith(')'):
            return None
        depth = 0
        for i, ch in enumerate(t):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0 and i != len(t) - 1:
                    # e.g. `(a)+(b)` -- not a single parenthesised address
                    return None
        return t[1:-1].strip()
    if '(' in t or ')' in t:
        return None
    return t


def cands_src_direct(ops, width, regmap):
    """`<mnem> reg, (addr)` -> `ld reg', (addr:width)`"""
    parts = split_two(ops)
    if not parts:
        return []
    reg, mem = parts
    addr = address_text(mem)
    if addr is None:
        return []
    out = []
    for r in reg_candidates(reg, regmap):
        out.append("ld %s, (%s:%d)" % (r, addr, width))
    return out


def cands_dst_direct(ops, width, regmap, mnem="ld"):
    """`<mnem> (addr), reg` -> `ld (addr:width), reg'`"""
    parts = split_two(ops)
    if not parts:
        return []
    mem, reg = parts
    addr = address_text(mem)
    if addr is None:
        return []
    out = []
    for r in reg_candidates(reg, regmap):
        out.append("%s (%s:%d), %s" % (mnem, addr, width, r))
    return out


def cands_lda(ops, width):
    """`lda_* reg, (addr)` -> `lda reg, (addr:width)`"""
    parts = split_two(ops)
    if not parts:
        return []
    reg, mem = parts
    addr = address_text(mem)
    if addr is None:
        return []
    return ["lda %s, (%s:%d)" % (reg, addr, width)]


def cands_sri(ops):
    """`ld_sril reg, (base + disp)` -> `ld reg, (base + disp)`, operand text
    copied through byte for byte so the SIGN of the displacement cannot be
    reinterpreted."""
    parts = split_two(ops)
    if not parts:
        return []
    reg, mem = parts
    if not (mem.startswith('(') and mem.endswith(')')):
        return []
    return ["ld %s, %s" % (reg, mem)]


def reg_candidates(reg, regmap):
    """The register spelling to try, most-specific first.  `regmap` renames a
    32-bit name to the sub-register the operation actually touches; the
    original spelling is kept as a fallback so a name this table does not
    know is still given its chance."""
    r = reg.strip()
    low = r.lower()
    out = []
    if regmap and low in regmap:
        out.append(regmap[low])
    if low not in out:
        out.append(low)
    return out


FAMILIES = {
    # name        -> (candidate builder, human note)
    "ldb_d8":  (lambda ops: cands_src_direct(ops, 16, LO8),
                "8-bit load from a 16-bit direct address"),
    "ldw_d16": (lambda ops: cands_src_direct(ops, 16, LO16),
                "16-bit load from a 16-bit direct address"),
    "stb_d8":  (lambda ops: cands_dst_direct(ops, 16, LO8),
                "8-bit store to a 16-bit direct address"),
    "lda_d16": (lambda ops: cands_lda(ops, 16),
                "LDA of a 16-bit direct address"),
    "lda_24":  (lambda ops: cands_lda(ops, 24),
                "LDA of a 24-bit direct address"),
    "ld_sril": (lambda ops: cands_sri(ops),
                "32-bit load, (base register + d16)"),
}

ORDER = ["lda_24", "ldw_d16", "lda_d16", "ld_sril", "ldb_d8", "stb_d8"]


def tracked_sources(root):
    out = subprocess.run(["git", "ls-files", "-z", "*.s"], cwd=root,
                         capture_output=True, check=True)
    return [p.decode("latin-1") for p in out.stdout.split(b"\0") if p]


def line_regex(mnem):
    # leading whitespace, the mnemonic as a whole word, whitespace, operands,
    # then an optional inline comment.  The mnemonic must be the first thing
    # on the line -- a mnemonic inside a comment or a .ascii literal is not
    # matched, and neither is a macro DEFINITION line (`.macro ldb_d8 ...`).
    return re.compile(r'^([ \t]+)(' + re.escape(mnem) + r')([ \t]+)([^;]*?)([ \t]*)(;.*)?$')


def in_macro_body(lines):
    """Mark every line that sits between `.macro` and `.endm`."""
    flags = [False] * len(lines)
    inside = False
    for i, ln in enumerate(lines):
        s = ln.strip().lower()
        if s.startswith('.macro'):
            inside = True
            flags[i] = True
            continue
        if s.startswith('.endm'):
            inside = False
            flags[i] = True
            continue
        flags[i] = inside
    return flags


def assemble_records(texts, mc, workdir):
    """Assemble each text in isolation and return its (bytes, fixups) record,
    or None if it did not assemble.  Each text gets its own label so an error
    can be attributed to a line."""
    path = os.path.join(workdir, "cand.s")
    with open(path, "w", encoding="latin-1", errors="replace") as f:
        for i, t in enumerate(texts):
            f.write("L%d:\n\t%s\n" % (i, t))
    p = subprocess.run([mc, "-triple=tlcs900", "-show-encoding", path],
                       capture_output=True, text=True, errors="replace")
    bad = set()
    warned = collections.Counter()
    for m in re.finditer(r'^[^\n:]*:(\d+):\d+: (error|warning):', p.stderr, re.M):
        idx = (int(m.group(1)) - 1) // 2
        if 0 <= idx < len(texts):
            if m.group(2) == "error":
                bad.add(idx)
            else:
                warned[idx] += 1
    recs = {}
    cur = None
    for line in p.stdout.split("\n"):
        lm = re.match(r'^L(\d+):', line)
        if lm:
            cur = int(lm.group(1))
            continue
        if cur is None:
            continue
        m = ENC_LINE.match(line)
        if m:
            recs[cur] = [m.group(2)]
            continue
        if cur in recs and FIXUP_LINE.match(line):
            # keep the fixup text but drop the leading whitespace/comment
            recs[cur].append(re.sub(r'^\s*;\s*', '', line).strip())
            continue
        if line.strip():
            cur = None
    for i in bad:
        recs.pop(i, None)
    # ⚠ The record carries the DIAGNOSTIC COUNT as well as the bytes.  A
    # candidate that assembles to the ROM's bytes but makes the assembler
    # warn where the old spelling did not is a LOSS of information, not a
    # rename: `ld_sril xhl, (xbc + 0x00aa)` states the (Xrr+d16) form by
    # name, while `ld xhl, (xbc + 0x00aa)` is the spelling the encoder warns
    # about because +170 and -86 are different addresses that a d8 field
    # cannot tell apart.  Same bytes today, a trap for the next editor.
    # Refusing on the diagnostic keeps the source's statement as sharp as it
    # was and keeps the build's warning count meaningful.
    return [tuple(recs[i]) + ("warn=%d" % warned[i],) if i in recs else None
            for i in range(len(texts))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--family", action="append", required=True,
                    help="a family name, or 'all'")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--mc", default=DEFAULT_MC)
    ap.add_argument("--root", default=".")
    ap.add_argument("--refusals", help="write refused spellings to this CSV")
    args = ap.parse_args()

    fams = []
    for f in args.family:
        if f == "all":
            fams = list(ORDER)
            break
        if f not in FAMILIES:
            sys.exit("unknown family %r; known: %s" % (f, ", ".join(ORDER)))
        fams.append(f)

    mc = os.path.abspath(args.mc)
    print("llvm-mc      %s" % mc)
    print("llvm-mc sha  %s"
          % hashlib.sha256(open(mc, "rb").read()).hexdigest()[:16])
    root = os.path.abspath(args.root)
    files = tracked_sources(root)
    print("tracked .s   %d" % len(files))

    work = tempfile.mkdtemp(prefix="conv_disp_")
    grand = collections.Counter()
    refusal_rows = []

    for fam in fams:
        build, note = FAMILIES[fam]
        rx = line_regex(fam)
        # spelling -> list of (file, lineno)
        sites = collections.defaultdict(list)
        skipped_macro = 0
        for rel in files:
            path = os.path.join(root, rel)
            try:
                src = open(path, encoding="latin-1").read()
            except OSError:
                continue
            if fam not in src:
                continue
            lines = src.split("\n")
            macro = in_macro_body(lines)
            for i, ln in enumerate(lines):
                m = rx.match(ln)
                if not m:
                    continue
                if macro[i]:
                    skipped_macro += 1
                    continue
                ops = m.group(4).strip()
                if not ops:
                    continue
                sites[ops].append((rel, i))

        n_sites = sum(len(v) for v in sites.values())
        print("\n=== %-9s  %s" % (fam, note))
        print("    %d distinct operand spellings, %d sites%s"
              % (len(sites), n_sites,
                 "" if not skipped_macro
                 else ", %d skipped inside .macro bodies" % skipped_macro))
        if not sites:
            continue

        # ---- build candidates and verify per spelling -------------------
        spellings = sorted(sites)
        old_texts = ["%s %s" % (fam, s) for s in spellings]
        cand_lists = [build(s) for s in spellings]
        flat, index = [], []
        for si, cl in enumerate(cand_lists):
            for c in cl:
                index.append(si)
                flat.append(c)
        old_recs = assemble_records(old_texts, mc, work)
        new_recs = assemble_records(flat, mc, work) if flat else []

        accepted = {}
        refused = collections.Counter()
        for si, s in enumerate(spellings):
            n = len(sites[s])
            if old_recs[si] is None:
                refused["OLD_DID_NOT_ASSEMBLE"] += n
                refusal_rows.append((fam, s, n, "OLD_DID_NOT_ASSEMBLE", ""))
                continue
            if not cand_lists[si]:
                refused["NO_CANDIDATE_SHAPE"] += n
                refusal_rows.append((fam, s, n, "NO_CANDIDATE_SHAPE", ""))
                continue
            hit = None
            why = []
            for j, k in enumerate(index):
                if k != si:
                    continue
                if new_recs[j] is None:
                    why.append("%s -> did not assemble" % flat[j])
                elif new_recs[j][0] != old_recs[si][0]:
                    why.append("%s -> %s (want %s)"
                               % (flat[j], new_recs[j][0], old_recs[si][0]))
                elif new_recs[j] != old_recs[si]:
                    why.append("%s -> right bytes, but %s vs %s"
                               % (flat[j], new_recs[j][1:], old_recs[si][1:]))
                else:
                    hit = flat[j]
                    break
            if hit is None:
                kind = ("DIAGNOSTIC_OR_FIXUP_DIFFERS"
                        if all("right bytes" in w for w in why) and why
                        else "BYTES_DIFFER")
                refused[kind] += n
                refusal_rows.append((fam, s, n, kind, " | ".join(why)))
            else:
                accepted[s] = hit

        acc_sites = sum(len(sites[s]) for s in accepted)
        print("    accepted  %6d sites (%d spellings)"
              % (acc_sites, len(accepted)))
        for k, v in refused.most_common():
            print("    refused   %6d sites  %s" % (v, k))
        grand[fam + ":accepted"] += acc_sites
        for k, v in refused.items():
            grand[fam + ":refused:" + k] += v

        if not args.apply or not accepted:
            continue

        # ---- rewrite ----------------------------------------------------
        by_file = collections.defaultdict(list)
        for s, new in accepted.items():
            for rel, ln in sites[s]:
                by_file[rel].append((ln, s, new))
        changed_files = 0
        changed_lines = 0
        for rel, edits in by_file.items():
            path = os.path.join(root, rel)
            src = open(path, encoding="latin-1").read()
            lines = src.split("\n")
            for ln, s, new in edits:
                m = rx.match(lines[ln])
                assert m and m.group(4).strip() == s, \
                    "line moved under us: %s:%d" % (rel, ln + 1)
                # `new` is "<mnem> <operands>" -- keep the original leading
                # whitespace, the original gap after the mnemonic, the
                # original trailing whitespace and the original comment.
                nm, _, nops = new.partition(" ")
                lines[ln] = (m.group(1) + nm + m.group(3) + nops
                             + m.group(5) + (m.group(6) or ""))
                changed_lines += 1
            out = "\n".join(lines)
            with open(path, "w", encoding="latin-1") as f:
                f.write(out)
            changed_files += 1
        print("    rewrote   %6d lines in %d files"
              % (changed_lines, changed_files))

    if args.refusals and refusal_rows:
        import csv
        with open(args.refusals, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["family", "operands", "sites", "reason", "detail"])
            for r in sorted(refusal_rows, key=lambda x: (x[0], -x[2])):
                w.writerow(r)
        print("\nrefusals -> %s" % args.refusals)

    print("\n--- totals ---")
    for k in sorted(grand):
        print("%-40s %8d" % (k, grand[k]))


if __name__ == "__main__":
    main()
