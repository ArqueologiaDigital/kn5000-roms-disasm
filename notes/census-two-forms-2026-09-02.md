# Tree-wide census for the two forms fixed in ad8129f59880 (2026-09-02)

**Question:** the LLVM tlcs900 backend fix that unblocked
`DSP_Bytecode_Op01/02/03` (569 B, converted this session -- see the commit on
this branch) fixed two decoder bugs: the dst-mem immediate store (`OpByte ==
0x02`, mnemonic `ldw` with a memory destination) and the direct-address ALU
family (`addda16`/`subda16`/`andda16`/`xorda16`/`orda16`/`cpda16` and their
`_24` siblings). Nobody had checked whether either form appears anywhere else
in the tree. Scope: v9/maincpu, v10/maincpu, subcpu/boot (313 `.s` files) --
v142/subcpu was handled directly (see the conversion commit).

**Run:**

    python3 scripts/analysis/census_two_forms.py <files...>

**Result:** an unfiltered first pass (round-trips + mentions either form
*anywhere* in the decoded text) found 189 candidate blocks / 1,096 B. Manually
checking the smallest ones showed the filter was dominated by a false-positive
class this project has been burned by before: short DATA records that happen
to decode as the OTHER, unrelated `ldw reg, imm16` encoding (e.g.
`v9/maincpu/audio/sound_data_world_perc.s`'s `WorldPerc_PatchEntry_048`, a
3-byte `.byte 0x30, 0x00, 0xff` table row, round-trips as `ldw wa, 65280`).
Restricting the store form to a MEMORY destination (`ldw\s+\(`) dropped 169 of
189 sites (1,016 B) as coincidental -- see the script's own docstring for the
full accounting.

**The remaining 20 hits are 10 distinct code sites** (v9 and v10 hold
byte-identical duplicates at the same line numbers -- the two images share
this source in lockstep, per `README-v9v10-census.md`'s own note that they
"cannot corroborate each other" by diffing). All 10 were read in context and
are genuine misframed CODE islands: a single mis-decoded instruction sitting
between two already-disassembled real instructions, not a data table. Example:
`bmdredit_routines.s:3972`'s `.byte 0xd1, 0xba, 0x27, 0x80` sits directly next
to `stda16 10170, wa` in the same function and decodes byte-exact as
`addda16 xwa, (10170)` -- the same address, an ALU read instead of a store,
exactly the shape a bytecode interpreter or a hand-written accumulator update
would take.

    v9/maincpu/ui/drawbar_panel_ui.s:1211        ldw (xbc), 1
    v9/maincpu/ui/drawbar_panel_ui.s:1225        ldw (xwa), 0
    v9/maincpu/ui/drawbar_panel_ui.s:1443        ldw (xwa), 2
    v9/maincpu/ui/ui_widget_defs.s:7913          ldw (xwa), 164
    v9/maincpu/ui/ui_widget_defs.s:7915          ldw (xwa), 196
    v9/maincpu/display/scoop_display.s:8306      cpda16 xwa, (14106)
    v9/maincpu/sequencer/sequencer_engine.s:25465   subda16 xwa, (61911)
    v9/maincpu/sequencer/sequencer_engine.s:25481   subda16 xwa, (61922)
    v9/maincpu/sequencer/bmdredit_routines.s:3960   addda16 xbc, (10192)
    v9/maincpu/sequencer/bmdredit_routines.s:3972   addda16 xwa, (10170)

Total: **10 sites x 2 images = 20 sites, 80 B**, all in the shape README-v9v10
-census.md already measured and named "misframed islands" (~14,727 B/image,
deliberately not attempted that session because reframing an existing
"instruction" boundary is riskier than filling a plain gap). This census adds
nothing new about the SHAPE of that debt -- it narrows which of those islands
are attributable to today's two decoder fixes specifically, rather than one of
the many other unsupported forms in that population.

**Two labels are misleading and worth flagging so nobody double-counts them as
"already known to be data":** `MainExe_InlineByteData` (sequencer_engine.s)
and `BmDrEdit_ByteData_CompoundWidgetUpdate` (bmdredit_routines.s) both read
like data-table names, but in context they label the *start of a function*
that is mostly real, already-decoded code (`ldb_d8`, `jr`, `stdi8`, `call`,
...) -- the "ByteData" in the name is stale from an earlier, coarser pass, not
evidence the region is data. Same caution as the HD-AE5000 version-string
lesson in DEBT-INVENTORY-2026-09-02.md, opposite direction: there the name was
neutral and the content was data; here the name suggests data and the content
is code. Judge by decode + surrounding structure, never by label text alone.

**subcpu/boot/kn5000_subcpu_boot.s: 0 hits** (only 7 candidate `.byte` blocks /
650 B total in that file; none use either form).

**Not converted here.** v9/maincpu and v10/maincpu belong to a different lane
(V10V9), not subcpudsp. Each of the 10 sites is a single instruction inside a
`.byte` run that is otherwise already correctly framed by that lane's own
tooling; converting only the flagged 4 B is exactly the kind of "reframe one
existing instruction, not just fill a gap" operation README-v9v10-census.md
declined to do without its own risk budget. Left as a precise pointer for that
lane, not applied.
