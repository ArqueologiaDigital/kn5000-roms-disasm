#!/usr/bin/env python3
r"""seqeng_symbolize_imm.py -- ROM addresses written as numbers -> label names.

QUESTION ANSWERED
-----------------
"Which absolute call/jp operands, 32-bit register loads and address arithmetic in lane seqeng's files
(`ld xix, 16129036`, `add xhl, 14981983`, `lda xiz, (16009476)`) hold a value
that is EXACTLY the address of an existing label of the same image, and what
is the line with that label written in?"  CLAUDE.md's symbolic-cross-reference
policy wants the name; the v7 tree was generated with numeric operands.

HOW
---
Labels come from the image's last build (rebuilt_ROMs/kn5000_<v>_program.llvm.elf,
`t` symbols).  Only values inside the maincpu ROM window 0xE00000-0xFFFFFF and
only 32-bit destination registers (x..) are touched; a non-positional name is
preferred over a `<Parent>_0x<off>` .set alias.  Values with no label at that
exact address are left numeric and counted.  The byte gate certifies (a wrong
name moves bytes); run `make gate` after --apply.

RUN
    python3 scripts/converters/seqeng_symbolize_imm.py v7 [--apply]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import seqeng_reframe as R  # noqa: E402

FILES = ["sequencer/sequencer_engine.s", "sequencer/seq_event_playback.s",
         "sequencer/smf_event_processor.s", "sequencer/smf_tonegen_core.s",
         "sequencer/smf_playback.s"]
CALL = re.compile(r'^(\s*)(call|jp)(\s+)(\d+)(\s*(?:;.*)?)$')
PAT = re.compile(r'^(\s*)(ld|lda|lda_24|add|sub|cp)(\s+)(x\w+)(,\s*)(\(?)(\d+|0x[0-9a-fA-F]+)(:24)?(\)?)(\s*(?:;.*)?)$')


def main():
    image = sys.argv[1]
    apply = "--apply" in sys.argv
    labs = R.rom_labels(image)
    tot = done = 0
    for rel in FILES:
        p = os.path.join(R.ROOT, image, "maincpu", rel)
        lines = open(p, "rb").read().decode("latin-1").split("\n")
        n = 0
        for i, ln in enumerate(lines):
            mc = CALL.match(ln)
            if mc:
                # absolute call/jp to an address that carries a label: these are
                # the sites the branch symboliser refuses wholesale (R1: one bad
                # target in a small block poisons its good ones)
                val = int(mc.group(4))
                if 0xE00000 <= val <= 0xFFFFFF:
                    tot += 1
                    names = labs.get(val, [])
                    if names:
                        pick = [x for x in names if not re.search(r'_0x[0-9A-Fa-f]+$', x)] or names
                        new = "%s%s%s%s%s" % (mc.group(1), mc.group(2), mc.group(3), pick[0], mc.group(5))
                        print("%s:%d  %s  ->  %s" % (rel, i + 1, ln.strip(), new.strip()))
                        lines[i] = new
                        n += 1
                continue
            m = PAT.match(ln)
            if not m:
                continue
            val = int(m.group(7), 0)
            if not (0xE00000 <= val <= 0xFFFFFF):
                continue
            tot += 1
            names = labs.get(val, [])
            if not names:
                continue
            pick = [x for x in names if not re.search(r'_0x[0-9A-Fa-f]+$', x)] or names
            name = pick[0]
            op = m.group(2)
            if op in ("lda", "lda_24"):
                if not m.group(6):
                    continue
                new = "%s%s%s%s%s(%s:24)%s" % (m.group(1), "lda", m.group(3), m.group(4), m.group(5), name, m.group(10))
            else:
                if m.group(6):
                    continue          # memory operand, not an immediate
                new = "%s%s%s%s%s%s%s" % (m.group(1), op, m.group(3), m.group(4), m.group(5), name, m.group(10))
            print("%s:%d  %s  ->  %s" % (rel, i + 1, ln.strip(), new.strip()))
            lines[i] = new
            n += 1
        done += n
        if apply and n:
            open(p, "wb").write("\n".join(lines).encode("latin-1"))
    print("%s: %d ROM-range numeric operands, %d rewritten to labels, %d left (no label at that address)"
          % (image, tot, done, tot - done))


if __name__ == "__main__":
    main()
