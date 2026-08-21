#!/usr/bin/env python3
"""Why is so much of v7 still .byte? Because the assembler cannot say it.

The v7-vs-v9 territory diff (v7_undisassembled_spans.py) found 158,902 bytes
that v7 carries as data and v9 disassembles as code. The obvious reading is
that nobody got round to converting them. That is not the reason.

The tree must assemble BYTE-EXACTLY with llvm-mc, so a byte sequence can only be
written as an instruction if the TLCS-900 LLVM backend accepts that instruction.
Some forms it does not:

    and (xix), 0x7f      error: invalid operand for instruction
    ldcf 7, (xhl)        error: invalid operand for instruction
    scc c, a             error: invalid operand for instruction
    or (xix), a          fine -- encoding [0x84,0xe9]

Those three appear all through the unrolled bit-extraction loop at 0xFD3095, so
that block CANNOT be expressed as instructions today, however obviously it is
code. The blocker is backend coverage, and the fix lives in the LLVM tree
(~/compartilhado/llvm-project, branch tlcs900_backend), not here.

This script measures the blocker: it decodes each .byte block with unidasm --
which is complete where llvm-mc is not -- then tries to assemble each decoded
instruction with llvm-mc, and ranks the forms that fail by how many bytes they
block.

Run:  python3 scripts/analysis/llvm_missing_instruction_forms.py <file.s> [--top N]

Both operand orders are tried before a form is called missing, because unidasm
and llvm-mc disagree on order for some instructions -- unidasm prints
`sla 0x07,A`, llvm-mc wants `sla a, 7`, and without the swap every shift in the
ROM reads as a backend gap. Confirmed by hand after that fix:

    MISSING   and (mem), imm | bit imm, (mem) (both orders) | ldcf imm, (mem)
              | scc cc, reg | res imm, (mem)
    NOT A GAP sla imm, a -- llvm-mc accepts `sla a, 7`

⚠ Remaining entries are LEADS, not verdicts. `lda xbc, imm` still reports as
rejected and is not yet explained; confirm a form by hand before acting on it.
"""
import collections, os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
TMP = "/tmp/_missing_forms.bin"


def elf_syms():
    out = subprocess.run([NM, "--defined-only", "rebuilt_ROMs/kn5000_v7_program.llvm.elf"],
                         capture_output=True, text=True, cwd=REPO)
    d = {}
    for line in out.stdout.split("\n"):
        f = line.split()
        if len(f) == 3 and f[1] in ("t", "T"):
            d.setdefault(f[2], int(f[0], 16))
    return d


def byte_blocks(path, name2addr):
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    out, cur, label = [], [], None
    for ln in lines:
        m = re.match(r'^\s*\.byte\s+(.*)$', ln)
        if m:
            for t in m.group(1).split(","):
                t = t.strip()
                if t:
                    cur.append(int(t, 0))
        else:
            if cur:
                out.append((label, name2addr.get(label), bytes(cur))); cur = []
            lm = re.match(r'^([A-Za-z_][\w]*):', ln)
            if lm:
                label = lm.group(1)
    if cur:
        out.append((label, name2addr.get(label), bytes(cur)))
    return out


def unidasm(raw, addr):
    open(TMP, "wb").write(raw)
    out = subprocess.run([UNIDASM, TMP, "-arch", "tlcs900", "-basepc", hex(addr)],
                         capture_output=True, text=True).stdout
    insns = []
    for line in out.split("\n"):
        m = re.match(r'^[0-9a-f]+:\s+(?:[0-9a-f]{2} )+\s*(.+)$', line)
        if m:
            insns.append(m.group(1).strip())
    return insns


def _try(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input=text, capture_output=True, text=True)
    return "encoding:" in r.stdout


def assembles(text):
    """True if llvm-mc accepts the instruction in EITHER operand order.

    unidasm and llvm-mc disagree on operand order for some forms -- unidasm
    prints `sla 0x07,A` where llvm-mc wants `sla a, 7`. Without trying the swap,
    every shift in the ROM looks like a missing instruction. This removes the
    largest class of false accusations against the backend.
    """
    if _try(text):
        return True
    parts = text.split(None, 1)
    if len(parts) == 2 and parts[1].count(",") == 1:
        a, b = [x.strip() for x in parts[1].split(",")]
        if _try(f"{parts[0]} {b}, {a}"):
            return True
    return False


def form_of(insn):
    """Reduce an instruction to a FORM: mnemonic + operand shapes."""
    parts = insn.split(None, 1)
    mn = parts[0]
    if len(parts) == 1:
        return mn
    ops = []
    for o in parts[1].split(","):
        o = o.strip()
        if re.match(r'^0x[0-9a-f]+$|^-?\d+$', o):
            ops.append("imm")
        elif o.startswith("("):
            ops.append("(mem)")
        else:
            ops.append(o.lower())
    return f"{mn} {', '.join(ops)}"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    path = os.path.abspath(sys.argv[1])
    top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 20
    name2addr = elf_syms()
    blocks = byte_blocks(path, name2addr)
    fails = collections.Counter()
    fail_bytes = collections.Counter()
    checked, blocked_blocks = set(), 0
    for label, addr, raw in blocks:
        if addr is None or len(raw) < 4:
            continue
        insns = unidasm(raw, addr)
        bad = False
        for ins in insns:
            low = ins.lower()
            if low in checked:
                if low in fails:
                    bad = True
                continue
            checked.add(low)
            if not assembles(low):
                fails[form_of(low)] += 1
                bad = True
        if bad:
            blocked_blocks += 1
            fail_bytes[label] += len(raw)
    print(f"{os.path.basename(path)}: {blocked_blocks} blocks blocked by "
          f"instruction forms llvm-mc rejects, {sum(fail_bytes.values()):,} bytes\n")
    print(f"top {top} rejected FORMS (distinct instructions counted once):")
    for form, n in fails.most_common(top):
        print(f"   {n:5}  {form}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
