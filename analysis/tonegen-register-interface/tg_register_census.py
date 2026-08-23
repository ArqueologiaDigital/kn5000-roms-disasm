#!/usr/bin/env python3
"""Census of every tone-generator (IC303) register access in the KN5000 firmware.

QUESTION THIS ANSWERS
---------------------
"Which IC303 registers does the firmware actually write, from where in the code,
and what is the data source of each write?"  It also answers the negative half:
"is there a routine that walks a big ROM table straight into TG registers?" --
by listing every TG write site there is, so the absence of one cannot be a
sampling artefact.

THE SIGNAL BEING READ
---------------------
IC303 sits on the SUB-CPU bus only:

    0x100000  write -> register ADDRESS latch      read -> status / active-voice bitmap
    0x100002  write -> register DATA               (never read by the payload)
    0x110000 / 0x110002   the keybed window (A23 high), not the register file

The address latch word is  (register << 6) | voice , voice = 0..0x3F.  So a write
site looks like

        res 7,(0x18)            ; P6.7 low -> A23 low -> select the TG window
        ld   wa, iz             ; voice number
        add  wa, 0x840          ; register 0x21
        ld   (0x100000), wa     ; ADDRESS latch
        nop
        set 7,(0x18)
        ld   wa, (xwa + 26)     ; the datum, here staging block +0x1A
        ld   (0x100002), wa     ; DATA
        jr   <next insn>        ; + 3 nops: the mandatory settling gap

This script recognises that shape in the disassembly sources and reports, per
site: the source label, the address-latch value (constant bank, or "+ch" form),
and where the datum came from (staging-block offset, immediate, or register).

USAGE
-----
    python3 analysis/tonegen-register-interface/tg_register_census.py            # summary
    python3 analysis/tonegen-register-interface/tg_register_census.py --sites    # every site
    python3 analysis/tonegen-register-interface/tg_register_census.py --csv      # machine readable

Run from the repository root.  Sources scanned (all of them, no sampling):
    v142/subcpu/kn5000_subprogram_v142.s   the sub-CPU payload, v1.42
    subcpu/boot/kn5000_subcpu_boot.s       the sub-CPU boot mask ROM (IC30)
    v7/ v9/ v10/                           the MAIN CPU program -- scanned only to
                                           show it never touches 0x100000/0x100002.
"""

import argparse
import os
import re
import sys

SRC_SUB_PAYLOAD = "v142/subcpu/kn5000_subprogram_v142.s"
SRC_SUB_BOOT = "subcpu/boot/kn5000_subcpu_boot.s"
MAIN_DIRS = ("v7", "v9", "v10")

ADDR_LATCH = 0x100000
DATA_PORT = 0x100002

LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")
# Any store whose operand names 0x100000 / 0x100002 (or the decimal spellings).
# Both source trees spell the direct-addressing operand with and without parentheses.
STORE_LATCH_REG = re.compile(r"^\s*stw_da\s+\(?0x100000\)?,\s*(\w+)")
STORE_LATCH_IMM = re.compile(r"^\s*stiw_da\s+\(?0x100000\)?,\s*(0x[0-9a-fA-F]+|\d+)")
STORE_DATA_REG = re.compile(r"^\s*stw_da\s+\(?0x100002\)?,\s*(\w+)")
STORE_DATA_IMM = re.compile(r"^\s*stiw_da\s+\(?0x100002\)?,\s*(0x[0-9a-fA-F]+|\d+)")
READ_LATCH = re.compile(r"^\s*ldw_da\s+\w+,\s*\(?0x10000[04]\)?")
READ_DATA = re.compile(r"^\s*ldw_da\s+\w+,\s*\(?0x100002\)?")
ADD_BANK = re.compile(r"^\s*add\s+wa,\s*(0x[0-9a-fA-F]+|\d+)\s*$")
LD_SHADOW = re.compile(r"^\s*ld\s+wa,\s*\(xwa\s*\+\s*(\d+)\)")
LD_SHADOW_IZ = re.compile(r"^\s*ld\s+wa,\s*\(xiz\s*\+\s*(\d+)\)")
LD_IZ = re.compile(r"^\s*ld\s+wa,\s*iz\s*$")


