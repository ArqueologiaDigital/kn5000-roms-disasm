#!/usr/bin/env python3
"""Place a displaced label by SPLITTING the `.byte` run its routine starts in.

QUESTION ANSWERED
-----------------
After repairing the 691 labels whose routine started on an existing source line,
2,774 remain displaced by 0x41A and I recorded them as "blocked behind
conversion" -- their targets sit inside undisassembled `.byte` runs, with no
line to carry a label.

⚠ THAT WAS WRONG, and the correction is the point of this script. A `.byte`
directive is a LIST. Breaking it in two at an offset emits exactly the same
bytes -- `.byte 1,2,3,4` and `.byte 1,2` + `.byte 3,4` are identical output. So
the line the label needs can simply be CREATED. No disassembly is required, and
2,418 of the 2,774 qualify.

The deadlock I thought I had -- conversion blocked by displaced labels, labels
blocked waiting for conversion -- was an artefact of assuming a line boundary
had to be earned by converting the run rather than by splitting it.

HOW A SPLIT IS PERFORMED
    find the `.byte` line holding the target address, count bytes along it to
    the exact offset, and emit:
        .byte <bytes before the target>
        <Label>:
        .byte <bytes from the target on>
    A split at offset 0 needs no new directive, just the label above the line.

⚠ VERIFICATION, because the byte gate cannot review a label move (spec
anti-patterns 12 and 13): `make clean-all && make all` must stay 9/9 -- which
here checks the SPLIT, since a mis-split would change the byte stream and fail
loudly -- and `scripts/analysis/v7_label_displacement.py` must fall by the
number of labels placed, which is the only check that sees whether the label
landed on its routine.

Run:  python3 scripts/repair/v7_split_byte_run_for_label.py [--files N] [--apply N]
      then rebuild, `l2_symbol_reference.py --regen`, and re-measure.
"""
import bisect, glob, importlib.util, os, re, sys

BASE, DISP = 0xE00000, 0x41A
LO, HI = 0x00FCCE4A, 0x00FFFE80
W = int(sys.argv[sys.argv.index('--window') + 1]) if '--window' in sys.argv else 24
LAB = re.compile(r'^([A-Za-z_][\w]*):')
BYTE = re.compile(r'^(\s*)\.byte\s+(.*)$')


def syms(p):
    d = {}
    for line in open(os.path.join('symbols', p), encoding='latin1'):
        if line.startswith('#') or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            try:
                d[f[0]] = int(f[1], 16)
            except ValueError:
                pass
    return d


