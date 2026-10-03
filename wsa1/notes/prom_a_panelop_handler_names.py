#!/usr/bin/env python3
"""Name the handlers of prom_a's 38 PanelOpTable_* tables (and DispatchTable_FCF000) by CONTROL.

QUESTION IT ANSWERS
  prom_a 0xFCF000-0xFCFxxx holds 72-byte handler tables (17 addresses + a zero word).  Each is read by
  ONE screen's BUTTON method with a single shape:

      call PanelEvent_ToFieldIndex(code, flags, &op, &flag)       ; 0xFD7905
      cp WA,0xFFFF / jr z, skip
      ld C,4 / mul BC,(op) / add XBC,<table> / ld XBC,(XBC) / jp (XBC)

  PanelEvent_ToFieldIndex (read off its body, 0xFD7946-0xFD7989): code 0x00-0x10 -> op = code;
  0x11-0x18 -> op = code - 0x11 with the flag's bit 7 set (round 11's variant-1 already-held
  rewrite, FOLDED here onto the base code); 0x19 -> op 0x10; anything else -> no dispatch.
  So op k IS panel event code k, and the code -> control map is the established one
  (notes/prom_a_panel_control_map.py --map, which replicates round 12's SLOT_CONTROL):

      op 0-7   SoftKeyCol1-8      op 8-12  LcdKeyRow1-5      op 15  ExitKey      op 16  PageKey
      op 13    the -1/+1 pair: REFUSED -- round 11 (wave7_panel_names_round11.REFUSE_SLOT[0x0D])
               shows code 0x0D never reaches a screen's button method on this machine
      op 14    no producer: REFUSED (REFUSE_SLOT[0x0E])

  The screen comes from the reader: the table's one `add XBC,<table>` sits in a routine labelled
  ScreenButton_<Screen> or ScreenButton_Code<XX> (the screen object's +8 method), giving
  <Control>_<Screen> or <Control>_ScreenCode<XX> -- round 12's `<Control>_<Screen>` spelling.

  REFUSED, and left as they are:
    * a target already carrying a name (PanelOp_Nop and the rest);
    * a target reached at two DIFFERENT ops (one routine serving two controls has no one name);
    * a table whose reader is not a ScreenButton_* routine, or that has no reader (readers are
      looked for in prom_b too: nine of these tables belong to prom_b screen objects);
    * ops 13 and 14, as above.
  A target reached at the same op from several screens is named after the first table in
  address order; the header lists every (screen, op).

RUN
  python3 notes/prom_a_panelop_handler_names.py            # the plan, and the refusals
  python3 notes/prom_a_panelop_handler_names.py --args     # one 'old=new|header' per rename,
                                                           # the input of the session rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_A = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
OPNAME = {k: "SoftKeyCol%d" % (k + 1) for k in range(8)}
OPNAME.update({8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)})
OPNAME.update({15: "ExitKey", 16: "PageKey"})
GLOSS = {k: "SOFT KEY column %d (lower or upper; the flag carries which)" % (k + 1) for k in range(8)}
GLOSS.update({8 + k: "LCD key row %d (left or right)" % (k + 1) for k in range(5)})
GLOSS.update({15: "the EXIT key", 16: "the PAGE pair (code 0x10)"})
REFUSED_OP = {13: "op 13 is code 0x0D, the -1/+1 pair, which never reaches a screen's button method "
                  "(wave7_panel_names_round11.REFUSE_SLOT[0x0D])",
              14: "op 14 is code 0x0E, which nothing produces (REFUSE_SLOT[0x0E])"}
TABLE = re.compile(r'^((?:PanelOpTable|DispatchTable)_FCF[0-9A-F]{3}):')
GLOBAL = re.compile(r'^([A-Za-z_][\w$]*):')


def lines():
    return open(PROM_A, "rb").read().decode("latin-1").split("\n")


def tables(L):
    """{table: [(op, target name)]} for the 18-word tables in 0xFCF000-0xFCFFFF."""
    out, cur = collections.OrderedDict(), None
    for l in L:
        m = TABLE.match(l)
        if m:
            cur = m.group(1)
            out[cur] = []
            continue
        if cur:
            mm = re.match(r'^\s*\.long\s+(\S+)\s*;\s*[0-9A-F]{6}\s+\[\s*(\d+)\]', l)
            if mm:
                out[cur].append((int(mm.group(2)), mm.group(1)))
            elif l.strip() and not l.startswith(";"):
                cur = None
    return out


def readers(L):
    """{table: [reader routine]} from `add XBC,<table>` lines, in prom_a AND prom_b: nine of the
    tables are read by prom_b screen objects' BUTTON methods (ScreenButton_Code87 ...)."""
    out = collections.defaultdict(list)
    LB = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1").split("\n")
    for src in (L, LB):
        cur = None
        for l in src:
            m = GLOBAL.match(l)
            if m:
                cur = m.group(1)
                continue
            mm = re.search(r'\badd\s+x[a-z]{2},\s*((?:PanelOpTable|DispatchTable)_FCF[0-9A-F]{3})\b', l.split(";")[0], re.I)
            if mm and cur:
                out[mm.group(1)].append(cur)
    return out