def num(tok):
    return int(tok, 16) if tok.lower().startswith("0x") else int(tok)


def scan(path, lines):
    """Return (sites, reads).  A site is a dict describing one register write."""
    sites, reads = [], []
    label = "<top of file>"
    routine = "<top of file>"
    # Continuation labels are the settling gap + the next address/data pair of the same
    # burst; they are not separate routines.  Fold them into the routine that opened it.
    cont = re.compile(r"^(__jrt_nop_|.*_NopCont|.*_NopGap|.*_Word\d)")
    # A small sliding window is enough: the address latch and its data partner are
    # never more than ~10 instructions apart, and no other TG write intervenes.
    pending = None          # the latch half, waiting for its data half
    bank = None             # last `add wa, imm` seen
    bank_line = -1
    from_iz = False
    for i, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")
        m = LABEL_RE.match(line)
        if m:
            label = m.group(1)
            if not cont.match(label):
                routine = label
            continue
        if line.lstrip().startswith(";"):
            continue

        if ADD_BANK.match(line):
            bank, bank_line = num(ADD_BANK.match(line).group(1)), i
            continue
        if LD_IZ.match(line):
            # `ld wa, iz` reloads the bare channel; a following `add` gives the bank,
            # its absence means bank 0x000.
            bank, bank_line, from_iz = None, -1, True
            continue

        m = STORE_LATCH_REG.match(line)
        if m:
            if bank is not None and i - bank_line <= 3:
                latch = "0x%03X + ch" % bank
                reg = bank >> 6
            elif from_iz:
                latch = "0x000 + ch"
                reg = 0
            else:
                latch = "(register-computed)"
                reg = None
            pending = dict(file=path, line=i, label=label, routine=routine,
                           latch=latch, reg=reg)
            bank, from_iz = None, False
            continue
        m = STORE_LATCH_IMM.match(line)
        if m:
            v = num(m.group(1))
            pending = dict(file=path, line=i, label=label, routine=routine,
                           latch="0x%04X (absolute)" % v, reg=v >> 6)
            bank, from_iz = None, False
            continue

        if pending:
            m = LD_SHADOW.match(line) or LD_SHADOW_IZ.match(line)
            if m:
                pending["src"] = "shadow+0x%02X" % int(m.group(1))
                continue
            m = STORE_DATA_IMM.match(line)
            if m:
                pending["src"] = "immediate %s" % m.group(1)
                sites.append(pending)
                pending = None
                continue
            m = STORE_DATA_REG.match(line)
            if m:
                pending.setdefault("src", "register %s" % m.group(1))
                sites.append(pending)
                pending = None
                continue

        if READ_LATCH.match(line):
            reads.append(dict(file=path, line=i, label=label, port="0x100000 (status)"))
        elif READ_DATA.match(line):
            reads.append(dict(file=path, line=i, label=label, port="0x100002 (data)"))

    if pending:
        pending["src"] = "<no data write found>"
        sites.append(pending)
    return sites, reads


def count_raw(path, lines):
    """Raw occurrence counts, independent of the pattern matcher -- a cross-check."""
    n = dict(latch_w=0, data_w=0, latch_r=0, data_r=0)
    for raw in lines:
        line = raw.rstrip("\n")
        if line.lstrip().startswith(";"):
            continue
        if re.search(r"st\w*_da\s+\(?0x100000", line):
            n["latch_w"] += 1
        if re.search(r"st\w*_da\s+\(?0x100002", line):
            n["data_w"] += 1
        if re.search(r"ld\w*_da\s+\w+,\s*\(?0x10000[04]", line):
            n["latch_r"] += 1
        if re.search(r"ld\w*_da\s+\w+,\s*\(?0x100002", line):
            n["data_r"] += 1
    return n


