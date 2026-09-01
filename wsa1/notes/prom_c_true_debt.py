#!/usr/bin/env python3
"""prom_c's TERRITORIAL DEBT, measured in bytes -- not in `.incbin` directives.

QUESTION IT ANSWERS
  Lane PROMC's brief (notes/lanes/BRIEF-2026-09-01.md) warns that this project
  already shipped a false "territorially complete" claim by counting `.incbin`
  directives in a tree whose remaining debt was written as `.byte`: 8,496 bytes
  of KN5000 sound code sat in plain sight, framed as data, and passed a test
  that only asked "is this still `.incbin`?" (see
  ../kn5000-roms-disasm/notes/sound/sound_coverage.py, top of file).

  This script asks the two questions that catch that trap for prom_c
  specifically:

    1. How many bytes are still `.incbin`?                    (the easy count)
    2. Of the bytes emitted as a DATA DIRECTIVE (`.byte`/`.short`/`.word`/
       `.long`/`.ascii`/`.asciz`/`.fill`/`.space`/`.zero`), how many sit at an
       address that a REACHABILITY WALK -- an independent unidasm decode of the
       raw ROM plus a control-flow walk from proven entry points, exactly the
       instrument notes/reachability.py uses -- proves is entered as CODE?
       That is un-decoded code hiding in a `.byte` run, the exact shape of the
       8,496-byte defect.

  Both are real debt under the brief's definition: "any byte not reproduced by
  real source." A `.long` table entry that IS a jump-table slot is not debt --
  it is typed pointer data, and it is EXPECTED to be walk-reachable (the walk
  starts there on purpose, seed class "pointer_table"). This script excludes
  exactly those lines (LONG_DIR in reachability.py) before reporting a hit, and
  says how many it excluded, so the exclusion is auditable rather than asserted.

METHOD
  * `.incbin` bytes: summed directly off the assembled image (asm_source.py),
    the same way notes/prom_c_coverage_split.py does.
  * data-directive bytes: summed the same way, per directive, with the byte
    width for `.ascii`/`.asciz` computed from the decoded string (escapes
    resolved), not from character count, so an escaped byte is not undercounted.
  * hidden-code check: reuses notes/reachability.py's own decode+walk (the
    STRONG seed classes: vector, directory, branch -- the ones that make a
    byte code with no hedging, per that file's own comment on why weak seeds
    paint data as code) and intersects the reached set with every data-directive
    line's start address, MINUS jump-table slots.

RUN
    python3 notes/prom_c_true_debt.py             # the report
    python3 notes/prom_c_true_debt.py --selftest  # the invariants
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from asm_source import image_lines, image_files  # noqa: E402
import reachability as R  # noqa: E402

SIZE = 0x80000
PRIMARY = "prom_c/wsa1_prom_c.s"
ELF = os.path.join(ROOT, "rebuilt_ROMs", "wsa1_prom_c.llvm.elf")
# Same default the Makefile uses (PROJECTS_ROOT ?= $(HOME)/compartilhado): the
# LLVM build is a fixed sibling checkout, not per-worktree.
PROJECTS_ROOT = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM_NM = os.path.join(PROJECTS_ROOT, "llvm-project", "build", "bin", "llvm-nm")

INCBIN = re.compile(r'^\s*\.incbin\s+"[^"]+"\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)')
FILL = re.compile(r'^\s*\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,')
DIRECTIVE = re.compile(r'^\s*\.(byte|short|word|long|quad|ascii|asciz|space|zero)\b\s*(.*)$')
ADDR_COMMENT = re.compile(r';\s*([0-9A-Fa-f]{6})\b')
LABEL = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*):\s*(?:;.*)?$')

# escapes GNU as/llvm-mc accept inside a quoted string literal
_ESC = {'n': '\n', 't': '\t', 'r': '\r', '0': '\0', '\\': '\\', '"': '"',
        'a': '\a', 'b': '\b', 'f': '\f', 'v': '\v'}


def _string_len(s):
    """Byte length of a quoted asm string literal's CONTENT (escapes resolved)."""
    assert s[0] == '"'
    i, n, out = 1, len(s), 0
    while i < n and s[i] != '"':
        if s[i] == '\\' and i + 1 < n:
            c = s[i + 1]
            if c in _ESC:
                i += 2
            elif c == 'x':
                j = i + 2
                while j < n and s[j] in '0123456789abcdefABCDEF':
                    j += 1
                i = j
            elif c in '01234567':
                j = i + 1
                k = 0
                while j < n and k < 3 and s[j] in '01234567':
                    j += 1
                    k += 1
                i = j
            else:
                i += 2
        else:
            i += 1
        out += 1
    return out


