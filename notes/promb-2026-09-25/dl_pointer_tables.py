#!/usr/bin/env python3
r"""Type the prom_b `Data_*` objects that are whole arrays of 32-bit pointers to display-list records.

QUESTION THIS ANSWERS
    Thirteen coverage-walk objects ("EMITTED AS DATA", no layout) consist
    entirely of little-endian 32-bit prom_b addresses, each the first byte of an
    interpreter-A or -B record.  What reads them, and how?  For every place the
    firmware loads the object's address as a 32-bit immediate (prom_a and
    prom_b bytes), this script matches the instructions that follow against
    the reader shapes below -- byte for byte -- and REFUSES an object with a
    site it cannot classify:

      ONE     `ld XIY,this / call RunDisplayListBFromPointerArray (0xF09AE1)`:
              index A, ONE interpreter-B record is run from the entry.
      PAIR    `ld XIZ,this / ld XIY,(XIZ+BC) / add BC,4 / ld XIX,(XIZ+BC) /
              call T_DisplayList[B]_Run`: entries k and k+1 are the start and
              the end of list k.
      PAIR2   `ld XIY,this / extz XWA / xor W,W / sla 2,WA / add XIY,XWA /
              ld XIZ,XIY / ld XIY,(XIZ) / ld XIX,(XIZ+4)` then a run: the same
              pairing, indexed by A.
      FIXED   `ld XIZ,this / ld XIY,(XIZ+DE) / ld XIX,XIY / add XIX,n / .. call
              T_DisplayList_Run`: entry k is ONE n-byte list.
      END     `ld XIX,this / call T_DisplayList[B]_Run`: the address is also the
              END of the list that the `ld XIY` before it starts.
    The entry count is the object's extent over 4 (every word checked to be a
    record start); where a shape bounds the index (a `cp A,..` the script
    also checks) that is stated.  `Data_F33A1B` is three 3-entry tables read by
    one loop and is checked separately.

RUN
    python3 notes/promb-2026-09-25/dl_pointer_tables.py            # checks
    python3 notes/promb-2026-09-25/dl_pointer_tables.py --apply    # write the source
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    make gate-wsa1
"""
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE, BASE_A = 0xF00000, 0xF80000
OBJECTS = ["Data_F02F52", "Data_F02F9A", "Data_F03173", "Data_F0355D", "Data_F036C2", "Data_F04E93",
           "Data_F0509B", "Data_F0563B", "Data_F3281C", "Data_F32B97", "Data_F33508", "Data_F3380E"]
RUNNERS = {"1df017f4": "T_DisplayList_Run", "1df417f4": "T_DisplayListB_Run"}
A_LEN = None          # interpreter-A record lengths come from the record itself
FAIL = []
# Facts about one object's readers that the shapes alone do not carry; each is checked in derive().
NOTES = {
    "Data_F03173": "The callers' index ranges reach past the table: the pairing site takes A = 8..19 "
                   "(`cp A,0x14 / jr NC` at 0xF5CB2A, `cp A,8 / jr C` at 0xF5CB2F), so A = 18 and 19 read "
                   "entry 19 / 20; the one-record site takes A + 13 for A = 2..5 and 7 (`add A,0x0d` at 0xF5CB5E), "
                   "so A = 7 reads entry 20.  Entries 19 and 20 would be the first bytes of DL_F031BF, "
                   "which the same routine runs as a list at 0xF5CB68 -- so either those values of A do "
                   "not occur or the reads are garbage; entries 0..7 are read by neither site.",
}


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


class Img:
    def __init__(self):
        self.b = open(ROMB, "rb").read()
        self.a = open(ROMA, "rb").read()

    def at(self, x, n):
        if x >= BASE_A:
            return self.a[x - BASE_A:x - BASE_A + n]
        return self.b[x - BASE:x - BASE + n]

    def loads(self, v):
        """[(site, reg)] for every `ld r32,imm32` (0x40+r) whose immediate is v, in both images."""
        out = []
        pat = v.to_bytes(4, "little")
        for base, r in ((BASE, self.b), (BASE_A, self.a)):
            i = r.find(pat)
            while i >= 0:
                if i >= 1 and 0x40 <= r[i - 1] <= 0x47:
                    out.append((base + i - 1, r[i - 1] - 0x40))
                i = r.find(pat, i + 1)
        return out