def read(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.readlines()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sites", action="store_true", help="print every write site")
    ap.add_argument("--csv", action="store_true", help="CSV of every write site")
    ap.add_argument("--routines", action="store_true",
                    help="group the write sites by the routine that issues them")
    args = ap.parse_args()

    if not os.path.isdir("v142"):
        sys.exit("run this from the repository root (kn5000-roms-disasm)")

    all_sites, all_reads = [], []
    for path in (SRC_SUB_PAYLOAD, SRC_SUB_BOOT):
        lines = read(path)
        s, r = scan(path, lines)
        raw = count_raw(path, lines)
        all_sites += s
        all_reads += r
        if not args.csv:
            print("%-42s  latch writes %3d  data writes %3d  latch reads %d  data reads %d"
                  % (path, raw["latch_w"], raw["data_w"], raw["latch_r"], raw["data_r"]))
            print("%-42s  matched write sites: %d" % ("", len(s)))

    # The main CPU: prove the absence rather than assume it.
    if not args.csv:
        access, immediate = [], []
        tok = re.compile(r"\b0x10000[02]\b(?![0-9a-fA-F])")
        acc_form = re.compile(r"^\s*(st|ld)\w*_da\b")
        for d in MAIN_DIRS:
            for root, _dirs, files in os.walk(d):
                for fn in sorted(files):
                    if not fn.endswith(".s"):
                        continue
                    p2 = os.path.join(root, fn)
                    for i, raw in enumerate(read(p2), 1):
                        line = raw.split(";", 1)[0].rstrip()
                        if not tok.search(line):
                            continue
                        if acc_form.match(line) or re.search(r"\(0x10000[02]\)", line):
                            access.append((p2, i, line.strip()))
                        else:
                            immediate.append((p2, i, line.strip()))
        print("\nMAIN CPU (v7+v9+v10):")
        print("  bus ACCESSES to 0x100000/0x100002 : %d" % len(access))
        for h in access:
            print("     %s:%d  %s" % h)
        print("  IMMEDIATE uses of the same constants (not bus cycles): %d" % len(immediate))
        for h in immediate:
            print("     %s:%d  %s" % h)

    if args.csv:
        print("file,line,routine,label,latch,reg,src")
        for s in all_sites:
            print("%s,%d,%s,%s,%s,%s,%s" % (s["file"], s["line"], s["routine"], s["label"],
                                            s["latch"],
                                            "" if s["reg"] is None else "0x%02X" % s["reg"],
                                            s.get("src", "?")))
        return

    if args.routines:
        print("\n--- write sites grouped by the routine that issues them ---")
        order, groups = [], {}
        for s in all_sites:
            key = (s["file"], s["routine"])
            if key not in groups:
                order.append(key)
                groups[key] = []
            groups[key].append(s)
        for key in order:
            rows = groups[key]
            print("\n%s   (%s:%d, %d register writes)"
                  % (key[1], os.path.basename(key[0]), rows[0]["line"], len(rows)))
            for r in rows:
                print("    %-20s reg %-5s <- %s"
                      % (r["latch"], "0x%02X" % r["reg"] if r["reg"] is not None else "?",
                         r.get("src", "?")))

    if args.sites:
        print("\n--- every matched write site ---")
        for s in all_sites:
            print("  %-14s %-20s reg %-6s <- %-22s  %s:%d (%s)"
                  % ("", s["latch"], "0x%02X" % s["reg"] if s["reg"] is not None else "?",
                     s.get("src", "?"), os.path.basename(s["file"]), s["line"], s["label"]))

    # Register histogram.
    hist = {}
    for s in all_sites:
        hist.setdefault(s["latch"], []).append(s)
    print("\n--- distinct address-latch values, with write count ---")
    for latch in sorted(hist, key=lambda k: (len(k), k)):
        rows = hist[latch]
        srcs = sorted({r.get("src", "?") for r in rows})
        reg = rows[0]["reg"]
        print("  %-20s reg %-6s  %3d writes   sources: %s"
              % (latch, "0x%02X" % reg if reg is not None else "?", len(rows),
                 ", ".join(srcs[:6]) + (" ..." if len(srcs) > 6 else "")))

    print("\n--- reads of the register window ---")
    for r in all_reads:
        print("  %-22s %s:%d (%s)" % (r["port"], os.path.basename(r["file"]), r["line"], r["label"]))


if __name__ == "__main__":
    main()
