#!/usr/bin/env python3
"""Name the prom_a targets of prom_b's 32 ButtonTable_<Screen> panel-button tables.

QUESTION IT ANSWERS
  prom_b holds 32 button tables (0xF7D2D8 + 0x80*i, 32 LE32 slots each, indexed by the panel
  button CODE; notes/wave7_panel_names_round11.py).  Rounds 11/12 named every handler in prom_b's
  own span 0xF7E2D8-0xF80000 (notes/prom_b_panel_names_round12.py).  Eleven of the tables -- the
  later sequencer edit screens -- point into PROM_A instead (0xF80000-0xF81xxx), where no label
  stood at any target, so their 362 slots stayed `.long 0x00F8xxxx` in prom_b.  This script
  applies the SAME rules to those targets, so the two halves read as one family:

    * first byte a bare `ret`                -> ButtonTable_<Screen>_Nop<slot>   (prom_b's spelling)
    * base slot in round 11's CONTROL map    -> <Control>_<Screen>               (round 12's spelling:
      SoftKeyCol1-8, LcdKeyRow1-5, ExitKey, PageKey, NumberPadKey)
    * base slot refused by round 11 (0x0D, 0x0E, 0x19) or reachable only as a variant-1
      already-held alias (0x11-0x18)        -> <Screen>_Button<slot>, header "NOT NAMED" + the gap
      (prom_b's MeasureDelete_StageZero_Button21 is the precedent)

  <Screen> is the FIRST table (in table order) whose slot holds the target, and <slot> the lowest
  such slot -- round 11's base_slot() rule; every other (table, slot) is listed in the header.
  The slot -> control map, the refusals and the variant-2 reachability argument are round 11's,
  imported, not restated.  A target that is not an instruction line start in prom_a, or that
  already has a label, is reported and left.

  After --apply: `make wsa1` and scripts/converters/symbolize_wsa1_rom_addresses.py --apply
  --verify rewrite the prom_b `.long`s; then `make gate-all`.

RUN
  python3 notes/prom_a_button_handler_names.py            # the plan
  python3 notes/prom_a_button_handler_names.py --apply    # write prom_a/wsa1_prom_a.s
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import wave7_panel_names_round11 as R11  # noqa: E402

PROM_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
A_LO, A_HI = 0xF80000, 0x1000000
SPELL = {"Exit": "ExitKey", "NumberPad": "NumberPadKey", "Page": "PageKey"}


def census():
    """{prom_a target: [(table index, slot), ...]} in table order, then slot order."""
    out = collections.OrderedDict()
    for t_i, t in enumerate(R11.tables()):
        for slot in range(32):
            v = R11.le32b(t + 4 * slot)
            if A_LO <= v < A_HI:
                out.setdefault(v, []).append((t_i, slot))
    return out


def plan():
    labs, _ = R11.screen_names()
    rows = []
    for v, uses in sorted(census().items()):
        t_i, _ = uses[0]
        screen = labs[t_i][len("ButtonTable_"):]
        slots = sorted({s for t, s in uses if t == t_i})
        others = [(labs[t][len("ButtonTable_"):], s) for t, s in uses if t != t_i]
        where = "ButtonTable_%s slot%s %s" % (screen, "s" if len(slots) > 1 else "",
                                              ", ".join("0x%02X" % s for s in slots))
        if others:
            where += "; also " + ", ".join("%s 0x%02X" % o for o in others)
        if R11.A(v)[0] == R11.RET:
            rows.append((v, "ButtonTable_%s_Nop%d" % (screen, min(slots)),
                         ["%s: a bare ret -- %s." % ("ButtonTable_%s_Nop%d" % (screen, min(slots)), where)]))
            continue
        bs = R11.base_slot(slots)
        if bs in R11.CONTROL and bs not in R11.REFUSE_SLOT:
            ctl, gloss = R11.CONTROL[bs]
            name = "%s_%s" % (SPELL.get(ctl, ctl), screen)
            rows.append((v, name, ["%s: %s; %s." % (name, gloss, where),
                                   "  The slot -> control map is notes/wave7_panel_names_round11.py's CONTROL (variant 2)."]))
            continue
        name = "%s_Button%d" % (screen, bs)
        if bs in R11.REFUSE_SLOT:
            gap = R11.REFUSE_SLOT[bs]
        else:
            al = R11.held_alias(bs)
            gap = ("slot 0x%02X is only the VARIANT-1 already-held rewrite of base code 0x%02X; the "
                   "SX-WSA1R is variant 2, so the slot is never delivered here" % (bs, al if al is not None else 0))
        rows.append((v, name, ["%s -- %s, NOT NAMED: %s." % (name, where, gap)]))
    return rows


def apply_(rows):
    data = open(PROM_A, "rb").read().decode("latin-1")
    L = data.split("\n")
    at = {}
    for i, l in enumerate(L):
        m = re.search(r';\s*([0-9A-F]{6})\b', l)
        code = l.split(";", 1)[0].strip()
        if m and code and not re.match(r'^[A-Za-z_.][\w$.]*:$', code):
            at.setdefault(int(m.group(1), 16), i)
    ins, skipped = [], []
    for v, name, hdr in rows:
        if re.search(r'\b%s\b' % re.escape(name), data):
            skipped.append((v, name, "name already used"))
            continue
        i = at.get(v)
        if i is None:
            skipped.append((v, name, "not a prom_a line start"))
            continue
        j = i
        while j > 0 and re.match(r'^\.L[\w$]*:\s*$', L[j - 1]):
            j -= 1
        if re.match(r'^[A-Za-z_][\w$]*:', L[j - 1]):
            skipped.append((v, name, "already labelled " + L[j - 1].split(":")[0]))
            continue
        block = []
        for h in hdr:
            block += ["; " + x for x in _wrap(h)]
        ins.append((j, block + [name + ":"]))
    for j, block in sorted(ins, reverse=True):
        L[j:j] = block
    out = "\n".join(L).encode("latin-1")
    with open(PROM_A + ".tmp", "wb") as fh:
        fh.write(out)
    os.replace(PROM_A + ".tmp", PROM_A)
    return len(ins), skipped


def _wrap(s, width=110):
    out, line = [], ""
    for w in s.split(" "):
        if line and len(line) + 1 + len(w) > width:
            out.append(line)
            line = "  " + w
        else:
            line = (line + " " + w) if line else w
    out.append(line)
    return out


def main():
    rows = plan()
    kinds = collections.Counter("nop" if n.startswith("ButtonTable_") else
                                "not named" if "_Button" in n else "control" for _v, n, _h in rows)
    for v, n, h in rows:
        print("0x%06X  %-44s %s" % (v, n, h[0][len(n) + 2:][:90]))
    print("targets %d: %s" % (len(rows), dict(kinds)))
    if "--apply" in sys.argv:
        n, skipped = apply_(rows)
        for s in skipped:
            print("SKIPPED 0x%06X %s: %s" % s)
        print("labels placed: %d, skipped %d" % (n, len(skipped)))


if __name__ == "__main__":
    main()
