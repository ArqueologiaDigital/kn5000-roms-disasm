#!/usr/bin/env python3
"""Name COMBINATION EDIT MIXER's cell painters, their repaint callbacks and dirty masks after the PART parameter each draws.

QUESTION IT ANSWERS
  The MIXER screens (0x3A / 0xB7) draw 8 parts x 13 cells.  Each cell painter in prom_a 0xFBE5EE-0xFBECC3 starts
  with one read of one part-parameter byte:
      pushw OFF / push 0 / push PART             / call T_IndexedTable_GetByte     -> the part's first record
      pushw OFF / ld BC,(XIZ+8) / ... add BC,0x20 / pushw bc / call ..GetByte     -> its second record (part + 0x20)
  optionally followed by `and A,MASK` or `res 7,A` (MASK 0x7F).  The SysEx parameter descriptors
  (notes/sysex-probes/sysex_param_addresses.py, PART area 20 xx) give every Reference-Guide parameter its record
  (`rec` 0 / 32), offset and mask, so (record, offset, mask) names the cell.  The descriptors' masks are matched
  exactly; a read with no mask matches the one descriptor whose mask is the full byte, or -- for offset 13, whose
  bits 5-7 have cells of their own -- BASIC CHANNEL (bits 0-4), by elimination (stated in its header).
  Each painter is followed by a repaint callback (a `.L` label with no name of its own):
      ld E,(DIRTY) / ld (DIRTY),0 under `ei 6`, then for the 8 parts of the edited group whose bit is set: the painter
  and CombiEditMixer_OnPartParamEvent's page routines OR a part's bit into DIRTY and post the callback
  (T_CallbackQueue_Post).  So the callback and its DIRTY byte are named after the same parameter.
  One painter reads no parameter byte: 0xFBE5EE draws the part's sound (second record +0x1B / +0x1C / +0x1D in
  panel-mode group 0x16, else T_F42CA0's text); it is named CombiEditMixer_DrawSound by that reading.

RUN
  python3 notes/prom_a_combi_mixer_cells.py          # the plan
  python3 notes/prom_a_combi_mixer_cells.py --args   # 'old=new|header' for the rename helper (the painters)
  python3 notes/prom_a_combi_mixer_cells.py --place  # 'ADDR=Name|header' for the label placer (the callbacks)
  python3 notes/prom_a_combi_mixer_cells.py --ram    # RAM rows for scripts/tools/name_wsa1_ram.py (the dirty masks)
"""
import contextlib
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes", "sysex-probes"))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1").split("\n")
LO, HI = 0xFBE5EE, 0xFBECC3
H = "(notes/prom_a_combi_mixer_cells.py)"


def camel(s):
    s = re.sub(r'[^A-Za-z0-9]+', ' ', s.replace("&", " and ")).strip()
    return "".join(w[:1].upper() + w[1:].lower() for w in s.split())


def params():
    with contextlib.redirect_stdout(io.StringIO()):
        saved, sys.argv = sys.argv, ["x"]
        import sysex_param_addresses as P
        sys.argv = saved
    names = json.load(open(os.path.join(ROOT, "notes", "sysex-probes", "param_names.json")))
    return [(p.rec, p.off, p.mask, names["%02X/%02X" % (p.b7, p.b8)]["name"]) for p in P.PARAMS if p.b7 == 0x20]


def addr(i):
    for x in A[i + 1:i + 6]:
        m = re.search(r';\s*(F[0-9A-F]{5})\b', x)
        if m and x.split(";")[0].strip() and not re.match(r'^[\w.$]+:', x.strip()):
            return int(m.group(1), 16)
    return None


def code(i, n):
    out = []
    for x in A[i + 1:]:
        c = re.sub(r'\s+', ' ', x.split(";")[0]).strip()
        if c:
            out.append(c)
        if len(out) >= n:
            break
    return out


def read_of(body):
    j = next((k for k, c in enumerate(body) if c == "call T_IndexedTable_GetByte"), None)
    if j is None:
        return None
    pre = " ; ".join(body[:j])
    off = re.findall(r'pushw (0x[0-9a-f]+)', pre)
    if not off:
        return None
    rec = 32 if "add BC,0x0020" in pre else 0
    nxt = body[j + 1] if j + 1 < len(body) else ""
    m = re.match(r'and A,(0x[0-9a-f]+)$', nxt)
    mask = int(m.group(1), 16) if m else (0x7F if nxt == "res 0x07,A" else None)
    return rec, int(off[0], 16), mask


