#!/usr/bin/env python3
r"""fix_subcpu_boot_sfr_names.py -- the boot ROM's SFR names, checked against the TMP94C241 map MAME uses.

QUESTION THIS ANSWERS
    subcpu/boot/kn5000_subcpu_boot.s carries its own table of SFR `.equ`s.  19 of them disagree
    with v142/subcpu/shared/sfr_tmp94c241.s (the payload's table) -- e.g. boot T8RUN = 0x82,
    payload T8RUN = 0x80.  Which is right?  MAME's TMP94C241 device -- the emulation that boots
    this machine -- maps 0x80 = t8run, 0x81 = trdc, 0x82 = tffcr, 0x84 = t01mod, 0x85 = t23mod,
    0x88..0x8B = treg0..3, 0x03/0x07/0x0B/0x0F = port 0..3 FC, 0x94/0x95 = cap4, 0x9E = t16run,
    0x110/0x111 = watchdog (mame_driver/src/devices/cpu/tlcs900/tmp94c241.cpp, map() lines
    800-900), i.e. the PAYLOAD's table.  (The tmp94c241 skill's references/sfr.md, which puts
    T8RUN at 0x82, disagrees with MAME too.)  The boot table's wrong values were unused by its
    code, but its port-init COMMENTS were written from them ("0x07: Port 0 all function",
    "0x81: Watchdog control", "set 1,(0x80): Watchdog mode").

WHAT --apply DOES
    * corrects the wrong `.equ` values in place (P0FC..P2FC, T01MOD, T8RUN, TRDC, TREG0/1,
      T23MOD, WDMOD, WDCR, CAP4L/H), each line noting the old value; marks the names that are
      not TMP94C241 registers at their address at all (T01FFCR, T23FFCR, the SC0BUF..SC1MOD
      aliases at 0x34..0x3E, PF_FC, PORT_FC_1..4) without moving them;
    * adds the missing names the code needs (P3FC, port C/D/E/F data/CR/FC, T02FFCR, T16RUN,
      T16CR, IIMC) with the payload table's values;
    * rewrites the SFR operand of every `*_dd8` instruction and `(addr:8)` memory operand to
      the name for that address (PC = 0x30 excepted: `(PC:8)` reads as the PC register);
    * corrects the three port-init comments proven false by the map (old text quoted).
    The byte gate proves the operand rewrites.

RUN
    python3 scripts/converters/fix_subcpu_boot_sfr_names.py --apply ; make gate
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = os.path.join(ROOT, "subcpu/boot/kn5000_subcpu_boot.s")
STAR = "★".encode("utf-8").decode("latin-1")

FIX = {"P0FC": 0x03, "P1FC": 0x07, "P2FC": 0x0B, "T01MOD": 0x84, "T8RUN": 0x80, "TRDC": 0x81,
       "TREG0": 0x88, "TREG1": 0x89, "T23MOD": 0x85, "WDMOD": 0x110, "WDCR": 0x111,
       "CAP4L": 0x94, "CAP4H": 0x95}
WRONG = {"T01FFCR": "0x81 is TRDC; the timers' flip-flop control is T02FFCR, 0x82",
         "T23FFCR": "0x89 is TREG1; there is no separate timer-2/3 flip-flop register",
         "SC0BUF": "0x34 is port D (PD); SC0BUF is 0xD0 (SER0_BUF)",
         "SC0CR": "0x36 is PDCR", "SC0MOD": "0x38 is port E (PE)", "SC1BUF": "0x3A is PECR",
         "SC1CR": "0x3C is port F (PF)", "SC1MOD": "0x3E is PFCR",
         "PF_FC": "0xE5 is INTET23 (interrupt level, timers 2/3)",
         "PORT_FC_1": "0xEC is INTETC01", "PORT_FC_2": "0xED is INTETC23",
         "PORT_FC_3": "0xF0 is INTE0AD", "PORT_FC_4": "0xF6 is IIMC"}
ADD = [("P3FC", 0x0F), ("PCCR", 0x32), ("PCFC", 0x33), ("PD", 0x34), ("PDCR", 0x36), ("PDFC", 0x37),
       ("PE", 0x38), ("PECR", 0x3A), ("PEFC", 0x3B), ("PF", 0x3C), ("PFCR", 0x3E), ("PFFC", 0x3F),
       ("T02FFCR", 0x82), ("T16RUN", 0x9E), ("T16CR", 0x9F), ("IIMC", 0xF6)]
NAME = {0x03: "P0FC", 0x07: "P1FC", 0x0B: "P2FC", 0x0F: "P3FC", 0x1C: "P7", 0x1E: "P7CR", 0x1F: "P7FC",
        0x20: "P8", 0x22: "P8CR", 0x23: "P8FC", 0x28: "PA", 0x2B: "PAFC", 0x2C: "PB", 0x2F: "PBFC",
        0x32: "PCCR", 0x33: "PCFC", 0x34: "PD", 0x36: "PDCR", 0x37: "PDFC", 0x38: "PE", 0x3A: "PECR",
        0x3B: "PEFC", 0x3C: "PF", 0x3E: "PFCR", 0x3F: "PFFC", 0x40: "PG", 0x44: "PH", 0x46: "PHCR",
        0x47: "PHFC", 0x68: "PZ", 0x6A: "PZCR", 0x80: "T8RUN", 0x81: "TRDC", 0x82: "T02FFCR",
        0x84: "T01MOD", 0x85: "T23MOD", 0x88: "TREG0", 0x89: "TREG1", 0x8A: "TREG2", 0x8B: "TREG3",
        0x98: "T4MOD", 0x99: "T4FFCR", 0x9E: "T16RUN", 0x9F: "T16CR", 0xD1: "SER0_CR", 0xD2: "SER0_MOD",
        0xD5: "SER1_CR", 0xD6: "SER1_MOD", 0xF6: "IIMC"}
COMMENTS = [
    ("\tld (0x07:8), 0xFF:io\t; Port 0 all function", "; Port 1 all function",
     "; Port 1 all function (%s was \"Port 0\": 0x07 is P1FC, port 0's FC is 0x03)"),
    ("\tld (0x0B:8), 0xFF:io\t; Port 1 all function", "; Port 2 all function",
     "; Port 2 all function (%s was \"Port 1\": 0x0B is P2FC)"),
    ("\tld (0x0F:8), 0xFF:io\t; Port 2 all function", "; Port 3 all function",
     "; Port 3 all function (%s was \"Port 2\": 0x0F is P3FC)"),
    ("\tld (0x81:8), 0x00:io\t; Watchdog control", None,
     "; TRDC, timer double-buffer control (%s was \"Watchdog control\"; the watchdog is 0x110/0x111)"),
    ("\tset_dd8 1, 0x80\t; Watchdog mode", None,
     "; T8RUN bit 1: run 8-bit timer 1 (%s was \"Watchdog mode\": 0x80 is T8RUN)"),
]


def main():
    t = open(P, "rb").read().decode("latin-1")
    # comments first (their anchors carry the numeric operands)
    for anchor, _, new in COMMENTS:
        assert t.count(anchor) == 1, anchor
        code = anchor.split(";")[0]
        t = t.replace(anchor, code + new % STAR)
    L = t.split("\n")
    seen = set()
    for i, ln in enumerate(L):
        m = re.match(r"^\.equ\s+(\w+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)(\s*)(;.*)?$", ln)
        if not m:
            continue
        name, old = m.group(1), int(m.group(2), 0)
        seen.add(name)
        com = m.group(4) or ""
        if name in FIX and FIX[name] != old:
            L[i] = ".equ %s, 0x%X\t%s  [%s value corrected 2026-09-25, was 0x%X: MAME tmp94c241 map]" % (
                name, FIX[name], com if com else ";", STAR, old)
        elif name in WRONG:
            L[i] = ln + ("  " if com else "\t;") + "  [%s WRONG NAME for this address on the TMP94C241: %s]" % (
                STAR, WRONG[name])
    missing = [(n, v) for n, v in ADD if n not in seen]
    anchor = "; Legacy aliases for backward compatibility with existing code"
    k = L.index(anchor)
    block = ["; TMP94C241 SFR names this file lacked, with the values of v142/subcpu/shared/sfr_tmp94c241.s",
             "; and MAME's tmp94c241 map (added 2026-09-25 for the symbolic operands below)."]
    block += [".equ %s, 0x%X" % (n, v) for n, v in missing] + [""]
    L[k:k] = block
    n = 0
    DD8 = re.compile(r"^(\s*(?:set|res|bit|stcf|ldcf|xorcf|chg)_dd8\s+\d+\s*,\s*)(0x[0-9A-Fa-f]+|\d+)(\s*)$", re.I)
    for i, ln in enumerate(L):
        code, sep, com = ln.partition(";")
        if code.lstrip().startswith(".equ"):
            continue
        m = DD8.match(code)
        if m and int(m.group(2), 0) in NAME:
            code = m.group(1) + NAME[int(m.group(2), 0)] + m.group(3)
            n += 1

        def sub(mm):
            nonlocal n
            v = int(mm.group(1), 0)
            if v in NAME:
                n += 1
                return "(%s:8)" % NAME[v]
            return mm.group(0)
        code = re.sub(r"\((0x[0-9A-Fa-f]+|\d+):8\)", sub, code)
        L[i] = code + sep + com
    print("added %d names, rewrote %d operands" % (len(missing), n))
    if "--apply" in sys.argv:
        open(P, "wb").write("\n".join(L).encode("latin-1"))


if __name__ == "__main__":
    main()
