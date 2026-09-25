#!/usr/bin/env python3
r"""wave3a_byte_autoinc.py -- `.byte` lines that were one post-increment /
pre-decrement instruction, written as bytes only because the assembler had
no `(R+)` / `(-R)` syntax: respell them as the instruction.

QUESTION / JOB
--------------
Before TOOLCHAIN_VERSION UPDATE 17 the only spellings of the C4/C5/D4/D5/E4/
E5/F4/F5 addressing modes were pseudo mnemonics (two of them naming the wrong
instruction), so lanes that lifted code sometimes left such an instruction as
`.byte 0xf5, 0xe0, 0x31  ; lda xbc,xwa+`.  Which of those lines are really one
instruction, and what is its real spelling?

A `.byte` line is converted only if ALL of these hold -- a data table that
happens to start with 0xf5 must never become code:
  * its first byte is one of the eight prefixes and the whole line is ONE
    instruction to BOTH decoders: llvm-objdump and MAME's unidasm consume
    exactly the line's byte count;
  * the two decoders AGREE on operation and registers
    (notes/wave3a-toolchain-probes/two_decoder_sweep.py classify);
  * there is independent evidence the line is code: its own comment already
    names the instruction MAME reads (a previous lane decoded it by hand).
    ⚠ Instruction-looking NEIGHBOURS are NOT evidence: v10/v9/v7
    note_voice_mapping.s has `.byte 0xd3 / reti / .byte 0xe4, 0xe0, 0xc2`,
    the tail of a misframed 5-byte register-indexed instruction whose middle
    bytes decode as `reti` -- both neighbours "instructions", the line not an
    instruction boundary at all.  The first version of this tool accepted it.
  * llvm-mc re-encodes the new text to the line's own bytes.
Everything else is listed with the reason and left alone.  Then gate-all.

RUN (tree root)
    python3 scripts/converters/wave3a_byte_autoinc.py            # report
    python3 scripts/converters/wave3a_byte_autoinc.py --apply

    # --cannot-encode: instead of the post-increment prefixes, every `.byte`
    # line whose comment carries the SX-WSA1R lanes' tag "[llvm-mc cannot
    # encode this]" (any prefix) -- the same four tests; the tag is dropped
    # from a converted line.
    python3 scripts/converters/wave3a_byte_autoinc.py --cannot-encode [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "notes", "wave3a-toolchain-probes"))
import two_decoder_sweep as T  # noqa: E402

PREFIXES = {0xc4, 0xc5, 0xd4, 0xd5, 0xe4, 0xe5, 0xf4, 0xf5}
BYTE = re.compile(r'^([ \t]*(?:[A-Za-z_.$][\w.$@]*:[ \t]*)?)\.byte[ \t]+([^;]*?)[ \t]*(;.*)?$')


TAG = "[llvm-mc cannot encode this]"
CANNOT = "--cannot-encode" in sys.argv


def main():
    apply = "--apply" in sys.argv
    files = subprocess.run(["git", "ls-files", "*.s", "*.inc"], cwd=ROOT,
                           capture_output=True, text=True).stdout.split()
    cands = []
    for f in files:
        if f.startswith("archive/"):
            continue
        L = open(os.path.join(ROOT, f), encoding="latin-1").read().split("\n")
        for i, l in enumerate(L):
            m = BYTE.match(l)
            if not m:
                continue
            try:
                bs = bytes(int(x.strip(), 0) & 0xFF for x in m.group(2).split(",") if x.strip())
            except ValueError:
                continue
            if CANNOT:
                if TAG in (m.group(3) or "") and 1 <= len(bs) <= 8:
                    cands.append((f, i, L, m, bs))
            elif 3 <= len(bs) <= 7 and bs[0] in PREFIXES:
                cands.append((f, i, L, m, bs))
    ld = T.llvm_decode([c[4] for c in cands])
    md = T.mame_decode([c[4] for c in cands])
    texts = [x[1] if x else "nop" for x in ld]
    enc = T.llvm_encode(texts)
    edits = {}
    # direct addresses print in decimal; the tree writes them in hex
    hexify = lambda t: re.sub(r'\((\d+):(8|16|24)\)',
                              lambda mm: "(0x%x:%s)" % (int(mm.group(1)), mm.group(2)), t)
    enc2 = T.llvm_encode([hexify(t) for t in texts])
    print("toolchain:", T.toolchain())
    for (f, i, L, m, bs), l, u, e, e2 in zip(cands, ld, md, enc, enc2):
        why = None
        if not l or l[1].startswith("<unknown>"):
            why = "llvm refuses"
        elif not u or u[1].split()[0].lower() == "db":
            why = "unidasm: db"
        elif l[0] != len(bs) or u[0] != len(bs):
            why = "not one instruction (llvm %s, unidasm %s bytes)" % (l[0], u[0])
        elif T.classify(l[0], l[1], u[0], u[1]) != "AGREE":
            why = "decoders disagree (%s)" % T.classify(l[0], l[1], u[0], u[1])
        elif e != bs or e2 != bs:
            why = "llvm text does not re-encode"
        else:
            com = (m.group(3) or "").lower()
            mn = u[1].split()[0].lower()
            named = re.search(r'\b%s\b' % re.escape(mn), com) is not None
            if not named:
                why = "no evidence it is code (its comment does not name the instruction)"
        tag = "CONVERT" if not why else "keep"
        print("%-7s %s:%d  %-22s llvm: %-28s mame: %-24s %s" % (
            tag, f, i + 1, bs.hex(" "), l[1] if l else "-", u[1] if u else "-", why or ""))
        if not why:
            com = (m.group(3) or "").replace("   " + TAG, "").replace(" " + TAG, "").replace(TAG, "").rstrip()
            # a comment that only restates the instruction goes (Comment
            # Quality policy); one that says more (wsa1's address/bytes
            # columns, prose) stays
            squash = lambda t: re.sub(r'[\s()]', '', t.lower())
            if squash(com.lstrip(";")) == squash(u[1]):
                com = ""
            new = m.group(1) + hexify(l[1]).replace(" ", "\t", 1) + ("\t" + com if com else "")
            edits.setdefault(f, []).append((i, new))
    n = sum(len(v) for v in edits.values())
    print("convert %d lines in %d files" % (n, len(edits)))
    if apply:
        for f, ed in edits.items():
            p = os.path.join(ROOT, f)
            raw = open(p, "rb").read().decode("latin-1").split("\n")
            for i, new in ed:
                raw[i] = new
            open(p, "wb").write("\n".join(raw).encode("latin-1"))
            print("  M", f)


if __name__ == "__main__":
    main()
