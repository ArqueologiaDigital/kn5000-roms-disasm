#!/usr/bin/env python3
"""update_disasm_test_expectations.py -- when a decoder change alters what an
llvm-project TLCS900 lit test expects the DISASSEMBLER to print, rewrite those
expectations -- but only to a text MAME's unidasm agrees with.

QUESTION IT ANSWERS
    "Which disassembly expectations in this test file does the current decoder
    no longer print, what does it print instead, and does MAME's independent
    decoder agree with the new text?"  A lit test whose expectations are
    regenerated from the decoder under test proves nothing by itself; the
    second decoder is what makes the new expectation evidence.

WHAT IT TOUCHES
    * `.txt` disassembler tests: a `# CHECK: <text>` line followed (after any
      comments) by a hex byte line.  The text part is replaced, any
      `{{.*}}encoding: [...]` tail is kept.
    * `.s` tests whose objdump/re-decode prefixes (CHECK-INST, DISASM, INST)
      follow a `CHECK-ENC: encoding: [...]` or `CHECK: ... ; encoding: [...]`
      line of the same case; the bytes are taken from that encoding.
    A line is rewritten only if (a) its text differs from the new decode and
    (b) two_decoder_sweep.classify(new, unidasm) == AGREE.  Anything else is
    listed and left alone for a human.

RUN (from anywhere)
    python3 update_disasm_test_expectations.py <test file>...          # report
    python3 update_disasm_test_expectations.py --apply <test file>...  # write
    MC=/path/llvm-mc OBJDUMP=/path/llvm-objdump to pick the build.

The two decoders' readings of every rewritten line are printed; keep that
output with the commit that uses it.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import two_decoder_sweep as T  # noqa: E402

HEX_LINE = re.compile(r'^\s*((?:0x[0-9a-fA-F]{2}\s*)+)(?:#.*)?$')
ENC = re.compile(r'encoding: \[([^\]]*)\]')
TXT_CHECK = re.compile(r'^(#\s*CHECK:\s*)([^{]*?)(\s*\{\{\.\*\}\}encoding:.*)?$')
S_CHECK = re.compile(r'^(;\s*(?:CHECK-INST|DISASM|INST):\s*)(.*?)\s*$')


def norm(t):
    return re.sub(r'\s+', ' ', t.strip())


def cases_txt(L):
    """-> list of (check_line_index, bytes)."""
    out, pending = [], []
    for i, l in enumerate(L):
        if TXT_CHECK.match(l):
            pending.append(i)
            continue
        m = HEX_LINE.match(l)
        if m:
            b = bytes(int(x, 16) for x in m.group(1).split())
            for j in pending:
                out.append((j, b))
            pending = []
        elif l.strip() and not l.lstrip().startswith('#'):
            pending = []
    return out


def cases_s(L):
    out, enc, pend = [], None, []
    for i, l in enumerate(L):
        m = ENC.search(l)
        if m and l.lstrip().startswith(';'):
            try:
                enc = bytes(int(x, 16) for x in m.group(1).split(','))
            except ValueError:
                enc = None
        if S_CHECK.match(l):
            pend.append(i)
            continue
        if l.strip() and not l.lstrip().startswith(';'):
            if enc is not None:
                for j in pend:
                    out.append((j, enc))
            pend, enc = [], None
    return out


def main():
    apply = "--apply" in sys.argv
    files = [a for a in sys.argv[1:] if not a.startswith("--")]
    print("toolchain:", T.toolchain())
    for p in files:
        L = open(p, encoding="utf-8").read().split("\n")
        cs = cases_txt(L) if p.endswith(".txt") else cases_s(L)
        if not cs:
            print("%s: no cases" % p)
            continue
        ld = T.llvm_decode([b for _, b in cs])
        md = T.mame_decode([b for _, b in cs])
        changed = refused = 0
        for (i, b), l, m in zip(cs, ld, md):
            rx = TXT_CHECK if p.endswith(".txt") else S_CHECK
            mm = rx.match(L[i])
            old = norm(mm.group(2))
            if not l or l[1].startswith("<unknown>"):
                continue
            new = norm(l[1])
            if old == new:
                continue
            v = T.classify(l[0], l[1], m[0] if m else None, m[1] if m else None)
            tag = "OK " if v == "AGREE" else "REFUSED(%s)" % v
            print("%s:%d %s %-18s old: %-30s new: %-30s mame: %s" % (
                os.path.basename(p), i + 1, tag, b.hex(" "), old, new,
                m[1] if m else "-"))
            if v != "AGREE":
                refused += 1
                continue
            tail = (mm.group(3) or "") if p.endswith(".txt") else ""
            L[i] = mm.group(1) + new + tail
            changed += 1
        print("%s: %d rewritten, %d left for review" % (p, changed, refused))
        if apply and changed:
            open(p, "w", encoding="utf-8").write("\n".join(L))


if __name__ == "__main__":
    main()