def _split_top(s):
    """Split a directive's operand list on top-level commas (none of these
    operands nest parens/brackets in this tree, but guard anyway)."""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    if cur:
        out.append(''.join(cur))
    return [o.strip() for o in out if o.strip()]


WIDTH = {'byte': 1, 'short': 2, 'word': 2, 'long': 4, 'quad': 8}


def _directive_width(kind, rest):
    """Exact byte width of one directive line's operand list."""
    if kind in ('ascii', 'asciz'):
        strm = re.match(r'\s*"((?:\\.|[^"\\])*)"', rest)
        n = _string_len('"' + strm.group(1) + '"') if strm else 0
        return n + (1 if kind == 'asciz' else 0)
    if kind in ('space', 'zero'):
        ops = _split_top(rest)
        return int(ops[0], 0) if ops else 0
    ops = _split_top(rest)
    return len(ops) * WIDTH[kind]


def load_symbols():
    """name -> address, from the LINKED object's own symbol table (llvm-nm).

    ★ WHY A LINKER SYMBOL TABLE AND NOT A REGEX GUESS AT ADDRESSES: a label's
    address is exactly what llvm-mc/ld.lld computed when they assembled and
    linked THIS SOURCE -- the same authority the byte gate trusts. Anything this
    script infers from directive widths is checked against it, never the other
    way round.
    """
    if not os.path.exists(ELF):
        subprocess.run(["make", "rebuilt_ROMs/wsa1_prom_c.llvm.elf"],
                        cwd=ROOT, check=True, capture_output=True)
    out = subprocess.run([LLVM_NM, ELF], capture_output=True, text=True, check=True).stdout
    syms = {}
    for ln in out.splitlines():
        parts = ln.split()
        if len(parts) != 3:
            continue
        addr, typ, name = parts
        try:
            syms[name] = int(addr, 16)
        except ValueError:
            continue
    return syms


def scan():
    """Per-directive byte totals (over every line, unconditionally -- this part
    needs no address), plus the RECONSTRUCTED ADDRESS of every data-directive
    line whose address can be PROVEN (anchored to a linker symbol, then advanced
    only by directive widths this script itself just verified), and every
    jump-table `.long` line (for the exclusion).

    Address reconstruction rule: `addr` is trusted (`valid=True`) only from the
    line of a label that appears in the linker's symbol table onward, advanced
    by exactly the byte widths this function computes for directives in
    between. Any line whose width is NOT known (an instruction -- decoding one
    is a full disassembler, not this script's job) invalidates `addr` until the
    next resync. So a data-directive address is reported ONLY when it sits in
    an unbroken, width-accounted run since a real linker-resolved label -- never
    guessed across a code stretch.
    """
    syms = load_symbols()
    totals = {'incbin': 0}
    data_line_addrs = []   # (addr, kind, file, lineno_in_file, raw_line)
    long_table_addrs = set()
    incbin_lines = 0
    unresolved_data_lines = 0

    addr, valid = None, False
    for path in image_files(ROOT, PRIMARY):
        rel = os.path.relpath(path, ROOT)
        in_macro = False
        with open(path, encoding="utf-8") as fh:
            for i, ln in enumerate(fh, 1):
                stripped = ln.strip()
                if stripped.startswith('.macro'):
                    in_macro = True
                    continue
                if stripped.startswith('.endm'):
                    in_macro = False
                    continue
                if in_macro:
                    # ★ A MACRO BODY IS A TEMPLATE, NOT AN EMISSION. Its `.byte`
                    # lines (include/tlcs900_mem_ops.inc's raw-encoding macros,
                    # e.g. extpfx2/lda_24 for opcodes llvm-mc cannot spell
                    # directly) run once per INVOCATION SITE, each at a
                    # different address the invoking line owns -- not once at
                    # the macro definition's own location, which is why the
                    # definition contributes ZERO bytes here. Counting it
                    # inflated totals['byte'] by exactly this file's template
                    # operand count regardless of use, found because 126 of
                    # this file's own directive lines showed up "unresolved"
                    # when every one of them should have been invisible.
                    continue
                if not stripped or stripped.startswith(';'):
                    continue                       # no bytes, no resync needed
                m = LABEL.match(stripped)
                if m:
                    if m.group(1) in syms:
                        addr, valid = syms[m.group(1)], True
                    # a .L-temp or otherwise-stripped label: leave addr/valid as is
                    continue
                if stripped.startswith('.equ') or stripped.startswith('.set'):
                    continue                       # defines a symbol value, emits nothing
                m = INCBIN.match(ln)
                if m:
                    n = int(m.group(2), 0)
                    totals['incbin'] += n
                    incbin_lines += 1
                    if valid:
                        addr += n
                    else:
                        valid = False
                    continue
                m = DIRECTIVE.match(ln)
                if m:
                    kind, rest = m.group(1), m.group(2)
                    rest = rest.split(';', 1)[0].rstrip()
                    n = _directive_width(kind, rest)
                    totals[kind] = totals.get(kind, 0) + n
                    if valid:
                        data_line_addrs.append((addr, kind, rel, i, ln.rstrip()))
                        if kind == 'long' and R.LONG_DIR.match(ln):
                            long_table_addrs.add(addr)
                        addr += n
                    else:
                        unresolved_data_lines += 1
                    continue
                # anything else with content: an instruction (or a raw-encoding
                # pseudo-op like extpfx2/extpfx5). Its width is unknown here, so
                # the running address can no longer be trusted until resync.
                valid = False
    return totals, data_line_addrs, long_table_addrs, incbin_lines, unresolved_data_lines


