#!/usr/bin/env python3
"""Spell subcpu/boot VECTOR_TABLE's 44 RAM-trampoline pointers by name (IntTramp_<vector>) and declare the names.

Each hardware vector n (1..44) points into RAM at 0x400 + 5*slot, where COPY_VECTORS put VECTOR_TRAMPOLINES and the
payload later puts its own 45 trampolines (v142/subcpu/subcpu_vectors.s, which defines the same names as labels).
The script asserts that every `.long 0x4xx` it rewrites holds exactly 0x400 + 5*slot(n) before touching it.
"""
import os
import re

P = "subcpu/boot/kn5000_subcpu_boot.s"
VEC = ["RESET", "SWI1", "SWI2", "SWI3", "SWI4", "SWI5", "SWI6", "SWI7", "NMI", "INTWD", "INT0", "INT4", "INT5", "INT6",
       "INT7", "Reserved", "INT8", "INT9", "INTA", "INTB", "INTT0", "INTT1", "INTT2", "INTT3", "INTTR4", "INTTR5",
       "INTTR6", "INTTR7", "INTTR8", "INTTR9", "INTTRA", "INTTRB", "INTRX0", "INTTX0", "INTRX1", "INTTX1", "INTAD"] + \
      ["INTTC%d" % i for i in range(8)]


def slot(v):
    return v if 1 <= v <= 7 else (44 if v == 8 else v - 1)


L = open(P, "rb").read().decode("latin-1").split("\n")
t = L.index("VECTOR_TABLE:")
assert L[t + 1].startswith("\t.long RESET_HANDLER")
for v in range(1, 45):
    m = re.match(r"\t\.long 0x([0-9A-Fa-f]+)\t;", L[t + 1 + v])
    assert m and int(m.group(1), 16) == 0x400 + 5 * slot(v), (v, L[t + 1 + v])
    note = "\t; slot 44: the one entry out of slot order" if v == 8 else ""
    L[t + 1 + v] = "\t.long IntTramp_%s%s" % (VEC[v], note)
# declare the names beside PAYLOAD_ENTRY, which is slot 0 of the same block
e = L.index(".equ PAYLOAD_ENTRY, 0x400\t; Entry point of loaded payload")
decl = ["; RAM interrupt trampolines, 5 bytes each (`jp target` + `ret`) at PAYLOAD_ENTRY + 5*slot.  COPY_VECTORS",
        "; fills them from VECTOR_TRAMPOLINES; a loaded payload overwrites them with its own (v142/subcpu/subcpu_vectors.s",
        "; labels the same addresses with the same names).  Named for the TMP94C241F vector that VECTOR_TABLE points at",
        "; each one (vector order: MAME tmp94c241_irq_vector_map; vector 0x3C is unassigned there, hence _Reserved).",
        "; Slot = vector for SWI1..SWI7, NMI is slot 44, and every later vector n is slot n - 1."]
for v in sorted(range(1, 45), key=slot):
    decl.append(".equ IntTramp_%s, 0x%03x" % (VEC[v], 0x400 + 5 * slot(v)))
L[e + 1:e + 1] = decl
b = "\n".join(L).encode("latin-1")
open(P + ".tmp", "wb").write(b)
os.replace(P + ".tmp", P)
print("rewrote 44 vector entries, declared 44 names")
