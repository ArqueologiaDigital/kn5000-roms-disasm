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
        edits, drop, claimed, file_done = {}, set(), set(), 0

        # ⚠ CLAIM EVERY LINE A LABEL TOUCHES, BOTH LINES, BEFORE COMMITTING IT.
        #
        # Earlier versions checked for conflicts as they went -- "is the split
        # line already dropped?" -- but `drop` keeps GROWING, so a later label
        # could drop a line an earlier label had already split. The guard passed
        # at the moment it ran and was false by the end of the file. Two rounds
        # of ~580 wrong bytes came from this family, and each fix I made was for
        # a real but different collision.
        #
        # A label touches exactly two lines: where its definition is now, and
        # where the split happens. Reserve both up front, and skip the label if
        # either is spoken for. Order stops mattering.
        for (_, n, a, t, ba, st, en) in rows:
            addr = ba
            for i2 in range(st, en + 1):
                _l = LAB.match(lines[i2])
                m = BYTE.match(lines[i2][_l.end():] if _l else lines[i2])
                if not m:
                    continue
                vals = [v.strip() for v in m.group(2).split(',') if v.strip()]
                if not (addr <= t < addr + len(vals)):
                    addr += len(vals)
                    continue
                off = t - addr
                if off == 0 and _l:
                    break                       # a label is already here
                oldj = None
                for j2, ln in enumerate(lines):
                    if ln.strip() == n + ':':
                        oldj = ('whole', j2); break
                    lm = LAB.match(ln)
                    if lm and lm.group(1) == n:
                        oldj = ('shared', j2); break
                if oldj is None or i2 in claimed or oldj[1] in claimed:
                    break
                claimed.add(i2); claimed.add(oldj[1])
                ind = m.group(1)
                head, tail = vals[:off], vals[off:]
                rep = (_l.group(1) + ':\n') if _l else ''
                if head:
                    rep += f"{ind}.byte {', '.join(head)}\n"
                rep += f"{n}:\n"
                rep += f"{ind}.byte {', '.join(tail)}\n"
                edits[i2] = rep
                if oldj[0] == 'whole':
                    drop.add(oldj[1])
                else:
                    rest = lines[oldj[1]][LAB.match(lines[oldj[1]]).end():]
                    edits[oldj[1]] = rest if rest.strip() else ''
                    if not rest.strip():
                        drop.add(oldj[1]); edits.pop(oldj[1], None)
                done += 1; file_done += 1
                break

        out = []
        for i2, ln in enumerate(lines):
            if i2 in drop:
                continue
            out.append(edits.get(i2, ln))

        # PROVE BYTE-NEUTRALITY BEFORE WRITING. The invariant is checkable, so
        # check it rather than reason about which collisions remain.
        def payload(ls):
            # ⚠ THE ELEMENTS ARE NOT ALWAYS ONE LINE. A replacement is a
            # MULTI-LINE string ("head\nLabel:\ntail\n") held in a single list
            # slot, and `BYTE.match` only ever sees its first line -- so an
            # 8-byte split counted as 2 and the check reported 6 bytes lost.
            #
            # This verifier then REFUSED four correct batches in a row while I
            # hunted for the edit bug it was reporting. The invariant was right;
            # its implementation quietly disagreed with its own input format.
            # A checker is code too, and a check that fails is not automatically
            # evidence about the thing being checked.
            # ⚠ CHECK EVERY CONTENT LINE, NOT JUST `.byte`.
            #
            # This compared only the `.byte` payload. It therefore PASSED while
            # the build failed with 630 wrong bytes, because the damage was a
            # dropped INSTRUCTION line (`ld wa, (xsp+16)`) -- invisible to a
            # check that looks at `.byte` and nothing else. A necessary
            # invariant is not a sufficient one, and the gap is exactly the part
            # of the file the check ignores.
            #
            # Now: every line that emits anything, with labels stripped (a label
            # emits no bytes and is the one thing this tool is allowed to move).
            outb = []
            for chunk in ls:
                for ln in chunk.splitlines():
                    _l = LAB.match(ln)
                    body = (ln[_l.end():] if _l else ln).strip()
                    if not body or body.startswith((';', '#')):
                        continue
                    mm = BYTE.match(ln[_l.end():] if _l else ln)
                    if mm:
                        outb += [v.strip() for v in mm.group(2).split(',') if v.strip()]
                    else:
                        outb.append(body)          # instruction / directive text
            return outb
        if payload(out) != payload(lines):
            print(f"  ⚠ REFUSED {os.path.basename(f)}: payload "
                  f"{len(payload(lines))} -> {len(payload(out))}; left untouched")
            done -= file_done
            continue
        open(f, 'wb').write(''.join(out).encode('latin1'))
    print(f"  SPLIT+PLACED {done} label(s)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