def shape(img, site, reg):
    """Classify the instructions after `ld r32,this` at site."""
    nx = img.at(site + 5, 24).hex()
    if reg == 5 and nx.startswith("1de19af0"):
        return ("ONE", "`ld XIY,this / call RunDisplayListBFromPointerArray` at 0x%06X: ONE "
                "interpreter-B record from entry A" % site)
    if reg == 6 and nx.startswith("e307f8e425d9c80400e307f8e424") and nx[28:36] in RUNNERS:
        return ("PAIR", "`ld XIZ,this / ld XIY,(XIZ+BC) / add BC,4 / ld XIX,(XIZ+BC) / call %s` at "
                "0x%06X: entries k and k+1 bound list k" % (RUNNERS[nx[28:36]], site))
    if reg == 5 and nx.startswith("e812c8d0d8ec02e885ed8ea625ae0424"):
        return ("PAIR2", "`ld XIY,this / sla 2,WA / add XIY,XWA / ld XIZ,XIY / ld XIY,(XIZ) / ld XIX,(XIZ+4)` "
                "then T_DisplayListB_Run at 0x%06X: XIY = entry A, XIX = entry A+1" % site)
    if reg == 6 and nx.startswith("e307f8e825ed8cecc8"):
        n = int.from_bytes(bytes.fromhex(nx[18:26]), "little")
        return ("FIXED", "`ld XIZ,this / ld XIY,(XIZ+DE) / ld XIX,XIY / add XIX,%d` then "
                "T_DisplayList_Run at 0x%06X: entry k is ONE %d-byte list" % (n, site, n), n)
    if reg == 4 and nx[:8] in RUNNERS:
        prev = img.at(site - 5, 5)
        start = int.from_bytes(prev[1:5], "little") if prev[0] == 0x45 else None
        return ("END", "`%sld XIX,this / call %s` at 0x%06X: the END of the list%s"
                % ("ld XIY,0x%06X / " % start if start else "", RUNNERS[nx[:8]], site,
                   " that starts at 0x%06X" % start if start else ""))
    return None


def obj_extent(L, i):
    lo, hi, last = None, None, None
    k = i + 1
    while k < len(L):
        m = re.match(r'^\t\.byte\t(0x[0-9A-F]{2}(?:, 0x[0-9A-F]{2})*)\t; ([0-9A-F]{6})  \|.*\|$', L[k])
        if not m:
            break
        if lo is None:
            lo = int(m.group(2), 16)
        last, hi = k, int(m.group(2), 16) + len(m.group(1).split(","))
        k += 1
    return lo, hi, last


def rec(img, p):
    op, ln = img.at(p, 2)
    return op, ln


def derive(img):
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    plans = []
    for lab in OBJECTS:
        i = [k for k, t in enumerate(L) if t == lab + ":"]
        check("%s: one label line" % lab, len(i) == 1)
        if len(i) != 1:
            continue
        lo, hi, last = obj_extent(L, i[0])
        n = (hi - lo) // 4
        ws = [int.from_bytes(img.at(lo + 4 * k, 4), "little") for k in range(n)]
        ok = (hi - lo) % 4 == 0 and all(BASE <= w < 0xF80000 for w in ws)
        sites = [shape(img, s, r) for s, r in img.loads(lo)]
        paired = any(x and x[0] in ("PAIR", "PAIR2") for x in sites)
        # a PAIR table's last entry is the END of its last list, not necessarily a record
        tail_end = paired and ws == sorted(ws) and not (img.at(ws[-1], 1)[0] < 0x24 and
                                                        img.at(ws[-1] + 1, 1)[0] in (5, 7, 9, 10, 11, 12, 13, 15, 17))
        recs = [rec(img, w) for w in (ws[:-1] if tail_end else ws)]
        check("%s 0x%06X-0x%06X: %d LE32 prom_b addresses, each a record start (op/len %s); %d "
              "reader sites, every one of a known shape (%s)"
              % (lab, lo, hi - 1, n, " ".join(sorted(set("%02X/%d" % r for r in recs))), len(sites),
                 ", ".join(sorted(set(s[0] for s in sites if s)))),
              ok and all(r[0] < 0x24 and r[1] in (5, 7, 9, 10, 11, 12, 13, 15, 17) for r in recs)
              and sites and all(sites) and any(s[0] != "END" for s in sites))
        if lab == "Data_F03173":
            check("  Data_F03173's note: `cp A,0x14` (c9 cf 14) at 0xF5CB2A, `cp A,8` (c9 cf 08) at 0xF5CB2F, "
                  "`add A,0x0d` (c9 c8 0d) at 0xF5CB5E, DL_F031BF (0xF031BF) run at 0xF5CB68, and the "
                  "table ends at 0xF031BF", img.at(0xF5CB2A, 3).hex() == "c9cf14"
                  and img.at(0xF5CB2F, 3).hex() == "c9cf08" and img.at(0xF5CB5E, 3).hex() == "c9c80d"
                  and img.at(0xF5CB68, 5).hex() == "45bf31f000" and hi == 0xF031BF)
        plans.append(dict(label=lab, lo=lo, hi=hi, n=n, ws=ws, recs=recs, sites=sites, line=i[0],
                          last=last, tail_end=tail_end))
    return plans


