#!/usr/bin/env python3
"""gen_naka_regobj_table_names.py -- name the NAKA object tables by owner, class and object id (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  The Initialize<Owner> routines (InitializeKubo, InitializeHama, InitializeCheap, InitializeMurai, InitializeYoko)
  register NAKA object tables: `RegObjTabl NAKA_CLASS_<Class>, <Class>Proc, <count>, <table>, <object id>`.
  Many tables already follow <Owner>_<Class>Table_<id> (Kubo_ViewableTable_00A, Kubo_ApFuncTable_128,
  Kubo_ClassTable_168).  Others kept a positional name (InitializeKubo_PtrTable_35) or a generic one
  (HamaObj_169_Data).  For every registration whose table argument is one plain label of that kind, this script
  writes a rule  <label> -> <Owner>_<Class>Table_<id, 3 hex digits>  into
  scripts/renaming/rename_naka_regobj_tables_<tree>.sed.  The class word is the existing one: Viewable,
  ResName, Function, ApFunc, MainFunction, Class, ResEvent, ResMethod.  The object id comes from the
  registration itself, the index the NAKA registry is keyed by (ResName id = its Viewable's id + 0x300).
  A table registered twice, or a new name that exists already, stops the script.

RUN (repository root)
  python3 scripts/renaming/gen_naka_regobj_table_names.py      # writes the three sed files
  then per tree: sed -i -f scripts/renaming/rename_naka_regobj_tables_<tree>.sed <the tree's .s/.c files>
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLASS = {"Viewable": "ViewableTable", "ResName": "ResNameTable", "Function": "FunctionTable",
         "ApFunction": "ApFuncTable", "MainFunction": "MainFunctionTable", "Class": "ClassTable",
         "ResEvent": "ResEventTable", "ResMethod": "ResMethodTable"}
GENERIC = re.compile(r'^(Initialize\w+_PtrTable(_\d+)?|\w+Obj_[0-9A-F]{3}_Data)$')
REG = re.compile(r'\s*(RegObjTabl\w*|RegObjTable\w*)\s+NAKA_CLASS_(\w+),\s*(\w+),\s*([^,]+),\s*(\w+),\s*(0x[0-9a-fA-F]+|\d+)\s*$')


def main():
    for tree in ("v10", "v9", "v7"):
        defined, rules, seen = set(), {}, {}
        files = sorted(glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*.s"), recursive=True))
        for p in files:
            for line in open(p, "rb").read().decode("latin-1").split("\n"):
                m = re.match(r'^(\w+):', line) or re.match(r'^\s*\.set\s+(\w+),', line)
                if m:
                    defined.add(m.group(1))
        for p in files:
            owner = None
            for line in open(p, "rb").read().decode("latin-1").split("\n"):
                m = re.match(r'^(\w+):', line)
                if m:
                    owner = m.group(1)
                m = REG.match(line)
                if not m or not owner or not owner.startswith("Initialize"):
                    continue
                cls, table, oid = m.group(2), m.group(5), int(m.group(6), 0)
                if cls not in CLASS or not GENERIC.match(table):
                    continue
                new = "%s_%s_%03X" % (owner[len("Initialize"):], CLASS[cls], oid)
                assert table not in seen or seen[table] == new, (tree, table, seen.get(table), new)
                seen[table] = new
                assert new not in defined, (tree, new)
                rules[table] = new
        out = os.path.join(REPO, "scripts/renaming/rename_naka_regobj_tables_%s.sed" % tree)
        with open(out, "w") as f:
            f.write("# %s: NAKA object tables named <Owner>_<Class>Table_<object id> from their RegObjTabl\n"
                    "# registration (gen_naka_regobj_table_names.py).\n" % tree)
            for a, b in sorted(rules.items(), key=lambda x: -len(x[0])):
                f.write("s/\\b%s\\b/%s/g\n" % (a, b))
        print("%s: %d tables -> %s" % (tree, len(rules), os.path.relpath(out, REPO)))


if __name__ == "__main__":
    main()
