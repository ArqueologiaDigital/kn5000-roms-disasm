# WSA1 display-list drawers named (2026-10-03)

**Question:** which WSA1 `sub_<ADDR>` routines can be named from a fact read off their code?
A routine whose reachable code calls a display-list interpreter, and whose list *starts* include
exactly one text-named list, draws that list: it becomes `Draw_<List>`.

- Tool: `scripts/renaming/rename_wsa1_dl_drawers.py` (rule and history in its docstring),
  writing `scripts/renaming/rename_wsa1_dl_drawers.sed`.
- `renames.txt`: the 48 renames (prom_a 14, prom_b 34, split by address), each with the start operand of every
  interpreter call the routine's reachable code makes.  Produced by
  `python3 scripts/renaming/rename_wsa1_dl_drawers.py --verbose` on the tree before the renames
  (on the renamed tree it finds nothing left to do).

## What a name claims

The list, not the screen and not the routine's purpose.  Interpreters take a list as BOUNDS:
XIY = start, XIX = end (`wsa1/notes/FINDINGS-ui-display-list.md`); the 12-byte stack idiom pushes
the end first, the start last.  A list that only appears as an end bound is the next list in
memory and is not drawn.

## Correction of c0106cfa

c0106cfa named 54 routines counting **every** list operand as drawn.  `sub_F9315D` became
`Draw_Drum`, but `DL_Drum` is only the end bound of the list `0xF2BA16-0xF2BA20` it draws;
`sub_F7E354` became `Draw_TrackAssignPresetsTechnicsSetUp1116` for the same reason.  The commit
that added this note restored the parent's names and applied the start-operand rule.

## Not named, on purpose

- `sub_F99F24`: starts `DL_Input0utputFilterMidiT0talM0de`, but its header (round 7) records why
  it was not named -- that list is the MIDI menu's index of thirteen captions.  The renamer skips
  any routine whose header says `NOT NAMED because` / `REFUSED to name`.
- Routines with a start that is not a list label (a register copy, `xiz`-relative, `DLB_*` name
  tables) or that cannot be resolved within 8 reachable lines above the call.
