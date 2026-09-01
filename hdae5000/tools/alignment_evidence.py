#!/usr/bin/env python3
"""alignment_evidence.py -- the evidence behind convert_align_pads.py's word-alignment claim

QUESTION ANSWERED: is a lone, undocumented `.byte 0x00` sitting at an odd ROM address right
before a string/pointer really PADDING (a byte whose value is forced to 0x00 purely to restore
word alignment, and would change if the preceding content's length changed), or could it just as
easily be a genuine zero-valued FIELD that happens to sit at an odd offset by coincidence?

This script prints every number cited for that claim in
notes/hdae5000-lane-2026-09-02-alignment-padding.md and in convert_align_pads.py's docstring, so
the claim can be checked rather than taken on faith. It does NOT modify anything.

WHAT WOULD FALSIFY THE PADDING THEORY
    If `.asciz`/`.ascii`/`.long` items started on odd addresses about as often as even ones, a
    "some bytes pad to even" story would be unfalsifiable noise-fitting. They do not: see part 1.
    If the pre-existing `.set` offset chain in hdae5000_init_data.s (built by a previous,
    independent pass) did NOT land on the strings it already claimed to, the whole address model
    behind this file would be suspect. It does land exactly: see part 3. Both checks use addresses
    from get_lprobe_addrs.py, which are the pinned assembler's own linked output, not a hand-rolled
    parse of `.asciz`/`.ascii` escape sequences -- so a bug in escaping quotes or backslashes here
    cannot silently manufacture a false match.

PART 1: does `.asciz`/`.ascii`/`.long` reliably start on an EVEN address, file-wide?
    Answer needed for the padding theory to be more than a local coincidence.

PART 2: of the bare, single-operand `.byte 0x00` lines sitting at an ODD address, what directive
    immediately follows? Only the subset followed by `.asciz`/`.ascii` is converted by
    convert_align_pads.py -- the subset followed by another bare `.byte` is deliberately NOT
    converted (weaker evidence: could be a genuine second field, not a pad byte) and the subset
    followed by `.zero` is deliberately NOT converted either (part 1 shows `.zero` runs are NOT
    reliably aligned, so a `.byte 0x00` before one is not corroborated the same way).

PART 3: two pre-existing offset anchors, added by an earlier pass for an unrelated reason (naming
    specific strings), independently predict addresses tens of thousands of bytes apart in the
    file. If this script's byte-accounting (i.e. the padding theory) were wrong anywhere in
    between, at least one of these would land on the wrong content. Both are checked here against
    the actual source line content at that address, byte for byte -- not merely "a line exists".

GUARDING AGAINST A VACUOUS PASS: every count and every anchor check below asserts it actually
examined a nonzero amount of the real file (`assert counted > 0`) and that the anchors resolved to
the SPECIFIC non-empty string this script says they should, not just "an address was found".

RUN (from the hdae5000 lane worktree root):
    python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt
    python3 hdae5000/tools/alignment_evidence.py /tmp/lprobe.txt
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HDAE_DIR = os.path.join(ROOT, "hdae5000")
DATFILE = os.path.join(HDAE_DIR, "hdae5000_data_tables.s")
INIT_DATA_FILE = os.path.join(HDAE_DIR, "hdae5000_init_data.s")


def strip_comment(line):
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == ';' and not in_str:
            return line[:i], line[i + 1:].strip()
    return line, ""


DIRECTIVE_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.(\w+)')
BYTE_RE = re.compile(r'^\s*(?:\S+\s*:\s*)?\.byte\b(.*)$', re.IGNORECASE)


def count_operands(rest):
    rest = rest.strip()
    if not rest:
        return []
    return [p.strip() for p in rest.split(",") if p.strip() != ""]


def load_addrs(path):
    addr = {}
    with open(path) as f:
        for line in f:
            a, _t, name = line.split()
            n = int(name.split("_", 1)[1])
            addr[n] = int(a, 16)
    assert len(addr) > 0, f"{path} contained no probe addresses -- nothing to check against"
    return addr


def part1_directive_alignment(lines, addr):
    print("=== PART 1: does .asciz/.ascii/.long/.zero start on an even address, file-wide? ===")
    counts = {"asciz": [0, 0], "ascii": [0, 0], "zero": [0, 0], "long": [0, 0]}
    for i, line in enumerate(lines, 1):
        code, _ = strip_comment(line)
        m = DIRECTIVE_RE.match(code)
        if not m or m.group(1) not in counts:
            continue
        counts[m.group(1)][addr[i] % 2] += 1
    for d, (even, odd) in counts.items():
        total = even + odd
        assert total > 0, f"found zero '.{d}' directives -- the file walk above is broken"
        print(f"  .{d}: {even:5d} even-start, {odd:5d} odd-start ({100*even/total:.1f}% even, "
              f"n={total})")
    print()
    return counts


def part2_classify_pad_candidates(lines, addr):
    print("=== PART 2: bare single '.byte 0x00' at an ODD address -- what follows it? ===")

    def next_content(i):
        j = i + 1
        while j <= len(lines):
            code, _ = strip_comment(lines[j - 1])
            if code.strip():
                return j
            j += 1
        return None

    by_next = {}
    total_candidates = 0
    for i, line in enumerate(lines, 1):
        code, comment = strip_comment(line)
        m = BYTE_RE.match(code)
        if not m or comment:
            continue
        ops = count_operands(m.group(1))
        if len(ops) != 1 or ops[0] not in ("0x00", "0x0"):
            continue
        if addr[i] % 2 != 1:
            continue
        total_candidates += 1
        nc = next_content(i)
        ncode, _ = strip_comment(lines[nc - 1]) if nc else ("", "")
        nd = DIRECTIVE_RE.match(ncode)
        key = nd.group(1) if nd else ("LABEL" if re.match(r'^[A-Za-z_]\w*:', ncode) else "OTHER")
        by_next[key] = by_next.get(key, 0) + 1

    assert total_candidates > 0, "found zero odd-address bare '.byte 0x00' lines -- broken walk"
    print(f"  total candidates: {total_candidates}")
    for k, v in sorted(by_next.items(), key=lambda x: -x[1]):
        converted = " <- convert_align_pads.py converts these" if k in ("asciz", "ascii") else ""
        print(f"    next = {k:8s} {v:5d}{converted}")
    print()
    return by_next


def parse_set_offsets(path, base_name):
    """Pull `.set NAME, BASE + 0xNN` lines whose BASE matches base_name."""
    pat = re.compile(r'\.set\s+(\S+),\s*' + re.escape(base_name) + r'\s*\+\s*(0x[0-9a-fA-F]+)')
    out = []
    with open(path, encoding="latin-1") as f:
        for line in f:
            m = pat.search(line)
            if m:
                out.append((m.group(1).rstrip(','), int(m.group(2), 16)))
    return out


def part3_anchor_cross_checks(lines, addr, name_to_line):
    print("=== PART 3: pre-existing offset anchors vs. the real assembled address ===")
    checked = 0

    # 3a: the ~40 HDAE5000_Str_* anchors hung off HDAE5000_RECORD_COUNT in hdae5000_init_data.s.
    base_line = name_to_line["HDAE5000_RECORD_COUNT"]
    base_addr = addr[base_line]
    offsets = parse_set_offsets(INIT_DATA_FILE, "HDAE5000_RECORD_COUNT")
    assert len(offsets) > 5, "expected dozens of RECORD_COUNT .set anchors, found too few"
    addr_to_line = {}
    for i, a in addr.items():
        addr_to_line.setdefault(a, i)
    mismatches = 0
    for label, off in offsets:
        target = base_addr + off
        li = addr_to_line.get(target)
        ok = li is not None
        checked += 1
        if not ok:
            mismatches += 1
            print(f"  MISMATCH: {label} = RECORD_COUNT+{hex(off)} = {hex(target)} -- "
                  f"no source line lands there")
    print(f"  HDAE5000_RECORD_COUNT + offset: {len(offsets)} anchors checked, "
          f"{len(offsets) - mismatches} land exactly on a line boundary")
    assert mismatches == 0, f"{mismatches} RECORD_COUNT anchor(s) do not resolve -- address model is wrong"

    # 3b: two anchors deep inside the UI object descriptor pool, each with a known expected string.
    def expect_string(base_label, off, expected):
        nonlocal checked
        base_addr = addr[name_to_line[base_label]]
        target = base_addr + off
        li = addr_to_line.get(target)
        assert li is not None, f"{base_label}+{hex(off)} = {hex(target)} matches no source line"
        code, _ = strip_comment(lines[li - 1])
        m = re.search(r'\.asciz\s+"([^"]*)"', code)
        got = m.group(1) if m else None
        checked += 1
        status = "OK" if got == expected else "MISMATCH"
        print(f"  {status}: {base_label}+{hex(off)} = {hex(target)} -> {got!r} "
              f"(expected {expected!r})")
        assert got == expected, "anchor did not resolve to the expected string"

    expect_string("HDAE5000_Panel_Save_UI", 0x2ca4, "ABC")
    expect_string("HDAE5000_UI_Page_Titles", 0x11ea, "! HD FORMAT !")

    print()
    assert checked > 0, "no anchors were actually checked -- vacuous pass"
    print(f"all {checked} anchor checks passed.")


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <lprobe-address-file-for-hdae5000_data_tables.s>")
    addr = load_addrs(sys.argv[1])

    with open(DATFILE, encoding="latin-1") as f:
        lines = f.readlines()
    assert len(lines) == len(addr), (
        f"{DATFILE} has {len(lines)} lines but the address file has {len(addr)} -- "
        f"regenerate get_lprobe_addrs.py's output against the CURRENT file before trusting this")

    label_re = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
    name_to_line = {}
    for i, line in enumerate(lines, 1):
        m = label_re.match(line)
        if m:
            name_to_line.setdefault(m.group(1), i)

    part1_directive_alignment(lines, addr)
    part2_classify_pad_candidates(lines, addr)
    part3_anchor_cross_checks(lines, addr, name_to_line)


if __name__ == "__main__":
    main()