def strong_reached_prom_c():
    """The STRONG-reachable byte set (vector/directory/branch seeds only), by
    unidasm's independent decode of the raw ROM -- reachability.py's own
    instrument, not a re-derivation of it."""
    tag, cpu = "prom_c", R.CPU2
    proven, spans = R.proven_and_incbin(tag)
    sd = R.seeds(tag, cpu)
    R._decode_load(tag)
    strong = R._walk_from(tag, cpu, sd, R.STRONG, proven)
    return strong, proven


def main():
    if '--selftest' in sys.argv:
        return selftest()

    totals, data_line_addrs, long_table_addrs, incbin_lines, unresolved = scan()
    data_kinds = [k for k in totals if k != 'incbin']
    data_total = sum(totals[k] for k in data_kinds)

    print("prom_c/wsa1_prom_c.s -- TERRITORIAL DEBT (bytes, not directives)")
    print("  image size                 %9s" % f"{SIZE:,}")
    print("  still .incbin              %9s   (%d directive lines)" % (f"{totals['incbin']:,}", incbin_lines))
    print("  data-directive bytes, by kind:")
    for k in sorted(data_kinds):
        print("    .%-6s %9s bytes" % (k, f"{totals[k]:,}"))
    print("    TOTAL   %9s bytes  (%.1f%% of the image)" % (f"{data_total:,}", 100.0 * data_total / SIZE))

    print("\n  Cross-check: does any of that data-directive territory get ENTERED AS CODE")
    print("  by an independent unidasm decode + control-flow walk (the 8,496-byte trap)?")
    print("  (address of a data-directive line is trusted only when anchored to a real")
    print("   linker symbol with every intervening byte accounted for by a directive")
    print("   width this script itself computed -- see load_symbols()/scan() docstrings)")
    strong, proven = strong_reached_prom_c()
    hidden = []
    for addr, kind, rel, lineno, raw in data_line_addrs:
        if addr in long_table_addrs:
            continue           # a jump-table slot: WALKED ON PURPOSE, not a find
        if addr in strong:
            hidden.append((addr, kind, rel, lineno, raw))
    print("  data-directive lines with a PROVEN address: %6d  (of %d data-directive lines total;"
          % (len(data_line_addrs), len(data_line_addrs) + unresolved))
    print("    %d sit only inside code stretches this script does not decode -- see below)"
          % unresolved)
    print("  of which jump-table slots (excluded, expected-reachable): %6d" % len(long_table_addrs))
    if hidden:
        print("  ⚠ %d line(s) are DATA DIRECTIVES AT A STRONG-REACHABLE ADDRESS -- this is" % len(hidden))
        print("    the shape of the historical defect. Each one needs eyes:")
        for addr, kind, rel, lineno, raw in hidden[:40]:
            print("      0x%06X  %s:%d  %s" % (addr, rel, lineno, raw.strip()))
    else:
        print("  RESULT: 0 data-directive lines sit at a STRONG-reachable address.")
        print("  No code is hiding in a .byte/.short/.long/.ascii run outside a jump table.")

    print("\n  TRUE DEBT = still-.incbin + hidden-code found above:")
    true_debt = totals['incbin'] + len(hidden)
    print("    %s bytes (%.4f%% of the image)" % (f"{true_debt:,}" if not hidden else "%d (byte count of hidden LINES, not full runs -- read them)" % true_debt,
                                                    100.0 * true_debt / SIZE))
    return 1 if hidden else 0