def screen_of(reader):
    m = re.match(r'^ScreenButton_Code([0-9A-F]{2})$', reader)
    if m:
        return "ScreenCode" + m.group(1)
    m = re.match(r'^ScreenButton_(\w+)$', reader)
    return m.group(1) if m else None


def plan():
    L = lines()
    T, R = tables(L), readers(L)
    uses = collections.OrderedDict()           # target -> [(table, screen, op)]
    refused_tables = []
    for t, ents in T.items():
        rs = sorted(set(R.get(t, [])))
        scr = [screen_of(r) for r in rs]
        if len(rs) != 1 or scr[0] is None:
            refused_tables.append((t, rs))
            continue
        for op, tgt in ents:
            if re.match(r'^sub_F[0-9A-F]{5}$', tgt):          # prom_a or prom_b handlers
                uses.setdefault(tgt, []).append((t, scr[0], op))
    rows, refused = [], []
    for tgt, us in uses.items():
        ops = sorted({u[2] for u in us})
        where = ", ".join("%s op %d (%s)" % (u[1], u[2], u[0]) for u in us)
        if len(ops) > 1:
            refused.append((tgt, "reached at ops %s: %s" % (ops, where)))
            continue
        op = ops[0]
        if op in REFUSED_OP:
            refused.append((tgt, REFUSED_OP[op] + ": " + where))
            continue
        name = "%s_%s" % (OPNAME[op], us[0][1])
        hdr = "%s: %s on %s -- %s.\\n  op k of a PanelOpTable is panel event code k (PanelEvent_ToFieldIndex); the code -> control map is\\n  notes/prom_a_panel_control_map.py --map." % (
            name, GLOSS[op], us[0][1], where)
        rows.append((tgt, name, hdr))
    names = [r[1] for r in rows]
    dup = [n for n, c in collections.Counter(names).items() if c > 1]
    return rows, refused, refused_tables, dup


def main():
    rows, refused, rt, dup = plan()
    if "--args" in sys.argv:
        for tgt, name, hdr in rows:
            if name not in dup:
                print("%s=%s|%s" % (tgt, name, hdr))
        return
    for tgt, name, hdr in rows:
        print("%-12s -> %-34s%s" % (tgt, name, "  DUPLICATE NAME" if name in dup else ""))
    for tgt, why in refused:
        print("REFUSED %s: %s" % (tgt, why[:160]))
    for t, rs in rt:
        print("TABLE REFUSED %s: readers %s" % (t, rs))
    print("named %d (duplicate names withheld: %d), refused %d, tables refused %d"
          % (len([r for r in rows if r[1] not in dup]), len([r for r in rows if r[1] in dup]), len(refused), len(rt)))


if __name__ == "__main__":
    main()
