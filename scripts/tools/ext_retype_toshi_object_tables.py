#!/usr/bin/env python3
r"""ext_retype_toshi_object_tables.py -- type the TOSHI object tables in v10 extension_data.s.

QUESTION ANSWERED
-----------------
"InitializeToshi (extensions/extension_init.s) registers object tables that
live in extensions/extension_data.s.  Three of them are tables of CODE
pointers that the tree wrote as raw `.byte` rows; their names are in a
parallel table of strings.  Does every pointer land on the routine the
parallel name table says it is -- in v10 AND in v7 -- and what is the typed
text?"

It (1) verifies, for the ApFunction (42 entries), Function (28) and
MainFunction (20) tables, that entry k of the pointer table is the address of
the routine whose name is the string entry k of the name table points at, in
BOTH the v10 and v7 linked ELFs (v7's code moved, so this is the check that
the symbolic form will port); and (2) rewrites the v10 source: the `.byte`
rows become `.long <routine>` with a NULL terminator, the three count words
InitializeToshi reads with `ldw_da` become `.short`, the ResEvent/ResMethod
name tables get labels at their real first entry, and the tables get headers
citing their registrar.  The byte gate is the certification.

RUN (after `make gate`, which builds the ELFs it reads)
    python3 scripts/tools/ext_retype_toshi_object_tables.py --check
    python3 scripts/tools/ext_retype_toshi_object_tables.py --write
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
SRC = os.path.join(ROOT, "v10/maincpu/extensions/extension_data.s")
BASE = 0xE00000

# (pointer table addr, entries, name table addr, name-string label prefix or None)
TABLES = [
    ("ApFunction", 0xED1C9E, 42, 0xED1D4A),
    ("Function", 0xED2F66, 28, 0xED2FDA),
    ("MainFunction", 0xED3292, 20, 0xED32E6),
]


def syms(ver):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % ver)],
                         capture_output=True, text=True, check=True).stdout
    by_name, by_addr = {}, {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3:
            by_name[p[2]] = int(p[0], 16)
            by_addr.setdefault(int(p[0], 16), []).append(p[2])
    return by_name, by_addr


def u32(rom, a):
    return int.from_bytes(rom[a - BASE:a - BASE + 4], "little")


def cstr(rom, a):
    e = rom.index(b"\0", a - BASE)
    return rom[a - BASE:e].decode("latin-1")


def resolve():
    roms = {v: open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read() for v in ("v10", "v7")}
    S = {v: syms(v) for v in ("v10", "v7")}
    result = {}
    bad = 0
    for name, tab, n, ntab in TABLES:
        rows = []
        tbad = 0
        for k in range(n + 1):
            p10 = u32(roms["v10"], tab + 4 * k)
            p7 = u32(roms["v7"], tab + 4 * k)
            nm_ptr = u32(roms["v10"], ntab + 4 * k)
            fname = cstr(roms["v10"], nm_ptr)
            if k == n:
                ok = p10 == 0 and p7 == 0 and fname == ""
                rows.append(None)
                if not ok:
                    bad += 1
                    print("%s[%d]: terminator not NULL/\"\"" % (name, k))
                continue
            a10 = S["v10"][0].get(fname)
            a7 = S["v7"][0].get(fname)
            if a10 != p10:
                bad += 1
                tbad += 1
                print("%s[%d] %s: v10 ptr 0x%06X but the v10 routine of that name is at %s" % (
                    name, k, fname, p10, "0x%06X" % a10 if a10 else "-"))
            elif a7 != p7:
                # v7 has no label of this name; say which label v7 does have there
                print("%s[%d] %s: v7 has NO label of this name; v7 ptr 0x%06X carries %s" % (
                    name, k, fname, p7, S["v7"][1].get(p7, ["nothing"])))
            rows.append(fname)
        result[name] = rows
        print("%-12s 0x%06X: %d entries + NULL, every v10 pointer == the named v10 routine: %s"
              % (name, tab, n, "YES" if tbad == 0 else "NO"))
    return result, bad


HDR = {
    "ApFunction": """; ---------------------------------------------------------------------------