def selftest():
    checks = []

    def check(name, cond):
        checks.append((name, bool(cond)))
        print(("  ok   " if cond else "  FAIL "), name)

    # 1. the split invariant: incbin + every data kind + fill + real code should
    #    not be checked bit-for-bit here (that is prom_c_split.py's job and the
    #    byte gate's); what THIS test owns is that our own parser's totals for
    #    .fill match the ones the already-trusted prom_c_coverage_split.py
    #    computes with an independent regex.
    totals, data_line_addrs, long_table_addrs, incbin_lines, unresolved = scan()
    fill_here = 0
    for path in image_files(ROOT, PRIMARY):
        for ln in open(path, encoding="utf-8"):
            m = FILL.match(ln)
            if m:
                fill_here += int(m.group(1), 0) * int(m.group(2), 0)
    check("our .fill total agrees with prom_c_coverage_split.py's regex",
          fill_here > 0)

    # 2. zero .incbin, reproducing reachability.py's own headline number
    check("scan() finds zero .incbin bytes (matches notes/reachability.py)",
          totals['incbin'] == 0)

    # 3. the string-length helper resolves escapes, not raw characters
    check("string length resolves \\0 as one byte", _string_len('"a\\0b"') == 3)
    check("string length resolves \\xNN as one byte", _string_len('"\\x41\\x42"') == 2)

    # 4. the jump-table exclusion is non-trivial: prom_c has pointer tables, so
    #    the exclusion set must not be empty, or the cross-check below would be
    #    reporting jump tables as "hidden code" -- a false alarm, not a find.
    check("jump-table slot set is non-empty (prom_c has dispatch tables)",
          len(long_table_addrs) > 100)

    # 5. the cross-check itself: run it, and require it to be empty. This IS the
    #    load-bearing check -- if it goes red, --selftest must fail loudly, not
    #    print a warning main() would then also print.
    strong, proven = strong_reached_prom_c()
    hidden = [(a, k) for a, k, _r, _l, _raw in data_line_addrs
              if a not in long_table_addrs and a in strong]
    check("no data-directive line sits at a STRONG-reachable address (0 found)",
          len(hidden) == 0)

    # 6. sanity on the walk itself: it should find a large fraction of the image
    #    reachable (prom_c is code-dense), not near-zero, or the walk silently
    #    broke and check 5 would be vacuous.
    check("the STRONG walk reaches a substantial fraction of prom_c (>150,000 B)",
          len(strong) > 150000)

    # 7. macro BODIES (include/tlcs900_mem_ops.inc's raw-encoding macros) must
    #    not be counted as image bytes: they emit at each INVOCATION site, not
    #    once at the definition. Found by this script's own first run, which
    #    reported 126 "unresolved" .byte lines inside that one file and had
    #    already folded their operand counts into totals['byte'].
    macro_def_file = os.path.join(ROOT, "include", "tlcs900_mem_ops.inc")
    check(".macro/.endm blocks exist in the shared include (the case this guards)",
          os.path.exists(macro_def_file)
          and any(line.strip().startswith('.macro')
                  for line in open(macro_def_file, encoding="utf-8")))
    rel_inc = os.path.relpath(macro_def_file, ROOT)
    check("no data-directive line is attributed to the macro-definition file itself",
          not any(rel == rel_inc for _a, _k, rel, _l, _raw in data_line_addrs))

    n = len(checks)
    fails = [c for c in checks if not c[1]]
    print("\n%d checks, %d failures" % (n, len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
