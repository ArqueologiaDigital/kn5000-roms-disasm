#!/usr/bin/env python3
r"""hdae5000_reachability.py -- which HD-AE5000 code can never execute?

QUESTION ANSWERED
-----------------
Large parts of the HD-AE5000 program area (0x280000-0x29BAFB) look like a
linked library whose entry points nothing uses.  Before a routine is described
as "dead" -- or before effort is spent naming it -- this tool answers, for every
source line of code, whether ANY path from a known entry reaches it.

HOW (conservative: every approximation errs towards "reachable")
---
1. Build the line<->address map with scripts/analysis/hdae5000_line_map.py (its
   mirror is asserted byte-identical to original_ROMs/hd-ae5000_v2_06i.ic4).
2. Every instruction or data directive is a node.  An instruction falls
   through to the next node unless it is `ret`/`reti`/`retd`, or an
   UNCONDITIONAL `jp`/`jr`/`jrl` (condition `t` counts as unconditional).  A
   data row continues only into the next row of the same directive that does
   not start a new labelled object (so reaching one table does not reach the
   next one) -- except inside the code range, where the PPORT command table is
   read from 0x2953CE through three labels (`lda xix,(0x2953ce)` + 4*(n-1)).
3. A node references another node when its operand text names a label defined
   at that node's address, or holds a numeric literal equal to a node address
   inside the code range (the `(0x2971D2:24)` / `(2718112:24)` forms, `ld xwa,
   0x00295040`, ...).  `.long` / `.short Case - Base` table rows reference their
   labels the same way.
4. ROOTS: (a) the ROM header entry block 0x280000-0x28001F; (b) every code
   address whose 32-bit little-endian encoding (a `.long` pointer: the top
   byte is 0x00) occurs ANYWHERE in the data part of the image
   (0x29BAFC-0x2FFFFF) -- pointer tables, the RAM-copied init image, and also
   chance byte matches, which can only ADD roots.  (A 24-bit search was tried
   first: 624 hits against 112 for 32 bits, the extra ones chance matches in
   the 400 KB of bitmaps, which made whole dead routines look live.)  (c)
   every label named by a line of the data files (hdae5000_data_tables.s,
   hdae5000_init_data.s, and utilities.s from 0x29BAFC on), EXCEPT the rows of
   a switch table (`.short <case> - <base>`): a case is reached through its
   table's label, i.e. only if the code naming the table is itself reached.
5. Reachable = closure of the roots under fall-through + references.

What it cannot see (so "unreachable" means "no path found", stated as such):
a code address built at run time from two 16-bit halves (`pushw lo / pushw
hi`), or computed arithmetically.  Neither form was found for code targets in
this image; string pointers are pushed that way, and strings are data.

RUN
    python3 scripts/analysis/hdae5000_reachability.py            # summary + dead ranges
    python3 scripts/analysis/hdae5000_reachability.py --labels   # per label: LIVE/DEAD
    python3 scripts/analysis/hdae5000_reachability.py --tsv OUT  # per line: addr file line live
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hdae5000_line_map as hlm  # noqa: E402

CODE_LO, CODE_HI = 0x280000, 0x29BAFC
DATA_FILES = {"hdae5000_data_tables.s", "hdae5000_init_data.s"}
LABEL = re.compile(r"^([A-Za-z_.][A-Za-z0-9_.$]*):")
TOKEN = re.compile(r"(?<![A-Za-z0-9_.$])([A-Za-z_.][A-Za-z0-9_.$]*|0x[0-9A-Fa-f]+|\d+)")
DATA_DIR = re.compile(r"^\.(long|short|word|byte|ascii|asciz|string|zero|balign|align|fill|space|incbin|org|2byte|4byte)\b", re.I)
SWITCH_ROW = re.compile(r"^\.short\s+[.\w$]+\s*-\s*[.\w$]+\s*$")
CONDS = {"f", "lt", "le", "ule", "ov", "pe", "mi", "eq", "z", "c", "ge", "gt", "ugt",
         "nov", "po", "pl", "ne", "nz", "nc", "uge"}


def strip_comment(t):
    out, q = [], False
    for ch in t:
        if ch == '"':
            q = not q
        if ch == ";" and not q:
            break
        out.append(ch)
    return "".join(out).strip()


def build():
    rows, dump = hlm.build_map()
    # label -> address, and the text of each emitting line (label stripped)
    lab_addr = {}
    nodes = []          # (addr, rel, n, body)
    for a, rel, n, t in rows:
        body = t
        m = LABEL.match(body)
        if m:
            lab_addr[m.group(1)] = a
            body = body[m.end():]
        body = strip_comment(body)
        if not body or body.startswith((".set", ".equ", ".include", ".global", ".globl",
                                        ".section", ".text", ".type", ".size", ".macro", ".endm")):
            continue
        nodes.append((a, rel, n, body))
    return nodes, lab_addr, dump


def is_terminal(body):
    parts = body.split(None, 1)
    mn = parts[0].lower()
    if mn in ("ret", "reti", "retd"):
        return True
    if mn in ("jp", "jr", "jrl"):
        ops = parts[1].split(",") if len(parts) > 1 else []
        if len(ops) == 1:
            return True
        return ops[0].strip().lower() == "t"
    return False


def analyse():
    nodes, lab_addr, dump = build()
    at = {}
    for i, (a, rel, n, body) in enumerate(nodes):
        at.setdefault(a, i)
    code_nodes = [i for i, nd in enumerate(nodes) if CODE_LO <= nd[0] < CODE_HI]
    code_addrs = {nodes[i][0] for i in code_nodes}

    def refs(body):
        out = set()
        mn = body.split(None, 1)
        if mn[0].lower() == ".org" or len(mn) < 2:
            return out
        for tok in TOKEN.findall(mn[1]):
            if tok in lab_addr:
                out.add(lab_addr[tok])
            elif tok[0].isdigit():
                v = int(tok, 16) if tok.lower().startswith("0x") else int(tok)
                if v in code_addrs:
                    out.add(v)
        return out

    # switch tables (`.short <case> - <base>` rows under a label): the cases are
    # reached through the TABLE label, i.e. only when the code naming it is live
    case_of = {}
    tab_rows = {}
    for i, (a, rel, n, body) in enumerate(nodes):
        if SWITCH_ROW.match(body):
            tab_rows[i] = True
    for name, la in lab_addr.items():
        i = at.get(la)
        if i is None or i not in tab_rows or nodes[i][0] != la:
            continue
        cs = set()
        while i in tab_rows:
            cs |= {r for r in refs(nodes[i][3]) if r in code_addrs}
            i += 1
        case_of[la] = cs

    base_refs = refs

    def refs(body):  # noqa: F811 -- table labels pull in their cases
        out = base_refs(body)
        mn = body.split(None, 1)
        if len(mn) == 2:
            for tok in TOKEN.findall(mn[1]):
                la = lab_addr.get(tok)
                if la in case_of:
                    out |= case_of[la]
        return out

    roots = set()
    for i, (a, rel, n, body) in enumerate(nodes):
        if CODE_LO <= a < CODE_LO + 0x20:
            roots.add(a)
        if (rel in DATA_FILES or a >= CODE_HI) and i not in tab_rows:
            roots |= {r for r in refs(body) if r in code_addrs}
    data = dump[CODE_HI - 0x280000:]
    for a in code_addrs:
        if data.find(a.to_bytes(4, "little")) >= 0:
            roots.add(a)

    labelled = set(lab_addr.values())
    live = [False] * len(nodes)
    work = [at[r] for r in roots if r in at]
    while work:
        i = work.pop()
        if live[i]:
            continue
        live[i] = True
        a, rel, n, body = nodes[i]
        nxt = []
        is_data = body.startswith(".")
        if i + 1 < len(nodes):
            if not is_data and not is_terminal(body):
                nxt.append(i + 1)
            elif is_data:
                # a data row continues its own table only: same directive, and
                # the next row does not start a new labelled object
                nb = nodes[i + 1]
                if (nb[3].split()[0] == body.split()[0] and not SWITCH_ROW.match(body)
                        and (nb[0] not in labelled or a < CODE_HI)):
                    nxt.append(i + 1)
        for r in refs(body):
            if r in at:
                nxt.append(at[r])
        work.extend(j for j in nxt if not live[j])
    return nodes, lab_addr, live, code_nodes, roots


def main(argv):
    nodes, lab_addr, live, code_nodes, roots = analyse()
    size = {}
    for k, i in enumerate(code_nodes):
        a = nodes[i][0]
        j = i + 1
        while j < len(nodes) and nodes[j][0] == a:
            j += 1
        size[i] = (nodes[j][0] if j < len(nodes) else CODE_HI) - a
    dead = [i for i in code_nodes if not live[i]]
    if "--tsv" in argv:
        with open(argv[argv.index("--tsv") + 1], "w", encoding="latin-1") as f:
            for i in code_nodes:
                a, rel, n, body = nodes[i]
                f.write("%06X\t%s\t%d\t%s\t%d\n" % (a, rel, n, "LIVE" if live[i] else "DEAD", size[i]))
    if "--labels" in argv:
        addr_live = {}
        for i in code_nodes:
            addr_live[nodes[i][0]] = addr_live.get(nodes[i][0], False) or live[i]
        for name, a in sorted(lab_addr.items(), key=lambda kv: kv[1]):
            if CODE_LO <= a < CODE_HI and a in addr_live:
                print("%06X %s %s" % (a, "LIVE" if addr_live[a] else "DEAD", name))
        return
    # merge dead nodes into address ranges
    ranges = []
    for i in dead:
        a = nodes[i][0]
        if ranges and ranges[-1][1] == a:
            ranges[-1][1] = a + size[i]
            ranges[-1][2].append(i)
        else:
            ranges.append([a, a + size[i], [i]])
    total = sum(size[i] for i in code_nodes)
    nd = sum(size[i] for i in dead)
    print("code nodes %d (%d B); roots %d; unreachable %d nodes, %d B in %d ranges"
          % (len(code_nodes), total, len(roots), len(dead), nd, len(ranges)))
    for lo, hi, idx in ranges:
        a, rel, n, body = nodes[idx[0]]
        print("  %06X-%06X %5d B  %s:%d" % (lo, hi - 1, hi - lo, rel, n))


if __name__ == "__main__":
    main(sys.argv[1:])
