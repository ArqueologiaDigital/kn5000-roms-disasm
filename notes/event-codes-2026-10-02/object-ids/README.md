# NAKA object ids named from the firmware's registrations (2026-10-02, second pass)

**Question:** the event catalog (`../catalog.json`) named the ids its worklist met as v10
INSTRUCTION operands.  The registration macros pass many more as arguments (`RegMode 0x4,
..., 0x11, 0x1440016, 0x1a000dc`), which no tool substituted -- `apply_event_constants.py`
only matched lowercase mnemonics -- and v7, which expands those macros, showed 57 of them as
bare operands.  What are they?

**How:** `scripts/analysis/naka_object_id_names.py --out catalog_derived.json` reads the v10
source's RegObjTabl/RegObjTable/RegMode/RegTitle calls (*Hama too), resolves their arguments
through the v10 ELF, and reads the ROM:
* Function / ApFunction / MainFunction: the object table at slot S and its NAME table, the same
  class registered at S + 0x300 (u32 pointers to strings).  id `0x01SSnnnn` = entry n; name =
  string n.  `NAKA_FUNC_` / `NAKA_APFUNC_` / `NAKA_MAINFUNC_` + name; a name two modules share
  takes `_<Module>`.
* Modes: `RegMode m, "MD_X", i, ...` -> `0x01800000 + i`, `NAKA_MODE_MD_X`.
* Titles: `RegTitle m, "TT_X", i, ...` -> `0x01A00000 + i`, `TITLE_X`.

**Check:** 1,395 ids derived; 122 were already named by the first catalog (from handlers and
senders, with an independent skeptic per group) and all 122 agree with the derived name.
1,273 are new (`catalog_derived.json`: 520 NAKA_FUNC, 394 NAKA_APFUNC, 184 NAKA_MAINFUNC,
14 NAKA_MODE, the rest TITLE).

**Applied:**

    python3 scripts/tools/apply_event_constants.py notes/event-codes-2026-10-02/catalog.json --macros
    python3 scripts/tools/apply_event_constants.py notes/event-codes-2026-10-02/object-ids/catalog_derived.json --macros
    make gate-all                                   # 13/13

`--macros` (new) lets a capitalised mnemonic -- a macro invocation -- have its whole-literal
arguments substituted like instruction operands.  First catalog over macro arguments: 625
v10, 625 v9, 347 v7; derived catalog: 148 per KN5000 tree.  The 1,273 constants are defined
in every tree's `shared/event_codes.s`, HD-AE5000 included (unused there so far; the ids are
the main CPU's, which the expansion ROM addresses too).  Dashboard `numevt`: v7 57 -> 3,
v10 2 -> 1, v9 2 -> 1.
