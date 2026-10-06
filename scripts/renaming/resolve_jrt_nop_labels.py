#!/usr/bin/env python3
"""resolve_jrt_nop_labels.py -- the `__jrt_nop_XXXXXX` labels of the sub-CPU payload and boot and table data are resolved.

QUESTION IT ANSWERS
  The conversion from ASL left a positional label after every compiled `jr` whose target is the very next
  instruction:
      jr  __jrt_nop_01FACB
  __jrt_nop_01FACB:
  The CLAUDE.md canonical-label rule names `__jrt_nop_XXXXXX` as an alias to remove.  In v142 (the payload and
  subcpu_fp_math.s), the sub-CPU boot ROM and table data, each such label is referenced once, by the `jr` on the
  line before it.  It is one of two things:
    - ALIAS: the next code line is another label (e.g. Audio_System_Init).  The compiler jumps into the next routine.
      The `jr` now names that label and the alias line goes.  A comment that says "(alias symbol __jrt_nop_X is the
      same address)" goes with it.
    - JOIN: the next code line is an instruction.  The label is renamed <Parent>_Next[N], where Parent is the enclosing
      routine, as a local branch label.  When the target starts with `nop / nop / nop`, a comment on the `jr` calls
      the `jr` and the nops the settling gap after the register write, the file's own term
      (ToneGen_WriteNote2ch_NopCont2).  In v142 each one follows a ToneGen_RegDataPort write.
  Labels move no bytes; the byte gate is the proof.

RUN (repository root)
  python3 scripts/renaming/resolve_jrt_nop_labels.py [--apply]
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["v142/subcpu/kn5000_subprogram_v142.s", "v142/subcpu/subcpu_fp_math.s", "table_data/kn5000_table_data.s",
         "subcpu/boot/kn5000_subcpu_boot.s"]
JRT = re.compile(r'__jrt_nop_[0-9A-F]{6}')
LAB = re.compile(r'^([A-Za-z_.$][\w.$]*):\s*(;.*)?$')
DEF = re.compile(r'^([A-Za-z_][\w$]*):')
LOC = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
ALIAS_NOTE = re.compile(r'\s*\((?:The a|A)lias symbol __jrt_nop_[0-9A-F]{6} (?:refers to|is) the same address\.\)')
DELAY = "\t; `jr` to the next instruction + three `nop`s: the settling gap after the register write"


def main():
    apply = "--apply" in sys.argv
    texts = {f: open(os.path.join(ROOT, f), "rb").read().decode("latin-1").split("\n") for f in FILES}
    taken = {m.group(1) for L in texts.values() for x in L for m in [DEF.match(x)] if m}
    for f, L in texts.items():
        n_alias = n_join = 0
        ren = {}
        drop = set()
        delay_at = set()
        for i, x in enumerate(L):
            m = re.match(r'^(__jrt_nop_[0-9A-F]{6}):\s*$', x)
            if not m:
                continue
            name = m.group(1)
            assert re.match(r'^\s*jr\s+%s\s*(;.*)?$' % name, L[i - 1]), (f, i, L[i - 1])
            uses = sum(len(JRT.findall(y.split(";")[0])) for y in L if name in y)
            assert uses == 2, (f, name, uses)            # the jr and the definition
            j = i + 1
            while j < len(L) and (not L[j].strip() or L[j].lstrip().startswith(";")):
                j += 1
            nxt = LAB.match(L[j])
            if nxt and not JRT.match(nxt.group(1)):
                ren[name] = nxt.group(1)
                drop.add(i)
                n_alias += 1
            else:
                k = i - 1
                while not (DEF.match(L[k]) and not LOC.search(DEF.match(L[k]).group(1))
                           and not JRT.match(DEF.match(L[k]).group(1))):
                    k -= 1
                parent = DEF.match(L[k]).group(1)
                new, c = parent + "_Next", 2
                while new in taken:
                    new, c = "%s_Next%d" % (parent, c), c + 1
                taken.add(new)
                ren[name] = new
                n_join += 1
                if [y.strip() for y in L[j:j + 3]] == ["nop", "nop", "nop"]:
                    delay_at.add(i - 1)
        out = []
        for i, x in enumerate(L):
            if i in drop:
                continue
            if ALIAS_NOTE.search(x) and ALIAS_NOTE.sub("", x).strip() == ";":
                continue                                  # the note was the whole comment line
            x = ALIAS_NOTE.sub("", x)
            x = JRT.sub(lambda m: ren.get(m.group(0), m.group(0)), x)
            if i in delay_at and ";" not in x:
                x += DELAY
            out.append(x)
        left = sum(1 for x in out if JRT.search(x))
        print("%s: %d aliases resolved to the next label, %d joins renamed <Parent>_Next (%d with the delay note); "
              "%d __jrt_nop mentions left" % (f, n_alias, n_join, len(delay_at), left))
        if apply:
            data = "\n".join(out).encode("latin-1")
            p = os.path.join(ROOT, f)
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