def main():
    s7, s9 = syms('maincpu_v7_symbols_reference.txt'), syms('maincpu_v9_symbols_reference.txt')
    rom7 = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    rom9 = open('original_ROMs/kn5000_v9_program.rom', 'rb').read()
    displaced = {}
    for n in set(s7) & set(s9):
        a7, a9 = s7[n], s9[n]
        if not (LO <= a7 <= HI):
            continue
        o7, o9 = a7 - BASE, a9 - BASE
        if not (0 <= o9 < len(rom9) - W and DISP <= o7 < len(rom7) - W):
            continue
        ref = rom9[o9:o9 + W]
        at = sum(1 for x, y in zip(rom7[o7:o7 + W], ref) if x == y)
        tr = sum(1 for x, y in zip(rom7[o7 - DISP:o7 - DISP + W], ref) if x == y)
        if at <= 0.34 * W and tr >= 0.87 * W:
            displaced[n] = a7

    spec = importlib.util.spec_from_file_location('cr', 'scripts/converters/convert_reachable_ranges.py')
    cr = importlib.util.module_from_spec(spec)
    saved, sys.argv2 = sys.argv, None
    _a = sys.argv; sys.argv = ['cr']
    spec.loader.exec_module(cr); sys.argv = _a
    idx = cr.source_index(cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
    owned = set(cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

    # target address -> (file, run) it lands inside
    plan = []
    for n, a in displaced.items():
        t = a - DISP
        if t in owned:
            continue
        for f, (lines, blocks) in idx.items():
            for (bl, ba, st, en, raw) in blocks:
                if ba is None or not (ba <= t < ba + len(raw)):
                    continue
                plan.append((f, n, a, t, ba, st, en))
                break
            else:
                continue
            break

    print(f"  displaced labels                  : {len(displaced):,}")
    print(f"  with a target inside a `.byte` run: {len(plan):,}")
    if '--apply' not in sys.argv:
        for f, n, a, t, ba, st, en in plan[:8]:
            print(f"    {n:42} {a:#08x} -> {t:#08x}  run@{ba:#08x}  {os.path.basename(f)}")
        return 0

    k = int(sys.argv[sys.argv.index('--apply') + 1])
    byfile = {}
    for row in plan[:k]:
        byfile.setdefault(row[0], []).append(row)
    done = 0
    for f, rows in byfile.items():
        lines = open(f, 'rb').read().decode('latin1').splitlines(True)
        edits = {}                      # line index -> replacement text
        drop = set()
        for (_, n, a, t, ba, st, en) in rows:
            # walk the run's .byte lines to find the one holding t
            addr = ba
            for i in range(st, en + 1):
                m = BYTE.match(lines[i])
                if not m:
                    continue
                vals = [v.strip() for v in m.group(2).split(',') if v.strip()]
                if addr <= t < addr + len(vals):
                    off = t - addr
                    ind = m.group(1)
                    if i in edits:
                        break               # one split per line, keep it simple
                    if i == st and off == 0:
                        break               # label would duplicate the run's own
                    head = vals[:off]
                    tail = vals[off:]
                    new = ''
                    if head:
                        new += f"{ind}.byte {', '.join(head)}\n"
                    new += f"{n}:\n"
                    new += f"{ind}.byte {', '.join(tail)}\n"
                    # ⚠ THE OLD DEFINITION MUST GO, AND IT IS NOT ALWAYS ALONE.
                    # The first version searched for a line equal to `Name:` and
                    # dropped it. A label sharing its line with a directive --
                    # `Name:\t.byte ...` -- does not match, so nothing was
                    # removed and the label ended up defined TWICE. The gate
                    # caught it at once ("symbol 'X' is already defined", 0/9),
                    # which is the one advantage a split has over a plain label
                    # move: it touches the byte stream, so the strongest check in
                    # the project can actually see it.
                    oldline = None
                    for j, ln in enumerate(lines):
                        if ln.strip() == n + ':':
                            oldline = ('whole', j); break
                        lm = LAB.match(ln)
                        if lm and lm.group(1) == n:
                            oldline = ('shared', j); break
                    if oldline is None:
                        break                      # cannot find it: leave alone
                    # ⚠ THE OLD DEFINITION AND THE SPLIT MAY BE THE SAME LINE, or
                    # a line another label in this batch already claimed. Writing
                    # both edits then loses one of them and the BYTE STREAM
                    # changes: a 1,951-label run produced 578 wrong bytes in v7
                    # (gate 8/9) while an 18-label run was clean, because the
                    # collision is rare. Refuse the label instead -- a skipped
                    # repair costs nothing, a corrupted run costs the tree.
                    if (oldline[1] == i or oldline[1] in edits or oldline[1] in drop
                            or i in drop):
                        break
                    if oldline[0] == 'whole':
                        drop.add(oldline[1])
                    else:
                        # strip just the label off the front, keep the directive
                        j = oldline[1]
                        rest = lines[j][LAB.match(lines[j]).end():]
                        if not rest.strip():
                            drop.add(j)
                        else:
                            edits[j] = ('\t' + rest.lstrip()) if not rest.startswith((' ', '\t')) else rest
                    if i in edits:
                        break
                    edits[i] = new
                    done += 1
                    break
                addr += len(vals)
        if not edits:
            continue
        out = []
        for i, ln in enumerate(lines):
            if i in drop:
                continue
            out.append(edits.get(i, ln))
        open(f, 'wb').write(''.join(out).encode('latin1'))
    print(f"  SPLIT+PLACED {done} label(s)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