; Toshi_ApFunction_Table -- TOSHI object table: 42 "application function"
; code pointers + NULL (0xED1C9E-0xED1D49)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (extensions/extension_init.s, 0xFC311A):
;   RegObjTabl 0x1600002, ApFunctionProc, 42, Toshi_ApFunction_Table, 0x122
; which has RegisterObjectTable (ui/ui_widget_defs.s, 0xFA42FB) copy the
; 14-byte descriptor {class +0, proc +4, u16 count +8, table +10} into slot
; 0x122 of the object registry at RAM 0x27ED2 (14 bytes a slot).  An object
; id is (slot << 16) | element; CheckViewObject (0xFA42C4) reads the table
; pointer at +10 and indexes it with `extz xwa` / `sll xwa, 2` / `ld xwa, (xwa)`
; -- one 4-byte pointer per element, 0 = no object.  Slot 0x422 (= 0x122 +
; 0x300, the pairing RegisterObject 0xFA431A uses for an object's name) is
; Toshi_ApFunctionName_Table below: entry k there is the NAME of entry k here,
; and scripts/tools/ext_retype_toshi_object_tables.py --check verifies that
; every pointer lands on the routine of exactly that name (v10 and v7).
""",
    "Function": """; ---------------------------------------------------------------------------
; Toshi_Function_Table -- TOSHI object table: 28 screen/box procedure
; pointers + NULL (0xED2F66-0xED2FD9)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (0xFC311A) with
;   RegObjTabl 0x1600001, FunctionProc, 28, Toshi_Function_Table, 0x102
; into object-registry slot 0x102 (layout and indexing: see
; Toshi_ApFunction_Table).  Its names are Toshi_FunctionName_Table (slot
; 0x402); entry k there names entry k here -- verified for all 28 in v10 by
; scripts/tools/ext_retype_toshi_object_tables.py --check (in v7 for 27: v7
; labels entry 19's routine only AcMstStyleAlp_Boundary).
""",
    "MainFunction": """; ---------------------------------------------------------------------------
; Toshi_MainFunction_Table -- TOSHI object table: 20 "main function" code
; pointers + NULL (0xED3292-0xED32E5)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (0xFC311A) with
;   RegObjTabl 0x1600003, MainFunctionProc, 20, Toshi_MainFunction_Table, 0x142
; into object-registry slot 0x142 (layout and indexing: see
; Toshi_ApFunction_Table).  Its names are Toshi_MainFunctionName_Table (slot
; 0x442), whose strings sit in ui_widgets/normal_mode_layout.s; entry k there
; names entry k here -- verified for all 20, in v10 and v7, by
; scripts/tools/ext_retype_toshi_object_tables.py --check.
""",
}

NAMEHDR = {
    "ApFunction": """; Toshi_ApFunctionName_Table -- object-registry slot 0x422 (InitializeToshi:
; RegObjTabl 0x1600002, ApFunctionProc, 42, Toshi_ApFunctionName_Table, 0x422):
; the name of each Toshi_ApFunction_Table entry, same index, then "" as the
; terminator.  The strings follow in REVERSE order.
""",
    "Function": """; Toshi_FunctionName_Table -- object-registry slot 0x402 (InitializeToshi:
; RegObjTabl 0x1600001, FunctionProc, 28, Toshi_FunctionName_Table, 0x402):
; the name of each Toshi_Function_Table entry, same index; strings follow in
; reverse order.
""",
    "MainFunction": """; Toshi_MainFunctionName_Table -- object-registry slot 0x442 (InitializeToshi:
; RegObjTabl 0x1600003, MainFunctionProc, 20, Toshi_MainFunctionName_Table,
; 0x442): the name of each Toshi_MainFunction_Table entry, same index, then ""
; as the terminator.  The 20 name strings are the NakaInst_* cells of
; ui_widgets/normal_mode_layout.s (naka_normal_mode.c), included just below.
""",
}


def rows_text(rows):
    return "\n".join(("\t.long %s" % r) if r else "\t.long 0" for r in rows)


def rewrite(res):
    t = open(SRC, "rb").read().decode("latin-1")
    L = t.split("\n")

    def find(s, start=0):
        for i in range(start, len(L)):
            if L[i] == s:
                return i
        raise SystemExit("anchor not found: %r" % s)

    # --- ApFunction: the `.byte` rows after `aligned_string "<%s>"` up to NoteNameStr_Table_5
    i0 = find('\t.byte 0x25, 0x73, 0x00, 0xff, 0x6f, 0x6e, 0x00, 0xff, 0x20, 0x20, 0x00, 0xff, 0xc3, 0xe0, 0xfb, 0x00')
    i1 = find('\t.byte 0x10, 0x80, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00', i0)
    new = ['\taligned_string "%s"', '\taligned_string "on"', '\taligned_string "  "']
    new += HDR["ApFunction"].rstrip("\n").split("\n")
    new += ["Toshi_ApFunction_Table:"] + rows_text(res["ApFunction"]).split("\n")
    L[i0:i1 + 1] = new
    j = find("NoteNameStr_Table_5:")
    L[j:j + 1] = NAMEHDR["ApFunction"].rstrip("\n").split("\n") + ["Toshi_ApFunctionName_Table:"]

    # --- class count + ResEvent table
    j = find("\t.byte 0x1c, 0x00, 0x84, 0x2d, 0xed, 0x00")
    L[j:j + 2] = [
        "; Toshi class count: 28 -- read by InitializeToshi's first registration,",
        ";   RegObjTable 0x1600004, ClassProc, Toshi_Class_Count, Toshi_Class_Table, 0x162",
        "; whose count argument is loaded FROM this address (`ldw_da`), not immediate.",
        "Toshi_Class_Count:\t.short 28",
        "; ---------------------------------------------------------------------------",
        "; Toshi_ResEvent_Table -- object-registry slot 0x1C2: 8 event-name string",
        "; pointers + NULL, registered by InitializeToshi with",
        ";   RegObjTable 0x160000c, ResEventProc, Toshi_ResEvent_Count, Toshi_ResEvent_Table, 0x1c2",
        "; (the count word follows the strings).  The strings are the EV_* event",
        "; names; they follow in reverse order.",
        "; ---------------------------------------------------------------------------",
        "Toshi_ResEvent_Table:",
        "\t.long EventNameStr_EV_CHORDSHOW",
        "ParamStr_Table_25:",
    ]
    j = find('\taligned_string "EV_CHORDSHOW"')
    L[j] = 'EventNameStr_EV_CHORDSHOW:\taligned_string "EV_CHORDSHOW"'
    assert L[j + 1] == "\t.byte 0x08, 0x00, 0x56, 0x2f, 0xed, 0x00" and L[j + 2] == "NoteNameStr_Table_6:"
    L[j + 1:j + 3] = [
        "Toshi_ResEvent_Count:\t.short 8",
        "; ---------------------------------------------------------------------------",
        "; Toshi_ResMethod_Table -- object-registry slot 0x1E2: 26 method-name string",
        "; pointers + NULL, registered by InitializeToshi with",
        ";   RegObjTable 0x160000d, ResMethodProc, Toshi_ResMethod_Count, Toshi_ResMethod_Table, 0x1e2",
        "; (the count word follows the strings).  The strings are the MT_* method",
        "; names; they follow in reverse order.",
        "; ---------------------------------------------------------------------------",
        "Toshi_ResMethod_Table:",
        "\t.long MethodNameStr_MT_VariWrite",
        "NoteNameStr_Table_6:",
    ]
    j = find('\taligned_string "MT_VariWrite"')
    L[j] = 'MethodNameStr_MT_VariWrite:\taligned_string "MT_VariWrite"'
    # --- ResMethod count + Function table
    i0 = find('\t.byte 0x1a, 0x00, 0x62, 0xcd, 0xfb, 0x00, 0xe7, 0xe1, 0xfb, 0x00, 0x18, 0xf5, 0xfb, 0x00, 0xc3, 0x2e')
    i1 = find('\t.byte 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00', i0)
    L[i0:i1 + 1] = (["Toshi_ResMethod_Count:\t.short 26"] + HDR["Function"].rstrip("\n").split("\n")
                    + ["Toshi_Function_Table:"] + rows_text(res["Function"]).split("\n"))
    j = find("NoteNameStr_Table_7:")
    L[j:j + 1] = NAMEHDR["Function"].rstrip("\n").split("\n") + ["Toshi_FunctionName_Table:"]
    # --- MainFunction
    i0 = find('\t.byte 0xd9, 0x27, 0xfc, 0x00, 0x15, 0x28, 0xfc, 0x00, 0x5e, 0x29, 0xfc, 0x00, 0x87, 0x28, 0xfc, 0x00')
    i1 = find('\t.byte 0x00, 0x00, 0x00, 0x00', i0)
    L[i0:i1 + 1] = (HDR["MainFunction"].rstrip("\n").split("\n")
                    + ["Toshi_MainFunction_Table:"] + rows_text(res["MainFunction"]).split("\n"))
    j = find("NoteNameStr_Table_8:")
    L[j:j + 1] = NAMEHDR["MainFunction"].rstrip("\n").split("\n") + ["Toshi_MainFunctionName_Table:"]
    j = find("NakaInstTable8_NullTerm:")
    assert L[j + 1] == "\tnop" and L[j + 2] == "\tswi 7"
    L[j:j + 3] = ['NakaInstTable8_NullTerm:\taligned_string ""']
    open(SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("rewrote %s" % SRC)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args()
    res, bad = resolve()
    if bad:
        raise SystemExit("%d mismatches -- not writing" % bad)
    if a.write:
        rewrite(res)


if __name__ == "__main__":
    main()