def emit(p):
    lab = "DLRecordPtrs_%06X" % p["lo"]
    reads = [s for s in p["sites"] if s[0] != "END"]
    ends = [s for s in p["sites"] if s[0] == "END"]
    body = ("%s -- 0x%06X-0x%06X, %d 32-bit pointers, each to the first byte of a display-list "
            "record (%s).  Read by: %s.%s  Entry count: the object's extent over 4; every word is a "
            "record start (notes/promb-2026-09-25/dl_pointer_tables.py)."
            % (lab, p["lo"], p["hi"] - 1, p["n"],
               ", ".join("op %02X len %d" % r for r in sorted(set(p["recs"]))),
               "; ".join(s[1] for s in reads),
               ("  Its address is also used as a list end: %s." % "; ".join(s[1] for s in ends))
               if ends else "")
            + ("  The last entry, 0x%06X, is only the END of the last list%s."
               % (p["ws"][-1], " -- this table's own address" if p["ws"][-1] == p["lo"] else "")
               if p["tail_end"] else "")
            + ("  " + NOTES[p["label"]] if p["label"] in NOTES else ""))
    out = ["; " + "-" * 74]
    out += textwrap.wrap(body, width=78, initial_indent="; ", subsequent_indent=";   ")
    out.append("; " + "-" * 74)
    out.append("%s:" % lab)
    for k, w in enumerate(p["ws"]):
        out.append("\t.long\t0x%08X\t; %06X  [%d]" % (w, p["lo"] + 4 * k, k))
    return lab, out


OLD_EXTENT = ("; ⚠ The extent is the reachability walk's, not the object's; the rest of\n"
              ";   this span is unreachable and stays `.incbin`.  Why this is data and\n"
              ";   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.").encode(
                  "utf-8").decode("latin-1")
NEW_EXTENT = ("; ⚠ CORRECTED: that extent came from the coverage walk, not from the object;\n"
              ";   the readers below fix what the object is (notes/promb-2026-09-25/\n"
              ";   dl_pointer_tables.py).  The rest of this span is unreachable and stays\n"
              ";   `.incbin`.  Why this is data and not code: THE PROVENANCE SPLIT in\n"
              ";   notes/gen_prom_b_cover_round1.py.").encode("utf-8").decode("latin-1")


def apply(plans):
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    ren = {}
    for p in sorted(plans, key=lambda p: -p["line"]):
        i = p["line"]
        h = i
        while L[h - 1].startswith(";"):
            h -= 1
        head = "\n".join(L[h:i])
        assert OLD_EXTENT in head, p["label"]
        head = head.replace(OLD_EXTENT, NEW_EXTENT)
        head = re.sub(r'^; %s -- (\d+) bytes, EMITTED AS DATA' % p["label"],
                      lambda m: "; 0x%06X-0x%06X -- %s bytes, EMITTED AS DATA" % (p["lo"], p["hi"] - 1,
                                                                                  m.group(1)),
                      head, count=1, flags=re.M)
        lab, out = emit(p)
        new = head.split("\n") + out[1:]
        new = [x.encode("utf-8").decode("latin-1") if any(ord(c) > 0xFF for c in x) else x for x in new]
        L = L[:h] + new + L[p["last"] + 1:]
        ren[p["label"]] = lab
    txt = "\n".join(L)
    for o, n in ren.items():
        txt = re.sub(r'\b%s\b' % o, n, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    with open(os.path.join(HERE, "dl_pointer_tables.map"), "w") as f:
        f.write("".join("%s=%s\n" % kv for kv in sorted(ren.items())))
    print("wrote", SRC, "and dl_pointer_tables.map (%d)" % len(ren))


def main():
    img = Img()
    plans = derive(img)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    for p in plans:
        for s in p["sites"]:
            print("    %-12s %s" % (p["label"], s[1]))
    if "--apply" in sys.argv:
        apply(plans)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