def plan():
    P = params()
    labels = [(i, re.match(r'^([A-Za-z_.][\w$.]*):', l).group(1)) for i, l in enumerate(A) if re.match(r'^[A-Za-z_.][\w$.]*:', l)]
    cells, callbacks = {}, []
    for i, lab in labels:
        a = addr(i)
        if a is None or not LO <= a < HI:
            continue
        body = code(i, 14)
        if lab.startswith("sub_") or lab.startswith("CombiEditMixer_Draw"):   # the second spelling: after the rename
            r = read_of(body)
            if r is None:
                if a == 0xFBE5EE:
                    cells[lab] = (a, "Sound", "the part's sound: in panel-mode group 0x16 the second record's +0x1D bank, +0x1B group, "
                                  "+0x1C member (number = group x 8 + member + 1), otherwise T_F42CA0's text")
                continue
            rec, off, mask = r
            hits = [p for p in P if p[0] == rec and p[1] == off and (mask is None or p[2] == mask)]
            if mask is None and len(hits) > 1:
                full = [p for p in hits if p[2] in (0xFF, 0x7F)]
                hits = full if full else [p for p in hits if (rec, off, p[2]) == (0, 13, 0x1F)]
                why = "no mask; offset 13's bits 5-7 have cells of their own, so BASIC CHANNEL (bits 0-4) by elimination"
            else:
                why = None
            if len(hits) != 1:
                print("REFUSED %s: record %d offset %d mask %s -> %s" % (lab, rec, off, mask, [h[3] for h in hits]), file=sys.stderr)
                continue
            name = hits[0][3]
            ev = "reads %s record byte %d%s: %s" % ("the second" if rec else "the first", off, "" if mask is None else " & 0x%02X" % mask, name)
            cells[lab] = (a, camel(name), ev + ("; " + why if why else ""))
        elif lab.startswith(".L") or lab.startswith("CombiEditMixer_RepaintMarked"):   # likewise
            body = code(i, 30)
            m = re.match(r'ld e, \((0x27[0-9a-f]{2}):16\)$', body[3]) if len(body) > 3 else None
            if body[:3] != ["pushw hl", "pushw de", "ei 0x06"] or not m:
                continue                      # a callback starts exactly so; anything else is a branch target
            own = body[:next((k for k, c in enumerate(body) if c == "ret"), len(body))]
            call = next((c.split()[1] for c in own if re.match(r'calr (sub_|CombiEditMixer_Draw)', c)), None)
            if call:
                callbacks.append((a, int(m.group(1), 16), call))
    return cells, callbacks, labels


def main():
    cells, callbacks, labels = plan()
    if "--args" in sys.argv:
        for lab, (a, nm, ev) in sorted(cells.items(), key=lambda x: x[1][0]):
            if not lab.startswith("sub_"):
                continue                      # applied already
            print("%s=CombiEditMixer_Draw%s|CombiEditMixer_Draw%s: (part) the MIXER cell of one part -- %s.  Basis: table "
                  "(descriptor match) %s" % (lab, nm, nm, ev, H))
        return
    if "--place" in sys.argv:
        named = {a for a, _d, _c in callbacks if any(l.startswith("CombiEditMixer_RepaintMarked") and addr(i) == a for i, l in labels)}
        for a, dirty, call in callbacks:
            if call in cells and a not in named:
                nm = cells[call][1]
                print("%06X=CombiEditMixer_RepaintMarked%s|CombiEditMixer_RepaintMarked%s: the callback CombiEditMixer_OnPartParamEvent "
                      "posts: takes and clears CombiEditMixer_Dirty%s (0x%04X) under ei 6, then CombiEditMixer_Draw%s for each "
                      "part of the edited group whose bit is set.  Basis: body %s" % (a, nm, nm, nm, dirty, nm, H))
        return
    if "--ram" in sys.argv:
        for a, dirty, call in callbacks:
            if call in cells:
                print('        0x%04X: ("CombiEditMixer_Dirty%s", "the parts of the edited group (bit = part & 7) whose %s cell '
                      'waits for a repaint", "CombiEditMixer_RepaintMarked%s"),' % (dirty, cells[call][1], cells[call][1], cells[call][1]))
        return
    for lab, (a, nm, ev) in sorted(cells.items(), key=lambda x: x[1][0]):
        print("0x%06X %-12s -> CombiEditMixer_Draw%-28s %s" % (a, lab, nm, ev[:70]))
    for a, dirty, call in callbacks:
        print("0x%06X callback, dirty 0x%04X -> %s" % (a, dirty, call))
    print("cells %d, callbacks %d" % (len(cells), len(callbacks)))


if __name__ == "__main__":
    main()
